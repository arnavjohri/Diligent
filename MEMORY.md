# MEMORY — standing recall for every session

**Written 22/09/26.** This file exists so that nothing established at cost has to be
re-derived, and so that no mistake already made gets made again.

`CLAUDE.md` is the rulebook — *what to do*. This file is the memory — *what we already
know, and what already went wrong*. Read `CLAUDE.md` first; read §3 and §5 of this file
before touching CDS/RAP or any object that ships.

**Why it lives in the repo.** Claude Code sessions here run in an ephemeral container
cloned fresh from GitHub. `~/.claude/projects/.../memory/` **does not survive** — it was
empty at the start of this session, so the release-constraints memory file `CLAUDE.md`
points at was not readable. Anything that must be recalled has to be committed. A file
outside the repo is a file that will be lost.

---

## 1. Identity, systems, and the facts that don't change

| Fact | Value |
|---|---|
| Who | Arnav Johri, Associate Consultant, Diligent Tech India Pvt. Ltd. |
| Live projects | **OVL** (ONGC Videsh, ECC→S/4) and **KPMG**, concurrently; plus `gail/`, `mwc/`, `rws/`, `pal/` |
| Change-marker author, repo work | `Arnav` |
| Change-marker author, OVL / ATC | `SAP_ABAP` — never `ABAP7` (cipla) or `EJX9007359` (coke/CCEJ) |
| Marker date format | `DD/MM/YY` with slashes. Object **header** blocks use `DD.MM.YYYY` with dots. Do not conflate |
| Today, as this was written | 22/09/26 |
| OVL system | **OCQ**, client 500. Older S/4 release. No ADT connection, no outbound internet |
| Transfer into SAP | abapGit standalone (offline ZIP) or copy-paste from SE80. Nothing else |
| `abap-adt` MCP | Points at `192.168.11.21` client 200 — a **different** system. Scratch syntax rig only, when explicitly asked. Never `setObjectSource` / `activateByName` / `deleteObject` against a project object |
| Mass download helper | `ZR_PROG_DOWNLOAD` — pulls a program with its full include tree (also FGs/classes, by package or name list) |
| Not on any machine | `DDLS_BASE_FIELDS.txt`, `ARS_API_SUCCESSOR.xlsx`. CDS element names cannot be re-verified — use only mappings already written down |

**Assume no system access.** Never propose "let me check table X in your system". Reason
from the code and SAP knowledge, or give the exact SE16/SE11/tcode navigation for Arnav.

---

## 2. Process rules that have already cost a rebuild

### 2.1 Never trust the repo copy as current

Before changing any object, ask for a fresh SE80 download unless one was supplied this
session. Diff it against the repo copy **first** and report drift before applying a fix.
Unreported drift is how a fix silently reverts someone else's change.

**And never trust `main` either.** Run `git log --all -- <object path>` before building.
Twice — 03/09/26 and 15/09/26 — work was built on a base that `main` carried but a branch
had superseded, and both times the delivered ZIP overwrote real work in the system.

### 2.2 First action of any session that will touch code

```
./scripts/sync.sh --pull-only
```

This is the drift check in git terms. It does **not** replace asking for a fresh SE80
download, which catches changes made inside SAP.

### 2.3 Every file that matters lives in the repo

Corrected objects, originals, ZIPs, patch sheets, TS documents, `ISSUES.md`, `NOTES.md` —
under `<client>/<object>/` from the repo root. Never a scratchpad or temp directory: a
file outside the repo is invisible to git, `sync.sh` reports "nothing to commit", and the
work dies with the session. The scratchpad is for a diff being inspected and nothing else.

### 2.4 Push every code update, to `main`

`./scripts/sync.sh "<what changed>"` as the last step of any reply that wrote or changed
an object file. Report the commit hash with the file path. **Single branch `main`** — if a
session starts on another branch, merge it into `main` and push that. Standing
instruction; not something to ask about each time.

### 2.5 One object at a time, then stop

Name the object so Arnav knows what to create in ADT, then wait for *activated, give the
next* or a pasted activation error. Never dump twelve objects at once. When he pastes an
error: fix that error and return the corrected object — do not explain at length first.

### 2.6 Complete objects, never fragments

`" ... existing code ..."` or "rest unchanged" is a failure. If it was 866 lines before it
is ≥866 after; state the before/after count. Chat gets the root cause, a change table and
the file path — not a 2000-line dump.

### 2.7 Line numbers drift

