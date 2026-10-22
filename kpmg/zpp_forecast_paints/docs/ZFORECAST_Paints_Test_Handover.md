# ZFORECAST Paints — functional test pack

Astral / UDAY (KPMG) · Paints division (WRICEF ID-2B) · PP / SD
Prepared 22.10.2026 by Arnav Johri · Development system · Transport **DEVK930479**
(UDAYABAP03, "UDAY: PP: 2B: Forcast Paints"), not released.

## A. What is delivered

| Transaction | What it does |
|------------------|----------------------------------------------------------------------|
| **ZFCST_PAINTS** | Forecast generation for Paints plants: Annual, Quarter Based, Month Based. Shows the Paints list (brand, pack size, DPL, qty per carton, KL, crores, tonnage) and saves the selected rows |
| **ZFCST_UPL** | All nine uploads, shared with Adhesive: Product Category (now with MTS / MTO / DIS / TIN), Material Tracking, Material Exclusion, Legacy Sales History, Business Forecast Quarterly, Business Forecast Monthly, Forecast Change Quarterly, Forecast Change Monthly, **Brand** (new) |
| **ZFCST_RPT** | Final forecast report, shared with Adhesive; select the Paints plants |
| Tables (SE16) | `ZPPT_PNT_FCST_YR`, `ZPPT_PNT_FCST_QT`, `ZPPT_PNT_FCST_MN` hold the saved Paints forecasts exactly as the list shows them; `ZPPT_BRAND` the brands; `ZPPT_PROD_CAT`, `ZPPT_MAT_TRACK`, `ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST` the configuration and history; `ZPPT_FCST_YR` / `_QT` / `_MN` the shared rows the report reads |

Built to Sheet1 of `Forecast_Template-Paints_1.xlsx`. Where the sheets disagree Sheet1 was
taken; the points that needed a decision are listed in section H and are what this test
should settle.

## B. One-time setup before the first run

| # | Where | What | Why |
|-----|------------------|----------------------------------------------|------------------------------------|
| 1 | Nothing to configure for the sales organisation | Sales org 4000 is fixed in the program, as the FS states | Material groups 1, 2, 5 and quantity per carton are read from the sales view of 4000 |
| 2 | STVARV `ZPP_FORECAST_MTART` | FERT and HAWA (already maintained for Adhesive) | Only these material types appear on the lists |
| 3 | Test materials, master data | Sales view in sales org 4000 with Material Group 1, 2, 5 filled; an alternative unit L, ML, KG or G in Additional Data → Units of Measure; gross weight; a DPL condition record (condition table A923) | Qty per carton, material groups, pack size, tonnage and DPL come from here. A material without them shows blank or zero in that column, which is not an error |
| 4 | Test materials, sales | Billing documents (invoices, not returns, not cancelled, not pro forma) in the previous financial year and in the three months before the planned period, for the Paints plant | This is the sales history. Without it, upload Legacy Sales History (step 5 of section D) |
| 5 | Authorisation | None needed in DEV: the plant authorisation checks are switched off for testing. Any user with the transactions can run everything | Authorisation is not part of this test |

## C. Upload files for ZFCST_UPL

Press the **Download Template** button beside the upload type; the file carries the column
headings in the right order. Keep row 1 and the column order. Save as .xlsx or .csv. Material
codes may be typed without leading zeros. Thousand separators are removed. **Test Run** is
ticked by default: the file is checked and the result list shown, nothing is saved. Untick it
for the real run. Good rows are saved even when other rows are rejected; every row appears
on the result list with Created / Changed / Rejected and the reason.

