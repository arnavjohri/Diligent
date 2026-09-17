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

## 02/09/26 — first paste of ZSD_EXC_APPR_ADHESIVE

Syntax check stopped at ONE error, in `FORM f_get_approvals`:
`Unknown column name INFOCATEGORY` on the `SELECT ... FROM bp3100`. Everything the check
reached before that line resolved (UKM_INFOCAT-INFOCATEGORY, UKM_INFOTYP-INFOTYPE /
-INFOCATEGORY, BP3100-PARTNER / COUNTER / DATEFR / DATETO / AMNT / TEXT, CHAR40 / CHAR30 /
CHAR15 / CHAR7). Arnav corrected the WHERE clause by hand in SE38 and the program is active
in the system; the corrected field name was not sent back, so the repo copy stayed on the
failed version until 05/09/26 (item 17 below).

## 05/09/26 — full review of 141 A/B (both programs, upload, ZIP, docs)

| # | Doc | Item | Problem | Needed from functional / Arnav |
|---|-----|------|---------|--------------------------------|
| 17 | A | BP3100 category filter | BP3100 has no `INFOCATEGORY` column (activation error 02/09/26). Repo copy now filters on `INFOTYPE` only; the category is enforced on the selection screen (P_INFTYP must belong to P_INFCAT). `BP3100-INFOTYPE` itself is still unconfirmed by an activation. | **Arnav:** `ZR_PROG_DOWNLOAD` of the active `ZSD_EXC_APPR_ADHESIVE`, so the repo copy can be reconciled with the WHERE clause that actually activated. Until then A stays out of the ZIP. |
| 18 | A+B | BP number = customer number | `BP3100-PARTNER` and `UKMBP_CMS_SGM-PARTNER` are compared directly with `KUNNR`. Holds only with CVI same-number assignment. If not, A finds no approvals and both reports show zero limits. | Confirm BP and customer share the number range (SE16N `CVI_CUST_LINK`, PARTNER_GUID vs CUSTOMER). |
| 19 | A | Actual OS composition | Every BSID/BSAD line is summed: normal receivables, special G/L items (down payments, bills of exchange, deposits) and noted items (down-payment requests). The FS draws no line; FBL5N would exclude noted items. | Confirm whether special G/L and noted items count toward "Actual OS as on Commitment Date". |
| 20 | A | Division on the Adhesives screen | Yogesh Vanani's FS comment asks for division; the FS input table omits it. Built as an OPTIONAL range `S_SPART` (blank = all divisions). | Confirm optional is right, or make it obligatory as in Paints. |
| 21 | A | Commitment date spellings | Parser now also accepts a two-digit year (`05.08.26` → 2026) and month-first order when the middle part cannot be a month (`7/25/2026`). An ambiguous `8/5/2026` stays day-first, 8 May. | Still open under #3: the agreed entry convention for `BP3100-TEXT`. |
| 22 | B | abapGit ZIP shape | `ZSD_EXC_APPROVAL.zip` rebuilt 05/09/26: DDIC XML element order corrected (DDTEXT after SIGNFLAG/VALEXI/LOWERCASE in DD01V; REFTABLE/REFFIELD before NOTNULL/COMPTYPE in DD03P), `REFKIND D` added to the six data elements, `CLIDEP X` and `EXCLASS 4` added to DD02V, table short text aligned to the build sheet, selection-text LENGTH values corrected (+8), ZIP written without directory entries. See `ZIP_IMPORT_NOTES.md`. | **Arnav:** try the ZIP once more; if it dumps, capture the file abapGit names in ST22 and fall back to paste. |
| 23 | — | Root cause of the `zfi_tds_cl34` import dumps | Its `.abapgit.xml` is wrapped in an `<abapGit ...>` element. abapGit reads `.abapgit.xml` with `CALL TRANSFORMATION id` directly (`zcl_abapgit_dot_abapgit=>from_xml`, the very frame named in the dump), and that transformation needs a bare `<asx:abap>` root. Object XML files, by contrast, MUST carry the wrapper. This folder's `.abapgit.xml` is bare and correct. | Nothing for functional. Recorded in `kpmg/zfi_tds_cl34/NOTES.md` and `CLAUDE.md`. |

Also done 05/09/26, no functional input needed: `GT_APPR` sorted (A), commitment date
linked to its approval row by position instead of by PARTNER + COUNTER (A), BSID/BSAD and
ACDOCA reads driven by the approval partners instead of every customer of the company code
(A and B), ASSUMPTION tags added for deviations 9/10/11 (A), Adhesives TS wording corrected
(0.00, not blank, for cleared amounts), `fs/141B_extract.md` added.

## 17/09/26 — reported on Teams by Sanjay Modhvadiya: "L5 name is not coming"

Screenshots of `ZSD_EXC_APPR_ADHESIVE` output for customers 0001000000 (CPI Test Customer,
five approvals of 07/2026) and 0001000724 (IDS DISTRIBUTORS-F&S, 09/2026). L4 Name, L5 Name
and L6 Name are blank on every row. That is **open issue #1, not a defect**: the FS names
`SAPLSLVC_FULLSCREEN` as the source of the three names, and that is the program name every
ALV full-screen list shows under System -> Status — the FS author read it off the screen of
some existing report, and *that report* is the real source. `f_get_hierarchy` is a deliberate
stub (build spec §3 step 6) in both reports and stays one until the source is named.

Needed from Sanjay: the transaction or report he had open when he saw L4/L5/L6 for a
customer, or the table that holds them (KNVP partner functions with a sales-employee
number? a Z sales-hierarchy table keyed by customer or by sales office/group? KNVH?). One
FORM changes once that arrives, in both reports.

What the screenshots also confirm: the program is active and runs end to end on the
system copy — BP3100 PARTNER/COUNTER/DATEFR/DATETO/AMNT/TEXT resolve, the commitment date
is read out of the free text (04.08.2026), the BSID/BSAD as-on figure works (12,359,932.39
against a 65,006.00 limit -> Not Fulfilled, 18,913.53 %), and rows without a commitment date
or without a limit show 0.00 and a blank status as designed. Item #17 (reconcile the repo
copy with the active one) is still open.

| # | Doc | Item | Problem | Needed |
|---|-----|------|---------|--------|
| 24 | B | Overlapping approval windows | Two approvals of one customer whose windows overlap both count a receipt posted inside the overlap — each row sums its own window. Nothing prevents overlapping windows. `" ASSUMPTION:` note in `f_calc_collection`. | Accept, or name an allocation rule (earliest commitment first?). |
| 25 | B | Upload: COMMIT WORK AND WAIT semantics | The 02/09/26 build did `ROLLBACK WORK` and logged "rolled back" when SY-SUBRC <> 0 after the commit. A direct MODIFY is already durable at that point; the non-zero code only means a registered update task failed. Corrected 17/09/26: the rows count as written, the summary warns and points at SM13 (new text symbol M06). | Nothing — recorded for the TS. |

Also 17/09/26 (B, upload): an amount with more than two decimals is rejected (it was rounded
silently), the amount length check allows for the decimal point (24 characters), and the
header comments of all three programs no longer claim the block titles have literal defaults
(bare `TEXT-nnn` references are blank until Text Elements is maintained).
