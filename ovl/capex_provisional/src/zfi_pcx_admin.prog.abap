*&---------------------------------------------------------------------*
*& Report         : ZFI_PCX_ADMIN
*& Title          : Provisional Capex - fortnight control (Budgeting)
*& Project        : OVL                             Module: FI
*& Related FS     : SAP_Automation_Provisional_Capex_Process_-V3.xlsx
*& Author         : Arnav Johri                     Date: 20.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Corporate Budgeting's control of the fortnight calendar in table
*&   ZFI_PCX_PERIOD: generate the 24 fortnights of a year, freeze the
*&   open fortnight and open the next one in one step, freeze or reopen
*&   a single fortnight, enter the TTA rate of a fortnight. Every run
*&   ends with the calendar and the number of projects entered.
*&
*& CHANGE HISTORY
*&   20.11.2026  Arnav Johri  <TR>  Initial development
*&   23.11.2026  Arnav Johri  OCDK920554  Screen polish: status icons,
*&               entry completion %, open fortnight highlighted, missing
*&               TTA rate in red, header block, striped rows, frame
*&               titles, default year
*&   24.11.2026  Arnav Johri  OCDK920554  TEMPORARY DEMO_BYPASS of the
*&               ZFI_PCX check for the demo user - REMOVE BEFORE TRANSPORT
*&---------------------------------------------------------------------*
REPORT zfi_pcx_admin.

TYPES: BEGIN OF ty_cnt,
         perno TYPE zfi_pcx_perno,
         cnt   TYPE i,
       END OF ty_cnt.

TYPES: BEGIN OF ty_out,
         stico   TYPE icon_d,                      "Changes by Arnav on 23/11/26
         perno   TYPE zfi_pcx_perno,
         cutoff  TYPE zfi_pcx_cutoff,
         sttxt   TYPE c LENGTH 12,
         ttarate TYPE zfi_pcx_ttarate,
         entered TYPE i,
         active  TYPE i,
*BOC By Arnav on 23/11/26
         pct     TYPE p LENGTH 4 DECIMALS 1,
         t_color TYPE lvc_t_scol,
*EOC By Arnav on 23/11/26
       END OF ty_out.

CONSTANTS: gc_open     TYPE zfi_pcx_status VALUE 'O',
           gc_frozen   TYPE zfi_pcx_status VALUE 'F',
           gc_tab_per  TYPE rstable-tabname VALUE 'ZFI_PCX_PERIOD',
*          ASSUMPTION: authorisation object ZFI_PCX (SU21, manual);
*          activity 70 = Corporate Budgeting. The Business Unit field is
*          not checked here (DUMMY): the calendar is not BU-specific.
           gc_auth_obj TYPE c LENGTH 10 VALUE 'ZFI_PCX',
*BOC By Arnav on 24/11/26
*          gc_act_adm  TYPE c LENGTH 2 VALUE '70'.
           gc_act_adm  TYPE c LENGTH 2 VALUE '70',
*          TEMPORARY DEMO_BYPASS - remove before transport: this user skips
*          the ZFI_PCX check until the PFCG role exists.
           gc_demo_user TYPE syuname VALUE 'SAP_ABAP'.
*EOC By Arnav on 24/11/26

DATA: gt_per TYPE STANDARD TABLE OF zfi_pcx_period WITH DEFAULT KEY,
      gt_out TYPE STANDARD TABLE OF ty_out WITH DEFAULT KEY.

*BOC By Arnav on 23/11/26
*SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME.
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE gv_b01.
*EOC By Arnav on 23/11/26
PARAMETERS: p_gjahr TYPE gjahr OBLIGATORY,
            p_perno TYPE zfi_pcx_perno,
            p_rate  TYPE zfi_pcx_ttarate.
SELECTION-SCREEN END OF BLOCK b01.
*BOC By Arnav on 23/11/26
*SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME.
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE gv_b02.
*EOC By Arnav on 23/11/26
PARAMETERS: r_list RADIOBUTTON GROUP ac DEFAULT 'X',
            r_gen  RADIOBUTTON GROUP ac,
            r_next RADIOBUTTON GROUP ac,
            r_frz  RADIOBUTTON GROUP ac,
            r_open RADIOBUTTON GROUP ac,
            r_rate RADIOBUTTON GROUP ac.
