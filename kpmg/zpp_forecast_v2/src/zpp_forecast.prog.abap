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

*BOC By Arnav on 03/09/26
* Switch deciding whether legacy history may be used at all. Read once
* in INITIALIZATION; the Legacy checkbox is drawn only when it is set.
DATA g_legc_on TYPE abap_bool.

* ASSUMPTION: the switch is TVARVC parameter ZPP_FCST_LEGACY, value 'X'
* or blank. FORM LEGACY_SWITCH is the only reader, so the source can be
* swapped there alone.
CONSTANTS gc_tv_legacy TYPE rvari_vnam VALUE 'ZPP_FCST_LEGACY'.
*EOC By Arnav on 03/09/26

* GUI status of THIS program carrying ZSAVE, ZSELALL, ZDESEL and ZEXCEL.
* Change here only - it is used to set the status and to report it when
* it cannot be found.
CONSTANTS gc_status TYPE sypfkey VALUE 'PF_STATUS'.

DATA: gt_msg  TYPE bapiret2_t,
      gt_show TYPE tt_fname,
      gt_alv  TYPE zcl_pp_fcst=>tt_alv,
      go_fcst TYPE REF TO zcl_pp_fcst,
      go_alv  TYPE REF TO cl_salv_table,
      g_mode  TYPE char1,
*BOC By Arnav on 31/08/26
*     The quarter actually being planned. It is P_QUART when a quarter
*     was typed and is worked out from the date range when one was not,
*     so the column headings and the generation always agree.
      g_quart TYPE zde_quarter.
*EOC By Arnav on 31/08/26

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
*BOC By Arnav on 03/09/26
*PARAMETERS: p_tonn AS CHECKBOX,
*            p_legc AS CHECKBOX,
*            p_save AS CHECKBOX.
* Save is the toolbar button only - no checkbox and no confirm popup.
* Legacy carries MODIF ID LGC so it can be hidden when the switch is off.
PARAMETERS: p_tonn AS CHECKBOX,
            p_legc AS CHECKBOX MODIF ID lgc.
*EOC By Arnav on 03/09/26
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
*BOC By Arnav on 03/09/26
    CLASS-METHODS show_result.
    CLASS-METHODS result_message
      IMPORTING it_msg TYPE bapiret2_t.
*EOC By Arnav on 03/09/26

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

*BOC By Arnav on 03/09/26
*   show_log( lt_msg ) put the outcome in a popup. One status line
*   instead - the per row result is already in the MESSAGE column.
*   show_log( lt_msg ).
    show_result( ).
    go_alv->refresh( ).
    result_message( lt_msg ).
*EOC By Arnav on 03/09/26

  ENDMETHOD.


*BOC By Arnav on 03/09/26
  METHOD show_result.

*   Forecast number and message are hidden while the list is only a
*   proposal. Once Save has run they are the point of having pressed it,
*   so they come out of hiding at the end of the list.
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
*       Already there from an earlier Save. lines( gt_show ) would hand
*       both columns the same slot on the second press.
        lv_pos = sy-tabix.
      ELSE.
        APPEND lv_col TO gt_show.
        lv_pos = lines( gt_show ).
      ENDIF.

      TRY.
          lo_cols->get_column( lv_col )->set_technical( abap_false ).
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
*EOC By Arnav on 03/09/26


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

*BOC By Arnav on 03/09/26
  PERFORM legacy_switch CHANGING g_legc_on.
  IF g_legc_on = abap_false.
    CLEAR p_legc.
  ENDIF.
*EOC By Arnav on 03/09/26

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'QTR'. screen-active = COND #( WHEN p_qtr = abap_true THEN 1 ELSE 0 ).
      WHEN 'MTH'. screen-active = COND #( WHEN p_mth = abap_true THEN 1 ELSE 0 ).
      WHEN 'DAT'. screen-active = COND #( WHEN p_ann = abap_true THEN 0 ELSE 1 ).
*BOC By Arnav on 03/09/26
      WHEN 'LGC'. screen-active = COND #( WHEN g_legc_on = abap_true THEN 1 ELSE 0 ).
