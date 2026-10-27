# ISSUES — ovl/zpra_dpr

## ZCL_ZPRA_DAILY_PROD_DPC_EXT (CPI inbound OData, ZPRA_T_DLY_PRD)

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 06/10/26 | Measures sent as 0 still create rows in ZPRA_T_DLY_PRD | BUILD_PROD_ROWS skipped only the literal text '0'; CPI sends 0.000 / 0.00 | Skip on blank text, then skip when the converted PROD_VL_QTY1 = 0 (BUILD_PROD_ROWS only) | open |

Baseline: `original/ZCL_ZPRA_DAILY_PROD_DPC_EXT.abap` (repo copy, 14/08/26). Running class from
SE24 filed 06/10/26 as `original/ZCL_ZPRA_DAILY_PROD_DPC_EXT.2026-10-06.abap`: no code drift (only signature comments / method order).

## Reconciliations

| Date | Scope | Result | Folder |
|---|---|---|---|
| 08/10/26 | CPI payload (CallActivity_12) vs PRD, 06.10.2026 | x1,000 / x1,000,000 gas scaling (RUS_IEC, RUS_VAN, BRA_BC1), block mapping, DD-MM-YYYY date | `reconciliation/2026-10-06/` |
| 27/10/26 | QAS (interface run, SAP_ABAP) vs PRD (manual), 25.10.2026 | 9 of 17 PRD rows correct; RUS_VAN gas still x1,000,000 small; VEN_CAR gross gas from the m3 column (0.192 for 6.77 MCF); RUS_VAN WATER_INJ, VEN_CAR GAS_FLARE/INT_CONS not sent; COMMENT garbage on SSU_SPO/VEN_CAR/RUS_SK1; RUS_SK1 LEBEDINSKI INT_CONS implausible. Causes in CPI mapping, not the class. | `reconciliation/2026-10-25/` |
