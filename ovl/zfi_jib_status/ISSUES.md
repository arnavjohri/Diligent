# ZFI_JIB_STATUS — issues and activation log

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 03/11/26 | New data source for the Management Dashboard card "JIB Status": per joint venture, is the period's JIB posted and when was it entered. Consumer: Fiori app via Custom Analytical Queries (CAQ) built by the GR consultant | No venture on BKPF; the only stamped JIB marker is document type JM (GS01 set `ZJVNONOPJIB_DOCTYP_MON`, confirmed in GS03 and by SE16N BKPF OVL/JM 2016–2018 — every row a JIB) | Three classic CDS views, one at a time: `ZI_JIB_DOC_AGG` (delivered 03/11/26, awaiting activation), `ZI_JIB_PERIOD`, `ZI_JIB_STATUS_CUBE` (C1 release for CAQ) | `<TR>` | **Open** — object 1 awaiting activation |
