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

## Objects — all seven in `ZFI_JIB_STATUS.zip` (06/11/26, consumer: Custom Analytical Queries)

Seven classic `define view`s in `src/`, one abapGit ZIP, into the **existing package `ZFI_OTH`**.
No table, no domain, no data element, no `package.devc.xml` — on purpose (the treasury ZIP
created both DDL sources and not the table; a DEVC file would overwrite the package text).

**Model (06/11/26, from the client's test feedback).** The layout the client expects is her
example: `JV | BU | Project Name | Month | Status | Date of JIB Upload | Document Number`, all
twelve months of the fiscal year, Pending for the months not posted yet (October–March for
2026-27 in October 2026). So:
- **Month = the month the JIB is FOR** = the document's posting period (GJAHR / MONAT, fiscal
  year April–March). "JIB for September" sits in period 06/2026 however late it was entered.
- **Date of JIB Upload = BKPF-CPUDT** of the document, the day it was posted into the system.
- **One row per document**: four September documents = four rows, which the analytical table
  shows as one merged month with four document numbers. A Pending month = one row, no document.
- The 04/11 entry-date model is withdrawn: grouping by the month of *entry* showed August,
  November and February as Pending because those months' JIBs were entered in other months.

| # | Object | SQL view | What | Lines |
|---|---|---|---|---|
| 1 | `ZI_JIB_DOC` | `ZIJIBDOC` | `select distinct` BKPF ⋈ BSEG, document type JM, `stblg = ''`, `vname <> ''`: one row per JIB document and venture with posting period, posting date, entry date (CPUDT), header text, reference, user, and `One` = 1 (the cube's document count) | 87 |
| 1a | `ZI_JIB_YEAR_AGG` | `ZIJIBYEARAGG` | GROUP BY company code / venture / GJAHR on view 1: `max(EntryDate)`, `count(distinct FiscalPeriod)` MonthsUploaded, `count(distinct document)`, JibPosted = 1 — the year summary | 60 |
| 1b | `ZI_JIB_QTR_AGG` | `ZIJIBQTRAGG` | same per GJAHR + FiscalQuarter (view 1 now carries the quarter of the posting period as a CASE) | 57 |
| 2 | `ZI_JIB_DOC_AGG` | `ZIJIBDOCAGG` | GROUP BY company code / venture / GJAHR / MONAT on view 1: `max(EntryDate)` LastEntryDate, `max(PostingDate)`, `max(AccountingDocument)` LastDocument, `count(distinct document)`, JibPosted = 1 | 62 |
| 3 | `ZI_JIB_PERIOD` | `ZIJIBPERIOD` | twelve UNION ALL branches, each `select distinct bukrs, gjahr from bkpf` + the period as `cast( 'nn' as abap.numc(2) )` + FiscalQuarter literal + PeriodStartDate (1 April of GJAHR + n−1 months): every fiscal year with any document gets all twelve months | 232 |
| 4 | `ZI_JIB_VENTURE` | `ZIJIBVENTURE` | T8JV left join T8JVT on bukrs + vname, `max(vtext)` under GROUP BY — **WHERE vname = AA2002 / SD2002 / MM2002 / MM2012** | 63 |
| 5 | `ZI_JIB_STATUS_CUBE` | `ZIJIBSTATUSCUBE` | 4 ⋈ 3 on company code, LEFT OUTER JOIN 2 (month) and LEFT OUTER JOIN 1 (documents) on company code, venture, GJAHR, MONAT. Keys: CompanyCode (`_CompanyCode`), JointVenture (text ProjectName), FiscalYear, FiscalPeriod (text PeriodMonth), AccountingDocument (NULL on a Pending row → `#`). Characteristics: PeriodMonth (April … March), FiscalQuarter, PeriodStartDate, ProjectName, JointVentureName, VentureType, BusinessUnit, JibStatus (**Status**), LastEntryDate (last upload of the month, every row), LastPostingDate, EntryDate (**Date of JIB Upload**, per document), PostingDate, DocumentHeaderText, Reference, EnteredBy. Year / quarter summary on every row (LEFT OUTER JOIN 1a on venture + GJAHR, 1b on + FiscalQuarter): YearStatus, YearLastEntryDate, YearMonthsUploaded, YearJibDocuments, QuarterStatus, QuarterLastEntryDate, QuarterMonthsUploaded, QuarterJibDocuments. Measures (INT4, SUM): JibDocuments (`coalesce( Doc.One, 0 )`), JibPosted (1 on the row whose document = LastDocument — searched CASE comparing two joined fields), JibPending (1 on a Pending row), Ventures (JibPosted + JibPending via nested CASE). Header set = `ZI_TR_BANKACCT_CUBE` | 233 |

`ZI_JIB_ENTRY` and `ZI_JIB_WINDOW` (04/11 model) are **gone from `src/`**; abapGit offers them
for deletion on the pull — nothing references them. `ZI_JIB_PERIOD` comes back (new shape).

**Proven on OCD by the 04/11 pull (the Fiori query ran on it, screenshots 06/11/26):** classic
view with `cast( concat( …, '0401' ) as abap.dats )`, `dats_add_months( d, n, 'INITIAL' )`,
`substring()` on a DATS, UNION ALL of `select distinct` branches with literal `cast( 'Y' as
abap.char(1) )` keys, UNION ALL of GROUP BY branches with literal cast keys, `max()` on CHAR,
`count( distinct )`. Recorded in MEMORY.md §4.1.

**CPUDT on a parked-then-posted JIB (FB03 header of 1026003147, 06/11/26):** Entry Date
14.10.2026 13:07:04, Date of Parking 14.10.2026 12:34:23, parked with `ZJV_NOP_JIBUPLD_MO_C`,
transaction FBVB. Entry time is later than parking time, so CPUDT/CPUTM are written at the
posting, not the parking — Date of JIB Upload = CPUDT holds. (Same day in this sample; a
different-day sample would make it airtight.)

Decisions behind the shape:
- `JM` is a literal in `ZI_JIB_DOC`, not a SETLEAF join on the GS01 set: if the set is ever
  changed, the JM history must not vanish from the dashboard.
- No BSTAT filter: parked documents have no BSEG lines, so the inner join already drops them,
  and the upload-posted headers carry **BSTAT `Z`** in PRD. Reversed documents go through
  `stblg = ''`; the reversal documents carry STBLG too, so both sides drop.
- Only JM rows were pulled from PRD (BLART filter), so "JIBs under another type" (check 3) is
  unproven; Arnav's call 03/11/26: JM is enough.
- **Scope = the four ventures** (Arnav, 03/11/26). `ZI_JIB_VENTURE` keeps AA2002, SD2002,
  MM2002, MM2012; ProjectName and Business Unit are CASEs per venture in the cube with the
  workbook's texts. A fifth venture = one OR line in the view and two WHENs in the cube.
- **What two full PRD documents showed (03/11/26):** every BSEG line carries VNAME, the vendor
  line (PK 31) included; one venture per document. VN2012 (Vietnam 06.1) is a structurally
  normal JIB outside today's list — the "non-valid" example.
- Arnav's 04/11 reading ("if they enter 2026 and the last posting was in period 1, show that,
  not Pending for the other months") is superseded by the client's example, which lists every
  month with its own status. The year's "last upload" is still visible: filter the fiscal year,
  sort by Date of JIB Upload; the measures summed over the year give "x of 12 months uploaded".

**One line per venture for a year or quarter (Arnav, 06/11/26):** a second query (or a view
switch) whose rows are JV Code, Project Name, Business Unit, Year Status, Last JIB Upload in
Fiscal Year, Months Uploaded in Fiscal Year — no Month, no Document Number — collapses to one
line per venture, because those columns carry the same value on every row of the venture-year.
Quarter the same with the Quarter columns and a Fiscal Quarter filter. The monthly layout of
the client's example is untouched by this.

**How the query uses it.** Rows: JV Code, Business Unit, Project Name, Month, Status, Date of
JIB Upload, Document Number — the analytical table merges the repeated cells, so a month with
four documents reads as the client's example. Filters: Fiscal Year (twelve months), Fiscal
Quarter, Posting Period, Business Unit, JV Code, or a range on Period Start Date. Sort by Posting
Period, not Month (text). No mandatory filter in the cube. The document header dialog on a click
is navigation in the Fiori app with CompanyCode, AccountingDocument and FiscalYear from the row.

## How it ships — abapGit ZIP `ZFI_JIB_STATUS.zip`

`.abapgit.xml` (`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`) at the folder root; `src/`
with 14 files: seven `*.ddls.asddls` + seven `*.ddls.xml`. No DEVC file (existing package). Built with
`zip -X ZFI_JIB_STATUS.zip .abapgit.xml src/*`; XML well-formed, UTF-8, no BOM, LF; DDLNAME
= view name = file name checked by script.

Import: `ZABAPGIT_STANDALONE` → New Offline Repo → package **`ZFI_OTH`** (existing; nothing
in the ZIP touches the package itself) → Import ZIP → Pull → transport request when asked. abapGit activates the seven DDL sources in
dependency order (DOC, DOC_AGG, YEAR_AGG, QTR_AGG, PERIOD, VENTURE, then the cube). If the pull stops on a DDLS with a syntax error,
open it in ADT, paste the error here, the fix comes back as that one file and a rebuilt ZIP.

After the pull, by hand:
1. ADT → Data Preview on `ZI_JIB_STATUS_CUBE`, JointVenture AA2002, FiscalYear 2026: twelve
   months; period 06 (September) Uploaded with four document rows, Date of JIB Upload
   14.10.2026 (the client's example); periods 07–12 Pending with no document.
2. ADT → right-click `ZI_JIB_STATUS_CUBE` → Properties → API State → Add Release State →
   **Use in Key User Apps (C1)** → Finish. Without this the CAQ app does not list it.
3. `RSRTS_ODP_DIS` → `2CZIJIBSTATUSCUBE` opens without errors.
4. GR consultant: Custom Analytical Queries → New → data source `ZI_JIB_STATUS_CUBE` (search
   without `*`). Rows: JV Code, Project Name, Business Unit, JIB Posting Status, Date (Last
   JIB Entry); filters Fiscal Year, Posting Period / Fiscal Quarter, Business Unit.
