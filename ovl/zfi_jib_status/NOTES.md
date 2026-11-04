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

## Objects — all six in `ZFI_JIB_STATUS.zip` (04/11/26, consumer: Custom Analytical Queries)

Six classic `define view`s in `src/`, one abapGit ZIP, into the **existing package `ZFI_OTH`**.
No table, no domain, no data element, no `package.devc.xml` — on purpose (the treasury ZIP
created both DDL sources and not the table; a DEVC file would overwrite the package text).

**Model (04/11/26).** The window a JIB falls in is decided by its **entry date** (BKPF-CPUDT),
not its posting period, and the cube has one row per venture per *window* at three
granularities — fiscal year (Y), fiscal quarter (Q), month (M) of entry — each row carrying
the latest entry in that window. A query filters Granularity + the window and gets exactly one
row per venture: "if they enter 2026 and the last posting was done in period 1, show that, not
Pending for the other months" (Arnav, 04/11/26). Fiscal year variant April–March throughout.

| # | Object | SQL view | What | Lines |
|---|---|---|---|---|
| 1 | `ZI_JIB_ENTRY` | `ZIJIBENTRY` | every BKPF header with the fiscal year / quarter / period of its **entry date** (CPUDT − 3 months → fiscal year; literal CASE on the calendar month → period and quarter) and the first day of the entry month / quarter / fiscal year (`dats_add_months`, `concat`, `cast … as abap.dats`, the `ZDPR_P_ASOF` shapes) | 140 |
| 2 | `ZI_JIB_DOC` | `ZIJIBDOC` | `select distinct` ZI_JIB_ENTRY ⋈ BSEG, document type JM, `stblg = ''`, `vname <> ''`: one row per JIB document and venture with its entry-date window | 72 |
| 3 | `ZI_JIB_DOC_AGG` | `ZIJIBDOCAGG` | UNION ALL of three GROUP BYs on ZI_JIB_DOC — per venture and entry fiscal year (Y), + quarter (Q), + period (M): `max(EntryDate)` LastEntryDate, `max(PostingDate)`, `count(distinct document)`, JibPosted = 1. Literal key `Granularity` cast as in the active `ZDPR_P_PERF_AGG`; blank quarter / period on the coarser rows as `cast( ' ' as abap.char(2) )` | 100 |
| 4 | `ZI_JIB_WINDOW` | `ZIJIBWINDOW` | UNION ALL of three `select distinct` on ZI_JIB_ENTRY: every company code / entry window (Y, Q, M) in which any FI document was entered, with PeriodStartDate = first day of the window. Period '00' (initial CPUDT) excluded | 77 |
| 5 | `ZI_JIB_VENTURE` | `ZIJIBVENTURE` | T8JV left join T8JVT on bukrs + vname, `max(vtext)` under GROUP BY — **WHERE vname = AA2002 / SD2002 / MM2002 / MM2012** | 63 |
| 6 | `ZI_JIB_STATUS_CUBE` | `ZIJIBSTATUSCUBE` | 5 ⋈ 4 on company code, LEFT OUTER JOIN 3 on company code, venture, Granularity, FiscalYear, FiscalQuarter, FiscalPeriod. Keys: CompanyCode (`_CompanyCode` → `I_CompanyCode`), JointVenture (text element ProjectName), Granularity (text element GranularityText), FiscalYear, FiscalQuarter, FiscalPeriod. Characteristics: GranularityText, PeriodStartDate, PeriodMonth, ProjectName (workbook text), JointVentureName ('SAP Venture Name'), VentureType, BusinessUnit, JibStatus (**Status**: `case Jib.JibPosted when 1 'Uploaded' else 'Pending'`), LastEntryDate (**Date** = CPUDT of the latest JIB in the window), LastPostingDate. Measures (INT4, SUM): JibDocuments, JibPosted, JibPending, Ventures. Header set = `ZI_TR_BANKACCT_CUBE` | 190 |

`ZI_JIB_PERIOD` (posting-period frame of 03/11/26) is **gone from `src/`**. On the next pull
abapGit offers it for deletion; letting it delete is fine (nothing references it), or deselect
it and delete by hand later — object deletion is a manual decision.

Decisions behind the shape:
- `JM` is a literal in `ZI_JIB_DOC`, not a SETLEAF join on the GS01 set: if the set is ever
  changed, the JM history must not vanish from the dashboard.
- No BSTAT filter: parked documents have no BSEG lines, so the inner join already drops them,
  and the upload-posted headers carry **BSTAT `Z`** in PRD (column mapping of the SE16N dump,
  03/11/26; meaning of `Z` on domain BSTAT still to be read in SE11). Reversed documents go
  through `stblg = ''`; the reversal documents carry STBLG too, so both sides drop.
