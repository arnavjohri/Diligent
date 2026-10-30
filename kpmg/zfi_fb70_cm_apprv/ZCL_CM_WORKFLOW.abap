*----------------------------------------------------------------------*
* Class       : ZCL_CM_WORKFLOW
* Author      : Arnav Johri
* Date        : 15.10.2026, changed 27.10.2026 (AWTYP BKPFF),
*               30.10.2026 (SEND_MAIL)
* Description : Copy of ZCL_GL_WORKFLOW->START_WORKFLOW for a customer
*               credit memo parked in FB70. Same code, except:
*               - PRELIMINARY_POSTING_DOC_READ removed: the tables come
*                 in from BTE 00002218 (IT_VBKPF, IT_VBSEG, IT_VBSEC);
*               - PRELIMINARY_POSTING_DOC_WRITE replaced by UPDATEs of
*                 XWFFR and TCODE on VBKPF and TCODE on BKPF (no VBSET
*                 from the BTE; TCODE rewrite needed by the GL scenario);
*               - the status SELECT at the end removed: it runs before
*                 the caller's COMMIT WORK and would always give 'E'.
* Create via  : ADT or SE24 source-based, paste whole file.
*----------------------------------------------------------------------*
CLASS zcl_cm_workflow DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: tt_vbkpf TYPE STANDARD TABLE OF fvbkpf WITH DEFAULT KEY,
           tt_vbseg TYPE STANDARD TABLE OF fvbseg WITH DEFAULT KEY,
           tt_vbsec TYPE STANDARD TABLE OF fvbsec WITH DEFAULT KEY.

    CONSTANTS: gc_status_ok  TYPE char1 VALUE 'S',
               gc_status_err TYPE char1 VALUE 'E'.

    METHODS start_workflow
      IMPORTING
        it_vbkpf     TYPE tt_vbkpf
        it_vbseg     TYPE tt_vbseg
        it_vbsec     TYPE tt_vbsec OPTIONAL
        it_yvbkpf    TYPE tt_vbkpf OPTIONAL
        it_yvbseg    TYPE tt_vbseg OPTIONAL
        it_yvbsec    TYPE tt_vbsec OPTIONAL
        iv_submitter TYPE syuname OPTIONAL
      EXPORTING
        ev_status    TYPE char1.

*BOC By Arnav on 30/10/26
* Mail for the CM approval matrix (FS 30/10/26). Static so that the
* RFC FM Z_CM_WF_MAIL_SEND, the agent rule patch and the POST / reject
* enhancements can call it without an instance. No COMMIT inside: the
* caller commits (send) or rolls back (ev_sent = abap_false).
    CONSTANTS: gc_mail_approval TYPE char1 VALUE 'A',   " level n approval needed
               gc_mail_final    TYPE char1 VALUE 'F',   " final approval confirmation
               gc_mail_reject   TYPE char1 VALUE 'R'.   " rejected

    CLASS-METHODS send_mail
      IMPORTING
        iv_bukrs     TYPE bukrs
        iv_belnr     TYPE belnr_d
        iv_gjahr     TYPE gjahr
        iv_kind      TYPE char1
        iv_level     TYPE numc2 OPTIONAL
        iv_approver  TYPE syuname OPTIONAL
        iv_initiator TYPE syuname OPTIONAL
      EXPORTING
        ev_sent      TYPE abap_bool
        ev_msg       TYPE string.
*EOC By Arnav on 30/10/26

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_cm_workflow IMPLEMENTATION.

  METHOD start_workflow.
** Data Declarations
    DATA: lv_objtype          TYPE sibftypeid,
          lv_event            TYPE sibfevent,
          lt_vbkpf            TYPE STANDARD TABLE OF fvbkpf,
          lt_vbseg            TYPE STANDARD TABLE OF fvbseg,
          lt_vbsec            TYPE STANDARD TABLE OF fvbsec,
          lr_event_parameters TYPE REF TO if_swf_ifs_parameter_container,
          ls_lpor             TYPE sibflpor,
          lv_amt_coc          TYPE vbsegs-dmbtr,
          lv_amt_glb          TYPE vbsegs-dmbe2,
          lv_amt_third        TYPE vbsegs-dmbe3,
          lv_amt_func         TYPE vbsegs-wrbtr,
          lv_submitter        TYPE string,
          it_costcenter       TYPE kostl_t,
          it_accountgroup     TYPE ktoks_t,
          it_companycode      TYPE fdc_bukrs_t.

    ev_status = gc_status_err.

