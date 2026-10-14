REPORT zjv_bapi_balupload1 NO STANDARD PAGE HEADING LINE-SIZE 500.
***********************************************************************
* Program    : ZJV_BDC_BALUPLOAD1                                     *
*                                                                     *
* Title      : JV general ledger Balances  Upload                     *
*                                                                     *
* FS No.     : FS-JVA-DEV-002                                         *
*                                                                     *
* Author     : G.C Uniyal       Date : 12.3.2007                      *
*                                                                     *
* Login Id   : CAB_UNIYAL                                             *
*                                                                     *
* Description: JV general ledger Balances  Upload
*                                                                     *
* Tran. Code : ZJVBALUPLOAD1
*---------------------------------------------------------------------*
* Change History
*
*cab_pareek 06.01.2012 <RD1K979117> 1. Changes in
*                                      Perform modify_IST_GL.
*                                      Added Postky 11 and doctype 'DA'
*cab_pareek 17.01.2012 <RD1K979181> 1. Above changes reverted back
*---------------------------------------------------------------------*

DATA:  bdcdata LIKE bdcdata   OCCURS 0 WITH HEADER LINE.
DATA : g_upload.
DATA : nodata.
DATA : g_save.
DATA   g_nextline.
DATA   g_group(12).
DATA   l_bschl LIKE tbsl-bschl.
DATA   l_postkey(2) TYPE n.
g_group = 'OVL_GL_UPLD'.
*------internal table declaration--------------------------------------*
DATA : BEGIN OF ist_gl OCCURS 0,
         drcr_ind(1),
         somefield(3),
         docdt(8),
*         doctyp(2), " Bipin Shukla
         postdt(10),
         astval_dt(10),
         txn_type(3),
         compcd(3),
         curr(5),
         refdoc(18),
         bline_dt(10),
         paymethod(1),
         htext(25),
         postkey(2) ,
         accntno(10),
         amtinr(15),
*         amt_oth_curr(15), " Bipin Shukla
         amtidxcurr(15),
         orderno(12),
         efund(3),
         busarea(4)," like bseg-gsber,
         busi_sec(4),
         costcntr(10),
         wbs(24), "  LIKE jvto1-rprojk,
         profcntr(10),
         recind(2), " LIKE jvto1-rrecin,
         allocation(18),
         itemtext(50),
         lineno(5),
        xref1(12).
DATA: END OF ist_gl.

DATA : lv_amt_oth_curr(15) TYPE p DECIMALS 2.
DATA : BEGIN OF ist_gl1 OCCURS 0,
         drcr_ind(1),
         somefield(3),
         docdt(8),
         doctyp(2), " Bipin Shukla
         postdt(10),
         astval_dt(10),
         txn_type(3),
         compcd(3),
         curr(5),
         refdoc(18),
         bline_dt(10),
         paymethod(1),
         htext(25),
         postkey(2) ,
         accntno(10),
         amtinr(15),
         amt_oth_curr(15), " Bipin Shukla
         amtidxcurr(15),
         orderno(12),
         efund(3),
         busarea(4)," like bseg-gsber,
         busi_sec(4),
         costcntr(10),
         wbs(24), "  LIKE jvto1-rprojk,
         profcntr(10),
         recind(2), " LIKE jvto1-rrecin,
         allocation(18),
         itemtext(50),
         lineno(5).
DATA: END OF ist_gl1.

*DATA : ist_gl1 LIKE ist_gl OCCURS 0 WITH HEADER LINE.
DATA : lt_setvlue    TYPE TABLE OF rgsb4,
       lt_setvlue_er TYPE TABLE OF rgsb4,
       ls_setvlue_er TYPE         rgsb4,
       ls_setvlue    TYPE          rgsb4,
       gt_t001       TYPE TABLE OF t001,
       gs_t001       TYPE          t001,
       gs_tcurr      TYPE          tcurr,
       ls_date       TYPE datum.


******************New Data Declerations
TYPES: BEGIN OF ty_final,
         type    TYPE bapi_mtype,
         number  TYPE symsgno,
         message TYPE bapi_msg,
       END OF ty_final.
DATA: ls_head      TYPE bapiache09,
*      ls_gl     TYPE bapiacgl09,
*      lt_gl     TYPE STANDARD TABLE OF bapiacgl09,
      lt_return    TYPE STANDARD TABLE OF bapiret2,
      ls_return    TYPE bapiret2,
      lv_itemno    TYPE posnr_acc VALUE '0000000001',
      lt_tbsl      TYPE STANDARD TABLE OF tbsl,
      ls_tbsl      TYPE tbsl,
      lv_wrbtr     TYPE bapicurr-bapicurr,
      lv_wrbtr1    TYPE bapicurr-bapicurr,
      lv_wrbtr2    TYPE p DECIMALS 2,  " anjali
      ls_curr      TYPE bapiaccr09,
      lt_curr      TYPE STANDARD TABLE OF bapiaccr09,
      ls_gl        TYPE bapiacgl09,
      lt_gl        TYPE STANDARD TABLE OF bapiacgl09,
      lt_vend      TYPE STANDARD TABLE OF bapiacap09,
      ls_vend      TYPE bapiacap09,
      gv_day(2)    TYPE c,
      gv_month(2)  TYPE c,
      gv_year(4)   TYPE c,
      gv_date(8)   TYPE c,
      gt_final     TYPE STANDARD TABLE OF ty_final,
      gs_final     TYPE ty_final,
      it_fieldcat  TYPE  slis_t_fieldcat_alv,
      wa_fieldcat  TYPE slis_fieldcat_alv,
      lt_t003      TYPE STANDARD TABLE OF t003,
      ls_t003      TYPE t003,
      lv_kurst     TYPE t003-kurst,
      ls_xrate     TYPE bapi1093_0,
      lt_extension TYPE bapiparex_tab_ac,
      ls_extension TYPE bapiparex,
      lv_ktogr     TYPE ktogr,
      lv_ktogr1    TYPE char10,
      lv_text      TYPE char10,
      lv_text1     TYPE char12,
      lv_anln2     TYPE anln2,
      lv_fistl     TYPE fistl,
      lv_exc       TYPE p DECIMALS 2,  "anjali
      gv_amount    TYPE bapidoccur.    "Added by Javed

