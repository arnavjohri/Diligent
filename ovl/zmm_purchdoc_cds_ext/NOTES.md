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

## Chains per document (read off the TR by naming convention — confirm the order in ADT)

A view exposes only what its data source carries, so a new custom field is added at **every**
level, bottom (the view that selects from the table) to top (the consumption view the app's
OData service exposes), and activated in that order. Extending only the top view fails with
"element … not found in data source". Bottom-up order below is **presumed** from the names;
confirm it by opening each top view in ADT and following `as projection on` / `select from`
downwards until the table appears.

| Document | Table | Bottom → top (standard view behind each `Z…_EXT`) | Final extension |
|---|---|---|---|
| PO header | EKKO | `I_PurchaseOrder` → `R_PurchasingDocument` → `R_PurchaseOrder` → `I_PurchaseOrderTP` → `C_PurchaseOrderTP` | `ZC_PURCHASEORDERTP_EXT` |
| PO item | EKPO | `I_PurchaseOrderItem` → `R_PurchasingDocumentItem` → `R_PurchaseOrderItem` → `I_PurchaseOrderItemTP` → `C_PurchaseOrderItemTP` | `ZC_PURCHASEORDERITEMTP_EXT` |
| PR item | EBAN | `I_PurchaseReqnItemBasic` → `I_PurchaseRequisitionItem` → `P_PurchaseReqnItem` → `T_PurchaseReqnItem` → `R_PurchaseReqnItem` → `C_PurchaseReqnItem` | `ZC_PURCHASEREQNITEM_EXT` |
| Contract header | EKKO | `I_PurchaseContractWD` / `I_PurchaseContractVersion` → `R_PurchaseContract` → `C_ContractMaintain` | `ZC_CONTRACTMAINTAIN_EXT` |
| Contract item | EKPO | `I_PurchaseContractItem` → `I_PurchaseContractItemWD` → `R_PurchaseContractItem` → `C_ContractMaintainItem` | `ZC_CONTRACTMAINTAINITEM_EXT` |

`ZI_PURCHASEORDER`, `ZI_PURCHASEORDERITEM`, `ZR_PURCHASINGDOCUMENT`, `ZR_PURCHASINGDOCUMENTITEM`
have no `_EXT` suffix: which standard view each extends, and whether the `_EXT` twin on
`R_PurchasingDocument(Item)` is a second extension or a replacement, is only visible in the
source. PR header (`EBAN` has none; `C_PurchaseRequisition…`) is not in the TR.

Syntax differs by level: a classic `extend view` references the field through the base view's
alias (`<alias>.zzfield`); an `extend view entity` on a projection (`C_…TP`, `R_…`) lists the
element name as exposed by the view underneath, and carries the `@UI.*` annotations on the
top level. Field shown read-only is CDS only; input-ready in a RAP app needs the behavior
definition extended as well (not in this TR).

## On file (19/10/26)

- `original/ZC_PURCHASEORDERTP_EXT.ddls.asddls` — the final EKKO extension as supplied: classic
  `extend view C_PurchaseOrderTP with ZC_PurchaseOrderTP_EXT`, SQL append `ZCPURORDTP`, alias of
  the base view `PurchaseOrderTP`, 84 elements, all straight pass-throughs of `zz*` / `z*` fields
  the base view already carries (so the chain below it is complete for these 84).
- `original/ZSTR_HEADER_SE11_p1..p5_2026-10-19.png` — structure `ZSTR_HEADER` (*Structure For
  Header Part of PO*, 83 components). Transcribed and reconciled in `ZSTR_HEADER_vs_view.md`.

Reconciliation: structure = 4 standard (`EBELN MATKL PLIFZ WEBAZ`) + 79 custom; **all 79 are in
the view**. The view has 5 more, straight from the EKKO append: `ZZUSR`, `ZZFLAG_KOL`,
`ZZFLAG_MUM`, `ZZFLAG_CHEN`, `ZZFLAG_DEL`. Nothing is missing from the extension.

