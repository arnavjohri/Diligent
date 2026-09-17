# ZMM_PO_NOROUND — NOTES

## What it is

BAdI implementation `ZMM_BAPI_PO_NOROUND` for the classic BAdI `ME_BAPI_PO_CUST`.
Its interface is `IF_EX_ME_BAPI_PO_CREATE_02`, SAP's internal working name for the
BAdI, so the method is `IF_EX_ME_BAPI_PO_CREATE_02~INBOUND`. Implementing class
`ZCL_IM_MM_BAPI_PO_NOROUND`, created in SE19 on 17/09/26 via "Copy Sample".

For every PO that goes through `BAPI_PO_CREATE1` or `BAPI_PO_CHANGE`, whoever calls
it, it sets `NO_ROUNDING = X` on every item in `POITEM` and mirrors the flag in
`POITEMX`. The BAPI then takes the quantity as sent instead of rounding it to the
material master rounding value (`MARC-BSTRF`). Exactly what SAP AIS told Mahender to do
in the CIG call, done once inside the system instead.

Not affected, by construction: manual ME21N / ME22N, ME59N, and the MRP run (PR
quantity). None of them call the BAPI, so none reach this BAdI.

One file: `ZCL_IM_MM_BAPI_PO_NOROUND.abap`, the **whole class**, definition and
implementation, all nine interface methods. Paste in source-code-based mode, select-all
and replace. No `original/`: new object. No STVARV, no customizing TR.

History, both in git only: a version gated on TVARVC `ZMM_ARIBA_PO_USER` (dropped
17/09/26, Arnav's call: apply to every BAPI caller), and a `ME_PROCESS_PO_CUST`
`PROCESS_ITEM` fallback (retired, commit `4e2bfbc`).

## Shipping: PASTE ONLY

A BAdI method body inside an SE19 implementation. Not zippable.

## SE19 state after "Copy Sample"

"Copy Sample" copies `CL_EXM_IM_ME_BAPI_PO_CUST` into the Z class, so every method
carried live sample logic: `OUTBOUND` wiped accounts, schedules and conditions for
purchasing org 1000 / group 013, `EXTENSIONIN` and both `MAP2*` methods ran RTTS mapping
and raised exceptions, `TOGGLE_ORDER_UNIT` overrode the order unit. The file replaces
all of it: eight methods empty, `INBOUND` with the fix. The sample's public types and
private constants are dropped with the code that used them.

1. SE24 or SE80 → class → switch to source-code-based editing → select all → paste the
   file → Ctrl+F2 → Ctrl+F3, select all in the activation popup.
2. SE19 → implementation `ZMM_BAPI_PO_NOROUND` → **Implementation → Activate**. Status
   must read "Active". Without that step the class exists but the BAPI never calls it.

`INBOUND` signature confirmed on the PAL system 17/09/26: `CH_ITEM` type
`BAPIMEPOITEM_TP`, `CH_ITEMX` type `BAPIMEPOITEMX_TP`, both changing, plus `IM_AKTYP`
(create = `HIN`, change = `VER`) and `CH_RETURN` if a message is ever needed.

## Test plan

1. **Is the BAdI reached.** SE24 → the class → `INBOUND` → session breakpoint on the
   `LOOP`. SE37 → `BAPI_PO_CREATE1` → F8 → Execute with nothing filled. The debugger
   must stop in the method even though the BAPI then fails on missing data. If it does
   not stop, the implementation is not active.
2. **Does the flag work.** DEV, needs a PR of 100 on a rounding-value material (copy
   `EA02`'s MRP 1 setup, rounding value 120) and a vendor. SE37 → `BAPI_PO_CREATE1` →
   Function Module → Test → Test Sequences, with `BAPI_TRANSACTION_COMMIT` second.
   Header fields copied from a working PO in ME23N; item: material, plant, quantity 50,
   PR number and item; itemx: `X` on the same fields; schedule: delivery date.
   - Implementation inactive → PR quantity exceeded error, no PO.
   - Implementation active → PO created with 50, no rounding message.
3. **Regression, DEV.** ME21N on the same material, quantity 50 → still rounds to 120.
   MD02 on the material → PR quantity still rounded.
4. **Real path.** After transport to QS4-160, Mahender replays one Ariba award on a
   rounding-value material, split award, send prices → PO created with the awarded
   quantities. Same flow as PO 5000001993.

## Gotchas

- **Scope is every BAPI caller.** Any custom PO upload program or other interface at
  PAL that uses `BAPI_PO_CREATE1` / `BAPI_PO_CHANGE` also stops rounding from the
  moment this is active. Decided 17/09/26; if anyone reports a rounding change on a
  non-Ariba PO, this is why.
- `NO_ROUNDING` also suppresses rounding-profile rounding, not only the rounding value.
- Items with no `POITEMX` row are skipped on purpose. The BAPI transfers none of their
  fields anyway, and on a `BAPI_PO_CHANGE` call an added X-row would make the BAPI
  process an item the caller did not flag.
- A BAdI inside a BAPI cannot raise a dialog message. There is deliberately none.
- Upgrade-safe: released customer BAdI, no SPAU / SPAU_ENH entry.
