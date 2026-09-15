*&---------------------------------------------------------------------*
*& Report  ZPP_FORECAST          Transaction  ZFCST
*& ZFORECAST (Adhesive) - forecast generation
*&
*& Three planning modes selected by radio button:
*&   1  Annual        FS radio Button 1
*&   2  Quarter based FS radio Button 2
*&   3  Month based   FS radio button 3
*&
*& Displayed with CL_SALV_TABLE full screen, so no screen and no GUI
*& status need to be built. Rows are picked with the standard selection
*& column rather than a checkbox of our own, and Save is added to the
*& SALV toolbar.
*&
*& Built to Forecast Template-Adhesive.xlsx dated 20.08.2026
*&---------------------------------------------------------------------*
REPORT zpp_forecast MESSAGE-ID zpp_fcst.

TABLES: marc, sscrfields.

* LVC_T_FNAME is not available in every release, so the column name
* list is typed locally over LVC_FNAME
TYPES tt_fname TYPE STANDARD TABLE OF lvc_fname WITH DEFAULT KEY.

* Columns the FS does not draw - MTS/MTO, unit, forecast number, the
* status light and its message. OFF, so the list holds exactly the
* columns of the FS sheet and nothing else. Set to abap_true to bring
* them back, which also restores the traffic light column.
CONSTANTS gc_show_extras TYPE abap_bool VALUE abap_false.

* GUI status of THIS program carrying ZSAVE, ZSELALL, ZDESEL and ZEXCEL.
* Change here only - it is used to set the status and to report it when
* it cannot be found.
CONSTANTS gc_status TYPE sypfkey VALUE 'PF_STATUS'.

DATA: gt_msg  TYPE bapiret2_t,
      gt_show TYPE tt_fname,
      gt_alv  TYPE zcl_pp_fcst=>tt_alv,
      go_fcst TYPE REF TO zcl_pp_fcst,
      go_alv  TYPE REF TO cl_salv_table,
      g_mode  TYPE char1.

*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-b00.
PARAMETERS: p_ann RADIOBUTTON GROUP mod USER-COMMAND md DEFAULT 'X',
            p_qtr RADIOBUTTON GROUP mod,
            p_mth RADIOBUTTON GROUP mod.
SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
* Plant and financial year are NOT declared OBLIGATORY. The screen
* checks a mandatory field on every PAI, including the click on a mode
* radio button, so an empty plant produced "fill out all required entry
* fields" before the user had even chosen the mode - which looks exactly
* like the screen refusing to change. They are checked by hand on
* Execute instead, further down.
SELECT-OPTIONS: s_werks FOR marc-werks,
                s_matnr FOR marc-matnr.
PARAMETERS: p_fyear TYPE zde_fyear,
            p_quart TYPE zde_quarter MODIF ID qtr,
            p_perio TYPE poper       MODIF ID mth.
SELECT-OPTIONS: s_datum FOR sy-datum NO-EXTENSION MODIF ID dat.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS: p_tonn AS CHECKBOX,
            p_legc AS CHECKBOX,
            p_save AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b2.


*&---------------------------------------------------------------------*
*& Message log popup
*&
*& The SALV toolbar route is gone. add_function raises
*& CX_SALV_WRONG_CALL in this release and a GUI status could not be
*& resolved, so saving is driven from the selection screen instead and
*& this class is left with the one thing still needed.
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS on_added_function
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.

    CLASS-METHODS show_log
      IMPORTING it_msg TYPE bapiret2_t.

  PRIVATE SECTION.

    CLASS-METHODS save_selected.
    CLASS-METHODS select_all
      IMPORTING iv_on TYPE abap_bool.
    CLASS-METHODS export.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_added_function.

*   Every function code of the GUI status arrives here. Anything not
*   listed is ignored, so a button added to the status before it is
*   coded here does nothing rather than something unexpected.
    CASE e_salv_function.

      WHEN 'ZSAVE'.
        save_selected( ).

      WHEN 'ZSELALL'.
        select_all( abap_true ).

      WHEN 'ZDESEL'.
        select_all( abap_false ).

      WHEN 'ZEXCEL'.
        export( ).

      WHEN 'BACK' OR 'EXIT' OR 'CANC'.
*       A hand built status owns its own exit codes
        LEAVE TO SCREEN 0.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

  ENDMETHOD.


  METHOD save_selected.

    DATA lv_row TYPE i.

*   The button saves what the user picked. The Save checkbox on the
*   selection screen saves everything - both routes end in the same
*   class method, which decides the table from the mode.
    DATA(lt_rows) = go_alv->get_selections( )->get_selected_rows( ).

    IF lt_rows IS INITIAL.
      MESSAGE s017 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-mark = abap_false.
    ENDLOOP.

    LOOP AT lt_rows INTO lv_row.
      READ TABLE gt_alv ASSIGNING <ls> INDEX lv_row.
      IF sy-subrc = 0.
        <ls>-mark = abap_true.
      ENDIF.
    ENDLOOP.

    DATA(lt_msg) = go_fcst->save( EXPORTING iv_mode = g_mode
                                  CHANGING  ct_alv  = gt_alv ).

    go_alv->refresh( ).
    show_log( lt_msg ).

  ENDMETHOD.


  METHOD select_all.

    DATA: lt_rows TYPE salv_t_row,
          lv_row  TYPE i.

    IF iv_on = abap_true.
      lv_row = 1.
      WHILE lv_row <= lines( gt_alv ).
        APPEND lv_row TO lt_rows.
        lv_row = lv_row + 1.
      ENDWHILE.
    ENDIF.

