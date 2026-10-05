*----------------------------------------------------------------------*
***INCLUDE ZHANA_SERVICES_PRG_STATUS_9O02.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9002  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9002 OUTPUT.
*BOC By SAP_ABAP on 05/10/26
*  SET PF-STATUS '9002'.
* Download / Upload are offered in Create mode only
  DATA gt_excl_9002 TYPE STANDARD TABLE OF sy-ucomm.
  CLEAR gt_excl_9002.
  IF create <> 'X'.
    APPEND 'DOWNLOAD' TO gt_excl_9002.
    APPEND 'UPLOAD'   TO gt_excl_9002.
  ENDIF.
  SET PF-STATUS '9002' EXCLUDING gt_excl_9002.
*EOC By SAP_ABAP on 05/10/26
  SET TITLEBAR '9001'.

  IF change = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @DATA(it_temp) WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO DATA(ls_temp).

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.

    ENDLOOP.
    CLEAR: it_temp , ls_temp.
    gv_loaded = 'X'.
  ENDIF.

  IF display = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @it_temp WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO ls_temp.

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.
    ENDLOOP.
    gv_loaded = 'X'.

    CLEAR :it_temp , ls_temp.

  ENDIF.

  IF creator_release = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @it_temp WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO ls_temp.

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.
    ENDLOOP.
    gv_loaded = 'X'.

    CLEAR :it_temp , ls_temp.

  ENDIF.


  IF sap_pm = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @it_temp WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO ls_temp.

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.
    ENDLOOP.
    gv_loaded = 'X'.

    CLEAR :it_temp , ls_temp.

  ENDIF.

  IF core_team = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @it_temp WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO ls_temp.

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.
    ENDLOOP.
    gv_loaded = 'X'.

    CLEAR :it_temp , ls_temp.

  ENDIF.


  IF ovl_pm = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @it_temp WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO ls_temp.

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.
    ENDLOOP.
    gv_loaded = 'X'.

    CLEAR :it_temp , ls_temp.

  ENDIF.

  IF head_it = 'X' AND gv_loaded IS INITIAL..

    SELECT * FROM zsap_timesheet INTO TABLE @it_temp WHERE doc_no = @doc_no.
    LOOP AT it_temp INTO ls_temp.

      CLEAR ls_data.

      ls_data-consultant_name = ls_temp-consultant_name.
      ls_data-service_element = ls_temp-service_element.
      ls_data-zmodulec        = ls_temp-zmodulec.
      ls_data-datec           = ls_temp-datec.
      ls_data-daysc           = ls_temp-daysc.
      ls_data-activity        = ls_temp-activity.
      ls_data-scope           = ls_temp-scope.
      ls_data-stages          = ls_temp-stages.
      ls_data-location        = ls_temp-location.
      ls_data-remarks         = ls_temp-remarks.

      APPEND ls_data TO lt_data.
    ENDLOOP.
    gv_loaded = 'X'.

    CLEAR :it_temp , ls_temp.

  ENDIF.


*  DELETE  lt_data WHERE consultant_name EQ ' '.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9002  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9002 INPUT.

  """"""""""""""""""""""""""""""""""""""""""""""""""""""VALIDATION
  DATA lv_total TYPE zsap_timesheet-daysc.
  IF create = 'X' AND doc_no IS INITIAL AND sy-ucomm NE 'BACK' AND sy-ucomm NE 'EXIT' AND sy-ucomm NE 'CANC' .
    LOOP AT lt_data INTO ls_data.

