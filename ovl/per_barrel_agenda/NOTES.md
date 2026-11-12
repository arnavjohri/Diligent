# Per Barrel Analysis - Board Agenda format (OVL)

**Project:** OVL (ONGC Videsh) · finance MIS, corporate accounts
**Status:** PBA sheet chosen (10/11/26). Query built 12/11/26; both exports so far are from the **preview** (`2CZZ9_...` is the preview's
temporary query, not the published one - see *Tile* at the end); first export
checked - `docs/PBA_sheet_to_CDS_mapping.md` section 17. **12/11/26: class and cube changed for all
periods of a year side by side (section 18) - both activated by Arnav 12/11/26. Second export
(all periods, preview query `2CZZ9_NKE76O91E4N5`) checked 12/11/26: figures equal SAP, no Q1 because none
is saved - section 19. Open: Period No. above Reporting Period on the columns, and one ZFI_PL run
per project with Q1, H1, 9M, ANNUAL.**
AgendaFormat sheet: assessed only.

## What it is
The annual "Per Barrel Analysis" workbook, sheet `AgendaFormat`: five blocks per project
for the board agenda - average realization, sales revenue (INR mn), revenue variance
(quantity / price / exchange), quantities sold, quantities produced - current year against
the previous year. The ask (Arnav, 10/11/26): rebuild it as a CDS cube shown in Custom
Analytical Queries, the way `ovl/zfi_bank_reval/` and `ovl/zfi_tr_bankacct/` were done.

## Where the answer is
- `docs/AgendaFormat_to_CDS_mapping.md` - block-by-block source mapping, the proof for the
  production block, the inputs that are not in SAP, and the seven checks to run first.
- `docs/PBA_sheet_to_CDS_mapping.md` - the same for the `PBA` sheet (10/11/26 follow-up).
  **PBA is the better candidate:** one source (ZFI_PL), all USD, none of the typed inputs.
  The workbook's hidden `Check Sheet` already ties it to ZFI_PL (95 of 118 cells equal).

## The one thing to remember
It is **not** a DPR report. Only the production block comes from the DPR tables
(`ovl/zpra_dpr/`). Sales quantity, revenue and price come from the ZFI_PL tables
(`ovl/zfi_pl/`), and exchange rate, Dated Brent, adjustments, Sakhalin-1 revenue and VAP
are typed into the workbook.

## Shipping method
**Hybrid: two objects by ADT paste, then one abapGit ZIP.** The order is fixed.

| # | Object | How | File |
|---|---|---|---|
| 1 | `ZI_PBA_AGENDA_TF` (CDS table function) | ADT paste, activate | `ZI_PBA_AGENDA_TF.ddls.asddls` |
| 2 | `ZCL_PBA_AGENDA_TF` (class, AMDP) | ADT paste, activate | `ZCL_PBA_AGENDA_TF.clas.abap` |
| 3 | `ZI_PBA_ITEM` (classic view, `ZIPBAITEM`) | ZIP | `src/zi_pba_item.ddls.asddls` |
| 4 | `ZI_PBA_CUBE` (classic view, cube, `ZIPBACUBE`) | ZIP | `src/zi_pba_cube.ddls.asddls` |

Why not one ZIP: `ZFI_AGENDA`'s value columns are DF34_DEC, which a CDS view on an older
release can read but not cast, so the table is read through an AMDP table function. abapGit
activates DDL sources before classes, and a view on a table function activates only when its
class is active - a ZIP holding all four would stop on the views and never reach the class.
The class also keeps out of the ZIP because no hand-written class XML has pulled on OCD.

Steps (development system):
1. Package: one that has **no abapGit offline repo on it** - new `ZFI_PBA`, not `ZFI_OTH`
   (the JIB offline repo sits on `ZFI_OTH`; a different ZIP imported into that repo offers
   the seven JIB views for deletion on the pull).
2. ADT, New, Data Definition `ZI_PBA_AGENDA_TF`, replace the whole template with the file,
   activate. It activates without the class.