FIELD-SYMBOLS <ls_curr> TYPE bapiaccr09.

*------------- Working Variable Declaration .-------------------*

START-OF-SELECTION.
*------------------------------------------------------*
  PERFORM upload_file.

  PERFORM modify_ist_gl.

*-------------------------------------------------------*
END-OF-SELECTION.
  IF NOT ist_gl1[] IS INITIAL.
    WRITE : / 'Following records were found unsuitable for upload as this'(E01),
       'BDC takes care of posting keys = 01,21,11,31,40,50,70,75 and Doc type = AA,',
       'KJ,KM,RV,SA only' COLOR 3.
    WRITE : /.
    WRITE : / 'Delete entries from the data file that do not correspond',
 'to above posting keys or doc type'  COLOR 6 INTENSIFIED OFF.
    WRITE : / sy-uline.
    WRITE : /1 'Line No'.
    WRITE : / sy-uline.

    LOOP AT ist_gl1.
      WRITE :/1 ist_gl1-lineno,sy-vline,
            ist_gl1-somefield,sy-vline,
            ist_gl1-drcr_ind,sy-vline,
            ist_gl1-docdt,sy-vline,
            ist_gl1-doctyp COLOR 6 INTENSIFIED OFF,sy-vline,
            ist_gl1-postdt,sy-vline,
            ist_gl1-compcd,sy-vline,
            ist_gl1-curr,sy-vline,
            ist_gl1-refdoc,sy-vline,
            ist_gl1-htext,sy-vline,
            ist_gl1-postkey COLOR 6 INTENSIFIED OFF,sy-vline,
            ist_gl1-accntno,sy-vline,
            ist_gl1-amtinr,sy-vline,
            ist_gl1-amtidxcurr,sy-vline,
            ist_gl1-orderno,sy-vline,
            ist_gl1-efund,sy-vline,
            ist_gl1-busarea,sy-vline,
            ist_gl1-busi_sec,sy-vline,
            ist_gl1-costcntr,sy-vline,
            ist_gl1-wbs,sy-vline,
            ist_gl1-profcntr,sy-vline,
            ist_gl1-recind,sy-vline,
            ist_gl1-allocation,sy-vline,
            ist_gl1-itemtext.
    ENDLOOP.
    WRITE : / sy-uline.
  ELSE.
    SET PF-STATUS 'STATUS'.
    WRITE 'Click Upload button to start BDC' COLOR 7 .
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  upload_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_file.
***  Start of UC Check Change 20.06.2016
*  CALL FUNCTION 'UPLOAD'
*    EXPORTING
*      filename                = ' '
*      filetype                = 'DAT'
*    TABLES
*      data_tab                = ist_gl
*    EXCEPTIONS
*      conversion_error        = 1
*      invalid_table_width     = 2
*      invalid_type            = 3
*      no_batch                = 4
*      unknown_error           = 5
*      gui_refuse_filetransfer = 6. "#EC FB_OLDED
*  IF sy-subrc <> 0.
**     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**     WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*    MESSAGE i001(zjva_oth).
*    LEAVE PROGRAM.
*  ENDIF.

  DATA : i_file_table TYPE TABLE OF file_table,
         w_filetable  TYPE file_table,
         w_rc         TYPE i,
         w_p_def_file TYPE string,
         w_p_file     TYPE string,
         w_usr_act    TYPE i.


  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      default_filename        = w_p_def_file
    CHANGING
      file_table              = i_file_table
      rc                      = w_rc
      user_action             = w_usr_act
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  IF sy-subrc = 0 AND w_usr_act <> cl_gui_frontend_services=>action_cancel.

    LOOP AT i_file_table INTO w_filetable.
      w_p_file = w_filetable.
      EXIT.
    ENDLOOP.

    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = w_p_file
        filetype                = 'DAT'
        has_field_separator     = 'X'
      TABLES
        data_tab                = ist_gl
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
  ENDIF.
**** End of UCCheck change 20.06.2016

  IF ist_gl[] IS INITIAL.
    MESSAGE i002(zjva_oth).
    LEAVE PROGRAM.
  ENDIF.
*---------------------------------" CODE ADDED BY APARNA ON 09/10/2024 "----------------------------------*


      LOOP AT ist_gl.
**   Change Posting key 1 => '01'
        l_postkey = ist_gl-postkey.
        ist_gl-postkey = l_postkey.

        ist_gl-lineno = sy-tabix.
        MODIFY ist_gl INDEX sy-tabix.

  ENDLOOP.
*---------------------------------" CODE ENDED BY APARNA ON 09/10/2024 "-----------------------------------*


ENDFORM.                    " upload_file
*&---------------------------------------------------------------------*
*&      Form  modify_ip
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM modify_ist_gl.

  DELETE ist_gl INDEX 1.

* Reading Set Value for document type
  CALL FUNCTION 'G_SET_GET_ALL_VALUES'
    EXPORTING
      client          = sy-mandt
      setnr           = 'ZJVNONOPJIB_DOCTYP_MON'
      table           = 'BKPF'
      class           = '0000'
      no_descriptions = 'X'
      no_rw_info      = 'X'
      fieldname       = 'BLART'
    TABLES
      set_values      = lt_setvlue
    EXCEPTIONS
      set_not_found   = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  IF lt_setvlue[] IS NOT INITIAL.
    READ TABLE lt_setvlue INTO ls_setvlue INDEX 1.
  ENDIF.


* Reading Set Value for document type
  CALL FUNCTION 'G_SET_GET_ALL_VALUES'
    EXPORTING
      client          = sy-mandt
      setnr           = 'ZJVNONOPJIB_EXCHTYP_MON'
      table           = 'BKPF'
      class           = '0000'
      no_descriptions = 'X'
      no_rw_info      = 'X'
      fieldname       = 'KUTY2'
    TABLES
      set_values      = lt_setvlue_er
    EXCEPTIONS
      set_not_found   = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  IF lt_setvlue_er[] IS NOT INITIAL.
    READ TABLE lt_setvlue_er INTO ls_setvlue_er INDEX 1.
  ENDIF.

  LOOP AT ist_gl .
     IF ist_gl-wbs IS NOT INITIAL AND ist_gl-costcntr IS NOT INITIAL.
       MESSAGE 'WBS / Cost Centre not allowed in same line item' TYPE 'E' DISPLAY LIKE 'I'.
    ELSE.

