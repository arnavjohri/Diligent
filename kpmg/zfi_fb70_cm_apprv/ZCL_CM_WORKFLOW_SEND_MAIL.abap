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
