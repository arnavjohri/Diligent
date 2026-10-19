*&---------------------------------------------------------------------*
*& Report         : ZPP_FORECAST_PAINTS_UPL   Transaction: ZFCST_PAINTS_UPL
*& Title          : ZFORECAST (Paints) - product category and brand uploads
*& Project        : KPMG / Astral UDAY            Module: PP
*& Related FS     : Forecast_Template-Paints_1.xlsx (WRICEF ID-2B),
*&                  received 19.10.2026
*& Author         : Arnav Johri                   Date: 19.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   The two uploads the shared ZPP_FORECAST_UPLOAD (ZFCST_UPL) cannot
*&   take for Paints: the product category with the four indicator
*&   values MTS, MTO, DIS and TIN (the Adhesive upload accepts MTS and
*&   MTO only), and the brand per plant and material (ZPPT_BRAND, new).
*&   Tracking, exclusion, legacy history, business forecast and forecast
*&   change for Paints go through ZFCST_UPL as they are.
*&   File handling - Excel, CSV or tab separated text, template download,
*&   test run, row-by-row result list - is the Adhesive upload's, copied,
*&   so the two programs behave the same.
*&
*& CHANGE HISTORY
*&   19.10.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zpp_forecast_paints_upl MESSAGE-ID zpp_fcst.

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

* The indicator values Paints may carry on ZPPT_PROD_CAT-MTS_MTO are
* MTS, MTO, DIS and TIN - see FORM CHECK_INDICATOR.
* ASSUMPTION (query M3): DIS for "Dis Art", TIN for "Tinting", 3
* characters like MTS and MTO so the domain keeps its length. The domain
* ZDO_MTS_MTO lists MTS and MTO as fixed values; the two new codes are
* written by this program regardless, and should be added to the domain
* in SE11 if the category is also to be maintained through SM30.

DATA: gt_raw TYPE STANDARD TABLE OF ty_raw,
      gt_log TYPE STANDARD TABLE OF ty_log,
      g_new  TYPE i,
      g_chg  TYPE i,
      g_err  TYPE i,
      g_tab  TYPE c LENGTH 1,
*     The upload type as a key, so the template layout can be asked for
*     by name
      g_type TYPE char4,
*     Set when the file was read as a workbook. CL_FDT_XL_SPREADSHEET
*     consumes the heading row itself, so the header checkbox must not
*     delete a second row.
      g_xls  TYPE abap_bool.

*&---------------------------------------------------------------------*
SELECTION-SCREEN FUNCTION KEY 1.

* One Download Template button per upload type, on the line of the radio
* button it belongs to. The radio button texts are COMMENT fields,
* because a parameter inside BEGIN OF LINE does not draw its selection
* text; they are filled in INITIALIZATION.
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-b00.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_cat RADIOBUTTON GROUP typ DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(33) c_cat FOR FIELD p_cat.
SELECTION-SCREEN PUSHBUTTON 40(24) b_cat USER-COMMAND tcat.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_brd RADIOBUTTON GROUP typ.
SELECTION-SCREEN COMMENT 3(33) c_brd FOR FIELD p_brd.
SELECTION-SCREEN PUSHBUTTON 40(24) b_brd USER-COMMAND tbrd.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b0.

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

  c_cat = 'Product Category (Paints)'.
  c_brd = 'Brand'.

  b_cat = 'Download Template'.
  b_brd = 'Download Template'.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  PERFORM f4_file.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  CASE sscrfields-ucomm.

*   The application toolbar button serves whichever radio button is
*   selected. The two buttons name their own type.
    WHEN 'FC01'.
      PERFORM current_type CHANGING g_type.
      PERFORM download_template USING g_type.
    WHEN 'TCAT'. PERFORM download_template USING 'CAT'.
    WHEN 'TBRD'. PERFORM download_template USING 'BRD'.

    WHEN 'ONLI'.
      IF p_file IS INITIAL.
        MESSAGE e013 WITH 'no file name entered'.
      ENDIF.

  ENDCASE.

*&---------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR: gt_raw, gt_log, g_new, g_chg, g_err.

  PERFORM upload_file.

  IF gt_raw IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  CASE 'X'.
    WHEN p_cat. PERFORM do_category.
    WHEN p_brd. PERFORM do_brand.
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
FORM current_type CHANGING cv_type TYPE char4.

  CLEAR cv_type.

  CASE 'X'.
    WHEN p_cat. cv_type = 'CAT'.
    WHEN p_brd. cv_type = 'BRD'.
  ENDCASE.

ENDFORM.


