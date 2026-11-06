# ovl/zgr_fsitem_remap — Group Reporting: FS item remap per consolidation unit

**Client:** OVL (assumed — `ASSUMPTIONS_AND_QUERIES.md` item 1) · **System:** OCD 500 (ADT header
of the supplied source) · **Filed:** 06/11/26 · **Requester:** Group Reporting team, via Arnav (chat)

## What it is

A user-maintained table (SM30) that says, per consolidation unit and FS item, which FS item is to
be reported instead — and a customer copy of the standard *Group Data Analysis* cube
`I_MatrixConsolidationReportC` with one more column, **`NewFinancialStatementItem`**: the mapped
item when the table has a row for the line's unit + FS item (and the new item is filled),
otherwise the line's own FS item. Everything else in the cube is the standard cube, element for
element, so a query built on it behaves like one built on SAP's.

| Table field | Key | Data element | Domain | Type | SM30 heading |
|---|---|---|---|---|---|
| `MANDT` | key | `MANDT` | `MANDT` | CLNT 3 | — |
| `RBUNIT` | key | `ZGR_RBUNIT` (new) | `ZGR_RBUNIT` (new) | CHAR 18 | Cons. Unit |
| `RITEM` | key | `ZGR_RITEM` (new) | `ZGR_RITEM` (new) | CHAR 10 | FS Item |
| `RITEM_NEW` | — | `ZGR_RITEM_NEW` (new) | `ZGR_RITEM` | CHAR 10 | New FS Item |

Z domains and Z data elements on purpose: the standard ACDOCU data elements are not confirmed from
here (no system access) and a wrong name costs an activation cycle; the CDS join compares by type
and length, which are the ACDOCU lengths. Item 4 of the A&Q says how to swap in the standard
elements if wanted. Domain-based (not built-in types) because the DOMA + DTEL abapGit shapes are
the ones that have pulled on this landscape.

## Objects — all in the ZIP, in the order abapGit activates them

| # | Object | Type | File in `src/` |
|---|---|---|---|
| 1 | `ZGR_RBUNIT` (CHAR 18), `ZGR_RITEM` (CHAR 10) | Domains | `zgr_rbunit.doma.xml`, `zgr_ritem.doma.xml` |
| 2 | `ZGR_RBUNIT`, `ZGR_RITEM`, `ZGR_RITEM_NEW` | Data elements | `zgr_rbunit.dtel.xml`, `zgr_ritem.dtel.xml`, `zgr_ritem_new.dtel.xml` |
| 3 | `ZGR_FSITEM_MAP` | Transparent table, delivery class A, maintenance allowed, APPL0, size 0, no buffering, enhancement cat. 1 | `zgr_fsitem_map.tabl.xml` |
| 4 | `ZI_GR_FSREMAP_CUBE` (SQL view `ZIGRFSREMAPCUBE`) | CDS DDL source, classic view, `#CUBE`, 743 lines | `zi_gr_fsremap_cube.ddls.asddls` + `.ddls.xml` |

Paste-only, not in the ZIP: **`ZGR_FSREMAP_READ`** (`ZGR_FSREMAP_READ.abap`, 234 lines, SE38). Reads
the cube with obligatory ledger / dimension / version / year / period, optional unit and FS item
ranges, hierarchy parameters defaulted to `$`, key date today; `SUM` per unit / FS item / new FS
item / period in local and group currency, `CL_SALV_TABLE` with a *Remapped* checkbox. Selection
texts are maintained by hand (SE38 → Goto → Text Elements → Selection Texts; list in ISSUES row 3).

Then by hand (never serialised): the TMG (SE11 → Utilities → Table Maintenance Generator), the
key-user release of the cube (ADT, API State, C1), and the query / tile in *Custom Analytical
Queries* (functional consultant). TS §4.1 steps 2–5.

Optional, on request: DCL inheriting the standard cube's access control (A&Q item 10); SE93
transactions on SM30 (item 16); foreign keys / search helps on the table fields (item 5).

## How it ships — abapGit ZIP `ZGR_FSITEM_REMAP.zip` (06/11/26)