Line numbers in ATC worklists, patch sheets and any snapshot are snapshot-bound. Locate by
FORM / MODULE / METHOD name, never by line number. Arnav fixes things by hand between
runs, so a finding list is never assumed current — re-check before "fixing" what is fixed.

---

## 3. The ABAP coding standard, in force on every object

### 3.1 Change markers

```
*BOC By <author> on DD/MM/YY
...new or replacement code...
*EOC By <author> on DD/MM/YY
```

Single line: append `"Changes by <author> on DD/MM/YY`.

- **Comment old code out with `*`, never delete.** The commented original stays inside the
  block. New code goes **below** the commented original.
- **Never nest or double-wrap.** If a block already carries markers, extend it. Live
  defect, not hypothetical: 7 lines in the delivered OVL corrections read
  `" " Code Remediation changes S4 …BEGIN OF CHANGE…` — a marker that got re-commented.
- The date is the date the change is made — never copied from a sample file.
- ATC variant, matching the 205 existing pairs in the delivered corrections:
  `*--- BEGIN OF CHANGE BY SAP_ABAP <date> FOR ATC ---` / `*--- END OF CHANGE … ---`.
  If the file already carries ZATC-style markers, extend that style instead.

### 3.2 Open SQL — strict form, and the clause order

```abap
SELECT f1, f2 FROM src [FOR ALL ENTRIES IN @itab] [WHERE …] [GROUP BY …] [HAVING …]
       [ORDER BY f1, f2] INTO|APPENDING @tgt [UP TO n ROWS] [OFFSET n].
```

- Comma-separated field list **and** comma-separated `ORDER BY` list.
- `@`-escape every host variable, host expression and inline declaration — including
  `INTO @lt_tab`, `INTO @DATA(ls)` and `FOR ALL ENTRIES IN @itab`. All mandatory.
- **Escape the RHS only.** The column on the left of a `WHERE` stays bare:
  `WHERE vbeln = @itab-vbeln`. Never double-`@` an `@DATA( … )`.
- **`INTO` comes after `ORDER BY` but is not last** — `UP TO n ROWS` / `OFFSET` follow it.
  `… ORDER BY f1 INTO @tgt UP TO 1 ROWS.` is correct.
  `… ORDER BY f1 UP TO 1 ROWS INTO @tgt.` is invalid. "INTO last" is wrong as a flat rule.
- `%_HINTS` follows those and carries the terminating period — removing a `%_HINTS` line
  strips the `.` from the statement. Emit a lone `.` at the same indent. Remove only
  non-HANA hints (MSSQLNT / ORACLE / DB6); keep `%_HINTS HDB`.
- **`ORDER BY PRIMARY KEY` only on `SELECT *`** (or a full key in key order). On a
  projection: `ORDER BY <selected key fields>`, or drop it. This is the single most common
  defect in the delivered OVL batch — **26 sites**.
- Converting `SELECT SINGLE` to loop form: strip the **`SINGLE`** keyword. Leaving it gives
  *"ORDER is not allowed here. '.' is expected."*
- **`IS NOT INITIAL` guard before every `FOR ALL ENTRIES`.** An empty driver makes the
  kernel drop the WHERE and scan the whole table → `TSV_TNEW_PAGE_ALLOC_FAILED`.
- **`ORDER BY` is not allowed with `FOR ALL ENTRIES`** — close a NOORDER finding on an FAE
  SELECT with `"#EC CI_NOORDER`, not an ORDER BY.
- Dropping `CLIENT SPECIFIED` means dropping `mandt` from the field list and the WHERE too.
  Illegal on compatibility **views** (`DBSQL_ILLEGAL_CLIENT_SPECIFIED`): MBEW, MSEG, MKPF,
  FAGLFLEXA, BSID/BSAD, KONV/PRCD_ELEMENTS. Legal on real transparent tables (INOB, KSSK,
  KLAH, BKPF, all `Z*`) — leave those alone.
- No `SELECT` inside a `LOOP` where `FOR ALL ENTRIES` or a join would do.
- `DELETE ADJACENT DUPLICATES` needs a matching `SORT` **outside** any loop, on exactly the
  fields the DELETE compares.
- Never mass-regex across SELECT bodies or whole programs. Targeted edits only.

### 3.3 Field list ↔ target type is matched by POSITION, not by name

Strict ABAP SQL assigns `INTO TABLE @itab` slot by slot. Insert a field in the SELECT
without inserting it at the same index of the `TYPES` and you silently fill the wrong
component — or, when the types differ, fail activation with
`component "X" … not compatible with "Y"`, naming two fields that look unrelated.
**Re-check both lists together after any edit.**

### 3.4 Pseudo-comments

