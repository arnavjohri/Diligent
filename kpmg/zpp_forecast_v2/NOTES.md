# ZPP_FORECAST_V2 — NOTES

## What it is

ZFORECAST (Adhesive), Astral / UDAY, built to `Forecast Template-Adhesive.xlsx` dated
20.08.2026. Paints (WRICEF ID-2B) out of scope. **Supersedes `zpp_forecast/` (v1).**

- `ZCL_PP_FCST` — calculation engine (global class).
- `ZCL_PP_FCST_UTIL` — FY / quarter / period / tonnage helpers (global class).
- `ZPP_FORECAST` (tcode ZFCST) — three radio modes.
- `ZPP_FORECAST_REPORT` (tcode ZFCST_RPT) — final ALV.
- `ZPP_FORECAST_UPLOAD` (tcode ZFCST_UPL) — eight upload types with template download
  (`gui_download` template + `gui_upload`).

## Gotchas

- **Screen-free by design, and that is load-bearing.** Everything displays through
  `CL_SALV_TABLE` full screen: there is no SE51 screen and no SE41 GUI status anywhere in the
  repo — rows are picked with the standard SALV selection column instead of a checkbox, and
  Save is added to the SALV toolbar. A grep for `CALL SCREEN` / `^MODULE ` / `SET PF-STATUS` /
  `cl_gui_custom_container` across `src/*.abap` returns nothing. This is precisely what makes
  the object abapGit-shippable and why v1 was rewritten. **Do not reintroduce `CALL SCREEN`
  or `cl_gui_custom_container` here** — doing so converts the whole repo back to paste-only.
- `LVC_T_FNAME` is not available in every release, so the column-name list is typed locally
  over `LVC_FNAME`.
- Every table name in the source document exceeds SAP's 16-character limit and had to be
  renamed (`ZPP_ADH_FORECAST_YEAR` → `ZPPT_FCST_YR`, etc.); `ZPP_ADHESIVE_SNRO` → `ZPPFCST`
  because number range objects are capped at 10. The rename table is in
  `00_TECHNICAL_OBJECTS.md`.
- `ZDO_REASON` (CHAR 40) already exists and is reused, not created.
- Sources are exactly as the document specifies: annual and quarterly from VBRK / VBRP
  summing `VBRP-FKIMG`; monthly from MATDOC `BWART 601` summing `MATDOC-MENGE`; old material
  codes from MATDOC; legacy flag from `ZPPT_SLS_HIST` M01–M12. `VBRP-SHKZG` was verified in
  the system on 21.08.2026 against the FS wording.
- Two places where the document's prose and its worked example disagree are documented in
  `00_TECHNICAL_OBJECTS.md` §9 — **read that before "fixing" a formula**.
- `ZPPT_FCST_CFG` holds what the document hardcodes (VKORG default 1100, BWART default 601,
  legacy TVARVC name) so config changes need no code change. MTS/MTO lives on
  `ZPPT_PROD_CAT`, not in a table of its own.
- Do not mix DDIC or class names with v1 — the inventories genuinely differ (see
  `zpp_forecast/NOTES.md`).

## Dependencies

8 tables, 7 domains, 8 data elements, message class `ZPP_FCST`, number range `ZPPFCST`,
auth object `ZPP_FCST` (WERKS + ACTVT), SM30 views `ZPPV_PROD_CAT` / `ZPPV_MAT_TRACK` /
`ZPPV_MAT_EXCL` / `ZPPV_FCST_CFG`, tcodes ZFCST / ZFCST_RPT / ZFCST_UPL.

## Shipping: abapGit ZIP

The only object in this repository that ships this way cleanly. `.abapgit.xml`
(`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`) is correctly at the ZIP root; `src/` holds
package.devc, the 2 classes, 3 reports, 7 domains, 8 data elements, 8 tables and msag
`zpp_fcst`. Built `ZPP_FORECAST.zip` = 36 files.

Import via `ZABAPGIT_STANDALONE` → New Offline Repo → Import package from ZIP → Pull.

**Re-zip from `src/` rather than trusting the existing archive** — `ZPP_FORECAST.zip` was
rebuilt 23.08 while several `src/` XMLs date from 20–21.08.

## Stays manual regardless

SE93 tcodes ZFCST / ZFCST_RPT / ZFCST_UPL · SNRO `ZPPFCST` · SU21 `ZPP_FCST` ·
SE54 for the four SM30 views.

## Duplicate copies — none authoritative except `src/`

`zpp_forecast_v2/zcl_pp_fcst_nocomments.abap` is a comment-stripped paste copy of the engine
for when SE24 paste is preferred over an import, and `zpp_forecast_v2_nocomments.abap` exists
at the repository root as well. Both drift silently from
`src/zcl_pp_fcst.clas.abap`, which is the source of truth — keep them in step or delete them.
