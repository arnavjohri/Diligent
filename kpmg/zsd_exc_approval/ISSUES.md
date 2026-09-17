# ISSUES — WRICEF 141 A/B Exceptional Approval

## 02/09/26 — FS review, questions raised before build

| # | Doc | Item | Problem | Needed from functional |
|---|-----|------|---------|------------------------|
| 1 | A+B | L4/L5/L6 Name | FS says "Submit program SAPLSLVC_FULLSCREEN, fetch L4 Name". That is the generic ALV full-screen function group — not a program, not SUBMIT-able, holds no data. | Real source: report name, or the table/field holding the sales hierarchy (KNVP partner functions? Z hierarchy table? HR org level?) |
| 2 | A | Exceptional Approval Type | Sample column shows "Not Feasible"; stated values are Credit Limit / Order / Both. No source field given in the output mapping. | Which BP3100 field carries it — INFOTYPE? |
| 3 | A | Commitment Date | Mapped to BP3100-TEXT, a free-text field. Unparseable in the general case. | Agreed entry format, and behaviour when a row does not parse |
| 4 | A | Actual OS as on Commitment Date | BSID holds open items *as of now*, not as of a past date — needs BSID + BSAD with AUGDT > commitment date. Also WRBTR is document currency vs credit limit in segment currency, and GJAHR is not on the selection screen. | Confirm as-on-date logic, currency, and where GJAHR comes from |
| 5 | B | Actual Collection date range | Mapping table says BUDAT from selection screen; Parth Shah's comment says "collection received during the approval date & commitment date" (per row). Contradiction. | Which one applies |
| 6 | B | Non-Fulfilment Amount | Stated formula = Collection Commitment − Actual Collection. Sample row (100,000 / 125,000 → 25,000) is Actual − Credit Limit, i.e. copied from the Adhesives doc. Sign is opposite. | Confirm formula and sign convention |
| 7 | A+B | Default % of Non-Fulfilment | Divides by Actual Credit Limit — undefined when limit is 0. For Paints, dividing a collection shortfall by the credit limit looks wrong. | Confirm denominator + zero-limit handling |
| 8 | B | Field names | Table declares ZEXC_AMOUNT and ZEX_AMNT (both "Exceptional ... Amount"); output maps ZEXC_AMNT, which matches neither. | Confirm final field names and whether both amount fields are really needed |
| 9 | B | Table definition gaps | No currency key field for the CURR amounts (cannot activate without one). "Month" given as length "MM-YYYY" — that is a format, not a length. SR. No. key has no stated number source (SNRO or manual). | Confirm CURKY field, month storage (recommend NUMC 6 YYYYMM, displayed MM-YYYY), and SR. No. numbering |
| 10 | B | Info Category / Info Type | Both are *required* selection fields, but ZSD_EXP_PAINTS has no info category / info type field to filter on. | Drop them from the Paints selection screen, or add the fields to the table |
| 11 | A+B | "Date" selection field | Listed as required Range with no table/field. | Which date — approval date, commitment date, or posting date |
| 12 | B | Status - 2 | Uses > and < only; equality (collection exactly equals commitment) is undefined. | Confirm — assumed >= is Fulfilled unless told otherwise |
| 13 | A+B | Sales-area duplication | KNVV is sales-area dependent; a customer in several sales areas will multiply rows. | Dedupe rule, or accept one row per sales area |
| 14 | A+B | Output layout | Format shown as three stacked tables. | Confirm single flat ALV, one row per exception record, key columns repeated |
| 15 | A+B | Authorisation | FS says "Authorization TBD". | Auth object / check to build in |
| 16 | A+B | Actual Credit Limit | `UKMBP_CMS_SGM` is keyed by partner **and credit segment** — a customer with several segments has several CREDIT_LIMIT values. FS names neither a segment nor a rule. | Which credit segment: fixed default (0000?) or a selection-screen field |

## 07/09/26 — answers received, code updated for functional testing

