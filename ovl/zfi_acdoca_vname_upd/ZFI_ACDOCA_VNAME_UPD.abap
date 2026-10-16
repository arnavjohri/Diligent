*&---------------------------------------------------------------------*
*& Report         : ZFI_ACDOCA_VNAME_UPD
*& Title          : Fill custom field ZZ1_VNAME from Joint Venture (VNAME)
*&                  on historical ACDOCA line items
*& Project        : OVL                          Module: FI / GR
*& Related FS     : None - follow-up to GR custom field ZZ1_VNAME
*& Author         : Arnav Johri                  Date: 16.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   New postings get ZZ1_VNAME from substitution rule SET_VNAME.
*&   This report fills the line items posted before that rule existed:
*&   for one company code and fiscal year it copies ACDOCA-VNAME into
*&   ACDOCA-ZZ1_VNAME_COB wherever it is still empty.
*&   - Works in packages of at most 10,000 lines, COMMIT after each.
*&   - A line that already has a ZZ1_VNAME value is never changed, so
*&     the report can be re-run safely after an interruption.
*&   - Test run (default) only counts; nothing is written.
*&   - Optional document number filter and Max lines limit, e.g.
*&     Max lines = 1 to test on a single line first.
*&   - ACDOCU is not touched: GR re-runs the release for the periods.
*&
*& CHANGE HISTORY
*&   16.10.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zfi_acdoca_vname_upd LINE-SIZE 132.

*----------------------------------------------------------------------*
* Custom field ZZ1_VNAME is stored in ACDOCA as column ZZ1_VNAME_COB
*   (confirmed by activation on DEV, 16/10/26).
*----------------------------------------------------------------------*

TYPES: BEGIN OF ty_line,
         rldnr  TYPE acdoca-rldnr,
         rbukrs TYPE acdoca-rbukrs,
         gjahr  TYPE acdoca-gjahr,
         belnr  TYPE acdoca-belnr,
         docln  TYPE acdoca-docln,
         vname  TYPE acdoca-vname,
       END OF ty_line,
       BEGIN OF ty_ledger,
         rldnr TYPE acdoca-rldnr,
         cnt   TYPE int8,
       END OF ty_ledger.

CONSTANTS gc_max_pack TYPE i VALUE 10000.

DATA: gv_rldnr   TYPE acdoca-rldnr,
      gv_belnr   TYPE acdoca-belnr,
      gt_lines   TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY,
      gt_ledger  TYPE STANDARD TABLE OF ty_ledger WITH DEFAULT KEY,
      gv_total   TYPE int8,
      gv_updated TYPE int8,
      gv_left    TYPE int8,
      gv_batches TYPE i,
      gv_stopped TYPE abap_bool,
      gv_reason  TYPE string.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_bukrs TYPE bukrs OBLIGATORY,
            p_gjahr TYPE gjahr OBLIGATORY.
* ASSUMPTION: no ledger entered = all ledgers of the company code
SELECT-OPTIONS: s_rldnr FOR gv_rldnr,
                s_belnr FOR gv_belnr.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS: p_pack TYPE i DEFAULT 5000 OBLIGATORY,
* Max lines to update in this run, 0 = no limit (use 1 for a first test)
            p_max  TYPE i DEFAULT 0,
            p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  PERFORM check_selection.

*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM check_field_lengths.
  IF gv_stopped = abap_true.
    RETURN.
  ENDIF.

  PERFORM count_open_lines CHANGING gv_total.
  IF gv_total = 0.
    MESSAGE |No line items to fill for company code { p_bukrs }, fiscal year { p_gjahr }|
      TYPE 'S'.
    RETURN.
  ENDIF.

  IF p_test = abap_true.
    PERFORM show_test_counts.
  ELSE.
    PERFORM update_in_packages.
    PERFORM count_open_lines CHANGING gv_left.
    PERFORM show_result.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form CHECK_SELECTION
*&   Package size, company code and authorization. Errors keep the
*&   user on the selection screen.
*&---------------------------------------------------------------------*
FORM check_selection.
  DATA lv_actvt TYPE activ_auth.

  IF p_pack < 1 OR p_pack > gc_max_pack.
    MESSAGE |Lines per commit must be between 1 and { gc_max_pack }| TYPE 'E'.
  ENDIF.
  IF p_max < 0.
    MESSAGE 'Max lines must be 0 (no limit) or more' TYPE 'E'.
  ENDIF.

  SELECT SINGLE bukrs FROM t001
    WHERE bukrs = @p_bukrs
    INTO @DATA(lv_bukrs).
  IF sy-subrc <> 0.
    MESSAGE |Company code { p_bukrs } does not exist| TYPE 'E'.
  ENDIF.

