# TS — ZFI_ACDOCA_JVSO1_RECON (no FSD; chat requirement 19/10/2026)

## 1. Document control

| Item | Value |
|---|---|
| Version | 1.0 |
| Author | Arnav Johri, Diligent Global |
| Date | 19.10.2026 |
| Project / system | OVL · OCQ/500 |
| Related FS | None — requirement received in chat, 19/10/2026 |
| Transport | TBD |

## 2. Purpose / background

Before the JVA-on-ACDOCA cut-over, FI postings exist twice: in the universal journal
(ACDOCA, ledger 0L) and in the JV ledger line items (JVSO1, ledger 4A). This report totals both
sides for the same FI documents — those whose ACDOCA creation time stamp is before a cut-off
date (default 27.09.2026) — by company code, venture, equity group, G/L account, recovery
indicator, fiscal year and period, and shows the difference in local, group and transaction
currency so that the functional team can find where the two ledgers disagree.

## 3. Objects affected

| Object | Type | New / changed | Package | TR |
|---|---|---|---|---|
| ZFI_ACDOCA_JVSO1_RECON | Executable report (SE38, type 1, no includes) | New | TBD | TBD |
| Text elements of ZFI_ACDOCA_JVSO1_RECON | Text symbol B01, selection texts | New (manual, SE38 → Goto → Text elements) | — | same |

No DDIC, no screen, no GUI status, no table maintenance.

## 4. Detailed changes

Source: `ovl/zfi_acdoca_jvso1_recon/ZFI_ACDOCA_JVSO1_RECON.abap` (384 lines).

### 4.1 Selection screen (block B01 "Selection")

| Field | Type | Text | Note |
|---|---|---|---|
| S_BUKRS | select-option on ACDOCA-RBUKRS | Company Code | obligatory |
| S_GJAHR | select-option on ACDOCA-GJAHR | Fiscal Year | obligatory |
| S_POPER | select-option on ACDOCA-POPER | Posting Period | optional, applied to ACDOCA and JVSO1 |
| P_CUTDT | parameter, date | Created before (ACDOCA time stamp) | obligatory, default 27.09.2026 |

### 4.2 FORM read_acdoca
Anchor: `CONVERT DATE p_cutdt TIME lv_midnight`.
Converts the cut-off date at 00:00:00 UTC into a `TIMESTAMPL`. Two SELECTs on ACDOCA,
both with `rldnr = '0L'`, the three select-options and `timestamp < cut-off`:
1. `GROUP BY rbukrs, gjahr, poper, vname, egrup, racct, recid` with `SUM( hsl )`, `SUM( ksl )`,
   `SUM( wsl )` into `gt_acd_sum`.
2. `SELECT DISTINCT rbukrs, gjahr, belnr` into `gt_docs` — the FI document keys handed to JVSO1.
Empty result → caller issues *No ACDOCA line items (ledger 0L) before the cut-off for this
selection* (type S, displayed as W) and stops.

### 4.3 FORM read_jvso1
Anchor: `FOR ALL ENTRIES IN @gt_docs`.
Guarded by `IF gt_docs IS NOT INITIAL`. Reads JVSO1 with `rldnr = '4A'`, `rrcty = '0'`,
`rvers = '001'`, `rbukrs = gt_docs-rbukrs`, `ryear = gt_docs-gjahr`,
`reffidoc = gt_docs-belnr`, `poper IN s_poper`. Field list carries `docnr` and `docln` so
FOR ALL ENTRIES cannot drop identical lines. Amount fields: `hsl`, `ksl`, `tsl`.

### 4.4 FORM build_output / FORM get_sum_row
Anchor: `LOOP AT gt_acd_sum ASSIGNING FIELD-SYMBOL(<ls_acd>)`.
Both sides are added into `gt_sum` (sorted, unique key RBUKRS GJAHR POPER VNAME EGRUP RACCT
RECID) via `get_sum_row`, which returns a reference to the row and creates it with zero
amounts when absent. JVSO1 fields are mapped RBUKRS→RBUKRS, RYEAR→GJAHR, POPER→POPER,
RJVNAM→VNAME, REGROU→EGRUP, RACCT→RACCT, RRECIN→RECID, TSL→WSL column. Then per row:
`*_diff = *_acd − *_jv`, `diff = 'X'` when any of the three is non-zero. `gt_out` is the
standard-table copy for the ALV. Status message: rows and rows with differences; when no
JVSO1 line was found the message says so (displayed as W) and the list is still shown.

