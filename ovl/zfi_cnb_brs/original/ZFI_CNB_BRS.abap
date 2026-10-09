REPORT  zfi_cnb_brs   LINE-SIZE 255 MESSAGE-ID zfi NO STANDARD PAGE
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
INCLUDE zfibrstop.


* ---- Validations at Selection Screen ------ *

AT SELECTION-SCREEN .

  SELECT SINGLE MAX( aznum ) FROM febko INTO aznum
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
    CONCATENATE hktid temp_bukrs aznum+1(4) INTO session.
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
  SELECT SINGLE *  FROM csks WHERE kostl = kostl.
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
    IMPORT diff_flag FROM MEMORY ID diff_flag_id.
    IF diff_flag = 'X'.
      SKIP 2.
      FORMAT COLOR 4 INTENSIFIED OFF.
      WRITE:/15 icon_breakpoint AS ICON,20
      'Balance of Report15 is not zero,Please Check the entries'.
    ELSE.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Bank Reconciliation Data Uploading '
          text_question         = text-045
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
    text = text-037.
    CONCATENATE space text   INTO errtxt SEPARATED BY separator.
    PERFORM append_generic_err TABLES err_vald USING 'W' '0'.
  ELSEIF line > 1.
    aznum1 = aznum - 1.
    CONCATENATE bukrs aznum1  hbkid hktid  INTO param_txt1.
    READ TABLE input1 INDEX 1 .
    CONDENSE input1-narration.
    CONDENSE param_txt1.
    IF input1-narration = param_txt1.
* ---- Merge previous month brs input into the current month input ---

      APPEND LINES OF input1 FROM 2 TO input.

    ELSE.
      text = text-044.
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
  cum_bal =  opbl * 100.
  LOOP AT intab FROM 2.

    reccnt = sy-tabix.
    flg_match = 'N'.
    flg_dupl = 'N'.
    tot_err_flg = 0.
    err_flag_rec = '0'.
    err_narr = 'N'.
    counter = counter + 1.
    IF intab-slno(1) <> 'P' AND slno(1) <> 'P'.
      diff = intab-slno - slno.
      CONDENSE diff.
    ENDIF.
* --- Check if Control no. contains value other than numbers  --- *
    IF NOT ( intab-slno CO '0123456789P ').
*   concatenate intab-slno sy-vline  into errtxt separated by separator.
      err_vald-slno = intab-slno.
      errtxt = text-003 .
      PERFORM append_format_err TABLES err_vald USING 'E' '1' .

    ENDIF.
* --- Check if Control no is 1 more than the last control no --- *
    IF diff <> '1' AND counter > 1 AND intab-slno(1) <> 'P'.
*   concatenate intab-slno sy-vline into errtxt  separated by separator.
      err_vald-slno = intab-slno.
      errtxt = text-003 .
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
      text = text-032.
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
        text = text-004.
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
      text = text-028.
      err_vald-slno = intab-slno.
      CONCATENATE  text(18) intab-tran_dt text+18(11)
                                         INTO errtxt SEPARATED BY space.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.
* --- Check for Debit/Credit indicator --- *
    IF NOT ( intab-dr_cr = 'C' OR  intab-dr_cr = 'D' ).
      text  = text-006.
      err_vald-slno = intab-slno.
      CONCATENATE  text(23) intab-dr_cr text+23(20)
                                         INTO errtxt SEPARATED BY space.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.

    ENDIF.

* ---- Narration should not be blank -----*
    IF intab-narration IS INITIAL.
      err_vald-slno = intab-slno.
      errtxt = text-038.
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
        errtxt = text-027.
        PERFORM append_format_err TABLES err_vald USING 'E' '1'.
      ENDIF.
    ENDIF.
* ---- Amt can not be blank and should only contain numeric char -----*
    IF intab-tran_amt IS INITIAL.
      err_vald-slno = intab-slno.
      errtxt = text-039.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ELSEIF NOT ( intab-tran_amt CO '1234567890 ' ).
      err_vald-slno = intab-slno.
      errtxt = text-026.
      PERFORM append_format_err TABLES err_vald USING 'E' '1'.
    ENDIF.
    IF intab-slno(1) <> 'P'.
