*&---------------------------------------------------------------------*
*& Report  ZSAP_TIMESHEET_FORM_PRG
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zsap_timesheet_form_prg.


*----------------------*
* Selection Screen
*----------------------*
***PARAMETERS: p_docno TYPE zsap_timesheet-doc_no OBLIGATORY.
***
****----------------------*
**** Data Declarations
****----------------------*
***DATA: gv_fm_name   TYPE rs38l_fnam,
***      gs_timesheet TYPE zsap_timesheet.
***
***
***TYPES : BEGIN OF doc,
***          doc_no          TYPE zsap_timesheet-doc_no,
***          consultant_name TYPE zsap_timesheet-consultant_name,
****          datec           TYPE zsap_timesheet-datec,
***        END OF doc.
***
***DATA: gt_timesheet TYPE TABLE OF doc.
***
***
***AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_docno.
***
***  SELECT doc_no  consultant_name
***    FROM zsap_timesheet
***    INTO TABLE gt_timesheet WHERE head_it_approve = 'X'.
***
***  SORT gt_timesheet BY doc_no.
***  DELETE ADJACENT DUPLICATES FROM gt_timesheet COMPARING doc_no.
***
***  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
***    EXPORTING
***      retfield    = 'DOC_NO'
***      dynpprog    = sy-repid
***      dynpnr      = sy-dynnr
***      dynprofield = 'P_DOCNO'
***      value_org   = 'S'
***    TABLES
***      value_tab   = gt_timesheet.
***
****----------------------*
**** Fetch Data
****----------------------*
***START-OF-SELECTION.
***
***  SELECT SINGLE *
***  INTO gs_timesheet
***  FROM zsap_timesheet
***  WHERE doc_no = p_docno AND head_it_approve = 'X'.
***
***  IF sy-subrc <> 0.
***    MESSAGE 'Document No not found in ZSAP_TIMESHEET' TYPE 'E'.
***  ENDIF.
***
****----------------------*
**** Get Smartform FM Name
****----------------------*
***  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
***    EXPORTING
***      formname           = 'ZSAP_TIMESHEET_FORM'
***    IMPORTING
***      fm_name            = gv_fm_name
***    EXCEPTIONS
***      no_form            = 1
***      no_function_module = 2
***      OTHERS             = 3.
***
***  IF sy-subrc <> 0.
***    MESSAGE 'Smartform not found' TYPE 'E'.
***  ENDIF.
***
****----------------------*
**** Call Smartform
****----------------------*
***  CALL FUNCTION gv_fm_name
***    EXPORTING
***      doc_no           = p_docno
***      is_timesheet     = gs_timesheet
***    EXCEPTIONS
***      formatting_error = 1
***      internal_error   = 2
***      send_error       = 3
***      user_canceled    = 4
***      OTHERS           = 5.
***
***  IF sy-subrc <> 0.
***    MESSAGE 'Error while printing Smartform' TYPE 'E'.
***  ENDIF.

TABLES :zsap_timesheet.
*----------------------*
* Selection Screen
*----------------------*
SELECT-OPTIONS: s_docno FOR  zsap_timesheet-doc_no .
PARAMETERS: p_from TYPE sy-datum,
            p_to   TYPE sy-datum.
*BOC By SAP_ABAP on 06/10/26
* Scope dropdown: blank = all, AS IS, MICROSOFT
PARAMETERS: p_scope TYPE zsap_timesheet-scope AS LISTBOX VISIBLE LENGTH 20.

DATA: gt_scope_vals TYPE vrm_values,
      gs_scope_val  TYPE vrm_value.
*EOC By SAP_ABAP on 06/10/26

*----------------------*
* Data Declarations
*----------------------*
DATA: gv_fm_name   TYPE rs38l_fnam,
      gs_timesheet TYPE zsap_timesheet,
      lt_data      TYPE  TABLE OF zsap_timesheet.
DATA : p_docno TYPE  zsap_timesheet-doc_no.

