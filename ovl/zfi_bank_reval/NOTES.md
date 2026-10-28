# ovl/zfi_bank_reval — Bank Revaluation report for Group Reporting (custom analytical query)

**Client:** OVL · **System:** ovlrisedev (Fiori: *Custom Analytical Queries*) · **Filed:** 28/10/26
**Requester:** functional (FI) via Excel `original/FIORI_Development_-_Bank_Revaluation_-_Updated_V2.xlsx`

## What it is

A period-end bank revaluation sheet, one row per foreign/local-currency bank G/L account:
balance in the account currency, OVL's participating-interest (PI) share of it, the
exchange rate to USD at the key date, and the USD balance after revaluation, next to the
USD figure SAP already carries. The FI team built it in the Fiori app *Custom Analytical
Queries* as `ZZ1_BR_REPORT` ("Journal Entry Analyzer"), which generated the CDS query
`ZZ9_BR_REPORT` (SQL view `ZZ9_M8G5FS3XP4U2`) on `I_GLAccountLineItemCube`, with the G/L
hierarchy `H109/ONGC/BANK_REVAL` on the rows. Source as supplied:
`original/ZZ9_BR_REPORT.ddls.asddls` (806 lines); screenshot `original/*.png`.

## Why the generated query cannot be extended

`ZZ9_BR_REPORT` is correct for what it is — a valid app-generated query — but it is the
wrong layer for the two new columns:

- An `@Analytics.query: true` view can only re-expose elements of its one data source and
  add formulas over its measures. It cannot join a table, read TCURR, or carry a constant.
- `ZZ9_*` objects are generated; any manual edit is overwritten on the next *Publish* and
  the app does not let a query change its data source.

So the columns go into a **custom cube**, and the query is **re-created** in the app on
that cube (a new ID, e.g. `ZZ1_BR_REPORT2`; fields re-selected — far fewer than the 247
now selected; hierarchy re-picked).

## Column map — Excel → source

| Excel col | Heading | Source in the cube |
|---|---|---|
| B/C | GL Code / GL Description | `GLAccount` with `_GLAccountInChartOfAccounts` (key + text, hierarchy) |
| D | Account No | `BankAccountNumber` = T012K-BANKN via SKB1-HBKID/HKTID (blank until house banks exist — Excel says "To be created") |
| E | House Bank | `GLHouseBank` / `GLHouseBankAccount` = SKB1-HBKID / HKTID |
| F | Project/Section | `ProjectSection` — mapping table (text; replace by an SAP org element if one maps) |
| G | Business Unit | `BusinessUnit` — mapping table ("fixed element" per the Excel) |
| H | Account Currency | `GLAccountCurrency` = SKB1-WAERS |
| I | PI Interest in Bank Account | `PIShare` — mapping table, factor (0.97, 0.45, 1, 0.4, 0.9) |
| J | Local Currency Balance | `AmountInGLAccountCurrency` (company-code amount for INR accounts, transaction amount otherwise) |
| K | OVL Share = J × I | **query calculated measure** `AmountInGLAccountCurrency * PIShare` |
| L | Exchange Rate (from OB08) | `ExchangeRate` — SAP `currency_conversion` of 1 unit at `P_RevalDate` with the account's rate type |
| M | Exchange Rate Type (CLT / M / TTA) | `ExchangeRateType` — mapping table (it is an **input** to the rate lookup, not read from TCURR) |
| N | USD Balance after revaluation = K × L | **query calculated measure** `OVL Share * ExchangeRate` |
| O | Reported USD Balance SAP | `AmountInGlobalCurrency` / `AmountInFunctionalCurrency` / `AmountInFreeDefinedCurrency1` — whichever currency type is USD (confirm, then drop the other two) |

Prompts: Fiscal Year + Period range as today (query variables), plus `P_RevalDate`
(user input, the revaluation date) and `P_RevalCurrency` (fixed value `USD` in the query).

## Objects, in activation order

### 1. DDIC — `ZFI_BR_GLMAP` (SE11, by hand) + domain/data element + TMG