*   An empty table clears the selection, which is Deselect all
    go_alv->get_selections( )->set_selected_rows( lt_rows ).
    go_alv->refresh( ).

  ENDMETHOD.


  METHOD export.

    DATA: lt_out  TYPE string_table,
          lv_line TYPE string,
          lv_val  TYPE string,
          lv_col  TYPE lvc_fname,
          lv_tab  TYPE c LENGTH 1,
          lv_file TYPE string,
          lv_path TYPE string,
          lv_full TYPE string,
          lv_msg  TYPE string,
          lv_ix   TYPE i.

    FIELD-SYMBOLS <lv_f> TYPE any.

    IF gt_alv IS INITIAL.
      MESSAGE s008 DISPLAY LIKE 'I'.
      RETURN.
    ENDIF.

    lv_tab = cl_abap_char_utilities=>horizontal_tab.

*   Only the columns the list is showing, in the order it shows them,
*   so the file matches the screen rather than the whole structure
    CLEAR lv_line.
    LOOP AT gt_show INTO lv_col.
      IF lv_line IS INITIAL.
        lv_line = lv_col.
      ELSE.
        CONCATENATE lv_line lv_tab lv_col INTO lv_line.
      ENDIF.
    ENDLOOP.
    APPEND lv_line TO lt_out.

    LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<ls>).

      CLEAR: lv_line, lv_ix.

      LOOP AT gt_show INTO lv_col.

        lv_ix = lv_ix + 1.
        CLEAR lv_val.
        UNASSIGN <lv_f>.
        ASSIGN COMPONENT lv_col OF STRUCTURE <ls> TO <lv_f>.
        IF <lv_f> IS ASSIGNED.
          lv_val = <lv_f>.
          CONDENSE lv_val.
        ENDIF.

        IF lv_ix = 1.
          lv_line = lv_val.
        ELSE.
          CONCATENATE lv_line lv_tab lv_val INTO lv_line.
        ENDIF.

      ENDLOOP.

      APPEND lv_line TO lt_out.

    ENDLOOP.

    CONCATENATE 'ZFORECAST_' g_mode '.txt' INTO lv_file.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING  default_file_name = lv_file
                 default_extension = 'txt'
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
      CONCATENATE 'List saved to' lv_full INTO lv_msg SEPARATED BY space.
      MESSAGE lv_msg TYPE 'S'.
    ELSE.
      MESSAGE e013 WITH lv_full.
    ENDIF.

  ENDMETHOD.


  METHOD show_log.

    CHECK it_msg IS NOT INITIAL.

    CALL FUNCTION 'MESSAGES_INITIALIZE'.

    LOOP AT it_msg INTO DATA(ls_msg).
      CALL FUNCTION 'MESSAGE_STORE'
        EXPORTING  arbgb  = ls_msg-id
                   msgty  = ls_msg-type
                   msgv1  = ls_msg-message_v1
                   msgv2  = ls_msg-message_v2
                   msgv3  = ls_msg-message_v3
                   msgv4  = ls_msg-message_v4
                   txtnr  = ls_msg-number
        EXCEPTIONS OTHERS = 1.
    ENDLOOP.

    CALL FUNCTION 'MESSAGES_SHOW'
      EXPORTING  show_linno = abap_false
      EXCEPTIONS OTHERS     = 1.

  ENDMETHOD.

ENDCLASS.


*&---------------------------------------------------------------------*
INITIALIZATION.

  " Financial year containing today, April to March
  DATA(gv_y) = CONV i( sy-datum(4) ).
  IF sy-datum+4(2) < '04'.
    gv_y = gv_y - 1.
  ENDIF.
  p_fyear = |{ gv_y }-{ gv_y + 1 }|.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'QTR'. screen-active = COND #( WHEN p_qtr = abap_true THEN 1 ELSE 0 ).
      WHEN 'MTH'. screen-active = COND #( WHEN p_mth = abap_true THEN 1 ELSE 0 ).
      WHEN 'DAT'. screen-active = COND #( WHEN p_ann = abap_true THEN 0 ELSE 1 ).
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fyear.

  PERFORM f4_fyear.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_quart.

  PERFORM f4_quart.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_perio.

  PERFORM f4_perio.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.

* Clicking a mode radio button raises PAI, so every check below used to
* run while the user was still choosing the mode and threw errors on
* fields they had not reached yet. Only the mode switch is skipped, so a
* background run with a blank function code is still validated.
  IF sscrfields-ucomm = 'MD'.
    RETURN.
  ENDIF.

  IF s_werks[] IS INITIAL.
    MESSAGE e001.
  ENDIF.

  IF zcl_pp_fcst_util=>split_fyear( p_fyear ) = abap_false.
    MESSAGE e002 WITH p_fyear.
  ENDIF.

  " Either quarter or date, one of them mandatory
  IF p_qtr = abap_true.
    IF p_quart IS NOT INITIAL AND s_datum[] IS NOT INITIAL.
      MESSAGE e003.
    ENDIF.
    IF p_quart IS INITIAL AND s_datum[] IS INITIAL.
      MESSAGE e003.
    ENDIF.
  ENDIF.

  IF p_mth = abap_true AND p_perio IS INITIAL.
    MESSAGE e004.
  ENDIF.

  LOOP AT s_werks INTO DATA(ls_w).
    IF zcl_pp_fcst_util=>check_authority( iv_werks = ls_w-low
                                          iv_actvt = '03' ) = abap_false.
      MESSAGE e010 WITH ls_w-low '03'.
    ENDIF.
    IF p_legc = abap_true
   AND zcl_pp_fcst_util=>check_legacy_authority( ls_w-low ) = abap_false.
      MESSAGE e011.
    ENDIF.
  ENDLOOP.

*&---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM generate.

* Always written, whether the run produced rows or not. This is the
* record support reads in QAS when the numbers look wrong.
  PERFORM save_log.

  IF gt_alv IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

* Saved before the list is drawn, so the forecast number and the result
* of each row are already on the rows the list shows.
  IF p_save = abap_true.
    PERFORM save_all.
  ENDIF.

  PERFORM display.


