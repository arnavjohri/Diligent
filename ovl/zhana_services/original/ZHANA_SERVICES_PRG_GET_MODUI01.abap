*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_GET_MODUI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_MODULE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_module INPUT.


  TYPES: BEGIN OF ty_doc,
           zmodulec TYPE zcmodule, "Returned value
*         doc_no_disp TYPE char10, "Displayed value (no ALPHA)
         END OF ty_doc.

  DATA: lt_doc TYPE STANDARD TABLE OF ty_doc,
        ls_doc TYPE ty_doc.
*        lt_return TYPE STANDARD TABLE OF ddshretval,
*        ls_return TYPE ddshretval..
  CLEAR : lt_doc ,ls_doc,lt_return,ls_return.
*---------------------------------------------------------------------*
*  Fetch data from DB
*---------------------------------------------------------------------*
  SELECT  zmodulec
    FROM zresource_mappin
    INTO TABLE @DATA(lt_doc_db1) FOR ALL ENTRIES IN @lt_data
    WHERE consultant_name EQ @lt_data-consultant_name AND  zmodulec IS NOT NULL.

  IF lt_doc_db1 IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
*  Remove duplicates
*---------------------------------------------------------------------*
  SORT lt_doc_db1.
  DELETE ADJACENT DUPLICATES FROM lt_doc_db1.

*---------------------------------------------------------------------*
*  Prepare F4 internal table (KEEP LEADING ZEROS)
*---------------------------------------------------------------------*
  LOOP AT lt_doc_db1 INTO DATA(lv_doc1).
    CLEAR ls_doc.
    ls_doc-zmodulec     = lv_doc1.                          "0000000002
*  ls_doc_f4-doc_no_disp = lv_doc.   "Displayed exactly
    APPEND ls_doc TO lt_doc.
  ENDLOOP.

*---------------------------------------------------------------------*
*  Call F4 Help
*---------------------------------------------------------------------*
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'ZMODULEC'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'ZRESOURCE_MAPPIN-ZMODULEC'
      value_org   = 'S'
    TABLES
      value_tab   = lt_doc
      return_tab  = lt_return.

*---------------------------------------------------------------------*
*  Get selected value
*---------------------------------------------------------------------*
  IF sy-subrc = 0 AND lt_return IS NOT INITIAL.
    READ TABLE lt_return INTO ls_return INDEX 1.
    IF sy-subrc = 0.
      zresource_mappin-zmodulec = ls_return-fieldval.
    ENDIF.
  ENDIF.

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


ENDMODULE.