******* Check Doc type " Bipin
*******    IF ls_setvlue-from =  'SA' OR
*******       ls_setvlue-from =  'KJ' OR
*******       ls_setvlue-from =  'KM' OR
*******       ls_setvlue-from =  'RV' OR
*******       ls_setvlue-from =  'AA'.
*******      .
*******    ELSE.
*******      MOVE-CORRESPONDING ist_gl TO ist_gl1.
*******      MOVE sy-tabix TO ist_gl1-somefield.
*******      ist_gl1-doctyp = ls_setvlue-from.
*******      APPEND ist_gl1.
*******      DELETE ist_gl INDEX sy-tabix.
*******
*******    ENDIF.
******* Check posting key
    SELECT SINGLE  bschl FROM tbsl INTO l_bschl WHERE bschl =
    ist_gl-postkey
                                                                       .
    IF sy-subrc <> 0.
      MOVE-CORRESPONDING ist_gl TO ist_gl1.
      MOVE sy-tabix TO ist_gl1-somefield.
      ist_gl1-doctyp = ls_setvlue-from.
      APPEND ist_gl1.
      DELETE ist_gl INDEX sy-tabix.
    ENDIF.
* Delete blank lines.
    IF ist_gl-docdt  = ''  OR
       ls_setvlue-from =  '' OR  "Bipin
       ist_gl-postdt = ''.
      MOVE-CORRESPONDING ist_gl TO ist_gl1.
      MOVE sy-tabix TO ist_gl1-somefield.
      ist_gl1-doctyp = ls_setvlue-from.
      APPEND ist_gl1.
      DELETE ist_gl INDEX sy-tabix.
    ENDIF.

    IF ist_gl-postkey = '40' OR
       ist_gl-postkey = '50' OR
       ist_gl-postkey = '21' OR
       ist_gl-postkey = '31' OR
       ist_gl-postkey = '01' OR
       ist_gl-postkey = '70' OR
       ist_gl-postkey = '75'.
    ELSE.

      MOVE-CORRESPONDING ist_gl TO ist_gl1.
      MOVE sy-tabix TO ist_gl1-somefield.
      ist_gl1-doctyp = ls_setvlue-from.
      APPEND ist_gl1.
      DELETE ist_gl INDEX sy-tabix.
    ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " modify_ip
*&---------------------------------------------------------------------*
*&      Form  bdc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM bdc_start.
*  PERFORM open_group.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*  SELECT * FROM tbsl INTO TABLE lt_tbsl.
SELECT * FROM tbsl INTO TABLE lt_tbsl
      ORDER BY PRIMARY KEY.
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  SELECT * FROM t003 INTO TABLE lt_t003.

  CLEAR ls_extension.
  ls_extension-valuepart1 = sy-repid.
  ls_extension-valuepart2 = 'STATUS_NEW'.
  ls_extension-valuepart3 = '3'.
  APPEND ls_extension TO lt_extension.

  LOOP  AT ist_gl.
    gv_day = ist_gl-docdt+0(2).
    gv_month = ist_gl-docdt+2(4).
    CONCATENATE '20' ist_gl-docdt+4(2) INTO gv_year.
    CONCATENATE gv_year gv_month gv_day INTO gv_date.
    ist_gl-docdt = gv_date.
    CLEAR: gv_date, gv_day, gv_month, gv_year.

    gv_day = ist_gl-postdt+0(2).
    gv_month = ist_gl-postdt+2(4).
    CONCATENATE '20' ist_gl-postdt+4(2) INTO gv_year.
    CONCATENATE gv_year gv_month gv_day INTO gv_date.
    ist_gl-postdt = gv_date.
    CLEAR: gv_date, gv_day, gv_month, gv_year.


    IF ist_gl-astval_dt IS NOT INITIAL.
      gv_day = ist_gl-astval_dt+0(2).
      gv_month = ist_gl-astval_dt+2(4).
      CONCATENATE '20' ist_gl-astval_dt+4(2) INTO gv_year.
      CONCATENATE gv_year gv_month gv_day INTO gv_date.
      ist_gl-astval_dt = gv_date.
      CLEAR: gv_date, gv_day, gv_month, gv_year.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ist_gl-accntno
      IMPORTING
        output = ist_gl-accntno.

    SELECT SINGLE * FROM t001 INTO gs_t001 WHERE bukrs = ist_gl-compcd.

    IF sy-subrc = 0.
      SELECT SINGLE * FROM tcurr INTO gs_tcurr
            WHERE kurst = ls_setvlue_er-from
            AND fcurr = ist_gl-curr
            AND tcurr = gs_t001-waers.
    ENDIF.

    IF g_save = ''.
      PERFORM screen_100.
      g_save = 'X'.
    ENDIF.


    CASE ist_gl-postkey.
      WHEN '40' . ""Gl Accounts
*        IF g_nextline = 'X'.
*          PERFORM screen_700_newline.
*        ENDIF.

        PERFORM screen_300.
*        PERFORM screen_002.
*        PERFORM screen_330.
      WHEN '50'. ""Gl Accounts
*        IF g_nextline = 'X'.
*          PERFORM screen_700_newline.
*        ENDIF.
        PERFORM screen_300.
*        PERFORM screen_002.
*        PERFORM screen_330.
*        IF ist_gl-drcr_ind = 'X' OR ist_gl-drcr_ind = 'x'.
*          PERFORM screen_700.
*        ENDIF.
      WHEN '01' .
*        IF g_nextline = 'X'.
*          PERFORM screen_700_newline.
*        ENDIF.
*        PERFORM screen_301.
*        PERFORM screen_331.
      WHEN '31' OR '21'.
*        IF g_nextline = 'X'.
*          PERFORM screen_700_newline.
*        ENDIF.
        PERFORM screen_302.
*        PERFORM screen_332.
*        IF ist_gl-drcr_ind = 'X' OR ist_gl-drcr_ind = 'x' .
*          PERFORM screen_700.
*        ENDIF.
      WHEN '70' .
