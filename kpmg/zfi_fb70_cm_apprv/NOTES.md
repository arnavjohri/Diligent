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

## Gotchas

- FB70 *Hold* is not *Park*. Held documents raise no `FIPP` event.
- A workflow started by event must be a General task (PFTC) or it never starts for other users.
- Agent changes are buffered: run `SWU_OBUF` after every PFTC change.
- Without a start condition the linkage fires for every parked FI document in the client.
- Object names are chosen by Claude with a Z prefix; Arnav creates them in the system.
