*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_FI_CM_APPR_ITM_GET   (new)
* Spot                       : implicit, BEGINNING of method
*   CL_FAC_FINANCIALS_POST_DPC_EXT->GLPOSTINGITEMSET_GET_ENTITY
* Author / date              : Arnav Johri, 27/10/26
* Why: a change to a line in the Verify app is sent as a PATCH on entity
*   FinsPostingGLItem. The Gateway PATCH first reads the line through this
*   method, which ends with
*     IF ... iv_entity_name = 'FinsPostingGLItem' AND er_entity-koart <> 'S'
*            AND er_entity-koart <> 'A' ... -> FIN_ODATA_GL 017
*   so the customer line of a DG credit memo cannot be read for a change
*   and the app drops it. For that line only, this block runs the
*   method's own logic (same read, same conversion) without the G/L-only
*   check and leaves the method. Every other line: standard.
* Pair: ZEI_FI_CM_APPR_ITM_UPD (UPDATE_ENTITY) - activate both together.
* Source read: class source CL_FAC_FINANCIALS_POST_DPC_EXT, release 758,
*   supplied by Arnav 27/10/26.
* Create via: SE24, CL_FAC_FINANCIALS_POST_DPC_EXT, method
*   GLPOSTINGITEMSET_GET_ENTITY, Enhance, Show Implicit Enhancement
*   Options, right-click the line after METHOD ..., Create Implementation,
*   Code, name ZEI_FI_CM_APPR_ITM_GET. Paste between ENHANCEMENT and
*   ENDENHANCEMENT. Activate.
* Switch-off: deactivate the implementation (SE19).
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_FI_CM_APPR_ITM_GET.    "active version
*BOC By Arnav on 27/10/26
* ASSUMPTION: credit memo document type 'DG', as in the other objects.
  CONSTANTS lc_zcm_blart TYPE bkpf-blart VALUE 'DG'.

  DATA: lv_zcm_blart TYPE bkpf-blart,
        lv_zcm_tcode TYPE bkpf-tcode,
        lv_zcm_mine  TYPE abap_bool,
        lv_zcm_name  TYPE if_cfd_odata_runtime=>ty_entity_name.

  CLEAR: lv_zcm_blart, lv_zcm_tcode, lv_zcm_mine, lv_zcm_name.

  IF iv_entity_name = 'FinsPostingGLItem'.

    conv_key(
      EXPORTING
        it_key_tab = io_tech_request_context->get_keys( )
      IMPORTING
        ev_tmpty   = DATA(lv_zcm_tmpty)
        ev_tmpid   = DATA(lv_zcm_tmpid)
        ev_posnr   = DATA(lv_zcm_posnr) ).

*   Edit mode only (temporary document), as in the Verify app
    IF lv_zcm_tmpty = cl_fdc_posting_impl=>co_key_types-temporary.

*     Decision read without update flag: is this the customer line of a DG?
      mo_tmp_doc_access->document_read(
        EXPORTING
          is_accdoc_hdr_tmp_key = VALUE #( tmpty = lv_zcm_tmpty
                                           tmpid = lv_zcm_tmpid )
        IMPORTING
          es_accdoc_hdr         = DATA(ls_zcm_hdr)
          et_accdoc_itm         = DATA(lt_zcm_itm)
          ev_error_occurred     = DATA(lv_zcm_err)
          et_message            = DATA(lt_zcm_msg) ).

      IF lv_zcm_err IS INITIAL.
        READ TABLE lt_zcm_itm INTO DATA(ls_zcm_itm) WITH KEY posnr = lv_zcm_posnr.
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

      IF lv_zcm_mine = abap_true.
*       The method's own read, with the update flag a PATCH sets
        mo_tmp_doc_access->document_read(
          EXPORTING
            is_accdoc_hdr_tmp_key = VALUE #( tmpty = lv_zcm_tmpty
                                             tmpid = lv_zcm_tmpid )
            iv_for_update         = xsdbool( io_tech_request_context->get_conditional_operation_for( )
                                      = /iwbep/if_mgw_appl_types=>gcs_operation_type-patch_entity )
          IMPORTING
            es_accdoc_hdr         = ls_zcm_hdr
            et_accdoc_itm         = lt_zcm_itm
            ev_error_occurred     = lv_zcm_err
            et_message            = lt_zcm_msg ).
        IF lv_zcm_err = abap_true.
          cl_fac_message_handler=>get_instance( )->add_msg_to_message_container(
            io_context        = mo_context
            it_message        = lt_zcm_msg
            iv_exception_type = cl_fac_message_handler=>co_exception_type-technical_exception ).
        ENDIF.

        DELETE lt_zcm_itm WHERE posnr <> lv_zcm_posnr.
        mo_financials_post_dpc_imp->conv_doc_to_ext(
          IMPORTING
            et_accdoc_item   = DATA(lt_zcm_ext)
          CHANGING
            cs_accdoc_hdr_wa = ls_zcm_hdr
            ct_accdoc_itm_wa = lt_zcm_itm ).
        lv_zcm_name = iv_entity_name.
        conv_to_ext_extensibility(
          EXPORTING
            iv_entity_name    = lv_zcm_name
          CHANGING
            ct_fdc_accdoc_itm = lt_zcm_ext ).

*       Same output as the method - without its G/L-only check
        READ TABLE lt_zcm_ext INTO er_entity WITH KEY posnr = lv_zcm_posnr.
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
        RETURN.
      ENDIF.
    ENDIF.
  ENDIF.
*EOC By Arnav on 27/10/26
ENDENHANCEMENT.
