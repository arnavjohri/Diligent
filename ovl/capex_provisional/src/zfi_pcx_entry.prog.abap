*&---------------------------------------------------------------------*
*& Report         : ZFI_PCX_ENTRY
*& Title          : Provisional Capex - fortnightly entry by Business Unit
*& Project        : OVL                             Module: FI
*& Related FS     : SAP_Automation_Provisional_Capex_Process_-V3.xlsx
*& Author         : Arnav Johri                     Date: 20.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   The Business Unit enters the cumulative Capex of each project per
*&   category (EWIP, DWIP, CWIP, Other) for one fortnight, in USD
*&   million. The prior reported figures are pre-filled. A total below
*&   the prior reported total is refused. Colours: grey-blue = frozen,
*&   yellow = pre-filled, green = entered in this fortnight.
*&   No screen and no GUI status: the grid sits on the default screen
*&   and Save is a button in the grid toolbar.
*&
*& CHANGE HISTORY
*&   20.11.2026  Arnav Johri  <TR>  Initial development
*&   23.11.2026  Arnav Johri  OCDK920554  Screen polish: header pane
*&               with KPIs and colour legend, status icons, zebra,
*&               fixed key columns, tooltips, frame titles, defaults
*&               for year and open fortnight
*&   24.11.2026  Arnav Johri  OCDK920554  TEMPORARY DEMO_BYPASS of the
*&               ZFI_PCX check for the demo user - REMOVE BEFORE TRANSPORT
*&---------------------------------------------------------------------*
REPORT zfi_pcx_entry.

TYPES ty_amt TYPE p LENGTH 8 DECIMALS 2.

TYPES: BEGIN OF ty_row,
         projid  TYPE zfi_pcx_projid,
         projnm  TYPE zfi_pcx_projnm,
         bu      TYPE zfi_pcx_bu,
         jvtxt   TYPE zfi_pcx_jvtxt,
         prior   TYPE ty_amt,
         ewip    TYPE zfi_pcx_ewip,
         dwip    TYPE zfi_pcx_dwip,
         cwip    TYPE zfi_pcx_cwip,
         othcap  TYPE zfi_pcx_othcap,
         total   TYPE ty_amt,
         incr    TYPE ty_amt,
         state   TYPE c LENGTH 12,
         stico   TYPE icon_d,                     "Changes by Arnav on 23/11/26
         aenam   TYPE aenam,
         aedat   TYPE aedat,
*        last accepted values of the four entry cells
         o_ewip  TYPE ty_amt,
         o_dwip  TYPE ty_amt,
         o_cwip  TYPE ty_amt,
         o_oth   TYPE ty_amt,
*        category values of the prior reported fortnight
         p_ewip  TYPE ty_amt,
         p_dwip  TYPE ty_amt,
         p_cwip  TYPE ty_amt,
         p_oth   TYPE ty_amt,
*        total of the next later fortnight already saved, if any
         nxttot  TYPE ty_amt,
         has_nxt TYPE abap_bool,
         saved   TYPE abap_bool,
         dirty   TYPE abap_bool,
         coltab  TYPE lvc_t_scol,
       END OF ty_row.

CONSTANTS: gc_tab_capex TYPE rstable-tabname VALUE 'ZFI_PCX_CAPEX',
           gc_fc_save   TYPE ui_func VALUE 'ZSAVE',
           gc_open      TYPE zfi_pcx_status VALUE 'O',
           gc_frozen    TYPE zfi_pcx_status VALUE 'F',
*          ASSUMPTION: authorisation object ZFI_PCX (SU21, manual) with
*          fields ZPCX_BU and ACTVT: 02 enter, 03 display, 70 correct a
*          frozen fortnight (Corporate Budgeting).
           gc_auth_obj  TYPE c LENGTH 10 VALUE 'ZFI_PCX',
           gc_act_chg   TYPE c LENGTH 2 VALUE '02',
           gc_act_dis   TYPE c LENGTH 2 VALUE '03',
           gc_act_adm   TYPE c LENGTH 2 VALUE '70',
*BOC By Arnav on 24/11/26
*          TEMPORARY DEMO_BYPASS - remove before transport: this user skips
*          the ZFI_PCX check until the PFCG role exists.
           gc_demo_user TYPE syuname VALUE 'SAP_ABAP',
*          list user command that builds the grid once the list is up
           gc_fc_hdr    TYPE syucomm VALUE 'ZHDR',
*EOC By Arnav on 24/11/26
           gc_col_frz   TYPE i VALUE 1,
           gc_col_pre   TYPE i VALUE 3,
           gc_col_pun   TYPE i VALUE 5.

DATA: gs_proj TYPE zfi_pcx_proj,
      gs_per  TYPE zfi_pcx_period,
      gt_row  TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY,
      gv_edit TYPE abap_bool,
      gv_adm  TYPE abap_bool,
      go_grid TYPE REF TO cl_gui_alv_grid.