| Upload type | Columns in order | Rules |
|------------------|----------------------------------------------|------------------------------------|
| Product Category | Plant, Material, Product Category, Load Factor, MTS/MTO | Category mandatory. Load factor a number above 0 (1.300 = 30 % growth). Indicator MTS, MTO, DIS or TIN; "DIS ART" and "TINTING" are accepted and stored as DIS and TIN; blank allowed |
| Brand | Plant, Material, Brand | Brand mandatory, up to 40 characters, free text |
| Material Tracking | Plant, New Material, Old Material 1 … Old Material 5 | At least one old code; old codes differ from the new one and from each other; an old code that is itself a new code elsewhere is refused |
| Material Exclusion | Plant, Material | Material left out of every list |
| Legacy Sales History | Plant, Material, Year, April … March (12 columns), Unit | Year = the year the financial year starts in (2025 means April 2025 to March 2026). All twelve zero is rejected |
| Business Forecast Quarterly | Material, Plant, Quarter, Year, Forecast Quantity | Quarter 1 to 4 (1 = April to June). Year = start year of the financial year (2026 for 2026-2027). Not negative |
| Business Forecast Monthly | Material, Plant, Period, Year, Forecast Quantity, MSL | Period 1 to 12 (1 = April). Leave MSL blank for Paints |
| Forecast Change Quarterly | Material, Plant, Quarter, Month, Year, Forecast Quantity, Reason | **Month 1, 2 or 3 within the quarter** (quarter 2 month 1 = July). Quantity may be negative. Reason mandatory. The final quantity may not go below zero |
| Forecast Change Monthly | Material, Plant, Period, Year, Forecast Quantity, Reason | As above, per period |

Every upload checks that the material exists in the plant; a row that fails is rejected with
"Material … is not extended to plant …".

## D. Test sequence — run in this order, check the table after each step

| # | Tcode | Do this | Then check (SE16) |
|-----|------------------|----------------------------------------------|------------------------------------|
| 1 | ZFCST_UPL → Product Category | Template, fill, test run, real run. Include one row with DIS ART, one with TINTING, one with MTS | `ZPPT_PROD_CAT`: PROD_CAT, LOAD_FCT, MTS_MTO (DIS, TIN, MTS) |
| 2 | ZFCST_UPL → Brand | Template, fill, test run, real run | `ZPPT_BRAND`: BRAND |
| 3 | ZFCST_UPL → Material Tracking | New code and its old codes | `ZPPT_MAT_TRACK` |
| 4 | ZFCST_UPL → Material Exclusion | One material to leave out | `ZPPT_MAT_EXCL` |
| 5 | ZFCST_UPL → Legacy Sales History | Only if the previous year's sales are not in SAP | `ZPPT_SLS_HIST`: M01 = April … M12 = March |
| 6 | ZFCST_PAINTS → Annual Forecast Generation, Tonnage Wise ticked | Plant, material range, financial year 2026-2027. Execute. Check section E. Select rows → Save | `ZPPT_PNT_FCST_YR`: one row per plant, material, year with every list column. The same row without the Paints columns in `ZPPT_FCST_YR` |
| 7 | ZFCST_UPL → Business Forecast Quarterly | Quarter 2, year 2026, a quantity above and one below the calculated forecast | `ZPPT_FCST_QT`: BUS_FCST |
| 8 | ZFCST_PAINTS → Quarter Based Planning, quarter 2, Tonnage Wise ticked | Execute, check section E, Save | `ZPPT_PNT_FCST_QT`: every list column, M4 … M6 blocks. Also `ZPPT_FCST_QT` |
| 9 | ZFCST_UPL → Forecast Change Quarterly | Quarter 2, month 1 (July), year 2026, +500 and a second row −200 with reasons | `ZPPT_FCST_QT`: BUS_FCST_ADD1 and REASON. Re-run step 8: "Jul-26 additional" shows the net change, "Jul-26 final forecast" = forecast + additional, KL and crores follow |
| 10 | ZFCST_UPL → Business Forecast Monthly | Period 4 (July), year 2026 | `ZPPT_FCST_MN`: BUS_FCST |
| 11 | ZFCST_PAINTS → Month Based Planning, period 4, Tonnage Wise ticked | Execute, check section E, Save | `ZPPT_PNT_FCST_MN`: every list column. Also `ZPPT_FCST_MN` |
| 12 | ZFCST_UPL → Forecast Change Monthly | Period 4, year 2026, a change with reason | `ZPPT_FCST_MN`: BUS_FCST_ADD, REASON. Re-run step 11 |
| 13 | ZFCST_RPT | Plant, financial year 2026-2027 | Annual, quarter, additional, total quarter, monthly, additional, total month per material, with one forecast number per material |
| 14 | SLG1, object ZPP_FCST, subobject GENERATE | After any run that looks wrong | The run's messages: no category, load factor defaulted, superseded code shown under its successor, configuration missing |

