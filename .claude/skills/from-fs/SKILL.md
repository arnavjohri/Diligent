---
name: from-fs
description: Build a new ABAP object from a functional spec and write the TS that ships with it. Use when a new FS, FSD, BRD or change request arrives, when Arnav points at a .doc/.docx spec, when he wants a new report, upload program, module pool, CDS/RAP app or OData service built from scratch, or when he asks for the TS document. Triggers on "FS for", "FSD", "BRD", "CR", "build from FS", "new object", "new development", "write the TS". Not for issue mail — that is /triage then /fix-issue.
---

# Build an object from a functional spec

Two steps end with a hard stop: the open questions (2) and the object list (3).
No code before both are cleared. Everything after that is one object at a time.

## 1. Read the spec and calibrate the release

Read the FS end to end before anything else. `.doc`/`.docx` are read directly with the
`docx` skill — never ask Arnav to convert a file.

Ask which system and client this is for. The constraints in
`ovl/zpra_dpr/docs/sap-release-cds-constraints.md` (repo copy; the laptop memory file
`~/.claude/projects/.../memory/sap-release-cds-constraints.md` is the same content) were
established by real activation failures on OCQ (an older S/4). On a newer release, avoiding
valid syntax makes the code worse. **When the release is unknown, apply every constraint**
— code that avoids `year()` works everywhere, code that uses it fails on half his systems.

Give Arnav this probe to run in SE38 on the **target** system and paste the output back:

```abap
WRITE: / sy-saprl.
SELECT SINGLE release, extrelease FROM cvers
       WHERE component = 'SAP_ABA' INTO @DATA(ls_ver).
```

Never run it yourself — the only ADT system you can reach is `192.168.11.21`, which is not
where these objects live, so its release answers nothing (see `CLAUDE.md`).

The same applies to the throwaway CDS for the two constraints that actually bite: Arnav
activates it in the target system and reports whether `year( )` and
`cast( <int> as abap.numc(2) )` survive.

If the FS changes an existing program rather than creating one, get a fresh baseline first
— the drift rule in `CLAUDE.md` applies here too. `ZR_PROG_DOWNLOAD` is Arnav's own report
for pulling a program with its full include tree.

## 2. Open questions before code — hard rule

A real FS is always underspecified. Ambiguities go to the functional consultant as a
numbered list. They are never guessed at, never quietly resolved in code.

Produce an **Assumptions and Queries** document — the pattern already in `FSD/`
(`Scheme_Pipes_Assumptions_and_Queries.docx`,
`ZFORECAST_Adhesive_Assumptions_and_Queries.docx`). Markdown plus a matching `.docx`,
named `<OBJECT>_Assumptions_and_Queries.docx` in `FSD/`.

Per item: the question, the FS section it comes from, what you will assume if no answer
arrives, and what breaks if the assumption is wrong.

Then stop and wait.

- Never invent a table, field, CDS element, data element or BAPI name. An unconfirmed
  mapping is an open question, not a guess — a wrong CDS element name costs an activation
  cycle.
- `DDLS_BASE_FIELDS.txt` and `ARS_API_SUCCESSOR.xlsx` are **not on this machine**. CDS
  element names cannot be re-verified locally. Use only mappings the FS spells out.
- Assumptions that survive into code go in as `" ASSUMPTION: ...` so they stay greppable.

## 3. FS → object list, then stop

Before a line of code, produce:

| # | Object | Type | Purpose | Depends on |

and a second table mapping **every FS requirement → the object that implements it**.

- Order the list in **dependency order — that is paste order**: DDIC first, then
  declarations, then logic, then screen, then service/binding/tile.
- A requirement that maps to nothing is a gap to raise, not a thing to invent.
- Do not design anything the FS did not ask for.

Get approval on the list before building.

## 4. Build one object, then stop

The loop is: give object N → Arnav pastes into ADT/SE80 → he replies `activated, give the
next`, or pastes the exact activation error → you fix it → repeat.

Do not dump twelve objects at once. Name the object he has to create in ADT before
pasting, give the code, stop. When he pastes an error, return the corrected full object —
do not explain the error at length first.

Every new object opens with this header (note: **DD.MM.YYYY with dots here**; BOC/EOC
change markers stay DD/MM/YY with slashes per `CLAUDE.md`):

```abap
*&---------------------------------------------------------------------*
*& Report/Include : Z...
*& Title          : <one line>
*& Project        : <OVL / KPMG>                  Module: MM
*& Related FS     : <FSD number and file name>
*& Author         : Arnav Johri                   Date: DD.MM.YYYY
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   <what it does, in 3-5 lines>
*&
*& CHANGE HISTORY
*&   DD.MM.YYYY  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
```

Deliver **complete units** — whole form, method, class or view, first line to last.
`" ... existing code ...` or "rest unchanged" is a failure. Write the file to
`<object>/src/` and give the path; chat gets the object name and a change table, not a
2000-line paste.

When the FS baseline is an SE38 print listing rather than compilable source (as on
`ZMM_VEND_UPLOAD` / FSD 30), deliver compile-ready units anchored on the
FORM/MODULE/METHOD name plus a verbatim anchor line. A line number may accompany it only as
a dated hint — "after `FORM validate_vendor`; line 412 in the 12/08/26 `ZR_PROG_DOWNLOAD`
listing, indicative only". Locate by name; the number is snapshot-bound (`CLAUDE.md`). Add
a greppable change tag such as `"FSD30` on every touched line, rather than a whole-file
replacement.

