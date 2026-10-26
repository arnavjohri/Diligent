# ZFI_PL — Profitability statement, Per Barrel analysis, Other reports

**Project:** OVL (ONGC Videsh) · dev OCD/500, production OCP (RISE) · package ZFI_OTH
**Object:** module pool `SAPFZFIPL` (tcode ZFI_PL). Includes MZFIPLTOP, MZFIPLO01,
MZFIPLI01, MZFIPLF01. Author Hrishikesh Nikam, go-live 17.03.2023; later edits by
Sandeep R (18.01.2024) and Aparna (02/07/08.2024).

## Shipping method
**Paste-only** — module pool with SE51 screens and SE41 status. No `src/`, no `.abapgit.xml`.
Corrected include at the folder root: `ovl/zfi_pl/MZFIPLF01.abap` (whole include, overwritten
by each fix; git history keeps earlier versions). Paste sheets `PATCH_*.abap` beside it.

## What is in `original/`
- `SAPFZFIPL_ZR_PROG_DOWNLOAD_2026-10-26.txt` — full tree from `ZR_PROG_DOWNLOAD`, OCD/500,
  user SAP_ABAP, 26.10.2026 14:26. Main program + all four includes, line-numbered.
- `SAPFZFIPL.abap`, `MZFIPLTOP.abap`, `MZFIPLO01.abap`, `MZFIPLI01.abap`, `MZFIPLF01.abap` —
  the same download with the line-number prefix stripped (61 / 919 / 865 / 1737 / 15384
  lines). This is the baseline every later download is diffed against.
- `SAPFZFIPL_SE38_print_2026-09-27.TXT` — older SE38 print (OCP), main program + the first
  7933 lines of MZFIPLF01 only, lines cut at the print width. Diffed against the 26.10.26
  download on 26/10/26: no code drift; the 27/09/26 SECC patch is present in the download.

## How the numbers are built (the part that matters)
- Data source **was JVSO1** (JV line items), ledger `4A`, `rbukrs = p_comp1`, `ryear`,
  `poper BETWEEN s_period_low/high`, `rjvnam IN p_proj1`. **From 26/10/26 the same SELECTs
  read SAP's view `JV_JVSO1_ACDOCA`** (SQL view `CJVSO1_ACD`, package JVA): a JVSO1-shaped
  projection of ACDOCA on the company code's JVA ledger (`I_JVALedger`), `rldnr` fixed to
  `'4A'`, `rjvnam` = `ACDOCA-VNAME`, `ksl` = the 4A second-currency amount. Field names are
  identical, so only the `FROM` changed — 24 sites, FORMs `cre_prd_proj` (20) and
  `cre_non_prd` (4). `TABLES jvso1` / `p_proj1 FOR jvso1-rjvnam` in MZFIPLTOP are typing
  only and stay.
- The G/L filter is `FOR ALL ENTRIES IN @it_gls ... AND racct = @it_gls-gl_acct`
  where `it_gls` is `SELECT * FROM zfi_pnl_gl` (the whole mapping table, no
  company-code or year key). Then `zfi_pnl_gl` is re-read for the accounts actually
  posted (`it_gls1..4`) and amounts are summed per mapping row into the report line
  `prd_pro` (producing) / `oth_pro` (non-producing), divided by 1,000,000.
- **The report never shows a G/L number.** A G/L influences the output only if it has a
  row in `ZFI_PNL_GL`; an unmapped account is never selected at all.
- `ZFI_PNL_GL` and `ZFI_PNL_PROJ` are maintained from the program's own menu via
  `VIEW_MAINTENANCE_CALL` (FORMs `gl_maintain`, `projlist_maintain`) — that is the
  "GL Maintenance" screen users refer to.

## Gotchas of the ACDOCA view (26/10/26)
- The view only returns a line when `ACDOCA-VNAME` is filled. Years whose ACDOCA lines were
  migrated without VNAME show zero for the project — see `ovl/zfi_acdoca_vname_upd/` and
  `ovl/zfi_acdoca_jvso1_recon/` for the tools that fix / prove that.
- The view excludes migrated JVSO1 lines (`mig_source = 'J'` with `belnr LIKE 'DJ%'`) and
  needs `T001-XJVAA = 'X'` for the company code.
- `WHERE rldnr = '4A'` is kept at every site: harmless (the view's `rldnr` is the literal
  `'4A'`) and the same shape `ZFI_JV_TB` runs with on the live system.

## Hardcodes worth knowing
- VAT G/L `0000200668` and condensate G/L `0000230116`; material codes
  `722000001` (oil), `722000003` (condensate), `722000004` (gas).
- `IF p_year1 LT '2025'` gates the VAT split (comment still says "before 2023").
- `BREAK abapuser02.` ×3 in MZFIPLF01 (lines 3370, 9013, 9348 of the 26.10.26 download).
- `SELECT SINGLE SUM(ksl)` inside `LOOP AT lt_data` for "OTHER TAXES" rows — pre-existing
  SELECT-in-LOOP (Sandeep R, 18.01.2024), untouched on 26/10/26.
- `SELECT * FROM zfi_pnl_gl ... FOR ALL ENTRIES IN @it_jvso1..4` has no `IS NOT INITIAL`
  guard. Pre-existing; untouched because an empty driver currently fills `it_gls1..4` with
  the whole mapping table and later code may rely on that.
