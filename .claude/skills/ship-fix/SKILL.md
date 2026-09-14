---
name: ship-fix
description: Package an approved ABAP fix for upload and record it. Use after Arnav has verified a fix and wants it committed to git, and packaged as an abapGit ZIP or a paste sheet depending on object type. Triggers on "ship it", "approved", "package this", "commit and push the fix".
---

# Ship an approved fix

Only run this after Arnav has explicitly approved the diff. If approval is unclear, ask.

## 1. Confirm scope

Show the object, the files changed, and the issue being closed. One line each. Get a yes.

## 1b. Gate: is this object even ZIP-shippable?

**Check the object against the shipping-method table in `CLAUDE.md` before building
anything.** Getting this wrong can overwrite SAP standard code on import.

Do **not** build a ZIP for:

- module pools, or anything needing SE51 screens or SE41 GUI status
- modifications to standard SAP objects
- **Z copies of standard programs** — they carry SAP standard includes under standard
  names, and a serialised pull puts those originals at risk
- BAdI method bodies inside an existing implementation
- SE54 event routines, or any fragment-level patch

Paste-only in this repo today: `zmb5b/`, `zmmims/`, `zmm_me35k_release/`, `zsd_scheme/`,
`zpp_forecast/`, `zmm_po_budget_deferred/`. `zfi_tds_cl34/` is screen-free and carries
`src/` + `.abapgit.xml`, but its hand-written ZIP never imported (four `XML_FORMAT_ERROR`
dumps, see its `NOTES.md`) — it shipped by paste, and so will its next fix unless a
serialised-from-system ZIP exists.

**If the object is paste-only:** commit the source, then produce a paste sheet anchored
on FORM / MODULE / METHOD names — never on line numbers, which are snapshot-bound.
Skip steps 2 and 5 entirely and say why.

## 2. Build the abapGit ZIP  *(ZIP-shippable objects only)*

`.abapgit.xml` must sit at the **ZIP root** with `src/` beneath it — abapGit reads the
descriptor from the archive root, never from a subfolder.

On Arnav's Windows laptop there is **no `zip` binary** — use PowerShell:

```powershell
Compress-Archive -Path "<object>\.abapgit.xml","<object>\src" -DestinationPath "<OBJECT>.zip" -Force
```

In a Linux / remote Claude Code session `zip` is available:

```bash
cd <object> && zip -r ../<OBJECT>.zip .abapgit.xml src && cd - >/dev/null
```

If `.abapgit.xml` is missing, model it on `ztest_t001/.abapgit.xml`, with the correct
`MASTER_LANGUAGE` and a `STARTING_FOLDER` of `/src/`.

Verify before handing it over: list the archive, confirm the descriptor is at the root
and every changed file is present.

## 3. Commit and push

Single branch — everything lands on `main` (`CLAUDE.md`). If the session started on
another branch, merge it into `main` and push that. Use `./scripts/sync.sh "<message>"`:
commit, pull, push in one go.

Commit message: object, issue in one line, reporter. Example:

    ZPP_FORECAST: quarterly split ignores fiscal year shift (reported by <name>)

Push. Report the commit SHA and branch.

## 4. Update the log

Append to `<object>/ISSUES.md` — date, issue, root cause, files changed, commit SHA.
Leave the TR number blank; Arnav fills it after import.

## 5. Print the import steps  *(ZIP path only)*

1. SE38 → `ZABAPGIT_STANDALONE`
2. Select the offline repo for this package (or **New Offline** if first time)
3. Repo menu → **Import package** → upload `<OBJECT>.zip`
4. **Pull** / Deserialize, confirm the object list
5. Assign the transport when prompted
6. Activate, and re-pull once if DDIC objects come back inactive — abapGit resolves
   DOMA → DTEL → TABL order, but a single pass can leave objects inactive

Then state what the ZIP cannot carry: SE51 screens, SE41 GUI status, SE54 maintenance
generation, SNRO, SU21, SCDO. If the fix touched any of those, list the manual steps.

## Never

- Never release a transport.
- Never leave the fix off `main` — a commit on a session branch alone is not shipped.
- Never import anything yourself. You have no connection to that system.
- Never build a ZIP for a paste-only object. Re-read step 1b if unsure.
