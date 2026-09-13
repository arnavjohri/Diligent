# Review — "ZDPR_RAP_Manual_ADT_Objects.docx" (DPR Analytical RAP, manual ADT objects)

Reviewed 13/09/26 against `ovl/zpra_dpr/rap-app/` and the two build guides already in
`docs/`. The document asks a developer to hand-create 5 metadata extensions (DDLX) and
1 service binding in ADT. Nothing in it can be executed as written — the object names it
uses do not exist in this repo.

## Blockers — resolve before anyone opens ADT

### B1. Every object name in the document is wrong (or the repo is)

The document uses `ZDPR_*` in package `ZPR_DPR_RAP`. The repo, and both existing build
guides (`ZPRA_DPR_Analytical_RAP_ADT_Build_Guide.docx`,
`..._FULL.docx`), use `ZPRA_*_DPR_*` in package `ZPRA_DPR`. Not one `ZDPR_` name appears
anywhere in this repository.

| Document | Repo / existing guides |
|---|---|
| `ZDPR_Q_BOEPD_TREND`  | `ZPRA_Q_DPR_BOEPD_TREND` |
| `ZDPR_Q_PROD_PERF`    | `ZPRA_Q_DPR_PROD_PERF` |
| `ZDPR_Q_DAILY_TREND`  | `ZPRA_Q_DPR_DAILY_TREND` |
| `ZDPR_Q_PROD_QUERY`   | `ZPRA_Q_DPR_PROD_QUERY` |
| `ZDPR_Q_TARGET_QUERY` | `ZPRA_Q_DPR_TARGET_QUERY` |
| `ZDPR_SD_ANALYTICS`   | `ZPRA_SD_DPR_ANALYTICS` |
| `ZDPR_SB_ANALYTICS_O4`| `ZPRA_SB_DPR_ANALYTICS_O4` |
| `ZDPR_C_BOEPD_DAY` / `ZDPR_C_PROD_CUBE` | `ZPRA_C_DPR_BOEPD_DAY` / `ZPRA_C_DPR_CUBE` |
| `ZDPR_P_PERF_AGG`     | `ZPRA_P_DPR_PERF_AGG` |
| `ZDPR_I_EXCEL_DL`     | `ZPRA_I_DPR_EXCEL_DL` |
| `ZBP_ZDPR_EXCEL_DL` / `ZCL_ZDPR_EXCEL` / `ZCL_ZDPR_PDF` | `ZBP_ZPRA_DPR_EXCEL_DL` / `ZCL_ZPRA_DPR_EXCEL` / `ZCL_ZPRA_DPR_PDF` |
| Package `ZPR_DPR_RAP` | Package `ZPRA_DPR` |

The document is internally inconsistent on this: §6.1 names the target table
`ZPRA_T_PRD_TAR` (ZPRA prefix) while every object around it is `ZDPR_`.

A DDLX name must equal the annotated view's name exactly. Get one naming set confirmed
from the system before anything else — everything below assumes it is settled.

### B2. `@Metadata.allowExtensions: true` is never mentioned

A metadata extension cannot activate unless the annotated view carries
`@Metadata.allowExtensions: true`. §2 "Prerequisites" does not list it; §3.2's
troubleshooting does not mention it either. This is the most common DDLX activation
failure and it is silent in the document.

All five views in `rap-app/` do carry it. If the system's views were built from the
`ZDPR_*` sources instead, it must be checked on each of the five before creating any
extension.

### B3. The chart will not render — the presentation variant does not point at the chart

In all five sources the document declares a qualified chart but an unqualified
visualization:

```
@UI.chart: [{ qualifier: 'BoepdVsTarget', ... }]
@UI.presentationVariant: [{ visualizations: [ { type: #AS_CHART }, { type: #AS_LINEITEM } ] }]
```

`#AS_CHART` with no qualifier resolves to the annotation path `@UI.Chart` (unqualified),
which does not exist — the only chart is `@UI.Chart#BoepdVsTarget`. The extension
activates, and §6.3's promised graph does not appear.

The versions in `rap-app/*.ddlx.asddlx` are correct:
`{ type: #AS_CHART, qualifier: 'BoepdVsTarget' }`. Either carry the qualifier onto the
visualization, or drop it from `@UI.chart`.

### B4. A chart needs an aggregatable entity — these queries are plain views

