# WRICEF 141 A/B — open questions for functional, with the code that depends on each

Written 07/09/26, after all three programs activated. Every question below names the
program, the FORM and what the code does **today**, so the change is a known edit rather
than a re-read of the whole object.

Line numbers are snapshot-bound and drift as soon as anyone edits. **Locate by FORM name.**

| File | Object |
|---|---|
| A | `ZSD_EXC_APPR_ADHESIVE.abap` |
| B | `ZSD_EXC_APPR_PAINTS.abap` |
| U | `ZSD_EXP_PAINTS_UPLOAD.abap` |

---

# PART 1 — Blocking a correct number

**Two of these four closed on 07/09/26 — Q1 and Q2. Q3 and Q4, both on Paints, remain.**

Each of these has two readings that produce **different figures on the same data**. A guess
ships a wrong number rather than a blank, which is why none of them was assumed.

## ~~Q1 — Issue 2 (A). Which BP3100 field carries the Exceptional Approval Type?~~ CLOSED 07/09/26

> **Answered: the column is not required.** Removed from `TY_OUTPUT`, `F_BUILD_OUTPUT` and
> the field catalogue. Paints keeps its own approval type — that one has a real source field.

**Where:** A, `F_BUILD_OUTPUT`, around line 1327.

```abap
* ASSUMPTION (FS deviation 5): the FS shows an "Exceptional Approval
* Type" column with values Credit Limit / Order / Both but names no
* source field for it. The column is kept so the layout matches the FS
* and is left blank until functional confirms the field - open issue 2.
    CLEAR ls_out-exc_type.
```

**Today:** the ALV column "Approval Type" exists so the layout matches the FS, and is
**blank on every row**.

**Why it is open:** the FS sample shows "Not Feasible". The stated value list is Credit
Limit / Order / Both. Neither appears in the output mapping against a BP3100 field.

**What we need:** the BP3100 field name, plus the code-to-text mapping if it is a coded
field. Note `DATA_TYPE` is already consumed as the Information Type on the selection
screen, so if the approval type is also `DATA_TYPE` the two are the same thing and the
column should be dropped, not filled.

**Change if answered:** one assignment replaces the `CLEAR`, plus a `CASE` and three text
symbols if it is coded. Paints does this already — see its `F_BUILD_OUTPUT`, `ZEXC_APPR_TYPE`
1/2/3 to `T01`/`T02`/`T03` — so there is a working pattern to copy.

## ~~Q2 — Issue 3 (A). What is the agreed entry format for the commitment date in BP3100-TEXT?~~ CLOSED 07/09/26

> **Answered: DD.MM.YYYY.** `F_PARSE_COMMIT_DATE` narrowed; the bare 8-digit branch removed.
> `/` and `-` still normalised to `.` since they carry the same field order.

**Where:** A, `F_PARSE_COMMIT_DATE` (a whole FORM, around line 925), called from
`F_GET_OPEN_ITEMS`.

**Today:** `BP3100-TEXT` is free text, so the code scans it defensively and accepts
`DD.MM.YYYY`, `DD/MM/YYYY`, `DD-MM-YYYY` and a bare `YYYYMMDD` token anywhere in the text,
validating the calendar including leap years. The first token that parses wins.

**When a row will not parse:** the row is still shown, with the raw text visible in the
"Commitment Text" column, but Actual OS, Non-Fulfilment, Default % and Status stay
**blank** rather than showing a number derived from a date we could not read.

**Why it is open:** a free-text field has no guaranteed format. Somebody typing
"by 15th Oct" produces a blank row and will ask why.

**What we need:** the agreed format users are told to type, and confirmation that a blank
row is the right treatment for anything else, as opposed to an error list.

**Change if answered:** `F_PARSE_COMMIT_DATE` narrows to the agreed format. If the answer is
that this should be a real date field rather than free text, that is a BP configuration
change, not an ABAP change.

## Q3 — Issue 5 (B). Actual Collection window: per row, or from the selection screen?

