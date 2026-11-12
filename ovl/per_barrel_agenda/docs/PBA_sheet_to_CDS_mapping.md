# Per Barrel Analysis (Annual FY'26, V3) - sheet "PBA" -> data source mapping

Follow-up to `AgendaFormat_to_CDS_mapping.md`. Question (Arnav, 10/11/26): can the PBA sheet
be delivered as the CDS cube / CAQ report instead of AgendaFormat?
Assessed 10/11/26 from the workbook formulas and `ovl/zfi_pl/`. No system access; nothing built.

## Short answer

Yes, and it is the better candidate. The PBA sheet has one source (ZFI_PL), is all in USD,
and needs none of the five typed inputs that block AgendaFormat (exchange rate, Dated Brent,
INR adjustments, Sakhalin-1 revenue, VAP). It is still **not** DPR data.

## 1. What the sheet is

Two tables: oil per barrel (17 project rows + 2 "OVERALL" rows) and gas per MMBTU (7 rows +
2 "OVERALL" rows). Eight sections side by side, each by year (2025-26 back to 2014-15) and
period (Q1, H1, 9M, Annual; the price section also Q2, Q3, Q4).

| Section | Sheet formula | Numerator = ZFI_PL line(s) | Denominator |
|---|---|---|---|
| Realised price | revenue / sales quantity | REVENUE FROM CRUDE OIL, REVENUE FROM NATURAL GAS | Total Sales quantity (net of state share for Carabobo and CPO-5) |
| Production cost | cost / production quantity | PRODUCTION EXPENSES + OTHER OPERATING EXPENSE | Share of Production |
| Royalty | cost / production quantity | ROYALTY + OTHER TAXES (AS APPLICABLE) | Share of Production |
| Transportation | cost / sales quantity | TRANSPORTATION EXPENSES | Total Sales quantity |
| DD&A | cost / production quantity | DEPLETION + DEPRECIATION AND AMORTISATION | Share of Production |
| Survey | cost / production quantity | EXPLORATION COSTS(SURVEY) + EXPLORATION COSTS(DRY WELL) | Share of Production |
| Total cost of goods sold | sum of the five cost ratios | - | - |
| Profit | price - cost of goods sold | - | - |

The line names are the ones FORM `cre_rev` (`ovl/zfi_pl/MZFIPLF01.abap`) reads from
`ZFI_AGENDA`, per_key A2, and it adds them in the same pairs as the sheet. FORM `cre_bar`
is ZFI_PL's own cross-project per-barrel list. In the workbook the same lines arrive as
`[n]RawData` rows 42-43, 50-51, 52-53, 54, 59-60, 61-62 of the linked ZFI_PL extracts.

## 2. Evidence: the workbook's hidden "Check Sheet"

Finance compares the PBA figures for Annual FY'26 with "As per ZFI_PL" (the per-barrel
section of the same extracts). Values as saved in the workbook:

| Check | Result |
|---|---|
| Per-barrel cells with a value on both sides | 118 |
| Equal to 2 decimals | 95 |
| Differ by 0.08 or less | 17 |
| Differ by more | 6 |
| Production bbl, 12 oil projects with a figure on both sides | largest gap BC-10 Brazil, 0.44 % |

The six larger differences, all explained by the workbook itself:
- Carabobo, 4 cells: price, production cost, royalty and DD&A are each about 2.8 % higher
  in the sheet than in ZFI_PL. Same ratio on all four, so a different quantity basis.
- ACG DD&A: the sheet carries a typed 35.14 USD mn (10.02 per bbl); ZFI_PL shows 23.97.
- CPO-5 survey cost: 0.13 in the sheet, 2.36 in ZFI_PL. The sheet formula reads rows 60+61
  of the extract where every other project reads 61+62.

Also: Myanmar A-1 & A-3 is one sheet row and two ZFI_PL projects, so the check sheet has no
ZFI_PL value for it. Sakhalin-1 has no ZFI_PL figure, and its price and costs are zero in
the sheet for FY'26 as well, so nothing is lost there.

## 3. What SAP cannot supply for this sheet

- **History.** Only the Annual FY'26 column is linked to ZFI_PL extracts. FY'25 and earlier,
  and the FY'26 Q1 / H1 / 9M columns, are typed values. `ZFI_AGENDA` keeps only the last
  run per project (section 6), so SAP holds no history either: at most the four year /
  period columns of that last run.
- **The typed ACG DD&A figure.**
- **The page layout**: eight sections times twelve years on one sheet.

## 4. Shape of the cube (not built, names not decided)

Base measures only, per project / product (oil, gas) / fiscal year / period: revenue,
production cost, royalty, transportation, DD&A, survey (USD mn), sales quantity, production
quantity. The eight per-barrel figures are **calculated measures in the query**, evaluated
after aggregation. That makes the "OVERALL" rows true weighted averages, which is exactly
how the sheet computes them (total cost / total quantity). A stored per-barrel value cannot
be totalled, so per_key A3 is the wrong input for the cube.

Dimensions needed beyond the keys: a display project (Myanmar A-1 + A-3 as one row), a
group (Vankor apart, for the "excl. Vankor" subtotal) and a row sequence.

Division in a CAQ calculated measure has not been used on this system yet (the bank reval
query multiplies). Check it on the first query.

Source options for the base measures:

| | Source | For | Against |
|---|---|---|---|
| A | `ZFI_AGENDA`, per_key A1 (quantities) and A2 (amounts) | small build; figures equal what finance saw in ZFI_PL | holds the last run per project only (section 6); a re-run for another period replaces the figures |
| B | `ZPNL_QI_OIL` / `ZPNL_QI_GAS` for quantities, JVA ledger through the `ZFI_PNL_GL` mapping for amounts | live, approved / frozen quantities | re-implements FORM `cre_prd_proj` (about 3,900 lines) in CDS; `ZFI_PNL_GL` structure not known here |

Recommended: A, once the checks pass.

## 5. Checks before anything is built

1. SE11 `ZFI_AGENDA`: key fields, data types of `CRUDE_OIL1..4` and `GAS1..4`, length of
   `PER`. A value column that is not DEC / CURR / QUAN cannot be a cube measure as it stands.
2. SE16 `ZFI_AGENDA` in the system where finance runs ZFI_PL: FISCAL1 = the year, PERIOD1 =
   ANNUAL, PER_KEY = A1 and A2. Is there a row set for each of the 15 projects? More than
   one set per project (same FISCAL1 / PERIOD1, different FISCAL2..4)?
3. Which value FISCAL1 carries for FY 2025-26.
4. Unit of the gas quantity in the A1 rows. FORM `cre_age` multiplies it by 2.000000 with
   no comment; the reason is not visible in the code.
5. Dev / quality system: the table is filled only when a user runs the analysis, so it is
   probably empty there. Agree how the cube is to be tested.
6. Finance: is current year against previous year (plus whatever years the table holds)
   acceptable in place of twelve years, and one query each for oil and gas?

## 6. `ZFI_AGENDA` as found - SE11 and SE16, 10/11/26

Screenshots: `../original/ZFI_AGENDA_SE11_2026-11-10.png`, `..._SE16_count_2026-11-10.png`.
Sample rows were pasted in chat (client 500, partial list). This section answers checks 1
to 3 of section 5 and replaces what sections 3 and 4 assumed about years accumulating.

- **Key: MANDT, COMP, PROJ, PER, PER_KEY. Fiscal year and period are not in the key.** Every
  run of a project overwrites the rows of its previous run. The table holds the last run
  per project and nothing else.
- Value columns `CRUDE_OIL1..4`, `GAS1..4`: DF34_DEC, length 16, decimals 5 (data elements
  `ZCRUDE_OIL`, `ZGAS`). `FISCAL1..4` GJAHR, `PERIOD1..4` CHAR 6 (`ZPERIOD_P`), `PER` CHAR
  100, `PROJ` CHAR 6 (`JV_NAME`).
- 1,547 rows in total, about 100 lines per project.
- `FISCALn` carries the start year: 2025 = FY 2025-26.
- Projects sit on different runs. CL1202 is on 2025 ANNUAL against 2024 ANNUAL; RU2002 is
  on 2024 Q1 in both column sets. A project appears under a year / period only if that
  combination was in its last run.
- Left-over rows exist: CL1202 'PROFIT OIL PAID IN CASH' (A2) still carries 2024 Q1 / 2023
  ANNUAL. The line is now written as 'LESS:PROFIT OIL PAID IN CASH', so the old row is
  never overwritten. Harmless while the lines picked are current ones.
- Stored texts are 'EXPLORATION COSTS (SURVEY)' and 'EXPLORATION COSTS (DRY WELL)', with a
  space before the bracket. FORMs `cre_rev` / `cre_bar` of ZFI_PL read them without the
  space (18 places in `MZFIPLF01`), so those two lists never pick up exploration cost.
  ZFI_PL is not touched; the CDS uses the stored spelling.
- 'ROYALTY', 'Share of Production' and the A2 rows of the cost lines were not visible in
  the first paste. Confirmed from the full CL1202 list the same day - section 8.

Tie-out, joint venture CL1202 (CPO-5 Colombia):

| Line (section) | Table, 2025 | Workbook, FY'26 | Table, 2024 | Workbook, FY'25 |
|---|---|---|---|---|
| REVENUE FROM CRUDE OIL (A2), USD mn | 223.62 | 223.62 | 278.60 | 278.60 |
| Total Sales quantity (A1), bbl | 3,494,377.14 | 3,494,377.14 | 3,819,130.03 | 3,819,130.03 |
| REVENUE FROM CRUDE OIL (A3), USD / bbl | 63.99 | 63.9942 | 72.95 | 72.9486 |
| PRODUCTION EXPENSES + OTHER OPERATING EXPENSE (A3) | 6.50 + 2.24 | 8.74 on the check sheet | | |
| DEPLETION + DEPRECIATION AND AMORTISATION (A3) | 1.21 + 0.05 | 1.26 on the check sheet | | |
| EXPLORATION COSTS (DRY WELL) + (SURVEY) (A3) | 2.27 + 0.09 | 2.36 on the check sheet | | |

**Consequence.** A report on this table shows the last ZFI_PL run per project, usually the
current period against the comparison period. It cannot show a run that has since been
replaced. If periods are to be kept, a history table keyed by year and period is needed,
written at the point where ZFI_PL writes `ZFI_AGENDA` (one insert in `MZFIPLI01`). That is
a change to ZFI_PL and a decision for Arnav and finance; it is not built.

## 7. Objects

Built 10/11/26 - see section 15. The first plan (a view `ZI_PBA_LINE` casting DF34_DEC to DEC,
then a measures view, then a cube) is withdrawn.