`rap-app/README.md` and the header comment in `ZPRA_Q_DPR_PROD_QUERY.ddls.asddls` record
that the analytical queries were deliberately converted away from `@Analytics.query`,
because an analytical entity is not exposable through an OData V4 - UI service binding on
this release. A plain view entity publishes without `Aggregation.ApplySupported`, so Fiori
Elements renders a List Report — and a V4 List Report does not draw `@UI.chart`; the
Analytical List Page floorplan that does draw it requires the aggregatable entity.

So §6.3 ("the line chart appears automatically") is very likely not achievable by the five
extensions alone on this release. Check after publishing: open
`<service-url>$metadata` and search for `Aggregation.ApplySupported` on `DPRBoepdTrend`.
If it is absent, the table and filter bar will render and the chart will not.

This needs settling before the document goes to a developer, because the chart is the
whole point of the exercise.

## Errors to correct in the document

### E1. §5.2 entity-set table is wrong on five rows

`ZPRA_SD_DPR_ANALYTICS` exposes nine entities. The table lists eight, of which two do not
exist and three real ones are missing.

| §5.2 row | Reality |
|---|---|
| `DPRBoepdDayCube` (`ZDPR_C_BOEPD_DAY`) | **not exposed** — cubes are deliberately not in the service definition |
| `DPRProductionCube` (`ZDPR_C_PROD_CUBE`) | **not exposed** — same reason |
| — | missing: `DPRDailyProduction` (`ZPRA_I_DPR_DAILY`) |
| — | missing: `DPRMonthlyProduction` (`ZPRA_I_DPR_MONTHLY`) |
| — | missing: `DPRProductionTargets` (`ZPRA_I_DPR_TARGET`) |

A developer checking the published binding against this table will conclude the publish
failed.

### E2. §5.2 service URL is wrong

Document: `/sap/opu/odata4/sap/zdpr_analytics/srvd/sap/zdpr_sd_analytics/0001/`

The first path segment is the **service binding** name, not an invented group name. With
the repo naming it is:

`/sap/opu/odata4/sap/zpra_sb_dpr_analytics_o4/srvd/sap/zpra_sd_dpr_analytics/0001/`

### E3. §2.1 — SE03 route does not do what the text says

"SE03 → Object Directory → Change Object Directory Entries → delete the entry
R3TR BDEF ..." changes the directory entry; it is not an object deletion. Removing the
TADIR row while the runtime object survives leaves the system in a worse state than the
orphan it is meant to clear.

Use the ADT route only (right-click the behavior definition → Delete, same TR). If the
BDEF is genuinely gone and only a stale TADIR row remains, that is a Basis call, not a
developer step.

Related: `rap-app/ZPRA_BP_DPR_EXCEL_DL.bdef.asbdef` is misnamed. A behavior definition's
object name is always its root entity name, so this object is `ZPRA_I_DPR_EXCEL_DL`
(its own body says `define behavior for ZPRA_I_DPR_EXCEL_DL`). abapGit takes the object
name from the filename, so as committed it would try to create a BDEF called
`ZPRA_BP_DPR_EXCEL_DL` — a plausible source of the §2.1 orphan. Rename the file to
`ZPRA_I_DPR_EXCEL_DL.bdef.asbdef`.

### E4. §1 "18 objects imported successfully via abapGit" is unverified and doubtful

`ovl/zpra_dpr/rap-app/` contains **no** abapGit metadata at all — no `.abapgit.xml`, no
`package.devc.xml`, no per-object `*.xml`. It is plain source, not a serialised abapGit
repository, so it is not what was pulled. Separately, CLAUDE.md records that hand-written
abapGit XML has never imported successfully on this landscape (`kpmg/zfi_tds_cl34`, four
attempts, `XML_FORMAT_ERROR`), and `ovl/ztest_t001` was advertised as a working pilot but
never actually imported.

Confirm the 18 objects really are active in the system (ADT: open the package, check for
error markers) before accepting the document's premise that only six objects remain.

### E5. §1 diagnosis of the DDLX import failure is probably wrong

"Malformed 'annotate' statement" is blamed on "the abapGit DDLX handler in this system".
More likely causes, in order:

1. The DDLX was serialised with the wrong extension. abapGit needs
   `<NAME>.ddlx.asddlx` **plus** `<NAME>.ddlx.xml`. If the source landed as `.ddls.asddls`
   it is created as a DDL source, where `annotate view` is illegal — which is exactly this
   message.