**Where:** B, `F_CALC_COLLECTION`, around line 816, and the outer read in
`F_GET_COLLECTIONS`.

```abap
  LOOP AT gt_coll INTO ls_coll WHERE kunnr = iv_kunnr.
    IF ls_coll-budat < iv_date_from.
      CONTINUE.
    ENDIF.
    IF ls_coll-budat > iv_commit_date.
      CONTINUE.
    ENDIF.
    lv_sum = lv_sum + ls_coll-hsl.
  ENDLOOP.
```

**Today:** the window is **per approval row**, `ZEXC_DATE_FROM` to `ZCOMMIT_DATE`
inclusive, following Parth Shah's document comment "Collection received during the approval
date & Commitment date".

**The contradiction:** the FS mapping table says `BUDAT` comes from the selection screen —
one shared window for every row.

**Why it matters:** with a single shared window, a customer with two overlapping approvals
has the same collection counted **twice**, once against each. Per row it is counted once
against each row's own window. The totals differ.

**Change if answered the other way:** `F_CALC_COLLECTION` drops the two `budat` guards and
the whole read becomes the selection-screen range. Roughly ten lines.

## Q4 — Issue 6 (B). Non-Fulfilment: which formula, and which sign?

**Where:** B, `F_BUILD_OUTPUT`, line 1009.

```abap
* ASSUMPTION (FS deviation 4, build spec C2): the formula row of the FS
* says Non-Fulfilment = Collection Commitment minus Actual Collection,
* and the reviewer comment restates it. The sample row implies Actual
* minus Credit Limit, which is the Adhesives formula copy-pasted. The
* stated formula wins - see open issue 6.
    ls_out-non_fulfil = ls_out-cm_amnt - ls_out-act_coll.
```

**Today:** Collection Commitment minus Actual Collection. A shortfall is **positive**.

**The contradiction:** the FS sample row (100,000 / 125,000 giving 25,000) is Actual minus
Credit Limit — the Adhesives formula copied into the Paints document. That gives the
**opposite sign** and a different meaning.

**Note this feeds Q6 below.** Default % divides this number, so a wrong sign here flips the
percentage too.

**Change if answered the other way:** one line, plus the Default % denominator question.

---

# PART 2 — Needed to fill three columns

## Q5 — Issue 1 (A+B). The four ALV field names inside ZSD_CUSTOMER_DATA.

**Where:** the `GC_HIER_*` `CONSTANTS` block above the selection screen in **both** A and B,
around line 228, and `F_GET_HIERARCHY` in both.

```abap
CONSTANTS: gc_hier_prog    TYPE trdir-name       VALUE 'ZSD_CUSTOMER_DATA',
           gc_hier_selname TYPE rsparams-selname VALUE 'S_VKORG',
           gc_hier_f_kunnr TYPE dfies-fieldname  VALUE 'KUNNR',
           gc_hier_f_l4    TYPE dfies-fieldname  VALUE 'L4_NAME',
           gc_hier_f_l5    TYPE dfies-fieldname  VALUE 'L5_NAME',
           gc_hier_f_l6    TYPE dfies-fieldname  VALUE 'L6_NAME',
           gc_subc_report  TYPE trdir-subc       VALUE '1'.
```

**Confirmed:** `GC_HIER_PROG` is `ZSD_CUSTOMER_DATA`, given 07/09/26. The FS printed
`SAPLSLVC_FULLSCREEN`, which is the generic ALV function group — TRDIR type `F`, not an
executable report and not `SUBMIT`-able.

**Still placeholders:** the other four. Nothing else in either program guesses them.

**What a wrong placeholder costs — none of it a dump:**

| Constant wrong | Effect |
|---|---|
| `GC_HIER_SELNAME` | `SUBMIT` ignores an unknown `SELNAME`, so `ZSD_CUSTOMER_DATA` runs unfiltered. Slower; names still correct, because the merge is on customer key. |
| `GC_HIER_F_KUNNR` | Nothing keys. Message `M16` (A) / `M10` (B) says so, rather than leaving blanks that look like missing master data. |
| `GC_HIER_F_L4/5/6` | That level comes back blank. |

