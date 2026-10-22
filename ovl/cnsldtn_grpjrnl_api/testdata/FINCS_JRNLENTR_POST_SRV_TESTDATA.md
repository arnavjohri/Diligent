# Test data — `FINCS_JRNLENTR_POST_SRV` (Post Group Journal Entries, OData V2)

Status 22/10/26: written from the **service document only**. `$metadata` has not been read,
so every property, navigation and function-import name in §2 and in the payloads is SAP
standard naming and is marked *confirm*. Step 0 (§1) confirms them; nothing from §4 on is
run before Step 0 is done.

The service document supplied on 22/10/26 came from `s4hdevap01.saps4.np.woodside:8001`,
not from OCQ. On OCQ take the path from `/IWFND/MAINT_SERVICE` → service → *Call Browser*;
the registered name there may carry the Z prefix (`ZFINCS_JRNLENTR_POST_SRV`), the way
`API_GRTRANSACTIONDATA_SRV` is registered as `ZAPI_GRTRANSACTIONDATA_SRV`.

Base URL used below: `/sap/opu/odata/sap/FINCS_JRNLENTR_POST_SRV/`
Tool: `/IWFND/GW_CLIENT` (CSRF handled by the tool). Postman: GET with header
`X-CSRF-Token: Fetch`, reuse the returned token on every POST / DELETE.

## 0. What the service document says (certain)

| Entity set | Role in the test | Flags |
|---|---|---|
| `C_CnsldtnJrnlEntryTP` | Journal entry **header**, draft-enabled (`I_DraftAdministrativeData` is in the service) | create / update / delete / search |
| `C_CnsldtnJrnlEntryItemTP` | Journal entry **items** | create / update / delete |
| `GlobalParameterCollection` | The user's global parameters (ledger, version, year, period …) — the app prefills from these | create |
| `C_CnsldtnMnlPostDocTypeVH` | Document types allowed for manual posting | read |
| `C_CnsldtnMnlPostDocTypeAssgVH` | Document type ↔ task/version assignment | read |
| `SubItemSet` | Subitems valid for an FS item (parameterised, not pageable) | read |
| `ItemFieldControlSet` | Which item fields are mandatory / hidden per document type | read |
| `FeatureSupportSet`, `FeatureSupportUpdateSet` | Feature flags of the app | read / create |
| `MultiGCIsActiveCollection`, `RstmtIsActiveCollection` | Multi group currency active, restatement active | read / create |
| `C_CnsldtnGrpJrnlEntrWrkflw`, `C_CnsldtnGrpJrnlEntrItmWrkflw` | Workflow (approval) views — out of scope | read |
| every other `C_Cnsldtn*VH`, `I_Cnsldtn*` | Value helps and texts — the source of every key value in §3 | read |

Only the two `TP` sets, `GlobalParameterCollection`, `FeatureSupportUpdateSet` and the two
`IsActive` collections are creatable. A GET on a value help can never change anything, so
Step 0 is safe to run on any client.

## 1. Step 0 — capture live names and keys (run first, read only)

Run each GET in `/IWFND/GW_CLIENT`, `$format=json`. Paste the results into §2 and §3.