2. Hand-written `DDLX` XML with elements out of structure order — the `CALL TRANSFORMATION
   id` failure mode already documented in CLAUDE.md.

Neither is a reason to abandon abapGit for DDLX, and neither is fixed by retyping the
source in ADT.

## Content dropped versus the repo sources

The document's five sources are cut-down versions of `rap-app/*.ddlx.asddlx`. §3.2 frames
this as "only classic, widely supported annotations", but the cuts are not cosmetic:

| Dropped | Effect |
|---|---|
| `measureAttributes` / `dimensionAttributes` on every chart | no `#CATEGORY` / `#SERIES` / `#AXIS_1` roles — the chart library has nothing to lay the axes out from |
| `sortOrder` on every presentation variant | the tab-2 line chart plots dates in arbitrary order |
| `criticality: 'AchievementCriticality'` (PROD_PERF) | traffic-light colouring on % achievement is lost, and `AchievementCriticality` in `ZPRA_Q_DPR_PROD_PERF` becomes dead |
| second/third chart qualifiers (`ProductMix`, `OvlShareArea`, `JvVsOvl`, `ByAsset`, `AchievementByAsset`, `VarianceByPeriod`) | one chart per entity instead of three |
| `typeNamePlural` plurals | cosmetic |

One change goes the other way and is an improvement: 4.1 adds
`@UI.lineItem: [{ position: 10, ... label: 'Production Date' }]` on `ProductionDate`. The
repo version has no date column in the BOEPD table at all (its line items start at 20) —
carry that back into `rap-app/ZPRA_Q_DPR_BOEPD_TREND.ddlx.asddlx`.

**Recommendation: paste the `rap-app/*.ddlx.asddlx` sources, renamed to whatever B1
settles on, rather than the document's §4 sources.** They are the release-adapted versions
and they do not carry B3.

`@Metadata.layer: #CUSTOMER` (document) vs `#CORE` (repo): both activate. Pick one and use
it on all five — two DDLX for the same view in different layers is a future merge problem.

## Field names — checked, all valid

Every element named in the document's five sources exists in the corresponding repo query
view. No typos. Two notes:

- `ZDPR_Q_TARGET_QUERY`: `@UI.selectionField` on `FiscalYear` is a dead filter — the view
  parameter `P_FiscalYear` already pins it to a single value.
- Same view: `@UI.selectionField` on `TargetCode` filters a field from the outer-joined
  side. Rows with no matching target have `TargetCode` null and disappear when the user
  filters on it — which is the opposite of what a "show me targets" filter should do.

Both are pre-existing in the repo sources too.

## Caveats to carry into the document

- §6.1's data note is right that `TargetBoepd` is zero for FY 2025-26 (targets not loaded
  in `ZPRA_T_PRD_TAR`). It should also carry the open item from `rap-app/README.md`: the
  BE-target figure is read from `tar_qty` because the designed `tar_qty2` does not exist in
  that table. **BE-target semantics are unverified** — §6.3 presents the number as correct.
- §6.2 says "enter the same date range in the filter bar". All five queries are
  parameterised views; in a V4 Fiori Elements preview the parameters come up as a separate
  parameter entry, not as ordinary filter-bar fields. Worth a sentence so it is not
  reported as a defect.
- §7's closing note on Adobe forms names `ZDPR_FRM_PRODUCTION` / `ZDPR_FRM_TARGETS`; the
  repo has `ZPRA_FRM_DPR_PRODUCTION` / `ZPRA_FRM_DPR_TARGETS`, and `ZCL_ZPRA_DPR_PDF` is a
  stub, so PDF output is further off than "create two forms in SFP" suggests.
- Excel download emits **CSV**, not XLSX (XCO XLSX unavailable on this release). The
  document does not say so anywhere.

## Order of work

1. Settle B1 — which naming set is actually in the system. Ask for an ADT screenshot of
   package `ZPRA_DPR` (or `ZPR_DPR_RAP`) showing the object list.
2. Confirm E4 — are the 18 objects really active.
3. Check B2 on all five views.
4. Settle B4 — decide whether a chart is reachable at all on this release, or whether
   tab-2 needs a different delivery (ALP is out; a plain List Report table, or the existing
   `ZPRA_DPR_REPORT` ALV, would be the fallback).
5. Only then create the five DDLX — from `rap-app/`, not from §4 — and the binding.
6. Correct §5.2, §5.2 URL, §2.1 and §1 in the document before it goes to the developer.
