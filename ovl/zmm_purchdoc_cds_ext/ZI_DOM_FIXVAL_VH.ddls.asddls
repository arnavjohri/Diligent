//----------------------------------------------------------------------
// Object    : ZI_DOM_FIXVAL_VH (DDL source, value help view)
// Tables    : DD07L (fixed values of domains) + DD07T (their texts)
// Purpose   : Value help for the PO custom fields whose GUI F4 is the
//             fixed values of their domain (Inspection Type, Nature of
//             tender, Bidding System, ...): one view, read by the DPC
//             enhancement ZEI_MM_PO_VH_DPC, which filters on the domain
//             taken from the entity set name (ZVH_<DOMAIN>). The entity
//             sets are created in the model by ZCL_MM_PO_VH_MPC.
// Author    : Arnav Johri
// Date      : 21.10.2026
// Change    : 22/10/26 Arnav - restricted to domain ZINSP_TYP (by hand).
//             22/10/26 v2 Arnav - restriction lifted again: the DPC
//             filters per domain.
//             22/10/26 v3 Arnav - DomainValueHigh added for the interval
//             fixed values (ZPRE_AWD / ZPST_AWD, 001-100), taken from
//             DD07T-DOMVAL_LD / DOMVAL_HD.
//             22/10/26 v4 Arnav - DD07T's DOMVAL_LD / DOMVAL_HD are display
//             fields and are EMPTY on OCQ: the interval row came up blank
//             in the app. The values now come from DD07L (DOMVALUE_L /
//             DOMVALUE_H, which is what the GUI F4 shows), the text from
//             DD07T by a left outer join. Column names unchanged, so
//             ZCL_MM_PO_VH_MPC v13 and ZCL_MM_PO_VH_DPC need no change.
//----------------------------------------------------------------------
// ASSUMPTION: DomainValue stays CHAR 10 (DD07L-DOMVALUE_L) so that one
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
  as select from dd07l
    left outer join dd07t on  dd07t.domname    = dd07l.domname
                          and dd07t.as4local   = dd07l.as4local
                          and dd07t.valpos     = dd07l.valpos
                          and dd07t.as4vers    = dd07l.as4vers
                          and dd07t.ddlanguage = $session.system_language
{
      @EndUserText.label: 'Domain'
      @UI.hidden: true
  key dd07l.domname    as DomainName,

      @EndUserText.label: 'Value'
      @ObjectModel.text.element: ['DomainValueText']
      @UI.textArrangement: #TEXT_LAST
      @Search.defaultSearchElement: true
  key dd07l.domvalue_l as DomainValue,

      @EndUserText.label: 'Description'
      @Semantics.text: true
      @Search.defaultSearchElement: true
      dd07t.ddtext     as DomainValueText,

      @EndUserText.label: 'Upper Value'
      dd07l.domvalue_h as DomainValueHigh,

      @EndUserText.label: 'Sequence'
      dd07l.valpos     as ValuePosition
}
where
  dd07l.as4local = 'A'
