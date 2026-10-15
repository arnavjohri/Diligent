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
*                   six BTE tables (X = new, Y = old state). Waits 5 s for
*                   the park to commit, then starts the journal entry
*                   verification workflow through
*                   ZCL_CM_WORKFLOW->START_WORKFLOW (credit memo copy
*                   of ZCL_GL_WORKFLOW, fed from the BTE tables) and
*                   commits. No read of VBKPF; the BTE tables are the data.
*                   Pattern as agreed with the team (Z_JV_MASSGL_WF).
* Error path      : an asynchronous task has no caller to report to; a
*                   log table (object 3) is the place for failures once
*                   it exists.
*----------------------------------------------------------------------*

  DATA: lv_status   TYPE char1,
        lo_workflow TYPE REF TO zcl_cm_workflow.

* Let the FB70 park transaction commit (team pattern)
  WAIT UP TO 5 SECONDS.

* Start the verification workflow from the BTE tables
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

* Own RFC session: nothing commits unless we do. The commit delivers the
* event raised in START_WORKFLOW and writes the XWFFR flag.
  COMMIT WORK AND WAIT.

ENDFUNCTION.
