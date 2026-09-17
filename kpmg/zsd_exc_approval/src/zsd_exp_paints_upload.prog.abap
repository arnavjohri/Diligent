*&---------------------------------------------------------------------*
*& Report/Include : ZSD_EXP_PAINTS_UPLOAD
*& Title          : Exceptional Approval Paints - Upload and Change
*& Project        : KPMG / UDAY - Astral Limited        Module: SD
*& Related FS     : WRICEF 141.B - Exceptional approval format, Paints
*& Build spec     : BUILD_SPEC_141B.md section 5 (locked contract)
*& Author         : Arnav Johri                         Date: 02.09.2026
*& Transport      : <TR to be filled by Arnav>
*& Ships by       : PASTE (screen-free)
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Mass insert and change of the exceptional approval table
*&   ZSD_EXP_PAINTS from a tab delimited text file, per the FS line
*&   "Data Upload and change report is required for mass data entry".
*&
*&   The program never writes a bad row and never leaves the user
*&   guessing why a row was rejected:
*&     - every validation of build spec 5.3 runs on every row,
*&     - all errors of one row are collected, the row is not abandoned
*&       at the first mistake,
*&     - KNA1, TCURC and the existing table keys are read ONCE for the
*&       whole file, never inside the row loop,
*&     - the database update is one LUW, COMMIT WORK AND WAIT, with a
*&       ROLLBACK WORK and a message to the user when it fails,
*&     - the test run validates and reports without writing anything.
*&
*& SE38 ATTRIBUTES - please check on creation
*&   "Fixed point arithmetic" must be ON. F_CONV_AMOUNT converts the
*&   amount columns of the file into packed fields and needs the
*&   decimal point of the file to be honoured.
*&   "Unicode checks active" must be ON.
*&
*& FILE FORMAT (build spec 5.2)
*&   Tab delimited text, one row per record, optional header line.
*&   Column order, which is also the template column order:
*&     1 ZSRN             Serial number, numeric, up to 10 digits
*&     2 ZCUSTOMER        Customer, with or without leading zeros
*&     3 ZEXC_APPR_MONTH  Approval month, MM-YYYY or MM/YYYY
*&     4 ZEXC_APPR_TYPE   1, 2 or 3
*&     5 ZEXC_DATE_FROM   DD.MM.YYYY or DD/MM/YYYY
*&     6 ZEXC_DATE_TO     DD.MM.YYYY or DD/MM/YYYY
*&     7 ZEXC_AMOUNT      amount, thousand separators allowed
*&     8 ZCOMMIT_DATE     DD.MM.YYYY or DD/MM/YYYY
*&     9 ZEX_AMNT         amount, thousand separators allowed
*&    10 ZCM_AMNT         amount, thousand separators allowed
*&    11 WAERS            currency key
*&    12 ZREMARKS         free text, up to 250 characters
*&   In Excel the file is produced with File -> Save As -> Text (Tab
*&   delimited). An Excel binary is NOT read by this program.
*&
*& JUDGEMENT CALLS - all of them also carry an " ASSUMPTION: note at
*& the place in the code where they act.
*&   - ZEXC_DATE_FROM is mandatory, ZEXC_DATE_TO and ZCOMMIT_DATE are
*&     optional but must parse when they are filled.
*&   - A blank amount column is zero. A NON-BLANK value that does not
*&     parse is a hard error, never a silent zero.
*&   - The currency is mandatory, because all three amount fields of
*&     ZSD_EXP_PAINTS reference WAERS.
*&   - Remarks longer than 250 characters are truncated to the field
*&     length with a note in the log; the row itself stays valid.
*&
*& TEXT ELEMENTS
*&   Every message, heading and label is a text symbol with a literal
*&   default, so the program runs correctly even before Goto -> Text
*&   Elements is maintained. The three selection-screen block titles
*&   (TEXT-001 to TEXT-003) and the selection texts are bare references
*&   and stay blank until they are. The list ships as
*&   ZSD_EXP_PAINTS_UPLOAD_TEXTS.md and inside the abapGit ZIP.
*&
*& SELECTION TEXTS (Goto -> Text Elements -> Selection Texts)
*&   P_FILE  Upload file
*&   P_HEAD  First line is a column header
*&   P_INS   Insert new records only
*&   P_UPD   Insert new and change existing
*&   P_TEST  Test run - validate only, no database update
*&
*& CHANGE HISTORY
*&   02.09.2026  Arnav Johri  <TR>  Initial development
*&   17.09.2026  Arnav Johri  <TR>  No ROLLBACK after COMMIT WORK AND
*&                                  WAIT (rows are already durable, the
*&                                  summary warns instead); amounts with
*&                                  more than two decimals rejected;
*&                                  amount length check counts the
*&                                  decimal point
*&---------------------------------------------------------------------*
REPORT zsd_exp_paints_upload.

* Traffic light constants for the result list (build spec 5.5).
INCLUDE <icon>.

*&---------------------------------------------------------------------*
*& Types
*&---------------------------------------------------------------------*
* The file as it arrives. GUI_UPLOAD with HAS_FIELD_SEPARATOR splits
* the line at the tab character and fills these components from left to
* right, by POSITION - so this component order IS the template column
* order of build spec 5.2. Every component is a flat character field:
* the frontend service fills a flat structure only, and every column is
* deliberately wider than its target field so that a value which is too
* long is REPORTED instead of being silently truncated on the way in.
TYPES: BEGIN OF ty_raw,
         zsrn       TYPE c LENGTH 20,
         zcustomer  TYPE c LENGTH 20,
         zmonth     TYPE c LENGTH 20,
         ztype      TYPE c LENGTH 10,
         zdate_from TYPE c LENGTH 20,
         zdate_to   TYPE c LENGTH 20,
         zexc_amt   TYPE c LENGTH 40,
         zcom_date  TYPE c LENGTH 20,
         zex_amnt   TYPE c LENGTH 40,
         zcm_amnt   TYPE c LENGTH 40,
         zwaers     TYPE c LENGTH 10,
         zremarks   TYPE c LENGTH 500,
       END OF ty_raw.

* One parsed row. The first block carries the field names of
* ZSD_EXP_PAINTS so that f_prepare_update reads as a plain mapping.
* D_SRNO / D_CUST / D_MONTH / D_TYPE are the display values for the
* log: the converted value when the column parsed, the raw input when
* it did not, so the user recognises his own file row.
TYPES: BEGIN OF ty_row,
         rowno           TYPE i,
         zsrn            TYPE zsd_exp_paints-zsrn,
         zcustomer       TYPE zsd_exp_paints-zcustomer,
         zexc_appr_month TYPE zsd_exp_paints-zexc_appr_month,
         zexc_appr_type  TYPE zsd_exp_paints-zexc_appr_type,
         zexc_date_from  TYPE zsd_exp_paints-zexc_date_from,
         zexc_date_to    TYPE zsd_exp_paints-zexc_date_to,
         zexc_amount     TYPE zsd_exp_paints-zexc_amount,
         zcommit_date    TYPE zsd_exp_paints-zcommit_date,
         zex_amnt        TYPE zsd_exp_paints-zex_amnt,
         zcm_amnt        TYPE zsd_exp_paints-zcm_amnt,
         waers           TYPE zsd_exp_paints-waers,
         zremarks        TYPE zsd_exp_paints-zremarks,
         d_srno          TYPE c LENGTH 20,
         d_cust          TYPE c LENGTH 20,
         d_month         TYPE c LENGTH 20,
         d_type          TYPE c LENGTH 10,
         valid           TYPE abap_bool,
         keyok           TYPE abap_bool,
         act             TYPE c LENGTH 1,
         message         TYPE c LENGTH 255,
       END OF ty_row.

