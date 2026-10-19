# ISSUES — ZFI_FBL3N_ACDOCA_U

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 19/10/26 | Journal entries with document status `U` (ACDOCA only, no BSEG) are not displayed in FBL3N | FBL3N reads BSIS/BSAS, which only carry lines with a BSEG item | BAdI `FI_ITEMS_CH_DATA` → `CHANGE_ITEMS`: select ACDOCA `BSTAT = 'U'` for the FBL3N account / company code / posting-date selection (leading ledger), map to `RFPOSXEXT`, append to `CT_ITEMS`. FBL3N only (`sy-tcode`). Status: delivered for activation, not yet tested | <TR> |