Marker, comment-don't-delete, Open SQL and pseudo-comment rules: follow `CLAUDE.md`. Do
not restate or relax them here.

## 5. Pick the right skeleton

**Classic report** — `REPORT` + `INCLUDE _TOP / _SCR / _FORMS`; `INITIALIZATION` →
`AT SELECTION-SCREEN` → `START-OF-SELECTION` (fetch; on empty,
`No data found for the given selection` TYPE 'S' DISPLAY LIKE 'W') → `END-OF-SELECTION`
(display). `CL_SALV_TABLE` for a plain list. `CL_GUI_ALV_GRID` only when you need editable
cells, cell styles or custom toolbar events.

**Upload / Excel program with a processing log** — `upload_file` → `convert_data` →
`validate_data` → `process_data` → `download_error_log` + `display_log`. Non-negotiable:

- One bad row never stops the batch. No `LEAVE LIST-PROCESSING` on a data error.
- Every row carries row number, status S/W/E and message. Sub-operation statuses roll up
  into an overall `msgty` = worst of them.
- `COMMIT WORK` / `ROLLBACK WORK` **per row**, plus `BAPI_TRANSACTION_COMMIT` where the API
  needs it. Never one commit at the end.
- A blank cell must never overwrite existing data — set the `datax` flag only where the
  source cell is populated.
- Error-only download file; say `No error records to download.` when the run is clean.

**CDS → RAP list report** — build order: 1 `ZI_<obj>` interface view → 2 `ZP_<obj>_*`
private helpers *only* if a CASE inside GROUP BY forces it → 3 `ZC_<obj>` consumption with
`@Metadata.allowExtensions: true` → 4 DDLX metadata extension → 5 `ZSD_<obj>` service
definition → 6 `ZSB_<obj>` binding (OData V4 – UI). **Every tile's CDS goes into ONE
service definition and ONE binding** — not a separate OData service per tile. If the logic
is not SQL-expressible (RFC calls, nested lookups, computed rows), replace 1–3 with a
custom entity plus a query-provider class; paging is mandatory — honour `get_paging( )`,
`get_requested_elements`, `get_sort_elements`, `is_total_numb_of_rec_requested`, and call
`set_total_number_of_records`.

**SEGW OData V2** — propose the no-ABAP option first: keep the flat entity and have CPI
send an OData `$batch` changeset. If a deep entity is genuinely required, redefine
`/IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY`, define the deep structure in
`MPC_EXT` `DEFINE`, loop the item table, return one consolidated response.

## 6. Write the TS

```
# TS — <Object name> (<FS number>)
1. Document control     : version, author, date, related FS
2. Purpose / background : 3-5 lines
3. Objects affected     : table — name | type | new or changed | package | TR
4. Detailed changes     : per object, with the EXACT include name, the enclosing
                          FORM/MODULE/METHOD name, a verbatim anchor line, and the code
                          block. Line numbers carry the snapshot date and are explicitly
                          marked non-authoritative.
5. Requirement mapping  : FS requirement -> object/unit that implements it
6. Test scenarios       : input, expected output, actual
7. Open points          : anything the FS did not specify
```

Deliver Markdown **and** a matching `.docx`. The exact anchor is the point — it is what
makes the TS usable by another ABAPer after the program has moved.

## 7. Definition of done

Check all nine before handing over:

1. Complete code, first line to last. No `" ... rest unchanged ...`.
2. Every release constraint pre-applied (all of them, if the release is unknown).
3. Old code commented, not deleted; markers and author tag per `CLAUDE.md`.
4. Strict Open SQL. `IS NOT INITIAL` before every `FOR ALL ENTRIES`. No `SELECT` inside a
   `LOOP` where a `FOR ALL ENTRIES` or a join would do.
5. No hardcoded clients, dates or company codes unless the FS says to hardcode.
6. Error path gives the user a message. No short dump, no silent skip.
7. Selection texts and column headings are readable words, not technical names.
8. All FS requirements mapped; unmapped ones listed as open points.
9. Each object named so Arnav knows what to create in ADT before pasting.

## What cannot be generated — it stays manual

abapGit does not serialise these, so they never reach the system by ZIP or by paste:

- **SE51** screens — layout and flow logic
- **SE41** GUI status and titles
- **SE54** table maintenance views / maintenance generation
- **SNRO** number range objects
- **SU21** authorisation objects
- **SCDO** change document objects

When the FS needs one, do not pretend to deliver it. Put it in the TS as a numbered manual
step with the transaction, the object name, the field-by-field values to key in, and the
hook the generated code expects (PBO/PAI module names, status name, number range object
and interval). Also always manual: transport release, anything touching QA or PRD, sending
mail, ATC exemption requests.

## Never

- Never write to SAP via the `abap-adt` MCP. It points at a different system.
- Never modify a standard SAP object. Changes go into a `Z` copy, and custom includes are
  created only where an include actually changed — never blanket-Z every include.
- Never build what the FS did not ask for.
- Never present generated code as tested. You cannot run it.
- Never carry another client's conventions across. Marker author ids and disposition rules
  are project-scoped — if it is not obvious which applies, ask.
