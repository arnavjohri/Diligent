*&---------------------------------------------------------------------*
*& Modulpool  ZHANA_SERVICES_PRG
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
PROGRAM zhana_services_prg.

TABLES : zsap_timesheet, zresource_mappin,zstages, zapprovers.
DATA flag TYPE c.
DATA : loan            TYPE c,
       upload          TYPE c,
       form            TYPE c,
       create          TYPE c,
       change          TYPE c,
       schange         TYPE c,
       display         TYPE c,
       approve         TYPE c,
       print           TYPE c,
       r1              TYPE c,
       r2              TYPE c,
       month           TYPE c LENGTH 10,
       doc_no          TYPE zsap_timesheet-doc_no,
       creator_release TYPE c,
       sap_pm          TYPE c,
       core_team       TYPE c,
       ovl_pm          TYPE c,
       head_it         TYPE c,
       release         TYPE c,

       gv_loaded       TYPE c,
       lv_role         TYPE zapprovers-role,
       reason          TYPE c LENGTH 120,
       reject          TYPE c
       .

TYPES: BEGIN OF st_data,
         sel             TYPE c,
         consultant_name LIKE zsap_timesheet-consultant_name,
         ZCONSULTANT_ID  like zsap_timesheet-ZCONSULTANT_ID,       "added by mohd mobassir 30.06.2026
         service_element LIKE zsap_timesheet-service_element,
         zmodulec        LIKE zsap_timesheet-zmodulec,
         datec           LIKE zsap_timesheet-datec,
         daysc           LIKE zsap_timesheet-daysc,
         activity        LIKE zsap_timesheet-activity,
         scope           LIKE zsap_timesheet-scope,
         stages          LIKE zsap_timesheet-stages,
         location        LIKE zsap_timesheet-location,
         remarks         LIKE zsap_timesheet-remarks,
       END OF st_data.
TYPES: BEGIN OF st_role,
         role LIKE zapprovers-role,
       END OF st_role.
DATA: lt_role TYPE TABLE OF st_role.

DATA: lt_data   TYPE TABLE OF st_data,
      lt_delete TYPE TABLE OF st_data,
      ls_data   TYPE st_data.
DATA : namet TYPE c LENGTH 20.
DATA: lv_sap_id         TYPE syuname,
      lv_addrnumber     TYPE usr21-addrnumber,
      lv_persnumber     TYPE usr21-persnumber,
      lv_email          TYPE adr6-smtp_addr,
      lv_email_receiver TYPE adr6-smtp_addr,
      lv_email_sender   TYPE adr6-smtp_addr.
DATA: lv_addrnum TYPE usr21-addrnumber,
      lv_persnum TYPE usr21-persnumber.

DATA: ld_mail TYPE zapprovers.
DATA: ld_mail1 TYPE zsap_timesheet.

DATA: lv_addrnum1 TYPE adr6-addrnumber,
      lv_persnum1 TYPE adr6-persnumber,
      lv_email1   TYPE adr6-smtp_addr.

TYPES: BEGIN OF ty_recipient,
         userid TYPE syuname,
         email  TYPE adr6-smtp_addr,
       END OF ty_recipient.

DATA: lt_recipients TYPE STANDARD TABLE OF ty_recipient,
      ls_recipient  TYPE ty_recipient.

INCLUDE ztimesheet_mail.

*&SPWIZARD: DECLARATION OF TABLECONTROL 'TIMESHEET' ITSELF
CONTROLS: timesheet TYPE TABLEVIEW USING SCREEN 9002.





*&SPWIZARD: LINES OF TABLECONTROL 'TIMESHEET'
DATA:     g_timesheet_lines  LIKE sy-loopc.

DATA:     ok_code LIKE sy-ucomm.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TIMESHEET'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE timesheet_change_tc_attr OUTPUT.
  DESCRIBE TABLE lt_data LINES timesheet-lines.
  DATA(lv_lines) = lines( lt_data ).
  IF lt_data IS INITIAL AND create = 'X'.
    CLEAR ls_data.
    APPEND ls_data TO lt_data.
  ELSE.
    READ TABLE lt_data INTO ls_data INDEX lv_lines.
    IF ls_data-consultant_name IS NOT INITIAL.
      APPEND INITIAL LINE TO lt_data.
    ENDIF.
  ENDIF.

ENDMODULE.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TIMESHEET'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE timesheet_get_lines OUTPUT.
  g_timesheet_lines = sy-loopc.

ENDMODULE.

*&SPWIZARD: INPUT MODULE FOR TC 'TIMESHEET'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MODIFY TABLE
MODULE timesheet_modify INPUT.
  MODIFY lt_data
    FROM ls_data
    INDEX timesheet-current_line.
ENDMODULE.

*&SPWIZARD: INPUT MODUL FOR TC 'TIMESHEET'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MARK TABLE
MODULE timesheet_mark INPUT.
  DATA: g_timesheet_wa2 LIKE LINE OF lt_data.
  IF timesheet-line_sel_mode = 1
  AND ls_data-sel = 'X'.
    LOOP AT lt_data INTO g_timesheet_wa2
      WHERE sel = 'X'.
      g_timesheet_wa2-sel = ''.
      MODIFY lt_data
        FROM g_timesheet_wa2
        TRANSPORTING sel.
    ENDLOOP.
  ENDIF.
  MODIFY lt_data
    FROM ls_data
    INDEX timesheet-current_line
    TRANSPORTING sel.
ENDMODULE.

*&SPWIZARD: INPUT MODULE FOR TC 'TIMESHEET'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE timesheet_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TIMESHEET'
                              'LT_DATA'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM user_ok_tc USING    p_tc_name TYPE dynfnam
                         p_table_name
                         p_mark_name
                CHANGING p_ok      LIKE sy-ucomm.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA: l_ok     TYPE sy-ucomm,
        l_offset TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