*&---------------------------------------------------------------------*
*& Application log - SLG1, object ZPP_FCST subobject GENERATE
*&
*& Everything the run wanted to say is written here: materials with no
*& annual forecast, missing product categories, missing load factors.
*& The user is not shown any of it.
*&
*& If the log object has not been created in SLG0 the run carries on
*& without a log rather than failing. The list is what matters, and the
*& Show message log checkbox still puts the same messages on screen.
*&---------------------------------------------------------------------*
FORM save_log.

  DATA: ls_log    TYPE bal_s_log,
        ls_bal    TYPE bal_s_msg,
        ls_msg    TYPE bapiret2,
        lv_handle TYPE balloghndl,
        lt_handle TYPE bal_t_logh.

  CHECK gt_msg IS NOT INITIAL.

  ls_log-object    = 'ZPP_FCST'.
  ls_log-subobject = 'GENERATE'.
  ls_log-aldate    = sy-datum.
  ls_log-altime    = sy-uzeit.
  ls_log-aluser    = sy-uname.
  ls_log-alprog    = sy-repid.

* What the run was, so one log can be told from another in SLG1
  ls_log-extnumber = |{ g_mode } { p_fyear } { sy-uname }|.

  CALL FUNCTION 'BAL_LOG_CREATE'
    EXPORTING  i_s_log      = ls_log
    IMPORTING  e_log_handle = lv_handle
    EXCEPTIONS OTHERS       = 1.

  CHECK sy-subrc = 0.

  LOOP AT gt_msg INTO ls_msg.
    CLEAR ls_bal.
    ls_bal-msgty = ls_msg-type.
    ls_bal-msgid = ls_msg-id.
    ls_bal-msgno = ls_msg-number.
    ls_bal-msgv1 = ls_msg-message_v1.
    ls_bal-msgv2 = ls_msg-message_v2.
    ls_bal-msgv3 = ls_msg-message_v3.
    ls_bal-msgv4 = ls_msg-message_v4.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING  i_log_handle = lv_handle
                 i_s_msg      = ls_bal
      EXCEPTIONS OTHERS       = 1.
  ENDLOOP.

  APPEND lv_handle TO lt_handle.

  CALL FUNCTION 'BAL_DB_SAVE'
    EXPORTING  i_t_log_handle = lt_handle
               i_save_all     = abap_true
    EXCEPTIONS OTHERS         = 1.

  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM generate.

  DATA lt_msg TYPE bapiret2_t.

  CLEAR: gt_alv, gt_msg.
  CREATE OBJECT go_fcst.

  g_mode = COND #( WHEN p_ann = abap_true THEN zcl_pp_fcst=>gc_mode-annual
                   WHEN p_qtr = abap_true THEN zcl_pp_fcst=>gc_mode-quarterly
                   ELSE                        zcl_pp_fcst=>gc_mode-monthly ).

  CASE g_mode.

    WHEN zcl_pp_fcst=>gc_mode-annual.
      go_fcst->generate_annual( EXPORTING ir_werks   = s_werks[]
                                          ir_matnr   = s_matnr[]
                                          iv_fyear   = p_fyear
                                          iv_legacy  = p_legc
                                          iv_tonnage = p_tonn
                                IMPORTING et_alv     = gt_alv
                                          et_msg     = lt_msg ).

    WHEN zcl_pp_fcst=>gc_mode-quarterly.
      go_fcst->generate_quarterly( EXPORTING ir_werks   = s_werks[]
                                             ir_matnr   = s_matnr[]
                                             iv_fyear   = p_fyear
                                             iv_quarter = p_quart
                                             iv_legacy  = p_legc
                                             iv_tonnage = p_tonn
                                   IMPORTING et_alv     = gt_alv
                                             et_msg     = lt_msg ).

    WHEN zcl_pp_fcst=>gc_mode-monthly.
      go_fcst->generate_monthly( EXPORTING ir_werks   = s_werks[]
                                           ir_matnr   = s_matnr[]
                                           iv_fyear   = p_fyear
                                           iv_period  = p_perio
                                           iv_legacy  = p_legc
                                           iv_tonnage = p_tonn
                                 IMPORTING et_alv     = gt_alv
                                           et_msg     = lt_msg ).
  ENDCASE.

* The messages are kept rather than shown. A user who selected nothing
* wants to be told "no records", not handed six technical lines about
* materials they never asked about. They go to the application log, and
* on to the screen only if the log checkbox was ticked.
  gt_msg = lt_msg.

ENDFORM.


*&---------------------------------------------------------------------*
*& Save
*&
*& One routine for all three modes. The class decides which table the
*& rows belong to from the mode it is given:
*&
*&   Annual     ZPPT_FCST_YR   draws the forecast number from SNRO
*&   Quarterly  ZPPT_FCST_QT   reuses the annual number
*&   Monthly    ZPPT_FCST_MN   reuses the annual number
*&
*& Every generated row is saved. The user has already narrowed the run
*& with plant, material and year on the selection screen, so there is
*& nothing further to pick.
*&---------------------------------------------------------------------*
FORM save_all.

* LIKE LINE OF s_werks, not RSELOPTION - the generic select option line
* types LOW as CHAR 45, which is not compatible with WERKS_D
  DATA ls_w LIKE LINE OF s_werks.

* Saving is a different activity from displaying, so it is checked again
  LOOP AT s_werks INTO ls_w.
    IF zcl_pp_fcst_util=>check_authority( iv_werks = ls_w-low
                                          iv_actvt = '01' ) = abap_false.
      MESSAGE e010 WITH ls_w-low '01'.
    ENDIF.
  ENDLOOP.

* SAVE works on the rows carrying MARK
  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<ls>).
    <ls>-mark = abap_true.
  ENDLOOP.

  DATA(lt_msg) = go_fcst->save( EXPORTING iv_mode = g_mode
                                CHANGING  ct_alv  = gt_alv ).