* Test run only reads (03); the update run changes documents (02)
  IF p_test = abap_true.
    lv_actvt = '03'.
  ELSE.
    lv_actvt = '02'.
  ENDIF.
  AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
    ID 'BUKRS' FIELD p_bukrs
    ID 'ACTVT' FIELD lv_actvt.
  IF sy-subrc <> 0.
    MESSAGE |No authorization for company code { p_bukrs } (F_BKPF_BUK, activity { lv_actvt })|
      TYPE 'E'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_FIELD_LENGTHS
*&   Stop before any update if ZZ1_VNAME_COB is shorter than VNAME - the
*&   copied values would be cut off without any error.
*&---------------------------------------------------------------------*
FORM check_field_lengths.
  DATA: lv_src     TYPE acdoca-vname,
        lv_tgt     TYPE acdoca-zz1_vname_cob,
        lv_len_src TYPE i,
        lv_len_tgt TYPE i.

  DESCRIBE FIELD lv_src LENGTH lv_len_src IN CHARACTER MODE.
  DESCRIBE FIELD lv_tgt LENGTH lv_len_tgt IN CHARACTER MODE.

  IF lv_len_tgt < lv_len_src.
    gv_stopped = abap_true.
    gv_reason = |ZZ1_VNAME_COB has { lv_len_tgt } characters, VNAME has { lv_len_src }|.
    MESSAGE |Nothing updated: { gv_reason } - values would be cut off| TYPE 'S'
      DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form COUNT_OPEN_LINES
*&   Lines that have a Joint Venture but no ZZ1_VNAME yet.
*&   Keep this WHERE identical to SHOW_TEST_COUNTS / UPDATE_IN_PACKAGES.
*&---------------------------------------------------------------------*
FORM count_open_lines CHANGING cv_count TYPE int8.
* ASSUMPTION: rows posted before the field was added can hold NULL in
*   the new column instead of blanks - IS NULL covers both cases.
  SELECT COUNT(*) FROM acdoca
    WHERE rbukrs = @p_bukrs
      AND gjahr  = @p_gjahr
      AND rldnr IN @s_rldnr
      AND belnr IN @s_belnr
      AND vname <> @space
      AND ( zz1_vname_cob = @space OR zz1_vname_cob IS NULL )
    INTO @cv_count.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_TEST_COUNTS
*&   Test run: lines that would be filled, per ledger. No update.
*&---------------------------------------------------------------------*
FORM show_test_counts.
  SELECT rldnr, COUNT(*) AS cnt FROM acdoca
    WHERE rbukrs = @p_bukrs
      AND gjahr  = @p_gjahr
      AND rldnr IN @s_rldnr
      AND belnr IN @s_belnr
      AND vname <> @space
      AND ( zz1_vname_cob = @space OR zz1_vname_cob IS NULL )
    GROUP BY rldnr
    ORDER BY rldnr
    INTO TABLE @gt_ledger.

  WRITE: / 'TEST RUN - nothing was changed'.
  SKIP.
  WRITE: / 'Company code  :', p_bukrs,
         / 'Fiscal year   :', p_gjahr.
  SKIP.
  WRITE: / 'Ledger', 12 'Lines to fill'.
  ULINE /1(40).
  LOOP AT gt_ledger ASSIGNING FIELD-SYMBOL(<ls_ledger>).
    WRITE: / <ls_ledger>-rldnr, 12 <ls_ledger>-cnt.
  ENDLOOP.
  ULINE /1(40).
  WRITE: / 'Total', 12 gv_total.
  IF p_max > 0.
    WRITE: / 'Update run will stop after', p_max, 'line(s) (Max lines).'.
  ENDIF.
  SKIP.
  WRITE: / 'Untick "Test run" and execute again to update.'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form UPDATE_IN_PACKAGES
*&   Read at most P_PACK open lines, update each one by its full key,
*&   COMMIT, repeat. An updated line no longer matches the WHERE, so
*&   every SELECT returns the next lines - no cursor kept open across
*&   commits. Stops if a package updates nothing (prevents an endless
*&   loop) or if more packages run than the start count allows.
*&   With Max lines > 0 the run ends once that many lines are updated.
*&---------------------------------------------------------------------*
FORM update_in_packages.
  DATA: lv_done_pkg TYPE int8,
        lv_max_pkg  TYPE int8,
        lv_pack     TYPE i,
        lv_pct      TYPE i,
        lv_text     TYPE c LENGTH 70.
  FIELD-SYMBOLS <ls_line> TYPE ty_line.

  lv_max_pkg = gv_total DIV p_pack + 2.

  DO.
