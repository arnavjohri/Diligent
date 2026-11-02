*&---------------------------------------------------------------------*
*& Report         : ZFI_ACDOCA_JVA_ALIGN
*& Title          : JVA alignment of ACDOCA ledger 0L - Excel upload
*& Project        : OVL                          Module: FI / JVA
*& Related FS     : None - design agreed in chat, 02.11.2026
*&                  (repo: ovl/z_jva_alignment/NOTES.md, section 6)
*& Author         : Arnav Johri                  Date: 02.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Reads an Excel file built from ZFI_ACDOCA_JVSO1_RECON (its key and
*&   "To Post" columns, reviewed and completed with cost centre, order,
*&   WBS element and profit centre) and inserts the rows into ACDOCA
*&   ledger 0L as journal entry lines without an FI document (no
*&   BKPF/BSEG), one document per company code, fiscal year and period.
*&   Purpose: make the split by venture / equity group / recovery
*&   indicator in ledger 0L equal to the JV ledger. Every G/L account
*&   must net to zero within the file, so account balances never move -
*&   only their split does.
*&
*&   The file carries only what the reviewer decides. Everything else is
*&   derived here: fiscal year variant, chart of accounts and local
*&   currency (T001), group / third / functional currency keys (existing
*&   0L lines of the company code), controlling area (TKA02), posting
*&   date (last day of the period; 013-016 = last day of 012; 000 =
*&   first day of the fiscal year), account type (SKB1 / T030 BSX), G/L
*&   account type (SKA1), segment (CEPC), WBS internal numbers (PRPS /
*&   PROJ), document number, line number, user and time stamp.
*&
*&   Test run (default) validates and lists what would be posted.
*&   Update run inserts with a COMMIT per document; a rejected insert is
*&   rolled back for that document only. Undo mode deletes the lines this
*&   program created (document type ZJ, reference transaction ZJVA) for a
*&   selection of company code / year / period.
*&
*&   Direct write to ACDOCA. Approved use only - see NOTES.md.
*&
*& EXCEL LAYOUT - first worksheet, row 1 = headings, columns by position
*&   01 Company Code              08 Amount Local Currency  (debit +, credit -)
*&   02 Fiscal Year               09 Amount Group Currency
*&   03 Posting Period (0-16)     10 Amount 3rd Currency    (company codes with ROCUR)
*&   04 Joint Venture             11 Cost Center            (optional)
*&   05 Equity Group              12 Order                  (optional)
*&   06 G/L Account               13 WBS Element            (optional)
*&   07 Recovery Indicator        14 Profit Center          (optional)
*&                                15 Line Text              (optional)
*&   Columns 1-10 are the recon ALV's key columns and its three "To Post"
*&   columns in that order - save that as a layout and export.
*&
*& CHANGE HISTORY
*&   02.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zfi_acdoca_jva_align.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES:
  " One Excel data row, raw text, as read from the sheet
  BEGIN OF ty_row,
    rowno TYPE i,
    bukrs TYPE string,
    gjahr TYPE string,
    poper TYPE string,
    vname TYPE string,
    egrup TYPE string,
    racct TYPE string,
    recid TYPE string,
    hsl   TYPE string,
    ksl   TYPE string,
    osl   TYPE string,
    kostl TYPE string,
    aufnr TYPE string,
    posid TYPE string,
    prctr TYPE string,
    sgtxt TYPE string,
  END OF ty_row,

  " One validated, typed row - also the output list
  BEGIN OF ty_line,
    rowno          TYPE i,
    status         TYPE c LENGTH 1,
    status_txt     TYPE c LENGTH 30,
    rbukrs         TYPE acdoca-rbukrs,
    gjahr          TYPE acdoca-gjahr,
    poper          TYPE acdoca-poper,
    racct          TYPE acdoca-racct,
    vname          TYPE acdoca-vname,
    egrup          TYPE acdoca-egrup,
    recid          TYPE acdoca-recid,
    hsl            TYPE acdoca-hsl,
    ksl            TYPE acdoca-ksl,
    osl            TYPE acdoca-osl,
    rcntr          TYPE acdoca-rcntr,
    aufnr          TYPE acdoca-aufnr,
    ps_posid       TYPE acdoca-ps_posid,
    prctr          TYPE acdoca-prctr,
    segment        TYPE acdoca-segment,
    belnr          TYPE acdoca-belnr,
    docln          TYPE acdoca-docln,
    budat          TYPE acdoca-budat,
    sgtxt          TYPE acdoca-sgtxt,
    message        TYPE bapi_msg,
    ps_psp_pnr     TYPE acdoca-ps_psp_pnr,
    ps_prj_pnr     TYPE acdoca-ps_prj_pnr,
    ps_pspid       TYPE acdoca-ps_pspid,
    koart          TYPE acdoca-koart,
    glaccount_type TYPE acdoca-glaccount_type,
  END OF ty_line,

  " Company code context - read once per company code
  BEGIN OF ty_cc,
    rbukrs  TYPE acdoca-rbukrs,
    periv   TYPE t001-periv,
    ktopl   TYPE t001-ktopl,
    waers   TYPE t001-waers,
    kokrs   TYPE tka02-kokrs,
    rkcur   TYPE acdoca-rkcur,
    rocur   TYPE acdoca-rocur,
    rfccur  TYPE acdoca-rfccur,
    valid   TYPE abap_bool,
    message TYPE bapi_msg,
  END OF ty_cc,

  " One ACDOCA document = one company code / fiscal year / period
  BEGIN OF ty_doc,
    rbukrs  TYPE acdoca-rbukrs,
    gjahr   TYPE acdoca-gjahr,
    poper   TYPE acdoca-poper,
    belnr   TYPE acdoca-belnr,
    budat   TYPE acdoca-budat,
    lines   TYPE i,
    status  TYPE c LENGTH 1,
    message TYPE bapi_msg,
  END OF ty_doc,

  " Account-level totals for the net-zero check
  BEGIN OF ty_acc_sum,
    rbukrs TYPE acdoca-rbukrs,
    gjahr  TYPE acdoca-gjahr,
    poper  TYPE acdoca-poper,
    racct  TYPE acdoca-racct,
    hsl    TYPE acdoca-hsl,
    ksl    TYPE acdoca-ksl,
    osl    TYPE acdoca-osl,
  END OF ty_acc_sum,

  " Document-level indicators for the third-currency check
  BEGIN OF ty_doc_sum,
    rbukrs  TYPE acdoca-rbukrs,
    gjahr   TYPE acdoca-gjahr,
    poper   TYPE acdoca-poper,
    any_hsl TYPE abap_bool,
    any_osl TYPE abap_bool,
  END OF ty_doc_sum,

  " Stock accounts (T030 BSX) per chart of accounts
  BEGIN OF ty_bsx,
    ktopl TYPE t030-ktopl,
    konts TYPE t030-konts,
  END OF ty_bsx.

*----------------------------------------------------------------------*
* Constants
*----------------------------------------------------------------------*
CONSTANTS: gc_rldnr       TYPE acdoca-rldnr       VALUE '0L',      " leading ledger
           gc_rrcty       TYPE acdoca-rrcty       VALUE '0',       " record type actual
           gc_bsx         TYPE t030-ktosl         VALUE 'BSX',     " stock accounts -> KOART M
           gc_max_cols    TYPE i                  VALUE 15.        " Excel columns read
