# ZFORECAST (Paints) — Assumptions and Open Queries

Version 2 — raised against `Forecast_Template-Paints_1.xlsx`, received 19.10.2026.
Version 2 (same day) applies the rule that **no Adhesive program or class is changed**.

| Item | Detail |
|-------------------------|---------------------------------------------------------------------------|
| Client | Astral Limited |
| Project | UDAY |
| Division | Paints (WRICEF ID-2B) |
| Module | PP / SD |
| Object | ZFORECAST Paints — Annual, Quarterly and Monthly Forecasting |
| Reference document | `Forecast_Template-Paints_1.xlsx` (no date or version inside the file). Builds on `Forecast Template-Adhesive.xlsx` dated 20.08.2026 |
| Sheets read | Sheet1, RADIO BUTTON 1 ANNUAL, Radio Button 2 Quauter, Month, Consolidated |
| Purpose | Development assumptions for confirmation, open queries for resolution, defects found in the FS, and the proposed object list for approval |
| Status of document | Draft — no version record, no approval, no message or authorisation section, no test scenarios. The "Month" sheet is a copy of the quarterly sheet. The annual sample rows do not line up with the annual column header |
| Prepared by | Arnav Johri, 19.10.2026 |

> **Status note, 23/10/26.** This is the v2 document of 19/10/26, kept as issued. Since then:
> P01, P21 and P26 — the separate Paints upload `ZPP_FORECAST_PAINTS_UPL` / `ZFCST_PAINTS_UPL`
> was withdrawn on 22/10; its two uploads live in the Adhesive `ZPP_FORECAST_UPLOAD` (ZFCST_UPL,
> ninth radio button Brand, four-value indicator). P16 — the Paints columns are now also **saved**,
> into `ZPPT_PNT_FCST_YR` / `_QT` / `_MN`. M4 — sales organisation 4000 is hardcoded in
> `ZCL_PP_FCST_PNT`, not configured. The queries themselves are still unanswered.
> Current state: `HANDOVER.md` and `ISSUES.md` in the folder above.

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

**Standing rule for this build: the Adhesive objects are in functional testing and work.
No Adhesive program, class, message or report is edited for Paints.** Paints calls the
Adhesive engine and reads and writes the Adhesive tables; everything Paints-specific is a
new object. The one DDIC touch that cannot be avoided without a worse design is listed
in 0.1 with its alternative.

### 0.1 Reuse decision, object by object

| Adhesive object | Paints use | Change to the Adhesive object |
|-----------------------------|------------------------------------------------------------|---------------------------|
| `ZPPT_PROD_CAT`, `ZPPT_MAT_TRACK`, `ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST`, `ZPPT_FCST_CFG` | Read and written for Paints plants | None |
| `ZPPT_FCST_YR`, `ZPPT_FCST_QT`, `ZPPT_FCST_MN` | Paints forecasts are saved here, keyed on Paints plants. The new columns are display only, so no field is added | None |
| Number range `ZPPFCST` | One sequence per financial year for both divisions | None |
| Auth object `ZPP_FCST` (plant, activity) | Paints plants are authorised with the same object | None |
| Message class `ZPP_FCST` | Messages 001–026 are read by the new programs | None. Any Paints-only message goes to a new class |
| `ZCL_PP_FCST_UTIL` | Called as is (financial year, quarter, period, tonnage helpers, authority checks) | None. Note the authority bypass of 07/09/26 is still live in it and Paints inherits it |
| `ZCL_PP_FCST` | Called as is: `GENERATE_ANNUAL`, `GENERATE_QUARTERLY`, `GENERATE_MONTHLY`, `SAVE`. Its public row type `TY_ALV` is the base of the Paints row type | None. The A923 price read, which Paints also needs for the annual mode, is private; it is re-implemented in the Paints class rather than opened up |
| `ZPP_FORECAST` (ZFCST) | Template for the new Paints program. Not used by Paints users | None |
| `ZPP_FORECAST_UPLOAD` (ZFCST_UPL) | Used by Paints users for tracking, exclusion, legacy history, business forecast (Q and M) and forecast change (Q and M) — six of its eight types. **Not usable** for the Paints product category (it refuses any indicator other than MTS or MTO) and has no brand type | None. Those two uploads go into a new Paints upload program |
| `ZPP_FORECAST_REPORT` (ZFCST_RPT) | Used as is; its columns are a superset of the Paints final report and the Consolidated sheet | None |
| `ZDO_MTS_MTO` domain | Must carry the two new values DIS and TIN for the category table to hold them | **Fixed values added, length unchanged.** DDIC only: no table conversion, no code, Adhesive upload still accepts only MTS and MTO. Alternative with zero touch: a Paints-only indicator field in `ZPPT_BRAND` — rejected because one column would then come from two tables |
| TVARVC `ZPP_FORECAST_MTART`, per-plant `ZPPT_FCST_CFG` rows, legacy TVARVC | Configuration. Paints plants need their own `ZPPT_FCST_CFG` rows (sales organisation 4000) | None in code |

