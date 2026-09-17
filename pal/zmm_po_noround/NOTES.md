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
