# ovl/zgr_ct_tasklog — Group Reporting: read the currency translation task log

**Client:** OVL · **System:** OCD 500 (ST05 trace, user SAP_FI, 06.11.2026 12:03) · **Filed:** 06/11/26
· **Requester:** Arnav (chat) — "which CDS view does the CXCD task log read, and give me a program
that reads from it"

## What it is

`ZGR_CT_TASKLOG` — SE38 executable, paste-only. Selection screen → log headers from
`FINCS_LOG_HEADER` (newest first, deleted excluded, at most *Number of latest logs*) → log lines
from CDS view `C_CNSLDTNCRCYTRNSLTNTSKLG` for those logs → one `CL_SALV_TABLE` list, header
fields in front of the line fields. No includes, no screen, no GUI status.

## Where the Fiori task log gets its data (from the ST05 trace, `trace/`)

The task log opened from CXCD is the Group Reporting generic log, OData service
`FIN_CONS_GENERICLOG_SRV` (local registration `ZFIN_CONS_GENERICLOG_SRV_0001`, SAP code only).

| Reader | Source | Purpose |
|---|---|---|
| CXCD itself, `SAPLFC05` | TF533, TF500, TF562, TF570, T100 | Data Monitor customizing. No log data |
| `CL_FINCS_GENERIC_LOG_FACTORY`, `CL_FINCS_CONGR_ACCESS` | `FINCS_LASTLOG`, `FINCS_LOG_HEADER`, CDS `I_CNSLDTNGROUP_3` (SQL view `ICCGROUP3`) | Last log per task, cons group authorisation |
| SADL, entity set `LogHeaderSet` | CDS `FINCS_LOG_HEADER_OLD` (SQL view `FINCSLOGHDR`) | Log header list |
| `CL_FINCS_GENERIC_LOG_DPC_HLP` | `FINCS_LOG_HEADER`, `FINCS_LOG_ITEM`, `FINCS_LOG_MESSAG`, `FINCS_CONTROL`, `FINCS_BUNITT`, `FINCS_ADDLCHARCX` | Header, items, messages, texts |
| SADL, three selects | CDS **`C_CNSLDTNCRCYTRNSLTNTSKLG`** | The currency translation lines: amounts in local / group currency, rate, translation key and method, difference FS item and subitem |

- `CNSLDTNTASKLOGUUID` of the view = `CNSLDTNLOGNUMBER` of `FINCS_LOG_HEADER` — the trace bound
  the same 32-character value (`7C1E520E31821FE1B6A1A9988662571B`) to both, as a character string.
- `ACDOCU` was not read at all while the log was displayed.
- The view is a CDS view entity (no separate SQL view; HANA runs it under the entity name) and
  carries CDS access control: *CDS access control applied* in every statement. A user without the
  group reporting authorisation gets no rows, not an error.
- Its base tables are not visible in the trace. ADT → DDL source, or SE38 `RUTDDLSSHOW2` with
  the entity name, shows them.

## Shipping method

Paste-only: SE38 → create `ZGR_CT_TASKLOG`, type 1 executable, paste
`ovl/zgr_ct_tasklog/ZGR_CT_TASKLOG.abap` (401 lines, 06/11/26, v4). No `original/` — new object.
Not yet syntax-checked on OCD.

## ALV columns 1–23 = the Fiori "Items" export (`test/Items_4_fiori_export_2026-11-06.xlsx`)

Same order and headings as the export, so the two lists compare column for column.

