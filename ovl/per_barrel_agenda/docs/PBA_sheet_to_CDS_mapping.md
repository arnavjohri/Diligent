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

| # | Object | What | State |
|---|---|---|---|
| 1 | `ZI_PBA_LINE` (classic view, `../ZI_PBA_LINE.ddls.asddls`) | `ZFI_AGENDA` with the four column sets turned into rows; DF34_DEC cast to DEC | delivered 10/11/26, not yet activated |
| 2 | measures per project / product / year / period | picks the lines of section 1 into base measures | not written; waits for object 1 and the line list |
| 3 | cube for CAQ | dimensions, SUM measures, key-user release | not written |

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

