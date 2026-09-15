*&---------------------------------------------------------------------*
*& Report  ZPP_FORECAST_UPLOAD   Transaction  ZFCST_UPL
*& ZFORECAST (Adhesive) - all uploads in one program
*&
*& Eight upload types selected by radio button. Each radio button has a
*& Download Template button of its own beside it, so the file the user
*& fills in always carries the right columns in the right order.
*&
*& The file is read back as a real Excel workbook (.XLSX / .XLS) through
*& CL_FDT_XL_SPREADSHEET, or as CSV or tab separated text. The user no
*& longer has to save their spreadsheet as a text file first.
*&
*& Built to Forecast Template-Adhesive.xlsx dated 20.08.2026
*&---------------------------------------------------------------------*
REPORT zpp_forecast_upload MESSAGE-ID zpp_fcst.

TABLES sscrfields.

TYPES: BEGIN OF ty_raw,
         f01 TYPE char40, f02 TYPE char40, f03 TYPE char40, f04 TYPE char40,
         f05 TYPE char40, f06 TYPE char40, f07 TYPE char40, f08 TYPE char40,
         f09 TYPE char40, f10 TYPE char40, f11 TYPE char40, f12 TYPE char40,
         f13 TYPE char40, f14 TYPE char40, f15 TYPE char40, f16 TYPE char40,
       END OF ty_raw,

       BEGIN OF ty_log,
         row     TYPE i,
         werks   TYPE werks_d,
         matnr   TYPE matnr,
         period  TYPE char12,
         action  TYPE char14,
         light   TYPE char1,
         message TYPE char200,
       END OF ty_log.

CONSTANTS: gc_new  TYPE char14 VALUE 'Created',
           gc_chg  TYPE char14 VALUE 'Changed',
           gc_err  TYPE char14 VALUE 'Rejected',
           gc_tnew TYPE char14 VALUE 'Would create',
           gc_tchg TYPE char14 VALUE 'Would change'.

*BOC By Arnav on 03/09/26
* MONTH on the quarterly change file has two possible readings and the
* business has not settled it. Switch here, one letter:
*
*   'S' - 1, 2 or 3: the first, second or third month OF THE QUARTER.
*         Quarter 2 month 1 is July. This is what is live.
*   'P' - the fiscal period 1 to 12, 1 = April, checked against the
*         quarter on the same row. Quarter 2 takes 4 to 6.
*
* They agree only for quarter 1, where both give April, May, June.
* Whichever applies, LV_SLOT ends up 1, 2 or 3 and everything after it
* works off that alone.
*
* A DATA and not a CONSTANTS on purpose - a constant lets the compiler
* fold the IF and report the other branch as unreachable.
DATA gv_qmonth TYPE char1 VALUE 'S'.

* Used by DO_CHANGE to reach BUS_FCST_ADDn and Mn_FCST_FINAL by name
FIELD-SYMBOLS: <gv_add> TYPE any,
               <gv_fin> TYPE any,
               <gv_a>   TYPE any,
               <gv_b>   TYPE any.
*EOC By Arnav on 03/09/26

DATA: gt_raw TYPE STANDARD TABLE OF ty_raw,
      gt_log TYPE STANDARD TABLE OF ty_log,
      g_new  TYPE i,
      g_chg  TYPE i,
      g_err  TYPE i,
      g_tab  TYPE c LENGTH 1,
*BOC By Arnav on 31/08/26
*     The upload type as a key rather than eight radio buttons, so the
*     template layout can be asked for by name
      g_type TYPE char4,
*     Set when the file was read as a workbook. CL_FDT_XL_SPREADSHEET
*     consumes the heading row itself, so the header checkbox must not
*     delete a second row.
      g_xls  TYPE abap_bool.
*EOC By Arnav on 31/08/26

*&---------------------------------------------------------------------*
SELECTION-SCREEN FUNCTION KEY 1.

*BOC By Arnav on 31/08/26
* One Download Template button per upload type, on the line of the radio
* button it belongs to. The single button in the application toolbar
* served whichever radio button happened to be selected, so a user who
* wanted the legacy history layout had to select that radio button
* first; the eight buttons below each download their own layout whatever
* is selected.
*
* The radio button texts move from the selection texts into COMMENT
* fields, because a parameter inside BEGIN OF LINE does not draw its
* selection text. They are filled in INITIALIZATION.
*
*PARAMETERS: p_cat  RADIOBUTTON GROUP typ DEFAULT 'X',
*            p_trk  RADIOBUTTON GROUP typ,
*            p_exc  RADIOBUTTON GROUP typ,
*            p_hist RADIOBUTTON GROUP typ,
*            p_busq RADIOBUTTON GROUP typ,
*            p_busm RADIOBUTTON GROUP typ,
*            p_chgq RADIOBUTTON GROUP typ,
*            p_chgm RADIOBUTTON GROUP typ.
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-b00.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_cat RADIOBUTTON GROUP typ DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(33) c_cat FOR FIELD p_cat.
SELECTION-SCREEN PUSHBUTTON 40(24) b_cat USER-COMMAND tcat.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_trk RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_trk FOR FIELD p_trk.
SELECTION-SCREEN PUSHBUTTON 40(24) b_trk USER-COMMAND ttrk.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_exc RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_exc FOR FIELD p_exc.
SELECTION-SCREEN PUSHBUTTON 40(24) b_exc USER-COMMAND texc.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_hist RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_hist FOR FIELD p_hist.
SELECTION-SCREEN PUSHBUTTON 40(24) b_hist USER-COMMAND thst.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_busq RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_busq FOR FIELD p_busq.
SELECTION-SCREEN PUSHBUTTON 40(24) b_busq USER-COMMAND tbsq.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_busm RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_busm FOR FIELD p_busm.
SELECTION-SCREEN PUSHBUTTON 40(24) b_busm USER-COMMAND tbsm.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_chgq RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_chgq FOR FIELD p_chgq.
SELECTION-SCREEN PUSHBUTTON 40(24) b_chgq USER-COMMAND tcgq.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_chgm RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_chgm FOR FIELD p_chgm.
SELECTION-SCREEN PUSHBUTTON 40(24) b_chgm USER-COMMAND tcgm.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b0.
*EOC By Arnav on 31/08/26

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_file TYPE localfile,
            p_head AS CHECKBOX DEFAULT 'X',
            p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.


*&---------------------------------------------------------------------*
INITIALIZATION.

* The file name is deliberately not OBLIGATORY. A mandatory field is
* checked before AT SELECTION-SCREEN runs, which would stop the user
* pressing Download Template before they have a file to name.
  sscrfields-functxt_01 = 'Download Template'.
  g_tab = cl_abap_char_utilities=>horizontal_tab.

*BOC By Arnav on 31/08/26
* Radio button texts, which a parameter inside BEGIN OF LINE cannot draw
* from the selection texts
  c_cat  = 'Product Category'.
  c_trk  = 'Material Tracking'.
  c_exc  = 'Material Exclusion'.
  c_hist = 'Legacy Sales History'.
  c_busq = 'Business Forecast Quarterly'.
  c_busm = 'Business Forecast Monthly'.
  c_chgq = 'Forecast Change Quarterly'.
  c_chgm = 'Forecast Change Monthly'.

  b_cat  = 'Download Template'.
  b_trk  = 'Download Template'.
  b_exc  = 'Download Template'.
  b_hist = 'Download Template'.
  b_busq = 'Download Template'.
  b_busm = 'Download Template'.
  b_chgq = 'Download Template'.
  b_chgm = 'Download Template'.
*EOC By Arnav on 31/08/26

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  PERFORM f4_file.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.

*BOC By Arnav on 31/08/26
*  IF sscrfields-ucomm = 'FC01'.
*    PERFORM download_template.
*  ELSEIF sscrfields-ucomm = 'ONLI' AND p_file IS INITIAL.
*    MESSAGE e013 WITH 'no file name entered'.
*  ENDIF.
  CASE sscrfields-ucomm.

*   The application toolbar button still serves whichever radio button
*   is selected. The eight buttons name their own type.
    WHEN 'FC01'.
      PERFORM current_type CHANGING g_type.
      PERFORM download_template USING g_type.
    WHEN 'TCAT'. PERFORM download_template USING 'CAT'.
    WHEN 'TTRK'. PERFORM download_template USING 'TRK'.
    WHEN 'TEXC'. PERFORM download_template USING 'EXC'.
    WHEN 'THST'. PERFORM download_template USING 'HIST'.
    WHEN 'TBSQ'. PERFORM download_template USING 'BUSQ'.
    WHEN 'TBSM'. PERFORM download_template USING 'BUSM'.
    WHEN 'TCGQ'. PERFORM download_template USING 'CHGQ'.
    WHEN 'TCGM'. PERFORM download_template USING 'CHGM'.

    WHEN 'ONLI'.
      IF p_file IS INITIAL.
        MESSAGE e013 WITH 'no file name entered'.
      ENDIF.

  ENDCASE.
*EOC By Arnav on 31/08/26

*&---------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR: gt_raw, gt_log, g_new, g_chg, g_err.

  PERFORM upload_file.

  IF gt_raw IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  CASE 'X'.
    WHEN p_cat.  PERFORM do_category.
    WHEN p_trk.  PERFORM do_tracking.
    WHEN p_exc.  PERFORM do_exclusion.
    WHEN p_hist. PERFORM do_history.
    WHEN p_busq. PERFORM do_business USING 'Q'.
    WHEN p_busm. PERFORM do_business USING 'M'.
    WHEN p_chgq. PERFORM do_change   USING 'Q'.
    WHEN p_chgm. PERFORM do_change   USING 'M'.
  ENDCASE.

* Nothing is committed on a test run. On a real run the good rows are
* committed even when other rows failed, so a partly correct file loads
* what it can and the log says exactly what it did not.
  IF p_test = abap_false AND ( g_new > 0 OR g_chg > 0 ).
    COMMIT WORK AND WAIT.
  ELSE.
    ROLLBACK WORK.
  ENDIF.

  PERFORM display_log.


*&---------------------------------------------------------------------*
*& Template definition - one place, used by the download button and
*& matching the layouts documented for the functional team
*&---------------------------------------------------------------------*
FORM current_type CHANGING cv_type TYPE char4.

  CLEAR cv_type.

  CASE 'X'.
    WHEN p_cat.  cv_type = 'CAT'.
    WHEN p_trk.  cv_type = 'TRK'.
    WHEN p_exc.  cv_type = 'EXC'.
    WHEN p_hist. cv_type = 'HIST'.
    WHEN p_busq. cv_type = 'BUSQ'.
    WHEN p_busm. cv_type = 'BUSM'.
    WHEN p_chgq. cv_type = 'CHGQ'.
    WHEN p_chgm. cv_type = 'CHGM'.
  ENDCASE.

