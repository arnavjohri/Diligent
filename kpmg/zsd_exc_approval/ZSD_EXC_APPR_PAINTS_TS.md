# Technical Specification — WRICEF 141.B, Exceptional Approval, Paints

Locked build contract: `BUILD_SPEC_141B.md`. Functional spec: `fs/141B_Exceptional_approval_format_Paints.docx`
(WRICEF 141.B, dated 24.08.2026, prepared by Sanjay Modhvadiya), as summarised and settled
in `BUILD_SPEC_141B.md` §1. Open functional questions: `ISSUES.md`. DDIC build sheet:
`ZSD_EXP_PAINTS_DDIC.md`. Upload file layout: `ZSD_EXP_PAINTS_UPLOAD_TEMPLATE.md`.

This document covers all five objects of WRICEF 141.B as one build. It is the pair of
`ZSD_EXC_APPR_ADHESIVE_TS.md` (WRICEF 141.A) and follows the same shape; the two reports
share FORM naming, ALV construction and text-symbol style by design.

---

## 1. Document control

| Item | Value |
|---|---|
| WRICEF | 141.B |
| Title | Exceptional approval format - Paints |
| Module | SD |
| Client | Astral Limited |
| Project | UDAY |
| Author | Arnav Johri, Associate Consultant, Diligent Tech India Pvt. Ltd. |
| Related FS | WRICEF 141.B — Exceptional approval format, Paints, dated 24.08.2026 |
| Build contract | `BUILD_SPEC_141B.md` (wins over the FS where the two disagree) |
| Objects | 5 — see §3 |
| ALV (both programs) | `REUSE_ALV_GRID_DISPLAY_LVC`, full screen, hand-built `LVC_T_FCAT` |
| Shipping | DDIC objects 1–3: SE11 build sheet, typed by hand (not ZIP-able, not paste-able). Programs 4–5: PASTE. Screen-free, so a ZIP is technically possible, but hand-written abapGit XML has never imported successfully on this landscape — see `CLAUDE.md`. |
| Transport | `<TR to be filled by Arnav>` |
| Date | 02.09.2026 |

---

## 2. Purpose

Astral's Paints division records exceptional credit approvals — a customer allowed to
trade past its credit limit, or past a promised collection date, on management's say-so —
nowhere in standard SAP today. WRICEF 141.B builds that record and a report over it, in
three layers:

1. A custom table, `ZSD_EXP_PAINTS`, one row per exceptional approval, keyed by customer,
   serial number and approval month, holding the approval window, the exceptional amount,
   a collection commitment amount and date, and free-text remarks.
2. A mass upload/change program, `ZSD_EXP_PAINTS_UPLOAD`, so a credit controller can load
   or update many rows at once from a spreadsheet instead of typing them one at a time in
   SM30.
3. An output report, `ZSD_EXC_APPR_PAINTS`, that lists every approval for a chosen
   customer/organisational selection and, for each row, shows the customer's actual
   credit limit in the chosen credit segment, the actual collection posted against that
   approval's own window, the resulting non-fulfilment amount and default percentage, and
   two independent status readings — whether the shortfall has since been collected, and
   whether the commitment date has fallen due at all.

Unlike WRICEF 141.A (Adhesives, which reads an existing BP credit-management table and is
explicitly read-only), 141.B both creates the data it reports on and reports on it — the
table exists for this purpose alone, so mass upload is in scope from the start.

---

## 3. The five objects, in build order

| # | Object | Type | Created via | Depends on |
|---|---|---|---|---|
| 1 | 5 domains + 6 data elements | DDIC | SE11, by hand (`ZSD_EXP_PAINTS_DDIC.md` §1–§2) | — |
| 2 | `ZSD_EXP_PAINTS` | Transparent table | SE11, by hand (`ZSD_EXP_PAINTS_DDIC.md` §3) | object 1, all active |
| 3 | Table maintenance generator | SE11 → Utilities → TMG | SE11, by hand (`ZSD_EXP_PAINTS_DDIC.md` §4) | object 2, active |
| 4 | `ZSD_EXP_PAINTS_UPLOAD` | Executable report, screen-free | SE38 paste | object 2, active (compiles against the table) |
| 5 | `ZSD_EXC_APPR_PAINTS` | Executable report, screen-free | SE38 paste | object 2, active |

Objects 1–3 cannot be pasted or ZIPped — abapGit does not serialise a table maintenance
generator's screens (SE51) or GUI status (SE41), so the TMG must be built by hand in every
system it is needed in, even if the table itself later travels by transport. Objects 4 and
5 have no dependency on each other and can be built or activated in either order once
object 2 is active, but object 4 is listed first because a report over an empty table has
nothing to show, and it is table population before it is table reading in Arnav's own
activation sequence.

---

## 4. Table design — `ZSD_EXP_PAINTS`

Full SE11 typing instructions, including the currency-reference activation blocker, live
in `ZSD_EXP_PAINTS_DDIC.md`. This section is the design summary a client reviewer needs
without opening the build sheet.

### 4.1 Domains and data elements

| Domain | Type | Len/Dec | Notes |
|---|---|---|---|
| `ZSD_DO_EXC_SRNO` | NUMC | 10 | serial number, no SNRO behind it — see §8 |
| `ZSD_DO_EXC_MONTH` | NUMC | 6 | stored `YYYYMM`, displayed `MM-YYYY` in ABAP, never by a conversion routine |
| `ZSD_DO_EXC_TYPE` | CHAR | 1 | fixed values `1` Credit Limit, `2` Overdue, `3` Credit Limit & Overdue |
| `ZSD_DO_EXC_AMOUNT` | CURR | 23,2 | FS-specified width, unusually wide — flagged in `ZSD_EXP_PAINTS_DDIC.md` §1.4 |
| `ZSD_DO_EXC_REMARKS` | CHAR | 250 | lower case ticked, free prose |

