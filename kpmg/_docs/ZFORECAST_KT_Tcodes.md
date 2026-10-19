# ZFORECAST — Transactions and what each one does

Astral Limited / Project UDAY (KPMG) · Adhesive and Paints forecasting · PP / SD
Knowledge transfer note, prepared 19.10.2026 by Arnav Johri. Development system only; nothing is transported yet.

## 1. Business transactions

| Tcode | Program / class behind it | Division | What it does |
|------------------|------------------------------|----------|----------------------------------------------------------------------|
| **ZFCST** | `ZPP_FORECAST` · engine `ZCL_PP_FCST` · helpers `ZCL_PP_FCST_UTIL` | Adhesive | Forecast generation, three radio buttons. **Annual**: last year's month × load factor, twelve months. **Quarterly**: higher of last year's same quarter and the current last three months, × load factor, then higher of that and the business forecast, split into the three months. **Monthly**: higher of last year's same month and the last-three-month average × load factor, then higher of that and the business forecast. Selection: plant, material, financial year (2026-2027), quarter or month or date range, Tonnage Wise, Legacy Data. History from billing (VBRK/VBRP), returns excluded; old material codes absorbed into the successor; uploaded history fills the gaps. SALV list; select rows and press Save to write `ZPPT_FCST_YR` / `_QT` / `_MN` under one forecast number per plant, material and year. Export to a tab file. |
| **ZFCST_UPL** | `ZPP_FORECAST_UPLOAD` | Adhesive and Paints | Eight uploads, each radio button with its own Download Template button: Product Category (plant, material, category, load factor, MTS/MTO), Material Tracking (new code and up to five old codes), Material Exclusion, Legacy Sales History (twelve months per plant, material, year), Business Forecast Quarterly, Business Forecast Monthly (MSL in column 6), Forecast Change Quarterly (Month 1, 2 or 3 within the quarter, with reason), Forecast Change Monthly. Reads Excel, CSV or tab text. Test run ticked by default; row-by-row result list; good rows are saved even when others are rejected. Paints uses it for everything except product category and brand. |
| **ZFCST_RPT** | `ZPP_FORECAST_REPORT` | Adhesive and Paints | Final forecast report by plant, material, financial year, forecast number, material group, quarter and period: annual, quarterly, additional, total quarter, monthly, additional, MSL, total month, MTS/MTO, price. Plant selection separates the divisions. |
| **ZFCST_PAINTS** | `ZPP_FORECAST_PAINTS` · `ZCL_PP_FCST_PNT` on top of the same engine | Paints | Same three modes and the same arithmetic, saved into the same tables. The list follows the Paints template: plant name, brand, MTS/MTO/DIS/TIN, material groups 1, 2 and 5, pack size, DPL, quantity per carton, forecast per month, volume in KL, value in crores, tonnage on gross weight. The Adhesive working columns are hidden but available through Change Layout. |
| **ZFCST_PAINTS_UPL** | `ZPP_FORECAST_PAINTS_UPL` | Paints | Two uploads: Product Category with the indicator MTS, MTO, DIS or TIN (the Adhesive upload takes MTS and MTO only), and Brand (plant, material, brand into `ZPPT_BRAND`). Same file handling and result list as ZFCST_UPL. |

## 2. Configuration and support transactions

| Tcode / object | What it is for |
|------------------------------------|----------------------------------------------------------------------|
| **SM30 `ZPPV_PROD_CAT`** (`ZPPT_PROD_CAT`) | Product category, load factor and MTS/MTO per plant and material. Also loaded by upload. |
| **SM30 `ZPPV_MAT_TRACK`** (`ZPPT_MAT_TRACK`) | New material code with up to five old codes per plant. The old codes' history is shown under the new code. |
| **SM30 `ZPPV_MAT_EXCL`** (`ZPPT_MAT_EXCL`) | Materials left out of forecasting, per plant. |
| **SM30 `ZPPV_FCST_CFG`** (`ZPPT_FCST_CFG`) | One row per plant: sales organisation for the material-group reads (Adhesive 1100, Paints 4000), TVARVC name of the legacy-user list, movement type (no longer used). A Paints plant without a row logs message 018 and uses 4000. |
| **SM30 `ZPPV_BRAND`** (`ZPPT_BRAND`, view still to be generated in SE54) | Brand per plant and material. Also loaded by ZFCST_PAINTS_UPL. |
| **STVARV** | `ZPP_FORECAST_MTART` (selection variable, FERT and HAWA): material types the lists are restricted to. `ZPP_FCST_LEGACY` (parameter, X or blank): whether the Legacy Data checkbox is drawn at all. The per-plant legacy-user list named in `ZPPT_FCST_CFG`. All client-specific. |
| **SNRO `ZPPFCST`** | Forecast number range, one interval per financial year, named by the last two digits of the starting year. Drawn on the first save of a plant, material and year, reused afterwards. |
| **SE91 `ZPP_FCST`** | Messages 001 to 026 for all five programs. |
| **SU21 `ZPP_FCST`** | Authorisation object, fields WERKS and ACTVT (01 save, 02 upload, 03 display). **Both checks are bypassed in `ZCL_PP_FCST_UTIL` since 07/09/26 for testing and must be restored before release.** |
| **SLG1** object `ZPP_FCST`, subobject `GENERATE` | Application log of every ZFCST and ZFCST_PAINTS run: missing category, load factor defaulted, superseded code shown under its successor, configuration missing. |
| **SE41** `PF_STATUS` of `ZPP_FORECAST` and of `ZPP_FORECAST_PAINTS` | GUI status: SALV_STANDARD plus ZSAVE, ZSELALL, ZDESEL, ZEXCEL. Not serialised by abapGit; the Paints copy is still to be made. |
| **SE16** `ZPPT_FCST_YR`, `ZPPT_FCST_QT`, `ZPPT_FCST_MN`, `ZPPT_SLS_HIST` | Saved annual, quarterly and monthly forecasts, and the uploaded legacy history. |

## 3. Three things to know before touching anything

1. One engine, two front ends. `ZCL_PP_FCST` does every calculation and every save for both divisions. Paints only adds display columns in `ZCL_PP_FCST_PNT`. A formula change goes into the engine once.
2. Everything is in the development system only. No transport has been released; the authority bypass above is live.
3. The repository `arnavjohri/Diligent`, folders `kpmg/zpp_forecast_v2` (Adhesive) and `kpmg/zpp_forecast_paints` (Paints), holds every source, the issue logs and the technical object lists.