* Setting values of Event Name
    lv_objtype = 'CL_FDC_ACCDOC_VER'. " Your Class Name
    lv_event   = 'SUBMITTED'.  " Event Name.

* Document as handed over by BTE 00002218 (was PRELIMINARY_POSTING_DOC_READ)
    lt_vbkpf = it_vbkpf.
    lt_vbseg = it_vbseg.
    lt_vbsec = it_vbsec.

    READ TABLE  lt_vbkpf ASSIGNING FIELD-SYMBOL(<fs_vbkpf>) INDEX 1.
    IF sy-subrc EQ 0.
      <fs_vbkpf>-xwffr =  abap_true.
    ELSE.
      RETURN.
    ENDIF.

    LOOP AT lt_vbseg ASSIGNING FIELD-SYMBOL(<fs_vbseg>).
      IF <fs_vbseg>-bzalt IS INITIAL.
        <fs_vbseg>-bzalt = <fs_vbseg>-buzei.
      ENDIF.
    ENDLOOP.

* Release flag on the parked header (was PRELIMINARY_POSTING_DOC_WRITE;
* no VBSET from the BTE, so only the flag is written) plus the Fiori app
* transaction code on both headers: the GL verification scenario's views
* filter on BKPF-TCODE in (FBDC_P001, FBDC_P050, FBDC_P051), and its
* posting check (enhancement ZEI_GL_WORKLFOW_INTR) keys on the same code.
* Decision Gaurav/Arnav 21/10/26: stay on the GL scenario with these
* rewrites. Document not on the database yet -> no event (RETURN).
*BOC By Arnav on 27/10/26
* Reference type BKPFF as well, as on every document the Fiori app creates
* (SE16 BKPF 27/10/26: app documents BKPFF, FB70 documents BKPF; AWKEY has
* the same format in both). On a resubmit from the Verify app the
* accounting interface processes the FI part only for BKPFF: with BKPF,
* FI_DOCUMENT_POST stops at CHECK process EQ char_x and nothing is saved.
    CONSTANTS lc_awtyp_interface TYPE bkpf-awtyp VALUE 'BKPFF'.

*    UPDATE vbkpf
*      SET xwffr = @abap_true,
*          tcode = @cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting
*      WHERE ausbk = @<fs_vbkpf>-ausbk
*        AND belnr = @<fs_vbkpf>-belnr
*        AND gjahr = @<fs_vbkpf>-gjahr.
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.
*
*    UPDATE bkpf
*      SET tcode = @cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting
*      WHERE bukrs = @<fs_vbkpf>-bukrs
*        AND belnr = @<fs_vbkpf>-belnr
*        AND gjahr = @<fs_vbkpf>-gjahr.
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.
    UPDATE vbkpf
      SET xwffr = @abap_true,
          tcode = @cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting,
          awtyp = @lc_awtyp_interface
      WHERE ausbk = @<fs_vbkpf>-ausbk
        AND belnr = @<fs_vbkpf>-belnr
        AND gjahr = @<fs_vbkpf>-gjahr.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    UPDATE bkpf
      SET tcode = @cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting,
          awtyp = @lc_awtyp_interface
      WHERE bukrs = @<fs_vbkpf>-bukrs
        AND belnr = @<fs_vbkpf>-belnr
        AND gjahr = @<fs_vbkpf>-gjahr.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
