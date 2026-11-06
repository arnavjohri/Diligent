# TS — ZGR_FSITEM_MAP / ZI_GR_FSREMAP_CUBE (Group Reporting: FS item remap per consolidation unit)

## 1. Document control

| Item | Value |
|---|---|
| Version | 1.1 (1.0 on 06.11.2026 paste-only; 1.1 the same day: abapGit ZIP, Z domains, DTELs domain-based) |
| Author | Arnav Johri, Diligent Global |
| Date | 06.11.2026 |
| Project / system | OVL (assumed) · OCD 500 (ADT header of the supplied source) |
| Related FS | None — request received in chat on 06/11/2026 together with the ADT source of `I_MatrixConsolidationReportC`, filed as `ovl/zgr_fsitem_remap/original/I_MATRIXCONSOLIDATIONREPORTC.ddls.asddls` |
| Companion documents | `ASSUMPTIONS_AND_QUERIES.md` / `FSD/ZGR_FSITEM_REMAP_Assumptions_and_Queries.docx` (16 items); `NOTES.md` |
| Transport | TBD |

## 2. Purpose / background

Group Reporting wants certain FS items reported under a different FS item for certain
consolidation units, without touching the postings in ACDOCU. The mapping is business-maintained:
a table with consolidation unit, FS item and new FS item, kept in SM30. Reporting then runs on a
customer copy of the standard *Group Data Analysis* cube `I_MatrixConsolidationReportC` that has
one more column, `NewFinancialStatementItem`: the mapped item where a row exists for the line's
unit and FS item, the line's own FS item everywhere else. The original FS item column stays, so a
query can show both.

## 3. Objects affected

| Object | Type | New / changed | Package | TR |
|---|---|---|---|---|
| `ZGR_RBUNIT` (CHAR 18), `ZGR_RITEM` (CHAR 10) | Domains | New | GR package (chosen at import) | TBD |
| `ZGR_RBUNIT`, `ZGR_RITEM`, `ZGR_RITEM_NEW` | Data elements on those domains | New | same | same |
| `ZGR_FSITEM_MAP` | Transparent table | New | same | same |
| `ZI_GR_FSREMAP_CUBE` (SQL view `ZIGRFSREMAPCUBE`) | CDS DDL source, classic view, `@Analytics.dataCategory: #CUBE` | New | same | same |
| Table maintenance generator for `ZGR_FSITEM_MAP` | SE11 → Utilities → TMG, manual (function group `ZGR_FSITEM_MAP`) | New | same | same |
| Key-user release of `ZI_GR_FSREMAP_CUBE` (API State, contract C1) | ADT, manual | New | — | same |
| Custom Analytical Query + tile on `ZI_GR_FSREMAP_CUBE` | Fiori app, by the functional consultant | New | — | — |

Not touched: `I_MatrixConsolidationReportC` and everything below it (no extension, no
modification); ACDOCU; the existing GR objects in `ovl/gr_venture_release` and `ovl/zcl_gr_je_post`.

## 4. Detailed changes

Source: `ovl/zgr_fsitem_remap/src/` (8 files) and `ovl/zgr_fsitem_remap/.abapgit.xml`; archive
`ovl/zgr_fsitem_remap/ZGR_FSITEM_REMAP.zip`. Paste fallback for the table:
`ovl/zgr_fsitem_remap/ZGR_FSITEM_MAP.tabl.ddl` (ADT Database Table DDL, 41 lines).

### 4.1 Build and activation order

