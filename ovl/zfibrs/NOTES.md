# ovl/zfibrs — ZFIBRS (bank book upload / BRS)

## What it is

OVL program `ZFIBRS`. Reads a **tab-delimited text file** from the PC with `GUI_UPLOAD`
(default path seen: `C:\SAPPC\bankbook.txt`), checks a header record, then processes
the detail lines. Has a "validation module" that must run before the main step
(message `Run Validation Module First`).

**Source is not in this repo** — `original/` is empty. Get it with `ZR_PROG_DOWNLOAD`
before any code change.

No download/template function was delivered with the development. Users have been
producing the `.txt` themselves (the header line looks system-generated).

## File layout (inferred from samples/bankbook_2026-09.txt — NOT from source)

16 tab-separated columns, CRLF, ASCII, no column-heading row.

- Line 1 = header record: col 2 `BP`, col 14 = 50-char control string
  (`OVL` `2026` ... `20260930` `HB_01` `HB001` ...), col 15 fiscal year.
- Lines 2+ = detail: doc no, BR/BP, S/H, amount, 0.00, YYYYMMDD, cheque no,
  00000000, JV, blank, 00, C/D reference, blank, narration, fiscal year, 0.

" ASSUMPTION: column meanings are inferred, and the header control-string structure is
unknown — confirm both against the program's upload structure.

## Template

`ZFIBRS_Upload_Template.xlsx` — Upload sheet (all cells Text-formatted) + Instructions +
Column Guide. Users Save As "Text (Tab delimited)". Verified: re-saving the Upload sheet
as tab-delimited reproduces the sample lines byte-for-byte.

## Gotchas

- `GUI_UPLOAD` sy-subrc 1 = `FILE_OPEN_ERROR`: file missing / `bankbook.txt.txt` /
  open in Excel / WebGUI cannot read a fixed local path / SAP GUI security setting.
  The program then shows "Inconsistent header" because the table is empty.
- Excel strips leading zeros and `0.00` unless cells are Text — hence the template.
