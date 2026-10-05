MODULE get_doc_no INPUT.

*---------------------------------------------------------------------*
* FULL Unique Type Declaration
*---------------------------------------------------------------------*
  TYPES: BEGIN OF ty_full_docno_f4,
           doc_no          TYPE zsap_timesheet-doc_no,

           consultant_name TYPE zsap_timesheet-consultant_name,
           service_element TYPE zsap_timesheet-service_element,
           zmodulec        TYPE zsap_timesheet-zmodulec,
           created_on      TYPE zsap_timesheet-created_on,
         END OF ty_full_docno_f4.

*---------------------------------------------------------------------*
* FULL Unique Data Declaration
*---------------------------------------------------------------------*
  DATA: lt_full_docno_f4_tab TYPE STANDARD TABLE OF ty_full_docno_f4,
        ls_full_docno_f4_tab TYPE ty_full_docno_f4,
        lt_full_return_tab   TYPE STANDARD TABLE OF ddshretval,
        ls_full_return_tab   TYPE ddshretval.

*---------------------------------------------------------------------*
* Fetch Data from DB
*---------------------------------------------------------------------*
  CLEAR lt_full_docno_f4_tab.
  IF sap_pm NE 'X' AND core_team NE 'X' AND ovl_pm NE 'X'AND head_it NE 'X' AND creator_release NE 'X'  AND change NE 'X' .
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
      WHERE stages IS NOT NULL AND zconsultant_id EQ sy-uname.
  ENDIF.

  IF change = 'X'.
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
      WHERE stages IS NOT NULL AND zconsultant_id EQ sy-uname AND creator_release_r NE 'X'.

  ENDIF.

  IF creator_release = 'X' .
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
      WHERE stages IS NOT NULL AND zconsultant_id EQ sy-uname AND creator_release_r NE 'X'.
  ENDIF.


  IF sap_pm = 'X'.
    " SAP PM level: SAP_PM_APPROVE blank
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
*      WHERE stages IS NOT NULL
*        AND ( sap_pm_approve IS NULL OR sap_pm_approve = '' ) AND reject_reason = ' '  AND creator_release_r = 'X'.
      WHERE stages IS NOT NULL
  AND ( sap_pm_approve IS NULL OR sap_pm_approve = '' ) AND sap_pm_reject NE 'X'  AND creator_release_r = 'X'.   "addded by mohd mobassir - 22.07.2026

  ELSEIF core_team = 'X'.
    " CORE TEAM level: CORE_TEAM_APPROVE blank
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
      WHERE stages IS NOT NULL
        AND ( core_team_approve IS NULL OR core_team_approve = '' ) AND reject_reason = ' ' AND sap_pm_approve = 'X' .

  ELSEIF ovl_pm = 'X'.
    " OVL PM level: OVL_PM_APPROVE blank
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
      WHERE stages IS NOT NULL
        AND ( ovl_pm_approve IS NULL OR ovl_pm_approve = '' ) AND reject_reason = ' ' AND sap_pm_approve = 'X' AND core_team_approve = 'X' .

  ELSEIF head_it = 'X'.
    " HEAD IT level: HEAD_IT_APPROVE blank
    SELECT doc_no
           consultant_name
           service_element
           zmodulec
           created_on
      INTO TABLE lt_full_docno_f4_tab
      FROM zsap_timesheet
      WHERE stages IS NOT NULL
        AND ( head_it_approve IS NULL OR head_it_approve = '' ) AND reject_reason = ' ' AND sap_pm_approve = 'X' AND core_team_approve = 'X' AND  ovl_pm_approve = 'X'.
  ENDIF.

  IF lt_full_docno_f4_tab IS INITIAL.
    MESSAGE 'No Document Found' TYPE 'I'.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* Remove Duplicate DOC_NO
*---------------------------------------------------------------------*
  SORT lt_full_docno_f4_tab BY doc_no.
  DELETE ADJACENT DUPLICATES FROM lt_full_docno_f4_tab COMPARING doc_no.

*---------------------------------------------------------------------*
* Force Leading Zero Format (For Internal Table & F4)
*---------------------------------------------------------------------*
**  LOOP AT lt_full_docno_f4_tab INTO ls_full_docno_f4_tab.
**
**    " Pad DOC_NO with leading zeros (width 10)
**    ls_full_docno_f4_tab-doc_no =
**      |{ ls_full_docno_f4_tab-doc_no WIDTH = 10 PAD = '0' }|.
**
**    MODIFY lt_full_docno_f4_tab FROM ls_full_docno_f4_tab.
**
**  ENDLOOP.

*---------------------------------------------------------------------*
* Call F4 Help (Multi-Column)
*---------------------------------------------------------------------*
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'DOC_NO'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'ZSAP_TIMESHEET-DOC_NO'
      value_org   = 'S'
    TABLES
      value_tab   = lt_full_docno_f4_tab
      return_tab  = lt_full_return_tab.

*---------------------------------------------------------------------*
* Get Selected Value (Ensure Leading Zeros)
*---------------------------------------------------------------------*
  IF sy-subrc = 0 AND lt_full_return_tab IS NOT INITIAL.

    READ TABLE lt_full_return_tab INTO ls_full_return_tab INDEX 1.
    IF sy-subrc = 0.

      " Pad selected DOC_NO to 10 chars
      zsap_timesheet-doc_no =
        |{ ls_full_return_tab-fieldval WIDTH = 10 PAD = '0' }|.

    ENDIF.

  ENDIF.

*---------------------------------------------------------------------*
* Clear Internal Tables
*---------------------------------------------------------------------*
  CLEAR: lt_full_docno_f4_tab,
         ls_full_docno_f4_tab,
         lt_full_return_tab,
         ls_full_return_tab.

ENDMODULE.
