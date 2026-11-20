# ovl/zfi_sub_loan_sched - Subsidiaries Loan and Deemed Investment Schedule (custom analytical query)

**Client:** OVL · **Filed:** 20/11/26 · **Status 20/11/26 (later):** Arnav: build on the assumptions, ship by abapGit ZIP. All objects written, **none imported or
activated yet**. The queries in `FSD/ZFI_SLDI_Assumptions_and_Queries.docx` were not sent to functional; every assumed
answer is an `ASSUMPTION:` line in the sources.
**Requirement:** `docs/SAP_FIORI_-_Subsidiaries_Loan_and_Deemed_Investment_Schedule_-_Annual_FY26.xlsx`

## What it is

Three schedules in USD for company code OVL, period 01.04.2025 - 31.03.2026:

| Schedule | Rows (G/L) | Columns |
|---|---|---|
| Loan movement | Imperial 100121 · OVRL 100133 · ONGC Narmada 100115 · OVSL 100611 + 100136 · BREML 100618 | Opening · Additional Funding · Repayment/Conversion/Interest · Closing · Provision Made · Net |
| Accrued interest | Imperial 91905 · OVRL 391908 · OVSL 91905 · BREML 391908 (shared G/Ls, split by text) | Opening · Interest recognised · Repayment/Conversion · Closing · Provision Made · Net |
| Deemed investment | Carabobo 100122 · BREML 100125 · OVRL 80538 · OVRL interest component 80541 | Opening · Additional Funding · Conv. to Equity · Conv. to Preference · Closing · Conv. to Loan · Closing; the four movements again in INR; INR/USD per movement |

Basis (sheet *Basis of Extraction*): opening/closing = FBL3N open items at key date, amount in local
currency 2; movement = all items posted in the period, classified **by item text**.

## Can it be a Custom Analytical Query

Yes, as bank reval / PBA / JIB: custom cube, query built in the app. Not on the standard cube, because
a query cannot (a) put two G/Ls on one row or one G/L on two rows, (b) split a movement by item text,
(c) take open items at two different key dates. All three go into the data source.

## Objects (dependency = creation order) - built 20/11/26

| # | Object | Type | Purpose | Depends on |
|---|---|---|---|---|
| 1 | `ZFI_SLDI_ROW` (+ data elements, domain for schedule) | Table, SM30 | Company code + G/L + sequence -> schedule (L/I/D), row no., subsidiary text, optional item-text pattern (shared G/Ls), provision flag | - |
| 2 | `ZFI_SLDI_MOV` (+ domain for movement column) | Table, SM30 | Company code + schedule + sequence -> item-text pattern, debit/credit -> movement column | - |
| 3 | `ZI_SLDI_ITEM_TF` | CDS table function | ACDOCA lines of the mapped G/Ls, leading ledger, no carry-forward rows; first matching rule of 1 and 2 per line; opening / movement / closing by From and To date | 1, 2 |
| 4 | `ZCL_SLDI_ITEM_TF` | AMDP class | Implementation of 3 (text patterns from a table need SQLScript `LIKE`; a CDS view takes only literal patterns) | 3 |
| 5 | `ZI_SLDI_CUBE` | CDS cube, parameters From date / To date | Dimensions: schedule, row, subsidiary, G/L, movement column, document, item text, assignment, partner. Measures USD: opening, the five movement columns, unclassified, closing, provision, net; INR: the movement columns | 3, 4 |
| - | SE54 maintenance for 1 and 2; C1 release of 5 (ADT, API State); three queries in the app; calculated measures there: closing before conversion to loan, INR / USD | manual | | 5 |

Shapes already proven on OCD: table function + AMDP under a classic cube (`ovl/per_barrel_agenda`,
10/11/26), parameterised cube in the app (`ovl/zfi_bank_reval`), DDIC by abapGit ZIP (bank reval, 28/10/26).
Not yet proven: passing view parameters into a table function.

## Requirement -> object

| Requirement | Implemented by |
|---|---|
| Rows per subsidiary, two G/Ls on one row | `ZFI_SLDI_ROW` |
| Shared G/L split by text | `ZFI_SLDI_ROW` pattern + 3/4 |
| Opening / closing = open items at key date, LC2 | 3/4 (posting date, clearing date; global currency = USD at OVL, confirmed 10/11/26 in bank reval) |
| Movement columns by text | `ZFI_SLDI_MOV` + 3/4 |
| Provision Made, Net Balance | `ZFI_SLDI_ROW` provision flag, cube measures - **G/L not named in the workbook (query 3)** |
| Actual INR at transaction date | cube measures in company code currency |
| Exchange rate impact | query calculated measure INR / USD |
| Three blocks | three queries on one cube |
| Hidden sheet "OVRL Loan Repayment Schedule" | **not mapped - assumed out of scope (query 10)** |

## Checks for Arnav before object 3 (display only, SE16N on ACDOCA, RLDNR 0L, RBUKRS OVL)

1. RACCT 91905 and 391908, GJAHR 2025: is RASSC (trading partner) filled and different per subsidiary?
2. RACCT 100125, GJAHR 2025: is GKONT filled on the conversion lines (100618 on the conversion to loan)?
3. RACCT 100115: is AUGDT filled on cleared lines, and do old years (2006 onwards) exist as line items
   with SGTXT? If history exists only as period 000 rows, the open-item basis cannot be rebuilt from ACDOCA.

## Shipping (20/11/26)

`src/` = 2 DOMA, 7 DTEL, 2 TABL, 2 DDLS, 1 CLAS, no DEVC (package chosen at import). Two ZIPs, same offline repo:

1. `ZFI_SLDI_1_of_2_without_cube.zip` - everything except `ZI_SLDI_CUBE`. Pull, activate.
2. `ZFI_SLDI_2_of_2_full.zip` - same plus the cube. Pull once the class is active (abapGit activates DDLS
   before CLAS, and a view on a table function does not activate before its class - PBA, 10/11/26).

XML shapes copied from bank reval (DOMA/DTEL/TABL/DDLS, pulled 28/10/26), `zdo_mts_mto` (fixed values) and
forecast paints (CLAS). **Not proven:** DDLS `SOURCE_TYPE = F` for the table function, and a CLAS without
`CLSCCINCL`. If either fails, paste `src/zi_sldi_item_tf.ddls.asddls` / `src/zcl_sldi_item_tf.clas.abap` in ADT.
Then by hand: SE54 for both tables, entries from `ZFI_SLDI_load.txt`, C1 release of the cube, the three queries.

Data elements reuse standard domains NUMC3, NUMC2, TEXT60, CHAR50, XFELD - assumed present (SE11 check).
