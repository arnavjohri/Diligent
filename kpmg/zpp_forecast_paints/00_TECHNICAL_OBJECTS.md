# ZFORECAST (Paints) — Technical Objects

Astral / UDAY / Paints (WRICEF ID-2B) · built to `Forecast_Template-Paints_1.xlsx` received
19.10.2026, **Sheet1 taken as the authority**; the mode sheets fill in what Sheet1 abbreviates.
Transport DEVK930479 (UDAYABAP03, UDAY: PP: 2B: Forcast Paints), not released.
Author Arnav Johri. First build 19.10.2026; brand upload moved into the Adhesive upload and
Paints forecast tables reshaped to the displayed list on 22.10.2026.

**Rule applied:** the Adhesive engine `ZCL_PP_FCST`, its helper class, `ZPP_FORECAST`,
`ZPP_FORECAST_REPORT` and the eight shared tables are not changed. The one Adhesive object
edited is `ZPP_FORECAST_UPLOAD`, on Arnav's instruction of 22/10/26, with change markers.

---

## 1. Object inventory

### New — package `ZPP_FORECAST_PAINTS`

| Type | Name | Description |
|---|---|---|
| Package | `ZPP_FORECAST_PAINTS` | ZFORECAST Paints - forecasting |
| Domain | `ZDO_BRAND` | CHAR 40 (**assumption**, query M2 unanswered) |
| Domain | `ZDO_FCST_KL` | DEC 13,3 — pack size, qty per carton, volume in KL |
| Domain | `ZDO_FCST_CR` | DEC 13,4 — value in crores |
| Data element | `ZDE_BRAND` | Brand |
| Data element | `ZDE_PACK_SIZE`, `ZDE_QTY_CARTON`, `ZDE_FCST_KL` | on `ZDO_FCST_KL` |
| Data element | `ZDE_FCST_CR` | on `ZDO_FCST_CR` |
| Table | `ZPPT_BRAND` | Key MANDT, WERKS, MATNR · BRAND · audit. Delivery class A, APPL0, size 0 |
| Table | `ZPPT_PNT_FCST_YR` | **Paints annual forecast = the ZFCST_PAINTS annual list.** Key WERKS, MATNR, FYEAR. 73 fields, see §4 |
| Table | `ZPPT_PNT_FCST_QT` | **Paints quarterly forecast = the quarterly list.** Key WERKS, MATNR, GJAHR, QUARTER. 58 fields |
| Table | `ZPPT_PNT_FCST_MN` | **Paints monthly forecast = the monthly list.** Key WERKS, MATNR, GJAHR, PERIOD. 45 fields |
| Class | `ZCL_PP_FCST_PNT` | `ENRICH`: the Paints columns on top of `ZCL_PP_FCST=>TY_ALV` — plant name, brand, pack size, DPL for annual, qty per carton, gross weight, tonnage on gross weight, KL and crores per month. `SAVE_PAINTS`: the saved rows into the three Paints tables |
| Report | `ZPP_FORECAST_PAINTS` | Generation, 3 radio modes, Sheet1 layouts, Save into the shared tables through the engine and into the Paints tables — tcode `ZFCST_PAINTS` |

### Changed — package `ZPP_FORECAST` (Adhesive), with markers `By Arnav on 22/10/26`

| Object | Change |
|---|---|
| `ZPP_FORECAST_UPLOAD` (ZFCST_UPL) | Ninth radio button **Brand** (Plant, Material, Brand into `ZPPT_BRAND`, `FORM DO_BRAND`); the product-category indicator accepts **MTS, MTO, DIS, TIN** and the long forms DIS ART / TINTING (`FORM CHECK_INDICATOR` in place of the MTS/MTO-only check, old lines commented). Selection text `P_BRD` added. Paints users use ZFCST_UPL for all nine uploads |

Withdrawn on 22/10/26: `ZPP_FORECAST_PAINTS_UPL` (the separate Paints upload of 19/10). It
was imported in DEV on 19/10; delete it in SE38 when convenient (optional), do not create its
transaction.

