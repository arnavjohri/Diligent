*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_MAILF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  MAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM mail .

ENDFORM.
*BOC By SAP_ABAP on 05/10/26
*&---------------------------------------------------------------------*
*& Download / Upload of the timesheet table control (screen 9002)
*&
*& Create mode only. The user keys one row, downloads the rows to an
*& .xlsx workbook, adds the remaining rows in Excel and uploads the
*& workbook again; the uploaded rows replace what is in the table
*& control. Nothing is written to ZSAP_TIMESHEET here - the rows are
*& saved, and validated, by the existing SAVE path.
*&
*& Column order of the workbook (fixed - UPLOAD_ROWS reads by POSITION,
*& never by heading, so keep both forms in step):
*&   1 Consultant Name   2 Service Element   3 Module   4 Date
*&   5 Days              6 Activity          7 Scope    8 Stages
*&   9 Location         10 Remarks
*&---------------------------------------------------------------------*
FORM download_rows.

  TYPES: BEGIN OF ty_xl,
           consultant_name TYPE zsap_timesheet-consultant_name,
           service_element TYPE zsap_timesheet-service_element,
           zmodulec        TYPE zsap_timesheet-zmodulec,
           datec           TYPE zsap_timesheet-datec,
           daysc           TYPE zsap_timesheet-daysc,
           activity        TYPE zsap_timesheet-activity,
           scope           TYPE zsap_timesheet-scope,
           stages          TYPE zsap_timesheet-stages,
           location        TYPE zsap_timesheet-location,
           remarks         TYPE zsap_timesheet-remarks,
         END OF ty_xl.

  DATA: lt_xl     TYPE STANDARD TABLE OF ty_xl,
        ls_xl     TYPE ty_xl,
        ls_row    TYPE st_data,
        lo_salv   TYPE REF TO cl_salv_table,
        lo_cols   TYPE REF TO cl_salv_columns_table,
        lx_salv   TYPE REF TO cx_salv_msg,
        lv_xstr   TYPE xstring,
        lt_bin    TYPE solix_tab,
        lv_size   TYPE i,
        lv_name   TYPE string,
        lv_path   TYPE string,
        lv_full   TYPE string,
        lv_action TYPE i,
        lv_count  TYPE i.

* Only rows that carry a consultant - the blank line the table control
* keeps at the bottom is not exported
  LOOP AT lt_data INTO ls_row WHERE consultant_name IS NOT INITIAL.
    CLEAR ls_xl.
    MOVE-CORRESPONDING ls_row TO ls_xl.
    APPEND ls_xl TO lt_xl.
  ENDLOOP.

  IF lt_xl IS INITIAL.
    MESSAGE 'Enter at least one row before downloading' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

* ASSUMPTION: CL_SALV_TABLE->TO_XML (XLSX) exists on the OVL release.
* Check in SE24 before activating if the release is in doubt.
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv
                              CHANGING  t_table      = lt_xl ).
    CATCH cx_salv_msg INTO lx_salv.
      MESSAGE lx_salv->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_cols = lo_salv->get_columns( ).
  PERFORM set_heading USING lo_cols 'CONSULTANT_NAME' 'Consultant Name'.
  PERFORM set_heading USING lo_cols 'SERVICE_ELEMENT' 'Service Element'.
  PERFORM set_heading USING lo_cols 'ZMODULEC'        'Module'.
  PERFORM set_heading USING lo_cols 'DATEC'           'Date'.
  PERFORM set_heading USING lo_cols 'DAYSC'           'Days'.
  PERFORM set_heading USING lo_cols 'ACTIVITY'        'Activity'.
  PERFORM set_heading USING lo_cols 'SCOPE'           'Scope'.
  PERFORM set_heading USING lo_cols 'STAGES'          'Stages'.
  PERFORM set_heading USING lo_cols 'LOCATION'        'Location'.
  PERFORM set_heading USING lo_cols 'REMARKS'         'Remarks'.

  lv_xstr = lo_salv->to_xml( xml_type = if_salv_bs_xml=>c_type_xlsx ).

  IF lv_xstr IS INITIAL.
    MESSAGE 'Excel file could not be built' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  lv_name = |Timesheet_{ sy-datum }.xlsx|.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      window_title      = 'Save Timesheet Rows'
      default_extension = 'xlsx'
      default_file_name = lv_name
      file_filter       = 'Excel Workbook (*.xlsx)|*.xlsx'
    CHANGING
      filename          = lv_name
      path              = lv_path
      fullpath          = lv_full
      user_action       = lv_action
    EXCEPTIONS
      OTHERS            = 1 ).

  IF sy-subrc <> 0.
    MESSAGE 'File save dialog could not be opened' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_action <> cl_gui_frontend_services=>action_ok OR lv_full IS INITIAL.
    MESSAGE 'Download cancelled' TYPE 'S'.
    RETURN.
  ENDIF.

  lt_bin  = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_xstr ).
  lv_size = xstrlen( lv_xstr ).

  cl_gui_frontend_services=>gui_download(
    EXPORTING
      bin_filesize = lv_size
      filename     = lv_full
      filetype     = 'BIN'
    CHANGING
      data_tab     = lt_bin
    EXCEPTIONS
      OTHERS       = 1 ).

  IF sy-subrc <> 0.
    MESSAGE 'File could not be saved - check the path and that it is not open in Excel'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  lv_count = lines( lt_xl ).
  MESSAGE |{ lv_count } row(s) downloaded| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Readable column heading in the downloaded workbook
