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
| Date | 02.09.2026, revised 17.09.2026 |

Revision 17.09.2026: L4/L5/L6 field names of `ZSD_CUSTOMER_DATA` resolved at runtime
with the callee's field list shown when nothing maps (§5.6, `ISSUES.md` #26); optional
Division on the selection screen; BSID/BSAD read for the approval partners only; commitment
dates linked to their approval row by position; approval-type column removed and the
commitment-date parse narrowed to DD.MM.YYYY (07.09.2026, notes at the end). Marked
`*BOC By Arnav on 17/09/26` and `07/09/26` in the source.

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
| `P_INFCAT` | PARAMETER, `BP3100-ADDTYPE` | **Obligatory** | custom — distinct `ADDTYPE` from `BP3100` | Information category |
| `P_INFTYP` | PARAMETER, `BP3100-DATA_TYPE` | **Obligatory** | custom — distinct `DATA_TYPE` from `BP3100` `WHERE ADDTYPE = P_INFCAT` | Information type |
| `S_DATE` | SELECT-OPTIONS on `BP3100-DATEFR` | **Obligatory** | standard (date) | Exceptional approval date (from) |
| `P_BUKRS` | PARAMETER, `KNB1-BUKRS` | **Obligatory** | standard DDIC | Company code |
| `S_VKORG` | SELECT-OPTIONS on `KNVV-VKORG` | **Obligatory** | standard DDIC | Sales organisation |
| `S_SPART` | SELECT-OPTIONS on `KNVV-SPART` | Optional | standard DDIC | Division (blank = all divisions; FS reviewer comment, §7 deviation 14) |
| `S_KVGR1` | SELECT-OPTIONS on `KNVV-KVGR1` | Optional | standard DDIC | Customer group 1 |
| `S_KVGR2` | SELECT-OPTIONS on `KNVV-KVGR2` | Optional | standard DDIC | Customer group 2 |
| `P_SEGMNT` | PARAMETER, `UKMBP_CMS_SGM-CREDIT_SGMNT` | **Obligatory**, default `2000` | standard DDIC | Credit segment |

`P_SEGMNT` is **not in the FS**. `UKMBP_CMS_SGM` (Actual Credit Limit) is keyed by
partner **and** credit segment, so without a segment the credit limit for a given
customer is ambiguous. See §7 deviation 7 / `ISSUES.md` #16.

### 3.1 F4 help behaviour

- **`P_INFCAT`**: reads the distinct `ADDTYPE` values from `BP3100` and
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
| `P_INFCAT` | exists as an `ADDTYPE` in `BP3100` | Error on the field: "Information category does not exist" |
| `P_INFTYP` | exists as a `DATA_TYPE` in `BP3100` for the chosen `ADDTYPE` (checked only once `P_INFCAT` is filled, so one mistake does not raise two errors) | Error on the field: "Information type not valid for this category" |
| `P_SEGMNT` | **not checked** | the customizing table holding valid credit segments is not confirmed on this landscape (build spec §1.2) |

---

## 4. Tables and views read

| Table | Used for | Read by |
|---|---|---|
| `KNB1` | Company-code customers for `P_BUKRS`, restricted by `S_KUNNR` | `F_GET_CUSTOMERS` |
| `KNVV` | Sales-area filter (`S_VKORG` / `S_SPART` / `S_KVGR1` / `S_KVGR2`); also the sole customer key still used once dedupe has run | `F_GET_CUSTOMERS` |
| `BP3100` | The driver: exceptional-approval "Additional Information" rows for the chosen information category, information type and approval-date range | `F_GET_APPROVALS` |
| `KNA1` | Customer name (`NAME1`) | `F_GET_NAMES` |
| `UKMBP_CMS_SGM` | Actual credit limit, keyed by partner + credit segment | `F_GET_CREDIT_LIMITS` |
| `T001` | Company-code currency (ALV currency reference); also the `P_BUKRS` existence check | `F_GET_COMPANY_CURRENCY`, `AT SELECTION-SCREEN ON P_BUKRS` |
| `BP3100` | F4 lists and existence checks for `P_INFCAT` (`ADDTYPE`) and `P_INFTYP` (`DATA_TYPE`) | F4 handlers, `AT SELECTION-SCREEN ON P_INFCAT` / `ON P_INFTYP` |
| `BSID` | Customer open items **as they stand today**, for the partners that carry an approval | `F_GET_OPEN_ITEMS` |
| `BSAD` | Customer items cleared **since** the commitment date, same partners — needed because an item open on the commitment date but cleared afterwards must still count as open on that date | `F_GET_OPEN_ITEMS` |
| `ZSD_CUSTEMP_ASSG` | Sales hierarchy: level name (`LNAME`) per customer and level (`LCATEGORY` `L4`/`L5`/`L6`), rows valid today — the same table `ZSD_CUSTOMER_DATA` shows these names from | `F_GET_HIERARCHY` |