3. ADT, New, ABAP Class `ZCL_PBA_AGENDA_TF`, replace the whole source, activate.
4. `ZABAPGIT_STANDALONE`, New Offline Repo on that package, Import ZIP `ZFI_PBA.zip`, Pull.
   The two views activate in order (item, then cube). The table function and the class show
   as local objects that are not in the ZIP - leave them.
5. ADT, Data Preview on `ZI_PBA_CUBE` (empty if `ZFI_AGENDA` is empty in development).
6. ADT, `ZI_PBA_CUBE`, Properties, API State, Add Release State, **Use in Key User Apps (C1)**.
7. Custom Analytical Queries: data source `ZI_PBA_CUBE`.
If the ZIP is refused, the two files in `src/` paste into ADT exactly as they are, item first.
Re-zip after any change: `zip -X ZFI_PBA.zip .abapgit.xml src/*` from this folder.

## The query (Custom Analytical Queries)
Rows: Report Row No., Report Row (or JV Code). Filters: Product (always - OIL and GAS are
different units), Fiscal Year, Reporting Period. Calculated measures:

| Calculated measure | Formula |
|---|---|
| Realised price | Revenue / Sales Qty Net of State Share |
| Production cost | Production Cost / Production Quantity |
| Royalty | Royalty and Taxes / Production Quantity |
| Transportation | Transportation / Sales Qty Net of State Share |
| DD&A | Depletion and Depreciation / Production Quantity |
| Survey | Survey and Dry Well / Production Quantity |
| Cost of goods sold | the five cost measures above added |
| Profit | Realised price - Cost of goods sold |

