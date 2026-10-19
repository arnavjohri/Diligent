# ZFORECAST (Paints) — Assumptions and Open Queries

Version 1 — raised against `Forecast_Template-Paints_1.xlsx`, received 19.10.2026

| Item | Detail |
|-------------------------|---------------------------------------------------------------------------|
| Client | Astral Limited |
| Project | UDAY |
| Division | Paints (WRICEF ID-2B) |
| Module | PP / SD |
| Object | ZFORECAST Paints — Annual, Quarterly and Monthly Forecasting |
| Reference document | `Forecast_Template-Paints_1.xlsx` (no date or version inside the file). Builds on `Forecast Template-Adhesive.xlsx` dated 20.08.2026 |
| Sheets read | Sheet1, RADIO BUTTON 1 ANNUAL, Radio Button 2 Quauter, Month, Consolidated |
| Purpose | Development assumptions for confirmation, open queries for resolution, and the proposed object list for approval |
| Status of document | Draft — no version record, no approval, no message or authorisation section, no test scenarios. The "Month" sheet is a copy of the quarterly sheet. The annual sample rows do not line up with the annual column header |
| Prepared by | Arnav Johri, 19.10.2026 |

## 0. Position — how Paints relates to the Adhesive build

The Paints template is the Adhesive template with a different column layout. The three
planning modes, the selection screens, the sales-history sources, the load-factor
calculation, the business-forecast comparison, the quarterly month split, the upload
formats and the save layouts are the same, and the FS names the Adhesive tables
(`ZPP_ADH_FORE_QUATER`, `ZPP_ADH_FORECAST_YEAR`, `ZPP_MATERIAL_CATEGORY`,
`ZPP_MATERIAL_TRACKING`, `ZPP_SALES_HISTORY`) as the tables Paints reads and writes.

What is new for Paints is presentation and master data: a brand per plant and material
(new table, new upload), the manufacturing plant name, pack size, dealer price (DPL),
quantity per carton, gross weight, a volume-in-kilolitre column and a value-in-crore
column per forecast month, and tonnage on gross weight instead of net weight. The MTS/MTO
indicator gains two more values. None of the new columns is saved.

**Recommended build:** reuse the eight Adhesive tables, the number range, the
authorisation object, the calculation engine `ZCL_PP_FCST`, the helper class
`ZCL_PP_FCST_UTIL`, the upload program `ZPP_FORECAST_UPLOAD` and the final report
`ZPP_FORECAST_REPORT`. Add one table with its upload type, one enrichment class that
puts the Paints columns on the engine's output, and one new generation program for
Paints. The Adhesive generation program `ZPP_FORECAST` is not touched. This keeps the
forecast arithmetic in one place, as Adhesive assumption C45 already requires, and means
every fix to the engine reaches both divisions.

The alternative — a full copy of the class, the program, the upload and the report for
Paints — is about 7,000 lines to maintain twice. Not recommended.

## 1. Mandatory queries

These cannot be resolved by assumption. Development cannot produce a correct result until
each is answered.

