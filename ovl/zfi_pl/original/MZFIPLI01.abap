*&---------------------------------------------------------------------*
*&  Include MZFIPLI01
*&---------------------------------------------------------------------*

MODULE user_command_0001 INPUT.
  CLEAR : pnl,                                                          "Variable for user selected program/report on main screen
          mode.                                                         "Variable for user selected mode i.e. Create,Change,etc

  CASE sy-ucomm.
    WHEN 'PROJLIST'.                                                  "Project list Mapping Table Maintainance
      pnl = 'PROJLIST'.
      PERFORM projlist_maintain.
    WHEN 'GLMAPPING'.                                                  "GL Mapping Table Maintainance
      pnl = 'GLMAP'.
      PERFORM gl_maintain.
    WHEN 'QUANTINFO'.                                                  "Qunatitative Information
      pnl = 'QUANTINFO'.
      CLEAR g_custom_container.                                         "Clear screen/custom-container
      CALL SCREEN '0101'.
    WHEN 'PRD_ASST'.                                                   "Producing project/Project Input
      pnl = 'PRD_ASST'.
      CLEAR g_custom_container.
      CALL SCREEN '0201'.
    WHEN 'OTH_PROJ'.                                                  "Other Project Input
      pnl = 'OTH_PROJ'.
      CLEAR g_custom_container.
      CALL SCREEN '0301'.
    WHEN 'PRD_PROJ'.                                                  "Profitability Statement - Producing Projects
      pnl = 'PRD_PROJ'.
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'PER_BAR1'.                                                   "Producing Projects & Per Barrel Analysis Report
      pnl = 'PER_BAR'.
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'NON_PRD'.                                                   "Profitability Statement - Non Producing Projects
      pnl = 'NON_PRD'.
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'VAR_PRD'.                                                   "Variance Analysis for Producing Projects
      pnl = 'VAR_PRD'.
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'VAR_NON'.                                                   "Variance Analysis for Non-Produing Projects
      pnl = 'VAR_NON'.
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'PRO_AN'.
      pnl = 'PRO_ANA'.                                               "Profitability Analysis Report
      CLEAR: g_custom_container.
      CALL SCREEN '0501'.
    WHEN 'PEND_INP'.                                                  "Pending Inputs Reports
      pnl = 'PEND_INP'.
      CLEAR: g_custom_container.
      CALL SCREEN '0601'.
    WHEN 'PRD_QTY'.
      pnl = 'PRD_QTY'.                                               " Production and sales quantity analysis
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'REV'.
      pnl = 'REV'.                                               " Revenu and cost
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'BAR_REP'.
      pnl = 'BAR_REP'.                                               " Per barrel analysis
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'AGE_REP'.
      pnl = 'AGE_REP'.                                               " agenda report
      CLEAR: g_custom_container.
      CALL SCREEN '0401'.
    WHEN 'GUIDE'.
      PERFORM process_guide.                                         "Process Guide
    WHEN 'BACK'.
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANC'.
      LEAVE PROGRAM.
    WHEN ' '.
  ENDCASE.

ENDMODULE."USER_COMMAND_0001


MODULE user_command_0101 INPUT.
  CLEAR mode .

  PERFORM initail_chk.                                                "check mandatory input fields

  PERFORM auth_check.                                                 "Authorization check for Create/Change/Display/Approve/Freeze

  IF p_company IS NOT INITIAL
       AND p_proj IS NOT INITIAL
       AND p_year IS NOT INITIAL
       AND s_period_low IS NOT INITIAL.

    SELECT SINGLE * FROM zpnl_qi_oil
      INTO @DATA(chk_cre_quant)
      WHERE company = @p_company
        AND bukrs   = @p_comp
        AND pro_nam = @p_proj
        AND fisyear = @p_year
        AND zperiod = @s_period_low.
  ENDIF.

  CLEAR stat.
  IF sy-ucomm NE 'CREATE' AND chk_cre_quant IS NOT INITIAL.             ""Get data to display Freezed/Approved status on screen
    CLEAR stat.
    IF chk_cre_quant-freezed_by IS NOT INITIAL.
      stat = 'FREEZED'.
    ELSEIF chk_cre_quant-approved_by IS NOT INITIAL AND chk_cre_quant-approved_by_rp IS  INITIAL.
      stat = 'APPROVED'.
    ELSEIF chk_cre_quant-approved_by_rp IS NOT INITIAL AND  chk_cre_quant-approved_by IS NOT INITIAL.
      stat = 'APPROVEFI'.
    ENDIF.
  ENDIF.

  IF s_period_low NE 'Q2' AND s_period_low NE 'Q3' AND s_period_low NE 'Q4'.
    IF sy-ucomm = 'CREATE' AND chk_cre_quant IS NOT INITIAL.           ""Check the status of entered inputs
      CLEAR : sy-ucomm,chk_cre_quant.
      MESSAGE 'Data already created for given inputs' TYPE 'E'.

    ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE' ) AND ( chk_cre_quant IS NOT INITIAL ).
      IF chk_cre_quant-freezed_by IS NOT INITIAL.
        CLEAR : sy-ucomm,chk_cre_quant.
        MESSAGE 'Data is already freezed. You can only display now' TYPE 'E'.
      ENDIF.

    ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE' )
       AND ( chk_cre_quant IS INITIAL ).
      CLEAR : sy-ucomm,chk_cre_quant.
      MESSAGE 'Data not yet created for given inputs' TYPE 'E'.
    ENDIF.

    IF stat = 'APPROVED' AND sy-ucomm = 'APPROVE' AND sy-ucomm = 'APPROVEFI'.
      CLEAR : sy-ucomm.
      MESSAGE 'Data already approved' TYPE 'E'.
    ELSEIF stat = 'FREEZED' AND sy-ucomm = 'FREEZE'.
      CLEAR : sy-ucomm.
      MESSAGE 'Data already freezed' TYPE 'E'.
    ENDIF.

  ELSEIF s_period_low EQ 'Q2' OR s_period_low EQ 'Q3' OR s_period_low EQ 'Q4'.
    IF sy-ucomm = 'CREATE' OR sy-ucomm = 'CHANGE' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE'.
      CLEAR : sy-ucomm,chk_cre_quant.
      MESSAGE 'Data for Q2, Q3 and Q4 is auto calculated. Data can be displayed directly' TYPE 'E' DISPLAY LIKE 'S'.
    ELSEIF sy-ucomm = 'DISPLAY'.
      IF s_period_low EQ 'Q2'.
        SELECT * FROM zpnl_qi_oil INTO TABLE @DATA(lt_pre_quant) WHERE company = @p_company
             AND bukrs   = @p_comp
             AND pro_nam = @p_proj
             AND fisyear = @p_year
             AND zperiod IN ('Q1','H1').
        DESCRIBE TABLE lt_pre_quant LINES DATA(lv_pre_quant).
        IF lv_pre_quant NE 2.
          MESSAGE 'Q1 or H1, or entries for both not available' TYPE 'E'.
        ENDIF.
        REFRESH lt_pre_quant[].
        CLEAR lv_pre_quant.

      ELSEIF s_period_low EQ 'Q3'.
        REFRESH lt_pre_quant[].
        CLEAR lv_pre_quant.
        SELECT * FROM zpnl_qi_oil INTO TABLE lt_pre_quant WHERE company = p_company
             AND bukrs   = p_comp
             AND pro_nam = p_proj
             AND fisyear = p_year
             AND zperiod IN ('9M','H1').
        DESCRIBE TABLE lt_pre_quant LINES lv_pre_quant.
        IF lv_pre_quant NE 2.
          MESSAGE '9M or H1, or entries for both not available' TYPE 'E'.
        ENDIF.

      ELSEIF s_period_low EQ 'Q4'.
        REFRESH lt_pre_quant[].
        SELECT * FROM zpnl_qi_oil INTO TABLE lt_pre_quant WHERE company = p_company
             AND bukrs   = p_comp
             AND pro_nam = p_proj
             AND fisyear = p_year
             AND zperiod IN ('9M','ANNUAL').
        DESCRIBE TABLE lt_pre_quant LINES lv_pre_quant.
        IF lv_pre_quant NE 2.
          MESSAGE '9M or ANNUAL, or entries for both not available' TYPE 'E'.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


  CLEAR chk_cre_quant.

  CASE sy-ucomm.
    WHEN 'CREATE'.
      mode = 'CRE'.
      bbl_mmbbl    = '0.000001'.
      bbl_mmt      = '0.000001'.
      mmscm_mmboe  = '0.00629'.
      mmscm_bcm    = '0.001'.
      PERFORM create_quant.                         "Prepare screen and its input parameters for Quantitative Analysis
      CALL SCREEN 0111.

    WHEN 'CHANGE'.
      mode = 'CHA'.
      PERFORM create_quant.
      PERFORM fetch_quant.                          "Fetch saved/created data from tables
      PERFORM cal_quant.
      CALL SCREEN 0111.

    WHEN 'DISPLAY'.
      mode = 'DIS'.
      PERFORM create_quant.
      PERFORM fetch_quant.
      PERFORM cal_quant.                            "Calculate the Output/Read only fields
      CALL SCREEN 0111.

    WHEN 'APPROVE'.
      mode = 'APP'.
      PERFORM create_quant.
      PERFORM fetch_quant.
      PERFORM cal_quant.
      CALL SCREEN 0111.
