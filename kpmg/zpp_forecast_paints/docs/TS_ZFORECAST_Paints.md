# TS — ZFORECAST Paints (WRICEF ID-2B)

## 1. Document control

| Item | Detail |
|-------------------------|---------------------------------------------------------------------------|
| Version | 1.0, 19.10.2026 |
| Author | Arnav Johri, Associate Consultant, Diligent Global |
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | PP / SD |
| Related FS | `Forecast_Template-Paints_1.xlsx`, received 19.10.2026 (no version inside the file). Sheet1 taken as the authority |
| Companion documents | `ZFORECAST_Paints_Assumptions_and_Queries.docx` v2 (queries M1–M7, Q1–Q10, FS defects F01–F28); `00_TECHNICAL_OBJECTS.md` |
| Status | Built, not yet imported or tested. Queries M1–M7 unanswered; built on the assumptions listed in section 7 |

## 2. Purpose and background

The Paints division needs the same annual, quarterly and monthly forecasting that was built for
Adhesive (ZFORECAST, 20.08.2026 template), with a different list layout: brand, plant name,
pack size, dealer price (DPL), quantity per carton, gross weight, volume in kilolitres and value
in crores per forecast month, tonnage on gross weight, and two more MTS/MTO indicator values.
The arithmetic, the uploads, the save layouts and the tables are the Adhesive ones, and the FS
names the Adhesive tables as its own.

The Adhesive objects are in functional testing and work. **None of them is changed.** Paints
is built as new objects that call the Adhesive engine and share its tables.

## 3. Objects affected

| Object | Type | New / changed | Package | TR |
|-----------------------------|--------------|------------|------------------------|----------|
| `ZPP_FORECAST_PAINTS` | Package | New | — | |
| `ZDO_BRAND` | Domain | New | `ZPP_FORECAST_PAINTS` | |
| `ZDE_BRAND` | Data element | New | `ZPP_FORECAST_PAINTS` | |
| `ZPPT_BRAND` | Table | New | `ZPP_FORECAST_PAINTS` | |
| `ZCL_PP_FCST_PNT` | Class | New | `ZPP_FORECAST_PAINTS` | |
| `ZPP_FORECAST_PAINTS` | Report | New | `ZPP_FORECAST_PAINTS` | |
| `ZPP_FORECAST_PAINTS_UPL` | Report | New | `ZPP_FORECAST_PAINTS` | |
| `PF_STATUS` of `ZPP_FORECAST_PAINTS` | GUI status | New, manual SE41 | | |
| `ZFCST_PAINTS`, `ZFCST_PAINTS_UPL` | Transactions | New, manual SE93 | | |
| `ZPPV_BRAND` | SM30 view | New, manual SE54, optional | | |
| `ZPPT_FCST_CFG` rows for Paints plants | Configuration | Manual SM30 | | |
| `ZDO_MTS_MTO` | Domain | Fixed values DIS, TIN — manual SE11, optional, not in the ZIP | `ZPP_FORECAST` | |
| `ZCL_PP_FCST`, `ZCL_PP_FCST_UTIL`, `ZPP_FORECAST`, `ZPP_FORECAST_UPLOAD`, `ZPP_FORECAST_REPORT`, the eight `ZPPT_*` tables, `ZPPFCST`, `ZPP_FCST` | | **No change** — used as they are | `ZPP_FORECAST` | |

## 4. Detailed design

### 4.1 `ZPPT_BRAND` — brand per plant and material

Key `MANDT`, `WERKS`, `MATNR`; `BRAND` (`ZDE_BRAND`, domain `ZDO_BRAND` CHAR 40); `ERNAM`,
`ERDAT`, `AENAM`, `AEDAT`. Delivery class A, data class APPL0, size category 0, not buffered.
Loaded by the brand upload (4.3); read by `ZCL_PP_FCST_PNT`.

### 4.2 `ZCL_PP_FCST_PNT` — the Paints columns

Public type `TY_ALV` = `ZCL_PP_FCST=>TY_ALV` (INCLUDE TYPE) plus `NAME1`, `BRAND`,
`PACK_SIZE`, `PACK_UNIT`, `QTY_CARTON`, `BRGEW`, `M01_KL…M12_KL`, `M01_CR…M12_CR`,
`M4_KL…M6_KL`, `M4_CR…M6_CR`. Public method `ENRICH( iv_mode, ct_alv, ct_msg )`.

`ENRICH` collects the plants, materials and plant+material pairs of the run, then reads once
each (all guarded by `IS NOT INITIAL`, `FOR ALL ENTRIES` on de-duplicated drivers):

