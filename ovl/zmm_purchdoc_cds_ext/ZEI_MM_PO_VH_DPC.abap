*----------------------------------------------------------------------*
* Enhancement : ZEI_MM_PO_VH_DPC (enhancement implementation, source code)
* Where       : class CL_MM_PUR_PO_MAINT_V2_DPC_EXT, method
*               /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET, implicit
*               enhancement option at the START of the method (before
*               INCLUDE mm_pur_odata_check_entity). Active since 22/10/26.
* Author      : Arnav Johri (Diligent)      Created: 22.10.2026
* Ships by    : paste. Object 3 of 3; needs ZCL_MM_PO_VH_MPC and
*               ZEI_MM_PO_VH_MPC active.
* Change      : 22/10/26 v2 - one entity set per fixed-value domain.
*               22/10/26 v3 - the data logic moves to ZCL_MM_PO_VH_DPC
*               (table-based sets ZVT_* added, $filter pushed to the DB);
*               this block only dispatches. Needs ZCL_MM_PO_VH_DPC active.
*----------------------------------------------------------------------*
* Why the START: the model carries the sets (object 1 + 2), so the
* framework routes GET requests on them here. SAP's dispatch below does
* not know the names; this block answers them first and leaves the
* method. Every other entity set falls through unchanged.
* ASSUMPTION A3: the request context offers GET_OSQL_WHERE_CLAUSE_CONVERT
* as a functional method returning a string. If activation rejects it,
* replace the argument by an empty string literal ('') - the dialog's
* filters then no longer reach the database, nothing else changes.
* Replace the whole content between ENHANCEMENT and ENDENHANCEMENT:
*----------------------------------------------------------------------*
*BOC By SAP_ABAP on 22/10/26
  " Value-help sets added to the model by ZCL_MM_PO_VH_MPC (ZVH_<DOMAIN>
  " for domain fixed values, ZVT_<NAME> for table-based helps). Served
  " by ZCL_MM_PO_VH_DPC before SAP's dispatch, which does not know them.
  IF iv_entity_set_name CP 'ZVH_*' OR iv_entity_set_name CP 'ZVT_*'.
    DATA lv_zvh_count  TYPE i.
    DATA lv_zvh_served TYPE abap_bool.

    zcl_mm_po_vh_dpc=>get_entityset(
      EXPORTING iv_entity_set_name = iv_entity_set_name
                iv_osql_where      = io_tech_request_context->get_osql_where_clause_convert( ) "A3
                it_order           = it_order
                is_paging          = is_paging
      IMPORTING er_entityset       = er_entityset
                ev_count           = lv_zvh_count
                ev_served          = lv_zvh_served ).

    IF lv_zvh_served = abap_true.
      IF io_tech_request_context->has_inlinecount( ) = abap_true.
        es_response_context-inlinecount = lv_zvh_count.
      ENDIF.
      RETURN.
    ENDIF.
  ENDIF.
*EOC By SAP_ABAP on 22/10/26
