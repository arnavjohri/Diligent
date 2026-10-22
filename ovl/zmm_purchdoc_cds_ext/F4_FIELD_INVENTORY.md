# F4 field inventory — ZC_PURCHASEORDERTP_EXT (PO header custom fields)

Built 22/10/26 from `ZSTR_HEADER_vs_view.md` (data elements transcribed from SE11 on 19/10/26) and the
extension's select list; Domain / Fixed values filled from the SE11 print of `ZSTR_HEADER` with its
*Input Checks* section (`original/ZSTR_HEADER_SE11_print_2026-10-22.txt`). The print covers the 83
structure fields, not the 5 append-only ones, and shows foreign keys and fixed values only — a search
help assigned to a data element or a `PROCESS ON VALUE-REQUEST` module is not in it.
Second source, same day: the SE11 print of table `EKKO` itself (`original/EKKO_SE11_print_2026-10-22.txt`,
307 fields, `CI_EKKODB` at lines 344–555). It adds what the structure lacks: foreign keys on the
table (`ZZTPI_ADD` / `ZZQAD_DET` → `ADRC`, `ZZSUBMI` → `ZMM_PUR_TENDER_D`, `ZZPSA` / `ZZCPO` /
`ZZINDPER` / `ZZRELCODE` → check table `*`, i.e. the value table of the domain) and the data elements
of the five append-only fields (`ZZUSR` → `ERNAM`, `ZZFLAG_KOL/MUM/CHEN/DEL` → `ZMM_MAIL`, `ZMM_MAIL2..4`).
extension's select list. Fill **Domain** and **Fixed values** from SE11 (data element → Definition tab →
Domain; domain → Value Range tab). Only the rows marked YES / maybe need looking up; the others
cannot carry a fixed-value or table F4 by their type. `zzinsp_typ` is done (domain `ZINSP_TYP`).

