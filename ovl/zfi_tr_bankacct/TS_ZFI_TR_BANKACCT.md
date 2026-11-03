# TS — ZFI_TR_BANKACCT / ZI_TR_BANKACCT / ZI_TR_BANKACCT_CUBE (Management Dashboard — Bank Details)

## 1. Document control

| Item | Value |
|---|---|
| Version | 1.1 (1.0 on 03.11.2026; 1.1 the same day adds the CAQ cube and the key-user release step) |
| Author | Arnav Johri, Diligent Global |
| Date | 03.11.2026 |
| Project / system | OVL (assumed) · same system as `ZFI_BANK_REVAL` |
| Related FS | `Management_Dashboard_-_Bank_Details.xlsx`, sheet *Bank Account Details* (headings only), received 03/11/2026 — filed as `ovl/zfi_tr_bankacct/original/` |
| Companion documents | `ASSUMPTIONS_AND_QUERIES.md` / `FSD/ZFI_TR_BANKACCT_Assumptions_and_Queries.docx` (16 items); `NOTES.md` (handover table) |
| Transport | TBD |

## 2. Purpose / background

Treasury needs a separate transaction in which it records the bank accounts held in the
company's own name — account name and number, Project/Section, Business Unit, bank address,
account currency, country, principal and signatory officer — and all other finance users need a
display view of the same list. The data is entered by hand; nothing is derived from house banks.
This TS delivers the table Treasury maintains, a basic CDS view that reads every row of it, a
cube on that view as the data source for the Management Dashboard tile — built by the functional
consultant in the Fiori app *Custom Analytical Queries* (CAQ) — and the manual steps (foreign
keys, maintenance dialog, transactions, authorisation, key-user release) that make it all usable.

## 3. Objects affected

| Object | Type | New / changed | Package | TR |
|---|---|---|---|---|
| `ZTR_ACCTNO` | Domain, CHAR 35 | New | `ZFI_TREASURY` (suggested) | TBD |
| `ZTR_TEXT60` | Domain, CHAR 60 | New | same | same |
| `ZTR_TEXT120` | Domain, CHAR 120 | New | same | same |
| `ZTR_ACCTNO`, `ZTR_ACCTNAME`, `ZTR_PROJSECT`, `ZTR_BUSUNIT`, `ZTR_ADDRESS`, `ZTR_PRINCOFF`, `ZTR_SIGNOFF` | Data elements | New | same | same |
| `ZFI_TR_BANKACCT` | Transparent table | New | same | same |
| `ZI_TR_BANKACCT` (SQL view `ZITRBANKACCT`) | CDS DDL source, classic view, basic | New | same | same |
| `ZI_TR_BANKACCT_CUBE` (SQL view `ZITRBNKACCTCUBE`) | CDS DDL source, classic view, `@Analytics.dataCategory: #CUBE` | New | same | same |
| Key-user release of `ZI_TR_BANKACCT_CUBE` (API State, contract C1) | ADT, manual | New | — | same |
| Custom Analytical Query + tile on `ZI_TR_BANKACCT_CUBE` | Fiori app, by the functional consultant | New | — | — |
| Foreign keys on `ZFI_TR_BANKACCT` (`BUKRS`, `WAERS`, `LAND1`) | SE11, manual | New | same | same |
| Table maintenance generator for `ZFI_TR_BANKACCT` | SE54, manual (function group `ZFI_TR_BANKACCT`) | New | same | same |
| `ZTR_BANKACCT`, `ZTR_BANKACCT_V` | SE93 parameter transactions on SM30, manual | New | same | same |
| Authorisation group `ZTRS` (`S_TABU_DIS`) | SE54 → Authorization Groups, manual | New | — | same |

Not touched: `ZFI_BANK_DETAILS` and the JV cash-call module pool that owns it; `ZFI_BR_GLMAP`,
`ZI_BR_BANKREVAL_ITM`, `ZI_BR_BANKREVAL_CUBE` (the link in query 9 is not built).

## 4. Detailed changes

Source files: `ovl/zfi_tr_bankacct/src/` (17 files) and `ovl/zfi_tr_bankacct/.abapgit.xml`;
archive `ovl/zfi_tr_bankacct/ZFI_TR_BANKACCT.zip`.

