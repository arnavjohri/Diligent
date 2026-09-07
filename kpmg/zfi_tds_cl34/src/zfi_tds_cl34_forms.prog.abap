*&---------------------------------------------------------------------*
*& Report/Include : ZFI_TDS_CL34_FORMS
*& Title          : TDS Reporting as per Clause 34(a) - form routines
*& Project        : KPMG - UDAY / Astral          Module: FI
*& Related FS     : Clause 34 TDS Report FS.xlsx, v1, 21.08.2026
*& Author         : Arnav Johri                   Date: 26.08.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   All form routines of report ZFI_TDS_CL34.
*&
*&   Shape of the run:
*&     INIT_DEFAULTS      proposes the period, nothing else
*&     VALIDATE_SELECTION plausibility of the input, the only TYPE 'E'
*&     FETCH_WT_ITEMS     the ONE database read of the driver set
*&     BUILD_OUTPUT       master data, configuration, exemptions, GL
*&                        derivation, then the 25 output columns
*&     REPORT_GL_GAPS     one aggregated message for undrivable GLs
*&     DISPLAY_ALV        CL_SALV_TABLE list
*&
*&   Every database read is set based. The only loops that touch the
*&   database are none - each buffer is filled once with FOR ALL ENTRIES
*&   over a de-duplicated key table and is then read with BINARY SEARCH
*&   over a table sorted on exactly the key of the read, so the row loop
*&   stays O(n log n) on a list that can return tens of thousands of rows.
*&
*& CHANGE HISTORY
*&   26.08.2026  Arnav Johri  <TR>  Initial development
*&   07.09.2026  Arnav Johri  <TR>  WhldgTaxItemStatus V/D/M/S excluded;
*&                                  vendor code F4 + ALPHA conversion;
*&                                  F4 on section code
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Propose the current Indian fiscal year and its posting-date window so
*& the three obligatory fields are not empty when the screen opens.
*&
*& Both proposals are guarded by IS INITIAL. A value handed in by a
*& variant or by SUBMIT ... WITH is already on the screen when
*& INITIALIZATION runs, and overwriting it would silently ignore what the
*& caller asked for.
*&
*& The year comes from SY-DATUM, never from a literal: before April the
*& current fiscal year is the previous calendar year.
*&---------------------------------------------------------------------*
FORM init_defaults.

  DATA: lv_year TYPE n LENGTH 4,
        lv_next TYPE n LENGTH 4.

  DATA ls_budat LIKE LINE OF s_budat.

* " ASSUMPTION: the company codes in scope run an April-March fiscal
* year variant (V3), so the proposed period and the proposed P_GJAHR
* agree with one another. Under a calendar year variant (K4) the
* proposal is internally inconsistent - P_GJAHR would exclude the
* January-to-March part of the proposed posting date range, because the
* two filters are applied with AND - and the user must overtype both
* fields. It is a PROPOSAL only: both fields are guarded by IS INITIAL,
* so a variant or SUBMIT ... WITH always wins. docs/QUERIES.md carries
* the question.
  lv_year = sy-datum(4).
  IF sy-datum+4(2) < gc_fy_start_mm.
    lv_year = lv_year - 1.
  ENDIF.
  lv_next = lv_year + 1.

  IF p_gjahr IS INITIAL.
    p_gjahr = lv_year.
  ENDIF.

  IF s_budat IS INITIAL.
    ls_budat-sign   = gc_sign_incl.
    ls_budat-option = gc_option_bt.

    ls_budat-low(4)     = lv_year.
    ls_budat-low+4(4)   = gc_fy_first_mmdd.
    ls_budat-high(4)    = lv_next.
    ls_budat-high+4(4)  = gc_fy_last_mmdd.

    APPEND ls_budat TO s_budat.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Plausibility of the selection screen.
*&
*& Four checks: every company code typed as a single value must exist in
*& T001, the user must be authorised to display documents of every
*& company code the selection resolves to, the fiscal year must not be
*& in the future, and no posting-date range may end before it starts.
*&
*& This is the only routine in the program allowed to issue TYPE 'E'.
*& AT SELECTION-SCREEN is the one event where an E message returns the
*& user to the input field; anywhere else it ends the report on a blank
*& screen, which is the short-dump-by-another-name that CLAUDE.md forbids.
*&
*& The fiscal year is deliberately NOT cross-checked against the posting
*& date range. Both filters are applied with AND and a contradiction
*& between them simply returns no rows - that is the user's decision to
*& make, not the report's to refuse.
*&---------------------------------------------------------------------*
FORM validate_selection.

  CONSTANTS lc_option_eq TYPE c LENGTH 2 VALUE 'EQ'.

  DATA: lv_maxyear TYPE bkpf-gjahr,
        lv_authcc  TYPE bkpf-bukrs,
        lv_text    TYPE string.

* Company code must exist. Only entries typed as a single value can be
* verified one by one; a range or an exclusion is left to the database.
  SELECT bukrs
    FROM t001
    WHERE bukrs IN @s_bukrs
    INTO TABLE @DATA(lt_cc).

  IF lt_cc IS INITIAL.
    MESSAGE 'No company code of the selection exists in T001' TYPE 'E'.
  ENDIF.

  SORT lt_cc BY bukrs.

  LOOP AT s_bukrs INTO DATA(ls_bukrs)
       WHERE sign = gc_sign_incl AND option = lc_option_eq.

    READ TABLE lt_cc TRANSPORTING NO FIELDS
         WITH KEY bukrs = ls_bukrs-low BINARY SEARCH.
    IF sy-subrc <> 0.
      lv_text = |Company code { ls_bukrs-low } does not exist|.
      MESSAGE lv_text TYPE 'E'.
    ENDIF.

  ENDLOOP.

* Authorisation. The check itself lives in CHECK_AUTHORISATION because
* START-OF-SELECTION has to repeat it for the background case - see the
* comment on that form. AT SELECTION-SCREEN is the only event where
* TYPE 'E' returns the user to the field instead of ending the report on
* a blank screen, so the dialog half of the answer belongs here.
  PERFORM check_authorisation CHANGING lv_authcc.

  IF lv_authcc IS NOT INITIAL.
    lv_text = |No display authorisation for company code { lv_authcc }|.
    MESSAGE lv_text TYPE 'E'.
  ENDIF.

* Fiscal year. The upper bound is derived from the system date so no
* year is hardcoded; a year one ahead is allowed because a shifted
* fiscal year variant can post into it.
* P_GJAHR is not tested for INITIAL: it is declared OBLIGATORY in
* ZFI_TDS_CL34_SCR, so the runtime rejects an empty value on the
* selection screen itself and this event never sees one.
  lv_maxyear = sy-datum(4) + 1.

  IF p_gjahr > lv_maxyear.
    MESSAGE 'Fiscal year lies more than one year in the future' TYPE 'E'.
  ENDIF.

* Posting date range.
  LOOP AT s_budat INTO DATA(ls_budat).
    IF ls_budat-high IS NOT INITIAL AND ls_budat-high < ls_budat-low.
      MESSAGE 'Posting date To must not be earlier than From' TYPE 'E'.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Company code authorisation, for both execution modes.
*&
*& Build decision D1 replaced the CDS view I_WITHHOLDINGTAXITEM, which is
*& authorisation-filtered by its own DCLS, with a direct read of
*& WITH_ITEM / BKPF / BSEG. A base-table SELECT carries no check of its
*& own, so without this form any user able to start the report would see
*& TDS base amounts, tax amounts, vendor names and vendor PANs for every
*& company code they cared to type. D1 is the right call for other
*& reasons; this form pays for it.
*&
*& It is called TWICE on purpose. AT SELECTION-SCREEN does not run in a
*& background job started from a variant, so a check placed only there
*& would leave every scheduled run unprotected - and a fiscal-year
*& compliance extract is precisely the kind of report people schedule.
*& The dialog caller turns a failure into TYPE 'E' and keeps the user on
*& the field; the START-OF-SELECTION caller reports and returns without
*& reading a single row.
*&
*& Returns the FIRST company code the user may not display, blank when
*& the check passes.
*&
*& " ASSUMPTION: F_BKPF_BUK (BUKRS, ACTVT) is the authorisation object in
*& force on this landscape and ACTVT '03' is display - confirm in SU21 /
*& SU24. docs/QUERIES.md carries the question.
*&---------------------------------------------------------------------*
FORM check_authorisation CHANGING pv_bukrs TYPE bkpf-bukrs.

  CONSTANTS lc_actvt_display TYPE c LENGTH 2 VALUE '03'.

  CLEAR pv_bukrs.

* The check is on the company codes the selection actually resolves to,
* never on what was typed: a range or an exclusion has to be expanded
* before it can be checked one code at a time. ORDER BY only makes the
* code that gets reported the lowest one rather than an arbitrary one.
  SELECT bukrs
    FROM t001
    WHERE bukrs IN @s_bukrs
    ORDER BY bukrs
    INTO TABLE @DATA(lt_auth).

  LOOP AT lt_auth INTO DATA(ls_auth).

    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
             ID 'BUKRS' FIELD ls_auth-bukrs
             ID 'ACTVT' FIELD lc_actvt_display.

    IF sy-subrc <> 0.
      pv_bukrs = ls_auth-bukrs.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM.

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& F4 for the Section Code select-option - the official withholding tax
*& key, output column H.
*&
*& The list must come from the SAME place the filter is applied, or it
*& offers keys the report cannot return. S_SECTN is compared with
*& LS_OUT-SECTION in BUILD_OUTPUT, which is T059Z-QSCOD read on the
*& item's country, withholding tax type and withholding tax code. So
*& this read reproduces that: the withholding items in scope, joined to
*& T001 for the country and to T059Z for the key, with the same V/D/M/S
*& status exclusion the driver applies. A key whose only items the driver
*& throws away is not offered.
*&
*& The description is fetched separately from T059OT rather than by a
*& LEFT OUTER JOIN: the join would need SY-LANGU in its ON condition to
*& stay outer, and a WHERE on the outer table silently makes the join
*& inner again, which would drop every key with no text in the logon
*& language. Two reads, no such trap.
*&
*& Company code and fiscal year are read off the SCREEN with
*& DYNP_VALUES_READ, not from S_BUKRS / P_GJAHR. At ON VALUE-REQUEST the
*& screen has not yet been transported into the ABAP variables, so those
*& are still empty. Both are OBLIGATORY anyway, so asking for them first
*& costs the user nothing and keeps the read bounded.
*&
*& Only the LOW and HIGH visible on the screen are honoured. Values added
*& through the multiple-selection dialog are not on the screen and cannot
*& be read here; they narrow the report itself, not this list.
*&
*& Wider than the report by one hair, which can only add a key and never
*& hide one: the posting date is not applied. It lives on the header and
*& would need a further join plus a date conversion off the screen, and
*& the fiscal year already bounds the read.
*&
*& History, so it is not re-tried: the first version of this form read
*& SELECT DISTINCT SECCO FROM BSEG, and the second joined BSEG to
*& I_WITHHOLDINGTAXITEM to get the section code of the vendor line. Both
*& were on BSEG-SECCO - the SAP India business place, values like 08AL -
*& which is not what the report shows in its Section column and, as of
*& 07/09/26, not what the screen filters either.
*&---------------------------------------------------------------------*
FORM f4_section_code USING pv_field TYPE clike.

  TYPES: BEGIN OF ty_key,
           land1 TYPE t001-land1,
           qscod TYPE t059z-qscod,
         END OF ty_key,
         BEGIN OF ty_f4,
           qscod  TYPE t059z-qscod,
           text40 TYPE t059ot-text40,
         END OF ty_f4.

  CONSTANTS: lc_digits TYPE string      VALUE '0123456789',
             lc_i      TYPE c LENGTH 1  VALUE 'I',
             lc_eq     TYPE c LENGTH 2  VALUE 'EQ',
             lc_bt     TYPE c LENGTH 2  VALUE 'BT',
*            Typed as the column itself, so the comparison below needs
*            no implicit length conversion.
             lc_noqsc  TYPE t059z-qscod VALUE IS INITIAL.

  DATA: lt_dynp  TYPE STANDARD TABLE OF dynpread    WITH DEFAULT KEY,
        lt_key   TYPE STANDARD TABLE OF ty_key      WITH DEFAULT KEY,
        lt_val   TYPE STANDARD TABLE OF ty_f4       WITH DEFAULT KEY,
        lt_ret   TYPE STANDARD TABLE OF ddshretval  WITH DEFAULT KEY,
        lt_txt   TYPE tt_t059ot,
        lr_bukrs TYPE RANGE OF bkpf-bukrs,
        lv_low   TYPE bkpf-bukrs,
        lv_high  TYPE bkpf-bukrs,
        lv_gj4   TYPE c LENGTH 4,
        lv_gjahr TYPE bkpf-gjahr.

