*&---------------------------------------------------------------------*
*& Program  : ZFI_CNB_BRS1
*& Title    : Bank Reconciliation Report (single-source copy)
*& Source   : ONGC version of ZFI_CNB_BRS (OCD, 10.10.2026) with include
*&            ZFIBRSTOP merged in place of the INCLUDE statement.
*& Created  : Arnav Johri, 10.10.2026
*&---------------------------------------------------------------------*
REPORT  zfi_cnb_brs1  LINE-SIZE 255 MESSAGE-ID zfi NO STANDARD PAGE
HEADING.
INCLUDE <icon>.
INCLUDE <symbol>.

***********************************************************************
* Program    : ZFI_CNB_BRS                                            *
*                                                                     *
* Title      : Bank Reconciliation Report                             *
*              MIGRATED FROM UFSO SERVER. NO LOGIC CHANGED
*                                                                     *
* Functional Specification No. : FS-FI-BA-001                         *
*                                                                     *
* Author     : Nandini Bakre                     Date : 28-03-2003

*                                                                     *
* Login Id   : CAB_NANDINIB                                           *
*                                                                     *
* Desciption : Bank Reconciliation Report                             *
*              MIGRATED FROM UFSO SERVER. NO LOGIC CHANGED
*                                                                     *
* Tran.Code  : ZFIBRS                                                 *
*                                                                     *
***********************************************************************
* CHANGE HISTORY                                                      *
*                                                                     *
* Mod Date    Changed by    Description                 Chng ID       *
*                                                                     *
**********************************************************************
*NO PROCESSING LOGIC HAS BEEN CHANGED.
***********************************************************************

************************************************************************
***For Accounting Document Program Has changed it is now going through
*** Table BSIS****
****Program Changed By Siladitya
************************************************************************

*** NO PROCESSING  LOGIC HAS BEEN CHANGED- Nandini Bakre***************
*********************************************************************
*  CHANGE HISTORY
*  MODIFICATION DATE  CHANGED BY     DESCRIPTION
*  06-08-2003         B.S. BHATIA    UNMATCHED FOREX RECEIPTS REPORT
*  LOGIN ID: CAB_BHATIABS
*  FS: FS-FI-BA-06 VER:1.0
**********************************************************************
* CHANGE HISTORY                                                      *
*                                                                     *
* Mod Date    Changed by    Description                 Chng ID       *
* 23.12.05    cab_nandinib  Doc.Amt. Type changed       +002          *
*                           from local currency to                    *
*                           document currency for OBV
***********************************************************************
***********************************************************************
*  Date           Transport    USERID       Description

* 17/09/2008      RD1K960036   SAB_RAMASUND
*
*1.CHANGE IN INCLUDE ZFIBRSTOP
*2.Replaced F.M UPLOAD With GUI_UPLOAD.
*3.Replaced F.M WS_UPLOAD with GUI_UPLOAD.
*4.Replaced F.M Convert_date_input withcconvert_date_with_threshold.
***********************************************************************

************************************************************************
*  Date            Transport      USERID        Description
* 27/10/2008      <RD1K960036>    SAB_SUMODH
*
*1) Table Parameter in GUI_Download Changed in line 1183.
************************************************************************
**********************************************************************
* CHANGE HISTORY                                                      *
*                                                                     *
* Mod Date    Changed by    Description                 Chng ID       *
*11.11.2014 Rama  Cr 30011953
************************************************************************
*BOC By Arnav on 10/10/26
* Include ZFIBRSTOP merged in-line (program has no own includes)
*INCLUDE zfibrstop.
*----------------------------------------------------------------------*
*   INCLUDE YBRSTOP                                                    *
*----------------------------------------------------------------------*
* --- DATA DECLARATION SECTION ----- *

***********************************************************************
*  Date           Transport    USERID       Description
* 12/09/2008      RD1K960036   SAB_RAMASUND 1.CONSTANT DECLARED

***********************************************************************

TABLES: febko,              " Electronic Bank Statement Header Records
        febep,              " Electronic Bank Statement Line Items
        bseg,               " Accounting document segment
        bkpf,               " Accounting document header
        t012k,              " House bank accounts
        t001,               " Company Codes
        t012,               " House banks
        bnka,               " Bank master record
        csks,               " Cost Center Master
        t028h,        " Allocate Manual to Internal Transactions
        tgsb,              "Master for BA
        payr,               " Payment transfer medium file
        ska1,               " G/L accounts master (chart of accounts)
        t021d,              "Screen no for Vanriant 'BANK'
*        T012K .             " House Bank Accounts
        bsis ,
        glt0. "G/L account master record transaction figures Dtd.25.03.2003

TABLES sscrfields.
* ---- Internal table to input Bank statement ---- *
DATA : BEGIN OF input OCCURS 0,
         slno(6),
         actno(12),
         valdt(6),
         tran_dt(6),
         narration(25),
         dr_cr(1),
         tran_amt(15),
*      TRAN_AMT(17),                                        "+003
         dr_cr1(1),
         cum_bal(15),
*      CUM_BAL(17),                                         "+003
         errrec(1),
       END OF input.

* ---- Internal Table to store Bank stmt input after derivation of ---*
* ---- Check no, RT# and Trans Code field ------ *
DATA : BEGIN OF intab OCCURS 2000,
         slno(6),                            " Control No
         actno(12),
         valdt(6),                          " Value Date
         tran_dt(6),
         narration(25),
         dr_cr(1),
         tran_amt(15),
*               TRAN_AMT(17),                               "+003
         dr_cr1(1),
         cum_bal(15),
*               CUM_BAL(17),                                "+003
         tcode(4),                           " Transaction Code
         chkno(13),                          " Check No
         rt#           LIKE bseg-belnr,              " document no
         docno         LIKE bseg-belnr,
         gsber         LIKE bseg-gsber,
         descr(55),                          " Description
         errrec(2),                          " Bank Rec Error
       END OF intab.
DATA : input1 LIKE input OCCURS 0 WITH HEADER LINE.

DATA : BEGIN OF opentab OCCURS 0,
         belnr     LIKE bseg-belnr,       " Document No
         blart     LIKE bkpf-blart,        " Document type
         shkzg     LIKE bseg-shkzg,       " Debit/Credit Indc
         dmbtr     LIKE bseg-dmbtr,       " Amount
         wrbtr     LIKE bseg-wrbtr,       " Amount (+002)
         budat(10),                   " Posting Date
         chect     LIKE payr-chect,       " Check number
         bancd(10),                   " Check Encashment date
         gsber     LIKE tgsb-gsber,
         vblnr     LIKE payr-vblnr,       " Payment doc. No
         voidr     LIKE payr-voidr,       " Check void Reason code
         zuonr     LIKE bseg-zuonr,       " Allocation number
         augbl     LIKE bseg-augbl,       " Doc no. of clearing doc.
         sgtxt     TYPE bseg-sgtxt,       " Text
         gjahr     LIKE bkpf-gjahr,       "Fiscal Year
         errrec(2),
       END OF opentab.
DATA : BEGIN OF cleartab OCCURS 0,
         belnr     LIKE bseg-belnr,
         shkzg     LIKE bseg-shkzg,       " D/C indicator
         dmbtr     LIKE bseg-wrbtr,       " Amount
         budat(10),                   " Posting Date
         chect     LIKE payr-chect,       " Check number
         bancd(10),                   " Check Encashment date
         blart     LIKE bkpf-blart,       " Document type
         voidr     LIKE payr-voidr,       " Check void Reason code
         zuonr     LIKE bseg-zuonr,       " Allocation number
         sgtxt     LIKE bseg-sgtxt,       " Text
       END OF cleartab.
DATA : errtab_bnkstmt LIKE input OCCURS 0 WITH HEADER LINE.
DATA : errrec LIKE intab OCCURS 0 WITH HEADER LINE.
DATA : errtab_bnkbook LIKE opentab OCCURS 0 WITH HEADER LINE.
DATA : BEGIN OF match_tab OCCURS 0,
         new_seq(5),
         slno(5),
         identif(15),
         amt(15),
*       AMT(17),
         dr_cr(1),
         chq_rt(13),
         amt1(15),
*       AMT1(17),
         dr_cr1(1),
         void(1),
         encash(1),
         remark(25),
       END OF match_tab.
*----- Internal Table to Trap Errors during Internal Table Validation -*
DATA : BEGIN OF err_vald OCCURS 1000,
         slno(6),
         counter      TYPE i,
         errline(132),              " Error Text
         errcode(2),               " Error Code 1: vald 2: Generic
         " .
         errtyp(1),
       END OF err_vald.

* ---- Internal Table to store BDC data ------*
DATA: BEGIN OF bdctab  .
        INCLUDE STRUCTURE bdcdata.
DATA: END OF bdctab.
DATA: bdcdata LIKE bdctab  OCCURS 1000 WITH HEADER LINE.
*--- Internal table to store system messages during CALL TRANSATION ---*
DATA: BEGIN OF bdcmsg OCCURS 0.
        INCLUDE STRUCTURE bdcmsgcoll.
DATA: END OF bdcmsg.

DATA : BEGIN OF itabmsg OCCURS 0,
         text(100),
       END OF itabmsg.

* ---- Working Variables ---- *
DATA :
  gjahr1           LIKE bkpf-gjahr,
  ans(1),
  temp_AZNUM       LIKE febmka-aznum,
  posn             TYPE i,
  tran_amt         LIKE bseg-wrbtr,
  damt             LIKE bseg-wrbtr,
  camt             LIKE bseg-wrbtr,
  diff_amt         LIKE bseg-wrbtr,
  var_sca(1),
  tran_amt1(15),
*    TRAN_AMT1(17),  " +003

  cl_actno         LIKE ska1-saknr,
  temp_bukrs(3),
  bk_actno         LIKE ska1-saknr,
  flg_match(1)     VALUE 'N',
  err_narr(1)      VALUE 'N',
  err_flg(1)       VALUE 'N',                 " Error flag during validation
  errtxt(132),                          " Error text during validation
  counter(6),                           " Record Counter
  diff             LIKE intab-slno,                 " Difference between 2 ctrl#
  valdt            LIKE sy-datum,                  " Value Date
  trndt            LIKE sy-datum,
  slno             LIKE intab-slno,                 " Control no
  separator(5)     VALUE '     ',           " Separator.
  bal              LIKE bseg-wrbtr,                     " Balance
  diff_bal         LIKE bal, " Diff op_bal and cl_bal
  cnt_diff         LIKE bal,
  tot_transd(17),
  tot_transc(17),
  d_balance(17),
  text(132),
  msgline(100),
  tempchar(1),
  amt_temp1(15),
*    AMT_TEMP1(17),   "+003
  rwbtr            LIKE payr-rwbtr,
  wrbtr1           LIKE payr-rwbtr,
  wrbtr            LIKE bseg-wrbtr,
  match_amt(17),
  match_amt1       LIKE glt0-tsl01,
  trancode(4),
  tcode(5),
  dr_cr(1),
  dif_bal          LIKE input-tran_amt,
  temp_bal         LIKE input-tran_amt,
  err_flag_rec(2)  VALUE '0',
  tot_err_flg      TYPE i,
  reccnt           TYPE i,
  diff_flag(1),
  diff_flag_id(1),
  line             TYPE i,
  sl(5),
  tot_amt_bnkbook  LIKE glt0-tsl01, " By Siladitya 26.03.2003
  reccnt1          LIKE reccnt,
  flg_dupl(1)      VALUE  'Y',
  len2             TYPE i,
  valdt1(10),
  trndt1(10),
  tempdt(10),
  tempdt1          LIKE sy-datum,
  gen_err_cnt      TYPE i,
  match_err_count  TYPE i,
  format_err_count TYPE i,
  rt_count         TYPE i VALUE 0,
  tot_trans(17),
  tot_tran_bnk     LIKE bseg-wrbtr,
  txt              LIKE bseg-sgtxt,
  new_seq(5),
  azdat1(6),
  tempbal(17),
  tempbal1         LIKE bseg-wrbtr,
  posn_opentab     LIKE sy-tabix,
  pre_count        TYPE i VALUE 0,
  file_exist(1),
  param_txt(55),
  param_txt1(55),
  tranamt          LIKE bseg-wrbtr,
  newseq(5),
  cum_bal(17),
  cum_bal1(17),
  tot_tran_amt(17),
  descr            LIKE febmkk-sgtxt_kf,
  rec_upld         TYPE i,
  aznum1           LIKE febmka-aznum,
  amount_1         LIKE glt0-hslvt,
  amount_2         LIKE amount_1,
  amount_3         LIKE amount_1,
  amount_4         LIKE amount_1,
  amount_5         LIKE amount_1,
  amount_6         LIKE amount_1,
  amount_7         LIKE amount_1,




*  Start of change on 06-08-2003  Change Id: 001.
  ist_forex        LIKE TABLE OF bsis,                          "+001
  l_tot_rs_amt     LIKE bsis-dmbtr.                          "+001
*  End of change on 06-08-2003  Change Id: 001.
*begin of <RD1K960036>
CONSTANTS : g_c_asc TYPE char10 VALUE 'ASC'.
*END of <RD1K960036>
DATA l_amt TYPE char15.
* ---- Parameters------*
PARAMETERS: bukrs LIKE t001-bukrs MEMORY ID a, "#EC EXISTS   " Company Code
            hbkid LIKE t012k-hbkid MEMORY ID b, "#EC EXISTS  " House Bank
            hktid LIKE t012k-hktid MEMORY ID c, "#EC EXISTS  " House Bank A/C id
            aznum LIKE febmka-aznum MEMORY ID d, "#EC EXISTS " Statement No
            azdat LIKE febmka-azdat MEMORY ID e OBLIGATORY . "#EC EXISTS
" Statement Date
SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN  BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    opbl   LIKE febmka-ssald MEMORY ID f OBLIGATORY, "#EC EXISTS " Bank Stmt Op. Bal.
    clbl   LIKE febmka-esald MEMORY ID g OBLIGATORY, "#EC EXISTS " Bank Stmt Cl. Bal.
    postdt LIKE bkpf-budat MEMORY ID h ,   "#EC EXISTS   " Posting Date
    kostl  LIKE csks-kostl MEMORY ID k ,   "#EC EXISTS    " Cost Center
    gsber  LIKE tgsb-gsber MEMORY ID z,   "#EC EXISTS    "Business Area
    gjahr  LIKE bseg-gjahr MEMORY ID l.    "#EC EXISTS    " Fiscal Year
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-029.
    PARAMETERS :
                dt_fm LIKE bkpf-budat MEMORY ID m.          "#EC EXISTS
    " Transaction dt to
    SELECTION-SCREEN COMMENT 45(5) TEXT-030.
    PARAMETERS :
                dt_to LIKE bkpf-budat MEMORY ID n. "#EC EXISTS  " Transaction dt fm
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-023.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS vald RADIOBUTTON GROUP grp DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 3(28) TEXT-041.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS brs RADIOBUTTON GROUP grp.
    SELECTION-SCREEN COMMENT 3(28) TEXT-042.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN ULINE.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS bdcsess RADIOBUTTON GROUP grp.
    SELECTION-SCREEN COMMENT 3(19) TEXT-025.
    SELECTION-SCREEN COMMENT 32(17) TEXT-024.
    SELECTION-SCREEN POSITION 52.
    PARAMETERS  session(12)  TYPE c DEFAULT 'BRS'.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN: FUNCTION KEY 1.
*EOC By Arnav on 10/10/26



* ---- Validations at Selection Screen ------ *
INITIALIZATION.

  DATA  :  functxt TYPE smp_dyntxt.
  CLEAR : functxt.
  functxt-text = 'Process Guide/ FAQ'.
  functxt-icon_id = 'ICON_HLP'.
  functxt-icon_text = 'Process Guide/ FAQ'.
  sscrfields-functxt_01 = functxt-text.


AT SELECTION-SCREEN OUTPUT.
*BOC By Arnav on 10/10/26
* ZPFSTATUS belongs to ZFI_CNB_BRS and stays active on the output list,
* where its function codes are not handled -> 'Choose a valid function'
* on Back/Exit. Its only extra (Process Guide button) is disabled anyway.
* Use the standard selection-screen and list status instead.
*  SET PF-STATUS 'ZPFSTATUS'. " added by cab_dns
*EOC By Arnav on 10/10/26

AT SELECTION-SCREEN ON EXIT-COMMAND.

*  IF sscrfields-ucomm EQ 'FC01'. " this is user command for the button
*    " start of code by cab_dns  CR 30012894 <RD1K998453>
*    PERFORM display_process_guide.
*    LEAVE TO SCREEN 1000.
*    " end of code change of cab_dns CR 30012894 <RD1K998453>
*  ENDIF.
IF SY-UCOMM = 'E' OR SY-UCOMM = 'ENDE' OR SY-UCOMM = 'ECAN'.
LEAVE PROGRAM.
ENDIF.


AT SELECTION-SCREEN .

  SELECT SINGLE MAX( aznum ) FROM febko INTO aznum "#EC "#EC CI_NOFIELD Change SAB_ANKUSH - 07.04.2021
                             WHERE bukrs = bukrs
                             AND hktid = hktid.
  IF sy-subrc = 0.
    aznum = aznum + 1 .
  ELSE.
    CLEAR aznum.
  ENDIF.
* selection logic for bk_actno and cl_actno changed on 160301 due
* to change in house bank master customizing. House bank master contains
* main bank account number and not clearing account number as earlier.
  SELECT SINGLE hkont FROM t012k INTO bk_actno
                      WHERE bukrs = bukrs
                      AND   hbkid = hbkid
                      AND   hktid = hktid.
  IF sy-subrc = 0.
    cl_actno = bk_actno + 1.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = cl_actno
      IMPORTING
        output = cl_actno.
    temp_bukrs = bukrs.
    DATA(lv_aznum) = |{ aznum ALPHA = OUT }|.              "S4H FP3 fix
    CONDENSE lv_aznum.                                     "S4H FP3 fix
*    CONCATENATE hktid temp_bukrs aznum+1(4) INTO session. "S4H FP3 fix
    CONCATENATE hktid temp_bukrs lv_aznum INTO session.    "S4H FP3 fix
  ELSE.
    CLEAR session.
  ENDIF.

*--- check If the  company code is valid ----- *
  SELECT SINGLE * FROM t001 WHERE bukrs = bukrs.
  IF sy-subrc NE 0.
    MESSAGE e002 .
  ELSE.
  ENDIF.

*--- Validation for House Bank Id --- *
  SELECT SINGLE * FROM t012k WHERE hbkid = hbkid.
  IF sy-subrc NE 0.
    MESSAGE e003.
  ENDIF.

*--- Validation for Bank Account --- *
  SELECT SINGLE * FROM t012k WHERE hktid = hktid.
  IF sy-subrc NE 0.
    MESSAGE e004.
  ENDIF.

* ---- Validation for  Cost Center ----- *
  SELECT SINGLE *  FROM csks WHERE kostl = kostl. "#EC "#EC CI_GENBUFF  S4HANA Change SAB_ANKUSH - 07.04.2021
  IF sy-subrc NE 0.
    MESSAGE e005.
  ENDIF.
* ----------------- Vailidation for Business Area ------------ *
  SELECT SINGLE * FROM tgsb WHERE gsber = gsber.
  IF sy-subrc NE 0.
    MESSAGE e033.
  ENDIF.

  IF dt_to <> postdt.
    MESSAGE w006.
  ENDIF.

  IF dt_fm > dt_to.
    MESSAGE w007.
  ENDIF.

  IF bukrs  = '' OR
     hbkid  = '' OR
     hktid  = '' OR
     aznum  = '' OR
     azdat  = '' OR
     postdt = '' OR
     dt_fm  = '' OR
     dt_to  = '' OR
     gjahr  = ''.
    MESSAGE e008.
  ENDIF.





