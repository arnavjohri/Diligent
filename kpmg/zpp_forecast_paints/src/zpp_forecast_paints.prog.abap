*&---------------------------------------------------------------------*
*& Report         : ZPP_FORECAST_PAINTS        Transaction: ZFCST_PAINTS
*& Title          : ZFORECAST (Paints) - forecast generation
*& Project        : KPMG / Astral UDAY            Module: PP
*& Related FS     : Forecast_Template-Paints_1.xlsx (WRICEF ID-2B),
*&                  received 19.10.2026, Sheet1 taken as the authority
*& Author         : Arnav Johri                   Date: 19.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Paints counterpart of ZPP_FORECAST (Adhesive). Same three planning
*&   modes, same selection screen, same engine - ZCL_PP_FCST generates
*&   and saves, ZCL_PP_FCST_UTIL checks - and the same tables. Nothing on
*&   the Adhesive side is changed. ZCL_PP_FCST_PNT adds the Paints
*&   columns: plant name, brand, pack size, DPL, qty per carton, gross
*&   weight, volume in KL and value in crores per month, and tonnage on
*&   gross weight. The list is laid out as Sheet1 of the Paints FS; the
*&   Adhesive working columns stay reachable through Change Layout.
*&   CL_SALV_TABLE full screen, no screen of its own.
*&
*& CHANGE HISTORY
*&   19.10.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zpp_forecast_paints MESSAGE-ID zpp_fcst.

TABLES: marc, sscrfields.

* LVC_T_FNAME is not available in every release, so the column name
* list is typed locally over LVC_FNAME
TYPES tt_fname TYPE STANDARD TABLE OF lvc_fname WITH DEFAULT KEY.

* Switch deciding whether legacy history may be used at all. Read once
* in INITIALIZATION; the Legacy checkbox is drawn only when it is set.
* Sheet1 of the Paints FS draws no Legacy checkbox; with the switch
* blank the screen looks exactly like Sheet1.
DATA g_legc_on TYPE abap_bool.

* ASSUMPTION: the switch is TVARVC parameter ZPP_FCST_LEGACY, value 'X'
* or blank - the same switch ZPP_FORECAST reads. FORM LEGACY_SWITCH is
* the only reader.
CONSTANTS gc_tv_legacy TYPE rvari_vnam VALUE 'ZPP_FCST_LEGACY'.

* GUI status of THIS program carrying ZSAVE, ZSELALL, ZDESEL and ZEXCEL.
* SE41: copy PF_STATUS of ZPP_FORECAST to this program, nothing else.
CONSTANTS gc_status TYPE sypfkey VALUE 'PF_STATUS'.

* Display mode of the list, as in ZPP_FORECAST:
*   abap_false  full screen with GUI status PF_STATUS (SALV_STANDARD plus
*               the four buttons). Toolbar in the application toolbar
*               row, list header in the title bar.
*   abap_true   container on CL_GUI_CONTAINER=>DEFAULT_SCREEN, buttons
*               added with ADD_FUNCTION, no status needed - toolbar one
*               row lower inside the grid.
* DATA and not CONSTANTS, so the compiler does not fold the IF.
DATA gv_container TYPE abap_bool VALUE abap_false.

DATA: gt_msg  TYPE bapiret2_t,
      gt_show TYPE tt_fname,          " columns drawn, in order
      gt_opt  TYPE tt_fname,          " columns hidden, reachable via layout
      gt_eng  TYPE zcl_pp_fcst=>tt_alv,      " what the engine returned
      gt_alv  TYPE zcl_pp_fcst_pnt=>tt_alv,  " what is displayed
      go_fcst TYPE REF TO zcl_pp_fcst,
      go_pnt  TYPE REF TO zcl_pp_fcst_pnt,
      go_alv  TYPE REF TO cl_salv_table,
      g_mode  TYPE char1,
*     The quarter actually being planned - P_QUART when typed, worked out
*     from the date range when not, so headings and generation agree.
      g_quart TYPE zde_quarter.

*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-b00.
PARAMETERS: p_ann RADIOBUTTON GROUP mod USER-COMMAND md DEFAULT 'X',
            p_qtr RADIOBUTTON GROUP mod,
            p_mth RADIOBUTTON GROUP mod.
SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
* Plant and financial year are NOT declared OBLIGATORY. A mandatory field
* is checked on every PAI, including the click on a mode radio button,
* which looks like the screen refusing to change mode. Checked by hand
* on Execute instead.
SELECT-OPTIONS: s_werks FOR marc-werks,
                s_matnr FOR marc-matnr.
PARAMETERS: p_fyear TYPE zde_fyear,
            p_quart TYPE zde_quarter MODIF ID qtr,
            p_perio TYPE poper       MODIF ID mth.
SELECT-OPTIONS: s_datum FOR sy-datum NO-EXTENSION MODIF ID dat.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
* Tonnage Wise - on gross weight for Paints. Legacy carries MODIF ID LGC
* so it can be hidden when the switch is off.
PARAMETERS: p_tonn AS CHECKBOX,
            p_legc AS CHECKBOX MODIF ID lgc.
SELECTION-SCREEN END OF BLOCK b2.


