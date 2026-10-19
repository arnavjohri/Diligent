import re, sys
src = open("zpp_forecast_v2/src/zpp_forecast_upload.prog.abap", encoding="utf-8").read()
pnt = open("zpp_forecast_paints/src/zpp_forecast_paints_upl.prog.abap", encoding="utf-8").read()

def rep1(text, old, new, label):
    n = text.count(old)
    assert n == 1, f"{label}: anchor found {n} times"
    return text.replace(old, new)

# 1. header: everything up to and including the REPORT statement
head_end = src.index("REPORT zpp_forecast_upload MESSAGE-ID zpp_fcst.")
head_end = src.index("\n", head_end) + 1
header = """*&---------------------------------------------------------------------*
*& Report         : ZPP_FORECAST_PAINTS_UPL   Transaction: ZFCST_PAINTS_UPL
*& Title          : ZFORECAST (Paints) - all uploads in one program
*& Project        : KPMG / Astral UDAY            Module: PP
*& Related FS     : Forecast_Template-Paints_1.xlsx (WRICEF ID-2B),
*&                  received 19.10.2026
*& Author         : Arnav Johri                   Date: 19.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   The Paints copy of ZPP_FORECAST_UPLOAD (ZFCST_UPL) with two
*&   differences: a ninth upload type, Brand (plant, material, brand into
*&   ZPPT_BRAND), and a product-category indicator that accepts MTS, MTO,
*&   DIS and TIN rather than MTS and MTO only. The other seven uploads -
*&   tracking, exclusion, legacy history, business forecast quarterly and
*&   monthly, forecast change quarterly and monthly - are the Adhesive
*&   ones unchanged and write the same shared tables, so a Paints user
*&   needs this transaction only. Nothing on the Adhesive side is edited.
*&
*&   Copied from the repository copy of ZPP_FORECAST_UPLOAD activated on
*&   23/09/26. The change-marker blocks inside refer to that object's
*&   history and are kept so the two sources can be compared line by line.
*&
*& CHANGE HISTORY
*&   19.10.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zpp_forecast_paints_upl MESSAGE-ID zpp_fcst.
"""
out = header + src[head_end:]

# 2. ninth radio button
old = """SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_chgm RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_chgm FOR FIELD p_chgm.
SELECTION-SCREEN PUSHBUTTON 40(24) b_chgm USER-COMMAND tcgm.
SELECTION-SCREEN END OF LINE.
"""
new = old + """
* Paints only: brand per plant and material
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_brd RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_brd FOR FIELD p_brd.
SELECTION-SCREEN PUSHBUTTON 40(24) b_brd USER-COMMAND tbrd.
SELECTION-SCREEN END OF LINE.
"""
out = rep1(out, old, new, "radio")

# 3. texts
out = rep1(out, "  c_chgm = 'Forecast Change Monthly'.\n", "  c_chgm = 'Forecast Change Monthly'.\n  c_brd  = 'Brand'.\n", "c_brd")
out = rep1(out, "  b_chgm = 'Download Template'.\n", "  b_chgm = 'Download Template'.\n  b_brd  = 'Download Template'.\n", "b_brd")
out = rep1(out, "  c_cat  = 'Product Category'.\n", "  c_cat  = 'Product Category (Paints)'.\n", "c_cat")

# 4. template button
out = rep1(out, "    WHEN 'TCGM'. PERFORM download_template USING 'CHGM'.\n",
                "    WHEN 'TCGM'. PERFORM download_template USING 'CHGM'.\n    WHEN 'TBRD'. PERFORM download_template USING 'BRD'.\n", "TBRD")

# 5. dispatch
out = rep1(out, "    WHEN p_chgm. PERFORM do_change   USING 'M'.\n",
                "    WHEN p_chgm. PERFORM do_change   USING 'M'.\n    WHEN p_brd.  PERFORM do_brand.\n", "dispatch")

# 6. current_type
out = rep1(out, "    WHEN p_chgm. cv_type = 'CHGM'.\n", "    WHEN p_chgm. cv_type = 'CHGM'.\n    WHEN p_brd.  cv_type = 'BRD'.\n", "current_type")

# 7. template columns
old = "      APPEND 'ZPPT_FCST_MN-REASON'       TO lt_pre.\n\n    WHEN OTHERS.\n      RETURN.\n"
new = """      APPEND 'ZPPT_FCST_MN-REASON'       TO lt_pre.

*   Paints only
    WHEN 'BRD'.
      cv_name = 'ZFCST_Paints_Brand'.
      APPEND 'ZPPT_BRAND-WERKS' TO lt_pre.
      APPEND 'ZPPT_BRAND-MATNR' TO lt_pre.
      APPEND 'ZPPT_BRAND-BRAND' TO lt_pre.

    WHEN OTHERS.
      RETURN.
"""
out = rep1(out, old, new, "template BRD")

# 8. indicator check in do_category
old = """    lv_tmp = ls_raw-f05.
    CONDENSE lv_tmp.
    lv_mts = to_upper( lv_tmp ).
    IF lv_mts IS NOT INITIAL AND lv_mts <> 'MTS' AND lv_mts <> 'MTO'.
      lv_err = 'MTS or MTO column must contain MTS, MTO or nothing'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.
"""
new = """    lv_tmp = ls_raw-f05.
    CONDENSE lv_tmp.
*   Paints: the indicator is MTS, MTO, DIS or TIN (DIS ART and TINTING
*   accepted and stored as DIS and TIN) - see FORM CHECK_INDICATOR.
*   The Adhesive upload accepts MTS and MTO only:
*   lv_mts = to_upper( lv_tmp ).
*   IF lv_mts IS NOT INITIAL AND lv_mts <> 'MTS' AND lv_mts <> 'MTO'.
*     lv_err = 'MTS or MTO column must contain MTS, MTO or nothing'.
    PERFORM check_indicator USING lv_tmp CHANGING lv_mts lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.
"""
out = rep1(out, old, new, "indicator")

# 9. append do_brand and check_indicator from the current Paints file
def form(text, name):
    m = re.search(r"\*&-{20,}\*\n\*& [^\n]*\n(?:\*&[^\n]*\n)*\*&-{20,}\*\nFORM " + name + r"\b.*?\nENDFORM\.\n", text, re.S)
    assert m, name
    return m.group(0)
tail = "\n\n" + form(pnt, "check_indicator") + "\n\n" + form(pnt, "do_brand")
out = out.rstrip("\n") + "\n" + tail
open("zpp_forecast_paints/src/zpp_forecast_paints_upl.prog.abap", "w", encoding="utf-8").write(out)
print("written", out.count("\n"), "lines")
