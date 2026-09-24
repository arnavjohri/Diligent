
@AbapCatalog.sqlViewName: 'ZDPRQTARGETQRY'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DPR Target vs Actual Query'
@Metadata.ignorePropagatedAnnotations: true

@Analytics.query: true
@OData.publish: true
@Metadata.allowExtensions: true

/* Target vs actual per fiscal period, asset and product.
   Analytical query: single cube data source, no joins, no expressions -
   the join and all calculations are in ZDPR_C_TARGET_CUBE. The target
   code parameter is passed through to the cube. */
define view ZDPR_Q_TARGET_QUERY
  with parameters
    P_FiscalYear : gjahr,
    P_TargetCode : char10

  as select from ZDPR_C_TARGET_CUBE( P_TargetCode: $parameters.P_TargetCode )

{
  /* ── Row dimensions ─────────────────────────────────────────────────── */
  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #SHOW
  FiscalPeriod,

  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #SHOW
  Product,

  @AnalyticsDetails.query.axis: #ROWS
  ProductDescription,

  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #SHOW
  Asset,

  @AnalyticsDetails.query.axis: #ROWS
  AssetDescription,

  /* ── Free (filter) dimensions ───────────────────────────────────────── */
  @AnalyticsDetails.query.axis: #FREE
  FiscalYear,

  @AnalyticsDetails.query.axis: #FREE
  Block,

  @AnalyticsDetails.query.axis: #FREE
  VolumeType,

  @AnalyticsDetails.query.axis: #FREE
  VolumeTypeDescription,

  @AnalyticsDetails.query.axis: #FREE
  TargetCode,

  @AnalyticsDetails.query.axis: #FREE
  TargetTypeDescription,

  /* ── Column measures ────────────────────────────────────────────────── */
  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Actual Production'
  ActualQty,
  ActualUom,

  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Target Quantity'
  TargetQty,
  TargetUom,

  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Variance (Actual - Target)'
  VarianceQty,

  /* FORMULA: evaluated by the analytic engine after aggregation, so every
     level shows actual-of-sums / target-of-sums. Float casts because a
     classic view allows '/' for floats only. */
  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Achievement %'
  @Aggregation.default: #FORMULA
  cast( ActualQty as abap.fltp ) * cast( 100 as abap.fltp )
    / cast( TargetQty as abap.fltp )                 as AchievementPct,

  // BOC By Arnav on 24/09/26
  /* Chart copies of the two quantities. ActualQty / TargetQty carry a unit
     property (BOPD for oil, MMSCMD for gas) and the SmartChart of the
     Analytical List Page refuses to draw measures whose unit differs across
     the result. A FORMULA element is evaluated after aggregation and carries
     no unit, so the chart can show one column pair per product in its native
     unit, as dashboard card 4 does. Float casts: classic view rule. */
  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Actual (native unit)'
  @Aggregation.default: #FORMULA
  cast( ActualQty as abap.fltp )                     as ActualQtyChart,

  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Target (native unit)'
  @Aggregation.default: #FORMULA
  cast( TargetQty as abap.fltp )                     as TargetQtyChart
  // EOC By Arnav on 24/09/26
}