### Shared with Adhesive — used as they are, not in any ZIP

`ZPPT_PROD_CAT`, `ZPPT_MAT_TRACK`, `ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST`, `ZPPT_FCST_CFG`,
`ZPPT_FCST_YR`, `ZPPT_FCST_QT`, `ZPPT_FCST_MN`; number range `ZPPFCST`; auth object `ZPP_FCST`;
message class `ZPP_FCST` (001–026, nothing added); `ZCL_PP_FCST`; `ZCL_PP_FCST_UTIL`;
`ZPP_FORECAST` (ZFCST); `ZPP_FORECAST_REPORT` (ZFCST_RPT) as the Paints final report.

### Where a Paints forecast is saved — two writes, by design

`ZCL_PP_FCST=>SAVE` (unchanged) draws the forecast number and writes the shared
`ZPPT_FCST_YR` / `_QT` / `_MN` exactly as for Adhesive. `ZCL_PP_FCST_PNT=>SAVE_PAINTS` then
writes the same rows, shaped as the displayed list, into `ZPPT_PNT_FCST_YR` / `_QT` / `_MN`.
The shared write cannot be dropped without changing the engine: it reads the business
forecast, the additional quantities, MSL and the stored price back from the shared tables at
generation, the change upload requires the shared row, the forecast number is shared across
the three tables through them, and ZFCST_RPT reads them. Nothing reads the Paints tables yet.

### Manual — abapGit never carries these (detail in `MANUAL_STEPS.md`)

| # | Transaction | What |
|---|---|---|
| 1 | SE41 | GUI status `PF_STATUS` of `ZPP_FORECAST_PAINTS`: copy from `ZPP_FORECAST` / `PF_STATUS`, or from `SAPLSALV_METADATA_STATUS` / `SALV_STANDARD` plus ZSAVE, ZSELALL, ZDESEL, ZEXCEL |
| 2 | SE93 | `ZFCST_PAINTS` → `ZPP_FORECAST_PAINTS`, screen 1000 |
| 3 | SM30 `ZPPV_FCST_CFG` | Not needed since 22/10/26 (VKORG 4000 hardcoded in `ZCL_PP_FCST_PNT`); only for a legacy TVARVC name |
| 4 | SE54, optional | `ZPPV_BRAND` on `ZPPT_BRAND`; views on the three Paints forecast tables only if hand editing is wanted |
| 5 | SE11, optional | `ZDO_MTS_MTO` fixed values DIS "Dis Art", TIN "Tinting" — only for SM30 maintenance of categories; the upload writes the codes regardless |
| 6 | SE38, optional | Delete `ZPP_FORECAST_PAINTS_UPL` |

---

## 2. Import — two delta ZIPs, one per package

| ZIP | Repo / package | Contents |
|---|---|---|
| `kpmg/zpp_forecast_v2/ZPP_FORECAST_UPLOAD_22-10-26_delta.zip` | the existing offline repo on `ZPP_FORECAST` | `zpp_forecast_upload.prog.abap` + `.xml`, package.devc, `.abapgit.xml` — nothing else, so the pull touches only this program |
| `kpmg/zpp_forecast_paints/ZPP_FORECAST_PAINTS_22-10-26_delta.zip` | the offline repo on `ZPP_FORECAST_PAINTS` | 2 domains, 4 data elements, 3 Paints forecast tables, `ZCL_PP_FCST_PNT`, `ZPP_FORECAST_PAINTS` (abap + xml each), package.devc, `.abapgit.xml` |

`ZABAPGIT_STANDALONE` → open the repo → Import ZIP → the stage shows exactly the objects
above as changed or new → Pull. **Before pulling ZIP A, open the diff of
`ZPP_FORECAST_UPLOAD` in the stage view: it must show only the 22/10/26 brand and indicator
lines. Any other difference means the running copy has edits the repo does not have — stop and
send the SE80 download.** No download of this program has been supplied since 03/09/26.

