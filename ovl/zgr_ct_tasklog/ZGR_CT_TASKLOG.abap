*&---------------------------------------------------------------------*
*& Report         : ZGR_CT_TASKLOG
*& Title          : Group Reporting - read the currency translation task log
*& Project        : OVL                          Module: FI / Group Reporting
*& Related FS     : None - ST05 trace of CXCD / task log, 06.11.2026
*&                  (repo: ovl/zgr_ct_tasklog/trace/)
*& Author         : Arnav Johri                  Date: 06.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Reads the currency translation task log the way the Fiori task log
*&   (OData service FIN_CONS_GENERICLOG_SRV, reached from CXCD) reads it:
*&     1. log headers from table FINCS_LOG_HEADER for the selection
*&        (consolidation group, fiscal year / period, version, task, or
*&        a log number typed directly), newest first, deleted logs
*&        excluded;
*&     2. the log lines from CDS view C_CNSLDTNCRCYTRNSLTNTSKLG, keyed
*&        by the task log UUID, which is the header's log number;
*&     3. one ALV list, header fields in front of the log line fields.
*&
*&   The view carries CDS access control. A user without the group
*&   reporting authorisation gets no rows and no error - the program
*&   says so instead of showing an empty list.
*&
*& CHANGE HISTORY
*&   06.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zgr_ct_tasklog.

TABLES: fincs_log_header.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
* Log header - table FINCS_LOG_HEADER (column names from the ST05 trace)
TYPES: BEGIN OF ty_hdr,
         cnsldtnlognumber TYPE fincs_log_header-cnsldtnlognumber,
         cnsldtngroup     TYPE fincs_log_header-cnsldtngroup,
         cnsldtnunit      TYPE fincs_log_header-cnsldtnunit,
         fiscalyear       TYPE fincs_log_header-fiscalyear,
         fiscalperiod     TYPE fincs_log_header-fiscalperiod,
         cnsldtnversion   TYPE fincs_log_header-cnsldtnversion,
         cnsldtntask      TYPE fincs_log_header-cnsldtntask,
         cnsldtntasktype  TYPE fincs_log_header-cnsldtntasktype,
         cnsldtnlogdate   TYPE fincs_log_header-cnsldtnlogdate,
         cnsldtnlogtime   TYPE fincs_log_header-cnsldtnlogtime,
         userid           TYPE fincs_log_header-userid,
         iscnsldtntestrun TYPE fincs_log_header-iscnsldtntestrun,
         status           TYPE fincs_log_header-status,
       END OF ty_hdr.

