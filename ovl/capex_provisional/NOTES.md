# Provisional Capex / Opex fortnightly punching (OVL)

**Project:** OVL (ONGC Videsh) · Corporate Budgeting / finance MIS
**Status:** FS received 18/11/26 (`original/SAP_Automation_Provisional_Capex_Process_V3.xlsx`).
Assessed only - nothing built. Object names not yet decided.

## What the workbook asks for

Sheets `Capex USD` / `Capex INR` (Tabs 1-8), `Opex USD` / `Opex INR`, `OVL JV Code List`,
and two `Process` sheets that are a reviewer's write-up of the same workbook.

The five numbered requirements at the top of `Capex USD` are the actual SAP ask:

1. BU punches the **category-wise cumulative Capex** (EWIP, DWIP, CWIP, Other) per project at
   each fortnight end (15th and month-end), USD million. 71 project rows, 24 fortnights a year.
2. If cumulative Capex is **less than the prior fortnight**, show an error.
3. BU **cannot decrease** cumulative Capex; minimum is the prior reported amount.
4. SAP **pre-fills the prior reported cumulative** until something is punched in the current period.
5. **Three colour states**: frozen (not changeable by BU), pre-filled, punched this fortnight.

Everything else in the workbook is derived from that one input table:

| Tab | Content | Needs besides the punched data |
|---|---|---|
| 2 | Cumulative per fortnight, all 24 periods side by side | nothing (history) |
| 3 | Marginal USD per fortnight = cum(t) - cum(t-1); month, quarter, YTD; BE/RE balance and utilisation % | BE/RE per project per FY |
| 4 | Same in INR crore: USD mn x TTA rate / 10, 15-day rate for the mid-month column, monthly rate for the month column, rounded 2 dp | rate per period |
| 5 | Roll-up of projects into subsidiaries / incorporated JVs | project -> entity mapping |
| 6 | Cumulative category-wise in INR via one weighted factor (total INR YTD / total USD YTD) | derived |
| 7, 8 | Inception-to-date roll-forward, INR and USD: opening ITD + prior-year Capex + current YTD | opening ITD and prior-year Capex per project |
| Opex | Same frame but **incremental** (not cumulative) amounts, two components (Opex, Survey), negatives not allowed | BE/RE per component |

In the Excel the history table (Tab 2) is empty and unlinked, a decrease is silently clamped
to zero in Tab 3 (`IF(E86-D86>0, E86-D86, 0)`), and the rates row is blank - the Process
sheets list these as findings C1-C3. Those gaps are exactly what the SAP build closes.

## Verdict: not a report. A punching transaction plus reports on top.

A report reads and displays. Requirements 1-5 are persistence, pre-fill from the prior
period, a validation against stored data, a period freeze, and per-cell state. None of that
exists without custom tables. The right shape is three layers, and the first one is the one
that matters:

**Layer 1 - Z tables (DDIC).** Sketch, names to be fixed with the FS owner:

| Table | Key | Content |
|---|---|---|
| Project master | project id | name, JV code(s), entity for Tab 5, active flag, BU/owner. **JV code is not usable as the key**: many rows carry `0`, row 70 carries six codes, Opex `Sl. No.` repeats (finding O8) |
| Period calendar | FY, period no. (1-24) | cutoff date, month, quarter, freeze flag / freeze date, 15-day vs month-end indicator |
| Punched amounts | project id, FY, period no., measure (EWIP/DWIP/CWIP/OTHER; later OPEX/SURVEY) | amount, state (punched / pre-filled / frozen), changed by / on |
| Budgets | project id, FY, measure | BE, RE (Corporate Budgeting, SM30) |
| Rates | FY, period no. | 15-day TTA rate, monthly TTA rate - **or** a custom rate type in TCURR via OB08 (preferred: standard, audited). Decision for functional |
| Opening balances | project id, FY | ITD at FY start, prior-year Capex, in USD mn and INR crore (Tabs 7/8) |

Volume is trivial: 71 x 24 x 4 is under 7,000 rows a year. No performance design needed.