Six data elements sit on these five domains (`ZSD_DE_CM_AMOUNT` shares `ZSD_DO_EXC_AMOUNT`
with `ZSD_DE_EXC_AMOUNT` so a later width change is one edit, not two).

### 4.2 Table fields, in key order

| Pos | Field | Key | Data element | Type | Len/Dec | Source |
|---|---|:--:|---|---|---|---|
| 1 | `MANDT` | X | `MANDT` | CLNT | 3 | standard |
| 2 | `ZSRN` | X | `ZSD_DE_EXC_SRNO` | NUMC | 10 | FS |
| 3 | `ZCUSTOMER` | X | `KUNNR` | CHAR | 10 | FS |
| 4 | `ZEXC_APPR_MONTH` | X | `ZSD_DE_EXC_MONTH` | NUMC | 6 | FS |
| 5 | `ZEXC_APPR_TYPE` | | `ZSD_DE_EXC_TYPE` | CHAR | 1 | FS |
| 6 | `ZEXC_DATE_FROM` | | `DATUM` | DATS | 8 | FS |
| 7 | `ZEXC_DATE_TO` | | `DATUM` | DATS | 8 | FS |
| 8 | `ZEXC_AMOUNT` | | `ZSD_DE_EXC_AMOUNT` | CURR | 23,2 | FS |
| 9 | `ZCOMMIT_DATE` | | `DATUM` | DATS | 8 | FS |
| 10 | `ZEX_AMNT` | | `ZSD_DE_EXC_AMOUNT` | CURR | 23,2 | FS — built, never read by the report, see §7 deviation 9 |
| 11 | `ZCM_AMNT` | | `ZSD_DE_CM_AMOUNT` | CURR | 23,2 | FS |
| 12 | `ZREMARKS` | | `ZSD_DE_EXC_REMARKS` | CHAR | 250 | FS |
| 13 | `WAERS` | | `WAERS` | CUKY | 5 | **not in FS** — mandatory currency reference for rows 8/10/11, see §7 deviation 10 |
| 14 | `ERNAM` | | `ERNAM` | CHAR | 12 | **not in FS** — recommended audit field, see §7 deviation 11 |
| 15 | `ERDAT` | | `ERDAT` | DATS | 8 | as above |
| 16 | `AENAM` | | `AENAM` | CHAR | 12 | as above |
| 17 | `AEDAT` | | `AEDAT` | DATS | 8 | as above |

The four-part key (`ZSRN` + `ZCUSTOMER` + `ZEXC_APPR_MONTH`) is what lets one customer
carry several approvals across different months, and is the key the upload program checks
for duplicates and for insert-vs-change.

Two foreign keys: `ZCUSTOMER` → `KNA1` and `WAERS` → `TCURC`. `ZEXC_APPR_TYPE` is checked
by its own domain fixed values, no foreign key needed.

Delivery class `A`, Display/Maintenance Allowed, data class `APPL0`, size category `1`,
buffering **not allowed** (the table is written from two directions — SM30 and the mass
upload — and the report must never read a stale buffered image right after an upload),
log data changes ticked, enhancement category "can be enhanced (deep)".

### 4.3 Table maintenance generator

Function group `ZSD_EXC_PAINTS` (note the **C**, against the table's **P** — both spellings
appear in the same programs and are easy to transpose), one-step maintenance, overview
screen `0001`, standard recording routine, authorization group `&NC&` pending a real group
from functional (open issue 15). Regenerate the TMG after any change to the table's field
list — a stale TMG dumps in SM30.

---

## 5. `ZSD_EXP_PAINTS_UPLOAD` — mass upload and change

### 5.1 Selection screen

| Block | Field | Type | Obligation | Default | Purpose |
|---|---|---|---|---|---|
| File | `P_FILE` | PARAMETERS, `TYPE localfile` | Obligatory | — | file path, F4 via `cl_gui_frontend_services=>file_open_dialog` |
| File | `P_HEAD` | CHECKBOX | — | `X` | first file line is a header row and is skipped |
| Mode | `P_INS` | RADIOBUTTON, group `MD` | — | `X` | insert new records only |
| Mode | `P_UPD` | RADIOBUTTON, group `MD` | — | — | insert new and change existing |
| Processing | `P_TEST` | CHECKBOX | — | `X` | validate only, no database update |

### 5.2 File format

Tab-delimited text, read with `cl_gui_frontend_services=>gui_upload` (`filetype = 'ASC'`,
`has_field_separator = abap_true`) — split by tab position, never by header name, so a
column typed in the wrong place is silently read into the wrong field. The file is
produced in Excel with **File → Save As → Text (Tab delimited)**; an `.xlsx`/`.xls` binary
is not read. A completely blank line, including a trailing one Excel often appends, is
skipped without comment.

Column order, fixed and unnamed at the file level:

