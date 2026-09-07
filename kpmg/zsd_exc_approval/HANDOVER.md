# HANDOVER — WRICEF 141 A/B, Exceptional Approval

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | SD |
| FS | `141.A ... Adhesives.docx`, `141.B ... Paints.docx`, both 24.08.2026, prepared by Sanjay Modhvadiya. Supplied 02/09/26 |
| Objects | 141.A: `ZSD_EXC_APPR_ADHESIVE` (report only). 141.B: table `ZSD_EXP_PAINTS` + TMG, `ZSD_EXP_PAINTS_UPLOAD`, `ZSD_EXC_APPR_PAINTS` |
| Repo path | `kpmg/zsd_exc_approval/` |
| Ships by | ZIP attempted (`ZSD_EXC_APPROVAL.zip`, 19 files, 14 objects) with paste as the fallback |
| Status | **BUILT AHEAD OF ANSWERS — 16 open FS questions, one of them a hard blocker** |

## Where it stands

Code is written and reviewable:

- `ZSD_EXC_APPR_ADHESIVE.abap` — 1,247 lines (141.A)
- `ZSD_EXC_APPR_PAINTS.abap` — 982 lines (141.B report)
- `ZSD_EXP_PAINTS_UPLOAD.abap` — 1,522 lines (141.B upload)
- DDIC for 141.B: 5 domains, 6 data elements, table `ZSD_EXP_PAINTS`

It was built deliberately ahead of the functional answers so there is something concrete
to review against — **not** because the questions are settled. They are not.

## The hard blocker — nobody can close this without functional

**Question 1: the L4 / L5 / L6 Name source.** Both FS documents say *"Submit program
`SAPLSLVC_FULLSCREEN`, fetch L4 Name"*. `SAPLSLVC_FULLSCREEN` is the generic ALV
full-screen function group — it is not a program, it is not `SUBMIT`-able, and it holds no
data. There is no way to guess this. What is needed back is the real source: a report
name, or the table/field holding the sales hierarchy (KNVP partner functions? a Z
hierarchy table? an HR org level?).

**Every other open item can wait. This one blocks both reports.**

## The other 15, in `ISSUES.md`

Grouped by who has to answer:

**Would change a number** — 4 (Actual OS as on commitment date: BSID holds open items as
of *now*, not as of a past date; needs BSID + BSAD with `AUGDT >` commitment date),
6 (Non-Fulfilment Amount — the stated formula and the sample row disagree and the **sign
is opposite**; the sample looks copied from the Adhesives doc), 7 (Default % of
Non-Fulfilment divides by Actual Credit Limit — undefined at zero, and for Paints dividing
a collection shortfall by a credit limit looks wrong), 16 (`UKMBP_CMS_SGM` is keyed by
partner **and credit segment**; a customer with several segments has several
`CREDIT_LIMIT` values and the FS names neither a segment nor a rule).

**Would stop the table activating** — 9 (no currency key field for the CURR amounts —
**cannot activate without one**; "Month" given as length `MM-YYYY`, which is a format not a
length; SR. No. has no stated number source), 8 (the table declares `ZEXC_AMOUNT` and
`ZEX_AMNT`, output maps `ZEXC_AMNT`, which matches neither).

**Selection screen contradictions** — 5, 10, 11, 12, 13, 14.
**Not yet specified at all** — 2, 3, 15 (FS says "Authorization TBD").

## The ZIP

`ZSD_EXC_APPROVAL.zip` is 141.B only — 14 objects. 141.A is not in it.
Its `PROGDIR` element order is **correct** (`NAME, VARCL, SUBC, FIXPT, UCCHECK`) —
verified again 07/09/26. That fixes one known defect but does **not** make the ZIP proven:
no hand-written abapGit ZIP has ever imported on this landscape, and the `zfi_tds_cl34`
failure was something else and is still unexplained.

**Try it; if it dumps, fall back to `ZSD_EXP_PAINTS_DDIC.md` for the DDIC and paste for
the two programs. Do not schedule around it working.** Steps are in
`ABAPGIT_UPLOAD_STEPS.md`; what is deliberately left out (foreign keys, enhancement
category, log-data-changes, the TMG) is in `ZIP_IMPORT_NOTES.md`.

## If functional answers arrive this week

Log the answer against its numbered question in `ISSUES.md` and **leave the code**. Every
one of the 16 is a contained change, none is urgent, and applying them piecemeal against a
half-answered FS is how the sign convention on item 6 gets baked in wrong.

The exception: if the **L4/L5/L6 source** comes back, that is worth capturing in detail
while the person who answered is still reachable.

## Contacts

Sanjay Modhvadiya — prepared both FS documents · Parth Shah — commented on 141.B
(his comment on the Actual Collection date range is question 5, and it contradicts the
mapping table)