*      IF  ls_data-consultant_name IS INITIAL OR ls_data-service_element IS INITIAL OR ls_data-zmodulec IS INITIAL OR ls_data-datec IS INITIAL
*        OR ls_data-daysc IS INITIAL OR ls_data-location IS INITIAL
*     .
*        MESSAGE 'All fields are required'
*            TYPE 'S' DISPLAY LIKE 'E'.
*        LEAVE TO SCREEN sy-dynnr.
*      ENDIF.

      IF ls_data-datec > sy-datum.
        MESSAGE 'Future date is not allowed'
        TYPE 'S' DISPLAY LIKE 'E'.
        LEAVE TO SCREEN sy-dynnr.
      ENDIF.

      SELECT SUM( daysc )
        INTO @lv_total
        FROM zsap_timesheet
        WHERE consultant_name = @ls_data-consultant_name and
         ZCONSULTANT_ID = @ls_data-ZCONSULTANT_ID and                "added by mohd mobassir 30.06.2026
         ZMODULEC = @ls_data-ZMODULEC                                "added by mohd mobassir 30.06.2026
        AND   datec           = @ls_data-datec AND reject_reason = ' '.

      IF lv_total IS INITIAL.
        lv_total = 0.
      ENDIF.

      IF lv_total + ls_data-daysc > 1.
        MESSAGE 'Data already exist'
        TYPE 'S' DISPLAY LIKE 'E'.
        LEAVE TO SCREEN sy-dynnr.
      ENDIF.

      CLEAR: ls_data, lv_total.
    ENDLOOP.

  ENDIF.

  """"""""""""""""""""""""""""""""""""""""""""""""


  CASE sy-ucomm.
    WHEN 'EXIT' OR 'CANC'.
      CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
      LEAVE PROGRAM.


    WHEN 'BACK'.
      CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
      CALL SCREEN '9001'.
    WHEN  'SAVE' .
      IF lt_data IS NOT INITIAL.
        DELETE  lt_data WHERE consultant_name EQ ' '.


        IF create = 'X' OR change = 'X' .
          LOOP AT lt_data INTO ls_data.
            IF  ls_data-consultant_name IS INITIAL OR ls_data-service_element IS INITIAL OR ls_data-zmodulec IS INITIAL OR ls_data-datec IS INITIAL
            OR ls_data-daysc IS INITIAL OR ls_data-location IS INITIAL OR ls_data-activity IS INITIAL OR ls_data-scope IS INITIAL
         .
              MESSAGE 'All fields are required'
                  TYPE 'S' DISPLAY LIKE 'E'.
              LEAVE TO SCREEN sy-dynnr.
            ENDIF.

          ENDLOOP.
        ENDIF.

        IF create = 'X' AND doc_no IS INITIAL.
          DATA: lv_doc_no TYPE zsap_timesheet-doc_no,
                wa_final  TYPE zsap_timesheet.

          " 1. Generate DOC_NO
          CALL FUNCTION 'NUMBER_GET_NEXT'
            EXPORTING
              nr_range_nr = '01'
              object      = 'ZTIMESHEET'
            IMPORTING
              number      = lv_doc_no
            EXCEPTIONS
              OTHERS      = 1.

          IF sy-subrc <> 0.
            MESSAGE 'DOC NO generation failed' TYPE 'E'.
          ENDIF.

          doc_no = lv_doc_no.
        ENDIF.

        IF  change = 'X' .
          DATA: lt_screen_dates TYPE HASHED TABLE OF zsap_timesheet
                WITH UNIQUE KEY consultant_name datec.

          LOOP AT lt_data INTO ls_data.

            " Future date check
            IF ls_data-datec > sy-datum.
              MESSAGE 'Future date is not allowed' TYPE 'S'.
              RETURN.
            ENDIF.

**            " DB duplicate check (ignore current doc_no)
**            DATA(lv_exists) = 0.
**            SELECT COUNT(*)
**              INTO @lv_exists
**              FROM zsap_timesheet
**              WHERE consultant_name = @ls_data-consultant_name
**                AND datec = @ls_data-datec
**                AND reject_reason = ' '
**                AND doc_no <> @doc_no.
**
**            IF lv_exists > 0.
**              MESSAGE |Data already exist for { ls_data-consultant_name } on { ls_data-datec }|
**                TYPE 'S'.
**              RETURN.
**            ENDIF.
**
**            " Screen duplicate check
**            READ TABLE lt_screen_dates
**              WITH KEY consultant_name = ls_data-consultant_name
**                       datec = ls_data-datec TRANSPORTING NO FIELDS.
**            IF sy-subrc = 0.
**              MESSAGE |Data already exist  for { ls_data-consultant_name } on { ls_data-datec }|
**                TYPE 'S'.
**              RETURN.
**            ELSE.
**              wa_final-doc_no = doc_no.
**              wa_final-consultant_name = ls_data-consultant_name.
**              wa_final-service_element = ls_data-service_element.
**              IF ls_data-service_element NE 'EXECUTION SERVICES'.
**                ls_data-scope = 'AS IS'.
**              ENDIF.
**              wa_final-zconsultant_id = sy-uname.
**              wa_final-zmodulec = ls_data-zmodulec.
**              wa_final-datec = ls_data-datec.
**              wa_final-daysc = ls_data-daysc.
**              wa_final-activity = ls_data-activity.
**              wa_final-scope = ls_data-scope.
**              wa_final-stages = ls_data-stages.
**              wa_final-location = ls_data-location.
**              wa_final-remarks = ls_data-remarks.
**              wa_final-created_on = sy-datum.
**              INSERT wa_final INTO TABLE lt_screen_dates.
**            ENDIF.
            CLEAR : wa_final , ls_data.
          ENDLOOP.

        ENDIF.



        DELETE  lt_data WHERE consultant_name EQ ' '.
        IF sap_pm NE 'X' AND core_team NE 'X' AND ovl_pm NE 'X' AND head_it NE 'X' AND creator_release NE 'X' .
          LOOP AT lt_data INTO ls_data.

            wa_final-doc_no = doc_no.
            wa_final-consultant_name = ls_data-consultant_name.
            wa_final-service_element = ls_data-service_element.
            IF ls_data-service_element NE 'EXECUTION SERVICES'.
              ls_data-scope = 'AS IS'.
            ENDIF.
            wa_final-zconsultant_id = sy-uname.
            wa_final-zmodulec = ls_data-zmodulec.
            wa_final-datec = ls_data-datec.
            wa_final-daysc = ls_data-daysc.
            wa_final-activity = ls_data-activity.
            wa_final-scope = ls_data-scope.
            wa_final-stages = ls_data-stages.
            wa_final-location = ls_data-location.
            wa_final-remarks = ls_data-remarks.
            wa_final-created_on = sy-datum.

            MODIFY zsap_timesheet FROM wa_final.