*BOC By Arnav on 23/11/26
* header pane above the grid
DATA: go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_body   TYPE REF TO cl_gui_container,
      go_doc    TYPE REF TO cl_dd_document,
      gv_doc_on TYPE abap_bool.
*EOC By Arnav on 23/11/26

*BOC By Arnav on 23/11/26
*SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME.
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE gv_b01.
*EOC By Arnav on 23/11/26
PARAMETERS: p_gjahr TYPE gjahr OBLIGATORY,
            p_perno TYPE zfi_pcx_perno OBLIGATORY.
SELECT-OPTIONS: s_bu   FOR gs_proj-bu,
                s_proj FOR gs_proj-projid.
SELECTION-SCREEN END OF BLOCK b01.
*BOC By Arnav on 23/11/26
*SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME.
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE gv_b02.
*EOC By Arnav on 23/11/26
PARAMETERS: p_disp AS CHECKBOX,
            p_adm  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
CLASS lcl_evt DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS:
      on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object,
      on_ucomm FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
      on_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
        IMPORTING e_modified et_good_cells.
ENDCLASS.

DATA go_evt TYPE REF TO lcl_evt.

*BOC By Arnav on 23/11/26
*----------------------------------------------------------------------*
INITIALIZATION.
  gv_b01 = 'Fortnight and Projects'.
  gv_b02 = 'Mode'.
  PERFORM set_defaults.
*EOC By Arnav on 23/11/26

*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF p_perno < 1 OR p_perno > 24.
    MESSAGE 'Fortnight number must be between 01 and 24' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM run.

*BOC By Arnav on 24/11/26
* ZHDR comes from SET USER-COMMAND in FORM run: the list screen is current
* now, so the grid and the header pane are created on it. Nothing may be
* written here - a WRITE would open a detail list.
AT USER-COMMAND.
  IF sy-ucomm = gc_fc_hdr.
    PERFORM display.
  ENDIF.
*EOC By Arnav on 24/11/26

*----------------------------------------------------------------------*
CLASS lcl_evt IMPLEMENTATION.
  METHOD on_toolbar.
    DATA ls_btn TYPE stb_button.
    IF gv_edit = abap_false.
      RETURN.
    ENDIF.
    ls_btn-butn_type = 3.
    APPEND ls_btn TO e_object->mt_toolbar.
    CLEAR ls_btn.
    ls_btn-function  = gc_fc_save.
    ls_btn-icon      = icon_system_save.
    ls_btn-text      = 'Save'.
    ls_btn-quickinfo = 'Save the entered Capex'.
    APPEND ls_btn TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_ucomm.
    IF e_ucomm = gc_fc_save.
      PERFORM save.
    ENDIF.
  ENDMETHOD.

  METHOD on_finished.
    DATA: ls_cell TYPE lvc_s_modi,
          lt_idx  TYPE SORTED TABLE OF i WITH UNIQUE KEY table_line,
          lv_idx  TYPE i,
          lv_msg  TYPE string.
    FIELD-SYMBOLS <ls_row> TYPE ty_row.

    IF e_modified = abap_false.
      RETURN.
    ENDIF.
    LOOP AT et_good_cells INTO ls_cell.
      INSERT ls_cell-row_id INTO TABLE lt_idx.
    ENDLOOP.
    LOOP AT lt_idx INTO lv_idx.
      READ TABLE gt_row ASSIGNING <ls_row> INDEX lv_idx.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      PERFORM check_row USING <ls_row> CHANGING lv_msg.
      IF lv_msg IS NOT INITIAL.
*       refused: back to the last accepted values
        <ls_row>-ewip   = <ls_row>-o_ewip.
        <ls_row>-dwip   = <ls_row>-o_dwip.
        <ls_row>-cwip   = <ls_row>-o_cwip.
        <ls_row>-othcap = <ls_row>-o_oth.
        MESSAGE lv_msg TYPE 'I' DISPLAY LIKE 'E'.
      ELSE.
        <ls_row>-o_ewip = <ls_row>-ewip.
        <ls_row>-o_dwip = <ls_row>-dwip.
        <ls_row>-o_cwip = <ls_row>-cwip.
        <ls_row>-o_oth  = <ls_row>-othcap.
        <ls_row>-dirty  = abap_true.
      ENDIF.
      PERFORM derive_row CHANGING <ls_row>.
    ENDLOOP.
    PERFORM refresh.
    PERFORM header.                               "Changes by Arnav on 23/11/26
  ENDMETHOD.
ENDCLASS.

