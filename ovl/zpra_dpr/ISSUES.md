# ISSUES — ovl/zpra_dpr

## ZCL_ZPRA_DAILY_PROD_DPC_EXT (CPI inbound OData, ZPRA_T_DLY_PRD)

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 06/10/26 | Measures sent as 0 still create rows in ZPRA_T_DLY_PRD | BUILD_PROD_ROWS skipped only the literal text '0'; CPI sends 0.000 / 0.00 | Skip on blank text, then skip when the converted PROD_VL_QTY1 = 0 (BUILD_PROD_ROWS only) | open |

Baseline for diffing: `original/ZCL_ZPRA_DAILY_PROD_DPC_EXT.abap` = repo copy of 14/08/26,
not a fresh SE24 download. ASSUMPTION: the active class matches it.