TYPES : BEGIN OF doc,
          doc_no          TYPE zsap_timesheet-doc_no,
          consultant_name TYPE zsap_timesheet-consultant_name,
*          datec           TYPE zsap_timesheet-datec,
        END OF doc.

DATA: gt_timesheet TYPE TABLE OF doc.

DATA: ls_control_param  TYPE ssfctrlop,
      ls_composer_param TYPE ssfcompop,
      ls_job_info       TYPE ssfcrescl,
      lv_objectid       TYPE cdhdr-objectid.

DATA: wa_ssfcrescl TYPE ssfcrescl,
      lw_spoolids  TYPE rspoid,
      lw_ssfctrlop TYPE ssfctrlop,
      wa_ssfcompop TYPE ssfcompop,
*     gt_otf       TYPE ssfcrescl,
      wa_line      TYPE itcoo,
      gt_otf_hr    TYPE ssfcrescl,
      gt_otf       TYPE ssfcrescl.
CLEAR :  gt_otf_hr-otfdata[],gt_otf,gt_otf_hr-otfdata.

*BOC By SAP_ABAP on 06/10/26
AT SELECTION-SCREEN OUTPUT.
  CLEAR gt_scope_vals.
  gs_scope_val-key  = 'AS IS'.
  gs_scope_val-text = 'AS IS'.
  APPEND gs_scope_val TO gt_scope_vals.
  gs_scope_val-key  = 'MICROSOFT'.
  gs_scope_val-text = 'MICROSOFT'.
  APPEND gs_scope_val TO gt_scope_vals.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id              = 'P_SCOPE'
      values          = gt_scope_vals
    EXCEPTIONS
      id_illegal_name = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE 'Scope dropdown values could not be set' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
*EOC By SAP_ABAP on 06/10/26

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_docno-low.
  SELECT doc_no  consultant_name
    FROM zsap_timesheet
    INTO TABLE gt_timesheet WHERE head_it_approve = 'X'.

  SORT gt_timesheet BY doc_no.
  DELETE ADJACENT DUPLICATES FROM gt_timesheet COMPARING doc_no.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'DOC_NO'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'S_DOCNO'
      value_org   = 'S'
    TABLES
      value_tab   = gt_timesheet.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_docno-high.
  SELECT doc_no  consultant_name
    FROM zsap_timesheet
    INTO TABLE gt_timesheet WHERE head_it_approve = 'X'.

  SORT gt_timesheet BY doc_no.
  DELETE ADJACENT DUPLICATES FROM gt_timesheet COMPARING doc_no.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'DOC_NO'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'S_DOCNO'
      value_org   = 'S'
    TABLES
      value_tab   = gt_timesheet.

*----------------------*
* Fetch Data
*----------------------*
START-OF-SELECTION.

*  SELECT  *
*  INTO TABLE lt_data
*  FROM zsap_timesheet
*  WHERE doc_no IN s_docno AND head_it_approve = 'X'.
*  SORT lt_data BY doc_no.
*  DELETE ADJACENT DUPLICATES FROM lt_data COMPARING doc_no.


  SELECT *
    INTO TABLE lt_data
    FROM zsap_timesheet
    WHERE head_it_approve = 'X'.
  SORT lt_data BY doc_no.
  " Doc No filter
  IF s_docno IS NOT INITIAL.
    DELETE lt_data WHERE doc_no NOT IN s_docno.
  ENDIF.

  " Date filters
  IF p_from IS NOT INITIAL.
    DELETE lt_data WHERE datec <= p_from.
  ENDIF.

  IF p_to IS NOT INITIAL.
    DELETE lt_data WHERE datec => p_to.
  ENDIF.

*BOC By SAP_ABAP on 06/10/26
* Scope filter - only documents with rows of the chosen Scope are printed.
* Done before the DELETE ADJACENT DUPLICATES below, so the row kept per
* document (passed as IS_TIMESHEET) is one of the chosen Scope.
  IF p_scope IS NOT INITIAL.
    DELETE lt_data WHERE scope <> p_scope.
  ENDIF.

  IF lt_data IS INITIAL.
    MESSAGE 'No approved timesheet found for the selection' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