* Key of ZSD_EXP_PAINTS without the client. Drives the FOR ALL ENTRIES
* read of the existing records.
TYPES: BEGIN OF ty_key,
         zsrn            TYPE zsd_exp_paints-zsrn,
         zcustomer       TYPE zsd_exp_paints-zcustomer,
         zexc_appr_month TYPE zsd_exp_paints-zexc_appr_month,
       END OF ty_key.

* Same key plus the file row it was first seen on, so that the
* duplicate message can name the earlier row instead of just saying
* that there is one somewhere.
TYPES: BEGIN OF ty_seen,
         zsrn            TYPE zsd_exp_paints-zsrn,
         zcustomer       TYPE zsd_exp_paints-zcustomer,
         zexc_appr_month TYPE zsd_exp_paints-zexc_appr_month,
         rowno           TYPE i,
       END OF ty_seen.

* Existing records. ERNAM and ERDAT are read as well: MODIFY replaces
* the whole row, so the created-by information of a changed record has
* to be carried forward or it would be overwritten with the changer.
TYPES: BEGIN OF ty_db,
         zsrn            TYPE zsd_exp_paints-zsrn,
         zcustomer       TYPE zsd_exp_paints-zcustomer,
         zexc_appr_month TYPE zsd_exp_paints-zexc_appr_month,
         ernam           TYPE zsd_exp_paints-ernam,
         erdat           TYPE zsd_exp_paints-erdat,
       END OF ty_db.

TYPES: BEGIN OF ty_kunnr,
         kunnr TYPE kna1-kunnr,
       END OF ty_kunnr.

TYPES: BEGIN OF ty_waers,
         waers TYPE tcurc-waers,
       END OF ty_waers.

* The result list of build spec 5.5. Every component is flat - the ALV
* output table of REUSE_ALV_GRID_DISPLAY_LVC carries no deep types.
TYPES: BEGIN OF ty_log,
         rowno   TYPE i,
         status  TYPE c LENGTH 4,
         srno    TYPE c LENGTH 20,
         kunnr   TYPE c LENGTH 20,
         month   TYPE c LENGTH 20,
         atype   TYPE c LENGTH 10,
         action  TYPE c LENGTH 14,
         message TYPE c LENGTH 255,
       END OF ty_log.

*&---------------------------------------------------------------------*
*& Constants
*&---------------------------------------------------------------------*
CONSTANTS: gc_digits TYPE string VALUE '0123456789',
           gc_amtchr TYPE string VALUE '0123456789.',
           gc_ins    TYPE c LENGTH 1 VALUE 'I',
           gc_chg    TYPE c LENGTH 1 VALUE 'C',
           gc_rej    TYPE c LENGTH 1 VALUE 'R'.

*&---------------------------------------------------------------------*
*& Global data
*&---------------------------------------------------------------------*
* The three lookup tables are SORTED, so every existence check is a
* keyed read and not a scan, and a duplicate row can never dump the
* SELECT ... INTO TABLE. No SELECT is issued inside a loop anywhere in
* this program.
DATA: gt_raw   TYPE STANDARD TABLE OF ty_raw,
      gt_row   TYPE STANDARD TABLE OF ty_row,
      gt_cust  TYPE STANDARD TABLE OF ty_kunnr,
      gt_curr  TYPE STANDARD TABLE OF ty_waers,
      gt_key   TYPE STANDARD TABLE OF ty_key,
      gt_kna1  TYPE SORTED TABLE OF ty_kunnr
                    WITH NON-UNIQUE KEY kunnr,
      gt_tcurc TYPE SORTED TABLE OF ty_waers
                    WITH NON-UNIQUE KEY waers,
      gt_db    TYPE SORTED TABLE OF ty_db
                    WITH NON-UNIQUE KEY zsrn zcustomer zexc_appr_month,
      gt_upd   TYPE STANDARD TABLE OF zsd_exp_paints,
      gt_log   TYPE STANDARD TABLE OF ty_log.

DATA: g_read    TYPE i,
      g_valid   TYPE i,
      g_writ    TYPE i,
      g_err     TYPE i,
      g_dbfail  TYPE abap_bool,
      g_updfail TYPE abap_bool,               "Changes by Arnav on 17/09/26
      gv_repid  TYPE sy-repid.

*&---------------------------------------------------------------------*
*& Selection screen (build spec 5.1)
*&---------------------------------------------------------------------*
* P_FILE is typed with the dictionary data element LOCALFILE and not
* with STRING: a flat character field is what every other upload report
* on this landscape uses on its selection screen, and the frontend
* services take the string copy made in f_read_file.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS p_file TYPE localfile OBLIGATORY.
PARAMETERS p_head AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS p_ins RADIOBUTTON GROUP md DEFAULT 'X'.
PARAMETERS p_upd RADIOBUTTON GROUP md.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
PARAMETERS p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b3.

*&---------------------------------------------------------------------*
*& Initialization
*&---------------------------------------------------------------------*
INITIALIZATION.

  gv_repid = sy-repid.

*&---------------------------------------------------------------------*
*& F4 help - the file on the presentation server
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  PERFORM f_f4_file.

*&---------------------------------------------------------------------*
*& Main flow
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  gv_repid = sy-repid.

  CLEAR: gt_raw, gt_row, gt_upd, gt_log,
         g_read, g_valid, g_writ, g_err, g_dbfail,
         g_updfail.                             "Changes by Arnav on 17/09/26

  PERFORM f_read_file.
  PERFORM f_parse_rows.
  PERFORM f_read_master_data.
  PERFORM f_validate_rows.
  PERFORM f_prepare_update.
  PERFORM f_update_database.
  PERFORM f_build_log.

END-OF-SELECTION.

  PERFORM f_show_summary.
  PERFORM f_display_log.

*&---------------------------------------------------------------------*
*& Form F_F4_FILE
*&---------------------------------------------------------------------*
*& Value help for the file name. A cancelled dialog leaves the field
*& untouched and is not an error.
*&---------------------------------------------------------------------*
FORM f_f4_file.

  DATA: lt_ftab   TYPE filetable,
        ls_ftab   TYPE file_table,
        lv_rc     TYPE i,
        lv_title  TYPE string,
        lv_filter TYPE string.

  CLEAR: lt_ftab, ls_ftab, lv_rc, lv_title, lv_filter.

  lv_title  = 'Select the upload file'(m08).
  lv_filter = 'Text (*.txt)|*.txt|All files (*.*)|*.*|'.

