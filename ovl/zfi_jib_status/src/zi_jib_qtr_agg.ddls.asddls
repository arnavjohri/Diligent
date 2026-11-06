//----------------------------------------------------------------------
// Object    : ZI_JIB_QTR_AGG (DDL source, classic view)
// Title     : JIB summary per joint venture and fiscal quarter
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 06.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 4 of 7 for the Management Dashboard card "JIB Status". The
//   JIB documents of ZI_JIB_DOC grouped per company code / joint
//   venture / fiscal year / fiscal quarter of the posting period: the
//   latest upload date of the quarter, how many of its three months
//   have a JIB, how many documents, and JibPosted = 1. Same purpose as
//   ZI_JIB_YEAR_AGG, for a one-line-per-venture quarter view.
//
// CHANGE HISTORY
//   06.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: JibPosted = count( distinct CompanyCode ) is 1 on every
//   row; the cube turns it into the quarter's Uploaded / Pending text
//   through a CASE on the joined column (NULL falls into ELSE).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBQTRAGG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB summary per venture and fiscal quarter'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_QTR_AGG
  as select from ZI_JIB_DOC as Doc
{
      @EndUserText.label: 'Company Code'
  key Doc.CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key Doc.JointVenture,
      @EndUserText.label: 'Fiscal Year'
  key Doc.FiscalYear,
      @EndUserText.label: 'Fiscal Quarter'
  key Doc.FiscalQuarter,

      @EndUserText.label: 'Last JIB Upload in Quarter'
      max( Doc.EntryDate )                     as LastEntryDate,
      @EndUserText.label: 'Months Uploaded in Quarter'
      count( distinct Doc.FiscalPeriod )       as MonthsUploaded,
      @EndUserText.label: 'JIB Documents in Quarter'
      count( distinct Doc.AccountingDocument ) as JibDocuments,
      @EndUserText.label: 'JIB Posted'
      count( distinct Doc.CompanyCode )        as JibPosted
}
group by Doc.CompanyCode, Doc.JointVenture, Doc.FiscalYear, Doc.FiscalQuarter
