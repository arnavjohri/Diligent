*&---------------------------------------------------------------------*
*& Report         : ZBC_TADIR_SRCSYS_CHANGE
*& Title          : Change source (original) system of Z/Y objects in TADIR
*& Project        : OVL                          Module: BC
*& Related FS     : None - utility, requested by mail
*& Author         : Arnav Johri                  Date: 05.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Development was done in OCQ, which is now the quality system. The
*&   objects arrived in this (development) system with TADIR-SRCSYSTEM =
*&   OCQ, so every edit here is a repair. This report resets SRCSYSTEM to
*&   the current system (SY-SYSID) so the objects become originals here.
*&
*&   Safety rules, all enforced in code:
*&   - Only PGMID R3TR, object name starting Z or Y, AND package starting
*&     Z or Y. A Z/Y-named object in a non-Z/Y package is listed as
*&     skipped and never updated. Nothing standard can qualify.
*&   - Only rows whose SRCSYSTEM equals the "old" system entered.
*&   - Test mode is the default; the update needs a confirmation popup
*&     and runs in dialog only.
*&   - Refuses to run when old system = current system.
*&
*&   Selection texts (SE38 > Goto > Text elements > Selection texts):
*&     P_OLD  Current Source System      S_OBJ  Object Type
*&     S_NAME Object Name                S_DEVC Package
*&     P_TEST Test Run (No Update)
*&   Text symbols: 001 Selection   002 Processing Options
*&
*& CHANGE HISTORY
*&   05.10.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zbc_tadir_srcsys_change.

TABLES tadir.

TYPES: BEGIN OF ty_out,
         pgmid    TYPE tadir-pgmid,
         object   TYPE tadir-object,
         obj_name TYPE tadir-obj_name,
         devclass TYPE tadir-devclass,
         author   TYPE tadir-author,
         src_old  TYPE tadir-srcsystem,
         src_new  TYPE tadir-srcsystem,
         status   TYPE c LENGTH 60,
       END OF ty_out.

DATA: gt_out   TYPE STANDARD TABLE OF ty_out,
      gv_upd   TYPE i,
      gv_skip  TYPE i,
      gv_fail  TYPE i.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
* ASSUMPTION: OCQ is the old development system, now quality. The
* default is only a convenience - overwrite it on the screen if needed.
PARAMETERS p_old TYPE tadir-srcsystem OBLIGATORY DEFAULT 'OCQ'.
SELECT-OPTIONS: s_obj  FOR tadir-object,
                s_name FOR tadir-obj_name,
                s_devc FOR tadir-devclass.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS p_test AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  PERFORM validate_selection.

START-OF-SELECTION.
  PERFORM fetch_data.
  IF gt_out IS INITIAL.
    MESSAGE |No Z/Y objects with source system { p_old } found| TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.
  PERFORM classify.

  IF p_test = abap_false.
    IF sy-batch = abap_true.
      MESSAGE 'Update runs in dialog only - start without background, or use test mode'
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    PERFORM confirm_and_update.
  ENDIF.

END-OF-SELECTION.
  IF gt_out IS NOT INITIAL.
    PERFORM display_alv.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form validate_selection
*&---------------------------------------------------------------------*
FORM validate_selection.
  IF p_old = sy-sysid.
    MESSAGE |Source system { p_old } is this system ({ sy-sysid }) - nothing to change|
      TYPE 'E'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form fetch_data
*& TADIR is client-independent - no client handling needed.
*&---------------------------------------------------------------------*
FORM fetch_data.
  SELECT pgmid, object, obj_name, devclass, author, srcsystem
    FROM tadir
    WHERE pgmid     = 'R3TR'
      AND srcsystem = @p_old
      AND object   IN @s_obj
      AND obj_name IN @s_name
      AND devclass IN @s_devc
      AND ( obj_name LIKE 'Z%' OR obj_name LIKE 'Y%' )
    ORDER BY object, obj_name
    INTO TABLE @gt_out.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form classify