*&---------------------------------------------------------------------*
*& Toolbar handler - Save, Select all, Deselect all, Export
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS on_added_function
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.

  PRIVATE SECTION.

    CLASS-METHODS save_selected.
    CLASS-METHODS select_all
      IMPORTING iv_on TYPE abap_bool.
    CLASS-METHODS export.
    CLASS-METHODS show_result.
    CLASS-METHODS result_message
      IMPORTING it_msg TYPE bapiret2_t.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_added_function.

*   Every function code of the GUI status arrives here. Anything not
*   listed is ignored.
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
        LEAVE TO SCREEN 0.

      WHEN OTHERS.
        RETURN.

    ENDCASE.

  ENDMETHOD.


  METHOD save_selected.

    DATA: lv_row TYPE i,
          lv_ix  TYPE i,
          lt_eng TYPE zcl_pp_fcst=>tt_alv,
          ls_eng TYPE zcl_pp_fcst=>ty_alv.

    FIELD-SYMBOLS <ls> TYPE zcl_pp_fcst_pnt=>ty_alv.

    DATA(lt_rows) = go_alv->get_selections( )->get_selected_rows( ).

    IF lt_rows IS INITIAL.
      MESSAGE s017 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT gt_alv ASSIGNING <ls>.
      <ls>-mark = abap_false.
    ENDLOOP.

    LOOP AT lt_rows INTO lv_row.
      READ TABLE gt_alv ASSIGNING <ls> INDEX lv_row.
      IF sy-subrc = 0.
        <ls>-mark = abap_true.
      ENDIF.
    ENDLOOP.

*   SAVE takes the engine's own row type. The displayed rows carry it as
*   their first part, so they are handed over row for row - and the
*   Paints tonnage (gross weight) goes with them into M4_TON..M6_TON.
    CLEAR lt_eng.
    LOOP AT gt_alv ASSIGNING <ls>.
      CLEAR ls_eng.
      MOVE-CORRESPONDING <ls> TO ls_eng.
      APPEND ls_eng TO lt_eng.
    ENDLOOP.

    DATA(lt_msg) = go_fcst->save( EXPORTING iv_mode = g_mode
                                  CHANGING  ct_alv  = lt_eng ).

*   The number and the per row outcome come back row for row
    LOOP AT lt_eng INTO ls_eng.
      lv_ix = sy-tabix.
      READ TABLE gt_alv ASSIGNING <ls> INDEX lv_ix.
      IF sy-subrc = 0.
        <ls>-fcst_no = ls_eng-fcst_no.
        <ls>-light   = ls_eng-light.
        <ls>-status  = ls_eng-status.
        <ls>-message = ls_eng-message.
      ENDIF.
    ENDLOOP.

    show_result( ).
    go_alv->refresh( ).
    result_message( lt_msg ).

  ENDMETHOD.


  METHOD show_result.

*   Forecast number and message are hidden while the list is only a
*   proposal. Once Save has run they come out of hiding at the end.
    DATA: lv_col TYPE lvc_fname,
          lv_pos TYPE i,
          lt_res TYPE tt_fname.

    CHECK go_alv IS BOUND.

    DATA(lo_cols) = go_alv->get_columns( ).

    APPEND 'FCST_NO' TO lt_res.
    APPEND 'MESSAGE' TO lt_res.

    LOOP AT lt_res INTO lv_col.

      READ TABLE gt_show TRANSPORTING NO FIELDS
        WITH KEY table_line = lv_col.

      IF sy-subrc = 0.
*       Already there from an earlier Save - keep its slot
        lv_pos = sy-tabix.
      ELSE.
        APPEND lv_col TO gt_show.
        lv_pos = lines( gt_show ).
      ENDIF.

      TRY.
          lo_cols->get_column( lv_col )->set_technical( abap_false ).
          lo_cols->get_column( lv_col )->set_visible( abap_true ).
          lo_cols->set_column_position( columnname = lv_col
                                        position   = lv_pos ).
        CATCH cx_salv_error.
      ENDTRY.

    ENDLOOP.

  ENDMETHOD.


  METHOD result_message.

    DATA: lv_err TYPE i,
          lv_n   TYPE char10,
          lv_txt TYPE string.

    LOOP AT it_msg INTO DATA(ls_msg).
      IF ls_msg-type CA 'AEX'.
        lv_err = lv_err + 1.
      ENDIF.
    ENDLOOP.

    IF lv_err = 0.
      lv_txt = 'Save completed'.
      MESSAGE lv_txt TYPE 'S'.
    ELSE.
      lv_n = lv_err.
      CONDENSE lv_n.
      CONCATENATE 'Save completed,' lv_n 'row(s) not saved'
             INTO lv_txt SEPARATED BY space.
      MESSAGE lv_txt TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.

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

*   Only the columns the list is showing, in the order it shows them
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

    CONCATENATE 'ZFORECAST_PAINTS_' g_mode '.txt' INTO lv_file.

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

ENDCLASS.


