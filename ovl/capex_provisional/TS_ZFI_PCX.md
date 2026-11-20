# TS — ZFI_PCX Provisional Capex entry and reports (SAP_Automation_Provisional_Capex_Process_-V3.xlsx)

## 1. Document control

Version 1.0 · Arnav Johri · 20.11.2026 · Project OVL · Related FS: `SAP_Automation_Provisional_Capex_Process_-V3.xlsx` (received 18.11.2026) · Queries: `CAPEX_PROVISIONAL_Assumptions_and_Queries.docx` · Status: built, not yet imported or tested.

## 2. Purpose

Corporate Budgeting collects provisional Capex from the Business Units every fortnight in Excel. This development moves the entry into SAP: the BU enters the cumulative Capex per project and category for the open fortnight, SAP pre-fills the prior reported figures, refuses a total below them and freezes closed fortnights. The workbook tabs are produced as reports from the saved figures. All amounts are manual entries; nothing is read from postings and no standard object is changed. Opex / Survey is not part of this version.

## 3. Objects affected

| Object | Type | New / changed | Package | TR |
|---|---|---|---|---|
| 10 domains `ZFI_PCX_*` | Domain | New | at import | `<TR>` |
| 27 data elements `ZFI_PCX_*` | Data element | New | at import | `<TR>` |
| `ZFI_PCX_ENT`, `ZFI_PCX_PROJ`, `ZFI_PCX_FY`, `ZFI_PCX_PERIOD`, `ZFI_PCX_FYPROJ` | Table, maintained in SM30 | New | at import | `<TR>` |
| `ZFI_PCX_CAPEX` | Table, written by the entry program | New | at import | `<TR>` |
| `ZFI_PCX_ENTRY` | Executable program | New | at import | `<TR>` |
| `ZFI_PCX_REPORT` | Executable program | New | at import | `<TR>` |

Field lists of all domains, data elements and tables: `ddic/01_domains_data_elements.md`.

## 4. Detailed design

### 4.1 Manual steps, in order

1. `ZABAPGIT_STANDALONE`: new offline repository on the chosen package, import `ZFI_PCX.zip`, pull, activate.
2. SE11, Table Maintenance Generator (one step, function group of the same name) for `ZFI_PCX_ENT`, `ZFI_PCX_PROJ`, `ZFI_PCX_FY`, `ZFI_PCX_PERIOD`, `ZFI_PCX_FYPROJ`.
3. SU20: authorisation field `ZPCX_BU` with data element `ZFI_PCX_BU`. SU21: object `ZFI_PCX` with fields `ZPCX_BU` and `ACTVT`, permitted activities 02 (enter), 03 (display), 70 (correct a frozen fortnight). PFCG: roles per Business Unit.
4. SM30: entities and projects from the load sheets in `load/`; Business Unit per project; 24 calendar rows per year in `ZFI_PCX_PERIOD` with cutoff date and rate; BE and RE rate in `ZFI_PCX_FY`; budgets and opening ITD in `ZFI_PCX_FYPROJ`.
5. SE93: report transactions `ZFI_PCX01` (program `ZFI_PCX_ENTRY`) and `ZFI_PCX02` (program `ZFI_PCX_REPORT`).
6. Each fortnight: Corporate Budgeting sets status `F` on the closed fortnight and `O` on the next one in `ZFI_PCX_PERIOD`.

### 4.2 Program ZFI_PCX_ENTRY

| Unit | What it does |
|---|---|
| `FORM run` | Reads the fortnight from `ZFI_PCX_PERIOD`. Status O: entry. Status F with *Correct a Frozen Fortnight*: entry with activity 70. Otherwise display. |
| `FORM read_projects` | Active projects of the selection; one `AUTHORITY-CHECK OBJECT 'ZFI_PCX'` per Business Unit; projects without authorisation are left out with a message. |
| `FORM read_amounts` | Prior reported = latest earlier fortnight with a row. Current fortnight row if saved, else the prior figures as pre-fill. Total of the next later saved fortnight as upper limit. |
| `FORM lock_rows` | `ENQUEUE_E_TABLE` per project and fortnight; a project locked by another user is left out with a message. |
| `FORM check_row` | Refuses a negative amount, a total below prior reported, a total above the next later fortnight. |
| `METHOD on_finished` | After each cell change: check, put the cells back if refused, recalculate total, increase and colours. |
| `FORM derive_row` | Colours: 1 (grey-blue) frozen, 3 (yellow) pre-filled, 5 (green) entered. |
| `FORM save` | Writes only the rows changed in the session to `ZFI_PCX_CAPEX` with user, date and time; `COMMIT WORK`. |
| `FORM display` | Editable `CL_GUI_ALV_GRID` on `CL_GUI_CONTAINER=>DEFAULT_SCREEN`; Save is a button in the grid toolbar (no screen, no GUI status). |

