# ZSAP_CONSUMPTION_REPORT — Consumption Report (OVL)

Report behind tcode `ZCON` (button `CON` on screen 9001 of `ZHANA_SERVICES_PRG`). Per Service
Element: scope days from `ZSERVICE_ELEMENT` (AS_IS_SCOPE_DAY, ADDITIONAL_SCOPE_DAYS,
DAILY_RATE_GST) against Head-IT-approved days in `ZSAP_TIMESHEET`, by Scope 'AS IS' /
'ADDITIONAL'. ALV via REUSE_ALV_GRID_DISPLAY. Include `ZSAP_CONSUMPTION_REPORT_GETF01` = F4 only
(not in repo, unchanged). Ships by paste.

## Gotchas
- Only Scope values 'AS IS' and 'ADDITIONAL' are counted. Any other domain value (e.g.
  MICROSOFT) is silently left out of every column.
