# FAGL_SETTINGS *_RESTRICT_MIG — migrated-data display in FAGLL03 / FAGLB03 / RFBILA00 / RFBELJ

**Project:** OVL (ONGC Videsh) · system OCQ client 500 · KBA 2891129
**Type:** SAP Notes + table entries. **No Z object.** Nothing to paste or zip.

## What the KBA is about
The FIN migration of the ECC→S/4 conversion wrote extra ACDOCA lines with
`MIG_SOURCE` A, C and R. They reconcile ACDOCA with asset accounting, CO and the old
GL totals; nobody posted them. FAGLL03, FAGLL03H, FAGLB03, RFBILA00, RFSSLD00 and the
RFBELJ journal reports read ACDOCA, so they show those lines and the figures stop
matching ECC. The notes add a `FAGL_SETTINGS` switch per program that restricts the
selection to originally posted items (`MIG_SOURCE` SPACE, F, G, E).

| Program(s) | Note | FAGL_SETTINGS parameter |
|---|---|---|
| FAGLL03 | 2697319 | `FAGLL03_RESTRICT_MIG` = X |
| FAGLL03H | 3170679 | `FAGLL03_RESTRICT_MIG` = X (same switch) |
| FAGLB03 | 2974898 | `FAGLB03_RESTRICT_MIG` = X |
| RFBILA00, RFSSLD00 | 2989318 | `RFSSLD_RESTRICT_MIG` = X |
| RFBELJ00, RFBELJ10, RFBELJ10_NACC | 3153442 | `RFBELJ_RESTRICT_MIG` = X |
| all of the above, `MIG_SOURCE` E | 3394830 | — |
| mixed signs in migrated CO-derived lines | 3647271 | `MIG_SOURCE_C_SIGN` = X |

Functional want FAGLL03 first; the rest follow only if they ask.

## How the notes land on OCQ
- OCQ has no outbound internet: SNOTE cannot download. Download note + prerequisites
  on a connected laptop from the SAP Support Portal, SNOTE → Goto → Upload SAP Note.
- SNOTE only. Never hand-apply correction instructions in SE38 (modification).
- Notes valid only for S4CORE 100–103 come back **"Cannot be implemented" / "Not Relevant"**
  on OCQ: the correction is already in the release. Not a failure, no TR.
  Confirm with System → Status (S4CORE release ≥ 104) or SE38 `FAGL_ACCOUNT_ITEMS_GL`,
  Find in main program for `RESTRICT_MIG`.
- Newer notes (3153442, 3170679, 3394830, 3647271) depend on the SP level — each still
  needs the upload to find out.

## Table entries
SM30 on `FAGL_SETTINGS`, client-specific (client 500). If SM30 asks for a request, use a
customizing TR so QA/PRD match; otherwise maintain per system. Set the four RESTRICT
switches together or none, else FAGLB03, FAGLL03, RFBILA00 and the journal disagree.

## Caveats to put in front of functional before QA
1. **Reversals.** A migrated document reversed after conversion is a new posting
   (`MIG_SOURCE` SPACE): the reversal stays visible, the original's migration lines are
   hidden, the account shows one side. KBA says live with it. Count the exposure:
   SE16H ACDOCA, `MIG_SOURCE` in A/C/R and `XREVERSED` = X, grouped by RACCT / RBUKRS.
2. **Fiori and Z reports ignore the switch.** Only the named standard programs read
   `FAGL_SETTINGS`. Fiori trial balance / line item apps and our ACDOCA readers
   (`ovl/zfi_jv_tb` via `JV_JVTO1_ACDOCA_SWITCH_2`, `ovl/atc/corrections/ZFCLEAR.abap`)
   keep showing A/C/R lines → FAGLB03 and Fiori can differ on the same account.
   Nothing built; decision after functional pick the "correct" view.
3. **Other MIG_SOURCE values on OVL.** `ovl/rgjv_update_acc_data_in_acdoca/NOTES.md`
   shows the JVA tool handling `MIG_SOURCE` J (JVA-on-ACDOCA migration) and S/T/U/V.
   The KBA keeps only SPACE/F/G/E. Before trusting the switch, get the real
   distribution: SE16H ACDOCA grouped by `MIG_SOURCE` and `RLDNR`, OVL company code.

## Test plan (DEV)
1. SE16H ACDOCA, `MIG_SOURCE` in A/C/R, group by RACCT/RBUKRS → pick one asset
   reconciliation account and one P&L account.
2. FAGLL03 on each, migration fiscal year, before and after the entry; save both totals.
   Difference must equal the sum of that account's A/C/R lines.
3. Tell functional FAGLB03 will now disagree with FAGLL03 on those accounts until
   2974898 / `FAGLB03_RESTRICT_MIG` follow.

## Status
See ISSUES.md. Original mail was cut off at "When the parameters FAGLB03_RESTRICT_MIG
and FAGLL03_RESTRICT_MIG are set to X," — remainder still awaited.
