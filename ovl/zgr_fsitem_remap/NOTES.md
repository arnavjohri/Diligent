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

| Table field | Key | Data element | Type | SM30 heading |
|---|---|---|---|---|
| `MANDT` | key | `MANDT` | CLNT 3 | — |
| `RBUNIT` | key | `ZGR_RBUNIT` (new, built-in type) | CHAR 18 | Cons. Unit |
| `RITEM` | key | `ZGR_RITEM` (new, built-in type) | CHAR 10 | FS Item |
| `RITEM_NEW` | — | `ZGR_RITEM_NEW` (new, built-in type) | CHAR 10 | New FS Item |

Z data elements with built-in types on purpose: the standard ACDOCU data elements are not
confirmed from here (no system access) and a wrong name costs an activation cycle; the CDS join
compares by type and length, which are the ACDOCU lengths. Item 4 of the A&Q says how to swap in
the standard elements if wanted.

## Objects, in creation order

1. **Data elements** `ZGR_RBUNIT`, `ZGR_RITEM`, `ZGR_RITEM_NEW` — SE11, form-based (TS §4.1 step 1).
   Never serialised by paste; 1 minute each.
2. **Table `ZGR_FSITEM_MAP`** — `ZGR_FSITEM_MAP.tabl.ddl` (41 lines incl. header), ADT *Database
   Table* DDL source, paste whole. Delivery class **A**, *Display/Maintenance allowed*,
   enhancement category *character-type*. Technical settings (separate tab): APPL2, size 0, no
   buffering. SE11 fallback: TS §4.2.
3. **TMG** on `ZGR_FSITEM_MAP` — SE11 → Utilities → Table Maintenance Generator, manual (TS §4.1
   step 3). Then SM30.
4. **CDS `ZI_GR_FSREMAP_CUBE`** — `ZI_GR_FSREMAP_CUBE.ddls.asddls` (743 lines), SQL view
   `ZIGRFSREMAPCUBE`, classic `define view`, `@Analytics.dataCategory: #CUBE`. ADT: New → Data
   Definition, name `ZI_GR_FSREMAP_CUBE`, replace the template with the file. Needs 2 active.
5. **Key-user release** of the cube — ADT, right-click the DDL source → Properties → API State →
   *Use in Key User Apps (C1)*. Manual; without it *Custom Analytical Queries* does not list the
   cube (MEMORY §4.1, bank reval 28/10–02/11/26).
6. The query / tile — functional consultant, in *Custom Analytical Queries* on
   `ZI_GR_FSREMAP_CUBE`.

Optional, on request: DCL inheriting the standard cube's access control (A&Q item 10); SE93
transactions on SM30 (item 16); foreign keys / search helps on the table fields (item 5).

## How it ships

**Paste**, all three code objects. No abapGit ZIP: the hand-written DDLS XML shape is proven on
this landscape (28/10, 03/11) but the DTEL/TABL shapes only via `kpmg/zpp_forecast_paints`, and
the two data elements are quicker in SE11 than in XML. Re-evaluate if a fourth GR object follows.

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

- **The standard cube is `#DEPRECATED`** (successor `I_MATRIXCNSLDTNREPORTC_2`). The Z cube is built
  on the deprecated one because its source was supplied and its signature is known. An upgrade
  that removes it breaks the Z cube — A&Q item 7.
- **`@Analytics.readClassName: 'CL_FINCS_GRA_CUBE_REL'` is not carried.** The Z cube is plain SQL
  over the foundation view. Compare totals with *Group Data Analysis* for one unit / version /
  period at posting level and at group level before anyone reports from it (TS §6, test 4).
- **`#NOT_REQUIRED` access control** — the standard cube restricts by DCL. Fine for the
  consolidation team; a DCL is one object if the tile goes wider.
- Key is unit + FS item only (single dimension / cons chart of accounts assumed). Adding `RDIMEN`
  / `RITCLG` later is a table conversion — decide before entries exist.
- A row with a blank *New FS Item* is "no mapping" (falls back). Blank is never shown.
- Delivery class A with the **standard** TMG recording routine prompts for a transport on every
  SM30 entry — set *no, or user, recording routine* when generating.
- `_Extension` and `_FiscalCalendarDate` from the standard source are left out: the first is SAP's
  extension hook (extend-view target), the second is defined there but never exposed.
- Baseline in `original/` is the SAP source as pasted from ADT on 06/11/26. Diff against it after
  any support package before touching the Z cube: a new element in the standard is one line here.
