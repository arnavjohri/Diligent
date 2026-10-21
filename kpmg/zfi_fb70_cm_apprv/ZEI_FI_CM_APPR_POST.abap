*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_FI_CM_APPR_POST   (new)
* Spot                       : implicit, BEGINNING of method
*   CL_FDC_ACCDOC_VER->IF_FDC_ACCDOC_VER~POST
*   (posting task TS02800036 of the GL verification scenario WS02800046)
* Author / date              : Arnav Johri, 21/10/26
* Why: the standard converts the parked document into the Fiori G/L
*   app's temporary document (ACCDOC_FUNC_PARKD_DOC_READ_UPD) and posts
*   that. The model has G/L lines only; a customer credit memo is
*   rejected with FDC_POSTING_001 092 "Parked document is no GL posting".
*   For a document with a customer line this block posts the parked
*   document the classic way instead - PRELIMINARY_POSTING_POST_ALL, as
*   FBV0 and the standard object FIPP method POST do - sets the workflow
*   status exactly as the standard method does, and leaves the method.
*   G/L-only documents (JV upload app) never enter the block.
* Create via: SE24, CL_FDC_ACCDOC_VER, method IF_FDC_ACCDOC_VER~POST,
*   Enhance (spiral), Edit -> Enhancement Operations -> Show Implicit
*   Enhancement Options, right-click the line after METHOD ...,
*   Create Implementation, Code, name ZEI_FI_CM_APPR_POST. Paste the
*   block between ENHANCEMENT and ENDENHANCEMENT. Activate.
* Variables carry the prefix ZCM to avoid the method's own LT_VBKPF /
*   LS_VBKPF.
* Entry conditions (Arnav 21/10/26): work item of posting task
*   TS02800036 exists for the document, VBKPF-BSTAT = 'V', BLART = 'DG'.
*   Anything else runs the standard code.
* ASSUMPTION: credit memo document type 'DG', same constant as the BTE
*   module; change both together if FI uses another type.
* ASSUMPTION: WF-BATCH holds the FI posting authorisations for customer
*   documents (F_BKPF_BUK, F_BKPF_KOA for account type D, F_KNA1_BUK).
*   Posting runs under that user.
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_FI_CM_APPR_POST.    "active version
*BOC By Arnav on 21/10/26
  CONSTANTS: lc_zcm_blart TYPE blart VALUE 'DG',
             lc_zcm_bstat TYPE bstat VALUE 'V',
             lc_zcm_task  TYPE sww_wi2obj-wi_rh_task VALUE 'TS02800036'.

  DATA: lt_zcm_vbkpf TYPE STANDARD TABLE OF vbkpf,
        ls_zcm_vbkpf TYPE vbkpf,
        lt_zcm_msg   TYPE STANDARD TABLE OF fimsg1,
        ls_zcm_msg   TYPE fimsg1,
        ls_zcm_key   TYPE if_fdc_je_wf_list_db=>ts_fdc_je_wf_list_key,
        lv_zcm_instid TYPE sww_wi2obj-instid,
        lv_zcm_wi_id  TYPE sww_wi2obj-wi_id,
        lv_zcm_blart  TYPE blart,
        lv_zcm_bstat  TYPE bstat,
        lv_zcm_apply  TYPE abap_bool.

* Entry conditions, all three required, else the standard code runs:
*   1. called from the workflow: a work item of the posting task exists
*      for this document (same table and key as the agent rule uses);
*   2. the document is parked (VBKPF-BSTAT 'V');
*   3. it is a credit memo (VBKPF-BLART 'DG', as in the BTE module).
  CLEAR: lv_zcm_apply, lv_zcm_wi_id, lv_zcm_blart, lv_zcm_bstat.

  CONCATENATE me->belnr me->ausbk me->gjahr INTO lv_zcm_instid.
  CONDENSE lv_zcm_instid.
  SELECT SINGLE wi_id
    FROM sww_wi2obj
    WHERE instid     = @lv_zcm_instid
      AND wi_rh_task = @lc_zcm_task
    INTO @lv_zcm_wi_id.
  IF sy-subrc = 0.
    SELECT SINGLE blart, bstat
      FROM vbkpf
      WHERE ausbk = @me->ausbk
        AND belnr = @me->belnr
        AND gjahr = @me->gjahr
      INTO ( @lv_zcm_blart, @lv_zcm_bstat ).
    IF sy-subrc = 0
       AND lv_zcm_bstat = lc_zcm_bstat
       AND lv_zcm_blart = lc_zcm_blart.
      lv_zcm_apply = abap_true.
    ENDIF.
  ENDIF.

  IF lv_zcm_apply = abap_true.

    ls_zcm_key-bukrs = me->ausbk.
    ls_zcm_key-belnr = me->belnr.
    ls_zcm_key-gjahr = me->gjahr.

