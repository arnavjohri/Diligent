# ZSAP_TIMESHEET_FORM_PRG — Timesheet print (OVL)

Report behind tcode `ZSAPT_FORM` (the "Timesheet Print" button, fcode `FORM`, on screen 9001
of `ZHANA_SERVICES_PRG`). Selects Head-IT-approved rows of `ZSAP_TIMESHEET`, one Smart Form
call (`ZSAP_TIMESHEET_FORM`) per document, OTF merged and shown via `HR_IT_DISPLAY_WITH_PDF`.

Ships by paste (single report). Selection texts are maintained by hand (SE38 → Text elements).

## Gotchas
- The form gets `DOC_NO` + one row (`IS_TIMESHEET`). Whether the form re-reads all rows of the
  document itself is unknown (form not supplied) — the Scope filter here works at document level.
