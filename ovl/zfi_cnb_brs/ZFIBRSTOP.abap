*----------------------------------------------------------------------*
*   INCLUDE YBRSTOP                                                    *
*----------------------------------------------------------------------*
* --- DATA DECLARATION SECTION ----- *

***********************************************************************
*  Date           Transport    USERID       Description
* 12/09/2008      RD1K960036   SAB_RAMASUND 1.CONSTANT DECLARED

***********************************************************************

TABLES: FEBKO,              " Electronic Bank Statement Header Records
        FEBEP,              " Electronic Bank Statement Line Items
        BSEG,               " Accounting document segment
        BKPF,               " Accounting document header
        T012K,              " House bank accounts
        T001,               " Company Codes
        T012,               " House banks
        BNKA,               " Bank master record
        CSKS,               " Cost Center Master
        T028H,        " Allocate Manual to Internal Transactions
        tgsb,              "Master for BA
        PAYR,               " Payment transfer medium file
        SKA1,               " G/L accounts master (chart of accounts)
        t021d,              "Screen no for Vanriant 'BANK'
*        T012K .             " House Bank Accounts
         BSIS ,
     GLT0. "G/L account master record transaction figures Dtd.25.03.2003
* ---- Internal table to input Bank statement ---- *
DATA : BEGIN OF INPUT OCCURS 0,
       SLNO(6),
       ACTNO(12),
       VALDT(6),
       TRAN_DT(6),
       NARRATION(25),
       DR_CR(1),
       TRAN_AMT(15),
*      TRAN_AMT(17),                                        "+003
       DR_CR1(1),
       CUM_BAL(15),
*      CUM_BAL(17),                                         "+003
       ERRREC(1),
END OF INPUT.

* ---- Internal Table to store Bank stmt input after derivation of ---*
* ---- Check no, RT# and Trans Code field ------ *
DATA : BEGIN OF INTAB OCCURS 2000,
                SLNO(6),                            " Control No
                ACTNO(12),
                VALDT(6),                          " Value Date
                TRAN_DT(6),
                NARRATION(25),
                DR_CR(1),
                TRAN_AMT(15),
*               TRAN_AMT(17),                               "+003
                DR_CR1(1),
                CUM_BAL(15),
*               CUM_BAL(17),                                "+003
                TCODE(4),                           " Transaction Code
                CHKNO(13),                          " Check No
                RT# LIKE BSEG-BELNR,              " document no
                DOCNO LIKE BSEG-BELNR,
                gsber like bseg-gsber,
*BOC By Arnav on 09/10/26
* DESCR (55) truncated the bnkstmt.txt header record - widened with PARAM_TXT
*               DESCR(55),                          " Description
                DESCR(70),                          " Description
*EOC By Arnav on 09/10/26
                ERRREC(2),                          " Bank Rec Error
END OF INTAB.
DATA : INPUT1 LIKE INPUT OCCURS 0 WITH HEADER LINE.

DATA : BEGIN OF OPENTAB OCCURS 0,
               BELNR LIKE BSEG-BELNR,       " Document No
               BLART LIKE BKPF-BLART,        " Document type
               SHKZG LIKE BSEG-SHKZG,       " Debit/Credit Indc
               DMBTR LIKE BSEG-DMBTR,       " Amount
               WRBTR LIKE BSEG-WRBTR,       " Amount (+002)
               BUDAT(10),                   " Posting Date
               CHECT LIKE PAYR-CHECT,       " Check number
               BANCD(10),                   " Check Encashment date
               gsber like tgsb-gsber,
               VBLNR LIKE PAYR-VBLNR,       " Payment doc. No
               VOIDR LIKE PAYR-VOIDR,       " Check void Reason code
               ZUONR LIKE BSEG-ZUONR,       " Allocation number
               AUGBL LIKE BSEG-AUGBL,       " Doc no. of clearing doc.
*BOC By Arnav on 09/10/26
* SGTXT (50) truncated the bankbook.txt header record - widened to hold it
*              SGTXT LIKE BSEG-SGTXT,       " Text
               SGTXT(70) TYPE C,            " Text / file header record
*EOC By Arnav on 09/10/26
               gjahr like bkpf-gjahr,       "Fiscal Year
               ERRREC(2),
END OF OPENTAB.
DATA : BEGIN OF CLEARTAB OCCURS 0,
               BELNR LIKE BSEG-BELNR,
               SHKZG LIKE BSEG-SHKZG,       " D/C indicator
               DMBTR LIKE BSEG-WRBTR,       " Amount
               BUDAT(10),                   " Posting Date
               CHECT LIKE PAYR-CHECT,       " Check number
               BANCD(10),                   " Check Encashment date
               BLART LIKE BKPF-BLART,       " Document type
               VOIDR LIKE PAYR-VOIDR,       " Check void Reason code
               ZUONR LIKE BSEG-ZUONR,       " Allocation number
               SGTXT LIKE BSEG-SGTXT,       " Text