*&---------------------------------------------------------------------*
FORM set_heading USING po_cols TYPE REF TO cl_salv_columns_table
                       pv_col  TYPE csequence
                       pv_text TYPE csequence.

  DATA: lo_col  TYPE REF TO cl_salv_column,
        lv_col  TYPE lvc_fname,
        lv_s    TYPE scrtext_s,
        lv_m    TYPE scrtext_m,
        lv_l    TYPE scrtext_l.

  lv_col = pv_col.
  lv_s   = pv_text.
  lv_m   = pv_text.
  lv_l   = pv_text.

  TRY.
      lo_col = po_cols->get_column( lv_col ).
      lo_col->set_short_text( lv_s ).
      lo_col->set_medium_text( lv_m ).
      lo_col->set_long_text( lv_l ).
    CATCH cx_salv_not_found.
*     Column names are fixed in DOWNLOAD_ROWS - nothing to tell the user
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Upload: read the workbook back into the table control
*&
*& The whole file is checked first; one bad cell rejects the file with
*& its row number and the table control is left exactly as it was.
*&---------------------------------------------------------------------*
FORM upload_rows.

  DATA: lt_file   TYPE filetable,
        ls_file   TYPE file_table,
        lv_rc     TYPE i,
        lv_action TYPE i,
        lv_name   TYPE string,
        lt_bin    TYPE solix_tab,
        lv_len    TYPE i,
        lv_xstr   TYPE xstring,
        lo_xl     TYPE REF TO cl_fdt_xl_spreadsheet,
        lt_ws     TYPE if_fdt_doc_spreadsheet=>t_worksheet_names,
        lv_ws     TYPE string,
        lr_data   TYPE REF TO data,
        lt_new    TYPE STANDARD TABLE OF st_data,
        ls_new    TYPE st_data,
        lv_row    TYPE i,
        lv_ix     TYPE i,
        lv_val    TYPE string,
        lv_ok     TYPE abap_bool,
        lv_count  TYPE i.

  FIELD-SYMBOLS: <lt_tab>  TYPE STANDARD TABLE,
                 <ls_line> TYPE any,
                 <lv_cell> TYPE any.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title   = 'Select Timesheet File'
      file_filter    = 'Excel Workbook (*.xlsx)|*.xlsx'
      multiselection = abap_false
    CHANGING
      file_table     = lt_file
      rc             = lv_rc
      user_action    = lv_action
    EXCEPTIONS
      OTHERS         = 1 ).

  IF sy-subrc <> 0.
    MESSAGE 'File open dialog could not be opened' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_action <> cl_gui_frontend_services=>action_ok.
    MESSAGE 'Upload cancelled' TYPE 'S'.
    RETURN.
  ENDIF.

  READ TABLE lt_file INTO ls_file INDEX 1.
  IF sy-subrc <> 0.
    MESSAGE 'Upload cancelled' TYPE 'S'.
    RETURN.
  ENDIF.
  lv_name = ls_file-filename.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename   = lv_name
      filetype   = 'BIN'
    IMPORTING
      filelength = lv_len
    CHANGING
      data_tab   = lt_bin
    EXCEPTIONS
      OTHERS     = 1 ).

  IF sy-subrc <> 0 OR lv_len = 0.
    MESSAGE 'File could not be read - close it in Excel and try again' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  lv_xstr = cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin
                                              iv_size  = lv_len ).

