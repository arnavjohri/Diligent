# ZMM_BP_CREATE_MAIL — notes

**What:** Daily job that e-mails the details of every supplier BP created the previous day
(FS 057_BRD_FS, Astral, Om Prakash 28.07.2026, routed via Ankit). KPMG - UDAY / Astral,
module MM.

**Ships by:** paste. Single report, no includes, no screen, no DDIC. Text symbols,
selection texts, program attributes, TVARVC, SE93, SM36 and SCOT steps are in
`ZMM_BP_CREATE_MAIL_TEXTS.md`. No `src/`, no `.abapgit.xml` — do not zip.

**Files**

| File | Purpose |
|---|---|
| `ZMM_BP_CREATE_MAIL.abap` | the corrected/current object, whole |
| `ZMM_BP_CREATE_MAIL_TEXTS.md` | text elements + manual steps checklist |
| `QUERIES.md` | assumptions, queries, answers, risks |
| `fs/057_BRD_FS_New_BP_creation_mail.doc` | FS as received |
| `fs/057_extract.md` | text extract of the FS (formatting lost — AN ID strike-out noted by hand) |
| `ISSUES.md` | running log |

**Gotchas**

- The FS `.doc` is Word 97 binary; the text extract was pulled from the raw file and loses
  strikethrough. Arnav confirmed AN ID is struck; check the original before trusting any
  other line as "in scope".
- Precedence on the selection screen is checkbox-first (Q1). A variant with the checkbox
  ticked ignores any date range typed into it.
- Recipient logic is ADR6 CONSNUMBER `004` / `005` **by position** (Q3) — data entry order
  in the BP address decides who gets the mail. Functional accepted the risk.
- ~~One mail per run to everyone (Q10 / R1)~~ — replaced 05/10/26: one mail per BP, sent as up
  to three separate mails (MDM / ADR6 004 / ADR6 005). A supplier now sees only its own data.
  10 BPs -> up to 30 mails per run; each is committed on its own, so one failure does not undo
  the rest. The per-BP result is in the log column ("MDM: sent; Supplier Manager (004): sent ...").
- Subject is 63 chars, longer than `CREATE_DOCUMENT`'s 50 — set via `SET_MESSAGE_SUBJECT`.
- Nothing prevents a manual re-run from sending the same day's mail again (by decision).
- Mail leaves the system only when the SCOT send job runs; check SOST first when "nothing
  arrived".
