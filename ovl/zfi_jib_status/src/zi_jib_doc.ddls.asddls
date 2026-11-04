//----------------------------------------------------------------------
// Object    : ZI_JIB_DOC (DDL source, classic view)
// Title     : JIB documents with their joint venture
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 04.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 2 of 6 for the Management Dashboard card "JIB Status". One
//   row per JIB document and joint venture: ZI_JIB_ENTRY restricted to
//   document type JM and not reversed, joined to its BSEG lines for the
//   venture, DISTINCT so the 150-odd lines of a JIB collapse to one row.
//   A JIB document is a BKPF header of document type JM: the type the
//   non-operated JIB upload (ZJV_NOP_JIBUPLD_MON / _MONC, GS01 set
//   ZJVNONOPJIB_DOCTYP_MON) stamps, and the only type JIBs are posted
//   under - SE16N BKPF OVL / JM over 2016-2018 (03/11/26) showed every
//   row to be a JIB, uploaded or parked and posted with FBV0.
//   The venture is not on the header; BSEG-VNAME carries it on every
//   line, the vendor line included (two PRD documents checked line by
//   line, 03/11/26), and a JIB document carries exactly one venture.
//   Parked documents have no BSEG lines, so the inner join drops them;
//   no BSTAT filter is used (upload-posted headers carry BSTAT 'Z').
//
// CHANGE HISTORY
//   04.11.2026  Arnav Johri  <TR>  Initial development (the document
//                                  part of the former ZI_JIB_DOC_AGG)
//----------------------------------------------------------------------
// ASSUMPTION: document type JM is a literal here, deliberately not read
//   from the GS01 set: if the upload is ever switched to another type,
//   the history posted as JM must stay visible. Add the new type as a
//   second value in the WHERE at that point.
// ASSUMPTION: XBLNR / BKTXT ("AIOC JIB", "For April ,26") are typed by
//   the user in the upload file and are not used as criteria.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBDOC'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB documents with joint venture'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_DOC
  as select distinct from ZI_JIB_ENTRY as Doc
    inner join            bseg         as Item on  Item.bukrs = Doc.CompanyCode
                                                and Item.belnr = Doc.AccountingDocument
                                                and Item.gjahr = Doc.FiscalYear
{
      @EndUserText.label: 'Company Code'
  key Doc.CompanyCode,
      @EndUserText.label: 'Document Number'
  key Doc.AccountingDocument,
      @EndUserText.label: 'Fiscal Year'
  key Doc.FiscalYear,
      @EndUserText.label: 'Joint Venture'
  key Item.vname                     as JointVenture,

      @EndUserText.label: 'Entry Date'
      Doc.EntryDate,
      @EndUserText.label: 'Posting Date'
      Doc.PostingDate,
      @EndUserText.label: 'Fiscal Year of Entry'
      Doc.EntryFiscalYear,
      @EndUserText.label: 'Fiscal Quarter of Entry'
      Doc.EntryFiscalQuarter,
      @EndUserText.label: 'Fiscal Period of Entry'
      Doc.EntryFiscalPeriod
}
where Doc.DocumentType     = 'JM'
  and Doc.ReversalDocument = ''
  and Item.vname          <> ''
