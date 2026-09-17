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

See `ISSUES.md` for the numbered list raised 02/09/26 and extended since. The L4/L5/L6
source is `ZSD_CUSTOMER_DATA` (confirmed 07/09/26; the FS printed `SAPLSLVC_FULLSCREEN`,
the generic ALV function group). Its field names are still unconfirmed — resolved at
runtime since 17/09/26, `ISSUES.md` #26.

## Where each object stands (17/09/26)

| Object | Repo copy | System | Next step |
|---|---|---|---|
| `ZSD_EXC_APPR_ADHESIVE` (141.A) | 07/09/26 system state (ADDTYPE/DATA_TYPE, segment 2000, approval-type column removed, DD.MM.YYYY) **plus 17/09/26**: hierarchy field names resolved at runtime with diagnostics, approval customers passed to `ZSD_CUSTOMER_DATA`, GT_APPR sorted, positional commitment-date link, BSID/BSAD read for approval partners only, optional Division | **active** since 07/09/26 — in functional testing, L4/L5/L6 blank (ISSUES.md #26). Fresh download 17/09/26 filed in `original/`: **no drift** from the 07/09 base | paste the repo copy whole, add text symbols M13–M17 and selection text S_SPART; then send the status-bar text or a download of `ZSD_CUSTOMER_DATA` |
| `ZSD_EXP_PAINTS` + 5 domains + 6 data elements | `src/` XML rebuilt 05/09/26 | **active** since 07/09/26, created by hand | nothing — the ZIP is now a convenience for the two programs only |
| TMG on `ZSD_EXP_PAINTS` | build sheet only | not confirmed | check SM30 opens on the table; SE11 by hand if not |
| `ZSD_EXP_PAINTS_UPLOAD` | corrected 17/09/26: no ROLLBACK after COMMIT WORK AND WAIT (summary warns instead, text symbol M06), amounts with a third decimal rejected, amount length check counts the decimal point | **active** since 07/09/26 (07/09 version) | paste the repo copy, add M06 |
| `ZSD_EXC_APPR_PAINTS` | 17/09/26: same hierarchy fix as Adhesives (text symbol M11 new), ACDOCA read driven by approval partners | **active** since 07/09/26 (07/09 version) | paste the repo copy, add M07–M11 |

## Originals

`original/ZSD_EXC_APPR_ADHESIVE.TXT` is the SE38 print Arnav supplied on 17/09/26 (page
headers, line numbers, 72-column wrap, text-element and cross-reference appendix), kept
byte for byte. `original/ZSD_EXC_APPR_ADHESIVE.from-print.abap` is the same source with
the pagination and line numbers stripped and the wrapped lines rejoined, so it diffs
directly against the repo copy. Neither is edited.

## Delivery

Table + data elements are ZIP-able. TMG (SE11 maintenance generator), any number
range (SNRO) and the authorisation object are manual. Reports are ZIP-able only if
they stay screen-free — use `REUSE_ALV_GRID_DISPLAY_LVC` full-screen, no custom
container, no `CALL SCREEN`.

`ZSD_EXC_APPROVAL.zip` (18 files) carries everything for 141.B except the TMG and the
two foreign keys. It was rebuilt 05/09/26 after an element-by-element check of the
abapGit XML — `ZIP_IMPORT_NOTES.md` lists the six defects that were fixed and the root
cause found for the `zfi_tds_cl34` import dumps — and again 17/09/26 with the current
Paints sources. It has never been imported: the DDIC objects were created by hand and all
three programs were pasted, so it is a convenience, not the shipping path. 141.A is
deliberately not in it — it is active, and a pull would overwrite the active object.