*        IF g_nextline = 'X'.
*          PERFORM screen_700_newline.
*        ENDIF.
        PERFORM screen_305.
*        PERFORM screen_002.
*        PERFORM screen_335.
      WHEN '75' .
*        IF g_nextline = 'X'.
*          PERFORM screen_700_newline.
*        ENDIF.
        PERFORM screen_305.
*        PERFORM screen_335.
*        IF ist_gl-drcr_ind = 'X'.
*          PERFORM screen_700.
*        ENDIF.
    ENDCASE.
* Save transaction.
*    IF ist_gl-drcr_ind = 'X' OR ist_gl-drcr_ind = 'x'.
*      PERFORM bdc_transaction USING 'F-02'.
*      CLEAR bdcdata.
*      REFRESH bdcdata.
*      g_save     = ''.
*      g_nextline = ''.
*    ENDIF.

    IF ist_gl-drcr_ind = 'X' OR ist_gl-drcr_ind = 'x'.
      IF gv_amount > 0.
        LOOP AT lt_curr ASSIGNING <ls_curr>
                WHERE curr_type = '50'
                  AND amt_doccur < 0.
          <ls_curr>-amt_doccur = <ls_curr>-amt_doccur - gv_amount.
          EXIT.
        ENDLOOP.
      ELSEIF gv_amount < 0.
        LOOP AT lt_curr ASSIGNING <ls_curr>
                WHERE curr_type = '50'
                  AND amt_doccur > 0.
          <ls_curr>-amt_doccur = <ls_curr>-amt_doccur - gv_amount.
          EXIT.
        ENDLOOP.
      ENDIF.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
      CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'"#EC CI_USAGE_OK[2628704]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
        EXPORTING
          "Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 12.06.2026  FOR ATC
          documentheader = ls_head "#EC CI_USAGE_OK[2438131]
          "Code Remediation changes S4 2025_1_A Conversion **END OF CHANGE BY SAP_ABAP 12.06.2026  FOR ATC
*         CUSTOMERCPD    =
*         CONTRACTHEADER =
*   IMPORTING
*         OBJ_TYPE       =
*         OBJ_KEY        =
*         OBJ_SYS        =
        TABLES
          accountgl      = lt_gl
*         ACCOUNTRECEIVABLE       =
          accountpayable = lt_vend
*         ACCOUNTTAX     =
          currencyamount = lt_curr
*         CRITERIA       =
*         VALUEFIELD     =
*         extension1     = lt_extension
          return         = lt_return
*         PAYMENTCARD    =
*         CONTRACTITEM   =
          extension2     = lt_extension
*         REALESTATE     =
*         ACCOUNTWT      =
        .

      READ TABLE lt_return INTO ls_return WITH KEY type = 'S'.
      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'
*       IMPORTING
*           RETURN        =
          .
      ENDIF.

      LOOP AT lt_return INTO ls_return WHERE type = 'S' OR type = 'E'.
        gs_final-type = ls_return-type.
        gs_final-number = ls_return-number.
        gs_final-message = ls_return-message.
        APPEND gs_final TO gt_final.
        CLEAR: gs_final, ls_return.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  wa_fieldcat-fieldname = 'TYPE'.
  wa_fieldcat-seltext_l = 'TYPE'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

  wa_fieldcat-fieldname = 'NUMBER'.
  wa_fieldcat-seltext_l = 'NUMBER'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

  wa_fieldcat-fieldname = 'MESSAGE'.
  wa_fieldcat-seltext_l = 'MESSAGE'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.




  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK  = ' '
*     I_BYPASSING_BUFFER = ' '
*     I_BUFFER_ACTIVE    = ' '
      i_callback_program = sy-repid
*     I_CALLBACK_PF_STATUS_SET          = ' '
*     I_CALLBACK_USER_COMMAND           = ' '
*     I_CALLBACK_TOP_OF_PAGE            = ' '
*     I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*     I_CALLBACK_HTML_END_OF_LIST       = ' '
*     I_STRUCTURE_NAME   =
*     I_BACKGROUND_ID    = ' '
*     I_GRID_TITLE       =
*     I_GRID_SETTINGS    =
*     IS_LAYOUT          =
      it_fieldcat        = it_fieldcat
*     IT_EXCLUDING       =
*     IT_SPECIAL_GROUPS  =
*     IT_SORT            =
*     IT_FILTER          =
*     IS_SEL_HIDE        =
*     I_DEFAULT          = 'X'
*     I_SAVE             = ' '
*     IS_VARIANT         =
*     IT_EVENTS          =
*     IT_EVENT_EXIT      =
*     IS_PRINT           =
*     IS_REPREP_ID       =
*     I_SCREEN_START_COLUMN             = 0
*     I_SCREEN_START_LINE               = 0
*     I_SCREEN_END_COLUMN               = 0
*     I_SCREEN_END_LINE  = 0
*     I_HTML_HEIGHT_TOP  = 0
*     I_HTML_HEIGHT_END  = 0
*     IT_ALV_GRAPHICS    =
*     IT_HYPERLINK       =
*     IT_ADD_FIELDCAT    =
*     IT_EXCEPT_QINFO    =
*     IR_SALV_FULLSCREEN_ADAPTER        =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER           =
*     ES_EXIT_CAUSED_BY_USER            =
    TABLES
      t_outtab           = gt_final
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.




*  PERFORM close_group.

*  submit rsbdcsub
*           with mappe = g_group and return.
*
ENDFORM.                    " bdc
*****************************************************
FORM open_group.
*  IF SESSION = 'X'.
*    SKIP.
*    WRITE: /(20) 'Create group'(I01), GROUP.
*    SKIP.
**   open batchinput group
  CALL FUNCTION 'BDC_OPEN_GROUP'
    EXPORTING
      client = sy-mandt
      group  = g_group
      user   = sy-uname
      keep   = 'X'.