- **Window = entry date**, Date = entry date. The posting period and the header text month play
  no part (1017004699: period 11/2017, text "For Jan'18").
- Only JM rows were pulled from PRD (BLART filter), so "JIBs under another type" (check 3) is
  unproven; Arnav's call 03/11/26: JM is enough.
- No `IS NULL`, no arithmetic in a CASE condition, no `$session` variable — every construct is
  one that activated here before (`select distinct`, `count( distinct )`, `coalesce( x, cast( 0
  as … ) )`, simple `CASE` on a field or `substring()`, `max()` on CHAR, `union all` with a
  literal key and GROUP BY per branch, `dats_add_months( d, n, 'INITIAL' )`, `concat`,
  `cast … as abap.char / abap.numc / abap.dats`). The CHAR → DATS cast is the least-proven
  piece (`ZDPR_P_ASOF` is "written", not confirmed active); if `ZI_JIB_ENTRY` fails, it is that.
- **Scope = the four ventures** (Arnav, 03/11/26). `ZI_JIB_VENTURE` keeps AA2002, SD2002,
  MM2002, MM2012; ProjectName and Business Unit are CASEs per venture in the cube with the
  workbook's texts. A fifth venture = one OR line in the view and two WHENs in the cube.
  Nothing in BKPF/BSEG marks a venture as in or out of scope, so the list cannot be derived.
- **What two full PRD documents showed (03/11/26, BSEG by position):** 1016003288 (AIOC JIB
  Oct 2016, 158 lines, venture AA2002) and 1017001506 (Vietnam 06.1 JIB Jul 2017, 31 lines,
  venture VN2012, vendor JV-BP). Every line carries VNAME, the vendor line (PK 31) included,
  with RECID CP on the vendor line and NB on the cost lines, EGRUP NP1. One venture per
  document. ZUONR also holds the venture code on the cost lines. So `count(distinct document)`
  per venture is exact and no JIB is dropped for want of a venture. VN2012 is a structurally
  normal JIB that is simply outside today's list — the "non-valid" example.

**How the query uses it.** Always filter **Granularity**: `Y` + Fiscal Year → one row per
venture with its last JIB entered in that fiscal year; `Q` + Fiscal Year + Fiscal Quarter → the
same for the quarter; `M` + Fiscal Year + Fiscal Period → the same for the month. Or a range on
Period Start Date within one granularity. Rows: JV Code, Project Name, Business Unit, Status,
Date. Without the Granularity filter every venture shows three times and the measures triple.
Pending = no JIB entered in the window; the row exists as long as any FI document was entered
in it.

## How it ships — abapGit ZIP `ZFI_JIB_STATUS.zip`

`.abapgit.xml` (`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`) at the folder root; `src/`
with 12 files: six `*.ddls.asddls` + six `*.ddls.xml`. No DEVC file (existing package). Built with
`zip -X ZFI_JIB_STATUS.zip .abapgit.xml src/*`; XML well-formed, UTF-8, no BOM, LF; DDLNAME
= view name = file name checked by script.

Import: `ZABAPGIT_STANDALONE` → New Offline Repo → package **`ZFI_OTH`** (existing; nothing
in the ZIP touches the package itself) → Import ZIP → Pull → transport request when asked. abapGit activates the six DDL sources in
dependency order (ENTRY, DOC, DOC_AGG, WINDOW, VENTURE, then the cube). If the pull stops on a DDLS with a syntax error,
open it in ADT, paste the error here, the fix comes back as that one file and a rebuilt ZIP.

After the pull, by hand:
1. ADT → Data Preview on `ZI_JIB_STATUS_CUBE`, filter Granularity `M`, FiscalYear 2026,
   FiscalPeriod 02 (May 2026 entries): AA2002 Uploaded with Date 21.05.2026 (the PRD sample,
   entered 21 May for April). Granularity `Y`, FiscalYear 2026: one row per venture.
2. ADT → right-click `ZI_JIB_STATUS_CUBE` → Properties → API State → Add Release State →
   **Use in Key User Apps (C1)** → Finish. Without this the CAQ app does not list it.
3. `RSRTS_ODP_DIS` → `2CZIJIBSTATUSCUBE` opens without errors.
4. GR consultant: Custom Analytical Queries → New → data source `ZI_JIB_STATUS_CUBE` (search
   without `*`). Rows: JV Code, Project Name, Business Unit, JIB Posting Status, Date (Last
   JIB Entry); filters Fiscal Year, Posting Period / Fiscal Quarter, Business Unit.