*&---------------------------------------------------------------------*
INITIALIZATION.

  " Financial year containing today, April to March
  DATA(gv_y) = CONV i( sy-datum(4) ).
  IF sy-datum+4(2) < '04'.
    gv_y = gv_y - 1.
  ENDIF.
  p_fyear = |{ gv_y }-{ gv_y + 1 }|.

  PERFORM legacy_switch CHANGING g_legc_on.
  IF g_legc_on = abap_false.
    CLEAR p_legc.
  ENDIF.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'QTR'. screen-active = COND #( WHEN p_qtr = abap_true THEN 1 ELSE 0 ).
      WHEN 'MTH'. screen-active = COND #( WHEN p_mth = abap_true THEN 1 ELSE 0 ).
      WHEN 'DAT'. screen-active = COND #( WHEN p_ann = abap_true THEN 0 ELSE 1 ).
      WHEN 'LGC'. screen-active = COND #( WHEN g_legc_on = abap_true THEN 1 ELSE 0 ).
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

* Clicking a mode radio button raises PAI. Only the mode switch is
* skipped, so a background run with a blank function code is validated.
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

* INITIALIZATION runs BEFORE a selection screen variant is transferred,
* so the CLEAR there loses to a variant carrying Legacy ticked. Here it
* runs last, in background and under SUBMIT too.
  IF g_legc_on = abap_false.
    CLEAR p_legc.
  ENDIF.

  PERFORM generate.

* Always written, whether the run produced rows or not
  PERFORM save_log.

  IF gt_alv IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  PERFORM display.


*&---------------------------------------------------------------------*
*& Legacy switch - 'X' means legacy history is loaded and may be used,
*& blank means the checkbox is not drawn at all.
*&---------------------------------------------------------------------*
FORM legacy_switch CHANGING cv_on TYPE abap_bool.

  CLEAR cv_on.

  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_low)
    WHERE name = @gc_tv_legacy
      AND type = 'P'
      AND numb = '0000'.

  IF sy-subrc = 0 AND lv_low IS NOT INITIAL.
    cv_on = abap_true.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Application log - SLG1, object ZPP_FCST subobject GENERATE, the same
*& log object as the Adhesive run. If it does not exist in SLG0 the run
*& carries on without a log rather than failing.
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
  ls_log-extnumber = |PAINTS { g_mode } { p_fyear } { sy-uname }|.

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
*& Generate: the Adhesive engine runs unchanged, then the Paints class
*& adds its columns to a copy of the result.
*&---------------------------------------------------------------------*
FORM generate.

  DATA: lt_msg TYPE bapiret2_t,
        ls_eng TYPE zcl_pp_fcst=>ty_alv,
        ls_alv TYPE zcl_pp_fcst_pnt=>ty_alv.

  CLEAR: gt_eng, gt_alv, gt_msg.
  CREATE OBJECT go_fcst.
  CREATE OBJECT go_pnt.

  g_mode = COND #( WHEN p_ann = abap_true THEN zcl_pp_fcst=>gc_mode-annual
                   WHEN p_qtr = abap_true THEN zcl_pp_fcst=>gc_mode-quarterly
                   ELSE                        zcl_pp_fcst=>gc_mode-monthly ).

  PERFORM resolve_quarter.

  CASE g_mode.

    WHEN zcl_pp_fcst=>gc_mode-annual.
      go_fcst->generate_annual( EXPORTING ir_werks   = s_werks[]
                                          ir_matnr   = s_matnr[]
                                          iv_fyear   = p_fyear
                                          iv_legacy  = p_legc
                                          iv_tonnage = p_tonn
                                IMPORTING et_alv     = gt_eng
                                          et_msg     = lt_msg ).

    WHEN zcl_pp_fcst=>gc_mode-quarterly.
      go_fcst->generate_quarterly( EXPORTING ir_werks   = s_werks[]
                                             ir_matnr   = s_matnr[]
                                             iv_fyear   = p_fyear
                                             iv_quarter = g_quart
                                             iv_legacy  = p_legc
                                             iv_tonnage = p_tonn
                                   IMPORTING et_alv     = gt_eng
                                             et_msg     = lt_msg ).

    WHEN zcl_pp_fcst=>gc_mode-monthly.
      go_fcst->generate_monthly( EXPORTING ir_werks   = s_werks[]
                                           ir_matnr   = s_matnr[]
                                           iv_fyear   = p_fyear
                                           iv_period  = p_perio
                                           iv_legacy  = p_legc
                                           iv_tonnage = p_tonn
                                 IMPORTING et_alv     = gt_eng
                                           et_msg     = lt_msg ).
  ENDCASE.

  gt_msg = lt_msg.

* The engine's rows, widened by the Paints columns. Row for row rather
* than a whole-table MOVE-CORRESPONDING.
  LOOP AT gt_eng INTO ls_eng.
    CLEAR ls_alv.
    MOVE-CORRESPONDING ls_eng TO ls_alv.
    APPEND ls_alv TO gt_alv.
  ENDLOOP.

  CHECK gt_alv IS NOT INITIAL.

  go_pnt->enrich( EXPORTING iv_mode = g_mode
                  CHANGING  ct_alv  = gt_alv
                            ct_msg  = gt_msg ).

ENDFORM.


*&---------------------------------------------------------------------*
FORM display.

  TRY.
      IF gv_container = abap_true.
        cl_salv_table=>factory( EXPORTING r_container  = cl_gui_container=>default_screen
                                IMPORTING r_salv_table = go_alv
                                CHANGING  t_table      = gt_alv ).
      ELSE.
        cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                                CHANGING  t_table      = gt_alv ).
      ENDIF.

      "--- toolbar -------------------------------------------------------
      go_alv->get_functions( )->set_all( ).

