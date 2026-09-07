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

## 07/09/26 — BP3100 field names corrected

Arnav confirmed from the system that **BP3100 has no `INFOCATEGORY` / `INFOTYPE` column**.
The fields carrying the information category and information type are **`ADDTYPE`** and
**`DATA_TYPE`**. `ZSD_EXC_APPR_ADHESIVE` re-pointed throughout: the BP3100 read, both
parameters (now typed off `BP3100-ADDTYPE` / `BP3100-DATA_TYPE`), both F4 helps and both
selection-screen checks.

Business labels are unchanged — the screen still reads "Information Category" and
"Information Type", and the parameter names `P_INFCAT` / `P_INFTYP` keep that meaning, so
no selection text or message text moved.

`UKM_INFOCAT` and `UKM_INFOTYP` were dropped as the value-help and validation source. Now
that BP3100 uses different field names, the matching customizing field names are not
confirmed on this landscape, and a wrong table or field name costs an activation cycle.
Both F4 helps and both checks now read the distinct values present in BP3100 itself, which
cannot be wrong and, for a report, is the better list: only values that carry data can be
reported on. If those customizing tables do exist with usable field names and functional
wants the full list offered rather than the used list, that is a change to two SELECTs.

`ZSD_EXC_APPR_PAINTS` is unaffected — Info Category and Info Type were already dropped from
the Paints selection screen (issue 10), so it never referenced either field.

## 07/09/26 — all three programs activated

| Object | State |
|---|---|
| `ZSD_EXC_APPR_ADHESIVE` | **Active.** With the credit-segment default, the `ZSD_CUSTOMER_DATA` hierarchy call, and the ADDTYPE / DATA_TYPE correction. |
| `ZSD_EXC_APPR_PAINTS` | **Active.** With the credit-segment default and the hierarchy call. |
| `ZSD_EXP_PAINTS_UPLOAD` | **Active.** |

Activation of the two Paints programs proves the DDIC underneath them is active as well —
neither would syntax check otherwise. So SE11 steps 1 to 4 of `ZSD_EXP_PAINTS_DDIC.md` are
done: the 5 domains, the 6 data elements, table `ZSD_EXP_PAINTS` and its technical settings.

### What is left on the build

| Item | Blocking? |
|---|---|
| Table maintenance generator, function group `ZSD_EXC_PAINTS`, one step, screen 0001 (§4 of the DDIC sheet) | Not implied by activation — check SM30 opens on `ZSD_EXP_PAINTS`. Needed for single-record maintenance; the upload program covers mass entry without it. |
| Text elements on all three programs | Cosmetic. Every literal carries its own default, so all three run without them. |
| The four `GC_HIER_*` field names from `ZSD_CUSTOMER_DATA` | L4/L5/L6 stay blank until supplied. |
| Authorisation object (issue 15) | Blocks QA, not functional testing. |
| The four functional questions (issues 2, 3, 5, 6) | Each decides a number, not whether the program runs. |

### First-run order for functional testing

1. `ZSD_EXP_PAINTS_UPLOAD` with the test-run box ticked, on a small file. The log must come
   back clean before anything is written.
2. Same file with the box unticked, insert mode.
3. `ZSD_EXC_APPR_PAINTS` over the loaded rows.
4. `ZSD_EXC_APPR_ADHESIVE` against real BP3100 data.

On the first run of either report, watch whether `ZSD_CUSTOMER_DATA` stops on its own
selection screen. That is the one failure mode the `GC_HIER_*` guards cannot cover.

## 07/09/26 — issues 2 and 3 answered

| # | Answer | What changed in `ZSD_EXC_APPR_ADHESIVE` |
|---|---|---|
| 2 | The Exceptional Approval Type is **not required** on this report. | Column removed, not blanked. `EXC_TYPE` dropped from `TY_OUTPUT`, the `CLEAR` dropped from `F_BUILD_OUTPUT`, the field-catalogue entry dropped and the columns after it renumbered 8 to 18. Text symbol `C08` is now unused. **Closed.** |
| 3 | The commitment date in `BP3100-TEXT` is entered as **DD.MM.YYYY**. | `F_PARSE_COMMIT_DATE` narrowed. The bare 8-digit `YYYYMMDD` branch is removed. `/` and `-` are still normalised to `.` first, because those carry the same field order and accepting them costs one `REPLACE` and prevents a blank row when a user types a slash out of habit. **Closed.** |

Dropping the 8-digit branch makes the parse **stricter**, not weaker: an 8-digit run inside
free text is more likely to be an amount, a phone fragment or a document number, all of
which the old code would have read as a date.

`ZSD_EXC_APPR_PAINTS` is unaffected by issue 2. Its approval type column has a real source
field, `ZSD_EXP_PAINTS-ZEXC_APPR_TYPE`, mapped 1/2/3 to text symbols `T01` to `T03`, and it
stays.

### Note on the commitment date DISPLAY

`COMMIT_DATE` in the ALV is typed `DATS`, so SAP renders it in each user's own date format
from their user profile (SU3, Defaults tab). For an Indian profile that is already
DD.MM.YYYY. Forcing DD.MM.YYYY regardless of the user setting would mean converting the
column to a character field, which loses date sorting and date filtering in the ALV — not
recommended, but it is a small change if functional insists.

