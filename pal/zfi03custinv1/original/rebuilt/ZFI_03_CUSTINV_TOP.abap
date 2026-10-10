*&---------------------------------------------------------------------*
*& Include ZFI_03_CUSTINV_TOP
*&---------------------------------------------------------------------*

*&----------------------------------------------------------------------------------------------*
*&        TABLE DECLARATION                                                                     *
*&----------------------------------------------------------------------------------------------*
*&  In this section you can declare all tables                                                  *
*&----------------------------------------------------------------------------------------------*
TABLES: acdoca, but000.

TYPE-POOLS: vrm.

TYPES: BEGIN OF ty_zglbparam,
         zparam_id  TYPE zglbparam-zparam_id,
         zwricef_id TYPE zglbparam-zwricef_id,
         bukrs      TYPE zglbparam-bukrs,
         zcounter   TYPE zglbparam-zcounter,
         zprog      TYPE zglbparam-zprog,
         zpm_low    TYPE zglbparam-zpm_low,
         zpm_high   TYPE zglbparam-zpm_high,
       END OF ty_zglbparam.

TYPES: BEGIN OF ty_doctype,
         zparam_id  TYPE zglbparam-zparam_id,
         zwricef_id TYPE zglbparam-zwricef_id,
         bukrs      TYPE zglbparam-bukrs,
         zcounter   TYPE zglbparam-zcounter,
         zprog      TYPE zglbparam-zprog,
         zpm_low    TYPE zglbparam-zpm_low,
         zpm_high   TYPE zglbparam-zpm_high,
       END OF ty_doctype.

TYPES: BEGIN OF ty_acdoca,
         rldnr          TYPE acdoca-rldnr,
         rbukrs         TYPE acdoca-rbukrs,
         gjahr          TYPE acdoca-gjahr,
         belnr          TYPE acdoca-belnr,
         docln          TYPE acdoca-docln,
         blart          TYPE acdoca-blart,
         buzei          TYPE acdoca-buzei,
         bldat          TYPE acdoca-bldat,
         kunnr          TYPE acdoca-kunnr,
         netdt          TYPE acdoca-netdt,
         prctr          TYPE acdoca-prctr,
         rwcur          TYPE acdoca-rwcur,
         sgtxt          TYPE acdoca-sgtxt,
         xreversed      TYPE acdoca-xreversed,
         usnam          TYPE acdoca-usnam,
         koart          TYPE acdoca-koart,
         racct          TYPE acdoca-racct,
         zuonr          TYPE acdoca-zuonr,
         wsl            TYPE acdoca-wsl,
         ktosl          TYPE acdoca-ktosl,
         mwskz          TYPE acdoca-mwskz,
         glaccount_type TYPE acdoca-glaccount_type,
         hbkid          TYPE acdoca-hbkid,
         hktid          TYPE acdoca-hktid,
         drcrk          TYPE acdoca-drcrk,
       END OF ty_acdoca.

*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
TYPES: BEGIN OF ty_acdoca_vat,
         rbukrs         TYPE acdoca-rbukrs,
         gjahr          TYPE acdoca-gjahr,
         belnr          TYPE acdoca-belnr,
         blart          TYPE acdoca-blart,
         mwskz          TYPE acdoca-mwskz,
         racct          TYPE acdoca-racct,
         wsl            TYPE acdoca-wsl,
         ktosl          TYPE acdoca-ktosl,
       END OF ty_acdoca_vat.
*End of Changes

TYPES: BEGIN OF ty_acdoca_asterisk,
         rldnr          TYPE acdoca-rldnr,
         nrivr_bukrs    TYPE nriv-subobject,
         gjahr          TYPE acdoca-gjahr,
         belnr          TYPE acdoca-belnr,
         asterisk_kunnr TYPE stxh-tdname,
         asterisk_rbg   TYPE stxh-tdname,
         asterisk_desc  TYPE stxh-tdname,
         kunnr          TYPE acdoca-kunnr,
       END OF ty_acdoca_asterisk.

TYPES: BEGIN OF ty_acdoca_sr,
         rldnr  TYPE acdoca-rldnr,
         rbukrs TYPE nriv-subobject,
         gjahr  TYPE nriv-toyear,
         blart  TYPE acdoca-blart,
       END OF ty_acdoca_sr.

TYPES: BEGIN OF ty_t001,
         bukrs TYPE t001-bukrs,
         adrnr TYPE t001-adrnr,
         stceg TYPE t001-stceg,
         butxt TYPE t001-butxt,
         land1 TYPE t001-land1,
       END OF ty_t001.

