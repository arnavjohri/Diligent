//----------------------------------------------------------------------
// Object    : ZI_JIB_CLEARING (DDL source, classic view)
// Title     : Clearing of the JIB document (vendor line)
// Project   : OVL                                   Module: FI-JVA
// Source    : Client mail 17/11/26 - additional requirements for the
//             JIB Report (clearing date, clearing document number)
// Author    : Arnav Johri                            Date: 17.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 3 of 8 for the Management Dashboard card "JIB Status". One
//   row per CLEARED JIB document: company code, document, fiscal year,
//   with the clearing date and the clearing document number of its
//   vendor line. A JIB is the operator's bill to OVL, so the document
//   credits the operator as a vendor (posting key 31, account type K)
//   and that is the one open-item line of the document - the cost lines
//   are not open-item managed. When the vendor line is settled (payment,
//   or clearing against the cash-call advances) BSEG-AUGBL / AUGDT are
//   written on it; while the JIB is open they are blank and the
//   document has no row here. The cube LEFT OUTER JOINs this view on
//   the document key, so Clearing Date and Clearing Document are filled
//   only once the JIB is cleared - exactly the client's wording - and
//   null on an open JIB and on a Pending month.
//   Why a view of its own and not two more columns in ZI_JIB_DOC: that
//   view is a SELECT DISTINCT over every BSEG line of the document;
//   AUGBL on the field list would split a cleared document into one row
//   for the vendor line (AUGBL filled) and one for the cost lines (AUGBL
//   blank) and double the document counts. Grouped per document here,
//   the grain of ZI_JIB_DOC is untouched.
//   Reads ZI_JIB_DOC rather than BKPF so the document type filter (JM)
//   stays in one place.
//
// CHANGE HISTORY
//   17.11.2026  Arnav Johri  <TR>  Initial development (ISSUES 11)
//----------------------------------------------------------------------
// ASSUMPTION: a JIB document has one vendor line (the two PRD documents
//   read line by line on 03/11/26 had one, posting key 31). With several
//   vendor lines cleared by different documents, max() returns the
//   latest clearing date and the highest clearing document number, not
//   necessarily from the same line.
// ASSUMPTION: a REVERSED JIB shows its reversal document (type YH) as
//   the clearing document and the reversal date as the clearing date -
//   FB08 clears the vendor line (ISSUES 8). The Reversed flag of the row
//   tells the two cases apart. Blank the clearing on reversed documents
//   only if the client asks.
// ASSUMPTION: the clearing document is display only. It carries no
//   semantic object for the FB03 click: the row's FiscalYear is the
//   JIB's, not the clearing document's, so the navigation parameters
//   would be wrong. BSEG-AUGGJ (clearing fiscal year) was not used
//   because its presence on this release is unconfirmed.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBCLEARING'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB document clearing (vendor line)'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_CLEARING
  as select from ZI_JIB_DOC as Doc
    inner join   bseg       as Item on  Item.bukrs = Doc.CompanyCode
                                    and Item.belnr = Doc.AccountingDocument
                                    and Item.gjahr = Doc.FiscalYear
{
      @EndUserText.label: 'Company Code'
  key Doc.CompanyCode,
      @EndUserText.label: 'Document Number'
  key Doc.AccountingDocument,
      @EndUserText.label: 'Fiscal Year'
  key Doc.FiscalYear,

      @EndUserText.label: 'Clearing Date'
      max( Item.augdt )                as ClearingDate,
      @EndUserText.label: 'Clearing Document'
      max( Item.augbl )                as ClearingDocument
}
// vendor line (account type K) that has been cleared
where Item.koart = 'K'
  and Item.augbl <> ''
group by Doc.CompanyCode, Doc.AccountingDocument, Doc.FiscalYear