### 4.1 Build and activation order

**Step 1 — DDIC + view by abapGit ZIP** (or by SE11 / ADT paste, same order).
`ZABAPGIT_STANDALONE` → New Offline Repo → package `ZFI_TREASURY` (new) → Import ZIP
`ZFI_TR_BANKACCT.zip` → Pull → transport when asked. Order inside the pull: domains → data
elements → table → `ZI_TR_BANKACCT` → `ZI_TR_BANKACCT_CUBE`. Check first in SE11 that
`ZFI_TR_BANKACCT`, `ZITRBANKACCT`, `ZITRBNKACCTCUBE` and the seven `ZTR_*` names do not already
exist. The ZIP carries everything abapGit can carry; steps 2–9 below cannot be in it.

Fallback by hand, when the ZIP does not import (MEMORY M-14 — this has happened):

| Order | SE11 object | Settings |
|---|---|---|
| 1 | Domain `ZTR_ACCTNO` | CHAR 35, output 35 |
| 1 | Domain `ZTR_TEXT60` | CHAR 60, output 60 |
| 1 | Domain `ZTR_TEXT120` | CHAR 120, output 120 |
| 2 | Data element `ZTR_ACCTNO` | domain `ZTR_ACCTNO`; short *Acct No.* / medium *Bank Account Number* / long *Bank Account Number* / heading *Bank Account Number* |
| 2 | `ZTR_ACCTNAME` | domain `ZTR_TEXT60`; *Acct Name* / *Name of Bank Account* / *Name of Bank Account* / *Name of Bank Account* |
| 2 | `ZTR_PROJSECT` | domain `TEXT40` (standard); *Proj/Sect* / *Project/Section* / *Project/Section* / *Project/Section* |
| 2 | `ZTR_BUSUNIT` | domain `TEXT40` (standard); *Bus. Unit* / *Business Unit* / *Business Unit* / *Business Unit* |
| 2 | `ZTR_ADDRESS` | domain `ZTR_TEXT120`; *Address* / *Address* / *Bank Address* / *Address* |
| 2 | `ZTR_PRINCOFF` | domain `ZTR_TEXT60`; *Princ.Off.* / *Principal Officer* / *Principal Officer* / *Principal Officer* |
| 2 | `ZTR_SIGNOFF` | domain `ZTR_TEXT60`; *Sign. Off.* / *Signatory Officer* / *Signatory Officer* / *Signatory Officer* |
| 3 | Table `ZFI_TR_BANKACCT` | Short text *Treasury: company bank accounts (Management Dashboard)*; delivery class **A**; Data Browser/Table View Maint. **Display/Maintenance Allowed**; technical settings data class APPL0, size category 0, **no buffering**; enhancement category *Can be enhanced (character-type)*. Fields in §4.2 |
| 4 | DDL source `ZI_TR_BANKACCT` | ADT → New → Data Definition, paste `src/zi_tr_bankacct.ddls.asddls` whole, activate |
| 5 | DDL source `ZI_TR_BANKACCT_CUBE` | ADT → New → Data Definition, paste `src/zi_tr_bankacct_cube.ddls.asddls` whole, activate |

**Step 2 — Foreign keys (SE11, after import, before the TMG).** Not in the ZIP (unproven
abapGit shape). Table `ZFI_TR_BANKACCT` → field → *Foreign Keys*:

| Field | Check table | Key fields | Cardinality / type |
|---|---|---|---|
| `BUKRS` | `T001` | `MANDT` = `ZFI_TR_BANKACCT-MANDT`, `BUKRS` = `ZFI_TR_BANKACCT-BUKRS` | 1 : CN, *Key fields of a text table* **off**, foreign key type *Key fields/candidates* |
| `WAERS` | `TCURC` | `MANDT`, `WAERS` | 1 : CN, *Non-key-fields/candidates* |
| `LAND1` | `T005` | `MANDT`, `LAND1` | 1 : CN, *Non-key-fields/candidates* |

Activate the table again. SM30 then rejects an unknown company code, currency or country.

**Step 3 — Authorisation group.** SE54 → *Authorization Groups* → *Create/Change* (maintains
`V_BRG`, object `S_TABU_DIS`): group `ZTRS`, text *Treasury register*. Then SE11 → table →
*Utilities → Table Maintenance Generator* (step 5) uses it.