*                                       HOLDDATE = HOLDDATE.
*    WRITE: /(30) 'BDC_OPEN_GROUP'(I02),
*            (12) 'returncode:'(I05),
*                 SY-SUBRC.
*  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  screen_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_100.
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '0100'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'RF05A-NEWKO'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                 '/00'.
*  PERFORM bdc_field       USING 'BKPF-BLDAT'
*                                 ist_gl-docdt.
*  PERFORM bdc_field       USING 'BKPF-BLART'
*                                 ls_setvlue-from. "ist_gl-doctyp. " Bipin
*  PERFORM bdc_field       USING 'BKPF-BUKRS'
*                                 ist_gl-compcd.
*  PERFORM bdc_field       USING 'BKPF-BUDAT'
*                                 ist_gl-postdt.
*  PERFORM bdc_field       USING 'BKPF-WAERS'
*                                 ist_gl-curr.
*  PERFORM bdc_field       USING 'FS006-DOCID'
*                                 '*'.
*  PERFORM bdc_field       USING 'BKPF-XBLNR'
*                                ist_gl-refdoc.
*  PERFORM bdc_field       USING 'BKPF-BKTXT'
*                                ist_gl-htext.
*  PERFORM bdc_field       USING 'RF05A-NEWBS'
*                                ist_gl-postkey.
*  PERFORM bdc_field       USING 'RF05A-NEWKO'
*                                ist_gl-accntno.
*  PERFORM bdc_field       USING 'RF05A-NEWBW'
*                            ist_gl-txn_type.

  ls_head-username     = sy-uname.
  ls_head-header_txt = ist_gl-htext.
  ls_head-doc_date = ist_gl-docdt.
  ls_head-pstng_date = ist_gl-postdt.
  ls_head-doc_type = ls_setvlue-from.
  ls_head-comp_code = ist_gl-compcd.
  ls_head-ref_doc_no = ist_gl-refdoc.
ENDFORM.                    " screen_100
*&---------------------------------------------------------------------*
*&      Form  screens_300
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_300.
*++++++++++++++++++++++++++++++++++++++++++++++++++++++
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '0300'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'BSEG-SGTXT'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=ZK'.
*  PERFORM bdc_field       USING 'BSEG-WRBTR'
*                                 ist_gl-amtinr.
*  lv_amt_oth_curr = ist_gl-amtinr * gs_tcurr-ukurs.
**  SHIFT lv_amt_oth_curr LEFT DELETING LEADING space.
**  CONDENSE lv_amt_oth_curr NO-GAPS.
*  PERFORM bdc_field       USING 'BSEG-DMBTR'
*                                lv_amt_oth_curr. "Bipin
*  PERFORM bdc_field       USING 'BSEG-ZUONR'
*                                 ist_gl-allocation.
*  PERFORM bdc_field       USING 'BSEG-SGTXT'
*                                 ist_gl-itemtext.
*  PERFORM bdc_field       USING 'DKACB-FMORE'
*                                 'X'.

  ls_gl-itemno_acc = lv_itemno.
  ls_gl-gl_account =  ist_gl-accntno.
  ls_gl-item_text = ist_gl-itemtext.
  ls_gl-bus_area = ist_gl-busarea.
  ls_gl-comp_code = ist_gl-compcd.
  ls_gl-doc_type = ls_setvlue-from.
  ls_gl-wbs_element = ist_gl-wbs.
  ls_gl-profit_ctr = ist_gl-profcntr.
  ls_gl-costcenter = ist_gl-costcntr.
  ls_gl-alloc_nmbr = ist_gl-allocation.
  ls_gl-ref_key_1 = ist_gl-xref1.
  APPEND ls_gl TO lt_gl.

  ls_curr-itemno_acc = lv_itemno.
  ls_curr-currency = ist_gl-curr.
*
  CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
    EXPORTING
      currency        = ls_curr-currency
      amount_internal = ist_gl-amtinr
    IMPORTING
      amount_external = lv_wrbtr.

  READ TABLE lt_tbsl INTO ls_tbsl WITH KEY bschl = ist_gl-postkey.
  IF sy-subrc = 0.
    IF ls_tbsl-shkzg = 'H'.
      ls_curr-amt_doccur = lv_wrbtr * -1.
    ELSE.
      ls_curr-amt_doccur = lv_wrbtr.
    ENDIF.
  ENDIF.

  READ TABLE lt_t003 INTO ls_t003 WITH KEY blart = ls_setvlue-from.
  IF sy-subrc = 0 .
    lv_kurst = ls_t003-kurst.
  ENDIF.

  ls_date = ist_gl-docdt.

  CALL FUNCTION 'BAPI_EXCHANGERATE_GETDETAIL'
    EXPORTING
      rate_type  = lv_kurst
      from_curr  = ist_gl-curr
      to_currncy = 'INR'  "GS_T001-WAERS
      date       = ls_date
    IMPORTING
      exch_rate  = ls_xrate.
*     RETURN     = .

  IF ls_xrate-exch_rate IS NOT INITIAL.
    ls_curr-exch_rate = ls_xrate-exch_rate.
  ENDIF.

  APPEND ls_curr TO lt_curr.
  CLEAR ls_curr.

  lv_exc = ls_xrate-exch_rate.  "added by anjali
  ls_curr-itemno_acc = lv_itemno.
  ls_curr-curr_type = '50'.
  ls_curr-currency = 'INR'. "ist_gl-curr.
  IF ist_gl-curr = 'USD'.
*      LV_WRBTR1 = LV_WRBTR  " COMMENT BY ANJALI
    lv_wrbtr1 = lv_wrbtr * lv_exc.  "LS_XRATE-EXCH_RATE.
  ELSE.
    lv_wrbtr1 = lv_wrbtr  / lv_exc. " LS_XRATE-EXCH_RATE.
  ENDIF.
  lv_wrbtr2 = lv_wrbtr1.
*  IF IST_GL-CURR = 'USD'.
**      LV_WRBTR1 = LV_WRBTR  " COMMENT BY ANJALI
*    LV_WRBTR2 = LV_WRBTR * LS_XRATE-EXCH_RATE.
*  ELSE.
*    LV_WRBTR2 = LV_WRBTR  / LS_XRATE-EXCH_RATE.
*  ENDIF.
*