* ---- Cum bal can not be blank and should contain numeric char -----*
      IF intab-cum_bal IS INITIAL.
        err_vald-slno = intab-slno.
        errtxt = text-040.
        PERFORM append_format_err TABLES err_vald USING 'E' '1'.
      ELSEIF NOT ( intab-cum_bal CO '1234567890 ' ).
        err_vald-slno = intab-slno.
        errtxt = text-026.
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
      errtxt = text-021.
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
      errtxt = text-035.
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
        text = text-036.
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
    dif_bal =  diff_bal.
    temp_bal = bal.
    CONDENSE temp_bal.
    CONDENSE dif_bal.
    text = text-017.
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
*                      '                 M A T C H I N G      E R R O RS
*                                   '.
    WRITE : icon_message_error AS ICON,
                         '                 M A T C H I N G      E R R OR S'
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
      match_amt1 = match_amt / 100.
      IF match_tab-new_seq <> newseq.
        WRITE : /1 sy-vline,
                 2 match_tab-slno, 9 sy-vline ,
                 10 match_tab-identif,29 sy-vline,
                 30 match_tab-dr_cr, 32 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                  33 match_amt1.
                 33 match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
      ELSE.
        WRITE : /1 sy-vline,
                  2 space, 9 sy-vline ,
                 10 space,29 sy-vline,
                 30 space, 32 sy-vline,
                 33 space.
      ENDIF.
      WRITE :  50 sy-vline,
               51 match_tab-chq_rt,62 sy-vline,
               63 match_tab-dr_cr1,66 sy-vline,
               67 match_tab-amt1,84  sy-vline,
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
    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37 dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*              55 opentab-dmbtr,71 sy-vline,
             55(16) opentab-dmbtr,71 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
             72 opentab-sgtxt.  "#EC CI_FLDEXT_OK[2610650]
  ENDLOOP.
  ULINE.

  IF line = 0.
    WRITE : / 'No Bank Clearing Account Open items for Debit  '.
  ELSE.
    ULINE.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*     WRITE :/35 'Total Rs.' , tot_amt_bnkbook.
    WRITE :/35 'Total Rs.' , tot_amt_bnkbook. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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

    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37 dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*              55 opentab-dmbtr,71 sy-vline,
             55(16) opentab-dmbtr,71 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
             72 opentab-sgtxt.  "#EC CI_FLDEXT_OK[2610650]
    tot_amt_bnkbook = tot_amt_bnkbook - opentab-dmbtr.
  ENDLOOP.
  ULINE.


  IF line = 0.
    WRITE : / 'No Bank Clearing Account Open items for Credit  '.
  ELSE.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*     WRITE :/50 'Total Rs.',tot_amt_bnkbook .
    WRITE :/50 'Total Rs.',tot_amt_bnkbook . "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,57 sy-vline,
               37(21) match_amt1,57 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               59 intab-narration,92 sy-vline.

    ENDIF.
  ENDLOOP.
  ULINE.
  match_amt = tot_tran_amt.
  match_amt1 = match_amt / 100.
  WRITE :/15 'Total amt (in Rs.):',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*           37 match_amt1.
          37 match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,57 sy-vline,
               37(21) match_amt1,57 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               59 intab-narration,92 sy-vline.
    ENDIF.
  ENDLOOP.
  ULINE.
  match_amt = tot_tran_amt .
  match_amt1 = match_amt / 100.
  WRITE :/15 'Total Amt (in Rs.)',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*           37 match_amt1.
          37 match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*   WRITE:/'Opening Balance of Bank book transfer Rs.' , amount_5.
  WRITE:/'Opening Balance of Bank book transfer Rs.' , amount_5. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  ULINE.
  FORMAT COLOR OFF.
  ULINE.
  WRITE :/1 'Allocation', 24 'Doc.no',
  36 'Post Date',48 'Amount in Rs.',70 'Description           '.
  ULINE.
  FORMAT COLOR 2 INTENSIFIED ON.
  line = 0.
  tot_tran_bnk = 0.

  SELECT * FROM bsis WHERE
            bukrs =  bukrs  AND
           hkont = bk_actno AND
           gjahr = gjahr  AND
           blart = 'CC'  AND
           budat BETWEEN dt_fm AND dt_to ORDER BY PRIMARY KEY.
    WRITE / bsis-zuonr.WRITE sy-vline. WRITE bsis-belnr.WRITE sy-vline.WRITE bsis-budat.
    " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGEBY SAP_ABAP 05.06.2026  FOR ATC