ENDFORM.


*&---------------------------------------------------------------------*
*& BOC By Arnav on 31/08/26
*&
*& Template layout - taken from the dictionary, not typed in here
*&
*& The layout used to be written into this program: the column headings
*& as literals, and a second row of sample data carrying plant 1001,
*& material FG00000000001 and year 2026. Two things were wrong with it.
*&
*&   1  It is hardcoded master data. That plant, that material and that
*&      year belong to no real system, they go stale on their own, and
*&      the standard for this repository is that nothing is hardcoded
*&      unless the functional spec says to hardcode it.
*&   2  A heading typed here drifts away from the field it loads. The
*&      heading IS the DDIC label of that field now, so a label changed
*&      in SE11 changes the template with it and the two cannot
*&      disagree.
*&
*& The sample row goes with it. Saying what a column means is the
*& heading's job; saying what a valid value is belongs to the validation
*& messages, which already name every rule.
*&
*& The old body, for reference - it is also what the syntax check was
*& rejecting, "'PLANT' and the row type of CT_HEAD are incompatible",
*& sixteen times, two per upload type:
*&
*&   ct_head = VALUE #( ( 'PLANT' ) ( 'MATERIAL' ) ( 'CATEGORY' )
*&                      ( 'LOAD FACTOR' ) ( 'MTS OR MTO' ) ).
*&   ct_demo = VALUE #( ( '1001' ) ( 'FG00000000001' ) ( 'A' )
*&                      ( '1.300' ) ( 'MTS' ) ).
*&
*& The rows of a VALUE table constructor have to be COMPATIBLE with the
*& row type on this release, not merely convertible. 'PLANT' is a C
*& literal and the row type of STRING_TABLE is STRING, so every one of
*& them was refused. APPEND converts and is used throughout instead -
*& the same statement ZPP_FORECAST already builds its column list with.
*&---------------------------------------------------------------------*
FORM template_columns USING pv_type TYPE any
                      CHANGING ct_head TYPE string_table
                               cv_name TYPE string.

  DATA: lt_pre  TYPE string_table,
        lt_post TYPE string_table,
        lv_key  TYPE string,
        lv_txt  TYPE string,
        lv_per  TYPE char12,
        lv_i    TYPE i,
        lv_mth  TYPE abap_bool.

  CLEAR: ct_head, cv_name.

* Each entry is the table and field the column loads. The order is the
* order of the columns in the file, and it is the ONLY thing about the
* layout this program still decides for itself.
  CASE pv_type.

    WHEN 'CAT'.
      cv_name = 'ZFCST_Product_Category'.
      APPEND 'ZPPT_PROD_CAT-WERKS'    TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-MATNR'    TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-PROD_CAT' TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-LOAD_FCT' TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-MTS_MTO'  TO lt_pre.

    WHEN 'TRK'.
      cv_name = 'ZFCST_Material_Tracking'.
      APPEND 'ZPPT_MAT_TRACK-WERKS'      TO lt_pre.
      APPEND 'ZPPT_MAT_TRACK-NEW_MATNR'  TO lt_pre.
      APPEND 'ZPPT_MAT_TRACK-OLD_MATNR1' TO lt_pre.
      APPEND 'ZPPT_MAT_TRACK-OLD_MATNR2' TO lt_pre.
*BOC By Arnav on 03/09/26
      APPEND 'ZPPT_MAT_TRACK-OLD_MATNR3' TO lt_pre.
      APPEND 'ZPPT_MAT_TRACK-OLD_MATNR4' TO lt_pre.
      APPEND 'ZPPT_MAT_TRACK-OLD_MATNR5' TO lt_pre.
*EOC By Arnav on 03/09/26

    WHEN 'EXC'.
      cv_name = 'ZFCST_Material_Exclusion'.
      APPEND 'ZPPT_MAT_EXCL-WERKS' TO lt_pre.
      APPEND 'ZPPT_MAT_EXCL-MATNR' TO lt_pre.

    WHEN 'HIST'.
      cv_name = 'ZFCST_Legacy_Sales_History'.
      APPEND 'ZPPT_SLS_HIST-WERKS' TO lt_pre.
      APPEND 'ZPPT_SLS_HIST-MATNR' TO lt_pre.
      APPEND 'ZPPT_SLS_HIST-GJAHR' TO lt_pre.
      lv_mth = abap_true.
      APPEND 'ZPPT_SLS_HIST-MEINS' TO lt_post.

    WHEN 'BUSQ'.
      cv_name = 'ZFCST_Business_Forecast_Quarterly'.
      APPEND 'ZPPT_FCST_QT-MATNR'    TO lt_pre.
      APPEND 'ZPPT_FCST_QT-WERKS'    TO lt_pre.
      APPEND 'ZPPT_FCST_QT-QUARTER'  TO lt_pre.
      APPEND 'ZPPT_FCST_QT-GJAHR'    TO lt_pre.
      APPEND 'ZPPT_FCST_QT-BUS_FCST' TO lt_pre.

    WHEN 'BUSM'.
      cv_name = 'ZFCST_Business_Forecast_Monthly'.
      APPEND 'ZPPT_FCST_MN-MATNR'    TO lt_pre.
      APPEND 'ZPPT_FCST_MN-WERKS'    TO lt_pre.
      APPEND 'ZPPT_FCST_MN-PERIOD'   TO lt_pre.
      APPEND 'ZPPT_FCST_MN-GJAHR'    TO lt_pre.
      APPEND 'ZPPT_FCST_MN-BUS_FCST' TO lt_pre.

    WHEN 'CHGQ'.
      cv_name = 'ZFCST_Forecast_Change_Quarterly'.
*BOC By Arnav on 03/09/26
*     MONTH is new, between QUARTER and YEAR, and everything after it
*     has moved one place right. MONTH is the only column with no table
*     field behind it, so it is the only plain heading here - the
*     quantity keeps its dictionary label, "Forecast Quantity", exactly
*     as before, by pointing at BUS_FCST_ADD1. The value is routed to
*     ADD1, ADD2 or ADD3 by the month at upload time.
*     APPEND 'ZPPT_FCST_QT-BUS_FCST_ADD' TO lt_pre.
      APPEND 'ZPPT_FCST_QT-MATNR'        TO lt_pre.
      APPEND 'ZPPT_FCST_QT-WERKS'        TO lt_pre.
      APPEND 'ZPPT_FCST_QT-QUARTER'      TO lt_pre.
      APPEND 'MONTH'                     TO lt_pre.
      APPEND 'ZPPT_FCST_QT-GJAHR'        TO lt_pre.
      APPEND 'ZPPT_FCST_QT-BUS_FCST_ADD1'  TO lt_pre.
      APPEND 'ZPPT_FCST_QT-REASON'       TO lt_pre.
*EOC By Arnav on 03/09/26

    WHEN 'CHGM'.
      cv_name = 'ZFCST_Forecast_Change_Monthly'.
      APPEND 'ZPPT_FCST_MN-MATNR'        TO lt_pre.
      APPEND 'ZPPT_FCST_MN-WERKS'        TO lt_pre.
      APPEND 'ZPPT_FCST_MN-PERIOD'       TO lt_pre.
      APPEND 'ZPPT_FCST_MN-GJAHR'        TO lt_pre.
      APPEND 'ZPPT_FCST_MN-BUS_FCST_ADD' TO lt_pre.
      APPEND 'ZPPT_FCST_MN-REASON'       TO lt_pre.

    WHEN OTHERS.
      RETURN.

  ENDCASE.

  LOOP AT lt_pre INTO lv_key.
    PERFORM field_label USING lv_key CHANGING lv_txt.
    APPEND lv_txt TO ct_head.
  ENDLOOP.

* The twelve legacy columns are all ZDE_FCST_QTY, so the dictionary
* label is the same twelve times over and would not tell the user which
* month is which. They are named from the financial calendar instead -
* period 1 is April - by the same routine that labels the result list,
* so the template and the log say the same thing.
  IF lv_mth = abap_true.
    DO 12 TIMES.
      lv_i = sy-index.
      PERFORM period_text USING 'M' lv_i CHANGING lv_per.
      lv_txt = lv_per.
      CONDENSE lv_txt.
      APPEND lv_txt TO ct_head.
    ENDDO.
  ENDIF.

  LOOP AT lt_post INTO lv_key.
    PERFORM field_label USING lv_key CHANGING lv_txt.
    APPEND lv_txt TO ct_head.
  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& The dictionary label of TABLE-FIELD
*&
*& Long text first, then medium, then the field text, so the heading is
*& as readable as the dictionary allows. A field with no label at all
*& still gets its own name rather than an empty column.
*&---------------------------------------------------------------------*
FORM field_label USING pv_key TYPE string
                 CHANGING cv_txt TYPE string.

  DATA: lt_part TYPE string_table,
        lv_s    TYPE string,
        lv_tab  TYPE ddobjname,
        lv_fld  TYPE dfies-fieldname,
        lt_dfie TYPE STANDARD TABLE OF dfies,
        ls_dfie TYPE dfies.

  CLEAR cv_txt.

  SPLIT pv_key AT '-' INTO TABLE lt_part.

  READ TABLE lt_part INTO lv_s INDEX 1.
  CHECK sy-subrc = 0.
  lv_tab = lv_s.

*BOC By Arnav on 03/09/26
* A key with no dash is not a dictionary field - it is a column the file
* carries that no table has, such as MONTH on the quarterly change
* sheet. It is used as the heading exactly as given.
  READ TABLE lt_part TRANSPORTING NO FIELDS INDEX 2.
  IF sy-subrc <> 0.
    cv_txt = pv_key.
    RETURN.
  ENDIF.
