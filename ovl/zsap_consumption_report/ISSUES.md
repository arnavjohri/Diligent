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

## 06/10/26 — CR: MICROSOFT columns (Option A, same rate, extra columns in ZCON1)
- New field `ZSERVICE_ELEMENT-MICROSOFT_SCOPE_DAYS` (SE11, manual) + TMG regeneration.
- Report: 7 columns MICROSOFT Scope / Consumed / Consumed till date / Available days, and
  Consumed / Consumed till date / Available amount, same DAILY_RATE_GST, same Head IT rule.
- **Open:** Total days / Total Value in ZSERVICE_ELEMENT — whether MICROSOFT should be added
  to them depends on how they are filled (TMG event?).
