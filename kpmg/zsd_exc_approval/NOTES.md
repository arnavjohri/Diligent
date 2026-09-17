# WRICEF 141 A/B — Exceptional Approval (Astral / project UDAY, SD)

FS documents supplied 02/09/26, both dated 24.08.2026, prepared by Sanjay Modhvadiya.
Source files: `fs/141A_..._Adhesives.docx`, `fs/141B_..._Paints.docx`.

## Scope as written

**141.A Adhesives** — report only. Data already lives in BP credit-management
"Additional Information" (BP → Further Information → Information Category →
Additional Information), table **BP3100**. No mass upload in scope (explicitly out of scope).

**141.B Paints** — three objects:
1. Custom table `ZSD_EXP_PAINTS` + table maintenance generator
2. Upload / change program for mass data entry
3. Report reading `ZSD_EXP_PAINTS`

Both reports share the same shape: selection screen → ALV with customer block,
approval block and actual-vs-commitment block.

## Open questions blocking build

See `ISSUES.md` for the numbered list raised 02/09/26 and extended 05/09/26. The hard
blocker is the L4/L5/L6 name source — the FS names `SAPLSLVC_FULLSCREEN`, which is the
generic ALV full-screen function group, not a data source and not SUBMIT-able.

## Where each object stands (05/09/26)

| Object | Repo copy | System | Next step |
|---|---|---|---|
| `ZSD_EXC_APPR_ADHESIVE` (141.A) | corrected 05/09/26: BP3100 filter on INFOTYPE only, GT_APPR sorted, positional commitment-date link, BSID/BSAD read for approval partners only, optional Division, sturdier date parse | **active** since 02/09/26 with Arnav's hand fix of the BP3100 WHERE clause — that clause was never sent back | `ZR_PROG_DOWNLOAD` the active version, diff against the repo copy, then paste the reconciled repo copy (ISSUES.md #17) |
| `ZSD_EXP_PAINTS` + 5 domains + 6 data elements | `src/` XML rebuilt 05/09/26 | not yet created | ZIP first (`ABAPGIT_UPLOAD_STEPS.md`); `ZSD_EXP_PAINTS_DDIC.md` by hand if the ZIP dumps |
| TMG on `ZSD_EXP_PAINTS` | build sheet only | not yet | SE11 by hand after the table is active |
| `ZSD_EXP_PAINTS_UPLOAD` | corrected 17/09/26: no ROLLBACK after COMMIT WORK AND WAIT (summary warns instead, text symbol M06), amounts with a third decimal rejected, amount length check counts the decimal point | not yet pasted | ZIP or paste after the table is active |
| `ZSD_EXC_APPR_PAINTS` | ACDOCA read driven by approval partners since 05/09/26 | not yet pasted | ZIP or paste after the table is active |

## Delivery

Table + data elements are ZIP-able. TMG (SE11 maintenance generator), any number
range (SNRO) and the authorisation object are manual. Reports are ZIP-able only if
they stay screen-free — use `REUSE_ALV_GRID_DISPLAY_LVC` full-screen, no custom
container, no `CALL SCREEN`.

`ZSD_EXC_APPROVAL.zip` (18 files) carries everything for 141.B except the TMG and the
two foreign keys. It was rebuilt 05/09/26 after an element-by-element check of the
abapGit XML — `ZIP_IMPORT_NOTES.md` lists the six defects that were fixed and the root
cause found for the `zfi_tds_cl34` import dumps. It has not been tried since the rebuild.
141.A is deliberately not in it (ISSUES.md #17).