Amounts are USD mn and quantities are millions (million bbl for OIL, million MMBTU for GAS), so
each quotient is USD per bbl / per MMBTU. The total row is then a weighted average, as the
sheet's OVERALL rows are. Any other ZFI_PL line: measure ZFI_PL Line Value restricted to one
ZFI_PL Section and one ZFI_PL Line.
**Layout like the sheet (Arnav's question, 10/11/26).** The cube's own rows are ZFI_PL lines and
are not the report. In the query: Report Row No. and Report Row on the rows; Fiscal Year and
Reporting Period on the columns with the eight calculated measures; the nine base measures
hidden; Product fixed to OIL (a second query for GAS). The total row is the sheet's OVERALL row.
Oil, 9M 2025-26, worked from the production extract: seven projects, and the price column equals
the sheet's 9M FY'26 column on all seven (61.98, 63.67, 54.16, 61.06, 62.66, 53.80, 69.54).
What the query does not give: the board page's formatting, years ZFI_PL no longer holds, rows
with no ZFI_PL project, and the second OVERALL row without a second filter. For the exact board
page the recommended route is the workbook as it is, fed by one export of this query in place
of the 15 ZFI_PL extract files; an ABAP report writing into the Excel template is the
alternative and a separate build. **Decision open - after finance has seen the query.**

Checked on the 1,547 production rows (same SQL and CASE text, run in SQLite, 10/11/26): 215
input cells of the PBA sheet rebuilt, 194 within 0.015 of the workbook; the other 21 are the
differences listed in `docs/PBA_sheet_to_CDS_mapping.md` section 9.

## Query steps in Custom Analytical Queries - one query, oil and gas (Arnav, 10/11/26)
Same sequence that worked for the bank revaluation query (`ovl/zfi_bank_reval/NOTES.md`).
0. Cube released C1; `RSRTS_ODP_DIS` -> `2CZIPBACUBE` opens without errors.
1. *New*. Data source: search `ZI_PBA` - no asterisk. Name `ZZ1_PBA`, label "Per Barrel Analysis".
2. *Field Selection*: Product, Report Row No., Report Row, Fiscal Year, Reporting Period; the six
   amount measures, Production Quantity (mn), Sales Qty Net of State Share (mn). Not ZFI_PL
   Section / Line / Line Value, not Sales Quantity (mn).
3. *Display*, rows in this order: Product (display text, result row on), Report Row No., Report
   Row. Columns: Fiscal Year (display text), Reporting Period, measures.
4. *Add Calculated Measure* eight times (formulas in the table of section The query; cost of
   goods sold and profit refer to the other calculated measures), 2 decimals, each division
   inside `NDIV0( )` - many rows have a zero quantity. Hide the eight base measures and the
   grand total if the properties offer it: the total over both products adds barrels to MMBTU.
5. *Filters*: Fiscal Year and Reporting Period = user input, several values allowed. Report Row
   No. = fixed range 1 to 16: row number 99 is a project that has no row in that product's table
   on the sheet (oil-only projects in the gas block, Myanmar in the oil block). No Product filter.
6. *Preview* with 2025 / 9M, expected from the production extract of 10/11/26 - Crude Oil: seven
   projects, Imperial 54.16, block result 65.22; Natural Gas: Vietnam 5.20, BC-10 0.66, block
   result 3.00 (Myanmar and Imperial show 0.00 there). Then *Publish* (the published query is `2CZZ1_...`;
   `ZZ9_` is the preview copy). Tile and Excel export from *Query Browser*.
Not yet tried on this system: division in a calculated measure, `NDIV0( )`, a fixed range filter.

## Formula text for the eight calculated measures (given to Arnav 12/11/26)
Element names of `ZI_PBA_CUBE`; the Name column is what is typed in the New Calculated Measure
dialog and what the last two formulas refer to. `NDIV0( x )` returns x, or 0 when x divides by
zero. Create in this order.

| Label | Name | Formula |
|---|---|---|
| Realised Price | `RealisedPrice` | `NDIV0( RevenueAmount / SalesQuantityNet )` |
| Production Cost per Unit | `ProdCostPerUnit` | `NDIV0( ProductionCostAmount / ProductionQuantity )` |
| Royalty per Unit | `RoyaltyPerUnit` | `NDIV0( RoyaltyAmount / ProductionQuantity )` |
| Transportation per Unit | `TransportPerUnit` | `NDIV0( TransportAmount / SalesQuantityNet )` |
| DD&A per Unit | `DdaPerUnit` | `NDIV0( DdaAmount / ProductionQuantity )` |
| Survey per Unit | `SurveyPerUnit` | `NDIV0( SurveyAmount / ProductionQuantity )` |
| Cost of Goods Sold | `CostOfGoodsSold` | sum of `ProdCostPerUnit`, `RoyaltyPerUnit`, `TransportPerUnit`, `DdaPerUnit`, `SurveyPerUnit` |
| Profit | `Profit` | `RealisedPrice - CostOfGoodsSold` |

**Seen on Arnav's screen, 12/11/26:** the editor (Display, measure properties, Expression, Formula,
*Edit*) writes measures as their LABEL in double quotes, not as element names, e.g.
`NDIV0 ( "Revenue (USD mn)" / "Sales Qty Net of State Share (mn)" )`. `NDIV0` is accepted as a
function name. The operator has to sit between the two operands - his first attempt had both
measures inserted and the slash after them. The formulas above, in that syntax: the same six
divisions with the labels of `ZI_PBA_CUBE`; cost of goods sold = the five per-unit labels added;
profit = `"Realised Price" - "Cost of Goods Sold"`. **Exception Aggregation stays unticked** - with
it the total row would be an average of the project ratios, not the weighted figure.

**Error seen 12/11/26:** `<Name> cannot be used in CostofGoodsSold (not measure in cube nor calc.
element in query)` for the five per-unit measures, and `CostOfGoodsSold cannot be used in Profit`.
Cause: formulas 7 and 8 were entered with the element names of the table above, but the app had
named the calculated measures from their labels (label without blanks: `CostofGoodsSold`, so
also `ProductionCostperUnit` and so on); only `RealisedPrice` happened to match. Fix: rebuild
formulas 7 and 8 by picking the measures from the editor's list (quoted labels). The Name column
of the table above is therefore not what this app produces - do not type names into a formula.

