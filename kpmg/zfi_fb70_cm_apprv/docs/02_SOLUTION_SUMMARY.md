# FB70 credit memo (DG) approval on the GL verification scenario — what was built and why

Status 23/10/26: working end to end in DEV, client 400, on test documents. Park in FB70, the
approver gets it, approve posts it, reject sends it back, the requester corrects it in the
Verify app and resubmits, and it goes back to the approver. Not yet transported. Gaurav's
sign-off on the standard-code enhancements is still outstanding.

## The flow as it runs now

1. **Park** a DG credit memo in FB70. BTE 00002218 calls `Z_FI_CM_APPR_PARK_EVENT`.
2. The BTE module hands over to `Z_FI_CM_APPR_START_WF` **in background task**, which runs
   after the park's own update has committed.
3. `ZCL_CM_WORKFLOW->START_WORKFLOW` flags the parked document for release, writes the Fiori
   G/L app transaction code on VBKPF and BKPF, and raises `CL_FDC_ACCDOC_VER` `SUBMITTED`.
   SAP's flexible workflow `WS02800046` (Verify General Journal Entries) starts. The rule
   `YY1_GL_WF_LVL1` finds the approver.
4. **Approve.** The posting step calls `CL_FDC_ACCDOC_VER->IF_FDC_ACCDOC_VER~POST`.
   `ZEI_FI_CM_APPR_POST` posts the DG document the classic way, as FBV0 does.
5. **Reject.** The workflow sends a Redo decision (`TS00008267`) to the initiator. The
   initiator opens the document in Verify General Journal Entries. `ZEI_FI_CM_APPR_READ` lets
   it open.
6. **Resubmit.** The app re-parks the document. `ZEI_FI_CM_APPR_REDO` completes the Redo
   decision with "resubmit", and the same workflow goes back to the approver (step 4).

## Objects and why each one exists

| # | Object | Where | Why |
|---|---|---|---|
| 1 | FIBF P/S entry `00002218` -> `Z_FI_CM_APPR_PARK_EVENT`, product `ZFI` | Customising, per client | FB70 has no BAdI after the park is saved (proved in the debugger). BTE 00002218 "document is saved" is the only reliable hook. The entry must be in the client where FB70 runs; country and application stay blank. |
| 2 | `Z_FI_CM_APPR_PARK_EVENT` | FM, FG `ZFI_CM_APPR` | Filters to the first park of a DG parked document and passes all six BTE tables on. Uses `IN BACKGROUND TASK`: `STARTING NEW TASK` raced the park's update and found no VBKPF row. |
| 3 | `Z_FI_CM_APPR_START_WF` | RFC FM, same FG | Background LUW: calls the class and commits. |
| 4 | `ZCL_CM_WORKFLOW->START_WORKFLOW` | Class | The team's `ZCL_GL_WORKFLOW` logic minus `PRELIMINARY_POSTING_DOC_READ` (data comes from the BTE tables). The transaction-code rewrite is needed because the scenario view `C_GLJRNLENTRYTOBEVERIFIED` only lists documents carrying the app's code on BKPF. Without it the agent rule got no data and the Verify list did not show the document. |
| 5 | `ZEI_FI_CM_APPR_POST` | Implicit enhancement, start of `CL_FDC_ACCDOC_VER->IF_FDC_ACCDOC_VER~POST` | The standard posting step converts the parked document into the Fiori G/L posting model. That model accepts G/L and supplier lines only, so DG failed with `FDC_POSTING_001 092`. For a DG document in the scenario, the enhancement posts with `PRELIMINARY_POSTING_POST_ALL` and sets the workflow status. |
| 6 | `ZEI_FI_CM_APPR_READ` | Implicit enhancement, end of `CL_FDC_ACCDOC_PARK_ACCESS=>READ` | Opening the document in the Verify app ran two more copies of the same account-type check (header read and read-for-change), both raising 092. Both take the account types from `READ`. For an app-code DG document opened for change, the customer type is taken out of that value. The items are not touched. |
| 7 | `ZEI_FI_CM_APPR_REDO` | Implicit enhancement, end of `CL_FDC_ACCDOC_POST->ACCDOC_POST` | On resubmit the app re-parks DG successfully but never completes the Redo decision, so the workflow stayed with the initiator. After a successful re-park of a DG submitted complete, this completes the open Redo item with `SAP_WAPI_DECISION_COMPLETE` `0001` in the same LUW. It never touches any other step. |
| 8 | Credit memo branch in the team's `ZEI_GL_WORKLFOW_INTR` | End of `CL_FDC_ACCDOC_VER_SERVICES->IS_DOC_VALID_FOR_NEW_WORKFLOW` | Added while looking for the resubmit gap. It clears 092 for app-code G/L + customer documents. **Not proven to be on any path we use**: breakpoints there never stopped. See open point 1. |

