*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_FI_CM_APPR_ITM_UPD   (new)
* Spot                       : implicit, BEGINNING of method
*   CL_FAC_FINANCIALS_POST_DPC_EXT->GLPOSTINGITEMSET_UPDATE_ENTITY
* Author / date              : Arnav Johri, 27/10/26
* Why: after the read (ZEI_FI_CM_APPR_ITM_GET) the Gateway PATCH writes
*   the merged line through this method. It updates the temporary
*   document (accdoc_mod_entity_imp, item update) and then rejects any
*   line that is not G/L or asset for entity FinsPostingGLItem with
*   FIN_ODATA_GL 017, so the change to the customer line of a DG credit
*   memo is refused. For that line only, this block runs the method's own
*   logic without the G/L-only check and leaves the method. The method's
*   own handling of customer lines is kept (LIFNR cleared, KUNNR kept,
*   down payment request check, FIPEX). Every other line: standard.
* Pair: ZEI_FI_CM_APPR_ITM_GET (GET_ENTITY) - activate both together.
* Source read: class source CL_FAC_FINANCIALS_POST_DPC_EXT, release 758,
*   supplied by Arnav 27/10/26.
* Create via: SE24, CL_FAC_FINANCIALS_POST_DPC_EXT, method
*   GLPOSTINGITEMSET_UPDATE_ENTITY, Enhance, Show Implicit Enhancement
*   Options, right-click the line after METHOD ..., Create Implementation,
*   Code, name ZEI_FI_CM_APPR_ITM_UPD. Paste between ENHANCEMENT and
*   ENDENHANCEMENT. Activate.
* Switch-off: deactivate the implementation (SE19).
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_FI_CM_APPR_ITM_UPD.    "active version
*BOC By Arnav on 27/10/26
* ASSUMPTION: credit memo document type 'DG', as in the other objects.
  CONSTANTS lc_zcm_blart TYPE bkpf-blart VALUE 'DG'.

  DATA: ls_zcm_item  TYPE fac_s_accdoc_itm_odata,
        lt_zcm_out   TYPE fac_t_accdoc_itm_odata,
        lv_zcm_blart TYPE bkpf-blart,
        lv_zcm_tcode TYPE bkpf-tcode,
        lv_zcm_mine  TYPE abap_bool,
        lv_zcm_name  TYPE if_cfd_odata_runtime=>ty_entity_name.

  CLEAR: ls_zcm_item, lt_zcm_out, lv_zcm_blart, lv_zcm_tcode, lv_zcm_mine,
         lv_zcm_name.

  IF iv_entity_name = 'FinsPostingGLItem'.

    io_data_provider->read_entry_data( IMPORTING es_data = ls_zcm_item ).
    IF ls_zcm_item-tmpid IS INITIAL OR ls_zcm_item-posnr IS INITIAL.
      conv_key(
        EXPORTING
          it_key_tab = io_tech_request_context->get_keys( )
        IMPORTING
          ev_tmpty   = ls_zcm_item-tmpty
          ev_tmpid   = ls_zcm_item-tmpid
          ev_posnr   = ls_zcm_item-posnr ).
    ENDIF.

    IF ls_zcm_item-tmpty = cl_fdc_posting_impl=>co_key_types-temporary.
