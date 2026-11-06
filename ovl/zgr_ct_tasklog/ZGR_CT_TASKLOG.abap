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
*&     3. one ALV list. Columns 1-23 are the Fiori task log "Items"
*&        export, same order and headings, so the two lists compare
*&        side by side; then the currency keys, the difference subitem
*&        code, the log UUID and the log header fields.
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

* Output row - columns 1-23 as in the Fiori "Items" export, then the extras,
* then the log header. Element names from the ST05 trace of 06/11/26.
TYPES: BEGIN OF ty_out,
         consolidationunit             TYPE c_cnsldtncrcytrnsltntsklg-consolidationunit,
         consolidationunittext         TYPE c_cnsldtncrcytrnsltntsklg-consolidationunittext,
         cnsldtncrcytranslationmethod  TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytranslationmethod,
         sequencenumber                TYPE c_cnsldtncrcytrnsltntsklg-sequencenumber,
         setidentificationitem         TYPE c_cnsldtncrcytrnsltntsklg-setidentificationitem,
         cnsldtntasklogitemtype        TYPE c_cnsldtncrcytrnsltntsklg-cnsldtntasklogitemtype,
         cnsldtntasklogitemtypetxt     TYPE c_cnsldtncrcytrnsltntsklg-cnsldtntasklogitemtypetxt,
         cnsldtnfinancialstatementitem TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnfinancialstatementitem,
         financialstatementitemtext    TYPE c_cnsldtncrcytrnsltntsklg-financialstatementitemtext,
         subitemcategory               TYPE c_cnsldtncrcytrnsltntsklg-subitemcategory,
         subitemcategorytext           TYPE c_cnsldtncrcytrnsltntsklg-subitemcategorytext,
         subitem                       TYPE c_cnsldtncrcytrnsltntsklg-subitem,
         subitemtext                   TYPE c_cnsldtncrcytrnsltntsklg-subitemtext,
         cnsldtncrcytrnsltndifffsitem  TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytrnsltndifffsitem,
         crcytrnsltndifffinstmntitmtxt TYPE c_cnsldtncrcytrnsltntsklg-crcytrnsltndifffinstmntitmtxt,
         crcytrnsltndiffsubitemtxt     TYPE c_cnsldtncrcytrnsltntsklg-crcytrnsltndiffsubitemtxt,
         cnsldtncrcytranslationkey     TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytranslationkey,
         cnsldtnexchangerate           TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnexchangerate,
         cnsldtnjrnlentryamtinloclcrcy TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtinloclcrcy,
         cnsldtnjrnlentryamtingrpcrcy  TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtingrpcrcy,
         calculateddiffamount          TYPE c_cnsldtncrcytrnsltntsklg-calculateddiffamount,
         calculatedrefamount           TYPE c_cnsldtncrcytrnsltntsklg-calculatedrefamount,
         cnsldtnrefexchangeratetype    TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnrefexchangeratetype,
*        extras not in the export
         cnsldtnjrnlentryamtloclcrcy   TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtloclcrcy,
         cnsldtnjrnlentryamtgrpcrcy    TYPE c_cnsldtncrcytrnsltntsklg-cnsldtnjrnlentryamtgrpcrcy,
         cnsldtncrcytrnsltndiffsubitem TYPE c_cnsldtncrcytrnsltntsklg-cnsldtncrcytrnsltndiffsubitem,
         cnsldtntaskloguuid            TYPE c_cnsldtncrcytrnsltntsklg-cnsldtntaskloguuid,
