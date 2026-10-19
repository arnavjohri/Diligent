# ZFORECAST (Paints) — Technical Objects

Astral / UDAY / Paints (WRICEF ID-2B) · built to `Forecast_Template-Paints_1.xlsx` received
19.10.2026, **Sheet1 taken as the authority**; the mode sheets fill in what Sheet1 abbreviates.
Author Arnav Johri, 19.10.2026.

**Standing rule applied: no Adhesive program, class, table or message is changed.** Paints
calls `ZCL_PP_FCST` / `ZCL_PP_FCST_UTIL` and reads and writes the eight `ZPPT_*` tables as
they are. Everything Paints-specific is a new object in its own package.

---

## 1. Object inventory

### New — in `src/`, shipped by `ZPP_FORECAST_PAINTS.zip`

| Type | Name | Description |
|---|---|---|
| Package | `ZPP_FORECAST_PAINTS` | ZFORECAST Paints - forecasting |
| Domain | `ZDO_BRAND` | CHAR 40 (**assumption**, query M2 unanswered) |
| Domain | `ZDO_FCST_KL` | DEC 13,3 — pack size, qty per carton, volume in KL |
| Domain | `ZDO_FCST_CR` | DEC 13,4 — value in crores |
| Data element | `ZDE_BRAND` | Brand |
| Data element | `ZDE_PACK_SIZE`, `ZDE_QTY_CARTON`, `ZDE_FCST_KL` | on `ZDO_FCST_KL` |
| Data element | `ZDE_FCST_CR` | on `ZDO_FCST_CR` |
| Table | `ZPPT_BRAND` | Key MANDT, WERKS, MATNR · BRAND · ERNAM, ERDAT, AENAM, AEDAT. Delivery class A, APPL0, size 0 |
| Table | `ZPPT_PNT_FCST_YR` | **Paints annual forecast.** `ZPPT_FCST_YR` field for field (key WERKS, MATNR, FYEAR) plus NAME1, BRAND, PACK_SIZE, PACK_UNIT, QTY_CARTON, BRGEW, WAERS, PRICE, M01_KL…M12_KL, M01_CR…M12_CR. 92 fields |
| Table | `ZPPT_PNT_FCST_QT` | **Paints quarterly forecast.** `ZPPT_FCST_QT` field for field (key WERKS, MATNR, GJAHR, QUARTER) plus NAME1, BRAND, PACK_SIZE, PACK_UNIT, QTY_CARTON, BRGEW, M4_KL…M6_KL, M4_CR…M6_CR. 68 fields |
| Table | `ZPPT_PNT_FCST_MN` | **Paints monthly forecast.** `ZPPT_FCST_MN` field for field (key WERKS, MATNR, GJAHR, PERIOD) plus NAME1, BRAND, PACK_SIZE, PACK_UNIT, QTY_CARTON, BRGEW, WAERS, PRICE, M4_KL, M4_CR. 50 fields |
| Class | `ZCL_PP_FCST_PNT` | Paints columns on top of `ZCL_PP_FCST=>TY_ALV`: plant name, brand, pack size, DPL for annual, qty per carton, gross weight, tonnage on gross weight, KL and crores per month (`ENRICH`); and the write of the saved rows into the three Paints tables (`SAVE_PAINTS`) |
| Report | `ZPP_FORECAST_PAINTS` | Generation, 3 radio modes, Sheet1 layouts — tcode `ZFCST_PAINTS` |
| Report | `ZPP_FORECAST_PAINTS_UPL` | All nine Paints uploads — tcode `ZFCST_PAINTS_UPL`. The Adhesive upload copied whole, plus a ninth type Brand and a category indicator accepting MTS, MTO, DIS, TIN. A Paints user never needs ZFCST_UPL |

### Where a Paints forecast is saved — two writes, by design

`ZCL_PP_FCST=>SAVE` (unchanged) draws the forecast number and writes the shared
`ZPPT_FCST_YR` / `_QT` / `_MN` exactly as for Adhesive. `ZCL_PP_FCST_PNT=>SAVE_PAINTS` then
writes the same rows, with the Paints columns, into `ZPPT_PNT_FCST_YR` / `_QT` / `_MN`. The
shared write cannot be dropped without changing the engine: the engine reads the business
forecast, the additional quantities, MSL and the stored price back from the shared tables
at generation time, the change upload requires the shared row to exist, the forecast number
is shared across the three tables through them, and ZFCST_RPT reads them. The Paints tables
are the Paints output with every column the list shows; nothing reads them yet.