| # | Answer received | What the code now does | Status |
|---|-----------------|------------------------|--------|
| 16 | Credit segment is **2000** | `P_SEGMNT` on both selection screens now defaults to `2000`. Kept as an overridable parameter, not a constant. | **Closed** |
| 1 | The hierarchy report is to be called in background and its output read. The program name in the FS is wrong and will be corrected. | `F_GET_HIERARCHY` in both reports now builds the call in full: TRDIR check, `SUBMIT ... WITH SELECTION-TABLE ... AND RETURN`, ALV capture via `CL_SALV_BS_RUNTIME_INFO`, dynamic field mapping, merge into the customer list. The unconfirmed names sit in one `GC_HIER_*` constants block. | **Partly answered — still blocked on the name** |

### Issue 1 — program name given 07/09/26, field names still placeholders

Arnav supplied the real source: **`ZSD_CUSTOMER_DATA`**. `GC_HIER_PROG` now carries it,
so the TRDIR guard passes and the `SUBMIT` genuinely runs. The other four constants are
still unconfirmed and are **not** guessed anywhere else in the code.

| Constant | Needs | Status |
|---|---|---|
| `GC_HIER_PROG` | the executable report that lists the sales hierarchy | **`ZSD_CUSTOMER_DATA` — confirmed 07/09/26** |
| `GC_HIER_SELNAME` | that report's SELECT-OPTION name for sales organisation | placeholder `S_VKORG` |
| `GC_HIER_F_KUNNR` | the customer field in its ALV output | placeholder `KUNNR` |
| `GC_HIER_F_L4` / `_L5` / `_L6` | the three level-name fields in its ALV output | placeholder `L4_NAME` / `L5_NAME` / `L6_NAME` |

What a wrong placeholder costs, none of it a dump:

- **`GC_HIER_SELNAME` wrong.** `SUBMIT` ignores an unknown `SELNAME`, so `ZSD_CUSTOMER_DATA`
  runs unfiltered. Slower, but the merge is on customer key so the names reported are still
  right for the customers on the report.
- **`GC_HIER_F_KUNNR` wrong.** Nothing keys. `F_GET_HIERARCHY` says so with a status message
  rather than showing blank columns that look like missing master data.
- **`GC_HIER_F_L4` / `_L5` / `_L6` wrong.** That level comes back blank.

To confirm them: run `ZSD_CUSTOMER_DATA`, use Settings → Layout → Current on its ALV for the
technical field names, and F1 on its sales-organisation field for the select-option name.

**Watch in functional testing:** if `ZSD_CUSTOMER_DATA` has an obligatory selection field
other than sales organisation, the `SUBMIT` stops on its own selection screen. That is the
one behaviour the placeholders cannot protect against, because we do not know its screen.

## Still open and genuinely blocking a correct number

These four cannot be assumed either way — each has two readings that produce different
figures on the same data, so a guess would ship a wrong number rather than a blank.

| # | Doc | Question |
|---|-----|----------|
| 2 | A | Which BP3100 field carries the Exceptional Approval Type. Column ships blank until answered. |
| 3 | A | The agreed entry format for the commitment date inside BP3100-TEXT, and what to do with a row that does not parse. |
| 5 | B | Actual Collection window: BUDAT from the selection screen, or per row from approval date to commitment date. Currently per row. |
| 6 | B | Non-Fulfilment sign: Commitment minus Actual Collection (the prose), or Actual minus Credit Limit (the sample). Currently the prose. |

Issue 15 (authorisation object) is still "TBD" in the FS. It does not block functional
testing, but it blocks the move to QA.

## 07/09/26 — BP3100 field names corrected

Arnav confirmed from the system that **BP3100 has no `INFOCATEGORY` / `INFOTYPE` column**.
The fields carrying the information category and information type are **`ADDTYPE`** and
**`DATA_TYPE`**. `ZSD_EXC_APPR_ADHESIVE` re-pointed throughout: the BP3100 read, both
parameters (now typed off `BP3100-ADDTYPE` / `BP3100-DATA_TYPE`), both F4 helps and both
selection-screen checks.