*             sy-vline,bsis-wrbtr,sy-vline,bsis-sgtxt,sy-vline.
    WRITE sy-vline.WRITE (16) bsis-wrbtr.WRITE sy-vline.WRITE bsis-sgtxt.WRITE sy-vline. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*   WRITE:/43 amount_7.
  WRITE:/43 amount_7. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  ULINE.
  FORMAT COLOR OFF.
  amount_3 = amount_7 +  amount_5.
  FORMAT COLOR 3.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*   WRITE:/43 amount_3.
  WRITE:/43 amount_3. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,60 sy-vline,
               37(21) match_amt1,60 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               62 intab-chkno,78 sy-vline,
               80 intab-descr.

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
    WRITE ' No Bank Statement Transfers during the period'.
  ELSE.
    ULINE.
    match_amt = tot_trans.
    match_amt1 = match_amt / 100.
    WRITE :/15 ' Total amt in Rs.:',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*             37   match_amt1.
            37   match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

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
" " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
      SELECT  * FROM bseg "#EC CI_DB_OPERATION_OK[2431747]
        INTO CORRESPONDING FIELDS OF TABLE ist_bseg
              WHERE bukrs = bukrs AND gjahr = gjahr
              AND hkont = cl_actno  AND augbl <> ''
              AND augdt > dt_to AND belnr = wa_bkpf-belnr ORDER BY PRIMARY KEY.
" " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BYSAP_ABAP 05.06.2026 FOR ATC
      IF NOT ist_bseg[] IS INITIAL.
        LOOP AT ist_bseg INTO wa_bseg.
          MOVE-CORRESPONDING wa_bkpf TO cleartab.
          MOVE-CORRESPONDING wa_bseg TO cleartab.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*          SELECT  SINGLE * FROM payr WHERE zbukr = bukrs AND gjahr = gjahr
*                       AND  ubhkt = cl_actno   AND hbkid = hbkid AND vblnr = wa_bkpf-belnr.
 SELECT * FROM PAYR   UP TO 1 ROWS WHERE ZBUKR = BUKRS AND GJAHR =
GJAHR AND UBHKT = CL_ACTNO AND HBKID = HBKID AND VBLNR = WA_BKPF-BELNR
ORDER BY  ZBUKR HBKID HKTID RZAWE CHECT .   ENDSELECT.
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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

    WRITE : /1 cleartab-zuonr ,11 sy-vline,
             13 cleartab-belnr,24 sy-vline,
             26 cleartab-chect ,34 sy-vline,
             36 cleartab-voidr, 40 sy-vline,
             42 cleartab-bancd, 55 sy-vline,
             57 cleartab-blart,65 sy-vline,
             67 cleartab-budat,77 sy-vline,
             78 dr_cr,81 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*              82 cleartab-dmbtr, 105 sy-vline,
             82(16) cleartab-dmbtr, 105 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
             106 cleartab-sgtxt.  "#EC CI_FLDEXT_OK[2610650]
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*     WRITE : /64  'Total amt in Rs. ', tot_tran_bnk.
    WRITE : /64  'Total amt in Rs. ', tot_tran_bnk. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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

" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*    SELECT SINGLE chect bancd voidr
*                 INTO (payr-chect, payr-bancd, payr-voidr)
*                  FROM payr
*           WHERE zbukr = bukrs AND
*                 hbkid = hbkid AND
*                 hktid = hktid AND
*                 vblnr = bsis-belnr AND
*                 gjahr = bsis-gjahr AND
*                 ubhkt = cl_actno AND
*                 voidr = '0' .
 SELECT CHECT BANCD VOIDR FROM PAYR   UP TO 1 ROWS INTO (PAYR-CHECT ,
PAYR-BANCD , PAYR-VOIDR) WHERE ZBUKR = BUKRS AND HBKID = HBKID AND
HKTID = HKTID AND VBLNR = BSIS-BELNR AND GJAHR = BSIS-GJAHR AND UBHKT =
CL_ACTNO AND VOIDR = '0'   ORDER BY  ZBUKR HBKID HKTID RZAWE CHECT .
ENDSELECT.
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
  match_tab-amt1 = wrbtr.
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
  CONCATENATE bukrs gjahr aznum azdat hbkid
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
  CONCATENATE bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to INTO
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*       data_tab                = opentab
      data_tab                = opentab "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*       data_tab                = errtab_bnkbook
      data_tab                = errtab_bnkbook "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
      CONCATENATE bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to INTO
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*       data_tab                = opentab
      data_tab                = opentab "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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
      CONCATENATE bukrs gjahr aznum azdat hbkid hktid dt_fm dt_to INTO
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
*WRITE : / 'Report5', icon_page_right AS ICON,  'I N T E R E S T  C H AR
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
      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,60 sy-vline,
               37(21) match_amt1,60 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               62 intab-chkno,78 sy-vline,
               80 intab-descr.

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
    WRITE ' No Bank Statement Transfers during the period'.
  ELSE.
    ULINE.
    match_amt = tot_trans.
    match_amt1 = match_amt / 100.
    WRITE :/15 ' Total amt in Rs.:',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*             37   match_amt1.
            37   match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

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
      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,60 sy-vline,
               37(21) match_amt1,60 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               62 intab-chkno,78 sy-vline,
               80 intab-descr.

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
    WRITE :/15 ' Total amt in Rs.:',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*             37   match_amt1.
            37   match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

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
      WRITE :/3 intab-slno,7 sy-vline,
               9 intab-valdt,21 sy-vline,
               23 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,60 sy-vline,
               37(21) match_amt1,60 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               62 intab-chkno,78 sy-vline,
               80 intab-descr.

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
    WRITE :/15 ' Total amt in Rs.:',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*             37   match_amt1.
            37   match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

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
      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,57 sy-vline,
               37(21) match_amt1,57 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               59 intab-narration,92 sy-vline.

    ENDIF.
  ENDLOOP.
  ULINE.
  IF line > 0.
    match_amt = tot_tran_amt.
    match_amt1 = match_amt / 100.
    WRITE :/15 'Total amt (in Rs.):',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*             37 match_amt1.
            37 match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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

      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,57 sy-vline,
               37(21) match_amt1,57 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               59 intab-narration,92 sy-vline.

    ENDIF.
  ENDLOOP.
  ULINE.
  IF line > 0.
    match_amt = tot_tran_amt.
    match_amt1 = match_amt / 100.
    WRITE :/15 'Total amt (in Rs.):',
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*             37 match_amt1.
            37 match_amt1. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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

    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37 dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*              55 opentab-dmbtr,71 sy-vline,
             55(16) opentab-dmbtr,71 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
             72 opentab-sgtxt.  "#EC CI_FLDEXT_OK[2610650]
  ENDLOOP.
  ULINE.

  IF line = 0.
    WRITE : / 'No Matched Debit Bank Book item during the period'.
  ELSE.
    ULINE.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*     WRITE :/35 'Total Rs.' , tot_amt_bnkbook.
    WRITE :/35 'Total Rs.' , tot_amt_bnkbook. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
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

    WRITE : /1 opentab-zuonr, 10 sy-vline,
             12  opentab-belnr ,23 sy-vline,
             25  opentab-chect,35 sy-vline,
             37  dr_cr, 40 sy-vline,
             42 opentab-budat,53 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*              55 opentab-dmbtr,71 sy-vline,
             55(16) opentab-dmbtr,71 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
             72 opentab-sgtxt.  "#EC CI_FLDEXT_OK[2610650]
    line = line + 1.
    tot_amt_bnkbook = tot_amt_bnkbook - opentab-dmbtr.
  ENDLOOP.
  ULINE.


  IF line = 0.
    WRITE : / 'No matched Credit Bankbook item during the period '.
  ELSE.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*     WRITE :/50 'Total Rs.',tot_amt_bnkbook .
    WRITE :/50 'Total Rs.',tot_amt_bnkbook . "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  ENDIF.
  ULINE.