### Shared with Adhesive — used as they are, **not in the ZIP**

`ZPPT_PROD_CAT`, `ZPPT_MAT_TRACK`, `ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST`, `ZPPT_FCST_CFG`,
`ZPPT_FCST_YR`, `ZPPT_FCST_QT`, `ZPPT_FCST_MN` (still written, see above); number range `ZPPFCST`; auth object `ZPP_FCST`;
message class `ZPP_FCST` (001–026, nothing added); `ZCL_PP_FCST`; `ZCL_PP_FCST_UTIL`;
`ZPP_FORECAST_REPORT` (ZFCST_RPT) as the Paints final report. `ZPP_FORECAST_UPLOAD`
(ZFCST_UPL) is not needed by Paints users since 19/10/26 PM — the Paints upload carries all
its types — but writes the same tables, so a Paints row loaded through it is equally valid.

### Manual, after the import — abapGit never carries these

| # | Transaction | What | Values |
|---|---|---|---|
| 1 | SE41 | GUI status `PF_STATUS` of `ZPP_FORECAST_PAINTS` | Copy status `PF_STATUS` from program `ZPP_FORECAST` to `ZPP_FORECAST_PAINTS`, same name; or copy `SALV_STANDARD` from `SAPLSALV_METADATA_STATUS` and add ZSAVE, ZSELALL, ZDESEL, ZEXCEL to the application toolbar. Step by step in `MANUAL_STEPS.md`. Until it exists the list shows the standard toolbar without the four buttons and says so |
| 2 | SE93 | `ZFCST_PAINTS` | Report transaction, program `ZPP_FORECAST_PAINTS`, screen 1000 |
| 3 | SE93 | `ZFCST_PAINTS_UPL` | Report transaction, program `ZPP_FORECAST_PAINTS_UPL`, screen 1000 |
| 4 | SM30 `ZPPV_FCST_CFG` | One row per **Paints plant** | `VKORG` = the Paints sales organisation (FS says 4000), `TVARV_LEGACY` as for Adhesive. Without a row the run logs message 018 and uses 4000 |
| 5 | SE54 (optional, query Q8) | `ZPPV_BRAND` maintenance view on `ZPPT_BRAND` | Same pattern as `ZPPV_MAT_EXCL`. Not needed for the upload |
| 6 | SE11 (optional, query M3) | `ZDO_MTS_MTO` fixed values | Add `DIS` "Dis Art" and `TIN` "Tinting", length unchanged, no conversion. Only needed if Paints categories are also maintained through SM30 `ZPPV_PROD_CAT`; the Paints upload writes the two codes regardless. **Not in the ZIP** so nothing Adhesive is overwritten |
| 7 | STVARV | `ZPP_FORECAST_MTART` | Already exists for Adhesive (FERT, HAWA). Applies to Paints through the shared engine — query Q7 |

---

## 2. Import

```
ZABAPGIT_STANDALONE → New Offline → package ZPP_FORECAST_PAINTS (create it in the dialog,
or SE80 first, superpackage as the Adhesive one) → Import ZIP ZPP_FORECAST_PAINTS.zip → Pull
```

20 files: `.abapgit.xml`, `package.devc.xml`, 3 domains, 5 data elements, 4 tables
(`zppt_brand`, `zppt_pnt_fcst_yr`, `zppt_pnt_fcst_qt`, `zppt_pnt_fcst_mn`),
`zcl_pp_fcst_pnt.clas.abap` + `.xml`, `zpp_forecast_paints.prog.abap` + `.xml`,
`zpp_forecast_paints_upl.prog.abap` + `.xml`. abapGit orders the activation itself
(domain → data element → table → class → programs). The three forecast tables are generated
from the Adhesive ones by `tools/mktables.py`, so their XML shape and element order are the
ones that imported.