*ADDED BY APARNA 27.06.2024  " ADDITIONAL REQURIMENT BY CORP FOR APPROVLA
    WHEN 'APPROVEFI'.
      mode = 'APF'.
      PERFORM create_quant.
      PERFORM fetch_quant.
      PERFORM cal_quant.
      CALL SCREEN 0111.

* ENDED BY APARNA 27.06.2024
    WHEN 'FREEZE'.
      mode = 'FRE'.
      PERFORM create_quant.
      PERFORM fetch_quant.
      PERFORM cal_quant.
      CALL SCREEN 0111.

    WHEN 'BACK'.
      REFRESH it_quant[].
      CLEAR it_quant.
      PERFORM clear_on_exit.                       "Clear Variables in exit
      LEAVE TO SCREEN 0001.

    WHEN 'EXIT'.
      REFRESH it_quant[].
      CLEAR it_quant.
      PERFORM clear_on_exit.
      LEAVE PROGRAM.

    WHEN 'CANC'.
      REFRESH it_quant[].
      CLEAR it_quant.
      PERFORM clear_on_exit.
      LEAVE TO SCREEN 0001.

    WHEN ' '.

  ENDCASE.

ENDMODULE."USER_COMMAND_0101


MODULE pov_company INPUT.               "get dropdown list for Company field
  REFRESH it_company[].
  REFRESH it_company2[].
  REFRESH it_return[].

  SELECT company FROM zfi_pnl_proj INTO CORRESPONDING FIELDS OF TABLE it_company2.
  IF it_company2 IS NOT INITIAL.
    SELECT name1 rcomp
      FROM t880 INTO TABLE it_company
      FOR ALL ENTRIES IN it_company2 WHERE rcomp = it_company2-company.
  ENDIF.

  SORT it_company BY company.
  DELETE ADJACENT DUPLICATES FROM it_company COMPARING company.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'RCOMP_D'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'P_COMPANY'
      value_org       = 'S'
    TABLES
      value_tab       = it_company
      return_tab      = it_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDMODULE.


MODULE pov_comp INPUT.       "Autofill company code based on Company and Get the dropdown list

  REFRESH it_comp[].
  REFRESH it_return[].
  CLEAR p_comp.

  REFRESH lt_dynpfields[].
  ls_dynpfields-fieldname = 'P_COMPANY'.
  APPEND ls_dynpfields TO lt_dynpfields.
  CLEAR ls_dynpfields.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = sy-repid
      dynumb               = sy-dynnr
    TABLES
      dynpfields           = lt_dynpfields
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.

  READ TABLE lt_dynpfields INTO ls_dynpfields WITH KEY fieldname = 'P_COMPANY'.
  IF ls_dynpfields IS NOT INITIAL.
    p_company = ls_dynpfields-fieldvalue.
  ENDIF.

  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp WHERE company = p_company.
  SORT it_comp BY bukrs.
  DELETE ADJACENT DUPLICATES FROM it_comp COMPARING bukrs.

  READ TABLE it_comp INTO DATA(wa_comp2) INDEX 1.
  IF wa_comp2 IS NOT INITIAL.
    p_comp = wa_comp2-bukrs.
  ENDIF.

ENDMODULE.

MODULE pov_proj INPUT.         "Get dropdown list for Projet field base on Company and Company code

  REFRESH it_proj[].
  CLEAR it_proj.
  REFRESH it_return[].
  CLEAR p_proj.

  REFRESH lt_dynpfields[].
  ls_dynpfields-fieldname = 'P_COMP'.
  APPEND ls_dynpfields TO lt_dynpfields.
  CLEAR ls_dynpfields.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = sy-repid
      dynumb               = sy-dynnr
    TABLES
      dynpfields           = lt_dynpfields
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.

  READ TABLE lt_dynpfields INTO ls_dynpfields WITH KEY fieldname = 'P_COMP'.
  IF ls_dynpfields IS NOT INITIAL.
    p_comp = ls_dynpfields-fieldvalue.
  ENDIF.

  IF p_comp NE 'N/A' AND p_company IS NOT INITIAL.
    IF pnl = 'QUANTINFO'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs  = p_comp
                           AND prod   = 'YES'.

    ELSEIF pnl = 'PRD_ASST'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs  = p_comp
                           AND prod   = 'YES'
                           AND manual = 'YES'.

    ELSEIF pnl = 'OTH_PROJ'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs  = p_comp
                           AND prod   = 'NO'
                           AND manual = 'YES'.

    ELSEIF pnl = 'PRD_PROJ'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs   = p_comp
                            AND prod   = 'YES'
                            AND manual = 'NO'.

    ELSEIF pnl = 'NON_PRD'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs   = p_comp
                            AND prod   = 'NO'
                            AND manual = 'NO'.

    ELSE.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs  = p_comp.

    ENDIF.

  ELSEIF p_comp EQ 'N/A' AND p_company IS NOT INITIAL.

    IF pnl = 'QUANTINFO'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE company = p_company
                           AND prod    = 'YES'.

    ELSEIF pnl = 'PRD_ASST'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE company = p_company
                           AND prod    = 'YES'
                           AND manual  = 'YES'.

    ELSEIF pnl = 'OTH_PROJ'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE company = p_company
                           AND prod    = 'NO'
                           AND manual  = 'YES'.

    ELSEIF pnl = 'PRD_PROJ'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                          WHERE company = p_company
                            AND prod    = 'YES'
                            AND manual  = 'NO'.

    ELSEIF pnl = 'NON_PRD'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                          WHERE company = p_company
                            AND prod    = 'NO'
                            AND manual  = 'NO'.
    ENDIF.

  ENDIF.

  SORT it_proj BY jvnam.
  DELETE ADJACENT DUPLICATES FROM it_proj COMPARING jvnam.

  IF it_proj IS INITIAL AND p_comp IS NOT INITIAL.
    CLEAR sy-ucomm.
    MESSAGE 'No Projects found' TYPE 'I' DISPLAY LIKE 'E'.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VNAME'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'P_PROJ'
      value_org       = 'S'
    TABLES
      value_tab       = it_proj
      return_tab      = it_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