*EOC By Arnav on 03/09/26
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

*BOC By Arnav on 03/09/26
* INITIALIZATION runs BEFORE a selection screen variant is transferred,
* so the CLEAR there loses to a variant carrying Legacy ticked, and to
* SUBMIT ... WITH p_legc = 'X'. Hiding the checkbox only stops it being
* typed. Re-asserted here, which runs last and in background too.
  IF g_legc_on = abap_false.
    CLEAR p_legc.
  ENDIF.
*EOC By Arnav on 03/09/26

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
*BOC By Arnav on 03/09/26
* IF p_save = abap_true.
*   PERFORM save_all.
* ENDIF.
* The run no longer saves anything by itself.
*EOC By Arnav on 03/09/26

  PERFORM display.

*BOC By Arnav on 31/08/26
* The Save button lives on a GUI status, and this program deliberately
* has none - it is screen free so that the whole object can ship by
* abapGit, and SE41 statuses are not serialised. The button therefore
* never appeared and the user was left with no way of saving from the
* list at all. The question is asked once the list is closed instead.
*BOC By Arnav on 03/09/26
* PERFORM save_prompt.
* The confirm popup is withdrawn - the user presses Save on the toolbar
* if they want to keep the run. FORM SAVE_PROMPT is left in place but is
* no longer called.
*EOC By Arnav on 03/09/26
*EOC By Arnav on 31/08/26


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
*&---------------------------------------------------------------------*
*& Legacy switch - 'X' means legacy history is loaded and may be used,
*& blank means the checkbox is not drawn at all.
*&
*& ASSUMPTION: TVARVC parameter ZPP_FCST_LEGACY (STVARV, Parameters
*& tab). Confirm the variable actually used - this is the only reader.
*&---------------------------------------------------------------------*
*BOC By Arnav on 03/09/26
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
*EOC By Arnav on 03/09/26


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

  PERFORM resolve_quarter.   "Changes by Arnav on 31/08/26

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
*BOC By Arnav on 31/08/26
*     P_QUART is blank when the user gave a date range instead, and the
*     class was then asked to plan quarter "". G_QUART carries the
*     quarter either way.
*                                             iv_quarter = p_quart
      go_fcst->generate_quarterly( EXPORTING ir_werks   = s_werks[]
                                             ir_matnr   = s_matnr[]
                                             iv_fyear   = p_fyear
                                             iv_quarter = g_quart
*EOC By Arnav on 31/08/26
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
*BOC By Arnav on 03/09/26
* Typed I and not NUMC2: a NUMC in a string template keeps its leading
* zero, which would build BUS_FCST_ADD01 instead of BUS_FCST_ADD1.
  DATA: lv_q TYPE i,
        lv_m TYPE i.
*EOC By Arnav on 03/09/26

  CLEAR ct_show.

* ---- leading block, identical on all three FS sheets ----------------
*BOC By Arnav on 31/08/26
* The rows of a VALUE table constructor have to be COMPATIBLE with the
* row type on this release, not merely convertible, so a C literal into
* a row typed LVC_FNAME is refused - the same syntax error the upload
* program threw sixteen times over STRING_TABLE. APPEND converts, and it
* is what the rest of this routine already uses.
*  ct_show = VALUE tt_fname(
*    ( 'WERKS' ) ( 'MATNR' ) ( 'MAKTX' ) ( 'MATKL' ) ( 'NTGEW' )
*    ( 'MVGR1_TXT' ) ( 'MVGR2_TXT' ) ( 'MVGR3_TXT' )
*    ( 'MVGR4_TXT' ) ( 'MVGR5_TXT' ) ).
  APPEND 'WERKS'     TO ct_show.
  APPEND 'MATNR'     TO ct_show.
  APPEND 'MAKTX'     TO ct_show.
  APPEND 'MATKL'     TO ct_show.
  APPEND 'NTGEW'     TO ct_show.
  APPEND 'MVGR1_TXT' TO ct_show.
  APPEND 'MVGR2_TXT' TO ct_show.
  APPEND 'MVGR3_TXT' TO ct_show.
  APPEND 'MVGR4_TXT' TO ct_show.
  APPEND 'MVGR5_TXT' TO ct_show.
*EOC By Arnav on 31/08/26

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
*BOC By Arnav on 31/08/26
*     MTS / MTO was drawn on the quarterly sheet only. It is asked for on
*     annual as well, next to the product category it is maintained with
*     on ZPPT_PROD_CAT.
      APPEND 'MTS_MTO'    TO ct_show.   " MTS / MTO
*EOC By Arnav on 31/08/26
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
*BOC By Arnav on 03/09/26
*     Month by month, so everything belonging to July stands together
*     and is followed by everything belonging to August:
*
*       Jul-26 · Jul-26 additional · Jul-26 final · Jul-26 value
*       Aug-26 · Aug-26 additional · Aug-26 final · Aug-26 value
*       Sep-26 · Sep-26 additional · Sep-26 final · Sep-26 value
*
*     Final = forecast + additional, value = final x PRICE, so a figure
*     is checked by reading along its own month rather than counting
*     three columns across. Tonnage joins its month when the Tonnage
*     checkbox is ticked.
      DO 3 TIMES.

        lv_q = sy-index.        " 1, 2, 3 - the additional plan columns
        lv_m = lv_q + 3.        " 4, 5, 6 - the Mn_ columns

        APPEND CONV lvc_fname( |M{ lv_m }_FCST| )       TO ct_show.
        APPEND CONV lvc_fname( |BUS_FCST_ADD{ lv_q }| ) TO ct_show.
        APPEND CONV lvc_fname( |M{ lv_m }_FCST_FINAL| ) TO ct_show.
        APPEND CONV lvc_fname( |M{ lv_m }_VAL| )        TO ct_show.

        IF p_tonn = abap_true.
          APPEND CONV lvc_fname( |M{ lv_m }_TON| )     TO ct_show.
          APPEND CONV lvc_fname( |M{ lv_m }_TON_VAL| ) TO ct_show.
        ENDIF.

      ENDDO.
*EOC By Arnav on 03/09/26

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

      IF p_tonn = abap_true.
        APPEND 'M4_TON' TO ct_show.
      ENDIF.

  ENDCASE.

*BOC By Arnav on 31/08/26
* Price, asked for on all three radio buttons. The column is drawn on
* every mode; it stays empty until the functional team confirm where the
* figure comes from - see the note on TY_ALV-PRICE in ZCL_PP_FCST.
  APPEND 'PRICE' TO ct_show.
*EOC By Arnav on 31/08/26

* ---- the result of a save --------------------------------------------
* Only when the run actually saved. The forecast number and the per row
* outcome are the point of pressing save, so they are shown then and
* only then. The traffic light stays off - an exception column is drawn
* in front of Plant whatever position it is given.
*BOC By Arnav on 03/09/26
* IF p_save = abap_true.
*   APPEND 'FCST_NO' TO ct_show.
*   APPEND 'MESSAGE' TO ct_show.
* ENDIF.
* The run no longer saves, so nothing is known here. LCL_HANDLER=>
* SHOW_RESULT brings the two out of hiding once Save has actually run.
*EOC By Arnav on 03/09/26

* ---- not drawn on this FS sheet, kept at the end --------------------
  IF gc_show_extras = abap_true.

    IF g_mode = zcl_pp_fcst=>gc_mode-quarterly.
*     Sheet 2 shows Business Forecast but not the additional column.
*     The Final ALV sheet carries it and the change upload writes it.
*BOC By Arnav on 03/09/26
*     BUS_FCST_ADD is a monthly field now - the quarterly sheet already
*     draws ADD1, ADD2 and ADD3 above, so nothing is added here.
*     APPEND 'BUS_FCST_ADD' TO ct_show.
*EOC By Arnav on 03/09/26
*BOC By Arnav on 31/08/26
*   Annual now carries MTS / MTO in its own right, so appending it here
*   as well would list the column twice and give it two positions.
*    ELSE.
*      APPEND 'MTS_MTO' TO ct_show.
    ELSEIF g_mode = zcl_pp_fcst=>gc_mode-monthly.
      APPEND 'MTS_MTO' TO ct_show.
*EOC By Arnav on 31/08/26
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
*BOC By Arnav on 03/09/26
*   The new quarterly columns are named from the financial calendar by
*   MONTH_HEADINGS, the same routine that names M4_FCST and M4_TON, so
*   they read Jul-26 rather than "Month 1". Nothing static here.
*EOC By Arnav on 03/09/26
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

    IF g_mode = zcl_pp_fcst=>gc_mode-quarterly.
      PERFORM txt USING 'MAX_QTY'  'Max. Qty'.
      PERFORM txt USING 'FCST_QTY' 'Forecast (Max * Growth %)'.
    ELSE.
      PERFORM txt USING 'MAX_QTY'  'Average * Load'.
      PERFORM txt USING 'FCST_QTY' 'LY vs Current Requirement Qty'.
    ENDIF.

*BOC By Arnav on 31/08/26
*   The headings above are the neutral ones. On quarter and month based
*   planning the calendar month behind each column is known, so it is
*   drawn instead - "Jul-25" rather than "LY Month 1". The neutral texts
*   stay as the fallback for a run where the quarter cannot be worked
*   out. Annual already names its months and is untouched.
    PERFORM month_headings.
*EOC By Arnav on 31/08/26

  ENDIF.

  PERFORM txt USING 'PROD_CAT'  'Product Cat.'.
  PERFORM txt USING 'MTS_MTO'   'MTS / MTO'.
*BOC By Arnav on 31/08/26
  PERFORM txt USING 'NTGEW'     'Net Weight'.
  PERFORM txt USING 'PRICE'     'Price'.
*EOC By Arnav on 31/08/26
  PERFORM txt USING 'MVGR1_TXT' 'Material Group 1'.
  PERFORM txt USING 'MVGR2_TXT' 'Material Group 2'.
  PERFORM txt USING 'MVGR3_TXT' 'Material Group 3'.
  PERFORM txt USING 'MVGR4_TXT' 'Material Group 4'.
  PERFORM txt USING 'MVGR5_TXT' 'Material Group 5'.
  PERFORM txt USING 'FCST_NO'   'Forecast Number'.

ENDFORM.


*&---------------------------------------------------------------------*
*& BOC By Arnav on 31/08/26
*&
*& The quarter actually being planned
*&
*& Quarter based planning takes either a quarter or a date range. When a
*& date range was given P_QUART is blank, and the class was being asked
*& to plan quarter "" - which produced a list whose columns belonged to
*& no month at all. The quarter of the first date of the range is used
*& instead, so generation and headings agree.
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
*& Calendar month headings for quarter and month based planning
*&
*& "M1", "M2", "LY Month 1" mean nothing to a planner. Every month
*& column is headed with the month it actually holds - Jul-25, Aug-25,
*& Sep-25 for the comparison quarter, Apr-26 to Jun-26 for the three
*& months before the plan, and the planned months themselves.
*&
*& Called after the neutral headings, so anything that cannot be worked
*& out keeps the text it already had.
*&---------------------------------------------------------------------*
FORM month_headings.

  DATA: lv_nam TYPE char3,
        lv_hdr TYPE string,
        lv_col TYPE lvc_fname,
        lv_ix  TYPE i,
        lv_qi  TYPE i,
        lv_ai  TYPE i,   "Changes by Arnav on 03/09/26
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
      lv_yy  = ls_q-gjahr.
      lv_mm  = ls_q-month.
      PERFORM month_name USING lv_mm CHANGING lv_nam.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
      lv_col = |M{ lv_ix }_FCST|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } tonnage|.
      lv_col = |M{ lv_ix }_TON|.
      PERFORM txt USING lv_col lv_hdr.