*BOC By Arnav on 23/11/26
*&---------------------------------------------------------------------*
*& Form set_defaults - financial year of today (April to March) and the
*& fortnight that is open for entry; without an open one, today's
*&---------------------------------------------------------------------*
FORM set_defaults.
  DATA: lt_open  TYPE STANDARD TABLE OF zfi_pcx_perno WITH DEFAULT KEY,
        lv_month TYPE i.

  lv_month = sy-datum+4(2).
  IF lv_month >= 4.
    p_gjahr = sy-datum(4).
  ELSE.
    p_gjahr = sy-datum(4) - 1.
  ENDIF.
  SELECT perno FROM zfi_pcx_period
    WHERE gjahr  = @p_gjahr
      AND status = @gc_open
    ORDER BY perno
    INTO TABLE @lt_open
    UP TO 1 ROWS.
  READ TABLE lt_open INTO p_perno INDEX 1.
  IF sy-subrc <> 0.
    lv_month = lv_month - 3.
    IF lv_month <= 0.
      lv_month = lv_month + 12.
    ENDIF.
    p_perno = 2 * lv_month - 1.
    IF sy-datum+6(2) > '15'.
      p_perno = p_perno + 1.
    ENDIF.
  ENDIF.
ENDFORM.
*EOC By Arnav on 23/11/26

*&---------------------------------------------------------------------*
*& Form run
*&---------------------------------------------------------------------*
FORM run.
  DATA lv_ok TYPE abap_bool.

  CLEAR: gt_row, gv_edit, gv_adm, gs_per.
  CALL FUNCTION 'DEQUEUE_ALL'.
  IF go_grid IS BOUND.
    go_grid->free( ).
    CLEAR go_grid.
  ENDIF.
*BOC By Arnav on 23/11/26
  IF go_split IS BOUND.
    go_split->free( ).
    CLEAR: go_split, go_top, go_body, go_doc, gv_doc_on.
  ENDIF.
*EOC By Arnav on 23/11/26

  SELECT SINGLE * FROM zfi_pcx_period
    WHERE gjahr = @p_gjahr
      AND perno = @p_perno
    INTO @gs_per.
  IF sy-subrc <> 0.
    MESSAGE 'Fortnight is not in the calendar (table ZFI_PCX_PERIOD)' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

* what this run may do
  IF p_disp = abap_false.
    IF gs_per-status = gc_open.
      gv_edit = abap_true.
    ELSEIF gs_per-status = gc_frozen AND p_adm = abap_true.
      gv_edit = abap_true.
      gv_adm  = abap_true.
    ENDIF.
  ENDIF.

  PERFORM read_projects CHANGING lv_ok.
  IF lv_ok = abap_false.
    RETURN.
  ENDIF.
  PERFORM read_amounts.
  IF gv_edit = abap_true.
    PERFORM lock_rows.
    IF gt_row IS INITIAL.
      MESSAGE 'All selected projects are being edited by another user' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ELSEIF p_disp = abap_false.
    IF gs_per-status = gc_frozen.
      MESSAGE 'Fortnight is frozen - display only' TYPE 'S' DISPLAY LIKE 'W'.
    ELSE.
      MESSAGE 'Fortnight is not open for entry - display only' TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDIF.
*BOC By Arnav on 24/11/26
*  PERFORM display.
* GUI controls attach to the screen that is current when they are created.
* Created here (START-OF-SELECTION) they went to the selection screen and the
* list came up empty (OCD, 24/11/26). The list is opened first; ZHDR then
* builds the grid from AT USER-COMMAND, when the list screen is current.
  WRITE space.
  SET USER-COMMAND gc_fc_hdr.
*EOC By Arnav on 24/11/26
ENDFORM.

*&---------------------------------------------------------------------*
*& Form read_projects
*&---------------------------------------------------------------------*
FORM read_projects CHANGING cv_ok TYPE abap_bool.
  DATA: lt_proj TYPE STANDARD TABLE OF zfi_pcx_proj WITH DEFAULT KEY,
        ls_proj TYPE zfi_pcx_proj,
        ls_row  TYPE ty_row,
        lv_act  TYPE c LENGTH 2,
        lv_auth TYPE abap_bool,
        lv_skip TYPE i.

  cv_ok = abap_false.
  SELECT * FROM zfi_pcx_proj
    WHERE projid IN @s_proj
      AND bu     IN @s_bu
      AND active = @abap_true
    ORDER BY PRIMARY KEY
    INTO TABLE @lt_proj.
  IF lt_proj IS INITIAL.
    MESSAGE 'No active project found for the given selection' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.
  SORT lt_proj BY sortno projid.

  IF gv_adm = abap_true.
    lv_act = gc_act_adm.
  ELSEIF gv_edit = abap_true.
    lv_act = gc_act_chg.
  ELSE.
    lv_act = gc_act_dis.
  ENDIF.
  LOOP AT lt_proj INTO ls_proj.
    PERFORM check_auth USING ls_proj-bu lv_act CHANGING lv_auth.
    IF lv_auth = abap_false.
      lv_skip = lv_skip + 1.
      CONTINUE.
    ENDIF.
    CLEAR ls_row.
    ls_row-projid = ls_proj-projid.
    ls_row-projnm = ls_proj-projnm.
    ls_row-bu     = ls_proj-bu.
    ls_row-jvtxt  = ls_proj-jvtxt.
    APPEND ls_row TO gt_row.
  ENDLOOP.
  IF gt_row IS INITIAL.
    MESSAGE 'No authorisation for the Business Units of the selected projects' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  IF lv_skip > 0.
    MESSAGE |{ lv_skip } project(s) left out: no authorisation for their Business Unit| TYPE 'S'.
  ENDIF.
  cv_ok = abap_true.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form check_auth
