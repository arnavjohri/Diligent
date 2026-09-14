# Diligent — SAP ABAP work, standing rules

Arnav Johri, Associate Consultant, Diligent Tech India Pvt. Ltd. Two projects run
concurrently — **OVL** (ONGC Videsh, ECC→S/4) and **KPMG** — alongside `gail/`,
`mwc/` and `rws/`. Issues arrive by mail daily. He supplies the source
(SE80 download or the copy in this repo), Claude produces the corrected code, he
verifies it, and it goes back into SAP via abapGit standalone or by paste.

## The system this repo mirrors is NOT reachable

The `abap-adt` MCP points at a **different** dev system (`192.168.11.21`, client 200).
It is **not** the system these objects live on.

- Never assume `getObjectSource` returns the real object. It does not.
- Never call `setObjectSource` / `activateByName` / `deleteObject` against a project object.
- The MCP is usable only as a scratch rig for syntax-checking self-contained snippets,
  and only when explicitly asked. Say so when you use it.

The real system has no ADT connection and no outbound internet. Transfer is by
**ZIP (abapGit standalone, offline repo)** or by **copy-paste from SE80**.

## Golden rule: never trust the repo copy as current

Before changing any object, ask for a fresh SE80 download unless one was supplied
this session. Someone else may have edited it, or the running version may predate
the last fix. When a fresh copy is supplied, **diff it against the repo copy first**
and report any drift before applying the new fix. Unreported drift is how a fix
silently reverts someone else's change.

Arnav's helper report `ZR_PROG_DOWNLOAD` mass-downloads a program with its full
include tree (also FGs/classes, by package or name list) — name it when asking for a
fresh download. Line numbers in any patch sheet are snapshot-bound: locate by
FORM/MODULE name, never by line number.

## Change markers

Multi-line blocks:

    *BOC By Arnav on DD/MM/YY
    ...new or replacement code...
    *EOC By Arnav on DD/MM/YY

Single line: append `"Changes by Arnav on DD/MM/YY`

- Date format is **DD/MM/YY** with slashes. Use today's real date. (Object *header*
  blocks use `DD.MM.YYYY` with dots — don't conflate the two.)
- **Never nest or double-wrap markers.** If a block already carries markers, extend the
  existing block; do not wrap a wrapped block.
- The author tag is project-dependent. `Arnav` for the work in this repo; the OVL/ATC
  remediation work uses `SAP_ABAP`. If it is not obvious which applies, ask.

## Correcting code

- **Comment old code out, never delete it.** The commented original stays inside the
  BOC/EOC block so the reviewer can see what was replaced.
- Change only what the issue calls for. State explicitly what you deliberately did not
  touch, and why.
- Never mass-regex across SELECT bodies or whole programs. Targeted edits only.
- One `#EC` pseudo-comment per line. On a line with no comment it starts with `"`; on a
  line that **already** has a `"` comment the `#EC` goes *inside* that comment — never add
  a second `"`. No P1 pseudo-comments without Arnav's approval.
- `IS NOT INITIAL` guard before every `FOR ALL ENTRIES`.
- Strict Open SQL: comma-separated field list; every host variable, host expression and
  inline declaration escaped with `@` — including `INTO @lt_tab`, `INTO @DATA(ls)` and
  `FOR ALL ENTRIES IN @itab`, all of which are mandatory.
- Clause order: `INTO`/`APPENDING` comes **after** `ORDER BY`, and `UP TO n ROWS` /
  `OFFSET` come **after** `INTO`. So:
  `SELECT f1, f2 FROM t WHERE ... ORDER BY f1 INTO @tgt UP TO 1 ROWS.`
  "`INTO` last" is wrong as a flat rule — it produces the invalid
  `... ORDER BY f1 UP TO 1 ROWS INTO @tgt.`
- `ORDER BY PRIMARY KEY` only on `SELECT *`.
- Dropping `CLIENT SPECIFIED` means dropping `mandt` from the field list too.
- No `SELECT` inside a `LOOP` where `FOR ALL ENTRIES` or a join would do.
- `DELETE ADJACENT DUPLICATES` needs a matching `SORT` **outside** any loop, on exactly
  the fields the DELETE compares.
- No hardcoded clients, dates or company codes unless the FS says to hardcode.
- Error paths give the user a message — no short dump, no silent skip.
- Selection texts and column headings are readable words, not technical names.
- Work only on findings that are **still open**. Arnav fixes things by hand between runs,
  so line numbers drift and some findings are already resolved. Re-check; never assume the
  list is current.

## Delivering code

- **Keep source lines under ~120 characters.** Everything here ships by paste, and SE38
  wraps a long line on paste: the tail lands on the next line without its `"` prefix and
  becomes a bogus statement, reported as `"<WORD>" is invalid here (due to grammar)` at a
  line that looks innocent. ABAP's hard limit is 255 but the wrap bites well before that.
  Long `" ASSUMPTION:` notes go in a `*` block above the statement, not trailing it.
