*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_GET_C_NAI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_C_NAME  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_c_name INPUT.

  TYPES: BEGIN OF ty_doc_f4,
           consultant_name TYPE zcname, "Returned value
*         doc_no_disp TYPE char10, "Displayed value (no ALPHA)
         END OF ty_doc_f4.

  DATA: lt_doc_f4 TYPE STANDARD TABLE OF ty_doc_f4,
        ls_doc_f4 TYPE ty_doc_f4,
        lt_return TYPE STANDARD TABLE OF ddshretval,
        ls_return TYPE ddshretval..
  CLEAR : lt_doc_f4 ,ls_doc_f4,lt_return,ls_return.
*---------------------------------------------------------------------*
*  Fetch data from DB
*---------------------------------------------------------------------*
*  BREAK-POINT
  .
  SELECT  consultant_name
    FROM zresource_mappin
    INTO TABLE @DATA(lt_doc_db)
    WHERE consultant_name IS NOT NULL AND zconsultant_id = @sy-uname.

  IF lt_doc_db IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
*  Remove duplicates
*---------------------------------------------------------------------*
  SORT lt_doc_db.
  DELETE ADJACENT DUPLICATES FROM lt_doc_db COMPARING consultant_name.

*---------------------------------------------------------------------*
*  Prepare F4 internal table (KEEP LEADING ZEROS)
*---------------------------------------------------------------------*
  LOOP AT lt_doc_db INTO DATA(lv_doc).
    CLEAR ls_doc_f4.
    ls_doc_f4-consultant_name      = lv_doc.                "0000000002
*  ls_doc_f4-doc_no_disp = lv_doc.   "Displayed exactly
    APPEND ls_doc_f4 TO lt_doc_f4.
  ENDLOOP.

*---------------------------------------------------------------------*
*  Call F4 Help
*---------------------------------------------------------------------*
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'CONSULTANT_NAME'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'ZRESOURCE_MAPPIN-CONSULTANT_NAME'
      value_org   = 'S'
    TABLES
      value_tab   = lt_doc_f4
      return_tab  = lt_return.

*---------------------------------------------------------------------*
*  Get selected value
*---------------------------------------------------------------------*
  IF sy-subrc = 0 AND lt_return IS NOT INITIAL.
    READ TABLE lt_return INTO ls_return INDEX 1.
    IF sy-subrc = 0.
      zresource_mappin-consultant_name = ls_return-fieldval.
    ENDIF.
  ENDIF.

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

ENDMODULE.