*EOC By Arnav on 27/10/26

    IF lt_vbseg IS NOT INITIAL.
      SELECT saknr , ktoks FROM ska1 FOR ALL ENTRIES IN @lt_vbseg
        WHERE saknr = @lt_vbseg-saknr INTO TABLE @DATA(lt_acc_grp).
    ENDIF.

    LOOP AT lt_vbseg INTO DATA(ls_item).
      IF ls_item-kostl IS NOT INITIAL.
        APPEND ls_item-kostl TO it_costcenter.
      ENDIF.

      READ TABLE lt_acc_grp INTO DATA(ls_acc_grp) WITH KEY saknr = ls_item-saknr.
      IF sy-subrc EQ 0 AND ls_acc_grp-ktoks IS NOT INITIAL.
        APPEND ls_acc_grp-ktoks  TO it_accountgroup.
      ENDIF.

    ENDLOOP.

    READ TABLE lt_vbkpf INTO DATA(ls_vbkpf) INDEX 1.
    APPEND ls_vbkpf-bukrs TO it_companycode.
    CLEAR:lv_amt_coc,lv_amt_glb,lv_amt_third,lv_amt_func.
    LOOP AT lt_vbseg INTO DATA(ls_vbseg) WHERE shkzg = 'S'.
      lv_amt_coc   =  lv_amt_coc +  ls_vbseg-dmbtr.
      lv_amt_glb   =  lv_amt_glb +  ls_vbseg-dmbe2.
      lv_amt_third =  lv_amt_third +  ls_vbseg-dmbe3.
      lv_amt_func  =  lv_amt_func +  ls_vbseg-wrbtr.
    ENDLOOP.

    DATA(lr_wf_cm) = NEW cl_fdc_accdoc_ver( iv_accdocnumber = ls_vbkpf-belnr
                                    iv_sourcecompanycode = ls_vbkpf-bukrs
                                    iv_fiscalyear = ls_vbkpf-gjahr
                                    iv_amountincocdcrcy = lv_amt_coc
                                    iv_accountingdocumenttype = ls_vbkpf-blart
                                    iv_amountinglobcrcy =  lv_amt_glb
                                    iv_amountinthirdcrcy =  lv_amt_third
                                    iv_amountinfunccrcy = lv_amt_func
                                    it_costcenter = it_costcenter
                                    it_accountgroup     = it_accountgroup
                                    it_companycode   = it_companycode
                                                                        ).

    ls_lpor-instid = lr_wf_cm->ms_por-instid. "Get the key

    CALL METHOD cl_swf_evt_event=>get_event_container
      EXPORTING
        im_objcateg  = cl_swf_evt_event=>mc_objcateg_cl
        im_objtype   = lv_objtype
        im_event     = lv_event
      RECEIVING
        re_reference = lr_event_parameters.

    IF iv_submitter IS NOT INITIAL.
      lv_submitter = 'US' && iv_submitter.
    ELSE.
      lv_submitter = 'US' && sy-uname.
    ENDIF.

    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AccountingDocumentType'
            value = lr_wf_cm->blart.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInCompanyCodeCurrency'
            value = lr_wf_cm->dmbtr.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInGlobalCurrency'
            value = lr_wf_cm->dmbe2.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInThirdCurrency'
            value = lr_wf_cm->dmbe3.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInFunctionalCurrency'
            value = lr_wf_cm->fcsl.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'CostCenter_T'
            value = lr_wf_cm->mt_costcenter.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AccountGroup_T'
            value = lr_wf_cm->mt_accountgroup.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'CompanyCode_T'
            value = lr_wf_cm->mt_companycode.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'Submitter'
            value = lv_submitter.
      CATCH cx_root .
    ENDTRY.
*
* Raise the event passing the prepared event container
* (delivered on the COMMIT WORK in Z_FI_CM_APPR_START_WF)
    TRY.
        CALL METHOD cl_swf_evt_event=>raise
          EXPORTING
            im_objcateg        = cl_swf_evt_event=>mc_objcateg_cl
            im_objtype         = lv_objtype
            im_event           = lv_event
            im_objkey          = ls_lpor-instid
            im_event_container = lr_event_parameters.
        ev_status = gc_status_ok.
      CATCH cx_swf_evt_invalid_objtype .
        ev_status = gc_status_err.
      CATCH cx_swf_evt_invalid_event .
        ev_status = gc_status_err.
    ENDTRY.

    CLEAR: lv_amt_coc,lv_amt_glb,lv_amt_third,lv_amt_func,ls_vbkpf,
           ls_lpor,lr_event_parameters,lr_wf_cm.
    REFRESH:  lt_vbkpf  ,
              lt_vbseg  ,
              lt_vbsec  ,
              it_costcenter  ,
              it_accountgroup ,
              it_companycode.
  ENDMETHOD.

  METHOD send_mail.
