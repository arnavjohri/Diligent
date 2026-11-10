# ISSUES - ovl/per_barrel_agenda

| Date | Issue | Cause / finding | Fix | TR |
|---|---|---|---|---|
| 10/11/26 | Arnav: can the AgendaFormat sheet of the Per Barrel Analysis be rebuilt as a CDS cube for CAQ from the DPR data, for every block? | Only the production block is DPR data (FY'25 column matches the DPR export on 25 of 26 lines, BC-10 crude off by 0.001). Sales quantity, revenue and price are ZFI_PL data. Exchange rate, Dated Brent, adjustments, Sakhalin-1 revenue and VAP are typed in the workbook. | None - assessment only: `docs/AgendaFormat_to_CDS_mapping.md`. Seven checks listed there before any build. | - |
| 10/11/26 | Arnav: can the `PBA` sheet be given instead? | Yes. All eight sections are ZFI_PL lines divided by ZFI_PL quantities, all USD. Finance's hidden Check Sheet: 95 of 118 per-barrel cells equal ZFI_PL to 2 decimals, 17 within 0.08, 6 explained (Carabobo basis, typed ACG DD&A, CPO-5 survey row). History before FY'26 is typed and not in SAP. | None - assessment only: `docs/PBA_sheet_to_CDS_mapping.md`. Six checks listed there, first of all SE11 / SE16 on `ZFI_AGENDA`. | - |
