# ovl/zfi_tasa_recon - TASA Recon Statement as a Fiori tile (custom analytical query)

**Client:** OVL · **Filed:** 23/11/26 · **Status 24/11/26:** built, active and published on OCD 500
(Claude, desktop control) on Arnav's "Start building". **Mapping table still empty** (SM30 needs the
SAP GUI, which had logged out) - until it is loaded every row shows as "Other" / "Not in Customer List".
**Requirement:** `docs/TASA_Recon_Statement_AnnualFY26_v5.xlsx` (Arnav: "make this as a fiori tile
also .. check if you can do this with the info provided").

## Status 24/11/26 - what exists on OCD 500

Package **`ZFI_TASA`** (new, HOME / ZOCD, not encapsulated), workbench request **OCDK920558**
("SAP: FI: TASA Recon Statement Fiori Tile"). Nothing transported.

| Object | How | State |
|---|---|---|
| Domain `ZFI_TASA_PCT`, 7 data elements, table `ZFI_TASA_MAP` | ADT wizards (the GUI was logged out, so no abapGit). `src/*.xml` + `ZFI_TASA_DDIC.zip` are the same definitions, unused; `src/zfi_tasa_map.tabl.adt.txt` is the pasted table source | active |
| `ZI_TASA_DOCCUST`, `ZI_TASA_DOCGL`, `ZI_TASA_INC_ITEM`, `ZI_TASA_INC_CUBE`, `ZI_TASA_BAL_ITEM`, `ZI_TASA_BAL_CUBE` | ADT paste of `src/*.asddls`, in that order | active (warnings only) |
| C1 release of both cubes | ADT, API State, Use in Key User Apps | released |
| Queries | Custom Analytical Queries, all **Published** | see below |
| SE54 maintenance for `ZFI_TASA_MAP` + 58 entries (`load/ZFI_TASA_MAP_load.txt`) | **open - needs SAP GUI** | - |

| Query | Label | Technical name for the tile | Layout |
|---|---|---|---|
| `ZZ1_TASA_INCOME` | TASA Income by Project / Subsidiary | `2CZZ1_MV4AETHIWQTD` | Rows Sort No. + Project / Subsidiary; columns Income USD / INR x Fiscal Quarter with year total; prompt Fiscal Year (default 2025 = FY26, mandatory); CompanyCode = OVL |
| `ZZ1_TASA_BALANCE` | TASA Customer Balance and Reclassification | `2CZZ1_ZAS7W42BS1ZW` | Rows Customer Category, Customer, Project / Subsidiary; Gross, Provision, Net (USD), Closing Rate, Net at Closing Rate (INR, calculated = Net x Rate), Actual G/L INR, Reclassification USD / INR; prompt Key Date (default 31.03.2026); OVL |
| `ZZ1_TASA_AGING` | TASA Customer Aging | `2CZZ1_5FJ6YJM19FAS` | Same rows; 1 Month .. More than 3 Years + Gross Balance (USD); Key Date; OVL |

Names read from `DDLDEPENDENCY`.

**Checked on OCD 500 with the views (24/11/26, SQL console):**
- `ZI_TASA_INC_ITEM`, FY 2025, by partner and quarter against the workbook's Q1-Q4 USD and INR:
  **88 of 88 cells equal**; the only gap is Block 128 Q2 carrying the -0.72 "Other" JIB lines, which
  separates once `80801` is in the mapping table (then Block 128 = 100,000 / 100,000 and Other -0.72,
  as the workbook).
- `ZI_TASA_BAL_CUBE( p_keydate = '20260331' )` by customer: gross USD and all **7 aging buckets equal
  for all 19 customers** (0 differences) to the ZFI_AGE dump; totals 1,625,610.90 / 2,041,786.03 /
  645,456.00 / 256,291.77 / 120,615.41 / 281,172.31 / 137,060.29 = 5,107,992.71. Closing rate 93.75.
  One extra row (customer 10094, 0.36) belongs to another company code - the queries filter OVL.
- Aging by **calendar months**, not days: derived from the workbook's line items (0 / 1-2 / 3-5 /
  6-11 / 12-23 / 24-35 / 36+ months between posting month and key-date month); the cube compares the
  posting date with the first day of month 0, -2, -5, -11, -23, -35.

