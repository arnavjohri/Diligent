*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_GET_SERVI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_SERVICE_ELEMENT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_service_element INPUT.

  TYPES: BEGIN OF ty_serv_f4,
           service_element TYPE zser_ele, "Returned value
         END OF ty_serv_f4.

  DATA: lt_serv_f4     TYPE STANDARD TABLE OF ty_serv_f4,
        ls_serv_f4     TYPE ty_serv_f4,
        lt_serv_return TYPE STANDARD TABLE OF ddshretval,
        ls_serv_return TYPE ddshretval..
  CLEAR : lt_serv_f4 ,ls_serv_f4,lt_serv_return,ls_serv_return.
*---------------------------------------------------------------------*
*  Fetch data from DB
*---------------------------------------------------------------------*
  SELECT  service_element
    FROM ZSERVICE_ELEMENT
    INTO TABLE @DATA(lt_serv_db)
    WHERE service_element IS NOT NULL.

  IF lt_serv_db IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
*  Remove duplicates
*---------------------------------------------------------------------*
  SORT lt_serv_db.
  DELETE ADJACENT DUPLICATES FROM lt_serv_db.

*---------------------------------------------------------------------*
*  Prepare F4 internal table (KEEP LEADING ZEROS)
*---------------------------------------------------------------------*
  LOOP AT lt_serv_db INTO DATA(lv_serv).
    CLEAR ls_serv_f4.
    ls_serv_f4-service_element     = lv_serv.
    APPEND ls_serv_f4 TO lt_serv_f4.
  ENDLOOP.

*---------------------------------------------------------------------*
*  Call F4 Help
*---------------------------------------------------------------------*
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'SERVICE_ELEMENT'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'ZRESOURCE_MAPPIN-SERVICE_ELEMENT'
      value_org   = 'S'
    TABLES
      value_tab   = lt_serv_f4
      return_tab  = lt_serv_return.

*---------------------------------------------------------------------*
*  Get selected value
*---------------------------------------------------------------------*
  IF sy-subrc = 0 AND lt_serv_return IS NOT INITIAL.
    READ TABLE lt_serv_return INTO ls_serv_return INDEX 1.
    IF sy-subrc = 0.
      zresource_mappin-service_element = ls_serv_return-fieldval.
    ENDIF.
  ENDIF.

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

ENDMODULE.