*     Layout key, so Save / Select layout work. The mode is the handle:
*     the three modes have different column sets. SY-REPID keeps the
*     Paints layouts apart from the Adhesive ones.
      DATA(ls_lkey) = VALUE salv_s_layout_key( report = sy-repid
                                               handle = g_mode ).
      go_alv->get_layout( )->set_key( ls_lkey ).
      go_alv->get_layout( )->set_save_restriction( if_salv_c_layout=>restrict_none ).
      go_alv->get_layout( )->set_default( abap_true ).

      DATA(lv_save_ok) = abap_true.

      LOOP AT s_werks INTO DATA(ls_w2).
        IF zcl_pp_fcst_util=>check_authority( iv_werks = ls_w2-low
                                              iv_actvt = '01' ) = abap_false.
          lv_save_ok = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF gv_container = abap_true.

        DATA(lo_fn) = go_alv->get_functions( ).

        IF lv_save_ok = abap_true.
          lo_fn->add_function(
            name     = 'ZSAVE'
            icon     = CONV string( icon_system_save )
            text     = 'Save'
            tooltip  = 'Save the selected rows'
            position = if_salv_c_function_position=>right_of_salv_functions ).
        ENDIF.

        lo_fn->add_function(
          name     = 'ZSELALL'
          icon     = CONV string( icon_select_all )
          text     = 'Select all'
          tooltip  = 'Select every row'
          position = if_salv_c_function_position=>right_of_salv_functions ).

        lo_fn->add_function(
          name     = 'ZDESEL'
          icon     = CONV string( icon_deselect_all )
          text     = 'Deselect all'
          tooltip  = 'Clear the selection'
          position = if_salv_c_function_position=>right_of_salv_functions ).

        lo_fn->add_function(
          name     = 'ZEXCEL'
          icon     = CONV string( icon_xls )
          text     = 'Export'
          tooltip  = 'Save the list as a tab separated file'
          position = if_salv_c_function_position=>right_of_salv_functions ).

      ELSEIF lv_save_ok = abap_true.

*       Full screen: the GUI status of this program carries the four
*       buttons on top of the standard functions it was copied with.
*       Without save authority no status is set and SALV's own standard
*       status serves the list, buttons absent.
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
      PERFORM visible_columns CHANGING gt_show gt_opt.
      PERFORM setup_columns   USING    gt_show gt_opt.

      DATA(lv_head) = |Paints { SWITCH string( g_mode
                                               WHEN 'A' THEN 'Annual'
                                               WHEN 'Q' THEN 'Quarterly'
                                               ELSE          'Monthly' ) }| &&
                      | Forecast - { p_fyear }|.

      go_alv->get_display_settings( )->set_list_header( CONV lvc_title( lv_head ) ).

      IF gv_container = abap_true.
        go_alv->display( ).
        WRITE: space.
      ELSE.
*       SALV resolves the status when it draws the list, so a status it
*       cannot find surfaces here; redrawn with SALV's own standard
*       status instead of dumping, and the user is told.
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
      ENDIF.

    CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error
          cx_salv_existing cx_salv_wrong_call
          cx_salv_object_not_found INTO DATA(lx_salv).
      DATA(lv_err) = lx_salv->get_text( ).
      MESSAGE lv_err TYPE 'E'.
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
*& Columns of the chosen mode, laid out as Sheet1 of the Paints FS.
*&
*& CT_SHOW  drawn, in this order.
*& CT_OPT   not drawn, but offered by Change Layout - the Adhesive
*&          working columns (history months, category, growth, material
*&          groups 3 and 4, net weight, unit) the Paints sheet does not
*&          show. Everything else is set technical.
*&---------------------------------------------------------------------*
FORM visible_columns CHANGING ct_show TYPE tt_fname
                              ct_opt  TYPE tt_fname.

  DATA: lv_p TYPE numc2,
        lv_q TYPE i,
        lv_m TYPE i.

  CLEAR: ct_show, ct_opt.

* ---- leading block, Sheet1 columns A to M on all three sheets --------
  APPEND 'WERKS'      TO ct_show.   " MFG. PLANT CODE
  APPEND 'NAME1'      TO ct_show.   " MFG. PLANT NAME
  APPEND 'BRAND'      TO ct_show.   " BRAND
  APPEND 'MATNR'      TO ct_show.   " MAT. CODE
  APPEND 'MAKTX'      TO ct_show.   " MAT. DESC
  APPEND 'MTS_MTO'    TO ct_show.   " MTS / MTO / DIS ART / TINTING
  APPEND 'MVGR1_TXT'  TO ct_show.   " MATERIAL GROUP 1
  APPEND 'MVGR2_TXT'  TO ct_show.   " MATERIAL GROUP 2
  APPEND 'MVGR5_TXT'  TO ct_show.   " MATERIAL GROUP 5
  APPEND 'MATKL'      TO ct_show.   " MATERIAL GROUP
  APPEND 'PACK_SIZE'  TO ct_show.   " PACK SIZE
  APPEND 'PRICE'      TO ct_show.   " DPL
  APPEND 'QTY_CARTON' TO ct_show.   " QTY / CARTON

