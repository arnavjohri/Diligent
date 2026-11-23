# ovl/zfi_sub_loan_sched - Subsidiaries Loan and Deemed Investment Schedule (custom analytical query)

**Client:** OVL · **Filed:** 20/11/26 · **Status 20/11/26 (later):** Arnav: build on the assumptions, ship by abapGit ZIP. All objects written, **none imported or
activated yet**. The queries in `FSD/ZFI_SLDI_Assumptions_and_Queries.docx` were not sent to functional; every assumed
answer is an `ASSUMPTION:` line in the sources.
**Requirement:** `docs/SAP_FIORI_-_Subsidiaries_Loan_and_Deemed_Investment_Schedule_-_Annual_FY26.xlsx`

## Status 23/11/26 - built, active and published on OCD 500 (Claude, desktop control)

Everything below exists in OCD client 500, package `ZFI_OTH`, workbench request **OCDK920552**
(task OCDK920553, "SAP: FI: Subsidiary Loan & Deemed Investment Schedule CAQ"). **Nothing transported.**

| Step | Done how | Result |
|---|---|---|
| 2 DOMA, 7 DTEL, 2 TABL | **ADT wizards** (not abapGit: the only offline repo on `ZFI_OTH` is the JIB one, and a different ZIP in it offers the JIB views for deletion - see `ovl/per_barrel_agenda/NOTES.md`) | all active |
| `ZI_SLDI_ITEM_TF`, `ZCL_SLDI_ITEM_TF`, `ZI_SLDI_CUBE` | ADT paste of `src/`, in that order | all active. **Proven:** view parameters passed into a table function (`TF( p_from : $parameters.P_FromDate )`) |
| SM30 | SE54: FG `ZFI_SLDI`, auth group `&NC&`, one step, screens 0001 (ROW) / 0002 (MOV), no recording routine | generated |
| Entries | SM30, 15 ROW + 5 MOV rows, words checked against ACDOCA first - `ZFI_SLDI_load.txt` | saved (client data, not on the TR) |
| C1 | ADT, API State, Use System-Internally (C1), Released, Use in Key User Apps | released (warnings only) |
| Queries | Custom Analytical Queries, all **Published** | see below |

| Query | Label | Technical name for the tile (`#AnalyticQuery-analyze?bsa_query=`) | Filter |
|---|---|---|---|
| `ZZ1_SLDI_LOAN` | Subsidiary Loan Movement Schedule | `2CZZ1_200HYYH5R7ZM` | ScheduleType = L |
| `ZZ1_SLDI_INTEREST` | Accrued Interest Movement Schedule | `2CZZ1_14IFEG0E06GT` | ScheduleType = I |
| `ZZ1_SLDI_DEEMED` | Deemed Investment Schedule | `2CZZ1_GZ22O2H113GC` | ScheduleType = D |

All three: prompts From Date / To Date (mandatory), rows Row No. + Subsidiary with a Grand Total, G/L Account
free for drill-down. Deemed adds calculated measures *Closing Balance before Conv. to Loan* (`Closing - Conv. to
Loan`) and `INR/USD` per movement (`NDIV0( INR / USD )`). Names read from `DDLDEPENDENCY`, not from a preview
(M-31).

Two cube changes were forced by Custom Analytical Queries (both in `src/zi_sldi_cube.ddls.asddls`, MEMORY §4.1):
parameters `DATUM` -> `VDM_V_KEY_DATE` ("The use of Data Element DATUM is not permitted") and element
`Schedule` -> `ScheduleType` ("SCHEDULE is a reserved word"). The rename was blocked until the draft query that
used the old field was deleted (DDIC: field still used in a view).

FY26 run (01.04.2025-31.03.2026) checks: ONGC Narmada opening = closing = 31,403,156.30 (= the workbook's
Provision Made amount); BREML deemed conversion to loan -135,528,106.80 = Loan to BREML addition; Carabobo
opening 246,469.23 fully converted to equity.

**Reconciliation to the workbook (sheet Loan & Interest Movement), FY26, after the movement rules were
changed to net like the workbook (23/11/26 later, `ZFI_SLDI_load.txt`):**

| Block | Result |
|---|---|
| Loan | Every row and column equal to the cent, except Provision Made / Net for ONGC Narmada (no provision G/L) |
| Deemed (USD) | Every row and column equal (Unclassified now 0) |
| Deemed (INR) | OVRL equal (5.35 INR rounding on conversion to equity); BREML conversions equal; BREML Additional Funding INR 15,321,989,177.29 vs workbook 14,919,977,377.29 (+402,011,800 INR) - the workbook's INR for the netted cash-call reversals differs from the posted INR amounts |
| Interest | OVRL, BREML equal. Imperial +3,768.54 (WHT line "WHT @ 15% Acc Interest 28Jan to 31 Mar 2025", no subsidiary in the text, falls to seq 999 = Imperial; not in the workbook). OVSL +282,130.71 on interest recognised and closing - not explainable from the workbook (its line-item sheets are FY21); FBL3N 91905 at 31.03.2026 for the OVSL lines will show it |

**Open - for functional / Arnav:**
1. Provision G/L still not named (query 3) - Provision Made and Net equal plain balances until it is entered.
2. Interest: Imperial +3,768.54 (WHT line) and OVSL +282,130.71 against the workbook - see table above.
3. 91905 / 391908 lines **without item text** fall to the seq 999 rows (Imperial / OVRL). With the FY26 data
   the OVRL interest row matches the workbook this way; confirm before deleting any 999 row.
4. Deemed BREML Additional Funding in INR differs from the workbook by 402,011,800 INR (USD equal).
5. Tile: catalog / group assignment pending (Arnav to name them). Transport of the queries themselves is a
   separate key-user step (they are not on OCDK920552).
6. The ZIPs in this folder were **not** used; the system was built from `src/` by ADT. They predate the two cube
   changes - do not import them.

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
