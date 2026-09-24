# zdprtarget — Analytical List Page on ZDPR_Q_TARGET_QUERY_CDS (detail app for card 4)

Generated in BAS 23/09/26 (Fiori generator, ALP, OData V2, main entity
ZDPR_Q_TARGET_QUERYResults, module `zdprtarget`, BSP `ZDPRTARGET`, intent
`DPRTarget-display`). Only the files that differ from the generator output live
here; `original/` holds the generator's version as supplied.

- `annotation.xml` → `webapp/annotations/annotation.xml`. Adds a default
  `UI.Chart` (no qualifier) with Dimension/MeasureAttributes. Reason: the backend
  presentation variant references `@UI.Chart` without qualifier while the backend
  only ships `UI.Chart#ActualVsTarget`; navigating in from the dashboard card
  applies that presentation variant and crashed the SmartChart
  (`Cannot read properties of undefined (reading 'FiscalPeriod')` in
  `ChartProvider._getRole`). Standalone the page used the manifest qualifier and
  was fine.
- `manifest.json` (24/09/26): `defaultFilterMode: compact`, `hideVisualFilter: true`
  in the page settings; the ALP opened in the empty visual-filter mode.
- `annotation.xml` is superseded by DDLX `ZDPR_Q_TARGET_QUERY` (chart on
  AchievementPct); in BAS restore the generator's empty file so the local copy
  does not override the backend chart.
