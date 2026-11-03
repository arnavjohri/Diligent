//----------------------------------------------------------------------
// Object    : ZI_JIB_PERIOD (DDL source, classic view)
// Title     : Fiscal periods with postings, per company code
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 2 of 4 for the Management Dashboard card "JIB Status".
//   The frame of periods the cube reports on: every company code /
//   fiscal year / posting period that has at least one FI document of
//   any type. The cube pairs each of these periods with every joint
//   venture of the company code, so a venture whose JIB is missing in
//   a period still gets a row - the "Pending" line. Taking the periods
//   from all documents, not from JIB documents only, means a period in
//   which no JIB at all has been posted yet (the current month) still
//   appears, with every venture Pending.
//   Special periods 13-16 are left out: JIBs are posted in 01-12.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: a period with no FI posting at all needs no row. If the
//   dashboard must show a future period before anything is posted in
//   it, the frame has to come from a calendar / T009B view instead.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBPERIOD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Fiscal periods with postings'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_PERIOD
  as select distinct from bkpf as Doc
{
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key Doc.monat                      as FiscalPeriod
}
where Doc.monat >= '01'
  and Doc.monat <= '12'
