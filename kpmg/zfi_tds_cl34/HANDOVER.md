# HANDOVER — ZFI_TDS_CL34 (TDS Report, Clause 34)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | FI — withholding tax |
| FS | `Clause 34 TDS Report FS.xlsx` v1, 21/08/2026 |
| Objects in SAP | `ZFI_TDS_CL34` (exec) + includes `_TOP` / `_SCR` / `_FORMS` |
| Repo path | `kpmg/zfi_tds_cl34/` |
| Ships by | **PASTE.** The abapGit ZIP does not import — see below |
| Status | **LIVE IN DEV, RUNNING, OUTPUT RECONCILED** |

## Where it stands

All four programs are **activated and produce correct output**. Two live runs are on record:

- Run 1 — company code 1000, FY 2026, **49 rows**. Arithmetic reconciled on a sample
  including the threshold case `(6,000,000 − 5,000,000) × 0.1% = 1,000`. All three GL
  derivation branches resolve. Closed queries Q9, Q10, Q11, Q14, Q17, Q18, Q19.
- Run 2 — second company code, **17 rows, every one reconciles**, no blank GL, no status
  message. Added the `EKKN-SAKTO` branch (WBS assignment) to proven coverage.

Three changes went in **today, 07/09/26** — they are in the repo but have **not been
through a live run yet**:

1. `WHLDGTAXITEMSTATUS NOT IN ('V','D','M','S')` added to the driver `WHERE`, so
   non-reportable items no longer reach the ALV. Filtered in the database, so every
   downstream buffer and the GL-gap counts narrow with it. Raised as **Q26**.
2. `S_LIFNR` moved from `FOR with_item-wt_acco` to `FOR lfa1-lifnr` — same CHAR 10,
   same value, but data element `LIFNR` brings the vendor F4 **and** the ALPHA exit, so
   the user stops typing `0000100025` by hand. Existing variants stay valid.
3. New `FORM f4_section_code` + two `AT SELECTION-SCREEN ON VALUE-REQUEST` blocks —
   section-code F4 built from the codes **actually posted** in the company code and
   fiscal year already on the screen, so every code offered returns rows.

**If the user reports anything odd on the selection screen this week, it is almost
certainly one of these three.** They are the newest code in the whole KPMG set.

## This is the object most likely to generate mail while I am away

It is the only KPMG object with real users running it against real data. Everything else
is either delivered-and-quiet or blocked.

## Open queries — `docs/QUERIES.md`

The ones that would change a number on the report:

| Q | Question | Owner |
|---|---|---|
| Q1 | Column Y accumulation rule — `FIWTIN_ACC_EXEM` keyed by `SECCO` | Ankita Parikh |
| Q2 | Columns U–X certificate pick — `SECCODE` / `FIWTIN_TANEX_SUB` unrestricted | Ankita Parikh |
| Q3 | Is a valuation grouping code active (OMWM)? `T001K-BWMOD` unverified | Bhavin Suthar |
| Q6 | Reversed (`BKPF-STBLG`) / parked (`BKPF-BSTAT`) documents — reported today, FS silent | Client decision |
| Q20 | Should customer withholding items be excluded? No `KOART` filter today | Ankita Parikh |
| Q21 | Sign convention on amount columns — negative today. If flipped it must be `× −1`, **never** `ABS( )` (a credit memo comes through positive against the invoice's negative) | Ankita Parikh |
| Q22 | Exclude zero-deduction rows and noted items? | Ankita Parikh |
| Q24 | Rows 27–29 and 38 do not reconcile rate against amount — certificate-specific source data, **not** a code defect (proved by run 2) | Ankita Parikh |
| Q26 | The status filter added today — confirm V/D/M/S is the right exclusion set | Ankita Parikh |

**None of these is a defect.** If any comes back answered this week, log it and leave the
code change for my return — each is a one-form change and none is urgent.

## If something breaks this week

| Symptom | Almost certainly | Do this |
|---|---|---|
| Column F/G blank on many rows | GL could not be derived — the report says so in one aggregated status message | Read the message; it names the distinct reasons, capped at 170 chars |
| Columns E and U–Y all blank together | Vendor has no PAN (`LFA1-J_1IPANNO`, **CHAR 40**) | Column-wide blanks = investigate; scattered blanks = normal |
| Report refuses every company code | Authorisation object `F_BKPF_BUK` (`BUKRS`, `ACTVT 03`) — **Q16, unconfirmed** | Basis. This is the one open query that can stop the report dead |
| Fewer rows than last week | Expected — the 07/09 status filter | Not a defect |
| Vendor code returns nothing | Should be fixed by today's change | Confirm the user is on the newly pasted `_SCR` |

## Do not do this

- **Do not retry the abapGit ZIP.** Four attempts, four short dumps
  (`XML_FORMAT_ERROR` / `CX_XSLT_FORMAT_ERROR` in `FROM_XML`, `ZABAPGIT_STANDALONE`).
  Well-formedness, encoding, `package.devc.xml`, `TPOOL` `KEY` items and `PROGDIR`
  element order were each ruled out or fixed — the last was a genuine defect and the dump
  survived it. Root cause never established because **the failing file was never
  identified from ST22**. If anyone does try again, capture the filename abapGit names in
  the `FROM_XML` frame *before* changing anything.
- **Do not "fix" the `AWKEY` / `RMRP` deviation.** The FS says test `AWKEY = 'RMRP'`;
  `RMRP` is `BKPF-AWTYP`. Testing on `AWKEY` matches nothing and **fails silently** —
  every PO invoice drops to the direct-FI branch and column F goes wrong with no error.
  Proven correct by both live runs. Q14.
- **Do not correct the column X heading spelling** ("Ceritificate"). Deliberate — logged
  as Q13 with the reasoning in the source.
- **Do not remove the second `IF gt_dockey IS INITIAL` guard.** It is unreachable and a
  review asked for its removal; it stays because removing it leaves the only unguarded
  `FOR ALL ENTRIES` in the program. A comment in the source says exactly this.
- **Do not add a field to a `SELECT` without adding it at the same index of the `TYPES`.**
  This already cost one activation cycle here — `GHKON` was being written into `H_BUDAT`.
- **Do not exceed 120 characters on a source line.** A 256-char trailing comment wrapped
  on paste and produced `"REPORT_GL_GAPS" is invalid here (due to grammar)` at a line that
  looked innocent.

## Before anyone changes this

Ask for a fresh SE38 download (`ZR_PROG_DOWNLOAD`, program + include tree) and diff it
against `src/`. Locate by FORM name, never by line number. Tick **Fixed point arithmetic**
on any newly created program — every `SELECT` here is strict ABAP SQL and will not compile
without it, and the error text points at the SQL, not the attribute.

## Contacts

Ankita Parikh — FI / TDS · Bhavin Suthar — MM / account determination
