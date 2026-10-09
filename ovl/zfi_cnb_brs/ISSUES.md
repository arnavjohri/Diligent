# ZFI_CNB_BRS (ZFIBRS) — issue log

| # | Date | Issue | Cause | Fix | TR | Status |
|---|------|-------|-------|-----|----|--------|
| 1 | 09/10/26 | BRS run after Validation: "Inconsistent header in file C:\SAPPC\bankbook.txt / Run Validation Module First". Header row in the file is cut at `...HB0012026090`. | Header `bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to` is ~59 chars (AZNUM is 18 digits on OCP). It is stored in `OPENTAB-SGTXT` (LIKE BSEG-SGTXT, 50) on download but compared to `PARAM_TXT(55)` on upload, so the lengths differ and it never matches. `INTAB-DESCR(55)`/`PARAM_TXT(55)` for bnkstmt.txt matched only because both sides truncated at 55, which silently drops `DT_TO`. | `ZFIBRSTOP`: `OPENTAB-SGTXT` → `(70) TYPE C`, `INTAB-DESCR` → `(70)`, `PARAM_TXT` → `(70)`. Main program untouched. | — | **Corrected include delivered, awaiting Arnav's test** |
| 2 | 09/10/26 | FF67 upload (3rd radio button) must run with processing type `WVAR_ART` = 4 instead of 2. | Hardcoded `'2'` in FORM `GENERATE_HEADER_DATA` (screen SAPMF40K 0110). | `ZFI_CNB_BRS`: `FEBMKA-WVAR_ART` `'2'` → `'4'` (BOC/EOC 09/10/26). `NM1VB`/`MNAM1` (session flag/name) left as is. Confirm with an F4 on the field that 4 is the intended value and that 0101 still accepts `NM1VB`/`MNAM1` with it. | — | **Delivered, awaiting test** |

## Noted, not fixed
- Prev-month error merge (FORM around `aznum1 = aznum - 1`): header `bukrs aznum1 hbkid hktid`
  (~31 chars) is written into `ERRTAB_BNKSTMT-NARRATION` (CHAR 25) and compared to `PARAM_TXT1`.
  Same truncation, so it always mismatches and gives warning TEXT-044, and previous-month errors are
  never merged. Fixing it means widening `INPUT-NARRATION`, which changes the bank-statement
  upload layout. That needs FS confirmation first.
