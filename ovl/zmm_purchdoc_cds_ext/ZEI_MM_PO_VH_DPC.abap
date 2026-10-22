*----------------------------------------------------------------------*
* Enhancement : ZEI_MM_PO_VH_DPC (enhancement implementation, source code)
* Where       : class CL_MM_PUR_PO_MAINT_V2_DPC_EXT, method
*               /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET, implicit
*               enhancement option at the START of the method (before
*               INCLUDE mm_pur_odata_check_entity). Active since 22/10/26.
* Author      : Arnav Johri (Diligent)      Created: 22.10.2026
* Ships by    : paste. Object 3 of 3; needs ZCL_MM_PO_VH_MPC and
*               ZEI_MM_PO_VH_MPC active.
* Change      : 22/10/26 v2 - one entity set per fixed-value domain,
*               ZVH_<DOMAIN>, all on the DD07T view; the domain is read
*               from the set name and applied in the WHERE, so the
*               dropdown never depends on the front end filtering. The
*               first set, ZI_DOM_FIXVAL_VH, is still served (ZINSP_TYP)
*               until class v8 renames it. Paste v2 BEFORE class v8.
*----------------------------------------------------------------------*
* Why the START: the model carries the sets (object 1 + 2), so the
* framework routes GET requests on them here. SAP's dispatch below does
* not know the names; this block answers them first and leaves the
* method. Every other entity set falls through unchanged.
* Replace the whole content between ENHANCEMENT and ENDENHANCEMENT:
*----------------------------------------------------------------------*
*BOC By SAP_ABAP on 22/10/26
  " Value-help sets added to the model by ZCL_MM_PO_VH_MPC. Served here,
  " before SAP's dispatch, which does not know them. Fixed-value sets
  " are ZVH_<DOMAIN> on the shared DD07T view ZI_DOM_FIXVAL_VH.
  IF iv_entity_set_name = 'ZI_DOM_FIXVAL_VH' OR iv_entity_set_name CP 'ZVH_*'.
    DATA lt_zvh_rows   TYPE STANDARD TABLE OF zidomfixvalvh WITH DEFAULT KEY.
    DATA lv_zvh_domain TYPE domname.

    IF iv_entity_set_name = 'ZI_DOM_FIXVAL_VH'.
      lv_zvh_domain = 'ZINSP_TYP'.                 "first set, until class v8
    ELSE.
      lv_zvh_domain = iv_entity_set_name+4.        "ZVH_ZT_NATURE -> ZT_NATURE
    ENDIF.

    SELECT * FROM zi_dom_fixval_vh
      WHERE domainname = @lv_zvh_domain
      ORDER BY valueposition
      INTO TABLE @lt_zvh_rows.

    " $filter, $orderby, $inlinecount, $top / $skip - the framework utilities
    /iwbep/cl_mgw_data_util=>filtering( EXPORTING it_select_options = it_filter_select_options
                                        CHANGING  ct_data           = lt_zvh_rows ).
    /iwbep/cl_mgw_data_util=>orderby( EXPORTING it_order = it_order
                                      CHANGING  ct_data  = lt_zvh_rows ).
    IF io_tech_request_context->has_inlinecount( ) = abap_true.
      es_response_context-inlinecount = lines( lt_zvh_rows ).
    ENDIF.
    /iwbep/cl_mgw_data_util=>paging( EXPORTING is_paging = is_paging
                                     CHANGING  ct_data   = lt_zvh_rows ).

    copy_data_to_ref( EXPORTING is_data = lt_zvh_rows
                      CHANGING  cr_data = er_entityset ).
    RETURN.
  ENDIF.
*EOC By SAP_ABAP on 22/10/26
