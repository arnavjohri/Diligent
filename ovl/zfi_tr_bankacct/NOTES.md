# ovl/zfi_tr_bankacct — Treasury register of company bank accounts (Management Dashboard)

**Client:** OVL (assumed — see `ASSUMPTIONS_AND_QUERIES.md` item 1) · **Filed:** 03/11/26
**Requester:** Treasury / FI via Excel `original/Management_Dashboard_-_Bank_Details.xlsx`

## What it is

A table Treasury maintains in SM30 (one row per bank account held in the company's own
name), a basic CDS view that reads every row of it, and a cube on that view which is the data
source for a Custom Analytical Query (CAQ) — the Fiori tile for the Management Dashboard is
built in the app by the functional consultant, not in ADT. The sheet asks for a separate
T-code (Treasury maintains, all other finance users display) and lists nine columns. No sample
rows were supplied.

| Excel col | Heading | Table field | Data element | Type |
|---|---|---|---|---|
| — | (client) | `MANDT` key | `MANDT` | CLNT 3 |
| — | (company) | `BUKRS` key | `BUKRS` | CHAR 4, check `T001` |
| C | A/C Number | `ZACCTNO` key | `ZTR_ACCTNO` (dom. `ZTR_ACCTNO`) | CHAR 35 |
| B | Name of Bank Account | `ZACCTNAME` | `ZTR_ACCTNAME` (dom. `ZTR_TEXT60`) | CHAR 60 |
| D | Project/Section | `ZPROJSECT` | `ZTR_PROJSECT` (dom. `TEXT40`, standard) | CHAR 40 |
| E | Business Unit | `ZBUSUNIT` | `ZTR_BUSUNIT` (dom. `TEXT40`, standard) | CHAR 40 |
| F | Address | `ZADDRESS` | `ZTR_ADDRESS` (dom. `ZTR_TEXT120`) | CHAR 120 |
| G | Local Currency | `WAERS` | `WAERS` | CUKY 5, check `TCURC` |
| H | Country | `LAND1` | `LAND1` | CHAR 3, check `T005` |
| I | Principal Officer | `ZPRINCOFF` | `ZTR_PRINCOFF` (dom. `ZTR_TEXT60`) | CHAR 60 |
| J | Signatory Officer | `ZSIGNOFF` | `ZTR_SIGNOFF` (dom. `ZTR_TEXT60`) | CHAR 60 |

Project/Section and Business Unit are CHAR 40 on purpose — the same length as
`ZFI_BR_GLMAP-ZPROJSECT` / `ZBUSUNIT` in `ovl/zfi_bank_reval`, so the two can be compared or
joined if the "link to the Bank Revaluation template" is confirmed (query 9).

Z data elements rather than `TEXT40`/`TEXT60` everywhere: the SM30 column headings and the
view's field labels come from the data element, and Treasury should read *Principal Officer*,
not *Text, 60 characters*.

## Why a new table — `ZFI_BANK_DETAILS` already exists

`ZFI_BANK_DETAILS` is on OVL already (`ovl/jv-cash-call/src/SAPMZOVL_JV_CASH_CALL.abap`,
module `USER_COMMAND_9050`: `INSERT zfi_bank_details FROM wa_bank` → *Beneficiary added
successfully*). Fields `BANKL`, `BANKN`, `NAME1`, `BANKA`, `BANK_ADDR`, `BANK_COUNTRY`, `SNO`,
key `BANKN`. It is the JV cash-call **payee** bank list, not the company's own accounts, and it
is written by that module pool. The Treasury register therefore gets its own table. Do not name
anything `ZFI_BANK_DETAILS*` in this folder.

## Objects, in activation order

1. Domains `ZTR_ACCTNO` (CHAR 35), `ZTR_TEXT60` (CHAR 60), `ZTR_TEXT120` (CHAR 120)
2. Data elements `ZTR_ACCTNO`, `ZTR_ACCTNAME`, `ZTR_PROJSECT`, `ZTR_BUSUNIT`, `ZTR_ADDRESS`,
   `ZTR_PRINCOFF`, `ZTR_SIGNOFF`
3. Table `ZFI_TR_BANKACCT` — delivery class **A**, Display/Maintenance Allowed, size category 0,
   no buffering, enhancement category *Can be enhanced (character-type)*
