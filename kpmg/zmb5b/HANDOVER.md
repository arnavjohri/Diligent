# HANDOVER — ZMB5B (receipt / issue amount on MB5B)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | MM |
| FS | WRICEF 195_BRD_FS |
| Object in SAP | `ZRM07MLBD` — a **Z copy of SAP standard `RM07MLBD`** (MB5B), tcode `ZMB5B` |
| Repo path | `kpmg/zmb5b/` |
| Ships by | **PASTE-ONLY** |
| Status | Program + 7-unit paste sheet delivered. No activation or issue record in the repo — confirm in the system before assuming it is live |

## What the change does

For radio button **"Storage Loc./Batch Stock" (`LGBST`)**, adds **Receipt amount** and
**Issue amount** columns.

## Two files, and only one is a program

- `src/zrm07mlbd.abap` — 6,206 lines, the whole program.
- `src/ZMB5B_receipt_issue_amount.abap` — 446 lines, **not a program**: a 7-unit paste
  instruction sheet (UNIT 1–7 plus unit tests), each unit naming a target FORM and an
  approximate line number.

## Why this was more than a field-catalog change

The two figures already exist as fields (`BESTAND-SOLLWERT` / `-HABENWERT`,
`STYPE_TOTALS_FLAT-...`, both from include `RM07MLDD`) — but the standard **never fills
them outside valuated stock**. Three gates leave the columns empty if only the field
catalog is touched:

1. `FORM summen_bilden` collects into `SUM_MAT` / `SUM_CHAR`, which carry `MENGE` only and
   have no `DMBTR`;
2. `FORM bestaende_berechnen` fills the values in the `BWBST = 'X'` branch only;
3. `FORM create_fieldcat_totals_flat` appends the amount columns in the `BWBST` branch only.

**And a fourth trap:** `BESTAND-WAERS` is filled by `MOVE-CORRESPONDING g_s_mbew` in the
`BWBST` branch only — in the `LGBST` branch the currency key is initial too, so even a
correct amount renders without a currency or with the wrong one.

If someone reports "amounts are blank" or "amounts have no currency" this week, it is one
of these four, not a new defect.

## Deliberately not delivered

`ANFWERT` / `ENDWERT` were **not** added. They derive from `MBEW-SALK3`, which does not
exist per storage location. Only the two requested fields were built. If anyone asks why
the opening/closing values are missing, that is the answer — it is a data-model limit, not
an omission.

## Applying it

The paste sheet's line numbers ("approx. line 3641", "approx. line 2572") are against one
specific print. **Re-locate by FORM name, never by line number**, and diff a fresh SE38
download against the repo copy before applying.

## Do not do this

- **Never serialise or overwrite the SAP standard includes.** `RM07MLDD`,
  `RM07MLBD_FORM_01`, `RM07MLBD_FORM_02` are kept under their **standard names**,
  unchanged. This is exactly why the object is paste-only and has no `src/`-plus-
  `.abapgit.xml` abapGit layout — a serialised pull would put the standard includes at
  risk.
- The standard `ENHANCEMENT-POINT`s `rm07mlbd_g4`–`g7` on spot `ES_RM07MLBD` are still
  present in the copy. Leave them.

## Stays manual regardless

Creation of `ZRM07MLBD` itself and the `ZMB5B` transaction code (SE93).
