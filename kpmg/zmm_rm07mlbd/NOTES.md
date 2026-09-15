# ZMM_RM07MLBD — NOTES

## What it is

`ZMM_RM07MLBD`, tcode **`ZMM_MB5B_NEW`**, package `ZMM_ABAP`. An existing custom copy of
standard `RM07MLBD` (MB5B) built by VC-ERP (Rahul Vasita, TR DEVK937941, Dec 2023),
titled "REPORT FOR MB5B VIEW WITHOUT VALUE VIEW". It carries its own Z includes:

| Include | Status vs standard |
|---|---|
| `ZMM_RM07MLDD` | enhancement points commented, ATC type fixes (UDAYABAP03 13/02/26), EWM `gt_mblnr` type added (KPMG-JP 01/12/25) |
| `ZMM_RM07MLBD_FORM_01` | older-release copy (no `/cwm/` blocks), enhancement points commented |
| `ZMM_RM07MLBD_FORM_02` | EWM `gt_mblnr` FAE join in `f1000_select_mseg_mkpf`, new `fetch_mblnr_wh_styp` (body commented) |
| `RM07MLBD_CUST_FIELDS` | standard, unchanged |

This is where the ZMB5B receipt/issue-amount function (`kpmg/zmb5b/`) was ported on
15/09/26, so the client has one custom tcode instead of two.

## Files

- `ZMM_RM07MLBD.abap` — the whole corrected main program (6,137 lines; was 5,960).
- `ZMM_RM07MLBD_units.abap` — the same change as a 10-block paste sheet, each block
  naming its FORM and the line above the insertion. **Prefer this over a whole-program
  paste**: the running program already has five lines over 120 characters (Rahul's
  `AUTHORITY-CHECK` lines with trailing comments, Raj's CSV path comment) that SE38
  would wrap on a whole-file paste and turn into bogus statements.
- `original/ZMM_RM07MLBD_SE38_print_2026-09-15.TXT` — the SE38 print listing as supplied.
- `drafts/parsed/*.abap` — the five objects reconstructed from that listing (page
  headers stripped, wrapped lines rejoined). Baseline for diffs, not supplied source.

## What was ported (main program only, marker `*BOC/EOC By Arnav on 15/09/26`)

Same seven units as `kpmg/zmb5b/src/ZMB5B_receipt_issue_amount.abap`, minus unit 7:

1. `gt_zwert_sum` work table after `INCLUDE zmm_rm07mldd`.
2. `summen_bilden` — aggregate `g_t_mseg_lean-dmbtr` per plant/material/(batch)/SHKZG for LGBST.
3. New `FORM zf_lgbst_wert_ergaenzen`, called after `bestaende_berechnen` — fills
   `bestand-sollwert/-habenwert` and `bestand-waers` (via `f9300_read_organ`, which
   lives in `ZMM_RM07MLBD_FORM_02`).
4. `create_fieldcat_totals_flat` — SOLLWERT / HABENWERT / WAERS columns for LGBST.
5. `create_table_totals_flat` — sign and colour for the two values.
6. `create_table_totals_hq` / `_hq_1` — GR and GI value lines and colour for LGBST.
7. `f0400_create_fieldcat` — DMBTR column in the detail list for LGBST (the July ZMB5B change).
8. **`gv_newdb = abap_false` for LGBST** after the `CASE p_aut` block (unit 11 in the sheet).
   Without it the amounts are blank on HANA — see Gotchas.

**Deliberately not ported: the header-block values (ZMB5B unit 7).** In this program
Rahul commented out every value line in the per-material header (`***` lines in the
"Comment Start 18.12.2023 11:05:04" block) — that is the "WITHOUT VALUE VIEW" in the
title — and the header is not covered by the `ZMB5B_NEW1` authorization check. Adding
LGBST values there would reverse his design and bypass the check. Ask before adding.

## Gotchas

- **Why the amounts were blank on the first activation (15/09/26).** This copy predates
  the standard's "Deactivate old MMIM optimization in SAPSCORE" line, so on HANA the BAdI
  `RM07MLBD_DBSYS_OPT` sets `gv_newdb = 'X'`, the stocks come from `FORM new_db_run`
  (stored procedure) and the whole classic block `summen_bilden` / `bestaende_berechnen` /
  `zf_lgbst_wert_ergaenzen` is skipped. `ZRM07MLBD` was copied from the current standard,
  which forces `gv_newdb = abap_false`, so it never hit this. Fixed by forcing it off for the
  storage location view only; the standard does it for every view.

- **Authorization gating already exists and now covers the new values.**
  `check_matnr_pa_sumfl` clears `sollwert/habenwert/waers` in the flat totals list and
  `check_g_t_belege1` clears `dmbtr/waers` in the detail list for material types the user
  lacks `ZMB5B_NEW1` for. Test with a restricted user (UT-06).
- `check_matner_xsum` (hierarchical "Totals with levels") tests `IF ls_mara IS INITIAL`,
  i.e. it only clears values for materials *not* in MARA — effectively no value gating in
  that list. Pre-existing, not touched; flag to functional if the LGBST values in that
  list need the same restriction.
- `create_table_for_detail` calls `summen_bilden` a second time on the `gv_newdb` path;
  that call returns before the new block (standard `RETURN` at the top), so the
  aggregation runs only from the main flow. Same as in ZRM07MLBD.
- Text symbols TEXT-101 / TEXT-102 / TEXT-030 / TEXT-031 already exist in this program
  (used by the BWBST branch) — nothing to add in the text pool.
- Enhancement points are all commented out in this copy; do not re-activate them.

## Shipping: PASTE-ONLY

Z copy of a standard program with Z includes of standard includes. No `src/`, no
`.abapgit.xml`. Paste the units from `ZMM_RM07MLBD_units.abap` into `ZMM_RM07MLBD` in
SE38. The three Z includes are untouched.
