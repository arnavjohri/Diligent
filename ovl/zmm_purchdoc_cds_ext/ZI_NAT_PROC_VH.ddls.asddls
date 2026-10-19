//----------------------------------------------------------------------
// Object    : ZI_NAT_PROC_VH (DDL source, value help view)
// Table     : ZNAT_PROC (Tender Process)
// Purpose   : Fiori value help for the PO header custom field
//             ZZNAT_PROC (Tender Process) - same rows as the GUI F4
//             (MODULE pop_up: ZNAT_PROC where STATUS = 'active',
//             code + description, ordered by SERIAL_NO).
//             Referenced from ZC_PURCHASEORDERTP_EXT via
//             @Consumption.valueHelpDefinition.
// Author    : Arnav Johri
// Date      : 19.10.2026
//----------------------------------------------------------------------
// ASSUMPTION: field names ZZNAT_PROC, SERIAL_NO, NAT_PROC_DESC, STATUS
// and the literal 'active' are taken from the GUI module pop_up, not
// from SE11. Confirm STATUS is a character field before activating.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZINATPROCVH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tender Process - value help'
@ObjectModel.representativeKey: 'zznat_proc'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view ZI_NAT_PROC_VH
  as select from znat_proc
{
      @ObjectModel.text.element: ['nat_proc_desc']
      @UI.textArrangement: #TEXT_LAST
      @Search.defaultSearchElement: true
  key zznat_proc,

      @Semantics.text: true
      @Search.defaultSearchElement: true
      nat_proc_desc,

      @EndUserText.label: 'Sequence'
      serial_no
}
where
  status = 'active'