Business labels are unchanged — the screen still reads "Information Category" and
"Information Type", and the parameter names `P_INFCAT` / `P_INFTYP` keep that meaning, so
no selection text or message text moved.

`UKM_INFOCAT` and `UKM_INFOTYP` were dropped as the value-help and validation source. Now
that BP3100 uses different field names, the matching customizing field names are not
confirmed on this landscape, and a wrong table or field name costs an activation cycle.
Both F4 helps and both checks now read the distinct values present in BP3100 itself, which
cannot be wrong and, for a report, is the better list: only values that carry data can be
reported on. If those customizing tables do exist with usable field names and functional
wants the full list offered rather than the used list, that is a change to two SELECTs.

`ZSD_EXC_APPR_PAINTS` is unaffected — Info Category and Info Type were already dropped from
the Paints selection screen (issue 10), so it never referenced either field.

## 07/09/26 — all three programs activated

| Object | State |
|---|---|
| `ZSD_EXC_APPR_ADHESIVE` | **Active.** With the credit-segment default, the `ZSD_CUSTOMER_DATA` hierarchy call, and the ADDTYPE / DATA_TYPE correction. |
| `ZSD_EXC_APPR_PAINTS` | **Active.** With the credit-segment default and the hierarchy call. |
| `ZSD_EXP_PAINTS_UPLOAD` | **Active.** |

Activation of the two Paints programs proves the DDIC underneath them is active as well —
neither would syntax check otherwise. So SE11 steps 1 to 4 of `ZSD_EXP_PAINTS_DDIC.md` are
done: the 5 domains, the 6 data elements, table `ZSD_EXP_PAINTS` and its technical settings.

### What is left on the build

| Item | Blocking? |
|---|---|
| Table maintenance generator, function group `ZSD_EXC_PAINTS`, one step, screen 0001 (§4 of the DDIC sheet) | Not implied by activation — check SM30 opens on `ZSD_EXP_PAINTS`. Needed for single-record maintenance; the upload program covers mass entry without it. |
| Text elements on all three programs | Cosmetic. Every literal carries its own default, so all three run without them. |
| The four `GC_HIER_*` field names from `ZSD_CUSTOMER_DATA` | L4/L5/L6 stay blank until supplied. |
| Authorisation object (issue 15) | Blocks QA, not functional testing. |
| The four functional questions (issues 2, 3, 5, 6) | Each decides a number, not whether the program runs. |

### First-run order for functional testing

1. `ZSD_EXP_PAINTS_UPLOAD` with the test-run box ticked, on a small file. The log must come
   back clean before anything is written.
2. Same file with the box unticked, insert mode.
3. `ZSD_EXC_APPR_PAINTS` over the loaded rows.
4. `ZSD_EXC_APPR_ADHESIVE` against real BP3100 data.

On the first run of either report, watch whether `ZSD_CUSTOMER_DATA` stops on its own
selection screen. That is the one failure mode the `GC_HIER_*` guards cannot cover.

## 07/09/26 — issues 2 and 3 answered

| # | Answer | What changed in `ZSD_EXC_APPR_ADHESIVE` |
|---|---|---|
| 2 | The Exceptional Approval Type is **not required** on this report. | Column removed, not blanked. `EXC_TYPE` dropped from `TY_OUTPUT`, the `CLEAR` dropped from `F_BUILD_OUTPUT`, the field-catalogue entry dropped and the columns after it renumbered 8 to 18. Text symbol `C08` is now unused. **Closed.** |
| 3 | The commitment date in `BP3100-TEXT` is entered as **DD.MM.YYYY**. | `F_PARSE_COMMIT_DATE` narrowed. The bare 8-digit `YYYYMMDD` branch is removed. `/` and `-` are still normalised to `.` first, because those carry the same field order and accepting them costs one `REPLACE` and prevents a blank row when a user types a slash out of habit. **Closed.** |

