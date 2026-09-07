# HANDOVER — ZSD_SCHEME (Scheme, Pipes)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | SD |
| Objects | `SAPMZSD_SCHEME` (module pool), `ZCL_SD_SCHEME`, `ZCL_SD_SCHEME_SETTLE`, `ZCL_SD_SCHEME_UI`, `ZSD_SCHEME_REPORT` (ZSCHM_RPT), `ZSD_SCHEME_UPLOAD` (ZSCHM_UPL) |
| Repo path | `kpmg/zsd_scheme/` |
| Ships by | **PASTE-ONLY** for the package as a whole |
| Status | Built (3,579 lines across 6 files). Largest manual footprint of anything in the KPMG set. No activation or issue record in the repo |

## The single biggest trap in this folder

**`src/SAPMZSD_SCHEME.abap` is one file containing FIVE includes concatenated** —
`ZSD_SCHEME_TOP`, `_CLS`, `_O01`, `_I01`, `_F01`. Creating the module pool means creating
**five includes, not one program**. Anyone who pastes that file into a single SE38 program
will produce something that does not activate and will not understand why.

## Second trap

`ZSD_SCHEME_REPORT` is a report but is **not screen-free**: `CALL SCREEN 0100` (l.163),
`SET PF-STATUS 'S0100'` (l.216), `cl_gui_custom_container`. It needs its **own SE51 screen
0100 and SE41 status** before it will activate. `ZSD_SCHEME_UPLOAD` is the opposite —
selection screen + `CL_SALV_TABLE` + `cl_gui_frontend_services` only, no screen work.

## What is in it

- Module pool with **four SE51 screens** (0100 initial, 0200 maintain, 0210 / 0220
  subscreens under tabstrip `TS_MAIN`), two GUI statuses (`S0100`, `S0200`), two titles,
  8 PBO and 8 PAI modules, two `CL_GUI_ALV_GRID` instances in custom controls
  `CC_SEL` / `CC_RAT`.
- `ZCL_SD_SCHEME` (790) — model + validation.
- `ZCL_SD_SCHEME_SETTLE` (893) — volume / early-bird / cascading logic and CN posting.
- `ZCL_SD_SCHEME_UI` (180) — field texts and switchable F4.
- Tcodes `ZSCHM01` / `ZSCHM02` / `ZSCHM03` are **parameter transactions** on screen 0100
  passing `MODE` = H / V / A.

## Design decisions someone might mistake for defects

- **One generic range table (`ZSDT_SCHM_RNG`) replaces seven child tables.** "Select All"
  is one row, `I / CP / *`. Adding a new selection field means extending domain
  `ZDO_SCHM_FLD`'s fixed values plus the mapping in `ZCL_SD_SCHEME_SETTLE=>build_ranges`
  — **no DDIC change**.
- **Segregation of duties is enforced by removing the Post button from the GUI status**
  when `ZSD_SCHM_ST ACTVT 16` is missing, not only by a check at posting time. If someone
  reports "the Post button is missing", that is authorisation working, not a bug.
- **`ZSDT_SCHM_SLB` (slabs) is created empty on purpose** so slab payout stays a code
  change, never a table conversion.
- **Nothing about the posting is hardcoded** — order type, billing type, material and
  condition all come from `ZSDT_SCHM_CFG` via SM30.
- **Validation lives only in `ZCL_SD_SCHEME`** so the online transaction and the mass
  upload cannot diverge (A39). Uploaded schemes are always status New — release stays
  manual (A40).

## Open point Q2 — flagged, not resolved

The FS maps sold-to / distribution channel to the analytical fields `VBRP-KUNAG_ANA` /
`VTWEG_AUFT`; the code uses **`VBRK-KUNAG` / `VBRK-VTWEG`** instead, because the analytical
fields may not be active on this landscape. `KNA1-ZZ1_LOC1_CUS` / `ZZ1_LOC2_CUS` /
`ZZ1_SP_CODE_CUS` are read via `ASSIGN COMPONENT` so the class compiles whether or not
those extension fields exist.

If the numbers ever look wrong at customer level, this is the first thing to check.

## Dependencies — large

7 tables, 8 domains, 10 data elements, 4 structures, 4 table types; number range
`ZSDSCHEME`; lock object `EZSDT_SCHM_HDR`; message class `ZSD_SCHEME` (35 messages);
auth objects `ZSD_SCHM` / `ZSD_SCHM_ST`; change document object `ZSDSCHEME`; SM30 views
`ZSDV_SCHM_FKA` / `ZSDV_SCHM_CFG`; search help `ZSH_SCHM_NO`.

Build order is in `docs/00_TECHNICAL_OBJECTS.md` §11; screen layout in
`docs/01_SCREEN_LAYOUT.md`. **Follow the build order** — with this many dependencies,
building out of order wastes a day.

## Could this ever ship by abapGit?

Only partly. The DDIC set + the three classes + `ZSD_SCHEME_UPLOAD` are the abapGit-able
subset. The module pool's screens, GUI statuses, SM30 views, number range, auth objects
and change-document object are not serialisable by abapGit, and `ZSD_SCHEME_REPORT` needs a
hand-built screen too. Not worth attempting this week.

## Stays manual regardless

SE51 screens 0100 / 0200 / 0210 / 0220 · SE41 statuses `S0100` / `S0200` and titles ·
SNRO `ZSDSCHEME` · SU21 `ZSD_SCHM` / `ZSD_SCHM_ST` · SCDO `ZSDSCHEME` ·
lock object `EZSDT_SCHM_HDR` · SE54 views `ZSDV_SCHM_FKA` / `ZSDV_SCHM_CFG` ·
SE93 tcodes ZSCHM01 / 02 / 03 / ZSCHM_RPT / ZSCHM_UPL.
