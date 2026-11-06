//----------------------------------------------------------------------
// Object    : ZI_JIB_STATUS_CUBE (DDL source, classic view, cube)
// Title     : JIB Status per joint venture, month and document (cube
//             for Custom Analytical Queries)
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx; test
//             feedback Corporate Accounts (K. Sharma), 06/11/26
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 7 of 7 for the Management Dashboard card "JIB Status": the
//   data source the functional consultant picks in the Fiori app Custom
//   Analytical Queries. The layout of the requirement's example:
//     JV | BU | Project Name | Month | Status | Date of JIB Upload |
//     Document Number
//   One row per company code / joint venture / fiscal year / posting
//   period / JIB document. The MONTH is the month the JIB is FOR (the
//   posting period of the document: "JIB for September" = period 06),
//   the DATE is the day that document was entered in the system (BKPF
//   CPUDT: "uploaded on 14.10.2026"), and every document of the month
//   is its own row (four documents for September 2026 = four rows,
//   which the analytical table shows as one merged month with four
//   document numbers). A month with no JIB has exactly one row, Status
//   Pending, no date, no document - including the months still to come
//   in the fiscal year.
//     JibStatus        Uploaded / Pending per venture and month
//     EntryDate        Date of JIB Upload, per document
//     LastEntryDate    latest upload date of the month, on every row
//     AccountingDocument  the document number (navigation target for
//                      the document header dialog: CompanyCode +
//                      AccountingDocument + FiscalYear)
//   Measures: JibDocuments (1 per document row), JibPosted (1 on one
//   row per uploaded venture-month), JibPending (1 on a Pending row),
//   Ventures (1 per venture-month) - summed over a Business Unit or a
//   fiscal year they give "x of n months uploaded".
//   Filters: Fiscal Year alone lists the twelve months; Fiscal Quarter
//   or Posting Period narrow it; Period Start Date for a date range.
//   YEAR AND QUARTER SUMMARY: every row also carries, for its venture,
//   the year's and the quarter's Uploaded / Pending text, last upload
//   date, months uploaded and document count (ZI_JIB_YEAR_AGG,
//   ZI_JIB_QTR_AGG). A query whose rows are JV Code, Project Name,
//   Business Unit and the year summary columns - without Month and
//   Document Number - collapses to one line per venture: the last
//   posting of the year, whichever month it was in.
//   Built as ZI_JIB_VENTURE (the four ventures) x ZI_JIB_PERIOD (the
//   twelve periods of every fiscal year with postings), joined on
//   company code, LEFT OUTER JOIN to ZI_JIB_DOC_AGG (month totals) and
//   to ZI_JIB_DOC (the documents). Annotation set copied from
//   ZI_TR_BANKACCT_CUBE / ZI_BR_BANKREVAL_CUBE (listed by the app after
//   the C1 release). After activation: ADT, Properties, API State, Add
//   Release State, contract Use in Key User Apps (C1).
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development (per posting
//                                  period)
//   03.11.2026  Arnav Johri  <TR>  Business Unit per venture;
//                                  ProjectName and labels as in the
//                                  workbook; PeriodStartDate
//   04.11.2026  Arnav Johri  <TR>  Entry-date windows at three
//                                  granularities (withdrawn 06/11/26:
//                                  the client's example is per JIB
//                                  month - August, November, February
//                                  showed Pending because their JIBs
//                                  were entered in other months)
//   06.11.2026  Arnav Johri  <TR>  Month = posting period again; one
//                                  row per document; all twelve months
//                                  of the fiscal year; Granularity
//                                  removed
//   06.11.2026  Arnav Johri  <TR>  Year and quarter summary columns
//----------------------------------------------------------------------
// ASSUMPTION: Business Unit and ProjectName are the requirement's fixed
//   texts per venture ("shall be a freezed input"; "as mentioned in
//   Excel"): AA2002 ACG and SD2002 Block 5A are MENA & CIS BU, MM2002
//   A1, Myanmar and MM2012 A3, Myanmar are AP BU. The T8JVT text is
//   still exposed as SAP Venture Name.
// ASSUMPTION: fiscal year variant April-March for every company code
//   (OVL: posting period 1 = April, confirmed on the PRD sample).
// ASSUMPTION: a JIB for month X is the JM document whose posting period
//   is X, however late it was entered (the April JIB entered on 15 May
//   is April, Uploaded, 15.05.2026).
// ASSUMPTION: no access control, as on the two earlier cubes. The
//   published query runs with the user's analytics authorisations.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBSTATUSCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB Status per venture, month and document (cube)'
@VDM.viewType: #COMPOSITE
@Analytics.dataCategory: #CUBE
@ObjectModel.modelingPattern: #ANALYTICAL_CUBE
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_PROVIDER,
                                      #CDS_MODELING_DATA_SOURCE,
                                      #CDS_MODELING_ASSOCIATION_TARGET,
                                      #SQL_DATA_SOURCE ]
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType.sizeCategory: #M
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MIXED
define view ZI_JIB_STATUS_CUBE
  as select from ZI_JIB_VENTURE as Venture
    inner join      ZI_JIB_PERIOD  as Period on  Period.CompanyCode = Venture.CompanyCode
    left outer join ZI_JIB_DOC_AGG as Month  on  Month.CompanyCode  = Venture.CompanyCode
                                             and Month.JointVenture = Venture.JointVenture
                                             and Month.FiscalYear   = Period.FiscalYear
                                             and Month.FiscalPeriod = Period.FiscalPeriod
    left outer join ZI_JIB_DOC     as Doc    on  Doc.CompanyCode    = Venture.CompanyCode
                                             and Doc.JointVenture   = Venture.JointVenture
                                             and Doc.FiscalYear     = Period.FiscalYear
                                             and Doc.FiscalPeriod   = Period.FiscalPeriod
    left outer join ZI_JIB_YEAR_AGG as Year  on  Year.CompanyCode   = Venture.CompanyCode
                                             and Year.JointVenture  = Venture.JointVenture
                                             and Year.FiscalYear    = Period.FiscalYear
    left outer join ZI_JIB_QTR_AGG as Qtr    on  Qtr.CompanyCode    = Venture.CompanyCode
                                             and Qtr.JointVenture   = Venture.JointVenture
                                             and Qtr.FiscalYear     = Period.FiscalYear
                                             and Qtr.FiscalQuarter  = Period.FiscalQuarter
  association [0..1] to I_CompanyCode as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
{
      // -- keys ----------------------------------------------------------
      @ObjectModel.foreignKey.association: '_CompanyCode'
      @EndUserText.label: 'Company Code'
  key Venture.CompanyCode,
      @ObjectModel.text.element: ['ProjectName']
      @EndUserText.label: 'JV Code'
  key Venture.JointVenture,
      @EndUserText.label: 'Fiscal Year'
  key Period.FiscalYear,
      @ObjectModel.text.element: ['PeriodMonth']
      @EndUserText.label: 'Posting Period'
  key Period.FiscalPeriod,
      @EndUserText.label: 'Document Number'
  key Doc.AccountingDocument,

      // -- month attributes (fiscal year April-March) --------------------
      @EndUserText.label: 'Month'
      case Period.FiscalPeriod
        when '01' then 'April'
        when '02' then 'May'
        when '03' then 'June'
        when '04' then 'July'
        when '05' then 'August'
        when '06' then 'September'
        when '07' then 'October'
        when '08' then 'November'
        when '09' then 'December'
        when '10' then 'January'
        when '11' then 'February'
        when '12' then 'March'
        else           ' '
      end                                              as PeriodMonth,
      @EndUserText.label: 'Fiscal Quarter'
      Period.FiscalQuarter,
      @EndUserText.label: 'Period Start Date'
      Period.PeriodStartDate,

      // -- venture attributes, texts as in the requirement workbook -------
      @EndUserText.label: 'Project Name'
      case Venture.JointVenture
        when 'AA2002' then 'ACG'
        when 'SD2002' then 'Block 5A'
        when 'MM2002' then 'A1, Myanmar'
        when 'MM2012' then 'A3, Myanmar'
        else               'OTHER'
      end                                              as ProjectName,
      @EndUserText.label: 'SAP Venture Name'
      Venture.JointVentureName,
      @EndUserText.label: 'Venture Type'
      Venture.VentureType,
      @EndUserText.label: 'Business Unit'
      case Venture.JointVenture
        when 'AA2002' then 'MENA & CIS BU'
        when 'SD2002' then 'MENA & CIS BU'
        when 'MM2002' then 'AP BU'
        when 'MM2012' then 'AP BU'
        else               'OTHER'
      end                                              as BusinessUnit,

      // -- JIB status of the month ----------------------------------------
      @EndUserText.label: 'Status'
      case Month.JibPosted
        when 1 then 'Uploaded'
        else        'Pending'
      end                                              as JibStatus,
      @EndUserText.label: 'Last JIB Upload Date'
      Month.LastEntryDate,
      @EndUserText.label: 'Last JIB Posting Date'
      Month.LastPostingDate,

      // -- the document --------------------------------------------------
      @EndUserText.label: 'Date of JIB Upload'
      Doc.EntryDate,
      @EndUserText.label: 'Posting Date'
      Doc.PostingDate,
      @EndUserText.label: 'Document Header Text'
      Doc.DocumentHeaderText,
      @EndUserText.label: 'Reference'
      Doc.Reference,
      @EndUserText.label: 'Entered By'
      Doc.EnteredBy,

      // -- year summary (same value on every row of the venture-year) ----
      @EndUserText.label: 'Year Status'
      case Year.JibPosted
        when 1 then 'Uploaded'
        else        'Pending'
      end                                              as YearStatus,
      @EndUserText.label: 'Last JIB Upload in Fiscal Year'
      Year.LastEntryDate                               as YearLastEntryDate,
      @EndUserText.label: 'Months Uploaded in Fiscal Year'
      Year.MonthsUploaded                              as YearMonthsUploaded,
      @EndUserText.label: 'JIB Documents in Fiscal Year'
      Year.JibDocuments                                as YearJibDocuments,

      // -- quarter summary (same value on every row of the venture-quarter)
      @EndUserText.label: 'Quarter Status'
      case Qtr.JibPosted
        when 1 then 'Uploaded'
        else        'Pending'
      end                                              as QuarterStatus,
      @EndUserText.label: 'Last JIB Upload in Quarter'
      Qtr.LastEntryDate                                as QuarterLastEntryDate,
      @EndUserText.label: 'Months Uploaded in Quarter'
      Qtr.MonthsUploaded                               as QuarterMonthsUploaded,
      @EndUserText.label: 'JIB Documents in Quarter'
      Qtr.JibDocuments                                 as QuarterJibDocuments,

      // -- measures --------------------------------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'JIB Documents'
      coalesce( Doc.One, cast( 0 as abap.int4 ) )      as JibDocuments,
      // 1 on the row of the month's highest document number only, so a
      // venture-month counts once however many documents it has
      @DefaultAggregation: #SUM
      @EndUserText.label: 'JIB Uploaded (1/0)'
      case when Doc.AccountingDocument = Month.LastDocument
           then cast( 1 as abap.int4 )
           else cast( 0 as abap.int4 )
      end                                              as JibPosted,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'JIB Pending (1/0)'
      case Month.JibPosted
        when 1 then cast( 0 as abap.int4 )
        else        cast( 1 as abap.int4 )
      end                                              as JibPending,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Ventures'
      case Month.JibPosted
        when 1 then
          case when Doc.AccountingDocument = Month.LastDocument
               then cast( 1 as abap.int4 )
               else cast( 0 as abap.int4 )
          end
        else cast( 1 as abap.int4 )
      end                                              as Ventures,

      // -- texts -----------------------------------------------------------
      _CompanyCode
}
