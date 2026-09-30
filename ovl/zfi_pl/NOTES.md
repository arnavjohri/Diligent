# ZFI_PL — Profitability statement, Per Barrel analysis, Other reports

**Project:** OVL (ONGC Videsh) · system OCP (RISE Production) · package ZFI_OTH
**Object:** module pool `SAPFZFIPL` (tcode ZFI_PL). Includes MZFIPLTOP, MZFIPLO01,
MZFIPLI01, MZFIPLF01. Author Hrishikesh Nikam, go-live 17.03.2023; later edits by
Sandeep R (18.01.2024) and Aparna (02/07/08.2024).

## Shipping method
**Paste-only** — module pool with SE51 screens and SE41 status. No `src/`, no `.abapgit.xml`.

## What is in `original/`
`SAPFZFIPL_SE38_print_2026-09-27.TXT` is an SE38 print (page headers, wrapped lines,
`27.09.26 OCP` banners), not a raw SE80 download. It contains only the main program
and `MZFIPLF01`. **TOP, O01 and I01 are not in it** — `it_setgls`, screen fields and
globals are declared elsewhere. Ask for the full tree via `ZR_PROG_DOWNLOAD` before any
edit that touches declarations.

## How the numbers are built (the part that matters)
- Data source is **JVSO1** (JV line items), ledger `4A`, `rbukrs = p_comp1`,
  `ryear`, `poper BETWEEN s_period_low/high`, `rjvnam IN p_proj1`.
- The G/L filter is `FOR ALL ENTRIES IN @it_gls ... AND racct = @it_gls-gl_acct`
  where `it_gls` is `SELECT * FROM zfi_pnl_gl` (the whole mapping table, no
  company-code or year key). Then `zfi_pnl_gl` is re-read for the accounts actually
  posted (`it_gls1..4`) and amounts are summed per mapping row into the report line
  `prd_pro` (producing) / `oth_pro` (non-producing), divided by 1,000,000.
- **The report never shows a G/L number.** A G/L influences the output only if it has a
  row in `ZFI_PNL_GL`; an unmapped account is never selected from JVSO1 at all.
- `ZFI_PNL_GL` and `ZFI_PNL_PROJ` are maintained from the program's own menu via
  `VIEW_MAINTENANCE_CALL` (FORMs `gl_maintain`, `projlist_maintain`) — that is the
  "GL Maintenance" screen users refer to.

## Hardcodes worth knowing
- VAT G/L `0000200668` and condensate G/L `0000230116`; material codes
  `722000001` (oil), `722000003` (condensate), `722000004` (gas).
- `IF p_year1 LT '2025'` gates the VAT split (comment still says "before 2023").
- `BREAK abapuser02.` left in `cre_prd_proj` (harmless for other users, but should go).
- `SELECT SINGLE SUM(ksl)` on JVSO1 inside `LOOP AT lt_data` for "OTHER TAXES" rows.