Dropping the 8-digit branch makes the parse **stricter**, not weaker: an 8-digit run inside
free text is more likely to be an amount, a phone fragment or a document number, all of
which the old code would have read as a date.

`ZSD_EXC_APPR_PAINTS` is unaffected by issue 2. Its approval type column has a real source
field, `ZSD_EXP_PAINTS-ZEXC_APPR_TYPE`, mapped 1/2/3 to text symbols `T01` to `T03`, and it
stays.

### Note on the commitment date DISPLAY

`COMMIT_DATE` in the ALV is typed `DATS`, so SAP renders it in each user's own date format
from their user profile (SU3, Defaults tab). For an Indian profile that is already
DD.MM.YYYY. Forcing DD.MM.YYYY regardless of the user setting would mean converting the
column to a character field, which loses date sorting and date filtering in the ALV — not
recommended, but it is a small change if functional insists.


## 05/09/26 — full review of 141 A/B (recorded 17/09/26; the entry was lost in a merge)

| # | Doc | Item | Problem | Needed from functional / Arnav |
|---|-----|------|---------|--------------------------------|
| 17 | A | BP3100 category filter | The 05/09/26 repo copy filtered on `INFOTYPE` only, reasoning from the 02/09/26 syntax error. **Superseded 07/09/26**: the real columns are `ADDTYPE` and `DATA_TYPE`, and the program is active with both in the WHERE clause. | Nothing — closed by the 07/09/26 correction above. |
| 18 | A+B | BP number = customer number | `BP3100-PARTNER` and `UKMBP_CMS_SGM-PARTNER` are compared directly with `KUNNR`. Holds only with CVI same-number assignment. If not, A finds no approvals and both reports show zero limits. Tagged `ASSUMPTION` in both sources. | Confirm BP and customer share the number range (SE16N `CVI_CUST_LINK`, PARTNER_GUID vs CUSTOMER). |
| 19 | A | Actual OS composition | Every BSID/BSAD line is summed: normal receivables, special G/L items (down payments, bills of exchange, deposits) and noted items (down-payment requests). The FS draws no line; FBL5N would exclude noted items. Tagged `ASSUMPTION` in `F_GET_OPEN_ITEMS`. | Confirm whether special G/L and noted items count toward "Actual OS as on Commitment Date". |
| 20 | A | Division on the Adhesives screen | Yogesh Vanani's FS comment asks for division; the FS input table omits it. Built as an OPTIONAL range `S_SPART` (blank = all divisions), applied to the KNVV read. | Confirm optional is right, or make it obligatory as in Paints. |
| 21 | A | Commitment date spellings | The 05/09/26 copy also accepted a two-digit year and month-first order. **Dropped 07/09/26** when functional confirmed DD.MM.YYYY — the narrower parse of the 07/09/26 entry stands. | Nothing — closed with issue 3. |
| 22 | B | abapGit ZIP shape | `ZSD_EXC_APPROVAL.zip` rebuilt: DDIC XML element order corrected (DDTEXT after SIGNFLAG/VALEXI/LOWERCASE in DD01V; REFTABLE/REFFIELD before NOTNULL/COMPTYPE in DD03P), `REFKIND D` on the six data elements, `CLIDEP X` and `EXCLASS 4` on DD02V, selection-text LENGTH values corrected (+8), no directory entries. See `ZIP_IMPORT_NOTES.md`. | The DDIC objects were created by hand and are active since 07/09/26, so the ZIP is now a convenience for the two Paints programs only. Untested on the system. |
| 23 | — | Root cause of the `zfi_tds_cl34` import dumps | Its `.abapgit.xml` is wrapped in an `<abapGit ...>` element. abapGit reads `.abapgit.xml` with `CALL TRANSFORMATION id` directly (`zcl_abapgit_dot_abapgit=>from_xml`, the frame in the dump), which needs a bare `<asx:abap>` root. Object XML files, by contrast, MUST carry the wrapper. This folder's `.abapgit.xml` is bare and correct. | Nothing for functional. Recorded in `kpmg/zfi_tds_cl34/NOTES.md` and `CLAUDE.md`. |

