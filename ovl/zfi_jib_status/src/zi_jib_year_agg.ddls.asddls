//----------------------------------------------------------------------
// Object    : ZI_JIB_YEAR_AGG (DDL source, classic view)
// Title     : JIB summary per joint venture and fiscal year
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 06.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 3 of 7 for the Management Dashboard card "JIB Status". The
//   JIB documents of ZI_JIB_DOC grouped per company code / joint
//   venture / fiscal year: the latest upload date of the year, how many
//   of the twelve months have a JIB, how many documents, and
//   JibPosted = 1. The cube carries these on every row of the venture
//   and year, so a query without Month and Document Number in its rows
//   collapses to one line per venture - "if they enter 2026, show the
//   last posting of the year" - while the monthly layout stays intact.
//
// CHANGE HISTORY
//   06.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: JibPosted = count( distinct CompanyCode ) is 1 on every
//   row (a group has exactly one company code); the cube turns it into
//   the year's Uploaded / Pending text through a CASE on the joined
//   column (NULL falls into ELSE).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBYEARAGG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB summary per venture and fiscal year'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_YEAR_AGG
  as select from ZI_JIB_DOC as Doc
{
      @EndUserText.label: 'Company Code'
  key Doc.CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key Doc.JointVenture,
      @EndUserText.label: 'Fiscal Year'
  key Doc.FiscalYear,

      @EndUserText.label: 'Last JIB Upload in Fiscal Year'
      max( Doc.EntryDate )                     as LastEntryDate,
      @EndUserText.label: 'Months Uploaded in Fiscal Year'
      count( distinct Doc.FiscalPeriod )       as MonthsUploaded,
      @EndUserText.label: 'JIB Documents in Fiscal Year'
      count( distinct Doc.AccountingDocument ) as JibDocuments,
      @EndUserText.label: 'JIB Posted'
      count( distinct Doc.CompanyCode )        as JibPosted
}
group by Doc.CompanyCode, Doc.JointVenture, Doc.FiscalYear
