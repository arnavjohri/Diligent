# ISSUES — ZR_PROG_DOWNLOAD

| # | Date | Issue | Cause | Fix | TR | Status |
|---|---|---|---|---|---|---|
| 1 | 19/10/26 | Program source needed again (not in the target system, not in the repo); DDL sources of `ovl/zmm_purchdoc_cds_ext` cannot be pulled without it | The Aug 2026 version was never filed in git (CLAUDE.md §2.3 — M-20) | Rewritten: `ZR_PROG_DOWNLOAD.abap` (766 lines), same listing layout, DDLS added. Not yet activated | `<TR>` | **Superseded 19/10/26** — the live program exists (selection screen filed under `original/`); only DDLS support is missing. Rewrite kept as reference |
| 2 | 19/10/26 | Live `ZR_PROG_DOWNLOAD` has no CDS DDL source object type; 26 DDLS of `ovl/zmm_purchdoc_cds_ext` cannot be pulled with it | Written before CDS work started | Add `S_DDLS` + package checkbox + `DDDDLSRC` read + `.ddls.asddls` writer into the live source (`add_ddl_source` FORM in the rewrite is the piece). Needs the live source first: program downloads itself | `<TR>` | **Open — awaiting self-download of the live program** |
