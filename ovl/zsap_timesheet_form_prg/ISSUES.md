# ZSAP_TIMESHEET_FORM_PRG — issue log

## 06/10/26 — CR: Scope dropdown on the print selection screen
- **Ask:** dropdown on Timesheet Print, AS IS / MICROSOFT, print the matching records.
- **Fix:** `P_SCOPE AS LISTBOX` (blank = all) filled in `AT SELECTION-SCREEN OUTPUT`;
  `DELETE lt_data WHERE scope <> p_scope` before the per-document de-duplication; message
  when nothing is left instead of a blank run.
- **Manual:** selection text `P_SCOPE` = "Scope".
- **Open:** if `ZSAP_TIMESHEET_FORM` selects its own lines by DOC_NO, the line items are not
  filtered by Scope — needs the form's code.
- **Not touched (flagged):** date filters exclude the boundary dates (`<= p_from`, `=> p_to`).
- **Status:** awaiting activation / test. TR: —

## 06/10/26 — "Document No not found" on every single-row run (copy ZSAP_TIMESHEET_FORM_PRG_CP)
- **Cause:** `IF sy-subrc <> 0` after `DELETE ADJACENT DUPLICATES` — subrc 4 means nothing was
  deleted (no duplicate doc), so it fired with data present (seen in debugger: LT_DATA 1 row).
- **Fix:** check commented out; the `lt_data IS INITIAL` check added earlier covers "not found".
- Running copy is `ZSAP_TIMESHEET_FORM_PRG_CP` (tcode `ZSAPT_FORM1`); repo file holds its source.

## 06/10/26 — Scope = MICROSOFT still printed all 3 lines of doc 00005
- **Cause:** the program filters correctly (doc 00005 selected via its one MICROSOFT row), but
  Smart Form `ZSAP_TIMESHEET_FORM` re-reads every line of the document by DOC_NO.
- **Fix (program side, done):** `gs_timesheet-scope` cleared when `P_SCOPE` is blank, so
  `IS_TIMESHEET-SCOPE` carries the chosen Scope only — no form-interface change needed.
- **Fix (form side, pending):** add `AND scope = is_timesheet-scope` (when filled) to the form's
  SELECT on ZSAP_TIMESHEET. Needs the form's program-lines code.
