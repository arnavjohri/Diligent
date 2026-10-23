*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_FI_CM_APPR_REDO   (new)
* Spot                       : implicit, END of method
*   CL_FDC_ACCDOC_POST->ACCDOC_POST
* Author / date              : Arnav Johri, 23/10/26
* Why: after a rejection the GL verification workflow WS02800046 waits
*   in a Redo decision (TS00008267) at the initiator. For SA the Verify
*   app's Submit completes it with decision 0001 (resubmit) and the same
*   workflow returns to the manager. For a customer credit memo (DG) the
*   Submit re-parks the document (ACCDOC_POST -> AC_DOCUMENT_POST, success
*   message FDC_POSTING_001 129) but the Redo item stays open. Completing
*   it from My Inbox works (tested 23/10/26). This block does the same
*   completion at the end of the re-park, in the same LUW: the app's
*   transaction_save commits both together, a rejected save commits
*   neither.
* Entry conditions, all required:
*   - re-park succeeded (RV_SAVE_REJECTED initial, posted number set);
*   - update of a parked document submitted complete (STATUS_OLD filled,
*     STATUS_NEW = complete), app transaction code;
*   - BKPF-BLART = DG (SA and every other type: standard only);
*   - latest task of the document's workflow is the Redo decision
*     TS00008267 and still open (READY / SELECTED / STARTED).
* Not done: the workflow amounts are not refreshed (the standard REDO
*   does that via modify_workflow_input); same as completing in My Inbox.
*   If the requester changes the amount, the next approver is still
*   determined on the old amount.
* Create via: SE24, CL_FDC_ACCDOC_POST, method ACCDOC_POST, Display,
*   Enhance (spiral), Edit -> Enhancement Operations -> Show Implicit
*   Enhancement Options, right-click the line before ENDMETHOD,
*   Enhancement Implementation -> Create Implementation, Code, name
*   ZEI_FI_CM_APPR_REDO, Z package and request. Paste the block between
*   ENHANCEMENT and ENDENHANCEMENT. Activate.
* Switch-off: deactivate the implementation (SE19).
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_FI_CM_APPR_REDO.    "active version
*BOC By Arnav on 23/10/26
* ASSUMPTION: Submit in the Verify app parks with STATUS_NEW = complete
*             (park complete); a plain save would be "untested".
* ASSUMPTION: CL_FDC_ACCDOC_VER_SERVICES=>GET_WORKFLOW_ID and
*             GET_WF_LATEST_TASK are public (CL_FDC_ACCDOC_VER_BASE->
*             IF_FDC_ACCDOC_VER~REDO calls them from outside the class).
* ASSUMPTION: decision key 0001 = resubmit (SAP comment in REDO).
  CONSTANTS: lc_zcm_blart     TYPE bkpf-blart VALUE 'DG',
             lc_zcm_redo_task TYPE swwwihead-wi_rh_task VALUE 'TS00008267'.

  DATA: lv_zcm_blart   TYPE bkpf-blart,
        lv_zcm_wf_id   TYPE sww_wiid,
        lv_zcm_wi_id   TYPE sww_wiid,
        lv_zcm_task    TYPE swwwihead-wi_rh_task,
        lv_zcm_stat    TYPE swwwihead-wi_stat,
        lv_zcm_retcode TYPE sy-subrc,
        lt_zcm_wapimsg TYPE STANDARD TABLE OF swr_messag,
        ls_zcm_wapimsg TYPE swr_messag,
        ls_zcm_msg     TYPE bapiret2.

  CLEAR: lv_zcm_blart, lv_zcm_wf_id, lv_zcm_wi_id, lv_zcm_task,
         lv_zcm_stat, lv_zcm_retcode, lt_zcm_wapimsg.

  IF rv_save_rejected IS INITIAL
     AND es_posted_document-belnr IS NOT INITIAL
     AND is_fdc_accdoc_hdr-status_old IS NOT INITIAL
     AND is_fdc_accdoc_hdr-status_new = if_fdc_accdoc_types=>gc_acc_status-complete
     AND is_fdc_accdoc_hdr-tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting.

    SELECT SINGLE blart
      FROM bkpf
      WHERE bukrs = @is_fdc_accdoc_hdr-bukrs
        AND belnr = @is_fdc_accdoc_hdr-belnr
        AND gjahr = @is_fdc_accdoc_hdr-gjahr
      INTO @lv_zcm_blart.

    IF sy-subrc = 0 AND lv_zcm_blart = lc_zcm_blart.

*     Same lookup as the standard REDO: document -> workflow -> latest task
      lv_zcm_wf_id = cl_fdc_accdoc_ver_services=>get_workflow_id(
                       iv_ausbk = is_fdc_accdoc_hdr-bukrs
                       iv_belnr = is_fdc_accdoc_hdr-belnr
                       iv_gjahr = is_fdc_accdoc_hdr-gjahr ).

      IF lv_zcm_wf_id IS NOT INITIAL.
        lv_zcm_wi_id = cl_fdc_accdoc_ver_services=>get_wf_latest_task(
                         iv_top_workitem = lv_zcm_wf_id )-wi_id.
      ENDIF.

      IF lv_zcm_wi_id IS NOT INITIAL.
        SELECT SINGLE wi_rh_task, wi_stat
          FROM swwwihead
          WHERE wi_id = @lv_zcm_wi_id
          INTO ( @lv_zcm_task, @lv_zcm_stat ).
      ENDIF.

*     Only the open Redo decision - never the approver's Verify step
      IF lv_zcm_wi_id IS NOT INITIAL
         AND lv_zcm_task = lc_zcm_redo_task
         AND ( lv_zcm_stat = 'READY' OR lv_zcm_stat = 'SELECTED' OR lv_zcm_stat = 'STARTED' ).

        CALL FUNCTION 'SAP_WAPI_DECISION_COMPLETE'
          EXPORTING
            workitem_id   = lv_zcm_wi_id
            decision_key  = '0001'
            do_commit     = ' '
          IMPORTING
            return_code   = lv_zcm_retcode
          TABLES
            message_lines = lt_zcm_wapimsg.

        IF lv_zcm_retcode <> 0.
*         Type S on purpose: a W or E here would stop the app's save
          CLEAR ls_zcm_msg.
          ls_zcm_msg-type    = 'S'.
          ls_zcm_msg-message = 'Approval not resumed - complete the Redo item in My Inbox'. "#EC NOTEXT
          APPEND ls_zcm_msg TO et_message.
          LOOP AT lt_zcm_wapimsg INTO ls_zcm_wapimsg.
            CLEAR ls_zcm_msg.
            ls_zcm_msg-type    = 'S'.
            ls_zcm_msg-message = ls_zcm_wapimsg-line.
            APPEND ls_zcm_msg TO et_message.
          ENDLOOP.
        ENDIF.

      ENDIF.
    ENDIF.
  ENDIF.
*EOC By Arnav on 23/10/26
ENDENHANCEMENT.
