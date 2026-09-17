
*&---------------------------------------------------------------------*
*& Report  ZSD_CUSTOMER_DATA
*&
*&---------------------------------------------------------------------*
*&   Created By     : Carina Jose
*&   Creation Date  : 19.01.2021
*&---------------------------------------------------------------------*
REPORT zsd_customer_data.

TABLES : kna1,knvv,knkk, but000.
SELECTION-SCREEN : BEGIN OF BLOCK a1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS : s_kunnr FOR kna1-kunnr.
  SELECT-OPTIONS : s_knkli FOR knkk-knkli.
  SELECT-OPTIONS : s_vkorg FOR knvv-vkorg OBLIGATORY.
  SELECT-OPTIONS : s_vtweg FOR knvv-vtweg.
  SELECT-OPTIONS : s_spart FOR knvv-spart.
*SELECT-OPTIONS : s_vkgrp FOR knvv-vkgrp.
  SELECT-OPTIONS : s_vkbur FOR knvv-vkbur.
  SELECT-OPTIONS : s_aufsd FOR kna1-aufsd.
  PARAMETERS: p_chkbx AS CHECKBOX MODIF ID grp.  """added by akshay dt.29.07.2025
  PARAMETERS: p_chkbx1 AS CHECKBOX MODIF ID grp.  """added by akshay dt.29.07.2025
  PARAMETERS: p_batch AS CHECKBOX MODIF ID grp.

SELECTION-SCREEN : END OF BLOCK a1.

TYPES : BEGIN OF ty_kna1,
          kunnr                      TYPE kna1-kunnr,
          land1                      TYPE kna1-land1,
          name1                      TYPE kna1-name1,
          name2                      TYPE kna1-name2,
          sortl                      TYPE kna1-sortl,
          bu_sort2                   TYPE but000-bu_sort2, ""added by shubham wani 28.07.2026
          telf1                      TYPE kna1-telf1,
          adrnr                      TYPE kna1-adrnr,
          bp_adrnr                   TYPE but000-addrcomm,
          anred                      TYPE kna1-anred,
          erdat                      TYPE kna1-erdat,
          ktokd                      TYPE kna1-ktokd,
          kukla                      TYPE kna1-kukla,
          name3                      TYPE kna1-name3,
          name4                      TYPE kna1-name4,
          ort02                      TYPE kna1-ort02,
          telf2                      TYPE kna1-telf2,
          stcd3                      TYPE kna1-stcd3,
          taxnum3                    TYPE kna1-stcd3, " Added by BP
          aufsd                      TYPE kna1-aufsd,
          sperr                      TYPE kna1-sperr,  "Added by Shubham Wani on 14.07.2026 - Posting Block
          bran1                      TYPE kna1-bran1,
          brsch                      TYPE kna1-brsch,
          bbbnr                      TYPE kna1-bbbnr,  "Added by CarinaJose 13/07/2021
          bbsnr                      TYPE kna1-bbsnr,  "Added by CarinaJose 13/07/2021
          bahns                      TYPE kna1-bahns,
          faksd                      TYPE kna1-faksd,  "Added by Raj on23.05.2023
          lifsd                      TYPE kna1-lifsd,  "Added by Raj on23.05.2023
          bahne                      TYPE kna1-bahne, "Added by Raj on 06.10.2023
          stcd5                      TYPE kna1-stcd5, "Added by Raj on 06.10.2023
          taxnum5                    TYPE kna1-stcd5, " Added by BP
          katr1                      TYPE kna1-katr1, "Added by Raj on 23.08.2024 "Added by Raj on 23.08.2024
          mp_code                    TYPE kna1-mp_code, "Added by Rutvion 29.01.2025
          mp_code_create_date        TYPE kna1-mp_code_create_date, "Added by Rutvi on 29.01.2025
          old_parent_code            TYPE kna1-old_parent_code, "Added by Rutvi on 29.01.2025
          remark                     TYPE kna1-remark, "Added by Rutvi on 29.01.2025

          "START OF ADDITION OF NEW FIELDS OF HANA BY RANJAN 31.01.2026

          zz1_zzflag_t_cus           TYPE kna1-zz1_zzflag_t_cus,
          zz1_mp_code_cus            TYPE kna1-zz1_mp_code_cus,
          zz1_mp_code_create_dat_cus TYPE kna1-zz1_mp_code_create_dat_cus,
          zz1_old_parent_code_cus    TYPE kna1-zz1_old_parent_code_cus,
          zz1_remark_cus             TYPE kna1-zz1_remark_cus,
          zz1_sp_code_cus            TYPE kna1-zz1_sp_code_cus,
          zz1_cf_indicator_cus       TYPE kna1-zz1_cf_indicator_cus,
          zz1_cf_valid_from_cus      TYPE kna1-zz1_cf_valid_from_cus,
          zz1_cf_valid_to_cus        TYPE kna1-zz1_cf_valid_to_cus,
          zz1_agreement_status_cus   TYPE kna1-zz1_agreement_status_cus,
          zz1_cheque_details_cus     TYPE kna1-zz1_cheque_details_cus,
          zz1_update_loyalty_sta_cus TYPE kna1-zz1_update_loyalty_sta_cus,
          zz1_alp_flag_cus           TYPE  kna1-zz1_alp_flag_cus,
          zz1_code_to_consider_cus   TYPE kna1-zz1_code_to_consider_cus,
          zz1_dms_tagging_cus        TYPE kna1-zz1_dms_tagging_cus,
          zz1_posid1_cus             TYPE  kna1-zz1_posid1_cus,
          zz1_posid2_cus             TYPE  kna1-zz1_posid2_cus,
          zz1_posid3_cus             TYPE  kna1-zz1_posid3_cus,
          zz1_posid4_cus             TYPE  kna1-zz1_posid4_cus,
          zz1_posid5_cus             TYPE  kna1-zz1_posid5_cus,
          zz1_posid6_cus             TYPE  kna1-zz1_posid6_cus,
          zz1_geo1_cus               TYPE kna1-zz1_geo1_cus,
          zz1_geo2_cus               TYPE kna1-zz1_geo2_cus,
          zz1_geo3_cus               TYPE kna1-zz1_geo3_cus,
          zz1_geo4_cus               TYPE kna1-zz1_geo4_cus,
          zz1_geo5_cus               TYPE kna1-zz1_geo5_cus,
          zz1_geo6_cus               TYPE kna1-zz1_geo6_cus,
          zz1_tax5_cus               TYPE kna1-zz1_tax5_cus,
          type                       TYPE but000-type,


          "END OF ADDITION OF NEW FIELDS OF HANA BY RANJAN 31.01.2026
        END OF ty_kna1.

TYPES : BEGIN OF ty_knvv,
          kunnr TYPE knvv-kunnr,
          vkorg TYPE knvv-vkorg,
          vtweg TYPE knvv-vtweg,
          spart TYPE knvv-spart,
          kalks TYPE knvv-kalks,
          kdgrp TYPE knvv-kdgrp,
          bzirk TYPE knvv-bzirk,
          konda TYPE knvv-konda,
          pltyp TYPE knvv-pltyp,
          waers TYPE knvv-waers,
          zterm TYPE knvv-zterm,
          vkgrp TYPE knvv-vkgrp,
          vkbur TYPE knvv-vkbur,
          inco1 TYPE knvv-inco1,
          erdat TYPE knvv-erdat,
          kvgr1 TYPE knvv-kvgr1,   ""Added by Ranjan 31.01.2026
          kvgr2 TYPE knvv-kvgr2,   ""Added by Ranjan 31.01.2026
          ktgrd TYPE knvv-ktgrd,
*          inco1 type knvv-inco1,
          vsbed TYPE knvv-vsbed,
          kzazu TYPE knvv-kzazu,
          aufsd TYPE knvv-aufsd, " ADDED BY AARTI K
          faksd TYPE knvv-faksd, " ADDED BY AARTI K
          lifsd TYPE knvv-lifsd, " ADDED BY AARTI K
        END OF ty_knvv.

TYPES : BEGIN OF ty_adrc,
          addrnumber TYPE adrc-addrnumber,
          city1      TYPE adrc-city1,
          city2      TYPE adrc-city2,
          post_code1 TYPE adrc-post_code1,
          street     TYPE adrc-street,
          str_suppl1 TYPE adrc-str_suppl1,
          str_suppl2 TYPE adrc-str_suppl2,
          str_suppl3 TYPE adrc-str_suppl3,
          langu      TYPE adrc-langu,
          region     TYPE adrc-region,
          mc_name1   TYPE adrc-mc_name1,
          extension1 TYPE adrc-extension1,
          extension2 TYPE adrc-extension2,
        END OF ty_adrc.

TYPES : BEGIN OF ty_adr6,
          addrnumber TYPE adr6-addrnumber,
          smtp_addr  TYPE adr6-smtp_addr,
        END OF ty_adr6.
TYPES : BEGIN OF ty_adrct,
          addrnumber TYPE adrct-addrnumber,
          remark     TYPE adrct-remark,
        END OF ty_adrct.
TYPES : BEGIN OF ty_knkk,
          kunnr TYPE knkk-kunnr,
          kkber TYPE knkk-kkber,
          klimk TYPE knkk-klimk,
          knkli TYPE knkk-knkli,
          sauft TYPE knkk-sauft,
          skfor TYPE knkk-skfor,
          uedat TYPE knkk-uedat,
          ctlpc TYPE knkk-ctlpc,
        END OF ty_knkk.

TYPES : BEGIN OF ty_t014,
          kkber TYPE t014-kkber,
          waers TYPE t014-waers,
        END OF ty_t014.

"""""""""Added by Shubham Wani on 14.07.2026"""""""""""""""
TYPES : BEGIN OF ty_ukmbp_cms_sgm,
          partner      TYPE ukmbp_cms_sgm-partner,
          credit_sgmnt TYPE ukmbp_cms_sgm-credit_sgmnt,
          credit_limit TYPE ukmbp_cms_sgm-credit_limit,
        END OF ty_ukmbp_cms_sgm.

DATA : it_ukmbp_cms_sgm TYPE STANDARD TABLE OF ty_ukmbp_cms_sgm,
       wa_ukmbp_cms_sgm TYPE ty_ukmbp_cms_sgm.
"""""""""Ended by Shubham Wani on 14.07.2026"""""""""""""""

TYPES : BEGIN OF ty_j_1imocust,
          " ATC Correction for S4 HANA **BEGIN OF CHANGE BY UDAYABAP03 12.01.2026  FOR ATC
*           kunnr     TYPE j_1imocust-kunnr,
          kunnr     TYPE kna1-kunnr,
          " ATC Correction for S4 HANA * *END OF CHANGE BY UDAYABAP03 12.01.2026 FOR ATC
          " ATC Correction for S4 HANA **BEGIN OF CHANGE BY UDAYABAP03 12.01.2026  FOR ATC
*           j_1ipanno TYPE j_1imocust-j_1ipanno,
          j_1ipanno TYPE kna1-j_1ipanno,
          " ATC Correction for S4 HANA * *END OF CHANGE BY UDAYABAP03 12.01.2026 FOR ATC
        END OF ty_j_1imocust.

TYPES : BEGIN OF ty_tvast,
          spras TYPE tvast-spras,
          aufsp TYPE tvast-aufsp,
          vtext TYPE tvast-vtext,
        END OF ty_tvast.

TYPES : BEGIN OF ty_tinct,
          spras TYPE tinct-spras,
          inco1 TYPE tinct-inco1,
          bezei TYPE tinct-bezei,
        END OF ty_tinct.
********************************Added by Raj on 23.05.2023****************
TYPES : BEGIN OF ty_tvlst,
          spras TYPE tvlst-spras,
          lifsp TYPE tvlst-lifsp,
          vtext TYPE tvlst-vtext,
        END OF ty_tvlst.

TYPES : BEGIN OF ty_tvfst,
          spras TYPE tvfst-spras,
          faksp TYPE tvfst-faksp,
          vtext TYPE tvfst-vtext,
        END OF ty_tvfst.
********************************Added by Raj on 23.05.2023****************

********************************Added by Raj on 25.11.2023****************

TYPES : BEGIN OF ty_tvzbt,
          spras TYPE tvzbt-spras,
          zterm TYPE tvzbt-zterm,
          vtext TYPE tvzbt-vtext,
        END OF ty_tvzbt.

DATA : it_tvzbt TYPE STANDARD TABLE OF ty_tvzbt,
       wa_tvzbt TYPE ty_tvzbt.
* ********************************Added by Raj on 25.11.2023****************
TYPES : BEGIN OF ty_knvp,
          kunnr TYPE knvp-kunnr,
          vkorg TYPE knvp-vkorg,
          vtweg TYPE knvp-vtweg,
          spart TYPE knvp-spart,
          parvw TYPE knvp-parvw,
          kunn2 TYPE knvp-kunn2,
        END OF ty_knvp.
TYPES : BEGIN OF ty_tvko,
          vkorg TYPE tvko-vkorg,
        END OF ty_tvko.
TYPES : BEGIN OF ty_final,
          kunnr                      TYPE kna1-kunnr,
          partner                    TYPE kna1-kunnr,
          vkorg                      TYPE knvv-vkorg,
          bukrs                      TYPE knb1-bukrs,
          vtweg                      TYPE knvv-vtweg,
          spart                      TYPE knvv-spart,
          kalks                      TYPE knvv-kalks,
          kdgrp                      TYPE knvv-kdgrp,
          bzirk                      TYPE knvv-bzirk,
          bzdes                      TYPE t171t-bztxt,
          konda                      TYPE knvv-konda,
          pltyp                      TYPE knvv-pltyp,
          waers                      TYPE knvv-waers,
          zterm                      TYPE knvv-zterm,
          ztag1                      TYPE dztage,
          vkgrp                      TYPE knvv-vkgrp,
          vkdes                      TYPE tvgrt-bezei,
          vkbur                      TYPE knvv-vkbur,
          vdesc                      TYPE tvkbt-bezei,
          land1                      TYPE kna1-land1,
          name1                      TYPE kna1-name1,
          name2                      TYPE kna1-name2,
          sortl                      TYPE kna1-sortl,
          bu_sort2                   TYPE but000-bu_sort2, ""added by shubham wani 28.07.2026
          telf1                      TYPE kna1-telf1,
          anred                      TYPE kna1-anred,
          erdat                      TYPE kna1-erdat,
          ktokd                      TYPE kna1-ktokd,
          kukla                      TYPE kna1-kukla,
          name3                      TYPE kna1-name3,
          name4                      TYPE kna1-name4,
          ort02                      TYPE kna1-ort02,
          telf2                      TYPE kna1-telf2,
          stcd3                      TYPE kna1-stcd3,
          aufsd                      TYPE kna1-aufsd,
          sperr                      TYPE kna1-sperr, "Added by Shubham Wani on 14.07.2026 - Posting Block
          credit_limit               TYPE ukmbp_cms_sgm-credit_limit, "Added by Shubham Wani on 14.07.2026 - Credit Limit
          city1                      TYPE adrc-city1,
          city2                      TYPE adrc-city2,
          post_code1                 TYPE adrc-post_code1,
          street                     TYPE adrc-street,
          str_suppl1                 TYPE adrc-str_suppl1,
          str_suppl2                 TYPE adrc-str_suppl2,
          str_suppl3                 TYPE adrc-str_suppl3,
          langu                      TYPE adrc-langu,
          region                     TYPE adrc-region,
          mc_name1                   TYPE adrc-mc_name1,
          extension1                 TYPE adrc-extension1,
          extension2                 TYPE adrc-extension2,
          kkber                      TYPE knkk-kkber,
          klimk                      TYPE knkk-klimk,
          knkli                      TYPE knkk-knkli,
          sauft                      TYPE knkk-sauft,
          skfor                      TYPE knkk-skfor,
          uedat                      TYPE knkk-uedat,
          waers002                   TYPE knvv-waers,
          " ATC Correction for S4 HANA **BEGIN OF CHANGE BY UDAYABAP03 12.01.2026  FOR ATC
*           panno               TYPE j_1imocust-j_1ipanno,
          panno                      TYPE kna1-j_1ipanno,
          " ATC Correction for S4 HANA * *END OF CHANGE BY UDAYABAP03 12.01.2026 FOR ATC
          email                      TYPE adr6-smtp_addr,
          bran1                      TYPE kna1-bran1,
          brsch                      TYPE kna1-brsch,
          remark                     TYPE adrct-remark,
          perdat                     TYPE kna1-erdat,
          vtext                      TYPE tvast-vtext,
          vtext1                     TYPE tvast-vtext,  "Added by Raj on 23.05.2023
          vtext2                     TYPE tvast-vtext,  "Added by Raj on 23.05.2023
          kunn2                      TYPE knvp-kunn2,
          dname1                     TYPE kna1-name1,
          ctlpc                      TYPE knkk-ctlpc,

***********   Added changes by Carina Jose on 08/07/2021
          zone                       TYPE zsd_zone-name,
          szone                      TYPE zsd_zone-sname,
          lcategory1                 TYPE zsd_custemp_assg-lcategory,
          lname1                     TYPE zsd_custemp_assg-lname,
          lcategory2                 TYPE zsd_custemp_assg-lcategory,
          lname2                     TYPE zsd_custemp_assg-lname,
          lcategory3                 TYPE zsd_custemp_assg-lcategory,
          lname3                     TYPE zsd_custemp_assg-lname,
          lcategory4                 TYPE zsd_custemp_assg-lcategory,
          lname4                     TYPE zsd_custemp_assg-lname,
          lcategory5                 TYPE zsd_custemp_assg-lcategory,
          lname5                     TYPE zsd_custemp_assg-lname,
          lcategory6                 TYPE zsd_custemp_assg-lcategory,
          lname6                     TYPE zsd_custemp_assg-lname,