*  IF LS_TBSL-SHKZG = 'H'.
*    LS_CURR-AMT_DOCCUR = LV_WRBTR1 * -1.
*  ELSE.
*    LS_CURR-AMT_DOCCUR = LV_WRBTR1.
*  ENDIF.
  IF ls_tbsl-shkzg = 'H'.
    ls_curr-amt_doccur = lv_wrbtr2 * -1.
  ELSE.
    ls_curr-amt_doccur = lv_wrbtr2.
  ENDIF.
  gv_amount = gv_amount + ls_curr-amt_doccur.
  ls_curr-exch_rate = ls_xrate-exch_rate.
  APPEND ls_curr TO lt_curr.
  CLEAR: ls_curr, lv_wrbtr , lv_wrbtr1, ls_gl,lv_wrbtr2.

  lv_itemno = lv_itemno + 1.
ENDFORM.

*+++++++++++++++++++++++++++++++++++++++++++++++++++++++
FORM screen_002.

  PERFORM bdc_dynpro      USING 'SAPLKACB' '0002'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'COBL-FIPOS'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=ENTE'.
  PERFORM bdc_field       USING 'COBL-GSBER'
                                 ist_gl-busarea.
  PERFORM bdc_field       USING 'COBL-KOSTL'
                                 ist_gl-costcntr.
  PERFORM bdc_field       USING 'COBL-PS_POSID'
                                 ist_gl-wbs.
  PERFORM bdc_field       USING 'COBL-AUFNR'
                                ist_gl-orderno.
  IF ist_gl-postkey = '70' OR ist_gl-postkey = '75'.
    ist_gl-profcntr = '          '     .
  ENDIF.
  PERFORM bdc_field       USING 'COBL-PRCTR'
                               ist_gl-profcntr.

*  perform bdc_field       using 'COBL-FIPOS'
*                                 ist_gl-commit_item.
  PERFORM bdc_field       USING 'COBL-PS_POSID'
                                 ist_gl-wbs.
  PERFORM bdc_field       USING 'COBL-RECID'
                                ist_gl-recind.
ENDFORM.

*++++++++++++++++++++++++++++++++++++++++++++++++
FORM screen_330.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0330'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-DMBE2'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                       '=AB'.
  PERFORM bdc_field       USING 'BSEG-DMBE2'
                           ist_gl-amtidxcurr.
  g_nextline = 'X'.

ENDFORM.
*----------------------------------------------
FORM screen_700_newline.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0700'.

  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05A-NEWBS'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                 '/00'.
  PERFORM bdc_field       USING 'RF05A-NEWBS'
                               ist_gl-postkey.
  PERFORM bdc_field       USING 'RF05A-NEWKO'
                               ist_gl-accntno.
  PERFORM bdc_field       USING 'RF05A-NEWBW'
                            ist_gl-txn_type.
ENDFORM.
*++++++++++++++++++++++++++++++++++++++++++++++++
FORM screen_301.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0301'.

  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-SGTXT'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=ZK'.
  PERFORM bdc_field       USING 'BSEG-WRBTR'
                                 ist_gl-amtinr.
  lv_amt_oth_curr = ist_gl-amtinr * gs_tcurr-ukurs.
*  SHIFT lv_amt_oth_curr LEFT DELETING LEADING space.
  PERFORM bdc_field       USING 'BSEG-DMBTR'
                                 lv_amt_oth_curr. "Bipin
  PERFORM bdc_field       USING 'BSEG-SECCO'
                                 ist_gl-busi_sec.
  PERFORM bdc_field       USING 'BSEG-ZFBDT'
                                 ist_gl-bline_dt.
  PERFORM bdc_field       USING 'BSEG-GSBER'
                                 ist_gl-busarea.
  PERFORM bdc_field       USING 'BSEG-ZLSCH'
                                 ist_gl-paymethod.
  PERFORM bdc_field       USING 'BSEG-ZUONR'
                                 ist_gl-allocation.
  PERFORM bdc_field       USING 'BSEG-SGTXT'
                                 ist_gl-itemtext.
  PERFORM bdc_field       USING 'DKACB-FMORE'
                                 'X'.

ENDFORM.                    " screen_301
*&---------------------------------------------------------------------*
*&      Form  screen_331
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_331.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0331'.

  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-DMBE2'.

  PERFORM bdc_field       USING 'BDC_OKCODE'
                                       '=AB'.
  PERFORM bdc_field       USING 'BSEG-DMBE2'
                           ist_gl-amtidxcurr.
  g_nextline = 'X'.

ENDFORM.                    " screen_331
*&---------------------------------------------------------------------*
*&      Form  SCREEN_700_01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_700.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0700'.

  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05A-NEWBS'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                 '=RW'.
ENDFORM.                    " SCREEN_700_01

*&---------------------------------------------------------------------*
*&      Form  screen_302
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_302.
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '0302'.
*
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'BSEG-SGTXT'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=ZK'.
*  PERFORM bdc_field       USING 'BSEG-WRBTR'
*                                 ist_gl-amtinr.
*  lv_amt_oth_curr = ist_gl-amtinr * gs_tcurr-ukurs.
**  SHIFT lv_amt_oth_curr LEFT DELETING LEADING space.
*  PERFORM bdc_field       USING 'BSEG-DMBTR'
*                                lv_amt_oth_curr. "Bipin
*  PERFORM bdc_field       USING 'BSEG-SECCO'
*                                 ist_gl-busi_sec.
*  PERFORM bdc_field       USING 'BSEG-ZFBDT'
*                                 ist_gl-bline_dt.
*  PERFORM bdc_field       USING 'BSEG-GSBER'
*                                 ist_gl-busarea.
*  PERFORM bdc_field       USING 'BSEG-ZLSCH'
*                                 ist_gl-paymethod.
*  PERFORM bdc_field       USING 'BSEG-ZUONR'
*                                 ist_gl-allocation.
*  PERFORM bdc_field       USING 'BSEG-SGTXT'
*                                 ist_gl-itemtext.
*  PERFORM bdc_field       USING 'DKACB-FMORE'
*                                 'X'.
  CLEAR ls_tbsl.
  READ TABLE lt_tbsl INTO ls_tbsl WITH KEY bschl = ist_gl-postkey.
  IF sy-subrc = 0.
    CASE ls_tbsl-koart.
      WHEN 'K'.
        ls_vend-itemno_acc = lv_itemno.
        ls_vend-vendor_no = ist_gl-accntno.
        ls_vend-comp_code = ist_gl-compcd.
        ls_vend-item_text = ist_gl-itemtext.
        ls_vend-profit_ctr = ist_gl-profcntr.

        APPEND ls_vend TO lt_vend.

        ls_curr-itemno_acc = lv_itemno.
        ls_curr-currency = ist_gl-curr.

        CLEAR lv_wrbtr.

        CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
          EXPORTING
            currency        = ls_curr-currency
            amount_internal = ist_gl-amtinr
          IMPORTING
            amount_external = lv_wrbtr.

        IF ls_tbsl-shkzg = 'H'.
          ls_curr-amt_doccur = lv_wrbtr * -1.
        ELSE.
          ls_curr-amt_doccur = lv_wrbtr.
        ENDIF.

        IF ls_xrate-exch_rate IS NOT INITIAL.
          ls_curr-exch_rate = ls_xrate-exch_rate.
        ENDIF.

        APPEND ls_curr TO lt_curr.
        CLEAR ls_curr.

        lv_exc =  ls_xrate-exch_rate.  "anjali
        ls_curr-itemno_acc = lv_itemno.
        ls_curr-curr_type = '50'.
        ls_curr-currency = 'INR'.  "ist_gl-curr.
        IF ist_gl-curr = 'USD'.
