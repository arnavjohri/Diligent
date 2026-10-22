//----------------------------------------------------------------------
// Object    : ZI_GEM_ORDER_VH (DDL source, value help view)
// Table     : ZGEM_ORDERDET (GEM orders), the selection method of the
//             GUI search help ZGEM_ORDER on ZSTR_HEADER-ZGEMPO
// Purpose   : Fiori value help for the PO custom field ZGEMPO (GEM PO
//             No.). Same two columns as the search help: ORDER_ID and
//             LIFNR. Entity set ZVT_GEM_ORDER, created in the model by
//             ZCL_MM_PO_VH_MPC, served by ZCL_MM_PO_VH_DPC; the PO's
//             supplier is passed in as the search help's LIFNR import
//             parameter is in the GUI.
// Author    : Arnav Johri
// Date      : 22.10.2026
//----------------------------------------------------------------------
// ASSUMPTION: ZGEM_ORDERDET has the columns ORDER_ID and LIFNR (the two
// search help parameters, SE11 22/10/26) and (MANDT,) ORDER_ID, LIFNR
// identify a row. If the table has further key fields, duplicates would
// appear in the dialog; add them as key elements then.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIGEMORDERVH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GEM orders - value help'
@ObjectModel.representativeKey: 'GemOrderId'
@Search.searchable: true
define view ZI_GEM_ORDER_VH
  as select from zgem_orderdet
{
      @EndUserText.label: 'GEM Order'
      @Search.defaultSearchElement: true
  key order_id as GemOrderId,

      @EndUserText.label: 'Supplier'
      @Search.defaultSearchElement: true
  key lifnr    as Supplier
}
