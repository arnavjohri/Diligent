# ZMM_PO_NOROUND — NOTES

## What it is

Two files, one fix. Ship **one** of them, never both.

| File | BAdI | Method | Role |
|---|---|---|---|
| `ZCL_IM_MM_BAPI_PO_NOROUND.abap` | `ME_BAPI_PO_CUST` | `INBOUND` | **Primary.** Sets `NO_ROUNDING` in the BAPI item tables `POITEM` / `POITEMX`, exactly where SAP said to. Runs only for BAPI calls, so ME21N is out of reach by construction |
| `ZCL_IM_MM_PO_NOROUND.abap` | `ME_PROCESS_PO_CUST` | `PROCESS_ITEM` | **Fallback.** Sets `MEPOITEM-NO_ROUNDING`, the field the BAPI flag maps to. Runs in dialog too, and depends on `PROCESS_ITEM` firing before the rounding check. Use only if the primary cannot be implemented |

Both gate on the calling user being in TVARVC selection variable `ZMM_ARIBA_PO_USER`,
so only the Ariba / CIG technical user loses rounding. MRP rounding of PR quantities is a
different code path and is not touched by either.

Each file is a method body, header comment to `ENDMETHOD`. No `original/`: new object.

## Shipping: PASTE ONLY

A BAdI method body inside an SE19 implementation. Not zippable.

## Before you create the primary

1. **Parameter names.** The code uses `CH_ITEM` and `CH_ITEMX`. Confirm them on the
   `INBOUND` signature (SE18 → `ME_BAPI_PO_CUST` → Interface → double-click `INBOUND` →
   Parameters). If they differ, rename the two; the logic does not change. If the item
   tables are import-only, drop to the fallback.
2. **Existing implementation.** SE18 → `ME_BAPI_PO_CUST` → Implementation → Overview.
   Single-use BAdI: if PAL already has one active, put the method body into its
   `INBOUND` under BOC/EOC markers instead of creating a second one.
3. **Ariba technical user.** The RFC / service user CIG posts with. Basis or Mahender.
   Check `sy-uname` in a debug session on a replay if unsure.

If you fall back to `ME_PROCESS_PO_CUST`: it is almost always already implemented. Add
the block at the **top** of the existing `PROCESS_ITEM`, before anything that could
`RETURN`, under BOC/EOC markers.

## Manual steps

| Step | Where | What |
|---|---|---|
| 1 | SE19 | Classic BAdI → Create Implementation → definition `ME_BAPI_PO_CUST`, implementation `ZMM_BAPI_PO_NOROUND`, short text "Ariba PO: no qty rounding (INC01192)" |
| 2 | SE19 | Interface tab → double-click `INBOUND` → paste the method body → activate class. Other methods stay as generated, empty |
| 3 | SE19 | Activate the implementation |
| 4 | STVARV | Selection Options tab → `ZMM_ARIBA_PO_USER`, sign `I`, option `EQ`, low = Ariba technical user. One row per user if more than one. Customizing request |
| 5 | SE10 | Workbench TR for implementation + class; customizing TR for the STVARV entry |

Fallback: same steps with definition `ME_PROCESS_PO_CUST`, implementation
`ZMM_PO_NOROUND`, method `PROCESS_ITEM`.

## Test plan

Unit, DEV, no Ariba needed:

1. Put **your own user** into `ZMM_ARIBA_PO_USER` in DEV for the test.
2. Material with a rounding value (copy `EA02`'s MRP 1 setup, rounding value 120), PR for
   100.
3. SE37 → `BAPI_PO_CREATE1` → item referencing the PR, quantity 50, `NO_ROUNDING` left
   blank in `POITEM`, then `BAPI_TRANSACTION_COMMIT`.
   - Implementation inactive → PR quantity exceeded error, no PO.
   - Implementation active → PO created with 50, no rounding message.
4. Take your user back out of the variable.

With the fallback active, step 3 also proves the timing assumption: if the PO still
rounds, `PROCESS_ITEM` fires too late on this release and the flag has to be set by the
CIG add-on before the BAPI call.

Regression, DEV, with your user removed:

- ME21N on the same material, quantity 50 → rounds to 120. Manual path unchanged.
- MD02 on the material → PR quantity still rounded. MRP unchanged.

Integration, QS4-160, with Mahender:

- One real Ariba sourcing event on a rounding-value material, split award, send prices →
  PO created with the awarded quantities. Same flow Mahender used for PO 5000001993.

## Gotchas

- **Empty or missing TVARVC variable = no change.** Both versions return before touching
  anything, so a forgotten STVARV entry in QA or PRD shows up as "the fix does nothing",
  not as an error. First thing to check when a PO from Ariba still fails.
- The user gate is the whole scope control. Whoever is in the variable gets no rounding
  on every PO they post through the BAPI (primary), or every PO they create or change
  anywhere (fallback). Keep it to the CIG user; do not add buyers to it.
- `NO_ROUNDING` also suppresses rounding-profile rounding, not only the rounding value.
  For the Ariba path that is what PAL asked for.
- A BAdI inside a BAPI cannot raise a dialog message. There is deliberately no message
  in either method.
- Fallback only: `PROCESS_ITEM` fires once per item and again on re-processing. The
  `SET_DATA` call is guarded by "flag not yet set" so the item is written back once.

## First-time SE19 walkthrough (classic BAdI)

Written 17/09/26 for the first implementation on the PAL system. Pre-checks first, then
create, then STVARV, then test.

### Pre-checks, all display-only

1. **Method signature.** SE18 → BAdI name `ME_BAPI_PO_CUST` → Display → Interface tab →
   double-click the interface name `IF_EX_ME_BAPI_PO_CUST` → Methods tab → put the
   cursor on `INBOUND` → Parameters button. Note the names of the item and itemx table
   parameters and their Type column. Code expects `CH_ITEM` / `CH_ITEMX`, Changing.
2. **Flag exists.** SE11 → Data type `BAPIMEPOITEM` → Display → Components → find
   `NO_ROUNDING`. Repeat for `BAPIMEPOITEMX`.
3. **No existing implementation.** SE18 → `ME_BAPI_PO_CUST` → Display → menu
   Implementation → Overview. Already done 17/09/26: none.
4. **Package and TR.** Ask Mahender or Basis which Z package PAL's MM enhancements go
   in, and whether to create a new workbench request or use an open one.
5. **CIG user.** Ask Basis for the user CIG posts POs with. SU01 to confirm it exists.

### Create the implementation

1. SE19 → block "Create Implementation" → radio button **Classic BAdI** → BAdI Name
   `ME_BAPI_PO_CUST` → button **Create Impl.**
2. Popup: Implementation Name `ZMM_BAPI_PO_NOROUND` → Enter.
3. Package popup: the Z package from pre-check 4 → Save → workbench request popup →
   the TR from pre-check 4. The class `ZCL_IM_MM_BAPI_PO_NOROUND` is generated
   automatically in the same package and request.
4. Implementation screen: Short text `Ariba PO: no qty rounding (INC01192)`.
   Tab **Interface** lists the methods and the generated class name. **Save** (Ctrl+S)
   before touching any method.
5. Interface tab → double-click `INBOUND`. The Class Builder opens the method with two
   generated lines, `method ...` and `endmethod.`. Select everything in the editor,
   delete it, paste the whole of `ZCL_IM_MM_BAPI_PO_NOROUND.abap`, first line to last.
   The file already starts with `METHOD` and ends with `ENDMETHOD`.
6. Syntax check (Ctrl+F2). Fix or paste back any error. Then **Activate** (Ctrl+F3) →
   activation popup lists the class and its includes → select all → Enter. The class is
   now active.
7. Back (F3) to the SE19 implementation screen → **Activate** the implementation
   (Implementation → Activate, or the activate icon). Status text changes to "Active".
   Without this step the class exists but the BAPI never calls it.

The other methods (`EXTENSIONIN`, `EXTENSIONOUT`, `OUTBOUND` and any others listed)
stay as generated, empty. Do not delete them.

### STVARV entry

STVARV → tab **Selection Options** → Change → new row: Name `ZMM_ARIBA_PO_USER` →
Sign `I`, Option `EQ`, Low = CIG user → Save → customizing request popup → a
customizing TR, separate from the workbench one. For the DEV unit test below, add a
second row with your own user and delete it again afterwards.

### Test

1. **Is the BAdI reached at all.** SE24 → `ZCL_IM_MM_BAPI_PO_NOROUND` → method
   `INBOUND` → set a session breakpoint on the `SELECT`. SE37 → `BAPI_PO_CREATE1` →
   Test (F8) → fill nothing, Execute. The debugger must stop in the method even though
   the BAPI will then fail for missing data. If it does not stop, the implementation is
   not active; back to step 7 above.
2. **Does the flag work.** Needs a PR of 100 on a rounding-value material and a vendor
   in DEV. SE37 → `BAPI_PO_CREATE1` → menu Function Module → Test → Test Sequences →
   `BAPI_PO_CREATE1` then `BAPI_TRANSACTION_COMMIT`. Header: doc type, vendor, purch org,
   purch group, company code, copied from a working PO in ME23N. Item: material, plant,
   quantity 50, PR number and item. Itemx: `X` on the same fields. Schedule: delivery
   date. With your user in STVARV the PO is created with 50; with your user removed the
   BAPI returns the PR quantity exceeded error. Both results together are the proof.
3. **Real path.** After transport to QS4-160, Mahender replays one Ariba award on a
   rounding-value material with the CIG user in STVARV there. Same flow as PO
   5000001993.