**Open:** SM30 + entries (GUI login), the tile (catalog / group from Arnav), the questions below
(defaults taken, each an `ASSUMPTION:` in the views), a query run once the table is loaded.

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
| P&L-TASA | Cube 1: ACDOCA lines of 230903, customer taken from the document's customer line (`KOART = 'D'`; `GKONT` / `KUNNR` are blank on the income line - checked 23/11) -> mapping row; measures USD (`KSL`) and INR (`HSL`); fiscal year / quarter from `POPER` by literal `CASE` (MEMORY §4.1 - no `month()`, no INT->NUMC) | Query: rows = project, columns = quarter / year. Q-on-Q difference and % as measures in the cube (current and previous quarter for a selected year/quarter), since CAQ cannot offset a quarter on its own |
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

## Checks run in OCD 500, 23/11/26 (ADT SQL console, read-only; ACDOCA `RLDNR 0L`, `RBUKRS OVL`)

| Check | Result |
|---|---|
| 230903, `GJAHR 2025`, total | **-18,722,408.62 USD / -1,660,654,536.70 INR, 393 lines** - equal to the workbook |
| Where the customer is | **Not on the income line**: `GKONT`, `GKOAR` and `KUNNR` are blank on all 393 lines. It is on the **customer line (`KOART = 'D'`) of the same document** - the cube must join income line to customer line by `RBUKRS / GJAHR / BELNR` |
| FY26 by customer (via that join) | **All 15 customers equal to the cent** (CPO-5 6,314,022.52, ONGBV 6,543,684.12, SPOC 2,490,391.20, OVRL 53,660.26 ...) |
| Lines without a customer line (8) | Block 128 = "Parent Co. Overheads 2024 / 2025" (-100,000 x 3, +100,000 = -200,000 USD, JV `CP0001`); "Other" -0.72 = four INTER-ASSOCIATION / CO Exp JIB lines netting to zero. Rule needed: no customer line -> by text or by the other G/L of the document (80801) |
| Q4 FY26 (`POPER` >= 010) by customer | **All 14 customers equal**, Block 128 -100,000 in period 011 - total 4,538,174.86 |
| 230903 by year vs the workbook's "P&L Income" row | FY21 (2020) -17,406,050.98 **equal** · FY22 (2021) -20,592,146.63 **equal** · FY23 (2022) **-21,783,750.54 vs -20,080,882.57 (SAP higher by 1,702,867.97 USD)** · FY24 (2023) **-20,279,674.39 vs -20,179,674.39 (SAP higher by 100,000.00 USD / 8,319,000 INR)** · FY25 (2024) -21,612,440.39 **equal**. Line items exist back to 2018 |
| 91111 open at 31.03.2026 (`BUDAT` <= key date, `AUGDT` blank or later, `BSTAT` <> C) by `KUNNR` | **All 19 customers equal to the SAP dump in the BS sheet**, INR and USD (5,107,992.71 USD / 462,876,293.79 INR) |
| Provision G/Ls 190790 / 190791, `GJAHR 2025` | Only 190790 has lines (8, -75,340.69 USD / -4,688,227.62 INR), **no customer on any of them**. The workbook provides only IPRNT (10,682.62 USD). Provision per customer cannot come from postings - needs a maintained value or rule |

**Answers this gives:** question 3 (Block 128 has no customer line - a text or G/L rule), question 4
("Other" = JIB lines netting to zero), question 5 (provisions are not customer-assigned in SAP).
**New point for question 1:** FY23 and FY24 in SAP no longer equal the workbook (postings after the
workbook froze them). Reading history from SAP changes those two years - the functional must choose.
The income cube, the balance cube and the aging all reproduce FY26 exactly with the join above.
