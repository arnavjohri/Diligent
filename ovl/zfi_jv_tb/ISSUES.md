# ZFI_JV_TB — issue log

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 26/08/26 | Q1 FY27 run: last venture **VN2012** not populated in the Excel output (`RawData` sheet). Reported by Gitesh S Lad, Corporate Accounts. | **Still open.** The Excel-template theory was wrong — see "Retraction" below. Current lead: the export is truncated at a fixed `BAL_CLO<k>`, consistent with a saved ALV layout hiding every venture field above the number the layout was saved with. | Not yet determined. | n/a | **RETRACTED 27/08/26 — see below. Reopened.** |
| 2 | 13/09/26 | Opening balance blank in every venture column since the program was moved from `JVTO1`/`JVSO1` to the ACDOCA views. Dr/Cr still correct. | Opening balance is `HSLVT` from the totals view and nothing else (all 8 write sites traced). Fresh download 22/09/26 shows the live program reads **`JV_JVTO1_ACDOCA`** — the ACDOCA-only branch. SAP's `JV_JVTO1_ACDOCA_SWITCH_2` (definition supplied by Arnav from OCQ/500) unions that branch for years ≥ the JVA-on-ACDOCA activation year (`JVAONACDOCAACTIV`, id `START`) with legacy JVTO1 (`JV_JVTO1_T8JTPM`) for earlier years; the live view has no legacy branch. Second, independent defect: `Index Based USD` branch summed `hslvt` where the original was `SUM( kslvt ) AS hslvt`. | `ovl/zfi_jv_tb/ZFI_JV_TB.abap` (22/09/26, tag `SAP_ABAP`): all five reads of the totals view → `jv_jvto1_acdoca_switch_2`; USD branch restored to `SUM( kslvt ) AS hslvt`. Ledger stays `= '4A'` — in `_SWITCH_2` the 4C amounts are columns (`HSLVT_4C`), not rows. `JV_JVSO1_ACDOCA` reads untouched. The 14/09 ledger-widening fix is **withdrawn** (built on the 26/08 copy, which was not the live view). | n/a | **Corrected object delivered — awaiting Arnav's test ("values coming or not we will see")** |

## How it was localised (26–27/08/26)

Ruled out in order, each with evidence:

1. **Export/template column limit?** Not a hard limit — `ZJVTB_24.07.2026_Final.xlsx` has 75 columns
   (A1:BW776) including `Closing Bal VN2012` with 109 non-zero rows, against
   `ZJVTB for Q1 FY27 … 04.08.2026.xlsx` with 74 (A1:BV779). Same 74 headers, same order.
2. **Venture list SELECT dropping VN2012?** No. Breakpoint on the `SELECT DISTINCT rjvnam`
   in `AT SELECTION-SCREEN`: `lt_alljv` contained VN2012, last of 27 in the test run.
3. **Field catalogue losing it?** No. `lt_fieldcat` had all 29 entries —
   `BAL_CLO27` / `Closing Bal VN2012` at `col_pos 29`, positions contiguous 1…29.
4. **Saved ALV layout hiding the new column?** No. The column is displayed in the grid, and
   the direct download from that same list carries it.
5. **Template export.** Only the "upload the Excel" path loses it. `RawData` defined name is
   74 columns wide. Root cause.

The 24.07.2026 file reconciles with this: its `RawData` name is still `$A$1:$BV$765` while its
content runs to BW776 — it was produced by the direct download and put into the workbook by
hand, not by a template export.

## Separate defects noted, not fixed

- Four `break abapuser02.` statements left in a productive report — source lines 550, 1047,
  1151, 1561 of the filed baseline.
- `disp_data`, single-currency fill loop: `READ TABLE lt_fieldcat … WITH KEY coltext` has no
  `sy-subrc` check. On a miss it reuses the previous `ls_fieldcat-col_pos` and writes the
  amount into the wrong venture's column.
- Field names are positional (`BAL_CLO<sy-tabix>`), so `BAL_CLO27` means a different venture
  depending on what the selection returned. Any saved ALV layout is therefore only valid for
  one particular venture set.
- Object name unresolved: the `REPORT` statement reads `zzjvtb_test` while the SE38 print
  header says `ZFI_JV_TB`. Arnav confirms this is what runs in the backend.

## Retraction, 27/08/26 — the template named range was NOT the cause