| Read | Source | Rule |
|----------------------|------------------------------------------------|------------------------------|
| `READ_CONFIG` | `ZPPT_FCST_CFG` | `VKORG` per plant. Missing row → message 018 (W) in the run log, 4000 used |
| `READ_NAMES` | `T001W` | `NAME1` |
| `READ_BRANDS` | `ZPPT_BRAND` | by plant and material |
| `READ_MARA` | `MARA` | `MEINS`, `BRGEW`, `GEWEI` |
| `READ_PACK_SIZES` | `MARM` | units L, ML, KG, G only; first in that order that is not the base unit; pack = `UMREN` ÷ `UMREZ`; ML and G ÷ 1000 |
| `READ_CARTONS` | `MVKE` | `AUMNG` where `MVGR1` not blank, `VKORG` in the configured sales organisations |
| `READ_PRICES` | `A923` → `KONP` | annual mode only; material alone, latest `DATAB`, lowest `KOPOS`, `KBETR`. Same rule as `ZCL_PP_FCST=>READ_PRICES` |

Per row, then: `NAME1`, `BRAND`, `BRGEW`, `PACK_SIZE`/`PACK_UNIT`, `QTY_CARTON` (sales org of the
row's plant), `PRICE` (annual). Per forecast month, on the quantity the engine prices:

| Mode | Quantity | Columns written |
|----------------------|------------------------------------------------|------------------------------|
| Annual | `Mnn_FCST` | `Mnn_TON` = qty × `BRGEW` ÷ 1000 · `Mnn_KL` = qty × pack ÷ 1000 · `Mnn_CR` = `PRICE` × qty ÷ 1,00,00,000 |
| Quarterly | `Mn_FCST_FINAL` (forecast + additional) | `Mn_TON`, `Mn_KL`, `Mn_CR`, n = 4, 5, 6 |
| Monthly | `TOTAL_QTY` (final + additional + MSL) | `M4_TON`, `M4_KL`, `M4_CR` |

`Mnn_TON` overwrites the engine's net-weight tonnage. Because the Paints program hands the rows
back to `ZCL_PP_FCST=>SAVE` after enrichment, the quarterly save stores the gross-weight tonnage
in `ZPPT_FCST_QT-M4_TON…M6_TON` for Paints rows.

### 4.3 `ZPP_FORECAST_PAINTS_UPL` — all nine Paints uploads

`ZPP_FORECAST_UPLOAD` copied whole (repo copy activated 23/09/26: eight radio buttons, each
with its own Download Template button, Excel through `CL_FDT_XL_SPREADSHEET`, CSV, tab text,
header detection, per-row result list with traffic light, commit of good rows only) with
three additions: a ninth radio button Brand, `FORM DO_BRAND`, and `FORM CHECK_INDICATOR`
replacing the MTS/MTO-only check in `FORM DO_CATEGORY`. Tracking, exclusion, legacy history,
business forecast and forecast change are the Adhesive routines unchanged and write the same
tables. A Paints user never needs ZFCST_UPL.

| Type | Template | Columns | Checks | Writes |
|------------|----------------------|----------------------------|------------------------|--------------|
| CAT | `ZFCST_Paints_Product_Category.csv` | Plant, Material, Product Category, Load Factor, MTS/MTO | plant+material in MARC and authorised (activity 02); category mandatory; load factor > 0; indicator MTS, MTO, DIS, TIN, DIS ART, TINTING or blank (`FORM CHECK_INDICATOR`) | `ZPPT_PROD_CAT`, overwrite or insert, created-by kept |
| BRD | `ZFCST_Paints_Brand.csv` | Plant, Material, Brand | plant+material as above; brand mandatory | `ZPPT_BRAND`, overwrite or insert |

Template headings are the DDIC labels of the fields loaded (`FORM FIELD_LABEL`), as on Adhesive.

### 4.4 `ZPP_FORECAST_PAINTS` — generation

Selection screen, validations, value helps, toolbar handler (Save, Select all, Deselect all,
Export), application log (SLG1 object `ZPP_FCST`, subobject `GENERATE`, external number
`PAINTS <mode> <FY> <user>`), layout key (`SY-REPID` + mode) and display-mode switch
`GV_CONTAINER` are those of `ZPP_FORECAST`.

`FORM GENERATE`: `ZCL_PP_FCST=>GENERATE_ANNUAL / _QUARTERLY / _MONTHLY` into `GT_ENG`; rows
copied one by one (`MOVE-CORRESPONDING`) into `GT_ALV` of the Paints row type;
`ZCL_PP_FCST_PNT=>ENRICH`. `LCL_HANDLER=>SAVE_SELECTED`: marks the selected rows, rebuilds the
engine table row for row, calls `ZCL_PP_FCST=>SAVE`, copies `FCST_NO`, `LIGHT`, `STATUS`,
`MESSAGE` back by index, reveals `FCST_NO` and `MESSAGE`.

`FORM VISIBLE_COLUMNS` returns two lists: `CT_SHOW` (drawn, Sheet1 order) and `CT_OPT`
(hidden, offered by Change Layout). `FORM SETUP_COLUMNS` sets the rest technical, positions the
shown columns, and heads them with Sheet1's wording and the financial calendar
(`FORM ANNUAL_HEADINGS`, `FORM MONTH_HEADINGS`). Column lists per mode are in
`00_TECHNICAL_OBJECTS.md` §4.

### 4.5 Manual steps

See `00_TECHNICAL_OBJECTS.md` §1 "Manual": SE41 copy of `PF_STATUS`, SE93 ×2, SM30 config rows
for the Paints plants, optional SE54 `ZPPV_BRAND`, optional SE11 fixed values on `ZDO_MTS_MTO`.

## 5. Requirement mapping

| FS requirement (Sheet1) | Implemented by |
|----------------------------|------------------------------------------------------------------------|
| Annual: LY month × growth; quarterly: max(LY quarter, L3M) × growth, max with business forecast, month split; monthly: max(LY month, L3M avg × growth), max with business forecast | `ZCL_PP_FCST`, shared, unchanged |
| Product category and % by user (B) | `ZPPT_PROD_CAT`; Paints upload type CAT |
| Skip materials (D) | `ZPPT_MAT_EXCL`; ZFCST_UPL type EXC |
| Forecast number (E) | `ZPPFCST` via `ZCL_PP_FCST=>SAVE` |
| MTS / MTO maintenance (F), four values | `ZPPT_PROD_CAT-MTS_MTO`; Paints upload |
| Old code replaced by new (G) | `ZPPT_MAT_TRACK`; ZFCST_UPL type TRK; engine absorption |
| Sales forecast upload (G/J), change upload (I), last-3-years history (J) | ZFCST_UPL types BUSQ/BUSM, CHGQ/CHGM, HIST |
| Brand, plant name, pack size, DPL, qty/carton, gross weight, KL, crores, tonnage columns | `ZCL_PP_FCST_PNT`, `ZPP_FORECAST_PAINTS` |
| Brand upload | `ZPPT_BRAND`, Paints upload type BRD |
| Final report, Consolidated | ZFCST_RPT, shared, unchanged |

## 6. Test scenarios

| # | Scenario | Input | Expected |
|--------|--------------------------------------------------|--------------------|----------------------|
| 1 | Brand upload, test run | 3 rows, one material not in the plant | 2 "Would create", 1 "Rejected: Material … is not extended to plant …"; nothing written |
| 2 | Brand upload, real run, then again | same file twice | first run Created ×2; second run Changed ×2, `ERNAM`/`ERDAT` unchanged, `AENAM`/`AEDAT` updated |
| 3 | Category upload with DIS ART and TINTING | indicator column "DIS ART", "TINTING", "MTS", "xyz" | stored DIS, TIN, MTS; "xyz" rejected with the indicator message |
| 4 | Annual run, Paints plant with config row | plant, FY 2026-2027 | lead block incl. brand, pack size, DPL, qty/carton; 12 forecast, 12 KL, 12 crore columns; no history columns; history reachable via Change Layout |
| 5 | Annual run, plant without config row | | list produced; SLG1 log carries message 018 for the plant; MVKE reads on 4000 |
| 6 | Pack size | material with L and CAR units, base EA, UMREZ 1 UMREN 4 on L | pack size 4.000, unit L; KL = qty × 4 ÷ 1000 |
| 7 | Pack size in ML | material with ML only, UMREN 500 | pack size 0.500 |
| 8 | Quarterly run, Q2, Tonnage ticked | | per month: forecast, additional, final, KL, Cr, tonnage; tonnage = final × BRGEW ÷ 1000; Gross Weight column at the end |
| 9 | Quarterly save | select rows, Save | forecast number and message revealed; `ZPPT_FCST_QT` row carries `M4_TON` on gross weight |
| 10 | Monthly run, period 6 | | `BUS_FCST_ADD`, `TOTAL_QTY`, `M4_KL`, `M4_CR` for the one month |
| 11 | DPL on annual | material with two A923 records | the latest `DATAB` wins; crores = DPL × forecast ÷ 1e7 |
| 12 | No PF_STATUS yet | run before SE41 | standard toolbar, status-bar note, no dump |
| 13 | Adhesive regression | run ZFCST on an Adhesive plant after the import | unchanged — no Adhesive object is in the transport |

## 7. Open points

Queries M1–M7 and Q1–Q10 of the Assumptions and Queries document are unanswered; the build
stands on the assumptions in `00_TECHNICAL_OBJECTS.md` §5 and the `ASSUMPTION` comments in
the code. In particular: the pack-size unit rule (M5), the brand length (M2), the indicator
codes (M3), the Paints sales organisation (M4), tonnage on gross weight in all modes (Q4), the
crore column on the monthly list (Q3), and whether a plant can carry both divisions (M1). The
ZIP has not been imported on this landscape yet; the paste order is in
`00_TECHNICAL_OBJECTS.md` §2.
