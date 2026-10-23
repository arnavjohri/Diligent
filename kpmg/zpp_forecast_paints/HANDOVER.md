# ZFORECAST Paints — handover

Astral Limited / Project UDAY (KPMG) · Paints division, WRICEF ID-2B · modules PP / SD
Development system only · transport **DEVK930479** (UDAYABAP03, "UDAY: PP: 2B: Forcast Paints"),
not released · handed over 23.10.2026 by Arnav Johri, Associate Consultant, Diligent Global.

This is the one file to read first. It is written so that a person **and their Claude** can
pick the development up without Arnav: what exists, where every file is, how the pieces fit,
the rules the code was written to, what is still open, and how to ship a change. Everything it
summarises is in the repository `arnavjohri/Diligent`, folder `kpmg/zpp_forecast_paints/`,
and the longer documents it points to are in that folder's `docs/`.

---

## 0. How to use this file with Claude

1. **Get the repository.** Ask Arnav for collaborator access to
   `https://github.com/arnavjohri/Diligent` (private), then
   `git clone https://github.com/arnavjohri/Diligent.git`. Work on `main`, the only branch.
2. **Give Claude the context.** Either open Claude Code in the clone (the root `CLAUDE.md` and
   `MEMORY.md` are read automatically), or paste this file into a Claude project / conversation
   as the standing context. If the repository is not available yet, this file alone carries
   the object list, the table layouts, the method list, the rules and the open items.
3. **Read in this order** (paths from the repository root):
   - this file;
   - `kpmg/zpp_forecast_paints/docs/ZFORECAST_Paints_Technical_Handover.md` — every field,
     method, FORM and column, 13 sections;
   - `kpmg/zpp_forecast_paints/ISSUES.md` — the dated log of every decision and change;
   - `kpmg/zpp_forecast_paints/src/` — the code itself (abapGit layout);
   - `kpmg/zpp_forecast_v2/NOTES.md` and `00_TECHNICAL_OBJECTS.md` — the Adhesive engine
     Paints runs on;
   - `MEMORY.md` §4 and §5 (repository root) — release constraints and mistakes already made;
   - `CLAUDE.md` (repository root) — the working rules for this repository.
4. **Your author tag.** The change markers in this repository say `By Arnav on DD/MM/YY`. Use
   your own name in the same form on anything you change (`*BOC By <Name> on DD/MM/YY`).
5. **The SAP system is not reachable from Claude.** There is no ADT or RFC connection and no
   internet from the system. Code travels by abapGit ZIP (`ZABAPGIT_STANDALONE`, offline repo)
   or by copy-paste from SE80/SE24/SE38. Claude never "checks the system"; you do, and you
   paste what you see (SE80 download, activation error, SE16 row) into the conversation.

---

## 1. What Paints is, in one paragraph

The Paints forecast is the **Adhesive forecast** (`kpmg/zpp_forecast_v2/`, built August to
September 2026, in functional testing) with a different list layout and three extra tables.
The arithmetic (annual, quarterly, monthly), the sales-history reads from billing, the
business-forecast comparison, the quarterly month split, the eight uploads, the forecast
number and the final report are the Adhesive ones and run in the Adhesive objects unchanged.
Paints adds, on top of the engine's output, the columns the Paints template draws — plant
name, brand, material groups from sales organisation 4000, pack size, dealer price (DPL),
quantity per carton, gross weight, volume in kilolitres and value in crores per month,
tonnage on gross weight — and saves the list, column for column, into three Paints tables,
while the engine still saves the shared Adhesive-shaped row. One Adhesive object was edited:
the upload program, which gained a Brand upload and a four-value category indicator.

The functional spec is `kpmg/zpp_forecast_paints/fs/Forecast_Template-Paints_1.xlsx`
(received 19.10.2026; `fs/*.extract.txt` is its text, sheet by sheet). **Sheet1 was taken as
the authority** where the sheets disagree. Twenty-eight defects in the FS and seventeen open
queries are logged in `docs/ZFORECAST_Paints_Assumptions_and_Queries.md`; **none has been
answered**. The build stands on the assumptions in section 9 below.

---

## 2. Where things stand (23.10.2026)

