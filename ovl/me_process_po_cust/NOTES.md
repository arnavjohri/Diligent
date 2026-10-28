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

## Udayan Dayal's two-PO test, 26/10/26 (mail via Vaibhav, forwarded 28/10/26)

PO 5300000068 created in the GUI, 5300000069 in the Fiori app, same data, doc type "MM- SRV
Board PO" (an `S*` type: the lines 344–346 error fired, and it is `S*`-only). Screenshots in
`original/`. What the test established and what it did not:

- The app showed the error of lines 344–346 and a warning "Validity period less than a week"
  that is **not in `CHECK`** — it sits in another method of the implementation, together with
  the defaulting Udayan describes (`KDATB`/`KDATE` taken from the custom Scheduled Work
  Start/End dates while saving). That source is not on file.
- No W523 in the popover, so both dates were filled when the check ran. The two messages fit
  the moment after Scheduled Start was entered and before Scheduled End: both dates equal to the
  start, so end < delivery date and period < 7 days. At Order the end date was 30.12.2026, the
  rules passed, the PO saved. Fiori keeps the stale messages in the popover.
- Not excluded: a raw `MESSAGE … TYPE 'E'` without `ch_failed` is collected but does not block
  the app's save. One test decides it: a Fiori PO with Scheduled Work End earlier than the item
  delivery date, then Order. If it saves, every rule that must hold in Fiori needs
  `ch_failed = 'X'` and `mmpur_message`.
- After approval (ME29N, classic release) the Fiori PO opens in SAP GUI for HTML. That is the
  app's feature check, not this BAdI — see `ovl/zmm_purchdoc_cds_ext/ISSUES.md` #4.

## Corrected object (28/10/26)

`IF_EX_ME_PROCESS_PO_CUST_CHECK.abap` at the folder root is the whole method body, 6351 lines
(original 6336). One change, lines 344–360: the "validity end before the latest delivery date"
rule is a warning when `sy-tcode` is blank (the app, and every BAPI / RFC / batch caller) and
an error otherwise. Everything else is byte-identical to the 27/10 paste — diff it against the
system copy before pasting if anyone has touched the method since.

Why a warning and not `ch_failed`: in the app the raw `MESSAGE E` showed on the first Order and
the second Order saved (no re-check without a change, and the message never marked the document
failed). A warning makes the first Order behave like the second, which is what the client wants
since the dates are defaulted from the Scheduled Work dates anyway. In the GUI the user can
still correct the validity end, so the error stays.

## Approved PO opens in SAP GUI for HTML — what decides it, and the way to "Fiori only"

Not this BAdI. SAP's `C_PurchaseOrderTP` carries `IsAdvancedPurchaseOrder` (line 315 of the copy
in `ovl/zmm_purchdoc_cds_ext/original/`), filled at runtime by
`CL_MM_PUR_PO_MAINTAIN_FEAT_CHK` (`CHECK_HEADER_FEATURES`, `CHECK_ITEM_FEATURES`) when the list
is built. One failed feature marks the PO Advanced; the app then opens ME23N/ME22N in GUI for
HTML and shows the Advanced marker in the list (SAP KBAs 2372209, 3777528, 2822661 — hosts not
reachable from this session). Order of work:

1. Which check fails: external breakpoint in the two methods, user = the tester, refresh the
   list. The failing feature name is the whole diagnosis. Also: does 5300000068 (GUI-created,
   also approved) switch? Yes → the release state trips it, not the creation path.
2. Lead inside this method: on ME29N the client's `CHECK` rewrites the header at release —
   `kalsm` to `ZIMP`/`ZIND` and `zzrelcode`, then `im_header->set_data`. If the failing feature
   is pricing-procedure related, the client's own release step causes it.
3. Remove the cause (config or data) if the feature is one SAP lists as unsupported by
   configuration. Only as a last resort, and only after the app has been seen to display and
   edit such a PO correctly: an implicit enhancement at the end of the failing check method
   that clears the flag for that one feature. That overrides SAP's protection for the app and
   needs the functional lead's sign-off; no code until step 1 names the feature.
