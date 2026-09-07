# HANDOVER — ZMMIMS (GeM Invoice No. handling)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | MM |
| Object in SAP | `SAPMZMMIMS`, tcode `ZMMIMS` — a **pre-existing custom module pool from 2008** |
| My change marker | **+019** (earlier authors: +005, +012, +018) |
| Repo path | `kpmg/zmmims/` |
| Ships by | **PASTE-ONLY** |
| Status | Corrections delivered. No activation or issue record in the repo — confirm in the system before assuming it is live |

## What the change does

Two things, both about the GeM Invoice number:

1. **F4 fix** — the search help was returning the wrong invoice, or none.
2. **Auto-display** — the invoice number is proposed into the field instead of being typed.

## The four files, and which are whole objects

| File | Lines | What |
|---|---|---|
| `MZMMIMSF01.abap` | 3,511 | **Whole include** — the FORM include |
| `MZMMIMSI01.abap` | 2,002 | **Whole include** — PAI / module include, screens 0100 / 0150 / 0200 |
| `MZMMIMSI01_GET_GEMINV.abap` | 136 | **Fragment** — the single replacement `MODULE get_geminv INPUT` |
| `ZMMIMS_GEM_INV_AUTO_DISPLAY.abap` | 172 | **Fragment / patch sheet** — new `FORM get_gem_invoice_no` appended to `MZMMIMSF01`, plus three call points |

The three call points for auto-fill: `MODULE valid_input_200` (create),
`FORM save_data_ims` (safety net before the `MODIFY`), `FORM check_validation_150`
(change / display of pre-existing documents).

## The three root causes — worth reading, because the symptoms are misleading

1. **"The number appears automatically" (the original complaint).**
   `IST_RETURN_TAB` is declared `WITH HEADER LINE` in `MZMMIMSTOP` and is **shared by every
   search help in the program** — plant, purchasing group, currency, tracking no., indentor
   CPF. The original `GET_GEMINV` neither refreshed it nor guarded the assignment, so a
   cancelled or empty F4 left behind the value picked in a *different* search help.
   **Always `CLEAR` and `REFRESH` it.**
2. **The correct invoice vanished from the hit list.**
   `DELETE ADJACENT DUPLICATES` ran **before** the PO filter, so when one GeM invoice
   existed against several POs the surviving row could carry a different `EBELN` and got
   deleted.
3. **Every F4 read the whole table.** `EBELN` was missing from the `WHERE` clause, so all of
   `ZGEM_BILL` was joined against EKKO / LFA1 and read into memory on every F4.

## If a user reports an empty hit list this week

**Check `BSART` / `PROCSTAT` of the PO in SE16 first.** The restriction
`EKKO-BSART IN ('MMGM','MMGS') AND EKKO-PROCSTAT = '05'` is retained from the original but
is now **isolated in a RANGE so it can be switched off in one place**. It is the likeliest
cause of an empty list, and it is not a defect in my change.

Second candidate: only invoices that also exist in `ZGEM_BILLDET` may be proposed —
`MODULE check_geminv` validates against that table with a type E message, so proposing
anything else makes the document unsaveable.

## Behaviour that is deliberate, not a bug

- Auto-fill only ever writes into an **initial** field, so calling the FORM more than once
  is harmless and a user's own entry is never overwritten.
- With several GeM invoices on one PO, the **first (ascending)** is filled and an
  information message is issued.

## Applying the two fragments

The patch sheets locate their inserts **by line number**. Those numbers are against one
snapshot. **Locate by FORM / MODULE name instead**, and diff a fresh SE80 download against
the repo copy before applying anything — this pool has had four other authors in it and the
running version may not match.

## Dependencies

Tables `ZGEM_BILL`, `ZGEM_BILLDET`, `EKKO` (`ZGEMPO`), `LFA1`, `ZMM_IMS`.
`ZMM_IMS-GEM_INVOICE_NO` is persisted by the existing `MODIFY zmm_ims FROM wa_zmm_ims`
in `FORM save_data_ims` — no new persistence was added.

## Stays manual regardless

SE51 screens 0100 / 0150 / 0200 of `SAPMZMMIMS` and everything else in that pool. This work
touches includes only and never re-creates the program. **Never re-create the pool.**