* Output row - header fields first, then the log line fields of the view
* C_CNSLDTNCRCYTRNSLTNTSKLG (element names from the ST05 trace)
TYPES: BEGIN OF ty_out,
         cnsldtnlognumber              TYPE fincs_log_header-cnsldtnlognumber,
         cnsldtngroup                  TYPE fincs_log_header-cnsldtngroup,
         fiscalyear                    TYPE fincs_log_header-fiscalyear,
         fiscalperiod                  TYPE fincs_log_header-fiscalperiod,
         cnsldtnversion                TYPE fincs_log_header-cnsldtnversion,
         cnsldtntask                   TYPE fincs_log_header-cnsldtntask,
         cnsldtntasktype               TYPE fincs_log_header-cnsldtntasktype,
         cnsldtnlogdate                TYPE fincs_log_header-cnsldtnlogdate,
         cnsldtnlogtime                TYPE fincs_log_header-cnsldtnlogtime,
         userid                        TYPE fincs_log_header-userid,
         iscnsldtntestrun              TYPE fincs_log_header-iscnsldtntestrun,
         status                        TYPE fincs_log_header-status,
         cnsldtntaskloguuid            TYPE c_cnsldtncrcytrnsltntsklg-cnsldtntaskloguuid,
         consolidationunit             TYPE c_cnsldtncrcytrnsltntsklg-consolidationunit,
         consolidationunittext         TYPE c_cnsldtncrcytrnsltntsklg-consolidationunittext,
         sequencenumber                TYPE c_cnsldtncrcytrnsltntsklg-sequencenumber,
         cnsldtntasklogitemtype        TYPE c_cnsldtncrcytrnsltntsklg-cnsldtntasklogitemtype,
         cnsldtntasklogitemtypetxt     TYPE c_cnsldtncrcytrnsltntsklg-cnsldtntasklogitemtypetxt,
         cnsldtnfinancialstatementitem TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnfinancialstatementitem,
         financialstatementitemtext    TYPE c_cnsldtncrcytrnsltntsklg-financialstatementitemtext,
         subitemcategory               TYPE c_cnsldtncrcytrnsltntsklg-subitemcategory,
         subitem                       TYPE c_cnsldtncrcytrnsltntsklg-subitem,
         subitemtext                   TYPE c_cnsldtncrcytrnsltntsklg-subitemtext,
         cnsldtncrcytranslationkey     TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytranslationkey,
         cnsldtncrcytranslationmethod  TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytranslationmethod,
         cnsldtnrefexchangeratetype    TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnrefexchangeratetype,
         cnsldtnexchangerate           TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnexchangerate,
         cnsldtnjrnlentryamtinloclcrcy TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtinloclcrcy,
         cnsldtnjrnlentryamtloclcrcy   TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtloclcrcy,
         cnsldtnjrnlentryamtingrpcrcy  TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtingrpcrcy,
         cnsldtnjrnlentryamtgrpcrcy    TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtgrpcrcy,
         calculatedrefamount           TYPE c_cnsldtncrcytrnsltntsklg-calculatedrefamount,
         calculateddiffamount          TYPE c_cnsldtncrcytrnsltntsklg-calculateddiffamount,
         cnsldtncrcytrnsltndifffsitem  TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytrnsltndifffsitem,
         cnsldtncrcytrnsltndiffsubitem TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytrnsltndiffsubitem,
       END OF ty_out.

*----------------------------------------------------------------------*
* Data
*----------------------------------------------------------------------*
DATA: gt_hdr TYPE SORTED TABLE OF ty_hdr WITH UNIQUE KEY cnsldtnlognumber,
      gt_out TYPE STANDARD TABLE OF ty_out,
      go_alv TYPE REF TO cl_salv_table,
      gv_msg TYPE string.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_group FOR fincs_log_header-cnsldtngroup,
                s_year  FOR fincs_log_header-fiscalyear,
                s_perid FOR fincs_log_header-fiscalperiod,
                s_vers  FOR fincs_log_header-cnsldtnversion,
                s_task  FOR fincs_log_header-cnsldtntask,
                s_lognr FOR fincs_log_header-cnsldtnlognumber.
PARAMETERS:     p_maxlg TYPE i DEFAULT 1.
SELECTION-SCREEN END OF BLOCK b1.
* Selection texts (SE38 -> Goto -> Text elements): S_GROUP Consolidation Group,
* S_YEAR Fiscal Year, S_PERID Fiscal Period, S_VERS Consolidation Version,
* S_TASK Consolidation Task, S_LOGNR Log Number, P_MAXLG Number of latest logs.

*----------------------------------------------------------------------*
* Events
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF p_maxlg < 1.
    MESSAGE 'Number of latest logs must be at least 1' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM read_headers.
  IF gt_hdr IS INITIAL.
    MESSAGE 'No task log header found for this selection' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM read_log_lines.
  IF gt_out IS INITIAL.
    gv_msg = 'Log header found, but the view returned no line: not a currency translation log,'.
    gv_msg = gv_msg && ' or no authorisation for the consolidation group'.
    MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM add_header_fields.

END-OF-SELECTION.
  PERFORM display_alv.