*&---------------------------------------------------------------------*
*& Template layout - taken from the dictionary, not typed in here.
*& Each entry is the table and field the column loads. The order is the
*& order of the columns in the file. The heading IS the DDIC label of
*& the field, so a label changed in SE11 changes the template with it.
*&---------------------------------------------------------------------*
FORM template_columns USING pv_type TYPE any
                      CHANGING ct_head TYPE string_table
                               cv_name TYPE string.

  DATA: lt_pre TYPE string_table,
        lv_key TYPE string,
        lv_txt TYPE string.

  CLEAR: ct_head, cv_name.

  CASE pv_type.

    WHEN 'CAT'.
      cv_name = 'ZFCST_Paints_Product_Category'.
      APPEND 'ZPPT_PROD_CAT-WERKS'    TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-MATNR'    TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-PROD_CAT' TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-LOAD_FCT' TO lt_pre.
      APPEND 'ZPPT_PROD_CAT-MTS_MTO'  TO lt_pre.

    WHEN 'BRD'.
      cv_name = 'ZFCST_Paints_Brand'.
      APPEND 'ZPPT_BRAND-WERKS' TO lt_pre.
      APPEND 'ZPPT_BRAND-MATNR' TO lt_pre.
      APPEND 'ZPPT_BRAND-BRAND' TO lt_pre.

    WHEN OTHERS.
      RETURN.

  ENDCASE.

  LOOP AT lt_pre INTO lv_key.
    PERFORM field_label USING lv_key CHANGING lv_txt.
    APPEND lv_txt TO ct_head.
  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& The dictionary label of TABLE-FIELD. Long text first, then medium,
*& then the field text. A key with no dash is used as given.
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

  READ TABLE lt_part TRANSPORTING NO FIELDS INDEX 2.
  IF sy-subrc <> 0.
    cv_txt = pv_key.
    RETURN.
  ENDIF.

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


*&---------------------------------------------------------------------*
* PV_TYPE is TYPE ANY, not TYPE CHAR4: the buttons pass a literal such
* as 'CAT', which is C(3) and not type compatible with a C(4) formal.
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

* One row, the column headings
  PERFORM join_row USING lt_head CHANGING lv_line.
  APPEND lv_line TO lt_out.

* A .csv opens straight into columns, and the upload reads the workbook
* back whether it is saved as .csv or as .xlsx
  CONCATENATE lv_name '.csv' INTO lv_file.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING  default_file_name = lv_file
               default_extension = 'csv'
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
    CONCATENATE 'Template saved to' lv_full
                '- keep row 1 and the column order as they are'
           INTO lv_msg SEPARATED BY space.
    MESSAGE lv_msg TYPE 'S'.
  ELSE.
    MESSAGE e013 WITH lv_full.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Comma separated: a value that itself contains a comma or a quote is
*& wrapped in quotes and its own quotes are doubled
*&---------------------------------------------------------------------*
FORM join_row USING pt_val TYPE string_table
              CHANGING cv_line TYPE string.

  DATA: lv_val TYPE string,
        lv_out TYPE string,
        lv_ix  TYPE i.

  CLEAR cv_line.

  LOOP AT pt_val INTO lv_val.

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
*& Reading the file the user actually has
*&
*&   .XLSX .XLSM .XLS   binary, CL_FDT_XL_SPREADSHEET, first worksheet
*&   .CSV               comma separated, quoted values understood
*&   anything else      tab separated, comma as a fallback
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

* The LAST dot, so a path such as C:\My.Files\brand.xlsx is read right
  SPLIT pv_name AT '.' INTO TABLE lt_part.
  lv_last = lines( lt_part ).
  CHECK lv_last > 1.

  READ TABLE lt_part INTO cv_ext INDEX lv_last.
  CHECK sy-subrc = 0.

  CONDENSE cv_ext.
  cv_ext = to_upper( cv_ext ).

ENDFORM.


*&---------------------------------------------------------------------*
*& A real Excel workbook, read by COLUMN POSITION, never by column name
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

* A workbook in the old .XLS format, or a file renamed to .XLSX that is
* not one, cannot be parsed. The user is told to save it as CSV.
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
*& One line into the sixteen raw columns. SPLIT whenever the line
*& carries no quote; only a quoted line is walked character by character.
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
*     SY-TABIX is copied first - a system field handed straight to a
*     FORM is passed by reference
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
*& The heading row. An Excel upload arrives with the heading already
*& consumed by CL_FDT_XL_SPREADSHEET; a text file is matched against the
*& first heading of the template, and the checkbox is only used for a
*& text file whose first row is something else.
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


*&---------------------------------------------------------------------*
*& 1 - Product category, load factor, indicator (MTS / MTO / DIS / TIN)
*&
*& The Adhesive upload's DO_CATEGORY with one difference: the indicator
*& accepts the four Paints values. Same table, same overwrite-or-insert.
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
    PERFORM check_indicator USING lv_tmp CHANGING lv_mts lv_err.
    IF lv_err IS NOT INITIAL.
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

    lv_txt = 'Product category uploaded'.
    PERFORM log_ok USING lv_row lv_werks lv_matnr lv_blank lv_ex lv_txt.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& The indicator as typed in the file -> the stored code, or an error.
*&
*& MTS, MTO, DIS and TIN are stored as they are. The two long forms the
*& FS header uses, "DIS ART" and "TINTING", are accepted and stored as
*& DIS and TIN, so a user who types the heading's own words is not
*& refused. Anything else is rejected; blank stays blank.
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
*& 2 - Brand per plant and material
*&
*& FS (RADIO BUTTON 1 ANNUAL, row 70): Plant, Material code, Brand into
*& ZPPT_BRAND. Plant and material checked against MARC as every other
*& upload does; an existing plant and material is overwritten, a new one
*& inserted.
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

* The width is set from the heading so the long text is chosen, and
* set_optimize then widens further where the data needs it
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