| # | Query | FS section | What it affects |
|-------|----------------------------------------------------------|---------------|--------------------|
| M1 | The FS names the Adhesive tables as the tables Paints reads and saves into. Please confirm that one set of tables, one forecast number range (`ZPPFCST`) and one authorisation object (`ZPP_FCST`, by plant) serve both divisions, and that **a Paints plant is never also an Adhesive plant**. Every configuration the two divisions differ on (sales organisation, legacy TVARVC) is held per plant, so a plant that carries both divisions cannot be configured | Quarter sheet, save layout and "From ZPP_ADH_FORE_QUATER" | The whole data model. Nothing can be built until this is settled |
| M2 | Brand table. The FS calls it `ZPP_BRAND` in the logic rows and `ZPPT_BRAND` in the upload format. Please confirm: name `ZPPT_BRAND`, key plant + material, one field `BRAND`, and give the **length** of the brand and whether it is free text or a fixed list. Upload format read as Plant, Material, Brand | RADIO BUTTON 1 ANNUAL, rows 70 and 85 | DDIC. The domain cannot be created without a length |
| M3 | MTS / MTO / DIS ART / TINTING. The Adhesive indicator is a 3-character domain with the fixed values `MTS` and `MTO`, used by the category table and the three forecast tables, all of which hold data. Proposal: add fixed values `DIS` (Dis Art) and `TIN` (Tinting) to the same domain — no table conversion, the category upload accepts the two new codes. Please confirm the codes and give the long text of "DIS ART" | Every ALV header, column "MTS / MTO / DIS ART / TINTING" | Category upload validation, ALV display, four shared tables |
| M4 | Sales organisation. "QTY / CARTON" reads MVKE with `VKORG = 4000`; the material-group rows still say `VKORG = 1100`, which is the Adhesive value. Please confirm **4000 is the Paints sales organisation for every MVKE read** (material groups 1, 2, 5 and quantity per carton). It is held per plant in `ZPPT_FCST_CFG`, so this is configuration, not code, provided M1 holds | RADIO BUTTON 1 ANNUAL row 91; Quarter sheet rows 30–34 | Material group descriptions, quantity per carton |
| M5 | Pack size. "MARM-UMREN where the unit is not the base unit; ML or GM divided by 1000." A material usually has several alternative units (carton, litre, kilogram). Please confirm **which unit** gives the pack size when more than one exists. Proposal: the MARM row whose unit is L, ML, KG or G, taken in that order of preference, pack size = UMREN ÷ UMREZ (equal to UMREN when UMREZ is 1, as the FS assumes), ML and G divided by 1000. Please also confirm the unit codes as they exist in the system (gram is `G` in standard SAP, the FS writes `GM`) | RADIO BUTTON 1 ANNUAL row 88 | Every "Volume in KL" column |
| M6 | Additional forecast per month or per quarter. The quarterly ALV shows "July 26 additional / Aug 26 additional / Sep 26 additional" and a final per month, but the change-upload format has no Month column and the save list has one "Business Forecast M4 TO M6 additional". Adhesive settled this on 03/09/26: three per-month fields `BUS_FCST_ADD1/2/3`, a Month column on the quarterly change upload (1, 2 or 3 within the quarter). Please confirm Paints follows the same rule | RADIO BUTTON 1 ANNUAL row 125; Quarter sheet rows 91 and 109–113 | Change upload, quarterly columns, saved fields |
| M7 | Annual ALV columns. The annual header lists forecast months only (quantity, KL, crores, tonnage) and no last-year history, while the sample rows underneath carry the twelve history months, the last-year total, category, growth and total forecast in the Adhesive order. Please confirm the annual list keeps the Adhesive columns (history months, total, category, growth, forecast total, forecast months) **and adds** the Paints columns, rather than replacing them | RADIO BUTTON 1 ANNUAL rows 23–29 and 75–80 | Annual ALV layout |

## 2. Assumptions

The points below are the assumptions on which development will proceed. Any assumption
not corrected in the "Confirmed / Correction" column will be treated as agreed and built as
stated. Adhesive assumptions C01–C46 (document of 20.08.2026) and every decision recorded
since in `kpmg/zpp_forecast_v2/ISSUES.md` carry over unless a row below says otherwise.

### 2.1 Scope and object identity