**Step 1 — DDIC + view by abapGit ZIP.** `ZABAPGIT_STANDALONE` → New Offline Repo → package (the
existing GR package, or a new one; the ZIP carries no `package.devc.xml`, so the package is not
touched) → Import ZIP `ZGR_FSITEM_REMAP.zip` → Pull → transport request when asked. abapGit
activates in dependency order: domains → data elements → table → `ZI_GR_FSREMAP_CUBE`. Check first
in SE11 that `ZGR_FSITEM_MAP`, `ZIGRFSREMAPCUBE`, `ZGR_RBUNIT`, `ZGR_RITEM`, `ZGR_RITEM_NEW` do not
already exist. Expected on the cube: warnings only (the standard's deprecated associations
`_CnsldtnUnit` / `_PartnerUnit` / `_InvesteeUnit` carry `@API.element.releaseState: #DEPRECATED`,
same as in the standard cube). If the pull stops on the DDLS, the DDIC is already in: open the
view in ADT, paste the error back, the fix comes back as the one file.

**Step 1 fallback — same objects, same order, by hand** (if a DDIC object does not arrive, as on
the `ZFI_TR_BANKACCT` pull of 03/11/26):

1a. SE11 → Domain: `ZGR_RBUNIT` CHAR 18, output length 18, text *Consolidation unit, 18
characters (as ACDOCU-RBUNIT)*; `ZGR_RITEM` CHAR 10, output length 10, text *FS item, 10
characters (as ACDOCU-RITEM)*. Activate both.

1b. SE11 → Data element (*Elementary type → Domain*):

| Name | Domain | Short description | Field labels short (10) / medium (20) / long (40) / heading (20) |
|---|---|---|---|
| `ZGR_RBUNIT` | `ZGR_RBUNIT` | Consolidation unit (GR FS item remap) | Cons.Unit / Cons. Unit / Consolidation Unit / Consolidation Unit |
| `ZGR_RITEM` | `ZGR_RITEM` | FS item as posted (GR FS item remap) | FS Item / FS Item / FS Item / FS Item |
| `ZGR_RITEM_NEW` | `ZGR_RITEM` | New FS item to report instead (GR FS item remap) | New Item / New FS Item / New FS Item / New FS Item |

1c. Table: ADT → New → Other → Dictionary → Database Table `ZGR_FSITEM_MAP`, replace the source
with `ZGR_FSITEM_MAP.tabl.ddl` (the `//` header lines are comments and can stay); *Technical
Settings*: data class **APPL0**, size category **0**, buffering **not allowed**, log data changes
off. Or SE11 with the field list in §4.2. Activate.

1d. ADT → New → Core Data Services → Data Definition `ZI_GR_FSREMAP_CUBE`, description *Group
Data Analysis - Cube with FS item remap*, any template; replace the whole template with
`src/zi_gr_fsremap_cube.ddls.asddls`. Activate.

**Step 2 — Table Maintenance Generator (SE11 → `ZGR_FSITEM_MAP` → Utilities → Table Maintenance
Generator).** Authorization group `&NC&` (or the GR group if one exists); function group
`ZGR_FSITEM_MAP` (new); maintenance type **one step**, overview screen 1; recording routine
**no, or user, recording routine** (delivery class A — the standard routine would prompt for a
transport on every SM30 entry, A&Q item 6). Create. Test: SM30 → `ZGR_FSITEM_MAP` → Maintain →
New Entries: columns read *Cons. Unit*, *FS Item*, *New FS Item*.

**Step 3 — Key-user release (ADT).** Right-click the DDL source `ZI_GR_FSREMAP_CUBE` → Properties
→ *API State* → Add Release State → **Use in Key User Apps (C1)**. Without it the cube is not
offered in *Custom Analytical Queries* (MEMORY §4.1; bank reval 28/10–02/11/26). Check with
`RSRTS_ODP_DIS` on `2CZIGRFSREMAPCUBE` if the app still does not list it.

**Step 4 — Query and tile.** Functional consultant, *Custom Analytical Queries* on
`ZI_GR_FSREMAP_CUBE` (search without `*`); the four parameters are prompted exactly as on the
standard cube (`$` = no hierarchy, key date = today).

**Step 5 — Mapping entries.** Group Reporting team, SM30 `ZGR_FSITEM_MAP`. Nothing changes in the
cube until rows exist.