*EOC By Arnav on 03/09/26

  READ TABLE lt_part INTO lv_s INDEX 2.
  CHECK sy-subrc = 0.
  lv_fld = lv_s.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING  tabname        = lv_tab
               fieldname      = lv_fld
               langu          = sy-langu
    TABLES     dfies_tab      = lt_dfie
    EXCEPTIONS not_found      = 1
               internal_error = 2
               OTHERS         = 3.

  IF sy-subrc = 0.
    READ TABLE lt_dfie INTO ls_dfie INDEX 1.
    IF sy-subrc = 0.
      IF ls_dfie-scrtext_l IS NOT INITIAL.
        cv_txt = ls_dfie-scrtext_l.
      ELSEIF ls_dfie-scrtext_m IS NOT INITIAL.
        cv_txt = ls_dfie-scrtext_m.
      ELSE.
        cv_txt = ls_dfie-fieldtext.
      ENDIF.
    ENDIF.
  ENDIF.

  IF cv_txt IS INITIAL.
    cv_txt = lv_fld.
  ENDIF.

  CONDENSE cv_txt.

ENDFORM.
*& EOC By Arnav on 31/08/26


*&---------------------------------------------------------------------*
* PV_TYPE is TYPE ANY, not TYPE CHAR4: the eight buttons pass a literal
* such as 'CAT', which is C(3) and would not be type compatible with a
* C(4) formal parameter.
FORM download_template USING pv_type TYPE any.

  DATA: lt_head TYPE string_table,
        lt_out  TYPE string_table,
        lv_name TYPE string,
        lv_line TYPE string,
        lv_path TYPE string,
        lv_full TYPE string,
        lv_file TYPE string,
        lv_msg  TYPE string.

  PERFORM template_columns USING pv_type
                           CHANGING lt_head lv_name.

  CHECK lt_head IS NOT INITIAL.

*BOC By Arnav on 31/08/26
* One row, the column headings. The sample row that used to follow it
* carried invented master data - see the note on TEMPLATE_COLUMNS.
*  PERFORM join_row USING lt_demo CHANGING lv_line.
*  APPEND lv_line TO lt_out.
  PERFORM join_row USING lt_head CHANGING lv_line.
  APPEND lv_line TO lt_out.
*EOC By Arnav on 31/08/26

*BOC By Arnav on 31/08/26
* The template was written as .txt, which Excel opens through the text
* import wizard - and a user who clicked past it got the columns in one
* cell and uploaded a file the program could not read. A .csv opens
* straight into columns, and the upload now reads the workbook back
* whether it is saved as .csv or as .xlsx.
*  CONCATENATE lv_name '.txt' INTO lv_file.
  CONCATENATE lv_name '.csv' INTO lv_file.
*EOC By Arnav on 31/08/26

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING  default_file_name = lv_file
               default_extension = 'csv'   "Changes by Arnav on 31/08/26
    CHANGING   filename          = lv_file
               path              = lv_path
               fullpath          = lv_full
    EXCEPTIONS OTHERS            = 1 ).

  IF sy-subrc <> 0 OR lv_full IS INITIAL.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>gui_download(
    EXPORTING  filename         = lv_full
               filetype         = 'ASC'
    CHANGING   data_tab         = lt_out
    EXCEPTIONS file_write_error = 1
               OTHERS           = 2 ).

  IF sy-subrc = 0.
*BOC By Arnav on 31/08/26
*   The headings are the dictionary labels of the fields the columns
*   load, so the user is told to keep them where they are.
    CONCATENATE 'Template saved to' lv_full
                '- keep row 1 and the column order as they are'
           INTO lv_msg SEPARATED BY space.
*EOC By Arnav on 31/08/26
    MESSAGE lv_msg TYPE 'S'.
  ELSE.
    MESSAGE e013 WITH lv_full.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*BOC By Arnav on 31/08/26
*& The template is comma separated now rather than tab separated, so a
*& value that itself contains a comma or a quote is wrapped in quotes
*& and its own quotes are doubled - the CSV convention the upload reads
*& back. Nothing in the shipped layouts needs it today; a reason text
*& added to a template later would.
*&---------------------------------------------------------------------*
FORM join_row USING pt_val TYPE string_table
              CHANGING cv_line TYPE string.

  DATA: lv_val TYPE string,
        lv_out TYPE string,
        lv_ix  TYPE i.

  CLEAR cv_line.

  LOOP AT pt_val INTO lv_val.

*   SY-TABIX is read straight away rather than after the statements
*   below, so nothing in between can have moved it
    lv_ix  = sy-tabix.
    lv_out = lv_val.

    IF lv_out CS ',' OR lv_out CS '"' OR lv_out CS g_tab.
      REPLACE ALL OCCURRENCES OF '"' IN lv_out WITH '""'.
      CONCATENATE '"' lv_out '"' INTO lv_out.
    ENDIF.

    IF lv_ix = 1.
      cv_line = lv_out.
    ELSE.
      CONCATENATE cv_line ',' lv_out INTO cv_line.
    ENDIF.

  ENDLOOP.

ENDFORM.
*& EOC By Arnav on 31/08/26


*&---------------------------------------------------------------------*
FORM f4_file.

  DATA: lt_files TYPE filetable,
        ls_file  TYPE file_table,
        lv_rc    TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    CHANGING   file_table = lt_files
               rc         = lv_rc
    EXCEPTIONS OTHERS     = 1 ).

  IF sy-subrc = 0 AND lv_rc > 0.
    READ TABLE lt_files INTO ls_file INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_file-filename.
    ENDIF.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& BOC By Arnav on 31/08/26
*&
*& Reading the file the user actually has
*&
*& GUI_UPLOAD with FILETYPE 'ASC' and HAS_FIELD_SEPARATOR reads tab
*& separated TEXT. Handed a real .XLSX it reads the zip container as
*& text, so every row came back as rubbish or as nothing at all - which
*& is what the users were reporting. The workbook is now read as a
*& workbook; CSV and tab separated text still work exactly as before:
*&
*&   .XLSX .XLSM .XLS   binary, CL_FDT_XL_SPREADSHEET, first worksheet
*&   .CSV               comma separated, quoted values understood
*&   anything else      tab separated, comma as a fallback
*&
*& The old body, for reference:
*&
*&   cl_gui_frontend_services=>gui_upload(
*&     EXPORTING  filename            = lv_name
*&                filetype            = 'ASC'
*&                has_field_separator = 'X'
*&     CHANGING   data_tab            = gt_raw ... ).
*&   IF p_head = 'X'.
*&     DELETE gt_raw INDEX 1.
*&   ENDIF.
*&---------------------------------------------------------------------*
FORM upload_file.

  DATA: lv_name TYPE string,
        lv_ext  TYPE string.

  CLEAR: gt_raw, g_xls.

  lv_name = p_file.
  PERFORM file_extension USING lv_name CHANGING lv_ext.

  IF lv_ext = 'XLSX' OR lv_ext = 'XLSM' OR lv_ext = 'XLS'.
    PERFORM upload_excel USING lv_name.
  ELSE.
    PERFORM upload_text  USING lv_name lv_ext.
  ENDIF.

  PERFORM drop_header.

* Trailing blank lines at the end of a spreadsheet export are ignored
* rather than reported as errors
  DELETE gt_raw WHERE f01 IS INITIAL AND f02 IS INITIAL AND f03 IS INITIAL.

ENDFORM.


*&---------------------------------------------------------------------*
FORM file_extension USING pv_name TYPE string
                    CHANGING cv_ext TYPE string.

  DATA: lt_part TYPE string_table,
        lv_last TYPE i.

  CLEAR cv_ext.
  CHECK pv_name CS '.'.

* The LAST dot, so a path such as C:\My.Files\history.xlsx is read
* correctly
  SPLIT pv_name AT '.' INTO TABLE lt_part.
  lv_last = lines( lt_part ).
  CHECK lv_last > 1.

  READ TABLE lt_part INTO cv_ext INDEX lv_last.
  CHECK sy-subrc = 0.

  CONDENSE cv_ext.
  cv_ext = to_upper( cv_ext ).

ENDFORM.


*&---------------------------------------------------------------------*
*& A real Excel workbook
*&
*& The sheet is read by COLUMN POSITION, never by column name.
*& CL_FDT_XL_SPREADSHEET builds the component names from the heading row
*& of the sheet, which the user can and does retype; the template fixes
*& the ORDER of the columns, and that is what is relied on.
*&---------------------------------------------------------------------*
FORM upload_excel USING pv_name TYPE string.

  DATA: lt_bin  TYPE solix_tab,
        lv_len  TYPE i,
        lv_xstr TYPE xstring,
        lt_ws   TYPE if_fdt_doc_spreadsheet=>t_worksheet_names,
        lv_ws   TYPE string,
        lo_xl   TYPE REF TO cl_fdt_xl_spreadsheet,
        lr_data TYPE REF TO data,
        ls_raw  TYPE ty_raw,
        lv_ix   TYPE i,
        lv_val  TYPE string.

  FIELD-SYMBOLS: <lt_tab> TYPE STANDARD TABLE,
                 <ls_row> TYPE any,
                 <lv_in>  TYPE any,
                 <lv_out> TYPE any.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING  filename        = pv_name
               filetype        = 'BIN'
    IMPORTING  filelength      = lv_len
    CHANGING   data_tab        = lt_bin
    EXCEPTIONS file_open_error = 1
               file_read_error = 2
               OTHERS          = 3 ).

  IF sy-subrc <> 0 OR lv_len = 0.
    MESSAGE e013 WITH pv_name.
    RETURN.
  ENDIF.

  lv_xstr = cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin
                                              iv_size  = lv_len ).

* A workbook saved in the old .XLS format, or a file renamed to .XLSX
* that is not one, cannot be parsed. The user is told to save it as CSV
* rather than being left with an empty list.
  TRY.
      CREATE OBJECT lo_xl
        EXPORTING document_name = pv_name
                  xdocument     = lv_xstr.

      lo_xl->if_fdt_doc_spreadsheet~get_worksheet_names(
        IMPORTING worksheet_names = lt_ws ).

      READ TABLE lt_ws INTO lv_ws INDEX 1.
      IF sy-subrc <> 0.
        MESSAGE e024 WITH pv_name.
        RETURN.
      ENDIF.

      lr_data = lo_xl->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_ws ).

    CATCH cx_root.
      MESSAGE e024 WITH pv_name.
      RETURN.
  ENDTRY.

  IF lr_data IS NOT BOUND.
    MESSAGE e024 WITH pv_name.
    RETURN.
  ENDIF.

  ASSIGN lr_data->* TO <lt_tab>.
  IF <lt_tab> IS NOT ASSIGNED.
    MESSAGE e024 WITH pv_name.
    RETURN.
  ENDIF.

  g_xls = abap_true.

  LOOP AT <lt_tab> ASSIGNING <ls_row>.

    CLEAR ls_raw.

    DO 16 TIMES.

      lv_ix = sy-index.

      UNASSIGN: <lv_in>, <lv_out>.
      ASSIGN COMPONENT lv_ix OF STRUCTURE <ls_row> TO <lv_in>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      ASSIGN COMPONENT lv_ix OF STRUCTURE ls_raw TO <lv_out>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      lv_val = <lv_in>.
      CONDENSE lv_val.
      <lv_out> = lv_val.

    ENDDO.

    APPEND ls_raw TO gt_raw.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& CSV or tab separated text