4. `ZI_TR_BANKACCT` — `src/zi_tr_bankacct.ddls.asddls` (63 lines). Classic `define view`, SQL
   view `ZITRBANKACCT`, `@VDM.viewType: #BASIC`, plain projection of the table: keys
   `CompanyCode`, `BankAccountNumber`; elements `BankAccountName`, `ProjectSection`,
   `BusinessUnit`, `BankAddress`, `LocalCurrency` (`@Semantics.currencyCode`), `Country`,
   `PrincipalOfficer`, `SignatoryOfficer`. Labels set to the Excel headings. `#NOT_REQUIRED`
   access control. Kept separate from the cube on purpose: a cube cannot go into an OData V4 UI
   binding (MEMORY §4.1), so this is the base for any later list report or value help.
5. `ZI_TR_BANKACCT_CUBE` — `src/zi_tr_bankacct_cube.ddls.asddls` (90 lines). Classic
   `define view` on `ZI_TR_BANKACCT`, SQL view `ZITRBNKACCTCUBE`, `@Analytics.dataCategory:
   #CUBE`, `@ObjectModel.modelingPattern: #ANALYTICAL_CUBE`, `supportedCapabilities`
   `[#ANALYTICAL_PROVIDER, #CDS_MODELING_DATA_SOURCE, #CDS_MODELING_ASSOCIATION_TARGET,
   #SQL_DATA_SOURCE]`, `@Metadata.allowExtensions: true` — the exact header set of
   `ZI_BR_BANKREVAL_CUBE`, which the CAQ app listed on 02/11/26. All ten elements of the basic
   view as characteristics, `_CompanyCode` → `I_CompanyCode` for key + text, and one measure
   **`NumberOfAccounts`** = `cast( 1 as abap.int4 )`, `@DefaultAggregation: #SUM` (a cube
   needs a measure; SUM over rows is the account count per BU / country / currency).

Then by hand (never serialised — TS §4.1 steps 2, 5–9): foreign keys in SE11, SE54 TMG and
the SE93 transactions (Arnav), the key-user release of the cube in ADT (Arnav), the CAQ query
and tile in the app (functional consultant).

## How it ships — abapGit ZIP `ZFI_TR_BANKACCT.zip` (03/11/26, rebuilt with the cube)

`.abapgit.xml` (`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`) at the folder root; `src/` with
17 files: `package.devc.xml`, 3 `*.doma.xml`, 7 `*.dtel.xml`, `zfi_tr_bankacct.tabl.xml`,
`zi_tr_bankacct.ddls.asddls` + `.ddls.xml`, `zi_tr_bankacct_cube.ddls.asddls` + `.ddls.xml`.
Every XML is the element-for-element shape of the files that pulled on this landscape
(`kpmg/zpp_forecast_paints` 19/10/26 for DOMA / DTEL / TABL / DEVC, `ovl/zfi_bank_reval`
28/10/26 for DDLS) — generated, then diffed against them with the values blanked. No
foreign-key XML: that shape has never been pulled here, so the FKs are an SE11 step after
import (MEMORY M-04 / M-14).

**The ZIP carries everything abapGit can carry.** It cannot carry: the foreign keys (SE11),
the TMG (SE54), the T-codes (SE93), the authorisation group, the key-user release of the cube
(ADT API State), or the CAQ query itself (app). Those are TS §4.1 steps 2–9.

Import: `ZABAPGIT_STANDALONE` → New Offline Repo → package **`ZFI_TREASURY`** (new; the ZIP's
`package.devc.xml` sets the description) → Import ZIP → Pull → transport request when asked.
abapGit activates in dependency order (domains → data elements → table → `ZI_TR_BANKACCT` →
`ZI_TR_BANKACCT_CUBE`).

**Fallback, same objects, same order:** SE11 with the field table above (data elements first,
each on its domain), then ADT → New → Data Definition `ZI_TR_BANKACCT`, paste
`src/zi_tr_bankacct.ddls.asddls`, activate; then `ZI_TR_BANKACCT_CUBE`, paste
`src/zi_tr_bankacct_cube.ddls.asddls`. If the pull stops on a DDLS with a syntax error, the
DDIC is already in: open the view in ADT, paste the error here, the fix comes back as the one
file.