- One `#EC` per line, maximum. A second finding on the same line → real-fix it.
- A `#EC` **must start with `"`** — it is a comment. On a line that already has a `"`
  comment the `#EC` goes *inside* that comment; never add a second `"`.
- No P1 pseudo-comments without Arnav's explicit approval. P2/P3 may be pragma'd; P1s go on
  a separate manual-review list.
- Markers are for real structural fixes. A pure P2/P3 pseudo gets an inline `#EC` and no
  BEGIN/END block.
- Tokens: `CI_FLDEXT_OK[<note>]`, `CI_NOORDER` (bare), `CI_USAGE_OK[<note>]`,
  `CI_DB_OPERATION_OK[<note>]`, `CI_EXECSQL`.

### 3.5 General

- Change only what the issue calls for. **State explicitly what was deliberately not
  touched, and why.**
- No hardcoded clients, dates or company codes unless the FS says to hardcode.
- Error paths give the user a message — no short dump, no silent skip.
- Selection texts and column headings are readable words, not technical names.
- Never modify a standard SAP object. Changes go into a `Z` copy. Create custom includes
  only where an include actually changed — never blanket-Z every include.
- Build nothing the FS or the issue did not ask for.
- Flag risky assumptions in the code as `" ASSUMPTION: …` so they are greppable, and in the
  reply — never bury them.
- **Keep source lines under ~120 characters.** SE38 wraps a long line on paste: the tail
  lands on the next line without its `"` prefix and becomes a bogus statement, reported as
  `"<WORD>" is invalid here (due to grammar)` at a line that looks innocent. Long
  `" ASSUMPTION:` notes go in a `*` block above the statement, not trailing it.

### 3.6 The auditor

`./scripts/abap-audit.py <folder|file> [--md report.md]` checks source against these rules:
`ORDER_PRIMARY`, `CLAUSE_ORDER`, `INTO_BEFORE_FROM`, `INTO_NO_AT`, `WHERE_NO_AT`,
`FAE_NO_AT`, `FAE_NO_GUARD`, `SELECT_IN_LOOP`, `SELECT_ENDSEL`, `ENDSELECT`, `DAD_NO_SORT`,
`CLIENT_MANDT`, `HARDCODED`, `DUP_INLINE_DATA`, `EC_DOUBLE`, `OFFSET`, `READ_ERROR`.
It reads source, it does not compile — findings are candidates for review.

---

## 4. Release constraints on OCQ — confirmed by activation failure

**Apply pre-emptively.** Every row below is a real error hit on this system and the fix
that worked. This table is the asset — append to it whenever a new one is found.

### 4.1 CDS / RAP