| # | Column | Mandatory | Accepted format |
|---|---|---|---|
| 1 | `ZSRN` | Yes | digits only, ≤10, right-padded into NUMC(10) |
| 2 | `ZCUSTOMER` | Yes | ≤10 chars, ALPHA-converted so leading zeros are optional |
| 3 | `ZEXC_APPR_MONTH` | Yes | `MM-YYYY` or `MM/YYYY`, converted to stored `YYYYMM` |
| 4 | `ZEXC_APPR_TYPE` | Yes | exactly `1`, `2` or `3` |
| 5 | `ZEXC_DATE_FROM` | Yes | `DD.MM.YYYY` or `DD/MM/YYYY`, day first |
| 6 | `ZEXC_DATE_TO` | No | same date rule; blank allowed |
| 7 | `ZEXC_AMOUNT` | No (blank = 0) | digits, one decimal point, comma thousand separators stripped, `+`/`-` sign |
| 8 | `ZCOMMIT_DATE` | No | same date rule; blank allowed |
| 9 | `ZEX_AMNT` | No (blank = 0) | same amount rule |
| 10 | `ZCM_AMNT` | No (blank = 0) | same amount rule |
| 11 | `WAERS` | Yes | ≤5 chars, upper-cased |
| 12 | `ZREMARKS` | No | free text, not trimmed or upper-cased; >250 chars truncated with a log note, row stays valid |

Full accepted-format detail, rejection wording and a worked example are in
`ZSD_EXP_PAINTS_UPLOAD_TEMPLATE.md`.

### 5.3 Validation — every check runs on every row, all errors collected

The program never abandons a row at its first mistake; every applicable check still runs,
and every message found is joined with `;` so the user fixes everything in one pass.

| # | Check | FORM | Error text | Build spec ref |
|---|---|---|---|---|
| 1 | `ZSRN` not blank and numeric, ≤10 digits | `f_parse_rows` | E01 / E02 | 5.3.1 |
| 2 | `ZCUSTOMER` exists in `KNA1` — one read for the whole file | `f_validate_rows` | E20 | 5.3.2 |
| 3 | `ZEXC_APPR_MONTH` parses to `YYYYMM`, month 01–12 | `f_parse_rows` | E05 / E06 | 5.3.3 |
| 4 | `ZEXC_APPR_TYPE` in `1`/`2`/`3` | `f_parse_rows` | E07 / E08 | 5.3.4 |
| 5 | `ZEXC_DATE_FROM`/`ZEXC_DATE_TO`/`ZCOMMIT_DATE` parse to real calendar dates | `f_parse_rows` | E09 / E10 / E11 / E13 | 5.3.5 |
| 6 | `ZEXC_DATE_TO >= ZEXC_DATE_FROM` when both are filled | `f_parse_rows` | E12 | 5.3.6 |
| 7 | Amounts convert cleanly; non-numeric is an error, never a silent zero | `f_parse_rows` | E14 / E15 / E16 | 5.3.7 |
| 8 | `WAERS` exists in `TCURC` — one read for the whole file | `f_validate_rows` | E17 / E18 / E21 | 5.3.8 |
| 9 | Duplicate key (`ZSRN`+`ZCUSTOMER`+`ZEXC_APPR_MONTH`) inside the file | `f_validate_rows` | E22, names the earlier row | 5.3.9 |
| 10 | Key already on the database | `f_validate_rows` | E23 (insert mode) / row updated (change mode) | 5.3.10 |

`KNA1` and `TCURC` existence, and the existing-key read against `ZSD_EXP_PAINTS`, are each
read exactly once for the whole file (`f_read_master_data`), all `FOR ALL ENTRIES` driven
off deduplicated tables built outside the row loop — never a SELECT per row.

### 5.4 Update behaviour

Runs only when `P_TEST` is off **and** at least one row is valid. Valid rows are collected
into `gt_upd` and written with `MODIFY zsd_exp_paints FROM TABLE @gt_upd` inside one LUW,
followed by `COMMIT WORK AND WAIT`; a non-zero `sy-subrc` from either the `MODIFY` or the
`COMMIT` rolls the whole LUW back and marks every row "Not written" — either every valid
row of the file lands on the table, or none does. Invalid rows are never in `gt_upd` and
so can never be written regardless of the outcome.

On insert, `ERNAM`/`ERDAT` are set from `sy-uname`/`sy-datum`. On change, `AENAM`/`AEDAT`
are set the same way, and `ERNAM`/`ERDAT` are read back from the existing row and carried
forward — `MODIFY` replaces the whole row, so without this the created-by information
would be silently overwritten with the changer's.

### 5.5 Log and summary

`REUSE_ALV_GRID_DISPLAY_LVC`, one line per file row: file row number, a traffic-light icon
(`ICON_GREEN_LIGHT` / `ICON_RED_LIGHT` from `INCLUDE <icon>`), serial number, customer,
approval month, approval type, the outcome (Inserted / Changed / Would insert / Would
change / Rejected / Not written) and the message. A closing status-bar message states
counts read / valid / written / in error, and appends "TEST RUN — nothing was written" or
"DATABASE UPDATE FAILED — nothing was written" when either applies.

---

## 6. `ZSD_EXC_APPR_PAINTS` — the report

### 6.1 Selection screen

| Block | Field | Type | Obligation | Default |
|---|---|---|---|---|
| Exceptional Approval Data | `S_KUNNR` | SELECT-OPTIONS on `KNVV-KUNNR` | Optional | — |
| Exceptional Approval Data | `S_DATE` | SELECT-OPTIONS on `ZSD_EXP_PAINTS-ZEXC_DATE_FROM` | **Obligatory** | — |
| Organisational Data | `P_BUKRS` | PARAMETER, `KNB1-BUKRS` | **Obligatory** | — |
| Organisational Data | `S_VKORG` | SELECT-OPTIONS on `KNVV-VKORG` | **Obligatory** | — |
| Organisational Data | `S_SPART` | SELECT-OPTIONS on `KNVV-SPART` | **Obligatory** | — |
| Organisational Data | `S_KVGR1` | SELECT-OPTIONS on `KNVV-KVGR1` | Optional | — |
| Organisational Data | `S_KVGR2` | SELECT-OPTIONS on `KNVV-KVGR2` | Optional | — |
| Organisational Data | `P_SEGMNT` | PARAMETER, `UKMBP_CMS_SGM-CREDIT_SGMNT` | **Obligatory**, default `2000` | — |
| Collection Document Selection | `P_RLDNR` | PARAMETER, `ACDOCA-RLDNR` | **Obligatory** | `0L` |
| Collection Document Selection | `S_BLART` | SELECT-OPTIONS on `ACDOCA-BLART` | **Obligatory** | `DZ` |