| Item | State |
|---|---|
| All objects of package `ZPP_FORECAST_PAINTS` | Imported and **active in DEV** (full ZIP 19/10, delta ZIP 22/10) |
| `ZPP_FORECAST_UPLOAD` change (Adhesive package) | Imported and active in DEV (delta ZIP 22/10) |
| `ZCL_PP_FCST_PNT`, sales org 4000 hardcoded (22/10 PM) | In the repository and in `ZPP_FORECAST_PAINTS_22-10-26_vkorg_delta.zip`; Arnav was given the full class source to paste. **Confirm in SE24 that `GC_VKORG` exists** — if the class still has `READ_CONFIG` / `GC_VKORG_DEFAULT`, the system copy is the 22/10 AM version and the class must be replaced |
| SE41 GUI status `PF_STATUS` of `ZPP_FORECAST_PAINTS` | Created 22/10 |
| SE93 `ZFCST_PAINTS` | Reported created 22/10; Arnav later asked that tcodes be left out of the handover documents — check SE93, otherwise run from SE38 |
| Transport | DEVK930479, not released; nothing in QAS |
| Functional test | **Not started.** Pack: `docs/ZFORECAST_Paints_Test_Handover.docx` (22 cases) |
| Queries M1–M7, Q1–Q10 | Unanswered |
| Authorisation checks | **Bypassed** in `ZCL_PP_FCST_UTIL` since 07/09/26 (QAS testing); restore before any release — affects Adhesive and Paints |

---

## 3. Object inventory

### 3.1 New — package `ZPP_FORECAST_PAINTS` (all in `src/`, abapGit layout)

| Object | Type | Size | Purpose |
|---|---|---|---|
| `ZPP_FORECAST_PAINTS` | Package | | "ZFORECAST Paints - forecasting" |
| `ZDO_BRAND` | Domain | CHAR 40 | brand (length is an assumption, query M2) |
| `ZDO_FCST_KL` | Domain | DEC 13,3 | pack size, qty per carton, volume in KL |
| `ZDO_FCST_CR` | Domain | DEC 13,4 | value in crores |
| `ZDE_BRAND` | Data element | | on `ZDO_BRAND`, "Brand" |
| `ZDE_PACK_SIZE`, `ZDE_QTY_CARTON`, `ZDE_FCST_KL` | Data elements | | on `ZDO_FCST_KL` |
| `ZDE_FCST_CR` | Data element | | on `ZDO_FCST_CR` |
| `ZPPT_BRAND` | Table | 8 fields | brand per plant and material (key MANDT WERKS MATNR) |
| `ZPPT_PNT_FCST_YR` | Table | 73 fields | Paints annual forecast = the annual list (key + FYEAR) |
| `ZPPT_PNT_FCST_QT` | Table | 58 fields | Paints quarterly forecast = the quarterly list (key + GJAHR QUARTER) |
| `ZPPT_PNT_FCST_MN` | Table | 45 fields | Paints monthly forecast = the monthly list (key + GJAHR PERIOD) |
| `ZCL_PP_FCST_PNT` | Class | 845 lines, 9 methods | `ENRICH` adds the Paints columns; `SAVE_PAINTS` writes the Paints tables |
| `ZPP_FORECAST_PAINTS` | Report | 1,581 lines | generation, three modes, Paints list, save (SALV full screen, no SE51 screen) |

### 3.2 Changed — package `ZPP_FORECAST` (Adhesive), markers `By Arnav on 22/10/26`