| Field | Key | Data element | Type | Meaning |
|---|---|---|---|---|
| `MANDT` | X | `MANDT` | CLNT 3 | |
| `BUKRS` | X | `BUKRS` | CHAR 4 | Company code |
| `SAKNR` | X | `SAKNR` | CHAR 10 | G/L account |
| `ZPISHARE` | | **`ZBR_PISHARE`** (new; domain `ZBR_PISHARE` DEC 7, 4 decimals) | DEC 7.4 | PI share as a factor, 1.0000 = 100 % |
| `KURST` | | `KURST` | CHAR 4 | Exchange rate type for the revaluation (CLT / M / TTA) |
| `ZPROJSECT` | | `TEXT40` | CHAR 40 | Project/Section (Excel col F) |
| `ZBUSUNIT` | | `TEXT40` | CHAR 40 | Business Unit (Excel col G) |

Delivery class **A**, *Display/Maintenance Allowed*, size category 0, no buffering.
Maintenance: SE54 table maintenance generator (one-step, function group `ZFI_BR_GLMAP`),
optional SE93 parameter transaction on SM30. Maintained in each system directly, so PI
changes need no transport. Load the 49 rows of the Excel once it exists. Field labels
come from the data elements, so `ZBR_PISHARE` needs short/medium/long texts
("PI Share").

Alternative considered and **not** recommended: hardcoding the 49 PI values in a CDS
`CASE` on `GLAccount`. Every farm-in/out would then be a transport.

### 2. `ZI_BR_BANKREVAL_ITM` — `ZI_BR_BANKREVAL_ITM.ddls.asddls` (folder root, 121 lines)

Classic `define view`, SQL view `ZIBRBNKREVITM`. `I_GLAccountLineItemCube` left-outer
joined to `skb1`, `t012k`, `zfi_br_glmap`. Adds `GLAccountCurrency`, house bank fields,
`BankAccountNumber`, the four mapping fields, `AmountInGLAccountCurrency` (CASE on
account currency = company code currency) and `UnitAmount` = 1.0 as `abap.curr(23,10)`.
Every `I_GLAccountLineItemCube` element name used is one that appears in the generated
query, so they are confirmed on this system. Table fields `skb1-waers/hbkid/hktid`,
`t012k-bankn` are standard.

### 3. `ZI_BR_BANKREVAL_CUBE` — `ZI_BR_BANKREVAL_CUBE.ddls.asddls` (folder root, 173 lines)

Classic `define view`, `@Analytics.dataCategory: #CUBE`, SQL view `ZIBRBNKREVCUBE`,
parameters `P_RevalDate : vdm_v_key_date` and `P_RevalCurrency : waers`. The exchange
rate element:

```
cast( currency_conversion( amount => Item.UnitAmount, source_currency => Item.GLAccountCurrency,
      target_currency => $parameters.P_RevalCurrency, exchange_rate_type => Item.ExchangeRateType,
      exchange_rate_date => $parameters.P_RevalDate, round => ' ', decimal_shift => ' ',
      decimal_shift_back => ' ', error_handling => 'SET_TO_NULL' ) as abap.dec(23,10) )
```

Why this and not a join on TCURR: OVL maintains `CLT` as `USD → INR` in OB08
(`ovl/zfi_jv_tb/ZFI_JV_TB.abap`, `FCURR = 'USD' AND TCURR = 'INR'`), while the Excel needs
*account currency → USD*. A hand-written join would have to redo inversion, `TCURF`
ratios (per-100/1000 currencies such as VND, IRR), negative (indirect) rates and
reference-currency triangulation, plus the inverted `GDATU` key date. `currency_conversion`
is SAP's own routine for all of that; converting exactly **1.0000000000** unit with
`round => ' '` and `decimal_shift => ' '` returns the rate itself, to 10 decimals, in the
right direction. Unmapped G/L (no rate type) or missing rate → `NULL`, visible as a blank
rate — the signal that `ZFI_BR_GLMAP` or OB08 lacks a row.

