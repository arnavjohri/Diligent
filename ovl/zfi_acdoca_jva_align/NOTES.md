# ZFI_ACDOCA_JVA_ALIGN — JVA alignment of ACDOCA ledger 0L, Excel upload

**Project:** OVL (ONGC Videsh) · system OCQ/500 · package/TR: TBD
**Purpose:** insert the venture / equity group / recovery indicator split that ledger 0L is
missing against the JV ledger, as ACDOCA-only journal entry lines (no BKPF/BSEG), from a
reviewed Excel file. One document per company code / fiscal year / period. Every account in
the file must net to zero, so account balances never change — only their split. Design and
decisions: `ovl/z_jva_alignment/NOTES.md` §6 (02/11/26). Reference program the field map came
from: `ovl/z_jva_alignment/original/Z_JVA_ALIGNMENT.abap`.

**Direct write to ACDOCA.** Same approval point as `ZFI_ACDOCA_VNAME_UPD`: client / functional
sign-off before anything beyond DEV, one company code and one period first, undo mode kept.

## Shipping method
Paste-only. SE38, type 1 executable, no includes, no screen, no GUI status. Source:
`ovl/zfi_acdoca_jva_align/ZFI_ACDOCA_JVA_ALIGN.abap` (1613 lines, 03/11/26). No `original/` —
new object. 03/11/26: first syntax check on OCQ fixed (see ISSUES.md); activation pending.

## Text elements to maintain (SE38 → Goto → Text elements)
Text symbols: `B01` Mode · `B02` Upload · `B03` Undo selection · `B04` Processing.
Selection texts: R_UPL Upload Excel and post · R_DEL Undo: delete alignment lines ·
P_FILE Excel file (.xlsx) · S_BUKRS Company Code · S_GJAHR Fiscal Year · S_POPER Posting Period ·
P_TEST Test run (no database update).

## Excel layout (first worksheet, row 1 headings, columns by position)

| # | Column | ACDOCA | Mandatory | Checked against |
|---|---|---|---|---|
| 1 | Company Code | RBUKRS | yes | T001, TKA02 |
| 2 | Fiscal Year | GJAHR, RYEAR | yes | 4 digits |
| 3 | Posting Period | POPER | yes | 0–16 (0 = carry-forward, posting date = first day of FY) |
| 4 | Joint Venture | VNAME | blank = offset row | T8JV (BUKRS, JVNAME) |
| 5 | Equity Group | EGRUP | blank allowed | T8JG (BUKRS, VNAME, EGRUP); needs a venture |
| 6 | G/L Account | RACCT | yes | SKA1 + SKB1, leading zeros added |
| 7 | Recovery Indicator | RECID | blank allowed | `JV_JVSO1_ACDOCA`: posted with that venture in that year on ledger 4A (T8JJ columns unconfirmed on OCQ); needs a venture |
| 8 | Amount Local Currency | HSL (TSL, WSL copied) | yes | number, debit +, credit − |
| 9 | Amount Group Currency | KSL | yes | number, in the company code's RKCUR |
| 10 | Amount 3rd Currency | OSL | when the company code's 0L lines carry ROCUR | must be blank otherwise |
| 11 | Cost Center | RCNTR | optional | CSKS valid on the posting date |
| 12 | Order | AUFNR | optional | AUFK |
| 13 | WBS Element | PS_POSID → PS_PSP_PNR, PS_PRJ_PNR, PS_PSPID | optional | PRPS as typed, then without mask separators; PROJ |
| 14 | Profit Center | PRCTR (+ SEGMENT from CEPC) | optional; from CSKS of the cost centre when blank | CEPC valid on the posting date |
| 15 | Line Text | SGTXT | optional | default `JVA alignment YYYY/PPP` |

Columns 1–10 are the recon's key columns and its three *To Post* columns in that order: in
`ZFI_ACDOCA_JVSO1_RECON` hide every other column, save the layout, export, add columns 11–15.
Blank rows are ignored; rows with all three amounts zero are listed as *Skipped*.

## Behaviour
1. **Read** — `cl_gui_frontend_services=>gui_upload` binary, `cl_fdt_xl_spreadsheet`, first
   worksheet, cells by position (same pattern as `kpmg/zpp_forecast_v2` upload).
2. **Row checks** (FORM `parse_row`) — key fields, then company code context (FORM
   `get_company`: T001 fiscal year variant / chart / local currency, TKA02 controlling area,
   RKCUR / ROCUR / RFCCUR from a `SELECT DISTINCT` on the company code's existing 0L lines of
   that year), posting date (`LAST_DAY_IN_PERIOD_GET`; 013–016 → 012; 000 →
   `FIRST_DAY_IN_PERIOD_GET` of 001), account (SKA1 G/L account type, SKB1 MITKZ → KOART A/D/K,
   T030 BSX → M, else S), JVA fields, cost objects, amounts, text.
