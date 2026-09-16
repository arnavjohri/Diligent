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

    webapp/manifest.json                    data sources, models, global filter, cards
    webapp/annotations/annotation_boepd.xml local annotations for ZDPR_Q_BOEPD_TREND_CDS
    webapp/i18n/i18n.properties             all card titles

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

### 1.3 Add the second service
*Application Info* → *Add Data Source* (or *Application Modeler → Data Sources
→ Add*): destination `ZDPR_S4_BACKEND`, service **ZDPR_Q_BOEPD_TREND_CDS**,
data source name `boepd`, model name `boepd`. This also downloads its metadata
to `webapp/localService/boepd/metadata.xml` and adds an entry in `xs-app.json`.

The other three services (`target`, `daily`, `prod`) are already declared in
`manifest.json` here so later steps only add cards. Either add them the same
way now (recommended, so the local metadata files exist), or delete the three
entries from `dataSources` and `models` until their step.

### 1.4 Copy the files from this folder
Overwrite the generated `webapp/manifest.json`, add
`webapp/annotations/annotation_boepd.xml`, replace `webapp/i18n/i18n.properties`.
Keep the generated `Component.js`, `index.html`, `xs-app.json`, `ui5.yaml`,
`localService/**` untouched.

### 1.5 Checks before the first preview
1. **Service URIs**: `manifest.json` data-source `uri` values are the on-prem
   paths. The generator may rewrite them to the destination-prefixed form
   (`/ZDPR_S4_BACKEND/sap/opu/odata/...`) depending on the `xs-app.json`
   routing it generated. Whatever the generator wrote for `mainService`, apply
   the same prefix to the other four.
2. **Entity set and type names** (the one real assumption in this step). Open
   `/sap/opu/odata/sap/ZDPR_Q_BOEPD_TREND_CDS/$metadata` in the browser and
   confirm:

   | Expected | Where used |
   |---|---|
   | entity set `ZDPR_Q_BOEPD_TRENDSet` (result rows) | manifest card01 `entitySet` |
   | entity type `ZDPR_Q_BOEPD_TREND_CDS.ZDPR_Q_BOEPD_TRENDType` (namespace = service name, uppercase, confirmed 16/09/26) | annotation `Target=` |
   | entity set `ZDPR_Q_PROD_PERFSet` | manifest `globalFilterEntitySet` |
   | parameter set `ZDPR_Q_BOEPD_TREND` with navigation `Set` | not referenced, informational |

   If the system named them `...Results` / `Results`, change the three names.
   Nothing else depends on it.
3. **Date parameter format**. The SelectionVariant defaults are written as
   `2024-04-01T00:00:00` (Edm.DateTime). If card 1 shows "Cannot load card"
   with an *invalid key predicate* in the network trace, change the two values
   to `20240401` / `20240414` and retry. Once the filter bar supplies the
   dates this default is not used.

### 1.6 Preview
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