- **A field list and its target type are matched by POSITION, not by name.** Strict ABAP
  SQL assigns `INTO TABLE @itab` slot by slot, so inserting a field in the SELECT without
  inserting it at the same index of the `TYPES` silently fills the wrong component - or,
  when the types differ, fails activation with `component "X" ... not compatible with "Y"`,
  naming two fields that look unrelated. Re-check both lists together after any edit.
- **Complete objects, never fragments.** The file you write is whole, first line to last —
  `" ... existing code ..."` or "rest unchanged" is a failure. If it was 866 lines before it
  is ≥866 lines after; state the before/after count. Chat gets the root cause, a change table
  and the file path — not a 2000-line dump.
- New code goes **below** the commented-out original.
- **One object at a time, then stop.** Name the object so Arnav knows what to create in ADT,
  then wait for `activated, give the next` or a pasted activation error. Never dump twelve
  objects at once. When he pastes an error, fix that error and return the corrected object —
  don't explain at length first.
- **Never modify a standard SAP object.** Changes go into a `Z` copy. Create custom includes
  only where an include actually changed — never blanket-Z every include.
- Build nothing the FS or the issue did not ask for.
- **Every file that matters lives in the repo, never in a scratchpad or temp directory.**
  Claude Code offers a session scratchpad for throwaway working files; corrected objects,
  originals, ZIPs, patch sheets, TS documents, ISSUES.md and NOTES.md are not throwaway and
  never go there. Write them under `<client>/<object>/` from the repo root — a file outside
  the repo is invisible to git, so `sync.sh` will report "nothing to commit" and the work is
  lost when the session ends. The scratchpad is for scratch: a diff being inspected, an
  intermediate parse, a file that is deleted before the reply is finished.
- **Pull before you start.** First action in a session that will touch code: run
  `./scripts/sync.sh --pull-only`. Arnav edits by hand between runs and other sessions push
  too, so the working copy can be behind. This is the drift check in git terms — it does not
  replace asking for a fresh SE80 download, which catches changes made in SAP itself.
- **Push every code update, to `main`.** Whenever an object file is written or changed, run
  `./scripts/sync.sh "<what changed>"` as the last step of that reply — commit, pull, push, in
  one go — and report the commit hash with the file path. Check you are on `main` first; if a
  session started you on some other branch, merge it into `main` and push that. This is a standing instruction, not
  something to ask about each time. It pushes the *repo* copy only; it does not touch SAP, and
  it is not sign-off — Arnav still verifies before anything goes into the system. If the script
  stops on a merge conflict or a dead network, say so in the reply rather than retrying blind.

## Answering

- Be concise. No preamble, no restating the question, no essay of options he didn't ask for.
  If there is a decision, recommend one.
- **Assume no system access.** Never propose "let me check table X in your system" — reason
  from the code and SAP knowledge, or give the exact SE16/SE11/tcode navigation for Arnav to
  check himself.
- **Don't guess field, table or CDS element names.** A wrong name costs an activation cycle;
  if a mapping isn't confirmed, say so. `DDLS_BASE_FIELDS.txt` and `ARS_API_SUCCESSOR.xlsx`
  are not on this machine, so CDS names cannot be re-verified locally — use only mappings
  already spelled out.
- Flag risky assumptions instead of burying them, and put them in the code as
  `" ASSUMPTION: ...` so they are greppable.

## Emails and messages

Drafts to functional consultants and client leads: 3–6 lines, professional, no flourish.
Sign off exactly:

    Thanks & Regards,
    Arnav Johri | Associate Consultant | Diligent Global

Drafting is fine; sending stays manual.

## Release constraints

This landscape is an older S/4 release. Before writing CDS or RAP, read
`ovl/zpra_dpr/docs/sap-release-cds-constraints.md` (repo copy; the laptop memory file
`~/.claude/projects/.../memory/sap-release-cds-constraints.md` is the same content, and a
remote session cannot see it) — it records confirmed failures for `year()`/`month()`,
INT→NUMC casts, `@Semantics.*` in view entities, `@Analytics.query` in OData bindings, key
contiguity, and unmanaged-RAP handler placement. Do not re-derive these; they were
established by activation failures on the real system (the ZPRA DPR RAP build on OCQ).

## Repository layout

One folder per object. Every folder has:

    <object>/ISSUES.md     running log: issue -> cause -> fix -> TR -> date
    <object>/NOTES.md      what it is, how it ships, gotchas
    <object>/original/     the source exactly as Arnav supplied it — never edited

**Original and corrected are both kept, in different places.**

- `<object>/original/<NAME>.abap` is the as-supplied SE80 download. It is written once and
  never overwritten or corrected. File it with
  `./scripts/save-original.sh <client/object> <file>` before touching anything — if a later
  download of the same object differs, the script keeps it beside the baseline as
  `<NAME>.<YYYY-MM-DD>.abap` and prints the drift instead of clobbering either one.
- The **corrected** object lives in the object folder proper — `src/` for abapGit objects,
  a loose `.abap` at the folder root for paste-only ones. Each new fix overwrites it, so
  there is exactly one current version to paste or zip; git history holds every earlier one
  (`git log -p -- <path>`).