What is duplicated as a consequence of the rule, and should be known: the A923 price read
(about 30 lines) and the file-reading routines of the upload program (Excel and text
reading, template download, roughly 400 lines) exist a second time in the Paints objects.
A fix to either on the Adhesive side has to be repeated on the Paints side.

## 1. Mandatory queries

These cannot be resolved by assumption. Development cannot produce a correct result until
each is answered.

| # | Query | FS section | What it affects |
|-------|----------------------------------------------------------|---------------|--------------------|
| M1 | The FS names the Adhesive tables as the tables Paints reads and saves into. Please confirm that one set of tables, one forecast number range (`ZPPFCST`) and one authorisation object (`ZPP_FCST`, by plant) serve both divisions, and that **a Paints plant is never also an Adhesive plant**. Every configuration the two divisions differ on (sales organisation, legacy TVARVC) is held per plant, so a plant that carries both divisions cannot be configured | Quarter sheet, save layout and "From ZPP_ADH_FORE_QUATER" | The whole data model. Nothing can be built until this is settled |
| M2 | Brand table. The FS calls it `ZPP_BRAND` in the logic rows and `ZPPT_BRAND` in the upload format. Please confirm: name `ZPPT_BRAND`, key plant + material, one field `BRAND`, and give the **length** of the brand and whether it is free text or a fixed list. Upload format read as Plant, Material, Brand | RADIO BUTTON 1 ANNUAL, rows 70 and 85 | DDIC. The domain cannot be created without a length |
| M3 | MTS / MTO / DIS ART / TINTING. The Adhesive indicator is a 3-character domain with the fixed values `MTS` and `MTO`, used by the category table and the three forecast tables, all of which hold data. Proposal: add fixed values `DIS` (Dis Art) and `TIN` (Tinting) to the same domain — no table conversion, no code change on the Adhesive side; Paints maintains its categories through the Paints upload. Please confirm the codes and give the long text of "DIS ART" | Every ALV header, column "MTS / MTO / DIS ART / TINTING" | Category upload (Paints), ALV display, four shared tables |
| M4 | Sales organisation. "QTY / CARTON" reads MVKE with `VKORG = 4000`; the material-group rows still say `VKORG = 1100`, which is the Adhesive value. Please confirm **4000 is the Paints sales organisation for every MVKE read** (material groups 1, 2, 5 and quantity per carton). It is held per plant in `ZPPT_FCST_CFG`, so this is configuration, not code, provided M1 holds | RADIO BUTTON 1 ANNUAL row 91; Quarter sheet rows 30–34 | Material group descriptions, quantity per carton |
| M5 | Pack size. "MARM-UMREN where the unit is not the base unit; ML or GM divided by 1000." A material usually has several alternative units (carton, litre, kilogram). Please confirm **which unit** gives the pack size when more than one exists. Proposal: the MARM row whose unit is L, ML, KG or G, taken in that order of preference, pack size = UMREN ÷ UMREZ (equal to UMREN when UMREZ is 1, as the FS assumes), ML and G divided by 1000. Please also confirm the unit codes as they exist in the system (gram is `G` in standard SAP, the FS writes `GM`) | RADIO BUTTON 1 ANNUAL row 88 | Every "Volume in KL" column |
| M6 | Additional forecast per month or per quarter. The quarterly ALV shows "July 26 additional / Aug 26 additional / Sep 26 additional" and a final per month, but the change-upload format has no Month column and the save list has one "Business Forecast M4 TO M6 additional". Adhesive settled this on 03/09/26: three per-month fields `BUS_FCST_ADD1/2/3`, a Month column on the quarterly change upload (1, 2 or 3 within the quarter). Paints uses the shared change upload, so it follows the same rule — please confirm | RADIO BUTTON 1 ANNUAL row 125; Quarter sheet rows 91 and 109–113 | Change upload, quarterly columns, saved fields |
| M7 | Annual ALV columns. The annual header lists forecast months only (quantity, KL, crores, tonnage) and no last-year history, while the sample rows underneath carry the twelve history months, the last-year total, category, growth and total forecast in the Adhesive order. Please confirm the annual list keeps the Adhesive columns (history months, total, category, growth, forecast total, forecast months) **and adds** the Paints columns, rather than replacing them | RADIO BUTTON 1 ANNUAL rows 23–29 and 75–80 | Annual ALV layout |

