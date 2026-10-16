# ZFI_ACDOCA_VNAME_UPD — fill ZZ1_VNAME on historical ACDOCA lines

**What it is.** One-off back-fill report. New postings get custom field `ZZ1_VNAME`
from Fiori substitution rule `SET_VNAME` (Journal Entry Item: copy Joint Venture).
Lines posted before the rule existed are empty; this report copies `ACDOCA-VNAME`
into `ACDOCA-ZZ1_VNAME` for one company code + fiscal year.

**How it ships.** Paste-only (SE38, type 1 report). Own workbench TR, imported
**after** the custom-field TR (OCDK920155 / its replacement) — the report references
the ZZ1 column and fails activation in QA if the field is not there yet.

## Behaviour
- Selection: company code, fiscal year (both mandatory), ledger (optional, blank = all),
  lines per commit (default 5000, max 10000), Test run (default ON).
- Only lines with `VNAME <> ' '` **and** `ZZ1_VNAME` empty or NULL are touched.
  A line that already has a value is never overwritten → safe to re-run.
- Package loop: SELECT up to N open lines → UPDATE each by full primary key
  (RLDNR, RBUKRS, GJAHR, BELNR, DOCLN) with the same guard → COMMIT → repeat.
  No cursor held across commits. The auditor's SELECT_IN_LOOP finding is this loop —
  intentional.
- Stops if a package updates nothing, or if packages exceed (start count / N) + 2.
- Stops before any update if ZZ1_VNAME is shorter than VNAME.
- Auth: F_BKPF_BUK, activity 03 (test) / 02 (update).
- ACDOCU is **not** updated — GR consultant re-runs the data release afterwards.

## Text elements to maintain (SE38 → Goto → Text elements)
Text symbols: `B01` Selection, `B02` Processing options.
Selection texts: P_BUKRS Company Code · P_GJAHR Fiscal Year · S_RLDNR Ledger ·
P_PACK Lines per commit (max 10000) · P_TEST Test run (no update).

## Assumptions (grep `ASSUMPTION`)
- ACDOCA column is `ZZ1_VNAME_COB` (confirmed by activation on DEV, 16/10/26).
- Blank ledger = all ledgers.
- Old rows may hold NULL in the appended column — covered by `IS NULL`.

## Run order
1. Test run per company code / year → note counts.
2. Update run (background, F9, for large volumes).
3. Re-run test: count should be 0.
4. GR re-releases the periods → check ACDOCU.
Direct table update of ACDOCA: get client/functional approval before PRD.
