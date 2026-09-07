# Technical Specification — ZSD_EXC_APPR_ADHESIVE

Locked build contract: `BUILD_SPEC_141A.md`. Functional spec: `fs/141A_extract.md`
(WRICEF 141.A, V.01, 24.08.2026, prepared by Sanjay Modhvadiya). Open functional
questions: `ISSUES.md`.

## 1. Document control

| Item | Value |
|---|---|
| Program | `ZSD_EXC_APPR_ADHESIVE` |
| Object type | Executable report (type 1), screen-free |
| Title | Exceptional Approval Report - Adhesives |
| Module | SD |
| WRICEF | 141.A |
| Client | Astral Limited |
| Project | UDAY |
| Author | Arnav Johri, Associate Consultant, Diligent Tech India Pvt. Ltd. |
| Related FS | WRICEF 141.A — Exceptional approval format, Adhesives, V.01, 24.08.2026 |
| Build contract | `BUILD_SPEC_141A.md` (wins over the FS where the two disagree) |
| ALV | `REUSE_ALV_GRID_DISPLAY_LVC`, full screen, hand-built `LVC_T_FCAT` |
| Shipping | PASTE. Screen-free, so a ZIP is technically possible, but hand-written
abapGit XML has never imported successfully on this landscape — see `CLAUDE.md`. |
| Transport | `<TR to be filled by Arnav>` |
| Date | 02.09.2026 |

---

## 2. Purpose

Exceptional credit approvals for Adhesives customers are recorded today as free-form
"Additional Information" against the business partner's credit management data
(BP → Further Information → Information Category → Additional Information, table
`BP3100`). There is no report over this data. This program selects a set of
customers by company code, sales organisation and customer group, retrieves their
exceptional-approval rows for a chosen information category, information type and
approval-date range, and for every row shows:

- the customer's actual credit limit in the chosen credit segment,
- the customer's actual outstanding balance **as it stood on the commitment date**
  quoted in the approval row's free text,
- the resulting non-fulfilment amount and default percentage, and
- a Fulfilled / Not Fulfilled status.

No data is created, changed or uploaded — the FS explicitly excludes a mass-upload
program (§1.2 of the FS). This is a read-only list.

---

## 3. Selection screen

Two framed blocks, `TEXT-001` "Exceptional Approval Data" and `TEXT-002`
"Organisational Data".

| Field | Type | Obligation | F4 source | Description |
|---|---|---|---|---|
| `S_KUNNR` | SELECT-OPTIONS on `KNVV-KUNNR` | Optional | standard DDIC (customer search helps) | Customer number |
| `P_INFCAT` | PARAMETER, `UKM_INFOCAT-INFOCATEGORY` | **Obligatory** | custom — distinct `INFOCATEGORY` from `UKM_INFOCAT` | Information category |
| `P_INFTYP` | PARAMETER, `UKM_INFOTYP-INFOTYPE` | **Obligatory** | custom — distinct `INFOTYPE` from `UKM_INFOTYP` `WHERE INFOCATEGORY = P_INFCAT` | Information type |
| `S_DATE` | SELECT-OPTIONS on `BP3100-DATEFR` | **Obligatory** | standard (date) | Exceptional approval date (from) |
| `P_BUKRS` | PARAMETER, `KNB1-BUKRS` | **Obligatory** | standard DDIC | Company code |
| `S_VKORG` | SELECT-OPTIONS on `KNVV-VKORG` | **Obligatory** | standard DDIC | Sales organisation |
| `S_KVGR1` | SELECT-OPTIONS on `KNVV-KVGR1` | Optional | standard DDIC | Customer group 1 |
| `S_KVGR2` | SELECT-OPTIONS on `KNVV-KVGR2` | Optional | standard DDIC | Customer group 2 |
| `P_SEGMNT` | PARAMETER, `UKMBP_CMS_SGM-CREDIT_SGMNT` | **Obligatory**, default `2000` | standard DDIC | Credit segment |

