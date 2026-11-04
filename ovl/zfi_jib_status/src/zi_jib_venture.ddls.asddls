//----------------------------------------------------------------------
// Object    : ZI_JIB_VENTURE (DDL source, classic view)
// Title     : Joint ventures with description
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 5 of 6 for the Management Dashboard card "JIB Status".
//   The ventures the dashboard reports on - one row each from the
//   venture master T8JV, with the description from T8JVT and the
//   venture type. The scope is the four ventures the requirement names
//   (AA2002 ACG, SD2002 Block 5A, MM2002 A1 Myanmar, MM2012 A3 Myanmar);
//   JIBs are received only for these today (Arnav, 03/11/26). Other
//   ventures with JM documents in history, e.g. VN2012 (Vietnam 06.1,
//   operator BP, JIBs up to 2017), are ordinary JIBs structurally -
//   nothing in BKPF or BSEG marks them as out of scope - so the list
//   has to be explicit. The text join is on company code and venture
//   only - the join the active cash-call program and ZFI_JV_TB use -
//   and the text is taken with max() under a GROUP BY, so if T8JVT
//   carries a language key with several languages maintained, a
//   venture still comes out exactly once and the cube's counts hold.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//   03.11.2026  Arnav Johri  <TR>  Scope fixed to the four ventures of
//                                  the requirement (was: all of T8JV)
//----------------------------------------------------------------------
// ASSUMPTION: the four venture codes are those of the requirement
//   workbook and are spelled exactly as in T8JV for company code OVL.
//   A fifth venture is one more OR line in the WHERE below.
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
where Venture.vname = 'AA2002'
   or Venture.vname = 'SD2002'
   or Venture.vname = 'MM2002'
   or Venture.vname = 'MM2012'
group by Venture.bukrs, Venture.vname, Venture.vtype
