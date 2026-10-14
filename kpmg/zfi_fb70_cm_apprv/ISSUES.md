# ZFI_FB70_CM_APPRV — ISSUES

| Date | Issue | Root cause | Files | Commit | TR |
|---|---|---|---|---|---|
| 30/09/26 | Build started: object 1, workflow skeleton build sheet | new development | `docs/01_WORKFLOW_SKELETON_SWDD.md` | | |
| 05/10/26 | Trigger corrected: SAP raises FIPP.CREATED on park only with OBWA posting-release customising; added object 2, Z FM on BTE 00002218 raising the event | wrong assumption in design | `docs/00_DESIGN.md`, `docs/01_WORKFLOW_SKELETON_SWDD.md`, `NOTES.md` | | |
| 14/10/26 | Trigger proven by debugger: no post-park BAdI on the FB70 path (COBL exit, FAA delegation, PPA_CUST_BADI, AC_DOCUMENT, FI_LIMIT_PROCESS, FAGL_SET_SEGMENT, FMRE_BUS_PROCESS, BADI_PRKNG_NO_UPDATE all check-time); BTEs 00001011/00001140 (VIM subscribed) check-time; registered test FM on 00002218 fires. Object 2 split: BTE module (this commit) + RFC module IN BACKGROUND TASK reusing zcl_gl_workflow->start_workflow (standard verification scenario WS02800046) | design confirmed | `Z_FI_CM_APPR_PARK_EVENT.abap` | | |
| 14/10/26 | Object 2b: RFC module Z_FI_CM_APPR_START_WF (background task after park commit; VBKPF retry, start_workflow, COMMIT, instance check, errors to SM58) | new development | `Z_FI_CM_APPR_START_WF.abap` | | |
