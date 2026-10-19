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

## 19/10/26 PM — v2: no Adhesive program or class is edited for Paints

Arnav's rule: the Adhesive code works and stays as it is. The v1 object list changed two
Adhesive objects (`ZPP_FORECAST_UPLOAD` ninth radio, `ZCL_PP_FCST` `READ_PRICES` made
public); both withdrawn. Replacement: a Paints upload program `ZPP_FORECAST_PAINTS_UPL`
for the two uploads the shared one cannot take (category with DIS/TIN, brand) and the
price read re-implemented inside `ZCL_PP_FCST_PNT` for the annual mode. The one DDIC
touch left is the two fixed values on `ZDO_MTS_MTO` (no conversion, no code), with the
zero-touch alternative recorded. §0.1 of the document now gives the reuse decision per
Adhesive object; §8 lists 28 defects found in the FS (F01–F28). Q9 added (report Month
and Quarter both mandatory), old Q9 is now Q10.

Files: `docs/ZFORECAST_Paints_Assumptions_and_Queries.md` / `.docx`, `NOTES.md`.
TR: none.
