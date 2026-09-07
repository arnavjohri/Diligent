# ISSUES — WRICEF 141 A/B Exceptional Approval

## 02/09/26 — FS review, questions raised before build

| # | Doc | Item | Problem | Needed from functional |
|---|-----|------|---------|------------------------|
| 1 | A+B | L4/L5/L6 Name | FS says "Submit program SAPLSLVC_FULLSCREEN, fetch L4 Name". That is the generic ALV full-screen function group — not a program, not SUBMIT-able, holds no data. | Real source: report name, or the table/field holding the sales hierarchy (KNVP partner functions? Z hierarchy table? HR org level?) |
| 2 | A | Exceptional Approval Type | Sample column shows "Not Feasible"; stated values are Credit Limit / Order / Both. No source field given in the output mapping. | Which BP3100 field carries it — INFOTYPE? |
| 3 | A | Commitment Date | Mapped to BP3100-TEXT, a free-text field. Unparseable in the general case. | Agreed entry format, and behaviour when a row does not parse |
| 4 | A | Actual OS as on Commitment Date | BSID holds open items *as of now*, not as of a past date — needs BSID + BSAD with AUGDT > commitment date. Also WRBTR is document currency vs credit limit in segment currency, and GJAHR is not on the selection screen. | Confirm as-on-date logic, currency, and where GJAHR comes from |
| 5 | B | Actual Collection date range | Mapping table says BUDAT from selection screen; Parth Shah's comment says "collection received during the approval date & commitment date" (per row). Contradiction. | Which one applies |
| 6 | B | Non-Fulfilment Amount | Stated formula = Collection Commitment − Actual Collection. Sample row (100,000 / 125,000 → 25,000) is Actual − Credit Limit, i.e. copied from the Adhesives doc. Sign is opposite. | Confirm formula and sign convention |
| 7 | A+B | Default % of Non-Fulfilment | Divides by Actual Credit Limit — undefined when limit is 0. For Paints, dividing a collection shortfall by the credit limit looks wrong. | Confirm denominator + zero-limit handling |
| 8 | B | Field names | Table declares ZEXC_AMOUNT and ZEX_AMNT (both "Exceptional ... Amount"); output maps ZEXC_AMNT, which matches neither. | Confirm final field names and whether both amount fields are really needed |
| 9 | B | Table definition gaps | No currency key field for the CURR amounts (cannot activate without one). "Month" given as length "MM-YYYY" — that is a format, not a length. SR. No. key has no stated number source (SNRO or manual). | Confirm CURKY field, month storage (recommend NUMC 6 YYYYMM, displayed MM-YYYY), and SR. No. numbering |
| 10 | B | Info Category / Info Type | Both are *required* selection fields, but ZSD_EXP_PAINTS has no info category / info type field to filter on. | Drop them from the Paints selection screen, or add the fields to the table |
| 11 | A+B | "Date" selection field | Listed as required Range with no table/field. | Which date — approval date, commitment date, or posting date |
| 12 | B | Status - 2 | Uses > and < only; equality (collection exactly equals commitment) is undefined. | Confirm — assumed >= is Fulfilled unless told otherwise |
| 13 | A+B | Sales-area duplication | KNVV is sales-area dependent; a customer in several sales areas will multiply rows. | Dedupe rule, or accept one row per sales area |
| 14 | A+B | Output layout | Format shown as three stacked tables. | Confirm single flat ALV, one row per exception record, key columns repeated |
| 15 | A+B | Authorisation | FS says "Authorization TBD". | Auth object / check to build in |
| 16 | A+B | Actual Credit Limit | `UKMBP_CMS_SGM` is keyed by partner **and credit segment** — a customer with several segments has several CREDIT_LIMIT values. FS names neither a segment nor a rule. | Which credit segment: fixed default (0000?) or a selection-screen field |

## 07/09/26 — answers received, code updated for functional testing

| # | Answer received | What the code now does | Status |
|---|-----------------|------------------------|--------|
| 16 | Credit segment is **2000** | `P_SEGMNT` on both selection screens now defaults to `2000`. Kept as an overridable parameter, not a constant. | **Closed** |
| 1 | The hierarchy report is to be called in background and its output read. The program name in the FS is wrong and will be corrected. | `F_GET_HIERARCHY` in both reports now builds the call in full: TRDIR check, `SUBMIT ... WITH SELECTION-TABLE ... AND RETURN`, ALV capture via `CL_SALV_BS_RUNTIME_INFO`, dynamic field mapping, merge into the customer list. The unconfirmed names sit in one `GC_HIER_*` constants block. | **Partly answered — still blocked on the name** |

### Issue 1 — program name given 07/09/26, field names still placeholders

Arnav supplied the real source: **`ZSD_CUSTOMER_DATA`**. `GC_HIER_PROG` now carries it,
so the TRDIR guard passes and the `SUBMIT` genuinely runs. The other four constants are
still unconfirmed and are **not** guessed anywhere else in the code.

| Constant | Needs | Status |
|---|---|---|
| `GC_HIER_PROG` | the executable report that lists the sales hierarchy | **`ZSD_CUSTOMER_DATA` — confirmed 07/09/26** |
| `GC_HIER_SELNAME` | that report's SELECT-OPTION name for sales organisation | placeholder `S_VKORG` |
| `GC_HIER_F_KUNNR` | the customer field in its ALV output | placeholder `KUNNR` |
| `GC_HIER_F_L4` / `_L5` / `_L6` | the three level-name fields in its ALV output | placeholder `L4_NAME` / `L5_NAME` / `L6_NAME` |

What a wrong placeholder costs, none of it a dump:

- **`GC_HIER_SELNAME` wrong.** `SUBMIT` ignores an unknown `SELNAME`, so `ZSD_CUSTOMER_DATA`
  runs unfiltered. Slower, but the merge is on customer key so the names reported are still
  right for the customers on the report.
- **`GC_HIER_F_KUNNR` wrong.** Nothing keys. `F_GET_HIERARCHY` says so with a status message
  rather than showing blank columns that look like missing master data.
- **`GC_HIER_F_L4` / `_L5` / `_L6` wrong.** That level comes back blank.

To confirm them: run `ZSD_CUSTOMER_DATA`, use Settings → Layout → Current on its ALV for the
technical field names, and F1 on its sales-organisation field for the select-option name.

**Watch in functional testing:** if `ZSD_CUSTOMER_DATA` has an obligatory selection field
other than sales organisation, the `SUBMIT` stops on its own selection screen. That is the
one behaviour the placeholders cannot protect against, because we do not know its screen.

## Still open and genuinely blocking a correct number

These four cannot be assumed either way — each has two readings that produce different
figures on the same data, so a guess would ship a wrong number rather than a blank.

| # | Doc | Question |
|---|-----|----------|
| 2 | A | Which BP3100 field carries the Exceptional Approval Type. Column ships blank until answered. |
| 3 | A | The agreed entry format for the commitment date inside BP3100-TEXT, and what to do with a row that does not parse. |
| 5 | B | Actual Collection window: BUDAT from the selection screen, or per row from approval date to commitment date. Currently per row. |
| 6 | B | Non-Fulfilment sign: Commitment minus Actual Collection (the prose), or Actual minus Credit Limit (the sample). Currently the prose. |

Issue 15 (authorisation object) is still "TBD" in the FS. It does not block functional
testing, but it blocks the move to QA.
