# Issues — ZPP_FORECAST_V2

Log format: date | issue | root cause | files changed | commit | TR


---

## 15/09/26 — ZPP_FORECAST / ZCL_PP_FCST, quarterly and monthly: price, value columns, material type

Change request received 15/09/26 (three points under "Quarter and Month"). **Built on the
repo copy of 26/08/26 — no fresh SE80 download was supplied.** Diff the running versions of
`ZCL_PP_FCST` and `ZPP_FORECAST` against the repo before pasting; anything edited by hand in
the system since 26/08 is not in these files.

| # | Request | What was built | Where |
|---|---|---|---|
| 1 | Price logic: A923-MATNR → KNUMH by DATAB descending; KONP-KNUMH → KBETR | `READ_PRICES`, one read per run, latest DATAB per material, lowest KOPOS line of that KNUMH. Read on material alone, no condition type / VKORG / valid-to check, no KPEIN or KONWA — as worded, flagged `ASSUMPTION` in the method header | `ZCL_PP_FCST` private method, called after `BUILD_SCOPE` in `GENERATE_QUARTERLY` and `GENERATE_MONTHLY` |
| 2 | Columns "Price for <month> in EA" ×3, "Price for <month> in Tonnage" ×3, "Final forecast qty × Price" | `TY_ALV` gains `PRICE`, `VAL_M4..M6` (= `Mn_FCST` × price), `VAL_M4_TON..M6_TON` (= `Mn_TON` × price, per the sample 189.045 × 1.2 = 226.854), `VAL_TOTAL` (= `TOTAL_QTY` × price). Display only, not stored. Monthly shows `PRICE`, `VAL_M4`, `VAL_TOTAL` and `VAL_M4_TON`; the tonnage value follows the Tonnage Wise checkbox like `M4_TON` does. Headings carry the real month via new `FORM price_headings` | `ZCL_PP_FCST` `FILL_VALUES`; `ZPP_FORECAST` `VISIBLE_COLUMNS`, `SETUP_COLUMNS`, `PRICE_HEADINGS` |
| 3 | Material type only FERT and HAWA, TVARVC `ZPP_FORECAST_MTART` | `FILTER_MTART` reads the variable as a range (EQ rows or BT), drops every scope material whose MARA-MTART is outside it. Applied in quarterly and monthly only, not annual (the request is headed "Quarter and Month"). Unmaintained variable → no filter + new message **ZPP_FCST 022** (W) in the log | `ZCL_PP_FCST` private method |

**Point 3, "values come in quarterly but not in monthly" — no code defect found.** The two
modes share `BUILD_SCOPE`, the same date windows (`LAST_YEAR_QUARTER` + `LAST_THREE_MONTHS`,
verified identical for Q2 and period 04) and the same `HIST_QTY` lookup. The only structural
difference is the history source: quarterly sums `VBRP-FKIMG` from billing, monthly sums
`MATDOC-MENGE` for `BWART` = `ZPPT_FCST_CFG-BWART` (default 601) with `CANCELLED` blank. If
a material shows quantities in quarterly and zeros in monthly, there are no 601 goods issues
for it in MATDOC in the window, or the plant's `ZPPT_FCST_CFG-BWART` is not 601. Check in
SE16: `MATDOC` with WERKS, MATNR, BWART 601, BUDAT between the LY-quarter start and the
L3M end; and `ZPPT_FCST_CFG` for the plant. This is mandatory query **M1** of the assumptions
document (`kpmg/_docs/ZFORECAST_Adhesive_Assumptions_v2.docx`), never answered. If the
functional answer is "monthly from billing too", the switch is one call in
`GENERATE_MONTHLY`: `read_matdoc` → `read_billing` and `iv_use_billing = abap_true`.

Not touched: `ZPP_FORECAST_REPORT` (final ALV) and `ZPP_FORECAST_UPLOAD` — neither was named.
Annual mode unchanged. `ZPP_FORECAST.zip` not rebuilt (PROGDIR order defect still open, see
NOTES). The two `_nocomments` copies were not regenerated.

Manual steps: SE91 message `ZPP_FCST 022`; STVARV selection variable `ZPP_FORECAST_MTART` with
rows FERT and HAWA; confirm `A923` exists with fields MATNR, DATAB, KNUMH (SE11).

TR: not yet transported.
