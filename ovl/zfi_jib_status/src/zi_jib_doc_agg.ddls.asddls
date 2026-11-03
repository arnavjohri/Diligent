//----------------------------------------------------------------------
// Object    : ZI_JIB_DOC_AGG (DDL source, classic view)
// Title     : JIB postings per joint venture and fiscal period
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 1 of 4 for the Management Dashboard card "JIB Status". The
//   others are ZI_JIB_PERIOD (periods with postings), ZI_JIB_VENTURE
//   (venture master with text) and ZI_JIB_STATUS_CUBE, the cube the
//   functional consultant picks in Custom Analytical Queries. All four
//   ship together in ZFI_JIB_STATUS.zip, into package ZFI_OTH.
//   One row per company code / joint venture / fiscal year / posting
//   period: how many JIB documents were posted for that venture in that
//   period and when the last one was entered (BKPF-CPUDT - the
//   "creation date" the dashboard shows next to "Uploaded").
//   A JIB document is a BKPF header of document type JM: the type the
//   non-operated JIB upload (ZJV_NOP_JIBUPLD_MON / _MONC, GS01 set
//   ZJVNONOPJIB_DOCTYP_MON) stamps, and the only type JIBs are posted
//   under. SE16N BKPF OVL / JM over 2016-2018 (03/11/26): every row is
//   a JIB, whether uploaded by the program or parked and posted with
//   FBV0 (TCODE FBVB).
//   The venture is not on the header. It comes from the line items
//   (BSEG-VNAME), so a document that bills several ventures counts once
//   for each of them, and header lines without a venture are ignored.
//   Excluded: reversed documents (STBLG filled - a reversed JIB has to
//   be posted again) and parked documents (they have no BSEG lines, so
//   the inner join drops them; no BSTAT filter is needed, and none is
//   used because upload-posted headers carry BSTAT 'Z' in PRD).
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: document type JM is a literal here, deliberately not read
//   from the GS01 set: if the upload is ever switched to another type,
//   the history posted as JM must stay visible. Add the new type as a
//   second value in the WHERE at that point.
// ASSUMPTION: XBLNR / BKTXT ("AIOC JIB", "For April ,26") are typed by
//   the user in the upload file and are not used as criteria.
// ASSUMPTION: the period a JIB belongs to is its posting period
//   (GJAHR / MONAT), not the month named in the header text. The two
//   differ in PRD (1017004699: period 11/2017, text "For Jan'18").
// ASSUMPTION: JibPosted = count( distinct bukrs ) is 1 on every row (a
//   group has exactly one company code). The cube turns it into the
//   0 / 1 indicator "JIB posted" through coalesce( ..., 0 ) after the
//   left outer join, without a CASE on a joined column.
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
  as select from bkpf as Doc
    inner join   bseg as Item on  Item.bukrs = Doc.bukrs
                              and Item.belnr = Doc.belnr
                              and Item.gjahr = Doc.gjahr
{
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Joint Venture'
  key Item.vname                     as JointVenture,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Posting Period'
  key Doc.monat                      as FiscalPeriod,

      @EndUserText.label: 'Last JIB Entry Date'
      max( Doc.cpudt )               as LastEntryDate,
      @EndUserText.label: 'Last JIB Posting Date'
      max( Doc.budat )               as LastPostingDate,
      @EndUserText.label: 'JIB Documents'
      count( distinct Doc.belnr )    as JibDocuments,
      @EndUserText.label: 'JIB Posted'
      count( distinct Doc.bukrs )    as JibPosted
}
where Doc.blart  = 'JM'
  and Doc.stblg  = ''
  and Item.vname <> ''
group by Doc.bukrs, Item.vname, Doc.gjahr, Doc.monat
