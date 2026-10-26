*&---------------------------------------------------------------------*
*&  Include MZFIPLO01
*&---------------------------------------------------------------------*
MODULE status_0001 OUTPUT.

  SET PF-STATUS 'STATUS_0001'.
  SET TITLEBAR 'TITLE_0001'.

  DATA(lv_bu_corp) = 'Z:FI_PL_CORP'.

  SELECT * FROM AGR_USERS INTO @DATA(LV_CRE_QT) UP TO 1 ROWS
 WHERE UNAME = @SY-UNAME AND AGR_NAME = @LV_BU_CORP
 ORDER BY PRIMARY KEY .
 ENDSELECT.

  LOOP AT SCREEN.
    IF screen-group1 = 'OLD' AND sy-uname+0(1) CA sy-abcde.
      screen-invisible = 0.
      MODIFY SCREEN.
    ENDIF.

    IF screen-group1 = 'PEN' AND lv_cre_qt IS INITIAL.
      screen-invisible = 1.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  PERFORM fetch_layout_texts.                                           "get texts to be used in all programs/reports

  sy-ucomm = ''.

ENDMODULE.

MODULE status_0101 OUTPUT.

  SET PF-STATUS 'STATUS_0101'.
  SET TITLEBAR 'TITLE_0101' WITH '' 'Quantitative Information'.

  PERFORM clear_list.                                                     "Clear input parameters if input parameters does not match with the corresponding entries in Z Table

ENDMODULE.

MODULE status_0111 OUTPUT.

  IF mode = 'CRE'.   "When Create
    SET TITLEBAR 'TITLE_0101' WITH 'Create -' 'Quantitative Information'.

    CLEAR fcode.
    wa_fcode = 'FREEZE'.             "excluding freeze button
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.            "excluding approve button
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'PRINT'.              "excluding print function
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'ATTACHMENT'.         "excluding attachment button
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0111' EXCLUDING fcode.

  ELSEIF mode = 'CHA'.    "When Change
    SET TITLEBAR 'TITLE_0101' WITH 'Change -' 'Quantitative Information'.

    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'PRINT'.              "excluding print
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0111' EXCLUDING fcode.

  ELSEIF mode = 'DIS'.   "When Display
    SET TITLEBAR 'TITLE_0101' WITH 'Display -' 'Quantitative Information'.

    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0111' EXCLUDING fcode.

  ELSEIF mode = 'APP' OR mode = 'APF'. "When Approve   ADDED BY APARNA ON 27/06/2024
    SET TITLEBAR 'TITLE_0101' WITH 'Approve -' 'Quantitative Information'.
    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0111' EXCLUDING fcode.

  ELSEIF mode = 'FRE'.    "When Freeze
    SET TITLEBAR 'TITLE_0101' WITH 'Freeze -' 'Quantitative Information'.
    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0111' EXCLUDING fcode .

  ENDIF.

*Disable all inputs in display mode
  IF ( mode EQ 'DIS' ) OR ( mode EQ 'APP' )  OR ( mode EQ 'FRE' ) OR ( mode EQ 'APF' ). " ADDED BY APARNA ON 27/06/2024
    LOOP AT SCREEN.
      IF screen-group1 = 'DIS'.
        screen-input     = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
    PERFORM cal_quant.
  ENDIF.

*Removing the status tab and calucation based cloumns from create screen
  IF mode EQ 'CRE'.
    LOOP AT SCREEN.
      IF screen-name = 'STATUS'.
        screen-input     = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

    LOOP AT SCREEN.
      IF screen-name = 'CALC'.
        screen-input     = 1.
        screen-invisible = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF mode EQ 'CHA'.
    LOOP AT SCREEN.
      IF screen-name = 'CALC'.
        screen-input     = 1.
        screen-invisible = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

