*&---------------------------------------------------------------------*
*& Report         : ZBC_TADIR_SRCSYS_CHANGE
*& Title          : Change TADIR source system OCQ -> OCD for Z/Y objects
*& Project        : OVL                          Module: BC
*& Related FS     : None - utility, requested by mail
*& Author         : Arnav Johri                  Date: 05.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Development was done in OCQ (now quality). In OCD the custom objects
*&   carry TADIR-SRCSYSTEM = OCQ, so every edit is a repair. This report
*&   sets SRCSYSTEM = OCD so they become originals in OCD.
*&
*&   Which objects: every R3TR entry with SRCSYSTEM = OCQ, i.e. every
*&   object created in OCQ. Standard objects carry SRCSYSTEM = SAP (also
*&   when modified), so they can never qualify. As a second guard the
*&   entry must also be customer namespace by NAME (Z*, Y*) or PACKAGE
*&   (Z*, Y*, local $*). Anything else with OCQ is listed, not changed.
*&   Runs in OCD only.
*&
*&   Selection text: P_TEST  Test Run (No Update)
*&
*& CHANGE HISTORY
*&   05.10.2026  Arnav Johri  <TR>  Initial development
*&   05.10.2026  Arnav Johri  <TR>  Simplified: fixed OCQ -> OCD, all
*&                                  custom objects, only a test flag
*&---------------------------------------------------------------------*
REPORT zbc_tadir_srcsys_change.

* Systems fixed as per requirement: OCQ (old dev, now quality) -> OCD
CONSTANTS: gc_old TYPE tadir-srcsystem VALUE 'OCQ',
           gc_new TYPE tadir-srcsystem VALUE 'OCD'.

TYPES: BEGIN OF ty_obj,
         pgmid    TYPE tadir-pgmid,
         object   TYPE tadir-object,
         obj_name TYPE tadir-obj_name,
         devclass TYPE tadir-devclass,
       END OF ty_obj.

DATA: gt_obj    TYPE STANDARD TABLE OF ty_obj,
      gt_chg    TYPE STANDARD TABLE OF ty_obj,
      gt_skip   TYPE STANDARD TABLE OF ty_obj,
      gt_fail   TYPE STANDARD TABLE OF ty_obj,
      gv_answer TYPE c LENGTH 1,
      gv_text   TYPE string,
      gv_count  TYPE i.

PARAMETERS p_test AS CHECKBOX DEFAULT abap_true.

START-OF-SELECTION.

  IF sy-sysid <> gc_new.
    MESSAGE |Run this program in { gc_new } only (current system { sy-sysid })|
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

* Everything created in OCQ
  SELECT pgmid, object, obj_name, devclass
    FROM tadir
    WHERE pgmid     = 'R3TR'
      AND srcsystem = @gc_old
    ORDER BY object, obj_name
    INTO TABLE @gt_obj.

  IF gt_obj IS INITIAL.
    MESSAGE |No objects with source system { gc_old } found| TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

* Second guard: customer namespace by name or by package.
* SMIM keys are GUIDs and SICF keys can be lower case, so those qualify
* through their Z/Y/$ package; lower-case z/y names are accepted too.
  LOOP AT gt_obj ASSIGNING FIELD-SYMBOL(<ls_obj>).
    IF <ls_obj>-obj_name(1) = 'Z' OR <ls_obj>-obj_name(1) = 'Y'
    OR <ls_obj>-obj_name(1) = 'z' OR <ls_obj>-obj_name(1) = 'y'
    OR <ls_obj>-devclass(1) = 'Z' OR <ls_obj>-devclass(1) = 'Y'
    OR <ls_obj>-devclass(1) = '$'.
      APPEND <ls_obj> TO gt_chg.
    ELSE.
      APPEND <ls_obj> TO gt_skip.
    ENDIF.
  ENDLOOP.

  gv_count = lines( gt_chg ).

  IF p_test = abap_false AND gv_count > 0.
    gv_text = |Change source system { gc_old } -> { gc_new } for { gv_count } objects?|.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Change Source System in TADIR'
        text_question         = gv_text
        text_button_1         = 'Yes'
        text_button_2         = 'No'
        default_button        = '2'
        display_cancel_button = abap_false
      IMPORTING
        answer                = gv_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0 OR gv_answer <> '1'.
      MESSAGE 'Cancelled - nothing changed' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    gv_count = 0.
    LOOP AT gt_chg ASSIGNING FIELD-SYMBOL(<ls_chg>).
      UPDATE tadir SET srcsystem = @gc_new
        WHERE pgmid     = @<ls_chg>-pgmid
          AND object    = @<ls_chg>-object
          AND obj_name  = @<ls_chg>-obj_name
          AND srcsystem = @gc_old.
      IF sy-subrc = 0.
        gv_count = gv_count + 1.
      ELSE.
        APPEND <ls_chg> TO gt_fail.
      ENDIF.
    ENDLOOP.
    COMMIT WORK.

    WRITE: / |UPDATE RUN - { gv_count } objects changed { gc_old } -> { gc_new }|.
  ELSEIF p_test = abap_true.
    WRITE: / |TEST RUN - { gv_count } objects would change { gc_old } -> { gc_new }|.
  ELSE.
    WRITE: / 'No custom objects qualify - nothing changed'.
  ENDIF.

  PERFORM print_list USING 'Changed / to be changed' gt_chg.
  PERFORM print_list USING 'Update failed - entry changed meanwhile' gt_fail.
  PERFORM print_list USING 'NOT changed - not Z/Y by name or package, check manually'
                           gt_skip.

*&---------------------------------------------------------------------*
*& Form print_list
*&---------------------------------------------------------------------*
FORM print_list USING iv_title TYPE csequence
                      it_list  LIKE gt_obj.
  DATA lv_lines TYPE i.

  IF it_list IS INITIAL.
    RETURN.
  ENDIF.
  lv_lines = lines( it_list ).
  SKIP.
  WRITE: / iv_title, '(', lv_lines, ')'.
  ULINE.
  WRITE: / 'Object Type', 15 'Object Name', 58 'Package'.
  ULINE.
  LOOP AT it_list ASSIGNING FIELD-SYMBOL(<ls_line>).
    WRITE: / <ls_line>-object, 15 <ls_line>-obj_name(40), 58 <ls_line>-devclass.
  ENDLOOP.
ENDFORM.
