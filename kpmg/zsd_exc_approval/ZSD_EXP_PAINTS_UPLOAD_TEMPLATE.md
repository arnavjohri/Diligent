# ZSD_EXP_PAINTS_UPLOAD — upload file template

WRICEF 141.B, Astral Limited, project UDAY, module SD. This is the layout the business
fills in and feeds to `ZSD_EXP_PAINTS_UPLOAD` via the **P_FILE** parameter.

Every rule below is read off `/home/user/Diligent/kpmg/zsd_exc_approval/ZSD_EXP_PAINTS_UPLOAD.abap`
(forms `f_parse_rows`, `f_conv_date`, `f_conv_month`, `f_conv_amount`, `f_validate_rows`),
not off the FS. Two places where the FS narrative and the code disagree are called out
explicitly — **the code is what will run, so the code wins.**

## 1. How to produce the file

In Excel: **File → Save As → Text (Tab delimited) (*.txt)**. The program reads the file
with `cl_gui_frontend_services=>gui_upload`, filetype `ASC`, `has_field_separator = 'X'`
— it splits each line on the **tab** character. It does **not** open an `.xlsx`/`.xls`
binary; saving as anything other than tab-delimited text will not load.

Tick **"First line is a column header"** (`P_HEAD`) on the selection screen if row 1 of
the file is a header row like the one below — the program then drops that row before
reading data. Leave it off if row 1 is already a data row.

A completely blank line (including a trailing blank line Excel often adds at the end of
the file) is silently skipped — it is not counted and does not appear in the log.

## 2. Column layout

Columns must appear in exactly this order — the file is split by tab position, not by
header name, so a column typed in the wrong place is silently read into the wrong field.

| # | Column | Mandatory | Accepted format | What the program does with a bad value |
|---|---|---|---|---|
| 1 | **ZSRN** (Serial number) | Yes | Digits only, up to 10 digits. Leading zeros optional — the value is stored right‑padded into a NUMC(10) field, so `7` and `0000000007` are the same. | Blank → row rejected, *"Serial number is missing"*. Non‑digit characters, or more than 10 digits → row rejected, *"Serial number must be numeric, up to 10 digits"*. |
| 2 | **ZCUSTOMER** (Customer) | Yes | Customer number, up to 10 characters, with or without leading zeros (`ALPHA` conversion is applied, same as a screen field — `10001` and `0000010001` both resolve to the same customer). | Blank → *"Customer is missing"*. More than 10 characters → *"Customer number is longer than 10 characters"*. Any value not found in KNA1 (checked once for the whole file, after parsing) → *"Customer does not exist in KNA1"*. |
| 3 | **ZEXC_APPR_MONTH** (Approval month) | Yes | `MM-YYYY` or `MM/YYYY`. Month may be 1 or 2 digits (`7-2026` and `07-2026` both work); year must be exactly 4 digits, month must be 01–12. Stored internally as `YYYYMM`, shown back on the log as `MM-YYYY`. | Blank → *"Approval month is missing"*. Anything that doesn't split into a valid month and a 4‑digit year → *"Approval month is not in MM-YYYY format"*. |
| 4 | **ZEXC_APPR_TYPE** (Approval type) | Yes | Exactly one character: `1` (Credit Limit), `2` (Overdue) or `3` (Credit Limit & Overdue) — per the build spec's fixed values. `01` or `1 ` with an embedded space is **not** the same as `1` after the program strips spaces, so only a bare `1`/`2`/`3` passes. | Blank → *"Approval type is missing"*. Anything else → *"Approval type must be 1, 2 or 3"*. |
| 5 | **ZEXC_DATE_FROM** (Approval date from) | Yes | `DD.MM.YYYY` or `DD/MM/YYYY` — **day first**. Day/month may be 1 or 2 digits, year must be exactly 4 digits, and the day/month combination must be a real calendar date (leap years handled). | Blank → *"Approval date from is missing"*. Not a valid date in day‑first form → *"Approval date from is not a valid date"*. |
| 6 | **ZEXC_DATE_TO** (Approval date to) | No | Same `DD.MM.YYYY` / `DD/MM/YYYY` rule as column 5. May be left blank (stored as an initial date). | Left blank → accepted, no error. Filled but not a valid date → *"Approval date to is not a valid date"*. If both column 5 and column 6 are filled and column 6 is earlier than column 5 → *"Approval date to is before approval date from"* (equal dates are allowed). |
| 7 | **ZEXC_AMOUNT** (Exceptional amount) | No (blank = 0) | Digits, one optional decimal point with **at most two decimals**, optional thousand separators as commas in **any** grouping (`125,000.00` or `1,25,000.00` both work — commas are stripped before conversion). Optional leading `+`, leading or trailing `-` for a negative value. Up to 21 integer digits + 2 decimals. | Blank → stored as `0`, no error. Anything that isn't cleanly numeric after the above (including a comma appearing **after** the decimal point, e.g. `1.234,56`, which is read as continental notation and rejected rather than silently misparsed, and a third decimal such as `100.567`, which would otherwise be rounded without a trace) → *"Exceptional amount is not a valid number"* — **never** silently defaulted to zero or rounded. |
| 8 | **ZCOMMIT_DATE** (Commitment date) | No | Same `DD.MM.YYYY` / `DD/MM/YYYY` rule as columns 5–6. | Left blank → accepted, no error (later read as "no status yet" by the output report). Filled but invalid → *"Commitment date is not a valid date"*. |
| 9 | **ZEX_AMNT** (Exceptional approval amount) | No (blank = 0) | Same rule as column 7. | Same as column 7; bad value → *"Exceptional approval amount is not a number"*. |
| 10 | **ZCM_AMNT** (Collection commitment amount) | No (blank = 0) | Same rule as column 7. | Same as column 7; bad value → *"Collection commitment amount is not a number"*. |
| 11 | **WAERS** (Currency) | Yes | Currency key, up to 5 characters, case‑insensitive (converted to upper case), e.g. `INR`. | Blank → *"Currency is missing"*. More than 5 characters → *"Currency key is longer than 5 characters"*. Any value not found in TCURC (checked once for the whole file) → *"Currency does not exist in TCURC"*. |
| 12 | **ZREMARKS** (Remarks) | No | Free text. Unlike every other column this one is **not** trimmed or upper‑cased — internal spacing and case are kept exactly as typed. Field on the table is 250 characters; the program reads at most the first 500 characters of the cell. | Blank → accepted. Longer than 250 characters → the row is **not** rejected; the text is truncated to 250 characters and a note is added to the log (*"Remarks truncated to 250 characters, file length nnn"*) so the truncation is never silent. A cell longer than 500 characters is cut to 500 on the way in, before that check, so the note then reports 500. |