* The three screen fields whose current contents this F4 needs.
  APPEND INITIAL LINE TO lt_dynp ASSIGNING FIELD-SYMBOL(<ls_ask>).
  <ls_ask>-fieldname = 'S_BUKRS-LOW'.
  APPEND INITIAL LINE TO lt_dynp ASSIGNING <ls_ask>.
  <ls_ask>-fieldname = 'S_BUKRS-HIGH'.
  APPEND INITIAL LINE TO lt_dynp ASSIGNING <ls_ask>.
  <ls_ask>-fieldname = 'P_GJAHR'.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname             = sy-repid
      dynumb             = sy-dynnr
      translate_to_upper = abap_true
    TABLES
      dynpfields         = lt_dynp
    EXCEPTIONS
      OTHERS             = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Enter Company Code and Fiscal Year, then press F4' TYPE 'S'.
    RETURN.
  ENDIF.

  LOOP AT lt_dynp ASSIGNING FIELD-SYMBOL(<ls_got>).

    CASE <ls_got>-fieldname.
      WHEN 'S_BUKRS-LOW'.
        lv_low  = <ls_got>-fieldvalue.
      WHEN 'S_BUKRS-HIGH'.
        lv_high = <ls_got>-fieldvalue.
      WHEN 'P_GJAHR'.
*       FIELDVALUE is CHAR 132 and blank padded, so it is moved into a
*       CHAR 4 first - CO against the padded field would never match.
        lv_gj4 = <ls_got>-fieldvalue.
        IF lv_gj4 CO lc_digits.
          lv_gjahr = lv_gj4.
        ENDIF.
    ENDCASE.

  ENDLOOP.

  IF lv_low IS INITIAL OR lv_gjahr IS INITIAL.
    MESSAGE 'Enter Company Code and Fiscal Year first, then press F4' TYPE 'S'.
    RETURN.
  ENDIF.

  APPEND INITIAL LINE TO lr_bukrs ASSIGNING FIELD-SYMBOL(<ls_rng>).
  <ls_rng>-sign = lc_i.
  <ls_rng>-low  = lv_low.
  IF lv_high IS INITIAL.
    <ls_rng>-option = lc_eq.
  ELSE.
    <ls_rng>-option = lc_bt.
    <ls_rng>-high   = lv_high.
  ENDIF.

* The official withholding tax keys the report can return in this
* company code and fiscal year. The country comes from T001 because
* T059Z is keyed by it, exactly as FETCH_TAX_CONFIG reads it at runtime.
  SELECT DISTINCT c~land1, z~qscod
    FROM i_withholdingtaxitem AS w
    INNER JOIN t001  AS c ON c~bukrs = w~companycode
    INNER JOIN t059z AS z ON  z~land1     = c~land1
                          AND z~witht     = w~withholdingtaxtype
                          AND z~wt_withcd = w~withholdingtaxcode
    WHERE w~companycode IN @lr_bukrs
      AND w~fiscalyear  =  @lv_gjahr
      AND z~qscod      <> @lc_noqsc
      AND w~whldgtaxitemstatus NOT IN ( @gc_wtstat_v, @gc_wtstat_d,
                                        @gc_wtstat_m, @gc_wtstat_s )
    ORDER BY c~land1, z~qscod
    INTO TABLE @lt_key.

  IF lt_key IS INITIAL.
    MESSAGE 'No TDS document in this company code and year has a section' TYPE 'S'.
    RETURN.
  ENDIF.

* Descriptions of those keys, the same source column I uses.
  SELECT spras, land1, wt_qscod, text40
    FROM t059ot
    FOR ALL ENTRIES IN @lt_key
    WHERE spras    = @sy-langu
      AND land1    = @lt_key-land1
      AND wt_qscod = @lt_key-qscod
    INTO TABLE @lt_txt.

  SORT lt_txt BY spras land1 wt_qscod.

  LOOP AT lt_key ASSIGNING FIELD-SYMBOL(<ls_key>).

    APPEND INITIAL LINE TO lt_val ASSIGNING FIELD-SYMBOL(<ls_val>).
    <ls_val>-qscod = <ls_key>-qscod.

    READ TABLE lt_txt ASSIGNING FIELD-SYMBOL(<ls_txt>)
         WITH KEY spras    = sy-langu
                  land1    = <ls_key>-land1
                  wt_qscod = <ls_key>-qscod
         BINARY SEARCH.
    IF sy-subrc = 0.
      <ls_val>-text40 = <ls_txt>-text40.
    ENDIF.

  ENDLOOP.

* Two company codes in different countries can carry the same key, so
* the pair is collapsed to the key the user actually picks.
  SORT lt_val BY qscod text40.
  DELETE ADJACENT DUPLICATES FROM lt_val COMPARING qscod.

* DYNPROFIELD is what makes the picked value land back in the field the
* user pressed F4 on, so RETURN_TAB needs no post-processing here.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'QSCOD'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_field
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Section value help could not be displayed' TYPE 'S'.
  ENDIF.

ENDFORM.
*EOC By Arnav on 07/09/26

*&---------------------------------------------------------------------*
*& Read the driver set: the withholding tax items, their document
*& headers and every line item of those documents.
*&
*& THIS IS THE ONLY FORM THAT READS THE WITHHOLDING TAX DATA. It reads
*& the two CDS views FS [B2] names, I_WITHHOLDINGTAXITEM inner-joined to
*& I_JOURNALENTRY, under the FS's mandatory filter of company code,
*& fiscal year and posting date.
*&
*& The read is isolated here on purpose. None of the CDS element names
*& can be verified without the target system, so if the view rejects one
*& of them THIS FORM IS THE ONLY ONE TO CHANGE - everything downstream
*& works off GT_WITEM / GT_BKPF / GT_BSEG and never touches a view. The
*& equivalent base-table read, should the views turn out to be absent or
*& thin on this release, is:
*&
*&   SELECT w~bukrs, w~belnr, w~gjahr, w~buzei, w~witht, w~wt_withcd,
*&          w~wt_acco, w~wt_qsshh, w~wt_qbshh, w~qsatz
*&     FROM with_item AS w
*&     INNER JOIN bkpf AS h ON  h~bukrs = w~bukrs
*&                          AND h~belnr = w~belnr
*&                          AND h~gjahr = w~gjahr
*&     WHERE h~bukrs IN @s_bukrs AND h~gjahr = @p_gjahr
*&       AND h~budat IN @s_budat AND w~wt_acco IN @s_lifnr
*&       AND w~koart = 'K' AND w~wt_withcd <> @space
*&     INTO TABLE @gt_witem.
*&
*& The WHLDGTAXITEMSTATUS exclusion added on 07/09/26 is NOT reproduced
*& in that fallback - no WITH_ITEM equivalent of the element has been
*& confirmed. Before ever switching to the fallback, look up where the
*& view sources WHLDGTAXITEMSTATUS from and carry the filter across;
*& dropping it would silently widen the report.
*&
*& The header buffer GT_BKPF is still read from BKPF and the line items
*& from BSEG, because that is what the FS itself asks for everywhere
*& except this one driver select: [L2] names BKPF for XBLNR, [J2] [K2]
*& [M2] [N2] [O2] name BSEG, and the GLCode Logic tab works on BSEG,
*& AWKEY, RSEG, EKKN, MBEW and T030.
*&
*& Section code is filtered in ABAP rather than in the WHERE clause. It
*& lives on the line item, and the very same BSEG read serves the vendor
*& line (columns J / N / O) and the withholding lines of the GL
*& derivation, so pushing SECCO into the database would cost a second
*& read of the same rows.
*&---------------------------------------------------------------------*
FORM fetch_wt_items.

*BOC By Arnav on 07/09/26
*  CLEAR: gt_witem, gt_bkpf, gt_bseg, gt_dockey, gv_nobseg.
  CLEAR: gt_witem, gt_bkpf, gt_bseg, gt_dockey, gv_nosect.
*EOC By Arnav on 07/09/26

* Driver. FS [B2]: inner join the two views, apply the mandatory filter
* of company code, fiscal year and posting date, and take every
* ACCOUNTINGDOCUMENT the join returns.
*
* The element list is in TY_WITEM component order - strict ABAP SQL
* assigns by position, so the two must not drift apart.
*
* " ASSUMPTION: no account-type restriction is applied. The FS asks for
* CUSTOMERSUPPLIERACCOUNT without qualifying it, so customer withholding
* items are not excluded; where one occurs its Vendor Name and Vendor PAN
* come back blank because LFA1 has no such account. Registered as a query.
  SELECT w~companycode, w~accountingdocument, w~fiscalyear,
         w~accountingdocumentitem, w~withholdingtaxtype,
         w~withholdingtaxcode, w~customersupplieraccount,
         w~whldgtaxbaseamtincocodecrcy, w~whldgtaxamtincocodecrcy,
         w~withholdingtaxpercent
    FROM i_withholdingtaxitem AS w
    INNER JOIN i_journalentry AS h
            ON  h~companycode        = w~companycode
            AND h~accountingdocument = w~accountingdocument
            AND h~fiscalyear         = w~fiscalyear
    WHERE h~companycode             IN @s_bukrs
      AND h~fiscalyear              =  @p_gjahr
      AND h~postingdate             IN @s_budat
      AND w~customersupplieraccount IN @s_lifnr
*BOC By Arnav on 07/09/26
*     Status exclusion. Items in status V, D, M or S are not reportable
*     and are filtered in the database rather than after the read, so
*     they are absent from GT_WITEM, from GT_DOCKEY and therefore from
*     every buffer and every diagnostic count downstream.
*
*     A BLANK status is KEPT - only the four listed codes are excluded.
*     " ASSUMPTION: WHLDGTAXITEMSTATUS is never NULL in the view. NOT IN
*     evaluates to unknown against NULL, so a NULL-bearing element would
*     drop the row silently. It is a field of the withholding tax item
*     itself, on the inner-joined side, so a NULL can only come from a
*     CASE or a left outer join inside the view - check the view's own
*     definition in ADT if a document you expect goes missing.
      AND w~whldgtaxitemstatus  NOT IN ( @gc_wtstat_v, @gc_wtstat_d,
                                         @gc_wtstat_m, @gc_wtstat_s )
*EOC By Arnav on 07/09/26
    INTO TABLE @gt_witem.

  IF gt_witem IS INITIAL.
    RETURN.                    " no message here - the main program owns it
  ENDIF.

* Rows carrying neither a base amount nor a tax amount are not a TDS
* deduction and are dropped (build contract D5).
  DELETE gt_witem WHERE wt_qsshh = 0 AND wt_qbshh = 0.

  IF gt_witem IS INITIAL.
    RETURN.
  ENDIF.

* Document key of the driver set, first pass.
  PERFORM build_dockey.

  IF gt_dockey IS INITIAL.
    RETURN.
  ENDIF.

* Every line of every driver document. KTOSL is deliberately absent from
* the WHERE clause - see the form comment above.
*
* THE FIELD ORDER BELOW MUST MATCH TY_BSEG COMPONENT FOR COMPONENT.
* Strict ABAP SQL assigns INTO TABLE by POSITION, not by name, so a field
* inserted in the select but not in the same slot of the type silently
* lands in the wrong component - or, if the types happen to differ,
* fails activation with "component X is not compatible with Y".
*
* H_BUDAT and H_BLDAT are the header dates propagated onto the line item,
* which FS [K2] and [M2] name for columns K and M.
* " ASSUMPTION: BSEG-GHKON is populated on the withholding line. The field
* exists; its content on the Astral system is unverified. If it is empty
* in practice, columns F and G stay blank for direct FI postings - see
* QUERIES Q11.
  SELECT bukrs, belnr, gjahr, buzei, koart, ktosl, lifnr, sgtxt,
         augbl, augdt, secco, ghkon, h_budat, h_bldat
    FROM bseg
    FOR ALL ENTRIES IN @gt_dockey
    WHERE bukrs = @gt_dockey-bukrs
      AND belnr = @gt_dockey-belnr
      AND gjahr = @gt_dockey-gjahr
    INTO TABLE @gt_bseg.

  SORT gt_bseg BY bukrs belnr gjahr buzei.

*BOC By Arnav on 07/09/26
* The section filter USED to sit here, on the BSEG-SECCO of the vendor
* line, and narrowed GT_WITEM before the headers were read. It has moved
* to BUILD_OUTPUT: S_SECTN now filters column H, the official withholding
* tax key, which is not known until T059Z has been read. The block is
* kept commented rather than deleted so the shape it had is on record.
*
* Consequence, deliberate and documented: the GL derivation and its gap
* counts now run over the documents the DATE and COMPANY CODE selection
* returns, not over the section-filtered subset. So a run filtered to one
* section can report GL gaps for documents that section excluded. The
* alternative was to read T001 and T059Z inside this form and filter
* early, which restructures a form that is proven against two live runs.
* If the message noise matters, that is the fix - it is not a defect in
* the numbers, only in the scope of a diagnostic.
*
** Section code filter. The section code is read off the SAME vendor line
** that later supplies columns J / N / O, through the one form
** READ_VENDOR_LINE, so the filter and those three columns can never
** resolve to different lines of the document.
*  IF s_secco IS NOT INITIAL.
*
*    DATA: lt_keep  TYPE tt_witem,
*          ls_vline TYPE ty_bseg.
*
*    LOOP AT gt_witem INTO DATA(ls_wi).
*
*      PERFORM read_vendor_line USING    ls_wi-bukrs
*                                        ls_wi-belnr
*                                        ls_wi-gjahr
*                                        ls_wi-buzei
*                               CHANGING ls_vline.
*
*      IF ls_vline IS INITIAL.
*        gv_nobseg = gv_nobseg + 1.
*      ELSEIF ls_vline-secco IN s_secco.
*        APPEND ls_wi TO lt_keep.
*      ENDIF.
*
*    ENDLOOP.
*
*    gt_witem = lt_keep.
*    FREE lt_keep.
*
*    IF gt_witem IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    PERFORM build_dockey.
*
*  ENDIF.
*EOC By Arnav on 07/09/26