START-OF-SELECTION.

  IF vald = 'X'.
* --- Upload Current month Bank statement,Prev month Errors and Bank
* --- Book Records into Internal Tables . The Current month Bnk stmt
* ---and Prev month Error files are merged into a single internal table*

***Changes has taken place on 06.08.2002 By Siladitya
    PERFORM upload_file.

* --- Validation of Format Errors and Generic Errors in the Internal Tab
    PERFORM format_generic_error_check.

* --- Derive Transaction Codes based on Narration and Clearing A/C no -*
    PERFORM derive_other_fields.

* ---- Matching Errors ---- *
    PERFORM validation_error_check.

* --- Download Bank Stmt, Bank Book to file system ----- *
    PERFORM dumping_tofilesystem.
  ENDIF.

* ---- Display Validation Errors ----- *
  IF vald = 'X' .
    IF format_err_count > 0 OR  gen_err_cnt > 0 OR match_err_count > 0.
      PERFORM disp_vald.
    ENDIF.
  ENDIF.

  IF brs = 'X'.
    line = 0.
    DESCRIBE TABLE intab LINES line.
    IF line > 0.
      file_exist = 'Y'.
    ELSEIF line = 0.
      PERFORM upload_bankstmt_fromfile.
    ENDIF.
    line = 0.
    file_exist = 'N'.
    DESCRIBE TABLE opentab LINES line.
    IF line > 1.
      file_exist = 'Y'.
    ELSEIF line = 0.
      PERFORM upload_bankbook_fromfile.
    ENDIF.

    IF file_exist = 'Y'.
*on 4-2-2001 as told by Rohit - kameswari
      PERFORM disp_error_rep10.
*on 4-2-2001 as told by Rohit - kameswari

* Display Unmatched Bank Statements Entries-Debit and Credit rep 1,2 *
      PERFORM bank_stmt_unmatched.


*----- Display Bank statement Transfers rep 3---- *
      PERFORM bankstmt_transfers.

* ---- Display  Bank Charges from Bank statement rep 4------*
      PERFORM bank_charges.
* ---- Display Interest Charges from Bank Statement rep 5------*
      PERFORM int_charges.
* ---- Display Interest Credited from Bank Statement rep 6------ *
      PERFORM int_credited.
* ---- Display Unmatched Bankbook Entries-Debit and Credit rep 7,8--- *
      PERFORM unmatched_bnk_book.

* ---- Display Bankbook Transfers rep 9------- *
***Change on  29.08.2001 by Siladitya reqest from Rohit
      PERFORM bankbook_transfers.
* ---- Dispaly Clear documents rep 10---- *

****Changes has taken place in this Subroutine on 06.08.2002
      PERFORM clear_itm_bankbook.

*---Display Matched Bank statement Entries Debit and Credit for SCA--- *
* Included on 4-2-2001 as told by Rohit - kameswari
*      PERFORM matched_bnk_stmt_sca.
* Included on 4-2-2001 as told by Rohit - kameswari
* Display matched Bank Statements Entries-Debit and Credit rep 11,12-- *
      PERFORM bank_stmt_matched.
* ---- Display Matched Bankbook Entries-Debit and Credit rep 13,14---- *
      PERFORM matched_bnk_book.
*---Display Matched Bank statement Entries Debit and Credit for SCA--- *
* Included on 4-2-2001 as told by Rohit rep 15- kameswari
      PERFORM matched_bnk_stmt_sca.
* Included on 4-2-2001 as told by Rohit - kameswari

*********************************************************************
*  CHANGE HISTORY
*  MODIFICATION DATE  CHANGED BY     DESCRIPTION
*  06-08-2003         B.S. BHATIA    UNMATCHED FOREX RECEIPTS REPORT
*  LOGIN ID: CAB_BHATIABS
*  FS: FS-FI-BA-06 VER:1.0
**********************************************************************
*  Start of change on 06-08-2003.
      PERFORM get_unmatched_forex_data.
      PERFORM unmatched_bnk_book_forex_rcpt.                "0001+
*  End of change on 06-08-2003.
    ELSE.
      STOP.
    ENDIF.
  ENDIF.

* ----- Upload Program ----- *
  IF bdcsess = 'X'.
*BOC By Arnav on 10/10/26
* Upload no longer depends on validation results: Report 15 balance
* check does not block it any more (steps 1 and 2 are information only).
*   IMPORT diff_flag FROM MEMORY ID diff_flag_id.
*   IF diff_flag = 'X'.
    CLEAR diff_flag.
    IF diff_flag = 'X'.
*EOC By Arnav on 10/10/26
      SKIP 2.
      FORMAT COLOR 4 INTENSIFIED OFF.
      WRITE:/15 icon_breakpoint AS ICON,20
      'Balance of Report15 is not zero,Please Check the entries'.
    ELSE.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Bank Reconciliation Data Uploading '
          text_question         = TEXT-045
          text_button_1         = 'Yes'
          text_button_2         = 'No'
          default_button        = '1'
          display_cancel_button = ' '
          start_column          = 9
          start_row             = 6
        IMPORTING
          answer                = ans
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.

      IF ans = '1'.
        line = 0.
        file_exist = 'N'.
        DESCRIBE TABLE intab LINES line.
        IF line > 0.
          file_exist = 'Y'.
        ELSEIF line = 0.
          PERFORM upload_bankstmt_fromfile.
        ENDIF.


        IF file_exist = 'Y'.
* ---- Upload Program ------ *
          PERFORM upload_bdc_program.

        ELSE.
          STOP.
        ENDIF.
      ELSE.
        STOP.
      ENDIF.
    ENDIF.
  ENDIF.

*---------------------------------------------------------------------*
*       FORM UPLOAD_FILE                                              *
*       Upload the data from text file to internal table ftab         *
*---------------------------------------------------------------------*
FORM upload_file.
*begin of <RD1K960036>
* ----- Upload brs input file for the current month ---- *
*  CALL FUNCTION 'UPLOAD'
*       EXPORTING
*            filename            = 'C:\brs\input\'
*            filetype            = 'DAT'
*            item                = 'Read File for BRS'
*       TABLES
*            data_tab            = input
*       EXCEPTIONS
*            conversion_error    = 1
*            invalid_table_width = 2
*            invalid_type        = 3.
*
*  IF sy-subrc <> 0.
*    WRITE:/ 'Unable to open dataset'.
*
*  ENDIF.
  DATA : i_file_table TYPE  TABLE OF file_table,
         l_filetable  TYPE  file_table,
         l_rc         TYPE  i,
         l_p_def_file TYPE  string,
         l_p_file     TYPE  string,
         l_usr_act    TYPE  i,
         l_title      TYPE string.

  l_title = 'Read File for BRS'.
  l_p_def_file = 'C:\brs\input\'.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = l_title
      initial_directory       = l_p_def_file
    CHANGING
      file_table              = i_file_table
      rc                      = l_rc
      user_action             = l_usr_act
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  IF sy-subrc = 0
        AND l_usr_act <>
        cl_gui_frontend_services=>action_cancel.


    LOOP AT i_file_table  INTO l_filetable.
      l_p_file = l_filetable.
      EXIT.
    ENDLOOP.


    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = l_p_file
        filetype                = g_c_asc
        has_field_separator     = 'X'
      TABLES
        data_tab                = input
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        OTHERS                  = 17.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDIF.

*end of <RD1K960036>
  DESCRIBE TABLE input LINES line.
  IF line = 0.
    STOP.
  ENDIF.
* ---- Upload the error brs file of the previous month ----*
*begin of <RD1K960036>
*  CALL FUNCTION 'WS_UPLOAD'
*       EXPORTING
*            filename        = 'C:\BRS\prevmonth.txt'
*            filetype        = 'DAT'
*       TABLES
*            data_tab        = input1
*       EXCEPTIONS
*            file_open_error = 2
*            file_read_error = 3.
  DATA l_p_file1 TYPE string.
  l_p_file1 = 'C:\BRS\prevmonth.txt'.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = l_p_file1
      filetype                = g_c_asc
      has_field_separator     = 'X'
    TABLES
      data_tab                = input1
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
*  IF SY-SUBRC NE 0.
*    MESSAGE E033 WITH l_P_FILE ' could not be opened'(E03).
*  ENDIF.

*end of <RD1K960036>
  DESCRIBE TABLE input1 LINES line.

  IF line <= 1.
    text = TEXT-037.
    CONCATENATE space text   INTO errtxt SEPARATED BY separator.
    PERFORM append_generic_err TABLES err_vald USING 'W' '0'.
  ELSEIF line > 1.
    aznum1 = aznum - 1.
    DATA(lv_aznum1) = |{ aznum1 ALPHA = OUT }|.              "S4H FP3 fix
    CONDENSE lv_aznum1.                                     "S4H FP3 fix
*    CONCATENATE bukrs aznum1  hbkid hktid  INTO param_txt1. "S4H FP3 fix
    CONCATENATE bukrs lv_aznum1  hbkid hktid  INTO param_txt1. "S4H FP3 fix
    READ TABLE input1 INDEX 1 .
    CONDENSE input1-narration.
    CONDENSE param_txt1.
    IF input1-narration = param_txt1.
* ---- Merge previous month brs input into the current month input ---

      APPEND LINES OF input1 FROM 2 TO input.

    ELSE.
      text = TEXT-044.
      CONCATENATE space text   INTO errtxt SEPARATED BY separator.
      PERFORM append_generic_err TABLES err_vald USING 'W' '0'.
    ENDIF.
  ENDIF.


* ----- derive trancode ,chkno,RT# from and store into intab. ---- *
  LOOP AT input.
    intab-slno =    input-slno.
    intab-actno = input-actno.
    intab-valdt = input-valdt.
    intab-tran_dt = input-tran_dt.
    intab-tran_amt = input-tran_amt.
    intab-dr_cr =   input-dr_cr.
    intab-cum_bal = input-cum_bal.
    intab-dr_cr1 =  input-dr_cr1.
    intab-narration = input-narration.
    intab-errrec = '0'.
    TRANSLATE intab-narration TO UPPER CASE.
    TRANSLATE intab-dr_cr TO UPPER CASE.
    TRANSLATE intab-dr_cr1 TO UPPER CASE.
    CONDENSE intab-tran_amt.
    CONDENSE intab-cum_bal.
    APPEND intab.
  ENDLOOP.
* This Subroutine has changed on 06.08.2002  Request from Mr. Iqbal Aham
  PERFORM get_opentab.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DATA_VALIDATION
*&---------------------------------------------------------------------*
FORM format_generic_error_check.
* Changes Done for Serial Number issue - Unicode
  DATA: zlv_typ1 TYPE dd01v-datatype,
        zlv_typ2 TYPE dd01v-datatype.
* End Changes
  cum_bal =  opbl * 100.
  LOOP AT intab FROM 2.

    reccnt = sy-tabix.
    flg_match = 'N'.
    flg_dupl = 'N'.
    tot_err_flg = 0.
    err_flag_rec = '0'.
    err_narr = 'N'.
    counter = counter + 1.
*   Changes Done for Serial Number Issue - Unicode
*   End Changes
    IF intab-slno(1) <> 'P' AND slno(1) <> 'P'.

      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in = intab-slno
        IMPORTING
*         STRING_OUT       =
          htype     = zlv_typ1.

      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in = slno
        IMPORTING
*         STRING_OUT       =
          htype     = zlv_typ2.
      IF zlv_typ1 = 'NUMC' AND zlv_typ2 = 'NUMC'.
*      if intab-slno co '0123456789' AND slno co '0123456789'.
        CLEAR: zlv_typ1, zlv_typ2.
        diff = intab-slno - slno.
        CONDENSE diff.
      ENDIF.
    ENDIF.
* --- Check if Control no. contains value other than numbers  --- *
    IF NOT ( intab-slno CO '0123456789P ').
*   concatenate intab-slno sy-vline  into errtxt separated by separator.
      err_vald-slno = intab-slno.
      errtxt = TEXT-003 .
      PERFORM append_format_err TABLES err_vald USING 'E' '1' .

    ENDIF.
* --- Check if Control no is 1 more than the last control no --- *
    IF diff <> '1' AND counter > 1 AND intab-slno(1) <> 'P'.
*   concatenate intab-slno sy-vline into errtxt  separated by separator.
      err_vald-slno = intab-slno.
      errtxt = TEXT-003 .
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.

*Step1- Convert Internal table date into internal date format YYYYMMDD-*
    IF intab-valdt(2) = '99'.
      CONCATENATE '19' intab-valdt INTO valdt.
    ELSE.
      CONCATENATE '20' intab-valdt INTO valdt.
    ENDIF.
*Step2- Convert internal date format to external date as in user default
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = valdt
      IMPORTING
        date_external            = valdt1
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.

*Step3- Convert external date into input format which checks if a date
* format is proper (sy-subrc = 0)
*begin of <RD1K960036>
*    CALL FUNCTION 'CONVERT_DATE_INPUT'
*         EXPORTING
*              input                     = valdt1
*              plausibility_check        = 'X'
*         IMPORTING
*              output                    = valdt
*         EXCEPTIONS
*              plausibility_check_failed = 1
*              wrong_format_in_input     = 2
*              OTHERS                    = 3.
    CALL FUNCTION 'CONVERT_DATE_WITH_THRESHOLD'
      EXPORTING
        input                     = valdt1
        plausibility_check        = 'X'
      IMPORTING
        output                    = valdt
      EXCEPTIONS
        plausibility_check_failed = 1
        wrong_format_in_input     = 2
        OTHERS                    = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*end of <RD1K960036>
    IF sy-subrc <> 0.
      text = TEXT-032.
      err_vald-slno = intab-slno.
      CONCATENATE  text(12) intab-valdt text+12(11)
                                         INTO errtxt SEPARATED BY space.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.

    ELSEIF sy-subrc = 0.
      IF intab-valdt(2) = '99'.
        CONCATENATE '19' intab-valdt INTO tempdt.
      ELSEIF intab-valdt(2) = '00'.
        CONCATENATE '20' intab-valdt INTO tempdt.
      ENDIF.
* ---- Check if Value date is less than Statement date--- *
      IF tempdt > azdat.
        text = TEXT-004.
        err_vald-slno = intab-slno.
        azdat1 = azdat+2(6).
        CONCATENATE text(10) intab-valdt text+10(31) azdat1
                                         INTO errtxt SEPARATED BY space.
        PERFORM append_format_err_w TABLES err_vald USING 'W' '0'.

      ENDIF.
    ENDIF.

* ---- Transaction date not valid ------ *
*Step1- Convert Internal table date into internal date format YYYYMMDD-*
    IF intab-tran_dt(2) = '99'.
      CONCATENATE '99' intab-tran_dt INTO trndt.
    ELSE.
      CONCATENATE '20' intab-tran_dt INTO trndt.
    ENDIF.
*Step2- Convert internal date format to external date as in user default
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = trndt
      IMPORTING
        date_external            = trndt1
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.

*Step3- Convert external date into input format which checks if a date
* format is proper (sy-subrc = 0)
*begin of <RD1K960036>
*    CALL FUNCTION 'CONVERT_DATE_INPUT'
*         EXPORTING
*              input                     = trndt1
*              plausibility_check        = 'X'
*         IMPORTING
*              output                    = trndt
*         EXCEPTIONS
*              plausibility_check_failed = 1
*              wrong_format_in_input     = 2
*              OTHERS                    = 3.
    CALL FUNCTION 'CONVERT_DATE_WITH_THRESHOLD'
      EXPORTING
        input                     = trndt1
        plausibility_check        = 'X'
      IMPORTING
        output                    = trndt
      EXCEPTIONS
        plausibility_check_failed = 1
        wrong_format_in_input     = 2
        OTHERS                    = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*end of <RD1K960036>
    IF sy-subrc <> 0.
      text = TEXT-028.
      err_vald-slno = intab-slno.
      CONCATENATE  text(18) intab-tran_dt text+18(11)
                                         INTO errtxt SEPARATED BY space.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.
* --- Check for Debit/Credit indicator --- *
    IF NOT ( intab-dr_cr = 'C' OR  intab-dr_cr = 'D' ).
      text  = TEXT-006.
      err_vald-slno = intab-slno.
      CONCATENATE  text(23) intab-dr_cr text+23(20)
                                         INTO errtxt SEPARATED BY space.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.

    ENDIF.

* ---- Narration should not be blank -----*
    IF intab-narration IS INITIAL.
      err_vald-slno = intab-slno.
      errtxt = TEXT-038.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.
* ----- Duplicate Narration ------- *
    IF intab-narration <> 'BCH' AND intab-narration <> 'INT' AND
    intab-narration <> 'INC' AND intab-narration <> 'SI'
    AND intab-narration <> 'SCA'.
      posn = 0.
      LOOP AT input WHERE narration = intab-narration.
        posn = posn + 1.
      ENDLOOP.
      IF posn > 1.
        err_vald-slno = intab-slno.
        errtxt = TEXT-027.
        PERFORM append_format_err TABLES err_vald USING 'E' '1'.
      ENDIF.
    ENDIF.
* ---- Amt can not be blank and should only contain numeric char -----*
    IF intab-tran_amt IS INITIAL.
      err_vald-slno = intab-slno.
      errtxt = TEXT-039.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ELSEIF NOT ( intab-tran_amt CO '1234567890 ' ).
      err_vald-slno = intab-slno.
      errtxt = TEXT-026.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.
    IF intab-slno(1) <> 'P'.
* ---- Cum bal can not be blank and should contain numeric char -----*
      IF intab-cum_bal IS INITIAL.
        err_vald-slno = intab-slno.
        errtxt = TEXT-040.
        PERFORM append_format_err TABLES err_vald USING 'E' '1'.
      ELSEIF NOT ( intab-cum_bal CO '1234567890 ' ).
        err_vald-slno = intab-slno.
        errtxt = TEXT-026.
        PERFORM append_format_err TABLES err_vald USING 'E' '1'.
      ENDIF.
    ENDIF.
    IF NOT ( intab-narration CO '0123456789 ' OR
      ( ( intab-narration(1) = 'R' OR  intab-narration(1) = 'D'
             OR intab-narration(1) = 'C' ) AND
                               intab-narration+1(6)  CO '0123456789 ' )
            OR intab-narration = 'BCH' OR intab-narration = 'INT'
                      OR intab-narration = 'INC'
                      OR intab-narration = 'SI' OR intab-narration =
                     'SCA' ).
      err_vald-slno = intab-slno.
      errtxt = TEXT-021.
      CONCATENATE errtxt '-' intab-narration INTO errtxt.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.
    err_narr = 'N'.
* ---- Narration does not match with DR/CR indicator -------*
    IF intab-narration CO '0123456789 ' AND intab-dr_cr <> 'D'.
      err_narr = 'Y'.
    ELSEIF intab-narration(1) = 'R' AND intab-narration+1(6)
            CO '0123456789 ' AND    intab-dr_cr <> 'C'.
      err_narr = 'Y'.
    ELSEIF intab-narration(1) = 'D' AND intab-narration+1(6)
            CO '0123456789 ' AND intab-dr_cr <> 'D'.
      err_narr = 'Y'.
    ELSEIF intab-narration(1) = 'C' AND intab-narration+1(6)
            CO '0123456789 ' AND  intab-dr_cr <> 'C'.
      err_narr = 'Y'.
    ELSEIF intab-narration(3) = 'BCH' AND  intab-dr_cr <> 'D'.
      err_narr = 'Y'.
    ELSEIF intab-narration(3) = 'INT' AND  intab-dr_cr <> 'D'.
      err_narr = 'Y'.
    ELSEIF intab-narration(3) = 'INC' AND  intab-dr_cr <> 'C'.
      err_narr = 'Y'.
    ENDIF.
    IF err_narr = 'Y'.
      err_vald-slno = intab-slno.
      errtxt = TEXT-035.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.

