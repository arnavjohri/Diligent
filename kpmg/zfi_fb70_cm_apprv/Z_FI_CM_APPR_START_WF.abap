FUNCTION z_fi_cm_appr_start_wf.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUKRS) TYPE  BUKRS
*"     VALUE(IV_BELNR) TYPE  BELNR_D
*"     VALUE(IV_GJAHR) TYPE  GJAHR
*"     VALUE(IV_BLART) TYPE  BLART
*"     VALUE(IV_USNAM) TYPE  SYUNAME
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
* Function module : Z_FI_CM_APPR_START_WF
* Function group  : ZFI_CM_APPR
* Author          : Arnav Johri
* Date            : 14.10.2026
* Attributes      : Processing type = Remote-Enabled Module (mandatory,
*                   it is called STARTING NEW TASK). All parameters
*                   pass by value. No exceptions, no export parameters.
* Description     : Called asynchronously by Z_FI_CM_APPR_PARK_EVENT
*                   (BTE 00002218) while FB70 is still saving. Waits 5
*                   seconds for the park to commit, reads the parked
*                   document, then starts the journal entry
*                   verification workflow through the existing
*                   ZCL_GL_WORKFLOW->START_WORKFLOW, exactly as the GL
*                   upload app does, and commits.
*                   Pattern as agreed with the team (Z_JV_MASSGL_WF).
* Error path      : a document not found after the wait, or already in
*                   workflow, is skipped. An asynchronous task has no
*                   caller to report to; a log table (object 3) is the
*                   place for these once it exists.
*----------------------------------------------------------------------*

  DATA: lv_xwffr    TYPE xwffr,
        lv_status   TYPE c LENGTH 1,
        lo_workflow TYPE REF TO zcl_gl_workflow.

  CLEAR: lv_xwffr, lv_status.

*--- 1. Let the FB70 park transaction commit (team pattern)
  WAIT UP TO 5 SECONDS.

*--- 2. Parked document must be on the database
* ASSUMPTION: FB70 is single company code, so VBKPF-BUKRS = VBKPF-AUSBK
*             and the key passed from the BTE (BUKRS) selects the row.
  SELECT SINGLE xwffr
    FROM vbkpf
    WHERE bukrs = @iv_bukrs
      AND belnr = @iv_belnr
      AND gjahr = @iv_gjahr
    INTO @lv_xwffr.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*--- 3. Already in workflow: nothing to do
  IF lv_xwffr = abap_true.
    RETURN.
  ENDIF.

*--- 4. Start the verification workflow. START_WORKFLOW sets XWFFR on
*      the parked document, rewrites it and raises
*      CL_FDC_ACCDOC_VER.SUBMITTED. Both are committed together below.
*      Its returned STATUS is read before the commit, so it is not
*      evaluated here.
  CREATE OBJECT lo_workflow.

  lo_workflow->start_workflow(
    EXPORTING
      journal_entry       = iv_belnr
      source_company_code = iv_bukrs
      fiscal_year         = iv_gjahr
      multiple_wf         = abap_false
    IMPORTING
      status              = lv_status ).

  COMMIT WORK AND WAIT.

ENDFUNCTION.
