*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_GET_ROLEI02.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_ROLE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

MODULE get_role INPUT.

  TYPES: BEGIN OF ty_full_role_f4,
           role TYPE zapprovers-role,
           name TYPE zapprovers-name,
         END OF ty_full_role_f4.

  DATA: lt_full_role_f4_tab TYPE STANDARD TABLE OF ty_full_role_f4,
        ls_full_role_f4_tab TYPE ty_full_role_f4,
        lt_role_return_tab  TYPE STANDARD TABLE OF ddshretval,
        ls_role_return_tab  TYPE ddshretval,
        lv_rolef            TYPE zapprovers-role.

  CLEAR: lt_full_role_f4_tab,
         lt_role_return_tab.

  " Determine Role
  IF sap_pm = 'X'.
    lv_rolef = 'CORE_TEAM'.
  ELSEIF core_team = 'X'.
    lv_rolef = 'OVL_PM'.
  ELSEIF ovl_pm = 'X'.
    lv_rolef = 'HEAD_IT'.
  ELSEIF head_it = 'X'.
    lv_rolef = 'HEAD_IT'.
  ENDIF.

  IF lv_rolef IS INITIAL.
    MESSAGE 'Select Role checkbox first' TYPE 'I'.
    RETURN.
  ENDIF.

  " Fetch Data
  SELECT role name
    INTO TABLE lt_full_role_f4_tab
    FROM zapprovers
    WHERE role = lv_rolef.

  IF lt_full_role_f4_tab IS INITIAL.
    MESSAGE 'No data found for selected role' TYPE 'I'.
    RETURN.
  ENDIF.

  " Remove duplicates
  SORT lt_full_role_f4_tab BY role.
*  DELETE ADJACENT DUPLICATES FROM lt_full_role_f4_tab COMPARING role.

  " Call F4
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'NAME'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'ZAPPROVERS_ROLE'
      value_org   = 'S'
    TABLES
      value_tab   = lt_full_role_f4_tab
      return_tab  = lt_role_return_tab.


  " Get Selected ROLE
  IF sy-subrc = 0 AND lt_role_return_tab IS NOT INITIAL.

    READ TABLE lt_role_return_tab INTO ls_role_return_tab INDEX 1.
    IF sy-subrc = 0.
*      namet = ls_role_return_tab-fieldval.
      lv_role = ls_role_return_tab-fieldval.
    ENDIF.

    READ TABLE lt_full_role_f4_tab  INTO DATA(id) WITH KEY name = ls_role_return_tab-fieldval.
    IF sy-subrc = 0.
*    lv_role = id-role.
      namet = id-role.
    ENDIF.
  ENDIF.

  " Clear Internal Tables
  CLEAR: lt_full_role_f4_tab,
         ls_full_role_f4_tab,
         lt_role_return_tab,
         ls_role_return_tab,id.

ENDMODULE.
