# OVL — Group Reporting journal item API (`API_CNSLDTNGRPJRNLITEM`)

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

**How ACDOCU is written on OVL, therefore:** company code data via Data Monitor task
"Release Universal Journal" (ACDOCA -> ACDOCU, posting level 00); consolidation adjustments
via Fiori "Post Group Journal Entries" / "Import Group Journal Entries"; automatic tasks
(currency translation, eliminations) by the monitor. Programmatic posting would mean
unreleased SAP classes behind the Fiori app - flag to Gaurav as a risk before building.

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

Still to paste: parameters of `CREATE...`, `POST`, `POST_TES...`; the header/item types they
use; full names and parameters of `SELECT_DOC...`/`DELETE_D...`; one standard caller of
`GET_FACTORY` (where-used list) as the example — `CL_FINCS_UPLOAD_POSTING` is a candidate.