***********   End of changes on 08/07/2021
          bahns                      TYPE kna1-bahns,
          inco1                      TYPE knvv-inco1,
          ekvbd                      TYPE knb1-ekvbd,   "buying group
          faksd                      TYPE kna1-faksd,   "Added by Raj on 23.05.2023
          lifsd                      TYPE kna1-lifsd,   "Added by Raj on 23.05.2023
          taxkd                      TYPE knvi-taxkd,
          taxkd_s                    TYPE knvi-taxkd,
          taxkd_c                    TYPE knvi-taxkd,
          taxkd_i                    TYPE knvi-taxkd,
          mahna                      TYPE knb5-mahna,   "Added by Raj on 15.09.2023
          bahne                      TYPE kna1-bahne,   "Added by Raj on 06.10.2023
          stcd5                      TYPE kna1-stcd5,   "Added by Raj on 06.10.2023
          pay_desc                   TYPE tvzbt-vtext,  "Added by Raj on 25.11.2023
          text                       TYPE string,       "Added by Raj on 01.03.2024
          text_c                     TYPE string,       "Added by Raj on 01.03.2024
          text_s                     TYPE string,       "Added by Raj on 01.03.2024
          text_i                     TYPE string,       "Added by Raj on 01.03.2024
          licnr                      TYPE knvl-licnr,   "Added by Raj on 26.03.2024
          datab                      TYPE knvl-datab,   "Added by Raj on 26.03.2024
          datbi                      TYPE knvl-datbi,   "Added by Raj on 26.03.2024
          belic                      TYPE knvl-belic,   "Added by Raj on 26.03.2024
          katr1                      TYPE tvk1t-vtext,  "Added by Raj on 23.08.2024
          banks                      TYPE knbk-banks,   "Added by Rutvion 18.11.2024
          bankl                      TYPE knbk-bankl,   "Added by Rutvion 18.11.2024
          banka                      TYPE bnka-banka,   "Added by Rutvion 18.11.2024
          bankn                      TYPE knbk-bankn,   "Added by Rutvion 18.11.2024
          koinh                      TYPE knbk-koinh,   "Added by Rutvion 18.11.2024
          mp_code                    TYPE kna1-mp_code, "Added by Rutvion 29.01.2025
          mp_code_create_date        TYPE kna1-mp_code_create_date, "Added by Rutvi on 29.01.2025
          old_parent_code            TYPE kna1-old_parent_code, "Added by Rutvi on 29.01.2025
          remark_k                   TYPE kna1-remark,  "Added by Rutvion 29.01.2025
          kdesc                      TYPE t077x-txt30,  "Added by Raj on 12.02.2025
          kcdesc                     TYPE t151t-ktext,  "Added by Raj on 20.02.2025

          ""START OF ADDITION OF NEW FIELDS OF HANA BY RANJAN 31.01.2026

          zz1_zzflag_t_cus           TYPE kna1-zz1_zzflag_t_cus,
          zz1_mp_code_cus            TYPE kna1-zz1_mp_code_cus,
          zz1_mp_code_create_dat_cus TYPE kna1-zz1_mp_code_create_dat_cus,
          zz1_old_parent_code_cus    TYPE kna1-zz1_old_parent_code_cus,
          zz1_remark_cus             TYPE kna1-zz1_remark_cus,
          zz1_sp_code_cus            TYPE kna1-zz1_sp_code_cus,
          zz1_cf_indicator_cus       TYPE kna1-zz1_cf_indicator_cus,
          zz1_cf_valid_from_cus      TYPE kna1-zz1_cf_valid_from_cus,
          zz1_cf_valid_to_cus        TYPE kna1-zz1_cf_valid_to_cus,
          zz1_agreement_status_cus   TYPE kna1-zz1_agreement_status_cus,
          zz1_cheque_details_cus     TYPE kna1-zz1_cheque_details_cus,
          zz1_update_loyalty_sta_cus TYPE kna1-zz1_update_loyalty_sta_cus,
          zz1_alp_flag_cus           TYPE  kna1-zz1_alp_flag_cus,
          zz1_code_to_consider_cus   TYPE kna1-zz1_code_to_consider_cus,
          zz1_dms_tagging_cus        TYPE kna1-zz1_dms_tagging_cus,
          zz1_posid1_cus             TYPE  kna1-zz1_posid1_cus,
          zz1_posid2_cus             TYPE  kna1-zz1_posid2_cus,
          zz1_posid3_cus             TYPE  kna1-zz1_posid3_cus,
          zz1_posid4_cus             TYPE  kna1-zz1_posid4_cus,
          zz1_posid5_cus             TYPE  kna1-zz1_posid5_cus,
          zz1_posid6_cus             TYPE  kna1-zz1_posid6_cus,
          zz1_geo1_cus               TYPE kna1-zz1_geo1_cus,
          zz1_geo2_cus               TYPE kna1-zz1_geo2_cus,
          zz1_geo3_cus               TYPE kna1-zz1_geo3_cus,
          zz1_geo4_cus               TYPE kna1-zz1_geo4_cus,
          zz1_geo5_cus               TYPE kna1-zz1_geo5_cus,
          zz1_geo6_cus               TYPE kna1-zz1_geo6_cus,
          zz1_tax5_cus               TYPE kna1-zz1_tax5_cus,
          kvgr1                      TYPE knvv-kvgr1,
          kvgr2                      TYPE knvv-kvgr1,
          vsbed                      TYPE knvv-vsbed,
*          inco1                      type knvv-inco1,
          ktgrd                      TYPE knvv-ktgrd,
          akont                      TYPE knb1-akont,
          bezei_desc                 TYPE tinct-bezei,
          kvgr2_desc                 TYPE tvv2t-bezei,
          kvgr1_desc                 TYPE tvv1t-bezei,
          type                       TYPE but000-type,
          ""END OF ADDITION OF NEW FIELDS OF HANA BY RANJAN 31.01.2026

*    **   Start added by Archna Gupta on 06.03.2026
          zz1_lid_1_sdh              TYPE vbak-zz1_lid_1_sdh,
**          zz1_l1_d_sdh               TYPE vbak-zz1_l1_d_sdh,
          emp_name1                  TYPE string,
          l1_mob                     TYPE sysid,
          l1_email                   TYPE comm_id_long,

          zz1_lid_2_sdh              TYPE vbak-zz1_lid_2_sdh,
**          zz1_l2_d_sdh               TYPE vbak-zz1_l2_d_sdh,
          emp_name2                  TYPE string,
          l2_mob                     TYPE sysid,
          l2_email                   TYPE comm_id_long,

          zz1_lid_3_sdh              TYPE vbak-zz1_lid_3_sdh,
**          zz1_l3_d_sdh               TYPE vbak-zz1_l3_d_sdh,
          emp_name3                  TYPE string,
          l3_mob                     TYPE sysid,
          l3_email                   TYPE comm_id_long,

          zz1_lid_4_sdh              TYPE vbak-zz1_lid_4_sdh,
**          zz1_l4_d_sdh               TYPE vbak-zz1_l4_d_sdh,
          emp_name4                  TYPE string,
          l4_mob                     TYPE sysid,
          l4_email                   TYPE comm_id_long,

          zz1_lid_5_sdh              TYPE vbak-zz1_lid_5_sdh,
**          zz1_l5_d_sdh               TYPE vbak-zz1_l5_d_sdh,
          emp_name5                  TYPE string,
          l5_mob                     TYPE sysid,
          l5_email                   TYPE comm_id_long,

          zz1_lid_6_sdh              TYPE vbak-zz1_lid_6_sdh,
**          zz1_l6_d_sdh               TYPE vbak-zz1_l6_d_sdh,
          emp_name6                  TYPE string,
          l6_mob                     TYPE sysid,
          l6_email                   TYPE comm_id_long,

          zz1_lid_7_sdh              TYPE vbak-zz1_lid_7_sdh,
**          zz1_l7_d_sdh               TYPE vbak-zz1_l7_d_sdh,
          emp_name7                  TYPE string,
          l7_mob                     TYPE sysid,
          l7_email                   TYPE comm_id_long,

          zz1_gid_1_sdh              TYPE vbak-zz1_gid_1_sdh,
          zz1_g1_d_sdh               TYPE vbak-zz1_g1_d_sdh,

          zz1_gid_2_sdh              TYPE vbak-zz1_gid_2_sdh,
          zz1_g2_d_sdh               TYPE vbak-zz1_g2_d_sdh,

          zz1_gid_3_sdh              TYPE vbak-zz1_gid_3_sdh,
          zz1_g3_d_sdh               TYPE vbak-zz1_g3_d_sdh,

          zz1_gid_4_sdh              TYPE vbak-zz1_gid_4_sdh,
          zz1_g4_d_sdh               TYPE vbak-zz1_g4_d_sdh,

          zz1_gid_5_sdh              TYPE vbak-zz1_gid_5_sdh,
          zz1_g5_d_sdh               TYPE vbak-zz1_g5_d_sdh,

          zz1_gid_6_sdh              TYPE vbak-zz1_gid_6_sdh,
          zz1_g6_d_sdh               TYPE vbak-zz1_g6_d_sdh,

          zz1_gid_7_sdh              TYPE vbak-zz1_gid_7_sdh,
          zz1_g7_d_sdh               TYPE vbak-zz1_g7_d_sdh,
**  End of change By Archna Gupta on 06.03.2026
          kzazu                      TYPE knvv-kzazu,
**          mobile                     TYPE sysid,
**          email_id                   TYPE comm_id_long,
        END OF ty_final.

DATA: it_kna1       TYPE STANDARD TABLE OF ty_kna1,
      wa_kna1       TYPE ty_kna1,
      it_pkna1      TYPE STANDARD TABLE OF ty_kna1,
      wa_pkna1      TYPE ty_kna1,
      it_dkna1      TYPE STANDARD TABLE OF ty_kna1,
      wa_dkna1      TYPE ty_kna1,
      it_knvv       TYPE STANDARD TABLE OF ty_knvv,
      wa_knvv       TYPE ty_knvv,
      it_knvp       TYPE STANDARD TABLE OF ty_knvp,
      wa_knvp       TYPE ty_knvp,
      it_tvko       TYPE STANDARD TABLE OF ty_tvko,
      wa_tvko       TYPE ty_tvko,
      it_knkk       TYPE STANDARD TABLE OF ty_knkk,
      wa_knkk       TYPE ty_knkk,
      it_t014       TYPE STANDARD TABLE OF ty_t014,
      wa_t014       TYPE ty_t014,
      it_adrct      TYPE STANDARD TABLE OF ty_adrct,
      wa_adrct      TYPE ty_adrct,
      it_adrc       TYPE STANDARD TABLE OF ty_adrc,
      it_adrc_bp    TYPE STANDARD TABLE OF ty_adrc,
      wa_adrc       TYPE ty_adrc,
      it_adr6       TYPE STANDARD TABLE OF ty_adr6,
      wa_adr6       TYPE ty_adr6,
      it_j_1imocust TYPE STANDARD TABLE OF ty_j_1imocust,
      wa_j_1imocust TYPE ty_j_1imocust,
      it_tvast      TYPE STANDARD TABLE OF ty_tvast,
      wa_tvast      TYPE ty_tvast,
      it_tinct      TYPE STANDARD TABLE OF ty_tinct,
      wa_tinct      TYPE ty_tinct,
*****************************************Added by Raj on 23.05.2023**************************************************
      it_tvlst      TYPE STANDARD TABLE OF ty_tvlst,
      wa_tvlst      TYPE ty_tvlst,
      it_tvfst      TYPE STANDARD TABLE OF ty_tvfst,
      wa_tvfst      TYPE ty_tvfst,
*****************************************Added by Raj on 23.05.2023**************************************************
      it_final      TYPE STANDARD TABLE OF ty_final,
      wa_final      TYPE ty_final,
      it_final1     TYPE STANDARD TABLE OF ty_final,
      wa_final1     TYPE ty_final.

DATA : t_listheader   TYPE slis_t_listheader   WITH HEADER LINE,
       t_fieldcatalog TYPE slis_t_fieldcat_alv WITH HEADER LINE,
       fs_layout      TYPE slis_layout_alv,
       t_event        TYPE slis_t_event WITH HEADER LINE.

TYPES: BEGIN OF ty_tvarvc1,
         sign TYPE tvarv_sign,
         opti TYPE tvarv_opti,
         low  TYPE tvarv_val,
         high TYPE tvarv_val,
       END OF ty_tvarvc1.

************ Added by Carina Jose on 13/07/2021
DATA: it_zone TYPE STANDARD TABLE OF zsd_zone,
      wa_zone TYPE zsd_zone.
TYPES : BEGIN OF ty_custemp,
          kunnr     TYPE zsd_custemp_assg-kunnr,
          lcategory TYPE zsd_custemp_assg-lcategory,
          lid       TYPE zsd_custemp_assg-lid,
          startval  TYPE  zsd_custemp_assg-startval,
          endval    TYPE  zsd_custemp_assg-endval,
          lname     TYPE zsd_custemp_assg-lname,
        END OF ty_custemp.
DATA : it_custemp TYPE STANDARD TABLE OF ty_custemp,
       wa_custemp TYPE ty_custemp.

TYPES : BEGIN OF ty_knb1,
          kunnr TYPE knb1-kunnr,
          bukrs TYPE knb1-bukrs,
          ekvbd TYPE knb1-ekvbd,
          akont TYPE knb1-akont,
        END OF ty_knb1.
DATA : it_knb1 TYPE STANDARD TABLE OF ty_knb1,
       wa_knb1 TYPE ty_knb1.
************ End of changes on 13/07/2021

DATA: lt_acc_key1  TYPE STANDARD TABLE OF ty_tvarvc1.
DATA: lwa_acc_key1 TYPE ty_tvarvc1,
      lv_country   TYPE tvarv_val.

*******Begin of changes Added by Raj on 15.09.2023***********************
TYPES : BEGIN OF ty_knb5,
          kunnr TYPE knb5-kunnr,
          bukrs TYPE knb5-bukrs,
          mahna TYPE knb5-mahna,
        END OF ty_knb5.

DATA : it_knb5 TYPE STANDARD TABLE OF ty_knb5,
       wa_knb5 TYPE ty_knb5.

DATA : ls_hierarchy TYPE zst_hierarchy_flat.

*******Begin of changes Added by Raj on 15.09.2023***********************

CONSTANTS : c_var_user    TYPE rvari_vnam VALUE 'ZSD_CUSTCREDIT_SHOW',
            c_var_country TYPE rvari_vnam VALUE 'ZSD_COUNTRY',
            c_type_user   TYPE rsscr_kind VALUE 'S'.

TYPES: BEGIN OF ty_lock,
         objectclas TYPE cdhdr-objectclas,
         objectid   TYPE cdhdr-objectid,
         changenr   TYPE cdhdr-changenr,
         udate      TYPE cdhdr-udate,
         tabname    TYPE cdpos-tabname,
         fname      TYPE cdpos-fname,
       END OF ty_lock.

DATA: gt_lock TYPE TABLE OF ty_lock,
      gs_lock TYPE ty_lock.
"""""addded by akshay dt.29.07.2025

AT SELECTION-SCREEN OUTPUT.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* Transport DEVK900442 ECC to S4 Hana Migration
* Replaced Code:
*  SELECT SINGLE low FROM tvarvc INTO @DATA(lv_user) WHERE low = @sy-uname AND name = 'ZSD_CUST_USER' AND type = 'S'.

  SELECT low FROM tvarvc INTO @DATA(lv_user) UP TO 1 ROWS WHERE low = @sy-uname AND name = 'ZSD_CUST_USER' AND type = 'S'
   ORDER BY PRIMARY KEY .
  ENDSELECT.

* End of Quick Fix

  LOOP AT SCREEN.
    IF screen-name = 'P_CHKBX'. " Or check screen-group1 if using MODIFID
      IF sy-uname = lv_user. " Replace with the desired user ID
        screen-invisible = '0'. " Make visible
        screen-active = '1'.  " Make active/editable
      ELSE.
        screen-invisible = '1'. " Make invisible
        screen-active = '0'.  " Make inactive/non-editable
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  """"eoc dt.29.07.2025

START-OF-SELECTION.
  PERFORM authorization_check.
  PERFORM get_data.
  IF  it_knvv IS INITIAL.
    MESSAGE 'No customer available for the provided input' TYPE 'S' DISPLAY LIKE 'E'.
  ELSEIF it_kna1 IS INITIAL.
    MESSAGE 'Please enter valid Central order block for customer' TYPE 'S' DISPLAY LIKE 'E'.
  ELSE.
    PERFORM fill_fieldcatalog.
    PERFORM display_grid.
    "Added by UDAYABAP03 on 01.05.2026
    IF p_batch = 'X'.
      PERFORM f_batch.
    ENDIF.
    "Added by UDAYABAP03 on 01.05.2026
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data .
  SELECT sign
         opti
         low
         high
    INTO CORRESPONDING FIELDS OF TABLE lt_acc_key1
    FROM tvarvc
    WHERE name = c_var_user
      AND type = c_type_user.

  SELECT low
   INTO lv_country FROM tvarvc UP TO 1 ROWS WHERE name = c_var_country
   ORDER BY PRIMARY KEY .
  ENDSELECT.

  SELECT kunnr vkorg vtweg spart kalks kdgrp bzirk konda pltyp kzazu waers zterm vkgrp vkbur inco1 erdat kvgr1 kvgr2 ktgrd vsbed aufsd faksd   lifsd
    INTO CORRESPONDING FIELDS OF TABLE it_knvv
    FROM knvv
    WHERE kunnr IN s_kunnr
    AND   vkorg IN s_vkorg
    AND   vtweg IN s_vtweg
    AND   spart IN s_spart
*    AND   vkgrp IN s_vkgrp.
    AND   vkbur IN s_vkbur.

  IF it_knvv IS NOT INITIAL.
    SELECT * FROM t151t INTO TABLE @DATA(it_t151t) FOR ALL ENTRIES IN @it_knvv
    WHERE kdgrp = @it_knvv-kdgrp AND spras = 'E'.

    SELECT zterm, ztag1 FROM t052 FOR ALL ENTRIES IN @it_knvv
      WHERE zterm = @it_knvv-zterm INTO TABLE @DATA(it_ztag1).
  ENDIF.



* Start chnage by Archna Gupta on 11.03.2026