*--- If the total_err_flag for a Record is > '0' then it is a unmatch -*
*--- Record else it is match record ; Modify the error field of intab *

* ---- Total the amount considering the debit and credit indicator ---*
    IF intab-tran_amt CO '1234567890 ' AND  intab-slno(1) <> 'P'.
      tranamt = intab-tran_amt / 100.
      IF intab-dr_cr = 'D'.
        bal = bal + tranamt.
        cum_bal = cum_bal + intab-tran_amt.
      ELSEIF intab-dr_cr = 'C'.
        bal = bal - tranamt.
        cum_bal = cum_bal - intab-tran_amt.
      ENDIF.
      IF intab-tran_amt CO '1234567890 ' .
        IF intab-dr_cr1 = 'D'.
          cum_bal1 = 0 + intab-cum_bal.
        ELSEIF intab-dr_cr1 = 'C'.
          cum_bal1 = 0 - intab-cum_bal.
        ENDIF.
      ENDIF.
      IF cum_bal <> cum_bal1.
        text = TEXT-036.
        err_vald-slno = intab-slno.

        CONCATENATE text(7) intab-cum_bal text+7(24) cum_bal
                                         INTO errtxt SEPARATED BY space.
        PERFORM append_format_err TABLES err_vald USING 'E' '1'.
      ENDIF.
    ENDIF.
    intab-errrec = tot_err_flg.
    MODIFY intab FROM intab INDEX reccnt.
    slno = intab-slno.
  ENDLOOP.

* ---- if prev month table intab1 contains records then deduct that ---*
* ---- from the bal so that the diff of open bal and cl. bal can be----*
* ----- matched only with current months amount -------*
*--- Check Diff of op.bal and Cl.bal does not tally with sum of amount-*
  diff_bal = clbl - opbl.
  IF diff_bal NE bal.
***S/4 Start of Change - SAP_ABAP5 — TR RP1K951283   – 2022/05/27
*    dif_bal =  diff_bal.
    dif_bal = CONV #(  diff_bal ).
***S/4 End of Change - SAP_ABAP5— TR RP1K951283  – 2022/05/27
***S/4 Start of Change - SAP_ABAP5 — TR RP1K951283   – 2022/05/27
*    temp_bal = bal.
    temp_bal = CONV #( bal ).
***S/4 End of Change - SAP_ABAP5— TR RP1K951283  – 2022/05/27
    CONDENSE temp_bal.
    CONDENSE dif_bal.
    text = TEXT-017.
    CONCATENATE space text(38)  INTO errtxt SEPARATED BY separator.
    CONCATENATE  errtxt  temp_bal text+39(74) dif_bal
   INTO errtxt SEPARATED BY space.
    PERFORM append_generic_err TABLES err_vald USING 'E' '1'.
  ENDIF.
ENDFORM.                               " DATA_VALIDATION

*&---------------------------------------------------------------------*
*&      Form  DISP_VALD
*&---------------------------------------------------------------------*
FORM disp_vald.
  DATA : htype TYPE dd01v-datatype.
  WRITE :/20 'BRS Validation Errors / Messages ' COLOR 1 INTENSIFIED ON.
  IF format_err_count > 0.
    SKIP.
    IF err_flg = 'Y'.
      WRITE :/ sy-uline.
      FORMAT COLOR 4.
      WRITE / : 'Record No'.
      WRITE sy-vline.
      WRITE: icon_message_error AS ICON,
*begin of <RD1K960036>
*       '           F O R M A T   E R R O R   D E T A I L S '&
*                                      '.
       '           F O R M A T   E R R O R   D E T A I L S'
&'                                     '.
*end of <RD1K960036>
      WRITE sy-vline.
      WRITE 'Error Type'.
      WRITE :/ sy-uline.
    ENDIF.
    FORMAT COLOR 2 INTENSIFIED ON.
    SORT err_vald BY counter.
    LOOP AT err_vald WHERE errcode = '1'.
      WRITE : /1 err_vald-slno,
               10 sy-vline, 12 err_vald-errline, 83 sy-vline ,
              90 err_vald-errtyp.
    ENDLOOP.
    WRITE sy-uline.
    WRITE :/ ' Do  not Proceed until All Format Errors are Corrected '.
  ENDIF.
  IF gen_err_cnt > 0.
*---- Generic Errors ---- *
    SKIP 2.
    WRITE sy-uline.
    FORMAT COLOR 6 INTENSIFIED ON.
*begin of <RD1K960036>
*  WRITE '            G E N E R I C     E R R O R S
*                                                '.
    WRITE '            G E N E R I C     E R R O R S'
    &'                                             '.
*end of <RD1K960036>
    WRITE :/ sy-uline.
    FORMAT COLOR 2 INTENSIFIED ON.
    sl = space.
    LOOP AT err_vald WHERE errcode = '2'.
      sl = sl + 1.
      IF err_vald-errtyp = 'E'.
        WRITE : /1 sl,5 icon_message_critical AS ICON ,
   8 err_vald-errline(77) ,   86 '                                    '.
*begin of <RD1K960036>
*        WRITE : /13 err_vald-errline+77(55),
*      69 '
*                                                           '.
        WRITE : /13 err_vald-errline+77(55),
      69 '    '
                                                     &'      '.
*end of <RD1K960036>
      ELSEIF err_vald-errtyp = 'W'.
        WRITE : /1 sl,8 err_vald-errline(77) ,
              86 '                                                 '.
        WRITE : /13 err_vald-errline+77(55),
      69 '                                                            '.


*WRITE '
*                                   '.
        WRITE ''
        &'                                   '.
      ENDIF.
    ENDLOOP.
    SKIP.
    WRITE :/ sy-uline.
  ENDIF.

*----- Matching Errors ------*
  IF match_err_count > 0.
    SKIP 2.
*    WRITE sy-uline.
    WRITE AT 1(93) sy-uline.
    NEW-LINE.
    FORMAT COLOR 5 INTENSIFIED ON.
    WRITE sy-vline.
*    WRITE : icon_message_error AS ICON,
*                      '                 M A T C H I N G      E R R O R S
*                                   '.
    WRITE : icon_message_error AS ICON,
                         '                 M A T C H I N G      E R R O R S'
    &'                                  '.
    WRITE sy-vline.

*    WRITE :/ sy-uline.
    NEW-LINE.
    WRITE AT 1(93) sy-uline.
*begin of <RD1K960036>
*WRITE :/1 sy-vline , 20 ' Bank Statement ', 50 sy-vline , 55 'Bank
*book',93 sy-vline.
    WRITE :/1 sy-vline , 20 ' Bank Statement ', 50 sy-vline , 55 'Bank'
    &'book',93 sy-vline.
*begin of <RD1K960036>
*    WRITE :/ sy-uline.
    NEW-LINE.
    WRITE AT 1(93) sy-uline.
    WRITE :/1 sy-vline,2 'Rec#' , 10 '   Narration' , 30 'D/C',
    33 '  Trans. Amount' ,
    50 sy-vline,51 'Doc. No' ,62 ' D/C' , 67 ' Doc. Amt'  ,
     84 ' Encashed', 93 sy-vline.
*    WRITE :/ sy-uline.
    NEW-LINE.
    WRITE AT 1(93) sy-uline.
    FORMAT COLOR 2 INTENSIFIED ON.

    LOOP AT match_tab.
      match_amt = match_tab-amt.
*      IF match_amt CA '1234567890'.
      CALL FUNCTION 'NUMERIC_CHECK'
        EXPORTING
          string_in  = match_amt
        IMPORTING
          string_out = match_amt
          htype      = htype.
      IF htype EQ 'NUMC'.

        match_amt1 = match_amt / 100.
      ENDIF.
      IF match_tab-new_seq <> newseq.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*        WRITE : /1 sy-vline,
*                 2 match_tab-slno, 9 sy-vline ,
*                 10 match_tab-identif,29 sy-vline,
*                 30 match_tab-dr_cr, 32 sy-vline,
*                 33 match_amt1.

        CLEAR l_amt.
        l_amt =  match_amt1.
*CONDENSE l_amt.

        WRITE : /1 sy-vline,
                 2 match_tab-slno, 9 sy-vline ,
                 10 match_tab-identif,29 sy-vline,
                 30 match_tab-dr_cr, 32 sy-vline,
                 33 l_amt.                   "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
      ELSE.
        WRITE : /1 sy-vline,
                  2 space, 9 sy-vline ,
                 10 space,29 sy-vline,
                 30 space, 32 sy-vline,
                 33 space.
      ENDIF.
      CLEAR l_amt.
      l_amt =  match_amt1.
*CONDENSE l_amt.
      WRITE :  50 sy-vline,
               51 match_tab-chq_rt,62 sy-vline,
               63 match_tab-dr_cr1,66 sy-vline,
               67 l_amt,84  sy-vline,
              85 match_tab-encash,93 sy-vline.
      newseq = match_tab-new_seq.
    ENDLOOP.
*    SKIP.
*    WRITE :/ sy-uline.
    NEW-LINE.
    WRITE AT 1(93) sy-uline.

  ENDIF.

ENDFORM.                               " DISP_VALD

*&---------------------------------------------------------------------*
*&      Form  BANK_STMT
*&---------------------------------------------------------------------*
FORM bank_stmt_unmatched.
  PERFORM write_bankstmt_debit_unmat.
  PERFORM write_bankstmt_credit_unmat.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BNK_CLR_D
*&---------------------------------------------------------------------*
FORM unmatched_bnk_book.
  SKIP 5.
  FORMAT COLOR 4 INTENSIFIED OFF.
  ULINE.
*begin of <RD1K960036>
*WRITE : / 'Report7:',icon_page_right AS ICON ,      'U N M A T C H E D
* b a n k   b o o k    e n t r i e s - debit' ,icon_page_left AS ICON,'
*            '.
  WRITE : / 'Report7:',icon_page_right AS ICON ,      'U N M A T C H E D'
   &'b a n k   b o o k    e n t r i e s - debit' ,'icon_page_left AS ICON,'
  &'            '.
*end of <RD1K960036>
  ULINE.
  WRITE :/1 'Allocation' ,12 'Doc No', 25 'cheque no',
   37 'Doc.Typ' ,42 'Post date',55 'Amount in Rs.',
   72 'Description                                 '.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_amt_bnkbook = 0.
  line = 0.
  LOOP AT opentab WHERE errrec <> '0' AND shkzg = 'S' AND zuonr <>
                                                   'TRANBRS'.
    line = line + 1.
    tot_amt_bnkbook = tot_amt_bnkbook + opentab-dmbtr.
    IF opentab-shkzg = 'H'.
      dr_cr = 'C'.
    ELSEIF opentab-shkzg = 'S'.
      dr_cr = 'D'.
    ENDIF.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE : /1 opentab-zuonr, 10 sy-vline,
*             12  opentab-belnr ,23 sy-vline,
*             25  opentab-chect,35 sy-vline,
*             37 dr_cr, 40 sy-vline,
*             42 opentab-budat,53 sy-vline,
*             55 opentab-dmbtr,71 sy-vline,
*             72 opentab-sgtxt.

    CLEAR l_amt.
    l_amt = opentab-dmbtr.
*CONDENSE l_amt.

    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37 dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
             55 l_amt,                       "#EC CI_FLDEXT_OK[2610650]
             71 sy-vline,
             72 opentab-sgtxt.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDLOOP.
  ULINE.

  IF line = 0.
    WRITE : / 'No Bank Clearing Account Open items for Debit              '.
  ELSE.
    ULINE.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/35 'Total Rs.' , tot_amt_bnkbook.
    WRITE :/35 'Total Rs.' , tot_amt_bnkbook. "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.
  SKIP 5.

  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report8:',icon_page_right AS ICON ,      'U N M A T C H E D'
*&'b a n k   b o o k    e n t r i e s - credit' ,icon_page_left AS ICON,'
*            '.
  WRITE : / 'Report8:',icon_page_right AS ICON ,      'U N M A T C H E D'
  &'b a n k   b o o k    e n t r i e s - credit' ,icon_page_left AS ICON,''
              &''.
*end of <RD1K960036>
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.

  WRITE :/1 'Allocation' ,12 'Doc No', 25 'cheque no',
   37 'Doc.Typ' ,42 'Post date',55 '  Amount',
   72 'Description                                 '.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_amt_bnkbook = 0.
  line = 0.
  LOOP AT opentab WHERE errrec <> '0' AND shkzg = 'H' AND zuonr <>
                                                              'TRANBRS'.
    line = line + 1.
    IF opentab-shkzg = 'H'.
      dr_cr = 'C'.
    ELSEIF opentab-shkzg = 'S'.
      dr_cr = 'D'.
    ENDIF.

***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE : /1 opentab-zuonr, 10 sy-vline,
*             12  opentab-belnr ,23 sy-vline,
*             25  opentab-chect,35 sy-vline,
*             37 dr_cr, 40 sy-vline,
*             42 opentab-budat,53 sy-vline,
*             55 opentab-dmbtr,71 sy-vline,
*             72 opentab-sgtxt.

    CLEAR l_amt.
    l_amt = opentab-dmbtr.
    "CONDENSE l_amt.

    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37 dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
             55 l_amt,                       "#EC CI_FLDEXT_OK[2610650]
             71 sy-vline,
             72 opentab-sgtxt.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    tot_amt_bnkbook = tot_amt_bnkbook - opentab-dmbtr.
  ENDLOOP.
  ULINE.


  IF line = 0.
    WRITE : / 'No Bank Clearing Account Open items for Credit             '.
  ELSE.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/50 'Total Rs.',tot_amt_bnkbook .
    WRITE :/50 'Total Rs.',tot_amt_bnkbook . "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  APPEND_FORMAT_ERR
*&---------------------------------------------------------------------*
FORM append_format_err TABLES err_vald STRUCTURE err_vald
                                                 USING errtyp flag_rec .
  err_vald-counter = counter.
  err_vald-errline = errtxt.
  err_vald-errcode = '1'.
  err_vald-errtyp = errtyp.
  APPEND err_vald.
  format_err_count = format_err_count + 1.
  err_flag_rec = flag_rec.
  err_flg = 'Y'.
  tot_err_flg = tot_err_flg + 1.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM APPEND_FORMAT_ERR_W                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ERR_VALD                                                      *
*  -->  ERRTYP                                                        *
*  -->  FLAG_REC                                                      *
*---------------------------------------------------------------------*
FORM append_format_err_w TABLES err_vald STRUCTURE err_vald
                                                 USING errtyp flag_rec .
  err_vald-counter = counter.
  err_vald-errline = errtxt.
  err_vald-errcode = '1'.
  err_vald-errtyp = errtyp.
  APPEND err_vald.
  format_err_count = format_err_count + 1.
  err_flag_rec = flag_rec.
  err_flg = 'Y'.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM APPEND_MATCH_ERR                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ERR_VALD                                                      *
*  -->  ERRTYP                                                        *
*  -->  FLAG_REC                                                      *
*---------------------------------------------------------------------*
FORM append_match_err TABLES err_vald STRUCTURE err_vald
                                                 USING errtyp flag_rec .

  err_vald-counter = counter.
  err_vald-errline = errtxt.
  err_vald-errcode = '3'.
  err_vald-errtyp = errtyp.
  APPEND err_vald.
  match_err_count = match_err_count + 1.
  err_flag_rec = flag_rec.
  err_flg = 'Y'.
  tot_err_flg = tot_err_flg + 1.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM APPEND_GENERIC_ERR                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ERR_VALD                                                      *
*  -->  ERRTYP                                                        *
*  -->  FLAG_REC                                                      *
*---------------------------------------------------------------------*
FORM append_generic_err TABLES err_vald STRUCTURE err_vald
                                                 USING errtyp flag_rec .
  err_vald-errline = errtxt.
  err_vald-errcode = '2'.
  err_vald-errtyp = errtyp.
  APPEND err_vald.
  gen_err_cnt = gen_err_cnt + 1.
  err_flag_rec = flag_rec.
  err_flg = 'Y'.
  tot_err_flg = tot_err_flg + 1.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BRS_REPORT
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  WRITE_BANK_STMT_DEBIT
*&---------------------------------------------------------------------*
FORM write_bankstmt_debit_unmat.
  NEW-PAGE .
  SKIP 4.
  FORMAT COLOR OFF.
  WRITE :/20 'Bank Reconciliation  Reports ' COLOR 1 INTENSIFIED ON.
  SKIP 2.
  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report1: ', icon_page_right AS ICON,  'U N M A T C H E D
*   d e b i t    b a n k   s t a t e m e n t ',icon_page_left AS ICON,
*'
  WRITE : / 'Report1: ', icon_page_right AS ICON,  'U N M A T C H E D'
  &'d e b i t    b a n k   s t a t e m e n t ',icon_page_left AS ICON,
  '                           '.
  ULINE.
  WRITE :/3 'Rec.No',13 'Value date',30 'D/C' ,37 'Amount in Rs.',
      57 '           Narration'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_tran_amt = 0.
  LOOP AT intab FROM 2.
    IF intab-dr_cr = 'D' AND intab-errrec <> '0' AND intab-tcode <> 'TRAN'.
      IF  NOT ( intab-tran_amt IS INITIAL )
                                AND intab-tran_amt CO '1234567890 '.
        tot_tran_amt =  tot_tran_amt - intab-tran_amt.
      ENDIF.
      match_amt = intab-tran_amt .
      match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,11 sy-vline,
*               13 intab-valdt,28 sy-vline,
*               30 intab-dr_cr,35 sy-vline,
*               37 match_amt1,57 sy-vline,
*               59 intab-narration,92 sy-vline.

      CLEAR l_amt.
      l_amt =  match_amt1.
      "CONDENSE l_amt.

      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               57 sy-vline,
               59 intab-narration,92 sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ENDIF.
  ENDLOOP.
  ULINE.
  match_amt = tot_tran_amt.
  match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*  WRITE :/15 'Total amt (in Rs.):',
*          37 match_amt1.

  WRITE :/15 'Total amt (in Rs.):',
          37 match_amt1.                     "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ULINE.
ENDFORM.                               " WRITE_BANK_STMT_DEBIT

*&---------------------------------------------------------------------*
*&      Form  WRITE_BANK_STMT_CREDIT
*&---------------------------------------------------------------------*
FORM write_bankstmt_credit_unmat.
  NEW-PAGE  NO-HEADING.
  SKIP 2.
  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report2: ', icon_page_right AS ICON,  'U N M A T C H E D
*   c r e d i t     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
*'
  WRITE : / 'Report2: ', icon_page_right AS ICON,  'U N M A T C H E D'
   &' c r e d i t     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
  '                           '.
*end of <RD1K960036>
  ULINE.
  WRITE :/3 'Rec.No',13 'Value date',30 'D/C' ,37 'Amount in Rs.',
      57 '           Narration'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_tran_amt = 0.
  LOOP AT intab FROM 2.
    IF intab-dr_cr = 'C' AND intab-errrec <> '0' AND intab-tcode <> 'TRAN'.
      IF  NOT ( intab-tran_amt IS INITIAL ) AND
                         intab-tran_amt CO '1234567890 '.
        tot_tran_amt =  tot_tran_amt + intab-tran_amt.
      ENDIF.
      match_amt = intab-tran_amt.
      match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,11 sy-vline,
