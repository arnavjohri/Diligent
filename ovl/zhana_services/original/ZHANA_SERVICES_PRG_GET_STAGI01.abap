*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_GET_STAGI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  GET_STAGE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_stage INPUT.




  TYPES: BEGIN OF ty_doc1,
           stages TYPE zstagec, "Returned value
*         doc_no_disp TYPE char10, "Displayed value (no ALPHA)
         END OF ty_doc1.

  DATA: lt_doc1 TYPE STANDARD TABLE OF ty_doc1,
        ls_doc1 TYPE ty_doc1.
*        lt_return TYPE STANDARD TABLE OF ddshretval,
*        ls_return TYPE ddshretval..
  CLEAR : lt_doc1 ,ls_doc1,lt_return,ls_return.
*---------------------------------------------------------------------*
*  Fetch data from DB
*---------------------------------------------------------------------*
  SELECT  stages
    FROM zstages
    INTO TABLE @DATA(lt_doc_db2)
    WHERE stages IS NOT NULL.

  IF lt_doc_db2 IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
*  Remove duplicates
*---------------------------------------------------------------------*
  SORT lt_doc_db2.
  DELETE ADJACENT DUPLICATES FROM lt_doc_db2.

*---------------------------------------------------------------------*
*  Prepare F4 internal table (KEEP LEADING ZEROS)
*---------------------------------------------------------------------*
  LOOP AT lt_doc_db2 INTO DATA(lv_doc2).
    CLEAR ls_doc1.
    ls_doc1-stages  = lv_doc2.                            "0000000002
*  ls_doc_f4-doc_no_disp = lv_doc.   "Displayed exactly
    APPEND ls_doc1 TO lt_doc1.
  ENDLOOP.

*---------------------------------------------------------------------*
*  Call F4 Help
*---------------------------------------------------------------------*
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'STAGES'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'ZSTAGES-STAGES'
      value_org   = 'S'
    TABLES
      value_tab   = lt_doc1
      return_tab  = lt_return.

*---------------------------------------------------------------------*
*  Get selected value
*---------------------------------------------------------------------*
  IF sy-subrc = 0 AND lt_return IS NOT INITIAL.
    READ TABLE lt_return INTO ls_return INDEX 1.
    IF sy-subrc = 0.
      zstages-stages = ls_return-fieldval.
    ENDIF.
  ENDIF.

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



ENDMODULE.
