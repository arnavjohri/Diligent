# OVL — Group Reporting journal item API (`API_CNSLDTNGRPJRNLITEM`)

**Outcome 22/10/26:** posting wrapper built as `ovl/zcl_gr_je_post/` on the Data Monitor engine.
This file is the research trail.

Status 22/10/26: service active on the OVL system, metadata read. Requirement not yet
stated (who consumes it, read or post, which hierarchy/version values). Nothing built.

## What it is

OData V2, CDS binding, **read only**, analytical (`sap:semantics="aggregate"`): group journal
entry line items from `ACDOCU`. Entity sets `CnsldtnGrpJrnlItem` (parameters) and
`CnsldtnGrpJrnlItemResults` (data). `creatable/updatable/deletable = false` on both; Insert
and Update restrictions false. It cannot create group journal entries.

Also registered on the system, both read: `API_CNSLDTNADHOCITEM`, `API_CNSLDTNADHOCSET`.

**Backend catalogue checked 22/10/26** (`/IWFND/MAINT_SERVICE`, Add Service, alias LOCAL,
`*CNSLDTN*`): only two more services exist, `API_CNSLDTNRLBSDGRPJRNLITM` (released group
journal items, read) and `UI_RFM_POCNSLDTNRULE` (procurement, unrelated). The posting
service `API_CNSLDTNGRPJRNLENTR` does **not** exist on this release. There is no released
OData API to create group journal entries here.

Second pass 22/10/26, `API_GR*`: only Grants Management (`API_GRANT`, `API_GRANTCORE`,
`API_GRANTCOREHIERARCHY`, `API_GRANTHIERARCHY`). Already registered as
`ZAPI_GRTRANSACTIONDATA_SRV`: `API_GRTRANSACTIONDATA_SRV` "Transaction Data for Group
Reporting - Read", the `ACDOCU` read API for data collection / analytics, no posting.
Catalogue exhausted: **no OData service on this release posts group journal entries.**

The hub artifact `sap-vdm-sot-CnsldtnGroupJournalEntry-v1` is an SAP Object Type
catalogue page (object model plus the list of its APIs), not a callable service; the
posting API it lists is `API_CNSLDTNGRPJRNLENTR`, S/4HANA 2022 and later.

**How ACDOCU is written on OVL, therefore:** company code data via Data Monitor task
"Release Universal Journal" (ACDOCA -> ACDOCU, posting level 00); consolidation adjustments
via Fiori "Post Group Journal Entries" / "Import Group Journal Entries"; automatic tasks
(currency translation, eliminations) by the monitor. Programmatic posting would mean
unreleased SAP classes behind the Fiori app - flag to Gaurav as a risk before building.

## Decision 22/10/26: team wants `API_CNSLDTNGRPJRNLENTR` (post)

