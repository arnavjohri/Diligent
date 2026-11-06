//----------------------------------------------------------------------
// Object    : ZI_JIB_DOC (DDL source, classic view)
// Title     : JIB documents with their joint venture
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 04.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 1 of 7 for the Management Dashboard card "JIB Status". One
//   row per JIB document and joint venture: BKPF restricted to document
//   type JM, joined to its BSEG lines for the venture, DISTINCT so the
//   150-odd lines of a JIB collapse to one row. REVERSED JIBs COUNT:
//   Block 5A books its JIB and reverses it later (1025001669 for June
//   2025, reversed 01.07.2025 by 9102500194; both December 2025
//   documents reversed 31.01.2026), and Corporate Accounts still treats
//   the month as uploaded (06/11/26). The reversal document and a
//   Reversed flag are carried so the dashboard can show it. The
//   reversal documents themselves are type YH, not JM, so the document
//   type filter keeps them out. Carries
//   the posting period the JIB is FOR (GJAHR / MONAT - "JIB for
//   September" sits in period 06/2026) and the day it was entered in
//   the system (CPUDT - "uploaded on 14.10.2026"), plus header text,
//   reference and user for the document line of the dashboard.
//   A JIB document is a BKPF header of document type JM: the type the
//   non-operated JIB upload (ZJV_NOP_JIBUPLD_MON / _MO_C, GS01 set
//   ZJVNONOPJIB_DOCTYP_MON) stamps, and the only type JIBs are posted
//   under - SE16N BKPF OVL / JM over 2016-2018 (03/11/26) showed every
//   row to be a JIB. The upload PARKS the document and it is posted
//   with FBV0 (TCODE FBVB); CPUDT / CPUTM are set at that posting (FB03
//   header of 1026003147: entry 13:07:04, parking 12:34:23, 06/11/26).
//   The venture is not on the header; BSEG-VNAME carries it on every
//   line, the vendor line included (two PRD documents checked line by
//   line, 03/11/26), and a JIB document carries exactly one venture.
//   Parked documents have no BSEG lines, so the inner join drops them;
//   no BSTAT filter is used (upload-posted headers carry BSTAT 'Z').
//
// CHANGE HISTORY
//   04.11.2026  Arnav Johri  <TR>  Initial development (on ZI_JIB_ENTRY,
//                                  entry-date windows)
//   06.11.2026  Arnav Johri  <TR>  Reads BKPF directly; posting period
//                                  instead of entry-date windows; header
//                                  text, reference, user added
//   06.11.2026  Arnav Johri  <TR>  FiscalQuarter of the posting period
//                                  (for the quarter summary)
//   06.11.2026  Arnav Johri  <TR>  Reversed JIBs no longer excluded;
//                                  ReversalDocument, ReversalIndicator
//----------------------------------------------------------------------
// ASSUMPTION: document type JM is a literal here, deliberately not read
//   from the GS01 set: if the upload is ever switched to another type,
//   the history posted as JM must stay visible. Add the new type as a
//   second value in the WHERE at that point.
// ASSUMPTION: XBLNR / BKTXT ("AIOC JIB", "For September ,26") are typed
//   by the user in the upload file; shown, never used as criteria.
// ASSUMPTION: a reversed JIB counts as uploaded for its month, with the
//   original entry date. A JIB reversed and posted again shows both
//   documents. Reversal documents are not type JM on this system (YH,
//   number range 91); if that ever changes they would count as JIBs.
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
  as select distinct from bkpf as Doc
    inner join            bseg as Item on  Item.bukrs = Doc.bukrs
                                       and Item.belnr = Doc.belnr
                                       and Item.gjahr = Doc.gjahr
{
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Document Number'
  key Doc.belnr                      as AccountingDocument,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,
      @EndUserText.label: 'Joint Venture'
  key Item.vname                     as JointVenture,

      @EndUserText.label: 'Posting Period'
      Doc.monat                      as FiscalPeriod,
      @EndUserText.label: 'Fiscal Quarter'
      case Doc.monat
        when '01' then 'Q1'
        when '02' then 'Q1'
        when '03' then 'Q1'
        when '04' then 'Q2'
        when '05' then 'Q2'
        when '06' then 'Q2'
        when '07' then 'Q3'
        when '08' then 'Q3'
        when '09' then 'Q3'
        else           'Q4'
      end                            as FiscalQuarter,
      @EndUserText.label: 'Posting Date'
      Doc.budat                      as PostingDate,
      @EndUserText.label: 'Date of JIB Upload'
      Doc.cpudt                      as EntryDate,
      @EndUserText.label: 'Document Header Text'
      Doc.bktxt                      as DocumentHeaderText,
      @EndUserText.label: 'Reference'
      Doc.xblnr                      as Reference,
      @EndUserText.label: 'Entered By'
      Doc.usnam                      as EnteredBy,
      @EndUserText.label: 'Reversal Document'
      Doc.stblg                      as ReversalDocument,
      @EndUserText.label: 'Reversed'
      case when Doc.stblg <> ''
           then 'X'
           else ' '
      end                            as ReversalIndicator,
      // 1 per document: the cube's "JIB Documents" measure after the
      // left outer join (coalesce to 0 on a Pending row)
      @EndUserText.label: 'One'
      cast( 1 as abap.int4 )         as One
}
where Doc.blart  = 'JM'
  and Item.vname <> ''