**Preview empty, 12/11/26** ("The result set does not contain any relevant data", query
`2CZZ9_6Y2SQTAPWWLS`). The prompt on Arnav's screen is labelled *Financial Year* with the value
2025. *Financial Year* is the label of `FiscalYearName`, the text field that holds `2025-26`;
the key field `FiscalYear` is labelled *Fiscal Year*. So the filter most likely sits on the text
field and 2025 matches nothing. Test: enter 2025-26. Proper set-up: filter and column on *Fiscal
Year*, *Financial Year* out of the field selection. **Confirmed 12/11/26:** with Fiscal Year
the query returns data (export filed). The two labels are
too close - a point against the cube's labelling, to be changed only if he wants another
activation.

## The table behind it
All tables pasted on 10/11/26 are **production** data (confirmed by Arnav). The views are built
in development and transported; figures can only be tied out after transport.
`ZFI_AGENDA` keeps the **last ZFI_PL run per project only** - fiscal year and period are not
in its key (SE11, 10/11/26). The report shows that run and has no history. Details and the
tie-out in `docs/PBA_sheet_to_CDS_mapping.md` section 6.

## original/
`Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx` - as supplied 10/11/26. The 18 workbooks it
links to (15 ZFI_PL extracts, S-1 LLC, standalone and consolidated accounts) were not
supplied.
`ZFI_AGENDA_SE11_2026-11-10.png`, `ZFI_AGENDA_SE16_count_2026-11-10.png` - table definition
and row count (1,547) as supplied 10/11/26.
`ZFI_AGENDA_SE16_full_2026-11-10.tsv` - the whole table, 1,547 rows, as pasted 10/11/26.
`ZPRA_T_MREC_PRD_GJAHR2025_SE16_2026-11-10.tsv` - reconciled production, fiscal year 2025,
2,335 rows, as pasted 10/11/26. Both taken from the session record, tab-separated, no header.
`ZFI_PL_PRO_AN_CL1202_2025ANNUAL_run_2026-11-10.tsv`, `ZFI_PL_PRO_AN_CL1202_screen_2026-11-10.png` -
output and screen of the control run of 10/11/26 (CL1202, 2025 ANNUAL in both column sets).
That run **overwrote CL1202's rows in `ZFI_AGENDA`**; the full-table file above is the copy of
what was there before. Result in `docs/PBA_sheet_to_CDS_mapping.md` section 11: a fresh run
does not tie to the board figures for CPO-5 production cost and DD&A - open.
`ZFI_PNL_GL_SE16_2026-11-10.tsv` - the ZFI_PL G/L mapping, 1,168 accounts, four columns (G/L,
text, third column, producing-project line), no header, as pasted 10/11/26.
`ZPNL_QI_OIL_CL1202_SE16_2026-11-10.tsv` - quantity records of CL1202, 25 rows, as pasted
10/11/26. Read in `docs/PBA_sheet_to_CDS_mapping.md` section 12.
`ZFI_PL_PRO_AN_CL1202_2025_2024_ANNUAL_run2_2026-11-10.tsv` - Arnav's second run in PRD the same
day, 2025 ANNUAL against 2024 ANNUAL: it put the previous-year column back for CL1202
(`docs/PBA_sheet_to_CDS_mapping.md` section 14).
`ZI_PBA_CUBE_output_partial_2026-11-10.tsv` - part of the cube's output as Arnav pasted it after
activation (IEL, LZ, MECL, PCSA; 1,322 complete rows, list display with thousands separators).
`CAQ_export_6_2025_9M_2026-11-12.xlsx` - first export of the published query, 2025-26 9M, as supplied
12/11/26.
`CAQ_export_7_2025_all_periods_2026-11-12.xlsx` - export of query `2CZZ9_NKE76O91E4N5`, 2025-26, periods
on the columns (9M, ANNUAL, H1 - no Q1 saved), as supplied 12/11/26.