*     Decision from the stored line, not from the request
      mo_tmp_doc_access->document_read(
        EXPORTING
          is_accdoc_hdr_tmp_key = VALUE #( tmpty = ls_zcm_item-tmpty
                                           tmpid = ls_zcm_item-tmpid )
        IMPORTING
          es_accdoc_hdr         = DATA(ls_zcm_hdr)
          et_accdoc_itm         = DATA(lt_zcm_itm)
          ev_error_occurred     = DATA(lv_zcm_err)
          et_message            = DATA(lt_zcm_msg) ).

      IF lv_zcm_err IS INITIAL.
        READ TABLE lt_zcm_itm INTO DATA(ls_zcm_itm) WITH KEY posnr = ls_zcm_item-posnr.
        IF sy-subrc = 0 AND ls_zcm_itm-koart = 'D' AND ls_zcm_hdr-belnr IS NOT INITIAL.
          SELECT SINGLE blart, tcode
            FROM bkpf
            WHERE bukrs = @ls_zcm_hdr-bukrs
              AND belnr = @ls_zcm_hdr-belnr
              AND gjahr = @ls_zcm_hdr-gjahr
            INTO ( @lv_zcm_blart, @lv_zcm_tcode ).
          IF sy-subrc = 0
             AND lv_zcm_blart = lc_zcm_blart
             AND lv_zcm_tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting.
            lv_zcm_mine = abap_true.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_zcm_mine = abap_true.
*     The method's own preparation (see GLPOSTINGITEMSET_UPDATE_ENTITY)
      CLEAR: ls_zcm_item-wrbtr, ls_zcm_item-shkzg.
      ls_zcm_item-koart = 'D'.
      CLEAR ls_zcm_item-lifnr.
      IF ls_zcm_item-umskz = if_fdc_accdoc_types=>gc_umskz_down_payment_request
         AND mv_service_document_name <> co_service_ar_down_payment_req.
        cl_fac_message_handler=>get_instance( )->raise_invalid_request(
          EXPORTING
            io_context     = mo_context
            iv_entity_name = iv_entity_name
            it_key_tab     = it_key_tab ).
      ENDIF.

*     Update of FIPOS from FIPEX, as in the method
      IF NOT ls_zcm_item-fipex IS INITIAL.
        CALL FUNCTION 'FM_FIPOS_GET_FROM_FIPEX'
          EXPORTING
            i_fipex       = ls_zcm_item-fipex
          IMPORTING
            e_fipos       = ls_zcm_item-fipos
          EXCEPTIONS
            error_message = 1.
        IF sy-subrc = 1.
          cl_fac_message_handler=>get_instance( )->add_msg_to_message_container(
            io_context        = mo_context
            iv_msg_type       = 'E'
            iv_msg_id         = sy-msgid
            iv_msg_no         = sy-msgno
            iv_par1           = sy-msgv1
            iv_par2           = sy-msgv2
            iv_par3           = sy-msgv3
            iv_par4           = sy-msgv4
            iv_exception_type = cl_fac_message_handler=>co_exception_type-technical_exception ).
        ENDIF.
      ENDIF.

      accdoc_mod_entity_imp(
        EXPORTING
          is_modification_cntxt = co_modification_context-item-update
          is_glposting_header   = VALUE #( tmpty = ls_zcm_item-tmpty
                                           tmpid = ls_zcm_item-tmpid )
          it_glposting_item     = VALUE #( ( ls_zcm_item ) )
        IMPORTING
          et_glposting_item     = lt_zcm_out ).

*     Same output as the method - without its G/L-only check
      READ TABLE lt_zcm_out INTO er_entity WITH KEY posnr = ls_zcm_item-posnr.
      IF sy-subrc <> 0.
        IF 1 = 2.
          MESSAGE e017(fin_odata_gl).
        ENDIF.
        cl_fac_message_handler=>get_instance( )->add_msg_to_message_container(
          io_context        = mo_context
          iv_msg_type       = 'E'
          iv_msg_id         = 'FIN_ODATA_GL'
          iv_msg_no         = '017'
          iv_exception_type = cl_fac_message_handler=>co_exception_type-technical_exception ).
      ENDIF.

      lv_zcm_name = iv_entity_name.
      conv_to_ext_extensibility(
        EXPORTING
          iv_entity_name    = lv_zcm_name
        CHANGING
          ct_fdc_accdoc_itm = lt_zcm_out ).
      RETURN.
    ENDIF.
  ENDIF.
*EOC By Arnav on 27/10/26
ENDENHANCEMENT.
