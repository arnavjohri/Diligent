# HANDOVER — ZMM_ME35K_RELEASE (ZMMME35K stopped releasing after S/4 conversion)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | MM — purchasing release |
| System | OCQ, S4 2025_1_A |
| Objects | `ZMM_RM06EF00`, `SAPMZFM06L`, `ZFM06LFFR` + new include `ZFM06LFFR_FRG_SET` |
| Repo path | `kpmg/zmm_me35k_release/` |
| Ships by | **PASTE-ONLY** |
| Status | `README.md` records it as **fixed and confirmed working** — that is my claim at the time, not reproducible from the repo alone |

## What broke

The custom release transaction `ZMMME35K` stopped releasing after the ECC → S/4
conversion. Every object involved is a frozen **2003 Z copy** of SAP standard code, so the
conversion rebuilt parts of it from the modern standard and dropped the custom logic.

## Two root causes

1. **A split `FEKKO`.** `FEKKO` is declared in `FM06LFFR` as a plain program-local table —
   it is **not** in a `COMMON PART` (only `XEKKO` is, via `FM06LCFR`). Every program
   including `FM06LFFR` therefore owns a **private** `FEKKO`. `ZMM_RM06EF00` built `FEKKO`
   by calling into `SAPFM06L` but handled the click by calling into `SAPMZFM06L`, so
   `FRG_SET` read an empty table and exited silently on `CHECK sy-subrc EQ 0`.
   `FRG_UPDATE` then found no `UPDKZ = 'U'` and reported `06 022 "No data changed"`.
   The same split emptied `HIDK`.
2. **The custom `FRG_SET` was lost.** On S/4, `ZFM06LFFR` was rebuilt from the modular SAP
   standard and now reads `INCLUDE FM06LFFR_FRG_SET` — SAP's own routine. The CR 30011813
   header and the `ist_ola_pr_hdr` / `wa_ola_pr_rec` declarations survived at the top;
   every custom block inside `FRG_SET` was gone.

**"No data changed" was the reported symptom and it is a misleading one** — nothing was
wrong with the data. If it recurs, look at which program the `PERFORM` targets, not at the
document.

## The fix — three files, two of which are edit instructions

| File | Lines | What |
|---|---|---|
| `ZFM06LFFR_FRG_SET.abap` | 602 | **New Z include**, main program `SAPMZFM06L`. Restores the custom `FORM frg_set` plus `GET_1ST_PR_REL_DT` / `GET_ALL_OLAS_PRS` / `GET_OLA_PR_DTL` / `GET_OLD_PR_DTL_R` |
| `ZFM06LFFR_change.abap` | 40 | The **one-line include swap** inside `ZFM06LFFR` |
| `ZMM_RM06EF00_perform_fix.abap` | 72 | **13 `PERFORM` target corrections** `(sapfm06l)` → `(sapmzfm06l)` |

Line 343 (`frg_fekko_aufbauen`) is the actual defect; 343, 413 and 425 carry the `HIDE`.

**Activation order: `ZFM06LFFR_FRG_SET` → `ZFM06LFFR` → `ZMM_RM06EF00` → `SAPMZFM06L`.**
Syntax-check from `SAPMZFM06L`, not from the include.

Prerequisites on S/4: message class `ZMM` msg 192, `ZMM_OTH` msg 239, and
`ist_ola_pr_hdr` / `wa_ola_pr_hdr` declared in `ZFM06LFFR` (already present).

## Do not do this

- **Never edit SAP's `FM06LFFR_FRG_SET`.** `SAPFM06L` shares it, so standard ME35K / ME28 /
  ME35L would change for every user. That is the whole reason a Z include exists.
- **Do not activate `BDP_CHECK`, `CHECK_FINAL_REL` or `READ_CHANGE_DOC`** in
  `ZMM_RM06EF00` without a business decision. They are defined and never called — in ECC as
  well as S/4 — and implement tender-committee governance. Note that `CHECK_FINAL_REL` does
  `SELECT ... WHERE ebeln IN s_ebeln` then `READ TABLE ... INDEX 1`, judging the whole list
  by its first document.

## Deliberate differences from the ECC source

`ME_REL_SET` keeps the S/4 standard `EXCEPTIONS` block with E102 / E103 / E104 handling
(ECC has it commented out, which risks a short dump). `FORM ITERATION` is not carried over
— its only call site is commented out in ECC, superseded by `GET_ALL_OLAS_PRS`. Dead
commented blocks were dropped. **No executable statement was changed.**

## Known, not fixed, carried forward

These are pre-existing in the 2003 clone. None was introduced by my fix; all are still
there and could surface at any time:

- `lo_buffer->close( )` deleted, so `CL_MMBSI_SRM_CTR_BUFFER` is never reset.
- `PERFORM start_via_table_manager` deleted, so ZMMME35K stays on classic WRITE lists.
- The clone predates every SAP note since 2005 — `SELOPT_CNT_CALL`, T160L / note 1876863,
  enhancement points all missing.
- With `MM_SFWS_P2PSE`, `BSTYP='K'` + `STATU='K'` documents are deleted from the list, so
  **central contracts can silently disappear**.
- `MESSAGE a239` reads `wa_ekko_ola-bedat` after the LOOP ended, so with several OLAs it
  reports whichever was read last.
- `SY-TCODE = ZMMME35K` is passed to `ME_PURCHASE_DOCUMENT_DATA_READ` and **needs a T160
  entry**.

## Strategic note

The long-term target is to move the genuine business logic into a BAdI or a Flexible
Workflow precondition and leave SAP's ME35K untouched. Not this week's work, but it is the
right answer if this breaks again.

## Applying it

Line numbers in `ZMM_RM06EF00_perform_fix.abap` refer to the **21.08.2026** print. Locate
by FORM name and diff a fresh SE38 download before applying.
