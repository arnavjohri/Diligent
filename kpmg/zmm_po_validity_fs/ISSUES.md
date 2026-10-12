# ZMM_PO_VALIDITY_FS — ISSUES

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 12/10/26 | Validity Start / End to be input-ready for PO type SBP in GUI (Udayan, Fiori + GUI demo) | Standard fields EKKO-KDATB/KDATE. OMF4 key **NBF**, group "Administrative data, header": "Start of validity period" / "Validity period end" have no option ticked = Hide. ME21N and AKTH already Opt. entry. T161: SBP → NBF | **Customizing only**: tick Opt. entry for both fields in NBF (functional, customizing TR). No ABAP. BAdI `FIELDSELECTION_HEADER` withdrawn — it receives only customer metafields, never 37/38 (debugger) | — | Mail drafted to Udayan; awaiting customizing change |
