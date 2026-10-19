# ovl/zmm_purchdoc_cds_ext — CDS extensions for custom fields on PO / PR / Purchase Contract

**Client:** OVL · **Author tag:** `SAP_ABAP` · **Filed:** 19/10/26 from an SE09 screenshot.

## What it is

Custom fields on the purchasing documents (EKKO / EKPO level — purchase order, purchase
requisition, purchase contract) are surfaced to Fiori through a set of CDS view extensions,
one per standard view in the stack, so the fields show in a Fiori tile. 26 DDL sources,
all in one transport:

| TR | Owner | Description |
|---|---|---|
| `OCQK901357` | SAP_ABAP | Extenstion of EKKO and EKPO CDS Views *(sic, as typed in SE09)* |
| `OCQK901358` | SAP_ABAP | task — Development/Correction, object type DDLS (Data Definition Language Source) |

Screenshot of the TR as supplied: `original/OCQK901357_SE09_2026-10-19.png`.

## Objects in OCQK901358

The "presumed base" column is the name with the `Z` prefix and `_EXT` suffix removed. It is
a naming-convention guess, **not confirmed** — read the `extend view` line of each source
before relying on it. Four objects carry no `_EXT` suffix; whether they are extensions or
own views is unknown until the source is seen.

| # | Object | Area | Presumed base view (unconfirmed) |
|---|---|---|---|
| 1 | `ZC_CONTRACTMAINTAINITEM_EXT` | PC | `C_ContractMaintainItem` |
| 2 | `ZC_CONTRACTMAINTAIN_EXT` | PC | `C_ContractMaintain` |
| 3 | `ZC_PURCHASEORDERITEMTP_EXT` | PO | `C_PurchaseOrderItemTP` |
| 4 | `ZC_PURCHASEORDERTP_EXT` | PO | `C_PurchaseOrderTP` |
| 5 | `ZC_PURCHASEREQNITEM_EXT` | PR | `C_PurchaseReqnItem` |
| 6 | `ZI_PURCHASECONTRACTITEMWD_EXT` | PC | `I_PurchaseContractItemWD` |
| 7 | `ZI_PURCHASECONTRACTITEM_EXT` | PC | `I_PurchaseContractItem` |
| 8 | `ZI_PURCHASECONTRACTVERSION_EXT` | PC | `I_PurchaseContractVersion` |
| 9 | `ZI_PURCHASECONTRACTWD_EXT` | PC | `I_PurchaseContractWD` |
| 10 | `ZI_PURCHASEORDER` | PO | no `_EXT` — extension or own view? |
| 11 | `ZI_PURCHASEORDERITEM` | PO | no `_EXT` — extension or own view? |
| 12 | `ZI_PURCHASEORDERITEMTP_EXT` | PO | `I_PurchaseOrderItemTP` |
| 13 | `ZI_PURCHASEORDERTP_EXT` | PO | `I_PurchaseOrderTP` |
| 14 | `ZI_PURCHASEREQNITEMBASIC_EXT` | PR | `I_PurchaseReqnItemBasic` |
| 15 | `ZI_PURCHASEREQUISITIONITEM_EXT` | PR | `I_PurchaseRequisitionItem` |
| 16 | `ZP_PURCHASEREQNITEM_EXT` | PR | `P_PurchaseReqnItem` |
| 17 | `ZR_PURCHASECONTRACTITEM_EXT` | PC | `R_PurchaseContractItem` |
| 18 | `ZR_PURCHASECONTRACT_EXT` | PC | `R_PurchaseContract` |
| 19 | `ZR_PURCHASEORDERITEM_EXT` | PO | `R_PurchaseOrderItem` |
| 20 | `ZR_PURCHASEORDER_EXT` | PO | `R_PurchaseOrder` |
| 21 | `ZR_PURCHASEREQNITEM_EXT` | PR | `R_PurchaseReqnItem` |
| 22 | `ZR_PURCHASINGDOCUMENT` | PO/PC | no `_EXT` — extension or own view? |
| 23 | `ZR_PURCHASINGDOCUMENTITEM` | PO/PC | no `_EXT` — extension or own view? |
| 24 | `ZR_PURCHASINGDOCUMENTITEM_EXT` | PO/PC | `R_PurchasingDocumentItem` |
| 25 | `ZR_PURCHASINGDOCUMENT_EXT` | PO/PC | `R_PurchasingDocument` |
| 26 | `ZT_PURCHASEREQNITEM_EXT` | PR | `T_PurchaseReqnItem` |

PO = purchase order, PR = purchase requisition, PC = purchase contract.

## Not in the repo yet

- **The 26 sources.** Only the names are known. Nothing can be changed, reviewed or
  re-shipped until they are filed under `original/` (one `<NAME>.ddls.asddls` each).
  `ZR_PROG_DOWNLOAD` covers programs, FGs and classes, not DDLS — copy each source from
  ADT (open the DDL source, Ctrl+A, Ctrl+C) into `incoming/`, or supply the DDL source
  table rows (`DDDDLSRC`, field `SOURCE`, one row per object).
- **Which custom fields** each extension exposes (`ZZ1_…` / `ZZ…` names) and where they live
  (EKKO / EKPO appends, or Custom Fields app with the PO / PR / contract business contexts).
- **The consumer**: service definition / binding, or the standard app whose tile shows the
  fields (Manage Purchase Orders / Requisitions / Contracts, or a custom List Report).
- **Transport status**: released or not, and which systems it has reached.

## How it ships

Already in the system under `OCQK901357`; nothing to ship today. Any future change is
**paste into ADT** (DDL source editor), one object at a time, activated in stack order:
`I_` extensions before `C_` extensions, `R_`/`P_`/`T_` extensions before the views that
read them. Do not hand-write abapGit XML for these (see CLAUDE.md — it has not imported on
this landscape).

## Gotchas

- Extending a standard view adds only fields on data sources the view already reads; a
  field from a table the base view does not join needs an association in the extension
  (the F1592 custodian case in `ovl/f1592_asset_worklist/`, branch
  `claude/standard-field-cds-extend-d8xpij`, is the worked example).
- `C_…TP` / `R_…` views back RAP transactional apps. Extending them exposes the field for
  display; making it editable in the app needs the behavior definition extended as well,
  which is a separate object type (BDEF extension) and is not in this TR.
- After any reactivation: `/IWBEP/CACHE_CLEANUP`, `/IWFND/CACHE_CLEANUP`,
  `/UI2/INVALIDATE_CLIENT_CACHES`, then check `$metadata` before touching the UI.
