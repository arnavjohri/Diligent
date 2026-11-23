# ovl/zfi_sub_loan_sched - issue log

| Date | Issue | Cause / decision | Files | Commit | TR |
|---|---|---|---|---|---|
| 20/11/26 | Requirement workbook received: can it be a Custom Analytical Query, and the data source | Feasible with a custom cube; 11 queries to functional and object list raised, no code yet | `NOTES.md`, `FSD/ZFI_SLDI_Assumptions_and_Queries.*` | | |
| 20/11/26 | Build everything on the assumptions, ship by abapGit | 14 objects written, two-stage ZIP; nothing activated yet | `src/*`, `ZFI_SLDI_*.zip`, `ZFI_SLDI_load.txt` | | |
| 20/11/26 | DDIC-only ZIP wanted for abapGit standalone | `ZFI_SLDI_DDIC.zip`: 2 DOMA, 7 DTEL, 2 TABL from `src/` | `ZFI_SLDI_DDIC.zip` | | |
| 23/11/26 | Arnav: build everything in OCD and publish (Claude via desktop control) | DDIC by ADT wizards, not abapGit (JIB offline repo on `ZFI_OTH` would offer its views for deletion); TF, class, cube by ADT paste; SE54 FG `ZFI_SLDI`; SM30 entries; C1 release; 3 queries published | all of `src/`, `ZFI_SLDI_load.txt`, `NOTES.md` | | OCDK920552 |
| 23/11/26 | ACDOCA checks before loading words (SQL console, read-only) | Trading partner unusable on 91905/391908 (OVL/IMPL/blank); words replaced by real texts: LOAN TO OVSL / LOAN TO IEL / BREML / P. SHARE / NO OF SHARES. 100115 history exists as line items 2006-2015, balance 31,403,156.30 | `ZFI_SLDI_load.txt` | | (client data) |
| 23/11/26 | CAQ: "The use of Data Element DATUM is not permitted" on the cube | Parameters retyped `VDM_V_KEY_DATE` (as bank reval) | `src/zi_sldi_cube.ddls.asddls` | | OCDK920552 |
| 23/11/26 | CAQ: "SCHEDULE is a reserved word (choose another field name)" | Element renamed `ScheduleType`; activation first failed (field used by the draft query's view) - draft deleted, cube activated, query rebuilt | `src/zi_sldi_cube.ddls.asddls` | | OCDK920552 |
