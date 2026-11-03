//----------------------------------------------------------------------
// Object    : ZI_JIB_VENTURE (DDL source, classic view)
// Title     : Joint ventures with description
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 3 of 4 for the Management Dashboard card "JIB Status".
//   One row per company code / joint venture from the venture master
//   T8JV, with the description from T8JVT and the venture type. The
//   text join is on company code and venture only - the same join the
//   active cash-call program and ZFI_JV_TB use - and the text is taken
//   with max() under a GROUP BY, so if T8JVT turns out to carry a
//   language key with more than one language maintained, a venture
//   still comes out exactly once and the cube's counts stay right.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: every venture in T8JV is in scope. Ventures that never
//   receive a JIB (operated ones, closed ones) show as Pending in every
//   period; filter them in the query on Venture Type or on the venture
//   list until a scope table or the venture-type meaning is confirmed.
// ASSUMPTION: VentureType is T8JV-VTYPE, exposed as is. The cash-call
//   program selects VTYPE '2' for the ventures it raises cash calls on,
//   which is the non-operated population JIBs are received for; the
//   fixed-value texts have not been read on this system.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBVENTURE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Joint ventures with description'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_VENTURE
  as select from t8jv as Venture
    left outer join t8jvt as Text on  Text.bukrs = Venture.bukrs
                                  and Text.vname = Venture.vname
{
      @EndUserText.label: 'Company Code'
  key Venture.bukrs                  as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key Venture.vname                  as JointVenture,

      @EndUserText.label: 'Venture Type'
      Venture.vtype                  as VentureType,
      @EndUserText.label: 'Joint Venture Name'
      max( Text.vtext )              as JointVentureName
}
group by Venture.bukrs, Venture.vname, Venture.vtype