3. **File checks** (FORM `file_checks`) — document `ZJVA000` + period must not exist yet for
   the company code / year (undo first); company code with ROCUR needs 3rd-currency amounts;
   every account nets to zero in HSL, KSL and OSL. Any failure marks the rows; nothing posts.
4. **Documents** — BELNR `ZJVA000ppp`, DOCLN 1..n in key order, assigned in test mode too.
5. **Post** — `AUTHORITY-CHECK F_BKPF_BUK` activity 01 per company code; `INSERT acdoca FROM
   TABLE ... ACCEPTING DUPLICATE KEYS` per document; `COMMIT WORK` on success, `ROLLBACK WORK`
   on a rejected insert (that document only). Test run marks rows *T* and writes nothing.
6. **Undo** — radio button; needs company code and year; counts (test) or `DELETE FROM acdoca`
   (update) on `RLDNR 0L`, `BLART ZJ`, `AWTYP ZJVA`, the selection ranges; COMMIT per company
   code; classic list output.
7. **Output** — one SALV list of every file row: Excel row, status (Error / Skipped / Test /
   Not posted / Posted / Failed), key, amounts, cost objects, document, line, posting date,
   message. Technical columns (internal WBS numbers, KOART, G/L account type) hidden.

## What each ACDOCA field gets (FORM `build_acdoca_line`)
From the file: RBUKRS, GJAHR (= RYEAR), POPER, RACCT, VNAME, EGRUP, RECID, HSL, KSL, OSL,
RCNTR, AUFNR, PS_POSID, PRCTR, SGTXT. Derived: RLDNR 0L, RRCTY 0, BLART ZJ, AWTYP ZJVA,
AWREF = BELNR, AWORG = BUKRS+GJAHR, BELNR, DOCLN, FISCYEARPER, BUDAT = BLDAT, PERIV, KTOPL,
KOKRS, KOART, GLACCOUNT_TYPE, PS_PSP_PNR, PS_PRJ_PNR, PS_PSPID, SEGMENT, RTCUR = RWCUR = RHCUR
= T001 currency, RKCUR / ROCUR / RFCCUR as on existing lines, TSL = WSL = HSL, FCSL = the
amount whose currency equals RFCCUR, DRCRK from the sign of HSL (KSL when HSL is zero),
MIG_SOURCE U, SDM_VERSION 05, USNAM, TIMESTAMP. Left blank on purpose, as on the migrated
ACDOCA-only lines seen on OCQ: BSTAT, VORGN, BTTYPE, LINETYPE, XSPLITMOD, BUZEI, RMVCT, RASSC,
RFAREA, RBUSA.

## Assumptions (grep `ASSUMPTION` in the source)
- Marker constants (`gc_blart ZJ` not in OBA7, `gc_awtyp ZJVA`, `gc_mig_source U`,
  `gc_sdm_version 05`) — one constants block; `U` pending the MIG_SOURCE domain check.
- Recovery indicator validated against posted JV lines (`JV_JVSO1_ACDOCA`), not against the
  master table T8JJ, whose column names are not confirmed on OCQ.
- Currency keys copied from existing 0L lines, not from configuration.
- Transaction currency = local currency (no RTCUR in the recon key).
- .xlsx only, first worksheet, row 1 headings.

## Gotchas
- `SELECT` inside the row loop for every master-data check — intentional, a file has hundreds
  to a few thousand rows. Run large files in background if needed.
- Changing `gc_blart` or `gc_awtyp` after lines were posted orphans those lines for the undo.
- A file for a period already uploaded is rejected as a whole: run the undo for that company
  code / year / period first, then upload again. Partial re-uploads are not supported.
- Period 000 rows are accepted (posting date first day of the fiscal year). The recon does not
  produce them yet — step 2 of the design.
- `F_BKPF_BUK` activity 01 is required for the update run **and** for the undo.
- The recon run after a posted upload shows the alignment lines (TIMESTAMP = now) only with a
  cut-off date later than today — move `P_CUTDT` forward to verify.

## Run order
1. Recon → layout with the 10 columns → export → review, add cost objects → save as .xlsx.
2. Upload, test run (default): list must show *Test - would be posted* on every valid row.
3. Update run for one company code / one period. SE16H ACDOCA on `BELNR ZJVA000ppp`.
4. Recon again with a later cut-off: differences for that period should be zero.
5. GR data release (functional) — the lines must reach ACDOCU.
6. Anything wrong → Undo for that company code / year / period, correct the file, repeat.