TYPES: BEGIN OF ty_t001z,
         bukrs TYPE t001z-bukrs,
         party TYPE t001z-party,
         paval TYPE t001z-paval,
       END OF ty_t001z.

TYPES: BEGIN OF ty_adrc_comadd,
         addrnumber TYPE adrc-addrnumber,
         date_from  TYPE adrc-date_from,
         nation     TYPE adrc-nation,
         str_suppl1 TYPE adrc-str_suppl1,
         str_suppl2 TYPE adrc-str_suppl2,
         str_suppl3 TYPE adrc-str_suppl3,
         street     TYPE adrc-street,
         city1      TYPE adrc-city1,
         post_code1 TYPE adrc-post_code1,
         region     TYPE adrc-region,
         city2      TYPE adrc-city2,
         name1      TYPE adrc-name1,
         location   TYPE adrc-location,
         country    TYPE t005t-land1,
         landx      TYPE t005t-landx,
       END OF ty_adrc_comadd.

TYPES: BEGIN OF ty_t012k,
         bukrs TYPE t012k-bukrs,     "Company Code
         hbkid TYPE t012k-hbkid,     "House Bank
         hktid TYPE t012k-hktid,     "Account ID
         bankn TYPE t012k-bankn,     "Bank Account
         waers TYPE t012k-waers,     "Currency
       END OF ty_t012k.

TYPES: BEGIN OF ty_t012,
         bukrs TYPE t012-bukrs,     "Company Code
         hbkid TYPE t012-hbkid,     "House Bank
         banks TYPE t012-banks,     "Bank Country/Region
         bankl TYPE t012-bankl,     "Bank Key
       END OF ty_t012.

TYPES: BEGIN OF ty_bnka,
         banks TYPE bnka-banks,     "Bank Country/Region
         bankl TYPE bnka-bankl,     "Bank Key
         banka TYPE bnka-banka,     "Bank Name
         swift TYPE bnka-swift,     "SWIFT/BIC for International Payments
         bnklz TYPE bnka-bnklz,      "Bank Number
       END OF ty_bnka.


TYPES: BEGIN OF ty_adrc_billto_add,
         addrnumber TYPE adrc-addrnumber,
         date_from  TYPE adrc-date_from,
         nation     TYPE adrc-nation,
         name1      TYPE adrc-name1,
         name2      TYPE adrc-name2,
         name3      TYPE adrc-name3,
         name4      TYPE adrc-name4,
         street     TYPE adrc-street,
         str_suppl1 TYPE adrc-str_suppl1,
         str_suppl2 TYPE adrc-str_suppl2,
         str_suppl3 TYPE adrc-str_suppl3,
         city2      TYPE adrc-city2,
         city1      TYPE adrc-city1,
         post_code1 TYPE adrc-post_code1,
       END OF ty_adrc_billto_add.

TYPES: BEGIN OF ty_cepct,
         spras TYPE cepct-spras,
         prctr TYPE cepct-prctr,
         datbi TYPE cepct-datbi,
         kokrs TYPE cepct-kokrs,
         ltext TYPE cepct-ltext,
       END OF ty_cepct.

TYPES: BEGIN OF ty_but020,
         partner    TYPE but020-partner,
         addrnumber TYPE but020-addrnumber,
       END OF ty_but020.

TYPES: BEGIN OF ty_adr6,
         addrnumber TYPE adr6-addrnumber,
         smtp_addr  TYPE adr6-smtp_addr,
         default    TYPE adr6-flgdefault,
       END OF ty_adr6.

TYPES: BEGIN OF ty_but000,
         partner    TYPE but000-partner,
         type       TYPE but000-type,
         name_first TYPE but000-name_first,
         namemiddle TYPE but000-namemiddle,
         name_last  TYPE but000-name_last,
         name_org4  TYPE but000-name_org4,
         bu_group   TYPE but000-bu_group,
       END OF ty_but000.

TYPES: BEGIN OF ty_but000_cag,
         partner  TYPE but000-partner,
         bu_group TYPE but000-bu_group,
       END OF ty_but000_cag.

TYPES: BEGIN OF ty_dfkkbptaxnum,
         partner TYPE dfkkbptaxnum-partner,
         taxtype TYPE dfkkbptaxnum-taxtype,
         taxnum  TYPE dfkkbptaxnum-taxnum,
       END OF ty_dfkkbptaxnum.

