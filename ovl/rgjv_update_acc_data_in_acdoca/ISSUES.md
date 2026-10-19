# ISSUES — RGJV_UPDATE_ACC_DATA_IN_ACDOCA (SAP standard, analysis only)

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 19/10/26 | Understand how the SAP JVA ACDOCA correction tool fetches data, and the JVSO1 ↔ ACDOCA relation, in support of `ovl/zfi_acdoca_vname_upd` | — | Analysis written up in NOTES.md; three SE80 prints filed in original/. No code change — standard object. | — |
| 19/10/26 | Test case, FI mode, one doc in S_BELNR: "The detected issues cannot be fixed through this program". Log: "JV and ACDOCA document have different number of lines (50 <> 13)", JV lines compressed in groups against ACDOCA line 0 [FI doc line 3], amounts never match, cost center blank on ACDOCA side | Structure mismatch, not a field value: JVSO1 splits the offset line (BSEG 003, 20,695,950.00) into ~37 lines per venture/EG/RI; ACDOCA has the offset as one line. line_missing in FI mode -> correction_not_possible (doc level, no line updated) | Not fixable by this tool. Next: SE16H ACDOCA vs JVSO1 for the doc (MIG_SOURCE, VNAME on expense lines, REFFIDLN=003 on JV offset lines); check posting date vs JVA-on-ACDOCA go-live; raise with GR/JVA functional | — |
