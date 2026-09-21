# WRICEF 147 — Overall CC MIS, summary-wise and customer-wise (Astral / project UDAY, SD)

FS supplied 21/09/26: `fs/147_Overall_CC_MIS_Summary_and_Customer_wise.docx` (V.01, dated
14.08.2026, prepared by Satyendra Singh / Rajesh Vagashiya). Logic sheets supplied with it:
`fs/147_Output_MIS_sheet.xlsx` (selection screen, 80-column output map with source per
column) and `fs/147_Z_Table_format.xlsx` (proposed Z table, month-wise, with sample rows).

## Scope as written

Two objects:

1. Report **`ZSD_MIS_CUSTOMER`** — ALV, one row per customer, 80 columns (customer master
   and sales-officer hierarchy L1–L6, sales / returns / collections for current FY, last FY,
   selected month and selected quarter, outstanding and overdue, credit limit, exception
   approval, legal status, security deposits). Values in lakh. Paint and Adhesive divisions.
2. Custom table **`ZSD_CUST_SDFI_DATA`** — filled by the user via SM30 (FS: "no uploader
   program will be provided") with everything the FS calls "not available in SAP": the
   whole of last FY month by month, plus static attributes (security cheques, legal status,
   dispute amount, demand notice, DCA, exception approval, critical OD count).

Plus two STVARV variables: `ZSD_PAINT_CUSTGRP2` (dealer 38,39,40,43,44,45,46 /
distributor 47,53) and `ZSD_PAINT_OLDCUSTGRP2` (old 38 / new 39,40,43,44,45,46,47).

## Status

**Assessment only — not started.** The FS cannot be built end to end from what was
supplied; see `FS_QUERIES.md` for the verdict, the per-column source classification and the
numbered query list to send back. The hard blocker is that roughly a third of the columns
are specified as "fetch from Z report X" for seven existing Z reports whose source has not
been supplied, and "fetch from a report" is not an implementation.

## Delivery

Report is ZIP-able if it stays screen-free (`REUSE_ALV_GRID_DISPLAY_LVC` full screen, no
custom container). Table + data elements by ZIP; the SM30 maintenance generator (TMG) and
the STVARV entries are manual. Folder has no `src/` yet.

## Related

`kpmg/zsd_exc_approval/` (WRICEF 141 A/B, same client). Its ISSUES.md #1 (L4/L5/L6 name
source unknown) is the same open point as this FS's L1–L6 columns. Note that 141's objects
(`ZSD_EXC_APPR_*`) do **not** compute Default Invoice %, CEI % or clearing days — the
`ZFI_EXCP_APPROVAL` this FS cites is a different, pre-existing report.