*&---------------------------------------------------------------------*
FORM upload_text USING pv_name TYPE string
                       pv_ext  TYPE string.

  DATA: lt_line TYPE string_table,
        lv_line TYPE string,
        lv_sep  TYPE c LENGTH 1,
        ls_raw  TYPE ty_raw.

* Read whole lines. The separator is decided below rather than by
* HAS_FIELD_SEPARATOR, which only ever splits on a tab.
  cl_gui_frontend_services=>gui_upload(
    EXPORTING  filename        = pv_name
               filetype        = 'ASC'
    CHANGING   data_tab        = lt_line
    EXCEPTIONS file_open_error = 1
               file_read_error = 2
               OTHERS          = 3 ).

  IF sy-subrc <> 0.
    MESSAGE e013 WITH pv_name.
    RETURN.
  ENDIF.

* A tab anywhere in the file wins, so a tab separated export whose text
* happens to contain commas is still split on tabs
  CLEAR lv_sep.
  LOOP AT lt_line INTO lv_line.
    IF lv_line CS g_tab.
      lv_sep = g_tab.
      EXIT.
    ENDIF.
    IF lv_line CS ','.
      lv_sep = ','.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF lv_sep IS INITIAL.
    IF pv_ext = 'CSV'.
      lv_sep = ','.
    ELSE.
      lv_sep = g_tab.
    ENDIF.
  ENDIF.

  LOOP AT lt_line INTO lv_line.
    CLEAR ls_raw.
    PERFORM split_line USING lv_line lv_sep CHANGING ls_raw.
    APPEND ls_raw TO gt_raw.
  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& One line into the sixteen raw columns
*&
*& SPLIT does the work whenever the line carries no quote, which is
*& every line of every template shipped today. Only a line that really
*& is quoted is walked character by character.
*&---------------------------------------------------------------------*
FORM split_line USING pv_line TYPE string
                      pv_sep  TYPE c
                CHANGING cs_raw TYPE ty_raw.

  DATA: lt_fld TYPE string_table,
        lv_fld TYPE string,
        lv_len TYPE i,
        lv_off TYPE i,
        lv_ch  TYPE c LENGTH 1,
        lv_q   TYPE abap_bool,
        lv_val TYPE string,
        lv_ix  TYPE i.

  CLEAR cs_raw.

  IF pv_line NS '"'.

    SPLIT pv_line AT pv_sep INTO TABLE lt_fld.
    LOOP AT lt_fld INTO lv_fld.
*     SY-TABIX is copied first. Handing a system field straight to a
*     FORM passes it by reference, and the form is then working on a
*     field the runtime may move underneath it.
      lv_ix = sy-tabix.
      PERFORM put_field USING lv_ix lv_fld CHANGING cs_raw.
    ENDLOOP.
    RETURN.

  ENDIF.

  lv_ix  = 1.
  lv_len = strlen( pv_line ).

  WHILE lv_off < lv_len.

    lv_ch = pv_line+lv_off(1).

    IF lv_ch = '"'.
*     Two quotes inside a quoted value are one quote
      IF lv_q = abap_true AND lv_off + 2 <= lv_len AND pv_line+lv_off(2) = '""'.
        CONCATENATE lv_val '"' INTO lv_val RESPECTING BLANKS.
        lv_off = lv_off + 2.
        CONTINUE.
      ENDIF.
      IF lv_q = abap_true.
        lv_q = abap_false.
      ELSE.
        lv_q = abap_true.
      ENDIF.
      lv_off = lv_off + 1.
      CONTINUE.
    ENDIF.

    IF lv_ch = pv_sep AND lv_q = abap_false.
      PERFORM put_field USING lv_ix lv_val CHANGING cs_raw.
      CLEAR lv_val.
      lv_ix  = lv_ix + 1.
      lv_off = lv_off + 1.
      CONTINUE.
    ENDIF.

    CONCATENATE lv_val lv_ch INTO lv_val RESPECTING BLANKS.
    lv_off = lv_off + 1.

  ENDWHILE.

  PERFORM put_field USING lv_ix lv_val CHANGING cs_raw.

ENDFORM.


*&---------------------------------------------------------------------*
FORM put_field USING pv_ix  TYPE i
                     pv_val TYPE string
               CHANGING cs_raw TYPE ty_raw.

  FIELD-SYMBOLS <lv_out> TYPE any.

* Sixteen columns is what TY_RAW holds. A file with more is not an
* error, the extra columns simply belong to no field.
  CHECK pv_ix >= 1 AND pv_ix <= 16.

  UNASSIGN <lv_out>.
  ASSIGN COMPONENT pv_ix OF STRUCTURE cs_raw TO <lv_out>.
  CHECK sy-subrc = 0.

  <lv_out> = pv_val.

ENDFORM.


*&---------------------------------------------------------------------*
*& The heading row
*&
*& CL_FDT_XL_SPREADSHEET turns the heading row of the sheet into the
*& component names of the table it returns, so an Excel upload arrives
*& with the heading already gone. Deleting on the checkbox alone would
*& then have thrown away the first real row. The row is matched against
*& the first heading of the template instead, and the checkbox is only
*& used for a text file whose first row is something else.
*&---------------------------------------------------------------------*
FORM drop_header.

  DATA: lt_head  TYPE string_table,
        lv_name  TYPE string,
        lv_first TYPE string,
        lv_col1  TYPE string,
        ls_first TYPE ty_raw.

  CHECK gt_raw IS NOT INITIAL.

  PERFORM current_type CHANGING g_type.
  PERFORM template_columns USING g_type
                           CHANGING lt_head lv_name.

  READ TABLE gt_raw INTO ls_first INDEX 1.
  CHECK sy-subrc = 0.

  lv_first = ls_first-f01.
  CONDENSE lv_first.
  lv_first = to_upper( lv_first ).

  READ TABLE lt_head INTO lv_col1 INDEX 1.
  IF sy-subrc = 0.
    lv_col1 = to_upper( lv_col1 ).
  ENDIF.

  IF lv_col1 IS NOT INITIAL AND lv_first = lv_col1.
    DELETE gt_raw INDEX 1.
    RETURN.
  ENDIF.

  IF p_head = 'X' AND g_xls = abap_false.
    DELETE gt_raw INDEX 1.
  ENDIF.

ENDFORM.
*& EOC By Arnav on 31/08/26


*&---------------------------------------------------------------------*
*& 1 - Product category, load factor, MTS / MTO
*&---------------------------------------------------------------------*
FORM do_category.

  DATA: ls_raw   TYPE ty_raw,
        ls_cat   TYPE zppt_prod_cat,
        ls_old   TYPE zppt_prod_cat,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_matnr TYPE matnr,
        lv_cat   TYPE zde_prod_cat,
        lv_mts   TYPE zde_mts_mto,
        lv_load  TYPE zde_load_fct,
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
    lv_cat = to_upper( lv_tmp ).
    IF lv_cat IS INITIAL.
      lv_err = 'Product category is mandatory'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

    PERFORM to_dec USING ls_raw-f04 CHANGING lv_load.
    IF lv_load <= 0.
      lv_err = 'Load factor must be a number greater than zero'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

    lv_tmp = ls_raw-f05.
    CONDENSE lv_tmp.
    lv_mts = to_upper( lv_tmp ).
    IF lv_mts IS NOT INITIAL AND lv_mts <> 'MTS' AND lv_mts <> 'MTO'.
      lv_err = 'MTS or MTO column must contain MTS, MTO or nothing'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

*   The existing row is read first so the original created by and
*   created on are carried forward instead of being wiped by the MODIFY
    CLEAR: ls_cat, ls_old, lv_ex.
    SELECT SINGLE * FROM zppt_prod_cat INTO @ls_old
      WHERE werks = @lv_werks AND matnr = @lv_matnr.
    IF sy-subrc = 0.
      lv_ex  = abap_true.
      ls_cat = ls_old.
    ENDIF.

    ls_cat-werks    = lv_werks.
    ls_cat-matnr    = lv_matnr.
    ls_cat-prod_cat = lv_cat.
    ls_cat-load_fct = lv_load.
    ls_cat-mts_mto  = lv_mts.
    PERFORM stamp USING lv_ex CHANGING ls_cat-ernam ls_cat-erdat
                                       ls_cat-aenam ls_cat-aedat.

    IF p_test = abap_false.
      MODIFY zppt_prod_cat FROM @ls_cat.
      IF sy-subrc <> 0.
        lv_err = 'Database update failed'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
        CONTINUE.
      ENDIF.
    ENDIF.

*BOC By Arnav on 03/09/26
*   lv_txt = |Category { lv_cat }, load factor { lv_load }, { lv_mts }|.
    lv_txt = 'Product category uploaded'.
*EOC By Arnav on 03/09/26
    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_blank lv_ex lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& 2 - Material code tracking, old code to new code
*&---------------------------------------------------------------------*
FORM do_tracking.

  DATA: ls_raw   TYPE ty_raw,
        ls_trk   TYPE zppt_mat_track,
        ls_old   TYPE zppt_mat_track,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_new   TYPE matnr,
        lv_old1  TYPE matnr,
        lv_old2  TYPE matnr,
*BOC By Arnav on 03/09/26
        lv_old3  TYPE matnr,
        lv_old4  TYPE matnr,
        lv_old5  TYPE matnr,
*       The five codes as read, for the checks and for CHECK_CHAIN
        ls_chk   TYPE zppt_mat_track,
        lv_cnt   TYPE i,
        lv_j     TYPE i,
*EOC By Arnav on 03/09/26
        lv_ex    TYPE abap_bool,
        lv_err   TYPE string,
        lv_txt   TYPE string,
        lv_blank TYPE char12.

  LOOP AT gt_raw INTO ls_raw.

    lv_row = sy-tabix.
    PERFORM to_plant    USING ls_raw-f01 CHANGING lv_werks.
    PERFORM to_material USING ls_raw-f02 CHANGING lv_new.
    PERFORM to_material USING ls_raw-f03 CHANGING lv_old1.
    PERFORM to_material USING ls_raw-f04 CHANGING lv_old2.
