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
  and the FY'26 Q1 / H1 / 9M columns, are typed values. ZFI_PL went live 17.03.2023 and the
  write to `ZFI_AGENDA` was added 28.03.2024, so earlier years are not in SAP at all.
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
| A | `ZFI_AGENDA`, per_key A1 (quantities) and A2 (amounts) | small build; figures equal what finance saw in ZFI_PL | exists only for the year / period combinations a user ran; can be stale; needs the table key and types (checks below) |
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
