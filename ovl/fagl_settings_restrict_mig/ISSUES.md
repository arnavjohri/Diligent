# ISSUES — FAGL_SETTINGS *_RESTRICT_MIG (KBA 2891129, OVL)

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 19/10/26 | Functional forwarded KBA 2891129: FAGLL03 / FAGLB03 / RFBILA00 / RFBELJ show incorrect migrated data; review notes and FAGL_SETTINGS steps. They want FAGLL03 first. | FIN migration correction lines (`MIG_SOURCE` A/C/R) selected by the standard reports | Reviewed; work split: notes via SNOTE (ABAP/Basis), SM30 entries + testing (functional). Caveats on reversals, Fiori/Z reports and MIG_SOURCE J recorded in NOTES.md. Mail text truncated — remainder awaited. | — |
| 23/10/26 | SNOTE 2697319 (FAGLL03): "Cannot be implemented", processing status "Not Relevant". Valid S4CORE 100–103 only. | Correction already contained in OCQ's release (≥ 104) | Nothing to implement. Confirm via System → Status or SE38 FAGL_ACCOUNT_ITEMS_GL find `RESTRICT_MIG`. | — |
| 23/10/26 | `FAGLL03_RESTRICT_MIG` = X maintained in FAGL_SETTINGS, DEV client 500 (Arnav: "done"). | — | Entry in. Pending: release line, whether SM30 asked for a TR, FAGLL03 before/after totals on the two test accounts, MIG_SOURCE × ledger distribution. | pending |