No table other than these is touched.

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
code and customer range, then reads `KNVV` for the sales organisation, division and
customer group filters against that customer list (`S_SPART` is optional — blank means
every division). Because `KNVV` is sales-area dependent, a
customer extended to several sales areas comes back more than once from that read —
the routine sorts by customer and runs `DELETE ADJACENT DUPLICATES COMPARING KUNNR`
so each customer appears **exactly once** downstream, regardless of how many sales
areas match. If either read comes back empty, the user sees "No customers match the
selection" and the report stops cleanly (`LEAVE LIST-PROCESSING`) — no dump.

### 5.2 `F_GET_APPROVALS`

Reads `BP3100` for the customer set built in 5.1, filtered by information category
(`ADDTYPE`), information type (`DATA_TYPE`) and the approval-date range. This is the row
that drives everything downstream — one BP3100 row becomes one output row. The result is
sorted by partner, approval date from and counter, so rows group per customer as in the FS
layout and the order is the same on every run. Also builds a deduplicated list of the
partners that actually carry an approval (`GT_PARTNER`), so the downstream reads (§5.3,
§5.4, §5.6, §5.7) run over the minimum key set rather than the full customer set from 5.1.
Empty result: "No exceptional approvals found for the selection", report stops.

`BP3100-PARTNER` is compared directly with the customer number. That holds only where the
business partner and the customer share one number (CVI same-number assignment), which is
tagged `ASSUMPTION` in the source — `ISSUES.md` #18.

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

### 5.6 `F_GET_HIERARCHY` — L4/L5/L6 from `ZSD_CUSTEMP_ASSG`

The FS asks for the names shown by the sales hierarchy report `ZSD_CUSTOMER_DATA` (the FS
printed `SAPLSLVC_FULLSCREEN`, the generic ALV function group; the real name was given on
07/09/26 and its source on 17/09/26). That report does not compute the levels: it reads
table `ZSD_CUSTEMP_ASSG` — one row per customer and level, `LCATEGORY` `L1` to `L6`, `LNAME`
the level name, `STARTVAL`/`ENDVAL` the validity — for the rows valid on `SY-DATUM`, and
shows `LNAME` as `LNAME4` / `LNAME5` / `LNAME6`. This FORM reads the same table the same way:

1. If no partner carries an approval, nothing is read.
2. One `SELECT` of `KUNNR`, `LCATEGORY`, `LNAME` for the approval partners (`GT_PARTNER`,
   `FOR ALL ENTRIES` behind an `IS NOT INITIAL` guard), `LCATEGORY` in `L4`/`L5`/`L6`,
   `STARTVAL <= SY-DATUM <= ENDVAL`.
3. No row at all: status message M18 "No sales hierarchy maintained for the selected
   customers", columns blank, report continues.
4. Otherwise each row's `LNAME` is copied into the customer list under its level. A
   customer with no valid row for a level keeps that level blank. Where a level has more
   than one valid row the last one read wins, as in `ZSD_CUSTOMER_DATA`.

The three level keys are the only source names, constants `GC_LCAT_L4/5/6`. The level-name
fields of `TY_CUST` and `TY_OUTPUT` are typed off `ZSD_CUSTEMP_ASSG-LNAME` so a name is never
truncated.

**History.** 07/09/26: built as a background `SUBMIT` of `ZSD_CUSTOMER_DATA` with the ALV
captured through `CL_SALV_BS_RUNTIME_INFO` and read by placeholder field names. 17/09/26
morning: names resolved at runtime with diagnostics, after functional testing showed the
columns blank. 17/09/26 afternoon: the callee's source showed its fields are `LNAME4`–`LNAME6`
(matching neither the placeholders nor the `L4` token) and that the names are a plain table
read, so the SUBMIT, the capture and the helper `F_HIER_FIELD` were retired — commented out
in the source, not deleted. `ISSUES.md` #1, #26, #27.

### 5.7 `F_GET_OPEN_ITEMS`

