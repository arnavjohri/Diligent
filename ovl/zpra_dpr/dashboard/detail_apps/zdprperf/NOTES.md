# zdprperf — List Report on ZDPR_Q_PROD_PERF_CDS (detail app for cards 2 and 3)

Generated in BAS 23/09/26 (Fiori generator, List Report Object Page, OData V2,
entity set ZDPR_Q_PROD_PERFSet, module `zdprperf`, BSP `ZDPRPERF`, intent
`DPRPerformance-display`). `original/` = generator output as supplied 24/09/26.

- `manifest.json`: `filterSettings.dateSettings.useDateRange` true → false.
  The generator's date-range control cannot fill the single-value Edm.DateTime
  analytical parameters P_DateFrom / P_DateTo; console showed
  `Wrong parameters defined for filter` and the page never loaded.
  ASSUMPTION 24/09/26: this is the spinner's cause; confirmed only when the
  standalone preview renders after the change.
