*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_FI_CM_APPR_ITM_LIST   (new)
* Spot                       : implicit, END of method
*   CL_FAC_FINANCIALS_POST_DPC_EXT->GLPOSTINGITEMSET_GET_ENTITYSET
* Author / date              : Arnav Johri, 27/10/26
* Why: the Verify app shows a parked document through the expanded header
*   read (GET_EXPANDED_ENTITY, all items). After any change it re-reads
*   the item list through entity set FinsPostingGLItems, and this method
*   removes every line that is not G/L or asset for entity
*   FinsPostingGLItem:
*     DELETE lt_accdoc_itm_wa WHERE ( koart <> 'S' AND koart <> 'A' )
*                                  OR ux_mainind = 'X'.
*   So the customer (credit) line of a DG credit memo disappears from the
*   screen as soon as any line is changed. The line itself is still in
*   the temporary document (debugger 27/10/26: 2 rows before
*   document_write).
*   This block adds the customer lines back to the list, converted the
*   same way as the method converts the G/L lines, for DG documents of
*   the GL verification scenario only.
* Source read: class source CL_FAC_FINANCIALS_POST_DPC_EXT, release 758,
*   supplied by Arnav 27/10/26.
* Companion objects (next): GLPOSTINGITEMSET_GET_ENTITY and
*   GLPOSTINGITEMSET_UPDATE_ENTITY reject a customer line for entity
*   FinsPostingGLItem (FIN_ODATA_GL 017), so editing the credit line
*   itself needs two more enhancements.
* Create via: SE24, CL_FAC_FINANCIALS_POST_DPC_EXT, method
*   GLPOSTINGITEMSET_GET_ENTITYSET, Display, Enhance (spiral), Edit ->
*   Enhancement Operations -> Show Implicit Enhancement Options,
*   right-click the line before ENDMETHOD, Enhancement Implementation ->
*   Create Implementation, Code, name ZEI_FI_CM_APPR_ITM_LIST, Z package
*   and request. Paste the block between ENHANCEMENT and ENDENHANCEMENT.
* Switch-off: deactivate the implementation (SE19).
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_FI_CM_APPR_ITM_LIST.    "active version
*BOC By Arnav on 27/10/26
* ASSUMPTION: credit memo document type 'DG' (same constant as the other
*             credit memo enhancements).
* Types are taken from the method's own variables (LIKE), except the item
* list: ET_ENTITYSET is generic here (activation 27/10/26), so the item
* type the class itself uses for G/L items is named
* (FAC_S_ACCDOC_ITM_ODATA / FAC_T_ACCDOC_ITM_ODATA, as in
* GLPOSTINGITEMSET_UPDATE_ENTITY).
  CONSTANTS lc_zcm_blart TYPE bkpf-blart VALUE 'DG'.

  DATA: lv_zcm_blart TYPE bkpf-blart,
        lv_zcm_tcode TYPE bkpf-tcode,
        ls_zcm_hdr   LIKE ls_accdoc_hdr_wa,
        lt_zcm_itm   LIKE lt_accdoc_itm_wa,
        lt_zcm_ext   TYPE fac_t_accdoc_itm_odata,
        lt_zcm_all   TYPE STANDARD TABLE OF fac_s_accdoc_itm_odata WITH DEFAULT KEY,
        lv_zcm_err   LIKE lv_error_occurred,
        lt_zcm_msg   LIKE lt_message.

  CLEAR: lv_zcm_blart, lv_zcm_tcode, ls_zcm_hdr, lt_zcm_itm, lt_zcm_ext,
         lt_zcm_all, lv_zcm_err, lt_zcm_msg.

  IF iv_entity_name = 'FinsPostingGLItem'
     AND lv_tmpty <> cl_fdc_tmp_doc_access=>co_key_types-recurrence
     AND ls_accdoc_hdr_wa-belnr IS NOT INITIAL.

    SELECT SINGLE blart, tcode
      FROM bkpf
      WHERE bukrs = @ls_accdoc_hdr_wa-bukrs
        AND belnr = @ls_accdoc_hdr_wa-belnr
        AND gjahr = @ls_accdoc_hdr_wa-gjahr
      INTO ( @lv_zcm_blart, @lv_zcm_tcode ).

    IF sy-subrc = 0
       AND lv_zcm_blart = lc_zcm_blart
       AND lv_zcm_tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting.

*     Same read as the method itself; keep only the customer lines it removed
      mo_tmp_doc_access->document_read(
        EXPORTING
          is_accdoc_hdr_tmp_key = VALUE #( tmpty = lv_tmpty
                                           tmpid = lv_tmpid )
        IMPORTING
          es_accdoc_hdr         = ls_zcm_hdr
          et_accdoc_itm         = lt_zcm_itm
          ev_error_occurred     = lv_zcm_err
          et_message            = lt_zcm_msg ).

      IF lv_zcm_err IS INITIAL.
        DELETE lt_zcm_itm WHERE koart <> 'D' OR ux_mainind = 'X'.
        IF lt_zcm_itm IS NOT INITIAL.
          mo_financials_post_dpc_imp->conv_doc_to_ext(
            IMPORTING
              et_accdoc_item   = lt_zcm_ext
            CHANGING
              cs_accdoc_hdr_wa = ls_zcm_hdr
              ct_accdoc_itm_wa = lt_zcm_itm ).
          conv_to_ext_extensibility(
            EXPORTING
              iv_entity_name    = lv_entity_name
              iv_for_display    = lv_for_display
            CHANGING
              ct_fdc_accdoc_itm = lt_zcm_ext ).
*         ET_ENTITYSET is generic in this method: merge in a typed copy
          lt_zcm_all = et_entityset.
          APPEND LINES OF lt_zcm_ext TO lt_zcm_all.
          SORT lt_zcm_all BY posnr.
          et_entityset = lt_zcm_all.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
*EOC By Arnav on 27/10/26
ENDENHANCEMENT.
