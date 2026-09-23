# WRICEF 147 — feasibility check against the supplied FS and logic sheets

Checked 21/09/26 against `fs/147_Overall_CC_MIS_Summary_and_Customer_wise.docx`,
`fs/147_Output_MIS_sheet.xlsx` and `fs/147_Z_Table_format.xlsx`. No system access; reasoned
from the documents and SAP knowledge only.

## Verdict

**Not buildable end to end from what was supplied. Roughly half of it is.**

The report skeleton, the Z table, and every column that comes from standard tables or from
the Z table can be built now. Everything the FS specifies as "fetch from Z report X" cannot:
the source of those seven reports was not supplied, and a report name is not a data source.
Either the source is provided (`ZR_PROG_DOWNLOAD` for the seven names below) or the
functional team writes out, per column, the tables, fields, document types and filters those
reports use. Until then those columns are guesswork and a wrong guess costs a test cycle.

Recommended implementation for the "fetch from Z report" columns is to **read the same
tables directly**, not `SUBMIT` the seven reports and scrape their ALV output
(`cl_salv_bs_runtime_info` / `LIST TO MEMORY`). Submitting seven reports per run, each over
the whole customer base, with their selection-screen names and output structures unknown,
is both slow and brittle. Reading the tables needs their logic, which is why the source is
the ask.

## Where each of the 80 output columns comes from

