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

## 16/10/26 — MICROSOFT consumed out of AS IS scope (supersedes the 06/10 MICROSOFT columns)
- No MICROSOFT scope of its own: **AS IS Available = AS IS scope − AS IS till date − MICROSOFT
  till date**. MICROSOFT Scope / Available columns removed (commented).
- MICROSOFT Consumed days / till date / amounts kept, placed next to the matching AS IS column.
- `ZSERVICE_ELEMENT-MICROSOFT_SCOPE_DAYS` no longer referenced — the SE11 field is not needed.

## 16/10/26 — column order: Additional before MICROSOFT
- Ask: in each group show AS IS → Additional → MICROSOFT.
- Fix: BUILD_FIELDCAT only — MS_CONSUMED_DAYS, MS_CONS_TILL, MS_CONSUMED_AMT, MS_CONS_TILL_AMT moved
  below their ADD_* line. No logic change. TR: pending (PRD move with consumption-report changes).