* Document headers of the surviving set.
*
* The guard below cannot currently fire - GT_DOCKEY was already proven
* non-empty before the BSEG read above, and on the filtered path
* BUILD_DOCKEY has just rebuilt it from a GT_WITEM the branch itself
* proved non-empty. It is kept deliberately, not by oversight: a
* FOR ALL ENTRIES over an empty driver table reads the WHOLE of BKPF,
* and the standing rule is one emptiness check before EVERY
* FOR ALL ENTRIES, so this read is not made the one exception in the
* program. The live guard is the one before the BSEG read.
  IF gt_dockey IS INITIAL.
    RETURN.
  ENDIF.

* " ASSUMPTION: reversed documents (BKPF-STBLG filled) and parked
* documents (BKPF-BSTAT) are REPORTED, not excluded. The FS is silent,
* both fields exist and are readable, and a reversed TDS document
* double-counted on a clause 34 return is a client decision rather than
* a technical one - docs/QUERIES.md Q6 carries the question for Ankita
* Parikh. Turning her answer into a filter means adding STBLG / BSTAT
* to TY_BKPF in ZFI_TDS_CL34_TOP, to the field list below and to the
* WHERE clause.
  SELECT bukrs, belnr, gjahr, budat, bldat, xblnr, awtyp, awkey
    FROM bkpf
    FOR ALL ENTRIES IN @gt_dockey
    WHERE bukrs = @gt_dockey-bukrs
      AND belnr = @gt_dockey-belnr
      AND gjahr = @gt_dockey-gjahr
    INTO TABLE @gt_bkpf.

  SORT gt_bkpf BY bukrs belnr gjahr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Distinct BUKRS / BELNR / GJAHR of the current driver set. Called
*& twice - once on the raw result and once after the section code filter
*& has narrowed it.
*&
*& The SORT is on exactly the three fields the DELETE ADJACENT DUPLICATES
*& compares. It is deliberately NOT the WITH_ITEM key: WT_WITHCD is not a
*& key field of WITH_ITEM, and the document key is all this table needs.
*&---------------------------------------------------------------------*
FORM build_dockey.

  CLEAR gt_dockey.

  LOOP AT gt_witem ASSIGNING FIELD-SYMBOL(<ls_wi>).
    APPEND INITIAL LINE TO gt_dockey ASSIGNING FIELD-SYMBOL(<ls_dk>).
    <ls_dk>-bukrs = <ls_wi>-bukrs.
    <ls_dk>-belnr = <ls_wi>-belnr.
    <ls_dk>-gjahr = <ls_wi>-gjahr.
  ENDLOOP.

  SORT gt_dockey BY bukrs belnr gjahr.
  DELETE ADJACENT DUPLICATES FROM gt_dockey COMPARING bukrs belnr gjahr.

ENDFORM.

*&---------------------------------------------------------------------*
*& The vendor line of one FI document, returned whole.
*&
*& FS [J2] does not name an item number - it says to read BSEG for the
*& document "where LIFNR <> blank". Build contract D5 restates it. The
*& item number the withholding item carries is tried first because it is
*& almost always the vendor line, but the FS's own condition is what
*& decides: a line is the vendor line when its account type is 'K' and
*& its vendor number is filled.
*&
*& " ASSUMPTION: WITH_ITEM-BUZEI addresses the vendor line. Where it
*& does not, the lowest numbered vendor line of the same document is
*& taken rather than columns J / N / O being filled from a GL or tax
*& line - a plausible wrong value is worse than a blank, and a blank
*& would lose data the FS asks for.
*&
*& An empty structure comes back where the document has no vendor line
*& at all. FETCH_WT_ITEMS counts that case in GV_NOBSEG; BUILD_OUTPUT
*& leaves the three columns blank.
*&
*& GT_BSEG is sorted by BUKRS / BELNR / GJAHR / BUZEI, so the binary
*& search below is on a proper prefix of that sort and the forward walk
*& meets the items of the document in ascending item number.
*&---------------------------------------------------------------------*
FORM read_vendor_line USING    pv_bukrs TYPE bseg-bukrs
                               pv_belnr TYPE bseg-belnr
                               pv_gjahr TYPE bseg-gjahr
                               pv_buzei TYPE bseg-buzei
                      CHANGING ps_bseg  TYPE ty_bseg.

  DATA lv_idx TYPE sy-tabix.

  CLEAR ps_bseg.

* The line the withholding item points at, if it really is a vendor line.
  READ TABLE gt_bseg ASSIGNING FIELD-SYMBOL(<ls_bseg>)
       WITH KEY bukrs = pv_bukrs
                belnr = pv_belnr
                gjahr = pv_gjahr
                buzei = pv_buzei
       BINARY SEARCH.

  IF sy-subrc = 0.
    IF <ls_bseg>-koart = gc_koart_vendor AND <ls_bseg>-lifnr IS NOT INITIAL.
      ps_bseg = <ls_bseg>.
      RETURN.
    ENDIF.
  ENDIF.

* Fall back to the lowest numbered vendor line of the same document.
  READ TABLE gt_bseg TRANSPORTING NO FIELDS
       WITH KEY bukrs = pv_bukrs
                belnr = pv_belnr
                gjahr = pv_gjahr
       BINARY SEARCH.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

  LOOP AT gt_bseg ASSIGNING <ls_bseg> FROM lv_idx.

    IF <ls_bseg>-bukrs <> pv_bukrs
    OR <ls_bseg>-belnr <> pv_belnr
    OR <ls_bseg>-gjahr <> pv_gjahr.
      EXIT.
    ENDIF.

    IF <ls_bseg>-koart = gc_koart_vendor AND <ls_bseg>-lifnr IS NOT INITIAL.
      ps_bseg = <ls_bseg>.
      EXIT.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Everything from the driver set to the finished output list.
*&
*& Order matters: the company code supplies the country that keys the
*& withholding configuration and the chart of accounts that keys the GL
*& text, the GL derivation must run before the GL texts can be read, and
*& the vendor PAN must be known before the two exemption tables can be
*& read.
*&
*& No MESSAGE is issued anywhere in this form or in anything it calls. A
*& derivation that finds nothing blanks its cell and the row survives -
*& the withholding figures are still valid and reportable. The only
*& feedback is the aggregated count in REPORT_GL_GAPS.
*&---------------------------------------------------------------------*
FORM build_output.

* LS_T001 is a copy rather than a field symbol on purpose. A failed
* READ TABLE leaves a field symbol in whatever state the previous loop
* pass left it, so a company code missing from T001 would silently be
* reported with the country, currency and chart of accounts of the row
* before it. The copy is cleared at the top of every pass.
  DATA: ls_out    TYPE ty_output,
        ls_t001   TYPE ty_t001,
        ls_vline  TYPE ty_bseg,
        lv_secco  TYPE bseg-secco,
        lv_budat  TYPE bkpf-budat,
        lv_hidate TYPE bkpf-budat.

  CLEAR gt_output.

  IF gt_witem IS INITIAL.
    RETURN.
  ENDIF.

* Document order, so the running number reads as a document list. Only a
* SORT - the withholding items are never de-duplicated, each one is a row.
  SORT gt_witem BY bukrs belnr gjahr buzei witht wt_withcd.

  PERFORM fetch_company_data.
  PERFORM fetch_vendor_data.
  PERFORM fetch_tax_config.
  PERFORM derive_gl_codes.
  PERFORM fetch_gl_texts.
  PERFORM fetch_exemptions.

  PERFORM budat_upper CHANGING lv_hidate.

  LOOP AT gt_witem ASSIGNING FIELD-SYMBOL(<ls_wi>).

    CLEAR: ls_out, ls_t001, ls_vline, lv_secco, lv_budat.

    ls_out-belnr    = <ls_wi>-belnr.              " col B
    ls_out-lifnr    = <ls_wi>-wt_acco.            " col C
*BOC By Arnav on 07/09/26
* Columns P and T are reported as MAGNITUDES.
*
* WITH_ITEM stores the base and tax with the sign of the VENDOR LINE the
* tax was calculated on - BSEG-SHKZG, not the document type:
*   vendor CREDITED (invoice, posting key 31)          -> negative
*   vendor DEBITED  (down payment key 29 / SGL J,
*                    payment, invoice cancellation)    -> positive
* Proven on 07/09/26 against 1900000001 (key 31, base 4,500.00- and tax
* 90.00-) and 1500000010 (key 29 SGL J, base 10,000.00 and tax 2,000.00),
* and consistent across all 93 rows of that run: every positive row is a
* vendor-debit posting, and 1700000000 is negative despite being a 17*
* document, which rules out the number range as the driver.
*
* Neither raw signs nor a flat x -1 is reportable:
*   raw    - invoices and down payments read opposite ways although both
*            ARE deductions, which is the defect being fixed;
*   x -1   - would turn invoices positive but down payments negative.
* ABS( ) is the only rule that makes every deduction read the same way,
* which is what a clause 34(a) disclosure needs.
*
* " ASSUMPTION: the cost of ABS( ) is that a REVERSAL adds instead of
* subtracting - it is a vendor-debit posting too. On the 07/09/26 run
* that is 5 rows (5110000004/5/6, 5110000018, 5110000012), 400,100.00 of
* base and 2.00 of tax, because four of them carry code C8 at 0.0000.
* Whether reversed documents belong on the report at all is QUERIES Q6,
* open with Ankita Parikh; ABS( ) does not decide it. If she wants them
* to net off, the sign has to be driven off a reversal indicator on BKPF
* rather than off the amount - note that the "MR8M" visible in Nature of
* Payment is BSEG-SGTXT, free text somebody typed, and 5110000012 is a
* reversal without it, so that text is NOT a usable marker.
*
* Columns W and Y are left alone - they come from the FIWTIN exemption
* tables as positive accumulations already.
*    ls_out-base_amt = <ls_wi>-wt_qsshh.           " col P  company code currency
*    ls_out-tds_amt  = <ls_wi>-wt_qbshh.           " col T  company code currency
    ls_out-taxcode  = <ls_wi>-wt_withcd.          " col Q
    ls_out-rate_ded = <ls_wi>-qsatz.              " col S  rate actually deducted
    ls_out-base_amt = abs( <ls_wi>-wt_qsshh ).    " col P  magnitude
    ls_out-tds_amt  = abs( <ls_wi>-wt_qbshh ).    " col T  magnitude

*   Col Z. The direction the magnitudes above no longer carry. Taken
*   off the base amount, which is non-zero on every surviving row -
*   build contract D5 keeps a row when base OR tax is non-zero, so the
*   tax amount is used only where the base itself is zero.
    IF <ls_wi>-wt_qsshh < 0
    OR ( <ls_wi>-wt_qsshh = 0 AND <ls_wi>-wt_qbshh < 0 ).
      ls_out-drcr = gc_shkzg_credit.              " H  invoice
    ELSE.
      ls_out-drcr = gc_shkzg_debit.               " S  down payment, payment, cancellation
    ENDIF.
*EOC By Arnav on 07/09/26

*   Company code - country, currency, chart of accounts.
    READ TABLE gt_t001 INTO ls_t001
         WITH KEY bukrs = <ls_wi>-bukrs BINARY SEARCH.
    IF sy-subrc <> 0.
      CLEAR ls_t001.
    ELSE.
      ls_out-waers = ls_t001-waers.
    ENDIF.

*   Vendor master - name and PAN.
    READ TABLE gt_lfa1 ASSIGNING FIELD-SYMBOL(<ls_lfa1>)
         WITH KEY lifnr = <ls_wi>-wt_acco BINARY SEARCH.
    IF sy-subrc = 0.
      ls_out-name1  = <ls_lfa1>-name1.            " col D
      ls_out-pan_no = <ls_lfa1>-j_1ipanno.        " col E
    ENDIF.

*   Document header - posting date, reference, document date.
    READ TABLE gt_bkpf ASSIGNING FIELD-SYMBOL(<ls_bkpf>)
         WITH KEY bukrs = <ls_wi>-bukrs
                  belnr = <ls_wi>-belnr
                  gjahr = <ls_wi>-gjahr
         BINARY SEARCH.
    IF sy-subrc = 0.
      ls_out-xblnr  = <ls_bkpf>-xblnr.            " col L  FS [L2] names BKPF for the reference
    ENDIF.