*& Second guard: the package must also be a customer (Z/Y) package.
*&---------------------------------------------------------------------*
FORM classify.
  LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<ls_out>).
    IF <ls_out>-devclass(1) = 'Z' OR <ls_out>-devclass(1) = 'Y'.
      <ls_out>-src_new = sy-sysid.
      IF p_test = abap_true.
        <ls_out>-status = 'Test run - would be changed'.
      ELSE.
        <ls_out>-status = 'Pending'.
      ENDIF.
    ELSE.
      <ls_out>-src_new = <ls_out>-src_old.
      <ls_out>-status  = 'Skipped - package is not Z/Y, not changed'.
      gv_skip = gv_skip + 1.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form confirm_and_update
*&---------------------------------------------------------------------*
FORM confirm_and_update.
  DATA: lv_answer TYPE c LENGTH 1,
        lv_count  TYPE i,
        lv_text   TYPE string.

  LOOP AT gt_out TRANSPORTING NO FIELDS WHERE status = 'Pending'.
    lv_count = lv_count + 1.
  ENDLOOP.
  IF lv_count = 0.
    MESSAGE 'No objects qualify for update (all skipped)' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  lv_text = |Change source system { p_old } -> { sy-sysid } for { lv_count } objects?|.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Change Source System in TADIR'
      text_question         = lv_text
      text_button_1         = 'Yes'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = abap_false
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<ls_cancel>) WHERE status = 'Pending'.
      <ls_cancel>-src_new = <ls_cancel>-src_old.
      <ls_cancel>-status  = 'Cancelled by user - not changed'.
    ENDLOOP.
    MESSAGE 'Update cancelled - nothing changed' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

* The SRCSYSTEM = old-system condition re-checks each row at update
* time, so a row changed by someone else meanwhile is not overwritten.
  LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<ls_upd>) WHERE status = 'Pending'.
    UPDATE tadir SET srcsystem = @sy-sysid
      WHERE pgmid     = @<ls_upd>-pgmid
        AND object    = @<ls_upd>-object
        AND obj_name  = @<ls_upd>-obj_name
        AND srcsystem = @p_old.
    IF sy-subrc = 0 AND sy-dbcnt = 1.
      <ls_upd>-status = 'Changed'.
      gv_upd = gv_upd + 1.
    ELSE.
      <ls_upd>-src_new = <ls_upd>-src_old.
      <ls_upd>-status  = 'Not changed - entry no longer matches'.
      gv_fail = gv_fail + 1.
    ENDIF.
  ENDLOOP.

  IF gv_upd > 0.
    COMMIT WORK.
  ENDIF.

  MESSAGE |Changed: { gv_upd }, skipped: { gv_skip }, not changed: { gv_fail }| TYPE 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv.
  DATA: lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_out ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_alv->get_functions( )->set_all( abap_true ).
  lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
  IF p_test = abap_true.
    lo_alv->get_display_settings( )->set_list_header( 'TADIR Source System - TEST RUN' ).
  ELSE.
    lo_alv->get_display_settings( )->set_list_header( 'TADIR Source System - UPDATE RUN' ).
  ENDIF.

  lo_cols = lo_alv->get_columns( ).
  lo_cols->set_optimize( abap_true ).

  PERFORM set_col_text USING io_cols  TYPE REF TO cl_salv_columns_table
                        iv_col   TYPE csequence
                        iv_short TYPE csequence
                        iv_med   TYPE csequence
                        iv_long  TYPE csequence.
  DATA: lo_col   TYPE REF TO cl_salv_column,
        lv_col   TYPE lvc_fname,
        lv_short TYPE scrtext_s,
        lv_med   TYPE scrtext_m,
        lv_long  TYPE scrtext_l.

  lv_col   = iv_col.
  lv_short = iv_short.
  lv_med   = iv_med.
  lv_long  = iv_long.

  TRY.
      lo_col = io_cols->get_column( lv_col ).
      lo_col->set_short_text( lv_short ).
      lo_col->set_medium_text( lv_med ).
      lo_col->set_long_text( lv_long ).
    CATCH cx_salv_not_found.
      MESSAGE |ALV column { lv_col } not found| TYPE 'S' DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.