* ASSUMPTION: CL_FDT_XL_SPREADSHEET exists on the OVL release (it is
* proven on the KPMG landscape). A file that is not a real .xlsx - an
* old .xls, or a renamed CSV - fails here and gets a message.
  TRY.
      CREATE OBJECT lo_xl
        EXPORTING
          document_name = lv_name
          xdocument     = lv_xstr.

      lo_xl->if_fdt_doc_spreadsheet~get_worksheet_names(
        IMPORTING worksheet_names = lt_ws ).

      READ TABLE lt_ws INTO lv_ws INDEX 1.
      IF sy-subrc = 0.
        lr_data = lo_xl->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_ws ).
      ENDIF.

    CATCH cx_root.
      CLEAR lr_data.
  ENDTRY.

  IF lr_data IS NOT BOUND.
    MESSAGE 'File is not a readable Excel workbook (.xlsx)' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  ASSIGN lr_data->* TO <lt_tab>.
  IF <lt_tab> IS NOT ASSIGNED.
    MESSAGE 'File is not a readable Excel workbook (.xlsx)' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT <lt_tab> ASSIGNING <ls_line>.

*   Row number as the user sees it in Excel. The heading row may or may
*   not arrive in the table depending on the release, so it is skipped
*   by its text rather than by position.
    lv_row = sy-tabix.
    CLEAR ls_new.

    DO 10 TIMES.

      lv_ix = sy-index.
      UNASSIGN <lv_cell>.
      ASSIGN COMPONENT lv_ix OF STRUCTURE <ls_line> TO <lv_cell>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_val = <lv_cell>.
      CONDENSE lv_val.

      CASE lv_ix.
        WHEN 1.
          ls_new-consultant_name = lv_val.
        WHEN 2.
          ls_new-service_element = lv_val.
        WHEN 3.
          ls_new-zmodulec        = lv_val.
        WHEN 4.
          PERFORM xl_to_date USING lv_val CHANGING ls_new-datec lv_ok.
          IF lv_ok = abap_false.
            MESSAGE |Row { lv_row }: Date "{ lv_val }" is not a valid date. File not uploaded.|
              TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.
        WHEN 5.
          PERFORM xl_to_days USING lv_val CHANGING ls_new-daysc lv_ok.
          IF lv_ok = abap_false.
            MESSAGE |Row { lv_row }: Days "{ lv_val }" is not a number. File not uploaded.|
              TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.
        WHEN 6.
          ls_new-activity        = lv_val.
        WHEN 7.
          ls_new-scope           = lv_val.
        WHEN 8.
          ls_new-stages          = lv_val.
        WHEN 9.
          ls_new-location        = lv_val.
        WHEN 10.
          ls_new-remarks         = lv_val.
      ENDCASE.

    ENDDO.

*   Heading row
    IF to_upper( ls_new-consultant_name ) = 'CONSULTANT NAME'.
      CONTINUE.
    ENDIF.

*   Fully blank rows at the end of a sheet are ignored
    IF ls_new IS INITIAL.
      CONTINUE.
    ENDIF.

    IF ls_new-consultant_name IS INITIAL.
      MESSAGE |Row { lv_row }: Consultant Name is blank. File not uploaded.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*   ASSUMPTION: ZCONSULTANT_ID is the logged-on user, as the SAVE path
*   writes it (wa_final-zconsultant_id = sy-uname). It is not a column in
*   the workbook.
    ls_new-zconsultant_id = sy-uname.

    APPEND ls_new TO lt_new.

  ENDLOOP.

  IF lt_new IS INITIAL.
    MESSAGE 'No rows found in the file' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

* Replace what is on the screen with the file
  lt_data = lt_new.
  CLEAR ls_data.
  timesheet-top_line = 1.

  lv_count = lines( lt_new ).
  MESSAGE |{ lv_count } row(s) uploaded - check and press Save| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& A date cell from the workbook