*&---------------------------------------------------------------------*
FORM check_auth USING iv_bu TYPE zfi_pcx_bu iv_act TYPE clike CHANGING cv_ok TYPE abap_bool.
*BOC By Arnav on 24/11/26
* TEMPORARY DEMO_BYPASS - remove before transport
  IF sy-uname = gc_demo_user.
    cv_ok = abap_true.
    RETURN.
  ENDIF.
*EOC By Arnav on 24/11/26
  AUTHORITY-CHECK OBJECT gc_auth_obj
    ID 'ZPCX_BU' FIELD iv_bu
    ID 'ACTVT'   FIELD iv_act.
  IF sy-subrc = 0.
    cv_ok = abap_true.
  ELSE.
    cv_ok = abap_false.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form read_amounts
*& prior = latest fortnight before the selected one that has a row;
*& current = row of the selected fortnight; next = first later row.
*&---------------------------------------------------------------------*
FORM read_amounts.
  DATA: lt_cap TYPE STANDARD TABLE OF zfi_pcx_capex WITH DEFAULT KEY,
        ls_cap TYPE zfi_pcx_capex.
  FIELD-SYMBOLS <ls_row> TYPE ty_row.

* the year's rows come back sorted by fortnight (primary key)
  SELECT * FROM zfi_pcx_capex
    WHERE gjahr  = @p_gjahr
      AND projid IN @s_proj
    ORDER BY PRIMARY KEY
    INTO TABLE @lt_cap.

  LOOP AT lt_cap INTO ls_cap.
    READ TABLE gt_row ASSIGNING <ls_row> WITH KEY projid = ls_cap-projid.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    IF ls_cap-perno < p_perno.
      <ls_row>-p_ewip = ls_cap-ewip.
      <ls_row>-p_dwip = ls_cap-dwip.
      <ls_row>-p_cwip = ls_cap-cwip.
      <ls_row>-p_oth  = ls_cap-othcap.
    ELSEIF ls_cap-perno = p_perno.
      <ls_row>-ewip   = ls_cap-ewip.
      <ls_row>-dwip   = ls_cap-dwip.
      <ls_row>-cwip   = ls_cap-cwip.
      <ls_row>-othcap = ls_cap-othcap.
      <ls_row>-aenam  = ls_cap-aenam.
      <ls_row>-aedat  = ls_cap-aedat.
      <ls_row>-saved  = abap_true.
    ELSEIF <ls_row>-has_nxt = abap_false.
      <ls_row>-nxttot  = ls_cap-ewip + ls_cap-dwip + ls_cap-cwip + ls_cap-othcap.
      <ls_row>-has_nxt = abap_true.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_row ASSIGNING <ls_row>.
    <ls_row>-prior = <ls_row>-p_ewip + <ls_row>-p_dwip + <ls_row>-p_cwip + <ls_row>-p_oth.
    IF <ls_row>-saved = abap_false.
*     nothing punched yet in this fortnight: show the prior reported figures
      <ls_row>-ewip   = <ls_row>-p_ewip.
      <ls_row>-dwip   = <ls_row>-p_dwip.
      <ls_row>-cwip   = <ls_row>-p_cwip.
      <ls_row>-othcap = <ls_row>-p_oth.
    ENDIF.
    <ls_row>-o_ewip = <ls_row>-ewip.
    <ls_row>-o_dwip = <ls_row>-dwip.
    <ls_row>-o_cwip = <ls_row>-cwip.
    <ls_row>-o_oth  = <ls_row>-othcap.
    PERFORM derive_row CHANGING <ls_row>.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form lock_rows - one user per project and fortnight
*&---------------------------------------------------------------------*
FORM lock_rows.
  DATA: lv_varkey TYPE rstable-varkey,
        lv_locked TYPE i,
        lv_user   TYPE sy-msgv1.
  FIELD-SYMBOLS <ls_row> TYPE ty_row.

  LOOP AT gt_row ASSIGNING <ls_row>.
    CONCATENATE sy-mandt p_gjahr p_perno <ls_row>-projid INTO lv_varkey.
    CALL FUNCTION 'ENQUEUE_E_TABLE'
      EXPORTING
        mode_rstable   = 'E'
        tabname        = gc_tab_capex
        varkey         = lv_varkey
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      lv_user   = sy-msgv1.
      lv_locked = lv_locked + 1.
      DELETE gt_row.
    ENDIF.
  ENDLOOP.
  IF lv_locked > 0.
    MESSAGE |{ lv_locked } project(s) left out: being edited by { lv_user }| TYPE 'I'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form check_row - the rules of the FS; cv_msg stays empty when valid