| # | CDS element | ZSTR_HEADER component | Data element | Type | Description | F4 candidate | Domain | Fixed values / table |
|---|---|---|---|---|---|---|---|---|
| 1 | `zzt_nature` | `ZZT_NATURE` | `ZT_NATURE` | CHAR 3 | Nature of tender | fixed values | `ZT_NATURE` | 10 values: 1 ST-OEM … 10 Open Tender |
| 2 | `zztnd_dt` | `ZZTND_DT` | `ZTND_DT` | DATS 8 | Collective (Tender) Date | no — date/time |  |  |
| 3 | `zzlst_sel_date` | `ZZLST_SEL_DATE` | `ZLST_SEL_DATE` | DATS 8 | Last date of selling tender | no — date/time |  |  |
| 4 | `zzsub_time` | `ZZSUB_TIME` | `ZSUB_TIME` | TIMS 6 | Time of Submission of Tender | no — date/time |  |  |
| 5 | `zztb_op_dt` | `ZZTB_OP_DT` | `ZTB_OP_DT` | DATS 8 | Date of opening of bid / Tech-comm. Bid | no — date/time |  |  |
| 6 | `zztb_op_tm` | `ZZTB_OP_TM` | `ZTB_OP_TM` | TIMS 6 | Time of opening of bid / Tech-comm. Bid | no — date/time |  |  |
| 7 | `zzpb_op_dt` | `ZZPB_OP_DT` | `ZPB_OP_DT` | DATS 8 | Date of Price Bid Opening | no — date/time |  |  |
| 8 | `zzpb_op_tm` | `ZZPB_OP_TM` | `ZPB_OP_TM` | TIMS 6 | Time of Price Bid Opening | no — date/time |  |  |
| 9 | `zzpre_bid_dt` | `ZZPRE_BID_DT` | `ZPRE_BID_DT` | DATS 8 | Date of Pre-Bid Conference | no — date/time |  |  |
| 10 | `zzbd_type` | `ZZBD_TYPE` | `ZBD_TYPE` | CHAR 3 | Bidding System | fixed values | `ZBD_TYPE` | 1 Single Bid, 2 Two bid |
| 11 | `zzt_duration` | `ZZT_DURATION` | `ZT_DURATION` | CHAR 3 | Tender Duration type | fixed values | `ZT_DURATION` | 1 Short Tender, 2 Regular Tender |
| 12 | `zzlst_dt_que` | `ZZLST_DT_QUE` | `ZLST_DT_QUE` | DATS 8 | Last Date for receiving queries for Pre-bid conference | no — date/time |  |  |
| 13 | `zzinsp_typ` | `ZZINSP_TYP` | `ZINSP_TYP` | CHAR 3 | Inspection Type | done | `ZINSP_TYP` | 1 Source / 2 Destination Inspection |
| 14 | `zzvend_cat` | `ZZVEND_CAT` | `ZVEND_CAT` | CHAR 3 | Vendor Category | fixed values | `ZVEND_CAT` | 13 values: 1 OEM/OES … 13 MSE/NSIC/SSI-SC/ST-Women |
| 15 | `zzinsp_auth` | `ZZINSP_AUTH` | `ZINSP_AUTH` | CHAR 3 | Inspection Authority | fixed values | `ZINSP_AUTH` | 7 values: 1 QAD … 7 Others |
| 16 | `zzpre_awd` | `ZZPRE_AWD` | `ZPRE_AWD` | NUMC 3 | Pre award communication | no — interval 001–100, no list | `ZPRE_AWD` | interval 001–100 (validation only) |
| 17 | `zzpst_awd` | `ZZPST_AWD` | `ZPST_AWD` | NUMC 3 | Post award communication | no — interval 001–100, no list | `ZPST_AWD` | interval 001–100 (validation only) |
| 18 | `zzarbit` | `ZZARBIT` | `ZARBIT` | CHAR 2 | Arbitration cases | fixed values (one with blank key) | `ZARBIT` | '' No Arbitration, CA Closed, OA Open |
| 19 | `zzar_op_dt` | `ZZAR_OP_DT` | `ZAR_OP_DT` | DATS 8 | Date of Arbitration open | no — date/time |  |  |
| 20 | `zzar_cl_dt` | `ZZAR_CL_DT` | `ZAR_CL_DT` | DATS 8 | Date of Arbitration closed | no — date/time |  |  |
| 21 | `zztpi_add` | `ZZTPI_ADD` | `ZTPI_ADD` | CHAR 10 | Third Party Inspection address | check table | — | table `ADRC` (address number, ALPHA) — EKKO foreign key |
| 22 | `zzqad_det` | `ZZQAD_DET` | `ZQAD_DET` | CHAR 10 | QAD Department | check table | — | table `ADRC` (address number, ALPHA) — EKKO foreign key |
| 23 | `zzport_con` | `ZZPORT_CON` | `ZPORT_CON` | CHAR 10 | Port Consignee | no DDIC check on EKKO either — ALPHA like the two ADRC fields; search help / screen? | — | probably `ADRC` as well; the ZULT* address fields are copied from it |
| 24 | `zzult_con` | `ZZULT_CON` | `ZULT_CON` | CHAR 10 | Ultimate consignee | no DDIC check on EKKO either — ALPHA like the two ADRC fields; search help / screen? | — | probably `ADRC` as well; the ZULT* address fields are copied from it |
| 25 | `zupflag` | `ZUPFLAG` | `ZUPFLAG` | CHAR 1 | Flag for Ultimate & Port Cong. | no DDIC check — probably a checkbox | — |  |
| 26 | `zznat_proc` | `ZZNAT_PROC` | `ZNATPROC` | CHAR 2 | Tender Process | check table | — | table `ZNAT_PROC` (key `ZZNAT_PROC`, `SERIAL_NO` generic); GUI `pop_up`: `STATUS = 'active'` |
| 27 | `zznitdt` | `ZZNITDT` | `ZNITDT` | DATS 8 | Date of Publication of NIT in Website | no — date/time |  |  |
| 28 | `zzbider_agr` | `ZZBIDER_AGR` | `ZBIDERAGR` | CHAR 1 | Contract / PO awarded to Lowest bidder | fixed values | `ZBIDERAGR` | N No, Y Yes |
| 29 | `zzsch_st_dt` | `ZZSCH_ST_DT` | `ZSCHSTDT` | DATS 8 | Scheduled Work Start Date | no — date/time |  |  |
| 30 | `zzsch_en_dt` | `ZZSCH_EN_DT` | `ZSCHENDT` | DATS 8 | Schedule Work End Date | no — date/time |  |  |
| 31 | `zzsubmi` | `ZZSUBMI` | `SUBMI` | CHAR 10 | Collective Number | check table (was marked free text) | — | table `ZMM_PUR_TENDER_D` — EKKO foreign key; fields unknown |
| 32 | `zzepc` | `ZZEPC` | `ZZEPC` | CHAR 1 | EPC approval OLD Value | fixed values | `ZZEPC` | N No, Y Yes |
| 33 | `zzexchng_rate` | `ZZEXCHNG_RATE` | `ZWKURS` | DEC 9,5 | SRM-Exchange rate | no — amount/rate |  |  |
| 34 | `zzusr` | — (append only, `CI_EKKODB`) | `ERNAM` | CHAR 12 | User (EKKO append, not in ZSTR_HEADER) | no DDIC check — user name; `I_BusinessUserVH` is in the service if an F4 is wanted | — |  |
| 35 | `zzpsa` | `ZZPSA` | `ZPSA` | CHAR 12 | PO Signing Authority | check table `*` = value table of the domain | — | domain / value table from DD04L + DD01L |
| 36 | `zzcpo` | `ZZCPO` | `ZZCPO` | NUMC 8 | Contact Person for current PO | check table `*` = value table of the domain | — | domain / value table from DD04L + DD01L |
| 37 | `zzphone` | `ZZPHONE` | `ZZPNO` | CHAR 11 | Landline Number | no — free text / number |  |  |
| 38 | `zzfax` | `ZZFAX` | `ZZFAX` | CHAR 25 | Fax Number | no — free text / number |  |  |
| 39 | `zzmobile` | `ZZMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | no — free text / number |  |  |
| 40 | `zzemail` | `ZZEMAIL` | `ZZEMA` | CHAR 40 | Email ID | no — free text / number |  |  |
| 41 | `zzindper` | `ZZINDPER` | `ZZIND` | NUMC 8 | Indenting person for current PO | check table `*` = value table of the domain | — | domain / value table from DD04L + DD01L |
| 42 | `zzindphone` | `ZZINDPHONE` | `ZZPNO` | CHAR 11 | Landline Number | no — free text / number |  |  |
| 43 | `zzindfax` | `ZZINDFAX` | `ZZFAX` | CHAR 25 | Fax Number | no — free text / number |  |  |
| 44 | `zzindmobile` | `ZZINDMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | no — free text / number |  |  |
| 45 | `zzindemail` | `ZZINDEMAIL` | `ZZEMA` | CHAR 40 | Email ID | no — free text / number |  |  |
| 46 | `zzreldate` | `ZZRELDATE` | `ZZRELDATE` | DATS 8 | Release Date | no — date/time |  |  |
| 47 | `zzrelcode` | `ZZRELCODE` | `ZFRGCO` | CHAR 2 | Final Release Code | check table `*` = value table of the domain | — | domain / value table from DD04L + DD01L |
| 48 | `zzloino` | `ZZLOINO` | `ZZLOINO` | CHAR 20 | LOI/NOA number | no — free text / number |  |  |
| 49 | `zzloidt` | `ZZLOIDT` | `ZZLOIDT` | DATS 8 | LOI/NOA Date | no — date/time |  |  |
| 50 | `zzfaxdt` | `ZZFAXDT` | `ZZFAXDT` | DATS 8 | Fax Order Date | no — date/time |  |  |
| 51 | `zzflag_kol` | — (append only, `CI_EKKODB`) | `ZMM_MAIL` | CHAR 1 | Flag Kolkata (EKKO append) | no DDIC check — release flag Kolkata, checkbox | — |  |
| 52 | `zzflag_mum` | — (append only, `CI_EKKODB`) | `ZMM_MAIL2` | CHAR 1 | Flag Mumbai (EKKO append) | no DDIC check — release flag Mumbai, checkbox | — |  |
| 53 | `zzflag_chen` | — (append only, `CI_EKKODB`) | `ZMM_MAIL3` | CHAR 1 | Flag Chennai (EKKO append) | no DDIC check — release flag Chennai, checkbox | — |  |
| 54 | `zzflag_del` | — (append only, `CI_EKKODB`) | `ZMM_MAIL4` | CHAR 1 | Flag Delhi (EKKO append) | no DDIC check — release flag Delhi, checkbox | — |  |
| 55 | `zzmse` | `ZZMSE` | `ZZMSE` | CHAR 2 | For MSE | check table | — | table `ZMSE_EKKO` (key `ZZMSE`); text field unknown |
| 56 | `zzdmep` | `ZZDMEP` | `ZZDMEP` | CHAR 3 | Domestically Manufactured Electronic Products (DMEP) | fixed values | `ZZDMEP` | NO No, YES Yes |
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