*Displaying/Removing in status tab on screen
  IF stat IS INITIAL.
    LOOP AT SCREEN.
      IF screen-name = 'FRAME3'.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'STATUS'.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'TEXT1'.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF stat IS NOT INITIAL.
    LOOP AT SCREEN.
      IF screen-name = 'TEXT1'.
        screen-invisible = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

*Display status icon as approve/freeze.
  IF stat = 'APPROVED'.
    icon_type = 'ICON_ALLOW'.
    icon_text = 'Approved(FI)'.

   ELSEIF  stat = 'APPROVEFI'.
    icon_type = 'ICON_ALLOW'.
    icon_text = 'Approved(RP)'.

  ELSEIF stat = 'FREEZED'.
    icon_type = 'ICON_LOCKED'.
    icon_text = 'Freezed'.
  ENDIF.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = icon_type
      text                  = icon_text
    IMPORTING
      result                = status
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  g_container = 'SUBSCREEN_0111'.     "custom container

  IF lt_fcat[] IS NOT INITIAL.
    PERFORM fcat_fill_quant.            "fill field catalog for qunatitatve info
  ENDIF.

  IF g_custom_container IS INITIAL.
    CREATE OBJECT g_custom_container
      EXPORTING
        container_name = g_container.     "Creating Container

    CREATE OBJECT grid1
      EXPORTING
        i_parent = g_custom_container.

    "Creating Gird
    IF mode EQ 'CRE'.
      PERFORM create_quant.         "Prepare screen and its input parameters for Quantitative Analysis
    ENDIF.
    PERFORM fcat_fill_quant.        "Bulid field catalog for Qunatitiatve Information

    PERFORM cal_quant.              "Calc. Qunat Info values

    gs_layout-stylefname = 'CELLTAB'.
    gs_layout-no_toolbar = 'X'.

    CALL METHOD grid1->set_table_for_first_display      "Display output
      EXPORTING
        i_structure_name = 'TY_QUANT'
        is_layout        = gs_layout
      CHANGING
        it_outtab        = it_quant[]
        it_fieldcatalog  = lt_fcat[].
  ELSE.
    IF mode = 'CRE' AND lt_fcat[] IS INITIAL.
      PERFORM create_quant.
      PERFORM fcat_fill_quant.

      CALL METHOD grid1->set_table_for_first_display
        EXPORTING
          i_structure_name = 'TY_QUANT'
          is_layout        = gs_layout
        CHANGING
          it_outtab        = it_quant[]
          it_fieldcatalog  = lt_fcat[].
    ENDIF.

    IF sy-ucomm NE ' '.
      PERFORM cal_quant.
      CALL METHOD grid1->refresh_table_display. "refresh grid
    ENDIF.


  ENDIF.

  CLEAR sy-ucomm.

  IF ( mode = 'CRE' OR mode = 'CHA' ) AND sy-ucomm NE 'OPT1'.
    CALL METHOD grid1->set_ready_for_input             "Enable for input
      EXPORTING
        i_ready_for_input = 1.
  ENDIF.

ENDMODULE.

MODULE status_0201 OUTPUT.

  SET PF-STATUS 'STATUS_0201'.
  SET TITLEBAR 'TITLE_0101' WITH ' ' 'Producing Projects'.

  PERFORM clear_list.  "Clear input parameters if input parameters does not match with the corresponding entries in Z Table

ENDMODULE.

MODULE status_0211 OUTPUT.

  IF mode = 'CRE'.
    SET TITLEBAR 'TITLE_0101' WITH 'Create -' 'Producing Projects'.

    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    LOOP AT SCREEN.
      IF screen-name = 'TEXT6'.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

  ELSEIF mode = 'CHA'.
    SET TITLEBAR 'TITLE_0101' WITH 'Change -' 'Producing Projects'.

    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

      wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

  ELSEIF mode = 'DIS'.
    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.
    SET TITLEBAR 'TITLE_0101' WITH 'Display -' 'Producing Projects'.
