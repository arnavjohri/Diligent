# ZPP_FORECAST_PAINTS — NOTES

## What it is

ZFORECAST for the **Paints** division (WRICEF ID-2B), Astral / UDAY, KPMG. FS is
`fs/Forecast_Template-Paints_1.xlsx`, received 19/10/26; `fs/*.extract.txt` is its text,
sheet by sheet, so it can be grepped without openpyxl.

It is the Adhesive forecast (`kpmg/zpp_forecast_v2/`) with a different column layout:
brand, plant name, pack size, DPL, quantity per carton, gross weight, volume in KL and
value in crores per month, tonnage on gross weight ÷ 1000, two more MTS/MTO values. The
arithmetic, the uploads, the save layouts and the tables are the Adhesive ones, and the FS
names the Adhesive tables.

## Status

**19/10/26 — FS read, Assumptions and Queries issued (v2), no code.**
`docs/ZFORECAST_Paints_Assumptions_and_Queries.md` (+ `.docx`) carries the reuse decision
per Adhesive object (§0.1), seven mandatory queries (M1–M7), assumptions (P01–P26),
further queries (Q1–Q10), the proposed object list (§4) and 28 defects found in the FS
(§8). Waiting on answers and on approval of the object list.

## Standing rule: no Adhesive program or class is edited for Paints

Arnav's call, 19/10/26: the Adhesive objects work and are in functional testing. Paints
calls them and shares their tables; anything Paints-specific is a new object. The v1 idea
of adding a ninth radio to `ZPP_FORECAST_UPLOAD` and opening `READ_PRICES` in
`ZCL_PP_FCST` is withdrawn.

## Proposed shape (pending approval — see the document, §0.1 and §4)

- **Shared with Adhesive, unchanged:** the eight `ZPPT_*` tables, `ZPPFCST`, auth object
  `ZPP_FCST`, msag `ZPP_FCST`, `ZCL_PP_FCST`, `ZCL_PP_FCST_UTIL`, `ZPP_FORECAST_REPORT`,
  and `ZPP_FORECAST_UPLOAD` for six of its eight types (tracking, exclusion, history,
  business forecast Q/M, change Q/M). Tcodes `ZFCST_UPL` / `ZFCST_RPT` serve both.
- **One DDIC touch:** `ZDO_MTS_MTO` gains fixed values `DIS`, `TIN`, length unchanged. No
  conversion, no code. The zero-touch alternative (a Paints-only indicator in the brand
  table) is recorded and rejected in §0.1.
- **New:** `ZPPT_BRAND` (+ `ZDO_BRAND`, `ZDE_BRAND`, SM30 view `ZPPV_BRAND`),
  `ZCL_PP_FCST_PNT` (enrichment: Paints columns on top of `ZCL_PP_FCST=>TY_ALV`, own
  A923 price read for annual, tonnage on gross weight ÷ 1000, KL and crores),
  `ZPP_FORECAST_PAINTS` (tcode `ZFCST_PAINTS`, SE41 status `PF_STATUS`),
  `ZPP_FORECAST_PAINTS_UPL` (tcode `ZFCST_PAINTS_UPL`: category with four indicator
  values, and brand — the two uploads the shared program cannot take).
- **Not built:** a Paints copy of the engine or the report.
- **Known duplication:** the A923 price read (~30 lines) and the upload file handling
  (~400 lines) exist twice. A fix on the Adhesive side has to be repeated here.

## Gotchas, already known before a line is written

- `ZPP_FORECAST` and `ZPP_FORECAST_UPLOAD` are templates for the new programs. Copy from
  a fresh download, never edit them.
- Everything shared is in functional testing on the Adhesive side with **no transport**
  and the auth bypass of 07/09 still in `ZCL_PP_FCST_UTIL`. Paints inherits the bypass;
  restoring it restores both. The material-type filter TVARVC `ZPP_FORECAST_MTART`
  applies to Paints through the engine (Q7).
- The domain change on `ZDO_MTS_MTO` touches four tables holding data. Adding fixed
  values at the same length needs no conversion; changing the length would.
- Paints plants need their own `ZPPT_FCST_CFG` rows (sales org 4000) — configuration,
  not code, but only if a plant never carries both divisions (M1).
- Screen-free, like Adhesive: `CL_SALV_TABLE` only, no `CALL SCREEN`, no
  `cl_gui_custom_container`. The SE41 status is the one manual GUI object.
- Pack size: `MARM` has several alternative units per material; the rule for which one
  is query M5. Do not build it on a guess.

## Shipping

Paste, one object at a time, as Adhesive has shipped since 15/09/26. `src/` and
`.abapgit.xml` will be added when the first object is written so the folder stays
ZIP-capable; the ZIP path has not been proven on this landscape since the 03/09 PROGDIR fix.

## Layout

    fs/        the FS as received, plus its text extract — never edited
    docs/      Assumptions and Queries (md + docx); TS when written
    original/  SE80 downloads of the shared objects, filed with save-original.sh
    src/       corrected / new objects, once there are any
    ISSUES.md  running log
