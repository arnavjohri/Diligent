*&---------------------------------------------------------------------*
*& Include MZMMIMSTOP
*&
*&---------------------------------------------------------------------*

*Data declaration for container & grid in conatiner
DATA : g_custom_container TYPE REF TO cl_gui_custom_container,
       g_container        TYPE scrfname,
       grid1              TYPE REF TO cl_gui_alv_grid,
       gs_layout          TYPE lvc_s_layo,
       g_max              TYPE i VALUE 100,
       lt_celltab         TYPE lvc_t_styl,
       l_index            TYPE i,
       io_flag            TYPE c,
       l_mode             TYPE raw4,
       l_mode2            TYPE raw4.

DATA: ls_cell_color TYPE lvc_s_scol.

DATA : ref_grid TYPE REF TO cl_gui_alv_grid.

DATA : lv_ucomm TYPE sy-ucomm.
*Data declaration for Initial screen input parameters
DATA : p_company TYPE t880-rcomp,
       p_comp    TYPE t880-rcomp,
       p_proj    TYPE t8jv-vname,
       p_year    TYPE gjahr.
DATA: s_period_low(6)   TYPE c,
      s_period_high(15) TYPE c.

*Data declaration for status bar
DATA per_text(20) TYPE c.
DATA status TYPE icons-text.
DATA icon_type(20) TYPE c.
DATA icon_text(30) TYPE c.
DATA stat(10) TYPE c.

*Data declaration for period in reports
DATA : s_peri1  TYPE STANDARD TABLE OF selopt,
       wa_peri1 TYPE selopt.

DATA: fcode    TYPE TABLE OF sy-ucomm,
      wa_fcode TYPE sy-ucomm.

*Variables used in reports
DATA pnl(15) TYPE c.
DATA mode(3) TYPE c.
DATA ans(3)  TYPE c.
DATA lv_popup_txt(80) TYPE c.
DATA gl_msg_lines(5)  TYPE c.

DATA : it_prod_f4 TYPE STANDARD TABLE OF zfi_pnl_glf4,  "Table used to store the report texts
       it_oth_f4  TYPE STANDARD TABLE OF zfi_pnl_glf4.

DATA : lv_spl TYPE string VALUE 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,/;[]\<>?:"{}|!@#$%^&*()=_+'.

************************************************************************************************************
******************************For input help/dropdown list ***********************************************

DATA it_return LIKE STANDARD TABLE OF ddshretval WITH  HEADER LINE.

TYPES : BEGIN OF ty_company,
          txtcp   TYPE txt50,
          company TYPE rcomp_d,
        END OF ty_company.

TYPES : BEGIN OF ty_comp,
          txtcc TYPE txt50,
          bukrs TYPE bukrs,
        END OF ty_comp.

TYPES : BEGIN OF ty_proj,
          txtjv TYPE  txt50,
          jvnam TYPE jv_name,
        END OF ty_proj.

TYPES : BEGIN OF ty_period,
          per    TYPE grpcrta_period,
          period TYPE txt16,
        END OF ty_period.

TYPES : BEGIN OF ty_curr,
          curr TYPE waers,
        END OF ty_curr.

DATA : it_company  TYPE STANDARD TABLE OF ty_company,
       it_company2 TYPE STANDARD TABLE OF ty_company,
       it_comp     TYPE STANDARD TABLE OF ty_comp,
       it_proj     TYPE STANDARD TABLE OF ty_proj,
       it_period   TYPE STANDARD TABLE OF ty_period,
       wa_period   TYPE ty_period.


******************for other projects<<<<<<<<<<<<<<<<<<<<<<<<<<
TYPES: BEGIN OF ty_prd,
         jv(50)      TYPE c,
         jv_name(10) TYPE c,
         sh_prd_q1   TYPE  decfloat34,
         tot_sal_q1  TYPE  decfloat34,
         sh_prd_q2   TYPE  decfloat34,
         tot_sal_q2  TYPE  decfloat34,
         gas1        TYPE  decfloat34,
         gas2        TYPE  decfloat34,
         gas3        TYPE  decfloat34,
         gas4        TYPE  decfloat34,
         gas5        TYPE  decfloat34,
         gas6        TYPE  decfloat34,
         gas7        TYPE  decfloat34,
         gas8        TYPE  decfloat34,
         gas9        TYPE  decfloat34,
         gas10       TYPE  decfloat34,
         gas11       TYPE  decfloat34,
         gas12       TYPE  decfloat34,
       END OF ty_prd.