*            IF ls_data-sel = 'X'.
*              DELETE FROM zsap_timesheet
*                 WHERE datec = ls_data-datec
*               AND doc_no =  wa_final-doc_no.
*            ENDIF.

            CLEAR: wa_final, ls_data.



          ENDLOOP.

          LOOP AT lt_delete INTO ls_data .
            wa_final-doc_no = doc_no.
            IF ls_data-sel = 'X'.
              DELETE FROM zsap_timesheet
                 WHERE datec = ls_data-datec
               AND doc_no =  wa_final-doc_no.
            ENDIF.
            CLEAR: wa_final, ls_data.
          ENDLOOP.

          " # Final Message Logic
          IF create = 'X'.
            MESSAGE |Doc No { doc_no } generated and data updated successfully| TYPE 'S'.
            CLEAR : change , create ,display , lt_delete,lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
            LEAVE TO SCREEN 9001.
          ELSEIF change = 'X'.
            MESSAGE 'Data updated successfully' TYPE 'S'.
            CLEAR : change , create ,display , lt_data, lt_delete,  ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
            LEAVE TO SCREEN 9001.
          ENDIF.
        ENDIF.
      ENDIF.


    WHEN 'RELEASE'.

      LOOP AT lt_data INTO ls_data.


        UPDATE zsap_timesheet
             SET creator_release_r    = 'X'
                 creator_release_date = sy-datum
                 creator_release_time = sy-uzeit
           WHERE doc_no = doc_no.

      ENDLOOP.

      MESSAGE 'Data Released Successfully' TYPE 'I'.

****************************************************************
*        Email ID for Reciever
****************************************************************
      SELECT SINGLE * FROM  zapprovers INTO @DATA(ls_temp4) WHERE role = 'SAP_PM'.
      IF sy-subrc = 0.
        lv_sap_id = ls_temp4-sap_id.
*        step 1: get address and person number
        SELECT SINGLE addrnumber persnumber
          INTO (lv_addrnumber, lv_persnumber)
          FROM usr21
          WHERE bname = lv_sap_id.

        IF sy-subrc = 0.

*        step 2: get email address
          SELECT SINGLE smtp_addr
            INTO lv_email_receiver
            FROM adr6
            WHERE addrnumber = lv_addrnumber
              AND persnumber = lv_persnumber
              AND flgdefault = 'X'.   "Fetch default email

        ENDIF.
      ENDIF.
********************************************************************
*        Email ID for sender
********************************************************************
* Step 1: Get address and person number
      SELECT SINGLE addrnumber persnumber
        INTO (lv_addrnum, lv_persnum)
        FROM usr21
        WHERE bname = sy-uname.

      IF sy-subrc = 0.

* step 2: get email address
        SELECT SINGLE smtp_addr
          INTO @lv_email_sender
          FROM adr6
          WHERE addrnumber = @lv_addrnum
            AND persnumber = @lv_persnum
            AND flgdefault = 'X'.   "Fetch default email

      ENDIF.