| Problem | Fix that works |
|---|---|
| `Function YEAR is unknown` / `MONTH is unknown` | Derive from the date string: `substring(dats,1,4)`, `substring(dats,5,2)` |
| `Number of function parameters for DATS_ADD_MONTHS is not as expected: 2 <> 3` | 3rd arg is required: `dats_add_months(date, -3, 'INITIAL')` |
| `CAST of type INT4 to type NUMC is not possible` | INT↔NUMC casts are not allowed. Stay in CHAR: `cast( substring(…) as abap.numc(n) )`. Map month→fiscal period with a literal `CASE`, never arithmetic |
| `Annotation 'Semantics.calendar.date' unknown` / `Semantics.unitOfMeasure is not allowed in view entities` | Strip all `@Semantics.*` from view entities |
| `…-PRODQTY1 reference information missing or data type wrong` | Cast QUAN fields to `abap.dec(23,3)` to drop the unit-reference requirement |
| `Annotation 'Analytics.settings.maxResultSize' unknown`, `'MappingRole' used at wrong position`, `@Consumption.valueHelp` without the association | Remove them |
| `Unexpected word "-"` on a parameter / `Parameter P_X has no data type` | Parameter typing as `table-field` is not supported, and OData needs a **data element**: dates→`datum`, year→`gjahr`, asset→`oiu_dn_no`, target code→`ztar_code` |
| `Annotation 'ANALYTICS.QUERY' is not supported (Entity: …)` | `@Analytics.query: true` / `@Analytics.dataCategory: #CUBE` **cannot be exposed in an OData V4–UI service binding**. Convert to plain keyed view entities (drop `@Analytics*`, add keys, keep parameters). Don't expose cubes |
| `Entity type … has no key field assigned` / `Key must be contiguous and start at the first position` | Keys first and contiguous in the field list |
| `Unexpected keyword "case"` in GROUP BY | `CASE` is not allowed in `GROUP BY`. Add a helper view exposing the classified column and group on it (this is why `ZPRA_P_DPR_TAR_GRP` exists) |
| `Annotation 'UI.headerInfo.typeName' used at wrong position (wrong scope)` | In a DDLX, **entity-level** annotations (`@UI.headerInfo`, `@UI.chart`, `@UI.presentationVariant`) must appear **before** `annotate view`. The base view needs `@Metadata.allowExtensions: true`. Keep `@UI.dataPoint` minimal (title only) |
| `Maximum accuracy 37 at DEC exceeded by an arithmetic expression` | Cast operands down before multiplying/dividing |
| `Do not use conversion exit OIUNM for property ASSETDESCRIPTION` | `cast( field as abap.char(100) )` |
| `Type "CX_AI_SYSTEM_ERROR" is unknown` | Not available. Drop the exception, plain `RETURN` design |
| `Type "IF_XCO_XLSX_DOCUMENT" is unknown` | XCO XLSX is not available. Emit **CSV** via `cl_abap_codepage=>convert_to( )`, label it `.csv` / `text/csv` |
| `"PROD_QTY1" must be a character-like data object` with `CONCATENATE` | Build rows with string templates: `\|{ f }\|`; escape a literal pipe; dates as `DATE = RAW` |
| RAP `managed` behavior needs a persistent table | For an **action-only** entity use **`unmanaged`** (no CUD) |
| `Local classes of "CL_ABAP_BEHAVIOR_HANDLER" can only be derived in the "Local Definitions/Implementations"` | The `lhc_*` handler lives in the behavior class's **Local Types** tab, not the global source |
| `The type "C(10)" of "…-%PARAM-TARGET_CODE" is not compatible with "C(6)"` | `%param` field types must match exactly — assign through a correctly typed local variable |
| `Query not fully covered by implementation: … get_paging missing` | A custom-entity query provider **must** honour `get_paging( )` → `get_offset`/`get_page_size`, plus `get_requested_elements`, `get_sort_elements`, `is_total_numb_of_rec_requested` |
| `A RETURNING parameter must be fully typed` / `Multiple markers … ) (` | Method signatures cannot carry inline `LENGTH`/`DECIMALS`. Declare `TYPES ty_amount TYPE p LENGTH 8 DECIMALS 2.` first |
| Classic view: arithmetic inside a `CASE` condition is rejected | Pre-compute the value in the underlying view and compare fields only (`ZDPR_P_PERF_AGG` → `ZDPR_Q_PROD_PERF`) |

Analytical queries expose `…Results` / `…Result` in OData — not `Set` / `Type`.

### 4.2 Classic ABAP on this landscape

| Problem | Fix that works |
|---|---|
| `"'PLANT' and the row type of 'CT_HEAD' are incompatible"` ×16 | **Do not use `VALUE #( ( literal ) )` over an elementary line type.** A string template row `( \|PLANT\| )` is rejected the same way — the release will not take a constructor expression with a literal row over an elementary type at all. **Use `APPEND`**, which assigns by conversion. Structured-row `VALUE #( ( sign = 'I' … ) )` is a different shape and is fine |
| `ASSIGN COMPONENT` silently returns sy-subrc 4 | A string template **aligns LEFT by default**, so `\|M{ i WIDTH = 2 PAD = '0' }\|` gives `M10`, `M20`…`M90`. **Always `ALIGN = RIGHT` when zero-padding.** This one corrupted data silently — see §5, M-09 |
| `"<field> is unknown"` ×51 in an include | ABAP resolves declarations in **source order**. A `DATA` block at the end of an include is too late — move it ahead of the first MODULE/FORM that uses it |
| `Error during insertion into a table with a unique key` | `MODIFY itab FROM wa` inside `LOOP AT itab INTO wa` re-inserts. Use `LOOP AT … ASSIGNING FIELD-SYMBOL(<wa>)` and modify in place |
| `OBJECTS_TABLES_NOT_COMPATIBLE` at runtime | Never whole-table `MOVE-CORRESPONDING` from a dynamic / `ANY TABLE` source into a fixed DDIC table. Loop row-wise into `DATA l_row LIKE LINE OF tgt` |
| `UC_OBJECTS_NOT_CONVERTIBLE` | A bad decouple: `TYPE mbew-bwtty` → `TYPE bwtty` resolved to STRING. **A same-named data element is not guaranteed** — only decouple when the note removed the field *and* the bare data element exists |
| `DBSQL_STMNT_TOO_LARGE` | `WHERE f IN r_range` with tens of thousands of EQ lines. Use a guarded `FOR ALL ENTRIES` on a de-duplicated driver |
| `CX_SY_DYN_CALL_PARAM_MISSING` | Wrong parameter name in a dynamic `CALL FUNCTION` — these are not syntax-checked |
| RSDBGENA *"Error generating selection screen 1000"* | Fixed `SELECTION-SCREEN COMMENT 60(nn)` on the same line as a now-40-char MATNR parameter → `VISIBLE LENGTH 18`, or its own BEGIN/END OF LINE. Surfaces only on full regeneration |
| A retype changes **only** the data element after `TYPE`/`LIKE` | `vbtyp_n TYPE vbtyp_n,` → `vbtyp_n TYPE vbtypl,` — never rename the component |

