# ZSD_FI_SGTXT — NOTES

## What it is

PAL (Philippine Airlines) | SD-FI | Ticket INC01740.
Fiori app **Manage Customer Line Items** (F0711) shows no text on the customer line of SD
billing documents. Business wants the sales order **Header Note 1** on the customer
(A/R) line, so it appears in the app the way it already does on the Statement of Account.

`BSEG-SGTXT` / `ACDOCA-SGTXT` on the customer line are both filled from `ACCIT-SGTXT` by
the SD-FI interface, so the fix is to fill `SGTXT` at posting time. Nothing in the Fiori
app or its CDS needs touching.

Object names are **not yet fixed** — see "Where the code goes". Folder is named after the
function; rename once the include/project is known.

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

**First check on the system:** whether `SDVFX002` is already active in a CMOD project at
PAL (CMOD → Utilities → project list by enhancement, or SE37 `EXIT_SAPLV60B_002` →
double-click `INCLUDE ZXVVFU02`). If the include exists, this is an insert into someone
else's code — fresh download of `ZXVVFU02` first, BOC/EOC markers, drift check. If not,
a new CMOD project (name TBD, e.g. `ZSDFI001`) with `SDVFX002` only.

## How the text is found

1. **Sales order(s) behind the billing document.** `VBRP-AUBEL` per item. At VF01/VF04
   time `VBRP` is **not yet in the database** (billing doc and accounting doc are saved in
   one LUW), so the exit cannot `SELECT` from `VBRP`. Read the in-memory item table of the
   billing program instead: `ASSIGN ('(SAPLV60A)XVBRP[]') TO <fs>`. Fall back to a
   `SELECT` on `VBRP` only if the assign fails (VF02 / VFX3 release-to-accounting of an
   already-saved document). Confirm the exit's own signature in SE37 first — if it already
   hands over the items, no assign is needed. **Do not guess the signature.**
2. **Which sales order when there are several.** Ticket says "by creation date/time or
   document number". Recommend: lowest `AUBEL` (document number order = creation order in
   practice, no extra `VBAK` read). Confirm with Omprakash ji.
3. **The text.** `READ_TEXT` — never read `STXL` directly, it is a compressed cluster.
   `OBJECT = 'VBBK'`, `NAME = <sales order>`, `ID = <Header Note 1 text ID>`,
   `LANGUAGE = vbrk-spras` (fall back to `sy-langu`, then `'E'`), `EXCEPTIONS OTHERS`.
   The text ID for "Header Note 1" is **not confirmed** — SAP-delivered is normally
   `0002` (`0001` = Form header) but PAL may use a Z ID or a text procedure of its own.
   Get it from VOTXN or from whichever form/program prints the SOA — the SOA already
   shows this text, so reuse its object/ID/language and the two views will match.
4. **Into SGTXT.** `SGTXT` is CHAR 50. Concatenate the `TLINE` rows with a space and
   take the first 50 characters. Only assign when a text was found — never blank out a
   value already in `xaccit-sgtxt`.

Reading the *billing document's own* header text (if config copied the SO note into it)
is **not** an option here: at VF01 the billing texts are not in `STXH` yet either.

## Shipping: PASTE ONLY

Code lives inside a CMOD customer-exit include; CMOD project activation is manual.
Not zippable.

## Scope / behaviour to confirm before writing code

See ISSUES.md "Open questions". None of the code should be written until the text ID and
the multi-SO rule are answered — both change the code and cost an activation cycle each.

## Test plan (draft)

1. VF01 on an order-related invoice from one SO with a Header Note 1 → FB03 customer
   line `SGTXT` = the note (first 50 chars); F0711 shows it.
2. Same, SO without Header Note 1 → `SGTXT` unchanged (blank or whatever it was).
3. Collective invoice from two SOs → text of the lowest SO number (or the agreed rule).
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