* ---- reachable through Change Layout on every mode ------------------
  APPEND 'PACK_UNIT'  TO ct_opt.
  APPEND 'MVGR3_TXT'  TO ct_opt.
  APPEND 'MVGR4_TXT'  TO ct_opt.
  APPEND 'MEINS'      TO ct_opt.
  APPEND 'NTGEW'      TO ct_opt.
  APPEND 'GEWEI'      TO ct_opt.
  APPEND 'PROD_CAT'   TO ct_opt.
  APPEND 'LOAD_FCT'   TO ct_opt.

  CASE g_mode.

*   ---- Sheet1 row 24: twelve forecast months, twelve KL, twelve crore -
    WHEN zcl_pp_fcst=>gc_mode-annual.

      DO 12 TIMES.
        lv_p = sy-index.
        APPEND CONV lvc_fname( |M{ lv_p }_FCST| ) TO ct_show.
      ENDDO.

      DO 12 TIMES.
        lv_p = sy-index.
        APPEND CONV lvc_fname( |M{ lv_p }_KL| ) TO ct_show.
      ENDDO.

      DO 12 TIMES.
        lv_p = sy-index.
        APPEND CONV lvc_fname( |M{ lv_p }_CR| ) TO ct_show.
      ENDDO.

*     Tonnage Wise with Gross Weight - RADIO BUTTON 1 ANNUAL row 75
      IF p_tonn = abap_true.
        APPEND 'BRGEW' TO ct_show.
        DO 12 TIMES.
          lv_p = sy-index.
          APPEND CONV lvc_fname( |M{ lv_p }_TON| ) TO ct_show.
        ENDDO.
      ELSE.
        APPEND 'BRGEW' TO ct_opt.
      ENDIF.

*     The Adhesive working columns, not drawn on Sheet1 (query M7)
      DO 12 TIMES.
        lv_p = sy-index.
        APPEND CONV lvc_fname( |M{ lv_p }| ) TO ct_opt.
      ENDDO.
      APPEND 'LY_TOTAL'   TO ct_opt.
      APPEND 'FCST_TOTAL' TO ct_opt.

*   ---- Sheet1 row 50 ------------------------------------------------
    WHEN zcl_pp_fcst=>gc_mode-quarterly.

      APPEND 'M4_LAST'    TO ct_show.   " July'25
      APPEND 'M5_LAST'    TO ct_show.   " Aug'25
      APPEND 'M6_LAST'    TO ct_show.   " Sep'25
      APPEND 'LY_QTR_TOT' TO ct_show.   " Total LY Quarter Sales Qty
      APPEND 'M1_CURR'    TO ct_show.   " April'26
      APPEND 'M2_CURR'    TO ct_show.   " May'26
      APPEND 'M3_CURR'    TO ct_show.   " Jun'26
      APPEND 'L3M_TOT'    TO ct_show.   " L3 Month Total Sales Qty
      APPEND 'MAX_QTY'    TO ct_show.   " Max. Qty (E, I)
      APPEND 'PROD_CAT'   TO ct_show.   " Product Cat.
      APPEND 'LOAD_FCT'   TO ct_show.   " Growth Based on Category
      APPEND 'FCST_QTY'   TO ct_show.   " Forecast (Max * Growth %)
      APPEND 'BUS_FCST'   TO ct_show.   " Business Forecast
      APPEND 'FINAL_QTY'  TO ct_show.   " Final Forecast Qty

*     Month by month: forecast, additional, final, KL, crores, and the
*     tonnage when ticked - RADIO BUTTON 1 ANNUAL row 125 fills in what
*     Sheet1 abbreviates to "Final july 26 in KL".
      DO 3 TIMES.
        lv_q = sy-index.        " 1, 2, 3 - the additional plan columns
        lv_m = lv_q + 3.        " 4, 5, 6 - the Mn_ columns
        APPEND CONV lvc_fname( |M{ lv_m }_FCST| )       TO ct_show.
        APPEND CONV lvc_fname( |BUS_FCST_ADD{ lv_q }| ) TO ct_show.
        APPEND CONV lvc_fname( |M{ lv_m }_FCST_FINAL| ) TO ct_show.
        APPEND CONV lvc_fname( |M{ lv_m }_KL| )         TO ct_show.
        APPEND CONV lvc_fname( |M{ lv_m }_CR| )         TO ct_show.
        IF p_tonn = abap_true.
          APPEND CONV lvc_fname( |M{ lv_m }_TON| )      TO ct_show.
        ENDIF.
      ENDDO.

      IF p_tonn = abap_true.
        APPEND 'BRGEW' TO ct_show.
      ELSE.
        APPEND 'BRGEW' TO ct_opt.
      ENDIF.

*     PROD_CAT and LOAD_FCT are drawn here, so they leave the optional list
      DELETE ct_opt WHERE table_line = 'PROD_CAT' OR table_line = 'LOAD_FCT'.
      APPEND 'TOTAL_VAL' TO ct_opt.