* The outcome of a save is something the user asked for, so unlike the
* generation messages it is shown rather than only logged
  lcl_handler=>show_log( lt_msg ).

  APPEND LINES OF lt_msg TO gt_msg.

ENDFORM.


*&---------------------------------------------------------------------*
FORM display.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                              CHANGING  t_table      = gt_alv ).

      "--- toolbar -------------------------------------------------------
      go_alv->get_functions( )->set_all( ).

      DATA(lv_save_ok) = abap_true.

      LOOP AT s_werks INTO DATA(ls_w2).
        IF zcl_pp_fcst_util=>check_authority( iv_werks = ls_w2-low
                                              iv_actvt = '01' ) = abap_false.
          lv_save_ok = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.

*     The GUI status of THIS program carries the custom buttons.
*     set_functions = c_functions_all keeps SALV's own functions working
*     alongside it. If the status cannot be resolved the display below
*     falls back rather than dumping, and the Save checkbox on the
*     selection screen still saves.
      IF lv_save_ok = abap_true.
        go_alv->set_screen_status(
          pfstatus      = gc_status
          report        = sy-repid
          set_functions = cl_salv_table=>c_functions_all ).
      ENDIF.

      "--- row selection, so the buttons have something to act on -------
      go_alv->get_selections( )->set_selection_mode(
        if_salv_c_selection_mode=>row_column ).

      SET HANDLER lcl_handler=>on_added_function FOR go_alv->get_event( ).

      "--- columns ------------------------------------------------------
      PERFORM visible_columns CHANGING gt_show.
      PERFORM setup_columns   USING    gt_show.

      DATA(lv_head) = |{ SWITCH string( g_mode
                                        WHEN 'A' THEN 'Annual'
                                        WHEN 'Q' THEN 'Quarterly'
                                        ELSE          'Monthly' ) }| &&
                      | Forecast - { p_fyear }|.

      go_alv->get_display_settings( )->set_list_header( CONV lvc_title( lv_head ) ).

*     SALV resolves the status when it draws the list, not when
*     set_screen_status is called, so a status it cannot find surfaces
*     here. Redrawn with SALV's own status instead of dumping.
      TRY.
          go_alv->display( ).
        CATCH cx_salv_object_not_found.
          DATA(lv_stmsg) = |GUI status { gc_status } not found in { sy-repid }, | &&
                           |standard toolbar used|.
          MESSAGE lv_stmsg TYPE 'S' DISPLAY LIKE 'W'.
          go_alv->set_screen_status(
            report        = 'SAPLSALV_METADATA_STATUS'
            pfstatus      = 'SALV_STANDARD'
            set_functions = cl_salv_table=>c_functions_all ).
          go_alv->display( ).
      ENDTRY.

    CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error
          cx_salv_existing cx_salv_wrong_call
          cx_salv_object_not_found INTO DATA(lx_salv).
*     Reporting 008 "no data selected" for any ALV failure hid the real
*     cause. The exception text is shown instead.
      DATA(lv_err) = lx_salv->get_text( ).
      MESSAGE lv_err TYPE 'E'.
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
*& Columns belonging to the chosen mode. Everything else is set
*& technical, so one wide structure serves all three modes.
*&---------------------------------------------------------------------*
FORM visible_columns CHANGING ct_show TYPE tt_fname.

  DATA lv_p TYPE numc2.

  CLEAR ct_show.

* ---- leading block, identical on all three FS sheets ----------------
  ct_show = VALUE tt_fname(
    ( 'WERKS' ) ( 'MATNR' ) ( 'MAKTX' ) ( 'MATKL' ) ( 'NTGEW' )
    ( 'MVGR1_TXT' ) ( 'MVGR2_TXT' ) ( 'MVGR3_TXT' )
    ( 'MVGR4_TXT' ) ( 'MVGR5_TXT' ) ).

  CASE g_mode.

*   ---- FS radio Button 1, row 24 (tonnage block from row 75) --------
    WHEN zcl_pp_fcst=>gc_mode-annual.

*     Apr-25 .. Mar-26
      DO 12 TIMES.
        lv_p = sy-index.
        APPEND CONV lvc_fname( |M{ lv_p }| ) TO ct_show.
      ENDDO.

      APPEND 'LY_TOTAL'   TO ct_show.   " Total LY Sales Qty
      APPEND 'PROD_CAT'   TO ct_show.   " Product Cat.
      APPEND 'LOAD_FCT'   TO ct_show.   " Load Factor
      APPEND 'FCST_TOTAL' TO ct_show.   " Forecast Qty_FY2026-27

*     Apr-26 .. Mar-27
      DO 12 TIMES.
        lv_p = sy-index.
        APPEND CONV lvc_fname( |M{ lv_p }_FCST| ) TO ct_show.
      ENDDO.

      IF p_tonn = abap_true.
        DO 12 TIMES.
          lv_p = sy-index.
          APPEND CONV lvc_fname( |M{ lv_p }_TON| ) TO ct_show.
        ENDDO.
      ENDIF.

*   ---- FS radio Button 2, row 17 ------------------------------------
    WHEN zcl_pp_fcst=>gc_mode-quarterly.

      APPEND 'M4_LAST'    TO ct_show.   " July'25
      APPEND 'M5_LAST'    TO ct_show.   " Aug'25
      APPEND 'M6_LAST'    TO ct_show.   " Sep'25
      APPEND 'LY_QTR_TOT' TO ct_show.   " Total LY Quarter Sales Qty
      APPEND 'M1_CURR'    TO ct_show.   " April'26
      APPEND 'M2_CURR'    TO ct_show.   " May'26
      APPEND 'M3_CURR'    TO ct_show.   " Jun'26
      APPEND 'L3M_TOT'    TO ct_show.   " L3 Month Total Sales Qty
      APPEND 'MAX_QTY'    TO ct_show.   " Max. Qty
      APPEND 'PROD_CAT'   TO ct_show.   " Product Cat.
      APPEND 'LOAD_FCT'   TO ct_show.   " Growth Based on Category
      APPEND 'FCST_QTY'   TO ct_show.   " Forecast (Max * Growth %)
      APPEND 'BUS_FCST'   TO ct_show.   " Business Forecast
      APPEND 'FINAL_QTY'  TO ct_show.   " Final Forecast Qty
      APPEND 'M4_FCST'    TO ct_show.   " July'26
      APPEND 'M5_FCST'    TO ct_show.   " Aug'26
      APPEND 'M6_FCST'    TO ct_show.   " Sep'26

