*--- MAIN PROGRAM: MZMMPREPROLE1_PHASEIIO01 ---*
*----------------------------------------------------------------------*
*   INCLUDE MZMMPREPROLEO01                                            *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
************************************************************************
*  Date            Transport      USERID        Description
* 02/04/2009      < RD1K962817>    SAB_SUMODH
*
*1)Change at Line 1471.
************************************************************************
************************************************************************
*  Date            Transport      USERID        Description
* 30/04/2009      <RD1K963151>    SAB_SUMODH
* CR No. 30012322  RD1K996279 CAB_SUDHIR
*
*1)Change in Line 309.
* 19.03.2015   <RD1K996555>  CAB_SPYADAV   CR 30012482(LIPSY)          *
*                                          (Simultaneous assignment of *
*                                           cross company ,multi module
*                                           roles,during approval      *
"                                          ,SRM Module introductin)    *
*&                                                                     *
*&                                                                     *
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


""""""""""""""""""""""""""""""""""""""""""""""""""""
************************************************************************
MODULE status_0100 OUTPUT.


 PERFORM fill_sttab.

 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.

 CASE old_ok_code.
   WHEN 'CREATE'.
     SET TITLEBAR 'PREP_TITLE' WITH ': Create Request'.
   WHEN 'CROSSCO'.
     SET TITLEBAR 'PREP_TITLE' WITH
     ': Cross Company '.
   WHEN 'CRCROLES'.
     SET TITLEBAR 'PREP_TITLE' WITH ': CRC '.
   WHEN 'CHANGE'.
     SET TITLEBAR 'PREP_TITLE' WITH ': Change Request'.
   WHEN 'DISPLAY'.
     SET TITLEBAR 'PREP_TITLE' WITH ': Display Request'.
*      SET PF-STATUS 'OPTNSX' excluding it_tab.
   WHEN 'DELETE'.
     SET TITLEBAR 'PREP_TITLE' WITH ': Delete Request'.
   WHEN 'RELEASE'.
     SET TITLEBAR 'PREP_TITLE' WITH ': Release Request'.
   WHEN 'APPROVE'.
     SET TITLEBAR 'PREP_TITLE' WITH ': Approve Request'.

   WHEN OTHERS.
     SET TITLEBAR 'PREP_TITLE' WITH ''.
 ENDCASE.

******************************** code added by Bipin  : 20/09/2013
 DATA lv_docno TYPE zchar12.
*  BREAK-POINT.
 IF zic_prep_rolereq-docno IS INITIAL.
   GET PARAMETER ID 'ZREQNO' FIELD zic_prep_rolereq-docno.
   lv_docno = zic_prep_rolereq-docno.
   DELETE gt_icon1 WHERE docno NE zic_prep_rolereq-docno.
   IF zic_prep_rolereq-docno IS  NOT INITIAL.
     CLEAR zic_prep_rolereq-docno.
   ENDIF.
 ELSE.
   lv_docno = zic_prep_rolereq-docno.
 ENDIF.
 SELECT * FROM zgrc_sod_result INTO CORRESPONDING FIELDS OF TABLE gt_icon WHERE docno = lv_docno.
 IF sy-subrc EQ 0.
   gt_icon1[] = gt_icon[].
 ENDIF.

 DESCRIBE TABLE gt_icon1 LINES lv_count.
 IF sy-tcode EQ 'ZICE_ARMS' ." OR SY-TCODE EQ 'ZIC_AUTH_FI_REP'.
   IF lv_count EQ 1.
     gicon = '@08@'. "GREEN
     risk_desc = 'No Risk'.
   ELSEIF lv_count GT 1.
     gicon = '@0A@'. "RED
     risk_desc = 'Risk found'.
   ELSEIF lv_count EQ 0.
     gicon = '@09@'. " YELLOW
     risk_desc = 'Risk analysis in progress'.
   ENDIF.
 ENDIF.

******************************** code added by Bipin  : 20/09/2013

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  get_header_data  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_header_data OUTPUT.

IF NOT zic_prep_rolereq-docno IS INITIAL.

  DATA : l_docno LIKE zic_prep_rolereq-docno.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = l_docno
    IMPORTING
      output = l_docno.

  zic_prep_rolereq-docno = l_docno.

ENDIF.

IF  g_hd_copied <> 'X'.
*
  IF old_ok_code IS INITIAL AND okcode_100 IS INITIAL.

  ELSE.

    IF ( old_ok_code = 'CREATE' OR old_ok_code = 'CROSSCO' ) AND
                                     okcode_100 IS INITIAL.

    ELSE.

      IF ( old_ok_code = 'CHANGE' ) OR ( old_ok_code = 'DELETE' )
          OR ( old_ok_code = 'RELEASE' )
          OR ( old_ok_code = 'APPROVE' ).
        IF NOT zic_prep_rolereq-docno IS INITIAL.
          """"""""
          """""""""""
          PERFORM lock_reqhd.
        ENDIF.
      ENDIF.

**      if sy-subrc = 0 and not ZIC_PREP_ROLEREQ-docno is initial.

*        g_hd_copied = 'X'.

**        clear g_TABCTRL100_itab.
**        refresh g_TABCTRL100_itab.

**        select * from ZIC_PREP_ROLEREI into corresponding
**                  fields of table g_TABCTRL100_itab
**                    where DOCNO = ZIC_PREP_ROLEREQ-docno.

**************************
**       clear g_srno.
**************************

**      endif.

      IF NOT zic_prep_rolereq-docno IS INITIAL.

        SELECT SINGLE * FROM zic_prep_rolereq
                   WHERE docno = zic_prep_rolereq-docno.

        IF sy-subrc = 0 .

          IF g_l4 = 'X' AND old_ok_code = 'APPROVE'.
            zic_prep_rolereq-radio_fl = 'X'.
          ENDIF.

*           select single moduleid from zic_prep_rolerei into
*           moduleid where DOCNO = ZIC_PREP_ROLEREQ-DOCNO.

          SELECT DISTINCT moduleid FROM zic_prep_rolerei INTO
          CORRESPONDING FIELDS OF TABLE it_module1 WHERE docno =
          zic_prep_rolereq-docno.
****
          SORT IT_MODULE1 BY MODULEID. READ TABLE it_module1 INDEX 1 INTO wa_module1.
          IF moduleid IS INITIAL.
            moduleid = wa_module1-moduleid.
**** 13/04/07
            old_moduleid = moduleid.
          ENDIF.
****
          DATA : l_module_lines LIKE sy-index.

          DESCRIBE TABLE it_module1 LINES l_module_lines.

          IF l_module_lines > 1.
            g_mult_module_fl = 'X'.
          ENDIF.

          g_hd_copied = 'X'.
** check line items modulewise/initialise
          g_tablctrl110_copied = ''.
          g_tablctrl111_copied = ''.
          g_tablctrl112_copied = ''.
          g_tablctrl113_copied = ''.
          g_tablctrl114_copied = ''.
          g_tablctrl115_copied = ''.
          g_tablctrl116_copied = ''.

          """"""""""""""""""""""
          """"""""""""""""""""""""
          ""added by lipsy on 20.03.2015 RD1K996555
          g_tc_117_copied = ''.
          g_tablctrl118_copied = ''.

          "
          ""End of addition by lipsy on 20.03.2015 RD1K996555

          """""""""""""""""""

**

          IF zic_prep_rolereq-comm_fl = 'X' AND old_ok_code = 'CHANGE'
.
            PERFORM verify2.
          ENDIF.

          PERFORM validations.

        ELSE.
          MESSAGE i101(zhelp) WITH zic_prep_rolereq-docno.
        ENDIF.

      ENDIF.

    ENDIF.

    SELECT SINGLE * FROM t500p
               WHERE persa = zic_prep_rolereq-persa.

    IF sy-subrc = 0.

      zic_prep_rolereq-name1 = t500p-name1.

    ENDIF.


  ENDIF.

ENDIF.

SELECT SINGLE * FROM zmm_prep_rsn
           WHERE reason = zic_prep_rolereq-rsn_code.

IF sy-subrc = 0.

  zic_prep_rolereq-rsn_text1 = zmm_prep_rsn-description.

ENDIF.

SELECT SINGLE * FROM zmm_prep_status
           WHERE status_code = zic_prep_rolereq-status .

IF sy-subrc = 0.

  status_desc = zmm_prep_status-status_desc.

ENDIF.


IF zic_prep_rolereq-fundc <> '' AND zic_prep_rolereq-reason1 = ''.

  SET CURSOR FIELD 'ZIC_PREP_ROLEREQ-REASON1'.
  MESSAGE i100(zhelp).
ENDIF.

PERFORM crc_module_checking.

PERFORM get_correspondence.

ENDMODULE.                 " get_header_data  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr100_attr  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr100_attr OUTPUT.

CASE old_ok_code.

  WHEN ''.

    LOOP AT SCREEN.
      screen-input = 0.
      MODIFY SCREEN.

*        ************************* START OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION
      IF screen-name = 'GRC_RISK'. "AND SY-TCODE EQ 'ZIC_AUTH_FI'.
        screen-invisible = 1.
*         SCREEN-INPUT = 1.
        MODIFY SCREEN.
      ENDIF.

      IF  screen-name = 'SEC_LEVEL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-invisible = 1.
*         SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDIF.

      IF  screen-name = 'GICON' ."AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-invisible = 1.
*         SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RAL'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RPL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'RISK_DESC'." AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.

************************* END OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION

    ENDLOOP.

  WHEN 'CREATE' OR 'ROLE_DEL'.

    LOOP AT SCREEN.

************************* START OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION
      IF screen-name = 'GRC_RISK'. "AND SY-TCODE EQ 'ZIC_AUTH_FI'.
        screen-invisible = 1.
*         SCREEN-INPUT = 1.
        MODIFY SCREEN.
      ENDIF.

      IF  screen-name = 'SEC_LEVEL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-invisible = 1.
*         SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDIF.

      IF  screen-name = 'GICON'." AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-invisible = 1.
*         SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RAL'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RPL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'RISK_DESC'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.

************************* END OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION

      IF screen-group1 = 'GP1'.
        IF moduleid <> 'MM' AND screen-name = 'ZIC_PREP_ROLEREQ-FUNDC'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
          screen-required = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group2 = 'GP2'.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF ( screen-name = 'ZIC_PREP_ROLEREQ-PERSA' ).
        IF zic_prep_rolereq-rsn_code = '01'.
          screen-input = 1.
*             perform pop_up_message.
        ELSE.
          CLEAR : zic_prep_rolereq-persa, zic_prep_rolereq-name1.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID' AND moduleid <> ''
          AND zic_prep_rolereq-userid <> ''.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID' AND old_ok_code = 'ROLE_DEL'.
        moduleid = 'FI'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-REASON1'.
        IF NOT zic_prep_rolereq-fundc IS INITIAL.
          screen-input = 1.
          screen-required = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

  WHEN 'CHANGE'.
    LOOP AT SCREEN.

************************* START OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION



      IF  screen-name = 'GRC_RAL'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RPL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.


************************* END OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION

      IF screen-group1 = 'GP1'.
        IF moduleid <> 'MM' AND screen-name = 'ZIC_PREP_ROLEREQ-FUNDC'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
          screen-required = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group2 = 'GP2'.
        IF moduleid <> 'MM' AND screen-name = 'ZIC_PREP_ROLEREQ-FUNDC'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
          screen-required = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
*Begin of <RD1K963151>.
      IF zic_prep_rolereq-docno IS NOT INITIAL.
        IF screen-group2 = 'GP2'.
          screen-name = 'ZIC_PREP_ROLEREQ-DOCNO'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
*End of <RD1K963151>.
      IF screen-name = 'MODULEID'.
        screen-input = 1.
*           screen-required = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-USERID' AND
          zic_prep_rolereq-userid <> ''.
        screen-input = 0.
*           screen-required = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC' .
        IF zic_prep_rolereq-crc_fl = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
        screen-invisible = 0.
        MODIFY SCREEN.
      ENDIF.

      IF ( screen-name = 'ZIC_PREP_ROLEREQ-PERSA' ).
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-REASON1'.
        IF NOT zic_prep_rolereq-fundc IS INITIAL.
          screen-input = 1.
          screen-required = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

  WHEN 'RELEASE'.

    LOOP AT SCREEN.

************************* START OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION
      IF screen-name = 'GRC_RISK'. "AND SY-TCODE EQ 'ZIC_AUTH_FI'.
        screen-invisible = 1.
*         SCREEN-INPUT = 1.
        MODIFY SCREEN.
      ENDIF.

      IF  screen-name = 'SEC_LEVEL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-invisible = 1.
*         SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDIF.

      IF  screen-name = 'GICON'." AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-invisible = 1.
*         SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RAL'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'GRC_RPL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
      IF  screen-name = 'RISK_DESC'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.

************************* END OF CHNGES : BY BIPIN SHUKLA : TO HIDE FROM REQUEST CREATION

      IF screen-group1 = 'GP1'.
        screen-input = 0.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group2 = 'GP2'.
        screen-input = 1.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID'.
        screen-input = 1.
*           screen-required = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-REQ_CR_FL'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC' AND zic_prep_rolereq-crc_fl = 'X'.
        screen-active = 1.
        screen-invisible = 0.
        MODIFY SCREEN.
      ELSEIF screen-group3 = 'GPC' AND zic_prep_rolereq-crc_fl <> 'X'.
        screen-active = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-REASON1'.
        IF NOT zic_prep_rolereq-fundc IS INITIAL.
          screen-input = 1.
          screen-required = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

  WHEN 'APPROVE'.

    LOOP AT SCREEN.

      IF screen-group1 = 'GP1'.
        screen-input = 0.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group2 = 'GP2'.
        screen-input = 1.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID'.
        screen-input = 1.
*           screen-required = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-DISC_MM_FLAG'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

*       if screen-name = 'TABCTRL100_DELETE' or
*           screen-name = 'TABCTRL100_INSERT' or
*           screen-name = 'COPY'.
*              screen-input = 0.
*              modify screen.
*       endif.

      IF g_user = 'L1' AND screen-name = 'ZIC_PREP_ROLEREQ-REQ_APP1_FL'.
** CODE ADDED BY CAB_AMITMOZA  CR: 30007580   01.03.2013
        SELECT * FROM ZIC_PREP_ROLEREI UP TO 1 ROWS

WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
ORDER BY PRIMARY KEY .
ENDSELECT.
        IF zic_prep_rolerei-moduleid = 'OLM'.
          screen-input = 0.
        ELSE.
** CODE END BY CAB_AMITMOZA  CR: 30007580
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
** CODE ADDED BY CAB_AMITMOZA  CR: 30007580   01.03.2013
      IF g_user = 'L1' AND screen-name = 'ZIC_PREP_ROLEREQ-REQ_APP_FL'.
        SELECT * FROM ZIC_PREP_ROLEREI UP TO 1 ROWS

WHERE DOCNO = ZIC_PREP_ROLEREQ-DOCNO
ORDER BY PRIMARY KEY .
ENDSELECT.
        IF zic_prep_rolerei-moduleid = 'OLM'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
** CODE END BY CAB_AMITMOZA  CR: 30007580
      IF ( g_user = 'IM' ) AND
          screen-name = 'ZIC_PREP_ROLEREQ-REQ_APP0_FL'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
      IF ( g_user = 'L3' ) AND
          screen-name = 'ZIC_PREP_ROLEREQ-REQ_APP_FL'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC' AND zic_prep_rolereq-crc_fl = 'X'.
        screen-active = 1.
        screen-invisible = 0.
        MODIFY SCREEN.
      ELSEIF screen-group3 = 'GPC' AND zic_prep_rolereq-crc_fl <> 'X'.
        screen-active = 0.
        screen-invisible = 1.
        MODIFY SCREEN.

      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-FUNDC' OR
         screen-name = 'ZIC_PREP_ROLEREQ-REASON1'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

  WHEN 'CROSSCO'.

    LOOP AT SCREEN.

      IF screen-group1 = 'GP1' OR
          screen-group4 = 'GP4'.
        screen-input = 1.
        IF screen-name = 'ZIC_PREP_ROLEREQ-DISC_MM_FLAG'.
          screen-required = 0.
        ELSE.
          screen-required = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group2 = 'GP2'.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF ( screen-name = 'ZIC_PREP_ROLEREQ-PERSA' ).
        IF zic_prep_rolereq-rsn_code = '01'.
          screen-input = 1.
        ELSE.
          CLEAR : zic_prep_rolereq-persa, zic_prep_rolereq-name1.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC' .
        screen-active = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID' AND moduleid <> ''
          AND zic_prep_rolereq-userid <> ''.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-CCODE' AND
         NOT zic_prep_rolereq-ccode IS INITIAL .
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-FUNDC_FL' OR
         screen-name = 'IN'.
        screen-active = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'ZIC_PREP_ROLEREQ-REASON1'.
        IF NOT zic_prep_rolereq-fundc IS INITIAL.
          screen-input = 1.
          screen-required = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

  WHEN 'DISPLAY'.

    LOOP AT SCREEN.



      IF screen-name = 'ZIC_PREP_ROLEREQ-DOCNO'       OR
*          screen-name = 'MODULEID'    or
         screen-name = 'DETAILS'     OR
         screen-name = 'CORR' OR screen-name = 'STAT' OR
         screen-name = 'M'    OR screen-name = 'TABCTRL100_PREVIOUS'
                              OR screen-name = 'TABCTRL100_NEXT'.
        screen-input = 1.
        screen-required = 1.
        MODIFY SCREEN.
      ELSE.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC' AND zic_prep_rolereq-crc_fl = 'X'.
        screen-active = 1.
        screen-invisible = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID'.
        screen-input = 1.
*           screen-required = 1.
        MODIFY SCREEN.
      ENDIF.
*Begin of <RD1K963151>.
      IF zic_prep_rolereq-docno IS NOT INITIAL.
        IF screen-group2 = 'GP2'.
          screen-name = 'ZIC_PREP_ROLEREQ-DOCNO'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
*End of <RD1K963151>.

    ENDLOOP.

  WHEN 'DELETE'.

    LOOP AT SCREEN.

      IF screen-name = 'ZIC_PREP_ROLEREQ-DOCNO' OR screen-name = 'CORR'
                                                OR screen-name = 'STAT'
.
        screen-input = 1.
        screen-required = 1.
        MODIFY SCREEN.
      ELSE.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

  WHEN 'CRCROLES'.

    LOOP AT SCREEN.

      IF screen-group1 = 'GP1'.
        screen-input = 1.
        screen-required = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group2 = 'GP2'.
        screen-required = 0.
        MODIFY SCREEN.
      ENDIF.

      IF ( screen-name = 'ZIC_PREP_ROLEREQ-PERSA' ).
        IF zic_prep_rolereq-rsn_code = '01'.
          screen-input = 1.
        ELSE.
          CLEAR : zic_prep_rolereq-persa, zic_prep_rolereq-name1.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group3 = 'GPC'.
        screen-input = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'MODULEID'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF ( screen-name = 'ZIC_PREP_ROLEREQ-FR_DATE_AUTH' OR
            screen-name = 'ZIC_PREP_ROLEREQ-TO_DATE_AUTH' ).
        screen-input = 1.
        screen-invisible = 0.
        screen-required = 0.
      ELSE.
        IF ( screen-name = 'ZIC_PREP_ROLEREQ-OFF_ORDER_NO' OR
            screen-name = 'ZIC_PREP_ROLEREQ-OFF_ORDER_DATE' ).
          screen-input = 1.
          screen-invisible = 0.
          screen-required = 1.
        ENDIF.

      ENDIF.

      IF ( screen-name = 'OONO' OR screen-name = 'DT1'  OR
           screen-name = 'DT2' OR screen-name = 'DT3' ).
        screen-invisible = 0.
        screen-active = 1.
      ENDIF.

      MODIFY SCREEN.

      IF screen-name = 'ZIC_PREP_ROLEREQ-REASON1'.
        IF NOT zic_prep_rolereq-fundc IS INITIAL.
          screen-input = 1.
          screen-required = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

*added on 05/03/2007
      IF screen-name = 'ZIC_PREP_ROLEREQ-DISC_MM_FLAG'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

ENDCASE.

IF old_ok_code = 'DISPLAY'.

  LOOP AT SCREEN.

    IF screen-name = 'GRC_RISK'. "AND SY-TCODE EQ 'ZIC_AUTH_FI'.
      screen-invisible = 0.
      screen-active = 1.
      screen-input = 1.
      MODIFY SCREEN.
    ENDIF.
    IF  screen-name = 'GRC_RAL'. " AND SY-TCODE EQ 'ZIC_AUTH_FI' .
      screen-invisible = 0.
      screen-active = 1.
      screen-input = 1.
      MODIFY SCREEN.
    ENDIF.
    IF  screen-name = 'GRC_RPL'. "AND SY-TCODE EQ 'ZIC_AUTH_FI' .
      screen-invisible = 0.
      screen-active = 1.
      screen-input = 1.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDIF.

ENDMODULE.                 " scr100_attr  OUTPUT

*&spwizard: output module for tc 'TABCTRL100'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tabctrl100_init OUTPUT.

PERFORM get_user.

**   if g_hd_copied is initial.
**    refresh control 'TABCTRL100' from screen '0100'.
DATA l_fis_initial.
SET PARAMETER ID 'FIS' FIELD l_fis_initial.
SET PARAMETER ID 'BUK' FIELD l_fis_initial.
**  endif.

ENDMODULE.                    "TABCTRL100_init OUTPUT

*&spwizard: output module for tc 'TABCTRL100'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tabctrl100_move OUTPUT.
MOVE-CORRESPONDING g_tabctrl100_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
  zic_prep_rolerei-docno = zic_prep_rolereq-docno.

  IF old_ok_code = 'CRCROLES' OR zic_prep_rolereq-crc_fl = 'X'.
    SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
WHERE ROLE_TYPE =
ZIC_PREP_ROLEREI-ROLE_NAME
ORDER BY PRIMARY KEY .
ENDSELECT.
    IF sy-subrc = 0 .
      MOVE zmm_prep_rolecrc-brief_desc TO role_desc.
    ENDIF.
  ELSE.
    SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                zic_prep_rolerei-role_name.
    IF sy-subrc = 0 .
      MOVE zmm_prep_roledes-brief_desc TO role_desc.
    ENDIF.
  ENDIF.

ENDIF.
ENDMODULE.                    "TABCTRL100_move OUTPUT

*&spwizard: output module for tc 'TABCTRL100'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tabctrl100_get_lines OUTPUT.
g_tabctrl100_lines = sy-loopc.
ENDMODULE.                    "TABCTRL100_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  value_list  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE value_list OUTPUT.

SUPPRESS DIALOG.
LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0.
*  MOVE 'REQ1' to WA_TAB.
*  APPEND WA_TAB to TAB.
SET PF-STATUS 'STATUS_120' EXCLUDING tab.
CLEAR : wa_tab.
REFRESH : tab.
WRITE :'Selected Values for Company Code :',zic_prep_rolereq-ccode
        COLOR COL_HEADING.
ULINE.
IF flag_s_fundc = 'X'.
  PERFORM help_list.
ENDIF.

ENDMODULE.                 " value_list  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_120  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_120 OUTPUT.
SET PF-STATUS 'STATUS_120'.
*  SET TITLEBAR 'xxx'.

ENDMODULE.                 " STATUS_120  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABCTRL100_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tabctrl100_attrib OUTPUT.

IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 IF old_ok_code <> 'CRCROLES'.
   IF old_ok_code = 'CREATE'.
   ELSEIF zic_prep_rolereq-crc_fl = 'X'.
     crc_check_fl = 'X'.
   ENDIF.
 ELSE.
   crc_check_fl = 'X'.
 ENDIF.

 IF crc_check_fl <> 'X' .

   CLEAR crc_check_fl.

   SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                                             g_tabctrl100_wa-role_name.

   IF sy-subrc = 0.

     LOOP AT SCREEN.

       IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

         IF old_ok_code <> 'APPROVE'.
           screen-input = 1.
         ELSE.
           screen-input = 0.
         ENDIF.
         MODIFY SCREEN.
       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
         old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
         screen-input = 1.
         MODIFY SCREEN.
       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

         IF zmm_prep_roledes-plant = 'X' AND
                       old_ok_code <> 'APPROVE'.
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-GRP'.

         IF zmm_prep_roledes-p_grp = 'X' AND
                       old_ok_code <> 'APPROVE'.
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER'.

         IF zmm_prep_roledes-app_level = 'X' AND
                     old_ok_code <> 'APPROVE'.
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.


       IF screen-name = 'ZIC_PREP_ROLEREI-SLOC'.

         IF zmm_prep_roledes-s_loc = 'X' AND
                   old_ok_code <> 'APPROVE'.
           .
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.
       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.

         IF zmm_prep_roledes-r_loc = 'X' AND
                   old_ok_code <> 'APPROVE'.
           .
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

     ENDLOOP.

   ELSE.

     LOOP AT SCREEN.

       IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                      NOT old_ok_code IS INITIAL AND
                      old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
         IF NOT zic_prep_rolerei-role_name IS INITIAL .
           MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
         ENDIF.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDLOOP.

   ENDIF.

 ELSE.

   IF zic_prep_rolereq-crc_fl = 'X' OR old_ok_code = 'CRCROLES'.

     SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
WHERE ROLE_TYPE =
G_TABCTRL100_WA-ROLE_NAME
ORDER BY PRIMARY KEY .
ENDSELECT.

     IF sy-subrc = 0.

       LOOP AT SCREEN.

         IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

           IF old_ok_code <> 'APPROVE'.
             screen-input = 1.
           ELSE.
             screen-input = 0.
           ENDIF.
           MODIFY SCREEN.
         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
           old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
           screen-input = 1.
           MODIFY SCREEN.
         ENDIF.


         IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .


           IF zmm_prep_rolecrc-plant = 'X' AND
                                old_ok_code <> 'APPROVE'.
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-GRP' .


           IF zmm_prep_rolecrc-p_grp = 'X' AND
                                old_ok_code <> 'APPROVE'.
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.


         IF screen-name = 'ZIC_PREP_ROLEREI-SLOC'.

           IF zmm_prep_rolecrc-s_loc = 'X' AND
                     old_ok_code <> 'APPROVE'.
             .
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.
         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.

           IF zmm_prep_rolecrc-r_loc = 'X' AND
                     old_ok_code <> 'APPROVE'.
             .
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.

       ENDLOOP.

     ELSE.

       LOOP AT SCREEN.

         IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                            NOT old_ok_code IS INITIAL.
           screen-input = 1.
           MODIFY SCREEN.

           IF NOT zic_prep_rolerei-role_name IS INITIAL.
             MESSAGE i116(zhelp) WITH zic_prep_rolerei-role_name.
           ENDIF.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDLOOP.

     ENDIF.

   ENDIF.

 ENDIF.

ELSE.

 LOOP AT SCREEN.

   screen-input = 0.
   MODIFY SCREEN.
*
 ENDLOOP.
*

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

ENDMODULE.                 " TABCTRL100_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0105  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0105 OUTPUT.

SET PF-STATUS 'STAT105'.

ENDMODULE.                 " STATUS_0105  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  INITIALIZE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE initialize OUTPUT.

PERFORM get_correspondence.

ENDMODULE.                 " INITIALIZE  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SPLITTER_CTRL_VORBEREITEN1  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE splitter_ctrl_vorbereiten1 OUTPUT.

IF gv_splitter1 IS INITIAL.
 CREATE OBJECT gv_custom_container
   EXPORTING
     container_name = 'C_DIS'.

 CREATE OBJECT gv_splitter1
   EXPORTING
     parent        = gv_custom_container
     orientation   = 1
     sash_position = 1.
ENDIF.

IF ( old_ok_code = 'CREATE' )
OR ( old_ok_code = 'CROSSCO' )
OR ( old_ok_code = 'CRCROLES' )
OR ( old_ok_code = 'CHANGE' )
OR ( old_ok_code = 'RELEASE' )
OR ( old_ok_code = 'APPROVE' )
OR ( old_ok_code = 'DISPLAY' AND zic_prep_rolereq-comm_fl = 'X' AND
    zic_prep_rolereq-status <> 'C' ).

 IF gv_splitter2 IS INITIAL.

   CREATE OBJECT gv_custom_container
     EXPORTING
       container_name = 'C_WRT'.


   CREATE OBJECT gv_splitter2
     EXPORTING
       parent        = gv_custom_container
       orientation   = 1
       sash_position = 1.

 ENDIF.
ENDIF.

ENDMODULE.                 " SPLITTER_CTRL_VORBEREITEN1  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TEXT_CTRL_VORBEREITEN1  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE text_ctrl_vorbereiten1 OUTPUT.

IF gv_text_editor1 IS INITIAL.
 CREATE OBJECT gv_text_editor1
   EXPORTING
     parent                     = gv_splitter1->bottom_right_container
     wordwrap_mode              = cl_gui_textedit=>wordwrap_at_windowborder
     wordwrap_to_linebreak_mode = cl_gui_textedit=>false
   EXCEPTIONS
     error_cntl_create          = 1
     error_cntl_init            = 2
     error_cntl_link            = 3
     error_dp_create            = 4
     gui_type_not_supported     = 5.
 flag1 = 'X'.
ENDIF.
IF ( old_ok_code = 'CREATE' )
   OR ( old_ok_code = 'CROSSCO' )
   OR ( old_ok_code = 'CRCROLES' )
   OR ( old_ok_code = 'CHANGE' )
   OR ( old_ok_code = 'RELEASE' )
   OR ( old_ok_code = 'APPROVE' )
    OR ( old_ok_code = 'DISPLAY' AND zic_prep_rolereq-comm_fl = 'X'
         AND zic_prep_rolereq-status <> 'C').

 IF gv_text_editor2 IS INITIAL.
   CREATE OBJECT gv_text_editor2
     EXPORTING
       parent                     = gv_splitter2->bottom_right_container
       wordwrap_mode              = cl_gui_textedit=>wordwrap_at_windowborder
       wordwrap_to_linebreak_mode = cl_gui_textedit=>false
     EXCEPTIONS
       error_cntl_create          = 1
       error_cntl_init            = 2
       error_cntl_link            = 3
       error_dp_create            = 4
       gui_type_not_supported     = 5.
   flag2 = 'X'.
 ENDIF.
ENDIF.

PERFORM text_control_eingabebereit1.
PERFORM text_control_set_text_table1.

ENDMODULE.                 " TEXT_CTRL_VORBEREITEN1  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr100_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr100_col_attrib OUTPUT.

**LOOP AT TABCTRL100-cols INTO cols WHERE index GT 10.
**      cols-invisible = '1'.
**      MODIFY TABCTRL100-cols FROM cols INDEX sy-tabix.
**ENDLOOP.
**
**LOOP AT TABCTRL100-cols INTO cols WHERE index = 11.
**    cols-invisible = '0'.
**    MODIFY TABCTRL100-cols FROM cols INDEX sy-tabix.
**ENDLOOP.

ENDMODULE.                 " scr100_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  delete_dup  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE delete_dup OUTPUT.

*if not g_TABCTRL100_itab[] is initial and okcode_100 <> 'COPY'.

IF NOT g_tabctrl100_itab[] IS INITIAL .

 SORT g_tabctrl100_itab
 BY role_name plant grp sloc receipt_loc approver.
 DELETE ADJACENT DUPLICATES FROM g_tabctrl100_itab
 COMPARING role_name plant grp sloc receipt_loc approver.

ENDIF.

DESCRIBE TABLE g_tabctrl100_itab LINES tabctrl100-lines.

ENDMODULE.                 " delete_dup  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_cursor  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_110 OUTPUT.

DESCRIBE TABLE g_tablctrl110_itab LINES tablctrl110-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_110
.
ENDIF.

CLEAR sy-ucomm.

ENDMODULE.                 " set_cursor  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_title  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_title OUTPUT.

IF zic_prep_rolereq-crossco_fl = 'X'.
 g_text = ' : Cross Company Authorisation'.
 SET TITLEBAR 'PREP_TITLE' WITH g_text.
 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
ENDIF.
IF old_ok_code = 'CREATE' AND ( okcode_100 = '' OR
   okcode_100 = 'CREATE' ) .
 MOVE 'ATTACH' TO wa_tab-fcode.
 APPEND wa_tab TO it_tab.
 MOVE 'LIST' TO wa_tab-fcode.
 APPEND wa_tab TO it_tab.
 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
ENDIF.
IF old_ok_code = 'CHANGE' AND ( okcode_100 = '' OR
   okcode_100 = 'CHANGE' OR okcode_100 = 'LIST' ) .
 IF zic_prep_rolereq-crc_fl = 'X' OR
    zic_prep_rolereq-crossco_fl = 'X'.
 ELSE.
   MOVE 'ATTACH' TO wa_tab-fcode.
   APPEND wa_tab TO it_tab.
 ENDIF.
 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
ENDIF.

IF old_ok_code = 'DELETE' AND ( okcode_100 = '' OR
   okcode_100 = 'DELETE' OR okcode_100 = 'LIST' ) .
 MOVE 'ATTACH' TO wa_tab-fcode.
 APPEND wa_tab TO it_tab.
 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
ENDIF.

IF old_ok_code = 'DISPLAY'
  AND zic_prep_rolereq-comm_fl = 'X'.
 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
ELSE.

 IF old_ok_code = 'DISPLAY' AND ( okcode_100 = '' OR
     okcode_100 = 'DISPLAY' OR okcode_100 = 'LIST' ) .
   MOVE 'ATTACH' TO wa_tab-fcode.
   APPEND wa_tab TO it_tab.
   SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
 ENDIF.

ENDIF.

IF old_ok_code = 'APPROVE' AND ( okcode_100 = '' OR
   okcode_100 = 'APPROVE' OR okcode_100 = 'LIST' ) .
 MOVE 'ATTACH' TO wa_tab-fcode.
 APPEND wa_tab TO it_tab.
 SET PF-STATUS 'OPTNS' EXCLUDING it_tab.
ENDIF.

IF zic_prep_rolereq-crc_fl = 'X'.
 g_text = ' : CRC Authorisation'.
 SET TITLEBAR 'PREP_TITLE' WITH g_text.
ENDIF.
* Begin of <> 25032014
**** Get Users maintained in SET 'ZICE_ARMS_CREATE_GUIDE'.
CALL FUNCTION 'G_SET_GET_ALL_VALUES'
 EXPORTING
   client        = sy-mandt
   setnr         = 'ZICE_ARMS_CREATE_GUIDE'
   table         = 'AGR_USERS'
   class         = '0000'
   fieldname     = 'UNAME'
 TABLES
   set_values    = lt_set_values
 EXCEPTIONS
   set_not_found = 1
   OTHERS        = 2.

* End of <> 25032014
ENDMODULE.                 " set_title  OUTPUT

*&spwizard: output module for tc 'TABLCTRL110'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl110_init OUTPUT.
IF g_tablctrl110_copied IS INITIAL AND old_ok_code <> 'CREATE'.

 REFRESH g_tablctrl110_itab[].
 CLEAR   g_tablctrl110_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL110_itab'
*Begin of <RD1K963151>.
 IF zic_prep_rolereq-docno IS NOT INITIAL.
*End of <RD1K963151>.
   SELECT * FROM zic_prep_rolerei
      INTO CORRESPONDING FIELDS
      OF TABLE g_tablctrl110_itab WHERE moduleid = 'MM' AND
               docno = zic_prep_rolereq-docno ORDER BY PRIMARY KEY.
*Begin of <RD1K963151>.
 ENDIF.
*End of <RD1K963151>.
 g_tablctrl110_copied = 'X'.
 READ TABLE g_tablctrl110_itab INTO g_tablctrl110_wa INDEX 1.
 IF sy-subrc = 0.
   moduleid = g_tablctrl110_wa-moduleid.
 ENDIF.
 REFRESH CONTROL 'TABLCTRL110' FROM SCREEN '0110'.
ENDIF.
ENDMODULE.                    "TABLCTRL110_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL110'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl110_move OUTPUT.

MOVE-CORRESPONDING g_tablctrl110_wa TO zic_prep_rolerei.

IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.

 IF old_ok_code = 'CRCROLES' OR zic_prep_rolereq-crc_fl = 'X'.
   SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
WHERE ROLE_TYPE =
ZIC_PREP_ROLEREI-ROLE_NAME
ORDER BY PRIMARY KEY .
ENDSELECT.
   IF sy-subrc = 0 .
     MOVE zmm_prep_rolecrc-brief_desc TO role_desc.
   ENDIF.
   SELECT * FROM ZMM_PREP_CRCDESG UP TO 1 ROWS
WHERE ROLE_TYPE =
ZIC_PREP_ROLEREI-ROLE_NAME AND ROLE_TYPE_EX = ZIC_PREP_ROLEREI-ROLE_TYPE_EX
ORDER BY PRIMARY KEY .
ENDSELECT.
   IF sy-subrc = 0 AND zic_prep_rolerei-plant <> ''.
     MOVE zmm_prep_crcdesg-crc_pos TO crc_pos.
   ENDIF.
 ELSE.
   SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
               zic_prep_rolerei-role_name.
   IF sy-subrc = 0 .
     MOVE zmm_prep_roledes-brief_desc TO role_desc.
   ENDIF.
 ENDIF.

ENDIF.

ENDMODULE.                    "TABLCTRL110_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL110'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl110_get_lines OUTPUT.
g_tablctrl110_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL110_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_dynnr  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_dynnr OUTPUT.
IF dynnr IS INITIAL.
 dynnr = '101'.
ENDIF.
CASE moduleid.

 WHEN 'MM'.
   dynnr = '0110'.
 WHEN 'PM'.
   dynnr = '0111'.
 WHEN 'PS'.
   dynnr = '0112'.
 WHEN 'PP'.
   dynnr = '0113'.
 WHEN 'SD'.
   dynnr = '0114'.
 WHEN 'QM'.
   dynnr = '0115'.
 WHEN 'HSE'.
   dynnr = '0116'.
 WHEN 'OLM'.
   dynnr = '0117'.

   """"""""""""""""""""""""""""
   "addition by lipsy  for srm module introduction on 2.03.2015 RD1K996555
 WHEN 'SRM'.
   dynnr = '0118'.
   "end of addition by lipsy  for srm module introduction   on  3.03.2015 RD1K996555
   """""""""""""""""""""""""""""
ENDCASE.
ENDMODULE.                 " set_dynnr  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr110_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr110_col_attrib OUTPUT.

LOOP AT tablctrl110-cols INTO cols WHERE index GT 11.
 cols-invisible = '1'.
 MODIFY tablctrl110-cols FROM cols INDEX sy-tabix.
ENDLOOP.

LOOP AT tablctrl110-cols INTO cols WHERE index = 12.
 cols-invisible = '0'.
 MODIFY tablctrl110-cols FROM cols INDEX sy-tabix.
ENDLOOP.

ENDMODULE.                 " scr110_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  delete_dup_110  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE delete_dup_110 OUTPUT.

IF NOT g_tablctrl110_itab[] IS INITIAL .

 SORT g_tablctrl110_itab
 BY role_name plant grp sloc receipt_loc approver.
 DELETE ADJACENT DUPLICATES FROM g_tablctrl110_itab
 COMPARING role_name plant grp sloc receipt_loc approver.

ENDIF.

DESCRIBE TABLE g_tablctrl110_itab LINES tablctrl110-lines.

ENDMODULE.                 " delete_dup_110  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL110_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl110_attrib OUTPUT.

IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 IF old_ok_code <> 'CRCROLES'.
   IF old_ok_code = 'CREATE'.
   ELSEIF zic_prep_rolereq-crc_fl = 'X'.
     crc_check_fl = 'X'.
   ENDIF.
 ELSE.
   crc_check_fl = 'X'.
 ENDIF.

 IF crc_check_fl <> 'X' .

   CLEAR crc_check_fl.

   SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                                             g_tablctrl110_wa-role_name
.

   IF sy-subrc = 0.

     LOOP AT SCREEN.

       IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

         IF old_ok_code <> 'APPROVE'.
           screen-input = 1.
         ELSE.
           screen-input = 0.
         ENDIF.
         MODIFY SCREEN.
       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
         old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
         screen-input = 1.
         MODIFY SCREEN.
       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

         IF zmm_prep_roledes-plant = 'X' AND
                       old_ok_code <> 'APPROVE'.
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-GRP'.

         IF zmm_prep_roledes-p_grp = 'X' AND
                       old_ok_code <> 'APPROVE'.
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER'.

         IF zmm_prep_roledes-app_level = 'X' AND
                     old_ok_code <> 'APPROVE'.
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

*Begin of <RD1K962817>.
       IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER'.
         IF g_tablctrl110_wa-role_name = 'M8'.
           IF zmm_prep_roledes-app_level = 'X' AND
                       old_ok_code <> 'APPROVE'.

             screen-input = 0.

             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.
       ENDIF.
*End of <RD1K962817>.
       IF screen-name = 'ZIC_PREP_ROLEREI-SLOC'.

         IF zmm_prep_roledes-s_loc = 'X' AND
                   old_ok_code <> 'APPROVE'.
           .
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.
       ENDIF.

       IF screen-name = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.

         IF zmm_prep_roledes-r_loc = 'X' AND
                   old_ok_code <> 'APPROVE'.
           .
           screen-input = 1.
           MODIFY SCREEN.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDIF.

     ENDLOOP.

   ELSE.

     LOOP AT SCREEN.

       IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                      NOT old_ok_code IS INITIAL AND
                      old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
         IF NOT zic_prep_rolerei-role_name IS INITIAL .
           MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
         ENDIF.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDLOOP.

   ENDIF.

 ELSE.

   IF zic_prep_rolereq-crc_fl = 'X' OR old_ok_code = 'CRCROLES'.

     SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
WHERE ROLE_TYPE =
G_TABLCTRL110_WA-ROLE_NAME
ORDER BY PRIMARY KEY .
ENDSELECT.

     IF sy-subrc = 0.

       LOOP AT SCREEN.

         IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

           IF old_ok_code <> 'APPROVE'.
             screen-input = 1.
           ELSE.
             screen-input = 0.
           ENDIF.
           MODIFY SCREEN.
         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
           old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
           screen-input = 1.
           MODIFY SCREEN.
         ENDIF.


         IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .


           IF zmm_prep_rolecrc-plant = 'X' AND
                                old_ok_code <> 'APPROVE'.
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-GRP' .


           IF zmm_prep_rolecrc-p_grp = 'X' AND
                                old_ok_code <> 'APPROVE'.
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.


         IF screen-name = 'ZIC_PREP_ROLEREI-SLOC'.

           IF zmm_prep_rolecrc-s_loc = 'X' AND
                     old_ok_code <> 'APPROVE'.
             .
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.
         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.

           IF zmm_prep_rolecrc-r_loc = 'X' AND
                     old_ok_code <> 'APPROVE'.
             .
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.
**
         IF screen-name = 'CRC_POS' AND
               ( zic_prep_rolerei-role_name <> 'M3B' AND
                 zic_prep_rolerei-role_name <> 'M11S' AND
                 zic_prep_rolerei-role_name <> 'M11M' ).
           IF old_ok_code <> 'APPROVE'.
             screen-required = 1.
             screen-input = 1.
             MODIFY SCREEN.
           ELSE.
             screen-input = 0.
             MODIFY SCREEN.
           ENDIF.

         ENDIF.

         IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER' AND
                ( zic_prep_rolerei-role_name = 'M3B' OR
                 zic_prep_rolerei-role_name = 'M11S' OR
                 zic_prep_rolerei-role_name = 'M11M' ).
           .          screen-input = 1.
         ELSEIF screen-name = 'ZIC_PREP_ROLEREI-APPROVER' AND
                ( zic_prep_rolerei-role_name <> 'M3B' AND
                 zic_prep_rolerei-role_name <> 'M11S' AND
                 zic_prep_rolerei-role_name <> 'M11M' ).
           screen-input = 0.
         ENDIF.

         MODIFY SCREEN.

**

       ENDLOOP.

     ELSE.

       LOOP AT SCREEN.

         IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                            NOT old_ok_code IS INITIAL.
           screen-input = 1.
           MODIFY SCREEN.

           IF NOT zic_prep_rolerei-role_name IS INITIAL.
             MESSAGE i116(zhelp) WITH zic_prep_rolerei-role_name.
           ENDIF.
         ELSE.
           screen-input = 0.
           MODIFY SCREEN.
         ENDIF.

       ENDLOOP.

     ENDIF.

   ENDIF.

 ENDIF.

ELSE.

 LOOP AT SCREEN.

   screen-input = 0.
   MODIFY SCREEN.
*
 ENDLOOP.
*

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

ENDMODULE.                 " TABLCTRL110_attrib  OUTPUT

*&spwizard: output module for tc 'TABLCTRL111'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl111_init OUTPUT.
IF g_tablctrl111_copied IS INITIAL AND old_ok_code <> 'CREATE'.
 REFRESH g_tablctrl111_itab[].
 CLEAR   g_tablctrl111_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL111_itab'
 SELECT * FROM zic_prep_rolerei
    INTO CORRESPONDING FIELDS
    OF TABLE g_tablctrl111_itab WHERE moduleid = 'PM' AND
             docno = zic_prep_rolereq-docno.
 g_tablctrl111_copied = 'X'.
 REFRESH CONTROL 'TABLCTRL111' FROM SCREEN '0111'.
ENDIF.
ENDMODULE.                    "TABLCTRL111_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL111'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl111_move OUTPUT.

MOVE-CORRESPONDING g_tablctrl111_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zpm_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zpm_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.
ENDMODULE.                    "TABLCTRL111_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL111'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl111_get_lines OUTPUT.
g_tablctrl111_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL111_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  delete_dup_111  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE delete_dup_111 OUTPUT.
IF NOT g_tablctrl111_itab[] IS INITIAL .

 SORT g_tablctrl111_itab
 BY role_name plant shop_no.
 DELETE ADJACENT DUPLICATES FROM g_tablctrl111_itab
 COMPARING role_name plant shop_no.

ENDIF.

DESCRIBE TABLE g_tablctrl111_itab LINES tablctrl111-lines.

ENDMODULE.                 " delete_dup_111  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL111_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl111_attrib OUTPUT.
IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 SELECT SINGLE * FROM zpm_prep_roledes WHERE role_type =
                                           g_tablctrl111_wa-role_name
.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

       IF zpm_prep_roledes-plant = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-SHOP_NO' .

       IF zpm_prep_roledes-shop_no = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.


   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ENDIF.

ELSE.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

ENDMODULE.                 " TABLCTRL111_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_cursor_111  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_111 OUTPUT.

DESCRIBE TABLE g_tablctrl111_itab LINES tablctrl111-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_111
.
ENDIF.

CLEAR sy-ucomm.

ENDMODULE.                 " set_cursor_111  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr111_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr111_col_attrib OUTPUT.

LOOP AT tablctrl111-cols INTO cols WHERE index GT 8.
 cols-invisible = '1'.
 MODIFY tablctrl111-cols FROM cols INDEX sy-tabix.
ENDLOOP.

ENDMODULE.                 " scr111_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_200 OUTPUT.
SET PF-STATUS 'STATUS_200'.
*  SET TITLEBAR 'xxx'.

ENDMODULE.                 " STATUS_200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SELECT_DATA  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE select_data OUTPUT.

g_release = zic_prep_rolereq-req_cr_fl.
g_approve = zic_prep_rolereq-req_app_fl.
g_approve0 = zic_prep_rolereq-req_app0_fl.
g_approve1 = zic_prep_rolereq-req_app1_fl.

SELECT SINGLE * FROM zic_prep_rolereq
               WHERE docno = zic_prep_rolereq-docno.

IF zic_prep_rolereq-req_cr_fl IS INITIAL.
 zic_prep_rolereq-req_cr_fl = g_release.
ENDIF.
IF zic_prep_rolereq-req_app_fl IS INITIAL.
 zic_prep_rolereq-req_app_fl = g_approve.
ENDIF.
IF zic_prep_rolereq-req_app1_fl IS INITIAL.
 zic_prep_rolereq-req_app1_fl = g_approve1.
ENDIF.

IF zic_prep_rolereq-req_app0_fl IS INITIAL.
 zic_prep_rolereq-req_app0_fl = g_approve0.
ENDIF.


CLEAR : g_release, g_approve, g_approve0, g_approve1.

*  select single * from zic_prep_rolereq
*  where docno = zic_prep_rolereq-docno.

SELECT * FROM zic_prep_rolerei INTO TABLE ist_item
WHERE docno = zic_prep_rolereq-docno.

ENDMODULE.                 " SELECT_DATA  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  value_list1  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE value_list1 OUTPUT.
SUPPRESS DIALOG.
LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0.

DATA : l_desc(30).

SORT ist_item DESCENDING.

LOOP AT ist_item INTO wa_item.
 CASE wa_item-moduleid.
   WHEN 'MM'.
     PERFORM check_module_status_mm.
   WHEN 'PM'.
     PERFORM check_module_status_pm.
   WHEN 'PS'.
     PERFORM check_module_status_ps.
   WHEN 'PP'.
     PERFORM check_module_status_pp.
   WHEN 'SD'.
     PERFORM check_module_status_sd.
   WHEN 'QM'.
     PERFORM check_module_status_qm.
   WHEN 'HSE'.
     PERFORM check_module_status_hse.
 ENDCASE.
ENDLOOP.

LOOP AT ist_item INTO wa_item.

 CASE wa_item-moduleid .

   WHEN 'MM'.

     AT NEW moduleid.

       WRITE :/.

       IF mm_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.

       WRITE: / 'MM Module', 'Role', 'Description',
              AT 48  'Plant',
              AT 53  'PurGp',
              AT 59  'Sloc',
              AT 64  'RecptLoc',
              AT 73  'User level' .

       FORMAT INTENSIFIED OFF COLOR OFF.

*     uline.

     ENDAT.

     IF zic_prep_rolereq-crc_fl = 'X'.

       SELECT BRIEF_DESC FROM ZMM_PREP_ROLECRC INTO L_DESC UP TO 1 ROWS
WHERE ROLE_TYPE = WA_ITEM-ROLE_NAME
ORDER BY PRIMARY KEY .
ENDSELECT.

     ELSE.

       SELECT SINGLE brief_desc FROM zmm_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     ENDIF.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc,
              AT 48 wa_item-plant,
              AT 53 wa_item-grp,
              AT 59 wa_item-sloc,
              AT 64 wa_item-receipt_loc,
              AT 73 wa_item-approver.

   WHEN 'PM'.

     AT NEW moduleid.

       WRITE /.

       IF pm_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.
       WRITE: / 'PM Module', 'Role', 'Description',
          AT 48  'Plant',
          AT 54  'ShopNo'.

       FORMAT INTENSIFIED OFF COLOR OFF.

*        uline.
     ENDAT.

     SELECT SINGLE brief_desc FROM zpm_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc,
              AT 48 wa_item-plant,
              AT 54 wa_item-shop_no.

**
   WHEN 'PS'.

     AT NEW moduleid.

       WRITE /.

       IF ps_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.
       WRITE: / 'PS Module', 'Role', 'Description',
          AT 48  'Service',
          AT 56  'Project',
          AT 64  'Location',
          AT 73  'Asset',
          AT 79  'Basin'.

       FORMAT INTENSIFIED OFF COLOR OFF.

*        uline.
     ENDAT.

     SELECT SINGLE brief_desc FROM zps_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc,
              AT 48 wa_item-service,
              AT 56 wa_item-project,
              AT 64 wa_item-location,
              AT 73 wa_item-asset,
              AT 79 wa_item-basin.

***

   WHEN 'PP'.

     AT NEW moduleid.

       WRITE /.

       IF pp_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.
       WRITE: / 'PP Module', 'Role', 'Description',
          AT 48  'Plant',
          AT 56  'Sloc',
          AT 64  'Resource',
          AT 73  'CTF_sloc'.

       FORMAT INTENSIFIED OFF COLOR OFF.

*        uline.
     ENDAT.

     SELECT SINGLE brief_desc FROM zpp_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc,
              AT 48 wa_item-plant,
              AT 56 wa_item-sloc,
              AT 64 wa_item-res,
              AT 73 wa_item-ctf_sloc.

   WHEN 'SD'.

     AT NEW moduleid.

       WRITE /.

       IF sd_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.
       WRITE: / 'SD Module', 'Role', 'Description',
          AT 48  'S_Org',
          AT 56  'Div',
          AT 64  'Plant',
          AT 73  'ShPt'.

       FORMAT INTENSIFIED OFF COLOR OFF.

*        uline.
     ENDAT.

     SELECT SINGLE brief_desc FROM zsd_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc,
              AT 48 wa_item-sale_org,
              AT 56 wa_item-div,
              AT 64 wa_item-plant,
              AT 73 wa_item-ship_point.

   WHEN 'QM'.

     AT NEW moduleid.

       WRITE /.

       IF qm_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.
       WRITE: / 'QM Module', 'Role', 'Description',
          AT 48  'Plant',
          AT 56  'Asset'.

       FORMAT INTENSIFIED OFF COLOR OFF.

*        uline.
     ENDAT.

     SELECT SINGLE brief_desc FROM zqm_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc,
              AT 48 wa_item-plant,
              AT 56 wa_item-asset_qm.

   WHEN 'HSE'.

     AT NEW moduleid.

       WRITE /.

       IF hs_not_ok = 'X'.
         FORMAT INTENSIFIED ON COLOR 6.
       ELSE.
         FORMAT INTENSIFIED ON COLOR 5.
       ENDIF.
       WRITE: / 'HSE Module', 'Role', 'Description'.

       FORMAT INTENSIFIED OFF COLOR OFF.

*        uline.
     ENDAT.

     SELECT SINGLE brief_desc FROM zhs_prep_roledes INTO l_desc
           WHERE role_type = wa_item-role_name.

     WRITE: / wa_item-moduleid, AT 12 wa_item-role_name, AT 17 l_desc.

 ENDCASE.

*
 HIDE : wa_item-moduleid, wa_item-role_name, wa_item-plant,
          wa_item-grp, wa_item-sloc, wa_item-receipt_loc,
          wa_item-approver, wa_item-service, wa_item-project,
          wa_item-location,wa_item-region,wa_item-asset,
          wa_item-basin,wa_item-res, wa_item-ctf_sloc,
          wa_item-sale_org,wa_item-div,wa_item-plant,
          wa_item-ship_point,wa_item-asset_qm.


ENDLOOP.

ENDMODULE.                 " value_list1  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr111_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr111_attrib OUTPUT.
LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL111_DELETE' OR
          screen-name = 'TABLCTRL111_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.
ENDMODULE.                 " scr111_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr110_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr110_attrib OUTPUT.

LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL110_DELETE' OR
          screen-name = 'TABLCTRL110_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.

ENDMODULE.                 " scr110_attrib  OUTPUT

*&spwizard: output module for tc 'TABLCTRL112'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl112_init OUTPUT.
IF g_tablctrl112_copied IS INITIAL AND old_ok_code <> 'CREATE'.
 REFRESH g_tablctrl112_itab[].
 CLEAR   g_tablctrl112_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL112_itab'
 SELECT * FROM zic_prep_rolerei
    INTO CORRESPONDING FIELDS
    OF TABLE g_tablctrl112_itab WHERE moduleid = 'PS' AND
             docno = zic_prep_rolereq-docno.
 g_tablctrl112_copied = 'X'.
 REFRESH CONTROL 'TABLCTRL112' FROM SCREEN '0112'.
ENDIF.
ENDMODULE.                    "TABLCTRL112_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL112'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl112_move OUTPUT.

MOVE-CORRESPONDING g_tablctrl112_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zps_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zps_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.

ENDMODULE.                    "TABLCTRL112_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL112'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl112_get_lines OUTPUT.
g_tablctrl112_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL112_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr112_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr112_col_attrib OUTPUT.
LOOP AT tablctrl112-cols INTO cols WHERE index GT 11.
 cols-invisible = '1'.
 MODIFY tablctrl112-cols FROM cols INDEX sy-tabix.
ENDLOOP.
ENDMODULE.                 " scr112_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr112_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr112_attrib OUTPUT.
LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL112_DELETE' OR
          screen-name = 'TABLCTRL112_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.
ENDMODULE.                 " scr112_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL112_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl112_attrib OUTPUT.

IF old_ok_code <> 'DISPLAY' AND old_ok_code <> '' AND
   NOT g_tablctrl112_wa-role_name IS INITIAL.

 SELECT SINGLE * FROM zps_prep_roledes WHERE role_type =
                   g_tablctrl112_wa-role_name.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-SERVICE' .

*            if zps_prep_roledes-service = 'X' and
       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-PROJECT' .

       IF zps_prep_roledes-project = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-LOCATION' .

       IF zps_prep_roledes-location = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

*        if screen-name = 'ZIC_PREP_ROLEREI-REGION' .
*
*            if zps_prep_roledes-region = 'X' and
*                          old_ok_code <> 'APPROVE'.
*                screen-input = 1.
*                modify screen.
*            else.
*                screen-input = 0.
*                modify screen.
*            endif.
*
*        endif.

     IF screen-name = 'ZIC_PREP_ROLEREI-ASSET' .

       IF zps_prep_roledes-asset = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-BASIN' .

       IF zps_prep_roledes-basin = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.
 ENDIF.
ENDIF.

IF old_ok_code = 'DISPLAY'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

ENDMODULE.                 " TABLCTRL112_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_cursor_112  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_112 OUTPUT.

DESCRIBE TABLE g_tablctrl112_itab LINES tablctrl112-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_112
.
ENDIF.

CLEAR sy-ucomm.

ENDMODULE.                 " set_cursor_112  OUTPUT

*&spwizard: output module for tc 'TABLCTRL113'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl113_init OUTPUT.
IF g_tablctrl113_copied IS INITIAL AND old_ok_code <> 'CREATE'.
 REFRESH g_tablctrl113_itab[].
 CLEAR   g_tablctrl113_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL113_itab'
 SELECT * FROM zic_prep_rolerei
    INTO CORRESPONDING FIELDS
    OF TABLE g_tablctrl113_itab WHERE moduleid = 'PP' AND
    docno = zic_prep_rolereq-docno.
 g_tablctrl113_copied = 'X'.
 REFRESH CONTROL 'TABLCTRL113' FROM SCREEN '0113'.
ENDIF.
ENDMODULE.                    "TABLCTRL113_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL113'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl113_move OUTPUT.
MOVE-CORRESPONDING g_tablctrl113_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zpp_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zpp_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.
ENDMODULE.                    "TABLCTRL113_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL113'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl113_get_lines OUTPUT.
g_tablctrl113_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL113_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL113_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl113_attrib OUTPUT.

IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 SELECT SINGLE * FROM zpp_prep_roledes WHERE role_type =
                                           g_tablctrl113_wa-role_name
.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

       IF zpp_prep_roledes-plant = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-SLOC' .

       IF zpp_prep_roledes-sloc = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-RES'.

       SELECT * FROM zpp_prep_res INTO CORRESPONDING FIELDS OF
       TABLE it_res  WHERE role_type = zic_prep_rolerei-role_name
       AND plant = zic_prep_rolerei-plant.

       IF sy-subrc = 0  AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-CTF_SLOC' .

       SELECT SINGLE * FROM zpp_prep_droleex WHERE
           role_type = zic_prep_rolerei-role_name AND
           plant = zic_prep_rolerei-plant AND
           sloc = zic_prep_rolerei-sloc.

       IF sy-subrc = 0 AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ENDIF.

ELSE.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

ENDMODULE.                 " TABLCTRL113_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_cursor_113  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_113 OUTPUT.

DESCRIBE TABLE g_tablctrl113_itab LINES tablctrl113-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_113.
ENDIF.

CLEAR sy-ucomm.

ENDMODULE.                 " set_cursor_113  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr113_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr113_col_attrib OUTPUT.
LOOP AT tablctrl113-cols INTO cols WHERE index GT 9.
 cols-invisible = '1'.
 MODIFY tablctrl113-cols FROM cols INDEX sy-tabix.
ENDLOOP.
ENDMODULE.                 " scr113_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr113_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr113_attrib OUTPUT.

LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL113_DELETE' OR
          screen-name = 'TABLCTRL113_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.

ENDMODULE.                 " scr113_attrib  OUTPUT

*&spwizard: output module for tc 'TABLCTRL114'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl114_init OUTPUT.
IF g_tablctrl114_copied IS INITIAL AND old_ok_code <> 'CREATE'.
 REFRESH g_tablctrl114_itab[].
 CLEAR   g_tablctrl114_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL114_itab'
 SELECT * FROM zic_prep_rolerei
    INTO CORRESPONDING FIELDS
    OF TABLE g_tablctrl114_itab WHERE moduleid = 'SD' AND
    docno = zic_prep_rolereq-docno.
 g_tablctrl114_copied = 'X'.
 REFRESH CONTROL 'TABLCTRL114' FROM SCREEN '0114'.
ENDIF.
ENDMODULE.                    "TABLCTRL114_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL114'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl114_move OUTPUT.
**13/04/07
CLEAR zic_prep_rolerei-rej_fl_save.
MOVE-CORRESPONDING g_tablctrl114_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zsd_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zsd_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.
ENDMODULE.                    "TABLCTRL114_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL114'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl114_get_lines OUTPUT.
g_tablctrl114_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL114_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr114_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr114_col_attrib OUTPUT.

LOOP AT tablctrl114-cols INTO cols WHERE index GT 9.
 cols-invisible = '1'.
 MODIFY tablctrl114-cols FROM cols INDEX sy-tabix.
ENDLOOP.

ENDMODULE.                 " scr114_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr114_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr114_attrib OUTPUT.

LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL114_DELETE' OR
          screen-name = 'TABLCTRL114_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.

ENDMODULE.                 " scr114_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL114_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl114_attrib OUTPUT.

IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 SELECT SINGLE * FROM zsd_prep_roledes WHERE role_type =
                                           g_tablctrl114_wa-role_name
.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

       IF zsd_prep_roledes-plant = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-SALE_ORG' .

       IF zsd_prep_roledes-sale_org = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-DIV'.

       IF zsd_prep_roledes-div = 'X'  AND
                    old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-SHIP_POINT' .

       IF zsd_prep_roledes-ship_point = 'X'  AND
                    old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ENDIF.

ELSE.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

ENDMODULE.                 " TABLCTRL114_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_cursor_114  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_114 OUTPUT.

DESCRIBE TABLE g_tablctrl114_itab LINES tablctrl114-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_114.
ENDIF.

CLEAR sy-ucomm.

ENDMODULE.                 " set_cursor_114  OUTPUT

*&spwizard: output module for tc 'TABLCTRL115'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl115_init OUTPUT.
IF g_tablctrl115_copied IS INITIAL AND old_ok_code <> 'CREATE'.
 REFRESH g_tablctrl115_itab[].
 CLEAR   g_tablctrl115_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL115_itab'
 SELECT * FROM zic_prep_rolerei
    INTO CORRESPONDING FIELDS
    OF TABLE g_tablctrl115_itab WHERE
    moduleid = 'QM' AND
    docno = zic_prep_rolereq-docno.
 g_tablctrl115_copied = 'X'.
 REFRESH CONTROL 'TABLCTRL115' FROM SCREEN '0115'.
ENDIF.
ENDMODULE.                    "TABLCTRL115_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL115'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl115_move OUTPUT.
MOVE-CORRESPONDING g_tablctrl115_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zqm_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zqm_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.
ENDMODULE.                    "TABLCTRL115_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL115'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl115_get_lines OUTPUT.
g_tablctrl115_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL115_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr115_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr115_col_attrib OUTPUT.
LOOP AT tablctrl115-cols INTO cols WHERE index GT 7.
 cols-invisible = '1'.
 MODIFY tablctrl115-cols FROM cols INDEX sy-tabix.
ENDLOOP.
ENDMODULE.                 " scr115_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr115_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr115_attrib OUTPUT.
LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL115_DELETE' OR
          screen-name = 'TABLCTRL115_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.
ENDMODULE.                 " scr115_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL115_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl115_attrib OUTPUT.

IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 SELECT SINGLE * FROM zqm_prep_roledes WHERE role_type =
                                           g_tablctrl115_wa-role_name
.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

       IF zic_prep_rolereq-ccode = 'MUM' AND
          zic_prep_rolerei-role_name = 'Q1' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-ASSET_QM' .

       SELECT SINGLE * FROM zqm_prep_asset WHERE ccode =
                                             zic_prep_rolereq-ccode.

       IF sy-subrc = 0 AND
          zic_prep_rolerei-role_name = 'Q2' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ENDIF.

ELSE.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.
ENDMODULE.                 " TABLCTRL115_attrib  OUTPUT

*&spwizard: output module for tc 'TABLCTRL116'. do not change this line!
*&spwizard: copy ddic-table to itab
MODULE tablctrl116_init OUTPUT.
IF g_tablctrl116_copied IS INITIAL AND old_ok_code <> 'CREATE'.
 REFRESH g_tablctrl116_itab[].
 CLEAR   g_tablctrl116_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL116_itab'
 SELECT * FROM zic_prep_rolerei
    INTO CORRESPONDING FIELDS
    OF TABLE g_tablctrl116_itab WHERE moduleid = 'HSE' AND
             docno = zic_prep_rolereq-docno.
 g_tablctrl116_copied = 'X'.
 REFRESH CONTROL 'TABLCTRL116' FROM SCREEN '0116'.
ENDIF.
ENDMODULE.                    "TABLCTRL116_init OUTPUT

*&spwizard: output module for tc 'TABLCTRL116'. do not change this line!
*&spwizard: move itab to dynpro
MODULE tablctrl116_move OUTPUT.
MOVE-CORRESPONDING g_tablctrl116_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zhs_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zhs_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.
ENDMODULE.                    "TABLCTRL116_move OUTPUT

*&spwizard: output module for tc 'TABLCTRL116'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tablctrl116_get_lines OUTPUT.
g_tablctrl116_lines = sy-loopc.
ENDMODULE.                    "TABLCTRL116_get_lines OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr116_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr116_col_attrib OUTPUT.

LOOP AT tablctrl116-cols INTO cols WHERE index GT 6.
 cols-invisible = '1'.
 MODIFY tablctrl116-cols FROM cols INDEX sy-tabix.
ENDLOOP.

ENDMODULE.                 " scr116_col_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  scr116_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr116_attrib OUTPUT.
LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL116_DELETE' OR
          screen-name = 'TABLCTRL116_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.
ENDMODULE.                 " scr116_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL116_attrib  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl116_attrib OUTPUT.
IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.

 SELECT SINGLE * FROM zhs_prep_roledes WHERE role_type =
                                           g_tablctrl116_wa-role_name
.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ENDIF.

ELSE.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.
ENDMODULE.                 " TABLCTRL116_attrib  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  set_cursor_116  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_116 OUTPUT.

DESCRIBE TABLE g_tablctrl116_itab LINES tablctrl116-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_111
.
ENDIF.

CLEAR sy-ucomm.

ENDMODULE.                 " set_cursor_116  OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_117'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: COPY DDIC-TABLE TO ITAB
MODULE tc_117_init OUTPUT.
IF g_tc_117_copied IS INITIAL.
*&SPWIZARD: COPY DDIC-TABLE 'ZIC_PREP_ROLEREI'
*&SPWIZARD: INTO INTERNAL TABLE 'g_TC_117_itab'
*Begin of <RD1K983325>.

 REFRESH g_tc_117_itab[].
 CLEAR   g_tc_117_itab.
 IF zic_prep_rolereq-docno IS NOT INITIAL.
*End of <RD1K983325>.
   SELECT * FROM zic_prep_rolerei
      INTO CORRESPONDING FIELDS
      OF TABLE g_tc_117_itab WHERE moduleid = 'OLM' AND
               docno = zic_prep_rolereq-docno ORDER BY PRIMARY KEY.
*Begin of <RD1K983325>.
 ENDIF.
*End of <RD1K983325>.
 g_tc_117_copied = 'X'.
 READ TABLE g_tc_117_itab INTO g_tc_117_wa INDEX 1.
 IF sy-subrc = 0.
   moduleid = g_tc_117_wa-moduleid.
 ENDIF.
 REFRESH CONTROL 'TC_117' FROM SCREEN '0117'.
ENDIF.
ENDMODULE.                    "TC_117_INIT OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_117'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MOVE ITAB TO DYNPRO
MODULE tc_117_move OUTPUT.
MOVE-CORRESPONDING g_tc_117_wa TO zic_prep_rolerei.
IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.
 SELECT SINGLE * FROM zfi_prep_roledes WHERE role_type =
              zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zfi_prep_roledes-brief_desc TO role_desc.
 ENDIF.
ENDIF.
ENDMODULE.                    "TC_117_MOVE OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_117'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE tc_117_get_lines OUTPUT.
g_tc_117_lines = sy-loopc.
ENDMODULE.                    "TC_117_GET_LINES OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SCR117_COL_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr117_col_attrib OUTPUT.
LOOP AT tc_117-cols INTO cols WHERE index GT 11.
 cols-invisible = '1'.
 MODIFY tc_117-cols FROM cols INDEX sy-tabix.
ENDLOOP.

LOOP AT tc_117-cols INTO cols WHERE index = 12.
 cols-invisible = '0'.
 MODIFY tc_117-cols FROM cols INDEX sy-tabix.
ENDLOOP.
ENDMODULE.                 " SCR117_COL_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SCR117_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr117_attrib OUTPUT.
LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TC_117_DELETE' OR
          screen-name = 'TC_117_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.

 IF old_ok_code = 'DISPLAY'.
   IF screen-name = 'TC_117_DELETE' OR
          screen-name = 'TC_117_INSERT' OR
          screen-name = 'COPY'.
*        OR
*        SCREEN-NAME = 'ZIC_PREP_ROLEREI-ROLE_NAME' OR
*         SCREEN-NAME = 'ZMM_PREP_ROLEREI-ROLE_NAME'.
     screen-input = 0.
     MODIFY SCREEN.

   ENDIF.

   IF  screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' .
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
*    modify screen.
ENDLOOP.
ENDMODULE.                 " SCR117_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TC_117_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_117_attrib OUTPUT.

ENDMODULE.                 " TC_117_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_CURSOR_117  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_117 OUTPUT.
DESCRIBE TABLE g_tc_117_itab LINES tc_117-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_117
.
ENDIF.

CLEAR sy-ucomm.
ENDMODULE.                 " SET_CURSOR_117  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  POP_MESSAGE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pop_message OUTPUT.

DATA : gv_auth TYPE c.

IMPORT gv_auth TO gv_auth FROM MEMORY  ID 'AUTH'.

IF gv_auth <> 'X'.
 MESSAGE 'Please Use TRANSACTION ZOVL_ARMS.' TYPE 'E'.
ENDIF.

IF sy-tcode = 'ZICE_ARMS'.
*    BREAK-POINT.

 lv_msg_var = lv_msg_var + 1.

ENDIF.

*  IF SY-TCODE = 'ZICE_ARMS' AND OLD_OK_CODE = ' ' AND SY-UCOMM = ' '.
IF lv_msg_var = '1'.
 IF  okcode_100_p NE 'BAC'.
   DATA : l_ans1 TYPE c.
   CLEAR : wa_call.
   SELECT * FROM TVARVC INTO CORRESPONDING FIELDS OF WA_CALL UP TO 1 ROWS
WHERE NAME = 'ZGRC_CALL'
ORDER BY PRIMARY KEY .
ENDSELECT.
   IF wa_call-low EQ 'X'.

*        CALL FUNCTION 'POPUP_TO_INFORM'
*          EXPORTING
*            titel = 'ZOVL_ARMS USER GUIDE-NEW'
*            txt1  = 'The process for ZOVL_ARMS has been changed to include an alert & approval'
*            txt2  = 'process for possible Segregation of Duties Risk in roles of the user.'
*            txt3  = 'Documentation on the revised process is available in Process Guide Section as'
*            txt4  = ' " ZOVL_ARMS USER GUIDE-NEW. " '.



   ENDIF.
 ENDIF.
ENDIF.

ENDMODULE.                 " POP_MESSAGE  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  INIT_100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_100 OUTPUT.
IF manager IS INITIAL.
 obj-objtype = objtype.
 obj-objkey = 'ASY'.
 CREATE OBJECT manager
   EXPORTING
     ip_no_commit = 'R'
   EXCEPTIONS
     OTHERS       = 1.
ENDIF.
ENDMODULE.                 " INIT_100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_INIT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_init OUTPUT.
IF g_tablctrl118_copied IS INITIAL AND old_ok_code <> 'CREATE'.

 REFRESH g_tablctrl118_itab[].
 CLEAR   g_tablctrl118_itab.
*&spwizard: copy ddic-table 'ZIC_PREP_ROLEREI'
*&spwizard: into internal table 'g_TABLCTRL110_itab'
*Begin of <RD1K963151>.
 IF zic_prep_rolereq-docno IS NOT INITIAL.
*End of <RD1K963151>.
   SELECT * FROM zic_prep_rolerei
      INTO CORRESPONDING FIELDS
      OF TABLE g_tablctrl118_itab WHERE moduleid = 'SRM' AND
               docno = zic_prep_rolereq-docno ORDER BY PRIMARY KEY.
*Begin of <RD1K963151>.
 ENDIF.
*End of <RD1K963151>.
 g_tablctrl118_copied = 'X'.
 READ TABLE g_tablctrl118_itab INTO g_tablctrl118_wa INDEX 1.
 IF sy-subrc = 0.
   moduleid = g_tablctrl118_wa-moduleid.
 ENDIF.
 REFRESH CONTROL 'TABLCTRL118' FROM SCREEN '0118'.
ENDIF.
ENDMODULE.                 " TABLCTRL118_INIT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SCR118_COL_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr118_col_attrib OUTPUT.
LOOP AT tablctrl118-cols INTO cols WHERE index GT 11.
 cols-invisible = '1'.
 MODIFY tablctrl118-cols FROM cols INDEX sy-tabix.
ENDLOOP.

LOOP AT tablctrl118-cols INTO cols WHERE index = 12.
 cols-invisible = '0'.
 MODIFY tablctrl118-cols FROM cols INDEX sy-tabix.
ENDLOOP.
ENDMODULE.                 " SCR118_COL_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SCR118_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE scr118_attrib OUTPUT.
LOOP AT SCREEN.
 IF old_ok_code = 'APPROVE'.
   IF screen-name = 'TABLCTRL118_DELETE' OR
          screen-name = 'TABLCTRL118_INSERT' OR
          screen-name = 'COPY'.
     screen-input = 0.
     MODIFY SCREEN.
   ENDIF.
 ENDIF.
ENDLOOP.
ENDMODULE.                 " SCR118_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_MOVE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_move OUTPUT.
MOVE-CORRESPONDING g_tablctrl118_wa TO zic_prep_rolerei.

IF NOT zic_prep_rolerei-role_name IS INITIAL.
 zic_prep_rolerei-docno = zic_prep_rolereq-docno.


 SELECT SINGLE * FROM zsr_prep_roledes WHERE role_type =
             zic_prep_rolerei-role_name.
 IF sy-subrc = 0 .
   MOVE zsr_prep_roledes-brief_desc TO role_desc.
 ENDIF.


ENDIF.
ENDMODULE.                 " TABLCTRL118_MOVE  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_GET_LINES  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_get_lines OUTPUT.
g_tablctrl118_lines = sy-loopc.
ENDMODULE.                 " TABLCTRL118_GET_LINES  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_attrib OUTPUT.
IF old_ok_code <> 'DISPLAY' AND old_ok_code <> ''.


 SELECT SINGLE * FROM zsr_prep_roledes WHERE role_type =
                                           g_tablctrl118_wa-role_name.

 IF sy-subrc = 0.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

       IF old_ok_code <> 'APPROVE'.
         screen-input = 1.
       ELSE.
         screen-input = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-REJ_FL' AND
       old_ok_code = 'APPROVE' AND zic_prep_rolerei-rej_fl_save = ''.
       screen-input = 1.
       MODIFY SCREEN.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' .

       IF zsr_prep_roledes-plant = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-GRP'.

       IF zsr_prep_roledes-p_grp = 'X' AND
                     old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER'.

       IF zsr_prep_roledes-app_level = 'X' AND
                   old_ok_code <> 'APPROVE'.
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

*Begin of <RD1K962817>.
*          IF SCREEN-NAME = 'ZIC_PREP_ROLEREI-APPROVER'.
*            IF G_TABLCTRL118_WA-ROLE_NAME = 'M8'.
*              IF ZSR_PREP_ROLEDES-APP_LEVEL = 'X' AND
*                          OLD_OK_CODE <> 'APPROVE'.
*
*                SCREEN-INPUT = 0.
*
*                MODIFY SCREEN.
*              ELSE.
*                SCREEN-INPUT = 0.
*                MODIFY SCREEN.
*              ENDIF.
*
*            ENDIF.
*          ENDIF.
*End of <RD1K962817>.
     IF screen-name = 'ZIC_PREP_ROLEREI-SLOC'.

       IF zsr_prep_roledes-s_loc = 'X' AND
                 old_ok_code <> 'APPROVE'.
         .
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.
     ENDIF.

     IF screen-name = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.

       IF zsr_prep_roledes-r_loc = 'X' AND
                 old_ok_code <> 'APPROVE'.
         .
         screen-input = 1.
         MODIFY SCREEN.
       ELSE.
         screen-input = 0.
         MODIFY SCREEN.
       ENDIF.

     ENDIF.

   ENDLOOP.

 ELSE.

   LOOP AT SCREEN.

     IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND
                    NOT old_ok_code IS INITIAL AND
                    old_ok_code <> 'APPROVE'.
       screen-input = 1.
       MODIFY SCREEN.
       IF NOT zic_prep_rolerei-role_name IS INITIAL .
         MESSAGE i115(zhelp) WITH zic_prep_rolerei-role_name.
       ENDIF.
     ELSE.
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.

   ENDLOOP.

 ENDIF.

*    ELSE.



*    ENDIF.

ELSE.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
*
 ENDLOOP.
*

ENDIF.

LOOP AT SCREEN.

 IF zic_prep_rolerei-rej_fl <> ''.
   screen-input = 0.
   MODIFY SCREEN.
 ENDIF.

ENDLOOP.


**************************************************************
IF old_ok_code = 'DELETE'.

 LOOP AT SCREEN.
   screen-input = 0.
   MODIFY SCREEN.
 ENDLOOP.

ENDIF.
ENDMODULE.                 " TABLCTRL118_ATTRIB  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_CURSOR_118  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_cursor_118 OUTPUT.
DESCRIBE TABLE g_tablctrl118_itab LINES tablctrl118-lines.

IF NOT g_field IS INITIAL.
 SET CURSOR FIELD g_field LINE g_i.
 CLEAR g_field.
ELSE.
 SET CURSOR FIELD 'ZIC_PREP_ROLEREI-ROLE_NAME' LINE g_curr_line_118
.
ENDIF.
CLEAR sy-ucomm.

ENDMODULE.                 " SET_CURSOR_118  OUTPUT
