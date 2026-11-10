//----------------------------------------------------------------------
// Object    : ZI_PBA_LINE (DDL source, classic view)
// Title     : Per Barrel Analysis - saved ZFI_PL lines, one row per
//             project, fiscal year and period
// Project   : OVL                                   Module: FI
// Source    : Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx, sheet PBA
// Author    : Arnav Johri                            Date: 10.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 1 for the Per Barrel Analysis query (Custom Analytical
//   Queries). ZFI_AGENDA is the table transaction ZFI_PL fills on every
//   profitability run: one row per company code / joint venture / line
//   text / report section, carrying up to four column sets (FISCAL1..4,
//   PERIOD1..4, CRUDE_OIL1..4, GAS1..4) - the up to four year / period
//   columns the user chose for that run.
//   This view turns the four column sets into rows, so that fiscal
//   year and period become ordinary fields the next views can filter
//   and group on. Four UNION ALL branches, one per column set. All
//   lines of all three report sections are passed through unchanged;
//   picking the lines the PBA sheet needs is the next object's job.
//     ReportSection A1 = Quantitative Information
//                   A2 = Profitability Producing Project (USD mn)
//                   A3 = Per Barrel Analysis
//
// CHANGE HISTORY
//   10.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// NOTE: fiscal year and period are NOT part of the key of ZFI_AGENDA.
//   Each run of a joint venture overwrites the rows of its previous
//   run, so the table holds the LAST run per joint venture only. This
//   view can therefore show at most the four year / period columns of
//   that last run; it has no history.
// ASSUMPTION: a cast from DF34_DEC (data elements ZCRUDE_OIL, ZGAS,
//   length 16, decimals 5) to DEC( 16, 5 ) is accepted on this release.
//   No view in this landscape has cast a DF34_DEC column yet. If the
//   activation rejects it, the error names the cast - paste it.
// ASSUMPTION: when two column sets of one row carry the same fiscal
//   year and period (seen: 2024 / Q1 in sets 1 and 2), they hold the
//   same figures, because both come from the same run. The later set
//   is dropped so that a total does not count the period twice.
// ASSUMPTION: FISCALn = 0000 marks an unused column set.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIPBALINE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Per barrel analysis: ZFI_PL saved lines'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PBA_LINE
  as select from zfi_agenda as A
{
      // -- column set 1 ----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key A.comp                                      as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key A.proj                                      as JointVenture,
      @EndUserText.label: 'Report Section'
  key A.per_key                                   as ReportSection,
      @EndUserText.label: 'Line Text'
  key A.per                                       as LineText,
      @EndUserText.label: 'Fiscal Year'
  key A.fiscal1                                   as FiscalYear,
      @EndUserText.label: 'Reporting Period'
  key A.period1                                   as ReportingPeriod,
      @EndUserText.label: 'Crude Oil Value'
      cast( A.crude_oil1 as abap.dec( 16, 5 ) )   as CrudeOilValue,
      @EndUserText.label: 'Gas Value'
      cast( A.gas1 as abap.dec( 16, 5 ) )         as GasValue
}
where
  A.fiscal1 <> '0000'

union all

  select from zfi_agenda as A
{
      // -- column set 2 ----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key A.comp                                      as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key A.proj                                      as JointVenture,
      @EndUserText.label: 'Report Section'
  key A.per_key                                   as ReportSection,
      @EndUserText.label: 'Line Text'
  key A.per                                       as LineText,
      @EndUserText.label: 'Fiscal Year'
  key A.fiscal2                                   as FiscalYear,
      @EndUserText.label: 'Reporting Period'
  key A.period2                                   as ReportingPeriod,
      @EndUserText.label: 'Crude Oil Value'
      cast( A.crude_oil2 as abap.dec( 16, 5 ) )   as CrudeOilValue,
      @EndUserText.label: 'Gas Value'
      cast( A.gas2 as abap.dec( 16, 5 ) )         as GasValue
}
where
      A.fiscal2 <> '0000'
  and (    A.fiscal2 <> A.fiscal1
        or A.period2 <> A.period1 )

union all

  select from zfi_agenda as A
{
      // -- column set 3 ----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key A.comp                                      as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key A.proj                                      as JointVenture,
      @EndUserText.label: 'Report Section'
  key A.per_key                                   as ReportSection,
      @EndUserText.label: 'Line Text'
  key A.per                                       as LineText,
      @EndUserText.label: 'Fiscal Year'
  key A.fiscal3                                   as FiscalYear,
      @EndUserText.label: 'Reporting Period'
  key A.period3                                   as ReportingPeriod,
      @EndUserText.label: 'Crude Oil Value'
      cast( A.crude_oil3 as abap.dec( 16, 5 ) )   as CrudeOilValue,
      @EndUserText.label: 'Gas Value'
      cast( A.gas3 as abap.dec( 16, 5 ) )         as GasValue
}
where
      A.fiscal3 <> '0000'
  and (    A.fiscal3 <> A.fiscal1
        or A.period3 <> A.period1 )
  and (    A.fiscal3 <> A.fiscal2
        or A.period3 <> A.period2 )

union all

  select from zfi_agenda as A
{
      // -- column set 4 ----------------------------------------------------
      @EndUserText.label: 'Company Code'
  key A.comp                                      as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key A.proj                                      as JointVenture,
      @EndUserText.label: 'Report Section'
  key A.per_key                                   as ReportSection,
      @EndUserText.label: 'Line Text'
  key A.per                                       as LineText,
      @EndUserText.label: 'Fiscal Year'
  key A.fiscal4                                   as FiscalYear,
      @EndUserText.label: 'Reporting Period'
  key A.period4                                   as ReportingPeriod,
      @EndUserText.label: 'Crude Oil Value'
      cast( A.crude_oil4 as abap.dec( 16, 5 ) )   as CrudeOilValue,
      @EndUserText.label: 'Gas Value'
      cast( A.gas4 as abap.dec( 16, 5 ) )         as GasValue
}
where
      A.fiscal4 <> '0000'
  and (    A.fiscal4 <> A.fiscal1
        or A.period4 <> A.period1 )
  and (    A.fiscal4 <> A.fiscal2
        or A.period4 <> A.period2 )
  and (    A.fiscal4 <> A.fiscal3
        or A.period4 <> A.period3 )
