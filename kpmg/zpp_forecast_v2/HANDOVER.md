# HANDOVER — ZPP_FORECAST_V2 (ZFORECAST, Adhesive)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | PP |
| Source doc | `Forecast Template-Adhesive.xlsx`, 20.08.2026. Paints (WRICEF ID-2B) out of scope |
| Objects | `ZCL_PP_FCST`, `ZCL_PP_FCST_UTIL`, `ZPP_FORECAST` (ZFCST), `ZPP_FORECAST_REPORT` (ZFCST_RPT), `ZPP_FORECAST_UPLOAD` (ZFCST_UPL) |
| Repo path | `kpmg/zpp_forecast_v2/` |
| Ships by | abapGit ZIP — **but see the defect below** |
| Status | **BUILT. ZIP CARRIES A KNOWN, UNFIXED DEFECT** |

## The one thing to know

**`ZPP_FORECAST.zip` will short-dump if anyone imports it this week.**

All three `prog.xml` files carry `PROGDIR` in the order
`NAME, SUBC, FIXPT, VARCL, UCCHECK`. The correct order is
`NAME, VARCL, SUBC, FIXPT, UCCHECK` — `varcl` is component 5 of
`zif_abapgit_sap_report=>ty_progdir`, `subc` 11, `fixpt` 23, `uccheck` 30. abapGit
deserialises with `CALL TRANSFORMATION id`, which raises `CX_XSLT_FORMAT_ERROR` on the
first out-of-sequence element, so the import dies on `VARCL`.

Found 03/09/26 while building `kpmg/zsd_exc_approval`. **Verified still present
07/09/26** — the three files have not been fixed.

`NOTES.md` calls this "the only object in this repository that ships this way cleanly".
That claim predates the finding and **is not supported by any record of a successful
import**. Do not act on it.

Fix is: reorder the three `prog.xml` files, re-zip from `src/`. Ten minutes. I have left
it rather than push an unverifiable change on my way out — if someone needs the ZIP this
week, that is the fix, and the corrected shape to copy is in
`kpmg/zsd_exc_approval/src/*.prog.xml`.

## Also on the ZIP

Re-zip from `src/` rather than trusting the archive — `ZPP_FORECAST.zip` was rebuilt 23.08
while several `src/` XMLs date from 20–21.08.

## Screen-free by design, and that is load-bearing

Everything displays through `CL_SALV_TABLE` full screen. No SE51 screen, no SE41 GUI
status anywhere. Rows are picked with the standard SALV selection column instead of a
checkbox; Save is added to the SALV toolbar.

**Do not introduce `CALL SCREEN` or `cl_gui_custom_container` here.** Doing so converts
the whole object back to paste-only, which is exactly why v1 was rewritten.

## Do not mix with v1

`kpmg/zpp_forecast/` is version 1, superseded, built to a **different source document**
(14.08.2026 vs 20.08.2026). The inventories genuinely differ — different class names,
different message class, and five tables v2 does not have at all. Pulling a v1 table
definition into a v2 system produces orphans. Never cite one version's DDIC while shipping
the other.

## A reverted change — do not re-apply it without asking me

On 31/08/26 I pushed upload corrections (file row numbers, plant condense, non-numeric
cells, category length, UOM validation, exclusion check, table locking, prefetch, plus
`ZPP_FCST` messages 022/023) and a `TO_DEC` fix for cells holding a comma. **Both were
reverted the same day at Arnav's request** (commit `8a87bc8`). `ZPP_FORECAST_UPLOAD`,
`ZPP_FCST`, the ZIP, `ISSUES.md` and `NOTES.md` are all back at their pre-31/08 state.

If the comma-decimal problem (`1,5` loading as `15`) comes up again this week, the fix
exists in git history — `git show 3611641` — but it was deliberately backed out. Ask
before restoring it.

## Duplicate copies — none authoritative except `src/`

`zcl_pp_fcst_nocomments.abap` and `zpp_forecast_v2_nocomments.abap` are comment-stripped
paste copies for when SE24 paste is preferred over an import. Both drift silently from
`src/zcl_pp_fcst.clas.abap`, which is the source of truth.

## Gotchas worth keeping in front of you

- Every table name in the source document exceeds SAP's 16-character limit and was renamed
  (`ZPP_ADH_FORECAST_YEAR` → `ZPPT_FCST_YR`, etc.); `ZPP_ADHESIVE_SNRO` → `ZPPFCST` because
  number range objects cap at 10. Rename table is in `00_TECHNICAL_OBJECTS.md`.
- Two places where the source document's prose and its worked example disagree are
  documented in `00_TECHNICAL_OBJECTS.md` §9. **Read that before "fixing" a formula.**
- `LVC_T_FNAME` is not available in every release, so the column-name list is typed locally
  over `LVC_FNAME`.
- `ZDO_REASON` (CHAR 40) already exists and is reused, not created.
- MTS/MTO lives on `ZPPT_PROD_CAT`, not in a table of its own.

## Stays manual regardless

SE93 tcodes ZFCST / ZFCST_RPT / ZFCST_UPL · SNRO `ZPPFCST` · SU21 `ZPP_FCST` ·
SE54 for the four SM30 views.
