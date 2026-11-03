# ZFI_ACDOCA_JVA_ALIGN — Assumptions and Queries

Project OVL · design agreed in chat 02/11/2026 (`ovl/z_jva_alignment/NOTES.md` §6) · prepared 02/11/2026

| # | Question | From | Assumed in the code | If wrong |
|---|---|---|---|---|
| 1 | Document type `ZJ` without OBA7 entry — acceptable? | Arnav, 02/11 | Hardcoded constant `gc_blart`; the INSERT does not check T003. SE16 T003 must have no `ZJ`. | If `ZJ` exists or a type is created later: change the constant **before** the first update run; after posting, changing it orphans the lines for the undo. |
| 2 | Meaning of `MIG_SOURCE = 'U'` on this release | reference program | Constant `gc_mig_source = 'U'`, as `Z_JVA_ALIGNMENT` writes it. | SE11 → ACDOCA → MIG_SOURCE → domain value range. If `U` is asset / ML related, pick the value for JVA or leave it blank — one constant. |
| 3 | Marker fields BSTAT, VORGN, BTTYPE, LINETYPE, XSPLITMOD | SE16H CA001J0000, 02/11 | Left blank, as on the migrated ACDOCA-only lines on OCQ. | If GR data release or an FI consistency check wants a value (SAP's own JVA direct postings use BSTAT `U`, VORGN `RFRA`, AWTYP `BKPFF`): add them in `build_acdoca_line`, three lines. |
| 4 | Currency keys RKCUR / ROCUR / RFCCUR | SE16H 02/11: RKCUR differs per company code | `SELECT DISTINCT` on the company code's existing 0L lines of the file's year; first non-blank value wins. | A company code with mixed keys in one year fails the check "local currency differs from T001" or picks the wrong ROCUR — fix the data or hardcode per company code. |
| 5 | Transaction currency | decision 02/11 | RTCUR = RWCUR = local currency, TSL = WSL = HSL. | If document-currency reporting of the alignment lines matters, RTCUR must come back into the recon key and the file. |
| 6 | Posting date | decision 02/11 | Last day of the period; 013–016 = last day of 012; 000 = first day of the fiscal year. | Change FORM `period_date`. |
| 7 | Third currency mandatory when ROCUR exists | design 02/11 | Document-level error when the company code has ROCUR, the document has non-zero HSL and no OSL at all. | Downgrade to a warning: remove the second `err_document` call in `file_checks`. |
| 8 | Which `F_BKPF_BUK` activity | not stated | `01` for the update run and for the undo. | Change the two `AUTHORITY-CHECK` statements. |
| 9 | Account nets to zero per company code / year / period | design 02/11 | Hard error on all rows of the account; nothing posts. | None — a non-zero changes an account balance in 0L and must not be posted. |
| 10 | WBS element in the file: with or without mask separators | not stated | PRPS by `POSID` as typed, then with every non-alphanumeric character removed. | If PRPS stores a different form, use `CONVERSION_EXIT_ABPSP_INPUT` — its exception names must be checked in SE37 first. |
| 11 | Order existence only, no company code check | not stated | `AUFK` by order number. | Add `AND bukrs = @cs_line-rbukrs` to that SELECT. |
| 12 | Period 000 | decision 02/11 | Accepted and posted (first day of FY, all accounts). Recon does not produce 000 rows yet. | None in this object; recon step 2. |
| 13 | Target system and release | not stated | OCQ/500. `cl_fdt_xl_spreadsheet` (BRFplus, 7.02+), `FIRST_DAY_IN_PERIOD_GET` / `LAST_DAY_IN_PERIOD_GET`, `find( occ = -1 )`, inline declarations. No `FIELDS`, no `FINAL`, no `+=`. | Activation error names the statement; all four have fallbacks. |
| 14 | Recovery indicator master table T8JJ — column names? | activation 03/11/2026: `RECIN` unknown, and `JVNAME` unknown on T8JV | T8JJ is not read. FORM `check_recid` tests that the indicator was posted with the venture in that fiscal year on ledger 4A (`JV_JVSO1_ACDOCA`, names confirmed by active `ZFI_JV_TB`), cached per combination. | If a master-data check is wanted: SE11 T8JJ → field names → one SELECT in `check_recid`. |
