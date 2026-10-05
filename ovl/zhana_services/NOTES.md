# ZHANA_SERVICES_PRG — SAP Timesheet (OVL)

Module pool, package `ZFI_OTH`, title "SAP Timesheet". Consultants book days per
consultant / module / date (table control `TIMESHEET` on screen 9002 → `ZSAP_TIMESHEET`),
then a 4-level approval: SAP PM → Core Team → OVL PM → Head IT (`ZAPPROVERS`), with
BCS mails (`ZTIMESHEET_MAIL`, class `LCL_AST_MAIL`).

**Ships by paste only** (module pool, SE51 screens, SE41 status).

## Objects
- Main `ZHANA_SERVICES_PRG` + includes `_STATUS_9O01/9O02/9O03`, `_GET_*` (F4 modules),
  `_MAILF01` (FORMs), `ZTIMESHEET_MAIL`.
- Screens 9001 (menu), 9002 (table control), 9009 (doc no entry). Status 9002 is used by
  **both** 9002 and 9009. Titlebar 9001.
- Tables: `ZSAP_TIMESHEET`, `ZRESOURCE_MAPPIN`, `ZSTAGES`, `ZAPPROVERS`, `ZSERVICE_ELEMENT`.
- Number range object `ZTIMESHEET`, interval 01. Auth object `ZSAP_TIME` (ACTVT 01/02/03).

## Not in the repo (never supplied)
Screen flow logic / element lists (SE51), GUI status (SE41), DDIC definitions.

## Gotchas
- `original/` holds the SE80 print (`*_SE80_PRINT.txt`) and includes extracted from it.
  The print wraps at 72 columns; the extraction rejoins wrapped lines (a dropped space at
  the wrap point is restored).
- Several existing lines are > 120 chars. **Paste only the marked blocks** into 9O02 / 9O03,
  not the whole include — a whole-include paste will wrap those lines.
- Dates from `.xlsx` cells arrive as Excel serial numbers (base 30.12.1899).
