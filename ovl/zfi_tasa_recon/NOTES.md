# ovl/zfi_tasa_recon - TASA Recon Statement as a Fiori tile (custom analytical query)

**Client:** OVL · **Filed:** 23/11/26 · **Status:** feasibility only. Nothing built, nothing checked
in the system yet.
**Requirement:** `docs/TASA_Recon_Statement_AnnualFY26_v5.xlsx` (Arnav: "make this as a fiori tile
also .. check if you can do this with the info provided").

## What the workbook is

Six sheets (two of them hidden). Company code OVL, FY26 = 01.04.2025 - 31.03.2026, USD and INR.

| Sheet | Content | Source in SAP | In scope? |
|---|---|---|---|
| `P&L-TASA` | TASA income on P&L G/L **230903**, one row per project / subsidiary (23 rows + Other), USD and INR **per quarter and year, FY21 - FY26** (60 columns), Q4 vs Q3 difference and %. Column *Offset Account No* = the customer the income was billed to. Total checked against the G/L balance (row 31, Check = 0). *Related Party Income* subtotal over 8 rows | ACDOCA, RACCT 230903, grouped by offsetting account (customer) and fiscal quarter | yes |
| `BS - Customer Balance (TASA)` | Balance of customer non-trade G/L **91111** per customer at 31.03.2026, category TASA / non-TASA, provision (G/L 190790 / 190791), net receivable, INR at closing rate (93.75, typed) vs actual G/L INR, checks against the SAP dump and the aging. Then the **reclassification amount**: net TASA balance of 10 subsidiaries to 100616 / 100711, and the posting documents of past quarters | ACDOCA open items of 91111 at the key date, by customer | yes - amount only, the posting stays manual |
| `zfi_age_31.03.2026` | Dump of the existing custom report **ZFI_AGE**: aging of the same customers in 7 buckets (1 month, 2-3 m, 4-6 m, 6 m - 1 y, 1-2 y, 2-3 y, > 3 y), summary and line items with document, posting date, joint venture | ACDOCA open items, days between posting date and key date | yes (or keep ZFI_AGE) |
| `Customer List` | 57 customer codes -> classification (project / subsidiary name) and TASA / non-TASA | becomes a mapping table (SM30) | yes |
| `PayableBalanceReclassification` (hidden) | FY25 working: vendor 604276 (OVAI / BEO) monthly figures from FBL1N, the 31.03.2025 reclass 160602 / 190599 / 190541 | - | **no** - one-off working |
| `OVRL Reco` (hidden) | FY24-25 OVRL TASA booked vs revised, with GST | - | **no** - one-off working |

## Verdict: feasible, same pattern as the loan schedule

Custom cube(s) on ACDOCA plus a mapping table, published as Custom Analytical Queries and put on a
tile. Proven on OCD: parameterised cube in CAQ (bank reval, loan schedule), open items at a key date
(loan schedule), `currency_conversion` with a literal rate type (bank reval, MEMORY §4.1).
Simpler than the loan schedule: everything keys on **customer number**, not on item text, so plain
CDS views do it - no table function, no AMDP.

| Workbook block | Proposed object | Notes |
|---|---|---|
| Customer List | Table `ZFI_TASA_CUST` (SM30): customer -> row label, sort, TASA flag, related-party flag, include-in-reclass flag, balance-sheet G/L (info) | Several codes map to one row (`CPO5NT` and `10033` -> CPO-5) |
| P&L-TASA | Cube 1: ACDOCA lines of 230903, offsetting account (`GKONT`, customer) -> mapping row; measures USD (`KSL`) and INR (`HSL`); fiscal year / quarter from `POPER` by literal `CASE` (MEMORY §4.1 - no `month()`, no INT->NUMC) | Query: rows = project, columns = quarter / year. Q-on-Q difference and % as measures in the cube (current and previous quarter for a selected year/quarter), since CAQ cannot offset a quarter on its own |
| BS - Customer Balance | Cube 2, parameter key date: open items of 91111 (posting date <= key date, not cleared or cleared after it) per customer; provision G/Ls alongside; INR at closing rate via `currency_conversion` (rate type `M`, key date) next to actual INR; reclass amount = net balance of customers flagged in the table | Same open-item logic as `ZI_SLDI_ITEM_TF`, but in plain CDS |
| zfi_age | Cube 2 again: bucket from `dats_days_between( posting date, key date )`, 7 buckets as in ZFI_AGE | Or leave aging in ZFI_AGE and link it |
| Tile | Three queries (Income, Balance, Aging), tiles on the catalog / group Arnav names | As loan schedule |

## What the workbook alone does not settle - questions for the functional

1. **History FY21 - FY25:** read from ACDOCA as posted, or frozen as in the workbook? The workbook
   has hand adjustments SAP will not reproduce: CPO-5 FY21 Q1/Q2 (`=678890+346060`, `=1115398.5-346060`),
   Iran Farsi FY21-22 "Including GST" (cell comments). Expect FY21-22 not to tie.
2. **Quarters:** April - March, Q4 = periods 10-12. Do special periods 13-16 count in Q4?
3. **Block 128** row: offset account `80801` is not a customer number - a G/L? How do its
   230903 lines identify it?
4. **"Other"** row (-0.72 USD this year) = 230903 lines whose offset is not in the list - confirm.
5. **Provision per customer** (190790 / 190791): how a provision line is tied to a customer.
   Today only `IPRNT` carries one (100 %, typed as `=E44`).
6. **Closing rate** 93.75 is typed: SAP rate type `M` at the key date, or another type?
7. **Reclassification** to 100616 / 100711: display the amount only (assumed) - posting stays
   manual. The 10 customers summed in row 57 become the flag in the table.
8. **Aging basis:** posting date (as the ZFI_AGE dump suggests) or due / baseline date.
9. Several P&L rows show a balance-sheet G/L other than 91111 (OAAL 100609, ONGBV 100606,
   ONGCSCBV 100612, Carabobo 400122): should the balance tile include those G/Ls too?
10. The two hidden sheets are out of scope - confirm.

## Checks to run in OCD before building (read-only, SQL console)

1. ACDOCA `RLDNR 0L`, `RBUKRS OVL`, `RACCT 0000230903`, `GJAHR 2025`: sum `KSL` / `HSL` by `GKONT`,
   `GKART` - is `GKONT` the customer on every income line? Annual totals should give the workbook's
   18,722,408.62 USD / 1,660,654,536.70 INR, and CPO-5 (10033) 6,314,022.52 USD.
2. Same with `POPER` 010-012 for Q4: total 4,538,174.86 USD.
3. `RACCT 0000091111` open at 31.03.2026 by `KUNNR`: total 5,107,992.71 USD / 462,876,293.79 INR
   (the SAP dump in the BS sheet).
4. `GJAHR` 2020-2024 present as line items for 230903 (history question 1).