## 2. Assumptions

The points below are the assumptions on which development will proceed. Any assumption
not corrected in the "Confirmed / Correction" column will be treated as agreed and built as
stated. Adhesive assumptions C01–C46 (document of 20.08.2026) and every decision recorded
since in `kpmg/zpp_forecast_v2/ISSUES.md` carry over unless a row below says otherwise.

### 2.1 Scope and object identity

| # | Assumption | Confirmed (Y/N) / Correction |
|-------|-------------------------------------------------------------------------|--------------------|
| P01 | Paints is delivered as a **new generation program** `ZPP_FORECAST_PAINTS` (transaction `ZFCST_PAINTS`) with the three radio-button modes, and a **new upload program** `ZPP_FORECAST_PAINTS_UPL` (transaction `ZFCST_PAINTS_UPL`) for the two uploads the shared one cannot take: product category with the four indicator values, and brand. The Adhesive programs are not changed | |
| P02 | Paints **shares** with Adhesive, unchanged: the eight tables, number range `ZPPFCST`, authorisation object `ZPP_FCST`, message class `ZPP_FCST`, classes `ZCL_PP_FCST` and `ZCL_PP_FCST_UTIL`, the upload program `ZPP_FORECAST_UPLOAD` for tracking, exclusion, legacy history, business forecast and forecast change, and the final report `ZPP_FORECAST_REPORT` | |
| P03 | Every decision taken on Adhesive and not contradicted by the Paints FS applies to Paints: returns excluded (`VBRP-SHKZG` blank), history selected on billing date, financial year as one field `2026-2027`, legacy data all-or-nothing per year, material types restricted to TVARVC `ZPP_FORECAST_MTART` (FERT, HAWA), monthly history from billing documents rather than MATDOC 601, one forecast number shared by the three tables with no requirement that the annual forecast exists first, superseded codes absorbed into the successor with sales-history fill, up to five old codes per new code (the FS's two are a subset), load factor 1.000 when none is maintained, equal split when a divisor is zero, monthly formula built to the worked example | |
| P04 | "Last 3 years sales data upload in the custom table" is the existing legacy sales-history upload: one row per plant, material and year, three years are three rows. No new table, and only the previous year is read by the arithmetic, as on Adhesive | |
| P05 | The target system, client, package and release are those of the Adhesive objects. The release constraints already recorded for this landscape apply | |

### 2.2 New columns

| # | Assumption | Confirmed (Y/N) / Correction |
|-------|-------------------------------------------------------------------------|--------------------|
| P06 | Manufacturing plant name is `T001W-NAME1` for the row's plant | |
| P07 | Brand is read from `ZPPT_BRAND` by plant and material. A material with no brand row shows a blank brand; it is not an error and the row is not dropped | |
| P08 | Material Group 1, 2 and 5 are shown as descriptions (TVM1T, TVM2T, TVM5T), as on Adhesive. Material Group 3 and 4 are still read by the shared engine but are **not shown** on the Paints lists, as drawn. "Material Group" is `MARA-MATKL` | |
| P09 | DPL (dealer price) is the Adhesive price rule unchanged: `A923` on material alone, record with the latest `DATAB`, its `KONP-KBETR`. Quarterly and monthly rows already carry it from the engine; for the **annual** mode, which on Adhesive carries no price, the same read is implemented again in the Paints class. See query Q1 on the condition table | |
| P10 | Quantity per carton is `MVKE-AUMNG` for the plant's sales organisation where `MVGR1` is not blank, blank when there is no sales view. The SAP label of `AUMNG` is "minimum order quantity" — built as the FS says, see query Q2 | |
| P11 | Gross weight is `MARA-BRGEW` with its weight unit. **Tonnage = forecast quantity × gross weight ÷ 1000**, so a gross weight in KG gives tonnes. This replaces, for Paints only, the Adhesive tonnage (quantity × net weight, no division). The Paints program overwrites the engine's tonnage before display and save, so the quarterly save stores the Paints tonnage in the same `M4_TON`–`M6_TON` fields | |
| P12 | Volume in KL = forecast quantity × pack size ÷ 1000, one column per forecast month. In quarterly and monthly it uses the **final** quantity of the month (forecast plus additional); in annual it uses the month's forecast quantity | |
| P13 | Value in crores = DPL × the same quantity ÷ 1,00,00,000, one column per forecast month. `KBETR` is taken as the price of one unit in INR; pricing unit and currency are not evaluated, as on Adhesive | |
| P14 | Each forecast month uses its own quantity. The FS formulas repeat "April 25" for all twelve months; this is read as a copy-and-paste slip, as Adhesive C21 | |
| P15 | The header cells `FEB 26` and `MAR 26` under `Q4_26-27` are read as `FEB 27` and `MAR 27`. The thirteenth "Value in Crores" column (a repeat of March) is not built | |
| P16 | Brand, plant name, pack size, DPL, quantity per carton, gross weight, KL and crores are **display only**. The save layout is the Adhesive one; no field is added to any forecast table | |
| P17 | The "Month" sheet is a copy of the quarterly sheet. Monthly is built as Adhesive monthly plus the Paints master-data columns and one KL column for the month. No crore column on monthly, as none is drawn — see query Q3 | |
| P18 | MSL is an Adhesive-only column. The Paints monthly list does not show it. Because the monthly business-forecast upload is shared, an MSL value uploaded for a Paints plant is still stored and added into the monthly total by the engine; Paints users leave column 6 of that template blank | |

### 2.3 Selection screens, uploads, save, report

| # | Assumption | Confirmed (Y/N) / Correction |
|-------|-------------------------------------------------------------------------|--------------------|
| P19 | Selection screens are the Adhesive ones: plant range, material range, financial year, quarter or period or date range, Tonnage Wise, Legacy Data (TVARVC-protected). "Tonnage Wise with Gross Weight" is the same checkbox; only the weight used differs | |
| P20 | For the six shared upload types Paints users download and use the **shared templates** from ZFCST_UPL. The column order in the FS (plant before material on Sheet1, material before plant on the quarter sheet) is not followed; the downloaded template is authoritative | |
| P21 | Paints upload program: two radio buttons. **Product category** — Plant, Material, Category, Load Factor, Indicator; the indicator accepts MTS, MTO, DIS, TIN or blank; plant and material checked against MARC; overwrite or insert into `ZPPT_PROD_CAT`. **Brand** — Plant, Material, Brand; same checks; overwrite or insert into `ZPPT_BRAND`. Both with a template download, test run and the row-by-row result list of the Adhesive upload | |
| P22 | The MTS / MTO column on every Paints list shows the code (MTS, MTO, DIS, TIN) | |
| P23 | Save behaviour is the Adhesive one in all three modes: `ZCL_PP_FCST=>SAVE` on the selected rows, one forecast number per plant, material and financial year across the three tables | |
| P24 | The final report is `ZPP_FORECAST_REPORT` (ZFCST_RPT) **as it stands**. Its columns are a superset of the Paints final report (material, plant, description, material group, groups 1, 2, 5, annual, quarter, additional, total quarter, monthly, additional, total monthly, forecast number) and the "Consolidated" sheet (same columns plus month, selection by material group). Plant selection separates the divisions. No new report, no brand column on the report | |
| P25 | Authorisation: `ZPP_FCST` by plant and activity covers Paints plants; no new authorisation object. Legacy-data authorisation via the per-plant TVARVC name in `ZPPT_FCST_CFG` | |
| P26 | Transaction codes: `ZFCST_PAINTS` and `ZFCST_PAINTS_UPL` for the new programs. `ZFCST_UPL` and `ZFCST_RPT` serve both divisions | |

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
| Q7 | Material type restriction: Adhesive restricts the lists to the material types in TVARVC `ZPP_FORECAST_MTART` (FERT, HAWA). The same variable applies to Paints through the shared engine. Please confirm, or name the Paints types — a different list would need a Paints-specific variable, which the engine does not support without a change | Before unit test |
| Q8 | Brand maintenance: besides the upload, is an SM30 view (`ZPPV_BRAND`) wanted for manual maintenance, as the other configuration tables have? | Before SE54 |
| Q9 | Final report selection: the FS marks both Month and Quarter as mandatory. They cannot both be mandatory on one screen. The Adhesive report has both optional; built that way | Before unit test |
| Q10 | The FS carries no version record, approval, message list, authorisation matrix or test scenarios, and the annual worked example does not match its own header. Please complete and sign off to baseline it | Before baseline |

## 4. Proposed objects — for approval before any code

In dependency order, which is also paste order. Manual steps are marked. No Adhesive
program or class appears in this list.

| # | Object | Type | New / changed | Purpose | Depends on |
|-----|-----------------|------------|------------|-------------------------------------------|------------|
| 1 | `ZDO_BRAND` | Domain | New | CHAR, length per M2 | M2 |
| 2 | `ZDE_BRAND` | Data element | New | "Brand" | 1 |
| 3 | `ZPPT_BRAND` | Table | New | Key MANDT, WERKS, MATNR; BRAND; ERNAM, ERDAT, AENAM, AEDAT | 2 |
| 4 | `ZPPV_BRAND` | SM30 view | New, **manual SE54** | Brand maintenance, if Q8 is yes | 3 |
| 5 | `ZDO_MTS_MTO` | Domain | Changed, DDIC only | Fixed values DIS and TIN added, length unchanged. The only touch on an Adhesive object; see 0.1 | M3 |
| 6 | `ZCL_PP_FCST_PNT` | Class | New | Paints enrichment. Row type = `ZCL_PP_FCST=>TY_ALV` plus the Paints columns. `ENRICH` reads T001W, ZPPT_BRAND, MARM, MVKE-AUMNG, MARA-BRGEW and, for annual, A923 → KONP; recomputes tonnage on gross weight ÷ 1000; computes KL and crores per month. Display only | 3 |
| 7 | `ZPP_FORECAST_PAINTS_UPL` | Report | New | Product category (four indicator values) and brand uploads, with template download, test run and result list. File handling copied from `ZPP_FORECAST_UPLOAD` | 3, 5 |
| 8 | `ZPP_FORECAST_PAINTS` | Report | New | Selection screen and SALV handling copied from `ZPP_FORECAST`; calls `ZCL_PP_FCST` to generate, `ZCL_PP_FCST_PNT` to enrich, `ZCL_PP_FCST=>SAVE` to save; column lists per the Paints layouts | 6 |
| 9 | `PF_STATUS` of `ZPP_FORECAST_PAINTS` | GUI status | New, **manual SE41** | Copy of the Adhesive status (SALV_STANDARD plus ZSAVE, ZSELALL, ZDESEL, ZEXCEL) | 8 |
| 10 | `ZFCST_PAINTS`, `ZFCST_PAINTS_UPL` | Transactions | New, **manual SE93** | | 7, 8 |
| 11 | `ZPPT_FCST_CFG` rows for the Paints plants | Configuration | **Manual SM30** | Sales organisation 4000, legacy TVARVC name | M1, M4 |
| 12 | `ZPP_FORECAST`, `ZPP_FORECAST_UPLOAD`, `ZPP_FORECAST_REPORT`, `ZCL_PP_FCST`, `ZCL_PP_FCST_UTIL`, `ZPP_FCST`, the eight tables, `ZPPFCST` | | **No change** | Shared, used as they are | |

Messages: the Paints uploads reuse `ZPP_FCST` 012, 013, 014, 015 and 024 by reading them;
the result texts are literals in the program as on Adhesive. No new message number is
expected; if one is needed it goes into a new class `ZPP_FCST_PNT`, not into `ZPP_FCST`.

## 5. Requirement mapping

| FS requirement | Where | Implemented by |
|-----------------------------------|-------------------------|----------------------------------------|
| Annual, quarterly, monthly forecasting with the Adhesive arithmetic | Sheet1 1.1–1.3 | `ZCL_PP_FCST` (shared), called from `ZPP_FORECAST_PAINTS` |
| Selection screens incl. Tonnage Wise and Legacy Data | All mode sheets | `ZPP_FORECAST_PAINTS`, copied from `ZPP_FORECAST` |
| Product category, load factor, indicator maintenance and upload | Annual sheet rows 32–47 | `ZPPT_PROD_CAT` (shared); upload in `ZPP_FORECAST_PAINTS_UPL` because of the two new indicator values; domain change |
| Material tracking (new code, old codes) | Annual sheet rows 50–62 | `ZPPT_MAT_TRACK`, ZFCST_UPL type TRK (shared, five old codes) |
| Material exclusion | Annual sheet rows 64–70 | `ZPPT_MAT_EXCL`, ZFCST_UPL type EXC (shared) |
| Brand per plant and material, upload | Annual sheet rows 70, 85 | `ZPPT_BRAND`, `ZPP_FORECAST_PAINTS_UPL`, `ZCL_PP_FCST_PNT` |
| Mfg plant name | Annual sheet row 84 | `ZCL_PP_FCST_PNT` (T001W) |
| Material group, groups 1, 2, 5 | Row 87; quarter sheet 30–34 | engine (shared), displayed by `ZPP_FORECAST_PAINTS` |
| Pack size | Annual sheet row 88 | `ZCL_PP_FCST_PNT` (MARM), rule per M5 |
| Gross weight, tonnage on gross weight ÷ 1000 | Rows 89, 120 | `ZCL_PP_FCST_PNT` |
| DPL | Row 90 | engine (quarterly, monthly); `ZCL_PP_FCST_PNT` (annual) |
| Qty per carton | Row 91 | `ZCL_PP_FCST_PNT` (MVKE-AUMNG) |
| Volume in KL per month | Rows 92–103 | `ZCL_PP_FCST_PNT` |
| Value in crores per month | Rows 104–116 | `ZCL_PP_FCST_PNT` |
| Last-year sales history upload (WRICEF 2) | Sheet1 row 93; "J" | ZFCST_UPL type HIST (shared) |
| Sales forecast upload, quarterly and monthly (WRICEF 3) | Quarter sheet rows 102–106 | ZFCST_UPL types BUSQ / BUSM (shared) |
| Change upload with reason (WRICEF 4) | Quarter sheet rows 109–115 | ZFCST_UPL types CHGQ / CHGM (shared), per M6 |
| Save with forecast number, quarter condition | Quarter sheet rows 58–100 | `ZCL_PP_FCST=>SAVE` (shared) |
| Final report and Consolidated view | Sheet1 rows 98–108, Consolidated | `ZPP_FORECAST_REPORT` as is (P24) |

Nothing in the FS maps to no object. Nothing is built that the FS does not ask for.

## 6. Before the build can start

1. Answers to M1–M7.
2. Approval of the object list in section 4, or corrections to it.
3. A fresh `ZR_PROG_DOWNLOAD` of `ZPP_FORECAST` and `ZPP_FORECAST_UPLOAD` from the running
   system. Both are copied, not changed, but the copy must start from what runs, and no
   download has been supplied since 03/09/26. `ZCL_PP_FCST` is called, not copied, so its
   public interface as in the repo is enough — unless it has been edited in SAP since
   30/09/26, in which case its download too.
4. The current SE11 state of `ZDO_MTS_MTO` (fixed values) and `ZPPT_PROD_CAT`.
5. Confirmation that the target is the same development system and client as the
   Adhesive objects.

## 7. Position summary

The Paints template changes what is shown, not what is calculated. Reusing the Adhesive
tables, engine, six of the eight upload types and the report is the natural reading of
the FS, which names those very tables, and it keeps the two divisions from drifting apart.
Under the rule that nothing Adhesive is edited, the build is: one new table with its
domain, data element and view; one enrichment class; one generation program; one
two-type upload program; and two fixed values on one domain.

Two points carry real risk if left to assumption: whether a plant can belong to both
divisions (M1, which decides whether per-plant configuration is enough), and the pack-size
rule (M5, which drives every kilolitre figure). The annual worked example cannot be used to
verify the arithmetic because its columns do not match its own header; a corrected example
is requested under Q10.

## 8. Defects and inconsistencies found in the FS

Listed so the FS can be corrected and re-issued. Each is tied to an assumption or query
above; none is resolved silently in code.

| # | Finding | Where | Handled under |
|-----|---------------------------------------------------------------------------|---------------------|------------|
| F01 | The "Month" sheet is a copy of the quarterly sheet: headed 1.3 Monthly Forecasting but with Quarter mandatory, the Q2 example, the M4–M6 save layout and no monthly formula. Monthly logic exists only on Sheet1 row 78 and the one-month header at RADIO BUTTON 1 row 135 | Month sheet | P17 |
| F02 | Annual header and sample disagree: the header has no last-year history columns, the sample rows carry twelve history months, total, category, growth and forecast total in the Adhesive order, ten columns out of step with the header | RADIO BUTTON 1 rows 23–29, 75–80 | M7 |
| F03 | Header typos: `FEB 26` and `MAR 26` under `Q4_26-27` should read 27; thirteen "Value in Crores" columns for twelve months (the last repeats March) | RADIO BUTTON 1 rows 23, 75 | P15 |
| F04 | Sales organisation 4000 in the quantity-per-carton row, 1100 in the material-group rows | RADIO BUTTON 1 row 91; Quarter rows 30–34 | M4 |
| F05 | Tonnage on gross weight ÷ 1000 on the annual sheet; net weight × quantity, no division, in the quarter sheet logic rows. The quarterly header shows both tonnage columns and a gross-weight column | RADIO BUTTON 1 rows 89, 120; Quarter rows 29, 53–55 | P11, Q4 |
| F06 | Pack-size rule incomplete: no rule for a material with several alternative units; refers to `MARA-MEINH`, which does not exist (`MARM-MEINH` meant); unit written `GM` where SAP uses `G`; UMREN alone is right only when UMREZ is 1 | RADIO BUTTON 1 row 88 | M5 |
| F07 | Additional forecast is per month on the ALV (three "additional" and three "final" columns) but the change-upload format has no Month column and the save list has one "additional" | RADIO BUTTON 1 row 125; Quarter rows 91, 109–113 | M6 |
| F08 | Upload column order differs between Sheet1 (Plant, Material, Quarter, FY, Qty) and the quarter sheet (Material, Plant, Quarter, Year, Sales Forecast), and both differ from the Adhesive templates in use | Sheet1 rows 57, 62; Quarter rows 104, 111 | P20 |
| F09 | Brand table named `ZPP_BRAND` in the logic and `ZPPT_BRAND` in the upload block; the upload block sits under the exclusion upload heading, so it is unclear whether brand is a new upload or a column added to the exclusion upload; no brand length | RADIO BUTTON 1 rows 70, 85 | M2 |
| F10 | "MTS / MTO / DIS ART / TINTING": four values against a two-value, 3-character domain; no codes or descriptions given | Every header | M3 |
| F11 | KL and crore formulas repeat "April 25" for all twelve months | RADIO BUTTON 1 rows 92–116 | P14 |
| F12 | KL formula divides by 1000; the illustration row (100 × 10 = 1000) does not | RADIO BUTTON 1 rows 12, 92 | P12 |
| F13 | Crore formula does not say which quantity in quarterly and monthly: the split month or the final month including the additional | RADIO BUTTON 1 rows 104–116 | P12, P13 |
| F14 | Material Group 3 and 4 defined in the logic rows, absent from every header | Quarter rows 32–33 | P08, Q5 |
| F15 | A UOM column is defined in the logic (`MARA-MEINS`) but appears in no header | RADIO BUTTON 1 row 86 | not built |
| F16 | Final report: Month and Quarter both marked mandatory | Sheet1 rows 104–105 | Q9 |
| F17 | Two layouts for the final report: Sheet1 (with forecast number, no month) and the Consolidated sheet (with month and material-group selection, no forecast number) | Sheet1 rows 98–108; Consolidated | P24 |
| F18 | Quantity per carton mapped to `MVKE-AUMNG`, whose SAP meaning is minimum order quantity | RADIO BUTTON 1 row 91 | Q2 |
| F19 | "VBRP-SHKZG is not equal to blank" — selects returns only. Carried over from the Adhesive FS, where it was verified wrong in the system on 21.08.2026 | Quarter row 26 | P03 |
| F20 | Old material codes summed from `MATDOC-MENGE` while the list reads billing quantity — the Adhesive FS defect M2, carried over. Adhesive built old codes on billing on 15/09/26 | Quarter row 35 | P03 |
| F21 | Monthly sales-history source not stated (copy of the quarterly sheet). Adhesive moved monthly from MATDOC 601 to billing on 15/09/26 | Month sheet | P03 |
| F22 | "Last 3 years sales data upload" — three years are uploaded but only the previous year is used by any formula | Sheet1 rows 48, 85 | P04 |
| F23 | Date-range alternative ("last year 3 months forward and current year last 3 months") does not say how a range off a quarter boundary is handled. Adhesive C08 applies | Sheet1 row 39 | P03 |
| F24 | Quarterly sample rows show `#DIV/0!` in the month-split columns, so the split cannot be verified against the example | Quarter rows 18–22 | Q10 |
| F25 | The twelve annual tonnage columns and the gross-weight column appear only in the second annual block, not in the first | RADIO BUTTON 1 rows 23, 75 | P11 |
| F26 | Financial year drawn as two fields (From, To) on Sheet1; one field on the quarter sheet. Adhesive built one field | Sheet1 row 9; Quarter row 8 | P19 |
| F27 | The Legacy Data checkbox appears on the mode sheets but not on the Sheet1 selection screens | Sheet1 rows 6–10 | P19 |
| F28 | No version, date, approval, message list, authorisation matrix or test scenarios | Whole document | Q10 |