*   Package size, cut down to what is left of the Max lines limit
    lv_pack = p_pack.
    IF p_max > 0.
      IF gv_updated >= p_max.
        EXIT.
      ENDIF.
      IF p_max - gv_updated < lv_pack.
        lv_pack = p_max - gv_updated.
      ENDIF.
    ENDIF.

    CLEAR gt_lines.
    SELECT rldnr, rbukrs, gjahr, belnr, docln, vname FROM acdoca
      WHERE rbukrs = @p_bukrs
        AND gjahr  = @p_gjahr
        AND rldnr IN @s_rldnr
        AND belnr IN @s_belnr
        AND vname <> @space
        AND ( zz1_vname_cob = @space OR zz1_vname_cob IS NULL )
      INTO TABLE @gt_lines
      UP TO @lv_pack ROWS.
    IF gt_lines IS INITIAL.
      EXIT.
    ENDIF.

    lv_done_pkg = 0.
    LOOP AT gt_lines ASSIGNING <ls_line>.
*     Full primary key + the same guard: never overwrites a value
      UPDATE acdoca SET zz1_vname_cob = @<ls_line>-vname
        WHERE rldnr  = @<ls_line>-rldnr
          AND rbukrs = @<ls_line>-rbukrs
          AND gjahr  = @<ls_line>-gjahr
          AND belnr  = @<ls_line>-belnr
          AND docln  = @<ls_line>-docln
          AND ( zz1_vname_cob = @space OR zz1_vname_cob IS NULL ).
      IF sy-subrc = 0.
        lv_done_pkg = lv_done_pkg + sy-dbcnt.
      ENDIF.
    ENDLOOP.
    COMMIT WORK.

    gv_updated = gv_updated + lv_done_pkg.
    gv_batches = gv_batches + 1.

    IF lv_done_pkg = 0.
      gv_stopped = abap_true.
      gv_reason = |package { gv_batches } selected lines but none could be updated|.
      EXIT.
    ENDIF.
    IF gv_batches >= lv_max_pkg.
      gv_stopped = abap_true.
      gv_reason = |more packages than expected ({ gv_batches }) - check the remaining count|.
      EXIT.
    ENDIF.

    lv_pct = gv_updated * 100 / gv_total.
    IF lv_pct > 100.
      lv_pct = 100.
    ENDIF.
    lv_text = |{ gv_updated } of { gv_total } lines updated|.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = lv_pct
        text       = lv_text.
  ENDDO.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_RESULT
*&---------------------------------------------------------------------*
FORM show_result.
  WRITE: / 'UPDATE RUN'.
  SKIP.
  WRITE: / 'Company code               :', p_bukrs,
         / 'Fiscal year                :', p_gjahr.
  IF s_rldnr[] IS INITIAL.
    WRITE: / 'Ledgers                    : all'.
  ELSE.
    WRITE: / 'Ledgers                    : as selected'.
  ENDIF.
  IF s_belnr[] IS NOT INITIAL.
    WRITE: / 'Documents                  : as selected'.
  ENDIF.
  IF p_max > 0.
    WRITE: / 'Max lines for this run     :', p_max.
  ENDIF.
  SKIP.
  WRITE: / 'Lines to fill at start     :', gv_total,
         / 'Lines updated              :', gv_updated,
         / 'Packages committed         :', gv_batches,
         / 'Lines still without value  :', gv_left.
  SKIP.

  IF gv_stopped = abap_true.
    WRITE: / 'Run stopped early:', gv_reason.
    MESSAGE |Stopped after { gv_updated } lines: { gv_reason }| TYPE 'S' DISPLAY LIKE 'E'.
  ELSEIF p_max > 0 AND gv_left > 0.
    WRITE: / 'Max lines limit', p_max, 'reached - remaining lines left as they are.'.
    MESSAGE |Limit reached: { gv_updated } lines updated, { gv_left } still empty| TYPE 'S'.
  ELSEIF gv_left > 0.
    WRITE: / 'Some lines are still empty (new postings during the run?) - run again.'.
    MESSAGE |{ gv_updated } lines updated, { gv_left } still empty - run again| TYPE 'S'
      DISPLAY LIKE 'W'.
  ELSE.
    MESSAGE |{ gv_updated } lines updated - all lines filled| TYPE 'S'.
  ENDIF.

  SKIP.
  WRITE: / 'Next: ask the GR consultant to re-run the data release for fiscal year',
           p_gjahr, 'so ACDOCU takes the values.'.
ENDFORM.
