//----------------------------------------------------------------------
// Object    : ZI_PBA_ITEM (DDL source, classic view)
// Title     : Per barrel analysis: ZFI_PL saved lines
// Project   : OVL                                   Module: FI-JVA
// Source    : Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx, sheet PBA
// Author    : Arnav Johri                            Date: 10.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 3 of 4 for the Per Barrel Analysis report: the rows of the
//   table function ZI_PBA_AGENDA_TF under business names. One row per
//   company code / joint venture / product / fiscal year / period /
//   ZFI_PL section / ZFI_PL line.
//     ReportSection    A1 quantities, A2 profitability (USD mn),
//                      A3 per barrel
//     LineValue        the figure as ZFI_PL saved it
//     QuantityMillion  the same figure in millions for quantity lines
//                      (oil bbl / 1,000,000; gas is stored in millions)
//   NOTE: ZFI_AGENDA holds the last ZFI_PL run per project only. This
//   view shows that run and nothing older.
//   Needs ZI_PBA_AGENDA_TF and ZCL_PBA_AGENDA_TF active first.
//
// CHANGE HISTORY
//   10.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIPBAITEM'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Per barrel analysis: ZFI_PL saved lines'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PBA_ITEM
  as select from ZI_PBA_AGENDA_TF( p_clnt : $session.client ) as A
{
      @EndUserText.label: 'Company Code'
  key A.company_code   as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key A.joint_venture  as JointVenture,
      @EndUserText.label: 'Product'
  key A.product        as Product,
      @EndUserText.label: 'Fiscal Year'
  key A.fiscal_year    as FiscalYear,
      @EndUserText.label: 'Reporting Period'
  key A.report_period  as ReportingPeriod,
      @EndUserText.label: 'Report Section'
  key A.report_section as ReportSection,
      @EndUserText.label: 'Line Text'
  key A.line_text      as LineText,

      @EndUserText.label: 'Line Value'
      A.line_value     as LineValue,
      @EndUserText.label: 'Quantity in Millions'
      A.quantity_mn    as QuantityMillion
}
