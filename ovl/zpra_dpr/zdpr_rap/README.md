# ZDPR_* backend objects touched for the dashboard

Package `ZPR_DPR_RAP`. Source of truth for the package is the senior's
repository (`vaibhavdiligent/ONGC-CST-Purchase-Date-Sharing-`, branch
`claude/eager-euler-dpm9rf`, folder `src/rap`, ZIP in `deploy/`). This folder
holds only what Arnav has to paste or verify, one file per object.

## ZDPR_Q_DASH_FILTER.ddls.asddls — dashboard filter entity (17/09/26, Arnav)

New classic view, `@OData.publish: true` → service `ZDPR_Q_DASH_FILTER_CDS`
(parameter set `ZDPR_Q_DASH_FILTER`, result set `ZDPR_Q_DASH_FILTERSet`).
Global filter entity of the Overview Page instead of ZDPR_Q_PROD_PERF: same
three parameters (names unchanged — cards receive them by name) plus Asset,
Block, Product, BusinessUnit, AssetDescription, ProductDescription, from
`zpra_c_prd_prof` + `zoiu_pr_dn`. The page only reads its `$metadata`. SAC
plan (`sac/`) is parked — the senior decided to stay with the Overview Page.

## ZDPR_Q_BOEPD_TOTAL.ddls.asddls — card 1 query, date-only (17/09/26, Arnav)

New analytical query on ZDPR_C_BOEPD_DAY: ProductionDate, ProductionDateText,
ActualBoepdOvl, TargetBoepd, nothing else. Exists so that card 1 (Actual vs
BE Target) ignores the Asset / Business Unit / Block / Product fields of the
new filter bar while card 5 on ZDPR_Q_BOEPD_TREND honours them — the Overview
Page matches filter fields to cards by element name and has no per-card
opt-out. Service `ZDPR_Q_BOEPD_TOTAL_CDS`, result set
`ZDPR_Q_BOEPD_TOTALResults`, type `ZDPR_Q_BOEPD_TOTALResult`.

## v16-09/ — backend revision of 16/09/26 (senior's ZIP / Developer Guide)

Extracted verbatim from `../docs/ZDPR_RAP_Complete_Source_Code_2026-09-16.docx`.
Files are numbered in **dependency order = paste order**. 01–11 come in through
the abapGit ZIP (`deploy/ZPR_DPR_RAP_abapgit.zip`, untick the deletions of the
service binding and the five DDLX when pulling); 12–14 are DDLX and must be
pasted in ADT because abapGit cannot import DDLX on this system.

| # | Object | New / changed | What it does |
|---|---|---|---|
| 01 | ZDPR_P_TARGET_ROW | new | ZPRA_T_PRD_TAR rows scaled like the classic report: oil family tar_qty (MMT) × 1e6 × conv_factor from **ZPRA_T_TAR_CF**; gas (BCM) × 1000 = MMSCM, × 6290 = BOE; days in fiscal year |
| 02 | ZDPR_I_TARGET_FY | new | annual TAR_BE volume per FY/asset/block/product, all months, all three volume types |
| 03 | ZDPR_P_DATE_SPINE | new | one row per production date with FY/period |
| 04 | ZDPR_P_TARGET_DAY | new | annual volume ÷ days in FY on every date = flat daily target rate |
| 05 | ZDPR_P_BOEPD_ROWS | new | union: actual rows (A) from ZDPR_P_DAY_BASE + target rows (T) from ZDPR_P_TARGET_DAY |
| 06 | ZDPR_C_BOEPD_DAY | changed | now a plain select on 05 (no join); new key RowType; new ProductionDateText |
| 07 | ZDPR_C_PROD_CUBE | changed | + ProductionDateText (YYYY-MM-DD) |
| 08 | ZDPR_P_PERF_AGG | changed | ANNUAL branch from ZDPR_I_TARGET_FY, divisor = days in FY; + SumTargetBoepd90 (Arnav, 16/09) so the classic query needs no arithmetic in conditions |
| 09 | ZDPR_Q_PROD_PERF | changed | Arnav's activated classic view + RowLabel (the senior's arithmetic form `SumActualBoepd * 100` inside division() and `cast(division())` failed the classic-view check with "* unexpected"; the morning form with typed casts activates) |
| 10 | ZDPR_Q_BOEPD_TREND | changed | + ProductionDateText |
| 11 | ZDPR_Q_DAILY_TREND | changed | + ProductionDateText |
| 12 | ZDPR_Q_BOEPD_TREND (DDLX) | changed | chart on ProductionDateText, sort by date |
| 13 | ZDPR_Q_DAILY_TREND (DDLX) | changed | chart on ProductionDateText, sort by date |
| 14 | ZDPR_Q_PROD_PERF (DDLX) | changed | line items reordered for a 3-column table card, criticality on AchievementPct |

Unchanged in this revision: ZDPR_I_DAILY, ZDPR_I_MONTHLY, ZDPR_I_TARGET,
ZDPR_P_DAY_BASE, ZDPR_C_TARGET_CUBE, ZDPR_Q_PROD_QUERY, ZDPR_Q_TARGET_QUERY,
abstract entities, download stack, SD/SB, the other two DDLX.

New external dependency: table **ZPRA_T_TAR_CF** (gjahr, asset, block, product,
conv_factor). Must exist in the target system; a missing row gives an oil
target of 0 for that asset/FY — same as the classic report.

Why: the BE target line was zero on the dashboard. The old cube joined
monthly TAR_BE / NET_PROD rows at raw tar_qty; the classic report sums the
whole fiscal year over all volume types, converts MMT→bbl and BCM→MMSCM, and
divides by the days in the year.

## Earlier