*   Vendor line of this withholding item. FS [J2] and build contract D5
*   require the VENDOR line ("where LIFNR <> blank") - KOART and LIFNR
*   are read into GT_BSEG for exactly this guard. The BUZEI the
*   withholding item points at is tried first; where that line is not a
*   vendor line the lowest numbered vendor line of the same document is
*   used, so the three columns are never filled from a GL or tax line.
    PERFORM read_vendor_line USING    <ls_wi>-bukrs
                                      <ls_wi>-belnr
                                      <ls_wi>-gjahr
                                      <ls_wi>-buzei
                             CHANGING ls_vline.

*   " ASSUMPTION: col J is the item text of the vendor line, not the
*   BKPF header text. FS [J6] says header text, FS [J2] says BSEG-SGTXT
*   of the line "where LIFNR <> blank". QUERIES Q5.
    ls_out-nature = ls_vline-sgtxt.               " col J
    ls_out-budat  = ls_vline-h_budat.             " col K  FS [K2] - BSEG-H_BUDAT, not BKPF-BUDAT
    ls_out-bldat  = ls_vline-h_bldat.             " col M  FS [M2] - BSEG-H_BLDAT, not BKPF-BLDAT
    ls_out-augbl  = ls_vline-augbl.               " col N  blank while the item is open
    ls_out-augdt  = ls_vline-augdt.               " col O  blank while the item is open
    lv_secco      = ls_vline-secco.               " tie-break for columns U to X and column Y

*   The posting date drives the exemption certificate validity test and
*   the cumulative amount cut-off, so it comes from the same field the
*   FS puts in column K.
*   " ASSUMPTION: BSEG-H_BUDAT is populated. It is a propagated copy of
*   BKPF-BUDAT and can be blank depending on how the document was
*   posted; where it is blank column K is blank and columns U to Y fall
*   away with it. If that happens, BKPF-BUDAT is already in GT_BKPF and
*   this is a one-line change.
    lv_budat      = ls_vline-h_budat.

*   GL code and GL name.
    READ TABLE gt_glmap ASSIGNING FIELD-SYMBOL(<ls_glmap>)
         WITH KEY bukrs = <ls_wi>-bukrs
                  belnr = <ls_wi>-belnr
                  gjahr = <ls_wi>-gjahr
         BINARY SEARCH.
    IF sy-subrc = 0.
      ls_out-gl_code = <ls_glmap>-gl_code.        " col F
    ENDIF.

    IF ls_out-gl_code IS NOT INITIAL.
      READ TABLE gt_skat ASSIGNING FIELD-SYMBOL(<ls_skat>)
           WITH KEY ktopl = gc_ktopl_gl
                    saknr = ls_out-gl_code
           BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-gl_name = <ls_skat>-txt50.         " col G
      ENDIF.
    ENDIF.

*   Withholding tax configuration - official key and configured rate.
    IF ls_t001-land1 IS NOT INITIAL.

      READ TABLE gt_t059z ASSIGNING FIELD-SYMBOL(<ls_t059z>)
           WITH KEY land1     = ls_t001-land1
                    witht     = <ls_wi>-witht
                    wt_withcd = <ls_wi>-wt_withcd
           BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-section  = <ls_t059z>-qscod.       " col H
        ls_out-rate_sec = <ls_t059z>-qsatz.       " col R  zero is legitimate for a formula based code
      ENDIF.

*     Col I. FS [I2] names T059Z-TXT40, which does not exist; the text of
*     the official key comes from T059OT. H and I are then consistent -
*     if QSCOD is unmaintained in config both are blank together, which
*     is configuration, not a defect.
      IF ls_out-section IS NOT INITIAL.
        READ TABLE gt_t059ot ASSIGNING FIELD-SYMBOL(<ls_t059ot>)
             WITH KEY spras    = sy-langu
                      land1    = ls_t001-land1
                      wt_qscod = ls_out-section
             BINARY SEARCH.
        IF sy-subrc = 0.
          ls_out-sec_desc = <ls_t059ot>-text40.   " col I
        ENDIF.
      ENDIF.

    ENDIF.

*BOC By Arnav on 07/09/26
*   Section filter. S_SECTN is compared with COLUMN H - the official
*   withholding tax key just derived - because that is the value the
*   report shows in its Section column. It sits here rather than in
*   FETCH_WT_ITEMS because the key is not known until T059Z has been
*   read, and before the exemption reads below so a row that is about to
*   be dropped does not pay for them.
    IF s_sectn IS NOT INITIAL.

      IF ls_out-section IS INITIAL.
*       No T059Z entry for this item's country, type and code, so column
*       H is blank and the row cannot be tested against the filter. It is
*       COUNTED, never dropped in silence - REPORT_GL_GAPS reports the
*       count. Without this the same row would survive a run with an
*       empty section and vanish from a run with one, saying nothing.
        gv_nosect = gv_nosect + 1.
        CONTINUE.
      ELSEIF ls_out-section NOT IN s_sectn.
        CONTINUE.
      ENDIF.

    ENDIF.
*EOC By Arnav on 07/09/26

*   Exemption certificate - columns U / V / W / X.
    PERFORM read_exemption USING    <ls_wi>-bukrs
                                    <ls_wi>-wt_acco
                                    <ls_wi>-witht
                                    <ls_wi>-wt_withcd
                                    ls_out-pan_no
                                    lv_secco
                                    lv_budat
                           CHANGING ls_out-exdf
                                    ls_out-exdt
                                    ls_out-threshold
                                    ls_out-cert_no.

*   Accumulated base amount - column Y.
    PERFORM read_cumulative USING    <ls_wi>-bukrs
                                     <ls_wi>-wt_acco
                                     <ls_wi>-witht
                                     <ls_wi>-wt_withcd
                                     ls_out-pan_no
                                     lv_secco
                                     lv_hidate
                            CHANGING ls_out-cum_amt.

    APPEND ls_out TO gt_output.

  ENDLOOP.

* Running number, continuous over the whole list and not restarted per
* company code. Assigned in place - never MODIFY <itab> FROM inside a
* loop over that same table.
  LOOP AT gt_output ASSIGNING FIELD-SYMBOL(<ls_out>).
    <ls_out>-sr = sy-tabix.                       " col A
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Company code data. No FOR ALL ENTRIES is needed - the selection screen
*& already restricts the company codes and the field is obligatory.
*&
*& The chart of accounts read here is the one the GLCode Logic tab asks
*& for - "fetch KTOPL from T001 using BUKRS and provide the same in T030".
*& It is NOT the one column G uses: FS [G2] asks for a literal 'ASTL'
*& there, and that instruction is honoured through the constant
*& GC_KTOPL_GL. The two are deliberately separate.
*&
*& " ASSUMPTION: KTOPL is maintained for every company code in scope. The
*& field exists; the content on the Astral system is unverified. A blank
*& chart drops the T030 account determination for that company code and
*& the document is counted by REPORT_GL_GAPS.
*&---------------------------------------------------------------------*
FORM fetch_company_data.

  CLEAR gt_t001.

  SELECT bukrs, land1, waers,
         ktopl
    FROM t001
    WHERE bukrs IN @s_bukrs
    INTO TABLE @gt_t001.

  SORT gt_t001 BY bukrs.

ENDFORM.

*&---------------------------------------------------------------------*
*& Vendor master. The PAN read here also keys the four exemption columns
*& and the cumulative column, so a column-wide blank PAN blanks six
*& columns at once - that is a defect to investigate, while scattered
*& blanks are normal for vendors without a PAN.
*&
*& " ASSUMPTION: the PAN is held in LFA1-J_1IPANNO and is read at its
*& full dictionary length, never truncated to 10. Its population on the
*& Astral system is unverified - QUERIES Q10.
*&---------------------------------------------------------------------*
FORM fetch_vendor_data.

  DATA lt_venkey TYPE tt_venkey.

  CLEAR gt_lfa1.

  LOOP AT gt_witem ASSIGNING FIELD-SYMBOL(<ls_wi>).
    CHECK <ls_wi>-wt_acco IS NOT INITIAL.
    APPEND INITIAL LINE TO lt_venkey ASSIGNING FIELD-SYMBOL(<ls_vk>).
    <ls_vk>-lifnr = <ls_wi>-wt_acco.
  ENDLOOP.

  SORT lt_venkey BY lifnr.
  DELETE ADJACENT DUPLICATES FROM lt_venkey COMPARING lifnr.

  IF lt_venkey IS NOT INITIAL.
    SELECT lifnr, name1,
           j_1ipanno              " col E - see the ASSUMPTION above
      FROM lfa1
      FOR ALL ENTRIES IN @lt_venkey
      WHERE lifnr = @lt_venkey-lifnr
      INTO TABLE @gt_lfa1.
  ENDIF.

  SORT gt_lfa1 BY lifnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Withholding tax configuration.
*&
*& T059Z is keyed LAND1 + WITHT + WT_WITHCD. The FS names only
*& WT_WITHCD; the country comes from the company code and the tax type
*& from the withholding item, so the read is on the full key and cannot
*& pick up a code of the same name from another country.
*&
*& T059Z carries no text field at all, so the description in column I is
*& the text of the OFFICIAL withholding tax key and lives in T059OT.
*& Note that the key field is called WT_QSCOD there and QSCOD on T059Z.
*&---------------------------------------------------------------------*
FORM fetch_tax_config.

  DATA: lt_wtkey TYPE tt_t059z,
        lt_otkey TYPE tt_t059ot.

  CLEAR: gt_t059z, gt_t059ot.

  LOOP AT gt_witem ASSIGNING FIELD-SYMBOL(<ls_wi>).

    READ TABLE gt_t001 ASSIGNING FIELD-SYMBOL(<ls_t001>)
         WITH KEY bukrs = <ls_wi>-bukrs BINARY SEARCH.
    CHECK sy-subrc = 0.

    APPEND INITIAL LINE TO lt_wtkey ASSIGNING FIELD-SYMBOL(<ls_wk>).
    <ls_wk>-land1     = <ls_t001>-land1.
    <ls_wk>-witht     = <ls_wi>-witht.
    <ls_wk>-wt_withcd = <ls_wi>-wt_withcd.

  ENDLOOP.

  SORT lt_wtkey BY land1 witht wt_withcd.
  DELETE ADJACENT DUPLICATES FROM lt_wtkey COMPARING land1 witht wt_withcd.

  IF lt_wtkey IS NOT INITIAL.
    SELECT land1, witht, wt_withcd, qscod, qsatz
      FROM t059z
      FOR ALL ENTRIES IN @lt_wtkey
      WHERE land1     = @lt_wtkey-land1
        AND witht     = @lt_wtkey-witht
        AND wt_withcd = @lt_wtkey-wt_withcd
      INTO TABLE @gt_t059z.
  ENDIF.

  SORT gt_t059z BY land1 witht wt_withcd.

* Text of the official withholding tax key, in the logon language.
* FS [I2] asks for T059Z-TXT40; that field does not exist - see the
* comment on TY_T059OT in ZFI_TDS_CL34_TOP.
  LOOP AT gt_t059z ASSIGNING FIELD-SYMBOL(<ls_t059z>).
    CHECK <ls_t059z>-qscod IS NOT INITIAL.
    APPEND INITIAL LINE TO lt_otkey ASSIGNING FIELD-SYMBOL(<ls_ok>).
    <ls_ok>-spras    = sy-langu.
    <ls_ok>-land1    = <ls_t059z>-land1.
    <ls_ok>-wt_qscod = <ls_t059z>-qscod.
  ENDLOOP.

  SORT lt_otkey BY spras land1 wt_qscod.
  DELETE ADJACENT DUPLICATES FROM lt_otkey COMPARING spras land1 wt_qscod.

  IF lt_otkey IS NOT INITIAL.
    SELECT spras, land1, wt_qscod, text40
      FROM t059ot
      FOR ALL ENTRIES IN @lt_otkey
      WHERE spras    = @lt_otkey-spras
        AND land1    = @lt_otkey-land1
        AND wt_qscod = @lt_otkey-wt_qscod
      INTO TABLE @gt_t059ot.
  ENDIF.

  SORT gt_t059ot BY spras land1 wt_qscod.

ENDFORM.

*&---------------------------------------------------------------------*
*& GL account long text, column G.
*&
*& SKA1 has no text field of any kind on this release, so the text comes
*& from the text table SKAT in the logon language. The chart of accounts
*& is the one of the document's own company code.
*&---------------------------------------------------------------------*
FORM fetch_gl_texts.

  DATA lt_glkey TYPE tt_glkey.

  CLEAR gt_skat.

  LOOP AT gt_glmap ASSIGNING FIELD-SYMBOL(<ls_glmap>).

    CHECK <ls_glmap>-gl_code IS NOT INITIAL.

*   FS [G2]: provide "ASTL" in KTOPL. The chart is not read from T001
*   here - see the comment on GC_KTOPL_GL.
    APPEND INITIAL LINE TO lt_glkey ASSIGNING FIELD-SYMBOL(<ls_gk>).
    <ls_gk>-ktopl = gc_ktopl_gl.
    <ls_gk>-saknr = <ls_glmap>-gl_code.

  ENDLOOP.

  SORT lt_glkey BY ktopl saknr.
  DELETE ADJACENT DUPLICATES FROM lt_glkey COMPARING ktopl saknr.

  IF lt_glkey IS NOT INITIAL.
    SELECT spras, ktopl, saknr, txt50
      FROM skat
      FOR ALL ENTRIES IN @lt_glkey
      WHERE spras = @sy-langu
        AND ktopl = @lt_glkey-ktopl
        AND saknr = @lt_glkey-saknr
      INTO TABLE @gt_skat.
  ENDIF.