SELECTION-SCREEN END OF BLOCK b02.

*BOC By Arnav on 23/11/26
INITIALIZATION.
  gv_b01 = 'Year and Fortnight'.
  gv_b02 = 'Action'.
* financial year of today (April to March)
  IF sy-datum+4(2) >= '04'.
    p_gjahr = sy-datum(4).
  ELSE.
    p_gjahr = sy-datum(4) - 1.
  ENDIF.
*EOC By Arnav on 23/11/26

AT SELECTION-SCREEN.
  IF r_frz = abap_true OR r_open = abap_true OR r_rate = abap_true.
    IF p_perno < 1 OR p_perno > 24.
      MESSAGE 'Enter a fortnight number between 01 and 24 for this action' TYPE 'E'.
    ENDIF.
  ENDIF.
  IF r_rate = abap_true AND p_rate <= 0.
    MESSAGE 'Enter the TTA rate' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM run.

*&---------------------------------------------------------------------*
*& Form run
*&---------------------------------------------------------------------*
FORM run.
  DATA lv_ok TYPE abap_bool.

  IF r_list = abap_false.
*BOC By Arnav on 24/11/26
*    AUTHORITY-CHECK OBJECT gc_auth_obj
*      ID 'ZPCX_BU' DUMMY
*      ID 'ACTVT'   FIELD gc_act_adm.
*    IF sy-subrc <> 0.
*      MESSAGE 'No authorisation to change the fortnight calendar' TYPE 'S' DISPLAY LIKE 'E'.
*      RETURN.
*    ENDIF.
*   TEMPORARY DEMO_BYPASS - remove before transport
    IF sy-uname <> gc_demo_user.
      AUTHORITY-CHECK OBJECT gc_auth_obj
        ID 'ZPCX_BU' DUMMY
        ID 'ACTVT'   FIELD gc_act_adm.
      IF sy-subrc <> 0.
        MESSAGE 'No authorisation to change the fortnight calendar' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
    ENDIF.
*EOC By Arnav on 24/11/26
    PERFORM lock CHANGING lv_ok.
    IF lv_ok = abap_false.
      RETURN.
    ENDIF.
  ENDIF.

  CASE abap_true.
    WHEN r_gen.
      PERFORM generate.
    WHEN r_next.
      PERFORM read_calendar.
      PERFORM next_fortnight.
    WHEN r_frz.
      PERFORM read_calendar.
      PERFORM set_status USING gc_frozen.
    WHEN r_open.
      PERFORM read_calendar.
      PERFORM set_status USING gc_open.
    WHEN r_rate.
      PERFORM read_calendar.
      PERFORM set_rate.
  ENDCASE.
  CALL FUNCTION 'DEQUEUE_ALL'.

  PERFORM read_calendar.
  PERFORM list.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form lock - one user changes the calendar of a year at a time
*&---------------------------------------------------------------------*
FORM lock CHANGING cv_ok TYPE abap_bool.
  DATA lv_varkey TYPE rstable-varkey.

  cv_ok = abap_false.
  CONCATENATE sy-mandt p_gjahr INTO lv_varkey.
  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING
      mode_rstable   = 'E'
      tabname        = gc_tab_per
      varkey         = lv_varkey
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE |The calendar of { p_gjahr } is being changed by { sy-msgv1 }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  cv_ok = abap_true.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form read_calendar
*&---------------------------------------------------------------------*
FORM read_calendar.
  CLEAR gt_per.
  SELECT * FROM zfi_pcx_period
    WHERE gjahr = @p_gjahr
    ORDER BY PRIMARY KEY
    INTO TABLE @gt_per.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form generate - the 24 fortnights of the year; existing rows stay
