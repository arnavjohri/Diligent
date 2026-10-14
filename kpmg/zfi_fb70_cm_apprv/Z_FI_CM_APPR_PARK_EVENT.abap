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
* Date            : 14.10.2026
* Description     : BTE 00002218 (PRELIMINARY POSTING: When document is
*                   saved). Fires inside the FB70 park transaction before
*                   its COMMIT WORK. Filters for a customer credit memo on
*                   first park and registers Z_FI_CM_APPR_START_WF as a
*                   background task, which runs only after the parking
*                   transaction has committed and VBKPF exists.
*                   No database write and no COMMIT WORK here.
* Registration    : FIBF -> Settings -> P/S Modules -> of a customer,
*                   event 00002218, product ZFICMAPR (active).
* Interface       : copied from SAMPLE_INTERFACE_00002218. Keep every
*                   parameter the copy brings, even if unused here.
*----------------------------------------------------------------------*

* ASSUMPTION: FB70 credit memo document type is DG (SAP default).
*             FI to confirm; moves to config table ZFI_CM_APPR_CFG later.
* ASSUMPTION: company code filter left EMPTY = all company codes until
*             FI names the codes. Fill lt_bukrs below to restrict.
  CONSTANTS: gc_blart_cm   TYPE blart VALUE 'DG',
             gc_bstat_park TYPE bstat VALUE 'V'.

  DATA: ls_new   TYPE fvbkpf,
        lt_bukrs TYPE RANGE OF bukrs,
        ls_bukrs LIKE LINE OF lt_bukrs.

  CLEAR ls_new.

* Company codes in scope. Add one APPEND per code once FI confirms, e.g.
*   ls_bukrs-sign = 'I'. ls_bukrs-option = 'EQ'. ls_bukrs-low = '1000'.
*   APPEND ls_bukrs TO lt_bukrs.
  CLEAR lt_bukrs.

*--- 1. New parked header must exist
  READ TABLE t_xvbkpf INTO ls_new INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*--- 2. First park only. On a re-save (FBV2, save as completed) the
*      old header is supplied in T_YVBKPF and the workflow is already
*      running, so do nothing.
* ASSUMPTION: T_YVBKPF is empty on the first park and filled on a
*             re-save. Confirmed by debugger on the first FB70 test;
*             re-check once with FBV2 before transport.
  IF t_yvbkpf[] IS NOT INITIAL.
    RETURN.
  ENDIF.

*--- 3. Document already flagged for workflow release -> never twice
  IF ls_new-xwffr = abap_true.
    RETURN.
  ENDIF.

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

*--- 7. Hand over to the RFC module. IN BACKGROUND TASK = executed only
*      after the parking transaction's COMMIT WORK, in its own LUW, so
*      VBKPF is on the database and the workflow start may COMMIT.
*      If the user cancels the park, this call is discarded with it.
*      Failures are visible in SM58.
  CALL FUNCTION 'Z_FI_CM_APPR_START_WF'
    IN BACKGROUND TASK
    EXPORTING
      iv_bukrs = ls_new-bukrs
      iv_belnr = ls_new-belnr
      iv_gjahr = ls_new-gjahr
      iv_blart = ls_new-blart
      iv_usnam = sy-uname.

ENDFUNCTION.