`ZPP_FORECAST_PAINTS.zip` (18 files) is the whole Paints package, rebuilt from `src/`, for a
fresh system. The table XMLs are generated by `tools/mktables.py` from the Adhesive table
XML's blocks; the upload change by `tools/mkupl_adhesive.py` with every anchor asserted once.

---

## 3. What is reused and what was built — per Sheet1 requirement

| Sheet1 | Built as |
|---|---|
| 1.1 Annual A–H, 1.2 Quarterly A–J, 1.3 Monthly A–J (arithmetic, history, categories, exclusions, tracking, forecast number, MTS/MTO) | `ZCL_PP_FCST` unchanged, called from `ZPP_FORECAST_PAINTS` |
| Selection screens (Plant, Material, FY, Quarter / Month / Date, Tonnage Wise) | Copied from `ZPP_FORECAST`. Legacy checkbox drawn only when TVARVC `ZPP_FCST_LEGACY` is set — with it blank the screen is exactly Sheet1 |
| MFG. PLANT NAME | `T001W-NAME1` |
| BRAND | `ZPPT_BRAND`, blank when not maintained |
| MTS / MTO / DIS ART / TINTING | `ZPPT_PROD_CAT-MTS_MTO`, codes MTS MTO DIS TIN; ZFCST_UPL category upload accepts the four (and the long forms) |
| MATERIAL GROUP 1, 2, 5 · MATERIAL GROUP | `ZCL_PP_FCST_PNT` re-reads MVKE in sales org 4000 and TVM1T–TVM5T, overwriting the engine's groups; `MATKL` from the engine; groups 3 and 4 hidden, reachable via Change Layout |
| PACK SIZE | `MARM` — first of L, ML, KG, G the material carries that is not its base unit; UMREN ÷ UMREZ; ML and G ÷ 1000. **Assumption** (query M5). `PACK_UNIT` via layout |
| DPL | Engine price for quarterly and monthly; the same A923 → KONP read inside `ZCL_PP_FCST_PNT` for annual |
| QTY / CARTON | `MVKE-AUMNG` of sales org 4000 (hardcoded), where `MVGR1` is not blank |
| Forecast Qty (EA) per month | Engine `Mnn_FCST` (annual), `Mn_FCST` / additional / `Mn_FCST_FINAL` (quarterly), `TOTAL_QTY` (monthly) |
| Volume in KL per month | quantity × pack size ÷ 1000 — `Mnn_KL`, `M4/5/6_KL` |
| Value in Crores per month | DPL × quantity ÷ 1,00,00,000 — `Mnn_CR`, `M4/5/6_CR` |
| Tonnage Wise (gross weight) | quantity × `MARA-BRGEW` ÷ 1000 written into the engine's `Mnn_TON` / `M4–6_TON` before display and save; `BRGEW` column shown with it |
| Upload: category (four indicator values), brand | ZFCST_UPL, changed 22/10/26 |
| Upload: tracking, exclusion, last-year history, sales forecast, forecast change | ZFCST_UPL, unchanged types |
| Save (annual, quarterly, monthly) as displayed | `ZCL_PP_FCST=>SAVE` into the shared tables, then `ZCL_PP_FCST_PNT=>SAVE_PAINTS` into `ZPPT_PNT_FCST_YR` / `_QT` / `_MN`, same number, same key |
| Final Report / Consolidated | ZFCST_RPT, shared, unchanged |

The quantity behind KL, crores and tonnage is the one the engine prices: the month's final
(forecast + additional) in quarterly, the month's total (final + additional + MSL) in monthly,
the month's forecast in annual.

---

## 4. The Paints tables = the displayed list, column for column

Every table starts with the key and `FCST_NO`, then the lead block every Paints list shows
(`NAME1 BRAND MAKTX MTS_MTO MVGR1_TXT MVGR2_TXT MVGR5_TXT MATKL PACK_SIZE PACK_UNIT PRICE
QTY_CARTON`), then the mode's columns in list order, then `BRGEW` and the tonnage columns,
then `ERNAM ERDAT AENAM AEDAT`. `MEINS`, `WAERS` and `GEWEI` are in each table because the
quantity, price and weight fields need them as unit references; they are not list columns.
Material groups are stored as the descriptions the list shows (`BEZEI20`).

