# ZMM_BAPI_PO_NOROUND — NOTES

## What it is

BAdI implementation `ZMM_BAPI_PO_NOROUND` for the classic BAdI `ME_BAPI_PO_CUST`,
method `IF_EX_ME_BAPI_PO_CUST~INBOUND`. Implementing class
`ZCL_IM_MM_BAPI_PO_NOROUND` (SE19 generates the name from the implementation name).

For POs created through `BAPI_PO_CREATE1` by the Ariba / CIG technical user, it sets
`NO_ROUNDING = X` on every item in `POITEM` and `POITEMX`, so the BAPI takes the
awarded quantity as sent instead of rounding it to the material master rounding value
(`MARC-BSTRF`). Any other caller is left alone. MRP rounding of PR quantities is on a
different code path and is not touched.

One file: `ZCL_IM_MM_BAPI_PO_NOROUND.abap` — the method body, header comment to
`ENDMETHOD`. No `original/`: this is a new object.

## Shipping: PASTE ONLY

A BAdI method body inside an SE19 implementation. Not zippable.

## Before you create it

1. **Check for an existing implementation.** SE18 → `ME_BAPI_PO_CUST` → Implementation
   → Overview. `ME_BAPI_PO_CUST` is single-use: if PAL already has an active
   implementation, put this logic into its `INBOUND` method under BOC/EOC markers
   instead of creating a second one.
2. **Verify the parameter names.** SE18 → `ME_BAPI_PO_CUST` → Interface tab →
   double-click `INBOUND` → Parameters. The code assumes `CH_ITEM` and `CH_ITEMX`
   (changing). If this release names them differently, rename the two in the code.
   If the item tables are import-only on this release, this BAdI cannot do the job and
   the flag has to be set in the CIG add-on before the BAPI call — that is the fallback
   design, not a variation of this one.
3. **Get the Ariba technical user.** The RFC / service user CIG posts with. Basis or
   Mahender. Check `sy-uname` in a debug session on a replay if unsure.

## Manual steps

| Step | Where | What |
|---|---|---|
| 1 | SE19 | Classic BAdI → Create Implementation → definition `ME_BAPI_PO_CUST`, implementation `ZMM_BAPI_PO_NOROUND`, short text "Ariba PO: no qty rounding (INC01192)" |
| 2 | SE19 | Interface tab → double-click `INBOUND` → paste the method body → activate class → activate implementation |
| 3 | STVARV | Selection Options tab → `ZMM_ARIBA_PO_USER`, sign `I`, option `EQ`, low = Ariba technical user. One row per user if more than one. Transport the table entry with the customizing request |
| 4 | SE10 | Workbench TR for the implementation + class; customizing TR for the STVARV entry |

## Test plan

Unit, DEV, no Ariba needed:

1. Put **your own user** into `ZMM_ARIBA_PO_USER` in DEV for the test.
2. Material with a rounding value (copy `EA02`'s MRP 1 setup, rounding value 120), PR for
   100.
3. SE37 → `BAPI_PO_CREATE1` → item referencing the PR with quantity 50, then
   `BAPI_TRANSACTION_COMMIT`.
   - Implementation inactive → PR quantity exceeded error, no PO.
   - Implementation active → PO created with 50, no rounding message.
4. Take your user back out of the variable.

Regression, DEV:

- ME21N on the same material, quantity 50 → still rounds to 120. Manual path unchanged.
- MD02 on the material → PR quantity still rounded. MRP unchanged.

Integration, QS4-160, with Mahender:

- One real Ariba sourcing event on a rounding-value material, split award, send prices →
  PO created with the awarded quantities. Same flow Mahender used for PO 5000001993.

## Gotchas

- **Empty or missing TVARVC variable = no change.** The method returns before touching
  anything, so a forgotten STVARV entry in QA or PRD shows up as "the fix does nothing",
  not as an error. First thing to check when a PO from Ariba still fails.
- The user gate is the whole scope control. Whoever is in the variable gets no rounding
  on **every** `BAPI_PO_CREATE1` call they make. Keep it to the CIG user; do not add
  buyers to it.
- `NO_ROUNDING` also suppresses rounding-profile rounding, not just the rounding value.
  For the Ariba path that is what PAL asked for.
- A BAdI inside a BAPI cannot raise a dialog message. There is deliberately no message
  in the method.