| # | URL (append to base) | What to take from it |
|---|---|---|
| 0.1 | `$metadata` | `EntityType` for `C_CnsldtnJrnlEntryTPType` and `…ItemTPType`: key properties, every property name, the `NavigationProperty` from header to items, and the `FunctionImport` list (look for `…Activation`, `…Preparation`, `…Validation`, `…Edit`, and anything with `Post` / `Revers` in the name; `sap:action-for` names the entity each one acts on) |
| 0.2 | `C_CnsldtnJrnlEntryTP?$top=5&$filter=IsActiveEntity eq true` | Shape of a posted document as the service returns it — property names with real values |
| 0.3 | `C_CnsldtnJrnlEntryItemTP?$top=10` | Same for items; shows how an item names its header key and which amount/currency pairs exist |
| 0.4 | `GlobalParameterCollection` | The calling user's current ledger / version / year / period |
| 0.5 | `C_CnsldtnLedgerVH?$top=20` | Ledger → §3 `LEDGER` |
| 0.6 | `C_CnsldtnVersionVH?$top=20` | Version → §3 `VERSION` (use a test / copy version if the GR team has one) |
| 0.7 | `C_CnsldtnChartOfAccountsVH?$top=20` | Consolidation chart of accounts → §3 `COA` |
| 0.8 | `C_CnsldtnFiscalYearVH`, `C_CnsldtnFiscalPeriodVH` | Year / period formats (`2026`, `010`) |
| 0.9 | `C_CnsldtnMnlPostDocTypeVH?$top=50` | Document types for manual posting with their posting level and currency → §3 `DT_PL01`, `DT_PL20` |
| 0.10 | `C_CnsldtnUnitValueHelp_2?$top=50` | Two consolidation units that belong to one group → §3 `CU_A`, `CU_B` |
| 0.11 | `C_CnsldtnGroupAllVH?$top=20` | The group containing both → §3 `CG` |
| 0.12 | `C_CnsldtnPartnerUnitVH?$top=50` | Confirms `CU_B` is a valid partner of `CU_A` |
| 0.13 | `C_CnsldtnFinStmntItemVH?$top=50` (add `$filter` on the chart of accounts if the service demands one) | Two balance-sheet items, one intercompany receivable, one intercompany payable, one P&L item → §3 `FSI_*` |
| 0.14 | `I_CnsldtnSubItemCategoryVH` | Subitem categories (transaction types / functional areas) |
| 0.15 | `SubItemSet` with the parameters `$metadata` shows for it | Valid subitems for each `FSI_*` chosen in 0.13 → §3 `SI_*` |
| 0.16 | `ItemFieldControlSet` (filter by document type if `$metadata` shows a parameter) | Mandatory item fields for `DT_PL01` and `DT_PL20` — anything mandatory that the payloads lack is added before TC-02 |

## 2. Name map — standard naming, every row *confirm* against 0.1

Names in the *released* read API `API_CNSLDTNGRPJRNLITEM` on OCQ were read on 22/10/26
(`ovl/cnsldtn_grpjrnl_api/NOTES.md`); where this UI service is expected to use the same
name the row says so. Nothing here is confirmed for **this** service until 0.1 is done.

| Business field | Expected property | Basis |
|---|---|---|
| Consolidation ledger | `ConsolidationLedger` | VDM naming |
| Consolidation version | `ConsolidationVersion` | same name in the released API |
| Consolidation chart of accounts | `ConsolidationChartOfAccounts` | VDM naming |
| Fiscal year / period | `FiscalYear` / `FiscalPeriod` | same names in the released API (`'2026'`, `'010'`) |
| Document type | `ConsolidationDocumentType` | same name in the released API |
| Consolidation unit (header and item) | `ConsolidationUnit` | same name in the released API |
| Consolidation group (header, group-level doc types) | `ConsolidationGroup` | same name in the released API |
| Partner unit (item) | `PartnerConsolidationUnit` | same name in the released API |
| FS item (item) | `FinancialStatementItem` | same name in the released API |
| Subitem category / subitem (item) | `SubItemCategory` / `SubItem` | `SubItem` is in the released API; category is VDM naming |
| Amount in local / group / transaction currency | `AmountInLocalCurrency` / `AmountInGroupCurrency` / `AmountInTransactionCurrency` | same names in the released API |
| Currency keys | `GroupCurrency`, `TransactionCurrency`, local-currency key **unknown** | read from 0.3 |
| Document number (returned after posting) | **unknown** — released API calls it `CnsldtnGroupJrnlEntry` | read from 0.2 |
| Header text / item text | **unknown** | read from 0.2 / 0.3 |
| Posting date, auto-reversal flag, reversal reason | **unknown** — search 0.1 for `Date` and `Revers` | optional |
| Draft control | `IsActiveEntity`, `HasActiveEntity`, `HasDraftEntity`, `DraftUUID` | standard SADL draft properties |
| Header → items navigation | **unknown** — placeholder `<NAV_TO_ITEM>` in the payloads | read from 0.1 |
| Post a draft | function import `C_CnsldtnJrnlEntryTPActivation` (standard SADL name) **or** an app-specific `Post` action | read from 0.1; the Fiori Post button runs `CL_FINCS_JE_POST->EXECUTE`, which may be exposed under its own name |

## 3. Test data values

Column *Sample* is SAP standard delivered content, so the payloads are readable and pasteable
as they stand. Column *OCQ* is filled from Step 0 and **replaces** the sample value in every
payload before anything is posted. A sample value that does not exist on OCQ fails with an
"invalid value" message, not with a wrong posting — but it still burns a cycle.

