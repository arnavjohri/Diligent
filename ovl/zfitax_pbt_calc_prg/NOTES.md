# ZFITAX_PBT_CALC_PRG — PBT calculation (OVL, system OCP)

**What it is.** Tax PBT calculation report, called from `ZFI_TAX_CREDIT_REPORT`
(`SUBMIT ... WITH year = year`). Builds `lt_racct` from SETLEAF account sets,
reads FAGLFLEXT totals per account into `it_fl` (`ty_fl` in the TOP include)
and sums HSL/KSL per account group.

**Source.** Not in the repo — no SE80 download supplied yet. Only the patch
sheet is here. Ask for a `ZR_PROG_DOWNLOAD` of the program with its TOP include
before any further change.

## How it ships

Paste-only. `PATCH_FAGLFLEXT_FAE.abap` is a fragment for `FORM PROCESS_DATA`,
located by statement text, not line number.

## Gotchas

- FAGLFLEXT is a **compatibility view** on this S/4 landscape. OBJNR00–08,
  ACTIV, RTCUR, RPMAX are constant; rows are distinguished by DRCRK, RCNTR,
  PRCTR and the other characteristics. The classic table key does not make a
  row unique here.
- `FOR ALL ENTRIES` + `INTO CORRESPONDING FIELDS` dedups on the target's
  columns. Never use it on this view unless the target carries every
  characteristic that can vary — in practice, use a RANGE.
- `lt_racct-racct` is ALPHA-converted before the read (around line 275), so
  leading zeros are already handled.