END OF CLEARTAB.
DATA : ERRTAB_BNKSTMT LIKE INPUT OCCURS 0 WITH HEADER LINE.
DATA : ERRREC LIKE INTAB OCCURS 0 WITH HEADER LINE.
DATA : ERRTAB_BNKBOOK LIKE OPENTAB OCCURS 0 WITH HEADER LINE.
DATA : BEGIN OF MATCH_TAB OCCURS 0,
       NEW_SEQ(5),
       SLNO(5),
       IDENTIF(15),
       AMT(15),
*       AMT(17),
       DR_CR(1),
       CHQ_RT(13),
       AMT1(15),
*       AMT1(17),
       DR_CR1(1),
       VOID(1),
       ENCASH(1),
       REMARK(25),
END OF MATCH_TAB.
*----- Internal Table to Trap Errors during Internal Table Validation -*
DATA : BEGIN OF ERR_VALD OCCURS 1000,
       SLNO(6),
      COUNTER TYPE I,
       ERRLINE(132),              " Error Text
       ERRCODE(2),               " Error Code 1: vald 2: Generic
                                 " .
       ERRTYP(1),
       END OF ERR_VALD.

* ---- Internal Table to store BDC data ------*
DATA: BEGIN OF BDCTAB  .
        INCLUDE STRUCTURE BDCDATA.
DATA: END OF BDCTAB.
DATA: BDCDATA LIKE BDCTAB  OCCURS 1000 WITH HEADER LINE.
*--- Internal table to store system messages during CALL TRANSATION ---*
DATA: BEGIN OF BDCMSG OCCURS 0.
        INCLUDE STRUCTURE BDCMSGCOLL.
DATA: END OF BDCMSG.

DATA : BEGIN OF ITABMSG OCCURS 0,
       TEXT(100),
       END OF ITABMSG.

* ---- Working Variables ---- *
DATA :
    GJAHR1 LIKE BKPF-GJAHR,
    ANS(1),
    temp_AZNUM like FEBMKA-AZNUM,
    POSN TYPE I,
    TRAN_AMT LIKE BSEG-WRBTR,
    damt LIKE BSEG-WRBTR,
    camt LIKE BSEG-WRBTR,
    diff_amt LIKE BSEG-WRBTR,
    var_sca(1),
    TRAN_AMT1(15),
*    TRAN_AMT1(17),  " +003

    CL_ACTNO LIKE SKA1-SAKNR ,
    temp_bukrs(3),
    BK_ACTNO LIKE SKA1-SAKNR  ,
    FLG_MATCH(1) VALUE 'N',
    ERR_NARR(1) VALUE 'N',
    ERR_FLG(1) VALUE 'N',                 " Error flag during validation
    ERRTXT(132),                          " Error text during validation
    COUNTER(6),                           " Record Counter
    DIFF LIKE INTAB-SLNO,                 " Difference between 2 ctrl#
    VALDT LIKE SY-DATUM,                  " Value Date
    TRNDT LIKE SY-DATUM,
    SLNO LIKE INTAB-SLNO,                 " Control no
    SEPARATOR(5) VALUE '     ',           " Separator.
    BAL LIKE BSEG-WRBTR,                     " Balance
    DIFF_BAL LIKE BAL, " Diff op_bal and cl_bal
    cnt_diff like bal,
      tot_transd(17),
    tot_transc(17),
    d_balance(17),
    TEXT(132),
    MSGLINE(100),
    TEMPCHAR(1),
    AMT_TEMP1(15),
*    AMT_TEMP1(17),   "+003
    RWBTR LIKE PAYR-RWBTR,
    WRBTR1 LIKE PAYR-RWBTR,
    WRBTR LIKE BSEG-WRBTR,
    MATCH_AMT(17),
    MATCH_AMT1 LIKE GLT0-TSL01,
    TRANCODE(4),
    TCODE(5),
    DR_CR(1),
    DIF_BAL LIKE INPUT-TRAN_AMT,
    TEMP_BAL LIKE INPUT-TRAN_AMT,
    ERR_FLAG_REC(2) VALUE '0',
    TOT_ERR_FLG TYPE I,
    RECCNT TYPE I,
    diff_flag(1),
    diff_flag_id(1),
    LINE TYPE I,
    SL(5),
    TOT_AMT_BNKBOOK LIKE GLT0-TSL01, " By Siladitya 26.03.2003
    RECCNT1 LIKE RECCNT,
    FLG_DUPL(1) VALUE  'Y',
    LEN2 TYPE I,
    VALDT1(10),
    TRNDT1(10),
    TEMPDT(10),
    TEMPDT1 LIKE SY-DATUM,
    GEN_ERR_CNT TYPE I,
    MATCH_ERR_COUNT TYPE I,
    FORMAT_ERR_COUNT TYPE I,
    RT_COUNT TYPE I VALUE 0,
    TOT_TRANS(17),
    TOT_TRAN_BNK LIKE BSEG-WRBTR,
    TXT LIKE BSEG-SGTXT,
    NEW_SEQ(5),
    AZDAT1(6),
    TEMPBAL(17),
    TEMPBAL1 LIKE BSEG-WRBTR,
    POSN_OPENTAB LIKE SY-TABIX,
    PRE_COUNT TYPE I VALUE 0,
    FILE_EXIST(1),