Two things happen here, in order:

1. **Parse every commitment date once.** `BP3100-TEXT` is free text, so each
   approval row's commitment date is extracted by `F_PARSE_COMMIT_DATE` (§5.7.1) and
   the result cached in `GT_CDATE`, one row per `GT_APPR` row in the same order.
   `F_BUILD_OUTPUT` (§5.9) reads this cache by position rather than parsing the text a
   second time; PARTNER + COUNTER is not confirmed unique in `BP3100`, so it is not
   used as a key.
2. **Read the open items once for the approval partners** (`GT_PARTNER`, §5.2 — not the
   whole customer set of §5.1, which gives identical figures on a far smaller read),
   bounded by the lowest and highest commitment date found across all rows
   (`lv_min_date` / `lv_max_date`). If no row parsed to a usable date, this whole step
   is skipped — there is no "as on" date to report against.
   - `BSID` (items open **now**) up to `lv_max_date` on posting date.
   - `BSAD` (items **cleared since**) up to `lv_max_date` on posting date and after
     `lv_min_date` on clearing date — an item cleared after a customer's commitment
     date was still open on that date and must still count.
   - Both guarded by `IS NOT INITIAL`; neither is filtered by fiscal year (`GJAHR`) —
     see §7 deviation 2 / `ISSUES.md` #4.
   - Every line is summed: normal receivables, special G/L items and noted items alike.
     The FS draws no line; tagged `ASSUMPTION`, §7 deviation 13 / `ISSUES.md` #19.

No `SELECT` runs inside a loop anywhere in this FORM or the two it drives.

#### 5.7.1 `F_PARSE_COMMIT_DATE` (helper, called from 5.7)

Scans the free text token by token (split on spaces), normalising `/` and `-`
separators to `.`. It accepts `DD.MM.YYYY` — the entry format functional confirmed on
07/09/26 — and `DD/MM/YYYY` / `DD-MM-YYYY` as the same field order with a different
separator, ignoring any surrounding words. The first token that
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
- **Approval Date From/To, Exceptional Amount, Commitment Text**: taken directly from
  the `BP3100` row.
- **Commitment Date**: taken from the `GT_CDATE` cache built in 5.7.1, by position.
- **Actual Credit Limit**: looked up from 5.4 (zero if the customer has none in this
  segment).
- If the commitment date parsed successfully:
  - **Actual OS on Commitment Date** = `F_CALC_OPEN_AMOUNT` (5.8).
  - **Non-Fulfilment Amount** = Actual OS − Actual Credit Limit.
  - **Default %** = `(Non-Fulfilment Amount × 100) / Actual Credit Limit`, computed
    in a wider packed field first so an extreme ratio cannot overflow the 7,2 output
    field and short dump; a limit of exactly zero leaves the percentage at 0.00 rather
    than dividing by zero.
  - **Status**: `Not Fulfilled` when Non-Fulfilment Amount `> 0`, otherwise
    `Fulfilled` — including exactly zero. The FS defines the status only for a
    strictly positive and a strictly negative amount; zero is treated as Fulfilled.
    See §7 deviation 8 / `ISSUES.md` #12.
- If the commitment date did **not** parse: Actual OS, Non-Fulfilment Amount and
  Default % are cleared (they show as 0.00, being packed fields) and Status is left
  blank. The row is not dropped.
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

One row per exceptional-approval record (`BP3100` row), 17 visible columns plus one
hidden currency-reference column (the Approval Type column was removed 07/09/26). Column order matches `TY_OUTPUT` and the ALV field
catalogue.

