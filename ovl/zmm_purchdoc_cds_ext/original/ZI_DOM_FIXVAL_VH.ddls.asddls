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
  and domname = 'ZINSP_TYP'
