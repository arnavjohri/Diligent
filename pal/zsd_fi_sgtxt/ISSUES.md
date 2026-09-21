# Issues — ZSD_FI_SGTXT

Running log: issue → cause → fix → TR → date. Newest last.

Object: customer exit `EXIT_SAPLV60B_002` (enhancement `SDVFX002`, include `ZXVVFU02`) —
object names to be confirmed once the CMOD state at PAL is known.
PAL (Philippine Airlines) — SD-FI | Fiori Manage Customer Line Items (F0711)
Ticket: INC01740 | Lead: Gaurav sir | Functional: Omprakash ji

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 21/09/26 | Customer line of SD billing documents shows no text in Manage Customer Line Items; SOA shows the SO Header Note 1 | SD-FI interface leaves `ACCIT-SGTXT` blank on the customer line, so `BSEG`/`ACDOCA-SGTXT` are blank and the app has nothing to show | Proposed: fill `xaccit-sgtxt` in `EXIT_SAPLV60B_002` from the first sales order's Header Note 1 via `READ_TEXT` (`VBBK`). Ticket text received 21/09/26: item text = `SGTXT`, source = Header Note 1 of the first-created SO. Text ID and CMOD state still open. See NOTES.md | — |

## Open questions (to close with Gaurav sir / Omprakash ji before coding)

1. **Text ID** of "Header Note 1" at PAL (VOTXN, or the SOA form's `READ_TEXT` call).
   SAP default `0002`, unconfirmed. Language: SO language or fixed EN?
2. ~~Multiple sales orders in one invoice~~ — **closed 21/09/26 by the ticket text**:
   first-created SO (`VBAK-ERDAT`, `ERZET`; `VBELN` as tie-break).
3. **Truncation** — `SGTXT` is 50 chars. First 50 of the concatenated note acceptable?
4. **Overwrite rule** — if `SGTXT` is already filled by something else, keep or replace?
   Recommend keep (assign only when blank and a note exists).
5. **Scope** — all billing types and company codes, or restricted (e.g. no intercompany)?
6. **Backlog** — already-posted invoices stay blank. Forward-only, or a one-time mass
   change program as a separate item?
7. **System state** — is `SDVFX002` already in an active CMOD project? If yes, need a
   fresh download of `ZXVVFU02` and the project name before touching it.
