# Provisional Capex / Opex fortnightly punching (OVL)

**Project:** OVL (ONGC Videsh) · Corporate Budgeting / finance MIS
**Status (20/11/26):** FS received 18/11/26, sent again 20/11/26 — byte-identical to
`original/SAP_Automation_Provisional_Capex_Process_V3.xlsx`. Feasible. **Nothing built.**
Queries issued (`ASSUMPTIONS_AND_QUERIES.md`, Word copy
`FSD/CAPEX_PROVISIONAL_Assumptions_and_Queries.docx`) and object list proposed (below).
Build starts only after the list is approved and query items 1, 3, 5, 8, 10, 11, 13, 15 are
answered — they fix table keys and field types. Object names are proposals.

## What the workbook asks for

Sheets `Capex USD` / `Capex INR`, `Opex USD` / `Opex INR`, and three hidden ones:
`OVL JV Code List-21.12.22`, `Capex Process`, `Opex Process`. The two Process sheets are a
reviewer's write-up of an **earlier layout** — their findings (C1–C8, O1–O8) hold, their cell
addresses do not match V3. Tab numbers also differ between the sheets and the write-up; the
table below uses the write-up's 1–8.

The five numbered requirements at the top of `Capex USD` are the actual SAP ask:

1. BU punches the **category-wise cumulative Capex** (EWIP, DWIP, CWIP, Other) per project at
   each fortnight end (15th and month-end), USD million. 71 project rows, 24 fortnights a year.
2. If cumulative Capex is **less than the prior fortnight**, show an error.
3. BU **cannot decrease** cumulative Capex; minimum is the prior reported amount.
4. SAP **pre-fills the prior reported cumulative** until something is punched in the current period.
5. **Three colour states**: frozen (not changeable by BU), pre-filled, punched this fortnight.