*----------------------------------------------------------------------*
* ASSUMPTION: the marker fields below follow the ACDOCA-only lines that
*   already exist on OCQ (BELNR CA001J0000, SE16H 02/11/26: BSTAT,
*   VORGN, BTTYPE, LINETYPE, XSPLITMOD blank; SDM_VERSION 05) plus our
*   own tags. Document type ZJ is a hardcoded constant and is NOT
*   maintained in OBA7 (decision 02/11/26) - SE16 T003 must have no ZJ.
*   MIG_SOURCE 'U' is taken from the reference program Z_JVA_ALIGNMENT;
*   confirm its meaning in the domain value range (SE11, ACDOCA,
*   MIG_SOURCE) and change it here if 'U' means something else.
*   The undo mode selects on GC_BLART + GC_AWTYP: changing either value
*   after lines were posted orphans those lines for the undo.
*----------------------------------------------------------------------*
CONSTANTS: gc_blart       TYPE acdoca-blart       VALUE 'ZJ',      " document type (not in OBA7)
           gc_awtyp       TYPE acdoca-awtyp       VALUE 'ZJVA',    " our reference transaction tag
           gc_belnr_root  TYPE c LENGTH 7         VALUE 'ZJVA000', " + 3-digit period = BELNR
           gc_mig_source  TYPE acdoca-mig_source  VALUE 'U',       " see ASSUMPTION
           gc_sdm_version TYPE acdoca-sdm_version VALUE '05'.      " as on existing OCQ lines

*----------------------------------------------------------------------*
* Global data
*----------------------------------------------------------------------*
DATA: gv_bukrs TYPE acdoca-rbukrs,
      gv_gjahr TYPE acdoca-gjahr,
      gv_poper TYPE acdoca-poper,
      gt_row   TYPE STANDARD TABLE OF ty_row  WITH DEFAULT KEY,
      gt_line  TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY,
      gt_cc    TYPE SORTED TABLE OF ty_cc  WITH UNIQUE KEY rbukrs,
      gt_doc   TYPE SORTED TABLE OF ty_doc WITH UNIQUE KEY rbukrs gjahr poper,
      gt_bsx   TYPE SORTED TABLE OF ty_bsx WITH UNIQUE KEY ktopl konts,
      gt_bsx_k TYPE SORTED TABLE OF t030-ktopl WITH UNIQUE KEY table_line.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: r_upl RADIOBUTTON GROUP mod DEFAULT 'X',
            r_del RADIOBUTTON GROUP mod.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS: p_file TYPE localfile LOWER CASE.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.
SELECT-OPTIONS: s_bukrs FOR gv_bukrs,
                s_gjahr FOR gv_gjahr,
                s_poper FOR gv_poper.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-b04.
PARAMETERS: p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b4.

*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f4_file.

*----------------------------------------------------------------------*
START-OF-SELECTION.
  IF r_del = abap_true.
    IF s_bukrs[] IS INITIAL OR s_gjahr[] IS INITIAL.
      MESSAGE 'Undo needs at least a company code and a fiscal year' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    PERFORM undo_alignment.
    RETURN.
  ENDIF.

  IF p_file IS INITIAL.
    MESSAGE 'Select the Excel file to upload' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM read_file.
  IF gt_row IS INITIAL.
    MESSAGE 'The file has no data rows below the heading' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM parse_rows.
  PERFORM file_checks.
  PERFORM assign_documents.
  PERFORM post_or_test.

*----------------------------------------------------------------------*
END-OF-SELECTION.
  IF gt_line IS NOT INITIAL.
    PERFORM display_result.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form F4_FILE
*&   File dialog for the Excel file.
*&---------------------------------------------------------------------*
FORM f4_file.
  DATA: lt_files TYPE filetable,
        ls_file  TYPE file_table,
        lv_rc    TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING  window_title = 'Select the JVA alignment Excel file'
               file_filter  = 'Excel (*.xlsx)|*.xlsx|All files (*.*)|*.*'
    CHANGING   file_table   = lt_files
               rc           = lv_rc
    EXCEPTIONS OTHERS       = 1 ).
  IF sy-subrc = 0 AND lv_rc > 0.
    READ TABLE lt_files INTO ls_file INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_file-filename.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_FILE
*&   Upload the .xlsx as binary and parse the first worksheet with
*&   CL_FDT_XL_SPREADSHEET. Columns are taken by position (1..15); the
*&   heading row is consumed by the class and is not a data row.
*&---------------------------------------------------------------------*
FORM read_file.
  DATA: lv_name TYPE string,
        lt_bin  TYPE solix_tab,
        lv_len  TYPE i,
        lv_xstr TYPE xstring,
        lt_ws   TYPE if_fdt_doc_spreadsheet=>t_worksheet_names,
        lv_ws   TYPE string,
        lo_xl   TYPE REF TO cl_fdt_xl_spreadsheet,
        lr_data TYPE REF TO data,
        ls_row  TYPE ty_row,
        lv_ix   TYPE i,
        lv_val  TYPE string.

  FIELD-SYMBOLS: <lt_tab>  TYPE STANDARD TABLE,
                 <ls_xrow> TYPE any,
                 <lv_cell> TYPE any.

  lv_name = p_file.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING  filename        = lv_name
               filetype        = 'BIN'
    IMPORTING  filelength      = lv_len
    CHANGING   data_tab        = lt_bin
    EXCEPTIONS file_open_error = 1
               file_read_error = 2
               OTHERS          = 3 ).
  IF sy-subrc <> 0 OR lv_len = 0.
    MESSAGE |File { lv_name } could not be read| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  lv_xstr = cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin
                                              iv_size  = lv_len ).

*----------------------------------------------------------------------*
* ASSUMPTION: the file is a real .xlsx workbook (not .xls, not a renamed
*   CSV); the data is on the first worksheet; row 1 holds headings.
*----------------------------------------------------------------------*
  TRY.
      CREATE OBJECT lo_xl
        EXPORTING document_name = lv_name
                  xdocument     = lv_xstr.
      lo_xl->if_fdt_doc_spreadsheet~get_worksheet_names(
        IMPORTING worksheet_names = lt_ws ).
      READ TABLE lt_ws INTO lv_ws INDEX 1.
      IF sy-subrc <> 0.
        MESSAGE 'The workbook has no worksheet' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      lr_data = lo_xl->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_ws ).
    CATCH cx_root.
      MESSAGE 'The file is not a readable .xlsx workbook' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  IF lr_data IS NOT BOUND.
    RETURN.
  ENDIF.
  ASSIGN lr_data->* TO <lt_tab>.
  IF <lt_tab> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  LOOP AT <lt_tab> ASSIGNING <ls_xrow>.
    CLEAR ls_row.
    ls_row-rowno = sy-tabix + 1.          " Excel row number (row 1 = headings)
    DO gc_max_cols TIMES.
      lv_ix = sy-index.
      UNASSIGN <lv_cell>.
      ASSIGN COMPONENT lv_ix OF STRUCTURE <ls_xrow> TO <lv_cell>.
      IF sy-subrc <> 0.
        EXIT.                             " sheet has fewer columns - rest blank
      ENDIF.
      lv_val = <lv_cell>.
      CASE lv_ix.
        WHEN 1.  ls_row-bukrs = lv_val.
        WHEN 2.  ls_row-gjahr = lv_val.
        WHEN 3.  ls_row-poper = lv_val.
        WHEN 4.  ls_row-vname = lv_val.
        WHEN 5.  ls_row-egrup = lv_val.
        WHEN 6.  ls_row-racct = lv_val.
        WHEN 7.  ls_row-recid = lv_val.
        WHEN 8.  ls_row-hsl   = lv_val.
        WHEN 9.  ls_row-ksl   = lv_val.
        WHEN 10. ls_row-osl   = lv_val.
        WHEN 11. ls_row-kostl = lv_val.
        WHEN 12. ls_row-aufnr = lv_val.
        WHEN 13. ls_row-posid = lv_val.
        WHEN 14. ls_row-prctr = lv_val.
        WHEN 15. ls_row-sgtxt = lv_val.
      ENDCASE.
    ENDDO.
    " Completely empty rows (trailing rows of the sheet) are ignored
    IF ls_row-bukrs IS INITIAL AND ls_row-gjahr IS INITIAL AND ls_row-poper IS INITIAL AND
       ls_row-racct IS INITIAL AND ls_row-hsl   IS INITIAL AND ls_row-ksl   IS INITIAL AND
       ls_row-osl   IS INITIAL.
      CONTINUE.
    ENDIF.
    APPEND ls_row TO gt_row.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_ROWS
