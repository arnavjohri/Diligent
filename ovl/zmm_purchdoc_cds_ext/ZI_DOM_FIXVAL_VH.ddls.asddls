//----------------------------------------------------------------------
// Object    : ZI_DOM_FIXVAL_VH (DDL source, value help view)
// Table     : DD07T (fixed-value texts of domains)
// Purpose   : ONE value help for every PO custom field whose GUI F4 is
//             the fixed-value list of its domain (Inspection Type, ...).
//             The element in ZC_PURCHASEORDERTP_EXT restricts it to its
//             own domain, so no view per field is needed:
//               @Consumption.valueHelpDefinition: [{
//                 entity: { name: 'ZI_DOM_FIXVAL_VH', element: 'DomainValue' },
//                 additionalBinding: [{ element: 'DomainName',
//                                       localConstant: 'ZINSP_TYP',
//                                       usage: #FILTER }] }]
//             Needed only where the OData runtime does not already emit
//             sap:value-list="fixed-values" for the property.
// Author    : Arnav Johri
// Date      : 21.10.2026
//----------------------------------------------------------------------
// ASSUMPTION: DomainValue stays CHAR 10 (DD07T-DOMVALUE_L) so that one
// view serves CHAR 2, CHAR 3 and NUMC 3 domains alike. ADT may warn that
// its length differs from the bound element; that warning is expected.
// For NUMC domains confirm in SE11 that the fixed values were entered
// with leading zeros, otherwise the copied value will not match.
// ASSUMPTION: the domain name in localConstant is spelled exactly as in
// DD07T (upper case). Take it from SE11, not from the data element name.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIDOMFIXVALVH'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Domain fixed values - value help'
@ObjectModel.representativeKey: 'DomainValue'
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view ZI_DOM_FIXVAL_VH
  as select from dd07t
{
      @EndUserText.label: 'Domain'
      @UI.hidden: true
  key domname    as DomainName,

      @EndUserText.label: 'Value'
      @ObjectModel.text.element: ['DomainValueText']
      @UI.textArrangement: #TEXT_LAST
      @Search.defaultSearchElement: true
  key domvalue_l as DomainValue,

      @EndUserText.label: 'Description'
      @Semantics.text: true
      @Search.defaultSearchElement: true
      ddtext     as DomainValueText,

      @EndUserText.label: 'Sequence'
      valpos     as ValuePosition
}
where
      ddlanguage = $session.system_language
  and as4local   = 'A'
