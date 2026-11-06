# Mail draft 06/11/26 — object names to the Group Reporting team (drafted, sending manual)

Subject: Group Reporting – FS item remap: custom table and CDS view (OCD 500)

Hi <name>,

The FS item remap objects are available in OCD, client 500:

- Custom table ZGR_FSITEM_MAP – maintained in SM30: consolidation unit, FS item as posted, new FS item to report instead. A row with a blank new FS item is treated as no mapping.
- CDS view ZI_GR_FSREMAP_CUBE (SQL view ZIGRFSREMAPCUBE) – copy of the standard Group Data Analysis cube I_MatrixConsolidationReportC with the additional column NewFinancialStatementItem: the mapped item where a table row exists, otherwise the original FS item. All standard fields and the four parameters are unchanged; enter $ in the three hierarchy parameters when no hierarchy is used.
- Report ZGR_FSREMAP_READ (SE38) – reads the cube with ledger, dimension, version, year and period as mandatory filters and shows the amounts per unit, FS item and new FS item.

Please maintain a few mapping rows in ZGR_FSITEM_MAP and confirm the output in ZGR_FSREMAP_READ for one unit and period. Any query built on the cube must have ledger, dimension, version, year and period as mandatory filters; an unfiltered read exceeds the HANA statement memory limit.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