TYPES: BEGIN OF ty_stxh,
         tdobject       TYPE stxh-tdobject,
         tdname         TYPE stxh-tdname,
         tdid           TYPE stxh-tdid,
         tdspras        TYPE stxh-tdspras,
         asterisk_kunnr TYPE stxh-tdname,
       END OF ty_stxh.

TYPES: BEGIN OF ty_stxh2,
         tdobject     TYPE stxh-tdobject,
         tdname       TYPE stxh-tdname,
         tdid         TYPE stxh-tdid,
         tdspras      TYPE stxh-tdspras,
         asterisk_rbg TYPE stxh-tdname,
       END OF ty_stxh2.

TYPES: BEGIN OF ty_zsigntab,
         user_id     TYPE zsigntab-user_id,
         lastname    TYPE zsigntab-lastname,
         firstname   TYPE zsigntab-firstname,
         releasecode TYPE zsigntab-releasecode,
         mi          TYPE zsigntab-mi,
         esignature  TYPE zsigntab-esignature,
         zposition   TYPE zsigntab-zposition,
       END OF ty_zsigntab.

TYPES: BEGIN OF ty_t003,
         blart      TYPE t003-blart,
         numkr      TYPE t003-numkr,
         object     TYPE nriv-object,
         subobject  TYPE nriv-subobject,
         nrrangenr  TYPE nriv-nrrangenr,
         toyear     TYPE nriv-toyear,
         fromnumber TYPE nriv-fromnumber,
         tonumber   TYPE nriv-tonumber,
       END OF ty_t003.

TYPES: BEGIN OF ty_nriv,
         object     TYPE nriv-object,
         subobject  TYPE nriv-subobject,
         nrrangenr  TYPE nriv-nrrangenr,
         toyear     TYPE nriv-toyear,
         fromnumber TYPE nriv-fromnumber,
         tonumber   TYPE nriv-tonumber,
       END OF ty_nriv.


TYPES: BEGIN OF ty_detail,
         descr    TYPE char200, "Description
         qty      TYPE char20, "QTY
         ucost    TYPE char20, "Unit Cost
         vat      TYPE char20, "Vat
         currency TYPE char10, "Currency
         tamount  TYPE char40, "Total Amount
       END OF ty_detail.

*FOR EMAIL LOG
TYPES: BEGIN OF ty_emaillog,
         status   TYPE string, "Status
         docnum   TYPE string, "Document No.
         fiscal   TYPE string, "Fiscal Year
         ccode    TYPE string, "Company Code
         cname    TYPE string, "Customer Name
         sendmail TYPE string, "Sending Email
         recmail  TYPE string, "Recieving Email
         message  TYPE string, "Message
       END OF ty_emaillog.

TYPES: BEGIN OF ty_tcurt,
         spras TYPE tcurt-spras,
         waers TYPE tcurt-waers,
         ltext TYPE tcurt-ltext,
         ktext TYPE tcurt-ktext,
       END OF ty_tcurt.

TYPES: BEGIN OF ty_hbank,
         bukrs TYPE t012k-bukrs,
         hbkid TYPE t012k-hbkid,
         banks TYPE t012-banks,
         bankl TYPE t012-bankl,
         banka TYPE bnka-banka,
         ort01 TYPE bnka-ort01,
       END OF ty_hbank.

TYPES: BEGIN OF ty_accid,
         bukrs TYPE t012t-bukrs,
         hbkid TYPE t012t-hbkid,
         hktid TYPE t012t-hktid,
         text1 TYPE t012t-text1,
       END OF ty_accid.

*FOR SALV
DATA: alv_table     TYPE REF TO cl_salv_table,
      alv_columns   TYPE REF TO cl_salv_columns_table,
      single_column TYPE REF TO cl_salv_column,
      o_events      TYPE REF TO cl_salv_events_table ##NEEDED.


*&----------------------------------------------------------------------------------------------*
*&        Internal Table and Work area Declaration                                                             *
*&----------------------------------------------------------------------------------------------*
DATA: gt_acdoca          TYPE STANDARD TABLE OF ty_acdoca,
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
      i_peza_param       TYPE STANDARD TABLE OF ty_zglbparam,
      gt_acdoca_vat      TYPE STANDARD TABLE OF ty_acdoca_vat,
