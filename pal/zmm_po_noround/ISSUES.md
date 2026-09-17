# Issues — ZMM_PO_NOROUND

Running log: issue → cause → fix → TR → date. Newest last.

Object: BAdI implementation `ZMM_PO_NOROUND` on `ME_PROCESS_PO_CUST`, class
`ZCL_IM_MM_PO_NOROUND`, method `PROCESS_ITEM` | PAL (Philippine Airlines) — Ariba
Sourcing → S4 PO | MM
Ticket: INC01192 (repeat of INC00512) | Functional: Mahender Reddy Patlolla |
Business: Zheryn Kaye A. Broqueza, Jo Valerie D. Rubio (PAL)

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 17/09/26 | No PO generated after "send prices" from Ariba Sourcing to S4 for materials with a rounding value (e.g. `EA02`, plant `2PHQ`, MRP 1 rounding value 120 GAL) | Ariba posts the PO through `BAPI_PO_CREATE1`. Each item is rounded to `MARC-BSTRF`; the rounded quantity exceeds the open PR quantity and the PO is rejected. Confirmed by SAP AIS MM Purchasing Dev Support and reproduced by Mahender in QS4-160 (PO 5000001993 created only after the rounding value was removed). PAL keeps the rounding value for MRP PR sizing, so it cannot be removed | SAP's own pointer: `NO_ROUNDING = X` in `POITEM` / `POITEMX`. First draft targeted `ME_BAPI_PO_CUST` method `INBOUND`, which does not exist on this system. Replaced by `ME_PROCESS_PO_CUST` method `PROCESS_ITEM` setting `MEPOITEM-NO_ROUNDING`, the field the BAPI flag maps to, gated on the calling user being in TVARVC `ZMM_ARIBA_PO_USER`, so manual ME21N and the MRP run are untouched | `<TR>` |