*BOC By Arnav on 03/09/26
*     The additional plan quantity, the final and the two value columns
*     are named from the same month, so a quarter 4 run reads Jan-27
*     rather than "Month 1".
      lv_ai  = lv_ix - 3.
      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } additional|.
      lv_col = |BUS_FCST_ADD{ lv_ai }|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } final|.
      lv_col = |M{ lv_ix }_FCST_FINAL|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } value|.
      lv_col = |M{ lv_ix }_VAL|.
      PERFORM txt USING lv_col lv_hdr.

      lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } tonnage value|.
      lv_col = |M{ lv_ix }_TON_VAL|.
      PERFORM txt USING lv_col lv_hdr.
*EOC By Arnav on 03/09/26
    ENDLOOP.

  ELSE.

*   Month based planning forecasts one month, drawn in M4_FCST
    lv_per = p_perio.
    zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = p_fyear
                                                     iv_period = lv_per
                                           IMPORTING ev_gjahr  = lv_yy
                                                     ev_month  = lv_mm ).
    PERFORM month_name USING lv_mm CHANGING lv_nam.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) }|.
    PERFORM txt USING 'M4_FCST' lv_hdr.

    lv_hdr = |{ lv_nam }-{ lv_yy+2(2) } tonnage|.
    PERFORM txt USING 'M4_TON' lv_hdr.

    lv_hdr = |Additional Plan Qty { lv_nam }-{ lv_yy+2(2) }|.
    PERFORM txt USING 'BUS_FCST_ADD' lv_hdr.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Save from the list