---

## 5. Mistakes already made. Each one is now a rule.

Sourced from the `ISSUES.md` logs. The rule in bold is the thing to carry forward.

**M-01 — Built on a stale base, twice.** (03/09/26, 15/09/26 · `kpmg/zpp_forecast_v2`)
A session forked from a commit that predated an unmerged branch, so every file edited
started from a version missing the real XLSX upload, legacy fallback, month-name headings,
MTS/MTO, Net Weight, Price and CSV templates. The ZIP built from it **overwrote all of
that in the system**. Recovered from git; nothing was lost, but the whole CR was rebuilt.
It happened a second time on 15/09 — 28 commits sat unmerged on a branch and the build
failed activation with `Unknown column name "BUS_FCST_ADD"`.
→ **`git log --all -- <path>` before trusting `main`, and ask for the SE80 download.**

**M-02 — Gave a DDIC instruction off the wrong file.** Following M-01, the advice was to
add `BUS_FCST_ADD` back to `ZPPT_FCST_QT` in SE11. The table was right; the source file was
wrong. The advice was withdrawn.
→ **Before telling Arnav to change DDIC to match code, prove which source is running.**

**M-03 — Contradicted Arnav from a stale copy.** Claimed `PRICE` did not exist; it did, on
the correct branch. Also called the CSV download a regression; it was deliberate.
→ **Arnav's report of what is on his screen outranks the repo copy. Reconcile, don't
overrule.**

**M-04 — abapGit `PROGDIR` element order.** Three `.prog.xml` files listed `SUBC` before
`VARCL`. abapGit deserialises with `CALL TRANSFORMATION id`, which walks the target
structure component by component, so `SUBC` never reached the program directory and SE38
reported *"REPORT/PROGRAM statement is missing, or the program type is INCLUDE"*. The shape
had been copied from `ovl/ztest_t001`, which was advertised as the working pilot and
carried the same defect unnoticed.
→ **Order is `NAME, VARCL, SUBC, FIXPT, UCCHECK` (components 5, 11, 23, 30 of
`zif_abapgit_sap_report=>ty_progdir`); `TPOOL` items are `ID, KEY, ENTRY, LENGTH`. Check
hand-written XML against the real structure order. Never copy a shape on the assumption it
imported.**

**M-05 — Changed a FORM signature, updated only some call sites.** `CV_ADD` was dropped
from `FORM final_qty`; the two quarterly `PERFORM`s were updated, the two monthly ones were
not. *"Different number of parameters in FORM and PERFORM"*. The compiler stops at the
first, so only one error showed.
→ **After any FORM signature change, sweep every `PERFORM` against its `FORM` (quote-aware,
so literals with spaces are not miscounted). 0 mismatches before delivery.**

**M-06 — Pasted one include's content into another.** *"A FORM already exists with the name
BDC_DYNPRO"*, reported against `MZAAIMPF01` line 26.
→ **That message names the *other*, earlier definition — include order puts `I01` before
`F01`. The error is not necessarily in the include the message names.**

**M-07 — Assumed a screen's implicit work carries over to a BAPI.** Replacing BDC with
`BAPI_ASSET_*`, every row failed `Asset 104008114 0 not in company code OVL`: the program
strips leading zeros for display, and the *screen field* used to re-pad them through its
ALPHA conversion exit. A BAPI performs no conversion. The currency field was the same
story, and so was depreciation-area derivation — `ABAAL` scopes areas from configuration,
the BAPI applies the amount to every area and drives 20/30/31/40 negative.
→ **Anything the old code relied on a screen to do — conversion exits, defaulting,
derivation — must be done explicitly once the screen is gone. A BDC→BAPI swap is never
like-for-like; enumerate what the screen was doing first.**

