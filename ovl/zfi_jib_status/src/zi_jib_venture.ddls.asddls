//----------------------------------------------------------------------
// Object    : ZI_JIB_VENTURE (DDL source, classic view)
// Title     : Joint ventures with description
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 2 of 8 for the Management Dashboard card "JIB Status".
//   The ventures the dashboard reports on - one row each from the
//   venture master T8JV, with the description from T8JVT and the
//   venture type. SCOPE SINCE 17/11/26: every venture, in any company
//   code, that has at least one JIB document (document type JM, via
//   ZI_JIB_DOC) - the client asked for "all ventures" after testing the
//   four of the requirement (AA2002 ACG, SD2002 Block 5A, MM2002 A1
//   Myanmar, MM2012 A3 Myanmar). The inner join to ZI_JIB_DOC is the
//   scope filter; it multiplies a venture by its documents and the
//   GROUP BY collapses it to one row again. A venture that never had a
//   JIB posted is NOT listed: nothing in BKPF/BSEG marks a venture as
//   one that should receive JIBs, and the T8JV venture type values have
//   not been read on this system, so an operated venture (OVL is the
//   operator, no JIB is ever received) cannot be told apart from a
//   non-operated one whose JIB is simply missing. VN2012 (Vietnam 06.1,
//   JIBs up to 2017) therefore comes back, with Pending months after.
//   The text join is on company code and venture only - the join the
//   active cash-call program and ZFI_JV_TB use - and the text is taken
//   with max() under a GROUP BY, so if T8JVT carries a language key
//   with several languages maintained, a venture still comes out
//   exactly once and the cube's counts hold.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//   03.11.2026  Arnav Johri  <TR>  Scope fixed to the four ventures of
//                                  the requirement (was: all of T8JV)
//   17.11.2026  Arnav Johri  <TR>  Scope = every venture with a JIB
//                                  document (join to ZI_JIB_DOC); the
//                                  WHERE on the four codes commented
//                                  out (ISSUES 11)
//----------------------------------------------------------------------
// ASSUMPTION: "all ventures" = all ventures that have received a JIB
//   (any company code). If the client also wants ventures with no JIB
//   ever posted, the join to ZI_JIB_DOC goes and a WHERE on the T8JV
//   venture type (non-operated) replaces it - the value has to be read
//   in SE16N T8JV first.
// ASSUMPTION: VentureType is T8JV-VTYPE, exposed as is; the fixed-value
//   texts have not been read on this system.
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
    // 17/11/26: scope = ventures with at least one JIB document
    inner join      ZI_JIB_DOC as Doc  on  Doc.CompanyCode  = Venture.bukrs
                                       and Doc.JointVenture = Venture.vname
    left outer join t8jvt      as Text on  Text.bukrs = Venture.bukrs
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
// 17/11/26: four-venture scope of 03/11/26 withdrawn (ISSUES 11)
// where Venture.vname = 'AA2002'
//    or Venture.vname = 'SD2002'
//    or Venture.vname = 'MM2002'
//    or Venture.vname = 'MM2012'
group by Venture.bukrs, Venture.vname, Venture.vtype
