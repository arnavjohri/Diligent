# ISSUES — GR data release, Venture field

## 2026-09-28 — Venture blank in ACDOCU after data release
- **Issue:** ACDOCU custom Venture field is blank after data release.
- **Cause (SAP incident reply):** no field mapping in the data release task.
  `ZZ1_VNAME_COB` not selectable in the mapping value help because it is not
  exposed by `I_CnsldtnIntegRptdFinData`; key-user TAI usage not offered.
- **Fix:** extend view `ZX_CNSLDTNINTEGRPTDFINVNAME` exposing
  `_Extension.ZZ1_VNAME_COB as ZZ_VNAME_COB`; then functional mapping + re-release.
- **TR:** —
- **Status:** drafted, awaiting activation.
