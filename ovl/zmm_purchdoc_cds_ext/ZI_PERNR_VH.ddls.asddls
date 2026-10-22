//----------------------------------------------------------------------
// Object    : ZI_PERNR_VH (DDL source, value help view)
// Table     : PA0002 (personal data)
// Purpose   : Fiori value help for the PO custom fields ZZCPO (Contact
//             Person) and ZZINDPER (Indenting Person): data element
//             PERSNO, value table PA0003. Entity set ZVT_PERNR, created
//             in the model by ZCL_MM_PO_VH_MPC, served by ZCL_MM_PO_VH_DPC.
// Author    : Arnav Johri
// Date      : 22.10.2026
//----------------------------------------------------------------------
// ASSUMPTION / RISK: #NOT_REQUIRED makes the name of every employee with
// a current PA0002 record visible to every user of the PO app. The GUI
// search help PREM checks HR authorisations. Confirm with the HR /
// functional lead before this view goes into the system; if an
// authorisation check is wanted, a DCL on PA0002 is the next object.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIPERNRVH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Personnel numbers - value help'
@ObjectModel.representativeKey: 'PersonnelNumber'
@Search.searchable: true
define view ZI_PERNR_VH
  as select from pa0002
{
      @EndUserText.label: 'Personnel Number'
      @ObjectModel.text.element: ['EmployeeName']
      @Search.defaultSearchElement: true
  key pernr                            as PersonnelNumber,

      @EndUserText.label: 'Last Name'
      @Search.defaultSearchElement: true
      nachn                            as LastName,

      @EndUserText.label: 'First Name'
      @Search.defaultSearchElement: true
      vorna                            as FirstName,

      @EndUserText.label: 'Name'
      @Semantics.text: true
      concat_with_space(vorna, nachn, 1) as EmployeeName
}
where
      begda <= $session.system_date
  and endda >= $session.system_date
