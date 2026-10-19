# ZSTR_HEADER — components (transcribed from SE11, 19/10/26) vs ZC_PURCHASEORDERTP_EXT

Structure *Structure For Header Part of PO*, 83 components; screenshots in `original/ZSTR_HEADER_SE11_p1..p5_2026-10-19.png`.
`In view` = element present in `ZC_PURCHASEORDERTP_EXT`; `UI pos` = its `@UI.identification` position, blank = no UI annotation (in the service, not on the screen).

| # | Component | Data element | Type | Description | In view | UI pos |
|---|---|---|---|---|---|---|
| 1 | `EBELN` | `EBELN` | CHAR 10 | Purchasing Document Number | std |  |
| 2 | `MATKL` | `MATKL` | CHAR 9 | Material Group | std |  |
| 3 | `PLIFZ` | `PLIFZ` | DEC 3 | Planned Delivery Time in Days | std |  |
| 4 | `WEBAZ` | `WEBAZ` | DEC 3 | Goods receipt processing time in days | std |  |
| 5 | `ZZT_NATURE` | `ZT_NATURE` | CHAR 3 | Nature of tender | yes |  |
| 6 | `ZZTND_DT` | `ZTND_DT` | DATS 8 | Collective (Tender) Date | yes |  |
| 7 | `ZZLST_SEL_DATE` | `ZLST_SEL_DATE` | DATS 8 | Last date of selling tender | yes |  |
| 8 | `ZZSUB_TIME` | `ZSUB_TIME` | TIMS 6 | Time of Submission of Tender | yes |  |
| 9 | `ZZTB_OP_DT` | `ZTB_OP_DT` | DATS 8 | Date of opening of bid / Tech-comm. Bid | yes |  |
| 10 | `ZZTB_OP_TM` | `ZTB_OP_TM` | TIMS 6 | Time of opening of bid / Tech-comm. Bid | yes |  |
| 11 | `ZZPB_OP_DT` | `ZPB_OP_DT` | DATS 8 | Date of Price Bid Opening | yes |  |
| 12 | `ZZPB_OP_TM` | `ZPB_OP_TM` | TIMS 6 | Time of Price Bid Opening | yes |  |
| 13 | `ZZPRE_BID_DT` | `ZPRE_BID_DT` | DATS 8 | Date of Pre-Bid Conference | yes |  |
| 14 | `ZZBD_TYPE` | `ZBD_TYPE` | CHAR 3 | Bidding System | yes |  |
| 15 | `ZZT_DURATION` | `ZT_DURATION` | CHAR 3 | Tender Duration type | yes |  |
| 16 | `ZZLST_DT_QUE` | `ZLST_DT_QUE` | DATS 8 | Last Date for receiving queries for Pre-bid conference | yes |  |
| 17 | `ZZINSP_TYP` | `ZINSP_TYP` | CHAR 3 | Inspection Type | yes | 120 |
| 18 | `ZZVEND_CAT` | `ZVEND_CAT` | CHAR 3 | Vendor Category | yes | 130 |
| 19 | `ZZINSP_AUTH` | `ZINSP_AUTH` | CHAR 3 | Inspection Authority | yes | 140 |
| 20 | `ZZPRE_AWD` | `ZPRE_AWD` | NUMC 3 | Pre award communication | yes |  |
| 21 | `ZZPST_AWD` | `ZPST_AWD` | NUMC 3 | Post award communication | yes |  |
| 22 | `ZZARBIT` | `ZARBIT` | CHAR 2 | Arbitration cases | yes |  |
| 23 | `ZZAR_OP_DT` | `ZAR_OP_DT` | DATS 8 | Date of Arbitration open | yes |  |
| 24 | `ZZAR_CL_DT` | `ZAR_CL_DT` | DATS 8 | Date of Arbitration closed | yes |  |
| 25 | `ZZTPI_ADD` | `ZTPI_ADD` | CHAR 10 | Third Party Inspection address | yes | 150 |
| 26 | `ZZQAD_DET` | `ZQAD_DET` | CHAR 10 | QAD Department | yes | 160 |
| 27 | `ZZPORT_CON` | `ZPORT_CON` | CHAR 10 | Port Consignee | yes | 170 |
| 28 | `ZZULT_CON` | `ZULT_CON` | CHAR 10 | Ultimate consignee | yes | 170 |
| 29 | `ZUPFLAG` | `ZUPFLAG` | CHAR 1 | Flag for Ultimate & Port Cong. | yes |  |
| 30 | `ZZNAT_PROC` | `ZNATPROC` | CHAR 2 | Tender Process | yes | 180 |
| 31 | `ZZNITDT` | `ZNITDT` | DATS 8 | Date of Publication of NIT in Website | yes | 190 |
| 32 | `ZZBIDER_AGR` | `ZBIDERAGR` | CHAR 1 | Contract / PO awarded to Lowest bidder | yes |  |
| 33 | `ZZSCH_ST_DT` | `ZSCHSTDT` | DATS 8 | Scheduled Work Start Date | yes | 200 |
| 34 | `ZZSCH_EN_DT` | `ZSCHENDT` | DATS 8 | Schedule Work End Date | yes | 210 |
| 35 | `ZZSUBMI` | `SUBMI` | CHAR 10 | Collective Number | yes |  |
| 36 | `ZZEPC` | `ZZEPC` | CHAR 1 | EPC approval OLD Value | yes |  |
| 37 | `ZZEXCHNG_RATE` | `ZWKURS` | DEC 9,5 | SRM-Exchange rate | yes |  |
| 38 | `ZZPSA` | `ZPSA` | CHAR 12 | PO Signing Authority | yes |  |
| 39 | `ZZCPO` | `ZZCPO` | NUMC 8 | Contact Person for current PO | yes |  |
| 40 | `ZZPHONE` | `ZZPNO` | CHAR 11 | Landline Number | yes |  |
| 41 | `ZZFAX` | `ZZFAX` | CHAR 25 | Fax Number | yes |  |
| 42 | `ZZMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | yes |  |
| 43 | `ZZEMAIL` | `ZZEMA` | CHAR 40 | Email ID | yes |  |
| 44 | `ZZINDPER` | `ZZIND` | NUMC 8 | Indenting person for current PO | yes |  |
| 45 | `ZZINDPHONE` | `ZZPNO` | CHAR 11 | Landline Number | yes |  |
| 46 | `ZZINDFAX` | `ZZFAX` | CHAR 25 | Fax Number | yes |  |
| 47 | `ZZINDMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | yes |  |
| 48 | `ZZINDEMAIL` | `ZZEMA` | CHAR 40 | Email ID | yes |  |
| 49 | `ZZRELDATE` | `ZZRELDATE` | DATS 8 | Release Date | yes |  |
| 50 | `ZZRELCODE` | `ZFRGCO` | CHAR 2 | Final Release Code | yes |  |
| 51 | `ZZLOINO` | `ZZLOINO` | CHAR 20 | LOI/NOA number | yes |  |
| 52 | `ZZLOIDT` | `ZZLOIDT` | DATS 8 | LOI/NOA Date | yes |  |
| 53 | `ZZFAXDT` | `ZZFAXDT` | DATS 8 | Fax Order Date | yes |  |
| 54 | `ZZMSE` | `ZZMSE` | CHAR 2 | For MSE | yes |  |
| 55 | `ZZDMEP` | `ZZDMEP` | CHAR 3 | Domestically Manufactured Electronic Products (DMEP) | yes | 220 |
| 56 | `ZSUPCONCT` | `ZZSUPCONCT` | CHAR 15 | Supplier Contact No | yes |  |
| 57 | `ZSUPEMAIL` | `ZZSUPEMAIL` | CHAR 50 | Supplier Email | yes |  |
| 58 | `ZFILENO` | `ZZFILENO` | CHAR 50 | File Number | yes |  |
| 59 | `ZULTNAME` | `AD_NAME1` | CHAR 40 | Name 1 | yes |  |
| 60 | `ZULTSTREET` | `AD_STREET` | CHAR 60 | Street | yes |  |
| 61 | `ZULTSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | yes |  |
| 62 | `ZULTCITY` | `AD_CITY1` | CHAR 40 | City | yes |  |
| 63 | `ZULTCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | yes |  |
| 64 | `ZULTEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | yes |  |
| 65 | `ZINVNAME` | `AD_NAME1` | CHAR 40 | Name 1 | yes |  |
| 66 | `ZINVSTREET` | `AD_STREET` | CHAR 60 | Street | yes |  |
| 67 | `ZINVSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | yes |  |
| 68 | `ZINVCITY` | `AD_CITY1` | CHAR 40 | City | yes |  |
| 69 | `ZINVCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | yes |  |
| 70 | `ZINVEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | yes |  |
| 71 | `ZINSNAME` | `AD_NAME1` | CHAR 40 | Name 1 | yes |  |
| 72 | `ZINSSTREET` | `AD_STREET` | CHAR 60 | Street | yes |  |
| 73 | `ZINSSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | yes |  |
| 74 | `ZINSCITY` | `AD_CITY1` | CHAR 40 | City | yes |  |
| 75 | `ZINSCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | yes |  |
| 76 | `ZINSEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | yes |  |
| 77 | `ZPAYNAME` | `AD_NAME1` | CHAR 40 | Name 1 | yes |  |
| 78 | `ZPAYSTREET` | `AD_STREET` | CHAR 60 | Street | yes |  |
| 79 | `ZPAYSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | yes |  |
| 80 | `ZPAYCITY` | `AD_CITY1` | CHAR 40 | City | yes |  |
| 81 | `ZPAYCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | yes |  |
| 82 | `ZPAYEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | yes |  |
| 83 | `ZGEMPO` | `ZGEMPONO` | CHAR 30 | GEM PO NO | yes |  |

## In the view but not in ZSTR_HEADER

These five come from the EKKO append directly (the structure is not the append; it carries four standard fields the append does not):

- `ZZUSR`
- `ZZFLAG_KOL`
- `ZZFLAG_MUM`
- `ZZFLAG_CHEN`
- `ZZFLAG_DEL`

Counts: structure 83 = 4 standard + 79 custom; view 84 = 79 + 5. Every custom component of the structure is in the view.
Annotated with `@UI.identification`: 12 of 84. Position 170 is used twice (`ZZPORT_CON`, `ZZULT_CON`).