| # | Object | What |
|---|---|---|
| 1 | `ZI_PBA_AGENDA_TF` (table function) + `ZCL_PBA_AGENDA_TF` (AMDP) | reads `ZFI_AGENDA`; DEC values, one row per year / period / product |
| 2 | `ZI_PBA_ITEM` (classic view) | the rows under business names |
| 3 | `ZI_PBA_CUBE` (classic view, cube) | dimensions, SUM measures, key-user release |

## 8. Full CL1202 list and one row per project - SE16, 10/11/26 (pasted in chat)

### 8.1 Lines confirmed, with their exact stored text

| Base measure of object 2 | Section | Stored `PER` text(s) | Column |
|---|---|---|---|
| Revenue, USD mn | A2 | `REVENUE FROM CRUDE OIL` | CRUDE_OIL |
| Revenue, USD mn | A2 | `REVENUE FROM NATURAL GAS` | GAS |
| Production cost, USD mn | A2 | `PRODUCTION EXPENSES` + `OTHER OPERATING EXPENSE` | both |
| Royalty, USD mn | A2 | `ROYALTY` + `OTHER TAXES (AS APPLICABLE)` | both |
| Transportation, USD mn | A2 | `TRANSPORTATION EXPENSES` | both |
| DD&A, USD mn | A2 | `DEPLETION` + `DEPRECIATION AND AMORTISATION` | both |
| Survey, USD mn | A2 | `EXPLORATION COSTS (SURVEY)` + `EXPLORATION COSTS (DRY WELL)` | both |
| Production quantity | A1 | `Share of Production` | both |
| Sales quantity | A1 | `Total Sales quantity` | both |
| Sales quantity net of state share | A1 | `Total Sales quantity-net of state share (13-3a)` | both |

Oil quantities are in bbl (5,417,237.30 for CL1202). The gas quantity unit is still not
confirmed: CL1202 has no gas. A full list of one gas project settles it.

### 8.2 The eight PBA figures for CPO-5, rebuilt from the table rows (2025 ANNUAL)

| Section | From `ZFI_AGENDA` (A2 / A1) | Excel PBA row 21 | Difference |
|---|---|---|---|
| Realised price | 63.9942 | 63.9942 | 0 |
| Production cost | 8.7425 | 8.7424 | 0.0001 |
| Royalty | 0.6904 | 0.6922 | -0.0018 |
| Transportation | 0 | 0 | 0 |
| DD&A | 1.2534 | 1.2534 | 0 |
| Survey | 2.3554 | 0.1348 | +2.2207 |
| Total cost of goods sold | 13.0417 | 10.8228 | +2.2189 |
| Profit | 50.9525 | 53.1715 | -2.2189 |

- The stored A3 values equal A2 / A1 line for line (ten lines checked), so the base-measure
  design reproduces what ZFI_PL shows.
- Royalty: the Excel reads the total column of the extract, which includes 0.01 USD mn of
  gas royalty, and divides by a typed production of 5,417,280 bbl.
- **Survey: the Excel cell is wrong for CPO-5.** Its formula reads rows 60+61 of the extract;
  every other project reads 61+62. It therefore adds depreciation and amortisation (0.26)
  to survey (0.47) = 0.73 USD mn, and leaves out dry well (12.29). Survey + dry well is
  12.76 USD mn = 2.36 per bbl. The 0.26 is also in the Excel's DD&A cell (6.53 + 0.26 =
  6.79), so it is counted twice. Cost of goods sold and profit for CPO-5, and the two
  OVERALL rows, carry the same slip. For finance to confirm.
- The sheet's "Total cost of goods sold" is the sum of the five cost ratios. For CPO-5 that
  is 13.04, the figure ZFI_PL stores as `(IV) OPERATING COST` (A3). It is not ZFI_PL's
  `(VII) COST OF GOODS SOLD` (20.19), which also takes inventory change and overlift and
  divides by sales quantity. The query follows the sheet.

### 8.3 Which run each project is on (PER = REVENUE FROM CRUDE OIL, PER_KEY = A2)

| COMP | PROJ | Column set 1 | Column set 2 | Sheet row (matched on revenue) |
|---|---|---|---|---|
| OVL | AA2002 | 2025 ANNUAL | 2024 ANNUAL | ACG, Azerbaijan |
| OVL | CL1202 | 2025 ANNUAL | 2024 ANNUAL | CPO-5, Colombia |
| OVL | SD2002 | 2025 ANNUAL | 2024 ANNUAL | Block 5A (SPOC), South Sudan |
| OVV | VANKOR | 2025 ANNUAL | 2024 ANNUAL | Vankorneft, Russia |
| SCB | PIVSA | 2025 ANNUAL | 2024 ANNUAL | PIVSA San Cristobal, Venezuela |
| OVL | MM2002 | 2025 ANNUAL | 2024 ANNUAL | Myanmar (gas only; A-1 or A-3 not told apart) |
| OVL | MM2012 | 2025 ANNUAL | 2024 ANNUAL | Myanmar (gas only; A-1 or A-3 not told apart) |
| N/A | IEL | 2025 9M | 2024 9M | Imperial Energy, Russia |
| N/A | LZ | 2025 9M | 2024 9M | Lower Zakum, UAE |
| N/A | MECL | 2025 9M | 2024 9M | MECL, Colombia |
| N/A | PCSA | 2025 9M | 2024 9M | Carabobo, Venezuela |
| OCL | BC10 | 2025 9M | 2024 9M | Block BC-10, Brazil |
| OVL | VN2012 | 2025 9M | 2024 9M | Block 06.1, Vietnam |
| OBV | GPOC | 2025 9M | 2024 ANNUAL | GPOC, South Sudan |
| OVL | RU2002 | 2024 Q1 | 2024 Q1 | Sakhalin-1, Russia (by code; all zero) |