Information Category and Information Type, required by the FS, are deliberately **absent**
— `ZSD_EXP_PAINTS` carries neither field, so neither could filter anything (§7 deviation
2). `P_SEGMNT` is not in the FS but is required because `UKMBP_CMS_SGM` is keyed by
partner **and** credit segment. `P_RLDNR`/`S_BLART` exist so the FS's `0L`/`DZ` are
defaults, not hardcoded values.

`AT SELECTION-SCREEN ON P_BUKRS` checks `P_BUKRS` against `T001` and raises "Company code
does not exist" on failure. `P_SEGMNT`, `P_RLDNR` and `S_BLART` are **not** existence
checked — their customizing/check tables are not confirmed on this landscape.

### 6.2 Tables read

| Table | Used for | Read by |
|---|---|---|
| `KNB1` | company-code customers for `P_BUKRS`, restricted by `S_KUNNR` | `F_GET_CUSTOMERS` |
| `KNVV` | sales-area/division/group filter; the customer key once dedupe has run | `F_GET_CUSTOMERS` |
| `ZSD_EXP_PAINTS` | the driver — one approval row becomes one output row | `F_GET_APPROVALS` |
| `KNA1` | customer name | `F_GET_NAMES` |
| `UKMBP_CMS_SGM` | actual credit limit, keyed by partner + credit segment | `F_GET_CREDIT_LIMITS` |
| `T001` | company-code currency (ALV currency reference); `P_BUKRS` check | `F_GET_COMPANY_CURRENCY`; selection-screen validation |
| `ACDOCA` | collection document lines for the Actual Collection figure | `F_GET_COLLECTIONS` |

No sales-hierarchy table is read for L4/L5/L6 — see 6.3.6.

### 6.3 Processing logic

Execution order (`START-OF-SELECTION`):

```
F_GET_CUSTOMERS → F_GET_APPROVALS → F_GET_NAMES → F_GET_CREDIT_LIMITS
→ F_GET_COMPANY_CURRENCY → F_GET_HIERARCHY → F_GET_COLLECTIONS
→ F_BUILD_OUTPUT                                    (END-OF-SELECTION) → F_DISPLAY_ALV
```

Every database read happens once, outside any loop; every `FOR ALL ENTRIES` is guarded by
an `IS NOT INITIAL` check on its driver table.

#### 6.3.1 `F_GET_CUSTOMERS`

Reads `KNB1` for `P_BUKRS`/`S_KUNNR`, then `KNVV` for `S_VKORG`/`S_SPART`/`S_KVGR1`/
`S_KVGR2` against that customer list. Because `KNVV` is sales-area dependent, a customer
extended to several sales areas comes back more than once; the routine sorts by customer
and runs `DELETE ADJACENT DUPLICATES COMPARING KUNNR` so each customer appears **exactly
once** downstream, regardless of how many sales areas or divisions match. An empty result
at either step shows "No customers match the selection" and stops the report cleanly
(`LEAVE LIST-PROCESSING`) — no dump.

#### 6.3.2 `F_GET_APPROVALS`

Reads `ZSD_EXP_PAINTS` for the customer set of 6.3.1, filtered by `ZEXC_DATE_FROM IN
S_DATE`. One approval row becomes one output row. Field list order matches `TY_APPR`
component for component; `ZEXC_AMOUNT` is the DDIC-authoritative name used here, not the
FS output mapping's `ZEXC_AMNT` (§7 deviation 8). `ZEX_AMNT` is deliberately not selected
— no output column reads it. Result is sorted by customer/serial number so two runs of the
same selection compare the same way, and a deduplicated partner list is built to drive the
smaller downstream reads. Empty result: "No exceptional approvals found for the
selection", report stops.

#### 6.3.3 `F_GET_NAMES`

`KNA1-NAME1` for the partners found in 6.3.2. A partner with no `KNA1` row is not an
error — the name is left blank.

#### 6.3.4 `F_GET_CREDIT_LIMITS`

`UKMBP_CMS_SGM-CREDIT_LIMIT` for the same partners, restricted to `P_SEGMNT`. A partner
with no limit row in that segment is not an error — the limit stays zero and the
percentage calculation in 6.3.10 guards the division.

#### 6.3.5 `F_GET_COMPANY_CURRENCY`

One `SELECT SINGLE T001-WAERS` for `P_BUKRS` — the currency shown against every amount
column. `P_BUKRS` is already validated on the selection screen, so this is a defensive
fallback; failure shows a warning and the report still runs.

#### 6.3.6 `F_GET_HIERARCHY` — background call to the hierarchy report

Functional confirmed on 07/09/26 that the hierarchy report is to be run in background and
its output read, and that the program name printed in the FS is wrong and will be
corrected. The call is therefore built in full:

1. `TRDIR` is read for `GC_HIER_PROG` (`ZSD_CUSTOMER_DATA`). Unless it exists **and** is
   `SUBC = '1'` (executable), the FORM issues one status message and returns with the
   columns blank, and no `SUBMIT` is attempted.