### 4.5 FORM display_alv / FORM set_col_text
Anchor: `cl_salv_table=>factory(`.
Full-screen `CL_SALV_TABLE`, all functions, optimised columns, striped pattern, list header
*ACDOCA 0L vs JVSO1 4A - lines created before <date>*. Amount columns get short/medium/long
headings in code (ACDOCA / JVSO1 / Difference × Local / Group / Trans.); key columns keep
their DDIC headings.

### 4.6 Output columns

| Column | Content |
|---|---|
| Company Code, Fiscal Year, Period, Joint Venture, Equity Group, Account, Recovery Indicator | grouping key |
| ACDOCA Local Amt / JVSO1 Local Amt / Difference Local | HSL both sides, ACDOCA − JVSO1 |
| ACDOCA Group Amt / JVSO1 Group Amt / Difference Group | KSL both sides, ACDOCA − JVSO1 |
| ACDOCA Trans. Amt / JVSO1 Trans. Amt / Difference Trans. | ACDOCA WSL vs JVSO1 TSL, ACDOCA − JVSO1 |
| Difference exists | X when any difference ≠ 0 — filter on it to see only mismatches |

## 5. Requirement mapping

| Requirement (as received) | Implemented by |
|---|---|
| Selection screen: company code, fiscal year, period as select-options | §4.1 S_BUKRS, S_GJAHR, S_POPER |
| ACDOCA entries, ledger 0L | §4.2, constant `gc_rldnr_acd` |
| TIMESTAMP date part before 27/09/2026 | §4.1 P_CUTDT default 27.09.2026 + §4.2 `timestamp < @gv_ts_cut` |
| Pass primary keys to JVSO1, find the matching record | §4.2 `gt_docs` + §4.3 FAE on RBUKRS / RYEAR / REFFIDOC |
| JVSO1 ledger 4A, record type 0, version 1 | §4.3 constants `gc_rldnr_jv`, `gc_rrcty`, `gc_rvers` |
| Compare HSL, KSL, WSL and show the difference | §4.4 `*_diff` columns, §4.6 |
| Totals by venture, equity group, account, recovery indicator, year, period | §4.4 key of `gt_sum` (plus company code — Query 5) |

## 6. Test scenarios

| # | Input | Expected | Actual |
|---|---|---|---|
| 1 | Company code with JVA, FY 2026, period 1, default cut-off | One row per venture/EG/account/RI; HSL/KSL equal on both sides for documents posted with JVA active, `Diff` blank | |
| 2 | Same, period of the 50-vs-13-line document from `rgjv_update_acc_data_in_acdoca` ISSUES (19/10/26) | Totals per venture still agree if JVA split the offset line correctly; a difference row shows the venture/account where they do not | |
| 3 | Company code without JVA (no JVSO1 lines) | List shown, all JVSO1 columns zero, every row `Diff = X`, status message says no JVSO1 line found | |
| 4 | Cut-off date earlier than the first posting of the year | *No ACDOCA line items ... before the cut-off* warning, no list | |
| 5 | Cut-off 27.09.2026 vs 28.09.2026, same period | Second run includes the 27.09 postings; the delta equals those documents' totals | |
| 6 | Period range 1–12 for a large company code, background | Completes; row count in the spool status line | |

## 7. Open points
See `ASSUMPTIONS_AND_QUERIES.md` — items 1 (REFFIDOC vs DOCNR), 4 (time zone), 6 (mixed
transaction currencies), 8 (period filter on JVSO1), 9 (authorisation), 10 (ledger 4C) change
behaviour if answered differently; the rest are confirmations.