**Step 4 — Data elements' labels** are already in the ZIP; nothing to do. (Fallback route: typed
in step 1.)

**Step 5 — Table Maintenance Generator (SE54 / SE11 → Utilities → TMG).**
Authorization group `ZTRS`; function group `ZFI_TR_BANKACCT` (new); maintenance type
**one step**, overview screen `0001`; recording routine **no, or user, recording routine**
(delivery class A — the standard routine would prompt for a transport on every SM30 entry).
Generate. Expected: the overview shows company code, account number and the eight attributes
in table order with the data-element headings.

**Step 6 — Transactions (SE93).** Both *Transaction with parameters* on `SM30`, *Skip initial
screen* on, default values:

| T-code | Text | Default values | For |
|---|---|---|---|
| `ZTR_BANKACCT` | Treasury: Bank Accounts (Maintain) | `VIEWNAME` = `ZFI_TR_BANKACCT`, `UPDATE` = `X` | Treasury |
| `ZTR_BANKACCT_V` | Treasury: Bank Accounts (Display) | `VIEWNAME` = `ZFI_TR_BANKACCT`, `SHOW` = `X` | all finance users |

GUI support: SAP GUI for Windows / HTML / Java all on. The sheet asks for "a separate T-Code"
— this is it; the display variant is the "view option".

**Step 7 — Roles (PFCG, by the authorisation team).** Treasury role: `S_TCODE` `ZTR_BANKACCT`
+ `S_TABU_DIS` `DICBERCLS` = `ZTRS`, `ACTVT` 02 03. Finance display role: `S_TCODE`
`ZTR_BANKACCT_V` + `S_TABU_DIS` `ZTRS`, `ACTVT` 03. Because the group is new, nobody has it by
accident.

**Step 8 — Release the cube for key-user apps (ADT, Arnav).** Without this the CAQ app does not
list the cube, even when it is active and `RSRTS_ODP_DIS` opens `2CZITRBNKACCTCUBE` cleanly
(bank reval, 28/10/26). Project Explorer → DDL source `ZI_TR_BANKACCT_CUBE` → right-click →
*Properties* → tab *API State* → *Add Release State* → contract **Use in Key User Apps (C1)** →
the release checks run → *Finish*. Afterwards *API State* reads Released. Cross-check in the
*View Browser* app: type Cube, key-user flag set. If a check fails, paste the message.

**Step 9 — Query and tile (Fiori *Custom Analytical Queries*, functional consultant).** *New* →
data source: search `ZI_TR_BANKACCT_CUBE` (type part of the name, **no asterisk**) → query name
e.g. `ZZ1_TR_BANKACCT`, label *Bank Accounts* → *Field Selection*: all ten characteristics and
*Number of Accounts* → *Display*: rows Company Code (key + text), Business Unit, Project/Section,
Country, Local Currency, A/C Number, Name of Bank Account, Address, Principal Officer, Signatory
Officer; column *Number of Accounts* (totals off for a list-like tile) → *Filters*: Company Code,
Business Unit, Country optional → *Preview* → *Publish*. Tile from the *Query Browser* app
(*Create Tile*) or from the query. Before the app, prove the engine accepts the cube:
`RSRTS_ODP_DIS` → `2CZITRBNKACCTCUBE`; `RSRT` → `2CZITRBNKACCTCUBE/!2CZITRBNKACCTCUBE`.

### 4.2 Table `ZFI_TR_BANKACCT` — field list (positional, keys first)

| # | Field | Key | Data element | Type | Excel column |
|---|---|---|---|---|---|
| 1 | `MANDT` | X | `MANDT` | CLNT 3 | — |
| 2 | `BUKRS` | X | `BUKRS` | CHAR 4 | — (assumed, query 3) |
| 3 | `ZACCTNO` | X | `ZTR_ACCTNO` | CHAR 35 | C — A/C Number |
| 4 | `ZACCTNAME` | | `ZTR_ACCTNAME` | CHAR 60 | B — Name of Bank Account |
| 5 | `ZPROJSECT` | | `ZTR_PROJSECT` | CHAR 40 | D — Project/Section |
| 6 | `ZBUSUNIT` | | `ZTR_BUSUNIT` | CHAR 40 | E — Business Unit |
| 7 | `ZADDRESS` | | `ZTR_ADDRESS` | CHAR 120 | F — Address |
| 8 | `WAERS` | | `WAERS` | CUKY 5 | G — Local Currency |
| 9 | `LAND1` | | `LAND1` | CHAR 3 | H — Country |
| 10 | `ZPRINCOFF` | | `ZTR_PRINCOFF` | CHAR 60 | I — Principal Officer |
| 11 | `ZSIGNOFF` | | `ZTR_SIGNOFF` | CHAR 60 | J — Signatory Officer |

