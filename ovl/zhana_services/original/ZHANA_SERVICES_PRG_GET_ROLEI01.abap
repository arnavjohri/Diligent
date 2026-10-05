*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_GET_ROLEI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_ROLE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
**MODULE get_role INPUT.
***---------------------------------------------------------------------*
*** FULL Unique Type Declaration
***---------------------------------------------------------------------*
**  TYPES: BEGIN OF ty_full_role_f4,
**           role TYPE zapprovers-role,
**           name TYPE zapprovers-name,
**
**         END OF ty_full_role_f4.
**
***---------------------------------------------------------------------*
*** FULL Unique Data Declaration
***---------------------------------------------------------------------*
**  DATA: lt_full_role_f4_tab  TYPE STANDARD TABLE OF ty_full_role_f4,
**        ls_full_role_f4_tab  TYPE ty_full_role_f4,
**        lt_full_return_tab_2 TYPE STANDARD TABLE OF ddshretval,
**        ls_full_return_tab_2 TYPE ddshretval.
**
***---------------------------------------------------------------------*
*** Fetch Data from DB
***---------------------------------------------------------------------*
**  DATA: lv_rolef TYPE zapprovers-role.
**
**  CLEAR lv_rolef.
**
**  IF sap_pm = 'X'.
**    lv_rolef = 'SAP_PM'.
**
**  ELSEIF core_team = 'X'.
**    lv_rolef = 'Core_Team'.
**
**  ELSEIF ovl_pm = 'X'.
**    lv_rolef = 'OVL_PM'.
**
**  ELSEIF head_it = 'X'.
**    lv_rolef = 'Head_IT'.
**
**  ENDIF.
**
**  SELECT role name
**    INTO TABLE lt_full_role_f4_tab
**    FROM zapprovers
**    WHERE role EQ  lv_rolef.
**
**  IF lt_full_role_f4_tab IS INITIAL.
**    MESSAGE 'No Role Found' TYPE 'I'.
**    RETURN.
**  ENDIF.
**
***---------------------------------------------------------------------*
*** Remove Duplicate Role
***---------------------------------------------------------------------*
**  SORT lt_full_role_f4_tab BY role.
**  DELETE ADJACENT DUPLICATES FROM lt_full_role_f4_tab COMPARING role.
**
**
***---------------------------------------------------------------------*
*** Call F4 Help (Multi-Column)
***---------------------------------------------------------------------*
**  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
**    EXPORTING
**      retfield    = 'ROLE'
**      dynpprog    = sy-repid
**      dynpnr      = sy-dynnr
**      dynprofield = 'ZAPPROVERS_ROLE'
**      value_org   = 'S'
**    TABLES
**      value_tab   = lt_full_role_f4_tab
**      return_tab  = lt_full_return_tab_2.
**
***---------------------------------------------------------------------*
*** Get Selected Value (Ensure Leading Zeros)
***---------------------------------------------------------------------*
**  IF sy-subrc = 0 AND lt_full_return_tab_2 IS NOT INITIAL.
**
**    READ TABLE lt_full_return_tab_2 INTO ls_full_return_tab_2 INDEX 1.
**    IF sy-subrc = 0.
**
**      " Pad selected DOC_NO to 10 chars
**      zsap_timesheet-doc_no =
**        |{ ls_full_return_tab_2-fieldval WIDTH = 10 PAD = '0' }|.
**
**    ENDIF.
**
**  ENDIF.
**
***---------------------------------------------------------------------*
*** Clear Internal Tables
***---------------------------------------------------------------------*
**  CLEAR: lt_full_role_f4_tab,
**         ls_full_role_f4_tab,
**         lt_full_return_tab_2,
**         ls_full_return_tab_2.
**
**ENDMODULE.
