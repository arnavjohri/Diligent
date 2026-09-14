---
name: status
description: Build Arnav's work-visibility report from git log, ISSUES.md and INBOX.md, grouped by project. Use when he wants his throughput written up for his team or management — triggers on "status report", "weekly summary", "what did I do", "what did I ship", "update for my manager", or an end-of-week wrap-up. Produces paste-ready bullets plus a STATUS.md rollup. Never sends mail.
---

# Write the status report

Arnav wants his throughput visible. Visibility only works if every line survives being
checked — a manager can open the commit.

## The rule that makes this work

**Every claim traces to a commit SHA or an ISSUES.md entry. If it traces to neither, it
does not go in the report.**

An inflated status report is worse than no status report, because it gets caught, and
after it gets caught the honest ones stop being believed. Three forms of inflation, all
banned:

- Work that did not happen.
- In-progress work described as complete. A fix awaiting Arnav's verification is not
  delivered. A ZIP not yet imported is not live.
- One item restated as three to make the list look longer.

## 1. Fix the period

Derive it, then **echo the window as explicit dates before collecting anything**. A
correct report over the wrong window is still wrong.

Default for "weekly" or end-of-week: Monday 00:00 of the current week to now. For "what
did I do" with no window, ask.

Check the existing `STATUS.md` first. If its period overlaps the new one, say so — the
same work must not be claimed in two reports.

## 2. Collect the evidence

**Git.** Single branch — everything is on `main` (`CLAUDE.md`). The old `claude`,
`documents` and `draft-code` branches were merged in and no longer exist on origin, so
`--all` is harmless but adds nothing.

```bash
git log --all --author="Arnav" --since=<start> --until=<end> \
  --date=short --pretty=format:'%h %ad%d %s' --stat
```

**ISSUES.md.** One per object folder (`ls */ISSUES.md`). Take entries dated inside the
window. These are richer than commit subjects — issue, root cause, files, commit SHA,
TR. A folder without an ISSUES.md simply has no logged issue; do not infer one.

**INBOX.md.** Read for *state*, not for credit. It says what is open, blocked or closed
as of its last triage. Note the triage date — anything after it is invisible to the file.

Reconcile the three and keep the mismatches visible:

| Mismatch | How to report it |
|---|---|
| Commit, no ISSUES.md entry | Report the commit as-is. Do not invent a root cause. |
| ISSUES.md entry, no commit in window | "logged, no commit in this period". |
| INBOX item closed, nothing else | Not a deliverable. Mention under closed, no credit. |

## 3. Group by project

| Project | Belongs to it |
|---|---|
| **OVL** | anything under `ovl/` — ZPRA DPR, ZFI_JV_TB, ZFI_CP_MASS_VEN_PAY, ZBNK_APP1/2, ZAA_IMPAIRMENTLOSS, CJ88/FLQ, ATC remediation, JV cash call, OCV transfer, ZF01 exchange rate |
| **KPMG** | anything under `kpmg/` — ZFI_TDS_CL34, ZSD_EXC_APPROVAL (WRICEF 141), ZPP_FORECAST / v2, ZMM_PO_BUDGET, ZMM_ME35K, ZMMIMS, ZSD_SCHEME, ZMM_VEND_UPLOAD, ZMB5B / ZRM07MLBD, FSD/TS documents |
| **GAIL / MWC / RWS** | `gail/`, `mwc/`, `rws/` — their own heading, only if the window touches them |

The top-level folder of the changed path decides the project. A commit that touches no
client folder (`scripts/`, `CLAUDE.md`, `.claude/skills/`) goes under **Repo / tooling**.
Never move an item to a group to make that group look fuller.

## 4. Classify each item — the wording matters

| State | Evidence | Say |
|---|---|---|
| Delivered | commit on `main` + ISSUES.md entry with TR filled | "delivered, TR \<n\>" |
| Fix ready | commit exists, TR blank in ISSUES.md | "fix ready for verification" |
| Packaged | ZIP built, not imported | "packaged; import pending" |
| Analysis / doc | commit that touches only `docs/`, `*.md` or `.docx` files | "TS drafted", "FS reviewed" |
| In flight | open in INBOX.md, no commit | "in progress" — In flight section only |

The blank TR is the tell. `/ship-fix` leaves it blank until Arnav fills it in after
import, so a blank TR means the change is not in the system yet. Never round that up to
"done".

## 5. Output A — the mail bullets

Terse, grouped under **OVL** and **KPMG**, one line per item: object, what changed,
state. No adjectives — no "successfully", "comprehensive", "significant", "robust".

```
OVL
- ZMM_ME35K: release strategy fix for S/4 conversion — delivered, TR D2K912345
- ZPRA DPR: RAP build guide written up — doc only, no transport

KPMG
- ZMB5B: receipt/issue amount columns — fix ready for verification (a1b2c3d)

In flight: ZMM_VMS number range error (awaiting SNRO detail from Basis)
Blocked: CR 2A/2B FS — waiting on sign-off
```

Print it in a fenced block so he can copy it straight into a mail. If the week produced
three bullets, print three.

## 6. Output B — STATUS.md

Overwrite `STATUS.md` at the repo root; the history lives in git. Longer rollup, same
facts, per item: object, what changed, root cause in one line, files, commit SHA, TR or
state. Then **In flight**, **Blocked**, and **Not done** (anything carried over that a
reader might expect to see finished).

End it with a **Sources** line — the git range used, which ISSUES.md files were read,
and INBOX.md as of its triage date. That line is what makes the report checkable.

## 7. Name what the report cannot see

Always close with it. Mail answered, meetings, debugging that produced no commit,
verification cycles, calls with functional — all real work, none of it in git. List the
category, leave it for Arnav to fill in from memory, and do not manufacture entries for
it.

## When the period is thin

Say so plainly. A quiet week reported as quiet costs nothing. Never spread one commit
across four bullets, never promote reading a document to a deliverable, and never pull
last month's work forward to fill the page.

## Never

- **Never send mail.** No send, no reply, no draft, no forward. Produce text; Arnav sends
  it. Sending is on the manual-always list in `CLAUDE.md`.
- Never present anything as tested or running. You cannot execute against that system.
- Never state a TR number that is not written in an ISSUES.md entry.
- Never invent an object name, a reporter, a date, or a root cause.
- Never commit or push `STATUS.md`. Git is `/ship-fix`'s job, and Arnav reads the report
  before anyone else does.
