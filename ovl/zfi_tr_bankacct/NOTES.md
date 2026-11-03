# ovl/zfi_tr_bankacct — Treasury register of company bank accounts (Management Dashboard)

**Client:** OVL (assumed — see `ASSUMPTIONS_AND_QUERIES.md` item 1) · **Filed:** 03/11/26
**Requester:** Treasury / FI via Excel `original/Management_Dashboard_-_Bank_Details.xlsx`

## What it is

A table Treasury maintains in SM30 (one row per bank account held in the company's own
name) and a CDS view that reads every row of it, for the Management Dashboard. The sheet asks
for a separate T-code — maintained by Treasury, display for all other finance users — and
lists nine columns. No sample rows were supplied.

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
   view `ZITRBANKACCT`, plain projection of the table: keys `CompanyCode`, `BankAccountNumber`;
   elements `BankAccountName`, `ProjectSection`, `BusinessUnit`, `BankAddress`, `LocalCurrency`
   (`@Semantics.currencyCode`), `Country`, `PrincipalOfficer`, `SignatoryOfficer`. Labels set to
   the Excel headings. `#NOT_REQUIRED` access control (the T-code carries the authorisation).

Then by hand (never serialised — TS §4.1 steps 2, 5–7): foreign keys in SE11, SE54 TMG, two
SE93 parameter transactions, authorisation group for `S_TABU_DIS`, PFCG.

## How it ships — abapGit ZIP `ZFI_TR_BANKACCT.zip` (03/11/26)

`.abapgit.xml` (`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`) at the folder root; `src/` with
15 files: `package.devc.xml`, 3 `*.doma.xml`, 7 `*.dtel.xml`, `zfi_tr_bankacct.tabl.xml`,
`zi_tr_bankacct.ddls.asddls` + `.ddls.xml`. Every XML is the element-for-element shape of
the files that pulled on this landscape (`kpmg/zpp_forecast_paints` 19/10/26 for DOMA / DTEL /
TABL / DEVC, `ovl/zfi_bank_reval` 28/10/26 for DDLS) — generated, then diffed against them
with the values blanked. No foreign-key XML: that shape has never been pulled here, so the FKs
are an SE11 step after import (MEMORY M-04 / M-14).

Import: `ZABAPGIT_STANDALONE` → New Offline Repo → package **`ZFI_TREASURY`** (new; the ZIP's
`package.devc.xml` sets the description) → Import ZIP → Pull → transport request when asked.
abapGit activates in dependency order (domains → data elements → table → view).

**Fallback, same objects, same order:** SE11 with the field table above (data elements first,
each on its domain), then ADT → New → Data Definition `ZI_TR_BANKACCT` and paste
`src/zi_tr_bankacct.ddls.asddls`. If the pull stops on the DDLS with a syntax error, the DDIC
is already in: open the view in ADT, paste the error here, the fix comes back as the one file.

Re-zip after any change:

    cd ovl/zfi_tr_bankacct && rm -f ZFI_TR_BANKACCT.zip && zip -X ZFI_TR_BANKACCT.zip .abapgit.xml src/*

## Gotchas

- `ZACCTNO` is a key of CHAR 35. Treasury must enter the account number exactly once per
  company code; a typo creates a second row rather than overwriting — that is intended.
- Delivery class A **with the standard TMG recording routine** makes SM30 ask for a transport on
  every entry. Set *no, or user, recording routine* when generating the TMG (TS §4.1 step 5).
- `LAND1` and `WAERS` are keys of `T005` / `TCURC`: Treasury types `IN`, `USD`, not "India".
  F4 works from the domain value tables even before the foreign keys are added; validation of a
  wrong code needs the foreign keys.
- The view has `@AccessControl.authorizationCheck: #NOT_REQUIRED`. If it is ever exposed via
  OData, add a DCL on `CompanyCode` (`F_BKPF_BUK`) first.
- Don't put `@Analytics.*`, view-entity syntax or `@Consumption.valueHelpDefinition` into this
  view on OCQ — MEMORY §4.1.

## Status

03/11/26 — delivered, not yet imported. Open questions in `ASSUMPTIONS_AND_QUERIES.md`; the
ones that change the key (3, 4) and the link (9) should be answered before the table is
activated with data in it.