*BOC By Arnav on 15/09/26
*     Price and the values in EA, change request of 15/09/26
      APPEND 'PRICE'      TO ct_show.   " KONP-KBETR via A923
      APPEND 'VAL_M4'     TO ct_show.   " Price for July 26 in EA
      APPEND 'VAL_M5'     TO ct_show.   " Price for Aug 26 in EA
      APPEND 'VAL_M6'     TO ct_show.   " Price for Sep 26 in EA
      APPEND 'VAL_TOTAL'  TO ct_show.   " Final forecast qty x Price
*EOC By Arnav on 15/09/26

      IF p_tonn = abap_true.
        APPEND 'M4_TON' TO ct_show.
        APPEND 'M5_TON' TO ct_show.
        APPEND 'M6_TON' TO ct_show.
*BOC By Arnav on 15/09/26
        APPEND 'VAL_M4_TON' TO ct_show.   " Price for July 26 in Tonnage
        APPEND 'VAL_M5_TON' TO ct_show.   " Price for Aug 26 in Tonnage
        APPEND 'VAL_M6_TON' TO ct_show.   " Price for Sep 26 in Tonnage
*EOC By Arnav on 15/09/26
      ENDIF.

      APPEND 'MTS_MTO'    TO ct_show.   " AE17, the last FS column

*   ---- FS radio button 3, row 25 ------------------------------------
    WHEN zcl_pp_fcst=>gc_mode-monthly.

      APPEND 'M4_LAST'      TO ct_show.   " July'25
      APPEND 'M5_LAST'      TO ct_show.   " Aug'25
      APPEND 'M6_LAST'      TO ct_show.   " Sep'25
      APPEND 'LY_QTR_TOT'   TO ct_show.   " Total LY Quarter Sales Qty
      APPEND 'M1_CURR'      TO ct_show.   " April'26
      APPEND 'M2_CURR'      TO ct_show.   " May'26
      APPEND 'M3_CURR'      TO ct_show.   " Jun'26
      APPEND 'L3M_AVG'      TO ct_show.   " L3 Month Average
      APPEND 'PROD_CAT'     TO ct_show.   " Product Cat.
      APPEND 'LOAD_FCT'     TO ct_show.   " Growth Based on Category
      APPEND 'MAX_QTY'      TO ct_show.   " Average * Load
      APPEND 'FCST_QTY'     TO ct_show.   " LY vs Current Requirement Qty
      APPEND 'BUS_FCST'     TO ct_show.   " Business Forecast
      APPEND 'FINAL_QTY'    TO ct_show.   " Final Forecast Qty
      APPEND 'BUS_FCST_ADD' TO ct_show.   " Additonal plan qty july 26
      APPEND 'TOTAL_QTY'    TO ct_show.   " final forecast qty, column Q

*BOC By Arnav on 15/09/26
*     Price and the values, change request of 15/09/26 - one month, so
*     one value in EA, the total, and the tonnage value below
      APPEND 'PRICE'        TO ct_show.   " KONP-KBETR via A923
      APPEND 'VAL_M4'       TO ct_show.   " Price for <month> in EA
      APPEND 'VAL_TOTAL'    TO ct_show.   " Final forecast qty x Price
*EOC By Arnav on 15/09/26

      IF p_tonn = abap_true.
        APPEND 'M4_TON' TO ct_show.
        APPEND 'VAL_M4_TON' TO ct_show.   "Changes by Arnav on 15/09/26 - Price in Tonnage
      ENDIF.

  ENDCASE.

* ---- the result of a save --------------------------------------------
* Only when the run actually saved. The forecast number and the per row
* outcome are the point of pressing save, so they are shown then and
* only then. The traffic light stays off - an exception column is drawn
* in front of Plant whatever position it is given.
  IF p_save = abap_true.
    APPEND 'FCST_NO' TO ct_show.
    APPEND 'MESSAGE' TO ct_show.
  ENDIF.

* ---- not drawn on this FS sheet, kept at the end --------------------
  IF gc_show_extras = abap_true.

    IF g_mode = zcl_pp_fcst=>gc_mode-quarterly.
*     Sheet 2 shows Business Forecast but not the additional column.
*     The Final ALV sheet carries it and the change upload writes it.
      APPEND 'BUS_FCST_ADD' TO ct_show.
    ELSE.
*     MTS / MTO is drawn on sheet 2 only
      APPEND 'MTS_MTO' TO ct_show.
    ENDIF.

    APPEND 'MEINS'   TO ct_show.   " unit for every quantity column
    APPEND 'FCST_NO' TO ct_show.   " forecast number, FS requirement E
    APPEND 'LIGHT'   TO ct_show.   " status light
    APPEND 'MESSAGE' TO ct_show.   " why a row is flagged

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM setup_columns USING pt_show TYPE tt_fname.

  DATA: lv_col TYPE lvc_fname,
        lv_hdr TYPE string,
        lv_nam TYPE char3,
        lv_pos TYPE i.

  DATA(lo_cols) = go_alv->get_columns( ).
  lo_cols->set_optimize( ).

* An exception column is drawn in front of every other column whatever
* position it is given, so it is only declared when the extras are on.
* Declaring it and then hiding LIGHT still leaves the light in front of
* Plant.
  IF gc_show_extras = abap_true.
    TRY.
        lo_cols->set_exception_column( 'LIGHT' ).
      CATCH cx_salv_data_error.
    ENDTRY.
  ENDIF.

