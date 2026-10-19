# ISSUES — ovl/zmm_purchdoc_cds_ext (PO / PR / contract CDS extensions for custom fields)

| # | Date | Issue | Cause | Fix | TR | Status |
|---|---|---|---|---|---|---|
| 0 | 19/10/26 | Work existed only in SAP; no repo record of the 26 DDLS extensions or their TR | Earlier session never synced to git | Object list filed from the SE09 screenshot (`NOTES.md`, `original/`). Sources, field list and consuming app still to be supplied | `OCQK901357` | **Open — awaiting the 26 sources** |
| 1 | 19/10/26 | Not all PO header custom fields show in the Fiori app although the CDS chain carries them | `ZC_PURCHASEORDERTP_EXT`: 84 elements, only 12 annotated `@UI.identification` (120–220); 72 are in `$metadata` but on no section; position 170 duplicated; 24 address fields carry generic `AD_*` labels | Proposed: annotate all 84 in the extension (positions from 230, 170→175, explicit labels on `ZULT*/ZINV*/ZINS*/ZPAY*`); `@UI.lineItem` if list columns wanted. Awaiting go / layout decision | `OCQK901357` | **Open — assessment delivered** |
