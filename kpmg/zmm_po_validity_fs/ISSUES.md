# ZMM_PO_VALIDITY_FS — ISSUES

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 12/10/26 | Validity Start / End to be input-ready for PO type SBP in GUI (Udayan, Fiori + GUI demo) | Standard fields EKKO-KDATB/KDATE hidden by field selection. T161 confirms SBP on NBF, so a stricter key (ME21N / AKTH / release) hides the Validity period group | **Customizing (OMF4)**, not code. BAdI attempt withdrawn: `FIELDSELECTION_HEADER` receives only customer metafields (90000121…), never 37/38 — confirmed in debugger | — | Open on functional side |
