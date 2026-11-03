//----------------------------------------------------------------------
// Object    : ZI_JIB_STATUS_CUBE (DDL source, classic view, cube)
// Title     : JIB Status per joint venture and period (cube for
//             Custom Analytical Queries)
// Project   : OVL                                   Module: FI-JVA
// Source    : Management_Dashboard_-_JIB_Status_-_Final.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 4 of 4 for the Management Dashboard card "JIB Status": the
//   data source the functional consultant picks in the Fiori app Custom
//   Analytical Queries. One row per company code / joint venture /
//   fiscal year / posting period:
//     JibStatus      Uploaded when a JM document with that venture on
//                    its lines is posted in the period, else Pending
//     LastEntryDate  BKPF-CPUDT of the latest such document - the date
//                    the dashboard shows next to Uploaded
//     JibDocuments   number of JM documents (measure)
//     JibPosted /    0 or 1 per row (measures) - summed over a Business
//     JibPending     Unit they give "x ventures uploaded, y pending"
//     Ventures       1 per row - the denominator
//   Built as ZI_JIB_VENTURE (venture master) x ZI_JIB_PERIOD (periods
//   with postings), joined on company code, LEFT OUTER JOIN to
//   ZI_JIB_DOC_AGG (the JM documents). Status and the 0/1 measures
//   come from a CASE on the joined JibPosted column (NULL on a Pending
//   row falls into ELSE) and coalesce( ..., 0 ) for the counts.
//   Annotation set copied from ZI_TR_BANKACCT_CUBE / ZI_BR_BANKREVAL_CUBE
//   (listed by the app on 02/11/26 after the C1 release). After
//   activation: ADT, Properties, API State, Add Release State, contract
//   Use in Key User Apps (C1) - without it the app does not list the
//   cube. Check: RSRTS_ODP_DIS on 2CZIJIBSTATUSCUBE.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//   03.11.2026  Arnav Johri  <TR>  Business Unit per venture (was: by
//                                  prefix); VenturePrefix dropped
//   03.11.2026  Arnav Johri  <TR>  ProjectName and labels as in the
//                                  workbook; PeriodStartDate for a
//                                  date-range filter
//----------------------------------------------------------------------
// ASSUMPTION: ProjectName is the workbook's text per venture (ACG,
//   Block 5A, A1 Myanmar, A3 Myanmar), not the T8JVT description, which
//   is still exposed as SAP Venture Name. The requirement asked for the
//   names "as mentioned in Excel".
// ASSUMPTION: Date = BKPF-CPUDT, the day the JIB document was entered
//   in the system (a JIB uploaded today shows today's date). For a
//   document parked on one day and posted with FBV0 on a later day the
//   field may hold the parking day - to be confirmed on one such
//   document in PRD.
// ASSUMPTION: Business Unit is the requirement's fixed attribute per
//   venture ("shall be a freezed input"): AA2002 ACG and SD2002 Block 5A
//   are MENA & CIS BU, MM2002 A1 and MM2012 A3 are AP BU. A venture
//   outside the list (none reach the cube today - ZI_JIB_VENTURE scopes
//   it) would show OTHER.
// ASSUMPTION: fiscal year variant April-March for every company code
//   (OVL: posting period 1 = April, confirmed on the PRD sample).
//   PeriodMonth and FiscalQuarter are literal CASEs on that variant.
// ASSUMPTION: no access control, as on the two earlier cubes. The
//   published query runs with the user's analytics authorisations.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIJIBSTATUSCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'JIB Status per venture and period (cube)'
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
    left outer join ZI_JIB_DOC_AGG as Jib    on  Jib.CompanyCode  = Venture.CompanyCode
                                             and Jib.JointVenture = Venture.JointVenture
                                             and Jib.FiscalYear   = Period.FiscalYear
                                             and Jib.FiscalPeriod = Period.FiscalPeriod
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
      @EndUserText.label: 'Posting Period'
  key Period.FiscalPeriod,

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

      // -- period attributes (fiscal year variant April-March) -----------
      @EndUserText.label: 'Period Start Date'
      Period.PeriodStartDate,
      @EndUserText.label: 'Period Month'
      case Period.FiscalPeriod
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
        else           '???'
      end                                              as PeriodMonth,
      @EndUserText.label: 'Fiscal Quarter'
      case Period.FiscalPeriod
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
      end                                              as FiscalQuarter,

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