**How to read them off:** run `ZSD_CUSTOMER_DATA`, then on its ALV use
**Settings → Layout → Current** for the technical field names, and **F1** on its sales
organisation field for the select-option name.

**Change when answered:** four `VALUE` literals in that one block, in both programs.
Nothing else moves.

**Also watch on the first run.** If `ZSD_CUSTOMER_DATA` has an obligatory selection field
other than sales organisation, the `SUBMIT` stops on its own selection screen. That is the
one failure mode the guards cannot cover, because its screen is not known here. If it
happens, send the selection screen.

---

# PART 3 — Assumed and built. Confirm, or tell us to change

These all produce a number today. Each is a documented assumption, greppable in the source
as `ASSUMPTION`.

## Q6 — Issue 7 (A+B). Default % denominator, and the zero-limit rule.

**Where:** `F_BUILD_OUTPUT` in both. A around line 1363, B around line 1029.

```abap
      IF ls_out-credit_limit <> 0.
        lv_perc = ( ls_out-non_fulfil * 100 ) / ls_out-credit_limit.
        ...
      ELSE.
*       Never divide by zero - the FS gives no rule for a zero limit.
        CLEAR ls_out-def_perc.
      ENDIF.
```

**Today:** divided by Actual Credit Limit exactly as the FS states, guarded so a zero limit
gives zero instead of a dump. Computed in a wider packed field first so a tiny limit against
a large shortfall cannot overflow.

**The concern, for Paints only:** the numerator there is a **collection shortfall** and the
denominator is a **credit limit**. Those are different quantities, so the percentage has no
obvious business meaning. For Adhesives, where the numerator is outstanding above the limit,
dividing by the limit is coherent.

**What we need:** confirm the denominator for Paints, and confirm that zero-limit means a
zero percentage rather than a blank or a dash.

## Q7 — Issue 4 (A). Actual OS as on the commitment date.

**Where:** A, `F_GET_OPEN_ITEMS` around line 1196, and `F_CALC_OPEN_AMOUNT`.

**Today:** BSID **plus** BSAD, bounded by `BUDAT` and `AUGDT`, with **no GJAHR filter**.

**Why it deviates from the FS:** the FS reads BSID by GJAHR. BSID holds what is open
**now**, so an item that was open on the commitment date but has been cleared since would be
lost. That is what the BSAD leg with `AUGDT > commitment date` recovers. And a GJAHR filter
drops open items that span fiscal years, which is why it is absent.

**Also assumed here:** `DMBTR` (company code currency) is used for the arithmetic, not
`WRBTR` (document currency), because the credit limit is not in document currency and only
comparable amounts can be subtracted. `WRBTR` is still selected for reference — switching
back is one line in `F_CALC_OPEN_AMOUNT`.

**What we need:** confirm the as-on-date logic and the currency choice.

## Q8 — Issue 11 (A+B). Which date is the "Date" selection field?

**Where:** A line 257, B line 232.

```abap
SELECT-OPTIONS s_date FOR bp3100-datefr OBLIGATORY.                     " A
SELECT-OPTIONS s_date  FOR zsd_exp_paints-zexc_date_from OBLIGATORY.    " B
```

**Today:** approval date from. The FS listed a required "Date" range with no table or field
against it.

**What we need:** confirm it is approval date from, and not commitment date or posting date.

## Q9 — Issue 12 (A+B). Status when the figures are exactly equal.

**Where:** A `F_BUILD_OUTPUT` around line 1378, B `F_CALC_STATUS` around line 896.

**Today:** equality counts as **Fulfilled**, in both. The FS defines only greater-than and
less-than. Paints additionally leaves Status-2 **blank** when the commitment date has not
yet fallen due — neither fulfilled nor unfulfilled.