*End of Changes
      i_param            TYPE STANDARD TABLE OF ty_zglbparam,
      i_param2           TYPE STANDARD TABLE OF ty_zglbparam,
      i_param3           TYPE STANDARD TABLE OF ty_zglbparam,
      i_param4           TYPE STANDARD TABLE OF ty_zglbparam,
      i_param5           TYPE STANDARD TABLE OF ty_zglbparam,
      i_param6           TYPE STANDARD TABLE OF ty_zglbparam,
      i_param7           TYPE STANDARD TABLE OF ty_zglbparam,
      gt_t001            TYPE STANDARD TABLE OF ty_t001,
      gt_adrc_comadd     TYPE STANDARD TABLE OF ty_adrc_comadd,
      gt_adrc_billto_add TYPE STANDARD TABLE OF ty_adrc_billto_add,
      gt_cepct           TYPE STANDARD TABLE OF ty_cepct,
      gt_but020          TYPE STANDARD TABLE OF ty_but020,
      gt_dfkkbptaxnum    TYPE STANDARD TABLE OF ty_dfkkbptaxnum,
      gt_stxh            TYPE STANDARD TABLE OF ty_stxh,
      gt_zsigntab        TYPE STANDARD TABLE OF ty_zsigntab,
      gt_t003            TYPE STANDARD TABLE OF ty_t003,
      gt_nriv            TYPE STANDARD TABLE OF ty_nriv ##NEEDED,
      gt_acdoca_asterisk TYPE STANDARD TABLE OF ty_acdoca_asterisk ##NEEDED,
      gt_doctype         TYPE STANDARD TABLE OF ty_doctype ##NEEDED,
      gt_t001z           TYPE STANDARD TABLE OF ty_t001z,
      gt_but000          TYPE STANDARD TABLE OF ty_but000,
      gt_but000_cag      TYPE STANDARD TABLE OF ty_but000_cag,
      gt_acdoca_sr       TYPE STANDARD TABLE OF ty_acdoca_sr,
      gt_acdoca_temp     TYPE STANDARD TABLE OF ty_acdoca,
      gt_stxh2           TYPE STANDARD TABLE OF ty_stxh2,
      gt_email           TYPE STANDARD TABLE OF ty_emaillog,
      gt_adr6            TYPE STANDARD TABLE OF ty_adr6,
      gt_tcurt           TYPE STANDARD TABLE OF ty_tcurt,
      gt_acdoca_kunnr    TYPE STANDARD TABLE OF ty_acdoca,
      gt_t012k           TYPE STANDARD TABLE OF ty_t012k,
      gt_t012            TYPE STANDARD TABLE OF ty_t012,
      gt_bnka            TYPE STANDARD TABLE OF ty_bnka,
      gt_t012kbh         TYPE STANDARD TABLE OF ty_t012k,
      gt_t012bh          TYPE STANDARD TABLE OF ty_t012,
      gt_bnkabh          TYPE STANDARD TABLE OF ty_bnka,
      gt_t001acname      TYPE STANDARD TABLE OF ty_t001,
      gt_t001acnamebh    TYPE STANDARD TABLE OF ty_t001.

DATA: gs_acdoca          TYPE ty_acdoca,
      gs_param           TYPE ty_zglbparam,
      gs_param2          TYPE ty_zglbparam ##NEEDED,
      gs_param3          TYPE ty_zglbparam ##NEEDED,
      gs_param4          TYPE ty_zglbparam ##NEEDED,
      gs_param5          TYPE ty_zglbparam ##NEEDED,
      gs_param6          TYPE ty_zglbparam ##NEEDED,
      gs_param7          TYPE ty_zglbparam,
      gs_t001            TYPE ty_t001,
      gs_adrc_comadd     TYPE ty_adrc_comadd,
      gs_adrc_billto_add TYPE ty_adrc_billto_add,
      gs_cepct           TYPE ty_cepct,
      gs_but020          TYPE ty_but020,
      gs_dfkkbptaxnum    TYPE ty_dfkkbptaxnum,
      gs_stxh            TYPE ty_stxh,
      gs_zsigntab        TYPE ty_zsigntab,
      gs_t003            TYPE ty_t003,
      gs_nriv            TYPE ty_nriv ##NEEDED,
      gs_acdoca_asterisk TYPE ty_acdoca_asterisk,
      gs_doctype         TYPE ty_doctype ##NEEDED,
      gs_t001z           TYPE ty_t001z ##NEEDED,
      gs_but000          TYPE ty_but000,
      gs_but000_cag      TYPE ty_but000_cag,
      gs_acdoca_sr       TYPE ty_acdoca_sr,
      gs_acdoca_temp     TYPE ty_acdoca,
      gs_stxh2           TYPE ty_stxh2,
      gs_email           TYPE ty_emaillog,
      gs_adr6            TYPE ty_adr6,
      gs_tcurt           TYPE ty_tcurt ##NEEDED,
      gs_acdoca_kunnr    TYPE ty_acdoca ##NEEDED,
      gs_t012k           TYPE ty_t012k,
      gs_t012            TYPE ty_t012,
      gs_bnka            TYPE ty_bnka,
      gs_t012kbh         TYPE ty_t012k,
      gs_t012bh          TYPE ty_t012,
      gs_bnkabh          TYPE ty_bnka,
      gs_t001acname      TYPE ty_t001,
      gs_t001acnamebh    TYPE ty_t001.