*               13 intab-valdt,28 sy-vline,
*               30 intab-dr_cr,35 sy-vline,
*               37 match_amt1,57 sy-vline,
*               59 intab-narration,92 sy-vline.
      CLEAR l_amt.
      l_amt = match_amt1.

      "CONDENSE l_amt.

      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
               37 l_amt RIGHT-JUSTIFIED,     "#EC CI_FLDEXT_OK[2610650]
               57 sy-vline,
               59 intab-narration,92 sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ENDIF.
  ENDLOOP.
  ULINE.
  match_amt = tot_tran_amt .
  match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*  WRITE :/15 'Total Amt (in Rs.)',
*          37 match_amt1.

  WRITE :/15 'Total Amt (in Rs.)',
          37 match_amt1.                     "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ULINE.
ENDFORM.                               " WRITE_BANK_STMT_CREDIT
*&---------------------------------------------------------------------*
*&      Form  BANKBOOK_TRANSFERS
*&---------------------------------------------------------------------*
FORM bankbook_transfers.
  SKIP 5.
  FORMAT COLOR 4 INTENSIFIED OFF.
  ULINE.
*begin of <RD1K960036>
*WRITE : / 'Report9:',icon_page_right AS ICON ,      'T R A N S F E R S
* f r o m   b a n k   b o o k                 ' ,icon_page_left AS ICON,'
*            '.
  WRITE : / 'Report9:',icon_page_right AS ICON ,      'T R A N S F E R S'
  &'f r o m   b a n k   b o o k                 ' ,icon_page_left AS ICON,''
  &'            '.
*end of <RD1K960036>

***Added on 29.08.2001 *************************************
  SELECT SUM( wrbtr ) INTO amount_1 FROM bsis
   WHERE  bukrs =  bukrs  AND
          hkont = bk_actno AND
          gjahr = gjahr AND
          blart = 'CC'  AND
          budat < dt_fm AND
          shkzg = 'H'.


  SELECT SUM( wrbtr ) INTO amount_4 FROM bsis
  WHERE  bukrs =  bukrs  AND
         hkont = bk_actno AND
         gjahr = gjahr AND
         blart = 'CC'  AND
         budat < dt_fm AND
         shkzg = 'S'.
  amount_5 = amount_4 - amount_1.
  ULINE .
  FORMAT COLOR 5.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*  WRITE:/'Opening Balance of Bank book transfer Rs.' , amount_5.
  WRITE:/'Opening Balance of Bank book transfer Rs.' , amount_5. "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ULINE.
  FORMAT COLOR OFF.
  ULINE.
  WRITE :/1 'Allocation', 24 'Doc.no',
  36 'Post Date',48 'Amount in Rs.',70 'D/C' , 75 'Description           '.  "++ Added D/C column by Rashmi(SAP)
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_tran_bnk = 0.

  SELECT * FROM bsis WHERE "#EC CI_ALL_FIELDS_NEEDED  S4HANA Change SAB_ANKUSH - 07.03.2021
            bukrs =  bukrs  AND
           hkont = bk_actno AND
           gjahr = gjahr  AND
           blart = 'CC'  AND
           budat BETWEEN dt_fm AND dt_to .
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE:/ bsis-zuonr,sy-vline, bsis-belnr,sy-vline,bsis-budat,
*            sy-vline,bsis-wrbtr,sy-vline,bsis-sgtxt,sy-vline.

    WRITE:/ bsis-zuonr,sy-vline, bsis-belnr,sy-vline,bsis-budat,
            sy-vline,bsis-wrbtr,             "#EC CI_FLDEXT_OK[2610650]
            sy-vline,COND #( WHEN bsis-shkzg = 'H' THEN 'CR' WHEN bsis-shkzg = 'S' THEN 'DR' ), "++ Rashmi(SAP)
            sy-vline,bsis-sgtxt,
            sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    IF bsis-shkzg  = 'S' .
      amount_2 = amount_2 + bsis-wrbtr.
    ELSEIF
      bsis-shkzg = 'H'.
      amount_6 = amount_6 + bsis-wrbtr.
    ENDIF.
    amount_7 = amount_2 - amount_6 .
  ENDSELECT.
  FORMAT COLOR 5.
  ULINE.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*  WRITE:/43 amount_7.
  WRITE:/43 amount_7.                        "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ULINE.
  FORMAT COLOR OFF.
  amount_3 = amount_7 +  amount_5.
  FORMAT COLOR 3.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*  WRITE:/43 amount_3.
  WRITE:/43 amount_3.                        "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  FORMAT COLOR OFF.
  ULINE.
************************************************************************
****Commented on 29.08.2001*********************************************
*  LOOP AT opentab.
*    TRANSLATE opentab-zuonr TO UPPER CASE.
*    IF opentab-shkzg = 'H'.
*      dr_cr = 'C'.
*    ELSEIF opentab-shkzg = 'S'.
*      dr_cr = 'D'.
*    ENDIF.
*
**     if opentab-blart = 'CC' .
** IF opentab-zuonr = 'TRANBRS' AND opentab-chect IS INITIAL.
*      WRITE : /1 opentab-zuonr ,11 sy-vline,
*               13 opentab-belnr,24 sy-vline,
*               26 opentab-chect ,34 sy-vline,
*               36 dr_cr,42 sy-vline,
*               44 opentab-budat,52 sy-vline,
*               54 opentab-dmbtr, 71 sy-vline,
*               72 opentab-sgtxt.
*      IF opentab-shkzg = 'H'.
*        tot_tran_bnk = tot_tran_bnk - opentab-dmbtr.
*      ELSEIF opentab-shkzg = 'S'.
*        tot_tran_bnk = tot_tran_bnk + opentab-dmbtr.
*      ENDIF.
*
*      line = line + 1.
*    ENDIF.
*  ENDLOOP.
*  IF line = 0.
*    WRITE : / 'No Transfers from Bankbook during the period'.
*  ELSE.
*    ULINE.
*    WRITE:/40 'Total amt in Rs.',tot_tran_bnk.
*  ENDIF.
*  ULINE.
ENDFORM.                               " BANKBOOK_TRANSFERS
*&---------------------------------------------------------------------*
*&      Form  BANKSTMT_TRANSFERS
*&---------------------------------------------------------------------*
FORM bankstmt_transfers.
  SKIP 5.
  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report3', icon_page_right AS ICON,  'T R A N S F E R S
*   f r o m     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
*'                            '.
  WRITE : / 'Report3', icon_page_right AS ICON,  'T R A N S F E R S'
  &'   f r o m     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
  '                            '.
*end of <RD1K960036>
  ULINE.
  WRITE :/1 'Rec.No',9 'Value date',23 'doc type',37 'Amount in Rs.',
      60 'Chk No/Doc. No', 78 'Description'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_trans = 0.
  LOOP AT intab FROM 2.
    match_amt = intab-tran_amt.
    match_amt1 = match_amt / 100.
    IF intab-tcode = 'TRAN' AND intab-narration = 'SI'.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,7 sy-vline,
*               9 intab-valdt,21 sy-vline,
*               23 intab-dr_cr,35 sy-vline,
*               37 match_amt1,60 sy-vline,
*               62 intab-chkno,78 sy-vline,
*               80 intab-descr.


      CLEAR l_amt.
      l_amt = match_amt1.
      "CONDENSE l_amt.

      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               60 sy-vline,
               62 intab-chkno,78 sy-vline,
               80 intab-descr.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
      line = line + 1.
      IF NOT ( intab-tran_amt IS INITIAL )
          AND intab-tran_amt CO '1234567890 '.
        IF intab-dr_cr = 'D'.
          tot_trans =  tot_trans - intab-tran_amt.
        ELSEIF intab-dr_cr = 'C'.
          tot_trans =  tot_trans + intab-tran_amt.
        ENDIF.


      ENDIF.
    ENDIF.
  ENDLOOP.

  IF line = 0.
    WRITE ' No interest charges from bank statement'.
  ELSE.
    ULINE.
    match_amt = tot_trans.
    match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/15 ' Total amt in Rs.:',
*            37   match_amt1.
    WRITE :/15 ' Total amt in Rs.:',
            37   match_amt1.                 "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.
ENDFORM.                               " BANKSTMT_TRANSFERS
*&---------------------------------------------------------------------*
*&      Form  CLEAR_ITM_BANKBOOK
*&---------------------------------------------------------------------*
FORM clear_itm_bankbook.
*/..Begin of Change CR :30011953 commented below code and rewritten select statement for Report 10 to appear
*****Commented on 06.08.2002 Request from Mr. Iqbal Ahamad
***By Siladitya
**  SELECT  * FROM bkpf WHERE bukrs = bukrs AND gjahr = gjahr
**      AND budat <= dt_to.
**    SELECT  * FROM bseg WHERE bukrs = bukrs AND gjahr = gjahr
**      AND hkont = cl_actno  AND augbl <> ''   AND
**      augdt > dt_to AND belnr = bkpf-belnr.
**      SELECT  SINGLE * FROM payr WHERE zbukr = bukrs AND gjahr = gjahr
**       AND  ubhkt = cl_actno   AND hbkid = hbkid AND vblnr = bkpf-belnr
*  .
**      MOVE-CORRESPONDING payr TO cleartab.
**      MOVE-CORRESPONDING bkpf TO cleartab.
**      MOVE-CORRESPONDING bseg TO cleartab.
**      APPEND cleartab.
**      CLEAR cleartab.
**      CLEAR payr.
**    ENDSELECT.
**  ENDSELECT.
*****Added by Siladitya on 06.08.2002 request By Mr. Iqbal Ahamad
*  Select
*          ZUONR  BELNR
*          BUDAT BLART SHKZG
*          DMBTR SGTXT  into
*
*          (BSIS-ZUONR, BSIS-BELNR,
*           BSIS-BUDAT, BSIS-BLART, BSIS-SHKZG,
*           BSIS-DMBTR, BSIS-SGTXT  )
*           from bsis
*           Where BUKRS = bukrs and
*                 HKONT = cl_actno and
*                 AUGDT > dt_to and
*                 AUGBL <> ' ' and
*                 gjahr = gjahr  and
*                 BUDAT <= DT_TO .
*
*    Select Single CHECT BANCD VOIDR
*                 into (payr-CHECT, payr-BANCD, payr-VOIDR)
*                  from payr
*           Where zbukr = bukrs and
*                 gjahr = gjahr and
*                 HBKID = HBKID and
*                 HKTID = HKTID and
*                 UBHKT = cl_actno and
*                 VBLNR = bsis-belnr and
*                 voidr = '0' .
*    Move:
*         BSIS-ZUONR to cleartab-ZUONR,
*         BSIS-BELNR to cleartab-belnr,
*         BSIS-BUDAT to cleartab-budat,
*         BSIS-BLART to cleartab-blart,
*         BSIS-SHKZG to cleartab-shkzg,
*         BSIS-DMBTR to cleartab-dmbtr,
*         BSIS-SGTXT to cleartab-sgtxt,
*         payr-chect to cleartab-chect,
*         payr-bancd to cleartab-bancd,
*         payr-voidr to cleartab-voidr.
*    APPEND cleartab.
*    CLEAR  cleartab.
*    Clear: BSIS-ZUONR,
*           BSIS-BELNR ,
*           BSIS-BUDAT ,
*           BSIS-BLART ,
*           BSIS-SHKZG ,
*           BSIS-DMBTR ,
*           BSIS-SGTXT ,
*           payr-chect ,
*           payr-bancd ,
*           payr-voidr .
*
*  Endselect.
**********Added by Siladitya on 06.08.2002
*Begin of Change CR :30012202
  DATA : l_yr_prev(4) TYPE n,
         l_budat_from TYPE sy-datum.

  CLEAR : l_budat_from,l_yr_prev.

  l_yr_prev = dt_to+0(4) - 1.
  CONCATENATE l_yr_prev dt_to+4(2) dt_to+6(2) INTO l_budat_from .

*  SELECT  * FROM bkpf WHERE bukrs = bukrs AND gjahr = gjahr
*    and budat <= dt_to
*    SELECT  * FROM bseg WHERE bukrs = bukrs AND gjahr = gjahr
*      AND hkont = cl_actno  AND augbl <> ''   AND
*      augdt > dt_to AND belnr = bkpf-belnr.
*      SELECT  SINGLE * FROM payr WHERE zbukr = bukrs AND gjahr = gjahr
*       AND  ubhkt = cl_actno   AND hbkid = hbkid AND vblnr = bkpf-belnr
*  .
*      MOVE-CORRESPONDING payr TO cleartab.
*      MOVE-CORRESPONDING bkpf TO cleartab.
*      MOVE-CORRESPONDING bseg TO cleartab.
*      APPEND cleartab.
*      CLEAR cleartab.
*      CLEAR payr.
*    ENDSELECT.
*  ENDSELECT.
*End of Change CR :30012202
  DATA : ist_bkpf TYPE STANDARD TABLE OF bkpf,
         wa_bkpf  TYPE bkpf.
  DATA : ist_bseg TYPE STANDARD TABLE OF bseg,
         wa_bseg  TYPE bseg.
  DATA : ist_payr TYPE STANDARD TABLE OF payr,
         wa_payr  TYPE payr.

  SELECT  * FROM bkpf
    INTO CORRESPONDING FIELDS OF TABLE ist_bkpf
    WHERE bukrs = bukrs AND gjahr = gjahr
    AND blart IN ('BR' , 'BP' , 'XE' , 'XD')
      AND ( budat >= l_budat_from AND budat <= dt_to ).

  IF NOT ist_bkpf[] IS INITIAL.
    LOOP AT ist_bkpf INTO wa_bkpf.
      CLEAR :wa_bseg,ist_bseg.
      REFRESH :ist_bseg.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 18-May-22
*      SELECT  * FROM bseg
*      "#EC CI_NOORDER S4HANA Change CAB_SUDHIR - 31.05.2021
*        INTO CORRESPONDING FIELDS OF TABLE ist_bseg  "#EC CI_SROFC_NESTED S4HANA Change SAB_ANKUSH - 07.04.2021
*              WHERE bukrs = bukrs AND gjahr = gjahr
*              AND hkont = cl_actno  AND augbl <> ''
*              AND augdt > dt_to AND belnr = wa_bkpf-belnr.

      SELECT  * FROM bseg "#EC CI_NOORDER S4HANA Change CAB_SUDHIR - 31.05.2021
        INTO CORRESPONDING FIELDS OF TABLE ist_bseg "#EC CI_SROFC_NESTED S4HANA Change SAB_ANKUSH - 07.04.2021
              WHERE bukrs = bukrs AND gjahr = gjahr
              AND hkont = cl_actno  AND augbl <> ''
              AND augdt > dt_to AND belnr = wa_bkpf-belnr. "#EC CI_DB_OPERATION_OK[2431747]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 18-May-22
      IF NOT ist_bseg[] IS INITIAL.
        LOOP AT ist_bseg INTO wa_bseg.
          MOVE-CORRESPONDING wa_bkpf TO cleartab.
          MOVE-CORRESPONDING wa_bseg TO cleartab.
          SELECT  SINGLE * FROM payr WHERE "#EC CI_ALL_FIELDS_NEEDED  S4HANA Change SAB_ANKUSH - 07.03.2021
            zbukr = bukrs AND gjahr = gjahr "#EC CI_NOORDER S4HANA Change CAB_SUDHIR - 31.05.2021
* S4HANA Change SAB_ANKUSH - 07.04.2021
                       AND  ubhkt = cl_actno   AND hbkid = hbkid
                       AND vblnr = wa_bkpf-belnr. "#EC CI_SROFC_NESTED
          IF sy-subrc = 0.
            MOVE-CORRESPONDING payr TO cleartab.
          ENDIF.
          APPEND cleartab.
          CLEAR cleartab.
          CLEAR payr.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDIF.


*/..End of Change CR :30011953

  SORT cleartab BY belnr.
  SKIP 5.
  FORMAT COLOR 4 INTENSIFIED OFF.
  ULINE.
*begin of <RD1K960036>
*  WRITE : / 'Report10:',icon_page_right AS ICON ,
*'S U B S E Q U E N T   C L E A R  I T E M S    F R O M    B A N K
*b o o k                 ' ,icon_page_left AS ICON,'
*            '.
  WRITE : / 'Report10:',icon_page_right AS ICON ,
  'S U B S E Q U E N T   C L E A R  I T E M S    F R O M    B A N K'
  &'b o o k                 ' ,icon_page_left AS ICON,''
  &'           '.
*end of <RD1K960036>
  ULINE.
  WRITE :/1 'Allocation', 13 'Doc.no',26 'Cheque No', 36 'Void',
  42 'Encashment Dt.',      57 'Doc.Type',
  67 'Post Date',78 'D/C',82 'Amount in Rs.',
                            106 'Description                          '.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_tran_bnk = 0.
  LOOP AT cleartab.
    IF cleartab-shkzg = 'H'.
      dr_cr = 'C'.
    ELSEIF cleartab-shkzg = 'S'.
      dr_cr = 'D'.
    ENDIF.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE : /1 cleartab-zuonr ,11 sy-vline,
*             13 cleartab-belnr,24 sy-vline,
*             26 cleartab-chect ,34 sy-vline,
*             36 cleartab-voidr, 40 sy-vline,
*             42 cleartab-bancd, 55 sy-vline,
*             57 cleartab-blart,65 sy-vline,
*             67 cleartab-budat,77 sy-vline,
*             78 dr_cr,81 sy-vline,
*             82 cleartab-dmbtr, 105 sy-vline,
*             106 cleartab-sgtxt.

    WRITE : /1 cleartab-zuonr ,11 sy-vline,
             13 cleartab-belnr,24 sy-vline,
             26 cleartab-chect ,34 sy-vline,
             36 cleartab-voidr, 40 sy-vline,
             42 cleartab-bancd, 55 sy-vline,
             57 cleartab-blart,65 sy-vline,
             67 cleartab-budat,77 sy-vline,
             78 dr_cr,81 sy-vline,
             82 cleartab-dmbtr,              "#EC CI_FLDEXT_OK[2610650]
             105 sy-vline,
             106 cleartab-sgtxt.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    IF cleartab-shkzg = 'H'.
      tot_tran_bnk = tot_tran_bnk - cleartab-dmbtr.
    ELSEIF cleartab-shkzg = 'S'.
      tot_tran_bnk = tot_tran_bnk + cleartab-dmbtr.
    ENDIF.
    line = line + 1.
  ENDLOOP.

  IF line = 0.
    WRITE : / 'No CLear items from bankbook'.
  ELSE.
    ULINE.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE : /64  'Total amt in Rs. ', tot_tran_bnk.
    WRITE : /64  'Total amt in Rs. ', tot_tran_bnk. "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.
ENDFORM.                               " CLEAR_ITM_BANKBOOK
*&---------------------------------------------------------------------*
*&      Form  GET_OPENTAB
*&---------------------------------------------------------------------*

FORM get_opentab.
  REFRESH opentab.
  gjahr1 = gjahr - 1.
  CLEAR opentab.
  opentab-sgtxt = txt.
  APPEND opentab.