Also done 05/09/26, no functional input needed: `GT_APPR` sorted by partner, date and
counter (A); commitment date linked to its approval row by position instead of by
PARTNER + COUNTER, which is not confirmed unique (A); BSID/BSAD and ACDOCA reads driven by
the approval partners instead of every customer of the company code (A and B); ASSUMPTION
tags for deviations 9/10/11 (A); `fs/141B_extract.md` added.

## 17/09/26 — functional testing: "L5 name is not coming"

Sanjay Modhvadiya reported on Teams, with screenshots of `ZSD_EXC_APPR_ADHESIVE`, that the
L4/L5/L6 columns are blank for every row (customers 0001000000 CPI Test Customer and
0001000724 IDS DISTRIBUTORS-F&S in the screenshots). The report otherwise runs.

### Root cause

The program name is right — `GC_HIER_PROG` = `ZSD_CUSTOMER_DATA` since 07/09/26 — so the
`SUBMIT` runs and the ALV capture returns data. What is still wrong is the **four field
names the program uses to read that data**, which were placeholders that were never
confirmed (issue 1 above): `KUNNR`, `L4_NAME`, `L5_NAME`, `L6_NAME`, plus the select-option
name `S_VKORG`. `ZSD_CUSTOMER_DATA` evidently names its columns differently. With the
07/09/26 code, a customer field that does not match gives message M16 and blank columns; a
level field that does not match gives **blank columns and no message**, which is what
Sanjay saw. The names cannot be confirmed from here: this repo does not hold
`ZSD_CUSTOMER_DATA`, and the system is not reachable.

### Fix applied — both reports, marked 17/09/26

| # | Change | Where |
|---|---|---|
| 26 | **Field names resolved at runtime.** `F_GET_HIERARCHY` now reads the callee's own structure with RTTI (`CL_ABAP_TABLEDESCR` → `CL_ABAP_STRUCTDESCR` → components) and resolves each of the four names through the new helper `F_HIER_FIELD`: the placeholder if the callee has that exact field, otherwise the first field whose name **contains** the level token (`L4`, `L5`, `L6`) or, for the customer, `KUNNR` and then `CUST`. A callee that calls the field `ZL5_NAME`, `NAME_L5` or `L5NAME` therefore maps without a code change. | A and B, `F_GET_HIERARCHY` step 4, new `F_HIER_FIELD` |
| 26a | **Diagnostics instead of silence.** When the customer field cannot be resolved (M16 / M10), when no level field can be resolved (new M17 / M11), or when everything resolves but not one callee row keys to a customer on the report (M16 / M10 again), the status message now ends with the callee's **actual field names**. The real `GC_HIER_*` values can then be read straight off the tester's status bar. An empty callee result gives M15 / M09 rather than a field-name message. | same |
| 26b | **Approval customers passed to the callee.** The partners in `GT_PARTNER` go into the `SUBMIT` selection table under the placeholder `GC_HIER_SELKUN` = `S_KUNNR`. A wrong name is ignored by `SUBMIT` (the callee runs for the whole sales organisation, as before); a right one makes it run for a handful of customers. | same, step 2 |

Placeholders still in the code, all in the `GC_HIER_*` block: `S_VKORG`, `S_KUNNR`,
`KUNNR`, `L4_NAME`, `L5_NAME`, `L6_NAME`. The runtime resolution makes the four field names
self-correcting for any sensible naming; the two select-option names are not resolvable at
runtime and simply fall back to an unfiltered run.

### What is needed to close issue 1 for good

Either of these, in this order of preference:

1. `ZR_PROG_DOWNLOAD` of **`ZSD_CUSTOMER_DATA`** into `incoming/` — its ALV structure and
   selection screen give all six names, and the token search can then be retired for the
   confirmed values.
