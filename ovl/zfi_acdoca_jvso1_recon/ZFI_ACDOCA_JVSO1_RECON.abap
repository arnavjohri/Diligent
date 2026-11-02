*&---------------------------------------------------------------------*
*& Report         : ZFI_ACDOCA_JVSO1_RECON
*& Title          : Reconcile ACDOCA (ledger 0L) with JVSO1 (JV ledger 4A)
*&                  - totals by venture / equity group / account / RI
*& Project        : OVL                          Module: FI / JVA
*& Related FS     : None - requirement given in chat, 19.10.2026
*& Author         : Arnav Johri                  Date: 19.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   For the selected company codes, fiscal years and periods the report
*&   reads ACDOCA ledger 0L line items whose creation time stamp is
*&   before the cut-off date (default 27.09.2026). The FI document keys
*&   (company code, year, document number) are passed to JVSO1 and the
*&   JV ledger 4A lines (record type 0, version 001) that reference those
*&   documents are read. Both sides are totalled by company code,
*&   venture, equity group, G/L account, recovery indicator, year and
*&   period and shown side by side with the difference in local and
*&   group currency (ACDOCA HSL/KSL vs JVSO1 HSL/KSL). Transaction
*&   currency is not compared: one key can hold several currencies.
*&   Display only - nothing is written to the database.
*&   02.11.2026: third currency added (ACDOCA OSL vs JV ledger 4C) and
*&   "amount to post" columns (JVSO1 - ACDOCA) per currency - the sign
*&   the ACDOCA alignment upload expects, so the ALV export is its input.
*&
*& CHANGE HISTORY
*&   19.10.2026  Arnav Johri  <TR>  Initial development
*&   21.10.2026  Arnav Johri  <TR>  Transaction currency (WSL/TSL) comparison removed
*&   02.11.2026  Arnav Johri  <TR>  Third currency (OSL, JV ledger 4C) and amount-to-post columns
*&---------------------------------------------------------------------*
REPORT zfi_acdoca_jvso1_recon.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES:
  " Grouping key of the output - one row per combination
  BEGIN OF ty_out_key,
    rbukrs TYPE acdoca-rbukrs,
    gjahr  TYPE acdoca-gjahr,
    poper  TYPE acdoca-poper,
    vname  TYPE acdoca-vname,
    egrup  TYPE acdoca-egrup,
    racct  TYPE acdoca-racct,
    recid  TYPE acdoca-recid,
  END OF ty_out_key,

  " ACDOCA totals, summed on the database (field order = SELECT order)
  BEGIN OF ty_acd_sum,
    rbukrs TYPE acdoca-rbukrs,
    gjahr  TYPE acdoca-gjahr,
    poper  TYPE acdoca-poper,
    vname  TYPE acdoca-vname,
    egrup  TYPE acdoca-egrup,
    racct  TYPE acdoca-racct,
    recid  TYPE acdoca-recid,
    hsl    TYPE acdoca-hsl,
    ksl    TYPE acdoca-ksl,
*BOC By Arnav on 02/11/26
    osl    TYPE acdoca-osl,
*EOC By Arnav on 02/11/26
  END OF ty_acd_sum,

  " FI document keys found in ACDOCA - driver for the JVSO1 read
  BEGIN OF ty_doc,
    rbukrs TYPE acdoca-rbukrs,
    gjahr  TYPE acdoca-gjahr,
    belnr  TYPE acdoca-belnr,
  END OF ty_doc,

  " JVSO1 line items (field order = SELECT order). DOCNR / DOCLN are
  " selected only so that FOR ALL ENTRIES cannot collapse equal lines.
  BEGIN OF ty_jv_line,
*BOC By Arnav on 02/11/26
    rldnr  TYPE jvso1-rldnr,
*EOC By Arnav on 02/11/26
    rbukrs TYPE jvso1-rbukrs,
    ryear  TYPE jvso1-ryear,
    docnr  TYPE jvso1-docnr,
    docln  TYPE jvso1-docln,
    poper  TYPE jvso1-poper,
    rjvnam TYPE jvso1-rjvnam,
    regrou TYPE jvso1-regrou,
    racct  TYPE jvso1-racct,
    rrecin TYPE jvso1-rrecin,
    hsl    TYPE jvso1-hsl,
    ksl    TYPE jvso1-ksl,
  END OF ty_jv_line.

" Output row: key + ACDOCA amount, JVSO1 amount and difference per currency
TYPES: BEGIN OF ty_out.
         INCLUDE TYPE ty_out_key.