TYPES: BEGIN OF ty_rev,
         jv(10)      TYPE c,
         jv_name(50) TYPE c,
         sh_prd_q1   TYPE  decfloat34,
         tot_sal_q1  TYPE  decfloat34,
         sh_prd_q2   TYPE  decfloat34,
         tot_sal_q2  TYPE  decfloat34,
         gas1        TYPE  decfloat34,
         gas2        TYPE  decfloat34,
         gas3        TYPE  decfloat34,
         gas4        TYPE  decfloat34,
         gas5        TYPE  decfloat34,
         gas6        TYPE  decfloat34,
         gas7        TYPE  decfloat34,
         gas8        TYPE  decfloat34,
         gas9        TYPE  decfloat34,
         gas10       TYPE  decfloat34,
         gas11       TYPE  decfloat34,
         gas12       TYPE  decfloat34,
         gas13       TYPE  decfloat34,
         gas14       TYPE  decfloat34,
         gas15       TYPE  decfloat34,
         gas16       TYPE  decfloat34,
         gas17       TYPE  decfloat34,
         gas18       TYPE  decfloat34,
         gas19       TYPE  decfloat34,
         gas20       TYPE  decfloat34,
         gas21       TYPE  decfloat34,
         gas22       TYPE  decfloat34,
         gas23       TYPE  decfloat34,
         gas24       TYPE  decfloat34,
         gas25       TYPE  decfloat34,
         gas26       TYPE  decfloat34,
         gas27       TYPE  decfloat34,
         gas28       TYPE  decfloat34,
         gas29       TYPE  decfloat34,
         gas30       TYPE  decfloat34,
         gas31       TYPE  decfloat34,
         gas32       TYPE  decfloat34,

       END OF ty_rev.

TYPES: BEGIN OF ty_age,
         jv(50)      TYPE c,
         jv_name(50) TYPE c,
         sh_prd_q1   TYPE  decfloat34,
         tot_sal_q1  TYPE  decfloat34,
         sh_prd_q2   TYPE  decfloat34,
         tot_sal_q2  TYPE  decfloat34,
         gas1        TYPE  decfloat34,
         gas2        TYPE  decfloat34,
         gas3        TYPE  decfloat34,
         gas4        TYPE  decfloat34,
         gas5        TYPE  decfloat34,
         gas6        TYPE  decfloat34,
         gas7        TYPE  decfloat34,
         gas8        TYPE  decfloat34,
         gas9        TYPE  decfloat34,
         gas10       TYPE  decfloat34,
         gas11       TYPE  decfloat34,
         gas12       TYPE  decfloat34,

       END OF ty_age.

DATA: it_oil TYPE TABLE OF ty_prd,
      wa_oil TYPE ty_prd.

DATA: it_oil1 TYPE TABLE OF ty_rev,
      wa_oil1 TYPE ty_rev.

DATA: it_oil2 TYPE TABLE OF ty_age,
      wa_oil2 TYPE ty_age.
********************************
******************************For input help/dropdown list **********************************************
************************************************************************************************************

************************************************************************************************************
******************************For Quantitative Information **********************************************

TYPES :        BEGIN OF ty_quant,
                 io_flag(3) TYPE c,
                 sr_no(3)   TYPE c,
                 data(80)   TYPE c,
                 bbl(15)    TYPE c,
                 mmscm(15)  TYPE c,
                 mmbbl(15)  TYPE c,
                 mmt(15)    TYPE c,
                 ton(15)    TYPE c,
                 mmbtu(15)  TYPE c,
                 mmboe(15)  TYPE c,
                 bcm(15)    TYPE c,
               END OF ty_quant.

DATA : BEGIN OF it_quant OCCURS 0.
        INCLUDE TYPE ty_quant.
DATA : celltab TYPE lvc_t_styl.
DATA : END OF it_quant.

DATA : wa_quant LIKE it_quant.

DATA : bbl_mmbbl(7)   TYPE p DECIMALS 6 VALUE '0.000001',
       bbl_mmt(7)     TYPE p DECIMALS 6 VALUE '0.000001',
       ton_bbl(7)     TYPE p DECIMALS 6,
       mmscm_mmbtu(7) TYPE p DECIMALS 6,
       mmscm_mmboe(7) TYPE p DECIMALS 6 VALUE '0.0629',
       mmscm_bcm(7)   TYPE p DECIMALS 6 VALUE '0.001'.

