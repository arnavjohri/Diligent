# Test case 1 — OVL / 2022 / period 001 (03/11/26)

| File | What |
|---|---|
| `recon_OVL_2022_001_diff_rows.txt` | `ZFI_ACDOCA_JVSO1_RECON` output for OVL 2022 001, the 172 rows with Diff = X, as pasted by Arnav. Whitespace-separated, SAP amount format |
| `build_testfile.py` | parses the rows, checks net-zero per account, writes the upload workbook **in Excel's own package layout** (relative relationship targets, shared strings). `python3 -I build_testfile.py <rows.txt> <out.xlsx>` |
| `ZFI_ACDOCA_JVA_ALIGN_OVL_2022_001.xlsx` | the upload file: 15 columns, 172 data rows, amounts = recon *To Post* columns, cost objects blank |

## Pre-check result (script output)

```
rows read: 172 / rows with an amount to post: 172
accounts touched: 40; accounts NOT netting to zero: 0
grand totals LC/GC/3C: 0.00 0.00 0.00
documents: OVL 2022 1
rows with venture blank but recovery indicator filled: 11
distinct ventures: 24 · recovery indicators: BR CB CP NB
```

The 11 venture-blank rows with a recovery indicator (e.g. account 190598 RI CP) are why the
upload's RI rule was changed on 03/11/26: RI and equity group are now checked against the
company code's 0L lines of the year, a venture is not required.

## Expected results

| Step | Expect |
|---|---|
| Test run | 172 rows *Test - would be posted*, 0 errors, 0 skipped; status line "172 lines would be posted in 1 documents" |
| Document | `ZJVA000001`, DOCLN 1–172, posting date = last day of period 001 of FY 2022 = **30.04.2021** if OVL's fiscal year variant is V3 (April–March) |
| Update run | 172 rows *Posted*; SE16H ACDOCA RBUKRS OVL, GJAHR 2022, BELNR ZJVA000001 → 172 lines, ΣHSL = 0, ΣKSL = 0 |
| Recon re-run, OVL 2022 001, cut-off = tomorrow | 0 rows with differences for this company code / period |
| Undo (test, then update) OVL 2022 001 | "172 alignment lines would be deleted" / "172 alignment lines deleted"; SE16H empty |

Possible first-run surprises and what they mean: *Company code OVL has third currency … column 10
is empty* → OVL's 0L lines carry a ROCUR after all; tell me the value. *Equity group … not
defined for venture …* → T8JG does not hold that venture / group pair; tell me which.

## 03/11/26, first upload attempt on OCD: *Unable to load worksheet*
Raised by SAP's `CL_FDT_XL_SPREADSHEET`, not by the program (the program's own messages are
different). Cause: the first workbook came from openpyxl, whose package differs from an
Excel-saved one — the worksheet relationship target is absolute (`/xl/worksheets/sheet1.xml`)
and text cells are inline strings. The builder now writes the package the way Excel does; the
file read back cleanly with 172 rows, sums zero. Fallback for any other generated .xlsx: open it
in Excel and *Save As* .xlsx — Excel rewrites the package.

## 03/11/26, second attempt: *The file has no data rows below the heading*
The package now loads, but `CL_FDT_XL_SPREADSHEET` handed back no data rows. Two suspects: the
hand-built package, or the heading texts ("G/L Account", "Amount 3rd Currency"), which the class
converts into ABAP component names. Done in response: (1) the test file now has plain headings
(`COMPANY_CODE` … `LINE_TEXT`); (2) the program reports what the class returned (rows, columns,
first column name) and, when that is nothing, reads the file a second time through Excel on the
PC with `TEXT_CONVERT_XLS_TO_SAP`, the reader OVL's other uploads use. The status message now
names both results, e.g. `class: worksheet Upload, 0 rows, 15 columns, first column
COMPANY_CODE, 0 data rows kept; Excel/OLE reader: 172 rows, 172 data rows kept`.

## Test case 1a — one account first (03/11/26)
`ZFI_ACDOCA_JVA_ALIGN_OVL_2022_001_acct30434.xlsx`: the two rows of account 30434 only
(BD1112 / NE1 / NB −431.25 LC −6.05 GC, and the blank-venture offset +431.25 / +6.05).
Expected: test run 2 rows *Test - would be posted*; update run document `ZJVA000001` with
DOCLN 1 and 2; recon for OVL 2022 001 with cut-off = tomorrow shows account 30434 with zero
difference on both rows. **Before the full 172-row file: run Undo for OVL / 2022 / 001** —
the document `ZJVA000001` already exists after this test and the full file would be rejected
(and would double-post the two rows if it were not).
