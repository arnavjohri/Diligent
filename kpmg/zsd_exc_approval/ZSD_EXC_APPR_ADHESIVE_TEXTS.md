# ZSD_EXC_APPR_ADHESIVE — Text Elements to maintain in SE38

None of this travels with a pasted source. After pasting `ZSD_EXC_APPR_ADHESIVE.abap`,
go **SE38 → (enter program) → Goto → Text Elements** and maintain the three tabs below
exactly as listed, then activate.

## Reconciliation performed

Grepped the source for every text-symbol reference:

```
grep -noE "TEXT-[0-9a-zA-Z]+" ZSD_EXC_APPR_ADHESIVE.abap
grep -noE "'[^']*'\([a-zA-Z0-9]+\)" ZSD_EXC_APPR_ADHESIVE.abap
```

This finds both reference forms the source uses: `TEXT-001` / `TEXT-002` (the two
selection-screen block titles) and `'literal'(nnn)` (every message and field-catalogue
string, plus the two status literals). The `(BSID)` on line 93 and the `(4)` / `(2)` /
`(1)` offsets on lines 694, 760–762 and 1032 are **not** text-symbol references — they
are comment prose and substring offsets (`lv_clean+lv_pos(1)`, `lv_clean(4)`,
`ls_appr-datefr+4(2)`), so they are excluded.

That leaves 38 distinct IDs: `001`, `002`, `C01`–`C19`, `M01`–`M15`, `S01`, `S02`. Every
one of the 38 appears in Table 1 below, each exactly once, with the literal text taken
verbatim from the source as the default. Nothing is listed that the source does not
reference, and nothing the source references is missing. The two `(m09)` occurrences
(lines 247 and 328) are the same symbol used twice — one row, not two.

Selection-screen fields were reconciled separately: every `SELECT-OPTIONS` and
`PARAMETERS` statement in the source (9 total) has exactly one row in Table 2.

---

## 1. Text Symbols

Numeric IDs first, then alphanumeric IDs in SAP's ascending sort order (digits sort
before letters, so `001`, `002` come before `C01…`).

| No. | Text (type into SE38 as the default) | Max length | Used for |
|-----|----------------------------------------|-----------:|----------|
| 001 | Exceptional Approval Data | 25 | `SELECTION-SCREEN ... TITLE TEXT-001` — block B1 frame title |
| 002 | Organisational Data | 19 | `SELECTION-SCREEN ... TITLE TEXT-002` — block B2 frame title |
| C01 | Customer Code | 13 | ALV column heading, KUNNR |
| C02 | Customer Name | 13 | ALV column heading, NAME1 |
| C03 | L4 Name | 7 | ALV column heading, L4_NAME |
| C04 | L5 Name | 7 | ALV column heading, L5_NAME |
| C05 | L6 Name | 7 | ALV column heading, L6_NAME |
| C06 | Approval Month | 14 | ALV column heading, EXC_MONTH |
| C07 | Exception Number | 16 | ALV column heading, EXC_NO |
| C08 | Approval Type | 13 | ALV column heading, EXC_TYPE |
| C09 | Approval Date From | 18 | ALV column heading, DATE_FROM |
| C10 | Approval Date To | 16 | ALV column heading, DATE_TO |
| C11 | Exceptional Amount | 18 | ALV column heading, EXC_AMNT |
| C12 | Commitment Date | 15 | ALV column heading, COMMIT_DATE |
| C13 | Commitment Text | 15 | ALV column heading, COMMIT_TEXT |
| C14 | Actual Credit Limit | 19 | ALV column heading, CREDIT_LIMIT |
| C15 | Actual OS on Commit Date | 24 | ALV column heading, ACT_OS |
| C16 | Non-Fulfilment Amount | 21 | ALV column heading, NON_FULFIL |
| C17 | Default % Non-Fulfilment | 24 | ALV column heading, DEF_PERC |
| C18 | Status | 6 | ALV column heading, STATUS |
| C19 | Currency | 8 | ALV column heading, WAERS (column itself is `no_out`) |
| M01 | No customers match the selection | 32 | message, F_GET_CUSTOMERS / F_GET_APPROVALS |
| M02 | No exceptional approvals found for the selection | 48 | message, F_GET_APPROVALS |
| M03 | Enter the information category first | 36 | message, F4 help for P_INFTYP |
| M04 | Company code does not exist | 27 | message, AT SELECTION-SCREEN ON P_BUKRS |
| M05 | Information category does not exist | 35 | message, AT SELECTION-SCREEN ON P_INFCAT |
| M06 | Information type not valid for this category | 44 | message, AT SELECTION-SCREEN ON P_INFTYP |
| M07 | The report list could not be displayed | 38 | message, F_DISPLAY_ALV |
| M08 | No information categories are maintained | 40 | message, F4 help for P_INFCAT |
| M09 | Value help could not be displayed | 33 | message, F4 help for P_INFCAT and P_INFTYP (used twice) |
| M10 | No information types for this category | 38 | message, F4 help for P_INFTYP |
| M11 | Company code currency could not be read | 39 | message, F_GET_COMPANY_CURRENCY |
| M12 | No data to display for the selection | 36 | message, F_DISPLAY_ALV |
| M13 | Sales hierarchy report not found - L4/L5/L6 left blank | 54 | message, F_GET_HIERARCHY |
| M14 | Hierarchy source is not an executable report - see TS | 53 | message, F_GET_HIERARCHY |
| M15 | Hierarchy report returned no ALV data - L4/L5/L6 blank | 54 | message, F_GET_HIERARCHY |
| S01 | Not Fulfilled | 13 | status literal, F_BUILD_OUTPUT |
| S02 | Fulfilled | 9 | status literal, F_BUILD_OUTPUT |

