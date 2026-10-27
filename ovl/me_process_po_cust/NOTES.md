# ovl/me_process_po_cust — client BAdI implementation ME_PROCESS_PO_CUST (PO checks), OVL

## What it is

The OVL implementation of BAdI `ME_PROCESS_PO_CUST`. Only method `CHECK` is on file:
`original/IF_EX_ME_PROCESS_PO_CUST_CHECK.abap`, 6336 lines, pasted into chat by Arnav on
27/10/26 and recovered from the session transcript (the paste carried a chat sentence after
`ENDMETHOD.`, stripped). **Implementation name and class (SE19) not yet supplied** — needed
before any change is written. It runs for ME21N/ME22N/ME29N/ME31K…, for `BAPI_PO_CREATE1`
callers, and for the Fiori *Manage Purchase Orders* app (same ME processing on draft
activation).

Change history in the header goes back to 2011 (CAB_SPYADAV, CAB_LIPSY, CAB_DHIRAJ, Anamika,
Rahul Gupta, SAP_ABAP ATC remediation 05–11.06.2026). Dozens of client rules live here: vendor
category vs LFA1 industry key, fund sanction vs PR, tender/TC-member release checks, GST
pop-up, SRM price checks, valuation type, Udyam number, document date, and the PO validity
period.

## How it ships

Paste-only: a method body inside an existing BAdI implementation. Never abapGit. Change markers
per CLAUDE.md inside the method; the ATC work in this method used `SAP_ABAP` as the author tag,
issue fixes use `Arnav` — confirm which before the first paste.

## The validity-period rules (27/10/26) — why Fiori service POs fail

All inside `IF g_trtyp = 'V' OR g_trtyp = 'H'` (create/change) and only for documents not yet
released (`frgke NE 'S'`). Line numbers are of the original file, snapshot-bound.

| Lines | Rule | Effect with blank `KDATB`/`KDATE` |
|---|---|---|
| 244–256 | `bsart+0(1) = 'S'` and start or end blank → `MESSAGE W523(zmm)` and `ch_failed = 'X'` ("Change for Lean": E523 became W523, but `ch_failed` still fails the check) | check fails, PO not saved |
| 295–311 | `SWO` against the OLA validity | skipped when either date is blank — harmless |
| 313–342 | fiscal year of the latest delivery date vs fiscal year of `KDATE` (`GM_GET_FISCAL_YEAR`, FYV `V3`) → `e525` for `S*` | blank end date → no fiscal year → years differ → `e525` |
| 344–346 | `S*` and `KDATE` < latest delivery date → error | blank < any date → error |

So a service-type PO created in the Fiori app, where the two dates cannot be entered (the
standard `C_PurchaseOrderTP` hides them with `@Consumption.hidden`, see
`ovl/zmm_purchdoc_cds_ext/`), fails at three places, not one. The 2015-era E→W change did not
open the path.

## Telling Fiori from the GUI

`sy-tcode` is blank in the Fiori session. Evidence (Arnav, 27/10/26): `CDHDR-TCODE` is `ME21N`
for GUI-created POs and blank for app-created ones; change documents copy `sy-tcode`. The same
is true for `BAPI_PO_CREATE1` from RFC, IDoc, SRM and background jobs, so "`sy-tcode` blank"
means *not a dialog transaction*, not *Fiori*. The method already scopes several rules with
`IF sy-tcode = 'ME21N' OR …`; the inverse (`IF sy-tcode IS NOT INITIAL`) is the consistent way
to keep a rule GUI-only.

## Fiori hazard found while reading (not part of any issue yet)

Line ~4563: `POPUP_TO_CONFIRM` ("Sanction is not sufficient but EPC approval exists?") runs
whenever `zzepc = 'Y'` and the purchasing group is in `ZMM_EKGRP`, with no `sy-tcode` guard.
In a Fiori or BAPI session there is no GUI, so this is a `DYNPRO_SEND_IN_BACKGROUND` short dump
waiting for the first EPC-approved PO saved from the app. The GST pop-up at ~553 is guarded
(`ME21N`/`ME22N` only).

## Gotchas

- The paste is one method of a class; the implementation's other methods (`OPEN`,
  `PROCESS_HEADER`, `PROCESS_ITEM`, `POST`, `CLOSE`) are not on file. `g_trtyp` is set elsewhere.
- Many rules raise plain `MESSAGE … TYPE 'E'` rather than `mmpur_message`; in a BAPI/Fiori
  session those abort the save with the text as the error.
- Do not touch anything outside the validity block when the bypass is built: the rest of the
  method is the client's PO rulebook.
