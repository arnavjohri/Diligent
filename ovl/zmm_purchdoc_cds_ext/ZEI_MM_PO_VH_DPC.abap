*----------------------------------------------------------------------*
* Enhancement : ZEI_MM_PO_VH_DPC (enhancement implementation, source code)
* Where       : class CL_MM_PUR_PO_MAINT_V2_DPC_EXT, method
*               /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET, implicit
*               enhancement option at the START of the method (before
*               SAP's first statement). If the _EXT does not redefine
*               that method, the START of the same method in
*               CL_MM_PUR_PO_MAINT_V2_DPC. Never both.
* Author      : Arnav Johri (Diligent)      Created: 22.10.2026
* Ships by    : paste. Object 3 of 3; needs ZCL_MM_PO_VH_MPC and
*               ZEI_MM_PO_VH_MPC active.
*----------------------------------------------------------------------*
* Why the START: the model now carries entity set ZI_DOM_FIXVAL_VH
* (object 1 + 2), so the framework routes GET requests on it here. SAP's
* dispatch below does not know the name; this block answers it first and
* leaves the method. Every other entity set falls through unchanged.
* Path: method -> Enhance (spiral) -> Edit -> Enhancement Operations ->
* Show Implicit Enhancement Options -> the option right after METHOD ...
* -> Create Implementation -> Code -> ZEI_MM_PO_VH_DPC, short text
* "PO custom field value helps - data". Paste between ENHANCEMENT and
* ENDENHANCEMENT:
*----------------------------------------------------------------------*
*BOC By SAP_ABAP on 22/10/26
  " Value-help set added to the model by ZCL_MM_PO_VH_MPC. Served here,
  " before SAP's dispatch, which does not know the set.
  IF iv_entity_set_name = 'ZI_DOM_FIXVAL_VH'.
    DATA lt_zvh_rows TYPE STANDARD TABLE OF zidomfixvalvh WITH DEFAULT KEY.

    SELECT * FROM zi_dom_fixval_vh
      ORDER BY domainname, valueposition
      INTO TABLE @lt_zvh_rows.

    " $filter (the Constant parameter sends DomainName eq '<domain>'),
    " $orderby, $inlinecount, $top / $skip - the framework utilities
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