*select single
*select single
*data: v_ZZ1_GEO1_CUS type kna1-ZZ1_GEO1_CUS,
*      v_ZZ1_POSID1_CUS type kna1-ZZ1_POSID1_CUS,
*      v_kunnr type kna1-kunnr.
*
*data: v_spart type knvv-spart,
*      v_kvgr1 type knvv-kvgr1.
*
*select single  kunnr, ZZ1_GEO1_CUS, ZZ1_POSID1_CUS from kna1 INTO ( v_kunnr, v_ZZ1_GEO1_CUS, v_ZZ1_POSID1_CUS ) where kunnr in s_kunnr.
*select single spart, kvgr1 from knvv into ( v_spart, v_kvgr1 ) where kunnr = v_kunnr.


  IF it_knvv IS NOT INITIAL.
    SELECT  *
        FROM zsd_hierarchy_tb  INTO TABLE  @DATA(lt_hierarchy_tab) FOR ALL ENTRIES IN @it_knvv
        WHERE div = @it_knvv-spart
        AND cust_grp = @it_knvv-kvgr1.
*        AND geo_code = @wa_kna1-zz1_geo1_cus
*       AND position_id = @wa_kna1-zz1_posid1_cus.
  ENDIF.

*     SELECT  *
*        FROM zsd_hierarchy_tb  INTO TABLE @lt_hierarchy_tab FOR ALL ENTRIES IN @it_kna1
*        WHERE geo_code = @it_kna1-zz1_geo1_cus
*           and position_id = @it_kna1-zz1_posid1_cus.

  "Added by BP
  IF lt_hierarchy_tab IS NOT INITIAL.

    " 2. Fetch Holder (Person) from HRP1001 using Position ID
    SELECT objid, sobid
      FROM hrp1001
      FOR ALL ENTRIES IN @lt_hierarchy_tab
      WHERE otype = 'S'
        AND objid = @lt_hierarchy_tab-position_id
        AND relat = '008'
        AND sclas = 'P'
        AND begda <= @sy-datum
        AND endda >= @sy-datum
      INTO TABLE @DATA(lt_hrp1001).

    IF lt_hrp1001 IS NOT INITIAL.

      " 3. Fetch Mobile (CELL) and Email (0030) from PA0105
      SELECT pernr, subty, usrid, usrid_long
        FROM pa0105
        FOR ALL ENTRIES IN @lt_hrp1001
        WHERE pernr = @lt_hrp1001-objid
          AND ( subty = 'CELL' OR subty = '0030' )
          AND begda <= @sy-datum
          AND endda >= @sy-datum
        INTO TABLE @DATA(lt_pa0105).
    ENDIF.
  ENDIF.



********Customer Group Desc.***********
******* Added by Carina Jose on 13/07/2021
  SELECT * FROM zsd_zone INTO TABLE it_zone.
  SELECT kunnr bukrs ekvbd akont
    INTO CORRESPONDING FIELDS OF TABLE it_knb1
    FROM knb1
    FOR ALL ENTRIES IN it_knvv
  WHERE kunnr = it_knvv-kunnr.

  SELECT kunnr lcategory lid startval endval lname
    INTO CORRESPONDING FIELDS OF TABLE it_custemp
    FROM zsd_custemp_assg
    FOR ALL ENTRIES IN it_knvv
    WHERE kunnr = it_knvv-kunnr
    AND   startval <= sy-datum
  AND   endval >= sy-datum.
******* End of changes by Carina Jose on 13/07/2021

  SORT it_knvv.
  IF it_knvv IS NOT INITIAL.
    " Get customer master data
****    SELECT kunnr land1 name1 name2 sortl telf1 adrnr anred
****          aufsd faksd lifsd brsch erdat ktokd kukla name3 name4
****          ort02 telf2 stcd3 bran1 bbbnr bbsnr bahns bahne stcd5   "Bahne and stcd5 Added by Raj on 06.10.2023
****          katr1    "KATR1 Added by Raj on 23.08.2024
****          mp_code mp_code_create_date old_parent_code remark   "Added by Rutvi on 29.01.2025
****      " Added by Ranjan 31.01.2026
****          zz1_zzflag_t_cus  zz1_mp_code_cus zz1_mp_code_create_dat_cus  zz1_old_parent_code_cus zz1_remark_cus
****          zz1_sp_code_cus zz1_cf_indicator_cus  zz1_cf_valid_from_cus zz1_cf_valid_to_cus zz1_agreement_status_cus
****          zz1_cheque_details_cus  zz1_update_loyalty_sta_cus  zz1_alp_flag_cus  zz1_code_to_consider_cus
****          zz1_dms_tagging_cus zz1_posid1_cus  zz1_posid2_cus  zz1_posid3_cus  zz1_posid4_cus  zz1_posid5_cus
****          zz1_posid6_cus  zz1_geo1_cus  zz1_geo2_cus  zz1_geo3_cuszz1_geo4_cus  zz1_geo5_cus
****          zz1_geo6_cus  zz1_tax5_cus
****      " End of changes by Ranjan 31.01.2026
****
****      INTO CORRESPONDING FIELDS OF TABLE it_kna1
****      FROM kna1
****      FOR ALL ENTRIES IN it_knvv
****      WHERE kunnr = it_knvv-kunnr
****        AND aufsd IN s_aufsd.
    SELECT k~kunnr, k~land1, k~name1, k~name2, k~sortl, k~telf1,
           k~adrnr,                " Original KNA1 Address Number
           b~addrcomm AS bp_adrnr, " Address Number from BUT000 (BP Header)
           k~anred, k~aufsd, k~faksd, k~lifsd, k~brsch, k~erdat,
           k~ktokd, k~kukla, k~name3, k~name4, k~ort02, k~telf2,
           k~stcd3, t3~taxnum AS taxnum3,
           k~sperr,   "Added by Shubham Wani on 14.07.2026 -Posting Block
           k~bran1, k~bbbnr, k~bbsnr, k~bahns, k~bahne,
           k~stcd5, t5~taxnum AS taxnum5,
           k~katr1, k~mp_code, k~mp_code_create_date, k~old_parent_code, k~remark,
           k~zz1_zzflag_t_cus, k~zz1_mp_code_cus, k~zz1_mp_code_create_dat_cus,
           k~zz1_old_parent_code_cus, k~zz1_remark_cus, k~zz1_sp_code_cus,
           k~zz1_cf_indicator_cus, k~zz1_cf_valid_from_cus, k~zz1_cf_valid_to_cus,
           k~zz1_agreement_status_cus, k~zz1_cheque_details_cus, k~zz1_update_loyalty_sta_cus,
           k~zz1_alp_flag_cus, k~zz1_code_to_consider_cus, k~zz1_dms_tagging_cus,
           k~zz1_posid1_cus, k~zz1_posid2_cus, k~zz1_posid3_cus, k~zz1_posid4_cus,
           k~zz1_posid5_cus, k~zz1_posid6_cus, k~zz1_geo1_cus, k~zz1_geo2_cus,
           k~zz1_geo3_cus, k~zz1_geo4_cus, k~zz1_geo5_cus, k~zz1_geo6_cus, k~zz1_tax5_cus ,b~type, b~bu_sort2
      INTO CORRESPONDING FIELDS OF TABLE @it_kna1
      FROM kna1 AS k
      LEFT OUTER JOIN but000 AS b
      ON b~partner = k~kunnr
      LEFT OUTER JOIN dfkkbptaxnum AS t3 ON t3~partner = k~kunnr
                                    AND t3~taxtype = 'IN3'
      LEFT OUTER JOIN dfkkbptaxnum AS t5 ON t5~partner = k~kunnr
                                    AND t5~taxtype = 'IN5'
      FOR ALL ENTRIES IN @it_knvv
      WHERE k~kunnr = @it_knvv-kunnr
        AND k~aufsd IN @s_aufsd.

******-----------------------------  added by aarti kumari 08.05.2026..----------------------------**
*    READ TABLE it_kna1 INTO DATA(wa_kna1) INDEX 1.
*
*    IF wa_kna1-aufsd IS INITIAL.
*
*      SELECT k~kunnr, k~land1, k~name1, k~name2, k~sortl, k~telf1,
*      k~adrnr,                " Original KNA1 Address Number
*      b~addrcomm AS bp_adrnr, " Address Number from BUT000 (BP Header)
*      k~anred, kn~aufsd, kn~faksd, kn~lifsd, k~brsch, k~erdat,
*      k~ktokd, k~kukla, k~name3, k~name4, k~ort02, k~telf2,
*      k~stcd3, t3~taxnum AS taxnum3,
*      k~bran1, k~bbbnr, k~bbsnr, k~bahns, k~bahne,
*      k~stcd5, t5~taxnum AS taxnum5,
*      k~katr1, k~mp_code, k~mp_code_create_date, k~old_parent_code, k~remark,
*      k~zz1_zzflag_t_cus, k~zz1_mp_code_cus, k~zz1_mp_code_create_dat_cus,
*      k~zz1_old_parent_code_cus, k~zz1_remark_cus, k~zz1_sp_code_cus,
*      k~zz1_cf_indicator_cus, k~zz1_cf_valid_from_cus, k~zz1_cf_valid_to_cus,
*      k~zz1_agreement_status_cus, k~zz1_cheque_details_cus, k~zz1_update_loyalty_sta_cus,
*      k~zz1_alp_flag_cus, k~zz1_code_to_consider_cus, k~zz1_dms_tagging_cus,
*      k~zz1_posid1_cus, k~zz1_posid2_cus, k~zz1_posid3_cus, k~zz1_posid4_cus,
*      k~zz1_posid5_cus, k~zz1_posid6_cus, k~zz1_geo1_cus, k~zz1_geo2_cus,
*      k~zz1_geo3_cus, k~zz1_geo4_cus, k~zz1_geo5_cus, k~zz1_geo6_cus, k~zz1_tax5_cus ,b~type
*    INTO TABLE @DATA(it_knvvV)
*    FROM kna1 AS k
*    LEFT OUTER JOIN but000 AS b
*    ON b~partner = k~kunnr
*    LEFT OUTER JOIN dfkkbptaxnum AS t3 ON t3~partner = k~kunnr
*                               AND t3~taxtype = 'IN3'
*    LEFT OUTER JOIN dfkkbptaxnum AS t5 ON t5~partner = k~kunnr
*                               AND t5~taxtype = 'IN5'
*    INNER JOIN knvv AS kn ON kn~kunnr = k~kunnr
*    FOR ALL ENTRIES IN @it_knvv
*    WHERE k~kunnr = @it_knvv-kunnr
*    AND k~aufsd IN @s_aufsd.
*
*      SORT it_knvvV BY kunnr aufsd DESCENDING.
*
*      "Added by BP
*      LOOP AT it_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1>).
*        <fs_kna1> = VALUE #( BASE <fs_kna1>
*          stcd3 = COND #( WHEN <fs_kna1>-stcd3 IS INITIAL THEN <fs_kna1>-taxnum3 ELSE <fs_kna1>-stcd3 )
*          stcd5 = COND #( WHEN <fs_kna1>-stcd5 IS INITIAL THEN <fs_kna1>-taxnum5 ELSE <fs_kna1>-stcd5 ) ).
*
*        "" ADDED LOGIC BY AARTI KUMARI 08.05.2026
*        READ TABLE it_knvvV INTO DATA(wa_knvvV) WITH KEY kunnr = <fs_kna1>-kunnr.
*        <fs_kna1>-aufsd = wa_knvvV-aufsd.
*        <fs_kna1>-faksd = wa_knvvV-faksd.
*        <fs_kna1>-lifsd = wa_knvvV-lifsd.
**      <fs_kna1>-aufsd = wa_knvvV-aufsd.
*      ENDLOOP.
*
*    ELSE.
*      "Added by BP
*      LOOP AT it_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna11>).
*        <fs_kna11> = VALUE #( BASE <fs_kna11>
*          stcd3 = COND #( WHEN <fs_kna11>-stcd3 IS INITIAL THEN <fs_kna11>-taxnum3 ELSE <fs_kna11>-stcd3 )
*          stcd5 = COND #( WHEN <fs_kna11>-stcd5 IS INITIAL THEN <fs_kna11>-taxnum5 ELSE <fs_kna11>-stcd5 ) ).
*
*      ENDLOOP.
*
*    ENDIF.
*****----------------------------- ended BY aarti kumari 08.05.2026 ----------------------------**

    LOOP AT it_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna11>).
      <fs_kna11> = VALUE #( BASE <fs_kna11>
        stcd3 = COND #( WHEN <fs_kna11>-stcd3 IS INITIAL THEN <fs_kna11>-taxnum3 ELSE <fs_kna11>-stcd3 )
        stcd5 = COND #( WHEN <fs_kna11>-stcd5 IS INITIAL THEN <fs_kna11>-taxnum5 ELSE <fs_kna11>-stcd5 ) ).

    ENDLOOP.

    "Ended   by BP

* loop at it_kna1 INTO wa_kna1.
*  IF sy-subrc IS INITIAL.
*    DATA(lv_zz1_geo1_cus) = CONV char8( wa_kna1-zz1_geo1_cus ).
*  ENDIF.
*
*  IF it_kna1 IS NOT INITIAL.
*    SELECT  *
*        FROM zsd_hierarchy_tb  INTO TABLE @lt_hierarchy_tab FOR ALL ENTRIES IN @it_kna1
*      where geo_code = @lv_zz1_geo1_cus
*      AND position_id = @it_kna1-zz1_posid1_cus.
*  ENDIF.
*ENDLOOP.

    SELECT k~kunnr,
           k~adrnr AS kna1_adrnr,   " Legacy Address
           b20~addrnumber,          " Current BP Address
           a~extension1,
           a~extension2
      FROM kna1 AS k
      INNER JOIN but020 AS b20 ON b20~partner = k~kunnr
      INNER JOIN but021_fs AS b21 ON b21~partner   = b20~partner
                                AND b21~addrnumber = b20~addrnumber
      INNER JOIN adrc AS a ON a~addrnumber = b20~addrnumber
      FOR ALL ENTRIES IN @it_knvv
      WHERE k~kunnr = @it_knvv-kunnr
       AND b21~adr_kind = 'XXDEFAULT'      " Filter for Standard Address usage
       AND k~aufsd IN @s_aufsd
      INTO TABLE @DATA(it_ext).

************Begin of Change Added by Raj on 12.02.2025*********
    IF it_kna1 IS NOT INITIAL.
      SELECT * FROM t077x INTO TABLE @DATA(it_t077x) FOR ALL ENTRIES IN@it_kna1
       WHERE ktokd = @it_kna1-ktokd AND spras = 'E'
       ORDER BY PRIMARY KEY .
    ENDIF.
************End of Changes Added by Raj on 12.02.2025***********

    " Get Distributor Partner (ZD)
    SELECT kunnr vkorg vtweg spart parvw kunn2
      INTO CORRESPONDING FIELDS OF TABLE it_knvp
      FROM knvp
      FOR ALL ENTRIES IN it_knvv
      WHERE kunnr = it_knvv-kunnr
      AND   vkorg = it_knvv-vkorg
      AND   vtweg = it_knvv-vtweg
      AND   spart = it_knvv-spart
    AND   parvw = 'ZD'.
  ENDIF.
  " Get Distr. Parnter name
  IF it_knvp IS NOT INITIAL.
    SELECT kunnr name1
    INTO CORRESPONDING FIELDS OF TABLE it_dkna1
    FROM kna1
    FOR ALL ENTRIES IN it_knvp
    WHERE kunnr = it_knvp-kunn2.
  ENDIF.

  IF it_kna1 IS NOT INITIAL.
    " Get cust. address
    SELECT addrnumber city1 city2 post_code1 street str_suppl1 str_suppl2 str_suppl3 langu region mc_name1 extension1 extension2
      INTO CORRESPONDING FIELDS OF TABLE it_adrc
      FROM adrc
      FOR ALL ENTRIES IN it_kna1
      WHERE addrnumber = it_kna1-adrnr.

    " Get control block desc.
    SELECT spras aufsp vtext
      INTO CORRESPONDING FIELDS OF TABLE it_tvast
      FROM tvast
      FOR ALL ENTRIES IN it_kna1
      WHERE spras = sy-langu
    AND   aufsp = it_kna1-aufsd.

*******************************Added by Raj on 23.05.2023**********
    " Central billing block for customer .
    SELECT spras faksp vtext
      INTO CORRESPONDING FIELDS OF TABLE it_tvfst
      FROM tvfst
      FOR ALL ENTRIES IN it_kna1
      WHERE spras = sy-langu
    AND   faksp = it_kna1-faksd.

    " Central delivery block for the customer.
    SELECT spras lifsp vtext
      INTO CORRESPONDING FIELDS OF TABLE it_tvlst
      FROM tvlst
      FOR ALL ENTRIES IN it_kna1
      WHERE spras = sy-langu
    AND   lifsp = it_kna1-lifsd.

*******************************Added by Raj on 23.05.2023**********
    " Get cust. email
    SELECT addrnumber smtp_addr
      INTO CORRESPONDING FIELDS OF TABLE it_adr6
      FROM adr6
      FOR ALL ENTRIES IN it_kna1
    WHERE addrnumber = it_kna1-adrnr.

    " Get Address note
    SELECT addrnumber remark
    INTO CORRESPONDING FIELDS OF TABLE it_adrct
    FROM adrct
    FOR ALL ENTRIES IN it_kna1
    WHERE addrnumber = it_kna1-adrnr.
  ENDIF.

  IF it_knvv IS NOT INITIAL.
    " Get cust. credit control data
*    SELECT kunnr kkber klimk knkli sauft skfor uedat ctlpc
*      INTO CORRESPONDING FIELDS OF TABLE it_knkk
*      FROM knkk
*      FOR ALL ENTRIES IN it_knvv
*      WHERE kunnr = it_knvv-kunnr.

    """"""""""""""""""Commented by Shubham Wani on 14.07.2026""""""""""""
