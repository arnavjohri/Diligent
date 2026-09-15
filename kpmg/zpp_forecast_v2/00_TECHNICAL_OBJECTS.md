# ZFORECAST (Adhesive) — Technical Objects

Astral / UDAY / Adhesive · built to `Forecast Template-Adhesive.xlsx` dated 20.08.2026
Paints (WRICEF ID-2B) out of scope.

## Renaming — forced by SAP limits

| Document name | Chars | Renamed |
|---|:--:|---|
| `ZPP_PROD_CATEGORY` / `ZPP_MATERIAL_CATEGORY` | 17 / 21 | `ZPPT_PROD_CAT` |
| `ZPP_MATERIAL_TRACKING` | 21 | `ZPPT_MAT_TRACK` |
| `ZPP_MATERIAL_EXCLUDE` | 20 | `ZPPT_MAT_EXCL` |
| `ZPP_SALES_HISTORY` | 17 | `ZPPT_SLS_HIST` |
| `ZPP_ADH_FORECAST_YEAR` | 21 | `ZPPT_FCST_YR` |
| `ZPP_ADH_FORE_QUATER` | 19 | `ZPPT_FCST_QT` |
| `ZPP_ADH_FORE_MONTH` | 18 | `ZPPT_FCST_MN` |
| `ZPP_ADHESIVE_SNRO` | 17 (max **10**) | `ZPPFCST` |

Namespace `Z*`, package `ZPP_FORECAST` — pending the package/system answer.

---

## 1. Object inventory

| Type | Name | Description |
|---|---|---|
| Package | `ZPP_FORECAST` | Adhesive forecasting |
| Table | `ZPPT_PROD_CAT` | Category, load factor, MTS/MTO |
| Table | `ZPPT_MAT_TRACK` | New / old material codes |
| Table | `ZPPT_MAT_EXCL` | Materials excluded |
| Table | `ZPPT_SLS_HIST` | Uploaded legacy sales history |
| Table | `ZPPT_FCST_YR` | Annual forecast |
| Table | `ZPPT_FCST_QT` | Quarterly forecast |
| Table | `ZPPT_FCST_MN` | Monthly forecast |
| Table | `ZPPT_FCST_CFG` | VKORG + legacy TVARVC name |
| Number range | `ZPPFCST` | Forecast number, FY-dependent |
| Message class | `ZPP_FCST` | Messages |
| Auth object | `ZPP_FCST` | `WERKS` + `ACTVT` |
| Class | `ZCL_PP_FCST_UTIL` | FY / quarter / period / tonnage |
| Class | `ZCL_PP_FCST` | Calculation engine |
| Report | `ZPP_FORECAST` | Generation, 3 radio modes — tcode `ZFCST` |
| Report | `ZPP_FORECAST_REPORT` | Final ALV — tcode `ZFCST_RPT` |
| Report | `ZPP_FORECAST_UPLOAD` | All uploads — tcode `ZFCST_UPL` |
| SM30 views | `ZPPV_PROD_CAT` `ZPPV_MAT_TRACK` `ZPPV_MAT_EXCL` `ZPPV_FCST_CFG` | TMG per the document |

---

## 2. Domains and data elements

| Domain | Type | Data element |
|---|---|---|
| `ZDO_FCST_NO` | CHAR 10 | `ZDE_FCST_NO` |
| `ZDO_PROD_CAT` | CHAR 2 | `ZDE_PROD_CAT` |
| `ZDO_LOAD_FCT` | DEC 5,3 | `ZDE_LOAD_FCT` |
| `ZDO_MTS_MTO` | CHAR 3 (`MTS` / `MTO`) | `ZDE_MTS_MTO` |
| `ZDO_FYEAR` | CHAR 9 (`2026-2027`) | `ZDE_FYEAR` |
| `ZDO_QUARTER` | NUMC 1 (1–4) | `ZDE_QUARTER` |
| `ZDO_FCST_QTY` | QUAN 15,3 | `ZDE_FCST_QTY` |
| `ZDO_REASON` *(exists, CHAR 40)* | reused, not created | `ZDE_FCST_REASON` |

---

## 3. Configuration tables

### `ZPPT_PROD_CAT`
Key `MANDT` `WERKS` `MATNR` · `PROD_CAT` · `LOAD_FCT` · `MTS_MTO` · `AENAM` `AEDAT`

MTS/MTO sits here per the revised document, not in a table of its own.

### `ZPPT_MAT_TRACK`
Key `MANDT` `WERKS` `NEW_MATNR` · `OLD_MATNR1` · `OLD_MATNR2` · `AENAM` `AEDAT`

### `ZPPT_MAT_EXCL`
Key `MANDT` `WERKS` `MATNR` · `AENAM` `AEDAT`