**********ADDED BY APARNA
  ELSEIF mode = 'APP' OR mode = 'APR'.
    SET TITLEBAR 'TITLE_0101' WITH 'Approve -' 'Producing Projects'.

    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode .

  ELSEIF mode = 'FRE'.
    SET TITLEBAR 'TITLE_0101' WITH 'Freeze -' 'Producing Projects'.

    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

      wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode .
*-----------------------------" Changes begins by Aparna on 31.07.2024 "----------------------------"
     ELSEIF mode = 'APF'.
    SET TITLEBAR 'TITLE_0101' WITH 'Approve by RP -' 'Producing Projects'.

    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode .
*-----------------------------" Changes ended  by Aparna on 31.07.2024 "----------------------------"


  ENDIF.

  IF mode = 'DIS' OR  mode = 'APP ' OR mode = 'FRE'.
    LOOP AT SCREEN.
      IF screen-name = 'CALC'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF stat IS INITIAL.
    LOOP AT SCREEN.
      IF screen-name = 'FRAME2'.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF stat = 'APPROVED'.          "set status
    icon_type = 'ICON_ALLOW'.
    icon_text = 'Approved(FI)'.

 ELSEIF stat = 'APPROVEDFI'.
    icon_type = 'ICON_ALLOW'.
    icon_text = 'Approved(RP)'.


  ELSEIF stat = 'FREEZED'.
    icon_type = 'ICON_LOCKED'.
    icon_text = 'Freezed'.
  ENDIF.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = icon_type
      text                  = icon_text
    IMPORTING
      result                = status
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  IF status IS INITIAL.
    LOOP AT SCREEN.
      IF screen-name = 'TEXT6'.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  g_container = 'SUBSCREEN_0211'.

  IF lt_fcat[] IS INITIAL.
    PERFORM fcat_fill_prof_prd .
  ENDIF.

  IF g_custom_container IS INITIAL.
    CREATE OBJECT g_custom_container
      EXPORTING
        container_name = g_container.

    CREATE OBJECT grid1
      EXPORTING
        i_parent = g_custom_container.

    PERFORM create_prof_prd.     "Create screen layout for producing Project input
    IF mode NE 'CRE'.
      PERFORM change_prof_prd.   "To update the changes in the existing data
    ENDIF.
    PERFORM fcat_fill_prof_prd.  "fill field catalog for producing Project input

    PERFORM calc_0211.           "calc. values for producing Project input

    PERFORM set_for_disp. "deleting first 6 rows from report

    gs_layout-stylefname = 'CELLTAB'.
    gs_layout-no_toolbar = 'X'.
    gs_layout-cwidth_opt = ' '.

    CALL METHOD grid1->set_table_for_first_display
      EXPORTING
        i_structure_name = 'TY_PROF_PRD'
        is_layout        = gs_layout
      CHANGING
        it_outtab        = it_prof_prd2[]
        it_fieldcatalog  = lt_fcat[].
  ELSE.

    IF mode = 'CRE' AND lt_fcat[] IS INITIAL.
      PERFORM create_prof_prd.
      PERFORM fcat_fill_prof_prd .

      PERFORM set_for_disp. "deleting first 6 rows from report

      CALL METHOD grid1->set_table_for_first_display
        EXPORTING
          i_structure_name = 'TY_PROF_PRD'
          is_layout        = gs_layout
        CHANGING
          it_outtab        = it_prof_prd2[]
          it_fieldcatalog  = lt_fcat[].
    ENDIF.
    IF sy-ucomm NE ' '.
      PERFORM calc_0211.
      CALL METHOD grid1->refresh_table_display.
    ENDIF.
  ENDIF.

  IF ( mode = 'CRE' OR mode = 'CHA' ) AND sy-ucomm NE 'OPT1'.
    CALL METHOD grid1->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.
  ENDIF.

ENDMODULE.

