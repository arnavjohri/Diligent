# ovl/zmm_arms — issue log

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 05/10/26 | Inventory of hardcoded values requested | Company-code → purchasing-group map, role codes, FRGCO levels, status codes, HR conventions and tcodes are all hardcoded | Analysis only, no code changed. See `HARDCODES.md` | — |
| 26/10/26 | Uday (SAP Basis/BPC): rename 4 hardcoded PFCG roles in ZOVL_ARMS; move 14 role tables to QA; customer test from 27/10 | ZOVL_ARMS = SAPMZMMPREPROLE1_PHASEII. Literals in I01 `validate_header_data` (user gate), F01 `GRC_RISK_ANALYSIS`, `ROLE_HELP`, `INSERT_DATA`, `INSERT_DATA_ADDL`; same in ZIC_AUTH (PROLE3) and FI includes. PM_PS_LIS_CIN maps to two roles — not a literal swap | Analysis only, no code changed. Patch map + open questions for Uday in `ROLE_RENAME.md` | — |