*   Lock, as FIPP does before posting
    CALL FUNCTION 'ENQUEUE_EFBKPF'
      EXPORTING
        belnr          = me->belnr
        bukrs          = me->ausbk
        gjahr          = me->gjahr
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_swf_flex_ifs_run_exception
        EXPORTING
          textid          = VALUE #( msgid = sy-msgid msgno = sy-msgno
                                     attr1 = sy-msgv1 attr2 = sy-msgv2
                                     attr3 = sy-msgv3 attr4 = sy-msgv4 )
          business_textid = VALUE #( msgid = sy-msgid msgno = sy-msgno
                                     attr1 = sy-msgv1 attr2 = sy-msgv2
                                     attr3 = sy-msgv3 attr4 = sy-msgv4 ).
    ENDIF.

*   Approval is complete: set the release flag so the classic posting
*   does not refuse a document that still "requires release" (XWFFR).
*   Same call as FIPP method FLAGRELEASESET.
    CALL FUNCTION 'PRELIMINARY_POSTING_REL_SET'
      EXPORTING
        belnr              = me->belnr
        bukrs              = me->ausbk
        gjahr              = me->gjahr
      EXCEPTIONS
        document_not_found = 1
        update_error       = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
      CALL FUNCTION 'DEQUEUE_EFBKPF'
        EXPORTING
          belnr = me->belnr
          bukrs = me->ausbk
          gjahr = me->gjahr.
      RAISE EXCEPTION TYPE cx_swf_flex_ifs_run_exception
        EXPORTING
          textid          = VALUE #( msgid = sy-msgid msgno = sy-msgno
                                     attr1 = sy-msgv1 attr2 = sy-msgv2
                                     attr3 = sy-msgv3 attr4 = sy-msgv4 )
          business_textid = VALUE #( msgid = sy-msgid msgno = sy-msgno
                                     attr1 = sy-msgv1 attr2 = sy-msgv2
                                     attr3 = sy-msgv3 attr4 = sy-msgv4 ).
    ENDIF.

*   Post the parked document (as FIPP method POST / FBV0)
    CLEAR: lt_zcm_vbkpf, lt_zcm_msg, ls_zcm_vbkpf, ls_zcm_msg.
    ls_zcm_vbkpf-belnr = me->belnr.
    ls_zcm_vbkpf-bukrs = me->ausbk.
    ls_zcm_vbkpf-gjahr = me->gjahr.
    APPEND ls_zcm_vbkpf TO lt_zcm_vbkpf.

    CALL FUNCTION 'PRELIMINARY_POSTING_POST_ALL'
      EXPORTING
        nomsg   = 'X'
        synch   = 'X'
      TABLES
        t_vbkpf = lt_zcm_vbkpf
        t_msg   = lt_zcm_msg.

    READ TABLE lt_zcm_msg INTO ls_zcm_msg INDEX 1.

    CALL FUNCTION 'DEQUEUE_EFBKPF'
      EXPORTING
        belnr = me->belnr
        bukrs = me->ausbk
        gjahr = me->gjahr.

*   Workflow status, as the standard method sets it below
    DATA(lo_zcm_status) = clf_fdc_je_wf_list=>get_instance(
                            )->get_fdc_je_wf_status_mng( ).

    IF ls_zcm_msg-posted = 'X'.
      lo_zcm_status->modify_status(
        is_je_key = ls_zcm_key
        iv_status = if_fdc_je_wf_list_db=>gc_wf_status-posted ).
      COMMIT WORK.
      RETURN.
    ENDIF.

    lo_zcm_status->modify_status(
      is_je_key = ls_zcm_key
      iv_status = if_fdc_je_wf_list_db=>gc_wf_status-failed ).
    RAISE EXCEPTION TYPE cx_swf_flex_ifs_run_exception
      EXPORTING
        textid          = VALUE #( msgid = ls_zcm_msg-msgid
                                   msgno = ls_zcm_msg-msgno
                                   attr1 = ls_zcm_msg-msgv1
                                   attr2 = ls_zcm_msg-msgv2
                                   attr3 = ls_zcm_msg-msgv3
                                   attr4 = ls_zcm_msg-msgv4 )
        business_textid = VALUE #( msgid = ls_zcm_msg-msgid
                                   msgno = ls_zcm_msg-msgno
                                   attr1 = ls_zcm_msg-msgv1
                                   attr2 = ls_zcm_msg-msgv2
                                   attr3 = ls_zcm_msg-msgv3
                                   attr4 = ls_zcm_msg-msgv4 ).
  ENDIF.
*EOC By Arnav on 21/10/26
ENDENHANCEMENT.
