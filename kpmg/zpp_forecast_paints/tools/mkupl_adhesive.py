"""Apply the Paints brand upload and the four-value indicator to the Adhesive
ZPP_FORECAST_UPLOAD, with change markers, originals commented in place.
Run from kpmg/:  python3 -I zpp_forecast_paints/tools/mkupl_adhesive.py
Each anchor must occur exactly once in the source, otherwise nothing is written.
"""
import re
P = "zpp_forecast_v2/src/zpp_forecast_upload.prog.abap"
D = "22/10/26"
BOC, EOC = f"*BOC By Arnav on {D}\n", f"*EOC By Arnav on {D}\n"
src = open(P, encoding="utf-8").read()
assert "p_brd" not in src, "already applied"

def rep1(text, old, new, label):
    n = text.count(old)
    assert n == 1, f"{label}: anchor found {n} times"
    return text.replace(old, new)

out = src

# 1. header line
out = rep1(out, "*& Eight upload types selected by radio button.",
                "*& Nine upload types selected by radio button (Brand, for Paints, since 22/10/26).", "header")

# 2. ninth radio button
old = """SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_chgm RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_chgm FOR FIELD p_chgm.
SELECTION-SCREEN PUSHBUTTON 40(24) b_chgm USER-COMMAND tcgm.
SELECTION-SCREEN END OF LINE.
"""
# The screen block already sits inside the 31/08/26 BOC/EOC block, so the new
# lines carry single-line markers rather than a nested block (CLAUDE.md rule).
new = old + f"""
* Brand per plant and material (ZPPT_BRAND) - the Paints template. Single-line
* markers: this screen block already sits inside the 31/08/26 block above.
SELECTION-SCREEN BEGIN OF LINE.                                "Changes by Arnav on {D}
PARAMETERS p_brd RADIOBUTTON GROUP typ.                        "Changes by Arnav on {D}
SELECTION-SCREEN COMMENT 3(33) c_brd FOR FIELD p_brd.          "Changes by Arnav on {D}
SELECTION-SCREEN PUSHBUTTON 40(24) b_brd USER-COMMAND tbrd.    "Changes by Arnav on {D}
SELECTION-SCREEN END OF LINE.                                  "Changes by Arnav on {D}
"""
out = rep1(out, old, new, "radio")

# 3. texts
out = rep1(out, "  c_chgm = 'Forecast Change Monthly'.\n",
                f"  c_chgm = 'Forecast Change Monthly'.\n  c_brd  = 'Brand'.                          \"Changes by Arnav on {D}\n", "c_brd")
out = rep1(out, "  b_chgm = 'Download Template'.\n",
                f"  b_chgm = 'Download Template'.\n  b_brd  = 'Download Template'.              \"Changes by Arnav on {D}\n", "b_brd")

# 4. template button
out = rep1(out, "    WHEN 'TCGM'. PERFORM download_template USING 'CHGM'.\n",
                f"    WHEN 'TCGM'. PERFORM download_template USING 'CHGM'.\n    WHEN 'TBRD'. PERFORM download_template USING 'BRD'.   \"Changes by Arnav on {D}\n", "TBRD")

# 5. dispatch
out = rep1(out, "    WHEN p_chgm. PERFORM do_change   USING 'M'.\n",
                f"    WHEN p_chgm. PERFORM do_change   USING 'M'.\n    WHEN p_brd.  PERFORM do_brand.                 \"Changes by Arnav on {D}\n", "dispatch")

# 6. current_type
out = rep1(out, "    WHEN p_chgm. cv_type = 'CHGM'.\n",
                f"    WHEN p_chgm. cv_type = 'CHGM'.\n    WHEN p_brd.  cv_type = 'BRD'.               \"Changes by Arnav on {D}\n", "current_type")

# 7. template columns
old = "      APPEND 'ZPPT_FCST_MN-REASON'       TO lt_pre.\n\n    WHEN OTHERS.\n      RETURN.\n"
new = f"""      APPEND 'ZPPT_FCST_MN-REASON'       TO lt_pre.

{BOC}    WHEN 'BRD'.
      cv_name = 'ZFCST_Brand'.
      APPEND 'ZPPT_BRAND-WERKS' TO lt_pre.
      APPEND 'ZPPT_BRAND-MATNR' TO lt_pre.
      APPEND 'ZPPT_BRAND-BRAND' TO lt_pre.
{EOC}
    WHEN OTHERS.
      RETURN.
"""
out = rep1(out, old, new, "template BRD")