*&SPWIZARD: Table control specific operations                          *
*&SPWIZARD: evaluate TC name and operations                            *
  SEARCH p_ok FOR p_tc_name.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.
  l_offset = strlen( p_tc_name ) + 1.
  l_ok = p_ok+l_offset.
*&SPWIZARD: execute general and TC specific operations                 *
  CASE l_ok.
    WHEN 'INSR'.                      "insert row
      PERFORM fcode_insert_row USING    p_tc_name
                                        p_table_name.
      CLEAR p_ok.

    WHEN 'DELE'.                      "delete row

      lt_delete = lt_data.

      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.
      CLEAR p_ok.

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            l_ok.
      CLEAR p_ok.
*     WHEN 'L--'.                       "total left
*       PERFORM FCODE_TOTAL_LEFT USING P_TC_NAME.
*
*     WHEN 'L-'.                        "column left
*       PERFORM FCODE_COLUMN_LEFT USING P_TC_NAME.
*
*     WHEN 'R+'.                        "column right
*       PERFORM FCODE_COLUMN_RIGHT USING P_TC_NAME.
*
*     WHEN 'R++'.                       "total right
*       PERFORM FCODE_TOTAL_RIGHT USING P_TC_NAME.
*
    WHEN 'MARK'.                      "mark all filled lines
      PERFORM fcode_tc_mark_lines USING p_tc_name
                                        p_table_name
                                        p_mark_name   .
      CLEAR p_ok.

    WHEN 'DMRK'.                      "demark all filled lines
      PERFORM fcode_tc_demark_lines USING p_tc_name
                                          p_table_name
                                          p_mark_name .
      CLEAR p_ok.

*     WHEN 'SASCEND'   OR
*          'SDESCEND'.                  "sort column
*       PERFORM FCODE_SORT_TC USING P_TC_NAME
*                                   l_ok.

  ENDCASE.

ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name             .

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_lastline         TYPE i.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>.

*&SPWIZARD: get current line                                           *
  GET CURSOR LINE l_selline.
  IF sy-subrc <> 0.                   " append line to table
    l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line                                               *
    IF l_selline > <lines>.
      <tc>-top_line = l_selline - <lines> + 1 .
    ELSE.
      <tc>-top_line = 1.
    ENDIF.
  ELSE.                               " insert line into table
    l_selline = <tc>-top_line + l_selline - 1.
    l_lastline = <tc>-top_line + <lines> - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.

*&SPWIZARD: insert initial line                                        *
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
  <tc>-lines = <tc>-lines + 1.
*&SPWIZARD: set cursor                                                 *
  SET CURSOR LINE l_line.

ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name   .

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

*&SPWIZARD: delete marked lines                                        *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    IF <mark_field> = 'X'.
      DELETE <table> INDEX syst-tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                              " FCODE_DELETE_ROW

*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*      -->P_OK       ok code
*----------------------------------------------------------------------*
FORM compute_scrolling_in_tc USING    p_tc_name
                                      p_ok.
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_lines_name       LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <lines>      TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.
*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.
  ASSIGN (l_tc_lines_name) TO <lines>.


*&SPWIZARD: is no line filled?                                         *
  IF <tc>-lines = 0.
*&SPWIZARD: yes, ...                                                   *
    l_tc_new_top_line = 1.
  ELSE.
*&SPWIZARD: no, ...                                                    *
    CALL FUNCTION 'SCROLLING_IN_TABLE'
      EXPORTING
        entry_act      = <tc>-top_line
        entry_from     = 1
        entry_to       = <tc>-lines
        last_page_full = 'X'
        loops          = <lines>
        ok_code        = p_ok
        overlapping    = 'X'
      IMPORTING
        entry_new      = l_tc_new_top_line
      EXCEPTIONS
*       NO_ENTRY_OR_PAGE_ACT  = 01
*       NO_ENTRY_TO    = 02
*       NO_OK_CODE_OR_PAGE_GO = 03
        OTHERS         = 0.
  ENDIF.

*&SPWIZARD: get actual tc and column                                   *
  GET CURSOR FIELD l_tc_field_name
             AREA  l_tc_name.

  IF syst-subrc = 0.
    IF l_tc_name = p_tc_name.
*&SPWIZARD: et actual column                                           *
      SET CURSOR FIELD l_tc_field_name LINE 1.
    ENDIF.
  ENDIF.

*&SPWIZARD: set the new top line                                       *
  <tc>-top_line = l_tc_new_top_line.


ENDFORM.                              " COMPUTE_SCROLLING_IN_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       marks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_mark_lines USING p_tc_name
                               p_table_name
                               p_mark_name.
*&SPWIZARD: EGIN OF LOCAL DATA-----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

*&SPWIZARD: mark all filled lines                                      *
  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = 'X'.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_demark_lines USING p_tc_name
                                 p_table_name
                                 p_mark_name .
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

*&SPWIZARD: demark all filled lines                                    *
  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

INCLUDE zhana_services_prg_status_9o01.

INCLUDE zhana_services_prg_status_9o02.

INCLUDE zhana_services_prg_status_9o03.

INCLUDE zhana_services_prg_get_c_nai01.

INCLUDE zhana_services_prg_get_modui01.

INCLUDE zhana_services_prg_get_stagi01.

INCLUDE zhana_services_prg_get_doc_i01.

INCLUDE zhana_services_prg_mailf01.

INCLUDE zhana_services_prg_get_servi01.

INCLUDE zhana_services_prg_get_rolei01.

INCLUDE zhana_services_prg_get_rolei02.
