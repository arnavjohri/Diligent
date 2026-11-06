# Mail draft — to the UI developer, after the client's test feedback (06/11/26)

Subject: JIB Status tile – revised data source ZI_JIB_STATUS_CUBE (no Granularity any more)

Hi <name>,

Corporate Accounts tested the tile and the expected layout is one row per JIB month, not per
month of upload. The cube ZI_JIB_STATUS_CUBE is rebuilt accordingly; the Granularity field is
gone and nothing is mandatory. Please rebuild the query as follows:

Rows: JointVenture (JV Code), BusinessUnit, ProjectName, PeriodMonth (Month), JibStatus
(Status), EntryDate (Date of JIB Upload), AccountingDocument (Document Number). Sort on
FiscalPeriod. A month with several documents comes as several rows; the analytical table merges
the repeated cells, which is the layout in their example. A Pending month has one row with no
date and no document.

Filters: FiscalYear (gives all twelve months, April–March, Pending for the ones not posted),
optionally FiscalQuarter, FiscalPeriod, BusinessUnit, JointVenture, or a range on
PeriodStartDate.

For a one-line-per-venture year view (the tile's summary), build a second query or a view
switch with rows JointVenture, ProjectName, BusinessUnit, YearStatus, YearLastEntryDate,
YearMonthsUploaded and no Month / Document Number; the quarter view uses the Quarter* columns
with a FiscalQuarter filter.

Document Number should open the document header dialog: navigate with CompanyCode,
AccountingDocument and FiscalYear from the row to the journal entry display app.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