### 4.2 Table `ZGR_FSITEM_MAP` — SE11 field list (fallback for step 1c)

Delivery class **A**; Data Browser/Table View Maint. **Display/Maintenance Allowed**; enhancement
category *Can be enhanced (character-type)*.

| Field | Key | Initial | Data element | Type | Short description |
|---|---|---|---|---|---|
| `MANDT` | X | X | `MANDT` | CLNT 3 | Client |
| `RBUNIT` | X | X | `ZGR_RBUNIT` | CHAR 18 | Consolidation unit |
| `RITEM` | X | X | `ZGR_RITEM` | CHAR 10 | FS item as posted (ACDOCU) |
| `RITEM_NEW` | — | — | `ZGR_RITEM_NEW` | CHAR 10 | FS item to report instead; blank = no mapping |

Technical settings as in step 1c.

### 4.3 CDS `ZI_GR_FSREMAP_CUBE` — what differs from the standard cube

The view is the supplied standard source re-typed as a customer object: same four parameters
(`P_ConsolidationUnitHierarchy`, `P_ConsolidationPrftCtrHier`, `P_ConsolidationSegmentHier`,
`P_KeyDate`, passed straight through), the same 111 elements in the same order with the same
annotations, 71 of its 73 associations redefined with `$projection` on the same element names.
Differences, each marked in the source:

| Where (anchor in the file) | Change |
|---|---|
| Header annotations | `@AbapCatalog.sqlViewName: 'ZIGRFSREMAPCUBE'`; `@AccessControl.authorizationCheck: #NOT_REQUIRED` (standard: `#CHECK` + DCL, A&Q 10); `@Analytics.readClassName` **not carried** (A&Q 9); `@VDM.lifecycle.*` not carried (customer object) |
| `as select from I_MatrixConsolidationReportC( … ) as JrnlEntry` | Data source is the standard cube itself, parameters passed through |
| `left outer join zgr_fsitem_map as FSItemMap` | New. `on FSItemMap.rbunit = JrnlEntry.ConsolidationUnit and FSItemMap.ritem = JrnlEntry.FinancialStatementItem`. Client by `#SESSION_VARIABLE`, not written |
| `association [0..1] to I_GroupReportingFSItem as _NewFinStmntItm` (inside `//BOC … 06/11/26`) | New. On cons chart of accounts + `$projection.NewFinancialStatementItem`. `[0..1]` because the new item may not exist |
| Element after `JrnlEntry.FinancialStatementItem` (inside `//BOC … 06/11/26`) | New: `case when FSItemMap.ritem_new is not null and FSItemMap.ritem_new <> '' then FSItemMap.ritem_new else JrnlEntry.FinancialStatementItem end as NewFinancialStatementItem`, label *New FS Item*, `@ObjectModel.foreignKey.association: '_NewFinStmntItm'` |
| Association list, after `_FinStmntItm` | `_NewFinStmntItm` exposed |
| Not carried | `_Extension` (SAP's extension hook) and `_FiscalCalendarDate` (defined but not exposed in the standard) |

The `//BOC By Arnav on 06/11/26` / `//EOC` markers enclose the three customer additions; the rest
is the standard, so a later diff against `original/` after a support package shows exactly what
SAP changed.

### 4.4 The abapGit XML

Every `src/*.xml` is the element-for-element shape of a file that has pulled on this landscape —
DOMA / DTEL / TABL as `ovl/zfi_bank_reval/src/` (OCD 28/10/26) and `kpmg/zpp_forecast_paints/src/`
(19/10/26), DDLS as the bank reval views. Only values differ. Deliberately absent: `package.devc.xml`
(package chosen at import, not rewritten), foreign keys (shape never pulled here; SE11 if wanted,
A&Q 5). Re-zip after any change: `cd ovl/zgr_fsitem_remap && rm -f ZGR_FSITEM_REMAP.zip && zip -X
ZGR_FSITEM_REMAP.zip .abapgit.xml src/*`.

## 5. Requirement mapping

| # | Requirement (chat, 06/11/2026) | Implemented by |
|---|---|---|
| R1 | A table with consolidation unit, FS item and new FS item | `ZGR_FSITEM_MAP` (keys `RBUNIT`, `RITEM`; `RITEM_NEW`), domains and data elements `ZGR_*` |
| R2 | The user maintains it | Delivery class A, maintenance allowed, TMG (step 2) → SM30 |
| R3 | Another view on top of `I_MatrixConsolidationReportC` | `ZI_GR_FSREMAP_CUBE`, data source the standard cube with its parameters passed through, every standard element carried |
| R4 | New column: the new FS item if present, else the old FS item | `NewFinancialStatementItem` — left outer join + CASE (§4.3); `_NewFinStmntItm` for key + text in the query |
| R5 | "zip file to directly upload the objects" | `ZGR_FSITEM_REMAP.zip`, abapGit offline (§4.1 step 1, §4.4) |

No requirement is unmapped. Nothing beyond R1–R5 is built (A&Q, last paragraph).

## 6. Test scenarios

| # | Input | Expected | Actual |
|---|---|---|---|
| 1 | abapGit pull of `ZGR_FSITEM_REMAP.zip` | 7 objects created and active: 2 domains, 3 data elements, table, DDL source. SE11 shows `ZGR_FSITEM_MAP` with 4 fields and `ZIGRFSREMAPCUBE` | |
| 2 | SM30 `ZGR_FSITEM_MAP`, New Entries: unit `U1`, FS item `I1`, new `I9`. Save | Row saved without a transport prompt (recording routine off). Column headings *Cons. Unit*, *FS Item*, *New FS Item* | |
| 3 | ADT Data Preview on `ZI_GR_FSREMAP_CUBE` (`$`, `$`, `$`, today); filter `ConsolidationUnit = U1`, `FinancialStatementItem = I1` | `NewFinancialStatementItem = I9` on every line; `FinancialStatementItem` still `I1` | |
| 4 | Same preview, a unit / FS item **without** a mapping row | `NewFinancialStatementItem = FinancialStatementItem` on every line (never blank, never NULL) | |
| 5 | Mapping row with blank *New FS Item* | Treated as no mapping — original FS item shown (A&Q 11) | |
| 6 | Preview row count and sum of `AmountInGroupCurrency` for one unit / version / year-period, Z cube vs. `I_MatrixConsolidationReportC` with the same four parameters | Identical — the join is left outer on a unique key, so no line is dropped or doubled | |
| 7 | Same selection in *Group Data Analysis* (standard app) vs. a CAQ on the Z cube, at posting level 00/10/20 and at group level, amounts in group currency per FS item | Identical. A difference means the standard read class adds logic the SQL does not — A&Q 9 | |
| 8 | CAQ: `NewFinancialStatementItem` as a row dimension with key + text; FS item hierarchy on it | Text from `I_GroupReportingFSItem` of the same cons chart of accounts; hierarchy offered | |
| 9 | Second row for the same unit + FS item in SM30 | Rejected — key violation (SM30 message) | |

## 7. Open points

Items 2, 3, 6, 9 and 10 of `ASSUMPTIONS_AND_QUERIES.md` need an answer before the mapping is filled
in production: key scope (dimension / cons chart of accounts), validity dates, delivery class and
transport of entries, the read-class comparison (test 7), and whether a DCL is needed. Items 4 and
5 (standard data elements, F4 / existence check in SM30) are SE11-only follow-ups that need no code
change. Items 7, 8, 13 and 16 are design confirmations. The 03/11/26 `ZFI_TR_BANKACCT` pull that
created the views but not the table is still undiagnosed; if this pull does the same, supply the
abapGit log line for the first DDIC object (not a screenshot of the whole log).
