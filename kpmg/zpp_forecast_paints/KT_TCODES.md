# ZFORECAST Paints — transactions and what each one does

Astral / UDAY (KPMG), Paints division. Handover note, 19.10.2026, Arnav Johri.
Objects imported in DEV on 19.10.2026 from `ZPP_FORECAST_PAINTS.zip`; not transported, not yet
functionally tested.

## Paints transactions

| Tcode | Program | What it does |
|------------------|------------------------------|----------------------------------------------------------------------|
| **ZFCST_PAINTS** | `ZPP_FORECAST_PAINTS` with `ZCL_PP_FCST_PNT`; arithmetic and save in the shared engine `ZCL_PP_FCST` | Forecast generation, three radio buttons. **Annual**: last year's month × load factor, twelve months. **Quarterly**: higher of last year's same quarter and the current last three months, × load factor, then higher of that and the business forecast, split into the three months. **Monthly**: higher of last year's same month and the last-three-month average × load factor, then higher of that and the business forecast. Selection: plant, material, financial year as 2026-2027, quarter or month or date range, Tonnage Wise. List columns: plant code and name, brand, material and description, MTS/MTO/DIS/TIN, material groups 1, 2 and 5, material group, pack size, DPL, quantity per carton, then per forecast month the quantity, volume in KL (quantity × pack size ÷ 1000), value in crores (DPL × quantity ÷ 1,00,00,000) and, with Tonnage ticked, gross weight and tonnage (quantity × gross weight ÷ 1000). The Adhesive working columns (history months, category, growth, groups 3 and 4) are hidden and reachable through Change Layout. Select rows and press Save: writes `ZPPT_FCST_YR` / `ZPPT_FCST_QT` / `ZPPT_FCST_MN` under one forecast number per plant, material and year. Export to a tab file. |
| **ZFCST_PAINTS_UPL** | `ZPP_FORECAST_PAINTS_UPL` | All nine Paints uploads, each radio button with its own Download Template button: **Product Category (Paints)** — plant, material, category, load factor, indicator MTS, MTO, DIS or TIN (DIS ART and TINTING accepted and stored as DIS and TIN); **Material Tracking** — new code and up to five old codes; **Material Exclusion**; **Legacy Sales History** — twelve months per plant, material, year; **Business Forecast Quarterly**; **Business Forecast Monthly** (leave MSL column 6 blank); **Forecast Change Quarterly** — Month 1, 2 or 3 within the quarter, with reason; **Forecast Change Monthly**; **Brand** — plant, material, brand into `ZPPT_BRAND`. Plant and material checked against MARC; existing rows overwritten, new ones inserted. Excel, CSV or tab text; test run ticked by default; row-by-row result list; good rows saved even when others are rejected. Writes the same tables as the Adhesive upload. |
| **ZFCST_RPT** (shared with Adhesive) | `ZPP_FORECAST_REPORT` | Final forecast report by plant, material, financial year, forecast number, material group, quarter and period: annual, quarterly, additional, total quarter, monthly, additional, total month. Plant selection separates Paints from Adhesive. |

## Configuration and support

| Tcode / object | What it is for |
|------------------------------------|----------------------------------------------------------------------|
| **SM30 `ZPPV_FCST_CFG`** (`ZPPT_FCST_CFG`) | One row per **Paints plant**: sales organisation 4000 for the material-group and carton reads, TVARVC name of the legacy-user list. A plant without a row logs message 018 and uses 4000. **To be maintained before the first run.** |
| **SM30 `ZPPV_PROD_CAT`** (`ZPPT_PROD_CAT`) | Product category, load factor, indicator. Manual entry of DIS or TIN needs the two fixed values added to domain `ZDO_MTS_MTO` in SE11 (optional, not in the ZIP); the upload writes them regardless. |
| **SM30 `ZPPV_MAT_TRACK`**, **`ZPPV_MAT_EXCL`** | Old-to-new material codes; excluded materials. Shared tables, by plant. |
| **SM30 `ZPPV_BRAND`** (`ZPPT_BRAND`) | Brand per plant and material. View not generated yet (SE54, optional); the upload covers it. |
| **STVARV `ZPP_FORECAST_MTART`** | Material types the lists are restricted to (FERT, HAWA). Applies to Paints through the shared engine. Client-specific. |
| **STVARV `ZPP_FCST_LEGACY`** | Parameter X or blank: whether the Legacy Data checkbox is drawn. Blank gives the Paints FS screen exactly. |
| **SNRO `ZPPFCST`** | Forecast number range, one interval per financial year, shared with Adhesive. |
| **SE91 `ZPP_FCST`** | Messages 001 to 026, shared. |
| **SU21 `ZPP_FCST`** | Authorisation by plant and activity (01 save, 02 upload, 03 display). Both checks are bypassed in `ZCL_PP_FCST_UTIL` since 07/09/26 for testing. |
| **SLG1** object `ZPP_FCST`, subobject `GENERATE`, external number `PAINTS …` | Log of every ZFCST_PAINTS run: missing category, load factor defaulted, superseded code shown under its successor, configuration missing. |
| **SE41** `PF_STATUS` of `ZPP_FORECAST_PAINTS` | Copy of the status from `ZPP_FORECAST`: SALV_STANDARD plus ZSAVE, ZSELALL, ZDESEL, ZEXCEL. **Still to be created**; until then the list shows the standard toolbar without the four buttons and says so. |
| **SE93** `ZFCST_PAINTS`, `ZFCST_PAINTS_UPL` | Report transactions, screen 1000. **Still to be created** if not done with the import. |

## Tables

ZFCST_UPL (the Adhesive upload) is not needed for Paints; it writes the same tables, so a
Paints row loaded through it by mistake is still valid, except that its category upload
refuses DIS and TIN.

Paints-only: `ZPPT_BRAND`. Shared with Adhesive: `ZPPT_PROD_CAT`, `ZPPT_MAT_TRACK`,
`ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST`, `ZPPT_FCST_CFG`, `ZPPT_FCST_YR`, `ZPPT_FCST_QT`, `ZPPT_FCST_MN`.
Package `ZPP_FORECAST_PAINTS` holds the Paints objects; the shared ones are in `ZPP_FORECAST`.
