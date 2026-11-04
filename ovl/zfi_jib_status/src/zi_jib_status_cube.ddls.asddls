//----------------------------------------------------------------------
// Object    : ZI_JIB_STATUS_CUBE (DDL source, classic view, cube)
// Title     : JIB Status per joint venture and entry window (cube for
//             Custom Analytical Queries)
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 6 of 6 for the Management Dashboard card "JIB Status": the
//   data source the functional consultant picks in the Fiori app Custom
//   Analytical Queries. One row per company code / joint venture /
//   granularity / window, where a window is a fiscal year (Y), a fiscal
//   quarter (Q) or a period (M) of the ENTRY date of the JIB documents:
//     JibStatus      Uploaded when at least one JM document with that
//                    venture was entered in the window, else Pending
//     LastEntryDate  BKPF-CPUDT of the latest such document - the day
//                    it was posted into the system; a JIB uploaded
//                    today shows today's date. Blank when Pending
//     JibDocuments   number of JIB documents entered in the window
//     JibPosted /    0 or 1 per row (measures) - summed over a Business
//     JibPending     Unit they give "x ventures uploaded, y pending"
//     Ventures       1 per row - the denominator
//   A query ALWAYS filters Granularity (Y, Q or M) and then the window:
//   Fiscal Year 2026 at Y gives one row per venture with its last JIB
//   entered in that fiscal year; Granularity M with period 02 gives the
//   same for May. Without the Granularity filter every venture appears
//   three times and the measures triple.
//   Built as ZI_JIB_VENTURE (the four ventures) x ZI_JIB_WINDOW (entry
//   windows with postings), joined on company code, LEFT OUTER JOIN to
//   ZI_JIB_DOC_AGG (latest JIB entry per venture and window). Status
//   and the 0/1 measures come from a CASE on the joined JibPosted
//   column (NULL on a Pending row falls into ELSE) and coalesce( .., 0 )
//   for the counts. Annotation set copied from ZI_TR_BANKACCT_CUBE /
//   ZI_BR_BANKREVAL_CUBE (listed by the app on 02/11/26 after the C1
//   release). After activation: ADT, Properties, API State, Add Release
//   State, contract Use in Key User Apps (C1) - without it the app
//   does not list the cube. Check: RSRTS_ODP_DIS on 2CZIJIBSTATUSCUBE.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development (per posting
//                                  period)
//   03.11.2026  Arnav Johri  <TR>  Business Unit per venture;
//                                  ProjectName and labels as in the
//                                  workbook; PeriodStartDate
//   04.11.2026  Arnav Johri  <TR>  Windows by ENTRY date at three
//                                  granularities (Y / Q / M), one row
//                                  per venture and window
//----------------------------------------------------------------------
// ASSUMPTION: Business Unit and ProjectName are the requirement's fixed
//   texts per venture ("shall be a freezed input"; "as mentioned in
//   Excel"): AA2002 ACG and SD2002 Block 5A are MENA & CIS BU, MM2002
//   A1, Myanmar and MM2012 A3, Myanmar are AP BU. The T8JVT text is
//   still exposed as SAP Venture Name.
// ASSUMPTION: fiscal year variant April-March for every company code
//   (OVL: posting period 1 = April, confirmed on the PRD sample).
// ASSUMPTION: Date = BKPF-CPUDT, the day the JIB document was entered.
//   For a document parked on one day and posted with FBV0 on a later
//   day the field may hold the parking day - to be confirmed on one
//   such document in PRD.
// ASSUMPTION: no access control, as on the two earlier cubes. The
//   published query runs with the user's analytics authorisations.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBSTATUSCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB Status per venture and entry window (cube)'
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
    inner join      ZI_JIB_WINDOW  as Window on  Window.CompanyCode = Venture.CompanyCode
    left outer join ZI_JIB_DOC_AGG as Jib    on  Jib.CompanyCode   = Venture.CompanyCode
                                             and Jib.JointVenture  = Venture.JointVenture
                                             and Jib.Granularity   = Window.Granularity
                                             and Jib.FiscalYear    = Window.FiscalYear
                                             and Jib.FiscalQuarter = Window.FiscalQuarter
                                             and Jib.FiscalPeriod  = Window.FiscalPeriod
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
      @ObjectModel.text.element: ['GranularityText']
      @EndUserText.label: 'Granularity'
  key Window.Granularity,
      @EndUserText.label: 'Fiscal Year'
  key Window.FiscalYear,
      @EndUserText.label: 'Fiscal Quarter'
  key Window.FiscalQuarter,
      @EndUserText.label: 'Fiscal Period'
  key Window.FiscalPeriod,

      // -- window attributes (entry date, fiscal year April-March) -------
      @EndUserText.label: 'Granularity Text'
      case Window.Granularity
        when 'Y' then 'Fiscal Year'
        when 'Q' then 'Quarter'
        else         'Month'
      end                                              as GranularityText,
      @EndUserText.label: 'Period Start Date'
      Window.PeriodStartDate,
      @EndUserText.label: 'Month'
      case Window.FiscalPeriod
        when '01' then 'Apr'
        when '02' then 'May'
        when '03' then 'Jun'
        when '04' then 'Jul'
        when '05' then 'Aug'
        when '06' then 'Sep'
        when '07' then 'Oct'
        when '08' then 'Nov'
        when '09' then 'Dec'
        when '10' then 'Jan'
        when '11' then 'Feb'
        when '12' then 'Mar'
        else           ' '
      end                                              as PeriodMonth,

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

      // -- JIB status ------------------------------------------------------
      @EndUserText.label: 'Status'
      case Jib.JibPosted
        when 1 then 'Uploaded'
        else        'Pending'
      end                                              as JibStatus,
      @EndUserText.label: 'Date'
      Jib.LastEntryDate,
      @EndUserText.label: 'Last JIB Posting Date'
      Jib.LastPostingDate,

      // -- measures --------------------------------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'JIB Documents'
      coalesce( Jib.JibDocuments, cast( 0 as abap.int4 ) ) as JibDocuments,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'JIB Uploaded (1/0)'
      coalesce( Jib.JibPosted, cast( 0 as abap.int4 ) )    as JibPosted,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'JIB Pending (1/0)'
      case Jib.JibPosted
        when 1 then cast( 0 as abap.int4 )
        else        cast( 1 as abap.int4 )
      end                                              as JibPending,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Ventures'
      cast( 1 as abap.int4 )                           as Ventures,

      // -- texts -----------------------------------------------------------
      _CompanyCode
}