## 3. Row-level and file-level rules (not tied to one column)

- **Every check on a row runs, even after the row has already failed one.** All the
  problems found on a row are reported together, separated by `;`, so you get every
  mistake on that row in one pass instead of fixing them one at a time.
- **Duplicate key inside the file.** The key is columns 1+2+3 (Serial number + Customer +
  Approval month) together. The **first** occurrence of a key is processed normally; the
  **second and any later** occurrence in the same file is rejected with *"The same key is
  already used in file row N"*, naming the earlier row.
- **Insert mode vs. change mode**, set on the selection screen, not in the file:
  - **Insert new records only** (`P_INS`, default): if the key (columns 1+2+3) already
    exists on the table, the row is rejected — *"Record exists already - use the change
    mode"*.
  - **Insert new and change existing** (`P_UPD`): an existing key is updated instead of
    rejected; a new key is inserted. Either way, one row in the file = one row on the
    table.
- **A rejected row never blocks the good rows around it.** Only rows that pass every
  check are written; the rest of the file's valid rows still go through, in one database
  update (unless the update itself fails technically, in which case nothing from the
  whole file is written and every row's log line says so).
- **Test run** (`P_TEST`, checked by default): validates and shows the log exactly as a
  real run would, but writes nothing to the table.

## 4. Worked example

Astral customer master (from the Astral FS sample data — confirm both still exist in
KNA1 before using this file as a real test, per the "don't guess names" rule):
`1009024` BABA TRADING CO‑MNT, `1025584` AGRAWAL INDUSTRIES‑MNT.

| ZSRN | ZCUSTOMER | ZEXC_APPR_MONTH | ZEXC_APPR_TYPE | ZEXC_DATE_FROM | ZEXC_DATE_TO | ZEXC_AMOUNT | ZCOMMIT_DATE | ZEX_AMNT | ZCM_AMNT | WAERS | ZREMARKS |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1009024 | 07-2026 | 1 | 25.07.2026 | | 50000 | 05.08.2026 | 50000 | 100000 | INR | Credit limit exceeded for July dispatch - approved by RM |
| 2 | 1025584 | 07-2026 | 2 | 26.07.2026 | 31.07.2026 | 25000 | 06.08.2026 | 25000 | 98000 | INR | Overdue balance from Q1, part payment agreed |
| 3 | 1009024 | 08-2026 | 3 | 10.08.2026 | | 1,25,000.00 | | 1,25,000.00 | | INR | |

As the tab-delimited text the program actually reads (`→` marks a tab; do not type the
arrows — they are only there so the columns line up on screen):

```
ZSRN→ZCUSTOMER→ZEXC_APPR_MONTH→ZEXC_APPR_TYPE→ZEXC_DATE_FROM→ZEXC_DATE_TO→ZEXC_AMOUNT→ZCOMMIT_DATE→ZEX_AMNT→ZCM_AMNT→WAERS→ZREMARKS
1→1009024→07-2026→1→25.07.2026→→50000→05.08.2026→50000→100000→INR→Credit limit exceeded for July dispatch - approved by RM
2→1025584→07-2026→2→26.07.2026→31.07.2026→25000→06.08.2026→25000→98000→INR→Overdue balance from Q1, part payment agreed
3→1009024→08-2026→3→10.08.2026→→1,25,000.00→→1,25,000.00→→INR→
```

Row 3 shows three things at once: a thousand-separated amount (`1,25,000.00`), several
optional columns left blank (date to, commitment date, collection commitment amount,
remarks), and a second approval for a customer that already has a row in the file — this
is fine, because the key (serial number + customer + month) differs from row 1.

With `P_HEAD` = X and `P_INS` (insert only), a first run of this file inserts all three
rows. Running the same file again in insert mode would reject all three with *"Record
exists already - use the change mode"*; switch to `P_UPD` to update them instead.

## 5. Mistakes that will get a row rejected

- **Wrong date order.** Dates are **day first**: `25.07.2026` is 25 July, not 7 January.
  Excel's US-style `7/25/2026` (month/day/year) will usually fail outright because the
  month position exceeds 12 — but a date like `07/08/2026` will be silently read as **7
  August**, not 8 July, because both 07 and 08 are valid day-or-month values. Always type
  dates as `DD.MM.YYYY`, and format the date columns as **Text** in Excel before typing
  into them — otherwise Excel is liable to re-format the cell into its own regional date
  style on save, which may not be day-first at all.
- **A 2-digit approval type.** `01` is not the same as `1` — only the bare digit is
  accepted.
- **Continental amount notation.** `1.234,56` (dot as thousand separator, comma as
  decimal) is rejected outright rather than being misread — write amounts as
  `1,234.56` or `1234.56`.
- **Three or more decimals.** `100.567` is rejected, not rounded to `100.57` — the table
  holds two decimals and the program never changes a value silently.
- **A currency or customer that doesn't exist yet in the system** — both are checked
  against KNA1 / TCURC and rejected by name, not by a generic "invalid" message.
- **Re-uploading the same file in "Insert new records only" mode** once the rows are
  already on the table — switch to "Insert new and change existing" to update them.
- **The same Serial No. + Customer + Approval month combination twice in one file** — the
  second occurrence is rejected even if every other column on it is correct.
- **Typing extra columns, or columns out of order.** The file has no column-name lookup;
  position 1 is always read as Serial number, position 2 as Customer, and so on,
  regardless of what the header row says.
- **A file saved as `.xlsx` or `.xls`** instead of tab-delimited text — the program will
  fail to read it as data (garbled or empty rows) rather than telling you the file type
  is wrong.

## 6. Notes for the SE11 / functional checklist (not upload-file issues, flagged for completeness)

- The FS calls this amount **ZEXC_AMNT** in its output mapping; the table field the
  program actually writes to (and the one you validate against here) is **ZEXC_AMOUNT**
  — see build spec §1 C4. The **file column name above (`ZEXC_AMOUNT`) is correct** for
  this upload.
- **ZEX_AMNT** (column 9) is loaded and validated like any other amount, but no output
  report reads it back (build spec §7 item 9) — confirm with functional whether it is a
  genuine second figure the business needs, before spending effort getting it right on
  every upload.
