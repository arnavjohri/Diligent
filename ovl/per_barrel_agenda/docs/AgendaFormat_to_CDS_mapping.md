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
