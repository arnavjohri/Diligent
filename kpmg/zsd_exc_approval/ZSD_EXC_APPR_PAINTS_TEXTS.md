# ZSD_EXC_APPR_PAINTS — Text Elements to maintain in SE38

None of this travels with a pasted source. After pasting `ZSD_EXC_APPR_PAINTS.abap`,
go **SE38 → (enter program) → Goto → Text Elements** and maintain the three tabs below
exactly as listed, then activate.

## Reconciliation performed

Grepped the source for every text-symbol reference:

```
grep -noE "TEXT-[0-9a-zA-Z]+" ZSD_EXC_APPR_PAINTS.abap
grep -noE "'[^']*'\([a-zA-Z0-9]+\)" ZSD_EXC_APPR_PAINTS.abap
```

This finds both reference forms the source uses: `TEXT-001` / `TEXT-002` / `TEXT-003`
(the three selection-screen block titles) and `'literal'(nnn)` (every message, every
field-catalogue heading, the three approval-type literals and the five status
literals). The `+4(2)` substring offsets on lines 746 and 748
(`ls_appr-zexc_appr_month+4(2)`) are **not** text-symbol references — they are ABAP
offset/length notation, so they are excluded.

That leaves 42 distinct IDs: `001`–`003`, `C01`–`C21`, `M01`–`M10`, `S01`–`S05`,
`T01`–`T03`. Every one of the 42 appears in Table 1 below, each exactly once, with the
literal text taken verbatim from the source as the default. Nothing is listed that the
source does not reference, and nothing the source references is missing. `M01` occurs
three times in the source (twice in `F_GET_CUSTOMERS`, once in `F_GET_APPROVALS`) — one
row, not three.

Selection-screen fields were reconciled separately: every `SELECT-OPTIONS` and
`PARAMETERS` statement in the source (10 total) has exactly one row in Table 2.

Cross-checked against `ZSD_EXC_APPR_ADHESIVE_TEXTS.md` in both directions (build spec
6 says the two programs are meant to be maintained together):

- Paints adds a third selection-screen block (`003`, "Collection Document Selection")
  that Adhesive has no equivalent of, because Adhesive does not read ACDOCA.
- Paints drops Adhesive's `P_INFCAT` / `P_INFTYP` F4-help messages (`M03`, `M05`–`M10`
  in the Adhesive table) — build spec §1 / C3 omits Info Category and Info Type from
  this program entirely, so there is no F4 help to maintain and those message IDs do
  not exist here.
- Paints' `M01`–`M06` are the Adhesive equivalents of Adhesive's `M01`, `M02`, `M04`,
  `M07`, `M11`, `M12` (customer/approval-not-found, company-code-not-found,
  currency-not-found, ALV-display-failed, no-data-to-display) renumbered contiguously
  since the Info Category/Type messages are absent — same wording, different IDs, so do
  not copy Adhesive's numbering across by hand.
- Paints' `M07`–`M10` are the four `F_GET_HIERARCHY` messages added on 07/09/26. Same
  wording as Adhesive's `M13`–`M16`, different IDs for the same renumbering reason.
- Paints adds three columns and their headings that Adhesive does not carry:
  `T01`–`T03` (approval-type literals — Adhesive has no approval-type column) and the
  `C12` "Collection Commitment" / `C15` "Actual Collection" pair, which replace
  Adhesive's `C13` "Commitment Text" / `C15` "Actual OS on Commit Date" — Paints reads
  a committed amount and a real collection figure from ACDOCA where Adhesive reads a
  free-text commitment and an open-item balance. `C18`/`C19` are also new here: Paints
  splits Adhesive's single `STATUS` column into `STATUS1` + `STATUS2`.
- Both programs keep the same `C01`–`C11`, `C14`, `C16`, `C17`, `C20`(customer/name/
  hierarchy/month/number/type/dates/exceptional-amount/credit-limit/non-fulfilment/
  default-%/remarks) wording and the same selection-text labels for the seven fields
  they share (`S_KUNNR`, `S_DATE`, `P_BUKRS`, `S_VKORG`, `S_KVGR1`, `S_KVGR2`,
  `P_SEGMNT`), so the two programs read the same way to the end user wherever the
  underlying data is the same shape.

---

## 1. Text Symbols

Numeric IDs first, then alphanumeric IDs in SAP's ascending sort order (digits sort
before letters, so `001`–`003` come before `C01`…).