* The language is constant across the buffer, so it is not part of the
* sort key - the lookups read by chart of accounts and account only.
  SORT gt_skat BY ktopl saknr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Exemption certificates and accumulated base amounts, columns U to Y.
*&
*& Both tables are keyed by company code, account type, account, tax
*& type, tax code and PAN. Supplying all of them keeps the read on the
*& primary key; reading by PAN alone - which is what the FS asks for -
*& would be an unindexed full scan, and PAN is the LAST key field.
*&
*& The posting date is deliberately NOT part of the key table. Validity
*& is a property of the individual row and is evaluated per output row in
*& READ_EXEMPTION, so the date never enters the database read.
*&
*& Note the field name trap: the section code is SECCODE on
*& FIWTIN_TAN_EXEM and SECCO on FIWTIN_ACC_EXEM. Neither is RESTRICTED
*& here - the FS makes neither the certificate nor the accumulation
*& section code specific - but both are selected and both are appended
*& to the sort key, together with FIWTIN_TANEX_SUB, which is the other
*& unrestricted key field of FIWTIN_TAN_EXEM. Without them two rows of
*& one vendor can tie on the date the pick is made by, and ABAP SORT is
*& unstable, so columns U to X and column Y could change between two
*& runs of the same report over unchanged data.
*& READ_EXEMPTION and READ_CUMULATIVE then use the section code only to
*& break such a tie in favour of the document's own section code. WHICH
*& section code's certificate and accumulation belong on the row is a
*& functional question and is logged in docs/QUERIES.md for Ankita
*& Parikh; only her answer turns the section code into a filter.
*&---------------------------------------------------------------------*
FORM fetch_exemptions.

  DATA lt_exkey TYPE tt_exkey.

  CLEAR: gt_tanex, gt_accex.

  LOOP AT gt_witem ASSIGNING FIELD-SYMBOL(<ls_wi>).

    READ TABLE gt_lfa1 ASSIGNING FIELD-SYMBOL(<ls_lfa1>)
         WITH KEY lifnr = <ls_wi>-wt_acco BINARY SEARCH.
    CHECK sy-subrc = 0 AND <ls_lfa1>-j_1ipanno IS NOT INITIAL.

    APPEND INITIAL LINE TO lt_exkey ASSIGNING FIELD-SYMBOL(<ls_ek>).
    <ls_ek>-bukrs     = <ls_wi>-bukrs.
    <ls_ek>-koart     = gc_koart_vendor.
    <ls_ek>-accno     = <ls_wi>-wt_acco.
    <ls_ek>-witht     = <ls_wi>-witht.
    <ls_ek>-wt_withcd = <ls_wi>-wt_withcd.
    <ls_ek>-pan_no    = <ls_lfa1>-j_1ipanno.

  ENDLOOP.

  SORT lt_exkey BY bukrs koart accno witht wt_withcd pan_no.
  DELETE ADJACENT DUPLICATES FROM lt_exkey
         COMPARING bukrs koart accno witht wt_withcd pan_no.

  IF lt_exkey IS NOT INITIAL.
    SELECT bukrs, koart, accno, fiwtin_tanex_sub, seccode, witht,
           wt_withcd, wt_exdf, pan_no, wt_exdt, wt_exnr, fiwtin_exem_thr
      FROM fiwtin_tan_exem
      FOR ALL ENTRIES IN @lt_exkey
      WHERE bukrs     = @lt_exkey-bukrs
        AND koart     = @lt_exkey-koart
        AND accno     = @lt_exkey-accno
        AND witht     = @lt_exkey-witht
        AND wt_withcd = @lt_exkey-wt_withcd
        AND pan_no    = @lt_exkey-pan_no
      INTO TABLE @gt_tanex.
  ENDIF.

* Sorted so that the validity scan can binary search the six restricting
* fields and then walk the certificates of that vendor in ascending
* valid-from order - the last one that qualifies is the latest one.
* SECCODE and FIWTIN_TANEX_SUB are key fields of FIWTIN_TAN_EXEM that
* this report does not restrict on, so they are APPENDED on the right:
* the six restricting fields stay leading, which keeps the BINARY SEARCH
* in READ_EXEMPTION a proper prefix of the sort, WT_EXDF stays ahead of
* them so "latest valid-from wins" still holds, and no two rows can tie.
  SORT gt_tanex BY bukrs koart accno witht wt_withcd pan_no
                   wt_exdf seccode fiwtin_tanex_sub.

  IF lt_exkey IS NOT INITIAL.
    SELECT bukrs, accno, witht, wt_withcd, secco, wt_date, koart, pan_no,
           acc_amt
      FROM fiwtin_acc_exem
      FOR ALL ENTRIES IN @lt_exkey
      WHERE bukrs     = @lt_exkey-bukrs
        AND accno     = @lt_exkey-accno
        AND witht     = @lt_exkey-witht
        AND wt_withcd = @lt_exkey-wt_withcd
        AND koart     = @lt_exkey-koart
        AND pan_no    = @lt_exkey-pan_no
      INTO TABLE @gt_accex.
  ENDIF.

* SECCO is the unrestricted key field of FIWTIN_ACC_EXEM and is appended
* on the right for the same reason: the six restricting fields stay
* leading so the BINARY SEARCH in READ_CUMULATIVE is a proper prefix,
* WT_DATE stays ahead of SECCO so the walk remains ascending by date,
* and two rows accumulated under different section codes on the same
* date can no longer resolve in undefined order.
  SORT gt_accex BY bukrs accno witht wt_withcd koart pan_no
                   wt_date secco.

ENDFORM.

*&---------------------------------------------------------------------*
*& GL derivation for every document of the driver set - the "GLCode
*& Logic" tab of the FS.
*&
*& Two branches. A document whose reference transaction is RMRP came from
*& logistics invoice verification and is resolved through the purchase
*& order; every other document is a direct FI posting and is resolved
*& from the offsetting account of its own withholding line.
*&
*& The FS calls RMRP a value of AWKEY. It is not - RMRP is a value of
*& BKPF-AWTYP, and AWKEY is the 20 character reference key from which the
*& logistics invoice number and year are cut. The test is on AWTYP.
*&
*& Nothing here issues a message. A document that cannot be resolved is
*& collected in GT_GLMSG, keeps its row in the output with columns F and
*& G blank, and is counted once in REPORT_GL_GAPS.
*&---------------------------------------------------------------------*
FORM derive_gl_codes.

  DATA: lv_gl     TYPE bseg-hkont,
        lv_reason TYPE string.

  CLEAR: gt_glmap, gt_glmsg, gt_glamb.

  PERFORM fetch_mm_data.

  LOOP AT gt_dockey ASSIGNING FIELD-SYMBOL(<ls_dk>).

    CLEAR: lv_gl, lv_reason.

    READ TABLE gt_bkpf ASSIGNING FIELD-SYMBOL(<ls_bkpf>)
         WITH KEY bukrs = <ls_dk>-bukrs
                  belnr = <ls_dk>-belnr
                  gjahr = <ls_dk>-gjahr
         BINARY SEARCH.

    IF sy-subrc <> 0.
      lv_reason = 'Document header not found'.
    ELSEIF <ls_bkpf>-awtyp = gc_awtyp_rmrp AND <ls_bkpf>-awkey IS NOT INITIAL.
*     Logistics invoice. An RMRP header with an empty reference key
*     carries nothing to follow, so it falls through to the direct
*     branch rather than failing outright.
      PERFORM derive_gl_rmrp USING    <ls_bkpf>
                             CHANGING lv_gl
                                      lv_reason.
    ELSE.
      PERFORM derive_gl_direct USING    <ls_dk>
                               CHANGING lv_gl
                                        lv_reason.
    ENDIF.

    IF lv_gl IS INITIAL.
      APPEND INITIAL LINE TO gt_glmsg ASSIGNING FIELD-SYMBOL(<ls_msg>).
      <ls_msg>-bukrs  = <ls_dk>-bukrs.
      <ls_msg>-belnr  = <ls_dk>-belnr.
      <ls_msg>-gjahr  = <ls_dk>-gjahr.
      <ls_msg>-reason = lv_reason.
    ELSE.
      APPEND INITIAL LINE TO gt_glmap ASSIGNING FIELD-SYMBOL(<ls_map>).
      <ls_map>-bukrs   = <ls_dk>-bukrs.
      <ls_map>-belnr   = <ls_dk>-belnr.
      <ls_map>-gjahr   = <ls_dk>-gjahr.
      <ls_map>-gl_code = lv_gl.
    ENDIF.

  ENDLOOP.

  SORT gt_glmap BY bukrs belnr gjahr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Read everything the logistics invoice branch needs, set based and
*& before the per-document resolution runs.
*&
*& Four reads in sequence, each narrowing the next: the invoice items of
*& the RMRP documents, the account assignments of the purchase order
*& items they reference, the valuation segments of the materials that
*& have no usable account assignment, and finally the account
*& determination for the valuation classes those segments carry.
*&
*& The valuation segment is read for the invoice item's own valuation
*& area (RSEG-BWKEY), which is correct under both plant level and company
*& code level valuation - RSEG-WERKS, which the FS names, is only correct
*& under plant level valuation.
*&---------------------------------------------------------------------*
FORM fetch_mm_data.

  CONSTANTS lc_digits TYPE string VALUE '0123456789'.

  DATA: lt_mmkey   TYPE tt_mmkey,
        lt_pokey   TYPE tt_ekkn,
        lt_matkey  TYPE tt_mbew,
        lt_t030key TYPE tt_t030,
        lv_gjahr   TYPE rseg-gjahr,
        lv_gj4     TYPE c LENGTH 4,
        lv_sakto   TYPE ekkn-sakto.

  CLEAR: gt_rseg, gt_ekkn, gt_mbew, gt_t030.

* Logistics invoice keys, cut out of the reference key of the header.
  LOOP AT gt_bkpf ASSIGNING FIELD-SYMBOL(<ls_bkpf>).

    CHECK <ls_bkpf>-awtyp = gc_awtyp_rmrp AND <ls_bkpf>-awkey IS NOT INITIAL.

    CLEAR lv_gjahr.
    lv_gj4 = <ls_bkpf>-awkey+gc_awkey_gjahr_off(gc_awkey_gjahr_len).
    IF lv_gj4 CO lc_digits.
      lv_gjahr = lv_gj4.
    ENDIF.
    IF lv_gjahr IS INITIAL.
      lv_gjahr = <ls_bkpf>-gjahr.       " reference key carries no usable year
    ENDIF.

    APPEND INITIAL LINE TO lt_mmkey ASSIGNING FIELD-SYMBOL(<ls_mk>).
    <ls_mk>-belnr = <ls_bkpf>-awkey+gc_awkey_belnr_off(gc_awkey_belnr_len).
    <ls_mk>-gjahr = lv_gjahr.

  ENDLOOP.

  SORT lt_mmkey BY belnr gjahr.
  DELETE ADJACENT DUPLICATES FROM lt_mmkey COMPARING belnr gjahr.

  IF lt_mmkey IS INITIAL.
    RETURN.                             " no logistics invoice in this run
  ENDIF.

  SELECT belnr, gjahr, buzei, bukrs, ebeln, ebelp, zekkn, matnr,
         werks, bwtar          " FS [H27]: the plant is the MBEW valuation area
    FROM rseg
    FOR ALL ENTRIES IN @lt_mmkey
    WHERE belnr = @lt_mmkey-belnr
      AND gjahr = @lt_mmkey-gjahr
    INTO TABLE @gt_rseg.

* Ascending item number, so the resolution loop finds the lowest item of
* an invoice first.
  SORT gt_rseg BY belnr gjahr buzei.

  IF gt_rseg IS INITIAL.
    RETURN.
  ENDIF.

* Purchase order account assignments.
  LOOP AT gt_rseg ASSIGNING FIELD-SYMBOL(<ls_rseg>).
    CHECK <ls_rseg>-ebeln IS NOT INITIAL.
    APPEND INITIAL LINE TO lt_pokey ASSIGNING FIELD-SYMBOL(<ls_pk>).
    <ls_pk>-ebeln = <ls_rseg>-ebeln.
    <ls_pk>-ebelp = <ls_rseg>-ebelp.
  ENDLOOP.

  SORT lt_pokey BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_pokey COMPARING ebeln ebelp.

  IF lt_pokey IS NOT INITIAL.
    SELECT ebeln, ebelp, zekkn, sakto
      FROM ekkn
      FOR ALL ENTRIES IN @lt_pokey
      WHERE ebeln = @lt_pokey-ebeln
        AND ebelp = @lt_pokey-ebelp
      INTO TABLE @gt_ekkn.
  ENDIF.

  SORT gt_ekkn BY ebeln ebelp zekkn.

