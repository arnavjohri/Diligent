*  ************************************************************************
*  Date            Transport      USERID        Description
* 12/09/2008      <RD1K960036>    SAB_SUMODH
*
* 1) Obsolete FM POPUP_TO_CONFIRM_STEP Replaced by POPUP_TO_CONFIRM.
************************************************************************
************************************************************************
*  Date            Transport      USERID        Description
* 30/04/2009      <RD1K963151>    SAB_SUMODH
* CR No. 30012322  RD1K996279 CAB_SUDHIR
*
*1)Change in Line 558.

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
* 24.02.2015   <RD1K996042>  CAB_SPYADAV    CR 30012295(LIPSY)         *
*                                          (Simultaneous assignment of *
*                                           MM  and OLM roles          *
*                                          during approval)            *
*&                                                                     *
*&                                                                     *
* 19.03.2015   <RD1K996555>  CAB_SPYADAV   CR 30012482(LIPSY)          *
*                                          (Simultaneous assignment of *
*                                           cross company ,multi module
*                                           roles,during approval      *
"                                          ,SRM Module introductin)    *
*&                                                                     *
*&                                                                     *

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
************************************************************************

*----------------------------------------------------------------------*
*   INCLUDE MZMMPREPROLEF01                                            *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  bac_confirm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM BAC_CONFIRM.

  DATA L_CHOICE.
  CLEAR L_CHOICE.
  IF G_MODE <> 'DIS'.

    " Begin of <RD1K960036>.
*    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Data will be lost, Want to quit? '
*              TITEL          = 'BACK'
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = l_choice.
    DATA : L_GET1(1) TYPE C.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = 'BACK '
        TEXT_QUESTION         = 'Data will be lost, Want to quit? '
        DISPLAY_CANCEL_BUTTON = ' '
        START_COLUMN          = 25
        START_ROW             = 6
      IMPORTING
        ANSWER                = L_GET1
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.

    IF SY-SUBRC = 0.
      CASE L_GET1.
        WHEN '1'.
          MOVE 'J' TO L_CHOICE.
        WHEN '2'.
          MOVE 'N' TO L_CHOICE.
      ENDCASE.
    ENDIF.
    " End of <RD1K960036>.

    IF L_CHOICE = 'J'.
*       perform clear_var.
      CLEAR L_CHOICE.
    ENDIF.
  ELSE.
*     perform clear_var.
  ENDIF.

ENDFORM.                    " bac_confirm
*&---------------------------------------------------------------------*
*&      Form  fill_sttab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_STTAB.

  IF SY-TCODE = 'ZIC_ARMS_CONNECT'.
    OLD_OK_CODE = 'DISPLAY'.
    GET PARAMETER ID 'ZREQNO' FIELD ZIC_PREP_ROLEREQ-DOCNO.
  ENDIF.

  REFRESH IT_TAB.
  CLEAR WA_TAB.

  IF OLD_OK_CODE =  'CREATE' OR
        OLD_OK_CODE = 'CROSSCO' OR
        OLD_OK_CODE = 'CRCROLES' OR
        OLD_OK_CODE =  'CHANGE' OR
        OLD_OK_CODE =  'RELEASE' OR
        OLD_OK_CODE =  'APPROVE' OR
        OLD_OK_CODE = 'DISPLAY'  OR
        OLD_OK_CODE = 'DELETE'.

    MOVE 'CREATE' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'CHANGE' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'DELETE' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'DISPLAY' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'RELEASE' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'APPROVE' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'SUIM' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'ROLE_DEL' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'CROSSCO' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'CRCROLES' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
*     move 'ATTACH' to wa_tab-fcode.
*     append wa_tab to it_tab.

  ELSE.

    MOVE 'CHECK' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'ATTACH' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'LIST' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.
    MOVE 'SAV' TO WA_TAB-FCODE.
    APPEND WA_TAB TO IT_TAB.

*    MOVE 'CRCROLES' TO wa_tab-fcode.
*    APPEND wa_tab TO it_tab.
  ENDIF.

ENDFORM.                    " fill_sttab
*&---------------------------------------------------------------------*
*&      Form  lock_reqhd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM LOCK_REQHD.

  CALL FUNCTION 'ENQUEUE_EZ_IC_PREPHDR'
    EXPORTING
*     MODE_ZMM_CDHD         = 'E'
      MODE_ZIC_PREP_ROLEREQ = 'E'
      MANDT                 = SY-MANDT
      DOCNO                 = ZIC_PREP_ROLEREQ-DOCNO
    EXCEPTIONS
      FOREIGN_LOCK          = 1
      SYSTEM_FAILURE        = 2
      OTHERS                = 3.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ELSE.
    MOVE 'Y' TO G_LOCK.
  ENDIF.

ENDFORM.                    " lock_reqhd
*&---------------------------------------------------------------------*
*&      Form  get_correspondence
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_CORRESPONDENCE.

  DATA : L_CORS LIKE THEAD-TDNAME.

  IF OLD_OK_CODE <> 'CREATE' OR
     OLD_OK_CODE <> 'CROSSCO'.

    REFRESH LINES_CORS.

    MOVE ZIC_PREP_ROLEREQ-DOCNO TO L_CORS.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        CLIENT                  = SY-MANDT
        ID                      = '0001'
        LANGUAGE                = SY-LANGU
        NAME                    = L_CORS
        OBJECT                  = 'ZHELP'
      TABLES
        LINES                   = LINES_CORS
      EXCEPTIONS
        ID                      = 1
        LANGUAGE                = 2
        NAME                    = 3
        NOT_FOUND               = 4
        OBJECT                  = 5
        REFERENCE_CHECK         = 6
        WRONG_ACCESS_TO_ARCHIVE = 7
        OTHERS                  = 8.

    IF SY-SUBRC <> 0.
      READ_FLAG = ''.
      ZIC_PREP_ROLEREQ-LONG_TEXT_FL = ''.
    ELSE.
      READ_FLAG = 'X'.
      ZIC_PREP_ROLEREQ-LONG_TEXT_FL = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " get_correspondense

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM USER_OK_TC USING    P_TC_NAME TYPE DYNFNAM
                         P_TABLE_NAME
                         P_MARK_NAME
                CHANGING P_OK      LIKE SY-UCOMM.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA: L_OK     TYPE SY-UCOMM,
        L_OFFSET TYPE I.
*-END OF LOCAL DATA----------------------------------------------------*

* Table control specific operations                                    *
*   evaluate TC name and operations                                    *
  SEARCH P_OK FOR P_TC_NAME.
  IF SY-SUBRC <> 0.
    EXIT.
  ENDIF.
  L_OFFSET = STRLEN( P_TC_NAME ) + 1.
  L_OK = P_OK+L_OFFSET.
* execute general and TC specific operations                           *
  CASE L_OK.
    WHEN 'INSR'.                      "insert row
      PERFORM FCODE_INSERT_ROW USING    P_TC_NAME
                                        P_TABLE_NAME.
      CLEAR P_OK.
      G_INS_FLAG = 'X'.

    WHEN 'DELE'.                      "delete row

      PERFORM FCODE_DELETE_ROW USING    P_TC_NAME
                                        P_TABLE_NAME
                                        P_MARK_NAME.
      CLEAR P_OK.

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM COMPUTE_SCROLLING_IN_TC USING P_TC_NAME
                                            L_OK.
      CLEAR P_OK.
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
      PERFORM FCODE_TC_MARK_LINES USING P_TC_NAME
                                        P_TABLE_NAME
                                        P_MARK_NAME   .
      CLEAR P_OK.

    WHEN 'DMRK'.                      "demark all filled lines
      PERFORM FCODE_TC_DEMARK_LINES USING P_TC_NAME
                                          P_TABLE_NAME
                                          P_MARK_NAME .
      CLEAR P_OK.

*     WHEN 'SASCEND'   OR
*          'SDESCEND'.                  "sort column
*       PERFORM FCODE_SORT_TC USING P_TC_NAME
*                                   l_ok.

  ENDCASE.

ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM FCODE_INSERT_ROW
              USING    P_TC_NAME           TYPE DYNFNAM
                       P_TABLE_NAME             .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA L_LINES_NAME       LIKE FELD-NAME.
  DATA L_SELLINE          LIKE SY-STEPL.
  DATA L_LASTLINE         TYPE I.
  DATA L_LINE             TYPE I.
  DATA L_TABLE_NAME       LIKE FELD-NAME.
  FIELD-SYMBOLS <TC>                 TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <LINES>              TYPE I.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

* get the table, which belongs to the tc                               *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

* get looplines of TableControl
  CONCATENATE 'G_' P_TC_NAME '_LINES' INTO L_LINES_NAME.
  ASSIGN (L_LINES_NAME) TO <LINES>.

* get current line
  GET CURSOR LINE L_SELLINE.
  IF SY-SUBRC <> 0.                   " append line to table
    L_SELLINE = <TC>-LINES + 1.
*&SPWIZARD: set top line and new cursor line                           *
    IF L_SELLINE > <LINES>.
      <TC>-TOP_LINE = L_SELLINE - <LINES> + 1 .
    ELSE.
      <TC>-TOP_LINE = 1.
    ENDIF.
  ELSE.                               " insert line into table
    L_SELLINE = <TC>-TOP_LINE + L_SELLINE - 1.
    L_LASTLINE = <TC>-TOP_LINE + <LINES> - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  L_LINE = L_SELLINE - <TC>-TOP_LINE + 1.
* insert initial line
  INSERT INITIAL LINE INTO <TABLE> INDEX L_SELLINE.
  <TC>-LINES = <TC>-LINES + 1.
* set cursor
  SET CURSOR LINE L_LINE.

  G_I = L_LINE.
  G_FIELD = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM FCODE_DELETE_ROW
              USING    P_TC_NAME           TYPE DYNFNAM
                       P_TABLE_NAME
                       P_MARK_NAME   .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA L_TABLE_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <WA>.
  FIELD-SYMBOLS <MARK_FIELD>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

* get the table, which belongs to the tc                               *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

* delete marked lines                                                  *
  DESCRIBE TABLE <TABLE> LINES <TC>-LINES.

  LOOP AT <TABLE> ASSIGNING <WA>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT P_MARK_NAME OF STRUCTURE <WA> TO <MARK_FIELD>.

***
    DATA : L_I LIKE SY-INDEX.
    L_I = 36.
    IF <MARK_FIELD> = 'X' AND <WA>+L_I(1) = ''.
      DELETE <TABLE> INDEX SYST-TABIX.
      IF SY-SUBRC = 0.
        <TC>-LINES = <TC>-LINES - 1.
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
FORM COMPUTE_SCROLLING_IN_TC USING    P_TC_NAME
                                      P_OK.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA L_TC_NEW_TOP_LINE     TYPE I.
  DATA L_TC_NAME             LIKE FELD-NAME.
  DATA L_TC_LINES_NAME       LIKE FELD-NAME.
  DATA L_TC_FIELD_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <LINES>      TYPE I.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.
* get looplines of TableControl
  CONCATENATE 'G_' P_TC_NAME '_LINES' INTO L_TC_LINES_NAME.
  ASSIGN (L_TC_LINES_NAME) TO <LINES>.
***********************************************************************
  G_TC_LINES = <TC>-LINES.
***********************************************************************

* is no line filled?                                                   *
  IF <TC>-LINES = 0.
*   yes, ...                                                           *
    L_TC_NEW_TOP_LINE = 1.
  ELSE.
*   no, ...                                                            *
    CALL FUNCTION 'SCROLLING_IN_TABLE'
      EXPORTING
        ENTRY_ACT      = <TC>-TOP_LINE
        ENTRY_FROM     = 1
        ENTRY_TO       = <TC>-LINES
        LAST_PAGE_FULL = 'X'
        LOOPS          = <LINES>
        OK_CODE        = P_OK
        OVERLAPPING    = 'X'
      IMPORTING
        ENTRY_NEW      = L_TC_NEW_TOP_LINE
      EXCEPTIONS
*       NO_ENTRY_OR_PAGE_ACT  = 01
*       NO_ENTRY_TO    = 02
*       NO_OK_CODE_OR_PAGE_GO = 03
        OTHERS         = 0.
  ENDIF.

* get actual tc and column                                             *
  GET CURSOR FIELD L_TC_FIELD_NAME
             AREA  L_TC_NAME.

  IF SYST-SUBRC = 0.
    IF L_TC_NAME = P_TC_NAME.
*     set actual column                                                *
      SET CURSOR FIELD L_TC_FIELD_NAME LINE 1.
    ENDIF.
  ENDIF.

* set the new top line                                                 *
  <TC>-TOP_LINE = L_TC_NEW_TOP_LINE.


ENDFORM.                              " COMPUTE_SCROLLING_IN_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       marks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM FCODE_TC_MARK_LINES USING P_TC_NAME
                               P_TABLE_NAME
                               P_MARK_NAME.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA L_TABLE_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <WA>.
  FIELD-SYMBOLS <MARK_FIELD>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

* get the table, which belongs to the tc                               *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

* mark all filled lines                                                *
  LOOP AT <TABLE> ASSIGNING <WA>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT P_MARK_NAME OF STRUCTURE <WA> TO <MARK_FIELD>.

    <MARK_FIELD> = 'X'.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM FCODE_TC_DEMARK_LINES USING P_TC_NAME
                                 P_TABLE_NAME
                                 P_MARK_NAME .
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA L_TABLE_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <WA>.
  FIELD-SYMBOLS <MARK_FIELD>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

* get the table, which belongs to the tc                               *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

* demark all filled lines                                              *
  LOOP AT <TABLE> ASSIGNING <WA>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT P_MARK_NAME OF STRUCTURE <WA> TO <MARK_FIELD>.

    <MARK_FIELD> = SPACE.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines
*&---------------------------------------------------------------------*
*&      Form  HELP_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM HELP_LIST.

  IF ZIC_PREP_ROLEREQ-CCODE IS INITIAL.
    SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-CCODE'.
    MESSAGE I082(ZHELP).
    LEAVE TO SCREEN 0.
  ENDIF.
  REFRESH : IT_COND.
  CONCATENATE 'FICTR'  'LIKE'  INTO G_LINE SEPARATED BY
  SPACE.
  CONCATENATE G_LINE+0(10) '''' ZIC_PREP_ROLEREQ-CCODE '%' ''''  INTO
              G_LINE.
  APPEND G_LINE TO IT_COND.
  IF HELP_LIST_FLAG <> 'X' .
    SELECT * FROM M_FISTB INTO CORRESPONDING FIELDS OF TABLE IT_M_FISTB
                  WHERE (IT_COND).

*Begin of <RD1K963151>.
    IT_M_FISTB1[] = IT_M_FISTB[].
    CLEAR IT_M_FISTB[].

    SELECT FIKRS HIVARNT FISTL HIROOT_ST PARENT_ST  NEXT_ST CHILD_ST HILEVEL FROM
           FMHISV INTO TABLE IT_FMHISV FOR ALL ENTRIES IN IT_M_FISTB1 WHERE
           FISTL = IT_M_FISTB1-FICTR.

    DELETE IT_FMHISV WHERE PARENT_ST = SPACE OR PARENT_ST = 'ONGC'
    OR  PARENT_ST = 'OVL' OR PARENT_ST = 'OBV'.

    LOOP AT IT_M_FISTB1 INTO WA_FISTB1.
      READ TABLE IT_FMHISV WITH KEY FISTL = WA_FISTB1-FICTR.
      IF SY-SUBRC = 0 .
        MOVE WA_FISTB1-FICTR TO WA_FISTB-FICTR.
        MOVE WA_FISTB1-BEZEICH TO WA_FISTB-BEZEICH.
        APPEND WA_FISTB TO IT_M_FISTB.
      ENDIF.
    ENDLOOP.
*End of <RD1K963151>.

    HELP_LIST_FLAG = 'X'.
    REFRESH IT_COND.
  ENDIF.
  LOOP AT IT_M_FISTB INTO WA_M_FISTB.
*
    IF WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC OR
       WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC2 OR
       WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC3 OR
       WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC4.
      WA_M_FISTB-G_MARK = 'X'.
    ENDIF.

    IF OLD_OK_CODE = 'DISPLAY' OR OLD_OK_CODE = 'APPROVE'.
      IF WA_M_FISTB-G_MARK = 'X'.
        WRITE: / WA_M_FISTB-FICTR, WA_M_FISTB-BEZEICH.
      ENDIF.
    ELSE.
      WRITE: / WA_M_FISTB-G_MARK AS CHECKBOX, WA_M_FISTB-FICTR,
            WA_M_FISTB-BEZEICH.
    ENDIF.

    HIDE : WA_M_FISTB-G_MARK, WA_M_FISTB-FICTR.
*    CLEAR : wa_m_fistb-g_mark, wa_m_fistb-fictr.
  ENDLOOP.
  LINES = SY-LINNO .

ENDFORM.                    " HELP_LIST
*&---------------------------------------------------------------------*
*&      Form  tick_all
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM TICK_ALL.

  SY-LSIND = 0.

  MOVE 'REQ1' TO WA_TAB.
  APPEND WA_TAB TO TAB.
  MOVE 'SELALL' TO WA_TAB.
  APPEND WA_TAB TO TAB.
  MOVE 'DESELALL' TO WA_TAB.
  APPEND WA_TAB TO TAB.

  SET PF-STATUS 'STATUS_120' EXCLUDING TAB.
  CLEAR : WA_TAB.
  REFRESH : TAB.
  WRITE :'Selected Values for Company Code :',ZIC_PREP_ROLEREQ-CCODE
           COLOR COL_HEADING.
  ULINE.


  IF FLAG_S_FUNDC = 'X'.
*    refresh : s_fundc.
    LOOP AT IT_M_FISTB INTO WA_M_FISTB.
*
      WA_M_FISTB-G_MARK = 'X'.
      WRITE: / WA_M_FISTB-G_MARK AS CHECKBOX, WA_M_FISTB-FICTR,
               WA_M_FISTB-BEZEICH.
      MODIFY  IT_M_FISTB FROM WA_M_FISTB.
      HIDE : WA_M_FISTB-G_MARK, WA_M_FISTB-FICTR, WA_M_FISTB-BEZEICH.
      CLEAR : WA_M_FISTB-G_MARK, WA_M_FISTB-FICTR, WA_M_FISTB-BEZEICH.
    ENDLOOP.

    LINES = SY-LINNO .

  ENDIF.



ENDFORM.                    " tick_all
*&---------------------------------------------------------------------*
*&      Form  notick_all
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM NOTICK_ALL.

  SY-LSIND = 0.

  MOVE 'REQ1' TO WA_TAB.
  APPEND WA_TAB TO TAB.
  MOVE 'SELALL' TO WA_TAB.
  APPEND WA_TAB TO TAB.
  MOVE 'DESELALL' TO WA_TAB.
  APPEND WA_TAB TO TAB.

  SET PF-STATUS 'STATUS_120' EXCLUDING TAB.
  CLEAR : WA_TAB.
  REFRESH : TAB.
  WRITE :'Selected Values for Company Code :',ZIC_PREP_ROLEREQ-CCODE
         COLOR COL_HEADING.
  ULINE.


  IF FLAG_S_FUNDC = 'X'.
*    refresh : s_fundc.
    LOOP AT IT_M_FISTB INTO WA_M_FISTB.
*
      WA_M_FISTB-G_MARK = ''.
      WRITE: / WA_M_FISTB-G_MARK AS CHECKBOX, WA_M_FISTB-FICTR,
               WA_M_FISTB-BEZEICH.
      MODIFY  IT_M_FISTB FROM WA_M_FISTB.
      HIDE : WA_M_FISTB-G_MARK, WA_M_FISTB-FICTR, WA_M_FISTB-BEZEICH.
      CLEAR : WA_M_FISTB-G_MARK, WA_M_FISTB-FICTR, WA_M_FISTB-BEZEICH.
    ENDLOOP.

    LINES = SY-LINNO .

  ENDIF.


ENDFORM.                    " notick_all
*&---------------------------------------------------------------------*
*&      Form  pick
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PICK.

  SY-LSIND = 0.

  MOVE 'REQ1' TO WA_TAB.
  APPEND WA_TAB TO TAB.
  MOVE 'SELALL' TO WA_TAB.
  APPEND WA_TAB TO TAB.
  MOVE 'DESELALL' TO WA_TAB.
  APPEND WA_TAB TO TAB.

  DATA L_BLANK VALUE ''.

  SET PF-STATUS 'STATUS_120' EXCLUDING TAB.
  CLEAR : WA_TAB.
  REFRESH : TAB.
  WRITE :'Selected Values for Company Code :',ZIC_PREP_ROLEREQ-CCODE
         COLOR COL_HEADING.
  ULINE.


  IF FLAG_S_FUNDC = 'X'.
*    refresh : s_fundc.
    LOOP AT IT_M_FISTB INTO WA_M_FISTB.

      LINES_INDEX = SY-TABIX + 4.

      READ LINE LINES_INDEX FIELD VALUE WA_M_FISTB-G_MARK.

      WRITE: / WA_M_FISTB-G_MARK AS CHECKBOX, WA_M_FISTB-FICTR,
               WA_M_FISTB-BEZEICH.

      IF WA_M_FISTB-G_MARK <> 'X'.

        IF WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC.
          ZIC_PREP_ROLEREQ-FUNDC = 'X'.
        ENDIF.

        IF WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC2.
          CLEAR ZIC_PREP_ROLEREQ-FUNDC2.
        ENDIF.

        IF WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC3.
          CLEAR ZIC_PREP_ROLEREQ-FUNDC3.
        ENDIF.

        IF WA_M_FISTB-FICTR = ZIC_PREP_ROLEREQ-FUNDC4.
          CLEAR ZIC_PREP_ROLEREQ-FUNDC4.
        ENDIF.

      ENDIF.

      MODIFY  IT_M_FISTB FROM WA_M_FISTB.
      HIDE : WA_M_FISTB-G_MARK, WA_M_FISTB-FICTR.
*      CLEAR : wa_m_fistb-g_mark, wa_m_fistb-fictr, wa_m_fistb-bezeich.
    ENDLOOP.

    HELP_LIST_FLAG = 'X'.

    LINES = SY-LINNO .

    READ TABLE IT_M_FISTB INTO WA_M_FISTB WITH KEY G_MARK = 'X'.

    IF SY-SUBRC = 0.

      ZIC_PREP_ROLEREQ-FUNDC = WA_M_FISTB-FICTR.

    ELSE.

      CLEAR ZIC_PREP_ROLEREQ-FUNDC .

    ENDIF.

  ENDIF.

ENDFORM.                    " pick
*&---------------------------------------------------------------------*
*&      Form  check_items
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS.

  PERFORM VALIDATIONS1.

ENDFORM.                    " check_items
*&---------------------------------------------------------------------*
*&      Form  Save_request
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE_REQUEST.

  IF OLD_OK_CODE = 'CREATE' OR
     OLD_OK_CODE = 'CROSSCO' OR
     OLD_OK_CODE = 'CRCROLES'.

    PERFORM GEN_NO.

  ENDIF.

  IF OLD_OK_CODE = 'RELEASE' OR
     OLD_OK_CODE = 'APPROVE'.

    G_RELEASE = ZIC_PREP_ROLEREQ-REQ_CR_FL.
    G_APPROVE = ZIC_PREP_ROLEREQ-REQ_APP_FL.
    G_APPROVE0 = ZIC_PREP_ROLEREQ-REQ_APP0_FL.
    G_APPROVE1 = ZIC_PREP_ROLEREQ-REQ_APP1_FL.


    SELECT SINGLE * FROM ZIC_PREP_ROLEREQ
                    WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO.

    IF ZIC_PREP_ROLEREQ-REQ_CR_FL IS INITIAL.
      ZIC_PREP_ROLEREQ-REQ_CR_FL = G_RELEASE.
    ENDIF.
    IF ZIC_PREP_ROLEREQ-REQ_APP_FL IS INITIAL.
      ZIC_PREP_ROLEREQ-REQ_APP_FL = G_APPROVE.
    ENDIF.
    IF ZIC_PREP_ROLEREQ-REQ_APP1_FL IS INITIAL.
      ZIC_PREP_ROLEREQ-REQ_APP1_FL = G_APPROVE1.
    ENDIF.

    IF ZIC_PREP_ROLEREQ-REQ_APP0_FL IS INITIAL.
      ZIC_PREP_ROLEREQ-REQ_APP0_FL = G_APPROVE0.
    ENDIF.


    CLEAR : G_RELEASE, G_APPROVE, G_APPROVE0, G_APPROVE1.

    IF G_RELEASE = 'X' AND ( G_APPROVE <> 'X' AND
                             G_APPROVE0 <> 'X' AND
                             G_APPROVE1 <> 'X' ).

      G_APP_REL = 'X'.

    ENDIF.

  ENDIF.

  IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
    MESSAGE I089(ZHELP).
  ELSE.
    PERFORM INSERT_HEADER.
  ENDIF.

ENDFORM.                    " Save_request
*&---------------------------------------------------------------------*
*&      Form  gen_no
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GEN_NO.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      NR_RANGE_NR = '01'
      OBJECT      = 'ZDOCNUMB'
    IMPORTING
      NUMBER      = ZDOCNUMB.
  IF SY-SUBRC <> 0.
  ENDIF.

ENDFORM.                    " gen_no
*&---------------------------------------------------------------------*
*&      Form  insert_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_HEADER.

  ZIC_PREP_ROLEREQ-MANDT = SY-MANDT.
  IF OLD_OK_CODE = 'CREATE' OR
     OLD_OK_CODE = 'CROSSCO' OR
     OLD_OK_CODE = 'CRCROLES'.
    ZIC_PREP_ROLEREQ-DOCNO = ZDOCNUMB.
  ENDIF.

****************************************

**---------- Changes Start date 24.06.2016 11:43:05-------------------
**  SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
**      A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
**    D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
**    D~DISC_CD AS DISC_CD
**      INTO CORRESPONDING FIELDS OF TABLE IST_DATA
**       FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
**       ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
**          ON C~DESIGNO = D~DESIG_CODE AND
**              C~R_P_CD  = D~R_P_CD AND
**              C~VERSION = D~VERSION )
**           WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
**                 A~SPRPS = ' ' AND
**                 A~ENDDA = '99991231' AND
**                 C~SPRPS = ' ' AND
**                 C~ENDDA = '99991231' .


  SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
      A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
    D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
    D~DISC_CD AS DISC_CD
      INTO CORRESPONDING FIELDS OF TABLE IST_DATA
       FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
       ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
          ON C~DESIGNO = D~DESIG_CODE AND
              C~R_P_CD  = D~R_P_CD AND
              C~VERSION = D~VERSION )
           WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                 A~SPRPS = ' ' AND
                 A~ENDDA = '99991231' AND
                 C~SPRPS = ' ' AND
                 C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:43:05-----------------


  IF SY-SUBRC = 0.
    READ TABLE IST_DATA INDEX 1. "#EC CI_NOORDER

    ZIC_PREP_ROLEREQ-PERSA = IST_DATA-WERKS .

  ENDIF.
****************************************


  IF ZIC_PREP_ROLEREQ-USERIDCR IS INITIAL.

    ZIC_PREP_ROLEREQ-USERIDCR = SY-UNAME.
    ZIC_PREP_ROLEREQ-CR_DATE  = SY-DATUM.

    CLEAR ZUSRMST.

    SELECT SINGLE * FROM USR02 WHERE BNAME =
                               ZIC_PREP_ROLEREQ-USERIDCR.

    IF SY-SUBRC NE 0.

    ELSE.
*
      CLEAR IST_DATA.
      REFRESH IST_DATA.
**---------- Changes Start date 24.06.2016 11:44:38-------------------
**  SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
**           A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
**         D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
**           INTO CORRESPONDING FIELDS OF TABLE IST_DATA
**      FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
**            ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
**               ON C~DESIGNO = D~DESIG_CODE AND
**                   C~R_P_CD  = D~R_P_CD AND
**                   C~VERSION = D~VERSION )
**                WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDCR AND
**                      A~SPRPS = ' ' AND
**                      A~ENDDA = '99991231' AND
**                      C~SPRPS = ' ' AND
**                      C~ENDDA = '99991231' .


      SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
           A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
         D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
           INTO CORRESPONDING FIELDS OF TABLE IST_DATA
      FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
            ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
               ON C~DESIGNO = D~DESIG_CODE AND
                   C~R_P_CD  = D~R_P_CD AND
                   C~VERSION = D~VERSION )
                WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDCR AND
                      A~SPRPS = ' ' AND
                      A~ENDDA = '99991231' AND
                      C~SPRPS = ' ' AND
                      C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:44:38-----------------


      IF SY-SUBRC = 0.
        READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
        ZIC_PREP_ROLEREQ-NAMECR = IST_DATA-NAME.
        ZIC_PREP_ROLEREQ-DESIGCR = IST_DATA-DESIGNATION.
      ENDIF.

    ENDIF.

    CLEAR : IST_DATA.
    REFRESH : IST_DATA.

  ENDIF.


  IF ZIC_PREP_ROLEREQ-USERIDAP IS INITIAL.

    IF OLD_OK_CODE = 'APPROVE' AND
          ( ZIC_PREP_ROLEREQ-REQ_APP_FL = 'X' ).
      ZIC_PREP_ROLEREQ-USERIDAP = SY-UNAME.
      ZIC_PREP_ROLEREQ-APP_DATE  = SY-DATUM.

      IF ZIC_PREP_ROLEREQ-STATUS = 'IC' OR
         ZIC_PREP_ROLEREQ-STATUS = 'IR'.
        ZIC_PREP_ROLEREQ-STATUS   = 'IF'.
      ELSE.
        ZIC_PREP_ROLEREQ-STATUS   = 'N'.
      ENDIF.

      CLEAR ZUSRMST.

      SELECT SINGLE * FROM USR02 WHERE BNAME =
                            ZIC_PREP_ROLEREQ-USERIDAP.

      IF SY-SUBRC NE 0.

      ELSE.

        CLEAR IST_DATA.
        REFRESH IST_DATA.

**---------- Changes Start date 24.06.2016 11:45:22-------------------
*        SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
*                A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
*                C~VERSION D~SDESIG_TEXT AS DESIGNATION
*                 D~ADESIG_TEXT AS ADESIGNATION
*             INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*             FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*       ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*       ON C~DESIGNO = D~DESIG_CODE AND
*           C~R_P_CD  = D~R_P_CD AND
*           C~VERSION = D~VERSION )
*        WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDAP AND
*              A~SPRPS = ' ' AND
*              A~ENDDA = '99991231' AND
*              C~SPRPS = ' ' AND
*              C~ENDDA = '99991231' .
*--------Commented & Added by Manisha Dt:09.02.2018-------------------*

*        SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs
*                a~werks a~persk a~sbmod  c~designo c~r_p_cd
*                c~version d~sdesig_text AS designation
*                 d~adesig_text AS adesignation
*             INTO CORRESPONDING FIELDS OF TABLE ist_data
*             FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
*       ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
*       ON c~designo = d~desig_code AND
*           c~r_p_cd  = d~r_p_cd AND
*           c~version = d~version )
*        WHERE a~pernr = zic_prep_rolereq-useridap AND
*              a~sprps = ' ' AND
*              a~endda = '99991231' AND
*              c~sprps = ' ' AND
*              c~endda = '99991231' .
        SELECT * FROM ZMM_VMS_CR_NEW INTO WA_ZMM_VMS_CR_NEW UP TO 1 ROWS WHERE CORE_USER_ID = SY-UNAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
        IF SY-SUBRC = 0.
          SELECT SINGLE * FROM ZPA0001 INTO WA_PA0001 WHERE PERNR =  WA_ZMM_VMS_CR_NEW-CPF_NO AND
                                                           SPRPS  = ' '                       AND
                                                           ENDDA  >= '99991231' AND          "L_DATE
                                                           BEGDA <= SY-DATUM.


**---------- Changee  Ending Date 24.06.2016 11:45:22-----------------


*
          IF SY-SUBRC = 0.
*-------- Commented by Manisha bh.Dt:09.02.2018 ------------*
*            READ TABLE IST_DATA INDEX 1.
*            ZIC_PREP_ROLEREQ-NAMEAPP = IST_DATA-NAME.
*            ZIC_PREP_ROLEREQ-DESIGAP = IST_DATA-DESIGNATION.
*            IF ZIC_PREP_ROLEREQ-PERSA <> IST_DATA-WERKS AND
*                   NOT ZIC_PREP_ROLEREQ-PERSA IS INITIAL.
*              SELECT SINGLE * FROM T500P
*              WHERE PERSA = IST_DATA-WERKS.
*              IF ZIC_PREP_ROLEREQ-CCODE = T500P-BUKRS.
*              ELSE.
*                SELECT SINGLE * FROM ZMM_PREP_EX_APP
*                  WHERE USERID = ZIC_PREP_ROLEREQ-USERIDAP.
*                IF SY-SUBRC = 0.
*                ELSE.
*                  IF G_CCODE_CROSSCO = T500P-BUKRS.
*                  ELSE.
*                    MESSAGE E112(ZHELP).
*                  ENDIF.
*                ENDIF.
*              ENDIF.
*            ENDIF.
*-------------------------------------------------------------*
          ELSE.
            MESSAGE E110(ZHELP).
          ENDIF.
        ENDIF.
      ENDIF.
*    endif.

    ELSEIF OLD_OK_CODE = 'APPROVE' AND
            ZIC_PREP_ROLEREQ-REQ_APP0_FL = 'X'.
*                and
*                      ZIC_PREP_ROLEREQ-REQ_APP1_FL = 'X'.

      ZIC_PREP_ROLEREQ-USERIDAP = SY-UNAME.
      ZIC_PREP_ROLEREQ-APP_DATE = SY-DATUM.

      IF ZIC_PREP_ROLEREQ-STATUS = 'IC' OR
         ZIC_PREP_ROLEREQ-STATUS = 'IR'.
        ZIC_PREP_ROLEREQ-STATUS   = 'IF'.
      ELSE.
        ZIC_PREP_ROLEREQ-STATUS   = 'N'.
      ENDIF.


      SELECT SINGLE * FROM USR02 WHERE BNAME =
                              ZIC_PREP_ROLEREQ-USERIDAP.
      IF SY-SUBRC NE 0.
*              message e043(zhelp).
      ELSE.

        CLEAR IST_DATA.
        REFRESH IST_DATA.

**---------- Changes Start date 24.06.2016 11:45:58-------------------
*        SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
*                A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
*                C~VERSION D~SDESIG_TEXT AS DESIGNATION
*                 D~ADESIG_TEXT AS ADESIGNATION
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*                 FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*           ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*           ON C~DESIGNO = D~DESIG_CODE AND
*               C~R_P_CD  = D~R_P_CD AND
*               C~VERSION = D~VERSION )
*            WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDAP AND
*                  A~SPRPS = ' ' AND
*                  A~ENDDA = '99991231' AND
*                  C~SPRPS = ' ' AND
*                  C~ENDDA = '99991231' .

*--------Commented & Added by Manisha Dt:09.02.2018-------------------*
*        SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
*      A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
*      C~VERSION D~SDESIG_TEXT AS DESIGNATION
*       D~ADESIG_TEXT AS ADESIGNATION
*       INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*       FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
* ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
* ON C~DESIGNO = D~DESIG_CODE AND
*     C~R_P_CD  = D~R_P_CD AND
*     C~VERSION = D~VERSION )
*  WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDAP AND
*        A~SPRPS = ' ' AND
*        A~ENDDA = '99991231' AND
*        C~SPRPS = ' ' AND
*        C~ENDDA = '99991231' .
        SELECT * FROM ZMM_VMS_CR_NEW INTO WA_ZMM_VMS_CR_NEW UP TO 1 ROWS WHERE CORE_USER_ID = SY-UNAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
        IF SY-SUBRC = 0.
          SELECT SINGLE * FROM ZPA0001 INTO WA_PA0001 WHERE PERNR =  WA_ZMM_VMS_CR_NEW-CPF_NO AND
                                                           SPRPS  = ' '                       AND
                                                           ENDDA  >= '99991231' AND          "L_DATE
                                                           BEGDA <= SY-DATUM.

**---------- Changee  Ending Date 24.06.2016 11:45:58-----------------

          IF SY-SUBRC = 0.
*-------- Commented by Manisha bh.Dt:09.02.2018 ------------*
*          READ TABLE IST_DATA INDEX 1.
*          ZIC_PREP_ROLEREQ-NAMEAPP = IST_DATA-NAME.
*          ZIC_PREP_ROLEREQ-DESIGAP = IST_DATA-DESIGNATION.
*          IF ZIC_PREP_ROLEREQ-PERSA <> IST_DATA-WERKS AND
*             NOT ZIC_PREP_ROLEREQ-PERSA IS INITIAL.
*            SELECT SINGLE * FROM T500P
*                WHERE PERSA = IST_DATA-WERKS.
*            IF ZIC_PREP_ROLEREQ-CCODE = T500P-BUKRS.
*            ELSE.
*              SELECT SINGLE * FROM ZMM_PREP_EX_APP
*                   WHERE USERID = ZIC_PREP_ROLEREQ-USERIDAP.
*              IF SY-SUBRC = 0.
*              ELSE.
*
***code added by CAB_AMITMOZA  <RD1K983325>   CR: 30007580  dt: 09.04.2013.
*                IF ( ZIC_PREP_ROLEREQ-CCODE = 'SBW' AND T500P-BUKRS = 'SBS') OR
*                  ( ZIC_PREP_ROLEREQ-CCODE = 'BDW' AND T500P-BUKRS = 'BDA').
*                ELSE.
***code end by CAB_AMITMOZA  <RD1K983325>
*                  MESSAGE E112(ZHELP).
*                ENDIF.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*-------------------------------------------------------------*
          ELSE.
            MESSAGE E110(ZHELP).
          ENDIF.
        ENDIF.
      ENDIF.
**13.02.06

    ELSEIF OLD_OK_CODE = 'APPROVE' AND
*
                   ZIC_PREP_ROLEREQ-REQ_APP1_FL = 'X'.

      ZIC_PREP_ROLEREQ-USERIDAP = SY-UNAME.
      ZIC_PREP_ROLEREQ-APP_DATE = SY-DATUM.

      IF ZIC_PREP_ROLEREQ-STATUS = 'IC' OR
         ZIC_PREP_ROLEREQ-STATUS = 'IR'.
        ZIC_PREP_ROLEREQ-STATUS   = 'IF'.
      ELSE.
        ZIC_PREP_ROLEREQ-STATUS   = 'N'.
      ENDIF.


      SELECT SINGLE * FROM USR02 WHERE BNAME =
                              ZIC_PREP_ROLEREQ-USERIDAP.
      IF SY-SUBRC NE 0.
*              message e043(zhelp).
      ELSE.

        CLEAR IST_DATA.
        REFRESH IST_DATA.
**---------- Changes Start date 24.06.2016 11:47:43-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
*                A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
*                C~VERSION D~SDESIG_TEXT AS DESIGNATION
*                 D~ADESIG_TEXT AS ADESIGNATION
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*                 FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*           ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*           ON C~DESIGNO = D~DESIG_CODE AND
*               C~R_P_CD  = D~R_P_CD AND
*               C~VERSION = D~VERSION )
*            WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDAP AND
*                  A~SPRPS = ' ' AND
*                  A~ENDDA = '99991231' AND
*                  C~SPRPS = ' ' AND
*                  C~ENDDA = '99991231' .
*--------Commented & Added by Manisha Dt:09.02.2018-------------------*
*        SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
*                   A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
*                   C~VERSION D~SDESIG_TEXT AS DESIGNATION
*                    D~ADESIG_TEXT AS ADESIGNATION
*                    INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*                    FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
*              ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*              ON C~DESIGNO = D~DESIG_CODE AND
*                  C~R_P_CD  = D~R_P_CD AND
*                  C~VERSION = D~VERSION )
*               WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERIDAP AND
*                     A~SPRPS = ' ' AND
*                     A~ENDDA = '99991231' AND
*                     C~SPRPS = ' ' AND
*                     C~ENDDA = '99991231' .
        SELECT * FROM ZMM_VMS_CR_NEW INTO WA_ZMM_VMS_CR_NEW UP TO 1 ROWS WHERE CORE_USER_ID = SY-UNAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
        IF SY-SUBRC = 0.
          SELECT SINGLE * FROM ZPA0001 INTO WA_PA0001 WHERE PERNR =  WA_ZMM_VMS_CR_NEW-CPF_NO AND
                                                           SPRPS  = ' '                       AND
                                                           ENDDA  >= '99991231' AND          "L_DATE
                                                           BEGDA <= SY-DATUM.

**---------- Changee  Ending Date 24.06.2016 11:47:43-----------------


*
          IF SY-SUBRC = 0.
*-------- Commented by Manisha bh.Dt:09.02.2018 ------------*
*          READ TABLE IST_DATA INDEX 1.
*          ZIC_PREP_ROLEREQ-NAMEAPP = IST_DATA-NAME.
*          ZIC_PREP_ROLEREQ-DESIGAP = IST_DATA-DESIGNATION.
*          IF ZIC_PREP_ROLEREQ-PERSA <> IST_DATA-WERKS AND
*             NOT ZIC_PREP_ROLEREQ-PERSA IS INITIAL.
*            SELECT SINGLE * FROM T500P
*                WHERE PERSA = IST_DATA-WERKS.
*            IF ZIC_PREP_ROLEREQ-CCODE = T500P-BUKRS.
*            ELSE.
*              SELECT SINGLE * FROM ZMM_PREP_EX_APP
*                   WHERE USERID = ZIC_PREP_ROLEREQ-USERIDAP.
*              IF SY-SUBRC = 0.
*              ELSE.
** Check for L1 inserted  05/03/2007
*                IF G_USER = 'L1'.
*                ELSE.
*                  MESSAGE E112(ZHELP).
*                ENDIF.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*-------------------------------------------------------------*
          ELSE.
            MESSAGE E110(ZHELP).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
**13.02.06
  ENDIF.
*endif.
**12.06.06 vivek begin

  IF NOT ZIC_PREP_ROLEREQ-USERIDAP IS INITIAL AND
       OLD_OK_CODE = 'APPROVE' AND
                ( ZIC_PREP_ROLEREQ-REQ_APP_FL = 'X' OR
                     ZIC_PREP_ROLEREQ-REQ_APP1_FL = 'X' OR
                     ZIC_PREP_ROLEREQ-REQ_APP0_FL = 'X' ).

**
**---------- Changes Start date 24.06.2016 11:48:11-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
*              A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
*              C~VERSION D~SDESIG_TEXT AS DESIGNATION
*               D~ADESIG_TEXT AS ADESIGNATION
*           INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*           FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*     ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*     ON C~DESIGNO = D~DESIG_CODE AND
*         C~R_P_CD  = D~R_P_CD AND
*         C~VERSION = D~VERSION )
*      WHERE A~PERNR = SY-UNAME AND
*            A~SPRPS = ' ' AND
*            A~ENDDA = '99991231' AND
*            C~SPRPS = ' ' AND
*            C~ENDDA = '99991231' .

    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS
              A~WERKS A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD
              C~VERSION D~SDESIG_TEXT AS DESIGNATION
               D~ADESIG_TEXT AS ADESIGNATION
           INTO CORRESPONDING FIELDS OF TABLE IST_DATA
           FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
     ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
     ON C~DESIGNO = D~DESIG_CODE AND
         C~R_P_CD  = D~R_P_CD AND
         C~VERSION = D~VERSION )
      WHERE A~PERNR = SY-UNAME AND
            A~SPRPS = ' ' AND
            A~ENDDA = '99991231' AND
            C~SPRPS = ' ' AND
            C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:48:11-----------------


*
    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
      ZIC_PREP_ROLEREQ-NAMEAPP = IST_DATA-NAME.
      ZIC_PREP_ROLEREQ-USERIDAP = SY-UNAME.
    ENDIF.

**

    IF ZIC_PREP_ROLEREQ-STATUS = 'IC' OR
        ZIC_PREP_ROLEREQ-STATUS = 'IR'.
      ZIC_PREP_ROLEREQ-STATUS   = 'IF'.
    ELSE.
      ZIC_PREP_ROLEREQ-STATUS   = 'N'.
    ENDIF.
**12.06.06 vivek end
  ENDIF.
*****************************
  DATA L_FUNDC_NO LIKE SY-INDEX.
  CLEAR L_FUNDC_NO.
  LOOP AT IT_M_FISTB INTO WA_M_FISTB.
    IF WA_M_FISTB-G_MARK = 'X'.
      L_FUNDC_NO = L_FUNDC_NO + 1.
      CASE L_FUNDC_NO.
*Begin of <RD1K963151>.
        WHEN 2.
          ZIC_PREP_ROLEREQ-FUNDC2 = WA_M_FISTB-FICTR.
        WHEN 3.
          ZIC_PREP_ROLEREQ-FUNDC3 = WA_M_FISTB-FICTR.
        WHEN 4.
          ZIC_PREP_ROLEREQ-FUNDC4 = WA_M_FISTB-FICTR.
*        when 2.
*          ZIC_PREP_ROLEREQ-fundc2 = wa_m_fistb-fistl.
*        when 3.
*          ZIC_PREP_ROLEREQ-fundc3 = wa_m_fistb-fistl.
*        when 4.
*          ZIC_PREP_ROLEREQ-fundc4 = wa_m_fistb-fistl.
*End of <RD1K963151>.
        WHEN 5.
          MESSAGE I078(ZHELP).
          OKCODE_100 = 'MULTI'.
          G_FUNDC_ERR_FLAG = 'X'.
      ENDCASE.
    ENDIF.
  ENDLOOP.
*****************************

*****
  IF G_FUNDC_ERR_FLAG <> 'X'.

    IF OLD_OK_CODE = 'DISPLAY' AND ZIC_PREP_ROLEREQ-COMM_FL = 'X'.
      G_COMM_FL = 'X'.
      IF G_LINES_2 <> 0.
        CLEAR ZIC_PREP_ROLEREQ-COMM_FL.
        CLEAR G_LINES_2.
** Status New changed to IF
        ZIC_PREP_ROLEREQ-STATUS = 'IF'.
      ENDIF.
    ENDIF.

    IF OLD_OK_CODE = 'CHANGE' AND ZIC_PREP_ROLEREQ-COMM_FL = 'X'.
** Status New changed to IR
      ZIC_PREP_ROLEREQ-STATUS = 'IR'.
      CLEAR ZIC_PREP_ROLEREQ-COMM_FL.
    ENDIF.

    IF OLD_OK_CODE = 'CROSSCO'.
      ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
    ENDIF.

    IF OLD_OK_CODE = 'CRCROLES'.
      ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
    ENDIF.

    IF ZIC_PREP_ROLEREQ-CCODE IS INITIAL.
      MESSAGE E142(ZHELP).
    ENDIF.

    IF G_MULT_MODULE_FL = 'X' AND OLD_OK_CODE = 'CHANGE'.
      ZIC_PREP_ROLEREQ-MULTIMODULE_FL = 'X'.
    ENDIF.

    MODIFY ZIC_PREP_ROLEREQ FROM ZIC_PREP_ROLEREQ.

    IF SY-SUBRC = 0.

      IF G_APP_REL = 'X'.

        CLEAR G_APP_REL.

      ELSEIF
      ( OLD_OK_CODE = 'DISPLAY' AND ZIC_PREP_ROLEREQ-COMM_FL = 'X' )
      OR ( OLD_OK_CODE = 'CHANGE' AND ZIC_PREP_ROLEREQ-COMM_FL = 'X' ).

      ELSE.

        G_APPROVER_LEVEL = 'L3'.

** Module wise check & insertion

        IF G_RESET_FL <> 'X'.

          CASE MODULEID.

            WHEN 'MM'.

              PERFORM INSERT_ITEMS.

            WHEN 'PM'.

              PERFORM INSERT_ITEMS_PM.

            WHEN 'PS'.

              PERFORM INSERT_ITEMS_PS.

            WHEN 'PP'.

              PERFORM INSERT_ITEMS_PP.

            WHEN 'SD'.

              PERFORM INSERT_ITEMS_SD.

            WHEN 'QM'.

              PERFORM INSERT_ITEMS_QM.

            WHEN 'HSE'.

              PERFORM INSERT_ITEMS_HS.

            WHEN 'OLM'.

              PERFORM INSERT_ITEMS_OLM.

              """"""""""""""""""""""""""""""""""""""
              "added by lipsy for srm module introduction ON 3.3.2015 RD1K996555
            WHEN 'SRM'.
              PERFORM INSERT_ITEMS_SRM.
              "end of addition by lipsy  for srm module introduction ON 3.3.2015 RD1K996555
              """""""""""""""""""""""""""""""""""""""""""

          ENDCASE.

        ENDIF.

      ENDIF.

      IF G_RESET_FL <> 'X'.
        PERFORM ITEMS_APPROVAL_CHECK.
      ENDIF.

****Saving the long text.                              *****


      """""""""""""""""""""
      """"addition  by lipsy on 24.02.2015 for leaving program after release RD1K996042

      CLEAR:V_RELEASE.

      IF OLD_OK_CODE = 'RELEASE'.

        V_RELEASE = 'X'.

      ENDIF.

      "end of addition  by lipsy on 24.02.2015 for leaving program after release  RD1K996042
      """""""""""""""""""""""


      IF ( OLD_OK_CODE = 'CREATE' ) OR
      ( OLD_OK_CODE = 'CROSSCO' ) OR ( OLD_OK_CODE = 'CHANGE' )
          OR ( OLD_OK_CODE = 'CRCROLES' )
          OR ( OLD_OK_CODE = 'RELEASE' )
          OR ( OLD_OK_CODE = 'APPROVE' ).

        PERFORM SAVE_CORS_TEXT.
      ELSEIF G_COMM_FL = 'X'.
        PERFORM SAVE_CORS_TEXT.
        CLEAR G_COMM_FL.
      ENDIF.

**** Check if moduleid has changed
**13/04/07
      IF MODULE_CHANGED_FLAG = 'X' AND ( OLD_OK_CODE = 'CHANGE' OR
         OLD_OK_CODE = 'APPROVE' ).
        MODULEID = NEW_MODULEID.
        CLEAR NEW_MODULEID.
        CLEAR MODULE_CHANGED_FLAG.
        IF OLD_OK_CODE <> 'APPROVE'.
          OLD_OK_CODE = 'CHANGE'.
        ENDIF.
        PERFORM CLEAR_FOR_NEWMODULE.
      ELSE.
        PERFORM CLEAR.
      ENDIF.
****
*   if module_changed_flag = 'X' and old_ok_code = 'APPROVE'.
*      moduleid = new_moduleid.
*      clear new_moduleid.
*      clear module_changed_flag.
*      old_ok_code = 'CHANGE'.
*      perform clear_for_newmodule.
*   else.
*      perform clear.
*   endif.
****
      PERFORM UNLOCK_RECORD.
      IF G_RESET_FL = 'X'.
        CLEAR G_RESET_FL.
        CLEAR SET_DISC_MM_FLAG.
        CLEAR SET_DISC_FI_FLAG.
        CLEAR G_HD_COPIED.
**13/04/07
        IF OLD_OK_CODE = 'APPROVE'.
        ELSE.
          OLD_OK_CODE = 'CHANGE'.
        ENDIF.
        ZIC_PREP_ROLEREQ-DOCNO = G_DOCNO.
      ENDIF.

*      ZIC_PREP_ROLEREQ-crc_fl = g_crc_fl.
*      clear g_crc_fl.
      """"""""""""""""""""""""""""""
      """""addition  by lipsy on 24.02.2015 for leaving program after release RD1K996042
      IF  V_RELEASE = 'X'.
        LEAVE PROGRAM.
      ELSE.
        ""end of addition  by lipsy on 24.02.2015 for leaving program after release  RD1K996042
        """""""""""""""""""""""""""""""""""
        CALL SCREEN 100.
        """"""""""""""""""""""""""""""""""""
        """""addition  by lipsy on 24.02.2015 for leaving program after release RD1K996042
      ENDIF.
      ""end of addition  by lipsy on 24.02.2015 for leaving program after release  RD1K996042
      """"""""""""""""""""""""""""""""""""""

    ENDIF.

*****
  ELSE.

    CLEAR G_FUNDC_ERR_FLAG.
    CALL SCREEN 120 STARTING AT 10 5
                      ENDING   AT 90 15.
    CLEAR OKCODE_100.

  ENDIF.

ENDFORM.                    " insert_header
*&---------------------------------------------------------------------*
*&      Form  insert_items
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  SORT G_TABLCTRL110_ITAB
  BY ROLE_NAME PLANT GRP  SLOC RECEIPT_LOC APPROVER.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL110_ITAB
    COMPARING ROLE_NAME PLANT GRP  SLOC RECEIPT_LOC APPROVER REJ_FL
    ROLE_TYPE_EX CRC_POS.

  LOOP AT G_TABLCTRL110_ITAB INTO G_TABLCTRL110_WA.

    MOVE-CORRESPONDING G_TABLCTRL110_WA TO WA_ITEMTAB.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_ITEMS_SAVE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

***added g_reset_fl to check resetting & no rollback
  IF G_LINES_RL = 0 .
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
*      delete from ZIC_PREP_ROLEREQ
*            where docno = ZIC_PREP_ROLEREQ-docno.
*      delete from zic_prep_rolerei
*            where docno = ZIC_PREP_ROLEREQ-docno and
*                  moduleid = moduleid.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID..
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

**      if sy-subrc = 0.
**** Messages to be checked modulewise in sub
**        perform clear1.
**        if old_ok_code = 'CROSSCO' or
**              ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
**
**              if old_ok_code = 'RELEASE' or
**                  old_ok_code = 'CROSSCO' or
**                  old_ok_code = 'CHANGE'.
**                  perform popup_release_message.
**               endif.
**
**               if old_ok_code = 'APPROVE' or
**                  ZIC_PREP_ROLEREQ-status = 'IF'.
**                  perform popup_approve_message.
**               endif.
**
**               perform pop_up_crossco_message.          .
***          message i113(zhelp) with ZIC_PREP_ROLEREQ-docno.
**               message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**
**          else.
**            if old_ok_code = 'CRCROLES' or
**              ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
**               if old_ok_code = 'RELEASE' or
**                  old_ok_code = 'CRCROLES' or
**                  old_ok_code = 'CHANGE'.
**                  perform popup_release_message.
**               endif.
**               if old_ok_code = 'APPROVE' or
**                  ZIC_PREP_ROLEREQ-status = 'IF'.
**                  perform popup_approve_message.
**               endif.
**               perform pop_up_crc_message.
***              message i119(zhelp) with ZIC_PREP_ROLEREQ-docno.
**               message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**               g_crc_fl = 'X'.
**            else.
**              if old_ok_code = 'RELEASE'.
**                perform popup_release_message.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              elseif old_ok_code = 'APPROVE'.
**.               perform popup_approve_message.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              elseif old_ok_code = 'CREATE' or old_ok_code =
**'CHANGE'
      .
*.
**                perform popup_release_message1.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              elseif ZIC_PREP_ROLEREQ-status = 'IF'.
**                perform popup_approve_message.
**              else.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              endif.
**            endif.
**        endif.
**      endif.

    ENDIF.

  ENDIF.

ENDFORM.                    " insert_items
*&---------------------------------------------------------------------*
*&      Form  exit_confirm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM EXIT_CONFIRM.

  DATA L_CHOICE1.
  CLEAR L_CHOICE1.

  IF OLD_OK_CODE = 'CREATE' OR
     OLD_OK_CODE = 'CROSSCO' OR
     OLD_OK_CODE = 'CHANGE' OR
     OLD_OK_CODE = 'DELETE' OR
     OLD_OK_CODE = 'RELEASE' OR
     OLD_OK_CODE = 'APPROVE'.

    " Begin of <RD1K960036>.
*    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Data will be lost, Want to quit? '
*              TITEL          = 'EXIT'
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
**                 DEFAULTOPTION = 'N'
*         IMPORTING
*              ANSWER         = l_choice1.

    DATA : L_GET2(1) TYPE C.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = 'EXIT '
        TEXT_QUESTION         = 'Data will be lost, Want to quit? '
        DEFAULT_BUTTON        = '2'
        DISPLAY_CANCEL_BUTTON = ' '
        START_COLUMN          = 25
        START_ROW             = 6
      IMPORTING
        ANSWER                = L_GET2
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.
    IF SY-SUBRC = 0.
      CASE L_GET2.
        WHEN '1'.
          MOVE 'J' TO L_CHOICE1.
        WHEN '2'.
          MOVE 'N' TO L_CHOICE1.
      ENDCASE.
    ENDIF.
    " End of <RD1K960036>.

    IF L_CHOICE1 = 'J'.
      CLEAR L_CHOICE1.
      PERFORM CLEAR.
      PERFORM UNLOCK_RECORD.
      CALL SCREEN 100.
    ELSE.
    ENDIF.

  ELSE.

    PERFORM CLEAR.
    PERFORM UNLOCK_RECORD.
    CALL SCREEN 100.

  ENDIF.


ENDFORM.                    " exit_confirm
*&---------------------------------------------------------------------*
*&      Form  clear_var
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLEAR_VAR.

  PERFORM CLEAR.

ENDFORM.                    " clear_var
*&---------------------------------------------------------------------*
*&      Form  unlock_req
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UNLOCK_REQ.



ENDFORM.                    " unlock_req
*&---------------------------------------------------------------------*
*&      Form  unlock_record
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UNLOCK_RECORD.

  CALL FUNCTION 'DEQUEUE_EZ_IC_PREPHDR'
    EXPORTING
      MODE_ZIC_PREP_ROLEREQ = 'E'
      MANDT                 = SY-MANDT
      DOCNO                 = ZIC_PREP_ROLEREQ-DOCNO.

  CLEAR G_LOCK.

ENDFORM.                    " unlock_record
*&---------------------------------------------------------------------*
*&      Form  clear
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLEAR.

  PERFORM DESTROY_CTRL.

  OKCODE_100_P = OKCODE_100. " + BY BIPIN TO VALIDATE POP UP MESSAGE

  CLEAR   : OLD_OK_CODE, OKCODE_100, ERR_FLG.
  REFRESH : G_TABLCTRL110_ITAB[].
  CLEAR   : G_TABLCTRL110_ITAB.
  REFRESH : G_TABLCTRL111_ITAB[].
  CLEAR   : G_TABLCTRL111_ITAB.
  REFRESH : G_TABLCTRL112_ITAB[].
  CLEAR   : G_TABLCTRL112_ITAB.
  REFRESH : G_TABLCTRL113_ITAB[].
  CLEAR   : G_TABLCTRL113_ITAB.
  REFRESH : G_TABLCTRL114_ITAB[].
  CLEAR   : G_TABLCTRL114_ITAB.
  REFRESH : G_TABLCTRL115_ITAB[].
  CLEAR   : G_TABLCTRL115_ITAB.
  CLEAR   : SY-UCOMM.
  CLEAR   : G_CURR_LINE.
  CLEAR SET_DISC_MM_FLAG.
  CLEAR SET_DISC_FI_FLAG.
  CLEAR   : ZIC_PREP_ROLEREI, ZIC_PREP_ROLEREQ.
  CLEAR   : IT_TAB.
  REFRESH : TLINETAB1[],TLINETAB2[].
  CLEAR   : T500P-NAME1.
  CLEAR   : CRC_CHECK_FL.
  CLEAR   : HELP_LIST_FLAG.
  REFRESH : IT_M_FISTB.
  CLEAR   : MODULEID.

  """""""""""""""""""""""""
  "added by lipsy for clear on 20.03.2015 RD1K996555
  REFRESH : G_TABLCTRL118_ITAB[].
  CLEAR   : G_TABLCTRL118_ITAB.

  "end of addition by lipsy  for clear on 20.03.2015 RD1K996555
  """""""""""""""""


ENDFORM.                    " clear
*&---------------------------------------------------------------------*
*&      Form  text_control_eingabebereit1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM TEXT_CONTROL_EINGABEBEREIT1.

  CALL METHOD GV_TEXT_EDITOR1->SET_READONLY_MODE
    EXPORTING
      READONLY_MODE          = GV_TEXT_EDITOR1->TRUE
    EXCEPTIONS
      ERROR_CNTL_CALL_METHOD = 1
      INVALID_PARAMETER      = 2
      OTHERS                 = 3.

  IF ( OLD_OK_CODE = 'CREATE' )
   OR ( OLD_OK_CODE = 'CROSSCO' )
   OR ( OLD_OK_CODE = 'CRCROLES' )
   OR ( OLD_OK_CODE = 'CHANGE' )
   OR ( OLD_OK_CODE = 'RELEASE' )
   OR ( OLD_OK_CODE = 'APPROVE' )
  OR ( OLD_OK_CODE = 'DISPLAY' AND ZIC_PREP_ROLEREQ-COMM_FL = 'X'
       AND  ZIC_PREP_ROLEREQ-STATUS <> 'C' ).

    CALL METHOD GV_TEXT_EDITOR2->SET_READONLY_MODE
      EXPORTING
        READONLY_MODE          = GV_TEXT_EDITOR2->FALSE
      EXCEPTIONS
        ERROR_CNTL_CALL_METHOD = 1
        INVALID_PARAMETER      = 2
        OTHERS                 = 3.

  ENDIF.

ENDFORM.                    " text_control_eingabebereit1
*&---------------------------------------------------------------------*
*&      Form  text_control_set_text_table1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM TEXT_CONTROL_SET_TEXT_TABLE1.

  REFRESH: TLINETAB1, G_LINEFRTO_ITAB.
  IF OLD_OK_CODE <> 'CREATE' OR
     OLD_OK_CODE = 'CROSSCO' .
    APPEND LINES OF LINES_CORS TO TLINETAB1[].
  ENDIF.
*
  LOOP AT TLINETAB1[] INTO G_LINE132.
    IF ( G_LINE132+0(7) = '* Reply' ) OR
       ( G_LINE132+0(7) = '**Reply' ).
      G_LINEFRTO-LINE_FR = SY-TABIX.
      G_LINEFRTO-LINE_TO = SY-TABIX.
      APPEND G_LINEFRTO TO G_LINEFRTO_ITAB.
      CLEAR: G_LINEFRTO.
    ENDIF.
  ENDLOOP.
*
  CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
    TABLES
      ITF_TEXT    = TLINETAB1[]
      TEXT_STREAM = LT_TEXT_TABLE1.

  CALL METHOD GV_TEXT_EDITOR1->SET_TEXT_AS_STREAM
    EXPORTING
      TEXT            = LT_TEXT_TABLE1
    EXCEPTIONS
      ERROR_DP        = 1
      ERROR_DP_CREATE = 2
      OTHERS          = 3.
********************highlight**************************************
  CLEAR G_LINEFRTO.
  LOOP AT G_LINEFRTO_ITAB INTO G_LINEFRTO.
    CALL METHOD GV_TEXT_EDITOR1->HIGHLIGHT_LINES
      EXPORTING
        FROM_LINE      = G_LINEFRTO-LINE_FR
        TO_LINE        = G_LINEFRTO-LINE_TO
        HIGHLIGHT_MODE = 1.
  ENDLOOP.
********************************************************************

  IF ( OLD_OK_CODE = 'CREATE' )
   OR ( OLD_OK_CODE = 'CROSSCO' )
   OR ( OLD_OK_CODE = 'CRCROLES' )
   OR ( OLD_OK_CODE = 'CHANGE' )
   OR ( OLD_OK_CODE = 'DISPLAY' AND ZIC_PREP_ROLEREQ-COMM_FL = 'X'
       AND  ZIC_PREP_ROLEREQ-STATUS <> 'C').
    CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
      TABLES
        ITF_TEXT    = TLINETAB2
        TEXT_STREAM = LT_TEXT_TABLE2.

    CALL METHOD GV_TEXT_EDITOR2->SET_TEXT_AS_STREAM
      EXPORTING
        TEXT            = LT_TEXT_TABLE2
      EXCEPTIONS
        ERROR_DP        = 1
        ERROR_DP_CREATE = 2
        OTHERS          = 3.
  ENDIF.

ENDFORM.                    " text_control_set_text_table1
*&---------------------------------------------------------------------*
*&      Form  save_cors_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE_CORS_TEXT.

  DATA: L_THEADER LIKE THEAD.
  DATA: L_DATECH(10) TYPE C.
***********Assignments***********************
  CLEAR L_THEADER.
  L_THEADER-TDOBJECT   = 'ZHELP'.
  L_THEADER-TDID       = '0001'.
  L_THEADER-TDSPRAS    =  SY-LANGU.
  L_THEADER-TDLINESIZE =  72.
  MOVE ZIC_PREP_ROLEREQ-DOCNO TO L_THEADER-TDNAME.
  APPEND LINES OF TLINETAB2 TO TLINETAB1.
*********************************************
  IF NOT TLINETAB1[] IS INITIAL.
    CLEAR G_CORES_SENDER.
    CONCATENATE SY-DATUM+6(2) '/'
                SY-DATUM+4(2) '/'
                SY-DATUM+0(4) INTO L_DATECH.
    CONCATENATE '**Reply' L_DATECH SY-UNAME INTO G_CORES_SENDER
     SEPARATED BY '          '.
    IF NOT TLINETAB2[] IS INITIAL.
      APPEND G_CORES_SENDER TO TLINETAB1.
    ENDIF.
    CLEAR G_CORES_SENDER.
    CALL FUNCTION 'SAVE_TEXT'
      EXPORTING
        CLIENT          = SY-MANDT
        HEADER          = L_THEADER
        SAVEMODE_DIRECT = 'X'
      TABLES
        LINES           = TLINETAB1
      EXCEPTIONS
        ID              = 1
        LANGUAGE        = 2
        NAME            = 3
        OBJECT          = 4
        OTHERS          = 5.

    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.

ENDFORM.                    " save_cors_text
*&---------------------------------------------------------------------*
*&      Form  get_user
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_USER.

  CLEAR G_USER.

  """""""""""""""
  ""added by lipsy for l2 approver on 20.03.2015 RD1K996555
  CLEAR: G_USER_L2 .
  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
  """"""""

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                     ID 'FRGCO' FIELD : 'L1'.

  IF SY-SUBRC = 0.
    G_USER = 'L1'.
    CHECK 1 = 2.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                     ID 'FRGCO' FIELD : 'DI'.

  IF SY-SUBRC = 0.
    G_USER = 'L1'.
    CHECK 1 = 2.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                     ID 'FRGCO' FIELD : 'CS'.

  IF SY-SUBRC = 0.
    G_USER = 'L1'.
    CHECK 1 = 2.
  ENDIF.


  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                      ID 'FRGCO' FIELD : 'MD'.

  IF SY-SUBRC = 0.
    G_USER = 'L1'.
    CHECK 1 = 2.
  ENDIF.


  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                      ID 'FRGCO' FIELD : 'IM'.              "#EC *

  IF SY-SUBRC = 0.
    G_USER = 'IM'.
    CHECK 1 = 2.
  ENDIF.

  """"""""

  """""""""

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                    ID 'FRGCO' FIELD : 'L2'.
  IF SY-SUBRC = 0.
    G_USER = 'L3'.
    """"""""""""
    ""added by lipsy for l2 approver on 20.03.2015 RD1K996555
    G_USER_L2 = 'L2'.
    "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
    """"""""""

    CHECK 1 = 2.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                      ID 'FRGCO' FIELD : 'L3'.
  IF SY-SUBRC = 0.
    G_USER = 'L3'.

    """""""""""
    "add by lipsy on 7.12.2015
    G_USER_L2 = 'L3'.
    "eadd by lipsy on 7.12.2015
    """"""""""""
    CHECK 1 = 2.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
                      ID 'FRGCO' FIELD : 'L4'.

  IF SY-SUBRC = 0.
    G_USER = 'L3'.
    ZIC_PREP_ROLEREQ-RADIO_FL = 'X'.
    G_L4 = 'X'.
    CHECK 1 = 2.
  ENDIF.

ENDFORM.                    " find_user
*&---------------------------------------------------------------------*
*&      Form  validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATIONS.

  IF OLD_OK_CODE = 'APPROVE' AND MODULEID <> 'FI'.

    SELECT * FROM ZIC_PREP_ROLEREI UP TO 1 ROWS
 WHERE MODULEID = 'MM'
 AND DOCNO = ZIC_PREP_ROLEREQ-DOCNO
 ORDER BY PRIMARY KEY .
 ENDSELECT.

    IF SY-SUBRC = 0.
      MODULEMM_FL = 'X'.
    ENDIF.

    IF G_USER = 'L1' OR
       G_USER = 'IM' OR
       ( G_USER = 'L3' AND G_L4 <> 'X' ).
    ELSEIF MODULEMM_FL <> 'X' AND G_L4 = 'X'.
    ELSE.
      MESSAGE I131(ZHELP).
      CLEAR OLD_OK_CODE.
      CALL SCREEN 100.
    ENDIF.

    IF G_USER = 'L1' AND
       ( ZIC_PREP_ROLEREQ-REQ_APP0_FL = 'X' OR
         ZIC_PREP_ROLEREQ-REQ_APP_FL = 'X' ).
      MESSAGE I132(ZHELP).
      CLEAR OLD_OK_CODE.
      CALL SCREEN 100.
    ENDIF.

  ENDIF.

  IF OLD_OK_CODE <> 'DISPLAY' AND OLD_OK_CODE <> 'APPROVE'.

    IF  ZIC_PREP_ROLEREQ-USERIDCR = SY-UNAME.
    ELSE.
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          TEXTLINE1 = 'Not authorised to use this document- not yours '.
*                     message i046(zhelp).
      PERFORM CLEAR.
      CALL SCREEN 100.
    ENDIF.

  ENDIF.

  IF OLD_OK_CODE = 'CHANGE' AND ZIC_PREP_ROLEREQ-REQ_CR_FL = 'X'.

    IF ZIC_PREP_ROLEREQ-STATUS = 'IF' OR
          ZIC_PREP_ROLEREQ-STATUS = 'PC' OR
          ZIC_PREP_ROLEREQ-STATUS = 'C'.
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          TEXTLINE1 = 'Request under process / completed can''t change/reset'.

*                message e065(zhelp).
      PERFORM CLEAR.
      CALL SCREEN 100.

    ELSE.
      G_RESET_FL = ZIC_PREP_ROLEREQ-REQ_CR_FL.
      G_DOCNO = ZIC_PREP_ROLEREQ-DOCNO.
      PERFORM VERIFY.
    ENDIF.
  ENDIF.

  IF OLD_OK_CODE = 'APPROVE' AND
                    ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.

    """"""""""""""""""""""""""""""""""

    "comment by lipsy on 24.03.2015 RD1K996555
*    IF G_USER = 'IM' OR G_USER = 'L1'.
    "end of comment by lipsy on 24.03.2015 RD1K996555
    """"""""""""""""""""""""""""""""""

    """""""""""
    "added by lipsy  for approver on  24.03.2015 RD1K996555
    IF G_USER = 'IM' OR G_USER = 'L1' OR ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
      "end of addition by lipsy  for approver on  24.03.2015 RD1K996555
      """""""""""""""

    ELSE.
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          TEXTLINE1 = 'This requires approval of I/C MM'.

*               message e048(zhelp).
      PERFORM CLEAR.
      CALL SCREEN 100.
    ENDIF.
  ENDIF.

  """""""""""""""""""""""""""
  "added by lipsy  for approver on  20.03.2015 RD1K996555
  IF MODULEID = 'SRM'.
    IF OLD_OK_CODE = 'APPROVE' AND
                      ZIC_PREP_ROLEREQ-DISC_MM_FLAG NE 'X'.
      IF G_USER = 'L2' OR G_USER = 'L1' OR G_USER_L2 = 'L2'

        """""""""""""""""""""""""""""""""""
        "ADDED BY LIPSY ON 7.12.2015 RD1K999362
        OR  G_USER_L2 = 'L3'
        "END OF ADDITION  BY LIPSY ON 7.12.2015 RD1K999362
        """"""""""""""""""""""""""""""""""""""""
        .
      ELSE.
        CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
          EXPORTING
            """""""""""""""""""""""""""""""""""
            "COMMENT BY LIPSY ON 7.12.2015 RD1K999362
*           TEXTLINE1 = 'This requires approval of at least L2'.
            "END OF COMMENT BY LIPSY 7.12.2015 RD1K999362
            """""""""""""""""""""""""""""""""""""""
            """""""""""""""""""""""""""""""""""
            "ADDED BY LIPSY 7.12.2015 RD1K999362
            TEXTLINE1 = 'This requires approval of at least L3'.
        "END OF ADDITION  BY LIPSY 7.12.2015 RD1K999362
        """""""""""""""""""""""""""""""""""""""

*               message e048(zhelp).
        PERFORM CLEAR.
        CALL SCREEN 100.
      ENDIF.
    ENDIF.
  ENDIF.

* IF OLD_OK_CODE = 'APPROVE'.
*   if G_USER ne 'L1'.
*IF MODULEID = 'SRM' or  MODULEID = 'MM' or MODULEID = 'OLM'.
*
*  if ZIC_PREP_ROLEREQ-USERID = sy-uname.
*
*
*    endif.
*
*  endif.
*  ENDIF.
*ENDIF.
  "end of addition by lipsy  for approver on  20.03.2015 RD1K996555
  """"""""""""""""""""""""""""""""""

  IF OLD_OK_CODE = 'RELEASE' AND ZIC_PREP_ROLEREQ-REQ_CR_FL = 'X'.
    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
      EXPORTING
        TEXTLINE1 = 'Request already released by creator'.

*          message e053(zhelp).
    PERFORM CLEAR.
    CALL SCREEN 100.

  ENDIF.

  IF OLD_OK_CODE = 'APPROVE'.

    IF G_USER = 'L1' AND ZIC_PREP_ROLEREQ-REQ_APP1_FL = ' ' AND
       ZIC_PREP_ROLEREQ-REQ_CR_FL <> 'X'.
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          TEXTLINE1 = 'Request not released by creator'.

*                   message e051(zhelp).
      PERFORM CLEAR.
      CALL SCREEN 100.

    ENDIF.

    IF ( G_USER = 'IM' OR G_USER = 'L3' ) AND
                          ZIC_PREP_ROLEREQ-REQ_APP_FL = ' ' AND
       ZIC_PREP_ROLEREQ-REQ_CR_FL <> 'X'.
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          TEXTLINE1 = 'Request not released by creator'.
*                   message e051(zhelp)..
      PERFORM CLEAR.
      CALL SCREEN 100.

    ENDIF.

    IF  ZIC_PREP_ROLEREQ-REQ_APP1_FL = 'X' OR
        ZIC_PREP_ROLEREQ-REQ_APP_FL = 'X'.
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          TEXTLINE1 = 'Request already approved'.

      PERFORM CLEAR.
      CALL SCREEN 100.

    ENDIF.

  ENDIF.

  IF ( ZIC_PREP_ROLEREQ-STATUS = 'IF' OR
      ZIC_PREP_ROLEREQ-STATUS  = 'C' )
      AND OLD_OK_CODE <> 'DISPLAY'.
    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
      EXPORTING
        TEXTLINE1 = 'Request can not  be  changed, Can only be displayed'.

*              message e079(zhelp).
*               perform clear.
    OLD_OK_CODE = 'DISPLAY'.
    CALL SCREEN 100.

  ENDIF.

ENDFORM.                    " validations
*&---------------------------------------------------------------------*
*&      Form  validations1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATIONS1.

  DATA : L_DOCNO LIKE ZMM_PREP_ROLEREQ-DOCNO.

  SELECT * FROM FMZUOB UP TO 1 ROWS
 WHERE FISTL = ZIC_PREP_ROLEREQ-FUNDC
 ORDER BY PRIMARY KEY .
 ENDSELECT.

  IF SY-SUBRC <> 0.
    MESSAGE I166(ZHELP).
    G_ERROR_FUNDC = 'X'.
    CALL SCREEN 100.
  ENDIF.

  IF OLD_OK_CODE = 'CHANGE' OR
     OLD_OK_CODE = 'RELEASE' OR
     OLD_OK_CODE = 'APPROVE'.

    SELECT SINGLE DOCNO FROM ZIC_PREP_ROLEREQ
                    INTO L_DOCNO WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO.

    IF SY-SUBRC <> 0.
      MESSAGE I167(ZHELP).
      G_ERROR_FUNDC = 'X'.
      CALL SCREEN 100.
    ENDIF.

  ENDIF.

  IF G_VAL_ERR = 'X'.
    CLEAR G_VAL_ERR.
    MESSAGE I118(ZHELP).
    CALL SCREEN 100.
  ENDIF.

  IF ZIC_PREP_ROLEREI-REJ_FL = ''.

    IF OLD_OK_CODE = 'APPROVE' AND
                      ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
      IF G_USER = 'IM' OR G_USER = 'L1'.
      ELSE.
        MESSAGE E048(ZHELP).
      ENDIF.
    ENDIF.

  ENDIF.

  PERFORM CHECK_TEL.

ENDFORM.                    " validations1


*---------------------------------------------------------------------*
*       FORM destroy_ctrl                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM DESTROY_CTRL.

  IF NOT FLAG2 IS INITIAL.
    CLEAR : FLAG2, FLAG1.
    CALL METHOD GV_TEXT_EDITOR1->FREE.
    CALL METHOD GV_TEXT_EDITOR2->FREE.
  ENDIF.

  IF NOT FLAG1 IS INITIAL.
    CLEAR FLAG1.
    CALL METHOD GV_TEXT_EDITOR1->FREE.
  ENDIF.

  CLEAR:GV_TEXT_EDITOR1,GV_TEXT_EDITOR2.

  PERFORM UNLOCK_RECORD.

ENDFORM.                    " destroy_ctrl
*&---------------------------------------------------------------------*
*&      Form  delete_request
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DELETE_REQUEST.

  DATA : L_CHOICE.
  " Begin of <RD1K960036>.
*    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Are you sure, you want to delete the Document? '
*              TITEL          = ''
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = l_choice.

  DATA : L_GET3(1) TYPE C.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TEXT_QUESTION         = 'Are you sure, you want to delete the Document? '
      DISPLAY_CANCEL_BUTTON = ' '
      START_COLUMN          = 25
      START_ROW             = 6
    IMPORTING
      ANSWER                = L_GET3
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC = 0.
    CASE L_GET3.
      WHEN '1'.
        MOVE 'J' TO L_CHOICE.
      WHEN '2'.
        MOVE 'N' TO L_CHOICE.
    ENDCASE.
  ENDIF.
  " End of <RD1K960036>.

  IF L_CHOICE = 'J'.
    CLEAR L_CHOICE.

**************************************

    ZIC_PREP_ROLEREQ-MANDT = SY-MANDT.

    DELETE ZIC_PREP_ROLEREQ FROM ZIC_PREP_ROLEREQ.

    IF SY-SUBRC = 0.

      PERFORM DELETE_ITEMS.


      IF ZIC_PREP_ROLEREQ-LONG_TEXT_FL <> ''.
        PERFORM DELETE_CORS_TEXT.
      ENDIF.

      PERFORM CLEAR.
      PERFORM UNLOCK_RECORD.
      CALL SCREEN 100.

    ELSE.

      MESSAGE I057(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.

    ENDIF.

  ELSE.

  ENDIF.

ENDFORM.                    " delete_request
*&---------------------------------------------------------------------*
*&      Form  delete_items
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DELETE_ITEMS.

  LOOP AT G_TABCTRL100_ITAB INTO G_TABCTRL100_WA.

    MOVE-CORRESPONDING G_TABCTRL100_WA TO WA_ITEMTAB.
    WA_ITEMTAB-MANDT = SY-MANDT.
    APPEND WA_ITEMTAB TO IST_ITEMTAB.

  ENDLOOP.

  DELETE ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

  IF SY-SUBRC = 0.
    MESSAGE I120(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
  ENDIF.

ENDFORM.                    " delete_items
*&---------------------------------------------------------------------*
*&      Form  delete_cors_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DELETE_CORS_TEXT.

  DATA : L_NAME LIKE THEAD-TDNAME.

  L_NAME = ZIC_PREP_ROLEREQ-DOCNO.

  CALL FUNCTION 'DELETE_TEXT'
    EXPORTING
      CLIENT    = SY-MANDT
      ID        = '0001'
      LANGUAGE  = SY-LANGU
      NAME      = L_NAME
      OBJECT    = 'ZHELP'
*     SAVEMODE_DIRECT = ' '
*     TEXTMEMORY_ONLY = ' '
*     LOCAL_CAT = ' '
    EXCEPTIONS
      NOT_FOUND = 1
      OTHERS    = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " delete_cors_text
*&---------------------------------------------------------------------*
*&      Form  verify
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VERIFY.

  DATA L_CHOICE.
  CLEAR L_CHOICE.
  " Begin of <RD1K960036>.
*  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*      EXPORTING
*               TEXTLINE1      = 'Request already released Flags will be cancelled? '
*           TITEL          = 'RESET'
*           START_COLUMN   = 25
*           START_ROW      = 6
*           CANCEL_DISPLAY = ''
*           DEFAULTOPTION = 'N'
*      IMPORTING
*           ANSWER         = l_choice.

  DATA : L_GET5(1) TYPE C.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = 'RESET '
      TEXT_QUESTION         = 'Request already released Flags will be cancelled? '
      DEFAULT_BUTTON        = '2'
      DISPLAY_CANCEL_BUTTON = ' '
      START_COLUMN          = 25
      START_ROW             = 6
    IMPORTING
      ANSWER                = L_GET5
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC = 0.
    CASE L_GET5.
      WHEN '1'.
        MOVE 'J' TO L_CHOICE.
      WHEN '2'.
        MOVE 'N' TO L_CHOICE.
    ENDCASE.
  ENDIF.
  " End of <RD1K960036>.

  IF L_CHOICE = 'J'.

    CLEAR ZIC_PREP_ROLEREQ-REQ_CR_FL.
    CLEAR ZIC_PREP_ROLEREQ-REQ_APP_FL.
    CLEAR ZIC_PREP_ROLEREQ-REQ_APP0_FL.
    CLEAR ZIC_PREP_ROLEREQ-REQ_APP1_FL.
    ZIC_PREP_ROLEREQ-STATUS = 'IC'.
    PERFORM SAVE_REQUEST.
**20/03/2006
    G_APP_REL = 'X'.
    CLEAR L_CHOICE.

  ELSE.

    PERFORM CLEAR.
    PERFORM UNLOCK_RECORD.
    CALL SCREEN 100.

  ENDIF.

ENDFORM.                    " verify
*&---------------------------------------------------------------------*
*&      Form  check_items_save
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE.
  IF OLD_OK_CODE <> 'DISPLAY' .

    IF OLD_OK_CODE = 'CRCROLES' OR ZIC_PREP_ROLEREQ-CRC_FL = 'X'.

      SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
 WHERE ROLE_TYPE =
 WA_ITEMTAB-ROLE_NAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      IF SY-SUBRC = 0.

        IF ZMM_PREP_ROLECRC+0(1) = 'C'
*Begin of <RD1K962817>.
           OR ZMM_PREP_ROLECRC+0(1) = 'N'.
*End of <RD1K962817>.

          IF ZMM_PREP_ROLECRC-PLANT = 'X' AND
              WA_ITEMTAB-PLANT IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
            ROLLBACK WORK.
            MESSAGE I084(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.

          IF ZMM_PREP_ROLECRC-P_GRP = 'X' AND
             WA_ITEMTAB-GRP IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-P_GRP'.
            ROLLBACK WORK.
            MESSAGE I085(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.

          IF ZMM_PREP_ROLECRC-APP_LEVEL = 'X' AND
            WA_ITEMTAB-APPROVER IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-APPROVER'.
            ROLLBACK WORK.
            MESSAGE I096(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.
**
        ELSE.
*          G_FIELD = 'ZIC_PREP_ROLEREI-ROLE_NAME'.     "" commented by hiren
*          ROLLBACK WORK.
*          MESSAGE I197(ZHELP).
*          CLEAR OKCODE_100.
*          CALL SCREEN 100.
        ENDIF.

      ENDIF.

    ELSE.

      SELECT SINGLE * FROM ZMM_PREP_ROLEDES WHERE ROLE_TYPE =
                                                  WA_ITEMTAB-ROLE_NAME.
      IF SY-SUBRC = 0.

        IF ZMM_PREP_ROLEDES-PLANT = 'X' AND
                       ( OLD_OK_CODE = 'APPROVE' OR
                      OLD_OK_CODE = 'RELEASE' OR
                      OLD_OK_CODE = 'CHANGE' OR
                      OLD_OK_CODE = 'CREATE' OR
                      OLD_OK_CODE = 'CROSSCO' ) AND
                      NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

          IF WA_ITEMTAB-PLANT IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
            ROLLBACK WORK.
            MESSAGE I084(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.
        ENDIF.

        IF ZMM_PREP_ROLEDES-P_GRP = 'X' AND
                       ( OLD_OK_CODE = 'APPROVE' OR
                      OLD_OK_CODE = 'RELEASE' OR
                      OLD_OK_CODE = 'CHANGE'  OR
                      OLD_OK_CODE = 'CREATE'  OR
                      OLD_OK_CODE = 'CROSSCO' ) AND
                      NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

          IF WA_ITEMTAB-GRP IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-GRP'.
            ROLLBACK WORK.
            MESSAGE I085(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.
        ENDIF.

        IF ZMM_PREP_ROLEDES-S_LOC = 'X' AND
                       ( OLD_OK_CODE = 'APPROVE' OR
                      OLD_OK_CODE = 'RELEASE' OR
                      OLD_OK_CODE = 'CHANGE' OR
                      OLD_OK_CODE = 'CREATE' OR
                      OLD_OK_CODE = 'CROSSCO' ) AND
                      NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

          IF WA_ITEMTAB-SLOC IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-SLOC'.
            ROLLBACK WORK.
            MESSAGE I090(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.
        ENDIF.

        IF ZMM_PREP_ROLEDES-R_LOC = 'X' AND
                       ( OLD_OK_CODE = 'APPROVE' OR
                      OLD_OK_CODE = 'RELEASE' OR
                      OLD_OK_CODE = 'CHANGE' OR
                      OLD_OK_CODE = 'CREATE' OR
                      OLD_OK_CODE = 'CROSSCO' ) AND
                      NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

          IF WA_ITEMTAB-RECEIPT_LOC IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.
            ROLLBACK WORK.
            MESSAGE I095(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.
        ENDIF.

        IF ZMM_PREP_ROLEDES-APP_LEVEL = 'X' AND
                       ( OLD_OK_CODE = 'APPROVE' OR
                      OLD_OK_CODE = 'RELEASE' OR
                      OLD_OK_CODE = 'CHANGE' OR
                      OLD_OK_CODE = 'CREATE' OR
                      OLD_OK_CODE = 'CROSSCO' ) AND
                      NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

          IF WA_ITEMTAB-APPROVER IS INITIAL.
            G_FIELD = 'ZIC_PREP_ROLEREI-APPROVER'.
            ROLLBACK WORK.
            MESSAGE I096(ZHELP) WITH G_I.
            CLEAR OKCODE_100.
            CALL SCREEN 100.
          ENDIF.
        ENDIF.

      ENDIF.

    ENDIF.

  ENDIF.
**  if wa_itemtab-rej_fl is initial.
**** Header level changes for integration
**    perform validate_role_approval_level.
**  endif.
** Line item changes for integration call diffrent subs ( def 110 )
  PERFORM VALIDATE_LINEITEM_DATAX.
ENDFORM.                    " check_items_save
*&---------------------------------------------------------------------*
*&      Form  verify1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VERIFY1.

  DATA : L_CHOICE.
  CLEAR L_CHOICE.
  " Begin of <RD1K960036>.
*  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*      EXPORTING
*               TEXTLINE1      = 'If u cancel release, u can change data else go in display mode'
*               TEXTLINE2      = '& just do correspondence without cancelling release'
*           TITEL          = 'Do you want to cancel release?'
*           START_COLUMN   = 25
*           START_ROW      = 6
*           CANCEL_DISPLAY = ''
*           DEFAULTOPTION = 'N'
*      IMPORTING
*           ANSWER         = l_choice.

  DATA : L_GET6(1) TYPE C.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = 'Do you want to cancel release? '
      TEXT_QUESTION         = 'If u cancel release, u can change data else go in display mode'
                              & ' & just do correspondence without cancelling release.'
      DEFAULT_BUTTON        = '2'
      DISPLAY_CANCEL_BUTTON = ' '
      START_COLUMN          = 25
      START_ROW             = 6
    IMPORTING
      ANSWER                = L_GET6
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC = 0.
    CASE L_GET6.
      WHEN '1'.
        MOVE 'J' TO L_CHOICE.
      WHEN '2'.
        MOVE 'N' TO L_CHOICE.
    ENDCASE.
  ENDIF.
  " End of <RD1K960036>.

  IF L_CHOICE = 'J'.

    OLD_OK_CODE = 'CHANGE'.
    CLEAR L_CHOICE.

  ELSE.

    OLD_OK_CODE = 'DISPLAY'.
    CLEAR L_CHOICE.

  ENDIF.

ENDFORM.                                                    " verify1
*&---------------------------------------------------------------------*
*&      Form  check_tel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_TEL.

  IF    ( ( OLD_OK_CODE = 'DISPLAY' OR OLD_OK_CODE = 'CHANGE' OR
         OLD_OK_CODE = 'DELETE'
         OR OLD_OK_CODE = 'RELEASE' OR OLD_OK_CODE = 'APPROVE' )
         AND G_HD_COPIED = 'X' )
         OR ( OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' ).
    DATA : TEL_LEN TYPE I.
    TEL_LEN = STRLEN( ZIC_PREP_ROLEREQ-TELNO ).
    IF  ZIC_PREP_ROLEREQ-TELNO CN ' 0123456789-'.
      MESSAGE I097(ZHELP).
      CALL SCREEN 100.
    ELSE.
      IF TEL_LEN < 7.
        MESSAGE I098(ZHELP).
        CALL SCREEN 100.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " check_tel
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX.
*--------Added by Manisha bh.Dt:09.02.2018--------*
  TYPES : BEGIN OF TY_BUKRS,
            WERKS LIKE ZD_T001W_BUKRS-WERKS,
            NAME1 LIKE ZD_T001W_BUKRS-NAME1,
          END OF TY_BUKRS.

  DATA   : L_ZAREA LIKE ZMM_CONSM-ZAREA.
  DATA   : WA_T001L LIKE T001L.
  DATA   : IT_T001L TYPE TABLE OF T001L WITH HEADER LINE.

  DATA   : IT_BUKRS TYPE TABLE OF TY_BUKRS WITH HEADER LINE. "Added by Manisha bh.Dt:09.02.2018

  DATA : IT_RECPT TYPE STANDARD TABLE OF ZMM_LOCATION.
  DATA : WA_RECPT LIKE ZMM_LOCATION.
*-----------------------------------------------------------*
  IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.

* Begin of <RD1K981840>
*concatenate '000' ZIC_PREP_ROLEREQ-userid into cpf_lfb1.
    CPF_LFB1 = ZIC_PREP_ROLEREQ-USERID.
* End of <RD1K981840>

**---------- Changes Start date 24.06.2016 11:49:02-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .

    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
               D~DISC_CD AS DISC_CD
                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
            FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                     ON C~DESIGNO = D~DESIG_CODE AND
                         C~R_P_CD  = D~R_P_CD AND
                         C~VERSION = D~VERSION )
                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                            A~SPRPS = ' ' AND
                            A~ENDDA = '99991231' AND
                            C~SPRPS = ' ' AND
                            C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:49:02-----------------


    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER

***START OF COMMENT <RD1K983325>   CR: 30007580  dt: 05.04.2013.
*      G_CCODE = ist_data-bukrs.
***end OF COMMENT <RD1K983325>.

**code added by CAB_AMITMOZA  <RD1K983325>   CR: 30007580  dt: 05.04.2013.
      G_CCODE =  ZIC_PREP_ROLEREQ-CCODE.
**code end by CAB_AMITMOZA  <RD1K983325>

    ENDIF.

  ELSE.

    G_CCODE = ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL110_ITAB INTO G_TABLCTRL110_WA.

    IF OLD_OK_CODE = 'CRCROLES' OR ZIC_PREP_ROLEREQ-CRC_FL = 'X'.

*** 15/05/2007
      SELECT * FROM ZMM_PREP_CRCDESG UP TO 1 ROWS
 WHERE ROLE_TYPE =
 ZIC_PREP_ROLEREI-ROLE_NAME AND ROLE_TYPE_EX = ZIC_PREP_ROLEREI-ROLE_TYPE_EX
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      IF SY-SUBRC <> 0.
        ROLLBACK WORK.
        MESSAGE E200(ZHELP).
      ELSE.
*** 31/05/2007
        IF NOT ZMM_PREP_CRCDESG-ROLE_POS IS INITIAL.
          SELECT SINGLE * FROM AGR_USERS WHERE
                   UNAME = ZIC_PREP_ROLEREQ-USERID AND
                   AGR_NAME = ZMM_PREP_CRCDESG-ROLE_POS.
          IF SY-SUBRC = 0.
            ROLLBACK WORK.
            PERFORM MESSAGE1.
            LEAVE PROGRAM.
          ELSE.
            ROLLBACK WORK.
            PERFORM MESSAGE2.
            LEAVE PROGRAM.
          ENDIF.
        ENDIF.
      ENDIF.
***
      SELECT SINGLE * FROM ZMM_PREP_ROLECRC WHERE ROLE_TYPE =
                      G_TABLCTRL110_WA-ROLE_NAME.

      IF SY-SUBRC <> 0.
        ROLLBACK WORK.
        MESSAGE E117(ZHELP).
      ENDIF.

    ELSE.
      SELECT SINGLE * FROM ZMM_PREP_ROLEDES WHERE ROLE_TYPE =
                      G_TABLCTRL110_WA-ROLE_NAME.
      IF SY-SUBRC <> 0.
        ROLLBACK WORK.
        MESSAGE E118(ZHELP).
      ENDIF.

    ENDIF.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.

      IF OLD_OK_CODE = 'CRCROLES'.

      ELSE.

        IF ZMM_PREP_ROLEDES-MM_DISC_FLAG = 'X'.

          IF ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
          ELSE.
            ROLLBACK WORK.
            MESSAGE E081(ZHELP) WITH G_TABLCTRL110_WA-ROLE_NAME.
          ENDIF.

        ENDIF.

      ENDIF.

*  endif.

      IF NOT G_TABLCTRL110_WA-PLANT IS INITIAL.

        SELECT * FROM ZD_T001W_BUKRS INTO CORRESPONDING FIELDS OF
                   TABLE IT_BUKRS  WHERE BUKRS = ZIC_PREP_ROLEREQ-CCODE
                                      AND WERKS = G_TABLCTRL110_WA-PLANT.
        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE E068(ZHELP) WITH G_TABLCTRL110_WA-ROLE_NAME.

        ENDIF.

      ENDIF.


************finding group*******************

      REFRESH : IT_COND, IT_T024, IT_T024_1.
*  clear   : it_cond, it_t024, it_t024_1.
      CLEAR   : WA_T024.
*  concatenate 'EKGRP'  'LIKE'  into g_line1  separated by
*  space.
*  IF G_CCODE = 'SBS' or G_CCODE = 'SBW'.
*    g_select = 'R%'.
*    g_select_flag = 'X'.
*  ENDIF.
**  IF G_CCODE = 'JOR'.
*  IF G_CCODE = 'DVP'.
*    g_select = 'L%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'ANK'.
*    g_select = 'A%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'BDA' or G_CCODE = 'BDW'.
*    g_select = 'B%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'CBY'.
*    g_select = 'C%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'AMD'.
*    g_select = 'D%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'MHN'.
*    g_select = 'E%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'JDH'.
*    g_select = 'G%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'RJY'.
*    g_select = 'K%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'SIL'.
*    g_select = 'S%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'AGT'.
*    g_select = 'T%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'MBP'.
*    g_select = 'W%'.
*    g_select_flag = 'X'.
*
*  ENDIF.
*  IF G_CCODE = 'KKL'.
*    g_select = 'M%'.
*    g_select_flag = 'X'.
*
*    concatenate g_line1+0(10)  '''' g_select '''' into g_line1 .
*    append g_line1 to it_cond.
*    select * from t024 into table it_t024 where (it_cond).
*    refresh it_cond.
*    g_select = 'V%'.
*    concatenate  g_line1+0(10)  '''' g_select '''' into g_line1.
*    append g_line1 to it_cond.
*    select * from t024 into table it_t024_1 where (it_cond).
*    refresh it_cond.
*    append lines of it_t024_1 to it_t024.
*    refresh it_t024_1.
*
*  ENDIF.
**
*  if G_CCODE <> 'KKL'.
*    refresh it_cond.
*    concatenate  g_line1+0(10)  '''' g_select '''' into g_line1.
*    append g_line1 to it_cond.
*    select * from t024 into table it_t024 where (it_cond).
*    refresh it_cond.
*  endif.
*
*  if g_select_flag <> 'X'.
*    select * from t024 into table it_t024 where
*            ( ekgrp not between 'A' and 'EZZ' ) and
*            ( ekgrp not between 'K' and 'MZZ' ) and
*            ( ekgrp not between 'G' and 'GZZ' ) and
*            ( ekgrp not between 'R' and 'TZZ' ) and
*            ( ekgrp not between 'V' and 'WZZ' ).
*  endif.
*
*
* if  g_TABLCTRL110_wa-role_name = 'M6' or
*     g_TABLCTRL110_wa-role_name = 'M7' or
*     g_TABLCTRL110_wa-role_name = 'M8'.
*
* else.
*
*      if ZIC_PREP_ROLEREQ-DISC_MM_FLAG <> 'X'.
*
*            loop at it_t024 into wa_t024.
*
*             l_ekgrp = wa_t024-ekgrp.
*
*              if l_ekgrp+1(1) between '0' and 'A'.
*                delete it_t024.
*              endif.
*
*          endloop.
*
*
*      else.
*
*          loop at it_t024 into wa_t024.
*
*             l_ekgrp = wa_t024-ekgrp.
*
*              if l_ekgrp+1(1) < '0'  or
*              l_ekgrp+1(1) > 'A'.
*                delete it_t024.
*              endif.
*
*          endloop.
*
*      endif.
*
* endif.
*
**
      """""""""""""""""""""""""""""
      """"""""""""""""""""""""""""""""""""
      IF G_TABLCTRL110_WA-ROLE_NAME = 'M6' OR
          G_TABLCTRL110_WA-ROLE_NAME = 'M7' OR
          G_TABLCTRL110_WA-ROLE_NAME = 'M8'.
        CONCATENATE '%' G_CCODE '%' INTO G_LINE1.
        SELECT * FROM T024 INTO TABLE IT_T024 WHERE TELFX LIKE G_LINE1.
      ELSE.
        IF ZIC_PREP_ROLEREQ-DISC_MM_FLAG <> 'X'.
          CONCATENATE '%' G_CCODE '%' 'IND' '%'
          INTO G_LINE1.
          SELECT * FROM T024 INTO TABLE IT_T024 WHERE TELFX LIKE G_LINE1.
        ELSE.
          CONCATENATE  '%' G_CCODE '%' 'MM' '%'
          INTO G_LINE1.
          SELECT * FROM T024 INTO TABLE IT_T024 WHERE TELFX LIKE G_LINE1.
        ENDIF.
      ENDIF.

**
      IF  NOT G_TABLCTRL110_WA-GRP IS INITIAL.

        LOOP AT IT_T024 INTO WA_T024.

          IF G_TABLCTRL110_WA-GRP = WA_T024-EKGRP.
            GRP_FLAG = 'X'.
          ENDIF.

        ENDLOOP.

        IF GRP_FLAG = 'X'.
          CLEAR GRP_FLAG.
        ELSE.
          G_E_FL = 'X'.
          G_READ_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-GRP'.
          ROLLBACK WORK.
          MESSAGE I069(ZHELP).
          CALL SCREEN 100.

        ENDIF.

      ENDIF.

***************************

      CLEAR : L_ZAREA, WA_T001L.
      REFRESH IT_T001L.

      IF ( G_TABLCTRL110_WA-ROLE_NAME = 'M13' OR
         G_TABLCTRL110_WA-ROLE_NAME = 'M14' OR
          G_TABLCTRL110_WA-ROLE_NAME = 'M16' OR
          G_TABLCTRL110_WA-ROLE_NAME = 'M18' OR
          G_TABLCTRL110_WA-ROLE_NAME = 'M19' ) AND
          NOT G_TABLCTRL110_WA-PLANT IS INITIAL.

        SELECT * FROM T001L INTO CORRESPONDING FIELDS OF
                     TABLE IT_T001L  WHERE WERKS = G_TABLCTRL110_WA-PLANT.

        IF  SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE E074(ZHELP).

        ENDIF.

      ENDIF.

      IF ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.

        LOOP AT IT_T001L INTO WA_T001L.

          SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

          IF SY-SUBRC = 0.

            IF L_ZAREA+0(1) <> 'M'.
              DELETE IT_T001L.
            ENDIF.

          ELSE.

            DELETE IT_T001L.

          ENDIF.

        ENDLOOP.

      ELSE.

        LOOP AT IT_T001L INTO WA_T001L.

          SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

          IF SY-SUBRC = 0.

            IF L_ZAREA+0(1) = 'M'.
              DELETE IT_T001L.
            ENDIF.

          ELSE.

            DELETE IT_T001L.

          ENDIF.

        ENDLOOP.

      ENDIF.

      IF  NOT G_TABLCTRL110_WA-SLOC IS INITIAL.

        LOOP AT IT_T001L INTO WA_T001L.

          IF G_TABLCTRL110_WA-SLOC = WA_T001L-LGORT.
            LOC_FLAG = 'X'.
          ENDIF.

        ENDLOOP.

        IF LOC_FLAG = 'X'.
          CLEAR LOC_FLAG.
        ELSE.
** cab_ajit 07.02.2006
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-SLOC'.
          ROLLBACK WORK.
          MESSAGE E073(ZHELP).

        ENDIF.

      ENDIF.


***************************

      CLEAR WA_RECPT.
      REFRESH IT_RECPT.

      IF ( G_TABLCTRL110_WA-ROLE_NAME = 'M12' OR
         G_TABLCTRL110_WA-ROLE_NAME = 'M17' ) AND
         NOT G_TABLCTRL110_WA-RECEIPT_LOC IS INITIAL.

        SELECT * FROM ZMM_LOCATION INTO TABLE IT_RECPT.

        IF G_TABLCTRL110_WA-ROLE_NAME = 'M12'.

          LOOP AT IT_RECPT INTO WA_RECPT.

            IF WA_RECPT-LOCCG <> 'RL'.
              DELETE IT_RECPT.
            ENDIF.

          ENDLOOP.

        ENDIF.


        IF G_TABLCTRL110_WA-ROLE_NAME = 'M17'.

          LOOP AT IT_RECPT INTO WA_RECPT.

            IF WA_RECPT-LOCCG <> 'CF'.
              DELETE IT_RECPT.
            ENDIF.

          ENDLOOP.

        ENDIF.

      ENDIF.

      IF  NOT G_TABLCTRL110_WA-RECEIPT_LOC IS INITIAL.

        LOOP AT IT_RECPT INTO WA_RECPT.

          IF G_TABLCTRL110_WA-RECEIPT_LOC = WA_RECPT-LOCCD.
            LOC_FLAG = 'X'.
          ENDIF.

        ENDLOOP.

        IF LOC_FLAG = 'X'.
          CLEAR LOC_FLAG.
        ELSE.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.
          ROLLBACK WORK.
          MESSAGE E075(ZHELP).

        ENDIF.

      ENDIF.


*****************************

    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax
*&---------------------------------------------------------------------*
*&      Form  attach_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ATTACH_FILES.
  DATA LS_SODOCCHGI1 TYPE SODOCCHGI1.
  CLEAR G_ATT_FILES_WA.
  REFRESH G_ATT_FILES.

  G_ATT_FILES_WA-LOGSYS = ZIC_PREP_ROLEREQ-DOCNO+2(10).
  G_ATT_FILES_WA-OBJTYPE = 'ATT'.
  G_ATT_FILES_WA-OBJKEY = '01'.

  APPEND G_ATT_FILES_WA TO G_ATT_FILES.

  CALL FUNCTION 'SO_WIND_ATTACHMENT_CREATE_API1'
    EXPORTING
      ATTACHMENT_DATA     = LS_SODOCCHGI1
      ATTACHMENT_TYPE     = 'DOC'
    TABLES
      APPLICATION_OBJECTS = G_ATT_FILES.


ENDFORM.                    " attach_files
*&---------------------------------------------------------------------*
*&      Form  list_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM LIST_FILES.

  G_ATT_FILES_WA-LOGSYS = ZIC_PREP_ROLEREQ-DOCNO+2(10).
  G_ATT_FILES_WA-OBJTYPE = 'ATT'.
  G_ATT_FILES_WA-OBJKEY = '01'.

  CALL FUNCTION 'SO_WIND_ATTACHMENT_LIST_API1'
    EXPORTING
      APPLICATION_OBJECT = G_ATT_FILES_WA
*     FUNCTION           = ' '
* TABLES
*     FUNC_EXCLUDE       =
    .

ENDFORM.                    " list_files
*&---------------------------------------------------------------------*
*&      Form  pop_up_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POP_UP_MESSAGE.
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      TITEL     = 'Choosing Location '
      TEXTLINE1 = 'It is understood that user has joined at new location & HR Data'
      TEXTLINE2 = 'is updated. Please choose appropriate current location?'
*     START_COLUMN = 25
*     START_ROW = 6
    .

ENDFORM.                    " pop_up_message
*&---------------------------------------------------------------------*
*&      Form  items_approval_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ITEMS_APPROVAL_CHECK.
  SELECT * FROM ZIC_PREP_ROLEREI INTO TABLE IST_ITEMTAB
  WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO.
  LOOP AT IST_ITEMTAB INTO WA_ITEMTAB.
    IF WA_ITEMTAB-REJ_FL IS INITIAL.
** Header level changes for integration
      PERFORM VALIDATE_ROLE_APPROVAL_LEVEL.
    ENDIF.
  ENDLOOP.
  CLEAR IST_ITEMTAB.
  REFRESH IST_ITEMTAB[].
  CLEAR WA_ITEMTAB.
**      if sy-subrc = 0.
** Messages to be checked modulewise in sub
  PERFORM CLEAR1.

  """"""""""""""""""""""""""""""
*  BREAK-POINT.
  """"""""""""""""""""""""""""""""""
  IF OLD_OK_CODE = 'CROSSCO' OR
        ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.

    IF OLD_OK_CODE = 'RELEASE' OR
        OLD_OK_CODE = 'CROSSCO' OR
        OLD_OK_CODE = 'CHANGE'.
** code added by CAB_AMITMOZA   CR:30007580    01.03.2013
      SELECT * FROM ZIC_PREP_ROLEREI UP TO 1 ROWS

 WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      IF ZIC_PREP_ROLEREI-MODULEID = 'OLM'.
        PERFORM POPUP_RELEASE_MESSAGE3.
      ELSE.
** code END by CAB_AMITMOZA   CR:30007580
        PERFORM POPUP_RELEASE_MESSAGE.
      ENDIF.
    ENDIF.

    IF OLD_OK_CODE = 'APPROVE' OR
       ZIC_PREP_ROLEREQ-STATUS = 'IF'.

      """"""""""""""""""
      "added by lipsy  for cross company  on 9.03.2015 RD1K996555
      IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
        IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' .

        ELSE.
          "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555
          """"""""""""""""""""""
**********************************************@
          PERFORM POPUP_APPROVE_MESSAGE.
**********************************************@
          """"""""""""""""""""""""""""""""
          "added by lipsy  for cross company  on 9.03.2015 RD1K996555
        ENDIF.
      ENDIF.
      "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555

      """""""""""""""""""""""""""
    ENDIF.

    """""""""""""""""""""""""
    "added by lipsy  for cross company  on 9.03.2015 RD1K996555
    IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
      IF   OLD_OK_CODE = 'APPROVE' AND ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' .

      ELSE.
        "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555

        """"""""""""""""""""""""""""""""""
        PERFORM POP_UP_CROSSCO_MESSAGE.

        """""""""""""""""""""""""""""""""""""
        "added by lipsy  for cross company  on 9.03.2015 RD1K996555
      ENDIF.
    ENDIF.
    ""end of addition by lipsy  for cross company on 9.03.2015 RD1K996555

    """"""""""""""""""""""""""""""""""""""

    .
*          message i113(zhelp) with ZIC_PREP_ROLEREQ-docno.
    SET PARAMETER ID 'ZREQNO'
       FIELD ZIC_PREP_ROLEREQ-DOCNO.

    """""""""""""""""""""""""""
    "added by lipsy  for cross company  on 9.03.2015 RD1K996555
    IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
      IF OLD_OK_CODE = 'APPROVE' AND ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' .

      ELSE.
        ""end of addition by lipsy  for cross company on 9.03.2015 RD1K996555

        """""""""""""""""""""""""""""""""""
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.





        """"""""""""""""""""""""""""""
        """""added by lipsy  for cross company  on 9.03.2015  RD1K996555
        """""""""""""""""""""
      ENDIF.
    ENDIF.
    IF OLD_OK_CODE = 'APPROVE' AND   ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' .
      IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
        """"""""""""
        PERFORM CREATE_ROLES.
      ENDIF.
    ENDIF.
    """""end of addition by lipsy  for cross company on 9.03.2015 RD1K996555
    """""""""""""""""""""""""""""""""
**********************************************    code added by Bipin shukla : on 22/12/2013 sab_bipin
    IF OLD_OK_CODE = 'CROSSCO' OR OLD_OK_CODE = 'CHANGE'.
      CLEAR : IT_TVARV.
      SELECT * FROM TVARVC INTO CORRESPONDING FIELDS OF TABLE IT_TVARV
      WHERE NAME = 'ZGRC_CALL'.
      IF IT_TVARV[] IS NOT INITIAL.
        READ TABLE IT_TVARV INTO WA_TVARV WITH KEY NAME = 'ZGRC_CALL'.
      ENDIF.

      IF WA_TVARV-LOW IS NOT INITIAL.
        LV_GRCCALL = WA_TVARV-LOW.
      ENDIF.

      IF SYST-SYSID = 'RD1'.

        LV5_RFC = 'GRDCLNT500'.

      ELSEIF SYST-SYSID = 'RQ1'.

        LV5_RFC = 'GRDCLNT500'.

      ELSEIF SYST-SYSID = 'RP1'.

        LV5_RFC = 'GRPCLNT500'.
      ENDIF.

      CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
        EXPORTING
          RFCDESTINATION = LV5_RFC "'GRDCLNT500'
        IMPORTING
          RFC_SUBRC      = LV_SUBRC.

      IF  LV_GRCCALL = 'X' AND LV_SUBRC = '0'.
*        MESSAGE I232(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
        CLEAR TXT1.
        CONCATENATE 'Risk Analysis in Progress for Doc.' ZIC_PREP_ROLEREQ-DOCNO INTO TXT1 SEPARATED BY SPACE.
        CALL FUNCTION 'POPUP_TO_INFORM'
          EXPORTING
            TITEL = 'Information'
            TXT1  = TXT1
            TXT2  = 'To view the report, Pls press ENTER'
*           TXT3  = ' '
*           TXT4  = ' '
          .

        REQNUM_EX = ZIC_PREP_ROLEREQ-DOCNO.
        EXPORT REQNUM_EX TO MEMORY ID 'REQNUM_IM'.
        PERFORM GRC_RISK_ANALYSIS.
        IMPORT GT_RDESC FROM MEMORY ID 'IM_GT_RDESC'.
        CALL TRANSACTION 'ZGRC_RESULT'.
        CLEAR REQNUM_EX.
      ENDIF.
    ENDIF.
**********************************************    code added by Bipin shukla : on 22/12/2013 sab_bipin

  ELSE.
    IF OLD_OK_CODE = 'CRCROLES' OR
      ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
      IF OLD_OK_CODE = 'RELEASE' OR
         OLD_OK_CODE = 'CRCROLES' OR
         OLD_OK_CODE = 'CHANGE'.
** code added by CAB_AMITMOZA   CR:30007580    01.03.2013
        SELECT * FROM ZIC_PREP_ROLEREI UP TO 1 ROWS

 WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
 ORDER BY PRIMARY KEY .
 ENDSELECT.
        IF ZIC_PREP_ROLEREI-MODULEID = 'OLM'.
          PERFORM POPUP_RELEASE_MESSAGE3.
        ELSE.
** code END by CAB_AMITMOZA   CR:30007580


**          PERFORM POPUP_RELEASE_MESSAGE.  " commented by ss on 14.9.21
**             Added by ss on 14.9.21

  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
    EXPORTING
      TITEL     = 'Approval Requirement'
      TEXTLINE1 = 'Kindly get the request approved by competent authority: L1'.
**   EOC by ss on 14.9.21

        ENDIF.
      ENDIF.
      IF OLD_OK_CODE = 'APPROVE' OR
         ZIC_PREP_ROLEREQ-STATUS = 'IF'.
        PERFORM POPUP_APPROVE_MESSAGE.
      ENDIF.
*      PERFORM POP_UP_CRC_MESSAGE.   " Commented by ss on 14.9.21


******************************      Added by ss on 14.9.21
    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      TITEL     = 'CRC Authorizations '
      TEXTLINE1 = 'Please attach the scanned copy with the request and '
      TEXTLINE2 = ' send email to SAP Core Team. '
*     START_COLUMN = 25
*     START_ROW = 6
    .

**************************      ,  EOC by ss on 14.9.21

*              message i119(zhelp) with ZIC_PREP_ROLEREQ-docno.
      MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      G_CRC_FL = 'X'.
***************************************************cab_dns********************************
      SET PARAMETER ID 'ZREQNO'
     FIELD ZIC_PREP_ROLEREQ-DOCNO.
*    MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
**********************************************    code added by Bipin shukla : on 22/12/2013 sab_bipin
      IF OLD_OK_CODE = 'CRCROLES' OR OLD_OK_CODE = 'CHANGE'.
        CLEAR : IT_TVARV.
        SELECT * FROM TVARVC INTO CORRESPONDING FIELDS OF TABLE IT_TVARV
        WHERE NAME = 'ZGRC_CALL'.
        IF IT_TVARV[] IS NOT INITIAL.
          READ TABLE IT_TVARV INTO WA_TVARV WITH KEY NAME = 'ZGRC_CALL'.
        ENDIF.

        IF WA_TVARV-LOW IS NOT INITIAL.
          LV_GRCCALL = WA_TVARV-LOW.
        ENDIF.

        IF SYST-SYSID = 'RD1'.

          LV5_RFC = 'GRDCLNT500'.

        ELSEIF SYST-SYSID = 'RQ1'.

          LV5_RFC = 'GRDCLNT500'.

        ELSEIF SYST-SYSID = 'RP1'.

          LV5_RFC = 'GRPCLNT500'.
        ENDIF.

        CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
          EXPORTING
            RFCDESTINATION = LV5_RFC "'GRDCLNT500'
          IMPORTING
            RFC_SUBRC      = LV_SUBRC.

        IF  LV_GRCCALL = 'X' AND LV_SUBRC = '0'.
*        MESSAGE I232(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
          CLEAR TXT1.
          CONCATENATE 'Risk Analysis in Progress for Doc.' ZIC_PREP_ROLEREQ-DOCNO INTO TXT1 SEPARATED BY SPACE.
          CALL FUNCTION 'POPUP_TO_INFORM'
            EXPORTING
              TITEL = 'Information'
              TXT1  = TXT1
              TXT2  = 'To view the report, Pls press ENTER'
*             TXT3  = ' '
*             TXT4  = ' '
            .

          REQNUM_EX = ZIC_PREP_ROLEREQ-DOCNO.
          EXPORT REQNUM_EX TO MEMORY ID 'REQNUM_IM'.
          PERFORM GRC_RISK_ANALYSIS.
          IMPORT GT_RDESC FROM MEMORY ID 'IM_GT_RDESC'.
          CALL TRANSACTION 'ZGRC_RESULT'.
          CLEAR REQNUM_EX.
        ENDIF.
      ENDIF.
**********************************************    code added by Bipin shukla : on 22/12/2013 sab_bipin

***************************************************cab_dns********************************

    ELSE.
      IF OLD_OK_CODE = 'RELEASE'.
** code added by CAB_AMITMOZA   CR:30007580    01.03.2013
        SELECT * FROM ZIC_PREP_ROLEREI UP TO 1 ROWS

 WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
 ORDER BY PRIMARY KEY .
 ENDSELECT.
        IF ZIC_PREP_ROLEREI-MODULEID = 'OLM'.
          PERFORM POPUP_RELEASE_MESSAGE3.
        ELSE.
** code END by CAB_AMITMOZA   CR:30007580
          PERFORM POPUP_RELEASE_MESSAGE.
        ENDIF.
        SET PARAMETER ID 'ZREQNO'
          FIELD ZIC_PREP_ROLEREQ-DOCNO.
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ELSEIF OLD_OK_CODE = 'APPROVE'.
** 13/04/07
        IF MODULE_CHANGED_FLAG <> 'X'.

          """""""""""""""""""""""""
          "added by lipsy on 23.02.2015 for getting  requests assigned simultaneously after approval
          "with less message RD1K996042


          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*commented by lipsy on 4.03.2015 for getting  requests assigned simultaneously after approval
          "with less message RD1K996555

*         IF  zic_prep_rolerei-moduleid = 'MM' or zic_prep_rolerei-moduleid = 'OLM'.

*end of comment by lipsy on 4.03.2015 for getting  requests assigned simultaneously after approval
          "with less message RD1K996555
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          """"""""""""""""""""""""""""""""""""""""
*added by lipsy on 4.03.2015 for getting  requests assigned simultaneously after approval
          "with less message RD1K996555

          IF  ZIC_PREP_ROLEREI-MODULEID = 'MM' OR ZIC_PREP_ROLEREI-MODULEID = 'OLM' OR ZIC_PREP_ROLEREI-MODULEID = 'SRM'.

*end of addition by lipsy on 4.03.2015 for getting  requests assigned simultaneously after approval
            "with less message RD1K996555
            """"""""""""""""""""""""
          ELSE.
            "end of addition by lipsy on 23.02.2015 for getting  requests assigned simultaneously after approval
            "with less message RD1K996042
            """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "commented by lipsy on 23.02.2015 for getting  requests assigned simultaneously after approval
            "with less message RD1K996042
*          .
            "end of comment by lipsy on 23.02.2015 for getting  requests assigned simultaneously after approval
            "with less message RD1K996042
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
********************************************************@
*            PERFORM POPUP_APPROVE_MESSAGE.
********************************************************@
            """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "added by lipsy on 23.02.2015 for getting  requests assigned simultaneously after approval
            "with less message RD1K996042
          ENDIF.
          "end of addition by lipsy on 23.02.2015 for getting  requests assigned simultaneously after approval
          "with less message RD1K996042
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "Added by lipsy on 13.02.2015 for getting  requests assigned simultaneously after approval
                                                            "RD1K996042
          IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
            """"""""""""

            """"""""""""""""
            PERFORM CREATE_ROLES.
          ELSEIF ZIC_PREP_ROLEREI-MODULEID = 'OLM'.
            PERFORM CREATE_ROLES_OLM.
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "added by lipsy on 4.03.2015 for getting  requests assigned simultaneously after approval
            "for srm RD1K996555
          ELSEIF ZIC_PREP_ROLEREI-MODULEID = 'SRM'.
            PERFORM CREATE_ROLES_SRM.

            "end of addition by lipsy on 4.03.2015 for getting  requests assigned simultaneously after approval
            "for srm RD1K996555
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
************************************************@
          ELSE.
            PERFORM CREATE_ROLES.
************************************************@
          ENDIF.
          "end of Addition by lipsy on 13.02.2015 for getting  requests assigned simultaneously after approval
                                                            "RD1K996042
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


****************************************** changes done by bipin shukla to sent mail

          IMPORT CRT_NAME FROM MEMORY ID 'CRT_NAME_RJ'.
          CLEAR : WA_URINFO , WA_UNAME , WA_APPINFO.

*          **---------- Changes Start date 24.06.2016 12:04:39-------------------
* SELECT SINGLE PERNR FROM PA0105 INTO WA_URINFO-PERNR WHERE USRID = CRT_NAME
*          AND USRTY = '0001'. "AND ENDDA = '31.12.9999'.

          SELECT PERNR FROM ZPA0105 INTO WA_URINFO-PERNR UP TO 1 ROWS WHERE USRID = CRT_NAME
 AND USRTY = '0001'
 ORDER BY PRIMARY KEY .
 ENDSELECT. "AND ENDDA = '31.12.9999'.
*          *---------- Changee  Ending Date 24.06.2016 12:04:39-----------------

*if WA_URINFO-PERNR is not INITIAL.
          IF SY-SUBRC EQ 0.

**---------- Changes Start date 24.06.2016 12:04:18-------------------
            SELECT USRID_LONG FROM ZPA0105 INTO WA_URINFO-USRID_LONG UP TO 1 ROWS WHERE PERNR = WA_URINFO-PERNR
 AND USRTY = '0010'
 ORDER BY PRIMARY KEY .
 ENDSELECT. " AND ENDDA = '31.12.9999'.
**---------- Changee  Ending Date 24.06.2016 12:04:18-----------------

          ENDIF.

          IF WA_URINFO-PERNR IS NOT INITIAL.

**---------- Changes Start date 24.06.2016 12:03:59-------------------
*      SELECT SINGLE *   FROM PA0002 INTO CORRESPONDING FIELDS OF WA_UNAME
*                  WHERE PERNR = WA_URINFO-PERNR.

            SELECT SINGLE *   FROM ZPA0002 INTO CORRESPONDING FIELDS OF WA_UNAME
                   WHERE PERNR = WA_URINFO-PERNR.
**---------- Changee  Ending Date 24.06.2016 12:03:59-----------------

          ENDIF.

**********************************************Get approver user name

**---------- Changes Start date 24.06.2016 12:05:27-------------------
*       SELECT SINGLE PERNR FROM PA0105 INTO WA_APPINFO-PERNR WHERE USRID = SY-UNAME
*          AND USRTY = '0001'. "AND ENDDA = '31.12.9999'.
*          IF SY-SUBCS EQ 0.
*            SELECT SINGLE *   FROM PA0002 INTO CORRESPONDING FIELDS OF WA_APPNAME
*                  WHERE PERNR = WA_APPINFO-PERNR.
*          ENDIF.

          SELECT PERNR FROM ZPA0105 INTO WA_APPINFO-PERNR UP TO 1 ROWS WHERE USRID = SY-UNAME
 AND USRTY = '0001'
 ORDER BY PRIMARY KEY .
 ENDSELECT. "AND ENDDA = '31.12.9999'.
          IF SY-SUBCS EQ 0.
            SELECT * FROM ZPA0002 INTO CORRESPONDING FIELDS OF WA_APPNAME UP TO 1 ROWS
 WHERE PERNR = WA_APPINFO-PERNR
 ORDER BY PRIMARY KEY .
 ENDSELECT.
          ENDIF.
**---------- Changee  Ending Date 24.06.2016 12:05:27-----------------


          CONCATENATE WA_APPNAME-NACHN WA_APPNAME-VORNA INTO LV_APPNAME SEPARATED BY SPACE.
**********************************************Get approver user name


          CONCATENATE 'Approval of Role Request No.' ZIC_PREP_ROLEREQ-DOCNO
        INTO DOCDATA-OBJ_DESCR SEPARATED BY SPACE.

          WA_OBJHEAD = 'Dear Sir/Madam,'.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.
          CLEAR WA_OBJHEAD.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.

          CONCATENATE 'Your Role Request No.' ZIC_PREP_ROLEREQ-DOCNO 'has been approved and sent to ICE Core Team for assignment'
          INTO  WA_OBJHEAD SEPARATED BY SPACE.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.
          CLEAR WA_OBJHEAD.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.

          WA_OBJHEAD = 'Please check your request for details'.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.
          CLEAR WA_OBJHEAD.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.

          CLEAR WA_OBJHEAD.

          APPEND WA_OBJHEAD TO GT_OBJHEAD.

          WA_OBJHEAD = 'Regards'.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.
          CLEAR WA_OBJHEAD.
          WA_OBJHEAD = LV_APPNAME.
          APPEND WA_OBJHEAD TO GT_OBJHEAD.
          CLEAR WA_OBJHEAD.




*      WA_RECLIST-RECEIVER  = 'bipin@sapcnorth.in'.
          WA_RECLIST-RECEIVER  = WA_URINFO-USRID_LONG.
          WA_RECLIST-REC_TYPE = 'U'.
          APPEND WA_RECLIST TO GT_RECLIST.
          WA_RECLIST-RECEIVER  = CRT_NAME.
          WA_RECLIST-REC_TYPE = 'B'.
          APPEND WA_RECLIST TO GT_RECLIST.

*** Creation of the entry for the document
          DESCRIBE TABLE GT_OBJHEAD LINES LV_TAB_LINES.
          CLEAR OBJPACK-TRANSF_BIN.
          OBJPACK-HEAD_START = 1.
          OBJPACK-HEAD_NUM = 0.
          OBJPACK-BODY_START = 1.
          OBJPACK-BODY_NUM = LV_TAB_LINES.
          OBJPACK-DOC_TYPE = 'RAW'.
          APPEND OBJPACK." TO LT_OBJPACK.
          CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
            EXPORTING
              DOCUMENT_DATA              = DOCDATA
              PUT_IN_OUTBOX              = 'X'
              COMMIT_WORK                = 'X'
            TABLES
              PACKING_LIST               = OBJPACK[]
*             OBJECT_HEADER              =
*             CONTENTS_BIN               =
              CONTENTS_TXT               = GT_OBJHEAD[]
*             CONTENTS_HEX               =
*             OBJECT_PARA                =
*             OBJECT_PARB                =
              RECEIVERS                  = GT_RECLIST[]
            EXCEPTIONS
              TOO_MANY_RECEIVERS         = 1
              DOCUMENT_NOT_SENT          = 2
              DOCUMENT_TYPE_NOT_EXIST    = 3
              OPERATION_NO_AUTHORIZATION = 4
              PARAMETER_ERROR            = 5
              X_ERROR                    = 6
              ENQUEUE_ERROR              = 7
              OTHERS                     = 8.
          IF SY-SUBRC EQ 0.
* Implement suitable error handling here
            MESSAGE 'Mail successfully sent to creator !!' TYPE 'S'.
          ENDIF.


****************************************** changes done by bipin shukla to sent mail
          MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
        ENDIF.
        SET PARAMETER ID 'ZREQNO'
          FIELD ZIC_PREP_ROLEREQ-DOCNO.
*                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
      ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE =
'CHANGE'.
** 13/04/07
        IF MODULE_CHANGED_FLAG <> 'X'.
** code added by CAB_AMITMOZA   CR:30007580    01.03.2013
          IF ZIC_PREP_ROLEREI-MODULEID = 'OLM'.
            PERFORM POPUP_RELEASE_MESSAGE2.
          ELSE.
** code end by CAB_AMITMOZA   CR:30007580
            PERFORM POPUP_RELEASE_MESSAGE1.
          ENDIF.
          MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
        ENDIF.
        SET PARAMETER ID 'ZREQNO'
          FIELD ZIC_PREP_ROLEREQ-DOCNO.
****************** code added by Bipin : 20/09/2013
********************************* start of chages by bipin : for risk analysis : 02/09/2013
        CLEAR : IT_TVARV.
        SELECT * FROM TVARVC INTO CORRESPONDING FIELDS OF TABLE IT_TVARV
        WHERE NAME = 'ZGRC_CALL'.
        IF IT_TVARV[] IS NOT INITIAL.
          READ TABLE IT_TVARV INTO WA_TVARV WITH KEY NAME = 'ZGRC_CALL'.
        ENDIF.
        IF WA_TVARV-LOW IS NOT INITIAL.
          LV_GRCCALL = WA_TVARV-LOW.
        ENDIF.

        IF SYST-SYSID = 'OCD'.

          LV6_RFC = 'GRDCLNT500'.

        ELSEIF SYST-SYSID = 'OCQ'.

          LV6_RFC = 'GRDCLNT500'.

        ELSEIF SYST-SYSID = 'OCP'.

          LV6_RFC = 'GRPCLNT500'.
        ENDIF.

        CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
          EXPORTING
            RFCDESTINATION = LV6_RFC "'GRDCLNT500'
*           RFCDESTINATION = 'GRPCLNT500TEST'    changes on 02.08.2014  CAB_DNS
          IMPORTING
*           MSGV1          =
*           MSGV2          =
            RFC_SUBRC      = LV_SUBRC.

*        DATA : LV_RFC TYPE BOOLEAN.
*
*        CALL FUNCTION 'CHECK_RFC_DESTINATION'
*          EXPORTING
*            I_DESTINATION                    = 'GRDCLNT500'
*         IMPORTING
*           E_USER_PASSWORD_INCOMPLETE       =  LV_RFC
        .

        IF  LV_GRCCALL = 'X' AND LV_SUBRC = '0'.
*        IF  LV_GRCCALL = 'X' AND LV_RFC IS NOT INITIAL.
*          MESSAGE I232(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
          CLEAR TXT1.
          CONCATENATE 'Risk Analysis in Progress for Doc.' ZIC_PREP_ROLEREQ-DOCNO INTO TXT1 SEPARATED BY SPACE.
          CALL FUNCTION 'POPUP_TO_INFORM'
            EXPORTING
              TITEL = 'Information'
              TXT1  = TXT1
              TXT2  = 'To view the report, Pls press ENTER'.

          REQNUM_EX = ZIC_PREP_ROLEREQ-DOCNO.
          EXPORT REQNUM_EX TO MEMORY ID 'REQNUM_IM'.
          PERFORM GRC_RISK_ANALYSIS.
          IMPORT GT_RDESC FROM MEMORY ID 'IM_GT_RDESC'.
*          IF GT_RDESC IS NOT INITIAL.
          CALL TRANSACTION 'ZGRC_RESULT'.
*          ELSE.
*          MESSAGE 'No risk found!!' TYPE 'I'.
*          ENDIF.
*          CLEAR GT_RDESC.
          CLEAR REQNUM_EX.
        ENDIF.
****************************** end of chages by bipin : for risk analysis : 02/09/2013
******************* code added by Bipin : 20/09/2013

*                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
      ELSEIF ZIC_PREP_ROLEREQ-STATUS = 'IF'.
        PERFORM POPUP_APPROVE_MESSAGE.
      ELSE.
        SET PARAMETER ID 'ZREQNO'
          FIELD ZIC_PREP_ROLEREQ-DOCNO.
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ENDIF.
  ENDIF.
**      endif.
ENDFORM.                    " items_approval_check
*&---------------------------------------------------------------------*
*&      Form  pop_up_crc_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POP_UP_CRC_MESSAGE.
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      TITEL     = 'CRC Authorizations '
      TEXTLINE1 = 'Please attach the scanned order copy with the request or '
      TEXTLINE2 = 'Please send order copy by fax to Head-ICE '
*     START_COLUMN = 25
*     START_ROW = 6
    .

ENDFORM.                    " pop_up_crc_message
*&---------------------------------------------------------------------*
*&      Form  pop_up_crossco_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POP_UP_CROSSCO_MESSAGE.
*Begin of <RD1K963151>.
*CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
*  EXPORTING
*   TITEL              = 'Cross Company Authorisations '
*   TEXTLINE1          = 'Please attach the scanned order copy with the request or '
*   TEXTLINE2          = 'Please send order copy by fax to Head-ICE '
**   START_COLUMN       = 25
**   START_ROW          = 6
  .
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      TITEL     = 'Cross Company Authorisations '
      TEXTLINE1 = 'Please attach the scanned order copy with the request. '.
*End of <RD1K963151>.
ENDFORM.                    " pop_up_crossco_message
*&---------------------------------------------------------------------*
*&      Form  validate_role_approval_level
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_ROLE_APPROVAL_LEVEL.

** Check approval module wise & line item wise

  SELECT SINGLE * FROM ZMM_PREP_ROLEGRP
       WHERE ROLE_TYPE = WA_ITEMTAB-ROLE_NAME.

  IF SY-SUBRC = 0.

    IF ZMM_PREP_ROLEGRP-APPROVER1 = 'L3' AND
                 G_APPROVER_LEVEL = 'L3'.

    ELSEIF ZMM_PREP_ROLEGRP-APPROVER1 = 'IM' AND
                 G_APPROVER_LEVEL = 'L3'.
      G_APPROVER_LEVEL = 'IM'.
    ELSEIF  ZMM_PREP_ROLEGRP-APPROVER1 = 'L1' AND
                 ( G_APPROVER_LEVEL = 'L3' OR
                   G_APPROVER_LEVEL = 'IM' ).
      G_APPROVER_LEVEL = 'L1'.
    ENDIF.

**** CAB_AJIT Approval check added on 11/12/2006
    IF OLD_OK_CODE = 'APPROVE'.
      IF WA_ITEMTAB-REJ_FL = '' AND ZIC_PREP_ROLEREQ-CRC_FL <> 'X'.

        IF SY-SUBRC = 0 AND OLD_OK_CODE = 'APPROVE'.
          IF ZMM_PREP_ROLEGRP-APPROVER1 = G_USER
             OR ZMM_PREP_ROLEGRP-APPROVER2 = G_USER
             OR ZMM_PREP_ROLEGRP-APPROVER3 = G_USER
         """""""""""""""""""""""""""
           "added by lipsy for l2 approver on 20.03.2015 RD1K996555
            OR ( MODULEID = 'SRM' AND ZMM_PREP_ROLEGRP-APPROVER1 = G_USER_L2 )
             "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
          """""""""""""""""""""""""
            .
          ELSE.

            IF OKCODE_100 = 'SAV'.
              IF ERR_FLG <> 'X'.
                ERR_FLG = 'X'.
                CLEAR : SY-UCOMM, OKCODE_100.
              ENDIF.
              ROLLBACK WORK.
              MESSAGE I047(ZHELP) WITH ZMM_PREP_ROLEGRP-ROLE_TYPE.
              CLEAR OKCODE_100.
              CALL SCREEN 100.
            ENDIF.
          ENDIF.
        ENDIF.

      ENDIF.
***

    ENDIF.

  ENDIF.

ENDFORM.                    " validate_role_approval_level
*&---------------------------------------------------------------------*
*&      Form  popup_release_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POPUP_RELEASE_MESSAGE.

  IF G_APPROVER_LEVEL = 'IM'.
    G_APPROVER_LEVEL = 'I/C MM'.
  ENDIF.

  """"""""""""""""""
  "added by lipsy for l2 approver on 20.03.2015 RD1K996555
  IF MODULEID = 'SRM' AND ZIC_PREP_ROLEREQ-DISC_MM_FLAG NE 'X'.

    """""""""""""""""""""""""""""
    "COMMENTED BY LIPSY ON 7.12.2015 RD1K999362
*  G_APPROVER_LEVEL = 'L2'.
    "END OF COMMENT BY LIPSY ON 7.12.2015 RD1K999362
    "ADDED BY LIPSY ON 7.12.2015  RD1K999362
    G_APPROVER_LEVEL = 'L3'.
    "END OF ADDITION BY LIPSY ON 7.12.2015 RD1K999362

  ENDIF.

  IF ( MODULEID = 'SRM' OR  MODULEID = 'MM' ) AND ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
    G_APPROVER_LEVEL = 'I/C MM'.
  ENDIF.

  IF ( MODULEID = 'MM' ) AND ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X' AND  ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
    G_APPROVER_LEVEL = 'L3'.
  ENDIF.

  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
  """"""""""""""



  CONCATENATE 'Kindly get the request approved by competent authority: '
  G_APPROVER_LEVEL ' or above' INTO G_APPROVE_TEXT.


  """"""""""""""""""""""""""""""
  "added by lipsy for l2 approver on 20.03.2015 RD1K996555



*  IF  moduleid = 'SRM' OR  moduleid = 'MM' OR   moduleid = 'OLM'.
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
    EXPORTING
      TITEL     = 'Approval Requirement'
      TEXTLINE1 = G_APPROVE_TEXT
*     TEXTLINE2 = 'Request for authorization will be routed to ICE core team only '
*     TEXTLINE3 = 'after requisite approval '
*     START_COLUMN = 15
*     START_ROW = 6
    .

*  ELSE.
  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555


  """"""""""""""""""""""""""""""""""""""""

*    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
*      EXPORTING
*        titel     = 'Approval Requirement'
*        textline1 = g_approve_text
*        textline2 = 'Request for authorization will be routed to OVL core team only '
*        textline3 = 'after requisite approval '
**       START_COLUMN = 15
**       START_ROW = 6
*      .
*
*    """"""""""""""""""""""""""""""""""
*    "added by lipsy for l2 approver on 20.03.2015 RD1K996555
*
*  ENDIF.

  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
  """"""""""""""""""""""""""""""""""""""""""""""""
  CLEAR : G_APPROVER_LEVEL, G_APPROVE_TEXT.
ENDFORM.                    " popup_release_message
*&---------------------------------------------------------------------*
*&      Form  popup_approve_message
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POPUP_APPROVE_MESSAGE.
*  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
*    EXPORTING
*      titel     = 'Request Processing'
*      textline1 = 'The request will now be processed by OVL core  team & '
*      textline2 = 'user will get updated message once the request is processed '
**     START_COLUMN = 15
**     START_ROW = 6
*    .
ENDFORM.                    " popup_approve_message
*&---------------------------------------------------------------------*
*&      Form  verify2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VERIFY2.
  IF ZIC_PREP_ROLEREQ-STATUS <> 'C'.
**
    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
      EXPORTING
        TITEL     = 'Request Status IR'
        TEXTLINE1 = 'Please go to display mode & reply the query of the OVL core team in '
        TEXTLINE2 = 'correspondence  &  save the request.  No re-release or approval reqd.'
        TEXTLINE3 = 'The request will go directly to ICE core team  for further processing.'.
    OLD_OK_CODE = 'DISPLAY'.
**
  ELSE.
    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
      EXPORTING
        TITEL     = 'Request Status C'
        TEXTLINE1 = 'Request is closed, you can not change anything now'
        TEXTLINE2 = 'No more processing of the request can be done'.
    OLD_OK_CODE = 'DISPLAY'.
**
  ENDIF.
ENDFORM.                                                    " verify2
*&---------------------------------------------------------------------*
*&      Form  popup_release_message1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POPUP_RELEASE_MESSAGE1.
  IF G_APPROVER_LEVEL = 'IM'.
    G_APPROVER_LEVEL = 'I/C MM'.
  ENDIF.

  """"""
  "added by lipsy for l2 approver on 20.03.2015 RD1K996555
  IF MODULEID = 'SRM' AND ZIC_PREP_ROLEREQ-DISC_MM_FLAG NE 'X'.
    """""""""""""""""
    "COMMENTED BY LIPSY ON 7.12.2015 RD1K999362

*  G_APPROVER_LEVEL = 'L2'.

    "END OF COMMENT BY LIPSY ON 7.12.2015 RD1K999362


    "ADDED BY LIPSY ON 7.12.2015 RD1K999362
    G_APPROVER_LEVEL = 'L3'.
    "END OF ADDITION BY LIPSY ON 7.12.2015 RD1K999362

  ENDIF.

  IF ( MODULEID = 'SRM' OR  MODULEID = 'MM' ) AND ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
    G_APPROVER_LEVEL = 'I/C MM'.
  ENDIF.

  IF ( MODULEID = 'MM' ) AND ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X' AND  ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
    G_APPROVER_LEVEL = 'L3'.
  ENDIF.

  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
  """""""""

*  CONCATENATE g_approver_level ' or above. Request  for  authorization will be routed to OVL core' INTO g_approve_text.


  """""""""""""""""""""""""""""""""""""""""""""""
  "added by lipsy for l2 approver on 20.03.2015 RD1K996555
*  IF  moduleid = 'SRM' OR  moduleid = 'MM' OR   moduleid = 'OLM'.
  CLEAR : G_APPROVE_TEXT.
  CONCATENATE G_APPROVER_LEVEL ' or above.' INTO G_APPROVE_TEXT.
*  ENDIF.



*  IF  moduleid = 'SRM' OR  moduleid = 'MM' OR   moduleid = 'OLM'.
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
    EXPORTING
      TITEL     = 'Approval Requirement'
      TEXTLINE1 = 'Kindly self release the  request  &  get it approved by competent authority:'
      TEXTLINE2 = G_APPROVE_TEXT
*     TEXTLINE3 = 'team only after requisite approval '
*     START_COLUMN = 15
*     START_ROW = 6
    .
*  ELSE.
  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
  """"""""""""""""""""""""""""""""""""""""""""""""""""

*    CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
*      EXPORTING
*        titel     = 'Approval Requirement'
*        textline1 = 'Kindly self release the  request  &  get it approved by competent authority:'
*        textline2 = g_approve_text
*        textline3 = 'team only after requisite approval '
**       START_COLUMN = 15
**       START_ROW = 6
*      .
*
*    """"""""""""""""""""""""""""""""""
*    "added by lipsy for l2 approver on 20.03.2015 RD1K996555
*
*  ENDIF.

  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
  """"""""""""""""""""""""""""""""""""""""""""""""


  CLEAR : G_APPROVER_LEVEL, G_APPROVE_TEXT.
ENDFORM.                    " popup_release_message1
*&---------------------------------------------------------------------*
*&      Form  clear1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLEAR1.

  CLEAR   : HELP_LIST_FLAG.
  REFRESH : IT_M_FISTB.
  CLEAR   : DYNNR.

ENDFORM.                                                    " clear1
*&---------------------------------------------------------------------*
*&      Form  insert_items_pm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_PM.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  SORT G_TABLCTRL111_ITAB
  BY ROLE_NAME PLANT SHOP_NO.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL111_ITAB
    COMPARING ROLE_NAME PLANT REJ_FL SHOP_NO.

  LOOP AT G_TABLCTRL111_ITAB INTO G_TABLCTRL111_WA.

    MOVE-CORRESPONDING G_TABLCTRL111_WA TO WA_ITEMTAB.

*    Perform check_items_save.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_MODULE_WISE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
*      delete from ZIC_PREP_ROLEREQ
*            where docno = ZIC_PREP_ROLEREQ-docno.
*      delete from zic_prep_rolerei
*            where docno = ZIC_PREP_ROLEREQ-docno and
*                   moduleid = moduleid.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

**      if sy-subrc = 0.
**** Messages to be checked modulewise in sub
**        perform clear1.
**        if old_ok_code = 'CROSSCO' or
**              ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
**
**              if old_ok_code = 'RELEASE' or
**                  old_ok_code = 'CROSSCO' or
**                  old_ok_code = 'CHANGE'.
**                  perform popup_release_message.
**               endif.
**
**               if old_ok_code = 'APPROVE' or
**                  ZIC_PREP_ROLEREQ-status = 'IF'.
**                  perform popup_approve_message.
**               endif.
**
**               perform pop_up_crossco_message.          .
***          message i113(zhelp) with ZIC_PREP_ROLEREQ-docno.
**               message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**
**          else.
**            if old_ok_code = 'CRCROLES' or
**              ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
**               if old_ok_code = 'RELEASE' or
**                  old_ok_code = 'CRCROLES' or
**                  old_ok_code = 'CHANGE'.
**                  perform popup_release_message.
**               endif.
**               if old_ok_code = 'APPROVE' or
**                  ZIC_PREP_ROLEREQ-status = 'IF'.
**                  perform popup_approve_message.
**               endif.
**               perform pop_up_crc_message.
***              message i119(zhelp) with ZIC_PREP_ROLEREQ-docno.
**               message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**               g_crc_fl = 'X'.
**            else.
**              if old_ok_code = 'RELEASE'.
**                perform popup_release_message.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              elseif old_ok_code = 'APPROVE'.
**.               perform popup_approve_message.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              elseif old_ok_code = 'CREATE' or old_ok_code = 'CHANGE'.
*.
**                perform popup_release_message1.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              elseif ZIC_PREP_ROLEREQ-status = 'IF'.
**                perform popup_approve_message.
**              else.
**                message i045(zhelp) with ZIC_PREP_ROLEREQ-docno.
**              endif.
**            endif.
**        endif.
**      endif.

    ENDIF.

  ENDIF.

ENDFORM.                    " insert_items_pm
***&--------------------------------------------------------------------
*-
***
***&      Form  check_items_save_pm
***&--------------------------------------------------------------------
*-
***
***       text
***---------------------------------------------------------------------
*-
***
***  -->  p1        text
***  <--  p2        text
***---------------------------------------------------------------------
*-
***
FORM CHECK_ITEMS_SAVE_PM.

  IF OLD_OK_CODE <> 'DISPLAY' .

    SELECT SINGLE * FROM ZPM_PREP_ROLEDES WHERE ROLE_TYPE =
                                                WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC = 0.

      IF ZPM_PREP_ROLEDES-PLANT = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-PLANT IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE I084(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPM_PREP_ROLEDES-SHOP_NO = 'X' AND
                      ( OLD_OK_CODE = 'APPROVE' OR
                     OLD_OK_CODE = 'RELEASE' OR
                     OLD_OK_CODE = 'CHANGE' OR
                     OLD_OK_CODE = 'CREATE' OR
                     OLD_OK_CODE = 'CROSSCO' ) AND
                     NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-SHOP_NO IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.
          ROLLBACK WORK.
          MESSAGE I095(ZHELP) WITH G_I.
          CLEAR : OKCODE_100, SY-UCOMM.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ( ZIC_PREP_ROLEREQ-CCODE <> 'BDW' AND
         ZIC_PREP_ROLEREQ-CCODE <> 'SBW' ).

        IF  ( ZPM_PREP_ROLEDES-ROLE_TYPE = 'PM14' OR
            ZPM_PREP_ROLEDES-ROLE_TYPE = 'PM15' OR
            ZPM_PREP_ROLEDES-ROLE_TYPE = 'PM16' ).
          G_FIELD = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
          ROLLBACK WORK.
          MESSAGE I164(ZHELP) WITH ZIC_PREP_ROLEREI-ROLE_NAME
          ZIC_PREP_ROLEREQ-CCODE .
          CLEAR : OKCODE_100, SY-UCOMM.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF WA_ITEMTAB-ROLE_NAME = 'PM8'.
        IF WA_ITEMTAB-PLANT CS 'E1' OR
            WA_ITEMTAB-PLANT CS 'E2' OR
            WA_ITEMTAB-PLANT CS 'C1'.
        ELSE.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE I202(ZHELP) WITH WA_ITEMTAB-PLANT
          ZPM_PREP_ROLEDES-ROLE_TYPE.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.


    ENDIF.

  ENDIF.
*
**
  PERFORM VALIDATE_LINEITEM_DATAX11.

ENDFORM.                    " check_items_save_pm
*&---------------------------------------------------------------------*
*&      Form  check_module_wise
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_WISE.

  CASE MODULEID.

    WHEN 'MM'.

      PERFORM CHECK_ITEMS_SAVE.

    WHEN 'PM'.

      PERFORM CHECK_ITEMS_SAVE_PM.

    WHEN 'PS'.

      PERFORM CHECK_ITEMS_SAVE_PS.

    WHEN 'PP'.

      PERFORM CHECK_ITEMS_SAVE_PP.

    WHEN 'SD'.

      PERFORM CHECK_ITEMS_SAVE_SD.

    WHEN 'QM'.

      PERFORM CHECK_ITEMS_SAVE_QM.

    WHEN 'HSE'.

      PERFORM CHECK_ITEMS_SAVE_HS.


  ENDCASE.

ENDFORM.                    " check_module_wise
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax11
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX11.

  IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.

* Begin of <RD1K981840>
*concatenate '000' ZIC_PREP_ROLEREQ-userid into cpf_lfb1.
    CPF_LFB1 = ZIC_PREP_ROLEREQ-USERID.
* End of <RD1K981840>

**---------- Changes Start date 24.06.2016 12:01:35-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .

    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
              D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
              D~DISC_CD AS DISC_CD
                INTO CORRESPONDING FIELDS OF TABLE IST_DATA
           FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                 ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                    ON C~DESIGNO = D~DESIG_CODE AND
                        C~R_P_CD  = D~R_P_CD AND
                        C~VERSION = D~VERSION )
                     WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                           A~SPRPS = ' ' AND
                           A~ENDDA = '99991231' AND
                           C~SPRPS = ' ' AND
                           C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 12:01:35-----------------

    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1. "#EC CI_NOORDER
      G_CCODE = IST_DATA-BUKRS.
    ENDIF.

  ELSE.

    G_CCODE = ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL111_ITAB INTO G_TABLCTRL111_WA.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.

      IF NOT G_TABLCTRL111_WA-PLANT IS INITIAL.

        SELECT * FROM ZD_T001W_BUKRS INTO CORRESPONDING FIELDS OF
                   TABLE IT_BUKRS  WHERE BUKRS = ZIC_PREP_ROLEREQ-CCODE
                                      AND WERKS = G_TABLCTRL111_WA-PLANT.
        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE E068(ZHELP) WITH G_TABLCTRL111_WA-ROLE_NAME.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax11
*&---------------------------------------------------------------------*
*&      Form  crc_module_checking
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CRC_MODULE_CHECKING.
  IF OLD_OK_CODE = 'CRCROLES' OR ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
    MODULEID = 'MM'.
  ENDIF.
ENDFORM.                    " crc_module_checking
*&---------------------------------------------------------------------*
*&      Form  check_module_status_mm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_MM.
  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    MM_NOT_OK = 'X'.
  ENDIF.
ENDFORM.                    " check_module_status_mm
*&---------------------------------------------------------------------*
*&      Form  check_module_status_pm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_PM.
  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    PM_NOT_OK = 'X'.
  ENDIF.
ENDFORM.                    " check_module_status_pm
*&---------------------------------------------------------------------*
*&      Form  confirm_app
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_APP.
  " Begin of <RD1K960036>.
*    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Are you sure, you want to approve the Document? '
*              TITEL          = ''
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = g_choice_app.

  DATA : L_GET7(1) TYPE C.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TEXT_QUESTION         = 'Are you sure, you want to approve the Document? '
      DISPLAY_CANCEL_BUTTON = ' '
      START_COLUMN          = 25
      START_ROW             = 6
    IMPORTING
      ANSWER                = L_GET7
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC = 0.
    CASE L_GET7.
      WHEN '1'.
        MOVE 'J' TO G_CHOICE_APP.
      WHEN '2'.
        MOVE 'N' TO G_CHOICE_APP.
    ENDCASE.
  ENDIF.
  " End of <RD1K960036>.

ENDFORM.                    " confirm_app
*&---------------------------------------------------------------------*
*&      Form  insert_items_ps
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_PS.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB, I.

  SORT G_TABLCTRL112_ITAB
  BY ROLE_NAME SERVICE PROJECT LOCATION ASSET BASIN.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL112_ITAB
    COMPARING ROLE_NAME REJ_FL SERVICE PROJECT LOCATION
    ASSET BASIN.

  LOOP AT G_TABLCTRL112_ITAB INTO G_TABLCTRL112_WA.

    MOVE-CORRESPONDING G_TABLCTRL112_WA TO WA_ITEMTAB.

*    Perform check_items_save.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_MODULE_WISE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
*      delete from ZIC_PREP_ROLEREQ
*            where docno = ZIC_PREP_ROLEREQ-docno.
*      delete from zic_prep_rolerei
*            where docno = ZIC_PREP_ROLEREQ-docno and
*                   moduleid = moduleid.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

    ENDIF.

  ENDIF.

ENDFORM.                    " insert_items_ps
*&---------------------------------------------------------------------*
*&      Form  check_items_save_ps
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE_PS.

  IF NOT ZIC_PREP_ROLEREI-SERVICE IS INITIAL AND
        ZIC_PREP_ROLEREI-ROLE_NAME IS INITIAL.
    MESSAGE E185(ZHELP).
  ENDIF.

  IF OLD_OK_CODE <> 'DISPLAY' .

    SELECT SINGLE * FROM ZPS_PREP_ROLEDES WHERE ROLE_TYPE =
                                                WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC = 0.

      IF ZPS_PREP_ROLEDES-SERVICE = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-SERVICE IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-SERVICE'.
          ROLLBACK WORK.
          MESSAGE I174(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPS_PREP_ROLEDES-PROJECT = 'X' AND
                      ( OLD_OK_CODE = 'APPROVE' OR
                     OLD_OK_CODE = 'RELEASE' OR
                     OLD_OK_CODE = 'CHANGE' OR
                     OLD_OK_CODE = 'CREATE' OR
                     OLD_OK_CODE = 'CROSSCO' ) AND
                     NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-PROJECT IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-PROJECT'.
          ROLLBACK WORK.
          MESSAGE I175(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPS_PREP_ROLEDES-LOCATION = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-LOCATION IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-LOCATION'.
          ROLLBACK WORK.
          MESSAGE I176(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPS_PREP_ROLEDES-ASSET = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-ASSET IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-ASSET'.
          ROLLBACK WORK.
          MESSAGE I177(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPS_PREP_ROLEDES-BASIN = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-BASIN IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-BASIN'.
          ROLLBACK WORK.
          MESSAGE I178(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

*****
    ENDIF.

  ENDIF.
*
**
  PERFORM VALIDATE_LINEITEM_DATAX12.

ENDFORM.                    " check_items_save_ps
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax12
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX12.

  IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.


*concatenate '000' ZIC_PREP_ROLEREQ-userid into cpf_lfb1.
    CPF_LFB1 = ZIC_PREP_ROLEREQ-USERID.

**---------- Changes Start date 24.06.2016 12:01:02-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .


    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
               D~DISC_CD AS DISC_CD
                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
            FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                     ON C~DESIGNO = D~DESIG_CODE AND
                         C~R_P_CD  = D~R_P_CD AND
                         C~VERSION = D~VERSION )
                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                            A~SPRPS = ' ' AND
                            A~ENDDA = '99991231' AND
                            C~SPRPS = ' ' AND
                            C~ENDDA = '99991231' .

**---------- Changee  Ending Date 24.06.2016 12:01:02-----------------
    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
      G_CCODE = IST_DATA-BUKRS.
    ENDIF.

  ELSE.

    G_CCODE = ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL112_ITAB INTO G_TABLCTRL112_WA.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.

      IF NOT G_TABLCTRL112_WA-SERVICE IS INITIAL.

        SELECT SINGLE * FROM ZPS_PREP_SERVICE
                WHERE SERVICE = G_TABLCTRL112_WA-SERVICE.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-SERVICE'.
          ROLLBACK WORK.
          MESSAGE E179(ZHELP) WITH G_TABLCTRL112_WA-ROLE_NAME.

        ENDIF.

      ENDIF.

      IF NOT G_TABLCTRL112_WA-PROJECT IS INITIAL.

        SELECT SINGLE * FROM ZPS_PREP_PROJECT
             WHERE SERVICE = G_TABLCTRL112_WA-SERVICE AND
             PROJECT = G_TABLCTRL112_WA-PROJECT.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PROJECT'.
          ROLLBACK WORK.
          MESSAGE E180(ZHELP) WITH G_TABLCTRL112_WA-ROLE_NAME.

        ENDIF.

      ENDIF.

      IF NOT G_TABLCTRL112_WA-LOCATION IS INITIAL.

        SELECT SINGLE * FROM ZPS_PREP_LOCA
             WHERE CCODE = ZIC_PREP_ROLEREQ-CCODE AND
                   LOCATION = G_TABLCTRL112_WA-LOCATION AND
                   SERVICE = G_TABLCTRL112_WA-SERVICE.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-LOCATION'.
          ROLLBACK WORK.
          G_I = G_CURR_LINE.
          MESSAGE E181(ZHELP) WITH G_TABLCTRL112_WA-ROLE_NAME.
        ENDIF.

      ENDIF.

      IF NOT G_TABLCTRL112_WA-BASIN IS INITIAL.

        IF G_TABLCTRL112_WA-BASIN <> ZIC_PREP_ROLEREQ-CCODE AND
               G_TABLCTRL112_WA-BASIN <> 'ALL'.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-BASIN'.
          ROLLBACK WORK.
          MESSAGE E181(ZHELP) WITH G_TABLCTRL112_WA-ROLE_NAME.

        ENDIF.

      ENDIF.


      IF NOT G_TABLCTRL112_WA-ASSET IS INITIAL.

        IF ZIC_PREP_ROLEREQ-CCODE = 'MUM'.

          IF G_TABLCTRL112_WA-ASSET <> 'ALL'.
            SELECT SINGLE * FROM ZPS_PREP_ASST_EX
                   WHERE CCODE = ZIC_PREP_ROLEREQ-CCODE AND
                     ASSET = G_TABLCTRL112_WA-ASSET.
          ENDIF.
          IF SY-SUBRC <> 0 AND ZPS_PREP_ASST_EX-ASSET <> 'ALL'.
            G_E_FL = 'X'.
            G_FIELD = 'ZIC_PREP_ROLEREI-ASSET'.
            ROLLBACK WORK.
            MESSAGE E182(ZHELP) WITH G_TABLCTRL112_WA-ROLE_NAME.

          ENDIF.

        ELSE.

          IF G_TABLCTRL112_WA-ASSET <> ZIC_PREP_ROLEREQ-CCODE AND
              G_TABLCTRL112_WA-ASSET <> 'ALL'.
            G_E_FL = 'X'.
            G_FIELD = 'ZIC_PREP_ROLEREI-ASSET'.
            ROLLBACK WORK.
            MESSAGE E182(ZHELP) WITH G_TABLCTRL112_WA-ROLE_NAME.

          ENDIF.
        ENDIF.
      ENDIF.
************
    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax12
*&---------------------------------------------------------------------*
*&      Form  check_module_status_ps
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_PS.
  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    PS_NOT_OK = 'X'.
  ENDIF.
ENDFORM.                    " check_module_status_ps
*&---------------------------------------------------------------------*
*&      Form  clear_for_newmodule
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLEAR_FOR_NEWMODULE.

  PERFORM DESTROY_CTRL.

  CLEAR   : OKCODE_100, ERR_FLG.
  REFRESH : G_TABLCTRL110_ITAB[].
  CLEAR   : G_TABLCTRL110_ITAB.
  REFRESH : G_TABLCTRL111_ITAB[].
  CLEAR   : G_TABLCTRL111_ITAB.
  REFRESH : G_TABLCTRL112_ITAB[].
  CLEAR   : G_TABLCTRL112_ITAB.
  CLEAR   : SY-UCOMM.
  CLEAR   : G_CURR_LINE.
  CLEAR SET_DISC_MM_FLAG.
  CLEAR SET_DISC_FI_FLAG.
  CLEAR   : ZIC_PREP_ROLEREI.
  CLEAR   : IT_TAB.
  REFRESH : TLINETAB1[],TLINETAB2[].
  CLEAR   : T500P-NAME1.
  CLEAR   : CRC_CHECK_FL.
  CLEAR   : HELP_LIST_FLAG.
  REFRESH : IT_M_FISTB.
  CLEAR   : G_HD_COPIED.


  """""""""""""""""""
  "added by lipsy for clear on 20.03.2015 RD1K996555
  REFRESH : G_TABLCTRL118_ITAB[].
  CLEAR   : G_TABLCTRL118_ITAB.

  "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555

  """"""""""""""""""

ENDFORM.                    " clear_for_newmodule
*&---------------------------------------------------------------------*
*&      Form  insert_items_pp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_PP.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB, I.

  SORT G_TABLCTRL113_ITAB
  BY ROLE_NAME PLANT SLOC RES CTF_SLOC.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL113_ITAB
    COMPARING ROLE_NAME REJ_FL PLANT SLOC RES
    CTF_SLOC.

  LOOP AT G_TABLCTRL113_ITAB INTO G_TABLCTRL113_WA.

    MOVE-CORRESPONDING G_TABLCTRL113_WA TO WA_ITEMTAB.

*    Perform check_items_save.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_MODULE_WISE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

    ENDIF.

  ENDIF.

ENDFORM.                    " insert_items_pp
*&---------------------------------------------------------------------*
*&      Form  check_items_save_pp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE_PP.

  IF OLD_OK_CODE <> 'DISPLAY' .

    SELECT SINGLE * FROM ZPP_PREP_ROLEDES WHERE ROLE_TYPE =
                                                WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC = 0.

      IF ZPP_PREP_ROLEDES-PLANT = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-PLANT IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE I074(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPP_PREP_ROLEDES-SLOC = 'X' AND
                      ( OLD_OK_CODE = 'APPROVE' OR
                     OLD_OK_CODE = 'RELEASE' OR
                     OLD_OK_CODE = 'CHANGE' OR
                     OLD_OK_CODE = 'CREATE' OR
                     OLD_OK_CODE = 'CROSSCO' ) AND
                     NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-SLOC IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-SLOC'.
          ROLLBACK WORK.
          MESSAGE I090(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPP_PREP_ROLEDES-RES = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-RES IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-RES'.
          ROLLBACK WORK.
          MESSAGE I184(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZPP_PREP_ROLEDES-CTF_SLOC = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-CTF_SLOC IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-CTF_SLOC'.
          ROLLBACK WORK.
          MESSAGE I090(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

*****
    ENDIF.

  ENDIF.
*
**
  PERFORM VALIDATE_LINEITEM_DATAX13.


ENDFORM.                    " check_items_save_pp
*&---------------------------------------------------------------------*
*&      Form  check_module_status_pp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_PP.

  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    PP_NOT_OK = 'X'.
  ENDIF.

ENDFORM.                    " check_module_status_pp
*&---------------------------------------------------------------------*
*&      Form  insert_items_sd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_SD.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB, I.

  SORT G_TABLCTRL114_ITAB
  BY ROLE_NAME SALE_ORG DIV PLANT SHIP_POINT.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL114_ITAB
    COMPARING ROLE_NAME REJ_FL SALE_ORG DIV PLANT SHIP_POINT.

  LOOP AT G_TABLCTRL114_ITAB INTO G_TABLCTRL114_WA.

    CLEAR WA_ITEMTAB.

    MOVE-CORRESPONDING G_TABLCTRL114_WA TO WA_ITEMTAB.

*    Perform check_items_save.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_MODULE_WISE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

    ENDIF.

  ENDIF.

ENDFORM.                    " insert_items_sd
*&---------------------------------------------------------------------*
*&      Form  check_items_save_sd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE_SD.

  IF OLD_OK_CODE <> 'DISPLAY' .

    SELECT SINGLE * FROM ZSD_PREP_ROLEDES WHERE ROLE_TYPE =
                                                WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC = 0.

      IF ZSD_PREP_ROLEDES-PLANT = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-PLANT IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE I074(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZSD_PREP_ROLEDES-SALE_ORG = 'X' AND
                      ( OLD_OK_CODE = 'APPROVE' OR
                     OLD_OK_CODE = 'RELEASE' OR
                     OLD_OK_CODE = 'CHANGE' OR
                     OLD_OK_CODE = 'CREATE' OR
                     OLD_OK_CODE = 'CROSSCO' ) AND
                     NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-SALE_ORG IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-SALE_ORG'.
          ROLLBACK WORK.
          MESSAGE I190(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZSD_PREP_ROLEDES-DIV = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-DIV IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-DIV'.
          ROLLBACK WORK.
          MESSAGE I194(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

      IF ZSD_PREP_ROLEDES-SHIP_POINT = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-SHIP_POINT IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-SHIP_POINT'.
          ROLLBACK WORK.
          MESSAGE I191(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

*****
    ENDIF.

  ENDIF.
*
**
  PERFORM VALIDATE_LINEITEM_DATAX14.


ENDFORM.                    " check_items_save_sd
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax13
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX13.

  IF  ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.
**---------- Changes Start date 24.06.2016 12:00:31-------------------


*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR =  ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .
*


    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
               D~DISC_CD AS DISC_CD
                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
            FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                     ON C~DESIGNO = D~DESIG_CODE AND
                         C~R_P_CD  = D~R_P_CD AND
                         C~VERSION = D~VERSION )
                      WHERE A~PERNR =  ZIC_PREP_ROLEREQ-USERID AND
                            A~SPRPS = ' ' AND
                            A~ENDDA = '99991231' AND
                            C~SPRPS = ' ' AND
                            C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 12:00:31-----------------

    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
      G_CCODE = IST_DATA-BUKRS.
    ENDIF.

  ELSE.

    G_CCODE =  ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL113_ITAB INTO G_TABLCTRL113_WA.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.


      IF NOT ZIC_PREP_ROLEREI-PLANT IS INITIAL.

        SELECT * FROM ZD_T001W_BUKRS INTO CORRESPONDING FIELDS OF
                      TABLE IT_BUKRS  WHERE BUKRS =  ZIC_PREP_ROLEREQ-CCODE
                                         AND WERKS = ZIC_PREP_ROLEREI-PLANT.
        IF SY-SUBRC = 0.

          SELECT SINGLE * FROM ZHELP_PPROLES1 INTO CORRESPONDING FIELDS OF
                               ZHELP_PPROLES1 WHERE
                               ROLE_TYPE = ZIC_PREP_ROLEREI-ROLE_NAME AND
                               PLANT     = ZIC_PREP_ROLEREI-PLANT.

          IF SY-SUBRC <> 0.

            SELECT SINGLE * FROM ZPP_PREP_GENERIC INTO CORRESPONDING FIELDS OF
                                 ZPP_PREP_GENERIC WHERE
                                 ROLE_TYPE = ZIC_PREP_ROLEREI-ROLE_NAME AND
                                 PLANT     = ZIC_PREP_ROLEREI-PLANT.

            IF SY-SUBRC <> 0.
              G_E_FL = 'X'.
              G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
              G_I = G_CURR_LINE_113.
              ROLLBACK WORK.
              MESSAGE E068(ZHELP) WITH ZIC_PREP_ROLEREI-ROLE_NAME.
            ENDIF.

          ENDIF.

        ELSE.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          G_I = G_CURR_LINE_113.
          MESSAGE E068(ZHELP) WITH ZIC_PREP_ROLEREI-ROLE_NAME.
        ENDIF.

      ENDIF.

      IF NOT ZIC_PREP_ROLEREI-SLOC IS INITIAL.

        SELECT SINGLE * FROM T001L INTO CORRESPONDING FIELDS OF
                 IT_T001L  WHERE WERKS = ZIC_PREP_ROLEREI-PLANT
                 AND LGORT = ZIC_PREP_ROLEREI-SLOC.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-SLOC'.
          G_I = G_CURR_LINE_113.
          ROLLBACK WORK.
          MESSAGE E073(ZHELP) WITH ZIC_PREP_ROLEREI-SLOC.
        ENDIF.

      ENDIF.

      IF NOT ZIC_PREP_ROLEREI-RES IS INITIAL.

        SELECT SINGLE * FROM ZPP_PREP_RES INTO CORRESPONDING FIELDS OF
                 IT_RES  WHERE ROLE_TYPE = ZIC_PREP_ROLEREI-ROLE_NAME
                 AND
                 PLANT = ZIC_PREP_ROLEREI-PLANT
                 AND
                 RES = ZIC_PREP_ROLEREI-RES.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-RES'.
          G_I = G_CURR_LINE_113.
          ROLLBACK WORK.
          MESSAGE E183(ZHELP) WITH ZIC_PREP_ROLEREI-RES.

        ENDIF.

      ENDIF.


      IF NOT ZIC_PREP_ROLEREI-CTF_SLOC IS INITIAL.

        SELECT SINGLE * FROM ZPP_PREP_DROLEEX WHERE ROLE_TYPE =
          ZIC_PREP_ROLEREI-ROLE_NAME
          AND PLANT = ZIC_PREP_ROLEREI-PLANT
          AND SLOC = ZIC_PREP_ROLEREI-SLOC
          AND CTF_SLOC = ZIC_PREP_ROLEREI-CTF_SLOC.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-CTF_SLOC'.
          G_I = G_CURR_LINE.
          ROLLBACK WORK.
          MESSAGE E073(ZHELP) WITH ZIC_PREP_ROLEREI-CTF_SLOC.

        ENDIF.

      ENDIF.
****
    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax13
*&---------------------------------------------------------------------*
*&      Form  check_module_status_sd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_SD.

  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    SD_NOT_OK = 'X'.
  ENDIF.

ENDFORM.                    " check_module_status_sd
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax14
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX14.

  IF  ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.

**---------- Changes Start date 24.06.2016 11:59:59-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR =  ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .
*

    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
               D~DISC_CD AS DISC_CD
                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
            FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                     ON C~DESIGNO = D~DESIG_CODE AND
                         C~R_P_CD  = D~R_P_CD AND
                         C~VERSION = D~VERSION )
                      WHERE A~PERNR =  ZIC_PREP_ROLEREQ-USERID AND
                            A~SPRPS = ' ' AND
                            A~ENDDA = '99991231' AND
                            C~SPRPS = ' ' AND
                            C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:59:59-----------------

    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
      G_CCODE = IST_DATA-BUKRS.
    ENDIF.

  ELSE.

    G_CCODE =  ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL114_ITAB INTO G_TABLCTRL114_WA.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.

      IF NOT ZIC_PREP_ROLEREI-PLANT IS INITIAL.

        SELECT * FROM ZD_T001W_BUKRS INTO CORRESPONDING FIELDS OF
                       TABLE IT_BUKRS  WHERE BUKRS =  ZIC_PREP_ROLEREQ-CCODE
                                          AND WERKS = ZIC_PREP_ROLEREI-PLANT.
        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          G_I = G_CURR_LINE_114.
          MESSAGE E068(ZHELP) WITH ZIC_PREP_ROLEREI-ROLE_NAME.
        ENDIF.

      ENDIF.

      IF NOT ZIC_PREP_ROLEREI-SALE_ORG IS INITIAL.

        SELECT SINGLE * FROM TVKO CLIENT SPECIFIED INTO CORRESPONDING FIELDS
                 OF IT_TVKO  WHERE MANDT = SY-MANDT AND
                 BUKRS =  ZIC_PREP_ROLEREQ-CCODE AND
                 VKORG = ZIC_PREP_ROLEREI-SALE_ORG.

        IF SY-SUBRC <> 0 AND ZIC_PREP_ROLEREI-SALE_ORG <> 'ALL'.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-SALE_ORG'.
          G_I = G_CURR_LINE_114.
          MESSAGE E186(ZHELP) WITH ZIC_PREP_ROLEREI-SALE_ORG.
        ELSEIF ZIC_PREP_ROLEREQ-CCODE = 'MUM' AND
* 18092015
              ( ZIC_PREP_ROLEREQ-FUNDC1 = 'MUMPHPOP' OR ZIC_PREP_ROLEREQ-FUNDC1 = 'MUMPHPSP') AND
*                ZIC_PREP_ROLEREQ-FUNDC1 = 'MUMPHPOP' AND
* 18092015
                ZIC_PREP_ROLEREI-SALE_ORG <> 'HZRS'.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-SALE_ORG'.
          G_I = G_CURR_LINE_114.
          MESSAGE E186(ZHELP) WITH ZIC_PREP_ROLEREI-SALE_ORG.
        ELSE.
          IF ZIC_PREP_ROLEREQ-CCODE = 'MUM' AND
*          ZIC_PREP_ROLEREQ-FUNDC1 <> 'MUMPHPOP' AND
            ZIC_PREP_ROLEREQ-FUNDC1 <> 'MUMPHPOP' AND
            ZIC_PREP_ROLEREQ-FUNDC1 <> 'MUMPHPSP' AND       "18092015
          ZIC_PREP_ROLEREI-SALE_ORG = 'HZRS'.
            G_E_FL = 'X'.
            G_FIELD = 'ZIC_PREP_ROLEREI-SALE_ORG'.
            G_I = G_CURR_LINE_114.
            MESSAGE E186(ZHELP) WITH ZIC_PREP_ROLEREI-SALE_ORG.
          ENDIF.
        ENDIF.

      ENDIF.

      IF NOT ZIC_PREP_ROLEREI-DIV IS INITIAL.

        SELECT SINGLE * FROM TVKOS CLIENT SPECIFIED INTO CORRESPONDING
                 FIELDS OF IT_TVKOS  WHERE MANDT = SY-MANDT AND
                 VKORG =  ZIC_PREP_ROLEREI-SALE_ORG AND
                 SPART =  ZIC_PREP_ROLEREI-DIV.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-DIV'.
          G_I = G_CURR_LINE_114.
          MESSAGE E187(ZHELP) WITH ZIC_PREP_ROLEREI-DIV.

        ENDIF.

      ENDIF.


      IF NOT ZIC_PREP_ROLEREI-SHIP_POINT IS INITIAL.

        SELECT SINGLE * FROM TVSWZ INTO CORRESPONDING FIELDS OF
              IT_TVSWZ  WHERE WERKS = ZIC_PREP_ROLEREI-PLANT AND
              VSTEL = ZIC_PREP_ROLEREI-SHIP_POINT.

        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-SHIP_POINT'.
          G_I = G_CURR_LINE.
          MESSAGE E188(ZHELP) WITH ZIC_PREP_ROLEREI-SHIP_POINT.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax14
*&---------------------------------------------------------------------*
*&      Form  insert_items_qm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_QM.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB, I.

  SORT G_TABLCTRL115_ITAB
  BY ROLE_NAME PLANT ASSET_QM.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL115_ITAB
    COMPARING ROLE_NAME REJ_FL PLANT ASSET_QM.

  LOOP AT G_TABLCTRL115_ITAB INTO G_TABLCTRL115_WA.

    MOVE-CORRESPONDING G_TABLCTRL115_WA TO WA_ITEMTAB.

*    Perform check_items_save.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_MODULE_WISE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

    ENDIF.

  ENDIF.

ENDFORM.                    " insert_items_qm
*&---------------------------------------------------------------------*
*&      Form  check_items_save_qm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE_QM.

  IF OLD_OK_CODE <> 'DISPLAY' .

    SELECT SINGLE * FROM ZQM_PREP_ROLEDES WHERE ROLE_TYPE =
                                                WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC = 0.

      IF ZQM_PREP_ROLEDES-PLANT = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE' OR
                    OLD_OK_CODE = 'CREATE' OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-PLANT IS INITIAL AND
              ZIC_PREP_ROLEREQ-CCODE = 'MUM'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE I084(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.

    ENDIF.

  ENDIF.
*
**
  PERFORM VALIDATE_LINEITEM_DATAX15.

ENDFORM.                    " check_items_save_qm
**********************************************************************
*DATA:   MESSTAB LIKE BDCMSGCOLL OCCURS 0 WITH HEADER LINE.
*       messages of call transaction

*----------------------------------------------------------------------*
*   at selection screen                                                *
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*   create batchinput session                                          *
*   (not for call transaction using...)                                *
*----------------------------------------------------------------------*
FORM OPEN_GROUP.
  CALL FUNCTION 'BDC_OPEN_GROUP'
    EXPORTING
      CLIENT   = SY-MANDT
      GROUP    = SY-UNAME
      USER     = SY-UNAME
      KEEP     = ''
      HOLDDATE = SY-DATUM.

ENDFORM.                    "OPEN_GROUP

*----------------------------------------------------------------------*
*   end batchinput session                                             *
*   (call transaction using...: error session)                         *
*----------------------------------------------------------------------*
FORM CLOSE_GROUP.
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
ENDFORM.                    "CLOSE_GROUP
*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
FORM BDC_FIELD USING FNAM FVAL.
  IF FVAL <> '/'.
    CLEAR BDCDATA.
    BDCDATA-FNAM = FNAM.
    BDCDATA-FVAL = FVAL.
    APPEND BDCDATA.
  ENDIF.
ENDFORM.                    "BDC_FIELD
*----------------------------------------------------------------------*
*        Start new screen                                              *
*----------------------------------------------------------------------*
FORM BDC_DYNPRO USING PROGRAM DYNPRO.
  CLEAR BDCDATA.
  BDCDATA-PROGRAM  = PROGRAM.
  BDCDATA-DYNPRO   = DYNPRO.
  BDCDATA-DYNBEGIN = 'X'.
  APPEND BDCDATA.
ENDFORM.                    "BDC_DYNPRO
**********************************************************************
*&---------------------------------------------------------------------*
*&      Form  call_fi
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CALL_FI.

  SET PARAMETER ID 'ZOLDCODE_FI' FIELD OLD_OK_CODE.

  SET PARAMETER ID 'ZMODULEID_FI' FIELD 'FI'.

  SET PARAMETER ID 'ZUSERID_FI' FIELD ZIC_PREP_ROLEREQ-USERID.

  SET PARAMETER ID 'ZRSN_CODE_FI' FIELD ZIC_PREP_ROLEREQ-RSN_CODE.

  SET PARAMETER ID 'ZTELNO_FI' FIELD ZIC_PREP_ROLEREQ-TELNO.

  SET PARAMETER ID 'ZDOCNO_FI' FIELD ZIC_PREP_ROLEREQ-DOCNO.

  DYNNR = '0101'.
*****************************************@
  IF OLD_OK_CODE = 'APPROVE'.

    CLEAR OLD_OK_CODE.
*    PERFORM clear.
    SET PARAMETER ID 'ZOLDCODE_FI' FIELD 'APPROVE'.
    SET PARAMETER ID 'ZREQNO' FIELD ZIC_PREP_ROLEREQ-DOCNO.
    LEAVE TO TRANSACTION 'ZIC_AUTH_FI_REP' .

  ELSE.

    CLEAR OLD_OK_CODE.
    PERFORM CLEAR.

    CALL TRANSACTION 'ZIC_AUTH_FI' .
  ENDIF.

ENDFORM. "call_fi
*&---------------------------------------------------------------------*
*&      Form  check_module_status_qm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_QM.
  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    QM_NOT_OK = 'X'.
  ENDIF.
ENDFORM.                    " check_module_status_qm
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax15
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX15.

  IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.

*concatenate '000' ZIC_PREP_ROLEREQ-userid into cpf_lfb1.
    CPF_LFB1 = ZIC_PREP_ROLEREQ-USERID.

**---------- Changes Start date 24.06.2016 11:59:30-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .

    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
              D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
              D~DISC_CD AS DISC_CD
                INTO CORRESPONDING FIELDS OF TABLE IST_DATA
           FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                 ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                    ON C~DESIGNO = D~DESIG_CODE AND
                        C~R_P_CD  = D~R_P_CD AND
                        C~VERSION = D~VERSION )
                     WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                           A~SPRPS = ' ' AND
                           A~ENDDA = '99991231' AND
                           C~SPRPS = ' ' AND
                           C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:59:30-----------------

    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
      G_CCODE = IST_DATA-BUKRS.
    ENDIF.

  ELSE.

    G_CCODE = ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL115_ITAB INTO G_TABLCTRL115_WA.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.

      IF NOT G_TABLCTRL115_WA-PLANT IS INITIAL.

        SELECT * FROM ZD_T001W_BUKRS INTO CORRESPONDING FIELDS OF
                   TABLE IT_BUKRS  WHERE BUKRS = ZIC_PREP_ROLEREQ-CCODE
                                      AND WERKS = G_TABLCTRL115_WA-PLANT.
        IF SY-SUBRC <> 0.
          G_E_FL = 'X'.
          G_FIELD = 'ZIC_PREP_ROLEREI-PLANT'.
          ROLLBACK WORK.
          MESSAGE E068(ZHELP) WITH G_TABLCTRL115_WA-ROLE_NAME.
        ENDIF.

      ENDIF.

      IF NOT ZIC_PREP_ROLEREI-ASSET_QM IS INITIAL.

        IF ZIC_PREP_ROLEREQ-CCODE = 'MUM' OR ZIC_PREP_ROLEREQ-CCODE = 'KKL'.

          SELECT SINGLE * FROM ZQM_PREP_ASSET INTO ZQM_PREP_ASSET WHERE
                          CCODE =  ZIC_PREP_ROLEREQ-CCODE AND
                          ASSET =  ZIC_PREP_ROLEREI-ASSET_QM.
          IF SY-SUBRC <> 0.
            G_E_FL = 'X'.
            G_FIELD = 'ZIC_PREP_ROLEREI-ASSET_QM'.
            G_I = G_CURR_LINE.
            MESSAGE E172(ZHELP) WITH ZIC_PREP_ROLEREI-ASSET_QM.
          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax15
*&---------------------------------------------------------------------*
*&      Form  confirm_more
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_MORE.
  " Begin of <RD1K960036>.
*   CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Do you want to attach more files?'
*              DEFAULTOPTION  = ''
*              TITEL          = 'ATTACH MORE'
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = g_choice_more.
  DATA : L_GET8(1) TYPE C.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = 'ATTACH MORE '
      TEXT_QUESTION         = 'Do you want to attach more files?'
      DEFAULT_BUTTON        = ' '
      DISPLAY_CANCEL_BUTTON = ' '
      START_COLUMN          = 25
      START_ROW             = 6
    IMPORTING
      ANSWER                = L_GET8
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC = 0.
    CASE L_GET8.
      WHEN '1'.
        MOVE 'J' TO G_CHOICE_MORE.
      WHEN '2'.
        MOVE 'N' TO G_CHOICE_MORE.
    ENDCASE.
  ENDIF.

  " End of <RD1K960036>.
ENDFORM.                    " confirm_more
*&---------------------------------------------------------------------*
*&      Form  check_module_fi
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_FI.

  IF ( OLD_OK_CODE = 'CHANGE' OR
  OLD_OK_CODE = 'DISPLAY' ) AND MODULEID = 'FI'.
    SELECT SINGLE * FROM ZIC_PREP_ROLEREI INTO
                    CORRESPONDING FIELDS OF WA_MODULE1 WHERE
                    DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
                    MODULEID = 'FI'.
    IF SY-SUBRC <> 0 AND ZIC_PREP_ROLEREQ-DELIMIT <> 'X'.
      IF OLD_OK_CODE = 'CHANGE'.
        MESSAGE E196(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ELSE.
        MESSAGE E198(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " check_module_fi
*&---------------------------------------------------------------------*
*&      Form  confirm_rel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_REL.
  " Begin of <RD1K960036>.
*    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Roles created for all modules will be released?? '
*              TEXTLINE2      = 'Are you sure, you want to release the Document? '
*
*              TITEL          = ''
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = g_choice_rel.

  DATA : L_GET9(1) TYPE C.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TEXT_QUESTION         = 'Roles created for all modules will be released?? '
                              & 'Are you sure, you want to release the Document? '
      DISPLAY_CANCEL_BUTTON = ' '
      START_COLUMN          = 25
      START_ROW             = 6
    IMPORTING
      ANSWER                = L_GET9
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC = 0.
    CASE L_GET9.
      WHEN '1'.
        MOVE 'J' TO G_CHOICE_REL.
      WHEN '2'.
        MOVE 'N' TO G_CHOICE_REL.
    ENDCASE.
  ENDIF.
  " End of <RD1K960036>.

ENDFORM.                    " confirm_rel
*&---------------------------------------------------------------------*
*&      Form  list_help_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM LIST_HELP_FILES.

  CLEAR G_ATT_FILES_WA.

  G_ATT_FILES_WA-LOGSYS = 'ARMSHELP'.
  G_ATT_FILES_WA-OBJTYPE = 'HLP'.
  G_ATT_FILES_WA-OBJKEY = '01'.

  REFRESH EXCLUDE_TAB[].

  MOVE 'ENTR' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'CHNG' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'CREA' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'DELE' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'IMPO' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'EXPO' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'OLNK' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'PRIN' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'COPY' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'HGEN' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'REFL' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.
  MOVE 'MOVE' TO EXCLUDE_TAB. APPEND EXCLUDE_TAB.


  CALL FUNCTION 'SO_WIND_ATTACHMENT_LIST_API1'
    EXPORTING
      APPLICATION_OBJECT = G_ATT_FILES_WA
*     FUNCTION           = ' '
    TABLES
      FUNC_EXCLUDE       = EXCLUDE_TAB.

ENDFORM.                    " list_help_files
*&---------------------------------------------------------------------*
*&      Form  check_module_status_hse
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MODULE_STATUS_HSE.

  IF WA_ITEM-REJ_FL = '' AND WA_ITEM-ROLE_REQUEST <> ''.
  ELSEIF WA_ITEM-REJ_FL <> '' AND WA_ITEM-ROLE_REQUEST = ''.
  ELSE.
    HS_NOT_OK = 'X'.
  ENDIF.

ENDFORM.                    " check_module_status_hse
*&---------------------------------------------------------------------*
*&      Form  insert_items_hs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_HS.

  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  SORT G_TABLCTRL116_ITAB
  BY ROLE_NAME.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL116_ITAB
    COMPARING ROLE_NAME REJ_FL.

  LOOP AT G_TABLCTRL116_ITAB INTO G_TABLCTRL116_WA.

    MOVE-CORRESPONDING G_TABLCTRL116_WA TO WA_ITEMTAB.

*    Perform check_items_save.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    PERFORM CHECK_MODULE_WISE.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

    ENDIF.

  ENDIF.


ENDFORM.                    " insert_items_hs
*&---------------------------------------------------------------------*
*&      Form  check_items_save_hs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE_HS.

  IF OLD_OK_CODE <> 'DISPLAY' .

    SELECT SINGLE * FROM ZHS_PREP_ROLEDES WHERE ROLE_TYPE =
                                                WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC <> 0.

      MESSAGE E102(ZHELP) WITH ZHS_PREP_ROLEDES-ROLE_TYPE.

    ENDIF.

  ENDIF.
*
**
  PERFORM VALIDATE_LINEITEM_DATAX16.

ENDFORM.                    " check_items_save_hs
*&---------------------------------------------------------------------*
*&      Form  validate_lineitem_datax16
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_LINEITEM_DATAX16.

  IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' OR OLD_OK_CODE = 'CROSSCO'.

*concatenate '000' ZIC_PREP_ROLEREQ-userid into cpf_lfb1.
    CPF_LFB1 = ZIC_PREP_ROLEREQ-USERID.

**---------- Changes Start date 24.06.2016 11:59:02-------------------

*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*               D~DISC_CD AS DISC_CD
*                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*            FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                     ON C~DESIGNO = D~DESIG_CODE AND
*                         C~R_P_CD  = D~R_P_CD AND
*                         C~VERSION = D~VERSION )
*                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                            A~SPRPS = ' ' AND
*                            A~ENDDA = '99991231' AND
*                            C~SPRPS = ' ' AND
*                            C~ENDDA = '99991231' .


    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
                 A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
               D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
               D~DISC_CD AS DISC_CD
                 INTO CORRESPONDING FIELDS OF TABLE IST_DATA
            FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                  ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                     ON C~DESIGNO = D~DESIG_CODE AND
                         C~R_P_CD  = D~R_P_CD AND
                         C~VERSION = D~VERSION )
                      WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                            A~SPRPS = ' ' AND
                            A~ENDDA = '99991231' AND
                            C~SPRPS = ' ' AND
                            C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:59:02-----------------

    IF SY-SUBRC = 0.
      READ TABLE IST_DATA INDEX 1.  "#EC CI_NOORDER
      G_CCODE = IST_DATA-BUKRS.
    ENDIF.

  ELSE.

    G_CCODE = ZIC_PREP_ROLEREQ-CCODE.

  ENDIF.

  LOOP AT G_TABLCTRL116_ITAB INTO G_TABLCTRL116_WA.

**********************************************************

    IF OLD_OK_CODE <> 'DISPLAY'.

    ENDIF.

  ENDLOOP.

ENDFORM.                    " validate_lineitem_datax16
*&---------------------------------------------------------------------*
*&      Form  message1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM MESSAGE1.
  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      TITEL     = 'CRC Authorisations '
      TEXTLINE1 = 'The desired roles for the position are already available with you.'
      TEXTLINE2 = 'In case of any new roles please create normal request.'.
ENDFORM.                                                    " message1
*&---------------------------------------------------------------------*
*&      Form  message2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM MESSAGE2.

  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      TITEL     = 'CRC Authorisations '
      TEXTLINE1 = 'Your position has not been updated.Please get your position updated by'
      TEXTLINE2 = 'local HR so that the requisite roles with position will be available  to you.'.

ENDFORM.                                                    " message2


*&---------------------------------------------------------------------*
*&      Form  call_hr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CALL_HR.

* SET PARAMETER ID 'ZOLDCODE_FI' field old_ok_code.

  SET PARAMETER ID 'ZMODULEID_HR' FIELD 'HR'.

  SET PARAMETER ID 'ZUSERID_HR' FIELD ZIC_PREP_ROLEREQ-USERID.

  SET PARAMETER ID 'ZRSN_CODE_HR' FIELD ZIC_PREP_ROLEREQ-RSN_CODE.

  SET PARAMETER ID 'ZTELNO_HR' FIELD ZIC_PREP_ROLEREQ-TELNO.

* SET PARAMETER ID 'ZDOCNO_FI' field ZIC_PREP_ROLEREQ-DOCNO.

  DYNNR = '0101'.

  CLEAR OLD_OK_CODE.

  PERFORM CLEAR.

  CALL TRANSACTION 'ZHRARMS' .

  LEAVE PROGRAM.

ENDFORM. "call_hr
*&---------------------------------------------------------------------*
*&      Form  INSERT_ITEMS_OLM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_OLM .
  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  SORT G_TC_117_ITAB
  BY ROLE_NAME.

  DELETE ADJACENT DUPLICATES FROM G_TC_117_ITAB
    COMPARING ROLE_NAME.

  LOOP AT G_TC_117_ITAB INTO G_TC_117_WA.

    MOVE-CORRESPONDING G_TC_117_WA TO WA_ITEMTAB.

    IF OLD_OK_CODE = 'CREATE' OR
      OLD_OK_CODE = 'CROSSCO' OR
      OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.
  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID.
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.
    ENDIF.

  ENDIF.
ENDFORM.                    " INSERT_ITEMS_OLM
*&---------------------------------------------------------------------*
*&      Form  POPUP_RELEASE_MESSAGE2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POPUP_RELEASE_MESSAGE2 .
  IF G_APPROVER_LEVEL = 'IM'.
    G_APPROVER_LEVEL = 'I/C MM'.
  ENDIF.

  """""""""""""""
  "comment by lipsy on 24.03.2015 RD1K996555
*  CONCATENATE G_APPROVER_LEVEL ' or L4. Request  for  authorization will be routed to ICE core' INTO G_APPROVE_TEXT.

  "end of comment by lipsy on 24.03.2015 RD1K996555
  """"""""""""""


  """""""""""""""
  "added by lipsy on 24.03.2015 RD1K996555

  CONCATENATE G_APPROVER_LEVEL ' or L4.' INTO G_APPROVE_TEXT.

  "end of addition by lipsy on 24.03.2015 RD1K996555
  """"""""""""""

  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
    EXPORTING
      TITEL     = 'Approval Requirement'
      TEXTLINE1 = 'Kindly self release the  request  &  get it approved by competent authority:'
      TEXTLINE2 = G_APPROVE_TEXT
      """""""""""""""""""""""""""""
      "comment by lipsy on 24.03.2015 RD1K996555
*     TEXTLINE3 = 'team only after requisite approval '
      "end of comment by lipsy on 24.03.2015 RD1K996555
      """"""""""""""""""""""""""""""""""""""""""
*     START_COLUMN = 15
*     START_ROW = 6
    .
  CLEAR : G_APPROVER_LEVEL, G_APPROVE_TEXT.
ENDFORM.                    " POPUP_RELEASE_MESSAGE2
*&---------------------------------------------------------------------*
*&      Form  POPUP_RELEASE_MESSAGE3
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM POPUP_RELEASE_MESSAGE3 .
  IF G_APPROVER_LEVEL = 'IM'.
    G_APPROVER_LEVEL = 'I/C MM'.
  ENDIF.


  CONCATENATE 'Kindly get the request approved by competent authority: '
  G_APPROVER_LEVEL ' or L4' INTO G_APPROVE_TEXT.


  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
    EXPORTING
      TITEL     = 'Approval Requirement'
      TEXTLINE1 = G_APPROVE_TEXT
      """"""""""""""""""""""""""""""""""""""
      "commented by lipsy on 24.03.2015 RD1K996555
*     TEXTLINE2 = 'Request for authorization will be routed to ICE core team only '
*     TEXTLINE3 = 'after requisite approval '
      "end of comment by lipsy on 24.03.2015 RD1K996555
      """""""""""""""""""""""""""""""""""""""""""""""
*     START_COLUMN = 15
*     START_ROW = 6
    .
  CLEAR : G_APPROVER_LEVEL, G_APPROVE_TEXT.
ENDFORM.                    " POPUP_RELEASE_MESSAGE3
*&---------------------------------------------------------------------*
*&      Form  GRC_RISK_ANALYSIS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GRC_RISK_ANALYSIS .

  IF OLD_OK_CODE = 'APPROVE'.
    CHECK_OKCODE = 'A'.
  ELSEIF OLD_OK_CODE = 'CREATE'.
    CHECK_OKCODE = 'C'.
  ELSEIF OLD_OK_CODE = 'CHANGE'.
    CHECK_OKCODE = 'M'.
  ENDIF.
  CLEAR GT_BUK_ROLE.
  CLEAR GT_FINAL_TB.
  CLEAR GT_VIOL_DTL.
  CLEAR GT_BUCKET.
  CLEAR GT_BUCKET1.
  CLEAR GT_EROLES.
  CLEAR GT_EROLES1.
  CLEAR GT_USERINFO.
  CLEAR GT_OUTPUT.
  CLEAR GT_VIOLDTL.
  CLEAR : GT_RDESC, GT_CRMODULE.
  IMPORT  REQNUM_EX FROM MEMORY ID 'REQNUM_IM'.
******************* DELETING PRIVIOUS RISK ANALYSIS**************************

  DELETE FROM ZGRC_SOD_RESULT WHERE DOCNO = REQNUM_EX.
  DELETE FROM ZGRC_VIOL_DTL WHERE DOCNO = REQNUM_EX.
  COMMIT WORK AND WAIT.
******************* DELETING PRIVIOUS RISK ANALYSIS**************************

  IF MODULEID = 'MM'.
    LOOP AT G_TABLCTRL110_ITAB INTO G_TABLCTRL110_WA.

      MOVE-CORRESPONDING G_TABLCTRL110_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.
  ELSEIF MODULEID = 'SD'.
    LOOP AT G_TABLCTRL114_ITAB INTO G_TABLCTRL114_WA.

      MOVE-CORRESPONDING G_TABLCTRL114_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.
  ELSEIF MODULEID = 'PP'.
    LOOP AT G_TABLCTRL113_ITAB INTO G_TABLCTRL113_WA.

      MOVE-CORRESPONDING G_TABLCTRL113_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.

  ELSEIF MODULEID = 'PM'.
    LOOP AT G_TABLCTRL111_ITAB INTO G_TABLCTRL111_WA.

      MOVE-CORRESPONDING G_TABLCTRL111_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.

  ELSEIF MODULEID = 'PS'.
    LOOP AT G_TABLCTRL112_ITAB INTO G_TABLCTRL112_WA.

      MOVE-CORRESPONDING G_TABLCTRL112_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.

  ELSEIF MODULEID = 'HSE'.
    LOOP AT G_TABLCTRL116_ITAB INTO G_TABLCTRL116_WA.

      MOVE-CORRESPONDING G_TABLCTRL116_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.


  ELSEIF MODULEID = 'QM'.
    LOOP AT G_TABLCTRL115_ITAB INTO G_TABLCTRL115_WA.

      MOVE-CORRESPONDING G_TABLCTRL115_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.

  ELSEIF MODULEID = 'OLM'.
    LOOP AT G_TC_117_ITAB INTO G_TC_117_WA .

      MOVE-CORRESPONDING G_TC_117_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.

    """"""""""""""""""""""""""""""""""""""
    "added by lipsy  for srm module introduction ON 3.03.2015 RD1K996555
  ELSEIF MODULEID = 'SRM'.
    LOOP AT G_TABLCTRL118_ITAB INTO G_TABLCTRL118_WA.

      MOVE-CORRESPONDING G_TABLCTRL118_WA TO WA_BUCKET.
      WA_BUCKET-DOCNO = REQNUM_EX.
      APPEND WA_BUCKET TO GT_BUCKET.
*    CLEAR WA_BUCKET.
    ENDLOOP.

    "end of addition by lipsy  for srm module introduction ON 3.03.2015 RD1K996555
    """""""""""""""""""""""""""""""""""""""""""""""""


  ENDIF.


  DELETE GT_BUCKET WHERE REJ_FL = 'H'.

  SELECT * FROM ZIC_PREP_ROLEREI INTO CORRESPONDING FIELDS OF TABLE GT_CRMODULE WHERE
    DOCNO = REQNUM_EX AND MODULEID NE  MODULEID.

  IF SY-SUBRC EQ 0.

    LOOP AT GT_CRMODULE INTO WA_CRMODULE .
      MOVE-CORRESPONDING WA_CRMODULE TO WA_BUCKET.
      APPEND  WA_BUCKET TO GT_BUCKET.
    ENDLOOP.
    CLEAR WA_CRMODULE.

  ENDIF.

  LOOP AT GT_BUCKET INTO WA_BUCKET.

    MOVE-CORRESPONDING WA_BUCKET TO WA_BUCKET1.
    APPEND  WA_BUCKET1 TO GT_BUCKET1.



    CALL FUNCTION 'ZGRC_DEV_FM'
      EXPORTING
        T_TBTC    = GT_BUCKET1
        REQ_NUM   = WA_BUCKET-DOCNO
      IMPORTING
        IT_ROLES2 = GT_EROLES.

*CLEAR WA_BUCKET1.
    LOOP AT  GT_EROLES INTO WA_EROLES.

      MOVE-CORRESPONDING WA_EROLES TO WA_EROLES1.
      APPEND WA_EROLES1 TO  GT_EROLES1.

    ENDLOOP.
  ENDLOOP.

  LOOP AT GT_BUCKET1 INTO WA_BUCKET1.
    WA_BUK_ROLE-DOCNO	=	WA_BUCKET1-DOCNO.
    WA_BUK_ROLE-MODULEID  = WA_BUCKET1-MODULEID.
    WA_BUK_ROLE-SRNO  = WA_BUCKET1-SRNO.
    WA_BUK_ROLE-ROLE_NAME	=	WA_BUCKET1-ROLE_NAME.
    WA_BUK_ROLE-PLANT = WA_BUCKET1-PLANT .
    WA_BUK_ROLE-GRP = WA_BUCKET1-GRP .
    WA_BUK_ROLE-SLOC  = WA_BUCKET1-SLOC  .
    WA_BUK_ROLE-RECEIPT_LOC = WA_BUCKET1-RECEIPT_LOC .
    WA_BUK_ROLE-APPROVER  = WA_BUCKET1-APPROVER  .
    WA_BUK_ROLE-STATUS  = WA_BUCKET1-STATUS  .
    WA_BUK_ROLE-ROLE_REQUEST  = WA_BUCKET1-ROLE_REQUEST.
    WA_BUK_ROLE-REJ_FL  = WA_BUCKET1-REJ_FL  .
    WA_BUK_ROLE-REJ_ID  = WA_BUCKET1-REJ_ID  .
    WA_BUK_ROLE-REJ_DATE  = WA_BUCKET1-REJ_DATE  .
    WA_BUK_ROLE-REJ_FL_SAVE = WA_BUCKET1-REJ_FL_SAVE .
    WA_BUK_ROLE-SHOP_NO = WA_BUCKET1-SHOP_NO .
    WA_BUK_ROLE-ROLE_DESC = WA_BUCKET1-ROLE_DESC .
    WA_BUK_ROLE-FLAG  = WA_BUCKET1-FLAG  .
    WA_BUK_ROLE-GL_ACCOUNT  = WA_BUCKET1-GL_ACCOUNT  .
    WA_BUK_ROLE-BUSSINESS_AREA  = WA_BUCKET1-BUSSINESS_AREA  .
    WA_BUK_ROLE-FUND_CTR_GP = WA_BUCKET1-FUND_CTR_GP .
    WA_BUK_ROLE-JVA_GRP = WA_BUCKET1-JVA_GRP .
    WA_BUK_ROLE-SUB_MODULE  = WA_BUCKET1-SUB_MODULE.
    WA_BUK_ROLE-ROLE_SENSITIVITY  = WA_BUCKET1-ROLE_SENSITIVITY  .
    WA_BUK_ROLE-FR_DATE_AUTH  = WA_BUCKET1-FR_DATE_AUTH  .
    WA_BUK_ROLE-TO_DATE_AUTH  = WA_BUCKET1-TO_DATE_AUTH.
    WA_BUK_ROLE-ROLE_TYPE_EX  = WA_BUCKET-ROLE_TYPE_EX  .
    WA_BUK_ROLE-SALE_ORG  = WA_BUCKET1-SALE_ORG  .
    WA_BUK_ROLE-DIV = WA_BUCKET1-DIV .
    WA_BUK_ROLE-SHIP_POINT  = WA_BUCKET1-SHIP_POINT  .
    WA_BUK_ROLE-ASSET = WA_BUCKET1-ASSET .
    WA_BUK_ROLE-BASIN = WA_BUCKET1-BASIN .
    WA_BUK_ROLE-PROJECT = WA_BUCKET1-PROJECT .
    WA_BUK_ROLE-LOCATION  = WA_BUCKET1-LOCATION  .
    WA_BUK_ROLE-ASSET_QM  = WA_BUCKET1-ASSET_QM  .
    WA_BUK_ROLE-RES = WA_BUCKET1-RES .
    WA_BUK_ROLE-CTF_SLOC  = WA_BUCKET1-CTF_SLOC  .

    LOOP AT GT_EROLES INTO WA_EROLES WHERE ROLE_TYPE = WA_BUK_ROLE-ROLE_NAME .

      WA_BUK_ROLE-USERID  = WA_EROLES-USERID  .
      WA_BUK_ROLE-ROLE_TYPE	=	WA_EROLES-ROLE_TYPE	.
      WA_BUK_ROLE-ROLE_NAME_FINAL	=	WA_EROLES-ROLE_NAME	.
      WA_BUK_ROLE-FR_DATE_AUTH_FINAL  = WA_EROLES-FR_DATE_AUTH  .
      WA_BUK_ROLE-TO_DATE_AUTH_FINAL  = WA_EROLES-TO_DATE_AUTH  .

*BOC By SAP_ABAP on 26/10/26
*     IF  WA_BUK_ROLE-ROLE_NAME_FINAL = 'M:COMMON_USER_TOOLS'.
* Role renamed on S/4 (mail from Uday Mahato, SAP, 09/10/26):
*   'M:COMMON_USER_TOOLS' -> 'Z:S:BS:GENERAL_ACCESS:M:ALL'
      IF  WA_BUK_ROLE-ROLE_NAME_FINAL = 'Z:S:BS:GENERAL_ACCESS:M:ALL'.
*EOC By SAP_ABAP on 26/10/26
        WA_BUK_ROLE-ROLE_NAME = ''.
        WA_BUK_ROLE-ROLE_TYPE = ''.
      ENDIF.


      APPEND WA_BUK_ROLE TO GT_BUK_ROLE.



    ENDLOOP.

    CLEAR  WA_BUK_ROLE.
  ENDLOOP.
  SORT GT_BUK_ROLE BY ROLE_NAME_FINAL.
  DELETE ADJACENT DUPLICATES FROM GT_BUK_ROLE COMPARING ROLE_NAME_FINAL.

  SORT GT_EROLES1 BY ROLE_NAME.
  DELETE ADJACENT DUPLICATES FROM GT_EROLES1 COMPARING ROLE_NAME.

*  IF GT_BUCKET1 IS NOT INITIAL.
  SELECT USERID DESIGNATION PERSA RSN_CODE TELNO CCODE FUNDC1 PERSK REASONFORAUTH
  COSTC DESIG_LEVEL NAME NAME1 RSN_TEXT1
  FROM ZIC_PREP_ROLEREQ
  INTO CORRESPONDING FIELDS OF TABLE GT_USERINFO
  WHERE DOCNO = WA_BUCKET-DOCNO.
*  ENDIF.

  IF GT_BUCKET1 IS INITIAL.
    MESSAGE 'All Role are rejected by HOF !!' TYPE 'I'.
    RETURN.
  ENDIF .


  IF SYST-SYSID = 'OCD'.

    LV_RFC = 'GRDCLNT500'.

  ELSEIF SYST-SYSID = 'OCQ'.

    LV_RFC = 'GRDCLNT500'.

  ELSEIF SYST-SYSID = 'OCP'.

    LV_RFC = 'GRPCLNT500'.
  ENDIF.

  CALL FUNCTION 'ZGRC_RFC_FM' DESTINATION LV_RFC "'GRDCLNT500'
*  CALL FUNCTION 'ZGRC_RFC_FM' DESTINATION 'GRPCLNT500TEST'        changes on 02.08.2014  CAB_DNS
    EXPORTING
      IT_ROLES2       = GT_EROLES1
      IP_BUCKET       = GT_BUCKET1
      IP_USERINFO     = GT_USERINFO
      IP_COKCODE      = CHECK_OKCODE
    IMPORTING
      ET_FINAL        = GT_OUTPUT
      GT_RISK_DESC    = GT_RDESC    " PERMISSION LEVEL RISK
      LT_ACT_VIOL_DET = GT_VIOLDTL
      GT_COMPLETE     = GT_CP_RISK  " COMPLETE RISK ( UNION OF GT_RDESC AND  GT_ACTION_RISK)
      GT_ACC_RISK     = GT_ACTION_RISK. " ACCTION LEVEL RISK

*   IF GT_RDESC IS INITIAL.

  EXPORT GT_RDESC TO MEMORY ID 'IM_GT_RDESC'.
*     ENDIF.


  CHECK SY-SUBRC EQ 0.
  DESCRIBE TABLE GT_VIOLDTL LINES LV_LINES.
*   LV_LINES = SY-DBCNT.
  CLEAR: GD_PERCENT.


  READ TABLE GT_BUK_ROLE INTO WA_BUK_ROLE INDEX 1.  "#EC CI_NOORDER
  IF SY-SUBRC = 0.
    LV_DOCNO = WA_BUK_ROLE-DOCNO.
  ENDIF.

  LOOP AT GT_RDESC INTO WA_RDESC. "WHERE COMPROLE EQ WA_FINAL_TB-ROLE_NAME_FINAL OR ROLE EQ WA_FINAL_TB-ROLE_NAME_FINAL .

    WA_FINAL_TB-XCONNECTOR  = WA_RDESC-XCONNECTOR  .
    WA_FINAL_TB-OBJECTID  = WA_RDESC-OBJECTID  .
    WA_FINAL_TB-RISKID  = WA_RDESC-RISKID  .
    WA_FINAL_TB-ACTRULEID = WA_RDESC-ACTRULEID  .
    WA_FINAL_TB-CONNECTOR = WA_RDESC-CONNECTOR  .
    WA_FINAL_TB-FUNCTID = WA_RDESC-FUNCTID  .
    WA_FINAL_TB-ACTION  = WA_RDESC-ACTION  .
    WA_FINAL_TB-RESOURCEID  = WA_RDESC-RESOURCEID  .
    WA_FINAL_TB-RESOURCEEXTN  = WA_RDESC-RESOURCEEXTN  .
    WA_FINAL_TB-FROMVAL = WA_RDESC-FROMVAL  .
    WA_FINAL_TB-TOVAL = WA_RDESC-TOVAL  .
    WA_FINAL_TB-ROLE  = WA_RDESC-ROLE  .
    WA_FINAL_TB-COMPROLE  = WA_RDESC-COMPROLE  .
    WA_FINAL_TB-ACCONTROLID = WA_RDESC-ACCONTROLID  .
    WA_FINAL_TB-MONITOR = WA_RDESC-MONITOR  .
    WA_FINAL_TB-ORGRULEID = WA_RDESC-ORGRULEID  .
    WA_FINAL_TB-PRMSOURCE = WA_RDESC-PRMSOURCE  .
    WA_FINAL_TB-RISKTYPE  = WA_RDESC-RISKTYPE  .
    WA_FINAL_TB-OBJECTTYPE  = WA_RDESC-OBJECTTYPE  .
    WA_FINAL_TB-VALIDFROM = WA_RDESC-VALIDFROM  .
    WA_FINAL_TB-VALIDTO = WA_RDESC-VALIDTO  .
    WA_FINAL_TB-ACTIVE  = WA_RDESC-ACTIVE  .
    WA_FINAL_TB-LASTEXECUTEDON  = WA_RDESC-LASTEXECUTEDON  .
    WA_FINAL_TB-TERMINALNAME  = WA_RDESC-TERMINALNAME  .
    WA_FINAL_TB-EXECUTIONCOUNT  = WA_RDESC-EXECUTIONCOUNT  .
    WA_FINAL_TB-LANG  = WA_RDESC-LANG  .
    WA_FINAL_TB-DESCN  = WA_RDESC-DESCN  .
    WA_FINAL_TB-DT_DESC  = WA_RDESC-DT_DESC  .
    WA_FINAL_TB-GRC_RQNO  = WA_RDESC-GRC_RQNO  .


*  V_SNUM = LV_SNUM = LV_SNUM + 1.
    V_SNUM = V_SNUM + 1.
    WA_FINAL_TB-SERIALNO = V_SNUM.

*  start of role
    READ TABLE GT_BUK_ROLE INTO WA_BUK_ROLE WITH KEY ROLE_NAME_FINAL = WA_RDESC-COMPROLE.
    IF SY-SUBRC NE 0.
      READ TABLE GT_BUK_ROLE INTO WA_BUK_ROLE WITH KEY ROLE_NAME_FINAL = WA_RDESC-ROLE.
    ENDIF.
    WA_FINAL_TB-DOCNO =     LV_DOCNO. "WA_BUK_ROLE-DOCNO.
    WA_FINAL_TB-MODULEID = 	 WA_BUK_ROLE-MODULEID.
    WA_FINAL_TB-SRNO  =	 WA_BUK_ROLE-SRNO.
    WA_FINAL_TB-ROLE_NAME =     WA_BUK_ROLE-ROLE_NAME.
    WA_FINAL_TB-PLANT =	 WA_BUK_ROLE-PLANT .
    WA_FINAL_TB-GRP =	 WA_BUK_ROLE-GRP .
    WA_FINAL_TB-SLOC  =	 WA_BUK_ROLE-SLOC  .
    WA_FINAL_TB-RECEIPT_LOC =	 WA_BUK_ROLE-RECEIPT_LOC .
    WA_FINAL_TB-APPROVER  =	 WA_BUK_ROLE-APPROVER  .
    WA_FINAL_TB-STATUS = WA_BUK_ROLE-STATUS  .
    WA_FINAL_TB-ROLE_REQUEST =   WA_BUK_ROLE-ROLE_REQUEST.
    WA_FINAL_TB-REJ_FL = 	 WA_BUK_ROLE-REJ_FL  .
    WA_FINAL_TB-REJ_ID = 	 WA_BUK_ROLE-REJ_ID  .
    WA_FINAL_TB-REJ_DATE = 	 WA_BUK_ROLE-REJ_DATE  .
    WA_FINAL_TB-REJ_FL_SAVE =	 WA_BUK_ROLE-REJ_FL_SAVE .
    WA_FINAL_TB-SHOP_NO =	 WA_BUK_ROLE-SHOP_NO .
    WA_FINAL_TB-ROLE_DESC =	 WA_BUK_ROLE-ROLE_DESC .
    WA_FINAL_TB-FLAG = 	 WA_BUK_ROLE-FLAG  .
    WA_FINAL_TB-GL_ACCOUNT =     WA_BUK_ROLE-GL_ACCOUNT  .
    WA_FINAL_TB-BUSSINESS_AREA =     WA_BUK_ROLE-BUSSINESS_AREA  .
    WA_FINAL_TB-FUND_CTR_GP =	 WA_BUK_ROLE-FUND_CTR_GP .
    WA_FINAL_TB-JVA_GRP =	 WA_BUK_ROLE-JVA_GRP .
    WA_FINAL_TB-SUB_MODULE  =	 WA_BUK_ROLE-SUB_MODULE.
    WA_FINAL_TB-ROLE_SENSITIVITY  =	 WA_BUK_ROLE-ROLE_SENSITIVITY  .
    WA_FINAL_TB-FR_DATE_AUTH  =	 WA_BUK_ROLE-FR_DATE_AUTH  .
    WA_FINAL_TB-TO_DATE_AUTH = 	 WA_BUK_ROLE-TO_DATE_AUTH.
    WA_FINAL_TB-ROLE_TYPE_EX  =	 WA_BUCKET-ROLE_TYPE_EX  .
    WA_FINAL_TB-SALE_ORG = 	 WA_BUK_ROLE-SALE_ORG  .
    WA_FINAL_TB-DIV =	 WA_BUK_ROLE-DIV .
    WA_FINAL_TB-SHIP_POINT =     WA_BUK_ROLE-SHIP_POINT  .
    WA_FINAL_TB-ASSET =    WA_BUK_ROLE-ASSET .
    WA_FINAL_TB-BASIN =	 WA_BUK_ROLE-BASIN .
    WA_FINAL_TB-PROJECT =	 WA_BUK_ROLE-PROJECT .
    WA_FINAL_TB-LOCATION = 	 WA_BUK_ROLE-LOCATION  .
    WA_FINAL_TB-ASSET_QM  =	 WA_BUK_ROLE-ASSET_QM  .
    WA_FINAL_TB-RES =	 WA_BUK_ROLE-RES .
    WA_FINAL_TB-CTF_SLOC  =	 WA_BUK_ROLE-CTF_SLOC  .
    WA_FINAL_TB-USERID  = WA_BUK_ROLE-USERID  .
    WA_FINAL_TB-ROLE_TYPE	=	WA_BUK_ROLE-ROLE_TYPE	.
    WA_FINAL_TB-ROLE_NAME_FINAL	=	WA_BUK_ROLE-ROLE_NAME_FINAL	.
    WA_FINAL_TB-FR_DATE_AUTH_FINAL  = WA_BUK_ROLE-FR_DATE_AUTH_FINAL  .
    WA_FINAL_TB-TO_DATE_AUTH_FINAL  = WA_BUK_ROLE-TO_DATE_AUTH_FINAL  .

*  end of role

    APPEND WA_FINAL_TB TO GT_FINAL_TB.
    CLEAR :WA_FINAL_TB,GS_OUTPUT_TEMP,WA_BUK_ROLE.


  ENDLOOP.




  CLEAR: LV_DOCNO.
  IF GT_FINAL_TB[] IS INITIAL.
*  V_SNUM = LV_SNUM = LV_SNUM + 1.
    V_SNUM = V_SNUM + 1.
    WA_FINAL_TB-SERIALNO = V_SNUM.
    WA_FINAL_TB-DOCNO = REQNUM_EX.
    APPEND WA_FINAL_TB TO GT_FINAL_TB.
    CLEAR: WA_FINAL_TB.
  ENDIF.

*SELECT SINGLE MAX( SERIALNO ) FROM ZGRC_VIOL_DTL INTO LV_SNUM1.


  LOOP AT GT_ACTION_RISK INTO WA_ACTION_RISK.

    LV_INDX1 = SY-TABIX.


    V_SNUM1 = V_SNUM1 + 1.
    WA_VIOL_DTL-DOCNO =     REQNUM_EX.
    WA_VIOL_DTL-SERIALNO = V_SNUM1.

    WA_VIOL_DTL-XCONNECTOR  = WA_ACTION_RISK-XCONNECTOR  .
    WA_VIOL_DTL-OBJECTID  = WA_ACTION_RISK-OBJECTID  .
    WA_VIOL_DTL-RISKID  = WA_ACTION_RISK-RISKID  .
    WA_VIOL_DTL-ACTRULEID = WA_ACTION_RISK-ACTRULEID  .
    WA_VIOL_DTL-CONNECTOR = WA_ACTION_RISK-CONNECTOR  .
    WA_VIOL_DTL-FUNCTID = WA_ACTION_RISK-FUNCTID  .
    WA_VIOL_DTL-ACTION  = WA_ACTION_RISK-ACTION  .
    WA_VIOL_DTL-RESOURCEID  = WA_ACTION_RISK-RESOURCEID  .
    WA_VIOL_DTL-RESOURCEEXTN  = WA_ACTION_RISK-RESOURCEEXTN  .
    WA_VIOL_DTL-FROMVAL = WA_ACTION_RISK-FROMVAL  .
    WA_VIOL_DTL-TOVAL = WA_ACTION_RISK-TOVAL  .
    WA_VIOL_DTL-ROLE  = WA_ACTION_RISK-ROLE  .
    WA_VIOL_DTL-COMPROLE  = WA_ACTION_RISK-COMPROLE  .
    WA_VIOL_DTL-ACCONTROLID = WA_ACTION_RISK-ACCONTROLID  .
    WA_VIOL_DTL-MONITOR = WA_ACTION_RISK-MONITOR  .
    WA_VIOL_DTL-ORGRULEID = WA_ACTION_RISK-ORGRULEID  .
    WA_VIOL_DTL-PRMSOURCE = WA_ACTION_RISK-PRMSOURCE  .
    WA_VIOL_DTL-RISKTYPE  = WA_ACTION_RISK-RISKTYPE  .
    WA_VIOL_DTL-OBJECTTYPE  = WA_ACTION_RISK-OBJECTTYPE  .
    WA_VIOL_DTL-VALIDFROM = WA_ACTION_RISK-VALIDFROM  .
    WA_VIOL_DTL-VALIDTO = WA_ACTION_RISK-VALIDTO  .
    WA_VIOL_DTL-ACTIVE  = WA_ACTION_RISK-ACTIVE  .
    WA_VIOL_DTL-LASTEXECUTEDON  = WA_ACTION_RISK-LASTEXECUTEDON  .
    WA_VIOL_DTL-TERMINALNAME  = WA_ACTION_RISK-TERMINALNAME  .
    WA_VIOL_DTL-EXECUTIONCOUNT  = WA_ACTION_RISK-EXECUTIONCOUNT  .


*    READ TABLE GT_FINAL_RISK  INTO WA_FINAL_RISK WITH KEY RISKID = WA_FINAL-RISKID.

*    READ TABLE GT_FINAL_TB INTO WA_FINAL_TB WITH KEY RISKID = WA_VIOLDTL-RISKID.

    PERFORM PROGRESS_BAR USING 'Please wait Risk analysis is in process..'(004)
                               LV_INDX1
                               LV_LINES.

    WA_VIOL_DTL-DESCN = WA_ACTION_RISK-DESCN.
    WA_VIOL_DTL-DT_DESC = WA_ACTION_RISK-DT_DESC.
    WA_VIOL_DTL-GRC_RQNO = WA_ACTION_RISK-GRC_RQNO.

    APPEND WA_VIOL_DTL TO GT_VIOL_DTL.
    CLEAR: WA_VIOL_DTL.
    CLEAR WA_ACTION_RISK.
    CLEAR WA_FINAL_TB.
  ENDLOOP.

  IF GT_VIOL_DTL[] IS INITIAL.
    V_SNUM1 = V_SNUM1 + 1.
    WA_VIOL_DTL-SERIALNO = V_SNUM1.
    WA_VIOL_DTL-DOCNO = REQNUM_EX.
    APPEND WA_VIOL_DTL TO GT_VIOL_DTL.
    CLEAR: WA_VIOL_DTL.
  ENDIF.

*************** Progress indicator
*DATA: LV_LINES TYPE I.




*  LOOP AT GT_FINAL_TB INTO WA_FINAL_TB.

*    ENDLOOP.

*************** Progress indicator





  MODIFY  ZGRC_SOD_RESULT FROM  TABLE GT_FINAL_TB .
  MODIFY  ZGRC_VIOL_DTL FROM  TABLE GT_VIOL_DTL .
  COMMIT WORK AND WAIT.

*  REQNUM_ALV = ZIC_PREP_ROLEREQ-DOCNO.
*
*  IMPORT  REQNUM_ALV FROM MEMORY ID 'REQNUM_IP'.
*  CALL TRANSACTION 'ZGRC_RESULT'.


ENDFORM.                    " GRC_RISK_ANALYSIS
*&---------------------------------------------------------------------*
*&      Form  PROGRESS_BAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2086   text
*      -->P_LV_INDX1  text
*      -->P_LV_LINES  text
*----------------------------------------------------------------------*
FORM PROGRESS_BAR  USING    VALUE(P_2086)
                            P_LV_INDX1
                            P_LV_LINES.
  DATA: W_TEXT(40),
        W_PERCENTAGE      TYPE P,
        W_PERCENT_CHAR(3).

  W_PERCENTAGE = ( P_LV_INDX1 / P_LV_LINES ) * 100.
  W_PERCENT_CHAR = W_PERCENTAGE.
  SHIFT W_PERCENT_CHAR LEFT DELETING LEADING ' '.
  CONCATENATE P_2086 W_PERCENT_CHAR '% Complete'(006) INTO W_TEXT SEPARATED BY SPACE.

*  IF W_PERCENTAGE GT GD_PERCENT OR P_LV_INDX1 EQ 1.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      PERCENTAGE = W_PERCENTAGE
      TEXT       = W_TEXT.
  GD_PERCENT = W_PERCENTAGE.
*  ENDIF.                " PROGRESS_BAR

ENDFORM.                    " PROGRESS_BAR
" DISPLAY_INFO
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM DISPLAY_INFO .
*
*  DATA : L_ANS TYPE C.
*
*  CALL FUNCTION 'POPUP_TO_CONFIRM'
*    EXPORTING
*     TITLEBAR                    = 'ZICE_ARMS USER GUIDE-NEW'
**   DIAGNOSE_OBJECT             = ' '
*      TEXT_QUESTION               = 'The process for ZICE_ARMS has been changed to include an alert &'
*      &' approval process for possible Segregation of Duties Risk in roles of the user.'
*      &' Documentation on the revised process is available in User Guide Section as " ZICE_ARMS USER GUIDE-NEW. " '
*
*      TEXT_BUTTON_1               = 'YES'(098)
**   ICON_BUTTON_1               = ' '
*     TEXT_BUTTON_2               = 'NO'(099)
**   ICON_BUTTON_2               = ' '
**   DEFAULT_BUTTON              = '1'
*     DISPLAY_CANCEL_BUTTON       = ' '
**   USERDEFINED_F1_HELP         = ' '
*     START_COLUMN                = 25
*     START_ROW                   = 6
**   POPUP_TYPE                  =
**   IV_QUICKINFO_BUTTON_1       = ' '
**   IV_QUICKINFO_BUTTON_2       = ' '
*   IMPORTING
*     ANSWER                      = L_ANS
** TABLES
**   PARAMETER                   =
*   EXCEPTIONS
*     TEXT_NOT_FOUND              = 1
*     OTHERS                      = 2
*            .
*  IF SY-SUBRC <> 0.
** Implement suitable error handling here
*  ENDIF.
*
*  CASE L_ANS.
*    WHEN '2'.
*      exit.
*    WHEN OTHERS.
*  ENDCASE.
*
*
*
*ENDFORM.                    " DISPLAY_INFO
*&---------------------------------------------------------------------*
*&      Form  LIST_HELP_FILES_NEW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM LIST_HELP_FILES_NEW .
  OBJ-OBJTYPE = OBJTYPE.
  OBJ-OBJKEY =  'ASY'.
*  G_TCODE = SY-TCODE.
*  uname = sy-uname.

  G_TCODE1 = 'DISPLAY'.

  EXPORT : G_TCODE1 FROM G_TCODE1 TO MEMORY ID 'G_TCODE1'.
  CALL METHOD MANAGER->START_SERVICE_DIRECT
    EXPORTING
      IP_SERVICE       = 'VIEW_ATTA'
      IS_OBJECT        = OBJ
    EXCEPTIONS
      NO_OBJECT        = 1
      OBJECT_INVALID   = 2
      EXECUTION_FAILED = 3
      OTHERS           = 4.
ENDFORM.                    " LIST_HELP_FILES_NEW
*&---------------------------------------------------------------------*
*&      Form  CREATE_ROLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CREATE_ROLES .
  CLEAR IT_ROLES0.
  CLEAR IT_ROLES1.

******************************************@
  CASE MODULEID.
    WHEN 'MM'.
      SELECT * FROM ZHELP_MMROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.
    WHEN 'PM'.
      SELECT * FROM ZHELP_PMROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.
    WHEN 'PS'.
      SELECT * FROM ZHELP_PSROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.
    WHEN 'PP'.
      SELECT * FROM ZHELP_PPROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.
    WHEN 'SD'.
      SELECT * FROM ZHELP_SDROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.
    WHEN 'QM'.
      SELECT * FROM ZHELP_QMROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.
    WHEN 'HSE'.
      SELECT * FROM ZHELP_HSROLES INTO CORRESPONDING FIELDS OF TABLE IT_ROLES.

  ENDCASE.
******************************************@

  LOOP AT IT_ROLES INTO WA_ROLES.

    PERFORM CHECK_MUM.
    APPEND WA_ROLES TO IT_ROLES0.

  ENDLOOP.

  CLEAR WA_ROLES.
  LOOP AT IT_ROLES0 INTO WA_ROLES.

    IF NOT WA_ROLES-ROLE_TYPE IS INITIAL.

*      LOOP AT g_tablctrl110_itab INTO wa_item_req.
*        MOVE-CORRESPONDING wa_item_req TO wa_itemtab_sl.
*        APPEND wa_itemtab_sl TO ist_itemtab.
*      ENDLOOP.

********************************************@
      IF MODULEID = 'MM'.

        LOOP AT G_TABLCTRL110_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ELSEIF MODULEID = 'SD'.

        LOOP AT G_TABLCTRL114_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ELSEIF MODULEID = 'PP'.

        LOOP AT G_TABLCTRL113_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ELSEIF MODULEID = 'PM'.

        LOOP AT G_TABLCTRL111_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ELSEIF MODULEID = 'PS'.

        LOOP AT G_TABLCTRL112_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ELSEIF MODULEID = 'HSE'.

        LOOP AT G_TABLCTRL116_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ELSEIF MODULEID = 'QM'.

        LOOP AT G_TABLCTRL115_ITAB INTO WA_ITEM_REQ.
          MOVE-CORRESPONDING WA_ITEM_REQ TO WA_ITEMTAB_SL.
          APPEND WA_ITEMTAB_SL TO IST_ITEMTAB.
        ENDLOOP.

      ENDIF.

********************************************@


      LOOP AT IST_ITEMTAB INTO  WA_ITEMTAB_SL.
        IF WA_ROLES-ROLE_TYPE =  WA_ITEMTAB_SL-ROLE_NAME AND
                                 WA_ITEMTAB_SL-REJ_FL = '' AND
                                 WA_ITEMTAB_SL-STATUS = '' AND
                                WA_ITEMTAB_SL-ROLE_REQUEST = ''.
          PERFORM INSERT_DATA.
        ENDIF.
      ENDLOOP.

    ENDIF.

  ENDLOOP.

  LOOP AT IST_ITEMTAB INTO WA_ITEMTAB_SL.
*Begin of <RD1K964305>.
*    IF WA_ROLESZ-ROLE_NAME+0(1) = 'C' AND
    IF ( WA_ITEMTAB_SL-ROLE_NAME+0(1) = 'C' OR WA_ITEMTAB_SL-ROLE_NAME+0(1) = 'N' )  AND
*End of <RD1K964305>.
                         WA_ITEMTAB_SL-REJ_FL = '' AND
                         WA_ITEMTAB_SL-STATUS = '' AND
                         WA_ITEMTAB_SL-ROLE_REQUEST = ''.


      CASE MODULEID.
        WHEN 'MM'.
          PERFORM INSERT_DATA_ADDL.
        WHEN 'PM'.
          PERFORM INSERT_DATA_PM.
        WHEN 'PS'.
          PERFORM INSERT_DATA_PS.
        WHEN 'PP'.
          PERFORM INSERT_DATA_PP.
        WHEN 'SD'.
          PERFORM INSERT_DATA_SD.
        WHEN 'QM'.
          PERFORM INSERT_DATA_QM.
        WHEN 'HSE'.
          PERFORM INSERT_DATA_HS.

      ENDCASE.
    ENDIF.
  ENDLOOP.

  SORT IT_ROLES1.

**** Deleting tempelate as it gets added in logic

  LOOP AT IT_ROLES1 INTO WA_ROLE_DEL_DATA.

    IF WA_ROLE_DEL_DATA-ROLE_NAME = 'D:MM_SRV_IND_APPROVE_XX'
     OR WA_ROLE_DEL_DATA-ROLE_NAME = 'D:MM_PUR_PO_APPROVE_XX'.
      DELETE IT_ROLES1.
    ENDIF.
  ENDLOOP.

  DELETE ADJACENT DUPLICATES FROM IT_ROLES1.

  LOOP AT IT_ROLES1 INTO WA_ROLES1.

    WRITE ZIC_PREP_ROLEREQ-FR_DATE_AUTH TO WA_DAT1 DD/MM/YYYY.

    WRITE ZIC_PREP_ROLEREQ-TO_DATE_AUTH TO WA_DAT2 DD/MM/YYYY.

    WA_ROLES1-FR_DATE_AUTH = WA_DAT1.
    WA_ROLES1-TO_DATE_AUTH = WA_DAT2.
    MODIFY IT_ROLES1 FROM WA_ROLES1.
    CLEAR WA_ROLES1.
  ENDLOOP.


  PERFORM COPY_VALUES.

  PERFORM INSERT_RECORD.

  REFRESH IT_AGR.
  IF ZIC_PREP_ROLEREQ-RSN_CODE = '02' AND ZIC_PREP_ROLEREQ-OFF_ORDER_NO IS INITIAL.
    SET PARAMETER ID 'RCODE' FIELD ZIC_PREP_ROLEREQ-RSN_CODE.
    PERFORM DELIMIT_ROLES.
  ENDIF.

  PERFORM SAVE_REQUEST_ASSIGN.

  GL_ANS = GL_ANS_SAVE.
  CLEAR GL_ANS_SAVE.

  PERFORM FINAL_PROCESS.
  CLEAR : FLAG, FLAG1.

ENDFORM.                    " CREATE_ROLES
*&---------------------------------------------------------------------*
*&      Form  CREATE_ROLES_OLM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CREATE_ROLES_OLM .
  CLEAR IT_ROLES0.
  CLEAR IT_ROLES1.

  REFRESH: IT_ROLES_OLM[].

  SELECT * FROM ZHELP_OLMROLES INTO CORRESPONDING FIELDS OF TABLE
   IT_ROLES_OLM.

  LOOP AT IT_ROLES_OLM INTO WA_ROLES_OLM.
    APPEND WA_ROLES_OLM TO IT_ROLES0.
  ENDLOOP.

  CLEAR WA_ROLES_OLM.
  LOOP AT IT_ROLES0 INTO WA_ROLES_OLM.

    IF NOT WA_ROLES_OLM-ROLE_TYPE IS INITIAL.

      LOOP AT  G_TC_117_ITAB INTO WA_ROLESZ_OLM.
        IF WA_ROLES_OLM-ROLE_TYPE = WA_ROLESZ_OLM-ROLE_NAME .
          WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
          WA_ROLES1-ROLE_NAME = WA_ROLES_OLM-ROLE_NAME.
          APPEND WA_ROLES1 TO IT_ROLES1.
        ENDIF.
      ENDLOOP.

    ENDIF.

  ENDLOOP.

  SORT IT_ROLES1.

  DELETE ADJACENT DUPLICATES FROM IT_ROLES1.

  LOOP AT IT_ROLES1 INTO WA_ROLES1.

    WRITE ZIC_PREP_ROLEREQ-FR_DATE_AUTH TO WA_DAT1 DD/MM/YYYY.

    WRITE ZIC_PREP_ROLEREQ-TO_DATE_AUTH TO WA_DAT2 DD/MM/YYYY.

    WA_ROLES1-FR_DATE_AUTH = WA_DAT1.
    WA_ROLES1-TO_DATE_AUTH = WA_DAT2.
    MODIFY IT_ROLES1 FROM WA_ROLES1.
    CLEAR WA_ROLES1.
  ENDLOOP.

  PERFORM COPY_VALUES.


  PERFORM INSERT_RECORD.
  PERFORM SAVE_REQUEST_ASSIGN.
  GL_ANS = GL_ANS_SAVE.
  CLEAR GL_ANS_SAVE.

  PERFORM FINAL_PROCESS.


ENDFORM.                    " CREATE_ROLES_OLM
*&---------------------------------------------------------------------*
*&      Form  CHECK_MUM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_MUM .
  IF ZIC_PREP_ROLEREQ-CCODE = 'MUM'.
    SEARCH WA_ROLES-ROLE_NAME FOR 'D:FM_LOGS_FFFFFFFF'.
    IF SY-SUBRC = 0.
      WA_ROLES-ROLE_NAME = 'FM_LOGS_FFFFFFFF'.
    ENDIF.
    SEARCH WA_ROLES-ROLE_NAME FOR 'FI_AP_LOGS_DISP_CCC'.
    IF SY-SUBRC = 0.
      WA_ROLES-ROLE_NAME = 'FI_AP_LOGS_DISP_CCC_AL'.
    ENDIF.
  ENDIF.
ENDFORM.                    " CHECK_MUM
*&---------------------------------------------------------------------*
*&      Form  INSERT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA .
  SEARCH WA_ROLES-ROLE_NAME FOR 'INPP'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                WA_ROLES1-ROLE_NAME.
    REPLACE 'INPP' WITH  WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.
*
  SEARCH WA_ROLES-ROLE_NAME FOR 'SSPP'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                  WA_ROLES1-ROLE_NAME.
    REPLACE 'SSPP' WITH  WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.

  ENDIF.

  SEARCH WA_ROLES-ROLE_NAME FOR 'PLANT'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
*Begin of <RD1K963151>.
    IF WA_ROLES-ROLE_TYPE = 'M15' OR WA_ROLES-ROLE_TYPE = 'M20'.
      WA_ROLES1-ROLE_NAME = 'MM_INV_CCC_PLANT_PPPP'.
      REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                 WA_ROLES1-ROLE_NAME.
      REPLACE 'PPPP' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.

      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*End of <RD1K963151>.
      REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                  WA_ROLES1-ROLE_NAME.
      REPLACE 'PPPP' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.

    ENDIF.
  ENDIF.
  SEARCH WA_ROLES-ROLE_NAME FOR 'POPP'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                WA_ROLES1-ROLE_NAME.
    REPLACE 'POPP' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.

  ENDIF.

*
  SEARCH WA_ROLES-ROLE_NAME FOR 'IGG'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
*Begin of <RD1K963151>.
    DATA : L_BUKRS1 TYPE BUKRS.
**---------- Changes Start date 24.06.2016 11:58:29-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*               A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*             D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*             D~DISC_CD AS DISC_CD
*               INTO CORRESPONDING FIELDS OF TABLE IST_DATA1
*          FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                   ON C~DESIGNO = D~DESIG_CODE AND
*                       C~R_P_CD  = D~R_P_CD AND
*                       C~VERSION = D~VERSION )
*                    WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                          A~SPRPS = ' ' AND
*                          A~ENDDA = '99991231' AND
*                          C~SPRPS = ' ' AND
*                          C~ENDDA = '99991231' .


    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
               A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
             D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
             D~DISC_CD AS DISC_CD
               INTO CORRESPONDING FIELDS OF TABLE IST_DATA1
          FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
                ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                   ON C~DESIGNO = D~DESIG_CODE AND
                       C~R_P_CD  = D~R_P_CD AND
                       C~VERSION = D~VERSION )
                    WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                          A~SPRPS = ' ' AND
                          A~ENDDA = '99991231' AND
                          C~SPRPS = ' ' AND
                          C~ENDDA = '99991231' .

**---------- Changee  Ending Date 24.06.2016 11:58:29-----------------
    IF SY-SUBRC = 0.
      READ TABLE IST_DATA1 INDEX 1.  "#EC CI_NOORDER
      L_BUKRS1 = IST_DATA1-BUKRS.
    ENDIF.


*End of <RD1K963151>.
*Begin  of <RD1K963151>.

    """"""""""""""""""""""""""""""
    "added by lipsy  for cross company on 9.03.2015 RD1K996555
    IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
      IF OLD_OK_CODE = 'APPROVE' AND   ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' .
        REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                        WA_ROLES1-ROLE_NAME.
      ELSE.
        "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555
        """""""""""""""""""""""""""""""
        REPLACE 'CCC' WITH L_BUKRS1+0(3) INTO WA_ROLES1-ROLE_NAME.
*    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
*                                  WA_ROLES1-ROLE_NAME.
*End of <RD1K963151>.

        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "added by lipsy  for cross company on 9.03.2015 RD1K996555
      ENDIF.
    ENDIF.
    "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


    REPLACE 'IGG' WITH WA_ITEMTAB_SL-GRP INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.

  ENDIF.

*
  SEARCH WA_ROLES-ROLE_NAME FOR 'SGG'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                        WA_ROLES1-ROLE_NAME.
    REPLACE 'SGG' WITH WA_ITEMTAB_SL-GRP INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.

  ENDIF.
*
  SEARCH WA_ROLES-ROLE_NAME FOR 'PGG'.
  IF SY-SUBRC = 0.

    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
*Begin of <RD1K963151>.
    DATA : L_BUKRS TYPE BUKRS.
**---------- Changes Start date 24.06.2016 11:57:56-------------------
*    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*               A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*             D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*             D~DISC_CD AS DISC_CD
*               INTO CORRESPONDING FIELDS OF TABLE IST_DATA2
*          FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*                ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                   ON C~DESIGNO = D~DESIG_CODE AND
*                       C~R_P_CD  = D~R_P_CD AND
*                       C~VERSION = D~VERSION )
*                    WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
*                          A~SPRPS = ' ' AND
*                          A~ENDDA = '99991231' AND
*                          C~SPRPS = ' ' AND
*                          C~ENDDA = '99991231' .

    SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
              A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
            D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
            D~DISC_CD AS DISC_CD
              INTO CORRESPONDING FIELDS OF TABLE IST_DATA2
         FROM ( ( ZPA0001 AS A INNER JOIN ZPA9930 AS C
               ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
                  ON C~DESIGNO = D~DESIG_CODE AND
                      C~R_P_CD  = D~R_P_CD AND
                      C~VERSION = D~VERSION )
                   WHERE A~PERNR = ZIC_PREP_ROLEREQ-USERID AND
                         A~SPRPS = ' ' AND
                         A~ENDDA = '99991231' AND
                         C~SPRPS = ' ' AND
                         C~ENDDA = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:57:56-----------------

    IF SY-SUBRC = 0.
      READ TABLE IST_DATA2 INDEX 1.  "#EC CI_NOORDER
      L_BUKRS = IST_DATA2-BUKRS.
    ENDIF.
***CODE ADDED BY CAB_AMITMOZA <RD1K983325>   CR: 30007580  dt: 05.04.2013.
    IF ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.
      REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                 WA_ROLES1-ROLE_NAME.
    ELSE.
**CODE END BY CAB_AMITMOZA <RD1K983325>
*End of <RD1K963151>.
*Begin  of <RD1K963151>.
*     REPLACE 'CCC' WITH zic_prep_rolereq-ccode+0(3) INTO
*                                    wa_roles1-role_name.
      REPLACE 'CCC' WITH L_BUKRS+0(3) INTO WA_ROLES1-ROLE_NAME.
*End of <RD1K963151>.
    ENDIF.
    REPLACE 'PGG' WITH WA_ITEMTAB_SL-GRP INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.

  ENDIF.

  SEARCH WA_ROLES-ROLE_NAME FOR 'CCC'.
  IF SY-SUBRC = 0.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    IF FLAG <> 'X'.
      WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
      REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                    WA_ROLES1-ROLE_NAME.
*      APPEND WA_ROLES1 to IT_ROLES1.
    ENDIF.
    FLAG = 'X'.
    IF WA_ROLES-ROLE_TYPE = 'M12' OR WA_ROLES-ROLE_TYPE = 'M17'.
      REPLACE 'RR' WITH WA_ITEMTAB_SL-RECEIPT_LOC+0(2) INTO
                                              WA_ROLES1-ROLE_NAME.


    ENDIF.

    APPEND WA_ROLES1 TO IT_ROLES1.

    SELECT SINGLE * FROM ZHELP_MMROLES_RC WHERE
                        RECEIPT_LOC = WA_ITEMTAB_SL-RECEIPT_LOC AND
                        CCODE = ZIC_PREP_ROLEREQ-CCODE.
    IF SY-SUBRC = 0.
      WA_ROLES1-ROLE_NAME = ZHELP_MMROLES_RC-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.



  ENDIF.

  SEARCH WA_ROLES-ROLE_NAME FOR 'FM_LOGS'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
*BEGIN OF  <RD1K963151>.
    IF ZIC_PREP_ROLEREQ-CCODE = 'OVL'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
*BOC By SAP_ABAP on 26/10/26
*     WA_ROLES1-ROLE_NAME = 'D:FM_LOGS_OVL_ALL'.
* Role renamed on S/4 (mail from Uday Mahato, SAP, 09/10/26):
*   'D:FM_LOGS_OVL_ALL' -> 'Z:E:FM_LOGS_:M:ALL'
      WA_ROLES1-ROLE_NAME = 'Z:E:FM_LOGS_:M:ALL'.
*EOC By SAP_ABAP on 26/10/26
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*END OF <RD1K963151>.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
      IF ZIC_PREP_ROLEREQ-FUNDC1 <> '' AND
            ZIC_PREP_ROLEREQ-FUNDC_FL = 'X'.
        REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC1 INTO
                           WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.
      IF ZIC_PREP_ROLEREQ-FUNDC <> ''.
        WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
        REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC INTO
                           WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.
      IF ZIC_PREP_ROLEREQ-FUNDC2 <> ''.
        WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
        REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC2 INTO
                           WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.
      IF ZIC_PREP_ROLEREQ-FUNDC3 <> ''.
        WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
        REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC3 INTO
                           WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.
      IF ZIC_PREP_ROLEREQ-FUNDC4 <> ''.
        WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
        REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC4 INTO
                           WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.

    ENDIF.
  ENDIF.
  SEARCH WA_ROLES-ROLE_NAME FOR 'MM_SRV_SES_ACCEPT'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
    REPLACE 'YY' WITH WA_ITEMTAB_SL-APPROVER INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.
*
  SEARCH WA_ROLES-ROLE_NAME FOR 'MM_PUR_PO_APPROVE_ZZ'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
    REPLACE 'ZZ' WITH WA_ITEMTAB_SL-APPROVER INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  IF FLAG <> 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
*Begin of <RD1K963151>.
*BOC By SAP_ABAP on 26/10/26
*    IF ZIC_PREP_ROLEREQ-CCODE = 'OVL'  AND WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_ALL'.
*      WA_ROLES1-ROLE_NAME = 'D:MM_OVL_DISPLAY_ALL'.
*    ELSEIF ZIC_PREP_ROLEREQ-CCODE = 'OVL'  AND WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_PM_PS_LIS_CIN'.
*      WA_ROLES1-ROLE_NAME = 'D:MM_OVL_DISPLAY_PM_PS_LIS_CIN'.
*    ENDIF.
*End of <RD1K963151>.
*    APPEND WA_ROLES1 TO IT_ROLES1.
* S/4 role names (mail from Uday Mahato, SAP, 09/10/26):
*   D:MM_DISPLAY_ALL           -> Z:D:MM:DISPLAY:D:OVL
*   D:MM_DISPLAY_PM_PS_LIS_CIN -> Z:D:PM:DISPLAY:M:OVL + Z:D:PS:DISPLAY:D:OVL (two roles)
* ASSUMPTION: ZHELP_MMROLES still delivers the old D:MM_DISPLAY_* names. If the table
* already holds the Z: names, neither branch matches and the row is appended as it is.
    IF ZIC_PREP_ROLEREQ-CCODE = 'OVL' AND WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_ALL'.
      WA_ROLES1-ROLE_NAME = 'Z:D:MM:DISPLAY:D:OVL'.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSEIF ZIC_PREP_ROLEREQ-CCODE = 'OVL' AND
           WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_PM_PS_LIS_CIN'.
      WA_ROLES1-ROLE_NAME = 'Z:D:PM:DISPLAY:M:OVL'.
      APPEND WA_ROLES1 TO IT_ROLES1.
      WA_ROLES1-ROLE_NAME = 'Z:D:PS:DISPLAY:D:OVL'.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
*EOC By SAP_ABAP on 26/10/26

  ENDIF.

  CLEAR FLAG.

  IF WA_ROLES-ROLE_TYPE = 'M13'.
    IF FLAG1 <> 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.

**code added by CAB_AMITMOZA  RD1K983325   CR:30007580
      SELECT * FROM ZMM_PREP_ROLE_SL WHERE
                WERKS = WA_ITEMTAB_SL-PLANT AND
                LGORT = WA_ITEMTAB_SL-SLOC.
**code end RD1K983325

***comment start by CAB_AMITMOZA  RD1K983325   CR:30007580
*      SELECT SINGLE * FROM zmm_prep_role_sl WHERE
*                werks = wa_rolesz-plant AND
*                lgort = wa_rolesz-sloc.
***comment end RD1K983325

        WA_ROLES1-ROLE_NAME = ZMM_PREP_ROLE_SL-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDSELECT.
    ENDIF.
  ENDIF.

  IF WA_ROLES-ROLE_TYPE = 'M14'.
    IF FLAG1 <> 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      SELECT * FROM ZMM_PREP_ROLE_SL UP TO 1 ROWS
 WHERE
 WERKS = WA_ITEMTAB_SL-PLANT AND LGORT = WA_ITEMTAB_SL-SLOC
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      WA_ROLES1-ROLE_NAME = ZMM_PREP_ROLE_SL-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
  ENDIF.

  IF WA_ROLES-ROLE_TYPE = 'M16'.
    IF FLAG1 <> 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      SELECT * FROM ZMM_PREP_ROLE_SL UP TO 1 ROWS
 WHERE
 WERKS = WA_ITEMTAB_SL-PLANT AND LGORT = WA_ITEMTAB_SL-SLOC
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      WA_ROLES1-ROLE_NAME = ZMM_PREP_ROLE_SL-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
  ENDIF.

  IF WA_ROLES-ROLE_TYPE = 'M11S' OR
     WA_ROLES-ROLE_TYPE = 'M11M' OR
     WA_ROLES-ROLE_TYPE = 'M3'   OR
     WA_ROLES-ROLE_TYPE = 'M3A'  OR
     WA_ROLES-ROLE_TYPE = 'M3B'  .

    SEARCH WA_ROLES-ROLE_NAME FOR 'XX'.
    IF SY-SUBRC = 0.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ROLES-ROLE_NAME.
      REPLACE 'XX' WITH WA_ITEMTAB_SL-APPROVER INTO
                                    WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
  ENDIF.

**11/05/2007
  CLEAR FLAG.
ENDFORM.                    " INSERT_DATA
*&---------------------------------------------------------------------*
*&      Form  INSERT_DATA_ADDL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_ADDL .
  CLEAR WA_ROLES1.
  DATA : CONDITION(3) TYPE C.
*Begin of <RD1K962817>.
  CLEAR : LV_MIN_DESIG,
           LV_CURR_ROLE.
*End of <RD1K962817>.
  REFRESH IT_ROLES1_ADDL.
  SELECT * FROM ZMM_PREP_CRCDESG UP TO 1 ROWS
 WHERE
 ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND ROLE_TYPE_EX = WA_ITEMTAB_SL-ROLE_TYPE_EX
 ORDER BY PRIMARY KEY .
 ENDSELECT.
  IF SY-SUBRC = 0.
*Begin of <RD1K962817>.
    LV_MIN_DESIG = ZMM_PREP_CRCDESG-MIN_DESIGNATION.
    LV_CURR_ROLE = ZIC_PREP_ROLEREQ-PERSK.
*End of <RD1K962817>.

*Begin of< RD1K963297>.
*    IF zmm_prep_crcdesg-crc_level_addl <> space.
*      wa_rolesz-approver = zmm_prep_crcdesg-crc_level_addl.
*      IF lv_curr_role = lv_min_desig.
*      ELSE.
*        IF lv_curr_role LE lv_min_desig OR lv_min_desig = space.
*          CASE wa_rolesz-approver.
*            WHEN 'L2'.
*              wa_rolesz-approver = 'L3'.
*            WHEN 'L1'.
*              wa_rolesz-approver = 'L2'.
*            WHEN 'L3'.
*              wa_rolesz-approver = 'L4'.
*          ENDCASE.
*
*        ENDIF.
*      ENDIF.
*      MOVE wa_rolesz-approver TO zmm_prep_crcdesg-crc_level_addl.
    IF ZMM_PREP_CRCDESG-CRC_LEVEL_ADDL <> SPACE.
*      wa_rolesz-approver = zmm_prep_crcdesg-crc_level_addl.
      IF LV_CURR_ROLE = LV_MIN_DESIG  OR LV_MIN_DESIG = SPACE.
      ELSE.
        IF LV_CURR_ROLE LE LV_MIN_DESIG OR LV_MIN_DESIG = SPACE.
*          CASE wa_rolesz-approver.
*            WHEN 'L2'.
*              wa_rolesz-approver = 'L3'.
*            WHEN 'L1'.
*              wa_rolesz-approver = 'L2'.
*            WHEN 'L3'.
*              wa_rolesz-approver = 'L4'.
*          ENDCASE.
          SELECT SINGLE * FROM ZMM_PREP_CRCIMII WHERE
          CRC_LEVEL_ADDL = ZMM_PREP_CRCDESG-CRC_LEVEL_ADDL AND
          CRC_LEVEL      = ZMM_PREP_CRCDESG-CRC_LEVEL   AND
          MIN_DESIGNATION = ZIC_PREP_ROLEREQ-PERSK.
          IF SY-SUBRC = 0 .
            MOVE ZMM_PREP_CRCIMII-PO_LEVEL TO ZMM_PREP_CRCDESG-CRC_LEVEL.
            MOVE ZMM_PREP_CRCIMII-SRV_LEVL TO ZMM_PREP_CRCDESG-CRC_LEVEL_ADDL.
          ELSE .
            MESSAGE E803(ZMM) WITH 'No Entries Found in The Table ZMM_PREP_CRCIMII'.
          ENDIF.
        ENDIF.
      ENDIF.
      MOVE ZMM_PREP_CRCDESG-CRC_LEVEL_ADDL TO WA_ITEMTAB_SL-APPROVER.

    ELSE.    "zmm_prep_crcdesg-crc_level_addl IS INITIAL.  LV_CURR_ROLE LE LV_MIN_DESIG.
      WA_ITEMTAB_SL-APPROVER = ZMM_PREP_CRCDESG-CRC_LEVEL.
      IF LV_CURR_ROLE = LV_MIN_DESIG OR LV_MIN_DESIG = SPACE..
      ELSE.
        IF LV_CURR_ROLE LE LV_MIN_DESIG OR LV_MIN_DESIG = SPACE.
          MESSAGE 'You do not meet the minimum designation criteria. Pls. contact SAP team with a copy of order for further action.' TYPE 'E'.
*          CASE WA_ITEMTAB_SL-APPROVER.
*            WHEN 'L2'.
*              WA_ITEMTAB_SL-APPROVER = 'L3'.
*            WHEN 'L1'.
*              WA_ITEMTAB_SL-APPROVER = 'L2'.
*            WHEN 'L3'.
*              WA_ITEMTAB_SL-APPROVER = 'L4'.
*          ENDCASE.
        ENDIF.
      ENDIF.
      MOVE WA_ITEMTAB_SL-APPROVER TO ZMM_PREP_CRCDESG-CRC_LEVEL.
    ENDIF.
*End of < RD1K963297>.
    IF ZMM_PREP_CRCDESG-CRC_LEVEL = 'L1'.
      SELECT * FROM ZHELP_MMROLES INTO CORRESPONDING FIELDS OF TABLE
             IT_ROLES1_ADDL WHERE ROLE_TYPE = 'M3'.
    ELSEIF  ZMM_PREP_CRCDESG-CRC_LEVEL = 'L2' OR
            ZMM_PREP_CRCDESG-CRC_LEVEL = 'L3' OR
            ZMM_PREP_CRCDESG-CRC_LEVEL = 'IM' OR
*Begin of <RD1K963297>.
           ZMM_PREP_CRCDESG-CRC_LEVEL = 'SM'.
*End of <RD1K963297>.
      SELECT * FROM ZHELP_MMROLES INTO CORRESPONDING FIELDS OF TABLE
             IT_ROLES1_ADDL WHERE ROLE_TYPE = 'M3A'.
    ELSEIF ZMM_PREP_CRCDESG-CRC_LEVEL = 'L4' OR
            ZMM_PREP_CRCDESG-CRC_LEVEL = 'E5' OR
            ZMM_PREP_CRCDESG-CRC_LEVEL = 'E6' OR
            ZMM_PREP_CRCDESG-CRC_LEVEL = 'E7'.
      SELECT * FROM ZHELP_MMROLES INTO CORRESPONDING FIELDS OF TABLE
             IT_ROLES1_ADDL WHERE ROLE_TYPE = 'M3B'.
    ELSEIF ( ZMM_PREP_CRCDESG-CRC_LEVEL = 'SM' AND
            ZMM_PREP_CRCDESG-CRC_LEVEL_ADDL = 'SM' ).

      SELECT * FROM ZHELP_MMROLES INTO CORRESPONDING FIELDS OF TABLE
            IT_ROLES1_ADDL WHERE ROLE_TYPE = 'M11M'.
    ENDIF.
    CLEAR FLAG.
    LOOP AT IT_ROLES1_ADDL INTO WA_ROLES1.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ROLES1-ROLE_NAME.
      SEARCH WA_ROLES1-ROLE_NAME FOR 'XX'.
      IF SY-SUBRC = 0.
        FLAG = 'X'.
        REPLACE 'XX' WITH WA_ITEMTAB_SL-APPROVER INTO
                                     WA_ITEMTAB_SL-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.
      SEARCH WA_ROLES1-ROLE_NAME FOR 'QQ'.
      IF SY-SUBRC = 0.
        FLAG = 'X'.
        REPLACE 'QQ' WITH ZMM_PREP_CRCDESG-CRC_LEVEL INTO
                                      WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.
      SEARCH WA_ROLES1-ROLE_NAME FOR 'PLANT'.
      IF SY-SUBRC = 0.
        FLAG = 'X'.
        REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                              WA_ROLES1-ROLE_NAME.
        REPLACE 'PPPP' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.

      SEARCH WA_ROLES1-ROLE_NAME FOR 'FM_LOGS'.
      IF SY-SUBRC = 0.
        FLAG = 'X'.
*BEGIN OF  <RD1K963151>.
        IF ZIC_PREP_ROLEREQ-CCODE = 'OVL'.

*BOC By SAP_ABAP on 26/10/26
*         WA_ROLES1-ROLE_NAME = 'D:FM_LOGS_OVL_ALL'.
* Role renamed on S/4 (mail from Uday Mahato, SAP, 09/10/26):
*   'D:FM_LOGS_OVL_ALL' -> 'Z:E:FM_LOGS_:M:ALL'
          WA_ROLES1-ROLE_NAME = 'Z:E:FM_LOGS_:M:ALL'.
*EOC By SAP_ABAP on 26/10/26
          APPEND WA_ROLES1 TO IT_ROLES1.
        ELSE.
*END OF <RD1K963151>.
          IF ZIC_PREP_ROLEREQ-FUNDC1 <> '' .
            REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC1 INTO
                               WA_ROLES1-ROLE_NAME.
            APPEND WA_ROLES1 TO IT_ROLES1.
          ENDIF.
          IF ZIC_PREP_ROLEREQ-FUNDC <> ''.
            REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC INTO
                               WA_ROLES1-ROLE_NAME.
            APPEND WA_ROLES1 TO IT_ROLES1.
          ENDIF.
          IF ZIC_PREP_ROLEREQ-FUNDC2 <> ''.
            REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC2 INTO
                               WA_ROLES1-ROLE_NAME.
            APPEND WA_ROLES1 TO IT_ROLES1.
          ENDIF.
          IF ZIC_PREP_ROLEREQ-FUNDC3 <> ''.
            REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC3 INTO
                               WA_ROLES1-ROLE_NAME.
            APPEND WA_ROLES1 TO IT_ROLES1.
          ENDIF.
          IF ZIC_PREP_ROLEREQ-FUNDC4 <> ''.
            REPLACE 'FFFFFFFF' WITH ZIC_PREP_ROLEREQ-FUNDC4 INTO
                               WA_ROLES1-ROLE_NAME.
            APPEND WA_ROLES1 TO IT_ROLES1.
          ENDIF.
        ENDIF.
      ENDIF.

      SEARCH WA_ROLES1-ROLE_NAME FOR 'CCC_YY'.
      IF SY-SUBRC = 0.
        FLAG = 'X'.
        REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                      WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.

      SEARCH WA_ROLES1-ROLE_NAME FOR 'PGG'.
      IF SY-SUBRC = 0.
        FLAG = 'X'.
        REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                      WA_ROLES1-ROLE_NAME.
        REPLACE 'PGG' WITH WA_ITEMTAB_SL-GRP INTO WA_ROLES1-ROLE_NAME.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ENDIF.

      IF FLAG <> 'X'.
        APPEND WA_ROLES1 TO IT_ROLES1.
      ELSE.
        CLEAR FLAG.
      ENDIF.
    ENDLOOP.
*Begin of <RD1K963151>.
    IF ZIC_PREP_ROLEREQ-CCODE = 'OVL'.
      CLEAR WA_ROLES1.
      LOOP AT IT_ROLES1 INTO WA_ROLES1.
*BOC By SAP_ABAP on 26/10/26
*        IF WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_ALL'.
*          WA_ROLES1-ROLE_NAME = 'D:MM_OVL_DISPLAY_ALL'.
*        ENDIF.
*        IF WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_PM_PS_LIS_CIN'.
*          WA_ROLES1-ROLE_NAME = 'D:MM_OVL_DISPLAY_PM_PS_LIS_CIN'.
*        ENDIF.
*        MODIFY IT_ROLES1 FROM WA_ROLES1.
* S/4 role names (mail from Uday Mahato, SAP, 09/10/26), same mapping as FORM INSERT_DATA:
*   D:MM_DISPLAY_ALL           -> Z:D:MM:DISPLAY:D:OVL
*   D:MM_DISPLAY_PM_PS_LIS_CIN -> Z:D:PM:DISPLAY:M:OVL + Z:D:PS:DISPLAY:D:OVL (two roles)
* The PS row is appended while looping; it matches neither branch, so it is a no-op
* when the loop reaches it.
        IF WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_ALL'.
          WA_ROLES1-ROLE_NAME = 'Z:D:MM:DISPLAY:D:OVL'.
          MODIFY IT_ROLES1 FROM WA_ROLES1.
        ELSEIF WA_ROLES1-ROLE_NAME = 'D:MM_DISPLAY_PM_PS_LIS_CIN'.
          WA_ROLES1-ROLE_NAME = 'Z:D:PM:DISPLAY:M:OVL'.
          MODIFY IT_ROLES1 FROM WA_ROLES1.
          WA_ROLES1-ROLE_NAME = 'Z:D:PS:DISPLAY:D:OVL'.
          APPEND WA_ROLES1 TO IT_ROLES1.
        ENDIF.
*EOC By SAP_ABAP on 26/10/26
      ENDLOOP.
    ENDIF.
*End of <RD1K963151>.
  ENDIF.
ENDFORM.                    " INSERT_DATA_ADDL
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DOWNLOAD_FILE .
  IF NOT P1_FILE IS INITIAL.

* Download the file on presentation server
* begin of <RD1K960036>
* Replaced obsolete FM 'WS_DOWNLOAD'
*    CALL FUNCTION 'WS_DOWNLOAD'
*         EXPORTING
*              filename                = p1_file
*              filetype                = 'DAT'
*         TABLES
*              data_tab                = it_roles1
*         EXCEPTIONS
*              file_open_error         = 1
*              file_write_error        = 2
*              invalid_filesize        = 3
*              invalid_type            = 4
*              no_batch                = 5
*              unknown_error           = 6
*              invalid_table_width     = 7
*              gui_refuse_filetransfer = 8
*              customer_error          = 9
*              OTHERS                  = 10.

    DATA L_FILE TYPE STRING.

    L_FILE = P1_FILE.


    """"""""""""""""""""""""""""""""""""""""""""""""""
    "comment for testing

*types: t_line type c length 100.
*data: lt_tab type table of t_line.
*append 'test' to lt_tab.


*
*call method cl_gui_frontend_services=>gui_download
*  exporting
*    filename = l_file "'C:\temp\file.txt'
*  changing
*    data_tab = it_roles1. "lt_tab[].



    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
*       BIN_FILESIZE            =
        FILENAME                = L_FILE
        FILETYPE                = 'DAT'
*       APPEND                  = ' '
*       WRITE_FIELD_SEPARATOR   = ' '
*       HEADER                  = '00'
*       TRUNC_TRAILING_BLANKS   = ' '
*       WRITE_LF                = 'X'
*       COL_SELECT              = ' '
*       COL_SELECT_MASK         = ' '
*       DAT_MODE                = ' '
*       CONFIRM_OVERWRITE       = ' '
*       NO_AUTH_CHECK           = ' '
*       CODEPAGE                = ' '
*       IGNORE_CERR             = ABAP_TRUE
*       REPLACEMENT             = '#'
*       WRITE_BOM               = ' '
*       TRUNC_TRAILING_BLANKS_EOL       = 'X'
*       WK1_N_FORMAT            = ' '
*       WK1_N_SIZE              = ' '
*       WK1_T_FORMAT            = ' '
*       WK1_T_SIZE              = ' '
*       WRITE_LF_AFTER_LAST_LINE        = ABAP_TRUE
*       SHOW_TRANSFER_STATUS    = ABAP_TRUE
*     IMPORTING
*       FILELENGTH              =
      TABLES
        DATA_TAB                = IT_ROLES1
*       FIELDNAMES              =
      EXCEPTIONS
        FILE_WRITE_ERROR        = 1
        NO_BATCH                = 2
        GUI_REFUSE_FILETRANSFER = 3
        INVALID_TYPE            = 4
        NO_AUTHORITY            = 5
        UNKNOWN_ERROR           = 6
        HEADER_NOT_ALLOWED      = 7
        SEPARATOR_NOT_ALLOWED   = 8
        FILESIZE_NOT_ALLOWED    = 9
        HEADER_TOO_LONG         = 10
        DP_ERROR_CREATE         = 11
        DP_ERROR_SEND           = 12
        DP_ERROR_WRITE          = 13
        UNKNOWN_DP_ERROR        = 14
        ACCESS_DENIED           = 15
        DP_OUT_OF_MEMORY        = 16
        DISK_FULL               = 17
        DP_TIMEOUT              = 18
        FILE_NOT_FOUND          = 19
        DATAPROVIDER_EXCEPTION  = 20
        CONTROL_FLUSH_ERROR     = 21
        OTHERS                  = 22.
* end of <RD1K960036>
    IF SY-SUBRC <> 0.

      MESSAGE I061(ZHELP) WITH TEXT-053.

      EXIT.

    ENDIF.
    "end of comment for testing
    """"""""""

  ENDIF.
ENDFORM.                    " DOWNLOAD_FILE
*&---------------------------------------------------------------------*
*&      Form  CONFIRM_STEP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_STEP .
* begin of <RD1K960036>
* Replaced obsolete FM 'POPUP_TO_CONFIRM_STEP'
*  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*       EXPORTING
*            DEFAULTOPTION = 'Y'
*            TEXTLINE1     = 'Role request being created'
*            TEXTLINE2     = 'Continue ??? '
*            TITEL         = 'Confirm'
*       IMPORTING
*            ANSWER        = gl_ans.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR       = 'Confirm'
*     DIAGNOSE_OBJECT             = ' '
      TEXT_QUESTION  = 'Role request being created' &
                       'Continue ??? '
      TEXT_BUTTON_1  = 'Yes'(003)
*     ICON_BUTTON_1  = ' '
      TEXT_BUTTON_2  = 'No'(002)
*     ICON_BUTTON_2  = ' '
*     DEFAULT_BUTTON = '1'
*     DISPLAY_CANCEL_BUTTON       = 'X'
*     USERDEFINED_F1_HELP         = ' '
*     START_COLUMN   = 25
*     START_ROW      = 6
*     POPUP_TYPE     =
*     IV_QUICKINFO_BUTTON_1       = ' '
*     IV_QUICKINFO_BUTTON_2       = ' '
    IMPORTING
      ANSWER         = GL_ANS
*    TABLES
*     PARAMETER      =
    EXCEPTIONS
      TEXT_NOT_FOUND = 1
      OTHERS         = 2.
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  IF GL_ANS EQ '1'.
    CLEAR GL_ANS.
    MOVE 'J' TO GL_ANS.
  ELSEIF GL_ANS EQ '2'.
    CLEAR GL_ANS.
    MOVE 'N' TO GL_ANS.
  ELSE.
    CLEAR GL_ANS.
  ENDIF.
* end of <RD1K960036>
ENDFORM.                    " CONFIRM_STEP
*&---------------------------------------------------------------------*
*&      Form  INSERT_RECORD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_RECORD .
  G_ROLE_FLAG = 'X'.
ENDFORM.                    " INSERT_RECORD
*&---------------------------------------------------------------------*
*&      Form  COPY_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM COPY_VALUES .
  IF NOT ZROLEREQNO IS INITIAL.
    ZIC_PREP_ROLEREQ-REQ_NO = ZROLEREQNO.
  ENDIF.
ENDFORM.                    " COPY_VALUES
*&---------------------------------------------------------------------*
*&      Form  SAVE_REQUEST_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE_REQUEST_ASSIGN .
  IF OLD_OK_CODE = 'CREATE'.

    PERFORM GEN_NO.

  ENDIF.

  PERFORM INSERT_HEADER_ASSIGN.

ENDFORM.                    " SAVE_REQUEST_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  INSERT_HEADER_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_HEADER_ASSIGN .
  ZIC_PREP_ROLEREQ-MANDT = SY-MANDT.
  IF OLD_OK_CODE = 'CREATE'.
    ZIC_PREP_ROLEREQ-DOCNO = ZDOCNUMB.
  ENDIF.


  IF ZIC_PREP_ROLEREQ-USERIDCR IS INITIAL.

    ZIC_PREP_ROLEREQ-USERIDCR = SY-UNAME.
    ZIC_PREP_ROLEREQ-CR_DATE  = SY-DATUM.

    IF SY-TCODE <> 'ZIC_AUTH_CORETEAM'.

      CLEAR ZUSRMST.

      SELECT SINGLE * FROM ZUSRMST WHERE CPFNO =
                                 ZIC_PREP_ROLEREQ-USERIDCR.

      IF SY-SUBRC NE 0.

      ELSE.
*
        CONCATENATE ZUSRMST-FIRST_NAME ZUSRMST-LAST_NAME INTO
          ZUSRMST-LAST_NAME.
        ZIC_PREP_ROLEREQ-NAMECR = ZUSRMST-LAST_NAME.

      ENDIF.

    ENDIF.

  ENDIF.

  IF ZIC_PREP_ROLEREQ-USERIDAP IS INITIAL.

    IF OLD_OK_CODE = 'APPROVE' AND
          ( ZIC_PREP_ROLEREQ-REQ_APP_FL = 'X' ).
      ZIC_PREP_ROLEREQ-USERIDAP = SY-UNAME.
      ZIC_PREP_ROLEREQ-APP_DATE  = SY-DATUM.

      CLEAR ZUSRMST.

      SELECT SINGLE * FROM ZUSRMST WHERE CPFNO =
                            ZIC_PREP_ROLEREQ-USERIDAP.

      IF SY-SUBRC NE 0.

      ELSE.

        CONCATENATE ZUSRMST-FIRST_NAME ZUSRMST-LAST_NAME INTO
         ZUSRMST-LAST_NAME.
        ZIC_PREP_ROLEREQ-NAMEAPP = ZUSRMST-LAST_NAME.
      ENDIF.

    ENDIF.

  ELSE.

    IF OLD_OK_CODE = 'APPROVE' AND
          ZIC_PREP_ROLEREQ-REQ_APP0_FL = 'X'
                AND ZIC_PREP_ROLEREQ-REQ_APP1_FL = 'X'.

      ZIC_PREP_ROLEREQ-USERIDAP = SY-UNAME.
      ZIC_PREP_ROLEREQ-APP_DATE = SY-DATUM.

      SELECT SINGLE * FROM ZUSRMST WHERE CPFNO =
                              ZIC_PREP_ROLEREQ-USERIDAP.
      IF SY-SUBRC NE 0.
        MESSAGE E043(ZHELP).
      ELSE.

        CONCATENATE ZUSRMST-FIRST_NAME ZUSRMST-LAST_NAME INTO
        ZUSRMST-LAST_NAME.
        ZIC_PREP_ROLEREQ-NAMEAPP = ZUSRMST-LAST_NAME.
      ENDIF.
    ENDIF.
  ENDIF.

*****************************
  DATA L_FUNDC_NO LIKE SY-INDEX.
  CLEAR L_FUNDC_NO.

*****************************
  IF ZIC_PREP_ROLEREQ-STATUS <> 'C'.

    ZIC_PREP_ROLEREQ-STATUS = 'IF'.

  ENDIF.

*****
  IF G_FUNDC_ERR_FLAG <> 'X'.

*************************************************************

** Module wise check & insertion

    CASE MODULEID.

*      WHEN 'MM'.
*
*        PERFORM insert_items_assign.

      WHEN 'OLM'.

        PERFORM INSERT_ITEMS_OLM_ASSIGN.

*****************************************@
      WHEN OTHERS.
        PERFORM INSERT_ITEMS_ASSIGN.
*****************************************@

    ENDCASE.

    IF SY-TCODE <> 'ZIC_AUTH_CORETEAM'.

      PERFORM ITEMS_APPROVAL_CHECK_ASSIGN.

    ENDIF.

***********************

    IF SY-SUBRC = 0 AND ( ZIC_PREP_ROLEREQ-STATUS <> 'IC'
                        AND ZIC_PREP_ROLEREQ-STATUS <> 'IR' ).

      SELECT * FROM ZIC_PREP_ROLEREI INTO TABLE IST_ITEMTAB
              WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO.

      LOOP AT IST_ITEMTAB INTO WA_ITEMTAB.
        IF WA_ITEMTAB-REJ_FL = ''.
          IF WA_ITEMTAB-STATUS = '' AND
              WA_ITEMTAB-ROLE_REQUEST = ''.
            G_REQUEST_CLOSE_FLAG_P  = 'X'.
          ELSEIF WA_ITEMTAB-STATUS = 'H'.
            G_REQUEST_CLOSE_FLAG_H = 'X'.
          ELSEIF  WA_ITEMTAB-ROLE_REQUEST <> ''.
            G_REQUEST_CLOSE_FLAG_R = 'X'.
          ENDIF.
        ENDIF.
      ENDLOOP.

      IF ( G_REQUEST_CLOSE_FLAG_P  = 'X' OR
         G_REQUEST_CLOSE_FLAG_H  = 'X' ) AND
         G_REQUEST_CLOSE_FLAG_R = 'X'.
        ZIC_PREP_ROLEREQ-STATUS = 'PC'.
      ELSEIF G_REQUEST_CLOSE_FLAG_P  <> 'X' AND
         G_REQUEST_CLOSE_FLAG_H  = 'X' AND
         G_REQUEST_CLOSE_FLAG_R = 'X'.
        ZIC_PREP_ROLEREQ-STATUS = 'PC'.
      ELSEIF G_REQUEST_CLOSE_FLAG_P  = '' AND
         G_REQUEST_CLOSE_FLAG_H  = '' AND
         G_REQUEST_CLOSE_FLAG_R = 'X'.
        ZIC_PREP_ROLEREQ-STATUS = 'C'.
      ELSEIF G_REQUEST_CLOSE_FLAG_P  = 'X' AND
         G_REQUEST_CLOSE_FLAG_H  <> 'X' AND
         G_REQUEST_CLOSE_FLAG_R <> 'X'.
        ZIC_PREP_ROLEREQ-STATUS = 'IF'.
      ELSEIF  G_REQUEST_CLOSE_FLAG_P = '' AND
               G_REQUEST_CLOSE_FLAG_H = '' AND
                 G_REQUEST_CLOSE_FLAG_R <> ''.
        ZIC_PREP_ROLEREQ-STATUS = 'C'.
      ENDIF.

    ENDIF.



    MODIFY ZIC_PREP_ROLEREQ FROM ZIC_PREP_ROLEREQ.

    CLEAR : G_REQUEST_CLOSE_FLAG_P, G_REQUEST_CLOSE_FLAG_H,
            G_REQUEST_CLOSE_FLAG_R.


****Saving the long text.                              *****

    IF ( OLD_OK_CODE = 'CREATE' ) OR
       ( OLD_OK_CODE = 'CHANGE' ) OR
       ( OLD_OK_CODE = 'RELEASE' ) OR
       ( OLD_OK_CODE = 'APPROVE' ).

      PERFORM SAVE_CORS_TEXT.
      PERFORM UNLOCK_RECORD.
    ENDIF.

    IF G_ROLE_FLAG = 'X'.
      CLEAR G_ROLE_FLAG.


    ELSE.

      IF L_OLD_OK_CODE = 'X'.
        SET PARAMETER ID 'ZOLDCODE' FIELD L_INITIAL.
        LEAVE PROGRAM.
      ELSE.
        PERFORM CLEAR_ASSIGN.

      ENDIF.

    ENDIF.
  ELSE.
  ENDIF.
ENDFORM.                    " INSERT_HEADER_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  CONFIRM_MESSAGE_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_MESSAGE_ASSIGN .
* begin of <RD1K960036>
* FM 'POPUP_TO_CONFIRM_STEP' is obsolete.
*  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*       EXPORTING
*            DEFAULTOPTION = 'N'
*            TEXTLINE1     = 'This is a multiple module request. If u con
*tinue with correspondence,'
*            TEXTLINE2     = 'other modules will not be able to process t
*heir part of the request,OK'
*            TITEL         = 'Confirm'
*       IMPORTING
*            ANSWER        = gl_ans.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR       = 'Confirm'
*     DIAGNOSE_OBJECT             = ' '
      TEXT_QUESTION  = 'This is a multiple module request.' &
                       ' If u continue with correspondence,' &
                       ' other modules will not be able to' &
                       ' process their part of the request,OK'
      TEXT_BUTTON_1  = 'Yes'(003)
*     ICON_BUTTON_1  = ' '
      TEXT_BUTTON_2  = 'No'(002)
*     ICON_BUTTON_2  = ' '
      DEFAULT_BUTTON = '2'
*     DISPLAY_CANCEL_BUTTON       = 'X'
*     USERDEFINED_F1_HELP         = ' '
*     START_COLUMN   = 25
*     START_ROW      = 6
*     POPUP_TYPE     =
*     IV_QUICKINFO_BUTTON_1       = ' '
*     IV_QUICKINFO_BUTTON_2       = ' '
    IMPORTING
      ANSWER         = GL_ANS
*   TABLES
*     PARAMETER      =
    EXCEPTIONS
      TEXT_NOT_FOUND = 1
      OTHERS         = 2.
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  IF GL_ANS EQ '1'.
    CLEAR GL_ANS.
    MOVE 'Y' TO GL_ANS.
  ELSEIF GL_ANS EQ '2'.
    CLEAR GL_ANS.
    MOVE 'N' TO GL_ANS.
  ELSE.
    CLEAR GL_ANS.
  ENDIF.
* end of <RD1K960036>
ENDFORM.                    " CONFIRM_MESSAGE_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  CONFIRM_PROCESS_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_PROCESS_ASSIGN .
* begin of <RD1K960036>
* FM 'POPUP_TO_CONFIRM_STEP' is obsolete
*  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Do you want to process request after sav
*ing? '
*              TITEL          = ''
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = status_process.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
*     TITLEBAR              = ' '
*     DIAGNOSE_OBJECT       = ' '
      TEXT_QUESTION         = 'Do you want to process request after'
                              & ' saving?'
      TEXT_BUTTON_1         = 'Yes'(003)
*     ICON_BUTTON_1         = ' '
      TEXT_BUTTON_2         = 'No'(002)
*     ICON_BUTTON_2         = ' '
*     DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = SPACE
*     USERDEFINED_F1_HELP   = ' '
*     START_COLUMN          = 25
*     START_ROW             = 6
*     POPUP_TYPE            =
*     IV_QUICKINFO_BUTTON_1 = ' '
*     IV_QUICKINFO_BUTTON_2 = ' '
    IMPORTING
      ANSWER                = STATUS_PROCESS
*   TABLES
*     PARAMETER             =
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
* end of <RD1K960036>
ENDFORM.                    " CONFIRM_PROCESS_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  CONFIRM_STATUS_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONFIRM_STATUS_ASSIGN .
* begin of <RD1K960036>
*    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
*         EXPORTING
*              TEXTLINE1      = 'Do you want to change status to IC? '
*              TITEL          = ''
*              START_COLUMN   = 25
*              START_ROW      = 6
*              CANCEL_DISPLAY = ''
*         IMPORTING
*              ANSWER         = status_choice.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
*     TITLEBAR              = ' '
*     DIAGNOSE_OBJECT       = ' '
      TEXT_QUESTION         = 'Do you want to change status to IC? '
      TEXT_BUTTON_1         = 'Yes'(003)
*     ICON_BUTTON_1         = ' '
      TEXT_BUTTON_2         = 'No'(002)
*     ICON_BUTTON_2         = ' '
*     DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = SPACE
*     USERDEFINED_F1_HELP   = ' '
*     START_COLUMN          = 25
*     START_ROW             = 6
*     POPUP_TYPE            =
*     IV_QUICKINFO_BUTTON_1 = ' '
*     IV_QUICKINFO_BUTTON_2 = ' '
    IMPORTING
* Begin of <RD1K960611>
*   Worng variable was used in the previous change
*     ANSWER                = status_process
      ANSWER                = STATUS_CHOICE
* End of <RD1K960611>
*   TABLES
*     PARAMETER             =
    EXCEPTIONS
      TEXT_NOT_FOUND        = 1
      OTHERS                = 2.
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

* end of <RD1K960036>
ENDFORM.                    " CONFIRM_STATUS_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  SEND_SAPMAIL_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SEND_SAPMAIL_ASSIGN .
*--- Send mail to user


  DOCUMENT_DATA-OBJ_LANGU  = SY-LANGU.
  DOCUMENT_DATA-OBJ_NAME   = 'OVL Core Team'.
  DOCUMENT_DATA-OBJ_DESCR  = 'Mail from OVL Core Team'.
  SELECT * FROM ZAUTH_USER UP TO 1 ROWS
 WHERE BNAME = SY-UNAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
  CONCATENATE DOCUMENT_DATA-OBJ_DESCR '---' ZAUTH_USER-PRIMARY_MODULE
  '-' 'Module' INTO DOCUMENT_DATA-OBJ_DESCR.
  DOCUMENT_DATA-PRIORITY   = '3'.

* Remove prefix 'US' from receiver
  REFRESH RECEIVERS.

  CLEAR WA_RECEIVERS.
  WA_RECEIVERS-RECEIVER = ZIC_PREP_ROLEREQ-USERIDCR.
  WA_RECEIVERS-REC_TYPE = 'B'.
  WA_RECEIVERS-EXPRESS  = 'X'.
  APPEND WA_RECEIVERS TO RECEIVERS.

  CLEAR WA_RECEIVERS.

  MOVE SPACE TO OBJECT_CONTENT-LINE.
  APPEND OBJECT_CONTENT.

  CONCATENATE  'Subject: '  'Creation of Roles for userid '
ZIC_PREP_ROLEREQ-USERID INTO  OBJECT_CONTENT-LINE
SEPARATED BY SPACE.
  APPEND OBJECT_CONTENT.

  MOVE SPACE TO OBJECT_CONTENT-LINE.
  APPEND OBJECT_CONTENT.
  IF ZIC_PREP_ROLEREQ-STATUS = 'C'.
* begin of <RD1K960036>
* Literal exceeding more then one line is not allowed
*      concatenate 'Please  check  your role request  which  has  been
*assigned  &  completed - ' zic_prep_rolereq-docno into

    CONCATENATE 'Please  check  your role request  which  has'
     'been assigned  &  completed - ' ZIC_PREP_ROLEREQ-DOCNO INTO
* end of <RD1K960036>
OBJECT_CONTENT-LINE
SEPARATED BY SPACE.
    APPEND OBJECT_CONTENT.
  ELSE.
* begin of <RD1K960036>
* Literal exceeding more then one line is not allowed
*      concatenate 'Please check your role request which has been updated
* - ' zic_prep_rolereq-docno into  object_content-line
*    CONCATENATE 'Please check your role request which has been' &
*     ' updated - ' zic_prep_rolereq-docno INTO  object_content-line
** end of <RD1K960036>
*SEPARATED BY space.
*    APPEND object_content.
  ENDIF.
********************************************************************
  """"""""""""""""""""""
  IF ZIC_PREP_ROLEREQ-STATUS = 'IF'.
    IF V_MESSAGE_AS = 'X'.
      CONCATENATE 'All Required roles are already assigned in previous requests.- ' ZIC_PREP_ROLEREQ-DOCNO INTO
OBJECT_CONTENT-LINE
SEPARATED BY SPACE.
    ENDIF.
    APPEND OBJECT_CONTENT.
  ENDIF.
  """""""""""""""""""""""""""""



  IF ZIC_PREP_ROLEREQ-STATUS = 'IC'.
* begin of <RD1K960036>
* Literal exceeding more then one line is not allowed
*      Move 'Please go through correspondence in the request. The request
* needs to be changed, re-released & re-approved by competent authority.
*Once the request is approved, the request will flow to ICE core team.'
    MOVE 'Please go through correspondence in the request. The' &
         ' request needs to be changed, re-released & re-approved' &
         ' by competent authority. Once the request is approved, the' &
         ' request will flow to OVL core team.'
* end of <RD1K960036>
TO OBJECT_CONTENT-LINE.
    APPEND OBJECT_CONTENT.
  ENDIF.
  IF ZIC_PREP_ROLEREQ-STATUS = 'IR'.
* begin of <RD1K960036>
* Literal exceeding more then one line is not allowed
*      Move 'Please go through the correspondence in the request & reply
*to the query raised by ICE core team. You need to save the request after
* giving reply in correspondence(In display mode only). Once the request
*is saved, the request will flow to ICE core team.'
    MOVE 'Please go through the correspondence in the request &' &
         ' reply to the query raised by OVL core team. You need to' &
         ' save the request after giving reply in correspondence' &
         '(In display mode only). Once the request is saved, the' &
         ' request will flow to OVL core team.'
* end of <RD1K960036>
TO OBJECT_CONTENT-LINE.
    APPEND OBJECT_CONTENT.
* begin of <RD1K960036>
* Literal exceeding more then one line is not allowed
*     Move 'No re-release or approvals are required in this case & user
*will not be able to open the request in change mode.'
    MOVE 'No re-release or approvals are required in this case &' &
         ' user will not be able to open the request in change mode.'
* end of <RD1K960036>
TO OBJECT_CONTENT-LINE.
    APPEND OBJECT_CONTENT.
  ENDIF.
  IF ZIC_PREP_ROLEREQ-STATUS = 'PC'.
* begin of <RD1K960036>
* Literal exceeding more then one line is not allowed
*      Move 'Your request is still under process with ICE core team. Only
* partial roles have been assigned. You will get the next message'
    MOVE 'Your request is still under process with OVL core team.' &
         ' Only partial roles have been assigned. You will get the' &
         ' next message'
* end of <RD1K960036>
TO OBJECT_CONTENT-LINE.
    APPEND OBJECT_CONTENT.
    MOVE 'for completion or return of request soon.' TO
OBJECT_CONTENT-LINE.
    APPEND OBJECT_CONTENT.
  ENDIF.
********************************************************************
  MOVE SPACE TO OBJECT_CONTENT-LINE.
  APPEND OBJECT_CONTENT.

  OBJECT_CONTENT-LINE = 'OVL Core Team'.
  APPEND OBJECT_CONTENT.

  CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
    EXPORTING
      DOCUMENT_DATA              = DOCUMENT_DATA
      DOCUMENT_TYPE              = 'RAW'
      PUT_IN_OUTBOX              = 'X'
    IMPORTING
      SENT_TO_ALL                = SENT_TO_ALL
    TABLES
      OBJECT_HEADER              = OBJHEAD
      OBJECT_CONTENT             = OBJECT_CONTENT
      RECEIVERS                  = RECEIVERS
    EXCEPTIONS
      TOO_MANY_RECEIVERS         = 01
      DOCUMENT_NOT_SENT          = 02
      DOCUMENT_TYPE_NOT_EXIST    = 03
      OPERATION_NO_AUTHORIZATION = 04
      PARAMETER_ERROR            = 05
      X_ERROR                    = 06
      ENQUEUE_ERROR              = 07.

  CASE SY-SUBRC.
    WHEN 0.

*      MESSAGE i060(zhelp) WITH zic_prep_rolereq-useridcr.
    WHEN '01'.
      RAISE TOO_MANY_RECEIVERS.
    WHEN '02'.
      RAISE DOCUMENT_NOT_SENT.
    WHEN '03'.
      RAISE DOCUMENT_TYPE_NOT_EXIST.
    WHEN '04'.
      RAISE OPERATION_NO_AUTHORIZATION.
    WHEN '05'.
      RAISE PARAMETER_ERROR.
    WHEN '06'.
      RAISE X_ERROR.
    WHEN '07'.
      RAISE ENQUEUE_ERROR.
  ENDCASE.

********************************************
********************************************
ENDFORM.                    " SEND_SAPMAIL_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  INSERT_ITEMS_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_ASSIGN .
  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  CASE MODULEID.
    WHEN 'PM'.

      PERFORM INSERT_ITEMS_PM.

    WHEN 'PS'.

      PERFORM INSERT_ITEMS_PS.

    WHEN 'PP'.

      PERFORM INSERT_ITEMS_PP.

    WHEN 'SD'.

      PERFORM INSERT_ITEMS_SD.

    WHEN 'QM'.

      PERFORM INSERT_ITEMS_QM.

    WHEN 'HSE'.

      PERFORM INSERT_ITEMS_HS.

    WHEN 'MM'.
      SORT G_TABLCTRL110_ITAB
      BY ROLE_NAME PLANT GRP  SLOC RECEIPT_LOC APPROVER.

      DELETE ADJACENT DUPLICATES FROM G_TABLCTRL110_ITAB
        COMPARING ROLE_NAME PLANT GRP  SLOC RECEIPT_LOC APPROVER REJ_FL.

      LOOP AT G_TABLCTRL110_ITAB INTO G_TABLCTRL110_WA.

        MOVE-CORRESPONDING G_TABLCTRL110_WA TO WA_ITEMTAB.

        IF G_ROLE_FLAG = 'X' AND WA_ITEMTAB-REJ_FL = '' AND
            WA_ITEMTAB-STATUS = '' AND WA_ITEMTAB-ROLE_REQUEST = ''.
          WA_ITEMTAB-ROLE_REQUEST = ZROLEREQNO.
        ENDIF.

        IF OLD_OK_CODE = 'CREATE'.
          WA_ITEMTAB-DOCNO = ZDOCNUMB.
        ENDIF.

        WA_ITEMTAB-MANDT = SY-MANDT.
        IF WA_ITEMTAB-REJ_FL <> ''.
          WA_ITEMTAB-REJ_FL_SAVE = 'X'.
        ENDIF.
        IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
          I = I + 1.
          WA_ITEMTAB-SRNO = I .
          APPEND WA_ITEMTAB TO IST_ITEMTAB.
        ENDIF.

        G_I = I.

*    PERFORM check_items_save_assign.

      ENDLOOP.

      DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

      IF G_LINES_RL = 0.
        IF OLD_OK_CODE = 'CHANGE'.
          IF SY-SUBRC = 0.
            SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
            MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
          ENDIF.
        ELSE.
          ROLLBACK WORK.
        ENDIF.
      ELSE.

        DELETE FROM ZIC_PREP_ROLEREI WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
           AND MODULEID = MODULEID..

        MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

        IF SY-SUBRC = 0 AND G_ROLE_FLAG <> 'X'.
          MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
        ENDIF.

      ENDIF.

  ENDCASE.
ENDFORM.                    " INSERT_ITEMS_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  CHECK_ITEMS_SAVE_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ITEMS_SAVE_ASSIGN .
  IF OLD_OK_CODE <> 'DISPLAY' .

*    IF old_ok_code = 'CRCROLES' OR zic_prep_rolereq-crc_fl = 'X'.
*
*      SELECT SINGLE * FROM zmm_prep_rolecrc WHERE role_type =
*                                                  wa_itemtab-role_name.
*      IF sy-subrc = 0.
*
*        IF zmm_prep_rolecrc-plant = 'X' AND
*            wa_itemtab-plant IS INITIAL.
*          g_field = 'ZIC_PREP_ROLEREI-PLANT'.
*          ROLLBACK WORK.
*          MESSAGE i084(zhelp) WITH g_i.
*          CLEAR okcode_100.
*          CALL SCREEN 100.
*        ENDIF.
*
*        IF zmm_prep_rolecrc-p_grp = 'X' AND
*           wa_itemtab-grp IS INITIAL.
*          g_field = 'ZIC_PREP_ROLEREI-P_GRP'.
*          ROLLBACK WORK.
*          MESSAGE i085(zhelp) WITH g_i.
*          CLEAR okcode_100.
*          CALL SCREEN 100.
*        ENDIF.
*
*        IF zmm_prep_rolecrc-app_level = 'X' AND
*          wa_itemtab-approver IS INITIAL.
*          g_field = 'ZIC_PREP_ROLEREI-APPROVER'.
*          ROLLBACK WORK.
*          MESSAGE i096(zhelp) WITH g_i.
*          CLEAR okcode_100.
*          CALL SCREEN 100.
*        ENDIF.
*
*      ENDIF.
*
*    ELSE.
*
*      SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
*                                                  wa_itemtab-role_name.
*      IF sy-subrc = 0.
*
*        IF zmm_prep_roledes-plant = 'X' AND
*                       ( old_ok_code = 'APPROVE' OR
*                      old_ok_code = 'RELEASE' OR
*                      old_ok_code = 'CHANGE' OR
*                      old_ok_code = 'CREATE' OR
*                      old_ok_code = 'CROSSCO' ) AND
*                      NOT wa_itemtab-role_name IS INITIAL.
*
*          IF wa_itemtab-plant IS INITIAL.
*            g_field = 'ZIC_PREP_ROLEREI-PLANT'.
*            ROLLBACK WORK.
*            MESSAGE i084(zhelp) WITH g_i.
*            CLEAR okcode_100.
*            CALL SCREEN 100.
*          ENDIF.
*        ENDIF.
*
*        IF zmm_prep_roledes-p_grp = 'X' AND
*                       ( old_ok_code = 'APPROVE' OR
*                      old_ok_code = 'RELEASE' OR
*                      old_ok_code = 'CHANGE'  OR
*                      old_ok_code = 'CREATE'  OR
*                      old_ok_code = 'CROSSCO' ) AND
*                      NOT wa_itemtab-role_name IS INITIAL.
*
*          IF wa_itemtab-grp IS INITIAL.
*            g_field = 'ZIC_PREP_ROLEREI-GRP'.
*            ROLLBACK WORK.
*            MESSAGE i085(zhelp) WITH g_i.
*            CLEAR okcode_100.
*            CALL SCREEN 100.
*          ENDIF.
*        ENDIF.
*
*        IF zmm_prep_roledes-s_loc = 'X' AND
*                       ( old_ok_code = 'APPROVE' OR
*                      old_ok_code = 'RELEASE' OR
*                      old_ok_code = 'CHANGE' OR
*                      old_ok_code = 'CREATE' OR
*                      old_ok_code = 'CROSSCO' ) AND
*                      NOT wa_itemtab-role_name IS INITIAL.
*
*          IF wa_itemtab-sloc IS INITIAL.
*            g_field = 'ZIC_PREP_ROLEREI-SLOC'.
*            ROLLBACK WORK.
*            MESSAGE i090(zhelp) WITH g_i.
*            CLEAR okcode_100.
*            CALL SCREEN 100.
*          ENDIF.
*        ENDIF.
*
*        IF zmm_prep_roledes-r_loc = 'X' AND
*                       ( old_ok_code = 'APPROVE' OR
*                      old_ok_code = 'RELEASE' OR
*                      old_ok_code = 'CHANGE' OR
*                      old_ok_code = 'CREATE' OR
*                      old_ok_code = 'CROSSCO' ) AND
*                      NOT wa_itemtab-role_name IS INITIAL.
*
*          IF wa_itemtab-receipt_loc IS INITIAL.
*            g_field = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.
*            ROLLBACK WORK.
*            MESSAGE i095(zhelp) WITH g_i.
*            CLEAR okcode_100.
*            CALL SCREEN 100.
*          ENDIF.
*        ENDIF.
*
*        IF zmm_prep_roledes-app_level = 'X' AND
*                       ( old_ok_code = 'APPROVE' OR
*                      old_ok_code = 'RELEASE' OR
*                      old_ok_code = 'CHANGE' OR
*                      old_ok_code = 'CREATE' OR
*                      old_ok_code = 'CROSSCO' ) AND
*                      NOT wa_itemtab-role_name IS INITIAL.
*
*          IF wa_itemtab-approver IS INITIAL.
*            g_field = 'ZIC_PREP_ROLEREI-APPROVER'.
*            ROLLBACK WORK.
*            MESSAGE i096(zhelp) WITH g_i.
*            CLEAR okcode_100.
*            CALL SCREEN 100.
*          ENDIF.
*        ENDIF.
*
*      ENDIF.
*
*    ENDIF.

  ENDIF.
**  if wa_itemtab-rej_fl is initial.
**** Header level changes for integration
**    perform validate_role_approval_level.
**  endif.
** Line item changes for integration call diffrent subs ( def 110 )
*Begin of <RD1K963151>.
*  IF old_ok_code = 'CHANGE' AND sy-ucomm NE 'REQ1'.
**End of <RD1K963151>.
*    PERFORM validate_lineitem_datax.
**Begin of <RD1K963151>.
*  ENDIF.
ENDFORM.                    " CHECK_ITEMS_SAVE_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  ITEMS_APPROVAL_CHECK_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ITEMS_APPROVAL_CHECK_ASSIGN .
  SELECT * FROM ZIC_PREP_ROLEREI INTO TABLE IST_ITEMTAB
  WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO.
  LOOP AT IST_ITEMTAB INTO WA_ITEMTAB.
    IF WA_ITEMTAB-REJ_FL IS INITIAL.
** Header level changes for integration
      PERFORM VALIDATE_ROLE_APPROVAL_AS.
    ENDIF.
  ENDLOOP.
  CLEAR IST_ITEMTAB.
  REFRESH IST_ITEMTAB[].
  CLEAR WA_ITEMTAB.
**      if sy-subrc = 0.
** Messages to be checked modulewise in sub
  PERFORM CLEAR1.
  IF OLD_OK_CODE = 'CROSSCO' OR
        ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X'.

    IF OLD_OK_CODE = 'RELEASE' OR
        OLD_OK_CODE = 'CROSSCO' OR
        OLD_OK_CODE = 'CHANGE'.
      PERFORM POPUP_RELEASE_MESSAGE.
    ENDIF.

    IF OLD_OK_CODE = 'APPROVE' OR
       ZIC_PREP_ROLEREQ-STATUS = 'IF'.
*      PERFORM popup_approve_message.
    ENDIF.

    """""""""""""""""""""""""""""""""""""
    " added by lipsy  for cross company on 9.03.2015 RD1K996555
    IF  ZIC_PREP_ROLEREI-MODULEID = 'MM'.
      IF OLD_OK_CODE = 'APPROVE' AND   ZIC_PREP_ROLEREQ-CROSSCO_FL = 'X' .

      ELSE.
        "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555
        """"""""""""""""""""""""""""""""""

        PERFORM POP_UP_CROSSCO_MESSAGE.          .
*          message i113(zhelp) with ZIC_PREP_ROLEREQ-docno.
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.


        """"""""""""""""""""""""""""""
        "added by lipsy  for cross company on 9.03.2015 RD1K996555

      ENDIF.

    ENDIF.
    "end of addition by lipsy  for cross company on 9.03.2015 RD1K996555
    """"""""""""""""""""""""""""""""""""
  ELSE.
    IF OLD_OK_CODE = 'CRCROLES' OR
      ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
      IF OLD_OK_CODE = 'RELEASE' OR
         OLD_OK_CODE = 'CRCROLES' OR
         OLD_OK_CODE = 'CHANGE'.
        PERFORM POPUP_RELEASE_MESSAGE.
      ENDIF.
      IF OLD_OK_CODE = 'APPROVE' OR
         ZIC_PREP_ROLEREQ-STATUS = 'IF'.
*        PERFORM popup_approve_message.
      ENDIF.
      PERFORM POP_UP_CRC_MESSAGE.
*              message i119(zhelp) with ZIC_PREP_ROLEREQ-docno.
      MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      G_CRC_FL = 'X'.
    ELSE.
      IF OLD_OK_CODE = 'RELEASE'.
        PERFORM POPUP_RELEASE_MESSAGE.
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ELSEIF OLD_OK_CODE = 'APPROVE'.
*        .               PERFORM popup_approve_message.
*        MESSAGE i045(zhelp) WITH zic_prep_rolereq-docno.
      ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE =
'CHANGE'.
        PERFORM POPUP_RELEASE_MESSAGE1.
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ELSEIF ZIC_PREP_ROLEREQ-STATUS = 'IF'.
        PERFORM POPUP_APPROVE_MESSAGE.
      ELSE.
        MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ENDIF.
  ENDIF.
**      endif.
ENDFORM.                    " ITEMS_APPROVAL_CHECK_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  VALIDATE_ROLE_APPROVAL_AS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDATE_ROLE_APPROVAL_AS .

  SELECT SINGLE * FROM ZMM_PREP_ROLEGRP
       WHERE ROLE_TYPE = WA_ITEMTAB-ROLE_NAME.

  IF SY-SUBRC = 0.

    IF ZMM_PREP_ROLEGRP-APPROVER1 = 'L3' AND
                 G_APPROVER_LEVEL = 'L3'.

    ELSEIF ZMM_PREP_ROLEGRP-APPROVER1 = 'IM' AND
                 G_APPROVER_LEVEL = 'L3'.
      G_APPROVER_LEVEL = 'IM'.
    ELSEIF  ZMM_PREP_ROLEGRP-APPROVER1 = 'L1' AND
                 ( G_APPROVER_LEVEL = 'L3' OR
                   G_APPROVER_LEVEL = 'IM' ).
      G_APPROVER_LEVEL = 'L1'.
    ENDIF.

  ENDIF.
ENDFORM.                    " VALIDATE_ROLE_APPROVAL_AS
*&---------------------------------------------------------------------*
*&      Form  LIST_PROCESSING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM LIST_PROCESSING .
  IF GL_ANS = 'J'.
    SUPPRESS DIALOG.
    LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 100.
    PERFORM WRITE_LIST.
    G_LIST_PROC_FLAG = 'X'.
    CLEAR GL_ANS.
  ENDIF.
ENDFORM.                    " LIST_PROCESSING
*&---------------------------------------------------------------------*
*&      Form  WRITE_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM WRITE_LIST .
  SET PF-STATUS 'STATUS_130' EXCLUDING 'SEL'.

  READ TABLE IT_ROLES1 INTO WA_ROLES1 INDEX 1.  "#EC CI_NOORDER
  G_USERID = WA_ROLES1-USERID.
  L_COLOR = 5.
  LOOP AT IT_ROLES1 INTO WA_ROLES1.
    IF G_USERID = WA_ROLES1-USERID.
      WRITE : / WA_ROLES1-USERID COLOR 1,WA_ROLES1-ROLE_NAME COLOR 2.
    ELSE.
      WRITE : / WA_ROLES1-USERID COLOR 3,WA_ROLES1-ROLE_NAME COLOR 3.
    ENDIF.
    G_USERID = WA_ROLES1-USERID.
  ENDLOOP.
ENDFORM.                    " WRITE_LIST
*&---------------------------------------------------------------------*
*&      Form  FINAL_PROCESS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FINAL_PROCESS .

  SET PARAMETER ID 'ZROLEREQNO' FIELD ZROLEREQNO.

  CLEAR:V_MODULEID.

  V_MODULEID  = MODULEID.

  EXPORT V_MODULEID TO MEMORY ID 'ID3'.

  CLEAR V_REMARKS_HEAD.
  CONCATENATE ZIC_PREP_ROLEREQ-DOCNO ' - ARMS'
       ' - ' MODULEID ' Module' INTO V_REMARKS_HEAD.
  EXPORT V_REMARKS_HEAD TO MEMORY ID 'ID2'.
  CLEAR ZUSERID.
  MOVE ZIC_PREP_ROLEREQ-USERIDCR TO ZUSERID.
  EXPORT ZUSERID TO MEMORY ID 'ID'.
  CLEAR ZAPPROVER.
  MOVE ZIC_PREP_ROLEREQ-USERIDAP TO ZAPPROVER.
  EXPORT ZAPPROVER TO MEMORY ID 'ID1'.

  CLEAR:V_MESSAGE_AS.
  PERFORM ROLE_HELP.
  GET PARAMETER ID 'ZROLEREQNO' FIELD ZROLEREQNO.

  IF NOT ZROLEREQNO IS INITIAL AND ZROLEREQNO <> '00000000'.

    SUBMIT ZBC_ROLE_REP01_RFC AND RETURN.

    MESSAGE I056(ZBC) WITH ZIC_PREP_ROLEREQ-DOCNO.

    G_ROLE_FLAG = 'X'.
    ZIC_PREP_ROLEREQ-STATUS = 'IR'.

    PERFORM SAVE_REQUEST_ASSIGN.
    IF ZIC_PREP_ROLEREQ-STATUS = 'IF' OR
     ZIC_PREP_ROLEREQ-STATUS = 'N'.
    ELSE.
      PERFORM SEND_SAPMAIL_ASSIGN .

    ENDIF.
    PERFORM CLEAR_ASSIGN.
    REFRESH OBJECT_CONTENT.
  ENDIF.
  IF V_MESSAGE_AS = 'X'.
    PERFORM SAVE_REQUEST_ASSIGN.
    PERFORM SEND_SAPMAIL_ASSIGN .

    V_MESSAGE_UNAS = 'All roles already assigned or do not exist.'.

    MESSAGE I735(ZMM) WITH V_MESSAGE_UNAS.
  ELSE.
  ENDIF.

  LEAVE PROGRAM.

ENDFORM.                    " FINAL_PROCESS
*&---------------------------------------------------------------------*
*&      Form  ROLE_HELP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ROLE_HELP .
  DATA: UPL_COUNT TYPE I.
  DATA: XFLAG(1).
  DATA: XXCPF_NO LIKE ZAUTH_ITEM-CPF_NO.
  DATA: XXROLE LIKE ZAUTH_ITEM-ROLE.


  DATA: XXFROM_DAT LIKE ZAUTH_ITEM-FROM_DAT .
  DATA: XXTO_DAT LIKE ZAUTH_ITEM-TO_DAT .
  DATA: L_AGR_USERS LIKE TABLE OF AGR_USERS WITH HEADER LINE .


  DATA : DATEO(10), DATE LIKE SY-DATUM.
  DATA : ZUSERID LIKE ZAUTH_HEAD-REQUESTED_BY.
  DATA : ZAPPROVER LIKE ZAUTH_HEAD-APPROVED_BY.
  DATA:V_REMARKS_HEAD TYPE ZAUTH_HEAD-REMARKS,
       V_MODULEID(3).

  ZAUTH_HEAD-AUTH_REQ_DATE = SY-DATUM.

  IMPORT  V_MODULEID TO  V_MODULEID FROM MEMORY ID 'ID3'.
  ZAUTH_HEAD-PRIMOD = V_MODULEID.

  IMPORT V_REMARKS_HEAD TO V_REMARKS_HEAD FROM MEMORY ID 'ID2'.


  ZAUTH_HEAD-REMARKS  = V_REMARKS_HEAD.

  IMPORT ZUSERID TO ZUSERID FROM MEMORY ID 'ID'.
  ZAUTH_HEAD-REQUESTED_BY  = ZUSERID.

  IMPORT ZAPPROVER TO ZAPPROVER FROM MEMORY ID 'ID1'.
  ZAUTH_HEAD-APPROVED_BY = ZAPPROVER.


  CLEAR UPL_TAB. REFRESH UPL_TAB.
  CLEAR UPL_TABX. REFRESH UPL_TABX.




  CLEAR:WA_ROLES1.
  LOOP AT IT_ROLES1 INTO WA_ROLES1.
    UPL_TABX-CPF_NO = WA_ROLES1-USERID.
    UPL_TABX-ROLE = WA_ROLES1-ROLE_NAME.
    UPL_TABX-FROM_DAT = WA_ROLES1-FR_DATE_AUTH.
    UPL_TABX-TO_DAT  = WA_ROLES1-TO_DATE_AUTH.
    APPEND  UPL_TABX.
  ENDLOOP.

  LOOP AT UPL_TABX.

    UPL_TAB-CPF_NO = UPL_TABX-CPF_NO.
    UPL_TAB-ROLE   = UPL_TABX-ROLE.

*******************************************************
    DATEO = UPL_TABX-FROM_DAT.
    CONCATENATE DATEO+6(4) DATEO+3(2) DATEO+0(2) INTO DATE.
***************************************************
    UPL_TAB-FROM_DAT   = DATE.

    CLEAR : DATEO, DATE.

    DATEO = UPL_TABX-TO_DAT.
    CONCATENATE DATEO+6(4) DATEO+3(2) DATEO+0(2) INTO DATE.

    UPL_TAB-TO_DAT   = DATE.

    CLEAR : DATEO, DATE.


***************************************************

    APPEND UPL_TAB.

  ENDLOOP.
***********************
  REFRESH UPL_TABX.
  CLEAR   UPL_TABX.
***********************
  IF SY-SUBRC EQ 0.
    XXCPF_NO = 'XX'.
    XXROLE   = 'XX'.
*******************************************************
    LOOP AT UPL_TAB.
      TRANSLATE UPL_TAB TO UPPER CASE.
      MODIFY UPL_TAB.
    ENDLOOP.
***********************************************************************
    LOOP AT UPL_TAB.
      IF UPL_TAB-CPF_NO EQ SPACE AND
         UPL_TAB-ROLE EQ SPACE.
        DELETE UPL_TAB.
        CONTINUE.
      ENDIF.
      IF UPL_TAB-CPF_NO EQ SPACE.
        UPL_TAB-CPF_NO = XXCPF_NO.
      ENDIF.
      IF UPL_TAB-ROLE EQ SPACE.
        UPL_TAB-ROLE  = XXROLE.
      ENDIF.

      IF UPL_TAB-FROM_DAT EQ '00000000' .
        UPL_TAB-FROM_DAT = SY-DATUM .
      ENDIF .
      IF UPL_TAB-TO_DAT EQ '00000000' .
        UPL_TAB-TO_DAT = '99991231' .
      ENDIF .


      MODIFY UPL_TAB.
      XXCPF_NO = UPL_TAB-CPF_NO.
      XXROLE   = UPL_TAB-ROLE.
    ENDLOOP.
    SORT UPL_TAB.
    DELETE ADJACENT DUPLICATES FROM UPL_TAB.

    LOOP AT UPL_TAB.
      XFLAG = 'N'.
      UPL_TABX-CPF_NO = UPL_TAB-CPF_NO.
      UPL_TABX-ROLE   = UPL_TAB-ROLE.

      UPL_TABX-FROM_DAT = UPL_TAB-FROM_DAT.
      UPL_TABX-TO_DAT   = UPL_TAB-TO_DAT.


      SELECT SINGLE * FROM USR02 WHERE
           BNAME = UPL_TAB-CPF_NO.
      IF SY-SUBRC NE 0.
        UPL_TABX-USER_NA = 'X'.
      ENDIF.

      SELECT SINGLE * FROM AGR_DEFINE WHERE
         AGR_NAME = UPL_TAB-ROLE.
      IF SY-SUBRC NE 0.
        UPL_TABX-ROLE_NA = 'X'.
      ENDIF.


      IF UPL_TABX-USER_NA = 'X'.
        DELETE UPL_TAB.

        CLEAR UPL_TABX.
        CONTINUE.
      ELSE .

        SELECT AGR_NAME UNAME FROM_DAT TO_DAT INTO CORRESPONDING FIELDS
        OF TABLE L_AGR_USERS FROM AGR_USERS
        WHERE AGR_NAME = UPL_TABX-ROLE AND UNAME = UPL_TABX-CPF_NO .

        IF SY-SUBRC  EQ 0 .
          SORT L_AGR_USERS BY TO_DAT ASCENDING .
          CLEAR L_AGR_USERS .
          LOOP AT L_AGR_USERS .
            IF L_AGR_USERS-FROM_DAT <= UPL_TABX-FROM_DAT AND
               L_AGR_USERS-TO_DAT >= UPL_TABX-TO_DAT .
              XFLAG = 'X'.
              EXIT.
            ELSE .
              IF L_AGR_USERS-FROM_DAT <= UPL_TABX-FROM_DAT AND
                 L_AGR_USERS-TO_DAT >= UPL_TABX-FROM_DAT .
                UPL_TAB-FROM_DAT = L_AGR_USERS-TO_DAT .
                MODIFY UPL_TAB .
              ENDIF .
              IF L_AGR_USERS-FROM_DAT <= UPL_TABX-TO_DAT AND
                 L_AGR_USERS-TO_DAT >= UPL_TABX-TO_DAT .
                UPL_TAB-TO_DAT = L_AGR_USERS-FROM_DAT .
                MODIFY UPL_TAB .
              ENDIF .
            ENDIF .
          ENDLOOP .
        ENDIF .
**
        CLEAR UPL_TABX.
      ENDIF.
      IF XFLAG = 'X'.
        DELETE UPL_TAB.
      ENDIF.
      CLEAR UPL_TABX.

    ENDLOOP.
  ENDIF.
  LOOP AT UPL_TAB.
    MOVE-CORRESPONDING UPL_TAB TO G_ROLE_ITAB.
    G_ROLE_ITAB-ITEM_NO = ZITEM_NO.
    APPEND G_ROLE_ITAB.
    ZITEM_NO = ZITEM_NO + 1.
  ENDLOOP.


***************************************************************
***************************************************************

  """""""""""""""""""""""""""
  """"""""for text
  LOOP AT G_ROLE_ITAB.

    SELECT SINGLE * FROM USR21 WHERE BNAME = G_ROLE_ITAB-CPF_NO.
    SELECT NAME_TEXT INTO G_ROLE_ITAB-USER_NAME
 FROM ADRP UP TO 1 ROWS WHERE PERSNUMBER = USR21-PERSNUMBER
 ORDER BY PRIMARY KEY .
 ENDSELECT.

    SELECT TEXT INTO G_ROLE_ITAB-TEXT
 FROM AGR_TEXTS UP TO 1 ROWS WHERE AGR_NAME = G_ROLE_ITAB-ROLE AND SPRAS = 'EN'
 ORDER BY PRIMARY KEY .
 ENDSELECT.
    IF SY-SUBRC = 0.
    ELSE.
      DELETE G_ROLE_ITAB WHERE ROLE = G_ROLE_ITAB-ROLE.
    ENDIF.
    MODIFY G_ROLE_ITAB.
  ENDLOOP.
  """""""""""""""""""""""""""""
  """"""""""""""""""""""""

  """"""""""""""""


  IF  G_ROLE_ITAB[]  IS  NOT INITIAL.
***********************************************************************
    IF ZAUTH_HEAD-AUTH_REQ_NO IS INITIAL.


      PERFORM GET_NEXT_NUMBER_ASN.

      ZAUTH_HEAD-AUTH_REQ_NO = ZGET_NUMBER.

    ENDIF.
    MODIFY ZAUTH_HEAD.


    SET PARAMETER ID 'ZROLEREQNO' FIELD ZGET_NUMBER.

******************************************************************

    ZAUTH_ITEM-AUTH_REQ_NO = ZAUTH_HEAD-AUTH_REQ_NO.
    ZITEM_NO = 1.
    DELETE FROM ZAUTH_ITEM
       WHERE AUTH_REQ_NO = ZAUTH_HEAD-AUTH_REQ_NO.

***************************Added by Abhishek - Delimit existing roles.
    IF IT_AGR IS NOT INITIAL.

      CLEAR S_ITAB.
      LOOP AT G_ROLE_ITAB.
        MOVE-CORRESPONDING G_ROLE_ITAB TO S_ITAB.
      ENDLOOP.

*BOC By SAP_ABAP on 26/10/26
*     LOOP AT IT_AGR INTO WA_AGR WHERE AGR_NAME NE 'M:COMMON_USER_TOOLS'.
* Role renamed on S/4 (mail from Uday Mahato, SAP, 09/10/26):
*   'M:COMMON_USER_TOOLS' -> 'Z:S:BS:GENERAL_ACCESS:M:ALL'
      LOOP AT IT_AGR INTO WA_AGR WHERE AGR_NAME NE 'Z:S:BS:GENERAL_ACCESS:M:ALL'.
*EOC By SAP_ABAP on 26/10/26
        S_ITAB-ITEM_NO = S_ITAB-ITEM_NO + 1.
        G_ROLE_ITAB-ITEM_NO = S_ITAB-ITEM_NO.
        G_ROLE_ITAB-CPF_NO = S_ITAB-CPF_NO.
        G_ROLE_ITAB-ROLE = WA_AGR-AGR_NAME.
        G_ROLE_ITAB-TEXT = WA_AGR-AGR_TEXT.
        G_ROLE_ITAB-USER_NAME = S_ITAB-USER_NAME.
        G_ROLE_ITAB-FROM_DAT = WA_AGR-FROM_DAT.
        G_ROLE_ITAB-TO_DAT = SY-DATUM.
        APPEND G_ROLE_ITAB.
      ENDLOOP.

    ENDIF.
****************************************************End of addition by Abhishek

    LOOP AT G_ROLE_ITAB.
      IF G_ROLE_ITAB-CPF_NO NE SPACE AND
         G_ROLE_ITAB-ROLE NE SPACE .

        ZAUTH_ITEM-FROM_DAT = G_ROLE_ITAB-FROM_DAT .
        ZAUTH_ITEM-TO_DAT = G_ROLE_ITAB-TO_DAT .
************************************************************************
        ZAUTH_ITEM-CPF_NO = G_ROLE_ITAB-CPF_NO.
        ZAUTH_ITEM-ROLE = G_ROLE_ITAB-ROLE.
        ZAUTH_ITEM-ITEM_NO = ZITEM_NO.
        ZITEM_NO = ZITEM_NO + 1.
        MODIFY ZAUTH_ITEM.
      ENDIF.
    ENDLOOP.
    ZAUTH_EXCP-AUTH_REQ_NO = ZAUTH_HEAD-AUTH_REQ_NO.

    LOOP AT UPL_TABX.
      ZAUTH_EXCP-CPF_NO = UPL_TABX-CPF_NO.
      ZAUTH_EXCP-ROLE   = UPL_TABX-ROLE.
      ZAUTH_EXCP-REMARKS = UPL_TABX-REMARKS.
      ZAUTH_EXCP-ROLE_NA = UPL_TABX-ROLE_NA.
      ZAUTH_EXCP-USER_NA = UPL_TABX-USER_NA.
      MODIFY ZAUTH_EXCP.
    ENDLOOP.

  ELSE.
    V_MESSAGE_AS = 'X'.
  ENDIF.
************************************************************************
ENDFORM.                    " ROLE_HELP
*&---------------------------------------------------------------------*
*&      Form  GET_NEXT_NUMBER_ASN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_NEXT_NUMBER_ASN .
  DATA: RC         LIKE INRI-RETURNCODE.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      NR_RANGE_NR = '01'
      OBJECT      = 'ZROLEREQ'
      QUANTITY    = '1'
*     SUBOBJECT   = ' '
*     TOYEAR      = '0000'
*     IGNORE_BUFFER                 = ' '
    IMPORTING
      NUMBER      = ZGET_NUMBER
*     QUANTITY    =
      RETURNCODE  = RC
* EXCEPTIONS
*     INTERVAL_NOT_FOUND            = 1
*     NUMBER_RANGE_NOT_INTERN       = 2
*     OBJECT_NOT_FOUND              = 3
*     QUANTITY_IS_0                 = 4
*     QUANTITY_IS_NOT_1             = 5
*     INTERVAL_OVERFLOW             = 6
*     BUFFER_OVERFLOW               = 7
*     OTHERS      = 8
    .
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.                    " GET_NEXT_NUMBER_ASN
*&---------------------------------------------------------------------*
*&      Form  INSERT_ITEMS_OLM_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_OLM_ASSIGN .
  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  SORT G_TC_117_ITAB
  BY ROLE_NAME.

  DELETE ADJACENT DUPLICATES FROM G_TC_117_ITAB
    COMPARING ROLE_NAME.

  LOOP AT G_TC_117_ITAB INTO G_TC_117_WA .

    MOVE-CORRESPONDING G_TC_117_WA TO WA_ITEMTAB.

    IF G_ROLE_FLAG = 'X' AND WA_ITEMTAB-REJ_FL = '' AND
         WA_ITEMTAB-STATUS = '' AND WA_ITEMTAB-ROLE_REQUEST = ''.
      WA_ITEMTAB-ROLE_REQUEST = ZROLEREQNO.
    ENDIF.

    IF OLD_OK_CODE = 'CREATE'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

*    PERFORM check_module_wise.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

  IF G_LINES_RL = 0.
    IF OLD_OK_CODE = 'CHANGE'.
      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.

    DELETE FROM ZIC_PREP_ROLEREI WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
        AND MODULEID = MODULEID.

    MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.

    IF SY-SUBRC = 0 AND G_ROLE_FLAG <> 'X'.
      MESSAGE I045(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ENDIF.

  ENDIF.
ENDFORM.                    " INSERT_ITEMS_OLM_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  CLEAR_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLEAR_ASSIGN .
  PERFORM DESTROY_CTRL.

  OKCODE_100_P = OKCODE_100. " + BY BIPIN TO VALIDATE POP UP MESSAGE

  CLEAR   : OLD_OK_CODE, OKCODE_100, ERR_FLG.
  REFRESH : G_TABLCTRL110_ITAB[].
  CLEAR   : G_TABLCTRL110_ITAB.
  REFRESH : G_TABLCTRL111_ITAB[].
  CLEAR   : G_TABLCTRL111_ITAB.
  REFRESH : G_TABLCTRL112_ITAB[].
  CLEAR   : G_TABLCTRL112_ITAB.
  REFRESH : G_TABLCTRL113_ITAB[].
  CLEAR   : G_TABLCTRL113_ITAB.
  REFRESH : G_TABLCTRL114_ITAB[].
  CLEAR   : G_TABLCTRL114_ITAB.
  REFRESH : G_TABLCTRL115_ITAB[].
  CLEAR   : G_TABLCTRL115_ITAB.
  CLEAR   : SY-UCOMM.
  CLEAR   : G_CURR_LINE.
  CLEAR SET_DISC_MM_FLAG.
  CLEAR SET_DISC_FI_FLAG.
  CLEAR   : ZIC_PREP_ROLEREI.
  CLEAR   : IT_TAB.
  REFRESH : TLINETAB1[],TLINETAB2[].
  CLEAR   : T500P-NAME1.
  CLEAR   : CRC_CHECK_FL.
  CLEAR   : HELP_LIST_FLAG.
  REFRESH : IT_M_FISTB.
  CLEAR   : MODULEID.
ENDFORM.                    " CLEAR_ASSIGN
*&---------------------------------------------------------------------*
*&      Form  INSERT_ITEMS_SRM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_ITEMS_SRM .
  DATA : I LIKE SY-INDEX .
  CLEAR : WA_ITEMTAB, IST_ITEMTAB.

  SORT G_TABLCTRL118_ITAB
  BY ROLE_NAME PLANT GRP  SLOC RECEIPT_LOC APPROVER.

  DELETE ADJACENT DUPLICATES FROM G_TABLCTRL118_ITAB
    COMPARING ROLE_NAME PLANT GRP  SLOC RECEIPT_LOC APPROVER REJ_FL
    ROLE_TYPE_EX CRC_POS.

  LOOP AT G_TABLCTRL118_ITAB INTO G_TABLCTRL118_WA.

    MOVE-CORRESPONDING G_TABLCTRL118_WA TO WA_ITEMTAB.

    IF OLD_OK_CODE = 'CREATE' OR
       OLD_OK_CODE = 'CROSSCO' OR
       OLD_OK_CODE = 'CRCROLES'.
      WA_ITEMTAB-DOCNO = ZDOCNUMB.
    ENDIF.

    WA_ITEMTAB-MANDT = SY-MANDT.
    IF WA_ITEMTAB-REJ_FL <> ''.
      WA_ITEMTAB-REJ_FL_SAVE = 'X'.
    ENDIF.
    IF NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.
      I = I + 1.
      WA_ITEMTAB-SRNO = I .
      APPEND WA_ITEMTAB TO IST_ITEMTAB.
    ENDIF.

    G_I = I.

    SELECT SINGLE * FROM ZSR_PREP_ROLEDES WHERE ROLE_TYPE =
                                                     WA_ITEMTAB-ROLE_NAME.
    IF SY-SUBRC = 0.



      IF ZSR_PREP_ROLEDES-P_GRP = 'X' AND
                     ( OLD_OK_CODE = 'APPROVE' OR
                    OLD_OK_CODE = 'RELEASE' OR
                    OLD_OK_CODE = 'CHANGE'  OR
                    OLD_OK_CODE = 'CREATE'  OR
                    OLD_OK_CODE = 'CROSSCO' ) AND
                    NOT WA_ITEMTAB-ROLE_NAME IS INITIAL.

        IF WA_ITEMTAB-GRP IS INITIAL.
          G_FIELD = 'ZIC_PREP_ROLEREI-GRP'.
          ROLLBACK WORK.
          MESSAGE I085(ZHELP) WITH G_I.
          CLEAR OKCODE_100.
          CALL SCREEN 100.
        ENDIF.
      ENDIF.
    ENDIF.

    CLEAR:COUNT_GRP,G_WA_PGRP.

    LOOP AT G_TABLCTRL118_ITAB INTO G_WA_PGRP WHERE  GRP = WA_ITEMTAB-GRP  .
      IF G_WA_PGRP-GRP  IS NOT INITIAL.
        COUNT_GRP = COUNT_GRP + 1.
      ENDIF.
    ENDLOOP.
    IF  COUNT_GRP > '1'.
      MESSAGE I092(ZHELP) .
      CLEAR OKCODE_100.
      CALL SCREEN 100.
    ENDIF.

  ENDLOOP.

  DESCRIBE TABLE IST_ITEMTAB LINES G_LINES_RL.

***added g_reset_fl to check resetting & no rollback
  IF G_LINES_RL = 0 .
    ROLLBACK WORK.
    IF OLD_OK_CODE = 'CHANGE'.

      IF SY-SUBRC = 0.
        SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-DOCNO'.
        MESSAGE I099(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
      ENDIF.
    ELSEIF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO' .
      MESSAGE I103(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSE.
    IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL = 0.
      ROLLBACK WORK.
      MESSAGE I089(ZHELP).
    ELSE.

      IF OLD_OK_CODE = 'CREATE' OR OLD_OK_CODE = 'CROSSCO'
.
      ELSEIF OLD_OK_CODE <> 'DISPLAY'.
        DELETE FROM ZIC_PREP_ROLEREI WHERE
        DOCNO = ZIC_PREP_ROLEREQ-DOCNO AND
        MODULEID = MODULEID..
      ENDIF.

      MODIFY ZIC_PREP_ROLEREI FROM TABLE IST_ITEMTAB.


    ENDIF.

  ENDIF.
ENDFORM.                    " INSERT_ITEMS_SRM
*&---------------------------------------------------------------------*
*&      Form  CREATE_ROLES_SRM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CREATE_ROLES_SRM .
  CLEAR:L_LOGSYS.



  SELECT SINGLE LOGSYS FROM ZMM_LOGSYS INTO L_LOGSYS
  WHERE  APPL = 'SRM'.

  """"""calling srm

  IF NOT L_LOGSYS  IS INITIAL.

    LOOP AT   G_TABLCTRL118_ITAB INTO G_TABLCTRL118_WA.

      WA_ROLES_SRMP-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES_SRMP-ROLE_NAME = G_TABLCTRL118_WA-ROLE_NAME.
      WA_ROLES_SRMP-CCODE = ZIC_PREP_ROLEREQ-CCODE.
      WA_ROLES_SRMP-FROM_DAT = SY-DATUM.
      WA_ROLES_SRMP-TO_DAT   = '99991231'.
      WA_ROLES_SRMP-GRP =  G_TABLCTRL118_WA-GRP.
      APPEND  WA_ROLES_SRMP TO IT_ROLES_SRMP.

    ENDLOOP.




    P_UNAME = ZIC_PREP_ROLEREQ-USERID.

    SELECT SINGLE * FROM ZBCUSRMST  INTO CORRESPONDING FIELDS OF WA_ZBCUSRMST
      WHERE CPFNO = ZIC_PREP_ROLEREQ-USERID.

    P_FNAME        = WA_ZBCUSRMST-FIRST_NAME.
    P_LNAME        = WA_ZBCUSRMST-LAST_NAME.
    P_CCODE =    ZIC_PREP_ROLEREQ-CCODE.






    CALL FUNCTION 'ZSRM_ROLE_ASSIGN_ARMS' DESTINATION L_LOGSYS
      EXPORTING
        P_UNAME       = P_UNAME
        P_FNAME       = P_FNAME
        P_LNAME       = P_LNAME
        P_CCODE       = P_CCODE
      TABLES
        IT_ROLES_SRMP = IT_ROLES_SRMP
        ITAB_RETURN   = ITAB_RETURN.

    IF ITAB_RETURN[] IS NOT INITIAL.

      V_SRM_ST = 'C'.

      LOOP AT ITAB_RETURN INTO WA_RETURN.

        IF   WA_RETURN-STATUS NE  'C'.
          V_SRM_ST = 'IF'.
        ELSE.

        ENDIF.
      ENDLOOP.

      IF  V_SRM_ST = 'C'.
        ZIC_PREP_ROLEREQ-STATUS = 'C'.

      ELSE.
        ZIC_PREP_ROLEREQ-STATUS = 'IF'.
        PERFORM SEND_SAPMAIL_SRMASSIGN .
      ENDIF.


      V_ROLEREQ-DOCNO = ZIC_PREP_ROLEREQ-DOCNO.
      P_UNAME_SMS = P_UNAME.
      G_USERID_N = ''.
      MODIFY ZIC_PREP_ROLEREQ FROM ZIC_PREP_ROLEREQ.
      IF SY-SUBRC = 0.
        IF  ZIC_PREP_ROLEREQ-STATUS = 'C'.

          CALL FUNCTION 'ZMM_SEND_SMS'
            EXPORTING
              CPFNO_S     = G_USERID_N
              CPFNO_R     = P_UNAME_SMS
              FROM_DAT    = SY-DATUM
              TO_DAT      = '99991231'
              AUTH_REQ_NO = V_ROLEREQ-DOCNO
            IMPORTING
              FLAG_MSG    = L_FLAG_MSG.

          PERFORM SEND_SAPMAIL_SRMASSIGN .

        ENDIF.
      ENDIF.


    ELSE.
      IF  V_SRM_ST = ''.
        ZIC_PREP_ROLEREQ-STATUS = 'N'.
        MODIFY ZIC_PREP_ROLEREQ FROM ZIC_PREP_ROLEREQ.
      ENDIF.

    ENDIF.

    PERFORM UNLOCK_RECORD.

    CLEAR:V_MESSAGE_SRM.
    IF ZIC_PREP_ROLEREQ-STATUS = 'C'.

      CONCATENATE 'Roles assigned for request No .' ZIC_PREP_ROLEREQ-DOCNO INTO
      V_MESSAGE_SRM SEPARATED BY SPACE.

      MESSAGE I735(ZMM) WITH V_MESSAGE_SRM.

    ELSE.

      CONCATENATE 'Roles not  assigned for request No .' ZIC_PREP_ROLEREQ-DOCNO INTO
   V_MESSAGE_SRM SEPARATED BY SPACE.

      MESSAGE I735(ZMM) WITH V_MESSAGE_SRM.
    ENDIF.

    LEAVE PROGRAM.
  ENDIF.


ENDFORM.                    " CREATE_ROLES_SRM
*&---------------------------------------------------------------------*
*&      Form  SEND_SAPMAIL_SRMASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SEND_SAPMAIL_SRMASSIGN .
  DOCUMENT_DATA-OBJ_LANGU  = SY-LANGU.
  DOCUMENT_DATA-OBJ_NAME   = 'ICE Core Team'.
  DOCUMENT_DATA-OBJ_DESCR  = 'Mail from ICE Core Team'.

  CONCATENATE DOCUMENT_DATA-OBJ_DESCR '---' MODULEID
  '-' 'Module' INTO DOCUMENT_DATA-OBJ_DESCR.
  DOCUMENT_DATA-PRIORITY   = '3'.

* Remove prefix 'US' from receiver
  REFRESH RECEIVERS.

  CLEAR WA_RECEIVERS.
  WA_RECEIVERS-RECEIVER = ZIC_PREP_ROLEREQ-USERIDCR.
  WA_RECEIVERS-REC_TYPE = 'B'.
  WA_RECEIVERS-EXPRESS  = 'X'.
  APPEND WA_RECEIVERS TO RECEIVERS.

  CLEAR WA_RECEIVERS.

  MOVE SPACE TO OBJECT_CONTENT-LINE.
  APPEND OBJECT_CONTENT.

  CONCATENATE  'Subject: '  'Creation of Roles for userid '
ZIC_PREP_ROLEREQ-USERID INTO  OBJECT_CONTENT-LINE
SEPARATED BY SPACE.
  APPEND OBJECT_CONTENT.

  MOVE SPACE TO OBJECT_CONTENT-LINE.
  APPEND OBJECT_CONTENT.
  IF ZIC_PREP_ROLEREQ-STATUS = 'C'.


    CONCATENATE 'Please  check  your role request  which  has'
     'been assigned  &  completed - ' ZIC_PREP_ROLEREQ-DOCNO INTO
OBJECT_CONTENT-LINE
SEPARATED BY SPACE.
    APPEND OBJECT_CONTENT.
  ELSE.

  ENDIF.
********************************************************************
  """"""""""""""""""""""
  IF ZIC_PREP_ROLEREQ-STATUS = 'IF'.

    CONCATENATE ' Roles are not assigned for Request no.- ' ZIC_PREP_ROLEREQ-DOCNO INTO
OBJECT_CONTENT-LINE
SEPARATED BY SPACE.

    APPEND OBJECT_CONTENT.
  ENDIF.
  """""""""""""""""""""""""""""
********************************************************************
  MOVE SPACE TO OBJECT_CONTENT-LINE.
  APPEND OBJECT_CONTENT.

  OBJECT_CONTENT-LINE = 'ICE Core Team'.
  APPEND OBJECT_CONTENT.

  CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
    EXPORTING
      DOCUMENT_DATA              = DOCUMENT_DATA
      DOCUMENT_TYPE              = 'RAW'
      PUT_IN_OUTBOX              = 'X'
    IMPORTING
      SENT_TO_ALL                = SENT_TO_ALL
    TABLES
      OBJECT_HEADER              = OBJHEAD
      OBJECT_CONTENT             = OBJECT_CONTENT
      RECEIVERS                  = RECEIVERS
    EXCEPTIONS
      TOO_MANY_RECEIVERS         = 01
      DOCUMENT_NOT_SENT          = 02
      DOCUMENT_TYPE_NOT_EXIST    = 03
      OPERATION_NO_AUTHORIZATION = 04
      PARAMETER_ERROR            = 05
      X_ERROR                    = 06
      ENQUEUE_ERROR              = 07.

  CASE SY-SUBRC.
    WHEN 0.

*      MESSAGE i060(zhelp) WITH zic_prep_rolereq-useridcr.
    WHEN '01'.
      RAISE TOO_MANY_RECEIVERS.
    WHEN '02'.
      RAISE DOCUMENT_NOT_SENT.
    WHEN '03'.
      RAISE DOCUMENT_TYPE_NOT_EXIST.
    WHEN '04'.
      RAISE OPERATION_NO_AUTHORIZATION.
    WHEN '05'.
      RAISE PARAMETER_ERROR.
    WHEN '06'.
      RAISE X_ERROR.
    WHEN '07'.
      RAISE ENQUEUE_ERROR.
  ENDCASE.

ENDFORM.                    " SEND_SAPMAIL_SRMASSIGN
*&---------------------------------------------------------------------*
*&      Form  insert_data_hs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_HS.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'CCC'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  IF FLAG <> 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  CLEAR FLAG.

*
ENDFORM.                    " insert_data_hs
*&---------------------------------------------------------------------*
*&      Form  insert_data_pm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_PM.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'XXXX'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'YYY' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                WA_ROLES1-ROLE_NAME.
    REPLACE 'XXXX' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  IF FLAG <> 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  CLEAR FLAG.

*
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  insert_data_pp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_PP.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'XXXX'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'XXXX'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'XXXX' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'YYYY'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'YYYY'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'YYYY' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'AAAA'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
         ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
         PLANT     = WA_ITEMTAB_SL-PLANT    AND
         PLANT_GEN = 'AAAA'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'AAAA' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'BBBB'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'BBBB'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'BBBB' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'CCCC'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'CCCC'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'CCCC' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'DDDD'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'DDDD'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'DDDD' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'EEEE'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'EEEE'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'EEEE' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'FFFF'.
  IF SY-SUBRC = 0.

    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'FFFF'.
    IF SY-SUBRC = 0.
*      wa_flag = 'X'.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      REPLACE 'FFFF' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ELSE.
*      wa_flag1 = 'X'.
    ENDIF.
  ENDIF.

*  IF wa_flag <> 'X' AND wa_flag1 <> 'X'.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'ZZZZ'.
  IF SY-SUBRC <> 0.
*      CLEAR :wa_flag, wa_flag1.
    SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
         ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
         PLANT     = WA_ITEMTAB_SL-PLANT.
    IF SY-SUBRC = 0.
      WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
      WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
  ELSE.
  ENDIF.
*  ENDIF.

  IF WA_ITEMTAB_SL-ROLE_NAME = 'PP3'.

    SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'ZZZZ'.
    IF SY-SUBRC = 0.
      SELECT SINGLE * FROM ZPP_PREP_GENERIC WHERE
           ROLE_TYPE = WA_ITEMTAB_SL-ROLE_NAME AND
           PLANT     = WA_ITEMTAB_SL-PLANT    AND
           PLANT_GEN = 'AAAA'.
      IF SY-SUBRC = 0.
        WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
        WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
        REPLACE 'ZZZZ' WITH WA_ITEMTAB_SL-PLANT INTO WA_ROLES1-ROLE_NAME.
*        SELECT SINGLE * FROM zpp_prep_res WHERE
*             role_type = wa_itemtab_sl-role_name AND
*             plant     = wa_itemtab_sl-plant     AND
*             res       = wa_itemtab_sl-res.
*        CONCATENATE wa_roles1-role_name zpp_prep_res-res_code INTO
*        wa_roles1-role_name.
*        APPEND wa_roles1 TO it_roles1.
      ENDIF.
    ENDIF.

  ENDIF.

*  CLEAR : wa_flag, wa_flag1.

ENDFORM.                    " insert_data_pp
FORM INSERT_DATA1_PP.

*  IF wa_rolesz_pp-role_name = 'PP1' OR
*     wa_rolesz_pp-role_name = 'PP2' OR
*     wa_rolesz_pp-role_name = 'PP10'.
*    SELECT * FROM  zhelp_pproles1 INTO TABLE it_roles1_pp_tmp WHERE
*    role_type = wa_rolesz_pp-role_name AND
*    plant = wa_rolesz_pp-plant.
*    IF sy-subrc = 0.
*      LOOP AT it_roles1_pp_tmp INTO wa_roles1_pp.
*        wa_roles1-userid = zic_prep_rolereq-userid.
*        wa_roles1-role_name = wa_roles1_pp-role_name.
*        APPEND wa_roles1 TO it_roles1.
*      ENDLOOP.
*    ENDIF.
*
*  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  insert_data_qm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_QM.
  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'XXXX'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    IF WA_ITEMTAB_SL-ROLE_NAME = 'Q1'.
      SELECT SINGLE * FROM ZQM_PREP_LOC WHERE
             PLANT = WA_ITEMTAB_SL-PLANT.
      IF SY-SUBRC = 0.
        REPLACE 'XXXX' WITH ZQM_PREP_LOC-LOC INTO
                                 WA_ROLES1-ROLE_NAME.
      ELSE.
        REPLACE 'XXXX' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                 WA_ROLES1-ROLE_NAME.
      ENDIF.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'YYYY'.

  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    IF WA_ITEMTAB_SL-ROLE_NAME = 'Q2'.
*      IF  wa_itemtab_sl-asset_qm <> ''.
*        REPLACE 'YYYY' WITH wa_itemtab_sl-asset_qm INTO
*                                    wa_roles1-role_name.
*      ELSE.
      REPLACE 'YYYY' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                  WA_ROLES1-ROLE_NAME.
*      ENDIF.
      APPEND WA_ROLES1 TO IT_ROLES1.
    ENDIF.
  ENDIF.

  IF WA_ITEMTAB_SL-ROLE_NAME = 'Q3'.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  IF FLAG <> 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  CLEAR FLAG.

ENDFORM.                    " insert_data_qm
*&---------------------------------------------------------------------*
*&      Form  insert_data_sd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_SD.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'XXXX'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'XXXX' WITH WA_ITEMTAB_SL-SALE_ORG INTO
                             WA_ROLES1-ROLE_NAME.
    REPLACE 'ZZ' WITH WA_ITEMTAB_SL-DIV INTO
                             WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'YYYY'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    IF WA_ITEMTAB_SL-ROLE_NAME = 'S2'.
      IF WA_ITEMTAB_SL-DIV = 'GA' AND
         ( WA_ITEMTAB_SL-SHIP_POINT = 'GAIL' OR
           WA_ITEMTAB_SL-SHIP_POINT = 'HBJ' ).
        REPLACE 'YYYY' WITH WA_ITEMTAB_SL-SALE_ORG INTO
                                   WA_ROLES1-ROLE_NAME.
      ELSE.
        REPLACE 'YYYY' WITH WA_ITEMTAB_SL-SHIP_POINT INTO
                                    WA_ROLES1-ROLE_NAME.
      ENDIF.
    ENDIF.
    REPLACE 'ZZ' WITH WA_ITEMTAB_SL-DIV INTO
                                WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'PPPP'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'PPPP' WITH WA_ITEMTAB_SL-PLANT INTO
                                  WA_ROLES1-ROLE_NAME.
    IF WA_ITEMTAB_SL-ROLE_NAME = 'S7A'.
      REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                                  WA_ROLES1-ROLE_NAME.
    ENDIF.
*    SELECT SINGLE * FROM zsd_prep_level WHERE plant = wa_itemtab_sl-plant
*.
*    IF sy-subrc = 0 AND wa_itemtab_sl-role_name = 'S7'.
*      REPLACE 'LL' WITH zsd_prep_level-level_ex INTO
*                                wa_roles1-role_name.
*    ELSE.
    REPLACE 'ZZ' WITH WA_ITEMTAB_SL-DIV INTO
                              WA_ROLES1-ROLE_NAME.
*    ENDIF.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  IF WA_ITEMTAB_SL-ROLE_NAME = 'SXX'.
*    SELECT SINGLE * FROM zsd_prep_area WHERE
*                  sale_org = wa_itemtab_sl-sale_org.
*    IF sy-subrc = 0.
*      flag = 'X'.
*      wa_roles1-userid = zic_prep_rolereq-userid.
*      wa_roles1-role_name = wa_itemtab_sl-role_name.
*      REPLACE 'AAA' WITH zsd_prep_area-area INTO
*                                wa_roles1-role_name.
*      APPEND wa_roles1 TO it_roles1.
*    ENDIF.
  ENDIF.

  IF FLAG <> 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  CLEAR FLAG.

ENDFORM.                    " insert_data_sd
*&---------------------------------------------------------------------*
*&      Form  insert_data_ps
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INSERT_DATA_PS.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'CCC'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'CCC' WITH ZIC_PREP_ROLEREQ-CCODE+0(3) INTO
                               WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'AAA'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'AAA' WITH WA_ITEMTAB_SL-ASSET INTO
                                WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'BBB'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'BBB' WITH WA_ITEMTAB_SL-BASIN INTO
                                WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'XXYY'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'XX' WITH WA_ITEMTAB_SL-PROJECT INTO
                                WA_ROLES1-ROLE_NAME.
    REPLACE 'YY' WITH WA_ITEMTAB_SL-LOCATION INTO
                                WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  SEARCH WA_ITEMTAB_SL-ROLE_NAME FOR 'ZZZ'.
  IF SY-SUBRC = 0.
    FLAG = 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    REPLACE 'ZZZ' WITH 'ALL' INTO
                                WA_ROLES1-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  IF FLAG <> 'X'.
    WA_ROLES1-USERID = ZIC_PREP_ROLEREQ-USERID.
    WA_ROLES1-ROLE_NAME = WA_ITEMTAB_SL-ROLE_NAME.
    APPEND WA_ROLES1 TO IT_ROLES1.
  ENDIF.

  CLEAR FLAG.

ENDFORM.                    " insert_data_ps
*&---------------------------------------------------------------------*
*&      Form  DELIMIT_ROLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DELIMIT_ROLES .

  DATA: TMP_AGR TYPE STANDARD TABLE OF BAPIAGR,
        IT_RETN TYPE STANDARD TABLE OF BAPIRET2.

  CALL FUNCTION 'BAPI_USER_GET_DETAIL'
    EXPORTING
      USERNAME       = ZIC_PREP_ROLEREQ-USERID
      CACHE_RESULTS  = ''
    TABLES
*     PARAMETER      =
*     PROFILES       =
      ACTIVITYGROUPS = IT_AGR
      RETURN         = IT_RETN.

*  IF tmp_agr IS NOT INITIAL.
*    LOOP AT tmp_agr INTO wa_agr WHERE agr_name NE 'M:COMMON_USER_TOOLS'.
*      wa_agr-to_dat = sy-datum.
*      APPEND wa_agr TO it_agr.
*    ENDLOOP.
*  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  CHECK_RSN  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE CHECK_RSN INPUT.
  IF OLD_OK_CODE = 'CRCROLES' AND ZIC_PREP_ROLEREQ-RSN_CODE = '02'.
    MESSAGE 'Change of Assignment Reason not allowed for CRC roles' TYPE 'E'.
  ENDIF.
ENDMODULE.