### `ZPPT_SLS_HIST`
Key `MANDT` `WERKS` `MATNR` `GJAHR` · `M01`…`M12` · `AENAM` `AEDAT`

Twelve months on one row, matching the upload layout.

### `ZPPT_FCST_CFG`
Key `MANDT` `WERKS` · `VKORG` (default `1100`) · `TVARV_LEGACY` · `BWART` (default `601`)

Holds what the document hardcodes, so no code change is needed to alter it.

---

## 4. Forecast tables

### `ZPPT_FCST_YR` — Annual

| Key | Field | Notes |
|:--:|---|---|
| ✔ | `MANDT` `WERKS` `MATNR` `FYEAR` | Upsert key |
| | `FCST_NO` | From `ZPPFCST`, reused on re-run |
| | `MAKTX` `MATKL` `NTGEW` `MVGR1`–`MVGR5` | From ALV |
| | `M01`…`M12` | Last year monthly sales |
| | `LY_TOTAL` | Total LY sales qty |
| | `PROD_CAT` `LOAD_FCT` `MTS_MTO` | |
| | `FCST_TOTAL` | `LY_TOTAL × LOAD_FCT` |
| | `M01_FCST`…`M12_FCST` | Forecast split |
| | `M01_TON`…`M12_TON` | Tonnage |
| | `ERNAM` `ERDAT` `AENAM` `AEDAT` | |

**Key is plant + material + financial year, not the forecast number** — that is what makes
the re-run behaviour ("assign the same forecast number which is available in the table")
an upsert. `FCST_NO` carries a non-unique index `Z01`.

### `ZPPT_FCST_QT` — Quarterly

Key `MANDT` `WERKS` `MATNR` `GJAHR` `QUARTER`, plus `FCST_NO`, the descriptive block,
then `M4_LAST` `M5_LAST` `M6_LAST` · `LY_QTR_TOT` · `M1_CURR` `M2_CURR` `M3_CURR` ·
`L3M_TOT` · `MAX_QTY` · `PROD_CAT` `LOAD_FCT` `MTS_MTO` · `FCST_QTY` · `BUS_FCST` ·
`BUS_FCST_ADD` · `FINAL_QTY` · `M4_FCST` `M5_FCST` `M6_FCST` · `M4_TON` `M5_TON` `M6_TON` ·
`REASON` · audit fields.

Field names follow the document's own save layout.

### `ZPPT_FCST_MN` — Monthly

Key `MANDT` `WERKS` `MATNR` `GJAHR` `PERIOD`, plus `FCST_NO`, the descriptive block,
then `M4_LAST` `M5_LAST` `M6_LAST` · `LY_QTR_TOT` · `M1_CURR` `M2_CURR` `M3_CURR` ·
`L3M_AVG` · `MAX_QTY` · `PROD_CAT` `LOAD_FCT` `MTS_MTO` · `FCST_QTY` · `BUS_FCST` ·
`BUS_FCST_ADD` · `FINAL_QTY` · `M4_FCST` · `M4_TON` · `REASON` · audit fields.

---

## 5. Data sources — as specified

| Mode | Source | Quantity |
|---|---|---|
| Annual | `VBRK` ⋈ `VBRP` | `VBRP-FKIMG` |
| Quarterly | `VBRK` ⋈ `VBRP` | `VBRP-FKIMG` |
| Monthly | `MATDOC`, `BWART = 601` | `MATDOC-MENGE` |
| Superseded codes | `MATDOC` | `MATDOC-MENGE` |
| Legacy checkbox | `ZPPT_SLS_HIST` | `M01`…`M12` |

Billing filters: `VBRK-FKSTO ≠ 'X'`, `VBTYP ≠ 'U'`, `VBRP-SHKZG` per the document.

---

## 6. Calculations

```
Annual     FCST_TOTAL = LY_TOTAL × LOAD_FCT
           M(n)_FCST  = ( M(n) / LY_TOTAL ) × FCST_TOTAL

Quarterly  MAX_QTY    = max( LY_QTR_TOT , L3M_TOT )
           FCST_QTY   = MAX_QTY × LOAD_FCT
           FINAL_QTY  = max( FCST_QTY , BUS_FCST )
           M(n)_FCST  = ( M(n)_LAST / LY_QTR_TOT ) × FINAL_QTY

Monthly    L3M_AVG    = L3M_TOT / 3
           MAX_QTY    = max( LY same month , L3M_AVG × LOAD_FCT )
           FINAL_QTY  = max( MAX_QTY , BUS_FCST )

All        Tonnage    = forecast qty × MARA-NTGEW
           Divisor 0  → split equally across the periods
```

---

## 7. Message class `ZPP_FCST`