`.abapgit.xml` (`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`) at the folder root; `src/` with
8 files. **No `package.devc.xml`** — the target package is chosen when the offline repo is created
(the GR objects' existing package, or a new one), and leaving the DEVC out means the import does
not rewrite that package's description. Every XML is the element-for-element shape of files that
pulled on this landscape: DOMA / DTEL / TABL as `ovl/zfi_bank_reval` (OCD, 28/10/26) and
`kpmg/zpp_forecast_paints` (19/10/26); DDLS `DDLNAME, DDLANGUAGE, DDTEXT, SOURCE_TYPE = V` as the
three bank reval views (28/10, 03/11). Values differ, elements and order do not. No foreign keys
in the XML (that shape has never been pulled here).

**Not yet imported.** `ovl/zfi_tr_bankacct` (03/11/26, same TABL shape) came back "views created,
table not created" and the pull log line was never supplied — so a DDIC failure on this pull is
possible and the SE11 fallback below is part of the delivery, not an afterthought.

Import: `ZABAPGIT_STANDALONE` → New Offline Repo → package (existing GR package, or new) → Import
ZIP `ZGR_FSITEM_REMAP.zip` → Pull → transport request when asked. Check first in SE11 that
`ZGR_FSITEM_MAP`, `ZIGRFSREMAPCUBE`, the two domains and three data elements do not already exist.
If the pull stops on the DDLS with an activation error, the DDIC is already in: open
`ZI_GR_FSREMAP_CUBE` in ADT and paste the error back.

**Fallback, same objects, same order, by hand:** SE11 domains `ZGR_RBUNIT` (CHAR 18) and
`ZGR_RITEM` (CHAR 10); SE11 data elements on them with the labels in TS §4.1; table from
`ZGR_FSITEM_MAP.tabl.ddl` (ADT Database Table, paste whole) or the SE11 field list in TS §4.2;
then ADT → New → Data Definition `ZI_GR_FSREMAP_CUBE`, paste `src/zi_gr_fsremap_cube.ddls.asddls`.

Re-zip after any change:

    cd ovl/zgr_fsitem_remap && rm -f ZGR_FSITEM_REMAP.zip && zip -X ZGR_FSITEM_REMAP.zip .abapgit.xml src/*

## F4 in SM30 (asked 06/11/26) — manual SE11 step after the import

A search-help assignment or a foreign key is DDIC metadata that abapGit has never pulled here, so
it is done in SE11 once the table is active. The names come from ACDOCU, not from memory:

1. SE11 → `ACDOCU` → *Entry help/check*: rows `RBUNIT` and `RITEM`, columns *Check table* and
   *Srch Help* (if empty: double-click the data element → *Further Characteristics* → Search Help).
2. SE11 → `ZGR_FSITEM_MAP` → Change → *Entry help/check* → row → *Search Help* button → name,
   export parameter mapped to the field → Copy. `RBUNIT` gets the unit help; `RITEM` **and**
   `RITEM_NEW` the FS item help. An import parameter for the cons chart of accounts stays
   unassigned (single chart, A&Q 2). Activate; the TMG needs no regeneration.
3. Check table instead of search help on ACDOCU: *Foreign Keys* → that check table → *Generate
   proposal*; the chart-of-accounts key field, absent here, becomes generic `*`. This variant
   also validates on save.

Alternative: the two standard data elements from step 1 on `RBUNIT` / `RITEM` in place of
`ZGR_RBUNIT` / `ZGR_RITEM` (table XML + DDL change, A&Q 4); `RITEM_NEW` keeps `ZGR_RITEM_NEW` for
its heading and gets the help by step 2.

## How the view does it

```
left outer join zgr_fsitem_map as FSItemMap
  on  FSItemMap.rbunit = JrnlEntry.ConsolidationUnit
  and FSItemMap.ritem  = JrnlEntry.FinancialStatementItem
...
case
  when FSItemMap.ritem_new is not null
   and FSItemMap.ritem_new <> ''
  then FSItemMap.ritem_new
  else JrnlEntry.FinancialStatementItem
end as NewFinancialStatementItem
```

`@ClientHandling.algorithm: #SESSION_VARIABLE` (as on the standard cube) adds the client
condition on the table itself — `MANDT` is not written in the join. `IS NOT NULL` is tested first:
after a join miss the column is NULL and `NULL <> ''` is not true, so the ELSE branch would be
reached either way, but the order makes the intent explicit. `_NewFinStmntItm`
(`I_GroupReportingFSItem`, same cons chart of accounts) gives the new column key + text and the FS
item hierarchies in the query.

## Gotchas

- **Never read the standard cube or the Z cube without filters.** Data Preview with the four
  parameters and no WHERE dumped on OCD on 06/11/26 (`DBSQL_SQL_INTERNAL_DB_ERROR`, HANA statement
  memory limit, 577 MB in pool `Results`, on `IMCRPTC`). Test in the ADT SQL Console with ledger,
  dimension, version, year, period and unit in the WHERE (statements in the ISSUES row of 06/11);
  make those filters mandatory in the CAQ query. Not a defect in `ZI_GR_FSREMAP_CUBE`.

- **The standard cube is `#DEPRECATED`** (successor `I_MATRIXCNSLDTNREPORTC_2`). The Z cube is built
  on the deprecated one because its source was supplied and its signature is known. An upgrade
  that removes it breaks the Z cube — A&Q item 7.
- **`@Analytics.readClassName: 'CL_FINCS_GRA_CUBE_REL'` is not carried.** The Z cube is plain SQL
  over the foundation view. Compare totals with *Group Data Analysis* for one unit / version /
  period at posting level and at group level before anyone reports from it (TS §6, test 7).
- **`#NOT_REQUIRED` access control** — the standard cube restricts by DCL. Fine for the
  consolidation team; a DCL is one object if the tile goes wider.
- Key is unit + FS item only (single dimension / cons chart of accounts assumed). Adding `RDIMEN`
  / `RITCLG` later is a table conversion — decide before entries exist.
- A row with a blank *New FS Item* is "no mapping" (falls back). Blank is never shown.
- Delivery class A with the **standard** TMG recording routine prompts for a transport on every
  SM30 entry — set *no, or user, recording routine* when generating.
- The CAQ app lists a cube only when it is `#CUBE`, classified (`modelingPattern` /
  `supportedCapabilities`, both set) **and** released for key-user apps (C1, manual in ADT).
- `_Extension` and `_FiscalCalendarDate` from the standard source are left out: the first is SAP's
  extension hook (extend-view target), the second is defined there but never exposed.
- Baseline in `original/` is the SAP source as pasted from ADT on 06/11/26. Diff against it after
  any support package before touching the Z cube: a new element in the standard is one line here.