*BOC By Arnav on 09/10/26
* File header = BUKRS GJAHR AZNUM AZDAT HBKID HKTID DT_FM DT_TO, now ~60 chars
*   PARAM_TXT(55),
    PARAM_TXT(70),
*EOC By Arnav on 09/10/26
    PARAM_TXT1(55),
    TRANAMT LIKE BSEG-WRBTR,
    NEWSEQ(5),
    CUM_BAL(17),
    CUM_BAL1(17),
    TOT_TRAN_AMT(17),
    DESCR LIKE FEBMKK-SGTXT_KF,
     REC_UPLD TYPE I,
     AZNUM1 LIKE FEBMKA-AZNUM,
     amount_1 like glt0-hslvt ,
     amount_2 like amount_1,
     amount_3 like amount_1,
     amount_4 like amount_1,
     amount_5 like amount_1,
     amount_6 like amount_1,
     amount_7 like amount_1,


*  Start of change on 06-08-2003  Change Id: 001.
     IST_FOREX LIKE TABLE OF BSIS,                          "+001
     L_TOT_RS_AMT LIKE BSIS-DMBTR.                          "+001
*  End of change on 06-08-2003  Change Id: 001.
*begin of <RD1K960036>
CONSTANTS : G_C_ASC TYPE CHAR10 VALUE 'ASC'.
*END of <RD1K960036>

* ---- Parameters------*
PARAMETERS: BUKRS LIKE T001-BUKRS MEMORY ID A, "#EC EXISTS   " Company Code
            HBKID LIKE T012K-HBKID MEMORY ID B, "#EC EXISTS  " House Bank
            HKTID LIKE T012K-HKTID MEMORY ID C, "#EC EXISTS  " House Bank A/C id
            AZNUM LIKE FEBMKA-AZNUM MEMORY ID D, "#EC EXISTS " Statement No
            AZDAT LIKE FEBMKA-AZDAT MEMORY ID E OBLIGATORY . "#EC EXISTS
" Statement Date
SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN  BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.
PARAMETERS:
OPBL LIKE FEBMKA-SSALD MEMORY ID F OBLIGATORY, "#EC EXISTS " Bank Stmt Op. Bal.
CLBL LIKE FEBMKA-ESALD MEMORY ID G OBLIGATORY, "#EC EXISTS " Bank Stmt Cl. Bal.
            POSTDT LIKE BKPF-BUDAT MEMORY ID H , "#EC EXISTS   " Posting Date
            KOSTL LIKE CSKS-KOSTL MEMORY ID K ,  "#EC EXISTS    " Cost Center
            gsber like tgsb-gsber memory id z,  "#EC EXISTS    "Business Area
            GJAHR LIKE BSEG-GJAHR MEMORY ID L.  "#EC EXISTS    " FiscalYear
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) TEXT-029.
PARAMETERS :
            DT_FM LIKE BKPF-BUDAT MEMORY ID M."#EC EXISTS
" Transaction dt to
SELECTION-SCREEN COMMENT 45(5) TEXT-030.
PARAMETERS :
            DT_TO LIKE BKPF-BUDAT MEMORY ID N. "#EC EXISTS  " Transaction dt fm
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK B1.


SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF BLOCK B3 WITH FRAME TITLE TEXT-023.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS VALD RADIOBUTTON GROUP GRP DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(28) TEXT-041.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS BRS RADIOBUTTON GROUP GRP.
SELECTION-SCREEN COMMENT 3(28) TEXT-042.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN ULINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS BDCSESS RADIOBUTTON GROUP GRP.
SELECTION-SCREEN COMMENT 3(19) TEXT-025.
SELECTION-SCREEN COMMENT 32(17) TEXT-024.
SELECTION-SCREEN POSITION 52.
PARAMETERS  SESSION(12)  TYPE C DEFAULT 'BRS'.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK B3.