* ---- hide everything that does not belong to this mode --------------
* LOOP AT over a functional call iterates zero times in this release,
* so the result is put in a variable first. Without this nothing is
* hidden and every field of the structure is displayed.
  DATA(lt_cols) = lo_cols->get( ).

  LOOP AT lt_cols INTO DATA(ls_col).

    READ TABLE pt_show TRANSPORTING NO FIELDS
      WITH KEY table_line = ls_col-columnname.

    IF sy-subrc <> 0.
      TRY.
          ls_col-r_column->set_technical( abap_true ).
        CATCH cx_salv_error.
      ENDTRY.
    ENDIF.

  ENDLOOP.

* ---- display order --------------------------------------------------
* PT_SHOW is already in the order the FS draws the columns, so the
* position of a column is simply its index in that list. Without this
* the ALV falls back to the order of the fields in the structure, which
* puts the status light, the message and the forecast number in front
* of Plant.
  lv_pos = 0.
  LOOP AT pt_show INTO lv_col.
    lv_pos = lv_pos + 1.
    TRY.
        lo_cols->set_column_position( columnname = lv_col
                                      position   = lv_pos ).
      CATCH cx_salv_error.
    ENDTRY.
  ENDLOOP.

* ---- headings -------------------------------------------------------
  IF g_mode = zcl_pp_fcst=>gc_mode-annual.

    DATA(lv_prev) = zcl_pp_fcst_util=>previous_fyear( p_fyear ).

*   PERFORM ... USING takes data objects only, so the column name and
*   the heading are built into variables first
    DO 12 TIMES.

      DATA(lv_p) = CONV numc2( sy-index ).

      zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = lv_prev
                                                       iv_period = lv_p
                                             IMPORTING ev_gjahr  = DATA(lv_yy)
                                                       ev_month  = DATA(lv_mm) ).
      lv_col = |M{ lv_p }|.
      PERFORM month_name USING lv_mm CHANGING lv_nam.
      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
      PERFORM txt USING lv_col lv_hdr.

      zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = p_fyear
                                                       iv_period = lv_p
                                             IMPORTING ev_gjahr  = lv_yy
                                                       ev_month  = lv_mm ).
      lv_col = |M{ lv_p }_FCST|.
      PERFORM month_name USING lv_mm CHANGING lv_nam.
      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
      PERFORM txt USING lv_col lv_hdr.

      lv_col = |M{ lv_p }_TON|.
      PERFORM month_name USING lv_mm CHANGING lv_nam.
      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } tonnage|.
      PERFORM txt USING lv_col lv_hdr.

    ENDDO.

    PERFORM txt USING 'LY_TOTAL' 'Total LY Sales Qty'.
    PERFORM txt USING 'LOAD_FCT' 'Load Factor'.

    lv_hdr = |Forecast Qty FY{ p_fyear }|.
    PERFORM txt USING 'FCST_TOTAL' lv_hdr.

  ELSE.

    PERFORM txt USING 'M4_LAST'      'LY Month 1'.
    PERFORM txt USING 'M5_LAST'      'LY Month 2'.
    PERFORM txt USING 'M6_LAST'      'LY Month 3'.
    PERFORM txt USING 'LY_QTR_TOT'   'Total LY Quarter Sales Qty'.
    PERFORM txt USING 'M1_CURR'      'Current Month 1'.
    PERFORM txt USING 'M2_CURR'      'Current Month 2'.
    PERFORM txt USING 'M3_CURR'      'Current Month 3'.
    PERFORM txt USING 'L3M_TOT'      'L3 Month Total Sales Qty'.
    PERFORM txt USING 'L3M_AVG'      'L3 Month Average'.
    PERFORM txt USING 'LOAD_FCT'     'Growth Based on Category'.
    PERFORM txt USING 'BUS_FCST'     'Business Forecast'.
    PERFORM txt USING 'BUS_FCST_ADD' 'Additional Plan Qty'.
    PERFORM txt USING 'FINAL_QTY'    'Final Forecast Qty'.
*   The FS heads both column O and column Q "Final Forecast Qty". The
*   second is qualified here so the two can be told apart on screen.
    PERFORM txt USING 'TOTAL_QTY'    'Final Fcst Qty incl. Additional'.
    PERFORM txt USING 'M4_FCST'      'Month 1'.
    PERFORM txt USING 'M5_FCST'      'Month 2'.
    PERFORM txt USING 'M6_FCST'      'Month 3'.
    PERFORM txt USING 'M4_TON'       'Month 1 tonnage'.
    PERFORM txt USING 'M5_TON'       'Month 2 tonnage'.
    PERFORM txt USING 'M6_TON'       'Month 3 tonnage'.

*BOC By Arnav on 15/09/26
*   Price and value headings carry the real month - "Price for Jul 26
*   in EA" - as the change request words them. Built in PRICE_HEADINGS
*   from the quarter, or from the one period entered in monthly mode.
    PERFORM txt USING 'PRICE'        'Price'.
    PERFORM txt USING 'VAL_TOTAL'    'Final Fcst Qty x Price'.
    PERFORM price_headings.
*EOC By Arnav on 15/09/26

    IF g_mode = zcl_pp_fcst=>gc_mode-quarterly.
      PERFORM txt USING 'MAX_QTY'  'Max. Qty'.
      PERFORM txt USING 'FCST_QTY' 'Forecast (Max * Growth %)'.
    ELSE.
      PERFORM txt USING 'MAX_QTY'  'Average * Load'.
      PERFORM txt USING 'FCST_QTY' 'LY vs Current Requirement Qty'.
    ENDIF.

  ENDIF.

  PERFORM txt USING 'PROD_CAT'  'Product Cat.'.
  PERFORM txt USING 'MTS_MTO'   'MTS / MTO'.
  PERFORM txt USING 'MVGR1_TXT' 'Material Group 1'.
  PERFORM txt USING 'MVGR2_TXT' 'Material Group 2'.
  PERFORM txt USING 'MVGR3_TXT' 'Material Group 3'.
  PERFORM txt USING 'MVGR4_TXT' 'Material Group 4'.
  PERFORM txt USING 'MVGR5_TXT' 'Material Group 5'.
  PERFORM txt USING 'FCST_NO'   'Forecast Number'.