- 23 of the 24 non-zero revenue figures equal the workbook to the cent, annual against its
  annual column and 9M against its 9M column. The one that differs is Vietnam 9M FY'25
  (table 1.82, workbook 2.00, a typed value).
- **In this client 7 projects are on the annual run, 7 on the 9M run and 1 on an old Q1
  run.** An annual query here shows 7 of 15 projects. `COMP` is not always OVL, and four
  projects carry `N/A`.
- Project names are in `ZFI_PNL_PROJ-TXTJV`; the last column above is only the cross-check.

### 8.4 Recommendation on history (decision open)

To get what the Excel shows - several periods side by side, all projects - the figures must
stop being overwritten. A history table keyed by company / project / section / line / fiscal
year / period, written next to the `MODIFY zfi_agenda` in `MZFIPLI01`, does that. One ZFI_PL
run per project with Q1, H1, 9M and ANNUAL of a year as its four columns then fills that
whole year. `ZI_PBA_LINE` would read the history table and keep its eight output fields, so
objects 2 and 3 do not change. Needs a fresh download of `MZFIPLI01` first. Not built.

## 9. Full `ZFI_AGENDA` table, 1,547 rows - the whole PBA sheet rebuilt (10/11/26)

`../original/ZFI_AGENDA_SE16_full_2026-11-10.tsv` (as pasted by Arnav, client 500).

**Object 1 logic run on the real rows** (same rules as `ZI_PBA_LINE`): 1,547 table rows give
2,999 view rows, **no duplicate key**; 99 repeated year / period entries dropped (all RU2002);
column set 3 is used on 4 rows, set 4 on none.

**Gas quantity unit: million MMBTU.** Myanmar sales 14.174 + 5.244 = 19.418 and Vankor 35.827
equal the workbook. MM2002 is Block A-1 (gas revenue 103.32), MM2012 is A-3 (38.10).

**Value added products are in the table:** IEL, `SALE OF VAP`, section A2, gas column: 6.00
(9M FY'26) and 4.89 (9M FY'25), USD mn.

**Runs:** 7 projects on 2025 ANNUAL / 2024 ANNUAL, 6 on 2025 9M / 2024 9M, GPOC on 2025 9M /
2024 ANNUAL, RU2002 on 2024 Q1. Every project also carries 2 to 8 left-over rows of old
line names (`CHANGE IN INVENTORIES`, `OVERLIFT/(UNDERLIFT)`) on older periods.

**Comparison.** Base measures per section 8.1, ratios as in section 1, each project in the
periods its last run holds, against the same project / year / period cell of the PBA sheet:

| Section | Cells | Within 0.015 |
|---|---|---|
| Realised price | 34 | 32 |
| Production cost | 34 | 29 |
| Royalty | 34 | 31 |
| Transportation | 33 | 33 |
| DD&A | 34 | 26 |
| Survey | 34 | 31 |
| **Six input sections** | **203** | **182** |

The 21 outside: 9 differ by 0.04 or less (production quantity: ZFI_PL figure against the
typed approved production). The other 12:

| Cells | Cause |
|---|---|
| ACG: production cost FY'25, DD&A FY'25 and FY'26, survey FY'25 | finance's own figures in the sheet (FY'26 DD&A typed 35.14 USD mn) |
| CPO-5: survey FY'25 and FY'26 | sheet shows 0 and 0.13; the table has survey + dry well of 12.63 and 12.76 USD mn. FY'25 is zero in the sheet, so exploration cost looks left out for CPO-5 on purpose; the FY'26 formula (rows 60+61) is a slip on top of that. **This corrects section 8.2, which called the sheet simply wrong.** For finance to say which is intended |
| PIVSA royalty FY'25; Vietnam price 9M FY'25, oil and gas; MECL DD&A 9M both years; Vankor DD&A FY'26, oil and gas | the figure in this client's table differs from the one finance used (typed prior-period values, or a later re-run) |

**Formula error in the sheet, prior-year profit.** `PBA!MH` is `=+J-KL`: Annual FY'25 profit
takes the **Q1** price (column J) where the annual price is column P. `PBA!MG` is `=+M-KK`:
9M takes the Q3 price (M) instead of 9M (N). The current-year columns are right (`MD = I - KH`).
All prior-year profit cells of the sheet are affected (SPOC FY'25: sheet 23.12, price 75.49
minus cost 55.55 = 19.94). For finance.

## 10. Where SAP has no record - does the Excel hold a figure there? (10/11/26)

Yes, almost everywhere. Count over the project rows of the PBA sheet, all eight sections:
cells with a non-zero figure in the Excel, and how many of those have the same project /
year / period in this client's `ZFI_AGENDA` (client 500, table as filed in `../original/`).

| Year | Period | Excel has a figure | SAP has the record |
|---|---|---|---|
| FY 2025-26 | Annual | 104 | 44 |
| FY 2025-26 | 9M | 104 | 60 |
| FY 2025-26 | H1 | 104 | 0 |
| FY 2025-26 | Q1 | 103 | 0 |
| FY 2025-26 | Q2, Q3, Q4 | 42 | 0 |
| FY 2024-25 | Annual | 103 | 49 |
| FY 2024-25 | 9M | 101 | 52 |
| FY 2024-25 | H1, Q1, Q2-Q4 | 246 | 0 |
| FY 2023-24 and earlier (ten years) | all | 4,417 | 0 |
| **Total** | | **5,324** | **205** |