35 rows, 35 distinct IDs referenced in the source — the two sets match.

## 2. Selection Texts

One row per `SELECT-OPTIONS` / `PARAMETERS` on the selection screen, in source order.
Type the label into the **Text** column of the Selection Texts tab against the field
name shown; SE38 pre-lists the field names automatically, this table is what to type
next to each.

| Field name | Statement | Label to enter |
|---|---|---|
| S_KUNNR | SELECT-OPTIONS FOR KNVV-KUNNR | Customer Number |
| P_INFCAT | PARAMETERS TYPE UKM_INFOCAT-INFOCATEGORY | Information Category |
| P_INFTYP | PARAMETERS TYPE UKM_INFOTYP-INFOTYPE | Information Type |
| S_DATE | SELECT-OPTIONS FOR BP3100-DATEFR | Approval Date |
| P_BUKRS | PARAMETERS TYPE KNB1-BUKRS | Company Code |
| S_VKORG | SELECT-OPTIONS FOR KNVV-VKORG | Sales Organization |
| S_KVGR1 | SELECT-OPTIONS FOR KNVV-KVGR1 | Customer Group 1 |
| S_KVGR2 | SELECT-OPTIONS FOR KNVV-KVGR2 | Customer Group 2 |
| P_SEGMNT | PARAMETERS TYPE UKMBP_CMS_SGM-CREDIT_SGMNT | Credit Segment |  <!-- defaults to 2000, FS deviation 7 -->

9 rows — every SELECT-OPTIONS/PARAMETERS statement in the source has one.

## 3. List Headings / Title

The program is screen-free ALV only (`REUSE_ALV_GRID_DISPLAY_LVC`, no `WRITE`, no
classical list, no `TOP-OF-PAGE`), so the **Header**, **Column heading** and **Key
word** fields on the List Headings tab are not read by this program at runtime — leave
them blank.

Set only the **Title**:

| Field | Text |
|---|---|
| Title | Exceptional Approval Report - Adhesives |

This matches the program title given in `BUILD_SPEC_141A.md` §"Title" and is also
the title SE38 shows in the object list / program attributes; it is cosmetic only for
this ALV-grid program (it would appear in the status bar of a classical list, which
this program never produces).
