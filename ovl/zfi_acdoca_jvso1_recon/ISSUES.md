# ISSUES — ZFI_ACDOCA_JVSO1_RECON

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 19/10/26 | New report: reconcile ACDOCA ledger 0L (lines created before 27.09.2026) with JVSO1 ledger 4A (RRCTY 0, RVERS 001) for company code / year / period, totals by venture, equity group, account, recovery indicator, year, period, difference in HSL / KSL / WSL | — | `ZFI_ACDOCA_JVSO1_RECON.abap` built (384 lines, CL_SALV_TABLE). Open questions in `ASSUMPTIONS_AND_QUERIES.md`; TS in `TS_ZFI_ACDOCA_JVSO1_RECON.md`. Awaiting activation + answers | <TR> |
| 21/10/26 | Arnav: drop the transaction-currency comparison — a grouping key can hold rows in several transaction currencies, so the WSL/TSL total means nothing | Requirement change | WSL/TSL removed end to end: ACDOCA `SUM( wsl )`, JVSO1 `tsl`, the three TC output columns, the TSL assumption. Only HSL and KSL compared. 384 → 367 lines. Queries 2 and 6 closed | <TR> |
