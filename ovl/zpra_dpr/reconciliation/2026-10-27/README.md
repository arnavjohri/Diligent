# DPR reconciliation — production date 27.10.2026 — QAS (interface) vs PRD (manual)

PRD: manual entries 28.10.2026 (users 121903, 121720, 122337, 95660, 94521, 96029, 105013, 92051, 60749).
QAS: one CPI run 28.10.2026 17:34:02 (SAP_ABAP); COL_CPO came from an earlier run 07:39:02.
Raw extracts were pasted in chat only (not filed as TSV). Same method as `../2026-10-25/`.

## Correct in QAS
MMR_BA1, MMR_BA3 gas; RUS_IEC oil (4 blocks) and DVOINOYE / SNEZHNOYE gas; RUS_SK1 oil (all 4 blocks);
RUS_VAN NET_PROD and GROSS_PROD (10,751,000 M3 - the x1,000,000 gap from 06.10/25.10 is gone);
SSU_SPO NET_PROD; VEN_SAN GROSS_PROD. (Only rounding differences, e.g. 153,144.96 vs 153,145.)

## Wrong in QAS
| Item | QAS | PRD | Cause |
|---|---|---|---|
| RUS_SK1 gas, all 13 rows (flare, inj, gross, int_cons) | e.g. ARKUTUN gross 105,022 | 2,973,886.970 | PRD/QAS = 28.3168 on every row = 1/0.0353147. QAS holds MCF but class labels it M3. CPI must send m3 (x28.3168). |
| RUS_SK1 LEBEDINSKI INT_CONS | 524,498 | 14,838.003 | QAS = PRD x 35.3147: a further x1,000 off (cubic feet, not MCF) |
| BRA_BC1 | block BRA_BC1; gas 533,366 "MCM" | ARGONAUTA 34,333 BBL, gas 0.533 MCM | block does not exist in PRD; gas in m3 labelled MCM (x1,000,000); oil total matches |
| RUS_IEC gas MAISKOYE | block RUS_IEC_MAISKOYE 9,500 | block RUS_IEC_MAISKOYEGRP 9,500 | value OK, block wrong |
| COL_CPO MARIPOSA NET | 533.890 | 532.810 | differs (QAS run 07:39, PRD keyed 10:50 - likely corrected later) |
| COL_CPO MARIPOSA gas | 55,280 | 1,373.366 | does not reconcile (ratio 40.25) |
| COL_CPO PERICO NET | 424.780 | 408.660 | as MARIPOSA |
| COL_CPO Milano | block "Milano" 488.380 | CALAO 436.760 | block does not exist in PRD; value differs |

## Missing in QAS (non-zero in PRD)
UAE_LZC NET 444,594; RUS_VAN WATER_INJ 285,338 M3; VEN_SAN NET 5,585 and GAS_FLARE 2.77 MCF.
Zero rows (BRA_BC1, COL_CPO others, RUS_IEC zeros, SK1 zero water/inj, VAN GAS_INJ, VEN_SAN zeros)
are not posted by design (06/10/26 fix).

## COMMENT
QAS comments are wrong or empty: SSU_SPO "12.5" (PRD: CPP power black-out text); VEN_SAN a header dump;
RUS_SK1 "к добыче:"; operator remarks on MMR_BA3, RUS_IEC, COL_CPO block-level are not carried
(COL_CPO QAS has its own well-status text instead).

Causes are in the source file (values, units, blocks, comments), not in ZCL_ZPRA_DAILY_PROD_DPC_EXT; the interface passes values as received.
