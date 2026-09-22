# diligent

SAP ABAP work — Arnav Johri, Diligent Tech India Pvt. Ltd.

**Single consolidated repository. Private.** Everything lives on `main`; there are no
per-topic branches. Organised client / project first, then object.

This repo is the only copy. Nothing of value is laptop-only.

## Working with this repo

`CLAUDE.md` at the root is the standing rulebook — change markers, correction rules,
release constraints, how each object ships. It loads automatically in Claude Code.

`MEMORY.md` beside it is the standing memory: system and project facts, the coding standard
collected in one place, the release constraints confirmed by activation failure, and a
write-up of every mistake already made with the rule each one produced. It is in git on
purpose — web sessions run in a throwaway container, so anything not committed is lost.

Skills in `.claude/skills/` drive the day-to-day work:

| Skill | Does |
|---|---|
| `/triage` | Scans Outlook, writes a ranked work queue to `INBOX.md`. Thread-level, latest-state-only. |
| `/fix-issue` | Diagnose → drift-check against a fresh SE80 download → targeted fix with BOC/EOC markers. |
| `/ship-fix` | Gate on object type, then abapGit ZIP or paste sheet, commit, and import steps. |
| `/from-fs` | FS document → working object + the TS deliverable. |
| `/atc-fix` | ATC finding remediation (OVL; author tag `SAP_ABAP`). |
| `/status` | Factual weekly rollup from commits and `ISSUES.md`, for status mail. |

One plain command keeps the repo in step with GitHub:

```
./scripts/sync.sh                     commit everything, pull, push — auto commit message
./scripts/sync.sh "ZMB5B qty fix"     the same, with your own message
./scripts/sync.sh --pull-only         just bring the repo up to date
```

From Windows `cmd` or PowerShell, use `scripts\sync.cmd` with the same arguments — it just
calls the shell script through Git's bash.

It is safe to run when there is nothing to do, and it never force-pushes: if the same file
changed here and on GitHub it stops and tells you, leaving your commit intact. `/sync` runs
it from inside Claude Code.

To have it fire by itself, run this once per machine:

```
./scripts/enable-auto-sync.sh          # and --off to undo
```

It installs two hooks into `.claude/settings.json`, merging with anything already there and
keeping a `.bak`. Reopen Claude Code afterwards. The two halves:

- **`SessionStart`** pulls from GitHub before work begins, so a session never starts on a
  stale working copy. No downside — keep this one.
- **`Stop`** commits and pushes whatever changed after every reply, including edits made by
  hand outside Claude. Auto-written commit messages, verified or not. This is the belt to the
  braces — Claude pushes its own code updates anyway; this catches everything else.

Hook output goes to `.git/sync-hook.log`, not the chat. If a reply seems not to have pushed,
read that log first — `sync: nothing new to commit` means the file was written outside the
repo (a scratchpad or temp folder), not that the sync failed. Ask for files by repo-relative
path — `kpmg/zmb5b/src/…` — and they land where git can see them.

`incoming/` is the drop folder for fresh SE80 downloads awaiting triage. File a supplied
download into its object folder with:

```
./scripts/save-original.sh kpmg/zmb5b ~/Downloads/ZRM07MLBD.txt
```

That writes `kpmg/zmb5b/original/ZRM07MLBD.txt` and never overwrites it. A later download of
the same object that differs is kept beside it as `ZRM07MLBD.<date>.txt` with the drift
printed. Corrected code does not go in `original/` — it goes in the object folder itself
(`src/` for abapGit objects, a loose `.abap` at the root for paste-only ones) and is
overwritten by each new fix. `git log -p -- <path>` gets any earlier version back.

To pull it all down on your own machine:

```
git clone https://github.com/aj-02/Diligent.git     # first time
git pull origin main                                # after that
```
`COPILOT_CONTEXT_HANDOFF.md` is the deeper cross-project reference behind `CLAUDE.md`.

## Layout