`PIShare` and `ExchangeRate` are **MAX** measures: correct on a G/L row, meaningless on a
total row (the Excel has no totals; switch totals off for them in the query).
`where PostingDate <= P_RevalDate` keeps the balance consistent with the rate date.

Dimension associations defined in the cube itself (`I_Ledger`, `I_CompanyCode`,
`I_GLAccountInChartOfAccounts` — standard keys), so key+text display and the
`H109/ONGC/BANK_REVAL` hierarchy work as they do on the standard cube.

### 4. Query — in the app (manual)

New custom analytical query on `ZI_BR_BANKREVAL_CUBE`. Rows: Company Code, G/L Account
(hierarchy `H109/ONGC/BANK_REVAL`, key+text), Account Currency, Exchange Rate Type,
Project/Section, Business Unit, Bank Account Number, G/L House Bank. Columns: Balance in
Account Currency, PI Share, Exchange Rate at Key Date, the USD currency-type amount, and
two **calculated measures**: *OVL Share* = `AmountInGLAccountCurrency * PIShare`, *USD
Balance after revaluation* = `OVL Share * ExchangeRate` (decimals: rate 6, amounts 2).
Filters: Ledger (derived leading), Company Code (mandatory), Fiscal Year (make it
mandatory), Period range; parameters: `P_RevalDate` user input, `P_RevalCurrency` fixed
`USD`. If the calculated measures are not wanted in the app, a third view on top of the
cube can carry them as CDS measures (same pattern, one more object).

## Release-constraint fallbacks (MEMORY §4 — none of these constructs is yet proven on OCQ)

| Construct | If activation rejects it |
|---|---|
| `cast( 1.0 as abap.curr(23,10) )` in object 2 | `cast( 1.0 as abap.dec(23,10) )`; `currency_conversion` accepts DEC amounts |
| `cast( currency_conversion(...) as abap.dec(23,10) )` in object 3 | drop the cast, annotate `@Semantics.amount.currencyCode: 'RevaluationCurrency'`, set decimals in the query |
| `decimal_shift_back` unknown parameter | remove it (no effect for a 2-decimal target currency) |
| `@Consumption.defaultValue` on the parameter | remove it; set the fixed value in the query instead |
| App does not offer the cube's parameters | write the query in ADT as `@Analytics.query: true` on the cube with `with parameters` passed through — then it is paste/ADT only, not key-user |

## Checks before go (Arnav / functional — no system access from here)

1. OB08 for `CLT`, `M`, `TTA`: which pairs exist for each account currency in the Excel
   (USD, MMK, EUR, BDT, VND, COP, VEB, AZN, INR, IRR, LYD, RUB, GBP) and in which
   direction; OB07 for those types: inversion allowed / reference currency. A missing pair
   shows as a blank rate, not a wrong one.
2. FINSC_LEDGER (or OB22) for the company codes: which currency type is USD — that decides
   Global / Functional / Free-defined 1 for Excel col O.
3. FS00 → Control data for the INR accounts (`93294`, `93201`, `93292`): account currency
   INR confirms the CASE branch; nothing to do if so.
4. The hierarchy ID `H109/ONGC/BANK_REVAL` is taken from the app's value help; re-pick it in
   the new query rather than typing it.
5. `vdm_v_key_date` and `waers` exist (both already used by the generated query / standard).

## How it ships

Paste-only in practice: DDIC in SE11 by hand (plus SE54 TMG), the two DDL sources pasted
into ADT, the query rebuilt in the Fiori app and *Published*. abapGit ZIP would carry the
DDIC + DDLS, but hand-written abapGit XML has not imported on this landscape
(MEMORY §6) — do not promise it.

## Do not

- Do not edit `ZZ9_BR_REPORT` in ADT — generated, overwritten on Publish.
- Do not replace `currency_conversion` by a `SELECT`-style TCURR join without handling
  direction, ratios and indirect quotation; the Excel's rate is account currency → USD,
  OB08 holds USD → INR.
- Do not add `@Analytics.query` views to an OData V4 service binding (MEMORY §4.1); the
  app's generated query handles OData itself.
