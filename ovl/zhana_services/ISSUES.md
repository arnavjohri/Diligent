# ZHANA_SERVICES_PRG — issue log

## 05/10/26 – 06/10/26 — CR: Download / Upload rows of the timesheet table control
- **Ask:** in Create, user keys one row, downloads the rows to Excel, fills more rows,
  uploads; uploaded rows come into the table control.
- **Decisions (Arnav):** real `.xlsx`; Create mode only; upload **replaces** the table
  control rows; marker tag `SAP_ABAP`.
- **Fix:** new FORMs `DOWNLOAD_ROWS` (CL_SALV_TABLE→TO_XML xlsx), `UPLOAD_ROWS`
  (CL_FDT_XL_SPREADSHEET, by column position), `XL_TO_DATE`, `XL_TO_DAYS`, `SET_HEADING`
  in `_MAILF01`; fcodes `DOWNLOAD`/`UPLOAD` in `USER_COMMAND_9002`; buttons excluded
  outside Create in `STATUS_9002`, `DISP`, `STATUS_9009`.
- **Manual:** SE41 status 9002 — add function codes `UPLOAD`, `DOWNLOAD` (application
  toolbar, Download last).
- **06/10/26 addition:** Scope column (`LS_DATA-SCOPE`) becomes a listbox AS IS / MICROSOFT
  (`VRM_SET_VALUES` in `STATUS_9002`); Download opens `POPUP_TO_DECIDE_LIST` radio buttons
  All / AS IS / MICROSOFT and exports only matching table-control rows (`LT_DATA` — nothing
  is read from `ZSAP_TIMESHEET`); Download now runs at the end of `USER_COMMAND_9002`, after
  Service Element / Scope derivation; Upload rejects a Scope other than AS IS / MICROSOFT.
  Not yet pasted at that point, so all markers re-dated 06/10/26 as one change.
- **Manual:** SE51 screen 9002 — Scope column attribute Dropdown = Listbox.
- **Status:** awaiting activation / test. TR: —

## 06/10/26 — Print button calls the copied print transaction
- Print program changed in a copy (see `ovl/zsap_timesheet_form_prg/`), new tcode `ZSAPT_FORM1`.
- `USER_COMMAND_9001` (`_STATUS_9O01`), `WHEN 'FORM'`: `CALL TRANSACTION 'ZSAPT_FORM'` →
  `'ZSAPT_FORM1'`. Other CALL TRANSACTIONs (table maintenance, report, ZCON) untouched.
- **Status:** awaiting activation / test. TR: —

## 06/10/26 — Scope dropdown on Create must show the domain values, not AS IS / MICROSOFT
- **Cause:** the VRM_SET_VALUES block added to `STATUS_9002` overrode the listbox, which
  before the CR showed the fixed values of the Scope domain.
- **Fix:** VRM block commented out (listbox falls back to the domain). `_MAILF01`: Download
  popup and Upload check now read the same domain fixed values at run time (new FORM
  `GET_SCOPE_VALUES`, `CL_ABAP_ELEMDESCR->GET_DDIC_FIXED_VALUES`) instead of the two literals.
- Print program `ZSAP_TIMESHEET_FORM_PRG(_CP)` deliberately left on its own AS IS/MICROSOFT list.