*&---------------------------------------------------------------------*
FORM generate.
  DATA: ls_per   TYPE zfi_pcx_period,
        lt_new   TYPE STANDARD TABLE OF zfi_pcx_period WITH DEFAULT KEY,
        lv_i     TYPE i,
        lv_year  TYPE n LENGTH 4,
        lv_month TYPE n LENGTH 2,
        lv_ny    TYPE n LENGTH 4,
        lv_nm    TYPE n LENGTH 2,
        lv_date  TYPE d,
        lv_cnt   TYPE i.

  PERFORM read_calendar.
* ASSUMPTION: the financial year runs April to March, as in the
* workbook; fortnight 01 ends on 15 April of the year entered.
  DO 12 TIMES.
    lv_i = sy-index.
    IF lv_i <= 9.
      lv_year  = p_gjahr.
      lv_month = lv_i + 3.
    ELSE.
      lv_year  = p_gjahr + 1.
      lv_month = lv_i - 9.
    ENDIF.

*   first fortnight: the 15th
    CLEAR ls_per.
    ls_per-mandt = sy-mandt.
    ls_per-gjahr = p_gjahr.
    ls_per-perno = 2 * lv_i - 1.
    CONCATENATE lv_year lv_month '15' INTO lv_date.
    ls_per-cutoff = lv_date.
    READ TABLE gt_per TRANSPORTING NO FIELDS WITH KEY perno = ls_per-perno.
    IF sy-subrc <> 0.
      APPEND ls_per TO lt_new.
    ENDIF.

*   second fortnight: the last day = first day of the next month - 1
    IF lv_month = 12.
      lv_ny = lv_year + 1.
      lv_nm = 1.
    ELSE.
      lv_ny = lv_year.
      lv_nm = lv_month + 1.
    ENDIF.
    CONCATENATE lv_ny lv_nm '01' INTO lv_date.
    lv_date = lv_date - 1.
    CLEAR ls_per.
    ls_per-mandt  = sy-mandt.
    ls_per-gjahr  = p_gjahr.
    ls_per-perno  = 2 * lv_i.
    ls_per-cutoff = lv_date.
    READ TABLE gt_per TRANSPORTING NO FIELDS WITH KEY perno = ls_per-perno.
    IF sy-subrc <> 0.
      APPEND ls_per TO lt_new.
    ENDIF.
  ENDDO.

  IF lt_new IS INITIAL.
    MESSAGE |The calendar of { p_gjahr } already has all 24 fortnights| TYPE 'S'.
    RETURN.
  ENDIF.
  INSERT zfi_pcx_period FROM TABLE lt_new ACCEPTING DUPLICATE KEYS.
  COMMIT WORK.
  lv_cnt = lines( lt_new ).
  MESSAGE |{ lv_cnt } fortnight(s) created for { p_gjahr }; none is open yet| TYPE 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form next_fortnight - freeze what is open, open the one after it
*&---------------------------------------------------------------------*
FORM next_fortnight.
  DATA: lv_last  TYPE i,
        lv_next  TYPE i,
        lv_nextn TYPE zfi_pcx_perno,
        lv_lastn TYPE zfi_pcx_perno,
        lv_act   TYPE i,
        lv_ent   TYPE i,
        lv_miss  TYPE i,
        lv_text  TYPE c LENGTH 200,
        lv_ans   TYPE c LENGTH 1.
  FIELD-SYMBOLS <ls_per> TYPE zfi_pcx_period.

  IF gt_per IS INITIAL.
    MESSAGE 'Generate the calendar of the year first' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  LOOP AT gt_per ASSIGNING <ls_per> WHERE status = gc_open.
    lv_last = <ls_per>-perno.
  ENDLOOP.
  IF lv_last > 0.
    lv_next = lv_last + 1.
  ELSE.
*   nothing open: the first fortnight that is not frozen
    LOOP AT gt_per ASSIGNING <ls_per> WHERE status <> gc_frozen.
      lv_next = <ls_per>-perno.
      EXIT.
    ENDLOOP.
  ENDIF.
  IF lv_last = 0 AND lv_next = 0.
    MESSAGE 'All fortnights of the year are frozen' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.
  lv_lastn = lv_last.
  lv_nextn = lv_next.

  IF lv_last > 0.