**    SELECT kunnr kkber klimk knkli sauft skfor uedat ctlpc
**    INTO CORRESPONDING FIELDS OF TABLE it_knkk
**    FROM knkk
**    FOR ALL ENTRIES IN it_knvv
**    WHERE kunnr = it_knvv-kunnr
**    AND knkli IN s_knkli.
    """"""""""""""""""end of Commented by Shubham Wani on 14.07.2026""""""""""""

    """"""""""""""""""Added by Shubham Wani on 14.07.2026""""""""""""
    SELECT partner, credit_sgmnt, credit_limit
      FROM ukmbp_cms_sgm
      INTO CORRESPONDING FIELDS OF TABLE @it_ukmbp_cms_sgm
      FOR ALL ENTRIES IN @it_knvv
      WHERE partner = @it_knvv-kunnr
      AND credit_sgmnt = '2000'.
    """"""""""""""""""ended by shubham wani on 14.07.2026""""""""""""

    SELECT spras inco1 bezei
      INTO CORRESPONDING FIELDS OF TABLE it_tinct
      FROM tinct
      FOR ALL ENTRIES IN it_knvv
      WHERE spras = 'E'
       AND  inco1 =  it_knvv-inco1.

  ENDIF.

  IF it_knkk IS NOT INITIAL.
    " Get Currency according to credit control area
    SELECT kkber waers
      INTO CORRESPONDING FIELDS OF TABLE it_t014
      FROM t014
      FOR ALL ENTRIES IN it_knkk
    WHERE kkber = it_knkk-kkber.
    " Get Parent customer creation date
    SELECT kunnr erdat
      INTO CORRESPONDING FIELDS OF TABLE it_pkna1
      FROM kna1
      FOR ALL ENTRIES IN it_knkk
    WHERE kunnr = it_knkk-knkli.

    " Get Pan Number
    " ATC Correction for S4 HANA ** BEGIN OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
*    SELECT kunnr j_1ipanno
*      INTO CORRESPONDING FIELDS OF TABLE it_j_1imocust
*      FROM j_1imocust                         "#EC CI_USAGE_OK[2877717]
*      FOR ALL ENTRIES IN it_knkk
*    WHERE kunnr = it_knkk-kunnr.


    " ATC Correction for S4 HANA ** END OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
  ENDIF.

  IF it_knvv IS NOT INITIAL.
    SELECT kunnr j_1ipanno
        INTO CORRESPONDING FIELDS OF TABLE it_j_1imocust
        FROM kna1
        FOR ALL ENTRIES IN it_knvv
      WHERE kunnr = it_knvv-kunnr.
  ENDIF.

****************Begin of changes Added by Raj on 15.09.2023********************
  IF it_knb1 IS NOT INITIAL.

    SELECT kunnr bukrs mahna
       FROM knb5 INTO TABLE it_knb5
       FOR ALL ENTRIES IN it_knb1
      WHERE kunnr = it_knb1-kunnr
    AND bukrs = it_knb1-bukrs.
  ENDIF.

*****************End of changes Added by Raj on 15.09.2023*********************
****************Begin of changes Added by Raj on 15.09.2023********************
  IF it_knvv IS NOT INITIAL.
    SELECT spras zterm vtext FROM tvzbt INTO TABLE it_tvzbt FOR ALL ENTRIES IN it_knvv WHERE zterm = it_knvv-zterm AND spras = 'EN'.
  ENDIF.
*  ****************End of changes Added by Raj on 15.09.2023********************
****************Begin of changes Added by Raj on 26.03.2024*********************
  IF it_knvv IS NOT INITIAL.
    SELECT kunnr,licnr,datab,datbi,belic FROM knvl INTO TABLE @DATA(it_knvl) FOR ALL ENTRIES IN @it_knvv WHERE kunnr = @it_knvv-kunnr.
  ENDIF.
  IF it_knvv IS NOT INITIAL.
    SELECT spras,kvgr2,bezei FROM tvv2t INTO TABLE @DATA(it_tvv2t) FOR ALL ENTRIES IN @it_knvv WHERE kvgr2 = @it_knvv-kvgr2 AND spras = 'E'.
  ENDIF.

  IF it_knvv IS NOT INITIAL.
    SELECT spras,kvgr1,bezei FROM tvv1t INTO TABLE @DATA(it_tvv1t) FOR ALL ENTRIES IN @it_knvv WHERE kvgr1 = @it_knvv-kvgr1 AND spras = 'E'.
  ENDIF.


  IF it_kna1 IS NOT INITIAL.  "Added by Raj on 23.08.2024
    SELECT spras,katr1,vtext FROM tvk1t INTO TABLE @DATA(it_tvk1t) FOR ALL ENTRIES IN @it_kna1 WHERE katr1 = @it_kna1-katr1 AND spras = 'E'.

*******************************************Added by Rutvi on 18.11.2024
    SELECT kunnr,
           banks,
           bankl,
           bankn,
           koinh FROM knbk INTO TABLE @DATA(it_knbk)
    FOR ALL ENTRIES IN @it_kna1 WHERE kunnr = @it_kna1-kunnr.

    IF it_knbk IS NOT INITIAL.

      SELECT banks,
             bankl,
             banka FROM bnka INTO TABLE @DATA(it_bnka)
             FOR ALL ENTRIES IN @it_knbk WHERE banks = @it_knbk-banks
      AND bankl = @it_knbk-bankl.

    ENDIF.
***********************************************************************

  ENDIF.
  "---------------------------------------------------------------- READ TABLES ---------------------------------------------------------------------------

  "Added by BP for the Partener
  SELECT partner1, partner2 FROM but050 INTO TABLE @DATA(lt_partner2)
    FOR ALL ENTRIES IN @it_kna1 WHERE partner2 = @it_kna1-kunnr.
  IF sy-subrc NE 0.
    SELECT partner1, partner2 FROM but050 INTO TABLE @DATA(lt_partner1)
        FOR ALL ENTRIES IN @it_kna1 WHERE partner2 = @it_kna1-kunnr.
  ENDIF.

*  LOOP AT it_knvv INTO wa_knvv.
  LOOP AT it_kna1 INTO wa_kna1.
***************************added by rutvi on 18.11.2024

    "Commented by BP|30.06.2026
**    READ TABLE lt_partner1 INTO DATA(ls_partner1) WITH KEY partner2 =wa_kna1-kunnr.
**    IF sy-subrc = 0.
**      wa_final-partner = ls_partner1-partner1.
**    ENDIF.
**
**    READ TABLE lt_partner2 INTO DATA(ls_partner) WITH KEY partner2 = wa_kna1-kunnr.
**    IF sy-subrc = 0.
**      wa_final-partner = ls_partner-partner1.
**    ENDIF.

    READ TABLE it_knbk INTO DATA(wa_knbk) WITH KEY kunnr = wa_kna1-kunnr.
    IF sy-subrc = 0.
      wa_final-banks = wa_knbk-banks.
      wa_final-bankl = wa_knbk-bankl.
      wa_final-bankn = wa_knbk-bankn.

      wa_final-koinh = wa_knbk-koinh.
      READ TABLE it_bnka INTO DATA(wa_bnka) WITH KEY banks = wa_knbk-banks
                                                     bankl = wa_knbk-bankl.
      IF sy-subrc = 0.
        wa_final-banka = wa_bnka-banka.
      ENDIF.
    ENDIF.

    READ TABLE it_knvv INTO wa_knvv WITH KEY kunnr = wa_kna1-kunnr.
    CLEAR ls_hierarchy.
    CALL FUNCTION 'ZSALES_HIERARCHY'
      EXPORTING
        iv_kunnr     = wa_kna1-kunnr
        iv_div       = wa_knvv-spart
        iv_cust_grp  = wa_knvv-kvgr1
*       IV_GEO_CODE  =
*       IV_POS_ID    =
      IMPORTING
        es_hierarchy = ls_hierarchy.

    IF ls_hierarchy IS NOT INITIAL.
      MOVE-CORRESPONDING ls_hierarchy TO wa_final.
    ENDIF.

    FIELD-SYMBOLS: <lv_pos_id> TYPE any,
                   <lv_mob>    TYPE any,
                   <lv_email>  TYPE any.
    DATA: lv_index TYPE n LENGTH 1.

    IF ls_hierarchy IS NOT INITIAL.
      MOVE-CORRESPONDING ls_hierarchy TO wa_final.

      DO 7 TIMES.
        lv_index = sy-index.

        ASSIGN COMPONENT 'ZZ1_LID_' && lv_index && '_SDH' OF STRUCTURE ls_hierarchy TO <lv_pos_id>.

        IF <lv_pos_id> IS ASSIGNED AND <lv_pos_id> IS NOT INITIAL.

          "Fetch PERNR
          SELECT SINGLE sobid FROM hrp1001 INTO @DATA(lv_pernr)
            WHERE otype = 'S'
              AND objid = @<lv_pos_id>
              AND relat = '008'
              AND sclas = 'P'
              AND begda <= @sy-datum AND endda >= @sy-datum.

          IF sy-subrc = 0.
            ASSIGN COMPONENT 'L' && lv_index && '_MOB'   OF STRUCTURE wa_final TO <lv_mob>.
            ASSIGN COMPONENT 'L' && lv_index && '_EMAIL' OF STRUCTURE wa_final TO <lv_email>.

            "Fetch Mobile
            IF <lv_mob> IS ASSIGNED.
              SELECT SINGLE usrid FROM pa0105 INTO @<lv_mob>
                WHERE pernr = @lv_pernr AND subty = 'CELL'
                  AND begda <= @sy-datum AND endda >= @sy-datum.
            ENDIF.

            "Fetch Email
            IF <lv_email> IS ASSIGNED.
              SELECT SINGLE usrid_long FROM pa0105 INTO @<lv_email>
                WHERE pernr = @lv_pernr AND subty = '0010'
                  AND begda <= @sy-datum AND endda >= @sy-datum.
            ENDIF.
          ENDIF.
        ENDIF.

        UNASSIGN: <lv_pos_id>, <lv_mob>, <lv_email>.
      ENDDO.
    ENDIF.



**    SELECT SINGLE objid, sobid FROM hrp1001 INTO @DATA(ls_holders)
**       WHERE otype = 'S' AND objid = @ls_hierarchy-zz1_l1_d_sdh
**       AND relat = '008' AND sclas = 'P'
**       AND begda <= @sy-datum AND endda >= @sy-datum.
**
**    IF sy-subrc = 0.
**      " 5. Contact Info (PA0105)
**      SELECT SINGLE usrid FROM pa0105 INTO @wa_final-l1_mob
**        WHERE pernr = @ls_holders-sobid AND subty = 'CELL'
**          AND begda <= @sy-datum AND endda >= @sy-datum.
**
**      SELECT SINGLE usrid_long FROM pa0105 INTO @wa_final-l1_EMAIL
**        WHERE pernr = @ls_holders-sobid AND subty = '0010'
**          AND begda <= @sy-datum AND endda >= @sy-datum.
**    ENDIF.


*************************************************************
*    READ TABLE it_knvv INTO wa_knvv WITH KEY kunnr = wa_kna1-kunnr.
    LOOP AT it_knvv INTO wa_knvv WHERE kunnr = wa_kna1-kunnr.
      wa_final-kunnr = wa_knvv-kunnr.
      wa_final-vkorg = wa_knvv-vkorg.
      wa_final-vtweg = wa_knvv-vtweg.
      wa_final-spart = wa_knvv-spart.
      wa_final-kalks = wa_knvv-kalks.
      wa_final-kdgrp = wa_knvv-kdgrp.
      wa_final-erdat = wa_knvv-erdat.
      wa_final-kvgr1 = wa_knvv-kvgr1.  "added by Ranjan 31.01.2026
      wa_final-kvgr2 = wa_knvv-kvgr2.  "added by Ranjan 31.01.2026
*      wa_final-inco1 = wa_knvv-inco1.  "added by Ranjan 31.01.2026
      wa_final-vsbed = wa_knvv-vsbed.  "added by Ranjan 31.01.2026
      wa_final-ktgrd = wa_knvv-ktgrd.  "added by Ranjan 31.01.2026
      wa_final-kzazu = wa_knvv-kzazu.

      "Added by BP|30.06.2026
      READ TABLE lt_partner1 INTO DATA(ls_partner1) WITH KEY partner2 =wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-partner = ls_partner1-partner1.
      ENDIF.

      READ TABLE lt_partner2 INTO DATA(ls_partner) WITH KEY partner2 = wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-partner = ls_partner-partner1.
      ENDIF.

      If wa_final-partner is INITIAL.
      wa_final-partner = wa_kna1-kunnr.  ""Added by Ranjan
      ENDIF.

      READ TABLE it_ztag1 INTO DATA(ls_ztag1) WITH KEY zterm = wa_knvv-zterm.
      IF sy-subrc = 0.
        wa_final-ztag1 = ls_ztag1-ztag1.
      ENDIF.

*     LOOP AT it_knvv ASSIGNING FIELD-SYMBOL(<ls_knvv>).
      """""""""""Archna
*          READ TABLE it_kna1 INTO wa_kna1 WITH KEY kunnr = wa_kna1-kunnr.
*           IF sy-subrc = 0.
**        READ TABLE it_knvv INTO wa_knvv WITH KEY kunnr = wa_kna1-kunnr.
**        IF sy-subrc = 0.
**          READ TABLE lt_hierarchy_tab INTO DATA(ls_hierarchy_tab) WITH KEY  geo_code = wa_kna1-zz1_geo1_cus
**      position_id = wa_kna1-zz1_posid1_cus
**      div = wa_knvv-spart         "
**      cust_grp = wa_knvv-kvgr1.
**
**          IF sy-subrc = 0.
**            CASE ls_hierarchy_tab-geo_level .
**              WHEN  'G7' .
**                wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                  wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**
**              WHEN 'G6'.
**                wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                  wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**
**              WHEN 'G5'.
**                wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                  wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**
**              WHEN 'G4'.
**                wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                  wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**
**              WHEN 'G3'.
**                wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                  wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**              WHEN 'G2'.
**                wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                  wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**              WHEN 'G1'.
**                wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
**                wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab-geo_desc."is_vbak-zz1_lid_7_sdh.
**                wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                  wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab-dummy_val.
**                ENDIF.
**              WHEN OTHERS.
**            ENDCASE.
**            READ TABLE lt_hierarchy_tab
**                       INTO DATA(ls_hierarchy_tab_6)
**                       WITH  KEY  geo_level = ls_hierarchy_tab-parent_geo_level
**                           div = wa_knvv-spart
**                           cust_grp = wa_knvv-kvgr1.
**            IF sy-subrc = 0.
**              CASE ls_hierarchy_tab_6-geo_level .
**                WHEN  'G7' .
**                  wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                    wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**                WHEN 'G6'.
**                  wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                    wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**                WHEN 'G5'.
**                  wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                  wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                    wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**                WHEN 'G4'.
**
**                  wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                  wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                    wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**                WHEN 'G3'.
**                  wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                  wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                    wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**
**                WHEN 'G2'.
**                  wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                  wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                    wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**                WHEN 'G1'.
**                  wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
**                  wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                  wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                  wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                  IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                    wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_6-dummy_val.
**                  ENDIF.
**
**                WHEN OTHERS.
**              ENDCASE.
**              READ TABLE lt_hierarchy_tab
**               INTO DATA(ls_hierarchy_tab_5)
**                WITH  KEY  geo_level = ls_hierarchy_tab_6-parent_geo_level
**                    div = wa_knvv-spart
**                    cust_grp = wa_knvv-kvgr1.
**              IF sy-subrc = 0.
**                CASE ls_hierarchy_tab_5-geo_level .
**                  WHEN  'G7' .
**
**                    wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                      wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN 'G6'.
**                    wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                      wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN 'G5'.
**                    wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                      wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN 'G4'.
**
**                    wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                      wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN 'G3'.
**                    wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                      wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN 'G2'.
**                    wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                      wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN 'G1'.
**                    wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
**                    wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                    wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                    wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                    IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                      wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_5-dummy_val.
**                    ENDIF.
**                  WHEN OTHERS.
**                ENDCASE.
***          STEP4
**                READ TABLE lt_hierarchy_tab
**                   INTO DATA(ls_hierarchy_tab_4)
**                   WITH  KEY  geo_level = ls_hierarchy_tab_5-parent_geo_level
**                       div = wa_knvv-spart
**                       cust_grp = wa_knvv-kvgr1.
**                IF sy-subrc = 0.
**
**                  CASE ls_hierarchy_tab_4-geo_level .
**                    WHEN  'G7' .
**
**                      wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                        wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**                    WHEN 'G6'.
**                      wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                        wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**                    WHEN 'G5'.
**                      wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                        wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**                    WHEN 'G4'.
**
**                      wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                        wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**                    WHEN 'G3'.
**                      wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                        wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**                    WHEN 'G2'.
**                      wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                        wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**                    WHEN 'G1'.
**                      wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
**                      wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                      wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                      wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                      IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                        wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_4-dummy_val.
**                      ENDIF.
**
**                    WHEN OTHERS.
**                  ENDCASE.
**
***            step 3
**                  READ TABLE lt_hierarchy_tab
**                     INTO DATA(ls_hierarchy_tab_3)
**                     WITH  KEY  geo_level = ls_hierarchy_tab_4-parent_geo_level
**                         div = wa_knvv-spart
**                         cust_grp = wa_knvv-kvgr1.
**                  IF sy-subrc = 0.
**                    CASE ls_hierarchy_tab_3-geo_level .
**                      WHEN  'G7' .
**
**                        wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                          wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**                      WHEN 'G6'.
**                        wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                          wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**                      WHEN 'G5'.
**                        wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                          wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**                      WHEN 'G4'.
**
**                        wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                          wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**                      WHEN 'G3'.
**                        wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                          wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**                      WHEN 'G2'.
**                        wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                          wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**                      WHEN 'G1'.
**                        wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
**                        wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                        wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                        wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                        IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                          wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_3-dummy_val.
**                        ENDIF.
**
**                      WHEN OTHERS.
**                    ENDCASE.
**
***              step 2
**                    READ TABLE lt_hierarchy_tab
**                       INTO DATA(ls_hierarchy_tab_2)
**                       WITH  KEY  geo_level = ls_hierarchy_tab_3-parent_geo_level
**                           div = wa_knvv-spart
**                           cust_grp = wa_knvv-kvgr1.
**                    IF sy-subrc = 0.
**
**                      CASE ls_hierarchy_tab_2-geo_level .
**                        WHEN  'G7' .
**
**                          wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                            wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN 'G6'.
**                          wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                            wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN 'G5'.
**                          wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                            wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN 'G4'.
**
**                          wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                            wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN 'G3'.
**                          wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                            wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN 'G2'.
**                          wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                            wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN 'G1'.
**                          wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
**                          wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                          wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                          wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                          IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                            wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_2-dummy_val.
**                          ENDIF.
**                        WHEN OTHERS.
**                      ENDCASE.
***                step 1
**                      READ TABLE lt_hierarchy_tab
**                  INTO DATA(ls_hierarchy_tab_1)
**                   WITH  KEY  geo_level = ls_hierarchy_tab_2-parent_geo_level
**                       div = wa_knvv-spart
**                       cust_grp = wa_knvv-kvgr1.
**                      IF sy-subrc = 0.
**
**                        CASE ls_hierarchy_tab_1-geo_level .
**                          WHEN  'G7' .
**
**                            wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                            wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                            IF wa_final-zz1_lid_7_sdh IS INITIAL .
**                              wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**                          WHEN 'G6'.
**                            wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                            wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                            IF wa_final-zz1_lid_6_sdh IS INITIAL .
**                              wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**                          WHEN 'G5'.
**                            wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                            wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                            IF wa_final-zz1_lid_5_sdh IS INITIAL .
**                              wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**                          WHEN 'G4'.
**
**                            wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                            wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                            IF wa_final-zz1_lid_4_sdh IS INITIAL .
**                              wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**                          WHEN 'G3'.
**                            wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                            wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                            IF wa_final-zz1_lid_3_sdh IS INITIAL .
**                              wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**                          WHEN 'G2'.
**                            wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**
**                            wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**                            IF wa_final-zz1_lid_2_sdh IS INITIAL .
**                              wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**                          WHEN 'G1'.
**                            wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
**                            wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
**                            wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
**
**                            IF wa_final-zz1_lid_1_sdh IS INITIAL .
**                              wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_1-dummy_val.
**                            ENDIF.
**
**                          WHEN OTHERS.
**                        ENDCASE.
**                      ENDIF.
**                    ENDIF.
**                  ENDIF.
**                ENDIF.
**              ENDIF.
**            ENDIF.
**          ENDIF.
**        ENDIF.
**      ENDIF.
      READ TABLE lt_hierarchy_tab INTO DATA(ls_hierarchy_tab) WITH KEYgeo_code = wa_kna1-zz1_geo1_cus
    position_id = wa_kna1-zz1_posid1_cus
    div = wa_knvv-spart         "
    cust_grp = wa_knvv-kvgr1.
      "Added by bp
      "Link Position (from Hierarchy) to Person Number (from HRP1001)
      READ TABLE lt_hrp1001 INTO DATA(ls_rel) WITH KEY objid = ls_hierarchy_tab-position_id.
      IF sy-subrc = 0.
        DATA(lv_current_pernr) = ls_rel-sobid.

        READ TABLE lt_pa0105 INTO DATA(ls_mob) WITH KEY pernr = lv_current_pernr subty = 'CELL'.
        IF sy-subrc = 0.
**          wa_final-mobile = ls_mob-usrid.
        ENDIF.

        READ TABLE lt_pa0105 INTO DATA(ls_email) WITH KEY pernr = lv_current_pernr subty = '0030'.
        IF sy-subrc = 0.
**          wa_final-email_id = ls_email-usrid_long.
        ENDIF.
      ENDIF.

      """"""""""""""""""""""Ended by Archna
      READ TABLE it_t151t INTO DATA(wa_t151t) WITH KEY kdgrp = wa_knvv-kdgrp spras = 'E'."Added by Raj on 20.02.2025
      IF sy-subrc = 0.
        wa_final-kcdesc = wa_t151t-ktext.
      ENDIF.
      CLEAR : wa_t151t.

      READ TABLE it_tvv2t INTO DATA(wa_tvv2t) WITH KEY kvgr2 = wa_knvv-kvgr2 spras = 'E'.
      IF sy-subrc = 0.
        wa_final-kvgr2_desc = wa_tvv2t-bezei.
      ENDIF.
      CLEAR : wa_tvv2t.

      READ TABLE it_tvv1t INTO DATA(wa_tvv1t) WITH KEY kvgr1 = wa_knvv-kvgr1 spras = 'E'.
      IF sy-subrc = 0.
        wa_final-kvgr1_desc = wa_tvv1t-bezei.
      ENDIF.
      CLEAR : wa_tvv1t.



      wa_final-bzirk = wa_knvv-bzirk.
      wa_final-konda = wa_knvv-konda.
      wa_final-pltyp = wa_knvv-pltyp.
      wa_final-waers = wa_knvv-waers.
      wa_final-zterm = wa_knvv-zterm.
      wa_final-vkgrp = wa_knvv-vkgrp.
      wa_final-vkbur = wa_knvv-vkbur.
      wa_final-inco1 = wa_knvv-inco1.

      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JTC1'.
      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd_s WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JOSG'.
      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd_c WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JOCG'.
      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd_i WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JOIG'.