* Only OTHERS is listed: the individual exception names of the
* frontend services differ between releases and a name that does not
* exist on this one would fail the syntax check.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title   = lv_title
      file_filter    = lv_filter
      multiselection = abap_false
    CHANGING
      file_table     = lt_ftab
      rc             = lv_rc
    EXCEPTIONS
      OTHERS         = 1.

  IF sy-subrc <> 0.
    MESSAGE 'The file dialog could not be opened'(m09)
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF lv_rc > 0.
    READ TABLE lt_ftab INTO ls_ftab INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_ftab-filename.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_READ_FILE
*&---------------------------------------------------------------------*
*& Reads the tab delimited file into GT_RAW. The header line, if the
*& user says there is one, is dropped here so that every later step
*& sees data rows only.
*&---------------------------------------------------------------------*
FORM f_read_file.

  DATA: lv_fname TYPE string,
        lv_msg   TYPE c LENGTH 200.

  CLEAR: gt_raw, lv_fname, lv_msg.

  lv_fname = p_file.

* HAS_FIELD_SEPARATOR splits the line at the tab character and fills
* the components of TY_RAW from left to right.
  CALL METHOD cl_gui_frontend_services=>gui_upload
    EXPORTING
      filename            = lv_fname
      filetype            = 'ASC'
      has_field_separator = abap_true
    CHANGING
      data_tab            = gt_raw
    EXCEPTIONS
      file_open_error     = 1
      file_read_error     = 2
      OTHERS              = 3.

  IF sy-subrc <> 0.
    CLEAR gt_raw.
    lv_msg = 'The upload file could not be read:'(m01).
    CONCATENATE lv_msg p_file INTO lv_msg SEPARATED BY space.
    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF p_head = abap_true AND gt_raw IS NOT INITIAL.
    DELETE gt_raw INDEX 1.
  ENDIF.

  IF gt_raw IS INITIAL.
    MESSAGE 'The upload file contains no data rows'(m02)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_PARSE_ROWS
*&---------------------------------------------------------------------*
*& Converts every file row into a typed row and collects every format
*& error of that row (build spec 5.3 checks 1, 3, 4, 5, 6 and 7).
*& Nothing here needs the database, so a row with a broken date still
*& reaches the existence checks and the user gets all of his mistakes
*& in one run.
*&---------------------------------------------------------------------*
FORM f_parse_rows.

  DATA: ls_raw TYPE ty_raw,
        ls_row TYPE ty_row,
        lv_str TYPE string,
        lv_rem TYPE string,
        lv_c10 TYPE c LENGTH 10,
        lv_len TYPE i,
        lv_ok  TYPE abap_bool,
        lv_idx TYPE i,
        lv_num TYPE c LENGTH 10,
        lv_txt TYPE c LENGTH 255.

  CLEAR: gt_row, g_read, ls_raw, ls_row.

  LOOP AT gt_raw INTO ls_raw.

    lv_idx = sy-tabix.

*   A completely empty line is skipped. A text file routinely ends
*   with one and it is not a mistake the user needs to be told about.
    IF ls_raw IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR: ls_row, lv_str, lv_rem, lv_c10, lv_len, lv_ok,
           lv_num, lv_txt.

*   The row number reported is the line number in the FILE, so the
*   header line is counted when the user said there is one.
    ls_row-rowno = lv_idx.
    IF p_head = abap_true.
      ls_row-rowno = lv_idx + 1.
    ENDIF.

    ls_row-valid = abap_true.
    ls_row-keyok = abap_true.
    g_read = g_read + 1.

*   --- 1. Serial number -------------------------------------------
    lv_str = ls_raw-zsrn.
    CONDENSE lv_str NO-GAPS.
    ls_row-d_srno = lv_str.

    IF lv_str IS INITIAL.
      PERFORM f_add_error USING 'Serial number is missing'(e01)
                          CHANGING ls_row.
      CLEAR ls_row-keyok.
    ELSEIF lv_str CN gc_digits OR strlen( lv_str ) > 10.
      PERFORM f_add_error
              USING 'Serial number must be numeric, up to 10 digits'(e02)
              CHANGING ls_row.
      CLEAR ls_row-keyok.
    ELSE.
      ls_row-zsrn   = lv_str.
      ls_row-d_srno = ls_row-zsrn.
    ENDIF.

*   --- 2. Customer -------------------------------------------------
    lv_str = ls_raw-zcustomer.
    CONDENSE lv_str NO-GAPS.
    TRANSLATE lv_str TO UPPER CASE.
    ls_row-d_cust = lv_str.

    IF lv_str IS INITIAL.
      PERFORM f_add_error USING 'Customer is missing'(e03)
                          CHANGING ls_row.
      CLEAR ls_row-keyok.
    ELSEIF strlen( lv_str ) > 10.
      PERFORM f_add_error
              USING 'Customer number is longer than 10 characters'(e04)
              CHANGING ls_row.
      CLEAR ls_row-keyok.
    ELSE.
*     The file is typed by hand, so 10001 and 0000010001 both have to
*     find the same customer. The ALPHA input conversion is what the
*     dictionary does on a screen field.
      lv_c10 = lv_str.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = lv_c10
        IMPORTING
          output = ls_row-zcustomer.
      ls_row-d_cust = ls_row-zcustomer.
    ENDIF.

*   --- 3. Approval month ------------------------------------------
    lv_str = ls_raw-zmonth.
    CONDENSE lv_str NO-GAPS.
    ls_row-d_month = lv_str.

    IF lv_str IS INITIAL.
      PERFORM f_add_error USING 'Approval month is missing'(e05)
                          CHANGING ls_row.
      CLEAR ls_row-keyok.
    ELSE.
      PERFORM f_conv_month USING lv_str
                           CHANGING ls_row-zexc_appr_month lv_ok.
      IF lv_ok = abap_true.
*       Stored as YYYYMM, shown to the user as MM-YYYY (build spec 3).
        CONCATENATE ls_row-zexc_appr_month+4(2) '-'
                    ls_row-zexc_appr_month(4)
               INTO ls_row-d_month.
      ELSE.
        PERFORM f_add_error
                USING 'Approval month is not in MM-YYYY format'(e06)
                CHANGING ls_row.
        CLEAR ls_row-keyok.
      ENDIF.
    ENDIF.

*   --- 4. Approval type -------------------------------------------
    lv_str = ls_raw-ztype.
    CONDENSE lv_str NO-GAPS.
    ls_row-d_type = lv_str.

    IF lv_str IS INITIAL.
      PERFORM f_add_error USING 'Approval type is missing'(e07)
                          CHANGING ls_row.
    ELSEIF lv_str <> '1' AND lv_str <> '2' AND lv_str <> '3'.
      PERFORM f_add_error USING 'Approval type must be 1, 2 or 3'(e08)
                          CHANGING ls_row.
    ELSE.
      ls_row-zexc_appr_type = lv_str.
    ENDIF.

*   --- 5. Approval date from --------------------------------------
    lv_str = ls_raw-zdate_from.
    CONDENSE lv_str NO-GAPS.

    IF lv_str IS INITIAL.
