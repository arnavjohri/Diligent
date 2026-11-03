# TS — ZFI_ACDOCA_JVA_ALIGN (no FSD; design agreed in chat 02/11/2026)

## 1. Document control

| Item | Value |
|---|---|
| Version | 1.0 |
| Author | Arnav Johri, Diligent Global |
| Date | 02.11.2026 |
| Project / system | OVL · OCQ/500 |
| Related FS | None — design in `ovl/z_jva_alignment/NOTES.md` §6; reference program `Z_JVA_ALIGNMENT` (another landscape) |
| Transport | TBD |

## 2. Purpose / background
Ledger 0L carries FI offset lines without venture split; the JV ledger carries the same amounts
split by venture / equity group / recovery indicator. Group reporting reads 0L. The recon
`ZFI_ACDOCA_JVSO1_RECON` computes the difference per key and, since v1.2, the amount to post.
This program takes that output, reviewed in Excel, and inserts it into ACDOCA 0L as
ACDOCA-only lines, balanced per account, so the venture split in 0L equals the JV ledger
without moving any account balance.

## 3. Objects affected

| Object | Type | New / changed | Package | TR |
|---|---|---|---|---|
| ZFI_ACDOCA_JVA_ALIGN | Executable report (SE38, type 1, no includes) | New | TBD | TBD |
| Text elements of ZFI_ACDOCA_JVA_ALIGN | Text symbols B01–B04, selection texts | New (manual) | — | same |

No DDIC, no message class, no OBA7 entry (document type ZJ is a constant — decision 02/11).

## 4. Detailed design

### 4.1 Selection screen
| Field | Text | Note |
|---|---|---|
| R_UPL / R_DEL | Upload Excel and post / Undo: delete alignment lines | radio group |
| P_FILE | Excel file (.xlsx) | F4 file dialog; required in upload mode |
| S_BUKRS, S_GJAHR, S_POPER | Company Code, Fiscal Year, Posting Period | undo mode; company code and year required |
| P_TEST | Test run (no database update) | default X |

### 4.2 Excel layout
See NOTES.md — 15 columns by position, columns 1–10 = recon key + *To Post* columns.

### 4.3 Processing — FORMs in call order
`read_file` → `parse_rows` / `parse_row` (`get_company`, `period_date`, `check_account` +
`read_bsx_accounts`, `check_jva_fields` + `check_on_ledger`, `check_cost_objects` + `find_wbs`,
`parse_amount`)
→ `file_checks` (+ `err_document`) → `assign_documents` → `post_or_test` (`build_acdoca_line`,
`set_doc_status`) → `display_result` (`set_col_text`, `hide_col`). Undo: `undo_alignment`.

### 4.4 Validation rules
Row: company code (T001, TKA02), year 4 digits, period 0–16, account (SKA1, SKB1), venture
(T8JV), equity group (T8JG with venture, else exists on 0L), recovery indicator (exists on 0L,
venture not required), cost
centre (CSKS valid on posting date), order (AUFK), WBS (PRPS/PROJ), profit centre (CEPC valid
on posting date), amounts numeric, 3rd-currency amount only where the company code has ROCUR.
File: no existing document `ZJVA000ppp` for the company code / year; company codes with ROCUR
have 3rd-currency amounts; every account nets to zero in HSL, KSL and OSL. Any error → nothing
is posted, every valid row shows *Not posted - file has errors*.

### 4.5 ACDOCA line
Field by field in NOTES.md. Key: RLDNR 0L, RBUKRS, GJAHR, BELNR `ZJVA000` + period, DOCLN
1..n. Markers: BLART ZJ, AWTYP ZJVA, AWREF = BELNR, AWORG = BUKRS+GJAHR, MIG_SOURCE U,
SDM_VERSION 05, USNAM, TIMESTAMP. Amounts: HSL/KSL/OSL from the file, TSL = WSL = HSL, FCSL by
RFCCUR match, DRCRK from the sign.

### 4.6 Database update
`INSERT acdoca FROM TABLE @lt ACCEPTING DUPLICATE KEYS` per document; `COMMIT WORK` on
sy-subrc 0, else `ROLLBACK WORK`. `AUTHORITY-CHECK F_BKPF_BUK` activity 01 per company code.
Undo: `DELETE FROM acdoca` on RLDNR 0L + BLART ZJ + AWTYP ZJVA + selection; COMMIT per company
code.

## 5. Test scenarios

| # | Input | Expected | Actual |
|---|---|---|---|
| 1 | Recon export of one company code / period, 10 columns, no cost objects, test run | Every row *Test - would be posted*; one document; DOCLN 1..n; posting date = last day of the period | |
| 2 | Same file, update run | Rows *Posted*; SE16H ACDOCA `BELNR ZJVA000ppp`: lines present with VNAME/EGRUP/RECID, BLART ZJ, AWTYP ZJVA; FB03 cannot open it (expected) | |
| 3 | Recon re-run, cut-off = tomorrow | Differences for that company code / period = 0 | |
| 4 | Same file uploaded again | All rows *Error: Document ... already exists - run the undo first*; nothing posted | |
| 5 | Undo, test then update, for that company code / year / period | Count equals the posted lines; after update SE16H shows none | |
| 6 | One amount edited so an account does not net to zero | All rows of that account *Error: Account ... does not net to zero*; nothing posted | |
| 7 | Company code OSL (ROCUR INR), column 10 empty | Every row of the document *Error: ... has third currency INR - column 10 is empty* | |
| 8 | Company code BML (no ROCUR), a value in column 10 | Row *Error: ... has no third currency - column 10 must be empty* | |
| 9 | Cost centre valid, profit centre blank | PRCTR filled from CSKS, SEGMENT from CEPC, visible in the list | |
| 10 | WBS element typed with separators | Found in PRPS, PS_POSID shown; internal numbers filled (hidden columns) | |
| 11 | Period 0 row | Posting date = first day of the fiscal year | |
| 12 | User without F_BKPF_BUK 01 for the company code, update run | Rows *Failed: No authorization ...*; nothing posted | |

## 6. Open points
`ASSUMPTIONS_AND_QUERIES.md` items 1 (T003 ZJ), 2 (MIG_SOURCE U), 3 (marker fields for GR),
7 (3rd currency hard error) decide behaviour; the rest are confirmations.
