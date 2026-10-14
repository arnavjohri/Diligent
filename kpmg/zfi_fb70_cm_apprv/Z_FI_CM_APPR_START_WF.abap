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
*                   it is called IN BACKGROUND TASK). All parameters
*                   pass by value. No exceptions, no export parameters.
* Description     : Runs in its own LUW after the FB70 park has
*                   committed (registered by Z_FI_CM_APPR_PARK_EVENT on
*                   BTE 00002218). Confirms the parked document is on
*                   the database, then starts the journal entry
*                   verification workflow through the existing
*                   ZCL_GL_WORKFLOW->START_WORKFLOW, exactly as the GL
*                   upload app does, and commits.
* Error path      : every failure ends in MESSAGE type E. In a
*                   background task that marks the LUW as failed in
*                   SM58 with the text, where it can be re-executed.
*                   Re-execution is safe: a document whose workflow
*                   flag is already set is skipped.
*----------------------------------------------------------------------*

  CONSTANTS: gc_retries TYPE i VALUE 5,
             gc_wf_err  TYPE c LENGTH 5 VALUE 'ERROR'.

  DATA: lv_xwffr     TYPE xwffr,
        lv_found     TYPE abap_bool,
        lv_status    TYPE c LENGTH 1,
        lv_wf_status TYPE c LENGTH 20,
        lo_workflow  TYPE REF TO zcl_gl_workflow.

  CLEAR: lv_xwffr, lv_found, lv_status, lv_wf_status.

*--- 1. Parked document must be on the database. The background task
*      starts after the park commit, so normally the first read hits.
*      The bounded retry only covers a slow update server.
* ASSUMPTION: FB70 is single company code, so VBKPF-BUKRS = VBKPF-AUSBK
*             and the key passed from the BTE (BUKRS) selects the row.
  DO gc_retries TIMES.
    SELECT SINGLE xwffr
      FROM vbkpf
      WHERE bukrs = @iv_bukrs
        AND belnr = @iv_belnr
        AND gjahr = @iv_gjahr
      INTO @lv_xwffr.
    IF sy-subrc = 0.
      lv_found = abap_true.
      EXIT.
    ENDIF.
    WAIT UP TO 1 SECONDS.
  ENDDO.

  IF lv_found = abap_false.
    MESSAGE e398(00)
      WITH 'Parked document' iv_bukrs iv_belnr
           'not found - credit memo workflow not started'.
  ENDIF.

*--- 2. Already in workflow (re-execution from SM58, or a parallel
*      start): nothing to do.
  IF lv_xwffr = abap_true.
    RETURN.
  ENDIF.

*--- 3. Start the verification workflow. START_WORKFLOW sets XWFFR on
*      the parked document, rewrites it and raises
*      CL_FDC_ACCDOC_VER.SUBMITTED. Both are committed together below,
*      so on any failure neither is on the database.
*      Its returned STATUS is read before the commit and is therefore
*      not used here; the real check is step 4.
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

*--- 4. Confirm the workflow instance exists. The event is delivered
*      after the commit, so allow it a few seconds.
* ASSUMPTION: CDS C_GLJRNLENTRYTOBEVERIFIED and its fields are those
*             used by ZCL_GL_WORKFLOW->START_WORKFLOW on this system.
  CLEAR lv_found.
  DO gc_retries TIMES.
    SELECT SINGLE taskprocessingstatus
      FROM c_gljrnlentrytobeverified
      WHERE accountingdocument = @iv_belnr
        AND companycode        = @iv_bukrs
        AND fiscalyear         = @iv_gjahr
      INTO @lv_wf_status.
    IF sy-subrc = 0 AND lv_wf_status <> gc_wf_err.
      lv_found = abap_true.
      EXIT.
    ENDIF.
    WAIT UP TO 1 SECONDS.
  ENDDO.

  IF lv_found = abap_false.
    MESSAGE e398(00)
      WITH 'Credit memo workflow not started for' iv_bukrs iv_belnr
           iv_gjahr.
  ENDIF.

ENDFUNCTION.