*&---------------------------------------------------------------------*
*& Form read_headers
*&---------------------------------------------------------------------*
* Newest logs first, deleted ones excluded, at most P_MAXLG of them.
* ASSUMPTION: DELETION = ' ' marks a live log. The task log service reads
* the deleted ones with DELETION = 'X' (ST05 trace, 06/11/26).
*----------------------------------------------------------------------*
FORM read_headers.
  SELECT cnsldtnlognumber, cnsldtngroup, cnsldtnunit, fiscalyear, fiscalperiod,
         cnsldtnversion, cnsldtntask, cnsldtntasktype, cnsldtnlogdate, cnsldtnlogtime,
         userid, iscnsldtntestrun, status
    FROM fincs_log_header
    WHERE cnsldtngroup     IN @s_group
      AND fiscalyear       IN @s_year
      AND fiscalperiod     IN @s_perid
      AND cnsldtnversion   IN @s_vers
      AND cnsldtntask      IN @s_task
      AND cnsldtnlognumber IN @s_lognr
      AND deletion          = @space
    ORDER BY cnsldtnlogdate DESCENDING, cnsldtnlogtime DESCENDING
    INTO CORRESPONDING FIELDS OF TABLE @gt_hdr
    UP TO @p_maxlg ROWS.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form read_log_lines
*&---------------------------------------------------------------------*
* The log lines of the selected headers from the CDS view behind the
* Fiori task log. Field names are the ones the service selected in the
* ST05 trace of 06/11/26 (FROM "C_CNSLDTNCRCYTRNSLTNTSKLG").
* ASSUMPTION: CNSLDTNTASKLOGUUID of the view is the same value as
* CNSLDTNLOGNUMBER of FINCS_LOG_HEADER - the trace bound the one 32-char
* value 7C1E520E31821FE1B6A1A9988662571B to both, as a character string.
* ASSUMPTION: the view is access-controlled (DCL); without the group
* reporting authorisation the SELECT returns no row and sy-subrc 4.
*----------------------------------------------------------------------*
FORM read_log_lines.
  IF gt_hdr IS NOT INITIAL.
    SELECT cnsldtntaskloguuid, consolidationunit, consolidationunittext,
           sequencenumber, cnsldtntasklogitemtype, cnsldtntasklogitemtypetxt,
           cnsldtnfinancialstatementitem, financialstatementitemtext,
           subitemcategory, subitem, subitemtext,
           cnsldtncrcytranslationkey, cnsldtncrcytranslationmethod,
           cnsldtnrefexchangeratetype, cnsldtnexchangerate,
           cnsldtnjrnlentryamtinloclcrcy, cnsldtnjrnlentryamtloclcrcy,
           cnsldtnjrnlentryamtingrpcrcy, cnsldtnjrnlentryamtgrpcrcy,
           calculatedrefamount, calculateddiffamount,
           cnsldtncrcytrnsltndifffsitem, cnsldtncrcytrnsltndiffsubitem
      FROM c_cnsldtncrcytrnsltntsklg
      FOR ALL ENTRIES IN @gt_hdr
      WHERE cnsldtntaskloguuid = @gt_hdr-cnsldtnlognumber
      INTO CORRESPONDING FIELDS OF TABLE @gt_out.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form add_header_fields
*&---------------------------------------------------------------------*
* Copy the header fields of each log into its lines, then order the list
* the way the Fiori log shows it.
*----------------------------------------------------------------------*
FORM add_header_fields.
  DATA ls_hdr TYPE ty_hdr.

  LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<ls_out>).
    READ TABLE gt_hdr INTO ls_hdr WITH TABLE KEY cnsldtnlognumber = <ls_out>-cnsldtntaskloguuid.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING ls_hdr TO <ls_out>.
    ENDIF.
  ENDLOOP.

  SORT gt_out BY cnsldtnlogdate DESCENDING cnsldtnlogtime DESCENDING
                 consolidationunit sequencenumber.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv.
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                              CHANGING  t_table      = gt_out ).

      go_alv->get_functions( )->set_all( abap_true ).
      go_alv->get_columns( )->set_optimize( abap_true ).
      go_alv->get_display_settings( )->set_striped_pattern( abap_true ).

      PERFORM set_column_texts.

      go_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_column_texts