All four enhancements on standard classes are implicit enhancements, not modifications. Each
one is guarded to DG plus the app's transaction code, and each is switched off in SE19 by
deactivating its implementation.

## Tried and withdrawn

| What | Why it was dropped |
|---|---|
| Asynchronous call with `WAIT UP TO 5 SECONDS` | Raced the park update; replaced by background task. |
| Enhancing `IS_DOC_VALID_FOR_NEW_WORKFLOW` to fix posting | Not on the posting path; the 092 came from the Fiori G/L conversion. |
| LOG-POINT / `DO. ENDDO.` test hooks | Diagnostic only, removed. |
| FBV2 as the correction route (BTE restart, VBKPF code kept) | The team decided on the Verify app only. With the app, a restart from the BTE would have started a second workflow. |

## Lessons recorded

- `MEMORY.md` M-28: a where-used list (SE91, SE24) is a lead, not proof. The where-used index
  for SAP standard code on this system is incomplete, and the source scan also missed lines.
  Prove the path with a breakpoint on the real user before enhancing.
- `ABAP CO` respects trailing blanks: `CO_ALLOWED_ACCT_TY_FOR_PARKING` is `KOARS_003` `'SK '`.
- In the GL scenario a rejection does not end the workflow. It waits in a Redo decision, and a
  resubmit continues the same instance.

## Open points

0. **26/10/26 - correcting a DG in the Verify app does not work.** Edits are not applied, and
   changing a line item makes the line disappear. The app's G/L posting model has no customer
   line. Recommended: corrections in FBV2; resubmit from the FBV2 save through our BTE with SAP's
   own `IF_FDC_ACCDOC_VER~REDO` (this also closes point 2); and a guard that refuses to save a DG
   from the Verify app once its customer line is gone. Needs the team's decision, because it
   reverses "Verify app only".

1. **Our branch in `ZEI_GL_WORKLFOW_INTR`.** Test the full flow once with only the team's
   original branch. If everything still works, leave it out (smaller footprint, no unproven
   code in a shared enhancement).
2. **Workflow amounts on resubmit - control gap with amount-based levels.** `ZEI_FI_CM_APPR_REDO`
   does not refresh the amounts in the workflow (the standard REDO does, via
   `cl_fdc_accdoc_ver_services=>modify_workflow_input`). With 2/3/4 approval levels chosen by
   amount, a requester who raises the amount while correcting gets the levels of the old amount,
   so a higher approver can be skipped. Recommended before go-live: refresh the amounts in
   `ZEI_FI_CM_APPR_REDO` before completing the Redo item.
2a. **Multi-level resubmit untested.** Logs show the resubmit continues the same workflow with a
   new Verify step; with one level only. Test: reject at level 2, resubmit, check in the log that
   approval restarts at level 1 and runs all levels again; then a second rejection and resubmit.
3. **Document integrity after an edit in the app.** After a correction and resubmit, check in
   FBV3 that the customer, amounts and tax are unchanged except for what was edited. Then
   approve and check the posted document.
4. **Regression for SA / JV.** Upload, approve, reject and resubmit one SA document with all
   enhancements active.
5. **Withdraw** (abort, decision `0002`) for a DG document is untested.
6. **Hardcoded `DG`** in four places (BTE, POST, READ, REDO): move to one constant or a config
   entry before go-live.
7. **System clean-up:** `DO. ENDDO.` removed from `ZCL_AGENT_GL_WF_RULE`;
   `ZCL_GL_EXCHANGE_AMOUNT_DET` loops reported to the owner; SM13 and SAAB clear.
8. **Agent determination:** the approver rule needs HR data (PA0105 and the org chain) for
   every requester.
9. **Transport:** list every object and the FIBF entry for the target clients. Gaurav's
   sign-off on items 5–8 of the object table.