*&---------------------------------------------------------------------*
FORM check_row USING is_row TYPE ty_row CHANGING cv_msg TYPE string.
  DATA lv_total TYPE ty_amt.

  CLEAR cv_msg.
  IF is_row-ewip < 0 OR is_row-dwip < 0 OR is_row-cwip < 0 OR is_row-othcap < 0.
    cv_msg = |{ is_row-projnm }: negative amounts are not allowed|.
    RETURN.
  ENDIF.
  lv_total = is_row-ewip + is_row-dwip + is_row-cwip + is_row-othcap.
  IF lv_total < is_row-prior.
    cv_msg = |{ is_row-projnm }: cumulative Capex { lv_total } is below the prior reported { is_row-prior }|.
    RETURN.
  ENDIF.
  IF is_row-has_nxt = abap_true AND lv_total > is_row-nxttot.
    cv_msg = |{ is_row-projnm }: cumulative Capex { lv_total } is above the next fortnight's { is_row-nxttot }|.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form derive_row - total, increase, state and cell colours
*&---------------------------------------------------------------------*
FORM derive_row CHANGING cs_row TYPE ty_row.
  DATA: ls_col  TYPE lvc_s_scol,
        lv_base TYPE i.

  cs_row-total = cs_row-ewip + cs_row-dwip + cs_row-cwip + cs_row-othcap.
  cs_row-incr  = cs_row-total - cs_row-prior.
  CLEAR cs_row-coltab.

  ls_col-fname     = 'PRIOR'.
  ls_col-color-col = gc_col_frz.
  APPEND ls_col TO cs_row-coltab.

*BOC By Arnav on 23/11/26
*  IF gs_per-status = gc_frozen AND gv_adm = abap_false.
*    cs_row-state = 'Frozen'.
*    lv_base      = gc_col_frz.
*  ELSEIF cs_row-saved = abap_true OR cs_row-dirty = abap_true.
*    cs_row-state = 'Entered'.
*    lv_base      = gc_col_pun.
*  ELSE.
*    cs_row-state = 'Pre-filled'.
*    lv_base      = gc_col_pre.
*  ENDIF.
  IF gs_per-status = gc_frozen AND gv_adm = abap_false.
    cs_row-state = 'Frozen'.
    cs_row-stico = icon_locked.
    lv_base      = gc_col_frz.
  ELSEIF cs_row-dirty = abap_true.
    cs_row-state = 'Not saved'.
    cs_row-stico = icon_change.
    lv_base      = gc_col_pun.
  ELSEIF cs_row-saved = abap_true.
    cs_row-state = 'Entered'.
    cs_row-stico = icon_led_green.
    lv_base      = gc_col_pun.
  ELSE.
    cs_row-state = 'Pre-filled'.
    cs_row-stico = icon_led_yellow.
    lv_base      = gc_col_pre.
  ENDIF.
*EOC By Arnav on 23/11/26

  ls_col-color-col = lv_base.
  ls_col-fname = 'EWIP'.
  APPEND ls_col TO cs_row-coltab.
  ls_col-fname = 'DWIP'.
  APPEND ls_col TO cs_row-coltab.
  ls_col-fname = 'CWIP'.
  APPEND ls_col TO cs_row-coltab.
  ls_col-fname = 'OTHCAP'.
  APPEND ls_col TO cs_row-coltab.
  ls_col-fname = 'STATE'.
  APPEND ls_col TO cs_row-coltab.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form add_fcat
*&---------------------------------------------------------------------*
FORM add_fcat USING iv_field TYPE clike iv_text TYPE clike iv_len TYPE i
                    iv_ref TYPE clike iv_edit TYPE abap_bool iv_sum TYPE abap_bool
              CHANGING ct_fcat TYPE lvc_t_fcat.
  DATA ls_fcat TYPE lvc_s_fcat.

  ls_fcat-fieldname = iv_field.
  ls_fcat-coltext   = iv_text.
  ls_fcat-scrtext_s = iv_text.
  ls_fcat-scrtext_m = iv_text.
  ls_fcat-scrtext_l = iv_text.
  ls_fcat-outputlen = iv_len.
  ls_fcat-do_sum    = iv_sum.
  IF iv_ref IS NOT INITIAL.
    ls_fcat-ref_table = gc_tab_capex.
    ls_fcat-ref_field = iv_ref.
  ENDIF.
  IF iv_edit = abap_true AND gv_edit = abap_true.
    ls_fcat-edit = abap_true.
  ENDIF.
  APPEND ls_fcat TO ct_fcat.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display
*&---------------------------------------------------------------------*
FORM display.
  DATA: lt_fcat TYPE lvc_t_fcat,
        ls_layo TYPE lvc_s_layo,
        lt_excl TYPE ui_functions,
        lv_fy2  TYPE n LENGTH 2,
        lv_st   TYPE string.

*BOC By Arnav on 23/11/26
  PERFORM add_fcat USING 'STICO'  'Status'               4  ''       abap_false abap_false CHANGING lt_fcat.