| Object | Change |
|---|---|
| `ZPP_FORECAST_UPLOAD` (tcode `ZFCST_UPL`) | Ninth radio button **Brand** (plant, material, brand into `ZPPT_BRAND`, `FORM do_brand`); category indicator accepts **MTS, MTO, DIS, TIN** and the long forms DIS ART / TINTING (`FORM check_indicator` replaces the MTS/MTO-only check; old lines commented); selection text `P_BRD`. 2,615 lines. Source: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap` |

### 3.3 Shared with Adhesive — used as they are, never in a Paints ZIP

Tables `ZPPT_PROD_CAT`, `ZPPT_MAT_TRACK`, `ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST`, `ZPPT_FCST_CFG`,
`ZPPT_FCST_YR`, `ZPPT_FCST_QT`, `ZPPT_FCST_MN`; number range `ZPPFCST`; authorisation object
`ZPP_FCST` (WERKS, ACTVT); message class `ZPP_FCST` (001–026, nothing added for Paints);
application-log object `ZPP_FCST` / subobject `GENERATE`; TVARVC `ZPP_FORECAST_MTART`
(material types FERT, HAWA) and `ZPP_FCST_LEGACY`; classes `ZCL_PP_FCST` (engine, 2,309
lines) and `ZCL_PP_FCST_UTIL` (393); programs `ZPP_FORECAST` (Adhesive generation, tcode
`ZFCST`, the template `ZPP_FORECAST_PAINTS` was copied from), `ZPP_FORECAST_REPORT` (final
report, tcode `ZFCST_RPT`, serves Paints by plant selection).

### 3.4 Withdrawn

`ZPP_FORECAST_PAINTS_UPL` — the separate Paints upload of 19/10, imported in DEV that day,
superseded on 22/10 by the change to `ZPP_FORECAST_UPLOAD`. **Still in DEV; delete it in SE38.**
No transaction was created for it. Source in git history:
`git log --all -- kpmg/zpp_forecast_paints/src/zpp_forecast_paints_upl.prog.abap`.

### 3.5 Manual objects (abapGit never carries these)

| Object | State |
|---|---|
| SE41 `PF_STATUS` of `ZPP_FORECAST_PAINTS` — SALV_STANDARD plus `ZSAVE`, `ZSELALL`, `ZDESEL`, `ZEXCEL` | created 22/10; travels in the transport with the program |
| SE93 `ZFCST_PAINTS` → `ZPP_FORECAST_PAINTS`, screen 1000 | reported created 22/10; verify |
| SM30 `ZPPV_FCST_CFG` row per Paints plant | **not needed** since 22/10 (sales org 4000 hardcoded); only for a legacy-user TVARVC name |
| SE54 views on `ZPPT_BRAND` and the three Paints tables | not generated, optional |
| SE11 `ZDO_MTS_MTO` fixed values `DIS`, `TIN` | not added, optional (the upload writes the codes regardless; SM30 on `ZPPT_PROD_CAT` would refuse them) |

---

## 4. How it works

### 4.1 Run and save, end to end

```
ZPP_FORECAST_PAINTS (ZFCST_PAINTS)
  selection screen  = ZPP_FORECAST's: plant, material, financial year "2026-2027",
                      quarter | period | date range, Tonnage Wise, [Legacy if TVARVC set]
  FORM generate     go_fcst = ZCL_PP_FCST  ->  generate_annual / _quarterly / _monthly
                      -> gt_eng (engine rows, zcl_pp_fcst=>tt_alv), gt_msg
                    gt_eng -> gt_alv (zcl_pp_fcst_pnt=>tt_alv) row by row, MOVE-CORRESPONDING
                    go_pnt->enrich( iv_mode = g_mode  ct_alv = gt_alv  ct_msg = gt_msg )
  FORM save_log     SLG1 object ZPP_FCST / GENERATE, external number "PAINTS <mode> <fy> <user>"
  FORM display      CL_SALV_TABLE full screen, status PF_STATUS, Sheet1 column lists,
                    Adhesive working columns hidden but offered by Change Layout
  ZSAVE             lcl_handler=>save_selected:
                      go_fcst->save( g_mode, engine-typed copy of the selected rows )
                        -> forecast number drawn or reused, ZPPT_FCST_YR/_QT/_MN written
                      FCST_NO LIGHT STATUS MESSAGE copied back; MARK re-set on the saved rows
                      go_pnt->save_paints( g_mode, gt_alv, lt_msg )
                        -> ZPPT_PNT_FCST_YR/_QT/_MN written, CORRESPONDING by field name
