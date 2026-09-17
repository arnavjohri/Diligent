# HANDOVER — ONGC Videsh DPR Production Dashboard (Fiori Overview Page)

Purpose: give a fresh Claude session (or a reviewer) everything needed to continue
this work without re-deriving it. Read fully before changing anything.
Written 16/09/26 by Arnav Johri's Claude session. Companion to
`../docs/ZDPR_HANDOVER.md` (backend RAP package handover, 15/09/26) — read that
one first for the business context, tables, unit rules and release constraints;
this file only adds what the dashboard work established.

---

## 1. What exists and where

| Thing | Location | State |
|---|---|---|
| Backend package `ZPR_DPR_RAP` (18 CDS + 5 DDLX + classes + SD/SB) | customer on-prem S/4, transport OCQK901644 | active; full source in `../docs/ZDPR_RAP_Complete_Source_Code.docx` |
| ZDPR_Q_PROD_PERF rewritten as classic view + `@OData.publish` | `../zdpr_rap/ZDPR_Q_PROD_PERF.ddls.asddls` (original in `../zdpr_rap/original/`) | activated 16/09/26, service ZDPR_Q_PROD_PERF_CDS registered |
| Five OData V2 services `ZDPR_Q_*_CDS` | `/IWFND/MAINT_SERVICE`, alias LOCAL | all answer `$metadata` |
| Fiori Overview Page app `zdprdashboard` | BAS dev space, project `zdprdashboard`; the files that differ from the generator output are in `webapp/` here | six cards render in BAS preview; ABAP-repository deploy as BSP `ZDPRPRODDASH` in progress 17/09/26, first runs failed on a TR lock (see §6 item 1) |
| Step plan, BAS click path, design decisions | `README.md` (this folder) | current |
| Review document for the senior | `../docs/ZDPR_Dashboard_Review.docx` | generated 16/09/26 from this folder |
| Mockup the customer-facing design was drawn from | screenshot supplied in chat 16/09/26 (not on disk); described in `README.md` step table and the Word document | — |

Repo: `arnavjohri/Diligent`, path `ovl/zpra_dpr/`. Every commit goes to `main`
(CLAUDE.md standing rule); the session branch `claude/eloquent-ride-px3sze` is
merged into `main` after each push. Sync with `./scripts/sync.sh "<msg>"` from
the repo root.

## 2. How the pieces connect

```
filter bar (mainModel = ZDPR_Q_PROD_PERF_CDS, entity set ZDPR_Q_PROD_PERFSet)
   P_DateFrom, P_DateTo, P_FiscalYear  ── passed by NAME to every card whose
                                          SelectionVariant lists the same parameter
        │
        ├─ card01  ZDPR_Q_BOEPD_TREND_CDS / ZDPR_Q_BOEPD_TRENDResults   line: actual vs BE target by date
        ├─ card02  mainModel             / ZDPR_Q_PROD_PERFSet          column: per-day BOEPD by product group (YTD rows)
        ├─ card03  mainModel             / ZDPR_Q_PROD_PERFSet          table, tabs YTD / Annual, % Achv criticality
        ├─ card04  ZDPR_Q_TARGET_QUERY_CDS / ZDPR_Q_TARGET_QUERYResults column: actual vs target per product (TAR_BE)
        ├─ card05  ZDPR_Q_BOEPD_TREND_CDS / ZDPR_Q_BOEPD_TRENDResults   line: OVL BOEPD by date, series = BusinessUnit
        └─ card06  ZDPR_Q_PROD_QUERY_CDS / ZDPR_Q_PROD_QUERYResults     table: asset, product, OVL share (window total)
```

All UI annotations the cards use are LOCAL (`webapp/annotations/annotation_*.xml`),
one file per service, so the page does not depend on the five backend DDLX.
The generator's own backend-annotation data sources (`*_VAN`) are kept in the
manifest but nothing on the page relies on them.

## 3. Facts established the hard way (do not re-derive)

**OData naming — two conventions in one package**

| View kind | Parameter entity set | Result entity set | Result entity type | nav. property |
|---|---|---|---|---|
| plain view with parameters (ZDPR_Q_PROD_PERF) | `ZDPR_Q_PROD_PERF` | `ZDPR_Q_PROD_PERFSet` | `ZDPR_Q_PROD_PERFType` | `Set` |
| `@Analytics.query: true` (the other four) | `ZDPR_Q_BOEPD_TREND` | `ZDPR_Q_BOEPD_TRENDResults` | `ZDPR_Q_BOEPD_TRENDResult` | `Results` |

