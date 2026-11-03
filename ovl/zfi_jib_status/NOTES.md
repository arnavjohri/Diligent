# ZFI_JIB_STATUS — Management Dashboard, "JIB Status" card (design notes, 03/11/26)

**Project:** OVL (ONGC Videsh) · dev OCQ/500, sample document from PRD · object name
provisional. **Nothing is built yet** — this file holds what was established in chat on
03/11/26 so the design survives the session.

**Purpose:** per joint venture, has the month's JIB (Joint Interest Billing received from the
operator — OVL is the non-operating partner) been posted, and when. Requirement workbook:
`docs/Management_Dashboard_-_JIB_Status_-_Final.xlsx` (sheet *JIB Status*).

| Column (workbook) | Example | Source (proposed) |
|---|---|---|
| JV Code | AA2002 | T8JV-VNAME |
| Project Name | ACG | T8JVT-VTEXT |
| Business Unit | MENA & CIS BU | fixed attribute of the JV — Z mapping table (see open questions) |
| Status | Uploaded / Pending | JM document with venture in the period exists / does not |
| Date | 21.04.2026 | MAX( BKPF-CPUDT ) of those documents |

Filters: Project, Business Unit ("freezed input" = fixed per JV, BU dropdown wanted),
Period (month / quarter / year).

## What a JIB posting looks like in PRD (BKPF row supplied 03/11/26)

| Field | Value | Meaning |
|---|---|---|
| BUKRS / BELNR / GJAHR | OVL / 1026000459 / 2026 | document key |
| BLART | JM | document type — the only machine-stamped marker |
| BLDAT = BUDAT | 30.04.2026 | the JIB *for* April 2026 |
| MONAT | 1 | FY variant April–March: April = period 1, GJAHR 2026 = FY 2026-27 |
| CPUDT / CPUTM | 21.05.2026 17:45:13 | entered on 21 May → the dashboard "Date" |
| TCODE | FBVB | posted from a *parked* document (FBV0 path), not by BAPI |
| XBLNR | AIOC JIB | free text, typed by the user |
| BKTXT | For April ,26 | free text, typed by the user |
| BSTAT / STBLG | blank | posted (not parked), not reversed |
| AWTYP / AWKEY | BKPFF / 1026000459OVL 2026 | manual FI document |
| WAERS / HWAER | USD / INR | |

BKPF carries no venture. BSEG-VNAME on the line items does (join on BUKRS, BELNR, GJAHR).

## How a JIB document is recognised — and why BLART is the key

- Nothing in BKPF/BSEG says "JIB". OVL's upload program `ZJV_BAPI_BALUPLOAD1` (repo:
  `ovl/zjv_bapi_balupload1/`) and its sister `ZJV_BAPI_BALUPLOAD1_MON` stamp **only the
  document type**, read from GS01 set `ZJVNONOPJIB_DOCTYP_MON` (`G_SET_GET_ALL_VALUES`,
  table BKPF, field BLART). `header_txt` and `ref_doc_no` are copied from the upload file
  (`ist_gl-htext`, `ist_gl-refdoc`) — so XBLNR / BKTXT are whatever the user typed and
  cannot be filter keys.
- The PRD sample is `TCODE FBVB` — a parked document that was posted. `BAPI_ACC_DOCUMENT_POST`
  never produces FBVB, so at least some JIBs are parked and posted by hand. The document type
  is still the common marker, as long as the hand-posted ones also use JM (the sample does).
- Read the document type from the same set (`SETLEAF`, set `ZJVNONOPJIB_DOCTYP_MON`) or a
  Z customizing table rather than hardcoding `'JM'`; the set is what the upload uses.

### Checks on PRD before anything is built (display only)
1. **Done 03/11/26 (GS03 screenshot):** set `ZJVNONOPJIB_DOCTYP_MON`, "Set for NonOP JIB
   upload-DocType-Monthly", table BKPF, field BLART, one line: `JM`. So every monthly JIB
   posted by the upload carries JM. Still open: is there a provision set (`_MON` has a
   JIB-provision mode, memory ID `ZJIB_PROV`)? If provisions post under JM too they would
   show as "Uploaded".
2. **Done 03/11/26:** SE16N BKPF OVL / JM, 2016–2018 pasted — every row is a JIB
   (AREA 1, AIOC, VN 06.1, SATYPEV, A1/A3, RC8-POSES), TCODE FBVB or ZJV_NOP_JIBUPLD_MON(C).
   Six of them are reversed (STBLG filled), hence the `stblg = ''` filter in view 1.
3. `SE16N BKPF`: BUKRS `OVL`, XBLNR `*JIB*`, BLART ≠ `JM` → any row means JIBs also go
   through another document type and BLART alone misses them.
4. `SE16N T003T`: BLART `JM`, SPRAS `EN` → the configured description.
5. One JIB that was parked on an earlier day than it was posted: FB03 → header *Entered on*
   vs *Environment → Document changes*. Settles whether CPUDT is the park date or the post
   date after FBV0 (the sample has AEDAT blank, so it cannot tell).

## Selection logic (proposed, not yet written as an object)

```
BKPF   bukrs = OVL, blart = JM (from set / Z table), bstat = ' ', stblg = ' ',
       budat between P_DateFrom and P_DateTo
join   BSEG on bukrs, belnr, gjahr, where vname <> ' '
group  by vname  ->  max( cpudt ) as LastEntryDate, count(*) as Documents
driver T8JV (bukrs, vname) LEFT OUTER JOIN the aggregate -> no row = Pending
texts  T8JVT-VTEXT (field names confirmed by active SAPMZOVL_JV_CC_PAI)
BU     Z mapping table (vname -> BU, project name) — or CASE on the venture prefix
       (AA Azerbaijan / SD Sudan -> MENA & CIS; MM Myanmar -> AP) as ZDPR_Q_DASH_FILTER does
       for assets. Recommend the table: "freezed input", maintainable by SM30.
```

