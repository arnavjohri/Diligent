# DPR reconciliation — production date 25.10.2026 — QAS (interface) vs PRD (manual)

Both extracts are from `ZPRA_T_DLY_PRD`, pasted by Arnav on 27.10.2026. PRD rows were keyed
per asset by the asset users (CREATED_BY 94521 / 96029 / 105013 / 60749); QAS rows came from
one CPI → `ZCL_ZPRA_DAILY_PROD_DPC_EXT` run (SAP_ABAP, 26.10.2026 11:00:03). The three empty
SE16 columns between QTY and COMMENT in the paste are not kept in the TSVs.

Files: `prd_extract_ZPRA_T_DLY_PRD.tsv`, `qas_extract_ZPRA_T_DLY_PRD.tsv`,
`DPR_QAS_vs_PRD_Discrepancies_25.10.2026.xlsx` (Summary / Discrepancies / Reconciliation /
QAS only / Interface notes — same layout as `../2026-10-06/`).

## Result — 17 PRD rows

| Outcome | Rows | Which |
|---|---|---|
| Exact match | 6 | RUS_SK1 oil: ARKUTUN NET+WINJ, CHAYVO NET, LEBEDINSKI NET, ODOPTU NET+WINJ |
| Match within rounding | 3 | RUS_VAN NET (.56 vs .60), SSU_SPO NET (8,553.088 vs 8,553), VEN_CAR NET (7,162.361 vs 7,162) |
| Wrong value | 2 | RUS_VAN GROSS_PROD 10.734 vs 10,734,000 M3 (x1,000,000, open since 06.10); VEN_CAR GROSS_PROD 0.192 vs 6.77 MCF (m3 column instead of MMPCD: 6.77 / 35.3147 = 0.1917) |
| Missing in QAS, non-zero in PRD | 3 | RUS_VAN WATER_INJ 283,500 M3; VEN_CAR GAS_FLARE 6.59; VEN_CAR INT_CONS 0.18 |
| Zero row not posted (by design, 06/10/26 fix) | 3 | RUS_SK1 CHAYVO + LEBEDINSKI WATER_INJ 0; RUS_VAN GAS_INJ 0 |

COMMENT is wrong on every interface row that carries one: SSU_SPO has three spilled numeric
cells where PRD has "HIGH WC (65.4%)"; VEN_CAR has a report header; RUS_SK1 has a Russian
text fragment ("к добыче: OP-22").

## QAS-only rows (21) — nothing in PRD to compare

RUS_IEC (7 rows, 4 blocks) and RUS_SK1 gas (13 rows). RUS_IEC gas now arrives in m3, so the
x1,000 finding from 06.10 looks resolved there; MAISKOYE vs MAISKOYEGRP block still differs.
RUS_SK1 LEBEDINSKI INT_CONS 467,496 M3 against GROSS_PROD 6,661 M3 is implausible (70x) —
almost certainly a wrong cell in the SK1 gas mapping.

All causes sit in CPI / the source mapping, not in the ABAP class: the class stores the number
as sent (no scaling), drops blank and zero measures, and copies COMMENT verbatim.