*          LV_WRBTR1 = LV_WRBTR.  " commen by anjali
          lv_wrbtr1 = lv_wrbtr *  lv_exc.  "LS_XRATE-EXCH_RATE.
        ELSE.
          lv_wrbtr1 = lv_wrbtr  /  lv_exc.  "LS_XRATE-EXCH_RATE.
        ENDIF.
        lv_wrbtr2 = lv_wrbtr1.
*        IF IST_GL-CURR = 'USD'.
**          LV_WRBTR1 = LV_WRBTR.  " commen by anjali
*          LV_WRBTR2 = LV_WRBTR * LS_XRATE-EXCH_RATE.
*        ELSE.
*          LV_WRBTR2 = LV_WRBTR  / LS_XRATE-EXCH_RATE.
*        ENDIF.

        IF ls_tbsl-shkzg = 'H'.
          ls_curr-amt_doccur = lv_wrbtr2 * -1.
        ELSE.
          ls_curr-amt_doccur = lv_wrbtr2.
        ENDIF.

*        IF LS_TBSL-SHKZG = 'H'.
*          LS_CURR-AMT_DOCCUR = LV_WRBTR1 * -1.
*        ELSE.
*          LS_CURR-AMT_DOCCUR = LV_WRBTR1.
*        ENDIF.
        gv_amount = gv_amount + ls_curr-amt_doccur.
        ls_curr-exch_rate = ls_xrate-exch_rate.
        APPEND ls_curr TO lt_curr.
        CLEAR ls_curr.
*    	WHEN .
*    	WHEN OTHERS.
    ENDCASE.
  ENDIF.

  lv_itemno = lv_itemno + 1.
ENDFORM.                    " screen_302
*&---------------------------------------------------------------------*
*&      Form  screen_332
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_332.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0332'.

  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-DMBE2'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                       '=AB'.
  PERFORM bdc_field       USING 'BSEG-DMBE2'
                           ist_gl-amtidxcurr.
  g_nextline = 'X'.

ENDFORM.                    " screen_332
*&---------------------------------------------------------------------*
*&      Form  screen_305
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_305.
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '0305'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'BSEG-WRBTR'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=ZK'.
*  PERFORM bdc_field       USING 'BSEG-WRBTR'
*                                 ist_gl-amtinr.
*  lv_amt_oth_curr = ist_gl-amtinr * gs_tcurr-ukurs.
**  SHIFT lv_amt_oth_curr LEFT DELETING LEADING space.
*  PERFORM bdc_field       USING 'BSEG-DMBTR'
*                                lv_amt_oth_curr. "Bipin
*  PERFORM bdc_field       USING 'BSEG-BZDAT'
*                                 ist_gl-astval_dt.
*  PERFORM bdc_field       USING 'BSEG-ZUONR'
*                                 ist_gl-allocation.
*  PERFORM bdc_field       USING 'BSEG-SGTXT'
*                                 ist_gl-itemtext.
*  PERFORM bdc_field       USING 'DKACB-FMORE'
*                                 'X'.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ist_gl-accntno
    IMPORTING
      output = lv_text.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_text
    IMPORTING
      output = lv_text1.

" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*  SELECT SINGLE ktogr anln2
*    FROM anla
*    INTO (lv_ktogr,lv_anln2 )
*    WHERE anln1 = lv_text1 AND
*          bukrs = ist_gl-compcd.
 SELECT KTOGR ANLN2 FROM ANLA   UP TO 1 ROWS INTO (LV_KTOGR , LV_ANLN2 )
 WHERE ANLN1 = LV_TEXT1 AND BUKRS = IST_GL-COMPCD  ORDER BY  BUKRS
ANLN1 ANLN2 .   ENDSELECT.
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC


" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*  SELECT SINGLE target1
*    FROM fmfmoarp15000012
*    INTO lv_fistl
*    WHERE sour1_from = ist_gl-compcd AND sour2_from = ist_gl-profcntr.
 SELECT TARGET1 FROM FMFMOARP15000012   UP TO 1 ROWS INTO LV_FISTL
WHERE SOUR1_FROM = IST_GL-COMPCD AND SOUR2_FROM = IST_GL-PROFCNTR
ORDER BY  SOUR1_FROM SOUR1_TO SOUR2_FROM SOUR2_TO VALID_FROM .
ENDSELECT.
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

  IF lv_ktogr IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_ktogr
      IMPORTING
        output = lv_ktogr1.
  ENDIF.
  ls_gl-itemno_acc = lv_itemno.
  ls_gl-comp_code  = ist_gl-compcd.
