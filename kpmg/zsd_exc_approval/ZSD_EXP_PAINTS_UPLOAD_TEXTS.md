# ZSD_EXP_PAINTS_UPLOAD — Text Elements to maintain in SE38

None of this travels with a pasted source. After pasting `ZSD_EXP_PAINTS_UPLOAD.abap`,
go **SE38 → (enter program) → Goto → Text Elements** and maintain the tabs below
exactly as listed, then activate.

## Reconciliation performed

Grepped the source for every text-symbol reference, in both forms it uses:

```
grep -noE "TEXT-[a-z0-9]{3}" ZSD_EXP_PAINTS_UPLOAD.abap
grep -noE "'[^']*'\([a-z][0-9]{2}\)" ZSD_EXP_PAINTS_UPLOAD.abap
```

The first form (`TEXT-001` / `TEXT-002` / `TEXT-003`) is the three selection-screen
block titles. The second form (`'literal'(xxx)`) is every message, action label, ALV
column heading and summary-line fragment. Nothing else in the source matches either
pattern — the `+4(2)` / `(1)` / `(4)` occurrences in the code and in comments (e.g.
`ls_row-zexc_appr_month+4(2)`, `lv_str(lv_off)`, `lv_str+1(lv_off)`) are substring
offsets, not text-symbol references, and are excluded.

That leaves **55 distinct IDs**: `001`–`003`, `m01`–`m09` (9 IDs — `m06` was added on
17/09/26 for the COMMIT WORK AND WAIT warning), `e01`–`e23` (23 IDs, no gaps),
`a01`–`a06` (6 IDs), `c01`–`c08` (8 IDs), `t01`–`t06` (6 IDs).
`3 + 9 + 23 + 6 + 8 + 6 = 55`. Every one of the 55 appears in Table 1 below, each
exactly once, with the literal text taken verbatim from the source as the default.
Nothing is listed that the source does not reference, and nothing the source
references is missing. `(m02)` occurs twice in the source (`F_READ_FILE` line 372 and
`F_DISPLAY_LOG` line 1088) with the identical literal both times — one row, not two.

Selection texts were reconciled separately against the header-comment block (lines
67–72 of the source, which already states the intended wording): every `PARAMETERS`
statement on the selection screen (5 total: `P_FILE`, `P_HEAD`, `P_INS`, `P_UPD`,
`P_TEST`) has exactly one row in Table 2.

---

## 1. Text Symbols

Numeric IDs first, then alphanumeric IDs in SAP's ascending sort order (digits sort
before letters).

