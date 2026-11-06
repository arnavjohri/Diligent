//----------------------------------------------------------------------
// Object    : ZI_JIB_DOC_AGG (DDL source, classic view)
// Title     : JIB postings per joint venture and posting period
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 2 of 5 for the Management Dashboard card "JIB Status". The
//   JIB documents of ZI_JIB_DOC grouped per company code / joint
//   venture / fiscal year / posting period - the month the JIB is FOR:
//   the latest day one of them was entered (LastEntryDate), the latest
//   posting date, the number of documents, the highest document number
//   (LastDocument - the cube flags that document's row as the one that
//   counts the venture once) and JibPosted = 1.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development (per posting
//                                  period, from BKPF/BSEG directly)
//   04.11.2026  Arnav Johri  <TR>  Entry-date windows, three
//                                  granularities (withdrawn 06/11/26)
//   06.11.2026  Arnav Johri  <TR>  Back to the posting period, on
//                                  ZI_JIB_DOC; LastDocument added
//----------------------------------------------------------------------
// ASSUMPTION: JibPosted = count( distinct CompanyCode ) is 1 on every
//   row (a group has exactly one company code). The cube turns it into
//   the Uploaded / Pending status through a CASE on the joined column
//   (NULL on a Pending row falls into ELSE).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBDOCAGG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB postings per venture and period'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_DOC_AGG
  as select from ZI_JIB_DOC as Doc
{
      @EndUserText.label: 'Company Code'
  key Doc.CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key Doc.JointVenture,
      @EndUserText.label: 'Fiscal Year'
  key Doc.FiscalYear,
      @EndUserText.label: 'Posting Period'
  key Doc.FiscalPeriod,

      @EndUserText.label: 'Last JIB Upload Date'
      max( Doc.EntryDate )                     as LastEntryDate,
      @EndUserText.label: 'Last JIB Posting Date'
      max( Doc.PostingDate )                   as LastPostingDate,
      @EndUserText.label: 'Last Document'
      max( Doc.AccountingDocument )            as LastDocument,
      @EndUserText.label: 'JIB Documents'
      count( distinct Doc.AccountingDocument ) as JibDocuments,
      @EndUserText.label: 'JIB Posted'
      count( distinct Doc.CompanyCode )        as JibPosted
}
group by Doc.CompanyCode, Doc.JointVenture, Doc.FiscalYear, Doc.FiscalPeriod
