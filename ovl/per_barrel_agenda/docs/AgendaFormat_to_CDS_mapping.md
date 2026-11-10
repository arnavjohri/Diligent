# Per Barrel Analysis (Annual FY'26, V3) - sheet "AgendaFormat" -> data source mapping

Workbook: `../original/Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx` (as supplied 10/11/26).
Question: can the AgendaFormat sheet be rebuilt as a CDS cube shown in Custom Analytical
Queries (CAQ), from the data the DPR stack already reads, for every block?
Assessed 10/11/26 from the workbook formulas, `ovl/zpra_dpr/` and `ovl/zfi_pl/`. No system
access; nothing was built. Table and field names below are the ones spelled out in those two
folders. Anything not confirmed there is marked as a check.

## Short answer

Not from DPR data alone. DPR covers one block of five. Three more blocks need the ZFI_PL
tables, which are in SAP but are a different source. Five inputs are typed into the workbook
and exist in no SAP table that the workbook or the two programs show.

## 1. How the workbook is built

`AgendaFormat` holds no source data. Every figure comes from the working sheets:

| Working sheet | Feeds | Where its FY'26 inputs come from |
|---|---|---|
| Production & Sales Quantity | blocks 4, 5; denominator of block 1 | Production: typed table "PRODUCTION DATA - Annual FY 2025-26" (bbl and tonnes per project, gas MMSCM), cols ES:EY. Sales: `[n]RawData!D37` / `D39` / `E37` of 15 linked files `<project>_Annual_FY26.xlsx` in a folder named `ZFI_PL DATA\Links` |
| Revenue & Costs | blocks 1, 2 | `[n]RawData!C42` / `D42` of the same 15 linked files (USD mn) |
| PBA | block 1 | Revenue & Costs / Production & Sales Quantity (pure arithmetic) |
| BoardAgenda Workng | blocks 2, 3 | the two sheets above, x typed average exchange rate (C1 = 88.335, C2 = 84.5875), + typed "Adjustments (With Comments)" per project in USD mn and INR mn; Sakhalin-1 revenue from a separate workbook `S1-LLC for Jan-Mar 26` |
| BoardAgenda Variance | block 3 | BoardAgenda Workng (pure arithmetic) |
| Reconciliation | one line of block 2 (Value added products - Imperial) | linked workbooks "OVL Standalone Annual FY'26" and "Consolidated Accounts - Annual FY'26" |

18 external workbooks are linked in total. The "RawData" sheets are ZFI_PL output: rows 37 /
39 / 42 line up with the program's screen layout ("Total Sales quantity", "Total Sales
quantity-net of state share (13-3a)", first revenue line). That is inferred from
`ovl/zfi_pl/MZFIPLF01.abap` FORM `create_quant`; the linked files themselves were not supplied.

## 2. Block by block

| # | Block (AgendaFormat cols) | Figures | In DPR tables? | Elsewhere in SAP? | Verdict |
|---|---|---|---|---|---|
| 5 | Quantities produced (AG:AM) | MMT / BCM per project, totals MMTOE, split consolidated / equity accounted | **Yes.** `ZPRA_T_MREC_PRD` x `ZPRA_T_PRD_PI` / `ZPRA_T_TAR_CF` - the same sources as rows 58-62 of the DPR Excel | - | **Possible now** |
| 4 | Quantities sold (Y:AE) | MMT / BCM per project, % of production | **No.** DPR has production volume types only (NET_PROD, GROSS_PROD, GAS_INJ); no sales or lifting | ZFI_PL: `ZPNL_QI_OIL` / `ZPNL_QI_GAS` (`TOT_SAL`, `SH_LIFT`), factors in `ZPNL_QI_CONVO`; also snapshot `ZFI_AGENDA` (per_key A1) | Possible, second source |
| 2 | Sales revenue, INR mn (I:N) | per project, crude / gas / VAP | **No** | USD revenue: `ZFI_AGENDA` (per_key A2) or the JVA ledger through ZFI_PL's logic. INR conversion, adjustments, Sakhalin-1, VAP: **not in SAP** (section 4) | Partly |
| 1 | Average realization, USD/bbl and USD/MMBTU (A:G) + Dated Brent table | revenue / sales quantity | **No** | Follows from blocks 2 and 4 (or `ZFI_AGENDA` per_key A3). Dated Brent is typed | Possible once 2 and 4 exist; Brent needs a maintained table |
| 3 | Revenue variance: quantity / price / exchange (P:U) | arithmetic on both years' quantity, price and rate | **No** | Follows from blocks 2 and 4 plus both years' exchange rates | Possible once 2 and 4 and the rate exist |

