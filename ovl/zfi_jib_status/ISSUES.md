# ZFI_JIB_STATUS — issues and activation log

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 03/11/26 | New data source for the Management Dashboard card "JIB Status": per joint venture, is the period's JIB posted and when was it entered. Consumer: Fiori app via Custom Analytical Queries (CAQ) built by the GR consultant | No venture on BKPF; the only stamped JIB marker is document type JM (GS01 set `ZJVNONOPJIB_DOCTYP_MON`, confirmed in GS03 and by SE16N BKPF OVL/JM 2016–2018 — every row a JIB) | Four classic CDS views in one abapGit ZIP `ZFI_JIB_STATUS.zip` (package `ZFI_JIB_STATUS`, DEVC + 4 DDLS, no DDIC): `ZI_JIB_DOC_AGG`, `ZI_JIB_PERIOD`, `ZI_JIB_VENTURE`, `ZI_JIB_STATUS_CUBE`. Arnav asked for the ZIP with everything in it (03/11/26) after the treasury import left its table uncreated — hence no table here. C1 release of the cube is manual | `<TR>` | **Open** — awaiting import |