Two more rules sit further down: `Capex USD` B174 *"error values should not be accepted by SAP"*
(so a decrease is a hard error, not the Excel's silent zero) and `Opex USD` D3 *"Negative No.s
can't be punched"*.

Everything else in the workbook is derived from that one input table:

| Tab | Content | Needs besides the punched data |
|---|---|---|
| 2 | Cumulative per fortnight, all 24 periods side by side | nothing (history) |
| 3 | Marginal USD per fortnight = cum(t) - cum(t-1); month, quarter, YTD; BE/RE balance and utilisation % | BE/RE per project per FY |
| 4 | Same in INR crore: USD mn x TTA rate / 10, 15-day rate for the mid-month column, monthly rate for the month column, rounded 2 dp | rate per period, BE rate, RE rate |
| 5 | Roll-up of projects into subsidiaries / incorporated JVs | project -> entity mapping |
| 6 | Cumulative category-wise in INR via one weighted factor (total INR to date / total USD to date) | derived |
| 7, 8 | Inception-to-date roll-forward, INR and USD: opening ITD + prior-year Capex + current YTD | opening ITD and prior-year Capex per project |
| Opex | Per fortnight, two components (Opex, Survey), negatives not allowed; consolidated blocks / equity investees summary | BE/RE per component, class per project |

Facts counted from the file on 20/11/26:

- JV Code column (`Capex INR` D12:D82): **49 of 71 rows have no code, 6 carry several, 16 carry
  one.** Not usable as a key. The codes are JVA joint ventures of company code `OVL`.
- `Opex USD` lists the same 71 projects in a **different row order** from the Capex sheets —
  nothing may be matched by row position.
- Tab 1 shows four fortnight blocks only (15 Apr – 31 May 2027); the other twenty are implied
  by the headings of the YTD tab.
- Opex month column: `K8` = 6.3 and `M8` = 12 are both typed, header says "Calculated" —
  query item 4.
- Template errors that must not be copied: `Capex INR` F108:L108 omit row 79 which E108
  includes; the Tab 5 check row compares shifted columns; `Opex USD` BS8 takes the Opex RE
  balance from the Survey RE; Sakhalin I changes class between BE and actuals; `Opex INR` has
  no /10.

## Verdict: feasible, but not a report. A punching transaction plus reports on top.

A report reads and displays. Requirements 1-5 are persistence, pre-fill from the prior
period, a validation against stored data, a period freeze, and per-cell state. None of that
exists without custom tables. No standard object is touched, nothing is read from postings,
volume is trivial (71 x 24 rows a year) — the risk is in the unanswered rules, not the ABAP.

Why an editable `CL_GUI_ALV_GRID` in an executable program, and not the alternatives:

- **Module pool + table control**: SE51 screens and SE41 status, all manual, for a flat grid
  the ALV already renders. No gain.
- **SM30 on the amounts table**: no pre-fill, no cross-period validation, no colour states,
  no freeze without SE54 events. Fine for the master tables, wrong for BU entry.
- **RAP / Fiori elements**: the modern answer, but OCQ is an older release (`MEMORY.md` §4),
  a 71 x 4 grid entry is clumsy in Fiori elements inline edit, and build plus BAS deployment
  is several times the effort. Phase-2 option if BUs must enter from a browser.
- **Excel upload program**: loses the pre-fill and colour interaction; could be added later
  as a second input path on the same tables.

## Proposed object list (20/11/26) — in dependency order, which is paste order

Built on the "assumed if no answer" column of the queries. Not approved yet.

| # | Object | Type | Purpose | Depends on |
|---|---|---|---|---|
| 1 | `ZFI_PCX_*` domains and data elements (about 12) | DDIC | project number, fortnight number, amount (DEC 15,2), rate (DEC 9,5), period status, Opex class, BU, entity number, texts — readable headings in SM30 and ALV | — |
| 2 | `ZFI_PCX_ENT` | table, SM30 | Tab 5 entities: number, name, type, sort number | 1 |
| 3 | `ZFI_PCX_PROJ` | table, SM30 | project master: number, name, sort number, active flag, BU, entity, JV code as text, Opex class | 1, 2 |
| 4 | `ZFI_PCX_FY` | table, SM30 | per year: BE rate, RE rate | 1 |
| 5 | `ZFI_PCX_PERIOD` | table, SM30 | per year and fortnight 01–24: cutoff date, status open / frozen, TTA rate | 1 |
| 6 | `ZFI_PCX_FYPROJ` | table, SM30 | per year and project: Capex BE and RE; opening ITD and prior-year Capex, USD and INR | 1, 3 |
| 7 | `ZFI_PCX_CAPEX` | table | punched cumulative EWIP / DWIP / CWIP / Other per year, fortnight and project; changed by / on / at | 1, 3, 5 |
| 8 | `EZFI_PCX_CAPEX` | lock object | one user per project and fortnight at a time | 7 |
| 9 | `ZFI_PCX` | message class | messages of both programs | — |
| 10 | `ZFI_PCX_ENTRY` + includes `_TOP`, `_SEL`, `_CLS`, `_F01` | executable program | BU entry: editable grid, pre-fill, checks, three colours, save; correction mode for Corporate Budgeting | 1–9 |
| 11 | `ZFI_PCX_REPORT` + includes | executable program | the tabs as views: cumulative by category, marginal USD with utilisation, INR, entity roll-up, category-wise INR, ITD INR, ITD USD | 1–7, 9 |
| 12 | Step 2, Opex: `ZFI_PCX_OPEX` (+ lock), Opex / Survey BE and RE fields on `ZFI_PCX_FYPROJ`, Opex view in 10, Opex USD / INR views in 11 | table + changes | Opex and Survey entry and reports | 1–11 |

Manual, never delivered as code: SE54 maintenance generation for tables 2–6; SE93 transaction
codes (entry, report, the SM30 calls); SU21 authorisation object (BU + activity) and the PFCG
roles; package and transport.

Screen: first choice is the grid on `CL_GUI_CONTAINER=>DEFAULT_SCREEN` with Save / Check as
grid-toolbar buttons — no SE51 screen and no SE41 status. `kpmg/zpp_forecast_v2` proves that
container for a display SALV only; **an editable grid on it is not yet proven on this
landscape.** Fallback: one screen 0100 with a custom container and one GUI status, keyed by hand.

### FS requirement → object

| Requirement (where) | Implemented by |
|---|---|
| 1 Category-wise cumulative punching per fortnight by BU (`Capex USD` C5) | `ZFI_PCX_ENTRY`, stored in `ZFI_PCX_CAPEX` |
| 2 Error if below prior period (C6); B174 not accepted by SAP | `ZFI_PCX_ENTRY` check on cell change and again on save |
| 3 BU cannot decrease (C7) | same check; correction mode by authorisation |
| 4 Prior reported pre-filled (C8) | `ZFI_PCX_ENTRY` read of the latest earlier fortnight |
| 5 Three colours, frozen not changeable (C9) | `ZFI_PCX_ENTRY` cell colour and cell style; status in `ZFI_PCX_PERIOD` |
| Tab 1 / Tab 2 cumulative, every period retained | `ZFI_PCX_CAPEX` keeps each fortnight; `ZFI_PCX_REPORT` view |
| YTD marginal USD, BE / RE balance, utilisation | `ZFI_PCX_REPORT` view; BE / RE from `ZFI_PCX_FYPROJ` |
| Tab 4 INR | `ZFI_PCX_REPORT` view; rates from `ZFI_PCX_PERIOD`, `ZFI_PCX_FY` |
| Tab 5 entity contribution | `ZFI_PCX_REPORT` view; `ZFI_PCX_ENT`, `ZFI_PCX_PROJ` |
| Weighted rate and Tab 6 category-wise INR | `ZFI_PCX_REPORT` view |
| Tabs 7 / 8 inception to date | `ZFI_PCX_REPORT` views; opening figures from `ZFI_PCX_FYPROJ` |
| Opex: no negatives; Opex USD / INR; consolidated / equity summary | step 2 (object 12) |
| JV code list | attribute on `ZFI_PCX_PROJ`, information only |
| Process sheet findings C1–C8, O1–O8 | not requirements. C1–C3 are closed by the design; the rest are query items |

**Gaps — in the requirement but in no sheet:** the list of Business Units and the
project-to-BU assignment; who may enter, display and correct; who freezes a fortnight and when.
Raised as query items 8 and 11, not invented.

## Shipping

Programs by paste. DDIC (domains, data elements, tables, lock object) by SE11 / ADT by hand —
hand-written abapGit XML has not yet imported on this landscape. SM30 generation (SE54), SU21
object and SE93 codes are manual in any case.