ENDMODULE.

MODULE pov_period INPUT.          "Get Dropdown list for Period field addec by aparna

  REFRESH it_return[].
  REFRESH it_period[].

  CLEAR wa_period.
  wa_period-period = 'Apr - Jun'.
  wa_period-per = 'Q1'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  IF ( pnl = 'PRD_PROJ' ) OR ( pnl = 'NON_PRD' ) OR ( pnl = 'VAR_PRD' ) OR ( pnl = 'VAR_NON' ) OR ( pnl = 'QUANTINFO' )
    OR ( pnl = 'PER_BAR' ) OR ( pnl = 'PRO_ANA' )  OR ( pnl = 'PRD_QTY' ) OR ( pnl = 'REV' ) OR ( pnl = 'BAR_REP' ) OR ( pnl = 'AGE_REP' ).
    wa_period-period = 'Jul - Sept'.
    wa_period-per = 'Q2'.
    APPEND wa_period TO it_period.
    CLEAR wa_period.
  ENDIF.

  wa_period-period = 'Apr - Sept'.
  wa_period-per = 'H1'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  IF ( pnl = 'PRD_PROJ' ) OR ( pnl = 'NON_PRD' ) OR ( pnl = 'VAR_PRD' ) OR ( pnl = 'VAR_NON' ) OR ( pnl = 'QUANTINFO' )
    OR ( pnl = 'PER_BAR' ) OR ( pnl = 'PRO_ANA' )  OR ( pnl = 'PRD_QTY' ) OR ( pnl = 'REV' ) OR ( pnl = 'BAR_REP' ) OR ( pnl = 'AGE_REP' ).
    wa_period-period = 'Oct - Dec'.
    wa_period-per = 'Q3'.
    APPEND wa_period TO it_period.
    CLEAR wa_period.
  ENDIF.

  wa_period-period = 'Apr - Dec'.
  wa_period-per = '9M'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  IF ( pnl = 'PRD_PROJ' ) OR ( pnl = 'NON_PRD' ) OR ( pnl = 'VAR_PRD' ) OR ( pnl = 'VAR_NON' ) OR ( pnl = 'QUANTINFO' )
     OR ( pnl = 'PER_BAR' ) OR ( pnl = 'PRO_ANA' )  OR ( pnl = 'PRD_QTY' ) OR ( pnl = 'REV' ) OR ( pnl = 'BAR_REP' ) OR ( pnl = 'AGE_REP' ).
    wa_period-period = 'Jan - Mar'.
    wa_period-per = 'Q4'.
    APPEND wa_period TO it_period.
    CLEAR wa_period.
  ENDIF.

  wa_period-period = 'Apr - Mar'.
  wa_period-per = 'Annual'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

*   IF ( PNL = 'PRD_PROJ' ) OR ( PNL = 'NON_PRD' ) OR ( PNL = 'VAR_PRD' ) OR ( PNL = 'VAR_NON' ) OR ( PNL = 'QUANTINFO' ) OR ( PNL = 'PER_BAR' ).
*     WA_PERIOD-PERIOD = 'Jul - Sept'.
*     WA_PERIOD-PER = 'Q2'.
*     APPEND WA_PERIOD TO IT_PERIOD.
*     CLEAR WA_PERIOD.
*
*     WA_PERIOD-PERIOD = 'Oct - Dec'.
*     WA_PERIOD-PER = 'Q3'.
*     APPEND WA_PERIOD TO IT_PERIOD.
*     CLEAR WA_PERIOD.
*
*     WA_PERIOD-PERIOD = 'Jan - Mar'.
*     WA_PERIOD-PER = 'Q4'.
*     APPEND WA_PERIOD TO IT_PERIOD.
*     CLEAR WA_PERIOD.
*
*   ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PER'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'S_PERIOD_LOW'
      value_org       = 'S'
    TABLES
      value_tab       = it_period
      return_tab      = it_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

ENDMODULE.

MODULE user_command_0111 INPUT.


  CASE sy-ucomm.
    WHEN 'BACK'.

      REFRESH : it_quant[]. "Clear inputs
      CLEAR: it_quant,bbl_mmbbl,bbl_mmt,mmscm_mmbtu,mmscm_mmboe,mmscm_bcm,ton_bbl,wa_final_qi_o,wa_final_qi_g,wa_final_conv,stat.

      IF grid1 IS BOUND.         "Clear grid and conatainer
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0101 .    "move to previous screen

    WHEN 'EXIT'.

      REFRESH : it_quant[].  "Clear inputs
      CLEAR: it_quant,bbl_mmbbl,bbl_mmt,mmscm_mmbtu,mmscm_mmboe,mmscm_bcm,ton_bbl,wa_final_qi_o, wa_final_qi_g, wa_final_conv,stat.

      IF grid1 IS BOUND.           "Clear grid and conatainer
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0001.    "move to main screen

    WHEN 'CANC'.

      REFRESH : it_quant[].    "Clear inputs
      CLEAR: it_quant,bbl_mmbbl,bbl_mmt,mmscm_mmbtu,mmscm_mmboe,mmscm_bcm,ton_bbl,wa_final_qi_o, wa_final_qi_g, wa_final_conv,stat.

      IF grid1 IS BOUND.         "Clear grid and conatainer
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0101 ."move to previous screen

    WHEN 'CALC'.
      PERFORM cal_quant.     "calculate Quant Info values

    WHEN 'SAVE'.
      PERFORM cal_quant.
      PERFORM save_quant.   "Save Quant Info data into database tables

      CALL METHOD grid1->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.     "After save freeze the screen input

      LOOP AT SCREEN.
        IF screen-group1 = 'DIS'.    "After save freeze the screen input
          screen-input     = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.

      IF sy-ucomm EQ 'OPT1'.          "
        CLEAR: it_quant,bbl_mmbbl,bbl_mmt,mmscm_mmbtu,mmscm_mmboe,mmscm_bcm,ton_bbl,wa_final_qi_o, wa_final_qi_g, wa_final_conv.
        REFRESH : it_quant[].
        CLEAR it_quant[].
        LEAVE TO SCREEN 0101.
      ENDIF.

    WHEN 'APPROVE'.
      PERFORM app_quant.             "Approve the Quant data

    WHEN 'FREEZE'.
      PERFORM app_quant.             "Freeze the Quant data

    WHEN 'PRI'.
      PERFORM download_xl.           "Download Quantitative Information Excel.

    WHEN 'ATTACHMENT'.
      PERFORM attachments.            "Create/Change/Display/Delete attachments

    WHEN OTHERS.

  ENDCASE.

ENDMODULE.

