//----------------------------------------------------------------------
// Object    : ZI_DOM_FIXVAL_VH (DDL source, value help view)
// Table     : DD07T (fixed-value texts of domains)
// Purpose   : Value help for the PO custom fields whose GUI F4 is the
//             fixed values of their domain (Inspection Type, Nature of
//             tender, Bidding System, ...): one view over DD07T, read by
//             the DPC enhancement ZEI_MM_PO_VH_DPC, which filters on the
//             domain taken from the entity set name (ZVH_<DOMAIN>). The
//             entity sets are created in the model by ZCL_MM_PO_VH_MPC.
// Author    : Arnav Johri
// Date      : 21.10.2026
// Change    : 22/10/26 Arnav - restricted to domain ZINSP_TYP in the WHERE
//             clause (done by hand in ADT; repo copy aligned).
//             22/10/26 v2 Arnav - restriction lifted again: the DPC now
//             filters per domain, so one view serves every fixed-value
//             field. Paste after ZCL_MM_PO_VH_MPC v8 is active.
//             22/10/26 v3 Arnav - DomainValueHigh (DD07T-DOMVALUE_H) added
//             so that interval fixed values (ZPRE_AWD / ZPST_AWD, 001-100)
//             show their upper bound in the F4, as in the GUI. Paste
//             BEFORE class v13, which reads the new column.
//----------------------------------------------------------------------
// ASSUMPTION: DomainValue stays CHAR 10 (DD07T-DOMVALUE_L) so that one
// view serves CHAR 1/2/3 and NUMC 3 domains alike. ADT may warn that
// its length differs from the bound element; that warning is expected.
// Known: domain ZARBIT has a fixed value with a blank key (No
// Arbitration) - it comes through as a row with DomainValue = ''.
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

      //BOC By Arnav on 22/10/26
      // v3: upper bound of an interval fixed value, blank for single values
      @EndUserText.label: 'Upper Value'
      domvalue_h as DomainValueHigh,
      //EOC By Arnav on 22/10/26

      @EndUserText.label: 'Sequence'
      valpos     as ValuePosition
}
where
      ddlanguage = $session.system_language
  and as4local   = 'A'
  //BOC By Arnav on 22/10/26
  // v2, same day: the single-domain restriction is lifted again - the DPC
  // filters on the domain of each entity set (ZVH_<DOMAIN>).
  // and domname    = 'ZINSP_TYP'
  //EOC By Arnav on 22/10/26