## Query change for all periods side by side (given to Arnav 12/11/26)
Query `2CZZ9_6Y2SQTAPWWLS`, after the cube with Period No. is active:
1. Field Selection: tick **Period No.** (Reporting Period stays ticked).
2. Display: Period No. and Reporting Period on the **columns**, below the measures, Period No.
   above Reporting Period. Rows unchanged (Product, Report Row No., Report Row).
3. Filters: no fixed value on Reporting Period; Fiscal Year stays the user input, single value,
   mandatory. Report Row No. 1 to 16 stays.
4. Save, preview, publish again.
Columns then read, per measure: 1 Q1, 2 Q2, 3 H1, 4 Q3, 5 9M, 6 Q4, 7 ANNUAL. A period shows only
for projects whose saved ZFI_PL run holds it (Q2 / Q3 / Q4 need the two cumulative periods).
The sheet shows the cost sections for Q1, H1, 9M, Annual only; the query also has them for Q2,
Q3, Q4 - finance can hide those columns in Excel.

## ZFI_PL run for finance (given 12/11/26)
Profitability Analysis, once per project, the four year / period pairs filled with the **same
year** and **Q1, H1, 9M, Annual** (values from the period F4: Q1 Apr - Jun, H1 Apr - Sept, 9M
Apr - Dec, Annual Apr - Mar). Display the output - that saves it. Each run replaces that
project's saved rows (the previous-year column goes). It is production: finance runs it, not us.

## Tile (12/11/26)
Launchpad Designer, catalog `ZZ1_BANKREVAL_REPORT`, group *Bank Reports* (both already in Arnav's
role). Pattern copied from the bank reval tile, which works on this system:
- Tile *App Launcher - Static*, **Use semantic object navigation unticked**, Target URL
  `#AnalyticQuery-analyze?bsa_query=<query>&sap-app-origin-hint` (bank reval: `2CZZ1_BZHO1M6TDK65`).
- Target mapping, Application Type URL, same URL, System Alias blank.

**First try failed: `Query 2CZZ9_NKE76O91E4N5 is unknown`.** The name was taken from the header of
export 7, and that export was made from the *preview*. A `2CZZ9_<random>` name is the preview's
temporary query (`ZZ9_...` SQL view, a new one per preview - export 6 had `2CZZ9_6Y2SQTAPWWLS`);
it does not exist for the launchpad. The tile needs the **published** query: `2C` + the SQL view
name of the published `ZZ1_...` view. Find it in ADT (`@AbapCatalog.sqlViewName` of the `ZZ1_`
query view) or open the query from *Query Browser* and copy the address from `#AnalyticQuery`.
Published query (ADT, 12/11/26): view **`ZZ1_PBA`** ("Per Barrel Analysis Report"), SQL view
`ZZ1_S370PML0P5P2`, so the query is **`2CZZ1_S370PML0P5P2`** and the tile / target mapping URL is
`#AnalyticQuery-analyze?bsa_query=2CZZ1_S370PML0P5P2&sap-app-origin-hint`. Source as generated:
`original/ZZ1_PBA.ddls.asddls` (generated - never edit in ADT, the next Publish overwrites it).
Read from that source, still as published 12/11/26: columns Financial Year, Reporting Period,
Period No., Fiscal Year (so the periods sort by text - Period No. has to go above Reporting
Period); rows Product, Report Row, Report Row No. (rows sort by name, not by the sheet's
number); Fiscal Year and Reporting Period are optional prompts with several values allowed.

**Cube source in the system (seen 12/11/26):** Arnav keeps the previous version commented out on
top - all 335 lines of the 10/11 source with `//` in front, two blank lines, then the active
source. The repo copy carries the same block (690 lines) so that a later paste does not drop it.
A further change goes into the active part only; do not comment the whole object out a second time.