DATA : it_final_qi_o TYPE STANDARD TABLE OF zpnl_qi_oil,
       wa_final_qi_o TYPE zpnl_qi_oil,
       it_final_qi_g TYPE STANDARD TABLE OF zpnl_qi_oil,
       wa_final_qi_g TYPE zpnl_qi_oil,
       it_final_conv TYPE STANDARD TABLE OF zpnl_qi_convo,
       wa_final_conv TYPE zpnl_qi_convo.

DATA : q_val1_o(15) TYPE c,
       q_val2_o(15) TYPE c,
       q_val1_g(15) TYPE c,
       q_val2_g(15) TYPE c.

DATA : wa_opstk_o TYPE zpnl_qi_oil.
DATA : wa_opstk_g TYPE zpnl_qi_gas.

*data declaration for GOS (attachments)
DATA : la_gos_dis  TYPE sibflporb.

*variable to attachment
DATA: lv_attano TYPE string.

******************************For Quantitative Information **********************************************
************************************************************************************************************

************************************************************************************************************
***********************For Profitabiity Statement Input PRODUCING Project *********************************

TYPES : BEGIN OF ty_prof_prd,
          io_flag(3) TYPE c,
          per(60)    TYPE c,
          oilng(10)  TYPE c,
          oil(10)    TYPE c,
          gas(10)    TYPE c,
        END OF ty_prof_prd.

TYPES : BEGIN OF ty_prof_prd2,
          io_flag(3) TYPE c,
          per(60)    TYPE c,
*          OILNG(10)  TYPE C,
*          OIL(10)    TYPE C,
*          GAS(10)    TYPE C,
          oilng      TYPE decfloat34,
          oil        TYPE decfloat34,
          gas        TYPE decfloat34,
        END OF ty_prof_prd2.

DATA : BEGIN OF it_prof_prd OCCURS 0.
        INCLUDE TYPE ty_prof_prd.
DATA : celltab TYPE lvc_t_styl.
DATA : END OF it_prof_prd.

DATA : BEGIN OF it_prof_prd2 OCCURS 0.
        INCLUDE TYPE ty_prof_prd2.
DATA : celltab TYPE lvc_t_styl.
DATA : END OF it_prof_prd2.

DATA : BEGIN OF it_prof_prd3 OCCURS 0.
        INCLUDE TYPE ty_prof_prd.
DATA : celltab TYPE lvc_t_styl.
DATA : END OF it_prof_prd3.

DATA : wa_prof_prd LIKE it_prof_prd.

DATA : lt_fcat TYPE STANDARD TABLE OF lvc_s_fcat,
       ls_fcat TYPE lvc_s_fcat.

DATA : it_prd_oil TYPE STANDARD TABLE OF zpnl_prd_oil,
       it_prd_gas TYPE STANDARD TABLE OF zpnl_prd_gas,
       wa_prd_oil TYPE zpnl_prd_oil,
       wa_prd_gas TYPE zpnl_prd_gas.


***********************For Profitabiity Statement Input PRODUCING Project *********************************
************************************************************************************************************


************************************************************************************************************
***********************For Profitabiity Statement Input OTHER PROJRCT ***********************************

TYPES : BEGIN OF ty_oth_proj,
          io_flag(3) TYPE c,
          per(80)    TYPE c,
          vals(20)   TYPE c,
        END OF ty_oth_proj.

DATA : BEGIN OF it_oth_proj OCCURS 0.
        INCLUDE TYPE ty_oth_proj.
DATA : celltab TYPE lvc_t_styl.
DATA : rowcolor(4) TYPE c.
DATA : cellcolor TYPE lvc_t_scol.
DATA : END OF it_oth_proj.

DATA : wa_oth_proj LIKE it_oth_proj.

DATA : lt_fcat_oth_proj TYPE STANDARD TABLE OF lvc_s_fcat,
       ls_fcat_oth_proj TYPE lvc_s_fcat.

DATA : it_pnl_oth TYPE STANDARD TABLE OF zpnl_oth_proj,
       wa_pnl_oth TYPE zpnl_oth_proj.

***********************For Profitabiity Statement Input  OTHER PROJRCT **********************************
************************************************************************************************************


************************************************************************************************************
***********************************************OTHERS****************************************************

