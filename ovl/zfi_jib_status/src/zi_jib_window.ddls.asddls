//----------------------------------------------------------------------
// Object    : ZI_JIB_WINDOW (DDL source, classic view)
// Title     : Entry-date windows (fiscal year, quarter, month) with
//             postings, per company code
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 04.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 4 of 6 for the Management Dashboard card "JIB Status". The
//   frame of windows the cube reports on: every company code / fiscal
//   year of entry (Y), fiscal year + quarter of entry (Q) and fiscal
//   year + quarter + period of entry (M) in which at least one FI
//   document of any type was entered, each with the first day of the
//   window. The cube pairs each window with every venture in scope, so
//   a venture without a JIB in the window still gets a row - the
//   "Pending" line. Taking the windows from all documents, not from
//   JIB documents only, means the current month exists as soon as
//   anything is entered in it, with every venture Pending.
//
// CHANGE HISTORY
//   04.11.2026  Arnav Johri  <TR>  Initial development (replaces
//                                  ZI_JIB_PERIOD)
//----------------------------------------------------------------------
// ASSUMPTION: a window with no FI document entered at all needs no
//   row. If the dashboard must show a future month before anything is
//   entered in it, the frame has to come from a calendar view instead.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBWINDOW'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Entry-date windows with postings'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_WINDOW
  as select distinct from ZI_JIB_ENTRY as Doc
{
      // -- Y: fiscal years of entry --------------------------------------
  key Doc.CompanyCode,
  key cast( 'Y' as abap.char( 1 ) )          as Granularity,
  key Doc.EntryFiscalYear                    as FiscalYear,
  key cast( ' ' as abap.char( 2 ) )          as FiscalQuarter,
  key cast( ' ' as abap.char( 2 ) )          as FiscalPeriod,
      Doc.EntryFiscalYearStart               as PeriodStartDate
}
where Doc.EntryFiscalPeriod <> '00'

union all

  select distinct from ZI_JIB_ENTRY as Doc
{
      // -- Q: fiscal quarters of entry -----------------------------------
  key Doc.CompanyCode,
  key cast( 'Q' as abap.char( 1 ) )          as Granularity,
  key Doc.EntryFiscalYear                    as FiscalYear,
  key Doc.EntryFiscalQuarter                 as FiscalQuarter,
  key cast( ' ' as abap.char( 2 ) )          as FiscalPeriod,
      Doc.EntryQuarterStart                  as PeriodStartDate
}
where Doc.EntryFiscalPeriod <> '00'

union all

  select distinct from ZI_JIB_ENTRY as Doc
{
      // -- M: months of entry --------------------------------------------
  key Doc.CompanyCode,
  key cast( 'M' as abap.char( 1 ) )          as Granularity,
  key Doc.EntryFiscalYear                    as FiscalYear,
  key Doc.EntryFiscalQuarter                 as FiscalQuarter,
  key Doc.EntryFiscalPeriod                  as FiscalPeriod,
      Doc.EntryMonthStart                    as PeriodStartDate
}
where Doc.EntryFiscalPeriod <> '00'
