FUNCTION z_fi_cm_appr_park_event.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      T_XVBKPF STRUCTURE  FVBKPF
*"      T_XVBSEG STRUCTURE  FVBSEG
*"      T_XVBSEC STRUCTURE  FVBSEC
*"      T_YVBKPF STRUCTURE  FVBKPF
*"      T_YVBSEG STRUCTURE  FVBSEG
*"      T_YVBSEC STRUCTURE  FVBSEC
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
* Function module : Z_FI_CM_APPR_PARK_EVENT
* Function group  : ZFI_CM_APPR
* Author          : Arnav Johri
* Date            : 14.10.2026, changed 15.10.2026 (X tables passed on)
*                   23.10.2026: restart after rejection (FBV2 re-save)
* Description     : BTE 00002218 (PRELIMINARY POSTING: When document is
*                   saved). Fires inside the FB70 park transaction before
*                   its COMMIT WORK. Filters for a customer credit memo on
*                   first park, or on a re-save (FBV2) once its last
*                   approval run has ended, and registers Z_FI_CM_APPR_START_WF
*                   IN BACKGROUND TASK: it runs after the park's update
*                   has completed, so VBKPF/BKPF exist when it reads
*                   them. Failures are visible in SM58.
*                   No database write and no COMMIT WORK here.
* Registration    : FIBF -> Settings -> P/S Modules -> of a customer,
*                   event 00002218, product ZFI (existing, active).
* Interface       : copied from SAMPLE_INTERFACE_00002218. Keep every
*                   parameter the copy brings, even if unused here.
*----------------------------------------------------------------------*

* ASSUMPTION: FB70 credit memo document type is DG (SAP default).
*             FI to confirm; moves to config table ZFI_CM_APPR_CFG later.
* ASSUMPTION: company code filter left EMPTY = all company codes until
*             FI names the codes. Fill lt_bukrs below to restrict.
  CONSTANTS: gc_blart_cm   TYPE blart VALUE 'DG',
             gc_bstat_park TYPE vbkpf-bstat VALUE 'V'.
*BOC By Arnav on 23/10/26
* Finished states of an approval run in the scenario view
* C_GLJRNLENTRYTOBEVERIFIED (same literal as ZEI_FI_CM_APPR_POST).
* ASSUMPTION: TaskProcessingStatus carries work item status words (the
*             GL class tests 'ERROR'); a rejected run ends COMPLETED, a
*             withdrawn one CANCELLED.
  CONSTANTS: gc_wf_completed TYPE c LENGTH 9 VALUE 'COMPLETED',
             gc_wf_cancelled TYPE c LENGTH 9 VALUE 'CANCELLED'.

  TYPES ty_wfstat TYPE c LENGTH 20.

  DATA: lv_resave TYPE abap_bool,
        lt_wfstat TYPE STANDARD TABLE OF ty_wfstat WITH DEFAULT KEY,
        lv_wfstat TYPE ty_wfstat.
*EOC By Arnav on 23/10/26

  DATA: ls_new   TYPE fvbkpf,
        lt_bukrs TYPE RANGE OF bukrs,
        ls_bukrs LIKE LINE OF lt_bukrs.

  CLEAR ls_new.
  CLEAR: lv_resave, lt_wfstat, lv_wfstat.                 "Changes by Arnav on 23/10/26

* Company codes in scope. Add one APPEND per code once FI confirms, e.g.
*   ls_bukrs-sign = 'I'. ls_bukrs-option = 'EQ'. ls_bukrs-low = '1000'.
*   APPEND ls_bukrs TO lt_bukrs.
  CLEAR lt_bukrs.

*--- 1. New parked header must exist
  READ TABLE t_xvbkpf INTO ls_new INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*BOC By Arnav on 23/10/26
* Steps 2 and 3 no longer leave the module. A re-save, or a document
* already sent to approval once, is only marked here; step 6a decides
* whether its last approval run has ended (rejected) and may restart.
**--- 2. First park only. On a re-save (FBV2, save as completed) the
**      old header is supplied in T_YVBKPF and the workflow is already
**      running, so do nothing.
** ASSUMPTION: T_YVBKPF is empty on the first park and filled on a
**             re-save. Confirmed by debugger on the first FB70 test;
**             re-check once with FBV2 before transport.
*  IF t_yvbkpf[] IS NOT INITIAL.
*    RETURN.
*  ENDIF.
*
**--- 3. Document already flagged for workflow release -> never twice
*  IF ls_new-xwffr = abap_true.
*    RETURN.
*  ENDIF.

*--- 2./3. Re-save or already submitted -> decided in step 6a
  IF t_yvbkpf[] IS NOT INITIAL OR ls_new-xwffr = abap_true.
    lv_resave = abap_true.
  ENDIF.
*EOC By Arnav on 23/10/26

*--- 4. Parked document only (not held, not posted)
* ASSUMPTION: VBKPF-BSTAT 'V' = parked document.
  IF ls_new-bstat <> gc_bstat_park.
    RETURN.
  ENDIF.

*--- 5. Credit memo document type only
  IF ls_new-blart <> gc_blart_cm.
    RETURN.
  ENDIF.

*--- 6. Company code filter, when maintained
  IF lt_bukrs IS NOT INITIAL AND ls_new-bukrs NOT IN lt_bukrs.
    RETURN.
  ENDIF.

*BOC By Arnav on 23/10/26
*--- 6a. Re-save: restart only when the document is known to the
*       verification scenario and none of its approval runs is still
*       open. A run in process or in error -> no restart (an error run
*       is restarted by the administrator in SWPR). Read before this
*       save's own update, so the view shows the state the approver left.
* ASSUMPTION: a rejected document stays in the view (still parked, app
*             transaction code on BKPF kept). If it does not, nothing
*             restarts - check one rejected document before transport.
* ASSUMPTION: on an FBV2 save T_XVBSEG carries every line of the
*             document, not only the changed ones; the amounts for the
*             agent rule are summed from it. Check the line count once.
  IF lv_resave = abap_true.
    SELECT taskprocessingstatus
      FROM c_gljrnlentrytobeverified
      WHERE accountingdocument = @ls_new-belnr
        AND companycode        = @ls_new-bukrs
        AND fiscalyear         = @ls_new-gjahr
      INTO TABLE @lt_wfstat.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT lt_wfstat INTO lv_wfstat.
      IF lv_wfstat <> gc_wf_completed AND lv_wfstat <> gc_wf_cancelled.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDIF.
*EOC By Arnav on 23/10/26

*--- 7. Hand over to the RFC module as a background task (own LUW, run
*      by the update task after the park's update completed), together
*      with all six BTE tables (X = new, Y = old state). Decided
*      21/10/26 after the asynchronous call raced the park update.
  CALL FUNCTION 'Z_FI_CM_APPR_START_WF'
    IN BACKGROUND TASK
    EXPORTING
      iv_bukrs = ls_new-bukrs
      iv_belnr = ls_new-belnr
      iv_gjahr = ls_new-gjahr
      iv_blart = ls_new-blart
      iv_usnam = sy-uname
    TABLES
      t_xvbkpf = t_xvbkpf
      t_xvbseg = t_xvbseg
      t_xvbsec = t_xvbsec
      t_yvbkpf = t_yvbkpf
      t_yvbseg = t_yvbseg
      t_yvbsec = t_yvbsec.

ENDFUNCTION.