| Source per the logic sheet | Columns | Can build now? |
|---|---|---|
| Standard customer master (KNA1 / KNVV / KNB1 / T052U / UKMBP_CMS_SGM) | Party code, Name 1+2, Cust grp 1, Cust grp 2, City, State/region, Search term, Telebox, Data line, Payment terms text, Credit limit, Active/Inactive | Yes, once queries 6–7 are answered |
| `ZSD_CUST` — custom hierarchy / custom fields | L1–L6 (LID_n + Ln_D), Opening date (MPC date), Buying group | **No** — source of the hierarchy and of "MPC date" unknown (same as 141 ISSUES.md #1) |
| STVARV logic | Dealer/Distributor, Old/New | Yes for Paint; Adhesive rule not given (query 8) |
| Z table `ZSD_CUST_SDFI_DATA` | Net/Gross sales last FY, last-month-prev-FY net/gross, last-quarter-prev-FY net, bank collection + CN last FY, sales return gross/net last FY, Default inv % prev FY, CEI % prev FY, Avg clearing days prev FY, Exception approval CY, C.F limit, C.F child limit, Security cheques, Legal status, Dispute amt, Demand notice, DCA, Critical OD count | Yes, once the table design is settled (query 1) |
| `ZSD_RCL_NEW` (Adh) / `ZSD_SALRCL` (Paint) — sales register | Net/Gross sales CY, last-month CY net/gross, last-quarter CY net, net/gross for date range, sales returns CY and last month (gross/net) | **No** — definition of "G/L Post (Net)" and "Gross Bill Amount" columns unknown (query 13) |
| `ZFI_COLL_CRN_P` / `ZFI_COLL_CRN` — collections | Bank collection CY, Credit note CY, both for last month CY | **No** — document types / posting logic unknown (query 14) |
| `ZFI_EXCP_APPROVAL` | Default invoice % CY, CEI % CY, Avg clearing days CY, Balance confirmation, E-Agreement, Credit policy | **No** — formulas unknown; not the 141 A/B objects in this repo (query 15) |
| FBL5N logic given in sheet (BSID, UMSKZ I / Q) | Security deposit, Add. security deposit | Yes, subject to query 10 |
| `ZFICUSTAG` (Paint) / `ZFI_CRITICAL_OD` (Adh) / `ZCUSTAGDUE` — ageing | Net outstanding, OD per payment terms, Critical OD by group, Total OS / OD / Critical OD as on quarter end | **No** — ageing logic and as-on-date handling unknown (queries 9, 11) |
| BP attribute 2 / "Ask Parth Shah" | Total legal cases | **No** — open in the sheet itself (query 12) |
| Computed in report | Avg monthly net sales (quarter/3), Growth %, Total collection, Last-year total collection, Total credit limit, Total exposure, Count of billing months | Yes |

Net: about 44 columns buildable now, about 36 blocked on source or on answers.

## Queries to send back — numbered so answers can be tracked

### Blocking

1. **Z table design — the FS and the sheet disagree.** The FS lists 18 annual fields
   ("Net Sales of Last FY" etc). The sheet defines a 94-column table, month by month
   (6 measures × 12 months + totals + 15 attributes). The sheet is right: "month of previous
   FY" and "quarter of previous FY" are selection-screen inputs, so annual totals cannot
   serve them. Recommend a **narrow** table instead of the 94-column one — key
   `MANDT, KUNNR, VKORG, GJAHR (FY), MONAT` with the six monthly amounts, and a second small
   table (or a MONAT = 00 row) for the annual attributes. SM30 on 94 columns with no upload
   program, which the FS rules out, is not realistic for the user filling it.
   If the wide layout is kept, the sheet still needs fixing before it can be created:
   - Duplicate / misspelt names: `ZSALE_GROSS_MAY` appears twice (second should be
     `ZSALE_RETURN_GROSS_MAY`), `ZCOLLEDTION_APR`, `ZSALE_RETRUN_NET_AUG`,
     `ZSALE_GROSS_RETURN` (Jan gross return), `ZCOLLECION_MAR`.
   - Lengths: all amounts are given as length 30 — should be CURR 15,2 (or 23,2) with a
     currency key. Percentages (length 4) should be DEC 5,2. Clearing days (length 3) hold
     text "No Clearing data" in the sample rows — a numeric field cannot, so decide: numeric
     with 0 / initial, or CHAR. `ZSD_CODC` (a count) should be INT4, not length 30.
     YES/NO flags should be CHAR 1 or a domain with fixed values.
   - No key was marked; `MANDT` is missing; division is not in the key although Paint and
     Adhesive are reported separately (query 17).
2. **Channel finance contradiction.** FS "Additional details" says channel finance data is
   not required. The output sheet has C.F Limit, C.F Child Limit, Total credit limit
   (= credit limit + C.F) and Total exposure (= total limit ÷ avg monthly net sales), and the
   Z table has `ZCF_LIMIT` / `ZCF_CHILD_LIMIT`. Which wins? If dropped, Total exposure
   becomes credit limit ÷ avg monthly net sales.
3. **"Summary wise" is not specified.** The title promises a summary view and a customer
   view; the FS and both sheets describe only the customer view. What are the summary levels
   (L1…L6? sales org / division?), which columns aggregate, and is it a second ALV, a
   subtotal layout, or a separate selection-screen radio button?
4. **L1–L6 source.** `LID_1…LID_6` and `L1_D…L6_D` come "from ZSD_CUST". Which table holds
   the sales-officer hierarchy? Same open point as 141 A/B ISSUES.md #1, still unanswered.
   Source of `ZSD_CUST` resolves it.
5. **Opening date = "MPC Date", else customer creation date.** Which table/field is MPC
   date? Not a standard KNA1/KNVV field.
6. **Active/Inactive.** Header says "Billing block status"; logic row says "Central order
   block desc." (KNA1-AUFSD → TVAST). Which one, and is the output the code or the text?
7. **Buying group and Data line.** Confirm fields — KNA1-KONZS (group key) for buying group?
   KNA1-DATLT for data line, KNA1-TELBX for telebox, KNA1-SORTL for search term?
8. **Adhesive division rules.** Dealer/Distributor and Old/New are defined for Paint only
   (customer group 2 via STVARV). What applies for Adhesive — blank, or a different set?
9. **Critical OD thresholds** ("ASP dealer > 55 days, ASP distributor > 60, GEM/IPT > 120").
   Need the actual customer-group-1 codes for ASP, GEM, IPT (KVGR1 values) and confirmation
   that dealer/distributor here reuses the Paint STVARV. Does Adhesive use the same days?
10. **Security deposits from BSID, UMSKZ I / Q.** All open special-GL items regardless of
    GJAHR, or only the selected FY? Local currency (DMBTR) rather than WRBTR? Sign — credit
    balances shown positive?
11. **Outstanding "as on last date of month".** BSID holds open items as of today; a
    past month-end needs BSID + BSAD with clearing date after the key date. The ageing
    reports presumably already do this — their source is needed, or the rule stated.
    Also confirm "credit balance to be shown as zero" applies to all four OS/OD columns.
12. **Total legal cases** — the sheet itself says "Ask Parth Shah". BP attribute 2
    (KNA1-KATR2) for Paint: which values count as a legal case?
13. **Net vs gross sales definitions.** "G/L Post (Net)" and "Gross Bill Amount (Paint) /
    Gross Amount (Adhesive)" are column names of the two sales-register reports. Which
    VBRK/VBRP or ACDOCA amounts, which condition types or subtotal fields (KZWI1–6), and are
    cancellations (S1/S2) included in "Return/Cancel Invoice"? Are ZRE1/ZRE2 billing types
    (VBRK-FKART) or FI document types?
14. **Bank collection vs credit note.** Which FI document types / posting keys separate
    them (DZ vs DG?), and from which table (ACDOCA / BSID+BSAD)? Posting date or clearing
    date for the month bucket?
15. **`ZFI_EXCP_APPROVAL` columns** — Default invoice %, CEI %, Avg clearing days, Balance
    confirmation, E-Agreement, Credit policy. Formulas and source unknown. This is not the
    141 A/B exception-approval report already built in this repo (that one has none of
    these). Is `ZFI_EXCP_APPROVAL` a live report? Source needed.

### Clarifications (buildable with a stated assumption, but confirm)

16. **Selection screen types.** FY entered as "2025-26": define as a 4-digit fiscal year,
    FY = April–March (sample data confirms). Quarter as Q1–Q4 with Q1 = Apr–Jun. Month as
    MM. Suggest one "Current FY" input and derive Last FY = current − 1, rather than two
    free inputs that can be entered inconsistently. The sheet lists "Customer group 1"
    twice (second is group 2). The FS input list omits Customer code; the sheet has it —
    include. Company code / sales org / division: single values or select-options?
17. **Paint vs Adhesive detection.** The report must switch between the Paint logic and the
    Adhesive logic. On what — division code (which values), or sales org? Not stated.
18. **Value in lakh.** Divide every amount column by 1,00,000, two decimals? Including
    security deposits, limits and outstanding, or sales/collection columns only?
19. **Authorization** section is empty. Propose a check on V_VBRK_VKO (sales org) and
    F_BKPF_BUK (company code).
20. **Messages** section is empty. Standard set proposed: no data for selection; Z table has
    no rows for the selected FY; STVARV variable not maintained.
21. **Performance.** The FS already flags it. Propose sales org and division mandatory, and
    the Z table read once per customer set, not per column.

## What is needed to start

- `ZR_PROG_DOWNLOAD` output for: `ZSD_CUST`, `ZSD_RCL_NEW`, `ZSD_SALRCL`, `ZFI_COLL_CRN`,
  `ZFI_COLL_CRN_P`, `ZFI_EXCP_APPROVAL`, `ZFICUSTAG`, `ZFI_CRITICAL_OD`, `ZCUSTAGDUE`
  (FBL5N and UKM_BP_DISPLAY are standard; nothing needed for those).
- Answers to queries 1–15.

With those, the order of build would be: Z table + TMG → report with customer block,
Z-table columns, deposits, credit limit and computed columns → sales register columns →
collections → ageing → exception approval columns. One object at a time, per the standing
rules.
