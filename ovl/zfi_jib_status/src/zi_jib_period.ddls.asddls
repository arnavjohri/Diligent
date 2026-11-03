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
//   PeriodStartDate is the first calendar day of the period (fiscal
//   year variant April-March: period 01 of 2026 = 01.04.2026, period 10
//   = 01.01.2027), so a query can filter a date range on it; a period
//   is in the range when its first day is. Built as 1 April of the
//   fiscal year plus (period - 1) months, one literal per period, since
//   arithmetic on the NUMC period is not possible on this release.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//   03.11.2026  Arnav Johri  <TR>  PeriodStartDate added
//----------------------------------------------------------------------
// ASSUMPTION: a period with no FI posting at all needs no row. If the
//   dashboard must show a future period before anything is posted in
//   it, the frame has to come from a calendar / T009B view instead.
// ASSUMPTION: fiscal year variant April-March for every company code
//   (OVL: posting period 1 = April, confirmed on the PRD sample).
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
  key Doc.monat                      as FiscalPeriod,

      @EndUserText.label: 'Period Start Date'
      case Doc.monat
        when '01' then
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats )
        when '02' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          1, 'INITIAL' )
        when '03' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          2, 'INITIAL' )
        when '04' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          3, 'INITIAL' )
        when '05' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          4, 'INITIAL' )
        when '06' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          5, 'INITIAL' )
        when '07' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          6, 'INITIAL' )
        when '08' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          7, 'INITIAL' )
        when '09' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          8, 'INITIAL' )
        when '10' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          9, 'INITIAL' )
        when '11' then dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          10, 'INITIAL' )
        else dats_add_months(
          cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
          11, 'INITIAL' )
      end                              as PeriodStartDate
}
where Doc.monat >= '01'
  and Doc.monat <= '12'
