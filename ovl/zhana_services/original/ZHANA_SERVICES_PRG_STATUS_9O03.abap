*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_STATUS_9O03.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9009  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9009 OUTPUT.
  SET PF-STATUS '9002'.
  SET TITLEBAR '9001'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9009  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9009 INPUT.
  " Auto-pad DOC_NO to 10 characters with leading zeros (ECC compatible)
  " --------------------------------------------
*  IF doc_no IS NOT INITIAL.
*
*    DATA lv_len TYPE i.
*    DATA lv_pad TYPE i.
*    DATA lv_zeros TYPE c LENGTH 10.
*
*    lv_len = strlen( doc_no ).
*    lv_pad = 10 - lv_len.
*
*    IF lv_pad > 0.
*      " Create string with lv_pad zeros
*      lv_zeros = ''.
*      DO lv_pad TIMES.
*        lv_zeros = lv_zeros && '0'.
*      ENDDO.
*
*      " Prepend zeros
*      doc_no = lv_zeros && doc_no.
*    ENDIF.
*
*  ENDIF.
  CASE sy-ucomm.
    WHEN 'EXIT' OR 'CANC'.

      LEAVE PROGRAM.


    WHEN 'BACK'.
      CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email.
      CALL SCREEN '9001'.


    WHEN 'SUB'.

      IF doc_no IS NOT INITIAL.

        SELECT *
 FROM ZSAP_TIMESHEET INTO @DATA(LS_FORM) UP TO 1 ROWS WHERE DOC_NO = @DOC_NO
 ORDER BY PRIMARY KEY .
 ENDSELECT.

        IF sy-subrc <> 0.
          MESSAGE 'Data not found for given Doc No'
            TYPE 'S' DISPLAY LIKE 'E'.
          LEAVE TO SCREEN sy-dynnr.
          RETURN.
        ENDIF.

        IF ls_form-creator_release_r = 'X' AND change = 'X'.
          MESSAGE 'Document already released. Cannot be changed.'
            TYPE 'S' DISPLAY LIKE 'E'.
          LEAVE TO SCREEN sy-dynnr.
          RETURN.
        ENDIF.

        "-----------------------------
        " Approval Validations
        "-----------------------------

***        IF sap_pm = 'X'. "Level 2
***          IF ls_form-creator_release_r <> 'X'.
***            MESSAGE 'Cannot approve. Creator Release not approved yet.'
***              TYPE 'S' DISPLAY LIKE 'E'.
***            LEAVE TO SCREEN sy-dynnr.
***            RETURN.
***          ENDIF.
***        ENDIF.
***
***        IF core_team = 'X'. "Level 3
***          IF ls_form-sap_pm_approve <> 'X'.
***            MESSAGE 'Cannot approve. SAP PM not approved yet.'
***              TYPE 'S' DISPLAY LIKE 'E'.
***            LEAVE TO SCREEN sy-dynnr.
***            RETURN.
***          ENDIF.
***        ENDIF.
***
***        IF ovl_pm = 'X'. "Level 4
***          IF ls_form-core_team_approve <> 'X'.
***            MESSAGE 'Cannot approve. Core Team not approved yet.'
***              TYPE 'S' DISPLAY LIKE 'E'.
***            LEAVE TO SCREEN sy-dynnr.
***            RETURN.
***          ENDIF.
***        ENDIF.
***
***        IF head_it = 'X'. "Level 5
***          IF ls_form-ovl_pm_approve <> 'X'.
***            MESSAGE 'Cannot approve. OVL PM not approved yet.'
***              TYPE 'S' DISPLAY LIKE 'E'.
***            LEAVE TO SCREEN sy-dynnr.
***            RETURN.
***          ENDIF.
***        ENDIF.

        "-----------------------------
        " Approval Validations with Master Data Authorization
        "-----------------------------

        DATA: lv_sap_user   TYPE zsap_user_id,
              ls_approver   TYPE zapprovers,
              lv_authorized TYPE abap_bool.

        lv_sap_user = sy-uname. " current SAP user

        " === LEVEL 2: SAP_PM ===
        IF sap_pm = 'X'.

          " Previous approval check
          IF ls_form-creator_release_r <> 'X'.
            MESSAGE 'Cannot approve. Creator Release not approved yet.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

          " Authorization check
          lv_authorized = abap_false.
          SELECT SINGLE *
            INTO ls_approver
            FROM zapprovers
            WHERE role = 'SAP_PM'
              AND sap_id = lv_sap_user.
          IF sy-subrc = 0.
            lv_authorized = abap_true.
          ENDIF.

          IF lv_authorized = abap_false.
            MESSAGE 'You are not authorized to approve as SAP PM.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

        ENDIF. "sap_pm

        " === LEVEL 3: CORE_TEAM ===
        IF core_team = 'X'.

          " Previous approval check
          IF ls_form-sap_pm_approve <> 'X'.
            MESSAGE 'Cannot approve. SAP PM not approved yet.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

          " Authorization check
          lv_authorized = abap_false.
          SELECT SINGLE *
            INTO ls_approver
            FROM zapprovers
            WHERE role = 'CORE_TEAM'
              AND sap_id = lv_sap_user.
          IF sy-subrc = 0.
            lv_authorized = abap_true.
          ENDIF.

          IF lv_authorized = abap_false.
            MESSAGE 'You are not authorized to approve as Core Team.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

        ENDIF. "core_team

        " === LEVEL 4: OVL_PM ===
        IF ovl_pm = 'X'.

          " Previous approval check
          IF ls_form-core_team_approve <> 'X'.
            MESSAGE 'Cannot approve. Core Team not approved yet.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

          " Authorization check
          lv_authorized = abap_false.
          SELECT SINGLE *
            INTO ls_approver
            FROM zapprovers
            WHERE role = 'OVL_PM'
              AND sap_id = lv_sap_user.
          IF sy-subrc = 0.
            lv_authorized = abap_true.
          ENDIF.

          IF lv_authorized = abap_false.
            MESSAGE 'You are not authorized to approve as OVL PM.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

        ENDIF. "ovl_pm

        " === LEVEL 5: HEAD_IT ===
        IF head_it = 'X'.

          " Previous approval check
          IF ls_form-ovl_pm_approve <> 'X'.
            MESSAGE 'Cannot approve. OVL PM not approved yet.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

          " Authorization check
          lv_authorized = abap_false.
          SELECT SINGLE *
            INTO ls_approver
            FROM zapprovers
            WHERE role = 'HEAD_IT'
              AND sap_id = lv_sap_user.
          IF sy-subrc = 0.
            lv_authorized = abap_true.
          ENDIF.

          IF lv_authorized = abap_false.
            MESSAGE 'You are not authorized to approve as Head IT.'
              TYPE 'S' DISPLAY LIKE 'E'.
            LEAVE TO SCREEN sy-dynnr.
            RETURN.
          ENDIF.

        ENDIF. "head_it

        "-----------------------------
        " Call Screen AFTER validation
        "-----------------------------
        CALL SCREEN 9002.

      ENDIF.
  ENDCASE.


  " --------------------------------------------


*  IF ls_form-approve IS NOT INITIAL AND change = 'X'.
*    MESSAGE 'Data has already been approved and cannot be changed' TYPE 'S' DISPLAY LIKE 'E'.
*    LEAVE TO SCREEN sy-dynnr.
*    RETURN.
*  ENDIF.

ENDMODULE.