*BOC By Arnav on 30/10/26
* Mail per the CM approval matrix:
*   A  initiator + approver of iv_level   "Level n approval needed"
*   F  initiator                          "Final approval confirmation"
*   R  initiator                          "Rejected"
* One row in ZCM_WF_MAIL_LOG per mail; the INSERT is the duplicate guard,
* so a second call for the same document / kind / level / agent sends
* nothing (the agent rule runs more than once per level).
* ASSUMPTION: addresses from the SAP user master (USR21 -> ADR6), not from
*   PA0105 0010. A user without an address in SU01 is reported in EV_MSG.
* ASSUMPTION: the parked header is read with AUSBK = IV_BUKRS; cross-
*   company credit memos are not in scope.
* ASSUMPTION: amount shown is the customer line in document currency
*   (VBSEGD-WRBTR while parked, BSEG-WRBTR KOART D once posted).
* ASSUMPTION: the sender is the executing user (WF-BATCH from the rule).
*   WF-BATCH needs an e-mail address in SU01, else BCS refuses to send.
    TYPES: BEGIN OF ty_rcpt,
             uname TYPE syuname,
             smtp  TYPE ad_smtpadr,
             name  TYPE ad_namtext,
           END OF ty_rcpt.

    DATA: lt_rcpt      TYPE STANDARD TABLE OF ty_rcpt,
          ls_rcpt      TYPE ty_rcpt,
          ls_log       TYPE zcm_wf_mail_log,
          lv_initiator TYPE syuname,
          lv_blart     TYPE blart,
          lv_bldat     TYPE bldat,
          lv_budat     TYPE budat,
          lv_waers     TYPE waers,
          lv_xblnr     TYPE xblnr1,
          lv_bktxt     TYPE bktxt,
          lv_usnam     TYPE usnam,
          lv_kunnr     TYPE kunnr,
          lv_wrbtr     TYPE wrbtr,
          lv_name1     TYPE name1_gp,
          lv_persnr    TYPE ad_persnum,
          lv_addrnr    TYPE ad_addrnum,
          lv_amt_c     TYPE c LENGTH 24,
          lv_date_c    TYPE c LENGTH 10,
          lv_purpose   TYPE string,
          lv_subject   TYPE string,
          lv_html      TYPE string,
          lv_missing   TYPE string,
          lt_body      TYPE soli_tab,
          lo_send      TYPE REF TO cl_bcs,
          lo_doc       TYPE REF TO cl_document_bcs,
          lo_rcpt      TYPE REF TO if_recipient_bcs,
          lo_bcs_ex    TYPE REF TO cx_bcs.

    CLEAR: ev_sent, ev_msg.

* 1. Document header: parked (VBKPF) first, posted (BKPF) once the
*    parked tables are gone after PRELIMINARY_POSTING_POST_ALL.
    SELECT SINGLE blart, bldat, budat, waers, xblnr, bktxt, usnam
      FROM vbkpf
      WHERE ausbk = @iv_bukrs
        AND belnr = @iv_belnr
        AND gjahr = @iv_gjahr
      INTO ( @lv_blart, @lv_bldat, @lv_budat, @lv_waers, @lv_xblnr, @lv_bktxt, @lv_usnam ).
    IF sy-subrc = 0.
      SELECT kunnr, wrbtr
        FROM vbsegd
        WHERE ausbk = @iv_bukrs
          AND belnr = @iv_belnr
          AND gjahr = @iv_gjahr
        INTO ( @lv_kunnr, @lv_wrbtr )
        UP TO 1 ROWS.
      ENDSELECT.
    ELSE.
      SELECT SINGLE blart, bldat, budat, waers, xblnr, bktxt, usnam
        FROM bkpf
        WHERE bukrs = @iv_bukrs
          AND belnr = @iv_belnr
          AND gjahr = @iv_gjahr
        INTO ( @lv_blart, @lv_bldat, @lv_budat, @lv_waers, @lv_xblnr, @lv_bktxt, @lv_usnam ).
      IF sy-subrc <> 0.
        ev_msg = |Document { iv_bukrs } { iv_belnr } { iv_gjahr } not found (VBKPF / BKPF)|.
        RETURN.
      ENDIF.
      SELECT kunnr, wrbtr
        FROM bseg
        WHERE bukrs = @iv_bukrs
          AND belnr = @iv_belnr
          AND gjahr = @iv_gjahr
          AND koart = 'D'
        INTO ( @lv_kunnr, @lv_wrbtr )
        UP TO 1 ROWS.
      ENDSELECT.
    ENDIF.

    IF lv_kunnr IS NOT INITIAL.
      SELECT SINGLE name1 FROM kna1 WHERE kunnr = @lv_kunnr INTO @lv_name1.
    ENDIF.

    IF iv_initiator IS NOT INITIAL.
      lv_initiator = iv_initiator.
    ELSE.
      lv_initiator = lv_usnam.
    ENDIF.