- Schema namespace = service name, uppercase (`ZDPR_Q_BOEPD_TREND_CDS`). One
  screenshot suggested lowercase `_cds`; the downloaded metadata is uppercase.
- A wrong `entitySet` in a card does not say "Cannot load card": the whole card
  is dropped and the console shows
  `TypeError: Cannot read properties of null (reading 'entityType')` in
  `sap.ovp Component-dbg.js getPreprocessors`.
- In the analytical services, dates (ProductionDate, P_DateFrom, P_DateTo) are
  exposed as `Edm.String` `yyyymmdd`, so SelectionVariant defaults are plain
  `20240401`; a `2024-04-01T00:00:00` default was timezone-shifted to 31.03.
  In the plain-view service the same parameters are `Edm.DateTime`, so
  `annotation_perf.xml` keeps the `T00:00:00` form. (Confirm the `Type=` of
  `P_DateFrom` in both `localService/*/metadata.xml` if this is ever in doubt —
  it was inferred from behaviour, not read from the file.)

**Overview Page behaviour**

- Parameterised card: `entitySet` = the RESULT set, parameters via
  `UI.SelectionVariant` → `Parameters` (SAP doc "Configuring an EntitySet with
  Input Parameters"). Filter-bar parameters override by name; that needs
  `"considerAnalyticalParameters": true` in `sap.ovp` — with `false` the filter
  bar showed the fields but cards on other models kept their annotation defaults.
- `"enableODataSelect": true` is required for table cards on analytical queries;
  without it the card fetches every column and the analytic engine returns
  unaggregated rows (card 6 showed 1336 rows).
- Table cards show at most THREE columns. Card 3 therefore has two tabs.
- Line-chart cards need no measure/dimension roles; Category on the date and
  Series on BusinessUnit is enough. Column cards ignore roles.
- Header KPI (`dataPointAnnotationPath`) on an analytical set SUMS over the rows
  (card 1 showed 2.8M = 16 days summed); on a plain view it shows the first row.
  Removed from card 1 for that reason.
- Layout: `containerLayout: resizable`, cards placed in manifest order, size per
  card `defaultSpan {rows, cols}`; ~16 px per row, grid had 4 columns at 1919 px
  width. All six cards are `rows 25, cols 2` → three rows of two, equal size.
  A user's drag/resize is persisted and beats the defaults (Manage Cards → Reset).
- BAS annotation checker warnings "Incomplete PropertyPath P_DateFrom" and
  "Text key not in i18n" are false alarms for this pattern; the only marker that
  matters is on the `Annotations Target=` line.
- `Unable to load schema from 'manifest-schema://local'` on manifest.json is an
  editor message, not an app problem.

**BAS specifics on this tenant**

- Generator version @sap/generator-fiori:ovp 1.32.0, minUI5Version 1.136.10.
- "Add Data Source" is called **Manage Service Models**; it names data source and
  model after the service (`ZDPR_Q_BOEPD_TREND_CDS` etc.); the main model is
  `mainModel`, not `""`. The generator also creates `annotations/annotation.xml`
  for the main service and `*_VAN` backend-annotation sources per service.
- Service URIs are plain `/sap/opu/odata/sap/<service>/` (no destination prefix).
- Preview: right-click project → Preview Application → `start`.

## 4. Backend change made for the dashboard

ZDPR_Q_PROD_PERF: `define view entity` → classic `define view` with
`@AbapCatalog.sqlViewName: 'ZDPRQPRODPERF'`, `@OData.publish: true`, ratios via
`division(a, b, dec)`, `@OData.entityType.name` dropped. Select list unchanged,
so DDLX ZDPR_Q_PROD_PERF and ZDPR_SD_ANALYTICS still activate. Change markers
`// BOC/EOC By Arnav on 16/09/26`; old lines kept commented. File in
`../zdpr_rap/`. Reason: an OVP runs on one protocol and the other four queries
are V2; the tab-3 table has no other source.

## 5. Gaps against the mockup (what the senior was told)

Not possible with standard cards: six-column performance table (3-column limit →
custom card, ~1 day UI); single headline BOEPD figure with deviation (needs a
TOTAL row in ZDPR_P_PERF_AGG + custom card); "Open detail" links (needs the
ALP apps deployed); mockup colours (Fiori theme).
Possible with a small backend view each: business unit + target code in the
filter bar (new classic view `ZDPR_Q_DASH_FILTER` with all four parameters +
BusinessUnit as global filter entity); gas as BOE on card 4 (BOE measure in
ZDPR_C_TARGET_CUBE); latest-day asset table with oil/gas/PI/BOEPD columns
(dedicated view); readable parameter labels (`@EndUserText.label` on the
parameters — the bar shows "Date, Date, Fiscal Year").
Data: BE targets (TAR_BE / NET_PROD) are missing for the dates tested, so the
target line is zero and % achievement is nonsense until ZPRA_T_PRD_TAR is loaded
for the fiscal year under test. Not a bug.

## 5a. Backend revision v16-09 (senior, 16/09 evening)
Five new views and nine changed objects, all in the target chain — list, paste
order and reason in `../zdpr_rap/README.md`, sources in `../zdpr_rap/v16-09/`,
documents in `../docs/ZDPR_RAP_Developer_Guide_2026-09-16.docx` and
`../docs/ZDPR_RAP_Complete_Source_Code_2026-09-16.docx`. The app files in
`webapp/` are adapted to it (ProductionDateText axes, RowLabel, YTD/Annual as
two cards) and REQUIRE it. Validation the senior asked for: the flat BE Target
line on card 1 must equal the "Target : YYYY-YY" grand total of the DPR Excel
(BOPD/MMSCMD mode) for the same date; if not, check ZPRA_T_TAR_CF first.
Two statements in the senior's Developer Guide §8.4 are wrong on this system
and were not applied: the PROD_PERF result set is `ZDPR_Q_PROD_PERFSet` (not
`...Results`) and the BOEPD annotation target type is `...Result` (not
`...Type`); the generator names models after the service, not boepd/daily/...

## 6. Open items, in the order they should be done

0. Get backend v16-09 active (ZIP pull or paste 01–11, then DDLX 12–14 in ADT),
   refresh the BAS service models, re-run the preview, do the target check.
1. Deploy — path changed 17/09/26. The app goes to the **on-prem ABAP
   repository** via `npm run deploy` (`fiori deploy`, ABAP deployment
   configuration in `ui5-deploy.yaml`), not to Cloud Foundry / Work Zone; the
   CF guide in `../docs/` is superseded for this app. State 17/09/26: NOT yet
   uploaded. The first run reserved `R3TR WAPA ZDPRPRODDASH` + two `R3TR SICF`
   nodes on workbench TR **OCQK901673** (user SAP_ABAP = destination user) and
   then failed; later runs used TR OCQK901674 in `ui5-deploy.yaml` and died
   with HTTP 400 `Object R3TR WAPA ZDPRPRODDASH is already locked in request
   OCQK901673`. Fix: `app.transport: OCQK901673`, `app.package: ZPR_DPR_RAP`
   (uppercase), rerun. Success looks like `* Creating new SAPUI5 ABAP
   repository ZDPRPRODDASH *`, 13 files, `Deployment Successful`. Then the
   standalone URL check (`/sap/bc/ui5_ui5/sap/zdprproddash/index.html`), then
   tile / catalog / group in `/UI2/FLPD_CUST` (customizing TR) and PFCG role.
2. Data check: SE16 ZPRA_T_PRD_TAR, TAR_CODE=TAR_BE, GJAHR=2024,
   PROD_VL_TYPE_CD=NET_PROD — which MONAT exist; then validate cards 1–4 against
   the DPR Excel for a window that has targets.
3. Read `Type=` of `P_DateFrom` from both local metadata files and record it here.
4. Senior's decision on custom cards (six-column table, headline KPI).
5. Step 7 filter view; parameter labels; BOE measure; step 8 navigation.

## 7. Working agreements

- One object at a time, then wait for "activated" or the error text.
- Paste-only into ADT/BAS: no abapGit for this package (DDLX import fails), no
  system access from here. Screenshots of console + Network tab are the debug
  loop: ask for F12 → Console red entries expanded, and Network filtered on the
  service name with Preserve log on, after an F5.
- Chat replies from Arnav are short ("activated", "matches", "works"); ask for
  exact metadata lines when a name is assumed rather than guessing twice.
- Keep `README.md` in this folder current: status block at the top, step table,
  and the naming table in 1.5.
- No model names in anything pushed to the repo.