| No. | Text (type into SE38 as the default) | Max length | Used for |
|-----|----------------------------------------|-----------:|----------|
| 001 | File | 4 | `SELECTION-SCREEN ... TITLE TEXT-001` — block B1 frame title (build spec 5.1) |
| 002 | Mode | 4 | `SELECTION-SCREEN ... TITLE TEXT-002` — block B2 frame title (build spec 5.1) |
| 003 | Processing | 10 | `SELECTION-SCREEN ... TITLE TEXT-003` — block B3 frame title (build spec 5.1) |
| M01 | The upload file could not be read: | 34 | error, `F_READ_FILE` — concatenated with the file name |
| M02 | The upload file contains no data rows | 37 | error, `F_READ_FILE` and `F_DISPLAY_LOG` (used twice, identical text) |
| M03 | The database update failed, the row was rolled back | 51 | log fragment, `F_BUILD_LOG` — shown when `G_DBFAIL = 'X'` |
| M04 | The row was written to the database | 35 | log fragment, `F_BUILD_LOG` — normal insert/change outcome |
| M05 | Test run - the row is valid, nothing written | 44 | log fragment, `F_BUILD_LOG` — shown when `P_TEST = 'X'` |
| M06 | Rows saved, but a follow-on update failed - see SM13 | 52 | summary warning, `F_SHOW_SUMMARY` — `SY-SUBRC <> 0` after `COMMIT WORK AND WAIT` (added 17/09/26) |
| M07 | The result list could not be displayed | 38 | error, `F_DISPLAY_LOG` — `REUSE_ALV_GRID_DISPLAY_LVC` failed |
| M08 | Select the upload file | 22 | F4 dialog title, `F_F4_FILE` |
| M09 | The file dialog could not be opened | 35 | error, `F_F4_FILE` |
| E01 | Serial number is missing | 24 | row error, `F_PARSE_ROWS` — ZSRN check, build spec 5.3.1 |
| E02 | Serial number must be numeric, up to 10 digits | 46 | row error, `F_PARSE_ROWS` — ZSRN check, build spec 5.3.1 |
| E03 | Customer is missing | 19 | row error, `F_PARSE_ROWS` — ZCUSTOMER check |
| E04 | Customer number is longer than 10 characters | 44 | row error, `F_PARSE_ROWS` — ZCUSTOMER check |
| E05 | Approval month is missing | 25 | row error, `F_PARSE_ROWS` — ZEXC_APPR_MONTH check, build spec 5.3.3 |
| E06 | Approval month is not in MM-YYYY format | 39 | row error, `F_PARSE_ROWS` — ZEXC_APPR_MONTH check, build spec 5.3.3 |
| E07 | Approval type is missing | 24 | row error, `F_PARSE_ROWS` — ZEXC_APPR_TYPE check, build spec 5.3.4 |
| E08 | Approval type must be 1, 2 or 3 | 31 | row error, `F_PARSE_ROWS` — ZEXC_APPR_TYPE check, build spec 5.3.4 |
| E09 | Approval date from is missing | 29 | row error, `F_PARSE_ROWS` — ZEXC_DATE_FROM check, build spec 5.3.5 |
| E10 | Approval date from is not a valid date | 38 | row error, `F_PARSE_ROWS` — ZEXC_DATE_FROM check, build spec 5.3.5 |
| E11 | Approval date to is not a valid date | 36 | row error, `F_PARSE_ROWS` — ZEXC_DATE_TO check, build spec 5.3.5 |
| E12 | Approval date to is before approval date from | 45 | row error, `F_PARSE_ROWS` — ZEXC_DATE_TO vs ZEXC_DATE_FROM, build spec 5.3.6 |
| E13 | Commitment date is not a valid date | 35 | row error, `F_PARSE_ROWS` — ZCOMMIT_DATE check, build spec 5.3.5 |
| E14 | Exceptional amount is not a valid number | 40 | row error, `F_PARSE_ROWS` — ZEXC_AMOUNT check, build spec 5.3.7 |
| E15 | Exceptional approval amount is not a number | 43 | row error, `F_PARSE_ROWS` — ZEX_AMNT check, build spec 5.3.7 |
| E16 | Collection commitment amount is not a number | 44 | row error, `F_PARSE_ROWS` — ZCM_AMNT check, build spec 5.3.7 |
| E17 | Currency is missing | 19 | row error, `F_PARSE_ROWS` — WAERS check |
| E18 | Currency key is longer than 5 characters | 40 | row error, `F_PARSE_ROWS` — WAERS check |
| E19 | Remarks truncated to 250 characters, file length | 48 | row **note** (not a rejection), `F_PARSE_ROWS` — added via `F_ADD_NOTE`, concatenated with the file length; row stays valid |
| E20 | Customer does not exist in KNA1 | 31 | row error, `F_VALIDATE_ROWS` — build spec 5.3.2 |
| E21 | Currency does not exist in TCURC | 32 | row error, `F_VALIDATE_ROWS` — build spec 5.3.8 |
| E22 | The same key is already used in file row | 40 | row error, `F_VALIDATE_ROWS` — concatenated with the earlier row number, build spec 5.3.9 |
| E23 | Record exists already - use the change mode | 43 | row error, `F_VALIDATE_ROWS` — insert mode only, build spec 5.3.10 |
| A01 | Inserted | 8 | ALV action label, `F_BUILD_LOG` — written, insert |
| A02 | Changed | 7 | ALV action label, `F_BUILD_LOG` — written, change |
| A03 | Would change | 12 | ALV action label, `F_BUILD_LOG` — test run, change |
| A04 | Would insert | 12 | ALV action label, `F_BUILD_LOG` — test run, insert |
| A05 | Rejected | 8 | ALV action label, `F_BUILD_LOG` — row invalid |
| A06 | Not written | 11 | ALV action label, `F_BUILD_LOG` — valid row, database update failed |
| C01 | File Row | 8 | ALV column heading, ROWNO |
| C02 | Status | 6 | ALV column heading, STATUS (icon column) |
| C03 | Sr. No. | 7 | ALV column heading, SRNO |
| C04 | Customer | 8 | ALV column heading, KUNNR |
| C05 | Approval Month | 14 | ALV column heading, MONTH |
| C06 | Result | 6 | ALV column heading, ACTION |
| C07 | Message | 7 | ALV column heading, MESSAGE |
| C08 | Approval Type | 13 | ALV column heading, ATYPE |
| T01 | Rows read: | 10 | summary-line fragment, `F_SHOW_SUMMARY` |
| T02 | valid: | 6 | summary-line fragment, `F_SHOW_SUMMARY` |
| T03 | written: | 8 | summary-line fragment, `F_SHOW_SUMMARY` |
| T04 | in error: | 9 | summary-line fragment, `F_SHOW_SUMMARY` |
| T05 | TEST RUN - nothing was written | 30 | summary-line fragment, `F_SHOW_SUMMARY` — appended when `P_TEST = 'X'` |
| T06 | DATABASE UPDATE FAILED - nothing was written | 44 | summary-line fragment, `F_SHOW_SUMMARY` — appended when `G_DBFAIL = 'X'` |

55 rows, 55 distinct IDs referenced in the source — the two sets match.

## 2. Selection Texts

One row per `PARAMETERS` on the selection screen, in source order. Type the label into
the **Text** column of the Selection Texts tab against the field name shown; SE38
pre-lists the field names automatically, this table is what to type next to each. The
wording is already dictated by the header comment of the source (lines 67–72) and by
build spec 5.1 — this table only carries it into one place.

| Field name | Statement | Label to enter |
|---|---|---|
| P_FILE | PARAMETERS TYPE localfile OBLIGATORY | Upload file |
| P_HEAD | PARAMETERS AS CHECKBOX DEFAULT 'X' | First line is a column header |
| P_INS  | PARAMETERS RADIOBUTTON GROUP md DEFAULT 'X' | Insert new records only |
| P_UPD  | PARAMETERS RADIOBUTTON GROUP md | Insert new and change existing |
| P_TEST | PARAMETERS AS CHECKBOX DEFAULT 'X' | Test run - validate only, no database update |

5 rows — every PARAMETERS statement in the source has one.

## 3. List Headings / Title

The program is screen-free ALV only (`REUSE_ALV_GRID_DISPLAY_LVC`, no `WRITE`, no
classical list, no `TOP-OF-PAGE`), so the **Header**, **Column heading** and **Key
word** fields on the List Headings tab are not read by this program at runtime — leave
them blank, same as `ZSD_EXC_APPR_ADHESIVE`.

Set only the **Title**:

| Field | Text |
|---|---|
| Title | Exceptional Approval Paints - Upload and Change |

This matches the `Title` line in the source's own object header (line 3) and is also
the title SE38 shows in the object list / program attributes; it is cosmetic only for
this ALV-grid program (it would appear in the status bar of a classical list, which
this program never produces).