```

**Two writes on every save, by design.** The shared tables must still be written because the
engine reads the business forecast, the additional quantities, MSL and the stored price back
from them at generation, the change upload needs the shared row, the forecast number is
shared across the three tables through them, and `ZFCST_RPT` reads them. Nothing reads the
three Paints tables yet. Dropping the shared write means changing the engine — not done.

### 4.2 `ZCL_PP_FCST_PNT` — the nine methods

Public, final, no instance attributes. `ty_alv` = `INCLUDE TYPE zcl_pp_fcst=>ty_alv` + the
Paints columns (`name1 brand pack_size pack_unit qty_carton brgew`, `m01_kl..m12_kl`,
`m01_cr..m12_cr`, `m4_kl..m6_kl`, `m4_cr..m6_cr`). `CONSTANTS gc_vkorg TYPE vkorg VALUE '4000'`.

| Method | Reads | Does |
|---|---|---|
| `ENRICH` (public) | the private reads below, once each on de-duplicated drivers | fills the Paints columns of every row; clears the engine's `MVGR1..5` and texts and refills them from sales org 4000; computes KL, crores and tonnage per forecast month (annual `M01..M12` on `Mnn_FCST`, quarterly `M4..M6` on `Mn_FCST_FINAL`, monthly `M4` on `TOTAL_QTY`). **`Mnn_TON` overwrites the engine's net-weight tonnage** — the only engine field it changes. `ct_msg` is kept in the signature, nothing is written to it |
| `SAVE_PAINTS` (public) | existing row's `ERNAM`/`ERDAT` | rows with `MARK = X` and a `FCST_NO`: `CORRESPONDING` into the mode's Paints table, created-by kept, `MODIFY`, one `COMMIT WORK AND WAIT`; a refused row gets `LIGHT 1` and a message; summary E message appended to `ct_msg` |
| `READ_NAMES` | `T001W` | plant name |
| `READ_BRANDS` | `ZPPT_BRAND` | brand by plant + material |
| `READ_MARA` | `MARA` | `MEINS`, `BRGEW`, `GEWEI` |
| `READ_PACK_SIZES` | `MARM`, `MEINH IN (L, ML, KG, G)` | first unit in that preference order that is not the base unit; pack = `UMREN / UMREZ`; ML and G ÷ 1000 (assumption, query M5) |
| `READ_SALES_VIEW` | `MVKE`, `VKORG = '4000'` | `MVGR1..5`, `AUMNG`; one row per material (first distribution channel); `AUMNG` → qty per carton only where `MVGR1` is filled (FS row 91; query Q2) |
| `READ_GROUP_TEXTS` | `TVM1T..TVM5T`, logon language | descriptions for groups 1..5 |
| `READ_PRICES` | `A923` → `KONP` | annual mode only: latest `DATAB` per material, lowest `KOPOS`, `KBETR`. Same rule as the engine's private `READ_PRICES`; duplicated because the engine is not changed (query Q1) |

Formulas: `Mnn_KL = qty × PACK_SIZE ÷ 1000` · `Mnn_CR = PRICE × qty ÷ 1,00,00,000` ·
`Mnn_TON = qty × BRGEW ÷ 1000`. The quantity is the one the engine prices.

### 4.3 The engine behind it (`ZCL_PP_FCST`, unchanged)

Annual: last year's twelve months (billing `VBRK`/`VBRP`, returns excluded, on `FKDAT`) ×
load factor from `ZPPT_PROD_CAT`. Quarterly: max(last year's same quarter, last three months)
× load factor, then max(that, business forecast from `ZPPT_FCST_QT`), split into the three
months in last year's proportions; per-month additional `BUS_FCST_ADD1/2/3` from the change
upload. Monthly: max(last year's same month, last-three-month average × load factor), then
max(that, business forecast); `TOTAL_QTY` = final + additional + MSL. Old material codes
(`ZPPT_MAT_TRACK`) are absorbed into the successor; `ZPPT_SLS_HIST` fills months billing does
not have; `ZPPT_MAT_EXCL` drops materials; TVARVC `ZPP_FORECAST_MTART` restricts material
types. The engine reads `MVKE` with the sales org from `ZPPT_FCST_CFG` (default 1100) — for
Paints that result is overwritten by `ENRICH`. Full detail: `kpmg/zpp_forecast_v2/NOTES.md`
and `00_TECHNICAL_OBJECTS.md` §6–§9.

### 4.4 The Paints tables = the displayed list

Every table: key, `FCST_NO`, the lead block `NAME1 BRAND MAKTX MTS_MTO MVGR1_TXT MVGR2_TXT
MVGR5_TXT MATKL PACK_SIZE PACK_UNIT WAERS PRICE QTY_CARTON MEINS`, the mode's columns in
list order, `GEWEI BRGEW` and the tonnage columns, `ERNAM ERDAT AENAM AEDAT`. Material groups
are stored as descriptions (`BEZEI20`). `MEINS`, `WAERS`, `GEWEI` are unit references, not
list columns.

| Table | Key | Mode columns |
|---|---|---|
| `ZPPT_PNT_FCST_YR` | WERKS MATNR FYEAR | `M01_FCST..M12_FCST` · `M01_KL..M12_KL` · `M01_CR..M12_CR` · `M01_TON..M12_TON` |
| `ZPPT_PNT_FCST_QT` | WERKS MATNR GJAHR QUARTER | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY` · per month n=4..6: `Mn_FCST BUS_FCST_ADDx Mn_FCST_FINAL Mn_KL Mn_CR Mn_TON` |
| `ZPPT_PNT_FCST_MN` | WERKS MATNR GJAHR PERIOD | comparison block as above · `BUS_FCST_ADD TOTAL_QTY M4_KL M4_CR M4_TON` |

