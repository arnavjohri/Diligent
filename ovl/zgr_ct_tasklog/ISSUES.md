# ISSUES — ZGR_CT_TASKLOG

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 06/11/26 | Which CDS view / table does the task log opened from CXCD (currency translation) read? ST05 export `Trace.trc` supplied (OCD 500, SAP_FI, 12:03:43–59) | The `.trc` is an ST05 binary export: an ABAP data cluster, LZH (DEFLATE-style) compressed twice. Decoded: the log is served by OData `FIN_CONS_GENERICLOG_SRV`; lines come from CDS view `C_CNSLDTNCRCYTRNSLTNTSKLG` keyed by the task log UUID = `FINCS_LOG_HEADER-CNSLDTNLOGNUMBER`; header list from CDS `FINCS_LOG_HEADER_OLD` (SQL view `FINCSLOGHDR`); detail from `FINCS_LOG_HEADER` / `_ITEM` / `_MESSAG`. ACDOCU not read | Findings in `NOTES.md`, decoded extract in `trace/`. New report `ZGR_CT_TASKLOG.abap` (302 lines, paste-only) reads header → view → SALV. Awaiting syntax check on OCD | — |