* ---- Select Open Items into Internal Table opentab----- *
**Commented on 06.08.2002 request from Mr. Iqbal
*  SELECT  * FROM bkpf WHERE bukrs = bukrs
*               AND ( gjahr = gjahr OR gjahr = gjahr1 )
*               AND budat <= dt_to.
*    SELECT  * FROM bseg WHERE bukrs = bukrs
*             AND ( gjahr = bkpf-gjahr )
*            AND hkont = cl_actno  AND augbl = '' AND belnr = bkpf-belnr
  .
*      SELECT  SINGLE * FROM payr WHERE zbukr = bukrs
*                                  AND ( gjahr = bkpf-gjahr )
*                              AND  ubhkt = cl_actno   AND hbkid = hbkid
*                                 AND vblnr = bseg-belnr AND voidr = '0'
  .
*      MOVE-CORRESPONDING bkpf TO opentab.
*      MOVE-CORRESPONDING bseg TO opentab.
*      MOVE-CORRESPONDING payr TO opentab.
*      opentab-errrec = '99'.
*      APPEND opentab.
*      CLEAR opentab.
*      CLEAR payr.
*    ENDSELECT.
*  ENDSELECT
*****************************************************************
****Added By Siladitya on 06.08.2002 Request frm Mr. Iqbal Ahamad
  SELECT
   augbl zuonr gjahr belnr
          budat blart shkzg gsber
*          DMBTR SGTXT  into
          dmbtr wrbtr sgtxt  INTO                      "+002
          (bsis-augbl, bsis-zuonr, bsis-gjahr, bsis-belnr,
           bsis-budat, bsis-blart, bsis-shkzg, bsis-gsber,
*           BSIS-DMBTR, BSIS-SGTXT  )
            bsis-dmbtr, bsis-wrbtr, bsis-sgtxt  ) "+002
           FROM bsis
           WHERE bukrs = bukrs AND
                 hkont = cl_actno AND
                 augbl = ' ' AND
                    ( gjahr = gjahr OR gjahr = gjahr1 ) AND
                 budat <= dt_to .

    SELECT SINGLE chect bancd voidr "#EC CI_NOORDER S4HANA Change CAB_SUDHIR - 31.05.2021
                 INTO (payr-chect, payr-bancd, payr-voidr) "#EC CI_SROFC_NESTED S4HANA Change SAB_ANKUSH - 07.04.2021
                  FROM payr
           WHERE zbukr = bukrs AND
                 hbkid = hbkid AND
                 hktid = hktid AND
                 vblnr = bsis-belnr AND
                 gjahr = bsis-gjahr AND
                 ubhkt = cl_actno AND
                 voidr = '0' .
********+002********
    IF bukrs = 'OBV'.
      CLEAR bsis-dmbtr.
      bsis-dmbtr = bsis-wrbtr.
    ENDIF.
**************end********
    MOVE:bsis-augbl TO opentab-augbl,
         bsis-zuonr TO opentab-zuonr,
         bsis-gjahr TO opentab-gjahr,
         bsis-belnr TO opentab-belnr,
         bsis-budat TO opentab-budat,
         bsis-blart TO opentab-blart,
         bsis-shkzg TO opentab-shkzg,
         bsis-gsber TO opentab-gsber,
         bsis-dmbtr TO opentab-dmbtr,
         bsis-sgtxt TO opentab-sgtxt,
         payr-chect TO opentab-chect,
         payr-bancd TO opentab-bancd,
         payr-voidr TO opentab-voidr.

    opentab-errrec = '99'.
    APPEND opentab.
    CLEAR opentab.

    CLEAR   :bsis-augbl,
             bsis-zuonr ,
             bsis-gjahr ,
             bsis-belnr ,
             bsis-budat ,
             bsis-blart ,
             bsis-shkzg ,
             bsis-gsber ,
             bsis-dmbtr ,
             bsis-wrbtr ,                    "+002
             bsis-sgtxt ,
             payr-chect ,
             payr-bancd ,
             payr-voidr .


  ENDSELECT.
*****************************************************************
  SORT opentab BY belnr.
ENDFORM.                               " GET_OPENTAB
*&---------------------------------------------------------------------*
*&      Form  APPEND_MATCH
*&---------------------------------------------------------------------*
FORM append_match USING new_seq slno chkno tran_amt dr_cr
        chect wrbtr  dr_cr1  void encash remark.
  match_tab-new_seq = new_seq.
  match_tab-slno = slno.
  match_tab-identif = chkno.
  match_tab-dr_cr = dr_cr.
  match_tab-amt = tran_amt.
  match_tab-chq_rt = chect.
***S/4 Start of Change - SAP_ABAP5 — TR RP1K951283   – 2022/05/27
*  match_tab-amt1 = wrbtr.
  match_tab-amt1 = CONV #( wrbtr ).
***S/4 End of Change - SAP_ABAP5— TR RP1K951283  – 2022/05/27
  match_tab-dr_cr1 = dr_cr1.
  match_tab-void = void.
  match_tab-encash = encash.
  match_tab-remark = remark.
  APPEND match_tab.
  match_err_count = match_err_count + 1.
ENDFORM.                               " APPEND_MATCH
*&---------------------------------------------------------------------*
*&      Form  DUMP_ERRORS
*&---------------------------------------------------------------------*
FORM dumping_tofilesystem.
* ---- Fill the first record of bankstmt with all fields blank and
*------description with the parameter values as file idetifier
  intab-slno = space.
  intab-actno = space.
  intab-valdt = space.
  intab-tran_dt = space.
  intab-narration = space.
  intab-dr_cr = space.
  intab-tran_amt = space.
  intab-dr_cr1 = space.
  intab-cum_bal = space.
  intab-tcode = space.
  intab-chkno = space.
  intab-rt# = space.
  intab-docno = space.
  intab-gsber = space.
  DATA(lv_aznum) = |{ aznum ALPHA = OUT }|.      "S4H FP3 fix
  CONDENSE lv_aznum.                             "S4H FP3 fix
*  CONCATENATE bukrs gjahr aznum azdat hbkid     "S4H FP3 fix
  CONCATENATE bukrs gjahr lv_aznum azdat hbkid   "S4H FP3 fix
   hktid dt_fm dt_to INTO intab-descr.
  intab-errrec = space.
  MODIFY intab FROM intab INDEX 1.
* --- Download bankstmt  into filesystem ------*
*begin of <RD1K960036>
*  CALL FUNCTION 'WS_DOWNLOAD'
*       EXPORTING
*            filename         = 'C:\sappc\bnkstmt.txt'
*            filetype         = 'DAT'
*       TABLES
*            data_tab         = intab
*       EXCEPTIONS
*            file_open_error  = 1
*            file_write_error = 2
*            OTHERS           = 8.
*  IF sy-subrc <> 0.
*WRITE :/ 'Error while downloading Bankstmt  to C:\sappc\bnkstmt.txt...'.
*  ENDIF.
  DATA : l_p_file TYPE string.
  l_p_file = 'C:\sappc\bnkstmt.txt'.
  CONSTANTS : g_c_dat TYPE char10 VALUE 'DAT'.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
*     BIN_FILESIZE            =
      filename                = l_p_file
      filetype                = g_c_dat
    TABLES
      data_tab                = intab
*     FIELDNAMES              =
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

*end of <RD1K960036>
* ---- Fill the first record of Bankbook with all fields blank and
*------description with the parameter values as file idetifier

  opentab-belnr = space.opentab-dmbtr = 0.
  opentab-budat = space.opentab-chect = space.
  opentab-bancd = space.opentab-vblnr = space.
  opentab-voidr = space.opentab-zuonr = space.
  opentab-shkzg = space.
  opentab-errrec = space.
  lv_aznum = |{ aznum ALPHA = OUT }|.      "S4H FP3 fix
  CONDENSE lv_aznum.                       "S4H FP3 fix
*  CONCATENATE bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to INTO  "S4H FP3 fix
  CONCATENATE bukrs gjahr lv_aznum azdat hbkid hktid dt_fm dt_to INTO "S4H Fp3 fix
                                                        opentab-sgtxt.
  MODIFY opentab FROM opentab INDEX 1.
* --- Download bankbook  into filesystem ------*
*begin of <RD1K960036>
*    CALL FUNCTION 'WS_DOWNLOAD'
*         EXPORTING
*              filename         = 'c:\sappc\bankbook.txt'
*              filetype         = 'DAT'
*         TABLES
*              data_tab         = opentab
*         EXCEPTIONS
*              file_open_error  = 1
*              file_write_error = 2
*              OTHERS           = 8.
*    IF sy-subrc <> 0.
*  WRITE :/ 'Error while downloading Bankbook to C:\sappc\bankbook.txt...'.
*    ENDIF.
*

  DATA : l_p_file1 TYPE string.
  l_p_file1 = 'c:\sappc\bankbook.txt'.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
*     BIN_FILESIZE            =
      filename                = l_p_file1
      filetype                = g_c_dat
*     APPEND                  = ' '
*     WRITE_FIELD_SEPARATOR   = ' '
*     HEADER                  = '00'
*     TRUNC_TRAILING_BLANKS   = ' '
*     WRITE_LF                = 'X'
*     COL_SELECT              = ' '
*     COL_SELECT_MASK         = ' '
*     DAT_MODE                = ' '
*     CONFIRM_OVERWRITE       = ' '
*     NO_AUTH_CHECK           = ' '
*     CODEPAGE                = ' '
*     IGNORE_CERR             = ABAP_TRUE
*     REPLACEMENT             = '#'
*     WRITE_BOM               = ' '
*     TRUNC_TRAILING_BLANKS_EOL       = 'X'
*     WK1_N_FORMAT            = ' '
*     WK1_N_SIZE              = ' '
*     WK1_T_FORMAT            = ' '
*     WK1_T_SIZE              = ' '
*     WRITE_LF_AFTER_LAST_LINE        = ABAP_TRUE
*     SHOW_TRANSFER_STATUS    = ABAP_TRUE
* IMPORTING
*     FILELENGTH              =
    TABLES
      data_tab                = opentab
*     FIELDNAMES              =
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc <> 0.
    WRITE :/ 'Error while downloading Bankbook to C:\sappc\bankbook.txt...'.
  ENDIF.
*end of <RD1K960036>


  LOOP AT  opentab WHERE errrec <>  '1'.
    MOVE-CORRESPONDING opentab TO errtab_bnkbook.
    APPEND errtab_bnkbook.
  ENDLOOP.

*begin of <RD1K960036>

*  CALL FUNCTION 'WS_DOWNLOAD'
*      EXPORTING
*           filename            = 'C:\sappc\Errors_bankbook.txt'
*           filetype            = 'DAT'
**     importing
*       TABLES
*            data_tab            = errtab_bnkbook
*       EXCEPTIONS
*            file_open_error     = 1
*            file_write_error    = 2.
*
  DATA : l_p_file2 TYPE string.
  l_p_file2 = 'C:\sappc\Errors_bankbook.txt'.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
*     BIN_FILESIZE            =
      filename                = l_p_file2
      filetype                = g_c_dat
*     APPEND                  = ' '
*     WRITE_FIELD_SEPARATOR   = ' '
*     HEADER                  = '00'
*     TRUNC_TRAILING_BLANKS   = ' '
*     WRITE_LF                = 'X'
*     COL_SELECT              = ' '
*     COL_SELECT_MASK         = ' '
*     DAT_MODE                = ' '
*     CONFIRM_OVERWRITE       = ' '
*     NO_AUTH_CHECK           = ' '
*     CODEPAGE                = ' '
*     IGNORE_CERR             = ABAP_TRUE
*     REPLACEMENT             = '#'
*     WRITE_BOM               = ' '
*     TRUNC_TRAILING_BLANKS_EOL       = 'X'
*     WK1_N_FORMAT            = ' '
*     WK1_N_SIZE              = ' '
*     WK1_T_FORMAT            = ' '
*     WK1_T_SIZE              = ' '
*     WRITE_LF_AFTER_LAST_LINE        = ABAP_TRUE
*     SHOW_TRANSFER_STATUS    = ABAP_TRUE
* IMPORTING
*     FILELENGTH              =
    TABLES
*     DATA_TAB                = opentab
      data_tab                = errtab_bnkbook
*     FIELDNAMES              =
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc <> 0.
    WRITE :/ 'Error while downloading Bankbook to C:\sappc\bankbook.txt...'.
  ENDIF.
*end of <RD1K960036>
ENDFORM.                               " DUMP_ERRORS
*&---------------------------------------------------------------------*
*&      Form  DERIVE_OTHER_FIELDS
*&---------------------------------------------------------------------*
FORM derive_other_fields.
  CONDENSE bk_actno.

* ---- derive the last char of bank account no ---- *
  IF cl_actno = '0000091220'.
    tempchar = 'A'.
  ELSEIF cl_actno = '0000091230'.
    tempchar = 'B'.
  ELSEIF cl_actno = '0000091240'.
    tempchar = 'C'.
  ELSEIF cl_actno = '0000091250'.
    tempchar = 'D'.
  ELSEIF cl_actno = '0000091260'.
    tempchar = 'E'.
  ELSEIF cl_actno = '0000091270'.
    tempchar = 'F'.
  ELSEIF cl_actno = '0000091280'.
    tempchar = 'G'.
  ELSEIF cl_actno = '0000091290'.
    tempchar = 'H'.
  ELSE.
    len2 = strlen( bk_actno ).
    len2 = len2 - 1.
    tempchar = bk_actno+len2(1).   " The last char of the bank accountno
  ENDIF.
  CLEAR intab.

  LOOP AT intab  FROM 2.

    tot_err_flg = intab-errrec.
* ---- if narration length is 8 and it has a format 99999999,tcode=CHK*-
    IF  intab-narration CO '0123456789 ' .
      intab-chkno = intab-narration.
      CONCATENATE 'CHK' tempchar INTO intab-tcode.
* ---- if narration length is 7 and it has a format R999999,tcode=RCT* -
    ELSEIF intab-narration(1) = 'R' OR intab-narration(1) = 'C' AND
        intab-narration+1(6) CO '1234567890 '  .
      intab-rt# = intab-narration.
      CONCATENATE 'RCT' tempchar INTO  intab-tcode.
* ---- if narration length is 7 and it has a format D999999,tcode=OTD* -
    ELSEIF intab-narration(1) = 'D' AND
        intab-narration+1(6) CO '1234567890 '  .
      intab-rt# = intab-narration.
      CONCATENATE 'OTD' tempchar INTO intab-tcode.
* - if narration is 'BCH' or 'INT' or 'INA' then tcode is same as narrt
    ELSEIF intab-narration = 'BCH'.
      CONCATENATE 'BCH' tempchar INTO intab-tcode.
    ELSEIF intab-narration = 'INT'.
      CONCATENATE 'INT' tempchar INTO intab-tcode.
    ELSEIF intab-narration = 'INC'.
      CONCATENATE 'INC' tempchar INTO intab-tcode.
    ELSEIF intab-narration = 'SI'.
      intab-tcode = 'TRAN'.
*Included for SCA -kameswari
    ELSEIF intab-narration = 'SCA'.
      intab-tcode = 'TRAN'.
*Included for SCA -kameswari
    ENDIF.
    intab-errrec = tot_err_flg.
    MODIFY intab FROM intab INDEX sy-tabix.
  ENDLOOP.
ENDFORM.                               " DERIVE_OTHER_FIELDS

*&---------------------------------------------------------------------*
*&      Form  VALIDATION_ERROR_CHECK
*&---------------------------------------------------------------------*
FORM validation_error_check.
  LOOP AT intab FROM 2.
    reccnt = sy-tabix.
    flg_match = 'N'.
    rt_count = 0.pre_count = 0. rwbtr = 0.
    tot_err_flg = intab-errrec.
***************** The Matching Starts here ***********************
* ---- If there is a Check No ------ *
    IF NOT ( intab-chkno IS INITIAL ).
* - Identify whether there is a matching check in the bank book---*
      READ TABLE opentab WITH KEY chect = intab-chkno.
      IF sy-subrc = 0  .
********************
        intab-gsber = opentab-gsber.
********************
        posn_opentab = sy-tabix.
        flg_match = 'Y'.
        IF  intab-tran_amt CO '1234567890 '.
          rwbtr = intab-tran_amt / 100.
          IF intab-dr_cr = 'D' .
            rwbtr = 0 - rwbtr.
          ENDIF.
          IF opentab-shkzg = 'H'.
            wrbtr1 = 0 - opentab-dmbtr.
          ELSE.
            wrbtr1 = opentab-dmbtr.
          ENDIF.
*---- Transaction Amt should be same as Check Amt in Payr Table ---*
          IF wrbtr1 <> rwbtr.
            tot_err_flg = tot_err_flg + 1.
            new_seq = new_seq + 1.
            PERFORM append_match USING new_seq intab-slno intab-chkno
             intab-tran_amt intab-dr_cr
             opentab-belnr opentab-dmbtr opentab-shkzg '' '' ''.
          ENDIF.
        ENDIF.
* ---- Check is encashed ---- *
        IF NOT ( opentab-bancd  = '00000000' ).

          READ TABLE match_tab WITH KEY identif = intab-chkno.
          IF sy-subrc = 0.
            match_tab-encash = 'Y'.
            MODIFY match_tab INDEX sy-tabix.
          ELSE.
            new_seq = new_seq + 1.
            PERFORM append_match USING new_seq intab-slno intab-chkno
            intab-tran_amt intab-dr_cr
            opentab-belnr opentab-dmbtr opentab-shkzg '' 'Y' ''.
          ENDIF.
        ENDIF.

*--- If it is not in Bankbook table(Payr) , identify if there is a
*--- Matching entry for the checkno
* in the allocation field of any doc-*
      ELSEIF sy-subrc <> 0.
        LOOP AT opentab WHERE zuonr = intab-chkno.
          pre_count = pre_count + 1.
        ENDLOOP.
        IF pre_count > 1.
          new_seq = new_seq + 1.
          tot_err_flg = tot_err_flg + 1.

          LOOP AT opentab WHERE zuonr = intab-chkno .

            PERFORM append_match USING new_seq intab-slno intab-chkno
             intab-tran_amt intab-dr_cr
         opentab-belnr opentab-dmbtr opentab-shkzg space space space.
          ENDLOOP.

        ELSEIF pre_count = 1.


          READ TABLE opentab WITH KEY zuonr = intab-chkno .
          IF sy-subrc = 0.
            intab-docno = opentab-belnr.
            intab-gsber = opentab-gsber.
            flg_match = 'Y'.

            posn_opentab = sy-tabix.
            IF  intab-tran_amt CO '1234567890 '.
              rwbtr = intab-tran_amt / 100.
              IF intab-dr_cr = 'D' .
                rwbtr = 0 - rwbtr.
              ENDIF.
              IF opentab-shkzg = 'H'.
                wrbtr1 = 0 - opentab-dmbtr.
              ELSE.
                wrbtr1 = opentab-dmbtr.
              ENDIF.
*---- Transaction Amt should be same as Check Amt in Payr Table ---*
              IF wrbtr1 <> rwbtr.
                tot_err_flg = tot_err_flg + 1.
                new_seq = new_seq + 1.
                PERFORM append_match USING new_seq intab-slno intab-chkno
                           intab-tran_amt intab-dr_cr
                       opentab-belnr opentab-dmbtr opentab-shkzg '' '' ''.
              ENDIF.
            ENDIF.
*-- it is a pre-golive chq the tcode has to be chaged to 'OTD*'----*
            CONCATENATE 'OTD' tempchar INTO tcode.
            intab-tcode = tcode.
            intab-gsber = opentab-gsber.
            MODIFY intab INDEX reccnt.
          ENDIF.
        ENDIF.
        IF flg_match <> 'Y' AND pre_count = 0.
