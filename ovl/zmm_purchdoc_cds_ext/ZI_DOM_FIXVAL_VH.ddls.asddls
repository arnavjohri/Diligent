//----------------------------------------------------------------------
// Object    : ZI_DOM_FIXVAL_VH (DDL source, value help view)
// Table     : DD07T (fixed-value texts of domains)
// Purpose   : Value help for PO custom field ZZINSP_TYP (Inspection Type):
//             the fixed values of its domain, same list as the GUI F4.
//             Referenced from ZC_PURCHASEORDERTP_EXT via
//               @Consumption.valueHelpDefinition: [{
//                 entity: { name: 'ZI_DOM_FIXVAL_VH', element: 'DomainValue' } }]
// Author    : Arnav Johri
// Date      : 21.10.2026
// Change    : 22/10/26 Arnav - restricted to domain ZINSP_TYP in the WHERE
//             clause (done by hand in ADT; repo copy aligned). The generic
//             form, one view for all domains with additionalBinding /
//             localConstant on DomainName, is dropped. Each further
//             fixed-value field now gets its own copy of this view with
//             its own domain name.
//----------------------------------------------------------------------
// ASSUMPTION: DomainValue stays CHAR 10 (DD07T-DOMVALUE_L) so that one
// view serves CHAR 2, CHAR 3 and NUMC 3 domains alike. ADT may warn that
// its length differs from the bound element; that warning is expected.
// For NUMC domains confirm in SE11 that the fixed values were entered
// with leading zeros, otherwise the copied value will not match.
// ASSUMPTION: the domain of data element ZINSP_TYP is ZINSP_TYP, spelled
// as in DD07T (upper case). Taken from SE11 by Arnav, not re-verified here.
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
  //BOC By Arnav on 22/10/26
  and domname    = 'ZINSP_TYP'
  //EOC By Arnav on 22/10/26
