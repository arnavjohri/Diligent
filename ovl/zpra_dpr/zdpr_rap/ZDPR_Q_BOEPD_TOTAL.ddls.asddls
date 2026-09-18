@AbapCatalog.sqlViewName: 'ZDPRQBOEPDTOTAL'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DPR BOEPD Total - Actual vs BE Target, by date only'
@Metadata.ignorePropagatedAnnotations: true

/* ── Card 1 of the dashboard: company-wide Actual vs BE Target per date ─────
 * The Overview Page applies a global-filter field to every card whose entity
 * type has a property of the same name, and offers no per-card opt-out. Card 1
 * must stay a company total driven by the date range only, while card 5 (same
 * source, ZDPR_Q_BOEPD_TREND) must react to Asset / Business Unit / Product.
 * So card 1 gets this query: the same cube, the same two lines, but NO
 * dimension elements - nothing for Asset, BusinessUnit, Block or Product in
 * the filter bar to match. Only P_DateFrom / P_DateTo reach it (by name).
 * Same 'OTHER' screen as ZDPR_Q_BOEPD_TREND, so both cards net the same total.
 * Service ZDPR_Q_BOEPD_TOTAL_CDS: result set ZDPR_Q_BOEPD_TOTALResults,
 * type ZDPR_Q_BOEPD_TOTALResult (analytical-query naming, as for BOEPD_TREND).
 * Created by Arnav on 17/09/26.
 * ─────────────────────────────────────────────────────────────────────────── */
@Analytics.query: true
@OData.publish: true
@Metadata.allowExtensions: true

define view ZDPR_Q_BOEPD_TOTAL
  with parameters
    P_DateFrom : datum,
    P_DateTo   : datum

  as select from ZDPR_C_BOEPD_DAY

{
  /* ── X-axis ─────────────────────────────────────────────────────────── */
  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #HIDE
  ProductionDate,

  /* chart category axis: readable YYYY-MM-DD text of the date */
  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #HIDE
  @EndUserText.label: 'Date'
  ProductionDateText,

  /* ── Chart series (Y-axis) ──────────────────────────────────────────── */
  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'Actual Production (BOEPD)'
  ActualBoepdOvl,

  @AnalyticsDetails.query.axis: #COLUMNS
  @EndUserText.label: 'BE Target (BOEPD)'
  TargetBoepd
}
where ProductionDate >= $parameters.P_DateFrom
  and ProductionDate <= $parameters.P_DateTo
  and BusinessUnit <> 'OTHER'   /* screen out test/garbage asset codes */