The forecast number is drawn on the first save of a plant, material and financial year and
reused by the other two modes.

## E. What each column of the ZFCST_PAINTS list should show

**Lead columns, all three modes**

| Column | Expected |
|------------------------|----------------------------------------------------------------------|
| Mfg. Plant Code / Name | Plant and its name |
| Brand | As uploaded; blank when none |
| Mat. Code / Mat. Desc | Material and description |
| MTS / MTO / Dis Art / Tinting | MTS, MTO, DIS or TIN as uploaded |
| Material Group 1 / 2 / 5 | Descriptions from the sales view, sales org 4000 |
| Material Group | Material group of the material master |
| Pack Size | From the L / ML / KG / G unit of the material: litres or kilograms per piece. 4 L can → 4.000; 500 ML bottle → 0.500 |
| DPL | Dealer price, latest condition record of the material |
| Qty / Carton | Minimum order quantity of the sales view, sales org 4000 |

**Annual**: twelve "Qn Mon-yy Forecast Qty" = last year's same month × load factor; twelve
"Volume in KL" = quantity × pack size ÷ 1000; twelve "Value in Crores" = DPL × quantity ÷
1,00,00,000; with Tonnage ticked, Gross Weight and twelve "Mon-yy Tonnage" = quantity × gross
weight ÷ 1000. Last year's months, the total, category and growth are hidden; **Change Layout**
on the toolbar brings them in.

**Quarterly**: last year's three months and their total; the current last three months and
their total; Max. Qty = the higher of the two totals; Product Cat., Growth; Forecast =
Max × growth; Business Forecast (from the upload); Final Forecast Qty = higher of Forecast and
Business Forecast; then per month: Mon-yy = final split in last year's proportions, Mon-yy
additional (change upload), Mon-yy final forecast = the two added, Mon-yy KL, Mon-yy in Cr,
Mon-yy tonnage (gross weight ÷ 1000) when ticked; Gross Weight.

**Monthly**: last year's three months and total; current three months and total; Max. Qty =
higher of last year's same month and (three-month average × growth); Product Cat., Growth;
Forecast; Business Forecast; Final Forecast Qty = higher of the two; Mon-yy additional;
Mon-yy final forecast = final + additional; Mon-yy KL; Mon-yy in Cr; Mon-yy tonnage when
ticked; Gross Weight.

**After Save**: Forecast Number and Message appear at the end of the list. Save, Select all,
Deselect all and Export are the four buttons on the toolbar; Export writes the list as a tab
separated file.

## F. Test cases with expected results