| # | Heading | Field | Currency ref | Notes |
|---|---|---|---|---|
| 1 | Customer Code | `KUNNR` | — | |
| 2 | Customer Name | `NAME1` | — | blank if no `KNA1` row |
| 3 | L4 Name | `L4_NAME` | — | from `ZSD_CUSTOMER_DATA`, §5.6; blank when that level cannot be mapped |
| 4 | L5 Name | `L5_NAME` | — | from `ZSD_CUSTOMER_DATA`, §5.6; blank when that level cannot be mapped |
| 5 | L6 Name | `L6_NAME` | — | from `ZSD_CUSTOMER_DATA`, §5.6; blank when that level cannot be mapped |
| 6 | Approval Month | `EXC_MONTH` | — | MM/YYYY from `DATEFR` |
| 7 | Exception Number | `EXC_NO` | — | `BP3100-COUNTER` |
| 8 | Approval Date From | `DATE_FROM` | — | `BP3100-DATEFR` |
| 9 | Approval Date To | `DATE_TO` | — | `BP3100-DATETO` |
| 10 | Exceptional Amount | `EXC_AMNT` | `WAERS` | `BP3100-AMNT` |
| 11 | Commitment Date | `COMMIT_DATE` | — | blank if unparseable |
| 12 | Commitment Text | `COMMIT_TEXT` | — | raw `BP3100-TEXT`, always shown |
| 13 | Actual Credit Limit | `CREDIT_LIMIT` | `WAERS` | for `P_SEGMNT`; zero if none |
| 14 | Actual OS on Commit Date | `ACT_OS` | `WAERS` | 0.00 if commitment date unparseable |
| 15 | Non-Fulfilment Amount | `NON_FULFIL` | `WAERS` | Actual OS − Actual Credit Limit; 0.00 if commitment date unparseable |
| 16 | Default % Non-Fulfilment | `DEF_PERC` | — | 0.00 when limit = 0 or commitment date unparseable |
| 17 | Status | `STATUS` | — | Fulfilled / Not Fulfilled; blank when commitment date unparseable |
| — | Currency | `WAERS` | — | hidden (`NO_OUT`); company-code currency, drives columns 10/13/14/15 |

Amount and percentage columns are packed fields, so a cleared value shows as `0.00` in
the grid, not as an empty cell — only the character columns (Commitment Date, Status)
are visibly blank.

---

## 7. Assumptions and deviations from the FS

Every row below carries an `" ASSUMPTION:` comment at the matching point in the
source and a cross-reference to the numbered item in `ISSUES.md`.

| # | FS says | Build does | Why | `ISSUES.md` |
|---|---|---|---|---|
| 1 | L4/L5/L6 from `SAPLSLVC_FULLSCREEN` | Direct read of **`ZSD_CUSTEMP_ASSG`**, the table `ZSD_CUSTOMER_DATA` shows these names from, valid today | `SAPLSLVC_FULLSCREEN` is the generic ALV function group, not a report; the real report is a table read plus display, so the table is read | #1, #27 |
| 2 | Actual OS from `BSID` by `GJAHR` | `BSID` + `BSAD`, bounded by `BUDAT`/`AUGDT`, no `GJAHR` filter | `BSID` holds items open **now**; an item cleared after the commitment date must still count as open on that date. Open items also span fiscal years, so a `GJAHR` filter drops valid rows | #4 |
| 3 | Fetch `WRBTR` | `WRBTR` is selected for reference; the arithmetic uses `DMBTR` | `WRBTR` is document currency; the credit limit is not. `DMBTR` (company-code currency) is the comparable figure. Switching back is a one-line change | #4 |
| 4 | `REBZG` blank / not blank as two separate steps | Single read, `REBZG` selected but not filtered | The two FS steps together are simply "all items" — filtering on `REBZG` would not change the sum | related to #4 |
| 5 | Exceptional Approval Type column, values Credit Limit / Order / Both | Column **removed** 07/09/26 | Functional confirmed it is not required | #2 closed |
| 6 | Commitment date "fetched" from `TEXT` | `DD.MM.YYYY` parse (separator `/` or `-` also accepted), initial on failure | `BP3100-TEXT` is free text; the entry format was confirmed 07/09/26 | #3 closed |
| 7 | No credit segment on the selection screen | `P_SEGMNT` added, obligatory, **defaults to 2000** | `UKMBP_CMS_SGM` is keyed by partner **and** credit segment — the credit limit is ambiguous without one. Segment 2000 confirmed by functional 07/09/26 | #16 closed |
| 8 | Status defined only for (+) and (−) non-fulfilment | Exactly zero is treated as **Fulfilled** | The FS gives no rule for the boundary case | #12 |
| 9 | KNVV-keyed customer selection | Result deduplicated to one row per customer | A customer extended to several sales areas would otherwise multiply rows | #13 |
| 10 | Required "Date" selection field, no table/field stated | Applied to `BP3100-DATEFR` (approval date from) | The output mapping's only date the FS ties to an approval, as opposed to a commitment or posting date | #11 |
| 11 | "Authorization TBD" | No authorization object built | Nothing was confirmed to check against; see open point below | #15 |
| 12 | Credit limit and approvals "for the customer" | `BP3100-PARTNER` and `UKMBP_CMS_SGM-PARTNER` compared directly with `KUNNR` | Holds only under CVI same-number assignment | #18 |
| 13 | "Actual OS" with no line drawn | Every BSID/BSAD line summed — receivables, special G/L and noted items | The FS gives no exclusion; FBL5N would drop noted items | #19 |
| 14 | No division on the selection screen | `S_SPART` added, optional | FS reviewer comment (Yogesh Vanani) asks for it; blank = all divisions | #20 |
| 15 | Hierarchy "as shown by the report" | Hierarchy rows valid on `SY-DATUM`, as `ZSD_CUSTOMER_DATA` selects them; last valid row wins for a duplicated level | Identical to the callee's own logic; the FS does not ask for the hierarchy as on the approval date | #27 |