2. The sales organisations from `S_VKORG` are copied into an `RSPARAMS` selection table
   under the name `GC_HIER_SELNAME`.
3. `CL_SALV_BS_RUNTIME_INFO` is armed with `display = abap_false`, the report is called
   with `SUBMIT (GC_HIER_PROG) WITH SELECTION-TABLE ... AND RETURN`, and its ALV result is
   taken with `GET_DATA_REF`. `CLEAR_ALL` runs on every path, so this report's own ALV is
   never swallowed by a capture left armed.
4. Result rows are read by field **name** through `ASSIGN COMPONENT`, so the callee
   structure need not be known at compile time, and are merged into `GT_CUST` on customer
   number after `CONVERSION_EXIT_ALPHA_INPUT`.

All six source names live in one `CONSTANTS` block, `GC_HIER_*`, immediately above the
selection screen. Correcting any of them is a change to that block and nothing else.

**Program name confirmed 07/09/26.** `GC_HIER_PROG` is `ZSD_CUSTOMER_DATA`, not the
`SAPLSLVC_FULLSCREEN` the FS printed. That name was the generic ALV full-screen function
group, `TRDIR` type `F`, which is neither a report nor `SUBMIT`-able. The guard now passes
and the call genuinely runs.

The remaining four constants are **placeholders**, not confirmed values, and nothing else in
the program guesses them. A wrong one degrades, it never dumps: a wrong select-option name
makes the callee run unfiltered (slower, same names reported, because the merge is on
customer key); a wrong customer field means nothing keys, and a status message says so
rather than leaving columns that look like missing master data; a wrong level field leaves
that level blank. See §7 deviation 1 / `ISSUES.md` #1 for how to read the real names off the
report's own layout.

**Watch in functional testing.** If `ZSD_CUSTOMER_DATA` carries an obligatory selection
field other than sales organisation, the `SUBMIT` stops on its own selection screen. That is
the one case the guards cannot cover, because its screen is not known here. Kept structurally identical to the Adhesives
FORM so that both reports fill from one confirmed source in one change.

#### 6.3.7 `F_GET_COLLECTIONS`

Reads `ACDOCA` **once** for the whole customer set. Before reading, the FORM scans every
approval row to find `lv_min_date` (the lowest `ZEXC_DATE_FROM`) and `lv_max_date` (the
highest `ZCOMMIT_DATE`) across the entire result set, and bounds the single read with them
— the per-row window applied in 6.3.8 is always a subset of what was read here.

```
SELECT rbukrs, gjahr, belnr, docln, budat, blart, kunnr, hsl FROM acdoca
FOR ALL ENTRIES IN @gt_cust
WHERE rldnr = @p_rldnr AND rbukrs = @p_bukrs AND kunnr = @gt_cust-kunnr
  AND budat BETWEEN @lv_min_date AND @lv_max_date
  AND blart IN @s_blart AND kunnr <> @space
```

No `GJAHR` filter — a collection window crossing a fiscal year boundary must not silently
lose rows (§7 deviation 6). If no approval row carries both ends of a usable window, or the
window is inverted, the FORM returns early and every Actual Collection is zero.

#### 6.3.8 `F_CALC_COLLECTION`