*&---------------------------------------------------------------------*
* Readable headings. The view's own labels are kept where SALV has them;
* these cover the header fields and the long technical names.
*----------------------------------------------------------------------*
FORM set_column_texts.
  PERFORM col_text USING 'CNSLDTNLOGNUMBER'              'Log Number'.
  PERFORM col_text USING 'CNSLDTNGROUP'                  'Consolidation Group'.
  PERFORM col_text USING 'FISCALYEAR'                    'Fiscal Year'.
  PERFORM col_text USING 'FISCALPERIOD'                  'Fiscal Period'.
  PERFORM col_text USING 'CNSLDTNVERSION'                'Version'.
  PERFORM col_text USING 'CNSLDTNTASK'                   'Task'.
  PERFORM col_text USING 'CNSLDTNTASKTYPE'               'Task Type'.
  PERFORM col_text USING 'CNSLDTNLOGDATE'                'Log Date'.
  PERFORM col_text USING 'CNSLDTNLOGTIME'                'Log Time'.
  PERFORM col_text USING 'USERID'                        'Run By'.
  PERFORM col_text USING 'ISCNSLDTNTESTRUN'              'Test Run'.
  PERFORM col_text USING 'STATUS'                        'Log Status'.
  PERFORM col_text USING 'CNSLDTNTASKLOGUUID'            'Task Log UUID'.
  PERFORM col_text USING 'CONSOLIDATIONUNIT'             'Consolidation Unit'.
  PERFORM col_text USING 'CONSOLIDATIONUNITTEXT'         'Consolidation Unit Name'.
  PERFORM col_text USING 'SEQUENCENUMBER'                'Sequence'.
  PERFORM col_text USING 'CNSLDTNTASKLOGITEMTYPE'        'Log Item Type'.
  PERFORM col_text USING 'CNSLDTNTASKLOGITEMTYPETXT'     'Log Item Type Text'.
  PERFORM col_text USING 'CNSLDTNFINANCIALSTATEMENTITEM' 'FS Item'.
  PERFORM col_text USING 'FINANCIALSTATEMENTITEMTEXT'    'FS Item Text'.
  PERFORM col_text USING 'SUBITEMCATEGORY'               'Subitem Category'.
  PERFORM col_text USING 'SUBITEM'                       'Subitem'.
  PERFORM col_text USING 'SUBITEMTEXT'                   'Subitem Text'.
  PERFORM col_text USING 'CNSLDTNCRCYTRANSLATIONKEY'     'Translation Key'.
  PERFORM col_text USING 'CNSLDTNCRCYTRANSLATIONMETHOD'  'Translation Method'.
  PERFORM col_text USING 'CNSLDTNREFEXCHANGERATETYPE'    'Reference Rate Type'.
  PERFORM col_text USING 'CNSLDTNEXCHANGERATE'           'Exchange Rate'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTINLOCLCRCY' 'Amount in Local Currency'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTLOCLCRCY'   'Local Currency'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTINGRPCRCY'  'Amount in Group Currency'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTGRPCRCY'    'Group Currency'.
  PERFORM col_text USING 'CALCULATEDREFAMOUNT'           'Reference Amount'.
  PERFORM col_text USING 'CALCULATEDDIFFAMOUNT'          'Translation Difference'.
  PERFORM col_text USING 'CNSLDTNCRCYTRNSLTNDIFFFSITEM'  'Difference FS Item'.
  PERFORM col_text USING 'CNSLDTNCRCYTRNSLTNDIFFSUBITEM' 'Difference Subitem'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form col_text
*&---------------------------------------------------------------------*
FORM col_text USING iv_name TYPE clike
                    iv_text TYPE clike.
  DATA: lv_name   TYPE lvc_fname,
        lv_long   TYPE scrtext_l,
        lv_medium TYPE scrtext_m.

  lv_name   = iv_name.
  lv_long   = iv_text.
  lv_medium = iv_text.
  TRY.
      DATA(lo_col) = go_alv->get_columns( )->get_column( lv_name ).
      lo_col->set_long_text( lv_long ).
      lo_col->set_medium_text( lv_medium ).
    CATCH cx_salv_not_found.
      " column not in the list - nothing to label
  ENDTRY.
ENDFORM.