`M4..M6` are positional names inherited from the engine: the first, second and third month of
whichever quarter is run. `PERIOD` is `POPER` 001–012 with 001 = April. `GJAHR` is the year the
financial year starts in. Field-by-field lists: Technical Handover §4.

### 4.5 Uploads (all nine in `ZFCST_UPL`)

Product Category (plant, material, category, load factor, indicator MTS/MTO/DIS/TIN) ·
Material Tracking · Material Exclusion · Legacy Sales History (twelve months per plant,
material, year) · Business Forecast Quarterly · Business Forecast Monthly (MSL column 6 —
Paints leaves it blank) · Forecast Change Quarterly (Month 1/2/3 within the quarter, reason) ·
Forecast Change Monthly · **Brand** (plant, material, brand). Each has a Download Template
button; Excel, CSV or tab text; test run ticked by default; row-by-row result list.

---

## 5. Repository map

```
kpmg/zpp_forecast_paints/
  HANDOVER.md                      this file (docs/ZFORECAST_Paints_Handover.docx is its Word copy)
  NOTES.md                         what it is, how it ships, gotchas
  ISSUES.md                        dated log: issue -> cause -> fix -> files -> TR  (read it)
  00_TECHNICAL_OBJECTS.md          inventory, import, requirement mapping, column lists, assumptions
  MANUAL_STEPS.md                  the two pulls, SE41 status (two routes), SE93, optional steps
  KT_TCODES.md                     one-page functional view, Paints only
  fs/                              Forecast_Template-Paints_1.xlsx as received + *.extract.txt
  docs/
    ZFORECAST_Paints_Technical_Handover.md/.docx   every field, method, FORM, column (13 sections)
    ZFORECAST_Paints_Test_Handover.md/.docx        functional test pack: setup, files, 14-step run, 22 cases
    TS_ZFORECAST_Paints.md/.docx                    technical specification
    ZFORECAST_Paints_Assumptions_and_Queries.md/.docx   M1-M7, P01-P26, Q1-Q10, F01-F28 (v2 of 19/10 + status note)
    ZFORECAST_Paints_Manual_Steps.docx, ZFORECAST_Paints_KT_Tcodes.docx   Word copies of the md files above
  src/                             the 18 abapGit files: package.devc.xml, 3 .doma.xml, 5 .dtel.xml,
                                   4 .tabl.xml, zcl_pp_fcst_pnt.clas.abap/.xml, zpp_forecast_paints.prog.abap/.xml
  tools/
    abapcheck.py                   static checks: line length, block balance, PERFORM/FORM, METHOD decl/impl
    mktables.py                    generates the three Paints table XMLs - edit and re-run, never the XML by hand
    mkupl_adhesive.py              generated the 22/10 upload change (anchors asserted once; refuses to run twice)
    mkupl.py                       historic (the withdrawn Paints upload)
  ZPP_FORECAST_PAINTS.zip                       the whole package, rebuilt 22/10 PM
  ZPP_FORECAST_PAINTS_22-10-26_delta.zip        22/10 AM delta (tables, class, program)
  ZPP_FORECAST_PAINTS_22-10-26_vkorg_delta.zip  22/10 PM delta (class only, sales org 4000)
  .abapgit.xml                     STARTING_FOLDER /src/, FOLDER_LOGIC PREFIX

kpmg/zpp_forecast_v2/              Adhesive: src/ (engine, util, 3 programs, DDIC, msag), NOTES.md,
                                   ISSUES.md (815 lines, the whole Adhesive history), 00_TECHNICAL_OBJECTS.md,
                                   ZPP_FORECAST_UPLOAD_22-10-26_delta.zip (the upload change, package ZPP_FORECAST)
kpmg/_docs/ZFORECAST_KT_Tcodes.md/.docx   KT of both divisions' transactions
MEMORY.md                          §4 release constraints, §5 mistakes made, §6 shipping, §10 definition of done
CLAUDE.md                          working rules of the repository
scripts/sync.sh                    commit + pull + push in one go;  --pull-only  to update first
scripts/save-original.sh           file an SE80 download under <object>/original/ with drift detection
```