* Valuation segments, but only for the invoice items that will actually
* need them - an item whose purchase order already carries a filled
* account assignment never reaches the material route.
  LOOP AT gt_rseg ASSIGNING <ls_rseg>.

    CHECK <ls_rseg>-matnr IS NOT INITIAL AND <ls_rseg>-werks IS NOT INITIAL.

    IF <ls_rseg>-ebeln IS NOT INITIAL.
      PERFORM read_ekkn_gl USING    <ls_rseg>-ebeln
                                    <ls_rseg>-ebelp
                                    <ls_rseg>-zekkn
                           CHANGING lv_sakto.
      CHECK lv_sakto IS INITIAL.
    ENDIF.

    APPEND INITIAL LINE TO lt_matkey ASSIGNING FIELD-SYMBOL(<ls_mt>).
    <ls_mt>-matnr = <ls_rseg>-matnr.
    <ls_mt>-bwkey = <ls_rseg>-werks.
    <ls_mt>-bwtar = <ls_rseg>-bwtar.

*   A split valuated item also needs the header segment, so the retry
*   with a blank valuation type can be answered from the buffer instead
*   of from a second database read.
    IF <ls_rseg>-bwtar IS NOT INITIAL.
      APPEND INITIAL LINE TO lt_matkey ASSIGNING <ls_mt>.
      <ls_mt>-matnr = <ls_rseg>-matnr.
      <ls_mt>-bwkey = <ls_rseg>-werks.
    ENDIF.

  ENDLOOP.

  SORT lt_matkey BY matnr bwkey bwtar.
  DELETE ADJACENT DUPLICATES FROM lt_matkey COMPARING matnr bwkey bwtar.

  IF lt_matkey IS NOT INITIAL.
    SELECT matnr, bwkey, bwtar, lvorm, bklas
      FROM mbew
      FOR ALL ENTRIES IN @lt_matkey
      WHERE matnr = @lt_matkey-matnr
        AND bwkey = @lt_matkey-bwkey
        AND bwtar = @lt_matkey-bwtar
      INTO TABLE @gt_mbew.
  ENDIF.

  SORT gt_mbew BY matnr bwkey bwtar.

  IF gt_mbew IS INITIAL.
    RETURN.
  ENDIF.

* Account determination. The read is not selective on the valuation
* grouping code or the account modifier: the valuation grouping code
* would have to come from T001K-BWMOD, a field this build has not been
* able to verify, and compiling against an unverified field is worse than
* resolving the ambiguity here. The sort puts the blank grouping code and
* the blank account modifier first, so the binary search below returns
* the general entry and only falls back to a specific one if that is all
* there is.
  LOOP AT gt_t001 ASSIGNING FIELD-SYMBOL(<ls_t001>).

    CHECK <ls_t001>-ktopl IS NOT INITIAL.

    LOOP AT gt_mbew ASSIGNING FIELD-SYMBOL(<ls_mbew>).
      CHECK <ls_mbew>-bklas IS NOT INITIAL.
      APPEND INITIAL LINE TO lt_t030key ASSIGNING FIELD-SYMBOL(<ls_tk>).
      <ls_tk>-ktopl = <ls_t001>-ktopl.
      <ls_tk>-ktosl = gc_ktosl_bsx.
      <ls_tk>-bklas = <ls_mbew>-bklas.
    ENDLOOP.

  ENDLOOP.

  SORT lt_t030key BY ktopl ktosl bklas.
  DELETE ADJACENT DUPLICATES FROM lt_t030key COMPARING ktopl ktosl bklas.

  IF lt_t030key IS NOT INITIAL.
*   " ASSUMPTION: T030 is read on KTOPL / KTOSL / BKLAS only. BWMOD is
*   left out because T001K-BWMOD could not be verified; the blank
*   valuation grouping code wins, and any remaining ambiguity is logged
*   in GT_GLAMB and reported by REPORT_GL_GAPS. QUERIES Q3.
    SELECT ktopl, ktosl, bwmod, komok, bklas, konts
      FROM t030
      FOR ALL ENTRIES IN @lt_t030key
      WHERE ktopl = @lt_t030key-ktopl
        AND ktosl = @lt_t030key-ktosl
        AND bklas = @lt_t030key-bklas
      INTO TABLE @gt_t030.
  ENDIF.

  SORT gt_t030 BY ktopl ktosl bklas bwmod komok.

ENDFORM.

*&---------------------------------------------------------------------*
*& Direct FI posting: the GL is the offsetting account of the document's
*& own withholding tax line.
*&
*& GT_BSEG is sorted by item number, so the first withholding line that
*& carries an offsetting account is the one with the lowest BUZEI.
*& " ASSUMPTION: on a document with several withholding lines pointing at
*& different offsetting accounts, the lowest item number is shown - the
*& row granularity of this report allows exactly one GL per document.
*&---------------------------------------------------------------------*
FORM derive_gl_direct USING    ps_dockey TYPE ty_dockey
                      CHANGING pv_gl     TYPE bseg-hkont
                               pv_reason TYPE string.

  DATA: lv_idx TYPE sy-tabix,
        lv_wit TYPE abap_bool.

  CLEAR: pv_gl, pv_reason, lv_wit.

  READ TABLE gt_bseg TRANSPORTING NO FIELDS
       WITH KEY bukrs = ps_dockey-bukrs
                belnr = ps_dockey-belnr
                gjahr = ps_dockey-gjahr
       BINARY SEARCH.

  IF sy-subrc <> 0.
    pv_reason = 'No line items found for the document'.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

  LOOP AT gt_bseg ASSIGNING FIELD-SYMBOL(<ls_bseg>) FROM lv_idx.

    IF <ls_bseg>-bukrs <> ps_dockey-bukrs
    OR <ls_bseg>-belnr <> ps_dockey-belnr
    OR <ls_bseg>-gjahr <> ps_dockey-gjahr.
      EXIT.
    ENDIF.

    CHECK <ls_bseg>-ktosl = gc_ktosl_wit.
    lv_wit = abap_true.

    IF <ls_bseg>-ghkon IS NOT INITIAL AND pv_gl IS INITIAL.
      pv_gl = <ls_bseg>-ghkon.
    ENDIF.

  ENDLOOP.

  IF pv_gl IS INITIAL.
    IF lv_wit = abap_true.
      pv_reason = 'Withholding line carries no offsetting GL account'.
    ELSE.
*     KTOSL is filled by automatic account determination. A manually
*     posted withholding line can carry a blank transaction key, which
*     lands here rather than in an incorrect GL.
      pv_reason = 'Document has no withholding line with transaction key WIT'.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Logistics invoice: follow the reference key to the invoice item, then
*& to the purchase order.
*&
*& An item with a filled account assignment takes the account from the
*& purchase order. An item without one is a stock posting and takes the
*& account from the automatic account determination of the material's
*& valuation class.
*&
*& " ASSUMPTION: an invoice with several items resolves through its
*& lowest item number. The FS is silent and this report shows one GL per
*& document.
*&---------------------------------------------------------------------*
FORM derive_gl_rmrp USING    ps_bkpf   TYPE ty_bkpf
                    CHANGING pv_gl     TYPE bseg-hkont
                             pv_reason TYPE string.

  CONSTANTS lc_digits TYPE string VALUE '0123456789'.

  DATA: ls_item  TYPE ty_rseg,
        lv_belnr TYPE rseg-belnr,
        lv_gjahr TYPE rseg-gjahr,
        lv_gj4   TYPE c LENGTH 4,
        lv_idx   TYPE sy-tabix,
        lv_t030  TYPE sy-tabix,
        lv_amb   TYPE abap_bool,
        lv_found TYPE abap_bool,
        lv_sakto TYPE ekkn-sakto,
        lv_bklas TYPE mbew-bklas.

  CLEAR: pv_gl, pv_reason, ls_item, lv_found, lv_amb.

  lv_belnr = ps_bkpf-awkey+gc_awkey_belnr_off(gc_awkey_belnr_len).

  lv_gj4 = ps_bkpf-awkey+gc_awkey_gjahr_off(gc_awkey_gjahr_len).
  IF lv_gj4 CO lc_digits.
    lv_gjahr = lv_gj4.
  ENDIF.
  IF lv_gjahr IS INITIAL.
    lv_gjahr = ps_bkpf-gjahr.
  ENDIF.

  READ TABLE gt_rseg TRANSPORTING NO FIELDS
       WITH KEY belnr = lv_belnr
                gjahr = lv_gjahr
       BINARY SEARCH.

  IF sy-subrc <> 0.
    pv_reason = 'Logistics invoice of the reference key not found'.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

* Lowest item of the invoice that belongs to the document's own company
* code. RSEG carries BUKRS itself, so no detour over RBKP is needed.
  LOOP AT gt_rseg ASSIGNING FIELD-SYMBOL(<ls_rseg>) FROM lv_idx.

    IF <ls_rseg>-belnr <> lv_belnr OR <ls_rseg>-gjahr <> lv_gjahr.
      EXIT.
    ENDIF.

    CHECK <ls_rseg>-bukrs = ps_bkpf-bukrs.

    ls_item  = <ls_rseg>.
    lv_found = abap_true.
    EXIT.

  ENDLOOP.

  IF lv_found = abap_false.
    pv_reason = 'Logistics invoice has no item for this company code'.
    RETURN.
  ENDIF.

* Purchase order account assignment. "EKKN is not blank" is read as
* "a row exists whose SAKTO is filled", not merely "a row exists".
  IF ls_item-ebeln IS NOT INITIAL.

    PERFORM read_ekkn_gl USING    ls_item-ebeln
                                  ls_item-ebelp
                                  ls_item-zekkn
                         CHANGING lv_sakto.

    IF lv_sakto IS NOT INITIAL.
      pv_gl = lv_sakto.
      RETURN.
    ENDIF.

  ENDIF.

* Stock posting: valuation class of the material, then the automatic
* account determination.
  IF ls_item-matnr IS INITIAL.
    pv_reason = 'Invoice item has no account assignment and no material'.
    RETURN.
  ENDIF.

  PERFORM read_bklas USING    ls_item-matnr
                              ls_item-werks    " FS [H27]: BWKEY = RSEG-WERKS
                              ls_item-bwtar
                     CHANGING lv_bklas.

  IF lv_bklas IS INITIAL.
    pv_reason = 'No valuation class for the material of the invoice item'.
    RETURN.
  ENDIF.

  READ TABLE gt_t001 ASSIGNING FIELD-SYMBOL(<ls_t001>)
       WITH KEY bukrs = ps_bkpf-bukrs BINARY SEARCH.

  IF sy-subrc <> 0.
    pv_reason = 'No chart of accounts for the company code'.
    RETURN.
  ENDIF.

  IF <ls_t001>-ktopl IS INITIAL.
    pv_reason = 'No chart of accounts for the company code'.
    RETURN.
  ENDIF.

* The buffer is sorted so that the blank valuation grouping code and the
* blank account modifier come first, which makes the binary search return
* the general entry wherever one exists.
  READ TABLE gt_t030 ASSIGNING FIELD-SYMBOL(<ls_t030>)
       WITH KEY ktopl = <ls_t001>-ktopl
                ktosl = gc_ktosl_bsx
                bklas = lv_bklas
       BINARY SEARCH.

  IF sy-subrc <> 0.
    pv_reason = 'No account determination (BSX) for the valuation class'.
    RETURN.
  ENDIF.

  lv_t030 = sy-tabix.

  IF <ls_t030>-konts IS INITIAL.
    pv_reason = 'Account determination (BSX) carries no debit account'.
    RETURN.
  ENDIF.

  pv_gl = <ls_t030>-konts.

* The general entry - blank valuation grouping code AND blank account
* modifier - sorts first and is unambiguous, so nothing is logged where
* one exists. Only where none does is the first entry of the sort order
* taken: the valuation grouping code cannot be read here because
* T001K-BWMOD is unverified on this landscape. If a second entry of the
* same valuation class then carries a DIFFERENT account, the document is
* logged. A plausible but wrong GL account on a compliance report must
* never be silent - REPORT_GL_GAPS counts GT_GLAMB.
  IF <ls_t030>-bwmod IS NOT INITIAL OR <ls_t030>-komok IS NOT INITIAL.

    LOOP AT gt_t030 ASSIGNING FIELD-SYMBOL(<ls_t030b>) FROM lv_t030.

      IF <ls_t030b>-ktopl <> <ls_t001>-ktopl
      OR <ls_t030b>-ktosl <> gc_ktosl_bsx
      OR <ls_t030b>-bklas <> lv_bklas.
        EXIT.
      ENDIF.

      IF <ls_t030b>-konts <> <ls_t030>-konts.
        lv_amb = abap_true.
        EXIT.
      ENDIF.

    ENDLOOP.

  ENDIF.

  IF lv_amb = abap_true.
