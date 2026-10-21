# ZFI_ACDOCA_JVSO1_RECON — Assumptions and Queries

Project OVL · requirement received in chat on 19/10/2026 · prepared 19/10/2026 · updated 21/10/2026

Requirement as received: *selection screen with company code, fiscal year and period as
select-options; fetch ACDOCA entries (ledger 0L, TIMESTAMP date part before 27/09/2026); pass
their primary keys to JVSO1 (ledger 4A, record type 0, version 1) and find the matching
record; compare HSL, KSL, WSL and show the difference; totals on venture, equity group,
account, recovery indicator, year and period.*
Update 21/10/2026: **WSL is dropped** — a key can hold rows in several transaction
currencies. Only HSL and KSL are compared.

Each item: the question, where it comes from, what the delivered code assumes if no answer
arrives, and what breaks if that assumption is wrong.

| # | Question | From | Assumed in the code | If wrong |
|---|---|---|---|---|
| 1 | Which JVSO1 field is the "primary key" link to ACDOCA — `REFFIDOC` (FI document reference) or `DOCNR` (JV document number)? | "passing those primary keys to jvso1 and finding a matching record" | `JVSO1-RBUKRS = ACDOCA-RBUKRS`, `RYEAR = GJAHR`, `REFFIDOC = BELNR`. This is the join SAP's `CL_JVA_MIG_CORRECT_ACDOCA` uses for FI documents. | If `DOCNR` was meant: change `reffidoc` to `docnr` in the one WHERE line of `FORM read_jvso1`. If JV lines exist that reference only a CO document (`REFDOCNR`), they are not matched and the JVSO1 side is understated. |
| 2 | ~~ACDOCA `WSL` vs JVSO1 `TSL` as the transaction-currency pair?~~ | "compare the hsl, ksl, wsl" | **Closed 21/10/2026** — transaction currency removed from the report. | — |
| 3 | Is 27.09.2026 a fixed rule or the current cut-over date? | "timestamp ... less than 27/9/2026" | Selection parameter **Created before**, default 27.09.2026, obligatory. Default behaviour is identical to a literal. | If it must be a literal (no user change allowed), replace the parameter with a constant — two lines. |
| 4 | Time zone of the cut-off: compare the raw UTC digits of `ACDOCA-TIMESTAMP`, or "created before 27.09.2026 IST"? | "the first few fields [of TIMESTAMP] less than 27/9/2026" | Raw UTC digits, exactly as described. | Lines created 00:00–05:30 IST on 27.09.2026 carry a 26.09 UTC stamp and are **included**. If IST was meant, convert with `TIME ZONE 'INDIA'` (or `sy-zonlo`) instead of `'UTC'` — one line. |
| 5 | Should company code be part of the grouping? The six keys named did not include it. | "totaled on the basis of jvnam, gegroup, racct, recin, year, poper" | Company code added as the first key — needed to read a run across several company codes. A venture belongs to one company code, so the totals are the same. | If not wanted, remove `rbukrs` from `ty_out_key` and the sorted-table key. |
| 6 | ~~Transaction-currency totals summed across currencies inside one key?~~ | — | **Closed 21/10/2026** — this is why WSL was dropped. | — |
| 7 | Scope of ACDOCA lines: all ledger 0L lines of the company code / year / period, or only JVA-relevant lines (venture filled)? | "acdoca entries to be fetched" | All lines. Lines without a venture appear with blank venture and no JVSO1 counterpart, i.e. as a difference. | If only JVA lines are wanted, add `AND vname <> @space` to both ACDOCA SELECTs. |
| 8 | Period filter on JVSO1: applied to `JVSO1-POPER` as well as to `ACDOCA-POPER`? | "period select option" | Yes, both sides, so the populations match. | If a JV line can sit in a different period from its FI line, those lines drop out of the JVSO1 side. Remove `AND poper IN @s_poper` from `FORM read_jvso1` to let the document match alone decide. |
| 9 | Authorisation check (`F_BKPF_BUK`, activity 03, per company code)? | not stated | None — same decision as `ZFI_ACDOCA_VNAME_UPD` (16/10/26). | Restrict by SE38 authorisation group / role, or add the check in `AT SELECTION-SCREEN`. |
| 10 | Ledger `4C` (3rd/4th JV currency): read it too? | "ledger 4a" | Only `4A`. KSL (group currency) is carried in `4A`. | If group currency is in `4C` on this system, the JVSO1 KSL column is zero — widen the ledger filter to `4A`/`4C` as `ZOCV_OVL_TRANSFER` does. |
| 11 | Target system and release | not stated | OCQ/500, older S/4. Syntax kept at 7.40 level (no `+=`, no `FIELDS`, no `FINAL`). | None expected. |

Volume note (no question): ACDOCA totals are built on the database; JVSO1 lines are read at
line level (aggregates are not allowed with FOR ALL ENTRIES). A full year for a large company
code should run in background.
