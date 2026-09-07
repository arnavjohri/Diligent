# KPMG — HANDOVER, all objects

**Arnav Johri, Associate Consultant, Diligent Global — away 08/09/26 – 14/09/26.**
Prepared 07/09/26. Client Astral Limited, project UDAY.

One handover file per object sits in each object folder as `<object>/HANDOVER.md`.
This page is the rollup: where everything stands, what can actually land while I am out,
and the traps that would cost someone a day.

---

## The one-minute version

| # | Object | Module | Status | Ships by | Live? |
|---|---|---|---|---|---|
| 1 | [`zfi_tds_cl34`](zfi_tds_cl34/HANDOVER.md) — TDS Clause 34 report | FI | **Running, output reconciled.** 3 changes made today, not yet run live | Paste | **Yes** |
| 2 | [`zmm_vend_upload`](zmm_vend_upload/HANDOVER.md) — mass vendor/BP upload, FSD 30 | MM | Delivered as 10 change units + TS | Paste (delta) | Unconfirmed |
| 3 | [`zmmims`](zmmims/HANDOVER.md) — GeM invoice F4 + auto-display | MM | Delivered, 2 whole includes + 2 fragments | Paste | Unconfirmed |
| 4 | [`zmb5b`](zmb5b/HANDOVER.md) — receipt/issue amount on MB5B | MM | Delivered, program + 7-unit paste sheet | Paste | Unconfirmed |
| 5 | [`zmm_me35k_release`](zmm_me35k_release/HANDOVER.md) — ZMMME35K release fix | MM | Recorded as fixed and working | Paste | Claimed |
| 6 | [`zsd_exc_approval`](zsd_exc_approval/HANDOVER.md) — WRICEF 141 A/B | SD | **Built ahead of answers. 16 open FS questions, 1 hard blocker** | ZIP, paste fallback | No |
| 7 | [`zpp_forecast_v2`](zpp_forecast_v2/HANDOVER.md) — ZFORECAST Adhesive | PP | Built. **ZIP carries an unfixed defect** | abapGit ZIP | No |
| 8 | [`zsd_scheme`](zsd_scheme/HANDOVER.md) — Scheme (Pipes) | SD | Built. Largest manual footprint in the set | Paste | No |
| 9 | [`zmm_po_budget`](zmm_po_budget/HANDOVER.md) — PO budget control | MM | **Blocked — two contradictory designs both present** | Hybrid | No |
| 10 | [`zmm_po_budget_deferred`](zmm_po_budget_deferred/HANDOVER.md) — budget check class | MM | Parked, wired to nothing, not importable as it stands | — | No |
| 11 | [`zpp_forecast`](zpp_forecast/HANDOVER.md) — ZFORECAST v1 | PP | **Superseded. Do not ship** | — | No |
| 12 | [`abapgit_pilot`](abapgit_pilot/HANDOVER.md) — abapGit proof of concept | — | PoC, never confirmed to have imported | — | No |

**"Unconfirmed" means the code was delivered and there is no activation or issue record in
the repo — not that it is broken.** I have not claimed a state I cannot evidence.

---

## What can actually reach you this week

**Only object 1.** `ZFI_TDS_CL34` is the one KPMG object with real users running it against
real data — two live runs on record, 49 and 17 rows, all reconciled. Everything else is
either delivered-and-quiet or blocked on someone else.

Three changes went into it **today** and have not been through a live run:
the withholding-status filter (V/D/M/S excluded), vendor-code F4 + ALPHA conversion, and a
new section-code F4. **If anything odd is reported on that selection screen, it is almost
certainly one of those three.** Detail and the symptom table are in
`zfi_tds_cl34/HANDOVER.md`.

The one open query that could stop the report dead is **Q16** — whether `F_BKPF_BUK` is the
right authorisation object. If it is wrong, the report refuses every company code and
nobody can run it. That is a Basis question, and it is the only open item on any KPMG
object that is worth interrupting someone for.

---

## Waiting on other people, not on me

| Object | Waiting for | From |
|---|---|---|
| `zsd_exc_approval` | **The L4/L5/L6 name source.** The FS says "Submit program `SAPLSLVC_FULLSCREEN`" — that is the generic ALV full-screen function group: not a program, not `SUBMIT`-able, holds no data. Unguessable. Blocks **both** reports | Sanjay Modhvadiya |
| `zsd_exc_approval` | 15 further FS questions — 4 would change a number, 2 would stop the table activating | Sanjay Modhvadiya / Parth Shah |
| `zfi_tds_cl34` | Q1, Q2, Q6, Q20, Q21, Q22, Q24, Q26 | Ankita Parikh (FI/TDS) |
| `zfi_tds_cl34` | Q3 — valuation grouping code active? | Bhavin Suthar (MM) |
| `zmm_po_budget` | Scope decisions 1 and 5 (scheduling agreements; direct vs indirect) | Functional |

**If any answer arrives: log it against its numbered question and leave the code for my
return.** Every one of these is a contained change and none is urgent. Applying them
piecemeal against a half-answered FS is how a sign convention gets baked in wrong.

---

## Traps that would cost someone a day