`P_SEGMNT` is **not in the FS**. `UKMBP_CMS_SGM` (Actual Credit Limit) is keyed by
partner **and** credit segment, so without a segment the credit limit for a given
customer is ambiguous. See §7 deviation 7 / `ISSUES.md` #16.

### 3.1 F4 help behaviour

- **`P_INFCAT`**: reads the distinct `INFOCATEGORY` values from `UKM_INFOCAT` and
  offers them via `F4IF_INT_TABLE_VALUE_REQUEST`. No text table is read — its name
  is unconfirmed on this landscape — so only the key value is shown.
- **`P_INFTYP`**: dependent on `P_INFCAT`. The routine reads what the user has typed
  into `P_INFCAT` directly off the screen (`DYNP_VALUES_READ`), so the dependent F4
  works even before the user presses Enter. If `P_INFCAT` is still blank, the user
  gets the message "Enter the information category first" and no F4 list — never a
  dump.

### 3.2 Validation (`AT SELECTION-SCREEN`)

| Field | Check | On failure |
|---|---|---|
| `P_BUKRS` | exists in `T001` | Error on the field: "Company code does not exist" |
| `P_INFCAT` | exists in `UKM_INFOCAT` | Error on the field: "Information category does not exist" |
| `P_INFTYP` | exists in `UKM_INFOTYP` for the chosen `P_INFCAT` (checked only once `P_INFCAT` is filled, so one mistake does not raise two errors) | Error on the field: "Information type not valid for this category" |
| `P_SEGMNT` | **not checked** | the customizing table holding valid credit segments is not confirmed on this landscape (build spec §1.2) |

---

## 4. Tables and views read

| Table | Used for | Read by |
|---|---|---|
| `KNB1` | Company-code customers for `P_BUKRS`, restricted by `S_KUNNR` | `F_GET_CUSTOMERS` |
| `KNVV` | Sales-area filter (`S_VKORG` / `S_KVGR1` / `S_KVGR2`); also the sole customer key still used once dedupe has run | `F_GET_CUSTOMERS` |
| `BP3100` | The driver: exceptional-approval "Additional Information" rows for the chosen information category, information type and approval-date range | `F_GET_APPROVALS` |
| `KNA1` | Customer name (`NAME1`) | `F_GET_NAMES` |
| `UKMBP_CMS_SGM` | Actual credit limit, keyed by partner + credit segment | `F_GET_CREDIT_LIMITS` |
| `T001` | Company-code currency (ALV currency reference); also the `P_BUKRS` existence check | `F_GET_COMPANY_CURRENCY`, `AT SELECTION-SCREEN ON P_BUKRS` |
| `UKM_INFOCAT` | F4 list and existence check for `P_INFCAT` | F4 handler, `AT SELECTION-SCREEN ON P_INFCAT` |
| `UKM_INFOTYP` | F4 list (dependent on `P_INFCAT`) and existence check for `P_INFTYP` | F4 handler, `AT SELECTION-SCREEN ON P_INFTYP` |
| `BSID` | Customer open items **as they stand today** | `F_GET_OPEN_ITEMS` |
| `BSAD` | Customer items cleared **since** the commitment date — needed because an item open on the commitment date but cleared afterwards must still count as open on that date | `F_GET_OPEN_ITEMS` |

No table other than these ten is touched. There is no read against a sales
hierarchy table for L4/L5/L6 — see §6, step 6.

---

## 5. Processing logic

Execution order, `START-OF-SELECTION`:

```
F_GET_CUSTOMERS → F_GET_APPROVALS → F_GET_NAMES → F_GET_CREDIT_LIMITS
→ F_GET_COMPANY_CURRENCY → F_GET_HIERARCHY → F_GET_OPEN_ITEMS
→ F_BUILD_OUTPUT                                    (END-OF-SELECTION) → F_DISPLAY_ALV
```

Every database read happens once, outside any loop, and every `FOR ALL ENTRIES` is
guarded by an `IS NOT INITIAL` check on its driver table.