- Period attribution by **BUDAT** (the JIB *for* April has BUDAT 30.04.2026); the "Date"
  shown is **CPUDT** (entered 21.05.2026). The workbook sample "21.04.2026" for AA2002 is
  then the March JIB, entered in April — confirm the semantics with the requester.
- A document can carry several ventures (one upload file, many JVs) — the per-venture
  grouping handles it.
- Venture from BSEG, not ACDOCA ledger 0L: on this landscape 0L venture is incomplete
  (`ovl/zfi_acdoca_jva_align`), and a JIB line has the venture explicitly on BSEG.
- **Not part of the DPR Overview Page** (Arnav, 03/11/26: "a different requirement"). The
  Management Dashboard is its own consumer, still to be named (Fiori app, SAC, or ABAP
  report). The DPR parameter names (`P_DateFrom` / `P_DateTo`) are therefore not binding;
  the ZDPR views remain the pattern for a classic `define view` + `@OData.publish: true`
  on this release. MEMORY.md §4.1 applies to any CDS written for it (no `year()`/`month()`,
  no `@Semantics.*` in view entities, parameters typed with data elements, `CASE` not in
  `GROUP BY` → helper view).

## Open questions (03/11/26)
1. `JM` is the set value (confirmed 03/11/26). Exclusive to JIBs, and used by every JIB
   including hand-parked ones (checks 2–3 above)? Still open.
2. Which document type do JIB **provisions** use?
3. Quarter / year period: "Uploaded" when every month is posted, or when any is?
4. Business Unit mapping: Z table (recommended) or hardcoded CASE on the venture prefix?
5. "Date" = CPUDT (entered) — confirmed by Arnav's wording "last creation date"; the
   requester's sample dates should be checked against that reading.
6. Company code OVL only, or every company code with ventures?
7. Consumer of the data source: Fiori / OData, SAC, or an ABAP report? Decides the object
   type (CDS view with OData service vs. a report).

## Objects (decided 03/11/26 — consumer is a Fiori tile built in Custom Analytical Queries)

Three classic `define view`s, pasted in ADT one at a time, loose files in this folder:

| # | Object | SQL view | What | File | Status |
|---|---|---|---|---|---|
| 1 | `ZI_JIB_DOC_AGG` | `ZIJIBDOCAGG` | BKPF (JM, not reversed) ⋈ BSEG, grouped by company code / venture / GJAHR / MONAT: `max(cpudt)` LastEntryDate, `max(budat)`, `count(distinct belnr)` JibDocuments, JibPosted (= 1) | `ZI_JIB_DOC_AGG.ddls.asddls` | delivered 03/11/26, awaiting activation |
| 2 | `ZI_JIB_PERIOD` | `ZIJIBPERIOD` | `select distinct bukrs, gjahr, monat from bkpf` (MONAT 01–12): every period with any posting, so a period with no JIB at all still shows every venture as Pending | — | next |
| 3 | `ZI_JIB_STATUS_CUBE` | `ZIJIBSTATUSCUBE` | T8JV ⋈ T8JVT (bukrs, vname — the active selects use no SPRAS) ⋈ `ZI_JIB_PERIOD` on bukrs (the cross join), LEFT OUTER JOIN view 1 on all four keys. Status and counts via `coalesce( x, cast( 0 as abap.int4 ) )` (proven in `ZDPR_C_TARGET_CUBE`); no `IS NULL`, no CASE on joined columns. Characteristics: CompanyCode (`_CompanyCode` → `I_CompanyCode`), JointVenture, JointVentureName, VentureType (T8JV-VTYPE; active cash-call code filters `'2'`), BusinessUnit (CASE on `substring(vname,1,2)`: AA/SD → MENA & CIS BU, MM → AP BU, else OTHER — ASSUMPTION until the list arrives), FiscalYear, FiscalPeriod, FiscalPeriodName (literal CASE 01→Apr … 12→Mar), FiscalQuarter, JibStatus, LastEntryDate, LastPostingDate. Measures: JibDocuments (SUM), JibPosted (SUM, 0/1), JibPending (SUM, 1 − JibPosted), Ventures (SUM, 1). Header set copied from `ZI_TR_BANKACCT_CUBE`; after activation ADT → API State → **Use in Key User Apps (C1)**, then `RSRTS_ODP_DIS` on `2CZIJIBSTATUSCUBE` | — | after 2 |

Decisions behind the shape:
- `JM` is a literal in view 1, not a SETLEAF join on the GS01 set: if the set is ever changed,
  the JM history must not vanish from the dashboard.
- No BSTAT filter: parked documents have no BSEG lines, so the inner join already drops them,
  and the upload-posted headers carry **BSTAT `Z`** in PRD (column mapping of the SE16N dump,
  03/11/26; meaning of `Z` on domain BSTAT still to be read in SE11). Reversed documents go
  through `stblg = ''`; the reversal documents carry STBLG too, so both sides drop.
- Period = GJAHR / MONAT of the posting (FY variant April–March: MONAT 1 = April). The header
  text month is unreliable (1017004699: period 11/2017, text "For Jan'18").
- Only JM rows were pulled from PRD (BLART filter), so "JIBs under another type" (check 3) is
  unproven; Arnav's call 03/11/26: JM is enough.

## Shipping
ADT paste, one DDL source at a time (no SE80 baseline, so no `original/`). The cube needs the
manual C1 release before CAQ lists it (MEMORY.md §4.1).