The XML shapes are copied from the Adhesive `src/` files of the same types, with `PROGDIR`
in the order `NAME, VARCL, SUBC, FIXPT, UCCHECK` and `TPOOL` items as `ID, KEY, ENTRY,
LENGTH`. The Adhesive DDIC and class XMLs imported in August; the program XMLs carry the
03/09 PROGDIR fix. This ZIP has **not** been imported anywhere yet.

**Paste fallback** (if the pull short-dumps as `kpmg/zfi_tds_cl34` did): SE11 `ZDO_BRAND`
(CHAR 40) → `ZDE_BRAND` → `ZPPT_BRAND` (fields above, technical settings APPL0 / size 0,
delivery class A) → SE24 `ZCL_PP_FCST_PNT` (source-code based, paste the `.clas.abap`) →
SE38 `ZPP_FORECAST_PAINTS` (type 1, selection texts from the `.prog.xml` TPOOL) → SE38
`ZPP_FORECAST_PAINTS_UPL` (same). The `.abap` files are complete objects, first line to last.

---

## 3. What is reused and what was built — per Sheet1 requirement

| Sheet1 | Built as |
|---|---|
| 1.1 Annual A–H, 1.2 Quarterly A–J, 1.3 Monthly A–J (arithmetic, history, categories, exclusions, tracking, forecast number, MTS/MTO, uploads) | `ZCL_PP_FCST` unchanged, called from `ZPP_FORECAST_PAINTS`; uploads through ZFCST_UPL except category and brand |
| Selection screens (Plant, Material, FY, Quarter / Month / Date, Tonnage Wise) | Copied from `ZPP_FORECAST`. Legacy checkbox present but drawn only when TVARVC `ZPP_FCST_LEGACY` is set — with it blank the screen is exactly Sheet1 |
| MFG. PLANT NAME | `T001W-NAME1` |
| BRAND | `ZPPT_BRAND`, blank when not maintained |
| MTS / MTO / DIS ART / TINTING | `ZPPT_PROD_CAT-MTS_MTO`, codes MTS MTO DIS TIN; the Paints category upload accepts the four (and the long forms DIS ART, TINTING) |
| MATERIAL GROUP 1, 2, 5 · MATERIAL GROUP | Engine (`MVGR1/2/5_TXT`, `MATKL`); groups 3 and 4 hidden, reachable via Change Layout |
| PACK SIZE | `MARM` — first of L, ML, KG, G the material carries that is not its base unit; UMREN ÷ UMREZ; ML and G ÷ 1000. **Assumption** (query M5). `PACK_UNIT` available via layout |
| DPL | Engine price for quarterly and monthly; the same A923 → KONP read inside `ZCL_PP_FCST_PNT` for annual |
| QTY / CARTON | `MVKE-AUMNG`, `MVGR1` not blank, sales org from `ZPPT_FCST_CFG` of the plant (default 4000) |
| Forecast Qty (EA) per month | Engine `Mnn_FCST` (annual), `Mn_FCST` / additional / `Mn_FCST_FINAL` (quarterly), `TOTAL_QTY` (monthly) |
| Volume in KL per month | quantity × pack size ÷ 1000 — `Mnn_KL`, `M4/5/6_KL` |
| Value in Crores per month | DPL × quantity ÷ 1,00,00,000 — `Mnn_CR`, `M4/5/6_CR` |
| Tonnage Wise (gross weight) | quantity × `MARA-BRGEW` ÷ 1000 written into the engine's `Mnn_TON` / `M4–6_TON` before display and save; `BRGEW` column shown with it |
| Upload: category | `ZPP_FORECAST_PAINTS_UPL` type CAT (four indicator values) |
| Upload: brand (Plant, Material, Brand) | `ZPP_FORECAST_PAINTS_UPL` type BRD |
| Upload: tracking, exclusion, last-year history, sales forecast Q/M, forecast change Q/M | `ZPP_FORECAST_PAINTS_UPL` types TRK, EXC, HIST, BUSQ, BUSM, CHGQ, CHGM — the Adhesive routines copied unchanged, same tables |
| Final Report / Consolidated | ZFCST_RPT, shared, unchanged |

The quantity behind KL, crores and tonnage is the one the engine prices: the month's final
(forecast + additional) in quarterly, the month's total (final + additional + MSL) in monthly,
the month's forecast in annual.