### 5.1 `F_GET_CUSTOMERS`

Builds the customer set the whole report runs against. Reads `KNB1` for the company
code and customer range, then reads `KNVV` for the sales organisation and customer
group filters against that customer list. Because `KNVV` is sales-area dependent, a
customer extended to several sales areas comes back more than once from that read —
the routine sorts by customer and runs `DELETE ADJACENT DUPLICATES COMPARING KUNNR`
so each customer appears **exactly once** downstream, regardless of how many sales
areas match. If either read comes back empty, the user sees "No customers match the
selection" and the report stops cleanly (`LEAVE LIST-PROCESSING`) — no dump.

### 5.2 `F_GET_APPROVALS`

Reads `BP3100` for the customer set built in 5.1, filtered by information category,
information type and the approval-date range. This is the row that drives everything
downstream — one BP3100 row becomes one output row. Also builds a deduplicated list
of the partners that actually carry an approval, so the smaller downstream reads
(§5.3, §5.4) run over the minimum key set rather than the full customer set from 5.1.
Empty result: "No exceptional approvals found for the selection", report stops.

### 5.3 `F_GET_NAMES`

Customer name (`KNA1-NAME1`) for the partners found in 5.2. A partner with no `KNA1`
row is not treated as an error — the name is simply left blank in the output.

### 5.4 `F_GET_CREDIT_LIMITS`

Actual credit limit (`UKMBP_CMS_SGM-CREDIT_LIMIT`) for the partners found in 5.2,
restricted to the credit segment entered on the selection screen (`P_SEGMNT`). A
partner with no limit row in that segment is not an error — the limit is left at
zero and the percentage calculation in 5.9 guards against dividing by it.

### 5.5 `F_GET_COMPANY_CURRENCY`

One `SELECT SINGLE` for `T001-WAERS` of `P_BUKRS`. This is the currency shown against
every amount column in the ALV. `P_BUKRS` is already validated on the selection
screen, so a failure here is defensive only — the report still runs, the amounts are
shown without a currency, and the user gets a warning.

### 5.6 `F_GET_HIERARCHY` — background call to the hierarchy report

Functional confirmed on 07/09/26 that the hierarchy report is to be run in background
and its output read, and that the program name printed in the FS is wrong and will be
corrected. The call is therefore built in full:

1. `TRDIR` is read for `GC_HIER_PROG` (`ZSD_CUSTOMER_DATA`). Unless it exists **and** is
   `SUBC = '1'` (executable), the FORM issues one status message and returns with the
   columns blank, and no `SUBMIT` is attempted.
2. The sales organisations from `S_VKORG` are copied into an `RSPARAMS` selection table
   under the name `GC_HIER_SELNAME`.
3. `CL_SALV_BS_RUNTIME_INFO` is armed with `display = abap_false`, the report is called
   with `SUBMIT (GC_HIER_PROG) WITH SELECTION-TABLE ... AND RETURN`, and its ALV result
   is taken with `GET_DATA_REF`. `CLEAR_ALL` runs on every path, so this report's own
   ALV is never swallowed by a capture left armed.
4. The result rows are read by field **name** through `ASSIGN COMPONENT`, so the callee
   structure does not have to be known at compile time, and are merged into `GT_CUST`
   on customer number after `CONVERSION_EXIT_ALPHA_INPUT`.

All six source names live in one `CONSTANTS` block, `GC_HIER_*`, immediately above the
selection screen. Correcting any of them is a change to that block and nothing else.

**Program name confirmed 07/09/26.** `GC_HIER_PROG` is `ZSD_CUSTOMER_DATA`, not the
`SAPLSLVC_FULLSCREEN` the FS printed. That name was the generic ALV full-screen function
group, `TRDIR` type `F`, which is neither a report nor `SUBMIT`-able. The guard now passes
and the call genuinely runs.