**********************Begin of changes Added by Raj on 01.03.2024**************
      IF wa_final-taxkd = '0'.
        wa_final-text = 'TCS APPLICABLE'.
      ELSE.
        wa_final-text = 'TCS NOT APPLICABLE'.
      ENDIF.
      IF wa_final-taxkd_s = '0'.
        wa_final-text_s = 'Registered'.
      ELSE.
        wa_final-text_s = 'Not Registered'.
      ENDIF.
      IF wa_final-taxkd_c = '0'.
        wa_final-text_c = 'Registered'.
      ELSE.
        wa_final-text_c = 'Not Registered'.
      ENDIF.
      IF wa_final-taxkd_i = '0'.
        wa_final-text_i = 'Registered'.
      ELSE.
        wa_final-text_i = 'Not Registered'.
      ENDIF.
*********************End of changes Added by Raj on 01.03.2024****************
***************** Added by Carina Jose on 08/07/2021
      CLEAR: wa_zone,wa_custemp,wa_knb1.
      READ TABLE it_knb1 INTO wa_knb1 WITH KEY kunnr = wa_knvv-kunnr.
      IF sy-subrc = 0.
        wa_final-ekvbd = wa_knb1-ekvbd.
        wa_final-bukrs = wa_knb1-bukrs.
        wa_final-akont = wa_knb1-akont.
      ENDIF.

* *******************Begin of changes Added by Raj on 15.09.2023******************
      IF wa_knb1 IS NOT INITIAL.
        READ TABLE it_knb5 INTO wa_knb5 WITH KEY kunnr = wa_knb1-kunnr bukrs = wa_knb1-bukrs.
        wa_final-mahna = wa_knb5-mahna.
      ENDIF.
********************End of changes Added by Raj on 15.09.2023*********************
********************Begin of changes Added by Raj on 25.11.2023******************
      IF wa_knvv IS NOT INITIAL.
        READ TABLE it_tvzbt INTO wa_tvzbt WITH KEY zterm = wa_knvv-zterm spras = 'EN'.
        IF wa_tvzbt IS NOT INITIAL.
          wa_final-pay_desc = wa_tvzbt-vtext.
        ENDIF.
      ENDIF.

      IF wa_knvv IS NOT INITIAL.
        READ TABLE it_tinct INTO wa_tinct WITH KEY inco1 = wa_knvv-inco1 spras = 'E'.
        IF wa_tinct IS NOT INITIAL.
          wa_final-bezei_desc = wa_tinct-bezei.
        ENDIF.
      ENDIF.


* *******************End of changes Added by Raj on 25.11.2023*********************
      IF wa_kna1-bbsnr IS NOT INITIAL.
        READ TABLE it_zone INTO wa_zone WITH KEY bukrs = wa_knb1-bukrs
                                                 zzone = wa_kna1-bbbnr.
        IF sy-subrc = 0.
          wa_final-zone = wa_zone-name.
        ELSE.
          wa_final-zone = 'wrongly maintain'.
        ENDIF.
        CLEAR: wa_zone.
        READ TABLE it_zone INTO wa_zone WITH KEY bukrs = wa_knb1-bukrs
                                                 zzone = wa_kna1-bbbnr
                                                 szone = wa_kna1-bbsnr.
        IF sy-subrc = 0.
          wa_final-szone = wa_zone-sname.
        ELSE.
          wa_final-szone = 'wrongly maintain'.
        ENDIF.
      ENDIF.

      LOOP AT it_custemp INTO wa_custemp WHERE kunnr = wa_knvv-kunnr.
*    READ TABLE it_custemp INTO wa_custemp WITH KEY kunnr = wa_knvv-kunnr.
        IF sy-subrc = 0.
          IF wa_custemp-startval <= sy-datum AND wa_custemp-endval >= sy-datum.
            IF wa_custemp-lcategory EQ 'L1'.
              wa_final-lcategory1 = wa_custemp-lcategory.
              wa_final-lname1     = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L2'.
              wa_final-lcategory2 = wa_custemp-lcategory.
              wa_final-lname2    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L3'.
              wa_final-lcategory3 = wa_custemp-lcategory.
              wa_final-lname3    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L4'.
              wa_final-lcategory4 = wa_custemp-lcategory.
              wa_final-lname4    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L5'.
              wa_final-lcategory5 = wa_custemp-lcategory.
              wa_final-lname5    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L6'.
              wa_final-lcategory6 = wa_custemp-lcategory.
              wa_final-lname6 = wa_custemp-lname.
            ENDIF.
          ENDIF.
        ENDIF.
        CLEAR : wa_custemp.
      ENDLOOP.
************ End of changes by Carina Jose on 13/07/2021
      READ TABLE it_knvp INTO wa_knvp WITH KEY kunnr = wa_knvv-kunnr
                                               vkorg = wa_knvv-vkorg
                                               vtweg = wa_knvv-vtweg
                                               spart = wa_knvv-spart.
      IF sy-subrc = 0.
        wa_final-kunn2 = wa_knvp-kunn2.
      ENDIF.
      READ TABLE it_dkna1 INTO wa_dkna1 WITH KEY kunnr = wa_knvp-kunn2.
      IF sy-subrc = 0.
        wa_final-dname1 = wa_dkna1-name1.
      ENDIF.

*    READ TABLE it_kna1 INTO wa_kna1 WITH KEY kunnr = wa_knvv-kunnr.

*    IF sy-subrc = 0.
      wa_final-anred = wa_kna1-anred.
      wa_final-ktokd = wa_kna1-ktokd.
      wa_final-kukla = wa_kna1-kukla.
      wa_final-land1 = wa_kna1-land1.
      wa_final-name1 = wa_kna1-name1.
      wa_final-name2 = wa_kna1-name2.
      wa_final-name3 = wa_kna1-name3.
      wa_final-name4 = wa_kna1-name4.
      wa_final-sortl = wa_kna1-sortl.
      wa_final-bu_sort2 = wa_kna1-bu_sort2.""added by shubham wani 28.07.2026
      wa_final-telf1 = wa_kna1-telf1.
