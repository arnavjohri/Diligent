# ZMM_PO_NOROUND — NOTES

## What it is

BAdI implementation `ZMM_PO_NOROUND` for the classic BAdI `ME_PROCESS_PO_CUST`,
method `IF_EX_ME_PROCESS_PO_CUST~PROCESS_ITEM`. Implementing class
`ZCL_IM_MM_PO_NOROUND` (SE19 generates the name from the implementation name).

For PO items processed under the Ariba / CIG technical user, it sets
`MEPOITEM-NO_ROUNDING = X`, which is the field `BAPI_PO_CREATE1` fills from
`POITEM-NO_ROUNDING`. The PO then takes the awarded quantity as sent instead of rounding
it to the material master rounding value (`MARC-BSTRF`). Any other user is left alone.
MRP rounding of PR quantities is a different code path and is not touched.

One file: `ZCL_IM_MM_PO_NOROUND.abap` — the method body, header comment to `ENDMETHOD`.
No `original/`: this is a new object.

History: the first draft (17/09/26, commit `61457a3`) was written for `ME_BAPI_PO_CUST`
method `INBOUND`. That method does not exist on this system. Superseded, not patched.

## Shipping: PASTE ONLY

A BAdI method body inside an SE19 implementation. Not zippable.

## Before you create it

1. **Check for an existing implementation.** SE18 → `ME_PROCESS_PO_CUST` →
   Implementation → Overview. This BAdI is single-use and very commonly already
   implemented. If PAL has an active implementation, put the method body into its
   `PROCESS_ITEM` under BOC/EOC markers instead of creating a second one. If that
   `PROCESS_ITEM` already has code, add this block at the **top**, before anything
   that could `RETURN`.
2. **Get the Ariba technical user.** The RFC / service user CIG posts with. Basis or
   Mahender. Check `sy-uname` in a debug session on a replay if unsure.

## Manual steps

| Step | Where | What |
|---|---|---|
| 1 | SE19 | Classic BAdI → Create Implementation → definition `ME_PROCESS_PO_CUST`, implementation `ZMM_PO_NOROUND`, short text "Ariba PO: no qty rounding (INC01192)" |
| 2 | SE19 | Interface tab → double-click `PROCESS_ITEM` → paste the method body → activate class. The other methods stay as generated, empty |
| 3 | SE19 | Activate the implementation |
| 4 | STVARV | Selection Options tab → `ZMM_ARIBA_PO_USER`, sign `I`, option `EQ`, low = Ariba technical user. One row per user if more than one. Customizing request |
| 5 | SE10 | Workbench TR for implementation + class; customizing TR for the STVARV entry |

## Test plan

Unit, DEV, no Ariba needed. This test also proves the timing assumption in the header:

1. Put **your own user** into `ZMM_ARIBA_PO_USER` in DEV for the test.
2. Material with a rounding value (copy `EA02`'s MRP 1 setup, rounding value 120), PR for
   100.
3. SE37 → `BAPI_PO_CREATE1` → item referencing the PR, quantity 50, `NO_ROUNDING`
   left blank in `POITEM`, then `BAPI_TRANSACTION_COMMIT`.
   - Implementation inactive → PR quantity exceeded error, no PO.
   - Implementation active → PO created with 50, no rounding message.
   If the PO still rounds with the implementation active, `PROCESS_ITEM` fires too late
   on this release and the flag must be set by the CIG add-on before the BAPI call.
4. ME21N under your user on the same material, quantity 50 → no rounding either. That
   is expected while your user is in the variable and is the reason for step 5.
5. Take your user back out of the variable.

Regression, DEV, with your user removed:

- ME21N on the same material, quantity 50 → rounds to 120. Manual path unchanged.
- MD02 on the material → PR quantity still rounded. MRP unchanged.

Integration, QS4-160, with Mahender:

- One real Ariba sourcing event on a rounding-value material, split award, send prices →
  PO created with the awarded quantities. Same flow Mahender used for PO 5000001993.

## Gotchas

- **Empty or missing TVARVC variable = no change.** The method returns before touching
  anything, so a forgotten STVARV entry in QA or PRD shows up as "the fix does nothing",
  not as an error. First thing to check when a PO from Ariba still fails.
- The user gate is the whole scope control. Whoever is in the variable gets no rounding
  on **every** PO they create or change, in dialog and by BAPI. Keep it to the CIG user;
  do not add buyers to it.
- `NO_ROUNDING` also suppresses rounding-profile rounding, not only the rounding value.
  For the Ariba path that is what PAL asked for.
- `PROCESS_ITEM` fires once per item and again on re-processing. The `SET_DATA` call is
  guarded by "flag not yet set" so the item is written back once, not on every pass.
- The TVARVC read is per item call. TVARVC is small; for a PO of a few items this is
  not measurable. If it ever matters, cache the range in a static attribute of the class.
