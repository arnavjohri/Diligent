# ZMM_PO_VALIDITY_FS — ISSUES

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 12/10/26 | Validity Start / End to be input-ready only for PO type SBP (Udayan, for Fiori + GUI demo) | Fields controlled by field selection key; SBP moved ZBRD→NBF for Fiori, so GUI needs per-doc-type hide | `FIELDSELECTION_HEADER`: `'-'` for KDATB/KDATE unless BSART in TVARVC `ZPO_VALIDITY_DOCTYPE` | — | Delivered, awaiting Arnav's verification |