*   " ASSUMPTION: no general BSX entry exists for this valuation class
*   and the valuation grouping code is not read, so the lowest grouping
*   code is shown and the document is flagged. QUERIES.md carries the
*   question for Bhavin Suthar - is a valuation grouping code active?
    APPEND INITIAL LINE TO gt_glamb ASSIGNING FIELD-SYMBOL(<ls_amb>).
    <ls_amb>-bukrs  = ps_bkpf-bukrs.
    <ls_amb>-belnr  = ps_bkpf-belnr.
    <ls_amb>-gjahr  = ps_bkpf-gjahr.
    <ls_amb>-reason = |BSX account determination not unique for | &&
                      |valuation class { lv_bklas } - lowest | &&
                      |valuation grouping code shown|.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Account of a purchase order item.
*&
*& The invoice item names the account assignment number it was posted
*& against, so that one is preferred. Where the invoice item does not
*& name one - or where the one it names has no account - the lowest
*& numbered assignment carrying an account is taken.
*& " ASSUMPTION: on a multiple account assignment purchase order the
*& lowest assignment number is shown; the report has one GL per document.
*&---------------------------------------------------------------------*
FORM read_ekkn_gl USING    pv_ebeln TYPE ekkn-ebeln
                           pv_ebelp TYPE ekkn-ebelp
                           pv_zekkn TYPE ekkn-zekkn
                  CHANGING pv_sakto TYPE ekkn-sakto.

  DATA lv_idx TYPE sy-tabix.

  CLEAR pv_sakto.

  IF pv_ebeln IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE gt_ekkn TRANSPORTING NO FIELDS
       WITH KEY ebeln = pv_ebeln
                ebelp = pv_ebelp
       BINARY SEARCH.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

  IF pv_zekkn IS NOT INITIAL.

    LOOP AT gt_ekkn ASSIGNING FIELD-SYMBOL(<ls_ekkn>) FROM lv_idx.
      IF <ls_ekkn>-ebeln <> pv_ebeln OR <ls_ekkn>-ebelp <> pv_ebelp.
        EXIT.
      ENDIF.
      IF <ls_ekkn>-zekkn = pv_zekkn AND <ls_ekkn>-sakto IS NOT INITIAL.
        pv_sakto = <ls_ekkn>-sakto.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDIF.

  LOOP AT gt_ekkn ASSIGNING <ls_ekkn> FROM lv_idx.
    IF <ls_ekkn>-ebeln <> pv_ebeln OR <ls_ekkn>-ebelp <> pv_ebelp.
      EXIT.
    ENDIF.
    IF <ls_ekkn>-sakto IS NOT INITIAL.
      pv_sakto = <ls_ekkn>-sakto.
      EXIT.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Valuation class of a material in a valuation area.
*&
*& Preference order: the invoice item's own valuation type on an active
*& segment, then any other active segment of the same valuation area
*& (which is the header segment for a split valuated material), and only
*& if neither exists a segment flagged for deletion. Losing the GL
*& entirely because the valuation segment carries a deletion flag would
*& be worse than reporting the class it still holds.
*&---------------------------------------------------------------------*
FORM read_bklas USING    pv_matnr TYPE mbew-matnr
                         pv_bwkey TYPE mbew-bwkey
                         pv_bwtar TYPE mbew-bwtar
                CHANGING pv_bklas TYPE mbew-bklas.

  DATA lv_idx TYPE sy-tabix.

  CLEAR pv_bklas.

  IF pv_matnr IS INITIAL OR pv_bwkey IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE gt_mbew TRANSPORTING NO FIELDS
       WITH KEY matnr = pv_matnr
                bwkey = pv_bwkey
       BINARY SEARCH.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

  LOOP AT gt_mbew ASSIGNING FIELD-SYMBOL(<ls_mbew>) FROM lv_idx.

    IF <ls_mbew>-matnr <> pv_matnr OR <ls_mbew>-bwkey <> pv_bwkey.
      EXIT.
    ENDIF.

    CHECK <ls_mbew>-bklas IS NOT INITIAL AND <ls_mbew>-lvorm <> gc_x.

    IF <ls_mbew>-bwtar = pv_bwtar.
      pv_bklas = <ls_mbew>-bklas.
      RETURN.
    ENDIF.

    IF pv_bklas IS INITIAL.
      pv_bklas = <ls_mbew>-bklas.
    ENDIF.

  ENDLOOP.

  IF pv_bklas IS NOT INITIAL.
    RETURN.
  ENDIF.

  LOOP AT gt_mbew ASSIGNING <ls_mbew> FROM lv_idx.
    IF <ls_mbew>-matnr <> pv_matnr OR <ls_mbew>-bwkey <> pv_bwkey.
      EXIT.
    ENDIF.
    IF <ls_mbew>-bklas IS NOT INITIAL.
      pv_bklas = <ls_mbew>-bklas.
      EXIT.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Exemption certificate valid for one withholding item - columns U, V,
*& W and X.
*&
*& " ASSUMPTION: the certificate shown is the one whose validity period
*& contains the posting date of the document and whose tax type and tax
*& code match the item; where several still qualify, the one with the
*& latest valid-from date, and among those the one carrying the
*& document's own section code. This is build contract D5, and it is the
*& point to raise with the functional side first - a certificate row with
*& an empty valid-to date does NOT qualify under this rule and its four
*& columns stay blank.
*&
*& " ASSUMPTION: the report is NOT section code specific. SECCODE and
*& FIWTIN_TANEX_SUB are key fields of FIWTIN_TAN_EXEM that neither the FS
*& nor build contract D5 restricts on, so a vendor holding separate
*& certificates per section code is reported from one of them. The
*& section code is used here only to BREAK A TIE between certificates
*& sharing a valid-from date, never to remove a row - restricting on it
*& would blank all four columns for every document whose line carries no
*& section code. docs/QUERIES.md carries the question for Ankita Parikh;
*& only her answer turns SECCODE into a filter.
*&
*& The four columns are blank together for any vendor with no
*& certificate, which is the normal case and not a defect.
*&---------------------------------------------------------------------*
FORM read_exemption USING    pv_bukrs  TYPE fiwtin_tan_exem-bukrs
                             pv_accno  TYPE fiwtin_tan_exem-accno
                             pv_witht  TYPE fiwtin_tan_exem-witht
                             pv_withcd TYPE fiwtin_tan_exem-wt_withcd
                             pv_pan    TYPE fiwtin_tan_exem-pan_no
                             pv_secco  TYPE fiwtin_tan_exem-seccode
                             pv_budat  TYPE bkpf-budat
                    CHANGING pv_exdf   TYPE fiwtin_tan_exem-wt_exdf
                             pv_exdt   TYPE fiwtin_tan_exem-wt_exdt
                             pv_thr    TYPE fiwtin_tan_exem-fiwtin_exem_thr
                             pv_cert   TYPE fiwtin_tan_exem-wt_exnr.

  DATA: lv_idx       TYPE sy-tabix,
        lv_taken     TYPE abap_bool,
        lv_seen_exdf TYPE fiwtin_tan_exem-wt_exdf,
        lv_seen_secc TYPE fiwtin_tan_exem-seccode.

  CLEAR: pv_exdf, pv_exdt, pv_thr, pv_cert,
         lv_taken, lv_seen_exdf, lv_seen_secc.

  IF pv_pan IS INITIAL OR pv_budat IS INITIAL OR gt_tanex IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE gt_tanex TRANSPORTING NO FIELDS
       WITH KEY bukrs     = pv_bukrs
                koart     = gc_koart_vendor
                accno     = pv_accno
                witht     = pv_witht
                wt_withcd = pv_withcd
                pan_no    = pv_pan
       BINARY SEARCH.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

* The buffer is sorted ascending by valid-from within the vendor's
* certificates, then by section code and sub-indicator, so the walk sees
* every qualifying certificate in a total order.
  LOOP AT gt_tanex ASSIGNING FIELD-SYMBOL(<ls_tanex>) FROM lv_idx.

    IF <ls_tanex>-bukrs     <> pv_bukrs
    OR <ls_tanex>-koart     <> gc_koart_vendor
    OR <ls_tanex>-accno     <> pv_accno
    OR <ls_tanex>-witht     <> pv_witht
    OR <ls_tanex>-wt_withcd <> pv_withcd
    OR <ls_tanex>-pan_no    <> pv_pan.
      EXIT.
    ENDIF.

    CHECK <ls_tanex>-wt_exdf <= pv_budat AND <ls_tanex>-wt_exdt >= pv_budat.

*   Latest valid-from wins (build contract D5). Among certificates that
*   share that valid-from - one per section code is the normal case -
*   the document's own section code is preferred. The first qualifying
*   row is always taken so a certificate with a blank valid-from is not
*   silently skipped.
    IF    lv_taken = abap_false
       OR <ls_tanex>-wt_exdf >  lv_seen_exdf
       OR (     <ls_tanex>-wt_exdf =  lv_seen_exdf
            AND <ls_tanex>-seccode =  pv_secco
            AND lv_seen_secc       <> pv_secco ).

      lv_taken     = abap_true.
      lv_seen_exdf = <ls_tanex>-wt_exdf.
      lv_seen_secc = <ls_tanex>-seccode.

      pv_exdf = <ls_tanex>-wt_exdf.             " col U
      pv_exdt = <ls_tanex>-wt_exdt.             " col V
*     " ASSUMPTION: col W shows the threshold AMOUNT, not a Y/N flag.
*     FS [W7] heads it "(Y/N)" but FS [W6] asks for the amount; blank
*     means no threshold maintained. QUERIES Q4.
      pv_thr  = <ls_tanex>-fiwtin_exem_thr.     " col W
      pv_cert = <ls_tanex>-wt_exnr.             " col X

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Accumulated base amount for the vendor - column Y.
*&
*& " ASSUMPTION: FIWTIN_ACC_EXEM already holds a running total, so the
*& row with the latest accumulation date not after the upper posting date
*& bound is shown as it stands. The rows are never summed - summing an
*& already accumulated table would multiply the figure, and this is a
*& compliance report where a plausible wrong number is the worst possible
*& failure.
*&
*& " ASSUMPTION: SECCO is a key field of FIWTIN_ACC_EXEM and the table
*& therefore accumulates per section code, but this report does NOT
*& restrict on it - the restricting fields are company code, account,
*& tax type, tax code, account type and PAN. Where two rows share the
*& latest accumulation date, the document's own section code breaks the
*& tie; the section code never removes a row, so a document line without
*& a section code still gets a figure. Which section code's accumulation
*& belongs on the row is the FIRST question for Ankita Parikh in
*& docs/QUERIES.md.
*&---------------------------------------------------------------------*
FORM read_cumulative USING    pv_bukrs  TYPE fiwtin_acc_exem-bukrs
                              pv_accno  TYPE fiwtin_acc_exem-accno
                              pv_witht  TYPE fiwtin_acc_exem-witht
                              pv_withcd TYPE fiwtin_acc_exem-wt_withcd
                              pv_pan    TYPE fiwtin_acc_exem-pan_no
                              pv_secco  TYPE fiwtin_acc_exem-secco
                              pv_hidate TYPE bkpf-budat
                     CHANGING pv_amt    TYPE fiwtin_acc_exem-acc_amt.

  DATA: lv_idx       TYPE sy-tabix,
        lv_taken     TYPE abap_bool,
        lv_seen_date TYPE fiwtin_acc_exem-wt_date,
        lv_seen_secc TYPE fiwtin_acc_exem-secco.

  CLEAR: pv_amt, lv_taken, lv_seen_date, lv_seen_secc.

  IF pv_pan IS INITIAL OR gt_accex IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE gt_accex TRANSPORTING NO FIELDS
       WITH KEY bukrs     = pv_bukrs
                accno     = pv_accno
                witht     = pv_witht
                wt_withcd = pv_withcd
                koart     = gc_koart_vendor
                pan_no    = pv_pan
       BINARY SEARCH.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_idx = sy-tabix.

  LOOP AT gt_accex ASSIGNING FIELD-SYMBOL(<ls_accex>) FROM lv_idx.

    IF <ls_accex>-bukrs     <> pv_bukrs
    OR <ls_accex>-accno     <> pv_accno
    OR <ls_accex>-witht     <> pv_witht
    OR <ls_accex>-wt_withcd <> pv_withcd
    OR <ls_accex>-koart     <> gc_koart_vendor
    OR <ls_accex>-pan_no    <> pv_pan.
      EXIT.
    ENDIF.

    CHECK <ls_accex>-wt_date <= pv_hidate.