Pure in-memory arithmetic over the lines read in 6.3.7 — no database access. For one
approval row (customer, its own `ZEXC_DATE_FROM`, its own `ZCOMMIT_DATE`): an item counts
when `BUDAT >= date_from AND BUDAT <= commit_date`, summed as `HSL`, then `ABS()` is taken
— a customer collection is a credit and is held negative in `ACDOCA`; the FS reports it as
a positive receipt (§7 deviation 3, build spec C1). `GT_COLL` is a sorted table keyed on
`KUNNR`, so this is a keyed access per output row, not a linear scan. Applying **each
row's own window**, rather than one selection-screen range, is the settled reading of
Parth Shah's document comment and prevents one collection being double-counted across two
overlapping approvals for the same customer (ISSUES.md #5).

#### 6.3.9 `F_CALC_STATUS`

The two independent status readings, evaluated in this fixed order because the first two
Status-1 conditions can both be true at once:

**Status-1**
1. `cm_amnt - act_coll <= 0` → *Collection Received*
2. `commit_date > sy-datum` → *Commitment Not due*
3. otherwise (`commit_date <= sy-datum`) → *Commitment Overdue*

**Status-2**
- `commit_date > sy-datum` → blank — the commitment has not fallen due, so it is neither
  fulfilled nor unfulfilled (the "not yet arrived" case)
- `act_coll >= cm_amnt` → *Fulfilled*
- `act_coll < cm_amnt` → *Not Fulfilled*

Exact equality (`act_coll = cm_amnt`) is undefined in the FS and is treated as *Fulfilled*
(§7 deviation 12, ISSUES.md #12). Both statuses stay blank when `COMMIT_DATE` is initial —
there is no due date to judge against.

#### 6.3.10 `F_BUILD_OUTPUT`

Assembles one output row per approval row, in customer/serial-number order:

- **Customer/name/L4–L6**: looked up from 6.3.1/6.3.3/6.3.6.
- **Approval Month** = `ZEXC_APPR_MONTH+4(2) && '-' && ZEXC_APPR_MONTH(4)` — the stored
  `YYYYMM`'s tail is the month, not the head. A stored value outside 01–12 is shown blank
  rather than as a misleading string.
- **Approval Type**: `CASE` on `1`/`2`/`3` to readable text via text symbols, never `DD07T`
  — an unexpected code is shown as-is so bad master data stays visible.
- **Approval Date From/To, Exceptional Amount, Collection Commitment, Commitment Date,
  Remarks**: taken directly from the table row.
- **Actual Credit Limit**: from 6.3.4, zero if none in this segment.
- **Actual Collection** = `F_CALC_COLLECTION` (6.3.8) over this row's own window.
- **Non-Fulfilment Amount** = `ZCM_AMNT − Actual Collection` (§7 deviation 4, ISSUES.md
  #6) — the stated formula, not the sample row's arithmetic, which is the Adhesives
  formula copy-pasted.
- **Default %** = `(Non-Fulfilment Amount × 100) / Actual Credit Limit`, computed in a
  wider packed field first so an extreme ratio cannot overflow the 7,2 output field; a
  zero limit leaves the percentage blank rather than dividing by zero (§7 deviation 5,
  ISSUES.md #7).
- **Status-1/Status-2**: `F_CALC_STATUS` (6.3.9).
- **Currency**: the company-code currency of 6.3.5, carried on every row.

Unlike the Adhesives report, Actual Collection and Non-Fulfilment Amount are **not**
cleared when `COMMIT_DATE` is initial — build spec 6.3 point 9 restricts the blank rule to
the two statuses only, so such a row shows Actual Collection zero and Non-Fulfilment equal
to the full commitment amount, with both statuses blank to mark the row as incomplete. This
is a judgement call, not a numbered FS deviation; functional should confirm whether blank
amounts would read more clearly than a full-shortfall figure paired with a blank status.

#### 6.3.11 `F_DISPLAY_ALV`

Hand-built `LVC_T_FCAT`, one entry per column in `TY_OUTPUT` order via the `F_ADD_FCAT`
helper. `WAERS` carries the currency reference (`cfieldname = 'WAERS'`) on Exceptional
Amount, Collection Commitment, Actual Credit Limit, Actual Collection and Non-Fulfilment
Amount, and is itself marked `NO_OUT`. Zebra-striped, optimised column widths, full-screen
via `REUSE_ALV_GRID_DISPLAY_LVC` (`I_SAVE = 'A'`). A failed grid call shows "The report
list could not be displayed"; an empty result shows "No data to display for the
selection" before the grid is even called — neither dumps.

### 6.4 Output layout

One row per approval record, 20 visible columns plus one hidden currency-reference
column, in `TY_OUTPUT` order.

| # | Heading | Field | Currency ref | Notes |
|---|---|---|---|---|
| 1 | Customer Code | `KUNNR` | — | |
| 2 | Customer Name | `NAME1` | — | blank if no `KNA1` row |
| 3 | L4 Name | `L4_NAME` | — | **always blank** — stub, 6.3.6 |
| 4 | L5 Name | `L5_NAME` | — | **always blank** — stub, 6.3.6 |
| 5 | L6 Name | `L6_NAME` | — | **always blank** — stub, 6.3.6 |
| 6 | Approval Month | `EXC_MONTH` | — | `MM-YYYY` from `ZEXC_APPR_MONTH` |
| 7 | Serial Number | `EXC_NO` | — | `ZSD_EXP_PAINTS-ZSRN` |
| 8 | Approval Type | `EXC_TYPE` | — | text from fixed values, via text symbols |
| 9 | Approval Date From | `DATE_FROM` | — | `ZEXC_DATE_FROM` |
| 10 | Approval Date To | `DATE_TO` | — | `ZEXC_DATE_TO` |
| 11 | Exceptional Amount | `EXC_AMNT` | `WAERS` | `ZEXC_AMOUNT` |
| 12 | Collection Commitment | `CM_AMNT` | `WAERS` | `ZCM_AMNT` |
| 13 | Commitment Date | `COMMIT_DATE` | — | `ZCOMMIT_DATE` |
| 14 | Actual Credit Limit | `CREDIT_LIMIT` | `WAERS` | for `P_SEGMNT`; zero if none |
| 15 | Actual Collection | `ACT_COLL` | `WAERS` | over the row's own window, 6.3.8 |
| 16 | Non-Fulfilment Amount | `NON_FULFIL` | `WAERS` | `ZCM_AMNT − Actual Collection` |
| 17 | Default % Non-Fulfilment | `DEF_PERC` | — | blank when credit limit = 0 |
| 18 | Status-1 | `STATUS1` | — | Collection Received / Commitment Not due / Commitment Overdue; blank if `COMMIT_DATE` initial |
| 19 | Status-2 | `STATUS2` | — | blank (not yet due) / Fulfilled / Not Fulfilled; blank if `COMMIT_DATE` initial |
| 20 | Remarks | `REMARKS` | — | `ZREMARKS` |
| — | Currency | `WAERS` | — | hidden (`NO_OUT`); drives columns 11/12/14/15/16 |

---

## 7. Assumptions and deviations from the FS

Every row carries an `" ASSUMPTION:` comment at the matching point in the source.

| # | FS says | Build does | Why | ISSUES.md |
|---|---|---|---|---|
| 1 | L4/L5/L6 from `SAPLSLVC_FULLSCREEN` | Background `SUBMIT` of **`ZSD_CUSTOMER_DATA`** + ALV capture. Program name confirmed 07/09/26; its select-option and ALV field names are still placeholders in `GC_HIER_*` | `SAPLSLVC_FULLSCREEN` is the generic ALV function group, `TRDIR` type `F`, not an executable report | #1 part-open |
| 2 | Info Category / Info Type required on the screen | Omitted | the Z table has no such field to filter on | #10 |
| 3 | Actual Collection `BUDAT` from the selection screen | Per row, `ZEXC_DATE_FROM` to `ZCOMMIT_DATE` inclusive | reviewer comment, and a shared range would double count | #5 |
| 4 | Sample row implies Actual minus Credit Limit | `ZCM_AMNT` minus Actual Collection | the prose states the formula twice, the sample is the Adhesives formula copy-pasted | #6 |
| 5 | Default % over Actual Credit Limit | followed as written, zero guarded | looks like the wrong denominator for a collection shortfall, but it is what the FS states | #7 |
| 6 | `GJAHR` filter on `ACDOCA` | No `GJAHR` filter, `BUDAT` bounded instead | a window crossing a fiscal year would otherwise lose rows | — |
| 7 | Ledger `0L`, document type `DZ` hardcoded | selection screen fields carrying those defaults | no hardcoded values (house rule) | — |
| 8 | `ZEXC_AMNT` in the output mapping | `ZEXC_AMOUNT` | the DDIC definition is authoritative | #8 |
| 9 | `ZEX_AMNT` declared | built, loaded by the upload program, never read by the report | no output column uses it | #8 |
| 10 | no currency field on the table | `WAERS` added | a CURR field cannot activate without one | #9 |
| 11 | no audit fields | `ERNAM`/`ERDAT`/`AENAM`/`AEDAT` added | TMG plus mass upload with no other audit trail | #9 |
| 12 | Status-2 equality undefined | equality treated as Fulfilled | the FS covers only strictly greater and strictly less | #12 |
| 13 | no credit segment on the screen | `P_SEGMNT` added, obligatory, **defaults to 2000** | `CREDIT_LIMIT` is per segment. Segment 2000 confirmed by functional 07/09/26 | #16 closed |
| 14 | Serial No. source unstated | required as a file/SM30 input, no number range | no SNRO object confirmed; can be added later without changing this build | #9 |

One additional judgement call, not a numbered FS deviation: the amount columns (Actual
Collection, Non-Fulfilment Amount) are **not** cleared when `COMMIT_DATE` is initial —
only the two statuses are, per build spec 6.3 point 9 (see 6.3.10). Flagged for functional
sign-off alongside the table above.

---

## 8. Open points still needing a functional answer

Ranked by what changes a number or a column on the report or the upload log, not by
`ISSUES.md` order.

1. **ISSUES.md #1 — L4/L5/L6 source.** Shared with 141.A. The only columns with no data at
   all. Needed: the real table/field, or a report name that can actually be read/submitted.
2. **ISSUES.md #6 — Non-Fulfilment formula.** Built as `ZCM_AMNT − Actual Collection`.
   Confirm this is right, not the sample row's `Actual − Credit Limit`.
3. **ISSUES.md #5 — Actual Collection date window.** Built as each row's own
   `ZEXC_DATE_FROM`–`ZCOMMIT_DATE`. Confirm this, not a shared selection-screen range.
4. **ISSUES.md #7 — Default % denominator.** Built over Actual Credit Limit, as the FS
   literally states, for a figure that is a collection shortfall. Confirm the denominator.
5. **ISSUES.md #8 — Field names.** `ZEXC_AMOUNT` is built as the DDIC name. Separately,
   confirm whether `ZEX_AMNT` is a genuine second figure the business needs or a duplicate
   of `ZEXC_AMOUNT` safe to drop.
6. ~~**ISSUES.md #16 — Credit segment.**~~ **Closed 07/09/26.** Functional confirmed
   segment `2000`. `P_SEGMNT` now defaults to it and stays overridable.
7. **ISSUES.md #10 — Info Category / Info Type.** Dropped from the selection screen because
   `ZSD_EXP_PAINTS` has no such field. Confirm: drop from the FS permanently, or add the
   fields to the table (a DDIC change, not a code-only fix).
8. **ISSUES.md #12 — Status-2 equality boundary.** Confirm *Fulfilled* (current build) is
   correct for an exact match between Actual Collection and Collection Commitment.
9. **ISSUES.md #13 — Sales-area duplication.** Confirm one row per customer (current build)
   is wanted, as opposed to one row per sales area/division.
10. **ISSUES.md #9 — Table gaps.** Confirm the added `WAERS` and audit fields
    (`ERNAM`/`ERDAT`/`AENAM`/`AEDAT`), the `YYYYMM` storage of the month, and the Serial No.
    source — file/SM30 input today, no SNRO object.
11. **ISSUES.md #15 — Authorization.** No object or check is built; the TMG carries the
    placeholder authorization group `&NC&`. Needed: the real group and object, and whether
    this table is maintained in DEV-and-transport or directly in production.
12. **`ZSD_EXP_PAINTS_DDIC.md` §1.4 — CURR length 23.** The FS figure is unusually wide
    against a standard 13,2/15,2 amount field; flagged as a runtime-overflow risk for any
    later interface, not an activation risk. Confirm the width, or accept 23 as built.
13. **Judgement call, §7 note.** Confirm whether Actual Collection/Non-Fulfilment should be
    blanked, not computed, on a row with no commitment date — currently they are computed
    against zero while both statuses stay blank.

---

## 9. Unit test scenarios

Covers both `ZSD_EXP_PAINTS_UPLOAD` and `ZSD_EXC_APPR_PAINTS`. Validation-class numbers
match build spec §5.3.

| # | Object | Scenario | Input | Expected result |
|---|---|---|---|---|
| 1 | Upload | Clean upload, insert mode | The three-row worked example of `ZSD_EXP_PAINTS_UPLOAD_TEMPLATE.md` §4, `P_INS`, `P_TEST` off | All 3 rows written; log shows green light / *Inserted* on each; summary "Rows read: 3 valid: 3 written: 3 in error: 0" |
| 2 | Upload | Validation class 1 — serial number | Row with `ZSRN` blank; another with `ZSRN` = `12A34` | Row 1 rejected E01 "Serial number is missing"; row 2 rejected E02 "Serial number must be numeric, up to 10 digits" |
| 3 | Upload | Validation class 2 — customer existence | Row with a `ZCUSTOMER` value not present in `KNA1` | Rejected E20 "Customer does not exist in KNA1" |
| 4 | Upload | Validation class 3 — approval month | Row with `ZEXC_APPR_MONTH` = `13-2026` | Rejected E06 "Approval month is not in MM-YYYY format" |
| 5 | Upload | Validation class 4 — approval type | Row with `ZEXC_APPR_TYPE` = `4` | Rejected E08 "Approval type must be 1, 2 or 3" |
| 6 | Upload | Validation class 5 — date parsing | Row with `ZEXC_DATE_FROM` = `31.02.2026` (not a real date) | Rejected E10 "Approval date from is not a valid date" |
| 7 | Upload | Validation class 6 — date order | `ZEXC_DATE_FROM` = `25.07.2026`, `ZEXC_DATE_TO` = `20.07.2026` | Rejected E12 "Approval date to is before approval date from" |
| 8 | Upload | Validation class 7 — amount format | `ZEXC_AMOUNT` = `1.234,56` (continental notation) | Rejected E14 "Exceptional amount is not a valid number" — never silently read as a wrong figure |
| 9 | Upload | Validation class 8 — currency existence | `WAERS` = `XXX`, not in `TCURC` | Rejected E21 "Currency does not exist in TCURC" |
| 10 | Upload | Validation class 9 — duplicate key in file | Two file rows both with `ZSRN` 1 / `ZCUSTOMER` 1009024 / `ZEXC_APPR_MONTH` 07-2026 | First row processed normally; second rejected E22 "The same key is already used in file row 2" (naming the first row's number) |
| 11 | Upload | Validation class 10a — key exists, insert mode | File row's key already on `ZSD_EXP_PAINTS`, `P_INS` selected | Rejected E23 "Record exists already - use the change mode" |
| 12 | Upload | Validation class 10b / insert vs. change mode | Same file and key as #11, re-run with `P_UPD` selected | Row updated, not rejected; log shows *Changed*; `AENAM`/`AEDAT` set from the run; `ERNAM`/`ERDAT` carried forward from the existing row, not overwritten |
| 13 | Upload | Test run | Any valid file, `P_TEST` = `X` | Log shows *Would insert*/*Would change* with green lights; nothing written to `ZSD_EXP_PAINTS`; summary appends "TEST RUN - nothing was written" |
| 14 | Upload | Remarks truncation | `ZREMARKS` column with 300 characters | Row stays valid; text truncated to 250 characters; log carries the note "Remarks truncated to 250 characters, file length 300" alongside the outcome |
| 15 | Report | Empty customer selection | `P_BUKRS`/`S_VKORG`/`S_SPART` combination matching no `KNB1`/`KNVV` row | Message "No customers match the selection"; report stops, no ALV shown |
| 16 | Report | No approvals for a valid customer set | Customers found, but no `ZSD_EXP_PAINTS` row matches `S_DATE` | Message "No exceptional approvals found for the selection"; report stops |
| 17 | Report | Customer in more than one sales area | One `KUNNR` extended to two `VKORG`/`SPART` combinations that both satisfy the selection | Customer appears exactly once in `GT_CUST`, therefore at most once per approval row — never duplicated by sales area |
| 18 | Report | Zero credit limit | Approval row for a customer with no `UKMBP_CMS_SGM` row in `P_SEGMNT` (or `CREDIT_LIMIT = 0`) | Actual Credit Limit = 0; Default % blank (no division by zero); Non-Fulfilment Amount still computed as `ZCM_AMNT − Actual Collection`; Status-1/Status-2 derived normally from that amount |
| 19 | Report | Status ladder — collection already received | `ZCM_AMNT` 100,000, Actual Collection 100,000 or more | Status-1 = "Collection Received" (takes priority even if the commitment date has not yet arrived) |
| 20 | Report | Status ladder — commitment not yet due (not-yet-arrived case) | `ZCOMMIT_DATE` later than `sy-datum`, `ZCM_AMNT` not yet fully collected | Status-1 = "Commitment Not due"; Status-2 = blank (neither Fulfilled nor Not Fulfilled) |
| 21 | Report | Status ladder — overdue and not fulfilled | `ZCOMMIT_DATE` on or before `sy-datum`, Actual Collection less than `ZCM_AMNT` | Status-1 = "Commitment Overdue"; Status-2 = "Not Fulfilled" |
| 22 | Report | Status ladder — overdue, exact equality | `ZCOMMIT_DATE` on or before `sy-datum`, Actual Collection exactly equal to `ZCM_AMNT` | Status-1 = "Collection Received" (the `<= 0` non-fulfilment test fires first); Status-2 = "Fulfilled" — boundary case, see ISSUES.md #12 |
| 23 | Report | Blank commitment date | Approval row with `ZCOMMIT_DATE` initial | Status-1 and Status-2 both blank; Actual Collection and Non-Fulfilment Amount still computed (see §7 judgement-call note), row is not dropped |
| 24 | Report | Collection outside the row's own window | An `ACDOCA` posting for the customer falls inside the outer read bound (§6.3.7) but before this row's own `ZEXC_DATE_FROM` or after its own `ZCOMMIT_DATE` | Excluded from this row's Actual Collection by `F_CALC_COLLECTION`'s per-row window, even though it was read into `GT_COLL` |

---

*End of technical specification — WRICEF 141.B, Exceptional Approval, Paints.*
