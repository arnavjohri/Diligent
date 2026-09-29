# ZINV GL upload — ISSUES

| Date | Issue | Cause | Fix | TR | Status |
|---|---|---|---|---|---|
| 29/09/26 | Group (and local) amounts differ from the Excel after a request is rejected, edited (PDF attached) and approved | Edit of the parked doc re-derives amounts from TCURR; `UPDATE_AMOUNT` should restore them but never matches a line (G/L without leading zeros), picks the first line for a repeated G/L, needs a local amount before setting group, and filters on ENDUSER. Behaviour pool also stores the local amount as the group amount | `UPDATE_AMOUNT`: ALPHA on G/L, pair by G/L + doc amount with used-line tracking, all-or-nothing, local/group set independently, ENDUSER dropped, guard against the mis-stored group amount. Behaviour pool `ZINV_CL_BP_GL_USER` mapping fix: patch sheet delivered | — | Both objects delivered for test |
