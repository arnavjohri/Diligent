//----------------------------------------------------------------------
// Object    : ZI_REL_CODE_VH (DDL source, value help view)
// Tables    : T16FC (release codes) + T16FD (their texts)
// Purpose   : Fiori value help for the PO custom field ZZRELCODE (Final
//             Release Code, data element ZFRGCO, domain FRGCO, value
//             table T16FC). Entity set ZVT_RELCODE, created in the model
//             by ZCL_MM_PO_VH_MPC and served by ZCL_MM_PO_VH_DPC.
// Author    : Arnav Johri
// Date      : 22.10.2026
//----------------------------------------------------------------------
// Note: release codes are valid per release group. The dialog shows the
// group as a column so the user can pick the right one; the field itself
// carries only the code, as in the GUI.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIRELCODEVH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Release codes - value help'
@ObjectModel.representativeKey: 'ReleaseCode'
@Search.searchable: true
define view ZI_REL_CODE_VH
  as select from t16fc
    left outer join t16fd on  t16fd.frggr = t16fc.frggr
                          and t16fd.frgco = t16fc.frgco
                          and t16fd.spras = $session.system_language
{
      @EndUserText.label: 'Release Group'
  key t16fc.frggr as ReleaseGroup,

      @EndUserText.label: 'Release Code'
      @ObjectModel.text.element: ['ReleaseCodeText']
      @Search.defaultSearchElement: true
  key t16fc.frgco as ReleaseCode,

      @EndUserText.label: 'Description'
      @Semantics.text: true
      @Search.defaultSearchElement: true
      t16fd.frgct as ReleaseCodeText
}