TYPES:   hsl_acd  TYPE acdoca-hsl,
         hsl_jv   TYPE acdoca-hsl,
         hsl_diff TYPE acdoca-hsl,
         ksl_acd  TYPE acdoca-ksl,
         ksl_jv   TYPE acdoca-ksl,
         ksl_diff TYPE acdoca-ksl,
*BOC By Arnav on 02/11/26
         osl_acd  TYPE acdoca-osl,
         osl_jv   TYPE acdoca-osl,
         osl_diff TYPE acdoca-osl,
         hsl_post TYPE acdoca-hsl,
         ksl_post TYPE acdoca-ksl,
         osl_post TYPE acdoca-osl,
*EOC By Arnav on 02/11/26
         diff     TYPE abap_bool,
       END OF ty_out.

TYPES: ty_t_sum TYPE SORTED TABLE OF ty_out
                WITH UNIQUE KEY rbukrs gjahr poper vname egrup racct recid,
       ty_t_out TYPE STANDARD TABLE OF ty_out WITH DEFAULT KEY.

*----------------------------------------------------------------------*
* Constants
*----------------------------------------------------------------------*
CONSTANTS: gc_rldnr_acd TYPE acdoca-rldnr VALUE '0L',  " leading ledger (ACDOCA side)
           gc_rldnr_jv  TYPE jvso1-rldnr  VALUE '4A',  " JV ledger (JVSO1 side)
           gc_rrcty     TYPE jvso1-rrcty  VALUE '0',   " record type: actual
           gc_rvers     TYPE jvso1-rvers  VALUE '001'. " version 1
*BOC By Arnav on 02/11/26
*----------------------------------------------------------------------*
* ASSUMPTION: the third currency of a company code (ACDOCA OSL, ROCUR -
*   e.g. INR for OSL) is carried on the JV side in ledger 4C, in the
*   column named in GC_OSL_COL. 'KSL' follows the only working code
*   seen (Z_JVA_ALIGNMENT reads e~ksl from 4C). If the first run shows
*   JVSO1 3C zero or unrelated to ACDOCA 3C, change GC_OSL_COL to 'HSL'.
*   Company codes without a third currency have ACDOCA OSL = 0 and no
*   4C lines, so they show zero on both sides.
*----------------------------------------------------------------------*
CONSTANTS: gc_rldnr_jv3 TYPE jvso1-rldnr  VALUE '4C',  " JV ledger, additional currencies
           gc_osl_col   TYPE c LENGTH 3   VALUE 'KSL'. " 4C column taken as 3rd currency
*EOC By Arnav on 02/11/26

*----------------------------------------------------------------------*
* Global data
*----------------------------------------------------------------------*
DATA: gv_bukrs    TYPE acdoca-rbukrs,
      gv_gjahr    TYPE acdoca-gjahr,
      gv_poper    TYPE acdoca-poper,
      gv_ts_cut   TYPE timestampl,
      gt_acd_sum  TYPE STANDARD TABLE OF ty_acd_sum WITH DEFAULT KEY,
      gt_docs     TYPE STANDARD TABLE OF ty_doc     WITH DEFAULT KEY,
      gt_jv_line  TYPE STANDARD TABLE OF ty_jv_line WITH DEFAULT KEY,
      gt_sum      TYPE ty_t_sum,
      gt_out      TYPE ty_t_out,
      gv_diff_cnt TYPE i.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
SELECT-OPTIONS: s_bukrs FOR gv_bukrs OBLIGATORY,
                s_gjahr FOR gv_gjahr OBLIGATORY,
                s_poper FOR gv_poper.
*----------------------------------------------------------------------*
* ASSUMPTION: the requirement names 27.09.2026 as the cut-off. It is
*   kept as a parameter with that default rather than a literal in the
*   SELECT, so a later cut-over can be run without a code change.
*----------------------------------------------------------------------*
PARAMETERS: p_cutdt TYPE sy-datum DEFAULT '20260927' OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM read_acdoca.
  IF gt_acd_sum IS INITIAL.
    MESSAGE 'No ACDOCA line items (ledger 0L) before the cut-off for this selection'
      TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM read_jvso1.
  PERFORM build_output.

*----------------------------------------------------------------------*
END-OF-SELECTION.
  IF gt_out IS NOT INITIAL.
    PERFORM display_alv.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form READ_ACDOCA
*&   Totals per grouping key and the list of FI document keys, both
*&   from ACDOCA ledger 0L, lines created before the cut-off date.
*&---------------------------------------------------------------------*
FORM read_acdoca.
  DATA lv_midnight TYPE t VALUE '000000'.