* 2. Duplicate guard - one row per mail. No COMMIT here.
    ls_log-mandt   = sy-mandt.
    ls_log-bukrs   = iv_bukrs.
    ls_log-belnr   = iv_belnr.
    ls_log-gjahr   = iv_gjahr.
    ls_log-mkind   = iv_kind.
    IF iv_kind = gc_mail_approval.
      ls_log-mlevel = iv_level.
      ls_log-agent  = iv_approver.
    ENDIF.
    ls_log-sent_by = sy-uname.
    ls_log-sent_on = sy-datum.
    ls_log-sent_at = sy-uzeit.

    INSERT zcm_wf_mail_log FROM @ls_log.
    IF sy-subrc <> 0.
      ev_msg = |Mail { iv_kind } level { iv_level } for { iv_belnr } already sent - skipped|.
      RETURN.
    ENDIF.

* 3. Recipients: initiator always, approver for kind A.
    CLEAR ls_rcpt.
    ls_rcpt-uname = lv_initiator.
    APPEND ls_rcpt TO lt_rcpt.
    IF iv_kind = gc_mail_approval AND iv_approver IS NOT INITIAL AND iv_approver <> lv_initiator.
      CLEAR ls_rcpt.
      ls_rcpt-uname = iv_approver.
      APPEND ls_rcpt TO lt_rcpt.
    ENDIF.

    LOOP AT lt_rcpt ASSIGNING FIELD-SYMBOL(<ls_rcpt>).
      CLEAR: lv_persnr, lv_addrnr.
      SELECT SINGLE persnumber, addrnumber
        FROM usr21
        WHERE bname = @<ls_rcpt>-uname
        INTO ( @lv_persnr, @lv_addrnr ).
      IF sy-subrc = 0.
        SELECT SINGLE smtp_addr
          FROM adr6
          WHERE addrnumber = @lv_addrnr
            AND persnumber = @lv_persnr
          INTO @<ls_rcpt>-smtp.
        SELECT SINGLE name_text
          FROM adrp
          WHERE persnumber = @lv_persnr
          INTO @<ls_rcpt>-name.
      ENDIF.
      IF <ls_rcpt>-smtp IS INITIAL.
        IF lv_missing IS INITIAL.
          lv_missing = <ls_rcpt>-uname.
        ELSE.
          lv_missing = |{ lv_missing }, { <ls_rcpt>-uname }|.
        ENDIF.
      ENDIF.
    ENDLOOP.

    DELETE lt_rcpt WHERE smtp IS INITIAL.
    IF lt_rcpt IS INITIAL.
      ev_msg = |No e-mail address in SU01 for { lv_missing }|.
      RETURN.
    ENDIF.

