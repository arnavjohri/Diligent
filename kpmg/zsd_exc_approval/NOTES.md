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

See `ISSUES.md` for the numbered list raised 02/09/26. The hard blocker is the
L4/L5/L6 name source — the FS names `SAPLSLVC_FULLSCREEN`, which is the generic
ALV full-screen function group, not a data source and not SUBMIT-able.

## Delivery

Table + data elements are ZIP-able. TMG (SE11 maintenance generator), any number
range (SNRO) and the authorisation object are manual. Reports are ZIP-able only if
they stay screen-free — use `REUSE_ALV_GRID_DISPLAY_LVC` full-screen, no custom
container, no `CALL SCREEN`.

## Functional flow note

`WRICEF_141AB_Exceptional_Approval_Flow.docx` (05/10/26) — business-language walkthrough of
141.A and 141.B for the functional team: flow per object, selection screens, column logic,
status rules, worked examples and the open confirmation points. Regenerate rather than
hand-edit if the build changes.