ENDFORM.                               " MATCHED_BNK_BOOK
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_PROGRAM
*&---------------------------------------------------------------------*
FORM upload_bdc_program.
* -The unmatched records are downloaded to File system as Prev month err
  PERFORM dumping_bnkstmt_err.
  line = 0.
  LOOP AT intab FROM 2 WHERE errrec = '0'.
    line = line + 1.
  ENDLOOP.
  IF line > 0.
* --- Calculate Closing Bal.------*
    PERFORM calculate_opbal.

    PERFORM  generate_header_data.
* ----- Generate BDCTAB only for matched records ----*
    LOOP AT intab FROM 2 WHERE errrec = '0' AND tcode <> 'TRAN'.
      PERFORM generate_bdc_data.
    ENDLOOP.
* --- BDC Call transaction and the BDC Lod to be downloed to file system
    PERFORM bdc_insert.
  ELSE.
    WRITE:/ 'There is no matching record to be uploaded...'.
*begin of <RD1K960036>
*WRITE:/'The Unmatched Records have been downloaded to
*c:\brs\prevmonth.txt'.
    WRITE:/'The Unmatched Records have been downloaded to'
    &'c:\brs\prevmonth.txt'.
*end of <RD1K960036>
  ENDIF.
ENDFORM.                               " UPLOAD_PROGRAM

*&---------------------------------------------------------------------*
*&      Form  GENERATE_HEADER_DATA
*&---------------------------------------------------------------------*
FORM generate_header_data.
  REFRESH bdcdata.
  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.        " '0102'. "'0101'. "Changes on 09.09.2016 TR  OCDK900893,OCDK900873
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

  PERFORM bdc_field       USING 'FEBMKA-WVAR_ART' '2'.
  PERFORM bdc_field       USING 'FEBMKA-BUCH_VAL' 'X'.

  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE' '/00'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-MNAM1'.
  PERFORM bdc_field       USING  'FEBMKA-BUKRS' bukrs.
  PERFORM bdc_field       USING 'FEBMKA-HBKID' hbkid.
  PERFORM bdc_field       USING 'FEBMKA-HKTID' hktid.
  PERFORM bdc_field       USING 'FEBMKA-AZNUM' aznum.