**Layer 2 - the punching program.** An SE38 executable with an **editable `CL_GUI_ALV_GRID`**:
selection screen = FY, fortnight, BU/project range; one row per project, four editable
amount columns; prior-period value pre-filled; cell colours from `LVC_T_SCOL` and
editability from `LVC_T_STYL` per cell give the three states of requirement 5 directly;
`DATA_CHANGED` handler for the non-decrease and non-negative checks; Save writes the table
under an `ENQUEUE` lock on project + period. This is the only sense in which "report" is
right: the vehicle is a report program, the behaviour is a transaction.

Why this over the alternatives:

- **Module pool + table control**: SE51 screens and SE41 status, all manual, for a flat grid
  the ALV already renders. No gain.
- **SM30 on the amounts table**: no pre-fill, no cross-period validation, no colour states,
  no freeze without SE54 events. Fine for the five master tables, wrong for BU entry.
- **RAP / Fiori elements**: the modern answer, but OCQ is an older release (`MEMORY.md` §4),
  a 71 x 4 grid entry is clumsy in Fiori elements inline edit, and build plus BAS deployment
  is several times the effort. Keep as a phase-2 option if BUs must enter from a browser.
- **Excel upload program**: loses the pre-fill and colour interaction; could be added later
  as a second input path on the same tables.

**Layer 3 - the output reports.** One ALV report with a view selector (cumulative USD /
marginal USD / INR / entity roll-up / ITD), or one report per tab, all reading Layer 1.
Marginal = cum(t) - cum(t-1) by period sequence; INR via the rates table and the fixed /10
(USD million -> INR crore); ITD = opening + YTD. ALV Excel export covers the "download" need.
A CDS cube + Custom Analytical Query (the pattern used for `zfi_bank_reval`,
`zfi_tr_bankacct`, `zfi_jib_status`, `per_barrel_agenda`) is a possible phase 2 once the
tables exist; the period self-join and roll-forward are doable but hit §4 constraints.

## Open questions for the FS owner before building

1. **Non-decrease check: per category or on the total?** The Excel checks the total only
   (`K17 = IF(J17<E17,"error",J17-E17)`). Requirement 3 reads as "prior reported amount".
2. **Decrease handling**: hard error that blocks Save (what requirements 2/3 say), or save
   with a warning flag? The Excel silently clamps to zero - Process sheet C3 flags that as wrong.
3. **Freeze rule**: who freezes a fortnight and when - automatically at the next cutoff, or
   by Corporate Budgeting action? Who may correct a frozen period, and is a change log needed
   (SCDO is manual)?
4. **Authorisation**: how is a BU limited to its own projects? Custom auth object with a
   project / JV field (SU21, manual), or an existing org field?
5. **Project key**: confirm a project master with one unique id per row; JV code as attribute.
   Which of the 71 rows are still active for FY 2027-28?
6. **Rates**: source of the 15-day and monthly TTA rates - OB08 rate types or a Z table?
   Confirm the /10 convention (the Opex INR sheet omits it, finding O2).
7. **Units and decimals**: USD million stored as entered? How many decimals (sample is
   integers, INR is 2 dp)?
8. **Calendar**: FY April-March, 24 cutoffs; the sheet mixes FY 2026-27 and 2027-28 labels
   and lists 28 Feb 2028 in a leap year (findings C6, C8). Confirm the cutoff list.
9. **Opex in scope now or later?** Same tables fit (incremental, two components, no negatives);
   recommend designing the tables for both and building Capex first.
10. **Tab 5 mapping, Tab 7/8 opening balances, BE/RE**: all Corporate Budgeting inputs -
    confirm they come as SM30-maintained tables and who owns them.

## Shipping

The punching program needs `CALL SCREEN` / a container, so it is **paste-only** from the
start. DDIC (domains, data elements, tables, lock object) can be attempted by abapGit ZIP
but hand-written XML has not yet imported on this landscape - plan on SE11 by hand or
ADT paste. SM30 generation (SE54), SU21 object and SE93 codes are manual in any case.