*BOC By Arnav on 03/09/26
    PERFORM to_material USING ls_raw-f05 CHANGING lv_old3.
    PERFORM to_material USING ls_raw-f06 CHANGING lv_old4.
    PERFORM to_material USING ls_raw-f07 CHANGING lv_old5.

    CLEAR ls_chk.
    ls_chk-old_matnr1 = lv_old1.
    ls_chk-old_matnr2 = lv_old2.
    ls_chk-old_matnr3 = lv_old3.
    ls_chk-old_matnr4 = lv_old4.
    ls_chk-old_matnr5 = lv_old5.
*EOC By Arnav on 03/09/26

    PERFORM check_marc USING lv_werks lv_new CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

*BOC By Arnav on 03/09/26 - the same three checks, over five codes
*   IF lv_old1 IS INITIAL AND lv_old2 IS INITIAL.
    CLEAR: lv_cnt, lv_err.

    DO 5 TIMES.
      UNASSIGN <gv_a>.
      ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_chk TO <gv_a>.
      CHECK sy-subrc = 0.
      CHECK <gv_a> IS NOT INITIAL.

      lv_cnt = lv_cnt + 1.

      IF <gv_a> = lv_new.
        lv_err = 'An old material code must be different from the new code'.
        EXIT.
      ENDIF.

      lv_j = sy-index.
      DO 5 TIMES.
        CHECK sy-index > lv_j.
        UNASSIGN <gv_b>.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_chk TO <gv_b>.
        CHECK sy-subrc = 0.
        IF <gv_b> IS NOT INITIAL AND <gv_b> = <gv_a>.
          lv_err = 'The same old material code is given twice'.
          EXIT.
        ENDIF.
      ENDDO.

      IF lv_err IS NOT INITIAL.
        EXIT.
      ENDIF.
    ENDDO.

    IF lv_err IS INITIAL AND lv_cnt = 0.
      lv_err = 'At least one old material code must be given'.
    ENDIF.

    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

*     lv_err = 'At least one old material code must be given'.
*     PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
*     CONTINUE.
*   ENDIF.
*
*   IF lv_old1 = lv_new OR lv_old2 = lv_new.
*     lv_err = 'The old material code must be different from the new code'.
*     PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
*     CONTINUE.
*   ENDIF.
*
*   IF lv_old1 IS NOT INITIAL AND lv_old1 = lv_old2.
*     lv_err = 'Old material 1 and old material 2 are the same code'.
*     PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
*     CONTINUE.
*   ENDIF.
*EOC By Arnav on 03/09/26

*   An old code that is itself a successor would make the chain
*   ambiguous, so it is refused rather than silently mis-added
*BOC By Arnav on 03/09/26
*   PERFORM check_chain USING lv_werks lv_old1 lv_old2 CHANGING lv_err.
    PERFORM check_chain USING lv_werks ls_chk CHANGING lv_err.
*EOC By Arnav on 03/09/26
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
      CONTINUE.
    ENDIF.

    CLEAR: ls_trk, ls_old, lv_ex.
    SELECT SINGLE * FROM zppt_mat_track INTO @ls_old
      WHERE werks = @lv_werks AND new_matnr = @lv_new.
    IF sy-subrc = 0.
      lv_ex  = abap_true.
      ls_trk = ls_old.
    ENDIF.

    ls_trk-werks      = lv_werks.
    ls_trk-new_matnr  = lv_new.
    ls_trk-old_matnr1 = lv_old1.
    ls_trk-old_matnr2 = lv_old2.
*BOC By Arnav on 03/09/26
    ls_trk-old_matnr3 = lv_old3.
    ls_trk-old_matnr4 = lv_old4.
    ls_trk-old_matnr5 = lv_old5.
*EOC By Arnav on 03/09/26
    PERFORM stamp USING lv_ex CHANGING ls_trk-ernam ls_trk-erdat
                                       ls_trk-aenam ls_trk-aedat.

    IF p_test = abap_false.
      MODIFY zppt_mat_track FROM @ls_trk.
      IF sy-subrc <> 0.
        lv_err = 'Database update failed'.
        PERFORM log USING lv_row lv_werks lv_new lv_blank gc_err lv_err.
        CONTINUE.
      ENDIF.
    ENDIF.

*BOC By Arnav on 03/09/26
*   lv_txt = |History of { lv_old1 } { lv_old2 } will now be reported under { lv_new }|.
    lv_txt = 'Material mapping uploaded'.
*EOC By Arnav on 03/09/26
    PERFORM log_ok USING lv_row lv_werks lv_new lv_blank lv_ex lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*BOC By Arnav on 03/09/26
* Five old codes now, so the row is passed in whole and walked rather
* than one parameter per code. Old body:
*FORM check_chain USING pv_werks TYPE werks_d
*                       pv_old1  TYPE matnr
*                       pv_old2  TYPE matnr
*                 CHANGING pv_err TYPE string.
*
*  DATA lv_hit TYPE matnr.
*
*  CLEAR pv_err.
*
*  IF pv_old1 IS NOT INITIAL.
*    SELECT SINGLE new_matnr FROM zppt_mat_track INTO @lv_hit
*      WHERE werks = @pv_werks AND new_matnr = @pv_old1.
*    IF sy-subrc = 0.
*      pv_err = |{ pv_old1 } is already a new code in this table, a chain is not supported|.
*      RETURN.
*    ENDIF.
*  ENDIF.
*
*  IF pv_old2 IS NOT INITIAL.
*    SELECT SINGLE new_matnr FROM zppt_mat_track INTO @lv_hit
*      WHERE werks = @pv_werks AND new_matnr = @pv_old2.
*    IF sy-subrc = 0.
*      pv_err = |{ pv_old2 } is already a new code in this table, a chain is not supported|.
*    ENDIF.
*  ENDIF.
*
*ENDFORM.
FORM check_chain USING pv_werks TYPE werks_d
                       ps_trk   TYPE zppt_mat_track
                 CHANGING pv_err TYPE string.

  DATA: lv_hit TYPE matnr,
        lv_old TYPE matnr.

  FIELD-SYMBOLS <lv_o> TYPE any.

  CLEAR pv_err.

  DO 5 TIMES.

    UNASSIGN <lv_o>.
    ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ps_trk TO <lv_o>.
    CHECK sy-subrc = 0.

    lv_old = <lv_o>.
    CHECK lv_old IS NOT INITIAL.

    SELECT SINGLE new_matnr FROM zppt_mat_track INTO @lv_hit
      WHERE werks = @pv_werks AND new_matnr = @lv_old.
    IF sy-subrc = 0.
      pv_err = |{ lv_old } is already a new code in this table, a chain is not supported|.
      RETURN.
    ENDIF.

  ENDDO.

ENDFORM.
*EOC By Arnav on 03/09/26


*&---------------------------------------------------------------------*
*& 3 - Material exclusion
*&---------------------------------------------------------------------*
FORM do_exclusion.

  DATA: ls_raw   TYPE ty_raw,
        ls_exc   TYPE zppt_mat_excl,
        ls_old   TYPE zppt_mat_excl,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_matnr TYPE matnr,
        lv_ex    TYPE abap_bool,
        lv_err   TYPE string,
        lv_txt   TYPE string,
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

    CLEAR: ls_exc, ls_old, lv_ex.
    SELECT SINGLE * FROM zppt_mat_excl INTO @ls_old
      WHERE werks = @lv_werks AND matnr = @lv_matnr.
    IF sy-subrc = 0.
      lv_ex  = abap_true.
      ls_exc = ls_old.
    ENDIF.

    ls_exc-werks = lv_werks.
    ls_exc-matnr = lv_matnr.
    PERFORM stamp USING lv_ex CHANGING ls_exc-ernam ls_exc-erdat
                                       ls_exc-aenam ls_exc-aedat.

    IF p_test = abap_false.
      MODIFY zppt_mat_excl FROM @ls_exc.
      IF sy-subrc <> 0.
        lv_err = 'Database update failed'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_blank gc_err lv_err.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF lv_ex = abap_true.
      lv_txt = 'Already excluded, entry refreshed'.
    ELSE.
      lv_txt = 'Excluded from forecasting'.
    ENDIF.
    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_blank lv_ex lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& 4 - Legacy sales history, twelve months on one row
*&---------------------------------------------------------------------*
FORM do_history.

  DATA: ls_raw   TYPE ty_raw,
        ls_hist  TYPE zppt_sls_hist,
        ls_old   TYPE zppt_sls_hist,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_matnr TYPE matnr,
        lv_year  TYPE i,
        lv_gjahr TYPE gjahr,
        lv_meins TYPE meins,
        lv_qty   TYPE zde_fcst_qty,
        lv_tot   TYPE zde_fcst_qty,
        lv_ex    TYPE abap_bool,
        lv_err   TYPE string,
        lv_txt   TYPE string,
        lv_tmp   TYPE char40,
        lv_per   TYPE char12,
        lv_i     TYPE i,
        lv_src   TYPE i,
        lv_fld   TYPE char3.

  FIELD-SYMBOLS: <lv_in>  TYPE any,
                 <lv_out> TYPE any.

  LOOP AT gt_raw INTO ls_raw.

    lv_row = sy-tabix.
    PERFORM to_plant    USING ls_raw-f01 CHANGING lv_werks.
    PERFORM to_material USING ls_raw-f02 CHANGING lv_matnr.

    lv_per = ls_raw-f03.
    CONDENSE lv_per.

    PERFORM check_marc USING lv_werks lv_matnr CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

    PERFORM to_int USING ls_raw-f03 CHANGING lv_year.
    IF lv_year < 1900 OR lv_year > 2999.
      lv_err = 'Year must be the four digit year the financial year starts in'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.
    lv_gjahr = lv_year.

    lv_tmp = ls_raw-f16.
    CONDENSE lv_tmp.
    lv_meins = to_upper( lv_tmp ).

    CLEAR: ls_hist, ls_old, lv_ex.
    SELECT SINGLE * FROM zppt_sls_hist INTO @ls_old
      WHERE werks = @lv_werks AND matnr = @lv_matnr AND gjahr = @lv_gjahr.
    IF sy-subrc = 0.
      lv_ex   = abap_true.
      ls_hist = ls_old.
    ENDIF.

    ls_hist-werks = lv_werks.
    ls_hist-matnr = lv_matnr.
    ls_hist-gjahr = lv_gjahr.
    ls_hist-meins = lv_meins.