*&
*& There is no GUI status in this program and there cannot be one - it
*& is screen free so that the object ships by abapGit, and SE41 statuses
*& are not serialised. SET_SCREEN_STATUS therefore always failed and the
*& Save button never reached the toolbar, which is why the list looked
*& like it refused to save. The list is closed first and the question is
*& asked afterwards, which needs no status at all.
*&
*& Skipped when the Save checkbox already saved the run, when there is
*& nothing to save, and when the user has no create authority - there is
*& no point asking a question whose answer can only be refused.
*&---------------------------------------------------------------------*
*BOC By Arnav on 03/09/26
* The confirm popup is withdrawn and this routine is no longer
* called. Commented out whole rather than left in place, because it
* still reads P_SAVE, which no longer exists.
*FORM save_prompt.
*
** LV_Q is CHAR 100 and not a STRING: TEXT_QUESTION of POPUP_TO_CONFIRM
** is typed generic C, which a STRING is not compatible with.
*  DATA: lv_ans  TYPE c LENGTH 1,
*        lv_q    TYPE char100,
*        lv_rows TYPE char10.
*
*  CHECK p_save = abap_false.
*  CHECK gt_alv IS NOT INITIAL.
*  CHECK go_fcst IS BOUND.
*
*  LOOP AT s_werks INTO DATA(ls_w3).
*    IF zcl_pp_fcst_util=>check_authority( iv_werks = ls_w3-low
*                                          iv_actvt = '01' ) = abap_false.
*      RETURN.
*    ENDIF.
*  ENDLOOP.
*
*  lv_rows = lines( gt_alv ).
*  CONDENSE lv_rows.
*  CONCATENATE 'Save' lv_rows 'forecast row(s) for' p_fyear
*         INTO lv_q SEPARATED BY space.
*  CONCATENATE lv_q '?' INTO lv_q.
*
*  CALL FUNCTION 'POPUP_TO_CONFIRM'
*    EXPORTING  titlebar              = 'Save forecast'
*               text_question         = lv_q
*               text_button_1         = 'Save'
*               text_button_2         = 'Do not save'
*               default_button        = '2'
*               display_cancel_button = abap_false
*    IMPORTING  answer                = lv_ans
*    EXCEPTIONS text_not_found        = 1
*               OTHERS                = 2.
*
*  CHECK sy-subrc = 0 AND lv_ans = '1'.
*
*  PERFORM save_all.
*
*ENDFORM.
*EOC By Arnav on 03/09/26
*& EOC By Arnav on 31/08/26


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
