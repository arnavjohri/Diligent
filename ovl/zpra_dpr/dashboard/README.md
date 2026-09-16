# DPR Production Dashboard — Fiori Overview Page (OVP)

One tile, one page, six cards, one global filter bar. Backend is package
`ZPR_DPR_RAP` (five OData V2 services `ZDPR_Q_*_CDS`, all active). Nothing in
the backend changes for step 1.

The mockup (`../docs/` — screenshot supplied 16/09/26) is the target layout.

## How this folder ships

`webapp/` holds the files that differ from what the SAP Fiori generator writes.
The app itself is generated in **Business Application Studio** (BAS) and
deployed from there. After generation, overwrite the generated files with the
ones here. Backend objects, if any step needs one, are pasted through ADT as
usual and are listed in the step.

    webapp/manifest.json                     data sources, models, global filter, six cards
    webapp/annotations/annotation_boepd.xml  ZDPR_Q_BOEPD_TREND_CDS  - cards 1 and 5
    webapp/annotations/annotation_perf.xml   ZDPR_Q_PROD_PERF_CDS    - cards 2 and 3
    webapp/annotations/annotation_target.xml ZDPR_Q_TARGET_QUERY_CDS - card 4
    webapp/annotations/annotation_prod.xml   ZDPR_Q_PROD_QUERY_CDS   - card 6
    webapp/i18n/i18n.properties              all card titles

## Status 16/09/26 (evening)
All six cards render in the BAS preview. The senior released backend revision
v16-09 (see `../zdpr_rap/README.md`): BE target now computed like the classic
report (annual TAR_BE ÷ days in FY, ZPRA_T_TAR_CF conversion), readable
ProductionDateText for chart axes, RowLabel in ZDPR_Q_PROD_PERF. The app files
here are already adapted to it: charts on ProductionDateText, card 3 split
into two table cards (YTD / Annual) with RowLabel as first column. They need
the v16-09 backend active; against the older backend cards 1, 3 and 5 would
fail on the missing elements.

Card design decisions forced by the Overview Page:
- A table card shows at most three columns, so card 3 is two tabs (YTD /
  Annual) of three columns each; % Achv is coloured by AchievementCriticality.
- Card 2 cannot show the Excel headline total as one number: an OVP header
  KPI on a plain view shows the first row only, and on the analytical query
  it sums the days. It is a per-day column chart by product group instead;
  the single total needs a TOTAL row in ZDPR_P_PERF_AGG (backend, later).
- Card 4 plots native units (BOPD next to MMSCMD) - a BOE column needs a
  backend measure in ZDPR_C_TARGET_CUBE.
- Card 6 shows OVL share per asset and product summed over the selected
  dates, not the latest day: an analytic query aggregates over the columns
  the card requests.

## Step plan (one step, then confirm, then the next)

| Step | Card (mockup) | Service | What is added | Backend change |
|---|---|---|---|---|
| 1 | Global filter + card 1 "Actual Production vs BE Target (BOEPD)" line chart | ZDPR_Q_PROD_PERF_CDS (filter), ZDPR_Q_BOEPD_TREND_CDS | project, filter bar, card 1 — **this step** | none |
| 2 | Card 2 "Total O+OEG (BOEPD)" KPI header | ZDPR_Q_BOEPD_TREND_CDS or PROD_PERF | KPI card | maybe: a TOTAL row in ZDPR_P_PERF_AGG if the per-day figure must equal Excel |
| 3 | Card 3 "Production Performance" table with % Achv colouring | ZDPR_Q_PROD_PERF_CDS | table card, criticality on AchievementPct | none |
| 4 | Card 4 "Target vs Actual by Product" column chart | ZDPR_Q_TARGET_QUERY_CDS | analytical card, P_TargetCode default TAR_BE | none |
| 5 | Card 5 "Daily Production Trend by Business Unit" | ZDPR_Q_BOEPD_TREND_CDS | line chart, BusinessUnit as series | none |
| 6 | Card 6 "Production Records" table | ZDPR_Q_PROD_QUERY_CDS or BOEPD_TREND | table card | none (columns differ slightly from the mockup — decided at step 6) |
| 7 | Business unit + target code in the filter bar | new | filter bar fields | **yes** — one small classic view `ZDPR_Q_DASH_FILTER` carrying all four parameters plus BusinessUnit, used as the global filter entity |
| 8 | Card navigation "Open detail" | — | intent navigation to the ALP apps, if those get deployed | none |

Why step 7 is separate: the global filter entity set in step 1 is
`ZDPR_Q_PROD_PERFSet`, which carries the three parameters every numeric card
needs (P_DateFrom, P_DateTo, P_FiscalYear) but has no BusinessUnit field, and
no existing query has all four parameters plus BusinessUnit. The filter bar
only offers fields of its own entity, so BU and target code need a filter
entity built for the page.

## Step 1 — generate the project, global filter, card 1

### 1.1 Prerequisites (already documented in the BTP guide)
- Cloud Connector exposes `/sap/opu/odata/` of the S/4 system.
- BTP destination `ZDPR_S4_BACKEND` with `WebIDEEnabled=true`,
  `WebIDEUsage=odata_abap,dev_abap`, `HTML5.DynamicDestination=true`.