*   Columns 4 to 15 of the file hold M01 to M12, April first
    CLEAR lv_tot.
    lv_i = 1.
    WHILE lv_i <= 12.

      lv_src = lv_i + 3.
      lv_fld = |M{ lv_i WIDTH = 2 PAD = '0' }|.

      UNASSIGN: <lv_in>, <lv_out>.
      ASSIGN COMPONENT lv_src OF STRUCTURE ls_raw  TO <lv_in>.
      ASSIGN COMPONENT lv_fld OF STRUCTURE ls_hist TO <lv_out>.

      IF <lv_in> IS ASSIGNED AND <lv_out> IS ASSIGNED.
        PERFORM to_dec USING <lv_in> CHANGING lv_qty.
        <lv_out> = lv_qty.
        lv_tot   = lv_tot + lv_qty.
      ENDIF.

      lv_i = lv_i + 1.
    ENDWHILE.

    IF lv_tot = 0.
      lv_err = 'All twelve monthly figures are zero or not numeric'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

    PERFORM stamp USING lv_ex CHANGING ls_hist-ernam ls_hist-erdat
                                       ls_hist-aenam ls_hist-aedat.

    IF p_test = abap_false.
      MODIFY zppt_sls_hist FROM @ls_hist.
      IF sy-subrc <> 0.
        lv_err = 'Database update failed'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
        CONTINUE.
      ENDIF.
    ENDIF.

*BOC By Arnav on 03/09/26
*   lv_txt = |Twelve months loaded, year total { lv_tot } { lv_meins }|.
    lv_txt = 'Sales history uploaded'.
*EOC By Arnav on 03/09/26
    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_per lv_ex lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& 5 and 6 - Business forecast given by sales, quarterly or monthly
*&---------------------------------------------------------------------*
FORM do_business USING pv_mode TYPE char1.

  DATA: ls_raw   TYPE ty_raw,
        ls_qt    TYPE zppt_fcst_qt,
        ls_mn    TYPE zppt_fcst_mn,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_matnr TYPE matnr,
        lv_pi    TYPE i,
        lv_year  TYPE i,
        lv_gjahr TYPE gjahr,
        lv_qtr   TYPE zde_quarter,
        lv_poper TYPE poper,
        lv_qty   TYPE zde_fcst_qty,
        lv_total TYPE zde_fcst_qty,
        lv_ex    TYPE abap_bool,
        lv_err   TYPE string,
        lv_txt   TYPE string,
        lv_per   TYPE char12.

  LOOP AT gt_raw INTO ls_raw.

    lv_row = sy-tabix.
    PERFORM to_material USING ls_raw-f01 CHANGING lv_matnr.
    PERFORM to_plant    USING ls_raw-f02 CHANGING lv_werks.
    PERFORM period_text USING pv_mode ls_raw-f03 CHANGING lv_per.

    PERFORM check_marc USING lv_werks lv_matnr CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

    PERFORM to_int USING ls_raw-f03 CHANGING lv_pi.
    PERFORM check_period USING pv_mode lv_pi CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

    PERFORM to_int USING ls_raw-f04 CHANGING lv_year.
    IF lv_year < 1900 OR lv_year > 2999.
      lv_err = 'Year must be the four digit year the financial year starts in'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.
    lv_gjahr = lv_year.

    PERFORM to_dec USING ls_raw-f05 CHANGING lv_qty.
    IF lv_qty < 0.
      lv_err = 'Sales forecast quantity cannot be negative'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

    CLEAR lv_ex.

    IF pv_mode = 'Q'.

      lv_qtr = lv_pi.

*     The whole row is read and written back, so a business forecast
*     loaded onto an already generated forecast changes only that one
*     column and leaves the calculated figures untouched
      CLEAR ls_qt.
      SELECT SINGLE * FROM zppt_fcst_qt INTO @ls_qt
        WHERE werks = @lv_werks AND matnr = @lv_matnr
          AND gjahr = @lv_gjahr AND quarter = @lv_qtr.
      IF sy-subrc = 0.
        lv_ex = abap_true.
      ELSE.
        CLEAR ls_qt.
        ls_qt-werks   = lv_werks.
        ls_qt-matnr   = lv_matnr.
        ls_qt-gjahr   = lv_gjahr.
        ls_qt-quarter = lv_qtr.
      ENDIF.

      ls_qt-bus_fcst = lv_qty.
*BOC By Arnav on 03/09/26
*     PERFORM final_qty CHANGING ls_qt-fcst_qty ls_qt-bus_fcst
*                                ls_qt-bus_fcst_add ls_qt-final_qty.
      PERFORM final_qty CHANGING ls_qt-fcst_qty ls_qt-bus_fcst
                                 ls_qt-final_qty.
      PERFORM qt_finals CHANGING ls_qt.
*EOC By Arnav on 03/09/26
      PERFORM stamp USING lv_ex CHANGING ls_qt-ernam ls_qt-erdat
                                         ls_qt-aenam ls_qt-aedat.

      IF p_test = abap_false.
        MODIFY zppt_fcst_qt FROM @ls_qt.
        IF sy-subrc <> 0.
          lv_err = 'Database update failed'.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.
      ENDIF.

*BOC By Arnav on 03/09/26
*     lv_total = ls_qt-final_qty + ls_qt-bus_fcst_add.
*     lv_txt = |Business forecast { lv_qty }, final quantity now { lv_total }|.
      lv_txt = 'Business forecast uploaded'.
*EOC By Arnav on 03/09/26

    ELSE.

      lv_poper = lv_pi.

      CLEAR ls_mn.
      SELECT SINGLE * FROM zppt_fcst_mn INTO @ls_mn
        WHERE werks = @lv_werks AND matnr = @lv_matnr
          AND gjahr = @lv_gjahr AND period = @lv_poper.
      IF sy-subrc = 0.
        lv_ex = abap_true.
      ELSE.
        CLEAR ls_mn.
        ls_mn-werks  = lv_werks.
        ls_mn-matnr  = lv_matnr.
        ls_mn-gjahr  = lv_gjahr.
        ls_mn-period = lv_poper.
      ENDIF.

      ls_mn-bus_fcst = lv_qty.
*BOC By Arnav on 03/09/26
*     PERFORM final_qty CHANGING ls_mn-fcst_qty ls_mn-bus_fcst
*                                ls_mn-bus_fcst_add ls_mn-final_qty.
      PERFORM final_qty CHANGING ls_mn-fcst_qty ls_mn-bus_fcst
                                 ls_mn-final_qty.
*EOC By Arnav on 03/09/26
      PERFORM stamp USING lv_ex CHANGING ls_mn-ernam ls_mn-erdat
                                         ls_mn-aenam ls_mn-aedat.

      IF p_test = abap_false.
        MODIFY zppt_fcst_mn FROM @ls_mn.
        IF sy-subrc <> 0.
          lv_err = 'Database update failed'.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.
      ENDIF.

      lv_total = ls_mn-final_qty + ls_mn-bus_fcst_add.
*BOC By Arnav on 03/09/26
*     lv_txt = |Business forecast { lv_qty }, final quantity now { lv_total }|.
      lv_txt = 'Business forecast uploaded'.
*EOC By Arnav on 03/09/26

    ENDIF.

    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_per lv_ex lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& 7 and 8 - Additional or reduced quantity with a reason
*&---------------------------------------------------------------------*
FORM do_change USING pv_mode TYPE char1.

  DATA: ls_raw   TYPE ty_raw,
        ls_qt    TYPE zppt_fcst_qt,
        ls_mn    TYPE zppt_fcst_mn,
        lv_row   TYPE i,
        lv_werks TYPE werks_d,
        lv_matnr TYPE matnr,
        lv_pi    TYPE i,
        lv_year  TYPE i,
        lv_gjahr TYPE gjahr,
        lv_qtr   TYPE zde_quarter,
        lv_poper TYPE poper,
        lv_qty   TYPE zde_fcst_qty,
        lv_total TYPE zde_fcst_qty,
        lv_rsn   TYPE zde_fcst_reason,
        lv_err   TYPE string,
        lv_txt   TYPE string,
        lv_tmp   TYPE char40,
        lv_per   TYPE char12,
*BOC By Arnav on 03/09/26
*       The quarterly file carries MONTH in column 4, so YEAR, QUANTITY
*       and REASON all sit one column further right than in the monthly
*       file. These hold whichever column applies to this mode.
        lv_c_mon  TYPE char40,
        lv_c_year TYPE char40,
        lv_c_qty  TYPE char40,
        lv_c_rsn  TYPE char40,
        lv_mi     TYPE i,
        lv_slot   TYPE i,
        lv_qchk   TYPE zde_quarter,
*EOC By Arnav on 03/09/26
        lv_yes   TYPE abap_bool.

  lv_yes = abap_true.

  LOOP AT gt_raw INTO ls_raw.

    lv_row = sy-tabix.
    PERFORM to_material USING ls_raw-f01 CHANGING lv_matnr.
    PERFORM to_plant    USING ls_raw-f02 CHANGING lv_werks.
    PERFORM period_text USING pv_mode ls_raw-f03 CHANGING lv_per.

    PERFORM check_marc USING lv_werks lv_matnr CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

    PERFORM to_int USING ls_raw-f03 CHANGING lv_pi.
    PERFORM check_period USING pv_mode lv_pi CHANGING lv_err.
    IF lv_err IS NOT INITIAL.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

*BOC By Arnav on 03/09/26
    CLEAR: lv_c_mon, lv_c_year, lv_c_qty, lv_c_rsn, lv_mi, lv_slot.

    IF pv_mode = 'Q'.
      lv_c_mon  = ls_raw-f04.
      lv_c_year = ls_raw-f05.
      lv_c_qty  = ls_raw-f06.
      lv_c_rsn  = ls_raw-f07.
    ELSE.
      lv_c_year = ls_raw-f04.
      lv_c_qty  = ls_raw-f05.
      lv_c_rsn  = ls_raw-f06.
    ENDIF.