* 4. Subject and body.
    CASE iv_kind.
      WHEN gc_mail_approval.
        lv_purpose = |Level { iv_level } approval needed|.
      WHEN gc_mail_final.
        lv_purpose = |Final approval confirmation|.
      WHEN gc_mail_reject.
        lv_purpose = |Rejected|.
      WHEN OTHERS.
        ev_msg = |Unknown mail kind { iv_kind }|.
        RETURN.
    ENDCASE.
    lv_subject = |Credit Memo { iv_belnr } / { iv_bukrs } / { iv_gjahr } - { lv_purpose }|.

    WRITE lv_wrbtr TO lv_amt_c CURRENCY lv_waers.
    CONDENSE lv_amt_c.
    WRITE lv_bldat TO lv_date_c DD/MM/YYYY.

    lv_html = |<html><body style="font-family:Arial;font-size:10pt">|.
    lv_html = |{ lv_html }<p>Dear User,</p>|.
    CASE iv_kind.
      WHEN gc_mail_approval.
        lv_html = |{ lv_html }<p>The credit memo below is waiting for level { iv_level } approval.|.
        IF iv_approver IS NOT INITIAL.
          lv_html = |{ lv_html } Approver: <b>{ iv_approver }</b>.|.
        ENDIF.
        lv_html = |{ lv_html } Please process it in My Inbox.</p>|.
      WHEN gc_mail_final.
        lv_html = |{ lv_html }<p>The credit memo below has received final approval and is posted.</p>|.
      WHEN gc_mail_reject.
        lv_html = |{ lv_html }<p>The credit memo below has been <b>rejected</b>. |.
        lv_html = |{ lv_html }Please correct and resubmit it, or withdraw it.</p>|.
    ENDCASE.
    lv_html = |{ lv_html }<table border="1" cellpadding="4" cellspacing="0">|.
    lv_html = |{ lv_html }<tr><td>Company code</td><td>{ iv_bukrs }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Document</td><td>{ iv_belnr } / { iv_gjahr }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Document type</td><td>{ lv_blart }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Document date</td><td>{ lv_date_c }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Customer</td><td>{ lv_kunnr ALPHA = OUT } { lv_name1 }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Amount</td><td>{ lv_amt_c } { lv_waers }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Reference</td><td>{ lv_xblnr }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Header text</td><td>{ lv_bktxt }</td></tr>|.
    lv_html = |{ lv_html }<tr><td>Initiator</td><td>{ lv_initiator }</td></tr>|.
    lv_html = |{ lv_html }</table>|.
    lv_html = |{ lv_html }<p>This is an automated mail from the Credit Memo approval workflow.</p>|.
    lv_html = |{ lv_html }</body></html>|.

    lt_body = cl_bcs_convert=>string_to_soli( iv_string = lv_html ).

* 5. Send. Delivered on the caller's COMMIT WORK.
    TRY.
        lo_send = cl_bcs=>create_persistent( ).
        lo_doc  = cl_document_bcs=>create_document( i_type    = 'HTM'
                                                    i_text    = lt_body
                                                    i_subject = CONV so_obj_des( lv_subject ) ).
        lo_send->set_document( lo_doc ).
        lo_send->set_message_subject( ip_subject = lv_subject ).

        LOOP AT lt_rcpt INTO ls_rcpt.
          lo_rcpt = cl_cam_address_bcs=>create_internet_address( i_address_string = ls_rcpt-smtp
                                                                 i_address_name   = ls_rcpt-name ).
          lo_send->add_recipient( i_recipient = lo_rcpt ).
          IF ls_log-rcpts IS INITIAL.
            ls_log-rcpts = ls_rcpt-smtp.
          ELSE.
            ls_log-rcpts = |{ ls_log-rcpts },{ ls_rcpt-smtp }|.
          ENDIF.
        ENDLOOP.

        lo_send->set_send_immediately( abap_true ).
        ev_sent = lo_send->send( i_with_error_screen = abap_false ).
      CATCH cx_bcs INTO lo_bcs_ex.
        ev_sent = abap_false.
        ev_msg  = lo_bcs_ex->get_text( ).
        RETURN.
    ENDTRY.

    IF ev_sent = abap_true.
      UPDATE zcm_wf_mail_log SET rcpts = @ls_log-rcpts
        WHERE bukrs  = @ls_log-bukrs  AND belnr = @ls_log-belnr AND gjahr = @ls_log-gjahr
          AND mkind  = @ls_log-mkind  AND mlevel = @ls_log-mlevel AND agent = @ls_log-agent.
      IF lv_missing IS NOT INITIAL.
        ev_msg = |Sent; no e-mail address in SU01 for { lv_missing }|.
      ENDIF.
    ELSE.
      ev_msg = |BCS send( ) returned false for { iv_belnr }|.
    ENDIF.
*EOC By Arnav on 30/10/26
  ENDMETHOD.

ENDCLASS.