The remaining four constants are **placeholders**, not confirmed values, and nothing else in
the program guesses them. A wrong one degrades, it never dumps: a wrong select-option name
makes the callee run unfiltered (slower, same names reported, because the merge is on
customer key); a wrong customer field means nothing keys, and a status message says so
rather than leaving columns that look like missing master data; a wrong level field leaves
that level blank. See §7 deviation 1 / `ISSUES.md` #1 for how to read the real names off the
report's own layout.

**Watch in functional testing.** If `ZSD_CUSTOMER_DATA` carries an obligatory selection
field other than sales organisation, the `SUBMIT` stops on its own selection screen. That is
the one case the guards cannot cover, because its screen is not known here.

### 5.7 `F_GET_OPEN_ITEMS`

Two things happen here, in order:

1. **Parse every commitment date once.** `BP3100-TEXT` is free text, so each
   approval row's commitment date is extracted by `F_PARSE_COMMIT_DATE` (§5.7.1) and
   the result cached in `GT_CDATE`, keyed by partner + counter. `F_BUILD_OUTPUT`
   (§5.9) reads this cache rather than parsing the text a second time.
2. **Read the open items once for the whole customer set**, bounded by the lowest and
   highest commitment date found across all rows (`lv_min_date` / `lv_max_date`). If
   no row parsed to a usable date, this whole step is skipped — there is no "as on"
   date to report against.
   - `BSID` (items open **now**) up to `lv_max_date` on posting date.
   - `BSAD` (items **cleared since**) up to `lv_max_date` on posting date and after
     `lv_min_date` on clearing date — an item cleared after a customer's commitment
     date was still open on that date and must still count.
   - Both guarded by `IS NOT INITIAL`; neither is filtered by fiscal year (`GJAHR`) —
     see §7 deviation 2 / `ISSUES.md` #4.

No `SELECT` runs inside a loop anywhere in this FORM or the two it drives.

#### 5.7.1 `F_PARSE_COMMIT_DATE` (helper, called from 5.7)

Scans the free text token by token (split on spaces), normalising `/` and `-`
separators to `.`. It accepts `DD.MM.YYYY`, `DD/MM/YYYY`, `DD-MM-YYYY` and an
unseparated 8-digit `YYYYMMDD`, ignoring any surrounding words. The first token that
parses to a **calendar-valid** date (via `F_CHECK_DATE`, leap-year aware) wins;
`00000000` is never accepted. If nothing in the text parses, the routine returns an
initial date — it never raises a message and never dumps. A row with an unparsed
commitment date still appears in the ALV: the free text is shown as-is in Commitment
Text, and Commitment Date, Actual OS, Non-Fulfilment Amount, Default % and Status are
all left blank rather than showing a number computed against nothing.

### 5.8 `F_CALC_OPEN_AMOUNT` (helper, called from `F_BUILD_OUTPUT`, §5.9)

Pure in-memory arithmetic — no database access. For one customer and one parsed
commitment date, it sums:

- every `BSID` row for that customer with `BUDAT <= commitment date` (still open
  today, and was already posted by the commitment date), and
- every `BSAD` row for that customer with `BUDAT <= commitment date AND
  AUGDT > commitment date` (posted by the commitment date, cleared afterwards — so
  still open **on** that date even though it is closed today).

`SHKZG = 'S'` (debit) adds to the running total, `SHKZG = 'H'` (credit) subtracts.
Both source tables are `SORTED` on customer number, so this is a keyed read per
output row, never a linear scan of the whole item set.

### 5.9 `F_BUILD_OUTPUT`

Assembles one output row per `BP3100` approval row (5.2), in customer/approval order:

- **Customer / name / L4-L6**: looked up from the tables built in 5.1, 5.3 and 5.6.
- **Approval Month** = `DATEFR+4(2) && '/' && DATEFR(4)` — MM/YYYY built from the
  approval-date-from field.
- **Approval Type**: left blank — no source field is named in the FS. See §7
  deviation 5 / `ISSUES.md` #2.
- **Approval Date From/To, Exceptional Amount, Commitment Text**: taken directly from
  the `BP3100` row.