*   The quarter is split by month, so a quarterly change has to say
*   which month it applies to. GV_QMONTH decides what MONTH means.
    IF pv_mode = 'Q'.

      PERFORM to_int USING lv_c_mon CHANGING lv_mi.

      IF gv_qmonth = 'P'.

        IF lv_mi < 1 OR lv_mi > 12.
          lv_err = 'Month must be a period 1 to 12, where 1 is April and 12 is March'.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.

        lv_qchk = zcl_pp_fcst_util=>period_to_quarter( CONV #( lv_mi ) ).
        IF lv_qchk <> lv_pi.
          lv_err = |Month { lv_mi } is not in quarter { lv_pi }|.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.

        lv_slot = lv_mi - ( lv_pi - 1 ) * 3.

      ELSE.

        IF lv_mi < 1 OR lv_mi > 3.
          lv_err = 'Month must be 1, 2 or 3 - the first, second or third month of the quarter'.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.

        lv_slot = lv_mi.

      ENDIF.

    ENDIF.

*   PERFORM to_int USING ls_raw-f04 CHANGING lv_year.
    PERFORM to_int USING lv_c_year CHANGING lv_year.
*EOC By Arnav on 03/09/26
    IF lv_year < 1900 OR lv_year > 2999.
      lv_err = 'Year must be the four digit year the financial year starts in'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.
    lv_gjahr = lv_year.

*BOC By Arnav on 03/09/26
*   lv_tmp = ls_raw-f06.
    lv_tmp = lv_c_rsn.
*EOC By Arnav on 03/09/26
    CONDENSE lv_tmp.
    lv_rsn = lv_tmp.
    IF lv_rsn IS INITIAL.
      lv_err = 'Reason is mandatory when the forecast is changed'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

*BOC By Arnav on 03/09/26
*   PERFORM to_dec USING ls_raw-f05 CHANGING lv_qty.
    PERFORM to_dec USING lv_c_qty CHANGING lv_qty.
*EOC By Arnav on 03/09/26
    IF lv_qty = 0.
      lv_err = 'Change quantity is zero or not numeric, nothing to apply'.
      PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
      CONTINUE.
    ENDIF.

*   A change adjusts a forecast that already exists. If it is not there
*   the row is rejected rather than a bare change record being created.
    IF pv_mode = 'Q'.

      lv_qtr = lv_pi.

      CLEAR ls_qt.
      SELECT SINGLE * FROM zppt_fcst_qt INTO @ls_qt
        WHERE werks = @lv_werks AND matnr = @lv_matnr
          AND gjahr = @lv_gjahr AND quarter = @lv_qtr.
      IF sy-subrc <> 0.
        lv_err = 'No quarterly forecast has been saved for this plant, material and quarter'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
        CONTINUE.
      ENDIF.

*BOC By Arnav on 03/09/26
*     ls_qt-bus_fcst_add = lv_qty.
*     ls_qt-reason       = lv_rsn.
*     PERFORM final_qty CHANGING ls_qt-fcst_qty ls_qt-bus_fcst
*                                ls_qt-bus_fcst_add ls_qt-final_qty.
**    FINAL_QTY no longer carries the change, so the guard tests the
**    total the change actually moves
*     lv_total = ls_qt-final_qty + ls_qt-bus_fcst_add.
*     IF lv_total < 0.
*       lv_err = 'The reduction is larger than the forecast, the final quantity would be negative'.
*       PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
*       CONTINUE.
*     ENDIF.
*     The change lands on the month it names and only that month. The
*     other two are left as the row already holds them. REASON is one
*     field for the quarter, so the last row uploaded owns it.
      UNASSIGN <gv_add>.
      ASSIGN COMPONENT |BUS_FCST_ADD{ lv_slot }| OF STRUCTURE ls_qt TO <gv_add>.
      IF <gv_add> IS NOT ASSIGNED.
        lv_err = 'Month is outside the three months of the quarter'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
        CONTINUE.
      ENDIF.

      <gv_add>     = lv_qty.
      ls_qt-reason = lv_rsn.

      PERFORM final_qty CHANGING ls_qt-fcst_qty ls_qt-bus_fcst
                                 ls_qt-final_qty.
      PERFORM qt_finals CHANGING ls_qt.

*     A reduction may not take THAT MONTH below zero. The quarter total
*     is no longer what is guarded - each month stands on its own.
      CLEAR lv_total.
      UNASSIGN <gv_fin>.
      ASSIGN COMPONENT |M{ lv_slot + 3 }_FCST_FINAL| OF STRUCTURE ls_qt
        TO <gv_fin>.
      IF <gv_fin> IS ASSIGNED.
        lv_total = <gv_fin>.
      ENDIF.
      IF lv_total < 0.
        lv_err = 'The reduction is larger than the forecast for that month, the final quantity would be negative'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
        CONTINUE.
      ENDIF.
*EOC By Arnav on 03/09/26

      PERFORM stamp USING lv_yes CHANGING ls_qt-ernam ls_qt-erdat
                                          ls_qt-aenam ls_qt-aedat.

      IF p_test = abap_false.
        MODIFY zppt_fcst_qt FROM @ls_qt.
        IF sy-subrc <> 0.
          lv_err = 'Database update failed'.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.
      ENDIF.

*BOC By Arnav on 03/09/26
*     lv_txt = |Change { lv_qty }, final quantity now { lv_total }, reason { lv_rsn }|.
      lv_txt = 'Forecast change uploaded'.
*EOC By Arnav on 03/09/26

    ELSE.

      lv_poper = lv_pi.

      CLEAR ls_mn.
      SELECT SINGLE * FROM zppt_fcst_mn INTO @ls_mn
        WHERE werks = @lv_werks AND matnr = @lv_matnr
          AND gjahr = @lv_gjahr AND period = @lv_poper.
      IF sy-subrc <> 0.
        lv_err = 'No monthly forecast has been saved for this plant, material and month'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
        CONTINUE.
      ENDIF.

      ls_mn-bus_fcst_add = lv_qty.
      ls_mn-reason       = lv_rsn.
*BOC By Arnav on 03/09/26
*     PERFORM final_qty CHANGING ls_mn-fcst_qty ls_mn-bus_fcst
*                                ls_mn-bus_fcst_add ls_mn-final_qty.
      PERFORM final_qty CHANGING ls_mn-fcst_qty ls_mn-bus_fcst
                                 ls_mn-final_qty.
*EOC By Arnav on 03/09/26

      lv_total = ls_mn-final_qty + ls_mn-bus_fcst_add.
      IF lv_total < 0.
        lv_err = 'The reduction is larger than the forecast, the final quantity would be negative'.
        PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
        CONTINUE.
      ENDIF.

      PERFORM stamp USING lv_yes CHANGING ls_mn-ernam ls_mn-erdat
                                          ls_mn-aenam ls_mn-aedat.

      IF p_test = abap_false.
        MODIFY zppt_fcst_mn FROM @ls_mn.
        IF sy-subrc <> 0.
          lv_err = 'Database update failed'.
          PERFORM log USING lv_row lv_werks lv_matnr lv_per gc_err lv_err.
          CONTINUE.
        ENDIF.
      ENDIF.

*BOC By Arnav on 03/09/26
*     lv_txt = |Change { lv_qty }, final quantity now { lv_total }, reason { lv_rsn }|.
      lv_txt = 'Forecast change uploaded'.
*EOC By Arnav on 03/09/26

    ENDIF.

*   A change always adjusts an existing forecast, so it is never a create
    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_per lv_yes lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& FINAL_QTY must be worked out exactly as the report works it out, or
*& an uploaded row and a generated row would disagree.
*&
*& The FS compares the generated forecast with the business forecast and
*& takes the higher of the two - "Compare forecast and business
*& forecast", sheet 3 row 57, confirmed by the worked example where
*& 1200 against 4000 gives 4000. The additional plan quantity is NOT
*& part of it; it is added afterwards to give the second final column.
*&
*& This previously added all three together, which inflated every
*& uploaded row.
*&---------------------------------------------------------------------*
*BOC By Arnav on 03/09/26
*FORM final_qty CHANGING cv_gen TYPE zde_fcst_qty
*                        cv_bus TYPE zde_fcst_qty
*                        cv_add TYPE zde_fcst_qty
*                        cv_fin TYPE zde_fcst_qty.
* CV_ADD was never read, and the quarterly table has no single
* BUS_FCST_ADD to pass any more.
FORM final_qty CHANGING cv_gen TYPE zde_fcst_qty
                        cv_bus TYPE zde_fcst_qty
                        cv_fin TYPE zde_fcst_qty.

  cv_fin = nmax( val1 = cv_gen val2 = cv_bus ).

ENDFORM.


*&---------------------------------------------------------------------*
*& Quarterly per month finals and values
*&
*&   Final of a month = that month's forecast + that month's additional
*&                      plan quantity
*&   Value            = final quantity x PRICE
*&   Tonnage value    = final quantity x net weight x PRICE
*&
*& PRICE is not filled by anything yet, so both value columns are 0.
*& Nothing else changes when the price logic arrives.
*&---------------------------------------------------------------------*
FORM qt_finals CHANGING cs_qt TYPE zppt_fcst_qt.

  DATA: lv_i   TYPE i,
        lv_fin TYPE zde_fcst_qty,
        lv_ton TYPE zde_fcst_qty.

  FIELD-SYMBOLS: <lv_f>  TYPE any,
                 <lv_a>  TYPE any,
                 <lv_ff> TYPE any,
                 <lv_v>  TYPE any,
                 <lv_tv> TYPE any.

  DO 3 TIMES.

    lv_i = sy-index.

    UNASSIGN: <lv_f>, <lv_a>, <lv_ff>, <lv_v>, <lv_tv>.

    ASSIGN COMPONENT |M{ lv_i + 3 }_FCST|       OF STRUCTURE cs_qt TO <lv_f>.
    ASSIGN COMPONENT |BUS_FCST_ADD{ lv_i }|     OF STRUCTURE cs_qt TO <lv_a>.
    ASSIGN COMPONENT |M{ lv_i + 3 }_FCST_FINAL| OF STRUCTURE cs_qt TO <lv_ff>.
    ASSIGN COMPONENT |M{ lv_i + 3 }_VAL|        OF STRUCTURE cs_qt TO <lv_v>.
    ASSIGN COMPONENT |M{ lv_i + 3 }_TON_VAL|    OF STRUCTURE cs_qt TO <lv_tv>.

    CHECK <lv_f> IS ASSIGNED AND <lv_a> IS ASSIGNED AND <lv_ff> IS ASSIGNED.

    lv_fin  = <lv_f> + <lv_a>.
    <lv_ff> = lv_fin.

    IF <lv_v> IS ASSIGNED.
      <lv_v> = lv_fin * cs_qt-price.
    ENDIF.

    IF <lv_tv> IS ASSIGNED.
      lv_ton  = lv_fin * cs_qt-ntgew.
      <lv_tv> = lv_ton * cs_qt-price.
    ENDIF.

  ENDDO.

ENDFORM.
*EOC By Arnav on 03/09/26


*&---------------------------------------------------------------------*
FORM stamp USING pv_exists TYPE abap_bool
           CHANGING cv_ernam TYPE any
                    cv_erdat TYPE any
                    cv_aenam TYPE any
                    cv_aedat TYPE any.

  IF pv_exists = abap_false OR cv_ernam IS INITIAL.
    cv_ernam = sy-uname.
    cv_erdat = sy-datum.
  ENDIF.

  cv_aenam = sy-uname.
  cv_aedat = sy-datum.

ENDFORM.


*&---------------------------------------------------------------------*
FORM check_period USING pv_mode TYPE char1
                        pv_per  TYPE i
                  CHANGING pv_err TYPE string.

  CLEAR pv_err.

  IF pv_mode = 'Q'.
    IF pv_per < 1 OR pv_per > 4.
      pv_err = 'Quarter must be 1 to 4, where 1 is April to June'.
    ENDIF.
  ELSE.
    IF pv_per < 1 OR pv_per > 12.
      pv_err = 'Month must be 1 to 12, where 1 is April and 12 is March'.
    ENDIF.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& The period is shown on the log in words so the user is not left
*& working out why month 1 means April
*&---------------------------------------------------------------------*
FORM period_text USING pv_mode TYPE char1
                       pv_in   TYPE any
                 CHANGING cv_txt TYPE char12.

  CONSTANTS lc_mon TYPE char36
    VALUE 'AprMayJunJulAugSepOctNovDecJanFebMar'.

  DATA: lv_i   TYPE i,
        lv_off TYPE i,
        lv_nam TYPE char3,
        lv_num TYPE char2.

  CLEAR cv_txt.

  PERFORM to_int USING pv_in CHANGING lv_i.

  IF pv_mode = 'Q'.
    IF lv_i >= 1 AND lv_i <= 4.
      lv_num = lv_i.
      CONDENSE lv_num.
      CONCATENATE 'Q' lv_num INTO cv_txt.
    ENDIF.
    RETURN.
  ENDIF.

  IF lv_i >= 1 AND lv_i <= 12.
    lv_off = ( lv_i - 1 ) * 3.
    lv_nam = lc_mon+lv_off(3).
    lv_num = lv_i.
    CONDENSE lv_num.
    CONCATENATE 'M' lv_num '-' lv_nam INTO cv_txt.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM check_marc USING pv_werks TYPE werks_d
                      pv_matnr TYPE matnr
                CHANGING pv_err TYPE string.

  DATA: lv_hit TYPE matnr,
        lv_ok  TYPE abap_bool.

  CLEAR pv_err.

  IF pv_werks IS INITIAL OR pv_matnr IS INITIAL.
    pv_err = 'Plant and material are both mandatory'.
    RETURN.
  ENDIF.

  SELECT SINGLE matnr FROM marc INTO @lv_hit
    WHERE werks = @pv_werks AND matnr = @pv_matnr.

  IF sy-subrc <> 0.
    pv_err = |Material { pv_matnr } is not extended to plant { pv_werks }|.
    RETURN.
  ENDIF.

  lv_ok = zcl_pp_fcst_util=>check_authority( iv_werks = pv_werks
                                             iv_actvt = '02' ).
  IF lv_ok = abap_false.
    pv_err = |No authorisation to maintain forecast data for plant { pv_werks }|.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM to_plant USING pv_in TYPE any CHANGING cv_werks TYPE werks_d.

* Plant carries no conversion exit, so it is taken as typed
  CLEAR cv_werks.
  cv_werks = pv_in.
  CONDENSE cv_werks.

ENDFORM.


*&---------------------------------------------------------------------*
FORM to_material USING pv_in TYPE any CHANGING cv_matnr TYPE matnr.

  DATA lv_in TYPE char40.

  CLEAR cv_matnr.

  lv_in = pv_in.
  CONDENSE lv_in.
  CHECK lv_in IS NOT INITIAL.

* Entered without leading zeros in the spreadsheet, stored padded
  CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
    EXPORTING  input        = lv_in
    IMPORTING  output       = cv_matnr
    EXCEPTIONS length_error = 1
               OTHERS       = 2.

  IF sy-subrc <> 0.
    cv_matnr = lv_in.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM to_dec USING pv_in TYPE any CHANGING cv_out TYPE any.

  DATA lv_in TYPE string.

  CLEAR cv_out.

  lv_in = pv_in.
  CONDENSE lv_in NO-GAPS.
  CHECK lv_in IS NOT INITIAL.

* Thousand separators from a spreadsheet export are dropped
  REPLACE ALL OCCURRENCES OF ',' IN lv_in WITH ''.

  TRY.
      cv_out = lv_in.
    CATCH cx_sy_conversion_no_number.
      CLEAR cv_out.
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
FORM to_int USING pv_in TYPE any CHANGING cv_out TYPE i.

  DATA lv_in TYPE string.

  CLEAR cv_out.

  lv_in = pv_in.
  CONDENSE lv_in NO-GAPS.
  CHECK lv_in IS NOT INITIAL.

  TRY.
      cv_out = lv_in.
    CATCH cx_sy_conversion_no_number.
      CLEAR cv_out.
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
FORM log USING pv_row    TYPE i
               pv_werks  TYPE any
               pv_matnr  TYPE any
               pv_period TYPE any
               pv_action TYPE char14
               pv_text   TYPE any.

  DATA ls_log TYPE ty_log.

  CLEAR ls_log.
  ls_log-row     = pv_row.
  ls_log-werks   = pv_werks.
  ls_log-matnr   = pv_matnr.
  ls_log-period  = pv_period.
  ls_log-action  = pv_action.
  ls_log-message = pv_text.

  IF pv_action = gc_err.
    ls_log-light = '1'.
    g_err = g_err + 1.
  ELSEIF pv_action = gc_chg OR pv_action = gc_tchg.
    ls_log-light = '2'.
    g_chg = g_chg + 1.
  ELSE.
    ls_log-light = '3'.
    g_new = g_new + 1.
  ENDIF.

  APPEND ls_log TO gt_log.

ENDFORM.


*&---------------------------------------------------------------------*
FORM log_ok USING pv_row    TYPE i
                  pv_werks  TYPE any
                  pv_matnr  TYPE any
                  pv_period TYPE any
                  pv_exists TYPE abap_bool
                  pv_text   TYPE any.

  DATA: lv_action TYPE char14,
        lv_text   TYPE string.

  IF p_test = 'X'.
    IF pv_exists = abap_true.
      lv_action = gc_tchg.
    ELSE.
      lv_action = gc_tnew.
    ENDIF.
  ELSE.
    IF pv_exists = abap_true.
      lv_action = gc_chg.
    ELSE.
      lv_action = gc_new.
    ENDIF.
  ENDIF.

  lv_text = pv_text.

  PERFORM log USING pv_row pv_werks pv_matnr pv_period lv_action lv_text.

ENDFORM.


*&---------------------------------------------------------------------*
FORM display_log.

  DATA: lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table,
        lv_head TYPE string,
        lv_n    TYPE char10,
        lv_c    TYPE char10,
        lv_e    TYPE char10,
        lv_ttl  TYPE lvc_title.

  lv_n = g_new. CONDENSE lv_n.
  lv_c = g_chg. CONDENSE lv_c.
  lv_e = g_err. CONDENSE lv_e.

  IF p_test = 'X'.
    CONCATENATE 'Test run, nothing saved:' lv_n 'would be created,' lv_c
                'would be changed,' lv_e 'rejected'
           INTO lv_head SEPARATED BY space.
  ELSE.
    CONCATENATE 'Upload finished:' lv_n 'created,' lv_c 'changed,' lv_e
                'rejected'
           INTO lv_head SEPARATED BY space.
  ENDIF.

  MESSAGE lv_head TYPE 'S'.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_log ).

      lo_alv->get_functions( )->set_all( ).

      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( ).

      TRY.
          lo_cols->set_exception_column( 'LIGHT' ).
        CATCH cx_salv_data_error.
      ENDTRY.

      PERFORM txt USING lo_cols 'ROW'     'File Row'.
      PERFORM txt USING lo_cols 'WERKS'   'Plant'.
      PERFORM txt USING lo_cols 'MATNR'   'Material'.
      PERFORM txt USING lo_cols 'PERIOD'  'Period'.
      PERFORM txt USING lo_cols 'ACTION'  'Result'.
      PERFORM txt USING lo_cols 'MESSAGE' 'Detail'.

