# ZCL_INV_UTILITY — ISSUES

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 12/10/26 | AR / GL upload: local (or group) currency amounts do not balance, document currency does, no validation error. | In `validate_inv_data_ar` and `validate_inv_data_gl` the local / group checks sat inside `IF loc_curr IS NOT INITIAL AND gp_curr IS NOT INITIAL`. One code blank skipped every local / group check. The four totals were inline `DATA(...)` inside that branch and were never cleared, so a skipped document compared the previous document's totals. One combined IF with one message for all three currencies. | Both methods: totals declared explicitly and CLEARed per document; local and group validated in separate blocks, each only when its own code is filled; amount-without-code is now an error; balance check split into three IFs with currency-specific messages. PHP / USD hardcode kept as is. | — | Corrected, awaiting Arnav's test |

## Open

- Hardcoded PHP / USD (see NOTES). Decide whether to read T001 / ledger currencies.
- Rate check (document amount × TCURR rate vs supplied local amount) if the business
  wants wrong-but-balanced local amounts caught.
- `lv_no_curr` behaviour when only one of local / group is supplied (zero-amount type
  30 lines sent to the BAPI).
