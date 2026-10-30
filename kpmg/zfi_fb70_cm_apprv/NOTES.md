# ZFI_FB70_CM_APPRV — NOTES

## What it is

Custom SAP Business Workflow on object `FIPP`: a customer credit memo parked in FB70 goes
through 1, 2 or 3 sequential approvers depending on amount, each approver gets a mail with a
PDF of the document including computed tax, and the document is posted automatically after the
last approval. Design and object list: `docs/00_DESIGN.md`. Build sheets: `docs/01_...` onwards,
one per object, in build order.

Client folder is a placeholder until Arnav names the project. Move with `git mv`, nothing
inside depends on the path.

## How it ships

Paste-only. Workflow definition, tasks, start condition, agent assignment and the form are
click-work in SWDD / PFTC / SWB_COND / SFP and are documented as build sheets. The class is
pasted into SE24. Tables are built by hand in SE11 from the build sheet.

Nothing here is SE80-downloaded original code; there is no `original/` folder.

## Email notifications (30/10/26)

FS matrix mapped in `docs/03_EMAIL_MATRIX.md`. Sending is `ZCL_CM_WORKFLOW=>SEND_MAIL`
(`docs/04_SEND_MAIL_SE24.md`), dedup table `ZCM_WF_MAIL_LOG`, RFC FM `Z_CM_WF_MAIL_SEND` next,
then the three call-point patches. All code, no SWNCONFIG.

## Where it stands (23/10/26)

Working end to end in DEV client 400 on the GL verification scenario: park -> approve -> post,
and reject -> correct in the Verify app -> resubmit -> approver. Objects, reasons, withdrawn
attempts and open points: `docs/02_SOLUTION_SUMMARY.md`. The sections below are history.

## Where it stood (14/10/26)

- `Z_FI_CM_APPR_PARK_EVENT` and `Z_FI_CM_APPR_START_WF` active in DEV, FG `ZFI_CM_APPR`.
- FIBF: P/S entry `00002218` -> `Z_FI_CM_APPR_PARK_EVENT`, product `ZFI` (existing, active).
  No separate `ZFICMAPR` product was created. **Entry is in client 200 only.** Client 400 is
  not modifiable; move the customising request with `SCC1` or test in 200. FIBF, the workflow
  configuration (Fiori app) and the test must all be in the same client.
- Not yet tested end to end: FI to supply a DEV customer, G/L account, tax code and confirm
  document type `DG`. Test checklist: park in FB70 -> `SM58` empty for the user ->
  `VBKPF-XWFFR` = X -> document in approver inbox. Negative test with type `DR`: nothing.
- **Answered 16/10/26: the GL verification scenario does NOT accept a customer credit memo.**
  Its views filter on `BKPF-TCODE` in (`FBDC_P001`, `FBDC_P050`, `FBDC_P051`); with those
  rewritten for the test the approval step ran, but the scenario's own posting step refused
  the document with `FDC_POSTING_001 092` "Parked document is no GL posting". Routes left:
  an Accounts Receivable verification scenario if this release has one (same trigger,
  different event), or the custom `FIPP` workflow in `docs/00_DESIGN.md` (same trigger,
  class raises `FIPP.CREATED`, posting via `FIPP.POST`).
- Debugging lesson: with a breakpoint in the BTE the FB70 dialog never commits, so the
  asynchronous task finds no VBKPF row after its 5-second wait. Debug the task only, with an
  external breakpoint in `Z_FI_CM_APPR_START_WF`, never the dialog.
- `ZCL_AGENT_GL_WF_RULE` carried a `DO. ENDDO.` at the top during the test (debug hook).
  Must not stay: it hangs a work process on every verification work item in the client.

## Gotchas

- FB70 *Hold* is not *Park*. Held documents raise no `FIPP` event.
- A workflow started by event must be a General task (PFTC) or it never starts for other users.
- Agent changes are buffered: run `SWU_OBUF` after every PFTC change.
- Without a start condition the linkage fires for every parked FI document in the client.
- Object names are chosen by Claude with a Z prefix; Arnav creates them in the system.
- `FIPP.CREATED` is NOT raised by SAP on park unless OBWA posting-release customising exists.
  Proven 14/10/26 by debugger trace: no customer BAdI runs after the park save; BTE
  `00002218` is the only post-save hook and a registered Z module on it fires.
- Object 2 is two modules, both paste-only in FG `ZFI_CM_APPR`:
  `Z_FI_CM_APPR_PARK_EVENT` (BTE, inside the park LUW, no commit) calls
  `Z_FI_CM_APPR_START_WF` STARTING NEW TASK with the X tables, which waits 5 seconds and
  calls `ZCL_CM_WORKFLOW->START_WORKFLOW` (credit memo copy of `ZCL_GL_WORKFLOW`, fed from
  the X tables; standard journal entry verification, `WS02800046`). Class is paste-only too.
  Whether that standard scenario accepts an FB70 customer credit memo is still to be tested.
- Team pattern (decided 14/10/26): the BTE calls the RFC module STARTING NEW TASK and the RFC
  module starts with WAIT UP TO 5 SECONDS, same as Z_JV_MASSGL_WF in the mass GL program.
