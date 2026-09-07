# HANDOVER — ZPP_FORECAST v1 (SUPERSEDED)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | PP |
| Repo path | `kpmg/zpp_forecast/` |
| Status | **SUPERSEDED by `kpmg/zpp_forecast_v2/`. DO NOT SHIP** |

## In one line

Version 1 of ZFORECAST (Adhesive), built to the **earlier** `Forecast Template-Adhesive.xlsx`
of **14.08.2026** and assumption register B01–B42. Kept only for the reasoning trail.

## Why it was replaced

`ZPP_FORECAST` here drives its ALV through `CALL SCREEN 0100` (l.140) with
`MODULE status_0100 OUTPUT` (l.234), `SET PF-STATUS 'S0100'` (l.250) and
`cl_gui_custom_container` container `'CC_ALV'` (l.351). That means a hand-built SE51 screen
and SE41 status, which abapGit cannot serialise — so v1 could **never** ship as a ZIP.
v2 rebuilds the same function on `CL_SALV_TABLE` and eliminates the screen entirely.

## The risk this week, and it is real

**Do not mix the two versions.** The object inventories genuinely differ, and the two
`00_TECHNICAL_OBJECTS.md` files are built to **different source documents**:

| | v1 (here) | v2 (ship this) |
|---|---|---|
| Classes | `ZCL_PP_FORECAST` / `ZCL_PP_FORECAST_UTIL` | `ZCL_PP_FCST` / `ZCL_PP_FCST_UTIL` |
| Message class | `ZPP_FORECAST` | `ZPP_FCST` |
| Extra tables | `ZPPT_FCST_ADJ`, `ZPPT_FCST_BUS`, `ZPPT_LOAD_FCT`, `ZPPT_FCST_EXCL`, `ZPPT_MTS_MTO` + structures `ZPPS_FCST_ALV` / `ZPPS_FCST_HIST` | none of these |

Load factor and MTS/MTO were folded into `ZPPT_PROD_CAT` in v2. **Pulling a v1 table
definition into a v2 system produces orphans.** Never cite one version's DDIC while
shipping the other.

## Still worth reading

`docs/00_TECHNICAL_OBJECTS.md` documents the 16-character rename decisions, and the
reasoning behind keying the annual table on plant + material + financial year rather than
on the forecast number — which makes "the same material cannot be saved twice in a
financial year" a property of the data model instead of a coded check. That reasoning
carried into v2 and is not written down anywhere else.

## If anyone asks

v1 is history. Point them at `kpmg/zpp_forecast_v2/HANDOVER.md`.