**M-08 — Double-counted BAPI messages.** Appended both `RETURN` and `RETURN_ALL`; every
asset appeared twice in the run log.
→ **`RETURN_ALL` already contains what `RETURN` repeats. Use `RETURN_ALL` when filled, fall
back to `RETURN` only when it is not.**

**M-09 — Silent data corruption from a left-aligned string template.** `do_history` built
the field name as `\|M{ lv_i WIDTH = 2 PAD = '0' }\|`, giving `M10`, `M20`…`M90`. Months 2–9
were lost, month 1 landed in January's column. A file with one month filled summed to zero
and was refused; a file with all twelve was **accepted and stored wrong**. Every legacy
history row loaded before the fix is wrong or missing.
→ **`ALIGN = RIGHT`. And when `ASSIGN COMPONENT` / `READ TABLE` can fail silently, check
`sy-subrc` and make the failure loud.**

**M-10 — Long lines wrapped on paste.** SE38 wraps at paste time; the tail becomes a bogus
statement reported at an innocent-looking line. `ZMM_RM07MLBD` already carries five lines
over 120 characters, so a whole-file paste of it is unsafe.
→ **≤120 characters. Where the running program already has long lines, deliver a
unit/block paste sheet naming each FORM and the line above the insertion, not the whole
file.** (`kpmg/zmm_rm07mlbd/ZMM_RM07MLBD_units.abap` is the pattern.)

**M-11 — A comment stripper ate a continuation line.** A continuation line starting with
`*` was treated as a comment and dropped from the paste copy.
→ **A full-line comment needs `*` in column 1. Any tool that strips comments must use the
column-1 rule, must `rstrip()` before `endswith('.')`, and any literal-masking helper must
be length-preserving.**

**M-12 — An ATC "fix" that made things worse.** Closing a NOORDER finding by rewriting
`SELECT SINGLE` as `SELECT … UP TO 1 ROWS … ORDER BY PRIMARY KEY.` + `ENDSELECT.` traded
one finding for two: it created a `SELECT…ENDSELECT` loop (itself a finding — 13 added) and
the `ORDER BY PRIMARY KEY` is invalid on a field list (26 sites). The same batch also added
2 unguarded `FOR ALL ENTRIES`.
→ **`SELECT SINGLE … ORDER BY PRIMARY KEY.` — no ENDSELECT, no rewrite — closes NOORDER
without either side effect. Syntax-check one instance on this release before applying a
pattern to 26 sites.**

**M-13 — Checked the wrong field's data element.** The batch-key truncation hypothesis for
`ZBNK_APP2` rested on `BNK_COM_BTCH_NO` (NUMC 10) — which is the data element on
`ty_final-batch_no`, **not** on `ZFI_BATCH_SIGN-BATCH_NO`, which is what the variable
actually inherits. Two SE16 checks and a reading of the code disproved it.
→ **Trace the type to the declaration that the variable actually inherits. And disproving a
hypothesis is worth writing down — record the checks that killed it.**

**M-14 — Promised a hand-written abapGit ZIP would import.** `kpmg/zfi_tds_cl34/` is
screen-free with a complete `src/` + `.abapgit.xml` + ZIP; four import attempts all
short-dumped `XML_FORMAT_ERROR` / `CX_XSLT_FORMAT_ERROR` in `FROM_XML`. It shipped by
paste. Ruled out and not worth redoing: well-formedness, UTF-8/no-BOM/LF,
`package.devc.xml`, `TPOOL` items carrying a `KEY`, `PROGDIR` element order.
→ **Never promise a hand-written ZIP will import. Generate it by serialising from a system
that has abapGit, or plan on paste from the start. `ovl/ztest_t001` has never imported
successfully — do not cite it as proof.**

**M-15 — Applied one client's disposition to another.** Cipla-labelled ATC dispositions
(`J_1IMOCUST`→`KNA1`, `VAKEY`→`VAKEY_LONG`, the KALKS P1 pseudo) are **not** OVL rules. The
KB in `ovl/atc/kb/` mixes cipla, Coca-Cola-CCEJ and ONGC and contradicts itself in places.
→ **Read the slice, never quote the KB as OVL policy. HR/EHS/HSE findings were out of scope
on OVL specifically — confirm scope rather than assuming everything is in scope.**

**M-16 — Matched a code pattern and assumed it was flagged.** Of 11 BDC calls in one
folder, only 3 were on the worklist.
→ **Cross-check the worklist by object name before rewriting anything.**

**M-17 — Applied a change to the modes the request happened to name.** The FERT/HAWA
material-type restriction was built for quarterly and monthly "as the request was headed",
and annual was left unfiltered.
→ **When a change is a data-scope rule rather than a display tweak, check every mode/branch
and say which ones it was applied to.**

