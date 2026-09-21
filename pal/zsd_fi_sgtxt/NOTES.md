# ZSD_FI_SGTXT — NOTES

## What it is

PAL (Philippine Airlines) | SD-FI | Ticket INC01740.
Fiori app **Manage Customer Line Items** (F0711) shows no text on the customer line of SD
billing documents. Business wants the sales order **Header Note 1** on the customer
(A/R) line, so it appears in the app the way it already does on the Statement of Account.

`BSEG-SGTXT` / `ACDOCA-SGTXT` on the customer line are both filled from `ACCIT-SGTXT` by
the SD-FI interface, so the fix is to fill `SGTXT` at posting time. Nothing in the Fiori
app or its CDS needs touching.

Object: include `ZXVVFU02` (customer exit `EXIT_SAPLV60B_002`, enhancement `SDVFX002`),
already active at PAL in an existing CMOD project (name not yet noted). The include carries
Nir Ben Ami's IATA SIS logic (09/08/2024, "Populate Reference/Payment Method"); the fix is
an insert into it. Corrected file: `ZXVVFU02.abap` (221 lines, original 119).

## Where the code goes (recommendation)

**Customer exit `EXIT_SAPLV60B_002`** (enhancement `SDVFX002`, include `ZXVVFU02`,
activated through a CMOD project). It is called once per customer (A/R) line while the
billing document is transferred to accounting, with the billing header `VBRK` importing
and the accounting line `XACCIT` changing. That is exactly the line the app shows, so:

- no filtering on `AWTYP`/`KOART` is needed — the exit only ever sees SD customer lines;
- `xaccit-sgtxt = <text>` is a direct assignment; nothing else to map;
- G/L, tax and cash-clearing lines are untouched (they have their own exits, `_004`/`_006`/`_003`).

**Not BTE 00001430.** No FI-BTE with that number is known; the general-FI alternative is
BTE 00001120 (SAP-internal field substitution), which fires for *every* FI posting and
would need `AWTYP = 'VBRK'` and `KOART = 'D'` guards plus the BTE's allowed-field list.
More surface, same result. Use the SD exit.

**Not the AC_DOCUMENT BAdI** for the same reason — fires for all postings.

**System state (confirmed 21/09/26):** `ZXVVFU02` exists and is active. Signature at PAL:
`XACCIT` importing/exporting by value, `VBRK` importing, `DOC_NUMBER` optional, tables
`CVBRP` (`VBRPVB`) and `CKOMV`. So the billing items **are handed over** — `CVBRP-AUBEL`
gives the sales orders, no `SAPLV60A` field-symbol trick and no `SELECT` on `VBRP`.

**Insert point is load-bearing.** The existing code starts with
`READ TABLE cvbrp INDEX 1` / `CHECK ls_cvbrp-kvgr3 = '1'` — an SIS (IATA) gate. `CHECK`
inside a customer-exit include leaves the whole function module, so every non-SIS
billing document exits there. The INC01740 block therefore sits **above** that `CHECK`,
right after the existing `CONSTANTS`. Placed below it, the fix would run only for SIS
invoices and the ticket would come back.

## How the text is found

1. **Sales order(s) behind the billing document.** `CVBRP-AUBEL` per item, distinct.
   (`VBRP` is not in the database yet at VF01 time — the exit's own `CVBRP` table is the
   only correct source, and it is there.)
2. **Which sales order when there are several.** Ticket wording (business): "the
   Header Note 1 details from the **first-created** Sales Order". So: collect the distinct
   `AUBEL`s, `SELECT vbeln, erdat, erzet FROM vbak FOR ALL ENTRIES` (SOs are in the DB),
   `SORT BY erdat erzet vbeln`, take the first. `VBELN` is the tie-break only. Lowest
   document number alone is not what was asked, even if it usually gives the same answer.
