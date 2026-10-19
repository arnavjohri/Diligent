# Issues — ZPP_FORECAST_PAINTS

Log format: date | issue | root cause | files changed | commit | TR

## 19/10/26 — FS received, Assumptions and Queries issued

`Forecast_Template-Paints_1.xlsx` filed under `fs/`. Read end to end (five sheets). It is
the Adhesive template with a different column layout and names the Adhesive tables as its
own. `docs/ZFORECAST_Paints_Assumptions_and_Queries.md` (+ `.docx`) raises M1–M7
(shared tables and plant separation, brand table and length, four MTS/MTO values, Paints
sales organisation, pack-size unit rule, per-month additional, annual column set),
assumptions P01–P26, further queries Q1–Q9, and the proposed object list: new
`ZPPT_BRAND` + upload type, new `ZCL_PP_FCST_PNT`, new `ZPP_FORECAST_PAINTS`; shared
engine, upload, report and tables reused.

No code written. Waiting on answers, approval of the object list, and a fresh
`ZR_PROG_DOWNLOAD` of `ZPP_FORECAST_UPLOAD`, `ZCL_PP_FCST`, `ZCL_PP_FCST_UTIL`,
`ZPP_FORECAST`.

TR: none.
