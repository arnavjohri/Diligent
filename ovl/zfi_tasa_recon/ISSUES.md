# ovl/zfi_tasa_recon - issue log

| Date | Issue | Cause / decision | Files | Commit | TR |
|---|---|---|---|---|---|
| 23/11/26 | Arnav: TASA Recon Statement FY26 v5 as a Fiori tile - can it be done with the info provided? | Feasible as custom cubes on ACDOCA + mapping table + CAQ (loan-schedule pattern, plain CDS). 10 open questions and 4 read-only OCD checks listed; nothing built | `NOTES.md`, `docs/TASA_Recon_Statement_AnnualFY26_v5.xlsx` | 1378208 | |
| 23/11/26 | Arnav: run the checks | OCD 500 SQL console: FY26 income, Q4 and 91111 balances equal to the cent; customer only via the document's customer line; FY23 / FY24 G/L now differ from the workbook (+1,702,867.97 / +100,000 USD); provision G/L 190790 has no customer | `NOTES.md` | | (read-only) |