---

## 8. Open points still needing a functional answer

Ranked by what changes a number or a column on the report, not by `ISSUES.md` order.

1. ~~**`ISSUES.md` #1 — L4/L5/L6 source.**~~ **Resolved 17/09/26** (#27): read directly
   from `ZSD_CUSTEMP_ASSG`, the table `ZSD_CUSTOMER_DATA` shows them from. Left to confirm
   in functional testing: the names on this report match that report for the same
   customers, and "valid today" is the wanted reading.
2. **`ISSUES.md` #4 — as-on-date logic, currency, GJAHR.** The build's `BSID`+`BSAD`
   approach and its use of `DMBTR` are the technical team's best read of "actual OS as
   on the commitment date" from a document-currency, GJAHR-scoped FS instruction that
   cannot literally be correct (see deviations 2–4 above). Confirmation removes the
   `" ASSUMPTION:` tags but does not by itself change any code unless the answer
   differs from what is built.
3. ~~**`ISSUES.md` #2 — Approval Type source field.**~~ **Closed 07/09/26.** Not required;
   column removed.
4. ~~**`ISSUES.md` #3 — commitment date format.**~~ **Closed 07/09/26.** `DD.MM.YYYY`.
   Still open within it: whether an unparseable row should be flagged beyond the blank
   Commitment Date and Status it already gets.
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
10. **`ISSUES.md` #18 — BP number = customer number.** Confirm CVI same-number
    assignment on this landscape; otherwise `BP3100` and `UKMBP_CMS_SGM` need a
    `CVI_CUST_LINK` hop.
11. **`ISSUES.md` #19 — what counts as "Actual OS".** Confirm special G/L and noted items
    are in (current build) or out.
12. **`ISSUES.md` #20 — division.** Confirm `S_SPART` optional (current build) rather than
    obligatory as on the Paints screen.

`ISSUES.md` items #5, #6, #8, #9 and #10 belong to WRICEF 141.B (Paints) and do not
apply to this object.

---

## 9. Unit test scenarios