What is missing is the **screen**: only 12 of the 84 elements carry `@UI.identification`
(positions 120–220); the other 72 reach the OData `$metadata` but no section of the object page,
which is why "all the custom fields" are not visible. Position 170 is used twice
(`ZZPORT_CON`, `ZZULT_CON`) — legal, but their order is then undefined. The 24 address fields
(`ZULT* ZINV* ZINS* ZPAY*`) inherit their labels from `AD_NAME1` / `AD_STREET` / … and would show
as four identical "Name 1 / Street / Street 2 / City / …" blocks unless `@EndUserText.label` is
set per element in the extension.

Smallest fix, in this one object: `@UI.identification` on every element, positions continuing
from 230 in structure order, 170 → 175 for `ZZULT_CON`, explicit labels on the 24 address fields.
`@UI.lineItem` as well if they must be columns of the list, not only on the object page.
A separate section per group (Tender / Award / Contacts / Addresses) needs `@UI.facet`, an
entity-level annotation an `extend view` cannot add — that would need a DDLX on
`C_PurchaseOrderTP`, which only works if the view carries `@Metadata.allowExtensions: true`
(not confirmed; `C_FixedAssetWorklist` did not — see `ovl/f1592_asset_worklist/`).

## Fiori value help for ZZNAT_PROC (Tender Process) — 19/10/26

GUI F4 is `MODULE pop_up` (PROCESS ON VALUE-REQUEST): `ZNAT_PROC` where `STATUS = 'active'`,
code + description, sorted by `SERIAL_NO`, shown with `F4IF_INT_TABLE_VALUE_REQUEST`. The Fiori
equivalent is OData-only, no UI5:

1. `ZI_NAT_PROC_VH.ddls.asddls` (this folder) — value help view, same rows, key + text.
   `@ObjectModel.resultSet.sizeCategory: #XS` makes Fiori render a dropdown instead of a
   dialog; drop the line if a dialog is wanted.
2. In `ZC_PURCHASEORDERTP_EXT`, on `zznat_proc`:
   `@Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_NAT_PROC_VH', element: 'zznat_proc' } }]`
   — to be added **after** the 230–260 change is activated, as the next change to that object.
3. The service must expose `ZI_NAT_PROC_VH` as an entity set. SADL-based services do that on
   their own; a RAP service definition does not — check `$metadata` for the entity set and the
   `Common.ValueList` annotation on `zznat_proc`. If missing and the app runs on an SAP service
   definition, the route is a service definition extension (`extend service … with { expose … }`),
   release-dependent, to be confirmed on the system.

Caveats: the F4 only matters where the field is input-ready in the app (CDS alone is display).
The GUI's `SERIAL_NO` order is not a value-help contract in Fiori — `serial_no` is exposed as a
column so users can sort on it. `@Semantics.text` is used here on a classic `define view`, where
it is allowed; it is the view-entity form that fails on this release (MEMORY §4.1).

## One value help for all fixed-value domains — 21/10/26

Arnav confirmed in SE11 that several customer-data fields get their GUI F4 from the fixed
values of their domain (Inspection Type is the one seen in the popup: `1 Source Inspection`,
`2 Destination Inspection`). The copy of `ZC_PURCHASEORDERTP_EXT` he pasted on 21/10/26 is
byte-identical to `original/`, so the 19/10 change (positions 230–260) is **not active yet**;
all value-help annotations go into that one re-paste.

**Zero-object route first.** The OData runtime derives a fixed-value list from the domain on
its own. Check `$metadata` for `sap:value-list="fixed-values"` (OData V2) or
`Common.ValueListWithFixedValues` (V4) on `zzinsp_typ`. Present → nothing to build for these
fields. Absent only on the custom fields → a `cast` somewhere in the five-layer chain dropped
the data element; the lower extension sources are then needed. Absent everywhere → fallback:

`ZI_DOM_FIXVAL_VH.ddls.asddls` (this folder) — **one** value help over `DD07T` for all of
them: keys `DomainName` + `DomainValue`, text `DomainValueText`, `ValuePosition`, filtered to
the logon language and the active version. Each element restricts it to its own domain in
the annotation, so there is one view instead of one per domain:

    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_DOM_FIXVAL_VH', element: 'DomainValue' },
                                         additionalBinding: [{ element: 'DomainName',
                                                               localConstant: 'ZINSP_TYP',
                                                               usage: #FILTER }] }]

Risks, to be tested on the first field before annotating the rest:

1. `additionalBinding.localConstant` is release-dependent. If activation reports
   `Annotation 'Consumption.valueHelpDefinition.additionalBinding.localConstant' unknown`, the
   fallback is one view per domain: the same source with `where domname = 'ZINSP_TYP'` added
   and `DomainName` dropped from the keys.
2. Older SAPUI5 may not apply the constant filter when it renders the `#XS` dropdown, so the
   list would show every domain's values. Then remove `@ObjectModel.resultSet.sizeCategory: #XS`
   — the value help dialog applies the filter and matches the GUI popup anyway.
3. The view must be an entity set of the service, same as `ZI_NAT_PROC_VH` (see above).
4. `DomainValue` is CHAR 10 against CHAR 2/3 and NUMC 3 elements. ADT warns, activation is
   fine. For NUMC domains the fixed values must carry leading zeros in SE11.

Not for this view: fields whose GUI F4 comes from a check table, a search help or a
`PROCESS ON VALUE-REQUEST` module. Those keep one value-help view each over their table.

## The consumer is the standard service — 22/10/26

Gateway Client screenshot (22/10/26): the app calls **`MM_PUR_PO_MAINT_V2_SRV`**, SAP's own
service behind Manage Purchase Orders, host `vhovlocdci.sap.ongcvidesh.in:44300`, OCQ 500.
The service document lists no `ZI_DOM_FIXVAL_VH` collection (search 0/0), so the value-help
annotation on `zzinsp_typ` is dropped by the runtime and the app shows the bare
"Define Conditions" dialog. **The CDS side is complete; the blocker is service exposure.**

Why the zz fields themselves show up but the value help does not: a referenced-data-source
service takes the *properties* of the referenced view at runtime (extension fields appear
without regeneration), but its *entity sets* are fixed when the project is generated. A new
value-help entity therefore never enters a standard service through a CDS annotation alone.

Routes, to be decided once the project type and the app's ownership are known:

| Finding | Route |
|---|---|
| SEGW project `MM_PUR_PO_MAINT_V2` exists and the app is a Z copy/extension whose `manifest.json` we own | **Redefine** into a Z SEGW project (`ZMM_PUR_PO_MAINT_V2`, Data Model → Redefine → OData Service (GW) → `MM_PUR_PO_MAINT_V2_SRV`), add `ZI_DOM_FIXVAL_VH` (and every later VH view) as a Data Source Reference entity set, generate, register, repoint the app's `mainService` to the Z service. Everything built so far works unchanged. |
| Service is a RAP service binding | `extend service … with { expose ZI_DOM_FIXVAL_VH; }` — only if ADT offers the object type "Service Definition Extension" on this release. |
| Standard app straight from the catalog, standard service, no extension object | No clean CDS/Gateway route. Options: UI extension of the standard app with a ComboBox bound to a small Z service on the VH view; or move the fields to the Custom Fields app (code list), SAP's intended way for standard apps. Both are projects, not fixes. |

Never modify `MM_PUR_PO_MAINT_V2` itself (standard object).

**Settled 22/10/26 from the source of `C_PurchaseOrderTP`** (filed as
`original/C_PURCHASEORDERTP.ddls.asddls`, 810 lines, reference only — standard object, never
edited): the view is BOPF-based (`transactionalProcessingDelegated: true`, `draftEnabled`,
actions `BOPF:COPY_PO` …). A BOPF TP view is served by a **SEGW project with referenced data
source**, so the RAP route (service definition extension) is gone. What remains: Z redefinition
of the service plus an app that calls it, a UI extension, or Custom Fields.

Why `IncotermsVersion` shows a `CollectionPath` although it has no `@Consumption.valueHelpDefinition`:
its list comes from `@ObjectModel.foreignKey.association: '_IncotermsVersion'` with the
association exposed in the select list, and SAP's project includes that target as an entity
set. Same mechanism, same precondition. SAP's own fields `PurchaseOrderType`, `PaymentTerms`,
`IncotermsClassification` use exactly the `valueHelpDefinition` + `entity` form we used on
`zzinsp_typ`; the only difference is that their targets are entity sets of the project.
An association added through `ZC_PURCHASEORDERTP_EXT` would not change that — entity sets and
navigations of a referenced-data-source project are fixed at generation, only properties are
read at runtime.

**Association test, 22/10/26 — negative.** `_ZzInspTypVH` to the VH view, exposed in the
extension exactly like `_IncotermsVersion`, activated cleanly; after cache cleanup and Load
Metadata the service document of `MM_PUR_PO_MAINT_V2_SRV` still has no `ZI_DOM_FIXVAL_VH`
collection. Confirms: the standard project's entity sets are closed. Association commented out.

**Correction, 22/10/26 evening — the app does not run on the standard service.** Arnav: the
custom tiles come from a **Z service** derived from `MM_PUR_PO_MAINT_V2_SRV`, which already
exists; the BAS app is deployed against it. So the Gateway Client test above was run against
the wrong service, and the whole "standard project is closed" analysis, while true, was beside
the point. The Z project exists; what it lacks is the new value-help entity set, for the same
reason: entity sets of a SEGW project are fixed when it is generated, and `ZI_DOM_FIXVAL_VH`
was created afterwards. The zz properties come through at runtime; the entity set does not.

**Fix = step 3 below applied to the existing Z project**, then regenerate, Load Metadata, cache
cleanups, test on the **Z** service. Z service / project name still to be read from the BAS
app's `manifest.json` (`sap.app.dataSources.mainService.uri`) or `/IWFND/MAINT_SERVICE` (`Z*`).

## Route decided: Z redefinition + repoint of the BAS app — 22/10/26 (project already exists; only step 3 onwards applies)

Backend, SEGW (manual, no paste object):

1. SEGW → Create Project `ZMM_PUR_PO_MAINT_V2`, own package, TR.
2. Data Model → right-click → **Redefine → OData Service (GW)** → technical service
   `MM_PUR_PO_MAINT_V2_SRV`, version 1 → next → tick **all** artifacts (entity types, sets,
   associations, function imports, complex types) → Finish. The generated `*_DPC_EXT` inherits
   SAP's `CL_MM_PUR_PO_MAINT_V2_DPC_EXT`, so BOPF, draft, actions and the SADL exits keep working.
3. Data Model → right-click → **Reference → Data Source** → CDS view `ZI_DOM_FIXVAL_VH` → tick
   the entity, no associations → Finish. Repeat later for every further value-help view.
   Plan B if SEGW refuses a data-source reference inside a redefined project: Import → DDIC
   Structure on the SQL view `ZIDOMFIXVALVH` and a 5-line `GET_ENTITYSET` in the DPC_EXT.
4. Generate Runtime Objects.
5. `/IWFND/MAINT_SERVICE` → Add Service → alias LOCAL → `ZMM_PUR_PO_MAINT_V2_SRV` → Add, activate
   the ICF node.
6. Gateway Client on the Z service: service document lists `ZI_DOM_FIXVAL_VH`; `$metadata` has
   `Common.ValueList` on `zzinsp_typ` with `CollectionPath="ZI_DOM_FIXVAL_VH"`;
   `ZI_DOM_FIXVAL_VH?$format=json` returns the two rows.

Front end, BAS:

- Adaptation project (app variant of Manage Purchase Orders): **Replace OData Service** →
  `/sap/opu/odata/sap/ZMM_PUR_PO_MAINT_V2_SRV/` → deploy.
- Generated FE / freestyle app: `manifest.json` → `sap.app.dataSources.mainService.uri` →
  `/sap/opu/odata/sap/ZMM_PUR_PO_MAINT_V2_SRV/` → deploy.

**Risk to check before building:** if the manifest also lists an annotation data source
`…MM_PUR_PO_MAINT_V2_ANNO_MDL…` (catalog service URI), those annotations are keyed to the SAP
schema namespace and will not match the Z service's namespace. They must then be re-created
for the Z service (SEGW, Annotation Model for Referenced Service) or the UI facets they carry
re-declared locally. CDS-derived annotations are unaffected — they come inline with the Z
service's own `$metadata`.

The upgrade-safe pairing for the redefinition route: SEGW Redefine → `ZMM_PUR_PO_MAINT_V2_SRV`,
then an **adaptation project / app variant** of Manage Purchase Orders with "Replace OData
Service" pointing at the Z service. If the "custom PO app" already is such a variant with its
own tile, only that one step is missing.

## Not in the repo yet

- **The 26 sources.** Only the names are known. Nothing can be changed, reviewed or
  re-shipped until they are filed under `original/` (one `<NAME>.ddls.asddls` each).
  `ZR_PROG_DOWNLOAD` covers programs, FGs and classes, not DDLS — copy each source from
  ADT (open the DDL source, Ctrl+A, Ctrl+C) into `incoming/`, or supply the DDL source
  table rows (`DDDDLSRC`, field `SOURCE`, one row per object).
- **Which custom fields** the other 25 extensions expose (PO header is now known: 84 `zz*`/`z*`
  fields of the EKKO append, classic CI append, not Custom Fields app).
- **The consumer** for PO: known since 22/10/26 — `MM_PUR_PO_MAINT_V2_SRV` (standard). Project type (SEGW
  vs service binding) and whether the app is a Z copy still to be confirmed. PR / contract consumers unknown.
- **Transport status**: released or not, and which systems it has reached.

## How it ships

Already in the system under `OCQK901357`; nothing to ship today. Any future change is
**paste into ADT** (DDL source editor), one object at a time, activated in stack order:
`I_` extensions before `C_` extensions, `R_`/`P_`/`T_` extensions before the views that
read them. Do not hand-write abapGit XML for these (see CLAUDE.md — it has not imported on
this landscape).

## Gotchas

- `ZI_DOM_FIXVAL_VH` (and every per-domain copy of it) activates with two warnings:
  *Key Definitions of ZI_DOM_FIXVAL_VH and DD07T are different, VALPOS / AS4VERS is missing in
  key*. Expected and harmless: the view keys on `domname` + `domvalue_l` while DD07T keys on
  `VALPOS` and `AS4VERS` as well, and the compiler cannot prove uniqueness. With the WHERE on
  one domain, the logon language and the active version, a fixed value occurs once, so the
  OData key (DomainName, DomainValue) is unique. Leave as is — putting `valpos`/`as4vers` into
  the key would only widen the OData key of a value help for nothing.

- Extending a standard view adds only fields on data sources the view already reads; a
  field from a table the base view does not join needs an association in the extension
  (the F1592 custodian case in `ovl/f1592_asset_worklist/`, branch
  `claude/standard-field-cds-extend-d8xpij`, is the worked example).
- `C_…TP` / `R_…` views back RAP transactional apps. Extending them exposes the field for
  display; making it editable in the app needs the behavior definition extended as well,
  which is a separate object type (BDEF extension) and is not in this TR.
- After any reactivation: `/IWBEP/CACHE_CLEANUP`, `/IWFND/CACHE_CLEANUP`,
  `/UI2/INVALIDATE_CLIENT_CACHES`, then check `$metadata` before touching the UI.