* ---- Convert Statement Date into SAP Date Format
  WRITE azdat TO sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-AZDAT' sy-tvar0.
  tempbal = 0.
  PERFORM bdc_field       USING 'FEBMKA-SSALD' tempbal.
  tempbal = tempbal1.
  PERFORM bdc_field       USING 'FEBMKA-ESALD' tempbal.
  WRITE postdt TO sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-BUDTM' sy-tvar0.
  PERFORM bdc_field       USING 'FEBMKA-NM1VB' 'X'.
  PERFORM bdc_field       USING 'FEBMKA-MNAM1' session.

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

  PERFORM bdc_field       USING  'FEBMKA-VGMAN(01)' intab-tcode.

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
  tran_amt1 = tran_amt.
  PERFORM bdc_field       USING 'FEBMKA-KWBTR(01)' tran_amt1." Amt

  IF intab-tcode(3) = 'RCT' OR intab-tcode(3) = 'OTD'.
    PERFORM bdc_field       USING 'FEBMKK-CHECT_KF(01)' intab-docno.
  ELSEIF intab-tcode(3) = 'CHK'.
    PERFORM bdc_field       USING 'FEBMKK-CHECT_KF(01)' intab-chkno.
  ENDIF.
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
  DATA lv_mode TYPE ctu_mode VALUE 'N'.
  PERFORM bdc_dynpro      USING 'SAPMF40K' t021d-dynnr.
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*  PERFORM bdc_field       USING 'BDC_OKCODE' 'SICH'.
  PERFORM bdc_field       USING 'BDC_OKCODE' 'SICH'. "#EC CI_USAGE_OK[2689873]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKK-CHECT_KF(01)'.
  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE' 'BUCH'.
  PERFORM bdc_field       USING 'BDC_CURSOR' 'FEBMKA-BUKRS'.
  PERFORM bdc_dynpro      USING 'SAPMF40K' '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE' '/N'.
  CALL TRANSACTION 'FF67' USING bdcdata MODE lv_mode UPDATE 'S'
                                        MESSAGES INTO bdcmsg.
  IF sy-subrc = 0.
    WRITE :/ 'The matched items has been uploaded to BDC Session ',session.
  ENDIF.
  PERFORM format_message .
  PERFORM display_call_transaction_log.
ENDFORM.                               " BDC_INSERT
*&---------------------------------------------------------------------*
*&      Form  CALCULATE_OPBAL
*&---------------------------------------------------------------------*
FORM calculate_opbal.
  tempbal1 = 0.
  LOOP AT intab FROM 2 WHERE errrec = '0' AND tcode <> 'TRAN'.
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
  DATA:  l_filename TYPE string,
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
  CONCATENATE bukrs aznum1  hbkid hktid INTO param_txt1.
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
      WRITE :/3 intab-slno,11 sy-vline,
               13 intab-valdt,28 sy-vline,
               30 intab-dr_cr,35 sy-vline,
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                37 match_amt1,57 sy-vline,
               37(21) match_amt1,57 sy-vline, "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
               59 intab-narration,92 sy-vline.
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
  WRITE : / 'Report16:',icon_page_right AS ICON ,      'U N M A T C H ED'
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
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
SORT IST_FOREX .
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  LOOP AT ist_forex INTO bsis.
    WRITE /1 sy-vline.WRITE bsis-zuonr.WRITE 14 sy-vline. WRITE bsis-belnr. WRITE 25 sy-vline.
    " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGEBY SAP_ABAP 05.06.2026  FOR ATC
*       bsis-budat,37 sy-vline, bsis-waers, 43 sy-vline, bsis-wrbtr,
" Code Remediation changes S4 2025_1_P Conversion **BEGIN OF CHANGE BY SAP_ABAP 11.06.2026  for ATC
*     WRITE bsis-budat.WRITE 37 sy-vline. WRITE bsis-waers. WRITE 43 sy-vline. WRITE bsis-wrbtr. WRITE "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_P Conversion * *END OF CHANGE BY SAP_ABAP 11.06.2026 for ATC
    " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
    " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGEBY SAP_ABAP 05.06.2026  FOR ATC
*       60 sy-vline, bsis-dmbtr,77 sy-vline, bsis-sgtxt,
    WRITE 60 sy-vline. WRITE (16) bsis-dmbtr.WRITE 77 sy-vline. WRITE bsis-sgtxt. WRITE "#EC CI_FLDEXT_OK[2610650]
    " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
    129 sy-vline.  "#EC CI_FLDEXT_OK[2610650]
  ENDLOOP.
  ULINE /(129).
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*   WRITE :/42 'Total Amount in Rs ',l_tot_rs_amt.
  WRITE :/42 'Total Amount in Rs ',l_tot_rs_amt. "#EC CI_FLDEXT_OK[2610650]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

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