*   tell Budgeting how many projects have nothing entered yet
    SELECT COUNT(*) FROM zfi_pcx_proj
      WHERE active = @abap_true
      INTO @lv_act.
    SELECT COUNT(*) FROM zfi_pcx_capex
      WHERE gjahr = @p_gjahr
        AND perno = @lv_lastn
      INTO @lv_ent.
    lv_miss = lv_act - lv_ent.
    IF lv_miss < 0.
      lv_miss = 0.
    ENDIF.
    IF lv_next <= 24.
      lv_text = |Freeze fortnight { lv_lastn } and open { lv_nextn }? { lv_miss } of { lv_act }| &&
                | projects have no entry in { lv_lastn }; their prior figure is carried forward.|.
    ELSE.
      lv_text = |Freeze fortnight { lv_lastn }, the last of the year? { lv_miss } of { lv_act }| &&
                | projects have no entry; their prior figure is carried forward.|.
    ENDIF.
  ELSE.
    lv_text = |Open fortnight { lv_nextn } for entry?|.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Provisional Capex'
      text_question         = lv_text
      display_cancel_button = space
    IMPORTING
      answer                = lv_ans
    EXCEPTIONS
      OTHERS                = 1.
  IF sy-subrc <> 0 OR lv_ans <> '1'.
    MESSAGE 'Nothing changed' TYPE 'S'.
    RETURN.
  ENDIF.

  LOOP AT gt_per ASSIGNING <ls_per>.
    IF <ls_per>-status = gc_open.
      <ls_per>-status = gc_frozen.
    ELSEIF <ls_per>-perno = lv_nextn.
      <ls_per>-status = gc_open.
    ENDIF.
  ENDLOOP.
  UPDATE zfi_pcx_period FROM TABLE gt_per.
  COMMIT WORK.
  MESSAGE 'Fortnight status changed' TYPE 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_status - freeze or reopen the fortnight on the screen
*&---------------------------------------------------------------------*
FORM set_status USING iv_status TYPE zfi_pcx_status.
  FIELD-SYMBOLS <ls_per> TYPE zfi_pcx_period.

  IF iv_status = gc_open.
*   one fortnight is open at a time
    LOOP AT gt_per ASSIGNING <ls_per> WHERE status = gc_open AND perno <> p_perno.
      MESSAGE |Fortnight { <ls_per>-perno } is open; freeze it first| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDLOOP.
  ENDIF.
  READ TABLE gt_per ASSIGNING <ls_per> WITH KEY perno = p_perno.
  IF sy-subrc <> 0.
    MESSAGE 'Fortnight is not in the calendar; generate the calendar first' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  <ls_per>-status = iv_status.
  UPDATE zfi_pcx_period FROM <ls_per>.
  COMMIT WORK.
  MESSAGE |Status of fortnight { p_perno } changed| TYPE 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_rate - TTA rate of the fortnight on the screen
*&---------------------------------------------------------------------*
FORM set_rate.
  FIELD-SYMBOLS <ls_per> TYPE zfi_pcx_period.

  READ TABLE gt_per ASSIGNING <ls_per> WITH KEY perno = p_perno.
  IF sy-subrc <> 0.
    MESSAGE 'Fortnight is not in the calendar; generate the calendar first' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  <ls_per>-ttarate = p_rate.
  UPDATE zfi_pcx_period FROM <ls_per>.
  COMMIT WORK.
  MESSAGE |TTA rate of fortnight { p_perno } saved| TYPE 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_text - column heading