---

## 6. Rules the code was written to (and must keep)

From `CLAUDE.md` and `MEMORY.md`; the ones that matter for this object.

1. **Never trust the repository copy as current.** Before changing an object, get a fresh SE80
   download (Arnav's helper report `ZR_PROG_DOWNLOAD` pulls a program with its includes, or an
   FG/class), diff it against `src/`, and report any drift before applying a fix.
2. **Change markers**: `*BOC By <Name> on DD/MM/YY` … `*EOC By <Name> on DD/MM/YY` around a
   block, `"Changes by <Name> on DD/MM/YY` on a single line. Date `DD/MM/YY` with slashes.
   **Never nest markers**; extend an existing block instead. Comment old code out, never delete
   it; new code goes below the commented original.
3. **Strict Open SQL**: comma-separated field list, every host variable escaped with `@`
   (`INTO TABLE @lt`, `FOR ALL ENTRIES IN @itab`, `INTO @DATA(ls)`), `IS NOT INITIAL` guard
   before every `FOR ALL ENTRIES`, no `SELECT` inside a `LOOP` where FAE or a join would do,
   `SORT` outside the loop before `DELETE ADJACENT DUPLICATES`. Clause order:
   `… WHERE … ORDER BY f INTO @tgt UP TO 1 ROWS.`
4. **A SELECT field list and its `TYPES` are matched by position**, not name — re-check both
   together after any edit.
5. **Lines under 120 characters.** SE38 wraps a longer line on paste and the tail becomes a
   bogus statement.
6. **Complete objects, never fragments.** A changed object is delivered whole, first line to
   last, with the before/after line count.
7. **No hardcoded clients, dates, company codes** unless the FS says so. Sales org 4000 is
   hardcoded because FS row 91 says `VKORG=4000` — recorded in the code and here.
8. **Assumptions** go in the code as `" ASSUMPTION: …` (greppable) and in the reply.
9. **Release constraints** (`MEMORY.md` §4.2) that bit on this landscape and are already
   applied in this code: no `VALUE #( ( literal ) )` over an elementary line type — use
   `APPEND`; `ALIGN = RIGHT` whenever a string template zero-pads (`|M{ i WIDTH = 2 PAD = '0'
   ALIGN = RIGHT }|`), or use a NUMC variable as this class does; put the result of a
   functional call into a variable before `LOOP AT` it; declarations in source order; `DATA`
   not `CONSTANTS` for a switch both branches of which must compile.
10. **Error paths give the user a message** — no short dump, no silent skip.
11. **Never modify a standard SAP object; never touch the Adhesive engine or helper class for
    Paints.** `ZPP_FORECAST_UPLOAD` is the one Adhesive object edited, on Arnav's explicit
    instruction, with markers.
12. **Push every change to `main`**: `./scripts/sync.sh "<what changed>"` as the last step;
    log it in `ISSUES.md` (date, cause, files, TR). `./scripts/sync.sh --pull-only` first in
    every session.
13. **Transport release, QAS/production, mail, ATC exemptions, object deletion stay manual.**

---

## 7. Shipping a change

**abapGit ZIP** (`ZABAPGIT_STANDALONE` → the offline repo of the package → Import ZIP → stage →
Pull). One ZIP per package. `.abapgit.xml` at the ZIP root (`STARTING_FOLDER /src/`,
`FOLDER_LOGIC PREFIX`), `src/package.devc.xml`, LF line endings, no BOM. **Element order in
hand-written XML is load-bearing**: `PROGDIR` = `NAME, VARCL, SUBC, FIXPT, UCCHECK`; `TPOOL`
items = `ID, KEY, ENTRY, LENGTH`; table `DD03P` fields = `FIELDNAME, KEYFLAG, ROLLNAME,
ADMINFIELD, NOTNULL, COMPTYPE, [REFTABLE, REFFIELD]`. Copy the shapes in `src/` — they are the
ones that imported on this landscape (the first hand-written abapGit ZIP that did).