*&   Every raw row becomes one typed, validated line.
*&---------------------------------------------------------------------*
FORM parse_rows.
  LOOP AT gt_row ASSIGNING FIELD-SYMBOL(<ls_row>).
    APPEND INITIAL LINE TO gt_line ASSIGNING FIELD-SYMBOL(<ls_line>).
    <ls_line>-rowno = <ls_row>-rowno.
    PERFORM parse_row USING <ls_row> CHANGING <ls_line>.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_ROW
*&   Key fields, company code context, posting date, account, JVA
*&   fields, cost objects, amounts, text - in that order, because the
*&   later checks need the earlier results.
*&---------------------------------------------------------------------*
FORM parse_row USING    is_row  TYPE ty_row
               CHANGING cs_line TYPE ty_line.
  DATA: ls_cc   TYPE ty_cc,
        lv_text TYPE string,
        lv_c40  TYPE c LENGTH 40,
        lv_int  TYPE i,
        lv_ok   TYPE abap_bool.

  " --- company code
  lv_text = to_upper( condense( is_row-bukrs ) ).
  IF lv_text IS INITIAL.
    PERFORM add_err USING 'Company code missing' CHANGING cs_line.
  ELSEIF strlen( lv_text ) > 4.
    PERFORM add_err USING 'Company code longer than 4 characters' CHANGING cs_line.
  ELSE.
    cs_line-rbukrs = lv_text.
  ENDIF.

  " --- fiscal year
  lv_text = condense( is_row-gjahr ).
  IF strlen( lv_text ) <> 4 OR lv_text CN '0123456789'.
    PERFORM add_err USING 'Fiscal year must be 4 digits' CHANGING cs_line.
  ELSE.
    cs_line-gjahr = lv_text.
  ENDIF.

  " --- posting period 0..16 (000 = balance carry-forward)
  lv_text = condense( is_row-poper ).
  IF lv_text IS INITIAL OR strlen( lv_text ) > 3 OR lv_text CN '0123456789'.
    PERFORM add_err USING 'Posting period must be a number 0 to 16' CHANGING cs_line.
  ELSE.
    lv_int = lv_text.
    IF lv_int > 16.
      PERFORM add_err USING 'Posting period must be a number 0 to 16' CHANGING cs_line.
    ELSE.
      cs_line-poper = lv_int.
    ENDIF.
  ENDIF.

  " --- G/L account, leading zeros added
  lv_text = to_upper( condense( is_row-racct ) ).
  IF lv_text IS INITIAL.
    PERFORM add_err USING 'G/L account missing' CHANGING cs_line.
  ELSEIF strlen( lv_text ) > 10.
    PERFORM add_err USING 'G/L account longer than 10 characters' CHANGING cs_line.
  ELSE.
    lv_c40 = lv_text.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_c40
      IMPORTING
        output = cs_line-racct.
  ENDIF.

  IF cs_line-status = 'E'.
    RETURN.                               " no key, nothing else can be checked
  ENDIF.

  " --- company code context and posting date
  PERFORM get_company USING cs_line-rbukrs cs_line-gjahr CHANGING ls_cc.
  IF ls_cc-valid = abap_false.
    PERFORM add_err USING ls_cc-message CHANGING cs_line.
    RETURN.
  ENDIF.

  PERFORM period_date USING cs_line-gjahr cs_line-poper ls_cc-periv
                      CHANGING cs_line-budat lv_ok.
  IF lv_ok = abap_false.
    PERFORM add_err USING |Posting date for period { cs_line-poper } not determined (FYV { ls_cc-periv })|
                    CHANGING cs_line.
    RETURN.
  ENDIF.

  " --- account, JVA fields, cost objects
  PERFORM check_account      USING ls_cc        CHANGING cs_line.
  PERFORM check_jva_fields   USING is_row ls_cc CHANGING cs_line.
  PERFORM check_cost_objects USING is_row ls_cc CHANGING cs_line.

  " --- amounts: the sign in the file is the sign posted (debit +, credit -)
  PERFORM parse_amount USING is_row-hsl CHANGING cs_line-hsl lv_ok.
  IF lv_ok = abap_false.
    PERFORM add_err USING 'Amount local currency is not a number' CHANGING cs_line.
  ENDIF.
  PERFORM parse_amount USING is_row-ksl CHANGING cs_line-ksl lv_ok.
  IF lv_ok = abap_false.
    PERFORM add_err USING 'Amount group currency is not a number' CHANGING cs_line.
  ENDIF.
  PERFORM parse_amount USING is_row-osl CHANGING cs_line-osl lv_ok.
  IF lv_ok = abap_false.
    PERFORM add_err USING 'Amount 3rd currency is not a number' CHANGING cs_line.
  ENDIF.
  IF ls_cc-rocur IS INITIAL AND cs_line-osl <> 0.
    PERFORM add_err USING |Company code { cs_line-rbukrs } has no third currency - column 10 must be empty|
                    CHANGING cs_line.
  ENDIF.

  " --- line text
  lv_text = condense( is_row-sgtxt ).
  IF lv_text IS INITIAL.
    cs_line-sgtxt = |JVA alignment { cs_line-gjahr }/{ cs_line-poper }|.
  ELSE.
    cs_line-sgtxt = lv_text.
  ENDIF.

  " --- rows with nothing to post
  IF cs_line-status <> 'E' AND cs_line-hsl = 0 AND cs_line-ksl = 0 AND cs_line-osl = 0.
    cs_line-status  = 'Z'.
    cs_line-message = 'All amounts zero - row skipped'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_ERR
*&   Mark the line as faulty and append the reason.
*&---------------------------------------------------------------------*
FORM add_err USING    iv_text TYPE csequence
             CHANGING cs_line TYPE ty_line.
  cs_line-status = 'E'.
  IF cs_line-message IS INITIAL.
    cs_line-message = iv_text.
  ELSE.
    cs_line-message = |{ cs_line-message }; { iv_text }|.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_COMPANY
*&   Company code context, cached in GT_CC: fiscal year variant, chart
*&   of accounts and local currency from T001, controlling area from
*&   TKA02, group / third / functional currency keys from the existing
*&   ledger 0L lines of the company code and year.
*&---------------------------------------------------------------------*
FORM get_company USING    iv_bukrs TYPE acdoca-rbukrs
                          iv_gjahr TYPE acdoca-gjahr
                 CHANGING cs_cc    TYPE ty_cc.

  READ TABLE gt_cc INTO cs_cc WITH TABLE KEY rbukrs = iv_bukrs.
  IF sy-subrc = 0.
    RETURN.
  ENDIF.

  CLEAR cs_cc.
  cs_cc-rbukrs = iv_bukrs.

  SELECT SINGLE periv, ktopl, waers
    FROM t001
    WHERE bukrs = @iv_bukrs
    INTO ( @cs_cc-periv, @cs_cc-ktopl, @cs_cc-waers ).
  IF sy-subrc <> 0.
    cs_cc-message = |Company code { iv_bukrs } does not exist (T001)|.
    INSERT cs_cc INTO TABLE gt_cc.
    RETURN.
  ENDIF.

  SELECT kokrs
    FROM tka02
    WHERE bukrs = @iv_bukrs
    INTO @cs_cc-kokrs
    UP TO 1 ROWS.
  ENDSELECT.
  IF sy-subrc <> 0.
    cs_cc-message = |Company code { iv_bukrs } has no controlling area (TKA02)|.
    INSERT cs_cc INTO TABLE gt_cc.
    RETURN.
  ENDIF.