2. Failing that, the **status-bar message text** after running the corrected
   `ZSD_EXC_APPR_ADHESIVE`: if the columns are still blank, the message now lists the callee's
   field names, which is enough to set the constants.

### To ship

The repo copies of both reports carry this fix; the active programs do not. Paste
`ZSD_EXC_APPR_ADHESIVE.abap` over the active program (diff against a fresh SE80 download
first, per the golden rule) and add text symbol `M17`; same for `ZSD_EXC_APPR_PAINTS.abap`
with `M11`. Text sheets and the ZIP are updated.

### 17/09/26 — drift check on the fresh download of `ZSD_EXC_APPR_ADHESIVE`

Arnav supplied the active program as an SE38 print (`original/ZSD_EXC_APPR_ADHESIVE.TXT`,
last changed 07.09.2026 by UDAYABAP03, 1590 source lines; de-paginated copy beside it as
`ZSD_EXC_APPR_ADHESIVE.from-print.abap`). **No drift**: it matches the 07/09/26 repo base
line for line. The single textual difference, a missing blank before `).` in the
`GET_DATA_REF` call, is the printer trimming a trailing blank where it wrapped the line
at 72 characters, not a code change.

So the repo copy (1919 lines) is the reconciled object: the active program plus the 17/09/26
changes, nothing lost. Paste it whole.

The print also lists what Goto → Text Elements holds in the system today: `001`, `002`,
`C01`–`C19`, `M01`–`M12`, `S01`, `S02`, and selection texts for the nine original fields.
After the paste, add:

| Tab | Add | Text |
|---|---|---|
| Text symbols | `M13` | Sales hierarchy report not found - L4/L5/L6 left blank |
| | `M14` | Hierarchy source is not an executable report - see TS |
| | `M15` | Hierarchy report returned no ALV data - L4/L5/L6 blank |
| | `M16` | Hierarchy field names do not match the report output |
| | `M17` | Hierarchy level fields not found in the report output |
| Selection texts | `S_SPART` | Division |

`C08` (Approval Type) is maintained but no longer referenced; it can stay or go. Every
message has a literal default, so the report runs correctly before the symbols are typed;
the symbols only matter for translation and for the selection text on `S_SPART`, which
shows as the technical name until it is entered.

### Also recorded 17/09/26

| # | Doc | Item | State |
|---|-----|------|-------|
| 24 | B | Overlapping approvals for one customer | Two approval rows whose windows overlap count the same ACDOCA posting against both. Tagged `ASSUMPTION` in `F_CALC_COLLECTION`; this is the per-row reading of issue 5 taken to its conclusion. | Confirm with issue 5. |
| 25 | U | Upload commit semantics | After `COMMIT WORK AND WAIT` a failed follow-on update no longer triggers a `ROLLBACK` that could not undo the committed rows anyway; the summary carries a warning (M06, "see SM13") instead. Amounts with more than two decimals are rejected rather than silently rounded. | None — repo copy only, not yet pasted over the active `ZSD_EXP_PAINTS_UPLOAD`. |

### 17/09/26 — corrected Adhesives pasted and activated; L4/L5/L6 still blank

Arnav activated the 17/09/26 object and ran it: columns still blank. He supplied a
screenshot of `ZSD_CUSTOMER_DATA` run on its own — an ALV grid titled "CUSTOMER DATA" with
columns Customer, Partner, Created On, Parent Customer, Parent Customer (second column,
heading cut), SOrg., DChl., Division, Title, Group, Customer Class, Country, and more to the
right of the scroll. **No column in view is a level name.** So either the level names are
further right under headings the token search does not recognise, or the callee does not
output them as columns at all and derives them from the parent-customer chain, or the
capture itself failed (a `CL_GUI_ALV_GRID` in a custom container is not captured by
`CL_SALV_BS_RUNTIME_INFO`; only `REUSE_ALV_*` and `CL_SALV_TABLE` are).