Released OData V2 API, S/4HANA 2022 on-premise and later, posts and simulates group
journal entries (simulation flag 'X' per SAP's PaPM integration blog). Not found in the
OVL backend catalogue on 22/10/26, so step 1 is to prove it exists on the target system
(`/IWFND/MAINT_SERVICE` Add Service, `API_CNSLDTNGRPJRNLENTR*`; System -> Status for the
product version). Entity set, navigation and property names are to be read from
`$metadata` on the system, not assumed. Steps given in chat 22/10/26; caller (ECC program
vs. BAdI) still to be confirmed.

## UI services found 22/10/26 (already registered)

`FINCS_JRNLENTR_POST_SRV` "Consolidation Journal Entry Post" (`ZFINCS_JRNLENTR_POST_SRV`)
and `FINCS_JRNLENTR_LIST_SRV` "Group Journal Entry List". These are the OData services of
the Fiori apps Post / Display Group Journal Entries: BOPF, draft-based, the Post button
runs `CL_FINCS_JE_POST->EXECUTE`. Technically callable over HTTP (token, create draft
header, create items, function import to post), but a UI service, not a released API: no
interface stability across upgrades, no support for A2X use. From inside S/4 (the BAdI) it
is the wrong layer; the engine behind it is `CL_FINCS_DP_DOCUMENT_POST`. From ECC an
RFC-enabled FM in S/4 wrapping the engine is simpler and more stable than driving a
draft UI service. If the team still wants it, Gaurav signs off on the upgrade risk.

## Mandatory parameters (all four, every call)

| Parameter | Meaning |
|---|---|
| `P_ConsolidationUnitHierarchy` | consolidation unit hierarchy ID |
| `P_ConsolidationPrftCtrHier` | profit centre hierarchy ID |
| `P_ConsolidationSegmentHier` | segment hierarchy ID |
| `P_KeyDate` | key date (`datetime'YYYY-MM-DDT00:00:00'`) |

Values come from the Group Reporting team. Untested whether empty strings are accepted.

## Call pattern

```
/sap/opu/odata/sap/API_CNSLDTNGRPJRNLITEM/CnsldtnGrpJrnlItem(P_ConsolidationUnitHierarchy='<H1>',P_ConsolidationPrftCtrHier='<H2>',P_ConsolidationSegmentHier='<H3>',P_KeyDate=datetime'2026-10-22T00:00:00')/Results?$select=ConsolidationUnit,FinancialStatementItem,FiscalYear,FiscalPeriod,ConsolidationVersion,AmountInGroupCurrency,GroupCurrency&$filter=FiscalYear eq '2026' and ConsolidationVersion eq '<V>'&$top=20&$format=json
```

- `$select` = grouping: measures are summed over the selected dimensions.
- Measures (`AmountInTransactionCurrency`, `AmountInLocalCurrency`, `AmountInGroupCurrency`,
  `CnsldtnQuantityInBaseUnit`) and `ID` are not filterable; every other property is.
- Key dimensions worth knowing: `ConsolidationUnit`, `ConsolidationGroup`,
  `ConsolidationVersion`, `FiscalYear`, `FiscalPeriod`, `FinancialStatementItem`,
  `ConsolidationDocumentType`, `PostingLevel`, `CnsldtnGroupJrnlEntry` (document number),
  `CnsldtnGroupJrnlEntryItem`, `PartnerConsolidationUnit`, `SubItem`, `CompanyCode`,
  `GLAccount`, `ProfitCenter`, `Segment`, `Customer`, `Supplier`.
- Test in `/IWFND/GW_CLIENT`; authorisation for the service via its role.

## From ABAP in the same system

Do not call the OData. Read the underlying CDS view (name via `/IWBEP/REG_SERVICE` or the
model of the service) with the same parameters.

## Open

1. Requirement: consumer, read vs post, fields and filters needed.
2. Hierarchy IDs, key date and consolidation version in use.
3. If posting by program is wanted: decision on building on unreleased classes (not
   recommended), or the file for "Import Group Journal Entries" as the deliverable instead.

## Posting from ABAP — classes found 22/10/26 (SE24 on the OVL system)

Context: a custom Data Monitor task (`CXCD`, BAdI `FINCS_CUST_DATAMON`,
`IF_BADI_FINCS_CUST_DATAMON~EXECUTE`) that must post into `ACDOCU`.

| Class | Verdict |
|---|---|
| `CL_FINCS_JE_POST` "Post Journal Entry from External" | **Not usable.** Its only method is `EXECUTE` with the BOPF action signature (`IS_CTX /BOBF/S_FRW_CTX_ACT`, `IT_KEY`, `IO_READ`, `IO_MODIFY`, `EO_MESSAGE`...). It is the action behind the Fiori "Post Group Journal Entries" app and runs only through the BOPF service manager of that business object. |
| `CL_FINCS_DP_DOCUMENT_POST` "Posting of documents" | **The posting engine.** Public via interface `IF_FINCS_DP_DOCUMENT_POST`: `POST` ("Post into acdocu"), `POST_DEL...` ("Post into delta table", not ours), `POST_TES...` (test run, no update), `POST_REV...` ("Post a reversal document"). Private: `CHECK_HEAD`, `POST_DOCUMENT`, `POST_ACDOCU`, `POST_ACDOCU_DELTA`, `POST_TEST_RUN`, `HANDLE_DATABASE_ERRORS`, `MAINTAIN_VERSION_RELATION`, `CREATE_REVERSAL_DOCUMENT`. |
| `CL_FINCS_DP_DOCUMENT_POST_FAC` | **Factory.** `GET_FACTORY` (static, public) and `IF_FINCS_DP_DOCUMENT_POST_FAC~CREATE...` (instance). This is how an instance of the engine is obtained. |
| `CL_FINCS_DOCUMENT_REFRESH` "Delete documents of previous task execution" | **Needed for re-runs.** Interface `IF_FINCS_DOCUMENT_REFRESH`: `SELECT_DOC...` ("Select documents from previous run"), `DELETE_D...`, `SELECT_A...`, `UPDATE_O...`, `REVERSE_...`. Private methods show the rule: current-version documents are deleted, documents of an underlying version are reversed. A posting task without this doubles its amounts on every re-run. |

None of these is a released API; they are the engine the standard monitor tasks use.
Call shape expected (signatures still to be confirmed from SE24):

    cl_fincs_dp_document_post_fac=>get_factory( )->if_fincs_dp_document_post_fac~create...( )
      -> if_fincs_dp_document_post~post / post_test...

### Signatures confirmed 22/10/26 (SE24 screenshots)

`IF_FINCS_DP_DOCUMENT_POST_FAC~CREATE` — no parameters, `RETURNING ro_instance TYPE REF TO
if_fincs_dp_document_post`. Interface methods: `POST` (into ACDOCU), `POST_DELTA` (delta
table), `POST_TEST_RUN`, `POST_REVERSAL`.

`IF_FINCS_DP_DOCUMENT_POST~POST`:

| Parameter | Type | Opt |
|---|---|---|
| `IV_RUNID` | `FINCS_RUNID` | no |
| `IV_DRAFT` | `FINCS_DRAFT` | no |
| `IS_CONTROL` | `FINCS_S_DOCUMENT_CONTROL_POST` | yes |
| `IS_HEAD` | `FINCS_S_DOCUMENT_HEAD_POST` | no |
| `IT_DOCUMENT` | `FC05_T_PDOC_S4H_QFLE` | no |
| `IO_MESSAGE_HANDLER` | `REF TO IF_FINCS_TE_MESSAGE_HANDLER` | no |

Everything the engine needs goes on `POST`; no task context in the factory call.

`IF_FINCS_DOCUMENT_REFRESH~SELECT_DOCUMENTS` (documents of the previous run): mandatory
`IV_SELECTION_MODE FC05_DR_TYPE`, `IV_DIMEN FC_DIMEN`, `IV_ITCLG FC_ITCLG`, `IV_RVERS
FC_RVERS`, `IV_RYEAR FC_RYEAR`, `IV_PERID FC_PERID`; optional `IV_RRCTY RRCTY` (default
`FC00_C_RRCTY_ACT`), `IV_DOCTY FC_DOCTY`, `IV_DOCCT DOCCT` (default `FC00_C_DOCCT_CONS`),
`IV_CONGR FC_CONGR`, `IT_CU FC05_T_DR_CU`, `IT_CU_PCU FC05_T_DR_CU_PCU`, `IT_CG_INV
FC05_T_DR_CG_INV`, `IS_INV FC05_S_DR_INV`, `IS_PAIR_LOCK FC02_S_PAIR_LOCK`, `IT_RA_RTFLG
TY_T_RA_RTFLG`, `IV_RESTRICT_CU FC_BUNIT`, `IV_RLDNR FC_RLDNR`; exporting `ET_DOCUMENT`,
`ET_DOCUMENT_ND`, `ET_DOCUMENT_OP`, `ET_DOCUMENT_FULL`, `ET_DOCUMENT_ND_FULL` (interface
types, names truncated in the screenshot). Selection is by document type, not by task: the
task's document type is the link to its previous run.

Fiori app path, confirmed 22/10/26 from `CL_FINCS_JE_POST->/BOBF/IF_FRW_ACTION~EXECUTE`:
`cl_fincs_je_factory=>get_je_draft_post( )->process_draft( io_read it_draft_key io_modify
-> eo_message et_failed_draft_key et_active_je )`, then deletes the draft node
`if_i_cnsldtnjrnlentrytp1_c=>sc_node-i_cnsldtnjrnlentrytp`. `CL_FINCS_JE_FACTORY` hands out
the journal-entry service layer; the service below `PROCESS_DRAFT` that takes plain header
and items (after the draft read) is the candidate entry point above the DP engine, because
it carries the app's checks (balance, FS item validity, posting level from document type).
`PROCESS_DRAFT` (seen 22/10/26): reads the draft via `cl_fincs_je_factory=>get_multigp_draft( )
->get_base( )->init_draft_by_header( )`, then `dispatch_post( )` (or `reverse( )`), working on
member tables `mt_journalentry_header` / `mt_journalentry_items` and a save service
`lcl_factory=>get_doc_save( )`. Test run = `iv_is_testrun`, before-save status from
`cl_fincs_journalentry_util=>cons_before_save_type_s/_p`. It also uses
`cl_fincs_je_api_factory=>get( )->create_je_workflow( ) / create_log_handler( )`: an API
factory exists on this release and is the best candidate for a plain-data posting service.
`CL_FINCS_JE_FACTORY` methods (seen 22/10/26, all static public): GET_RULE_PROVIDER,
GET_SV_TRACER_REPO, GET_SV_COI_TRACER_REPO, GET_SV_ENGINE, GET_SV_ENGINE_CLIENT,
GET_JE_RULE_BOPF_CONV, GET_FINCS_JE_ATTACHMENT, GET_JE_FIELD_DESC, GET_SV_REPOSITORY,
GET_MULTIGC_DRAFT, GET_VERSION_ACCESS, GET_JE_DRAFT_POST, GET_JE_DRAFT_PREPARE,
GET_IJE_EPU_TEMPLATE, GET_EXTBLT_FIELD_DESC, GET_DOCTY_ACCESS, GET_IJE_MULTIGC_PREPARE,
GET_JE_DRAFT_HANDLER, GET_IJE_CREATE_DRAFT, GET_UUID_GENERATOR, GET_JE_COI_FIELD_HANDLER,
GET_JE_LEGACY, GET_JE_ATTACHMENT, GET_IJE_EXCEL_PARSE, GET_IJE_DAO, GET_MULTIGC_ENABLE,
GET_FEATURE_DISPATCHER, GET_MULTIGP_ENABLE, GET_MULTIGP_DRAFT, CLEAR, GET_JE_DAO,
CREATE_RSTMT_ENABLE, CREATE_RSTMT_DRAFT, GET_WORKFLOW_BUFFER, GET_JE_REPLACE,
GET_DEBIT_CREDIT_STATE, GET_SV_ENGINE_CLIENT_COI, GET_SV_ENGINE_CLIENT_JE.
Draft handling throughout (IJE = import journal entry app also goes draft -> post). SV =
substitution/validation rules. The one name that could be a plain-data posting service is
`GET_JE_LEGACY`; `GET_JE_DAO` is the DB access layer.
To open next: `DISPATCH_POST` source (decisive); `GET_JE_LEGACY` returning type and that
interface's methods; `CL_FINCS_JE_API_FACTORY` methods; attribute types of
`mt_journalentry_header/items`.

Still to paste: `DELETE_D...` full name and parameters; `CL_FINCS_DP_DOCUMENT_POST`
constructor; where-used of `IF_FINCS_DP_DOCUMENT_POST~POST` (example caller); SE11 fields of
`FINCS_S_DOCUMENT_HEAD_POST`, `FINCS_S_DOCUMENT_CONTROL_POST`, line type of
`FC05_T_PDOC_S4H_QFLE`; data elements `FINCS_RUNID`, `FINCS_DRAFT`; domain `FC05_DR_TYPE`
values; `IF_FINCS_TE_MESSAGE_HANDLER` methods and implementing class; the BAdI `EXECUTE`
parameter list (screenshot lost to context compaction).

## Test data for `FINCS_JRNLENTR_POST_SRV` (22/10/26)

`ovl/cnsldtn_grpjrnl_api/testdata/FINCS_JRNLENTR_POST_SRV_TESTDATA.md`: Step 0 read-only GETs
to capture the real property names and OCQ keys, 8 data sets (TD-01..TD-08), 14 test cases
(TC-00..TC-13), plus JSON deep-insert payloads. Built from the service document only (it was
supplied from the Woodside host `s4hdevap01`, not OCQ). Property names, navigation and the post
function import are SAP standard naming, not confirmed, until `$metadata` is read (Step 0.1).