*----------------------------------------------------------------------*
* ASSUMPTION: the currency keys of the new lines are copied from what
*   SAP already writes on ledger 0L for this company code and year
*   (RKCUR differs per company code on OCQ: BML INR, OSL USD; ROCUR is
*   filled only where a third currency exists; RFCCUR only where a
*   functional currency is configured). No configuration table is read
*   for them, so the lines can never carry a currency key the existing
*   lines do not.
*----------------------------------------------------------------------*
  SELECT DISTINCT rhcur, rkcur, rocur, rfccur
    FROM acdoca
    WHERE rldnr  = @gc_rldnr
      AND rbukrs = @iv_bukrs
      AND gjahr  = @iv_gjahr
    INTO TABLE @DATA(lt_cur).
  IF lt_cur IS INITIAL.
    cs_cc-message = |No ledger 0L lines for { iv_bukrs } { iv_gjahr } - currency keys cannot be derived|.
    INSERT cs_cc INTO TABLE gt_cc.
    RETURN.
  ENDIF.

  LOOP AT lt_cur ASSIGNING FIELD-SYMBOL(<ls_cur>).
    IF cs_cc-rkcur IS INITIAL.
      cs_cc-rkcur = <ls_cur>-rkcur.
    ENDIF.
    IF cs_cc-rocur IS INITIAL.
      cs_cc-rocur = <ls_cur>-rocur.
    ENDIF.
    IF cs_cc-rfccur IS INITIAL.
      cs_cc-rfccur = <ls_cur>-rfccur.
    ENDIF.
    IF <ls_cur>-rhcur IS NOT INITIAL AND <ls_cur>-rhcur <> cs_cc-waers.
      cs_cc-message = |Local currency on existing 0L lines ({ <ls_cur>-rhcur }) differs from T001 ({ cs_cc-waers })|.
      INSERT cs_cc INTO TABLE gt_cc.
      RETURN.
    ENDIF.
  ENDLOOP.

  IF cs_cc-rkcur IS INITIAL.
    cs_cc-message = |Group currency key not found on the 0L lines of { iv_bukrs } { iv_gjahr }|.
    INSERT cs_cc INTO TABLE gt_cc.
    RETURN.
  ENDIF.

  cs_cc-valid = abap_true.
  INSERT cs_cc INTO TABLE gt_cc.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PERIOD_DATE