| No. | Text (type into SE38 as the default) | Max length | Used for |
|-----|----------------------------------------|-----------:|----------|
| 001 | Exceptional Approval Data | 25 | `SELECTION-SCREEN ... TITLE TEXT-001` — block B1 frame title |
| 002 | Organisational Data | 19 | `SELECTION-SCREEN ... TITLE TEXT-002` — block B2 frame title |
| 003 | Collection Document Selection | 29 | `SELECTION-SCREEN ... TITLE TEXT-003` — block B3 frame title |
| C01 | Customer Code | 13 | ALV column heading, KUNNR |
| C02 | Customer Name | 13 | ALV column heading, NAME1 |
| C03 | L4 Name | 7 | ALV column heading, L4_NAME |
| C04 | L5 Name | 7 | ALV column heading, L5_NAME |
| C05 | L6 Name | 7 | ALV column heading, L6_NAME |
| C06 | Approval Month | 14 | ALV column heading, EXC_MONTH |
| C07 | Serial Number | 13 | ALV column heading, EXC_NO |
| C08 | Approval Type | 13 | ALV column heading, EXC_TYPE |
| C09 | Approval Date From | 18 | ALV column heading, DATE_FROM |
| C10 | Approval Date To | 16 | ALV column heading, DATE_TO |
| C11 | Exceptional Amount | 18 | ALV column heading, EXC_AMNT |
| C12 | Collection Commitment | 21 | ALV column heading, CM_AMNT |
| C13 | Commitment Date | 15 | ALV column heading, COMMIT_DATE |
| C14 | Actual Credit Limit | 19 | ALV column heading, CREDIT_LIMIT |
| C15 | Actual Collection | 17 | ALV column heading, ACT_COLL |
| C16 | Non-Fulfilment Amount | 21 | ALV column heading, NON_FULFIL |
| C17 | Default % Non-Fulfilment | 24 | ALV column heading, DEF_PERC |
| C18 | Status-1 | 8 | ALV column heading, STATUS1 |
| C19 | Status-2 | 8 | ALV column heading, STATUS2 |
| C20 | Remarks | 7 | ALV column heading, REMARKS |
| C21 | Currency | 8 | ALV column heading, WAERS (column itself is `no_out`) |
| M01 | No customers match the selection | 32 | message, F_GET_CUSTOMERS (x2) / F_GET_APPROVALS |
| M02 | No exceptional approvals found for the selection | 48 | message, F_GET_APPROVALS |
| M03 | Company code does not exist | 27 | message, AT SELECTION-SCREEN ON P_BUKRS |
| M04 | Company code currency could not be read | 39 | message, F_GET_COMPANY_CURRENCY |
| M05 | No data to display for the selection | 36 | message, F_DISPLAY_ALV |
| M06 | The report list could not be displayed | 38 | message, F_DISPLAY_ALV |
| M07 | Sales hierarchy report not found - L4/L5/L6 left blank | 54 | message, F_GET_HIERARCHY |
| M08 | Hierarchy source is not an executable report - see TS | 53 | message, F_GET_HIERARCHY |
| M09 | Hierarchy report returned no ALV data - L4/L5/L6 blank | 54 | message, F_GET_HIERARCHY |
| M10 | Hierarchy field names do not match the report output | 52 | message, F_GET_HIERARCHY |
| S01 | Collection Received | 19 | status-1 literal, F_CALC_STATUS |
| S02 | Commitment Not due | 18 | status-1 literal, F_CALC_STATUS |
| S03 | Commitment Overdue | 18 | status-1 literal, F_CALC_STATUS |
| S04 | Fulfilled | 9 | status-2 literal, F_CALC_STATUS |
| S05 | Not Fulfilled | 13 | status-2 literal, F_CALC_STATUS |
| T01 | Credit Limit | 12 | approval-type literal, F_BUILD_OUTPUT (ZEXC_APPR_TYPE = '1') |
| T02 | Overdue | 7 | approval-type literal, F_BUILD_OUTPUT (ZEXC_APPR_TYPE = '2') |
| T03 | Credit Limit & Overdue | 22 | approval-type literal, F_BUILD_OUTPUT (ZEXC_APPR_TYPE = '3') |

42 rows, 42 distinct IDs referenced in the source — the two sets match.

## 2. Selection Texts

One row per `SELECT-OPTIONS` / `PARAMETERS` on the selection screen, in source order.
Type the label into the **Text** column of the Selection Texts tab against the field
name shown; SE38 pre-lists the field names automatically, this table is what to type
next to each.

| Field name | Statement | Label to enter |
|---|---|---|
| S_KUNNR | SELECT-OPTIONS FOR KNVV-KUNNR | Customer Number |
| S_DATE | SELECT-OPTIONS FOR ZSD_EXP_PAINTS-ZEXC_DATE_FROM | Approval Date |
| P_BUKRS | PARAMETERS TYPE KNB1-BUKRS | Company Code |
| S_VKORG | SELECT-OPTIONS FOR KNVV-VKORG | Sales Organization |
| S_SPART | SELECT-OPTIONS FOR KNVV-SPART | Division |
| S_KVGR1 | SELECT-OPTIONS FOR KNVV-KVGR1 | Customer Group 1 |
| S_KVGR2 | SELECT-OPTIONS FOR KNVV-KVGR2 | Customer Group 2 |
| P_SEGMNT | PARAMETERS TYPE UKMBP_CMS_SGM-CREDIT_SGMNT | Credit Segment |  <!-- defaults to 2000, FS deviation 13 -->
| P_RLDNR | PARAMETERS TYPE ACDOCA-RLDNR | Ledger |
| S_BLART | SELECT-OPTIONS FOR ACDOCA-BLART | Document Type |

10 rows — every SELECT-OPTIONS/PARAMETERS statement in the source has one.

## 3. List Headings / Title

The program is screen-free ALV only (`REUSE_ALV_GRID_DISPLAY_LVC`, no `WRITE`, no
classical list, no `TOP-OF-PAGE`), so the **Header**, **Column heading** and **Key
word** fields on the List Headings tab are not read by this program at runtime — leave
them blank.

Set only the **Title**:

| Field | Text |
|---|---|
| Title | Exceptional Approval Report - Paints |

This matches the program title given in the header comment of
`ZSD_EXC_APPR_PAINTS.abap` and the FS reference in `BUILD_SPEC_141B.md` §6; it is
cosmetic only for this ALV-grid program (it would appear in the status bar of a
classical list, which this program never produces).