* - Check no not in Bank book(Payr) nor in the alloc. field of a doc.-*
          tot_err_flg = tot_err_flg + 1.
          new_seq = new_seq + 1.
          PERFORM append_match USING new_seq intab-slno intab-chkno
         intab-tran_amt intab-dr_cr
         space space space space space space.
        ENDIF.
      ENDIF.


* --- Check for RT# ----- *

    ELSEIF NOT ( intab-rt# IS INITIAL ).

***  start<RD1K9A0B6B>
      DATA: str1      TYPE string,
            chr20(20) TYPE c.
      READ TABLE opentab WITH KEY zuonr = intab-rt#.
      IF sy-subrc = 0.
        IF opentab-chect IS NOT INITIAL.
          CLEAR: str1, chr20.
***S/4 Start of Change - SAP_ABAP5 — TR RP1K951283   – 2022/05/27
*          chr20 = opentab-dmbtr .
          chr20 =  CONV #( opentab-dmbtr ).
***S/4 End of Change - SAP_ABAP5— TR RP1K951283  – 2022/05/27
          CONDENSE chr20.
          CONCATENATE 'Against bank statement debit for' chr20
                      ',pls use narration chk no.' opentab-chect
                      'assigned with' opentab-belnr INTO str1 SEPARATED BY space.
          " error msg to be displayed
          MESSAGE  str1 TYPE 'I'.

          tot_err_flg = tot_err_flg + 1.
          new_seq = new_seq + 1.

          LOOP AT opentab WHERE zuonr = intab-rt# .
*          clear: str1.
*          CONCATENATE 'use' opentab-CHECT 'in BS narration' into str1.
            PERFORM append_match USING new_seq intab-slno intab-rt#
            intab-tran_amt intab-dr_cr
        opentab-belnr opentab-dmbtr opentab-shkzg space space space.
            EXIT.
          ENDLOOP.

*          leave to screen 0.
        ENDIF.
      ENDIF.
***  end
*--- The RT# should be there in the allocation field of only one doc--*
*read table opentab with key zuonr = intab-docno.
      LOOP AT opentab WHERE zuonr = intab-rt#.
        rt_count = rt_count + 1.
      ENDLOOP.
      IF rt_count > 1.
        tot_err_flg = tot_err_flg + 1.
        new_seq = new_seq + 1.

        LOOP AT opentab WHERE zuonr = intab-rt# .

          PERFORM append_match USING new_seq intab-slno intab-rt#
          intab-tran_amt intab-dr_cr
      opentab-belnr opentab-dmbtr opentab-shkzg space space space.
        ENDLOOP.

      ELSEIF rt_count = 0.
        tot_err_flg = tot_err_flg + 1.
        new_seq = new_seq + 1.
        PERFORM append_match USING new_seq intab-slno intab-rt#
       intab-tran_amt intab-dr_cr
       space space space space space space.

      ELSEIF rt_count = 1.
*--- The amount for the above document should be same as the amt of the
* --- RT# document.
        READ TABLE opentab WITH KEY zuonr = intab-rt# .
        intab-docno = opentab-belnr.
        intab-gsber = opentab-gsber.
        posn_opentab = sy-tabix.
        flg_match = 'Y'.
        IF intab-tran_amt CO '1234567890 '.
          wrbtr = intab-tran_amt / 100.
          IF intab-dr_cr = 'D'.
            wrbtr = 0 - wrbtr.
          ENDIF.
          IF opentab-shkzg = 'H'.
            wrbtr1 = 0 - opentab-dmbtr.
          ELSE.
            wrbtr1 = opentab-dmbtr.
          ENDIF.
          IF wrbtr1 <> wrbtr .
            tot_err_flg = tot_err_flg + 1.
            new_seq = new_seq + 1.
            PERFORM append_match
            USING new_seq intab-slno intab-rt#
            intab-tran_amt intab-dr_cr opentab-belnr
            opentab-dmbtr opentab-shkzg space space space.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    intab-errrec = tot_err_flg.
    MODIFY intab FROM intab INDEX reccnt.
    IF flg_match = 'Y'.
      opentab-errrec = tot_err_flg.
      MODIFY opentab INDEX posn_opentab.
    ENDIF.

  ENDLOOP.
ENDFORM.                               " VALIDATION_ERROR_CHECK
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_BANKSTMT_FROMFILE
*&---------------------------------------------------------------------*
FORM upload_bankstmt_fromfile.
  REFRESH intab.
  CLEAR intab.
*begin of <RD1K960036>
*  CALL FUNCTION 'WS_UPLOAD'
*       EXPORTING
*            filename        = 'C:\SAPPC\bnkstmt.txt'
*            filetype        = 'DAT'
*       TABLES
*            data_tab        = intab
*       EXCEPTIONS
*            file_open_error = 2
*            file_read_error = 3.

  DATA : l_p_file TYPE string.
  l_p_file = 'C:\SAPPC\bnkstmt.txt'.
  CONSTANTS : g_c_asc TYPE char10 VALUE 'ASC'.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = l_p_file
      filetype                = g_c_asc
      has_field_separator     = 'X'
*     HEADER_LENGTH           = 0
*     READ_BY_LINE            = 'X'
*     DAT_MODE                = ' '
*     CODEPAGE                = ' '
*     IGNORE_CERR             = ABAP_TRUE
*     REPLACEMENT             = '#'
*     CHECK_BOM               = ' '
*     VIRUS_SCAN_PROFILE      =
*     NO_AUTH_CHECK           = ' '
*   IMPORTING
*     FILELENGTH              =
*     HEADER                  =
    TABLES
      data_tab                = intab
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

*end of <RD1K960036>
  IF sy-subrc = 0.
    DESCRIBE TABLE intab LINES line.
    IF line > 1.
      DATA(lv_aznum) = |{ aznum ALPHA = OUT }|.      "S4H FP3 fix
      CONDENSE lv_aznum.                             "S4H FP3 fix
*      CONCATENATE bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to INTO   "S4H FP3 fix
      CONCATENATE bukrs gjahr lv_aznum azdat hbkid hktid dt_fm dt_to INTO "S4H FP3 fix
                                                              param_txt.
      READ TABLE intab INDEX 1.
      CONDENSE intab-descr.
      CONDENSE param_txt.
      IF intab-descr = param_txt.
        file_exist = 'Y'.
      ELSE.
        FORMAT COLOR 6.
        WRITE :/ 'Inconsistent header in file C:\SAPPC\bankstmt.txt'.
        WRITE:/ 'Run Validation Module First'.
        FORMAT COLOR OFF.
      ENDIF.
    ELSEIF line <= 1.
      FORMAT COLOR 3.
      WRITE :/ 'File C:\SAPPC\bnkstmt.txt does not have any record'.
      WRITE:/ 'Run Validation Module First'.
      FORMAT COLOR OFF.
    ENDIF.
  ELSEIF sy-subrc <> 0.
    FORMAT COLOR 6.
    WRITE:/ 'Program generated file C:\SAPPC\bnkstmt.txt is missing .'.
    WRITE:/ 'Run Validation Module First'.
    FORMAT COLOR OFF.
  ENDIF.
ENDFORM.                               " UPLOAD_BANKSTMT_FROMFILE

*&---------------------------------------------------------------------*
*&      Form  UPLOAD_BANKBOOK_FROMFILE
*&---------------------------------------------------------------------*
FORM upload_bankbook_fromfile.
*begin of <RD1K960036>
*  CALL FUNCTION 'WS_UPLOAD'
*       EXPORTING
*            filename        = 'C:\sappc\bankbook.txt'
*            filetype        = 'DAT'
*       TABLES
*            data_tab        = opentab
*       EXCEPTIONS
*            file_open_error = 2
*            file_read_error = 3.
  DATA : l_p_file TYPE string.
  l_p_file = 'C:\sappc\bankbook.txt'.
  CONSTANTS : g_c_asc TYPE char10 VALUE 'ASC'.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = l_p_file
      filetype                = g_c_asc
      has_field_separator     = 'X'
    TABLES
      data_tab                = opentab
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  IF sy-subrc = 0.
    DESCRIBE TABLE opentab LINES line.
    IF line > 1.
      DATA(lv_aznum) = |{ aznum ALPHA = OUT }|.      "S4H FP3 fix
      CONDENSE lv_aznum.                             "S4H FP3 fix
*      CONCATENATE bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to INTO   "S4H FP3 fix
      CONCATENATE bukrs gjahr lv_aznum azdat hbkid hktid dt_fm dt_to INTO "S4H FP3 fix
                                                              param_txt.
      READ TABLE opentab INDEX 1.
      CONDENSE opentab-sgtxt.
      CONDENSE param_txt.
      IF opentab-sgtxt = param_txt.
        file_exist = 'Y'.
      ELSE.
        FORMAT COLOR 4.
        WRITE :/ 'Inconsistent header in file C:\SAPPC\bankbook.txt'.
        WRITE:/ 'Run Validation Module First'.
        FORMAT COLOR OFF.

      ENDIF.
    ELSEIF line <= 1.
      FORMAT COLOR 3.
      WRITE :/ 'File C:\SAPPC\bankbook.txt does not have any record'.
      WRITE:/ 'Run Validation Module First'.
      FORMAT COLOR OFF.
    ENDIF.
  ELSEIF sy-subrc <> 0.
    FORMAT COLOR 4.
*begin of <RD1K960036>
*WRITE:/ 'Program generated file C:\SAPPC\bankbook.txt unable to open/R
*ead'.
    WRITE:/ 'Program generated file C:\SAPPC\bankbook.txt unable to open/R'
    &'ead'.
*end of <RD1K960036>
    WRITE:/ 'Run Validation Module First'.
    FORMAT COLOR OFF.
  ENDIF.

ENDFORM.                               " UPLOAD_BANKBOOK_FROMFILE
*&---------------------------------------------------------------------*
*&      Form  BANK_CHARGES
*&---------------------------------------------------------------------*
*begin of <RD1K960036
* this code is commented since this is dead code
*WRITE ' No Bank Charges during the period'.
*ULINE.
*FORMAT COLOR 4 INTENSIFIED OFF.
**begin of <RD1K960036>
**WRITE : / 'Report3', icon_page_right AS ICON,  'T R A N S F E R S
**   f r o m     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
**'                            '.
*WRITE : / 'Report3', icon_page_right AS ICON,  'T R A N S F E R S'
*&'   f r o m     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
*'                            '.
**end of <RD1K960036>
*ULINE.
*WRITE :/1 'Rec.No',9 'Value date',23 'doc type',37 'Amount in Paisa',
*    60 'Chk No/Doc. No', 78 'Description'.
*ULINE.
*FORMAT COLOR 2 INTENSIFIED ON.
*line = 0.
*tot_trans = 0.
*LOOP AT intab FROM 2.
*  IF intab-tcode = 'TRAN' .
*    WRITE :/3 intab-slno,7 sy-vline,
*             9 intab-valdt,21 sy-vline,
*             23 intab-dr_cr,35 sy-vline,
*             37 intab-tran_amt,58 sy-vline,
*             60 intab-chkno,76 sy-vline,
*             78 intab-descr.
*
*    line = line + 1.
*    IF  intab-tran_amt CO '1234567890 '.
*      IF intab-dr_cr = 'D'.
*        tot_trans =  tot_trans - intab-tran_amt.
*      ELSEIF intab-dr_cr = 'C'.
*        tot_trans =  tot_trans + intab-tran_amt.
*      ENDIF.
*
*
*    ENDIF.
*  ENDIF.
*ENDLOOP.
*
*IF line = 0.
*  WRITE ' No Bank Statement Transfers during the period'.
*ELSE.
*  ULINE.
*  WRITE :/15 ' Total amt in Paisa:',
*          37   tot_trans.
*
*ENDIF.
*ULINE.
*

*&---------------------------------------------------------------------*
*&      Form  INT_CHARGES
*&---------------------------------------------------------------------*
FORM int_charges.
  SKIP 5.
  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036
*WRITE : / 'Report5', icon_page_right AS ICON,  'I N T E R E S T  C H A R
* g e s       f r o m    b a n k  s t a t e m e n t ',
*icon_page_left AS ICON, '
  WRITE : / 'Report5', icon_page_right AS ICON,  'I N T E R E S T  C H A R'
  &' g e s       f r o m    b a n k  s t a t e m e n t ',
  icon_page_left AS ICON, ' '
  &'                    '.
*end of <RD1K960036
  ULINE.
  WRITE :/1 'Rec.No',9 'Value date',23 'doc type',37 'Amount in Rs.',
      60 'Chk No/Doc. No', 78 'Description'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_trans = 0.
  LOOP AT intab FROM 2.
    match_amt = intab-tran_amt.
    match_amt1 = match_amt / 100.

    IF intab-tcode(3) = 'INT' .
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,7 sy-vline,
*               9 intab-valdt,21 sy-vline,
*               23 intab-dr_cr,35 sy-vline,
*               37 match_amt1,60 sy-vline,
*               62 intab-chkno,78 sy-vline,
*               80 intab-descr.
      CLEAR l_amt.
      l_amt = match_amt1.
      "CONDENSE l_amt.


      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               60 sy-vline,
               62 intab-chkno,78 sy-vline,
               80 intab-descr.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
      line = line + 1.
      IF  intab-tran_amt CO '1234567890 ' AND
                           NOT ( intab-tran_amt IS INITIAL ).
        IF intab-dr_cr = 'D'.
          tot_trans =  tot_trans - intab-tran_amt.
        ELSEIF intab-dr_cr = 'C'.
          tot_trans =  tot_trans + intab-tran_amt.
        ENDIF.


      ENDIF.
    ENDIF.
  ENDLOOP.

  IF line = 0.
    WRITE ' No interest charges from bank statement'.
  ELSE.
    ULINE.
    match_amt = tot_trans.
    match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/15 ' Total amt in Rs.:',
*            37   match_amt1.

    WRITE :/15 ' Total amt in Rs.:',
            37   match_amt1.                 "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.

ENDFORM.                               " INT_CHARGES

*&---------------------------------------------------------------------*
*&      Form  BANK_CHARGES
*&---------------------------------------------------------------------*
FORM bank_charges.
  SKIP 5.
  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report4', icon_page_right AS ICON,  'B A N K  C H A R G E S
*   f r o m      b a n k    s t a t e m e n t ',icon_page_left AS ICON,
*'                            '.
  WRITE : / 'Report4', icon_page_right AS ICON,  'B A N K  C H A R G E S'
  &'   f r o m      b a n k    s t a t e m e n t ',icon_page_left AS ICON,
  '                            '.
*end of <RD1K960036>
  ULINE.
  WRITE :/1 'Rec.No',9 'Value date',23 'doc type',37 'Amount in Rs.',
      60 'Chk No/Doc. No', 78 'Description'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_trans = 0.
  LOOP AT intab FROM 2.
    match_amt = intab-tran_amt.
    match_amt1 = match_amt / 100.
    IF intab-tcode(3) = 'BCH' .
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,7 sy-vline,
*               9 intab-valdt,21 sy-vline,
*               23 intab-dr_cr,35 sy-vline,
*               37 match_amt1,60 sy-vline,
*               62 intab-chkno,78 sy-vline,
*               80 intab-descr.

      CLEAR l_amt.
      l_amt = match_amt1.
      "CONDENSE l_amt.


      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               60 sy-vline,
               62 intab-chkno,78 sy-vline,
               80 intab-descr.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
      line = line + 1.

      IF   NOT ( intab-tran_amt IS INITIAL )
         AND   intab-tran_amt CO '1234567890 '.

        IF intab-dr_cr = 'D'.
          tot_trans =  tot_trans - intab-tran_amt.
        ELSEIF intab-dr_cr = 'C'.
          tot_trans =  tot_trans + intab-tran_amt.
        ENDIF.


      ENDIF.
    ENDIF.
  ENDLOOP.

  IF line = 0.
    WRITE ' No Bank Interest  during the period'.
  ELSE.
    ULINE.
    match_amt = tot_trans.
    match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/15 ' Total amt in Rs.:',
*            37   match_amt1.
    WRITE :/15 ' Total amt in Rs.:',
            37   match_amt1.                 "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.

ENDFORM.                               " BANK_CHARGES

*&---------------------------------------------------------------------*
*&      Form  INT_CREDITED
*&---------------------------------------------------------------------*
FORM int_credited.
  SKIP 5.
  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
  WRITE : / 'Report6', icon_page_right AS ICON,  'I N T E R E S T  C R E D'
  &'i t e d      f r o m     b a n k   s t a t e m e n t ',
  icon_page_left AS ICON, ' '
  &'                         '.
*end of <RD1K960036>
  ULINE.
  WRITE :/1 'Rec.No',9 'Value date',23 'doc type',37 'Amount in Rs.',
      60 'Chk No/Doc. No', 78 'Description'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_trans = 0.
  LOOP AT intab FROM 2.
    match_amt = intab-tran_amt.
    match_amt1 = match_amt / 100.

    IF intab-tcode(3) = 'INC' .
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,7 sy-vline,
*               9 intab-valdt,21 sy-vline,
*               23 intab-dr_cr,35 sy-vline,
*               37 match_amt1,60 sy-vline,
*               62 intab-chkno,78 sy-vline,
*               80 intab-descr.
      CLEAR l_amt.
      l_amt = match_amt1.
      "CONDENSE l_amt.


      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               60 sy-vline,
               62 intab-chkno,78 sy-vline,
               80 intab-descr.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
      line = line + 1.
      IF  intab-tran_amt CO '1234567890 '
                      AND NOT ( intab-tran_amt IS INITIAL ) .
        IF intab-dr_cr = 'D'.
          tot_trans =  tot_trans - intab-tran_amt.
        ELSEIF intab-dr_cr = 'C'.
          tot_trans =  tot_trans + intab-tran_amt.
        ENDIF.


      ENDIF.
    ENDIF.
  ENDLOOP.

  IF line = 0.
    WRITE ' No Interest Credited  during the period'.
  ELSE.
    ULINE.
    match_amt = tot_trans.
    match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/15 ' Total amt in Rs.:',
*            37   match_amt1.

    WRITE :/15 ' Total amt in Rs.:',
            37   match_amt1.                 "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.

ENDFORM.                               " INT_CREDITED
*&---------------------------------------------------------------------*
*&      Form  BANK_STMT_MATCHED
*&---------------------------------------------------------------------*
FORM bank_stmt_matched.
  PERFORM write_bankstmt_debit_mat.
  PERFORM write_bankstmt_credit_mat.
ENDFORM.                               " BANK_STMT_MATCHED

*&---------------------------------------------------------------------*
*&      Form  WRITE_BANKSTMT_DEBIT_MAT
*&---------------------------------------------------------------------*
FORM write_bankstmt_debit_mat.
  SKIP 4.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report11: ', icon_page_right AS ICON,  'M A T C H E D
*   d e b i t    b a n k   s t a t e m e n t ',icon_page_left AS ICON,
*'                            '.
  WRITE : / 'Report11: ', icon_page_right AS ICON,  'M A T C H E D'
  &'  d e b i t    b a n k   s t a t e m e n t ',icon_page_left AS ICON,
  '                            '.
*end of <RD1K960036>
  ULINE.
  WRITE :/3 'Rec.No',13 'Value date',30 'D/C' ,37 'Amount in Rs.',
      57 '           Narration'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_tran_amt = 0.
  line  = 0.
  LOOP AT intab FROM 2.
    match_amt = intab-tran_amt.
    match_amt1 = match_amt / 100.

    IF intab-dr_cr = 'D' AND intab-errrec = '0'
    AND intab-tcode <> 'TRAN' AND intab-tcode(3) <> 'BCH' AND
    intab-tcode(3) <> 'INT' AND intab-tcode(3) <> 'INC' AND intab-tcode
        <> 'SCA'.
      line = line + 1.
      IF  NOT ( intab-tran_amt IS INITIAL )
                       AND intab-tran_amt CO '1234567890 '.
        tot_tran_amt =  tot_tran_amt - intab-tran_amt.
      ENDIF.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,11 sy-vline,
*               13 intab-valdt,28 sy-vline,
*               30 intab-dr_cr,35 sy-vline,
*               37 match_amt1,57 sy-vline,
*               59 intab-narration,92 sy-vline.
      CLEAR l_amt.
      l_amt = match_amt1.
      "CONDENSE l_amt.


      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               57 sy-vline,
               59 intab-narration,92 sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ENDIF.
  ENDLOOP.
  ULINE.
  IF line > 0.
    match_amt = tot_tran_amt.
    match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/15 'Total amt (in Rs.):',
*            37 match_amt1.

    WRITE :/15 'Total amt (in Rs.):',
            37 match_amt1.                   "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ULINE.
  ELSE.
    WRITE 'No matched Debit Bank Statement'.
  ENDIF.
ENDFORM.                               " WRITE_BANKSTMT_DEBIT_MAT

*&---------------------------------------------------------------------*
*&      Form  WRITE_BANKSTMT_CREDIT_MAT
*&---------------------------------------------------------------------*
FORM write_bankstmt_credit_mat.
  SKIP 4.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report12: ', icon_page_right AS ICON,  'M A T C H E D
*   c r e d i t     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
*'                            '.
  WRITE : / 'Report12: ', icon_page_right AS ICON,  'M A T C H E D'
  &'  c r e d i t     b a n k   s t a t e m e n t ',icon_page_left AS ICON,
  '                            '.
*end of <RD1K960036>
  ULINE.
  WRITE :/3 'Rec.No',13 'Value date',30 'D/C' ,37 'Amount in Rs.',
      57 '           Narration'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_tran_amt = 0.
  line  = 0.
  LOOP AT intab FROM 2.
    IF intab-dr_cr = 'C' AND intab-errrec = '0'
    AND intab-tcode <> 'TRAN' AND intab-tcode(3) <> 'BCH' AND
    intab-tcode(3) <> 'INT' AND intab-tcode(3) <> 'INC'
    AND intab-tcode(3) <> 'SCA'.
      line = line + 1.
      IF NOT ( intab-tran_amt IS INITIAL )
              AND     intab-tran_amt CO '1234567890 '.
        tot_tran_amt =  tot_tran_amt - intab-tran_amt.
      ENDIF.
      match_amt = intab-tran_amt.
      match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,11 sy-vline,
*               13 intab-valdt,28 sy-vline,
*               30 intab-dr_cr,35 sy-vline,
*               37 match_amt1,57 sy-vline,
*               59 intab-narration,92 sy-vline.
      CLEAR l_amt.
      l_amt = match_amt1.
      "CONDENSE l_amt.


      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
               37 l_amt,                     "#EC CI_FLDEXT_OK[2610650]
               57 sy-vline,
               59 intab-narration,92 sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ENDIF.
  ENDLOOP.
  ULINE.
  IF line > 0.
    match_amt = tot_tran_amt.
    match_amt1 = match_amt / 100.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/15 'Total amt (in Rs.):',
*            37 match_amt1.

    WRITE :/15 'Total amt (in Rs.):',
            37 match_amt1.                   "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ULINE.
  ELSE.
    WRITE 'No matched Credit Bank Statement'.
  ENDIF.

ENDFORM.                               " WRITE_BANKSTMT_CREDIT_MAT

*&---------------------------------------------------------------------*
*&      Form  MATCHED_BNK_BOOK
*&---------------------------------------------------------------------*
FORM matched_bnk_book.
  SKIP 5.
  FORMAT COLOR 4 INTENSIFIED OFF.
  ULINE.
*begin of <RD1K960036>
  WRITE : / 'Report13:',icon_page_right AS ICON ,      'M A T C H E D'
  &'b a n k   b o o k    e n t r i e s - debit' , icon_page_left AS ICON,''
  &'            '.
*end of <RD1K960036>
  ULINE.
  WRITE :/1 'Allocation' ,12 'Doc No', 25 'cheque no',
   37 'Doc.Typ' ,42 'Post date',55 'Amount in Rs.',
   72 'Description                                 '.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_amt_bnkbook = 0.
  line = 0.
  LOOP AT opentab WHERE errrec = '0' AND shkzg = 'S' AND zuonr <>
                                                   'TRANBRS'.
    line = line + 1.
    tot_amt_bnkbook = tot_amt_bnkbook + opentab-dmbtr.
    IF opentab-shkzg = 'H'.
      dr_cr = 'C'.
    ELSEIF opentab-shkzg = 'S'.
      dr_cr = 'D'.
    ENDIF.

***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE : /1 opentab-zuonr, 10 sy-vline,
*             12  opentab-belnr ,23 sy-vline,
*             25  opentab-chect,35 sy-vline,
*             37 dr_cr, 40 sy-vline,
*             42 opentab-budat,53 sy-vline,
*             55 opentab-dmbtr,71 sy-vline,
*             72 opentab-sgtxt.

    CLEAR l_amt.
    l_amt = opentab-dmbtr.
    "CONDENSE l_amt.


    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37 dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
             55 l_amt,                       "#EC CI_FLDEXT_OK[2610650]
             71 sy-vline,
             72 opentab-sgtxt.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDLOOP.
  ULINE.

  IF line = 0.
    WRITE : / 'No Matched Debit Bank Book item during the period'.
  ELSE.
    ULINE.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/35 'Total Rs.' , tot_amt_bnkbook.
    WRITE :/35 'Total Rs.' , tot_amt_bnkbook. "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.
  SKIP 5.

  ULINE.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report14:',icon_page_right AS ICON ,      'M A T C H E D
* b a n k   b o o k    e n t r i e s - credit' ,icon_page_left AS ICON,'
*            '.
  WRITE : / 'Report14:',icon_page_right AS ICON ,      'M A T C H E D'
  &' b a n k   b o o k    e n t r i e s - credit' ,icon_page_left AS ICON,''
  &'            '.
*end of <RD1K960036>
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  WRITE :/1 'Allocation' ,12 'Doc No', 25 'cheque no',
   37 'Doc.Typ' ,42 'Post date',55 '  Amount',
   72 'Description                                 '.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_amt_bnkbook = 0.
  LOOP AT opentab WHERE errrec = '0' AND shkzg = 'H' AND zuonr <>
                                                              'TRANBRS'.
    IF opentab-shkzg = 'H'.
      dr_cr = 'C'.
    ELSEIF opentab-shkzg = 'S'.
      dr_cr = 'D'.
    ENDIF.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE : /1 opentab-zuonr, 10 sy-vline,
*             12  opentab-belnr ,23 sy-vline,
*             25  opentab-chect,35 sy-vline,
*             37  dr_cr, 40 sy-vline,
*             42 opentab-budat,53 sy-vline,
*             55 opentab-dmbtr,71 sy-vline,
*             72 opentab-sgtxt.

    CLEAR l_amt.
    l_amt = opentab-dmbtr.
    "CONDENSE l_amt.

    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37  dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
             55 l_amt,                       "#EC CI_FLDEXT_OK[2610650]
             71 sy-vline,
             72 opentab-sgtxt.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    line = line + 1.
    tot_amt_bnkbook = tot_amt_bnkbook - opentab-dmbtr.
  ENDLOOP.
  ULINE.


  IF line = 0.
    WRITE : / 'No matched Credit Bankbook item during the period '.
  ELSE.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/50 'Total Rs.',tot_amt_bnkbook .
    WRITE :/50 'Total Rs.',tot_amt_bnkbook . "#EC CI_FLDEXT_OK[2610650]
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDIF.
  ULINE.

ENDFORM.                               " MATCHED_BNK_BOOK
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_PROGRAM
*&---------------------------------------------------------------------*
FORM upload_bdc_program.
*BOC By Arnav on 10/10/26
* Upload ALL bank statement lines to FF67 without validation filters.
* Matching/clearing is done afterwards by the posting exit. Lines that are
* not posted here must not go to the previous-month error file, otherwise
* they would be uploaded twice.
** -The unmatched records are downloaded to File system as Prev month err
* PERFORM dumping_bnkstmt_err.
* line = 0.
* LOOP AT intab FROM 2 WHERE errrec = '0'.
*   line = line + 1.
* ENDLOOP.
* IF line > 0.
** --- Calculate Closing Bal.------*
*   PERFORM calculate_opbal.
*
*   PERFORM  generate_header_data.
** ----- Generate BDCTAB only for matched records ----*
*   LOOP AT intab FROM 2 WHERE errrec = '0' AND tcode <> 'TRAN'.
*     PERFORM generate_bdc_data.
*   ENDLOOP.
** --- BDC Call transaction and the BDC Lod to be downloed to file system
*   PERFORM bdc_insert.
* ELSE.
*   WRITE:/ 'There is no matching record to be uploaded...'.
**begin of <RD1K960036>
**WRITE:/'The Unmatched Records have been downloaded to
**c:\brs\prevmonth.txt'.
*   WRITE:/'The Unmatched Records have been downloaded to'
*   &'c:\brs\prevmonth.txt'.
**end of <RD1K960036>
* ENDIF.
  DATA lv_skip TYPE i.
* Transaction code suffix (A, B, ...) for lines without a derived code.
* TEMPCHAR is set only in the Validation run (DERIVE_OTHER_FIELDS); in a
* separate Upload run take it from a line Validation already classified.
  IF tempchar IS INITIAL.
    LOOP AT intab FROM 2 WHERE tcode IS NOT INITIAL AND tcode <> 'TRAN'.
      tempchar = intab-tcode+3(1).
      EXIT.
    ENDLOOP.
  ENDIF.
  IF tempchar IS INITIAL.
    WRITE:/ 'Transaction code suffix could not be determined.',
            'Run Validation for this statement first.'.
    EXIT.
  ENDIF.
* Only a non-numeric amount is skipped (it would dump); it is listed.
  line = 0.
  LOOP AT intab FROM 2.
    IF intab-tran_amt CO '0123456789 ' AND intab-tran_amt IS NOT INITIAL.
      line = line + 1.
    ELSE.
      lv_skip = lv_skip + 1.
      WRITE:/ 'Line not uploaded - invalid amount: Sl.No', intab-slno,
              intab-tran_amt.
    ENDIF.
  ENDLOOP.
  IF lv_skip > 0.
    WRITE:/ lv_skip, 'line(s) not uploaded because of an invalid amount.'.
  ENDIF.
  IF line > 0.
    PERFORM calculate_opbal.
    PERFORM generate_header_data.
    LOOP AT intab FROM 2.
      CHECK intab-tran_amt CO '0123456789 ' AND intab-tran_amt IS NOT INITIAL.
      PERFORM generate_bdc_data.
    ENDLOOP.
    PERFORM bdc_insert.
  ELSE.
    WRITE:/ 'There is no record to be uploaded...'.
  ENDIF.
*EOC By Arnav on 10/10/26
ENDFORM.                               " UPLOAD_PROGRAM

*&---------------------------------------------------------------------*
*&      Form  GENERATE_HEADER_DATA
*&---------------------------------------------------------------------*
FORM generate_header_data.
  REFRESH bdcdata.
  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'FEBMKA-AZNUM' aznum.
  WRITE azdat TO sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-AZDAT' sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-HBKID' hbkid.
  PERFORM bdc_field       USING 'FEBMKA-HKTID' hktid.
  PERFORM bdc_field       USING 'BDC_OKCODE' '/EVORG'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-BUKRS'.

  PERFORM bdc_dynpro      USING 'SAPMF40K' '0110'.
  PERFORM bdc_field       USING 'BDC_OKCODE' 'ENTE'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-FDIS_SEL'.
  PERFORM bdc_field       USING 'FEBMKA-KONT_INT' 'X'.
  PERFORM bdc_field       USING 'FEBMKA-FDIS_SEL'  ' '.
  PERFORM bdc_field       USING 'FEBMKA-VARI_START' 'BANK'.
  PERFORM bdc_field       USING 'FEBMKA-DEBI_MID' 'D'.
  PERFORM bdc_field       USING 'FEBMKA-KRED_MID' 'K'.

*  PERFORM bdc_field       USING 'FEBMKA-WVAR_ART' '2'. "S4H FP3 fix as per note 3438783
  PERFORM bdc_field       USING 'FEBMKA-WVAR_ART' '3'.  "S4H FP3 fix as per note 3438783
  PERFORM bdc_field       USING 'FEBMKA-BUCH_VAL' 'X'.

  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE' '/00'.
*  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-MNAM1'. "--S4H FP3 fix
  PERFORM bdc_field       USING 'BDC_CURSOR'  'FEBMKA-JNAME'. "++S4H FP3 fix
  PERFORM bdc_field       USING  'FEBMKA-BUKRS' bukrs.
  PERFORM bdc_field       USING 'FEBMKA-HBKID' hbkid.
  PERFORM bdc_field       USING 'FEBMKA-HKTID' hktid.
  PERFORM bdc_field       USING 'FEBMKA-AZNUM' aznum.
* ---- Convert Statement Date into SAP Date Format
  WRITE azdat TO sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-AZDAT' sy-tvar0.
  tempbal = opbl.
  PERFORM bdc_field       USING 'FEBMKA-SSALD' tempbal.
***S/4 Start of Change - SAP_ABAP5 — TR RP1K951283   – 2022/05/27
*  tempbal = tempbal1.
  tempbal = CONV #( tempbal1 ).
***S/4 End of Change - SAP_ABAP5— TR RP1K951283  – 2022/05/27
*BOC By Arnav on 10/10/26
* Closing balance = opening (OPBL) + net of the uploaded lines, otherwise
* FF67 rejects the statement with FV 072 (items <> closing - opening).
  DATA lv_esald LIKE bseg-wrbtr.
  lv_esald = opbl + tempbal1.
  tempbal = CONV #( lv_esald ).
*EOC By Arnav on 10/10/26
  PERFORM bdc_field       USING 'FEBMKA-ESALD' tempbal.
  WRITE postdt TO sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-BUDTM' sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-NM1VB' 'X'.
*  PERFORM bdc_field       USING 'FEBMKA-MNAM1' session. "--S4H FP3 fix
  PERFORM bdc_field       USING 'FEBMKA-JNAME' session.  "++S4H FP3 fix

ENDFORM.                               " GENERATE_HEADER_DATA


*&---------------------------------------------------------------------*
*&      Form  BDC_DYNPRO
*&---------------------------------------------------------------------*
FORM bdc_dynpro USING    program dynpro.
  CLEAR bdcdata.
  bdcdata-program = program.
  bdcdata-dynpro = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                               " BDC_DYNPRO


*&---------------------------------------------------------------------*
*&      Form  BDC_FIELD
*&---------------------------------------------------------------------*
FORM bdc_field USING    fname fval.
  CLEAR bdcdata.
  bdcdata-fnam = fname.
  bdcdata-fval = fval.
  APPEND bdcdata.
ENDFORM.                               " BDC_FIELD

*&---------------------------------------------------------------------*
*&      Form  GENERATE_BDC_DATA
*&---------------------------------------------------------------------*
FORM generate_bdc_data.
*added for removing inconsistency of screen no in DEV and PRD -
*for variant BANK kameswari
  CLEAR t021d.
  SELECT SINGLE * FROM t021d WHERE progn = 'SAPMF40K'
                               AND anwnd = 'KNTAZ'
                               AND varnr = 'BANK'.

  PERFORM bdc_dynpro      USING 'SAPMF40K' t021d-dynnr.
*added for removing inconsistency of screen no in DEV and PRD -
*for variant BANK kameswari
  PERFORM bdc_field       USING 'BDC_OKCODE' 'ZINS'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-VGMAN(01)'."Transac

*BOC By Arnav on 10/10/26
* Lines Validation could not classify, and transfers (TRAN), get a
* receipt or outgoing code by debit/credit so every line can be uploaded.
* ASSUMPTION: RCT<x>/OTD<x> exist in the BANK account variant (T028G) and
* post such lines to the clearing account for the exit to clear.
  IF intab-tcode IS INITIAL OR intab-tcode = 'TRAN'.
    IF intab-dr_cr = 'D'.
      CONCATENATE 'OTD' tempchar INTO intab-tcode.
    ELSE.
      CONCATENATE 'RCT' tempchar INTO intab-tcode.
    ENDIF.
  ENDIF.
* PERFORM bdc_field       USING  'FEBMKA-VGMAN(01)' intab-tcode.
  PERFORM bdc_field       USING  'FEBMKA-VGMAN(01)' intab-tcode.
*EOC By Arnav on 10/10/26

* -- Convert The Date into SAP Date Format ---*
  IF intab-valdt(2) = '99'.
    CONCATENATE '19' intab-valdt INTO tempdt1.

  ELSE.
*Commented on 2-2-2001 for Fiscal year - kameswari
*   IF INTAB-VALDT(2) = '01'.
*Commented on 2-2-2001 for Fiscal year - kameswari
    CONCATENATE '20' intab-valdt INTO tempdt1.
  ENDIF.
*concatenate tempdt+4(2) '/' tempdt+6(2) '/' tempdt(4) into tempdt.
  WRITE tempdt1 TO sy-tvar0.

  PERFORM bdc_field       USING  'FEBEP-VALUT(01)' sy-tvar0. " Value dt
  intab-tran_amt = intab-tran_amt / 100.
  IF intab-dr_cr = 'D'.
    tran_amt = 0 - intab-tran_amt.
  ELSE.
    tran_amt = intab-tran_amt.
  ENDIF.
***S/4 Start of Change - SAP_ABAP5 — TR RP1K951283   – 2022/05/27
*  tran_amt1 = tran_amt.
  tran_amt1 = CONV #( tran_amt ).
***S/4 End of Change - SAP_ABAP5— TR RP1K951283  – 2022/05/27
  PERFORM bdc_field       USING 'FEBMKA-KWBTR(01)' tran_amt1." Amt

*BOC By Arnav on 10/10/26
* INTAB-DOCNO (bank book document) is filled only when Validation matched
* the line. Now that unmatched lines are uploaded too, it is often blank and
* FF67 gets no cheque/document number. Fall back to the reference from the
* bank file: RT# (R/C/D + number), cheque no., then the narration.
* ASSUMPTION: the FF67 exit reads FEBMKK-CHECT_KF to find the document.
* IF intab-tcode(3) = 'RCT' OR intab-tcode(3) = 'OTD'.
*   PERFORM bdc_field       USING 'FEBMKK-CHECT_KF(01)' intab-docno.
* ELSEIF intab-tcode(3) = 'CHK'.
*   PERFORM bdc_field       USING 'FEBMKK-CHECT_KF(01)' intab-chkno.
* ENDIF.
  DATA lv_chect TYPE febmkk-chect_kf.
  CLEAR lv_chect.
  IF intab-tcode(3) = 'RCT' OR intab-tcode(3) = 'OTD'.
    lv_chect = intab-docno.
    IF lv_chect IS INITIAL.
      lv_chect = intab-rt#.
    ENDIF.
  ELSEIF intab-tcode(3) = 'CHK'.
    lv_chect = intab-chkno.
  ENDIF.
  IF lv_chect IS INITIAL AND intab-tcode(3) <> 'BCH'
     AND intab-tcode(3) <> 'INT' AND intab-tcode(3) <> 'INC'.
    lv_chect = intab-narration.
  ENDIF.
  CONDENSE lv_chect.
  IF lv_chect IS NOT INITIAL.
    PERFORM bdc_field       USING 'FEBMKK-CHECT_KF(01)' lv_chect.
  ENDIF.
*EOC By Arnav on 10/10/26
  PERFORM bdc_field       USING 'FEBMKK-ZUONR(01)' intab-narration.
  IF intab-tcode(3) = 'BCH' OR intab-tcode(3) = 'INT'
                                        OR intab-tcode(3) = 'INC'.
    PERFORM bdc_field       USING 'FEBMKK-KOSTL_KF(01)' kostl.
  ENDIF.
  CONCATENATE
'Company:' bukrs ';' 'Stmt No:' aznum ';' 'Slno:' intab-slno INTO descr.
  PERFORM bdc_field USING 'FEBMKK-SGTXT_KF(01)' descr.
  PERFORM bdc_field USING 'FEBMKK-GSBER_KF(01)' intab-gsber.
  IF intab-tcode(3) = 'BCH' OR intab-tcode(3) = 'INT'
                                      OR intab-tcode(3) = 'INC'.
*Code included for BA as told by Rohit - kameswari
    PERFORM bdc_field USING 'FEBMKK-GSBER_KF(01)' gsber.
*Code included for BA as told by Rohit - kameswari
  ENDIF.
* ----
ENDFORM.                               " GENERATE_BDC_DATA
*&---------------------------------------------------------------------*
*&      Form  BDC_INSERT
*&---------------------------------------------------------------------*
FORM bdc_insert.
  PERFORM bdc_dynpro      USING 'SAPMF40K' t021d-dynnr.
  PERFORM bdc_field       USING 'BDC_OKCODE' 'SICH'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKK-CHECT_KF(01)'.
  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE' 'BUCH'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-BUKRS'.
  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE' '/N'.
  CALL TRANSACTION 'FF67' USING bdcdata MODE 'N' UPDATE 'S'
                                        MESSAGES INTO bdcmsg.
*BOC By Arnav on 10/10/26
* If FF67 reports the statement as posted, the run is treated as correct:
* only that message is shown and no error log file is saved. Otherwise the
* log is shown and offered for download as before.
* ASSUMPTION: FORMAT_MESSAGE runs with LANG 'E', so the posted message reads
* 'Statement/list posted' (message class/number not confirmed).
* IF sy-subrc = 0.
*   WRITE :/ 'The matched items has been uploaded to BDC Session ',session.
* ENDIF.
* PERFORM format_message .
* PERFORM display_call_transaction_log.
  DATA lv_posted TYPE c LENGTH 1.
  PERFORM format_message.
  CLEAR lv_posted.
  LOOP AT itabmsg WHERE text CS 'Statement/list posted'.
    lv_posted = 'X'.
    EXIT.
  ENDLOOP.
  IF lv_posted = 'X'.
    SKIP 2.
    WRITE:/ itabmsg-text.
  ELSE.
    PERFORM display_call_transaction_log.
  ENDIF.
*EOC By Arnav on 10/10/26
ENDFORM.                               " BDC_INSERT
*&---------------------------------------------------------------------*
*&      Form  CALCULATE_OPBAL
*&---------------------------------------------------------------------*
FORM calculate_opbal.
  tempbal1 = 0.
*BOC By Arnav on 10/10/26
* Net of ALL uploaded lines (same lines as UPLOAD_BDC_PROGRAM sends)
* LOOP AT intab FROM 2 WHERE errrec = '0' AND tcode <> 'TRAN'.
  LOOP AT intab FROM 2.
    CHECK intab-tran_amt CO '0123456789 ' AND intab-tran_amt IS NOT INITIAL.
*EOC By Arnav on 10/10/26
    IF intab-dr_cr = 'D'.
      tempbal1 = tempbal1 - intab-tran_amt / 100.
    ELSEIF intab-dr_cr = 'C'.
      tempbal1 = tempbal1 + intab-tran_amt / 100.
    ENDIF.
  ENDLOOP.

ENDFORM.                               " CALCULATE_OPBAL
*&---------------------------------------------------------------------*
*&      Form  FORMAT_MESSAGE
*&---------------------------------------------------------------------*
FORM format_message .

  LOOP AT bdcmsg.
*BOC By Arnav on 10/10/26
* Warnings are not shown in the upload log or written to the log file:
* type W, plus FV 058 (opening vs prior closing balance) and FV 093
* ('Warning: Values entered are ignored', may come with another type).
    CHECK bdcmsg-msgtyp <> 'W'.
    CHECK NOT ( bdcmsg-msgid = 'FV' AND
              ( bdcmsg-msgnr = '058' OR bdcmsg-msgnr = '093' ) ).
*EOC By Arnav on 10/10/26
    CLEAR msgline.
    CALL FUNCTION 'FORMAT_MESSAGE'
      EXPORTING
        id        = bdcmsg-msgid
        lang      = 'E'
        no        = bdcmsg-msgnr
        v1        = bdcmsg-msgv1
        v2        = bdcmsg-msgv2
        v3        = bdcmsg-msgv3
        v4        = bdcmsg-msgv4
      IMPORTING
        msg       = msgline
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.

    itabmsg-text = msgline.
    APPEND itabmsg.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_CALL_TRANSACTION_LOG
*&---------------------------------------------------------------------*
FORM display_call_transaction_log.
  SKIP 2.
  WRITE : / " C A L L   T R A N S A C T I O N     L O G ".
   sy-uline.
  LOOP AT itabmsg.
    WRITE :/ itabmsg-text.
  ENDLOOP.
*begin of <RD1K960036>
*  CALL FUNCTION 'DOWNLOAD'
*       EXPORTING
*            filename            = 'C:\BRS\ERR_LOG.TXT'
*            filetype            = 'DAT'
*       TABLES
*            data_tab            = itabmsg
*       EXCEPTIONS
*            invalid_filesize    = 1
*            invalid_table_width = 2
*            invalid_type        = 3
*            no_batch            = 4
*            unknown_error       = 5
*            OTHERS              = 6.
*
*  IF sy-subrc = 0.
*    WRITE :/ 'The upload log has been downloaded to C:\BRS\ERR_LOG.TXT'.
*  ENDIF.
*  WRITE :/ 'You need to initiate the Session', session.
  DATA: l_filename TYPE string,
        l_filen    TYPE string,
        l_path     TYPE string,
        l_fullpath TYPE string,
        l_usr_act  TYPE i.

  l_filename = 'C:\BRS\ERR_LOG.TXT'.
  CONSTANTS : g_c_dat TYPE char10 VALUE 'DAT'.

  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_file_name    = l_filename
    CHANGING
      filename             = l_filen
      path                 = l_path
      fullpath             = l_fullpath
      user_action          = l_usr_act
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.

  IF sy-subrc = 0
        AND l_usr_act <>
        cl_gui_frontend_services=>action_cancel.


    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = l_fullpath
        filetype                = g_c_dat
      TABLES
        data_tab                = itabmsg
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.
    IF sy-subrc = 0.
      WRITE :/ 'The upload log has been downloaded to C:\BRS\ERR_LOG.TXT'.
    ENDIF.
    WRITE :/ 'You need to initiate the Session', session.

  ENDIF.
*end of <RD1K960036>
ENDFORM.                               " DISPLAY_CALL_TRANSACTION_LOG

*&---------------------------------------------------------------------*
*&      Form  DUMPING_BNKSTMT_ERR
*&---------------------------------------------------------------------*
FORM dumping_bnkstmt_err.
  line = 0.
  LOOP AT intab FROM 2 WHERE errrec = '0'.
    line = line + 1.
  ENDLOOP.
  IF line > 0.
    aznum1 = aznum.
  ELSE.
    aznum1 = aznum - 1.
  ENDIF.
  DATA(lv_aznum1) = |{ aznum1 ALPHA = OUT }|.              "S4H FP3 fix
  CONDENSE lv_aznum1.                                     "S4H FP3 fix
*  CONCATENATE bukrs aznum1  hbkid hktid INTO param_txt1.   "S4H FP3 fix
  CONCATENATE bukrs lv_aznum1  hbkid hktid INTO param_txt1. "S4H FP3 fix
  errtab_bnkstmt-narration = param_txt1.
  APPEND errtab_bnkstmt.

* ---- Move Bank stmt errors into internal Table errtab_bnkstmt ----*
  LOOP AT intab FROM 2 WHERE errrec <> '0'.
    MOVE-CORRESPONDING intab TO errtab_bnkstmt.
    APPEND errtab_bnkstmt.
  ENDLOOP.
* ---- Modify the Ctrl# of the internal table as P1, P2 ..... ----- *
  sl = '0'.
  line = 0.
  DESCRIBE TABLE errtab_bnkstmt LINES line.
  IF line  > 1.
    LOOP AT errtab_bnkstmt FROM 2.
      sl = sl + '1'.
      CONDENSE sl.
      CONCATENATE 'P' sl INTO slno.
      errtab_bnkstmt-slno = slno.
      MODIFY errtab_bnkstmt INDEX sy-tabix.
    ENDLOOP.
* ---- Download the bank stmt error records to file system ----- *
*    CALL FUNCTION 'WS_DOWNLOAD'
*        EXPORTING
*             filename            = 'c:\brs\prevmonth.txt'
*             filetype            = 'DAT'
**    importing
*         TABLES
*              data_tab            = errtab_bnkstmt
*         EXCEPTIONS
*              file_open_error     = 1
*              file_write_error    = 2.
*    IF sy-subrc <> 0.

    DATA l_p_file TYPE string.
    l_p_file = 'c:\brs\prevmonth.txt'.
    CONSTANTS : g_c_dat TYPE char10 VALUE 'DAT'.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = l_p_file
        filetype                = g_c_dat
      TABLES
        data_tab                = errtab_bnkstmt
*       FIELDNAMES              = T_HEAD
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.

    IF sy-subrc <> 0.

*begin of <RD1K960036>
*WRITE :/ 'Error while downloading Bank stmt Error file
*to c:\brs\prevmonth.txt...'.
      WRITE :/ 'Error while downloading Bank stmt Error file'
      &'to c:\brs\prevmonth.txt...'.
*end of <RD1K960036>
    ENDIF.
  ENDIF.
ENDFORM.                               " DUMPING_BNKSTMT_ERR

*&---------------------------------------------------------------------*
*&      Form  MATCHED_BNK_STMT_SCA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM matched_bnk_stmt_sca.
  SKIP 4.
  FORMAT COLOR 4 INTENSIFIED OFF.
*begin of <RD1K960036>
*WRITE : / 'Report15: ', icon_page_right AS ICON,  'S E L F
* c l e a r i n g  t r a n s a c t i o n s ',icon_page_left AS ICON,
*'                            '.
  WRITE : / 'Report15: ', icon_page_right AS ICON,  'S E L F'
  &'c l e a r i n g  t r a n s a c t i o n s ',icon_page_left AS ICON,
  '                            '.

  ULINE.
  WRITE :/3 'Rec.No',13 'Value date',30 'D/C' ,37 'Amount in Rs.',
      57 '           Narration'.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  tot_tran_amt = 0.
  line  = 0.
  LOOP AT intab FROM 2.
    match_amt = intab-tran_amt.
    match_amt1 = match_amt / 100.
    IF intab-tcode = 'TRAN' AND intab-narration = 'SCA'.
      line = line + 1.
      IF   NOT ( intab-tran_amt IS INITIAL )
         AND   intab-tran_amt CO '1234567890 '.
        IF intab-dr_cr = 'D'.
          tot_transd =  tot_transd + intab-tran_amt.
        ELSEIF intab-dr_cr = 'C'.
          tot_transc =  tot_transc + intab-tran_amt.
        ENDIF.
      ENDIF.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*      WRITE :/3 intab-slno,11 sy-vline,
*               13 intab-valdt,28 sy-vline,
*               30 intab-dr_cr,35 sy-vline,
*               37 match_amt1,57 sy-vline,
*               59 intab-narration,92 sy-vline.

*** SOC by SAP on 10/01/2023 To handle increased amount length
      CLEAR l_amt.
      l_amt =  match_amt1.
*** EOC by SAP on 10/01/2023 To handle increased amount length

      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
***               37 match_amt1 RIGHT-JUSTIFIED, "#EC CI_FLDEXT_OK[2610650]
*** -- by SAP on 10/01/2023 To handle increased amount length
* ++ by SAP on 10/01/2023 To handle increased amount length
               37 l_amt RIGHT-JUSTIFIED, "#EC CI_FLDEXT_OK[2610650]
               57 sy-vline,
               59 intab-narration,92 sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
    ENDIF.
  ENDLOOP.
  FREE MEMORY ID diff_flag_id.
** Changes made on 12.10.2001
  d_balance = tot_transd - tot_transc.
  IF line = 0.
    WRITE:/3 'No records found for the Type SCA'.
  ENDIF.
  IF line <> 0.
    IF d_balance <> 0.
      d_balance = d_balance / 100.
      WRITE:/25 'Total Amt (in Rs)',d_balance.
      CLEAR diff_flag.
      diff_flag = 'X'.
      EXPORT diff_flag TO MEMORY ID diff_flag_id.
    ELSE.
      d_balance = d_balance / 100.
      WRITE:/30 'Total Amt (in Rs):',d_balance.
      CLEAR diff_flag.
    ENDIF.
    CLEAR d_balance.
  ENDIF.
** Changes made on 12.10.2001
ENDFORM.                               " MATCHED_BNK_STMT_SCA

*&---------------------------------------------------------------------*
*&      Form  DISP_ERROR_REP10
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM disp_error_rep10.
  LOOP AT intab WHERE narration = 'SCA'.
    var_sca = 'X'.
    CLEAR tranamt.
    tranamt = intab-tran_amt / 100.
    IF intab-dr_cr = 'D'.
      damt = damt + tranamt.
    ELSEIF intab-dr_cr = 'C'.
      camt = camt + tranamt.
    ENDIF.
  ENDLOOP.
  IF var_sca = 'X'.
    diff_amt = damt - camt.
    IF diff_amt <> 0.
      SKIP 2.
      FORMAT COLOR 4 INTENSIFIED OFF.
      WRITE:/20 icon_breakpoint AS ICON,
'Balance Not Zero,Please Check the Entries in Report 15',icon_breakpoint
      AS ICON.
      ULINE.
    ENDIF.
  ENDIF.
ENDFORM.
" DISP_ERROR_REP10

*&---------------------------------------------------------------------*
*&      Form  CHECK_BAL_SCA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_bal_sca.

ENDFORM.                               " CHECK_BAL_SCA

*  Start of change on 06-08-2003   Change Id: 001
*&---------------------------------------------------------------------*
*&      Form  UNMATCHED_BNK_BOOK_FOREX_RCPT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM unmatched_bnk_book_forex_rcpt.
  SKIP 5.
  FORMAT COLOR 4 INTENSIFIED OFF.
  ULINE /(129).
*begin of <RD1K960036>
*WRITE : / 'Report16:',icon_page_right AS ICON ,      'U N M A T C H E D
* b a n k   b o o k    e n t r i e s - F o r e x  R e c e i p t s' ,
* icon_page_left AS ICON,'                              '.
  WRITE : / 'Report16:',icon_page_right AS ICON ,      'U N M A T C H E D'
 &'b a n k   b o o k    e n t r i e s - F o r e x  R e c e i p t s' ,
  icon_page_left AS ICON,'                              '.
*end of <RD1K960036>
  ULINE /(129).
  WRITE :/1 sy-vline,'Allocation' ,14 sy-vline,'Doc No' ,25 sy-vline,
   'Post date',37 sy-vline,'Curr' ,43 sy-vline,'Amt in Fr Curr',
   60 sy-vline,'Amt in Lcl Curr' ,77 sy-vline,'Description',
   129 sy-vline.
  ULINE /(129).
  FORMAT COLOR 2 INTENSIFIED ON.
  LOOP AT ist_forex INTO bsis.
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*    WRITE :/1 sy-vline,bsis-zuonr,14 sy-vline, bsis-belnr, 25 sy-vline,
*      bsis-budat,37 sy-vline, bsis-waers, 43 sy-vline, bsis-wrbtr,
*      60 sy-vline, bsis-dmbtr,77 sy-vline, bsis-sgtxt,
*      129 sy-vline.

    WRITE :/1 sy-vline,bsis-zuonr,14 sy-vline, bsis-belnr, 25 sy-vline,
      bsis-budat,37 sy-vline, bsis-waers,
      43 sy-vline, bsis-wrbtr,               "#EC CI_FLDEXT_OK[2610650]
      60 sy-vline, bsis-dmbtr,               "#EC CI_FLDEXT_OK[2610650]
      77 sy-vline, bsis-sgtxt,
      129 sy-vline.
***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
  ENDLOOP.
  ULINE /(129).
***  #HCA – S4HANA_READINESS - Begin of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
*  WRITE :/42 'Total Amount in Rs ',l_tot_rs_amt.
  WRITE :/42 'Total Amount in Rs ',l_tot_rs_amt. "#EC CI_FLDEXT_OK[2610650]

***  #HCA – S4HANA_READINESS - End of changes - Code Adjustment SAP_ABAP3  RP1K951283 27-May-22
ENDFORM.                    " UNMATCHED_BNK_BOOK_FOREX_RCPT
*&---------------------------------------------------------------------*
*&      Form  get_unmatched_forex_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_unmatched_forex_data.
  SELECT SINGLE hkont FROM t012k INTO bk_actno
                      WHERE bukrs = bukrs
                      AND   hbkid = hbkid
                      AND   hktid = hktid.
  IF sy-subrc = 0.
    cl_actno = bk_actno + 2.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = cl_actno
      IMPORTING
        output = cl_actno.
*    temp_bukrs = bukrs.
*    CONCATENATE hktid temp_bukrs aznum+1(4) INTO session.
*  ELSE.
*    CLEAR session.
  ENDIF.
  gjahr1 = gjahr - 1.
  CLEAR l_tot_rs_amt.
  SELECT
    augbl zuonr gjahr belnr
    budat blart shkzg gsber
    dmbtr sgtxt waers wrbtr  INTO
    (bsis-augbl, bsis-zuonr, bsis-gjahr, bsis-belnr,
    bsis-budat, bsis-blart, bsis-shkzg, bsis-gsber,
    bsis-dmbtr, bsis-sgtxt, bsis-waers, bsis-wrbtr )
    FROM bsis
         WHERE bukrs = bukrs AND
               hkont = cl_actno AND
               augbl = ' ' AND
               ( gjahr = gjahr OR gjahr = gjahr1 ) AND
               budat <= dt_to .
    APPEND bsis TO ist_forex.
    CASE bsis-shkzg.
      WHEN 'S'.
        l_tot_rs_amt = l_tot_rs_amt + bsis-dmbtr.
      WHEN 'H'.
        l_tot_rs_amt = l_tot_rs_amt - bsis-dmbtr.
    ENDCASE.
  ENDSELECT.

ENDFORM.                    " get_unmatched_forex_data

*  End of change on 06-08-2003     Change Id: 001
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_PROCESS_GUIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM display_process_guide .
*
*  DATA: disp    TYPE REF TO zcl_basic_functioins,
*        l_tcode TYPE swo_typeid.
*
*  CLEAR : l_tcode.
*
*  CREATE OBJECT disp.
*  l_tcode = sy-tcode.
*
*  CALL METHOD disp->display_attachments
*    EXPORTING
*      ztxncode   = l_tcode
*      on_display = 'X'.
*
*
*ENDFORM.