*   ---- Sheet1 row 88 ------------------------------------------------
    WHEN zcl_pp_fcst=>gc_mode-monthly.

      APPEND 'M4_LAST'      TO ct_show.   " July'25
      APPEND 'M5_LAST'      TO ct_show.   " Aug'25
      APPEND 'M6_LAST'      TO ct_show.   " Sep'25
      APPEND 'LY_QTR_TOT'   TO ct_show.   " Total LY Quarter Sales Qty
      APPEND 'M1_CURR'      TO ct_show.   " April'26
      APPEND 'M2_CURR'      TO ct_show.   " May'26
      APPEND 'M3_CURR'      TO ct_show.   " Jun'26
      APPEND 'L3M_TOT'      TO ct_show.   " L3 Month Total Sales Qty
      APPEND 'MAX_QTY'      TO ct_show.   " Max. Qty (E, I)
      APPEND 'PROD_CAT'     TO ct_show.   " Product Cat.
      APPEND 'LOAD_FCT'     TO ct_show.   " Growth Based on Category
      APPEND 'FCST_QTY'     TO ct_show.   " Forecast (Max * Growth %)
      APPEND 'BUS_FCST'     TO ct_show.   " Business Forecast
      APPEND 'FINAL_QTY'    TO ct_show.   " Final Forecast Qty
      APPEND 'BUS_FCST_ADD' TO ct_show.   " additional (change upload)
      APPEND 'TOTAL_QTY'    TO ct_show.   " July'26 - final incl. additional
      APPEND 'M4_KL'        TO ct_show.   " Final july 26 in KL
      APPEND 'M4_CR'        TO ct_show.   " July'26 in Cr (query Q3)

      IF p_tonn = abap_true.
        APPEND 'M4_TON' TO ct_show.
        APPEND 'BRGEW'  TO ct_show.
      ELSE.
        APPEND 'BRGEW'  TO ct_opt.
      ENDIF.

      DELETE ct_opt WHERE table_line = 'PROD_CAT' OR table_line = 'LOAD_FCT'.
      APPEND 'L3M_AVG' TO ct_opt.
      APPEND 'MSL'     TO ct_opt.
      APPEND 'M4_VAL'  TO ct_opt.

  ENDCASE.

* FCST_NO and MESSAGE stay hidden until Save has run - SHOW_RESULT brings
* them out. They are optional here so SALV knows them.
  APPEND 'FCST_NO' TO ct_opt.
  APPEND 'MESSAGE' TO ct_opt.

ENDFORM.


*&---------------------------------------------------------------------*
FORM setup_columns USING pt_show TYPE tt_fname
                         pt_opt  TYPE tt_fname.

  DATA: lv_col TYPE lvc_fname,
        lv_hdr TYPE string,
        lv_nam TYPE char3,
        lv_pos TYPE i.

  DATA(lo_cols) = go_alv->get_columns( ).
  lo_cols->set_optimize( ).

* ---- hide what does not belong to this mode --------------------------
* LOOP AT over a functional call iterates zero times in this release,
* so the result is put in a variable first.
  DATA(lt_cols) = lo_cols->get( ).

  LOOP AT lt_cols INTO DATA(ls_col).

    READ TABLE pt_show TRANSPORTING NO FIELDS
      WITH KEY table_line = ls_col-columnname.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    READ TABLE pt_opt TRANSPORTING NO FIELDS
      WITH KEY table_line = ls_col-columnname.

    TRY.
        IF sy-subrc = 0.
*         Not drawn, but there for Change Layout
          ls_col-r_column->set_visible( abap_false ).
        ELSE.
          ls_col-r_column->set_technical( abap_true ).
        ENDIF.
      CATCH cx_salv_error.
    ENDTRY.

  ENDLOOP.

* ---- display order --------------------------------------------------
  lv_pos = 0.
  LOOP AT pt_show INTO lv_col.
    lv_pos = lv_pos + 1.
    TRY.
        lo_cols->set_column_position( columnname = lv_col
                                      position   = lv_pos ).
      CATCH cx_salv_error.
    ENDTRY.
  ENDLOOP.