| # | Scenario | Input | Expected result |
|---|---|---|---|
| 1 | FS sample row 1 — customer 1009024, exceptional amount driving a positive non-fulfilment | Customer 1009024, credit limit 100,000, actual OS on commitment date 125,000 | Non-Fulfilment Amount = 25,000; Default % = 25.00; Status = Not Fulfilled |
| 2 | FS sample row 2 — customer with actual OS below the limit | Customer with credit limit 100,000, actual OS on commitment date 98,000 | Non-Fulfilment Amount = −2,000; Default % = −2.00; Status = Fulfilled |
| 3 | Empty selection | `P_BUKRS` / `S_VKORG` combination that matches no `KNB1`/`KNVV` row | Message "No customers match the selection"; report stops, no ALV shown |
| 4 | Zero credit limit | Approval row for a customer with no `UKMBP_CMS_SGM` row in `P_SEGMNT` (or `CREDIT_LIMIT = 0`) | Actual Credit Limit = 0; Default % shows 0.00 (no division by zero); Non-Fulfilment Amount still computed as Actual OS − 0; Status set from that amount |
| 5 | Unparseable commitment date | `BP3100-TEXT` containing no recognisable date token (e.g. free-form remarks only) | Row still appears; Commitment Text shows the raw text; Commitment Date and Status are blank, Actual OS, Non-Fulfilment Amount and Default % show 0.00 |
| 6 | Customer in more than one sales area | One `KUNNR` extended to two `VKORG` values that both satisfy `S_VKORG` | Customer appears **exactly once** in `GT_CUST` and therefore at most once per approval row — never duplicated by sales area |
| 7 | No exceptional approvals for a valid customer set | Customers found in `KNB1`/`KNVV`, but no `BP3100` row matches `P_INFCAT`/`P_INFTYP`/`S_DATE` | Message "No exceptional approvals found for the selection"; report stops |
| 8 | Company code that does not exist | `P_BUKRS` value absent from `T001` | Error on the selection screen: "Company code does not exist"; cursor stays on the field |
| 9 | Information type not valid for the category | `P_INFTYP` filled, but no `BP3100` row for that `ADDTYPE`/`DATA_TYPE` pair | Error on the selection screen: "Information type not valid for this category" |
| 10 | Item cleared after the commitment date | A `BSID` item as of the commitment date is later cleared (now only in `BSAD`), with `AUGDT` after the commitment date | Still counted as open in `F_CALC_OPEN_AMOUNT` via the `BSAD` leg — Actual OS on Commitment Date includes it |
| 11 | Division filter | Same `P_BUKRS`/`S_VKORG` run twice, once with `S_SPART` blank and once with one division | Blank: every division's customers; filled: only customers with a `KNVV` row in that division; no duplicate rows either way |
| 12 | Hierarchy names | Customer with `ZSD_CUSTEMP_ASSG` rows for `L4`, `L5`, `L6` valid today | L4/L5/L6 Name equal to `LNAME` of those rows — identical to the L4/L5/L6 Name columns of `ZSD_CUSTOMER_DATA` for the same customer |
| 13 | Partial hierarchy | Customer with a valid `L4` and `L5` row but no `L6` row, or an `L6` row whose `ENDVAL` is in the past | L4 and L5 filled, L6 blank; no message |
| 14 | No hierarchy at all | None of the approval customers has a `ZSD_CUSTEMP_ASSG` row valid today | All three columns blank; status message M18; report still displays |

## Note added 07/09/26 — BP3100 field names

`BP3100` has no `INFOCATEGORY` / `INFOTYPE` column. The information category and
information type are held in **`ADDTYPE`** and **`DATA_TYPE`**, confirmed from the system.
Everything technical was re-pointed; the business labels on the screen are unchanged.

`UKM_INFOCAT` / `UKM_INFOTYP` are no longer read. With BP3100 using different field names,
the matching customizing field names are unconfirmed here, and both value helps now read
the distinct values present in `BP3100` itself. That cannot be wrong, and for a report it
is the better list: only values that carry data can be reported on. Offering the full
customizing list instead is a change to two `SELECT`s.

## Note added 07/09/26 — issues 2 and 3 closed

**Exceptional Approval Type removed.** Functional confirmed the column is not required.
`EXC_TYPE` is gone from `TY_OUTPUT`, from `F_BUILD_OUTPUT` and from the field catalogue; the
columns after it renumber 8 to 18. The ALV now carries 17 visible columns plus the hidden
`WAERS` currency reference. Text symbol `C08` is unused; the rest were deliberately not
renumbered so only one row left the text-element sheet.

**Commitment date confirmed as DD.MM.YYYY.** `F_PARSE_COMMIT_DATE` no longer accepts a bare
8-digit `YYYYMMDD` token. `/` and `-` are still normalised to `.` before parsing, since those
carry the same field order and accepting them prevents a blank row when a user types a slash
out of habit. This makes the parse stricter: an 8-digit run inside free text is more likely
to be an amount or a document number, which the old code would have read as a date.

A row that still fails to parse behaves as before — the raw text shows in the Commitment
Text column, Status stays blank and Actual OS, Non-Fulfilment and Default % show 0.00 rather than
carrying a number derived from a date the program could not read.


## Note added 17/09/26 — L4/L5/L6 blank in functional testing

Sanjay reported the three hierarchy columns blank on every row. The morning fix resolved
the callee's field names at runtime and listed them when nothing mapped (`ISSUES.md` #26);
it was activated and the columns stayed blank, because the callee's fields are `LNAME4`,
`LNAME5`, `LNAME6` — neither the placeholders nor anything containing the token `L4`.

The same afternoon Arnav supplied the source of `ZSD_CUSTOMER_DATA`. Its level names are a
plain read of table `ZSD_CUSTEMP_ASSG`, valid today, so `F_GET_HIERARCHY` now reads that
table directly and the SUBMIT, the ALV capture and the field-name resolution are retired
(commented out). Details in §5.6 and `ISSUES.md` #27. Text symbol `M18` is new; `M13`–`M17`
are no longer referenced.