- **Commitment Date**: looked up from the `GT_CDATE` cache built in 5.7.1.
- **Actual Credit Limit**: looked up from 5.4 (zero if the customer has none in this
  segment).
- If the commitment date parsed successfully:
  - **Actual OS on Commitment Date** = `F_CALC_OPEN_AMOUNT` (5.8).
  - **Non-Fulfilment Amount** = Actual OS − Actual Credit Limit.
  - **Default %** = `(Non-Fulfilment Amount × 100) / Actual Credit Limit`, computed
    in a wider packed field first so an extreme ratio cannot overflow the 7,2 output
    field and short dump; a limit of exactly zero leaves the percentage blank rather
    than dividing by zero.
  - **Status**: `Not Fulfilled` when Non-Fulfilment Amount `> 0`, otherwise
    `Fulfilled` — including exactly zero. The FS defines the status only for a
    strictly positive and a strictly negative amount; zero is treated as Fulfilled.
    See §7 deviation 8 / `ISSUES.md` #12.
- If the commitment date did **not** parse: Actual OS, Non-Fulfilment Amount,
  Default % and Status are all left blank. The row is not dropped.
- **Currency** (`WAERS`, hidden): the company-code currency from 5.5, carried on
  every row as the ALV's currency reference field for the four amount columns.

### 5.10 `F_DISPLAY_ALV`

Builds the LVC field catalogue by hand, one entry per column (via the `F_ADD_FCAT`
helper), in the exact order of `TY_OUTPUT`. The four amount columns (Exceptional
Amount, Actual Credit Limit, Actual OS, Non-Fulfilment Amount) carry `WAERS` as their
currency reference field; `WAERS` itself is marked `NO_OUT` — it drives currency
formatting but is not a business column. The grid is zebra-striped with optimized
column widths and shown full-screen via `REUSE_ALV_GRID_DISPLAY_LVC` (`I_SAVE = 'A'`,
so a layout variant can be saved). If the grid call fails, the user sees "The report
list could not be displayed" — no dump. If there is nothing to show at all, the user
sees "No data to display for the selection" before the grid is even called.

---

## 6. Output layout

One row per exceptional-approval record (`BP3100` row), 18 visible columns plus one
hidden currency-reference column. Column order matches `TY_OUTPUT` and the ALV field
catalogue.

| # | Heading | Field | Currency ref | Notes |
|---|---|---|---|---|
| 1 | Customer Code | `KUNNR` | — | |
| 2 | Customer Name | `NAME1` | — | blank if no `KNA1` row |
| 3 | L4 Name | `L4_NAME` | — | **always blank** — stub, §5.6 |
| 4 | L5 Name | `L5_NAME` | — | **always blank** — stub, §5.6 |
| 5 | L6 Name | `L6_NAME` | — | **always blank** — stub, §5.6 |
| 6 | Approval Month | `EXC_MONTH` | — | MM/YYYY from `DATEFR` |
| 7 | Exception Number | `EXC_NO` | — | `BP3100-COUNTER` |
| 8 | Approval Type | `EXC_TYPE` | — | **always blank** — no source field, §5.9 |
| 9 | Approval Date From | `DATE_FROM` | — | `BP3100-DATEFR` |
| 10 | Approval Date To | `DATE_TO` | — | `BP3100-DATETO` |
| 11 | Exceptional Amount | `EXC_AMNT` | `WAERS` | `BP3100-AMNT` |
| 12 | Commitment Date | `COMMIT_DATE` | — | blank if unparseable |
| 13 | Commitment Text | `COMMIT_TEXT` | — | raw `BP3100-TEXT`, always shown |
| 14 | Actual Credit Limit | `CREDIT_LIMIT` | `WAERS` | for `P_SEGMNT`; zero if none |
| 15 | Actual OS on Commit Date | `ACT_OS` | `WAERS` | blank if commitment date unparseable |
| 16 | Non-Fulfilment Amount | `NON_FULFIL` | `WAERS` | Actual OS − Actual Credit Limit |
| 17 | Default % Non-Fulfilment | `DEF_PERC` | — | blank when limit = 0 or commitment date unparseable |
| 18 | Status | `STATUS` | — | Fulfilled / Not Fulfilled; blank when commitment date unparseable |
| — | Currency | `WAERS` | — | hidden (`NO_OUT`); company-code currency, drives columns 11/14/15/16 |