MODULE status_0301 OUTPUT.

  SET PF-STATUS 'STATUS_0201'.
  SET TITLEBAR 'TITLE_0101' WITH ' ' 'Other Projects'.

  PERFORM clear_list.

ENDMODULE.

MODULE status_0311 OUTPUT.

  IF mode = 'CRE'.

    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    SET TITLEBAR 'TITLE_0101' WITH 'Create -' 'Other Projects'.

  ELSEIF mode = 'CHA'.

    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    SET TITLEBAR 'TITLE_0101' WITH 'Change -' 'Other Projects'.

  ELSEIF mode = 'DIS'.

    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    SET TITLEBAR 'TITLE_0101' WITH 'Display -' 'Other Projects'.

  ELSEIF mode = 'APP'.

    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.



    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    SET TITLEBAR 'TITLE_0101' WITH 'Display -' 'Other Projects'.

  ELSEIF mode = 'FRE'.

    CLEAR fcode.
    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

     wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    SET TITLEBAR 'TITLE_0101' WITH 'Display -' 'Other Projects'.

*---------------------------" Changes begins by Aparna on 31.07.2024 "----------------------------*

  ELSEIF mode = 'APF'.
    CLEAR fcode.
    wa_fcode = 'FREEZE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'SAVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS_0211' EXCLUDING fcode.

    SET TITLEBAR 'TITLE_0101' WITH 'Display -' 'Other Projects'.

  ENDIF.
*---------------------------" Changes ended by Aparna on 31.07.2024 "----------------------------*
  IF mode = 'DIS' OR  mode = 'APP' OR mode = 'FRE'.
    LOOP AT SCREEN.
      IF screen-name = 'CALC'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF stat IS INITIAL.
    LOOP AT SCREEN.
      IF screen-group1 = 'STA'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF mode NE 'CRE' AND stat IS NOT INITIAL.
    IF stat = 'APPROVED'.
      icon_type = 'ICON_ALLOW'.
      icon_text = 'Approved(FI)'.

   ELSEIF stat = 'APPROVEDFI'.
    icon_type = 'ICON_ALLOW'.
    icon_text = 'Approved(RP)'.


    ELSEIF stat = 'FREEZED'.
      icon_type = 'ICON_LOCKED'.
      icon_text = 'Freezed'.
    ENDIF.

    CLEAR status.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name                  = icon_type
        text                  = icon_text
*       INFO                  = ' '
*       ADD_STDINF            = 'X'
      IMPORTING
        result                = status
      EXCEPTIONS
        icon_not_found        = 1
        outputfield_too_short = 2
        OTHERS                = 3.
  ENDIF.


  g_container = 'SUBSCREEN_0311'.
  IF lt_fcat[] IS NOT INITIAL.
    PERFORM fcat_fill_oth_proj.
  ENDIF.

  IF g_custom_container IS INITIAL.
    CREATE OBJECT g_custom_container
      EXPORTING
        container_name = g_container.
    CREATE OBJECT grid1
      EXPORTING
        i_parent = g_custom_container.

    PERFORM create_oth_proj.
    IF mode NE 'CRE'.
      PERFORM change_oth_proj.
    ENDIF.
    PERFORM fcat_fill_oth_proj.

    PERFORM calc_0311.

    gs_layout-stylefname = 'CELLTAB'.
    gs_layout-no_toolbar = 'X'.
    gs_layout-col_opt = ' '.

    CALL METHOD grid1->set_table_for_first_display
      EXPORTING
        i_structure_name = 'TY_OTH_PROJ'
        is_layout        = gs_layout
      CHANGING
        it_outtab        = it_oth_proj[]
        it_fieldcatalog  = lt_fcat[].

  ELSE.
    IF mode = 'CRE' AND lt_fcat[] IS INITIAL.
      PERFORM change_oth_proj.
      PERFORM fcat_fill_oth_proj.

      CALL METHOD grid1->set_table_for_first_display
        EXPORTING
          i_structure_name = 'TY_OTH_PROJ'
          is_layout        = gs_layout
        CHANGING
          it_outtab        = it_oth_proj[]
          it_fieldcatalog  = lt_fcat[].
    ENDIF.

    IF sy-ucomm NE ' '.
      PERFORM calc_0311.
      CALL METHOD grid1->refresh_table_display.
    ENDIF.
  ENDIF.

  IF mode = 'CRE' OR mode = 'CHA' AND sy-ucomm NE 'OPT1'.
    CALL METHOD grid1->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.
  ENDIF.

