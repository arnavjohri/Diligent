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

## Where it stands (14/10/26)

- `Z_FI_CM_APPR_PARK_EVENT` and `Z_FI_CM_APPR_START_WF` active in DEV, FG `ZFI_CM_APPR`.
- FIBF: P/S entry `00002218` -> `Z_FI_CM_APPR_PARK_EVENT`, product `ZFI` (existing, active).
  No separate `ZFICMAPR` product was created. **Entry is in client 200 only.** Client 400 is
  not modifiable; move the customising request with `SCC1` or test in 200. FIBF, the workflow
  configuration (Fiori app) and the test must all be in the same client.
- Not yet tested end to end: FI to supply a DEV customer, G/L account, tax code and confirm
  document type `DG`. Test checklist: park in FB70 -> `SM58` empty for the user ->
  `VBKPF-XWFFR` = X -> document in approver inbox. Negative test with type `DR`: nothing.
- Open decision after the test: does the standard verification scenario accept a customer
  credit memo? If yes, objects 4-7 of `docs/00_DESIGN.md` are not needed.

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