**What we need:** confirm both rules.

## Q10 — Issue 13 (A+B). One row per customer, or one per sales area?

**Where:** `F_GET_CUSTOMERS` in both. A around line 590, B around line 367.

```abap
  SORT lt_knvv BY kunnr.
  DELETE ADJACENT DUPLICATES FROM lt_knvv COMPARING kunnr.
```

**Today:** deduplicated to one row per customer. KNVV is sales-area dependent, so a customer
extended to several sales areas would otherwise multiply every approval row by the number of
sales areas and inflate every total.

**What we need:** confirm one row per customer is wanted, and that sales area is a filter
rather than an output dimension.

## Q11 — Issue 8 (B). Is ZEX_AMNT a real second figure?

**Where:** B, `TY_APPR` around line 95, and `F_GET_APPROVALS` around line 409. Also U, which
loads it.

**Today:** the field exists on the table and the upload program loads it, but **no output
column reads it**. The report does not select it. The FS output mapping names `ZEXC_AMNT`,
which matches neither the declared `ZEXC_AMOUNT` nor the declared `ZEX_AMNT`; the DDIC name
`ZEXC_AMOUNT` was taken as authoritative.

**What we need:** whether `ZEX_AMNT` is a genuine second amount the business needs on the
report, or a copy-paste duplicate that can be dropped from the table.

## Q12 — Issue 10 (B). Info Category and Info Type on the Paints screen.

**Where:** B, selection screen comment around line 226.

**Today:** both are **absent** from the Paints selection screen. The FS marks them required,
but `ZSD_EXP_PAINTS` carries neither field, so neither could filter anything. Two mandatory
fields that filter nothing would tell the user the list is narrower than it really is.

**What we need:** either drop them from the FS, or add `ZINFOCAT` / `ZINFOTYPE` to the
table — the second is a DDIC change plus an upload-file column, not a code-only fix.

## Q13 — Issue 9 (B). Where does the serial number come from?

**Where:** U, `F_PARSE_ROWS`, the serial-number block.

**Today:** the **upload file supplies it**. It is validated as numeric, up to 10 digits, and
must be unique within the file and against the table in insert mode.

**What we need:** whether a number range (SNRO) should assign it automatically instead. If
so that is an added object and a change to the upload program, not a change to the table.

**Related, already decided and worth confirming:** `WAERS` was added to the table because a
CURR field cannot activate without a currency reference, and `ERNAM`/`ERDAT`/`AENAM`/`AEDAT`
were added so a table maintained by both SM30 and a mass upload has an audit trail. Neither
group is in the FS.

## Q14 — Issue 14 (A+B). Output layout.

**Today:** one flat ALV, one row per exception record, key columns repeated on every row.
The FS shows the format as three stacked tables, which is a document layout rather than an
ALV layout.

**What we need:** confirm the flat ALV is acceptable for both reports.

---

# PART 4 — Blocks QA, not testing

## Q15 — Issue 15 (A+B). Authorisation.

The FS says "Authorization TBD". **No object and no check is built** in any of the three
programs. Functional testing works without it; the move to QA does not.

**What we need:** which authorisation object gates these reports — company code, credit
segment, sales organisation, or a custom object — and whether the upload program needs a
separate, stricter check, since it writes data.

---

# Closed since the FS review

| # | Answer | Effect in code |
|---|---|---|
| 16 | Credit segment is **2000** | `P_SEGMNT` defaults to `2000` on both selection screens, still overridable |
| — | BP3100 has no `INFOCATEGORY` / `INFOTYPE`; the fields are **`ADDTYPE`** and **`DATA_TYPE`** | A re-pointed throughout: the BP3100 read, both parameters, both F4 helps, both checks |
| 1 (part) | Hierarchy report is **`ZSD_CUSTOMER_DATA`**, called in background | Built in full in `F_GET_HIERARCHY` in both; four field names still placeholders — see Q5 |