**M-18 — Missed that the running release takes a different code path.** `ZMM_RM07MLBD`
amounts came out blank on HANA: the BAdI `RM07MLBD_DBSYS_OPT` sets `gv_newdb = 'X'`, stocks
come from `FORM new_db_run`, and the whole classic aggregation block is skipped. The donor
program (`ZRM07MLBD`, copied from the current standard) forces `gv_newdb = abap_false`, so
it never hit this.
→ **On a Z copy of a standard program, check for a HANA / BAdI / optimisation branch that
bypasses the code you are changing — a port that works in the donor can be dead in the
target.**

**M-19 — A run-level flag treated as batch-level.** `ZFI_PAYM_FILE` is keyed per run
(`LAUFD`+`LAUFI`), `REGUT` is per batch. Every `READ TABLE` dropped the batch component, so
one approval marked the whole run sent and made the other batches unreachable. Origin: the
ECC→S/4 BCM→REGUT port, where one-batch-per-run used to hold.
→ **After an ECC→S/4 port, re-check every "there is only one of these" assumption. Someone
had already patched the same collision in `ZFI_BATCH_SIGN` and nobody patched it here.**

**M-20 — Wrote a file outside the repo.** `sync: nothing new to commit` means the file went
to a scratchpad, not that the sync failed.
→ See §2.3. Ask for and give paths from the repo root.

**M-21 — Reported a parameter problem as a code problem.** The failing impairment run used
posting date 31.03.2026 with asset value date 12.08.2026 and period 3 — different fiscal
years on an Apr–Mar variant, and 31.03 is period 12, not 3. It would have been rejected
independently of the bug being fixed.
→ **Sanity-check the input values against the fiscal calendar before attributing a failure
to the code.**

---

## 6. Shipping — what can and cannot go back through abapGit

**ZIP works for:** reports, classes, DDIC (domains, data elements, tables, structures),
message classes, CDS/RAP source, and text pools (TPOOL — the real saving; ~107 lines of
text symbols and selection texts per program that would otherwise be typed by hand).

**PASTE-ONLY, always:** module pools and anything needing an SE51 screen or SE41 status;
modifications to standard SAP objects; Z copies of standard programs (they include SAP
standard includes under standard names, which a serialised pull would put at risk); BAdI
method bodies inside an existing implementation; SE54 event routines; and patch sheets that
are fragments rather than whole objects.

**Never serialised by abapGit, in any case:** SE51 screens, SE41 GUI status, SE54
maintenance views/TMG, SNRO number ranges, SU21 auth objects, SCDO change documents.

**In this repo:**

| Path | Ships as |
|---|---|
| `kpmg/zpp_forecast_v2/` | ZIP — screen-free **by design**; adding `CALL SCREEN` or `cl_gui_custom_container` reverts it to paste-only |
| `kpmg/abapgit_pilot/`, `kpmg/zmm_po_budget/` (DDIC + message class) | ZIP |
| `ovl/ztest_t001/` | pilot — **never actually imported successfully** |
| `kpmg/zfi_tds_cl34/` | complete ZIP that **failed four imports**; shipped by paste |
| `kpmg/zmm_po_budget/` overall | hybrid — DDIC + message class by ZIP; BAdI insert, SE54 event, screen module, TMG, SE93 by hand |
| `kpmg/zmb5b/`, `kpmg/zmmims/`, `kpmg/zmm_me35k_release/`, `kpmg/zsd_scheme/`, `kpmg/zpp_forecast/`, `kpmg/zmm_po_budget_deferred/` | paste-only |

Re-zip from `src/` rather than trusting an existing archive, and check the object names do
not already exist in the target before importing. For the ATC batch the route is different
and safer: **export the package to ZIP with abapGit standalone → overlay our `.prog.abap`
files → re-import → review the diff → pull.** The export already carries correct metadata
and only source is ever replaced. Keep the untouched export ZIP — it is the rollback.

**Always manual, never automated:** transport release; anything touching QA or production;
sending mail; ATC exemption requests; object deletion.

---

## 7. Repository layout — where things go

```
<client>/<object>/ISSUES.md     running log: date | issue | root cause | files | commit | TR
<client>/<object>/NOTES.md      what it is, how it ships, gotchas, dependencies
<client>/<object>/original/     the SE80 download exactly as supplied — written once, never edited
<client>/<object>/src/          corrected source, for abapGit objects
<client>/<object>/<NAME>.abap   corrected source, for paste-only objects
<client>/<object>/docs/         BRD / FSD / TS, object lists, screen layouts
<client>/<object>/drafts/       baselines, SE38 print listings, superseded deltas
incoming/                       drop folder for fresh SE80 downloads awaiting triage
```

