//----------------------------------------------------------------------
// Object    : ZI_ADRC_VH (DDL source, value help view)
// Table     : ADRC (addresses, international version)
// Purpose   : Fiori value help for the four PO custom fields that hold an
//             address number (ZZTPI_ADD, ZZQAD_DET, ZZPORT_CON,
//             ZZULT_CON - data element AD_ADDRNUM, value table ADRC, GUI
//             search help ADMC). Entity set ZVT_ADRC, created in the
//             model by ZCL_MM_PO_VH_MPC, served by ZCL_MM_PO_VH_DPC.
// Author    : Arnav Johri
// Date      : 22.10.2026
//----------------------------------------------------------------------
// Note: ADRC is large. The DPC pushes the dialog's filters into the
// WHERE clause; the user is expected to filter on name or city first.
// Decided 23/10/26 (Arnav): all four fields have the GUI F4 and get it
// in Fiori too. Paste this view first, then the two classes.
// ASSUMPTION: GUI search help ADMC lists ADRC addresses without a
// further restriction (e.g. an address group). If the GUI list is
// narrower, add that condition to the WHERE below.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIADRCVH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Addresses - value help'
@ObjectModel.representativeKey: 'AddressNumber'
@Search.searchable: true
define view ZI_ADRC_VH
  as select from adrc
{
      @EndUserText.label: 'Address Number'
      @ObjectModel.text.element: ['Name']
      @Search.defaultSearchElement: true
  key addrnumber as AddressNumber,

      @EndUserText.label: 'Name'
      @Semantics.text: true
      @Search.defaultSearchElement: true
      name1      as Name,

      @EndUserText.label: 'City'
      @Search.defaultSearchElement: true
      city1      as City,

      @EndUserText.label: 'Street'
      street     as Street,

      @EndUserText.label: 'Postal Code'
      post_code1 as PostalCode
}
where
      nation    = ''
  and date_from <= $session.system_date
  and date_to   >= $session.system_date