MODULE user_command_0201 INPUT.

  PERFORM auth_check.         "Authorization check for Create/Change/Display/Approve/Freeze

  PERFORM initail_chk.        "check mandatory input fields
  IF p_company IS NOT INITIAL
      AND p_proj IS NOT INITIAL
      AND p_year IS NOT INITIAL
      AND s_period_low IS NOT INITIAL.

    SELECT SINGLE * FROM zpnl_prd_oil
      INTO @DATA(chk_cre_oil)
      WHERE company = @p_company
        AND bukrs   = @p_comp
        AND pro_nam = @p_proj
        AND fisyear = @p_year
        AND zperiod = @s_period_low.
  ENDIF.

  IF sy-ucomm NE 'CREATE' AND chk_cre_oil IS NOT INITIAL.
    CLEAR stat.
    IF chk_cre_oil-freezed_by IS NOT INITIAL.      "to set status freezed
      stat = 'FREEZED'.
    ELSEIF chk_cre_oil-approved_by IS NOT INITIAL AND chk_cre_oil-approved_by_rp IS  INITIAL.. "to set status approved
      stat = 'APPROVED'.
    ELSEIF chk_cre_oil-approved_by IS NOT INITIAL AND chk_cre_oil-approved_by_rp IS NOT INITIAL. "to set status approved
      stat = 'APPROVEDFI'.
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'CREATE' AND chk_cre_oil IS NOT INITIAL.      "if data already created for given inputs
    CLEAR : sy-ucomm,chk_cre_oil.
    MESSAGE 'Data already created for given inputs' TYPE 'E'.
  ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE' ) AND ( chk_cre_oil IS NOT INITIAL ).
    IF chk_cre_oil-freezed_by IS NOT INITIAL AND chk_cre_oil-freezed_on IS NOT INITIAL.
      CLEAR : sy-ucomm,chk_cre_oil.
      MESSAGE 'Data is already freezed. You can only display now' TYPE 'E'.    "cannot change/approve if data freezed
    ENDIF.
  ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE' )
          AND ( chk_cre_oil IS INITIAL ).
    CLEAR : sy-ucomm,chk_cre_oil.
    MESSAGE 'Data not yet created for given inputs' TYPE 'E'.    "cannot perform any action if data not created
  ENDIF.

  CLEAR: mode,chk_cre_oil.

  CASE sy-ucomm.
    WHEN 'CREATE'.
      mode = 'CRE'.

      PERFORM create_prof_prd.     "Create screen layout for producing project input
      PERFORM fcat_fill_prof_prd.  "fill field catalog for producing project input

      CALL SCREEN 0211.

    WHEN 'CHANGE'.
      mode = 'CHA'.

      PERFORM create_prof_prd.
      PERFORM change_prof_prd.    "to update the changes in the existing data

      CLEAR sy-ucomm.
      CALL SCREEN 0211.

    WHEN 'DISPLAY'.
      mode = 'DIS'.

      PERFORM create_prof_prd.
      PERFORM change_prof_prd.

      CLEAR sy-ucomm.
      CALL SCREEN 0211.

    WHEN 'APPROVE'.
      mode = 'APP'.

      PERFORM create_prof_prd.
      PERFORM change_prof_prd.

      CLEAR sy-ucomm.
      CALL SCREEN 0211.
*******************ADDED BY APARNA ON 31 .07 .2024
    WHEN 'APPROVEFI'.
      mode = 'APF'.

      PERFORM create_prof_prd.
      PERFORM change_prof_prd.

      CLEAR sy-ucomm.
      CALL SCREEN 0211.
*************** ENDED BY APARNA ON 31.07 .2024
    WHEN 'FREEZE'.
      mode = 'FRE'.

      PERFORM create_prof_prd.
      PERFORM change_prof_prd.

      CLEAR sy-ucomm.
      CALL SCREEN 0211.

    WHEN 'BACK'.

      PERFORM clear_on_exit.
      LEAVE TO SCREEN 0001.

    WHEN 'EXIT'.
      PERFORM clear_on_exit.
      LEAVE PROGRAM.

    WHEN 'CANC'.

      PERFORM clear_on_exit.
      LEAVE TO SCREEN 0001.

    WHEN OTHERS.

  ENDCASE.

ENDMODULE.

MODULE user_command_0211 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK'.
      REFRESH : it_prof_prd[],it_prof_prd2[].
      CLEAR : it_prof_prd,wa_prd_oil.
      CLEAR stat.
      IF grid1 IS BOUND.
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0201 .

    WHEN 'EXIT'.
      REFRESH : it_prof_prd[],it_prof_prd2[].
      CLEAR : it_prof_prd,wa_prd_oil.
      CLEAR stat.

      IF grid1 IS BOUND.
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0201.

    WHEN 'CANC'.
      REFRESH : it_prof_prd[],it_prof_prd2[].
      CLEAR : it_prof_prd,wa_prd_oil.
      CLEAR stat.

      IF grid1 IS BOUND.
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0201.

    WHEN 'CALC'.
      PERFORM calc_0211.
      CALL METHOD grid1->refresh_table_display.

    WHEN 'SAVE'.
      PERFORM calc_0211.
      PERFORM save_prof_prd.

      CALL METHOD grid1->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.

      LOOP AT SCREEN.
        IF screen-group1 = 'DIS'.    "After save freeze the screen input
          screen-input     = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.

      IF sy-ucomm EQ 'OPT1'.
        REFRESH : it_prof_prd[].
        CLEAR it_prof_prd[].
        LEAVE TO SCREEN 0201.
      ENDIF.

    WHEN 'APPROVE' OR  'APPROVEFI'.
      PERFORM app_prd_i.
    WHEN 'FREEZE'.
      PERFORM app_prd_i.
    WHEN OTHERS.

  ENDCASE.

ENDMODULE.