### 4.3 Program ZFI_PCX_REPORT

| View (radio button) | Workbook tab | Calculation |
|---|---|---|
| Cumulative Capex by Category | Capex USD, Tab 1 | Latest entered figures as at the fortnight; prior reported; increase. |
| Cumulative Capex per Fortnight | Capex USD, cumulative history | Cumulative total for each fortnight up to the selected one; a fortnight without entry carries the last figure. |
| Capex per Period, USD Million | Capex USD, YTD with utilisation | Mid-month column = increase in the first fortnight; month = increase in the month; quarter; to date; BE / RE balance; utilisation %. |
| Capex per Period, INR Crore | Capex INR, Tab 4 | USD x rate / 10, 2 decimals: 15-day rate for the mid-month column, monthly rate on the month total; BE and RE with the budget rates. |
| Capex by Entity, INR Crore | Capex INR, Tab 5 | INR rows added up per entity of the project master; entities without project shown with zero; utilisation from the totals. |
| Capex by Category, INR Crore | Capex INR, Tab 6 | Category figures x one factor (INR to date / USD to date, 5 decimals); difference to the INR figure to date. |
| Inception to Date, USD / INR | Capex USD Tab 3, Capex INR Tab 7 | Opening ITD + prior-year Capex + quarters of the current year. |

Units: `FORM read_data`, `build_base`, `finish_wide`, `add_wide`, `total_wide`, `cols_wide`, `view_cum`, `view_his`, `view_ent`, `view_cat`, `view_itd`, `show`.

## 5. Requirement mapping

| Requirement | Implemented by |
|---|---|
| 1 Category-wise cumulative entry per fortnight by BU | `ZFI_PCX_ENTRY`, table `ZFI_PCX_CAPEX` |
| 2 Error if below the prior period; error values not accepted | `FORM check_row`, called on cell change and on save |
| 3 BU cannot decrease | `FORM check_row`; correction mode needs activity 70 |
| 4 Prior reported pre-filled until something is entered | `FORM read_amounts` |
| 5 Colours for frozen, pre-filled, entered | `FORM derive_row`; status in `ZFI_PCX_PERIOD` |
| Workbook tabs 1 to 8 (Capex) | the eight views of `ZFI_PCX_REPORT` |
| Opex / Survey sheets | not in this version |

## 6. Test scenarios

| # | Input | Expected | Actual |
|---|---|---|---|
| 1 | Entry, fortnight 01 open, nothing saved | All projects, prior 0, cells yellow and editable | |
| 2 | Enter 1 / 2 / 3 / 4 for one project, Save | Total 10, row green, row in `ZFI_PCX_CAPEX` with user and date | |
| 3 | Freeze 01, open 02, run entry for 02 | Prior reported 10, cells pre-filled 1 / 2 / 3 / 4 in yellow | |
| 4 | In 02 change the cells so that the total is 9 | Message, cells back to the previous values, nothing saved | |
| 5 | In 02 lower one category and raise another, total 12 | Accepted | |
| 6 | Type a negative amount | Refused | |
| 7 | Run entry for frozen fortnight 01 without correction mode | Display only, grey-blue | |
| 8 | Correction mode on 01 with activity 70; raise the total above the total of 02 | Refused | |
| 9 | Two users, same project and fortnight | Second user: project left out with a message | |
| 10 | User without authorisation for a Business Unit | Its projects left out with a message | |
| 11 | Report, each of the eight views, as at 02 | Figures agree with a hand calculation from the workbook formulas | |
| 12 | Report for a year with fewer than 24 calendar rows | Message, no list | |

## 7. Open points

1. All 24 queries are open; the build uses the "assumed if no answer" column. Items 5, 6, 8, 10, 11 and 13 change tables or rules if answered differently.
2. Business Unit list and project-to-BU assignment are not in the workbook; the BU column of the project load sheet is empty.
3. Leaving the entry list with Back gives no warning about unsaved cells (no GUI status).
4. The total row of the reports is a normal row and moves when the user sorts.
5. The editable grid on the default screen and the fixed-value domains have not been imported or run on this landscape before.
6. Opex / Survey entry and its reports are a second step.
