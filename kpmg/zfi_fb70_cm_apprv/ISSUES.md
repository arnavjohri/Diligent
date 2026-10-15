# ZFI_FB70_CM_APPRV — ISSUES

| Date | Issue | Root cause | Files | Commit | TR |
|---|---|---|---|---|---|
| 30/09/26 | Build started: object 1, workflow skeleton build sheet | new development | `docs/01_WORKFLOW_SKELETON_SWDD.md` | | |
| 05/10/26 | Trigger corrected: SAP raises FIPP.CREATED on park only with OBWA posting-release customising; added object 2, Z FM on BTE 00002218 raising the event | wrong assumption in design | `docs/00_DESIGN.md`, `docs/01_WORKFLOW_SKELETON_SWDD.md`, `NOTES.md` | | |
| 14/10/26 | Trigger proven by debugger: no post-park BAdI on the FB70 path (COBL exit, FAA delegation, PPA_CUST_BADI, AC_DOCUMENT, FI_LIMIT_PROCESS, FAGL_SET_SEGMENT, FMRE_BUS_PROCESS, BADI_PRKNG_NO_UPDATE all check-time); BTEs 00001011/00001140 (VIM subscribed) check-time; registered test FM on 00002218 fires. Object 2 split: BTE module (this commit) + RFC module IN BACKGROUND TASK reusing zcl_gl_workflow->start_workflow (standard verification scenario WS02800046) | design confirmed | `Z_FI_CM_APPR_PARK_EVENT.abap` | | |
| 14/10/26 | Object 2b: RFC module Z_FI_CM_APPR_START_WF (background task after park commit; VBKPF retry, start_workflow, COMMIT, instance check, errors to SM58) | new development | `Z_FI_CM_APPR_START_WF.abap` | | |
| 14/10/26 | Objects 2a and 2b activated in DEV; FIBF P/S entry 00002218 -> Z_FI_CM_APPR_PARK_EVENT under product ZFI. End-to-end FB70 test pending: no test data (customer, G/L, tax code, DG type) - requested from FI | awaiting functional | `NOTES.md` | | |
| 14/10/26 | Team decision: use the Z_JV_MASSGL_WF pattern - STARTING NEW TASK + WAIT UP TO 5 SECONDS - instead of IN BACKGROUND TASK. 2a call changed, 2b simplified (wait, single read, start, commit) | pattern alignment | `Z_FI_CM_APPR_PARK_EVENT.abap`, `Z_FI_CM_APPR_START_WF.abap` | | |
| 15/10/26 | Client mismatch found: FIBF entry made in client 200, FB70 tested in 400 (not modifiable) - 00002218 never dispatched in 400. Move via SCC1 or test in 200 | customising client | | | |
| 15/10/26 | Team decision: own class ZCL_CM_WORKFLOW (credit memo copy of ZCL_GL_WORKFLOW) fed from the BTE X tables; 2a passes T_XVBKPF/T_XVBSEG/T_XVBSEC to 2b, 2b calls the new class and commits/rolls back on EV_STATUS | design change | `ZCL_CM_WORKFLOW.abap`, `Z_FI_CM_APPR_START_WF.abap`, `Z_FI_CM_APPR_PARK_EVENT.abap` | | |