```
kpmg/                            KPMG engagements
  zmb5b/                         MB5B receipt & issue amount report (RM07MLBD copy)
  zmm_vend_upload/               Vendor master upload — ZMM_VEND_MASTER (FSD 30)
  zsd_scheme/                    Scheme (Pipes) — SD, Astral / Project UDAY
  zpp_forecast/                  Adhesive forecasting — ZFORECAST, Astral / Project UDAY
  zpp_forecast_v2/               Forecast rebuild — abapGit-serialised (DDIC + classes)
  zmm_po_budget/                 PO budget check — BAdI + DDIC, abapGit-serialised
  zmm_po_budget_deferred/        Deferred budget-check class
  zmm_me35k_release/             ME35K release fix for S/4 conversion (standard-object mods)
  zmmims/                        IMS module pool includes + GeM invoice display
  abapgit_pilot/                 DDIC-via-abapGit import pilot (DOMA→DTEL→TABL proof)
  _docs/                         FSDs and assumption/query documents

ovl/                             OVL / ONGC Videsh
  atc/                           ECC→S/4 ATC remediation
    kb/                          Knowledge base + session handover notes
    worklists/                   ATC run exports, error lists, program sheets
    object-list/                 Objects in scope, by category
    corrections/                 Corrected sources + manual-review list
    sources/                     Pre-remediation snapshots (modpool / reports / changedoc)
  zpra_dpr/                      ZPRA Daily Production Report — analytical RAP / CPI
  jv-cash-call/                  SAPMZOVL_JV_CASH_CALL module pool
  ocv-to-ovl-transfer/           Colombia OCV → OVL document transfer
  zf01_exchange_rate/            Exchange rate OData V2 interface (CPI → TCURR)
  mm-fiori/                      MM programs assessed for Fiori tiles
  ztest_t001/                    abapGit round-trip test (importable repo)
  _engagement/                   Transport lists, scope notes

gail/                            GAIL — S2A project
mwc/                             MWC
rws/                             RWS
```

`gail/`, `mwc/` and `rws/` keep the delivered engagement structure:
`Codes/`, `FSD/`, `TSD/`, `QCD/`, `TUT/`.

Object folders use this split where it applies:

| Folder | Holds |
|---|---|
| `src/` | Current ABAP source — what you'd paste or serialize into a system |
| `docs/` | BRD / FSD / TS, technical object lists, screen layouts, build guides |
| `drafts/` | Baselines, SE38 print listings, superseded deltas — history, not deliverables |
| `NOTES.md` | What the object is, **how it ships**, gotchas, dependencies |
| `ISSUES.md` | Running log: date, issue, root cause, files changed, commit, TR |

## How objects ship

Not everything can go back through abapGit. Read `NOTES.md` in the object folder, and
the shipping table in `CLAUDE.md`, before packaging anything.

- **abapGit ZIP** — reports, classes, DDIC sets. Have `.abapgit.xml` + `src/`:
  `kpmg/zpp_forecast_v2`, `kpmg/zmm_po_budget`, `kpmg/abapgit_pilot`, `ovl/ztest_t001`.
- **Paste only** — module pools with SE51 screens, modifications to standard SAP objects,
  and Z copies of standard programs (they carry SAP standard includes under standard
  names, which a serialised pull would put at risk): `kpmg/zmb5b`, `kpmg/zmmims`,
  `kpmg/zmm_me35k_release`, `kpmg/zsd_scheme`, `kpmg/zpp_forecast`,
  `kpmg/zmm_po_budget_deferred`.

Never serialisable in any case: SE51 screens, SE41 GUI status, SE54 maintenance
generation, SNRO number ranges, SU21 auth objects, SCDO change documents.

## Notes

- **kpmg/zmb5b** — `src/zrm07mlbd.abap` is the working copy of the `RM07MLBD` clone.
  `drafts/RM07MLBD_*.TXT` are SE38 print listings (tokens run together, page headers) and
  are *not* compilable; baseline record only.
- **kpmg/zmm_vend_upload** — delivered as a delta against a print-listing baseline; see
  `drafts/README.md` for the change-unit table.
- **kpmg/zsd_scheme, kpmg/zpp_forecast** — `docs/00_TECHNICAL_OBJECTS.md` carries the DDIC
  definitions the ABAP in `src/` depends on. Read it before creating anything in a system.
- **ovl/atc/sources** — pre-remediation snapshot. Corrected versions live in
  `ovl/atc/corrections/`.
- The `abap-adt` MCP points at a **different** dev system (`192.168.11.21`) that is *not*
  where these objects live. Never write to SAP through it. See `CLAUDE.md`.

## Not in this repo

`.mcp.json` and `.claude/settings.local.json` hold connection details including a
plaintext SAP password, and stay local by design. `.claude/skills/` **is** tracked — it
is work product.
