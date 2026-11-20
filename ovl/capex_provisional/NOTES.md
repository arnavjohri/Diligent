# Provisional Capex / Opex fortnightly punching (OVL)

**Project:** OVL (ONGC Videsh) · Corporate Budgeting / finance MIS
**Status (20/11/26):** FS received 18/11/26, sent again 20/11/26 — byte-identical to
`original/SAP_Automation_Provisional_Capex_Process_V3.xlsx`. Feasible. 
Queries issued (`ASSUMPTIONS_AND_QUERIES.md`, Word copy
`FSD/CAPEX_PROVISIONAL_Assumptions_and_Queries.docx`) and object list proposed (below).
**20/11/26, Arnav: assume and build, everything as an abapGit ZIP.** The "assumed if no answer"
column of the queries is the build basis. **Built, not imported, not tested:** `ZFI_PCX.zip`
(10 domains, 27 data elements, 6 tables, 3 programs — `ZFI_PCX_ADMIN` and the entry-status view
added the same day on Arnav's "what the business will need"). TS: `TS_ZFI_PCX.md` / `.docx`.

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

## Objects — built 20/11/26, all in `ZFI_PCX.zip` (Arnav: "create everything, I will use abapGit standalone")

49 files in `src/`, generated DDIC (`build/build_ddic.py`) and program XML (`build/build_prog_xml.py`)
plus three hand-written programs. No DEVC
file: the package is chosen at import. **Nothing here has been activated or run.**

| # | Object | Type | Purpose |
|---|---|---|---|
| 1 | 10 domains `ZFI_PCX_*` | DOMA | amount DEC 15,2 and rate DEC 9,5 (no sign), NUMC 2/3/4, CHAR 10/60, three with fixed values (status O/F, entity type S/J/H, Opex class C/E) |
| 2 | 27 data elements `ZFI_PCX_*` | DTEL | all domain-based (the shape that has pulled here); labels are the SM30 / ALV headings |
| 3 | `ZFI_PCX_ENT` | TABL | entities for the roll-up: number, name, type, sort number |
| 4 | `ZFI_PCX_PROJ` | TABL | project master: number, name, sort number, active, BU, entity, JV code text, Opex class |
| 5 | `ZFI_PCX_FY` | TABL | per year: BE rate, RE rate |
| 6 | `ZFI_PCX_PERIOD` | TABL | per year and fortnight 01–24: cutoff date, status (blank / O / F), TTA rate |
| 7 | `ZFI_PCX_FYPROJ` | TABL | per year and project: Capex BE, RE, opening ITD and prior-year Capex in USD and INR |
| 8 | `ZFI_PCX_CAPEX` | TABL | entered cumulative EWIP / DWIP / CWIP / Other per year, fortnight, project; changed by / on / at |
| 9 | `ZFI_PCX_ENTRY` (624 lines) | PROG | BU entry: editable grid, pre-fill, checks, colours, Save button in the grid toolbar, correction mode |
| 10 | `ZFI_PCX_REPORT` (1000 lines) | PROG | nine views: cumulative by category, cumulative per fortnight, per period USD, per period INR, by entity, by category INR, ITD USD, ITD INR, **entry status of the fortnight** (who has entered, who has not) |
| 11 | `ZFI_PCX_ADMIN` (444 lines) | PROG | Corporate Budgeting: generate the 24 fortnights of a year (15th and month-end, April to March), freeze the open fortnight and open the next in one step (popup says how many projects have no entry), freeze / reopen one fortnight, save the TTA rate of a fortnight; ends with the calendar and projects entered per fortnight. Activity 70 |

Changed against the 20/11 proposal, and why:

- **No lock object, no message class.** Neither shape has ever been pulled on this landscape. Locking
  uses the standard `ENQUEUE_E_TABLE` on `ZFI_PCX_CAPEX` + client/year/fortnight/project; messages are
  literals in the programs.
- **Data elements are domain-based**, so 10 domains instead of 5 (`DATUM`, `UZEIT`, `XFELD` are standard).
  If object 1 was already keyed by hand from the first sheet, the pull overwrites those data elements.
- **Opex is not built** (query 3: Capex first). `OPXCLS` on the project master is ready for it.
- Each program is one source, no includes.

How the entry program behaves (`src/zfi_pcx_entry.prog.abap`):

- Selection: year, fortnight, BU, project, *Display Only*, *Correct a Frozen Fortnight*.
- Status `O` in `ZFI_PCX_PERIOD` = editable; `F` = display, or editable in correction mode with
  activity 70; blank = display with a message.
- Prior reported = latest earlier fortnight that has a row (carried forward). Category cells start
  from the prior figures until the project is saved in this fortnight.
- Refused, with the cells put back: a negative, a total below prior reported, a total above the next
  later fortnight already saved.
- Colours: grey-blue = frozen (prior column, frozen fortnight), yellow = pre-filled, green = entered.
- **Save writes only the rows changed in the session.** Leaving the list with Back does not warn about
  unsaved cells — the price of having no GUI status.

Report (`src/zfi_pcx_report.prog.abap`): everything is "as at" the selected fortnight; a fortnight
without a row carries the last figure forward; INR = USD x rate / 10; as at mid-month the month
column uses the 15-day rate (`" ASSUMPTION` in the code); the total row is calculated by the program
(utilisation from totals), so it moves if the user sorts.

### Unproven on this landscape — expect the first error here

1. **Editable `CL_GUI_ALV_GRID` on `CL_GUI_CONTAINER=>DEFAULT_SCREEN`** with `WRITE space` as carrier.
   `kpmg/zpp_forecast_v2` proves it for a display SALV only. Fallback: screen 0100 + custom container
   + GUI status by hand.
2. **Domains with fixed values** (`DD07V_TAB`): shape taken from `kpmg/zpp_forecast_v2`, never pulled on OCD.
3. **TABL on OCD**: pulled on 28/10 (`ZFI_BR_GLMAP`), "table not created" on 03/11 (`ZFI_TR_BANKACCT`,
   never diagnosed). If a table is missing after the pull: `ddic/01_domains_data_elements.md` is the
   SE11 sheet, and the abapGit log line is what is needed here.
4. Selection texts in the program XML carry `LENGTH` = text + 8, the abapGit convention.

## Import and set-up

1. `ZABAPGIT_STANDALONE` → New Offline Repo → package (new or existing) → Import `ZFI_PCX.zip` → Pull.
   Check first that no `ZFI_PCX*` object exists other than what was keyed by hand.
2. SE54 / SE11 → Table Maintenance Generator for `ZFI_PCX_ENT`, `ZFI_PCX_PROJ`, `ZFI_PCX_FY`,
   `ZFI_PCX_FYPROJ` (one step). Not for `ZFI_PCX_CAPEX`; `ZFI_PCX_PERIOD` is run from `ZFI_PCX_ADMIN`
   and needs none.
3. SU20: field `ZPCX_BU` (data element `ZFI_PCX_BU`). SU21: object `ZFI_PCX` with `ZPCX_BU` and `ACTVT`
   (02 enter, 03 display, 70 correct a frozen fortnight). PFCG roles. **Until this exists nobody passes
   the check, in either program.**
4. SM30 data: `ZFI_PCX_ENT` and `ZFI_PCX_PROJ` from `load/*.txt` (tab-separated, field order of the
   table without client; BU column is empty — query 11); `ZFI_PCX_FY`; `ZFI_PCX_FYPROJ`. Calendar:
   `ZFI_PCX_ADMIN` → *Generate the 24 Fortnights*, then *Freeze Open, Open Next* opens fortnight 01;
   the rate per fortnight with *Save TTA Rate of Fortnight*.
5. SE93: report transactions for the three programs (suggested `ZFI_PCX01` entry, `ZFI_PCX02` report,
   `ZFI_PCX03` fortnight control).

Load sheets (`build/build_ddic.py <workbook>` rebuilds them): 17 entities, 71 projects. Three projects
sit in two entity formulas of the workbook (GNPOC Sudan, Namibia PEL 0037, Block-32 Israel) — kept
under the named entity, not HQ. Eleven rows (Myanmar AD2 … OMEL 285) are in no formula — put under
HQ. Seven projects are flagged equity investee, Sakhalin I among them (query 20).

Re-zip after any change:

    cd ovl/capex_provisional && rm -f ZFI_PCX.zip && zip -X ZFI_PCX.zip .abapgit.xml src/*