| Table | Mode columns |
|---|---|
| `ZPPT_PNT_FCST_YR` | `M01_FCST…M12_FCST` · `M01_KL…M12_KL` · `M01_CR…M12_CR` · `GEWEI BRGEW` · `M01_TON…M12_TON` |
| `ZPPT_PNT_FCST_QT` | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY` · per month `Mn_FCST BUS_FCST_ADDn Mn_FCST_FINAL Mn_KL Mn_CR Mn_TON` · `GEWEI BRGEW` |
| `ZPPT_PNT_FCST_MN` | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY BUS_FCST_ADD TOTAL_QTY M4_KL M4_CR M4_TON` · `GEWEI BRGEW` |

Not stored (not displayed): the annual history months and totals, material groups 3 and 4,
net weight, the engine's value columns, MSL, REASON. They remain in the shared tables.

Hidden but offered by Change Layout on the list: `PACK_UNIT MVGR3_TXT MVGR4_TXT MEINS NTGEW
GEWEI`, the annual history months, `LY_TOTAL`, `FCST_TOTAL`, `PROD_CAT`/`LOAD_FCT` on annual,
`TOTAL_VAL` (quarterly), `L3M_AVG MSL M4_VAL` (monthly), `BRGEW` when tonnage is off.
`FCST_NO` and `MESSAGE` appear after Save. Headings follow Sheet1's wording and the financial
calendar: `Q2 Jul-26 Forecast Qty`, `Q2 Jul-26 Volume in KL`, `Jul-26 additional`,
`Jul-26 final forecast`, `Jul-26 KL`, `Jul-26 in Cr`, `Jul-26 tonnage`.

---

## 5. Assumptions carried into the code (greppable as `ASSUMPTION`)

| Where | Assumption | Query |
|---|---|---|
| `ZDO_BRAND` | Brand is free text, 40 characters | M2 |
| `ZPP_FORECAST_UPLOAD` `CHECK_INDICATOR` | Indicator codes DIS and TIN; long forms DIS ART / TINTING accepted | M3 |
| `ZCL_PP_FCST_PNT=>GC_VKORG` | 4000 hardcoded as FS row 91 states (Arnav, 22/10/26); material groups 1–5 and qty per carton read from that sales view, overwriting the engine's groups | M4 |
| `ZCL_PP_FCST_PNT=>READ_PACK_SIZES` | Unit preference L, ML, KG, G; codes as internal MSEHI (`G` not `GM`); UMREN ÷ UMREZ | M5 |
| `ZCL_PP_FCST_PNT=>READ_PRICES` | A923 holds the Paints DPL; material alone, latest DATAB, lowest KOPOS | Q1 |
| `ZCL_PP_FCST_PNT=>READ_SALES_VIEW` | `MVKE-AUMNG` is the quantity per carton; first distribution channel of 4000 when there are several | Q2 |
| `ZCL_PP_FCST_PNT=>ENRICH` | Tonnage on gross weight ÷ 1000 in all three modes, on the priced quantity | Q4 |
| `ZPP_FORECAST_PAINTS` | Annual list without history columns (Sheet1); they stay reachable via layout | M7 |
| `ZPP_FORECAST_PAINTS` | Legacy switch is TVARVC `ZPP_FCST_LEGACY`, the Adhesive one | — |
| shared engine | Per-month additional via the ZFCST_UPL change upload, Month 1/2/3 within the quarter | M6 |

---

## 6. Known duplication

The A923 price read (`READ_PRICES`, ~40 lines) exists in `ZCL_PP_FCST` and again in
`ZCL_PP_FCST_PNT`, because the engine's copy is private and the engine is not changed. The
upload duplication of 19/10 is gone: the Paints uploads live in `ZPP_FORECAST_UPLOAD`.