DATA: gt_billoff TYPE STANDARD TABLE OF ty_zglbparam,
      gs_billoff TYPE ty_zglbparam.

************ TABLES SMARTFORMS ************
DATA: gt_detail      TYPE STANDARD TABLE OF ty_detail,
      gs_detail      TYPE ty_detail,
      gs_header      TYPE zfi_struc_custinv_hdr,
      gv_result      TYPE sfpjoboutput,
      gv_funcname    TYPE funcname,
      "      gv_funcname    TYPE ,
      gs_docparams   TYPE sfpoutputparams,
      "     gs_docparams   TYPE sfpdocparams,

      gv_form_output TYPE fpformoutput.

*&----------------------------------------------------------------------------------------------*
*&        DATA/VARIABLE DECLARATION                                                             *
*&----------------------------------------------------------------------------------------------*
*&  In this section you can define internal tables,variables and etc.                           *
*&----------------------------------------------------------------------------------------------*


******* SAVE FILE AS PDF *******
DATA: gv_formname   TYPE tdsfname,
      gv_fm_name    TYPE rs38l_fnam,
      gwa_ssfcompop TYPE ssfcompop,
      gwa_control   TYPE ssfctrlop,
      gv_devtype    TYPE rspoptype,
      gv_job_output TYPE ssfcrescl,
      gt_lines      TYPE TABLE OF tline,
      gv_size       TYPE i,
      gv_pdfname    TYPE string,
*****************add a variable*************
      lt_pdf_binary TYPE STANDARD TABLE OF solix,
      gv_pdf_data   TYPE xstring.
***************end*****************************

********** SEND EMAIL **********
DATA: t_pdf_tab          LIKE tline OCCURS 0 WITH HEADER LINE, " SAPscript: Text Lines
      t_otf              TYPE itcoo OCCURS 0 WITH HEADER LINE, " OTF Structure
      w_bin_filesize(10) TYPE c,
      "      i_tline            TYPE STANDARD TABLE OF tline.
      i_tline            TYPE solix_tab.
"      i_tline            TYPE solix_tab.
*******************************************************
"    i_tline1           TYPE  solix_tab.
*****************************************************

DATA: li_otf          TYPE TABLE OF itcoo ##NEEDED,
      lw_otf          TYPE itcoo ##NEEDED,
      li_otf1         TYPE TABLE OF itcoo ##NEEDED,
      li_pdf_tab      TYPE TABLE OF tline ##NEEDED,
      li_content_txt  TYPE soli_tab ##NEEDED,
      lw_content      TYPE soli,
      li_content_hex  TYPE solix_tab,
      li_objhead      TYPE soli_tab,
      lv_bin_filesize TYPE i ##NEEDED,
      lv_transfer_bin TYPE sx_boolean ##NEEDED,
      lv_len          TYPE so_obj_len.

*********** EMAIL LOG **********
DATA: gv_elog_status   TYPE string,
      gv_elog_docnum   TYPE string,
      gv_elog_fiscal   TYPE string,
      gv_elog_ccode    TYPE string,
      gv_elog_cname    TYPE string,
      gv_elog_sendmail TYPE string,
      gv_elog_recmail  TYPE string,
      gv_elog_message  TYPE string.

DATA: gv_rword          LIKE spell,
      gv_col19          TYPE p DECIMALS 2,
      gv_col19_char(50) TYPE c,
      gv_var1_int       TYPE int8,
      gv_total          TYPE p DECIMALS 2 ##NEEDED,
      gv_blart          TYPE string ##NEEDED,
      gv_tamtfig2       TYPE p DECIMALS 2 ##NEEDED.

DATA: full_path   TYPE string, "filepath for PDF
      lv_day      TYPE char2,  "Date format
      lv_month    TYPE char3,
      lv_year     TYPE char4,
      lv_daydue   TYPE char2,  "Date format
      lv_monthdue TYPE char3,
      lv_yeardue  TYPE char4.

