# ZFI_ACDOCA_JVSO1_RECON — ACDOCA (0L) vs JVSO1 (4A) reconciliation

**Project:** OVL (ONGC Videsh) · system OCQ/500 · package/TR: TBD
**Purpose:** show, per company code / venture / equity group / G/L account / recovery
indicator / fiscal year / period, the totals of ACDOCA ledger 0L against the JV ledger 4A
line items in JVSO1 for the same FI documents, with the difference in local (HSL) and group
(KSL) currency. Display only — nothing is written.

Requirement arrived in chat on 19/10/26 (no FSD). 21/10/26: transaction-currency comparison
(ACDOCA WSL vs JVSO1 TSL) **removed** on Arnav's instruction — one grouping key can hold
several transaction currencies, so that total is meaningless. Open questions are in
`ASSUMPTIONS_AND_QUERIES.md`; the TS is `TS_ZFI_ACDOCA_JVSO1_RECON.md`.

## Shipping method
Paste-only. SE38, type 1 executable, no includes, no screen, no GUI status.
Source: `ovl/zfi_acdoca_jvso1_recon/ZFI_ACDOCA_JVSO1_RECON.abap` (loose file, overwritten by
each fix; git history keeps earlier versions). No `original/` — new object, no SE80 baseline.

## Text elements to maintain (SE38 → Goto → Text elements)
Text symbol: `B01` Selection.
Selection texts: S_BUKRS Company Code · S_GJAHR Fiscal Year · S_POPER Posting Period ·
P_CUTDT Created before (ACDOCA time stamp).

## Behaviour
1. **ACDOCA** (ledger `0L`, company code / year / period from the screen,
   `TIMESTAMP < cut-off date 00:00:00 UTC`): one `GROUP BY` SELECT gives the HSL/KSL totals
   per grouping key on the database; a second `SELECT DISTINCT` gives the FI document keys
   (RBUKRS, GJAHR, BELNR) of the same lines.
2. **JVSO1** (`RLDNR 4A`, `RRCTY 0`, `RVERS 001`, period from the screen): `FOR ALL ENTRIES`
   on those document keys with `RBUKRS = RBUKRS`, `RYEAR = GJAHR`, **`REFFIDOC = BELNR`** —
   the FI-document join SAP's own `CL_JVA_MIG_CORRECT_ACDOCA` uses (see
   `ovl/rgjv_update_acc_data_in_acdoca/NOTES.md` §2). DOCNR/DOCLN are in the field list only
   so FAE cannot collapse two identical lines.
3. Both sides are added into one sorted table keyed RBUKRS, GJAHR, POPER, VNAME, EGRUP,
   RACCT, RECID (JVSO1: RBUKRS, RYEAR, POPER, RJVNAM, REGROU, RACCT, RRECIN). Difference =
   ACDOCA − JVSO1 for HSL and KSL; `Diff` = `X` when either differs.
4. `CL_SALV_TABLE` full-screen grid, headings set in code. Status message gives row count and
   number of rows with differences. No ACDOCA data → warning, no list. ACDOCA data but no
   JVSO1 lines → list is shown (JVSO1 columns zero) with a warning in the status line.

## Assumptions (grep `ASSUMPTION` in the source)
- Link is `JVSO1-REFFIDOC = ACDOCA-BELNR`, not `JVSO1-DOCNR`. CO-only JV lines (REFDOCNR)
  are not matched.
- Cut-off compares the raw UTC digits of `ACDOCA-TIMESTAMP`; no IST shift.
- 27.09.2026 is a parameter default, not a literal in the SELECT.
- Company code was added as the first grouping key (requirement listed six keys without it).

## Gotchas
- Transaction currency (WSL/TSL) is deliberately not read or shown — see 21/10/26 above.
- JVSO1 lines are read at line level (aggregate functions are not allowed with FAE). A full
  year over all periods for a large company code should run in background (F9).
- No authority check in the code (same decision as `ZFI_ACDOCA_VNAME_UPD`, 16/10/26).
- Ledger `4C` (3rd/4th JV currency) is not read; KSL comes from `4A`.