| Object | Change | Date |
|---|---|---|
| ZDPR_Q_PROD_PERF (`ZDPR_Q_PROD_PERF.ddls.asddls`, root of this folder) | view entity → classic view + @OData.publish, `/` → `division()` | 16/09/26 morning, activated; superseded the same day by v16-09/09 |

`original/` = the source exactly as it stood in the 15/09 document. Never edited.

## sac/ — summary cube for the SAC story (started 17/09/26)

Goal: one analytical query that already carries every row of the Excel
summary block per asset, so SAC only lays it out. Mapping and verdict in
`../docs/DPR_Excel_to_CDS_mapping.md`. Parameter everywhere: `P_AsOf` = last
production date included (DPR of 01-JAN-2026 → 31.12.2025).

| # | Object | Purpose | State |
|---|---|---|---|
| 01 | ZDPR_P_ASOF | calendar helper: windows + day divisors for the as-of date | written |
| 02 | ZDPR_P_SUM_DAILY | MTD, MTD-LY, YTD, YTD-LY, annual-LY rows from ZDPR_P_DAY_BASE, per day + MMT/BCM | next |
| 03 | ZDPR_P_SUM_MONTHLY | previous-month row + FY history from ZDPR_I_MONTHLY | |
| 04 | ZDPR_P_SUM_TARGET | monthly / FY / YTD target rows + asking rate | |
| 05 | ZDPR_P_SUM_ROWS | union of 02–04, identical columns | |
| 06 | ZDPR_C_SUMMARY | cube on 05 | |
| 07 | ZDPR_Q_SUMMARY | analytical query (SAC live) | |
| 08 | ZDPR_I_DAILY | + Comments field | |
| 09 | ZDPR_C_REMARKS / 10 ZDPR_Q_REMARKS | remarks for the as-of date | |

Column contract of 02–05 (union rule: identical types in every branch):
BlockType char6 · FiscalYear numc4 · ProductionDate dats · Asset · Block ·
Product · VolumeType char10 · ProductGroup char3 · BusinessUnit char15 ·
QtyJvPerDay dec(23,7) · QtyOvlPerDay dec(23,7) · BoepdOvlPerDay dec(23,3) ·
VolumeOvlMmt dec(23,7) (block TOTAL in MMT for oil family / BCM for gas) ·
ConversionFactor dec(11,6).

## 23/09/26 — DDLX chart fix for the detail apps

`ZDPR_Q_BOEPD_TREND.ddlx.asddlx` (this folder; original in `original/`, identical
to `v16-09/12_...`): the `@UI.chart` gains `dimensionAttributes` /
`measureAttributes`, and `@UI.presentationVariant` names the chart qualifier
`BoepdVsTarget` in its `#AS_CHART` visualization. Without both, the Analytical
List Page built on the service shows a blank chart standalone and the SmartChart
crashes (`ChartProvider._getRole`) when opened from the dashboard card.
DDLX only; no view, service or `/IWFND/MAINT_SERVICE` change. `ZDPR_Q_TARGET_QUERY.ddlx.asddlx` (same folder, original in `original/`, supplied
23/09/26 and identical to the 16/09 source document): same two defects, same fix,
chart `ActualVsTarget`.

23/09/26 later: `ZDPR_Q_TARGET_QUERY` chart measure switched to `AchievementPct`
(unit-free, FORMULA) so the ALP chart draws Oil and Gas together; ActualQty /
TargetQty remain in the table. Records app default: chart X = AssetDescription,
Y = OvlShareQty1 with a default selection variant Product = Oil — pending the
`ZDPR_Q_PROD_QUERY` DDLX source from ADT.

24/09/26: `ZDPR_Q_BOEPD_TREND` default chart = date × BusinessUnit series,
measure ActualBoepdOvl (the drill-down for cards 1 and 5; card 1 already shows
total vs target, so the app shows the breakdown). Target stays in the table.

## 24/09/26 — OVL Share (BOE) for the records detail app (3 objects, in order)

The records ALP chart cannot draw Oil and Gas together because every quantity
measure in ZDPR_Q_PROD_QUERY carries a per-product unit. The cube already has
the unit-free `BoepdQty` (JV, O+OEG BOE); the OVL share of it is missing.

1. `ZDPR_C_PROD_CUBE.ddls.asddls` — new measure `OvlShareBoe` = BoepdQty × PI/100
   (same conversion and sign as BoepdQty, same PI share as OvlShareQty1), added
   at the end of the select list. Original = v16-09/07 (`original/`).
   ASSUMPTION: the active cube on OCQ equals the v16-09 copy; compare in ADT
   before pasting.
2. `ZDPR_Q_PROD_QUERY` — expose `BoepdQty` and `OvlShareBoe` as column measures
   (next, after 1 activates).
3. DDLX `ZDPR_Q_PROD_QUERY.ddlx.asddlx` — chart `ByAsset`: X = AssetDescription,
   Y = OvlShareBoe, attribute blocks, PV qualifier + sort desc; BOE columns added
   to the line items. Original = 16/09 source document (`original/`).
Target app stays on AchievementPct: ZDPR_C_TARGET_CUBE has no BOE measure and
adding one needs the ZPRA_T_TAR_CF factor join — senior's call, mail drafted 23/09.

24/09/26 later: Achievement % rejected as the chart default (figure not trusted
yet). `ZDPR_Q_TARGET_QUERY.ddls.asddls` (original = 16/09 source document) gains
two FORMULA measures `ActualQtyChart` / `TargetQtyChart` = the quantities without
the unit property, so the ALP SmartChart draws one column pair per product in its
native unit like dashboard card 4. DDLX `ZDPR_Q_TARGET_QUERY` chart then moves to
those two measures (next object). AchievementPct stays in the table only.