| # | Assumption | Confirmed (Y/N) / Correction |
|-------|-------------------------------------------------------------------------|--------------------|
| P01 | Paints is delivered as a **new generation program** `ZPP_FORECAST_PAINTS` (transaction `ZFCST_PAINTS`) with the three radio-button modes. The Adhesive program `ZPP_FORECAST` (ZFCST) is not changed | |
| P02 | Paints **shares** with Adhesive: the eight tables, number range `ZPPFCST`, authorisation object `ZPP_FCST`, message class `ZPP_FCST`, classes `ZCL_PP_FCST` and `ZCL_PP_FCST_UTIL`, the upload program `ZPP_FORECAST_UPLOAD` (which gains the brand upload) and the final report `ZPP_FORECAST_REPORT` | |
| P03 | Every decision taken on Adhesive and not contradicted by the Paints FS applies to Paints: returns excluded (`VBRP-SHKZG` blank), history selected on billing date, financial year as one field `2026-2027`, legacy data all-or-nothing per year, material types restricted to TVARVC `ZPP_FORECAST_MTART` (FERT, HAWA), monthly history from billing documents rather than MATDOC 601, one forecast number shared by the three tables with no requirement that the annual forecast exists first, superseded codes absorbed into the successor with sales-history fill, up to five old codes per new code (the FS's two are a subset), load factor 1.000 when none is maintained, equal split when a divisor is zero, monthly formula built to the worked example | |
| P04 | "Last 3 years sales data upload in the custom table" is the existing legacy sales-history upload: one row per plant, material and year, three years are three rows. No new table | |
| P05 | The target system, client, package and release are those of the Adhesive objects. The release constraints already recorded for this landscape apply | |

### 2.2 New columns

| # | Assumption | Confirmed (Y/N) / Correction |
|-------|-------------------------------------------------------------------------|--------------------|
| P06 | Manufacturing plant name is `T001W-NAME1` for the row's plant | |
| P07 | Brand is read from `ZPPT_BRAND` by plant and material. A material with no brand row shows a blank brand; it is not an error and the row is not dropped | |
| P08 | Material Group 1, 2 and 5 are shown as descriptions (TVM1T, TVM2T, TVM5T), as on Adhesive. Material Group 3 and 4 are still read by the shared engine but are **not shown** on the Paints lists, as drawn. "Material Group" is `MARA-MATKL` | |
| P09 | DPL (dealer price) is the Adhesive price logic unchanged: `A923` on material alone, record with the latest `DATAB`, its `KONP-KBETR`. It is also read for the **annual** mode, which on Adhesive carries no price. See query Q1 on the condition table | |
| P10 | Quantity per carton is `MVKE-AUMNG` for the plant's sales organisation where `MVGR1` is not blank, blank when there is no sales view. The SAP label of `AUMNG` is "minimum order quantity" — built as the FS says, see query Q2 | |
| P11 | Gross weight is `MARA-BRGEW` with its weight unit. **Tonnage = forecast quantity × gross weight ÷ 1000**, so a gross weight in KG gives tonnes. This replaces, for Paints only, the Adhesive tonnage (quantity × net weight, no division). The quarterly save stores the Paints tonnage in the same `M4_TON`–`M6_TON` fields | |
| P12 | Volume in KL = forecast quantity × pack size ÷ 1000, one column per forecast month. In quarterly and monthly it uses the **final** quantity of the month (forecast plus additional); in annual it uses the month's forecast quantity | |
| P13 | Value in crores = DPL × the same quantity ÷ 1,00,00,000, one column per forecast month. `KBETR` is taken as the price of one unit in INR; pricing unit and currency are not evaluated, as on Adhesive | |
| P14 | Each forecast month uses its own quantity. The FS formulas repeat "April 25" for all twelve months; this is read as a copy-and-paste slip, as Adhesive C21 | |
| P15 | The header cells `FEB 26` and `MAR 26` under `Q4_26-27` are read as `FEB 27` and `MAR 27`. The thirteenth "Value in Crores" column (a repeat of March) is not built | |
| P16 | Brand, plant name, pack size, DPL, quantity per carton, gross weight, KL and crores are **display only**. The save layout is the Adhesive one; no field is added to any forecast table | |
| P17 | The "Month" sheet is a copy of the quarterly sheet. Monthly is built as Adhesive monthly plus the Paints master-data columns and one KL column for the month. No crore column on monthly, as none is drawn — see query Q3 | |
| P18 | MSL is an Adhesive-only column. The Paints monthly list does not show it. Because the monthly business-forecast upload is shared, an MSL value uploaded for a Paints plant is still stored and added into the monthly total by the engine | |

### 2.3 Selection screens, uploads, save, report

| # | Assumption | Confirmed (Y/N) / Correction |
|-------|-------------------------------------------------------------------------|--------------------|
| P19 | Selection screens are the Adhesive ones: plant range, material range, financial year, quarter or period or date range, Tonnage Wise, Legacy Data (TVARVC-protected). "Tonnage Wise with Gross Weight" is the same checkbox; only the weight used differs | |
| P20 | Paints users download and use the **shared upload templates**. The column order in the FS (plant before material on Sheet1, material before plant on the quarter sheet) is not followed; the downloaded template is authoritative | |
| P21 | Brand upload: columns Plant, Material, Brand; plant and material checked against MARC; an existing plant and material is overwritten, a new one inserted — the same rules as the exclusion upload. It is the ninth radio button of `ZPP_FORECAST_UPLOAD` with its own template button | |
| P22 | The category upload accepts the four indicator values of M3; the MTS / MTO column on every list shows the code | |
| P23 | Save behaviour is the Adhesive one in all three modes: `ZCL_PP_FCST=>SAVE` on the selected rows, one forecast number per plant, material and financial year across the three tables | |
| P24 | The final report is `ZPP_FORECAST_REPORT` (ZFCST_RPT) **as it stands**. Its columns are a superset of the Paints final report (material, plant, description, material group, groups 1, 2, 5, annual, quarter, additional, total quarter, monthly, additional, total monthly, forecast number) and the "Consolidated" sheet (same columns plus month, selection by material group). Plant selection separates the divisions. No new report, no brand column on the report | |
| P25 | Authorisation: `ZPP_FCST` by plant and activity covers Paints plants; no new authorisation object. Legacy-data authorisation via the per-plant TVARVC name in `ZPPT_FCST_CFG` | |
| P26 | Transaction codes: `ZFCST_PAINTS` for the new program. `ZFCST_UPL` and `ZFCST_RPT` serve both divisions | |

## 3. Further queries

Each of these has been assumed above. Confirmation is needed before the relevant part of
the build, but none prevents work from starting.

| # | Query | Required by |
|-------|-------------------------------------------------------------------------|--------------------|
| Q1 | DPL is specified from condition table `A923`, the same table as the Adhesive price. Please confirm `A923` holds the Paints dealer price list, and name the condition type, so the right record is read when a material has records under more than one type | Before build of the enrichment class |
| Q2 | `MVKE-AUMNG` is "minimum order quantity in base unit" in SAP. Please confirm it is the field that holds the quantity per carton for Paints | Before build |
| Q3 | Monthly list: should it show a value-in-crores column for the month, as the quarterly list does? None is drawn | Before build |
| Q4 | Tonnage: the annual sheet says gross weight ÷ 1000, the quarter sheet logic rows still say net weight (Adhesive wording). Built on gross weight for all three modes — please confirm | Before build |
| Q5 | Material Group 3 and 4 are dropped from every Paints list. Please confirm, or they are shown as on Adhesive | Before build |
| Q6 | Is a brand column wanted on the final report? Not drawn; not built | Before build of the report change, if any |
| Q7 | Material type restriction: Adhesive restricts the lists to the material types in TVARVC `ZPP_FORECAST_MTART` (FERT, HAWA). The same variable applies to Paints through the shared engine. Please confirm, or name the Paints types | Before unit test |
| Q8 | Brand maintenance: besides the upload, is an SM30 view (`ZPPV_BRAND`) wanted for manual maintenance, as the other configuration tables have? | Before SE54 |
| Q9 | The FS carries no version record, approval, message list, authorisation matrix or test scenarios, and the annual worked example does not match its own header. Please complete and sign off to baseline it | Before baseline |

## 4. Proposed objects — for approval before any code

In dependency order, which is also paste order. Manual steps are marked.

| # | Object | Type | New / changed | Purpose | Depends on |
|-----|-----------------|------------|------------|-------------------------------------------|------------|
| 1 | `ZDO_BRAND` | Domain | New | CHAR, length per M2 | M2 |
| 2 | `ZDE_BRAND` | Data element | New | "Brand" | 1 |
| 3 | `ZPPT_BRAND` | Table | New | Key MANDT, WERKS, MATNR; BRAND; ERNAM, ERDAT, AENAM, AEDAT | 2 |
| 4 | `ZPPV_BRAND` | SM30 view | New, **manual SE54** | Brand maintenance, if Q8 is yes | 3 |
| 5 | `ZDO_MTS_MTO` | Domain | Changed | Fixed values DIS and TIN added, length unchanged | M3 |
| 6 | `ZCL_PP_FCST` | Class | Changed, one line | `READ_PRICES` moved from the private to the public section, so the Paints annual mode can price. No logic change. (Alternative: copy the 30-line read into the new class; rejected because the price rule then exists twice) | fresh SE80 download |
| 7 | `ZCL_PP_FCST_PNT` | Class | New | Paints enrichment. Row type = `ZCL_PP_FCST=>TY_ALV` plus the Paints columns. `ENRICH` reads T001W, ZPPT_BRAND, MARM, MVKE-AUMNG, MARA-BRGEW and (annual only) prices; recomputes tonnage on gross weight ÷ 1000; computes KL and crores per month. Display only | 3, 6 |
| 8 | `ZPP_FORECAST_UPLOAD` | Report | Changed | Ninth radio button "Brand" with template button; `FORM do_brand` modelled on `do_exclusion`; category upload accepts DIS and TIN | 3, 5, fresh SE80 download |
| 9 | `ZPP_FORECAST_PAINTS` | Report | New | Selection screen and SALV handling copied from `ZPP_FORECAST`; calls `ZCL_PP_FCST` to generate, `ZCL_PP_FCST_PNT` to enrich, `ZCL_PP_FCST=>SAVE` to save; column lists per the Paints layouts | 7 |
| 10 | `PF_STATUS` of `ZPP_FORECAST_PAINTS` | GUI status | New, **manual SE41** | Copy of the Adhesive status (SALV_STANDARD plus ZSAVE, ZSELALL, ZDESEL, ZEXCEL) | 9 |
| 11 | `ZFCST_PAINTS` | Transaction | New, **manual SE93** | | 9 |
| 12 | `ZPP_FORECAST_REPORT` | Report | No change | Serves Paints as is (P24) | |
| 13 | `ZCL_PP_FCST_UTIL`, the seven other tables, `ZPPFCST`, `ZPP_FCST` auth object | | No change | Shared | |

Messages: the brand upload reuses the existing result texts pattern ("Brand uploaded",
"Material is not created in the Plant"); no new message number is expected. Any that
turns out to be needed is listed at build time.

## 5. Requirement mapping

| FS requirement | Where | Implemented by |
|-----------------------------------|-------------------------|----------------------------------------|
| Annual, quarterly, monthly forecasting with the Adhesive arithmetic | Sheet1 1.1–1.3 | `ZCL_PP_FCST` (shared), called from `ZPP_FORECAST_PAINTS` |
| Selection screens incl. Tonnage Wise and Legacy Data | All mode sheets | `ZPP_FORECAST_PAINTS`, copied from `ZPP_FORECAST` |
| Product category, load factor, MTS/MTO maintenance and upload | Annual sheet rows 32–47 | `ZPPT_PROD_CAT`, `ZPP_FORECAST_UPLOAD` type CAT (shared); domain change for the two new values |
| Material tracking (new code, old codes) | Annual sheet rows 50–62 | `ZPPT_MAT_TRACK`, upload type TRK (shared, five old codes) |
| Material exclusion | Annual sheet rows 64–70 | `ZPPT_MAT_EXCL`, upload type EXC (shared) |
| Brand per plant and material, upload | Annual sheet rows 70, 85 | `ZPPT_BRAND`, upload type BRD (new), `ZCL_PP_FCST_PNT` |
| Mfg plant name | Annual sheet row 84 | `ZCL_PP_FCST_PNT` (T001W) |
| Material group, groups 1, 2, 5 | Rows 87, quarter sheet 30–34 | engine (shared), displayed by `ZPP_FORECAST_PAINTS` |
| Pack size | Annual sheet row 88 | `ZCL_PP_FCST_PNT` (MARM), rule per M5 |
| Gross weight, tonnage on gross weight ÷ 1000 | Rows 89, 120 | `ZCL_PP_FCST_PNT` |
| DPL | Row 90 | engine `READ_PRICES` (shared), called for annual by `ZCL_PP_FCST_PNT` |
| Qty per carton | Row 91 | `ZCL_PP_FCST_PNT` (MVKE-AUMNG) |
| Volume in KL per month | Rows 92–103 | `ZCL_PP_FCST_PNT` |
| Value in crores per month | Rows 104–116 | `ZCL_PP_FCST_PNT` |
| Last-year sales history upload (WRICEF 2) | Sheet1 row 93; "J" | upload type HIST (shared) |
| Sales forecast upload, quarterly and monthly (WRICEF 3) | Quarter sheet rows 102–106 | upload types BUSQ / BUSM (shared) |
| Change upload with reason (WRICEF 4) | Quarter sheet rows 109–115 | upload types CHGQ / CHGM (shared), per M6 |
| Save with forecast number, quarter condition | Quarter sheet rows 58–100 | `ZCL_PP_FCST=>SAVE` (shared) |
| Final report and Consolidated view | Sheet1 rows 98–108, Consolidated | `ZPP_FORECAST_REPORT` as is (P24) |

Nothing in the FS maps to no object. Nothing is built that the FS does not ask for.

## 6. Before the build can start

1. Answers to M1–M7.
2. Approval of the object list in section 4, or corrections to it.
3. A fresh `ZR_PROG_DOWNLOAD` of `ZPP_FORECAST_UPLOAD`, `ZCL_PP_FCST`, `ZCL_PP_FCST_UTIL`
   and `ZPP_FORECAST` from the running system. Three of them are changed or copied, and
   no download has been supplied since 03/09/26; the repo copy is not to be trusted as
   current.
4. The current SE11 state of `ZDO_MTS_MTO` and `ZPPT_PROD_CAT` (fixed values and fields),
   since the domain is changed.
5. Confirmation that the target is the same development system and client as the
   Adhesive objects.

## 7. Position summary

The Paints template changes what is shown, not what is calculated. Reusing the Adhesive
tables, engine, upload and report is the natural reading of the FS, which names those very
tables, and it is what keeps the two divisions from drifting apart. The build is one new
table with its upload type, one enrichment class and one new generation program, plus a
one-line visibility change in the engine and two fixed values on a domain.

Two points carry real risk if left to assumption: whether a plant can belong to both
divisions (M1, which decides whether per-plant configuration is enough), and the pack-size
rule (M5, which drives every kilolitre figure). The annual worked example cannot be used to
verify the arithmetic because its columns do not match its own header; a corrected example
is requested under Q9.