ENDMODULE.

MODULE status_0401 OUTPUT.


  IF pnl = 'VAR_PRD'  OR pnl = 'VAR_NON'..
    SET PF-STATUS 'STATUS_PRD'.
  ELSE.
    SET PF-STATUS 'STATUS_0401'.
  ENDIF.
  IF pnl = 'PRD_PROJ'.
    SET TITLEBAR 'TITLE_0000' WITH 'Producing projects report'.
  ELSEIF pnl = 'NON_PRD'.
    SET TITLEBAR 'TITLE_0000' WITH 'Non-Producing projects report'.
  ELSEIF pnl = 'VAR_PRD'.
    SET TITLEBAR  'TITLE_VAR' WITH ' - Producing Projects'.
  ELSEIF pnl = 'VAR_NON'.
    SET TITLEBAR  'TITLE_VAR' WITH '- Other Projects'.
  ELSEIF pnl = 'PER_BAR'.
    SET TITLEBAR 'TITLE_0000' WITH 'Producing projects report per barrel analysis'.
  ELSEIF pnl = 'PRD_QTY'.
    SET TITLEBAR 'TITLE_0000' WITH 'Producing And Quantity Report'.
  ELSEIF pnl = 'REV'.
    SET TITLEBAR 'TITLE_0000' WITH 'Revenue And cost Report'.
  ELSEIF pnl = 'BAR_REP'.
    SET TITLEBAR 'TITLE_0000' WITH 'Per Barrel Analysis Report'.
  ELSEIF pnl = 'AGE_REP'.
    SET TITLEBAR 'TITLE_0000' WITH 'Agenda Report'.
  ENDIF.

  IF pnl = 'VAR_PRD' OR pnl = 'VAR_NON' OR pnl = 'PRD_QTY' OR pnl = 'REV'
       OR pnl = 'BAR_REP' OR pnl = 'AGE_REP'   . " added by Aparna
    LOOP AT SCREEN.
      IF screen-group1 = 'VAR'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0501  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0501 OUTPUT.

  SET PF-STATUS 'STATUS_0401'.
  IF pnl = 'PRO_ANA'.
    SET TITLEBAR 'TITLE_0000' WITH 'Profitability Analysis Report'.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0601  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0601 OUTPUT.

*  SET PF-STATUS 'xxxxxxxx'.
*  SET TITLEBAR 'xxx'.
  SET PF-STATUS 'STATUS_0401'.
  IF r_pqi = 'X'.
    SET TITLEBAR 'TITLE_0000' WITH 'Pending Inputs Report - Quantitative Information'.
  ELSEIF r_ppp = 'X'.
    SET TITLEBAR 'TITLE_0000' WITH 'Pending Inputs Report - Producing Projects'.
  ELSEIF r_pop = 'X'.
    SET TITLEBAR 'TITLE_0000' WITH 'Pending Inputs Report - Other Projects'.
     ELSEIF r_var = 'X'.
    SET TITLEBAR 'TITLE_0000' WITH 'Pending Inputs Report - Variance Analysis Producing Project'.
     ELSEIF r_nvar = 'X'.
    SET TITLEBAR 'TITLE_0000' WITH 'Pending Inputs Report - Variance Analysis Non Producing Project'.
  ENDIF.

ENDMODULE.