*EOC By SAP_ABAP on 06/10/26

  SORT lt_data BY doc_no.
  DELETE ADJACENT DUPLICATES FROM lt_data COMPARING doc_no.

*BOC By SAP_ABAP on 06/10/26
* SY-SUBRC here is from DELETE ADJACENT DUPLICATES: 4 = nothing deleted,
* i.e. every document has one row - not "not found". The empty check is
* done above (lt_data IS INITIAL), before the duplicates are removed.
*  IF sy-subrc <> 0.
*    MESSAGE 'Document No not found in ZSAP_TIMESHEET' TYPE 'E'.
*  ENDIF.
*EOC By SAP_ABAP on 06/10/26


*    *  *      *--control parameters
  lw_ssfctrlop-getotf    = 'X'. " To get the OTF data
  lw_ssfctrlop-preview   = 'X'." To get the preview of the form
  lw_ssfctrlop-no_dialog = 'X'." To hide the print priview
*      *screen
  lw_ssfctrlop-device    = 'PRINTER'.

*--output options
  wa_ssfcompop-tdpageslct  = space.         "all pages
  wa_ssfcompop-tdcopies    = 1.             "one copy
  wa_ssfcompop-tddest      = 'LP01'.        "name of printer
  wa_ssfcompop-tdnoprev    = ' '.           "preview
  wa_ssfcompop-tdcover     = space.         "no cover page
  wa_ssfcompop-tdsuffix1   = 'LP01'.


*----------------------*
* Get Smartform FM Name
*----------------------*
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'ZSAP_TIMESHEET_FORM'
    IMPORTING
      fm_name            = gv_fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Smartform not found' TYPE 'E'.
  ENDIF.

*----------------------*
* Call Smartform
*----------------------*
  LOOP AT lt_data INTO gs_timesheet.

    p_docno = gs_timesheet-doc_no.

**    CALL FUNCTION gv_fm_name
**      EXPORTING
**        control_parameters = lw_ssfctrlop
**
**        output_options     = wa_ssfcompop
**
**        doc_no             = p_docno
**        is_timesheet       = gs_timesheet
**
**
**      IMPORTING
***       DOCUMENT_OUTPUT_INFO       =
**        job_output_info    = gt_otf
***       JOB_OUTPUT_OPTIONS =
**      EXCEPTIONS
**        formatting_error   = 1
**        internal_error     = 2
**        send_error         = 3
**        user_canceled      = 4
**        OTHERS             = 5.

    CALL FUNCTION gv_fm_name
      EXPORTING
        control_parameters = lw_ssfctrlop
        output_options     = wa_ssfcompop
        user_settings      = space   "<<< THIS IS MISSING
        doc_no             = p_docno
        is_timesheet       = gs_timesheet
        iv_scope           = p_scope    "Changes by SAP_ABAP on 06/10/26
      IMPORTING
        job_output_info    = gt_otf
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.

    IF sy-subrc <> 0.
      MESSAGE 'Error while printing Smartform' TYPE 'E'.
    ENDIF.

    APPEND LINES OF gt_otf-otfdata[] TO  gt_otf_hr-otfdata[].

    CLEAR: p_docno , gs_timesheet , gt_otf.


  ENDLOOP.

  IF gt_otf_hr IS NOT INITIAL.
    CALL FUNCTION 'HR_IT_DISPLAY_WITH_PDF'
* EXPORTING
*   IV_PDF          =
      TABLES
        otf_table = gt_otf_hr-otfdata[].

*IF gt_otf_f[] IS NOT INITIAL.
*    CALL FUNCTION 'SSFCOMP_PDF_PREVIEW'
*      EXPORTING
*        i_otf                    = gt_otf_f
*      EXCEPTIONS
*        convert_otf_to_pdf_error = 1
*        cntl_error               = 2
*        OTHERS                   = 3.
*    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
  ENDIF.
