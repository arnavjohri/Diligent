# ISSUES — ZFITAX_PBT_CALC_PRG

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 29/10/26 | FAGLFLEXT read in `FORM PROCESS_DATA` returns fewer rows than SE16N for the same account / company code / year / ledger (25 on DB, 21 in `it_fl` for RACCT 200153, OVL, 2026, 0L). Period-6 credits of 18,018.00 INR / 187.81 USD lost from the account sum | `FOR ALL ENTRIES` applies an implicit DISTINCT over the columns of `ty_fl`. On the S/4 FAGLFLEXT compatibility view OBJNR00–08 are zero, rows differ only by DRCRK + RCNTR, and `ty_fl` has no RCNTR, so H rows with identical amounts collapse (DRLL/LG/MM, IT/MD, BD/MOZ) | `PATCH_FAGLFLEXT_FAE.abap`: RANGE on RACCT instead of FOR ALL ENTRIES, guarded with `IS NOT INITIAL`. Same statement exists in `ZFI_TAX_CREDIT_REPORT` `FORM PROCESS_DATA` and needs the same patch. Status: patch sheet delivered, not yet pasted / tested | <TR> |