3. **The text.** `READ_TEXT` — never read `STXL` directly, it is a compressed cluster.
   `OBJECT = 'VBBK'`, `NAME = <sales order>`, `ID = 0002`, language = `VBRK-SPRAS`; if
   the note is not in that language, the first language it exists in (`STXH` header
   lookup, `ORDER BY tdspras`). `ID = 0002` is an **ASSUMPTION** in the code: the VA02
   text list at PAL runs Form Header / Header Note 1 / Header Note 2 in SAP's standard
   order (0001 / 0002 / 0003), which fits, but confirm in **SE75 → Text objects and IDs
   → VBBK** (or SE16 `TTXIT`, `TDOBJECT = VBBK`, `TDSPRAS = E`) before activating. If
   the SOA form's `READ_TEXT` uses a different ID, use that one — the two views must
   match.
4. **Into SGTXT.** `SGTXT` is CHAR 50. `TLINE` rows joined with a blank, `CONDENSE`,
   assignment truncates. Written only when `xaccit-sgtxt` is still empty and a note was
   found — a value already there (SAP or another exit) is kept.

Reading the *billing document's own* header text (if config copied the SO note into it)
is **not** an option here: at VF01 the billing texts are not in `STXH` yet either.

## Paste map

`ZXVVFU02` — the whole file replaces the include (select-all, paste, activate). The
block `*BOC By Arnav on 21/09/26` … `*EOC` sits between the existing `CONSTANTS` and
`READ TABLE cvbrp INTO ls_cvbrp INDEX 1`. Two header rows filled in the CHANGE HISTORY
table. Nothing else in the include is touched.

Deliberately not touched: the existing `SELECT SINGLE auart … WHERE vbeln = cvbrp-aubel`
and the `ziata_rej_det` select read the **header line** `cvbrp`, not `ls_cvbrp`, so
`lv_auart` and the rejection period are probably never found. Not this ticket; raise
separately with whoever owns the SIS interface if it matters.

## Shipping: PASTE ONLY

Code lives inside a CMOD customer-exit include; CMOD project activation is manual.
Not zippable.

## Before activating

Confirm the text ID (SE75 → VBBK). Everything else in ISSUES.md "Open questions" is
either closed or a business confirmation that does not change the code.

"Item text" in the ticket = `BSEG-SGTXT`. FI-direct documents show it because the user
types it in FB70/FB75; SD documents leave it blank. The two document types then look the
same in the app, which is the stated expected result.

## Test plan (draft)

0. Pick a sales order that actually has a Header Note 1 — the VA02 text list shows a
   language in the `Lang.` column only when a text is maintained (PLX6000001 had none).
1. VF01 on an order-related invoice from that SO → FB03 customer line `SGTXT` = the note
   (first 50 chars); F0711 shows it.
2. Same, SO without Header Note 1 → `SGTXT` unchanged (blank or whatever it was).
3. Collective invoice from two SOs → text of the first-created SO (`VBAK-ERDAT/ERZET`),
   not the lowest number — build the test with the newer SO having the lower number.
4. VF02 → release to accounting of a doc saved with posting block → text present
   (fallback path).
5. VF11 cancellation → cancellation doc's customer line also carries the text.
6. Regression: G/L and tax lines of the same document unchanged; a non-SD posting
   (FB70) unaffected.

## Gotchas

- Forward-only. Invoices already posted keep their blank `SGTXT`. A backlog fix is a
  separate one-time program (SGTXT is changeable in FB02 if OB32 allows it) — a
  decision for Gaurav sir, not part of this ticket unless asked.
- Installment payment terms produce several customer lines; each passes through the exit
  and each gets the same text. Fine, but say so.
- The exit runs inside the billing save. No dialog messages, no `MESSAGE` type E/A —
  anything that fails must just leave `SGTXT` alone.
- Long text lines: `TLINE-TDLINE` is 132 chars; with `TDFORMAT` `*` / `/` the note may be
  several rows. 50-char truncation will cut it — tell business up front.
