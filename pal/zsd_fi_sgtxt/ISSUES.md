# Issues — ZSD_FI_SGTXT

Running log: issue → cause → fix → TR → date. Newest last.

Object: include `ZXVVFU02` of customer exit `EXIT_SAPLV60B_002` (enhancement `SDVFX002`),
existing CMOD project at PAL (project name TBD). PASTE ONLY.
PAL (Philippine Airlines) — SD-FI | Fiori Manage Customer Line Items (F0711)
Ticket: INC01740 | Lead: Gaurav sir | Functional: Omprakash ji

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 21/09/26 | Customer line of SD billing documents shows no text in Manage Customer Line Items; SOA shows the SO Header Note 1 | SD-FI interface leaves `ACCIT-SGTXT` blank on the customer line, so `BSEG`/`ACDOCA-SGTXT` are blank and the app has nothing to show | Proposed: fill `xaccit-sgtxt` in `EXIT_SAPLV60B_002` from the first sales order's Header Note 1 via `READ_TEXT` (`VBBK`). Insert above the SIS `CHECK` in `ZXVVFU02`: distinct `CVBRP-AUBEL` → first-created SO by `VBAK-ERDAT/ERZET` → `READ_TEXT` `VBBK`/`0002` in `VBRK-SPRAS` (fallback: first language in `STXH`) → `xaccit-sgtxt` if still empty. `ZXVVFU02.abap`, 119 → 221 lines. Text ID 0002 confirmed in TTXIT 23/09/26. Delivered for paste 23/09/26 | `<TR>` |

## Open questions (to close with Gaurav sir / Omprakash ji before coding)

1. ~~Text ID~~ — **closed 23/09/26**: Header Note 1 = `0002`, checked in SE16 `TTXIT`.
2. ~~Multiple sales orders in one invoice~~ — **closed 21/09/26 by the ticket text**:
   first-created SO (`VBAK-ERDAT`, `ERZET`; `VBELN` as tie-break).
3. **Truncation** — `SGTXT` is 50 chars. First 50 of the concatenated note acceptable?
4. **Overwrite rule** — coded as keep: written only into an empty `SGTXT`. Say so to
   Omprakash ji; change is one line if they want replace.
5. **Scope** — all billing types and company codes, or restricted (e.g. no intercompany)?
6. **Backlog** — already-posted invoices stay blank. Forward-only, or a one-time mass
   change program as a separate item?
7. ~~System state~~ — **closed 21/09/26**: `ZXVVFU02` exists and is active (Nir Ben
   Ami, IATA SIS logic). Source supplied and filed as `original/ZXVVFU02.abap`. CMOD
   project name still to note for the TR.