Re-zip after any change:

    cd ovl/zfi_tr_bankacct && rm -f ZFI_TR_BANKACCT.zip && zip -X ZFI_TR_BANKACCT.zip .abapgit.xml src/*

## Handover — from the ZIP to the tile

| Step | Who | Where | What |
|---|---|---|---|
| 1 | Arnav | `ZABAPGIT_STANDALONE` | Import `ZFI_TR_BANKACCT.zip` into new package `ZFI_TREASURY`, pull, activate. Fallback: SE11 + ADT paste, order above |
| 2 | Arnav | SE11 | Foreign keys `BUKRS`→`T001`, `WAERS`→`TCURC`, `LAND1`→`T005` on `ZFI_TR_BANKACCT`; activate |
| 3 | Arnav | SE54 / SE11 → Utilities → TMG | Auth group `ZTRS`, function group `ZFI_TR_BANKACCT`, one step, **no, or user, recording routine**. SE93: `ZTR_BANKACCT` (SM30, `UPDATE=X`) and `ZTR_BANKACCT_V` (SM30, `SHOW=X`) |
| 4 | Treasury | `ZTR_BANKACCT` | Enter the accounts. Nothing shows in the app until rows exist |
| 5 | Arnav | ADT | Quick check: Data Preview on `ZI_TR_BANKACCT_CUBE` returns the rows with `NumberOfAccounts` = 1 each. Then `RSRTS_ODP_DIS` → `2CZITRBNKACCTCUBE` must open without errors (2C + SQL view name); `RSRT` → `2CZITRBNKACCTCUBE/!2CZITRBNKACCTCUBE` runs it |
| 6 | Arnav | ADT | **Release the cube for key users** or the app will not list it (bank reval, 28/10/26): Project Explorer → right-click DDL source `ZI_TR_BANKACCT_CUBE` → *Properties* → tab *API State* → *Add Release State* → contract **Use in Key User Apps (C1)** → checks run → *Finish*. If a check fails, paste it here. Afterwards Properties → API State must say Released; the *View Browser* app shows type Cube with the key-user flag |
| 7 | Functional consultant | Fiori *Custom Analytical Queries* → *New* | Data source: search `ZI_TR_BANKACCT_CUBE` or `ZI_TR` — **no asterisk**, the dialog searches "contains" and takes `*` literally. Query name e.g. `ZZ1_TR_BANKACCT`, label "Bank Accounts" |
| 8 | Functional consultant | *Field Selection* / *Display* | Tick all ten characteristics and the measure. Rows: Company Code (key + text), Business Unit, Project/Section, Country, Local Currency, A/C Number, Name of Bank Account, Address, Principal Officer, Signatory Officer. Column: Number of Accounts (totals off if the tile should read as a list). Filters: Company Code, Business Unit, Country optional |
| 9 | Functional consultant | *Preview* → *Publish* | Publish generates `ZZ9_TR_BANKACCT`-style query. Tile: *Query Browser* → *Create Tile*, or *Create Tile* from the query. Excel via Analysis for Office: `2CZZ9_…` |

Authorisation: the published query runs with the user's analytics authorisations; the cube
has `#NOT_REQUIRED` access control. Display of the register through the tile is therefore
governed by the tile/catalog assignment, not by `S_TABU_DIS` — say so to the role owner.

## Gotchas

- `ZACCTNO` is a key of CHAR 35. Treasury must enter the account number exactly once per
  company code; a typo creates a second row rather than overwriting — that is intended.
- Delivery class A **with the standard TMG recording routine** makes SM30 ask for a transport on
  every entry. Set *no, or user, recording routine* when generating the TMG (TS §4.1 step 5).
- `LAND1` and `WAERS` are keys of `T005` / `TCURC`: Treasury types `IN`, `USD`, not "India".
  F4 works from the domain value tables even before the foreign keys are added; validation of a
  wrong code needs the foreign keys.
- The CAQ app lists a cube only when it is `#CUBE`, classified (`modelingPattern` /
  `supportedCapabilities`) **and** released for key-user apps. Active + `RSRTS_ODP_DIS` clean
  is not enough — the bank reval cube sat unlisted for a day on exactly that (ISSUES there).
- `NumberOfAccounts` is 1 per row. A total over a filter is the count; on a single-account row
  it is 1. If the dashboard needs no figure at all, hide the column in the query — the measure
  must still exist in the cube.
- Country and Local Currency display the key only in the query. Text associations to the
  standard country / currency views were **not** added because their names are not confirmed on
  this system; one association + one `@ObjectModel.foreignKey.association` each when they are.
- Both views have `@AccessControl.authorizationCheck: #NOT_REQUIRED`. If `ZI_TR_BANKACCT` is
  ever exposed via OData, add a DCL on `CompanyCode` (`F_BKPF_BUK`) first.
- Don't put view-entity syntax, `@Semantics.*` beyond `currencyCode`, or
  `@Consumption.valueHelpDefinition` into these views on OCQ — MEMORY §4.1. Don't put the cube
  into an OData V4 UI binding — same section.

## Status

03/11/26 — delivered, not yet imported. ZIP rebuilt the same day with the cube after the CAQ
requirement arrived. Open questions in `ASSUMPTIONS_AND_QUERIES.md`; the ones that change the
key (3, 4) and the link (9) should be answered before the table is activated with data in it.
