# ZMM_PO_VALIDITY_FS — NOTES

## What it is

Udayan (KPMG, via Vaibhav), 12.10.2026: PO header fields **Validity Start / Validity End**
(`EKKO-KDATB` / `EKKO-KDATE`, Additional Data tab) must be input-ready for document type
**SBP** (MM- SRV Board PO) only. No validation wanted — the fields are simply hidden for every
other document type.

Functional side already moved SBP from field selection key ZBRD to NBF so Fiori shows the
fields. In GUI the hide-by-document-type is done in the existing classic BAdI implementation
of `ME_PROCESS_PO_CUST`, method `FIELDSELECTION_HEADER` (same implementation that carries the
budget check in `CHECK`, see `kpmg/zmm_po_budget/`).

## How it works

- Merged field status is the **most restrictive** of all sources (transaction, doc type key,
  BAdI). That is why the pre-existing `ELSE ... '.'` never opened the ZBRD-hidden fields, and
  why `'-'` from the BAdI hides them even on NBF.
- Document types that keep the fields come from TVARVC `ZPO_VALIDITY_DOCTYPE` (type S,
  selection option). **Create it in STVARV** before testing: `I EQ SBP`. Empty variable =
  hidden for everyone.
- The BAdI also fires for the Fiori Manage Purchase Orders app, so the same rule applies there.

## Shipping: PASTE-ONLY

SE19 → implementation of `ME_PROCESS_PO_CUST` → method `FIELDSELECTION_HEADER`. Replace the
whole method body with `ME_PROCESS_PO_CUST_FIELDSELECTION_HEADER.abap` (as-supplied body is
in `original/`).

## Gotchas

- Metafields confirmed from type group `MMMFD`: `mmmfd_valid_from` (037, EKKO-KDATB) and `mmmfd_valid_to` (038, EKKO-KDATE).
  **Not** `mmmfd_valid_startdate` / `mmmfd_valid_enddate` (851/852) — those are item-level lean-service dates.
- The customer metafields 9000013x / 90000121 / 90000148 (required) belong to someone else's
  custom-field work and were not touched.
- `ME23N` (display) is still forced to display by the transaction key; the BAdI cannot open it.

## 12/10/26 — BAdI approach withdrawn

Debugger on `FIELDSELECTION_HEADER` showed `CH_FIELDSELECTION` holds **only customer
metafields** (90000121–90000141). Standard header metafields 37/38 (KDATB/KDATE) are never
passed in, so this method cannot show or hide Validity Start/End. The delivered ELSEIF is dead
code; the method should be reverted to the original. Keep this file as the record of why.

Standard-field status = most restrictive of the merged keys: transaction `ME21N`, activity
`AKTH`, doc type `NBF`, release key. T161 shows SBP → NBF, so the hide sits in one of the
others. Fix in OMF4 by setting the Validity period group to Optional on the offending key.

If per-doc-type hiding is wanted dynamically later: `FIELDSELECTION_HEADER_REFKEYS` swaps the
field selection keys per document; `FIELDSELECTION_HEADER` is for customer fields only.
