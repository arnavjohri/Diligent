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