*  ls_gl-cs_trans_t  = '100'.
  ls_gl-gl_account  = lv_ktogr1.
  ls_gl-asset_no = lv_text1.
  ls_gl-sub_number = lv_anln2.
  ls_gl-bus_area = ist_gl-busarea.
  ls_gl-value_date = ist_gl-astval_dt.
  ls_gl-item_text  = ist_gl-itemtext.
*  ls_gl-funds_ctr  = ' '.
  ls_gl-cmmt_item = ' '.
  ls_gl-acct_type = 'A'.
  ls_gl-funds_ctr = lv_fistl.
*  ls_gl-bus_area  = ist_gl-busarea.

  APPEND ls_gl TO lt_gl.
  CLEAR ls_gl.

  CLEAR ls_extension.
  ls_extension-valuepart1 = sy-repid.
  ls_extension-valuepart2 = 'ANBWA'.
  ls_extension-valuepart3 = '100' .
  ls_extension-valuepart4 =  lv_itemno.
  APPEND ls_extension TO lt_extension.

  ls_curr-itemno_acc = lv_itemno.
  ls_curr-currency = ist_gl-curr.
  CLEAR lv_wrbtr.

  CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
    EXPORTING
      currency        = ls_curr-currency
      amount_internal = ist_gl-amtinr
    IMPORTING
      amount_external = lv_wrbtr.


  READ TABLE lt_tbsl INTO ls_tbsl WITH KEY bschl = ist_gl-postkey.
  IF sy-subrc = 0.
    IF ls_tbsl-shkzg = 'H'.
      ls_curr-amt_doccur = lv_wrbtr * -1.
    ELSE.
      ls_curr-amt_doccur = lv_wrbtr.
    ENDIF.
  ENDIF.

  IF ls_xrate-exch_rate IS NOT INITIAL.
    ls_curr-exch_rate = ls_xrate-exch_rate.
  ENDIF.

  APPEND ls_curr TO lt_curr.
  CLEAR ls_curr.

  lv_exc = ls_xrate-exch_rate.  "anjali
  ls_curr-itemno_acc = lv_itemno.
  ls_curr-curr_type = '50'.
  ls_curr-currency = 'INR'."ist_gl-curr.
  IF ist_gl-curr = 'USD'.
*    LV_WRBTR1 = LV_WRBTR. "" comment by anjali
    lv_wrbtr1 = lv_wrbtr * lv_exc.  "LS_XRATE-EXCH_RATE.
  ELSE.
    lv_wrbtr1 = lv_wrbtr  / lv_exc.  "LS_XRATE-EXCH_RATE.
  ENDIF.
  lv_wrbtr2 = lv_wrbtr1.
*  IF IST_GL-CURR = 'USD'.
**    LV_WRBTR1 = LV_WRBTR. "" comment by anjali
*    LV_WRBTR2 = LV_WRBTR * LS_XRATE-EXCH_RATE.
*  ELSE.
*    LV_WRBTR2 = LV_WRBTR  / LS_XRATE-EXCH_RATE.
*  ENDIF.
  IF ls_tbsl-shkzg = 'H'.
    ls_curr-amt_doccur = lv_wrbtr2 * -1.
  ELSE.
    ls_curr-amt_doccur = lv_wrbtr2.
  ENDIF.
*
*  IF LS_TBSL-SHKZG = 'H'.
*    LS_CURR-AMT_DOCCUR = LV_WRBTR1 * -1.
*  ELSE.
*    LS_CURR-AMT_DOCCUR = LV_WRBTR1.
*  ENDIF.
  gv_amount = gv_amount + ls_curr-amt_doccur.
  ls_curr-exch_rate = ls_xrate-exch_rate.
  APPEND ls_curr TO lt_curr.
  CLEAR ls_curr.

  lv_itemno = lv_itemno + 1.
ENDFORM.                    " screen_305
*&---------------------------------------------------------------------*
*&      Form  screen_335
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_335.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0335'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEG-DMBE2'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                       '=AB'.
  PERFORM bdc_field       USING 'BSEG-DMBE2'
                           ist_gl-amtidxcurr.
  g_nextline = 'X'.

ENDFORM.                    " screen_335


*&---------------------------------------------------------------------*
*   end batchinput session                                             *
*   (call transaction using...: error session)                         *
*----------------------------------------------------------------------*
FORM close_group.
*  IF SESSION = 'X'.
*   close batchinput group
  CALL FUNCTION 'BDC_CLOSE_GROUP'
    EXCEPTIONS
      not_open    = 1
      queue_error = 2.
  IF sy-subrc = 0.
    g_upload = 'X'.
  ELSE.
    g_upload = ''.
  ENDIF.

*    WRITE: /(30) 'BDC_CLOSE_GROUP'(I04),
*            (12) 'returncode:'(I05),
*                 SY-SUBRC.
*  ELSE.
*    IF E_GROUP_OPENED = 'X'.
*      CALL FUNCTION 'BDC_CLOSE_GROUP'.
*      WRITE: /.
*      WRITE: /(30) 'Fehlermappe wurde erzeugt'(I06).
*      E_GROUP_OPENED = ' '.
*    ENDIF.
*  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*        Start new screen                                              *
*----------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.

*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
*  IF FVAL <> NODATA.
  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.
*  ENDIF.
ENDFORM.
************************************************************************
*----------------------------------------------------------------------*
*        Start new transaction according to parameters                 *
*----------------------------------------------------------------------*
FORM bdc_transaction USING tcode.
  CALL FUNCTION 'BDC_INSERT'
    EXPORTING
      tcode            = tcode
    TABLES
      dynprotab        = bdcdata
    EXCEPTIONS
      internal_error   = 1
      not_open         = 2
      queue_error      = 3
      tcode_invalid    = 4
      printing_invalid = 5
      posting_invalid  = 6
      OTHERS           = 7.

ENDFORM.

*********************************************
AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'UPLO'.
      PERFORM bdc_start.
      SET PF-STATUS 'STATUS1'.
*      IF g_upload = 'X'.
*        WRITE : 1 'Session','OVL_GL_UPLD' COLOR 3, 'by', sy-uname ,
*'Created on', sy-datum,  sy-uzeit.
*      ELSE.
*        WRITE :  'Problem creating BDC session!!!' .
*      ENDIF.
    WHEN 'BACK' OR 'CANC' OR 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.