*EOC By Arnav on 23/11/26
  PERFORM add_fcat USING 'PROJID' 'Project'              6  ''       abap_false abap_false CHANGING lt_fcat.
  PERFORM add_fcat USING 'PROJNM' 'Project Name'         36 ''       abap_false abap_false CHANGING lt_fcat.
  PERFORM add_fcat USING 'BU'     'Business Unit'        10 ''       abap_false abap_false CHANGING lt_fcat.
  PERFORM add_fcat USING 'JVTXT'  'JV Code'              14 ''       abap_false abap_false CHANGING lt_fcat.
  PERFORM add_fcat USING 'PRIOR'  'Prior Reported Capex' 18 ''       abap_false abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'EWIP'   'Cumulative EWIP'      18 'EWIP'   abap_true  abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'DWIP'   'Cumulative DWIP'      18 'DWIP'   abap_true  abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'CWIP'   'Cumulative CWIP'      18 'CWIP'   abap_true  abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'OTHCAP' 'Cumulative Other'     18 'OTHCAP' abap_true  abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'TOTAL'  'Total'                18 ''       abap_false abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'INCR'   'Increase in Period'   18 ''       abap_false abap_true  CHANGING lt_fcat.
  PERFORM add_fcat USING 'STATE'  'State'                10 ''       abap_false abap_false CHANGING lt_fcat.
  PERFORM add_fcat USING 'AENAM'  'Changed By'           12 ''       abap_false abap_false CHANGING lt_fcat.
  PERFORM add_fcat USING 'AEDAT'  'Changed On'           10 'AEDAT'  abap_false abap_false CHANGING lt_fcat.
  PERFORM polish_fcat CHANGING lt_fcat.          "Changes by Arnav on 23/11/26

  CASE gs_per-status.
    WHEN gc_open.
      lv_st = 'open'.
    WHEN gc_frozen.
      lv_st = 'frozen'.
    WHEN OTHERS.
      lv_st = 'not open'.
  ENDCASE.
  IF gv_adm = abap_true.
    lv_st = 'correction mode'.
  ENDIF.
  lv_fy2 = ( p_gjahr + 1 ) MOD 100.
*BOC By Arnav on 23/11/26
* the header pane carries year, fortnight, cutoff and status now
*  ls_layo-grid_title = |Capex USD mn FY { p_gjahr }-{ lv_fy2 }, fortnight { p_perno }| &&
*                       | to { gs_per-cutoff DATE = USER } ({ lv_st })|.
  ls_layo-grid_title = |Projects of fortnight { p_perno } ({ lv_st })|.
*EOC By Arnav on 23/11/26
  ls_layo-ctab_fname = 'COLTAB'.
*BOC By Arnav on 23/11/26
*  ls_layo-zebra      = abap_false.
*  ls_layo-cwidth_opt = abap_false.
  ls_layo-zebra      = abap_true.
  ls_layo-cwidth_opt = abap_true.
*EOC By Arnav on 23/11/26
  ls_layo-sel_mode   = 'A'.

* no row operations: the project list comes from the project master
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO lt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO lt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO lt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO lt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_move_row      TO lt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO lt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO lt_excl.

*BOC By Arnav on 23/11/26
*  CREATE OBJECT go_grid
*    EXPORTING
*      i_parent = cl_gui_container=>default_screen.
* header pane on top, grid below
  CREATE OBJECT go_split
    EXPORTING
      parent  = cl_gui_container=>default_screen
      rows    = 2
      columns = 1.
  go_split->set_row_height( id = 1 height = 18 ).
  go_top  = go_split->get_container( row = 1 column = 1 ).
  go_body = go_split->get_container( row = 2 column = 1 ).
  CREATE OBJECT go_grid
    EXPORTING
      i_parent = go_body.
  PERFORM header.
*EOC By Arnav on 23/11/26
  IF go_evt IS NOT BOUND.
    CREATE OBJECT go_evt.
  ENDIF.
  SET HANDLER go_evt->on_toolbar  FOR go_grid.
  SET HANDLER go_evt->on_ucomm    FOR go_grid.
  SET HANDLER go_evt->on_finished FOR go_grid.

  go_grid->set_table_for_first_display(
    EXPORTING
      is_layout            = ls_layo
      it_toolbar_excluding = lt_excl
    CHANGING
      it_outtab            = gt_row
      it_fieldcatalog      = lt_fcat ).

  IF gv_edit = abap_true.
    go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_modified ).
    go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_enter ).
    go_grid->set_ready_for_input( 1 ).
  ELSE.
    go_grid->set_ready_for_input( 0 ).
  ENDIF.

* the list screen this WRITE opens is the screen the grid is drawn on
*  WRITE space.                                   "Changes by Arnav on 24/11/26
ENDFORM.