- All five services registered in `/IWFND/MAINT_SERVICE` and answering
  `$metadata` (list in the OVP document, section 3).

### 1.2 Generate in BAS
1. Dev space type *SAP Fiori* → *New Project from Template* → *SAP Fiori generator*.
2. Template **Overview Page**, OData V2.
3. Data source: *Connect to a System* → destination `ZDPR_S4_BACKEND` →
   service **ZDPR_Q_PROD_PERF_CDS**. This is the main model and the global
   filter model.
4. Filter entity: pick the **result** entity set of the performance query
   (`ZDPR_Q_PROD_PERFSet` — see check 2 for the exact name).
5. Project attributes: module name `zdprdashboard`, title
   *DPR Production Dashboard*, namespace empty, UI5 version 1.96 or higher,
   *Add deployment configuration* → Cloud Foundry, destination
   `ZDPR_S4_BACKEND`; *Add FLP configuration* → semantic object `DPRDashboard`,
   action `display`.
6. Finish. The generator creates the project with no cards.

### 1.3 Add the other four services
*Application Info* → *Manage Service Models* → *Add Service*, destination
`ZDPR_S4_BACKEND`, one per service. BAS names each data source and model after
the service (`ZDPR_Q_BOEPD_TREND_CDS`, `ZDPR_Q_TARGET_QUERY_CDS`,
`ZDPR_Q_DAILY_TREND_CDS`, `ZDPR_Q_PROD_QUERY_CDS`); `manifest.json` here uses
those names. Metadata lands in `webapp/localService/<service>/metadata.xml`.
URIs are the plain `/sap/opu/odata/sap/<service>/` paths (confirmed 16/09/26).

### 1.4 Merge the repo files in — do not overwrite the generated manifest
The generator's `manifest.json` already has the five data sources and models,
plus the backend-annotation entries it created for each. Keep all of that.
Change only two places:

1. In `sap.app.dataSources`, add the local annotation source
   `boepdAnnotation` (copy the block from the repo manifest) and add
   `"boepdAnnotation"` to the `settings.annotations` array of
   `ZDPR_Q_BOEPD_TREND_CDS` (create the array if the generator made none).
2. Replace the whole `sap.ovp` section with the one from the repo manifest.

Then add `webapp/annotations/annotation_boepd.xml` and replace
`webapp/i18n/i18n.properties` with the repo copies. Keep `Component.js`,
`index.html`, `xs-app.json`, `ui5.yaml`, `localService/**` untouched.

### 1.5 Checks before the first preview
1. **Service URIs**: confirmed plain `/sap/opu/odata/sap/<service>/`, no
   destination prefix. Nothing to change.
2. **Entity set and type names** (the one real assumption in this step). Open
   `/sap/opu/odata/sap/ZDPR_Q_BOEPD_TREND_CDS/$metadata` in the browser and
   confirm:

   Two naming conventions exist in this package (confirmed 16/09/26 from
   the downloaded metadata):

   | View kind | Parameter set | Result set | Result entity type |
   |---|---|---|---|
   | plain view (ZDPR_Q_PROD_PERF) | `ZDPR_Q_PROD_PERF` | `ZDPR_Q_PROD_PERFSet` | `ZDPR_Q_PROD_PERFType` |
   | analytical query (the other four) | `ZDPR_Q_BOEPD_TREND` | `ZDPR_Q_BOEPD_TRENDResults` | `ZDPR_Q_BOEPD_TRENDResult` |

   Schema namespace = service name, uppercase (`ZDPR_Q_BOEPD_TREND_CDS`).
   A wrong `entitySet` in a card shows up as
   `Cannot read properties of null (reading 'entityType')` in
   `Component-dbg.js getPreprocessors` and the card is silently dropped.
3. **Date parameter format**. The SelectionVariant defaults are written as
   `2024-04-01T00:00:00` (Edm.DateTime). If card 1 shows "Cannot load card"
   with an *invalid key predicate* in the network trace, change the two values
   to `20240401` / `20240414` and retry. Once the filter bar supplies the
   dates this default is not used.

### 1.6 Preview — DONE 16/09/26 (card 1 renders, filter bar drives it; target line zero for Sep 2024 = data coverage to check)
*Preview Application* → `start`. The filter bar shows three mandatory fields
(Production date from, to, Fiscal year) coming from the analytical parameters.
Enter 01.04.2024, 14.04.2024, 2024 and *Go*. Card 1 must show two lines: a
moving *Actual Production* and a flat *BE Target*, ascending dates left to
right, header KPI = aggregated actual with red/green against target.

Reply with one of:
- **works** → step 2
- the error text or a screenshot → fixed and re-issued before moving on
- the `$metadata` if check 2 differs → names corrected in this folder

### Notes carried from the handover
- FY 2025-26 targets are not loaded in `ZPRA_T_PRD_TAR`; the target line is
  zero for current dates. Test with FY 2024-25 dates.
- The five backend DDLX are not needed by this page: every chart and table
  annotation the cards use is defined locally in `webapp/annotations/` so the
  page does not depend on whether the manual DDLX creation succeeded.
- Views run with `@AccessControl.authorizationCheck: #NOT_REQUIRED` — no
  row-level restriction on the dashboard.