---

## 7. Assumptions and deviations from the FS

Every row below carries an `" ASSUMPTION:` comment at the matching point in the
source and a cross-reference to the numbered item in `ISSUES.md`.

| # | FS says | Build does | Why | `ISSUES.md` |
|---|---|---|---|---|
| 1 | L4/L5/L6 from `SAPLSLVC_FULLSCREEN` | Background `SUBMIT` of **`ZSD_CUSTOMER_DATA`** + ALV capture. Program name confirmed 07/09/26; its select-option and ALV field names are still placeholders in `GC_HIER_*` | `SAPLSLVC_FULLSCREEN` is the generic ALV function group, `TRDIR` type `F`, not an executable report | #1 part-open |
| 2 | Actual OS from `BSID` by `GJAHR` | `BSID` + `BSAD`, bounded by `BUDAT`/`AUGDT`, no `GJAHR` filter | `BSID` holds items open **now**; an item cleared after the commitment date must still count as open on that date. Open items also span fiscal years, so a `GJAHR` filter drops valid rows | #4 |
| 3 | Fetch `WRBTR` | `WRBTR` is selected for reference; the arithmetic uses `DMBTR` | `WRBTR` is document currency; the credit limit is not. `DMBTR` (company-code currency) is the comparable figure. Switching back is a one-line change | #4 |
| 4 | `REBZG` blank / not blank as two separate steps | Single read, `REBZG` selected but not filtered | The two FS steps together are simply "all items" — filtering on `REBZG` would not change the sum | related to #4 |
| 5 | Exceptional Approval Type column, values Credit Limit / Order / Both | Column present, always blank | No source field is named in the output mapping | #2 |
| 6 | Commitment date "fetched" from `TEXT` | Defensive multi-format parse, initial on failure | `BP3100-TEXT` is free text with no agreed entry format | #3 |
| 7 | No credit segment on the selection screen | `P_SEGMNT` added, obligatory, **defaults to 2000** | `UKMBP_CMS_SGM` is keyed by partner **and** credit segment — the credit limit is ambiguous without one. Segment 2000 confirmed by functional 07/09/26 | #16 closed |
| 8 | Status defined only for (+) and (−) non-fulfilment | Exactly zero is treated as **Fulfilled** | The FS gives no rule for the boundary case | #12 |
| 9 | KNVV-keyed customer selection | Result deduplicated to one row per customer | A customer extended to several sales areas would otherwise multiply rows | #13 |
| 10 | Required "Date" selection field, no table/field stated | Applied to `BP3100-DATEFR` (approval date from) | The output mapping's only date the FS ties to an approval, as opposed to a commitment or posting date | #11 |
| 11 | "Authorization TBD" | No authorization object built | Nothing was confirmed to check against; see open point below | #15 |

---

## 8. Open points still needing a functional answer

Ranked by what changes a number or a column on the report, not by `ISSUES.md` order.

1. **`ISSUES.md` #1 — L4/L5/L6 source.** The only column with no data at all. Needed:
   the real table/field (KNVP partner functions? a customer hierarchy table? an HR
   org level?) or a report name that can actually be read/submitted.
2. **`ISSUES.md` #4 — as-on-date logic, currency, GJAHR.** The build's `BSID`+`BSAD`
   approach and its use of `DMBTR` are the technical team's best read of "actual OS as
   on the commitment date" from a document-currency, GJAHR-scoped FS instruction that
   cannot literally be correct (see deviations 2–4 above). Confirmation removes the
   `" ASSUMPTION:` tags but does not by itself change any code unless the answer
   differs from what is built.