Clients: `kpmg/`, `ovl/`, `gail/`, `mwc/`, `rws/`, `pal/`. Give paths from the repo root in
chat so they stay clickable.

- File a supplied download with `./scripts/save-original.sh <client/object> <file>`. It
  never overwrites: a later differing download is kept beside the baseline as
  `<NAME>.<YYYY-MM-DD>.abap` with the drift printed.
- **Original and corrected are both kept, in different places.** `original/` is the
  as-supplied baseline. The corrected object is overwritten by each new fix — git history
  holds every earlier version (`git log -p -- <path>`).
- SE38 *print listings* (`drafts/*.TXT`) are not compilable source — tokens run together
  and page headers are embedded. Baseline record only; reconstructed copies go in
  `drafts/parsed/`.
- Never assume `<object>/src/` exists. Check.

---

## 8. Longer-form references, and when to read them

| File | Read it when |
|---|---|
| `CLAUDE.md` | Always — it loads automatically and is the rulebook |
| This file | Before CDS/RAP, before shipping, before repeating anything |
| `ovl/atc/ATC_HANDOVER.md` | Before **any** ATC work — 31 rules with the failure behind each, finding routing, verified table→CDS and DB-write→API maps, note dispositions, state of the 51-object OVL batch |
| `ovl/atc/kb/*` | Only for a mapping the handover does not spell out. Third-party, mixed-client, self-contradicting. Read named line ranges — reading whole blows the token cap |
| `COPILOT_CONTEXT_HANDOFF.md` | For the reusable ABAP pattern library (§6), object-header and program skeletons (§8.2–8.6), the TS document template (§8.7), project history (§5). **§4.1 is superseded by §4 of this file.** Its Copilot-specific parts (§8.9, §9) do not apply |
| `ovl/atc/AUDIT-2026-08-23.md` | The rule audit of the 51 corrected objects — 433 findings, 46 expected activation failures |
| `README.md` | Repo layout and the sync/save-original scripts |
| `INBOX.md` | Current work queue (rebuilt by `/triage`) |

Skills: `/triage` mail → ranked queue · `/fix-issue` issue → corrected object · `/ship-fix`
approved fix → commit + package · `/from-fs` FS → new object · `/atc-fix` ATC findings ·
`/status` where everything stands · `/solve` program in `~/Downloads` → fix → draft reply ·
`/sync` commit, pull, push.

---

## 9. Answering and writing

- Be concise. No preamble, no restating the question, no essay of options he didn't ask for.
  If there is a decision, recommend one.
- Don't guess field, table or CDS element names. A wrong name costs an activation cycle; if
  a mapping isn't confirmed, say so.
- Mail drafts to functional consultants and client leads: 3–6 lines, professional, no
  flourish. Sign off exactly:

```
Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
```

  Drafting is fine; **sending stays manual.**

---

## 10. Definition of done — check before handing over an object

1. Complete code, first line to last. Before/after line count stated.
2. Every §4 release constraint pre-applied (if the release is unknown, assume they all do).
3. Old code commented with `*`, not deleted; `*BOC/*EOC By <author> on DD/MM/YY` with the
   correct author tag for the client; no double-wrapping; new code below the original.
4. Strict Open SQL; clause order right; `IS NOT INITIAL` before every `FOR ALL ENTRIES`; no
   `SELECT` in a `LOOP` where FAE or a join would do; `SORT` outside the loop for every
   `DELETE ADJACENT DUPLICATES`.
5. SELECT field list re-checked against its `TYPES` **by position**.
6. Every `PERFORM` checked against its `FORM` signature.
7. Block balance on active lines only: `IF==ENDIF`, `LOOP==ENDLOOP`, `FORM==ENDFORM`,
   `CASE==ENDCASE`, `TRY==ENDTRY`, `SELECT(non-single) >= ENDSELECT`, markers `BOC==EOC`.
8. No line over 120 characters.
9. No hardcoded clients, dates or company codes unless the FS says so.
10. Error path: message to the user, no short dump, no silent skip.
11. Selection texts and column headings are readable words.
12. Assumptions in the code as `" ASSUMPTION: …` and repeated in the reply.
13. What was deliberately **not** touched, and why, stated explicitly.
14. Object named, so Arnav knows what to create in ADT. Then stop.
15. `./scripts/sync.sh "<what changed>"` run, on `main`, commit hash and path reported.