*BOC By Arnav on 23/11/26
*&---------------------------------------------------------------------*
*& Form polish_fcat - status icon, fixed key columns, emphasis, tooltips
*&---------------------------------------------------------------------*
FORM polish_fcat CHANGING ct_fcat TYPE lvc_t_fcat.
  FIELD-SYMBOLS <ls_fcat> TYPE lvc_s_fcat.

  LOOP AT ct_fcat ASSIGNING <ls_fcat>.
    CASE <ls_fcat>-fieldname.
      WHEN 'STICO'.
        <ls_fcat>-icon       = abap_true.
        <ls_fcat>-just       = 'C'.
        <ls_fcat>-key        = abap_true.
        <ls_fcat>-fix_column = abap_true.
        <ls_fcat>-tooltip    = 'Pre-filled / entered / unsaved / frozen'.
      WHEN 'PROJID' OR 'PROJNM'.
        <ls_fcat>-key        = abap_true.
        <ls_fcat>-fix_column = abap_true.
      WHEN 'PRIOR'.
        <ls_fcat>-tooltip = 'Last reported cumulative, USD million'.
      WHEN 'EWIP' OR 'DWIP' OR 'CWIP' OR 'OTHCAP'.
        <ls_fcat>-tooltip = 'Cumulative for the FY, USD million'.
      WHEN 'TOTAL'.
        <ls_fcat>-emphasize = 'C410'.
        <ls_fcat>-tooltip   = 'Sum of the four categories'.
      WHEN 'INCR'.
        <ls_fcat>-emphasize = 'C400'.
        <ls_fcat>-tooltip   = 'Total less prior reported Capex'.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form header - title, fortnight, figures so far and colour legend in
*& the pane above the grid; called again after every change and save
*&---------------------------------------------------------------------*
FORM header.
  DATA: lv_text  TYPE sdydo_text_element,
        lv_fy2   TYPE n LENGTH 2,
        lv_cnt   TYPE i,
        lv_ent   TYPE i,
        lv_unsav TYPE i,
        lv_prior TYPE ty_amt,
        lv_total TYPE ty_amt,
        lv_incr  TYPE ty_amt.
  FIELD-SYMBOLS <ls_row> TYPE ty_row.

  IF go_top IS NOT BOUND.
    RETURN.
  ENDIF.
  LOOP AT gt_row ASSIGNING <ls_row>.
    lv_cnt   = lv_cnt + 1.
    lv_prior = lv_prior + <ls_row>-prior.
    lv_total = lv_total + <ls_row>-total.
    IF <ls_row>-saved = abap_true OR <ls_row>-dirty = abap_true.
      lv_ent = lv_ent + 1.
    ENDIF.
    IF <ls_row>-dirty = abap_true.
      lv_unsav = lv_unsav + 1.
    ENDIF.
  ENDLOOP.
  lv_incr = lv_total - lv_prior.

  IF go_doc IS NOT BOUND.
    CREATE OBJECT go_doc
      EXPORTING
        style = 'ALV_GRID'.
  ENDIF.
  go_doc->initialize_document( background_color = cl_dd_area=>col_textarea ).

* line 1: what this screen is
  lv_fy2  = ( p_gjahr + 1 ) MOD 100.
  lv_text = |Provisional Capex  -  FY { p_gjahr }-{ lv_fy2 }, fortnight { p_perno }|.
  go_doc->add_text( text = lv_text sap_style = cl_dd_area=>heading ).
  go_doc->new_line( ).

* line 2: cutoff, status and mode
  go_doc->add_text( text = 'Cutoff date:' sap_emphasis = cl_dd_area=>strong ).
  lv_text = |{ gs_per-cutoff DATE = USER }|.
  go_doc->add_text( text = lv_text ).
  go_doc->add_gap( width = 4 ).
  go_doc->add_text( text = 'Fortnight:' sap_emphasis = cl_dd_area=>strong ).
  CASE gs_per-status.
    WHEN gc_open.
      lv_text = 'Open for entry'.
    WHEN gc_frozen.
      lv_text = 'Frozen'.
    WHEN OTHERS.
      lv_text = 'Not yet open'.
  ENDCASE.
  go_doc->add_text( text = lv_text ).
  go_doc->add_gap( width = 4 ).
  go_doc->add_text( text = 'Mode:' sap_emphasis = cl_dd_area=>strong ).
  IF gv_adm = abap_true.
    lv_text = 'Correction by Corporate Budgeting'.
  ELSEIF gv_edit = abap_true.
    lv_text = 'Entry'.
  ELSE.
    lv_text = 'Display only'.
  ENDIF.
  go_doc->add_text( text = lv_text ).
  go_doc->add_gap( width = 4 ).
  go_doc->add_text( text = 'Amounts:' sap_emphasis = cl_dd_area=>strong ).
  go_doc->add_text( text = 'USD million, cumulative for the year' ).
  go_doc->new_line( ).