*     The detail column carries a whole sentence, so it is given room
*     up front instead of the user dragging it wider on every run
      TRY.
          lo_cols->get_column( 'MESSAGE' )->set_output_length( 60 ).
        CATCH cx_salv_not_found.
      ENDTRY.

      lv_ttl = lv_head.
      lo_alv->get_display_settings( )->set_list_header( lv_ttl ).

      lo_alv->display( ).

    CATCH cx_salv_msg.
      MESSAGE lv_head TYPE 'I'.
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
FORM txt USING po_cols TYPE REF TO cl_salv_columns_table
               pv_name TYPE any
               pv_text TYPE any.

  DATA: lo_col TYPE REF TO cl_salv_column,
        lv_nam TYPE lvc_fname,
        lv_txt TYPE string,
        lv_len TYPE lvc_outlen,
        lv_s   TYPE scrtext_s,
        lv_m   TYPE scrtext_m,
        lv_l   TYPE scrtext_l.

  lv_nam = pv_name.
  lv_txt = pv_text.
  lv_s   = lv_txt.
  lv_m   = lv_txt.
  lv_l   = lv_txt.

* ALV picks WHICH of the three heading texts to draw from the column
* output length - the short one below 10 characters, the medium one
* below 20, the long one above that. A long heading on a narrow numeric
* column was therefore drawn from the short text and cut off. The width
* is set from the heading so the long text is chosen, and set_optimize
* then widens further where the data needs it.
  lv_len = strlen( lv_txt ).
  IF lv_len < 10.
    lv_len = 10.
  ELSEIF lv_len > 40.
    lv_len = 40.
  ENDIF.

  TRY.
      lo_col = po_cols->get_column( lv_nam ).
      lo_col->set_short_text( lv_s ).
      lo_col->set_medium_text( lv_m ).
      lo_col->set_long_text( lv_l ).
      lo_col->set_output_length( lv_len ).
    CATCH cx_salv_not_found.
  ENDTRY.

ENDFORM.