```
cd kpmg/zpp_forecast_paints
python3 -I tools/abapcheck.py src/zcl_pp_fcst_pnt.clas.abap src/zpp_forecast_paints.prog.abap
rm -f ZPP_FORECAST_PAINTS.zip && zip -X -D ZPP_FORECAST_PAINTS.zip .abapgit.xml src/*
```

A delta ZIP is the same layout with only the changed files under `src/` (plus `package.devc.xml`
and `.abapgit.xml`); the stage then shows exactly those objects. **Before pulling into
`ZPP_FORECAST`, open the stage diff of `ZPP_FORECAST_UPLOAD`: it must show only your lines.**
Anything else means the running program has edits the repository does not have — stop and
get the SE80 download.

**Paste** works for everything here (no SE51 screen anywhere): SE11 for DDIC, SE24 source-based
for the class, SE38 for the programs (selection texts from the `.prog.xml` TPOOL). Paste
order for a fresh system: domains → data elements → `ZPPT_BRAND`, the three Paints tables →
`ZCL_PP_FCST_PNT` → `ZPP_FORECAST_PAINTS` → the `ZPP_FORECAST_UPLOAD` blocks (by FORM name).

**Never in a ZIP**: SE41 status, SE93, SE54 views, SNRO, SU21 — by hand, once.

Table field change → edit the field list in `tools/mktables.py`, re-run it, re-zip; then
`SAVE_PAINTS` needs no change (it maps by name) but the program's column lists
(`FORM visible_columns`) and `ty_alv` in the class do if the column is to be displayed.

---

## 8. Known gotchas

- `ZPP_FORECAST_PAINTS` is a **copy of `ZPP_FORECAST`** (23/09/26 state). A fix to the
  Adhesive program's screen, handler or display code does not reach Paints by itself — port it
  by hand, with markers.
- The **A923 price read exists twice**: `ZCL_PP_FCST=>READ_PRICES` (private, quarterly and
  monthly) and `ZCL_PP_FCST_PNT=>READ_PRICES` (annual). A change to the price rule goes into both.
- `ENRICH` **overwrites** the engine's `MVGR1..5` (+ texts) and `Mnn_TON` for Paints rows, and
  those values flow into the shared tables on save. Adhesive rows are untouched (different
  program).
- Material groups come from **sales org 4000, first distribution channel**. A material with no
  sales view in 4000 shows blank groups and blank qty per carton; it is not an error.
- Pack size: a material usually has several alternative units; the rule (L, ML, KG, G in
  that order, never the base unit) is an **assumption** until M5 is answered. Unit codes are
  the internal `MSEHI` values (`G`, not `GM`).
- The forecast number (`ZPPFCST`) is **shared** with Adhesive's sequence and across the three
  shared tables in any save order.
- MSL on the monthly business-forecast upload is stored and added into `TOTAL_QTY` by the
  engine even for a Paints plant; Paints users leave column 6 blank.
- The Legacy Data checkbox is drawn only when TVARVC `ZPP_FCST_LEGACY` = `X`; with it blank
  the screen is exactly Sheet1. Legacy-user authorisation would need a `ZPPT_FCST_CFG` row.
- SLG1 shows a run's warnings (no category, load factor defaulted, superseded code shown under
  its successor, material type variable missing). Message 018 (configuration missing) is no
  longer raised for Paints.
- `kpmg/zpp_forecast_v2/zcl_pp_fcst_nocomments.abap` and `zpp_forecast_v2_nocomments.abap` are
  comment-stripped paste copies that drift; `src/` is the only source of truth.
- `ZPP_FORECAST_PAINTS`'s header still says `Transport <TR>`; the TR is DEVK930479. Cosmetic;
  change it on the next real edit, not on its own.

---

## 9. Assumptions the build stands on (greppable as `ASSUMPTION`)