*&---------------------------------------------------------------------*
FORM set_text USING io_cols TYPE REF TO cl_salv_columns_table iv_name TYPE clike iv_text TYPE clike
              RAISING cx_salv_not_found.
  DATA: lo_col  TYPE REF TO cl_salv_column,
        lv_name TYPE lvc_fname,
        lv_s    TYPE scrtext_s,
        lv_m    TYPE scrtext_m,
        lv_l    TYPE scrtext_l.

  lv_name = iv_name.
  lv_s    = iv_text.
  lv_m    = iv_text.
  lv_l    = iv_text.
  lo_col  = io_cols->get_column( lv_name ).
  lo_col->set_short_text( lv_s ).
  lo_col->set_medium_text( lv_m ).
  lo_col->set_long_text( lv_l ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form list - the calendar with the number of projects entered
*&---------------------------------------------------------------------*
FORM list.
  DATA: lt_cnt  TYPE STANDARD TABLE OF ty_cnt WITH DEFAULT KEY,
        ls_cnt  TYPE ty_cnt,
        ls_per  TYPE zfi_pcx_period,
        ls_out  TYPE ty_out,
        lv_act  TYPE i,
        lv_head TYPE lvc_title,
        lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table,
        lo_col  TYPE REF TO cl_salv_column_table,   "Changes by Arnav on 23/11/26
        lx_msg  TYPE REF TO cx_salv_msg,
        lx_nf   TYPE REF TO cx_salv_not_found,
        lv_err  TYPE string.

  CLEAR gt_out.
  IF gt_per IS INITIAL.
    MESSAGE |No calendar for { p_gjahr } yet; run "Generate the 24 fortnights"| TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.
  SELECT perno, COUNT(*) AS cnt
    FROM zfi_pcx_capex
    WHERE gjahr = @p_gjahr
    GROUP BY perno
    ORDER BY perno
    INTO TABLE @lt_cnt.
  SELECT COUNT(*) FROM zfi_pcx_proj
    WHERE active = @abap_true
    INTO @lv_act.

  LOOP AT gt_per INTO ls_per.
    CLEAR: ls_out, ls_cnt.
    ls_out-perno   = ls_per-perno.
    ls_out-cutoff  = ls_per-cutoff.
    ls_out-ttarate = ls_per-ttarate.
    ls_out-active  = lv_act.
    CASE ls_per-status.
      WHEN gc_open.
        ls_out-sttxt = 'Open'.
      WHEN gc_frozen.
        ls_out-sttxt = 'Frozen'.
      WHEN OTHERS.
        ls_out-sttxt = 'Not yet open'.
    ENDCASE.
    READ TABLE lt_cnt INTO ls_cnt WITH KEY perno = ls_per-perno.
    IF sy-subrc = 0.
      ls_out-entered = ls_cnt-cnt.
    ENDIF.
    PERFORM decorate USING ls_per CHANGING ls_out.  "Changes by Arnav on 23/11/26
    APPEND ls_out TO gt_out.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_out ).
      lo_cols = lo_alv->get_columns( ).
      PERFORM set_text USING lo_cols 'PERNO'   'Fortnight'.
      PERFORM set_text USING lo_cols 'CUTOFF'  'Cutoff Date'.
      PERFORM set_text USING lo_cols 'STTXT'   'Status'.
      PERFORM set_text USING lo_cols 'TTARATE' 'TTA Rate (INR/USD)'.
      PERFORM set_text USING lo_cols 'ENTERED' 'Projects Entered'.
      PERFORM set_text USING lo_cols 'ACTIVE'  'Active Projects'.
      lo_cols->set_optimize( abap_true ).
*BOC By Arnav on 23/11/26
      PERFORM set_text USING lo_cols 'STICO' 'Status'.
      PERFORM set_text USING lo_cols 'PCT'   'Entry Completion %'.
      lo_col ?= lo_cols->get_column( 'STICO' ).
      lo_col->set_icon( abap_true ).
      lo_col->set_key( abap_true ).
      lo_col->set_alignment( if_salv_c_alignment=>centered ).
      lo_col ?= lo_cols->get_column( 'PERNO' ).
      lo_col->set_key( abap_true ).
      lo_col ?= lo_cols->get_column( 'STTXT' ).
      lo_col->set_key( abap_true ).
      TRY.
          lo_cols->set_color_column( 'T_COLOR' ).
        CATCH cx_salv_data_error.
