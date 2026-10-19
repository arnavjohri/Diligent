# ZFORECAST Paints — what to run and what to check

Astral / UDAY (KPMG), Paints division. Functional test handover, 19.10.2026, Arnav Johri.
Development system. Run in the order below; each step feeds the next.

## 1. Before the first run (one-time setup)

| Where | What | Why |
|------------------------|----------------------------------------------|------------------------------------|
| SM30 `ZPPV_FCST_CFG` | One row per Paints plant: Sales Org = 4000 | Material groups and quantity per carton are read for this sales org. Without the row the run logs a warning and uses 4000 anyway |
| STVARV `ZPP_FORECAST_MTART` | Material types FERT and HAWA (already there for Adhesive) | Only these material types appear on the lists |
| Master data of the test materials | Sales view in sales org 4000 with Material Group 1 filled; alternative unit L, ML, KG or G in the material master (Additional Data → Units of Measure); gross weight; a DPL condition record (A923) | Qty per carton, pack size, tonnage and DPL come from here. A material without them shows blank or zero in that column, not an error |

## 2. Programs to run and tables to check, in order

| # | Tcode | Do this | Then check (SE16) |
|-----|------------------|----------------------------------------------|------------------------------------|
| 1 | `ZFCST_PAINTS_UPL` → Product Category (Paints) | Download Template, fill plant, material, category, load factor, indicator (MTS, MTO, DIS or TIN). Run with Test Run ticked, then unticked | `ZPPT_PROD_CAT`: one row per plant and material, PROD_CAT, LOAD_FCT, MTS_MTO as uploaded |
| 2 | `ZFCST_PAINTS_UPL` → Brand | Download Template, fill plant, material, brand. Test run, then real run | `ZPPT_BRAND`: BRAND as uploaded |
| 3 | `ZFCST_UPL` → Material Tracking | New code and its old codes, per plant | `ZPPT_MAT_TRACK` |
| 4 | `ZFCST_UPL` → Material Exclusion | Materials to leave out | `ZPPT_MAT_EXCL` |
| 5 | `ZFCST_UPL` → Legacy Sales History | Only if last year's sales are not in SAP: twelve months per plant, material, year (year = the April the financial year starts in) | `ZPPT_SLS_HIST`: M01 = April … M12 = March |
| 6 | `ZFCST_PAINTS` → Annual, Tonnage Wise ticked | Plant, material, financial year 2026-2027. Execute | On screen only, see section 3. Select rows → Save | `ZPPT_FCST_YR`: one row per plant, material, year with FCST_NO, M01_FCST…M12_FCST |
| 7 | `ZFCST_UPL` → Business Forecast Quarterly | Plant, material, quarter, year, quantity | `ZPPT_FCST_QT`: BUS_FCST |
| 8 | `ZFCST_PAINTS` → Quarter Based, quarter 2, Tonnage Wise ticked | Execute, check section 3, Save | `ZPPT_FCST_QT`: FCST_NO, FINAL_QTY, M4_FCST…M6_FCST, M4_TON…M6_TON (gross weight ÷ 1000), PRICE |
| 9 | `ZFCST_UPL` → Forecast Change Quarterly | Plant, material, quarter, **month 1, 2 or 3 within the quarter**, year, quantity (negative allowed), reason | `ZPPT_FCST_QT`: BUS_FCST_ADD1 / 2 / 3 and REASON; then re-run step 8 and see the "additional" and "final forecast" columns |
| 10 | `ZFCST_UPL` → Business Forecast Monthly | Plant, material, period (1 = April … 12 = March), year, quantity; leave the MSL column blank | `ZPPT_FCST_MN`: BUS_FCST |
| 11 | `ZFCST_PAINTS` → Month Based, period 4, Tonnage Wise ticked | Execute, check section 3, Save | `ZPPT_FCST_MN`: FCST_NO, FINAL_QTY, BUS_FCST_ADD, M4_FCST, M4_TON |
| 12 | `ZFCST_UPL` → Forecast Change Monthly | Plant, material, period, year, quantity, reason | `ZPPT_FCST_MN`: BUS_FCST_ADD, REASON; re-run step 11 |
| 13 | `ZFCST_RPT` | Plant, financial year | Annual, quarter, additional, total quarter, monthly, additional, total month per material, with the same forecast number as steps 6, 8, 11 |
| 14 | `SLG1`, object `ZPP_FCST`, subobject `GENERATE` | After any ZFCST_PAINTS run that looks wrong | The run's messages: no category, load factor defaulted to 1.000, old code shown under its successor, configuration missing for plant |

The same forecast number must appear on the annual, quarterly and monthly rows of a plant,
material and financial year, whichever was saved first.

## 3. What to check on the ZFCST_PAINTS list

| Column | Expected |
|------------------------|----------------------------------------------------------------------|
| Mfg. Plant Name | Name of the plant (T001W) |
| Brand | As uploaded in step 2; blank if not uploaded |
| MTS / MTO / Dis Art / Tinting | MTS, MTO, DIS or TIN as uploaded in step 1 |
| Material Group 1 / 2 / 5 | Descriptions from the sales view of sales org 4000 |
| Material Group | Material group of the material master |
| Pack Size | From the material's L / ML / KG / G unit: litres or kilograms per piece (a 4 L can shows 4.000; a 500 ML bottle shows 0.500). **Please confirm this is the pack size the business means** |
| DPL | Dealer price from the latest condition record of the material |
| Qty / Carton | Minimum order quantity of the sales view, sales org 4000. **Please confirm this is the quantity per carton** |
| Forecast quantity per month | Annual: last year's month × load factor. Quarterly: the quarter's final forecast split in last year's proportions, plus the uploaded additional per month. Monthly: the month's final forecast plus additional |
| Volume in KL | Quantity × pack size ÷ 1000 |
| Value in Crores | DPL × quantity ÷ 1,00,00,000 |
| Tonnage (Tonnage Wise ticked) | Quantity × gross weight ÷ 1000, gross weight shown beside it |
| Hidden columns | Last year's months, total, category, growth, material groups 3 and 4 are reachable through Change Layout (the layout button on the toolbar) |
| After Save | Forecast Number and Message columns appear at the end of the list |

If the four buttons Save / Select all / Deselect all / Export are missing and the status bar
says "GUI status PF_STATUS not found", the SE41 status has not been created yet; tell me, it
is a one-minute step on my side.

## 4. What to send back when something is wrong

Plant, material, financial year, mode (annual / quarter n / month n), the column, the figure
shown and the figure expected, and a screenshot of the list. For an upload: the file and the
result list.

## 5. Open questions the test should settle

1. Pack size: is the alternative unit rule right, and are the unit codes L, ML, KG, G?
2. Quantity per carton: is the sales-view minimum order quantity the right field?
3. Tonnage: gross weight ÷ 1000 in all three modes, on the final quantity — agreed?
4. Monthly list: should it also show value in crores? It does today.
5. Annual list: history months hidden by default — agreed, or show them?
6. DIS ART and TINTING: stored as DIS and TIN — agreed?