ENDFORM.


*&---------------------------------------------------------------------*
*& Value helps
*&
*& Plant, material and date get their help from the data dictionary and
*& need nothing here. Financial year, quarter and period are custom
*& types with no check table, so each is built by hand. Every one of
*& them shows the real calendar months behind the code, because M1
*& meaning April is not something a user should have to remember.
*&---------------------------------------------------------------------*
FORM month_name USING pv_mm TYPE any
                CHANGING cv_name TYPE any.

  CONSTANTS lc_names TYPE char36
    VALUE 'JanFebMarAprMayJunJulAugSepOctNovDec'.

  DATA: lv_i   TYPE i,
        lv_off TYPE i.

  CLEAR cv_name.

  lv_i = pv_mm.
  CHECK lv_i >= 1 AND lv_i <= 12.

  lv_off  = ( lv_i - 1 ) * 3.
  cv_name = lc_names+lv_off(3).

ENDFORM.


*&---------------------------------------------------------------------*
FORM f4_fyear.

  TYPES: BEGIN OF ty_f4,
           fyear TYPE char9,
           text  TYPE char30,
         END OF ty_f4.

  DATA: lt_f4  TYPE STANDARD TABLE OF ty_f4 WITH DEFAULT KEY,
        ls_f4  TYPE ty_f4,
        lt_ret TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY,
        ls_ret TYPE ddshretval,
        lv_y   TYPE i,
        lv_nx  TYPE i.

* The financial year containing today is the one that started last April
  lv_y = sy-datum(4).
  IF sy-datum+4(2) < '04'.
    lv_y = lv_y - 1.
  ENDIF.

* Five back and five forward is enough for planning and for restating
  lv_y = lv_y - 5.

  DO 11 TIMES.
    CLEAR ls_f4.
    lv_nx = lv_y + 1.
    ls_f4-fyear = |{ lv_y }-{ lv_nx }|.
    ls_f4-text  = |April { lv_y } to March { lv_nx }|.
    APPEND ls_f4 TO lt_f4.
    lv_y = lv_y + 1.
  ENDDO.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING  retfield        = 'FYEAR'
               dynpprog        = sy-repid
               dynpnr          = sy-dynnr
               dynprofield     = 'P_FYEAR'
               value_org       = 'S'
    TABLES     value_tab       = lt_f4
               return_tab      = lt_ret
    EXCEPTIONS parameter_error = 1
               no_values_found = 2
               OTHERS          = 3.

  IF sy-subrc = 0.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    IF sy-subrc = 0.
      p_fyear = ls_ret-fieldval.
    ENDIF.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM f4_quart.

  TYPES: BEGIN OF ty_f4,
           quarter TYPE char1,
           months  TYPE char24,
         END OF ty_f4.

  DATA: lt_f4  TYPE STANDARD TABLE OF ty_f4 WITH DEFAULT KEY,
        ls_f4  TYPE ty_f4,
        lt_ret TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY,
        ls_ret TYPE ddshretval,
        lv_q   TYPE i,
        lv_p1  TYPE numc2,
        lv_p3  TYPE numc2,
        lv_i   TYPE i,
        lv_y1  TYPE gjahr,
        lv_y3  TYPE gjahr,
        lv_m1  TYPE numc2,
        lv_m3  TYPE numc2,
        lv_n1  TYPE char3,
        lv_n3  TYPE char3,
        lv_ok  TYPE abap_bool.

* The financial year on the screen turns Q2 into "Jul 2026 to Sep 2026".
* If it is not readable yet the months are still shown, without a year.
  lv_ok = zcl_pp_fcst_util=>split_fyear( p_fyear ).

  DO 4 TIMES.

    CLEAR ls_f4.
    lv_q = sy-index.
    ls_f4-quarter = lv_q.

    lv_i  = ( lv_q - 1 ) * 3 + 1.
    lv_p1 = lv_i.
    lv_i  = lv_i + 2.
    lv_p3 = lv_i.

    CLEAR: lv_y1, lv_y3, lv_m1, lv_m3.

    IF lv_ok = abap_true.
      zcl_pp_fcst_util=>period_to_yearmonth(
        EXPORTING iv_fyear = p_fyear iv_period = lv_p1
        IMPORTING ev_gjahr = lv_y1   ev_month  = lv_m1 ).
      zcl_pp_fcst_util=>period_to_yearmonth(
        EXPORTING iv_fyear = p_fyear iv_period = lv_p3
        IMPORTING ev_gjahr = lv_y3   ev_month  = lv_m3 ).
    ELSE.
      lv_i  = ( lv_q - 1 ) * 3 + 4.
      IF lv_i > 12.
        lv_i = lv_i - 12.
      ENDIF.
      lv_m1 = lv_i.
      lv_i  = lv_i + 2.
      IF lv_i > 12.
        lv_i = lv_i - 12.
      ENDIF.
      lv_m3 = lv_i.
    ENDIF.

    PERFORM month_name USING lv_m1 CHANGING lv_n1.
    PERFORM month_name USING lv_m3 CHANGING lv_n3.

    IF lv_y1 IS INITIAL.
      ls_f4-months = |{ lv_n1 } to { lv_n3 }|.
    ELSE.
      ls_f4-months = |{ lv_n1 } { lv_y1 } to { lv_n3 } { lv_y3 }|.
    ENDIF.

    APPEND ls_f4 TO lt_f4.

  ENDDO.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING  retfield        = 'QUARTER'
               dynpprog        = sy-repid
               dynpnr          = sy-dynnr
               dynprofield     = 'P_QUART'
               value_org       = 'S'
    TABLES     value_tab       = lt_f4
               return_tab      = lt_ret
    EXCEPTIONS parameter_error = 1
               no_values_found = 2
               OTHERS          = 3.

  IF sy-subrc = 0.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    IF sy-subrc = 0.
      p_quart = ls_ret-fieldval.
    ENDIF.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM f4_perio.

  TYPES: BEGIN OF ty_f4,
           period TYPE char2,
           month  TYPE char3,
           year   TYPE char4,
         END OF ty_f4.

  DATA: lt_f4  TYPE STANDARD TABLE OF ty_f4 WITH DEFAULT KEY,
        ls_f4  TYPE ty_f4,
        lt_ret TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY,
        ls_ret TYPE ddshretval,
        lv_p   TYPE numc2,
        lv_i   TYPE i,
        lv_yy  TYPE gjahr,
        lv_mm  TYPE numc2,
        lv_nam TYPE char3,
        lv_ok  TYPE abap_bool.

  lv_ok = zcl_pp_fcst_util=>split_fyear( p_fyear ).

  DO 12 TIMES.

    CLEAR: ls_f4, lv_yy, lv_mm.
    lv_p = sy-index.
    ls_f4-period = lv_p.

    IF lv_ok = abap_true.
      zcl_pp_fcst_util=>period_to_yearmonth(
        EXPORTING iv_fyear = p_fyear iv_period = lv_p
        IMPORTING ev_gjahr = lv_yy   ev_month  = lv_mm ).
      ls_f4-year = lv_yy.
    ELSE.