*----------------------------------------------------------------------*
* ASSUMPTION: the cut-off is applied to the raw digits of
*   ACDOCA-TIMESTAMP (UTC, YYYYMMDDhhmmss...), exactly as the requirement
*   reads "date part of TIMESTAMP < 27.09.2026". No shift to IST.
*----------------------------------------------------------------------*
  CONVERT DATE p_cutdt TIME lv_midnight
          INTO TIME STAMP gv_ts_cut TIME ZONE 'UTC'.

  " Totals per company code / year / period / venture / equity group /
  " account / recovery indicator, summed on the database
  SELECT rbukrs, gjahr, poper, vname, egrup, racct, recid,
*BOC By Arnav on 02/11/26
*         SUM( hsl ) AS hsl, SUM( ksl ) AS ksl
         SUM( hsl ) AS hsl, SUM( ksl ) AS ksl, SUM( osl ) AS osl
*EOC By Arnav on 02/11/26
    FROM acdoca
    WHERE rldnr      = @gc_rldnr_acd
      AND rbukrs    IN @s_bukrs
      AND gjahr     IN @s_gjahr
      AND poper     IN @s_poper
      AND timestamp  < @gv_ts_cut
    GROUP BY rbukrs, gjahr, poper, vname, egrup, racct, recid
    INTO TABLE @gt_acd_sum.

  IF gt_acd_sum IS INITIAL.
    RETURN.
  ENDIF.

  " FI document keys of the same lines - passed on to JVSO1
  SELECT DISTINCT rbukrs, gjahr, belnr
    FROM acdoca
    WHERE rldnr      = @gc_rldnr_acd
      AND rbukrs    IN @s_bukrs
      AND gjahr     IN @s_gjahr
      AND poper     IN @s_poper
      AND timestamp  < @gv_ts_cut
    INTO TABLE @gt_docs.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_JVSO1
*&   JV ledger 4A actual lines (record type 0, version 001) of the FI
*&   documents found in ACDOCA. 02/11/26: ledger 4C lines of the same
*&   documents are read as well - they carry the third currency.
*&---------------------------------------------------------------------*
FORM read_jvso1.
*----------------------------------------------------------------------*
* ASSUMPTION: JVSO1 is matched on the FI document reference
*   REFFIDOC (= ACDOCA-BELNR) together with company code and year -
*   the join SAP's own JVA/ACDOCA correction tool
*   (CL_JVA_MIG_CORRECT_ACDOCA) uses. JVSO1-DOCNR is the JV document
*   number and is not the link. JV lines that reference only a CO
*   document (REFDOCNR) are therefore not matched.
*----------------------------------------------------------------------*
  IF gt_docs IS NOT INITIAL.
*BOC By Arnav on 02/11/26
*    SELECT rbukrs, ryear, docnr, docln, poper,
*           rjvnam, regrou, racct, rrecin, hsl, ksl
*      FROM jvso1
*      FOR ALL ENTRIES IN @gt_docs
*      WHERE rldnr    = @gc_rldnr_jv
*        AND rrcty    = @gc_rrcty
    SELECT rldnr, rbukrs, ryear, docnr, docln, poper,
           rjvnam, regrou, racct, rrecin, hsl, ksl
      FROM jvso1
      FOR ALL ENTRIES IN @gt_docs
      WHERE rldnr   IN ( @gc_rldnr_jv, @gc_rldnr_jv3 )
        AND rrcty    = @gc_rrcty
*EOC By Arnav on 02/11/26
        AND rvers    = @gc_rvers
        AND rbukrs   = @gt_docs-rbukrs
        AND ryear    = @gt_docs-gjahr
        AND reffidoc = @gt_docs-belnr
        AND poper   IN @s_poper
      INTO TABLE @gt_jv_line.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_OUTPUT
*&   Merge both sides into one row per grouping key and compute the
*&   differences (ACDOCA minus JVSO1) and, since 02/11/26, the amounts
*&   to post (JVSO1 minus ACDOCA) for the alignment upload.
*&---------------------------------------------------------------------*
FORM build_output.
  DATA: ls_key  TYPE ty_out_key,
        lr_row  TYPE REF TO ty_out,
        lv_rows TYPE i.

  LOOP AT gt_acd_sum ASSIGNING FIELD-SYMBOL(<ls_acd>).
    MOVE-CORRESPONDING <ls_acd> TO ls_key.
    PERFORM get_sum_row USING ls_key CHANGING lr_row.
    lr_row->hsl_acd = lr_row->hsl_acd + <ls_acd>-hsl.
    lr_row->ksl_acd = lr_row->ksl_acd + <ls_acd>-ksl.