### 4.3 View `ZI_TR_BANKACCT` — `src/zi_tr_bankacct.ddls.asddls` (63 lines)

Anchor: `define view ZI_TR_BANKACCT as select from zfi_tr_bankacct as BankAcct`.
Header annotations as on `ZI_BR_BANKREVAL_ITM` (activated 28/10/26): `@AbapCatalog.sqlViewName:
'ZITRBANKACCT'`, `compareFilter`, `preserveKey`, `@AccessControl.authorizationCheck:
#NOT_REQUIRED`, `@VDM.viewType: #BASIC`, `@ClientHandling.algorithm: #SESSION_VARIABLE`,
`@Metadata.ignorePropagatedAnnotations: true`. Element list, one per table field, labelled with
the Excel heading:

| Element | Key | Source | Label |
|---|---|---|---|
| `CompanyCode` | X | `bukrs` | Company Code |
| `BankAccountNumber` | X | `zacctno` | A/C Number |
| `BankAccountName` | | `zacctname` | Name of Bank Account |
| `ProjectSection` | | `zprojsect` | Project/Section |
| `BusinessUnit` | | `zbusunit` | Business Unit |
| `BankAddress` | | `zaddress` | Address |
| `LocalCurrency` | | `waers` (`@Semantics.currencyCode: true`) | Local Currency |
| `Country` | | `land1` | Country |
| `PrincipalOfficer` | | `zprincoff` | Principal Officer |
| `SignatoryOfficer` | | `zsignoff` | Signatory Officer |

No joins, parameters, aggregation or `@Analytics.*` — a base view that a consumption view, an
analytical query or a report can sit on. Assumptions are in the source as `// ASSUMPTION:`.

### 4.4 Cube `ZI_TR_BANKACCT_CUBE` — `src/zi_tr_bankacct_cube.ddls.asddls` (90 lines)

Anchor: `define view ZI_TR_BANKACCT_CUBE as select from ZI_TR_BANKACCT as BankAcct`.
The data source for CAQ. Header: `@AbapCatalog.sqlViewName: 'ZITRBNKACCTCUBE'`, `@VDM.viewType:
#COMPOSITE`, `@Analytics.dataCategory: #CUBE`, `@ObjectModel.modelingPattern: #ANALYTICAL_CUBE`,
`@ObjectModel.supportedCapabilities: [#ANALYTICAL_PROVIDER, #CDS_MODELING_DATA_SOURCE,
#CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE]`, `@Metadata.allowExtensions: true`,
`@ObjectModel.usageType.*` — the set that got `ZI_BR_BANKREVAL_CUBE` listed in the app on
02/11/26, with `sizeCategory: #S` and `dataClass: #MASTER` for a small master-data table.
Association `_CompanyCode` to `I_CompanyCode` (proven on this system) with
`@ObjectModel.foreignKey.association` on `CompanyCode` for key + text.

| Element | Role | Source | Label |
|---|---|---|---|
| `CompanyCode` | key, characteristic, text via `_CompanyCode` | basic view | Company Code |
| `BankAccountNumber` | key, characteristic | basic view | A/C Number |
| `BankAccountName`, `ProjectSection`, `BusinessUnit`, `BankAddress`, `Country`, `PrincipalOfficer`, `SignatoryOfficer` | characteristics | basic view | Excel headings |
| `LocalCurrency` | characteristic, `@Semantics.currencyCode: true` | basic view | Local Currency |
| `NumberOfAccounts` | **measure**, `@DefaultAggregation: #SUM` | `cast( 1 as abap.int4 )` | Number of Accounts |
| `_CompanyCode` | association exposed | `I_CompanyCode` | — |