*      lcl_ast_mail=>me2n_mail( ).
      TRY.
          lcl_ast_mail=>me2n_mail( ).
        CATCH cx_root INTO DATA(lx_error).
          " Handle the exception (log, message, etc.)
          MESSAGE lx_error->get_text( ) TYPE 'E'.
      ENDTRY.

      CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
      LEAVE TO SCREEN 9001.

    WHEN 'REJECT'.

      reject = 'X'.
      reason = reason.
      IF reason IS NOT INITIAL.
        IF sap_pm  = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @DATA(ls_app1) WHERE sap_id = @sy-uname AND role = 'SAP_PM' .
        ENDIF.

        IF core_team = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @ls_app1 WHERE sap_id = @sy-uname AND role = 'CORE_TEAM'.
        ENDIF.

        IF ovl_pm = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @ls_app1 WHERE sap_id = @sy-uname AND role = 'OVL_PM'.
        ENDIF.

        IF head_it = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @ls_app1 WHERE sap_id = @sy-uname AND role = 'HEAD_IT'.
        ENDIF.
        IF sy-subrc EQ 0.
          IF sap_pm  = 'X'  AND ls_app1-role EQ 'SAP_PM'.
            flag = 'X'.
          ELSEIF  core_team = 'X' AND ls_app1-role EQ 'CORE_TEAM'.
            flag = 'X'.
          ELSEIF  ovl_pm = 'X' AND  ls_app1-role EQ 'OVL_PM'.
            flag = 'X'.
          ELSEIF head_it = 'X' AND  ls_app1-role EQ 'HEAD_IT'.
            flag = 'X'.
          ENDIF.
        ENDIF.
        IF flag = 'X'.

          SELECT SINGLE * FROM zsap_timesheet INTO @DATA(t_id) WHERE doc_no = @doc_no. "added by mohd mobassir - 23.07.2026

          LOOP AT lt_data INTO ls_data.

            IF sap_pm = 'X'.

              UPDATE zsap_timesheet
                 SET sap_pm_reject       = 'X',
                     sap_pm_reject_date  = @sy-datum,
                     sap_pm_reject_time  = @sy-uzeit,
                     sap_pm_reject_by    = @sy-uname,
                    reject_reason   = @reason
*                    sap_pm_approve = ' '
               WHERE doc_no = @doc_no.

            ENDIF.


            IF core_team = 'X'.

              UPDATE zsap_timesheet
                 SET core_team_reject      = 'X',
                     core_team_reject_date = @sy-datum,
                     core_team_reject_time = @sy-uzeit,
                     core_team_reject_by   = @sy-uname,
                     reject_reason   = @reason,
                     sap_pm_approve = ' '                   "added by mohd mobassir
               WHERE doc_no = @doc_no.

            ENDIF.


            IF ovl_pm = 'X'.

              UPDATE zsap_timesheet
                 SET ovl_pm_reject      = 'X',
                     ovl_pm_reject_date = @sy-datum,
                     ovl_pm_reject_time = @sy-uzeit,
                     ovl_pm_reject_by   = @sy-uname,
                     reject_reason   = @reason,
                     sap_pm_approve = ' '
               WHERE doc_no = @doc_no.

            ENDIF.


            IF head_it = 'X'.

              UPDATE zsap_timesheet
                 SET head_it_reject      = 'X',
                     head_it_reject_date = @sy-datum,
                     head_it_reject_time = @sy-uzeit,
                     head_it_reject_by   = @sy-uname,
                     reject_reason   = @reason,
                     sap_pm_approve = ' '
               WHERE doc_no = @doc_no.

            ENDIF.

          ENDLOOP.


          MESSAGE 'Rejected Successfully' TYPE 'I'.

****************************************************************
*        Email ID for Reciever
****************************************************************
*        SELECT SINGLE * FROM  zapprovers INTO @DATA(ls_temp4) WHERE role = 'SAP_PM'.
*        IF sy-subrc = 0.
*          lv_sap_id = ls_temp4-sap_id.
*        step 1: get address and person number

