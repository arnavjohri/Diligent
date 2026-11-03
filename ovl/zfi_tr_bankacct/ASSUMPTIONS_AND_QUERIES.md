# ZFI_TR_BANKACCT — Assumptions and Queries

Project OVL (assumed, see item 1) · requirement received as `Management_Dashboard_-_Bank_Details.xlsx`
on 03/11/2026 · prepared 03/11/2026

Requirement as received (sheet *Bank Account Details*): *"A separate T-Code is required to be
prepared for Bank A/c details. T-Code will be managed by the treasury department and view option
will be provided to all other finance personnals. The Bank A/cs will be those who are in the name of
the company only."* Nine columns: Name of Bank Account, A/C Number, Project/Section, Business Unit,
Address, Local Currency, Country, Principal Officer, Signatory Officer. Notes: *"The data is
user-input based and must be entered by the user."* and *"Can be linked through Bank Revaluation
FIORI Template as well."* The sheet carries headings only — no sample rows.

Arnav's ask: a custom table that Treasury maintains, and a CDS view that reads all of it.

Each item: the question, where it comes from, what the delivered objects assume if no answer
arrives, and what breaks if that assumption is wrong.

| # | Question | From | Assumed in the delivered objects | If wrong |
|---|---|---|---|---|
| 1 | Project, system and package? | Not stated. "Bank Revaluation FIORI Template" is `ovl/zfi_bank_reval` (OVL), and Project/Section + Business Unit are the same two columns as that Excel | **OVL**, same system as `ZFI_BANK_REVAL` (OCD/OCQ). New package, named at import — suggested `ZFI_TREASURY`. | Nothing in the objects changes; only where the ZIP is imported. |
| 2 | Is this the existing table **`ZFI_BANK_DETAILS`**, or new? | Repo scan: `SAPMZOVL_JV_CASH_CALL` / `SAPMZOVL_JV_CC_PAI` read and insert `ZFI_BANK_DETAILS` (fields `BANKL`, `BANKN`, `NAME1`, `BANKA`, `BANK_ADDR`, `BANK_COUNTRY`, `SNO`; key `BANKN`; screen 9050 says *Beneficiary added successfully*) | **New table `ZFI_TR_BANKACCT`.** `ZFI_BANK_DETAILS` is the JV cash-call *beneficiary* (payee) bank list — other companies' accounts, no company code, no currency, no officers, maintained from the cash-call screen. Different data, different owner, different key. | If Treasury wants one list: append structure on `ZFI_BANK_DETAILS` with the five missing fields — but its key (`BANKN` alone) and its maintenance screen belong to the cash call, and any Treasury edit there changes cash-call behaviour. Not recommended. |
| 3 | Company code in the key? | "in the name of the company only" — no company code column in the sheet | **`BUKRS` is the second key field** (after `MANDT`), check table `T001`. Treasury enters it per row (`OVL`, the value fixed for `ZFI_BR_GLMAP` on 02/11/26). Keeps the register usable if a second company code (OSL etc.) ever holds accounts, and keeps the join to `ZFI_BR_GLMAP` (keyed `BUKRS` + `SAKNR`) possible. | Drop `BUKRS` from table and view **before** activation — after go-live a key change is a table conversion. |
| 4 | Primary key = the account number? Length? | "A/C Number" | **`BUKRS` + `ZACCTNO`** unique; `ZACCTNO` is CHAR **35** (IBAN is 34; `T012K-BANKN` is only 18). | Same number at two banks, or a running serial wanted: add a bank key / SWIFT key field, or a NUMC sequence from an SNRO object (manual object, not in a ZIP). |
| 5 | Country and currency as SAP keys or as free text? | "Local Currency", "Country" | **Keys**: `WAERS` (CUKY 5, `TCURC`) and `LAND1` (CHAR 3, `T005`) — F4 in SM30, `IN` / `USD`, and a dashboard can group on them. Foreign keys to `T001`, `TCURC`, `T005` are added in SE11 after import (TS §4.1 step 2). | Swap the two data elements for `ZTR_TEXT60`. Grouping by country/currency then depends on how each user typed it. |
| 6 | What is "Local Currency"? | column G | **The currency the account is held in** (account currency), not the company code currency. | Label change only (`@EndUserText.label` in the view, data element text). |
| 7 | Address as one line? | "Address" | **One field, CHAR 120** (`ZTR_ADDRESS`). | Split into two or three lines of 60: one field + one view element each, before activation. |
| 8 | Principal / Signatory Officer: a name, or a user ID / employee number? One per account? | columns I, J | **Free text, CHAR 60, one of each.** | Use `XUBNAME` (SAP user, `USR02`) or `PERNR_D` with F4; several signatories per account need a second table (account → signatory), a new object. |
| 9 | Link to the Bank Revaluation cube — by which key? | row 8: "Can be linked through Bank Revaluation FIORI Template as well" | **No link field in v1.** The natural key is the bank G/L account (`ZFI_BR_GLMAP` is `BUKRS` + `SAKNR`) or house bank / account ID (`SKB1-HBKID/HKTID` → `T012K-BANKN`). Say which. | One optional field `SAKNR` (or `HBKID`+`HKTID`) on the table, one element in `ZI_TR_BANKACCT`, one `left outer join` in `ZI_BR_BANKREVAL_ITM`. Cheap, but not without the key decision. |
| 10 | "View option for all other finance personnel" — a display T-code, or a Fiori list on the CDS view? | row 2 | **Two SE93 parameter transactions** on SM30 (maintain for Treasury, display for Finance) and an authorisation group on the table; the CDS view is built as asked but **not** exposed as OData. | A Fiori tile needs `ZC_TR_BANKACCT` + service definition + binding (three objects) and the MEMORY §4.1 rules; the basic view here is the right base for it. |
| 11 | Audit trail — who entered or changed a row, when? | not stated | **None in v1.** SE54 → technical setting *Log data changes* can be switched on without a field (viewed in SCU3). | Four admin fields (created/changed by/on) plus a TMG event (01/05) that fills them — an append and a generated-FM change. |
| 12 | Initial load? | sheet has headings only | Treasury types rows into SM30. | If a filled sheet exists: one-off paste into SM30 *New Entries*, as done for `ZFI_BR_GLMAP` (`ZFI_BR_GLMAP_load.txt`). |
| 13 | Delivery class and transport of entries? | "data is user-input based" | **Delivery class A**, TMG recording routine *no, or user, recording routine* — SM30 entries are made in each system directly, no transport prompt. | If entries must be transported (class C): change `CONTFLAG` and the recording routine before the first entry. |
| 14 | Target release? | not stated | **OCQ, older S/4** (MEMORY §4): classic `define view` with SQL view name `ZITRBANKACCT`, the form that activated on 28/10/26; no view entity. | If the system is newer the classic view still activates — nothing to change. |

Deliberately **not built** (not in the sheet, not asked): foreign-key XML in the ZIP (added by hand
in SE11 — unproven abapGit shape, MEMORY M-04/M-14), the T-codes and TMG (never serialised),
any OData exposure, text joins (country name, company name) in the view, admin fields, a link
field to the bank revaluation objects.
