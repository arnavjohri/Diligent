*---------------------------------------------------------------------*
* Class for Sending Mail
*---------------------------------------------------------------------*
CLASS lcl_ast_mail DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      me2n_mail.
ENDCLASS.

CLASS lcl_ast_mail IMPLEMENTATION.
  METHOD me2n_mail.

    DATA: lv_subject     TYPE so_obj_des,
          lv_text1       TYPE string,
          lv_text2       TYPE string,
          lv_text3       TYPE string,
          lv_text4       TYPE string,
          lv_text5       TYPE string,
          lv_text6       TYPE string,
          lv_text7       TYPE string,
          lt_body        TYPE bcsy_text,
          lv_min_date    TYPE zsap_timesheet-datec,
          lv_max_date    TYPE zsap_timesheet-datec,
          lv_duration    TYPE string,
          lv_status_text TYPE string.

    TRY.

        DATA(lo_send_request) = cl_bcs=>create_persistent( ).

*--------------------------------------------------------------------*
* Get Min / Max Date
*--------------------------------------------------------------------*
        SELECT MIN( datec ),
               MAX( datec )
          INTO (@lv_min_date, @lv_max_date)
          FROM zsap_timesheet
          WHERE doc_no = @doc_no.

*--------------------------------------------------------------------*
* Get Consultant Details
*--------------------------------------------------------------------*
        SELECT SINGLE *
          INTO @DATA(min_data)
          FROM zsap_timesheet
          WHERE doc_no = @doc_no.

*--------------------------------------------------------------------*
* Format Duration
*--------------------------------------------------------------------*
        lv_duration = |{ lv_min_date DATE = USER } to { lv_max_date DATE = USER }|.

*--------------------------------------------------------------------*
* Check Approve / Reject
*--------------------------------------------------------------------*
        IF approve = 'X' OR creator_release = 'X'  .

          lv_status_text = 'has been submitted for necessary action'.

        ELSE.

          lv_status_text = 'has been rejected'.

        ENDIF.

*--------------------------------------------------------------------*
* Subject
*--------------------------------------------------------------------*
        SHIFT doc_no LEFT DELETING LEADING '0'.
        CONCATENATE min_data-consultant_name
                    '-Timesheet Submission-Doc no-'
                    doc_no
               INTO lv_subject
          SEPARATED BY space.

*--------------------------------------------------------------------*
* Mail Body
*--------------------------------------------------------------------*
        lv_text1 = |Timesheet with the following details { lv_status_text }.|.
        lv_text2 = |Name of Consultant - { min_data-consultant_name }|.
        lv_text3 = |Service Element - { min_data-service_element }|.
        lv_text4 = |Module - { min_data-zmodulec }|.
        lv_text5 = |Duration - { lv_duration }|.
        lv_text6 = |Document Number - { doc_no }|.
        lv_text7 = |{ sy-uname }|.

        lt_body = VALUE bcsy_text(
                    ( line = 'Dear Sir/Madam,' )
                    ( line = '' )
                    ( line = lv_text1 )
                    ( line = '' )
                    ( line = lv_text2 )
                    ( line = lv_text3 )
                    ( line = lv_text4 )
                    ( line = lv_text5 )
                    ( line = lv_text6 )
                    ( line = '' )
                    ( line = 'Regards,' )
                    ( line = lv_text7 )
                  ).

*--------------------------------------------------------------------*
* Create Document
*--------------------------------------------------------------------*
        DATA(lo_document) = cl_document_bcs=>create_document(
                              i_type    = 'RAW'
                              i_text    = lt_body
                              i_subject = lv_subject ).

        lo_send_request->set_document( lo_document ).

*--------------------------------------------------------------------*
* Recipient
*--------------------------------------------------------------------*
        IF approve = 'X' OR creator_release = 'X'  .
          lo_send_request->add_recipient(
            i_recipient = cl_cam_address_bcs=>create_internet_address(
                            i_address_string = lv_email_receiver )
            i_express = abap_true ).

"boc by mohd mobassir - 24.07.2026

lo_send_request->add_recipient(
    i_recipient = cl_cam_address_bcs=>create_internet_address(
                    i_address_string = 'ovl_infocom@ongcvidesh.in' )
    i_copy      = abap_true
    i_express   = abap_true ).

"boc by mohd mobassir - 24.07.2026

        ELSE.

          LOOP AT lt_recipients INTO ls_recipient.
            lo_send_request->add_recipient(
              i_recipient = cl_cam_address_bcs=>create_internet_address(
                              i_address_string = ls_recipient-email )
              i_express = abap_true ).
          ENDLOOP.


        ENDIF.

*--------------------------------------------------------------------*
* Sender
*--------------------------------------------------------------------*
        lo_send_request->set_sender(
          cl_cam_address_bcs=>create_internet_address(
            i_address_string = lv_email_sender ) ).

*--------------------------------------------------------------------*
* Send Mail
*--------------------------------------------------------------------*
        DATA(lv_sent) = lo_send_request->send( ).
        COMMIT WORK.

        IF lv_sent = abap_true.
          MESSAGE 'Mail Sent Successfully' TYPE 'S'.
        ELSE.
          MESSAGE 'Mail Not Sent' TYPE 'E'.
        ENDIF.

      CATCH cx_bcs INTO DATA(lx_bcs).
        MESSAGE lx_bcs->get_text( ) TYPE 'E'.
    ENDTRY.

    CLEAR : lv_email_receiver , lv_email_sender.

  ENDMETHOD.

ENDCLASS.