*          SELECT SINGLE * FROM zsap_timesheet INTO @DATA(t_id) WHERE doc_no = @doc_no.

          CLEAR: lt_recipients.

          "------------------------------
          " SAP PM
          "------------------------------
          IF t_id-sap_pm_approve = 'X' AND t_id-sap_pm_approve_by IS NOT INITIAL.
            " Fetch mail for SAP_PM_APPROVE_BY
            SELECT SINGLE addrnumber ,persnumber
              INTO (@lv_addrnum1, @lv_persnum1)
              FROM usr21
              WHERE bname = @t_id-sap_pm_approve_by.

            IF sy-subrc = 0.
              SELECT SINGLE smtp_addr
                INTO @lv_email1
                FROM adr6
                WHERE addrnumber = @lv_addrnum1
                  AND persnumber = @lv_persnum1
                  AND flgdefault = 'X'.
              IF sy-subrc = 0.
                ls_recipient-userid = t_id-sap_pm_approve_by.
                ls_recipient-email  = lv_email1.
                APPEND ls_recipient TO lt_recipients.
              ENDIF.
            ENDIF.
          ENDIF.

          "------------------------------
          " CORE TEAM
          "------------------------------
          IF t_id-core_team_approve = 'X' AND t_id-core_team_approve_by IS NOT INITIAL.
            SELECT SINGLE addrnumber, persnumber
              INTO (@lv_addrnum1, @lv_persnum1)
              FROM usr21
              WHERE bname = @t_id-core_team_approve_by.

            IF sy-subrc = 0.
              SELECT SINGLE smtp_addr
                INTO @lv_email1
                FROM adr6
                WHERE addrnumber = @lv_addrnum1
                  AND persnumber = @lv_persnum1
                  AND flgdefault = 'X'.
              IF sy-subrc = 0.
                ls_recipient-userid = t_id-core_team_approve_by.
                ls_recipient-email  = lv_email1.
                APPEND ls_recipient TO lt_recipients.
              ENDIF.
            ENDIF.
          ENDIF.

          "------------------------------
          " OVL PM
          "------------------------------
          IF t_id-ovl_pm_approve = 'X' AND t_id-ovl_pm_approve_by IS NOT INITIAL.
            SELECT SINGLE addrnumber ,persnumber
              INTO (@lv_addrnum1, @lv_persnum1)
              FROM usr21
              WHERE bname = @t_id-ovl_pm_approve_by.

            IF sy-subrc = 0.
              SELECT SINGLE smtp_addr
                INTO @lv_email1
                FROM adr6
                WHERE addrnumber = @lv_addrnum1
                  AND persnumber = @lv_persnum1
                  AND flgdefault = 'X'.
              IF sy-subrc = 0.
                ls_recipient-userid = t_id-ovl_pm_approve_by.
                ls_recipient-email  = lv_email1.
                APPEND ls_recipient TO lt_recipients.
              ENDIF.
            ENDIF.
          ENDIF.

          "------------------------------
          " HEAD IT
          "------------------------------
          IF t_id-head_it_approve = 'X' AND t_id-head_it_approve_by IS NOT INITIAL.
            SELECT SINGLE addrnumber ,persnumber
              INTO (@lv_addrnum1, @lv_persnum1)
              FROM usr21
              WHERE bname = @t_id-head_it_approve_by.

            IF sy-subrc = 0.
              SELECT SINGLE smtp_addr
                INTO @lv_email1
                FROM adr6
                WHERE addrnumber = @lv_addrnum1
                  AND persnumber = @lv_persnum1
                  AND flgdefault = 'X'.
              IF sy-subrc = 0.
                ls_recipient-userid = t_id-head_it_approve_by.
                ls_recipient-email  = lv_email1.
                APPEND ls_recipient TO lt_recipients.
              ENDIF.
            ENDIF.
          ENDIF.

          """""""""""""""""""""""""""""""""""

*****        IF sy-subrc EQ 0.
*****          lv_sap_id = t_id-zconsultant_id.
*****        ENDIF.
*****        SELECT SINGLE addrnumber persnumber
*****          INTO (lv_addrnumber, lv_persnumber)
*****          FROM usr21
*****          WHERE bname = lv_sap_id.
*****
*****        IF sy-subrc = 0.
*****
******        step 2: get email address
*****          SELECT SINGLE smtp_addr
*****            INTO lv_email_receiver
*****            FROM adr6
*****            WHERE addrnumber = lv_addrnumber
*****              AND persnumber = lv_persnumber
*****              AND flgdefault = 'X'.   "Fetch default email
*****
*****        ENDIF.
*        ENDIF.
********************************************************************
*        Email ID for sender
********************************************************************
* Step 1: Get address and person number
          SELECT SINGLE addrnumber persnumber
            INTO (lv_addrnum, lv_persnum)
            FROM usr21
            WHERE bname = sy-uname.

          IF sy-subrc = 0.

* step 2: get email address
            SELECT SINGLE smtp_addr
              INTO @lv_email_sender
              FROM adr6
              WHERE addrnumber = @lv_addrnum
                AND persnumber = @lv_persnum
                AND flgdefault = 'X'.   "Fetch default email

          ENDIF.

*        lcl_ast_mail=>me2n_mail( ).
if lt_recipients IS NOT INITIAL. "added by mohd mobassir-23.07.2026
          TRY.
              lcl_ast_mail=>me2n_mail( ).
            CATCH cx_root INTO DATA(lx_error1).
              " Handle the exception (log, message, etc.)
              MESSAGE lx_error1->get_text( ) TYPE 'E'.
          ENDTRY.
    endif.
        ELSE.
          MESSAGE 'You are not authorized for reject' TYPE 'I'.
        ENDIF.
      ELSE.

        MESSAGE 'Please enter a reason for rejection.' TYPE 'I'.
      ENDIF.
      IF reason IS NOT INITIAL.
        CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
        LEAVE TO SCREEN 9001.
      ENDIF.

    WHEN 'APPROVE'.
      approve = 'X'.
      IF lv_role IS INITIAL AND head_it NE 'X'.
        MESSAGE 'Please select an approver' TYPE 'I'.
      ELSE.
        IF sap_pm  = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @DATA(ls_app) WHERE sap_id = @sy-uname AND role = 'SAP_PM' .
        ENDIF.

        IF core_team = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @ls_app WHERE sap_id = @sy-uname AND role = 'CORE_TEAM'.
        ENDIF.

        IF ovl_pm = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @ls_app WHERE sap_id = @sy-uname AND role = 'OVL_PM'.
        ENDIF.

        IF head_it = 'X'.
          SELECT SINGLE * FROM  zapprovers INTO @ls_app WHERE sap_id = @sy-uname AND role = 'HEAD_IT'.
        ENDIF.

        IF sy-subrc EQ 0.
          IF sap_pm  = 'X'  AND ls_app-role EQ 'SAP_PM'.
            flag = 'X'.
          ELSEIF  core_team = 'X' AND ls_app-role EQ 'CORE_TEAM'.
            flag = 'X'.
          ELSEIF  ovl_pm = 'X' AND  ls_app-role EQ 'OVL_PM'.
            flag = 'X'.

          ELSEIF head_it = 'X' AND  ls_app-role EQ 'HEAD_IT'.
            flag = 'X'.
          ENDIF.
        ENDIF.
        IF flag = 'X'.
          LOOP AT lt_data INTO ls_data.

            IF sap_pm = 'X'.

              UPDATE zsap_timesheet
                 SET sap_pm_approve       = 'X',
                     sap_pm_approve_date  = @sy-datum,
                     sap_pm_approve_time  = @sy-uzeit,
                     sap_pm_approve_by    = @sy-uname
               WHERE doc_no = @doc_no.

            ENDIF.


            IF core_team = 'X'.

              UPDATE zsap_timesheet
                 SET core_team_approve       = 'X',
                     core_team_approve_date  = @sy-datum,
                     core_team_approve_time  = @sy-uzeit,
                     core_team_approve_by    = @sy-uname
               WHERE doc_no = @doc_no.

            ENDIF.


            IF ovl_pm = 'X'.

              UPDATE zsap_timesheet
                 SET ovl_pm_approve       = 'X',
                     ovl_pm_approve_date  = @sy-datum,
                     ovl_pm_approve_time  = @sy-uzeit,
                     ovl_pm_approve_by    = @sy-uname
               WHERE doc_no = @doc_no.

            ENDIF.


            IF head_it = 'X'.

              UPDATE zsap_timesheet
                 SET head_it_approve       = 'X',
                     head_it_approve_date  = @sy-datum,
                     head_it_approve_time  = @sy-uzeit,
                     head_it_approve_by    = @sy-uname
               WHERE doc_no = @doc_no.

            ENDIF.

          ENDLOOP.


          MESSAGE 'Approved Successfully' TYPE 'I'.

****************************************************************
*        Email ID for Reciever
****************************************************************
*        SELECT SINGLE * FROM  zapprovers INTO @DATA(ls_temp4) WHERE role = 'SAP_PM'.
*        IF sy-subrc = 0.
*          lv_sap_id = ls_temp4-sap_id.
*        step 1: get address and person number
          IF lv_role IS NOT INITIAL.
            SELECT SINGLE * FROM  zapprovers INTO @DATA(ls_temp6) WHERE role = @namet AND name = @lv_role.
            lv_sap_id = ls_temp6-sap_id.
          ENDIF.

          SELECT SINGLE addrnumber persnumber
            INTO (lv_addrnumber, lv_persnumber)
            FROM usr21
            WHERE bname = lv_sap_id.

          IF sy-subrc = 0.

*        step 2: get email address
            SELECT SINGLE smtp_addr
              INTO lv_email_receiver
              FROM adr6
              WHERE addrnumber = lv_addrnumber
                AND persnumber = lv_persnumber
                AND flgdefault = 'X'.   "Fetch default email

          ENDIF.
*        ENDIF.
********************************************************************
*        Email ID for sender
********************************************************************
* Step 1: Get address and person number
          SELECT SINGLE addrnumber persnumber
            INTO (lv_addrnum, lv_persnum)
            FROM usr21
            WHERE bname = sy-uname.

          IF sy-subrc = 0.

* step 2: get email address
            SELECT SINGLE smtp_addr
              INTO @lv_email_sender
              FROM adr6
              WHERE addrnumber = @lv_addrnum
                AND persnumber = @lv_persnum
                AND flgdefault = 'X'.   "Fetch default email

          ENDIF.

*        lcl_ast_mail=>me2n_mail( ).
          IF head_it NE 'X'.
            TRY.
                lcl_ast_mail=>me2n_mail( ).
              CATCH cx_root INTO DATA(lx_error2).
                " Handle the exception (log, message, etc.)
                MESSAGE lx_error2->get_text( ) TYPE 'E'.
            ENDTRY.
          ENDIF.
        ELSE.

          MESSAGE 'You are not authorized for approval' TYPE 'I'.

        ENDIF.

      ENDIF.

      IF lv_role IS NOT INITIAL.
        CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
        LEAVE TO SCREEN 9001.
      ENDIF.
    WHEN 'RETURN'.

      UPDATE zsap_timesheet
      SET creator_release_r = ' '
      WHERE doc_no = @doc_no
      AND creator_release_r = 'X'.

      MESSAGE 'Document returned to change successfully' TYPE 'S'.
      CLEAR : change , create ,display , lt_data , ls_data,doc_no ,gv_loaded ,creator_release , sap_pm , core_team ,ovl_pm ,head_it,flag, lv_email , namet ,lv_role,reject,reason,approve.
      LEAVE TO SCREEN 9001.
*BOC By SAP_ABAP on 05/10/26
    WHEN 'DOWNLOAD'.
      IF create = 'X'.
        PERFORM download_rows.
      ENDIF.

    WHEN 'UPLOAD'.
      IF create = 'X'.
        PERFORM upload_rows.
      ENDIF.
*EOC By SAP_ABAP on 05/10/26
  ENDCASE.

  IF create = 'X' OR change = 'X'.

    LOOP AT lt_data INTO ls_data .
      IF ls_data-consultant_name IS NOT INITIAL.
        SELECT SINGLE service_element, zmodulec
            FROM zresource_mappin
            INTO @DATA(ser_ele)
            WHERE consultant_name = @ls_data-consultant_name.

**        SELECT SINGLE service_element
**                      zmodulec
**          FROM zresource_mappin
**          INTO (ls_data-service_element,
**                ls_data-zmodulec)
**          WHERE consultant_name = ls_data-consultant_name.
        ls_data-service_element = ser_ele-service_element.
*        ls_data-zmodulec = ser_ele-zmodulec.
        IF ls_data-service_element NE 'EXECUTION SERVICES'.
          ls_data-scope = 'AS IS'.
        ELSE.
*          ls_data-scope = 'ADDITIONAL'.
        ENDIF.
        MODIFY lt_data FROM ls_data.

      ENDIF.
    ENDLOOP.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  DISP  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE disp OUTPUT.
  IF display = 'X' OR creator_release = 'X' OR sap_pm = 'X' OR core_team = 'X' OR ovl_pm = 'X' OR head_it = 'X' .
    LOOP AT SCREEN.
      IF screen-group1 = 'A1'.
        screen-input = 0.         " Disable editing
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF display = 'X' OR change = 'X' OR create = 'X'  .
    LOOP AT SCREEN.
      IF screen-group1 = 'A2' OR screen-group1 = 'A3'.
        screen-active = 0.        " HIDE
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF  creator_release = 'X'  .
    LOOP AT SCREEN.
      IF screen-group1 = 'A3'.
        screen-active = 0.        " HIDE
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF  sap_pm EQ 'X' OR core_team EQ 'X' OR ovl_pm EQ 'X' OR head_it EQ 'X'.
    LOOP AT SCREEN.
      IF screen-group1 = 'A2'.
        screen-active = 0.        " HIDE
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
  """"""""""""""""""""""""""""""""""""""""""""""""RELEASE
  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND creator_release EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @DATA(ls_form1) WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
      IF ls_form1-creator_release_r EQ 'X'.
        LOOP AT SCREEN.
          IF screen-group1 = 'A2'.
            screen-input = 0.        " HIDE
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND sap_pm EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
*      IF ls_form1-sap_pm_r EQ 'X'.
*      IF ls_form1-sap_pm_r EQ 'X'.
      LOOP AT SCREEN.
        IF screen-group1 = 'A2'.
          screen-input = 0.        " HIDE
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
*      ENDIF.
*      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND core_team EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
*      IF ls_form1-core_team_r EQ 'X'.
      LOOP AT SCREEN.
        IF screen-group1 = 'A2'.
          screen-input = 0.        " HIDE
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
*      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND ovl_pm EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
*      IF ls_form1-ovl_pm_r EQ 'X'.
      LOOP AT SCREEN.
        IF screen-group1 = 'A2'.
          screen-input = 0.        " HIDE
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
*      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND head_it EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
*      IF ls_form1-head_it_r EQ 'X'.
      LOOP AT SCREEN.
        IF screen-group1 = 'A2'.
          screen-input = 0.        " HIDE
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
*      ENDIF.
    ENDIF.
  ENDIF.

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""APPROVAL
  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND creator_release EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
      IF ls_form1-creator_release_r EQ 'X'.
*      IF ls_form1-creator_release_approve EQ 'X'.
        LOOP AT SCREEN.
          IF screen-group1 = 'A3'.
            screen-input = 0.        " HIDE
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
*      ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND sap_pm EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
      IF ls_form1-sap_pm_approve EQ 'X'.
        LOOP AT SCREEN.
          IF screen-group1 = 'A3'.
            screen-input = 0.        " HIDE
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND core_team EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
      IF ls_form1-core_team_approve EQ 'X'.
        LOOP AT SCREEN.
          IF screen-group1 = 'A3'.
            screen-input = 0.        " HIDE
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND ovl_pm EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
      IF ls_form1-ovl_pm_approve EQ 'X'.
        LOOP AT SCREEN.
          IF screen-group1 = 'A3'.
            screen-input = 0.        " HIDE
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF  doc_no IS NOT INITIAL AND create NE 'X' AND display NE 'X' AND head_it EQ 'X' .
    SELECT SINGLE * FROM  zsap_timesheet INTO @ls_form1 WHERE  doc_no =  @doc_no.
    IF  sy-subrc EQ 0.
      IF ls_form1-head_it_approve EQ 'X'.
        LOOP AT SCREEN.
          IF screen-group1 = 'A3'.
            screen-input = 0.        " HIDE
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF  head_it EQ 'X'.
    LOOP AT SCREEN.

      IF screen-group2 = 'A4'.
        screen-active = 0.        " HIDE
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF reject NE 'X'.
    LOOP AT SCREEN.

      IF screen-group1 = 'R1'.
        screen-active = 0.        " HIDE
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

  ENDIF.

*  IF sap_pm NE 'X'.
*
*    LOOP AT SCREEN.
*
*      IF screen-group1 = 'Z4'.
*        screen-active = 0.        " HIDE
*        MODIFY SCREEN.
*      ENDIF.
*    ENDLOOP.
*
*  ENDIF.


  "boc by mohd mobassir - 22.07.2026

  IF sap_pm NE 'X'
   AND core_team NE 'X'
   AND ovl_pm NE 'X'
   AND head_it NE 'X'.

  LOOP AT SCREEN.
    IF screen-group1 = 'Z4'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDIF.
"eoc by mohd mobassir - 22.07.2026

  IF sap_pm = 'X' OR core_team = 'X' OR ovl_pm = 'X' OR head_it = 'X' OR creator_release = 'X' OR display = 'X'.

*BOC By SAP_ABAP on 05/10/26
*    SET PF-STATUS '9002' EXCLUDING 'SAVE'.
    CLEAR gt_excl_9002.
    APPEND 'SAVE'     TO gt_excl_9002.
    APPEND 'DOWNLOAD' TO gt_excl_9002.
    APPEND 'UPLOAD'   TO gt_excl_9002.
    SET PF-STATUS '9002' EXCLUDING gt_excl_9002.
*EOC By SAP_ABAP on 05/10/26

* LOOP AT SCREEN.
*
*    IF screen-ucomm = 'SAVE'.  " function code of the Save button
*      screen-active = 0.
*      screen-invisible = 1.
*      MODIFY SCREEN.
*    ENDIF.
*  ENDLOOP.

  ENDIF.


ENDMODULE.