| Key | Meaning | Sample | OCQ |
|---|---|---|---|
| `LEDGER` | Consolidation ledger | `Y1` | |
| `VERSION` | Consolidation version | `Y10` | |
| `COA` | Consolidation chart of accounts | `Y1` | |
| `YEAR` / `PERIOD` | Open period whose *Manual Posting* task is not blocked in the Data Monitor | `2026` / `010` | |
| `PERIOD_CLOSED` | A period that is blocked, for the negative test | `2026` / `001` | |
| `DT_PL01` | Unit-level document type, posting level 01, local currency, balance check = error | `01` | |
| `DT_PL20` | Group-level two-sided elimination document type, posting level 20, group currency | `21` | |
| `CU_A` | Consolidation unit, has reported data in `PERIOD` | `1010` | |
| `CU_B` | Second unit in the same group, valid partner of `CU_A` | `1710` | |
| `CG` | Consolidation group containing `CU_A` and `CU_B` | `CG1` | |
| `LC_A` | Local currency of `CU_A` | `INR` | |
| `GC` | Group currency of `LEDGER` | `INR` | |
| `FSI_CASH` | Balance-sheet FS item, breakdown by subitem category 1 | `111100` | |
| `FSI_RECV` | Balance-sheet FS item, same breakdown | `113100` | |
| `FSI_IC_RECV` | Intercompany receivable, partner unit mandatory | `113200` | |
| `FSI_IC_PAY` | Intercompany payable, partner unit mandatory | `213200` | |
| `FSI_PL` | Income-statement FS item, breakdown by subitem category 2 | `411100` | |
| `SI_CAT_BS` / `SI_BS` | Subitem category and a valid movement subitem for the BS items | `1` / `915` | |
| `SI_CAT_PL` / `SI_PL` | Subitem category and a valid functional-area subitem for `FSI_PL` | `2` / `YB10` | |
| `FSI_BAD` | FS item that does not exist in `COA` | `999999` | |

Amounts are signed: debit positive, credit negative. There is no debit/credit indicator.

### Data sets

| Set | Header | Items (CU · FS item · subitem · amount · partner) | Purpose |
|---|---|---|---|
| **TD-01** | `DT_PL01`, `CU_A`, `YEAR/PERIOD` | 1: `CU_A` · `FSI_CASH` · `SI_BS` · +10000.00 `LC_A` · — <br> 2: `CU_A` · `FSI_RECV` · `SI_BS` · −10000.00 `LC_A` · — | Balanced unit-level correction in LC. The baseline positive test |
| **TD-02** | `DT_PL20`, `CG`, `YEAR/PERIOD` | 1: `CU_A` · `FSI_IC_RECV` · `SI_BS` · −5000.00 `GC` · `CU_B` <br> 2: `CU_B` · `FSI_IC_PAY` · `SI_BS` · +5000.00 `GC` · `CU_A` | Group-level elimination with partner units; balances across the two units |
| **TD-03** | as TD-01 | line 2 amount −9000.00 | Unbalanced by 1000.00 → balance check must reject |
| **TD-04** | as TD-01 | line 1 FS item `FSI_BAD` | FS item not in the chart of accounts |
| **TD-05** | as TD-01 | line 1 without `SubItemCategory` / `SubItem` | Breakdown required, not supplied |
| **TD-06** | as TD-01 but `PERIOD_CLOSED` | as TD-01 | Blocked period / task |
| **TD-07** | `DT_PL01`, `CU_A` | 1: `FSI_CASH` · `SI_BS` · +2500.00 <br> 2: `FSI_PL` · `SI_PL` · −2500.00 | P&L line; the document type's automatic net-income lines must appear |
| **TD-08** | TD-01 header + auto-reversal flag (name from 0.1) | as TD-01 | Reversal document generated in `PERIOD + 1` |

## 4. Test cases