*      wa_final-erdat = wa_kna1-erdat. ""COMMENTED BY AKSHAY DT.17.06.2025
      wa_final-ort02 = wa_kna1-ort02.
      wa_final-telf2 = wa_kna1-telf2.
      wa_final-stcd3 = wa_kna1-stcd3.
      wa_final-aufsd = wa_kna1-aufsd.
      wa_final-faksd = wa_kna1-faksd.    " Added by Raj on 23.05.2023
      wa_final-lifsd = wa_kna1-lifsd.    " Added by Raj on 23.05.2023
      wa_final-sperr = wa_kna1-sperr.    " Added by Shubham Wani on 28.07.2026 - Posting Block

      """"Added by Shubham Wani on 28.07.2026 - Credit Limit"""""""""

      READ TABLE it_ukmbp_cms_sgm INTO wa_ukmbp_cms_sgm WITH KEY partner = wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-credit_limit = wa_ukmbp_cms_sgm-credit_limit.
      ENDIF.
      """"ended by Shubham Wani on 28.07.2026 - Credit Limit""""""""

****------------------- ADDED BY AARTI KUMARI 15.05.2026 ------------------- ****

      IF wa_kna1-aufsd IS INITIAL.
        IF wa_final-vkorg = wa_knvv-vkorg AND wa_final-vtweg = wa_knvv-vtweg  AND wa_final-spart = wa_knvv-spart .

          wa_final-aufsd = wa_knvv-aufsd.

          " Get control block desc.
          SELECT SINGLE vtext
                FROM tvast
            INTO wa_final-vtext
            WHERE spras = sy-langu
          AND aufsp = wa_final-aufsd.

        ENDIF.
      ENDIF.
      IF wa_kna1-faksd IS INITIAL.
        IF wa_final-vkorg = wa_knvv-vkorg AND wa_final-vtweg = wa_knvv-vtweg  AND wa_final-spart = wa_knvv-spart .
          wa_final-faksd = wa_knvv-faksd.

          " Central billing block for customer .
          SELECT SINGLE vtext
             FROM tvfst
           INTO wa_final-vtext1
            WHERE spras = sy-langu
          AND   faksp = wa_final-faksd.
        ENDIF.
      ENDIF.
      IF wa_kna1-lifsd IS INITIAL.
        IF wa_final-vkorg = wa_knvv-vkorg AND wa_final-vtweg = wa_knvv-vtweg  AND wa_final-spart = wa_knvv-spart .
          wa_final-lifsd = wa_knvv-lifsd.
          " Central delivery block for the customer.
          SELECT SINGLE vtext
                        FROM tvlst
            INTO wa_final-vtext2
            WHERE spras = sy-langu
          AND   lifsp = wa_final-lifsd.

          wa_final-aufsd = wa_knvv-aufsd.
        ENDIF.
      ENDIF.
****------------------- ENDED BY AARTI KUMARI 15.05.2026 ------------------- ****
      wa_final-brsch =  wa_kna1-brsch.
      wa_final-bran1 = wa_kna1-bran1.
      wa_final-bahns = wa_kna1-bahns  .
      wa_final-bahne = wa_kna1-bahne.    " Added by Raj on 06.10.2023
      wa_final-stcd5 = wa_kna1-stcd5.    " Added by Raj on 06.10.2023
      wa_final-mp_code = wa_kna1-mp_code. "Added by Rutvi on 29.01.2025
      wa_final-mp_code_create_date = wa_kna1-mp_code_create_date. "Added by Rutvi on 29.01.2025
      wa_final-old_parent_code = wa_kna1-old_parent_code. "Added by Rutvi on 29.01.2025
      wa_final-remark_k = wa_kna1-remark. "Added by Rutvi on 29.01.2025
*    ENDIF.

      ""Start of change by Ranjan 31.01.2026

      wa_final-zz1_zzflag_t_cus = wa_kna1-zz1_zzflag_t_cus.
      wa_final-zz1_mp_code_cus = wa_kna1-zz1_mp_code_cus.
      wa_final-zz1_mp_code_create_dat_cus = wa_kna1-zz1_mp_code_create_dat_cus.
      wa_final-zz1_old_parent_code_cus = wa_kna1-zz1_old_parent_code_cus.
      wa_final-zz1_remark_cus = wa_kna1-zz1_remark_cus.
      wa_final-zz1_sp_code_cus = wa_kna1-zz1_sp_code_cus.
      wa_final-zz1_cf_indicator_cus = wa_kna1-zz1_cf_indicator_cus.
      wa_final-zz1_cf_valid_from_cus = wa_kna1-zz1_cf_valid_from_cus.
      wa_final-zz1_cf_valid_to_cus = wa_kna1-zz1_cf_valid_to_cus.
      wa_final-zz1_agreement_status_cus = wa_kna1-zz1_agreement_status_cus.
      wa_final-zz1_cheque_details_cus = wa_kna1-zz1_cheque_details_cus.
      wa_final-zz1_update_loyalty_sta_cus = wa_kna1-zz1_update_loyalty_sta_cus.
      wa_final-zz1_alp_flag_cus = wa_kna1-zz1_alp_flag_cus.
      wa_final-zz1_code_to_consider_cus = wa_kna1-zz1_code_to_consider_cus.
      wa_final-zz1_dms_tagging_cus = wa_kna1-zz1_dms_tagging_cus.
      wa_final-zz1_posid1_cus = wa_kna1-zz1_posid1_cus.
      wa_final-zz1_posid2_cus = wa_kna1-zz1_posid2_cus.
      wa_final-zz1_posid3_cus = wa_kna1-zz1_posid3_cus.
      wa_final-zz1_posid4_cus = wa_kna1-zz1_posid4_cus.
      wa_final-zz1_posid5_cus = wa_kna1-zz1_posid5_cus.
      wa_final-zz1_posid6_cus = wa_kna1-zz1_posid6_cus.
      wa_final-zz1_geo1_cus = wa_kna1-zz1_geo1_cus.
      wa_final-zz1_geo2_cus = wa_kna1-zz1_geo2_cus.
      wa_final-zz1_geo3_cus = wa_kna1-zz1_geo3_cus.
      wa_final-zz1_geo4_cus = wa_kna1-zz1_geo4_cus.
      wa_final-zz1_geo5_cus = wa_kna1-zz1_geo5_cus.
      wa_final-zz1_geo6_cus = wa_kna1-zz1_geo6_cus.
      wa_final-zz1_tax5_cus = wa_kna1-zz1_tax5_cus.
      wa_final-type = wa_kna1-type.
*      wa_final-zz1_tax5_cus = wa_kna1-zz1_tax5_cus.

      ""End of change by Ranjan 31.01.2026

      READ TABLE it_tvast INTO wa_tvast WITH KEY aufsp = wa_final-aufsd.
      IF  sy-subrc = 0.
        wa_final-vtext = wa_tvast-vtext.
      ENDIF.

******************************************Added by Raj on 23.05.2023***********************
      READ TABLE it_tvfst INTO wa_tvfst WITH KEY faksp = wa_final-faksd.
      IF  sy-subrc = 0.
        wa_final-vtext1 = wa_tvfst-vtext.
      ENDIF.

      READ TABLE it_tvlst INTO wa_tvlst WITH KEY lifsp = wa_final-lifsd.
      IF  sy-subrc = 0.
        wa_final-vtext2 = wa_tvlst-vtext.
      ENDIF.
******************************************Added by Raj on 23.05.2023***********************

* ******************************************Added by Raj on 12.02.2025***********************
      READ TABLE it_t077x INTO DATA(wa_t077x) WITH KEY ktokd = wa_final-ktokd.
      IF  sy-subrc = 0.
        wa_final-kdesc = wa_t077x-txt30.
      ENDIF.

******************************************Added by Raj on 12.02.2025***********************

      READ TABLE it_adrc INTO wa_adrc WITH KEY  addrnumber = wa_kna1-adrnr.
      IF sy-subrc = 0.
        wa_final-city1       = wa_adrc-city1.
        wa_final-city2       = wa_adrc-city2.
        wa_final-post_code1  = wa_adrc-post_code1.
        wa_final-street      = wa_adrc-street.
        wa_final-str_suppl1  = wa_adrc-str_suppl1.
        wa_final-str_suppl2  = wa_adrc-str_suppl2 .
        wa_final-str_suppl3  = wa_adrc-str_suppl3.
        wa_final-langu       = wa_adrc-langu.
        wa_final-region      = wa_adrc-region.
        wa_final-mc_name1    = wa_adrc-mc_name1.
        wa_final-extension1  = wa_adrc-extension1.
        wa_final-extension2  = wa_adrc-extension2.
      ENDIF.
      READ TABLE it_ext INTO DATA(ls_ext) WITH KEY kunnr = wa_kna1-kunnr.
      IF sy-subrc = 0.
        IF wa_final-extension1 IS INITIAL.
          wa_final-extension1  = ls_ext-extension1.
        ENDIF.
        IF wa_final-extension2 IS INITIAL.
          wa_final-extension2  = ls_ext-extension2.
        ENDIF.
      ENDIF.

      READ TABLE it_adr6 INTO wa_adr6 WITH KEY  addrnumber = wa_kna1-adrnr.
      IF sy-subrc = 0.
        wa_final-email = wa_adr6-smtp_addr.
      ENDIF.

      READ TABLE it_adrct INTO wa_adrct WITH KEY  addrnumber = wa_kna1-adrnr.
      IF sy-subrc = 0.
        wa_final-remark = wa_adrct-remark.
      ENDIF.

*    READ TABLE it_knkk INTO wa_knkk WITH KEY kunnr = wa_knvv-kunnr.
*    IF sy-subrc = 0.
*      wa_final-kkber = wa_knkk-kkber.
*      wa_final-klimk = wa_knkk-klimk.
*      wa_final-knkli = wa_knkk-knkli.
*      wa_final-sauft = wa_knkk-sauft.
*      wa_final-skfor = wa_knkk-skfor.
*      wa_final-uedat = wa_knkk-uedat.
*      wa_final-ctlpc = wa_knkk-ctlpc.
*    ENDIF.

*    READ TABLE it_pkna1 INTO wa_pkna1 WITH KEY kunnr = wa_final-knkli.
*    IF sy-subrc = 0.
*      wa_final-perdat = wa_pkna1-erdat.
*    ENDIF.
*
*    READ TABLE it_t014 INTO wa_t014 WITH KEY kkber = wa_knkk-kkber.
*    IF  sy-subrc = 0.
*      wa_final-waers002 = wa_t014-waers.
*    ENDIF.

      READ TABLE it_j_1imocust INTO wa_j_1imocust WITH KEY kunnr = wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-panno = wa_j_1imocust-j_1ipanno.
      ENDIF.
*    SHIFT wa_final-kunnr LEFT DELETING LEADING '0'.
*    SHIFT wa_final-knkli LEFT DELETING LEADING '0'.

*********************"Added by Raj on 26.03.2024*************************************
      READ TABLE it_knvl INTO DATA(wa_knvl) WITH KEY kunnr = wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-licnr = wa_knvl-licnr.
        wa_final-datab = wa_knvl-datab.
        wa_final-datbi = wa_knvl-datbi.
        wa_final-belic = wa_knvl-belic.
      ENDIF.
********************"Added by Raj on 26.03.2024**************************************
      READ TABLE it_tvk1t INTO DATA(wa_tvk1t) WITH KEY katr1 = wa_kna1-katr1 spras = 'EN'."Added by Raj on 23.08.2024
      IF sy-subrc = 0.
        wa_final-katr1 = wa_tvk1t-vtext.
      ENDIF.

      APPEND wa_final TO it_final.
      CLEAR : wa_final,wa_knvv,wa_adrc,wa_knkk,wa_t014,wa_j_1imocust,wa_adr6,wa_pkna1,wa_tvast,wa_dkna1,wa_knvp,wa_adrct,wa_knb1,wa_knb5,wa_tvzbt,wa_knvl,wa_tvk1t, wa_ukmbp_cms_sgm.
    ENDLOOP.
    IF sy-subrc = '4'.
      READ TABLE it_knvv INTO wa_knvv WITH KEY kunnr = wa_kna1-kunnr.
*    LOOP AT it_knvv INTO wa_knvv WHERE kunnr = wa_kna1-kunnr.
      wa_final-kunnr = wa_knvv-kunnr.
      wa_final-vkorg = wa_knvv-vkorg.
      wa_final-vtweg = wa_knvv-vtweg.
      wa_final-spart = wa_knvv-spart.
      wa_final-kalks = wa_knvv-kalks.
      wa_final-kdgrp = wa_knvv-kdgrp.
      wa_final-erdat = wa_knvv-erdat.

      READ TABLE it_t151t INTO wa_t151t WITH KEY kdgrp = wa_knvv-kdgrp spras = 'E'.
      IF sy-subrc = 0.
        wa_final-kcdesc = wa_t151t-ktext.
      ENDIF.
      CLEAR : wa_t151t.



      wa_final-bzirk = wa_knvv-bzirk.
      wa_final-konda = wa_knvv-konda.
      wa_final-pltyp = wa_knvv-pltyp.
      wa_final-waers = wa_knvv-waers.
      wa_final-zterm = wa_knvv-zterm.
      wa_final-vkgrp = wa_knvv-vkgrp.
      wa_final-vkbur = wa_knvv-vkbur.
      wa_final-inco1 = wa_knvv-inco1.


      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JTC1'.
      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd_s WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JOSG'.
      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd_c WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JOCG'.
      SELECT SINGLE taxkd FROM knvi INTO wa_final-taxkd_i WHERE kunnr EQ wa_final-kunnr AND aland EQ lv_country AND tatyp EQ 'JOIG'.
**********************Begin of changes Added by Raj on 01.03.2024**************
      IF wa_final-taxkd = '0'.
        wa_final-text = 'TCS APPLICABLE'.
      ELSE.
        wa_final-text = 'TCS NOT APPLICABLE'.
      ENDIF.
      IF wa_final-taxkd_s = '0'.
        wa_final-text_s = 'Registered'.
      ELSE.
        wa_final-text_s = 'Not Registered'.
      ENDIF.
      IF wa_final-taxkd_c = '0'.
        wa_final-text_c = 'Registered'.
      ELSE.
        wa_final-text_c = 'Not Registered'.
      ENDIF.
      IF wa_final-taxkd_i = '0'.
        wa_final-text_i = 'Registered'.
      ELSE.
        wa_final-text_i = 'Not Registered'.
      ENDIF.
*********************End of changes Added by Raj on 01.03.2024****************


***************** Added by Carina Jose on 08/07/2021
      CLEAR: wa_zone,wa_custemp,wa_knb1.
      READ TABLE it_knb1 INTO wa_knb1 WITH KEY kunnr = wa_knvv-kunnr.
      IF sy-subrc = 0.
        wa_final-ekvbd = wa_knb1-ekvbd.
      ENDIF.

*      ********************Begin of changes Added by Raj on 25.11.2023******************
      IF wa_knvv IS NOT INITIAL.
        READ TABLE it_tvzbt INTO wa_tvzbt WITH KEY zterm = wa_knvv-zterm spras = 'EN'.
        IF wa_tvzbt IS NOT INITIAL.
          wa_final-pay_desc = wa_tvzbt-vtext.
        ENDIF.
      ENDIF.

* *******************End of changes Added by Raj on 25.11.2023*********************




      IF wa_kna1-bbsnr IS NOT INITIAL.
        READ TABLE it_zone INTO wa_zone WITH KEY bukrs = wa_knb1-bukrs
                                                 zzone = wa_kna1-bbbnr.
        IF sy-subrc = 0.
          wa_final-zone = wa_zone-name.
        ELSE.
          wa_final-zone = 'wrongly maintain'.
        ENDIF.
        CLEAR: wa_zone.
        READ TABLE it_zone INTO wa_zone WITH KEY bukrs = wa_knb1-bukrs
                                                 zzone = wa_kna1-bbbnr
                                                 szone = wa_kna1-bbsnr.
        IF sy-subrc = 0.
          wa_final-szone = wa_zone-sname.
        ELSE.
          wa_final-szone = 'wrongly maintain'.
        ENDIF.
      ENDIF.

      LOOP AT it_custemp INTO wa_custemp WHERE kunnr = wa_knvv-kunnr.
*    READ TABLE it_custemp INTO wa_custemp WITH KEY kunnr = wa_knvv-kunnr.
        IF sy-subrc = 0.
          IF wa_custemp-startval <= sy-datum AND wa_custemp-endval >= sy-datum.
            IF wa_custemp-lcategory EQ 'L1'.
              wa_final-lcategory1 = wa_custemp-lcategory.
              wa_final-lname1     = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L2'.
              wa_final-lcategory2 = wa_custemp-lcategory.
              wa_final-lname2    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L3'.
              wa_final-lcategory3 = wa_custemp-lcategory.
              wa_final-lname3    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L4'.
              wa_final-lcategory4 = wa_custemp-lcategory.
              wa_final-lname4    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L5'.
              wa_final-lcategory5 = wa_custemp-lcategory.
              wa_final-lname5    = wa_custemp-lname.
            ENDIF.
            IF wa_custemp-lcategory EQ 'L6'.
              wa_final-lcategory6 = wa_custemp-lcategory.
              wa_final-lname6 = wa_custemp-lname.
            ENDIF.
          ENDIF.
        ENDIF.
        CLEAR : wa_custemp.
      ENDLOOP.
************ End of changes by Carina Jose on 13/07/2021
      READ TABLE it_knvp INTO wa_knvp WITH KEY kunnr = wa_knvv-kunnr
                                               vkorg = wa_knvv-vkorg
                                               vtweg = wa_knvv-vtweg
                                               spart = wa_knvv-spart.
      IF sy-subrc = 0.
        wa_final-kunn2 = wa_knvp-kunn2.
      ENDIF.
      READ TABLE it_dkna1 INTO wa_dkna1 WITH KEY kunnr = wa_knvp-kunn2.
      IF sy-subrc = 0.
        wa_final-dname1 = wa_dkna1-name1.
      ENDIF.

*    READ TABLE it_kna1 INTO wa_kna1 WITH KEY kunnr = wa_knvv-kunnr.

*    IF sy-subrc = 0.
      wa_final-anred = wa_kna1-anred.
      wa_final-ktokd = wa_kna1-ktokd.
      wa_final-kukla = wa_kna1-kukla.
      wa_final-land1 = wa_kna1-land1.
      wa_final-name1 = wa_kna1-name1.
      wa_final-name2 = wa_kna1-name2.
      wa_final-name3 = wa_kna1-name3.
      wa_final-name4 = wa_kna1-name4.
      wa_final-sortl = wa_kna1-sortl.
      wa_final-telf1 = wa_kna1-telf1.
*      wa_final-erdat = wa_kna1-erdat. """COMMENTED BY AKSHAY DT.17.06.2025
      wa_final-ort02 = wa_kna1-ort02.
      wa_final-telf2 = wa_kna1-telf2.
      wa_final-stcd3 = wa_kna1-stcd3.
      wa_final-aufsd = wa_kna1-aufsd.
      wa_final-brsch =  wa_kna1-brsch.
      wa_final-bran1 = wa_kna1-bran1.
      wa_final-bahns  = wa_kna1-bahns.
*    ENDIF.

      READ TABLE it_tvast INTO wa_tvast WITH KEY aufsp = wa_final-aufsd.
      IF  sy-subrc = 0.
        wa_final-vtext = wa_tvast-vtext.
      ENDIF.

      READ TABLE it_adrc INTO wa_adrc WITH KEY  addrnumber = wa_kna1-adrnr.
      IF sy-subrc = 0.
        wa_final-city1       = wa_adrc-city1.
        wa_final-city2       = wa_adrc-city2.
        wa_final-post_code1  = wa_adrc-post_code1.
        wa_final-street      = wa_adrc-street.
        wa_final-str_suppl1  = wa_adrc-str_suppl1.
        wa_final-str_suppl2  = wa_adrc-str_suppl2 .
        wa_final-str_suppl3  = wa_adrc-str_suppl3.
        wa_final-langu       = wa_adrc-langu.
        wa_final-region      = wa_adrc-region.
        wa_final-mc_name1    = wa_adrc-mc_name1.
        wa_final-extension1  = wa_adrc-extension1.
        wa_final-extension2  = wa_adrc-extension2.
      ENDIF.

      READ TABLE it_adr6 INTO wa_adr6 WITH KEY  addrnumber = wa_kna1-adrnr.
      IF sy-subrc = 0.
        wa_final-email = wa_adr6-smtp_addr.
      ENDIF.

      READ TABLE it_adrct INTO wa_adrct WITH KEY  addrnumber = wa_kna1-adrnr.
      IF sy-subrc = 0.
        wa_final-remark = wa_adrct-remark.
      ENDIF.

*    READ TABLE it_knkk INTO wa_knkk WITH KEY kunnr = wa_knvv-kunnr.
*    IF sy-subrc = 0.
*      wa_final-kkber = wa_knkk-kkber.
*      wa_final-klimk = wa_knkk-klimk.
*      wa_final-knkli = wa_knkk-knkli.
*      wa_final-sauft = wa_knkk-sauft.
*      wa_final-skfor = wa_knkk-skfor.
*      wa_final-uedat = wa_knkk-uedat.
*      wa_final-ctlpc = wa_knkk-ctlpc.
*    ENDIF.

*    READ TABLE it_pkna1 INTO wa_pkna1 WITH KEY kunnr = wa_final-knkli.
*    IF sy-subrc = 0.
*      wa_final-perdat = wa_pkna1-erdat.
*    ENDIF.
*
*    READ TABLE it_t014 INTO wa_t014 WITH KEY kkber = wa_knkk-kkber.
*    IF  sy-subrc = 0.
*      wa_final-waers002 = wa_t014-waers.
*    ENDIF.

      READ TABLE it_j_1imocust INTO wa_j_1imocust WITH KEY kunnr = wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-panno = wa_j_1imocust-j_1ipanno.
      ENDIF.
*    SHIFT wa_final-kunnr LEFT DELETING LEADING '0'.
*    SHIFT wa_final-knkli LEFT DELETING LEADING '0'.

**********************"Added by Raj on 26.03.2024*************************************
      READ TABLE it_knvl INTO wa_knvl WITH KEY kunnr = wa_kna1-kunnr.
      IF sy-subrc = 0.
        wa_final-licnr = wa_knvl-licnr.
        wa_final-datab = wa_knvl-datab.
        wa_final-datbi = wa_knvl-datbi.
        wa_final-belic = wa_knvl-belic.
      ENDIF.
********************"Added by Raj on 26.03.2024**************************************
      READ TABLE it_tvk1t INTO wa_tvk1t WITH KEY katr1 = wa_kna1-katr1 spras = 'EN'."Added by Raj on 23.08.2024
      IF sy-subrc = 0.
        wa_final-katr1 = wa_tvk1t-vtext.
      ENDIF.


      READ TABLE it_t077x INTO wa_t077x WITH KEY ktokd = wa_final-ktokd."Added by Raj on 12.02.2025
      IF  sy-subrc = 0.
        wa_final-kdesc = wa_t077x-txt30.
      ENDIF.

**      Start change by Archna Gupta on 11.03.2026

*      LOOP AT it_knvv ASSIGNING FIELD-SYMBOL(<ls_knvv>).
*
*        READ TABLE it_kna1 ASSIGNING FIELD-SYMBOL(<ls_kna1>)
*             WITH KEY kunnr = <ls_knvv>-kunnr
*             BINARY SEARCH.
*        IF sy-subrc <> 0.
*          CONTINUE. " KNA1 nahi mila; skip or handle
*        ENDIF.
*        READ TABLE lt_hierarchy_tab INTO DATA(ls_hierarchy_tab) WITH KEY  geo_code = <ls_kna1>-zz1_geo1_cus
*   position_id = <ls_kna1>-zz1_posid1_cus
*    div = <ls_knvv>-spart
*    cust_grp = <ls_knvv>-kvgr1.
*        IF sy-subrc = 0.
*          CASE ls_hierarchy_tab-geo_level .
*            WHEN  'G7' .
*              wa_Final-zz1_gid_7_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_7_sdh IS INITIAL .
*                wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab-dummy_val.
*              ENDIF.
*
*            WHEN 'G6'.
*              wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_6_sdh IS INITIAL .
*                wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab-dummy_val.
*              ENDIF.
















*          ENDCASE.
*        ENDIF.  WHEN OTHERS.


**      ENDLOOP.

**      End of change by Archna Gupta on 11.03.2026


      APPEND wa_final TO it_final.
      CLEAR : wa_final,wa_knvv,wa_kna1,wa_adrc,wa_knkk,wa_t014,wa_j_1imocust,wa_adr6,wa_pkna1,wa_tvast,wa_dkna1,wa_knvp,wa_adrct,wa_knb1,wa_tvzbt,wa_knvl,wa_tvk1t, wa_ukmbp_cms_sgm.
    ENDIF.
  ENDLOOP.