DATA : it_fcat    TYPE STANDARD TABLE OF slis_fieldcat_alv,
       wa_fcat    TYPE slis_fieldcat_alv,
       it_fheader TYPE slis_t_listheader,
       wa_fheader TYPE slis_listheader,
       wa_layout  TYPE slis_layout_alv,
       it_sort    TYPE slis_t_sortinfo_alv,
       wa_sort    TYPE slis_sortinfo_alv,
       int_header TYPE slis_t_listheader,
       fs_header  TYPE slis_listheader.

DATA : it_fcat2   TYPE lvc_t_fcat,
       wa_fcat2   TYPE  lvc_s_fcat,
       wa_layout2 TYPE lvc_s_layo.

**********************************************OTHERS*****************************************************
************************************************************************************************************


************************************************************************************************************
***********************For Profitabiity Statement *****************************************************

*******************************************Producing*******************************************

TYPES : BEGIN OF ty_bar,
          sr_no(3)    TYPE c,
          per(60)     TYPE c,
          total1      TYPE decfloat34 , "P DECIMALS 2,
          oil1        TYPE decfloat34 , "P DECIMALS 2,
          gas1        TYPE decfloat34 , "P DECIMALS 2,
          total2      TYPE decfloat34 , "P DECIMALS 2,
          oil2        TYPE decfloat34 , "P DECIMALS 2,
          gas2        TYPE decfloat34 , "P DECIMALS 2,
          total3      TYPE decfloat34 , "P DECIMALS 2,
          oil3        TYPE decfloat34 , "P DECIMALS 2,
          gas3        TYPE decfloat34 , "P DECIMALS 2,
          total4      TYPE decfloat34 , "P DECIMALS 2,
          oil4        TYPE decfloat34 , "P DECIMALS 2,
          gas4        TYPE decfloat34 , "P DECIMALS 2,
*----------------" Changes begins by Aparna on 10.02.2024 "------------*
          remark      TYPE string,
          sel         TYPE c,
          field_style TYPE lvc_t_styl,
*----------------" Changes Ended by Aparna on 10.02.2024 "------------*
        END OF ty_bar.

TYPES : BEGIN OF ty_bar_temp,
          per(60)     TYPE c,
          total1(15)  TYPE c,
          oil1(15)    TYPE c,
          gas1(15)    TYPE c,
          total2(15)  TYPE c,
          oil2(15)    TYPE c,
          gas2(15)    TYPE c,
          total3(15)  TYPE c,
          oil3(15)    TYPE c,
          gas3(15)    TYPE c,
          total4(15)  TYPE c,
          oil4(15)    TYPE c,
          gas4(15)    TYPE c,
          remark(150) TYPE c,
        END OF ty_bar_temp.

DATA : it_final_bar1 TYPE STANDARD TABLE OF ty_bar,
       wa_final_bar1 TYPE ty_bar.

DATA : it_final_bar TYPE STANDARD TABLE OF ty_bar_temp,
       wa_final_bar TYPE ty_bar_temp.

DATA: wa_stylerow TYPE lvc_s_styl,
      it_styletab TYPE lvc_t_styl.

DATA dec(10) TYPE p DECIMALS 2 VALUE '0.00'.

DATA quater(8) TYPE c.

TYPES : BEGIN OF ty_setgls,           "Get GLs from set which are to be seperated in oil and gas fields
          setname  TYPE setleaf-setname,
          lineid   TYPE setleaf-lineid,
          valfrom  TYPE setleaf-valfrom,
          valto    TYPE setleaf-valto,
          descript TYPE text40,
        END OF ty_setgls.

DATA : it_setgls TYPE STANDARD TABLE OF ty_setgls,
       wa_setgls TYPE ty_setgls.
*************************************************END Producing************************************
************************************************NON Producing**********************************
TYPES : BEGIN OF ty_non_prd,
          per(65)     TYPE c,
          val1        TYPE decfloat34 , "P DECIMALS 2,
          val2        TYPE decfloat34 , "P DECIMALS 2,
          val3        TYPE decfloat34 , "P DECIMALS 2,
          val4        TYPE decfloat34 , "P DECIMALS 2,
*----------------" Changes begins by Aparna on 10.02.2024 "------------*
          remark      TYPE string,
          sel         TYPE c,
          field_style TYPE lvc_t_styl,
*----------------" Changes Ended by Aparna on 10.02.2024 "------------*

        END OF ty_non_prd.

