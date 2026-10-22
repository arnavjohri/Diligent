# F4 field inventory — ZC_PURCHASEORDERTP_EXT (PO header custom fields)

Built 22/10/26 from `ZSTR_HEADER_vs_view.md` (data elements transcribed from SE11 on 19/10/26) and the
extension's select list. Fill **Domain** and **Fixed values** from SE11 (data element → Definition tab →
Domain; domain → Value Range tab). Only the rows marked YES / maybe need looking up; the others
cannot carry a fixed-value or table F4 by their type. `zzinsp_typ` is done (domain `ZINSP_TYP`).

| # | CDS element | ZSTR_HEADER component | Data element | Type | Description | F4 candidate | Domain | Fixed values / table |
|---|---|---|---|---|---|---|---|---|
| 1 | `zzt_nature` | `ZZT_NATURE` | `ZT_NATURE` | CHAR 3 | Nature of tender | YES — code field, check domain |  |  |
| 2 | `zztnd_dt` | `ZZTND_DT` | `ZTND_DT` | DATS 8 | Collective (Tender) Date | no — date/time |  |  |
| 3 | `zzlst_sel_date` | `ZZLST_SEL_DATE` | `ZLST_SEL_DATE` | DATS 8 | Last date of selling tender | no — date/time |  |  |
| 4 | `zzsub_time` | `ZZSUB_TIME` | `ZSUB_TIME` | TIMS 6 | Time of Submission of Tender | no — date/time |  |  |
| 5 | `zztb_op_dt` | `ZZTB_OP_DT` | `ZTB_OP_DT` | DATS 8 | Date of opening of bid / Tech-comm. Bid | no — date/time |  |  |
| 6 | `zztb_op_tm` | `ZZTB_OP_TM` | `ZTB_OP_TM` | TIMS 6 | Time of opening of bid / Tech-comm. Bid | no — date/time |  |  |
| 7 | `zzpb_op_dt` | `ZZPB_OP_DT` | `ZPB_OP_DT` | DATS 8 | Date of Price Bid Opening | no — date/time |  |  |
| 8 | `zzpb_op_tm` | `ZZPB_OP_TM` | `ZPB_OP_TM` | TIMS 6 | Time of Price Bid Opening | no — date/time |  |  |
| 9 | `zzpre_bid_dt` | `ZZPRE_BID_DT` | `ZPRE_BID_DT` | DATS 8 | Date of Pre-Bid Conference | no — date/time |  |  |
| 10 | `zzbd_type` | `ZZBD_TYPE` | `ZBD_TYPE` | CHAR 3 | Bidding System | YES — code field, check domain |  |  |
| 11 | `zzt_duration` | `ZZT_DURATION` | `ZT_DURATION` | CHAR 3 | Tender Duration type | YES — code field, check domain |  |  |
| 12 | `zzlst_dt_que` | `ZZLST_DT_QUE` | `ZLST_DT_QUE` | DATS 8 | Last Date for receiving queries for Pre-bid conference | no — date/time |  |  |
| 13 | `zzinsp_typ` | `ZZINSP_TYP` | `ZINSP_TYP` | CHAR 3 | Inspection Type | done | `ZINSP_TYP` | 1 Source / 2 Destination Inspection |
| 14 | `zzvend_cat` | `ZZVEND_CAT` | `ZVEND_CAT` | CHAR 3 | Vendor Category | YES — code field, check domain |  |  |
| 15 | `zzinsp_auth` | `ZZINSP_AUTH` | `ZINSP_AUTH` | CHAR 3 | Inspection Authority | YES — code field, check domain |  |  |
| 16 | `zzpre_awd` | `ZZPRE_AWD` | `ZPRE_AWD` | NUMC 3 | Pre award communication | YES — code field, check domain |  |  |
| 17 | `zzpst_awd` | `ZZPST_AWD` | `ZPST_AWD` | NUMC 3 | Post award communication | YES — code field, check domain |  |  |
| 18 | `zzarbit` | `ZZARBIT` | `ZARBIT` | CHAR 2 | Arbitration cases | YES — code field, check domain |  |  |
| 19 | `zzar_op_dt` | `ZZAR_OP_DT` | `ZAR_OP_DT` | DATS 8 | Date of Arbitration open | no — date/time |  |  |
| 20 | `zzar_cl_dt` | `ZZAR_CL_DT` | `ZAR_CL_DT` | DATS 8 | Date of Arbitration closed | no — date/time |  |  |
| 21 | `zztpi_add` | `ZZTPI_ADD` | `ZTPI_ADD` | CHAR 10 | Third Party Inspection address | YES — code field, check domain |  |  |
| 22 | `zzqad_det` | `ZZQAD_DET` | `ZQAD_DET` | CHAR 10 | QAD Department | YES — code field, check domain |  |  |
| 23 | `zzport_con` | `ZZPORT_CON` | `ZPORT_CON` | CHAR 10 | Port Consignee | YES — code field, check domain |  |  |
| 24 | `zzult_con` | `ZZULT_CON` | `ZULT_CON` | CHAR 10 | Ultimate consignee | YES — code field, check domain |  |  |
| 25 | `zupflag` | `ZUPFLAG` | `ZUPFLAG` | CHAR 1 | Flag for Ultimate & Port Cong. | YES — code field, check domain |  |  |
| 26 | `zznat_proc` | `ZZNAT_PROC` | `ZNATPROC` | CHAR 2 | Tender Process | YES — Z table |  | table `ZNAT_PROC`, `STATUS = 'active'` (GUI `pop_up`) |
| 27 | `zznitdt` | `ZZNITDT` | `ZNITDT` | DATS 8 | Date of Publication of NIT in Website | no — date/time |  |  |
| 28 | `zzbider_agr` | `ZZBIDER_AGR` | `ZBIDERAGR` | CHAR 1 | Contract / PO awarded to Lowest bidder | YES — code field, check domain |  |  |
| 29 | `zzsch_st_dt` | `ZZSCH_ST_DT` | `ZSCHSTDT` | DATS 8 | Scheduled Work Start Date | no — date/time |  |  |
| 30 | `zzsch_en_dt` | `ZZSCH_EN_DT` | `ZSCHENDT` | DATS 8 | Schedule Work End Date | no — date/time |  |  |
| 31 | `zzsubmi` | `ZZSUBMI` | `SUBMI` | CHAR 10 | Collective Number | no — free text / number |  |  |
| 32 | `zzepc` | `ZZEPC` | `ZZEPC` | CHAR 1 | EPC approval OLD Value | YES — code field, check domain |  |  |
| 33 | `zzexchng_rate` | `ZZEXCHNG_RATE` | `ZWKURS` | DEC 9,5 | SRM-Exchange rate | no — amount/rate |  |  |
| 34 | `zzusr` | — (append only) | **?** |  | User (EKKO append, not in ZSTR_HEADER) | YES — flag/user, data element unknown |  |  |
| 35 | `zzpsa` | `ZZPSA` | `ZPSA` | CHAR 12 | PO Signing Authority | YES — code field, check domain |  |  |
| 36 | `zzcpo` | `ZZCPO` | `ZZCPO` | NUMC 8 | Contact Person for current PO | maybe — person number, probably a table |  |  |
| 37 | `zzphone` | `ZZPHONE` | `ZZPNO` | CHAR 11 | Landline Number | no — free text / number |  |  |
| 38 | `zzfax` | `ZZFAX` | `ZZFAX` | CHAR 25 | Fax Number | no — free text / number |  |  |
| 39 | `zzmobile` | `ZZMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | no — free text / number |  |  |
| 40 | `zzemail` | `ZZEMAIL` | `ZZEMA` | CHAR 40 | Email ID | no — free text / number |  |  |
| 41 | `zzindper` | `ZZINDPER` | `ZZIND` | NUMC 8 | Indenting person for current PO | maybe — person number, probably a table |  |  |
| 42 | `zzindphone` | `ZZINDPHONE` | `ZZPNO` | CHAR 11 | Landline Number | no — free text / number |  |  |
| 43 | `zzindfax` | `ZZINDFAX` | `ZZFAX` | CHAR 25 | Fax Number | no — free text / number |  |  |
| 44 | `zzindmobile` | `ZZINDMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | no — free text / number |  |  |
| 45 | `zzindemail` | `ZZINDEMAIL` | `ZZEMA` | CHAR 40 | Email ID | no — free text / number |  |  |
| 46 | `zzreldate` | `ZZRELDATE` | `ZZRELDATE` | DATS 8 | Release Date | no — date/time |  |  |
| 47 | `zzrelcode` | `ZZRELCODE` | `ZFRGCO` | CHAR 2 | Final Release Code | YES — code field, check domain |  |  |
| 48 | `zzloino` | `ZZLOINO` | `ZZLOINO` | CHAR 20 | LOI/NOA number | no — free text / number |  |  |
| 49 | `zzloidt` | `ZZLOIDT` | `ZZLOIDT` | DATS 8 | LOI/NOA Date | no — date/time |  |  |
| 50 | `zzfaxdt` | `ZZFAXDT` | `ZZFAXDT` | DATS 8 | Fax Order Date | no — date/time |  |  |
| 51 | `zzflag_kol` | — (append only) | **?** |  | Flag Kolkata (EKKO append) | YES — flag/user, data element unknown |  |  |
| 52 | `zzflag_mum` | — (append only) | **?** |  | Flag Mumbai (EKKO append) | YES — flag/user, data element unknown |  |  |
| 53 | `zzflag_chen` | — (append only) | **?** |  | Flag Chennai (EKKO append) | YES — flag/user, data element unknown |  |  |
| 54 | `zzflag_del` | — (append only) | **?** |  | Flag Delhi (EKKO append) | YES — flag/user, data element unknown |  |  |
| 55 | `zzmse` | `ZZMSE` | `ZZMSE` | CHAR 2 | For MSE | YES — code field, check domain |  |  |
| 56 | `zzdmep` | `ZZDMEP` | `ZZDMEP` | CHAR 3 | Domestically Manufactured Electronic Products (DMEP) | YES — code field, check domain |  |  |
| 57 | `zsupconct` | `ZSUPCONCT` | `ZZSUPCONCT` | CHAR 15 | Supplier Contact No | no — free text / number |  |  |
| 58 | `zsupemail` | `ZSUPEMAIL` | `ZZSUPEMAIL` | CHAR 50 | Supplier Email | no — free text / number |  |  |
| 59 | `zfileno` | `ZFILENO` | `ZZFILENO` | CHAR 50 | File Number | no — free text / number |  |  |
| 60 | `zultname` | `ZULTNAME` | `AD_NAME1` | CHAR 40 | Name 1 | no — address text |  |  |
| 61 | `zultstreet` | `ZULTSTREET` | `AD_STREET` | CHAR 60 | Street | no — address text |  |  |
| 62 | `zultstreet1` | `ZULTSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | no — address text |  |  |
| 63 | `zultcity` | `ZULTCITY` | `AD_CITY1` | CHAR 40 | City | no — address text |  |  |
| 64 | `zultcontct` | `ZULTCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | no — address text |  |  |
| 65 | `zultemail` | `ZULTEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | no — address text |  |  |
| 66 | `zinvname` | `ZINVNAME` | `AD_NAME1` | CHAR 40 | Name 1 | no — address text |  |  |
| 67 | `zinvstreet` | `ZINVSTREET` | `AD_STREET` | CHAR 60 | Street | no — address text |  |  |
| 68 | `zinvstreet1` | `ZINVSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | no — address text |  |  |
| 69 | `zinvcity` | `ZINVCITY` | `AD_CITY1` | CHAR 40 | City | no — address text |  |  |
| 70 | `zinvcontct` | `ZINVCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | no — address text |  |  |
| 71 | `zinvemail` | `ZINVEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | no — address text |  |  |
| 72 | `zinsname` | `ZINSNAME` | `AD_NAME1` | CHAR 40 | Name 1 | no — address text |  |  |
| 73 | `zinsstreet` | `ZINSSTREET` | `AD_STREET` | CHAR 60 | Street | no — address text |  |  |
| 74 | `zinsstreet1` | `ZINSSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | no — address text |  |  |
| 75 | `zinscity` | `ZINSCITY` | `AD_CITY1` | CHAR 40 | City | no — address text |  |  |
| 76 | `zinscontct` | `ZINSCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | no — address text |  |  |
| 77 | `zinsemail` | `ZINSEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | no — address text |  |  |
| 78 | `zpayname` | `ZPAYNAME` | `AD_NAME1` | CHAR 40 | Name 1 | no — address text |  |  |
| 79 | `zpaystreet` | `ZPAYSTREET` | `AD_STREET` | CHAR 60 | Street | no — address text |  |  |
| 80 | `zpaystreet1` | `ZPAYSTREET1` | `AD_STRSPP1` | CHAR 40 | Street 2 | no — address text |  |  |
| 81 | `zpaycity` | `ZPAYCITY` | `AD_CITY1` | CHAR 40 | City | no — address text |  |  |
| 82 | `zpaycontct` | `ZPAYCONTCT` | `AD_TLNMBR1` | CHAR 30 | First Telephone No.: Dialing Code + Number | no — address text |  |  |
| 83 | `zpayemail` | `ZPAYEMAIL` | `AD_SMTPADR` | CHAR 241 | E-Mail Address | no — address text |  |  |
| 84 | `zgempo` | `ZGEMPO` | `ZGEMPONO` | CHAR 30 | GEM PO NO | no — free text / number |  |  |

Candidates to look up: 27 of 84 (plus `zzinsp_typ`, done).
