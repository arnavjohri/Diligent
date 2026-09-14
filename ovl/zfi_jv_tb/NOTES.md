# ZFI_JV_TB (tcode/report commonly called "ZJVTB") — Joint Venture Trial Balance

**Project:** OVL (ONGC Videsh) · system OCQ · package/TR: TBD
**Purpose:** venture-wise Trial Balance / Balance Sheet / P&L for the JV ledger (4A).
Users export the ALV to an Excel template workbook whose `RawData` sheet feeds the
BS/PL summary sheets.

## Shipping method
Paste-only for now. Corrected copy: `ovl/zfi_jv_tb/ZFI_JV_TB.abap`
(loose file at folder root; overwritten by each fix, git history keeps earlier ones). Single report, no includes (`REPORT` statement in the supplied
download reads `zzjvtb_test`, so the download may have been taken from a test copy —
**confirm the real object name before any edit**).

## How the venture columns are built (the part that matters)

- `AT SELECTION-SCREEN` builds `lt_alljv`:
  `SELECT DISTINCT rjvnam FROM jv_jvto1_acdoca_4a_4c_switch`
  `WHERE ryear = p_year AND rbukrs = p_bukrs AND rjvnam IN p_jvnam`
  `AND rldnr = '4A' AND rrcty = '0' AND rrecin IN p_rrecin`.
  No period filter here — `s_period` is used only by the JVSO1 line-item selects.
- `row_count > 10` sets `flg1 = 'X'` → the **dynamic** branch: only Closing Balance
  columns, one per venture, field catalogue built by `LOOP AT lt_alljv`
  (`BAL_CLO<tabix>`, coltext `Closing Bal <RJVNAM>`), dynamic table via
  `cl_alv_table_create=>create_dynamic_table`, display via
  `REUSE_ALV_GRID_DISPLAY_LVC`.
- `row_count <= 10` → the static branch with hardcoded `BAL_OPN1..10` (opening / debit /
  credit / closing per venture).

**Consequence:** the ALV grid and the Excel export share one field catalogue. There is no
separate download logic. A venture that has no column on screen has no column in Excel,
and vice versa.

## Master source for venture codes
`T8JVT` (BUKRS, VNAME, VTEXT) — already used by the `p_jvnam` F4 help in this program.
That is the "73 venture codes" list the business quotes; the posted-totals view is not.

## Gotchas
- **Ledger.** All reads of `JV_JVTO1_ACDOCA_4A_4C_SWITCH` were `RLDNR = '4A'`. JV data on
  this landscape spans 4A **and** 4C (`ZOCV_OVL_TRANSFER_F01` reads both). Reading 4A alone
  drops the carry-forward (`HSLVT`) → blank opening balance. Corrected copy uses
  `IN ( '4A', '4C' )` on the totals view only; the `JV_JVSO1_ACDOCA` line-item reads stay
  on 4A. Whether 4A/4C are split or parallel ledgers is unconfirmed — see ISSUES #2.
- Opening balance is `HSLVT` (`KSLVT` for USD) from the totals view and nothing else.
- `break abapuser02.` is left in `get_data` and in `disp_data` — hard-coded user
  breakpoint in a productive report.
- In the single-currency data-fill loop the `READ TABLE lt_fieldcat ... WITH KEY coltext`
  has **no `sy-subrc` check**; on a miss it reuses the previous `ls_fieldcat-col_pos` and
  writes the amount into the wrong column.
- The supplied file is an SE38 **list** download (page headers, line numbers, cross-
  reference index at the end), not usable as paste source. A clean source download
  (`ZR_PROG_DOWNLOAD` or SE38 → Utilities → Download) is needed before any correction.