**Only ZIP-shippable objects have `src/` and `.abapgit.xml`** — today that is
`kpmg/zpp_forecast_v2/`, `kpmg/zmm_po_budget/`, `kpmg/abapgit_pilot/`,
`ovl/ztest_t001/`, `kpmg/zfi_tds_cl34/`. The rest hold loose `.abap` files and are paste-only. Never assume
`<object>/src/` exists; check.

`incoming/` is the drop folder for fresh SE80 downloads awaiting triage.

**Single branch: `main`.** No per-topic branches — every commit lands on `main` and is
pushed there, so `git pull origin main` on Arnav's laptop is always enough to have the
current state locally. Paths are client-first, then object — `kpmg/<object>/`,
`ovl/<project>/`, plus `gail/`, `mwc/`, `rws/`. When naming a path in chat, give it from
the repo root so it stays clickable.

## Shipping method depends on the object type

**abapGit ZIP** works for reports, classes, DDIC (domains, data elements, tables,
structures), message classes, CDS/RAP source. **PASTE-ONLY:** module pools and anything
needing an SE51 screen or SE41 status; modifications to standard SAP objects; Z copies of
standard programs (they include SAP standard includes under standard names, which a
serialised pull would put at risk); BAdI method bodies inside an existing implementation;
SE54 event routines; and patch sheets that are fragments rather than whole objects.

In this repo:

- **ZIP:** `kpmg/zpp_forecast_v2/` (screen-free *by design* — that is why it ships; adding
  `CALL SCREEN` or `cl_gui_custom_container` reverts it to paste-only), `kpmg/abapgit_pilot/`,
  `ovl/ztest_t001/` (pilot — **never actually imported successfully**; do not cite it as
  proof the ZIP path works).
- **Hand-written abapGit XML has not yet imported on this landscape.** `kpmg/zfi_tds_cl34/`
  is screen-free and has a complete `src/` + `.abapgit.xml` + `ZFI_TDS_CL34.zip`, but four
  import attempts all short-dumped `XML_FORMAT_ERROR` / `CX_XSLT_FORMAT_ERROR` in
  `FROM_XML`. It shipped by paste instead. **Do not hand-write abapGit XML for a new object
  and promise it will import** — generate it by serialising from a system that has abapGit
  installed, or plan on paste from the start. What was ruled out, so it need not be redone:
  well-formedness, UTF-8/no-BOM/LF, `package.devc.xml`, `TPOOL` items carrying a `KEY`, and
  `PROGDIR` element order.
- **Hand-written abapGit XML: element order is load-bearing.** abapGit deserialises with
  `CALL TRANSFORMATION id`, which walks the target structure component by component and
  raises `CX_XSLT_FORMAT_ERROR` — a short dump in `ZABAPGIT_STANDALONE` reported as
  "invalid XML format" — on the first element that arrives out of sequence. For a report's
  `PROGDIR` the order is `NAME, VARCL, SUBC, FIXPT, UCCHECK`
  (`varcl` is component 5, `subc` 11, `fixpt` 23, `uccheck` 30 of
  `zif_abapgit_sap_report=>ty_progdir`); for `TPOOL` items it is `ID, KEY, ENTRY, LENGTH`.
  Check any hand-written XML against the real structure order before zipping, and do not
  copy a shape from another object on the assumption that it imported — `ovl/ztest_t001`
  was advertised as the pilot and carried this exact defect unnoticed.
- **Hybrid:** `kpmg/zmm_po_budget/` — DDIC + message class by ZIP; BAdI insert, SE54 event,
  screen module, TMG and SE93 by hand.
- **Paste-only:** `kpmg/zmb5b/` (Z copy of RM07MLBD), `kpmg/zmmims/` (module-pool includes),
  `kpmg/zmm_me35k_release/` (Z copies of standard programs), `kpmg/zsd_scheme/` (module pool +
  screens + SNRO/SU21/SCDO/SM30), `kpmg/zpp_forecast/` (superseded v1, still needs a screen),
  `kpmg/zmm_po_budget_deferred/` (no `src/`, no `.abapgit.xml` — not importable as it stands).

Re-zip from `src/` rather than trusting an existing archive, and check the object names
don't already exist in the target before importing.

## What stays manual, always

Transport release. Anything touching QA or production. Sending mail. ATC exemption
requests. Object deletion. SE51 screens, SE41 GUI status, SE54 maintenance views,
SNRO number ranges, SU21 auth objects, SCDO change documents — abapGit does not
serialise these, so they never appear in a generated ZIP.

## Skills, and where the detail lives

- `/triage` mail → ranked queue · `/fix-issue` issue → corrected object ·
  `/ship-fix` approved fix → commit + ZIP
- `/from-fs` FS document → new object, built one object at a time ·
  `/atc-fix` ATC findings → corrections · `/status` where every object stands

`COPILOT_CONTEXT_HANDOFF.md` (repo root) is the long-form reference: reusable ABAP
patterns, object-header and program skeletons, the TS document template, project history.
Read it when a task needs one of those, not by default. Its §4.1 is superseded by the
memory file above, and its Copilot-specific parts (§8.9, §9) do not apply here.
