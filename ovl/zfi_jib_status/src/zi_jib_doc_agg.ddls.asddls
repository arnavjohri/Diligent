//----------------------------------------------------------------------
// Object    : ZI_JIB_DOC_AGG (DDL source, classic view)
// Title     : Latest JIB entry per venture and window (year, quarter,
//             month)
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 3 of 6 for the Management Dashboard card "JIB Status". The
//   JIB documents of ZI_JIB_DOC aggregated per company code / joint
//   venture at three granularities of the ENTRY date, in one UNION ALL:
//     Y  per fiscal year of entry            (quarter, period blank)
//     Q  per fiscal year + quarter of entry  (period blank)
//     M  per fiscal year + quarter + period of entry
//   Each row carries the latest entry date in the window, the latest
//   posting date, the number of JIB documents and JibPosted = 1. So a
//   query filtered on one granularity and one window gets one row per
//   venture with its last posting in that window - "if they enter 2026
//   and the last posting was done in period 1, show that" (Arnav,
//   04/11/26) - instead of one row per month.
//   Same shape as ZDPR_P_PERF_AGG (literal key column + GROUP BY in
//   each UNION ALL branch), which is active on this system.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development (per posting
//                                  period, from BKPF/BSEG directly)
//   04.11.2026  Arnav Johri  <TR>  Rebuilt on ZI_JIB_DOC: entry-date
//                                  windows, three granularities
//----------------------------------------------------------------------
// ASSUMPTION: JibPosted = count( distinct CompanyCode ) is 1 on every
//   row (a group has exactly one company code). The cube turns it into
//   the 0 / 1 indicator through coalesce( ..., 0 ) after the left outer
//   join, without a CASE on a joined column.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBDOCAGG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Latest JIB entry per venture and window'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_DOC_AGG
  as select from ZI_JIB_DOC as Doc
{
      // -- Y: per fiscal year of entry -----------------------------------
  key Doc.CompanyCode,
  key Doc.JointVenture,
  key cast( 'Y' as abap.char( 1 ) )          as Granularity,
  key Doc.EntryFiscalYear                    as FiscalYear,
  key cast( ' ' as abap.char( 2 ) )          as FiscalQuarter,
  key cast( ' ' as abap.char( 2 ) )          as FiscalPeriod,

      max( Doc.EntryDate )                   as LastEntryDate,
      max( Doc.PostingDate )                 as LastPostingDate,
      count( distinct Doc.AccountingDocument ) as JibDocuments,
      count( distinct Doc.CompanyCode )      as JibPosted
}
group by Doc.CompanyCode, Doc.JointVenture, Doc.EntryFiscalYear

union all

  select from ZI_JIB_DOC as Doc
{
      // -- Q: per fiscal year and quarter of entry -----------------------
  key Doc.CompanyCode,
  key Doc.JointVenture,
  key cast( 'Q' as abap.char( 1 ) )          as Granularity,
  key Doc.EntryFiscalYear                    as FiscalYear,
  key Doc.EntryFiscalQuarter                 as FiscalQuarter,
  key cast( ' ' as abap.char( 2 ) )          as FiscalPeriod,

      max( Doc.EntryDate )                   as LastEntryDate,
      max( Doc.PostingDate )                 as LastPostingDate,
      count( distinct Doc.AccountingDocument ) as JibDocuments,
      count( distinct Doc.CompanyCode )      as JibPosted
}
group by Doc.CompanyCode, Doc.JointVenture, Doc.EntryFiscalYear, Doc.EntryFiscalQuarter

union all

  select from ZI_JIB_DOC as Doc
{
      // -- M: per fiscal year, quarter and period of entry ---------------
  key Doc.CompanyCode,
  key Doc.JointVenture,
  key cast( 'M' as abap.char( 1 ) )          as Granularity,
  key Doc.EntryFiscalYear                    as FiscalYear,
  key Doc.EntryFiscalQuarter                 as FiscalQuarter,
  key Doc.EntryFiscalPeriod                  as FiscalPeriod,

      max( Doc.EntryDate )                   as LastEntryDate,
      max( Doc.PostingDate )                 as LastPostingDate,
      count( distinct Doc.AccountingDocument ) as JibDocuments,
      count( distinct Doc.CompanyCode )      as JibPosted
}
group by Doc.CompanyCode, Doc.JointVenture, Doc.EntryFiscalYear, Doc.EntryFiscalQuarter,
         Doc.EntryFiscalPeriod
