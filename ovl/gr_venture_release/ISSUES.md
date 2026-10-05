# ISSUES — GR data release, Venture field

## 2026-09-28 — Venture blank in ACDOCU after data release
- **Issue:** ACDOCU custom Venture field is blank after data release.
- **Cause (SAP incident reply):** no field mapping in the data release task.
  `ZZ1_VNAME_COB` not selectable in the mapping value help because it is not
  exposed by `I_CnsldtnIntegRptdFinData`; key-user TAI usage not offered.
- **Fix:** extend view `ZX_CNSLDTNINTEGRPTDFINVNAME` exposing
  `_Extension.ZZ1_VNAME_COB as ZZ_VNAME_COB`; then functional mapping + re-release.
- **Addendum 28/09/26:** standard ACDOCA-VNAME wanted too. `ZX_JOURNALENTRYITEMVNAME`
  (extends `E_JournalEntryItem`, `Persistence.vname as ZZ_VNAME`) — activated.
  `ZX_CNSLDTNINTEGRPTDFINVNAME` now also carries `_Extension.ZZ_VNAME`.
- **SAP review 05/10/26:** GR view extension "correct"; E_JournalEntryItem extension
  flagged because guide P110 writes `acdoca.xxx as zz_xxx`. Not changed: on this
  system `E_JournalEntryItem` is `select from acdoca as Persistence`, and once a CDS
  data source has an alias only the alias may be used — `acdoca.vname` would not
  activate. SAP's own generated append on the same view uses `Persistence.ZZ1_VNAME_COB`.
  Guide example predates the alias. Pushed back to SAP with this.
- **TR:** —
- **Status:** E_JournalEntryItem extension activated; GR view extension awaiting activation.
