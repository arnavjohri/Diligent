# Issues — ZMM_PO_NOROUND

Running log: issue → cause → fix → TR → date. Newest last.

Object: BAdI implementation `ZMM_BAPI_PO_NOROUND` on `ME_BAPI_PO_CUST`, class
`ZCL_IM_MM_BAPI_PO_NOROUND`, method `INBOUND`.
PAL (Philippine Airlines) — Ariba Sourcing → S4 PO | MM
Ticket: INC01192 (repeat of INC00512) | Functional: Mahender Reddy Patlolla |
Business: Zheryn Kaye A. Broqueza, Jo Valerie D. Rubio (PAL)

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 17/09/26 | No PO generated after "send prices" from Ariba Sourcing to S4 for materials with a rounding value (e.g. `EA02`, plant `2PHQ`, MRP 1 rounding value 120 GAL) | Ariba posts the PO through `BAPI_PO_CREATE1`. Each item is rounded to `MARC-BSTRF`; the rounded quantity exceeds the open PR quantity and the PO is rejected. Confirmed by SAP AIS MM Purchasing Dev Support and reproduced by Mahender in QS4-160 (PO 5000001993 created only after the rounding value was removed). PAL keeps the rounding value for MRP PR sizing, so it cannot be removed | SAP's own pointer: `NO_ROUNDING = X` in `POITEM` / `POITEMX`. Set in `ME_BAPI_PO_CUST` method `INBOUND` on the BAPI item tables. Manual ME21N and the MRP run do not pass through the BAdI and are untouched | `<TR>` |
| 17/09/26 | `INBOUND` briefly believed not to exist; a `ME_PROCESS_PO_CUST` method list was read as `ME_BAPI_PO_CUST`'s | Wrong BAdI opened in SE18 | `INBOUND` confirmed present, no existing implementation of `ME_BAPI_PO_CUST` on PAL. A `PROCESS_ITEM` fallback was written meanwhile and is retired: it fires in dialog too and depends on running before the rounding check. Kept in git history only (`4e2bfbc`) | — |
| 17/09/26 | Caller gate on TVARVC `ZMM_ARIBA_PO_USER` dropped | Arnav's decision: the flag applies to every `BAPI_PO_CREATE1` / `BAPI_PO_CHANGE` caller, not only the Ariba user. Gate, STVARV entry and the customizing TR go away. `POITEMX` append also removed: on a change call an added X-row would make the BAPI process an item the caller did not flag | Method reduced to the item loop. Items without a `POITEMX` row are skipped | `<TR>` |
| 17/09/26 | "Copy Sample" left SAP's example logic live in all nine methods, and the header named the interface `IF_EX_ME_BAPI_PO_CUST` | The BAdI `ME_BAPI_PO_CUST` is delivered with interface `IF_EX_ME_BAPI_PO_CREATE_02`; the sample class `CL_EXM_IM_ME_BAPI_PO_CUST` carries demo code in every method (`OUTBOUND` clears item data for purch org 1000 / group 013, `EXTENSIONIN` / `MAP2*` raise exceptions, `TOGGLE_ORDER_UNIT` overrides the unit) | Repo file is now the whole class: eight methods empty, `INBOUND` with the fix, interface name corrected. `INBOUND` signature confirmed from the system: `CH_ITEM` / `CH_ITEMX`, both changing | `<TR>` |