---

## 4. Column layout per mode (what is drawn, in order)

Lead block, all modes: `WERKS NAME1 BRAND MATNR MAKTX MTS_MTO MVGR1_TXT MVGR2_TXT MVGR5_TXT
MATKL PACK_SIZE PRICE QTY_CARTON`.

| Mode | Then |
|---|---|
| Annual | `M01_FCST…M12_FCST` · `M01_KL…M12_KL` · `M01_CR…M12_CR` · [Tonnage ticked: `BRGEW`, `M01_TON…M12_TON`] |
| Quarterly | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY` · per month: `Mn_FCST BUS_FCST_ADDn Mn_FCST_FINAL Mn_KL Mn_CR [Mn_TON]` · [`BRGEW`] |
| Monthly | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY BUS_FCST_ADD TOTAL_QTY M4_KL M4_CR [M4_TON BRGEW]` |

Hidden but offered by Change Layout: `PACK_UNIT MVGR3_TXT MVGR4_TXT MEINS NTGEW GEWEI`, the
annual history months `M01…M12`, `LY_TOTAL`, `FCST_TOTAL`, `PROD_CAT`/`LOAD_FCT` on annual,
`TOTAL_VAL` (quarterly), `L3M_AVG MSL M4_VAL` (monthly), `BRGEW` when tonnage is off.
`FCST_NO` and `MESSAGE` appear after Save, as on Adhesive. Everything else is technical.

Headings follow Sheet1's wording and the financial calendar: `Q2 Jul-26 Forecast Qty`,
`Q2 Jul-26 Volume in KL`, `Q2 Jul-26 Value in Crores`, `Jul-26 additional`,
`Jul-26 final forecast`, `Jul-26 KL`, `Jul-26 in Cr`, `Jul-26 tonnage`.

---

## 5. Assumptions carried into the code (greppable as `ASSUMPTION`)

| Where | Assumption | Query |
|---|---|---|
| `ZDO_BRAND` | Brand is free text, 40 characters | M2 |
| `ZPP_FORECAST_PAINTS_UPL` | Indicator codes DIS and TIN; long forms DIS ART / TINTING accepted | M3 |
| `ZCL_PP_FCST_PNT=>GC_VKORG_DEFAULT` | 4000 when the plant has no `ZPPT_FCST_CFG` row; message 018 logged | M4, M1 |
| `ZCL_PP_FCST_PNT=>READ_PACK_SIZES` | Unit preference L, ML, KG, G; codes as internal MSEHI (`G` not `GM`); UMREN ÷ UMREZ | M5 |
| `ZCL_PP_FCST_PNT=>READ_PRICES` | A923 holds the Paints DPL; material alone, latest DATAB, lowest KOPOS | Q1 |
| `ZCL_PP_FCST_PNT=>READ_CARTONS` | `MVKE-AUMNG` is the quantity per carton | Q2 |
| `ZCL_PP_FCST_PNT=>ENRICH` | Tonnage on gross weight ÷ 1000 in all three modes, on the priced quantity | Q4 |
| `ZPP_FORECAST_PAINTS` | Annual list without history columns (Sheet1); they stay reachable via layout | M7 |
| `ZPP_FORECAST_PAINTS` | Legacy switch is TVARVC `ZPP_FCST_LEGACY`, the Adhesive one | — |
| shared engine | Per-month additional via the ZFCST_UPL change upload, Month 1/2/3 within the quarter | M6 |

---

## 6. Known duplication, by design

The A923 price read (`READ_PRICES`, ~40 lines) exists in `ZCL_PP_FCST` and again in
`ZCL_PP_FCST_PNT`. `ZPP_FORECAST_PAINTS_UPL` is `ZPP_FORECAST_UPLOAD` whole (2,474 lines of
the 23/09/26 repo copy) plus the brand type and the indicator check, so **every fix to the
Adhesive upload has to be repeated in the Paints upload**; the two differ only in the header,
the ninth radio button, `FORM CHECK_INDICATOR` / `FORM DO_BRAND` and the `BRD` template
branch, so a diff between them shows exactly that. This is the price of leaving the Adhesive
code untouched.