*&
*& A cell formatted as a date arrives as the Excel serial number
*& (days since 30.12.1899); a cell typed as text arrives as typed.
*& Accepted: serial number, DD.MM.YYYY / DD/MM/YYYY / DD-MM-YYYY,
*& YYYY-MM-DD and YYYYMMDD. Blank is passed through - SAVE reports it.
*&---------------------------------------------------------------------*
FORM xl_to_date USING    pv_val  TYPE string
                CHANGING cv_date TYPE simple
                         cv_ok   TYPE abap_bool.

  DATA: lv_val   TYPE string,
        lv_int   TYPE string,
        lv_frac  TYPE string,
        lv_days  TYPE i,
        lv_date  TYPE d,
        lv_p1    TYPE string,
        lv_p2    TYPE string,
        lv_p3    TYPE string,
        lv_dd    TYPE n LENGTH 2,
        lv_mm    TYPE n LENGTH 2,
        lv_yyyy  TYPE n LENGTH 4.

  cv_ok = abap_false.
  CLEAR: cv_date, lv_date.

  lv_val = pv_val.
  CONDENSE lv_val NO-GAPS.

  IF lv_val IS INITIAL.
    cv_ok = abap_true.
    RETURN.
  ENDIF.

  SPLIT lv_val AT '.' INTO lv_int lv_frac.

  IF lv_val CO '0123456789' AND strlen( lv_val ) = 8.
*   YYYYMMDD
    lv_date = lv_val.

  ELSEIF lv_int CO '0123456789' AND strlen( lv_int ) <= 6
     AND ( lv_frac IS INITIAL OR lv_frac CO '0123456789' ).
*   Excel serial number; a time part after the decimal point is dropped
    lv_days = lv_int.
    IF lv_days <= 0.
      RETURN.
    ENDIF.
    lv_date = '18991230'.
    lv_date = lv_date + lv_days.

  ELSE.
    TRANSLATE lv_val USING '/.-.'.
    SPLIT lv_val AT '.' INTO lv_p1 lv_p2 lv_p3.
    IF lv_p1 IS INITIAL OR lv_p2 IS INITIAL OR lv_p3 IS INITIAL
       OR lv_p1 CN '0123456789' OR lv_p2 CN '0123456789' OR lv_p3 CN '0123456789'.
      RETURN.
    ENDIF.

    IF strlen( lv_p1 ) = 4.
*     YYYY-MM-DD
      lv_yyyy = lv_p1.
      lv_mm   = lv_p2.
      lv_dd   = lv_p3.
    ELSE.
*     DD.MM.YYYY - a two-digit year is taken as 20YY
      IF strlen( lv_p3 ) = 2.
        lv_p3 = |20{ lv_p3 }|.
      ENDIF.
      IF strlen( lv_p3 ) <> 4.
        RETURN.
      ENDIF.
      lv_dd   = lv_p1.
      lv_mm   = lv_p2.
      lv_yyyy = lv_p3.
    ENDIF.

    lv_date = |{ lv_yyyy }{ lv_mm }{ lv_dd }|.
  ENDIF.

  CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
    EXPORTING
      date                      = lv_date
    EXCEPTIONS
      plausibility_check_failed = 1
      OTHERS                    = 2.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

* ASSUMPTION: ZSAP_TIMESHEET-DATEC is a DATS field (it is compared with
* sy-datum in USER_COMMAND_9002).
  cv_date = lv_date.
  cv_ok   = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& A days cell from the workbook - 1, 0.5, 0,5 ... Blank passes through.
*&---------------------------------------------------------------------*
FORM xl_to_days USING    pv_val  TYPE string
                CHANGING cv_days TYPE simple
                         cv_ok   TYPE abap_bool.

  DATA lv_val TYPE string.

  cv_ok = abap_false.
  CLEAR cv_days.

  lv_val = pv_val.
  CONDENSE lv_val NO-GAPS.

  IF lv_val IS INITIAL.
    cv_ok = abap_true.
    RETURN.
  ENDIF.

  TRANSLATE lv_val USING ',.'.

  IF lv_val CN '0123456789.'.
    RETURN.
  ENDIF.

  TRY.
      cv_days = lv_val.
    CATCH cx_sy_conversion_error.
      RETURN.
  ENDTRY.

  cv_ok = abap_true.

ENDFORM.
*EOC By SAP_ABAP on 05/10/26
