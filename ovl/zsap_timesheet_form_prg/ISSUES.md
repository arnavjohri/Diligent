# ZSAP_TIMESHEET_FORM_PRG — issue log

## 06/10/26 — CR: Scope dropdown on the print selection screen
- **Ask:** dropdown on Timesheet Print, AS IS / MICROSOFT, print the matching records.
- **Fix:** `P_SCOPE AS LISTBOX` (blank = all) filled in `AT SELECTION-SCREEN OUTPUT`;
  `DELETE lt_data WHERE scope <> p_scope` before the per-document de-duplication; message
  when nothing is left instead of a blank run.
- **Manual:** selection text `P_SCOPE` = "Scope".
- **Open:** if `ZSAP_TIMESHEET_FORM` selects its own lines by DOC_NO, the line items are not
  filtered by Scope — needs the form's code.
- **Not touched (flagged):** date filters exclude the boundary dates (`<= p_from`, `=> p_to`);
  `IF sy-subrc <> 0` after DELETE ADJACENT DUPLICATES never reports "not found".
- **Status:** awaiting activation / test. TR: —
