# ZFI_CNB_BRS (tcode ZFIBRS): Bank Reconciliation Report

**Project:** OVL (ONGC Videsh) · system OCP · package `ZFI_BL`
**Objects:** report `ZFI_CNB_BRS` + top include `ZFIBRSTOP` (declarations, selection screen).

## Shipping method
Paste-only. Corrected include: `ovl/zfi_cnb_brs/ZFIBRSTOP.abap` (loose file at folder root).
Corrected main program: `ovl/zfi_cnb_brs/ZFI_CNB_BRS.abap` (issue 2, WVAR_ART).

## Source provenance
`original/ZFI_CNB_BRS.se38-list-2026-10-09.txt` is an SE38 print listing (page headers, line
numbers, long lines wrapped onto continuation lines). `original/*.abap` were rebuilt from it by
stripping headers and joining the continuation lines. Code is complete. A space can be lost
where a comment wrapped at a word boundary (e.g. `" FiscalYear`). That only affects comments.

## How the three modes hand off via files
- **Validation** (`VALD`) builds `INTAB` (bank statement) and `OPENTAB` (bank book). It writes them
  to `C:\sappc\bnkstmt.txt` / `C:\sappc\bankbook.txt` (`GUI_DOWNLOAD` DAT, tab-separated).
  Row 1 of each file is a **header record**: `CONCATENATE bukrs gjahr aznum azdat hbkid hktid
  dt_fm dt_to`. It goes into `INTAB-DESCR` / `OPENTAB-SGTXT`.
- **BRS** (`BRS`) re-uploads both files (`GUI_UPLOAD` ASC, separator) and compares row 1 to
  `PARAM_TXT` built the same way. A mismatch gives "Inconsistent header in file ...".
- Previous-month errors: header `bukrs aznum-1 hbkid hktid` in `INPUT-NARRATION` (CHAR 25).

## Gotchas
- `AZNUM` (FEBMKA-AZNUM) comes out as **18 digits** on OCP. The header is now ~59–60 chars.
  Every field holding it must be ≥ 60 characters.
- Old `.txt` files made before a header-width change fail the check once. Re-run Validation.