MODULE user_command_0301 INPUT.

  PERFORM auth_check.   "Authorization check for Create/Change/Display/Approve/Freeze

  PERFORM initail_chk.

  IF p_company IS NOT INITIAL
       AND p_proj IS NOT INITIAL
       AND p_year IS NOT INITIAL
       AND s_period_low IS NOT INITIAL.

    SELECT SINGLE * FROM zpnl_oth_proj
      INTO @DATA(chk_cre_oth)
      WHERE company = @p_company
        AND bukrs   = @p_comp
        AND pro_nam = @p_proj
        AND fisyear = @p_year
        AND zperiod = @s_period_low.
  ENDIF.

  IF ( sy-ucomm NE 'CREATE' ) AND ( chk_cre_oth IS NOT INITIAL ). "Check for frezeed and approved
    IF chk_cre_oth-freezed_by IS NOT INITIAL.
      CLEAR stat.
      stat = 'FREEZED'.
    ELSEIF chk_cre_oth-approve_by IS NOT INITIAL  AND chk_cre_oth-approved_by_rp IS  INITIAL.
      CLEAR stat.
      stat = 'APPROVED'.

    ELSEIF chk_cre_oth-approve_by IS NOT INITIAL AND chk_cre_oth-approved_by_rp IS NOT INITIAL.
      CLEAR stat.
      stat = 'APPROVEDFI'.
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'CREATE' AND chk_cre_oth IS NOT INITIAL.   "Check for already created
    CLEAR : sy-ucomm,chk_cre_oth.
    MESSAGE 'Data already created for given inputs' TYPE 'E'.
  ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' ) AND ( chk_cre_oth IS INITIAL ).  "Check for data not created
    CLEAR : sy-ucomm,chk_cre_oth.
    MESSAGE 'Data not yet created for given inputs' TYPE 'E'.
  ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE' ) AND ( chk_cre_oth IS NOT INITIAL ).
    IF chk_cre_oth-freezed_by IS NOT INITIAL AND chk_cre_oth-freezed_on IS NOT INITIAL.
      CLEAR : sy-ucomm,chk_cre_oth.
      MESSAGE 'Data is already freezed. You can only display now' TYPE 'E'.    "cannot change/approve if data freezed
    ENDIF.
  ELSEIF ( sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE' )
     AND ( chk_cre_oth IS INITIAL ).
    CLEAR : sy-ucomm,chk_cre_oth.
    MESSAGE 'Data not yet created for given inputs' TYPE 'E'.    "cannot perform any action if data not created
  ENDIF.

  CLEAR : chk_cre_oth.

  CASE sy-ucomm.
    WHEN 'CREATE'.
      mode = 'CRE'.
      PERFORM create_oth_proj.   "Create layout for non producing projects
      CLEAR sy-ucomm.
      CALL SCREEN 0311.
    WHEN 'CHANGE'.
      mode = 'CHA'.
      PERFORM create_oth_proj.
      PERFORM change_oth_proj.    "get previously filled data
      CLEAR sy-ucomm.
      CALL SCREEN 0311.
    WHEN 'DISPLAY'.
      mode = 'DIS'.
      PERFORM create_oth_proj.
      PERFORM change_oth_proj.
      CLEAR sy-ucomm.
      CALL SCREEN 0311.
    WHEN 'APPROVE'.
      mode = 'APP'.
      PERFORM create_oth_proj.
      PERFORM change_oth_proj.
      CLEAR sy-ucomm.
      CALL SCREEN 0311.
    WHEN 'FREEZE'.
      mode = 'FRE'.
      PERFORM create_oth_proj.
      PERFORM change_oth_proj.
      CLEAR sy-ucomm.
      CALL SCREEN 0311.
    WHEN 'BACK'.
      PERFORM clear_on_exit.
      LEAVE TO SCREEN 0001.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANC'.
      LEAVE TO SCREEN 0001.
*----------------------------------" Changes begins by Aparna on 31.07.2024 "------------------------------*
    WHEN 'APPROVEFI'.
      mode = 'APF'.
      PERFORM create_oth_proj.
      PERFORM change_oth_proj.
      CLEAR sy-ucomm.
      CALL SCREEN 0311.
*----------------------------------" Changes ended  by Aparna on 31.07.2024 "------------------------------*
  ENDCASE.

ENDMODULE.

MODULE user_command_0311 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK'.

      REFRESH it_oth_proj[].
      CLEAR : it_oth_proj,wa_pnl_oth.

      IF grid1 IS BOUND.         "clear grid and container
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      CALL SCREEN 0301 .

    WHEN 'EXIT'.

      REFRESH it_oth_proj[].
      CLEAR : it_oth_proj,wa_pnl_oth.

      IF grid1 IS BOUND.
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.

      LEAVE TO SCREEN 0301.

    WHEN 'CANC'.

      REFRESH it_oth_proj[].
      CLEAR : it_oth_proj,wa_pnl_oth.

      IF grid1 IS BOUND.
        CALL METHOD grid1->free.
        CLEAR grid1.
        CALL METHOD g_custom_container->free.
        CLEAR g_custom_container.
        CLEAR g_container.
      ENDIF.


      CALL SCREEN 0301 .

    WHEN 'CALC'.
      PERFORM calc_0311.

    WHEN 'SAVE'.
      PERFORM save_oth_proj.       "save data into database tables

      CALL METHOD grid1->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.

      IF sy-ucomm EQ 'OPT1'.
        REFRESH it_oth_proj[].
        CLEAR it_oth_proj.
        LEAVE TO SCREEN 0301.
      ENDIF.

    WHEN 'APPROVE'.

      PERFORM save_oth_proj.

      CALL METHOD grid1->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.

      REFRESH it_oth_proj[].
      CLEAR it_oth_proj.
      LEAVE TO SCREEN 0301.

**************************** ADDED BY APARNA
    WHEN 'APPROVEFI'.

      PERFORM save_oth_proj.

      CALL METHOD grid1->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.

      REFRESH it_oth_proj[].
      CLEAR it_oth_proj.
      LEAVE TO SCREEN 0301.
********************************** ENDED BY APARNA
    WHEN 'FREEZE'.

      PERFORM save_oth_proj.

      CALL METHOD grid1->set_ready_for_input
        EXPORTING
          i_ready_for_input = 0.

      REFRESH it_oth_proj[].
      CLEAR it_oth_proj.
      LEAVE TO SCREEN 0301.

    WHEN OTHERS.

  ENDCASE.

ENDMODULE.

MODULE user_command_0401 INPUT.

  DATA : lv_profitabilty     TYPE c,
         lv_non_profitabilty TYPE c. " Start of changes Madhu
  CLEAR : lv_profitabilty,lv_non_profitabilty." Start of changes Madhu

  IF sy-ucomm = 'DISPLAY'.

    lv_ucomm = 'DISPLAY'.
  ELSE.
    lv_ucomm = ''.
  ENDIF.
  EXPORT  lv_ucomm TO MEMORY ID 'A1'.

  CASE sy-ucomm.

    WHEN 'EXECUTE'.
      lv_non_profitabilty = 'X'.
      IF pnl = 'PRD_QTY' OR pnl = 'REV' OR pnl = 'BAR_REP' OR pnl = 'AGE_REP'.
        p_proj1-low  = 'ALL' .
        p_compy1 = 'ALL'.
      ENDIF.
      IF ( p_compy1 IS INITIAL ) OR ( p_proj1-low IS INITIAL ) OR ( p_year1 IS INITIAL ) OR
        ( s_period-low IS INITIAL ) OR ( p_year2 IS INITIAL ) OR ( s_period_low2 IS INITIAL ).
        CLEAR sy-ucomm.
        MESSAGE 'Fill in all required entry fields' TYPE 'E'.   "all input fields are mandatory
      ENDIF.

      CLEAR : it_final_bar , it_fcat , it_final_bar1.
      IF p_compy1 IS NOT INITIAL.
        SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      ENDIF.

      IF pnl = 'PRD_PROJ'.
        SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE bukrs = p_comp1
                          AND prod = 'YES'.

        IF it_proj IS INITIAL. "check project for that company code
          CLEAR p_proj1-low.
          CLEAR sy-ucomm.
          MESSAGE 'No Projects found for given inputs' TYPE 'E'.

        ELSE.
          READ TABLE it_proj INTO DATA(wa_proj_c) WITH KEY jvnam = p_proj1-low.
          IF wa_proj_c-jvnam NE p_proj1-low. "check given project is valid or not
            CLEAR sy-ucomm.
            MESSAGE 'Non-producing project selected. Please check' TYPE 'E'.
          ENDIF.
          CLEAR wa_proj_c.
        ENDIF.

      ELSEIF pnl = 'NON_PRD'.
        SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE bukrs = p_comp1
                          AND prod = 'NO'.

        IF it_proj IS INITIAL.
          CLEAR p_proj1-low.
          CLEAR sy-ucomm.
          MESSAGE 'No Projects found for given inputs' TYPE 'E'.

        ELSE.
          READ TABLE it_proj INTO wa_proj_c WITH KEY jvnam = p_proj1-low.
          IF wa_proj_c-jvnam NE p_proj1-low.
            CLEAR sy-ucomm.
            MESSAGE 'Producing project selected. Please check.' TYPE 'E'.
          ENDIF.
          CLEAR wa_proj_c.
        ENDIF.

      ELSEIF pnl = 'VAR_BAR'.
        SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE bukrs = p_comp1
                          AND prod = 'YES'.

        IF it_proj IS INITIAL.
          CLEAR p_proj1-low.
          CLEAR sy-ucomm.
          MESSAGE 'No Projects found for given inputs' TYPE 'E'.

        ELSE.
          READ TABLE it_proj INTO wa_proj_c WITH KEY jvnam = p_proj1-low.
          IF wa_proj_c-jvnam NE p_proj1-low.
            CLEAR sy-ucomm.
            MESSAGE 'Non-producing project selected. Please check' TYPE 'E'.
          ENDIF.
          CLEAR wa_proj_c.
        ENDIF.

      ELSEIF pnl = 'VAR_NON'.
        SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE bukrs = p_comp1
                          AND prod = 'NO'.

        IF it_proj IS INITIAL.
          CLEAR p_proj1-low.
          CLEAR sy-ucomm.
          MESSAGE 'No Projects found for given inputs' TYPE 'E'.

        ELSE.
          READ TABLE it_proj INTO wa_proj_c WITH KEY jvnam = p_proj1-low.
          IF wa_proj_c-jvnam NE p_proj1-low.
            CLEAR sy-ucomm.
            MESSAGE 'Producing project selected. Please check.' TYPE 'E'.
          ENDIF.
          CLEAR wa_proj_c.
        ENDIF.

      ELSEIF pnl = 'PER_BAR'.
        SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE bukrs = p_comp1
                          AND prod = 'YES'.

        IF it_proj IS INITIAL. "check project for that company code
          CLEAR p_proj1-low.
          CLEAR sy-ucomm.
          MESSAGE 'No Projects found for given inputs' TYPE 'E'.

        ELSE.
          READ TABLE it_proj INTO wa_proj_c WITH KEY jvnam = p_proj1-low.
          IF wa_proj_c-jvnam NE p_proj1-low. "check given project is valid or not
            CLEAR sy-ucomm.
            MESSAGE 'Non-producing project selected. Please check.' TYPE 'E'.
          ENDIF.
          CLEAR wa_proj_c.
        ENDIF.
      ENDIF.
      IF p_comp1 = 'OVL'. "GL maintenance check needs to be there only in the case of OVL Co. Code
        PERFORM check_gls. "Check all GLs are maintained in GL table maintanence
      ELSE.
        gl_msg_lines = '0'.
      ENDIF.

      PERFORM get_gls.   "Get GLs from set which are to be seperated in oil and gas fields

      IF gl_msg_lines EQ '0'.
        IF pnl = 'PRD_PROJ'.
          PERFORM cre_prd_proj.           "Create layout for Producing projects
          PERFORM fcat_fill_prd.          "fill field catlouge
          PERFORM alv_display_prd.        "Display report
        ELSEIF pnl = 'NON_PRD'.
          PERFORM cre_non_prd.            "Create layout for Producing projects
          PERFORM fcat_fill_non.          "fill field catlouge
          PERFORM alv_display_non.        "Display report
        ELSEIF pnl = 'VAR_PRD'.
          PERFORM cre_prd_proj.          "Create layout for Producing projects variance analysis
          PERFORM cre_var_prd.           "Calculations for variance analysis producing projects
          PERFORM fcat_fill_var_prd.     "fill field catlouge
          PERFORM alv_display_var_prd.   "Display report
        ELSEIF pnl = 'VAR_NON'.
          PERFORM cre_non_prd.           "Create layout for Non-Producing projects
          PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
          PERFORM fcat_fill_var_non.     "fill field catlouge
          PERFORM alv_display_var_non.   "Display report
        ELSEIF pnl = 'PER_BAR'.
          PERFORM cre_prd_proj.          "Create layout for Producing projects Per Barrel analysis
          PERFORM cre_per_barl.
          PERFORM fcat_fill_per_bar.     "fill field catlouge
          PERFORM alv_display_per_bar.   "Display report
*************ADDED BY APARNA 22/03/24
        ELSEIF pnl = 'PRD_QTY'.
          PERFORM cre_prd_qty.           "Create layout for Non-Producing projects
*          PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
          PERFORM fcat_fill_prd_qty.     "fill field catlouge
          PERFORM alv_display_prd_qty.   "Display report

        ELSEIF pnl = 'REV'.
          PERFORM cre_rev.           "Create layout for Non-Producing projects
*          PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
          PERFORM fcat_fill_rev.     "fill field catlouge
          PERFORM alv_display_rev.   "Display report

        ELSEIF pnl = 'BAR_REP'.
          PERFORM cre_bar.           "Create layout for Non-Producing projects
*          PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
          PERFORM fcat_fill_bar_rep.     "fill field catlouge
          PERFORM alv_display_rev.   "Display report

        ELSEIF pnl = 'AGE_REP'.
          PERFORM cre_age.           "Create layout for Non-Producing projects
*          PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
          PERFORM fcat_fill_age.     "fill field catlouge
          PERFORM alv_display_age.   "Display report

*  *************ENDED BY APARNA 22/03/24
        ENDIF.
      ELSEIF gl_msg_lines GT '0'.
        LEAVE TO SCREEN 401.
      ENDIF.

    WHEN 'CREATE' .
      PERFORM auth_check.

      IF ( p_compy1 IS INITIAL ) OR ( p_proj1-low IS INITIAL ) OR ( p_year1 IS INITIAL ) OR
    ( s_period-low IS INITIAL ) OR ( p_year2 IS INITIAL ) OR ( s_period_low2 IS INITIAL ).
        CLEAR sy-ucomm.
        MESSAGE 'Fill in all required entry fields' TYPE 'E'.   "all input fields are mandatory
      ENDIF.

      CLEAR : it_final_bar , it_fcat , it_final_bar1.
      IF pnl = 'VAR_PRD'.
        SELECT SINGLE status_cre FROM zfi_pl_status INTO @DATA(wa_status1) WHERE period = @s_period-low
                                                       AND period2 = @s_period_low2
                                                       AND fiscal = @p_year1
                                                       AND proj = @p_proj1-low
                                                       AND p_compy1 = @p_compy1
                                                       AND comp = @p_comp1.
      ELSEIF pnl = 'VAR_NON'.
        SELECT SINGLE status_cre FROM zfi_pl_status_n INTO @wa_status1 WHERE period = @s_period-low
                                                   AND period2 = @s_period_low2
                                                   AND fiscal = @p_year1
                                                   AND proj = @p_proj1-low
                                                   AND p_compy1 = @p_compy1
                                                   AND comp = @p_comp1.
      ENDIF.
      IF wa_status1 IS NOT INITIAL.
        MESSAGE 'Data already Created. Use Change or Display.' TYPE 'E'.
      ENDIF.
      CLEAR : wa_status1.
      IF pnl = 'VAR_PRD'.
        SELECT SINGLE status FROM zfi_pl_status INTO @DATA(wa_status) WHERE period = @s_period-low
                                                 AND period2 = @s_period_low2
                                                 AND fiscal = @p_year1
                                                 AND proj = @p_proj1-low
                                                 AND p_compy1 = @p_compy1
                                                 AND comp = @p_comp1.
      ELSEIF pnl = 'VAR_NON'.
        SELECT SINGLE status FROM zfi_pl_status_n INTO @wa_status WHERE period = @s_period-low
                                           AND period2 = @s_period_low2
                                           AND fiscal = @p_year1
                                           AND proj = @p_proj1-low
                                           AND p_compy1 = @p_compy1
                                           AND comp = @p_comp1.
      ENDIF.
      IF wa_status IS NOT INITIAL.
        MESSAGE 'Data already Approved. Changes not allowed.' TYPE 'E'.
      ENDIF.
      CLEAR : wa_status.
      IF p_compy1 IS NOT INITIAL.
        SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      ENDIF.


      IF p_comp1 = 'OVL'. "GL maintenance check needs to be there only in the case of OVL Co. Code
        PERFORM check_gls. "Check all GLs are maintained in GL table maintanence
      ELSE.
        gl_msg_lines = '0'.
      ENDIF.


      PERFORM get_gls.   "Get GLs from set which are to be seperated in oil and gas fields
      IF pnl = 'VAR_PRD'.
        PERFORM cre_prd_proj.          "Create layout for Producing projects variance analysis
        PERFORM cre_var_prd.           "Calculations for variance analysis producing projects
        PERFORM fcat_fill_var_prd1.     "fill field catlouge
        PERFORM alv_display_var_prd.   "Display report
      ELSEIF pnl = 'VAR_NON'.
        PERFORM cre_non_prd.           "Create layout for Non-Producing projects
        PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
        PERFORM fcat_fill_var_non.     "fill field catlouge
        PERFORM alv_display_var_non.   "Display report
      ELSEIF gl_msg_lines GT '0'.
        LEAVE TO SCREEN 401.
      ENDIF.
    WHEN 'CHANGE'.

      PERFORM auth_check.

      IF ( p_compy1 IS INITIAL ) OR ( p_proj1-low IS INITIAL ) OR ( p_year1 IS INITIAL ) OR
    ( s_period-low IS INITIAL ) OR ( p_year2 IS INITIAL ) OR ( s_period_low2 IS INITIAL ).
        CLEAR sy-ucomm.
        MESSAGE 'Fill in all required entry fields' TYPE 'E'.   "all input fields are mandatory
      ENDIF.
      CLEAR : wa_status.
      SELECT SINGLE status FROM zfi_pl_status INTO @wa_status WHERE period = @s_period-low
                                               AND period2 = @s_period_low2
                                               AND fiscal = @p_year1
                                               AND proj = @p_proj1-low
                                               AND comp = @p_comp1.
      IF wa_status IS NOT INITIAL.
        MESSAGE 'Data has been already Approved You Can not change' TYPE 'E'.
      ENDIF.

      CLEAR : it_final_bar , it_fcat , it_final_bar1.
      IF p_compy1 IS NOT INITIAL.
        SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      ENDIF.


      IF p_comp1 = 'OVL'. "GL maintenance check needs to be there only in the case of OVL Co. Code
        PERFORM check_gls. "Check all GLs are maintained in GL table maintanence
      ELSE.
        gl_msg_lines = '0'.
      ENDIF.


      PERFORM get_gls.   "Get GLs from set which are to be seperated in oil and gas fields
      IF pnl = 'VAR_PRD'.
        PERFORM cre_prd_proj.          "Create layout for Producing projects variance analysis
        PERFORM cre_var_prd.           "Calculations for variance analysis producing projects
        PERFORM fcat_fill_var_prd1.     "fill field catlouge
        PERFORM alv_display_var_prd.   "Display report
      ELSEIF pnl = 'VAR_NON'.
        PERFORM cre_non_prd.           "Create layout for Non-Producing projects
        PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
        PERFORM fcat_fill_var_non.     "fill field catlouge
        PERFORM alv_display_var_non.   "Display report
      ELSEIF gl_msg_lines GT '0'.
        LEAVE TO SCREEN 401.
      ENDIF.
      CLEAR lv_ucomm.
    WHEN 'DISPLAY'.

      PERFORM auth_check.
      IF ( p_compy1 IS INITIAL ) OR ( p_proj1-low IS INITIAL ) OR ( p_year1 IS INITIAL ) OR
    ( s_period-low IS INITIAL ) OR ( p_year2 IS INITIAL ) OR ( s_period_low2 IS INITIAL ).
        CLEAR sy-ucomm.
        MESSAGE 'Fill in all required entry fields' TYPE 'E'.   "all input fields are mandatory
      ENDIF.

      CLEAR : it_final_bar , it_fcat , it_final_bar1.

      IF p_compy1 IS NOT INITIAL.
        SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      ENDIF.


      IF p_comp1 = 'OVL'. "GL maintenance check needs to be there only in the case of OVL Co. Code
        PERFORM check_gls. "Check all GLs are maintained in GL table maintanence
      ELSE.
        gl_msg_lines = '0'.
      ENDIF.

      PERFORM get_gls.   "Get GLs from set which are to be seperated in oil and gas fields
      IF pnl = 'VAR_PRD'.
        PERFORM cre_prd_proj.          "Create layout for Producing projects variance analysis
        PERFORM cre_var_prd.           "Calculations for variance analysis producing projects
        PERFORM fcat_fill_var_prd.     "fill field catlouge
        PERFORM alv_display_var_prd.   "Display report
      ELSEIF pnl = 'VAR_NON'.
        PERFORM cre_non_prd.           "Create layout for Non-Producing projects
        PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
        PERFORM fcat_fill_var_non1.     "fill field catlouge
        PERFORM alv_display_var_non.   "Display report
      ELSEIF gl_msg_lines GT '0'.
        LEAVE TO SCREEN 401.
      ENDIF.
    WHEN 'APPROVE' OR 'APPROVEFI'.
      PERFORM auth_check.
      IF ( p_compy1 IS INITIAL ) OR ( p_proj1-low IS INITIAL ) OR ( p_year1 IS INITIAL ) OR
    ( s_period-low IS INITIAL ) OR ( p_year2 IS INITIAL ) OR ( s_period_low2 IS INITIAL ).
        CLEAR sy-ucomm.
        MESSAGE 'Fill in all required entry fields' TYPE 'E'.   "all input fields are mandatory
      ENDIF.

      CLEAR : it_final_bar , it_fcat , it_final_bar1.


      IF p_compy1 IS NOT INITIAL.
        SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      ENDIF.


      IF p_comp1 = 'OVL'. "GL maintenance check needs to be there only in the case of OVL Co. Code
        PERFORM check_gls. "Check all GLs are maintained in GL table maintanence
      ELSE.
        gl_msg_lines = '0'.
      ENDIF.

      PERFORM get_gls.   "Get GLs from set which are to be seperated in oil and gas fields
      IF pnl = 'VAR_PRD'.
        PERFORM cre_prd_proj.          "Create layout for Producing projects variance analysis
        PERFORM cre_var_prd.           "Calculations for variance analysis producing projects
        PERFORM fcat_fill_var_prd.     "fill field catlouge
        PERFORM alv_display_var_prd.   "Display report
      ELSEIF pnl = 'VAR_NON'.
        PERFORM cre_non_prd.           "Create layout for Non-Producing projects
        PERFORM cre_var_non.           "Calculations for variance analysis non-producing projects
        PERFORM fcat_fill_var_non1.     "fill field catlouge
        PERFORM alv_display_var_non.   "Display report
      ELSEIF gl_msg_lines GT '0'.
        LEAVE TO SCREEN 401.
      ENDIF.
    WHEN OTHERS.

  ENDCASE.


ENDMODULE.

MODULE user_exit_comm INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      CLEAR : it_final_bar , it_fcat.
      LEAVE TO SCREEN 0001.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANC'.
      LEAVE TO SCREEN 0001.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0501  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0501 INPUT.
*Begin of Changes - Madhu
  CLEAR : lv_profitabilty.
*End of Changes - Madhu

  CASE sy-ucomm.

    WHEN 'EXECUTE'.
      "Begin of Changes - Madhu
      lv_profitabilty = 'X'.
      "End of Changes - Madhu
      IF ( p_compy1 IS INITIAL ) OR ( p_proj1-low IS INITIAL ) OR ( p_year1 IS INITIAL ) OR
        ( s_period-low IS INITIAL ) OR ( p_year2 IS INITIAL ) OR ( s_period_low2 IS INITIAL ).
        CLEAR sy-ucomm.
        MESSAGE 'Fill in all required entry fields' TYPE 'E'.   "all input fields are mandatory
      ENDIF.

      CLEAR : it_final_bar , it_fcat , it_final_bar1.
      IF p_compy1 IS NOT INITIAL.
        SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      ENDIF.

      IF pnl = 'PRO_ANA'.
        SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE bukrs = p_comp1
                          AND prod = 'YES'.

        IF it_proj IS INITIAL. "check project for that company code
          CLEAR p_proj1-low.
          CLEAR sy-ucomm.
          MESSAGE 'No Projects found for given inputs' TYPE 'E'.

        ELSE.
          CLEAR wa_proj_c.
          READ TABLE it_proj INTO wa_proj_c WITH KEY jvnam = p_proj1-low.
          IF wa_proj_c-jvnam NE p_proj1-low. "check given project is valid or not
            CLEAR sy-ucomm.
            MESSAGE 'Non-producing project selected. Please check' TYPE 'E'.
          ENDIF.
          CLEAR wa_proj_c.
        ENDIF.
      ENDIF.

      PERFORM check_gls. "Check all GLs are maintained in GL table maintanence

      PERFORM get_gls.   "Get GLs from set which are to be seperated in oil and gas fields

      IF gl_msg_lines EQ '0'.
        IF pnl = 'PRO_ANA'.

          REFRESH it_pro_ana[].

          wa_pro_ana-per = '----------Quantitative Information Report---------------'.
          APPEND wa_pro_ana TO it_pro_ana.
          CLEAR : wa_pro_ana.

          PERFORM cre_quant_figs.       "Create Qunatitative Information Figures

          wa_pro_ana-per = ' '.
          APPEND wa_pro_ana TO it_pro_ana.
          CLEAR : wa_pro_ana.

          wa_pro_ana-per = '-----------Profitability Producing Project Report------------------'.
          APPEND wa_pro_ana TO it_pro_ana.
          CLEAR : wa_pro_ana.

          PERFORM cre_prd_proj.           "Create Profitability Producing Project Figures

          DATA(lv_p_count) = 40.

          CLEAR : wa_final_bar1,wa_pro_ana.
          LOOP AT it_final_bar1 INTO wa_final_bar1.

            wa_pro_ana-per    = wa_final_bar1-per.
            wa_pro_ana-total1 = wa_final_bar1-total1.
            wa_pro_ana-oil1   = wa_final_bar1-oil1  .
            wa_pro_ana-gas1   = wa_final_bar1-gas1  .

            wa_pro_ana-total2 = wa_final_bar1-total2.
            wa_pro_ana-oil2   = wa_final_bar1-oil2  .
            wa_pro_ana-gas2   = wa_final_bar1-gas2  .

            wa_pro_ana-total3 = wa_final_bar1-total3.
            wa_pro_ana-oil3   = wa_final_bar1-oil3  .
            wa_pro_ana-gas3   = wa_final_bar1-gas3  .

            wa_pro_ana-total4 = wa_final_bar1-total4.
            wa_pro_ana-oil4   = wa_final_bar1-oil4  .
            wa_pro_ana-gas4   = wa_final_bar1-gas4  .

            APPEND wa_pro_ana TO it_pro_ana.
            CLEAR : wa_final_bar1,wa_pro_ana.
          ENDLOOP.
          CLEAR : lv_p_count.


          wa_pro_ana-per = ' '.
          APPEND wa_pro_ana TO it_pro_ana.
          CLEAR : wa_pro_ana.

          wa_pro_ana-per = '------------------Per Barrel Analysis Report-----------------'.
          APPEND wa_pro_ana TO it_pro_ana.
          CLEAR : wa_pro_ana.

          PERFORM cre_per_barl.           "Get Profitability Per Barrel Figures.

          CLEAR : wa_final_per_bar,wa_pro_ana.
          LOOP AT it_final_per_bar INTO wa_final_per_bar.
            wa_pro_ana-per = wa_final_per_bar-per.
            wa_pro_ana-oil1   = wa_final_per_bar-oilp1  .
            wa_pro_ana-gas1   = wa_final_per_bar-gasp1  .

            wa_pro_ana-oil2   = wa_final_per_bar-oilp2  .
            wa_pro_ana-gas2   = wa_final_per_bar-gasp2  .

            wa_pro_ana-oil3   = wa_final_per_bar-oilp3  .
            wa_pro_ana-gas3   = wa_final_per_bar-gasp3  .

            wa_pro_ana-oil4   = wa_final_per_bar-oilp4  .
            wa_pro_ana-gas4   = wa_final_per_bar-gasp4  .

            APPEND wa_pro_ana TO it_pro_ana.
            CLEAR : wa_final_bar1,wa_pro_ana.
          ENDLOOP.

          CLEAR : lv_p_count.
          break abapuser02.
****************CODE BEIGN BY APARNA 28.03.2024<<<<<<<<<<<<<<<<<<<<
          LOOP AT it_pro_ana INTO wa_pro_ana.
            IF wa_pro_ana-per IS NOT INITIAL.
              IF wa_pro_ana-per CS 'Quantitative Information Report'.
                flag1 = 'X'.
                CLEAR : flag2 , flag3.
*                wa_agenda-per_key  = 'A1'.
              ELSEIF  wa_pro_ana-per CS 'Profitability Producing Project Report'.
                flag2 = 'X'.
                CLEAR : flag1 , flag3.
*                wa_agenda-per_key  = 'A2'.
              ELSEIF  wa_pro_ana-per CS 'Per Barrel Analysis Report'.
                flag3 = 'X'.
                CLEAR : flag1 , flag2.
*                wa_agenda-per_key = 'A3'.
              ENDIF.
              IF flag1 = 'X' AND flag2 NE 'X' AND flag3 NE 'X'.
                wa_agenda-per_key  = 'A1'.
              ELSEIF flag2 = 'X' AND flag1 NE 'X' AND flag3 NE 'X'.
                wa_agenda-per_key  = 'A2' .
              ELSEIF  flag3 = 'X' AND flag1 NE 'X' AND flag2 NE 'X'.
                wa_agenda-per_key  = 'A3'.
              ENDIF.
              wa_agenda-mandt = sy-mandt.
              wa_agenda-comp = p_comp.
              wa_agenda-fiscal1 = p_year1.
              wa_agenda-period1 = s_period-low.
              wa_agenda-fiscal2 = p_year2.
              wa_agenda-fiscal3 = p_year3.
              wa_agenda-fiscal4 = p_year4.
              wa_agenda-period2 = s_period_low2.
              wa_agenda-period3 = s_period_low3.
              wa_agenda-period4 = s_period_low4.
              wa_agenda-per  = wa_pro_ana-per.
              wa_agenda-proj = p_proj1-low.
              wa_agenda-crude_oil1 = wa_pro_ana-oil1.
              wa_agenda-crude_oil2 = wa_pro_ana-oil2.
              wa_agenda-crude_oil3 = wa_pro_ana-oil3.
              wa_agenda-crude_oil4 = wa_pro_ana-oil4.
              wa_agenda-gas1 = wa_pro_ana-gas1.
              wa_agenda-gas2 = wa_pro_ana-gas2.
              wa_agenda-gas3 = wa_pro_ana-gas3.
              wa_agenda-gas4 = wa_pro_ana-gas4.

              APPEND wa_agenda TO it_agenda.
              MODIFY zfi_agenda FROM wa_agenda.
              CLEAR wa_agenda.
              COMMIT WORK AND WAIT.
            ENDIF.
            CLEAR wa_pro_ana.
          ENDLOOP.
*          MODIFY zfi_agenda FROM TABLE  it_agenda.
****************CODE ENDED BY APARNA 28.03.2024<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


**************END OF ADDN*******************************


          PERFORM fcat_fill_prd.
          PERFORM alv_display_pro_ana.

        ENDIF.
      ELSEIF gl_msg_lines GT '0'.
        LEAVE TO SCREEN 401.
      ENDIF.

    WHEN OTHERS.

  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0601  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0601 INPUT.
  CASE sy-ucomm.
    WHEN 'EXECUTE'.
      IF p_year1 IS INITIAL OR s_period-low IS INITIAL.
        CLEAR sy-ucomm.
        MESSAGE 'Please enter fiscal year and Period' TYPE 'E'.
      ENDIF.

      PERFORM get_pend_rep.
      IF lt_pend_fin[] IS NOT INITIAL.
        PERFORM fcat_fill_pend.
        PERFORM alv_display_pend.
      ENDIF.

    WHEN 'BACK'.
      CLEAR : p_compy1 ,
              p_comp1  ,
              p_proj1  ,
              p_year1  ,
              s_period .
      REFRESH : s_period[],p_proj1[].
      LEAVE TO SCREEN 0001.

    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CANC'.
      CLEAR : p_compy1 ,
              p_comp1  ,
              p_proj1  ,
              p_year1  ,
              s_period .
      REFRESH : s_period[],p_proj1[].
      LEAVE TO SCREEN 0001.
  ENDCASE.



ENDMODULE.