These are the things a person picking up cold would not see coming.

1. **`zmm_po_budget` has two mutually exclusive designs in the same folder.**
   `MANUAL_STEPS.md` §3 describes a BAdI `CHECK` calling `ZCL_MM_PO_BUDGET_CHECK`;
   the delivered snippet does the opposite — inline code in the **already existing**
   `ME_PROCESS_PO_CUST` implementation, no class. **Both cannot be live. Confirm in SE19
   before activating either.** The same `MANUAL_STEPS.md` also misdescribes the ZIP
   contents (says 6 objects including a class; it is 7 files and no class).

2. **`zpp_forecast_v2`'s ZIP will short-dump if anyone imports it.** All three `prog.xml`
   files carry `PROGDIR` as `NAME, SUBC, FIXPT, VARCL, UCCHECK`; correct is
   `NAME, VARCL, SUBC, FIXPT, UCCHECK`. Found 03/09/26, **verified still present 07/09/26**.
   Its `NOTES.md` still calls it "the only object that ships this way cleanly" — that claim
   predates the finding and is not supported by any record of a successful import.

3. **`zsd_scheme/src/SAPMZSD_SCHEME.abap` is five includes concatenated into one file.**
   Creating the module pool means creating **five includes, not one program**.

4. **`zmm_vend_upload/NOTES.md` is stale** — it says the folder is empty on `main` and the
   code is on a `claude` branch. Untrue since 27/08/26. The `HANDOVER.md` in that folder is
   the current one.

5. **`abapgit_pilot` collides with `zmm_po_budget`** — same object names, different field
   count, no message class. Importing both into one system will collide.

6. **`zpp_forecast` v1 and v2 have genuinely different inventories** — different classes,
   different message class, five tables v1 has that v2 does not. Pulling a v1 table
   definition into a v2 system produces orphans.

---

## About abapGit on this landscape — read before promising anyone a ZIP

**No hand-written abapGit ZIP has ever been confirmed to import here.**

- `zfi_tds_cl34` — four attempts, four short dumps (`XML_FORMAT_ERROR` /
  `CX_XSLT_FORMAT_ERROR` in `FROM_XML`). Well-formedness, encoding, `package.devc.xml`,
  `TPOOL` `KEY` items and `PROGDIR` order were each ruled out or fixed; the last was a
  genuine defect and the dump survived it. **Root cause never established, because the
  failing file was never identified from ST22.** It shipped by paste.
- `zpp_forecast_v2` — no record of an import, and it carries the `PROGDIR` defect above.
- `abapgit_pilot` — no record of an import.
- `zsd_exc_approval` — `PROGDIR` order is **correct** (verified 07/09/26), but that fixes
  one known defect; it does not make the ZIP proven.

**So: try a ZIP if it is convenient, and have the paste route ready. Never schedule around
one working.** If anyone does attempt an import and it dumps, the single most useful thing
they can do is capture **which file abapGit names in the `FROM_XML` frame** from ST22
before changing anything — every fix so far was made without that, and three of four were
wrong.

---

## Standing rules for anyone touching this code

Full detail is in `CLAUDE.md` at the repo root. The five that bite hardest:

- **Get a fresh SE80/SE38 download and diff it against the repo copy before changing
  anything.** The repo is a snapshot, not necessarily the running version — several of
  these objects have other authors in them. `ZR_PROG_DOWNLOAD` pulls a program with its
  full include tree.
- **Locate by FORM / MODULE name, never by line number.** Every patch sheet in this repo
  carries line numbers bound to one specific print.
- **Comment old code out, never delete it**, inside `*BOC By Arnav on DD/MM/YY` …
  `*EOC By Arnav on DD/MM/YY`. Never nest or double-wrap markers.
- **Keep source lines under ~120 characters.** Everything here ships by paste, and SE38
  wraps a long line: the tail lands on the next line without its `"` prefix and becomes a
  bogus statement, reported at a line that looks innocent. This has already cost one
  activation cycle.
- **A SELECT field list and its target type are matched by POSITION, not by name.**
  Inserting a field in the SELECT without inserting it at the same index of the `TYPES`
  silently fills the wrong component — or fails activation naming two fields that look
  unrelated. This has also already cost one cycle.

## What stays manual, always

Transport release · anything touching QA or production · sending mail · ATC exemption
requests · object deletion · SE51 screens · SE41 GUI statuses · SE54 maintenance views ·
SNRO number ranges · SU21 auth objects · SCDO change documents. abapGit does not serialise
any of the last six, so they never appear in a generated ZIP.

---

## Contacts recorded in the repo

| Name | For |
|---|---|
| Ankita Parikh | FI / TDS — `zfi_tds_cl34` queries |
| Bhavin Suthar | MM / account determination — `zfi_tds_cl34` Q3, Q14 |
| Sanjay Modhvadiya | Prepared both WRICEF 141 A/B FS documents |
| Parth Shah | Commented on 141.B (his comment is open question 5) |

---

*Every statement above is drawn from the repository as it stands on 07/09/26. Where a
status could not be evidenced from the repo it is marked "unconfirmed" rather than
guessed.*