DATA : it_final_non TYPE STANDARD TABLE OF ty_non_prd,
       wa_final_non TYPE ty_non_prd.

************************************************END NON Producing**********************************
************************************************VARIANCE ANALYSIS********************************
TYPES : BEGIN OF ty_var_prd,
          per(60)    TYPE c,
          total1(15) TYPE c,
          oil1(15)   TYPE c,
          gas1(15)   TYPE c,
          total2(15) TYPE c,
          oil2(15)   TYPE c,
          gas2(15)   TYPE c,
          total3(15) TYPE c,
          oil3(15)   TYPE c,
          gas3(15)   TYPE c,
          total4(15) TYPE c,
          oil4(15)   TYPE c,
          gas4(15)   TYPE c,
          remark     TYPE string,
        END OF ty_var_prd.

DATA : it_final_var_p TYPE STANDARD TABLE OF ty_var_prd,
       wa_final_var_p TYPE ty_var_prd.

DATA : it_agenda TYPE STANDARD TABLE OF zfi_agenda,
       wa_agenda TYPE zfi_agenda.
DATA: flag1 TYPE char1,
      flag2 TYPE char1,
      flag3 TYPE char1.
************************************************END VARIANCE ANAYISIS****************************
****************************************************************************************************

*Auto calculation (in case of manually entered project) to get Q2,Q3,Q4 values i.e. Q2 = Q1-H1, Q3 = H1-9M & Q4 = 9M-ANNUAL
DATA : peri1_1(6) TYPE c,
       peri1_2(6) TYPE c,
       peri2_1(6) TYPE c,
       peri2_2(6) TYPE c,
       peri3_1(6) TYPE c,
       peri3_2(6) TYPE c,
       peri4_1(6) TYPE c,
       peri4_2(6) TYPE c.

TYPES : BEGIN OF ty_alloct,
          fisyear TYPE zpnl_qi_oil-fisyear,
          zperiod TYPE zpnl_qi_oil-zperiod,
          sh_prod TYPE zpnl_qi_oil-sh_prod,
          sh_lift TYPE zpnl_qi_oil-sh_lift,
          tot_sal TYPE zpnl_qi_oil-tot_sal,
        END OF ty_alloct.

TYPES : BEGIN OF ty_alloct2,
          fisyear TYPE zpnl_qi_oil-fisyear,
          zperiod TYPE zpnl_qi_oil-zperiod,
          sh_prod TYPE decfloat34, "ZPNL_QI_OIL-SH_PROD,
          sh_lift TYPE decfloat34, "ZPNL_QI_OIL-SH_LIFT,
          tot_sal TYPE decfloat34, "ZPNL_QI_OIL-TOT_SAL,
        END OF ty_alloct2.

DATA : it_assoct_oil  TYPE STANDARD TABLE OF ty_alloct,
       it_assoct_gas  TYPE STANDARD TABLE OF ty_alloct,
       it_assoct_cnv  TYPE STANDARD TABLE OF zpnl_qi_convo,
       wa_assoct_oil1 TYPE ty_alloct,
       wa_assoct_gas1 TYPE ty_alloct,
       wa_assoct_oil2 TYPE ty_alloct,
       wa_assoct_gas2 TYPE ty_alloct,
       wa_assoct_oil3 TYPE ty_alloct,
       wa_assoct_gas3 TYPE ty_alloct,
       wa_assoct_oil4 TYPE ty_alloct,
       wa_assoct_gas4 TYPE ty_alloct.

TYPES : BEGIN OF ty_per_bar,
          per(60) TYPE c,

          oil1    TYPE decfloat34, "P DECIMALS 2,
          oilp1   TYPE decfloat34, "P DECIMALS 2,
          gas1    TYPE decfloat34, "P DECIMALS 2,
          gasp1   TYPE decfloat34, "P DECIMALS 2,

          oil2    TYPE decfloat34, "P DECIMALS 2,
          oilp2   TYPE decfloat34, "P DECIMALS 2,
          gas2    TYPE decfloat34, "P DECIMALS 2,
          gasp2   TYPE decfloat34, "P DECIMALS 2,

          oil3    TYPE decfloat34, "P DECIMALS 2,
          oilp3   TYPE decfloat34, "P DECIMALS 2,
          gas3    TYPE decfloat34, "P DECIMALS 2,
          gasp3   TYPE decfloat34, "P DECIMALS 2,

          oil4    TYPE decfloat34, "P DECIMALS 2,
          oilp4   TYPE decfloat34, "P DECIMALS 2,
          gas4    TYPE decfloat34, "P DECIMALS 2,
          gasp4   TYPE decfloat34, "P DECIMALS 2,
        END OF ty_per_bar.

