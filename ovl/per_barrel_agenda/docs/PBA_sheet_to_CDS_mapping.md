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
- Not visible in the pasted rows: 'ROYALTY', 'Share of Production', and the A2 rows of the
  cost lines. To be confirmed from a full list of one project before object 2.

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