| No | Type | Text |
|---|---|---|
| 001 | E | Enter a plant |
| 002 | E | Financial year &1 is not in the format YYYY-YYYY |
| 003 | E | Enter either a quarter or a date range, not both |
| 004 | E | Year is mandatory when a quarter is entered |
| 005 | E | Annual forecast does not exist for plant &1 material &2 year &3 |
| 006 | E | No product category maintained for plant &1 material &2 |
| 007 | W | No load factor for plant &1 category &2, 1.000 used |
| 008 | I | No data selected for the given criteria |
| 009 | S | Forecast number &1 saved for &2 material(s) |
| 010 | E | No authorisation for plant &1 activity &2 |
| 011 | E | No authorisation to use legacy data |
| 012 | E | Material &1 is not created in plant &2 |
| 013 | E | Upload file could not be read: &1 |
| 014 | E | Row &1: &2 |
| 015 | S | &1 rows uploaded, &2 rows in error |
| 016 | E | Reason is mandatory for a forecast change |
| 017 | E | Select at least one line |
| 018 | E | Configuration missing for plant &1 |
| 019 | E | Save is only allowed when the selected period condition is met |
| 020 | W | Material &1 is excluded from forecasting |

---

## 8. Build sequence

1. Domains → data elements → tables (this ZIP)
2. Number range `ZPPFCST`, message class, auth object, SM30 views
3. `ZCL_PP_FCST_UTIL`
4. `ZCL_PP_FCST`
5. `ZPP_FORECAST_UPLOAD` — needed to load config and history before anything can be tested
6. `ZPP_FORECAST`
7. `ZPP_FORECAST_REPORT`

---

## 9. Design decisions taken during build

These are choices the document does not settle, or where it contradicts itself.
Each is isolated so it can be reversed cheaply.

### 9.1 Monthly MAX — the prose and the numbers disagree

FS radio button 3 text (A51, A55) reads:

```
MAX_QTY  = max( LY same month , L3M total )
FORECAST = MAX_QTY x load factor
```

The worked example says otherwise:

```
MAX_QTY  = max( LY same month , L3M average x load factor )
```

Both give the same answer for M1, M3, M4 and M5. They differ on **M2**:

| | LY Jul | L3M avg | Load | Prose | Sample | Document shows |
|---|---:|---:|---:|---:|---:|---:|
| M2 | 1,200 | 616.67 | 1.3 | 1,560 | **1,200** | **1,200** |

**Built to the sample**, since it is the only reading that reproduces the
document's own figures. Isolated in `ZCL_PP_FCST=>calc_monthly`.

### 9.2 The load factor is applied at different points in the two modes

Quarterly applies it **after** the max — `max(LY qtr, L3M total) x load`, giving
13,000 x 1.3 = 16,900. Monthly applies it **before** — `max(LY month, avg x load)`.
Both follow their own worked example. Not an error on our side, but it is
inconsistent within the document and worth confirming.

### 9.3 `VBRP-SHKZG` — RESOLVED, the document is wrong

The document states `SHKZG is not equal to blank`.

**Verified in the system on 21.08.2026.** `VBRP-SHKZG` is blank on normal sales
and `X` on returns. The condition as written therefore selects returns only and
excludes every ordinary sale — the first annual run returned no data at all
(message 008), which is what exposed it.

`gc_shkzg_ne_blank` is set to `abap_false`, so the selection excludes returns
and includes normal sales.

**This is a deviation from the document and must be corrected in the FS.** Built
as written, the forecast would have been produced entirely from returns
quantities: plausible-looking numbers, completely wrong.

### 9.4 Annual history is selected on `FKDAT`, not `VBRK-GJAHR`

The document says to pass the fiscal year to `VBRK-GJAHR`. The ALV columns
however run Apr-25 to Mar-26, which is the **previous** financial year, and
`GJAHR` depends on the fiscal year variant rather than on the April to March
year this object uses. History is therefore selected on `VBRK-FKDAT` between the
previous financial year's dates, which produces the columns as drawn.

### 9.5 Fields to confirm at first syntax check

| Field | Note |
|---|---|
| `MATDOC-CANCELLED` | Used for "cancelled is equal to blank". Confirm the field name in this release |
| `MATDOC-MENGE`, `BUDAT`, `BWART` | Confirm all present and populated |
| `VBRK-VBTYP` | Filter `<> 'U'` per the document |

### 9.6 The ALV line type lives in the class, not in DDIC

`ZCL_PP_FCST=>ty_alv` carries all sixty-odd columns and uses the same field
names as the three forecast tables, so `CORRESPONDING #( )` maps straight to
them on save. This avoids a second DDIC import cycle. If a dictionary structure
is preferred for the field catalogue it can be added later without touching the
logic.