DATA : it_final_per_bar TYPE STANDARD TABLE OF ty_per_bar,
       wa_final_per_bar TYPE ty_per_bar.

DATA : manual TYPE c,
       assoct TYPE c.

****************************************************************************************************
*************************************Profitability Analysis Report******************

DATA : lv_s_period(6) TYPE c.
DATA : lv_p_year TYPE gjahr.

DATA : it_pro_ana TYPE STANDARD TABLE OF ty_bar,
       wa_pro_ana TYPE ty_bar.

*************************************Profitability Analysis Report******************
****************************************************************************************************


****************************************************************************************************
*************************************Pednding Inputs Report******************

TYPES : BEGIN OF ty_pend,
          company        TYPE rcomp_d,
          bukrs          TYPE bukrs,
          pro_nam        TYPE jv_name,
          fisyear        TYPE gjahr,
          zperiod(6)     TYPE c,
          status(20)     TYPE c,
          fisyear1        TYPE gjahr,
          zperiod1(6)     TYPE c,
          created_by     TYPE sy-uname,
          created_on     TYPE sy-datum,
          approved_by    TYPE sy-uname,
          approved_on    TYPE sy-datum,
          approved_by_rp TYPE sy-uname,
          approved_on_rp TYPE sy-datum,
        END OF ty_pend.

DATA : lt_pend TYPE STANDARD TABLE OF ty_pend.
DATA : lt_pend_fin TYPE STANDARD TABLE OF ty_pend.
DATA : ls_pend  TYPE  ty_pend.

DATA : r_pqi TYPE c,  ""quant info
       r_ppp TYPE c,  ""prod proj
       r_pop TYPE c, ""oth proj
       r_var TYPE c, "" variance
       r_nvar TYPE c. "" non variance



*************************************Pednding Inputs Report******************
****************************************************************************************************


****************************************************************************************************
*************************************Selection Screen Declarations for Reports******************
DATA : p_year2            TYPE gjahr,
       p_year3            TYPE gjahr,
       p_year4            TYPE gjahr,
       s_period_low2(6)   TYPE c,
       s_period_high2(15) TYPE c,
       s_period_low3(6)   TYPE c,
       s_period_high3(15) TYPE c,
       s_period_low4(6)   TYPE c,
       s_period_high4(15) TYPE c.

DATA: lt_dynpfields TYPE TABLE OF dynpread,
      ls_dynpfields TYPE dynpread.


TABLES jvso1.


SELECTION-SCREEN  BEGIN OF SCREEN 411 AS SUBSCREEN.

PARAMETERS  p_compy1 TYPE rcomp_d .
PARAMETERS  p_comp1 TYPE bukrs .
SELECT-OPTIONS p_proj1 FOR jvso1-rjvnam NO INTERVALS NO-EXTENSION.
PARAMETERS p_year1 TYPE gjahr .
SELECT-OPTIONS s_period FOR s_period_low NO-EXTENSION NO INTERVALS.
SELECT-OPTIONS s_peri FOR s_period_low NO-DISPLAY.

SELECTION-SCREEN  END OF SCREEN 411.



AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_COMP1'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  IF p_compy1 IS NOT INITIAL.
    SELECT BUKRS
 FROM ZFI_PNL_PROJ INTO P_COMP1 UP TO 1 ROWS WHERE COMPANY = P_COMPY1
 ORDER BY PRIMARY KEY .
 ENDSELECT.
  ENDIF.

  IF  pnl = 'PRD_QTY' OR pnl = 'REV' OR pnl = 'BAR_REP' OR pnl = 'AGE_REP'.


    LOOP AT SCREEN.

      IF screen-name = 'P_PROJ1-LOW' OR screen-name = 'P_COMPY1'.

        screen-input = 0.

        MODIFY SCREEN.

      ENDIF.

    ENDLOOP.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_compy1.

  REFRESH it_company[].
  REFRESH it_return[].
  REFRESH it_company2[].

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
      dynpprog        = sy-repid
      dynpnr          = '0411'
      dynprofield     = 'P_COMPY1'
      value_org       = 'S'
    TABLES
      value_tab       = it_company
      return_tab      = it_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_comp1.

  REFRESH it_comp[].
  REFRESH it_return[].
  REFRESH lt_dynpfields.

  REFRESH lt_dynpfields[].
  ls_dynpfields-fieldname = 'P_COMPY1'.
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

  READ TABLE lt_dynpfields INTO ls_dynpfields WITH KEY fieldname = 'P_COMPY1'.
  IF ls_dynpfields IS NOT INITIAL.
    p_compy1 = ls_dynpfields-fieldvalue.
  ENDIF.

  IF p_compy1 IS NOT INITIAL.
    SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp WHERE company = p_compy1.
    SORT it_comp BY bukrs.
    DELETE ADJACENT DUPLICATES FROM it_comp COMPARING bukrs.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'BUKRS'
        dynpprog        = sy-repid
        dynpnr          = '0411'
        dynprofield     = 'P_COMP1'
        value_org       = 'S'
      TABLES
        value_tab       = it_comp
        return_tab      = it_return
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
*   Implement suitable error handling here
    ENDIF.
  ENDIF.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_proj1-low.                  """"change = p_proj1-low

  REFRESH it_proj[].
  CLEAR it_proj.
  REFRESH it_return[].
  REFRESH lt_dynpfields.


  REFRESH lt_dynpfields[].
  ls_dynpfields-fieldname = 'P_COMP1'.
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

  READ TABLE lt_dynpfields INTO ls_dynpfields WITH KEY fieldname = 'P_COMP1'.
  IF ls_dynpfields IS NOT INITIAL .
    p_comp1 = ls_dynpfields-fieldvalue.

  ENDIF.

  IF p_comp1 NE 'N/A' AND p_compy1 IS NOT INITIAL.
    IF pnl = 'PRD_PROJ'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs = p_comp1
      AND prod = 'YES'.
    ELSEIF pnl = 'NON_PRD'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs = p_comp1
      AND prod   = 'NO'.

    ELSEIF pnl = 'PER_BAR'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE bukrs = p_comp1
      AND prod = 'YES'.
    ELSEIF pnl = 'PRO_ANA' OR pnl = 'VAR_PRD'. " OR Condition added by Aparna on 05.08.2024

      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                      WHERE bukrs = p_comp1
                      AND   prod   = 'YES'.


    ELSE.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
      WHERE bukrs = p_comp1.
    ENDIF.

  ELSEIF p_comp1 EQ 'N/A' AND p_compy1 IS NOT INITIAL.
    IF pnl = 'PRD_PROJ'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE company = p_compy1
      AND prod   = 'YES'.
    ELSEIF pnl = 'NON_PRD'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE company = p_compy1
      AND prod   = 'NO'.


    ELSEIF pnl = 'PER_BAR'.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                         WHERE company = p_compy1
      AND prod   = 'YES'.

    ELSEIF pnl = 'PRO_ANA'.

      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                      WHERE company = p_compy1
      AND prod   = 'YES'.

    ELSE.
      SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
      WHERE company = p_compy1.
    ENDIF.

  ENDIF.

  SORT it_proj BY jvnam.
  DELETE ADJACENT DUPLICATES FROM it_proj COMPARING jvnam.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VNAME'
      dynpprog        = sy-cprog
      dynpnr          = '0401'
      dynprofield     = 'P_PROJ1-LOW'
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



AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_period-low.

  REFRESH it_return[].
  REFRESH it_period[].

  CLEAR wa_period.

  wa_period-period = 'Apr - Jun'.
  wa_period-per = 'Q1'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  wa_period-period = 'Jul - Sept'.
  wa_period-per = 'Q2'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  wa_period-period = 'Apr - Sept'.
  wa_period-per = 'H1'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  wa_period-period = 'Oct - Dec'.
  wa_period-per = 'Q3'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  wa_period-period = 'Apr - Dec'.
  wa_period-per = '9M'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  wa_period-period = 'Jan - Mar'.
  wa_period-per = 'Q4'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  wa_period-period = 'Apr - Mar'.
  wa_period-per = 'Annual'.
  APPEND wa_period TO it_period.
  CLEAR wa_period.

  break abapuser01.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PER'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'S_PERIOD-LOW'
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

*************************************Selection Screen Declarations for Reports******************
****************************************************************************************************

*********************************** For Profitabiity Statement Input ***********************************
************************************************************************************************************
