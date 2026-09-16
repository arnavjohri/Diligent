# ZDPR_* backend objects touched for the dashboard

Package `ZPR_DPR_RAP`. Source of truth for the package is the senior's
repository (`vaibhavdiligent/ONGC-CST-Purchase-Date-Sharing-`, branch
`claude/eager-euler-dpm9rf`, folder `src/rap`, ZIP in `deploy/`). This folder
holds only what Arnav has to paste or verify, one file per object.

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
