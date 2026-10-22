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
Third and fourth source, same day: SE16N extracts of DD04L joined with DD01L and of DD07T
(`original/DD04L_DD01L_extract_2026-10-22.txt`, `original/DD07T_extract_2026-10-22.txt`) — domain,
search help and value table per data element, and the fixed values exactly as the view reads them.
**Every field on the Customers tab now has a known source.**
extension's select list. Fill **Domain** and **Fixed values** from SE11 (data element → Definition tab →
Domain; domain → Value Range tab). Only the rows marked YES / maybe need looking up; the others
cannot carry a fixed-value or table F4 by their type. `zzinsp_typ` is done (domain `ZINSP_TYP`).

| # | CDS element | ZSTR_HEADER component | Data element | Type | Description | F4 candidate | Domain | Fixed values / table |
|---|---|---|---|---|---|---|---|---|
| 1 | `zzt_nature` | `ZZT_NATURE` | `ZT_NATURE` | CHAR 3 | Nature of tender | fixed values — in class v8 | `ZT_NATURE` | 10 values (DD07T 22/10/26): 1 ST-OEM … 9 LT-Indegineous development, 10 Open Tender |
| 2 | `zztnd_dt` | `ZZTND_DT` | `ZTND_DT` | DATS 8 | Collective (Tender) Date | no — date/time |  |  |
| 3 | `zzlst_sel_date` | `ZZLST_SEL_DATE` | `ZLST_SEL_DATE` | DATS 8 | Last date of selling tender | no — date/time |  |  |
| 4 | `zzsub_time` | `ZZSUB_TIME` | `ZSUB_TIME` | TIMS 6 | Time of Submission of Tender | no — date/time |  |  |
| 5 | `zztb_op_dt` | `ZZTB_OP_DT` | `ZTB_OP_DT` | DATS 8 | Date of opening of bid / Tech-comm. Bid | no — date/time |  |  |
| 6 | `zztb_op_tm` | `ZZTB_OP_TM` | `ZTB_OP_TM` | TIMS 6 | Time of opening of bid / Tech-comm. Bid | no — date/time |  |  |
| 7 | `zzpb_op_dt` | `ZZPB_OP_DT` | `ZPB_OP_DT` | DATS 8 | Date of Price Bid Opening | no — date/time |  |  |
| 8 | `zzpb_op_tm` | `ZZPB_OP_TM` | `ZPB_OP_TM` | TIMS 6 | Time of Price Bid Opening | no — date/time |  |  |
| 9 | `zzpre_bid_dt` | `ZZPRE_BID_DT` | `ZPRE_BID_DT` | DATS 8 | Date of Pre-Bid Conference | no — date/time |  |  |
| 10 | `zzbd_type` | `ZZBD_TYPE` | `ZBD_TYPE` | CHAR 3 | Bidding System | fixed values — in class v8 | `ZBD_TYPE` | 1 Single Bid, 2 Two bid |
| 11 | `zzt_duration` | `ZZT_DURATION` | `ZT_DURATION` | CHAR 3 | Tender Duration type | fixed values — in class v8 | `ZT_DURATION` | 1 Short Tender, 2 Regular Tender |
| 12 | `zzlst_dt_que` | `ZZLST_DT_QUE` | `ZLST_DT_QUE` | DATS 8 | Last Date for receiving queries for Pre-bid conference | no — date/time |  |  |
| 13 | `zzinsp_typ` | `ZZINSP_TYP` | `ZINSP_TYP` | CHAR 3 | Inspection Type | done | `ZINSP_TYP` | 1 Source / 2 Destination Inspection |
| 14 | `zzvend_cat` | `ZZVEND_CAT` | `ZVEND_CAT` | CHAR 3 | Vendor Category | fixed values — in class v8 | `ZVEND_CAT` | 13 values: 1 OEM/OES … 13 MSE/NSIC/SSI-SC/ST-Women |
| 15 | `zzinsp_auth` | `ZZINSP_AUTH` | `ZINSP_AUTH` | CHAR 3 | Inspection Authority | fixed values — in class v8 | `ZINSP_AUTH` | 7 values: 1 QAD … 7 Others |
| 16 | `zzpre_awd` | `ZZPRE_AWD` | `ZPRE_AWD` | NUMC 3 | Pre award communication | no — interval, no list | `ZPRE_AWD` | DD07T: one row 001–100 'Validate the ranges from 1 to 100' |
| 17 | `zzpst_awd` | `ZZPST_AWD` | `ZPST_AWD` | NUMC 3 | Post award communication | no — interval, no list | `ZPST_AWD` | DD07T: one row 001–100 'Validate the ranges from 1 to 100' |
| 18 | `zzarbit` | `ZZARBIT` | `ZARBIT` | CHAR 2 | Arbitration cases | fixed values — in class v8 (blank key!) | `ZARBIT` | '' No Arbitration (pos 1), OA Arbitration Open, CA Arbitration Closed |
| 19 | `zzar_op_dt` | `ZZAR_OP_DT` | `ZAR_OP_DT` | DATS 8 | Date of Arbitration open | no — date/time |  |  |
| 20 | `zzar_cl_dt` | `ZZAR_CL_DT` | `ZAR_CL_DT` | DATS 8 | Date of Arbitration closed | no — date/time |  |  |
| 21 | `zztpi_add` | `ZZTPI_ADD` | `ZTPI_ADD` | CHAR 10 | Third Party Inspection address | check table — functional decision | `AD_ADDRNUM` | value table `ADRC`, search help `ADMC`, ALPHA — address number |
| 22 | `zzqad_det` | `ZZQAD_DET` | `ZQAD_DET` | CHAR 10 | QAD Department | check table — functional decision | `AD_ADDRNUM` | value table `ADRC`, search help `ADMC`, ALPHA — address number |
| 23 | `zzport_con` | `ZZPORT_CON` | `ZPORT_CON` | CHAR 10 | Port Consignee | check table — functional decision | `AD_ADDRNUM` | value table `ADRC`, search help `ADMC`, ALPHA — address number (confirmed by DD04L) |
| 24 | `zzult_con` | `ZZULT_CON` | `ZULT_CON` | CHAR 10 | Ultimate consignee | check table — functional decision | `AD_ADDRNUM` | value table `ADRC`, search help `ADMC`, ALPHA — address number (confirmed by DD04L) |
| 25 | `zupflag` | `ZUPFLAG` | `ZUPFLAG` | CHAR 1 | Flag for Ultimate & Port Cong. | no — flag | `CHAR1` |  |
| 26 | `zznat_proc` | `ZZNAT_PROC` | `ZNATPROC` | CHAR 2 | Tender Process | check table — own VH view | `ZNATPROC` | value table `ZNAT_PROC`, search help `ZNAT_PROC_H`; GUI `pop_up`: `STATUS = 'active'` |
| 27 | `zznitdt` | `ZZNITDT` | `ZNITDT` | DATS 8 | Date of Publication of NIT in Website | no — date/time |  |  |
| 28 | `zzbider_agr` | `ZZBIDER_AGR` | `ZBIDERAGR` | CHAR 1 | Contract / PO awarded to Lowest bidder | fixed values — in class v8 | `ZBIDERAGR` | Y Yes, N No |
| 29 | `zzsch_st_dt` | `ZZSCH_ST_DT` | `ZSCHSTDT` | DATS 8 | Scheduled Work Start Date | no — date/time |  |  |
| 30 | `zzsch_en_dt` | `ZZSCH_EN_DT` | `ZSCHENDT` | DATS 8 | Schedule Work End Date | no — date/time |  |  |
| 31 | `zzsubmi` | `ZZSUBMI` | `SUBMI` | CHAR 10 | Collective Number | check table — own VH view | `CHAR10` | foreign key on EKKO to `ZMM_PUR_TENDER_D` (key `SUBMI`); fields unknown |
| 32 | `zzepc` | `ZZEPC` | `ZZEPC` | CHAR 1 | EPC approval OLD Value | fixed values — in class v8 | `ZZEPC` | Y Yes, N No |
| 33 | `zzexchng_rate` | `ZZEXCHNG_RATE` | `ZWKURS` | DEC 9,5 | SRM-Exchange rate | no — amount/rate |  |  |
| 34 | `zzusr` | — (append only, `CI_EKKODB`) | `ERNAM` | CHAR 12 | User (EKKO append, not in ZSTR_HEADER) | no — user name | `USNAM` | `I_BusinessUserVH` if ever wanted |
| 35 | `zzpsa` | `ZZPSA` | `ZPSA` | CHAR 12 | PO Signing Authority | value table — SAP set | `XUBNAME` | value table `USR02` → user ID: `I_BusinessUserVH` is in the service, annotation only |
| 36 | `zzcpo` | `ZZCPO` | `ZZCPO` | NUMC 8 | Contact Person for current PO | value table — needs a VH view | `PERSNO` | value table `PA0003` → personnel number; no personnel set in the service |
| 37 | `zzphone` | `ZZPHONE` | `ZZPNO` | CHAR 11 | Landline Number | no — free text / number |  |  |
| 38 | `zzfax` | `ZZFAX` | `ZZFAX` | CHAR 25 | Fax Number | no — free text / number |  |  |
| 39 | `zzmobile` | `ZZMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | no — free text / number |  |  |
| 40 | `zzemail` | `ZZEMAIL` | `ZZEMA` | CHAR 40 | Email ID | no — free text / number |  |  |
| 41 | `zzindper` | `ZZINDPER` | `ZZIND` | NUMC 8 | Indenting person for current PO | value table — needs a VH view | `PERSNO` | value table `PA0003` → personnel number; no personnel set in the service |
| 42 | `zzindphone` | `ZZINDPHONE` | `ZZPNO` | CHAR 11 | Landline Number | no — free text / number |  |  |
| 43 | `zzindfax` | `ZZINDFAX` | `ZZFAX` | CHAR 25 | Fax Number | no — free text / number |  |  |
| 44 | `zzindmobile` | `ZZINDMOBILE` | `ZZMOB` | CHAR 11 | Mobile Number | no — free text / number |  |  |
| 45 | `zzindemail` | `ZZINDEMAIL` | `ZZEMA` | CHAR 40 | Email ID | no — free text / number |  |  |
| 46 | `zzreldate` | `ZZRELDATE` | `ZZRELDATE` | DATS 8 | Release Date | no — date/time |  |  |
| 47 | `zzrelcode` | `ZZRELCODE` | `ZFRGCO` | CHAR 2 | Final Release Code | value table — needs a VH view | `FRGCO` | value table `T16FC` (texts `T16FD`) → release code, depends on the release group |
| 48 | `zzloino` | `ZZLOINO` | `ZZLOINO` | CHAR 20 | LOI/NOA number | no — free text / number |  |  |
| 49 | `zzloidt` | `ZZLOIDT` | `ZZLOIDT` | DATS 8 | LOI/NOA Date | no — date/time |  |  |
| 50 | `zzfaxdt` | `ZZFAXDT` | `ZZFAXDT` | DATS 8 | Fax Order Date | no — date/time |  |  |
| 51 | `zzflag_kol` | — (append only, `CI_EKKODB`) | `ZMM_MAIL` | CHAR 1 | Flag Kolkata (EKKO append) | no — flag | `ZMM_MAIL` |  |
| 52 | `zzflag_mum` | — (append only, `CI_EKKODB`) | `ZMM_MAIL2` | CHAR 1 | Flag Mumbai (EKKO append) | no — flag | `ZMM_MAIL` |  |
| 53 | `zzflag_chen` | — (append only, `CI_EKKODB`) | `ZMM_MAIL3` | CHAR 1 | Flag Chennai (EKKO append) | no — flag | `ZMM_MAIL` |  |
| 54 | `zzflag_del` | — (append only, `CI_EKKODB`) | `ZMM_MAIL4` | CHAR 1 | Flag Delhi (EKKO append) | no — flag | `ZMM_MAIL` |  |
| 55 | `zzmse` | `ZZMSE` | `ZZMSE` | CHAR 2 | For MSE | check table — own VH view | `ZZMSE` (no fixed values) | foreign key on EKKO to `ZMSE_EKKO` (key `ZZMSE`); fields unknown |
| 56 | `zzdmep` | `ZZDMEP` | `ZZDMEP` | CHAR 3 | Domestically Manufactured Electronic Products (DMEP) | fixed values — in class v8 | `ZZDMEP` | YES Yes, NO No |
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
| 84 | `zgempo` | `ZGEMPO` | `ZGEMPONO` | CHAR 30 | GEM PO NO | YES — search help on the field | — | search help `ZGEM_ORDER` on `ZSTR_HEADER-ZGEMPO` (GUI technical info 22/10/26); selection method and parameters to be read in SE11 |

Candidates to look up: 27 of 84 (plus `zzinsp_typ`, done).

## Sorted by F4 source (22/10/26)

| Case | Fields | Build |
|---|---|---|
| Fixed values of a domain (9) | `zzt_nature` `ZT_NATURE`, `zzbd_type` `ZBD_TYPE`, `zzt_duration` `ZT_DURATION`, `zzvend_cat` `ZVEND_CAT`, `zzinsp_auth` `ZINSP_AUTH`, `zzarbit` `ZARBIT`, `zzbider_agr` `ZBIDERAGR`, `zzepc` `ZZEPC`, `zzdmep` `ZZDMEP` | shared DD07T set, one block per field in the class; the view's WHERE widened |
| Interval fixed values (2) | `zzpre_awd`, `zzpst_awd` | the GUI F4 shows the interval line; Fiori gets a dialog with Value, Upper Value, Description from view v3 (`DomainValueHigh`) and class v13; picking the line fills the lower bound |
| Check table, Z (3) | `zznat_proc` → `ZNAT_PROC` (GUI: `MODULE pop_up`; view `ZI_NAT_PROC_VH` written 19/10, **not active** — ST22 22/10), `zzmse` → `ZMSE_EKKO` (GUI: `MODULE pop_up_mse`), `zzsubmi` → `ZMM_PUR_TENDER_D` (no POV module — plain foreign key) | one VH view + one entity set + one DPC branch each; the two modules' code gives the exact selects |
| Check table, address (4, confirmed) | `zztpi_add`, `zzqad_det`, `zzport_con`, `zzult_con` — all `AD_ADDRNUM`, value table `ADRC`, search help `ADMC` | address-number F4: no `ADRC` set in the service; decide with the functional lead whether an address number is a sensible Fiori input at all |
| Value table of the domain (4, resolved) | `zzpsa` → `USR02` (user: `I_BusinessUserVH` in the service, annotation only); `zzcpo`, `zzindper` → `PA0003` (personnel number: no set in the service, needs a VH view over HR data — authorisation question); `zzrelcode` → `T16FC` (release code: no set in the service, and the valid codes depend on the PO's release group) | annotation only for `zzpsa`; the other three need a decision |
| Search help on the field (1) | `zgempo` → `ZGEM_ORDER` | one VH view over the search help's selection method, once read in SE11 |
| No check at all (6) | `zupflag`, `zzusr`, `zzflag_kol`, `zzflag_mum`, `zzflag_chen`, `zzflag_del` | flags and a user name — no F4 to build unless asked |

Watch-outs: `ZARBIT` has a fixed value with a blank key (No Arbitration) — a key property with an empty
value in the entity set; test that the dropdown accepts it. `ZT_NATURE` value `10` sorts after `1` as
CHAR — order by `ValuePosition`, which the DPC does.
