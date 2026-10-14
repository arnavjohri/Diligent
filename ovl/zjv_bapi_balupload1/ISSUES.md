# ZJV_BAPI_BALUPLOAD1 — issues

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 14/10/26 | XREF1 from the upload file not updating BSEG-XREF1 (works in ZJV_BAPI_BALUPLOAD1_MON, not here) | `IST_GL` declared XREF1 as field 28, directly after LINENO. The upload template has 33 columns (SPGL, ZTERM, FUN_AREA, TRAD_PART, TRANS_TYPE between LINENO and XREF1). `GUI_UPLOAD` DAT fills by position, so XREF1 got file column 28 (SPGL, blank) and column 33 was dropped. `SCREEN_300` already maps `LS_GL-REF_KEY_1 = IST_GL-XREF1`. | Added the five placeholder columns to `IST_GL` between LINENO and XREF1, same as the MON program. BOC/EOC Arnav 14/10/26, declaration only. | — | Corrected, awaiting Arnav's verification |

Not touched, deliberately:
- `IST_GL1` (reject list) — no XREF1 there, filled by MOVE-CORRESPONDING, so it needs no change.
- `SCREEN_302` (vendor, PK 21/31) and `SCREEN_305` (asset, PK 70/75) do not pass XREF1 in either program. If XREF1 is wanted on vendor/asset lines too, that is a separate change (`LS_VEND-REF_KEY_1` / `LS_GL-REF_KEY_1`).
- `MODIFY_IST_GL` still has the multi-DELETE-in-one-loop row-loss defect that the MON program already fixed. Out of scope for this issue; raise separately if wanted.