*   Latest accumulation date wins. Among rows sharing that date - one
*   row per section code is the normal population - the document's own
*   section code is preferred. SECCO breaks the tie, it does not
*   restrict, so a line without a section code still yields the figure.
    IF    lv_taken = abap_false
       OR <ls_accex>-wt_date >  lv_seen_date
       OR (     <ls_accex>-wt_date =  lv_seen_date
            AND <ls_accex>-secco   =  pv_secco
            AND lv_seen_secc       <> pv_secco ).

      lv_taken     = abap_true.
      lv_seen_date = <ls_accex>-wt_date.
      lv_seen_secc = <ls_accex>-secco.

      pv_amt = <ls_accex>-acc_amt.      " col Y  taken as it stands, never summed

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Upper bound of the selected posting date period, used as the "as of"
*& date of the cumulative column.
*&
*& " ASSUMPTION: the highest date the posting date selection can still
*& report on is the reporting date. Which end of a row carries that date
*& depends on the row's OPTION, so the option is read rather than the
*& two date fields being compared blindly: BT bounds the period with
*& HIGH, EQ / LE / LT bound it with LOW, and GE / GT / NE / NB / CP name
*& no upper bound at all and contribute today.
*&
*& Only INCLUDE rows are read. An EXCLUDE row names dates that are NOT
*& reported on and must never raise the reporting date - reading it would
*& overstate column Y.
*&
*& Every row contributes a candidate and the maximum wins, so a mixed
*& selection of a bounded and an open-ended row does not lose the higher
*& bounded date. A selection with no upper bound at all falls back to
*& today, which is what this comment has always claimed.
*&---------------------------------------------------------------------*
FORM budat_upper CHANGING pv_date TYPE bkpf-budat.

  CONSTANTS: lc_option_eq TYPE c LENGTH 2 VALUE 'EQ',
             lc_option_le TYPE c LENGTH 2 VALUE 'LE',
             lc_option_lt TYPE c LENGTH 2 VALUE 'LT'.

  DATA lv_cand TYPE bkpf-budat.

  CLEAR pv_date.

  LOOP AT s_budat INTO DATA(ls_budat) WHERE sign = gc_sign_incl.

    CLEAR lv_cand.

    CASE ls_budat-option.
      WHEN gc_option_bt.                          " upper bound is HIGH
        lv_cand = ls_budat-high.
      WHEN lc_option_eq OR lc_option_le OR lc_option_lt.
        lv_cand = ls_budat-low.                   " upper bound is LOW
      WHEN OTHERS.                                " GE / GT / NE / NB / CP - no upper bound
        lv_cand = sy-datum.
    ENDCASE.

    IF lv_cand > pv_date.
      pv_date = lv_cand.
    ENDIF.

  ENDLOOP.

  IF pv_date IS INITIAL.                          " every row excluded, or BT with a blank To
    pv_date = sy-datum.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& One aggregated diagnostic message for the whole run. It covers three
*& things, not one:
*&   GT_GLMSG   documents whose GL could not be derived at all
*&   GT_GLAMB   documents whose BSX account determination was not unique
*&   GV_NOBSEG  withholding items the section code filter had to discard
*&              because no vendor line could be resolved for them
*&
*& The affected rows themselves stay in the list wherever they can - a
*& document with no GL keeps its row with columns F and G blank, because
*& the withholding figures are valid and reportable without a GL.
*&
*& ONE message, not three: only the last status message survives on the
*& list screen, so a second MESSAGE would silently hide the first.
*& Issuing it here, and never inside the row loop, is what keeps a report
*& over tens of thousands of rows from turning into tens of thousands of
*& status lines.
*&---------------------------------------------------------------------*
FORM report_gl_gaps.

* The status bar renders roughly 200 characters and truncates the rest
* without telling the user, so the folded message is capped short of it.
  CONSTANTS lc_msg_max TYPE i VALUE 170.

  DATA lv_text TYPE string.

  IF gt_glmsg IS INITIAL AND gt_glamb IS INITIAL AND gv_nosect IS INITIAL.
    RETURN.
  ENDIF.

  IF gt_glmsg IS NOT INITIAL.
    lv_text = |GL could not be derived for { lines( gt_glmsg ) } document(s)|.
  ENDIF.

  IF gt_glamb IS NOT INITIAL.
    IF lv_text IS INITIAL.
      lv_text = |GL determination not unique for { lines( gt_glamb ) } document(s)|.
    ELSE.
      lv_text = |{ lv_text }; not unique for { lines( gt_glamb ) }|.
    ENDIF.
  ENDIF.

*BOC By Arnav on 07/09/26
*  IF gv_nobseg > 0.
*    IF lv_text IS INITIAL.
*      lv_text = |{ gv_nobseg } item(s) skipped by the section code filter - vendor line not found|.
*    ELSE.
*      lv_text = |{ lv_text }; { gv_nobseg } item(s) skipped, vendor line not found|.
*    ENDIF.
*  ENDIF.
  IF gv_nosect > 0.
    IF lv_text IS INITIAL.
      lv_text = |{ gv_nosect } item(s) skipped by the section filter - no T059Z entry|.
    ELSE.
      lv_text = |{ lv_text }; { gv_nosect } item(s) skipped, no T059Z entry|.
    ENDIF.
  ENDIF.
*EOC By Arnav on 07/09/26

* The counts on their own leave the user no way to tell a missing
* GHKON from a missing logistics invoice, and columns F and G are blank
* either way. DERIVE_GL_* already records a reason per document, so the
* DISTINCT reasons are folded in here - otherwise the REASON component
* is collected on every failed document and never reaches anyone.
  DATA(lt_why) = gt_glmsg.
  APPEND LINES OF gt_glamb TO lt_why.

  IF lt_why IS NOT INITIAL.

    SORT lt_why BY reason.
    DELETE ADJACENT DUPLICATES FROM lt_why COMPARING reason.

    LOOP AT lt_why ASSIGNING FIELD-SYMBOL(<ls_why>).
      IF strlen( lv_text ) + strlen( <ls_why>-reason ) > lc_msg_max.
        lv_text = |{ lv_text } ...|.
        EXIT.
      ENDIF.
      lv_text = |{ lv_text } / { <ls_why>-reason }|.
    ENDLOOP.

  ENDIF.

  MESSAGE lv_text TYPE 'S' DISPLAY LIKE 'W'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Build and show the output list.
*&
*& CL_SALV_TABLE, because the list has no editable cells, no cell styles
*& and no toolbar events. A container would make the object paste-only
*& for ever and the FS does not ask for one.
*&
*& Every visible column gets a PERFORM TXT call. A column without one
*& falls back to its dictionary label or, worse, to its technical name.
*& WAERS is the exception - it is set technical, not headed. It is NOT
*& linked to the four amount columns: CL_SALV_COLUMN_LIST=>
*& SET_CURRENCY_COLUMN is unverified on this release and the build
*& decision is not to use it until SE24 confirms it.
*&---------------------------------------------------------------------*
FORM display_alv.

  DATA lx_salv TYPE REF TO cx_root.

  TRY.

      cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                              CHANGING  t_table      = gt_output ).

      go_alv->get_functions( )->set_all( ).

      DATA(lo_cols) = go_alv->get_columns( ).
      lo_cols->set_optimize( ).

      PERFORM txt USING lo_cols 'SR'        'Sr'.
      PERFORM txt USING lo_cols 'BELNR'     'Document number'.
      PERFORM txt USING lo_cols 'LIFNR'     'Vendor Code'.
      PERFORM txt USING lo_cols 'NAME1'     'Vendor Name'.
      PERFORM txt USING lo_cols 'PAN_NO'    'Vendor PAN'.
      PERFORM txt USING lo_cols 'GL_CODE'   'GL Code'.
      PERFORM txt USING lo_cols 'GL_NAME'   'GL Name'.
      PERFORM txt USING lo_cols 'SECTION'   'Section'.
      PERFORM txt USING lo_cols 'SEC_DESC'  'Section Code Description'.
      PERFORM txt USING lo_cols 'NATURE'    'Nature of Payment'.
      PERFORM txt USING lo_cols 'BUDAT'     'Document Date (SAP)'.
      PERFORM txt USING lo_cols 'XBLNR'     'Invoice No.'.
      PERFORM txt USING lo_cols 'BLDAT'     'Invoice Date'.
      PERFORM txt USING lo_cols 'AUGBL'     'Payment Doc No.'.
      PERFORM txt USING lo_cols 'AUGDT'     'Payment Date'.
      PERFORM txt USING lo_cols 'BASE_AMT'  'Base Amount'.
      PERFORM txt USING lo_cols 'TAXCODE'   'Tax Code'.
      PERFORM txt USING lo_cols 'RATE_SEC'  'TDS Rate as per section'.
      PERFORM txt USING lo_cols 'RATE_DED'  'TDS Rate deducted'.
      PERFORM txt USING lo_cols 'TDS_AMT'   'TDS Amount'.
      PERFORM txt USING lo_cols 'EXDF'      'Valid From'.
      PERFORM txt USING lo_cols 'EXDT'      'Valid To'.
*     ONE heading deviates from the FS wording on purpose: the FS spells
*     "Ceritificate" and the heading ships corrected. Col W keeps the FS
*     heading unchanged even though it reads "(Y/N)" while the FS
*     description [W6] asks for the threshold AMOUNT - the contradiction
*     is the FS's own, it is what the reviewers have to see and sign off
*     with Ankita Parikh, and it is logged in docs/QUERIES.md rather
*     than resolved silently in the layout.
*     The two are deliberately NOT treated alike. A misspelling has one
*     defensible reading and correcting it changes nothing anyone has to
*     decide; an unresolved question about what a column CONTAINS has to
*     stay visible until the business answers it. Both are in QUERIES.md
*     as Q13 and Q4.
      PERFORM txt USING lo_cols 'THRESHOLD' 'Threshold Applicability (Y/N)'.
      PERFORM txt USING lo_cols 'CERT_NO'   'Certificate Number'.
      PERFORM txt USING lo_cols 'CUM_AMT'   'Cumulative Amount as of now for FY'.
*BOC By Arnav on 07/09/26
      PERFORM txt USING lo_cols 'DRCR'      'Debit/Credit'.
*EOC By Arnav on 07/09/26

*     Company code currency of the row. Carried in the structure but
*     neither shown nor linked to the amount columns - the contract is
*     25 columns and this is not a 26th.
*     " ASSUMPTION: the four amount columns are rendered with two
*     decimals and no currency. TY_OUTPUT is a local TYPES structure, so
*     its CURR components carry no dictionary currency reference, and
*     CL_SALV_COLUMN_LIST=>SET_CURRENCY_COLUMN is UNVERIFIED on this
*     release - the scratch rig could not be queried to confirm it, so
*     nothing here claims to wire the reference up.
*     " ASSUMPTION: every company code in scope reports in INR, so the
*     four amounts are readable without a currency beside them.
*     Confirm the method in SE24 and then add one SET_CURRENCY_COLUMN
*     call per amount column. QUERIES.md.
      DATA(lo_waers) = lo_cols->get_column( CONV lvc_fname( 'WAERS' ) ).
      lo_waers->set_technical( abap_true ).

*BOC By Arnav on 07/09/26
*     Renamed on Bhavin Suthar's instruction of 07/09/26. The fiscal
*     year stays dynamic - it is P_GJAHR, never a literal, so the
*     heading follows whatever year the user selects.
*      go_alv->get_display_settings( )->set_list_header(
*        |TDS Report - Clause 34 - Fiscal Year { p_gjahr }| ).
      go_alv->get_display_settings( )->set_list_header(
        |TDS Reporting as per Clause 34(a) - Fiscal Year { p_gjahr }| ).
*EOC By Arnav on 07/09/26

      go_alv->display( ).

    CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error INTO lx_salv.
*     END-OF-SELECTION is not a dialog event, so a TYPE 'E' here would
*     terminate the event block and leave the user on an empty basic
*     list - the short-dump-by-another-name that VALIDATE_SELECTION's
*     own comment and CLAUDE.md both forbid outside AT SELECTION-SCREEN.
*     The exception's own text is kept as well, because a failure in
*     GET_COLUMN( 'WAERS' ) and a failure in the factory are otherwise
*     indistinguishable to the user and to support.
      DATA(lv_err) = lx_salv->get_text( ).
      MESSAGE lv_err TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& ALV picks WHICH of the three heading texts to draw from the column
*& output length - the short one below 10 characters, the medium one
*& below 20, the long one above that. A long heading on a narrow numeric
*& column is therefore drawn from the short text and cut off. The width
*& is set from the heading so the long text is chosen, and set_optimize
*& then widens further where the data needs it.
*&
*& The CATCH is silent by design: a renamed or removed component must
*& blank one heading, never kill the list. ATC raises "Handler without
*& statements" (priority 3) on it, so the intent is stated to the
*& checker with the ##NO_HANDLER pragma rather than left to be
*& re-litigated at ATC time.
*&---------------------------------------------------------------------*
FORM txt USING po_cols TYPE REF TO cl_salv_columns_table
               pv_name TYPE any
               pv_text TYPE any.

  DATA: lv_txt TYPE string,
        lv_len TYPE lvc_outlen.

  lv_txt = pv_text.
  lv_len = strlen( lv_txt ).

  IF lv_len < gc_col_min_len.
    lv_len = gc_col_min_len.
  ELSEIF lv_len > gc_col_max_len.
    lv_len = gc_col_max_len.
  ENDIF.

  TRY.
      DATA(lo_col) = po_cols->get_column( CONV lvc_fname( pv_name ) ).
      lo_col->set_long_text( CONV scrtext_l( lv_txt ) ).
      lo_col->set_medium_text( CONV scrtext_m( lv_txt ) ).
      lo_col->set_short_text( CONV scrtext_s( lv_txt ) ).
      lo_col->set_output_length( lv_len ).
    CATCH cx_salv_not_found ##NO_HANDLER.
  ENDTRY.

ENDFORM.