*&   Posting date of a period: last day of the period; special periods
*&   013-016 = last day of period 012; period 000 = first day of the
*&   fiscal year (the date SAP's own carry-forward lines carry).
*&---------------------------------------------------------------------*
FORM period_date USING    iv_gjahr TYPE acdoca-gjahr
                          iv_poper TYPE acdoca-poper
                          iv_periv TYPE t001-periv
                 CHANGING cv_budat TYPE acdoca-budat
                          cv_ok    TYPE abap_bool.
  DATA lv_poper TYPE poper.

  CLEAR: cv_budat, cv_ok.

  CASE iv_poper.
    WHEN '000'.
      lv_poper = '001'.
      CALL FUNCTION 'FIRST_DAY_IN_PERIOD_GET'
        EXPORTING
          i_gjahr = iv_gjahr
          i_periv = iv_periv
          i_poper = lv_poper
        IMPORTING
          e_date  = cv_budat
        EXCEPTIONS
          OTHERS  = 1.
    WHEN '013' OR '014' OR '015' OR '016'.
      lv_poper = '012'.
      CALL FUNCTION 'LAST_DAY_IN_PERIOD_GET'
        EXPORTING
          i_gjahr = iv_gjahr
          i_periv = iv_periv
          i_poper = lv_poper
        IMPORTING
          e_date  = cv_budat
        EXCEPTIONS
          OTHERS  = 1.
    WHEN OTHERS.
      lv_poper = iv_poper.
      CALL FUNCTION 'LAST_DAY_IN_PERIOD_GET'
        EXPORTING
          i_gjahr = iv_gjahr
          i_periv = iv_periv
          i_poper = lv_poper
        IMPORTING
          e_date  = cv_budat
        EXCEPTIONS
          OTHERS  = 1.
  ENDCASE.

  IF sy-subrc = 0 AND cv_budat IS NOT INITIAL.
    cv_ok = abap_true.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_ACCOUNT
*&   SKA1 (chart of accounts, G/L account type), SKB1 (company code,
*&   reconciliation indicator -> KOART A/D/K), T030 BSX -> KOART M,
*&   otherwise KOART S.
*&---------------------------------------------------------------------*
FORM check_account USING    is_cc   TYPE ty_cc
                   CHANGING cs_line TYPE ty_line.
  DATA lv_mitkz TYPE skb1-mitkz.

  SELECT SINGLE glaccount_type
    FROM ska1
    WHERE ktopl = @is_cc-ktopl
      AND saknr = @cs_line-racct
    INTO @cs_line-glaccount_type.
  IF sy-subrc <> 0.
    PERFORM add_err USING |G/L account { cs_line-racct } not in chart of accounts { is_cc-ktopl }|
                    CHANGING cs_line.
    RETURN.
  ENDIF.

  SELECT SINGLE mitkz
    FROM skb1
    WHERE bukrs = @cs_line-rbukrs
      AND saknr = @cs_line-racct
    INTO @lv_mitkz.
  IF sy-subrc <> 0.
    PERFORM add_err USING |G/L account { cs_line-racct } not created in company code { cs_line-rbukrs }|
                    CHANGING cs_line.
    RETURN.
  ENDIF.

  CASE lv_mitkz.
    WHEN 'A' OR 'D' OR 'K'.
      cs_line-koart = lv_mitkz.
    WHEN OTHERS.
      PERFORM read_bsx_accounts USING is_cc-ktopl.
      READ TABLE gt_bsx TRANSPORTING NO FIELDS
           WITH TABLE KEY ktopl = is_cc-ktopl konts = cs_line-racct.
      IF sy-subrc = 0.
        cs_line-koart = 'M'.
      ELSE.
        cs_line-koart = 'S'.
      ENDIF.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_BSX_ACCOUNTS
*&   Stock accounts of a chart of accounts (T030, transaction key BSX),
*&   read once per chart.
*&---------------------------------------------------------------------*
FORM read_bsx_accounts USING iv_ktopl TYPE t030-ktopl.
  READ TABLE gt_bsx_k TRANSPORTING NO FIELDS WITH TABLE KEY table_line = iv_ktopl.
  IF sy-subrc = 0.
    RETURN.
  ENDIF.
  INSERT iv_ktopl INTO TABLE gt_bsx_k.

  SELECT DISTINCT ktopl, konts
    FROM t030
    WHERE ktopl = @iv_ktopl
      AND ktosl = @gc_bsx
    INTO TABLE @DATA(lt_bsx).
  INSERT LINES OF lt_bsx INTO TABLE gt_bsx.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_JVA_FIELDS
*&   Joint venture (T8JV), equity group (T8JG), recovery indicator
*&   (T8JJ). All three may be blank - that is the offset row of an
*&   account. Equity group or recovery indicator without a venture is
*&   rejected.
*&---------------------------------------------------------------------*
FORM check_jva_fields USING    is_row  TYPE ty_row
                               is_cc   TYPE ty_cc
                      CHANGING cs_line TYPE ty_line.
  DATA: lv_text TYPE string,
        lv_chk  TYPE c LENGTH 6.

  " --- joint venture
  lv_text = to_upper( condense( is_row-vname ) ).
  IF strlen( lv_text ) > 6.
    PERFORM add_err USING 'Joint venture longer than 6 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    cs_line-vname = lv_text.
    SELECT SINGLE jvname
      FROM t8jv
      WHERE bukrs  = @cs_line-rbukrs
        AND jvname = @cs_line-vname
      INTO @lv_chk.
    IF sy-subrc <> 0.
      PERFORM add_err USING |Joint venture { cs_line-vname } not defined for company code { cs_line-rbukrs }|
                      CHANGING cs_line.
    ENDIF.
  ENDIF.

  " --- equity group
  lv_text = to_upper( condense( is_row-egrup ) ).
  IF strlen( lv_text ) > 3.
    PERFORM add_err USING 'Equity group longer than 3 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    cs_line-egrup = lv_text.
    IF cs_line-vname IS INITIAL.
      PERFORM add_err USING 'Equity group given without a joint venture' CHANGING cs_line.
    ELSE.
      SELECT SINGLE egrup
        FROM t8jg
        WHERE bukrs = @cs_line-rbukrs
          AND vname = @cs_line-vname
          AND egrup = @cs_line-egrup
        INTO @lv_chk.
      IF sy-subrc <> 0.
        PERFORM add_err USING |Equity group { cs_line-egrup } not defined for venture { cs_line-vname }|
                        CHANGING cs_line.
      ENDIF.
    ENDIF.
  ENDIF.

  " --- recovery indicator
  lv_text = to_upper( condense( is_row-recid ) ).
  IF strlen( lv_text ) > 2.
    PERFORM add_err USING 'Recovery indicator longer than 2 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    cs_line-recid = lv_text.
    IF cs_line-vname IS INITIAL.
      PERFORM add_err USING 'Recovery indicator given without a joint venture' CHANGING cs_line.
    ELSE.
      SELECT SINGLE recin
        FROM t8jj
        WHERE bukrs  = @cs_line-rbukrs
          AND jvname = @cs_line-vname
          AND recin  = @cs_line-recid
        INTO @lv_chk.
      IF sy-subrc <> 0.
        PERFORM add_err USING |Recovery indicator { cs_line-recid } not defined for venture { cs_line-vname }|
                        CHANGING cs_line.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_COST_OBJECTS
*&   Cost centre (CSKS, valid on the posting date), order (AUFK), WBS
*&   element (PRPS / PROJ), profit centre (CEPC, valid on the posting
*&   date; taken from the cost centre when the column is blank),
*&   segment from the profit centre.
*&---------------------------------------------------------------------*
FORM check_cost_objects USING    is_row  TYPE ty_row
                                 is_cc   TYPE ty_cc
                        CHANGING cs_line TYPE ty_line.
  DATA: lv_text     TYPE string,
        lv_c40      TYPE c LENGTH 40,
        lv_prctr_cc TYPE csks-prctr,
        lv_aufnr    TYPE aufk-aufnr,
        lv_ok       TYPE abap_bool.

  " --- cost centre
  lv_text = to_upper( condense( is_row-kostl ) ).
  IF strlen( lv_text ) > 10.
    PERFORM add_err USING 'Cost center longer than 10 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    lv_c40 = lv_text.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_c40
      IMPORTING
        output = cs_line-rcntr.
    SELECT SINGLE prctr
      FROM csks
      WHERE kokrs  = @is_cc-kokrs
        AND kostl  = @cs_line-rcntr
        AND datbi >= @cs_line-budat
        AND datab <= @cs_line-budat
      INTO @lv_prctr_cc.
    IF sy-subrc <> 0.
      PERFORM add_err USING |Cost center { cs_line-rcntr } invalid in { is_cc-kokrs } on { cs_line-budat DATE = USER }|
                      CHANGING cs_line.
    ENDIF.
  ENDIF.

  " --- order
  lv_text = to_upper( condense( is_row-aufnr ) ).
  IF strlen( lv_text ) > 12.
    PERFORM add_err USING 'Order longer than 12 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    lv_c40 = lv_text.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_c40
      IMPORTING
        output = cs_line-aufnr.
    SELECT SINGLE aufnr
      FROM aufk
      WHERE aufnr = @cs_line-aufnr
      INTO @lv_aufnr.
    IF sy-subrc <> 0.
      PERFORM add_err USING |Order { cs_line-aufnr } does not exist (AUFK)| CHANGING cs_line.
    ENDIF.
  ENDIF.

  " --- WBS element
  lv_text = to_upper( condense( is_row-posid ) ).
  IF strlen( lv_text ) > 24.
    PERFORM add_err USING 'WBS element longer than 24 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    PERFORM find_wbs USING lv_text CHANGING cs_line lv_ok.
    IF lv_ok = abap_false.
      PERFORM add_err USING |WBS element { lv_text } not found (PRPS)| CHANGING cs_line.
    ENDIF.
  ENDIF.

  " --- profit centre: from the file, else from the cost centre
  lv_text = to_upper( condense( is_row-prctr ) ).
  IF strlen( lv_text ) > 10.
    PERFORM add_err USING 'Profit center longer than 10 characters' CHANGING cs_line.
  ELSEIF lv_text IS NOT INITIAL.
    lv_c40 = lv_text.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_c40
      IMPORTING
        output = cs_line-prctr.
  ELSEIF lv_prctr_cc IS NOT INITIAL.
    cs_line-prctr = lv_prctr_cc.
  ENDIF.

  IF cs_line-prctr IS NOT INITIAL.
    SELECT SINGLE segment
      FROM cepc
      WHERE prctr  = @cs_line-prctr
        AND kokrs  = @is_cc-kokrs
        AND datbi >= @cs_line-budat
        AND datab <= @cs_line-budat
      INTO @cs_line-segment.
    IF sy-subrc <> 0.
      PERFORM add_err USING |Profit ctr { cs_line-prctr } invalid in { is_cc-kokrs } on { cs_line-budat DATE = USER }|
                      CHANGING cs_line.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FIND_WBS
*&   PRPS by external WBS id - first as typed, then with the edit-mask
*&   separators removed. Fills the internal numbers and the project.
*&---------------------------------------------------------------------*
FORM find_wbs USING    iv_text TYPE string
              CHANGING cs_line TYPE ty_line
                       cv_ok   TYPE abap_bool.
  DATA: lv_posid TYPE prps-posid,
        lv_clean TYPE prps-posid.

  cv_ok    = abap_false.
  lv_posid = iv_text.

  SELECT SINGLE pspnr, psphi, posid
    FROM prps
    WHERE posid = @lv_posid
    INTO ( @cs_line-ps_psp_pnr, @cs_line-ps_prj_pnr, @cs_line-ps_posid ).
  IF sy-subrc <> 0.
    lv_clean = lv_posid.
    REPLACE ALL OCCURRENCES OF REGEX '[^A-Z0-9]' IN lv_clean WITH ''.
    SELECT SINGLE pspnr, psphi, posid
      FROM prps
      WHERE posid = @lv_clean
      INTO ( @cs_line-ps_psp_pnr, @cs_line-ps_prj_pnr, @cs_line-ps_posid ).
  ENDIF.
  IF sy-subrc <> 0.
    CLEAR: cs_line-ps_psp_pnr, cs_line-ps_prj_pnr, cs_line-ps_posid.
    RETURN.
  ENDIF.

  SELECT SINGLE pspid
    FROM proj
    WHERE pspnr = @cs_line-ps_prj_pnr
    INTO @cs_line-ps_pspid.
  cv_ok = abap_true.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_AMOUNT
*&   Text -> amount. Accepts plain numbers ("1234.56", "-1234.56"),
*&   trailing minus ("1234.56-"), thousands separators ("1,234.56" or
*&   "1.234,56" - the right-most separator is the decimal one).
*&   Blank = zero.
*&---------------------------------------------------------------------*
FORM parse_amount USING    iv_text   TYPE string
                  CHANGING cv_amount TYPE acdoca-hsl
                           cv_ok     TYPE abap_bool.
  DATA: lv_s     TYPE string,
        lv_neg   TYPE abap_bool,
        lv_cnt_c TYPE i,
        lv_cnt_p TYPE i,
        lv_off_c TYPE i,
        lv_off_p TYPE i.

  CLEAR: cv_amount, cv_ok, lv_neg.
  lv_s = iv_text.
  CONDENSE lv_s NO-GAPS.
  IF lv_s IS INITIAL.
    cv_ok = abap_true.
    RETURN.
  ENDIF.

  IF lv_s CA '-'.
    lv_neg = abap_true.
    REPLACE ALL OCCURRENCES OF '-' IN lv_s WITH ''.
  ENDIF.

  FIND ALL OCCURRENCES OF ',' IN lv_s MATCH COUNT lv_cnt_c.
  FIND ALL OCCURRENCES OF '.' IN lv_s MATCH COUNT lv_cnt_p.
  IF lv_cnt_c > 0 AND lv_cnt_p > 0.
    lv_off_c = find( val = lv_s sub = ',' occ = -1 ).
    lv_off_p = find( val = lv_s sub = '.' occ = -1 ).
    IF lv_off_c > lv_off_p.
      " decimal comma, points are thousands separators
      REPLACE ALL OCCURRENCES OF '.' IN lv_s WITH ''.
      REPLACE ',' IN lv_s WITH '.'.
    ELSE.
      REPLACE ALL OCCURRENCES OF ',' IN lv_s WITH ''.
    ENDIF.
  ELSEIF lv_cnt_c = 1 AND lv_cnt_p = 0.
    " single comma: decimal comma when at most 2 digits follow it
    lv_off_c = find( val = lv_s sub = ',' ).
    IF strlen( lv_s ) - lv_off_c - 1 <= 2.
      REPLACE ',' IN lv_s WITH '.'.
    ELSE.
      REPLACE ALL OCCURRENCES OF ',' IN lv_s WITH ''.
    ENDIF.
  ELSEIF lv_cnt_c > 1.
    REPLACE ALL OCCURRENCES OF ',' IN lv_s WITH ''.
  ENDIF.

  IF lv_s CN '0123456789.' OR lv_s IS INITIAL.
    RETURN.
  ENDIF.

  TRY.
      cv_amount = lv_s.
      IF lv_neg = abap_true.
        cv_amount = - cv_amount.
      ENDIF.
      cv_ok = abap_true.
    CATCH cx_sy_conversion_no_number cx_sy_conversion_overflow.
      CLEAR cv_amount.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FILE_CHECKS
*&   Whole-file rules, applied after every row is parsed:
*&   1. a document for the company code / year / period must not exist
*&      yet (run the undo first),
*&   2. a company code with a third currency must have 3rd-currency
*&      amounts in the file,
*&   3. every G/L account nets to zero in every currency.
*&   A failed rule marks every affected row; nothing is posted then.
*&---------------------------------------------------------------------*
FORM file_checks.
  DATA: lt_acc   TYPE SORTED TABLE OF ty_acc_sum WITH UNIQUE KEY rbukrs gjahr poper racct,
        lt_docs  TYPE SORTED TABLE OF ty_doc_sum WITH UNIQUE KEY rbukrs gjahr poper,
        ls_acc   TYPE ty_acc_sum,
        ls_docs  TYPE ty_doc_sum,
        ls_cc    TYPE ty_cc,
        lv_belnr TYPE acdoca-belnr,
        lv_cnt   TYPE i,
        lv_msg   TYPE string.

  FIELD-SYMBOLS: <ls_acc>  TYPE ty_acc_sum,
                 <ls_docs> TYPE ty_doc_sum.

  " totals per account and indicators per document, valid rows only
  LOOP AT gt_line ASSIGNING FIELD-SYMBOL(<ls_line>) WHERE status <> 'E' AND status <> 'Z'.
    READ TABLE lt_acc ASSIGNING <ls_acc>
         WITH TABLE KEY rbukrs = <ls_line>-rbukrs gjahr = <ls_line>-gjahr
                        poper  = <ls_line>-poper  racct = <ls_line>-racct.
    IF sy-subrc <> 0.
      CLEAR ls_acc.
      ls_acc-rbukrs = <ls_line>-rbukrs.
      ls_acc-gjahr  = <ls_line>-gjahr.
      ls_acc-poper  = <ls_line>-poper.
      ls_acc-racct  = <ls_line>-racct.
      INSERT ls_acc INTO TABLE lt_acc ASSIGNING <ls_acc>.
    ENDIF.
    <ls_acc>-hsl = <ls_acc>-hsl + <ls_line>-hsl.
    <ls_acc>-ksl = <ls_acc>-ksl + <ls_line>-ksl.
    <ls_acc>-osl = <ls_acc>-osl + <ls_line>-osl.

    READ TABLE lt_docs ASSIGNING <ls_docs>
         WITH TABLE KEY rbukrs = <ls_line>-rbukrs gjahr = <ls_line>-gjahr poper = <ls_line>-poper.
    IF sy-subrc <> 0.
      CLEAR ls_docs.
      ls_docs-rbukrs = <ls_line>-rbukrs.
      ls_docs-gjahr  = <ls_line>-gjahr.
      ls_docs-poper  = <ls_line>-poper.
      INSERT ls_docs INTO TABLE lt_docs ASSIGNING <ls_docs>.
    ENDIF.
    IF <ls_line>-hsl <> 0.
      <ls_docs>-any_hsl = abap_true.
    ENDIF.
    IF <ls_line>-osl <> 0.
      <ls_docs>-any_osl = abap_true.
    ENDIF.
  ENDLOOP.

  " 1 + 2: per document
  LOOP AT lt_docs ASSIGNING <ls_docs>.
    lv_belnr = |{ gc_belnr_root }{ <ls_docs>-poper }|.
    SELECT COUNT( * )
      FROM acdoca
      WHERE rldnr  = @gc_rldnr
        AND rbukrs = @<ls_docs>-rbukrs
        AND gjahr  = @<ls_docs>-gjahr
        AND belnr  = @lv_belnr
      INTO @lv_cnt.
    IF lv_cnt > 0.
      PERFORM err_document USING <ls_docs>-rbukrs <ls_docs>-gjahr <ls_docs>-poper
        |Document { lv_belnr } already exists for { <ls_docs>-rbukrs } { <ls_docs>-gjahr } - run the undo first|.
    ENDIF.

    READ TABLE gt_cc INTO ls_cc WITH TABLE KEY rbukrs = <ls_docs>-rbukrs.
    IF sy-subrc = 0 AND ls_cc-rocur IS NOT INITIAL AND
       <ls_docs>-any_hsl = abap_true AND <ls_docs>-any_osl = abap_false.
      PERFORM err_document USING <ls_docs>-rbukrs <ls_docs>-gjahr <ls_docs>-poper
        |Company code { <ls_docs>-rbukrs } has third currency { ls_cc-rocur } - column 10 is empty|.
    ENDIF.
  ENDLOOP.

  " 3: per account
  LOOP AT lt_acc ASSIGNING <ls_acc> WHERE hsl <> 0 OR ksl <> 0 OR osl <> 0.
    lv_msg = |Account { <ls_acc>-racct } does not net to zero:| &&
             | LC { <ls_acc>-hsl } GC { <ls_acc>-ksl } 3C { <ls_acc>-osl }|.
    LOOP AT gt_line ASSIGNING <ls_line>
         WHERE rbukrs = <ls_acc>-rbukrs AND gjahr = <ls_acc>-gjahr
           AND poper  = <ls_acc>-poper  AND racct = <ls_acc>-racct
           AND status <> 'E' AND status <> 'Z'.
      PERFORM add_err USING lv_msg CHANGING <ls_line>.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ERR_DOCUMENT
*&   Mark every valid row of one company code / year / period.
*&---------------------------------------------------------------------*
FORM err_document USING iv_bukrs TYPE acdoca-rbukrs
                        iv_gjahr TYPE acdoca-gjahr
                        iv_poper TYPE acdoca-poper
                        iv_text  TYPE csequence.
  LOOP AT gt_line ASSIGNING FIELD-SYMBOL(<ls_line>)
       WHERE rbukrs = iv_bukrs AND gjahr = iv_gjahr AND poper = iv_poper
         AND status <> 'E' AND status <> 'Z'.
    PERFORM add_err USING iv_text CHANGING <ls_line>.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ASSIGN_DOCUMENTS
*&   One document per company code / year / period; line numbers 1..n
*&   in key order. Done in test mode too, so the list shows them.
*&---------------------------------------------------------------------*
FORM assign_documents.
  DATA ls_doc TYPE ty_doc.
  FIELD-SYMBOLS <ls_doc> TYPE ty_doc.

  SORT gt_line BY rbukrs gjahr poper racct vname egrup recid rowno.

  LOOP AT gt_line ASSIGNING FIELD-SYMBOL(<ls_line>) WHERE status = space.
    READ TABLE gt_doc ASSIGNING <ls_doc>
         WITH TABLE KEY rbukrs = <ls_line>-rbukrs gjahr = <ls_line>-gjahr poper = <ls_line>-poper.
    IF sy-subrc <> 0.
      CLEAR ls_doc.
      ls_doc-rbukrs = <ls_line>-rbukrs.
      ls_doc-gjahr  = <ls_line>-gjahr.
      ls_doc-poper  = <ls_line>-poper.
      ls_doc-belnr  = |{ gc_belnr_root }{ <ls_line>-poper }|.
      ls_doc-budat  = <ls_line>-budat.
      INSERT ls_doc INTO TABLE gt_doc ASSIGNING <ls_doc>.
    ENDIF.
    <ls_doc>-lines  = <ls_doc>-lines + 1.
    <ls_line>-belnr = <ls_doc>-belnr.
    <ls_line>-docln = <ls_doc>-lines.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form POST_OR_TEST
*&   Errors anywhere -> nothing is posted, valid rows are marked N.
*&   Test run -> valid rows marked T. Update run -> INSERT per document,
*&   COMMIT on success, ROLLBACK on a rejected insert.
*&---------------------------------------------------------------------*
FORM post_or_test.
  DATA: lt_ins   TYPE STANDARD TABLE OF acdoca WITH DEFAULT KEY,
        ls_acd   TYPE acdoca,
        ls_cc    TYPE ty_cc,
        lv_dbcnt TYPE i,
        lv_errs  TYPE i.

  LOOP AT gt_line TRANSPORTING NO FIELDS WHERE status = 'E'.
    lv_errs = lv_errs + 1.
  ENDLOOP.

  IF lv_errs > 0.
    LOOP AT gt_line ASSIGNING FIELD-SYMBOL(<ls_line>) WHERE status = space.
      <ls_line>-status  = 'N'.
      <ls_line>-message = 'Not posted - the file has errors'.
    ENDLOOP.
    RETURN.
  ENDIF.

  IF p_test = abap_true.
    LOOP AT gt_line ASSIGNING <ls_line> WHERE status = space.
      <ls_line>-status  = 'T'.
      <ls_line>-message = 'Test run - would be posted'.
    ENDLOOP.
    RETURN.
  ENDIF.

  LOOP AT gt_doc ASSIGNING FIELD-SYMBOL(<ls_doc>).
    READ TABLE gt_cc INTO ls_cc WITH TABLE KEY rbukrs = <ls_doc>-rbukrs.

    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD <ls_doc>-rbukrs
      ID 'ACTVT' FIELD '01'.
    IF sy-subrc <> 0.
      <ls_doc>-status  = 'F'.
      <ls_doc>-message = |No authorization for company code { <ls_doc>-rbukrs } (F_BKPF_BUK 01)|.
      PERFORM set_doc_status USING <ls_doc>.
      CONTINUE.
    ENDIF.

    CLEAR lt_ins.
    LOOP AT gt_line ASSIGNING <ls_line>
         WHERE rbukrs = <ls_doc>-rbukrs AND gjahr = <ls_doc>-gjahr
           AND poper  = <ls_doc>-poper  AND status = space.
      PERFORM build_acdoca_line USING <ls_line> ls_cc CHANGING ls_acd.
      APPEND ls_acd TO lt_ins.
    ENDLOOP.
    IF lt_ins IS INITIAL.
      CONTINUE.
    ENDIF.

    INSERT acdoca FROM TABLE @lt_ins ACCEPTING DUPLICATE KEYS.
    lv_dbcnt = sy-dbcnt.
    IF sy-subrc = 0.
      COMMIT WORK.
      <ls_doc>-status  = 'S'.
      <ls_doc>-message = |Posted: document { <ls_doc>-belnr }, { lv_dbcnt } lines|.
    ELSE.
      ROLLBACK WORK.
      <ls_doc>-status  = 'F'.
      <ls_doc>-message = |Insert rejected for document { <ls_doc>-belnr } (duplicate key) - nothing written|.
    ENDIF.
    PERFORM set_doc_status USING <ls_doc>.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_DOC_STATUS
*&   Copy the document result to its lines.
*&---------------------------------------------------------------------*
FORM set_doc_status USING is_doc TYPE ty_doc.
  LOOP AT gt_line ASSIGNING FIELD-SYMBOL(<ls_line>)
       WHERE rbukrs = is_doc-rbukrs AND gjahr = is_doc-gjahr
         AND poper  = is_doc-poper  AND status = space.
    <ls_line>-status  = is_doc-status.
    <ls_line>-message = is_doc-message.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_ACDOCA_LINE
*&   One ACDOCA line from a validated row and its company code context.
*&---------------------------------------------------------------------*
FORM build_acdoca_line USING    is_line TYPE ty_line
                                is_cc   TYPE ty_cc
                       CHANGING cs_acd  TYPE acdoca.
  CLEAR cs_acd.

  " key and document
  cs_acd-rldnr       = gc_rldnr.
  cs_acd-rbukrs      = is_line-rbukrs.
  cs_acd-gjahr       = is_line-gjahr.
  cs_acd-belnr       = is_line-belnr.
  cs_acd-docln       = is_line-docln.
  cs_acd-ryear       = is_line-gjahr.
  cs_acd-rrcty       = gc_rrcty.
  cs_acd-blart       = gc_blart.
  cs_acd-awtyp       = gc_awtyp.
  cs_acd-awref       = is_line-belnr.
  cs_acd-aworg       = |{ is_line-rbukrs }{ is_line-gjahr }|.
  cs_acd-poper       = is_line-poper.
  cs_acd-fiscyearper = |{ is_line-gjahr }{ is_line-poper }|.
  cs_acd-budat       = is_line-budat.
  cs_acd-bldat       = is_line-budat.
  cs_acd-periv       = is_cc-periv.
  cs_acd-ktopl       = is_cc-ktopl.
  cs_acd-kokrs       = is_cc-kokrs.

  " account and assignments
  cs_acd-racct          = is_line-racct.
  cs_acd-koart          = is_line-koart.
  cs_acd-glaccount_type = is_line-glaccount_type.
  cs_acd-vname          = is_line-vname.
  cs_acd-egrup          = is_line-egrup.
  cs_acd-recid          = is_line-recid.
  cs_acd-rcntr          = is_line-rcntr.
  cs_acd-aufnr          = is_line-aufnr.
  cs_acd-ps_psp_pnr     = is_line-ps_psp_pnr.
  cs_acd-ps_posid       = is_line-ps_posid.
  cs_acd-ps_prj_pnr     = is_line-ps_prj_pnr.
  cs_acd-ps_pspid       = is_line-ps_pspid.
  cs_acd-prctr          = is_line-prctr.
  cs_acd-segment        = is_line-segment.
  cs_acd-sgtxt          = is_line-sgtxt.

*----------------------------------------------------------------------*
* ASSUMPTION: transaction currency = local currency (no RTCUR in the
*   recon key, decision 02/11/26): TSL and WSL carry the local amount.
*   Group reporting reads HSL / KSL (and OSL where it exists).
*----------------------------------------------------------------------*
  cs_acd-rtcur  = is_cc-waers.
  cs_acd-rwcur  = is_cc-waers.
  cs_acd-rhcur  = is_cc-waers.
  cs_acd-rkcur  = is_cc-rkcur.
  cs_acd-rocur  = is_cc-rocur.
  cs_acd-rfccur = is_cc-rfccur.
  cs_acd-tsl    = is_line-hsl.
  cs_acd-wsl    = is_line-hsl.
  cs_acd-hsl    = is_line-hsl.
  cs_acd-ksl    = is_line-ksl.
  IF is_cc-rocur IS NOT INITIAL.
    cs_acd-osl = is_line-osl.
  ENDIF.
  IF is_cc-rfccur IS NOT INITIAL.
    IF is_cc-rfccur = is_cc-waers.
      cs_acd-fcsl = is_line-hsl.
    ELSEIF is_cc-rfccur = is_cc-rkcur.
      cs_acd-fcsl = is_line-ksl.
    ELSEIF is_cc-rfccur = is_cc-rocur.
      cs_acd-fcsl = is_line-osl.
    ENDIF.
  ENDIF.

  IF is_line-hsl < 0 OR ( is_line-hsl = 0 AND is_line-ksl < 0 ).
    cs_acd-drcrk = 'H'.
  ELSE.
    cs_acd-drcrk = 'S'.
  ENDIF.

  " markers and audit
  cs_acd-mig_source  = gc_mig_source.
  cs_acd-sdm_version = gc_sdm_version.
  cs_acd-usnam       = sy-uname.
  GET TIME STAMP FIELD cs_acd-timestamp.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form UNDO_ALIGNMENT
*&   Delete the lines this program created - document type ZJ and
*&   reference transaction ZJVA - for the selected company codes,
*&   years and periods. Test run counts only.
*&---------------------------------------------------------------------*
FORM undo_alignment.
  DATA: lv_cnt   TYPE i,
        lv_dbcnt TYPE i,
        lv_subrc TYPE sy-subrc.

  SELECT DISTINCT rbukrs
    FROM acdoca
    WHERE rldnr   = @gc_rldnr
      AND rbukrs IN @s_bukrs
      AND gjahr  IN @s_gjahr
      AND poper  IN @s_poper
      AND blart   = @gc_blart
      AND awtyp   = @gc_awtyp
    ORDER BY rbukrs
    INTO TABLE @DATA(lt_bukrs).
  IF lt_bukrs IS INITIAL.
    MESSAGE |No alignment lines (type { gc_blart }, ref. { gc_awtyp }) found for this selection|
      TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF p_test = abap_true.
    WRITE: / 'TEST RUN - nothing is deleted'.
  ELSE.
    WRITE: / 'UPDATE RUN - alignment lines are deleted'.
  ENDIF.
  SKIP.

  LOOP AT lt_bukrs ASSIGNING FIELD-SYMBOL(<ls_bukrs>).
    SELECT COUNT( * )
      FROM acdoca
      WHERE rldnr  = @gc_rldnr
        AND rbukrs = @<ls_bukrs>-rbukrs
        AND gjahr IN @s_gjahr
        AND poper IN @s_poper
        AND blart  = @gc_blart
        AND awtyp  = @gc_awtyp
      INTO @lv_cnt.

    IF p_test = abap_true.
      WRITE: / |Company code { <ls_bukrs>-rbukrs }: { lv_cnt } alignment lines would be deleted|.
      CONTINUE.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD <ls_bukrs>-rbukrs
      ID 'ACTVT' FIELD '01'.
    IF sy-subrc <> 0.
      WRITE: / |Company code { <ls_bukrs>-rbukrs }: no authorization (F_BKPF_BUK 01) - { lv_cnt } lines kept|.
      CONTINUE.
    ENDIF.

    DELETE FROM acdoca
      WHERE rldnr  = @gc_rldnr
        AND rbukrs = @<ls_bukrs>-rbukrs
        AND gjahr IN @s_gjahr
        AND poper IN @s_poper
        AND blart  = @gc_blart
        AND awtyp  = @gc_awtyp.
    lv_subrc = sy-subrc.
    lv_dbcnt = sy-dbcnt.
    IF lv_subrc = 0.
      COMMIT WORK.
      WRITE: / |Company code { <ls_bukrs>-rbukrs }: { lv_dbcnt } alignment lines deleted|.
    ELSE.
      ROLLBACK WORK.
      WRITE: / |Company code { <ls_bukrs>-rbukrs }: delete failed, nothing changed|.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_RESULT
*&   One SALV list: every file row with status and message, plus the
*&   document / line / posting date it got.
*&---------------------------------------------------------------------*
FORM display_result.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lv_title   TYPE lvc_title,
        lv_e       TYPE i,
        lv_z       TYPE i,
        lv_t       TYPE i,
        lv_n       TYPE i,
        lv_s       TYPE i,
        lv_f       TYPE i.

  LOOP AT gt_line ASSIGNING FIELD-SYMBOL(<ls_line>).
    CASE <ls_line>-status.
      WHEN 'E'.
        lv_e = lv_e + 1.
        <ls_line>-status_txt = 'Error'.
      WHEN 'Z'.
        lv_z = lv_z + 1.
        <ls_line>-status_txt = 'Skipped - zero amounts'.
      WHEN 'T'.
        lv_t = lv_t + 1.
        <ls_line>-status_txt = 'Test - would be posted'.
      WHEN 'N'.
        lv_n = lv_n + 1.
        <ls_line>-status_txt = 'Not posted - file has errors'.
      WHEN 'S'.
        lv_s = lv_s + 1.
        <ls_line>-status_txt = 'Posted'.
      WHEN 'F'.
        lv_f = lv_f + 1.
        <ls_line>-status_txt = 'Failed'.
    ENDCASE.
  ENDLOOP.

  SORT gt_line BY rowno.

  IF lv_e > 0.
    MESSAGE |Nothing posted: { lv_e } rows with errors, { lv_n } valid rows held back - correct the file|
      TYPE 'S' DISPLAY LIKE 'W'.
    lv_title = |JVA alignment upload - { lv_e } errors - nothing posted|.
  ELSEIF p_test = abap_true.
    MESSAGE |Test run: { lv_t } lines would be posted in { lines( gt_doc ) } documents, { lv_z } zero rows skipped|
      TYPE 'S'.
    lv_title = |JVA alignment upload - TEST RUN - { lv_t } lines in { lines( gt_doc ) } documents|.
  ELSE.
    MESSAGE |{ lv_s } lines posted, { lv_f } failed, { lv_z } zero rows skipped| TYPE 'S'.
    lv_title = |JVA alignment upload - UPDATE RUN - { lv_s } lines posted, { lv_f } failed|.
  ENDIF.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_line ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_alv->get_functions( )->set_all( abap_true ).
  lo_columns = lo_alv->get_columns( ).
  lo_columns->set_optimize( abap_true ).

  PERFORM set_col_text USING lo_columns 'ROWNO'
    'Excel Row'  'Excel Row'            'Row number in the uploaded file'.
  PERFORM set_col_text USING lo_columns 'STATUS'
    'St'         'Status'               'Status'.
  PERFORM set_col_text USING lo_columns 'STATUS_TXT'
    'Status'     'Status Text'          'Status Text'.
  PERFORM set_col_text USING lo_columns 'HSL'
    'Local Amt'  'Amount Local Curr.'   'Amount in Local Currency to post'.
  PERFORM set_col_text USING lo_columns 'KSL'
    'Group Amt'  'Amount Group Curr.'   'Amount in Group Currency to post'.
  PERFORM set_col_text USING lo_columns 'OSL'
    '3rd Amt'    'Amount 3rd Curr.'     'Amount in Third Currency to post'.
  PERFORM set_col_text USING lo_columns 'MESSAGE'
    'Message'    'Message'              'Message'.
  PERFORM hide_col USING lo_columns 'PS_PSP_PNR'.
  PERFORM hide_col USING lo_columns 'PS_PRJ_PNR'.
  PERFORM hide_col USING lo_columns 'PS_PSPID'.
  PERFORM hide_col USING lo_columns 'KOART'.
  PERFORM hide_col USING lo_columns 'GLACCOUNT_TYPE'.

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
      MESSAGE |ALV column { iv_name } not found| TYPE 'S' DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form HIDE_COL
*&   Technical column - kept in the table, not shown.
*&---------------------------------------------------------------------*
FORM hide_col USING io_columns TYPE REF TO cl_salv_columns_table
                    iv_name    TYPE lvc_fname.
  DATA lo_col TYPE REF TO cl_salv_column.

  TRY.
      lo_col = io_columns->get_column( iv_name ).
      lo_col->set_technical( abap_true ).
    CATCH cx_salv_not_found.
      MESSAGE |ALV column { iv_name } not found| TYPE 'S' DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.
