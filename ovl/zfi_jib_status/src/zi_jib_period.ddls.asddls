//----------------------------------------------------------------------
// Object    : ZI_JIB_PERIOD (DDL source, classic view)
// Title     : The twelve posting periods of every fiscal year with
//             postings, per company code
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 06.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 5 of 7 for the Management Dashboard card "JIB Status". The
//   frame of months the cube reports on: for every company code /
//   fiscal year in which at least one FI document exists, all twelve
//   posting periods 01-12, whether or not anything was posted in them.
//   The cube pairs each period with every venture in scope, so a month
//   whose JIB is not posted yet - including the months still to come
//   in the current fiscal year - gets its "Pending" row, as the
//   requirement's example shows (October to March Pending for fiscal
//   year 2026-27 in October 2026). Twelve UNION ALL branches, one per
//   period, each a DISTINCT over company code and fiscal year of BKPF;
//   PeriodStartDate is 1 April of the fiscal year plus (period - 1)
//   months (fiscal year variant April-March).
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development (periods with
//                                  postings only; withdrawn 04/11/26)
//   06.11.2026  Arnav Johri  <TR>  Rebuilt: all twelve periods of each
//                                  fiscal year with postings
//   06.11.2026  Arnav Johri  <TR>  FiscalQuarter per period (join key
//                                  of the quarter summary)
//----------------------------------------------------------------------
// ASSUMPTION: fiscal year variant April-March for every company code
//   (OVL: posting period 1 = April, confirmed on the PRD sample).
// ASSUMPTION: a fiscal year appears once any document carries it. The
//   next fiscal year shows up with its first posting in April.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBPERIOD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Posting periods of fiscal years with postings'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_PERIOD
  as select distinct from bkpf as Doc
{
      // -- period 01 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '01' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q1' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats )
                                     as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 02 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '02' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q1' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       1, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 03 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '03' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q1' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       2, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 04 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '04' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q2' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       3, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 05 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '05' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q2' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       4, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 06 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '06' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q2' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       5, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 07 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '07' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q3' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       6, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 08 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '08' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q3' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       7, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 09 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '09' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q3' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       8, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 10 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '10' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q4' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       9, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 11 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '11' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q4' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       10, 'INITIAL' )  as PeriodStartDate
}

union all

  select distinct from bkpf as Doc
{
      // -- period 12 -----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key cast( '12' as abap.numc( 2 ) ) as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      cast( 'Q4' as abap.char( 2 ) )  as FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      dats_add_months( cast( concat( cast( Doc.gjahr as abap.char( 4 ) ), '0401' ) as abap.dats ),
                       11, 'INITIAL' )  as PeriodStartDate
}