* ASSUMPTION: the approval date from is treated as mandatory. The
* output report ZSD_EXC_APPR_PAINTS selects on ZEXC_DATE_FROM, so a
* record loaded without one would never appear in any list.
      PERFORM f_add_error USING 'Approval date from is missing'(e09)
                          CHANGING ls_row.
    ELSE.
      PERFORM f_conv_date USING lv_str
                          CHANGING ls_row-zexc_date_from lv_ok.
      IF lv_ok <> abap_true.
        PERFORM f_add_error
                USING 'Approval date from is not a valid date'(e10)
                CHANGING ls_row.
      ENDIF.
    ENDIF.

*   --- 6. Approval date to ----------------------------------------
* ASSUMPTION: an empty date to and an empty commitment date are
* accepted and stored as an initial date. The FS makes neither
* mandatory and the output report is built to treat an initial
* commitment date as "no status yet" (build spec 6.3 form 9), which it
* could not do if this program refused to load one.
    lv_str = ls_raw-zdate_to.
    CONDENSE lv_str NO-GAPS.

    IF lv_str IS NOT INITIAL.
      PERFORM f_conv_date USING lv_str
                          CHANGING ls_row-zexc_date_to lv_ok.
      IF lv_ok <> abap_true.
        PERFORM f_add_error
                USING 'Approval date to is not a valid date'(e11)
                CHANGING ls_row.
      ENDIF.
    ENDIF.

    IF ls_row-zexc_date_from IS NOT INITIAL AND
       ls_row-zexc_date_to   IS NOT INITIAL AND
       ls_row-zexc_date_to   <  ls_row-zexc_date_from.
      PERFORM f_add_error
              USING 'Approval date to is before approval date from'(e12)
              CHANGING ls_row.
    ENDIF.

*   --- 7. Commitment date -----------------------------------------
    lv_str = ls_raw-zcom_date.
    CONDENSE lv_str NO-GAPS.

    IF lv_str IS NOT INITIAL.
      PERFORM f_conv_date USING lv_str
                          CHANGING ls_row-zcommit_date lv_ok.
      IF lv_ok <> abap_true.
        PERFORM f_add_error
                USING 'Commitment date is not a valid date'(e13)
                CHANGING ls_row.
      ENDIF.
    ENDIF.

*   --- 8. Amounts --------------------------------------------------
*   A non numeric amount is an error, never a silent zero. An empty
*   amount column is zero (build spec 5.3 point 7).
    PERFORM f_conv_amount USING ls_raw-zexc_amt
                          CHANGING ls_row-zexc_amount lv_ok.
    IF lv_ok <> abap_true.
      PERFORM f_add_error
              USING 'Exceptional amount is not a valid number'(e14)
              CHANGING ls_row.
    ENDIF.

    PERFORM f_conv_amount USING ls_raw-zex_amnt
                          CHANGING ls_row-zex_amnt lv_ok.
    IF lv_ok <> abap_true.
      PERFORM f_add_error
              USING 'Exceptional approval amount is not a number'(e15)
              CHANGING ls_row.
    ENDIF.

    PERFORM f_conv_amount USING ls_raw-zcm_amnt
                          CHANGING ls_row-zcm_amnt lv_ok.
    IF lv_ok <> abap_true.
      PERFORM f_add_error
              USING 'Collection commitment amount is not a number'(e16)
              CHANGING ls_row.
    ENDIF.

*   --- 9. Currency -------------------------------------------------
    lv_str = ls_raw-zwaers.
    CONDENSE lv_str NO-GAPS.
    TRANSLATE lv_str TO UPPER CASE.

    IF lv_str IS INITIAL.
* ASSUMPTION: the currency is mandatory. All three amount fields of
* ZSD_EXP_PAINTS reference WAERS, so an amount without a currency key
* has no defined meaning.
      PERFORM f_add_error USING 'Currency is missing'(e17)
                          CHANGING ls_row.
    ELSEIF strlen( lv_str ) > 5.
      PERFORM f_add_error
              USING 'Currency key is longer than 5 characters'(e18)
              CHANGING ls_row.
    ELSE.
      ls_row-waers = lv_str.
    ENDIF.

*   --- 10. Remarks -------------------------------------------------
*   ZREMARKS is CHAR 250. A longer text is loaded truncated rather
*   than rejected - but the user is told, because a silent truncation
*   is exactly the kind of quiet data loss the log exists to prevent.
    lv_rem = ls_raw-zremarks.
    lv_len = strlen( lv_rem ).

    IF lv_len > 250.
      lv_num = lv_len.
      CONDENSE lv_num.
      CONCATENATE 'Remarks truncated to 250 characters, file length'(e19)
                  lv_num
             INTO lv_txt SEPARATED BY space.
      PERFORM f_add_note USING lv_txt CHANGING ls_row.
    ENDIF.

    ls_row-zremarks = ls_raw-zremarks.

    APPEND ls_row TO gt_row.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_READ_MASTER_DATA
*&---------------------------------------------------------------------*
*& One read per check table for the WHOLE file (build spec 5.3 points
*& 2, 8 and 10). Nothing in this program reads the database per row.
*&---------------------------------------------------------------------*
FORM f_read_master_data.

  DATA: ls_row  TYPE ty_row,
        ls_cust TYPE ty_kunnr,
        ls_curr TYPE ty_waers,
        ls_key  TYPE ty_key.

  CLEAR: gt_cust, gt_curr, gt_key, gt_kna1, gt_tcurc, gt_db.

  LOOP AT gt_row INTO ls_row.

    IF ls_row-zcustomer IS NOT INITIAL.
      CLEAR ls_cust.
      ls_cust-kunnr = ls_row-zcustomer.
      APPEND ls_cust TO gt_cust.
    ENDIF.

    IF ls_row-waers IS NOT INITIAL.
      CLEAR ls_curr.
      ls_curr-waers = ls_row-waers.
      APPEND ls_curr TO gt_curr.
    ENDIF.

*   Only a row whose three key fields parsed can be looked up.
    IF ls_row-keyok = abap_true.
      CLEAR ls_key.
      ls_key-zsrn            = ls_row-zsrn.
      ls_key-zcustomer       = ls_row-zcustomer.
      ls_key-zexc_appr_month = ls_row-zexc_appr_month.
      APPEND ls_key TO gt_key.
    ENDIF.

  ENDLOOP.

* Sorted and deduplicated OUTSIDE the loop, so each FOR ALL ENTRIES
* driver carries every value exactly once.
  SORT gt_cust BY kunnr.
  DELETE ADJACENT DUPLICATES FROM gt_cust COMPARING kunnr.

  SORT gt_curr BY waers.
  DELETE ADJACENT DUPLICATES FROM gt_curr COMPARING waers.

  SORT gt_key BY zsrn zcustomer zexc_appr_month.
  DELETE ADJACENT DUPLICATES FROM gt_key
         COMPARING zsrn zcustomer zexc_appr_month.

  IF gt_cust IS NOT INITIAL.
    SELECT kunnr
      FROM kna1
      FOR ALL ENTRIES IN @gt_cust
      WHERE kunnr = @gt_cust-kunnr
      INTO TABLE @gt_kna1.

    IF sy-subrc <> 0.
      CLEAR gt_kna1.
    ENDIF.
  ENDIF.

  IF gt_curr IS NOT INITIAL.
    SELECT waers
      FROM tcurc
      FOR ALL ENTRIES IN @gt_curr
      WHERE waers = @gt_curr-waers
      INTO TABLE @gt_tcurc.

    IF sy-subrc <> 0.
      CLEAR gt_tcurc.
    ENDIF.
  ENDIF.

  IF gt_key IS NOT INITIAL.