*BOC By Arnav on 02/11/26
    lr_row->osl_acd = lr_row->osl_acd + <ls_acd>-osl.
*EOC By Arnav on 02/11/26
  ENDLOOP.

  LOOP AT gt_jv_line ASSIGNING FIELD-SYMBOL(<ls_jv>).
    CLEAR ls_key.
    ls_key-rbukrs = <ls_jv>-rbukrs.
    ls_key-gjahr  = <ls_jv>-ryear.
    ls_key-poper  = <ls_jv>-poper.
    ls_key-vname  = <ls_jv>-rjvnam.
    ls_key-egrup  = <ls_jv>-regrou.
    ls_key-racct  = <ls_jv>-racct.
    ls_key-recid  = <ls_jv>-rrecin.
    PERFORM get_sum_row USING ls_key CHANGING lr_row.
*BOC By Arnav on 02/11/26
*    lr_row->hsl_jv = lr_row->hsl_jv + <ls_jv>-hsl.
*    lr_row->ksl_jv = lr_row->ksl_jv + <ls_jv>-ksl.
    IF <ls_jv>-rldnr = gc_rldnr_jv.
      " Ledger 4A: local and group currency
      lr_row->hsl_jv = lr_row->hsl_jv + <ls_jv>-hsl.
      lr_row->ksl_jv = lr_row->ksl_jv + <ls_jv>-ksl.
    ELSEIF gc_osl_col = 'KSL'.
      " Ledger 4C: third currency, column per GC_OSL_COL (see ASSUMPTION)
      lr_row->osl_jv = lr_row->osl_jv + <ls_jv>-ksl.
    ELSE.
      lr_row->osl_jv = lr_row->osl_jv + <ls_jv>-hsl.
    ENDIF.
*EOC By Arnav on 02/11/26
  ENDLOOP.

  LOOP AT gt_sum ASSIGNING FIELD-SYMBOL(<ls_sum>).
    <ls_sum>-hsl_diff = <ls_sum>-hsl_acd - <ls_sum>-hsl_jv.
    <ls_sum>-ksl_diff = <ls_sum>-ksl_acd - <ls_sum>-ksl_jv.
*BOC By Arnav on 02/11/26
*    IF <ls_sum>-hsl_diff <> 0 OR <ls_sum>-ksl_diff <> 0.
    <ls_sum>-osl_diff = <ls_sum>-osl_acd - <ls_sum>-osl_jv.
    " Amount to post = what ACDOCA 0L is missing against the JV ledger;
    " the Excel upload takes these columns as they are (debit +, credit -)
    <ls_sum>-hsl_post = <ls_sum>-hsl_jv - <ls_sum>-hsl_acd.
    <ls_sum>-ksl_post = <ls_sum>-ksl_jv - <ls_sum>-ksl_acd.
    <ls_sum>-osl_post = <ls_sum>-osl_jv - <ls_sum>-osl_acd.
    IF <ls_sum>-hsl_diff <> 0 OR <ls_sum>-ksl_diff <> 0 OR <ls_sum>-osl_diff <> 0.
*EOC By Arnav on 02/11/26
      <ls_sum>-diff = abap_true.
      gv_diff_cnt = gv_diff_cnt + 1.
    ENDIF.
  ENDLOOP.

  " Standard copy for the ALV - already in key order
  gt_out = gt_sum.
  lv_rows = lines( gt_out ).

  IF gt_jv_line IS INITIAL.
    MESSAGE |{ lv_rows } rows, { gv_diff_cnt } with differences - no JVSO1 (4A) line found for these documents|
      TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    MESSAGE |{ lv_rows } rows, { gv_diff_cnt } with differences| TYPE 'S'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_SUM_ROW
*&   Return a reference to the output row for the key, creating it
*&   with zero amounts when it does not exist yet.
*&---------------------------------------------------------------------*
FORM get_sum_row USING    is_key TYPE ty_out_key
                 CHANGING cr_row TYPE REF TO ty_out.
  DATA ls_new TYPE ty_out.

  READ TABLE gt_sum REFERENCE INTO cr_row
       WITH TABLE KEY rbukrs = is_key-rbukrs
                      gjahr  = is_key-gjahr
                      poper  = is_key-poper
                      vname  = is_key-vname
                      egrup  = is_key-egrup
                      racct  = is_key-racct
                      recid  = is_key-recid.
  IF sy-subrc <> 0.
    MOVE-CORRESPONDING is_key TO ls_new.
    INSERT ls_new INTO TABLE gt_sum REFERENCE INTO cr_row.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&   SALV grid with readable column headings.
