# Mail draft — to the UI developer building the JIB Status tile (04/11/26)

Subject: JIB Status tile – data source ZI_JIB_STATUS_CUBE and how to query it

Hi <name>,

The data source for the JIB Status tile is the CDS cube ZI_JIB_STATUS_CUBE (OCD 500, package
ZFI_OTH), released for Custom Analytical Queries. It holds one row per venture per time window,
where the window is the fiscal year, quarter or month in which the JIB was entered in SAP.

Every query must filter **Granularity** first, then the window:

| User picks | Filter on the cube | Result |
|---|---|---|
| Year | Granularity = Y, FiscalYear | one row per venture, last JIB of that fiscal year |
| Quarter | Granularity = Q, FiscalYear, FiscalQuarter (Q1–Q4) | one row per venture, last JIB of that quarter |
| Month | Granularity = M, FiscalYear, FiscalPeriod (01 = Apr … 12 = Mar) | one row per venture, last JIB of that month |

Without the Granularity filter every venture comes back three times. Fiscal year is April to
March, so period 01 is April and Q1 is April to June.

Columns for the tile: JointVenture (JV Code), ProjectName, BusinessUnit, JibStatus (Uploaded /
Pending), LastEntryDate (Date — the day the JIB was entered; blank on Pending). Business Unit is
also a filter. The measures JibPosted / JibPending / Ventures give the counts for a header KPI
(e.g. 3 of 4 uploaded) when summed under one granularity.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