| Where | Assumption | Query |
|---|---|---|
| `ZDO_BRAND` | brand is free text, 40 characters | M2 |
| `ZPP_FORECAST_UPLOAD` `check_indicator` | codes DIS, TIN; DIS ART / DISART / TINTING accepted and mapped | M3 |
| `ZCL_PP_FCST_PNT` `GC_VKORG` | 4000 hardcoded as FS row 91 states (Arnav, 22/10/26); groups 1–5 and qty per carton read from that view, overwriting the engine's | M4 |
| `READ_PACK_SIZES` | unit preference L, ML, KG, G; internal codes; UMREN ÷ UMREZ; ML, G ÷ 1000 | M5 |
| `READ_PRICES` | A923 holds the Paints DPL; material alone, latest DATAB, lowest KOPOS | Q1 |
| `READ_SALES_VIEW` | `MVKE-AUMNG` ("minimum order quantity") is the quantity per carton | Q2 |
| `ENRICH` | tonnage on gross weight ÷ 1000, on the priced quantity, all three modes | Q4 |
| `ZPP_FORECAST_PAINTS` | annual list without history columns (Sheet1); hidden, reachable via Change Layout | M7 |
| `ZPP_FORECAST_PAINTS` | legacy switch is TVARVC `ZPP_FCST_LEGACY`, the Adhesive one | — |
| shared engine | per-month additional via the change upload, Month 1/2/3 within the quarter | M6 |
| design | one set of shared tables for both divisions; a plant is never in both | M1 |

The seventeen queries in one line each — the full wording, FS references and impact are in
`docs/ZFORECAST_Paints_Assumptions_and_Queries.md` §1 and §3:

| # | Question |
|---|---|
| M1 | One set of tables, one number range, one auth object for both divisions; a Paints plant is never an Adhesive plant? |
| M2 | Brand table name, key, brand length, free text or fixed list? |
| M3 | Indicator codes DIS / TIN and the long text of "DIS ART"? |
| M4 | 4000 is the Paints sales organisation for every MVKE read? (built hardcoded) |
| M5 | Which MARM unit gives the pack size when several exist; unit codes? |
| M6 | Additional forecast per month (as Adhesive, Month 1/2/3 on the change upload)? |
| M7 | Annual list: Adhesive columns plus Paints columns, or Paints columns only? (built Sheet1-only, rest via layout) |
| Q1 | A923 is the Paints DPL table; which condition type? |
| Q2 | `MVKE-AUMNG` is the quantity per carton? |
| Q3 | Crore column on the monthly list? (built: yes, `M4_CR`) |
| Q4 | Tonnage on gross weight ÷ 1000 in all modes? |
| Q5 | Material groups 3 and 4 dropped from the Paints lists? (hidden, via layout) |
| Q6 | Brand column on the final report? (not built) |
| Q7 | Material type restriction FERT, HAWA applies to Paints? |
| Q8 | SM30 view `ZPPV_BRAND` wanted? |
| Q9 | Final report: Month and Quarter cannot both be mandatory; both optional as built? |
| Q10 | FS to be versioned, completed and signed off |

---

## 10. Open items, in priority order

1. **Confirm the sales-org-4000 class is in the system** (`GC_VKORG` in SE24; see §2).
2. **Functional test** — hand `docs/ZFORECAST_Paints_Test_Handover.docx` to the functional
   consultant; section D is the 14-step sequence, F the 22 cases, H the eight decisions the
   test should settle.
3. **Queries M1–M7, Q1–Q10** — unanswered; each assumption above is one of them.
4. **Restore the authorisation checks** in `ZCL_PP_FCST_UTIL` (bypassed 07/09/26) before any
   release — one change, both divisions (`kpmg/zpp_forecast_v2/ISSUES.md`, entry of 03/09/26
   "AUTHORITY CHECKS DISABLED").
5. Delete `ZPP_FORECAST_PAINTS_UPL` in SE38.
6. Verify SE93 `ZFCST_PAINTS`; create it if missing (`MANUAL_STEPS.md` §2).
7. Optional: `ZDO_MTS_MTO` fixed values DIS / TIN (SE11); SE54 views `ZPPV_BRAND` and on the
   Paints tables.
8. Release DEVK930479 when the test passes — manual, Arnav's or the lead's call.
9. Fix the FS: the 28 defects F01–F28 (A&Q §8), in particular F19 (`SHKZG` wording selects
   returns only) and F04 (1100 vs 4000).

---

## 11. People, format, sign-off

Mails to the functional consultant or the client lead: three to six lines, professional, no
flourish. Sign-off used so far:

    Thanks & Regards,
    Arnav Johri | Associate Consultant | Diligent Global

Use your own. Drafting with Claude is fine; sending stays manual.

Issue log entry format (`ISSUES.md`): `## DD/MM/YY — <title>`, then what was asked, the root
cause, what changed (object, FORM/method, line count), files, ZIP, TR.
