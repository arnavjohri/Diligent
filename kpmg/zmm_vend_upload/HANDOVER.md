# HANDOVER — ZMM_VEND_UPLOAD (mass vendor / BP upload, FSD 30)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | MM — Supplier / Business Partner |
| FS | FSD 30 — `30 FSD_ZMM_VEND_UPLOAD - upload program.doc` |
| Program | `ZMM_VEND_MASTER`, tcode `ZMM_VEND_UPLOAD`, package `ZMM_ABAP` |
| Includes | `_TOP`, `_SCR`, `_CL`, `_FORMS` |
| Repo path | `kpmg/zmm_vend_upload/` |
| Ships by | **PASTE** (delta units, not a whole-file replacement) |
| Status | Enhancement delivered as 10 change units + TS. No activation or issue record in the repo |

## Read this before you read `NOTES.md`

**`NOTES.md` in this folder is stale and will mislead you.** It says the folder is "empty
on `main`" and that the code lives on a `claude` branch. That has not been true since
27/08/26 — the folder holds five source files under `src/` (3,601 lines total), the TS in
two formats, the FSD, and the delta units under `drafts/`. Single branch is `main`.

I have left `NOTES.md` as it is rather than rewrite it on my way out; **this file is the
current one**.

## What the enhancement does

`ZMM_VEND_MASTER` already created Supplier BPs from an uploaded Excel file and already had
an Extend path. FSD 30 adds four things:

- **R1** — record-level Success/Warning/Error with row number, on-screen ALV log, and a
  **download of failed records only**.
- **R2** — auto-extension to Company Code and Purchasing Org with **independent status per
  role** and **"already extended"** detection.
- **R3** — a separate **Change** mode (`rb_chg`): only file-populated fields updated, blank
  cells never overwrite master data, BP number mandatory.
- **R4** — validation and duplicate checks (GST / PAN / Tax): invalid records skipped and
  logged, and **one bad record never stops the batch**.

## Why it is a delta, not a full file

The baseline supplied was an **SE38 print listing** — tokens run together, page headers,
line numbers — not clean compilable ABAP. So the changes are delivered as clean,
compile-ready **units** in `drafts/ZMM_VEND_MASTER_FSD30_changes.abap`, each marked
`NEW` / `MODIFIED` with exact placement and the change tag `"FSD30`. Routines not listed
are unchanged from the baseline.

`drafts/README.md` has the full unit table (units 1–10) and the FSD-requirement → unit
mapping. `src/` holds the reconstructed complete includes.

## The units, in one line each

| Unit | Include | Type | What |
|---|---|---|---|
| 1 | `_TOP` | MOD | Add `rowno`, `stat_cc`, `stat_po` to `ty_log` / `ty_log_ex` |
| 2 | main | MOD | `START-OF-SELECTION`: call `validate_create`, activate Change mode, route error-only download |
| 3 | `_FORMS` | NEW | `validate_create` — mandatory + duplicate (GST/PAN) checks, drops bad rows |
| 4 | `_FORMS` | NEW | `validate_change` — BP mandatory and must exist |
| 5 | `_FORMS` | MOD | `extend_bp` — shared by Extend **and** Change; no hard stop, already-extended detection (LFB1/LFM1), blank-safe `datax`, per-role status |
| 6 | `_FORMS` | MOD | `create_bp_vendor` — set `msgty` S/W/E + `rowno`; stop silently dropping no-company-code rows |
| 7 | `_FORMS` | MOD | `display_log` — ALV columns Row No, BP Number, Supplier Name, Status, CC/PO Ext., GST, PAN, Message |
| 8 | `_FORMS` | NEW | `download_error_log_cr` — error-only download (create) |
| 9 | `_FORMS` | NEW | `download_error_log_ex` — error-only download (extend/change) |
| 10 | `_SCR` | NOTE | No structural change; label `rb_chg` as "Change" |

## Open points before transport

- **O4 — duplicate-check precedence** (GST vs PAN vs Tax No.), and whether a DB-level PAN
  match is an **error** or just a **warning**. Not answered.
- Company-code / purchasing-org fields are **assumed present and valid in the file** (an
  FSD assumption). Validation warns rather than hard-fails where it can.
- Confirm the message class if formal message IDs are preferred over literal text. Today it
  is literal text.

## If a user reports a problem this week

The most likely complaint is **"a row was skipped and I do not know why"**. That is what R1
was built to answer — send them to the error-only download, which carries the row number
and the message. If the log is empty for a skipped row, that is a real defect and worth
capturing the input file for my return.

## Underlying APIs

Create — `BAPI_BUPA_CREATE_FROM_DATA` / `BAPI_BUPA_CENTRAL_CHANGE`, roles FLVN00 / FLVN01.
CC + Purchasing — `vmd_ei_api=>maintain_bapi` (CC via `LFB1`, Purchasing via `LFM1`,
partner functions via `WYT3`).