* line 3: figures so far
  go_doc->add_text( text = 'Projects entered:' sap_emphasis = cl_dd_area=>strong ).
  lv_text = |{ lv_ent } of { lv_cnt }|.
  go_doc->add_text( text = lv_text ).
  IF lv_unsav > 0.
    lv_text = |({ lv_unsav } not saved yet)|.
    go_doc->add_gap( width = 1 ).
    go_doc->add_text( text = lv_text sap_color = cl_dd_area=>list_negative ).
  ENDIF.
  go_doc->add_gap( width = 4 ).
  go_doc->add_text( text = 'Prior reported:' sap_emphasis = cl_dd_area=>strong ).
  lv_text = |{ lv_prior NUMBER = USER }|.
  go_doc->add_text( text = lv_text ).
  go_doc->add_gap( width = 4 ).
  go_doc->add_text( text = 'Now:' sap_emphasis = cl_dd_area=>strong ).
  lv_text = |{ lv_total NUMBER = USER }|.
  go_doc->add_text( text = lv_text ).
  go_doc->add_gap( width = 4 ).
  go_doc->add_text( text = 'Increase:' sap_emphasis = cl_dd_area=>strong ).
  lv_text = |{ lv_incr NUMBER = USER }|.
  go_doc->add_text( text = lv_text sap_color = cl_dd_area=>list_positive ).
  go_doc->new_line( ).

* line 4: legend of the status icons and cell colours
  go_doc->add_icon( sap_icon = 'ICON_LED_YELLOW' ).
  go_doc->add_text( text = 'Pre-filled from the prior fortnight (yellow)' ).
  go_doc->add_gap( width = 3 ).
  go_doc->add_icon( sap_icon = 'ICON_CHANGE' ).
  go_doc->add_text( text = 'Changed, not saved' ).
  go_doc->add_gap( width = 3 ).
  go_doc->add_icon( sap_icon = 'ICON_LED_GREEN' ).
  go_doc->add_text( text = 'Entered (green)' ).
  go_doc->add_gap( width = 3 ).
  go_doc->add_icon( sap_icon = 'ICON_LOCKED' ).
  go_doc->add_text( text = 'Frozen (grey-blue)' ).

  go_doc->merge_document( ).
  IF gv_doc_on = abap_false.
    go_doc->display_document( EXPORTING  parent             = go_top
                              EXCEPTIONS html_display_error = 1
                                         OTHERS             = 2 ).
    gv_doc_on = abap_true.
  ELSE.
    go_doc->display_document( EXPORTING  reuse_control      = abap_true
                                         parent             = go_top
                              EXCEPTIONS html_display_error = 1
                                         OTHERS             = 2 ).
  ENDIF.
ENDFORM.
*EOC By Arnav on 23/11/26

*&---------------------------------------------------------------------*
*& Form refresh
*&---------------------------------------------------------------------*
FORM refresh.
  DATA ls_stbl TYPE lvc_s_stbl.

  ls_stbl-row = abap_true.
  ls_stbl-col = abap_true.
  go_grid->refresh_table_display( is_stable = ls_stbl i_soft_refresh = abap_true ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form save - only the rows changed in this session are written
*&---------------------------------------------------------------------*
FORM save.
  DATA: lt_db  TYPE STANDARD TABLE OF zfi_pcx_capex WITH DEFAULT KEY,
        ls_db  TYPE zfi_pcx_capex,
        lv_msg TYPE string,
        lv_cnt TYPE i.
  FIELD-SYMBOLS <ls_row> TYPE ty_row.

  IF gv_edit = abap_false.
    RETURN.
  ENDIF.
* take over a cell that is still being edited; this runs ON_FINISHED
  go_grid->check_changed_data( ).

  LOOP AT gt_row ASSIGNING <ls_row> WHERE dirty = abap_true.
    PERFORM check_row USING <ls_row> CHANGING lv_msg.
    IF lv_msg IS NOT INITIAL.
      MESSAGE lv_msg TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    CLEAR ls_db.
    ls_db-mandt  = sy-mandt.
    ls_db-gjahr  = p_gjahr.
    ls_db-perno  = p_perno.
    ls_db-projid = <ls_row>-projid.
    ls_db-ewip   = <ls_row>-ewip.
    ls_db-dwip   = <ls_row>-dwip.
    ls_db-cwip   = <ls_row>-cwip.
    ls_db-othcap = <ls_row>-othcap.
    ls_db-aenam  = sy-uname.
    ls_db-aedat  = sy-datum.
    ls_db-aetim  = sy-uzeit.
    APPEND ls_db TO lt_db.
  ENDLOOP.
  IF lt_db IS INITIAL.
    MESSAGE 'No changes to save' TYPE 'S'.
    RETURN.
  ENDIF.

  MODIFY zfi_pcx_capex FROM TABLE lt_db.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'Save failed - nothing was written' TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  COMMIT WORK.

  LOOP AT gt_row ASSIGNING <ls_row> WHERE dirty = abap_true.
    <ls_row>-dirty = abap_false.
    <ls_row>-saved = abap_true.
    <ls_row>-aenam = sy-uname.
    <ls_row>-aedat = sy-datum.
    PERFORM derive_row CHANGING <ls_row>.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.
  PERFORM refresh.
  PERFORM header.                                 "Changes by Arnav on 23/11/26
  MESSAGE |{ lv_cnt } project(s) saved for fortnight { p_perno }| TYPE 'S'.
ENDFORM.
