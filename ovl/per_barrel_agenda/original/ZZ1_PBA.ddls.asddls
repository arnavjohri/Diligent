@AbapCatalog.sqlViewName : 'ZZ1_S370PML0P5P2'
@Analytics.query: true

@ObjectModel.modelingPattern: #ANALYTICAL_QUERY
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_QUERY ]

@EndUserText.label: 'Per Barrel Analysis Report'
@OData.publish: true



define view ZZ1_PBA as select from ZI_PBA_CUBE
{ @AnalyticsDetails.query.axis:#ROWS
  @AnalyticsDetails.query.display: #TEXT
  Product,

  @AnalyticsDetails.query.axis:#COLUMNS
  @AnalyticsDetails.query.display: #TEXT


  FiscalYearName,
@AnalyticsDetails.query.axis:#COLUMNS
@Consumption.filter :{ selectionType: #SINGLE, multipleSelections: true, mandatory: false }

  ReportingPeriod,
@AnalyticsDetails.query.axis:#ROWS
  ReportRow,
  @AnalyticsDetails.query.axis:#ROWS
  ReportRowNumber,
  @Consumption.hidden : true
  ProductionCostAmount,
    @Consumption.hidden : true
    RevenueAmount,

    @Consumption.hidden : true
    RoyaltyAmount,
  @Consumption.hidden : true
  TransportAmount,
  @Consumption.hidden : true
  SurveyAmount,
  @Consumption.hidden : true
  DdaAmount,
  @Consumption.hidden : true
  ProductionQuantity,
  @Consumption.hidden : true
  SalesQuantityNet,
  @AnalyticsDetails.query.axis:#COLUMNS
  ReportingPeriodNumber,
@AnalyticsDetails.query.axis:#COLUMNS
  @Consumption.filter :{ selectionType: #SINGLE, multipleSelections: true, mandatory: false }

  FiscalYear,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: 'NDIV0 ( $projection.RevenueAmount / $projection.SalesQuantityNet )'
  @EndUserText.label: 'Realised Price'

  0 as RealisedPrice,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: 'NDIV0 ( $projection.ProductionCostAmount / $projection.ProductionQuantity )'
  @EndUserText.label: 'Production Cost per Unit'
  0 as ProductionCostperUnit,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: 'NDIV0 ( $projection.RoyaltyAmount / $projection.ProductionQuantity )'
  @EndUserText.label: 'Royalty per Unit'
  0 as RoyaltyperUnit,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: 'NDIV0 ( $projection.TransportAmount / $projection.SalesQuantityNet )'
  @EndUserText.label: 'Transportation per Unit'
  0 as TransportationperUnit,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: 'NDIV0 ( $projection.DdaAmount / $projection.ProductionQuantity )'
  @EndUserText.label: 'DD&A per Unit'
  0 as DDAperUnit,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: 'NDIV0 ( $projection.SurveyAmount / $projection.ProductionQuantity )'
  @EndUserText.label: 'Survey per Unit'
  0 as SurveyperUnit,
  @Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: '$projection.ProductionCostperUnit + $projection.RoyaltyperUnit + $projection.TransportationperUnit + $projection.DDAperUnit + $projection.SurveyperUnit'
  @EndUserText.label: 'Cost of Goods Sold'
  0 as CostofGoodsSold,
@Aggregation.default: #FORMULA
  @AnalyticsDetails.query.formula: '$projection.RealisedPrice - $projection.CostofGoodsSold'
  @EndUserText.label: 'Profit'
  0 as Profit


}
 where
 (
	ReportRowNumber between '01' and '16'
 )
