# zdprtrend — Analytical List Page on ZDPR_Q_BOEPD_TREND_CDS (detail app for cards 1 and 5)

Generated in BAS 23/09/26 (Fiori generator, ALP, OData V2, module `zdprtrend`,
BSP `ZDPRTREND`, intent `DPRTrend-display`). Only files that differ from the
generator output live here; `original/` is the generator's version.

- `annotation.xml` → `webapp/annotations/annotation.xml`: local UI.Chart
  (`#BoepdVsTarget` and default) with Dimension/MeasureAttributes. Backend DDLX
  had neither, and its presentation variant pointed at a non-existent default
  chart. The proper fix is the corrected DDLX in `../../../zdpr_rap/
  ZDPR_Q_BOEPD_TREND.ddlx.asddlx`; once that is active this local file can go
  back to the generator's empty version.
- ALP filter bar opened in visual-filter mode (empty): set
  `"defaultFilterMode": "compact"` and `"hideVisualFilter": true` in the page
  component settings of `manifest.json` (advised 23/09/26, not filed here).