*&---------------------------------------------------------------------*
FORM display_alv.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lv_title   TYPE lvc_title.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_out ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_alv->get_functions( )->set_all( abap_true ).

  lo_columns = lo_alv->get_columns( ).
  lo_columns->set_optimize( abap_true ).

  " Key columns keep their DDIC headings (Company Code, Fiscal Year, ...).
  " Amount columns share one DDIC text per currency, so they are named here.
  PERFORM set_col_text USING lo_columns 'HSL_ACD'
    'ACDOCA LC'  'ACDOCA Local Amt'   'ACDOCA Amount in Local Currency (HSL)'.
  PERFORM set_col_text USING lo_columns 'HSL_JV'
    'JVSO1 LC'   'JVSO1 Local Amt'    'JVSO1 Amount in Local Currency (HSL)'.
  PERFORM set_col_text USING lo_columns 'HSL_DIFF'
    'Diff LC'    'Difference Local'   'Difference Local Curr. (ACDOCA - JVSO1)'.
  PERFORM set_col_text USING lo_columns 'KSL_ACD'
    'ACDOCA GC'  'ACDOCA Group Amt'   'ACDOCA Amount in Group Currency (KSL)'.
  PERFORM set_col_text USING lo_columns 'KSL_JV'
    'JVSO1 GC'   'JVSO1 Group Amt'    'JVSO1 Amount in Group Currency (KSL)'.
  PERFORM set_col_text USING lo_columns 'KSL_DIFF'
    'Diff GC'    'Difference Group'   'Difference Group Curr. (ACDOCA - JVSO1)'.
*BOC By Arnav on 02/11/26
  PERFORM set_col_text USING lo_columns 'OSL_ACD'
    'ACDOCA 3C'  'ACDOCA 3rd Curr Amt' 'ACDOCA Amount in Third Currency (OSL)'.
  PERFORM set_col_text USING lo_columns 'OSL_JV'
    'JVSO1 3C'   'JVSO1 3rd Curr Amt'  'JVSO1 4C Amount taken as Third Currency'.
  PERFORM set_col_text USING lo_columns 'OSL_DIFF'
    'Diff 3C'    'Difference 3rd Curr' 'Difference Third Curr. (ACDOCA - JVSO1)'.
  PERFORM set_col_text USING lo_columns 'HSL_POST'
    'Post LC'    'To Post Local Amt'   'Amount to Post Local Curr (JVSO1-ACDOCA)'.
  PERFORM set_col_text USING lo_columns 'KSL_POST'
    'Post GC'    'To Post Group Amt'   'Amount to Post Group Curr (JVSO1-ACDOCA)'.
  PERFORM set_col_text USING lo_columns 'OSL_POST'
    'Post 3C'    'To Post 3rd Curr Amt' 'Amount to Post Third Curr (JVSO1-ACDOCA)'.
*  PERFORM set_col_text USING lo_columns 'DIFF'
*    'Diff'       'Difference exists'  'Difference in local or group currency'.
  PERFORM set_col_text USING lo_columns 'DIFF'
    'Diff'       'Difference exists'  'Difference in local, group or 3rd curr.'.
*EOC By Arnav on 02/11/26

  lv_title = |ACDOCA 0L vs JVSO1 4A - lines created before { p_cutdt DATE = USER }|.
  lo_alv->get_display_settings( )->set_list_header( lv_title ).
  lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

  lo_alv->display( ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_COL_TEXT
*&   Short / medium / long heading for one ALV column.
*&---------------------------------------------------------------------*
FORM set_col_text USING io_columns TYPE REF TO cl_salv_columns_table
                        iv_name    TYPE lvc_fname
                        iv_short   TYPE scrtext_s
                        iv_medium  TYPE scrtext_m
                        iv_long    TYPE scrtext_l.
  DATA lo_col TYPE REF TO cl_salv_column.

  TRY.
      lo_col = io_columns->get_column( iv_name ).
      lo_col->set_short_text( iv_short ).
      lo_col->set_medium_text( iv_medium ).
      lo_col->set_long_text( iv_long ).
    CATCH cx_salv_not_found.
      " Column name does not match the output structure - programming
      " error, the DDIC heading stays in place
      MESSAGE |ALV column { iv_name } not found| TYPE 'S' DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.