**********Start by Archna Gupta **
*  LOOP AT it_kna1 INTO wa_kna1.
*    IF sy-subrc IS INITIAL.
*      DATA(lv_zz1_geo1_cus) = CONV char8( wa_kna1-zz1_geo1_cus ).
*    ENDIF.
*    READ TABLE IT_KNVV INTO WA_KNVV WITH KEY KUNNR =  wa_kna1-kunnr.
*      IF SY-SUBRC = 0.
*    READ TABLE lt_hierarchy_tab INTO DATA(ls_hierarchy_tab) WITH KEY  geo_code = wa_kna1-zz1_geo1_cus
*                                                                      position_id = wa_kna1-zz1_posid1_cus
*                                                                      div = wa_knvv-spart         "
*                                                                      cust_grp = wa_knvv-kvgr1.
*
*    IF sy-subrc = 0.
*      CASE ls_hierarchy_tab-geo_level .
*        WHEN  'G7' .
*          wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_7_sdh IS INITIAL .
*            wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*
*        WHEN 'G6'.
*          wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_6_sdh IS INITIAL .
*            wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*
*        WHEN 'G5'.
*          wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_5_sdh IS INITIAL .
*            wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*
*        WHEN 'G4'.
*          wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_4_sdh IS INITIAL .
*            wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*
*        WHEN 'G3'.
*          wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_3_sdh IS INITIAL .
*            wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*        WHEN 'G2'.
*          wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_2_sdh IS INITIAL .
*            wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*        WHEN 'G1'.
*          wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab-geo_code."is_vbak-zz1_gid_7_sdh.
*          wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab-position_id. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab-geo_desc. "is_vbak-zz1_lid_7_sdh.
*          wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab-posid_desc. "is_vbak-zz1_lid_7_sdh.
*          IF wa_final-zz1_lid_1_sdh IS INITIAL .
*            wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab-dummy_val.
*          ENDIF.
*        WHEN OTHERS.
*      ENDCASE.
*      READ TABLE lt_hierarchy_tab
*                 INTO DATA(ls_hierarchy_tab_6)
*                 WITH  KEY  geo_level = ls_hierarchy_tab-parent_geo_level
*                     div = wa_knvv-spart
*                     cust_grp = wa_knvv-kvgr1.
*      IF sy-subrc = 0.
*        CASE ls_hierarchy_tab_6-geo_level .
*          WHEN  'G7' .
*            wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_7_sdh IS INITIAL .
*              wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*          WHEN 'G6'.
*            wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_6_sdh IS INITIAL .
*              wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*          WHEN 'G5'.
*            wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*
*            wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_5_sdh IS INITIAL .
*              wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*          WHEN 'G4'.
*
*            wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*
*            wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_4_sdh IS INITIAL .
*              wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*          WHEN 'G3'.
*            wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*
*            wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_3_sdh IS INITIAL .
*              wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*
*          WHEN 'G2'.
*            wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*
*            wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_2_sdh IS INITIAL .
*              wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*          WHEN 'G1'.
*            wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_6-geo_code."is_vbak-zz1_gid_7_sdh.
*            wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_6-position_id. "is_vbak-zz1_lid_7_sdh.
*
*            wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_6-geo_desc. "is_vbak-zz1_lid_7_sdh.
*            wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_6-posid_desc. "is_vbak-zz1_lid_7_sdh.
*            IF wa_final-zz1_lid_1_sdh IS INITIAL .
*              wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_6-dummy_val.
*            ENDIF.
*
*          WHEN OTHERS.
*        ENDCASE.
*        READ TABLE lt_hierarchy_tab
*         INTO DATA(ls_hierarchy_tab_5)
*          WITH  KEY  geo_level = ls_hierarchy_tab_6-parent_geo_level
*              div = wa_knvv-spart
*              cust_grp = wa_knvv-kvgr1.
*        IF sy-subrc = 0.
*          CASE ls_hierarchy_tab_5-geo_level .
*            WHEN  'G7' .
*
*              wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_7_sdh IS INITIAL .
*                wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN 'G6'.
*              wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_6_sdh IS INITIAL .
*                wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN 'G5'.
*              wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_5_sdh IS INITIAL .
*                wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN 'G4'.
*
*              wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_4_sdh IS INITIAL .
*                wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN 'G3'.
*              wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_3_sdh IS INITIAL .
*                wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN 'G2'.
*              wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_2_sdh IS INITIAL .
*                wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN 'G1'.
*              wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_5-geo_code."is_vbak-zz1_gid_7_sdh.
*              wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_5-position_id. "is_vbak-zz1_lid_7_sdh.
*
*              wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_5-geo_desc. "is_vbak-zz1_lid_7_sdh.
*              wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_5-posid_desc. "is_vbak-zz1_lid_7_sdh.
*              IF wa_final-zz1_lid_1_sdh IS INITIAL .
*                wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_5-dummy_val.
*              ENDIF.
*            WHEN OTHERS.
*          ENDCASE.
*          "STEP4
*          READ TABLE lt_hierarchy_tab
*             INTO DATA(ls_hierarchy_tab_4)
*             WITH  KEY  geo_level = ls_hierarchy_tab_5-parent_geo_level
*                 div = wa_knvv-spart
*                 cust_grp = wa_knvv-kvgr1.
*          IF sy-subrc = 0.
*
*            CASE ls_hierarchy_tab_4-geo_level .
*              WHEN  'G7' .
*
*                wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_7_sdh IS INITIAL .
*                  wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*              WHEN 'G6'.
*                wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_6_sdh IS INITIAL .
*                  wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*              WHEN 'G5'.
*                wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_5_sdh IS INITIAL .
*                  wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*              WHEN 'G4'.
*
*                wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_4_sdh IS INITIAL .
*                  wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*              WHEN 'G3'.
*                wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_3_sdh IS INITIAL .
*                  wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*              WHEN 'G2'.
*                wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_2_sdh IS INITIAL .
*                  wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*              WHEN 'G1'.
*                wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_4-geo_code."is_vbak-zz1_gid_7_sdh.
*                wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_4-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_4-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_4-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                IF wa_final-zz1_lid_1_sdh IS INITIAL .
*                  wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_4-dummy_val.
*                ENDIF.
*
*              WHEN OTHERS.
*            ENDCASE.
*
*            "step 3
*            READ TABLE lt_hierarchy_tab
*               INTO DATA(ls_hierarchy_tab_3)
*               WITH  KEY  geo_level = ls_hierarchy_tab_4-parent_geo_level
*                   div = wa_knvv-spart
*                   cust_grp = wa_knvv-kvgr1.
*            IF sy-subrc = 0.
*              CASE ls_hierarchy_tab_3-geo_level .
*                WHEN  'G7' .
*
*                  wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_7_sdh IS INITIAL .
*                    wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*                WHEN 'G6'.
*                  wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_6_sdh IS INITIAL .
*                    wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*                WHEN 'G5'.
*                  wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_5_sdh IS INITIAL .
*                    wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*                WHEN 'G4'.
*
*                  wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_4_sdh IS INITIAL .
*                    wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*                WHEN 'G3'.
*                  wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_3_sdh IS INITIAL .
*                    wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*                WHEN 'G2'.
*                  wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_2_sdh IS INITIAL .
*                    wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*                WHEN 'G1'.
*                  wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_3-geo_code."is_vbak-zz1_gid_7_sdh.
*                  wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_3-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                  wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_3-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                  wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_3-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                  IF wa_final-zz1_lid_1_sdh IS INITIAL .
*                    wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_3-dummy_val.
*                  ENDIF.
*
*                WHEN OTHERS.
*              ENDCASE.
*
*              "step 2
*              READ TABLE lt_hierarchy_tab
*                 INTO DATA(ls_hierarchy_tab_2)
*                 WITH  KEY  geo_level = ls_hierarchy_tab_3-parent_geo_level
*                     div = wa_knvv-spart
*                     cust_grp = wa_knvv-kvgr1.
*              IF sy-subrc = 0.
*
*                CASE ls_hierarchy_tab_2-geo_level .
*                  WHEN  'G7' .
*
*                    wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_7_sdh IS INITIAL .
*                      wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN 'G6'.
*                    wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_6_sdh IS INITIAL .
*                      wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN 'G5'.
*                    wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_5_sdh IS INITIAL .
*                      wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN 'G4'.
*
*                    wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_4_sdh IS INITIAL .
*                      wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN 'G3'.
*                    wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_3_sdh IS INITIAL .
*                      wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN 'G2'.
*                    wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_2_sdh IS INITIAL .
*                      wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN 'G1'.
*                    wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_2-geo_code."is_vbak-zz1_gid_7_sdh.
*                    wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_2-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                    wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_2-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                    wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_2-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                    IF wa_final-zz1_lid_1_sdh IS INITIAL .
*                      wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_2-dummy_val.
*                    ENDIF.
*                  WHEN OTHERS.
*                ENDCASE.
*                "step 1
*                READ TABLE lt_hierarchy_tab
*            INTO DATA(ls_hierarchy_tab_1)
*             WITH  KEY  geo_level = ls_hierarchy_tab_2-parent_geo_level
*                 div = wa_knvv-spart
*                 cust_grp = wa_knvv-kvgr1.
*                IF sy-subrc = 0.
*
*                  CASE ls_hierarchy_tab_1-geo_level .
*                    WHEN  'G7' .
*
*                      wa_final-zz1_gid_7_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                      wa_final-zz1_g7_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l7_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                      IF wa_final-zz1_lid_7_sdh IS INITIAL .
*                        wa_final-zz1_lid_7_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*                    WHEN 'G6'.
*                      wa_final-zz1_gid_6_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                      wa_final-zz1_g6_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l6_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                      IF wa_final-zz1_lid_6_sdh IS INITIAL .
*                        wa_final-zz1_lid_6_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*                    WHEN 'G5'.
*                      wa_final-zz1_gid_5_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                      wa_final-zz1_g5_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l5_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                      IF wa_final-zz1_lid_5_sdh IS INITIAL .
*                        wa_final-zz1_lid_5_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*                    WHEN 'G4'.
*
*                      wa_final-zz1_gid_4_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                      wa_final-zz1_g4_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l4_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                      IF wa_final-zz1_lid_4_sdh IS INITIAL .
*                        wa_final-zz1_lid_4_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*                    WHEN 'G3'.
*                      wa_final-zz1_gid_3_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                      wa_final-zz1_g3_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l3_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                      IF wa_final-zz1_lid_3_sdh IS INITIAL .
*                        wa_final-zz1_lid_3_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*                    WHEN 'G2'.
*                      wa_final-zz1_gid_2_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*
*                      wa_final-zz1_g2_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l2_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*                      IF wa_final-zz1_lid_2_sdh IS INITIAL .
*                        wa_final-zz1_lid_2_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*                    WHEN 'G1'.
*                      wa_final-zz1_gid_1_sdh    =  ls_hierarchy_tab_1-geo_code."is_vbak-zz1_gid_7_sdh.
*                      wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_1-position_id. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_g1_d_sdh    = ls_hierarchy_tab_1-geo_desc. "is_vbak-zz1_lid_7_sdh.
*                      wa_final-zz1_l1_d_sdh    = ls_hierarchy_tab_1-posid_desc. "is_vbak-zz1_lid_7_sdh.
*
*                      IF wa_final-zz1_lid_1_sdh IS INITIAL .
*                        wa_final-zz1_lid_1_sdh    = ls_hierarchy_tab_1-dummy_val.
*                      ENDIF.
*
*                    WHEN OTHERS.
*                  ENDCASE.
*                ENDIF.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*     ENDIF.
*    append wa_final to it_final.
*
*    "clear: wa_final.
*
*    ENDLOOP.
  "ENDLOOP.
  "endloop.
  "ENDIF.
  """""""""""""""""""Ended by archna Gupta


  LOOP AT it_final INTO wa_final.
    MOVE-CORRESPONDING wa_final TO  wa_final1.

    SELECT SINGLE bezei FROM tvgrt INTO wa_final1-vkdes WHERE spras = 'EN' AND vkgrp = wa_final1-vkgrp.
    SELECT SINGLE bezei FROM tvkbt INTO wa_final1-vdesc WHERE spras = 'EN' AND vkbur = wa_final1-vkbur.
    SELECT SINGLE bztxt FROM t171t INTO wa_final1-bzdes WHERE spras = 'EN' AND bzirk = wa_final1-bzirk.
*
*    LOOP AT it_knkk INTO wa_knkk WHERE kunnr = wa_final1-kunnr.
*      wa_final1-kkber = wa_knkk-kkber.
*      wa_final1-klimk = wa_knkk-klimk.
*      wa_final1-knkli = wa_knkk-knkli.
*      wa_final1-sauft = wa_knkk-sauft.
*      wa_final1-skfor = wa_knkk-skfor.
*      wa_final1-uedat = wa_knkk-uedat.
*      wa_final1-ctlpc = wa_knkk-ctlpc.
*
*      READ TABLE it_pkna1 INTO wa_pkna1 WITH KEY kunnr = wa_final1-knkli.
*      IF sy-subrc = 0.
*        wa_final1-perdat = wa_pkna1-erdat.
*      ENDIF.
*
*      READ TABLE it_t014 INTO wa_t014 WITH KEY kkber = wa_knkk-kkber.
*      IF  sy-subrc = 0.
*        wa_final1-waers002 = wa_t014-waers.
*      ENDIF.
*
*      SHIFT wa_final1-kunnr LEFT DELETING LEADING '0'.
*      SHIFT wa_final1-knkli LEFT DELETING LEADING '0'.
*      SHIFT wa_final1-ekvbd LEFT DELETING LEADING '0'.
*
*      CLEAR : wa_final1,wa_knkk,wa_t014,wa_pkna1.
*    ENDLOOP.
    APPEND wa_final1 TO it_final1.
    CLEAR : wa_final1.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FILL_FIELDCATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_fieldcatalog .
  PERFORM fieldcat_append  USING  'KUNNR'               'Customer'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'PARTNER'             'Partner'         'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ERDAT'               'Created On'            'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KNKLI'               'Parent Customer code'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'PERDAT'               'Parent Cust. Creation Date'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VKORG'               'SOrg.'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VTWEG'               'DChl.'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'SPART'               'Division'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ANRED'               'Title'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KTOKD'               'Group'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KUKLA'               'Customer Classification'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LAND1'               'Country'         'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'NAME1'               'Name1'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'NAME2'               'Name2'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'NAME3'               'Name3'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'NAME4'               'Name4'       'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'SORTL'               'Search Term'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'BU_SORT2'            'Search Term 2'               'X'  'IT_FINAL1'. ""added by shubham wani on 28.07.2026
  PERFORM fieldcat_append  USING  'KDGRP'               'Customer Group'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KALKS'               'Cust.pric.procedure'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KONDA'               'Price group'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'PLTYP'               'Price List'            'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'WAERS'               'Currency'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VKGRP'               'Sales Group'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VKDES'               'Sales Grp Desc.'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'STREET'              'Street'        'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'STR_SUPPL1'          'Street 2'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'STR_SUPPL2'          'Street 3'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'STR_SUPPL3'          'Street 4'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'STR_SUPPL3'          'Street 4'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'CITY1'               'City'      'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'CITY2'               'District'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'REGION'              'Region'        'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LANGU'               'Language'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'MC_NAME1'            'Name'      'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KKBER'               'Credit ControlArea'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'EKVBD'               'Buying group'              'X'  'IT_FINAL1'   .

************  Added by Carina Jose on 08.07.2021
  PERFORM fieldcat_append  USING  'LCATEGORY6'               'L6'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'LNAME6'               'L6 Name'            'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LCATEGORY5'               'L5'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'LNAME5'               'L5 Name'            'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'LCATEGORY4'               'L4'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'LNAME4'               'L4 Name'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'LCATEGORY3'               'L3'           'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LNAME3'               'L3 Name'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'LCATEGORY2'               'L2'          'X '  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LNAME2'               'L2 Name'            'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LCATEGORY1'               'L1'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'LNAME1'               'L1 Name'            'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZONE'              'Zone'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'SZONE'              'Sub Zone'                 'X'  'IT_FINAL1'   .
************  End of changes on .07.2021

  LOOP AT lt_acc_key1 INTO lwa_acc_key1.
    IF sy-uname = lwa_acc_key1-low.
      PERFORM fieldcat_append  USING  'KLIMK'               'Credit Limit'                'X'  'IT_FINAL1'   .
      PERFORM fieldcat_append  USING  'WAERS002'            'Currency'              'X'  'IT_FINAL1'   .
      PERFORM fieldcat_append  USING  'CTLPC'               'Risk category'                'X'  'IT_FINAL1'   .
      PERFORM fieldcat_append  USING  'SKFOR'               'Total Receivables'                'X'  'IT_FINAL1'   .
**      PERFORM fieldcat_append  USING  'WAERS002'            'Currency'                'X'  'IT_FINAL1'   .
    ENDIF.
  ENDLOOP.
*  PERFORM fieldcat_append  USING  'KNKLI'               'Credit Account'                'X'  'IT_FINAL'   .
*  PERFORM fieldcat_append  USING  'SAUFT'               'Sales Value'              'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'WAERS002'            'Currency'          'X'  'IT_FINAL1'   .

  PERFORM fieldcat_append  USING  'UEDAT'               'Exceeded on'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'STCD3'               'GST No.'         'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'PANNO'               'PAN No.'         'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'EMAIL'               'E-Mail Address'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'TELF1'               'Telephone 1'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'TELF2'               'Telephone 2'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'POST_CODE1'          'Postal Code'             'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'BZIRK'               'Sales District'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'BZDES'               'Sales Dist. Desc.'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VKBUR'               'Sales Office'              'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VDESC'               'Sales Off. Desc.'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'AUFSD'               'Central Order Block'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VTEXT'               'Central Order Block Desc.'                'X'  'IT_FINAL1'   .
*  ******************************************************************Added by Raj on 23.02.2023***********
  PERFORM fieldcat_append  USING  'FAKSD'               'Central billing block '                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'VTEXT1'               'Central billing block Desc'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'LIFSD'               'Central delivery block'                'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'VTEXT2'               'Central delivery block Desc'                'X'  'IT_FINAL1'   .
