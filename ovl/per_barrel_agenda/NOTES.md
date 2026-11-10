# Per Barrel Analysis - Board Agenda format (OVL)

**Project:** OVL (ONGC Videsh) · finance MIS, corporate accounts
**Status:** PBA sheet chosen (10/11/26). Object 1 `ZI_PBA_LINE` delivered 10/11/26, **not yet
activated**. Objects 2 and 3 not written. AgendaFormat sheet: assessed only.

## What it is
The annual "Per Barrel Analysis" workbook, sheet `AgendaFormat`: five blocks per project
for the board agenda - average realization, sales revenue (INR mn), revenue variance
(quantity / price / exchange), quantities sold, quantities produced - current year against
the previous year. The ask (Arnav, 10/11/26): rebuild it as a CDS cube shown in Custom
Analytical Queries, the way `ovl/zfi_bank_reval/` and `ovl/zfi_tr_bankacct/` were done.

## Where the answer is
- `docs/AgendaFormat_to_CDS_mapping.md` - block-by-block source mapping, the proof for the
  production block, the inputs that are not in SAP, and the seven checks to run first.
- `docs/PBA_sheet_to_CDS_mapping.md` - the same for the `PBA` sheet (10/11/26 follow-up).
  **PBA is the better candidate:** one source (ZFI_PL), all USD, none of the typed inputs.
  The workbook's hidden `Check Sheet` already ties it to ZFI_PL (95 of 118 cells equal).

## The one thing to remember
It is **not** a DPR report. Only the production block comes from the DPR tables
(`ovl/zpra_dpr/`). Sales quantity, revenue and price come from the ZFI_PL tables
(`ovl/zfi_pl/`), and exchange rate, Dated Brent, adjustments, Sakhalin-1 revenue and VAP
are typed into the workbook.

## Shipping method
**ADT paste, one DDL source at a time** - loose `.ddls.asddls` files at the folder root, no
`src/`, no `.abapgit.xml`. Suggested package `ZFI_OTH` (where ZFI_PL and the JIB views
live); Arnav decides. The cube's key-user release (ADT, API State, C1) is manual.

## The table behind it
`ZFI_AGENDA` keeps the **last ZFI_PL run per project only** - fiscal year and period are not
in its key (SE11, 10/11/26). The report shows that run and has no history. Details and the
tie-out in `docs/PBA_sheet_to_CDS_mapping.md` section 6.

## original/
`Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx` - as supplied 10/11/26. The 18 workbooks it
links to (15 ZFI_PL extracts, S-1 LLC, standalone and consolidated accounts) were not
supplied.
`ZFI_AGENDA_SE11_2026-11-10.png`, `ZFI_AGENDA_SE16_count_2026-11-10.png` - table definition
and row count (1,547) as supplied 10/11/26.
`ZFI_AGENDA_SE16_full_2026-11-10.tsv` - the whole table, 1,547 rows, as pasted 10/11/26.
`ZPRA_T_MREC_PRD_GJAHR2025_SE16_2026-11-10.tsv` - reconciled production, fiscal year 2025,
2,335 rows, as pasted 10/11/26. Both taken from the session record, tab-separated, no header.
