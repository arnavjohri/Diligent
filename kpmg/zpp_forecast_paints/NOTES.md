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

**19/10/26 — FS read, Assumptions and Queries issued, no code.**
`docs/ZFORECAST_Paints_Assumptions_and_Queries.md` (+ `.docx`) carries seven mandatory
queries (M1–M7), the assumptions (P01–P26), further queries (Q1–Q9) and the proposed object
list. Waiting on answers and on approval of the object list.

## Proposed shape (pending approval — see the document, section 4)

- **Shared with Adhesive, unchanged:** the eight `ZPPT_*` tables, `ZPPFCST`, auth object
  `ZPP_FCST`, msag `ZPP_FCST`, `ZCL_PP_FCST_UTIL`, `ZPP_FORECAST_REPORT`, tcodes
  `ZFCST_UPL` / `ZFCST_RPT`.
- **Shared, changed:** `ZPP_FORECAST_UPLOAD` (ninth radio, brand upload; category upload
  accepts the two new indicator values), `ZCL_PP_FCST` (`READ_PRICES` made public, no
  logic change), `ZDO_MTS_MTO` (fixed values `DIS`, `TIN`).
- **New:** `ZPPT_BRAND` (+ `ZDO_BRAND`, `ZDE_BRAND`, SM30 view `ZPPV_BRAND`),
  `ZCL_PP_FCST_PNT` (enrichment: Paints columns on top of `ZCL_PP_FCST=>TY_ALV`),
  `ZPP_FORECAST_PAINTS` (tcode `ZFCST_PAINTS`, SE41 status `PF_STATUS`).
- **Not built:** a Paints copy of the engine, upload or report.

## Gotchas, already known before a line is written

- The Adhesive program `ZPP_FORECAST` is the template for the new one. Do not edit it.
- Everything shared is in functional testing on the Adhesive side with **no transport**
  and the auth bypass of 07/09 still in `ZCL_PP_FCST_UTIL`. A change to a shared object
  reaches the Adhesive testers at once. Ask for the fresh SE80 download before touching
  `ZPP_FORECAST_UPLOAD` or `ZCL_PP_FCST` — none has been supplied since 03/09/26.
- The domain change on `ZDO_MTS_MTO` touches four tables holding data. Adding fixed
  values at the same length needs no conversion; changing the length would.
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