*     Period 1 is April, so the calendar month is the period plus three
      lv_i = sy-index + 3.
      IF lv_i > 12.
        lv_i = lv_i - 12.
      ENDIF.
      lv_mm = lv_i.
    ENDIF.

    PERFORM month_name USING lv_mm CHANGING lv_nam.
    ls_f4-month = lv_nam.

    APPEND ls_f4 TO lt_f4.

  ENDDO.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING  retfield        = 'PERIOD'
               dynpprog        = sy-repid
               dynpnr          = sy-dynnr
               dynprofield     = 'P_PERIO'
               value_org       = 'S'
    TABLES     value_tab       = lt_f4
               return_tab      = lt_ret
    EXCEPTIONS parameter_error = 1
               no_values_found = 2
               OTHERS          = 3.

  IF sy-subrc = 0.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    IF sy-subrc = 0.
      p_perio = ls_ret-fieldval.
    ENDIF.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM txt USING pv_name TYPE any
               pv_text TYPE any.

  DATA: lv_txt TYPE string,
        lv_len TYPE lvc_outlen.

* ALV picks WHICH of the three heading texts to draw from the column
* output length - the short one below 10 characters, the medium one
* below 20, the long one above that. A long heading on a narrow numeric
* column was therefore drawn from the short text and cut off. The width
* is set from the heading so the long text is chosen, and set_optimize
* then widens further where the data needs it.
  lv_txt = pv_text.
  lv_len = strlen( lv_txt ).
  IF lv_len < 10.
    lv_len = 10.
  ELSEIF lv_len > 40.
    lv_len = 40.
  ENDIF.

  TRY.
      DATA(lo_col) = go_alv->get_columns( )->get_column( CONV lvc_fname( pv_name ) ).
      lo_col->set_short_text( CONV scrtext_s( lv_txt ) ).
      lo_col->set_medium_text( CONV scrtext_m( lv_txt ) ).
      lo_col->set_long_text( CONV scrtext_l( lv_txt ) ).
      lo_col->set_output_length( lv_len ).
    CATCH cx_salv_not_found.
  ENDTRY.

ENDFORM.


*BOC By Arnav on 15/09/26
*&---------------------------------------------------------------------*
*& Headings of the value columns, with the calendar month behind them:
*&   VAL_M4 .. VAL_M6          Price for Jul 26 in EA
*&   VAL_M4_TON .. VAL_M6_TON  Price for Jul 26 in Tonnage
*& Quarterly names the three months of the quarter; monthly has one
*& month, so only VAL_M4 and VAL_M4_TON are headed (the others are
*& hidden in that mode anyway).
*&---------------------------------------------------------------------*
FORM price_headings.

  DATA: lt_per TYPE zcl_pp_fcst_util=>tt_period,
        lv_col TYPE lvc_fname,
        lv_hdr TYPE string,
        lv_nam TYPE char3,
        lv_yy  TYPE gjahr,
        lv_mm  TYPE numc2,
        lv_i   TYPE i.

  IF g_mode = zcl_pp_fcst=>gc_mode-quarterly.
    lt_per = zcl_pp_fcst_util=>quarter_periods( iv_fyear   = p_fyear
                                                iv_quarter = p_quart ).
  ELSE.
    zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = p_fyear
                                                     iv_period = CONV #( p_perio )
                                           IMPORTING ev_gjahr  = lv_yy
                                                     ev_month  = lv_mm ).
    APPEND VALUE #( gjahr = lv_yy month = lv_mm ) TO lt_per.
  ENDIF.

  LOOP AT lt_per INTO DATA(ls_per).

    lv_i  = sy-tabix + 3.
    lv_yy = ls_per-gjahr.
    PERFORM month_name USING ls_per-month CHANGING lv_nam.

    lv_col = |VAL_M{ lv_i }|.
    lv_hdr = |Price for { lv_nam } { lv_yy+2(2) } in EA|.
    PERFORM txt USING lv_col lv_hdr.

    lv_col = |VAL_M{ lv_i }_TON|.
    lv_hdr = |Price for { lv_nam } { lv_yy+2(2) } in Tonnage|.
    PERFORM txt USING lv_col lv_hdr.

  ENDLOOP.

ENDFORM.
*EOC By Arnav on 15/09/26