Test run `ZJVTB Mock 2 Testing 27.08.2026xlsx.xlsx`, exported against the widened
template (`RawData` = `$A$1:$CZ$5000`), came back **worse**: 18 columns, i.e. 2 + 16
ventures, against 27 ventures in `lt_alljv`.

Two findings kill the template theory:

1. The output's own `RawData` defined name reads `RawData!$A$1:$R$692` — exactly the 18
   columns written. **The export rewrites that name to match what it produced.** It is an
   output of the export, not a constraint on it. Widening it to CZ had no effect because
   nothing reads it.
2. The 16 ventures written are exactly the **first 16 of the 27** in `lt_alljv`, in order.
   Dropped: MM1702, MM2002, MM2012, MM2013, RU2002, SD1102, SD2002, SY2002, VN1101,
   VN1102, VN2012.

So this is not "the last column is missing" — it is a clean cut after `BAL_CLO16`. Q1 FY27
had the same shape, cut after `BAL_CLO72`, which left only VN2012 missing and made it look
like a last-column defect.

### Current lead

A cut at a fixed `BAL_CLO<k>` matches a **saved ALV layout**. Field names are positional
(`BAL_CLO<sy-tabix>`), so a layout saved when a run had k venture columns knows
`BAL_CLO1…BAL_CLO<k>`; anything above lands in the hidden column set, and hidden columns
are not exported. `REUSE_ALV_GRID_DISPLAY_LVC` is called with `i_save = 'A'` and
`i_default = 'X'`, so a default layout is applied automatically.

Awaiting from Arnav, on one run: grid column count, the Change Layout (Ctrl+F8) hidden
pane contents, and whether an ALV variant is involved at all or "upload a layout" only
ever meant the Excel file in the export dialog.

The widened template in `template/` is harmless but does nothing. Do not ship it.
The draft mail in `MAIL-2026-08-27-gitesh.md` must not be sent.

## Issue 2 — notes (13–14/09/26)

- Base for the corrected file is the 26/08 download. It does **not** contain the ATC change
  dated 08.08.2026 (`SKA1` → `I_GLAccountInChartOfAccounts`, in
  `ovl/atc/corrections/ZFI_JV_TB.abap`). Two divergent versions exist; which one is live is
  unconfirmed. **Paste the six change sites, not the whole file**, unless the live program is
  confirmed to match 26/08 — a whole-file paste would silently revert the ATC change.
- The 26/08 repo copy carries `ls_jvt-racctrjvnam` (missing space) at three `READ TABLE
  lt_jvto1` lines in `set_data`. That does not activate, so it is a transcription defect in
  the filed copy, not the live source. Restored in the corrected file without markers.
- Not touched, deliberately: the `READ TABLE lt_jvto1` at those same three sites has no
  `sy-subrc` check and the following `READ TABLE lt_ska1` keys off the possibly stale
  `ls_jvto1-racct`. Real defect in the same path, separate from what was reported.
- `break abapuser02.` ×4 still in place (see "Separate defects" above).

## Issue 2 — update 22/09/26

- Fresh source pasted by Arnav, filed as `original/ZFI_JV_TB.2026-09-22.abap`. Drift vs the 26/08
  baseline: the five totals-view reads say `jv_jvto1_acdoca` (baseline said
  `jv_jvto1_acdoca_4a_4c_switch`); the three `racctrjvnam` lines have their space — that was a
  transcription defect in the 26/08 copy, as suspected. Nothing else differs.
- `JV_JVTO1_ACDOCA_SWITCH_2` fields confirmed from the DDL: `rldnr rrcty rvers ryear rbukrs rjvnam
  racct rrecin hslvt kslvt` plus `hsl01..16`, `ksl01..16`, and `_4c` twins of all amount columns.
  Swap is the view name only. Arnav: "4A is there."
- Whether `HSLVT` is populated for activation-year-and-later rows depends on the JVA carry-forward
  having been posted into ACDOCA. Not resolvable from code; Arnav testing.
- Open, not touched: `READ TABLE lt_jvto1` ×3 in `set_data` has no `sy-subrc` check and the next
  read keys `lt_ska1` off the possibly stale `ls_jvto1-racct`; four `break abapuser02.`; in the
  160206 block `lv_crebal` takes `ls_jvso1_2-hsl` and `lv_debbal` takes `ls_jvso1_1-hsl` (sources
  swapped); in the 120170 rollup `lv_debbal_u = lv_debbal_i + ...` accumulates onto the INR total.