| # | Export heading | View element |
|---|---|---|
| 1 | Consolidation Unit | ConsolidationUnit |
| 2 | Consolidation Unit Desc. | ConsolidationUnitText |
| 3 | Translation Method | CnsldtnCrcyTranslationMethod |
| 4 | Sequence | SequenceNumber |
| 5 | Selection ID | SetIdentificationItem |
| 6 | Item Type (Technical Use Only) | CnsldtnTaskLogItemType |
| 7 | Item Type | CnsldtnTaskLogItemTypeTxt |
| 8 | FS Item | CnsldtnFinancialStatementItem |
| 9 | FS Item Description | FinancialStatementItemText |
| 10 | SI Cat. | SubitemCategory |
| 11 | SI Category Description | SubitemCategoryText |
| 12 | Subitem | Subitem |
| 13 | Subitem Description | SubitemText |
| 14 | Difference Item | CnsldtnCrcyTrnsltnDiffFSItem |
| 15 | Difference Item Desc. | CrcyTrnsltnDiffFinStmntItmTxt |
| 16 | Difference Subitem Desc. | CrcyTrnsltnDiffSubitemTxt |
| 17 | CT Key | CnsldtnCrcyTranslationKey |
| 18 | Exchange Rate | CnsldtnExchangeRate |
| 19 | LC Amount | CnsldtnJrnlEntryAmtInLoclCrcy |
| 20 | GC Amount | CnsldtnJrnlEntryAmtInGrpCrcy |
| 21 | Translation Difference | CalculatedDiffAmount |
| 22 | Reference Amount | CalculatedRefAmount |
| 23 | Reference Exchange Rate Indicator | CnsldtnRefExchangeRateType |

Then: **Crcy Transl. Attrib.** (from `FINCS_FSIASSGMT`, below), local and group currency keys,
difference subitem code, task log UUID, and the log header fields. The
export of 06/11/26 (log of cons group OVL, 3,403 rows) is the comparison baseline.

## FS item assignment join — `FINCS_FSIASSGMT` (v3 → v4, 06/11/26)

Table *FS Item Assignments, Version- and Year-Period-Dependent* (SE16N screenshot in `trace/`).
Key: MANDT, ITCLG (Cons COA, CHAR 2), ITEM (FS item, CHAR 10 ALPHA), IATVS (FS item attributes
version, CHAR 3 ALPHA), FROMYEARPER; plus TOYEARPER. The year periods are CHAR 7 `YYYYPPP`
behind conversion exit PERI7, shown as `PPP.YYYY` — 003.2025 is stored as `2025003`.

No selection fields for it (v4, by request): the chart of accounts is **fixed to `OV`**
(`gc_itclg`), the year period is the **log's own fiscal year + period** concatenated to `YYYYPPP`
(so the log of 003.2025 looks up `2025003`), and the attribute version is open. For every FS item
in the log the program reads all assignment rows of COA OV and takes, per line, the first row
(lowest version, earliest start) whose `FROMYEARPER ≤ period ≤ TOYEARPER`, filling
`SA_CURRENCY_TRANSLATION` into column 24. The SE16N selection with from = to = 003.2025 is the
special case of that. No assignment at all for COA OV → a message, list still shown.

**Test Run** checkbox (block 1, v4): exact filter on `FINCS_LOG_HEADER-ISCNSLDTNTESTRUN` —
blank selects update runs, X selects test runs.

**ASSUMPTION:** the attribute column is `SA_CURRENCY_TRANSLATION`, as named in the request; the
screenshot cuts it at `SA_CURRENCY_TRANSLA…` (data element `FINCS_FSI_CURRENCY_TRANSL…`). If
activation says *Unknown column name*, read the full name from SE11 and fix it in `ty_assg`, the
SELECT and the output structure — four places.

## Text elements to maintain (SE38 → Goto → Text elements)

Text symbol `001` Task log selection. Selection texts: S_GROUP Consolidation Group ·
S_YEAR Fiscal Year · S_PERID Fiscal Period · S_VERS Consolidation Version · S_TASK Consolidation
Task · S_LOGNR Log Number · P_TEST Test Run · P_MAXLG Number of latest logs.

## Gotchas

- Every field name in the program is one the service itself selected in the trace, so an
  *Unknown column name* on activation means the view differs on the target system, not a typo.
  Drop that column from `ty_out` and the SELECT and retry.
- Field list ↔ target type: both SELECTs use `INTO CORRESPONDING FIELDS OF TABLE`, so column
  order does not matter.
- `FOR ALL ENTRIES` compares `cnsldtntaskloguuid` with the header's `cnsldtnlognumber`. If the
  view types the UUID as RAW 16 on the target (the trace says CHAR 32), the syntax check says so
  at that line; convert the log number into a `sysuuid_x16` variable before the SELECT.
- Deleted logs: `DELETION = ' '` is live; the service reads deleted ones with `'X'`.
- Decoder for further ST05 exports: `tools/st05_decode/st05_decode.py` (the `.trc` is an
  LZH-compressed ABAP data cluster; the script unpacks it and writes the records as TSV).