A cube needs at least one measure; the register has no amount, so the constant 1 summed over
rows gives the account count per Business Unit / country / currency. Labels are re-stated because
`@Metadata.ignorePropagatedAnnotations: true` drops the basic view's. Country and currency texts
are not wired (query 16: the standard view names are not confirmed on this system).

## 5. Requirement mapping

| Sheet requirement | Implemented by |
|---|---|
| "A separate T-Code … managed by the treasury department" | `ZTR_BANKACCT` (SE93 → SM30 maintain) on `ZFI_TR_BANKACCT`, auth group `ZTRS` activity 02 |
| "view option will be provided to all other finance personnals" | `ZTR_BANKACCT_V` (SM30 display), auth group `ZTRS` activity 03; the CAQ tile for Fiori users |
| "Bank A/cs … in the name of the company only" | Scope of the register; `BUKRS` key identifies the company. Not enforced by code — Treasury's data discipline |
| Columns B–J | Fields 3–11 of §4.2, elements of §4.3, one to one |
| "The data is user-input based and must be entered by the user" | SM30 one-step maintenance; nothing derived from `T012`/`T012K` |
| "Can be linked through Bank Revaluation FIORI Template as well" | **Open — query 9.** Not built; the join key must be named first |
| Fetch all the data (Arnav) | `ZI_TR_BANKACCT` |
| Fiori tile through CAQ from the CDS data source (Arnav, 03/11/26) | `ZI_TR_BANKACCT_CUBE` + key-user release (step 8); query and tile by the functional consultant (step 9) |
| "Management Dashboard" — a figure to show | `NumberOfAccounts` (query 15) |

## 6. Test scenarios

| # | Input | Expected | Actual |
|---|---|---|---|
| 1 | Import ZIP / SE11 build; SE11 → `ZFI_TR_BANKACCT` active, 11 fields, 3 keys | Table active; data-element labels show in SE11 field list | |
| 2 | ADT Data Preview on `ZI_TR_BANKACCT` with an empty table | 0 rows, 10 columns with the Excel headings | |
| 3 | `ZTR_BANKACCT` → New Entries: `OVL`, an account, all attributes, `USD`, `IN` → Save | Saved, no transport prompt | |
| 4 | Same row again (same `BUKRS` + `ZACCTNO`) | SM30 rejects the duplicate key | |
| 5 | Company code `XXXX` (not in `T001`), currency `XXX`, country `ZZ` | Rejected after step 2 (foreign keys); F4 lists valid values | |
| 6 | 35-character account number; 120-character address | Accepted in full, visible in SE16N and the view | |
| 7 | `ZTR_BANKACCT_V` as a finance user without activity 02 | Display only; *Edit* not offered; `ZTR_BANKACCT` refused (`S_TABU_DIS`) | |
| 8 | ADT Data Preview on `ZI_TR_BANKACCT` after 3 and 6 | Every stored row and value returned unchanged, `LocalCurrency` typed as currency key | |
| 9 | SE16N on `ZITRBANKACCT` (SQL view) in another client | Only that client's rows | |
| 10 | ADT Data Preview on `ZI_TR_BANKACCT_CUBE` | Same rows as the basic view, `NumberOfAccounts` = 1 on each, Company Code text resolvable via `_CompanyCode` | |
| 11 | `RSRTS_ODP_DIS` → `2CZITRBNKACCTCUBE`; `RSRT` → `2CZITRBNKACCTCUBE/!2CZITRBNKACCTCUBE` | Provider opens without errors; the default query returns the rows, *Number of Accounts* = row count | |
| 12 | CAQ → *New* → search `ZI_TR_BANKACCT_CUBE` after step 8 | Cube listed; without step 8 it is not | |
| 13 | Published query, filter Business Unit = one value | Only that BU's accounts; *Number of Accounts* total = their count | |

## 7. Open points

Items 1–16 of `ASSUMPTIONS_AND_QUERIES.md` (10 answered 03/11/26). The ones to settle **before** the table is activated
with live rows: 3 (company code in the key), 4 (account number as key and 35 characters), 9
(link to the Bank Revaluation cube — adds a field). Items 11 (audit trail), 15 (the counting measure) and 16 (country / currency texts in the query)
can follow later without a key change.