## 3. Proof for block 5

`ovl/zpra_dpr/docs/DPR_export_2026-09-17.xlsx`, row 62 "Actual Production 2024-25" (ONGC
Videsh level, MMT / BCM) against AgendaFormat column AK (Annual FY'25 production):

| | Lines compared | Identical to 3 decimals | Different |
|---|---|---|---|
| Crude oil (MMT) | 14 | 13 | BC-10 Brazil: agenda 0.367, DPR 0.366 |
| Natural gas (BCM) | 12 | 12 | - |
| Totals | oil 7.266 / 7.265, gas 3.013 / 3.013, MMTOE 10.279 / 10.278 | | |

Myanmar A-1 & A-3 is one agenda line and two DPR assets (0.657 + 0.195 = 0.852). Vietnam
06.1 is condensate in DPR and sits under crude oil in the agenda.

Not proven: the FY'26 column. The DPR export in the repo ends at 31.12.2025, so the full
year could not be compared. The agenda's FY'26 figures are typed from an "approved
production" table, not read from SAP.

## 4. Inputs that exist in no SAP table shown by the workbook or the programs

| Input | Where it sits in the workbook | Effect if left out |
|---|---|---|
| Average USD/INR rate per year | BoardAgenda Workng C1, C2 (typed) | no INR revenue, no exchange variance. ZFI_PL sums only `KSL` and has no rate logic |
| Dated Brent, annual and quarterly | AgendaFormat C33:D33, C38:F38, C43:F43 (typed) | Brent / discount sub-table of block 1 missing |
| INR and USD adjustments per project | BoardAgenda Workng F:G, U:V (typed, "with comments") | block 2 will not tie to the published accounts. FY'26: 8 project lines carry one |
| Sakhalin-1 (S-1 LLC) revenue | separate workbook, one cell | one equity-accounted line of block 2 missing: 28,269.87 of the 146,402.03 INR mn total |
| Value added products - Imperial | Consolidated Accounts workbook via Reconciliation!C49 | line (C) of block 2 missing |

Also typed, but obtainable from SAP for a closed year: the FY'25 comparison columns of
blocks 4 and 5 (49 typed cells). 12 formulas carry a manual +/-0.01 so that totals tie; a
query will differ from the board paper by up to 0.02 on those lines.

## 5. What ZFI_PL already holds (from `ovl/zfi_pl/`, code only - no DDIC here)

- `ZPNL_QI_OIL`, `ZPNL_QI_GAS`: quantitative information keyed in per company / company
  code / project / fiscal year / period (Q1, H1, 9M, ANNUAL ...), with created / approved /
  frozen stamps. Fields used in code: `SH_PROD`, `SH_LIFT`, `SH_TAKE`, `TOT_SAL`, `TRN_LOS`,
  `FL_VENT`, `OST_*`, `CST_*`, `CH_INVT`, `OVR_UND`, `PRD_ACT`, `OTHERS`.
- `ZPNL_QI_CONVO`: `BBL_MMBBL`, `BBL_MMT`, `TON_BBL`, `MMSCM_MMBTU`, `MMSCM_BCM`, `MMSCM_MMBOE`.
- `ZFI_AGENDA`: snapshot written each time a user runs the profitability analysis for ONE
  project (`MZFIPLI01`, MODIFY at the end of the PRO_ANA branch). Keys seen: `COMP`, `PROJ`,
  `FISCAL1..4`, `PERIOD1..4`, `PER_KEY` (A1 quantities, A2 profit and loss, A3 per barrel),
  `PER` (row text, e.g. 'REVENUE FROM CRUDE OIL', 'Total Sales quantity', 'Share of
  Production'). Values `CRUDE_OIL1..4`, `GAS1..4`.
- FORM `cre_age` in `MZFIPLF01` already builds an agenda list from `ZFI_AGENDA`: realised
  price, revenue, sales quantity and production per project for two periods. FORMs
  `cre_prd_qty`, `cre_rev`, `cre_bar` are the counterparts of the three working sheets.
- `ZFI_PNL_PROJ`: project list (`JVNAM`, `TXTJV`, `BUKRS`, `COMPANY`, `PROD`, `MANUAL`,
  `ASSOCT`). `ASSOCT` takes values 1-5 and drives gas allocation; it is NOT an
  equity-accounted flag.

## 6. What CAQ can and cannot do with the layout

Can: project rows grouped by product and by consolidation group, subtotals, FY vs previous
FY as restricted measures, Variation and % Variation as calculated measures, average price
as revenue / quantity evaluated after aggregation (so the "AVERAGE CRUDE OIL - Total" line is
a true weighted average), fixed row order through a sequence field in the cube.

Cannot: five blocks side by side on one page, the Brent table inside block 1, mixed units
shown as merged cells, footnotes, manual rounding plugs. The realistic shape is one query
per block (five), or three if price, revenue and variance share one.

The three variances are row-level formulas whose totals are sums of the project rows. They
must be computed per project below the cube (current year joined to previous year) and
exposed as SUM measures; a calculated measure in the query would give a different total.

## 7. Checks before anything is built (all for Arnav in SE16 / SE11, or for finance)

1. SE16 `ZPRA_T_MREC_PRD`, GJAHR 2025: all 12 MONAT present for every asset? SE16
   `ZPRA_T_TAR_CF`, GJAHR 2025: a factor per oil asset? Without both, block 5 for FY'26 is
   short or zero.
2. SE16 `ZPNL_QI_OIL` / `ZPNL_QI_GAS`: is FY 2025-26, period ANNUAL saved and frozen for every
   producing project? Which value does FISYEAR carry for FY 2025-26?
3. SE11 `ZFI_AGENDA`: data type of `CRUDE_OIL1` / `GAS1`, and the key. The program fills them
   from DECFLOAT34 fields. A column that is not DEC / CURR / QUAN cannot be a cube measure
   as it stands. SE16: is there a row set for every producing project with FISCAL1 = the
   year and PERIOD1 = ANNUAL? It only exists if someone ran that exact combination.
4. Finance: where does the average exchange rate come from? If it is an average rate type
   in TCURR, name it; otherwise it needs a small maintained table. Same question for Dated
   Brent.
5. Finance: are the adjustments, Sakhalin-1 and VAP to stay manual (maintained table), or is
   a Fiori version without them acceptable?
6. A mapping DPR asset / block <-> ZFI_PL project (JVNAM) <-> agenda row, with product
   section, consolidated / equity-accounted group and row sequence. No common key was found
   in either source.
7. Is one query per block acceptable, or must the output look like the board page? The
   second is not a CAQ deliverable.

## 8. Follow-up 10/11/26: "everything is in ZFI_PL", three tabs, exact board layout

Arnav relayed: the functional user says everything can be displayed in ZFI_PL; the workbook
is fed by the tabs PBA, Revenue & Costs and Reconciliation; if all of that is available,
the report must look exactly like AgendaFormat, because that page goes to the board.

### 8.1 The three tabs

| Tab | From ZFI_PL? | Basis |
|---|---|---|
| PBA | Yes | `PBA_sheet_to_CDS_mapping.md`; CPO-5 rebuilt from `ZFI_AGENDA` rows |
| Revenue & Costs | Yes, in USD mn, for the run the table holds | its Annual FY'26 cells are links to the ZFI_PL extracts; 23 of 24 project revenues equal the table |
| Reconciliation | **No** | every input is a link to the standalone and the consolidated accounts workbooks (INR mn). `MZFIPLF01` has no consolidated / standalone / EWIP logic at all |

### 8.2 AgendaFormat is not fed by those three tabs alone

Sheet references in the AgendaFormat formulas: BoardAgenda Variance 59, PBA 54, BoardAgenda
Workng 47, Production & Sales Quantity 45, Reconciliation 1, Revenue & Costs 0 (only
indirectly). The two BoardAgenda sheets are where the typed inputs enter (section 4).

### 8.3 What ZFI_PL's own agenda list (FORM `cre_age`) shows

Per project and for two periods: crude price, crude revenue (USD mn), crude sales quantity,
crude production, and the same four for gas. Nothing else. Counted in `MZFIPLF01`: no INR,
no exchange rate, no TCURR read, no Dated Brent, no quantity / price / exchange variance
(its "variance analysis" is period 1 minus period 2 and a percentage). Its columns headed
MMT and BCM are not conversions: crude is bbl / 1,000,000 and gas is the stored quantity
x 2.000000.

So the user's statement holds for price, USD revenue and quantities. It does not hold for
INR revenue, the three variances, Brent, MMT / BCM, Sakhalin-1 revenue or VAP.

### 8.4 Exact board layout

Custom Analytical Queries gives a pivot grid, not a designed page: no five blocks side by
side, no fixed headings, no footnote. On this landscape a formatted workbook has so far been
produced only by the classic DPR report through Excel OLE in SAP GUI; the Fiori download of
the DPR emits CSV because XCO XLSX is not available (MEMORY section 4.1).

| Option | Layout | Where it runs |
|---|---|---|
| CAQ, one query per block | same figures, grid layout | Fiori |
| Classic report writing the AgendaFormat sheet through Excel OLE | exact page | SAP GUI only |
| Custom UI5 page | exact page | Fiori; UI development, not a paste delivery |

Whatever the option, the inputs of section 4 need a home (one small maintained table) or
finance must accept the page without them, and `ZFI_AGENDA` must stop overwriting runs
(history table, `PBA_sheet_to_CDS_mapping.md` section 8.4). Decisions open; nothing built.

### 8.5 Which of the missing inputs can be calculated or read from SAP (10/11/26)

| Input | Obtainable without typing? | How | Open |
|---|---|---|---|
| Average USD/INR rate | Probably | TCURR holds USD to INR; rate types CLT, M and TTA are maintained on this system (bank reval work, `ovl/zfi_bank_reval/NOTES.md`). No annual average is known to be stored, so it is computed from the entries | which rate type and averaging rule reproduce 88.335 (FY'26) and 84.5875 (FY'25). x4 and x12 of both give two-decimal sums, so an average of quarterly or monthly rates is likely. Test in SE16 |
| INR revenue | Yes, as USD x rate | arithmetic | see VAT and booked-INR rows below |
| Quantity / price / exchange variance | Yes | the three formulas on BoardAgenda Variance A33:A35 | 12 manual +/-0.01 plugs in the sheet |
| MMT, BCM | Yes | factors in `ZPNL_QI_CONVO` (ZFI_PL) or `ZPRA_T_TAR_CF` (DPR) | which factor finance wants |
| Production | Yes | DPR tables (section 3) | - |
| VAT added back to revenue | Not from `ZFI_AGENDA` | the USD "adjustments" are VAT (cell comments: "Amount of VAT", "Net of VAT"). Block 2 is gross of VAT; the ZFI_PL revenue line is net. ZFI_PL knows a VAT G/L (0000200668) but stores no VAT line | a ledger read per project; not verified |
| Booked INR on standalone projects | No | the INR "adjustments" replace USD x average rate by the booked figure for the projects tagged ST | - |
| Dated Brent | No | market quotation; TCURR does not hold it | maintained table |
| Sakhalin-1 revenue | No | not in ZFI_PL (RU2002 is all zero) | - |
| Value added products | Maybe | ZFI_PL has a line `SALE OF VAP`; value for IEL not seen yet | full table download |

Effect of leaving the typed adjustments out, FY'26 (ZFI_PL revenue x 88.335 against the
sheet): CPO-5 -17.5 %, Imperial -10.8 %, BC-10 gas -10.8 %, Vietnam crude and gas -6 %,
SPOC -0.75 %, ACG -0.70 %, Myanmar -0.09 %, all other lines equal. All lines together
-2.07 % (226,446 against 231,228 INR mn).

### 8.6 Tab "Production & Sales Quantity" (Arnav, 10/11/26: this tab, not Reconciliation)

The three base tabs are therefore PBA, Revenue & Costs and Production & Sales Quantity.
How the Annual FY'26 column of this tab is filled:

| Figure | Filled from | In SAP |
|---|---|---|
| Oil sales, MMBBL (12 projects) | ZFI_PL extract, `Total Sales quantity` (net of state share for Carabobo, CPO-5) | `ZFI_AGENDA` A1; CL1202 equal to the bbl |
| Gas production and sales, million MMBTU (6 projects) | ZFI_PL extract, `Share of Production` / `Total Sales quantity`, gas column | `ZFI_AGENDA` A1, gas column (unit to be confirmed on a gas project) |
| Oil production, bbl and tonnes (14 lines) | typed table "PRODUCTION DATA - Annual FY 2025-26" (approved production) | DPR reconciled table `ZPRA_T_MREC_PRD` with `ZPRA_T_TAR_CF`; ZFI_PL `Share of Production` is within 0.44 % but has no Sakhalin-1 and no BC-60 |
| Gas production, MMSCM (12 lines) | same typed table | DPR reconciled table |
| Gas sales, MMSCM | formula: MMBTU sales / (MMBTU production / MMSCM production) | follows from the rows above |
| Sales quantity, MMT | formula: MMBBL sales / (bbl per tonne of the typed table) | follows from the rows above |
| Q1, H1, 9M columns; all earlier years | typed | not in SAP |

So this tab is obtainable as well, from two sources: ZFI_PL for sales and MMBTU, DPR for the
approved production.

Test on the current year (the DPR export in the repo ends 31.12.2025 = 9M FY'26, daily
table, JV rate x participating interest x 275 days, against the tab's typed 9M column):

| | Lines | Within 0.5 % | Outside |
|---|---|---|---|
| Oil production, MMBBL | 13 | 10 | Sakhalin-1 +20 %, Vietnam condensate 0.0189 against 0.0055, Imperial +0.9 % |
| Gas production, MMSCM | 6 | 3 | Sakhalin-1 14.5 against 395.1, Vietnam 32.9 against 16.7, BC-10 +0.8 % |

The **daily** table is therefore not good enough for Sakhalin-1 and Vietnam in the current
year. The exact match of section 3 was on the **reconciled monthly** table (FY 2024-25).
The annual page must read the reconciled table, and check 1 of section 7 (all twelve
periods of GJAHR 2025 loaded) decides whether FY'26 is there.

### 8.7 Reconciled production, GJAHR 2025, all periods - proof for FY 2025-26 (10/11/26)

`../original/ZPRA_T_MREC_PRD_GJAHR2025_SE16_2026-11-10.tsv` (2,335 rows, as pasted by Arnav).
This closes check 1 of section 7 and replaces "not proven" in section 3.

OVL share = JV quantity x participating interest (percentages of the DPR export). Oil:
`NET_PROD`, QTY1 in bbl and QTY2 in tonnes - the table carries tonnes itself, no conversion
factor is needed. Gas: `GROSS_PROD` minus `GAS_INJ`; MCM as is, MCF / 35.3, M3 / 1,000,000.

| Against the workbook's approved production, Annual FY'26 | Lines | Equal | Different |
|---|---|---|---|
| Oil, bbl | 14 | 13 (to the barrel) | BC-10: table 2,360,603.5, workbook 2,357,305 (+0.14 %) |
| Oil, tonnes | 14 | 12 | BC-10 +495 t; BC-60 20,650.6 against 9,051 (keying error below) |
| Gas, MMSCM | 12 | 11 (to 0.001) | BC-10 32.651 against 32.631 |

- Sakhalin-1: 52,187,533.5 bbl JV x 20 % = 10,437,506.7; workbook 10,437,507.
- Net gas is gross minus injection: Sakhalin-1 622.593 and ACG 127.539 match only that way.
- All twelve periods are present for 14 assets. `BRA_BC2` (BC-60 Jubarte) starts in period
  5; `VNM_B06` has periods 1-3 only, and its totals still equal the workbook.
- **Keying error in the table:** GJAHR 2025, MONAT 8, `BRA_BC2_JUBARTE`, `NET_PROD`: QTY2 is
  5,536,097.463 TO for 3,573,089.590 BBL (0.645 bbl per tonne; every other row is 6.2-7.7).
  With 536,097.463 the BC-60 tonnes come to 9,050.6, the workbook's 9,051. Any MMT figure for
  BC-60 is overstated until the row is corrected. Not ours to change; for the DPR data owner.

