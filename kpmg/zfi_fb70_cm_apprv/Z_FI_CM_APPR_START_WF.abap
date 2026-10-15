FUNCTION z_fi_cm_appr_start_wf.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUKRS) TYPE  BUKRS
*"     VALUE(IV_BELNR) TYPE  BELNR_D
*"     VALUE(IV_GJAHR) TYPE  GJAHR
*"     VALUE(IV_BLART) TYPE  BLART
*"     VALUE(IV_USNAM) TYPE  SYUNAME
*"  TABLES
*"      T_XVBKPF STRUCTURE  FVBKPF
*"      T_XVBSEG STRUCTURE  FVBSEG
*"      T_XVBSEC STRUCTURE  FVBSEC
*"      T_YVBKPF STRUCTURE  FVBKPF
*"      T_YVBSEG STRUCTURE  FVBSEG
*"      T_YVBSEC STRUCTURE  FVBSEC
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
* Function module : Z_FI_CM_APPR_START_WF
* Function group  : ZFI_CM_APPR
* Author          : Arnav Johri
* Date            : 14.10.2026, changed 15.10.2026 (X tables, Z class)
* Attributes      : Processing type = Remote-Enabled Module (mandatory,
*                   it is called STARTING NEW TASK). Import parameters
*                   pass by value. No exceptions, no export parameters.
* Description     : Called asynchronously by Z_FI_CM_APPR_PARK_EVENT
*                   (BTE 00002218) while FB70 is still saving, with all
*                   six BTE tables (X = new, Y = old state). Waits 5 s for the
*                   park to commit, confirms the document is on the
*                   database, then starts the journal entry
*                   verification workflow through
*                   ZCL_CM_WORKFLOW->START_WORKFLOW (credit memo copy
*                   of ZCL_GL_WORKFLOW, fed from the X tables) and
*                   commits. Rolls back if no event was raised.
*                   Pattern as agreed with the team (Z_JV_MASSGL_WF).
* Error path      : a document not found after the wait, or already in
*                   workflow, is skipped. An asynchronous task has no
*                   caller to report to; a log table (object 3) is the
*                   place for these once it exists.
*----------------------------------------------------------------------*

  DATA: lv_xwffr    TYPE xwffr,
        lv_status   TYPE char1,
        lo_workflow TYPE REF TO zcl_cm_workflow.

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

*--- 4. Start the verification workflow from the X tables.
*      START_WORKFLOW sets XWFFR on the parked document and raises
*      CL_FDC_ACCDOC_VER.SUBMITTED. Both are committed together below,
*      or both discarded when no event was raised.
  IF t_xvbkpf[] IS INITIAL.
    RETURN.
  ENDIF.

  CREATE OBJECT lo_workflow.

  lo_workflow->start_workflow(
    EXPORTING
      it_vbkpf     = t_xvbkpf[]
      it_vbseg     = t_xvbseg[]
      it_vbsec     = t_xvbsec[]
      it_yvbkpf    = t_yvbkpf[]
      it_yvbseg    = t_yvbseg[]
      it_yvbsec    = t_yvbsec[]
      iv_submitter = iv_usnam
    IMPORTING
      ev_status    = lv_status ).

  IF lv_status = zcl_cm_workflow=>gc_status_ok.
    COMMIT WORK AND WAIT.
  ELSE.
    ROLLBACK WORK.
  ENDIF.

ENDFUNCTION.