*   The field list matches TY_DB component for component. Strict Open
*   SQL fills the target by POSITION, not by name.
    SELECT zsrn, zcustomer, zexc_appr_month, ernam, erdat
      FROM zsd_exp_paints
      FOR ALL ENTRIES IN @gt_key
      WHERE zsrn            = @gt_key-zsrn
        AND zcustomer       = @gt_key-zcustomer
        AND zexc_appr_month = @gt_key-zexc_appr_month
      INTO TABLE @gt_db.

    IF sy-subrc <> 0.
      CLEAR gt_db.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_VALIDATE_ROWS
*&---------------------------------------------------------------------*
*& The checks that need the data read in f_read_master_data (build spec
*& 5.3 points 2, 8 and 10), plus the duplicate check inside the file
*& (point 9) and the insert / change decision.
*&---------------------------------------------------------------------*
FORM f_validate_rows.

  DATA: ls_row  TYPE ty_row,
        ls_seen TYPE ty_seen,
        ls_hit  TYPE ty_seen,
        lv_idx  TYPE i,
        lv_num  TYPE c LENGTH 10,
        lv_txt  TYPE c LENGTH 255,
        lt_seen TYPE SORTED TABLE OF ty_seen
                     WITH UNIQUE KEY zsrn zcustomer zexc_appr_month.

  CLEAR: g_valid, g_err, lt_seen.

  LOOP AT gt_row INTO ls_row.

    lv_idx = sy-tabix.

    CLEAR: ls_seen, ls_hit, lv_num, lv_txt.

*   --- customer exists ---------------------------------------------
    IF ls_row-zcustomer IS NOT INITIAL.
      READ TABLE gt_kna1 TRANSPORTING NO FIELDS
           WITH TABLE KEY kunnr = ls_row-zcustomer.
      IF sy-subrc <> 0.
        PERFORM f_add_error USING 'Customer does not exist in KNA1'(e20)
                            CHANGING ls_row.
      ENDIF.
    ENDIF.

*   --- currency exists ---------------------------------------------
    IF ls_row-waers IS NOT INITIAL.
      READ TABLE gt_tcurc TRANSPORTING NO FIELDS
           WITH TABLE KEY waers = ls_row-waers.
      IF sy-subrc <> 0.
        PERFORM f_add_error USING 'Currency does not exist in TCURC'(e21)
                            CHANGING ls_row.
      ENDIF.
    ENDIF.

    IF ls_row-keyok = abap_true.

*     --- the same key twice in one file ----------------------------
*     The second and every later occurrence is the error, the first
*     one is kept and is named in the message (build spec 5.3 point 9).
      READ TABLE lt_seen INTO ls_hit
           WITH TABLE KEY zsrn            = ls_row-zsrn
                          zcustomer       = ls_row-zcustomer
                          zexc_appr_month = ls_row-zexc_appr_month.

      IF sy-subrc = 0.
        lv_num = ls_hit-rowno.
        CONDENSE lv_num.
        CONCATENATE 'The same key is already used in file row'(e22)
                    lv_num
               INTO lv_txt SEPARATED BY space.
        PERFORM f_add_error USING lv_txt CHANGING ls_row.
      ELSE.

        ls_seen-zsrn            = ls_row-zsrn.
        ls_seen-zcustomer       = ls_row-zcustomer.
        ls_seen-zexc_appr_month = ls_row-zexc_appr_month.
        ls_seen-rowno           = ls_row-rowno.
        INSERT ls_seen INTO TABLE lt_seen.

*       --- already on the database ---------------------------------
        READ TABLE gt_db TRANSPORTING NO FIELDS
             WITH TABLE KEY zsrn            = ls_row-zsrn
                            zcustomer       = ls_row-zcustomer
                            zexc_appr_month = ls_row-zexc_appr_month.

        IF sy-subrc = 0.
          IF p_ins = abap_true.
            PERFORM f_add_error
                    USING 'Record exists already - use the change mode'(e23)
                    CHANGING ls_row.
          ELSE.
            ls_row-act = gc_chg.
          ENDIF.
        ELSE.
          ls_row-act = gc_ins.
        ENDIF.

      ENDIF.

    ENDIF.

    IF ls_row-valid = abap_true.
      g_valid = g_valid + 1.
    ELSE.
      g_err      = g_err + 1.
      ls_row-act = gc_rej.
    ENDIF.

    MODIFY gt_row FROM ls_row INDEX lv_idx.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_PREPARE_UPDATE
*&---------------------------------------------------------------------*
*& Builds the database image of the valid rows. An invalid row never
*& reaches GT_UPD and therefore can never be written. The mapping is
*& written out field by field on purpose: a wrong dictionary name then
*& fails the syntax check here instead of quietly moving nothing.
*&---------------------------------------------------------------------*
FORM f_prepare_update.

  DATA: ls_row TYPE ty_row,
        ls_tab TYPE zsd_exp_paints,
        ls_db  TYPE ty_db.

  CLEAR: gt_upd, ls_row, ls_tab, ls_db.

  LOOP AT gt_row INTO ls_row.

    IF ls_row-valid <> abap_true.
      CONTINUE.
    ENDIF.

    CLEAR: ls_tab, ls_db.

*   The client column is deliberately not filled: with automatic
*   client handling MODIFY writes the logon client.
    ls_tab-zsrn            = ls_row-zsrn.
    ls_tab-zcustomer       = ls_row-zcustomer.
    ls_tab-zexc_appr_month = ls_row-zexc_appr_month.
    ls_tab-zexc_appr_type  = ls_row-zexc_appr_type.
    ls_tab-zexc_date_from  = ls_row-zexc_date_from.
    ls_tab-zexc_date_to    = ls_row-zexc_date_to.
    ls_tab-zexc_amount     = ls_row-zexc_amount.
    ls_tab-zcommit_date    = ls_row-zcommit_date.
    ls_tab-zex_amnt        = ls_row-zex_amnt.
    ls_tab-zcm_amnt        = ls_row-zcm_amnt.
    ls_tab-zremarks        = ls_row-zremarks.
    ls_tab-waers           = ls_row-waers.

    READ TABLE gt_db INTO ls_db
         WITH TABLE KEY zsrn            = ls_row-zsrn
                        zcustomer       = ls_row-zcustomer
                        zexc_appr_month = ls_row-zexc_appr_month.

    IF sy-subrc = 0.
*     A change. MODIFY replaces the whole row, so the created-by data
*     is carried over instead of being overwritten with the changer.
      ls_tab-ernam = ls_db-ernam.
      ls_tab-erdat = ls_db-erdat.
      ls_tab-aenam = sy-uname.
      ls_tab-aedat = sy-datum.
    ELSE.
      ls_tab-ernam = sy-uname.
      ls_tab-erdat = sy-datum.
      CLEAR: ls_tab-aenam,
             ls_tab-aedat.
    ENDIF.

    APPEND ls_tab TO gt_upd.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_UPDATE_DATABASE
