//----------------------------------------------------------------------
// Object    : ZI_JIB_ENTRY (DDL source, classic view)
// Title     : FI document headers with the fiscal window of their
//             entry date
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 04.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 1 of 6 for the Management Dashboard card "JIB Status". Every
//   BKPF header with the fiscal year, quarter and period of the day it
//   was ENTERED (CPUDT) - not of its posting date. The dashboard asks
//   "in which month / quarter / fiscal year was the JIB posted into the
//   system", so the entry date decides the window a document falls in
//   (Arnav, 04/11/26). Fiscal year variant April-March: the fiscal
//   year of an entry date is the calendar year of (date - 3 months),
//   period 01 = April. Three window start dates are carried as well:
//   first day of the entry month, of its fiscal quarter and of its
//   fiscal year - the frame view ZI_JIB_WINDOW picks the one that fits
//   the granularity, for a date-range filter in the query.
//   Read by ZI_JIB_DOC (the JM documents with venture) and by
//   ZI_JIB_WINDOW (every window in which anything was entered).
//
// CHANGE HISTORY
//   04.11.2026  Arnav Johri  <TR>  Initial development (replaces
//                                  ZI_JIB_PERIOD, which was keyed on
//                                  the posting period)
//----------------------------------------------------------------------
// ASSUMPTION: fiscal year variant April-March for every company code
//   (OVL: posting period 1 = April, confirmed on the PRD sample).
// ASSUMPTION: an initial entry date (00000000) yields period '00'; the
//   frame leaves those out.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBENTRY'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'FI documents with entry-date fiscal window'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_JIB_ENTRY
  as select from bkpf as Doc
{
      @EndUserText.label: 'Company Code'
  key Doc.bukrs                      as CompanyCode,
      @EndUserText.label: 'Document Number'
  key Doc.belnr                      as AccountingDocument,
      @EndUserText.label: 'Fiscal Year'
  key Doc.gjahr                      as FiscalYear,

      @EndUserText.label: 'Document Type'
      Doc.blart                      as DocumentType,
      @EndUserText.label: 'Reversal Document'
      Doc.stblg                      as ReversalDocument,
      @EndUserText.label: 'Entry Date'
      Doc.cpudt                      as EntryDate,
      @EndUserText.label: 'Posting Date'
      Doc.budat                      as PostingDate,

      // -- fiscal window of the entry date (April-March) -----------------
      @EndUserText.label: 'Fiscal Year of Entry'
      cast( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 )
            as abap.numc( 4 ) )      as EntryFiscalYear,

      @EndUserText.label: 'Fiscal Quarter of Entry'
      case substring( Doc.cpudt, 5, 2 )
        when '04' then 'Q1'
        when '05' then 'Q1'
        when '06' then 'Q1'
        when '07' then 'Q2'
        when '08' then 'Q2'
        when '09' then 'Q2'
        when '10' then 'Q3'
        when '11' then 'Q3'
        when '12' then 'Q3'
        else           'Q4'
      end                            as EntryFiscalQuarter,

      @EndUserText.label: 'Fiscal Period of Entry'
      case substring( Doc.cpudt, 5, 2 )
        when '04' then '01'
        when '05' then '02'
        when '06' then '03'
        when '07' then '04'
        when '08' then '05'
        when '09' then '06'
        when '10' then '07'
        when '11' then '08'
        when '12' then '09'
        when '01' then '10'
        when '02' then '11'
        when '03' then '12'
        else           '00'
      end                            as EntryFiscalPeriod,

      // -- first day of the entry month / quarter / fiscal year ----------
      @EndUserText.label: 'Entry Month Start'
      cast( concat( substring( cast( Doc.cpudt as abap.char( 8 ) ), 1, 6 ), '01' )
            as abap.dats )           as EntryMonthStart,

      @EndUserText.label: 'Entry Quarter Start'
      case substring( Doc.cpudt, 5, 2 )
        when '04' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '0401' ) as abap.dats )
        when '05' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '0401' ) as abap.dats )
        when '06' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '0401' ) as abap.dats )
        when '07' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '0701' ) as abap.dats )
        when '08' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '0701' ) as abap.dats )
        when '09' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '0701' ) as abap.dats )
        when '10' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '1001' ) as abap.dats )
        when '11' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '1001' ) as abap.dats )
        when '12' then
          cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                        '1001' ) as abap.dats )
        else
          cast( concat( substring( cast( Doc.cpudt as abap.char( 8 ) ), 1, 4 ), '0101' ) as abap.dats )
      end                            as EntryQuarterStart,

      @EndUserText.label: 'Entry Fiscal Year Start'
      cast( concat( substring( cast( dats_add_months( Doc.cpudt, -3, 'INITIAL' ) as abap.char( 8 ) ), 1, 4 ),
                    '0401' ) as abap.dats )
                                     as EntryFiscalYearStart
}