Which of the three it is shows in the status bar after the run — M15 (nothing captured),
M17 (no level field; the message lists every field name), or M16 (customer field / merge).
Not yet reported. Also open: whether the callee's own screen appeared during the Adhesives
run (it would, if the display could not be suppressed).

Needed to finish: `ZR_PROG_DOWNLOAD` of `ZSD_CUSTOMER_DATA`. With the source, the
recommendation is to read the hierarchy the same way that program does, directly inside
`F_GET_HIERARCHY`, and drop the `SUBMIT` — no capture, no field-name guessing, no callee
screen. The "Parent Customer" columns suggest the SAP customer hierarchy (`KNVH`), but the
level convention is not to be guessed.

### 17/09/26 — `ZSD_CUSTOMER_DATA` source received: the levels are a table read

Arnav supplied the SE38 print of `ZSD_CUSTOMER_DATA` (3607 lines, last changed 02.09.2026;
filed as `original/ZSD_CUSTOMER_DATA.TXT` with a de-paginated copy beside it). Findings:

| What | Found |
|---|---|
| Display | `REUSE_ALV_GRID_DISPLAY` — capturable, so the morning's SUBMIT path would have worked once the names were set |
| Selection screen | `S_KUNNR` (`KNA1-KUNNR`), `S_VKORG` obligatory, `S_VTWEG`, `S_SPART`, `S_VKBUR`, `S_AUFSD`, `S_KNKLI`, three checkboxes — both placeholder select-option names were right |
| ALV level fields | `LCATEGORY4` / `LNAME4`, `LCATEGORY5` / `LNAME5`, `LCATEGORY6` / `LNAME6` — not `L4_NAME`, and not containing the token `L4` either, which is why the morning's runtime resolution also came up empty (message M17) |
| Where the names come from | Table **`ZSD_CUSTEMP_ASSG`**: `KUNNR`, `LCATEGORY` (`L1`–`L6`), `LID`, `STARTVAL`, `ENDVAL`, `LNAME`. The report reads the rows with `STARTVAL <= SY-DATUM <= ENDVAL` for its customers and copies `LNAME` into `LNAME1`–`LNAME6` by `LCATEGORY` |
| Also in the callee | An `AUTHORITY-CHECK` on `Z_CT_VKORG` per sales organisation that ends the program with an E message when it fails — a SUBMIT from the report would have inherited that |

| # | Change | Where |
|---|---|---|
| 27 | **Direct read replaces the SUBMIT.** `F_GET_HIERARCHY` in both reports now selects `KUNNR`, `LCATEGORY`, `LNAME` from `ZSD_CUSTEMP_ASSG` for the approval partners, levels `L4`/`L5`/`L6`, valid on `SY-DATUM`, and copies `LNAME` into the customer list by level — exactly the callee's own logic, without running a 3600-line report, its authorisation check and an ALV capture per run. The SUBMIT, the capture, `F_HIER_FIELD` and the `GC_HIER_*` constants are commented out, not deleted. New constants `GC_LCAT_L4/5/6`. The three level-name fields are typed off `ZSD_CUSTEMP_ASSG-LNAME` so a name is never truncated. When no selected customer has a valid row, status message M18 (A) / M12 (B) says so. Tagged `ASSUMPTION`: hierarchy as valid today, as the callee shows it; last valid row wins for a duplicated level, as in the callee. | A and B, `F_GET_HIERARCHY`, `CONSTANTS`, `TY_CUST`, `TY_OUTPUT` |

Text symbols: A retires `M13`–`M17` and adds `M18`; B retires `M07`–`M11` and adds `M12`.
New numbers on purpose — a maintained old symbol would otherwise show its old text for the
new message. DDIC names `ZSD_CUSTEMP_ASSG-KUNNR/LCATEGORY/LNAME/STARTVAL/ENDVAL` are proven
by the callee's own activation.

**Issue 1 closes with this** once functional confirms the names on the report match
`ZSD_CUSTOMER_DATA` for the same customers. Not yet activated on the system.