******************************************************************Addedby Raj on 23.02.2023***********
  PERFORM fieldcat_append  USING  'EXTENSION1'          'Data Line'           'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'EXTENSION2'          'Telebox'           'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'REMARK'              'Address Note'              'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZTERM'               'Payment Terms'               'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZTAG1'               'PayTerms Days'               'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'BRSCH'               'Industry'          'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'BRAN1'               'Industry Code 1'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KUNN2'               'Distributor Partner Cust. code'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'DNAME1'               'Distributor Partner Cust. name'                'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'INCO1'               'Incoterms'           'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'BAHNS'               'CIN No.'         'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'TAXKD'               'TCS Value'           'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'MAHNA'               'Dunning Procedure'                'X'  'IT_FINAL1'   ."Added By Raj on 15.09.2023
  PERFORM fieldcat_append  USING  'BAHNE'               'Express Station'                'X'  'IT_FINAL1'   ."Added By Raj on 06.10.2023
  PERFORM fieldcat_append  USING  'STCD5'               'Tax Number 5'              'X'  'IT_FINAL1'   ."Added By Raj on 06.10.2023
  PERFORM fieldcat_append  USING  'PAY_DESC'               'Payment Desc.'                'X'  'IT_FINAL1'   ."Added By Raj on 06.10.2023
  PERFORM fieldcat_append  USING  'TEXT'               'TCS Status'           'X'  'IT_FINAL1'   ."Added By Raj on 01.03.2023

  PERFORM fieldcat_append  USING  'LICNR'               '194 Q Form'            'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'BELIC'               'Form Status'             'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'DATAB'               'Valid From'            'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'DATBI'               'Valid To'          'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'KATR1'               'Attribute1'            'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'BANKS'               'Bank Counry'             'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'BANKL'               'Bank Key(IFSC)'                'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'BANKA'               'Bank Name'           'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'BANKN'               'Bank Account'              'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
  PERFORM fieldcat_append  USING  'KOINH'               'Account Holder'                'X'  'IT_FINAL1'   ."Added By Raj on 26.03.2023
****************************************************Added by Rutvi on 29.01.2025
  PERFORM fieldcat_append  USING  'MP_CODE'             'MP Code'         'X'  'IT_FINAL1'.
  PERFORM fieldcat_append  USING  'MP_CODE_CREATE_DATE' 'MPC Create Date'                'X'  'IT_FINAL1'.
  PERFORM fieldcat_append  USING  'OLD_PARENT_CODE'     'Old Parent Code'                'X'  'IT_FINAL1'.
  PERFORM fieldcat_append  USING  'REMARK_K'              'Remark'          'X'  'IT_FINAL1'.
*********************************************************************************
  PERFORM fieldcat_append  USING  'KDESC'              'Category'         'X'  'IT_FINAL1'."Added by Raj on 12.02.2025
  PERFORM fieldcat_append  USING  'KCDESC'              'Customer GroupDesc.'                'X'  'IT_FINAL1'."Added by Raj on 12.02.2025



*******************************************************************************************
  "New fields of addition in Hana by Ranjan 31.01.2026
  PERFORM fieldcat_append  USING  'ZZ1_ZZFLAG_T_CUS'               'Flag'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_MP_CODE_CUS'               'Master Parent Code'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_MP_CODE_CREATE_DAT_CUS'     'MPC Create Date'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_OLD_PARENT_CODE_CUS'  'Old Parent Code'                  'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_REMARK_CUS'               'Remarks'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_SP_CODE_CUS'               'Scheme Parent Code'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_CF_INDICATOR_CUS'               'Channel Finance (CF) indicator'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_CF_VALID_FROM_CUS''Channel Finance (CF) Valid From'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_CF_VALID_TO_CUS'               'Channel Finance (CF) Valid To'                 'X '  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_AGREEMENT_STATUS_CUS'   'Agreement status'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_CHEQUE_DETAILS_CUS' 'Cheque details in master'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_UPDATE_LOYALTY_STA_CUS'     'To update loyalty status'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_ALP_FLAG_CUS'              'ALP flag'                        'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_CODE_TO_CONSIDER_CUS'  'Code to be considered'                        'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_DMS_TAGGING_CUS'               'DMS Tagging'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_POSID1_CUS'               'Position ID-1'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_POSID2_CUS'               'Position ID-2'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_POSID3_CUS'               'Position ID-3'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_POSID4_CUS'               'Position ID-4'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_POSID5_CUS'               'Position ID-5'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_POSID6_CUS'               'Position ID-6'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'ZZ1_GEO1_CUS'               'Geo Code-1'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GEO2_CUS'               'Geo Code-2'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GEO3_CUS'               'Geo Code-3'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GEO4_CUS'               'Geo Code-4'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GEO5_CUS'               'Geo Code-5'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GEO6_CUS'               'Geo Code-6'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_TAX5_CUS'               'tax no 5'                 'X '  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KVGR1'               'Customer group-1'                  'X'  'IT_FINAL1'   .
  PERFORM fieldcat_append  USING  'KVGR2'               'Customer group-2'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'KTGRD'               'Account Assignment Group for Customer'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'VSBED'               'Shipping Conditions '                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'AKONT'               'Revenue Account'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'BUKRS'               'Company code'                'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'BEZEI_DESC'               'IncotermsLocation 1'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TAXKD_S'               'Tax Condition type SGST'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TAXKD_C'               'Tax Condition type CGST'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TAXKD_I'               'Tax Condition type IGST'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TEXT_C'               'Tax classification CGST - Description'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TEXT_S'               'Tax classification SGST - Description'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TEXT_I'               'Tax classification IGST - Description'                  'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'TEXT_I'               'Tax classification IGST - Description'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'KVGR2_DESC'               'Customer Group 2 Description'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'KVGR1_DESC'               'Customer Group 1 Description'                  'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'TYPE'               'Partner Category'                  'X'  'IT_FINAL1'  .

**Start Added by Archna Gupta on 11/03/2026
  PERFORM fieldcat_append  USING  'ZZ1_LID_1_SDH'               'LID_1'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L1_D_SDH'               'L1_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME1'               'L1_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L1_MOB'               'L1_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L1_EMAIL'               'L1_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_LID_2_SDH'               'LID_2'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L2_D_SDH'               'L2_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME2'               'L2_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L2_MOB'               'L2_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L2_EMAIL'               'L2_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_LID_3_SDH'               'LID_3'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L3_D_SDH'               'L3_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME3'               'L3_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L3_MOB'               'L3_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L3_EMAIL'               'L3_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_LID_4_SDH'               'LID_4'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L4_D_SDH'               'L4_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME4'               'L4_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L4_MOB'               'L4_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L4_EMAIL'               'L4_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_LID_5_SDH'               'LID_5'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L5_D_SDH'               'L5_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME5'               'L5_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L5_MOB'               'L5_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L5_EMAIL'               'L5_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_LID_6_SDH'               'LID_6'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L6_D_SDH'               'L6_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME6'               'L6_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L6_MOB'               'L6_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L6_EMAIL'               'L6_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_LID_7_SDH'               'LID_7'                 'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'ZZ1_L7_D_SDH'               'L7_D'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'EMP_NAME7'               'L7_D'            'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L7_MOB'               'L7_MOB'           'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'L7_EMAIL'               'L7_EMAIL'               'X'  'IT_FINAL1'  .

  PERFORM fieldcat_append  USING  'ZZ1_GID_1_SDH'               'GID_1'                 'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_G1_D_SDH'               'G1_D'               'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GID_2_SDH'               'GID_2'                 'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_G2_D_SDH'               'G2_D'               'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GID_3_SDH'               'GID_3'                 'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_G3_D_SDH'               'G3_D'               'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GID_4_SDH'               'GID_4'                 'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_G4_D_SDH'               'G4_D'               'X'  'IT_FINAL1'.
  PERFORM fieldcat_append  USING  'ZZ1_GID_5_SDH'               'GID_5'                 'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_G5_D_SDH'               'G5_D'               'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GID_6_SDH'               'GID_6'                 'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_G6_D_SDH'               'G6_D'               'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'ZZ1_GID_7_SDH'               'GID_7'                 'X'  'IT_FINAL1' .
  PERFORM fieldcat_append  USING  'ZZ1_G7_D_SDH'               'G7_D'               'X'  'IT_FINAL1'  .
  PERFORM fieldcat_append  USING  'KZAZU'                       'Orde Combination'                  'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'MOBILE'                       'Mobile No'                  'X'  'IT_FINAL1'  .
**  PERFORM fieldcat_append  USING  'EMAIL_ID'                       'Email ID'                  'X'  'IT_FINAL1'  .


**  End by Archna Gupta on 11/03/2026

  PERFORM fieldcat_append  USING  'SPERR'          'Posting Block'   'X'  'IT_FINAL1'.  "Added by Shubham Wani on 14.07.2026
  PERFORM fieldcat_append  USING  'CREDIT_LIMIT'   'Credit Limit'    'X'  'IT_FINAL1'.  "Added by Shubham Wani on 14.07.2026

*******************************************************************************************
ENDFORM.
FORM fieldcat_append  USING    VALUE(p_fname)
                               VALUE(p_ftext)
                               VALUE(p_fixcol)
                               VALUE(p_table).
  t_fieldcatalog-fieldname   = p_fname.
  t_fieldcatalog-seltext_l   = p_ftext.
  t_fieldcatalog-fix_column  = p_fixcol.
  t_fieldcatalog-tabname     = p_table.

  APPEND t_fieldcatalog.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_GRID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_grid .
  """"ADDED BY AKSHAY DT.29.07.2025
  DATA : dbs TYPE dbcon-con_name.
  DATA : wa_flag(1).
  IF p_chkbx = abap_true AND it_final1 IS NOT INITIAL.
    dbs = 'MSSQL2'.

    " ATC Correction for S4 HANA ** BEGIN OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
    EXEC SQL.
      connect TO :dbs
    ENDEXEC.                                            "#EC CI_EXECSQL
    " ATC Correction for S4 HANA ** END OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC

    LOOP AT it_final1 INTO wa_final1 WHERE vtweg = '10' AND spart = '10'.
      IF wa_flag = 0.
        " ATC Correction for S4 HANA ** BEGIN OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
        EXEC SQL.
          DELETE FROM sap_customer_data

        ENDEXEC.                                        "#EC CI_EXECSQL
        " ATC Correction for S4 HANA ** END OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
        wa_flag = 1.
      ENDIF.

      " ATC Correction for S4 HANA ** BEGIN OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
      EXEC SQL.


        insert into sap_customer_data  ( distributor_code, distributor_name, central_billing, bill_block_des, central_delivery, delivery_block_des, central_order, order_block_des, payment_term, payment_term_des )
        values  ( :wa_final1-kunnr, :wa_final1-name1, :wa_final1-faksd,:wa_final1-vtext1, :wa_final1-lifsd, :wa_final1-vtext2, :wa_final1-aufsd, :wa_final1-vtext, :wa_final1-zterm, :wa_final1-pay_desc )

      ENDEXEC.                                          "#EC CI_EXECSQL
      " ATC Correction for S4 HANA ** END OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
*    endif.
      CLEAR wa_final1.
    ENDLOOP.
  ELSEIF p_chkbx1 = abap_true AND it_final1 IS NOT INITIAL.
    DATA: lv_objectid TYPE cdhdr-objectid.
    dbs = 'MSSQL2'.

    " ATC Correction for S4 HANA ** BEGIN OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
    EXEC SQL.
      connect TO :dbs
    ENDEXEC.                                            "#EC CI_EXECSQL
    " ATC Correction for S4 HANA ** END OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC

    LOOP AT it_final1 INTO wa_final1 WHERE vtweg = '10' AND spart = '10'.
      " Step 1: Select from CDHDR
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = wa_final1-kunnr
        IMPORTING
          output = wa_final1-kunnr.

      lv_objectid = wa_final1-kunnr.

      SELECT objectclas,
             objectid,
             changenr,
             udate
        FROM cdhdr
        INTO TABLE @DATA(lt_cdhdr)
        WHERE objectclas = 'DEBI'
          AND objectid = @lv_objectid AND udate = @sy-datum.

      IF lt_cdhdr IS NOT INITIAL.

        " Step 2: Select from CDPOS
        SELECT objectclas,
               objectid,
               changenr,
               tabname,
               fname
          FROM cdpos
          INTO TABLE @DATA(lt_cdpos)
          FOR ALL ENTRIES IN @lt_cdhdr
          WHERE objectclas = @lt_cdhdr-objectclas
            AND objectid   = @lt_cdhdr-objectid
            AND changenr   = @lt_cdhdr-changenr
            AND tabname    = 'KNA1'
            AND fname IN ('AUFSD', 'FAKSD', 'LIFSD').
        IF sy-subrc = 0.
          " ATC Correction for S4 HANA ** BEGIN OF CHANGE BY UDAYABAP0313.01.2026 FOR ATC
          EXEC SQL.

            insert into sap_customer_data  ( distributor_code, distributor_name, central_billing, bill_block_des, central_delivery, delivery_block_des, central_order, order_block_des, payment_term, payment_term_des )
            values  ( :wa_final1-kunnr, :wa_final1-name1, :wa_final1-faksd, :wa_final1-vtext1, :wa_final1-lifsd, :wa_final1-vtext2, :wa_final1-aufsd, :wa_final1-vtext, :wa_final1-zterm, :wa_final1-pay_desc )

          ENDEXEC.                                      "#EC CI_EXECSQL
          " ATC Correction for S4 HANA ** END OF CHANGE BY UDAYABAP03 13.01.2026 FOR ATC
        ENDIF.
      ENDIF.

      CLEAR wa_final1.
    ENDLOOP.

  ELSE.
    """"EOC DT.29.07.2025
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
*       i_callback_top_of_page = 'TOP_OF_PAGE'
        is_layout          = fs_layout
        it_fieldcat        = t_fieldcatalog[]
        it_events          = t_event[]
        i_save             = 'A'
      TABLES
        t_outtab           = it_final1
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.  """"ADDED BY AKSHAY DT.29.07.2025
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  AUTHORIZATION_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authorization_check .
  SELECT vkorg FROM tvko
      INTO CORRESPONDING FIELDS OF TABLE it_tvko
  WHERE vkorg IN s_vkorg.
  LOOP AT it_tvko INTO wa_tvko.
    AUTHORITY-CHECK OBJECT 'Z_CT_VKORG'
    ID 'VKORG' FIELD wa_tvko-vkorg
    ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE e013(zsd) WITH wa_tvko-vkorg.
    ENDIF.
    CLEAR : wa_tvko.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_batch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_batch . "Added by UDAYABAP03 on 01.05.2026
  IF sy-batch = 'X'.
    DATA lt_zcust TYPE STANDARD TABLE OF zcust_hierarchy.

    LOOP AT it_final1 INTO DATA(ls_final).

      IF  ls_final-zz1_lid_1_sdh IS NOT INITIAL OR
          ls_final-zz1_lid_2_sdh IS NOT INITIAL OR
          ls_final-zz1_lid_3_sdh IS NOT INITIAL OR
          ls_final-zz1_lid_4_sdh IS NOT INITIAL OR
          ls_final-zz1_lid_5_sdh IS NOT INITIAL OR
          ls_final-zz1_lid_6_sdh IS NOT INITIAL OR
          ls_final-zz1_lid_7_sdh IS NOT INITIAL .  "Added by UDAYABAP03on 22.06.2026


        APPEND VALUE zcust_hierarchy(
          mandt = sy-mandt
          vkorg = ls_final-vkorg
          kunnr = ls_final-kunnr

          "---- LID hierarchy
          lid_1    = ls_final-zz1_lid_1_sdh
          l1_d     = ls_final-emp_name1
          l1_mob   = ls_final-l1_mob
          l1_email = ls_final-l1_email

          lid_2    = ls_final-zz1_lid_2_sdh
          l2_d     = ls_final-emp_name2
          l2_mob   = ls_final-l2_mob
          l2_email = ls_final-l2_email

          lid_3    = ls_final-zz1_lid_3_sdh
          l3_d     = ls_final-emp_name3
          l3_mob   = ls_final-l3_mob
          l3_email = ls_final-l3_email

          lid_4    = ls_final-zz1_lid_4_sdh
          l4_d     = ls_final-emp_name4
          l4_mob   = ls_final-l4_mob
          l4_email = ls_final-l4_email

          lid_5    = ls_final-zz1_lid_5_sdh
          l5_d     = ls_final-emp_name5
          l5_mob   = ls_final-l5_mob
          l5_email = ls_final-l5_email

          lid_6    = ls_final-zz1_lid_6_sdh
          l6_d     = ls_final-emp_name6
          l6_mob   = ls_final-l6_mob
          l6_email = ls_final-l6_email

          lid_7    = ls_final-zz1_lid_7_sdh
          l7_d     = ls_final-emp_name7
          l7_mob   = ls_final-l7_mob
          l7_email = ls_final-l7_email

          "---- GID hierarchy
          gid_1 = ls_final-zz1_gid_1_sdh
          g1_d  = ls_final-zz1_g1_d_sdh

          gid_2 = ls_final-zz1_gid_2_sdh
          g2_d  = ls_final-zz1_g2_d_sdh

          gid_3 = ls_final-zz1_gid_3_sdh
          g3_d  = ls_final-zz1_g3_d_sdh

          gid_4 = ls_final-zz1_gid_4_sdh
          g4_d  = ls_final-zz1_g4_d_sdh

          gid_5 = ls_final-zz1_gid_5_sdh
          g5_d  = ls_final-zz1_g5_d_sdh

          gid_6 = ls_final-zz1_gid_6_sdh
          g6_d  = ls_final-zz1_g6_d_sdh

          gid_7 = ls_final-zz1_gid_7_sdh
          g7_d  = ls_final-zz1_g7_d_sdh
        ) TO lt_zcust.
      ENDIF.
    ENDLOOP.
    SORT lt_zcust BY kunnr.
    DELETE ADJACENT DUPLICATES FROM lt_zcust COMPARING vkorg kunnr.
    IF lt_zcust IS NOT INITIAL.
      MODIFY zcust_hierarchy FROM TABLE lt_zcust.

      IF sy-subrc = 0.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.
    ENDIF.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form for_customer_block
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM for_customer_block .


ENDFORM.