3. **`ISSUES.md` #2 — Approval Type source field.** Which `BP3100` field (or another
   source) carries Credit Limit / Order / Both.
4. **`ISSUES.md` #3 — commitment date format.** Confirm the agreed entry convention
   for `BP3100-TEXT` (today: defensive multi-format parse) and whether an unparseable
   row should be flagged to the user in some way beyond the blank columns it already
   gets.
5. ~~**`ISSUES.md` #16 — credit segment.**~~ **Closed 07/09/26.** Functional confirmed
   segment `2000`. `P_SEGMNT` now defaults to it and stays overridable.
6. **`ISSUES.md` #13 — sales-area duplication.** Confirm one row per customer
   (current build) is the wanted behaviour, as opposed to one row per sales area.
7. **`ISSUES.md` #12 — zero non-fulfilment boundary.** Confirm `Fulfilled` (current
   build) is correct for an exact match between outstanding and limit.
8. **`ISSUES.md` #15 — authorization.** No object or check is built. Needed: which
   authorization object (company code? credit segment?) should gate this report.
9. **`ISSUES.md` #11 — "Date" selection field.** Confirm approval date from (current
   build, on `BP3100-DATEFR`) is the intended filter, as opposed to commitment date or
   posting date.

`ISSUES.md` items #5, #6, #8, #9 and #10 belong to WRICEF 141.B (Paints) and do not
apply to this object.

---

## 9. Unit test scenarios

| # | Scenario | Input | Expected result |
|---|---|---|---|
| 1 | FS sample row 1 — customer 1009024, exceptional amount driving a positive non-fulfilment | Customer 1009024, credit limit 100,000, actual OS on commitment date 125,000 | Non-Fulfilment Amount = 25,000; Default % = 25.00; Status = Not Fulfilled |
| 2 | FS sample row 2 — customer with actual OS below the limit | Customer with credit limit 100,000, actual OS on commitment date 98,000 | Non-Fulfilment Amount = −2,000; Default % = −2.00; Status = Fulfilled |
| 3 | Empty selection | `P_BUKRS` / `S_VKORG` combination that matches no `KNB1`/`KNVV` row | Message "No customers match the selection"; report stops, no ALV shown |
| 4 | Zero credit limit | Approval row for a customer with no `UKMBP_CMS_SGM` row in `P_SEGMNT` (or `CREDIT_LIMIT = 0`) | Actual Credit Limit = 0; Default % left blank (no division by zero); Non-Fulfilment Amount still computed as Actual OS − 0; Status set from that amount |
| 5 | Unparseable commitment date | `BP3100-TEXT` containing no recognisable date token (e.g. free-form remarks only) | Row still appears; Commitment Text shows the raw text; Commitment Date, Actual OS, Non-Fulfilment Amount, Default % and Status are all blank |
| 6 | Customer in more than one sales area | One `KUNNR` extended to two `VKORG` values that both satisfy `S_VKORG` | Customer appears **exactly once** in `GT_CUST` and therefore at most once per approval row — never duplicated by sales area |
| 7 | No exceptional approvals for a valid customer set | Customers found in `KNB1`/`KNVV`, but no `BP3100` row matches `P_INFCAT`/`P_INFTYP`/`S_DATE` | Message "No exceptional approvals found for the selection"; report stops |
| 8 | Company code that does not exist | `P_BUKRS` value absent from `T001` | Error on the selection screen: "Company code does not exist"; cursor stays on the field |
| 9 | Information type not valid for the category | `P_INFTYP` filled, but no `UKM_INFOTYP` row for that `INFOCATEGORY`/`INFOTYPE` pair | Error on the selection screen: "Information type not valid for this category" |
| 10 | Item cleared after the commitment date | A `BSID` item as of the commitment date is later cleared (now only in `BSAD`), with `AUGDT` after the commitment date | Still counted as open in `F_CALC_OPEN_AMOUNT` via the `BSAD` leg — Actual OS on Commitment Date includes it |
