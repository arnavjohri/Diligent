*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_STATUS_9O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9001 OUTPUT.
  SET PF-STATUS '9001'.
  SET TITLEBAR '9001'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9001 INPUT.

  CASE sy-ucomm.

    WHEN 'EXIT' OR 'BACK' OR 'CANC'.
      CLEAR : change , create ,display.
*      perform cleardata.
      LEAVE PROGRAM.

    WHEN 'CREATE'.
      AUTHORITY-CHECK OBJECT 'ZSAP_TIME' ID 'ACTVT' FIELD '01'.
      IF sy-subrc EQ 0.
        create = 'X'.
        CALL SCREEN '9002'.
      ELSE .
        MESSAGE 'You are not authorized to create entries.' TYPE 'E'.
      ENDIF.

    WHEN 'CHANGE'.
      AUTHORITY-CHECK OBJECT 'ZSAP_TIME' ID 'ACTVT' FIELD '02'.
      IF sy-subrc EQ 0.
        change = 'X'.
        CALL SCREEN '9009'.
      ELSE .
        MESSAGE 'You are not authorized to change entries.' TYPE 'E'.
      ENDIF.

    WHEN 'DISPLAY'.
      AUTHORITY-CHECK OBJECT 'ZSAP_TIME' ID 'ACTVT' FIELD '03'.
      IF sy-subrc EQ 0.
        display = 'X'.
        CALL SCREEN '9009'.
      ELSE .
        MESSAGE 'You are not authorized to display entries.' TYPE 'E'.
      ENDIF.

    WHEN 'ZSER_ELE'.
      CALL TRANSACTION 'ZSERVICE_ELEMENTS'.

    WHEN 'ZRES_MAP'.
      CALL TRANSACTION 'ZRESOURCE_MAPPIN'.

    WHEN 'ZSTAGES'.
      CALL TRANSACTION 'ZSTAGES'.

    WHEN 'APP'.
      CALL TRANSACTION 'ZAPPROVERS'.

    WHEN 'REPORTS'.
      CALL TRANSACTION 'ZTIMESHEET_REP'.

    WHEN 'CON'.
      CALL TRANSACTION 'ZCON'.

    WHEN 'C_REL'.
      creator_release = 'X'.
      CALL SCREEN '9009'.

    WHEN 'SAP_PM'.
      sap_pm = 'X'.
      CALL SCREEN '9009'.


    WHEN 'C_TEAM'.
      core_team = 'X'.
      CALL SCREEN '9009'.

    WHEN 'OVL_PM'.
      ovl_pm = 'X'.
      CALL SCREEN '9009'.

    WHEN 'HEAD_IT'.
      head_it  = 'X'.
      CALL SCREEN '9009'.

" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 09.06.2026  FOR ATC
*      WHEN 'FORM'.
      WHEN 'FORM'. "#EC CI_USAGE_OK[2270335]
" Code Remediation changes S4 2025_1_A Conversion **END OF CHANGE BY SAP_ABAP 09.06.2026 FOR ATC
        CALL TRANSACTION 'ZSAPT_FORM'.


  ENDCASE.



ENDMODULE.
