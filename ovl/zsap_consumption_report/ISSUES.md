# ZSAP_CONSUMPTION_REPORT — issue log

## 06/10/26 — CR: Consumed till date + Available based on it
- **Ask:** Available only deducted the selected period's consumption. Add a column with
  everything consumed till date, and base Available on that.
- **Fix:** second SUM (`GT_SUM_TILL`, `datec <= p_datet`, Head IT approved) → new columns
  AS IS / Additional Consumed till date (days + amount). Available days (and hence Available
  amount) = Scope − Consumed till date. Period columns unchanged.
- **Defaults applied (not confirmed by Arnav):** till date = up to the To Date; counted from the
  first entry; days and amount.
- **Open:** Scope MICROSOFT not counted anywhere (only AS IS / ADDITIONAL read).
- **Status:** awaiting activation / test. TR: —