# 8. indicator check in do_category - old lines kept, commented
old = """    lv_tmp = ls_raw-f05.
    CONDENSE lv_tmp.
    lv_mts = to_upper( lv_tmp ).
    IF lv_mts IS NOT INITIAL AND lv_mts <> 'MTS' AND lv_mts <> 'MTO'.
      lv_err = 'MTS or MTO column must contain MTS, MTO or nothing'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.
"""
new = f"""    lv_tmp = ls_raw-f05.
    CONDENSE lv_tmp.
{BOC}*   The Paints template adds DIS ART and TINTING to MTS / MTO. The
*   indicator is now MTS, MTO, DIS or TIN; the two long forms are
*   accepted and stored as DIS and TIN. See FORM CHECK_INDICATOR.
*   lv_mts = to_upper( lv_tmp ).
*   IF lv_mts IS NOT INITIAL AND lv_mts <> 'MTS' AND lv_mts <> 'MTO'.
*     lv_err = 'MTS or MTO column must contain MTS, MTO or nothing'.
    PERFORM check_indicator USING lv_tmp CHANGING lv_mts lv_err.
    IF lv_err IS NOT INITIAL.
{EOC}      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.
"""
out = rep1(out, old, new, "indicator")

# 9. the two new FORMs, appended
tail = f"""

{BOC}*&---------------------------------------------------------------------*
*& The indicator as typed in the file -> the stored code, or an error.
*&
*& MTS, MTO, DIS and TIN are stored as they are. The two long forms the
*& Paints template header uses, "DIS ART" and "TINTING", are accepted and
*& stored as DIS and TIN. Anything else is rejected; blank stays blank.
*& The fixed values of domain ZDO_MTS_MTO still list MTS and MTO only;
*& DIS and TIN are to be added there if the category is also maintained
*& through SM30 - this upload writes them regardless.
*&---------------------------------------------------------------------*
FORM check_indicator USING pv_in TYPE char40
                     CHANGING cv_ind TYPE zde_mts_mto
                              cv_err TYPE string.

  DATA lv_in TYPE char40.

  CLEAR: cv_ind, cv_err.

  lv_in = pv_in.
  CONDENSE lv_in.
  lv_in = to_upper( lv_in ).

  CHECK lv_in IS NOT INITIAL.

  IF lv_in = 'MTS' OR lv_in = 'MTO' OR lv_in = 'DIS' OR lv_in = 'TIN'.
    cv_ind = lv_in.
  ELSEIF lv_in = 'DIS ART' OR lv_in = 'DISART'.
    cv_ind = 'DIS'.
  ELSEIF lv_in = 'TINTING'.
    cv_ind = 'TIN'.
  ELSE.
    cv_err = 'Indicator must be MTS, MTO, DIS, TIN or nothing'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& 9 - Brand per plant and material (Paints)
*&
*& Plant, Material, Brand into ZPPT_BRAND. Plant and material checked
*& against MARC as every other upload does; an existing plant and
*& material is overwritten, a new one inserted.
*&---------------------------------------------------------------------*
FORM do_brand.

  DATA: ls_raw   TYPE ty_raw,
        ls_brd   TYPE zppt_brand,
        ls_old   TYPE zppt_brand,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_matnr TYPE matnr,
        lv_brand TYPE zde_brand,
        lv_ex    TYPE abap_bool,
        lv_err   TYPE string,
        lv_txt   TYPE string,
        lv_tmp   TYPE char40,
        lv_blank TYPE char12.

  LOOP AT gt_raw INTO ls_raw.

    lv_row = sy-tabix.
    PERFORM to_plant    USING ls_raw-f01 CHANGING lv_werks.
    PERFORM to_material USING ls_raw-f02 CHANGING lv_matnr.

    PERFORM check_marc USING lv_werks lv_matnr CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

    lv_tmp = ls_raw-f03.
    CONDENSE lv_tmp.
    lv_brand = lv_tmp.
    IF lv_brand IS INITIAL.
      lv_err = 'Brand is mandatory'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

    CLEAR: ls_brd, ls_old, lv_ex.
    SELECT SINGLE * FROM zppt_brand INTO @ls_old
      WHERE werks = @lv_werks AND matnr = @lv_matnr.
    IF sy-subrc = 0.
      lv_ex  = abap_true.
      ls_brd = ls_old.
    ENDIF.

    ls_brd-werks = lv_werks.
    ls_brd-matnr = lv_matnr.
    ls_brd-brand = lv_brand.
    PERFORM stamp USING lv_ex CHANGING ls_brd-ernam ls_brd-erdat
                                       ls_brd-aenam ls_brd-aedat.

    IF p_test = abap_false.
      MODIFY zppt_brand FROM @ls_brd.
      IF sy-subrc <> 0.
        lv_err = 'Database update failed'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
        CONTINUE.
      ENDIF.
    ENDIF.

    lv_txt = 'Brand uploaded'.
    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_blank lv_ex lv_txt.

  ENDLOOP.

ENDFORM.
{EOC}"""
out = out.rstrip("\n") + "\n" + tail
open(P, "w", encoding="utf-8", newline="\n").write(out)
print("written", P, out.count("\n") + 1, "lines (was", src.count("\n") + 1, ")")
