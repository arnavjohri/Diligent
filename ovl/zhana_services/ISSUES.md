# ZHANA_SERVICES_PRG — issue log

## 05/10/26 — CR: Download / Upload rows of the timesheet table control
- **Ask:** in Create, user keys one row, downloads the rows to Excel, fills more rows,
  uploads; uploaded rows come into the table control.
- **Decisions (Arnav):** real `.xlsx`; Create mode only; upload **replaces** the table
  control rows; marker tag `SAP_ABAP`.
- **Fix:** new FORMs `DOWNLOAD_ROWS` (CL_SALV_TABLE→TO_XML xlsx), `UPLOAD_ROWS`
  (CL_FDT_XL_SPREADSHEET, by column position), `XL_TO_DATE`, `XL_TO_DAYS`, `SET_HEADING`
  in `_MAILF01`; fcodes `DOWNLOAD`/`UPLOAD` in `USER_COMMAND_9002`; buttons excluded
  outside Create in `STATUS_9002`, `DISP`, `STATUS_9009`.
- **Manual:** SE41 status 9002 — add function codes `DOWNLOAD`, `UPLOAD` (application
  toolbar).
- **Status:** awaiting activation / test. TR: —