*         plain rows
      ENDTRY.
      lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
      PERFORM top_of_list USING lo_alv lv_act.
*EOC By Arnav on 23/11/26
      lo_alv->get_functions( )->set_all( abap_true ).
      lv_head = |Provisional Capex - fortnight calendar { p_gjahr }|.
      lo_alv->get_display_settings( )->set_list_header( lv_head ).
      lo_alv->display( ).
    CATCH cx_salv_msg INTO lx_msg.
      lv_err = lx_msg->get_text( ).
      MESSAGE lv_err TYPE 'S' DISPLAY LIKE 'E'.
    CATCH cx_salv_not_found INTO lx_nf.
      lv_err = lx_nf->get_text( ).
      MESSAGE lv_err TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
ENDFORM.

*BOC By Arnav on 23/11/26
*&---------------------------------------------------------------------*
*& Form decorate - status icon, completion %, colours of one fortnight
*&---------------------------------------------------------------------*
FORM decorate USING is_per TYPE zfi_pcx_period CHANGING cs_out TYPE ty_out.
  DATA ls_scol TYPE lvc_s_scol.

  CLEAR cs_out-t_color.
  CASE is_per-status.
    WHEN gc_open.
      cs_out-stico = icon_led_green.
*     the open fortnight: green, the whole line
      ls_scol-color-col = 5.
      APPEND ls_scol TO cs_out-t_color.
    WHEN gc_frozen.
      cs_out-stico = icon_locked.
    WHEN OTHERS.
      cs_out-stico = icon_led_inactive.
  ENDCASE.
  IF cs_out-active > 0.
    cs_out-pct = cs_out-entered * 100 / cs_out-active.
  ENDIF.
* a fortnight that is or was open needs its TTA rate for the INR reports
  IF is_per-status IS NOT INITIAL AND cs_out-ttarate IS INITIAL.
    CLEAR ls_scol.
    ls_scol-fname     = 'TTARATE'.
    ls_scol-color-col = 6.
    APPEND ls_scol TO cs_out-t_color.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form top_of_list - header block above the calendar (screen and print)
*&---------------------------------------------------------------------*
FORM top_of_list USING io_alv TYPE REF TO cl_salv_table iv_act TYPE i.
  DATA: lo_grid TYPE REF TO cl_salv_form_layout_grid,
        ls_per  TYPE zfi_pcx_period,
        lv_text TYPE string,
        lv_fy2  TYPE n LENGTH 2,
        lv_frz  TYPE i.

  lv_text = 'none'.
  LOOP AT gt_per INTO ls_per.
    IF ls_per-status = gc_open.
      lv_text = |{ ls_per-perno } (cutoff { ls_per-cutoff DATE = USER })|.
    ELSEIF ls_per-status = gc_frozen.
      lv_frz = lv_frz + 1.
    ENDIF.
  ENDLOOP.

  CREATE OBJECT lo_grid.
  lv_fy2 = ( p_gjahr + 1 ) MOD 100.
  lo_grid->create_header_information( row = 1 column = 1
                                      text = 'Provisional Capex - fortnight calendar' ).
  lo_grid->create_label( row = 2 column = 1 text = 'Financial year:' ).
  lo_grid->create_text( row = 2 column = 2 text = |{ p_gjahr }-{ lv_fy2 }| ).
  lo_grid->create_label( row = 3 column = 1 text = 'Open fortnight:' ).
  lo_grid->create_text( row = 3 column = 2 text = lv_text ).
  lo_grid->create_label( row = 4 column = 1 text = 'Frozen:' ).
  lo_grid->create_text( row = 4 column = 2 text = |{ lv_frz } of 24| ).
  lo_grid->create_label( row = 5 column = 1 text = 'Active projects:' ).
  lo_grid->create_text( row = 5 column = 2 text = |{ iv_act }| ).
  io_alv->set_top_of_list( lo_grid ).
  io_alv->set_top_of_list_print( lo_grid ).
ENDFORM.
*EOC By Arnav on 23/11/26