**********VAT**********
DATA: gv_vatsales  TYPE acdoca-wsl,
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
      gv_vatlocal  TYPE acdoca-wsl,
      gv_vatlocal_bir TYPE acdoca-wsl,
*End of Changes
      gv_vat12     TYPE acdoca-wsl,
      gv_cwt       TYPE with_item-wt_qbshb,
      gv_zerosales TYPE acdoca-wsl,
      gv_xmptsales TYPE acdoca-wsl,
      gv_vattotal  TYPE acdoca-wsl,
      gv_totalamt  TYPE acdoca-wsl ##NEEDED.
**********Details**********
DATA: gv_descr    TYPE char200 ##NEEDED,
      gv_qty      TYPE acdoca-zuonr,
      gv_ucost    TYPE acdoca-wsl,
      gv_vat      TYPE acdoca-wsl,
      "      gv_tamount  TYPE acdoca-wsl,
      gv_currency TYPE acdoca-rwcur,
      gv_tamount  TYPE acdoca-wsl,
      gv_tamount1 TYPE acdoca-wsl,
      gv_tamtfig  TYPE char40 ##NEEDED,
      gv_tamtdec  TYPE p DECIMALS 2,
      gv_cwtdec   TYPE p DECIMALS 2,
      gv_duedec   TYPE p DECIMALS 2,
      gv_billto   TYPE string ##NEEDED,
      gv_wrbtr    TYPE wrbtr ##NEEDED,
      gv_tampfig  TYPE string ##NEEDED,
      gv_group    TYPE string,
      gv_emailadd TYPE string.

*ADDED 06/20/2023
DATA: gv_password TYPE string.


*&----------------------------------------------------------------------------------------------*
*&         CONSTANTS DECLARATION                                                                *
*&----------------------------------------------------------------------------------------------*

*FORM NAMES
*CONSTANTS: c_fbill   TYPE string VALUE 'ZFI_F03_CUSTINV_BILL',
*           c_fcredit TYPE string VALUE 'ZFI_F03_CUSTINV_CM',
*           c_fdebit  TYPE string VALUE 'ZFI_F03_CUSTINV_DM'.

CONSTANTS: "c_fbill   TYPE string VALUE 'ZF_FI_CUSTINV_FORM',
  c_fbill   TYPE string VALUE 'ZF_FI_CUSTINV_FORM',
  c_fcredit TYPE string VALUE 'ZF_FI_CREDITCUSTINV_FORM',
  c_fdebit  TYPE string VALUE 'ZF_FI_DEBITCUSTINV_FORM'.

*EMAIL SUBJECT
CONSTANTS: c_billing_statement TYPE string VALUE 'eBilling' ##NO_TEXT,
           c_debit_memo        TYPE string VALUE 'Debit Memo' ##NO_TEXT,
           c_credit_memo       TYPE string VALUE 'Credit Memo' ##NO_TEXT.

*SELECT STATEMENT
CONSTANTS: c_blank      TYPE string VALUE ' ',
           c_dash       TYPE string VALUE '-',
           c_bs         TYPE char40  VALUE 'ZFIDOCTYPE_BS', "Customer Inv Doc Type
           gc_dt_bs     TYPE string  VALUE 'DR',  "Document type for Customer Invoice
           c_cm         TYPE char40  VALUE 'ZFIDOCTYPE_CM', "Customer Credit Memo Doc Type
           gc_dt_cm     TYPE string  VALUE 'DG',  "type for credit memo
           c_dm         TYPE char40  VALUE 'ZFIDOCTYPE_DM', "Customer Debit Memo Doc Type
           gc_dt_dm     TYPE string  VALUE 'SA', "type for debit memo
           c_pr01       TYPE string VALUE 'PR01',
           c_2p01       TYPE string VALUE '2P01',
           c_logo_pal   TYPE string VALUE 'ZLOGO_PR01',
           c_logo_palex TYPE string VALUE 'ZLOGO_2P01inv',
           c_reprint    TYPE string VALUE 'REPRINTED',
           c_address    TYPE string VALUE 'Owned and Operated by' ##NO_TEXT,
           c_vat        TYPE string VALUE 'VAT REG. TIN',
           c_inv        TYPE string VALUE 'INVOICE',
           c_credit     TYPE string VALUE 'Credit Memo',
           c_debit      TYPE string VALUE 'Debit Memo'.