| TC | Data | Call sequence | Expected |
|---|---|---|---|
| TC-00 | — | Step 0 | All 200. §2 and §3 filled |
| TC-01 | TD-01 header only | `POST C_CnsldtnJrnlEntryTP` (no items) | 201. Response has `IsActiveEntity=false`, a `DraftUUID`, and the header key — note it, every later call needs it |
| TC-02 | TD-01 | `POST C_CnsldtnJrnlEntryTP` deep insert, then the posting function import from 0.1 on the draft key | 201 then 200. Document number returned. Display Group Journal Entries (or SE16 `ACDOCU` by ledger/version/year/period/doc type/doc number) shows 2 lines, posting level 01, signed amounts as sent, local currency only |
| TC-03 | TD-02 | same | Posted at group level: both lines carry the partner unit, posting level 20, group `CG`, group-currency amounts |
| TC-04 | TD-03 | same | Function import returns 400 with the balance error; **no** ACDOCU rows; the draft is still there (GET with `IsActiveEntity eq false`) |
| TC-05 | TD-04 | same | 400, message names the FS item / chart of accounts |
| TC-06 | TD-05 | same | 400, message names the subitem / breakdown |
| TC-07 | TD-06 | same | 400, message names the period or the monitor task |
| TC-08 | TD-07 | same | Posted; line count > 2 — the net-income lines the document type adds are present with the net-income FS items from customizing |
| TC-09 | TD-08 | same | Two documents: the entry in `PERIOD`, its reversal in `PERIOD + 1` with the reversal document type from customizing, amounts negated |
| TC-10 | document from TC-02 | the reverse function import from 0.1, or the app's Reverse button | Reversal document in the same period, amounts negated, original marked as reversed |
| TC-11 | draft from TC-01 | `DELETE C_CnsldtnJrnlEntryTP(<draft key>,IsActiveEntity=false)` | 204; the same GET afterwards is 404 |
| TC-12 | documents from TC-02, TC-03 | `GET C_CnsldtnJrnlEntryTP?$filter=<ledger/version/year/period/doc type>&$expand=<NAV_TO_ITEM>`; `GET C_CnsldtnJrnlEntryItemTP?$filter=<header key>` | 200; rows equal what was posted |
| TC-13 | — | TC-02 with a user lacking the Post Group Journal Entries role (`SAP_BR_GROUP_ACCOUNTANT` or its OCQ copy) | 403 on the POST |

Negative cases TC-04 to TC-07 are run **after** TC-02 has proved the payload shape, so a
400 means the business check fired and not a wrong property name.

## 5. Preconditions

1. Role for Post Group Journal Entries on the test user (standard `SAP_BR_GROUP_ACCOUNTANT`).
2. Global parameters set for that user (Set Global Parameters app, or 0.4 shows them).
3. `YEAR/PERIOD` opened in the Data Monitor for `CU_A` and `CU_B`; the *Manual Posting* task
   not blocked. For TD-02 the Consolidation Monitor for `CG` as well.
4. `CU_A` has reported data in `PERIOD` (Release Universal Journal run), so the posted
   correction is visible against something in the reports.
5. Development client only. `ACDOCU` rows are not deleted — clean-up is by reversal (TC-10).

## 6. Payloads

Files in this folder, one per data set. Replace every §3 sample value and `<NAV_TO_ITEM>`
from Step 0 before use. Decimal amounts and NUMC keys are JSON **strings**.

| File | Data set |
|---|---|
| `TD01_pl01_balanced.json` | TD-01 |
| `TD02_pl20_elimination.json` | TD-02 |
| `TD03_unbalanced.json` | TD-03 |
| `TD07_pl_item.json` | TD-07 |

TD-04, TD-05, TD-06 and TD-08 are TD-01 with the one change named in §3.

Posting call after the deep insert (name from 0.1, standard SADL shape):

```
POST C_CnsldtnJrnlEntryTPActivation?<header key from the create response>&IsActiveEntity=false
```

Verification read after posting:

```
GET C_CnsldtnJrnlEntryTP?$format=json&$filter=IsActiveEntity eq true and FiscalYear eq '2026' and FiscalPeriod eq '010' and ConsolidationDocumentType eq '01'&$expand=<NAV_TO_ITEM>
```

## 7. Not covered, and why

- Workflow entity sets: approval workflow is not in the requirement.
- `FeatureSupportUpdateSet`, `MultiGCIsActiveCollection`, `RstmtIsActiveCollection` as
  targets of a POST: they switch app behaviour, not journal data.
- Posting level 30 (consolidation of investments): needs investee / activity fields
  (`C_CnsldtnInvesteeUnitVH`, `C_CnsldtnInvmtEquityActyVH`) and COI customizing that has
  not been described. Add a TD-09 once the GR team confirms it is in scope.
- Performance / volume: this service drives a UI; a volume test belongs to the import app
  or to the posting engine, not here.
