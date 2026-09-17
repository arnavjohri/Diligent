# DPR Excel (export_dpr_17.09.2026.xlsx) → CDS mapping

Workbook = output of the classic report ZPRA_DPR_REPORT (v3.0 here; the
abap2xlsx variant produces the same layout). Report date 01-JAN-2026, window
30.11.2025–31.12.2025, FY 2025-26. Copy: `DPR_export_2026-09-17.xlsx`.
Mapping done 17/09/26 against package ZPR_DPR_RAP revision v16-09.

## Sheet "DPR ( 01-JAN-2026 )" — the report

| Rows | Block | Report source | CDS today | Gap |
|---|---|---|---|---|
| 5–6 | product blocks (Oil C–P, Condensate Q–R, Gas S–AF, Total AG), asset per column | ZPRA_C_DPR_PROF + ZOIU_PR_DN | Asset / AssetDescription / Product in ZDPR_C_PROD_CUBE | none (pivot assets→columns is a UI matter) |
| 7 | ONGC Videsh share % per asset | ZPRA_T_PRD_PI.pi | ParticipatingInterest (ZDPR_C_PROD_CUBE), PiPct (ZDPR_P_DAY_BASE) | none |
| 8 | Conversion factor bbl/tonne per oil asset | ZPRA_T_TAR_CF.conv_factor | ConversionFactor in ZDPR_P_TARGET_ROW (not in any query) | expose in a query |
| 9–10 | Consortium level (assets JV, totals ONGC Videsh), units BOPD/BCPD/MMSCMD/BOEPD | fixed | JV = ProdQty1, OVL = OvlShareQty1 / ActualBoepdOvl | none |
| 11–42 | daily grid: asset × product at JV level, totals at OVL level, AG = oil+cond+gas×6290 BOEPD | ZPRA_T_DLY_PRD | ZDPR_Q_PROD_QUERY (asset/product/date), ZDPR_Q_BOEPD_TREND (totals) | none |
| 43 | Target : <month> (monthly TAR_BE per asset) | ZPRA_T_PRD_TAR gjahr/monat | ZDPR_I_TARGET / ZDPR_C_TARGET_CUBE | **data**: empty for FY 2025-26 |
| 44–45 | Prod. MTD actual, current month and same month previous year (per-day averages) | dly_prd ÷ days | cubes have the sums and CalendarYear/Month; the ÷ days is not in any query | **backend**: summary view |
| 46 | Monthly actual, previous month | ZPRA_T_MREC_PRD (reconciled) ÷ days | ZDPR_I_MONTHLY / ZDPR_C_TARGET_CUBE sums | **backend**: summary view |
| 47–48 | Target FY, YTD target | ZPRA_T_PRD_TAR annual ÷ days | ZDPR_I_TARGET_FY, ZDPR_P_TARGET_DAY | **data** empty; logic exists |
| 49–50 | YTD actual current FY and previous FY (per day) | dly_prd ÷ days | ZDPR_Q_PROD_PERF (current FY, OIL/GAS groups only, no per-asset) | **backend**: per-asset + previous FY |
| 51 | Asking rate = (annual target − YTD actual volume) ÷ days left in FY | fill_dynamic_table_sec2e | nothing | **backend**: summary view (+ data) |
| 52 | Actual Prod. previous FY (per day, whole year) | dly_prd ÷ 365 | cubes have FiscalYear dimension | **backend**: summary view |
| 53–57 | ONGC Videsh level in MMT / BCM / MMTOE: target, YTD target, YTD actual | oil: bbl ÷ CF ÷ 1e6; gas: MMSCM ÷ 1000; MMTOE = MMT oil + MMT cond + BCM gas × 1.0 | ZDPR_P_TARGET_ROW has the scaling for targets only | **backend**: tonnes view for actuals |
| 58–62 | Actual production FY 2020-21 … 2024-25 in MMT/BCM/MMTOE | ZPRA_T_MREC_PRD + ZPRA_T_TAR_CF per gjahr | ZDPR_I_MONTHLY | **backend**: same tonnes view, by FY |
| 64–67 | Remarks: asset, date, comment for the report date; plus auto text "relinquished on …" from licence expiry | ZPRA_T_DLY_PRD.comments; ZPRA_T_PRD_PI.liscense_exp_dt | neither field exposed | **backend**: add COMMENTS to ZDPR_I_DAILY + small remarks query |

Verified from the numbers (01.12.2025): AG = P + R + AF×6290 → 108,243.63 + 0 +
5.7695×6290 = 144,533.8 ✓ (BoeFactor 6290 as in CDS). MMTOE: row 57
5.1705 + 0.0026 + 2.0146 = 7.1878 ✓ → gas factor 1 BCM = 1 MMTOE. Oil MMT:
329,823.89 BOPD × 2.925 % × 275 days ÷ 7.44461 ÷ 1e6 = 0.356 ≈ C57 0.357 ✓.

## Sheet "2" — graph series
Actual Production (row 3) and BE Target (row 4) per date, one month back to
report date = ZDPR_Q_BOEPD_TREND ActualBoepdOvl / TargetBoepd. Target is 0
in the export → confirms FY 2025-26 targets are not loaded, not a bug.

## Sheet "Production Performance" — the 2×6 table + line chart
Annual/YTD × (Oil BOPD, Gas MMSCMD, Total BOEPD); Actual row = YTD only
(P49, AF49, AG49); Target row = annual (P47…) and YTD (P48…). Exactly the
four rows of ZDPR_Q_PROD_PERF (ScopeType × ProductGroup) plus a total.
Chart = sheet 2 series. Fully covered today except the TOTAL column
(needs a TOTAL group row in ZDPR_P_PERF_AGG).

## The four "open customer questions" — answered by the workbook itself
1. Annual goals source: ZPRA_T_PRD_TAR, TAR_BE rows (MMT/BCM per month). Not
   a design question, a data load for FY 2025-26.
2. Gas-to-TOE factor: 1 BCM = 1 MMTOE (row 57/58 arithmetic).
3. Remarks: ZPRA_T_DLY_PRD-COMMENTS for the report date + licence-expiry text.
4. JV vs OVL: asset columns are JV, totals are ONGC Videsh share. Both exist
   in the cubes.

## Verdict
Possible. Every cell traces to a table the CDS layer already reads. Covered
today: header, daily grid, graph, performance table, YTD actual. Needs
backend (≈2 days total): one summary query per asset (MTD, MTD-LY, monthly,
YTD, YTD-LY, annual-LY, asking rate), one tonnes query (MMT/BCM/MMTOE incl.
5-year history), remarks exposure, CF in a query, TOTAL row in PERF_AGG.
Needs data: FY 2025-26 TAR_BE targets. Needs UI: a pivot with assets as
columns and stacked headers — native in SAC tables; code in a custom OVP card.