*        log header
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
           cnsldtncrcytranslationmethod, sequencenumber, setidentificationitem,
           cnsldtntasklogitemtype, cnsldtntasklogitemtypetxt,
           cnsldtnfinancialstatementitem, financialstatementitemtext,
           subitemcategory, subitemcategorytext, subitem, subitemtext,
           cnsldtncrcytrnsltndifffsitem, crcytrnsltndifffinstmntitmtxt,
           cnsldtncrcytrnsltndiffsubitem, crcytrnsltndiffsubitemtxt,
           cnsldtncrcytranslationkey, cnsldtnexchangerate,
           cnsldtnjrnlentryamtinloclcrcy, cnsldtnjrnlentryamtloclcrcy,
           cnsldtnjrnlentryamtingrpcrcy, cnsldtnjrnlentryamtgrpcrcy,
           calculateddiffamount, calculatedrefamount, cnsldtnrefexchangeratetype
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
                 consolidationunit sequencenumber cnsldtnfinancialstatementitem
                 subitemcategory subitem cnsldtntasklogitemtype.
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
* Headings of columns 1-23 are the Fiori "Items" export headings, so the
* ALV and the export compare column for column.
*----------------------------------------------------------------------*
FORM set_column_texts.
  PERFORM col_text USING 'CONSOLIDATIONUNIT'               'Consolidation Unit'.
  PERFORM col_text USING 'CONSOLIDATIONUNITTEXT'           'Consolidation Unit Desc.'.
  PERFORM col_text USING 'CNSLDTNCRCYTRANSLATIONMETHOD'    'Translation Method'.
  PERFORM col_text USING 'SEQUENCENUMBER'                  'Sequence'.
  PERFORM col_text USING 'SETIDENTIFICATIONITEM'           'Selection ID'.
  PERFORM col_text USING 'CNSLDTNTASKLOGITEMTYPE'          'Item Type (Technical)'.
  PERFORM col_text USING 'CNSLDTNTASKLOGITEMTYPETXT'       'Item Type'.
  PERFORM col_text USING 'CNSLDTNFINANCIALSTATEMENTITEM'   'FS Item'.
  PERFORM col_text USING 'FINANCIALSTATEMENTITEMTEXT'      'FS Item Description'.
  PERFORM col_text USING 'SUBITEMCATEGORY'                 'SI Cat.'.
  PERFORM col_text USING 'SUBITEMCATEGORYTEXT'             'SI Category Description'.
  PERFORM col_text USING 'SUBITEM'                         'Subitem'.
  PERFORM col_text USING 'SUBITEMTEXT'                     'Subitem Description'.
  PERFORM col_text USING 'CNSLDTNCRCYTRNSLTNDIFFFSITEM'    'Difference Item'.
  PERFORM col_text USING 'CRCYTRNSLTNDIFFFINSTMNTITMTXT'   'Difference Item Desc.'.
  PERFORM col_text USING 'CRCYTRNSLTNDIFFSUBITEMTXT'       'Difference Subitem Desc.'.
  PERFORM col_text USING 'CNSLDTNCRCYTRANSLATIONKEY'       'CT Key'.
  PERFORM col_text USING 'CNSLDTNEXCHANGERATE'             'Exchange Rate'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTINLOCLCRCY'   'LC Amount'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTINGRPCRCY'    'GC Amount'.
  PERFORM col_text USING 'CALCULATEDDIFFAMOUNT'            'Translation Difference'.
  PERFORM col_text USING 'CALCULATEDREFAMOUNT'             'Reference Amount'.
  PERFORM col_text USING 'CNSLDTNREFEXCHANGERATETYPE'      'Reference Exchange Rate Indicator'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTLOCLCRCY'     'Local Currency'.
  PERFORM col_text USING 'CNSLDTNJRNLENTRYAMTGRPCRCY'      'Group Currency'.
  PERFORM col_text USING 'CNSLDTNCRCYTRNSLTNDIFFSUBITEM'   'Difference Subitem'.
  PERFORM col_text USING 'CNSLDTNTASKLOGUUID'              'Task Log UUID'.
  PERFORM col_text USING 'CNSLDTNLOGNUMBER'                'Log Number'.
  PERFORM col_text USING 'CNSLDTNGROUP'                    'Consolidation Group'.
  PERFORM col_text USING 'FISCALYEAR'                      'Fiscal Year'.
  PERFORM col_text USING 'FISCALPERIOD'                    'Fiscal Period'.
  PERFORM col_text USING 'CNSLDTNVERSION'                  'Version'.
  PERFORM col_text USING 'CNSLDTNTASK'                     'Task'.
  PERFORM col_text USING 'CNSLDTNTASKTYPE'                 'Task Type'.
  PERFORM col_text USING 'CNSLDTNLOGDATE'                  'Log Date'.
  PERFORM col_text USING 'CNSLDTNLOGTIME'                  'Log Time'.
  PERFORM col_text USING 'USERID'                          'Run By'.
  PERFORM col_text USING 'ISCNSLDTNTESTRUN'                'Test Run'.
  PERFORM col_text USING 'STATUS'                          'Log Status'.
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