## Sorted by F4 source (22/10/26)

| Case | Fields | Build |
|---|---|---|
| Fixed values of a domain (9) | `zzt_nature` `ZT_NATURE`, `zzbd_type` `ZBD_TYPE`, `zzt_duration` `ZT_DURATION`, `zzvend_cat` `ZVEND_CAT`, `zzinsp_auth` `ZINSP_AUTH`, `zzarbit` `ZARBIT`, `zzbider_agr` `ZBIDERAGR`, `zzepc` `ZZEPC`, `zzdmep` `ZZDMEP` | shared DD07T set, one block per field in the class; the view's WHERE widened |
| Interval fixed values (2) | `zzpre_awd`, `zzpst_awd` | nothing — 001–100 is a validation range, no list in the GUI either |
| Check table, Z (3) | `zznat_proc` → `ZNAT_PROC` (view `ZI_NAT_PROC_VH` written 19/10, activation unknown), `zzmse` → `ZMSE_EKKO`, `zzsubmi` → `ZMM_PUR_TENDER_D` (fields of the last two unknown) | one VH view + one entity set + one DPC branch each |
| Check table, address (2 + 2 probable) | `zztpi_add`, `zzqad_det` → `ADRC` (EKKO foreign key); `zzport_con`, `zzult_con` same type and ALPHA, no foreign key | address-number F4: no `ADRC` set in the service; decide with the functional lead whether an address number is even a sensible Fiori input, or whether these stay display-only |
| Check table `*` (4) | `zzpsa`, `zzcpo`, `zzindper`, `zzrelcode` | value table of the domain — from DD04L (domain) + DD01L (`ENTITYTAB`); user / personnel number / release code map to sets already in the service |
| No check at all (6) | `zupflag`, `zzusr`, `zzflag_kol`, `zzflag_mum`, `zzflag_chen`, `zzflag_del` | flags and a user name — no F4 to build unless asked |

Watch-outs: `ZARBIT` has a fixed value with a blank key (No Arbitration) — a key property with an empty
value in the entity set; test that the dropdown accepts it. `ZT_NATURE` value `10` sorts after `1` as
CHAR — order by `ValuePosition`, which the DPC does.