*&---------------------------------------------------------------------*
*& One LUW for the whole file: either every valid row is on the
*& database or none of them is (build spec 5.4). Nothing is written on
*& a test run.
*&---------------------------------------------------------------------*
FORM f_update_database.

  CLEAR: g_writ, g_dbfail.

  IF p_test = abap_true.
    RETURN.
  ENDIF.

  IF gt_upd IS INITIAL.
    RETURN.
  ENDIF.

  MODIFY zsd_exp_paints FROM TABLE @gt_upd.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    g_dbfail = abap_true.
    RETURN.
  ENDIF.

  COMMIT WORK AND WAIT.

*BOC By Arnav on 17/09/26
* A non-zero SY-SUBRC after COMMIT WORK AND WAIT means an update task
* registered in this LUW failed. The direct MODIFY above was already
* made durable by the commit itself, and no ROLLBACK WORK can take it
* back - so the rows ARE on the database. The run is flagged and the
* summary points the user at SM13 instead of claiming a rollback that
* never happened.
*  IF sy-subrc <> 0.
*    ROLLBACK WORK.
*    g_dbfail = abap_true.
*    RETURN.
*  ENDIF.
  IF sy-subrc <> 0.
    g_updfail = abap_true.
  ENDIF.
*EOC By Arnav on 17/09/26

  g_writ = lines( gt_upd ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_BUILD_LOG
*&---------------------------------------------------------------------*
*& One log line per file row, built AFTER the update so that it states
*& what actually happened and not what was intended (build spec 5.5).
*&---------------------------------------------------------------------*
FORM f_build_log.

  DATA: ls_row TYPE ty_row,
        ls_log TYPE ty_log,
        lv_txt TYPE c LENGTH 255,
        lv_msg TYPE string.

  CLEAR: gt_log, ls_row, ls_log.

  LOOP AT gt_row INTO ls_row.

    CLEAR: ls_log, lv_txt, lv_msg.

    ls_log-rowno = ls_row-rowno.
    ls_log-srno  = ls_row-d_srno.
    ls_log-kunnr = ls_row-d_cust.
    ls_log-month = ls_row-d_month.
    ls_log-atype = ls_row-d_type.

    IF ls_row-valid <> abap_true.

*     The collected errors are the message - nothing is appended to
*     them, so the user reads only what he has to fix.
      ls_log-status  = icon_red_light.
      ls_log-action  = 'Rejected'(a05).
      ls_log-message = ls_row-message.

    ELSE.

      IF g_dbfail = abap_true.
        ls_log-status = icon_red_light.
        ls_log-action = 'Not written'(a06).
        lv_txt =
          'The database update failed, the row was rolled back'(m03).
      ELSEIF p_test = abap_true.
        ls_log-status = icon_green_light.
        IF ls_row-act = gc_chg.
          ls_log-action = 'Would change'(a03).
        ELSE.
          ls_log-action = 'Would insert'(a04).
        ENDIF.
        lv_txt = 'Test run - the row is valid, nothing written'(m05).
      ELSE.
        ls_log-status = icon_green_light.
        IF ls_row-act = gc_chg.
          ls_log-action = 'Changed'(a02).
        ELSE.
          ls_log-action = 'Inserted'(a01).
        ENDIF.
        lv_txt = 'The row was written to the database'(m04).
      ENDIF.

*     A valid row can still carry a note - a truncated remark, for
*     example. The note is kept beside the outcome, never replaced by
*     it.
      IF ls_row-message IS INITIAL.
        ls_log-message = lv_txt.
      ELSE.
        lv_msg = |{ lv_txt }; { ls_row-message }|.
        ls_log-message = lv_msg.
      ENDIF.

    ENDIF.

    APPEND ls_log TO gt_log.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_SHOW_SUMMARY
*&---------------------------------------------------------------------*
*& The closing counts of build spec 5.5: read, valid, written, in
*& error, and a plain statement when it was a test run. Issued before
*& the list is built so that it stands in the status bar of the result
*& list.
*&---------------------------------------------------------------------*
FORM f_show_summary.

  DATA: lv_msg  TYPE c LENGTH 200,
        lv_read TYPE c LENGTH 10,
        lv_val  TYPE c LENGTH 10,
        lv_wri  TYPE c LENGTH 10,
        lv_err  TYPE c LENGTH 10.

  CLEAR: lv_msg, lv_read, lv_val, lv_wri, lv_err.

  lv_read = g_read.
  lv_val  = g_valid.
  lv_wri  = g_writ.
  lv_err  = g_err.
  CONDENSE lv_read.
  CONDENSE lv_val.
  CONDENSE lv_wri.
  CONDENSE lv_err.

  CONCATENATE 'Rows read:'(t01) lv_read
              'valid:'(t02)     lv_val
              'written:'(t03)   lv_wri
              'in error:'(t04)  lv_err
         INTO lv_msg SEPARATED BY space.

  IF g_dbfail = abap_true.
    CONCATENATE lv_msg
                'DATABASE UPDATE FAILED - nothing was written'(t06)
           INTO lv_msg SEPARATED BY space.
    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
  ELSEIF p_test = abap_true.
    CONCATENATE lv_msg
                'TEST RUN - nothing was written'(t05)
           INTO lv_msg SEPARATED BY space.
    MESSAGE lv_msg TYPE 'S'.
  ELSE.
*BOC By Arnav on 17/09/26
*    MESSAGE lv_msg TYPE 'S'.
    IF g_updfail = abap_true.
      CONCATENATE lv_msg
                  'Rows saved, but a follow-on update failed - see SM13'(m06)
             INTO lv_msg SEPARATED BY space.
      MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'W'.
    ELSE.
      MESSAGE lv_msg TYPE 'S'.
    ENDIF.
*EOC By Arnav on 17/09/26
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_DISPLAY_LOG
*&---------------------------------------------------------------------*
*& Hand built LVC field catalogue and full screen grid display of the
*& upload log (build spec 5.5).
*&---------------------------------------------------------------------*
FORM f_display_log.

  DATA: lt_fcat    TYPE lvc_t_fcat,
        ls_layout  TYPE lvc_s_layo,
        ls_variant TYPE disvariant.

  CLEAR: lt_fcat, ls_layout, ls_variant.

  IF gt_log IS INITIAL.
    MESSAGE 'The upload file contains no data rows'(m02)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* Column order follows TY_LOG. The fourth argument is the currency
* reference field, the fifth the "do not display" flag and the sixth
* the icon flag.
  PERFORM f_add_fcat USING  1 'ROWNO'   'File Row'(c01)
                              space space space CHANGING lt_fcat.
  PERFORM f_add_fcat USING  2 'STATUS'  'Status'(c02)
                              space space 'X'   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  3 'SRNO'    'Sr. No.'(c03)
                              space space space CHANGING lt_fcat.
  PERFORM f_add_fcat USING  4 'KUNNR'   'Customer'(c04)
                              space space space CHANGING lt_fcat.
  PERFORM f_add_fcat USING  5 'MONTH'   'Approval Month'(c05)
                              space space space CHANGING lt_fcat.
  PERFORM f_add_fcat USING  6 'ATYPE'   'Approval Type'(c08)
                              space space space CHANGING lt_fcat.
  PERFORM f_add_fcat USING  7 'ACTION'  'Result'(c06)
                              space space space CHANGING lt_fcat.
  PERFORM f_add_fcat USING  8 'MESSAGE' 'Message'(c07)
                              space space space CHANGING lt_fcat.

  ls_layout-zebra      = abap_true.
  ls_layout-cwidth_opt = abap_true.

* IS_VARIANT must carry the report name for I_SAVE = 'A' to be able to
* store a layout.
  ls_variant-report = gv_repid.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program = gv_repid
      is_layout_lvc      = ls_layout
      it_fieldcat_lvc    = lt_fcat
      i_save             = 'A'
      is_variant         = ls_variant
    TABLES
      t_outtab           = gt_log
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE 'The result list could not be displayed'(m07)
            TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_ADD_FCAT
*&---------------------------------------------------------------------*
*& Builds one LVC_S_FCAT entry so that f_display_log stays a readable
*& list of column definitions. The parameters are typed generically
*& (CLIKE) so that literals, text symbols and SPACE can all be passed.
*&---------------------------------------------------------------------*
FORM f_add_fcat  USING    iv_pos   TYPE i
                          iv_field TYPE clike
                          iv_text  TYPE clike
                          iv_curr  TYPE clike
                          iv_noout TYPE clike
                          iv_icon  TYPE clike
                 CHANGING ct_fcat  TYPE lvc_t_fcat.

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR ls_fcat.

  ls_fcat-col_pos   = iv_pos.
  ls_fcat-fieldname = iv_field.
  ls_fcat-scrtext_l = iv_text.
  ls_fcat-scrtext_m = iv_text.
  ls_fcat-scrtext_s = iv_text.
  ls_fcat-reptext   = iv_text.

  IF iv_curr IS NOT INITIAL.
    ls_fcat-cfieldname = iv_curr.
  ENDIF.

  IF iv_noout = abap_true.
    ls_fcat-no_out = abap_true.
  ENDIF.

* The status column carries the traffic light of build spec 5.5, so it
* is flagged as an icon column and centred.
  IF iv_icon = abap_true.
    ls_fcat-icon = abap_true.
    ls_fcat-just = 'C'.
  ENDIF.

  APPEND ls_fcat TO ct_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_ADD_NOTE
*&---------------------------------------------------------------------*
*& Adds one more remark to a row WITHOUT rejecting it. Used for things
*& the user has to know about but that do not make the row unusable.
*&---------------------------------------------------------------------*
FORM f_add_note  USING    iv_text TYPE clike
                 CHANGING cs_row  TYPE ty_row.

  DATA lv_msg TYPE string.

  CLEAR lv_msg.

* The separator is written inside a string template because
* CONCATENATE ... SEPARATED BY drops the trailing blank of a '; '
* literal and the messages would run into each other.
  IF cs_row-message IS INITIAL.
    cs_row-message = iv_text.
  ELSE.
    lv_msg = |{ cs_row-message }; { iv_text }|.
    cs_row-message = lv_msg.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_ADD_ERROR
*&---------------------------------------------------------------------*
*& Collects one more error on a row. The row is marked invalid but is
*& NOT abandoned - the remaining checks still run, so the user sees
*& everything that is wrong with the row in a single upload.
*&---------------------------------------------------------------------*
FORM f_add_error USING    iv_text TYPE clike
                 CHANGING cs_row  TYPE ty_row.

  cs_row-valid = abap_false.

  PERFORM f_add_note USING iv_text CHANGING cs_row.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CONV_DATE
*&---------------------------------------------------------------------*
*& DD.MM.YYYY or DD/MM/YYYY to an internal date. CV_OK stays initial
*& when the value is not a calendar date. An EMPTY input is reported
*& as converted with an initial date - whether an empty date is
*& allowed is decided by the caller, not here.
*&---------------------------------------------------------------------*
FORM f_conv_date USING    iv_in   TYPE clike
                 CHANGING cv_date TYPE d
                          cv_ok   TYPE abap_bool.

  DATA: lv_str  TYPE string,
        lv_d    TYPE string,
        lv_m    TYPE string,
        lv_y    TYPE string,
        lv_day  TYPE i,
        lv_mon  TYPE i,
        lv_year TYPE i,
        lv_max  TYPE i,
        lv_nd   TYPE n LENGTH 2,
        lv_nm   TYPE n LENGTH 2,
        lv_ny   TYPE n LENGTH 4,
        lv_dat  TYPE c LENGTH 8.

  CLEAR: cv_date, cv_ok, lv_str, lv_d, lv_m, lv_y,
         lv_day, lv_mon, lv_year, lv_max,
         lv_nd, lv_nm, lv_ny, lv_dat.

  lv_str = iv_in.
  CONDENSE lv_str NO-GAPS.

  IF lv_str IS INITIAL.
    cv_ok = abap_true.
    RETURN.
  ENDIF.

* A slash is accepted as the separator as well as a full stop.
  REPLACE ALL OCCURRENCES OF '/' IN lv_str WITH '.'.

  SPLIT lv_str AT '.' INTO lv_d lv_m lv_y.

  IF lv_d IS INITIAL OR lv_m IS INITIAL OR lv_y IS INITIAL.
    RETURN.
  ENDIF.

  IF lv_d CN gc_digits OR lv_m CN gc_digits OR lv_y CN gc_digits.
    RETURN.
  ENDIF.

  IF strlen( lv_d ) > 2 OR strlen( lv_m ) > 2 OR strlen( lv_y ) <> 4.
    RETURN.
  ENDIF.

  lv_day  = lv_d.
  lv_mon  = lv_m.
  lv_year = lv_y.

  IF lv_year < 1900 OR lv_year > 9999.
    RETURN.
  ENDIF.

  IF lv_mon < 1 OR lv_mon > 12.
    RETURN.
  ENDIF.

  PERFORM f_days_in_month USING lv_year lv_mon CHANGING lv_max.

  IF lv_day < 1 OR lv_day > lv_max.
    RETURN.
  ENDIF.

  lv_nd = lv_day.
  lv_nm = lv_mon.
  lv_ny = lv_year.

  CONCATENATE lv_ny lv_nm lv_nd INTO lv_dat.

  cv_date = lv_dat.
  cv_ok   = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CONV_MONTH
*&---------------------------------------------------------------------*
*& MM-YYYY or MM/YYYY to the stored YYYYMM. Stored as YYYYMM so that
*& the field sorts and compares correctly; MM-YYYY is a display form
*& only and is never written to the table (build spec 3).
*&---------------------------------------------------------------------*
FORM f_conv_month USING    iv_in    TYPE clike
                  CHANGING cv_month TYPE n
                           cv_ok    TYPE abap_bool.

  DATA: lv_str  TYPE string,
        lv_m    TYPE string,
        lv_y    TYPE string,
        lv_mon  TYPE i,
        lv_year TYPE i,
        lv_nm   TYPE n LENGTH 2,
        lv_ny   TYPE n LENGTH 4,
        lv_c6   TYPE c LENGTH 6.

  CLEAR: cv_month, cv_ok, lv_str, lv_m, lv_y, lv_mon, lv_year,
         lv_nm, lv_ny, lv_c6.

  lv_str = iv_in.
  CONDENSE lv_str NO-GAPS.

  IF lv_str IS INITIAL.
    RETURN.
  ENDIF.

* A slash is accepted as the separator as well as a hyphen.
  REPLACE ALL OCCURRENCES OF '/' IN lv_str WITH '-'.

  SPLIT lv_str AT '-' INTO lv_m lv_y.

  IF lv_m IS INITIAL OR lv_y IS INITIAL.
    RETURN.
  ENDIF.

  IF lv_m CN gc_digits OR lv_y CN gc_digits.
    RETURN.
  ENDIF.

  IF strlen( lv_m ) > 2 OR strlen( lv_y ) <> 4.
    RETURN.
  ENDIF.

  lv_mon  = lv_m.
  lv_year = lv_y.

  IF lv_mon < 1 OR lv_mon > 12.
    RETURN.
  ENDIF.

  IF lv_year < 1900 OR lv_year > 9999.
    RETURN.
  ENDIF.

  lv_nm = lv_mon.
  lv_ny = lv_year.

  CONCATENATE lv_ny lv_nm INTO lv_c6.

  cv_month = lv_c6.
  cv_ok    = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CONV_AMOUNT
*&---------------------------------------------------------------------*
*& File amount to a packed amount. Thousand separators are stripped, a
*& leading or trailing sign is honoured, and anything that is not a
*& number is REPORTED - it is never turned into a silent zero. An
*& empty amount column is zero.
*&---------------------------------------------------------------------*
FORM f_conv_amount USING    iv_in  TYPE clike
                   CHANGING cv_amt TYPE p
                            cv_ok  TYPE abap_bool.

  DATA: lv_str  TYPE string,
        lv_tmp  TYPE string,
        lv_rest TYPE string,
        lv_sign TYPE c LENGTH 1,
        lv_len  TYPE i,
        lv_off  TYPE i,
        lv_dot  TYPE i,
        lv_p    TYPE p LENGTH 12 DECIMALS 2.

  CLEAR: cv_amt, cv_ok, lv_str, lv_tmp, lv_rest, lv_sign,
         lv_len, lv_off, lv_dot, lv_p.

  lv_str = iv_in.
  CONDENSE lv_str NO-GAPS.

  IF lv_str IS INITIAL.
    cv_ok = abap_true.
    RETURN.
  ENDIF.

* A comma AFTER the decimal point means the file was written with the
* continental notation 1.234,56. Stripping the commas would turn that
* into 1.23456 and load a wrong amount without anybody noticing, so
* the value is reported as not a number instead.
  SPLIT lv_str AT '.' INTO lv_tmp lv_rest.

  IF lv_rest CS ','.
    RETURN.
  ENDIF.

  CLEAR: lv_tmp, lv_rest.

* Both the 125,000.00 and the 1,25,000.00 grouping are handled by
* removing every comma before the conversion.
  REPLACE ALL OCCURRENCES OF ',' IN lv_str WITH ''.

  lv_len = strlen( lv_str ).

  IF lv_len = 0.
    RETURN.
  ENDIF.

  IF lv_len > 1.
    lv_off = lv_len - 1.
*   A trailing minus is how SAP and Excel both write a negative value.
    IF lv_str+lv_off(1) = '-'.
      lv_sign = '-'.
      lv_tmp  = lv_str(lv_off).
      lv_str  = lv_tmp.
    ELSEIF lv_str(1) = '-'.
      lv_sign = '-'.
      lv_tmp  = lv_str+1(lv_off).
      lv_str  = lv_tmp.
    ELSEIF lv_str(1) = '+'.
      lv_tmp = lv_str+1(lv_off).
      lv_str = lv_tmp.
    ENDIF.
  ENDIF.

  IF lv_str IS INITIAL.
    RETURN.
  ENDIF.

* Only digits and at most one decimal point may be left.
  IF lv_str CN gc_amtchr.
    RETURN.
  ENDIF.

  FIND ALL OCCURRENCES OF '.' IN lv_str MATCH COUNT lv_dot.

  IF lv_dot > 1.
    RETURN.
  ENDIF.

*BOC By Arnav on 17/09/26
* The target holds 23 digits including the two decimals, and the string
* still carries its decimal point, so 24 characters is the longest
* value that can fit. Anything longer is reported rather than allowed
* to overflow; the TRY below catches whatever still does not fit.
*  IF strlen( lv_str ) > 23.
*    RETURN.
*  ENDIF.
  IF strlen( lv_str ) > 24.
    RETURN.
  ENDIF.

* More than two decimal places would be rounded silently on the way
* into the CURR 23,2 field - 100.567 would load as 100.57 with nothing
* in the log. It is reported as not a number instead (build spec 5.3
* point 7: never a silent change of the value).
  SPLIT lv_str AT '.' INTO lv_tmp lv_rest.
  IF strlen( lv_rest ) > 2.
    RETURN.
  ENDIF.
  CLEAR: lv_tmp, lv_rest.
*EOC By Arnav on 17/09/26

* A value that still overflows the packed field - 23 integer digits,
* say - is caught here and reported as not a number rather than
* dumping the whole upload.
  TRY.
      lv_p = lv_str.
    CATCH cx_sy_conversion_error.
      RETURN.
  ENDTRY.

  IF lv_sign = '-'.
    lv_p = lv_p * -1.
  ENDIF.

  cv_amt = lv_p.
  cv_ok  = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_DAYS_IN_MONTH
*&---------------------------------------------------------------------*
*& Length of the month, leap years included. Kept in the program so
*& that the date check does not depend on a function module whose
*& interface cannot be verified on this landscape.
*&---------------------------------------------------------------------*
FORM f_days_in_month USING    iv_year TYPE i
                              iv_mon  TYPE i
                     CHANGING cv_days TYPE i.

  DATA: lv_r4   TYPE i,
        lv_r100 TYPE i,
        lv_r400 TYPE i.

  CLEAR: cv_days, lv_r4, lv_r100, lv_r400.

  CASE iv_mon.
    WHEN 1 OR 3 OR 5 OR 7 OR 8 OR 10 OR 12.
      cv_days = 31.
    WHEN 4 OR 6 OR 9 OR 11.
      cv_days = 30.
    WHEN 2.
      lv_r4   = iv_year MOD 4.
      lv_r100 = iv_year MOD 100.
      lv_r400 = iv_year MOD 400.
      IF ( lv_r4 = 0 AND lv_r100 <> 0 ) OR lv_r400 = 0.
        cv_days = 29.
      ELSE.
        cv_days = 28.
      ENDIF.
    WHEN OTHERS.
      cv_days = 0.
  ENDCASE.

ENDFORM.