* ---- headings, Sheet1 wording ----------------------------------------
  PERFORM txt USING 'WERKS'      'Mfg. Plant Code'.
  PERFORM txt USING 'NAME1'      'Mfg. Plant Name'.
  PERFORM txt USING 'BRAND'      'Brand'.
  PERFORM txt USING 'MATNR'      'Mat. Code'.
  PERFORM txt USING 'MAKTX'      'Mat. Desc'.
  PERFORM txt USING 'MTS_MTO'    'MTS / MTO / Dis Art / Tinting'.
  PERFORM txt USING 'MVGR1_TXT'  'Material Group 1'.
  PERFORM txt USING 'MVGR2_TXT'  'Material Group 2'.
  PERFORM txt USING 'MVGR3_TXT'  'Material Group 3'.
  PERFORM txt USING 'MVGR4_TXT'  'Material Group 4'.
  PERFORM txt USING 'MVGR5_TXT'  'Material Group 5'.
  PERFORM txt USING 'MATKL'      'Material Group'.
  PERFORM txt USING 'PACK_SIZE'  'Pack Size'.
  PERFORM txt USING 'PACK_UNIT'  'Pack Unit'.
  PERFORM txt USING 'PRICE'      'DPL'.
  PERFORM txt USING 'QTY_CARTON' 'Qty / Carton'.
  PERFORM txt USING 'BRGEW'      'Gross Weight'.
  PERFORM txt USING 'NTGEW'      'Net Weight'.
  PERFORM txt USING 'GEWEI'      'Weight Unit'.
  PERFORM txt USING 'MEINS'      'Unit'.
  PERFORM txt USING 'PROD_CAT'   'Product Cat.'.
  PERFORM txt USING 'LOAD_FCT'   'Growth Based on Category'.
  PERFORM txt USING 'FCST_NO'    'Forecast Number'.
  PERFORM txt USING 'MESSAGE'    'Message'.

  IF g_mode = zcl_pp_fcst=>gc_mode-annual.
    PERFORM annual_headings.
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
    PERFORM txt USING 'MAX_QTY'      'Max. Qty (E, I)'.
    PERFORM txt USING 'FCST_QTY'     'Forecast (Max * Growth %)'.
    PERFORM txt USING 'BUS_FCST'     'Business Forecast'.
    PERFORM txt USING 'FINAL_QTY'    'Final Forecast Qty'.
    PERFORM txt USING 'BUS_FCST_ADD' 'Additional Plan Qty'.
    PERFORM txt USING 'TOTAL_QTY'    'Final Fcst Qty incl. Additional'.
    PERFORM txt USING 'MSL'          'MSL'.
    PERFORM txt USING 'TOTAL_VAL'    'Final Fcst Qty x DPL'.
    PERFORM txt USING 'M4_VAL'       'Final Fcst Qty x DPL'.
    PERFORM txt USING 'M4_FCST'      'Month 1'.
    PERFORM txt USING 'M5_FCST'      'Month 2'.
    PERFORM txt USING 'M6_FCST'      'Month 3'.
*   The calendar months behind the columns, when the quarter is known
    PERFORM month_headings.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Annual headings from the financial calendar - Sheet1 writes each
*& forecast column as "Q1_26-27_APR 26_FORECAST QTY (EA)"
*&---------------------------------------------------------------------*
FORM annual_headings.

  DATA: lv_col TYPE lvc_fname,
        lv_hdr TYPE string,
        lv_nam TYPE char3,
        lv_p   TYPE numc2,
        lv_q   TYPE zde_quarter,
        lv_yy  TYPE gjahr,
        lv_mm  TYPE numc2.

  DATA(lv_prev) = zcl_pp_fcst_util=>previous_fyear( p_fyear ).

  DO 12 TIMES.

    lv_p = sy-index.
    lv_q = zcl_pp_fcst_util=>period_to_quarter( lv_p ).

*   Last year's month - the optional history columns
    zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = lv_prev
                                                     iv_period = lv_p
                                           IMPORTING ev_gjahr  = lv_yy
                                                     ev_month  = lv_mm ).
    PERFORM month_name USING lv_mm CHANGING lv_nam.
    lv_col = |M{ lv_p }|.
    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } LY Sales Qty|.
    PERFORM txt USING lv_col lv_hdr.

*   The forecast month
    zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = p_fyear
                                                     iv_period = lv_p
                                           IMPORTING ev_gjahr  = lv_yy
                                                     ev_month  = lv_mm ).
    PERFORM month_name USING lv_mm CHANGING lv_nam.

    lv_col = |M{ lv_p }_FCST|.
    lv_hdr = |Q{ lv_q } { lv_nam }-{ lv_yy+2(2) } Forecast Qty|.
    PERFORM txt USING lv_col lv_hdr.

    lv_col = |M{ lv_p }_KL|.
    lv_hdr = |Q{ lv_q } { lv_nam }-{ lv_yy+2(2) } Volume in KL|.
    PERFORM txt USING lv_col lv_hdr.

    lv_col = |M{ lv_p }_CR|.
    lv_hdr = |Q{ lv_q } { lv_nam }-{ lv_yy+2(2) } Value in Crores|.
    PERFORM txt USING lv_col lv_hdr.

    lv_col = |M{ lv_p }_TON|.
    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } Tonnage|.
    PERFORM txt USING lv_col lv_hdr.

  ENDDO.

  PERFORM txt USING 'LY_TOTAL' 'Total LY Sales Qty'.
  lv_hdr = |Forecast Qty FY{ p_fyear }|.
  PERFORM txt USING 'FCST_TOTAL' lv_hdr.

ENDFORM.


*&---------------------------------------------------------------------*
*& The quarter actually being planned - P_QUART when typed, otherwise
*& the quarter of the first date of the range
*&---------------------------------------------------------------------*
FORM resolve_quarter.

  DATA: lv_month TYPE numc2,
        lv_per   TYPE numc2,
        lv_date  TYPE dats.

  CLEAR g_quart.

  CASE g_mode.

    WHEN zcl_pp_fcst=>gc_mode-quarterly.

      IF p_quart IS NOT INITIAL.
        g_quart = p_quart.
        RETURN.
      ENDIF.

      READ TABLE s_datum INTO DATA(ls_dt) INDEX 1.
      CHECK sy-subrc = 0.

      lv_date = ls_dt-low.
      CHECK lv_date IS NOT INITIAL.

      lv_month = lv_date+4(2).
      lv_per   = zcl_pp_fcst_util=>month_to_period( lv_month ).
      g_quart  = zcl_pp_fcst_util=>period_to_quarter( lv_per ).

    WHEN zcl_pp_fcst=>gc_mode-monthly.

      CHECK p_perio IS NOT INITIAL.
      lv_per  = p_perio.
      g_quart = zcl_pp_fcst_util=>period_to_quarter( lv_per ).

  ENDCASE.

