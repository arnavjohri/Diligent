# ZMM_TMS_STATUS — Tender Monitoring Status report

**Project:** OVL (ONGC Videsh) · dev OCD/500 · tcode ZMMTMSSTATUS
**Object:** executable report `ZMM_TMS_STATUS`, no includes (1533 lines). Author S P Yadav
(CAB_SPYADAV, 11.02.2008), CRs 30008847 / 30010328 / 30010728 / 30012147 (lipsy, 2015).
Also launched from the TMS module pool `SAPMZMMTMS` (tcode ZMMTMS): the Reports button,
function code `REP` in `user_command_0100` of MZMMTMSI01, does
`SUBMIT zmm_tms_status VIA SELECTION-SCREEN AND RETURN`.

## What it does
Selects `ZMM_PUR_TENDER_D` (+ `ZMM_TMS` for indentor / CPA filters), builds `ist_data`
(`ty_data` = `INCLUDE STRUCTURE zmm_tms` + tender-document fields + day-count fields) and
shows it with `REUSE_ALV_GRID_DISPLAY`. Field catalog is SLIS, built by `append_fldcat`
with tabname / fieldname / seltext_l / hotspot / outputlen only (no ref_tabname, no datatype).
Layout: zebra, colwidth_optimize, detail_popup, reprep, expand_all. Events: `TOP_OF_PAGE`
(`REUSE_ALV_COMMENTARY_WRITE` with `i_logo = 'ZONGC'`) and `USER_COMMAND`
(`process_user_command`: hotspots to ZMMTMSDISP, ME23N / ME_DISPLAY_PURCHASE_DOCUMENT, ME53N).

## Shipping method
Plain report, so ZIP is possible in principle, but hand-written abapGit XML has never imported
on this landscape (see CLAUDE.md). Plan on **paste** via SE38. Corrected object, when there is
one, goes at the folder root as `ZMM_TMS_STATUS.abap`.

## What is in `original/`
- `ZMM_TMS_STATUS.txt` — `ZR_PROG_DOWNLOAD` output, OCD/500, user SAP_ABAP, 28.10.2026
  10:22. Line-numbered, main program only (the report has no includes). Baseline for drift.

## Gotchas
- The ONGC logo is drawn by `REUSE_ALV_COMMENTARY_WRITE` into the HTML pane above the grid
  splitter. It is not part of any export; do not blame it for Excel problems.
- `tabname = 'IST_DATA'` with no `ref_tabname`: all type information comes from the internal
  table at runtime. Any column whose type the export cannot map will fail silently.
- `no_out` must be `space` or `'X'`, nothing else. The original passed `'0'` (constant `c_out`)
  for every column: the grid still drew them, but Change Layout listed none as displayed and
  the spreadsheet export wrote an empty workbook. Fixed 28/10/26.
