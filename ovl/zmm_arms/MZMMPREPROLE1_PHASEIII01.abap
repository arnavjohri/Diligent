*----------------------------------------------------------------------*
*   INCLUDE MZMMPREPROLEI01                                            *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
************************************************************************
*  Date            Transport      USERID        Description
* 30/04/2009      <RD1K963151>    SAB_SUMODH
* CR No. 30012322  RD1K996279 CAB_SUDHIR
*
*1)Change in Line 630.
* 23/09/2014     <RD1K994398>     CAB_LIPSY    Changes made as per     *
*                                              CR 30011628
*                                              (BUKRS added in zmm_location,
*                                              MESSAGE zhelp 091)
* 19.03.2015   <RD1K996555>  CAB_SPYADAV   CR 30012482(LIPSY)          *
*                                          (Simultaneous assignment of *
*                                           cross company ,multi module
*                                           roles,during approval      *
"                                          ,SRM Module introductin)    *
*&                                                                     *
*&                                                                     *
************************************************************************
MODULE user_command_0100 INPUT.

  okcode = sy-ucomm.

  CASE okcode.

    WHEN 'BAC' OR 'CAN'.

      PERFORM bac_confirm.
*      refresh control 'TABCTRL100' from screen '0100'.
      CLEAR okcode.
      LEAVE PROGRAM.

    WHEN 'CREATE'.

      g_mode = 'CRE'.
      CLEAR okcode.

    WHEN 'CHANGE'.

      g_mode = 'CHA'.
      CLEAR okcode.

    WHEN 'DISPLAY'.

      g_mode = 'DIS'.
      CLEAR okcode.

    WHEN 'DELETE'.

      g_mode = 'DEL'.
      CLEAR okcode.

    WHEN 'SAVE'.

*        perform check_items.
*        Perform Check_dupl_rec1.
      .
*        Perform Save_request.

      CLEAR okcode.

    WHEN 'RELEASE'.

      g_mode = 'REL'.
      CLEAR okcode.

    WHEN 'APPROVE'.

      g_mode = 'APR'.
      CLEAR okcode.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT

*&spwizard: input module for tc 'TABCTRL100'. do not change this line!
*&spwizard: modify table
MODULE tabctrl100_modify INPUT.

  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tabctrl100_wa.

*  if old_ok_code = 'CRCROLES' or  ZIC_PREP_ROLEREQ-CRC_FL = 'X'.
*
*  else.

  SELECT SINGLE * FROM zmm_prep_rolegrp WHERE role_type =
                  zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

*  endif.

  IF zic_prep_rolerei-rej_fl = ''.

    IF sy-subrc = 0 AND old_ok_code = 'APPROVE'.
      IF zmm_prep_rolegrp-approver1 = g_user
         OR zmm_prep_rolegrp-approver2 = g_user
         OR zmm_prep_rolegrp-approver3 = g_user
     """""""""""""""
       "added by lipsy for l2 approver on 20.03.2015 RD1K996555
            OR ( moduleid = 'SRM' AND zmm_prep_rolegrp-approver1 = g_user_l2 )
      "end of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
     """""""""
        .
      ELSE.

        IF okcode_100 = 'SAV'.
          IF err_flg <> 'X'.
            err_flg = 'X'.
            CLEAR : sy-ucomm, okcode_100.
          ENDIF.
          MESSAGE e047(zhelp) WITH zmm_prep_rolegrp-role_type.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

  IF NOT g_tabctrl100_wa-role_name IS INITIAL.
**
    IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'.
      SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
 WHERE ROLE_TYPE =
 ZIC_PREP_ROLEREI-ROLE_NAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      IF sy-subrc = 0.
*        g_srno = g_srno + 1.
        g_tabctrl100_wa-role_desc = zmm_prep_rolecrc-brief_desc.
*        g_TABCTRL100_wa-srno = g_srno.
      ENDIF.
    ELSE.
      SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
      IF sy-subrc = 0.
*        g_srno = g_srno + 1.
        g_tabctrl100_wa-role_desc = zmm_prep_roledes-brief_desc.
*        g_TABCTRL100_wa-srno = g_srno.
      ENDIF.

    ENDIF.
**
  ENDIF.
  MODIFY g_tabctrl100_itab
    FROM g_tabctrl100_wa
    INDEX tabctrl100-current_line.

  IF sy-subrc <> 0.
    APPEND g_tabctrl100_wa TO g_tabctrl100_itab.
  ENDIF.

  IF g_tabctrl100_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tabctrl100_wa-flag.
    APPEND g_tabctrl100_wa TO g_tabctrl100_itab.
  ENDIF.

ENDMODULE.                    "TABCTRL100_modify INPUT

*&spwizard: input module for tc 'TABCTRL100'. do not change this line!
*&spwizard: mark table
MODULE tabctrl100_mark INPUT.
  IF tabctrl100-line_sel_mode = 1 AND
     g_tabctrl100_wa-flag = 'X'.
    LOOP AT g_tabctrl100_itab INTO g_tabctrl100_wa
      WHERE flag = 'X'.
      g_tabctrl100_wa-flag = ''.
      MODIFY g_tabctrl100_itab
        FROM g_tabctrl100_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tabctrl100_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tabctrl100_itab
    FROM g_tabctrl100_wa
    INDEX tabctrl100-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABCTRL100_mark INPUT

*&spwizard: input module for tc 'TABCTRL100'. do not change this line!
*&spwizard: process user command
MODULE tabctrl100_user_command INPUT.
**  OKCODE = sy-ucomm.
**  perform user_ok_tc using    'TABCTRL100'
**                              'G_TABCTRL100_ITAB'
**                              'FLAG'
**                     changing OKCODE.
**  sy-ucomm = OKCODE.
ENDMODULE.                    "TABCTRL100_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_PLANT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_plant INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


  DATA  :  ist_return_tab LIKE STANDARD TABLE OF ddshretval
                                               WITH  HEADER LINE.
*  TYPES :
*    BEGIN OF ty_bukrs,
*      werks LIKE zd_t001w_bukrs-werks,
*      name1 LIKE zd_t001w_bukrs-name1,
*    END OF ty_bukrs.
*
*  DATA   : it_bukrs TYPE TABLE OF ty_bukrs WITH HEADER LINE.

  SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
             TABLE it_bukrs ."""""" WHERE bukrs =  zic_prep_rolereq-ccode.    """ Commented By Suresh 23.01.2017

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'WERKS'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-PLANT'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_bukrs
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_bukrs,ist_return_tab.
  FREE : it_bukrs,ist_return_tab.

ENDMODULE.                 " POV_PLANT  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_GRP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_grp INPUT.

  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.

*    CONCATENATE '000'  zic_prep_rolereq-userid INTO cpf_lfb1.
    cpf_lfb1 = zic_prep_rolereq-userid.

**---------- Changes Start date 24.06.2016 11:57:21-------------------
*SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
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


    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                   a~persk a~sbmod  c~designo c~r_p_cd c~version
                 d~sdesig_text AS designation d~adesig_text AS adesignation
                 d~disc_cd AS disc_cd
                   INTO CORRESPONDING FIELDS OF TABLE ist_data
              FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                    ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                       ON c~designo = d~desig_code AND
                           c~r_p_cd  = d~r_p_cd AND
                           c~version = d~version )
                        WHERE a~pernr =  zic_prep_rolereq-userid AND
                              a~sprps = ' ' AND
                              a~endda = '99991231' AND
                              c~sprps = ' ' AND
                              c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:57:21-----------------


    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER

***START OF COMMENT <RD1K983325>   CR: 30007580  dt: 05.04.2013.
*      g_ccode = ist_data-bukrs.
***end OF COMMENT <RD1K983325>.

**code added by CAB_AMITMOZA  <RD1K983325>   CR: 30007580  dt: 05.04.2013.
      g_ccode =  zic_prep_rolereq-ccode.
**code end by CAB_AMITMOZA  <RD1K983325>

    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-GRP' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  DATA : l_ekgrp LIKE t024-ekgrp.
  DATA : loop_step LIKE sy-stepl.
  DATA : l_role_name LIKE zic_prep_rolerei-role_name.

  DATA l_disc_mm_flag LIKE zic_prep_rolereq-disc_mm_flag.

*  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
*       EXPORTING
*            STRUC = 'ZIC_PREP_ROLEREQ'
*            FIELD = 'DISC_MM_FLAG'
*            REPID = SY-CPROG
*            DYNNR = '0100'
*       IMPORTING
*            VALUE = l_disc_mm_flag.
*
*  ZIC_PREP_ROLEREQ-DISC_MM_FLAG = l_disc_mm_flag.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_role_name.

  IF l_role_name = 'M6' OR  l_role_name = 'M7' OR
     l_role_name = 'M8'.
    CONCATENATE '%' g_ccode '%' INTO g_line1.
    SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.

  ELSE.
    IF zic_prep_rolereq-disc_mm_flag <> 'X'.
*      concatenate '%' G_CCODE '-' 'IND' '%'
*      into g_line1.
      CONCATENATE '%' g_ccode '%' 'IND' '%'
      INTO g_line1.
      SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
    ELSE.
*      concatenate  '%' G_CCODE '-' 'MM' '%'
*      into g_line1.
      CONCATENATE  '%' g_ccode '%' 'MM' '%'
      INTO g_line1.
      SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
    ENDIF.
  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'T024'.
  g_field_wa-fieldname = 'EKGRP'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T024'.
  g_field_wa-fieldname = 'EKNAM'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'EKGRP'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-GRP'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_t024
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_t024,ist_return_tab, g_field_tab.
  FREE : it_t024,ist_return_tab, g_field_tab.
  CLEAR g_field_wa.

ENDMODULE.                 " POV_GRP  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  TYPES : BEGIN OF z_role_des,
            role_type    LIKE zmm_prep_roledes-role_type,
            brief_desc   LIKE zmm_prep_roledes-brief_desc,
            detail_desc1 LIKE zmm_prep_roledes-detail_desc1,
            detail_desc2 LIKE zmm_prep_roledes-detail_desc2,
            sort_field   LIKE zmm_prep_roledes-brief_desc,
            mm_disc_flag LIKE zmm_prep_roledes-mm_disc_flag,
          END OF z_role_des.

*  DATA   : it_role type table of zmm_prep_roledes with header line.
  DATA   : it_role TYPE TABLE OF z_role_des WITH HEADER LINE.

  IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'.

    SELECT * FROM zmm_prep_rolecrc INTO CORRESPONDING FIELDS OF
               TABLE it_role WHERE status = 'active'.

  ELSE.

    SELECT * FROM zmm_prep_roledes INTO CORRESPONDING FIELDS OF
               TABLE it_role.

  ENDIF.
  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZMM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
*Begin of <RD1K962817>.
*  g_field_wa-tabname = 'ZMM_PREP_ROLEDES'.
*  g_field_wa-fieldname = 'DETAIL_DESC2'.
*  APPEND g_field_wa TO g_field_tab.
*End of <RD1K962817>.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_ROLE  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_header_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_header_data INPUT.

  IF old_ok_code = 'DISPLAY' OR old_ok_code = 'CHANGE' OR
        old_ok_code = 'DELETE' OR old_ok_code = 'CREATE' OR
        old_ok_code = 'CROSSCO' OR ( old_ok_code = 'CRCROLES' )
        OR old_ok_code = 'RELEASE' OR ( old_ok_code = 'APPROVE' ).

    IF NOT  zic_prep_rolereq-userid IS INITIAL.
******* Start of Changes :  Changes done by Bipin shukla (SAB_BIPIN ) on 27/11/2013

      """"""""""""""""""""""""""""

      "comment by lipsy on 24.03.2015 RD1K996555
*      IF OLD_OK_CODE = 'CREATE'.
      "end of comment by lipsy on 24.03.2015 RD1K996555
      """"""""""""""""""""""""""""""""

      """""""""""""""""""""""""""""""""""
      "added by lipsy  for approver on  24.03.2015 RD1K996555
      IF old_ok_code = 'CREATE' OR old_ok_code = 'CROSSCO'.
        "end of addition by lipsy  for approver on  24.03.2015 RD1K996555
        """""""""""""""""""""""""""""""""



        CLEAR gt_role_usr[].

        SELECT * FROM agr_users INTO CORRESPONDING FIELDS OF TABLE gt_role_usr
*BOC By SAP_ABAP on 26/10/26
*         WHERE agr_name = 'M:COMMON_USER_TOOLS' AND
* Role renamed on S/4 (mail from Uday Mahato, SAP, 09/10/26):
*   'M:COMMON_USER_TOOLS' -> 'Z:S:BS:GENERAL_ACCESS:M:ALL'
          WHERE agr_name = 'Z:S:BS:GENERAL_ACCESS:M:ALL' AND
*EOC By SAP_ABAP on 26/10/26
                uname = zic_prep_rolereq-userid.

        IF gt_role_usr[] IS INITIAL.
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "commented by lipsy on 17.09.2014 for using message class zhelp  RD1K994398

*          MESSAGE 'User is  currently  not an SAP user. Kindly contact  ICE Team' TYPE 'E'.
          "end of  comment by lipsy on 17.09.2014 for using message class zhelp  RD1K994398

          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          """"""""""""""""""""""""""""""""""""""""""""""""""
          "added by lipsy  for srm module introduction ON 12.03.2015 RD1K996555
          IF  moduleid = 'SRM'.

          ELSE.
            "end of addition by lipsy  for srm module introduction ON 12.03.2015 RD1K996555
            """"""""""""""""""""""""""""""""""""""""""""""""

            "added by lipsy on 17.09.2014 for using message class zhelp  RD1K994398

            MESSAGE e091(zhelp) WITH zic_prep_rolereq-userid.

            "end of  addition by lipsy on 17.09.2014 for using message class zhelp  RD1K994398


            """"""""""""""""""""""""""""""""""""
            "added by lipsy  for srm module introduction ON 12.03.2015 RD1K996555

          ENDIF.
          "end of addition by lipsy  for srm module introduction ON 12.03.2015 RD1K996555
          """"""""""""""""""""""""""""""""""""""""

          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

        ENDIF.

      ENDIF.

******* End of changes : Changes done by Bipin shukla (SAB_BIPIN ) on 27/11/2013
***CODE ADDED BY CAB_AMITMOZA  CR:30007580  WR:RD1K983325
      SELECT * FROM  zpa9205 APPENDING
      CORRESPONDING FIELDS OF TABLE it_9205
      WHERE pernr = zic_prep_rolereq-userid AND
            subty = '01' AND
            endda = '99991231' .
*      clear ZIC_PREP_ROLEREQ-TELNO.
      IF sy-subrc = 0.          "" It means PHONE NO. OF REQUIRED T&S EXECUTIVE HAS BEEN FOUND
        SORT  it_9205 BY begda DESCENDING  .
        READ TABLE it_9205 INTO wa_9205 INDEX 1  .  "#EC CI_NOORDER
        CONCATENATE '91' wa_9205-zphone+1(10) INTO  zic_prep_rolereq-telno .
*else.
*  LOOP AT SCREEN.
*
*  if screen-name = 'ZIC_PREP_ROLEREQ-TELNO ' .
*  screen-group1 = 'GP1'.
*          MODIFY SCREEN.
*        ENDIF.
*      ENDLOOP.

      ENDIF.

***CODE END BY CAB_AMITMOZA  CR:30007580
**COMMENT DONE BY CAB_AMITMOZA  CR:30007580  WR:RD1K983325
*      PERFORM check_tel.
**COMMENT END BY CAB_AMITMOZA  CR:30007580

    ENDIF.

    IF old_ok_code = 'CREATE' OR old_ok_code = 'CROSSCO' OR
       old_ok_code = 'CRCROLES'.

      IF  zic_prep_rolereq-persa IS INITIAL AND
          zic_prep_rolereq-rsn_code = '01'.
        PERFORM pop_up_message.
      ENDIF.

      IF  zic_prep_rolereq-userid IS INITIAL.
        MESSAGE e035(zhelp).
      ENDIF.

      IF  zic_prep_rolereq-userid <> old_userid AND
        old_userid <> ''.
        CLEAR  zic_prep_rolereq-disc_mm_flag.
        CLEAR  zic_prep_rolereq-ccode.
        CLEAR  zic_prep_rolereq-fundc1.
        CLEAR  zic_prep_rolereq-fundc.
        CLEAR  zic_prep_rolereq-s_desc.
        CLEAR  zic_prep_rolereq-rsn_code.
        CLEAR  zic_prep_rolereq-rsn_text1.
        CLEAR  zic_prep_rolereq-reason1.
        CLEAR  zic_prep_rolereq-telno.
        CLEAR  zic_prep_rolereq-name.
        CLEAR  zic_prep_rolereq-designation.
        CLEAR set_disc_mm_flag.
        CLEAR set_disc_fi_flag.
        CLEAR help_list_flag.
        REFRESH it_m_fistb.
        CLEAR wa_m_fistb.
      ENDIF.

*        select single * from zusrmst where cpfno =
*                                    ZIC_PREP_ROLEREQ-userid.

      SELECT SINGLE * FROM usr02 WHERE bname =
                                  zic_prep_rolereq-userid.

      IF sy-subrc NE 0.
        MESSAGE e043(zhelp).
      ELSE.
*          concatenate zusrmst-first_name zusrmst-last_name into
*          zusrmst-last_name.
*           ZIC_PREP_ROLEREQ-name = zusrmst-last_name.
*           ZIC_PREP_ROLEREQ-designation = zusrmst-designation.

*Begin of <RD1K964434>.
        DATA : l_date TYPE datum.
        MOVE sy-datum TO l_date.
*End of <RD1K964434>.

**---------- Changes Start date 24.06.2016 11:56:49-------------------
*        SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*             A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*           D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*           D~DISC_CD AS DISC_CD
*             INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*        FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*              ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*                 ON C~DESIGNO = D~DESIG_CODE AND
*                     C~R_P_CD  = D~R_P_CD AND
*                     C~VERSION = D~VERSION )
*                  WHERE A~PERNR =  ZIC_PREP_ROLEREQ-USERID AND
*                        A~SPRPS = ' ' AND
**Begin of <RD1K964434>.
**                        a~endda = '99991231' AND
*                         A~ENDDA GE L_DATE AND
**End of <RD1K964434>.
*                         C~SPRPS = ' ' AND
**Begin of <RD1K964434>.
**                        c~endda = '99991231' .
*                         C~ENDDA GE L_DATE .

        SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
             a~persk a~sbmod  c~designo c~r_p_cd c~version
           d~sdesig_text AS designation d~adesig_text AS adesignation
           d~disc_cd AS disc_cd
             INTO CORRESPONDING FIELDS OF TABLE ist_data
        FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
              ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                 ON c~designo = d~desig_code AND
                     c~r_p_cd  = d~r_p_cd AND
                     c~version = d~version )
                  WHERE a~pernr =  zic_prep_rolereq-userid AND
                        a~sprps = ' ' AND
*Begin of <RD1K964434>.
*                        a~endda = '99991231' AND
                         a~endda GE l_date AND
*End of <RD1K964434>.
                         c~sprps = ' ' AND
*Begin of <RD1K964434>.
*                        c~endda = '99991231' .
                         c~endda GE l_date .
**---------- Changee  Ending Date 24.06.2016 11:56:49-----------------
*End of <RD1K964434>.

*Begin of <RD1K964434>.
        DATA : l_count TYPE i.
        DESCRIBE TABLE ist_data[] LINES l_count.
*End of <RD1K964434>.

        IF sy-subrc = 0.
          READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
          zic_prep_rolereq-name = ist_data-name.
          zic_prep_rolereq-designation = ist_data-designation.
*Begin of <RD1K962817>.
          zic_prep_rolereq-persk = ist_data-persk.
*End of <RD1K962817>.
          IF ist_data-disc_cd = '36' AND set_disc_mm_flag <> 'X'.
            zic_prep_rolereq-disc_mm_flag = 'X'.
            set_disc_mm_flag = 'X'.
          ENDIF.
          IF ist_data-disc_cd = '13' AND set_disc_fi_flag <> 'X'.
            zic_prep_rolereq-disc_fi_flag = 'X'.
            set_disc_fi_flag = 'X'.
          ENDIF.
***************************************************31.05.2006
          IF old_ok_code = 'CREATE' OR old_ok_code = 'CRCROLES'.
            zic_prep_rolereq-ccode = ist_data-bukrs.
          ELSE.
            g_ccode_crossco        = ist_data-bukrs.
          ENDIF.
          IF old_ok_code = 'APPROVE'.
            g_ccode_crossco        = ist_data-bukrs.
          ENDIF.
***************************************************31.05.2006
*            if ist_data-disc_cd = '36' and
*             ZIC_PREP_ROLEREQ-disc_mm_flag <> old_disc_mm_flag.
*                 ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
*            endif.

          IF old_ok_code = 'CREATE'.
            IF  zic_prep_rolereq-persa <> ist_data-werks AND
               NOT  zic_prep_rolereq-persa IS INITIAL.
              MESSAGE e108(zhelp).
            ENDIF.
          ENDIF.

        ENDIF.

*Begin of <RD1K962817>.
*if zic_prep_rolereq-persk < 'E4'.
*  MESSAGE i803(zmm) with text-003.
*  LEAVE PROGRAM.
*  endif.
*End of <RD1K962817>.
        CLEAR : ist_data.
        REFRESH : ist_data.

** Change company code, fund centre, costcentre logic 02.02.2006

* Begin of <RD1K981840>
*        CONCATENATE '000'  zic_prep_rolereq-userid INTO cpf_lfb1.
        cpf_lfb1 = zic_prep_rolereq-userid.
* End of <RD1K981840>

*          select single * from lfb1 where lifnr = cpf_lfb1.

* Select Company-KBU01, Cost Centre-kst01
* from pa0027  .
        CLEAR wa_pa0027.

**---------- Changes Start date 24.06.2016 12:12:14-------------------

*        SELECT SINGLE *
*           FROM PA0027
*           INTO WA_PA0027
*           WHERE PERNR = CPF_LFB1 AND
*                 ENDDA = '99991231' AND
*                 SPRPS = ' ' . " SPRPS - Lock Indicator 'X'

        SELECT *
 FROM ZPA0027 INTO WA_PA0027 UP TO 1 ROWS WHERE PERNR = CPF_LFB1 AND ENDDA = '99991231' AND SPRPS = ' '
 ORDER BY PRIMARY KEY .
 ENDSELECT. " SPRPS - Lock Indicator 'X'
**---------- Changee  Ending Date 24.06.2016 12:12:14-----------------

        IF sy-subrc = 0.
*Begin of <RD1K963151>.
*          IF old_ok_code <> 'CROSSCO'.
*End of <RD1K963151>.
          CONCATENATE  '''' '%' wa_pa0027-kst01
                       '''' INTO  g_line1.
          CONCATENATE  'OBJNR'  'LIKE' g_line1 INTO g_line1
          SEPARATED BY space.
          REFRESH :  it_cond.
          APPEND g_line1 TO it_cond.
          SELECT * FROM FMZUOB UP TO 1 ROWS
 WHERE (IT_COND)
 ORDER BY PRIMARY KEY .
 ENDSELECT.
*Begin of <RD1K963151>.
*          ENDIF.
*End of <RD1K963151>.
          IF sy-subrc = 0.
*Begin of <RD1K963151>.
* IF old_ok_code = 'CREATE' OR old_ok_code = 'CRCROLES' .
            IF old_ok_code = 'CREATE' OR old_ok_code = 'CRCROLES' OR old_ok_code = 'CROSSCO'.
*End of <RD1K963151>.
              zic_prep_rolereq-fundc1 = fmzuob-fistl.
              zic_prep_rolereq-fundc_fl = 'X'.
*               ZIC_PREP_ROLEREQ-CCODE = wa_pa0027-kbu01+0(3).
              zic_prep_rolereq-costc = wa_pa0027-kst01.
            ELSE.
*              G_CCODE_CROSSCO        = wa_pa0027-kbu01+0(3).
              zic_prep_rolereq-costc = wa_pa0027-kst01.
            ENDIF.

            SELECT * FROM CSKT UP TO 1 ROWS
 WHERE
 KOSTL = ZIC_PREP_ROLEREQ-COSTC
 ORDER BY PRIMARY KEY .
 ENDSELECT.

            IF sy-subrc =  0.
              zic_prep_rolereq-s_desc = cskt-ltext.
            ENDIF.

            REFRESH it_cond[].
            CLEAR it_cond.
          ELSE.
          ENDIF.
        ENDIF.

      ENDIF.

    ELSE.

***************************************************

      IF  zic_prep_rolereq-docno IS INITIAL.
        MESSAGE e041(zhelp).
      ENDIF.

    ENDIF.

**********************************************************nn

    SELECT SINGLE * FROM usr02 WHERE bname =
                                   zic_prep_rolereq-userid.

    IF sy-subrc NE 0.
    ELSE.
**   **---------- Changes Start date 24.06.2016 11:56:05-------------------

*   SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
*           A~PERSK A~SBMOD  C~DESIGNO C~R_P_CD C~VERSION
*         D~SDESIG_TEXT AS DESIGNATION D~ADESIG_TEXT AS ADESIGNATION
*         D~DISC_CD AS DISC_CD
*           INTO CORRESPONDING FIELDS OF TABLE IST_DATA
*      FROM ( ( PA0001 AS A INNER JOIN PA9930 AS C
*            ON A~PERNR = C~PERNR ) INNER JOIN ZDESIGNATION_REV AS D
*               ON C~DESIGNO = D~DESIG_CODE AND
*                   C~R_P_CD  = D~R_P_CD AND
*                   C~VERSION = D~VERSION )
*                WHERE A~PERNR =  ZIC_PREP_ROLEREQ-USERID AND
*                      A~SPRPS = ' ' AND
*                      A~ENDDA = '99991231' AND
*                      C~SPRPS = ' ' AND
*                      C~ENDDA = '99991231' .


      SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
              a~persk a~sbmod  c~designo c~r_p_cd c~version
            d~sdesig_text AS designation d~adesig_text AS adesignation
            d~disc_cd AS disc_cd
              INTO CORRESPONDING FIELDS OF TABLE ist_data
         FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
               ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                  ON c~designo = d~desig_code AND
                      c~r_p_cd  = d~r_p_cd AND
                      c~version = d~version )
                   WHERE a~pernr =  zic_prep_rolereq-userid AND
                         a~sprps = ' ' AND
                         a~endda = '99991231' AND
                         c~sprps = ' ' AND
                         c~endda = '99991231' .
***   *---------- Changee  Ending Date 24.06.2016 11:56:05-----------------

      IF sy-subrc = 0 AND zic_prep_rolereq-crossco_fl = 'X'.
        READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
        IF old_ok_code = 'APPROVE'.
          g_ccode_crossco        = ist_data-bukrs.
        ENDIF.
      ENDIF.
    ENDIF.
********************************************************nn
  ENDIF.


ENDMODULE.                 " validate_header_data  INPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_100 INPUT.

  IF moduleid = 'FI' .
    PERFORM call_fi.
  ENDIF.

  """""""""""
  " addition by lipsy  for srm module introduction on 17.03.2015 RD1K996555
  IF moduleid = 'SRM' .
    CLEAR:sy-ucomm.
  ENDIF.
  "end of addition by lipsy  for srm module introduction on 17.03.2015 RD1K996555
  """"""""""""""
* Start of Changes by CAB_DAV to Integrate ZHRARMS with ZICE_ARMS
* Date : 22-04-2008.

  IF moduleid = 'HR' .
    AUTHORITY-CHECK OBJECT 'ZHR_ARMS'
                     ID 'ZTCODE' FIELD 'ZHRARMS'.
    IF sy-subrc = 0.
      PERFORM call_hr.
    ELSE.
      MESSAGE e231(zhelp).
    ENDIF.

  ENDIF.

* End of Changes by CAB_DAV to Integrate ZHRARMS with ZICE_ARMS.

  CASE okcode_100.

    WHEN 'BAC' OR 'CAN'.
      PERFORM exit_confirm.
    WHEN 'EXT'.
      LEAVE PROGRAM.

    WHEN 'CREATE'.

      old_ok_code = okcode_100.
      moduleid = 'MM'.

    WHEN 'CHANGE'.

      old_ok_code = okcode_100.

    WHEN 'RELEASE'.

      old_ok_code = okcode_100.


    WHEN 'APPROVE'.

      old_ok_code = okcode_100.

    WHEN 'COPY'.


    WHEN 'DISPLAY'.

      old_ok_code = okcode_100.

    WHEN 'ROLE_DEL'.

      old_ok_code = okcode_100.

    WHEN 'SAV'.
*Begin of <RD1K962817>.
      DATA : lv_ol    TYPE char2,
             lv_ne    TYPE char2,
             l_ans(1) TYPE c.

******** Start of Changes :  Changes done by Bipin shukla (SAB_BIPIN ) on 27/11/2013
*
*      IF OLD_OK_CODE = 'CREATE'.
*
*        CLEAR GT_ROLE_USR[].
*
*        SELECT * FROM AGR_USERS INTO CORRESPONDING FIELDS OF TABLE GT_ROLE_USR
*          WHERE AGR_NAME = 'M:COMMON_USER_TOOLS' AND
*                UNAME = ZIC_PREP_ROLEREQ-USERID.
*
*        IF GT_ROLE_USR[] IS INITIAL.
*
*          MESSAGE 'You are not authorized to created the request for the user.' TYPE 'E'.
*
*        ENDIF.
*
*      ENDIF.
*
******** End of changes : Changes done by Bipin shukla (SAB_BIPIN ) on 27/11/2013

       perform check_plant_grp.

      READ TABLE ist_return_tab3 WITH KEY fieldname = 'MIN_DESIGNATION'.
      lv_ne = ist_return_tab3-fieldvalue.
      lv_ol = zic_prep_rolereq-persk.

      IF lv_ne > lv_ol.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            text_question         = text-002
            text_button_1         = 'Agree'
            text_button_2         = 'Cancel'
            default_button        = ' '
            start_column          = 25
            start_row             = 6
            display_cancel_button = ' '
          IMPORTING
            answer                = l_ans
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.

        IF l_ans = 1.
*          IF LV_NE < LV_OL.
*End of <RD1K962817>.

          IF old_ok_code = 'DELETE'.

            IF  zic_prep_rolereq-useridcr = sy-uname.

*            if  ZIC_PREP_ROLEREQ-STATUS = 'N' or  " 30/05/2006

              IF  zic_prep_rolereq-status = ''.
                PERFORM delete_request.
              ELSE.
                MESSAGE e138(zhelp).
              ENDIF.
            ELSE.
              MESSAGE e056(zhelp).
            ENDIF.
          ELSE.
*        describe table g_TABLCTRL110_itab lines g_lines_rl.
*        if g_lines_rl = 0.
*           clear okcode_100.
*           message i140(zhelp).
*        else.
*** cab_ajit 24/04/2007
            IF old_ok_code = 'RELEASE' AND
                   zic_prep_rolereq-req_cr_fl = 'X'.
              PERFORM confirm_rel.
              IF g_choice_rel <> 'J'.
                CLEAR g_choice_rel.
                PERFORM clear.
                CLEAR old_ok_code.
                dynnr = '0101'.
                CALL SCREEN 100.
              ENDIF.
            ENDIF.
***
            IF old_ok_code = 'RELEASE' AND
                   zic_prep_rolereq-req_cr_fl <> 'X'.
              MESSAGE i083(zhelp).

            ELSEIF old_ok_code = 'RELEASE' AND g_lines_rl = 0.
              MESSAGE i089(zhelp).

            ELSEIF old_ok_code = 'APPROVE' AND
                   (  zic_prep_rolereq-req_app_fl <> 'X' AND
                   zic_prep_rolereq-req_app0_fl <> 'X' AND
                   zic_prep_rolereq-req_app1_fl <> 'X' ).
**13/04/07
              IF module_changed_flag <> 'X'.
                MESSAGE i087(zhelp).
              ELSE.
                PERFORM save_request.
              ENDIF.
            ELSEIF old_ok_code = 'APPROVE' AND  g_mult_module_fl = 'X'.
              SET PARAMETER ID 'ZROLEREQNOFORDETAILS'
                     FIELD zic_prep_rolereq-docno.
              CALL SCREEN 200 STARTING AT 10 15  ENDING AT 90 25.
              PERFORM confirm_app.
              IF g_choice_app = 'J'.
                CLEAR g_choice_app.
                IF moduleid <> 'MM'.
                  g_approver_level = 'L3'.
                ENDIF.
                PERFORM save_request.
              ENDIF.
            ELSE.
*          Perform check_items.
              IF moduleid <> 'MM'.
                g_approver_level = 'L3'.
              ENDIF.
              PERFORM save_request.
            ENDIF.
**       endif.
          ENDIF.
*          ENDIF.
*Begin of <RD1K962817>.

        ENDIF.
      ELSE.
        IF old_ok_code = 'DELETE'.

          IF  zic_prep_rolereq-useridcr = sy-uname.

*            if  ZIC_PREP_ROLEREQ-STATUS = 'N' or  " 30/05/2006

            IF  zic_prep_rolereq-status = ''.
              PERFORM delete_request.
            ELSE.
              MESSAGE e138(zhelp).
            ENDIF.
          ELSE.
            MESSAGE e056(zhelp).
          ENDIF.
        ELSE.
*        describe table g_TABLCTRL110_itab lines g_lines_rl.
*        if g_lines_rl = 0.
*           clear okcode_100.
*           message i140(zhelp).
*        else.
*** cab_ajit 24/04/2007
********************** CHANGES BY BIPIN : TO CHECK RISK AND COMMENT

          SELECT * FROM zgrc_sod_result INTO CORRESPONDING FIELDS OF TABLE gt_risk WHERE docno = zic_prep_rolereq-docno.

          IF gt_risk[] IS NOT INITIAL..
            DESCRIBE TABLE gt_risk LINES lv_rcount.
          ENDIF.

          SELECT * FROM zgrc_log INTO CORRESPONDING FIELDS OF TABLE gt_log WHERE docno = zic_prep_rolereq-docno.
          IF gt_log[] IS NOT INITIAL.
            READ TABLE gt_log INTO wa_log WITH KEY docno = zic_prep_rolereq-docno.
          ENDIF.

          IMPORT gt_text FROM MEMORY ID 'TABLE1'.
          IMPORT zice_ex FROM MEMORY ID 'ZICE_IM'.
*          DESCRIBE TABLE GT_RISK LINES LV_RCOUNT.
********************** CHANGES BY BIPIN : TO CHECK RISK AND COMMENT
*          IF OLD_OK_CODE = 'RELEASE' AND G_LINES_RL NE 0 . "AND GT_TEXT IS  NOT INITIAL.
*            FREE MEMORY ID 'TABLE1'."+ by vikas
*            FREE MEMORY ID 'ZICE_IM'.
**          ENDIF.
*          IF OLD_OK_CODE = 'RELEASE' AND
*            GT_RISK IS NOT INITIAL AND GT_TEXT IS INITIAL AND ZICE_EX NOT BETWEEN '1' AND '4'.
*            MESSAGE S233(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
*            ENDIF.
*          IF OLD_OK_CODE = 'RELEASE'.
*            DESCRIBE TABLE GT_RISK LINES LV_RISK.
*            IF LV_RISK EQ 1.
*              ZICE_EX = '1'.
*            ENDIF.
*          ENDIF.

*          ELSEIF OLD_OK_CODE = 'RELEASE' AND
*            GT_RISK IS NOT INITIAL AND GT_TEXT IS INITIAL AND ZICE_EX NOT BETWEEN '1' AND '4'.
*            MESSAGE S233(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.

          IF old_ok_code = 'RELEASE' AND
                   zic_prep_rolereq-req_cr_fl = 'X'.

            PERFORM confirm_rel.

            IF g_choice_rel <> 'J'.
              CLEAR g_choice_rel.
              PERFORM clear.
              CLEAR old_ok_code.
              dynnr = '0101'.
              CALL SCREEN 100.
*              ENDIF.
            ENDIF.
          ENDIF.
***
**************************************** Code for risk analysis before approve  : added by Bipin
*          IF OLD_OK_CODE = 'APPROVE' AND GT_TEXT IS INITIAL AND ZICE_EX NOT BETWEEN '1' AND '4'.
          IF old_ok_code = 'APPROVE' AND wa_log-app_fl_app NE 'A'.

            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "added by lipsy on 27.05.2015  RD1K997318

            IF moduleid = 'MM' OR moduleid = 'SRM'.

              IF zic_prep_rolereq-useridcr = sy-uname.


                CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT_LO'
                  EXPORTING
                    titel     = 'Approval Requirement'
                    textline1 = 'Approver cannot be same as creator'.



                LEAVE PROGRAM.

              ENDIF.


            ENDIF.


            "end of addition by lipsy on 27.05.2015  RD1K997318
            """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
******************************** CHECKING REJECTIONG LINE ITEM IN BUCKET
            CLEAR gt_bucket.
            IF moduleid = 'MM'.
              LOOP AT g_tablctrl110_itab INTO g_tablctrl110_wa.

                MOVE-CORRESPONDING g_tablctrl110_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.
            ELSEIF moduleid = 'SD'.
              LOOP AT g_tablctrl114_itab INTO g_tablctrl114_wa.

                MOVE-CORRESPONDING g_tablctrl114_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.
            ELSEIF moduleid = 'PP'.
              LOOP AT g_tablctrl113_itab INTO g_tablctrl113_wa.

                MOVE-CORRESPONDING g_tablctrl113_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.

            ELSEIF moduleid = 'PM'.
              LOOP AT g_tablctrl111_itab INTO g_tablctrl111_wa.

                MOVE-CORRESPONDING g_tablctrl111_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.

            ELSEIF moduleid = 'PS'.
              LOOP AT g_tablctrl112_itab INTO g_tablctrl112_wa.

                MOVE-CORRESPONDING g_tablctrl112_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.

            ELSEIF moduleid = 'HSE'.
              LOOP AT g_tablctrl116_itab INTO g_tablctrl116_wa.

                MOVE-CORRESPONDING g_tablctrl116_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.


            ELSEIF moduleid = 'QM'.
              LOOP AT g_tablctrl115_itab INTO g_tablctrl115_wa.

                MOVE-CORRESPONDING g_tablctrl115_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.

            ELSEIF moduleid = 'OLM'.
              LOOP AT g_tc_117_itab INTO g_tc_117_wa .

                MOVE-CORRESPONDING g_tc_117_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.

              """"""""""""""""""""""""""""""""""""""""""
              "addition by lipsy  for srm module introduction   on  3.03.2015 RD1K996555
            ELSEIF moduleid = 'SRM'.
              LOOP AT g_tablctrl118_itab INTO g_tablctrl118_wa.

                MOVE-CORRESPONDING g_tablctrl118_wa TO wa_bucket.
                wa_bucket-docno = reqnum_ex.
                APPEND wa_bucket TO gt_bucket.
*    CLEAR WA_BUCKET.
              ENDLOOP.

              "end of addition by lipsy  for srm module introduction   on  3.03.2015 RD1K996555

              """"""""""""""""""""""""""""""""""
            ENDIF.

            DELETE gt_bucket WHERE rej_fl = 'H'.
            DELETE gt_bucket WHERE rej_fl = 'B'.
            DELETE gt_bucket WHERE rej_fl = 'F'.
            DELETE gt_bucket WHERE rej_fl = 'I'.
            DELETE gt_bucket WHERE rej_fl = 'R'.
******************************** CHECKING REJECTIONG LINE ITEM IN BUCKET
*            IF GT_TEXT IS NOT INITIAL AND OLD_OK_CODE = 'APPROVE'. " BIPIN

            IF gt_bucket IS NOT INITIAL.
              IF lv_rcount GT 1.
                CLEAR : it_tvarv.
                SELECT * FROM tvarvc INTO CORRESPONDING FIELDS OF TABLE it_tvarv
                WHERE name = 'ZGRC_CALL'.
                IF it_tvarv[] IS NOT INITIAL.
                  READ TABLE it_tvarv INTO wa_tvarv WITH KEY name = 'ZGRC_CALL'.
                ENDIF.

                IF wa_tvarv-low IS NOT INITIAL.
                  lv_grccall = wa_tvarv-low.
                ENDIF.

                IF syst-sysid = 'RD1'.

                  lv7_rfc = 'GRDCLNT500'.

                ELSEIF syst-sysid = 'RQ1'.

                  lv7_rfc = 'GRDCLNT500'.

                ELSEIF syst-sysid = 'RP1'.

                  lv7_rfc = 'GRPCLNT500'.
                ENDIF.

                CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
                  EXPORTING
                    rfcdestination = lv7_rfc "'GRDCLNT500'
                  IMPORTING
                    rfc_subrc      = lv_subrc.

                IF  lv_grccall = 'X' AND lv_subrc = '0'.
*                  MESSAGE I232(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
                  CLEAR txt1.
                  CONCATENATE 'Risk Analysis in Progress for Doc.' zic_prep_rolereq-docno INTO txt1 SEPARATED BY space.
                  CALL FUNCTION 'POPUP_TO_INFORM'
                    EXPORTING
                      titel = 'Information'
                      txt1  = txt1
                      txt2  = 'To view the report, Pls press ENTER'.

                  reqnum_ex = zic_prep_rolereq-docno.
                  EXPORT reqnum_ex TO MEMORY ID 'REQNUM_IM'.

                  PERFORM grc_risk_analysis.
                  IMPORT gt_rdesc FROM MEMORY ID 'IM_GT_RDESC'.

                  IF gt_rdesc IS NOT INITIAL.
                    CALL TRANSACTION 'ZGRC_RESULT'.
                  ELSE.
                    MESSAGE 'No risk found.' TYPE 'I'.
                  ENDIF.
                  IMPORT oc_9001_rj FROM MEMORY ID 'OC_9001_IM'.
                  IF oc_9001_rj = 'REJECT'.
                    LEAVE PROGRAM.
                  ENDIF.

                  CLEAR reqnum_ex.
                  CLEAR oc_9001_rj.
                ENDIF.
              ENDIF.
            ELSE.
*              MESSAGE 'All role Rejected.' TYPE 'I'.

            ENDIF.
          ENDIF.

**************************************** Code for risk analysis before approve
          IF old_ok_code = 'RELEASE'.
            CLEAR gt_log.
            CLEAR wa_log.
*********************************CHECK GRC SYSTEM IS UP OR NOT
            CLEAR : it_tvarv.
            SELECT * FROM tvarvc INTO CORRESPONDING FIELDS OF TABLE it_tvarv
WHERE name = 'ZGRC_CALL'.
            IF it_tvarv[] IS NOT INITIAL.
              READ TABLE it_tvarv INTO wa_tvarv WITH KEY name = 'ZGRC_CALL'.
            ENDIF.
            IF wa_tvarv-low IS NOT INITIAL.
              lv_grccall = wa_tvarv-low.
            ENDIF.

            IF syst-sysid = 'RD1'.

              lv8_rfc = 'GRDCLNT500'.

            ELSEIF syst-sysid = 'RQ1'.

              lv8_rfc = 'GRDCLNT500'.

            ELSEIF syst-sysid = 'RP1'.

              lv8_rfc = 'GRPCLNT500'.
            ENDIF.

            CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
              EXPORTING
                rfcdestination = lv8_rfc "'GRDCLNT500'
              IMPORTING
                rfc_subrc      = lv_subrc.

*********************************CHECK GRC SYSTEM IS UP OR NOT

            SELECT * FROM zgrc_log INTO CORRESPONDING FIELDS OF TABLE gt_log WHERE docno = zic_prep_rolereq-docno
AND okcode IN ('CHANGE','CREATE','CROSSCO').
            IF gt_log[] IS NOT INITIAL.
              READ TABLE gt_log INTO wa_log WITH KEY docno = zic_prep_rolereq-docno.
            ENDIF.
            DESCRIBE TABLE gt_risk LINES lv_risk.
            IF lv_risk EQ 1.
              zice_ex = '1'.
            ENDIF.
          ENDIF.




          IF old_ok_code = 'RELEASE' AND
                 zic_prep_rolereq-req_cr_fl <> 'X'.
            MESSAGE i083(zhelp).



*          ELSEIF OLD_OK_CODE = 'RELEASE' AND
*     GT_RISK IS NOT INITIAL AND GT_TEXT IS INITIAL AND ZICE_EX NOT BETWEEN '1' AND '4'.
*            MESSAGE S233(ZHELP) WITH ZIC_PREP_ROLEREQ-DOCNO.
********************** CHANGES BY BIPIN : TO CHECK RISK AND COMMENT

          ELSEIF old_ok_code = 'RELEASE' AND wa_log-app_fl NE 'A' AND lv_risk GT 1 AND lv_grccall = 'X' AND lv_subrc = '0'.

*                 GT_RISK IS NOT INITIAL AND GT_TEXT IS INITIAL AND ZICE_EX NOT BETWEEN '1' AND '4'.

            MESSAGE e234(zhelp) WITH zic_prep_rolereq-docno.

********************** CHANGES BY BIPIN : TO CHECK RISK AND COMMENT

          ELSEIF old_ok_code = 'RELEASE' AND g_lines_rl = 0.
            MESSAGE i089(zhelp).

          ELSEIF old_ok_code = 'APPROVE' AND
                 (  zic_prep_rolereq-req_app_fl <> 'X' AND
                 zic_prep_rolereq-req_app0_fl <> 'X' AND
                 zic_prep_rolereq-req_app1_fl <> 'X' ).
**13/04/07
            IF module_changed_flag <> 'X'.
              MESSAGE i087(zhelp).
            ELSE.
              PERFORM save_request.
            ENDIF.
          ELSEIF old_ok_code = 'APPROVE' AND  g_mult_module_fl = 'X'.
            SET PARAMETER ID 'ZROLEREQNOFORDETAILS'
                   FIELD zic_prep_rolereq-docno.
            CALL SCREEN 200 STARTING AT 10 15  ENDING AT 90 25.
            PERFORM confirm_app.
            IF g_choice_app = 'J'.
              CLEAR g_choice_app.
              IF moduleid <> 'MM'.
                g_approver_level = 'L3'.
              ENDIF.
              PERFORM save_request.
            ENDIF.
          ELSE.
*          Perform check_items.
            IF moduleid <> 'MM'.
              g_approver_level = 'L3'.
            ENDIF.
*************************************** added by Bipin to check okcode value for save request
            IF old_ok_code = 'RELEASE' AND g_lines_rl NE 0 . "AND GT_TEXT IS  NOT INITIAL.
              FREE MEMORY ID 'TABLE1'."+ by vikas
              FREE MEMORY ID 'ZICE_IM'.
              CLEAR gt_text.
              CLEAR zice_ex.

            ENDIF.

            IMPORT oc_9001_rj FROM MEMORY ID 'OC_9001_IM'.
            IMPORT oc_9002_rj FROM MEMORY ID 'OC_9002_IM'.
            IMPORT oc_9003_rj FROM MEMORY ID 'OC_9003_IM'.
            IMPORT lv_expo FROM MEMORY ID 'LV_IMP'.

            IF oc_9001_rj = 'SUBMIT' OR oc_9002_rj = 'SUBMIT' OR oc_9003_rj = 'SUBMIT'
             OR old_ok_code = 'CHANGE' OR old_ok_code = 'CREATE' OR lv_rcount EQ '1' OR lv_rcount EQ '0'..
              CLEAR lv_expo.
            ENDIF.
            CLEAR oc_9001_rj.
*************************************** added by Bipin to check okcode value for save request
*            PERFORM SAVE_REQUEST.
            IF lv_expo = ''. " ADDED BY BIPIN
              PERFORM save_request.
            ENDIF.
            CLEAR lv_expo.     " ADDED BY BIPIN
          ENDIF.
**       endif.
        ENDIF.
*          ENDIF.
*Begin of <RD1K962817>.

      ENDIF.
  ENDCASE.

  CASE okcode_100.
*End of <RD1K962817>.
    WHEN 'MULTI'.

*      clear help_list_flag.

      CALL SCREEN 120 STARTING AT 10 5
                  ENDING   AT 90 15.
      CLEAR okcode_100.


    WHEN 'DELETE'.

      old_ok_code = okcode_100.

    WHEN 'ATTACH'.

*       if old_ok_code = 'CREATE' or
*          old_ok_code = 'CROSSCO' or
*          old_ok_code = 'CRCROLES'.
*          message i137(zhelp).
*       else.
*          perform attach_files.
*       endif.
      IF old_ok_code = 'CREATE' OR
          old_ok_code = 'CROSSCO' OR
          old_ok_code = 'CRCROLES'.
        MESSAGE i137(zhelp).
      ELSE.
        PERFORM attach_files.
        IF old_ok_code = 'DISPLAY' AND
           zic_prep_rolereq-status = 'IR'.
          attach_fl = 'X'.
          PERFORM confirm_more.

          IF g_choice_more = 'J'.
            CLEAR g_choice_more.
          ELSE.
            PERFORM save_request.
          ENDIF.
        ENDIF.
      ENDIF.

*       old_ok_code = okcode_100.

    WHEN 'LIST'.

      PERFORM list_files.

*       old_ok_code = okcode_100.

    WHEN 'CORR'.

      CALL SCREEN 105 STARTING AT 85 05 ENDING AT 148 24.
      CLEAR okcode_100.

    WHEN 'CROSSCO'.

      old_ok_code = okcode_100.
      moduleid = 'MM'.

    WHEN 'CRCROLES'.

      old_ok_code = okcode_100.

    WHEN 'SUMMARY'.

      SET PARAMETER ID 'ZROLEREQNOFORDETAILS'
                  FIELD zic_prep_rolereq-docno.
*      call transaction 'ZIC_DETAILS' .

      CALL SCREEN 200 STARTING AT 10 15  ENDING AT 90 25.

    WHEN 'GUIDE'.
* End of <> on 24032014
*      PERFORM LIST_HELP_FILES.
      PERFORM list_help_files_new.
* End of <> on 27032014
    WHEN OTHERS.

      CLEAR okcode_100.

  ENDCASE.

ENDMODULE.                 " user_command_100  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0120 INPUT.


ENDMODULE.                 " USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*&      Module  move_ok_code  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE move_ok_code INPUT.


********************* Added by Bipin to export the value for ZGRC_RISK_NALYSIS_RESULT.
  okcode_rj = old_ok_code.
  crt_name = zic_prep_rolereq-useridcr.
  tcode_rj = sy-tcode.

  EXPORT okcode_rj TO MEMORY ID 'OKCODE_RJ'.
  EXPORT crt_name TO MEMORY ID 'CRT_NAME_RJ'.
  EXPORT tcode_rj TO MEMORY ID 'TCODE_IM'.
********************* Added by Bipin to export the value for ZGRC_RISK_NALYSIS_RESULT.

  IF sy-ucomm = 'DBLCLK'.
    CLEAR sy-ucomm.
  ENDIF.
  okcode_100 = sy-ucomm.

  CLEAR :  err_flg.
  CASE okcode.

    WHEN 'GRC_RISK'.

      CLEAR gt_bucket_ex.
      reqnum_ex = zic_prep_rolereq-docno.
      IF moduleid = 'MM'.
        LOOP AT g_tablctrl110_itab INTO g_tablctrl110_wa.

          MOVE-CORRESPONDING g_tablctrl110_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.
      ELSEIF moduleid = 'SD'.
        LOOP AT g_tablctrl114_itab INTO g_tablctrl114_wa.

          MOVE-CORRESPONDING g_tablctrl114_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.
      ELSEIF moduleid = 'PP'.
        LOOP AT g_tablctrl113_itab INTO g_tablctrl113_wa.

          MOVE-CORRESPONDING g_tablctrl113_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.

      ELSEIF moduleid = 'PM'.
        LOOP AT g_tablctrl111_itab INTO g_tablctrl111_wa.

          MOVE-CORRESPONDING g_tablctrl111_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.

      ELSEIF moduleid = 'PS'.
        LOOP AT g_tablctrl112_itab INTO g_tablctrl112_wa.

          MOVE-CORRESPONDING g_tablctrl112_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.

      ELSEIF moduleid = 'HSE'.
        LOOP AT g_tablctrl116_itab INTO g_tablctrl116_wa.

          MOVE-CORRESPONDING g_tablctrl116_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.


      ELSEIF moduleid = 'QM'.
        LOOP AT g_tablctrl115_itab INTO g_tablctrl115_wa.

          MOVE-CORRESPONDING g_tablctrl115_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.

      ELSEIF moduleid = 'OLM'.
        LOOP AT g_tc_117_itab INTO g_tc_117_wa .

          MOVE-CORRESPONDING g_tc_117_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.

        """""""""""""""""""""""""""""""""""""""""""""""""""""
        "addition by lipsy  for srm module introduction on 3.03.2015 RD1K996555
      ELSEIF moduleid = 'SRM'.
        LOOP AT g_tablctrl118_itab INTO g_tablctrl118_wa.

          MOVE-CORRESPONDING g_tablctrl118_wa TO wa_bucket_ex.
          wa_bucket-docno = reqnum_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.
*    CLEAR WA_BUCKET.
        ENDLOOP.

        "end of addition by lipsy  for srm module introduction on 3.03.2015 RD1K996555

        """"""""""""""""""""""""""""""""""""""""""""""""

      ENDIF.


      SELECT * FROM zic_prep_rolerei INTO CORRESPONDING FIELDS OF TABLE gt_crmodule_ex
        WHERE docno = reqnum_ex AND moduleid NE moduleid.

      IF sy-subrc EQ 0.

        LOOP AT gt_crmodule_ex INTO wa_crmodule_ex.

          MOVE-CORRESPONDING wa_crmodule_ex TO wa_bucket_ex.
          APPEND wa_bucket_ex TO gt_bucket_ex.

        ENDLOOP.
        CLEAR : wa_crmodule_ex , gt_crmodule_ex.

      ENDIF.

*      LOOP AT G_TABLCTRL111_ITAB INTO G_TABLCTRL111_WA.
*
*        MOVE-CORRESPONDING G_TABLCTRL111_WA TO WA_BUCKET_EX.
*        APPEND WA_BUCKET_EX TO GT_BUCKET_EX.
*        CLEAR WA_BUCKET_EX.
*
*      ENDLOOP.

      EXPORT gt_bucket_ex TO MEMORY ID 'TABLE_IM'.
      CLEAR : it_tvarv.
      SELECT * FROM tvarvc INTO CORRESPONDING FIELDS OF TABLE it_tvarv
      WHERE name = 'ZGRC_CALL'.
      IF it_tvarv[] IS NOT INITIAL.
        READ TABLE it_tvarv INTO wa_tvarv WITH KEY name = 'ZGRC_CALL'.
      ENDIF.
      IF wa_tvarv-low IS NOT INITIAL.
        lv_grccall = wa_tvarv-low.
      ENDIF.

      IF syst-sysid = 'RD1'.

        lv9_rfc = 'GRDCLNT500'.

      ELSEIF syst-sysid = 'RQ1'.

        lv9_rfc = 'GRDCLNT500'.

      ELSEIF syst-sysid = 'RP1'.

        lv9_rfc = 'GRPCLNT500'.
      ENDIF.

      CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
        EXPORTING
          rfcdestination = lv9_rfc                   "'GRDCLNT500'
*         RFCDESTINATION = 'GRPCLNT500TEST'         changes on 02.08.2014  CAB_DNS
        IMPORTING
*         MSGV1          =
*         MSGV2          =
          rfc_subrc      = lv_subrc.
      IF  lv_grccall = 'X' AND lv_subrc = '0'.


        EXPORT reqnum_ex TO MEMORY ID 'REQNUM_IM'.
        okcode_ex = old_ok_code.
        EXPORT okcode_ex TO MEMORY ID 'OKCODE_IM'.
*        CALL TRANSACTION 'ZGRC_RISK_RESULT'. " + COMMENT BY VIKAS
        CALL TRANSACTION 'ZGRC_RISK_RESULT'. " + aDDED BY VIKAS

        IMPORT oc_9001_rj FROM MEMORY ID 'OC_9001_IM'.
        IF oc_9001_rj = 'REJECT'.
          LEAVE PROGRAM.
        ENDIF.

        IF old_ok_code EQ 'CREATE' OR old_ok_code EQ 'CHANGE'.
*          LEAVE PROGRAM."-BY VIKAS
          RETURN."+ by Vikas
*          LEAVE TO SCREEN 0.
*          SET SCREEN
        ENDIF.

*        IMPORT LV_EXPO FROM MEMORY ID 'LV_IMP'.
*********************************End of changes : Changes by Bipin Shukla on 24 july 2013
*        IF LV_EXPO = ''. " ADDED BY BIPIN
*          PERFORM SAVE_REQUEST.
*        ENDIF.       " ADDED BY BIPIN

      ENDIF.
      CLEAR reqnum_ex.
      CLEAR: okcode.
      CLEAR okcode_ex.

    WHEN 'GRC_RAL'.
      reqnum_ex = zic_prep_rolereq-docno.
      EXPORT reqnum_ex TO MEMORY ID 'REQNUM_IM'.
      okcode_ex = old_ok_code.
      EXPORT okcode_ex TO MEMORY ID 'OKCODE_IM'.
      CALL TRANSACTION 'ZGRC_SEC_RESULT'.

      CLEAR reqnum_ex.
      CLEAR okcode_ex.

    WHEN  'GRC_RPL'.
      reqnum_ex = zic_prep_rolereq-docno.
      EXPORT reqnum_ex TO MEMORY ID 'REQNUM_IM'.
      okcode_ex = old_ok_code.
      EXPORT okcode_ex TO MEMORY ID 'OKCODE_IM'.
      CALL TRANSACTION 'ZGRC_VIOL'.

      CLEAR reqnum_ex.
      CLEAR okcode_ex.

    WHEN OTHERS.
  ENDCASE.

**  get cursor line g_cursor_line.
**  g_curr_line = g_cursor_line.
**  g_curr_line = TABCTRL100-top_line + g_cursor_line - 1.
**  g_curr_line_100 = g_curr_line.

ENDMODULE.                 " move_ok_code  INPUT
*&---------------------------------------------------------------------*
*&      Module  clear_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE clear_data INPUT.
*Begin of <RD1K963151>.
  DATA: new_value TYPE i.
*End of <RD1K963151>.
  IF NOT  zic_prep_rolereq-docno IS INITIAL.

*  data : l_docno like  ZIC_PREP_ROLEREQ-docno.

    l_docno =  zic_prep_rolereq-docno.

*Begin of <RD1K963151>.
    LOOP AT SCREEN.
      IF screen-group3 = 'GP3'.
        screen-name = 'ZIC_PREP_ROLEREQ-DOCNO'.
        screen-active = 0.
        screen-required = 0.
        screen-input = 0.
        screen-output = 0 .
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
*End of <RD1K963151>.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = l_docno
      IMPORTING
        output = l_docno.

    zic_prep_rolereq-docno = l_docno.

  ENDIF.

  IF old_doc_no <>  zic_prep_rolereq-docno.
    CLEAR g_hd_copied.
    CLEAR g_mult_module_fl.
    PERFORM destroy_ctrl.
  ENDIF.

  IF NOT moduleid IS INITIAL AND old_moduleid <> moduleid.
    g_tablctrl110_copied = ''.
    g_tablctrl111_copied = ''.
    g_tablctrl112_copied = ''.
    g_tablctrl113_copied = ''.
    g_tablctrl114_copied = ''.
    g_tablctrl115_copied = ''.

    """""""""""""""""""""""""""""""""""""""
    "addition by lipsy  for srm module introduction on 3.03.2015 RD1K996555
    g_tablctrl118_copied = ''.

    "end of addition by lipsy  for srm module introduction on 3.03.2015 RD1K996555

    """"""""""""""""""""""""""""""""""""""""""""
  ENDIF.

ENDMODULE.                 " clear_data  INPUT
*&---------------------------------------------------------------------*
*&      Module  TEXT_CTRL_UEBERNEHMEN1  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE text_ctrl_uebernehmen1 INPUT.

  gv_xthead_updkz = 0.

  CALL METHOD gv_text_editor1->get_text_as_stream
    IMPORTING
      text                   = lt_text_table1
      is_modified            = gv_xthead_updkz
    EXCEPTIONS
      error_dp               = 1
      error_cntl_call_method = 2
      OTHERS                 = 3.

  CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
    TABLES
      text_stream = lt_text_table1
      itf_text    = tlinetab1.
*
  IF ( old_ok_code = 'CREATE' )
  OR ( old_ok_code = 'CROSSCO' )
  OR ( old_ok_code = 'CRCROLES' )
  OR ( old_ok_code = 'CHANGE' )
  OR ( old_ok_code = 'RELEASE' )
  OR ( old_ok_code = 'APPROVE' )
   OR ( old_ok_code = 'DISPLAY' AND  zic_prep_rolereq-comm_fl = 'X'
        AND  zic_prep_rolereq-status <> 'C' ).

    CALL METHOD gv_text_editor2->get_text_as_stream
      IMPORTING
        text                   = lt_text_table2
        is_modified            = gv_xthead_updkz
      EXCEPTIONS
        error_dp               = 1
        error_cntl_call_method = 2
        OTHERS                 = 3.

    CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
      TABLES
        text_stream = lt_text_table2
        itf_text    = tlinetab2.
    DESCRIBE TABLE tlinetab2 LINES g_lines_2.
  ENDIF..

ENDMODULE.                 " TEXT_CTRL_UEBERNEHMEN1  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0105  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0105 INPUT.

  DATA: okcode105 LIKE sy-ucomm.

  okcode105 = sy-ucomm.

  CASE okcode105.
    WHEN 'OK'.
      CLEAR okcode105.
    WHEN 'CANCEL'.
      REFRESH tlinetab2[].
      CLEAR okcode105.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0105  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_SLOC  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_sloc INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SLOC' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


  DATA : l_plant LIKE zic_prep_rolerei-plant.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'PLANT'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_plant.


  DATA   : it_t001l TYPE TABLE OF t001l WITH HEADER LINE.
  DATA   : it_excp_sl TYPE TABLE OF zmm_prep_sl_excp WITH HEADER LINE.
  DATA   : wa_t001l LIKE t001l.
  DATA   : l_zarea LIKE zmm_consm-zarea.

  SELECT * FROM t001l INTO CORRESPONDING FIELDS OF
             TABLE it_t001l WHERE werks = l_plant.

  IF  zic_prep_rolereq-disc_mm_flag = 'X'.

    LOOP AT it_t001l INTO wa_t001l.

      SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

      IF sy-subrc = 0.

        IF l_zarea+0(1) <> 'M'.
          DELETE it_t001l.
        ENDIF.

      ELSE.

        DELETE it_t001l.

      ENDIF.

    ENDLOOP.

  ELSE.

    LOOP AT it_t001l INTO wa_t001l.

      SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

      IF sy-subrc = 0.

        IF l_zarea+0(1) = 'M'.
          DELETE it_t001l.
        ENDIF.

      ELSE.

        DELETE it_t001l.

      ENDIF.

    ENDLOOP.

  ENDIF.

  SELECT * FROM zmm_prep_sl_excp INTO TABLE it_excp_sl.

************************************

  LOOP AT it_excp_sl.

    READ TABLE it_t001l WITH KEY werks = it_excp_sl-werks
    lgort = it_excp_sl-lgort.

    IF sy-subrc = 0.

      DELETE it_t001l WHERE werks = it_excp_sl-werks
      AND lgort = it_excp_sl-lgort.

    ENDIF.

  ENDLOOP.

************************************
  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'WERKS'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGORT'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGOBE'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LGORT'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SLOC'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_t001l
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_t001l,ist_return_tab,g_field_tab..
  FREE  : it_t001l,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_SLOC  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_APPROVER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_approver INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


  DATA : it_approver LIKE TABLE OF zmm_prep_approve.
  DATA : wa_approver LIKE zmm_prep_approve.

  DATA : it_approver1 LIKE TABLE OF zmm_prep_app_crc.
  DATA : wa_approver1 LIKE zmm_prep_app_crc.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_role_name.

  IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'.

    SELECT * FROM zmm_prep_app_crc INTO TABLE it_approver1.

  ELSE.

    SELECT * FROM zmm_prep_approve INTO TABLE it_approver.

  ENDIF.


*      if  ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
*
*
*              if l_role_name = 'M11'.
*
*                  loop at it_approver into wa_approver.
*
*                    if wa_approver-M11_FLAG <> 'X'.
*                      delete it_approver.
*                    endif.
*
*                  endloop.
*
*              endif.
*
*      endif.


*      if  ZIC_PREP_ROLEREQ-DISC_MM_FLAG <> 'X'.
*
*         if l_role_name = 'M11'.
*
*            loop at it_approver into wa_approver.
*
*                if wa_approver-M11_FLAG <> 'X'.
*                    delete it_approver.
*                 endif.
*
*            endloop.
*
*         endif.
*
*      endif.
*******************************************************
  IF l_role_name = 'M11S'.                                  "22.05.06

    LOOP AT it_approver INTO wa_approver.

      CASE  zic_prep_rolereq-disc_mm_flag.

        WHEN 'X'.
          IF wa_approver-mm_flag <> 'X'.
            DELETE it_approver.
          ENDIF.
        WHEN OTHERS.
          IF wa_approver-m11s_flag <> 'X'.
            DELETE it_approver.
          ENDIF.
      ENDCASE.

    ENDLOOP.

  ENDIF.

  IF l_role_name = 'M11M'.

    LOOP AT it_approver INTO wa_approver.

      CASE  zic_prep_rolereq-disc_mm_flag.

        WHEN 'X'.
          IF wa_approver-mm_flag <> 'X'
             OR wa_approver-m11m_flag <> 'X'.
            DELETE it_approver.
          ENDIF.
        WHEN OTHERS.
          IF wa_approver-mm_flag = 'X'
             OR wa_approver-m11m_flag <> 'X'.
            DELETE it_approver.
          ENDIF.
      ENDCASE.

    ENDLOOP.

  ENDIF.
**************************************************22.05.06

  IF l_role_name = 'M8'.

    LOOP AT it_approver INTO wa_approver.

      IF wa_approver-m8_flag <> 'X'.
        DELETE it_approver.
      ENDIF.

    ENDLOOP.

  ENDIF.

  IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'..

    IF l_role_name = 'M3'.

      LOOP AT it_approver1 INTO wa_approver1.

        IF wa_approver1-m3_flag <> 'X'.
          DELETE it_approver1.
        ENDIF.

      ENDLOOP.

    ENDIF.

    IF l_role_name = 'M3A'.                                 "22.05.06

      LOOP AT it_approver1 INTO wa_approver1.

        IF wa_approver1-m3a_flag <> 'X'.
          DELETE it_approver1.
        ENDIF.

      ENDLOOP.

    ENDIF.

    IF l_role_name = 'M3B'.

      LOOP AT it_approver1 INTO wa_approver1.

        IF wa_approver1-m3b_flag <> 'X'.
          DELETE it_approver1.
        ENDIF.

      ENDLOOP.

    ENDIF.                                                  " 22.05.06


    IF l_role_name = 'M11S'.

      LOOP AT it_approver1 INTO wa_approver1.

*                    if wa_approver1-M11S_FLAG <> 'X'.
*                        delete it_approver1.
*                    endif.
        CASE  zic_prep_rolereq-disc_mm_flag.

          WHEN 'X'.
            IF wa_approver1-mm_flag <> 'X'
               OR wa_approver1-m11s_flag <> 'X'.
              DELETE it_approver1.
            ENDIF.
          WHEN OTHERS.
            IF wa_approver1-mm_flag = 'X'
               OR wa_approver1-m11s_flag <> 'X'.
              DELETE it_approver1.
            ENDIF.
        ENDCASE.

      ENDLOOP.

    ENDIF.

    IF l_role_name = 'M11M'.

      LOOP AT it_approver1 INTO wa_approver1.

*                    if wa_approver1-M11M_FLAG <> 'X'.
*                        delete it_approver1.
*                     endif.

        CASE  zic_prep_rolereq-disc_mm_flag.

          WHEN 'X'.
            IF wa_approver1-mm_flag <> 'X'
               OR wa_approver1-m11m_flag <> 'X'.
              DELETE it_approver1.
            ENDIF.
          WHEN OTHERS.
            IF wa_approver1-mm_flag = 'X'
               OR wa_approver1-m11m_flag <> 'X'.
              DELETE it_approver1.
            ENDIF.
        ENDCASE.

      ENDLOOP.

    ENDIF.

    it_approver[] = it_approver1[].

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZMM_PREP_APPROVE'.
  g_field_wa-fieldname = 'APP_LEVEL'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_PREP_APPROVE'.
  g_field_wa-fieldname = 'L_DESC'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'APP_LEVEL'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-APPROVER'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_approver
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_approver,ist_return_tab, it_approver1,g_field_tab.
  FREE  : it_approver,ist_return_tab, it_approver1,g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_APPROVER  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_RECEIPT_LOC  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_receipt_loc INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-RECEIPT_LOC' AND screen-input =
0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


*  DATA : it_recpt LIKE TABLE OF zmm_location.
  DATA : it_recpt TYPE STANDARD TABLE OF zmm_location.
  DATA : wa_recpt LIKE zmm_location.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_role_name.

  SELECT * FROM zmm_location INTO TABLE it_recpt.
*WHERE bukrs = zic_prep_rolereq-ccode.      " Commented By Anjali Vala

  """""""""""""""""""""""""""""""""""""""""""""""""""""
  "commented by lipsy on 23.09.2014 for selecting for corresponding
  "company code RD1K994398
*    .
  """"end of comment by lipsy on 23.09.2014 for selecting for corresponding
  "company code RD1K994398
  """""""""""""""""""""""""""""""""""""""""""""""""
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""
  "added by lipsy on 23.09.2014 for selecting for corresponding
  "company code RD1K994398





  """"end of addition by lipsy on 23.09.2014 for selecting for corresponding
  "company code RD1K994398

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""


  IF l_role_name = 'M12'.

    LOOP AT it_recpt INTO wa_recpt.

      IF wa_recpt-loccg <> 'RL'.
        DELETE it_recpt.
      ENDIF.

    ENDLOOP.

  ENDIF.


  IF l_role_name = 'M17'.

    LOOP AT it_recpt INTO wa_recpt.

      IF wa_recpt-loccg <> 'CF'.
        DELETE it_recpt.
      ENDIF.

    ENDLOOP.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZMM_LOCATION'.
  g_field_wa-fieldname = 'LOCCD'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_LOCATION'.
  g_field_wa-fieldname = 'LOCCG'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_LOCATION'.
  g_field_wa-fieldname = 'LOCDS'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LOCCD'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_recpt
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_recpt,ist_return_tab,g_field_tab.
  FREE  : it_recpt,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_RECEIPT_LOC  INPUT
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  IF sy-ucomm = 'EXT' .
    LEAVE PROGRAM.
  ENDIF.
*  IF  SY-UCOMM = 'BAC' AND OLD_OK_CODE = ' '.
*    LEAVE TO SCREEN 0.
*  ENDIF.



ENDMODULE.                 " EXIT  INPUT
*&---------------------------------------------------------------------*
*&      Module  check_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_data INPUT.

  old_doc_no =  zic_prep_rolereq-docno.
  old_userid =  zic_prep_rolereq-userid.
  old_disc_mm_flag =  zic_prep_rolereq-disc_mm_flag.
  old_moduleid = moduleid.


  IF LV_new > LV_Old.
   MESSAGE 'You do not meet the minimum designation criteria. Pls. contact SAP team with a copy of order for further action.' TYPE 'I'.
   LEAVE TO SCREEN sy-DYNNR.
  ENDIF.
ENDMODULE.                 " check_data  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data INPUT.

  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.

**---------- Changes Start date 24.06.2016 11:55:29-------------------
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

    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                 a~persk a~sbmod  c~designo c~r_p_cd c~version
               d~sdesig_text AS designation d~adesig_text AS adesignation
               d~disc_cd AS disc_cd
                 INTO CORRESPONDING FIELDS OF TABLE ist_data
            FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                  ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                     ON c~designo = d~desig_code AND
                         c~r_p_cd  = d~r_p_cd AND
                         c~version = d~version )
                      WHERE a~pernr =  zic_prep_rolereq-userid AND
                            a~sprps = ' ' AND
                            a~endda = '99991231' AND
                            c~sprps = ' ' AND
                            c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:55:29-----------------

    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER

***START OF COMMENT <RD1K983325>   CR: 30007580  dt: 05.04.2013.
*      g_ccode = ist_data-bukrs.
***end OF COMMENT <RD1K983325>.

**code added by CAB_AMITMOZA  <RD1K983325>   CR: 30007580  dt: 05.04.2013.
      g_ccode =  zic_prep_rolereq-ccode.
**code end by CAB_AMITMOZA  <RD1K983325>

    ENDIF.

*SELECT single *
*       FROM pa0027
*       INTO wa_pa0027
*       WHERE pernr = cpf_lfb1 AND
*             endda = '99991231' AND
*             sprps = ' ' . " SPRPS - Lock Indicator 'X'
*
*G_CCODE = wa_pa0027-kbu01+0(3).

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X'.

*  clear g_e_fl.

    IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'.

*** 15/05/2007
      SELECT * FROM ZMM_PREP_CRCDESG UP TO 1 ROWS
 WHERE ROLE_TYPE =
 ZIC_PREP_ROLEREI-ROLE_NAME AND ROLE_TYPE_EX = ZIC_PREP_ROLEREI-ROLE_TYPE_EX
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      IF sy-subrc <> 0.
        g_field = 'CRC_POS'.
        MESSAGE i200(zhelp).
      ELSE.
*** 31/05/2007
        IF NOT zmm_prep_crcdesg-role_pos IS INITIAL.
          SELECT SINGLE * FROM agr_users WHERE
                   uname = zic_prep_rolereq-userid AND
                   agr_name = zmm_prep_crcdesg-role_pos.
          IF sy-subrc = 0.
            PERFORM message1.
          ELSE.
            PERFORM message2.
          ENDIF.
        ENDIF.
      ENDIF.
***

      SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
 WHERE ROLE_TYPE =
 ZIC_PREP_ROLEREI-ROLE_NAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.

      IF sy-subrc <> 0.
        g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
        MESSAGE i117(zhelp).
*      ELSEIF zic_prep_rolerei-role_name+0(1) <> 'C' AND zic_prep_rolerei-role_name+0(1) <> 'N'.
*        g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
*        MESSAGE i117(zhelp).
      ENDIF.

    ELSE.
      SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                      zic_prep_rolerei-role_name.
      IF sy-subrc <> 0.
        g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
        MESSAGE i118(zhelp).
      ENDIF.

    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
    CLEAR  zic_prep_rolerei-receipt_loc.
    CLEAR  zic_prep_rolerei-sloc.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR  zic_prep_rolerei-grp.
    CLEAR  zic_prep_rolerei-approver.

    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
    CLEAR  zic_prep_rolerei-receipt_loc.
    CLEAR  zic_prep_rolerei-sloc.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR  zic_prep_rolerei-grp.
    CLEAR  zic_prep_rolerei-approver.
  ENDIF.


  IF g_field IS INITIAL.
    g_field = 'ZIC_PREP_ROLEREI-PLANT'.
  ENDIF.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.

*  select single * from zmm_prep_roledes  where
*            role_type = ZIC_PREP_ROLEREI-role_name.
*  if sy-subrc <> 0.
*       message e067(zhelp) with ZIC_PREP_ROLEREI-role_name.
*  else.

** put validation for MM discipline roles????

    IF old_ok_code = 'CRCROLES'.

    ELSE.

      IF zmm_prep_roledes-mm_disc_flag = 'X'.

        IF  zic_prep_rolereq-disc_mm_flag = 'X'.
        ELSE.
          IF zic_prep_rolerei-role_name <> ''.
            MESSAGE e081(zhelp) WITH zic_prep_rolerei-role_name.
          ENDIF.
        ENDIF.

      ENDIF.

    ENDIF.

*  endif.

    IF NOT zic_prep_rolerei-plant IS INITIAL.

      SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
                 TABLE it_bukrs  WHERE """bukrs =  zic_prep_rolereq-ccode  ""--->Commented By Suresh 24.01.2016
                                    "AND werks = zic_prep_rolerei-plant.   ""---Commented By Suresh 24.01.2016
                                    werks = zic_prep_rolerei-plant.        ""--->Code added By Suresh 24.01.2016
*--->Started-Comment By Suresh 24.01.2016
****      IF sy-subrc <> 0.
****        g_e_fl = 'X'.
****        g_field = 'ZIC_PREP_ROLEREI-PLANT'.
****        g_i = g_curr_line.
****        MESSAGE e068(zhelp) WITH zic_prep_rolerei-role_name.
****
****      ENDIF.
*--->Ended-Comment By Suresh 24.01.2016
    ENDIF.

************finding group*******************

    REFRESH : it_cond, it_t024, it_t024_1.
    CLEAR   : wa_t024.
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
* if l_role_name = 'M6' or  l_role_name = 'M7' or
*     l_role_name = 'M8'.
*
* else.
*
*      if  ZIC_PREP_ROLEREQ-DISC_MM_FLAG <> 'X'.
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

    ""
    ""
    IF g_tablctrl110_wa-role_name = 'M6' OR
        g_tablctrl110_wa-role_name = 'M7' OR
        g_tablctrl110_wa-role_name = 'M8'.
      CONCATENATE '%' g_ccode '%' INTO g_line1.
      SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
    ELSE.
      IF zic_prep_rolereq-disc_mm_flag <> 'X'.
        CONCATENATE '%' g_ccode '%' 'IND' '%'
        INTO g_line1.
        SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
      ELSE.
        CONCATENATE  '%' g_ccode '%' 'MM' '%'
        INTO g_line1.
        SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
      ENDIF.
    ENDIF.
**
    IF  NOT zic_prep_rolerei-grp IS INITIAL.

      LOOP AT it_t024 INTO wa_t024.

        IF zic_prep_rolerei-grp = wa_t024-ekgrp.
          grp_flag = 'X'.
        ENDIF.

      ENDLOOP.

      IF grp_flag = 'X'.
        CLEAR grp_flag.
      ELSE.
        g_e_fl = 'X'.
        g_read_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-GRP'.
        MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl110_wa.
        MODIFY g_tablctrl110_itab
                  FROM g_tablctrl110_wa
                    INDEX tablctrl110-current_line.
        g_i = tablctrl110-current_line.
        MESSAGE i069(zhelp).
        CALL SCREEN 100.

      ENDIF.


      """"""""""""""
      REFRESH: itab_agr_users[].
      CLEAR:v_grp_comp.

      IF zic_prep_rolerei-grp IS NOT INITIAL.
        CONCATENATE '%' zic_prep_rolerei-grp  '%' INTO v_grp_comp.

        SELECT * FROM agr_users INTO CORRESPONDING FIELDS OF TABLE
            itab_agr_users
            WHERE uname = zic_prep_rolereq-userid
          AND agr_name LIKE v_grp_comp
          AND to_dat = '99991231'.

        IF sy-subrc = 0.
          MESSAGE 'Purchase group already Assigned' TYPE 'I'.
        ENDIF.
      ENDIF.

      """"""""""""

    ENDIF.

***************************

    CLEAR : l_zarea, wa_t001l.
    REFRESH it_t001l.

    IF ( zic_prep_rolerei-role_name = 'M13' OR
       zic_prep_rolerei-role_name = 'M14' OR
        zic_prep_rolerei-role_name = 'M16' OR
        zic_prep_rolerei-role_name = 'M18' OR
        zic_prep_rolerei-role_name = 'M19' ) AND
        NOT zic_prep_rolerei-plant IS INITIAL.

      SELECT * FROM t001l INTO CORRESPONDING FIELDS OF
                   TABLE it_t001l  WHERE werks = zic_prep_rolerei-plant.

      IF  sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-PLANT'.
        MESSAGE e074(zhelp).

      ENDIF.

    ENDIF.

    IF  zic_prep_rolereq-disc_mm_flag = 'X'.

      LOOP AT it_t001l INTO wa_t001l.

        SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

        IF sy-subrc = 0.

          IF l_zarea+0(1) <> 'M'.
            DELETE it_t001l.
          ENDIF.

        ELSE.

          DELETE it_t001l.

        ENDIF.

      ENDLOOP.

    ELSE.

      LOOP AT it_t001l INTO wa_t001l.

        SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

        IF sy-subrc = 0.

          IF l_zarea+0(1) = 'M'.
            DELETE it_t001l.
          ENDIF.

        ELSE.

          DELETE it_t001l.

        ENDIF.

      ENDLOOP.

    ENDIF.

    IF  NOT zic_prep_rolerei-sloc IS INITIAL.

      LOOP AT it_t001l INTO wa_t001l.

        IF zic_prep_rolerei-sloc = wa_t001l-lgort.
          loc_flag = 'X'.
        ENDIF.

      ENDLOOP.

      IF loc_flag = 'X'.
        CLEAR loc_flag.
      ELSE.
** cab_ajit 07.02.2006
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-SLOC'.
        MESSAGE e073(zhelp).

      ENDIF.

    ENDIF.


***************************

    CLEAR wa_recpt.
    REFRESH it_recpt.

    IF ( zic_prep_rolerei-role_name = 'M12' OR
       zic_prep_rolerei-role_name = 'M17' ) AND
       NOT zic_prep_rolerei-receipt_loc IS INITIAL.

      SELECT * FROM zmm_location INTO TABLE it_recpt.

      IF zic_prep_rolerei-role_name = 'M12'.

        LOOP AT it_recpt INTO wa_recpt.

          IF wa_recpt-loccg <> 'RL'.
            DELETE it_recpt.
          ENDIF.

        ENDLOOP.

      ENDIF.


      IF zic_prep_rolerei-role_name = 'M17'.

        LOOP AT it_recpt INTO wa_recpt.

          IF wa_recpt-loccg <> 'CF'.
            DELETE it_recpt.
          ENDIF.

        ENDLOOP.

      ENDIF.

    ENDIF.

    IF  NOT zic_prep_rolerei-receipt_loc IS INITIAL.

      LOOP AT it_recpt INTO wa_recpt.

        IF zic_prep_rolerei-receipt_loc = wa_recpt-loccd.
          loc_flag = 'X'.
        ENDIF.

      ENDLOOP.

      IF loc_flag = 'X'.
        CLEAR loc_flag.
      ELSE.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-RECEIPT_LOC'.
        MESSAGE e075(zhelp).

      ENDIF.

    ENDIF.


*****************************
*****************************22.05.06

    IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'.

      SELECT * FROM zmm_prep_app_crc INTO TABLE it_approver1.

    ELSE.

      SELECT * FROM zmm_prep_approve INTO TABLE it_approver.

    ENDIF.

    IF l_role_name = 'M11S'.                                "22.05.06

      LOOP AT it_approver INTO wa_approver.

        CASE  zic_prep_rolereq-disc_mm_flag.

          WHEN 'X'.
            IF wa_approver-mm_flag <> 'X'.
              DELETE it_approver.
            ENDIF.
          WHEN OTHERS.
            IF wa_approver-m11s_flag <> 'X'.
              DELETE it_approver.
            ENDIF.
        ENDCASE.

      ENDLOOP.

    ENDIF.

    IF l_role_name = 'M11M'.

      LOOP AT it_approver INTO wa_approver.

        CASE  zic_prep_rolereq-disc_mm_flag.

          WHEN 'X'.
            IF wa_approver-mm_flag <> 'X'
               OR wa_approver-m11m_flag <> 'X'.
              DELETE it_approver.
            ENDIF.
          WHEN OTHERS.
            IF wa_approver-mm_flag = 'X'
               OR wa_approver-m11m_flag <> 'X'.
              DELETE it_approver.
            ENDIF.
        ENDCASE.

      ENDLOOP.

    ENDIF.
**************************************************22.05.06

    IF l_role_name = 'M8'.
      LOOP AT it_approver INTO wa_approver.

        IF wa_approver-m8_flag <> 'X'.
          DELETE it_approver.
        ENDIF.

      ENDLOOP.

    ENDIF.

    IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'..

      IF l_role_name = 'M3'.

        LOOP AT it_approver1 INTO wa_approver1.

          IF wa_approver1-m3_flag <> 'X'.
            DELETE it_approver1.
          ENDIF.

        ENDLOOP.

      ENDIF.

      IF l_role_name = 'M3A'.                               "22.05.06

        LOOP AT it_approver1 INTO wa_approver1.

          IF wa_approver1-m3a_flag <> 'X'.
            DELETE it_approver1.
          ENDIF.

        ENDLOOP.

      ENDIF.

      IF l_role_name = 'M3B'.

        LOOP AT it_approver1 INTO wa_approver1.

          IF wa_approver1-m3b_flag <> 'X'.
            DELETE it_approver1.
          ENDIF.

        ENDLOOP.

      ENDIF.                                                " 22.05.06


      IF l_role_name = 'M11S'.

        LOOP AT it_approver1 INTO wa_approver1.

          CASE  zic_prep_rolereq-disc_mm_flag.

            WHEN 'X'.
              IF wa_approver1-mm_flag <> 'X'
                 OR wa_approver1-m11s_flag <> 'X'.
                DELETE it_approver1.
              ENDIF.
            WHEN OTHERS.
              IF wa_approver1-mm_flag = 'X'
                 OR wa_approver1-m11s_flag <> 'X'.
                DELETE it_approver1.
              ENDIF.
          ENDCASE.

        ENDLOOP.

      ENDIF.

      IF l_role_name = 'M11M'.

        LOOP AT it_approver1 INTO wa_approver1.

          CASE  zic_prep_rolereq-disc_mm_flag.

            WHEN 'X'.
              IF wa_approver1-mm_flag <> 'X'
                 OR wa_approver1-m11m_flag <> 'X'.
                DELETE it_approver1.
              ENDIF.
            WHEN OTHERS.
              IF wa_approver1-mm_flag = 'X'
                 OR wa_approver1-m11m_flag <> 'X'.
                DELETE it_approver1.
              ENDIF.
          ENDCASE.

        ENDLOOP.

      ENDIF.

      it_approver[] = it_approver1[].

    ENDIF.
*********************************************22.05.06

    IF  NOT zic_prep_rolerei-approver IS INITIAL.

      LOOP AT it_approver INTO wa_approver.

        IF zic_prep_rolerei-approver = wa_approver-app_level.
          approver_flag = 'X'.
        ENDIF.

      ENDLOOP.

      IF approver_flag = 'X'.
        CLEAR approver_flag.
      ELSE.
        g_e_fl = 'X'.
        g_read_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-APPROVER'.
        MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl110_wa.
        MODIFY g_tablctrl110_itab
                  FROM g_tablctrl110_wa
                    INDEX tablctrl110-current_line.
        g_i = tablctrl110-current_line.
        MESSAGE e135(zhelp).
        CALL SCREEN 100.

      ENDIF.

    ENDIF.


  ENDIF.

ENDMODULE.                 " validate_lineitem_data  INPUT
*&---------------------------------------------------------------------*
*&      Module  record_rej_id_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE record_rej_id_data INPUT.

  IF old_ok_code <> 'DISPLAY' AND old_ok_code <> 'CHANGE'.
**13/04/07
    IF zic_prep_rolerei-rej_id IS INITIAL.
      zic_prep_rolerei-rej_id = sy-uname.
      zic_prep_rolerei-rej_date = sy-datum.
    ENDIF.

    IF NOT zic_prep_rolerei-rej_fl IS INITIAL AND
       zic_prep_rolerei-rej_fl_save IS INITIAL.

      SELECT SINGLE * FROM  zmm_prep_rej_lis  WHERE
        rej_code = zic_prep_rolerei-rej_fl .
      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        MESSAGE e111(zhelp).
      ELSE.
*        IF g_user = 'L1' AND zic_prep_rolerei-rej_fl <> 'R'.
*          g_e_fl = 'X'.
*          MESSAGE e111(zhelp).
        IF g_user = 'L3' AND zic_prep_rolerei-rej_fl <> 'B'.
          g_e_fl = 'X'.
          MESSAGE e111(zhelp).
*        ELSEIF g_user = 'IM' AND zic_prep_rolerei-rej_fl <> 'I'.
*          g_e_fl = 'X'.
*          MESSAGE e111(zhelp).
        ENDIF.
      ENDIF.
    ENDIF.
**
  ENDIF.
ENDMODULE.                 " record_rej_id_data  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_TEL  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_tel INPUT.

  DATA : tel_len TYPE i.
  tel_len = strlen(  zic_prep_rolereq-telno ).
  IF   zic_prep_rolereq-telno CN ' 0123456789-'.
    MESSAGE e097(zhelp).
  ELSE.
    IF tel_len < 7.
      MESSAGE e098(zhelp).
    ENDIF.
  ENDIF.

ENDMODULE.                 " CHECK_TEL  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data1  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data1 INPUT.

  IF old_ok_code = 'CRCROLES'.

    SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
 WHERE ROLE_TYPE =
 ZIC_PREP_ROLEREI-ROLE_NAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
  ELSE.

    SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                   zic_prep_rolerei-role_name.

  ENDIF.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.

ENDMODULE.                 " validate_lineitem_data1  INPUT
*&---------------------------------------------------------------------*
*&      Module  clear_read  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE clear_read INPUT.
  CLEAR g_read_fl.
ENDMODULE.                 " clear_read  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno INPUT.
  CLEAR g_srno.
  LOOP AT g_tablctrl110_itab INTO g_tablctrl110_wa.
    g_srno = g_srno + 1.
    g_tablctrl110_wa-srno = g_srno.
    MODIFY g_tablctrl110_itab FROM g_tablctrl110_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl110_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl110_itab  LINES tablctrl110-lines.
  CLEAR g_srno.

ENDMODULE.                 " change_srno  INPUT
*&---------------------------------------------------------------------*
*&      Module  delete_dup  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE delete_dup INPUT.
  IF NOT g_tabctrl100_itab[] IS INITIAL .

    DELETE ADJACENT DUPLICATES FROM g_tabctrl100_itab
    COMPARING role_name plant grp sloc receipt_loc approver.

  ENDIF.
ENDMODULE.                 " delete_dup  INPUT
*&---------------------------------------------------------------------*
*&      Module  init_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_data INPUT.
  g_role_name_prev = zic_prep_rolerei-role_name.
ENDMODULE.                 " init_data  INPUT

*&spwizard: input module for tc 'TABLCTRL110'. do not change this line!
*&spwizard: modify table
MODULE tablctrl110_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl110_wa.

  SELECT SINGLE * FROM zmm_prep_rolegrp WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  IF zic_prep_rolerei-rej_fl = ''.

    IF sy-subrc = 0 AND old_ok_code = 'APPROVE'.
      IF zmm_prep_rolegrp-approver1 = g_user
         OR zmm_prep_rolegrp-approver2 = g_user
         OR zmm_prep_rolegrp-approver3 = g_user

      """""""""""""""""""""""""""
        "added by lipsy for l2 approver on 20.03.2015 RD1K996555
            OR ( moduleid = 'SRM' AND zmm_prep_rolegrp-approver1 = g_user_l2 )
             "End of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
       """"""""""""""""""""""""
        .
      ELSE.

        IF okcode_100 = 'SAV'.
          IF err_flg <> 'X'.
            err_flg = 'X'.
            CLEAR : sy-ucomm, okcode_100.
          ENDIF.
          MESSAGE e047(zhelp) WITH zmm_prep_rolegrp-role_type.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

  IF NOT g_tablctrl110_wa-role_name IS INITIAL.
    IF old_ok_code = 'CRCROLES' OR zic_prep_rolereq-crc_fl = 'X'.
      SELECT * FROM ZMM_PREP_ROLECRC UP TO 1 ROWS
 WHERE ROLE_TYPE =
 ZIC_PREP_ROLEREI-ROLE_NAME
 ORDER BY PRIMARY KEY .
 ENDSELECT.
      IF sy-subrc = 0.
        g_tabctrl100_wa-role_desc = zmm_prep_rolecrc-brief_desc.
      ENDIF.
    ELSE.
      SELECT SINGLE * FROM zmm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
      IF sy-subrc = 0.
        g_tablctrl110_wa-role_desc = zmm_prep_roledes-brief_desc.
*Begin  of <RD1K962817>.
        IF g_tablctrl110_wa-role_name = 'M8'.
          g_tablctrl110_wa-approver = zic_prep_rolereq-persk.
        ENDIF.
*End of <RD1K962817>.
*        if  not g_tablctrl110_wa-APPROVER is  INITIAL and ZIC_PREP_ROLEREI-ROLE_NAME = 'M8'.
*          loop AT SCREEN.
*            if screen-group2 = 'MOD'.
**              screen-active = 1.
**              screen-output =  1.
*              screen-input = 0.
**              screen-intensified = 0.
*              MODIFY SCREEN .
*              ENDIF.
*              endloop.
*endif.

      ENDIF.
    ENDIF.
  ENDIF.

  MODIFY g_tablctrl110_itab
     FROM g_tablctrl110_wa
     INDEX tablctrl110-current_line.

  IF sy-subrc <> 0.
    APPEND g_tablctrl110_wa TO g_tablctrl110_itab.
  ENDIF.

  IF g_tablctrl110_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl110_wa-flag.
    APPEND g_tablctrl110_wa TO g_tablctrl110_itab.
  ENDIF.

ENDMODULE.                    "TABLCTRL110_modify INPUT

*&spwizard: input module for tc 'TABLCTRL110'. do not change this line!
*&spwizard: mark table
MODULE tablctrl110_mark INPUT.
  IF tablctrl110-line_sel_mode = 1 AND
     g_tablctrl110_wa-flag = 'X'.
    LOOP AT g_tablctrl110_itab INTO g_tablctrl110_wa
      WHERE flag = 'X'.
      g_tablctrl110_wa-flag = ''.
      MODIFY g_tablctrl110_itab
        FROM g_tablctrl110_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl110_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl110_itab
    FROM g_tablctrl110_wa
    INDEX tablctrl110-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL110_mark INPUT

*&spwizard: input module for tc 'TABLCTRL110'. do not change this line!
*&spwizard: process user command
MODULE tablctrl110_user_command INPUT.
  """""""""
  """""""""""""""
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL110'
                              'G_TABLCTRL110_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL110_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_110 INPUT.

  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl110-top_line + g_cursor_line - 1.
  g_curr_line_110 = g_curr_line.

ENDMODULE.                 " get_cursor_line_110  INPUT

*&spwizard: input module for tc 'TABLCTRL111'. do not change this line!
*&spwizard: modify table
MODULE tablctrl111_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl111_wa.

  SELECT SINGLE * FROM zpm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  g_tablctrl111_wa-role_desc = zpm_prep_roledes-brief_desc.

  MODIFY g_tablctrl111_itab
    FROM g_tablctrl111_wa
    INDEX tablctrl111-current_line.

  IF sy-subrc <> 0.
    APPEND g_tablctrl111_wa TO g_tablctrl111_itab.
  ENDIF.

  IF g_tablctrl111_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl111_wa-flag.
    APPEND g_tablctrl111_wa TO g_tablctrl111_itab.
  ENDIF.
ENDMODULE.                    "TABLCTRL111_modify INPUT

*&spwizard: input module for tc 'TABLCTRL111'. do not change this line!
*&spwizard: mark table
MODULE tablctrl111_mark INPUT.
  IF tablctrl111-line_sel_mode = 1 AND
     g_tablctrl111_wa-flag = 'X'.
    LOOP AT g_tablctrl111_itab INTO g_tablctrl111_wa
      WHERE flag = 'X'.
      g_tablctrl111_wa-flag = ''.
      MODIFY g_tablctrl111_itab
        FROM g_tablctrl111_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl111_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl111_itab
    FROM g_tablctrl111_wa
    INDEX tablctrl111-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL111_mark INPUT

*&spwizard: input module for tc 'TABLCTRL111'. do not change this line!
*&spwizard: process user command
MODULE tablctrl111_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL111'
                              'G_TABLCTRL111_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL111_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_111  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_111 INPUT.

  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl111-top_line + g_cursor_line - 1.
  g_curr_line_111 = g_curr_line.

ENDMODULE.                 " get_cursor_line_111  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data11  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data11 INPUT.

  SELECT SINGLE * FROM zpm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.

ENDMODULE.                 " validate_lineitem_data11  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data11a  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data11a INPUT.

  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.


**---------- Changes Start date 24.06.2016 11:54:33-------------------
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


    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                 a~persk a~sbmod  c~designo c~r_p_cd c~version
               d~sdesig_text AS designation d~adesig_text AS adesignation
               d~disc_cd AS disc_cd
                 INTO CORRESPONDING FIELDS OF TABLE ist_data
            FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                  ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                     ON c~designo = d~desig_code AND
                         c~r_p_cd  = d~r_p_cd AND
                         c~version = d~version )
                      WHERE a~pernr =  zic_prep_rolereq-userid AND
                            a~sprps = ' ' AND
                            a~endda = '99991231' AND
                            c~sprps = ' ' AND
                            c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:54:33-----------------


    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
      g_ccode = ist_data-bukrs.
    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X'.

    SELECT SINGLE * FROM zpm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      MESSAGE i118(zhelp).
    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
    CLEAR  zic_prep_rolerei-shop_no.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
    CLEAR  zic_prep_rolerei-shop_no.
    CLEAR  zic_prep_rolerei-plant.
  ENDIF.


  g_field = 'ZIC_PREP_ROLEREI-PLANT'.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.


    IF NOT zic_prep_rolerei-plant IS INITIAL.

      SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
                 TABLE it_bukrs  WHERE bukrs =  zic_prep_rolereq-ccode
                                    AND werks = zic_prep_rolerei-plant.
      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-PLANT'.
        g_i = g_curr_line.
        MESSAGE e068(zhelp) WITH zic_prep_rolerei-role_name.

      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-role_name IS INITIAL.

      SELECT * FROM zpm_prep_roledes INTO CORRESPONDING FIELDS OF
                  TABLE it_role.

      IF zic_prep_rolereq-ccode = 'BDW' OR
         zic_prep_rolereq-ccode = 'SBW'.
      ELSE.
        DELETE it_role WHERE role_type = 'PM14' OR
        role_type = 'PM15' OR role_type = 'PM16'.
      ENDIF.

      LOOP AT it_role .
        IF it_role-role_type = zic_prep_rolerei-role_name.
          check_role_flag = 'X'.
        ENDIF.
      ENDLOOP.

      IF check_role_flag = 'X'.
        CLEAR check_role_flag.
      ELSE.
        MESSAGE e164(zhelp) WITH zic_prep_rolerei-role_name
        zic_prep_rolereq-ccode .
      ENDIF.

    ENDIF.

  ENDIF.
ENDMODULE.                 " validate_lineitem_data11a  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno11  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno11 INPUT.

  CLEAR g_srno.
  LOOP AT g_tablctrl111_itab INTO g_tablctrl111_wa.
    g_srno = g_srno + 1.
    g_tablctrl111_wa-srno = g_srno.
    MODIFY g_tablctrl111_itab FROM g_tablctrl111_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl111_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl111_itab  LINES tablctrl111-lines.
  CLEAR g_srno.

ENDMODULE.                 " change_srno11  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_PM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_pm INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

*  TYPES : Begin of z_role_des,
*            role_type like zmm_prep_roledes-role_type,
*            brief_desc like zmm_prep_roledes-brief_desc,
*            DETAIL_DESC1 like zmm_prep_roledes-detail_desc1,
*            DETAIL_DESC2 like zmm_prep_roledes-detail_desc2,
*            sort_field like zmm_prep_roledes-brief_desc,
*            mm_disc_flag like zmm_prep_roledes-mm_disc_flag,
*          end of z_role_des.

*  DATA   : it_role type table of z_role_des with header line.
*

  SELECT * FROM zpm_prep_roledes INTO CORRESPONDING FIELDS OF
             TABLE it_role.

  SORT it_role ASCENDING BY sort_field.

  IF zic_prep_rolereq-ccode = 'BDW' OR
     zic_prep_rolereq-ccode = 'SBW'.
  ELSE.
    DELETE it_role WHERE role_type = 'PM14' OR
    role_type = 'PM15' OR role_type = 'PM16'.
  ENDIF.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZPM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_ROLE_PM  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_SHOP_NO  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_shop_no INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SHOP_NO' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


*  DATA  :  IST_RETURN_TAB LIKE STANDARD TABLE OF DDSHRETVAL
*                                               WITH  HEADER LINE.
  TYPES :
    BEGIN OF ty_shop,
      werks LIKE t357-werks,
      beber LIKE t357-beber,
      fing  LIKE t357-fing,
    END OF ty_shop.

  DATA   : it_shop TYPE TABLE OF ty_shop WITH HEADER LINE.

  SELECT * FROM t357 INTO CORRESPONDING FIELDS OF
             TABLE it_shop  WHERE werks =  '53C1' OR
                                  werks =  '24C1'.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BEBER'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SHOP_NO'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_shop
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_bukrs,ist_return_tab.
  FREE : it_bukrs,ist_return_tab.

ENDMODULE.                 " POV_SHOP_NO  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_MODULEID  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_moduleid INPUT.

  DATA : it_module LIKE TABLE OF zic_modules.
  DATA : wa_module LIKE zic_modules.

**  data : l_docno like zic_prep_rolereq-DOCNO.
*  data : l_dynnr like sy-dynnr.
*
*  if sy-dynnr <> '0100'.
*     l_dynnr = '0100'.
*  else.
*     l_dynnr = sy-dynnr.
*  endif.

*  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
*       EXPORTING
*            STRUC = 'ZIC_PREP_ROLEREQ'
*            FIELD = 'DOCNO'
*            REPID = SY-CPROG
*            DYNNR = '0100'
*       IMPORTING
*            VALUE = l_docno.

  l_docno = zic_prep_rolereq-docno.

* clear l_dynnr.

  IF old_ok_code = 'CREATE'  OR
     old_ok_code = 'CROSSCO'  OR
     old_ok_code = 'CRCROLES' OR
     old_ok_code = 'CHANGE'.

    SELECT  moduleid FROM zice_prep_module INTO CORRESPONDING FIELDS
     OF TABLE it_module.

  ELSE.

    SELECT DISTINCT moduleid FROM zic_prep_rolerei INTO
      CORRESPONDING FIELDS OF TABLE it_module WHERE docno = l_docno.

  ENDIF.

  LOOP AT it_module INTO wa_module.
    SELECT SINGLE * FROM zice_prep_module WHERE moduleid =
    wa_module-moduleid.
    wa_module-z_desc = zice_prep_module-z_desc.
    MODIFY it_module FROM wa_module.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MODULEID'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'MODULEID'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_module
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_module,ist_return_tab.
  FREE  : it_module,ist_return_tab.

ENDMODULE.                 " POV_MODULEID  INPUT

*&spwizard: input module for tc 'TABLCTRL112'. do not change this line!
*&spwizard: modify table
MODULE tablctrl112_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl112_wa.
  SELECT SINGLE * FROM zps_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
*       g_val_err = 'X'.
*       message i102(zhelp) with zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  g_tablctrl112_wa-role_desc = zps_prep_roledes-brief_desc.

  MODIFY g_tablctrl112_itab
   FROM g_tablctrl112_wa
   INDEX tablctrl112-current_line.
  IF sy-subrc <> 0.
    APPEND g_tablctrl112_wa TO g_tablctrl112_itab.
  ENDIF.

  IF g_tablctrl112_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl112_wa-flag.
    APPEND g_tablctrl112_wa TO g_tablctrl112_itab.
  ENDIF.

ENDMODULE.                    "TABLCTRL112_modify INPUT

*&spwizard: input module for tc 'TABLCTRL112'. do not change this line!
*&spwizard: mark table
MODULE tablctrl112_mark INPUT.
  IF tablctrl112-line_sel_mode = 1 AND
     g_tablctrl112_wa-flag = 'X'.
    LOOP AT g_tablctrl112_itab INTO g_tablctrl112_wa
      WHERE flag = 'X'.
      g_tablctrl112_wa-flag = ''.
      MODIFY g_tablctrl112_itab
        FROM g_tablctrl112_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl112_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl112_itab
    FROM g_tablctrl112_wa
    INDEX tablctrl112-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL112_mark INPUT

*&spwizard: input module for tc 'TABLCTRL112'. do not change this line!
*&spwizard: process user command
MODULE tablctrl112_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL112'
                              'G_TABLCTRL112_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL112_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_112  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_112 INPUT.
  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl112-top_line + g_cursor_line - 1.
  g_curr_line_112 = g_curr_line.

ENDMODULE.                 " get_cursor_line_112  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data12  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data12 INPUT.

  IF NOT zic_prep_rolerei-role_name IS INITIAL.

    SELECT SINGLE * FROM zps_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

    IF g_role_name_prev <> zic_prep_rolerei-role_name AND
                NOT g_role_name_prev IS INITIAL.
      g_role_name_flag = 'X'.
    ENDIF.
    g_read_fl = 'X'.

  ENDIF.
ENDMODULE.                 " validate_lineitem_data12  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data12a  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data12a INPUT.
  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.

**---------- Changes Start date 24.06.2016 11:54:00-------------------
*  SELECT A~PERNR A~BEGDA A~ENDDA A~ENAME AS NAME A~BUKRS  A~WERKS
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


    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                   a~persk a~sbmod  c~designo c~r_p_cd c~version
                 d~sdesig_text AS designation d~adesig_text AS adesignation
                 d~disc_cd AS disc_cd
                   INTO CORRESPONDING FIELDS OF TABLE ist_data
              FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                    ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                       ON c~designo = d~desig_code AND
                           c~r_p_cd  = d~r_p_cd AND
                           c~version = d~version )
                        WHERE a~pernr =  zic_prep_rolereq-userid AND
                              a~sprps = ' ' AND
                              a~endda = '99991231' AND
                              c~sprps = ' ' AND
                              c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:54:00-----------------


    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
      g_ccode = ist_data-bukrs.
    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X' AND NOT zic_prep_rolerei-role_name IS INITIAL
     AND NOT zic_prep_rolerei-service IS INITIAL.

    SELECT SINGLE * FROM zps_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      MESSAGE i118(zhelp).
    ELSE.
      g_field = 'ZIC_PREP_ROLEREI-PROJECT'.
    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
*  clear  ZIC_PREP_ROLEREI-SERVICE.
    CLEAR  zic_prep_rolerei-project.
    CLEAR  zic_prep_rolerei-location.
*  clear  ZIC_PREP_ROLEREI-REGION.
    CLEAR  zic_prep_rolerei-asset.
    CLEAR  zic_prep_rolerei-basin.
    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
*      clear  ZIC_PREP_ROLEREI-SERVICE.
    CLEAR  zic_prep_rolerei-project.
    CLEAR  zic_prep_rolerei-location.
*      clear  ZIC_PREP_ROLEREI-REGION.
    CLEAR  zic_prep_rolerei-asset.
    CLEAR  zic_prep_rolerei-basin.
  ENDIF.


  g_field = 'ZIC_PREP_ROLEREI-SERVICE'.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.


    IF NOT zic_prep_rolerei-service IS INITIAL.

      SELECT * FROM zps_prep_service INTO CORRESPONDING FIELDS OF
                 TABLE it_service WHERE
                 service = zic_prep_rolerei-service.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-SERVICE'.
        g_i = g_curr_line_112.
        MESSAGE e169(zhelp) WITH zic_prep_rolerei-role_name.
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-project IS INITIAL.

      SELECT * FROM zps_prep_project INTO CORRESPONDING FIELDS OF
                 TABLE it_project WHERE
                 service = zic_prep_rolerei-service AND
                 project = zic_prep_rolerei-project.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-PROJECT'.
        g_i = g_curr_line.
        MESSAGE e170(zhelp) WITH zic_prep_rolerei-project.
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-location IS INITIAL.

      SELECT * FROM zps_prep_loca INTO CORRESPONDING FIELDS OF
             TABLE it_loca WHERE ccode = zic_prep_rolereq-ccode
             AND location = zic_prep_rolerei-location AND
             service = zic_prep_rolerei-service.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-LOCATION'.
        g_i = g_curr_line.
        MESSAGE e171(zhelp) WITH zic_prep_rolerei-location.
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-asset IS INITIAL.

      IF zic_prep_rolereq-ccode = 'MUM'.
        SELECT * FROM zps_prep_asst_ex INTO CORRESPONDING FIELDS OF
              TABLE it_asset WHERE ccode = 'MUM' AND
                    asset = zic_prep_rolerei-asset.

        IF sy-subrc <> 0 AND zic_prep_rolerei-asset <> 'ALL'.
          g_e_fl = 'X'.
          g_field = 'ZIC_PREP_ROLEREI-ASSET'.
          g_i = g_curr_line.
          MESSAGE e172(zhelp) WITH zic_prep_rolerei-asset.
        ENDIF.

      ELSE.
        IF zic_prep_rolerei-asset <> zic_prep_rolereq-ccode AND
           zic_prep_rolerei-asset <> 'ALL'.
          g_e_fl = 'X'.
          g_field = 'ZIC_PREP_ROLEREI-ASSET'.
          g_i = g_curr_line.
          MESSAGE e172(zhelp) WITH zic_prep_rolerei-asset.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT zic_prep_rolerei-basin IS INITIAL.

      IF zic_prep_rolerei-basin <> zic_prep_rolereq-ccode AND
          zic_prep_rolerei-basin <> 'ALL'.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-BASIN'.
        g_i = g_curr_line.
        MESSAGE e173(zhelp) WITH zic_prep_rolerei-basin.
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-role_name IS INITIAL AND
           NOT zic_prep_rolerei-service IS INITIAL.

      IF zic_prep_rolerei-service <> 'P1' AND zic_prep_rolerei-service <> 'P2' AND zic_prep_rolerei-service <> 'P3' OR zic_prep_rolerei-service <> 'PS'.
        SELECT SINGLE * FROM zps_prep_serv_rl WHERE
                       service = zic_prep_rolerei-service AND
                       role_type = zic_prep_rolerei-role_name.

        IF sy-subrc <> 0.
          MESSAGE e201(zhelp) WITH zic_prep_rolerei-role_name.
        ENDIF.
      ENDIF.


*     select * from zps_prep_roledes into corresponding fields of
*                 table it_role.
*
*     loop at it_role .
*        if it_role-role_type = zic_prep_rolerei-role_name.
*           check_role_flag = 'X'.
*        endif.
*     endloop.
*
*     if check_role_flag = 'X'.
*        clear check_role_flag.
*     else.
*        message e164(zhelp) with ZIC_PREP_ROLEREI-role_name
*        ZIC_PREP_ROLEREQ-ccode .
*     endif.

    ENDIF.

  ENDIF.

ENDMODULE.                 " validate_lineitem_data12a  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno12  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno12 INPUT.
  CLEAR g_srno.
  LOOP AT g_tablctrl112_itab INTO g_tablctrl112_wa.
    g_srno = g_srno + 1.
    g_tablctrl112_wa-srno = g_srno.
    MODIFY g_tablctrl112_itab FROM g_tablctrl112_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl112_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl112_itab  LINES tablctrl112-lines.
  CLEAR g_srno.
ENDMODULE.                 " change_srno12  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_PS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_ps INPUT.

  DATA : l_service LIKE zic_prep_rolerei-service.
  DATA : g_fldval TYPE zps_prep_roledes-role_type.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  DATA: BEGIN OF seltab OCCURS 0,
          sign(1),
          option(2),
          low       LIKE zic_prep_rolerei-role_name,
          high      LIKE zic_prep_rolerei-role_name,
        END OF seltab.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SERVICE'
      index = loop_step
      repid = sy-cprog
      dynnr = '0112'
    IMPORTING
      value = l_service.

  IF l_service = 'P1' OR l_service = 'P2' OR l_service = 'P3' OR l_service = 'PS'.

    IF l_service = 'P1'.
      CONCATENATE  'BU' '%' INTO g_fldval.   " PRA Module changes
    ELSEIF l_service = 'P2'.
      CONCATENATE  'APP' '%' INTO g_fldval.   " PRA Module changes
    ELSEIF l_service = 'P3'.
      CONCATENATE  'CP' '%' INTO g_fldval.   " PRA Module changes
    ELSEIF l_service = 'PS'.
      CONCATENATE  'PS' '%' INTO g_fldval.   " PRA Module changes
    ENDIF.
    SELECT * FROM zps_prep_roledes INTO CORRESPONDING FIELDS OF
                TABLE it_role WHERE role_type LIKE g_fldval.

  ELSE.
    SELECT * FROM zps_prep_serv_rl INTO CORRESPONDING FIELDS OF
          TABLE it_role WHERE service = l_service.

    LOOP AT it_role.

      seltab-sign   = 'I'.
      seltab-option = 'EQ'.
      seltab-low    = it_role-role_type.
      APPEND seltab.

    ENDLOOP.

    SELECT * FROM zps_prep_roledes INTO CORRESPONDING FIELDS OF
                TABLE it_role WHERE role_type IN seltab.
  ENDIF.


  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZPS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab, seltab.
  FREE  : it_role,ist_return_tab, g_field_tab, seltab.
  CLEAR : g_field_wa.



ENDMODULE.                 " POV_ROLE_PS  INPUT
*&---------------------------------------------------------------------*
*&      Module  dummy  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE dummy INPUT.
  PERFORM check_module_fi.
  IF NOT old_moduleid IS INITIAL AND old_moduleid <> moduleid AND
*    old_ok_code = 'CHANGE'.
**13/04/07
     ( old_ok_code = 'CHANGE' OR old_ok_code = 'APPROVE' ).
    okcode_100 = 'SAV'.
    new_moduleid = moduleid.
    moduleid = old_moduleid.
    module_changed_flag = 'X'.
    CLEAR old_moduleid.
  ENDIF.
ENDMODULE.                 " dummy  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_SERVIVES_PS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_servises_ps INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SERVICE' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

*  DATA  :  IST_RETURN_TAB LIKE STANDARD TABLE OF DDSHRETVAL
*                                               WITH  HEADER LINE.
*  DATA   : it_service type table of zps_prep_service with header line.

  SELECT * FROM zps_prep_service INTO CORRESPONDING FIELDS OF
             TABLE it_service.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SERVICE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SERVICE'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_service
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_service,ist_return_tab.
  FREE : it_service,ist_return_tab.

ENDMODULE.                 " POV_SERVIVES_PS  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_PROJECTS_PS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_projects_ps INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-PROJECT' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

*  data : loop_step like sy-stepl.
*  Data : l_service like ZIC_PREP_ROLEREI-SERVICE.
*
  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SERVICE'
      index = loop_step
      repid = sy-cprog
      dynnr = '0112'
    IMPORTING
      value = l_service.

*  DATA  :  IST_RETURN_TAB LIKE STANDARD TABLE OF DDSHRETVAL
*                                               WITH  HEADER LINE.
*  DATA   : it_project type table of zps_prep_project with header line.

  SELECT * FROM zps_prep_project INTO CORRESPONDING FIELDS OF
             TABLE it_project WHERE service = l_service.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PROJECT'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-PROJECT'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_project
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_project,ist_return_tab.
  FREE : it_project,ist_return_tab.

ENDMODULE.                 " POV_PROJECTS_PS  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ASSET_PS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_asset_ps INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ASSET' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SERVICE'
      index = loop_step
      repid = sy-cprog
      dynnr = '0112'
    IMPORTING
      value = l_service.

*  types :
*        begin of asset_ty,
*              ccode type ZIC_PREP_ROLEREQ-CCODE,
*              asset type ZIC_PREP_ROLEREI-BASIN,
*              a_desc type Zchar80,
*        end of asset_ty.

*  DATA  :  IST_RETURN_TAB LIKE STANDARD TABLE OF DDSHRETVAL
*                                               WITH  HEADER LINE.
*  DATA   : it_asset type table of asset_ty with header line.

  IF zic_prep_rolereq-ccode = 'MUM'.
    SELECT * FROM zps_prep_asst_ex INTO CORRESPONDING FIELDS OF TABLE
              it_asset.
  ELSE.
    MOVE zic_prep_rolereq-ccode TO it_asset-asset.
    MOVE zic_prep_rolereq-ccode TO it_asset-ccode.
    APPEND it_asset.
  ENDIF.
  MOVE 'ALL'                  TO it_asset-asset.
  MOVE 'ALL'                  TO it_asset-ccode.
  MOVE 'ALL'                  TO it_asset-a_desc.

  IF l_service <> 'WS'.
    APPEND it_asset.
  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ASSET'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ASSET'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_asset
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_asset,ist_return_tab.
  FREE  : it_asset,ist_return_tab.
  CLEAR : it_asset.

ENDMODULE.                 " POV_ASSET_PS  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_BASIN_PS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_basin_ps INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-BASIN' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

*  types :
*        begin of basin_ty,
*              ccode type ZIC_PREP_ROLEREQ-CCODE,
*              basin type ZIC_PREP_ROLEREI-BASIN,
*              b_desc type Zchar80,
*        end of basin_ty.

*  DATA  :  IST_RETURN_TAB LIKE STANDARD TABLE OF DDSHRETVAL
*                                               WITH  HEADER LINE.
*  DATA   : it_basin type table of basin_ty with header line.

  MOVE zic_prep_rolereq-ccode TO it_basin-basin.
  MOVE zic_prep_rolereq-ccode TO it_basin-ccode.
  SELECT SINGLE * FROM t001 WHERE bukrs = zic_prep_rolereq-ccode.
  MOVE t001-butxt TO it_basin-b_desc.
  APPEND it_basin.
  MOVE 'ALL'                  TO it_basin-basin.
  MOVE 'ALL'                  TO it_basin-ccode.
  MOVE 'ALL'                  TO it_basin-b_desc.
  APPEND it_basin.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BASIN'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-BASIN'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_basin
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_basin,ist_return_tab.
  FREE : it_basin,ist_return_tab.

ENDMODULE.                 " POV_BASIN_PS  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_LOCATION_PS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_location_ps INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-LOCATION' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SERVICE'
      index = loop_step
      repid = sy-cprog
      dynnr = '0112'
    IMPORTING
      value = l_service.

*  DATA  :  IST_RETURN_TAB LIKE STANDARD TABLE OF DDSHRETVAL
*                                               WITH  HEADER LINE.
*  DATA   : it_location type table of zps_prep_loc with header line.

  SELECT * FROM zps_prep_loca INTO CORRESPONDING FIELDS OF
             TABLE it_loca WHERE service = l_service AND
             ccode = zic_prep_rolereq-ccode.

*  if l_service = 'RD' and zic_prep_rolereq-ccode = 'AMD'.
*     clear it_location.
*     refresh it_location[].
*     it_location-ccode = zic_prep_rolereq-ccode.
*     it_location-location = 'IR'.
*     it_location-l_desc = 'INSTITUTE OF RESERVOIR STUDIES'.
*     append it_location.
*  else.
*  endif.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LOCATION'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-LOCATION'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_loca
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_loca,ist_return_tab.
  FREE : it_loca,ist_return_tab.

ENDMODULE.                 " POV_LOCATION_PS  INPUT

*&spwizard: input module for tc 'TABLCTRL113'. do not change this line!
*&spwizard: modify table
MODULE tablctrl113_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl113_wa.

  SELECT SINGLE * FROM zpp_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  g_tablctrl113_wa-role_desc = zpp_prep_roledes-brief_desc.

  MODIFY g_tablctrl113_itab
  FROM g_tablctrl113_wa
  INDEX tablctrl113-current_line.

  IF sy-subrc <> 0.
    APPEND g_tablctrl113_wa TO g_tablctrl113_itab.
  ENDIF.

  IF g_tablctrl113_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl113_wa-flag.
    APPEND g_tablctrl113_wa TO g_tablctrl113_itab.
  ENDIF.

ENDMODULE.                    "TABLCTRL113_modify INPUT

*&spwizard: input module for tc 'TABLCTRL113'. do not change this line!
*&spwizard: mark table
MODULE tablctrl113_mark INPUT.
  IF tablctrl113-line_sel_mode = 1 AND
     g_tablctrl113_wa-flag = 'X'.
    LOOP AT g_tablctrl113_itab INTO g_tablctrl113_wa
      WHERE flag = 'X'.
      g_tablctrl113_wa-flag = ''.
      MODIFY g_tablctrl113_itab
        FROM g_tablctrl113_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl113_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl113_itab
    FROM g_tablctrl113_wa
    INDEX tablctrl113-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL113_mark INPUT

*&spwizard: input module for tc 'TABLCTRL113'. do not change this line!
*&spwizard: process user command
MODULE tablctrl113_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL113'
                              'G_TABLCTRL113_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL113_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_113  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_113 INPUT.

  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl113-top_line + g_cursor_line - 1.
  g_curr_line_113 = g_curr_line.

ENDMODULE.                 " get_cursor_line_113  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data13  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data13 INPUT.

  SELECT SINGLE * FROM zpp_prep_roledes WHERE role_type =
                  zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.

ENDMODULE.                 " validate_lineitem_data13  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data13a  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data13a INPUT.

  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.

**---------- Changes Start date 24.06.2016 11:52:12-------------------
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

    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                 a~persk a~sbmod  c~designo c~r_p_cd c~version
               d~sdesig_text AS designation d~adesig_text AS adesignation
               d~disc_cd AS disc_cd
                 INTO CORRESPONDING FIELDS OF TABLE ist_data
            FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                  ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                     ON c~designo = d~desig_code AND
                         c~r_p_cd  = d~r_p_cd AND
                         c~version = d~version )
                      WHERE a~pernr =  zic_prep_rolereq-userid AND
                            a~sprps = ' ' AND
                            a~endda = '99991231' AND
                            c~sprps = ' ' AND
                            c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:52:12-----------------


    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
      g_ccode = ist_data-bukrs.
    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X'.

    SELECT SINGLE * FROM zpp_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      MESSAGE i118(zhelp).
    ELSE.
      g_field = 'ZIC_PREP_ROLEREI-PLANT'.
    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR  zic_prep_rolerei-sloc.
    CLEAR  zic_prep_rolerei-res.
    CLEAR  zic_prep_rolerei-ctf_sloc.
    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR  zic_prep_rolerei-sloc.
    CLEAR  zic_prep_rolerei-res.
    CLEAR  zic_prep_rolerei-ctf_sloc.
  ENDIF.


  g_field = 'ZIC_PREP_ROLEREI-PLANT'.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.


    IF NOT zic_prep_rolerei-plant IS INITIAL.

      SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
                     TABLE it_bukrs  WHERE bukrs =  zic_prep_rolereq-ccode
                                        AND werks = zic_prep_rolerei-plant.
      IF sy-subrc = 0.

        SELECT SINGLE * FROM zhelp_pproles1 INTO CORRESPONDING FIELDS OF
                             zhelp_pproles1 WHERE
                             role_type = zic_prep_rolerei-role_name AND
                             plant     = zic_prep_rolerei-plant.

        IF sy-subrc <> 0.

          SELECT SINGLE * FROM zpp_prep_generic INTO CORRESPONDING FIELDS OF
                               zpp_prep_generic WHERE
                               role_type = zic_prep_rolerei-role_name AND
                               plant     = zic_prep_rolerei-plant.
          IF sy-subrc <> 0.
            g_e_fl = 'X'.
            g_field = 'ZIC_PREP_ROLEREI-PLANT'.
            g_i = g_curr_line_113.
            MESSAGE e195(zhelp) WITH zic_prep_rolerei-role_name.
          ENDIF.

        ENDIF.
      ELSE.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-PLANT'.
        g_i = g_curr_line_113.
        MESSAGE e068(zhelp) WITH zic_prep_rolerei-role_name.


      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-sloc IS INITIAL.

      SELECT SINGLE * FROM t001l INTO CORRESPONDING FIELDS OF
               it_t001l  WHERE werks = zic_prep_rolerei-plant
               AND lgort = zic_prep_rolerei-sloc.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-SLOC'.
        g_i = g_curr_line.
        MESSAGE e073(zhelp) WITH zic_prep_rolerei-sloc.
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-res IS INITIAL.

      SELECT SINGLE * FROM zpp_prep_res INTO CORRESPONDING FIELDS OF
             it_res  WHERE role_type = zic_prep_rolerei-role_name
             AND
             plant = zic_prep_rolerei-plant
             AND
             res = zic_prep_rolerei-res.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-RES'.
        g_i = g_curr_line.
        MESSAGE e183(zhelp) WITH zic_prep_rolerei-res.

      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-ctf_sloc IS INITIAL.

      SELECT SINGLE * FROM zpp_prep_droleex WHERE role_type =
          zic_prep_rolerei-role_name
          AND plant = zic_prep_rolerei-plant
          AND sloc = zic_prep_rolerei-sloc
          AND ctf_sloc = zic_prep_rolerei-ctf_sloc.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-CTF_SLOC'.
        g_i = g_curr_line.
        MESSAGE e073(zhelp) WITH zic_prep_rolerei-ctf_sloc.

      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-role_name IS INITIAL.

      SELECT * FROM zpp_prep_roledes INTO CORRESPONDING FIELDS OF
                  TABLE it_role.

      LOOP AT it_role .
        IF it_role-role_type = zic_prep_rolerei-role_name.
          check_role_flag = 'X'.
        ENDIF.
      ENDLOOP.

      IF check_role_flag = 'X'.
        CLEAR check_role_flag.
      ELSE.
        MESSAGE e164(zhelp) WITH zic_prep_rolerei-role_name
        zic_prep_rolereq-ccode .
      ENDIF.

    ENDIF.

  ENDIF.

ENDMODULE.                 " validate_lineitem_data13a  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno13  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno13 INPUT.

  CLEAR g_srno.
  LOOP AT g_tablctrl113_itab INTO g_tablctrl113_wa.
    g_srno = g_srno + 1.
    g_tablctrl113_wa-srno = g_srno.
    MODIFY g_tablctrl113_itab FROM g_tablctrl113_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl113_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl113_itab  LINES tablctrl113-lines.
  CLEAR g_srno.

ENDMODULE.                 " change_srno13  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_PP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_pp INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


  SELECT * FROM zpp_prep_roledes INTO CORRESPONDING FIELDS OF
             TABLE it_role.

  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZPP_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPP_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPP_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZPP_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_ROLE_PP  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_PLANT_PP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_plant_pp INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
             TABLE it_bukrs  WHERE bukrs =  zic_prep_rolereq-ccode.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'WERKS'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-PLANT'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_bukrs
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_bukrs,ist_return_tab.
  FREE : it_bukrs,ist_return_tab.

ENDMODULE.                 " POV_PLANT_PP  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_SLOC_PP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_sloc_pp INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SLOC' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'PLANT'
      index = loop_step
      repid = sy-cprog
      dynnr = '0113'
    IMPORTING
      value = l_plant.

  SELECT * FROM t001l INTO CORRESPONDING FIELDS OF
             TABLE it_t001l  WHERE werks = l_plant.

************************************
  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'WERKS'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGORT'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGOBE'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LGORT'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SLOC'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_t001l
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_t001l,ist_return_tab,g_field_tab..
  FREE  : it_t001l,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.


ENDMODULE.                 " POV_SLOC_PP  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_RES_PP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_res_pp INPUT.

  DATA : l_role_type LIKE zic_prep_rolerei-role_name .

  LOOP AT SCREEN.
    IF screen-name = 'ZIC_PREP_ROLEREI-RES' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0113'
    IMPORTING
      value = l_role_type.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'PLANT'
      index = loop_step
      repid = sy-cprog
      dynnr = '0113'
    IMPORTING
      value = l_plant.

  SELECT * FROM zpp_prep_res INTO CORRESPONDING FIELDS OF
             TABLE it_res  WHERE role_type = l_role_type AND
             plant = l_plant..

************************************
  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'RES'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-RES'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_res
*     FIELD_TAB       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_res,ist_return_tab,g_field_tab..
  FREE  : it_res,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_RES_PP  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_CTF_SLOC_PP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_ctf_sloc_pp INPUT.

  DATA : l_sloc LIKE zic_prep_rolerei-sloc .

  LOOP AT SCREEN.
    IF screen-name = 'ZIC_PREP_ROLEREI-CTF_SLOC' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0113'
    IMPORTING
      value = l_role_type.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'PLANT'
      index = loop_step
      repid = sy-cprog
      dynnr = '0113'
    IMPORTING
      value = l_plant.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SLOC'
      index = loop_step
      repid = sy-cprog
      dynnr = '0113'
    IMPORTING
      value = l_sloc.

***********************************

  SELECT SINGLE * FROM zpp_prep_droleex WHERE role_type = l_role_type
         AND plant = l_plant AND sloc = l_sloc.

  IF sy-subrc = 0.

    CONCATENATE 'LGORT'  'LIKE'  INTO g_line SEPARATED BY
    space.
    CONCATENATE g_line+0(10) '''' '%Z%' ''''  INTO
                g_line.
    APPEND g_line TO it_cond.

    SELECT * FROM t001l INTO CORRESPONDING FIELDS OF
               TABLE it_t001l  WHERE werks = l_plant AND
               (it_cond).
  ENDIF.
***********************************
  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'WERKS'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGORT'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGOBE'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LGORT'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SLOC'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_t001l
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_t001l,ist_return_tab,g_field_tab..
  FREE  : it_t001l,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_CTF_SLOC_PP  INPUT

*&spwizard: input module for tc 'TABLCTRL114'. do not change this line!
*&spwizard: modify table
MODULE tablctrl114_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl114_wa.

  SELECT SINGLE * FROM zsd_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  g_tablctrl114_wa-role_desc = zpp_prep_roledes-brief_desc.

  MODIFY g_tablctrl114_itab
    FROM g_tablctrl114_wa
    INDEX tablctrl114-current_line.

  IF sy-subrc <> 0.
    APPEND g_tablctrl114_wa TO g_tablctrl114_itab.
  ENDIF.

  IF g_tablctrl114_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl114_wa-flag.
    APPEND g_tablctrl114_wa TO g_tablctrl114_itab.
  ENDIF.

ENDMODULE.                    "TABLCTRL114_modify INPUT

*&spwizard: input module for tc 'TABLCTRL114'. do not change this line!
*&spwizard: mark table
MODULE tablctrl114_mark INPUT.
  IF tablctrl114-line_sel_mode = 1 AND
     g_tablctrl114_wa-flag = 'X'.
    LOOP AT g_tablctrl114_itab INTO g_tablctrl114_wa
      WHERE flag = 'X'.
      g_tablctrl114_wa-flag = ''.
      MODIFY g_tablctrl114_itab
        FROM g_tablctrl114_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl114_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl114_itab
    FROM g_tablctrl114_wa
    INDEX tablctrl114-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL114_mark INPUT

*&spwizard: input module for tc 'TABLCTRL114'. do not change this line!
*&spwizard: process user command
MODULE tablctrl114_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL114'
                              'G_TABLCTRL114_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL114_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_114  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_114 INPUT.

  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl114-top_line + g_cursor_line - 1.
  g_curr_line_114 = g_curr_line.

ENDMODULE.                 " get_cursor_line_114  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data14  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data14 INPUT.

  SELECT SINGLE * FROM zsd_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.

ENDMODULE.                 " validate_lineitem_data14  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data14a  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data14a INPUT.
  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.

**---------- Changes Start date 24.06.2016 11:51:22-------------------
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


    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                a~persk a~sbmod  c~designo c~r_p_cd c~version
              d~sdesig_text AS designation d~adesig_text AS adesignation
              d~disc_cd AS disc_cd
                INTO CORRESPONDING FIELDS OF TABLE ist_data
           FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                 ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                    ON c~designo = d~desig_code AND
                        c~r_p_cd  = d~r_p_cd AND
                        c~version = d~version )
                     WHERE a~pernr =  zic_prep_rolereq-userid AND
                           a~sprps = ' ' AND
                           a~endda = '99991231' AND
                           c~sprps = ' ' AND
                           c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:51:22-----------------


    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
      g_ccode = ist_data-bukrs.
    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X'.

    SELECT SINGLE * FROM zsd_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name AND
                    disc_fi_fl = zic_prep_rolereq-disc_fi_flag.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      IF zic_prep_rolereq-disc_fi_flag = 'X' AND
      zic_prep_rolerei-role_name = 'SXX'.
      ELSE.
        MESSAGE i118(zhelp).
      ENDIF.
    ELSE.
      g_field = 'ZIC_PREP_ROLEREI-PLANT'.
    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
    CLEAR  zic_prep_rolerei-sale_org.
    CLEAR  zic_prep_rolerei-div.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR  zic_prep_rolerei-ship_point.
    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
    CLEAR  zic_prep_rolerei-sale_org.
    CLEAR  zic_prep_rolerei-div.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR  zic_prep_rolerei-ship_point.
  ENDIF.


  g_field = 'ZIC_PREP_ROLEREI-PLANT'.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.


    IF NOT zic_prep_rolerei-plant IS INITIAL.

      SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
                     TABLE it_bukrs  WHERE bukrs =  zic_prep_rolereq-ccode
                                        AND werks = zic_prep_rolerei-plant.
      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-PLANT'.
        g_i = g_curr_line_114.
        MESSAGE e068(zhelp) WITH zic_prep_rolerei-role_name.
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-sale_org IS INITIAL.

      SELECT SINGLE * FROM tvko CLIENT SPECIFIED INTO CORRESPONDING FIELDS
               OF it_tvko  WHERE mandt = sy-mandt AND
               bukrs =  zic_prep_rolereq-ccode AND
               vkorg = zic_prep_rolerei-sale_org.

      IF sy-subrc <> 0 AND zic_prep_rolerei-sale_org <> 'ALL'.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-SALE_ORG'.
        g_i = g_curr_line_114.
        MESSAGE e186(zhelp) WITH zic_prep_rolerei-sale_org.
***
      ELSEIF zic_prep_rolereq-ccode = 'MUM' AND
             ( zic_prep_rolereq-fundc1 = 'MUMPHPOP' OR
             zic_prep_rolereq-fundc1 = 'MUMPHPSP' )  AND    "18092015
              zic_prep_rolerei-sale_org <> 'HZRS'.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-SALE_ORG'.
        g_i = g_curr_line_114.
        MESSAGE e186(zhelp) WITH zic_prep_rolerei-sale_org.
      ELSE.
        IF zic_prep_rolereq-ccode = 'MUM' AND
        zic_prep_rolereq-fundc1 <> 'MUMPHPOP' AND
          zic_prep_rolereq-fundc1 <> 'MUMPHPSP' AND         "18092015
        zic_prep_rolerei-sale_org = 'HZRS'.
          g_e_fl = 'X'.
          g_field = 'ZIC_PREP_ROLEREI-SALE_ORG'.
          g_i = g_curr_line_114.
          MESSAGE e186(zhelp) WITH zic_prep_rolerei-sale_org.
        ENDIF.
***
      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-div IS INITIAL.

      SELECT SINGLE * FROM tvkos CLIENT SPECIFIED INTO CORRESPONDING
               FIELDS OF it_tvkos  WHERE mandt = sy-mandt AND
               vkorg =  zic_prep_rolerei-sale_org AND
               spart =  zic_prep_rolerei-div.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-DIV'.
        g_i = g_curr_line_114.
        MESSAGE e187(zhelp) WITH zic_prep_rolerei-div.

      ENDIF.

    ENDIF.


    IF NOT zic_prep_rolerei-ship_point IS INITIAL.

      SELECT SINGLE * FROM tvswz INTO CORRESPONDING FIELDS OF
            it_tvswz  WHERE werks = zic_prep_rolerei-plant AND
            vstel = zic_prep_rolerei-ship_point.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-SHIP_POINT'.
        g_i = g_curr_line.
        MESSAGE e188(zhelp) WITH zic_prep_rolerei-ship_point.

      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-role_name IS INITIAL.

*      SELECT * FROM ZSD_PREP_ROLEDES INTO CORRESPONDING FIELDS OF
*               TABLE IT_ROLE WHERE
*                  DISC_FI_FL = ZIC_PREP_ROLEREQ-DISC_FI_FLAG.
*      LOOP AT IT_ROLE .
*        IF IT_ROLE-ROLE_TYPE = ZIC_PREP_ROLEREI-ROLE_NAME.
*          CHECK_ROLE_FLAG = 'X'.
*        ENDIF.
*      ENDLOOP.
*
*      IF ZIC_PREP_ROLEREQ-DISC_FI_FLAG = 'X' AND
*      ZIC_PREP_ROLEREI-ROLE_NAME = 'SXX'.
*        CHECK_ROLE_FLAG = 'X'.
*      ENDIF.
*
*      IF CHECK_ROLE_FLAG = 'X'.
*        CLEAR CHECK_ROLE_FLAG.
*      ELSE.
*        MESSAGE E164(ZHELP) WITH ZIC_PREP_ROLEREI-ROLE_NAME
*        ZIC_PREP_ROLEREQ-CCODE .
*      ENDIF.

    ENDIF.

  ENDIF.

ENDMODULE.                 " validate_lineitem_data14a  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno14  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno14 INPUT.

  CLEAR g_srno.
  LOOP AT g_tablctrl114_itab INTO g_tablctrl114_wa.
    g_srno = g_srno + 1.
    g_tablctrl114_wa-srno = g_srno.
    MODIFY g_tablctrl114_itab FROM g_tablctrl114_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl114_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl114_itab  LINES tablctrl114-lines.
  CLEAR g_srno.

ENDMODULE.                 " change_srno14  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_SD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_sd INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


  SELECT * FROM zsd_prep_roledes INTO CORRESPONDING FIELDS OF
             TABLE it_role.

  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZSD_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZSD_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZSD_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZSD_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_ROLE_SD  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_PLANT_SD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_plant_sd INPUT.

  DATA : l_vkorg LIKE tvkwz-vkorg.
  DATA : l_div LIKE zic_prep_rolerei-div.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SALE_ORG'
      index = loop_step
      repid = sy-cprog
      dynnr = '0114'
    IMPORTING
      value = l_vkorg.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'DIV'
      index = loop_step
      repid = sy-cprog
      dynnr = '0114'
    IMPORTING
      value = l_div.

  DATA : it_tvkwz LIKE TABLE OF tvkwz WITH HEADER LINE.

*  select * from zd_t001w_bukrs into corresponding fields of
*             table it_bukrs  where bukrs =  ZIC_PREP_ROLEREQ-CCODE.

  SELECT * FROM TVTA INTO CORRESPONDING FIELDS OF TVTA UP TO 1 ROWS
 WHERE VKORG = L_VKORG AND SPART = L_DIV
 ORDER BY PRIMARY KEY .
 ENDSELECT.

  SELECT * FROM tvkwz INTO CORRESPONDING FIELDS OF
             TABLE it_tvkwz  WHERE vkorg =  l_vkorg
             AND vtweg = tvta-vtweg.
    sort it_tvkwz by werks.
  DELETE ADJACENT DUPLICATES FROM it_tvkwz COMPARING werks.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'TVKWZ'.
  g_field_wa-fieldname = 'VKORG'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'TVKWZ'.
  g_field_wa-fieldname = 'WERKS'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'WERKS'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-PLANT'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_tvkwz
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_tvkwz,ist_return_tab,g_field_tab.
  FREE : it_tvkwz,ist_return_tab,g_field_tab.

ENDMODULE.                 " POV_PLANT_SD  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_SALE_ORG_SD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_sale_org_sd INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SALE_ORG' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0114'
    IMPORTING
      value = l_role_type.

  SELECT * FROM tvko CLIENT SPECIFIED INTO CORRESPONDING FIELDS OF
             TABLE it_tvko  WHERE mandt = sy-mandt AND
             bukrs =  zic_prep_rolereq-ccode.

  IF zic_prep_rolereq-ccode = 'MUM'.
    LOOP AT it_tvko.
      IF zic_prep_rolereq-fundc1 = 'MUMPHPOP' OR zic_prep_rolereq-fundc1 = 'MUMPHPSP'.   "18092015 OR ADDED
        IF it_tvko-vkorg = 'HZRS'.
        ELSE.
          DELETE it_tvko.
        ENDIF.
      ELSE.
        IF it_tvko-vkorg = 'HZRS'.
          DELETE it_tvko.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF l_role_type = 'SXX'.
    it_tvko-vkorg = 'ALL'.
    it_tvko-bukrs = 'ALL'.
    APPEND it_tvko.
  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'TVKO'.
  g_field_wa-fieldname = 'VKORG'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'TVKO'.
  g_field_wa-fieldname = 'BUKRS'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VKORG'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SALE_ORG'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_tvko
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_tvko,ist_return_tab,g_field_tab.
  FREE : it_tvko,ist_return_tab,g_field_tab.


ENDMODULE.                 " POV_SALE_ORG_SD  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_DIV_SD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_div_sd INPUT.

*  data : l_vkorg like tvkos-vkorg.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-DIV' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'SALE_ORG'
      index = loop_step
      repid = sy-cprog
      dynnr = '0114'
    IMPORTING
      value = l_vkorg.


  SELECT * FROM tvkos CLIENT SPECIFIED INTO CORRESPONDING FIELDS OF
             TABLE it_tvkos  WHERE mandt = sy-mandt AND
             vkorg =  l_vkorg.

*  delete adjacent  duplicates from it_tvkos comparing werks.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'TVKOS'.
  g_field_wa-fieldname = 'VKORG'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'TVKOS'.
  g_field_wa-fieldname = 'SPART'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SPART'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-DIV'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_tvkos
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_tvkos,ist_return_tab,g_field_tab.
  FREE : it_tvkos,ist_return_tab,g_field_tab.

ENDMODULE.                 " POV_DIV_SD  INPUT
*&---------------------------------------------------------------------*
*&      Module  SHIP_POINT_SD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ship_point_sd INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SHIP_POINT' AND screen-input =
0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'PLANT'
      index = loop_step
      repid = sy-cprog
      dynnr = '0114'
    IMPORTING
      value = l_plant.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'DIV'
      index = loop_step
      repid = sy-cprog
      dynnr = '0114'
    IMPORTING
      value = l_div.

*  select * from tvswz into corresponding fields of
*             table it_tvswz  where werks = l_plant.

  SELECT SINGLE * FROM zsd_prep_ldggrp INTO CORRESPONDING FIELDS OF
            zsd_prep_ldggrp  WHERE div = l_div.

  SELECT * FROM tvstz INTO CORRESPONDING FIELDS OF TABLE it_tvstz
           WHERE ladgr = zsd_prep_ldggrp-ladgr AND
           werks = l_plant.

************************************
  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'TVSTZ'.
  g_field_wa-fieldname = 'WERKS'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'TVSTZ'.
  g_field_wa-fieldname = 'VSTEL'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VSTEL'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SLOC'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_tvstz
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_tvstz,ist_return_tab,g_field_tab..
  FREE  : it_tvstz,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " SHIP_POINT_SD  INPUT

*&spwizard: input module for tc 'TABLCTRL115'. do not change this line!
*&spwizard: modify table
MODULE tablctrl115_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl115_wa.
  SELECT SINGLE * FROM zqm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  g_tablctrl115_wa-role_desc = zqm_prep_roledes-brief_desc.
  MODIFY g_tablctrl115_itab
    FROM g_tablctrl115_wa
    INDEX tablctrl115-current_line.
  IF sy-subrc <> 0.
    APPEND g_tablctrl115_wa TO g_tablctrl115_itab.
  ENDIF.

  IF g_tablctrl115_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl115_wa-flag.
    APPEND g_tablctrl115_wa TO g_tablctrl115_itab.
  ENDIF.
ENDMODULE.                    "TABLCTRL115_modify INPUT

*&spwizard: input module for tc 'TABLCTRL115'. do not change this line!
*&spwizard: mark table
MODULE tablctrl115_mark INPUT.
  IF tablctrl115-line_sel_mode = 1 AND
     g_tablctrl115_wa-flag = 'X'.
    LOOP AT g_tablctrl115_itab INTO g_tablctrl115_wa
      WHERE flag = 'X'.
      g_tablctrl115_wa-flag = ''.
      MODIFY g_tablctrl115_itab
        FROM g_tablctrl115_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl115_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl115_itab
    FROM g_tablctrl115_wa
    INDEX tablctrl115-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL115_mark INPUT

*&spwizard: input module for tc 'TABLCTRL115'. do not change this line!
*&spwizard: process user command
MODULE tablctrl115_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL115'
                              'G_TABLCTRL115_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL115_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_QM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_qm INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


  SELECT * FROM zqm_prep_roledes INTO CORRESPONDING FIELDS OF
             TABLE it_role.

  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZQM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZQM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZQM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZQM_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_ROLE_QM  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_PLANT_QM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_plant_qm INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-PLANT' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  SELECT * FROM zqm_prep_loc INTO CORRESPONDING FIELDS OF
             TABLE it_plant.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PLANT'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-PLANT'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_plant
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_plant,ist_return_tab.
  FREE : it_plant,ist_return_tab.

ENDMODULE.                 " POV_PLANT_QM  INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_115  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_115 INPUT.

  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl115-top_line + g_cursor_line - 1.
  g_curr_line_115 = g_curr_line.

ENDMODULE.                 " get_cursor_line_115  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data15  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data15 INPUT.
  SELECT SINGLE * FROM zqm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.
ENDMODULE.                 " validate_lineitem_data15  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno15  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno15 INPUT.
  CLEAR g_srno.
  LOOP AT g_tablctrl115_itab INTO g_tablctrl115_wa.
    g_srno = g_srno + 1.
    g_tablctrl115_wa-srno = g_srno.
    MODIFY g_tablctrl115_itab FROM g_tablctrl115_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl115_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl115_itab  LINES tablctrl115-lines.
  CLEAR g_srno.
ENDMODULE.                 " change_srno15  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ASSET_QM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_asset_qm INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ASSET_QM' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  SELECT * FROM zqm_prep_asset INTO CORRESPONDING FIELDS OF TABLE
            it_asset WHERE ccode = zic_prep_rolereq-ccode.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ASSET'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ASSET_QM'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_asset
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_asset,ist_return_tab.
  FREE  : it_asset,ist_return_tab.
  CLEAR : it_asset.

ENDMODULE.                 " POV_ASSET_QM  INPUT
*&---------------------------------------------------------------------*
*&      Module  check_module_fi  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_module_fi INPUT.
  IF ( old_ok_code = 'CHANGE' OR
  old_ok_code = 'DISPLAY' ) AND moduleid = 'FI'.
    SELECT SINGLE * FROM zic_prep_rolerei INTO
                    CORRESPONDING FIELDS OF wa_module1 WHERE
                    docno = zic_prep_rolereq-docno AND
                    moduleid = 'FI'.
    IF sy-subrc <> 0.
      IF old_ok_code = 'CHANGE'.
        MESSAGE e196(zhelp) WITH zic_prep_rolereq-docno.
      ELSE.
        MESSAGE e198(zhelp) WITH zic_prep_rolereq-docno.
      ENDIF.
    ENDIF.
  ENDIF.
ENDMODULE.                 " check_module_fi  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data15a  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data15a INPUT.

  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.


**---------- Changes Start date 24.06.2016 11:50:45-------------------
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

    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                a~persk a~sbmod  c~designo c~r_p_cd c~version
              d~sdesig_text AS designation d~adesig_text AS adesignation
              d~disc_cd AS disc_cd
                INTO CORRESPONDING FIELDS OF TABLE ist_data
           FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                 ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                    ON c~designo = d~desig_code AND
                        c~r_p_cd  = d~r_p_cd AND
                        c~version = d~version )
                     WHERE a~pernr =  zic_prep_rolereq-userid AND
                           a~sprps = ' ' AND
                           a~endda = '99991231' AND
                           c~sprps = ' ' AND
                           c~endda = '99991231' .
**---------- Changee  Ending Date 24.06.2016 11:50:45-----------------


    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
      g_ccode = ist_data-bukrs.
    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X'.

    SELECT SINGLE * FROM zqm_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      MESSAGE i118(zhelp).
    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
    CLEAR  zic_prep_rolerei-asset_qm.
    CLEAR  zic_prep_rolerei-plant.
    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
    CLEAR  zic_prep_rolerei-asset_qm.
    CLEAR  zic_prep_rolerei-plant.
  ENDIF.


  g_field = 'ZIC_PREP_ROLEREI-PLANT'.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.


    IF NOT zic_prep_rolerei-plant IS INITIAL.

      SELECT * FROM zd_t001w_bukrs INTO CORRESPONDING FIELDS OF
                 TABLE it_bukrs  WHERE bukrs =  zic_prep_rolereq-ccode
                                    AND werks = zic_prep_rolerei-plant.
      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-PLANT'.
        g_i = g_curr_line.
        MESSAGE e068(zhelp) WITH zic_prep_rolerei-role_name.

      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-asset_qm IS INITIAL.

      IF zic_prep_rolereq-ccode = 'MUM' OR zic_prep_rolereq-ccode = 'KKL'.

        SELECT SINGLE * FROM zqm_prep_asset INTO zqm_prep_asset WHERE
                        ccode =  zic_prep_rolereq-ccode AND
                        asset =  zic_prep_rolerei-asset_qm.
        IF sy-subrc <> 0.
          g_e_fl = 'X'.
          g_field = 'ZIC_PREP_ROLEREI-ASSET_QM'.
          g_i = g_curr_line.
          MESSAGE e172(zhelp) WITH zic_prep_rolerei-asset_qm.
        ENDIF.

      ENDIF.

    ENDIF.

    IF NOT zic_prep_rolerei-role_name IS INITIAL.

      SELECT * FROM zqm_prep_roledes INTO CORRESPONDING FIELDS OF
                  TABLE it_role.

      IF sy-subrc <> 0.
        g_e_fl = 'X'.
        g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
        g_i = g_curr_line.
        MESSAGE e068(zhelp) WITH zic_prep_rolerei-role_name.

      ENDIF.

    ENDIF.

  ENDIF.

ENDMODULE.                 " validate_lineitem_data15a  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_fundc_data  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_fundc_data INPUT.

  SELECT * FROM FMZUOB UP TO 1 ROWS
 WHERE FISTL = ZIC_PREP_ROLEREQ-FUNDC
 ORDER BY PRIMARY KEY .
 ENDSELECT.
  IF sy-subrc <> 0.
    MESSAGE i166(zhelp).
    g_field =  'ZIC_PREP_ROLEREQ-FUNDC'.
  ENDIF.

ENDMODULE.                 " validate_fundc_data  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_CRC_POS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_crc_pos INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'CRC_POS' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

*  data : loop_step like sy-stepl.
*  Data : l_role_type like ZIC_PREP_ROLEREI-ROLE_NAME.
  DATA : ist_return_tab1 LIKE STANDARD TABLE OF dselc WITH HEADER LINE.
  DATA : ist_return_tab2 LIKE STANDARD TABLE OF dynpread WITH HEADER
         LINE.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_role_type.

  SELECT * FROM zmm_prep_crcdesg INTO CORRESPONDING FIELDS OF
             TABLE it_pos WHERE role_type = l_role_type AND status = 'active'.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZMM_PREP_CRCDESG'.
  g_field_wa-fieldname = 'CRC_POS'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_PREP_CRCDESG'.
  g_field_wa-fieldname = 'CRC_ORDER_AUTH'.
  APPEND g_field_wa TO g_field_tab.
*Begin of <RD1K962817>.
*  G_FIELD_WA-TABNAME = 'ZMM_PREP_CRCDESG'.
*  G_FIELD_WA-FIELDNAME = 'ROLE_TYPE'.
*  APPEND G_FIELD_WA TO G_FIELD_TAB.
*  g_field_wa-tabname = 'ZMM_PREP_CRCDESG'.
*  g_field_wa-fieldname = 'ROLE_TYPE_EX'.
*  APPEND g_field_wa TO g_field_tab.

  g_field_wa-tabname = 'ZMM_PREP_CRCDESG'.
  g_field_wa-fieldname = 'MIN_DESIGNATION'.
  APPEND g_field_wa TO g_field_tab.

  g_field_wa-tabname = 'ZMM_PREP_CRCDESG'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.

  g_field_wa-tabname = 'ZMM_PREP_CRCDESG'.
  g_field_wa-fieldname = 'ROLE_TYPE_EX'.
  APPEND g_field_wa TO g_field_tab.

*Begin of <RD1K962817>.
  ist_return_tab1-fldname = 'ROLE_TYPE_EX'.
  ist_return_tab1-dyfldname = 'ZIC_PREP_ROLEREI-ROLE_TYPE_EX'.
  APPEND ist_return_tab1 TO ist_return_tab1.
*End of <RD1K962817>.
  ist_return_tab1-fldname = 'ROLE_TYPE'.
  ist_return_tab1-dyfldname = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  APPEND ist_return_tab1 TO ist_return_tab1.
*Begin of <RD1K962817>.
  ist_return_tab1-fldname = 'MIN_DESIGNATION'.
  ist_return_tab1-dyfldname = 'ZMM_PREP_CRCDESG-MIN_DESIGNATION'.
  APPEND ist_return_tab1 TO ist_return_tab1.
*End of <RD1K962817>.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CRC_POS'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'CRC_POS'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_pos
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
      dynpfld_mapping = ist_return_tab1
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*Begin of <RD1K963151>.
  IF ist_return_tab[] IS NOT INITIAL.
*End of <RD1K963151>.
    READ TABLE ist_return_tab WITH KEY fieldname = 'CRC_POS'.
    ist_return_tab2-fieldname = ist_return_tab-fieldname.
    ist_return_tab2-fieldvalue = ist_return_tab-fieldval.
    ist_return_tab2-stepl = loop_step.
    APPEND ist_return_tab2 TO ist_return_tab2.
    READ TABLE ist_return_tab WITH KEY fieldname = 'ROLE_TYPE_EX'.
    CONCATENATE 'ZIC_PREP_ROLEREI-' ist_return_tab-fieldname INTO
    ist_return_tab-fieldname.
    ist_return_tab2-fieldname = ist_return_tab-fieldname.
    ist_return_tab2-fieldvalue = ist_return_tab-fieldval.
    ist_return_tab2-stepl = loop_step.
    APPEND ist_return_tab2 TO ist_return_tab2.

*Begin of <RD1K962817>.
    READ TABLE ist_return_tab WITH KEY fieldname = 'MIN_DESIGNATION'.
    ist_return_tab2-fieldname = ist_return_tab-fieldname.
    ist_return_tab2-fieldvalue = ist_return_tab-fieldval.
    ist_return_tab2-stepl = loop_step.
    APPEND ist_return_tab2 TO ist_return_tab2.

    READ TABLE ist_return_tab2 WITH KEY fieldname = 'MIN_DESIGNATION'.
*    DATA : lv_old      TYPE char2,
*           lv_new      TYPE char2,
*           l_answer(1) TYPE c.

    lv_new = ist_return_tab2-fieldvalue.
    lv_old = zic_prep_rolereq-persk.

*Begin of <RD1K962817>.
    IF lv_new = ' '.

    ELSEIF  zic_prep_rolereq-persk < 'E4'.
      MESSAGE i048(zmmaa). "with text-003.
      LEAVE PROGRAM.
    ENDIF.
*  if zic_prep_rolereq-persk < lv_new.
*  MESSAGE i803(zmm) with text-003.
*  LEAVE PROGRAM.
*  endif.
*End of <RD1K962817>.
* Begin of <RD1K963735> on 05/05/2009.
    DATA lv_text TYPE string.
    CONCATENATE 'You will be given Authorisation for Administrative Approval'
                             '& Expenditure Sanction One CRC Level Below as per the BDP 2009' INTO lv_text SEPARATED BY space.
    IF lv_new > lv_old.

       MESSAGE 'You do not meet the minimum designation criteria. Pls. contact SAP team with a copy of order for further action.' TYPE 'I'.

*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*        EXPORTING
*          text_question         = lv_text
*          text_button_1         = 'Agree'
*          text_button_2         = 'Cancel'
*          default_button        = ' '
*          start_column          = 25
*          start_row             = 6
*          display_cancel_button = ' '
*        IMPORTING
*          answer                = l_answer
*        EXCEPTIONS
*          text_not_found        = 1
*          OTHERS                = 2.
*      CASE l_answer.
*        WHEN 1.
**End of <RD1K962817>.
** Begin of <RD1K963735> on 05/05/2009.
*          CALL FUNCTION 'DYNP_VALUES_UPDATE'
*            EXPORTING
*              dyname               = sy-cprog
*              dynumb               = sy-dynnr
*            TABLES
*              dynpfields           = ist_return_tab2
*            EXCEPTIONS
*              invalid_abapworkarea = 1
*              invalid_dynprofield  = 2
*              invalid_dynproname   = 3
*              invalid_dynpronummer = 4
*              invalid_request      = 5
*              no_fielddescription  = 6
*              undefind_error       = 7
*              OTHERS               = 8.
*          IF sy-subrc <> 0.
*            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*          ENDIF.
*        WHEN 2.
**Begin of <RD1K963151>.
*          CLEAR : ist_return_tab2[],
*                  ist_return_tab1[],
*                  ist_return_tab[].
*          FREE : ist_return_tab2[],
*                  ist_return_tab1[],
*                  ist_return_tab[].
*
*          CALL FUNCTION 'DYNP_VALUES_UPDATE'
*            EXPORTING
*              dyname               = sy-cprog
*              dynumb               = sy-dynnr
*            TABLES
*              dynpfields           = ist_return_tab2
*            EXCEPTIONS
*              invalid_abapworkarea = 1
*              invalid_dynprofield  = 2
*              invalid_dynproname   = 3
*              invalid_dynpronummer = 4
*              invalid_request      = 5
*              no_fielddescription  = 6
*              undefind_error       = 7
*              OTHERS               = 8.
*          IF sy-subrc <> 0.
*            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*          ENDIF.
**End of <RD1K963151>.
*      ENDCASE.
    ENDIF.
    CLEAR dis_flag.
  ENDIF.

  ist_return_tab3[] = ist_return_tab2[].
  REFRESH:it_pos,g_field_tab,ist_return_tab,ist_return_tab1,ist_return_tab2.
  FREE  : it_pos,g_field_tab,ist_return_tab,ist_return_tab1,ist_return_tab2.

ENDMODULE.                 " POV_CRC_POS  INPUT

*&spwizard: input module for tc 'TABLCTRL116'. do not change this line!
*&spwizard: modify table
MODULE tablctrl116_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl116_wa.

  SELECT SINGLE * FROM zhs_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  g_tablctrl116_wa-role_desc = zhs_prep_roledes-brief_desc.

  MODIFY g_tablctrl116_itab
    FROM g_tablctrl116_wa
    INDEX tablctrl116-current_line.

  IF sy-subrc <> 0.
    APPEND g_tablctrl116_wa TO g_tablctrl116_itab.
  ENDIF.

  IF g_tablctrl116_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl116_wa-flag.
    APPEND g_tablctrl116_wa TO g_tablctrl116_itab.
  ENDIF.

ENDMODULE.                    "TABLCTRL116_modify INPUT

*&spwizard: input module for tc 'TABLCTRL116'. do not change this line!
*&spwizard: mark table
MODULE tablctrl116_mark INPUT.
  IF tablctrl116-line_sel_mode = 1 AND
     g_tablctrl116_wa-flag = 'X'.
    LOOP AT g_tablctrl116_itab INTO g_tablctrl116_wa
      WHERE flag = 'X'.
      g_tablctrl116_wa-flag = ''.
      MODIFY g_tablctrl116_itab
        FROM g_tablctrl116_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl116_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl116_itab
    FROM g_tablctrl116_wa
    INDEX tablctrl116-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TABLCTRL116_mark INPUT

*&spwizard: input module for tc 'TABLCTRL116'. do not change this line!
*&spwizard: process user command
MODULE tablctrl116_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL116'
                              'G_TABLCTRL116_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TABLCTRL116_user_command INPUT
*&---------------------------------------------------------------------*
*&      Module  get_cursor_line_116  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_116 INPUT.

  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl116-top_line + g_cursor_line - 1.
  g_curr_line_116 = g_curr_line.

ENDMODULE.                 " get_cursor_line_116  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data16  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data16 INPUT.

  SELECT SINGLE * FROM zhs_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.

ENDMODULE.                 " validate_lineitem_data16  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_lineitem_data16a  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data16a INPUT.

  IF  zic_prep_rolereq-crossco_fl = 'X' OR old_ok_code = 'CROSSCO'.

**---------- Changes Start date 24.06.2016 11:50:05-------------------
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


    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
                 a~persk a~sbmod  c~designo c~r_p_cd c~version
               d~sdesig_text AS designation d~adesig_text AS adesignation
               d~disc_cd AS disc_cd
                 INTO CORRESPONDING FIELDS OF TABLE ist_data
            FROM ( ( zpa0001 AS a INNER JOIN zpa9930 AS c
                  ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                     ON c~designo = d~desig_code AND
                         c~r_p_cd  = d~r_p_cd AND
                         c~version = d~version )
                      WHERE a~pernr =  zic_prep_rolereq-userid AND
                            a~sprps = ' ' AND
                            a~endda = '99991231' AND
                            c~sprps = ' ' AND
                            c~endda = '99991231' .

**---------- Changee  Ending Date 24.06.2016 11:50:05-----------------

    IF sy-subrc = 0.
      READ TABLE ist_data INDEX 1.  "#EC CI_NOORDER
      g_ccode = ist_data-bukrs.
    ENDIF.

  ELSE.

    g_ccode =  zic_prep_rolereq-ccode.

  ENDIF.

  IF g_read_fl <> 'X'.

    SELECT SINGLE * FROM zhs_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      MESSAGE e118(zhelp).
    ENDIF.

  ELSEIF g_e_fl = 'X'.
    CLEAR g_e_fl.
  ELSE.
    CLEAR g_read_fl.

  ENDIF.

  IF g_role_name_flag = 'X'.
    CLEAR g_role_name_flag.
  ENDIF.


  g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.

  g_i = g_curr_line.

  l_role_name = zic_prep_rolerei-role_name.

**********************************************************

  IF old_ok_code <> 'DISPLAY'.

    IF NOT zic_prep_rolerei-role_name IS INITIAL.

      SELECT SINGLE * FROM zhs_prep_roledes WHERE
          role_type = zic_prep_rolerei-role_name.

      IF sy-subrc <> 0.
        CLEAR :okcode_100,sy-ucomm.
        MESSAGE e164(zhelp) WITH zic_prep_rolerei-role_name
        zic_prep_rolereq-ccode .
      ENDIF.

    ENDIF.

  ENDIF.

ENDMODULE.                 " validate_lineitem_data16a  INPUT
*&---------------------------------------------------------------------*
*&      Module  change_srno16  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno16 INPUT.

  CLEAR g_srno.
  LOOP AT g_tablctrl116_itab INTO g_tablctrl116_wa.
    g_srno = g_srno + 1.
    g_tablctrl116_wa-srno = g_srno.
    MODIFY g_tablctrl116_itab FROM g_tablctrl116_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl116_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl116_itab  LINES tablctrl116-lines.
  CLEAR g_srno.

ENDMODULE.                 " change_srno16  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_HSE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_hse INPUT.

  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

  SELECT * FROM zhs_prep_roledes INTO CORRESPONDING FIELDS OF
               TABLE it_role.

  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZHS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZHS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZHS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZHS_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.

ENDMODULE.                 " POV_ROLE_HSE  INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_117'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MODIFY TABLE
MODULE tc_117_modify INPUT.
*  MOVE-CORRESPONDING ZIC_PREP_ROLEREI TO G_TC_117_WA.
*  MODIFY G_TC_117_ITAB
*    FROM G_TC_117_WA
*    INDEX TC_117-CURRENT_LINE.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tc_117_wa.

  SELECT SINGLE * FROM zmm_prep_rolegrp WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.
  IF NOT g_tc_117_wa-role_name IS INITIAL.
    SELECT SINGLE * FROM zol_prep_roledes WHERE role_type =
                    zic_prep_rolerei-role_name.
    IF sy-subrc = 0.

      g_tc_117_wa-role_desc = zol_prep_roledes-brief_desc.
    ENDIF.
  ENDIF.
  MODIFY g_tc_117_itab
    FROM g_tc_117_wa
    INDEX tc_117-current_line.

  IF sy-subrc <> 0.
    APPEND g_tc_117_wa TO g_tc_117_itab.
  ENDIF.

  IF g_tc_117_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tc_117_wa-flag.
    APPEND g_tc_117_wa TO g_tc_117_itab.
  ENDIF.
ENDMODULE.                    "TC_117_MODIFY INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_117'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE tc_117_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_117'
                              'G_TC_117_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TC_117_USER_COMMAND INPUT
*&---------------------------------------------------------------------*
*&      Module  GET_CURSOR_LINE_117  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_117 INPUT.
  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tc_117-top_line + g_cursor_line - 1.
  g_curr_line_117 = g_curr_line.
ENDMODULE.                 " GET_CURSOR_LINE_117  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_LINEITEM_DATA17  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data17 INPUT.

  SELECT SINGLE * FROM zol_prep_roledes WHERE role_type =
                   zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.

ENDMODULE.                 " VALIDATE_LINEITEM_DATA17  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE117  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role117 INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

*  TYPES : BEGIN OF z_role_des1,
*            role_type LIKE zmm_prep_roledes-role_type,
*            brief_desc LIKE zmm_prep_roledes-brief_desc,
*            detail_desc1 LIKE zmm_prep_roledes-detail_desc1,
*            detail_desc2 LIKE zmm_prep_roledes-detail_desc2,
*            sort_field LIKE zmm_prep_roledes-brief_desc,
*            mm_disc_flag LIKE zmm_prep_roledes-mm_disc_flag,
*          END OF z_role_des1.

*  DATA   : it_role type table of zmm_prep_roledes with header line.
*  DATA   : it_role1 TYPE TABLE OF z_role_des1 WITH HEADER LINE.

  SELECT * FROM zol_prep_roledes INTO CORRESPONDING FIELDS OF
             TABLE it_role.
  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZOL_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZOL_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZOL_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZOL_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC2'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.
ENDMODULE.                 " POV_ROLE117  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_SLOC117  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_sloc117 INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-SLOC' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


*  DATA : l_plant LIKE zic_prep_rolerei-plant.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'PLANT'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_plant.


*  DATA   : it_t001l TYPE TABLE OF t001l WITH HEADER LINE.
*  DATA   : it_excp_sl TYPE TABLE OF zmm_prep_sl_excp WITH HEADER LINE.
*  DATA   : wa_t001l LIKE t001l.
*  DATA   : l_zarea LIKE zmm_consm-zarea.

  SELECT * FROM t001l INTO CORRESPONDING FIELDS OF
             TABLE it_t001l  WHERE werks = l_plant.

  IF  zic_prep_rolereq-disc_mm_flag = 'X'.

    LOOP AT it_t001l INTO wa_t001l.

      SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

      IF sy-subrc = 0.

        IF l_zarea+0(1) <> 'M'.
          DELETE it_t001l.
        ENDIF.

      ELSE.

        DELETE it_t001l.

      ENDIF.

    ENDLOOP.

  ELSE.

    LOOP AT it_t001l INTO wa_t001l.

      SELECT ZAREA FROM ZMM_CONSM INTO L_ZAREA UP TO 1 ROWS
 WHERE ZLOC = WA_T001L-LGORT
 ORDER BY PRIMARY KEY .
 ENDSELECT.

      IF sy-subrc = 0.

        IF l_zarea+0(1) = 'M'.
          DELETE it_t001l.
        ENDIF.

      ELSE.

        DELETE it_t001l.

      ENDIF.

    ENDLOOP.

  ENDIF.
**COMMENT START BY CAB_AMITMOZA
*  SELECT * FROM zmm_prep_sl_excp INTO TABLE it_excp_sl.
*
*************************************
*
*  LOOP AT it_excp_sl.
*
*    READ TABLE it_t001l WITH KEY werks = it_excp_sl-werks
*    lgort = it_excp_sl-lgort.
*
*    IF sy-subrc = 0.
*
*      DELETE it_t001l WHERE werks = it_excp_sl-werks
*      AND lgort = it_excp_sl-lgort.
*
*    ENDIF.
*
*  ENDLOOP.
**COMMENT END BY CAB_AMITMOZA
************************************
  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'WERKS'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGORT'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T001L'.
  g_field_wa-fieldname = 'LGOBE'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LGORT'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-SLOC'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_t001l
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_t001l,ist_return_tab,g_field_tab..
  FREE  : it_t001l,ist_return_tab,g_field_tab.
  CLEAR : g_field_wa.
ENDMODULE.                 " POV_SLOC117  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_APPROVER117  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_approver117 INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-APPROVER' AND screen-input = 0.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.


*  DATA : it_approver LIKE TABLE OF zmm_prep_approve.
*  DATA : wa_approver LIKE zmm_prep_approve.

*  DATA : it_approver1 LIKE TABLE OF zmm_prep_app_crc.
*  DATA : wa_approver1 LIKE zmm_prep_app_crc.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0110'
    IMPORTING
      value = l_role_name.

*  IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'.
*
*    SELECT * FROM zmm_prep_app_crc INTO TABLE it_approver1.
*
*  ELSE.

  SELECT * FROM zmm_prep_approve INTO TABLE it_approver.

*  ENDIF.


*      if  ZIC_PREP_ROLEREQ-DISC_MM_FLAG = 'X'.
*
*
*              if l_role_name = 'M11'.
*
*                  loop at it_approver into wa_approver.
*
*                    if wa_approver-M11_FLAG <> 'X'.
*                      delete it_approver.
*                    endif.
*
*                  endloop.
*
*              endif.
*
*      endif.


*      if  ZIC_PREP_ROLEREQ-DISC_MM_FLAG <> 'X'.
*
*         if l_role_name = 'M11'.
*
*            loop at it_approver into wa_approver.
*
*                if wa_approver-M11_FLAG <> 'X'.
*                    delete it_approver.
*                 endif.
*
*            endloop.
*
*         endif.
*
*      endif.
*******************************************************
*  IF l_role_name = 'M11S'.                                  "22.05.06
*
*    LOOP AT it_approver INTO wa_approver.
*
*      CASE  zic_prep_rolereq-disc_mm_flag.
*
*        WHEN 'X'.
*          IF wa_approver-mm_flag <> 'X'.
*            DELETE it_approver.
*          ENDIF.
*        WHEN OTHERS.
*          IF wa_approver-m11s_flag <> 'X'.
*            DELETE it_approver.
*          ENDIF.
*      ENDCASE.
*
*    ENDLOOP.
*
*  ENDIF.
*
*  IF l_role_name = 'M11M'.
*
*    LOOP AT it_approver INTO wa_approver.
*
*      CASE  zic_prep_rolereq-disc_mm_flag.
*
*        WHEN 'X'.
*          IF wa_approver-mm_flag <> 'X'
*             OR wa_approver-m11m_flag <> 'X'.
*            DELETE it_approver.
*          ENDIF.
*        WHEN OTHERS.
*          IF wa_approver-mm_flag = 'X'
*             OR wa_approver-m11m_flag <> 'X'.
*            DELETE it_approver.
*          ENDIF.
*      ENDCASE.
*
*    ENDLOOP.
*
*  ENDIF.
***************************************************22.05.06
*
*  IF l_role_name = 'M8'.
*
*    LOOP AT it_approver INTO wa_approver.
*
*      IF wa_approver-m8_flag <> 'X'.
*        DELETE it_approver.
*      ENDIF.
*
*    ENDLOOP.
*
*  ENDIF.

*  IF old_ok_code = 'CRCROLES' OR  zic_prep_rolereq-crc_fl = 'X'..
*
*    IF l_role_name = 'M3'.
*
*      LOOP AT it_approver1 INTO wa_approver1.
*
*        IF wa_approver1-m3_flag <> 'X'.
*          DELETE it_approver1.
*        ENDIF.
*
*      ENDLOOP.
*
*    ENDIF.
*
*    IF l_role_name = 'M3A'.                                 "22.05.06
*
*      LOOP AT it_approver1 INTO wa_approver1.
*
*        IF wa_approver1-m3a_flag <> 'X'.
*          DELETE it_approver1.
*        ENDIF.
*
*      ENDLOOP.
*
*    ENDIF.
*
*    IF l_role_name = 'M3B'.
*
*      LOOP AT it_approver1 INTO wa_approver1.
*
*        IF wa_approver1-m3b_flag <> 'X'.
*          DELETE it_approver1.
*        ENDIF.
*
*      ENDLOOP.
*
*    ENDIF.                                                  " 22.05.06
*
*
*    IF l_role_name = 'M11S'.
*
*      LOOP AT it_approver1 INTO wa_approver1.
*
**                    if wa_approver1-M11S_FLAG <> 'X'.
**                        delete it_approver1.
**                    endif.
*        CASE  zic_prep_rolereq-disc_mm_flag.
*
*          WHEN 'X'.
*            IF wa_approver1-mm_flag <> 'X'
*               OR wa_approver1-m11s_flag <> 'X'.
*              DELETE it_approver1.
*            ENDIF.
*          WHEN OTHERS.
*            IF wa_approver1-mm_flag = 'X'
*               OR wa_approver1-m11s_flag <> 'X'.
*              DELETE it_approver1.
*            ENDIF.
*        ENDCASE.
*
*      ENDLOOP.
*
*    ENDIF.
*
*    IF l_role_name = 'M11M'.
*
*      LOOP AT it_approver1 INTO wa_approver1.
*
**                    if wa_approver1-M11M_FLAG <> 'X'.
**                        delete it_approver1.
**                     endif.
*
*        CASE  zic_prep_rolereq-disc_mm_flag.
*
*          WHEN 'X'.
*            IF wa_approver1-mm_flag <> 'X'
*               OR wa_approver1-m11m_flag <> 'X'.
*              DELETE it_approver1.
*            ENDIF.
*          WHEN OTHERS.
*            IF wa_approver1-mm_flag = 'X'
*               OR wa_approver1-m11m_flag <> 'X'.
*              DELETE it_approver1.
*            ENDIF.
*        ENDCASE.
*
*      ENDLOOP.
*
*    ENDIF.
*
*    it_approver[] = it_approver1[].
*
*  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZMM_PREP_APPROVE'.
  g_field_wa-fieldname = 'APP_LEVEL'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZMM_PREP_APPROVE'.
  g_field_wa-fieldname = 'L_DESC'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'APP_LEVEL'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-APPROVER'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_approver
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_approver,ist_return_tab, it_approver1,g_field_tab.
  FREE  : it_approver,ist_return_tab, it_approver1,g_field_tab.
  CLEAR : g_field_wa.
ENDMODULE.                 " POV_APPROVER117  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHANGE_SRNO_117  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno_117 INPUT.
  CLEAR g_srno.
  LOOP AT g_tc_117_itab INTO g_tc_117_wa.
    g_srno = g_srno + 1.
    g_tc_117_wa-srno = g_srno.
    MODIFY g_tc_117_itab FROM g_tc_117_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tc_117_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tc_117_itab  LINES tc_117-lines.
  CLEAR g_srno.
ENDMODULE.                 " CHANGE_SRNO_117  INPUT
*&---------------------------------------------------------------------*
*&      Module  TC_117_MARK  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_117_mark INPUT.
  IF tc_117-line_sel_mode = 1 AND
       g_tc_117_wa-flag = 'X'.
    LOOP AT g_tc_117_itab INTO g_tc_117_wa
      WHERE flag = 'X'.
      g_tc_117_wa-flag = ''.
      MODIFY g_tc_117_itab
        FROM g_tc_117_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tc_117_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tc_117_itab
    FROM g_tc_117_wa
    INDEX tc_117-current_line
    TRANSPORTING flag.
ENDMODULE.                 " TC_117_MARK  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_LINEITEM_DATA117  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data117 INPUT.
  IF g_read_fl <> 'X'.
    SELECT SINGLE * FROM zol_prep_roledes WHERE role_type =
                          zic_prep_rolerei-role_name.
    IF sy-subrc <> 0.
      g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
      MESSAGE i118(zhelp).
    ENDIF.
  ENDIF.
  IF NOT zic_prep_rolerei-role_name IS INITIAL.

    SELECT * FROM zol_prep_roledes INTO CORRESPONDING FIELDS OF
                TABLE it_role.
    LOOP AT it_role .
      IF it_role-role_type = zic_prep_rolerei-role_name.
        check_role_flag = 'X'.
      ENDIF.
    ENDLOOP.
    IF check_role_flag = 'X'.
      CLEAR check_role_flag.
    ELSE.
      MESSAGE e164(zhelp) WITH zic_prep_rolerei-role_name
      zic_prep_rolereq-ccode .
    ENDIF.

  ENDIF.
ENDMODULE.                 " VALIDATE_LINEITEM_DATA117  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_ROLE_SRM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_role_srm INPUT.
  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-ROLE_NAME' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.



  SELECT * FROM zsr_prep_roledes INTO CORRESPONDING FIELDS OF
             TABLE it_role.

  SORT it_role ASCENDING BY sort_field.

  IF old_ok_code <> 'DISPLAY'.

    CLEAR zic_prep_rolerei-role_name.

  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'ZSR_PREP_ROLEDES'.
  g_field_wa-fieldname = 'ROLE_TYPE'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZSR_PREP_ROLEDES'.
  g_field_wa-fieldname = 'BRIEF_DESC'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'ZSR_PREP_ROLEDES'.
  g_field_wa-fieldname = 'DETAIL_DESC1'.
  APPEND g_field_wa TO g_field_tab.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLE_TYPE'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-ROLE_NAME'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_role
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_role,ist_return_tab, g_field_tab.
  FREE  : it_role,ist_return_tab, g_field_tab.
  CLEAR : g_field_wa.
ENDMODULE.                 " POV_ROLE_SRM  INPUT
*&---------------------------------------------------------------------*
*&      Module  GET_CURSOR_LINE_118  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_cursor_line_118 INPUT.
  GET CURSOR LINE g_cursor_line.
  g_curr_line = g_cursor_line.
  g_curr_line = tablctrl118-top_line + g_cursor_line - 1.
  g_curr_line_118 = g_curr_line.

ENDMODULE.                 " GET_CURSOR_LINE_118  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_LINEITEM_DATA118  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data118 INPUT.

  SELECT SINGLE * FROM zsr_prep_roledes WHERE role_type =
                 zic_prep_rolerei-role_name.

  IF g_role_name_prev <> zic_prep_rolerei-role_name AND
              NOT g_role_name_prev IS INITIAL.
    g_role_name_flag = 'X'.
  ENDIF.
  g_read_fl = 'X'.
ENDMODULE.                 " VALIDATE_LINEITEM_DATA118  INPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_MODIFY  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_modify INPUT.
  MOVE moduleid TO zic_prep_rolerei-moduleid.
  IF zic_prep_rolerei-rej_fl IS INITIAL.
    CLEAR : zic_prep_rolerei-rej_id, zic_prep_rolerei-rej_date.
  ENDIF.
  MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl118_wa.

  SELECT SINGLE * FROM zmm_prep_rolegrp WHERE role_type =
                    zic_prep_rolerei-role_name.

  IF sy-subrc <> 0 .
    g_val_err = 'X'.
    MESSAGE i102(zhelp) WITH zic_prep_rolerei-role_name .
    g_field = 'ZIC_PREP_ROLEREI-ROLE_NAME'.
  ENDIF.

  IF zic_prep_rolerei-rej_fl = ''.

    IF sy-subrc = 0 AND old_ok_code = 'APPROVE'.
      IF zmm_prep_rolegrp-approver1 = g_user
         OR zmm_prep_rolegrp-approver2 = g_user
         OR zmm_prep_rolegrp-approver3 = g_user
   """"""""""""""""""""""""
      "added by lipsy for l2 approver on 20.03.2015 RD1K996555
            OR ( moduleid = 'SRM' AND zmm_prep_rolegrp-approver1 = g_user_l2 )
       "End of addition by lipsy for l2 approver on 20.03.2015 RD1K996555
    """"""""""""""""""""
        .
      ELSE.

        IF okcode_100 = 'SAV'.
          IF err_flg <> 'X'.
            err_flg = 'X'.
            CLEAR : sy-ucomm, okcode_100.
          ENDIF.
          MESSAGE e047(zhelp) WITH zmm_prep_rolegrp-role_type.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

  IF NOT g_tablctrl118_wa-role_name IS INITIAL.

    SELECT SINGLE * FROM zsr_prep_roledes WHERE role_type =
                  zic_prep_rolerei-role_name.
    IF sy-subrc = 0.
      g_tablctrl118_wa-role_desc = zsr_prep_roledes-brief_desc.
*Begin  of <RD1K962817>.
*        IF G_TABLCTRL118_WA-ROLE_NAME = 'M8'.
*          G_TABLCTRL118_WA-APPROVER = ZIC_PREP_ROLEREQ-PERSK.
*        ENDIF.
*End of <RD1K962817>.
*        if  not g_tablctrl110_wa-APPROVER is  INITIAL and ZIC_PREP_ROLEREI-ROLE_NAME = 'M8'.
*          loop AT SCREEN.
*            if screen-group2 = 'MOD'.
**              screen-active = 1.
**              screen-output =  1.
*              screen-input = 0.
**              screen-intensified = 0.
*              MODIFY SCREEN .
*              ENDIF.
*              endloop.
*endif.

    ENDIF.

  ENDIF.

  MODIFY g_tablctrl118_itab
     FROM g_tablctrl118_wa
     INDEX tablctrl118-current_line.

  IF sy-subrc <> 0.
    APPEND g_tablctrl118_wa TO g_tablctrl118_itab.
  ENDIF.

  IF g_tablctrl118_wa-flag = 'X' AND okcode_100 = 'COPY'.
    CLEAR g_tablctrl118_wa-flag.
    APPEND g_tablctrl118_wa TO g_tablctrl118_itab.
  ENDIF.
ENDMODULE.                 " TABLCTRL118_MODIFY  INPUT
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_MARK  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_mark INPUT.
  IF tablctrl118-line_sel_mode = 1 AND
       g_tablctrl118_wa-flag = 'X'.
    LOOP AT g_tablctrl118_itab INTO g_tablctrl118_wa
      WHERE flag = 'X'.
      g_tablctrl118_wa-flag = ''.
      MODIFY g_tablctrl118_itab
        FROM g_tablctrl118_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tablctrl118_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tablctrl118_itab
    FROM g_tablctrl118_wa
    INDEX tablctrl118-current_line.
ENDMODULE.                 " TABLCTRL118_MARK  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHANGE_SRNO_118  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_srno_118 INPUT.
  CLEAR g_srno.
  LOOP AT g_tablctrl118_itab INTO g_tablctrl118_wa.
    g_srno = g_srno + 1.
    g_tablctrl118_wa-srno = g_srno.
    MODIFY g_tablctrl118_itab FROM g_tablctrl118_wa.
  ENDLOOP.
  DESCRIBE TABLE g_tablctrl118_itab  LINES g_lines_rl.
  DESCRIBE TABLE g_tablctrl118_itab  LINES tablctrl118-lines.
  CLEAR g_srno.

ENDMODULE.                 " CHANGE_SRNO_118  INPUT
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  TABLCTRL118_USER_COMMAND  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tablctrl118_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TABLCTRL118'
                              'G_TABLCTRL118_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                 " TABLCTRL118_USER_COMMAND  INPUT
*&---------------------------------------------------------------------*
*&      Module  POV_GRP_SRM  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pov_grp_srm INPUT.


  g_ccode =  zic_prep_rolereq-ccode.


  LOOP AT SCREEN.

    IF screen-name = 'ZIC_PREP_ROLEREI-GRP' AND screen-input = 0
.
      dis_flag = 'X'.
    ENDIF.

  ENDLOOP.

**  DATA : L_EKGRP LIKE T024-EKGRP.
*  DATA : LOOP_STEP LIKE SY-STEPL.
*  DATA : L_ROLE_NAME LIKE ZIC_PREP_ROLEREI-ROLE_NAME.
*
*  DATA L_DISC_MM_FLAG LIKE ZIC_PREP_ROLEREQ-DISC_MM_FLAG.

*  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
*       EXPORTING
*            STRUC = 'ZIC_PREP_ROLEREQ'
*            FIELD = 'DISC_MM_FLAG'
*            REPID = SY-CPROG
*            DYNNR = '0100'
*       IMPORTING
*            VALUE = l_disc_mm_flag.
*
*  ZIC_PREP_ROLEREQ-DISC_MM_FLAG = l_disc_mm_flag.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = loop_step
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'SWD_DYNPRO_FIELD_GET'
    EXPORTING
      struc = 'ZIC_PREP_ROLEREI'
      field = 'ROLE_NAME'
      index = loop_step
      repid = sy-cprog
      dynnr = '0118'
    IMPORTING
      value = l_role_name.

  IF l_role_name = 'S1' OR  l_role_name = 'S2' .
    CONCATENATE '%' g_ccode '%' INTO g_line1.
    SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.

  ELSE.
    IF zic_prep_rolereq-disc_mm_flag <> 'X'.
*      concatenate '%' G_CCODE '-' 'IND' '%'
*      into g_line1.
      CONCATENATE '%' g_ccode '%' 'IND' '%'
      INTO g_line1.
      SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
    ELSE.
*      concatenate  '%' G_CCODE '-' 'MM' '%'
*      into g_line1.
      CONCATENATE  '%' g_ccode '%' 'MM' '%'
      INTO g_line1.
      SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line1.
    ENDIF.
  ENDIF.

  IF old_ok_code = 'DISPLAY'.
    dis_flag = 'X'.
  ENDIF.

  g_field_wa-tabname = 'T024'.
  g_field_wa-fieldname = 'EKGRP'.
  APPEND g_field_wa TO g_field_tab.
  g_field_wa-tabname = 'T024'.
  g_field_wa-fieldname = 'EKNAM'.
  APPEND g_field_wa TO g_field_tab.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'EKGRP'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'ZIC_PREP_ROLEREI-GRP'
      value_org       = 'S'
      display         = dis_flag
    TABLES
      value_tab       = it_t024
      field_tab       = g_field_tab
      return_tab      = ist_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR dis_flag.

  ENDIF.

  REFRESH:it_t024,ist_return_tab, g_field_tab.
  FREE : it_t024,ist_return_tab, g_field_tab.
  CLEAR g_field_wa.
ENDMODULE.                 " POV_GRP_SRM  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_LINEITEM_DATA1181  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_lineitem_data1181 INPUT.

*BREAK-POINT.
  CLEAR:g_line_srm.
  CONCATENATE  '%' zic_prep_rolereq-ccode '%' '%'
  INTO g_line_srm.

  SELECT * FROM t024 INTO TABLE it_t024 WHERE telfx LIKE g_line_srm.


**

  IF  NOT zic_prep_rolerei-grp IS INITIAL.

    LOOP AT it_t024 INTO wa_t024.

      IF zic_prep_rolerei-grp = wa_t024-ekgrp.
        grp_flag_srm = 'X'.
      ENDIF.

    ENDLOOP.

    IF grp_flag_srm = 'X'.
      CLEAR grp_flag_srm.
    ELSE.
*        G_E_FL = 'X'.
*        G_READ_FL = 'X'.
*        G_FIELD = 'ZIC_PREP_ROLEREI-GRP'.
      MOVE-CORRESPONDING zic_prep_rolerei TO g_tablctrl118_wa.
      MODIFY g_tablctrl118_itab
                FROM g_tablctrl118_wa
                  INDEX tablctrl118-current_line.
*        G_I = TABLCTRL110-CURRENT_LINE.
      MESSAGE i069(zhelp).
      CALL SCREEN 100.
    ENDIF.
  ENDIF.
ENDMODULE.                 " VALIDATE_LINEITEM_DATA1181  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_APPROVER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_approver INPUT.
  IF moduleid = 'MM'.
    IF zic_prep_rolerei-approver+0(1) = 'E'.
      v_app =  zic_prep_rolerei-approver+1(1) .

      IF v_app > zic_prep_rolereq-persk+1(1).

        MESSAGE e163(zmm_oth).
      ENDIF.

    ENDIF.
  ENDIF.
ENDMODULE.                 " VALIDATE_APPROVER  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_SRMGRP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_srmgrp INPUT.
  CLEAR:l_logsys.



  SELECT SINGLE logsys FROM zmm_logsys INTO l_logsys
  WHERE  appl = 'SRM'.

  """"""calling srm

  IF NOT l_logsys  IS INITIAL.





    p_uname = zic_prep_rolereq-userid.
    p_grp = zic_prep_rolerei-grp.
    p_role = zic_prep_rolerei-role_name.

    TRANSLATE p_grp TO UPPER CASE.
    TRANSLATE p_role TO UPPER CASE.

    IF p_grp  IS NOT INITIAL.
      CALL FUNCTION 'ZSRM_ROLE_ASSIGN_CHECK' DESTINATION l_logsys
        EXPORTING
          p_uname = p_uname
          p_grp   = p_grp
          p_role  = p_role
        IMPORTING
          v_exist = v_exist.

      IF v_exist = 'Y'.

        MESSAGE e164(zmm_oth) WITH zic_prep_rolerei-grp.

      ENDIF.

      IF v_exist = 'N'.

        MESSAGE e169(zmm_oth) WITH zic_prep_rolerei-grp.

      ENDIF.


    ENDIF.

  ENDIF.



  CLEAR:count_grp,g_wa_pgrp.

  LOOP AT g_tablctrl118_itab INTO g_wa_pgrp WHERE  grp = zic_prep_rolerei-grp  .
    IF g_wa_pgrp-grp  IS NOT INITIAL.
      count_grp = count_grp + 1.
    ENDIF.
  ENDLOOP.
  IF  count_grp > '1'.
    MESSAGE e092(zhelp).
  ENDIF.

ENDMODULE.                 " VALIDATE_SRMGRP  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_SRMROLE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_srmrole INPUT.
  CLEAR:l_logsys.



  SELECT SINGLE logsys FROM zmm_logsys INTO l_logsys
  WHERE  appl = 'SRM'.

  """"""calling srm

  IF NOT l_logsys  IS INITIAL.





    p_uname = zic_prep_rolereq-userid.
    p_role = zic_prep_rolerei-role_name.
    p_grp = zic_prep_rolerei-grp.

    TRANSLATE p_grp TO UPPER CASE.
    TRANSLATE p_role TO UPPER CASE.

    IF  p_role = 'S3'.
      CALL FUNCTION 'ZSRM_ROLE_ASSIGN_CHECK' DESTINATION l_logsys
        EXPORTING
          p_uname = p_uname
          p_grp   = p_grp
          p_role  = p_role
        IMPORTING
          v_exist = v_exist.

      IF v_exist = 'P'.

        MESSAGE e165(zmm_oth) WITH zic_prep_rolerei-role_name.

      ENDIF.


    ENDIF.

  ENDIF.
  IF zic_prep_rolereq-disc_mm_flag = 'X'.
    IF  p_role = 'S2'.
      MESSAGE e167(zmm_oth) WITH zic_prep_rolerei-role_name.
    ENDIF.
  ENDIF.

ENDMODULE.                 " VALIDATE_SRMROLE  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_PGRP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_pgrp INPUT.


*  SELECT SINGLE * from zmm_prep_rolecrc INTO @data(ls_rolec)
*    WHERE ROLE_TYPE = @ZIC_PREP_ROLEREI-role_name.
*
*    IF ZIC_PREP_ROLEREI-plant is INITIAL.
*     MESSAGE 'Please enter plant' TYPE 'W'.
*
*    ENDIF.
*
*     IF ZIC_PREP_ROLEREI-grp is INITIAL.
*     MESSAGE 'Please enter purchasing group' TYPE 'W'.
*
*    ENDIF.
*refresh: itab_agr_users[].
*clear:v_grp_comp.
*
*if ZIC_PREP_ROLEREI-GRP is not initial.
*CONCATENATE '%' ZIC_PREP_ROLEREI-GRP  '%' into v_grp_comp.
*
*select * FROM AGR_USERS into CORRESPONDING FIELDS OF TABLE
*    itab_agr_users
*    where uname = ZIC_PREP_ROLEREQ-USERID
*  and AGR_NAME like v_grp_comp
*  and to_dat = '99991231'.
*
*  if sy-subrc = 0.
*
*    MESSAGE 'Purchase group already Assigned' TYPE 'W'.
*
*    endif.

*endif.

ENDMODULE.                 " VALIDATE_PGRP  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_PLANT_GRP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  CHECK_PLANT_GRP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_plant_grp .
  if OLD_OK_CODE = 'CRCROLES' and moduleid = 'MM'.
    IF ZIC_PREP_ROLEREI-plant is INITIAL.
     MESSAGE 'Please enter plant' TYPE 'I'.
     leave TO SCREEN sy-dynnr.
    ENDIF.

     IF ZIC_PREP_ROLEREI-grp is INITIAL.
     MESSAGE 'Please enter purchasing group' TYPE 'I'.
     leave TO SCREEN sy-dynnr.
    ENDIF.
    endif.
ENDFORM.