ENDFORM.


*&---------------------------------------------------------------------*
*& Calendar month headings for quarter and month based planning -
*& Jul-25, Aug-25, Sep-25 for the comparison quarter, Apr-26 to Jun-26
*& for the three months before the plan, and the planned months with
*& their additional, final, KL, crore and tonnage columns.
*&---------------------------------------------------------------------*
FORM month_headings.

  DATA: lv_nam TYPE char3,
        lv_hdr TYPE string,
        lv_col TYPE lvc_fname,
        lv_ix  TYPE i,
        lv_qi  TYPE i,
        lv_ai  TYPE i,
        lv_per TYPE numc2,
        lv_yy  TYPE gjahr,
        lv_mm  TYPE numc2.

  CHECK g_quart IS NOT INITIAL.

* ---- last year, the same quarter -------------------------------------
  DATA(lt_ly) = zcl_pp_fcst_util=>last_year_quarter( iv_fyear   = p_fyear
                                                     iv_quarter = g_quart ).

  lv_ix = 3.
  LOOP AT lt_ly INTO DATA(ls_ly).
    lv_ix  = lv_ix + 1.
    lv_yy  = ls_ly-gjahr.
    lv_mm  = ls_ly-month.
    PERFORM month_name USING lv_mm CHANGING lv_nam.
    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
    lv_col = |M{ lv_ix }_LAST|.
    PERFORM txt USING lv_col lv_hdr.
  ENDLOOP.

  lv_hdr = |Total LY Q{ g_quart } Sales Qty|.
  PERFORM txt USING 'LY_QTR_TOT' lv_hdr.

* ---- the three months immediately before the plan --------------------
  IF g_mode = zcl_pp_fcst=>gc_mode-monthly.
    lv_per = p_perio.
  ELSE.
    lv_qi  = g_quart.
    lv_per = ( lv_qi - 1 ) * 3 + 1.
  ENDIF.

  DATA(lt_l3m) = zcl_pp_fcst_util=>last_three_months( iv_fyear  = p_fyear
                                                      iv_period = lv_per ).

  lv_ix = 0.
  LOOP AT lt_l3m INTO DATA(ls_l3).
    lv_ix  = lv_ix + 1.
    lv_yy  = ls_l3-gjahr.
    lv_mm  = ls_l3-month.
    PERFORM month_name USING lv_mm CHANGING lv_nam.
    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
    lv_col = |M{ lv_ix }_CURR|.
    PERFORM txt USING lv_col lv_hdr.
  ENDLOOP.

* ---- the months being planned ----------------------------------------
  IF g_mode = zcl_pp_fcst=>gc_mode-quarterly.

    DATA(lt_qtr) = zcl_pp_fcst_util=>quarter_periods( iv_fyear   = p_fyear
                                                      iv_quarter = g_quart ).

    lv_ix = 3.
    LOOP AT lt_qtr INTO DATA(ls_q).
      lv_ix  = lv_ix + 1.
      lv_ai  = lv_ix - 3.
      lv_yy  = ls_q-gjahr.
      lv_mm  = ls_q-month.
      PERFORM month_name USING lv_mm CHANGING lv_nam.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
      lv_col = |M{ lv_ix }_FCST|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } additional|.
      lv_col = |BUS_FCST_ADD{ lv_ai }|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } final forecast|.
      lv_col = |M{ lv_ix }_FCST_FINAL|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } KL|.
      lv_col = |M{ lv_ix }_KL|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } in Cr|.
      lv_col = |M{ lv_ix }_CR|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } tonnage|.
      lv_col = |M{ lv_ix }_TON|.
      PERFORM txt USING lv_col lv_hdr.
    ENDLOOP.

  ELSE.

*   Month based planning forecasts one month, drawn in the M4 columns
    lv_per = p_perio.
    zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = p_fyear
                                                     iv_period = lv_per
                                           IMPORTING ev_gjahr  = lv_yy
                                                     ev_month  = lv_mm ).
    PERFORM month_name USING lv_mm CHANGING lv_nam.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } additional|.
    PERFORM txt USING 'BUS_FCST_ADD' lv_hdr.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } final forecast|.
    PERFORM txt USING 'TOTAL_QTY' lv_hdr.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } KL|.
    PERFORM txt USING 'M4_KL' lv_hdr.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } in Cr|.
    PERFORM txt USING 'M4_CR' lv_hdr.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } tonnage|.
    PERFORM txt USING 'M4_TON' lv_hdr.

  ENDIF.

ENDFORM.


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
*& Value helps - financial year, quarter and period are custom types
*& with no check table, so each is built by hand and shows the real
*& calendar months behind the code.
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

* Five back and five forward
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
* output length. The width is set from the heading so the long text is
* chosen, and set_optimize then widens further where the data needs it.
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