- Annual FY'26, rows with Excel figures and no SAP annual record (60 cells): Vietnam oil
  and gas, BC-10 oil and gas, Imperial oil and gas, MECL, GPOC, Carabobo, Lower Zakum - the
  seven projects whose last run in this client is 9M. Finance did run them for the year (the
  workbook's annual column is linked to those extracts); the table has since been, or in
  this client never was, on that run.
- Sakhalin-1: no figure in the Excel from FY 2023-24 onwards, so nothing is missing there.
  Its figures up to FY 2022-23 are typed.
- Rows with no ZFI_PL project (GNPOC Sudan, Imperial Domestic / International, AFPC, Block
  24): no Excel figure after FY 2022-23.

What closes which gap:
- Annual against previous annual, all projects (207 cells): one ZFI_PL annual run per
  project in the system the report reads. No development.
- Q1, H1, 9M next to Annual for both years (about 700 more cells): the history table of
  section 8.4 plus one run per project and year with the four periods as columns.
- FY 2023-24 and earlier (4,417 cells): typed history; not in SAP. Upload once into a
  table, or leave blank.


## 11. Control run of ZFI_PL for CL1202 - what a fresh run fetches (10/11/26)

Arnav ran Profitability Analysis (`PRO_AN`) for CL1202 (CPO-5), company code OVL, with
**2025 ANNUAL in both column sets** (screen heading `ANNUAL FY 25 - 26` twice). Output as
pasted: `../original/ZFI_PL_PRO_AN_CL1202_2025ANNUAL_run_2026-11-10.tsv`; screen:
`../original/ZFI_PL_PRO_AN_CL1202_screen_2026-11-10.png`. Compared with CL1202's rows in
`../original/ZFI_AGENDA_SE16_full_2026-11-10.tsv` (the table before the run).

**96 lines in the output: 64 equal the saved rows, 32 differ.** The 32 come from six inputs;
every other changed line is a total or a per-barrel figure built on them.

| Input line | Saved rows | Fresh run | Difference |
|---|---:|---:|---:|
| PRODUCTION EXPENSES (USD mn) | 35.23 | 23.82 | -11.41 |
| DEPLETION (USD mn) | 6.53 | 7.88 | +1.35 |
| PROVISIONS, WRITE OFF AND OTHER IMPAIRMENT (USD mn) | 0.00 | -0.11 | -0.11 |
| (XI) INCOME TAX (USD mn) | 45.25 | 62.53 | +17.28 |
| Closing stock, storage tanks (bbl) | 7,988.60 | 5,974.72 | -2,013.88 |
| Adj. for Changes in Inventories / Other adj. (bbl) | 2,013.87 | blank | -2,013.87 |

Reproduced to the cent: crude revenue 223.62, Share of Production 5,417,237.30, Total Sales
quantity 3,494,377.14, price 63.99, royalty 0.38, other taxes 3.36, other operating expense
12.13, transport nil, depreciation and amortisation 0.26, survey 0.47, dry well 12.29,
opening stock 10,621.26.

**The board workbook agrees with the saved rows, not with the fresh run.**
`Revenue & Costs!BY24` (CPO-5, Annual FY'26, production cost) = 47.36 = 35.23 + 12.13; the
fresh run gives 35.95. DD&A in the workbook 6.79 = 6.53 + 0.26; fresh run 8.14. Per barrel
of production: production cost 8.74 against 6.64, DD&A 1.25 against 1.50.

What the source shows about the two kinds of difference:

- **Stock quantities** are not calculated. `cal_quant` prints `ZPNL_QI_OIL-CST_TNK` and
  `-CH_INVT` of the record COMPANY / BUKRS / PRO_NAM / FISYEAR / ZPERIOD = ANNUAL as stored
  (`MZFIPLF01`, FORM `fetch_quant` / `cal_quant`). So that record was saved again after the
  run that produced the saved rows: closing stock now 5,974.72 = 7,988.60 - 2,013.88 and no
  adjustment. Net quantity available for sale (+4,027.75), overlift quantity (-4,027.75)
  and the overlift amount (-0.09 to -0.10) follow from it.
- **The four amounts** are sums of `KSL` from the JV ledger for the G/L accounts mapped to
  those lines in `ZFI_PNL_GL`. The four differences add up to +7.11, so this is not accounts
  moved from one line to another inside the statement: the ledger amounts read are different.
  Not proven which of these it is:
  1. ASSUMPTION: the 26/10/26 change is active where the run was made, so the run read ACDOCA
     through `JV_JVSO1_ACDOCA`, while the saved rows were produced from `JVSO1`. Then the
     differences are the ACDOCA against JVSO1 gap on those accounts - the subject of
     `ovl/zfi_acdoca_jvso1_recon/` and `ovl/z_jva_alignment/`.
  2. Postings to those accounts after the saved run.
  3. Accounts added to or removed from those four lines in `ZFI_PNL_GL` since the saved run.

Effect of the run on the table: `MODIFY zfi_agenda` runs for every output line as soon as the
analysis is displayed (`MZFIPLI01`, after `cre_per_barl`). CL1202 now carries 2025 ANNUAL in
column sets 1 and 2; **its 2024 ANNUAL comparison column and the saved 2025 figures are no
longer in the table of that client.** The file in `../original/` is the copy of them.
`ZI_PBA_LINE` needs no change: a second set that repeats the first is dropped. Six older rows
with texts the program no longer writes (`CHANGE IN INVENTORIES`, `OVERLIFT/(UNDERLIFT)`,
`PROFIT OIL PAID IN CASH`, sections A2 and A3, all zero) stay as they were.

Consequence for the report: ZFI_PL does fetch every line the PBA sheet needs, but a fresh run
in this system does not tie to the board figure for CPO-5 production cost and DD&A. Until
the four amounts are explained, no further project should be run through `PRO_AN` there -
each run replaces rows that match the board paper with today's ledger figures.

Checks (Arnav, in the system the run was made in):
1. SE38, `MZFIPLF01`, FORM `cre_prd_proj`: does the active source read `jv_jvso1_acdoca`
   or `jvso1`?
2. SE16 `ZFI_PNL_GL`: the G/L accounts whose `PRD_PRO` is one of the four lines. Then
   `ZFI_ACDOCA_JVSO1_RECON` for company code OVL, fiscal year 2025, periods 1 to 12,
   filtered on venture CL1202 and those accounts: group-currency differences of about
   11.41 mn, 1.35 mn, 0.11 mn and 17.28 mn prove cause 1.
3. SE16 `ZPNL_QI_OIL`, PRO_NAM = CL1202, FISYEAR = 2025: `CST_TNK`, `CH_INVT` and the
   change stamp of the ANNUAL record.

## 12. Follow-up to the control run - mapping table and quantity records (10/11/26)

Arnav's answers to the three checks of section 11, as pasted:
`../original/ZFI_PNL_GL_SE16_2026-11-10.tsv` (1,168 accounts: G/L, text, third column, fourth
column - no header was pasted; the fourth column holds the producing-project line texts, so
it is read as `PRD_PRO`) and `../original/ZPNL_QI_OIL_CL1202_SE16_2026-11-10.tsv` (25 rows).

### 12.1 Check 1 - the active source reads `jv_jvso1_acdoca`
So the control run read ACDOCA through the view. Whether the saved rows were produced from
`JVSO1` or from the view is still not known.

### 12.2 Check 3 - the stock difference is explained
`ZPNL_QI_OIL`, CL1202, 2025, ANNUAL (stamp fields per `save_quant`: created, changed,
approved):

| | Value |
|---|---|
| Opening stock | 10,621.26 |
| Share of production | 5,417,237.30 |
| Closing stock (`CST_TNK`) | 5,974.72 |
| Adjustment (`CH_INVT`) | 0 |
| Overlift (`OVR_UND`) | -6,977.35 |
| Total sales (`TOT_SAL`) | 3,494,377.14 |
| Created | 96021, 28.04.2026 |
| Changed | 96021, 25.07.2026 - approval cleared, not approved again |

On the same 25.07.2026 the same user created the 2026 Q1 record with opening stock 5,974.72.
The program takes opening stock from the closing stock of the previous ANNUAL record, so the
2025 ANNUAL record was changed that day: closing stock 7,988.60 less the 2,013.87 adjustment
became closing stock 5,974.72 with no adjustment. The saved analysis rows carry the earlier
values, so **the saved CL1202 run was made between 28.04.2026 and 25.07.2026**. Production
and sales quantity did not change, so no figure of the PBA sheet is affected. The 2024 ANNUAL
record (closing 10,621.26, overlift 5,711.59, sales 3,819,130.03) equals the saved rows.

### 12.3 Check 2 - the accounts behind the four amounts
A mapping row reaches a statement line only when its fourth-column text equals the line text
(`READ TABLE it_final_bar ... WITH KEY per = wa_gls1-prd_pro`, FORM `cre_prd_proj`).

| Line | Difference (USD mn) | Accounts |
|---|---:|---|
| PRODUCTION EXPENSES | -11.41 | 200382, 209985, 250141 |
| DEPLETION | +1.35 | 209103, 209114 |
| (XI) INCOME TAX | +17.28 | 209701, 209702, 209711, 209722, 209723, 209724, 209726 |
| PROVISIONS, WRITE OFF AND OTHER IMPAIRMENT | -0.11 | 29 accounts, 2015xx and 209123, 209125 |

Open, and the one check that decides it: the same selection the program uses - ledger 4A,
company code OVL, year 2025, periods 01 to 16, venture CL1202, the twelve accounts of the
first three lines - summed on `KSL` per account and period, once on `JVSO1` and once on
`CJVSO1_ACD` (the SQL view of `JV_JVSO1_ACDOCA`).
- `JVSO1` gives the saved figures (35.23, 6.53, 45.25): the difference is ACDOCA against
  JVSO1; the period shows whether it is lines missing from the view or postings made after
  JVSO1 stopped being written.
- `JVSO1` gives the fresh figures (23.82, 7.88, 62.53): the saved rows were simply older than
  the final ledger, and the board workbook was built on them.

### 12.4 Mapping texts that match no line (for finance, not ours to change)
Fourteen accounts carry a fourth-column text that is not a line of the producing-project
statement as printed, so their amounts do not reach it:

| Mapping text | Printed line | Accounts |
|---|---|---|
| INCOME TAX (XII) | (XI) INCOME TAX | 200688, 200963, 201557, 250112 |
| EXPLORATION COSTS (SURVEY & DRY WELL) | two separate lines | 200875, 209113, 250142 |
| CHANGE IN INVENTORIES | (V)CHANGE IN INVENTORIES | 239101, 239116, 239120 |
| PROFIT OIL PAID IN CASH | LESS:PROFIT OIL PAID IN CASH | 200607, 200608 |
| OVERLIFT/(UNDERLIFT) | (VI)OVERLIFT/(UNDERLIFT) | 201943 |
| DEPRECIATION, DEPLETION & AMORTIZATION | DEPLETION / DEPRECIATION AND AMORTISATION | 201530 |

The three zero rows of older text left in `ZFI_AGENDA` (section 11) are the same renaming.
ASSUMPTION: the printed line texts are the only ones the program matches on; the line list
itself comes from `ZFI_PNL_GLF4`, which was not supplied.

### 12.5 Which system
The quantity table holds records saved by business users up to 23.10.2026 (2026 H1, user
82407). That is live data or a very recent copy of it. If the control run was made in the
live system, CL1202's rows in the live `ZFI_AGENDA` are the ones that were overwritten, and
the list reports that read that table (`REV`, `BAR_REP`, `AGE_REP`) now show the fresh
figures and 2025 in both columns for CPO-5. To be confirmed by Arnav.

## 13. Decisions of 10/11/26 after the control run

- **The system is production (PRD).** Arnav confirmed. Every table pasted on 10/11/26
  (`ZFI_AGENDA`, `ZPRA_T_MREC_PRD`, `ZFI_PNL_GL`, `ZPNL_QI_OIL`) is live data, and the control
  run of section 11 replaced CL1202's rows in the live `ZFI_AGENDA`.
- **The data gap is left as it is.** Arnav: the data is coming correctly; the four ledger
  amounts of section 12.3 are not to be chased. The `JVSO1` against `CJVSO1_ACD` check is
  dropped. The report shows what ZFI_PL last saved, whatever the ledger gave on that day.
- Known consequence, accepted: for CPO-5 the report will show production cost 35.95 and DD&A
  8.14 (USD mn) where the board workbook V3 has 47.36 and 6.79, and no previous-year column,
  until finance runs Profitability Analysis for CL1202 again with 2025 ANNUAL and 2024 ANNUAL.
  That run is finance's to make; nothing in production is touched from here.
- The views are created and activated in the development system and reach PRD by transport.
  `ZFI_AGENDA` in development may hold little or nothing, so a data preview there proves the
  view, not the figures; the tie-out against the workbook is done after transport.

## 14. Second run for CL1202 - 2025 ANNUAL against 2024 ANNUAL (10/11/26)

Arnav ran Profitability Analysis for CL1202 again in PRD, this time with 2024 ANNUAL as the
second column set. Output as pasted:
`../original/ZFI_PL_PRO_AN_CL1202_2025_2024_ANNUAL_run2_2026-11-10.tsv`.

- **2025 ANNUAL column:** identical to the first run on all 96 lines.
- **2024 ANNUAL column:** 86 of 96 lines equal the rows saved before the control run. The 10
  that differ come from one input, OTHER EXPENSES (INCL. EXCHANGE FLUCTUATION): 6.86 saved,
  6.01 now (-0.85), carried into (IX), (X), (XII) and their per-barrel lines. It sits below
  the operating margin and is not an input of the PBA sheet.
- So `ZFI_AGENDA` for CL1202 again carries both years, and every PBA-sheet figure for CPO-5
  in FY 2024-25 is what it was: price 72.95, production expenses 26.97, other operating
  expense 4.08, depletion 12.19, depreciation 0.12, survey 4.01, royalty 0.23.

What it says about the gap of section 12.3 (left as it is, section 13): for fiscal year 2024
the read through `JV_JVSO1_ACDOCA` gives back production expenses, depletion and income tax
to the cent. The view is therefore reading those accounts correctly, and the fiscal year
2025 differences point to entries posted after the run finance saved between 28.04.2026 and
25.07.2026 rather than to lines the view cannot see. Not proven; not pursued.

## 15. Objects as built (10/11/26)

Arnav asked for all views in one go, in a ZIP, with no correction rounds. Rethinking the first
view showed its weak point: `CRUDE_OILn` / `GASn` are DF34_DEC, and the ABAP documentation and
SAP community sources say a DDIC-based CDS view can only read that type - no cast, no
arithmetic - until release 2022 or so (7.51 news: "none in ABAP CDS besides simple reads"; the
7.54 cast table has no DF34_DEC source row; the reported workaround is an AMDP table function).
The cast in `ZI_PBA_LINE` would most likely have failed activation. Design changed:

- **`ZI_PBA_AGENDA_TF` + `ZCL_PBA_AGENDA_TF=>GET_LINES`**: SQLScript, eight SELECTs joined by
  UNION ALL (four column sets x oil / gas). `TO_DECIMAL( value, 16, 5 )` as `LINE_VALUE`;
  `QUANTITY_MN` = oil value x 0.000001, gas value as stored. A later column set repeating an
  earlier year / period is left out. Client through the parameter `p_clnt`
  (`@Environment.systemField: #CLIENT`).
- **`ZI_PBA_ITEM`**: projection of the table function, `p_clnt : $session.client`.
- **`ZI_PBA_CUBE`**: line grain, no SQL aggregation (as the bank reval, treasury and JIB cubes).
  Each PBA input is a measure filled on the rows of its ZFI_PL lines by nested simple CASEs
  and zero elsewhere. Keys: company code, JV code, product, fiscal year, period, ZFI_PL
  section, ZFI_PL line. Texts: project name, report row (Myanmar A-1 and A-3 merged), report
  row number (the sheet's serial number, per product), product name, financial year. A
  generic measure `LineValue` with the section / line dimensions gives every other ZFI_PL
  line.
- Only constructs that have activated on this landscape are used in the two views (simple and
  nested CASE with literal branches, `cast( 0 as abap.dec )`, text elements, the JIB cube's
  annotation set). No `sum()`, no GROUP BY, no arithmetic, no AND / OR in a CASE.
- Not proven on this landscape before: a CDS table function, an AMDP class,
  `$session.client` as an actual parameter.

Test (no system access): the class's SQL statement and both DDL sources, as written, were run
in SQLite on `../original/ZFI_AGENDA_SE16_full_2026-11-10.tsv` (only `TO_DECIMAL`, the
NVARCHAR cast and the annotations translated). 1,547 table rows give 5,998 rows, no duplicate
key. Aggregated per report row / product / year / period and divided as the query will: 215
input cells of the sheet, 194 within 0.015; the 21 outside are those of section 9. Every
project has a name; every report row number equals the sheet's serial number.

## 16. Activated - first output of the cube (10/11/26)

Arnav created the four objects one by one in ADT by paste, in the order table function, class,
item view, cube; no activation error was reported. He then pasted part of the cube's output
(`../original/ZI_PBA_CUBE_output_partial_2026-11-10.tsv`: IEL, LZ, MECL, PCSA).

- 1,322 complete rows, 22 columns each. Every row - keys, texts, the nine measures and the
  line value - equals the result of the SQLite run of section 15 on the production extract.
- The output is at line grain, as designed: one row per ZFI_PL line, each measure filled on
  its own lines and zero on the others. Added up per project and period it gives the query's
  figures. IEL, OIL, 2025 9M: revenue 32.60, production cost 18.57, royalty 17.24, transport
  1.69, DD&A 6.24 (USD mn), production 0.601276, sales net 0.601901 (million bbl). Revenue /
  sales net = 54.16 and DD&A / production = 10.38, the per-barrel figures ZFI_PL itself saved
  in section A3 for the same lines.
- Report Row No. is displayed as 5, 7, 8, 12, 13, 99: a literal made of digits is NUMC in a
  classic view, and the list display drops the leading zero. Sorting is numeric, which is what
  the column is for.
- Now proven on this landscape: a CDS table function with an AMDP class, `$session.client`
  passed to its client parameter from a classic view, and the DF34_DEC columns read through
  `TO_DECIMAL` in SQLScript.

Still to do: C1 release of `ZI_PBA_CUBE`, the query with its eight calculated measures
(`../NOTES.md`), transport request.

## 17. First export of the published query - 2025-26, 9M (12/11/26)

`../original/CAQ_export_6_2025_9M_2026-11-12.xlsx`: query `2CZZ9_6Y2SQTAPWWLS` on `2CZIPBACUBE`,
variables Fiscal Year 2025 and Reporting Period 9M, filter Report Row No. 1 to 16. Eleven rows
(four gas, seven oil), the eight calculated measures. The empty preview of the same morning was
the filter on the text field, as suspected; with Fiscal Year it returns data.

**Against SAP:** 88 of 88 cells equal the figures worked out from the production extract of
10/11/26 (largest difference 1.4e-14). The calculated measures, `NDIV0` and the range filter do
what was intended.

**Against the board workbook** (PBA sheet, 9M FY'26 columns G, BX, DT, FP, HL, JH, KG, MC; oil
rows 10 to 20, gas rows 32 to 37): 65 of 88 cells within 0.015. The six input measures: 55 of 66.

| Cells | Query | Workbook | Cause |
|---|---|---|---|
| Myanmar gas, 4 inputs | 0 | price 7.33, costs 0.62 / 0.71 / 0.79 | MM2002 and MM2012 are on the ANNUAL run in SAP; no 9M record exists. The workbook has 108.98 USD mn on 14.872 mn MMBTU |
| BC-10 production cost, DD&A | 17.09, 14.11 | 17.12, 14.13 | same amounts (31.23, 25.78); production 1.827654 in ZFI_PL, 1.823903 on the sheet |
| GPOC production cost | 26.70 | 26.72 | same amount (80.89); production 3.029500 against 3.026770 |
| Lower Zakum royalty, DD&A | 15.01, 6.98 | 15.05, 7.00 | same amounts (68.07, 31.64); production 4.533487 against 4.521754 |
| MECL production cost | 24.71 | 24.68 | same amount (16.71); production 0.676260 against 0.677199 |
| MECL DD&A | 12.02 | 12.82 | amount differs: 8.13 in SAP, 8.68 on the sheet |

The twelve cost-of-goods-sold and profit cells that differ are sums of the above (Imperial by
0.02, from rounding inside the tolerance).

So: every amount equals the workbook except MECL DD&A; every price equals except Myanmar, which
SAP does not hold for 9M. The small cost differences are the production quantity: the sheet
divides by the approved production of its Production & Sales Quantity tab (DPR), ZFI_PL by its
own Share of Production, up to 0.26 % apart.

For finance, not changed here: whether ZFI_PL's production quantity is acceptable as the
divisor (the alternative is production from the DPR reconciled table - a join the cube does
not have), and which MECL DD&A figure is right.
Layout seen in the export: no result rows (Product totals not switched on) and rows in
alphabetical order (Report Row sits above Report Row No.).

**Decision, 12/11/26 (Arnav, on finance's confirmation):** the production quantity may differ
from the sheet; ZFI_PL's own Share of Production stays the divisor for now. The BC-10, GPOC,
Lower Zakum and MECL production-cost / royalty / DD&A differences of up to 0.04 are therefore
accepted. Still open with finance: MECL DD&A (8.13 in SAP, 8.68 on the sheet) and Myanmar at 9M
(no record in SAP). Only 2025-26 9M has been checked through the published query so far.