| # | Case | Expected |
|-----|------------------------------------------------------|----------------------------------------------|
| 1 | Category upload with indicator "DIS ART" | Stored as DIS, list shows DIS |
| 2 | Category upload with indicator "xyz" | Row rejected: "Indicator must be MTS, MTO, DIS, TIN or nothing" |
| 3 | Brand upload, material not in the plant | Row rejected: "Material … is not extended to plant …"; other rows saved |
| 4 | Brand upload twice with the same file | First run Created, second run Changed; brand unchanged |
| 5 | Annual run, material with category C, growth 1.2, April last year 1,000 | April forecast 1,200; KL = 1,200 × pack size ÷ 1000; crores = DPL × 1,200 ÷ 1,00,00,000 |
| 6 | Annual run, material with sales but no category | Row shown, growth 1.000, forecast = last year; SLG1 carries "No product category" |
| 7 | Annual run, material in the exclusion table | Not on the list |
| 8 | Annual run, old code entered on the selection screen | The successor is shown, carrying the old code's figures only; SLG1 message "Material … is superseded by …" |
| 9 | Annual run, material with no L / ML / KG / G unit | Pack size blank, KL 0, everything else filled |
| 10 | Annual run, no DPL record | DPL 0, crores 0 |
| 11 | Annual Save, then run again | Row marked already saved, same forecast number; Save overwrites under the same number |
| 12 | Quarterly, business forecast 12,000 against forecast 16,900 | Final 16,900 (the higher); split in last year's proportions |
| 13 | Quarterly, business forecast 4,000 against forecast 3,315 | Final 4,000 |
| 14 | Quarterly change +500 month 1, then −200 month 1 | Jul additional 300, Jul final = Jul forecast + 300 |
| 15 | Quarterly change that would take the month below zero | Row rejected |
| 16 | Quarterly change, month 7 | Rejected: month must be 1 to 3 |
| 17 | Monthly, period 4, Tonnage ticked, material gross weight 1.250 kg | Tonnage = final × 1.250 ÷ 1000 |
| 18 | Save with no row selected | Message "Select at least one line" |
| 19 | Save: quarterly first, annual later for the same material | Both carry the same forecast number |
| 20 | ZFCST_RPT for the plant | One line per material with annual, quarterly, additional, monthly, additional and totals; forecast number matches |
| 21 | Material with no sales view in sales org 4000 | Material groups 1, 2, 5 and qty per carton blank; everything else filled |
| 22 | Tonnage Wise unticked | No tonnage and no gross weight columns; KL and crores still shown |

## G. Behaviour to be aware of

1. Sales history comes from billing documents on billing date: returns, cancelled and pro
   forma documents are excluded. Legacy history from the upload is used only when the Legacy
   checkbox is ticked, and that checkbox is drawn only when the TVARVC switch `ZPP_FCST_LEGACY`
   is set; in Paints it is normally not shown.
2. Monthly history is read from billing documents, the same as quarterly.
3. Tonnage is quantity × gross weight ÷ 1000 in all three modes, on the final quantity.
4. Crores are DPL × quantity ÷ 1,00,00,000 with DPL taken as the price of one piece.
5. The annual list hides last year's months, the total, category and growth by default; they
   are available through Change Layout.
6. The monthly list shows a value-in-crores column although the template does not draw one.
7. Each Save writes the Paints table and the shared Adhesive-shaped table. The final report
   and the change uploads work on the shared one.
8. Manual entry of DIS or TIN through SM30 on the category table is refused until the two
   values are added to the domain; the upload writes them regardless.
9. The plant authorisation checks are switched off in DEV for testing.
10. Material types are restricted to FERT and HAWA by the TVARVC variable shared with Adhesive.

## H. Decisions this test should settle

1. Pack size: is "the material's L / ML / KG / G unit, litres or kg per piece" the pack size
   the business means, and are those the unit codes in use?
2. Quantity per carton: is the sales-view minimum order quantity the right field?
3. Tonnage on gross weight ÷ 1000, on the final quantity, in all three modes: agreed?
4. Value in crores on the monthly list: keep or drop?
5. Annual list: history months hidden by default, or shown?
6. DIS ART and TINTING stored as DIS and TIN: agreed, and what is the long text of DIS ART?
7. Sales organisation 4000 for every Paints plant: confirmed?
8. Is any plant used by both Adhesive and Paints? If so, say so before go-live.

## I. How to report a finding

Plant, material, financial year, mode (annual, quarter n, month n), the column, the figure
shown, the figure expected and how it was worked out, a screenshot of the list. For an
upload: the file and the result list. One finding per mail is easiest to track.
