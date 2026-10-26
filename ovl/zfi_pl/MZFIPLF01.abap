CONSTANTS: line_length TYPE i VALUE 256.
TYPES: BEGIN OF t_texttable,
         line(line_length) TYPE c,
       END OF t_texttable .
DATA: l_dyndoc_id            TYPE REF TO cl_dd_document,
      l_splitter             TYPE REF TO cl_gui_splitter_container,
      l_parent_grid          TYPE REF TO cl_gui_container,
      l_html_cntrl           TYPE REF TO cl_gui_html_viewer,
      l_parent_html          TYPE REF TO cl_gui_container,

      g_editor               TYPE REF TO cl_gui_textedit,
      g_editor_container     TYPE REF TO cl_gui_custom_container,
      g_repid                LIKE sy-repid,
      g_ok_code              LIKE sy-ucomm,
      g_relink               TYPE c,
      g_mytable(line_length) TYPE c OCCURS 0,
      g_mycontainer(30)      TYPE c,
      g_container_linked     TYPE i,
      i_texttable            TYPE TABLE OF t_texttable,
      wa_texttable           TYPE t_texttable,
      val2                   TYPE string,
      val1                   TYPE i,
      l_grid                 TYPE REF TO cl_gui_alv_grid,
      it_zfi_val             TYPE TABLE OF zfi_pl_var_prd,
      it_zfi_non             TYPE TABLE OF zfi_pl_var_non,
      it_zfi_status          TYPE TABLE OF zfi_pl_status,
      it_zfi_status1         TYPE TABLE OF zfi_pl_status_n,
      wa_zfi_pl_var_prd      TYPE zfi_pl_var_prd,
      wa_zfi_pl_var_non      TYPE zfi_pl_var_non,
      wa_zfi_status          TYPE zfi_pl_status,
      wa_zfi_status1         TYPE zfi_pl_status_n.

*&---------------------------------------------------------------------*
*&  Include MZFIPLF01
*&---------------------------------------------------------------------*
FORM fetch_layout_texts.

  SELECT * FROM zfi_pnl_glf4 INTO TABLE it_prod_f4 WHERE prod_proj NE ' '.
  SELECT * FROM zfi_pnl_glf4 INTO TABLE it_oth_f4 WHERE oth_proj NE ' '.

  IF it_prod_f4 IS NOT INITIAL.
    SORT it_prod_f4 BY prod_proj.
    DELETE ADJACENT DUPLICATES FROM it_prod_f4 COMPARING prod_proj.
    SORT it_prod_f4 BY text_no.
  ENDIF.

  IF it_oth_f4 IS NOT INITIAL.
    SORT it_oth_f4 BY oth_proj.
    DELETE ADJACENT DUPLICATES FROM it_oth_f4 COMPARING oth_proj.
    SORT it_oth_f4 BY text_no.
  ENDIF.

ENDFORM."FETCH_LAYOUT_TEXTS

FORM projlist_maintain.                                                "Table Maintainance to maintain Project list and its related details

  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'                                 "Table Maintainance to maintain GLs for P&L Program
    EXPORTING
      action                       = 'S'
      view_name                    = 'ZFI_PNL_PROJ'
    EXCEPTIONS
      client_reference             = 1
      foreign_lock                 = 2
      invalid_action               = 3
      no_clientindependent_auth    = 4
      no_database_function         = 5
      no_editor_function           = 6
      no_show_auth                 = 7
      no_tvdir_entry               = 8
      no_upd_auth                  = 9
      only_show_allowed            = 10
      system_failure               = 11
      unknown_field_in_dba_sellist = 12
      view_not_found               = 13
      maintenance_prohibited       = 14
      OTHERS                       = 15.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM."PROJLIST_MAINTAIN.

FORM gl_maintain.

  CALL FUNCTION 'VIEW_MAINTENANCE_CALL'                                 "Table Maintainance to maintain GLs for P&L Program
    EXPORTING
      action                       = 'S'
      view_name                    = 'ZFI_PNL_GL'
    EXCEPTIONS
      client_reference             = 1
      foreign_lock                 = 2
      invalid_action               = 3
      no_clientindependent_auth    = 4
      no_database_function         = 5
      no_editor_function           = 6
      no_show_auth                 = 7
      no_tvdir_entry               = 8
      no_upd_auth                  = 9
      only_show_allowed            = 10
      system_failure               = 11
      unknown_field_in_dba_sellist = 12
      view_not_found               = 13
      maintenance_prohibited       = 14
      OTHERS                       = 15.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM."GL_MAINTAIN

FORM initail_chk. ""check mandatory input fields

  IF sy-ucomm = 'CREATE' OR sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY'
   OR sy-ucomm = 'APPROVE' OR sy-ucomm = 'FREEZE'.
    IF p_company IS INITIAL OR p_proj IS INITIAL
     OR p_year IS INITIAL OR s_period_low IS INITIAL." OR P_COMP IS INITIAL.

      CLEAR sy-ucomm.
      MESSAGE 'Fill in all required entry fields' TYPE 'E'.

    ENDIF.

    IF p_company IS NOT INITIAL.
      PERFORM fetch_comp_code.
    ENDIF.
  ENDIF.

ENDFORM."INITAIL_CHK

FORM fetch_comp_code.

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

ENDFORM.

FORM create_quant.   "Prepare screen and its input parameters for Quantitative Analysis

  "Openning stock should be Closing stock of previous annual period for oil only
  "Openning stock should be same and appear auto in all periods for that year for oil only

  CLEAR : wa_opstk_o,wa_opstk_g.

  IF pnl = 'PRO_ANA'.
    DATA(lv_year1) = lv_p_year - 1.
    p_company = p_compy1.
    p_comp    = p_comp1.
    p_proj    = p_proj1-low.
  ELSE.
    lv_year1 = p_year - 1.

  ENDIF.

  SELECT SINGLE * FROM zpnl_qi_oil INTO wa_opstk_o                   "get Quant Oil data
            WHERE company = p_company
              AND bukrs   = p_comp
              AND pro_nam = p_proj
              AND fisyear = lv_year1
              AND zperiod = 'ANNUAL' .

  SELECT SINGLE * FROM zpnl_qi_gas INTO wa_opstk_g                   "get Quant GAS data
        WHERE company = p_company
          AND bukrs   = p_comp
          AND pro_nam = p_proj
          AND fisyear = lv_year1
          AND zperiod = 'ANNUAL' .
*   ENDIF.

  CLEAR wa_quant.
  REFRESH : it_quant[],lt_fcat[].

  wa_quant-sr_no = '1'.
  wa_quant-data = 'Opening inventory:'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '1a'.
  wa_quant-data = 'Stock in Storage tanks/locations/FPSO'.
  IF mode = 'CRE' AND wa_opstk_o IS NOT INITIAL.
    wa_quant-bbl   = wa_opstk_o-cst_tnk.
    wa_quant-mmscm = wa_opstk_g-cst_tnk.
  ENDIF.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '1b'.
  wa_quant-data = 'Stock in pipelines/linefill'.
  IF mode = 'CRE' AND wa_opstk_o IS NOT INITIAL.
    wa_quant-bbl   = wa_opstk_o-cst_pip.
    wa_quant-mmscm = wa_opstk_g-cst_pip.
  ENDIF.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '2'.
  wa_quant-data = 'Share of Production'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '3'.
  wa_quant-data = 'Profit Oil/Gas:'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '3a'.
  wa_quant-data = 'State/Govt. share-lifted by OVL'.
*  wa_quant-data = 'State/Govt. share-lifted by OVL(applicable for Sakhalin-1)'." added aparna
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '3b'.
  wa_quant-data = 'State/Govt. share-taken by state in kind'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '4'.
  wa_quant-data = 'Share of entitled production (entitlement) (2-3)'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '5'.
  wa_quant-data = 'Royalty paid in kind & Transit Loss/Flaring etc.:'."'Transit Loss & Flaring:'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '5a'.
  wa_quant-data = 'Royalty paid in kind'."'Transit loss'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '5b'.
  wa_quant-data = 'Transit loss/Flaring etc.'."'Flaring/vented'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '6'.
  wa_quant-data = 'Production quantity after Royalty paid in kind, transit loss/flaring (4-5)'."'Production quantity after transit loss & flaring (4-5)'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '7'.
  wa_quant-data = 'Internal consumption:'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '7a'.
  wa_quant-data = 'Production activity'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '7b'.
  wa_quant-data = 'Others'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '8'.
  wa_quant-data = 'Net production quantity available (6-7)'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '9'.
  wa_quant-data = 'Closing Stock:'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '9a'.
  wa_quant-data = 'Stock in Storage tanks/locations/FPSO'.
  wa_quant-io_flag = '1'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '9b'.
  wa_quant-data = 'Stock in pipelines/linefill'.
  wa_quant-io_flag = '1'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '10'.
  wa_quant-data = 'Adj. for Changes in Inventories/Other adj.'.
  wa_quant-io_flag = '1'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '11'.
  wa_quant-data = 'Net quantity available for sale (8-9-10+1+3a)'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '12'.
  wa_quant-data = 'Overlift/(underlift) quantity (13-11)'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '13'.
  wa_quant-data = 'Total Sales quantity'.
  wa_quant-io_flag = '12'.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = ' '.
  wa_quant-data = ' '.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

  wa_quant-sr_no = '14'.
  wa_quant-data = 'Total Sales quantity-net of state share (13-3a)'.
  wa_quant-io_flag = ' '.
  APPEND wa_quant TO it_quant.
  CLEAR wa_quant.

*making field as input field or output only.
  IF ( mode EQ 'CRE' ) OR ( mode EQ 'CHA' ).

    CLEAR l_index.
    LOOP AT it_quant.
      l_index = sy-tabix.
      REFRESH lt_celltab.

      IF it_quant-io_flag = '12' .                         "Both oil and gas as input field i.e. Read and Write
        PERFORM fill_celltab_quant USING 'RW' '12'
                             CHANGING lt_celltab.
      ELSEIF it_quant-io_flag = '1'.                       "Only oil as input field
        PERFORM fill_celltab_quant USING 'RW' '1'
                             CHANGING lt_celltab.
      ELSE.
        PERFORM fill_celltab_quant USING 'RO' ' '        "Both as output field i.e Read Only
                             CHANGING lt_celltab.
      ENDIF.

      INSERT LINES OF lt_celltab INTO TABLE it_quant-celltab.
      MODIFY it_quant INDEX l_index.

    ENDLOOP.

  ENDIF.

ENDFORM. "CREATE_QUANT

FORM fill_celltab_quant USING VALUE(p_mode) VALUE(io_flag2)              ""making field as input field or output only
                  CHANGING pt_celltab TYPE lvc_t_styl.

  DATA : ls_celltab TYPE lvc_t_styl WITH HEADER LINE.

  CLEAR l_mode.

  IF p_mode EQ 'RW'.
    l_mode = cl_gui_alv_grid=>mc_style_enabled.
  ELSE.
    l_mode = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.


  ls_celltab-fieldname = 'DATA'.                                         "Column 1 - Field names
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'BBL'.                                        "Cloumn 2 - Oil(MMBBL)
  IF io_flag2 CA '1'.
    ls_celltab-style = l_mode.
  ELSE.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'MMSCM'.                                        "Columm 3 - Gas(MMBTU)
  IF io_flag2 CA '2'.
    ls_celltab-style = l_mode.
  ELSE.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.
  INSERT ls_celltab INTO TABLE pt_celltab.

*COLUMN no.4 to 9 are Output only and visible only in mode Display,Approve and Freeze.
  ls_celltab-fieldname = 'MMBBL'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'MMT'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'TON'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'MMBTU'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'MMBOE'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'BCM'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

ENDFORM. "fill_celltab_quant


FORM fcat_fill_quant . "Bulid field catalog for Quantitiatve Information

  DATA col_hide TYPE c.
  REFRESH lt_fcat[].

  IF ( mode EQ 'CRE' ) OR ( mode EQ 'CHA' ).
    col_hide = 'X'.                                         "Hiding cloumn 4-8 in create and change mode
  ELSE.
    col_hide = ' '.
  ENDIF.

  PERFORM alv_fcat_quant USING :  'SR_NO'   'No.'                      ' '        '3'     ,
                                  'DATA'    'Quantative Inforamtion'   ' '        '60'    ,
                                  'BBL'     'CRUDE OIL (BBL)'          ' '        '20'    ,
                                  'MMSCM'   'GAS (MMSCM)'              ' '        '20'    ,
                                  'MMBBL'   'CRUDE OIL (MMBBL)'        col_hide   '20'    ,
                                  'MMT'     'CRUDE OIL (MMT)'          col_hide   '20'    ,
                                  'TON'     'CRUDE OIL (Tonnes)'       col_hide   '20'    ,
                                  'MMBTU'   'GAS (Mn.MMBTU)'           col_hide   '20'    ,
                                  'MMBOE'   'GAS (MMBOE)'              col_hide   '20'    ,
                                  'BCM'     'GAS (BCM)'                col_hide   '20'    .

ENDFORM. "fcat_fill_quant

FORM alv_fcat_quant USING  VALUE(p_011)   ""Append field catalog table
                           VALUE(p_012)
                           VALUE(p_013)
                           VALUE(p_014).

  ls_fcat-fieldname   = p_011.
  ls_fcat-scrtext_l   = p_012.
  ls_fcat-no_out      = p_013.
  ls_fcat-outputlen   = p_014.

  APPEND ls_fcat TO lt_fcat.
  CLEAR ls_fcat.

ENDFORM.  " alv_fcat_quant

FORM cal_quant.   "calculate Quant Info values

  IF pnl NE 'PRO_ANA'.
    PERFORM conv_fact_chk.
    IF NOT grid1 IS INITIAL.
      CALL METHOD grid1->check_changed_data.
    ENDIF.
  ENDIF.

  DATA lv_msg1 TYPE string .

  IF mode EQ 'CRE'.
    CLEAR : wa_final_qi_o,wa_final_qi_g,wa_final_conv.
  ENDIF.

*moving input parameters to Oil, Gas & Conversion table
  wa_final_conv-company = wa_final_qi_g-company = wa_final_qi_o-company = p_company.
  wa_final_conv-bukrs   = wa_final_qi_g-bukrs   = wa_final_qi_o-bukrs   = p_comp.
  wa_final_conv-pro_nam = wa_final_qi_g-pro_nam = wa_final_qi_o-pro_nam = p_proj.
  wa_final_conv-fisyear = wa_final_qi_g-fisyear = wa_final_qi_o-fisyear = p_year.
  wa_final_conv-zperiod = wa_final_qi_g-zperiod = wa_final_qi_o-zperiod = s_period_low.

  wa_final_conv-bbl_mmbbl   = bbl_mmbbl.
  wa_final_conv-bbl_mmt     = bbl_mmt.
  wa_final_conv-ton_bbl     = ton_bbl.

  wa_final_conv-mmscm_mmbtu = mmscm_mmbtu.
  wa_final_conv-mmscm_mmboe = mmscm_mmboe.
  wa_final_conv-mmscm_bcm   = mmscm_bcm  .

  "variables for calc.
  DATA: prf_oil_o(15)  TYPE c, sh_ent_o(15) TYPE c, trl_flr_o(15) TYPE c, atrl_flr_o(15) TYPE c, int_con_o(15) TYPE c,
        prf_oil_g(15)  TYPE c, sh_ent_g(15) TYPE c, trl_flr_g(15) TYPE c, atrl_flr_g(15) TYPE c, int_con_g(15) TYPE c,

        net_prd_o(15)  TYPE c, opn_sto_o(15) TYPE c, clo_sto_o(15) TYPE c, chg_inv_o(15) TYPE c,
        net_prd_g(15)  TYPE c,                                             chg_inv_g(15) TYPE c.

  DATA : spl_flg TYPE c.


*check for any special characters
  IF pnl NE 'PRO_ANA'.
    LOOP AT it_quant INTO DATA(wa_quant_c).

      IF wa_quant_c-bbl CA lv_spl.
        CLEAR sy-ucomm.
        spl_flg = 'X'.
        MESSAGE 'Special character in amount field is not allowed' TYPE 'W' DISPLAY LIKE 'E'.
      ENDIF.
      IF wa_quant_c-mmscm CA lv_spl.
        CLEAR sy-ucomm.
        spl_flg = 'X'.
        MESSAGE 'Special character in amount field is not allowed' TYPE 'W' DISPLAY LIKE 'E'.
      ENDIF.

      CLEAR wa_quant_c.
    ENDLOOP.
  ENDIF.

  IF ton_bbl EQ '0.000000'. "to avoid divide by 0 error
    ton_bbl = '1'.
    DATA(ton_flg) = 'X'.
  ENDIF.

*     Calculate the values screen input/fetched (formula :- oil X conversion|gas X conversion||exception=>TON:- oil / Conversion)
  IF spl_flg NE 'X'.
    LOOP AT it_quant INTO wa_quant.
      CASE sy-tabix.
        WHEN 1.  " 1 Opening inventory OVL:
          IF mode = 'CRE'.
            PERFORM cal_quant_cre USING sy-tabix.       "fetch values from internal table to calculate total value i.e 2 = 3 + 4.

            wa_quant-bbl = opn_sto_o = q_val1_o + q_val2_o.

          ELSEIF mode NE 'CRE'.
            CLEAR opn_sto_o.
            wa_quant-bbl = opn_sto_o = wa_final_qi_o-ost_tnk + wa_final_qi_o-ost_pip.   "When 1 = 2 + 3.

          ENDIF.

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = 0 * mmscm_mmbtu.
          wa_quant-mmboe = 0 * mmscm_mmboe.
          wa_quant-bcm   = 0 * mmscm_bcm.

        WHEN 2.  " 1a Opening inventory OVL: Stock in Storage tanks/locations/FPSO
          wa_final_qi_o-ost_tnk = wa_quant-bbl.
*           " N/A for Gas

          wa_quant-mmbbl = wa_final_qi_o-ost_tnk * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-ost_tnk / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = 0 * mmscm_mmbtu.
          wa_quant-mmboe = 0 * mmscm_mmboe.
          wa_quant-bcm   = 0 * mmscm_bcm.

        WHEN 3.  "1b Opening inventory OVL: Stock in pipelines/linefill
          wa_final_qi_o-ost_pip = wa_quant-bbl.
          " N/A for Gas

          wa_quant-mmbbl = wa_final_qi_o-ost_pip * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-ost_pip / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = 0 * mmscm_mmbtu.
          wa_quant-mmboe = 0 * mmscm_mmboe.
          wa_quant-bcm   = 0 * mmscm_bcm.

        WHEN 5. "2 OVL share of Production
          wa_final_qi_o-sh_prod = wa_quant-bbl.
          wa_final_qi_g-sh_prod = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-sh_prod * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-sh_prod / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-sh_prod * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-sh_prod * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-sh_prod * mmscm_bcm.

        WHEN 7. "3 Profit Oil/Gas:
          CLEAR : prf_oil_o,prf_oil_g.

          IF mode = 'CRE'.
            PERFORM cal_quant_cre USING sy-tabix.

            wa_quant-bbl   = prf_oil_o = q_val1_o + q_val2_o.
            wa_quant-mmscm = prf_oil_g = q_val1_g + q_val2_g.

          ELSEIF mode NE 'CRE'.
            prf_oil_o = wa_quant-bbl   = wa_final_qi_o-sh_lift + wa_final_qi_o-sh_take.
            prf_oil_g = wa_quant-mmscm = wa_final_qi_g-sh_lift + wa_final_qi_g-sh_take.

          ENDIF.

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 8. "3a State/Govt. share-lifted by OVL
          wa_final_qi_o-sh_lift = wa_quant-bbl.
          wa_final_qi_g-sh_lift = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-sh_lift * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-sh_lift / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-sh_lift * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-sh_lift * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-sh_lift * mmscm_bcm.


        WHEN 9. "3b State/Govt. share-taken by state in kind
          wa_final_qi_o-sh_take = wa_quant-bbl.
          wa_final_qi_g-sh_take = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-sh_take * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-sh_take / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-sh_take * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-sh_take * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-sh_take * mmscm_bcm.


        WHEN 11.  "4 OVL share of entitled production (entitlement) (2-3)
          wa_quant-bbl   = sh_ent_o = wa_final_qi_o-sh_prod - prf_oil_o.  "     When 11 = 5 - 7
          wa_quant-mmscm = sh_ent_g = wa_final_qi_g-sh_prod - prf_oil_g.

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.

          CLEAR: prf_oil_o,
                 prf_oil_g.


        WHEN 13. "5 Transit Loss & Flaring:
          IF mode = 'CRE'.
            PERFORM cal_quant_cre USING sy-tabix.  "fetch values from the internal tables for further calculations

            wa_quant-bbl   = trl_flr_o = q_val1_o + q_val2_o.
            wa_quant-mmscm = trl_flr_g = q_val1_g + q_val2_g.

          ELSEIF mode NE 'CRE'.

            wa_quant-bbl   = trl_flr_o = wa_final_qi_o-trn_los + wa_final_qi_o-fl_vent.  " When 13 = 14 + 15
            wa_quant-mmscm = trl_flr_g = wa_final_qi_g-trn_los + wa_final_qi_g-fl_vent.

          ENDIF.

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 14.    "5a Transit loss
          wa_final_qi_o-trn_los = wa_quant-bbl.
          wa_final_qi_g-trn_los = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-trn_los * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-trn_los / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-trn_los * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-trn_los * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-trn_los * mmscm_bcm.


        WHEN 15. "5b Flaring/vented
          wa_final_qi_o-fl_vent = wa_quant-bbl.
          wa_final_qi_g-fl_vent = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-fl_vent * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-fl_vent / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-fl_vent * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-fl_vent * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-fl_vent * mmscm_bcm.


        WHEN 17.  "6 Production quantity after transit loss & flaring (4-5)
          wa_quant-bbl   = atrl_flr_o = sh_ent_o - trl_flr_o .            " When 17 = 11 - 13
          wa_quant-mmscm = atrl_flr_g = sh_ent_g - trl_flr_g .

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 19. "7 Internal consumption:
          IF mode = 'CRE'.
            PERFORM cal_quant_cre USING sy-tabix.

            wa_quant-bbl   = int_con_o = q_val1_o + q_val2_o.
            wa_quant-mmscm = int_con_g = q_val1_g + q_val2_g.

          ELSEIF mode NE 'CRE'.
            wa_quant-bbl   = int_con_o = wa_final_qi_o-prd_act + wa_final_qi_o-others .    "When 19 = 20 + 21
            wa_quant-mmscm = int_con_g = wa_final_qi_g-prd_act + wa_final_qi_g-others .

          ENDIF.

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 20. "7a Production activity
          wa_final_qi_o-prd_act = wa_quant-bbl.
          wa_final_qi_g-prd_act = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-prd_act * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-prd_act / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-prd_act * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-prd_act * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-prd_act * mmscm_bcm.


        WHEN 21. "7b Others
          wa_final_qi_o-others = wa_quant-bbl.
          wa_final_qi_g-others = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-others * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-others / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-others * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-others * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-others * mmscm_bcm.


        WHEN 23. "8 Net production quantity available (6-7)
          wa_quant-bbl   = net_prd_o = atrl_flr_o - int_con_o .            " When 23 = 17 - 19
          wa_quant-mmscm = net_prd_g = atrl_flr_g - int_con_g .

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 25. "9 Closing Stock:
          IF mode = 'CRE'.
            PERFORM cal_quant_cre USING sy-tabix.

            wa_quant-bbl = clo_sto_o = q_val1_o + q_val2_o.

          ELSEIF mode NE 'CRE'.
            wa_quant-bbl = clo_sto_o = wa_final_qi_o-cst_tnk + wa_final_qi_o-cst_pip .      "When 25 = 26 + 27

          ENDIF.

          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 26. "9a Stock in Storage tanks/locations/FPSO
          wa_final_qi_o-cst_tnk = wa_quant-bbl.

          wa_quant-mmbbl = wa_final_qi_o-cst_tnk * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-cst_tnk / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = 0 * mmscm_mmbtu.
          wa_quant-mmboe = 0 * mmscm_mmboe.
          wa_quant-bcm   = 0 * mmscm_bcm.


        WHEN 27. "9b Stock in pipelines/linefill
          wa_final_qi_o-cst_pip = wa_quant-bbl.
          "N/A for gas

          wa_quant-mmbbl = wa_final_qi_o-cst_pip * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-cst_pip / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = 0 * mmscm_mmbtu.
          wa_quant-mmboe = 0 * mmscm_mmboe.
          wa_quant-bcm   = 0 * mmscm_bcm.


        WHEN 29. "10 Adj. for Changes in Inventories/Other adj.
          wa_final_qi_o-ch_invt = chg_inv_o = wa_quant-bbl.
          wa_final_qi_g-ch_invt = chg_inv_g = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-ch_invt * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-ch_invt / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-ch_invt * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-ch_invt * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-ch_invt * mmscm_bcm.


        WHEN 31.  "11 Net quantity available for sale (8-9-10+1+3a)
          wa_quant-bbl   = net_prd_o - clo_sto_o - chg_inv_o + opn_sto_o + wa_final_qi_o-sh_lift.
          wa_quant-mmscm = net_prd_g - chg_inv_g + wa_final_qi_g-sh_lift.
          "When 31 = 23 - 25 - 29 + 1 + 8.
          wa_quant-mmbbl = wa_quant-bbl * bbl_mmbbl.
          wa_quant-ton   = wa_quant-bbl / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_quant-mmscm * mmscm_mmbtu.
          wa_quant-mmboe = wa_quant-mmscm * mmscm_mmboe.
          wa_quant-bcm   = wa_quant-mmscm * mmscm_bcm.


        WHEN 33. "12 Overlift/(underlift) quantity
          IF mode = 'CRE'.
            PERFORM cal_quant_cre USING sy-tabix.

            wa_final_qi_o-ovr_und = wa_quant-bbl = ( q_val2_o ) - ( net_prd_o - clo_sto_o - chg_inv_o + opn_sto_o + wa_final_qi_o-sh_lift ).
            "N/A for gas

          ELSEIF mode NE 'CRE'.
            wa_final_qi_o-ovr_und = wa_quant-bbl = ( wa_final_qi_o-tot_sal ) - ( net_prd_o - clo_sto_o - chg_inv_o + opn_sto_o + wa_final_qi_o-sh_lift ).        " 35 = 36 - 33
            "N/A for gas
          ENDIF.

          wa_quant-mmbbl = wa_final_qi_o-ovr_und * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-ovr_und / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = 0 * mmscm_mmbtu.
          wa_quant-mmboe = 0 * mmscm_mmboe.
          wa_quant-bcm   = 0 * mmscm_bcm.


        WHEN 35.  "13 Total Sales quantity
          wa_final_qi_o-tot_sal = wa_quant-bbl.
          wa_final_qi_g-tot_sal = wa_quant-mmscm.

          wa_quant-mmbbl = wa_final_qi_o-tot_sal * bbl_mmbbl.
          wa_quant-ton   = wa_final_qi_o-tot_sal / ton_bbl.
          wa_quant-mmt   = wa_quant-ton * bbl_mmt.

          wa_quant-mmbtu = wa_final_qi_g-tot_sal * mmscm_mmbtu.
          wa_quant-mmboe = wa_final_qi_g-tot_sal * mmscm_mmboe.
          wa_quant-bcm   = wa_final_qi_g-tot_sal * mmscm_bcm.

        WHEN 37.  "14 Total Sales quantity-net of state share (13-3a)
          READ TABLE it_quant INTO DATA(wa_quant_z1) INDEX 8.
          READ TABLE it_quant INTO DATA(wa_quant_z2) INDEX 35.
          wa_quant-bbl   = wa_quant_z2-bbl - wa_quant_z1-bbl.
          wa_quant-mmscm = wa_quant_z2-mmscm - wa_quant_z1-mmscm.

          wa_quant-mmbbl = wa_quant_z2-mmbbl - wa_quant_z1-mmbbl.
          wa_quant-ton   = wa_quant_z2-ton - wa_quant_z1-ton.
          wa_quant-mmt   = wa_quant_z2-mmt - wa_quant_z1-mmt.

          wa_quant-mmbtu = wa_quant_z2-mmbtu - wa_quant_z1-mmbtu.
          wa_quant-mmboe = wa_quant_z2-mmboe - wa_quant_z1-mmboe.
          wa_quant-bcm   = wa_quant_z2-bcm - wa_quant_z1-bcm.

          CLEAR : wa_quant_z1,wa_quant_z2.
      ENDCASE.


      IF ( mode NE 'CRE' ) OR ( mode NE 'CHA' ).
        IF sy-ucomm = 'SAVE'.

          IF wa_quant-io_flag CA '1'.        "Check Mandatory fields for OIL column
            IF wa_quant-bbl = ' '.
              CLEAR : sy-ucomm,lv_msg1.
              CONCATENATE 'Field' wa_quant-data 'of BBL column cannot be blank' INTO lv_msg1 SEPARATED BY space.
              MESSAGE lv_msg1 TYPE 'E'.
            ENDIF.
          ENDIF.

          IF wa_quant-io_flag CA '2'.         "Check Mandatory fields for GAS column
            IF wa_quant-mmscm = ' '.
              CLEAR : sy-ucomm,lv_msg1.
              CONCATENATE 'Field' wa_quant-data 'of MMSCM column cannot be blank' INTO lv_msg1 SEPARATED BY space.
              MESSAGE lv_msg1 TYPE 'E'.
            ENDIF.
          ENDIF.

        ENDIF.

        IF wa_quant-bbl IS NOT INITIAL.  "round off all values to 3 decimals
          wa_quant-bbl   = round( val = wa_quant-bbl   dec = '3' ).
          wa_quant-mmbbl = round( val = wa_quant-mmbbl dec = '3' ).
          wa_quant-mmt   = round( val = wa_quant-mmt   dec = '3' ).
          wa_quant-ton   = round( val = wa_quant-ton   dec = '3' ).
        ENDIF.

        IF wa_quant-mmscm IS NOT INITIAL. "round off all values to 3 decimals
          wa_quant-mmscm = round( val = wa_quant-mmscm dec = '3' ).
          wa_quant-mmbtu = round( val = wa_quant-mmbtu dec = '3' ).
          wa_quant-mmboe = round( val = wa_quant-mmboe dec = '3' ).
          wa_quant-bcm   = round( val = wa_quant-bcm   dec = '3' ).
        ENDIF.

        MODIFY it_quant FROM wa_quant TRANSPORTING bbl mmscm mmbbl mmt ton mmbtu mmboe bcm.
        CLEAR wa_quant.

      ENDIF.

    ENDLOOP.
  ENDIF.

  IF ton_flg = 'X'.
    CLEAR ton_bbl.
  ENDIF.
  CLEAR ton_flg.

  CLEAR : prf_oil_o, sh_ent_o, trl_flr_o, atrl_flr_o, int_con_o,
          prf_oil_g, sh_ent_g, trl_flr_g, atrl_flr_g, int_con_g,
          net_prd_o, opn_sto_o, clo_sto_o, chg_inv_o, chg_inv_o,
          net_prd_g,                                  chg_inv_g.



ENDFORM."CAL_QUANT


FORM cal_quant_cre USING VALUE(quant_indx). "fetch values from the internal tables for further calculations

  CLEAR : q_val1_o,q_val2_o,q_val1_g,q_val2_g.
  quant_indx = quant_indx + 1.

  READ TABLE it_quant INTO DATA(wa_quant2) INDEX quant_indx.
  q_val1_o = wa_quant2-bbl.
  q_val1_g = wa_quant2-mmscm.

  CLEAR wa_quant2.
  quant_indx = quant_indx + 1.
  READ TABLE it_quant INTO wa_quant2 INDEX quant_indx.
  q_val2_o = wa_quant2-bbl.
  q_val2_g = wa_quant2-mmscm.

ENDFORM. "CAL_QUANT_CRE


FORM save_quant.      "Save Quant Info data into database tables

  IF ( mode NE 'DIS' ) .

    PERFORM chk_before_save.   "checking (1a+8-13=9a) and conv factor not blank

    PERFORM popup_save.        "confirmation before saving to database tables

    IF ( mode EQ 'CRE' ) .     "update status as Created and user detials
      wa_final_conv-created_by = wa_final_qi_g-created_by = wa_final_qi_o-created_by  = sy-uname.
      wa_final_conv-created_on = wa_final_qi_g-created_on = wa_final_qi_o-created_on  = sy-datum.

    ELSEIF ( mode EQ 'CHA' ) .  "update status as Changed and user detials
      wa_final_conv-changed_by = wa_final_qi_g-changed_by = wa_final_qi_o-changed_by  = sy-uname.
      wa_final_conv-changed_on = wa_final_qi_g-changed_on = wa_final_qi_o-changed_on  = sy-datum.

      wa_final_conv-approved_by = wa_final_qi_g-approved_by = wa_final_qi_o-approved_by  = ' '.
      wa_final_conv-approved_on = wa_final_qi_g-approved_on = wa_final_qi_o-approved_on  = '00000000'.

    ENDIF.

    IF ans = '1'.   "save data into database tables on confirmation
      MODIFY zpnl_qi_oil FROM wa_final_qi_o.   "Save oil data into oil table
      CLEAR wa_final_qi_o.

      MODIFY zpnl_qi_gas FROM wa_final_qi_g.   "Save gas data into gas table
      CLEAR wa_final_qi_g.

      MODIFY zpnl_qi_convo FROM wa_final_conv. "Save conversion factor data into conversion factor
      CLEAR wa_final_conv.

      MESSAGE 'Data saved successfully.' TYPE 'S'.

    ENDIF.
    CLEAR ans.

  ENDIF.

ENDFORM."SAVE_QUANT

FORM app_quant.

  IF mode EQ 'FRE'.
    IF wa_final_qi_g-approved_by IS INITIAL AND wa_final_qi_o-approved_by IS INITIAL.
      MESSAGE 'Data is not approved yet' TYPE 'E'.
    ENDIF.
  ENDIF.

  PERFORM popup_save.    "confirmation popup before save

  IF ans = '1'.   "on confirmation
    IF ( mode EQ 'APP' ) .   "update the status and user details internally
      wa_final_conv-approved_by = wa_final_qi_g-approved_by = wa_final_qi_o-approved_by  = sy-uname.
      wa_final_conv-approved_on = wa_final_qi_g-approved_on = wa_final_qi_o-approved_on  = sy-datum.
      stat = 'APPROVED'.

    ELSEIF ( mode EQ 'FRE' ) .  "update the status and user details internally
      wa_final_conv-freezed_by = wa_final_qi_g-freezed_by = wa_final_qi_o-freezed_by  = sy-uname.
      wa_final_conv-freezed_on = wa_final_qi_g-freezed_on = wa_final_qi_o-freezed_on  = sy-datum.
      stat = 'FREEZED'.
*********ADDED BY APARNA 03.07.2024
    ELSEIF ( mode EQ 'APF' ) .  "update the status and user details internally
      wa_final_conv-approved_by_rp = wa_final_qi_g-approved_by_rp = wa_final_qi_o-approved_by_rp  = sy-uname.
      wa_final_conv-approved_on_rp = wa_final_qi_g-approved_on_rp = wa_final_qi_o-approved_on_rp  = sy-datum.
      stat = 'APPROVED'.
    ENDIF.
***************ENDED BY APARNA 03.07.2024

    IF mode = 'APP'.  "update status as approve and user details in database tables
      wa_final_conv-approved_by = wa_final_qi_g-approved_by = wa_final_qi_o-approved_by  = sy-uname.
      wa_final_conv-approved_on = wa_final_qi_g-approved_on = wa_final_qi_o-approved_on  = sy-datum.


      MODIFY zpnl_qi_oil FROM wa_final_qi_o.
      CLEAR wa_final_qi_o.

      MODIFY zpnl_qi_gas FROM wa_final_qi_g.
      CLEAR wa_final_qi_g.

      MODIFY zpnl_qi_convo FROM wa_final_conv.
      CLEAR wa_final_conv.

      MESSAGE 'Data has been approved.' TYPE 'S'.

*******************      ADDED BY APARNA ON 03.07.2024

    ELSEIF mode = 'APF'.  "update status as approve and user details in database tables
      wa_final_conv-approved_by_rp = wa_final_qi_g-approved_by_rp = wa_final_qi_o-approved_by_rp  = sy-uname.
      wa_final_conv-approved_on_rp = wa_final_qi_g-approved_on_rp = wa_final_qi_o-approved_on_rp  = sy-datum.


      MODIFY zpnl_qi_oil FROM wa_final_qi_o.
      CLEAR wa_final_qi_o.

      MODIFY zpnl_qi_gas FROM wa_final_qi_g.
      CLEAR wa_final_qi_g.

      MODIFY zpnl_qi_convo FROM wa_final_conv.
      CLEAR wa_final_conv.

      MESSAGE 'Data has been approved.' TYPE 'S'.

********      ENDED BY APARNA ON 03.07.2024

    ELSEIF mode = 'FRE'.    "update status as freeze and user details in database tables
      wa_final_conv-freezed_by = wa_final_qi_g-freezed_by = wa_final_qi_o-freezed_by  = sy-uname.
      wa_final_conv-freezed_on = wa_final_qi_g-freezed_on = wa_final_qi_o-freezed_on  = sy-datum.

      MODIFY zpnl_qi_oil FROM wa_final_qi_o.
      CLEAR wa_final_qi_o.

      MODIFY zpnl_qi_gas FROM wa_final_qi_g.
      CLEAR wa_final_qi_g.

      MODIFY zpnl_qi_convo FROM wa_final_conv.
      CLEAR wa_final_conv.

      MESSAGE 'Data has been freezed. You cannot change this data now.' TYPE 'S'.

    ENDIF.
  ENDIF.

ENDFORM."APP_QUANT

FORM fetch_quant.  "Fetch saved/created data from tables

  DATA s_period_low_1(6) TYPE c.
  DATA s_period_low_2(6) TYPE c.
  DATA auto_cal TYPE c.

  DATA : wa_final_qi_o_1 TYPE zpnl_qi_oil,
         wa_final_qi_g_1 TYPE zpnl_qi_oil,
         wa_final_conv_1 TYPE zpnl_qi_convo.

  CLEAR : s_period_low_1,s_period_low_2,auto_cal.

  IF pnl = 'PRO_ANA'.
    p_company = p_compy1.
    p_comp    = p_comp1.
    p_proj    = p_proj1-low.
    p_year    = lv_p_year.
    s_period_low = lv_s_period.
  ENDIF.

  IF s_period_low EQ 'Q2'.     "Get periods to cal. values for Q2,Q3,Q4.
    s_period_low_1 = 'Q1'.
    s_period_low_2 = 'H1'.
    auto_cal = 'X'.            "Set automatic cal. flag
  ELSEIF s_period_low EQ 'Q3'.
    s_period_low_1 = 'H1'.
    s_period_low_2 = '9M'.
    auto_cal = 'X'.
  ELSEIF s_period_low EQ 'Q4'.
    s_period_low_1 = '9M'.
    s_period_low_2 = 'ANNUAL'.
    auto_cal = 'X'.
  ELSEIF s_period_low IS NOT INITIAL.
    auto_cal = ' '.
  ENDIF.

  REFRESH : it_final_qi_o, it_final_qi_g , it_final_conv .

  IF auto_cal = ' '.

    SELECT * FROM zpnl_qi_oil INTO TABLE it_final_qi_o                  "get Quant Oil data
            WHERE company = p_company
              AND bukrs = p_comp
              AND pro_nam = p_proj
              AND fisyear = p_year
              AND zperiod = s_period_low .

    SELECT * FROM zpnl_qi_gas INTO TABLE it_final_qi_g                  "get Quant Gas data
             WHERE company = p_company
             AND bukrs = p_comp
             AND pro_nam = p_proj
             AND fisyear = p_year
             AND zperiod = s_period_low .

    SELECT * FROM zpnl_qi_convo INTO TABLE it_final_conv                "get Conversion factors
           WHERE company = p_company
             AND bukrs = p_comp
             AND pro_nam = p_proj
             AND fisyear = p_year
             AND zperiod = s_period_low .

  ELSEIF auto_cal = 'X'.

    SELECT * FROM zpnl_qi_oil INTO TABLE it_final_qi_o                  "get Quant Oil data
            WHERE company = p_company
              AND bukrs = p_comp
              AND pro_nam = p_proj
              AND fisyear = p_year
              AND zperiod IN ( s_period_low_1 , s_period_low_2 ).

    SELECT * FROM zpnl_qi_gas INTO TABLE it_final_qi_g                  "get Quant Gas data
             WHERE company = p_company
             AND bukrs = p_comp
             AND pro_nam = p_proj
             AND fisyear = p_year
             AND zperiod IN ( s_period_low_1 , s_period_low_2 ).

    SELECT * FROM zpnl_qi_convo INTO TABLE it_final_conv                "get Conversion factors
           WHERE company = p_company
             AND bukrs = p_comp
             AND pro_nam = p_proj
             AND fisyear = p_year
             AND zperiod IN ( s_period_low_1 , s_period_low_2 ).

  ENDIF.

  IF it_final_qi_o IS INITIAL AND it_final_qi_g IS INITIAL ."AND IT_FINAL_CONV IS INITIAL .

    CLEAR sy-ucomm.
    MESSAGE 'Data not found for given input parameters' TYPE 'E' DISPLAY LIKE 'I'.

  ELSE.

    IF auto_cal = ' '.   "if period is Q1,H1,9M and Annual
      READ TABLE it_final_qi_o INTO wa_final_qi_o WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low .
      READ TABLE it_final_qi_g INTO wa_final_qi_g WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low .
      READ TABLE it_final_conv INTO wa_final_conv WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low .

    ELSEIF auto_cal = 'X'. "if period is Q2,Q3,Q4
      CLEAR : wa_final_qi_o , wa_final_qi_o_1 , wa_final_qi_g , wa_final_qi_g_1.
******Oil calculation for Q2,Q3,Q4
      READ TABLE it_final_qi_o INTO wa_final_qi_o WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low_2 .

      READ TABLE it_final_qi_o INTO wa_final_qi_o_1 WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low_1 .

******Gas calculation for Q2,Q3,Q4
      READ TABLE it_final_qi_g INTO wa_final_qi_g WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low_2 .

      READ TABLE it_final_qi_g INTO wa_final_qi_g_1 WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low_1 .

******Conversion calculation for Q2,Q3,Q4
      READ TABLE it_final_conv INTO wa_final_conv WITH KEY company = p_company
                                                           bukrs = p_comp
                                                           pro_nam = p_proj
                                                           fisyear = p_year
                                                           zperiod = s_period_low_2 .

      READ TABLE it_final_conv INTO wa_final_conv_1 WITH KEY company = p_company
                                                             bukrs = p_comp
                                                             pro_nam = p_proj
                                                             fisyear = p_year
                                                             zperiod = s_period_low_1 .
    ENDIF.

    LOOP AT it_quant INTO wa_quant.  "move data from oil and gas tables into corresponding fields of internal table
      CASE sy-tabix.
*           WHEN 1 . " 1  Opening inventory OVL:
        WHEN 2. "1a Stock in Storage tanks/locations/FPSO
          IF auto_cal = 'X'.
            wa_final_qi_o-ost_tnk = wa_final_qi_o_1-cst_tnk.
            wa_final_qi_g-ost_tnk = wa_final_qi_g_1-cst_tnk.
          ELSE.
            wa_final_qi_o-ost_tnk = wa_opstk_o-cst_tnk.
            wa_final_qi_g-ost_tnk = wa_opstk_g-cst_tnk.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-ost_tnk.
          wa_quant-mmscm = wa_final_qi_g-ost_tnk.

        WHEN 3. "1b Stock in pipelines/linefill
          IF auto_cal = 'X'.
            wa_final_qi_o-ost_pip = wa_final_qi_o_1-cst_pip.
            wa_final_qi_g-ost_pip = wa_final_qi_g_1-cst_pip.
          ELSE.
            wa_final_qi_o-ost_pip = wa_opstk_o-cst_pip.
            wa_final_qi_g-ost_pip = wa_opstk_g-cst_pip.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-ost_pip.
          wa_quant-mmscm = wa_final_qi_g-ost_pip.

        WHEN 5. "2 OVL share of Production
          IF auto_cal = 'X'.
            wa_final_qi_o-sh_prod = wa_final_qi_o-sh_prod - wa_final_qi_o_1-sh_prod.
            wa_final_qi_g-sh_prod = wa_final_qi_g-sh_prod - wa_final_qi_g_1-sh_prod.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-sh_prod.
          wa_quant-mmscm = wa_final_qi_g-sh_prod.

        WHEN 8. "3a State/Govt. share-lifted by OVL
          IF auto_cal = 'X'.
            wa_final_qi_o-sh_lift = wa_final_qi_o-sh_lift - wa_final_qi_o_1-sh_lift.
            wa_final_qi_g-sh_lift = wa_final_qi_g-sh_lift - wa_final_qi_g_1-sh_lift.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-sh_lift.
          wa_quant-mmscm = wa_final_qi_g-sh_lift.

        WHEN 9. "3b State/Govt. share-taken by state in kind
          IF auto_cal = 'X'.
            wa_final_qi_o-sh_take = wa_final_qi_o-sh_take - wa_final_qi_o_1-sh_take.
            wa_final_qi_g-sh_take = wa_final_qi_g-sh_take - wa_final_qi_g_1-sh_take.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-sh_take.
          wa_quant-mmscm = wa_final_qi_g-sh_take.

        WHEN 14. "5a  Transit loss
          IF auto_cal = 'X'.
            wa_final_qi_o-trn_los = wa_final_qi_o-trn_los - wa_final_qi_o_1-trn_los.
            wa_final_qi_g-trn_los = wa_final_qi_g-trn_los - wa_final_qi_g_1-trn_los.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-trn_los.
          wa_quant-mmscm = wa_final_qi_g-trn_los.

        WHEN 15. "5b  Flaring/vented
          IF auto_cal = 'X'.
            wa_final_qi_o-fl_vent = wa_final_qi_o-fl_vent - wa_final_qi_o_1-fl_vent.
            wa_final_qi_g-fl_vent = wa_final_qi_g-fl_vent - wa_final_qi_g_1-fl_vent.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-fl_vent.
          wa_quant-mmscm = wa_final_qi_g-fl_vent.

        WHEN 20. "7a  Production activity
          IF auto_cal = 'X'.
            wa_final_qi_o-prd_act = wa_final_qi_o-prd_act - wa_final_qi_o_1-prd_act.
            wa_final_qi_g-prd_act = wa_final_qi_g-prd_act - wa_final_qi_g_1-prd_act.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-prd_act.
          wa_quant-mmscm = wa_final_qi_g-prd_act.

        WHEN 21. "7b  Others
          IF auto_cal = 'X'.
            wa_final_qi_o-others = wa_final_qi_o-others - wa_final_qi_o_1-others.
            wa_final_qi_g-others = wa_final_qi_g-others - wa_final_qi_g_1-others.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-others.
          wa_quant-mmscm = wa_final_qi_g-others.

        WHEN 26. "9a  Stock in Storage tanks/locations/FPSO
          IF auto_cal = 'X'.
            wa_final_qi_o-cst_tnk = wa_final_qi_o-cst_tnk.
            wa_final_qi_g-cst_tnk = wa_final_qi_g-cst_tnk.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-cst_tnk.
          wa_quant-mmscm = wa_final_qi_g-cst_tnk.

        WHEN 27. "9b  Stock in pipelines/linefill
          IF auto_cal = 'X'.
            wa_final_qi_o-cst_pip = wa_final_qi_o-cst_pip.
            wa_final_qi_g-cst_pip = wa_final_qi_g-cst_pip.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-cst_pip.
          wa_quant-mmscm = wa_final_qi_g-cst_pip.

        WHEN 29. "10  Adj. for Changes in Inventories/Other adj.
          IF auto_cal = 'X'.
            wa_final_qi_o-ch_invt = wa_final_qi_o-ch_invt - wa_final_qi_o_1-ch_invt.
            wa_final_qi_g-ch_invt = wa_final_qi_g-ch_invt - wa_final_qi_g_1-ch_invt.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-ch_invt.
          wa_quant-mmscm = wa_final_qi_g-ch_invt.

        WHEN 33. "12  Overlift/(underlift) quantity
          IF auto_cal = 'X'.
            wa_final_qi_o-ovr_und = wa_final_qi_o-ovr_und - wa_final_qi_o_1-ovr_und.
            wa_final_qi_g-ovr_und = wa_final_qi_g-ovr_und - wa_final_qi_g_1-ovr_und.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-ovr_und.
          wa_quant-mmscm = wa_final_qi_g-ovr_und.

        WHEN 35. "13  Total Sales quantity
          IF auto_cal = 'X'.
            wa_final_qi_o-tot_sal = wa_final_qi_o-tot_sal - wa_final_qi_o_1-tot_sal.
            wa_final_qi_g-tot_sal = wa_final_qi_g-tot_sal - wa_final_qi_g_1-tot_sal.
          ENDIF.
          wa_quant-bbl   = wa_final_qi_o-tot_sal.
          wa_quant-mmscm = wa_final_qi_g-tot_sal.

      ENDCASE.

      MODIFY it_quant FROM wa_quant TRANSPORTING bbl mmscm.
      CLEAR wa_quant.
    ENDLOOP.

*        Move conversion factors from table to its corresponding variables
    IF auto_cal = ' '.
      bbl_mmbbl    = '0.000001'."WA_FINAL_CONV-BBL_MMBBL   .
      bbl_mmt      = '0.000001'."WA_FINAL_CONV-BBL_MMT .
      ton_bbl      = wa_final_conv-ton_bbl .
      mmscm_mmbtu  = wa_final_conv-mmscm_mmbtu .
      mmscm_mmboe  = '0.00629'.
      mmscm_bcm    = '0.001'."WA_FINAL_CONV-MMSCM_BCM   .

    ELSEIF auto_cal = 'X'.
      bbl_mmbbl    = wa_final_conv-bbl_mmbbl.    "if auto cal.then input convo will the values of period with is bigger
      bbl_mmt      = wa_final_conv-bbl_mmt  .
      ton_bbl      = wa_final_conv-ton_bbl  .
      mmscm_mmbtu  = wa_final_conv-mmscm_mmbtu .
      mmscm_mmboe  = wa_final_conv-mmscm_mmboe .
      mmscm_bcm    = wa_final_conv-mmscm_bcm   .

    ENDIF.

  ENDIF.

ENDFORM."FETCH_QUANT

FORM download_xl. "Download Quantitative Information Excel.
  DATA : BEGIN OF excel_heading ,
           head1 TYPE char30,
           head2 TYPE char30,
         END OF excel_heading .

  DATA : it_heading LIKE STANDARD TABLE OF excel_heading INITIAL SIZE 0.

  CONSTANTS g_c_ftype TYPE char10 VALUE 'ASC'.
  DATA : i_file_table TYPE  TABLE OF file_table,
         l_filetable  TYPE  file_table,
         l_rc         TYPE  i,
         l_p_def_file TYPE  string,
         l_p_file     TYPE  string,
         def_name     TYPE  string,
         l_path       TYPE string,
         l_fullpath   TYPE string,
         l_usr_act    TYPE  i.

  DATA : it_quant_xl TYPE STANDARD TABLE OF ty_quant,
         wa_quant_xl TYPE ty_quant.

  CONCATENATE p_comp'-'p_proj'-'p_year'-'s_period_low'.XLS' INTO def_name . "Default file name

  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      window_title         = 'Download Qunatitative Information Excel'
      default_file_name    = def_name
    CHANGING
      filename             = l_p_file
      path                 = l_path
      fullpath             = l_fullpath
      user_action          = l_usr_act
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.

  IF sy-subrc = 0 AND l_usr_act <> cl_gui_frontend_services=>action_cancel.

    LOOP AT i_file_table  INTO l_filetable.
      l_p_file = l_filetable.
      EXIT.
    ENDLOOP.

    CLEAR:it_quant_xl,wa_quant_xl-data.
    REFRESH it_quant_xl[].

    "Create header
    CONCATENATE 'Input Parameters:- ' wa_quant_xl-data INTO wa_quant_xl-data.
    CONCATENATE 'Conversion Factor:- ' wa_quant_xl-bbl INTO wa_quant_xl-bbl .
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    CONCATENATE 'Company:- ' p_company INTO wa_quant_xl-data .
    wa_quant_xl-bbl   = 'Crude Oil'.
    wa_quant_xl-mmscm = 'BBL To MMBBL'.
    wa_quant_xl-mmbbl = bbl_mmbbl.
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    CONCATENATE 'Company Code:- ' p_comp INTO wa_quant_xl-data .
    wa_quant_xl-bbl   = 'Crude Oil'.
    wa_quant_xl-mmscm = 'BBL To MMT'.
    wa_quant_xl-mmbbl = bbl_mmt.
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    CONCATENATE 'Project:- ' p_proj INTO wa_quant_xl-data .
    wa_quant_xl-bbl   = 'Crude Oil'.
    wa_quant_xl-mmscm = 'TON To BBL'.
    wa_quant_xl-mmbbl = ton_bbl.
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    CONCATENATE 'Fiscal Year:- ' p_year INTO wa_quant_xl-data .
    wa_quant_xl-bbl   = 'Natural Gas'.
    wa_quant_xl-mmscm = 'MMSCM To MMBTU'.
    wa_quant_xl-mmbbl = mmscm_mmbtu.
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    CONCATENATE 'Period:- ' s_period_low INTO wa_quant_xl-data .
    wa_quant_xl-bbl   = 'Natural Gas'.
    wa_quant_xl-mmscm = 'MMSCM To MMBOE'.
    wa_quant_xl-mmbbl = mmscm_mmboe.
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    wa_quant_xl-bbl   = 'Natural Gas'.
    wa_quant_xl-mmscm = 'MMSCM To BCM'.
    wa_quant_xl-mmbbl = mmscm_bcm.
    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    "Create Cloumns
    wa_quant_xl-sr_no = 'No.'.
    wa_quant_xl-data  = 'Quantitative Information'.
    wa_quant_xl-bbl   = 'CRUDE OIL(BBL)'.
    wa_quant_xl-mmscm = 'GAS(MMSCM)'.
    wa_quant_xl-mmbbl = 'CRUDE OIL(MMBBL)'.
    wa_quant_xl-mmt   = 'CRUDE OIL(MMT)'.
    wa_quant_xl-ton   = 'CRUDE OIL(TON)'.
    wa_quant_xl-mmbtu = 'GAS(MMBTU)'.
    wa_quant_xl-mmboe = 'GAS(MMBOE)'.
    wa_quant_xl-bcm   = 'GAS(BCM)'.

    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    "Create data and insert
    LOOP AT it_quant INTO DATA(wa_quant).
      MOVE-CORRESPONDING wa_quant TO wa_quant_xl.
      wa_quant_xl-io_flag = ''.
      APPEND wa_quant_xl TO it_quant_xl.
      CLEAR wa_quant_xl.
    ENDLOOP.

    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    APPEND wa_quant_xl TO it_quant_xl.
    CLEAR wa_quant_xl.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = def_name
        filetype                = 'DAT'
        header                  = '00'
      TABLES
        data_tab                = it_quant_xl[]
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.

ENDFORM."DOWNLOAD_XL

FORM create_prof_prd.      "Create screen layout for producing Projects input

  CLEAR wa_prof_prd.
  REFRESH : it_prof_prd[],lt_fcat[].

  wa_prof_prd-per = 'GROSS PRODUCTION'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'LESS: PROFIT OIL'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'OVLs ENTITLEMENT (AFTER PROFIT OIL))'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'ADD/(LESS):OVERLIFT QTY/(UNDER LIFT)'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'ADD/(LESS): CHANGES IN INVENTORIES'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'LESS: INTERNAL CONSUMPTION/RE-INJECTION IN RESERVOIR'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  READ TABLE it_prod_f4 INTO DATA(wa_prod_f4) WITH KEY text_no = '103'.   "fetching texts from texts table
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '115'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '104'.
  CONCATENATE 'LESS:' wa_prod_f4-prod_proj '(APPLICABLE FOR SAKHALIN)' INTO  wa_prof_prd-per.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4.

  wa_prof_prd-per = 'SALE OF VAP'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '117'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4.

  wa_prof_prd-per = 'SALES REALISATION(I)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = '  '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'OPERATING EXPENSES:'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '102'.
  CONCATENATE wa_prod_f4-prod_proj '/MET' INTO  wa_prof_prd-per.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4.

  wa_prof_prd-per = 'OTHER TAXES(AS APPLICABLE)'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '101'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '119'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '107'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  wa_prof_prd-per = 'INTERNAL CONSUMPTION OF GAS'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'TOTAL OPERATING EXPENSES(II)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'DDA & EXPLORATIONS:'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '113'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '114'.
  wa_prof_prd-per = wa_prod_f4-prod_proj.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.


  " Splited 'Exploration Costs (Survey & Dry well)' to EC Survey and Dry well.
  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '106'.
  wa_prof_prd-per = wa_prod_f4-prod_proj. "'Exploration Costs Survey'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4 .

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '124'.
  wa_prof_prd-per = wa_prod_f4-prod_proj. "'Exploration Costs Dry well'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4 .

  wa_prof_prd-per = 'TOTAL DDA & EXPLORATION(III)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'TOTAL EXPENSES IV(II+III)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'OPERATING COST V'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'ADJUSTMENT FOR COST OF SALES:'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '120'.
  CONCATENATE wa_prod_f4-prod_proj '(VI)' INTO  wa_prof_prd-per.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4 .

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '112'.
  CONCATENATE wa_prod_f4-prod_proj '(VII)' INTO  wa_prof_prd-per.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd ,wa_prod_f4 .

  wa_prof_prd-per = 'COST OF GOODS SOLD VIII (V+VI+VII)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.


  wa_prof_prd-per = 'NET OPERATING MARGIN IX(I-VIII)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'OTHER INCOME/ EXPENSE:'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '116'.
  wa_prof_prd-per = wa_prod_f4-prod_proj. "'Other Income'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '108'.
  wa_prof_prd-per = wa_prod_f4-prod_proj. "'Finance Cost'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '109'.
  CONCATENATE wa_prod_f4-prod_proj+0(22) '(INCL. IMPARIMENT)' INTO wa_prof_prd-per.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '111'.
  wa_prof_prd-per = wa_prod_f4-prod_proj. "'Other Expenses (incl. exchange fluctuation)'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  wa_prof_prd-per = 'TOTAL OTHER INCOME/ EXPENSE (X)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'NET PROFIT BEFORE TAX XI (IX-X)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'INCOME TAX (XII)'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'NET PROFIT/(LOSS) AFTER TAX XIV(XI-XII)'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '110'.
  wa_prof_prd-per = wa_prod_f4-prod_proj. "'Impairment loss/(reversal)'.
  wa_prof_prd-io_flag = '23'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR : wa_prof_prd,wa_prod_f4.

  wa_prof_prd-per = ' '.
  wa_prof_prd-io_flag = ' '.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.

  wa_prof_prd-per = 'NET PROFIT/(LOSS) AFTER TAX-BEFORE IMPAIRMENT'.
  wa_prof_prd-io_flag = '0'.
  APPEND wa_prof_prd TO it_prof_prd.
  CLEAR wa_prof_prd.


  IF mode NE 'DIS'.
    CLEAR l_index.
    LOOP AT it_prof_prd.
      l_index = sy-tabix.
      REFRESH lt_celltab.

      IF it_prof_prd-io_flag = '23'.
        PERFORM fill_celltab_prof_prd USING 'RW' '23'       "make field as Read and Write field/available for input
                             CHANGING lt_celltab.

      ELSE.
        IF it_prof_prd-io_flag = '0'.
          PERFORM fill_celltab_prof_prd USING 'RO' '0'       "make field as read only/available as output field
                               CHANGING lt_celltab.
        ELSE.
          PERFORM fill_celltab_prof_prd USING 'RO' ' '       "make field as read only/available as output field
                               CHANGING lt_celltab.
        ENDIF.
      ENDIF.

      INSERT LINES OF lt_celltab INTO TABLE it_prof_prd-celltab.
      MODIFY it_prof_prd INDEX l_index.

    ENDLOOP.

  ENDIF.

ENDFORM."CREATE_PROF_PRD.

FORM fill_celltab_prof_prd USING VALUE(p_mode) VALUE(io_flag2)
                  CHANGING pt_celltab TYPE lvc_t_styl.

  DATA : ls_celltab TYPE lvc_t_styl WITH HEADER LINE.

  CLEAR l_mode.
  CLEAR l_mode2.

  IF p_mode EQ 'RW'.
    l_mode = cl_gui_alv_grid=>mc_style_enabled.
  ELSE.
    l_mode = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.

  ls_celltab-fieldname = 'PER'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.   "first column as read only

  IF io_flag2 CA '0'.
  ENDIF.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'OILNG'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.   "second column as read only
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'OIL'.                            "third column as read only/read and write field
  IF io_flag2 CA '2'.
    ls_celltab-style = l_mode.
  ELSE.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'GAS'.                           "fourth column as read only/read and write field
  IF io_flag2 CA '3'.
    ls_celltab-style = l_mode.
  ELSE.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.
  INSERT ls_celltab INTO TABLE pt_celltab.

ENDFORM."fill_celltab_prof_prd

FORM fcat_fill_prof_prd .  "fill field catalog for producing projects input

  REFRESH lt_fcat[].

  PERFORM alv_fcat USING : 'PER'     'Particulars'         '50'  ,    "Column1:- Row name/heading
                           'OILNG'   'CRUDE OIL and GAS'   '18'  ,    "Column2:- Oil + Gas values
                           'OIL'     'CRUDE OIL  '         '18'  ,    "Column3:- Oil values
                           'GAS'     'GAS  '               '18'  .    "Column4:- Gas values

ENDFORM."fcat_fill_PROF_PRD

FORM alv_fcat  USING  VALUE(p_011)
                      VALUE(p_012)
                      VALUE(p_013).

  ls_fcat-fieldname  = p_011.
  ls_fcat-scrtext_l  = p_012.
  ls_fcat-outputlen  = p_013.
  ls_fcat-no_zero    = abap_true.

  IF ls_fcat-fieldname NE 'PER'.
    ls_fcat-decimals   = 2.
    ls_fcat-decimals_o = 2.
    ls_fcat-round      = 2.
    ls_fcat-inttype   = 'P'.
    ls_fcat-decimals  = '3'.
  ENDIF.
  IF ls_fcat-fieldname EQ 'VALS'.
    ls_fcat-datatype   = 'DEC'.
    ls_fcat-decimals   = 2.
    ls_fcat-decimals_o = 2.
    ls_fcat-round      = 2.
    ls_fcat-inttype   = 'P'.
    ls_fcat-decimals  = '3'.
  ENDIF.


  APPEND ls_fcat TO lt_fcat.
  CLEAR ls_fcat.

ENDFORM." alv_fcat

FORM calc_0211.     "calc. values for producing project input

  DATA : roylty_ong(10)   TYPE c,     "Royalty/MET
         roylty_oil(10)   TYPE c,
         roylty_gas(10)   TYPE c,

         oth_tax_ong(10)  TYPE c,    "Other taxes(as applicable)
         oth_tax_oil(10)  TYPE c,
         oth_tax_gas(10)  TYPE c,

         net_slrl_ong(10) TYPE c,   "Net Sales Realisation(I)
         net_slrl_oil(10) TYPE c,
         net_slrl_gas(10) TYPE c,

         tot_oprx_ong(10) TYPE c,   "Total Operating Expenses(II)
         tot_oprx_oil(10) TYPE c,
         tot_oprx_gas(10) TYPE c,

         tot_dda_ong(10)  TYPE c,    "Total DDA & Exploration(III)
         tot_dda_oil(10)  TYPE c,
         tot_dda_gas(10)  TYPE c,

         tot_exp_ong(10)  TYPE c,    "Total expenses IV(II+III)
         tot_exp_oil(10)  TYPE c,
         tot_exp_gas(10)  TYPE c,

         orp_cst_ong(10)  TYPE c,   "Operating Cost V
         orp_cst_oil(10)  TYPE c,
         orp_cst_gas(10)  TYPE c,

         sld_god_ong(10)  TYPE c,   "Cost of Goods Sold VIII (V+VI+VII)
         sld_god_oil(10)  TYPE c,
         sld_god_gas(10)  TYPE c,

         net_rev_ong(10)  TYPE c,    "Net Operating Revenue V(I-IV)
         net_rev_oil(10)  TYPE c,
         net_rev_gas(10)  TYPE c,

         tot_otin_ong(10) TYPE c,   "Total Other Income/ Expense (VI)
         tot_otin_oil(10) TYPE c,
         tot_otin_gas(10) TYPE c,

         net_btax_ong(10) TYPE c,   "Net Profit Before Tax VII (V-VI)
         net_btax_oil(10) TYPE c,
         net_btax_gas(10) TYPE c,

         in_tax_ong(10)   TYPE c,     "Income Tax (VIII) (20%)
         in_tax_oil(10)   TYPE c,
         in_tax_gas(10)   TYPE c,

         net_atax_ong(10) TYPE c,   "Net Profit/(Loss) after tax IX (VII-VIII)
         net_atax_oil(10) TYPE c,
         net_atax_gas(10) TYPE c.


  IF NOT grid1 IS INITIAL.
    CALL METHOD grid1->check_changed_data.
  ENDIF.

  wa_prd_oil-company = p_company.
  wa_prd_gas-company = p_company.

  wa_prd_oil-bukrs = p_comp.
  wa_prd_gas-bukrs = p_comp.

  wa_prd_oil-pro_nam = p_proj.
  wa_prd_gas-pro_nam = p_proj.

  wa_prd_oil-fisyear = p_year.
  wa_prd_gas-fisyear = p_year.

  wa_prd_oil-zperiod = s_period_low.
  wa_prd_gas-zperiod = s_period_low.


  IF it_prof_prd2[] IS NOT INITIAL.
    REFRESH it_prof_prd[].
    CLEAR : it_prof_prd, wa_prof_prd.

    DO 6 TIMES.
      APPEND wa_prof_prd TO it_prof_prd.
    ENDDO.

    LOOP AT it_prof_prd2 INTO DATA(wa_prof_prd2).
      MOVE-CORRESPONDING wa_prof_prd2 TO wa_prof_prd.
      APPEND wa_prof_prd TO it_prof_prd.
      CLEAR : wa_prof_prd2,wa_prof_prd.
    ENDLOOP.
  ENDIF.

  LOOP AT it_prof_prd INTO wa_prof_prd.

    IF wa_prof_prd-oil CA lv_spl.
      CLEAR sy-ucomm.
      MESSAGE 'Special character in amount field is not allowed' TYPE 'W' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    IF wa_prof_prd-gas CA lv_spl.
      CLEAR sy-ucomm.
      MESSAGE 'Special character in amount field is not allowed' TYPE 'W' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    CASE sy-tabix.
      WHEN 1 ."GROSS PRODUCTION
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-sh_prod = wa_prof_prd-oil.
        wa_prd_gas-sh_prod = wa_prof_prd-gas.

      WHEN 2 ."LESS: PROFIT OIL
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-prf_oil = wa_prof_prd-oil.
        wa_prd_gas-prf_oil = wa_prof_prd-gas.

      WHEN 3 ."OVLs ENTITLEMENT (AFTER PROFIT OIL))
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-sh_entl = wa_prof_prd-oil.
        wa_prd_gas-sh_entl = wa_prof_prd-gas.

      WHEN 4 ."ADD/(LESS):OVERLIFT QTY/(UNDER LIFT)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-ovr_und = wa_prof_prd-oil.
        wa_prd_gas-ovr_und = wa_prof_prd-gas.

      WHEN 5 ."ADD/(LESS): CHANGES IN INVENTORIES
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-chg_inv = wa_prof_prd-oil.
        wa_prd_gas-chg_inv = wa_prof_prd-gas.

      WHEN 6 ."LESS: INTERNAL CONSUMPTION/RE-INJECTION IN RESERVOIR
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-int_con = wa_prof_prd-oil.
        wa_prd_gas-int_con = wa_prof_prd-gas.

      WHEN 7 ."REVENUE FROM CRUDE OIL
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-rev_oil = wa_prof_prd-oil.
        wa_prd_gas-rev_oil = wa_prof_prd-gas.

      WHEN 8 ."REVENUE FROM NATURAL GAS
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-rev_gas = wa_prof_prd-oil.
        wa_prd_gas-rev_gas = wa_prof_prd-gas.

      WHEN 9 ."Less: Profit Oil paid in cash (applicable for Sakhalin)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-prfoilc = wa_prof_prd-oil.
        wa_prd_gas-prfoilc = wa_prof_prd-gas.

      WHEN 10."SALE OF VAP
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-sal_vap = wa_prof_prd-oil.
        wa_prd_gas-sal_vap = wa_prof_prd-gas.

      WHEN 11."OTHER OPERATING REVENUE
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oth_rev = wa_prof_prd-oil.
        wa_prd_gas-oth_rev = wa_prof_prd-gas.

      WHEN 12."SALES REALISATION(I)
        net_slrl_oil = wa_prof_prd-oil   = ( wa_prd_oil-rev_oil + wa_prd_oil-rev_gas + wa_prd_oil-sal_vap + wa_prd_oil-oth_rev )
                                            - ( wa_prd_oil-prfoilc ).

        net_slrl_gas = wa_prof_prd-gas   = ( wa_prd_gas-rev_oil + wa_prd_gas-rev_gas + wa_prd_gas-sal_vap + wa_prd_gas-oth_rev )
                                           - ( wa_prd_gas-prfoilc ).

        net_slrl_ong = wa_prof_prd-oilng = net_slrl_oil + net_slrl_gas .

      WHEN 13.

      WHEN 14."OPERATING EXPENSES:

      WHEN 15."ROYALTY/MET
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-ls_met = wa_prof_prd-oil.
        wa_prd_gas-ls_met = wa_prof_prd-gas.

      WHEN 16."OTHER TAXES(AS APPLICABLE)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-ls_ottx = wa_prof_prd-oil.
        wa_prd_gas-ls_ottx = wa_prof_prd-gas.

      WHEN 17."PRODUCTION EXPENSES
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oe_prdx = wa_prof_prd-oil.
        wa_prd_gas-oe_prdx = wa_prof_prd-gas.

      WHEN 18."OTHER OPERATING EXPENSE
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oe_oexp = wa_prof_prd-oil.
        wa_prd_gas-oe_oexp = wa_prof_prd-gas.

      WHEN 19."TRANSPORTATION EXPENSES
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oechin2 = wa_prof_prd-oil.
        wa_prd_gas-oechin2 = wa_prof_prd-gas.

      WHEN 20."INTERNAL CONSUMPTION OF GAS
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oe_cgas = wa_prof_prd-oil.
        wa_prd_gas-oe_cgas = wa_prof_prd-gas.

      WHEN 21."TOTAL OPERATING EXPENSES(II)
        tot_oprx_oil = wa_prof_prd-oil   =  wa_prd_oil-ls_met +  wa_prd_oil-ls_ottx + wa_prd_oil-oe_oexp
                                            + wa_prd_oil-oe_prdx + wa_prd_oil-oechin2 + wa_prd_oil-oe_cgas.

        tot_oprx_gas = wa_prof_prd-gas   =  wa_prd_gas-ls_met +  wa_prd_gas-ls_ottx + wa_prd_gas-oe_oexp +
                                          + wa_prd_gas-oe_prdx + wa_prd_gas-oechin2 + wa_prd_gas-oe_cgas.

        tot_oprx_ong = wa_prof_prd-oilng = tot_oprx_oil + tot_oprx_gas.

      WHEN 22.

      WHEN 23."DDA & EXPLORATIONS:

      WHEN 24."DEPLETION
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-da_depl = wa_prof_prd-oil.
        wa_prd_gas-da_depl = wa_prof_prd-gas.

      WHEN 25."DEPRECIATION AND AMORTISATION
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-da_dpam = wa_prof_prd-oil.
        wa_prd_gas-da_dpam = wa_prof_prd-gas.

      WHEN 26."EXPLORATION COSTS (SURVEY)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-da_exps = wa_prof_prd-oil.
        wa_prd_gas-da_exps = wa_prof_prd-gas.

      WHEN 27."EXPLORATION COSTS (DRY WELL)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-da_expd = wa_prof_prd-oil.
        wa_prd_gas-da_expd = wa_prof_prd-gas.

      WHEN 28."TOTAL DDA & EXPLORATION(III)
        tot_dda_oil = wa_prof_prd-oil   = wa_prd_oil-da_depl + wa_prd_oil-da_dpam + wa_prd_oil-da_exps + wa_prd_oil-da_expd.

        tot_dda_gas = wa_prof_prd-gas   = wa_prd_gas-da_depl + wa_prd_gas-da_dpam + wa_prd_gas-da_exps + wa_prd_gas-da_expd.

        tot_dda_ong = wa_prof_prd-oilng = tot_dda_oil + tot_dda_gas.

      WHEN 29.

      WHEN 30."TOTAL EXPENSES IV(II+III)
        tot_exp_oil = wa_prof_prd-oil   = tot_oprx_oil + tot_dda_oil.

        tot_exp_gas = wa_prof_prd-gas   = tot_oprx_gas + tot_dda_gas.

        tot_exp_ong = wa_prof_prd-oilng = tot_exp_oil + tot_exp_gas.

      WHEN 31.

      WHEN 32."OPERATING COST V
        orp_cst_oil = wa_prof_prd-oil    = tot_exp_oil .

        orp_cst_gas = wa_prof_prd-gas    = tot_exp_gas .

        orp_cst_ong = wa_prof_prd-oilng  = orp_cst_oil +  orp_cst_gas.

      WHEN 33."ADJUSTMENT FOR COST OF SALES:

      WHEN 34."CHANGE IN INVENTORIES(VI)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oechin1 = wa_prof_prd-oil.
        wa_prd_gas-oechin1 = wa_prof_prd-gas.

      WHEN 35."OVERLIFT/(UNDERLIFT)(VII)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oe_ovun = wa_prof_prd-oil.
        wa_prd_gas-oe_ovun = wa_prof_prd-gas.

      WHEN 36."COST OF GOODS SOLD VIII (V+VI+VII)
        sld_god_oil = wa_prof_prd-oil   = orp_cst_oil + wa_prd_oil-oechin1 + wa_prd_oil-oe_ovun.

        sld_god_gas = wa_prof_prd-gas   = orp_cst_gas + wa_prd_gas-oechin1 + wa_prd_gas-oe_ovun.

        sld_god_ong = wa_prof_prd-oilng = sld_god_oil + sld_god_gas.

      WHEN 37.

      WHEN 38."NET OPERATING MARGIN IX(I-VIII)
        net_rev_oil = wa_prof_prd-oil   = net_slrl_oil - sld_god_oil .

        net_rev_gas = wa_prof_prd-gas   = net_slrl_gas - sld_god_gas .

        net_rev_ong = wa_prof_prd-oilng =  net_rev_oil +  net_rev_gas.

      WHEN 39.

      WHEN 40."OTHER INCOME/ EXPENSE:

      WHEN 41."OTHER INCOME
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oth_oth = wa_prof_prd-oil.
        wa_prd_gas-oth_oth = wa_prof_prd-gas.

      WHEN 42."FINANCE COST
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oth_fin = wa_prof_prd-oil.
        wa_prd_gas-oth_fin = wa_prof_prd-gas.

      WHEN 43."PROVISIONS, WRITE OFF(INCL. IMPARIMENT)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oth_prv = wa_prof_prd-oil.
        wa_prd_gas-oth_prv = wa_prof_prd-gas.

      WHEN 44."OTHER EXPENSES (INCL. EXCHANGE FLUCTUATION)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-oth_exp = wa_prof_prd-oil.
        wa_prd_gas-oth_exp = wa_prof_prd-gas.

      WHEN 45."TOTAL OTHER INCOME/ EXPENSE (X)
        tot_otin_oil = wa_prof_prd-oil   = wa_prd_oil-oth_oth + wa_prd_oil-oth_fin + wa_prd_oil-oth_prv + wa_prd_oil-oth_exp.
        tot_otin_gas = wa_prof_prd-gas   = wa_prd_gas-oth_oth + wa_prd_gas-oth_fin + wa_prd_gas-oth_prv + wa_prd_gas-oth_exp.
        tot_otin_ong = wa_prof_prd-oilng = tot_otin_oil + tot_otin_gas.

      WHEN 46.

      WHEN 47."NET PROFIT BEFORE TAX XI (IX-X)
        net_btax_oil = wa_prof_prd-oil   = net_rev_oil - tot_otin_oil.
        net_btax_gas = wa_prof_prd-gas   = net_rev_gas - tot_otin_gas.
        net_btax_ong = wa_prof_prd-oilng = net_btax_oil + net_btax_gas.

      WHEN 48.

      WHEN 49."INCOME TAX (XII)
        in_tax_oil = wa_prd_oil-inc_tax = wa_prof_prd-oil  .
        in_tax_gas = wa_prd_gas-inc_tax = wa_prof_prd-gas  .
        in_tax_ong = wa_prof_prd-oilng  = wa_prd_oil-inc_tax + wa_prd_gas-inc_tax.

      WHEN 50.

      WHEN 51."NET PROFIT/(LOSS) AFTER TAX XIV(XI-XII)
        net_atax_oil = wa_prof_prd-oil   = net_btax_oil - in_tax_oil .
        net_atax_gas = wa_prof_prd-gas   = net_btax_gas - in_tax_gas .
        net_atax_ong = wa_prof_prd-oilng = net_atax_oil + net_atax_gas.

      WHEN 52.

      WHEN 53."IMPAIRMENT LOSS/(REVERSAL)
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.
        wa_prd_oil-imploss = wa_prof_prd-oil.
        wa_prd_gas-imploss = wa_prof_prd-gas.

      WHEN 54.

      WHEN 55."NET PROFIT/(LOSS) AFTER TAX-BEFORE IMPAIRMENT
        wa_prof_prd-oil   = net_atax_oil + wa_prd_oil-imploss .
        wa_prof_prd-gas   = net_atax_gas + wa_prd_gas-imploss .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas .

    ENDCASE.

    MODIFY it_prof_prd FROM wa_prof_prd TRANSPORTING oilng oil gas.

  ENDLOOP.

  PERFORM set_for_disp.

ENDFORM."CALC_0211

FORM change_prof_prd.     "to update the changes in the existing data

  DATA : roylty_ong(10)   TYPE c,     "Royalty/MET
         roylty_oil(10)   TYPE c,
         roylty_gas(10)   TYPE c,

         oth_tax_ong(10)  TYPE c,    "Other taxes(as applicable)
         oth_tax_oil(10)  TYPE c,
         oth_tax_gas(10)  TYPE c,

         net_slrl_ong(10) TYPE c,   "Net Sales Realisation(I)
         net_slrl_oil(10) TYPE c,
         net_slrl_gas(10) TYPE c,

         tot_oprx_ong(10) TYPE c,   "Total Operating Expenses(II)
         tot_oprx_oil(10) TYPE c,
         tot_oprx_gas(10) TYPE c,

         tot_dda_ong(10)  TYPE c,    "Total DDA & Exploration(III)
         tot_dda_oil(10)  TYPE c,
         tot_dda_gas(10)  TYPE c,

         tot_exp_ong(10)  TYPE c,    "Total expenses IV(II+III)
         tot_exp_oil(10)  TYPE c,
         tot_exp_gas(10)  TYPE c,

         orp_cst_ong(10)  TYPE c,   "Operating Cost V
         orp_cst_oil(10)  TYPE c,
         orp_cst_gas(10)  TYPE c,

         sld_god_ong(10)  TYPE c,   "Cost of Goods Sold VIII (V+VI+VII)
         sld_god_oil(10)  TYPE c,
         sld_god_gas(10)  TYPE c,

         net_rev_ong(10)  TYPE c,    "Net Operating Revenue V(I-IV)
         net_rev_oil(10)  TYPE c,
         net_rev_gas(10)  TYPE c,

         tot_otin_ong(10) TYPE c,   "Total Other Income/ Expense (VI)
         tot_otin_oil(10) TYPE c,
         tot_otin_gas(10) TYPE c,

         net_btax_ong(10) TYPE c,   "Net Profit Before Tax VII (V-VI)
         net_btax_oil(10) TYPE c,
         net_btax_gas(10) TYPE c,

         in_tax_ong(10)   TYPE c,     "Income Tax (VIII) (20%)
         in_tax_oil(10)   TYPE c,
         in_tax_gas(10)   TYPE c,

         net_atax_ong(10) TYPE c,   "Net Profit/(Loss) after tax IX (VII-VIII)
         net_atax_oil(10) TYPE c,
         net_atax_gas(10) TYPE c.


  IF NOT grid1 IS INITIAL.
    CALL METHOD grid1->check_changed_data.
  ENDIF.

  IF p_company IS NOT INITIAL
  AND p_comp IS NOT INITIAL
  AND p_proj IS NOT INITIAL
  AND p_year IS NOT INITIAL
  AND s_period_low IS NOT INITIAL.

    SELECT SINGLE * FROM zpnl_prd_oil    "fetch the existing oil values
      INTO @DATA(chk_cre_oil)
      WHERE company = @p_company
        AND bukrs   = @p_comp
        AND pro_nam = @p_proj
        AND fisyear = @p_year
        AND zperiod = @s_period_low.

    SELECT SINGLE * FROM zpnl_prd_gas   "fetch the existing gas values
      INTO @DATA(chk_cre_gas)
      WHERE company = @p_company
        AND bukrs   = @p_comp
        AND pro_nam = @p_proj
        AND fisyear = @p_year
        AND zperiod = @s_period_low.

    IF chk_cre_gas IS NOT INITIAL AND chk_cre_oil IS NOT INITIAL.
      MOVE-CORRESPONDING chk_cre_oil TO wa_prd_oil.
      MOVE-CORRESPONDING chk_cre_gas TO wa_prd_gas.
    ENDIF.

  ENDIF.


  LOOP AT it_prof_prd INTO wa_prof_prd.   "Calculate the calculation field according to the changes

    CASE sy-tabix.
      WHEN 1 ."GROSS PRODUCTION

        wa_prof_prd-oil   = wa_prd_oil-sh_prod .
        wa_prof_prd-gas   = wa_prd_gas-sh_prod .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 2 ."LESS: PROFIT OIL

        wa_prof_prd-oil = wa_prd_oil-prf_oil .
        wa_prof_prd-gas = wa_prd_gas-prf_oil .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 3 ."OVLs ENTITLEMENT (AFTER PROFIT OIL))

        wa_prof_prd-oil = wa_prd_oil-sh_entl .
        wa_prof_prd-gas = wa_prd_gas-sh_entl .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 4 ."ADD/(LESS):OVERLIFT QTY/(UNDER LIFT)

        wa_prof_prd-oil = wa_prd_oil-ovr_und .
        wa_prof_prd-gas = wa_prd_gas-ovr_und .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 5 ."ADD/(LESS): CHANGES IN INVENTORIES

        wa_prof_prd-oil = wa_prd_oil-chg_inv .
        wa_prof_prd-gas = wa_prd_gas-chg_inv .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 6 ."LESS: INTERNAL CONSUMPTION/RE-INJECTION IN RESERVOIR

        wa_prof_prd-oil = wa_prd_oil-int_con .
        wa_prof_prd-gas = wa_prd_gas-int_con .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 7 ."REVENUE FROM CRUDE OIL

        wa_prof_prd-oil = wa_prd_oil-rev_oil .
        wa_prof_prd-gas = wa_prd_gas-rev_oil .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 8 ."REVENUE FROM NATURAL GAS

        wa_prof_prd-oil = wa_prd_oil-rev_gas .
        wa_prof_prd-gas = wa_prd_gas-rev_gas .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 9 ."LESS:PROFIT OIL PAID IN CASH(APPLICABLE FOR SAKHALIN)

        wa_prof_prd-oil = wa_prd_oil-prfoilc .
        wa_prof_prd-gas = wa_prd_gas-prfoilc .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 10."SALE OF VAP

        wa_prof_prd-oil = wa_prd_oil-sal_vap.
        wa_prof_prd-gas = wa_prd_gas-sal_vap.
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 11."OTHER OPERATING REVENUE

        wa_prof_prd-oil = wa_prd_oil-oth_rev .
        wa_prof_prd-gas = wa_prd_gas-oth_rev .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.


      WHEN 15."ROYALTY/MET

        wa_prof_prd-oil = wa_prd_oil-ls_met .
        wa_prof_prd-gas = wa_prd_gas-ls_met .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 16."OTHER TAXES(AS APPLICABLE)

        wa_prof_prd-oil = wa_prd_oil-ls_ottx.
        wa_prof_prd-gas = wa_prd_gas-ls_ottx.
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 17."PRODUCTION EXPENSES

        wa_prof_prd-oil = wa_prd_oil-oe_prdx.
        wa_prof_prd-gas = wa_prd_gas-oe_prdx.
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 18."OTHER OPERATING EXPENSE

        wa_prof_prd-oil = wa_prd_oil-oe_oexp.
        wa_prof_prd-gas = wa_prd_gas-oe_oexp.
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 19."TRANSPORTATION EXPENSES

        wa_prof_prd-oil = wa_prd_oil-oechin2 .
        wa_prof_prd-gas = wa_prd_gas-oechin2 .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 20."INTERNAL CONSUMPTION OF GAS

        wa_prof_prd-oil = wa_prd_oil-oe_cgas .
        wa_prof_prd-gas = wa_prd_gas-oe_cgas .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 24."DEPLETION

        wa_prof_prd-oil = wa_prd_oil-da_depl.
        wa_prof_prd-gas = wa_prd_gas-da_depl.
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 25."DEPRECIATION AND AMORTISATION

        wa_prof_prd-oil = wa_prd_oil-da_dpam .
        wa_prof_prd-gas = wa_prd_gas-da_dpam .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 26."EXPLORATION COSTS (SURVEY)

        wa_prof_prd-oil = wa_prd_oil-da_exps .
        wa_prof_prd-gas = wa_prd_gas-da_exps .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 27."EXPLORATION COSTS (SURVEY)

        wa_prof_prd-oil = wa_prd_oil-da_expd .
        wa_prof_prd-gas = wa_prd_gas-da_expd .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 34."CHANGE IN INVENTORIES(VI)

        wa_prof_prd-oil = wa_prd_oil-oechin1 .
        wa_prof_prd-gas = wa_prd_gas-oechin1 .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 35."OVERLIFT/(UNDERLIFT)(VII)

        wa_prof_prd-oil = wa_prd_oil-oe_ovun .
        wa_prof_prd-gas = wa_prd_gas-oe_ovun .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 41."OTHER INCOME

        wa_prof_prd-oil = wa_prd_oil-oth_oth .
        wa_prof_prd-gas = wa_prd_gas-oth_oth .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 42."FINANCE COST

        wa_prof_prd-oil = wa_prd_oil-oth_fin .
        wa_prof_prd-gas = wa_prd_gas-oth_fin .
        wa_prof_prd-oilng  = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 43."PROVISIONS, WRITE OFF(INCL. IMPARIMENT)

        wa_prof_prd-oil = wa_prd_oil-oth_prv.
        wa_prof_prd-gas = wa_prd_gas-oth_prv.
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 44."OTHER EXPENSES (INCL. EXCHANGE FLUCTUATION)

        wa_prof_prd-oil = wa_prd_oil-oth_exp .
        wa_prof_prd-gas = wa_prd_gas-oth_exp .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

      WHEN 49."INCOME TAX (XII)

        in_tax_oil = wa_prof_prd-oil =  wa_prd_oil-inc_tax .
        in_tax_gas = wa_prof_prd-gas =  wa_prd_gas-inc_tax .
        in_tax_ong = wa_prof_prd-oilng  = wa_prd_oil-inc_tax + wa_prd_gas-inc_tax.

      WHEN 53."IMPAIRMENT LOSS/(REVERSAL)

        wa_prof_prd-oil = wa_prd_oil-imploss .
        wa_prof_prd-gas = wa_prd_gas-imploss .
        wa_prof_prd-oilng = wa_prof_prd-oil + wa_prof_prd-gas.

    ENDCASE.

    MODIFY it_prof_prd FROM wa_prof_prd TRANSPORTING oilng oil gas.

  ENDLOOP.

ENDFORM."CHANGE_PROF_PRD

FORM save_prof_prd.

  IF NOT grid1 IS INITIAL.
    CALL METHOD grid1->check_changed_data.
  ENDIF.

  PERFORM popup_save.

  IF ( mode NE 'DIS' ) .

    IF ans = '1'.
      IF wa_prd_oil IS NOT INITIAL AND wa_prd_gas IS NOT INITIAL.

        IF mode = 'CRE' .
          wa_prd_oil-created_by = sy-uname.
          wa_prd_gas-created_by = sy-uname.

          wa_prd_oil-created_on = sy-datum.
          wa_prd_gas-created_on = sy-datum.

        ELSEIF mode = 'CHA'.
          wa_prd_oil-changed_by = sy-uname.
          wa_prd_gas-changed_by = sy-uname.

          wa_prd_oil-changed_on = sy-datum.
          wa_prd_gas-changed_on = sy-datum.


          wa_prd_oil-approved_by = ' '.
          wa_prd_gas-approved_by = '00000000'.

          wa_prd_oil-approved_on = ' '.
          wa_prd_gas-approved_on = '00000000'.

        ENDIF.


        MODIFY zpnl_prd_oil FROM wa_prd_oil.
        MODIFY zpnl_prd_gas FROM wa_prd_gas.

        MESSAGE 'Data saved successfully.' TYPE 'S'.

        CLEAR : wa_prd_oil,
                wa_prd_gas.
      ENDIF.
    ENDIF.
    CLEAR ans.
  ENDIF.


ENDFORM."SAVE_PROF_PRD

FORM app_prd_i.

  IF mode EQ 'FRE'.
    IF wa_prd_oil-approved_by IS INITIAL AND wa_prd_gas-approved_by IS INITIAL.
      MESSAGE 'Data is not approved yet' TYPE 'E'.
    ENDIF.
  ENDIF.

  PERFORM popup_save.

  IF ans = '1'.
    IF mode = 'APP'.
      wa_prd_oil-approved_by = sy-uname.
      wa_prd_gas-approved_by = sy-uname.

      wa_prd_oil-approved_on = sy-datum.
      wa_prd_gas-approved_on = sy-datum.

      MODIFY zpnl_prd_oil FROM wa_prd_oil .
      MODIFY zpnl_prd_gas FROM wa_prd_gas .

      stat = 'APPROVED'.

      MESSAGE 'Data has been approved.' TYPE 'S'.

      CLEAR : wa_prd_oil,
              wa_prd_gas.
********      added by aparna on 03.07.2024

    ELSEIF mode = 'APF'.
      wa_prd_oil-approved_by_rp = sy-uname.
      wa_prd_gas-approved_by_rp = sy-uname.

      wa_prd_oil-approved_on_rp = sy-datum.
      wa_prd_gas-approved_on_rp = sy-datum.

      MODIFY zpnl_prd_oil FROM wa_prd_oil .
      MODIFY zpnl_prd_gas FROM wa_prd_gas .

      stat = 'APPROVED'.

      MESSAGE 'Data has been approved.' TYPE 'S'.

      CLEAR : wa_prd_oil,
              wa_prd_gas.
********      ended by aparna on 03.07.2024

    ELSEIF mode = 'FRE'.
      wa_prd_oil-freezed_by = sy-uname.
      wa_prd_gas-freezed_by = sy-uname.

      wa_prd_oil-freezed_on = sy-datum.
      wa_prd_gas-freezed_on = sy-datum.

      MODIFY zpnl_prd_oil FROM wa_prd_oil .
      MODIFY zpnl_prd_gas FROM wa_prd_gas .

      stat = 'FREEZED'.

      MESSAGE 'Data has been freezed. You cannot change this data now.' TYPE 'S'.

      CLEAR : wa_prd_oil,
              wa_prd_gas.

    ENDIF.
  ENDIF.

ENDFORM."APP_PRD_I

FORM create_oth_proj.     "Create layout for non producing projects

  CLEAR wa_oth_proj.
  REFRESH it_oth_proj[].

  wa_oth_proj-per = 'PARTICULARS'.
  wa_oth_proj-vals = '(Amount in US$ Mn.)'.
  wa_oth_proj-io_flag = ' '.
  APPEND ls_cell_color TO wa_oth_proj-cellcolor.
  CLEAR ls_cell_color.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  READ TABLE it_oth_f4 INTO DATA(wa_oth_f4) WITH KEY text_no = '301'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Revenue From Operations '.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '302'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Other Income'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  wa_oth_proj-per = 'TOTAL INCOME'.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = ' '.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '304'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Change in inventories'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '305'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Overlift/(Underlift)'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '303'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Production,Transportation,Selling & Distribution Expenditure'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '307'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "Exploration Costs written off'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '308'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Finance Cost'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '306'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'DDA'. DEPRECIATION, DEPLETION & AMORTIZATION.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '309'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "Provision & Write-off(incl. impairment)'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '310'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "Other Expenses (incl. exchange fluctuation)'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  wa_oth_proj-per = 'TOTAL EXPENSE'.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = ' '.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = 'PROFIT BEFORE TAX'.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = ' '.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR : wa_oth_proj ,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '311'.
  wa_oth_proj-per = wa_oth_f4-oth_proj. "'Income Tax'.
  wa_oth_proj-io_flag = '1'.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = ' '.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = 'NET PROFIT/(LOSS) AFTER TAX'.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.

  wa_oth_proj-per = ' '.
  wa_oth_proj-io_flag = ' '.
  APPEND wa_oth_proj TO it_oth_proj.
  CLEAR wa_oth_proj.


  CLEAR l_index.
  LOOP AT it_oth_proj.
    l_index = sy-tabix.
    REFRESH lt_celltab.


    IF it_oth_proj-io_flag = '1'.
      PERFORM fill_celltab_oth_proj USING 'RW' '1'
                           CHANGING lt_celltab.

    ELSE.
      PERFORM fill_celltab_oth_proj USING 'RO' ' '
                           CHANGING lt_celltab.
    ENDIF.

    INSERT LINES OF lt_celltab INTO TABLE it_oth_proj-celltab.
    MODIFY it_oth_proj INDEX l_index.

  ENDLOOP.

ENDFORM."CREATE_OTH_PROJ

FORM fill_celltab_oth_proj USING VALUE(p_mode) VALUE(io_flag2)
                  CHANGING pt_celltab TYPE lvc_t_styl.

  DATA : ls_celltab TYPE lvc_t_styl WITH HEADER LINE.

  CLEAR l_mode.

  IF p_mode EQ 'RW'.
    l_mode = cl_gui_alv_grid=>mc_style_enabled.
  ELSE.
    l_mode = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.

  ls_celltab-fieldname = 'PER'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  INSERT ls_celltab INTO TABLE pt_celltab.

  ls_celltab-fieldname = 'VALS'.
  IF io_flag2 CA '1'.
    ls_celltab-style = l_mode.
  ELSE.
    ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  ENDIF.
  INSERT ls_celltab INTO TABLE pt_celltab.

ENDFORM."fill_celltab_oth_proj

FORM fcat_fill_oth_proj .
  REFRESH lt_fcat[].
  DATA oth_proj_h TYPE string.

  PERFORM period_text USING s_period_low p_year.
  oth_proj_h = per_text.

  PERFORM alv_fcat USING :  'PER'   'Particulars'   '65' ,
                            'VALS'   oth_proj_h     '25'   .

ENDFORM."fcat_fill_OTH_PROJ

FORM calc_0311.           "calculate fetched/input data

  IF NOT grid1 IS INITIAL.
    CALL METHOD grid1->check_changed_data.
  ENDIF.

  wa_pnl_oth-company = p_company.
  wa_pnl_oth-company = p_company.

  wa_pnl_oth-bukrs = p_comp.
  wa_pnl_oth-bukrs = p_comp.

  wa_pnl_oth-pro_nam = p_proj.
  wa_pnl_oth-pro_nam = p_proj.

  wa_pnl_oth-fisyear = p_year.
  wa_pnl_oth-fisyear = p_year.

  wa_pnl_oth-zperiod = s_period_low.
  wa_pnl_oth-zperiod = s_period_low.

  DATA : tot_inc(10)   TYPE c,
         tot_exp(10)   TYPE c,
         prof_btax(10) TYPE c,
         prof_atax(10) TYPE c.

  LOOP AT it_oth_proj INTO wa_oth_proj.

    IF wa_oth_proj-vals CA lv_spl AND sy-tabix NE 1.
      CLEAR sy-ucomm.
      MESSAGE 'Special character in amount field is not allowed' TYPE 'W' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    CASE sy-tabix.
      WHEN 1.

      WHEN 2.
        wa_pnl_oth-rev_opr = wa_oth_proj-vals.
      WHEN 3.
        wa_pnl_oth-oth_inc = wa_oth_proj-vals.
      WHEN 4.
        tot_inc = wa_oth_proj-vals = wa_pnl_oth-rev_opr + wa_pnl_oth-oth_inc.
      WHEN 5.
      WHEN 6.
        wa_pnl_oth-chg_inv = wa_oth_proj-vals.
      WHEN 7.
        wa_pnl_oth-ovr_und = wa_oth_proj-vals.
      WHEN 8.
        wa_pnl_oth-pts_de = wa_oth_proj-vals.
      WHEN 9.
        wa_pnl_oth-exp_cst = wa_oth_proj-vals.
      WHEN 10.
        wa_pnl_oth-fin_cst = wa_oth_proj-vals.
      WHEN 11.
        wa_pnl_oth-dda = wa_oth_proj-vals.
      WHEN 12.
        wa_pnl_oth-prov_of = wa_oth_proj-vals.
      WHEN 13.
        wa_pnl_oth-oth_exp = wa_oth_proj-vals.
      WHEN 14.
        tot_exp = wa_oth_proj-vals =  wa_pnl_oth-chg_inv + wa_pnl_oth-ovr_und
                                    + wa_pnl_oth-pts_de  + wa_pnl_oth-exp_cst
                                    + wa_pnl_oth-fin_cst + wa_pnl_oth-dda
                                    + wa_pnl_oth-prov_of + wa_pnl_oth-oth_exp.

      WHEN 15.
      WHEN 16.
        prof_btax = wa_oth_proj-vals = tot_inc - tot_exp.
      WHEN 17.
      WHEN 18.
        wa_pnl_oth-inc_tax = wa_oth_proj-vals.
      WHEN 19.
      WHEN 20.
        wa_oth_proj-vals = prof_btax - wa_pnl_oth-inc_tax.

    ENDCASE.
    MODIFY it_oth_proj FROM wa_oth_proj TRANSPORTING vals.
    CLEAR wa_oth_proj.
  ENDLOOP.


ENDFORM."CALC_0311

FORM change_oth_proj.    "get previously filled data

  IF NOT grid1 IS INITIAL.
    CALL METHOD grid1->check_changed_data.
  ENDIF.

  SELECT SINGLE * FROM zpnl_oth_proj
       INTO @DATA(chk_oth_proj)
       WHERE company = @p_company
         AND bukrs   = @p_comp
         AND pro_nam = @p_proj
         AND fisyear = @p_year
         AND zperiod = @s_period_low.

  IF chk_oth_proj IS NOT INITIAL.
    MOVE-CORRESPONDING chk_oth_proj TO wa_pnl_oth.
  ENDIF.

  DATA : tot_inc(10)   TYPE c,
         tot_exp(10)   TYPE c,
         prof_btax(10) TYPE c,
         prof_atax(10) TYPE c.

  LOOP AT it_oth_proj INTO wa_oth_proj.

    CASE sy-tabix.
      WHEN 1.

      WHEN 2.
        wa_oth_proj-vals = wa_pnl_oth-rev_opr.
      WHEN 3.
        wa_oth_proj-vals = wa_pnl_oth-oth_inc.
      WHEN 4.
        tot_inc = wa_oth_proj-vals = wa_pnl_oth-rev_opr + wa_pnl_oth-oth_inc.
      WHEN 5.
      WHEN 6.
        wa_oth_proj-vals = wa_pnl_oth-chg_inv.
      WHEN 7.
        wa_oth_proj-vals = wa_pnl_oth-ovr_und.
      WHEN 8.
        wa_oth_proj-vals = wa_pnl_oth-pts_de .
      WHEN 9.
        wa_oth_proj-vals = wa_pnl_oth-exp_cst.
      WHEN 10.
        wa_oth_proj-vals = wa_pnl_oth-fin_cst.
      WHEN 11.
        wa_oth_proj-vals = wa_pnl_oth-dda    .
      WHEN 12.
        wa_oth_proj-vals = wa_pnl_oth-prov_of.
      WHEN 13.
        wa_oth_proj-vals = wa_pnl_oth-oth_exp.
      WHEN 14.
        tot_exp = wa_oth_proj-vals =  wa_pnl_oth-chg_inv + wa_pnl_oth-ovr_und
                                    + wa_pnl_oth-pts_de  + wa_pnl_oth-exp_cst
                                    + wa_pnl_oth-fin_cst + wa_pnl_oth-dda
                                    + wa_pnl_oth-prov_of + wa_pnl_oth-oth_exp.

      WHEN 15.
      WHEN 16.
        prof_btax = wa_oth_proj-vals = tot_inc - tot_exp.
      WHEN 17.
      WHEN 18.
        wa_oth_proj-vals = wa_pnl_oth-inc_tax.
      WHEN 19.
      WHEN 20.
        wa_oth_proj-vals = prof_btax - wa_pnl_oth-inc_tax.

    ENDCASE.

    MODIFY it_oth_proj FROM wa_oth_proj TRANSPORTING vals.
    CLEAR wa_oth_proj.

  ENDLOOP.

ENDFORM."CHANGE_OTH_PROJ

FORM save_oth_proj.       "save data into database tables

  IF NOT grid1 IS INITIAL.
    CALL METHOD grid1->check_changed_data.
  ENDIF.


  IF mode EQ 'FRE'.
    IF wa_pnl_oth-approve_by IS INITIAL AND wa_pnl_oth-approve_on IS INITIAL.
      MESSAGE 'Data is not approved yet' TYPE 'E'.
    ENDIF.
  ENDIF.

  PERFORM popup_save.

  IF ( mode NE 'DIS' ) .
    IF ans = '1'.
      IF wa_pnl_oth IS NOT INITIAL .

        IF mode = 'CRE'.
          wa_pnl_oth-created_by = sy-uname.
          wa_pnl_oth-created_on = sy-datum.

        ELSEIF mode = 'CHA'.
          wa_pnl_oth-changed_by = sy-uname.
          wa_pnl_oth-changed_on = sy-datum.
        ELSEIF mode = 'APP'.
          wa_pnl_oth-approve_by = sy-uname.
          wa_pnl_oth-approve_on = sy-datum.
        ELSEIF mode = 'FRE'.
          wa_pnl_oth-freezed_by = sy-uname.
          wa_pnl_oth-freezed_on = sy-datum.

        ELSEIF mode = 'APF'.
          wa_pnl_oth-approved_by_rp = sy-uname.
          wa_pnl_oth-approved_on_rp = sy-datum.
        ENDIF.

        MODIFY zpnl_oth_proj FROM wa_pnl_oth.
        CLEAR : wa_pnl_oth.

        MESSAGE 'Data saved successfully.' TYPE 'S'.

      ENDIF.
    ENDIF.
    CLEAR ans.
  ENDIF.

ENDFORM."SAVE_OTH_PROJ


FORM cre_prd_proj.    "Create layout for Producing projects variance analysis
  DATA :
    tot_rev_oil1(15)   TYPE c,     tot_rev_oil2(15) TYPE c,   tot_rev_oil3(15) TYPE c,    tot_rev_oil4(15) TYPE c, "TOTAL REV OIL
    tot_rev_gas1(15)   TYPE c,     tot_rev_gas2(15) TYPE c,   tot_rev_gas3(15) TYPE c,    tot_rev_gas4(15) TYPE c, "TOTAL REV GAS

    royalty_ong1(15)   TYPE c,     royalty_ong2(15) TYPE c,   royalty_ong3(15) TYPE c,    royalty_ong4(15) TYPE c, "Royalty
    royalty_oil1(15)   TYPE c,     royalty_oil2(15) TYPE c,   royalty_oil3(15) TYPE c,    royalty_oil4(15) TYPE c,
    royalty_gas1(15)   TYPE c,     royalty_gas2(15) TYPE c,   royalty_gas3(15) TYPE c,    royalty_gas4(15) TYPE c,

    oth_tax_ong1(15)   TYPE c,     oth_tax_ong2(15) TYPE c,   oth_tax_ong3(15) TYPE c,    oth_tax_ong4(15) TYPE c, "Other taxes(as applicable)
    oth_tax_oil1(15)   TYPE c,     oth_tax_oil2(15) TYPE c,   oth_tax_oil3(15) TYPE c,    oth_tax_oil4(15) TYPE c,
    oth_tax_gas1(15)   TYPE c,     oth_tax_gas2(15) TYPE c,   oth_tax_gas3(15) TYPE c,    oth_tax_gas4(15) TYPE c,

    net_slrl_ong1(15)  TYPE c,    net_slrl_ong2(15) TYPE c,   net_slrl_ong3(15) TYPE c,   net_slrl_ong4(15) TYPE c, "Net Sales Realisation(I)
    net_slrl_oil1(15)  TYPE c,    net_slrl_oil2(15) TYPE c,   net_slrl_oil3(15) TYPE c,   net_slrl_oil4(15) TYPE c,
    net_slrl_gas1(15)  TYPE c,    net_slrl_gas2(15) TYPE c,   net_slrl_gas3(15) TYPE c,   net_slrl_gas4(15) TYPE c,

    tot_oprx_ong1(15)  TYPE c,    tot_oprx_ong2(15) TYPE c,   tot_oprx_ong3(15) TYPE c,   tot_oprx_ong4(15) TYPE c, "Total Operating Expenses(II)
    tot_oprx_oil1(15)  TYPE c,    tot_oprx_oil2(15) TYPE c,   tot_oprx_oil3(15) TYPE c,   tot_oprx_oil4(15) TYPE c,
    tot_oprx_gas1(15)  TYPE c,    tot_oprx_gas2(15) TYPE c,   tot_oprx_gas3(15) TYPE c,   tot_oprx_gas4(15) TYPE c,

    tot_oprx_ongm1(15) TYPE c,    tot_oprx_ongm2(15) TYPE c,   tot_oprx_ongm3(15) TYPE c,   tot_oprx_ongm4(15) TYPE c, "Total Operating Expenses(II) MANUAL
    tot_oprx_oilm1(15) TYPE c,    tot_oprx_oilm2(15) TYPE c,   tot_oprx_oilm3(15) TYPE c,   tot_oprx_oilm4(15) TYPE c,
    tot_oprx_gasm1(15) TYPE c,    tot_oprx_gasm2(15) TYPE c,   tot_oprx_gasm3(15) TYPE c,   tot_oprx_gasm4(15) TYPE c,

    tot_dda_ong1(15)   TYPE c,     tot_dda_ong2(15) TYPE c,    tot_dda_ong3(15) TYPE c,    tot_dda_ong4(15) TYPE c, "Total DDA & Exploration(III)
    tot_dda_oil1(15)   TYPE c,     tot_dda_oil2(15) TYPE c,    tot_dda_oil3(15) TYPE c,    tot_dda_oil4(15) TYPE c,
    tot_dda_gas1(15)   TYPE c,     tot_dda_gas2(15) TYPE c,    tot_dda_gas3(15) TYPE c,    tot_dda_gas4(15) TYPE c,

    tot_exp_ong1(15)   TYPE c,     tot_exp_ong2(15) TYPE c,    tot_exp_ong3(15) TYPE c,    tot_exp_ong4(15) TYPE c, "Total expenses IV (II+III)
    tot_exp_oil1(15)   TYPE c,     tot_exp_oil2(15) TYPE c,    tot_exp_oil3(15) TYPE c,    tot_exp_oil4(15) TYPE c,
    tot_exp_gas1(15)   TYPE c,     tot_exp_gas2(15) TYPE c,    tot_exp_gas3(15) TYPE c,    tot_exp_gas4(15) TYPE c,

    opr_cst_ong1(15)   TYPE c,     opr_cst_ong2(15) TYPE c,    opr_cst_ong3(15) TYPE c,    opr_cst_ong4(15) TYPE c, "Operating Cost IV
    opr_cst_oil1(15)   TYPE c,     opr_cst_oil2(15) TYPE c,    opr_cst_oil3(15) TYPE c,    opr_cst_oil4(15) TYPE c,
    opr_cst_gas1(15)   TYPE c,     opr_cst_gas2(15) TYPE c,    opr_cst_gas3(15) TYPE c,    opr_cst_gas4(15) TYPE c,

    god_sld_ong1(15)   TYPE c,     god_sld_ong2(15) TYPE c,    god_sld_ong3(15) TYPE c,    god_sld_ong4(15) TYPE c, "Cost of Goods Sold VII (IV+V+VI)
    god_sld_oil1(15)   TYPE c,     god_sld_oil2(15) TYPE c,    god_sld_oil3(15) TYPE c,    god_sld_oil4(15) TYPE c,
    god_sld_gas1(15)   TYPE c,     god_sld_gas2(15) TYPE c,    god_sld_gas3(15) TYPE c,    god_sld_gas4(15) TYPE c,


    god_sld_ong11(15)  TYPE c,     god_sld_ong22(15) TYPE c,    god_sld_ong33(15) TYPE c,    god_sld_ong44(15) TYPE c, "Cost of Goods Sold VII (IV+V+VI)manual
    god_sld_oil11(15)  TYPE c,     god_sld_oil22(15) TYPE c,    god_sld_oil33(15) TYPE c,    god_sld_oil44(15) TYPE c,
    god_sld_gas11(15)  TYPE c,     god_sld_gas22(15) TYPE c,    god_sld_gas33(15) TYPE c,    god_sld_gas44(15) TYPE c,

    net_rev_ong1(15)   TYPE c,     net_rev_ong2(15) TYPE c,    net_rev_ong3(15) TYPE c,    net_rev_ong4(15) TYPE c, "Net Operating margin VIII (I-VII)
    net_rev_oil1(15)   TYPE c,     net_rev_oil2(15) TYPE c,    net_rev_oil3(15) TYPE c,    net_rev_oil4(15) TYPE c,
    net_rev_gas1(15)   TYPE c,     net_rev_gas2(15) TYPE c,    net_rev_gas3(15) TYPE c,    net_rev_gas4(15) TYPE c,

    tot_otin_ong1(15)  TYPE c,    tot_otin_ong2(15) TYPE c,   tot_otin_ong3(15) TYPE c,   tot_otin_ong4(15) TYPE c, "Total Other Income/ Expense IX
    tot_otin_oil1(15)  TYPE c,    tot_otin_oil2(15) TYPE c,   tot_otin_oil3(15) TYPE c,   tot_otin_oil4(15) TYPE c,
    tot_otin_gas1(15)  TYPE c,    tot_otin_gas2(15) TYPE c,   tot_otin_gas3(15) TYPE c,   tot_otin_gas4(15) TYPE c,

    net_btax_ong1(15)  TYPE c,    net_btax_ong2(15) TYPE c,   net_btax_ong3(15) TYPE c,   net_btax_ong4(15) TYPE c, "Net Profit Before Tax X (VIII-IX)
    net_btax_oil1(15)  TYPE c,    net_btax_oil2(15) TYPE c,   net_btax_oil3(15) TYPE c,   net_btax_oil4(15) TYPE c,
    net_btax_gas1(15)  TYPE c,    net_btax_gas2(15) TYPE c,   net_btax_gas3(15) TYPE c,   net_btax_gas4(15) TYPE c,

    in_tax_ong1(15)    TYPE c,      in_tax_ong2(15) TYPE c,     in_tax_ong3(15) TYPE c,     in_tax_ong4(15) TYPE c, "Income Tax (XI)
    in_tax_oil1(15)    TYPE c,      in_tax_oil2(15) TYPE c,     in_tax_oil3(15) TYPE c,     in_tax_oil4(15) TYPE c,
    in_tax_gas1(15)    TYPE c,      in_tax_gas2(15) TYPE c,     in_tax_gas3(15) TYPE c,     in_tax_gas4(15) TYPE c,

    imploss_ong1(15)   TYPE c,     imploss_ong2(15) TYPE c,    imploss_ong3(15) TYPE c,    imploss_ong4(15) TYPE c, "Impairment loss/(reversal)
    imploss_oil1(15)   TYPE c,     imploss_oil2(15) TYPE c,    imploss_oil3(15) TYPE c,    imploss_oil4(15) TYPE c,
    imploss_gas1(15)   TYPE c,     imploss_gas2(15) TYPE c,    imploss_gas3(15) TYPE c,    imploss_gas4(15) TYPE c,

    net_atax_ong1(15)  TYPE c,    net_atax_ong2(15) TYPE c,   net_atax_ong3(15) TYPE c,   net_atax_ong4(15) TYPE c, "Net Profit/(Loss) after tax XII (X-XI)
    net_atax_oil1(15)  TYPE c,    net_atax_oil2(15) TYPE c,   net_atax_oil3(15) TYPE c,   net_atax_oil4(15) TYPE c,
    net_atax_gas1(15)  TYPE c,    net_atax_gas2(15) TYPE c,   net_atax_gas3(15) TYPE c,   net_atax_gas4(15) TYPE c,


*****************************************************************************************************************
    inv_ong1(15)       TYPE c,    inv_ong2(15) TYPE c,   inv_ong3(15) TYPE c,   inv_ong4(15) TYPE c, " CHANGES IN IN VENTRIES
    inv_oil1(15)       TYPE c,    inv_oil2(15) TYPE c,   inv_oil3(15) TYPE c,   inv_oil4(15) TYPE c,
    inv_gas1(15)       TYPE c,    inv_gas2(15) TYPE c,   inv_gas3(15) TYPE c,   inv_gas4(15) TYPE c,

    ovr_ong1(15)       TYPE c,     ovr_ong2(15) TYPE c,    ovr_ong3(15) TYPE c,    ovr_ong4(15) TYPE c, " OVERLIFT OR UNDER LIFT
    ovr_oil1(15)       TYPE c,     ovr_oil2(15) TYPE c,    ovr_oil3(15) TYPE c,    ovr_oil4(15) TYPE c,
    ovr_gas1(15)       TYPE c,     ovr_gas2(15) TYPE c,    ovr_gas3(15) TYPE c,    ovr_gas4(15) TYPE c,

*******************************************************************************************************

    rev_oil_ong(15)    TYPE c,      rev_oil_oil(15) TYPE c,     rev_oil_gas(15) TYPE c,
    rev_gas_ong(15)    TYPE c,      rev_gas_oil(15) TYPE c,     rev_gas_gas(15) TYPE c,
    prfoilc_ong(15)    TYPE c,      prfoilc_oil(15) TYPE c,     prfoilc_gas(15) TYPE c,
    sal_vap_ong(15)    TYPE c,      sal_vap_oil(15) TYPE c,     sal_vap_gas(15) TYPE c,
    oth_rev_ong(15)    TYPE c,      oth_rev_oil(15) TYPE c,     oth_rev_gas(15) TYPE c,
    ls_met_ong(15)     TYPE c,       ls_met_oil(15) TYPE c,      ls_met_gas(15) TYPE c,
    ls_ottx_ong(15)    TYPE c,      ls_ottx_oil(15) TYPE c,     ls_ottx_gas(15) TYPE c,
    oe_prdx_ong(15)    TYPE c,      oe_prdx_oil(15) TYPE c,     oe_prdx_gas(15) TYPE c,
    oe_oexp_ong(15)    TYPE c,      oe_oexp_oil(15) TYPE c,     oe_oexp_gas(15) TYPE c,
    oechin2_ong(15)    TYPE c,      oechin2_oil(15) TYPE c,     oechin2_gas(15) TYPE c,
    oe_cgas_ong(15)    TYPE c,      oe_cgas_oil(15) TYPE c,     oe_cgas_gas(15) TYPE c,
    da_depl_ong(15)    TYPE c,      da_depl_oil(15) TYPE c,     da_depl_gas(15) TYPE c,
    da_dpam_ong(15)    TYPE c,      da_dpam_oil(15) TYPE c,     da_dpam_gas(15) TYPE c,
    da_exps_ong(15)    TYPE c,      da_exps_oil(15) TYPE c,     da_exps_gas(15) TYPE c,
    da_expd_ong(15)    TYPE c,      da_expd_oil(15) TYPE c,     da_expd_gas(15) TYPE c,
    oechin1_ong(15)    TYPE c,      oechin1_oil(15) TYPE c,     oechin1_gas(15) TYPE c,
    oe_ovun_ong(15)    TYPE c,      oe_ovun_oil(15) TYPE c,     oe_ovun_gas(15) TYPE c,
    oth_oth_ong(15)    TYPE c,      oth_oth_oil(15) TYPE c,     oth_oth_gas(15) TYPE c,
    oth_fin_ong(15)    TYPE c,      oth_fin_oil(15) TYPE c,     oth_fin_gas(15) TYPE c,
    oth_prv_ong(15)    TYPE c,      oth_prv_oil(15) TYPE c,     oth_prv_gas(15) TYPE c,
    oth_exp_ong(15)    TYPE c,      oth_exp_oil(15) TYPE c,     oth_exp_gas(15) TYPE c,
    inc_tax_ong(15)    TYPE c,      inc_tax_oil(15) TYPE c,     inc_tax_gas(15) TYPE c,
    imploss_ong(15)    TYPE c,      imploss_oil(15) TYPE c,     imploss_gas(15) TYPE c.


  DATA lt_text TYPE TABLE OF textpool.
  DATA ls_text TYPE textpool.

  DATA lv_amt(17) TYPE c.
  DATA lv_amt_o(17) TYPE c.
  DATA lv_amt_g(17) TYPE c.
  DATA lv_amt_c(17) TYPE c.

  DATA : lv_oil TYPE matnr VALUE '722000001',
         lv_con TYPE matnr VALUE '722000003',
         lv_gas TYPE matnr VALUE '722000004'.

  CLEAR wa_final_bar.
  REFRESH : it_final_bar[],lt_fcat[],it_final_bar1[].

  BREAK abapuser02.

  SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls).

  SELECT * FROM zfi_pnl_proj INTO TABLE @DATA(it_proj)
           WHERE company = @p_compy1
             AND bukrs = @p_comp1
             AND jvnam IN @p_proj1.

  IF it_proj IS NOT INITIAL.

    LOOP AT it_proj INTO DATA(wa_proj).
      IF wa_proj-manual = 'YES'.
        CLEAR manual.
        manual = 'X'.
      ENDIF.

      CLEAR assoct.
      IF wa_proj-assoct = '1'.
        assoct = '1'.
      ELSEIF wa_proj-assoct = '2'.
        assoct = '2'.
      ELSEIF wa_proj-assoct = '3'.
        assoct = '3'.
      ELSEIF wa_proj-assoct = '4'.
        assoct = '4'.
      ELSEIF wa_proj-assoct = '5'.
        assoct = '5'.
      ENDIF.

      CLEAR wa_proj.
    ENDLOOP.
  ENDIF.

  IF it_gls IS NOT INITIAL AND manual NE 'X'.

    PERFORM map_period USING s_period-low .     "Get periods according to input parameters to pass in database tables

*Fetching the values for Non Manual Projects from table JVSO1
    SELECT rldnr,
           ryear,
           rtcur,
           drcrk,
           poper,
           docnr,
           docln,
           rbukrs,
           rjvnam,
           racct,
           ksl,
           matnr
*BOC By Arnav on 26/10/26
* JVSO1 is no longer written once JVA runs on ACDOCA (S/4HANA). JV line
* items are read through the SAP view JV_JVSO1_ACDOCA (SQL view CJVSO1_ACD),
* which exposes the JVSO1 field names: field list and WHERE are unchanged.
* ASSUMPTION: ACDOCA-VNAME is filled for every year the report is run for;
* the view returns no line for a project whose ACDOCA-VNAME is blank.
*      FROM jvso1 INTO TABLE @DATA(it_jvso1)
      FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso1)
*EOC By Arnav on 26/10/26
               FOR ALL ENTRIES IN @it_gls
                WHERE rbukrs = @p_comp1
                  AND ryear  = @p_year1
                  AND rldnr  = '4A'
                  AND poper BETWEEN @s_period_low AND @s_period_high
                  AND racct  = @it_gls-gl_acct
                  AND rjvnam IN @p_proj1.

    SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls1)
              FOR ALL ENTRIES IN @it_jvso1
              WHERE gl_acct = @it_jvso1-racct.




******************CODE ADDED BY SANDEEP R AS ON `18.01.2024*********

    SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(lt_data) WHERE prd_pro = 'OTHER TAXES (AS APPLICABLE)'.

    IF lt_data IS NOT INITIAL.
      LOOP AT lt_data INTO DATA(ls_data).
*BOC By Arnav on 26/10/26
*        SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat1)
        SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat1)
*EOC By Arnav on 26/10/26
                   WHERE rbukrs = @p_comp1
                     AND ryear  = @p_year1
                     AND rldnr  = '4A'
                     AND poper BETWEEN @s_period_low AND @s_period_high
                     AND racct = @ls_data-gl_acct
                     AND rjvnam IN @p_proj1.

        oth_tax_ong1 = oth_tax_ong1 + vat1.

        CLEAR: vat1, ls_data.

      ENDLOOP.
      oth_tax_ong1 = oth_tax_ong1 / 1000000.

    ENDIF.

******************CODE ADDED BY SANDEEP R AS ON `18.01.2024*********



    IF p_year1 LT '2025'. "VAT Cal. only befor 2023

*Fetching amount for VAT in OIL
*BOC By Arnav on 26/10/26
*      SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o1)
      SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o1)
*EOC By Arnav on 26/10/26
                 WHERE rbukrs = @p_comp1
                   AND ryear  = @p_year1
                   AND rldnr  = '4A'
                   AND poper BETWEEN @s_period_low AND @s_period_high
                   AND racct  = '0000200668'
                   AND rjvnam IN @p_proj1
                   AND matnr IN ( @lv_oil ).

*Fetching amount for VAT in GAS
*BOC By Arnav on 26/10/26
*      SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g1)
      SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g1)
*EOC By Arnav on 26/10/26
                 WHERE rbukrs = @p_comp1
                   AND ryear  = @p_year1
                   AND rldnr  = '4A'
                   AND poper BETWEEN @s_period_low AND @s_period_high
                   AND racct  = '0000200668'
                   AND rjvnam IN @p_proj1
                   AND matnr IN ( @lv_gas , ' ' ).

*Fetching amount for VAT in CONDENSATE
*BOC By Arnav on 26/10/26
*      SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c1)
      SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c1)
*EOC By Arnav on 26/10/26
                 WHERE rbukrs = @p_comp1
                   AND ryear  = @p_year1
                   AND rldnr  = '4A'
                   AND poper BETWEEN @s_period_low AND @s_period_high
                   AND racct  = '0000200668'
                   AND rjvnam IN @p_proj1
                   AND matnr IN ( @lv_con ).

      vat_o1 = vat_o1 / 1000000.
      vat_g1 = vat_g1 / 1000000.
      vat_c1 = vat_c1 / 1000000.

    ENDIF.

    IF p_year2 IS NOT INITIAL AND s_period_low2 IS NOT INITIAL. "fetching values same way as frist period and year
      PERFORM map_period USING s_period_low2 .

      SELECT rldnr,
             ryear,
             rtcur,
             drcrk,
             poper,
             docnr,
             docln,
             rbukrs,
             rjvnam,
             racct,
             ksl,
             matnr
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso2)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso2)
*EOC By Arnav on 26/10/26
                 FOR ALL ENTRIES IN @it_gls
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year2
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = @it_gls-gl_acct
                    AND rjvnam IN @p_proj1.

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls2)
                   FOR ALL ENTRIES IN @it_jvso2
                   WHERE gl_acct = @it_jvso2-racct.


*****************CODE ADDED BY SANDEEP R AS ON 18.01.2024*************


      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(lt_data1) WHERE prd_pro = 'OTHER TAXES (AS APPLICABLE)'.

      IF lt_data1 IS NOT INITIAL.
        LOOP AT lt_data1 INTO DATA(ls_data1).
*BOC By Arnav on 26/10/26
*          SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat2)
          SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat2)
*EOC By Arnav on 26/10/26
                     WHERE rbukrs = @p_comp1
                       AND ryear  = @p_year2
                       AND rldnr  = '4A'
                       AND poper BETWEEN @s_period_low AND @s_period_high
                       AND racct = @ls_data1-gl_acct
                       AND rjvnam IN @p_proj1.

          oth_tax_ong2 = oth_tax_ong2 + vat2.

          CLEAR: vat2, ls_data1.

        ENDLOOP.
        oth_tax_ong2 = oth_tax_ong2 / 1000000.
      ENDIF.
*****************CODE ADDED BY SANDEEP R AS ON 18.01.2024*************


      IF p_year2 LT '2025'. "VAT Cal. only befor 2023

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o2)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o2)
*EOC By Arnav on 26/10/26
                    WHERE rbukrs = @p_comp1
                      AND ryear  = @p_year2
                      AND rldnr  = '4A'
                      AND poper BETWEEN @s_period_low AND @s_period_high
                      AND racct  = '0000200668'
                      AND rjvnam IN @p_proj1
                      AND matnr IN ( @lv_oil ).

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g2)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g2)
*EOC By Arnav on 26/10/26
                   WHERE rbukrs = @p_comp1
                     AND ryear  = @p_year2
                     AND rldnr  = '4A'
                     AND poper BETWEEN @s_period_low AND @s_period_high
                     AND racct  = '0000200668'
                     AND rjvnam IN @p_proj1
                     AND matnr IN ( @lv_gas , ' ' ).

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c2)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c2)
*EOC By Arnav on 26/10/26
                   WHERE rbukrs = @p_comp1
                     AND ryear  = @p_year2
                     AND rldnr  = '4A'
                     AND poper BETWEEN @s_period_low AND @s_period_high
                     AND racct  = '0000200668'
                     AND rjvnam IN @p_proj1
                     AND matnr IN ( @lv_con ).

        vat_o2 = vat_o2 / 1000000.
        vat_g2 = vat_g2 / 1000000.
        vat_c2 = vat_c2 / 1000000.

      ENDIF.

    ENDIF.

    IF p_year3 IS NOT INITIAL AND s_period_low3 IS NOT INITIAL. "fetching values same way as frist period and year
      PERFORM map_period USING s_period_low3 .

      SELECT rldnr,
             ryear,
             rtcur,
             drcrk,
             poper,
             docnr,
             docln,
             rbukrs,
             rjvnam,
             racct,
             ksl,
             matnr
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso3)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso3)
*EOC By Arnav on 26/10/26
                 FOR ALL ENTRIES IN @it_gls
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year3
                    AND rldnr  = '4A'
               AND poper BETWEEN @s_period_low AND @s_period_high
*                   AND POPER IN @S_PERI
                    AND racct  = @it_gls-gl_acct
                    AND rjvnam IN @p_proj1.

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls3)
               FOR ALL ENTRIES IN @it_jvso3
               WHERE gl_acct = @it_jvso3-racct.



*****************CODE ADDED BY SANDEEP R AS ON 18.01.2024*************


      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(lt_data2) WHERE prd_pro = 'OTHER TAXES (AS APPLICABLE)'.

      IF lt_data2 IS NOT INITIAL.
        LOOP AT lt_data2 INTO DATA(ls_data2).
*BOC By Arnav on 26/10/26
*          SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat3)
          SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat3)
*EOC By Arnav on 26/10/26
                     WHERE rbukrs = @p_comp1
                       AND ryear  = @p_year3
                       AND rldnr  = '4A'
                       AND poper BETWEEN @s_period_low AND @s_period_high
                       AND racct = @ls_data2-gl_acct
                       AND rjvnam IN @p_proj1.

          oth_tax_ong3 = oth_tax_ong3 + vat3.

          CLEAR: vat3, ls_data2.

        ENDLOOP.
        oth_tax_ong3 = oth_tax_ong3 / 1000000.
      ENDIF.

*****************CODE ADDED BY SANDEEP R AS ON 18.01.2024*************

      IF p_year3 LT '2025'. "VAT Cal. only befor 2023

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o3)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o3)
*EOC By Arnav on 26/10/26
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year3
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
*                   AND POPER IN @S_PERI
                    AND racct  = '0000200668'
                    AND rjvnam IN @p_proj1
                    AND matnr IN ( @lv_oil  ).

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g3)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g3)
*EOC By Arnav on 26/10/26
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year3
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
*                   AND POPER IN @S_PERI
                    AND racct  = '0000200668'
                    AND rjvnam IN @p_proj1
                    AND matnr IN ( @lv_gas , ' ' ).

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c3)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c3)
*EOC By Arnav on 26/10/26
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year3
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
*                   AND POPER IN @S_PERI
                    AND racct  = '0000200668'
                    AND rjvnam IN @p_proj1
                    AND matnr IN ( @lv_con ).

        vat_o3 = vat_o3 / 1000000.
        vat_g3 = vat_g3 / 1000000.
        vat_c3 = vat_c3 / 1000000.

      ENDIF.

    ENDIF.

    IF p_year4 IS NOT INITIAL AND s_period_low4 IS NOT INITIAL.    "fetching values same way as frist period and year
      PERFORM map_period USING s_period_low4 .

      SELECT rldnr,
             ryear,
             rtcur,
             drcrk,
             poper,
             docnr,
             docln,
             rbukrs,
             rjvnam,
             racct,
             ksl,
             matnr
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso4)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso4)
*EOC By Arnav on 26/10/26
                 FOR ALL ENTRIES IN @it_gls
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year4
                    AND rldnr  = '4A'
               AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = @it_gls-gl_acct
                    AND rjvnam IN @p_proj1.

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls4)
               FOR ALL ENTRIES IN @it_jvso4
               WHERE gl_acct = @it_jvso4-racct.



*****************CODE ADDED BY SANDEEP R AS ON 18.01.2024*************

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(lt_data3) WHERE prd_pro = 'OTHER TAXES (AS APPLICABLE)'.

      IF lt_data3 IS NOT INITIAL.
        LOOP AT lt_data3 INTO DATA(ls_data3).
*BOC By Arnav on 26/10/26
*          SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat4)
          SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat4)
*EOC By Arnav on 26/10/26
                     WHERE rbukrs = @p_comp1
                       AND ryear  = @p_year4
                       AND rldnr  = '4A'
                       AND poper BETWEEN @s_period_low AND @s_period_high
                       AND racct = @ls_data3-gl_acct
                       AND rjvnam IN @p_proj1.

          oth_tax_ong4 = oth_tax_ong4 + vat4.

          CLEAR: vat4, ls_data3.

        ENDLOOP.
        oth_tax_ong4 = oth_tax_ong4 / 1000000.
      ENDIF.

*****************CODE ADDED BY SANDEEP R AS ON 18.01.2024*************

      IF p_year4 LT '2025'. "VAT Cal. only befor 2023

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o4)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o4)
*EOC By Arnav on 26/10/26
                   WHERE rbukrs = @p_comp1
                     AND ryear  = @p_year4
                     AND rldnr  = '4A'
                     AND poper BETWEEN @s_period_low AND @s_period_high
                     AND racct  = '0000200668'
                     AND rjvnam IN @p_proj1
                     AND matnr IN ( @lv_oil ).

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g4)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g4)
*EOC By Arnav on 26/10/26
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year4
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = '0000200668'
                    AND rjvnam IN @p_proj1
                    AND matnr IN ( @lv_gas , ' ' ).

*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c4)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c4)
*EOC By Arnav on 26/10/26
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year4
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = '0000200668'
                    AND rjvnam IN @p_proj1
                    AND matnr IN ( @lv_con ).

        vat_o4 = vat_o4 / 1000000.
        vat_g4 = vat_g4 / 1000000.
        vat_c4 = vat_c4 / 1000000.

      ENDIF.

    ENDIF.


  ELSEIF it_gls IS NOT INITIAL AND manual EQ 'X'.

*Fetching the values which are entered Manually
    SELECT * FROM zpnl_prd_oil INTO TABLE @DATA(it_manual_oil)
             WHERE company = @p_compy1
               AND bukrs = @p_comp1
               AND pro_nam IN @p_proj1
               AND fisyear = @p_year1.

    SELECT * FROM zpnl_prd_gas INTO TABLE @DATA(it_manual_gas)
             WHERE company = @p_compy1
               AND bukrs = @p_comp1
               AND pro_nam IN @p_proj1
               AND fisyear = @p_year1.

    SELECT * FROM zpnl_prd_oil APPENDING TABLE it_manual_oil
             WHERE company = p_compy1
               AND bukrs = p_comp1
               AND pro_nam IN p_proj1
               AND fisyear IN ( p_year2 ,p_year3 ,p_year4 ).

    SELECT * FROM zpnl_prd_gas APPENDING TABLE it_manual_gas
             WHERE company = p_compy1
               AND bukrs = p_comp1
               AND pro_nam IN p_proj1
               AND fisyear IN ( p_year2 ,p_year3 ,p_year4 ).

  ENDIF.

*  IF PNL NE 'PRO_ANA'.
  PERFORM create_layout.   "Preparing the Report Layout/Screen
*  ENDIF.


  DATA lv_flag_ong TYPE c.

  IF it_jvso1 IS NOT INITIAL.

    LOOP AT it_gls1 INTO DATA(wa_gls1).

*      IF p_year1 LT '2023' AND wa_gls1-gl_acct = '0000200668'. "----------> Line Commented by Aparna on 22.07.2024
      IF p_year1 LT '2025' AND wa_gls1-gl_acct = '0000200668'.  "----------> Line Added     by Aparna on 22.07.2024
        wa_gls1-prd_pro = 'N/A'.
      ENDIF.


      LOOP AT it_jvso1 INTO DATA(wa_jvso1) WHERE racct = wa_gls1-gl_acct.

*Seperating revenue of Oil,Gas and Condensate accorging to their material code which are stored in single GL in database

        IF wa_gls1-prd_pro EQ TEXT-103 OR wa_gls1-prd_pro EQ TEXT-115 OR wa_gls1-prd_pro EQ TEXT-117.    "Gl/s with description as Oil,
          IF wa_jvso1-matnr = lv_oil. "Crude Oil                                                        "-as Natural Gas & as Condensate
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso1-ksl.
          ELSEIF wa_jvso1-matnr = lv_gas. "Natural Gas
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso1-ksl.
          ELSEIF wa_gls1-gl_acct = '0000230116' AND wa_jvso1-matnr = lv_con. "Condensate
            lv_flag_ong = 'C'.
            lv_amt_c = lv_amt_c + wa_jvso1-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso1-ksl.

*Seperating Royalty of oil and gas from respt. gl to add it later in calculations
        ELSEIF wa_gls1-prd_pro EQ TEXT-102.     "Gl/s with description as Royalty
          CLEAR wa_setgls.
          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls1-gl_acct.
          IF wa_setgls-descript = TEXT-401. "Royalty-crude oil
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso1-ksl."oil
          ELSEIF wa_setgls-descript = TEXT-402. "Royalty-natural gas
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso1-ksl."gas
          ENDIF.
          lv_amt = lv_amt + wa_jvso1-ksl."total

        ELSE.       "all other GLs
          lv_amt = lv_amt + wa_jvso1-ksl.
        ENDIF.

        CLEAR wa_jvso1.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.
      CONDENSE lv_amt_o NO-GAPS.
      CONDENSE lv_amt_g NO-GAPS.
      CONDENSE lv_amt_c NO-GAPS.

*Inserting fetched values (IF the GL desc = Desc of a Row in Report).
*Calculate all total and inserting the seperated oil and gas values for revenue as pre flag set in above code
      READ TABLE it_final_bar INTO wa_final_bar WITH KEY per = wa_gls1-prd_pro.
      IF wa_final_bar IS NOT INITIAL.

        IF lv_flag_ong = 'O'.
          lv_amt_o = lv_amt_o / 1000000.
          wa_final_bar-oil1   = ( wa_final_bar-oil1 + lv_amt_o ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil1 WHERE per = wa_gls1-prd_pro.
        ELSEIF lv_flag_ong = 'G' .
          lv_amt_g = lv_amt_g / 1000000.
          wa_final_bar-gas1   = ( wa_final_bar-gas1 + lv_amt_g ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas1 WHERE per = wa_gls1-prd_pro.
        ENDIF.

        IF wa_final_bar-gas1 IS NOT INITIAL OR wa_final_bar-oil1 IS NOT INITIAL.
*          <<<<<<<<<<   added by aparna on 17/7/2024 on request of Rahul pauranik
          IF p_year1 GT '2022'.

            "----------------------------------" Comment begins by Aparna on 10.08.2024 "------------------------------*

****        wa_final_bar-total1 = (  wa_final_bar-total1 + wa_final_bar-oil1 + wa_final_bar-gas1 ).
            wa_final_bar-total1 = (  wa_final_bar-total1 + lv_amt_o + lv_amt_g ).

            "----------------------------------" Comment ended by Aparna on 10.08.2024 "-------------------------------*

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 WHERE per = wa_gls1-prd_pro.
          ELSE.
            wa_final_bar-total1 = (   wa_final_bar-oil1 + wa_final_bar-gas1 ).
            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 WHERE per = wa_gls1-prd_pro.
          ENDIF.
        ELSE.
          IF lv_flag_ong = 'C' .
            lv_amt_c = lv_amt_c / 1000000.
            wa_final_bar-total1 = ( wa_final_bar-total1 + lv_amt_c ).
          ELSE.
            lv_amt = lv_amt / 1000000.
            wa_final_bar-total1 = ( wa_final_bar-total1 + lv_amt ).
          ENDIF.

          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls1-gl_acct.
          IF wa_setgls-descript = TEXT-403 AND sy-subrc = 0.          "IMPAIRMENT LOSS/(REVERSAL)
            DATA(wa_final_bar_imp) = wa_final_bar.
            wa_final_bar_imp-total1 = lv_amt.
            MODIFY it_final_bar FROM wa_final_bar_imp TRANSPORTING total1 WHERE per = TEXT-403.
            CLEAR wa_final_bar_imp.
          ENDIF.
          CLEAR wa_setgls.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 WHERE per = wa_gls1-prd_pro.
        ENDIF.

      ENDIF.

      CLEAR : wa_final_bar,lv_amt,wa_gls1,lv_amt_o,lv_amt_g,lv_flag_ong,lv_amt_c.

    ENDLOOP.
  ENDIF.


  IF it_jvso2 IS NOT INITIAL.
    LOOP AT it_gls2 INTO DATA(wa_gls2).

*      IF p_year1 LT '2023' AND wa_gls1-gl_acct = '0000200668'. "----------> Line Commented by Aparna on 22.07.2024
      IF p_year2 LT '2025' AND wa_gls2-gl_acct = '0000200668'.  "----------> Line Added     by Aparna on 22.07.2024
        wa_gls2-prd_pro = 'N/A'.
      ENDIF.

      LOOP AT it_jvso2 INTO DATA(wa_jvso2) WHERE racct = wa_gls2-gl_acct.

        IF wa_gls2-prd_pro EQ TEXT-103 OR wa_gls2-prd_pro EQ TEXT-115 OR wa_gls2-prd_pro EQ TEXT-117.
          IF wa_jvso2-matnr = lv_oil.
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso2-ksl.
          ELSEIF  wa_jvso2-matnr = lv_gas.
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso2-ksl.
          ELSEIF wa_gls2-gl_acct = '0000230116' AND wa_jvso2-matnr = lv_con. "Condensate
            lv_flag_ong = 'C'.
            lv_amt_c = lv_amt_c + wa_jvso2-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso2-ksl.
        ELSEIF wa_gls2-prd_pro EQ TEXT-102.
          CLEAR wa_setgls.
          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls2-gl_acct.
          IF wa_setgls-descript = TEXT-401. "Royalty-crude oil
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso2-ksl.
          ELSEIF wa_setgls-descript = TEXT-402. "Royalty-natural gas.
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso2-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso2-ksl.
        ELSE.
          lv_amt = lv_amt + wa_jvso2-ksl.
        ENDIF.

        CLEAR wa_jvso2.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.
      CONDENSE lv_amt_o NO-GAPS.
      CONDENSE lv_amt_g NO-GAPS.
      CONDENSE lv_amt_c NO-GAPS.


      READ TABLE it_final_bar INTO wa_final_bar WITH KEY per = wa_gls2-prd_pro.
      IF wa_final_bar IS NOT INITIAL.
        IF lv_flag_ong = 'O'.
          lv_amt_o = lv_amt_o / 1000000.
          wa_final_bar-oil2   = ( wa_final_bar-oil2 + lv_amt_o ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil2 WHERE per = wa_gls2-prd_pro.
        ELSEIF lv_flag_ong = 'G' .
          lv_amt_g = lv_amt_g / 1000000.
          wa_final_bar-gas2   = ( wa_final_bar-gas2 + lv_amt_g ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas2 WHERE per = wa_gls2-prd_pro.
        ENDIF.
        IF wa_final_bar-gas2 IS NOT INITIAL OR wa_final_bar-oil2 IS NOT INITIAL.
*************************************
          IF p_year1 GT '2022'.

            "----------------------------------" Comment begins by Aparna on 10.08.2024 "------------------------------*

****        wa_final_bar-total1 = (  wa_final_bar-total1 + wa_final_bar-oil1 + wa_final_bar-gas1 ).
            wa_final_bar-total2 = (  wa_final_bar-total2 + lv_amt_o + lv_amt_g ).
*             wa_final_bar-total2 = (  wa_final_bar-total2 + wa_final_bar-oil2 + wa_final_bar-gas2 ).

            "----------------------------------" Comment ended by Aparna on 10.08.2024 "-------------------------------*

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total2 WHERE per = wa_gls2-prd_pro.
          ELSE.
            wa_final_bar-total2 = (   wa_final_bar-oil2 + wa_final_bar-gas2 ).
            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total2 WHERE per = wa_gls2-prd_pro.
          ENDIF.
***************************************************

        ELSE.
          IF lv_flag_ong = 'C' .
            lv_amt_c = lv_amt_c / 1000000.
            wa_final_bar-total2 = ( wa_final_bar-total2 + lv_amt_c ) .
          ELSE.
            lv_amt = lv_amt / 1000000.
            wa_final_bar-total2 = ( wa_final_bar-total2 + lv_amt ) .
          ENDIF.

          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls2-gl_acct.
          IF wa_setgls-descript = TEXT-403 AND sy-subrc = 0.          "IMPAIRMENT LOSS/(REVERSAL)
            wa_final_bar_imp = wa_final_bar.
            wa_final_bar_imp-total2 = lv_amt.
            MODIFY it_final_bar FROM wa_final_bar_imp TRANSPORTING total2 WHERE per = TEXT-403.
            CLEAR wa_final_bar_imp.
          ENDIF.
          CLEAR wa_setgls.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total2 WHERE per = wa_gls2-prd_pro.
        ENDIF.
      ENDIF.

      CLEAR : wa_final_bar,lv_amt,wa_gls2,lv_amt_o,lv_amt_g,lv_flag_ong,lv_amt_c.

    ENDLOOP.

  ENDIF.


  IF it_jvso3 IS NOT INITIAL.
    LOOP AT it_gls3 INTO DATA(wa_gls3).

*      IF p_year1 LT '2023' AND wa_gls1-gl_acct = '0000200668'. "----------> Line Commented by Aparna on 22.07.2024
      IF p_year3 LT '2025' AND wa_gls3-gl_acct = '0000200668'.  "----------> Line Added     by Aparna on 22.07.2024
        wa_gls3-prd_pro = 'N/A'.
      ENDIF.

      LOOP AT it_jvso3 INTO DATA(wa_jvso3) WHERE racct = wa_gls3-gl_acct.

        IF wa_gls3-prd_pro EQ TEXT-103 OR wa_gls3-prd_pro EQ TEXT-115 OR wa_gls2-prd_pro EQ TEXT-117.
          IF wa_jvso3-matnr = lv_oil.
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso3-ksl.
          ELSEIF wa_jvso3-matnr = lv_gas.
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso3-ksl.
          ELSEIF wa_gls3-gl_acct = '0000230116' AND wa_jvso3-matnr = lv_con.
            lv_flag_ong = 'C'.
            lv_amt_c = lv_amt_c + wa_jvso3-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso3-ksl.
        ELSEIF wa_gls3-prd_pro EQ TEXT-102.
          CLEAR wa_setgls.
          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls3-gl_acct.
          IF wa_setgls-descript = TEXT-401. "Royalty-crude oil
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso3-ksl.
          ELSEIF wa_setgls-descript = TEXT-402. "Royalty-natural gas
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso3-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso3-ksl.
        ELSE.
          lv_amt = lv_amt + wa_jvso3-ksl.
        ENDIF.

        CLEAR wa_jvso3.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.
      CONDENSE lv_amt_o NO-GAPS.
      CONDENSE lv_amt_g NO-GAPS.
      CONDENSE lv_amt_c NO-GAPS.


      READ TABLE it_final_bar INTO wa_final_bar WITH KEY per = wa_gls3-prd_pro.
      IF wa_final_bar IS NOT INITIAL.
        IF lv_flag_ong = 'O'.
          lv_amt_o = lv_amt_o / 1000000.
          wa_final_bar-oil3   = ( wa_final_bar-oil3 + lv_amt_o ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil3 WHERE per = wa_gls3-prd_pro.
        ELSEIF lv_flag_ong = 'G' .
          lv_amt_g = lv_amt_g / 1000000.
          wa_final_bar-gas3   = ( wa_final_bar-gas3 + lv_amt_g ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas3 WHERE per = wa_gls3-prd_pro.
        ENDIF.

        IF wa_final_bar-gas3 IS NOT INITIAL OR wa_final_bar-oil3 IS NOT INITIAL.
**********************************
          IF p_year1 GT '2022'.
*            wa_final_bar-total3 = (  wa_final_bar-total3 + wa_final_bar-oil3 + wa_final_bar-gas3 ).

            wa_final_bar-total3 = (  wa_final_bar-total3 +  lv_amt_o + lv_amt_g ).

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total3 WHERE per = wa_gls3-prd_pro.
          ELSE.
            wa_final_bar-total3 = (   wa_final_bar-oil3 + wa_final_bar-gas3 ).
            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total3 WHERE per = wa_gls3-prd_pro.
          ENDIF.
****************************************

        ELSE.
          IF lv_flag_ong = 'C' .
            lv_amt_c = lv_amt_c / 1000000.
            wa_final_bar-total3 = ( wa_final_bar-total3 + lv_amt_c ) .
          ELSE.
            lv_amt = lv_amt / 1000000.
            wa_final_bar-total3 = ( wa_final_bar-total3 + lv_amt ) .
          ENDIF.

          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls3-gl_acct.
          IF wa_setgls-descript = TEXT-403 AND sy-subrc = 0.          "IMPAIRMENT LOSS/(REVERSAL)
            wa_final_bar_imp = wa_final_bar.
            wa_final_bar_imp-total3 = lv_amt.
            MODIFY it_final_bar FROM wa_final_bar_imp TRANSPORTING total3 WHERE per = TEXT-403.
            CLEAR wa_final_bar_imp.
*            MODIFY IT_FINAL_BAR FROM WA_FINAL_BAR TRANSPORTING TOTAL3 WHERE PER = TEXT-403.
          ENDIF.
          CLEAR wa_setgls.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total3 WHERE per = wa_gls3-prd_pro.
        ENDIF.
      ENDIF.

      CLEAR : wa_final_bar,lv_amt,wa_gls3,lv_amt_o,lv_amt_g,lv_flag_ong,lv_amt_c.

    ENDLOOP.

  ENDIF.


  IF it_jvso4 IS NOT INITIAL.
    LOOP AT it_gls4 INTO DATA(wa_gls4).

*      IF p_year1 LT '2023' AND wa_gls1-gl_acct = '0000200668'. "----------> Line Commented by Aparna on 22.07.2024
      IF p_year4 LT '2025' AND wa_gls4-gl_acct = '0000200668'.  "----------> Line Added     by Aparna on 22.07.2024
        wa_gls4-prd_pro = 'N/A'.
      ENDIF.

      LOOP AT it_jvso4 INTO DATA(wa_jvso4) WHERE racct = wa_gls4-gl_acct.

        IF wa_gls4-prd_pro EQ TEXT-103 OR wa_gls4-prd_pro EQ TEXT-115 OR wa_gls1-prd_pro EQ TEXT-117.
          IF wa_jvso4-matnr = lv_oil.
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso4-ksl.
          ELSEIF wa_jvso4-matnr = lv_gas.
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso4-ksl.
          ELSEIF wa_gls4-gl_acct = '0000230116' AND wa_jvso4-matnr = lv_con.
            lv_flag_ong = 'C'.
            lv_amt_c = lv_amt_c + wa_jvso4-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso4-ksl.
        ELSEIF wa_gls4-prd_pro EQ TEXT-102.
          CLEAR wa_setgls.
          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls4-gl_acct.
          IF wa_setgls-descript = TEXT-401. "Royalty-crude oil
            lv_flag_ong = 'O'.
            lv_amt_o = lv_amt_o + wa_jvso4-ksl.
          ELSEIF wa_setgls-descript = TEXT-402. "Royalty-natural gas
            lv_flag_ong = 'G'.
            lv_amt_g = lv_amt_g + wa_jvso4-ksl.
          ENDIF.
          lv_amt = lv_amt + wa_jvso4-ksl.
        ELSE.
          lv_amt = lv_amt + wa_jvso4-ksl.
        ENDIF.

        CLEAR wa_jvso4.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.
      CONDENSE lv_amt_o NO-GAPS.
      CONDENSE lv_amt_g NO-GAPS.
      CONDENSE lv_amt_c NO-GAPS.


      READ TABLE it_final_bar INTO wa_final_bar WITH KEY per = wa_gls4-prd_pro.
      IF wa_final_bar IS NOT INITIAL.
        IF lv_flag_ong = 'O'.
          lv_amt_o = lv_amt_o / 1000000.
          wa_final_bar-oil4   = ( wa_final_bar-oil4 + lv_amt_o ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil4 WHERE per = wa_gls4-prd_pro.
        ELSEIF lv_flag_ong = 'G' .
          lv_amt_g = lv_amt_g / 1000000.
          wa_final_bar-gas4   = ( wa_final_bar-gas4 + lv_amt_g ).
          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas4 WHERE per = wa_gls4-prd_pro.
        ENDIF.
        IF wa_final_bar-gas4 IS NOT INITIAL OR wa_final_bar-oil4 IS NOT INITIAL.
          IF p_year1 GT '2022'.
*            wa_final_bar-total4 = (  wa_final_bar-total4 + wa_final_bar-oil4 + wa_final_bar-gas4 ).
            wa_final_bar-total4 = (  wa_final_bar-total4 +   lv_amt_o + lv_amt_g ).

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total4 WHERE per = wa_gls4-prd_pro.
          ELSE.
            wa_final_bar-total4 = (   wa_final_bar-oil4 + wa_final_bar-gas4 ).
            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total4 WHERE per = wa_gls4-prd_pro.
          ENDIF.

        ELSE.
          IF lv_flag_ong = 'C' .
            lv_amt_c = lv_amt_c / 1000000.
            wa_final_bar-total4 = ( wa_final_bar-total4 + lv_amt_c ) .
          ELSE.
            lv_amt = lv_amt / 1000000.
            wa_final_bar-total4 = ( wa_final_bar-total4 + lv_amt ) .
          ENDIF.

          READ TABLE it_setgls INTO wa_setgls WITH KEY valfrom = wa_gls4-gl_acct.
          IF wa_setgls-descript = TEXT-403 AND sy-subrc = 0.          "IMPAIRMENT LOSS/(REVERSAL)
            wa_final_bar_imp = wa_final_bar.
            wa_final_bar_imp-total4 = lv_amt.
            MODIFY it_final_bar FROM wa_final_bar_imp TRANSPORTING total4 WHERE per = TEXT-403.
            CLEAR wa_final_bar_imp.
*              MODIFY IT_FINAL_BAR FROM WA_FINAL_BAR TRANSPORTING TOTAL4 WHERE PER = TEXT-403.
          ENDIF.
          CLEAR wa_setgls.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total4 WHERE per = wa_gls4-prd_pro.
        ENDIF.
      ENDIF.

      CLEAR : wa_final_bar,lv_amt,wa_gls4,lv_amt_o,lv_amt_g,lv_flag_ong,lv_amt_c.

    ENDLOOP.

  ENDIF.

*Auto calculation (in case of manually entered project) to get Q2,Q3,Q4 values i.e. Q2 = Q1-H1, Q3 = H1-9M & Q4 = 9M-ANNUAL
  CLEAR : peri1_1,peri2_1,peri3_1,peri4_1,
          peri1_2,peri2_2,peri3_2,peri4_2.

  CASE s_period-low.
    WHEN 'Q2'.
      peri1_1 = 'Q1'.
      peri1_2 = 'H1'.
    WHEN 'Q3'.
      peri1_1 = 'H1'.
      peri1_2 = '9M'.
    WHEN 'Q4'.
      peri1_1 = '9M'.
      peri1_2 = 'ANNUAL'.
    WHEN OTHERS.
      peri1_1 = s_period-low.
      peri1_2 = s_period-low.
  ENDCASE.

  CASE s_period_low2.
    WHEN 'Q2'.
      peri2_1 = 'Q1'.
      peri2_2 = 'H1'.
    WHEN 'Q3'.
      peri2_1 = 'H1'.
      peri2_2 = '9M'.
    WHEN 'Q4'.
      peri2_1 = '9M'.
      peri2_2 = 'ANNUAL'.
    WHEN OTHERS.
      peri2_1 = s_period_low2.
      peri2_2 = s_period_low2.
  ENDCASE.

  CASE s_period_low3.
    WHEN 'Q2'.
      peri3_1 = 'Q1'.
      peri3_2 = 'H1'.
    WHEN 'Q3'.
      peri3_1 = 'H1'.
      peri3_2 = '9M'.
    WHEN 'Q4'.
      peri3_1 = '9M'.
      peri3_2 = 'ANNUAL'.
    WHEN OTHERS.
      peri3_1 = s_period_low3.
      peri3_2 = s_period_low3.
  ENDCASE.

  CASE s_period_low4.
    WHEN 'Q2'.
      peri4_1 = 'Q1'.
      peri4_2 = 'H1'.
    WHEN 'Q3'.
      peri4_1 = 'H1'.
      peri4_2 = '9M'.
    WHEN 'Q4'.
      peri4_1 = '9M'.
      peri4_2 = 'ANNUAL'.
    WHEN OTHERS.
      peri4_1 = s_period_low4.
      peri4_2 = s_period_low4.
  ENDCASE.

  IF it_manual_oil IS NOT INITIAL AND it_manual_gas IS NOT INITIAL.
    DATA : it_manual_oil2 TYPE STANDARD TABLE OF zpnl_prd_oil,
           it_manual_gas2 TYPE STANDARD TABLE OF zpnl_prd_gas.

************************Input Oil and Input Gas
    MOVE-CORRESPONDING it_manual_oil TO it_manual_oil2.
    MOVE-CORRESPONDING it_manual_gas TO it_manual_gas2.

    DATA lv_msg1 TYPE string.

    CLEAR lv_msg1.
    IF peri1_1 IS NOT INITIAL AND peri1_2 IS NOT INITIAL.
      READ TABLE it_manual_oil INTO DATA(wa_manual_oil1) WITH KEY fisyear = p_year1 zperiod = peri1_2.
      READ TABLE it_manual_oil2 INTO DATA(wa_manual_oil1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

      READ TABLE it_manual_gas INTO DATA(wa_manual_gas1) WITH KEY fisyear = p_year1 zperiod = peri1_2.
      READ TABLE it_manual_gas2 INTO DATA(wa_manual_gas1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

      IF wa_manual_oil1 IS INITIAL OR wa_manual_gas1 IS INITIAL..
        CONCATENATE lv_msg1 '[ 1 Year' p_year1 'and Period' peri1_2 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.
      IF wa_manual_oil1_1 IS INITIAL OR wa_manual_gas1_1 IS INITIAL.
        CONCATENATE lv_msg1 '[ 1.1 Year' p_year1 'and Period' peri1_1 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.

      wa_manual_oil1-zperiod = s_period-low.
      wa_manual_oil1-rev_oil = wa_manual_oil1-rev_oil - wa_manual_oil1_1-rev_oil.
      wa_manual_oil1-rev_gas = wa_manual_oil1-rev_gas - wa_manual_oil1_1-rev_gas.
      wa_manual_oil1-prfoilc = wa_manual_oil1-prfoilc - wa_manual_oil1_1-prfoilc.
      wa_manual_oil1-sal_vap = wa_manual_oil1-sal_vap - wa_manual_oil1_1-sal_vap.
      wa_manual_oil1-oth_rev = wa_manual_oil1-oth_rev - wa_manual_oil1_1-oth_rev.
      wa_manual_oil1-ls_met  = wa_manual_oil1-ls_met  - wa_manual_oil1_1-ls_met .
      wa_manual_oil1-ls_ottx = wa_manual_oil1-ls_ottx - wa_manual_oil1_1-ls_ottx.
      wa_manual_oil1-oe_prdx = wa_manual_oil1-oe_prdx - wa_manual_oil1_1-oe_prdx.
      wa_manual_oil1-oe_oexp = wa_manual_oil1-oe_oexp - wa_manual_oil1_1-oe_oexp.
      wa_manual_oil1-oechin2 = wa_manual_oil1-oechin2 - wa_manual_oil1_1-oechin2.
      wa_manual_oil1-oe_cgas = wa_manual_oil1-oe_cgas - wa_manual_oil1_1-oe_cgas.
      wa_manual_oil1-da_depl = wa_manual_oil1-da_depl - wa_manual_oil1_1-da_depl.
      wa_manual_oil1-da_dpam = wa_manual_oil1-da_dpam - wa_manual_oil1_1-da_dpam.
      wa_manual_oil1-da_exps = wa_manual_oil1-da_exps - wa_manual_oil1_1-da_exps.
      wa_manual_oil1-da_expd = wa_manual_oil1-da_expd - wa_manual_oil1_1-da_expd.
      wa_manual_oil1-oechin1 = wa_manual_oil1-oechin1 - wa_manual_oil1_1-oechin1.
      wa_manual_oil1-oe_ovun = wa_manual_oil1-oe_ovun - wa_manual_oil1_1-oe_ovun.
      wa_manual_oil1-oth_oth = wa_manual_oil1-oth_oth - wa_manual_oil1_1-oth_oth.
      wa_manual_oil1-oth_fin = wa_manual_oil1-oth_fin - wa_manual_oil1_1-oth_fin.
      wa_manual_oil1-oth_prv = wa_manual_oil1-oth_prv - wa_manual_oil1_1-oth_prv.
      wa_manual_oil1-oth_exp = wa_manual_oil1-oth_exp - wa_manual_oil1_1-oth_exp.
      wa_manual_oil1-inc_tax = wa_manual_oil1-inc_tax - wa_manual_oil1_1-inc_tax.
      wa_manual_oil1-imploss = wa_manual_oil1-imploss - wa_manual_oil1_1-imploss.

      wa_manual_gas1-zperiod = s_period-low.
      wa_manual_gas1-rev_oil = wa_manual_gas1-rev_oil - wa_manual_gas1_1-rev_oil.
      wa_manual_gas1-rev_gas = wa_manual_gas1-rev_gas - wa_manual_gas1_1-rev_gas.
      wa_manual_gas1-prfoilc = wa_manual_gas1-prfoilc - wa_manual_gas1_1-prfoilc.
      wa_manual_gas1-sal_vap = wa_manual_gas1-sal_vap - wa_manual_gas1_1-sal_vap.
      wa_manual_gas1-oth_rev = wa_manual_gas1-oth_rev - wa_manual_gas1_1-oth_rev.
      wa_manual_gas1-ls_met  = wa_manual_gas1-ls_met  - wa_manual_gas1_1-ls_met .
      wa_manual_gas1-ls_ottx = wa_manual_gas1-ls_ottx - wa_manual_gas1_1-ls_ottx.
      wa_manual_gas1-oe_prdx = wa_manual_gas1-oe_prdx - wa_manual_gas1_1-oe_prdx.
      wa_manual_gas1-oe_oexp = wa_manual_gas1-oe_oexp - wa_manual_gas1_1-oe_oexp.
      wa_manual_gas1-oechin2 = wa_manual_gas1-oechin2 - wa_manual_gas1_1-oechin2.
      wa_manual_gas1-oe_cgas = wa_manual_gas1-oe_cgas - wa_manual_gas1_1-oe_cgas.
      wa_manual_gas1-da_depl = wa_manual_gas1-da_depl - wa_manual_gas1_1-da_depl.
      wa_manual_gas1-da_dpam = wa_manual_gas1-da_dpam - wa_manual_gas1_1-da_dpam.
      wa_manual_gas1-da_exps = wa_manual_gas1-da_exps - wa_manual_gas1_1-da_exps.
      wa_manual_gas1-da_expd = wa_manual_gas1-da_expd - wa_manual_gas1_1-da_expd.
      wa_manual_gas1-oechin1 = wa_manual_gas1-oechin1 - wa_manual_gas1_1-oechin1.
      wa_manual_gas1-oe_ovun = wa_manual_gas1-oe_ovun - wa_manual_gas1_1-oe_ovun.
      wa_manual_gas1-oth_oth = wa_manual_gas1-oth_oth - wa_manual_gas1_1-oth_oth.
      wa_manual_gas1-oth_fin = wa_manual_gas1-oth_fin - wa_manual_gas1_1-oth_fin.
      wa_manual_gas1-oth_prv = wa_manual_gas1-oth_prv - wa_manual_gas1_1-oth_prv.
      wa_manual_gas1-oth_exp = wa_manual_gas1-oth_exp - wa_manual_gas1_1-oth_exp.
      wa_manual_gas1-inc_tax = wa_manual_gas1-inc_tax - wa_manual_gas1_1-inc_tax.
      wa_manual_gas1-imploss = wa_manual_gas1-imploss - wa_manual_gas1_1-imploss.

      APPEND wa_manual_oil1 TO it_manual_oil.
      CLEAR : wa_manual_oil1,wa_manual_oil1_1.

      APPEND wa_manual_gas1 TO it_manual_gas.
      CLEAR : wa_manual_gas1,wa_manual_gas1_1.

    ENDIF.

    IF peri2_1 IS NOT INITIAL AND peri2_2 IS NOT INITIAL.

      READ TABLE it_manual_oil INTO wa_manual_oil1 WITH KEY fisyear = p_year2 zperiod = peri2_2.
      READ TABLE it_manual_oil2 INTO wa_manual_oil1_1 WITH KEY fisyear = p_year2 zperiod = peri2_1.

      READ TABLE it_manual_gas INTO wa_manual_gas1 WITH KEY fisyear = p_year2 zperiod = peri2_2.
      READ TABLE it_manual_gas2 INTO wa_manual_gas1_1 WITH KEY fisyear = p_year2 zperiod = peri2_1.

      IF wa_manual_oil1 IS INITIAL OR wa_manual_gas1 IS INITIAL..
        CONCATENATE lv_msg1 '[ 2 Year' p_year2 'and Period' peri2_2 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.
      IF wa_manual_oil1_1 IS INITIAL OR wa_manual_gas1_1 IS INITIAL.
        CONCATENATE lv_msg1 '[ 2.1 Year' p_year2 'and Period' peri2_1 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.

      wa_manual_oil1-zperiod = s_period_low2.
      wa_manual_oil1-rev_oil = wa_manual_oil1-rev_oil - wa_manual_oil1_1-rev_oil.
      wa_manual_oil1-rev_gas = wa_manual_oil1-rev_gas - wa_manual_oil1_1-rev_gas.
      wa_manual_oil1-prfoilc = wa_manual_oil1-prfoilc - wa_manual_oil1_1-prfoilc.
      wa_manual_oil1-sal_vap = wa_manual_oil1-sal_vap - wa_manual_oil1_1-sal_vap.
      wa_manual_oil1-oth_rev = wa_manual_oil1-oth_rev - wa_manual_oil1_1-oth_rev.
      wa_manual_oil1-ls_met  = wa_manual_oil1-ls_met  - wa_manual_oil1_1-ls_met .
      wa_manual_oil1-ls_ottx = wa_manual_oil1-ls_ottx - wa_manual_oil1_1-ls_ottx.
      wa_manual_oil1-oe_prdx = wa_manual_oil1-oe_prdx - wa_manual_oil1_1-oe_prdx.
      wa_manual_oil1-oe_oexp = wa_manual_oil1-oe_oexp - wa_manual_oil1_1-oe_oexp.
      wa_manual_oil1-oechin2 = wa_manual_oil1-oechin2 - wa_manual_oil1_1-oechin2.
      wa_manual_oil1-oe_cgas = wa_manual_oil1-oe_cgas - wa_manual_oil1_1-oe_cgas.
      wa_manual_oil1-da_depl = wa_manual_oil1-da_depl - wa_manual_oil1_1-da_depl.
      wa_manual_oil1-da_dpam = wa_manual_oil1-da_dpam - wa_manual_oil1_1-da_dpam.
      wa_manual_oil1-da_exps = wa_manual_oil1-da_exps - wa_manual_oil1_1-da_exps.
      wa_manual_oil1-da_expd = wa_manual_oil1-da_expd - wa_manual_oil1_1-da_expd.
      wa_manual_oil1-oechin1 = wa_manual_oil1-oechin1 - wa_manual_oil1_1-oechin1.
      wa_manual_oil1-oe_ovun = wa_manual_oil1-oe_ovun - wa_manual_oil1_1-oe_ovun.
      wa_manual_oil1-oth_oth = wa_manual_oil1-oth_oth - wa_manual_oil1_1-oth_oth.
      wa_manual_oil1-oth_fin = wa_manual_oil1-oth_fin - wa_manual_oil1_1-oth_fin.
      wa_manual_oil1-oth_prv = wa_manual_oil1-oth_prv - wa_manual_oil1_1-oth_prv.
      wa_manual_oil1-oth_exp = wa_manual_oil1-oth_exp - wa_manual_oil1_1-oth_exp.
      wa_manual_oil1-inc_tax = wa_manual_oil1-inc_tax - wa_manual_oil1_1-inc_tax.
      wa_manual_oil1-imploss = wa_manual_oil1-imploss - wa_manual_oil1_1-imploss.

      wa_manual_gas1-zperiod = s_period_low2.
      wa_manual_gas1-rev_oil = wa_manual_gas1-rev_oil - wa_manual_gas1_1-rev_oil.
      wa_manual_gas1-rev_gas = wa_manual_gas1-rev_gas - wa_manual_gas1_1-rev_gas.
      wa_manual_gas1-prfoilc = wa_manual_gas1-prfoilc - wa_manual_gas1_1-prfoilc.
      wa_manual_gas1-sal_vap = wa_manual_gas1-sal_vap - wa_manual_gas1_1-sal_vap.
      wa_manual_gas1-oth_rev = wa_manual_gas1-oth_rev - wa_manual_gas1_1-oth_rev.
      wa_manual_gas1-ls_met  = wa_manual_gas1-ls_met  - wa_manual_gas1_1-ls_met .
      wa_manual_gas1-ls_ottx = wa_manual_gas1-ls_ottx - wa_manual_gas1_1-ls_ottx.
      wa_manual_gas1-oe_prdx = wa_manual_gas1-oe_prdx - wa_manual_gas1_1-oe_prdx.
      wa_manual_gas1-oe_oexp = wa_manual_gas1-oe_oexp - wa_manual_gas1_1-oe_oexp.
      wa_manual_gas1-oechin2 = wa_manual_gas1-oechin2 - wa_manual_gas1_1-oechin2.
      wa_manual_gas1-oe_cgas = wa_manual_gas1-oe_cgas - wa_manual_gas1_1-oe_cgas.
      wa_manual_gas1-da_depl = wa_manual_gas1-da_depl - wa_manual_gas1_1-da_depl.
      wa_manual_gas1-da_dpam = wa_manual_gas1-da_dpam - wa_manual_gas1_1-da_dpam.
      wa_manual_gas1-da_exps = wa_manual_gas1-da_exps - wa_manual_gas1_1-da_exps.
      wa_manual_gas1-da_expd = wa_manual_gas1-da_expd - wa_manual_gas1_1-da_expd.
      wa_manual_gas1-oechin1 = wa_manual_gas1-oechin1 - wa_manual_gas1_1-oechin1.
      wa_manual_gas1-oe_ovun = wa_manual_gas1-oe_ovun - wa_manual_gas1_1-oe_ovun.
      wa_manual_gas1-oth_oth = wa_manual_gas1-oth_oth - wa_manual_gas1_1-oth_oth.
      wa_manual_gas1-oth_fin = wa_manual_gas1-oth_fin - wa_manual_gas1_1-oth_fin.
      wa_manual_gas1-oth_prv = wa_manual_gas1-oth_prv - wa_manual_gas1_1-oth_prv.
      wa_manual_gas1-oth_exp = wa_manual_gas1-oth_exp - wa_manual_gas1_1-oth_exp.
      wa_manual_gas1-inc_tax = wa_manual_gas1-inc_tax - wa_manual_gas1_1-inc_tax.
      wa_manual_gas1-imploss = wa_manual_gas1-imploss - wa_manual_gas1_1-imploss.

      APPEND wa_manual_oil1 TO it_manual_oil.
      CLEAR : wa_manual_oil1,wa_manual_oil1_1.

      APPEND wa_manual_gas1 TO it_manual_gas.
      CLEAR : wa_manual_gas1,wa_manual_gas1_1.

    ENDIF.

    IF peri3_1 IS NOT INITIAL AND peri3_2 IS NOT INITIAL.
      READ TABLE it_manual_oil INTO wa_manual_oil1 WITH KEY fisyear = p_year3 zperiod = peri3_2.
      READ TABLE it_manual_oil2 INTO wa_manual_oil1_1 WITH KEY fisyear = p_year3 zperiod = peri3_1.

      READ TABLE it_manual_gas INTO wa_manual_gas1 WITH KEY fisyear = p_year3 zperiod = peri3_2.
      READ TABLE it_manual_gas2 INTO wa_manual_gas1_1 WITH KEY fisyear = p_year3 zperiod = peri3_1.

      IF wa_manual_oil1 IS INITIAL OR wa_manual_gas1 IS INITIAL..
        CONCATENATE lv_msg1 '[ 3 Year' p_year3 'and Period' peri3_2 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.
      IF wa_manual_oil1_1 IS INITIAL OR wa_manual_gas1_1 IS INITIAL.
        CONCATENATE lv_msg1 '[ 3.1 Year' p_year3 'and Period' peri3_1 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.

      wa_manual_oil1-zperiod = s_period_low3.
      wa_manual_oil1-rev_oil = wa_manual_oil1-rev_oil - wa_manual_oil1_1-rev_oil.
      wa_manual_oil1-rev_gas = wa_manual_oil1-rev_gas - wa_manual_oil1_1-rev_gas.
      wa_manual_oil1-prfoilc = wa_manual_oil1-prfoilc - wa_manual_oil1_1-prfoilc.
      wa_manual_oil1-sal_vap = wa_manual_oil1-sal_vap - wa_manual_oil1_1-sal_vap.
      wa_manual_oil1-oth_rev = wa_manual_oil1-oth_rev - wa_manual_oil1_1-oth_rev.
      wa_manual_oil1-ls_met  = wa_manual_oil1-ls_met  - wa_manual_oil1_1-ls_met .
      wa_manual_oil1-ls_ottx = wa_manual_oil1-ls_ottx - wa_manual_oil1_1-ls_ottx.
      wa_manual_oil1-oe_prdx = wa_manual_oil1-oe_prdx - wa_manual_oil1_1-oe_prdx.
      wa_manual_oil1-oe_oexp = wa_manual_oil1-oe_oexp - wa_manual_oil1_1-oe_oexp.
      wa_manual_oil1-oechin2 = wa_manual_oil1-oechin2 - wa_manual_oil1_1-oechin2.
      wa_manual_oil1-oe_cgas = wa_manual_oil1-oe_cgas - wa_manual_oil1_1-oe_cgas.
      wa_manual_oil1-da_depl = wa_manual_oil1-da_depl - wa_manual_oil1_1-da_depl.
      wa_manual_oil1-da_dpam = wa_manual_oil1-da_dpam - wa_manual_oil1_1-da_dpam.
      wa_manual_oil1-da_exps = wa_manual_oil1-da_exps - wa_manual_oil1_1-da_exps.
      wa_manual_oil1-da_expd = wa_manual_oil1-da_expd - wa_manual_oil1_1-da_expd.
      wa_manual_oil1-oechin1 = wa_manual_oil1-oechin1 - wa_manual_oil1_1-oechin1.
      wa_manual_oil1-oe_ovun = wa_manual_oil1-oe_ovun - wa_manual_oil1_1-oe_ovun.
      wa_manual_oil1-oth_oth = wa_manual_oil1-oth_oth - wa_manual_oil1_1-oth_oth.
      wa_manual_oil1-oth_fin = wa_manual_oil1-oth_fin - wa_manual_oil1_1-oth_fin.
      wa_manual_oil1-oth_prv = wa_manual_oil1-oth_prv - wa_manual_oil1_1-oth_prv.
      wa_manual_oil1-oth_exp = wa_manual_oil1-oth_exp - wa_manual_oil1_1-oth_exp.
      wa_manual_oil1-inc_tax = wa_manual_oil1-inc_tax - wa_manual_oil1_1-inc_tax.
      wa_manual_oil1-imploss = wa_manual_oil1-imploss - wa_manual_oil1_1-imploss.

      wa_manual_gas1-zperiod = s_period_low3.
      wa_manual_gas1-rev_oil = wa_manual_gas1-rev_oil - wa_manual_gas1_1-rev_oil.
      wa_manual_gas1-rev_gas = wa_manual_gas1-rev_gas - wa_manual_gas1_1-rev_gas.
      wa_manual_gas1-prfoilc = wa_manual_gas1-prfoilc - wa_manual_gas1_1-prfoilc.
      wa_manual_gas1-sal_vap = wa_manual_gas1-sal_vap - wa_manual_gas1_1-sal_vap.
      wa_manual_gas1-oth_rev = wa_manual_gas1-oth_rev - wa_manual_gas1_1-oth_rev.
      wa_manual_gas1-ls_met  = wa_manual_gas1-ls_met  - wa_manual_gas1_1-ls_met .
      wa_manual_gas1-ls_ottx = wa_manual_gas1-ls_ottx - wa_manual_gas1_1-ls_ottx.
      wa_manual_gas1-oe_prdx = wa_manual_gas1-oe_prdx - wa_manual_gas1_1-oe_prdx.
      wa_manual_gas1-oe_oexp = wa_manual_gas1-oe_oexp - wa_manual_gas1_1-oe_oexp.
      wa_manual_gas1-oechin2 = wa_manual_gas1-oechin2 - wa_manual_gas1_1-oechin2.
      wa_manual_gas1-oe_cgas = wa_manual_gas1-oe_cgas - wa_manual_gas1_1-oe_cgas.
      wa_manual_gas1-da_depl = wa_manual_gas1-da_depl - wa_manual_gas1_1-da_depl.
      wa_manual_gas1-da_dpam = wa_manual_gas1-da_dpam - wa_manual_gas1_1-da_dpam.
      wa_manual_gas1-da_exps = wa_manual_gas1-da_exps - wa_manual_gas1_1-da_exps.
      wa_manual_gas1-da_expd = wa_manual_gas1-da_expd - wa_manual_gas1_1-da_expd.
      wa_manual_gas1-oechin1 = wa_manual_gas1-oechin1 - wa_manual_gas1_1-oechin1.
      wa_manual_gas1-oe_ovun = wa_manual_gas1-oe_ovun - wa_manual_gas1_1-oe_ovun.
      wa_manual_gas1-oth_oth = wa_manual_gas1-oth_oth - wa_manual_gas1_1-oth_oth.
      wa_manual_gas1-oth_fin = wa_manual_gas1-oth_fin - wa_manual_gas1_1-oth_fin.
      wa_manual_gas1-oth_prv = wa_manual_gas1-oth_prv - wa_manual_gas1_1-oth_prv.
      wa_manual_gas1-oth_exp = wa_manual_gas1-oth_exp - wa_manual_gas1_1-oth_exp.
      wa_manual_gas1-inc_tax = wa_manual_gas1-inc_tax - wa_manual_gas1_1-inc_tax.
      wa_manual_gas1-imploss = wa_manual_gas1-imploss - wa_manual_gas1_1-imploss.

      APPEND wa_manual_oil1 TO it_manual_oil.
      CLEAR : wa_manual_oil1,wa_manual_oil1_1.

      APPEND wa_manual_gas1 TO it_manual_gas.
      CLEAR : wa_manual_gas1,wa_manual_gas1_1.

    ENDIF.

    IF peri4_1 IS NOT INITIAL AND peri4_2 IS NOT INITIAL.
      READ TABLE it_manual_oil INTO wa_manual_oil1 WITH KEY fisyear = p_year4 zperiod = peri4_2.
      READ TABLE it_manual_oil2 INTO wa_manual_oil1_1 WITH KEY fisyear = p_year4 zperiod = peri4_1.

      READ TABLE it_manual_gas INTO wa_manual_gas1 WITH KEY fisyear = p_year4 zperiod = peri4_2.
      READ TABLE it_manual_gas2 INTO wa_manual_gas1_1 WITH KEY fisyear = p_year4 zperiod = peri4_1.

      IF wa_manual_oil1 IS INITIAL OR wa_manual_gas1 IS INITIAL..
        CONCATENATE lv_msg1 '[ 4 Year' p_year4 'and Period' peri4_2 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.
      IF wa_manual_oil1_1 IS INITIAL OR wa_manual_gas1_1 IS INITIAL.
        CONCATENATE lv_msg1 '[ 4.1 Year' p_year4 'and Period' peri4_1 ']' INTO lv_msg1 SEPARATED BY space.
      ENDIF.

      wa_manual_oil1-zperiod = s_period_low4.
      wa_manual_oil1-rev_oil = wa_manual_oil1-rev_oil - wa_manual_oil1_1-rev_oil.
      wa_manual_oil1-rev_gas = wa_manual_oil1-rev_gas - wa_manual_oil1_1-rev_gas.
      wa_manual_oil1-prfoilc = wa_manual_oil1-prfoilc - wa_manual_oil1_1-prfoilc.
      wa_manual_oil1-sal_vap = wa_manual_oil1-sal_vap - wa_manual_oil1_1-sal_vap.
      wa_manual_oil1-oth_rev = wa_manual_oil1-oth_rev - wa_manual_oil1_1-oth_rev.
      wa_manual_oil1-ls_met  = wa_manual_oil1-ls_met  - wa_manual_oil1_1-ls_met .
      wa_manual_oil1-ls_ottx = wa_manual_oil1-ls_ottx - wa_manual_oil1_1-ls_ottx.
      wa_manual_oil1-oe_prdx = wa_manual_oil1-oe_prdx - wa_manual_oil1_1-oe_prdx.
      wa_manual_oil1-oe_oexp = wa_manual_oil1-oe_oexp - wa_manual_oil1_1-oe_oexp.
      wa_manual_oil1-oechin2 = wa_manual_oil1-oechin2 - wa_manual_oil1_1-oechin2.
      wa_manual_oil1-oe_cgas = wa_manual_oil1-oe_cgas - wa_manual_oil1_1-oe_cgas.
      wa_manual_oil1-da_depl = wa_manual_oil1-da_depl - wa_manual_oil1_1-da_depl.
      wa_manual_oil1-da_dpam = wa_manual_oil1-da_dpam - wa_manual_oil1_1-da_dpam.
      wa_manual_oil1-da_exps = wa_manual_oil1-da_exps - wa_manual_oil1_1-da_exps.
      wa_manual_oil1-da_expd = wa_manual_oil1-da_expd - wa_manual_oil1_1-da_expd.
      wa_manual_oil1-oechin1 = wa_manual_oil1-oechin1 - wa_manual_oil1_1-oechin1.
      wa_manual_oil1-oe_ovun = wa_manual_oil1-oe_ovun - wa_manual_oil1_1-oe_ovun.
      wa_manual_oil1-oth_oth = wa_manual_oil1-oth_oth - wa_manual_oil1_1-oth_oth.
      wa_manual_oil1-oth_fin = wa_manual_oil1-oth_fin - wa_manual_oil1_1-oth_fin.
      wa_manual_oil1-oth_prv = wa_manual_oil1-oth_prv - wa_manual_oil1_1-oth_prv.
      wa_manual_oil1-oth_exp = wa_manual_oil1-oth_exp - wa_manual_oil1_1-oth_exp.
      wa_manual_oil1-inc_tax = wa_manual_oil1-inc_tax - wa_manual_oil1_1-inc_tax.
      wa_manual_oil1-imploss = wa_manual_oil1-imploss - wa_manual_oil1_1-imploss.

      wa_manual_gas1-zperiod = s_period_low4.
      wa_manual_gas1-rev_oil = wa_manual_gas1-rev_oil - wa_manual_gas1_1-rev_oil.
      wa_manual_gas1-rev_gas = wa_manual_gas1-rev_gas - wa_manual_gas1_1-rev_gas.
      wa_manual_gas1-prfoilc = wa_manual_gas1-prfoilc - wa_manual_gas1_1-prfoilc.
      wa_manual_gas1-sal_vap = wa_manual_gas1-sal_vap - wa_manual_gas1_1-sal_vap.
      wa_manual_gas1-oth_rev = wa_manual_gas1-oth_rev - wa_manual_gas1_1-oth_rev.
      wa_manual_gas1-ls_met  = wa_manual_gas1-ls_met  - wa_manual_gas1_1-ls_met .
      wa_manual_gas1-ls_ottx = wa_manual_gas1-ls_ottx - wa_manual_gas1_1-ls_ottx.
      wa_manual_gas1-oe_prdx = wa_manual_gas1-oe_prdx - wa_manual_gas1_1-oe_prdx.
      wa_manual_gas1-oe_oexp = wa_manual_gas1-oe_oexp - wa_manual_gas1_1-oe_oexp.
      wa_manual_gas1-oechin2 = wa_manual_gas1-oechin2 - wa_manual_gas1_1-oechin2.
      wa_manual_gas1-oe_cgas = wa_manual_gas1-oe_cgas - wa_manual_gas1_1-oe_cgas.
      wa_manual_gas1-da_depl = wa_manual_gas1-da_depl - wa_manual_gas1_1-da_depl.
      wa_manual_gas1-da_dpam = wa_manual_gas1-da_dpam - wa_manual_gas1_1-da_dpam.
      wa_manual_gas1-da_exps = wa_manual_gas1-da_exps - wa_manual_gas1_1-da_exps.
      wa_manual_gas1-da_expd = wa_manual_gas1-da_expd - wa_manual_gas1_1-da_expd.
      wa_manual_gas1-oechin1 = wa_manual_gas1-oechin1 - wa_manual_gas1_1-oechin1.
      wa_manual_gas1-oe_ovun = wa_manual_gas1-oe_ovun - wa_manual_gas1_1-oe_ovun.
      wa_manual_gas1-oth_oth = wa_manual_gas1-oth_oth - wa_manual_gas1_1-oth_oth.
      wa_manual_gas1-oth_fin = wa_manual_gas1-oth_fin - wa_manual_gas1_1-oth_fin.
      wa_manual_gas1-oth_prv = wa_manual_gas1-oth_prv - wa_manual_gas1_1-oth_prv.
      wa_manual_gas1-oth_exp = wa_manual_gas1-oth_exp - wa_manual_gas1_1-oth_exp.
      wa_manual_gas1-inc_tax = wa_manual_gas1-inc_tax - wa_manual_gas1_1-inc_tax.
      wa_manual_gas1-imploss = wa_manual_gas1-imploss - wa_manual_gas1_1-imploss.

      APPEND wa_manual_oil1 TO it_manual_oil.
      CLEAR : wa_manual_oil1,wa_manual_oil1_1.

      APPEND wa_manual_gas1 TO it_manual_gas.
      CLEAR : wa_manual_gas1,wa_manual_gas1_1.

    ENDIF.

    IF lv_msg1 IS NOT INITIAL.
      CLEAR sy-ucomm.
      CONCATENATE 'No Data Found for:-' lv_msg1 INTO lv_msg1.
      MESSAGE lv_msg1 TYPE 'E' DISPLAY LIKE 'I'.
    ENDIF.

    CLEAR : wa_manual_oil1,wa_manual_gas1.

*Moving values into the screen(in case of manual)
***********************Input Oil

    READ TABLE it_manual_oil INTO wa_manual_oil1 WITH KEY fisyear = p_year1 zperiod = s_period-low.

    READ TABLE it_manual_oil INTO DATA(wa_manual_oil2) WITH KEY fisyear = p_year2 zperiod = s_period_low2.

    READ TABLE it_manual_oil INTO DATA(wa_manual_oil3) WITH KEY fisyear = p_year3 zperiod = s_period_low3.

    READ TABLE it_manual_oil INTO DATA(wa_manual_oil4) WITH KEY fisyear = p_year4 zperiod = s_period_low4.

***********************Input Gas

    READ TABLE it_manual_gas INTO wa_manual_gas1 WITH KEY fisyear = p_year1 zperiod = s_period-low.

    READ TABLE it_manual_gas INTO DATA(wa_manual_gas2) WITH KEY fisyear = p_year2 zperiod = s_period_low2.

    READ TABLE it_manual_gas INTO DATA(wa_manual_gas3) WITH KEY fisyear = p_year3 zperiod = s_period_low3.

    READ TABLE it_manual_gas INTO DATA(wa_manual_gas4) WITH KEY fisyear = p_year4 zperiod = s_period_low4.


    LOOP AT it_final_bar INTO wa_final_bar.

      CASE sy-tabix.
        WHEN 1. "Revenue from Crude Oil
          wa_final_bar-total1 = wa_manual_oil1-rev_oil + wa_manual_gas1-rev_oil.
          wa_final_bar-oil1   = wa_manual_oil1-rev_oil.
          wa_final_bar-gas1   = wa_manual_gas1-rev_oil.

          wa_final_bar-total2 = wa_manual_oil2-rev_oil + wa_manual_gas2-rev_oil.
          wa_final_bar-oil2   = wa_manual_oil2-rev_oil.
          wa_final_bar-gas2   = wa_manual_gas2-rev_oil.

          wa_final_bar-total3 = wa_manual_oil3-rev_oil + wa_manual_gas3-rev_oil.
          wa_final_bar-oil3   = wa_manual_oil3-rev_oil.
          wa_final_bar-gas3   = wa_manual_gas3-rev_oil.

          wa_final_bar-total4 = wa_manual_oil4-rev_oil + wa_manual_gas4-rev_oil.
          wa_final_bar-oil4   = wa_manual_oil4-rev_oil.
          wa_final_bar-gas4   = wa_manual_gas4-rev_oil.

        WHEN 2."Revenue from Natural gas
          wa_final_bar-total1 = wa_manual_oil1-rev_gas + wa_manual_gas1-rev_gas.
          wa_final_bar-oil1   = wa_manual_oil1-rev_gas.
          wa_final_bar-gas1   = wa_manual_gas1-rev_gas.

          wa_final_bar-total2 = wa_manual_oil2-rev_gas + wa_manual_gas2-rev_gas.
          wa_final_bar-oil2   = wa_manual_oil2-rev_gas.
          wa_final_bar-gas2   = wa_manual_gas2-rev_gas.

          wa_final_bar-total3 = wa_manual_oil3-rev_gas + wa_manual_gas3-rev_gas.
          wa_final_bar-oil3   = wa_manual_oil3-rev_gas.
          wa_final_bar-gas3   = wa_manual_gas3-rev_gas.

          wa_final_bar-total4 = wa_manual_oil4-rev_gas + wa_manual_gas4-rev_gas.
          wa_final_bar-oil4   = wa_manual_oil4-rev_gas.
          wa_final_bar-gas4   = wa_manual_gas4-rev_gas.


        WHEN 3."Less: Profit Oil paid in cash
          wa_final_bar-total1 = wa_manual_oil1-prfoilc + wa_manual_gas1-prfoilc.
          wa_final_bar-oil1   = wa_manual_oil1-prfoilc.
          wa_final_bar-gas1   = wa_manual_gas1-prfoilc.

          wa_final_bar-total2 = wa_manual_oil2-prfoilc + wa_manual_gas2-prfoilc.
          wa_final_bar-oil2   = wa_manual_oil2-prfoilc.
          wa_final_bar-gas2   = wa_manual_gas2-prfoilc.

          wa_final_bar-total3 = wa_manual_oil3-prfoilc + wa_manual_gas3-prfoilc.
          wa_final_bar-oil3   = wa_manual_oil3-prfoilc.
          wa_final_bar-gas3   = wa_manual_gas3-prfoilc.

          wa_final_bar-total4 = wa_manual_oil4-prfoilc + wa_manual_gas4-prfoilc.
          wa_final_bar-oil4   = wa_manual_oil4-prfoilc.
          wa_final_bar-gas4   = wa_manual_gas4-prfoilc.

        WHEN 4."Sale of VAP
          wa_final_bar-total1 = wa_manual_oil1-sal_vap + wa_manual_gas1-sal_vap.
          wa_final_bar-oil1   = wa_manual_oil1-sal_vap.
          wa_final_bar-gas1   = wa_manual_gas1-sal_vap.

          wa_final_bar-total2 = wa_manual_oil2-sal_vap + wa_manual_gas2-sal_vap.
          wa_final_bar-oil2   = wa_manual_oil2-sal_vap.
          wa_final_bar-gas2   = wa_manual_gas2-sal_vap.

          wa_final_bar-total3 = wa_manual_oil3-sal_vap + wa_manual_gas3-sal_vap.
          wa_final_bar-oil3   = wa_manual_oil3-sal_vap.
          wa_final_bar-gas3   = wa_manual_gas3-sal_vap.

          wa_final_bar-total4 = wa_manual_oil4-sal_vap + wa_manual_gas4-sal_vap.
          wa_final_bar-oil4   = wa_manual_oil4-sal_vap.
          wa_final_bar-gas4   = wa_manual_gas4-sal_vap.

        WHEN 5."Other Operating Revenue
          wa_final_bar-total1 = wa_manual_oil1-oth_rev + wa_manual_gas1-oth_rev.
          wa_final_bar-oil1   = wa_manual_oil1-oth_rev.
          wa_final_bar-gas1   = wa_manual_gas1-oth_rev.

          wa_final_bar-total2 = wa_manual_oil2-oth_rev + wa_manual_gas2-oth_rev.
          wa_final_bar-oil2   = wa_manual_oil2-oth_rev.
          wa_final_bar-gas2   = wa_manual_gas2-oth_rev.

          wa_final_bar-total3 = wa_manual_oil3-oth_rev + wa_manual_gas3-oth_rev.
          wa_final_bar-oil3   = wa_manual_oil3-oth_rev.
          wa_final_bar-gas3   = wa_manual_gas3-oth_rev.

          wa_final_bar-total4 = wa_manual_oil4-oth_rev + wa_manual_gas4-oth_rev.
          wa_final_bar-oil4   = wa_manual_oil4-oth_rev.
          wa_final_bar-gas4   = wa_manual_gas4-oth_rev.


        WHEN 9."Royalty
          wa_final_bar-total1 = wa_manual_oil1-ls_met + wa_manual_gas1-ls_met.
          wa_final_bar-oil1   = wa_manual_oil1-ls_met.
          wa_final_bar-gas1   = wa_manual_gas1-ls_met.

          wa_final_bar-total2 = wa_manual_oil2-ls_met + wa_manual_gas2-ls_met.
          wa_final_bar-oil2   = wa_manual_oil2-ls_met.
          wa_final_bar-gas2   = wa_manual_gas2-ls_met.

          wa_final_bar-total3 = wa_manual_oil3-ls_met + wa_manual_gas3-ls_met.
          wa_final_bar-oil3   = wa_manual_oil3-ls_met.
          wa_final_bar-gas3   = wa_manual_gas3-ls_met.

          wa_final_bar-total4 = wa_manual_oil4-ls_met + wa_manual_gas4-ls_met.
          wa_final_bar-oil4   = wa_manual_oil4-ls_met.
          wa_final_bar-gas4   = wa_manual_gas4-ls_met.


        WHEN 10."Other taxes(as applicable)

          wa_final_bar-total1 = wa_manual_oil1-ls_ottx + wa_manual_gas1-ls_ottx.
          wa_final_bar-oil1   = wa_manual_oil1-ls_ottx.
          wa_final_bar-gas1   = wa_manual_gas1-ls_ottx.

          wa_final_bar-total2 = wa_manual_oil2-ls_ottx + wa_manual_gas2-ls_ottx.
          wa_final_bar-oil2   = wa_manual_oil2-ls_ottx.
          wa_final_bar-gas2   = wa_manual_gas2-ls_ottx.

          wa_final_bar-total3 = wa_manual_oil3-ls_ottx + wa_manual_gas3-ls_ottx.
          wa_final_bar-oil3   = wa_manual_oil3-ls_ottx.
          wa_final_bar-gas3   = wa_manual_gas3-ls_ottx.

          wa_final_bar-total4 = wa_manual_oil4-ls_ottx + wa_manual_gas4-ls_ottx.
          wa_final_bar-oil4   = wa_manual_oil4-ls_ottx.
          wa_final_bar-gas4   = wa_manual_gas4-ls_ottx.


        WHEN 11."Production expense
          wa_final_bar-total1 = wa_manual_oil1-oe_prdx + wa_manual_gas1-oe_prdx.
          wa_final_bar-oil1   = wa_manual_oil1-oe_prdx.
          wa_final_bar-gas1   = wa_manual_gas1-oe_prdx.

          wa_final_bar-total2 = wa_manual_oil2-oe_prdx + wa_manual_gas2-oe_prdx.
          wa_final_bar-oil2   = wa_manual_oil2-oe_prdx.
          wa_final_bar-gas2   = wa_manual_gas2-oe_prdx.

          wa_final_bar-total3 = wa_manual_oil3-oe_prdx + wa_manual_gas3-oe_prdx.
          wa_final_bar-oil3   = wa_manual_oil3-oe_prdx.
          wa_final_bar-gas3   = wa_manual_gas3-oe_prdx.

          wa_final_bar-total4 = wa_manual_oil4-oe_prdx + wa_manual_gas4-oe_prdx.
          wa_final_bar-oil4   = wa_manual_oil4-oe_prdx.
          wa_final_bar-gas4   = wa_manual_gas4-oe_prdx.


        WHEN 12."Other Operating Expenses
          wa_final_bar-total1 = wa_manual_oil1-oe_oexp + wa_manual_gas1-oe_oexp.
          wa_final_bar-oil1   = wa_manual_oil1-oe_oexp.
          wa_final_bar-gas1   = wa_manual_gas1-oe_oexp.

          wa_final_bar-total2 = wa_manual_oil2-oe_oexp + wa_manual_gas2-oe_oexp.
          wa_final_bar-oil2   = wa_manual_oil2-oe_oexp.
          wa_final_bar-gas2   = wa_manual_gas2-oe_oexp.

          wa_final_bar-total3 = wa_manual_oil3-oe_oexp + wa_manual_gas3-oe_oexp.
          wa_final_bar-oil3   = wa_manual_oil3-oe_oexp.
          wa_final_bar-gas3   = wa_manual_gas3-oe_oexp.

          wa_final_bar-total4 = wa_manual_oil4-oe_oexp + wa_manual_gas4-oe_oexp.
          wa_final_bar-oil4   = wa_manual_oil4-oe_oexp.
          wa_final_bar-gas4   = wa_manual_gas4-oe_oexp.


        WHEN 13."Transportation expense
          wa_final_bar-total1 = wa_manual_oil1-oechin2 + wa_manual_gas1-oechin2.
          wa_final_bar-oil1   = wa_manual_oil1-oechin2.
          wa_final_bar-gas1   = wa_manual_gas1-oechin2.

          wa_final_bar-total2 = wa_manual_oil2-oechin2 + wa_manual_gas2-oechin2.
          wa_final_bar-oil2   = wa_manual_oil2-oechin2.
          wa_final_bar-gas2   = wa_manual_gas2-oechin2.

          wa_final_bar-total3 = wa_manual_oil3-oechin2 + wa_manual_gas3-oechin2.
          wa_final_bar-oil3   = wa_manual_oil3-oechin2.
          wa_final_bar-gas3   = wa_manual_gas3-oechin2.

          wa_final_bar-total4 = wa_manual_oil4-oechin2 + wa_manual_gas4-oechin2.
          wa_final_bar-oil4   = wa_manual_oil4-oechin2.
          wa_final_bar-gas4   = wa_manual_gas4-oechin2.


        WHEN 14."Internal consumption of Gas
          wa_final_bar-total1 = wa_manual_oil1-oe_cgas + wa_manual_gas1-oe_cgas.
          wa_final_bar-oil1   = wa_manual_oil1-oe_cgas.
          wa_final_bar-gas1   = wa_manual_gas1-oe_cgas.

          wa_final_bar-total2 = wa_manual_oil2-oe_cgas + wa_manual_gas2-oe_cgas.
          wa_final_bar-oil2   = wa_manual_oil2-oe_cgas.
          wa_final_bar-gas2   = wa_manual_gas2-oe_cgas.

          wa_final_bar-total3 = wa_manual_oil3-oe_cgas + wa_manual_gas3-oe_cgas.
          wa_final_bar-oil3   = wa_manual_oil3-oe_cgas.
          wa_final_bar-gas3   = wa_manual_gas3-oe_cgas.

          wa_final_bar-total4 = wa_manual_oil4-oe_cgas + wa_manual_gas4-oe_cgas.
          wa_final_bar-oil4   = wa_manual_oil4-oe_cgas.
          wa_final_bar-gas4   = wa_manual_gas4-oe_cgas.


        WHEN 18."Depletion
          wa_final_bar-total1 = wa_manual_oil1-da_depl + wa_manual_gas1-da_depl.
          wa_final_bar-oil1   = wa_manual_oil1-da_depl.
          wa_final_bar-gas1   = wa_manual_gas1-da_depl.

          wa_final_bar-total2 = wa_manual_oil2-da_depl + wa_manual_gas2-da_depl.
          wa_final_bar-oil2   = wa_manual_oil2-da_depl.
          wa_final_bar-gas2   = wa_manual_gas2-da_depl.

          wa_final_bar-total3 = wa_manual_oil3-da_depl + wa_manual_gas3-da_depl.
          wa_final_bar-oil3   = wa_manual_oil3-da_depl.
          wa_final_bar-gas3   = wa_manual_gas3-da_depl.

          wa_final_bar-total4 = wa_manual_oil4-da_depl + wa_manual_gas4-da_depl.
          wa_final_bar-oil4   = wa_manual_oil4-da_depl.
          wa_final_bar-gas4   = wa_manual_gas4-da_depl.


        WHEN 19."Depreciation and Amortisation
          wa_final_bar-total1 = wa_manual_oil1-da_dpam + wa_manual_gas1-da_dpam.
          wa_final_bar-oil1   = wa_manual_oil1-da_dpam.
          wa_final_bar-gas1   = wa_manual_gas1-da_dpam.

          wa_final_bar-total2 = wa_manual_oil2-da_dpam + wa_manual_gas2-da_dpam.
          wa_final_bar-oil2   = wa_manual_oil2-da_dpam.
          wa_final_bar-gas2   = wa_manual_gas2-da_dpam.

          wa_final_bar-total3 = wa_manual_oil3-da_dpam + wa_manual_gas3-da_dpam.
          wa_final_bar-oil3   = wa_manual_oil3-da_dpam.
          wa_final_bar-gas3   = wa_manual_gas3-da_dpam.

          wa_final_bar-total4 = wa_manual_oil4-da_dpam + wa_manual_gas4-da_dpam.
          wa_final_bar-oil4   = wa_manual_oil4-da_dpam.
          wa_final_bar-gas4   = wa_manual_gas4-da_dpam.


        WHEN 20."Exploration Costs (Survey)
          wa_final_bar-total1 = wa_manual_oil1-da_exps + wa_manual_gas1-da_exps.
          wa_final_bar-oil1   = wa_manual_oil1-da_exps.
          wa_final_bar-gas1   = wa_manual_gas1-da_exps.

          wa_final_bar-total2 = wa_manual_oil2-da_exps + wa_manual_gas2-da_exps.
          wa_final_bar-oil2   = wa_manual_oil2-da_exps.
          wa_final_bar-gas2   = wa_manual_gas2-da_exps.

          wa_final_bar-total3 = wa_manual_oil3-da_exps + wa_manual_gas3-da_exps.
          wa_final_bar-oil3   = wa_manual_oil3-da_exps.
          wa_final_bar-gas3   = wa_manual_gas3-da_exps.

          wa_final_bar-total4 = wa_manual_oil4-da_exps + wa_manual_gas4-da_exps.
          wa_final_bar-oil4   = wa_manual_oil4-da_exps.
          wa_final_bar-gas4   = wa_manual_gas4-da_exps.


        WHEN 21."Exploration Costs (Dry Well)
          wa_final_bar-total1 = wa_manual_oil1-da_expd + wa_manual_gas1-da_expd.
          wa_final_bar-oil1   = wa_manual_oil1-da_expd.
          wa_final_bar-gas1   = wa_manual_gas1-da_expd.

          wa_final_bar-total2 = wa_manual_oil2-da_expd + wa_manual_gas2-da_expd.
          wa_final_bar-oil2   = wa_manual_oil2-da_expd.
          wa_final_bar-gas2   = wa_manual_gas2-da_expd.

          wa_final_bar-total3 = wa_manual_oil3-da_expd + wa_manual_gas3-da_expd.
          wa_final_bar-oil3   = wa_manual_oil3-da_expd.
          wa_final_bar-gas3   = wa_manual_gas3-da_expd.

          wa_final_bar-total4 = wa_manual_oil4-da_expd + wa_manual_gas4-da_expd.
          wa_final_bar-oil4   = wa_manual_oil4-da_expd.
          wa_final_bar-gas4   = wa_manual_gas4-da_expd.


        WHEN 26."CHANGE IN INVENTORIES
          CONCATENATE '(V)' wa_final_bar-per INTO wa_final_bar-per.

          wa_final_bar-total1  =  inv_ong1 = wa_manual_oil1-oechin1 + wa_manual_gas1-oechin1.
          wa_final_bar-oil1   =  inv_oil1 = wa_manual_oil1-oechin1.
          wa_final_bar-gas1   =  inv_gas1 = wa_manual_gas1-oechin1.

          wa_final_bar-total2   =  inv_ong2 = wa_manual_oil2-oechin1 + wa_manual_gas2-oechin1.
          wa_final_bar-oil2  =  inv_oil2  = wa_manual_oil2-oechin1.
          wa_final_bar-gas2  =  inv_gas2  = wa_manual_gas2-oechin1.

          wa_final_bar-total3   =  inv_ong3 = wa_manual_oil3-oechin1 + wa_manual_gas3-oechin1.
          wa_final_bar-oil3   =  inv_oil3  = wa_manual_oil3-oechin1.
          wa_final_bar-gas3    =  inv_gas3 = wa_manual_gas3-oechin1.

          wa_final_bar-total4  =  inv_ong4 = wa_manual_oil4-oechin1 + wa_manual_gas4-oechin1.
          wa_final_bar-oil4   =  inv_oil4  = wa_manual_oil4-oechin1.
          wa_final_bar-gas4   =  inv_gas4  = wa_manual_gas4-oechin1.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING  per total1 total2 total3 total4"TOTAL1 OIL1 GAS1."TOTAL2 TOTAL3.
                                                                  oil1   oil2   oil3   oil4
                                                                  gas1   gas2   gas3   gas4.
        WHEN 27."OVERLIFT/(UNDERLIFT)
          CONCATENATE '(VI)' wa_final_bar-per INTO wa_final_bar-per.

          wa_final_bar-total1 = ovr_ong1 = wa_manual_oil1-oe_ovun + wa_manual_gas1-oe_ovun.
          wa_final_bar-oil1  = ovr_oil1 = wa_manual_oil1-oe_ovun.
          wa_final_bar-gas1  = ovr_gas1 = wa_manual_gas1-oe_ovun.

          wa_final_bar-total2 = ovr_ong2 = wa_manual_oil2-oe_ovun + wa_manual_gas2-oe_ovun.
          wa_final_bar-oil2   = ovr_oil2 = wa_manual_oil2-oe_ovun.
          wa_final_bar-gas2  = ovr_gas2  = wa_manual_gas2-oe_ovun.

          wa_final_bar-total3 = ovr_ong3  = wa_manual_oil3-oe_ovun + wa_manual_gas3-oe_ovun.
          wa_final_bar-oil3  = ovr_oil3  = wa_manual_oil3-oe_ovun.
          wa_final_bar-gas3 = ovr_gas3  = wa_manual_gas3-oe_ovun.

          wa_final_bar-total4 = ovr_ong4 = wa_manual_oil4-oe_ovun + wa_manual_gas4-oe_ovun.
          wa_final_bar-oil4  = ovr_oil4  = wa_manual_oil4-oe_ovun.
          wa_final_bar-gas4  = ovr_gas4 = wa_manual_gas4-oe_ovun.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING  per total1 total2 total3 total4"TOTAL1 OIL1 GAS1."TOTAL2 TOTAL3.
                                                                  oil1   oil2   oil3   oil4
                                                                  gas1   gas2   gas3   gas4.
        WHEN 33."Other Income
          wa_final_bar-total1 = wa_manual_oil1-oth_oth + wa_manual_gas1-oth_oth.
          wa_final_bar-oil1   = wa_manual_oil1-oth_oth.
          wa_final_bar-gas1   = wa_manual_gas1-oth_oth.

          wa_final_bar-total2 = wa_manual_oil2-oth_oth + wa_manual_gas2-oth_oth.
          wa_final_bar-oil2   = wa_manual_oil2-oth_oth.
          wa_final_bar-gas2   = wa_manual_gas2-oth_oth.

          wa_final_bar-total3 = wa_manual_oil3-oth_oth + wa_manual_gas3-oth_oth.
          wa_final_bar-oil3   = wa_manual_oil3-oth_oth.
          wa_final_bar-gas3   = wa_manual_gas3-oth_oth.

          wa_final_bar-total4 = wa_manual_oil4-oth_oth + wa_manual_gas4-oth_oth.
          wa_final_bar-oil4   = wa_manual_oil4-oth_oth.
          wa_final_bar-gas4   = wa_manual_gas4-oth_oth.


        WHEN 34."Finance Cost
          wa_final_bar-total1 = wa_manual_oil1-oth_fin + wa_manual_gas1-oth_fin.
          wa_final_bar-oil1   = wa_manual_oil1-oth_fin.
          wa_final_bar-gas1   = wa_manual_gas1-oth_fin.

          wa_final_bar-total2 = wa_manual_oil2-oth_fin + wa_manual_gas2-oth_fin.
          wa_final_bar-oil2   = wa_manual_oil2-oth_fin.
          wa_final_bar-gas2   = wa_manual_gas2-oth_fin.

          wa_final_bar-total3 = wa_manual_oil3-oth_fin + wa_manual_gas3-oth_fin.
          wa_final_bar-oil3   = wa_manual_oil3-oth_fin.
          wa_final_bar-gas3   = wa_manual_gas3-oth_fin.

          wa_final_bar-total4 = wa_manual_oil4-oth_fin + wa_manual_gas4-oth_fin.
          wa_final_bar-oil4   = wa_manual_oil4-oth_fin.
          wa_final_bar-gas4   = wa_manual_gas4-oth_fin.


        WHEN 35."Provisions, Write off and Other Impairment
          wa_final_bar-total1 = wa_manual_oil1-oth_prv + wa_manual_gas1-oth_prv.
          wa_final_bar-oil1   = wa_manual_oil1-oth_prv.
          wa_final_bar-gas1   = wa_manual_gas1-oth_prv.

          wa_final_bar-total2 = wa_manual_oil2-oth_prv + wa_manual_gas2-oth_prv.
          wa_final_bar-oil2   = wa_manual_oil2-oth_prv.
          wa_final_bar-gas2   = wa_manual_gas2-oth_prv.

          wa_final_bar-total3 = wa_manual_oil3-oth_prv + wa_manual_gas3-oth_prv.
          wa_final_bar-oil3   = wa_manual_oil3-oth_prv.
          wa_final_bar-gas3   = wa_manual_gas3-oth_prv.

          wa_final_bar-total4 = wa_manual_oil4-oth_prv + wa_manual_gas4-oth_prv.
          wa_final_bar-oil4   = wa_manual_oil4-oth_prv.
          wa_final_bar-gas4   = wa_manual_gas4-oth_prv.


        WHEN 36."Other Expenses (incl. exchange fluctuation)
          wa_final_bar-total1 = wa_manual_oil1-oth_exp + wa_manual_gas1-oth_exp.
          wa_final_bar-oil1   = wa_manual_oil1-oth_exp.
          wa_final_bar-gas1   = wa_manual_gas1-oth_exp.

          wa_final_bar-total2 = wa_manual_oil2-oth_exp + wa_manual_gas2-oth_exp.
          wa_final_bar-oil2   = wa_manual_oil2-oth_exp.
          wa_final_bar-gas2   = wa_manual_gas2-oth_exp.

          wa_final_bar-total3 = wa_manual_oil3-oth_exp + wa_manual_gas3-oth_exp.
          wa_final_bar-oil3   = wa_manual_oil3-oth_exp.
          wa_final_bar-gas3   = wa_manual_gas3-oth_exp.

          wa_final_bar-total4 = wa_manual_oil4-oth_exp + wa_manual_gas4-oth_exp.
          wa_final_bar-oil4   = wa_manual_oil4-oth_exp.
          wa_final_bar-gas4   = wa_manual_gas4-oth_exp.


        WHEN 41."INCOME TAX
          wa_final_bar-total1 = wa_manual_oil1-inc_tax + wa_manual_gas1-inc_tax.
          wa_final_bar-oil1   = wa_manual_oil1-inc_tax.
          wa_final_bar-gas1   = wa_manual_gas1-inc_tax.

          wa_final_bar-total2 = wa_manual_oil2-inc_tax + wa_manual_gas2-inc_tax.
          wa_final_bar-oil2   = wa_manual_oil2-inc_tax.
          wa_final_bar-gas2   = wa_manual_gas2-inc_tax.

          wa_final_bar-total3 = wa_manual_oil3-inc_tax + wa_manual_gas3-inc_tax.
          wa_final_bar-oil3   = wa_manual_oil3-inc_tax.
          wa_final_bar-gas3   = wa_manual_gas3-inc_tax.

          wa_final_bar-total4 = wa_manual_oil4-inc_tax + wa_manual_gas4-inc_tax.
          wa_final_bar-oil4   = wa_manual_oil4-inc_tax.
          wa_final_bar-gas4   = wa_manual_gas4-inc_tax.


        WHEN 45."Impairment loss/(reversal)
          wa_final_bar-total1 = wa_manual_oil1-imploss + wa_manual_gas1-imploss.
          wa_final_bar-oil1   = wa_manual_oil1-imploss.
          wa_final_bar-gas1   = wa_manual_gas1-imploss.

          wa_final_bar-total2 = wa_manual_oil2-imploss + wa_manual_gas2-imploss.
          wa_final_bar-oil2   = wa_manual_oil2-imploss.
          wa_final_bar-gas2   = wa_manual_gas2-imploss.

          wa_final_bar-total3 = wa_manual_oil3-imploss + wa_manual_gas3-imploss.
          wa_final_bar-oil3   = wa_manual_oil3-imploss.
          wa_final_bar-gas3   = wa_manual_gas3-imploss.

          wa_final_bar-total4 = wa_manual_oil4-imploss + wa_manual_gas4-imploss.
          wa_final_bar-oil4   = wa_manual_oil4-imploss.
          wa_final_bar-gas4   = wa_manual_gas4-imploss.

      ENDCASE.

      MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4"TOTAL1 OIL1 GAS1."TOTAL2 TOTAL3.
                                                         oil1   oil2   oil3   oil4
                                                         gas1   gas2   gas3   gas4.
      CLEAR wa_final_bar.
    ENDLOOP.
  ENDIF.

*************Fetching Qunat Values for allocation(in case of auto calcuated values)

  DATA lv_msg2 TYPE string.

  DATA : lv_sh_lift1 TYPE zpnl_qi_oil-sh_lift, "for per bbl only
         lv_sh_lift2 TYPE zpnl_qi_oil-sh_lift.

  REFRESH : it_assoct_oil[], it_assoct_gas[], it_assoct_cnv[].
  SELECT fisyear zperiod sh_prod sh_lift tot_sal FROM zpnl_qi_oil INTO TABLE it_assoct_oil WHERE company = p_compy1
*   SELECT * FROM ZPNL_QI_OIL INTO TABLE IT_ASSOCT_OIL WHERE COMPANY = P_COMPY1
                                                              AND bukrs = p_comp1
                                                              AND pro_nam IN p_proj1
                                                              AND fisyear IN ( p_year1,p_year2,p_year3,p_year4 ).

  SELECT fisyear zperiod sh_prod sh_lift tot_sal FROM zpnl_qi_gas INTO TABLE it_assoct_gas WHERE company = p_compy1
*   SELECT * FROM ZPNL_QI_GAS INTO TABLE IT_ASSOCT_GAS WHERE COMPANY = P_COMPY1
                                                              AND bukrs = p_comp1
                                                              AND pro_nam IN p_proj1
                                                              AND fisyear IN ( p_year1,p_year2,p_year3,p_year4 ).

  SELECT * FROM zpnl_qi_convo INTO TABLE it_assoct_cnv WHERE company = p_compy1
                                                              AND bukrs = p_comp1
                                                              AND pro_nam IN p_proj1
                                                              AND fisyear IN ( p_year1,p_year2,p_year3,p_year4 ).

  IF peri1_2 EQ s_period-low AND s_period-low IS NOT INITIAL.
    READ TABLE it_assoct_oil INTO wa_assoct_oil1 WITH KEY fisyear = p_year1 zperiod = s_period-low.
    READ TABLE it_assoct_gas INTO wa_assoct_gas1 WITH KEY fisyear = p_year1 zperiod = s_period-low.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv1) WITH KEY fisyear = p_year1 zperiod = s_period-low.

    wa_assoct_oil1-sh_lift = ( wa_assoct_oil1-tot_sal - wa_assoct_oil1-sh_lift ) * wa_assoct_cnv1-bbl_mmbbl. "for Per BBL only

    wa_assoct_oil1-sh_prod = wa_assoct_oil1-sh_prod * wa_assoct_cnv1-bbl_mmbbl.
    wa_assoct_oil1-tot_sal = wa_assoct_oil1-tot_sal * wa_assoct_cnv1-bbl_mmbbl.

    wa_assoct_gas1-sh_prod = wa_assoct_gas1-sh_prod * wa_assoct_cnv1-mmscm_mmboe.
    wa_assoct_gas1-tot_sal = wa_assoct_gas1-tot_sal * wa_assoct_cnv1-mmscm_mmboe.

  ELSEIF s_period-low IS NOT INITIAL.
    READ TABLE it_assoct_cnv INTO wa_assoct_cnv1 WITH KEY fisyear = p_year1 zperiod = peri1_2.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

    READ TABLE it_assoct_oil INTO wa_assoct_oil1 WITH KEY fisyear = p_year1 zperiod = peri1_2.
    READ TABLE it_assoct_oil INTO DATA(wa_assoct_oil1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

    IF wa_assoct_oil1 IS NOT INITIAL.

      CLEAR : lv_sh_lift1,lv_sh_lift2.
      lv_sh_lift1 = ( wa_assoct_oil1-tot_sal - wa_assoct_oil1-sh_lift ) * wa_assoct_cnv1-bbl_mmbbl. "for Per BBL only
      lv_sh_lift2 = ( wa_assoct_oil1_1-tot_sal - wa_assoct_oil1_1-sh_lift ) * wa_assoct_cnv1_1-bbl_mmbbl. "for Per BBL only
      wa_assoct_oil1-sh_lift = lv_sh_lift1 - lv_sh_lift2. "for Per BBL only

      wa_assoct_oil1-sh_prod = ( wa_assoct_oil1-sh_prod * wa_assoct_cnv1-bbl_mmbbl ) - ( wa_assoct_oil1_1-sh_prod * wa_assoct_cnv1_1-bbl_mmbbl ).
      wa_assoct_oil1-tot_sal = ( wa_assoct_oil1-tot_sal * wa_assoct_cnv1-bbl_mmbbl ) - ( wa_assoct_oil1_1-tot_sal * wa_assoct_cnv1_1-bbl_mmbbl ).
    ENDIF.

    READ TABLE it_assoct_gas INTO wa_assoct_gas1 WITH KEY fisyear = p_year1 zperiod = peri1_2.
    READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

    IF wa_assoct_gas1 IS NOT INITIAL.
      wa_assoct_gas1-sh_prod = ( wa_assoct_gas1-sh_prod * wa_assoct_cnv1-mmscm_mmboe ) - ( wa_assoct_gas1_1-sh_prod * wa_assoct_cnv1_1-mmscm_mmboe ).
      wa_assoct_gas1-tot_sal = ( wa_assoct_gas1-tot_sal * wa_assoct_cnv1-mmscm_mmboe ) - ( wa_assoct_gas1_1-tot_sal * wa_assoct_cnv1_1-mmscm_mmboe ).
    ENDIF.

  ENDIF.

  IF peri2_2 EQ s_period_low2 AND s_period_low2 IS NOT INITIAL.
    READ TABLE it_assoct_oil INTO wa_assoct_oil2 WITH KEY fisyear = p_year2 zperiod = s_period_low2.
    READ TABLE it_assoct_gas INTO wa_assoct_gas2 WITH KEY fisyear = p_year2 zperiod = s_period_low2.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv2) WITH KEY fisyear = p_year2 zperiod = s_period_low2.

    wa_assoct_oil2-sh_lift = ( wa_assoct_oil2-tot_sal - wa_assoct_oil2-sh_lift ) * wa_assoct_cnv2-bbl_mmbbl. "for Per BBL only

    wa_assoct_oil2-sh_prod = wa_assoct_oil2-sh_prod * wa_assoct_cnv2-bbl_mmbbl.
    wa_assoct_oil2-tot_sal = wa_assoct_oil2-tot_sal * wa_assoct_cnv2-bbl_mmbbl.

    wa_assoct_gas2-sh_prod = wa_assoct_gas2-sh_prod * wa_assoct_cnv2-mmscm_mmboe.
    wa_assoct_gas2-tot_sal = wa_assoct_gas2-tot_sal * wa_assoct_cnv2-mmscm_mmboe.

  ELSEIF s_period_low2 IS NOT INITIAL.
    READ TABLE it_assoct_cnv INTO wa_assoct_cnv2 WITH KEY fisyear = p_year1 zperiod = peri2_2.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv2_1) WITH KEY fisyear = p_year1 zperiod = peri2_1.

    READ TABLE it_assoct_oil INTO wa_assoct_oil2 WITH KEY fisyear = p_year1 zperiod = peri2_2.
    READ TABLE it_assoct_oil INTO DATA(wa_assoct_oil2_1) WITH KEY fisyear = p_year1 zperiod = peri2_1.

    IF wa_assoct_oil2 IS NOT INITIAL.
      CLEAR : lv_sh_lift1,lv_sh_lift2.
      lv_sh_lift1 = ( wa_assoct_oil2-tot_sal - wa_assoct_oil2-sh_lift ) * wa_assoct_cnv2-bbl_mmbbl. "for Per BBL only
      lv_sh_lift2 = ( wa_assoct_oil2_1-tot_sal - wa_assoct_oil2_1-sh_lift ) * wa_assoct_cnv2_1-bbl_mmbbl. "for Per BBL only
      wa_assoct_oil2-sh_lift = lv_sh_lift1 - lv_sh_lift2. "for Per BBL only

      wa_assoct_oil2-sh_prod = ( wa_assoct_oil2-sh_prod * wa_assoct_cnv2-bbl_mmbbl ) - ( wa_assoct_oil2_1-sh_prod * wa_assoct_cnv2_1-bbl_mmbbl ).
      wa_assoct_oil2-tot_sal = ( wa_assoct_oil2-tot_sal * wa_assoct_cnv2-bbl_mmbbl ) - ( wa_assoct_oil2_1-tot_sal * wa_assoct_cnv2_1-bbl_mmbbl ).
    ENDIF.

    READ TABLE it_assoct_gas INTO wa_assoct_gas2 WITH KEY fisyear = p_year1 zperiod = peri2_2.
    READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas2_1) WITH KEY fisyear = p_year1 zperiod = peri2_1.

    IF wa_assoct_gas2 IS NOT INITIAL.
      wa_assoct_gas2-sh_prod = ( wa_assoct_gas2-sh_prod * wa_assoct_cnv2-mmscm_mmboe ) - ( wa_assoct_gas2_1-sh_prod * wa_assoct_cnv2_1-mmscm_mmboe ).
      wa_assoct_gas2-tot_sal = ( wa_assoct_gas2-tot_sal * wa_assoct_cnv2-mmscm_mmboe ) - ( wa_assoct_gas2_1-tot_sal * wa_assoct_cnv2_1-mmscm_mmboe ).
    ENDIF.

  ENDIF.

  IF peri3_2 EQ s_period_low3 AND s_period_low3 IS NOT INITIAL.
    READ TABLE it_assoct_oil INTO wa_assoct_oil3 WITH KEY fisyear = p_year3 zperiod = s_period_low3.
    READ TABLE it_assoct_gas INTO wa_assoct_gas3 WITH KEY fisyear = p_year3 zperiod = s_period_low3.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv3) WITH KEY fisyear = p_year3 zperiod = s_period_low3.

    wa_assoct_oil3-sh_lift = ( wa_assoct_oil3-tot_sal - wa_assoct_oil3-sh_lift ) * wa_assoct_cnv3-bbl_mmbbl. "for Per BBL only

    wa_assoct_oil3-sh_prod = wa_assoct_oil3-sh_prod * wa_assoct_cnv3-bbl_mmbbl.
    wa_assoct_oil3-tot_sal = wa_assoct_oil3-tot_sal * wa_assoct_cnv3-bbl_mmbbl.

    wa_assoct_gas3-sh_prod = wa_assoct_gas3-sh_prod * wa_assoct_cnv3-mmscm_mmboe.
    wa_assoct_gas3-tot_sal = wa_assoct_gas3-tot_sal * wa_assoct_cnv3-mmscm_mmboe.

  ELSEIF s_period_low3 IS NOT INITIAL.
    READ TABLE it_assoct_cnv INTO wa_assoct_cnv3 WITH KEY fisyear = p_year3 zperiod = peri3_2.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv3_1) WITH KEY fisyear = p_year3 zperiod = peri3_1.

    READ TABLE it_assoct_oil INTO wa_assoct_oil3 WITH KEY fisyear = p_year3 zperiod = peri3_2.
    READ TABLE it_assoct_oil INTO DATA(wa_assoct_oil3_1) WITH KEY fisyear = p_year3 zperiod = peri3_1.

    IF wa_assoct_oil3 IS NOT INITIAL.
      CLEAR : lv_sh_lift1,lv_sh_lift2.
      lv_sh_lift1 = ( wa_assoct_oil3-tot_sal - wa_assoct_oil3-sh_lift ) * wa_assoct_cnv3-bbl_mmbbl. "for Per BBL only
      lv_sh_lift2 = ( wa_assoct_oil3_1-tot_sal - wa_assoct_oil3_1-sh_lift ) * wa_assoct_cnv3_1-bbl_mmbbl. "for Per BBL only
      wa_assoct_oil3-sh_lift = lv_sh_lift1 - lv_sh_lift2. "for Per BBL only

      wa_assoct_oil3-sh_prod = ( wa_assoct_oil3-sh_prod * wa_assoct_cnv3-bbl_mmbbl ) - ( wa_assoct_oil3_1-sh_prod * wa_assoct_cnv3_1-bbl_mmbbl ).
      wa_assoct_oil3-tot_sal = ( wa_assoct_oil3-tot_sal * wa_assoct_cnv3-bbl_mmbbl ) - ( wa_assoct_oil3_1-tot_sal * wa_assoct_cnv3_1-bbl_mmbbl ).
    ENDIF.

    READ TABLE it_assoct_gas INTO wa_assoct_gas3 WITH KEY fisyear = p_year3 zperiod = peri3_2.
    READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas3_1) WITH KEY fisyear = p_year3 zperiod = peri3_1.

    IF wa_assoct_gas3 IS NOT INITIAL.
      wa_assoct_gas3-sh_prod = ( wa_assoct_gas3-sh_prod * wa_assoct_cnv3-mmscm_mmboe ) - ( wa_assoct_gas3_1-sh_prod * wa_assoct_cnv3_1-mmscm_mmboe ).
      wa_assoct_gas3-tot_sal = ( wa_assoct_gas3-tot_sal * wa_assoct_cnv3-mmscm_mmboe ) - ( wa_assoct_gas3_1-tot_sal * wa_assoct_cnv3_1-mmscm_mmboe ).
    ENDIF.

  ENDIF.

  IF peri4_2 EQ s_period_low4 AND s_period_low4 IS NOT INITIAL.
    READ TABLE it_assoct_oil INTO wa_assoct_oil4 WITH KEY fisyear = p_year4 zperiod = s_period_low4.
    READ TABLE it_assoct_gas INTO wa_assoct_gas4 WITH KEY fisyear = p_year4 zperiod = s_period_low4.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv4) WITH KEY fisyear = p_year4 zperiod = s_period_low4.

    wa_assoct_oil4-sh_lift = ( wa_assoct_oil4-tot_sal - wa_assoct_oil4-sh_lift ) * wa_assoct_cnv4-bbl_mmbbl. "for Per BBL only

    wa_assoct_oil4-sh_prod = wa_assoct_oil4-sh_prod * wa_assoct_cnv4-bbl_mmbbl.
    wa_assoct_oil4-tot_sal = wa_assoct_oil4-tot_sal * wa_assoct_cnv4-bbl_mmbbl.

    wa_assoct_gas4-sh_prod = wa_assoct_gas4-sh_prod * wa_assoct_cnv4-mmscm_mmboe.
    wa_assoct_gas4-tot_sal = wa_assoct_gas4-tot_sal * wa_assoct_cnv4-mmscm_mmboe.

  ELSEIF s_period_low4 IS NOT INITIAL.
    READ TABLE it_assoct_cnv INTO wa_assoct_cnv4 WITH KEY fisyear = p_year4 zperiod = peri4_2.
    READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv4_1) WITH KEY fisyear = p_year4 zperiod = peri4_1.

    READ TABLE it_assoct_oil INTO wa_assoct_oil4 WITH KEY fisyear = p_year4 zperiod = peri4_2.
    READ TABLE it_assoct_oil INTO DATA(wa_assoct_oil4_1) WITH KEY fisyear = p_year4 zperiod = peri4_1.

    IF wa_assoct_oil4 IS NOT INITIAL.
      CLEAR : lv_sh_lift1,lv_sh_lift2.
      lv_sh_lift1 = ( wa_assoct_oil4-tot_sal - wa_assoct_oil4-sh_lift ) * wa_assoct_cnv4-bbl_mmbbl. "for Per BBL only
      lv_sh_lift2 = ( wa_assoct_oil4_1-tot_sal - wa_assoct_oil4_1-sh_lift ) * wa_assoct_cnv4_1-bbl_mmbbl. "for Per BBL only
      wa_assoct_oil4-sh_lift = lv_sh_lift1 - lv_sh_lift2. "for Per BBL only

      wa_assoct_oil4-sh_prod = ( wa_assoct_oil4-sh_prod * wa_assoct_cnv4-bbl_mmbbl ) - ( wa_assoct_oil4_1-sh_prod * wa_assoct_cnv4_1-bbl_mmbbl ).
      wa_assoct_oil4-tot_sal = ( wa_assoct_oil4-tot_sal * wa_assoct_cnv4-bbl_mmbbl ) - ( wa_assoct_oil4_1-tot_sal * wa_assoct_cnv4_1-bbl_mmbbl ).
    ENDIF.

    READ TABLE it_assoct_gas INTO wa_assoct_gas4 WITH KEY fisyear = p_year4 zperiod = peri4_2.
    READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas4_1) WITH KEY fisyear = p_year4 zperiod = peri4_1.

    IF wa_assoct_gas4 IS NOT INITIAL.
      wa_assoct_gas4-sh_prod = ( wa_assoct_gas4-sh_prod * wa_assoct_cnv4-mmscm_mmboe ) - ( wa_assoct_gas4_1-sh_prod * wa_assoct_cnv4_1-mmscm_mmboe ).
      wa_assoct_gas4-tot_sal = ( wa_assoct_gas4-tot_sal * wa_assoct_cnv4-mmscm_mmboe ) - ( wa_assoct_gas4_1-tot_sal * wa_assoct_cnv4_1-mmscm_mmboe ).
    ENDIF.

  ENDIF.


  CLEAR lv_msg2.

  IF assoct NE '3' OR assoct NE '4'.

    IF wa_assoct_oil1 IS INITIAL AND s_period-low IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 1 OIL Year' p_year1 'and Period' s_period-low ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_gas1 IS INITIAL AND s_period-low IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 1 GAS Year' p_year1 'and Period' s_period-low ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_oil2 IS INITIAL AND s_period_low2 IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 2 OIL Year' p_year2 'and Period' s_period_low2 ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_gas2 IS INITIAL AND s_period_low2 IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 2 GAS Year' p_year2 'and Period' s_period_low2 ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_oil3 IS INITIAL AND s_period_low3 IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 3 OIL Year' p_year3 'and Period' s_period_low3 ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_gas3 IS INITIAL AND s_period_low3 IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 3 GAS Year' p_year3 'and Period' s_period_low3 ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_oil4 IS INITIAL AND s_period_low4 IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 4 OIL Year' p_year4 'and Period' s_period_low4 ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.
    IF wa_assoct_gas4 IS INITIAL AND s_period_low4 IS NOT INITIAL.
      CONCATENATE lv_msg2 '[ 4 GAS Year' p_year4 'and Period' s_period_low4 ']' INTO lv_msg2 SEPARATED BY space.
    ENDIF.

    IF lv_msg2 IS NOT INITIAL.
      CLEAR sy-ucomm.
      CONCATENATE 'No Qunatitative data found for:-' lv_msg2 INTO lv_msg2.
      MESSAGE lv_msg2 TYPE 'W' DISPLAY LIKE 'I'.
    ENDIF.

  ENDIF.

  PERFORM check_alloc_values.  ""Check weather the values are not zero to avoid divide by zero error

  LOOP AT it_final_bar INTO wa_final_bar.

    CASE sy-tabix.

      WHEN 1."Revenue from Crude Oil

*********** code added by sandeep as on 23.01.2024****
        IF manual = 'X'.

          wa_final_bar-total1 = wa_final_bar-total1.
          wa_final_bar-total2 = wa_final_bar-total2.
          wa_final_bar-total3 = wa_final_bar-total3 .
          wa_final_bar-total4 = wa_final_bar-total4 .
          "
*          IF WA_FINAL_BAR-TOTAL1 CA '-'.
*            WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*          ENDIF.
*          IF WA_FINAL_BAR-TOTAL2 CA '-'.
*            WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*          ENDIF.
*          IF WA_FINAL_BAR-TOTAL3 CA '-'.
*            WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*          ENDIF.
*          IF WA_FINAL_BAR-TOTAL4 CA '-'.
*            WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.
*          ENDIF.
        ELSEIF manual NE 'X'.                                              " REVENUE ALWAYS BE IN -VE IN CASE OF NON-MANUAL
          wa_final_bar-total1 = wa_final_bar-total1 * -1.
          wa_final_bar-total2 = wa_final_bar-total2 * -1.
          wa_final_bar-total3 = wa_final_bar-total3 * -1.
          wa_final_bar-total4 = wa_final_bar-total4 * -1.
        ENDIF.
*********** code added by sandeep as on 23.01.2024****

        wa_final_bar-total1 = ( wa_final_bar-total1 - vat_o1 ).
        wa_final_bar-total2 = ( wa_final_bar-total2 - vat_o2 ).
        wa_final_bar-total3 = ( wa_final_bar-total3 - vat_o3 ).
        wa_final_bar-total4 = ( wa_final_bar-total4 - vat_o4 ).

        IF manual NE 'X'.
          wa_final_bar-oil1   = wa_final_bar-total1.
          wa_final_bar-gas1   = 0.

          wa_final_bar-oil2   = wa_final_bar-total2.
          wa_final_bar-gas2   = 0.

          wa_final_bar-oil3   = wa_final_bar-total3.
          wa_final_bar-gas3   = 0.

          wa_final_bar-oil4   = wa_final_bar-total4.
          wa_final_bar-gas4   = 0.

        ENDIF.
        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                           oil1   oil2   oil3   oil4.

        net_slrl_ong1 = net_slrl_ong1 + wa_final_bar-total1 .
        net_slrl_ong2 = net_slrl_ong2 + wa_final_bar-total2 .
        net_slrl_ong3 = net_slrl_ong3 + wa_final_bar-total3 .
        net_slrl_ong4 = net_slrl_ong4 + wa_final_bar-total4 .

        tot_rev_oil1 = net_slrl_oil1 = net_slrl_oil1 + wa_final_bar-total1.
        tot_rev_oil2 = net_slrl_oil2 = net_slrl_oil2 + wa_final_bar-total2.
        tot_rev_oil3 = net_slrl_oil3 = net_slrl_oil3 + wa_final_bar-total3.
        tot_rev_oil4 = net_slrl_oil4 = net_slrl_oil4 + wa_final_bar-total4.

        CLEAR wa_final_bar.


      WHEN 2."Revenue from Natural Gas

*********** code added by sandeep as on 05.02.2024****

        IF manual = 'X'.

          wa_final_bar-total1 = wa_final_bar-total1.
          wa_final_bar-total2 = wa_final_bar-total2.
          wa_final_bar-total3 = wa_final_bar-total3 .
          wa_final_bar-total4 = wa_final_bar-total4 .
          "
*          IF WA_FINAL_BAR-TOTAL1 CA '-'.
*            WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*          ENDIF.
*          IF WA_FINAL_BAR-TOTAL2 CA '-'.
*            WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*          ENDIF.
*          IF WA_FINAL_BAR-TOTAL3 CA '-'.
*            WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*          ENDIF.
*          IF WA_FINAL_BAR-TOTAL4 CA '-'.
*            WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.
*          ENDIF.
        ELSEIF manual NE 'X'.                                              " REVENUE ALWAYS BE IN -VE IN CASE OF NON-MANUAL
          wa_final_bar-total1 = wa_final_bar-total1 * -1.
          wa_final_bar-total2 = wa_final_bar-total2 * -1.
          wa_final_bar-total3 = wa_final_bar-total3 * -1.
          wa_final_bar-total4 = wa_final_bar-total4 * -1.
        ENDIF.
*********** code added by sandeep as on 05.02.2024****

*
*        IF WA_FINAL_BAR-TOTAL1 CA '-'.            "prev logic
*          WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*        ENDIF.
*        IF WA_FINAL_BAR-TOTAL2 CA '-'.
*          WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*        ENDIF.
*        IF WA_FINAL_BAR-TOTAL3 CA '-'.
*          WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*        ENDIF.
*        IF WA_FINAL_BAR-TOTAL4 CA '-'.
*          WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.
*        ENDIF.                                                ""end of prev logic


        wa_final_bar-total1 = ( wa_final_bar-total1 -  vat_g1 ).
        wa_final_bar-total2 = ( wa_final_bar-total2 -  vat_g2 ).
        wa_final_bar-total3 = ( wa_final_bar-total3 -  vat_g3 ).
        wa_final_bar-total4 = ( wa_final_bar-total4 -  vat_g4 ).

        IF manual NE 'X'.
          wa_final_bar-oil1   = 0.
          wa_final_bar-gas1   = wa_final_bar-total1.

          wa_final_bar-oil2   = 0.
          wa_final_bar-gas2   = wa_final_bar-total2.

          wa_final_bar-oil3   = 0.
          wa_final_bar-gas3   = wa_final_bar-total3.

          wa_final_bar-oil4   = 0.
          wa_final_bar-gas4   = wa_final_bar-total4.

        ENDIF.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                           gas1   gas2   gas3   gas4.

        net_slrl_ong1 = net_slrl_ong1 + wa_final_bar-total1.
        net_slrl_ong2 = net_slrl_ong2 + wa_final_bar-total2.
        net_slrl_ong3 = net_slrl_ong3 + wa_final_bar-total3.
        net_slrl_ong4 = net_slrl_ong4 + wa_final_bar-total4.

        tot_rev_gas1 = net_slrl_gas1 = net_slrl_gas1 +  wa_final_bar-total1 .
        tot_rev_gas2 = net_slrl_gas2 = net_slrl_gas2 +  wa_final_bar-total2 .
        tot_rev_gas3 = net_slrl_gas3 = net_slrl_gas3 +  wa_final_bar-total3 .
        tot_rev_gas4 = net_slrl_gas4 = net_slrl_gas4 +  wa_final_bar-total4 .

        CLEAR wa_final_bar.


      WHEN 3."Less: Profit Oil paid in cash
        CONCATENATE 'LESS:' wa_final_bar-per INTO wa_final_bar-per.

        IF wa_final_bar-total1 CA '-'.
          wa_final_bar-total1 = wa_final_bar-total1 * -1.
        ENDIF.
        IF wa_final_bar-total2 CA '-'.
          wa_final_bar-total2 = wa_final_bar-total2 * -1.
        ENDIF.
        IF wa_final_bar-total3 CA '-'.
          wa_final_bar-total3 = wa_final_bar-total3 * -1.
        ENDIF.
        IF wa_final_bar-total4 CA '-'.
          wa_final_bar-total4 = wa_final_bar-total4 * -1.
        ENDIF.

        net_slrl_ong1 = net_slrl_ong1 - wa_final_bar-total1 .
        net_slrl_ong2 = net_slrl_ong2 - wa_final_bar-total2 .
        net_slrl_ong3 = net_slrl_ong3 - wa_final_bar-total3 .
        net_slrl_ong4 = net_slrl_ong4 - wa_final_bar-total4 .

*        WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*        WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*        WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*        WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.

        IF manual NE 'X'.
          wa_final_bar-oil1   = wa_final_bar-total1.
          wa_final_bar-gas1   = 0.

          wa_final_bar-oil2   = wa_final_bar-total2.
          wa_final_bar-gas2   = 0.

          wa_final_bar-oil3   = wa_final_bar-total3.
          wa_final_bar-gas3   = 0.

          wa_final_bar-oil4   = wa_final_bar-total4.
          wa_final_bar-gas4   = 0.

        ENDIF.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING per total1 total2 total3 total4
                                                           oil1   oil2   oil3   oil4
                                                           gas1   gas2   gas3   gas4.

        net_slrl_oil1 = net_slrl_oil1 - wa_final_bar-oil1 .
        net_slrl_oil2 = net_slrl_oil2 - wa_final_bar-oil2 .
        net_slrl_oil3 = net_slrl_oil3 - wa_final_bar-oil3 .
        net_slrl_oil4 = net_slrl_oil4 - wa_final_bar-oil4 .

        net_slrl_gas1 = net_slrl_gas1 - wa_final_bar-gas1 .
        net_slrl_gas2 = net_slrl_gas2 - wa_final_bar-gas2 .
        net_slrl_gas3 = net_slrl_gas3 - wa_final_bar-gas3 .
        net_slrl_gas4 = net_slrl_gas4 - wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 4."Sale of VAP
        IF wa_final_bar-total1 CA '-'.
          wa_final_bar-total1 = wa_final_bar-total1 * -1.
        ENDIF.
        IF wa_final_bar-total2 CA '-'.
          wa_final_bar-total2 = wa_final_bar-total2 * -1.
        ENDIF.
        IF wa_final_bar-total3 CA '-'.
          wa_final_bar-total3 = wa_final_bar-total3 * -1.
        ENDIF.
        IF wa_final_bar-total4 CA '-'.
          wa_final_bar-total4 = wa_final_bar-total4 * -1.
        ENDIF.
*        WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*        WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*        WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*        WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.

        net_slrl_ong1 = net_slrl_ong1 + wa_final_bar-total1 .
        net_slrl_ong2 = net_slrl_ong2 + wa_final_bar-total2 .
        net_slrl_ong3 = net_slrl_ong3 + wa_final_bar-total3 .
        net_slrl_ong4 = net_slrl_ong4 + wa_final_bar-total4 .

        net_slrl_oil1 = net_slrl_oil1 + wa_final_bar-oil1 .
        net_slrl_oil2 = net_slrl_oil2 + wa_final_bar-oil2 .
        net_slrl_oil3 = net_slrl_oil3 + wa_final_bar-oil3 .
        net_slrl_oil4 = net_slrl_oil4 + wa_final_bar-oil4 .

        net_slrl_gas1 = net_slrl_gas1 + wa_final_bar-gas1 .
        net_slrl_gas2 = net_slrl_gas2 + wa_final_bar-gas2 .
        net_slrl_gas3 = net_slrl_gas3 + wa_final_bar-gas3 .
        net_slrl_gas4 = net_slrl_gas4 + wa_final_bar-gas4 .

*        WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*        WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*        WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*        WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4.

        CLEAR wa_final_bar.


      WHEN 5."Other Operating Revenue
        IF wa_final_bar-total1 CA '-'.
          wa_final_bar-total1 = wa_final_bar-total1 * -1.
        ENDIF.
        IF wa_final_bar-total2 CA '-'.
          wa_final_bar-total2 = wa_final_bar-total2 * -1.
        ENDIF.
        IF wa_final_bar-total3 CA '-'.
          wa_final_bar-total3 = wa_final_bar-total3 * -1.
        ENDIF.
        IF wa_final_bar-total4 CA '-'.
          wa_final_bar-total4 = wa_final_bar-total4 * -1.
        ENDIF.

        "VAT on condensate is being reduced from condensate sales revenue (GL 230116)
        wa_final_bar-total1 = wa_final_bar-total1 - vat_c1.
        wa_final_bar-total2 = wa_final_bar-total2 - vat_c2.
        wa_final_bar-total3 = wa_final_bar-total3 - vat_c3.
        wa_final_bar-total4 = wa_final_bar-total4 - vat_c4.

        net_slrl_ong1 = net_slrl_ong1 + wa_final_bar-total1 .
        net_slrl_ong2 = net_slrl_ong2 + wa_final_bar-total2 .
        net_slrl_ong3 = net_slrl_ong3 + wa_final_bar-total3 .
        net_slrl_ong4 = net_slrl_ong4 + wa_final_bar-total4 .

        net_slrl_oil1 = net_slrl_oil1 + wa_final_bar-oil1 .
        net_slrl_oil2 = net_slrl_oil2 + wa_final_bar-oil2 .
        net_slrl_oil3 = net_slrl_oil3 + wa_final_bar-oil3 .
        net_slrl_oil4 = net_slrl_oil4 + wa_final_bar-oil4 .

        net_slrl_gas1 = net_slrl_gas1 + wa_final_bar-gas1 .
        net_slrl_gas2 = net_slrl_gas2 + wa_final_bar-gas2 .
        net_slrl_gas3 = net_slrl_gas3 + wa_final_bar-gas3 .
        net_slrl_gas4 = net_slrl_gas4 + wa_final_bar-gas4 .

*        WA_FINAL_BAR-TOTAL1 = WA_FINAL_BAR-TOTAL1 * -1.
*        WA_FINAL_BAR-TOTAL2 = WA_FINAL_BAR-TOTAL2 * -1.
*        WA_FINAL_BAR-TOTAL3 = WA_FINAL_BAR-TOTAL3 * -1.
*        WA_FINAL_BAR-TOTAL4 = WA_FINAL_BAR-TOTAL4 * -1.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4.
        CLEAR wa_final_bar.


      WHEN 6."Net Sales Realisation(I)
*        IF NET_SLRL_ONG1 CA '-' .
*          NET_SLRL_ONG1 = NET_SLRL_ONG1 * -1.
*        ENDIF.
*        IF NET_SLRL_ONG2 CA '-' .
*          NET_SLRL_ONG2 = NET_SLRL_ONG2 * -1.
*        ENDIF.
*        IF NET_SLRL_ONG3 CA '-' .
*          NET_SLRL_ONG3 = NET_SLRL_ONG3 * -1.
*        ENDIF.
*        IF NET_SLRL_ONG4 CA '-' .
*          NET_SLRL_ONG4 = NET_SLRL_ONG4 * -1.
*        ENDIF.
*        IF NET_SLRL_OIL1 CA '-' .
*          NET_SLRL_OIL1 = NET_SLRL_OIL1 * -1.
*        ENDIF.
*        IF NET_SLRL_OIL2 CA '-' .
*          NET_SLRL_OIL2 = NET_SLRL_OIL2 * -1.
*        ENDIF.
*        IF NET_SLRL_OIL3 CA '-' .
*          NET_SLRL_OIL3 = NET_SLRL_OIL3 * -1.
*        ENDIF.
*        IF NET_SLRL_OIL4 CA '-' .
*          NET_SLRL_OIL4 = NET_SLRL_OIL4 * -1.
*        ENDIF.
*        IF NET_SLRL_GAS1 CA '-' .
*          NET_SLRL_GAS1 = NET_SLRL_GAS1 * -1.
*        ENDIF.
*        IF NET_SLRL_GAS2 CA '-' .
*          NET_SLRL_GAS2 = NET_SLRL_GAS2 * -1.
*        ENDIF.
*        IF NET_SLRL_GAS3 CA '-' .
*          NET_SLRL_GAS3 = NET_SLRL_GAS3 * -1.
*        ENDIF.
*        IF NET_SLRL_GAS4 CA '-' .
*          NET_SLRL_GAS4 = NET_SLRL_GAS4 * -1.
*        ENDIF.

        wa_final_bar-total1 = net_slrl_ong1.
        wa_final_bar-total2 = net_slrl_ong2.
        wa_final_bar-total3 = net_slrl_ong3.
        wa_final_bar-total4 = net_slrl_ong4.

        wa_final_bar-oil1 = net_slrl_oil1.
        wa_final_bar-oil2 = net_slrl_oil2.
        wa_final_bar-oil3 = net_slrl_oil3.
        wa_final_bar-oil4 = net_slrl_oil4.

        wa_final_bar-gas1 = net_slrl_gas1.
        wa_final_bar-gas2 = net_slrl_gas2.
        wa_final_bar-gas3 = net_slrl_gas3.
        wa_final_bar-gas4 = net_slrl_gas4.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                           oil1   oil2   oil3   oil4
                                                           gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.

*      When 8."Operating Expenses:
      WHEN 9."Royalty
        tot_oprx_ong1 = tot_oprx_ong1 + wa_final_bar-total1 .
        tot_oprx_ong2 = tot_oprx_ong2 + wa_final_bar-total2 .
        tot_oprx_ong3 = tot_oprx_ong3 + wa_final_bar-total3 .
        tot_oprx_ong4 = tot_oprx_ong4 + wa_final_bar-total4 .

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_bar-oil1 .
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_bar-oil2 .
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_bar-oil3 .
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_bar-oil4 .

        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_bar-gas1 .
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_bar-gas2 .
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_bar-gas3 .
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_bar-gas4 .

        royalty_ong1 = wa_final_bar-total1 .
        royalty_ong2 = wa_final_bar-total2 .
        royalty_ong3 = wa_final_bar-total3 .
        royalty_ong4 = wa_final_bar-total4 .

        royalty_oil1 = wa_final_bar-oil1 .
        royalty_oil2 = wa_final_bar-oil2 .
        royalty_oil3 = wa_final_bar-oil3 .
        royalty_oil4 = wa_final_bar-oil4 .

        royalty_gas1 = wa_final_bar-gas1 .
        royalty_gas2 = wa_final_bar-gas2 .
        royalty_gas3 = wa_final_bar-gas3 .
        royalty_gas4 = wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 10."Other taxes(as applicable)
*    *******************For Allocation***********************************
        READ TABLE it_final_bar INTO DATA(wa_final_bar2) INDEX 1.
        READ TABLE it_final_bar INTO DATA(wa_final_bar3) INDEX 2.
*
*        IF MANUAL NE 'X'.
*          IF ASSOCT = '3' OR ASSOCT = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate
*            IF WA_FINAL_BAR2 IS NOT INITIAL AND WA_FINAL_BAR3 IS NOT INITIAL.
*
*              IF WA_FINAL_BAR2-TOTAL1 GT WA_FINAL_BAR3-TOTAL1.
*                WA_FINAL_BAR-OIL1 = WA_FINAL_BAR-TOTAL1 .
*              ELSE.
*                WA_FINAL_BAR-GAS1 = WA_FINAL_BAR-TOTAL1 .
*              ENDIF.
*
*              IF WA_FINAL_BAR2-TOTAL2 GT WA_FINAL_BAR3-TOTAL2.
*                WA_FINAL_BAR-OIL2 = WA_FINAL_BAR-TOTAL2 .
*              ELSE.
*                WA_FINAL_BAR-GAS2 = WA_FINAL_BAR-TOTAL2 .
*              ENDIF.
*
*              IF WA_FINAL_BAR2-TOTAL3 GT WA_FINAL_BAR3-TOTAL3.
*                WA_FINAL_BAR-OIL3 = WA_FINAL_BAR-TOTAL3 .
*              ELSE.
*                WA_FINAL_BAR-GAS3 = WA_FINAL_BAR-TOTAL3 .
*              ENDIF.
*
*              IF WA_FINAL_BAR2-TOTAL4 GT WA_FINAL_BAR3-TOTAL4.
*                WA_FINAL_BAR-OIL4 = WA_FINAL_BAR-TOTAL4 .
*              ELSE.
*                WA_FINAL_BAR-GAS4 = WA_FINAL_BAR-TOTAL4 .
*              ENDIF.
*
*            ENDIF.
*
*          ELSEIF ASSOCT = '4'.  "Oil Field with Non-associated Gas
*
*            WA_FINAL_BAR-OIL1   = ( WA_FINAL_BAR-TOTAL1 / ( NET_BTAX_OIL1 + NET_BTAX_GAS1 ) ) * ( NET_BTAX_OIL1 ) .
*            WA_FINAL_BAR-OIL2   = ( WA_FINAL_BAR-TOTAL2 / ( NET_BTAX_OIL2 + NET_BTAX_GAS2 ) ) * ( NET_BTAX_OIL2 ) .
*            WA_FINAL_BAR-OIL3   = ( WA_FINAL_BAR-TOTAL3 / ( NET_BTAX_OIL3 + NET_BTAX_GAS3 ) ) * ( NET_BTAX_OIL3 ) .
*            WA_FINAL_BAR-OIL4   = ( WA_FINAL_BAR-TOTAL4 / ( NET_BTAX_OIL4 + NET_BTAX_GAS4 ) ) * ( NET_BTAX_OIL4 ) .
*
*            WA_FINAL_BAR-OIL1 = ROUND( VAL = WA_FINAL_BAR-OIL1 DEC = '2' ) .
*            WA_FINAL_BAR-OIL2 = ROUND( VAL = WA_FINAL_BAR-OIL2 DEC = '2' ) .
*            WA_FINAL_BAR-OIL3 = ROUND( VAL = WA_FINAL_BAR-OIL3 DEC = '2' ) .
*            WA_FINAL_BAR-OIL4 = ROUND( VAL = WA_FINAL_BAR-OIL4 DEC = '2' ) .
*
*            WA_FINAL_BAR-GAS1   = WA_FINAL_BAR-TOTAL1 - WA_FINAL_BAR-OIL1.
*            WA_FINAL_BAR-GAS2   = WA_FINAL_BAR-TOTAL2 - WA_FINAL_BAR-OIL2.
*            WA_FINAL_BAR-GAS3   = WA_FINAL_BAR-TOTAL3 - WA_FINAL_BAR-OIL3.
*            WA_FINAL_BAR-GAS4   = WA_FINAL_BAR-TOTAL4 - WA_FINAL_BAR-OIL4.
*
*          ELSEIF ASSOCT = '1'.
*
*            WA_FINAL_BAR-OIL1 = WA_FINAL_BAR-TOTAL1.
*            WA_FINAL_BAR-OIL2 = WA_FINAL_BAR-TOTAL2.
*            WA_FINAL_BAR-OIL3 = WA_FINAL_BAR-TOTAL3.
*            WA_FINAL_BAR-OIL4 = WA_FINAL_BAR-TOTAL4.
*
*          ELSEIF ASSOCT = '2'.
*
*            WA_FINAL_BAR-GAS1 = WA_FINAL_BAR-TOTAL1.
*            WA_FINAL_BAR-GAS2 = WA_FINAL_BAR-TOTAL2.
*            WA_FINAL_BAR-GAS3 = WA_FINAL_BAR-TOTAL3.
*            WA_FINAL_BAR-GAS4 = WA_FINAL_BAR-TOTAL4.
*
*          ENDIF.
*
*          MODIFY IT_FINAL_BAR FROM WA_FINAL_BAR TRANSPORTING TOTAL1 TOTAL2 TOTAL3 TOTAL4
*                                                            OIL1   OIL2   OIL3   OIL4
*                                                            GAS1   GAS2   GAS3   GAS4.
*        ENDIF.
*
*        TOT_OPRX_ONG1 = TOT_OPRX_ONG1 + WA_FINAL_BAR-TOTAL1 .
*        TOT_OPRX_ONG2 = TOT_OPRX_ONG2 + WA_FINAL_BAR-TOTAL2 .
*        TOT_OPRX_ONG3 = TOT_OPRX_ONG3 + WA_FINAL_BAR-TOTAL3 .
*        TOT_OPRX_ONG4 = TOT_OPRX_ONG4 + WA_FINAL_BAR-TOTAL4 .
*
*        TOT_OPRX_OIL1 = TOT_OPRX_OIL1 + WA_FINAL_BAR-OIL1 .
*        TOT_OPRX_OIL2 = TOT_OPRX_OIL2 + WA_FINAL_BAR-OIL2 .
*        TOT_OPRX_OIL3 = TOT_OPRX_OIL3 + WA_FINAL_BAR-OIL3 .
*        TOT_OPRX_OIL4 = TOT_OPRX_OIL4 + WA_FINAL_BAR-OIL4 .
*
*        TOT_OPRX_GAS1 = TOT_OPRX_GAS1 + WA_FINAL_BAR-GAS1 .
*        TOT_OPRX_GAS2 = TOT_OPRX_GAS2 + WA_FINAL_BAR-GAS2 .
*        TOT_OPRX_GAS3 = TOT_OPRX_GAS3 + WA_FINAL_BAR-GAS3 .
*        TOT_OPRX_GAS4 = TOT_OPRX_GAS4 + WA_FINAL_BAR-GAS4 .
*
*        OTH_TAX_ONG1 = WA_FINAL_BAR-TOTAL1 .
*        OTH_TAX_ONG2 = WA_FINAL_BAR-TOTAL2 .
*        OTH_TAX_ONG3 = WA_FINAL_BAR-TOTAL3 .
*        OTH_TAX_ONG4 = WA_FINAL_BAR-TOTAL4 .
*
*        OTH_TAX_OIL1 =  WA_FINAL_BAR-OIL1.
*        OTH_TAX_OIL2 =  WA_FINAL_BAR-OIL2.
*        OTH_TAX_OIL3 =  WA_FINAL_BAR-OIL3.
*        OTH_TAX_OIL4 =  WA_FINAL_BAR-OIL4.
*
*        OTH_TAX_GAS1 =  WA_FINAL_BAR-GAS1.
*        OTH_TAX_GAS2 =  WA_FINAL_BAR-GAS2.
*        OTH_TAX_GAS3 =  WA_FINAL_BAR-GAS3.
*        OTH_TAX_GAS4 =  WA_FINAL_BAR-GAS4.



********* code added by sandeep r as on 18.01.2024**************


        IF manual NE 'X'.
*---------------------------" Changes begins by Aparna on 16.07.2024 "--------------------------------*
*          IF assoct = '3' OR assoct = '5'.
          IF assoct = '3' OR assoct = '5' OR assoct = '1' OR assoct = '2' OR assoct = '4'.
*---------------------------" Changes ended by Aparna on 16.07.2024 "---------------------------------*
            CLEAR wa_final_bar. "Oil Field with Associated Gas OR Gas Field with Condensate
            wa_final_bar-oil1 = oth_tax_ong1.
            wa_final_bar-oil2 = oth_tax_ong2.
            wa_final_bar-oil3 = oth_tax_ong3.
            wa_final_bar-oil4 = oth_tax_ong4.

************* *added by aparna on 11.07.2024
            wa_final_bar-gas1 = oth_tax_gas1.
            wa_final_bar-gas2 = oth_tax_gas2.
            wa_final_bar-gas3 = oth_tax_gas3.
            wa_final_bar-gas4 = oth_tax_gas4.


            wa_final_bar-total1 = wa_final_bar-oil1 + wa_final_bar-gas1.
            wa_final_bar-total2 = wa_final_bar-oil2 + wa_final_bar-gas2.
            wa_final_bar-total3 = wa_final_bar-oil3 + wa_final_bar-gas3.
            wa_final_bar-total4 = wa_final_bar-oil4 + wa_final_bar-gas4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
            CLEAR wa_final_bar.
          ENDIF.

        ENDIF.


* ENDIF.

********* code added by sandeep r as on 18.01.2024**************


      WHEN 11."Production expense
        tot_oprx_ong1 = tot_oprx_ong1 + wa_final_bar-total1 .
        tot_oprx_ong2 = tot_oprx_ong2 + wa_final_bar-total2 .
        tot_oprx_ong3 = tot_oprx_ong3 + wa_final_bar-total3 .
        tot_oprx_ong4 = tot_oprx_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.

          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            wa_final_bar-oil1   = ( tot_rev_oil1 / ( tot_rev_oil1 + tot_rev_gas1 ) ) * ( wa_final_bar-total1 ) .
            wa_final_bar-oil2   = ( tot_rev_oil2 / ( tot_rev_oil2 + tot_rev_gas2 ) ) * ( wa_final_bar-total2 ) .
            wa_final_bar-oil3   = ( tot_rev_oil3 / ( tot_rev_oil3 + tot_rev_gas3 ) ) * ( wa_final_bar-total3 ) .
            wa_final_bar-oil4   = ( tot_rev_oil4 / ( tot_rev_oil4 + tot_rev_gas4 ) ) * ( wa_final_bar-total4 ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '4'. "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-sh_prod + wa_assoct_gas1-sh_prod ) ) * ( wa_assoct_oil1-sh_prod ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-sh_prod + wa_assoct_gas2-sh_prod ) ) * ( wa_assoct_oil2-sh_prod ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-sh_prod + wa_assoct_gas3-sh_prod ) ) * ( wa_assoct_oil3-sh_prod ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-sh_prod + wa_assoct_gas4-sh_prod ) ) * ( wa_assoct_oil4-sh_prod ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                             oil1   oil2   oil3   oil4
                                                             gas1   gas2   gas3   gas4.


        ENDIF.

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_bar-oil1 .
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_bar-oil2 .
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_bar-oil3 .
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_bar-oil4 .

        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_bar-gas1 .
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_bar-gas2 .
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_bar-gas3 .
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 12."Other Operating Expenses
        tot_oprx_ong1 = tot_oprx_ong1 + wa_final_bar-total1 .
        tot_oprx_ong2 = tot_oprx_ong2 + wa_final_bar-total2 .
        tot_oprx_ong3 = tot_oprx_ong3 + wa_final_bar-total3 .
        tot_oprx_ong4 = tot_oprx_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            wa_final_bar-oil1   = ( tot_rev_oil1 / ( tot_rev_oil1 + tot_rev_gas1 ) ) * ( wa_final_bar-total1 ) .
            wa_final_bar-oil2   = ( tot_rev_oil2 / ( tot_rev_oil2 + tot_rev_gas2 ) ) * ( wa_final_bar-total2 ) .
            wa_final_bar-oil3   = ( tot_rev_oil3 / ( tot_rev_oil3 + tot_rev_gas3 ) ) * ( wa_final_bar-total3 ) .
            wa_final_bar-oil4   = ( tot_rev_oil4 / ( tot_rev_oil4 + tot_rev_gas4 ) ) * ( wa_final_bar-total4 ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '4'. "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-sh_prod + wa_assoct_gas1-sh_prod ) ) * ( wa_assoct_oil1-sh_prod ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-sh_prod + wa_assoct_gas2-sh_prod ) ) * ( wa_assoct_oil2-sh_prod ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-sh_prod + wa_assoct_gas3-sh_prod ) ) * ( wa_assoct_oil3-sh_prod ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-sh_prod + wa_assoct_gas4-sh_prod ) ) * ( wa_assoct_oil4-sh_prod ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.
        ENDIF.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                         oil1   oil2   oil3   oil4
                                                         gas1   gas2   gas3   gas4.

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_bar-oil1 .
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_bar-oil2 .
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_bar-oil3 .
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_bar-oil4 .

        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_bar-gas1 .
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_bar-gas2 .
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_bar-gas3 .
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 13."Transportation expense
        tot_oprx_ong1 = tot_oprx_ong1 + wa_final_bar-total1 .
        tot_oprx_ong2 = tot_oprx_ong2 + wa_final_bar-total2 .
        tot_oprx_ong3 = tot_oprx_ong3 + wa_final_bar-total3 .
        tot_oprx_ong4 = tot_oprx_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            IF wa_final_bar2 IS NOT INITIAL AND wa_final_bar3 IS NOT INITIAL.
              IF wa_final_bar2-total1 GT wa_final_bar3-total1.
                wa_final_bar-oil1 = wa_final_bar-total1 .
              ELSE.
                wa_final_bar-gas1 = wa_final_bar-total1 .
              ENDIF.

              IF wa_final_bar2-total2 GT wa_final_bar3-total2.
                wa_final_bar-oil2 = wa_final_bar-total2 .
              ELSE.
                wa_final_bar-gas2 = wa_final_bar-total2 .
              ENDIF.

              IF wa_final_bar2-total3 GT wa_final_bar3-total3.
                wa_final_bar-oil3 = wa_final_bar-total3 .
              ELSE.
                wa_final_bar-gas3 = wa_final_bar-total3 .
              ENDIF.

              IF wa_final_bar2-total4 GT wa_final_bar3-total4.
                wa_final_bar-oil4 = wa_final_bar-total4 .
              ELSE.
                wa_final_bar-gas4 = wa_final_bar-total4 .
              ENDIF.
            ENDIF.

          ELSEIF assoct = '4'. "Oil Field with Non-associated Gas
            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-tot_sal + wa_assoct_gas1-tot_sal ) ) * ( wa_assoct_oil1-tot_sal ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-tot_sal + wa_assoct_gas2-tot_sal ) ) * ( wa_assoct_oil2-tot_sal ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-tot_sal + wa_assoct_gas3-tot_sal ) ) * ( wa_assoct_oil3-tot_sal ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-tot_sal + wa_assoct_gas4-tot_sal ) ) * ( wa_assoct_oil4-tot_sal ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING  oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.

        ENDIF.
*    *********************************************************************************
        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_bar-oil1 .
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_bar-oil2 .
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_bar-oil3 .
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_bar-oil4 .

        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_bar-gas1 .
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_bar-gas2 .
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_bar-gas3 .
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_bar-gas4 .

        CLEAR : wa_final_bar.


      WHEN 14."Internal consumption of Gas
        tot_oprx_ong1 = tot_oprx_ong1 + wa_final_bar-total1 .
        tot_oprx_ong2 = tot_oprx_ong2 + wa_final_bar-total2 .
        tot_oprx_ong3 = tot_oprx_ong3 + wa_final_bar-total3 .
        tot_oprx_ong4 = tot_oprx_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          wa_final_bar-oil1   = wa_final_bar-total1.
          wa_final_bar-gas1   = 0.

          wa_final_bar-oil2   = wa_final_bar-total2.
          wa_final_bar-gas2   = 0.

          wa_final_bar-oil3   = wa_final_bar-total3.
          wa_final_bar-gas3   = 0.

          wa_final_bar-oil4   = wa_final_bar-total4.
          wa_final_bar-gas4   = 0.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                             oil1   oil2   oil3   oil4
                                                             gas1   gas2   gas3   gas4.
        ENDIF.

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_bar-oil1 .
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_bar-oil2 .
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_bar-oil3 .
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_bar-oil4 .

        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_bar-gas1 .
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_bar-gas2 .
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_bar-gas3 .
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 15."Total Operating Expenses(II)

        READ TABLE it_final_bar INTO DATA(ls_final_bar) INDEX 10.    "" ADDN BY SANDEEP AS ON 08.02.2024 TO ADD OTHER TAXES VALUE

        wa_final_bar-total1 = tot_oprx_ongm1 =  tot_oprx_ong1 + ls_final_bar-total1 .
        wa_final_bar-total2  = tot_oprx_ongm2 = tot_oprx_ong2  + ls_final_bar-total2.
        wa_final_bar-total3 = tot_oprx_ongm3 = tot_oprx_ong3 + ls_final_bar-total3 .
        wa_final_bar-total4 = tot_oprx_ongm4 = tot_oprx_ong4 + ls_final_bar-total4 .

        wa_final_bar-oil1  = tot_oprx_oilm1 = tot_oprx_oil1 + ls_final_bar-oil1 .
        wa_final_bar-oil2  = tot_oprx_oilm2 = tot_oprx_oil2 + ls_final_bar-oil2 .
        wa_final_bar-oil3 = tot_oprx_oilm3 = tot_oprx_oil3 + ls_final_bar-oil3 .
        wa_final_bar-oil4 = tot_oprx_oilm4 = tot_oprx_oil4  + ls_final_bar-oil4.

        wa_final_bar-gas1  = tot_oprx_gasm1 = tot_oprx_gas1 + ls_final_bar-gas1 .
        wa_final_bar-gas2  = tot_oprx_gasm2 = tot_oprx_gas2 + ls_final_bar-gas2 .
        wa_final_bar-gas3  = tot_oprx_gasm3 = tot_oprx_gas3  + ls_final_bar-gas3.
        wa_final_bar-gas4  = tot_oprx_gasm4 = tot_oprx_gas4  + ls_final_bar-gas4.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                           oil1   oil2   oil3   oil4
                                                           gas1   gas2   gas3   gas4.
        CLEAR : wa_final_bar , ls_final_bar.


*      When 17."DDA & Exploration:
      WHEN 18."Depletion
        tot_dda_ong1 = tot_dda_ong1 + wa_final_bar-total1 .
        tot_dda_ong2 = tot_dda_ong2 + wa_final_bar-total2 .
        tot_dda_ong3 = tot_dda_ong3 + wa_final_bar-total3 .
        tot_dda_ong4 = tot_dda_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            wa_final_bar-oil1   = ( tot_rev_oil1 / ( tot_rev_oil1 + tot_rev_gas1 ) ) * ( wa_final_bar-total1 ) .
            wa_final_bar-oil2   = ( tot_rev_oil2 / ( tot_rev_oil2 + tot_rev_gas2 ) ) * ( wa_final_bar-total2 ) .
            wa_final_bar-oil3   = ( tot_rev_oil3 / ( tot_rev_oil3 + tot_rev_gas3 ) ) * ( wa_final_bar-total3 ) .
            wa_final_bar-oil4   = ( tot_rev_oil4 / ( tot_rev_oil4 + tot_rev_gas4 ) ) * ( wa_final_bar-total4 ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '4'. "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-sh_prod + wa_assoct_gas1-sh_prod ) ) * ( wa_assoct_oil1-sh_prod ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-sh_prod + wa_assoct_gas2-sh_prod ) ) * ( wa_assoct_oil2-sh_prod ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-sh_prod + wa_assoct_gas3-sh_prod ) ) * ( wa_assoct_oil3-sh_prod ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-sh_prod + wa_assoct_gas4-sh_prod ) ) * ( wa_assoct_oil4-sh_prod ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                             oil1   oil2   oil3   oil4
                                                             gas1   gas2   gas3   gas4.
        ENDIF.

        tot_dda_oil1 = tot_dda_oil1 + wa_final_bar-oil1 .
        tot_dda_oil2 = tot_dda_oil2 + wa_final_bar-oil2 .
        tot_dda_oil3 = tot_dda_oil3 + wa_final_bar-oil3 .
        tot_dda_oil4 = tot_dda_oil4 + wa_final_bar-oil4 .

        tot_dda_gas1 = tot_dda_gas1 + wa_final_bar-gas1 .
        tot_dda_gas2 = tot_dda_gas2 + wa_final_bar-gas2 .
        tot_dda_gas3 = tot_dda_gas3 + wa_final_bar-gas3 .
        tot_dda_gas4 = tot_dda_gas4 + wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 19."Depreciation and Amortisation
        tot_dda_ong1 = tot_dda_ong1 + wa_final_bar-total1 .
        tot_dda_ong2 = tot_dda_ong2 + wa_final_bar-total2 .
        tot_dda_ong3 = tot_dda_ong3 + wa_final_bar-total3 .
        tot_dda_ong4 = tot_dda_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            wa_final_bar-oil1   = ( tot_rev_oil1 / ( tot_rev_oil1 + tot_rev_gas1 ) ) * ( wa_final_bar-total1 ) .
            wa_final_bar-oil2   = ( tot_rev_oil2 / ( tot_rev_oil2 + tot_rev_gas2 ) ) * ( wa_final_bar-total2 ) .
            wa_final_bar-oil3   = ( tot_rev_oil3 / ( tot_rev_oil3 + tot_rev_gas3 ) ) * ( wa_final_bar-total3 ) .
            wa_final_bar-oil4   = ( tot_rev_oil4 / ( tot_rev_oil4 + tot_rev_gas4 ) ) * ( wa_final_bar-total4 ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '4'. "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-sh_prod + wa_assoct_gas1-sh_prod ) ) * ( wa_assoct_oil1-sh_prod ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-sh_prod + wa_assoct_gas2-sh_prod ) ) * ( wa_assoct_oil2-sh_prod ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-sh_prod + wa_assoct_gas3-sh_prod ) ) * ( wa_assoct_oil3-sh_prod ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-sh_prod + wa_assoct_gas4-sh_prod ) ) * ( wa_assoct_oil4-sh_prod ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                             oil1   oil2   oil3   oil4
                                                             gas1   gas2   gas3   gas4.
        ENDIF.

        tot_dda_oil1 = tot_dda_oil1 + wa_final_bar-oil1 .
        tot_dda_oil2 = tot_dda_oil2 + wa_final_bar-oil2 .
        tot_dda_oil3 = tot_dda_oil3 + wa_final_bar-oil3 .
        tot_dda_oil4 = tot_dda_oil4 + wa_final_bar-oil4 .

        tot_dda_gas1 = tot_dda_gas1 + wa_final_bar-gas1 .
        tot_dda_gas2 = tot_dda_gas2 + wa_final_bar-gas2 .
        tot_dda_gas3 = tot_dda_gas3 + wa_final_bar-gas3 .
        tot_dda_gas4 = tot_dda_gas4 + wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 20."Exploration Costs (Survey)
        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            IF wa_final_bar2 IS NOT INITIAL AND wa_final_bar3 IS NOT INITIAL.
              IF wa_final_bar2-total1 GT wa_final_bar3-total1.
                wa_final_bar-oil1 = wa_final_bar-total1 .
              ELSE.
                wa_final_bar-gas1 = wa_final_bar-total1 .
              ENDIF.

              IF wa_final_bar2-total2 GT wa_final_bar3-total2.
                wa_final_bar-oil2 = wa_final_bar-total2 .
              ELSE.
                wa_final_bar-gas2 = wa_final_bar-total2 .
              ENDIF.

              IF wa_final_bar2-total3 GT wa_final_bar3-total3.
                wa_final_bar-oil3 = wa_final_bar-total3 .
              ELSE.
                wa_final_bar-gas3 = wa_final_bar-total3 .
              ENDIF.

              IF wa_final_bar2-total4 GT wa_final_bar3-total4.
                wa_final_bar-oil4 = wa_final_bar-total4 .
              ELSE.
                wa_final_bar-gas4 = wa_final_bar-total4 .
              ENDIF.
            ENDIF.

          ELSEIF assoct = '4'.  "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-sh_prod + wa_assoct_gas1-sh_prod ) ) * ( wa_assoct_oil1-sh_prod ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-sh_prod + wa_assoct_gas2-sh_prod ) ) * ( wa_assoct_oil2-sh_prod ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-sh_prod + wa_assoct_gas3-sh_prod ) ) * ( wa_assoct_oil3-sh_prod ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-sh_prod + wa_assoct_gas4-sh_prod ) ) * ( wa_assoct_oil4-sh_prod ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING  oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.
        ENDIF.

        tot_dda_ong1 = tot_dda_ong1 + wa_final_bar-total1 .
        tot_dda_ong2 = tot_dda_ong2 + wa_final_bar-total2 .
        tot_dda_ong3 = tot_dda_ong3 + wa_final_bar-total3 .
        tot_dda_ong4 = tot_dda_ong4 + wa_final_bar-total4 .

        tot_dda_oil1 = tot_dda_oil1 + wa_final_bar-oil1 .
        tot_dda_oil2 = tot_dda_oil2 + wa_final_bar-oil2 .
        tot_dda_oil3 = tot_dda_oil3 + wa_final_bar-oil3 .
        tot_dda_oil4 = tot_dda_oil4 + wa_final_bar-oil4 .

        tot_dda_gas1 = tot_dda_gas1 + wa_final_bar-gas1 .
        tot_dda_gas2 = tot_dda_gas2 + wa_final_bar-gas2 .
        tot_dda_gas3 = tot_dda_gas3 + wa_final_bar-gas3 .
        tot_dda_gas4 = tot_dda_gas4 + wa_final_bar-gas4 .


      WHEN 21."EXPLORATION COSTS(DRY WELL)
        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate

            IF wa_final_bar2 IS NOT INITIAL AND wa_final_bar3 IS NOT INITIAL.
              IF wa_final_bar2-total1 GT wa_final_bar3-total1.
                wa_final_bar-oil1 = wa_final_bar-total1 .
              ELSE.
                wa_final_bar-gas1 = wa_final_bar-total1 .
              ENDIF.

              IF wa_final_bar2-total2 GT wa_final_bar3-total2.
                wa_final_bar-oil2 = wa_final_bar-total2 .
              ELSE.
                wa_final_bar-gas2 = wa_final_bar-total2 .
              ENDIF.

              IF wa_final_bar2-total3 GT wa_final_bar3-total3.
                wa_final_bar-oil3 = wa_final_bar-total3 .
              ELSE.
                wa_final_bar-gas3 = wa_final_bar-total3 .
              ENDIF.

              IF wa_final_bar2-total4 GT wa_final_bar3-total4.
                wa_final_bar-oil4 = wa_final_bar-total4 .
              ELSE.
                wa_final_bar-gas4 = wa_final_bar-total4 .
              ENDIF.
            ENDIF.

          ELSEIF assoct = '4'.  "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( wa_assoct_oil1-sh_prod + wa_assoct_gas1-sh_prod ) ) * ( wa_assoct_oil1-sh_prod ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( wa_assoct_oil2-sh_prod + wa_assoct_gas2-sh_prod ) ) * ( wa_assoct_oil2-sh_prod ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( wa_assoct_oil3-sh_prod + wa_assoct_gas3-sh_prod ) ) * ( wa_assoct_oil3-sh_prod ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( wa_assoct_oil4-sh_prod + wa_assoct_gas4-sh_prod ) ) * ( wa_assoct_oil4-sh_prod ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING  oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.
        ENDIF.

        tot_dda_ong1 = tot_dda_ong1 + wa_final_bar-total1 .
        tot_dda_ong2 = tot_dda_ong2 + wa_final_bar-total2 .
        tot_dda_ong3 = tot_dda_ong3 + wa_final_bar-total3 .
        tot_dda_ong4 = tot_dda_ong4 + wa_final_bar-total4 .

        tot_dda_oil1 = tot_dda_oil1 + wa_final_bar-oil1 .
        tot_dda_oil2 = tot_dda_oil2 + wa_final_bar-oil2 .
        tot_dda_oil3 = tot_dda_oil3 + wa_final_bar-oil3 .
        tot_dda_oil4 = tot_dda_oil4 + wa_final_bar-oil4 .

        tot_dda_gas1 = tot_dda_gas1 + wa_final_bar-gas1 .
        tot_dda_gas2 = tot_dda_gas2 + wa_final_bar-gas2 .
        tot_dda_gas3 = tot_dda_gas3 + wa_final_bar-gas3 .
        tot_dda_gas4 = tot_dda_gas4 + wa_final_bar-gas4 .


      WHEN 22."Total DDA & Exploration(III)
        wa_final_bar-total1 = tot_dda_ong1  .
        wa_final_bar-total2 = tot_dda_ong2  .
        wa_final_bar-total3 = tot_dda_ong3  .
        wa_final_bar-total4 = tot_dda_ong4  .

        wa_final_bar-oil1 = tot_dda_oil1  .
        wa_final_bar-oil2 = tot_dda_oil2  .
        wa_final_bar-oil3 = tot_dda_oil3  .
        wa_final_bar-oil4 = tot_dda_oil4  .

        wa_final_bar-gas1 = tot_dda_gas1  .
        wa_final_bar-gas2 = tot_dda_gas2  .
        wa_final_bar-gas3 = tot_dda_gas3  .
        wa_final_bar-gas4 = tot_dda_gas4  .

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.


      WHEN 24."Operating Cost IV  added by aparna 11.07.2024
        god_sld_ong1 = wa_final_bar-total1 = tot_oprx_ong1 + tot_dda_ong1 + oth_tax_ong1.
        god_sld_ong2 = wa_final_bar-total2 = tot_oprx_ong2 + tot_dda_ong2 + oth_tax_ong2.
        god_sld_ong3 = wa_final_bar-total3 = tot_oprx_ong3 + tot_dda_ong3 + oth_tax_ong3.
        god_sld_ong4 = wa_final_bar-total4 = tot_oprx_ong4 + tot_dda_ong4 + oth_tax_ong4.

        god_sld_oil1 = wa_final_bar-oil1 = tot_oprx_oil1 + tot_dda_oil1 + oth_tax_ong1.
        god_sld_oil2 = wa_final_bar-oil2 = tot_oprx_oil2 + tot_dda_oil2 + oth_tax_ong2.
        god_sld_oil3 = wa_final_bar-oil3 = tot_oprx_oil3 + tot_dda_oil3 + oth_tax_ong3.
        god_sld_oil4 = wa_final_bar-oil4 = tot_oprx_oil4 + tot_dda_oil4 + oth_tax_ong4.

        god_sld_gas1 = wa_final_bar-gas1 = tot_oprx_gas1 + tot_dda_gas1 + oth_tax_gas1.
        god_sld_gas2 = wa_final_bar-gas2 = tot_oprx_gas2 + tot_dda_gas2 + oth_tax_gas2.
        god_sld_gas3 = wa_final_bar-gas3 = tot_oprx_gas3 + tot_dda_gas3 + oth_tax_gas3.
        god_sld_gas4 = wa_final_bar-gas4 = tot_oprx_gas4 + tot_dda_gas4 + oth_tax_gas1.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.
*     *ADDED BY APARNA on 23/7/24
        IF manual = 'X'.

          wa_final_bar-total1 = tot_dda_ong1 + tot_oprx_ongm1 .
          wa_final_bar-total2 = tot_dda_ong2 + tot_oprx_ongm2.
          wa_final_bar-total3 = tot_dda_ong3 + tot_oprx_ongm3.
          wa_final_bar-total4 = tot_dda_ong4 + tot_oprx_ongm4.

          wa_final_bar-oil1 =  tot_dda_oil1 + tot_oprx_oilm1.
          wa_final_bar-oil2 =  tot_dda_oil2 + tot_oprx_oilm2.
          wa_final_bar-oil3 =  tot_dda_oil3 + tot_oprx_oilm3.
          wa_final_bar-oil4 = tot_dda_oil4  + tot_oprx_oilm4.

          wa_final_bar-gas1 =  tot_dda_gas1  + tot_oprx_gasm1.
          wa_final_bar-gas2 =  tot_dda_gas2  + tot_oprx_gasm2  .
          wa_final_bar-gas3 =  tot_dda_gas3  + tot_oprx_gasm3.
          wa_final_bar-gas4 =  tot_dda_gas4  + tot_oprx_gasm4.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                              oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.
          CLEAR wa_final_bar.

        ENDIF.
*        ended by aprana

*      WHEN 25."Adjustment for cost of sales:
      WHEN 26 ."Change in inventories (V)
        CONCATENATE '(V)' wa_final_bar-per INTO wa_final_bar-per.

        god_sld_ong1 = god_sld_ong1 + wa_final_bar-total1.
        god_sld_ong2 = god_sld_ong2 + wa_final_bar-total2.
        god_sld_ong3 = god_sld_ong3 + wa_final_bar-total3.
        god_sld_ong4 = god_sld_ong4 + wa_final_bar-total4.

        IF manual NE 'X'.
          wa_final_bar-oil1   = wa_final_bar-total1.
          wa_final_bar-gas1   = 0.

          wa_final_bar-oil2   = wa_final_bar-total2.
          wa_final_bar-gas2   = 0.

          wa_final_bar-oil3   = wa_final_bar-total3.
          wa_final_bar-gas3   = 0.

          wa_final_bar-oil4   = wa_final_bar-total4.
          wa_final_bar-gas4   = 0.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING per total1 total2 total3 total4
                                                             oil1   oil2   oil3   oil4
                                                             gas1   gas2   gas3   gas4.
        ENDIF.

        god_sld_oil1 = god_sld_oil1 + wa_final_bar-oil1.
        god_sld_oil2 = god_sld_oil2 + wa_final_bar-oil2.
        god_sld_oil3 = god_sld_oil3 + wa_final_bar-oil3.
        god_sld_oil4 = god_sld_oil4 + wa_final_bar-oil4.

        god_sld_gas1 = god_sld_gas1 + wa_final_bar-gas1.
        god_sld_gas2 = god_sld_gas2 + wa_final_bar-gas2.
        god_sld_gas3 = god_sld_gas3 + wa_final_bar-gas3.
        god_sld_gas4 = god_sld_gas4 + wa_final_bar-gas4.

        CLEAR wa_final_bar.


      WHEN 27."Overlift/(Underlift) (VI)
        CONCATENATE '(VI)' wa_final_bar-per INTO wa_final_bar-per.

        god_sld_ong1 = god_sld_ong1 + wa_final_bar-total1.
        god_sld_ong2 = god_sld_ong2 + wa_final_bar-total2.
        god_sld_ong3 = god_sld_ong3 + wa_final_bar-total3.
        god_sld_ong4 = god_sld_ong4 + wa_final_bar-total4.

        IF manual NE 'X'.
          wa_final_bar-oil1   = wa_final_bar-total1.
          wa_final_bar-gas1   = 0.

          wa_final_bar-oil2   = wa_final_bar-total2.
          wa_final_bar-gas2   = 0.

          wa_final_bar-oil3   = wa_final_bar-total3.
          wa_final_bar-gas3   = 0.

          wa_final_bar-oil4   = wa_final_bar-total4.
          wa_final_bar-gas4   = 0.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING per total1 total2 total3 total4
                                                             oil1   oil2   oil3   oil4
                                                             gas1   gas2   gas3   gas4.
        ENDIF.

        god_sld_oil1 = god_sld_oil1 + wa_final_bar-oil1.
        god_sld_oil2 = god_sld_oil2 + wa_final_bar-oil2.
        god_sld_oil3 = god_sld_oil3 + wa_final_bar-oil3.
        god_sld_oil4 = god_sld_oil4 + wa_final_bar-oil4.

        god_sld_gas1 = god_sld_gas1 + wa_final_bar-gas1.
        god_sld_gas2 = god_sld_gas2 + wa_final_bar-gas2.
        god_sld_gas3 = god_sld_gas3 + wa_final_bar-gas3.
        god_sld_gas4 = god_sld_gas4 + wa_final_bar-gas4.

        CLEAR wa_final_bar.


      WHEN 28."Cost of Goods Sold VII(IV+V+VI)
        wa_final_bar-total1 = god_sld_ong1.
        wa_final_bar-total2 = god_sld_ong2.
        wa_final_bar-total3 = god_sld_ong3.
        wa_final_bar-total4 = god_sld_ong4.

        wa_final_bar-oil1 = god_sld_oil1.
        wa_final_bar-oil2 = god_sld_oil2.
        wa_final_bar-oil3 = god_sld_oil3.
        wa_final_bar-oil4 = god_sld_oil4.

        wa_final_bar-gas1 = god_sld_gas1.
        wa_final_bar-gas2 = god_sld_gas2.
        wa_final_bar-gas3 = god_sld_gas3.
        wa_final_bar-gas4 = god_sld_gas4.

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.
* *ADDED BY APARNA on 23/7/24
        IF manual = 'X'.

          wa_final_bar-total1  =  god_sld_ong11 = tot_dda_ong1 + tot_oprx_ongm1  + inv_ong1 + ovr_ong1 .
          wa_final_bar-total2  = god_sld_ong22 = tot_dda_ong2 + tot_oprx_ongm2  + inv_ong2 + ovr_ong2 .
          wa_final_bar-total3  =  god_sld_ong33 = tot_dda_ong3 + tot_oprx_ongm3  + inv_ong3 + ovr_ong3 .
          wa_final_bar-total4  =  god_sld_ong44 = tot_dda_ong4 + tot_oprx_ongm4  + inv_ong4 + ovr_ong4 .

          wa_final_bar-oil1 =  god_sld_oil11 = tot_dda_oil1 + tot_oprx_oilm1 + inv_oil1 + ovr_oil1.
          wa_final_bar-oil2 =  god_sld_oil22 = tot_dda_oil2 + tot_oprx_oilm2 + inv_oil2 + ovr_oil2.
          wa_final_bar-oil3 = god_sld_oil33  = tot_dda_oil3 + tot_oprx_oilm3 + inv_oil3 + ovr_oil3.
          wa_final_bar-oil4 = god_sld_oil44 = tot_dda_oil4  + tot_oprx_oilm4 + inv_oil4 + ovr_oil4.

          wa_final_bar-gas1 =  god_sld_gas11 = tot_dda_gas1  + tot_oprx_gasm1  + inv_gas1 + ovr_gas1.
          wa_final_bar-gas2 =  god_sld_gas22 = tot_dda_gas2  + tot_oprx_gasm2  + inv_gas2 + ovr_gas2.
          wa_final_bar-gas3 =  god_sld_gas33 = tot_dda_gas3  + tot_oprx_gasm3  + inv_gas3 + ovr_gas3.
          wa_final_bar-gas4 =  god_sld_gas44 = tot_dda_gas4  + tot_oprx_gasm4  + inv_gas4 + ovr_gas4.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                              oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.
          CLEAR wa_final_bar.

        ENDIF.
*        ended by aprana

      WHEN 30."Net Operating margin VIII (I-VII)
        wa_final_bar-total1 = net_rev_ong1 = net_slrl_ong1 - god_sld_ong1 .
        wa_final_bar-total2 = net_rev_ong2 = net_slrl_ong2 - god_sld_ong2 .
        wa_final_bar-total3 = net_rev_ong3 = net_slrl_ong3 - god_sld_ong3 .
        wa_final_bar-total4 = net_rev_ong4 = net_slrl_ong4 - god_sld_ong4 .

        wa_final_bar-oil1 = net_rev_oil1 = net_slrl_oil1 - god_sld_oil1 .
        wa_final_bar-oil2 = net_rev_oil2 = net_slrl_oil2 - god_sld_oil2 .
        wa_final_bar-oil3 = net_rev_oil3 = net_slrl_oil3 - god_sld_oil3 .
        wa_final_bar-oil4 = net_rev_oil4 = net_slrl_oil4 - god_sld_oil4 .

        wa_final_bar-gas1 = net_rev_gas1 = net_slrl_gas1 - god_sld_gas1 .
        wa_final_bar-gas2 = net_rev_gas2 = net_slrl_gas2 - god_sld_gas2 .
        wa_final_bar-gas3 = net_rev_gas3 = net_slrl_gas3 - god_sld_gas3 .
        wa_final_bar-gas4 = net_rev_gas4 = net_slrl_gas4 - god_sld_gas4 .

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.

        IF manual = 'X'.
          wa_final_bar-total1 = net_rev_ong1 = net_slrl_ong1 - god_sld_ong11 .
          wa_final_bar-total2 = net_rev_ong2 = net_slrl_ong2 - god_sld_ong22 .
          wa_final_bar-total3 = net_rev_ong3 = net_slrl_ong3 - god_sld_ong33 .
          wa_final_bar-total4 = net_rev_ong4 = net_slrl_ong4 - god_sld_ong44 .

          wa_final_bar-oil1 = net_rev_oil1 = net_slrl_oil1 - god_sld_oil11 .
          wa_final_bar-oil2 = net_rev_oil2 = net_slrl_oil2 - god_sld_oil22 .
          wa_final_bar-oil3 = net_rev_oil3 = net_slrl_oil3 - god_sld_oil33 .
          wa_final_bar-oil4 = net_rev_oil4 = net_slrl_oil4 - god_sld_oil44 .

          wa_final_bar-gas1 = net_rev_gas1 = net_slrl_gas1 - god_sld_gas11 .
          wa_final_bar-gas2 = net_rev_gas2 = net_slrl_gas2 - god_sld_gas22 .
          wa_final_bar-gas3 = net_rev_gas3 = net_slrl_gas3 - god_sld_gas33 .
          wa_final_bar-gas4 = net_rev_gas4 = net_slrl_gas4 - god_sld_gas44 .

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                              oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.
          CLEAR wa_final_bar.
        ENDIF.
*      When 34. "Other Income/ Expense:
      WHEN 33."Other Income
        tot_otin_ong1 = tot_otin_ong1 + wa_final_bar-total1 .
        tot_otin_ong2 = tot_otin_ong2 + wa_final_bar-total2 .
        tot_otin_ong3 = tot_otin_ong3 + wa_final_bar-total3 .
        tot_otin_ong4 = tot_otin_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '1' OR assoct = '3' OR assoct = '4'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil1 oil2 oil3 oil4.

          ELSEIF assoct = '2' OR assoct = '5'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas1 gas2 gas3 gas4.

          ENDIF.
        ENDIF.

        tot_otin_oil1 = tot_otin_oil1 + wa_final_bar-oil1 .
        tot_otin_oil2 = tot_otin_oil2 + wa_final_bar-oil2 .
        tot_otin_oil3 = tot_otin_oil3 + wa_final_bar-oil3 .
        tot_otin_oil4 = tot_otin_oil4 + wa_final_bar-oil4 .

        tot_otin_gas1 = tot_otin_gas1 + wa_final_bar-gas1 .
        tot_otin_gas2 = tot_otin_gas2 + wa_final_bar-gas2 .
        tot_otin_gas3 = tot_otin_gas3 + wa_final_bar-gas3 .
        tot_otin_gas4 = tot_otin_gas4 + wa_final_bar-gas4 .



      WHEN 34."Finance Cost
        tot_otin_ong1 = tot_otin_ong1 + wa_final_bar-total1 .
        tot_otin_ong2 = tot_otin_ong2 + wa_final_bar-total2 .
        tot_otin_ong3 = tot_otin_ong3 + wa_final_bar-total3 .
        tot_otin_ong4 = tot_otin_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '1' OR assoct = '3' OR assoct = '4'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil1 oil2 oil3 oil4.

          ELSEIF assoct = '2' OR assoct = '5'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas1 gas2 gas3 gas4.

          ENDIF.
        ENDIF.

        tot_otin_oil1 = tot_otin_oil1 + wa_final_bar-oil1 .
        tot_otin_oil2 = tot_otin_oil2 + wa_final_bar-oil2 .
        tot_otin_oil3 = tot_otin_oil3 + wa_final_bar-oil3 .
        tot_otin_oil4 = tot_otin_oil4 + wa_final_bar-oil4 .

        tot_otin_gas1 = tot_otin_gas1 + wa_final_bar-gas1 .
        tot_otin_gas2 = tot_otin_gas2 + wa_final_bar-gas2 .
        tot_otin_gas3 = tot_otin_gas3 + wa_final_bar-gas3 .
        tot_otin_gas4 = tot_otin_gas4 + wa_final_bar-gas4 .

      WHEN 35."Provisions, Write off and Other Impairment
        tot_otin_ong1 = tot_otin_ong1 + wa_final_bar-total1 .
        tot_otin_ong2 = tot_otin_ong2 + wa_final_bar-total2 .
        tot_otin_ong3 = tot_otin_ong3 + wa_final_bar-total3 .
        tot_otin_ong4 = tot_otin_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '1' OR assoct = '3' OR assoct = '4'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil1 oil2 oil3 oil4.

          ELSEIF assoct = '2' OR assoct = '5'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas1 gas2 gas3 gas4.

          ENDIF.
        ENDIF.

        tot_otin_oil1 = tot_otin_oil1 + wa_final_bar-oil1 .
        tot_otin_oil2 = tot_otin_oil2 + wa_final_bar-oil2 .
        tot_otin_oil3 = tot_otin_oil3 + wa_final_bar-oil3 .
        tot_otin_oil4 = tot_otin_oil4 + wa_final_bar-oil4 .

        tot_otin_gas1 = tot_otin_gas1 + wa_final_bar-gas1 .
        tot_otin_gas2 = tot_otin_gas2 + wa_final_bar-gas2 .
        tot_otin_gas3 = tot_otin_gas3 + wa_final_bar-gas3 .
        tot_otin_gas4 = tot_otin_gas4 + wa_final_bar-gas4 .

      WHEN 36."Other Expenses (incl. exchange fluctuation)
        tot_otin_ong1 = tot_otin_ong1 + wa_final_bar-total1 .
        tot_otin_ong2 = tot_otin_ong2 + wa_final_bar-total2 .
        tot_otin_ong3 = tot_otin_ong3 + wa_final_bar-total3 .
        tot_otin_ong4 = tot_otin_ong4 + wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '1' OR assoct = '3' OR assoct = '4'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING oil1 oil2 oil3 oil4.

          ELSEIF assoct = '2' OR assoct = '5'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

            MODIFY it_final_bar FROM wa_final_bar TRANSPORTING gas1 gas2 gas3 gas4.

          ENDIF.
        ENDIF.

        tot_otin_oil1 = tot_otin_oil1 + wa_final_bar-oil1 .
        tot_otin_oil2 = tot_otin_oil2 + wa_final_bar-oil2 .
        tot_otin_oil3 = tot_otin_oil3 + wa_final_bar-oil3 .
        tot_otin_oil4 = tot_otin_oil4 + wa_final_bar-oil4 .

        tot_otin_gas1 = tot_otin_gas1 + wa_final_bar-gas1 .
        tot_otin_gas2 = tot_otin_gas2 + wa_final_bar-gas2 .
        tot_otin_gas3 = tot_otin_gas3 + wa_final_bar-gas3 .
        tot_otin_gas4 = tot_otin_gas4 + wa_final_bar-gas4 .

      WHEN 37."Total Other Income/ Expense (X)
        wa_final_bar-total1 = tot_otin_ong1 .
        wa_final_bar-total2 = tot_otin_ong2 .
        wa_final_bar-total3 = tot_otin_ong3 .
        wa_final_bar-total4 = tot_otin_ong4 .

        wa_final_bar-oil1 = tot_otin_oil1 .
        wa_final_bar-oil2 = tot_otin_oil2 .
        wa_final_bar-oil3 = tot_otin_oil3 .
        wa_final_bar-oil4 = tot_otin_oil4 .

        wa_final_bar-gas1 = tot_otin_gas1 .
        wa_final_bar-gas2 = tot_otin_gas2 .
        wa_final_bar-gas3 = tot_otin_gas3 .
        wa_final_bar-gas4 = tot_otin_gas4 .

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.


      WHEN 39."Net Profit Before Tax X (VIII-IX)
        net_btax_ong1 = wa_final_bar-total1 = net_rev_ong1 - tot_otin_ong1 .
        net_btax_ong2 = wa_final_bar-total2 = net_rev_ong2 - tot_otin_ong2 .
        net_btax_ong3 = wa_final_bar-total3 = net_rev_ong3 - tot_otin_ong3 .
        net_btax_ong4 = wa_final_bar-total4 = net_rev_ong4 - tot_otin_ong4 .

        net_btax_oil1 = wa_final_bar-oil1 = net_rev_oil1 - tot_otin_oil1 .
        net_btax_oil2 = wa_final_bar-oil2 = net_rev_oil2 - tot_otin_oil2 .
        net_btax_oil3 = wa_final_bar-oil3 = net_rev_oil3 - tot_otin_oil3 .
        net_btax_oil4 = wa_final_bar-oil4 = net_rev_oil4 - tot_otin_oil4 .

        net_btax_gas1 = wa_final_bar-gas1 = net_rev_gas1 - tot_otin_gas1 .
        net_btax_gas2 = wa_final_bar-gas2 = net_rev_gas2 - tot_otin_gas2 .
        net_btax_gas3 = wa_final_bar-gas3 = net_rev_gas3 - tot_otin_gas3 .
        net_btax_gas4 = wa_final_bar-gas4 = net_rev_gas4 - tot_otin_gas4 .

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.


      WHEN 41."Income Tax (XI)
        IF manual NE 'X'.
          IF assoct = '3' OR assoct = '5'. "Oil Field with Associated Gas OR Gas Field with Condensate
            IF wa_final_bar2 IS NOT INITIAL AND wa_final_bar3 IS NOT INITIAL.

              IF wa_final_bar2-total1 GT wa_final_bar3-total1.
                wa_final_bar-oil1 = wa_final_bar-total1 .
              ELSE.
                wa_final_bar-gas1 = wa_final_bar-total1 .
              ENDIF.

              IF wa_final_bar2-total2 GT wa_final_bar3-total2.
                wa_final_bar-oil2 = wa_final_bar-total2 .
              ELSE.
                wa_final_bar-gas2 = wa_final_bar-total2 .
              ENDIF.

              IF wa_final_bar2-total3 GT wa_final_bar3-total3.
                wa_final_bar-oil3 = wa_final_bar-total3 .
              ELSE.
                wa_final_bar-gas3 = wa_final_bar-total3 .
              ENDIF.

              IF wa_final_bar2-total4 GT wa_final_bar3-total4.
                wa_final_bar-oil4 = wa_final_bar-total4 .
              ELSE.
                wa_final_bar-gas4 = wa_final_bar-total4 .
              ENDIF.

            ENDIF.

          ELSEIF assoct = '4'.  "Oil Field with Non-associated Gas

            wa_final_bar-oil1   = ( wa_final_bar-total1 / ( net_btax_oil1 + net_btax_gas1 ) ) * ( net_btax_oil1 ) .
            wa_final_bar-oil2   = ( wa_final_bar-total2 / ( net_btax_oil2 + net_btax_gas2 ) ) * ( net_btax_oil2 ) .
            wa_final_bar-oil3   = ( wa_final_bar-total3 / ( net_btax_oil3 + net_btax_gas3 ) ) * ( net_btax_oil3 ) .
            wa_final_bar-oil4   = ( wa_final_bar-total4 / ( net_btax_oil4 + net_btax_gas4 ) ) * ( net_btax_oil4 ) .

            wa_final_bar-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
            wa_final_bar-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
            wa_final_bar-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
            wa_final_bar-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

            wa_final_bar-gas1   = wa_final_bar-total1 - wa_final_bar-oil1.
            wa_final_bar-gas2   = wa_final_bar-total2 - wa_final_bar-oil2.
            wa_final_bar-gas3   = wa_final_bar-total3 - wa_final_bar-oil3.
            wa_final_bar-gas4   = wa_final_bar-total4 - wa_final_bar-oil4.

          ELSEIF assoct = '1'.

            wa_final_bar-oil1 = wa_final_bar-total1.
            wa_final_bar-oil2 = wa_final_bar-total2.
            wa_final_bar-oil3 = wa_final_bar-total3.
            wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            wa_final_bar-gas1 = wa_final_bar-total1.
            wa_final_bar-gas2 = wa_final_bar-total2.
            wa_final_bar-gas3 = wa_final_bar-total3.
            wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        ENDIF.

        in_tax_ong1 = wa_final_bar-total1 .
        in_tax_ong2 = wa_final_bar-total2 .
        in_tax_ong3 = wa_final_bar-total3 .
        in_tax_ong4 = wa_final_bar-total4 .

        in_tax_oil1 = wa_final_bar-oil1 .
        in_tax_oil2 = wa_final_bar-oil2 .
        in_tax_oil3 = wa_final_bar-oil3 .
        in_tax_oil4 = wa_final_bar-oil4 .

        in_tax_gas1 = wa_final_bar-gas1 .
        in_tax_gas2 = wa_final_bar-gas2 .
        in_tax_gas3 = wa_final_bar-gas3 .
        in_tax_gas4 = wa_final_bar-gas4 .

        CLEAR wa_final_bar.


      WHEN 43."Net Profit/(Loss) after tax XII (X-XI)
        wa_final_bar-total1 = net_atax_ong1 = net_btax_ong1 - in_tax_ong1  .
        wa_final_bar-total2 = net_atax_ong2 = net_btax_ong2 - in_tax_ong2  .
        wa_final_bar-total3 = net_atax_ong3 = net_btax_ong3 - in_tax_ong3  .
        wa_final_bar-total4 = net_atax_ong4 = net_btax_ong4 - in_tax_ong4  .

        wa_final_bar-oil1 = net_atax_oil1 = net_btax_oil1 - in_tax_oil1  .
        wa_final_bar-oil2 = net_atax_oil2 = net_btax_oil2 - in_tax_oil2  .
        wa_final_bar-oil3 = net_atax_oil3 = net_btax_oil3 - in_tax_oil3  .
        wa_final_bar-oil4 = net_atax_oil4 = net_btax_oil4 - in_tax_oil4  .

        wa_final_bar-gas1 = net_atax_gas1 = net_btax_gas1 - in_tax_gas1  .
        wa_final_bar-gas2 = net_atax_gas2 = net_btax_gas2 - in_tax_gas2  .
        wa_final_bar-gas3 = net_atax_gas3 = net_btax_gas3 - in_tax_gas3  .
        wa_final_bar-gas4 = net_atax_gas4 = net_btax_gas4 - in_tax_gas4  .

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.


      WHEN 45."Impairment loss/(reversal)
        imploss_ong1 = wa_final_bar-total1 .
        imploss_ong2 = wa_final_bar-total2 .
        imploss_ong3 = wa_final_bar-total3 .
        imploss_ong4 = wa_final_bar-total4 .

        IF manual NE 'X'.
          IF assoct = '1'.

            imploss_oil1 = wa_final_bar-oil1 = wa_final_bar-total1.
            imploss_oil2 = wa_final_bar-oil2 = wa_final_bar-total2.
            imploss_oil3 = wa_final_bar-oil3 = wa_final_bar-total3.
            imploss_oil4 = wa_final_bar-oil4 = wa_final_bar-total4.

          ELSEIF assoct = '2'.

            imploss_gas1 = wa_final_bar-gas1 = wa_final_bar-total1.
            imploss_gas2 = wa_final_bar-gas2 = wa_final_bar-total2.
            imploss_gas3 = wa_final_bar-gas3 = wa_final_bar-total3.
            imploss_gas4 = wa_final_bar-gas4 = wa_final_bar-total4.

          ENDIF.

          MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                              oil1   oil2   oil3   oil4
                                                              gas1   gas2   gas3   gas4.
        ENDIF.


      WHEN 47."Net Profit/(Loss) After Tax-before Impairment
        wa_final_bar-total1 = net_atax_ong1 + imploss_ong1 .
        wa_final_bar-total2 = net_atax_ong2 + imploss_ong2 .
        wa_final_bar-total3 = net_atax_ong3 + imploss_ong3 .
        wa_final_bar-total4 = net_atax_ong4 + imploss_ong4 .

        wa_final_bar-oil1 = net_atax_oil1 + imploss_oil1 .
        wa_final_bar-oil2 = net_atax_oil2 + imploss_oil2 .
        wa_final_bar-oil3 = net_atax_oil3 + imploss_oil3 .
        wa_final_bar-oil4 = net_atax_oil4 + imploss_oil4 .

        wa_final_bar-gas1 = net_atax_gas1 + imploss_gas1 .
        wa_final_bar-gas2 = net_atax_gas2 + imploss_gas2 .
        wa_final_bar-gas3 = net_atax_gas3 + imploss_gas3 .
        wa_final_bar-gas4 = net_atax_gas4 + imploss_gas4 .

        MODIFY it_final_bar FROM wa_final_bar TRANSPORTING total1 total2 total3 total4
                                                            oil1   oil2   oil3   oil4
                                                            gas1   gas2   gas3   gas4.
        CLEAR wa_final_bar.

    ENDCASE.

  ENDLOOP.

  CLEAR : wa_final_bar2, wa_final_bar3.

*Rounding off every amount to 2 decimals
  LOOP AT it_final_bar INTO wa_final_bar.

    wa_final_bar1-per = wa_final_bar-per.

    wa_final_bar1-total1 = round( val = wa_final_bar-total1 dec = '2' ) .
    wa_final_bar1-total2 = round( val = wa_final_bar-total2 dec = '2' ) .
    wa_final_bar1-total3 = round( val = wa_final_bar-total3 dec = '2' ) .
    wa_final_bar1-total4 = round( val = wa_final_bar-total4 dec = '2' ) .

    wa_final_bar1-oil1 = round( val = wa_final_bar-oil1 dec = '2' ) .
    wa_final_bar1-oil2 = round( val = wa_final_bar-oil2 dec = '2' ) .
    wa_final_bar1-oil3 = round( val = wa_final_bar-oil3 dec = '2' ) .
    wa_final_bar1-oil4 = round( val = wa_final_bar-oil4 dec = '2' ) .

    wa_final_bar1-gas1 = round( val = wa_final_bar-gas1 dec = '2' ) .
    wa_final_bar1-gas2 = round( val = wa_final_bar-gas2 dec = '2' ) .
    wa_final_bar1-gas3 = round( val = wa_final_bar-gas3 dec = '2' ) .
    wa_final_bar1-gas4 = round( val = wa_final_bar-gas4 dec = '2' ) .

*-------------------" Changes begins by Aparna on 11.02.2023 "----------------------*
*BREAK-POINT.
    SELECT SINGLE *
    FROM   zfi_pl_var_prd
    INTO   @DATA(wa_pl_var_prd)
           WHERE per    = @wa_final_bar1-per
           AND comp = @p_comp1
           AND   period = @s_period-low
      AND period2 = @s_period_low2
      AND fiscal = @p_year1
      AND proj = @p_proj1-low.
    IF sy-subrc = 0.

      wa_final_bar1-remark = wa_pl_var_prd-remark.

    ENDIF.
*-------------------" Changes ended by Aparna on 11.02.2023 "-----------------------*

    APPEND wa_final_bar1 TO it_final_bar1.

    CLEAR: wa_final_bar,wa_final_bar1.

  ENDLOOP.

ENDFORM."CRE_PRD_PROJ.

FORM fcat_fill_prd.
  DATA bar_h TYPE string.

  CLEAR bar_h.
  PERFORM period_text USING s_period-low p_year1.
  bar_h = per_text.

  PERFORM alv_fcat_prd USING :  'SR_NO'     'SR_NO',
                                'PER'       'Particulars',
                                'TOTAL1'     bar_h     ,
                                'OIL1'      'Crude Oil',
                                'GAS1'      'Gas'.

  IF  p_year2 IS NOT INITIAL.
    CLEAR bar_h.
    PERFORM period_text USING s_period_low2 p_year2.
    bar_h = per_text.

    PERFORM alv_fcat_prd USING :  'TOTAL2'     bar_h     ,
                                  'OIL2'      'Crude Oil',
                                  'GAS2'      'Gas'.
  ENDIF.

  IF  p_year3 IS NOT INITIAL.
    CLEAR bar_h.
    PERFORM period_text USING s_period_low3 p_year3.
    bar_h = per_text.

    PERFORM alv_fcat_prd USING :  'TOTAL3'     bar_h     ,
                                  'OIL3'      'Crude Oil',
                                  'GAS3'      'Gas'.
  ENDIF.

  IF  p_year4 IS NOT INITIAL.
    CLEAR bar_h.
    PERFORM period_text USING s_period_low4 p_year4.
    bar_h = per_text.

    PERFORM alv_fcat_prd USING :  'TOTAL4'     bar_h     ,
                                  'OIL4'      'Crude Oil',
                                  'GAS4'      'Gas'.
  ENDIF.


ENDFORM."fcat_fill_PRD

FORM alv_fcat_prd USING VALUE(p_011)
                        VALUE(p_012).

  wa_fcat-fieldname   = p_011.
  wa_fcat-seltext_l   = p_012.
  wa_fcat-no_zero     = 'X'.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

ENDFORM." alv_fcat_PRD

FORM alv_display_prd .

  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.
  CLEAR it_final_bar.
  REFRESH it_final_bar[].

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-cprog
      i_callback_top_of_page = 'TOP_OF_PAGE_BAR'
      is_layout              = wa_layout
      it_fieldcat            = it_fcat
      i_default              = 'X'
      i_save                 = 'U'
    TABLES
      t_outtab               = it_final_bar1
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM." alv_display_prd

FORM top_of_page_bar.

  REFRESH int_header[].
  fs_header-typ = 'H'.
  fs_header-info = 'Profitability Statement for Producing Project'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp
                       WHERE bukrs = p_comp1.

  READ TABLE it_comp INTO DATA(wa_comp) WITH KEY bukrs = p_comp1.
  fs_header-typ = 'S'.
  CONCATENATE 'Company code :- ' wa_comp-bukrs ' - ' wa_comp-txtcc INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE jvnam = p_proj1-low.

  READ TABLE it_proj INTO DATA(wa_proj) WITH KEY jvnam = p_proj1-low.
  fs_header-typ = 'S'.
  CONCATENATE 'Project :- ' wa_proj-jvnam ' - ' wa_proj-txtjv  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  CONCATENATE '(Amount in' 'US$ Mn.)' INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = int_header.

ENDFORM."TOP_OF_PAGE_BAR

FORM map_period USING VALUE(per_low).   "Get periods according to input parameters to pass in database tables
  REFRESH s_peri[].
  CLEAR : s_period_low,s_period_high,s_peri.

  s_peri-sign   = 'I'.
  s_peri-option = 'BT'.

  IF per_low = 'Q1'.
    s_period_low  = '01'.
    s_period_high = '03'.
  ELSEIF per_low = 'Q2'.
    s_period_low  = '04'.
    s_period_high = '06'.
  ELSEIF per_low = 'H1'.
    s_period_low  = '01'.
    s_period_high = '06'.
  ELSEIF per_low = 'Q3'.
    s_period_low  = '07'.
    s_period_high = '09'.
  ELSEIF per_low = '9M'.
    s_period_low  = '01'.
    s_period_high = '09'.
  ELSEIF per_low = 'Q4'.
    s_period_low  = '10'.
    s_period_high = '16'.
  ELSEIF per_low = 'ANNUAL'.
    s_period_low  = '01'.
    s_period_high = '16'.
  ENDIF.

  s_peri-low  = s_period_low.
  s_peri-high = s_period_high.

  APPEND s_peri.

ENDFORM."MAP_PERIOD

FORM clear_on_exit.
  CLEAR : p_company,
          p_comp,
          p_proj,
          p_year,
          s_period_low,
          p_comp1,
          p_year1,
          p_year2,s_period_low2,
          p_year3,s_period_low3,
          p_year4,s_period_low4.
ENDFORM."CLEAR_ON_EXIT

FORM cre_non_prd.      "Create layout for Non-Producing projects

  DATA : tot_inc1(15)   TYPE c,    tot_inc2(15) TYPE c,    tot_inc3(15) TYPE c,     tot_inc4(15) TYPE c,
         tot_exp1(15)   TYPE c,    tot_exp2(15) TYPE c,    tot_exp3(15) TYPE c,     tot_exp4(15) TYPE c,
         prof_btax1(15) TYPE c,  prof_btax2(15) TYPE c,  prof_btax3(15) TYPE c,   prof_btax4(15) TYPE c,
         prof_atax1(15) TYPE c,  prof_atax2(15) TYPE c,  prof_atax3(15) TYPE c,   prof_atax4(15) TYPE c.


  DATA: rev_opr(15) TYPE c,
        oth_inc(15) TYPE c,
        chg_inv(15) TYPE c,
        ovr_und(15) TYPE c,
        pts_de(15)  TYPE c,
        exp_cst(15) TYPE c,
        fin_cst(15) TYPE c,
        dda(15)     TYPE c,
        prov_of(15) TYPE c,
        oth_exp(15) TYPE c,
        inc_tax(15) TYPE c.



  DATA lv_amt(17) TYPE c.

  TYPES : BEGIN OF ty_gl_oth,
            oth_pro TYPE zfi_pnl_gl-oth_pro,
            gl_acct TYPE zfi_pnl_gl-gl_acct,
          END OF ty_gl_oth.

  DATA : lt_gl_oth TYPE STANDARD TABLE OF ty_gl_oth.

  CLEAR wa_final_non.
  REFRESH : it_final_non[],lt_fcat[].

  SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls).

  SELECT * FROM zfi_pnl_proj INTO TABLE @DATA(it_proj)
           WHERE company = @p_compy1
             AND bukrs = @p_comp1
             AND jvnam IN @p_proj1.

  IF it_proj IS NOT INITIAL.
    READ TABLE it_proj INTO DATA(wa_proj) WITH KEY manual = 'YES'.
    IF wa_proj IS NOT INITIAL.
      DATA(manual) = 'X'.
    ENDIF.

    CLEAR wa_proj.
    READ TABLE it_proj INTO wa_proj WITH KEY assoct = 'YES'.
    IF wa_proj IS NOT INITIAL.
      DATA(assoct) = 'X'.
    ENDIF.
  ENDIF.

  IF it_gls IS NOT INITIAL AND manual NE 'X'.

    PERFORM map_period USING s_period-low .

    SELECT rldnr,
           ryear,
           rtcur,
           drcrk,
           poper,
           docnr,
           docln,
           rbukrs,
           rjvnam,
           racct,
           ksl,
           matnr
*BOC By Arnav on 26/10/26
*      FROM jvso1 INTO TABLE @DATA(it_jvso1)
      FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso1)
*EOC By Arnav on 26/10/26
               FOR ALL ENTRIES IN @it_gls
                WHERE rbukrs = @p_comp1
                  AND ryear  = @p_year1
                  AND rldnr  = '4A'
                  AND poper BETWEEN @s_period_low AND @s_period_high
                  AND racct  = @it_gls-gl_acct
                  AND rjvnam IN @p_proj1.

    SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls1)
             FOR ALL ENTRIES IN @it_jvso1
             WHERE gl_acct = @it_jvso1-racct.


    IF p_year2 IS NOT INITIAL AND s_period_low2 IS NOT INITIAL.
      PERFORM map_period USING s_period_low2 .

      SELECT rldnr,
             ryear,
             rtcur,
             drcrk,
             poper,
             docnr,
             docln,
             rbukrs,
             rjvnam,
             racct,
             ksl,
             matnr
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso2)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso2)
*EOC By Arnav on 26/10/26
                 FOR ALL ENTRIES IN @it_gls
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year2
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = @it_gls-gl_acct
                    AND rjvnam IN @p_proj1.

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls2)
               FOR ALL ENTRIES IN @it_jvso2
               WHERE gl_acct = @it_jvso2-racct.
    ENDIF.

    IF p_year3 IS NOT INITIAL AND s_period_low3 IS NOT INITIAL.
      PERFORM map_period USING s_period_low3 .

      SELECT rldnr,
             ryear,
             rtcur,
             drcrk,
             poper,
             docnr,
             docln,
             rbukrs,
             rjvnam,
             racct,
             ksl,
             matnr
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso3)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso3)
*EOC By Arnav on 26/10/26
                 FOR ALL ENTRIES IN @it_gls
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year3
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = @it_gls-gl_acct
                    AND rjvnam IN @p_proj1.

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls3)
               FOR ALL ENTRIES IN @it_jvso3
               WHERE gl_acct = @it_jvso3-racct.

    ENDIF.

    IF p_year4 IS NOT INITIAL AND s_period_low4 IS NOT INITIAL.
      PERFORM map_period USING s_period_low4 .

      SELECT rldnr,
             ryear,
             rtcur,
             drcrk,
             poper,
             docnr,
             docln,
             rbukrs,
             rjvnam,
             racct,
             ksl,
             matnr
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso4)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso4)
*EOC By Arnav on 26/10/26
                 FOR ALL ENTRIES IN @it_gls
                  WHERE rbukrs = @p_comp1
                    AND ryear  = @p_year4
                    AND rldnr  = '4A'
                    AND poper BETWEEN @s_period_low AND @s_period_high
                    AND racct  = @it_gls-gl_acct
                    AND rjvnam IN @p_proj1.

      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls4)
               FOR ALL ENTRIES IN @it_jvso4
               WHERE gl_acct = @it_jvso4-racct.

    ENDIF.

  ELSEIF it_gls IS NOT INITIAL AND manual EQ 'X'.

    SELECT * FROM zpnl_oth_proj INTO TABLE @DATA(it_manual_non)
            WHERE company = @p_compy1
              AND bukrs = @p_comp1
              AND pro_nam IN @p_proj1
              AND fisyear = @p_year1.

    IF p_year2 IS NOT INITIAL.
      SELECT * FROM zpnl_oth_proj APPENDING TABLE it_manual_non
              WHERE company = p_compy1
                AND bukrs = p_comp1
                AND pro_nam IN p_proj1
                AND fisyear = p_year2.
    ENDIF.

    IF p_year3 IS NOT INITIAL.
      SELECT * FROM zpnl_oth_proj APPENDING TABLE it_manual_non
              WHERE company = p_compy1
                AND bukrs = p_comp1
                AND pro_nam IN p_proj1
                AND fisyear = p_year3.
    ENDIF.

    IF p_year4 IS NOT INITIAL.
      SELECT * FROM zpnl_oth_proj APPENDING TABLE it_manual_non
              WHERE company = p_compy1
                AND bukrs = p_comp1
                AND pro_nam IN p_proj1
                AND fisyear = p_year4.
    ENDIF.

  ENDIF.

  SORT it_manual_non BY fisyear zperiod.
  DELETE ADJACENT DUPLICATES FROM it_manual_non COMPARING fisyear zperiod.

  CLEAR wa_final_non.
  REFRESH it_final_non[].

  READ TABLE it_oth_f4 INTO DATA(wa_oth_f4) WITH KEY text_no = '301'.
  wa_final_non-per = wa_oth_f4-oth_proj ."REVENUE FROM OPERATIONS.
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '302'.
  wa_final_non-per = wa_oth_f4-oth_proj ."OTHER INCOME
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  wa_final_non-per = 'TOTAL INCOME'.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = ' '.
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '304'.
  wa_final_non-per = wa_oth_f4-oth_proj ."CHANGE IN INVENTORIES
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '305'.
  wa_final_non-per = wa_oth_f4-oth_proj ."OVERLIFT/(UNDERLIFT)
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '303'.
  wa_final_non-per = wa_oth_f4-oth_proj ."PRODUCTION, TRANSPORTATION, SELLING & DISTRIBUTION EXPENDITURE
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '307'.
  wa_final_non-per = wa_oth_f4-oth_proj ."EXPLORATION COSTS WRITTEN OFF
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '308'.
  wa_final_non-per = wa_oth_f4-oth_proj ."FINANCE COST
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '306'.
  wa_final_non-per = wa_oth_f4-oth_proj ."DEPRECIATION, DEPLETION & AMORTIZATION
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '309'.
  wa_final_non-per = wa_oth_f4-oth_proj ."PROVISIONS, WRITE OFF AND OTHER IMPAIRMENT
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '310'.
  wa_final_non-per = wa_oth_f4-oth_proj ."OTHER EXPENSES (INCL. EXCHANGE FLUCTUATION)
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  wa_final_non-per = 'TOTAL EXPENSE'.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = ' '.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = 'PROFIT BEFORE TAX'.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = ' '.
  APPEND wa_final_non TO it_final_non.
  CLEAR : wa_final_non,wa_oth_f4.

  READ TABLE it_oth_f4 INTO wa_oth_f4 WITH KEY text_no = '311'.
  wa_final_non-per = wa_oth_f4-oth_proj ."INCOME TAX
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = ' '.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = 'NET PROFIT/(LOSS) AFTER TAX'.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

  wa_final_non-per = ' '.
  APPEND wa_final_non TO it_final_non.
  CLEAR wa_final_non.

***********************begin by Aparna On 26.02.2024
  LOOP AT it_final_non ASSIGNING FIELD-SYMBOL(<fs_final_non>).


    SELECT SINGLE *
    FROM   zfi_pl_var_non
    INTO   @DATA(wa_pl_var_non)
           WHERE per    = @<fs_final_non>-per
           AND comp = @p_comp1
           AND   period = @s_period-low
      AND period2 = @s_period_low2
      AND fiscal = @p_year1
      AND proj = @p_proj1-low.
    IF sy-subrc = 0.

      <fs_final_non>-remark = wa_pl_var_non-remark.

    ENDIF.

  ENDLOOP.
********************** code ended by Aparna on 26.02.2024
  IF it_jvso1 IS NOT INITIAL.

    REFRESH lt_gl_oth[].
    MOVE-CORRESPONDING it_gls1[] TO lt_gl_oth[].
    SORT lt_gl_oth[] BY oth_pro.

    LOOP AT lt_gl_oth INTO DATA(wa_gls1).

      LOOP AT it_jvso1 INTO DATA(wa_jvso1) WHERE racct = wa_gls1-gl_acct.
        lv_amt = lv_amt + wa_jvso1-ksl.
        CLEAR wa_jvso1.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.

      AT END OF oth_pro.
        READ TABLE it_final_non INTO wa_final_non WITH KEY per = wa_gls1-oth_pro.
        IF wa_final_non IS NOT INITIAL.
          wa_final_non-val1 = ( wa_final_non-val1 + lv_amt ) / 1000000.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val1 WHERE per = wa_gls1-oth_pro.
        ENDIF.
        CLEAR : wa_final_non,lv_amt.
      ENDAT.
      CLEAR wa_gls1.

    ENDLOOP.
  ENDIF.


  IF it_jvso2 IS NOT INITIAL.
    REFRESH lt_gl_oth[].
    MOVE-CORRESPONDING it_gls2[] TO lt_gl_oth[].
    SORT lt_gl_oth[] BY oth_pro.

    LOOP AT lt_gl_oth INTO DATA(wa_gls2).

      LOOP AT it_jvso2 INTO DATA(wa_jvso2) WHERE racct = wa_gls2-gl_acct.
        lv_amt = lv_amt + wa_jvso2-ksl.
        CLEAR wa_jvso2.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.

      AT END OF oth_pro.
        READ TABLE it_final_non INTO wa_final_non WITH KEY per = wa_gls2-oth_pro.
        IF wa_final_non IS NOT INITIAL.
          wa_final_non-val2 = ( wa_final_non-val2 + lv_amt ) / 1000000.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val2 WHERE per = wa_gls2-oth_pro.
        ENDIF.
        CLEAR : wa_final_non,lv_amt.
      ENDAT.
      CLEAR wa_gls2.

    ENDLOOP.
  ENDIF.


  IF it_jvso3 IS NOT INITIAL.

    REFRESH lt_gl_oth[].
    MOVE-CORRESPONDING it_gls3[] TO lt_gl_oth[].
    SORT lt_gl_oth[] BY oth_pro.

    LOOP AT lt_gl_oth INTO DATA(wa_gls3).

      LOOP AT it_jvso3 INTO DATA(wa_jvso3) WHERE racct = wa_gls3-gl_acct.
        lv_amt = lv_amt + wa_jvso3-ksl.
        CLEAR wa_jvso3.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.

      AT END OF oth_pro.
        READ TABLE it_final_non INTO wa_final_non WITH KEY per = wa_gls3-oth_pro.
        IF wa_final_non IS NOT INITIAL.
          wa_final_non-val3 = ( wa_final_non-val3 + lv_amt ) / 1000000.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val3 WHERE per = wa_gls3-oth_pro.
        ENDIF.
        CLEAR : wa_final_non,lv_amt.
      ENDAT.
      CLEAR wa_gls3.

    ENDLOOP.
  ENDIF.


  IF it_jvso4 IS NOT INITIAL.
    REFRESH lt_gl_oth[].
    MOVE-CORRESPONDING it_gls4[] TO lt_gl_oth[].
    SORT lt_gl_oth[] BY oth_pro.

    LOOP AT lt_gl_oth INTO DATA(wa_gls4).

      LOOP AT it_jvso4 INTO DATA(wa_jvso4) WHERE racct = wa_gls4-gl_acct.
        lv_amt = lv_amt + wa_jvso4-ksl.
        CLEAR wa_jvso4.
      ENDLOOP.

      CONDENSE lv_amt NO-GAPS.

      AT END OF oth_pro.
        READ TABLE it_final_non INTO wa_final_non WITH KEY per = wa_gls4-oth_pro.
        IF wa_final_non IS NOT INITIAL.
          wa_final_non-val4 = ( wa_final_non-val4 + lv_amt ) / 1000000.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val4 WHERE per = wa_gls4-oth_pro.
        ENDIF.
        CLEAR : wa_final_non,lv_amt.
      ENDAT.
      CLEAR wa_gls4.

    ENDLOOP.
  ENDIF.


  IF it_manual_non IS NOT INITIAL .

    LOOP AT it_manual_non INTO DATA(wa_manual_non).

      rev_opr = rev_opr + wa_manual_non-rev_opr .
      oth_inc = oth_inc + wa_manual_non-oth_inc .
      chg_inv = chg_inv + wa_manual_non-chg_inv .
      ovr_und = ovr_und + wa_manual_non-ovr_und .
      pts_de =  pts_de + wa_manual_non-pts_de  .
      exp_cst = exp_cst + wa_manual_non-exp_cst .
      fin_cst = fin_cst + wa_manual_non-fin_cst .
      dda =     dda + wa_manual_non-dda     .
      prov_of = prov_of + wa_manual_non-prov_of .
      oth_exp = oth_exp + wa_manual_non-oth_exp .
      inc_tax = inc_tax + wa_manual_non-inc_tax .

    ENDLOOP.


    DATA peri1_1(6) TYPE c.
    DATA peri1_2(6) TYPE c.
    DATA peri2_1(6) TYPE c.
    DATA peri2_2(6) TYPE c.
    DATA peri3_1(6) TYPE c.
    DATA peri3_2(6) TYPE c.
    DATA peri4_1(6) TYPE c.
    DATA peri4_2(6) TYPE c.

    DATA : it_manual_non2 TYPE STANDARD TABLE OF zpnl_oth_proj.


    CASE s_period-low.
      WHEN 'Q2'.
        peri1_1 = 'Q1'.
        peri1_2 = 'H1'.
      WHEN 'Q3'.
        peri1_1 = 'H1'.
        peri1_2 = '9M'.
      WHEN 'Q4'.
        peri1_1 = '9M'.
        peri1_2 = 'ANNUAL'.
      WHEN OTHERS.
        peri1_1 = s_period-low.
        peri1_2 = s_period-low.
    ENDCASE.

    CASE s_period_low2.
      WHEN 'Q2'.
        peri2_1 = 'Q1'.
        peri2_2 = 'H1'.
      WHEN 'Q3'.
        peri2_1 = 'H1'.
        peri2_2 = '9M'.
      WHEN 'Q4'.
        peri2_1 = '9M'.
        peri2_2 = 'ANNUAL'.
      WHEN OTHERS.
        peri2_1 = s_period_low2.
        peri2_2 = s_period_low2.
    ENDCASE.

    CASE s_period_low3.
      WHEN 'Q2'.
        peri3_1 = 'Q1'.
        peri3_2 = 'H1'.
      WHEN 'Q3'.
        peri3_1 = 'H1'.
        peri3_2 = '9M'.
      WHEN 'Q4'.
        peri3_1 = '9M'.
        peri3_2 = 'ANNUAL'.
      WHEN OTHERS.
        peri3_1 = s_period_low3.
        peri3_2 = s_period_low3.
    ENDCASE.

    CASE s_period_low4.
      WHEN 'Q2'.
        peri4_1 = 'Q1'.
        peri4_2 = 'H1'.
      WHEN 'Q3'.
        peri4_1 = 'H1'.
        peri4_2 = '9M'.
      WHEN 'Q4'.
        peri4_1 = '9M'.
        peri4_2 = 'ANNUAL'.
      WHEN OTHERS.
        peri4_1 = s_period_low4.
        peri4_2 = s_period_low4.
    ENDCASE.

**********************Input other projects
    MOVE-CORRESPONDING it_manual_non TO it_manual_non2.
    IF peri1_1 IS NOT INITIAL AND peri1_2 IS NOT INITIAL.
      READ TABLE it_manual_non INTO DATA(wa_manual_non1) WITH KEY fisyear = p_year1 zperiod = peri1_2.
      READ TABLE it_manual_non2 INTO DATA(wa_manual_non1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

      wa_manual_non1-zperiod = s_period-low.
      wa_manual_non1-rev_opr = wa_manual_non1-rev_opr - wa_manual_non1_1-rev_opr.
      wa_manual_non1-oth_inc = wa_manual_non1-oth_inc - wa_manual_non1_1-oth_inc.
      wa_manual_non1-chg_inv = wa_manual_non1-chg_inv - wa_manual_non1_1-chg_inv.
      wa_manual_non1-ovr_und = wa_manual_non1-ovr_und - wa_manual_non1_1-ovr_und.
      wa_manual_non1-pts_de  = wa_manual_non1-pts_de  - wa_manual_non1_1-pts_de .
      wa_manual_non1-exp_cst = wa_manual_non1-exp_cst - wa_manual_non1_1-exp_cst.
      wa_manual_non1-fin_cst = wa_manual_non1-fin_cst - wa_manual_non1_1-fin_cst.
      wa_manual_non1-dda     = wa_manual_non1-dda     - wa_manual_non1_1-dda    .
      wa_manual_non1-prov_of = wa_manual_non1-prov_of - wa_manual_non1_1-prov_of.
      wa_manual_non1-oth_exp = wa_manual_non1-oth_exp - wa_manual_non1_1-oth_exp.
      wa_manual_non1-inc_tax = wa_manual_non1-inc_tax - wa_manual_non1_1-inc_tax.

      APPEND wa_manual_non1 TO it_manual_non.
      CLEAR : wa_manual_non1,wa_manual_non1_1.

    ENDIF.

    IF peri2_1 IS NOT INITIAL AND peri2_2 IS NOT INITIAL.
      READ TABLE it_manual_non INTO wa_manual_non1 WITH KEY fisyear = p_year1 zperiod = peri2_2.
      READ TABLE it_manual_non2 INTO wa_manual_non1_1 WITH KEY fisyear = p_year1 zperiod = peri2_1.

      wa_manual_non1-zperiod = s_period_low2.
      wa_manual_non1-rev_opr = wa_manual_non1-rev_opr - wa_manual_non1_1-rev_opr.
      wa_manual_non1-oth_inc = wa_manual_non1-oth_inc - wa_manual_non1_1-oth_inc.
      wa_manual_non1-chg_inv = wa_manual_non1-chg_inv - wa_manual_non1_1-chg_inv.
      wa_manual_non1-ovr_und = wa_manual_non1-ovr_und - wa_manual_non1_1-ovr_und.
      wa_manual_non1-pts_de  = wa_manual_non1-pts_de  - wa_manual_non1_1-pts_de .
      wa_manual_non1-exp_cst = wa_manual_non1-exp_cst - wa_manual_non1_1-exp_cst.
      wa_manual_non1-fin_cst = wa_manual_non1-fin_cst - wa_manual_non1_1-fin_cst.
      wa_manual_non1-dda     = wa_manual_non1-dda     - wa_manual_non1_1-dda    .
      wa_manual_non1-prov_of = wa_manual_non1-prov_of - wa_manual_non1_1-prov_of.
      wa_manual_non1-oth_exp = wa_manual_non1-oth_exp - wa_manual_non1_1-oth_exp.
      wa_manual_non1-inc_tax = wa_manual_non1-inc_tax - wa_manual_non1_1-inc_tax.

      APPEND wa_manual_non1 TO it_manual_non.
      CLEAR : wa_manual_non1,wa_manual_non1_1.

    ENDIF.

    IF peri3_1 IS NOT INITIAL AND peri3_2 IS NOT INITIAL.
      READ TABLE it_manual_non INTO wa_manual_non1 WITH KEY fisyear = p_year1 zperiod = peri3_2.
      READ TABLE it_manual_non2 INTO wa_manual_non1_1 WITH KEY fisyear = p_year1 zperiod = peri3_1.

      wa_manual_non1-zperiod = s_period_low3.
      wa_manual_non1-rev_opr = wa_manual_non1-rev_opr - wa_manual_non1_1-rev_opr.
      wa_manual_non1-oth_inc = wa_manual_non1-oth_inc - wa_manual_non1_1-oth_inc.
      wa_manual_non1-chg_inv = wa_manual_non1-chg_inv - wa_manual_non1_1-chg_inv.
      wa_manual_non1-ovr_und = wa_manual_non1-ovr_und - wa_manual_non1_1-ovr_und.
      wa_manual_non1-pts_de  = wa_manual_non1-pts_de  - wa_manual_non1_1-pts_de .
      wa_manual_non1-exp_cst = wa_manual_non1-exp_cst - wa_manual_non1_1-exp_cst.
      wa_manual_non1-fin_cst = wa_manual_non1-fin_cst - wa_manual_non1_1-fin_cst.
      wa_manual_non1-dda     = wa_manual_non1-dda     - wa_manual_non1_1-dda    .
      wa_manual_non1-prov_of = wa_manual_non1-prov_of - wa_manual_non1_1-prov_of.
      wa_manual_non1-oth_exp = wa_manual_non1-oth_exp - wa_manual_non1_1-oth_exp.
      wa_manual_non1-inc_tax = wa_manual_non1-inc_tax - wa_manual_non1_1-inc_tax.

      APPEND wa_manual_non1 TO it_manual_non.
      CLEAR : wa_manual_non1,wa_manual_non1_1.

    ENDIF.

    IF peri4_1 IS NOT INITIAL AND peri4_2 IS NOT INITIAL.
      READ TABLE it_manual_non INTO wa_manual_non1 WITH KEY fisyear = p_year1 zperiod = peri4_2.
      READ TABLE it_manual_non2 INTO wa_manual_non1_1 WITH KEY fisyear = p_year1 zperiod = peri4_1.

      wa_manual_non1-zperiod = s_period_low4.
      wa_manual_non1-rev_opr = wa_manual_non1-rev_opr - wa_manual_non1_1-rev_opr.
      wa_manual_non1-oth_inc = wa_manual_non1-oth_inc - wa_manual_non1_1-oth_inc.
      wa_manual_non1-chg_inv = wa_manual_non1-chg_inv - wa_manual_non1_1-chg_inv.
      wa_manual_non1-ovr_und = wa_manual_non1-ovr_und - wa_manual_non1_1-ovr_und.
      wa_manual_non1-pts_de  = wa_manual_non1-pts_de  - wa_manual_non1_1-pts_de .
      wa_manual_non1-exp_cst = wa_manual_non1-exp_cst - wa_manual_non1_1-exp_cst.
      wa_manual_non1-fin_cst = wa_manual_non1-fin_cst - wa_manual_non1_1-fin_cst.
      wa_manual_non1-dda     = wa_manual_non1-dda     - wa_manual_non1_1-dda    .
      wa_manual_non1-prov_of = wa_manual_non1-prov_of - wa_manual_non1_1-prov_of.
      wa_manual_non1-oth_exp = wa_manual_non1-oth_exp - wa_manual_non1_1-oth_exp.
      wa_manual_non1-inc_tax = wa_manual_non1-inc_tax - wa_manual_non1_1-inc_tax.

      APPEND wa_manual_non1 TO it_manual_non.
      CLEAR : wa_manual_non1,wa_manual_non1_1.
    ENDIF.

    CLEAR : wa_manual_non1.

    READ TABLE it_manual_non INTO wa_manual_non1 WITH KEY fisyear = p_year1 zperiod = s_period-low.

    READ TABLE it_manual_non INTO DATA(wa_manual_non2) WITH KEY fisyear = p_year2 zperiod = s_period_low2.

    READ TABLE it_manual_non INTO DATA(wa_manual_non3) WITH KEY fisyear = p_year3 zperiod = s_period_low3.

    READ TABLE it_manual_non INTO DATA(wa_manual_non4) WITH KEY fisyear = p_year4 zperiod = s_period_low4.

    LOOP AT it_final_non INTO wa_final_non.

      CASE sy-tabix.

        WHEN 1 .
          wa_final_non-val1 = wa_manual_non1-rev_opr.
          wa_final_non-val2 = wa_manual_non2-rev_opr.
          wa_final_non-val3 = wa_manual_non3-rev_opr.
          wa_final_non-val4 = wa_manual_non4-rev_opr.
        WHEN 2 .
          wa_final_non-val1 = wa_manual_non1-oth_inc.
          wa_final_non-val2 = wa_manual_non2-oth_inc.
          wa_final_non-val3 = wa_manual_non3-oth_inc.
          wa_final_non-val4 = wa_manual_non4-oth_inc.
        WHEN 3 .
        WHEN 4 .
        WHEN 5 .
          wa_final_non-val1 = wa_manual_non1-chg_inv.
          wa_final_non-val2 = wa_manual_non2-chg_inv.
          wa_final_non-val3 = wa_manual_non3-chg_inv.
          wa_final_non-val4 = wa_manual_non4-chg_inv.
        WHEN 6 .
          wa_final_non-val1 = wa_manual_non1-ovr_und.
          wa_final_non-val2 = wa_manual_non2-ovr_und.
          wa_final_non-val3 = wa_manual_non3-ovr_und.
          wa_final_non-val4 = wa_manual_non4-ovr_und.
        WHEN 7 .
          wa_final_non-val1 = wa_manual_non1-pts_de.
          wa_final_non-val2 = wa_manual_non2-pts_de.
          wa_final_non-val3 = wa_manual_non3-pts_de.
          wa_final_non-val4 = wa_manual_non4-pts_de.
        WHEN 8 .
          wa_final_non-val1 = wa_manual_non1-exp_cst.
          wa_final_non-val2 = wa_manual_non2-exp_cst.
          wa_final_non-val3 = wa_manual_non3-exp_cst.
          wa_final_non-val4 = wa_manual_non4-exp_cst.
        WHEN 9 .
          wa_final_non-val1 = wa_manual_non1-fin_cst.
          wa_final_non-val2 = wa_manual_non2-fin_cst.
          wa_final_non-val3 = wa_manual_non3-fin_cst.
          wa_final_non-val4 = wa_manual_non4-fin_cst.
        WHEN 10.
          wa_final_non-val1 = wa_manual_non1-dda.
          wa_final_non-val2 = wa_manual_non2-dda.
          wa_final_non-val3 = wa_manual_non3-dda.
          wa_final_non-val4 = wa_manual_non4-dda.
        WHEN 11.
          wa_final_non-val1 = wa_manual_non1-prov_of.
          wa_final_non-val2 = wa_manual_non2-prov_of.
          wa_final_non-val3 = wa_manual_non3-prov_of.
          wa_final_non-val4 = wa_manual_non4-prov_of.
        WHEN 12.
          wa_final_non-val1 = wa_manual_non1-oth_exp.
          wa_final_non-val2 = wa_manual_non2-oth_exp.
          wa_final_non-val3 = wa_manual_non3-oth_exp.
          wa_final_non-val4 = wa_manual_non4-oth_exp.
        WHEN 13.
        WHEN 14.
        WHEN 15.
        WHEN 16.
        WHEN 17.
          wa_final_non-val1 = wa_manual_non1-inc_tax.
          wa_final_non-val2 = wa_manual_non2-inc_tax.
          wa_final_non-val3 = wa_manual_non3-inc_tax.
          wa_final_non-val4 = wa_manual_non4-inc_tax.
        WHEN 18.
        WHEN 19.

      ENDCASE.

      MODIFY it_final_non FROM wa_final_non TRANSPORTING val1 val2 val3 val4.
      CLEAR wa_final_non.

    ENDLOOP.

  ENDIF.

  DATA lv_val(15) TYPE c.

  LOOP AT it_final_non INTO wa_final_non.

    CASE sy-tabix.
      WHEN 1 .

        CLEAR lv_val.
        lv_val = wa_final_non-val1.
        IF lv_val CA '-'.
          wa_final_non-val1 = wa_final_non-val1 * -1.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val1.
        ENDIF.

        CLEAR lv_val.
        lv_val = wa_final_non-val2.
        IF lv_val CA '-'.
          wa_final_non-val2 = wa_final_non-val2 * -1.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val2.
        ENDIF.

        CLEAR lv_val.
        lv_val = wa_final_non-val3.
        IF lv_val CA '-'.
          wa_final_non-val3 = wa_final_non-val3 * -1.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val3.
        ENDIF.

        CLEAR lv_val.
        lv_val = wa_final_non-val4.
        IF lv_val CA '-'.
          wa_final_non-val4 = wa_final_non-val4 * -1.
          MODIFY it_final_non FROM wa_final_non TRANSPORTING val4.
        ENDIF.

        tot_inc1 = tot_inc1 + wa_final_non-val1.
        tot_inc2 = tot_inc2 + wa_final_non-val2.
        tot_inc3 = tot_inc3 + wa_final_non-val3.
        tot_inc4 = tot_inc4 + wa_final_non-val4.


      WHEN 2 .
        tot_inc1 = tot_inc1 + wa_final_non-val1.
        tot_inc2 = tot_inc2 + wa_final_non-val2.
        tot_inc3 = tot_inc3 + wa_final_non-val3.
        tot_inc4 = tot_inc4 + wa_final_non-val4.

      WHEN 3 .
        wa_final_non-val1 = tot_inc1 .
        wa_final_non-val2 = tot_inc2 .
        wa_final_non-val3 = tot_inc3 .
        wa_final_non-val4 = tot_inc4 .

        MODIFY it_final_non FROM wa_final_non TRANSPORTING val1 val2 val3 val4 .
        CLEAR wa_final_non.

      WHEN 4 .
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 5 .
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 6 .
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 7 .
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 8 .
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 9 .
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 10.
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 11.
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 12.
        tot_exp1 = tot_exp1 + wa_final_non-val1.
        tot_exp2 = tot_exp2 + wa_final_non-val2.
        tot_exp3 = tot_exp3 + wa_final_non-val3.
        tot_exp4 = tot_exp4 + wa_final_non-val4.

      WHEN 13.
        wa_final_non-val1 = tot_exp1.
        wa_final_non-val2 = tot_exp2.
        wa_final_non-val3 = tot_exp3.
        wa_final_non-val4 = tot_exp4.


        MODIFY it_final_non FROM wa_final_non TRANSPORTING val1 val2 val3 val4 .
        CLEAR wa_final_non.

      WHEN 14.
      WHEN 15.
        prof_btax1 = wa_final_non-val1 = tot_inc1 - tot_exp1.
        prof_btax2 = wa_final_non-val2 = tot_inc2 - tot_exp2.
        prof_btax3 = wa_final_non-val3 = tot_inc3 - tot_exp3.
        prof_btax4 = wa_final_non-val4 = tot_inc4 - tot_exp4.


        MODIFY it_final_non FROM wa_final_non TRANSPORTING val1 val2 val3 val4 .
        CLEAR wa_final_non.

      WHEN 16.
      WHEN 17.
        prof_atax1 =  wa_final_non-val1.
        prof_atax2 =  wa_final_non-val2.
        prof_atax3 =  wa_final_non-val3.
        prof_atax4 =  wa_final_non-val4.

      WHEN 18.
      WHEN 19.
        wa_final_non-val1 = prof_btax1 - prof_atax1.
        wa_final_non-val2 = prof_btax2 - prof_atax2.
        wa_final_non-val3 = prof_btax3 - prof_atax3.
        wa_final_non-val4 = prof_btax4 - prof_atax4.

        MODIFY it_final_non FROM wa_final_non TRANSPORTING val1 val2 val3 val4 .
        CLEAR wa_final_non.

    ENDCASE.
*
    CLEAR wa_final_non.
  ENDLOOP.
ENDFORM."CRE_NON_PRD


FORM fcat_fill_non .
  DATA non_h TYPE string.

  CLEAR non_h.
  PERFORM period_text USING s_period-low p_year1.
  non_h = per_text.

  PERFORM alv_fcat_non USING :  'PER'      'Particulars'        ,
                                'VAL1'     non_h     .

  IF  p_year2 IS NOT INITIAL.
    CLEAR non_h.
    PERFORM period_text USING s_period_low2 p_year2.
    non_h = per_text.

    PERFORM alv_fcat_non USING :  'VAL2'     non_h     .
  ENDIF.

  IF  p_year3 IS NOT INITIAL.
    CLEAR non_h.
    PERFORM period_text USING s_period_low3 p_year3.
    non_h = per_text.

    PERFORM alv_fcat_non USING :  'VAL3'     non_h     .
  ENDIF.

  IF  p_year4 IS NOT INITIAL.
    CLEAR non_h.
    PERFORM period_text USING s_period_low4 p_year4.
    non_h = per_text.

    PERFORM alv_fcat_non USING :  'VAL4'     non_h     .
  ENDIF.

ENDFORM."fcat_fill_NON

FORM alv_fcat_non  USING  VALUE(p_011)
                        VALUE(p_012).

  wa_fcat-fieldname   = p_011.
  wa_fcat-seltext_l   = p_012.
  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

ENDFORM. " alv_fcat_non

FORM alv_display_non .
  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-cprog
      i_callback_top_of_page = 'TOP_OF_PAGE_NON'
      is_layout              = wa_layout
      it_fieldcat            = it_fcat
      i_default              = 'X'
      i_save                 = 'U'
    TABLES
      t_outtab               = it_final_non
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM. " alv_display_non

FORM top_of_page_non.

  REFRESH int_header[].
  IF lv_non_profitabilty EQ 'X'.
    fs_header-typ = 'H'.
    fs_header-info = 'Profitability Statement for Non-Producing Project'.
    APPEND fs_header TO int_header.
    CLEAR fs_header.
  ELSE.
    fs_header-typ = 'H'.
    fs_header-info = 'Variance Analysis for Non-Producing Project'.
    APPEND fs_header TO int_header.
    CLEAR fs_header.


    fs_header-typ = 'S'.
    fs_header-info = '"FOR SAVING THE REMARKS, SELECT ALL CELLS AND THEN CLICK ON SAVE"'.
    APPEND fs_header TO int_header.
    CLEAR fs_header.
  ENDIF.


  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp
                       WHERE bukrs = p_comp1.

  READ TABLE it_comp INTO DATA(wa_comp) WITH KEY bukrs = p_comp1.
  fs_header-typ = 'S'.
  CONCATENATE 'Company code :- ' wa_comp-bukrs ' - ' wa_comp-txtcc INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE jvnam = p_proj1-low.

  READ TABLE it_proj INTO DATA(wa_proj) WITH KEY jvnam = p_proj1-low.
  fs_header-typ = 'S'.
  CONCATENATE 'Project :- ' wa_proj-jvnam ' - ' wa_proj-txtjv  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  CONCATENATE '(Amount in' 'US$ Mn.)'  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = int_header.

ENDFORM. "TOP_OF_PAGE_NON.

FORM chk_before_save.   " Checking (1a+8-13=9a) and convo factor not blank

**********************************Checking (1a+8-13=9a)

  DATA : lv_13_o(15) TYPE c,
         lv_13_g(15) TYPE c,
         lv_9a_o(15) TYPE c,
         lv_9a_g(15) TYPE c.


  READ TABLE it_quant INTO DATA(wa_1a) INDEX 3.
  READ TABLE it_quant INTO DATA(wa_8)  INDEX 25.
  READ TABLE it_quant INTO DATA(wa_9a) INDEX 28.
  READ TABLE it_quant INTO DATA(wa_13) INDEX 35.
  READ TABLE it_quant INTO DATA(wa_11) INDEX 31.
  IF wa_1a IS NOT INITIAL AND wa_8 IS NOT INITIAL AND wa_13 IS NOT INITIAL.
    lv_9a_o = ( wa_1a-mmbbl + wa_8-mmbbl ) - ( wa_13-mmbbl ).
    lv_9a_g = ( wa_1a-mmbtu + wa_8-mmbtu ) - ( wa_13-mmbtu ).
  ENDIF.

  IF wa_9a IS NOT INITIAL AND lv_9a_o IS NOT INITIAL.
    IF wa_9a-mmbbl NE lv_9a_o.
      MESSAGE 'Closing Stock is not equal to (Opening Stock+Production-Sales) for Crude Oil' TYPE 'W'.
    ENDIF.
  ELSEIF wa_9a IS NOT INITIAL AND lv_9a_g IS NOT INITIAL.
    IF wa_9a-mmbtu NE lv_9a_g.
      MESSAGE 'Closing Stock is not equal to (Opening Stock+Production-Sales) for Natural Gas' TYPE 'W'.
    ENDIF.
  ENDIF.

  IF wa_11 IS NOT INITIAL AND wa_13 IS NOT INITIAL.
    IF wa_13-mmscm NE wa_11-mmscm.
      MESSAGE 'Sales qty. should be equal to Net qty. available for sale (for Natural Gas)' TYPE 'E'.
    ENDIF.
  ENDIF.
*********************************************************

**********************************Conversion factor check
  DATA lv_convo_chk(7) TYPE p DECIMALS 6 VALUE '0.000000'.
  IF ( wa_final_conv-bbl_mmbbl   EQ lv_convo_chk )
  OR ( wa_final_conv-bbl_mmt     EQ lv_convo_chk )
  OR ( wa_final_conv-mmscm_bcm   EQ lv_convo_chk )
  OR ( wa_final_conv-mmscm_mmboe EQ lv_convo_chk )
  OR ( wa_final_conv-mmscm_mmbtu EQ lv_convo_chk ).

    MESSAGE 'Conversion factors cannot be blank' TYPE 'E'.

  ENDIF.

  CLEAR : wa_1a,wa_8,wa_9a,wa_13,wa_11,lv_13_o,lv_13_g,lv_9a_o,lv_9a_g.
*********************************************************
ENDFORM. "CHK_BEFORE_SAVE

FORM popup_save.  "Confirmation before saving to database tables

  IF mode = 'CRE'.
    lv_popup_txt = 'Do you want to create new data?'.
  ELSEIF mode = 'CHA'.
    lv_popup_txt = 'Do you want to change existing data?'.
  ELSEIF mode = 'DIS'.

  ELSEIF mode = 'APP' OR mode = 'APF'.
    lv_popup_txt = 'Do you want to approve data?'.
  ELSEIF mode = 'FRE'.
    lv_popup_txt = 'You cannot change the data after this action. Do you want to freeze data?'.
  ENDIF.

  CLEAR ans.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Please Confirm'
      text_question         = lv_popup_txt
      text_button_1         = 'YES'
      text_button_2         = 'NO'
      default_button        = '2'
      display_cancel_button = 'X'
    IMPORTING
      answer                = ans
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
  CLEAR lv_popup_txt.

ENDFORM."POPUP_SAVE


FORM clear_list. "Clear input parameters if input parameters does not match with the corresponding entries in Z Table

  IF p_company IS NOT INITIAL AND p_comp IS NOT INITIAL. "Clear Comp code and Project if not associated with Company in Z Table

    SELECT txtcc, bukrs FROM zfi_pnl_proj INTO TABLE @DATA(it_comp2) WHERE company = @p_company   "select form project details TMG
                                                                       AND bukrs = @p_comp.
    IF it_comp2 IS INITIAL.
      CLEAR p_comp.
      CLEAR p_proj.
    ENDIF.
  ENDIF.

*Clear Project if not associated with Company in Z Table.
  IF ( p_company IS NOT INITIAL ) AND ( p_comp IS NOT INITIAL ) AND ( p_proj IS NOT INITIAL ).

    SELECT txtjv, jvnam FROM zfi_pnl_proj INTO TABLE @DATA(it_proj2) WHERE company = @p_company   "select form project details TMG
                                                        AND bukrs = @p_comp AND jvnam = @p_proj.
    IF it_proj2 IS INITIAL.
      CLEAR p_proj.
    ENDIF.
  ENDIF.

ENDFORM."CLEAR_LIST


FORM period_text USING VALUE(per_val)
                       VALUE(year_val).

  DATA year_val1(4) TYPE c .

  year_val1 = year_val + 1.
  CLEAR per_text.

  CONCATENATE per_val' FY' year_val+2(2) '-' year_val1+2(2) INTO per_text SEPARATED BY space.
  CLEAR year_val1.

ENDFORM."PERIOD_TEXT


FORM check_gls.  "Check all GLs are maintained in GL table maintanence

  TYPES : BEGIN OF ty_gl_msg,
            saknr TYPE saknr,
            txt50 TYPE txt50,
          END OF ty_gl_msg.

  DATA : it_gl_msg TYPE STANDARD TABLE OF ty_gl_msg,
         wa_gl_msg TYPE ty_gl_msg.
  "Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 12.06.2026

*  SELECT saknr FROM ska1 INTO TABLE @DATA(it_chk_gl1) WHERE ktopl = 'ONGC' AND xbilk = ' ' AND xloev = ' '.
*BOC By Arnav on 27/09/26
* In S/4HANA secondary cost elements are G/L accounts (SKA1, account group
* SECC, account type S). They are not balance-sheet accounts, so the check
* below listed them as unmapped P&L G/Ls. ECC had no such SKA1 rows. The
* OVL trial balance excludes them, so they are excluded from this check.
* ASSUMPTION: I_GLAccountInChartOfAccounts exposes SKA1-KTOKS as GLAccountGroup.
*  SELECT GLAccount               AS saknr
*    FROM I_GLAccountInChartOfAccounts
*    INTO TABLE @DATA(it_chk_gl1)
*    WHERE ChartOfAccounts          = 'ONGC'
*      AND IsBalanceSheetAccount    = ' '
*      AND AccountIsMarkedForDeletion = ' '.
  SELECT GLAccount               AS saknr
    FROM I_GLAccountInChartOfAccounts
    INTO TABLE @DATA(it_chk_gl1)
    WHERE ChartOfAccounts          = 'ONGC'
      AND IsBalanceSheetAccount    = ' '
      AND AccountIsMarkedForDeletion = ' '
      AND GLAccountGroup          <> 'SECC'.
*EOC By Arnav on 27/09/26

  IF it_chk_gl1 IS NOT INITIAL.
*    SELECT saknr FROM skb1 INTO TABLE @DATA(it_chk_gl2)
*                  FOR ALL ENTRIES IN @it_chk_gl1 WHERE saknr = @it_chk_gl1-saknr AND bukrs = @p_comp1 AND xloeb = ' '.
    SELECT GLAccount               AS saknr
      FROM I_GLAccountInCompanyCode
      INTO TABLE @DATA(it_chk_gl2)
      FOR ALL ENTRIES IN @it_chk_gl1
      WHERE GLAccount              = @it_chk_gl1-saknr
        AND CompanyCode            = @p_comp1
        AND AccountIsBlockedForPosting = ' '.
    "Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 12.06.2026
    IF it_chk_gl2 IS NOT INITIAL.
      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls).

      IF it_gls IS NOT INITIAL.
        LOOP AT it_gls  INTO DATA(wa_gls).
          DELETE it_chk_gl2 WHERE saknr = wa_gls-gl_acct.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF it_chk_gl2 IS NOT INITIAL.
    REFRESH :it_gl_msg.
    LOOP AT it_chk_gl2 INTO DATA(wa_chk_gl2).
      wa_gl_msg-saknr = wa_chk_gl2-saknr.
      wa_gl_msg-txt50 = 'GL missing from GL Maintanence' .
      APPEND wa_gl_msg TO it_gl_msg.
      CLEAR : wa_gl_msg,wa_chk_gl2.
    ENDLOOP.
  ENDIF.

  IF it_gl_msg IS NOT INITIAL.
    REFRESH : it_fcat.
    CLEAR gl_msg_lines.

    gl_msg_lines = lines( it_gl_msg ).

    wa_fcat-col_pos = '1' .
    wa_fcat-fieldname = 'SAKNR'.
    wa_fcat-tabname = 'IT_GL_MSG' .
    wa_fcat-seltext_m = 'GL Account' .
    wa_fcat-outputlen = '10'.
    APPEND wa_fcat TO it_fcat .
    CLEAR:wa_fcat.

    wa_fcat-col_pos = '2' .
    wa_fcat-fieldname = 'TXT50'.
    wa_fcat-tabname = 'IT_GL_MSG' .
    wa_fcat-seltext_m = 'Error Message' .
    wa_fcat-outputlen = '50'.
    APPEND wa_fcat TO it_fcat .
    CLEAR:wa_fcat.


    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program     = sy-repid
        i_callback_top_of_page = 'TOP_OF_PAGE_GL_MSG'
        it_fieldcat            = it_fcat
        i_default              = 'X'
        i_save                 = 'U'
      TABLES
        t_outtab               = it_gl_msg
      EXCEPTIONS
        program_error          = 1
        OTHERS                 = 2.

  ELSE.

    gl_msg_lines = '0'.

  ENDIF.


ENDFORM."CHECK_GLS.


FORM top_of_page_gl_msg.
  DATA sno TYPE i.

  REFRESH int_header[].

  fs_header-typ = 'S'.
  CONCATENATE 'No.of GLs not maintained in GL maintainance:-' gl_msg_lines INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = int_header.

ENDFORM."TOP_OF_PAGE_GL_MSG.


FORM cre_var_prd.    "Calculations for variance analysis producing projects

  LOOP AT it_final_bar1 INTO wa_final_bar1.

    wa_final_bar1-total3 = wa_final_bar1-total1 - wa_final_bar1-total2.
    wa_final_bar1-oil3   = wa_final_bar1-oil1   - wa_final_bar1-oil2.
    wa_final_bar1-gas3   = wa_final_bar1-gas1   - wa_final_bar1-gas2.

    IF ( wa_final_bar1-total1 NE '0.00' )
      AND ( wa_final_bar1-total2 = '0.00' ).

      wa_final_bar1-total4  = '100.00'.
      wa_final_bar1-oil4    = '100.00'.
      wa_final_bar1-gas4    = '100.00'.

    ELSEIF ( wa_final_bar1-total1 = '0.00' )
      AND ( wa_final_bar1-total2 NE '0.00' ).

      wa_final_bar1-total4  = '100.00-'.
      wa_final_bar1-oil4    = '100.00-'.
      wa_final_bar1-gas4    = '100.00-'.

    ELSE.

      IF wa_final_bar1-total2 = '0.00'.
        wa_final_bar1-total2 = wa_final_bar1-total3.
      ENDIF.
      IF wa_final_bar1-oil2 = '0.00'.
        wa_final_bar1-oil2 = wa_final_bar1-total3.
      ENDIF.
      IF wa_final_bar1-gas2 = '0.00'.
        wa_final_bar1-gas2 = wa_final_bar1-gas3.
      ENDIF.

      wa_final_bar1-total4 = ( wa_final_bar1-total3 / wa_final_bar1-total2  ) * 100.
      wa_final_bar1-oil4   = ( wa_final_bar1-oil3   / wa_final_bar1-oil2    ) * 100.
      wa_final_bar1-gas4   = ( wa_final_bar1-gas3   / wa_final_bar1-gas2    ) * 100.

    ENDIF.


    wa_final_bar1-total3 = round( val = wa_final_bar1-total3 dec = '2' ) .
    wa_final_bar1-oil3   = round( val = wa_final_bar1-oil3 dec = '2' ) .
    wa_final_bar1-gas3   = round( val = wa_final_bar1-gas3 dec = '2' ) .

    wa_final_bar1-total4 = round( val = wa_final_bar1-total4 dec = '2' ) .
    wa_final_bar1-oil4   = round( val = wa_final_bar1-oil4 dec = '2' ) .
    wa_final_bar1-gas4   = round( val = wa_final_bar1-gas4 dec = '2' ) .


    MODIFY it_final_bar1 FROM wa_final_bar1 TRANSPORTING total3 oil3 gas3
                                                         total4 oil4 gas4.
    CLEAR wa_final_bar1.

  ENDLOOP.

ENDFORM."CRE_VAR_PRD.

FORM fcat_fill_var_prd.
  DATA bar_h TYPE string.

  CLEAR bar_h.
  PERFORM period_text USING s_period-low p_year1.
  bar_h = per_text.


  PERFORM alv_fcat_var_prd USING :  'PER'       'Particulars'    ''    ,
                                    'TOTAL1'    bar_h         ''       ,
                                    'OIL1'      'Crude Oil'   'X'         ,
                                    'GAS1'      'Gas'        'X'          .

  CLEAR bar_h.
  PERFORM period_text USING s_period_low2 p_year2.
  bar_h = per_text.

  PERFORM alv_fcat_var_prd USING :  'TOTAL2'    bar_h    ''              ,
                                    'OIL2'      'Crude Oil'   'X'         ,
                                    'GAS2'      'Gas'       'X'           ,

                                    'TOTAL3'    'Variance-Total'  ''     ,
                                    'OIL3'      'Variance-Crude Oil'  'X'  ,
                                    'GAS3'      'Variance-Gas'    'X'     ,

                                    'TOTAL4'    '%Variance-Total'   ''    ,
                                    'OIL4'      '%Variance-Crude Oil'  'X'  ,
                                    'GAS4'      '%Variance-Gas'    'X'      ,
                                    'REMARK'    'Remark'  '' .

ENDFORM."fcat_fill_var_prd

FORM fcat_fill_var_prd1.

  DATA bar_h TYPE string.

  CLEAR bar_h.
  PERFORM period_text USING s_period-low p_year1.
  bar_h = per_text.


  PERFORM alv_fcat_var_prd1 USING :  'PER'       'Particulars'   ''       ,
                                    'TOTAL1'    bar_h     ''             ,
                                    'OIL1'      'Crude Oil'    'X'        ,
                                    'GAS1'      'Gas'     'X'             .

  CLEAR bar_h.
  PERFORM period_text USING s_period_low2 p_year2.
  bar_h = per_text.

  PERFORM alv_fcat_var_prd1 USING :  'TOTAL2'    bar_h      ''            ,
                                    'OIL2'      'Crude Oil'     'X'       ,
                                    'GAS2'      'Gas'      'X'            ,

                                    'TOTAL3'    'Variance-Total'   ''    ,
                                    'OIL3'      'Variance-Crude Oil'  'X'  ,
                                    'GAS3'      'Variance-Gas'   'X'      ,

                                    'TOTAL4'    '%Variance-Total'   ''    ,
                                    'OIL4'      '%Variance-Crude Oil'   'X'  ,
                                    'GAS4'      '%Variance-Gas'    'X'     ,
                                    'REMARK'    'Remarks'   '' .

ENDFORM."fcat_fill_var_prd


FORM alv_fcat_var_prd  USING  VALUE(p_011)
                              VALUE(p_012)
                              VALUE(p_013)  .

  IF p_011 = 'REMARK' .
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
*    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '100'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSEIF p_011 = 'PER' .
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
*    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '55'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSE.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
    wa_fcat2-no_zero     = 'X'.
    wa_fcat2-decimals_o  = 2.
    wa_fcat2-round       = 2.

    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ENDIF.

ENDFORM." alv_fcat_var_prd

FORM alv_fcat_var_prd1  USING   VALUE(p_011)
                                VALUE(p_012)
                                VALUE(p_013)  .


  IF p_011 = 'REMARK' .
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '100'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSEIF p_011 = 'PER' .
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
*    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '55'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSE.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
    wa_fcat2-no_zero     = 'X'.
    wa_fcat2-decimals_o  = 2.
    wa_fcat2-round       = 2.

    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ENDIF.
ENDFORM." alv_fcat_var_prd1


FORM alv_display_var_prd.
  DATA: i_setting TYPE lvc_s_glay.

  CLEAR it_final_bar.
  REFRESH it_final_bar[].
  wa_layout-box_fieldname  = 'SEL'.
  wa_layout-info_fieldname = 'LINE_COLOR'.

  wa_layout2-box_fname  = 'SEL'.
*  wa_layout2-info_fname = 'LINE_COLOR'.
  wa_layout2-stylefname = 'FIELD_STYLE'.
*  wa_layout2-CWIDTH_OPT = 'X'.   "Begin of Changes - Madhu

  i_setting-edt_cll_cb  = 'X'.
  PERFORM var_prd_cell_disable.

*  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
*    EXPORTING
*      i_callback_program       = sy-cprog
*      i_callback_pf_status_set = 'PF_STATUS_SET'
*      i_grid_settings          = i_setting
*      i_callback_user_command  = 'SAVE'
*      is_layout                = wa_layout
*      it_fieldcat              = it_fcat
**     i_default                = 'X'
**     i_save                   = 'U'
*    TABLES
*      t_outtab                 = it_final_bar1
*    EXCEPTIONS
*      program_error            = 1
*      OTHERS                   = 2.
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program          = sy-cprog
      i_callback_pf_status_set    = 'PF_STATUS_SET'
      i_callback_user_command     = 'SAVE'
      "Begin of Changes - Madhu
*     i_callback_top_of_page      = 'TOP_OF_PAGE_PRO_ANA'
      "End of Changes - Madhu
      i_callback_html_top_of_page = 'TOP_OF_PAGE_HTML'
      i_grid_settings             = i_setting
      is_layout_lvc               = wa_layout2
      it_fieldcat_lvc             = it_fcat2
      i_default                   = 'X'
      i_save                      = 'U'
    TABLES
      t_outtab                    = it_final_bar1
    EXCEPTIONS
      program_error               = 1
      OTHERS                      = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  REFRESH : it_fcat2.
ENDFORM."alv_display_var_prd
*&---------------------------------------------------------------------*
*&      Form  VAR_PRD_CELL_DISABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM var_prd_cell_disable .
*  break abapuser02.
  LOOP AT it_final_bar1 INTO DATA(wa_bar1).
    IF wa_bar1-per = 'OPREATING EXPENSE :' OR wa_bar1-per = '' OR
     wa_bar1-per = 'DDA & EXPLORATION :' OR wa_bar1-per = 'ADJUSTMENT FOR COST OF SALES:' OR
     wa_bar1-per = 'OTHER INCOME/ EXPENSE :' OR wa_bar1-per = '(I) SALES REALISATION' OR wa_bar1-per = '(II) TOTAL OPERATING EXPENSES' OR
     wa_bar1-per = '(IV) OPERATING COST' OR wa_bar1-per = '(III) TOTAL DDA & EXPLORATION' OR
     wa_bar1-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' OR wa_bar1-per = '(VIII) NET OPERATING MARGIN (I-VII)'
     OR wa_bar1-per = '(IX) TOTAL OTHER INCOME/ EXPENSE' OR
     wa_bar1-per = '(X) NET PROFIT BEFORE TAX (VIII-IX)' OR wa_bar1-per = '(XII) NET PROFIT/(LOSS) AFTER TAX (X-XI)' OR
     wa_bar1-per = 'IMPAIRMENT LOSS/(REVERSAL)' OR wa_bar1-per = 'NET PROFIT/(LOSS) AFTER TAX-BEFORE IMPAIRMENT'.

      wa_stylerow-fieldname = 'REMARK'.
      wa_stylerow-style     = cl_gui_alv_grid=>mc_style_disabled.
      INSERT wa_stylerow INTO TABLE wa_bar1-field_style.
      MODIFY it_final_bar1 FROM wa_bar1 TRANSPORTING field_style.
      CLEAR wa_bar1.
    ELSE.
      wa_stylerow-fieldname = 'REMARK'.
      wa_stylerow-style     = cl_gui_alv_grid=>mc_style_enabled.
      INSERT wa_stylerow INTO TABLE wa_bar1-field_style.
      MODIFY it_final_bar1 FROM wa_bar1 TRANSPORTING field_style.
      CLEAR wa_bar1.
    ENDIF.
  ENDLOOP.

ENDFORM.
*-----------------------" Changes Begins by Aparna on 10.02.2024 "-----------------------------*
FORM pf_status_set USING rt_extab TYPE slis_t_extab.


  IF sy-ucomm = 'APPROVE'.

    CLEAR fcode.
    wa_fcode = 'LONGTEXT'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS1' EXCLUDING fcode.

  ELSEIF sy-ucomm = 'CREATE' OR   sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' .
    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS1' EXCLUDING fcode.

  ELSEIF sy-ucomm = 'APPROVEFI'.

    CLEAR fcode.
    wa_fcode = 'LONGTEXT'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS1' EXCLUDING fcode.
  ENDIF.

*  REFRESH fcode.
*  APPEND 'LONGTEXT' TO  fcode.
*  APPEND 'APPROVE' TO  fcode.
*  IF sy-ucomm = 'APPROVE'.
*    SET PF-STATUS 'STATUS1' EXCLUDING 'LONGTEXT'.
*  ELSEIF sy-ucomm = 'CREATE' OR   sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' .
*    SET PF-STATUS 'STATUS1' EXCLUDING 'APPROVE'.
**  ELSEIF sy-ucomm = 'DISPLAY' .
**    SET PF-STATUS 'STATUS1'  EXCLUDING  fcode .
**    ELSE.
**      SET PF-STATUS 'STATUS1' EXCLUDING 'APPROVE'.
**----------------------------" Changes Beigns by Aparna on 31.07.2024 "--------------------------------"
*  ELSEIF sy-ucomm = 'APPROVEFI'.
*    SET PF-STATUS 'STATUS1' EXCLUDING fcode.
**----------------------------" Changes Ended  by Aparna on 31.07.2024 "--------------------------------"
*  ENDIF.

ENDFORM.
FORM save USING r_ucomm LIKE sy-ucomm
                rs_selfield TYPE slis_selfield.


  CASE sy-ucomm.

    WHEN 'SAVE' .
      PERFORM save_remarks.
    WHEN 'LONGTEXT'.
*      PERFORM clear_container.
      PERFORM edit_text.
    WHEN 'APPROVE'.
      PERFORM approver.

    WHEN 'APPROVEFI'.
      PERFORM approverfi1.

    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EDIT_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM edit_text .
  LOOP AT it_final_bar1 INTO DATA(wa_final_bar1) WHERE sel = 'X'.
    CALL SCREEN 9000 STARTING AT 80 10 ENDING AT 140 20 .
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form editor_to_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM editor_to_alv.

  DATA : wa_ahead LIKE thead,
         it_ltext TYPE TABLE OF tline.
  REFRESH : g_mytable.

  CALL METHOD g_editor->get_text_as_r3table
    IMPORTING
      table = g_mytable.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
  ENDIF.
  CLEAR val2.
  LOOP AT g_mytable INTO DATA(wa_mytable).
    CONCATENATE val2 wa_mytable INTO val2 SEPARATED BY space.
  ENDLOOP.

  IF val2 IS NOT INITIAL.
    READ TABLE it_final_bar1 INTO wa_final_bar1 WITH KEY sel = 'X'.
    IF sy-subrc = 0.
      wa_ahead-tdobject = 'ZREMARK'.
      wa_ahead-tdid = 'ZAD'.
      wa_ahead-tdspras = sy-langu.
      wa_ahead-tdname = wa_final_bar1-per.
      CONCATENATE p_proj1-low  s_period-low  s_period_low2  p_year1 wa_final_bar1-per INTO   wa_ahead-tdname.
      REFRESH : i_texttable .
      CLEAR val1.
      CALL METHOD g_editor->get_text_as_stream
        IMPORTING
          text                   = i_texttable  " text as stream with carrige retruns and linefeeds
          is_modified            = val1   " modify status of text
        EXCEPTIONS
          error_dp               = 1
          error_cntl_call_method = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
*       MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      IF  i_texttable  IS NOT INITIAL.

        CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
          EXPORTING
*           STREAM_LINES       =
            language    = sy-langu
*           LF          = ' '
          TABLES
            text_stream = i_texttable
            itf_text    = it_ltext.
      ENDIF.
      IF it_ltext IS NOT INITIAL.
        CALL FUNCTION 'SAVE_TEXT'
          EXPORTING
            client          = sy-mandt
            header          = wa_ahead
            insert          = ''
            savemode_direct = 'X'
            owner_specified = ' '
          TABLES
            lines           = it_ltext
          EXCEPTIONS
            id              = 1
            language        = 2
            name            = 3
            object          = 4
            OTHERS          = 5.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

      ENDIF.

      wa_final_bar1-remark = val2.
      MODIFY it_final_bar1 FROM wa_final_bar1 TRANSPORTING remark WHERE sel = 'X'.
      IF sy-subrc = 0.
        CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
          IMPORTING
            e_grid = l_grid.

*        l_grid->check_changed_data(
*          IMPORTING
*            e_valid   = DATA(l_valid)                 " Entries are Consistent
*        ).
*        IF l_valid IS NOT INITIAL.

        l_grid->refresh_table_display(
          EXCEPTIONS
            finished       = 1                " Display was Ended (by Export)
            OTHERS         = 2
        ).


*        ENDIF.
      ENDIF.

    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SAVE_REMARKS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_remarks .
  BREAK abapuser02.
  DATA(it_final_bar_temp) = it_final_bar1[].
  DELETE it_final_bar_temp WHERE per = 'OPREATING EXPENSE :'.
  DELETE it_final_bar_temp WHERE per = 'DDA & EXPLORATION :'.
  DELETE it_final_bar_temp WHERE per = 'ADJUSTMENT FOR COST OF SALES:'.
  DELETE it_final_bar_temp WHERE per = 'OTHER INCOME/ EXPENSE :' .
  "Begin of Changes     "Madhu
  DELETE it_final_bar_temp WHERE per = '(I) SALES REALISATION' .
  DELETE it_final_bar_temp WHERE per = '(II) TOTAL OPERATING EXPENSES' .
  DELETE it_final_bar_temp WHERE per = '(III) TOTAL DDA & EXPLORATION' .
  DELETE it_final_bar_temp WHERE per = '(IV) OPERATING COST' .
  DELETE it_final_bar_temp WHERE per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
  DELETE it_final_bar_temp WHERE per = '(VIII) NET OPERATING MARGIN (I-VII)' .
  DELETE it_final_bar_temp WHERE per = '(IX) TOTAL OTHER INCOME/ EXPENSE' .
  DELETE it_final_bar_temp WHERE per = '(X) NET PROFIT BEFORE TAX (VIII-IX)' .
  DELETE it_final_bar_temp WHERE per = '(XII) NET PROFIT/(LOSS) AFTER TAX (X-XI)' .
  DELETE it_final_bar_temp WHERE per = 'IMPAIRMENT LOSS/(REVERSAL)' .
  DELETE it_final_bar_temp WHERE per = 'NET PROFIT/(LOSS) AFTER TAX-BEFORE IMPAIRMENT' .
  DELETE it_final_bar_temp WHERE per = ''.
  "End of Changes       "Madhu
  CLEAR wa_final_bar1.
*  READ TABLE it_final_bar1 INTO wa_final_bar1 WITH KEY sel = 'X'.
  LOOP AT it_final_bar_temp INTO wa_final_bar1.
    IF wa_final_bar1-remark IS INITIAL  .
*      MESSAGE 'Please fill remarks in all columns. ' TYPE 'E'.
      MESSAGE 'Remarks column cannot be left blank. ' TYPE 'E'.
    ENDIF.
  ENDLOOP.
  LOOP AT it_final_bar_temp INTO wa_final_bar1 WHERE sel  = 'X'.
    IF  wa_final_bar1-per IS NOT INITIAL.
      IF wa_final_bar1-remark IS INITIAL  .

*        MESSAGE 'Please fill remarks in all columns. ' TYPE 'E'.
        MESSAGE 'Remarks column cannot be left blank. ' TYPE 'E'.
      ELSE.
        wa_zfi_pl_var_prd-mandt  = sy-mandt.
        wa_zfi_pl_var_prd-per    = wa_final_bar1-per.
        CONDENSE wa_final_bar1-remark.
        wa_zfi_pl_var_prd-remark = wa_final_bar1-remark.
        wa_zfi_pl_var_prd-period = s_period-low.
        wa_zfi_pl_var_prd-period2 =  s_period_low2.
        wa_zfi_pl_var_prd-fiscal = p_year1.
        wa_zfi_pl_var_prd-proj = p_proj1-low.
        wa_zfi_pl_var_prd-comp = p_comp1.
        APPEND wa_zfi_pl_var_prd TO  it_zfi_val  .
        CLEAR  wa_zfi_pl_var_prd.

      ENDIF.
    ENDIF.
  ENDLOOP .
  MODIFY zfi_pl_var_prd FROM TABLE it_zfi_val.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Remark Saved Successfully' TYPE 'S'.
    CLEAR: wa_zfi_pl_var_prd, wa_final_bar1.
    REFRESH : it_zfi_val , it_final_bar_temp .
  ENDIF.

  wa_zfi_status-mandt  = sy-mandt.
  wa_zfi_status-period = s_period-low.
  wa_zfi_status-period2 = s_period_low2.
  wa_zfi_status-fiscal = p_year1.
  wa_zfi_status-fiscal2 = p_year2.
  wa_zfi_status-proj = p_proj1-low.
  wa_zfi_status-comp = p_comp1.
  wa_zfi_status-p_compy1 = p_compy1.

  wa_zfi_status-status_cre = 'X'.
  wa_zfi_status-created_by = sy-uname.
  wa_zfi_status-created_on = sy-datum.


  APPEND wa_zfi_status TO  it_zfi_status  .
  CLEAR  wa_zfi_status.

  MODIFY zfi_pl_status FROM TABLE it_zfi_status.

  CLEAR: wa_zfi_status.
  REFRESH : it_zfi_status.

*  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form clear_container
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM clear_container .

  CALL METHOD g_editor_container->free
    EXCEPTIONS
      cntl_error        = 1                " CNTL_ERROR
      cntl_system_error = 2                " CNTL_SYSTEM_ERROR
      OTHERS            = 3.

  CALL METHOD g_editor->free
    EXCEPTIONS
      cntl_error        = 1                " CNTL_ERROR
      cntl_system_error = 2                " CNTL_SYSTEM_ERROR
      OTHERS            = 3.

  FREE: g_editor, g_editor_container.

ENDFORM.

*-----------------------" Chnages Ended  by Aparna on 10.02.2024 "-----------------------------*


FORM cre_var_non.   "Calculations for variance analysis non-producing projects

  CLEAR wa_final_non.
  LOOP AT it_final_non INTO wa_final_non.

    wa_final_non-val3 =   wa_final_non-val1 - wa_final_non-val2.

    IF wa_final_non-val2 = '0.00'. "value cannot be zero to avoid arthematic errors
      wa_final_non-val2 = '0.01'.
    ENDIF.

    wa_final_non-val4 = ( wa_final_non-val3 / wa_final_non-val2  ) * 100.

    wa_final_non-val3 = round( val = wa_final_non-val3 dec = '2' ) .
    wa_final_non-val4 = round( val = wa_final_non-val4 dec = '2' ) .


    MODIFY it_final_non FROM wa_final_non TRANSPORTING val3 val4.


    CLEAR wa_final_non.

  ENDLOOP.

ENDFORM."CRE_VAR_NON

FORM fcat_fill_var_non.
  DATA non_h TYPE string.

  CLEAR non_h.
  PERFORM period_text USING s_period-low p_year1.
  non_h = per_text.

  PERFORM alv_fcat_var_non USING :  'PER'       'Particulars'   ''   ,
                                    'VAL1'    non_h ''.

  CLEAR non_h.
  PERFORM period_text USING s_period_low2 p_year2.
  non_h = per_text.

  PERFORM alv_fcat_var_non USING :  'VAL2'    non_h  '',
                                    'VAL3'    'Variance-Total'  ''  ,
                                    'VAL4'    '%Variance-Total'  ''  ,
                                     'REMARK'   'Remarks' ''.
ENDFORM."fcat_fill_var_non.

FORM fcat_fill_var_non1.
  DATA non_h TYPE string.

  CLEAR non_h.
  PERFORM period_text USING s_period-low p_year1.
  non_h = per_text.

  PERFORM alv_fcat_var_non1 USING :  'PER'       'Particulars'   ''   ,
                                    'VAL1'    non_h ''.

  CLEAR non_h.
  PERFORM period_text USING s_period_low2 p_year2.
  non_h = per_text.

  PERFORM alv_fcat_var_non1 USING :  'VAL2'    non_h  '',
                                    'VAL3'    'Variance-Total'  ''  ,
                                    'VAL4'    '%Variance-Total'  ''  ,
                                     'REMARK'   'Remarks' ''.
ENDFORM."fcat_fill_var_non.

FORM alv_fcat_var_non  USING  VALUE(p_011)
                        VALUE(p_012)
                            VALUE(p_013)  .
  IF p_011 = 'REMARK'.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '100'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSEIF p_011 = 'PER'.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
*    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '55'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSE.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat-no_out      = p_013.
    wa_fcat2-no_zero     = 'X'.
    wa_fcat2-decimals_o  = 2.
    wa_fcat2-round       = 2.

    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ENDIF.

ENDFORM. " alv_fcat_var_nonF

FORM alv_fcat_var_non1  USING  VALUE(p_011)
                        VALUE(p_012)
                            VALUE(p_013)  .
  IF p_011 = 'REMARK'.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
*    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '100'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSEIF p_011 = 'PER'.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat2-no_out      = p_013.
*    wa_fcat2-edit        = 'X'.
    wa_fcat2-outputlen   = '55'.
*    wa_fcat2-input       = 'X'.
    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ELSE.
    wa_fcat2-fieldname   = p_011.
    wa_fcat2-scrtext_l   = p_012.
    wa_fcat-no_out      = p_013.
    wa_fcat2-no_zero     = 'X'.
    wa_fcat2-decimals_o  = 2.
    wa_fcat2-round       = 2.

    APPEND wa_fcat2 TO it_fcat2.
    CLEAR wa_fcat2.

  ENDIF.

ENDFORM. " alv_fcat_var_non
FORM alv_display_var_non.

  DATA: i_setting TYPE lvc_s_glay.

  CLEAR it_final_bar.
  REFRESH it_final_bar[].
  wa_layout-box_fieldname  = 'SEL'.
  wa_layout-info_fieldname = 'LINE_COLOR'.

  wa_layout2-box_fname  = 'SEL'.
*  wa_layout2-info_fname = 'LINE_COLOR'.
  wa_layout2-stylefname = 'FIELD_STYLE'.
*  wa_layout2-CWIDTH_OPT = 'X'.   "Begin of Changes - Madhu
  i_setting-edt_cll_cb  = 'X'.
  PERFORM var_non_cell_disable.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-cprog
      i_callback_pf_status_set = 'PF_STATUS_SET1'
      i_callback_user_command  = 'SAVE1'
      "Start of changes - Madhu
      i_callback_top_of_page   = 'TOP_OF_PAGE_NON'
      "End of changes - Madhu
      i_grid_settings          = i_setting
      is_layout_lvc            = wa_layout2
      it_fieldcat_lvc          = it_fcat2
      i_default                = 'X'
      i_save                   = 'U'
    TABLES
      t_outtab                 = it_final_non
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  REFRESH : it_fcat2.
*  wa_layout-info_fieldname     = 'LINE_COLOR'.
*  wa_layout-colwidth_optimize  = 'X'.
*
*  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
*    EXPORTING
*      i_callback_program = sy-cprog
*      is_layout          = wa_layout
*      it_fieldcat        = it_fcat
*      i_default          = 'X'
*      i_save             = 'U'
*    TABLES
*      t_outtab           = it_final_non
*    EXCEPTIONS
*      program_error      = 1
*      OTHERS             = 2.
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.

ENDFORM."alv_display_var_non
*********************" Added by Aparna Anand "*************************
FORM var_non_cell_disable .

  LOOP AT it_final_non INTO DATA(wa_non).
    IF wa_non-per CS ':' OR wa_non-per = ' ' OR wa_non-per = 'TOTAL INCOME' OR wa_non-per = 'TOTAL EXPENSE'
      OR wa_non-per = 'PROFIT BEFORE TAX' OR wa_non-per = 'NET PROFIT/(LOSS) AFTER TAX'.
      wa_stylerow-fieldname = 'REMARK'.
      wa_stylerow-style     = cl_gui_alv_grid=>mc_style_disabled.
      INSERT wa_stylerow INTO TABLE wa_non-field_style.
      MODIFY it_final_non FROM wa_non TRANSPORTING field_style.
      CLEAR wa_non.
    ELSE.
      wa_stylerow-fieldname = 'REMARK'.
      wa_stylerow-style     = cl_gui_alv_grid=>mc_style_enabled.
      INSERT wa_stylerow INTO TABLE wa_non-field_style.
      MODIFY it_final_non FROM wa_non TRANSPORTING field_style.
      CLEAR wa_non.
    ENDIF.
  ENDLOOP.

ENDFORM.
*-----------------------" Changes Begins by Aparna on 10.02.2024 "-----------------------------*
FORM pf_status_set1 USING rt_extab TYPE slis_t_extab.
  BREAK abapuser02.

  IF sy-ucomm = 'APPROVE'.

    CLEAR fcode.
    wa_fcode = 'LONGTEXT'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS1' EXCLUDING fcode.

  ELSEIF sy-ucomm = 'CREATE' OR   sy-ucomm = 'CHANGE' OR sy-ucomm = 'DISPLAY' .
    CLEAR fcode.
    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVEFI'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS1' EXCLUDING fcode.

  ELSEIF sy-ucomm = 'APPROVEFI'.

    CLEAR fcode.
    wa_fcode = 'LONGTEXT'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    wa_fcode = 'APPROVE'.
    APPEND wa_fcode TO fcode.
    CLEAR wa_fcode.

    SET PF-STATUS 'STATUS1' EXCLUDING fcode.
  ENDIF.

ENDFORM.
FORM save1 USING r_ucomm LIKE sy-ucomm
                rs_selfield TYPE slis_selfield.

  BREAK abapuser02.
  CASE sy-ucomm.
    WHEN 'SAVE' .
      PERFORM save_remarks1.
    WHEN 'LONGTEXT'.
      PERFORM edit_text1.
    WHEN 'APPROVE'.
      PERFORM approver1.
    WHEN 'APPROVEFI'.
      PERFORM approvefi.
    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EDIT_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM edit_text1 .
  LOOP AT it_final_non INTO DATA(wa_final_non1) WHERE sel = 'X'.
    CALL SCREEN 9001 STARTING AT 80 10 ENDING AT 140 20 .
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9000 OUTPUT.
  BREAK abapuser02.
  DATA : id       LIKE  thead-tdid,
         language LIKE  thead-tdspras,
         name     LIKE  thead-tdname,
         object   LIKE  thead-tdobject,
         it_lines TYPE TABLE OF tline.
  DATA lv_ucomm2 TYPE sy-ucomm.
  IF sy-ucomm = 'LONGTEXT'.
    CLEAR: g_editor, g_mycontainer, wa_texttable.
    REFRESH : i_texttable[].

    IF g_editor IS INITIAL.
      IMPORT lv_ucomm TO lv_ucomm2 FROM MEMORY ID 'A1'.
      IF lv_ucomm2 = 'DISPLAY'.
        SET PF-STATUS 'STATUS_T' EXCLUDING 'SAVE'.
      ELSE.
        SET PF-STATUS 'STATUS_T'.

      ENDIF.
      FREE MEMORY ID 'A1'.
      SET TITLEBAR 'TITLE2'.

      CREATE OBJECT g_editor_container
        EXPORTING
          container_name              = 'EDIT_CONT'
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.
      IF sy-subrc NE 0.
      ENDIF.
      g_mycontainer = 'EDIT_CONT'.

      CREATE OBJECT g_editor
        EXPORTING
          parent                     = g_editor_container
          wordwrap_mode              =
                                       cl_gui_textedit=>wordwrap_at_fixed_position
          wordwrap_position          = '50'
          wordwrap_to_linebreak_mode = cl_gui_textedit=>true.

      g_container_linked = 1.

      REFRESH g_mytable.

    ENDIF.


    CALL METHOD g_editor_container->link
      EXPORTING
        repid     = g_repid
        container = g_mycontainer.

    CALL METHOD g_editor->set_toolbar_mode
      EXPORTING
        toolbar_mode = cl_gui_textedit=>false.

    CALL METHOD g_editor->set_statusbar_mode
      EXPORTING
        statusbar_mode = cl_gui_textedit=>false.


    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.

    CALL METHOD g_editor->delete_text
      EXCEPTIONS
        error_cntl_call_method = 1                " Error while setting property of TextEdit control!
        OTHERS                 = 2.


    READ TABLE it_final_bar1 INTO wa_final_bar1 WITH KEY sel = 'X'.
    IF sy-subrc = 0.
      object = 'ZREMARK'.
      id = 'ZAD'.
      language = sy-langu.
*      name = wa_final_bar1-per.
      CONCATENATE p_proj1-low  s_period-low  s_period_low2  p_year1 wa_final_bar1-per INTO name.
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          client                  = sy-mandt
          id                      = id
          language                = language
          name                    = name
          object                  = object
        TABLES
          lines                   = it_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      IF it_lines IS NOT INITIAL.

        REFRESH: g_mytable,i_texttable.

        CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
          EXPORTING
            language    = sy-langu
          TABLES
            itf_text    = it_lines
            text_stream = i_texttable.

        CALL METHOD cl_gui_cfw=>flush
          EXCEPTIONS
            OTHERS = 1.

        IF sy-subrc NE 0.

        ENDIF.

        CALL METHOD g_editor->set_text_as_r3table
          EXPORTING
            table           = i_texttable                 " table with text
          EXCEPTIONS
            error_dp        = 1                " Error while sending R/3 table to TextEdit control!
            error_dp_create = 2                " ERROR_DP_CREATE
            OTHERS          = 3.

        IF sy-subrc <> 0.

        ENDIF.

        CALL METHOD g_editor->get_text_as_stream
          IMPORTING
            text                   = i_texttable        " text as stream with carrige retruns and linefeeds
            is_modified            = val1               " modify status of text
          EXCEPTIONS
            error_dp               = 1                  " Error while retrieving text table via DataProvider control!
            error_cntl_call_method = 2                  " Error while retrieving a property from TextEdit control
            OTHERS                 = 3.

        IF sy-subrc <> 0.

        ENDIF.
      ELSE.

        wa_texttable-line = wa_final_bar1-remark.
        APPEND wa_texttable TO i_texttable.
        CLEAR  wa_texttable.
      ENDIF.

      IF i_texttable IS NOT INITIAL.
        CALL METHOD g_editor->set_text_as_r3table
          EXPORTING
            table           = i_texttable                 " table with text
          EXCEPTIONS
            error_dp        = 1                " Error while sending R/3 table to TextEdit control!
            error_dp_create = 2                " ERROR_DP_CREATE
            OTHERS          = 3.
        IF sy-subrc <> 0.

        ENDIF.

        CALL METHOD g_editor->get_text_as_stream
          IMPORTING
            text                   = i_texttable        " text as stream with carrige retruns and linefeeds
            is_modified            = val1               " modify status of text
          EXCEPTIONS
            error_dp               = 1                  " Error while retrieving text table via DataProvider control!
            error_cntl_call_method = 2                  " Error while retrieving a property from TextEdit control
            OTHERS                 = 3.
        IF sy-subrc <> 0.

        ENDIF.

      ENDIF.

    ENDIF.
    REFRESH it_lines.
    CLEAR :id , object  ,name .
  ENDIF.
ENDMODULE.
**&---------------------------------------------------------------------*
**& Form editor_to_alv
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
FORM editor_to_alv1.

  DATA : wa_ahead LIKE thead,
         it_ltext TYPE TABLE OF tline.
  REFRESH : g_mytable.

  CALL METHOD g_editor->get_text_as_r3table
    IMPORTING
      table = g_mytable.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
  ENDIF.
  CLEAR val2.
  LOOP AT g_mytable INTO DATA(wa_mytable).
    CONCATENATE val2 wa_mytable INTO val2 SEPARATED BY space.
  ENDLOOP.

  IF val2 IS NOT INITIAL.
    READ TABLE it_final_non INTO wa_final_non WITH KEY sel = 'X'.
    IF sy-subrc = 0.
      wa_ahead-tdobject = 'ZREMARK1'.
      wa_ahead-tdid = 'ZAD1'.
      wa_ahead-tdspras = sy-langu.
      CONCATENATE p_proj1-low  s_period-low  s_period_low2  p_year1 wa_final_non-per INTO  wa_ahead-tdname.
*      wa_ahead-tdname = wa_final_non-per.
      REFRESH : i_texttable .
      CLEAR val1.
      CALL METHOD g_editor->get_text_as_stream
        IMPORTING
          text                   = i_texttable  " text as stream with carrige retruns and linefeeds
          is_modified            = val1   " modify status of text
        EXCEPTIONS
          error_dp               = 1
          error_cntl_call_method = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
*       MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      IF  i_texttable  IS NOT INITIAL.

        CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
          EXPORTING
*           STREAM_LINES       =
            language    = sy-langu
*           LF          = ' '
          TABLES
            text_stream = i_texttable
            itf_text    = it_ltext.
      ENDIF.
      IF it_ltext IS NOT INITIAL.
        CALL FUNCTION 'SAVE_TEXT'
          EXPORTING
            client          = sy-mandt
            header          = wa_ahead
            insert          = ''
            savemode_direct = 'X'
            owner_specified = ' '
          TABLES
            lines           = it_ltext
          EXCEPTIONS
            id              = 1
            language        = 2
            name            = 3
            object          = 4
            OTHERS          = 5.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

      ENDIF.

      wa_final_non-remark = val2.
      MODIFY it_final_non FROM wa_final_non TRANSPORTING remark WHERE sel = 'X'.
      IF sy-subrc = 0.
        CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
          IMPORTING
            e_grid = l_grid.

*        l_grid->check_changed_data(
*          IMPORTING
*            e_valid   = DATA(l_valid)                 " Entries are Consistent
*        ).
*        IF l_valid IS NOT INITIAL.

        l_grid->refresh_table_display(
          EXCEPTIONS
            finished       = 1                " Display was Ended (by Export)
            OTHERS         = 2
        ).


*        ENDIF.
      ENDIF.

    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.

*  BREAK-POINT.
  CASE sy-ucomm.
    WHEN 'CLOSE'.
      PERFORM clear_container.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM editor_to_alv.
      PERFORM clear_container.
      LEAVE TO SCREEN 0.

    WHEN OTHERS.
  ENDCASE.

ENDMODULE.
**&---------------------------------------------------------------------*
**&      Form  SAVE_REMARKS
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
FORM save_remarks1 .
  BREAK abapuser02.
  DATA(it_final_non_temp) = it_final_non[].
  DELETE it_final_non_temp WHERE per = ' ' .
  "Begin of Changes     "Madhu
  DELETE it_final_non_temp WHERE per = 'TOTAL INCOME' .
  DELETE it_final_non_temp WHERE per = 'TOTAL EXPENSE' .
  DELETE it_final_non_temp WHERE per = 'PROFIT BEFORE TAX' .
  DELETE it_final_non_temp WHERE per = 'NET PROFIT/(LOSS) AFTER TAX' .
  "End of Changes
  CLEAR wa_final_non.

  LOOP AT it_final_non_temp INTO wa_final_non.
    IF wa_final_non-remark IS INITIAL  .
*      MESSAGE 'Please fill remarks in all columns. ' TYPE 'E'.
      MESSAGE 'Remarks column cannot be left blank. ' TYPE 'E'.
    ENDIF.
  ENDLOOP.
  LOOP AT it_final_non_temp INTO wa_final_non WHERE sel  = 'X'.
    IF  wa_final_non-per IS NOT INITIAL.
      IF wa_final_non-remark IS INITIAL  .

*        MESSAGE 'Please fill remarks in all columns. ' TYPE 'E'.
        MESSAGE 'Remarks column cannot be left blank. ' TYPE 'E'.
      ELSE.
        wa_zfi_pl_var_non-mandt  = sy-mandt.
        wa_zfi_pl_var_non-per    = wa_final_non-per.

        CONDENSE wa_final_non-remark.
        wa_zfi_pl_var_non-remark = wa_final_non-remark.
        wa_zfi_pl_var_non-period = s_period-low.
        wa_zfi_pl_var_non-period2 =  s_period_low2.
        wa_zfi_pl_var_non-fiscal = p_year1.
        wa_zfi_pl_var_non-proj = p_proj1-low.
        wa_zfi_pl_var_non-comp = p_comp1.
        APPEND wa_zfi_pl_var_non TO  it_zfi_non  .
        CLEAR  wa_zfi_pl_var_non.

      ENDIF.
    ENDIF.
  ENDLOOP .
  MODIFY zfi_pl_var_non FROM TABLE it_zfi_non.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Remark Saved Successfully' TYPE 'S'.
    CLEAR: wa_zfi_pl_var_non, wa_final_non.
    REFRESH : it_zfi_non , it_final_non_temp .
  ENDIF.

  wa_zfi_status1-mandt  = sy-mandt.
  wa_zfi_status1-period = s_period-low.
  wa_zfi_status1-period2 = s_period_low2.
  wa_zfi_status1-fiscal = p_year1.
  wa_zfi_status1-fiscal2 = p_year2.
  wa_zfi_status1-proj = p_proj1-low.
  wa_zfi_status1-comp = p_comp1.
  wa_zfi_status1-p_compy1 = p_compy1.

  wa_zfi_status1-status_cre = 'X'.
  wa_zfi_status1-created_by = sy-uname.
  wa_zfi_status1-created_on = sy-datum.

  APPEND wa_zfi_status1 TO  it_zfi_status1  .
  CLEAR  wa_zfi_status1.

  MODIFY zfi_pl_status_n FROM TABLE it_zfi_status1.

  CLEAR: wa_zfi_status1.
  REFRESH : it_zfi_status1.

*  ENDIF.

ENDFORM.
**&---------------------------------------------------------------------*
**& Form clear_container
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM clear_container .
*
*  CALL METHOD g_editor_container->free
*    EXCEPTIONS
*      cntl_error        = 1                " CNTL_ERROR
*      cntl_system_error = 2                " CNTL_SYSTEM_ERROR
*      OTHERS            = 3.
*
*  CALL METHOD g_editor->free
*    EXCEPTIONS
*      cntl_error        = 1                " CNTL_ERROR
*      cntl_system_error = 2                " CNTL_SYSTEM_ERROR
*      OTHERS            = 3.
*
*  FREE: g_editor, g_editor_container.
*
*ENDFORM.

*-----------------------" Chnages Ended  by Aparna on 10.02.2024 "-----------------------------*
*************************end by aparna
FORM conv_fact_chk.  "Check to restrict the conversion factors within the given range

  IF ( sy-ucomm = 'CALC' ) OR ( sy-ucomm = 'SAVE' ).

    IF ton_bbl LT '6.000000' OR ton_bbl GT '9.000000'.
      CLEAR sy-ucomm.
      MESSAGE 'Conversion factor input "Tonnes To BBL " is beyond the range . Range 6.000000 to 9.000000'  TYPE 'E'.
    ENDIF.
    IF mmscm_mmbtu LT '0.034' OR mmscm_mmbtu GT '0.039'.
      CLEAR sy-ucomm.
      MESSAGE 'Conversion factor input "MMSCM  to MMBTU " is beyond the range. Range 0.039 to 0.034' TYPE 'E'.
    ENDIF.

  ENDIF.

ENDFORM."CONV_FACT_CHK.

FORM cre_per_barl.

  DATA : net_slrl_oil1(15) TYPE c,    net_slrl_oil2(15) TYPE c,   net_slrl_oil3(15) TYPE c,   net_slrl_oil4(15) TYPE c, "Net Sales Realisation(I)
         net_slrl_gas1(15) TYPE c,    net_slrl_gas2(15) TYPE c,   net_slrl_gas3(15) TYPE c,   net_slrl_gas4(15) TYPE c,

         tot_oprx_oil1(15) TYPE c,    tot_oprx_oil2(15) TYPE c,   tot_oprx_oil3(15) TYPE c,   tot_oprx_oil4(15) TYPE c, "Total Operating Expenses(II)
         tot_oprx_gas1(15) TYPE c,    tot_oprx_gas2(15) TYPE c,   tot_oprx_gas3(15) TYPE c,   tot_oprx_gas4(15) TYPE c,

         tot_dda_oil1(15)  TYPE c,     tot_dda_oil2(15) TYPE c,    tot_dda_oil3(15) TYPE c,    tot_dda_oil4(15) TYPE c, "Total DDA & Exploration(III)
         tot_dda_gas1(15)  TYPE c,     tot_dda_gas2(15) TYPE c,    tot_dda_gas3(15) TYPE c,    tot_dda_gas4(15) TYPE c,

         god_sld_oil1(15)  TYPE c,     god_sld_oil2(15) TYPE c,    god_sld_oil3(15) TYPE c,    god_sld_oil4(15) TYPE c, "Cost of Goods Sold VII(V+VI+VII)
         god_sld_gas1(15)  TYPE c,     god_sld_gas2(15) TYPE c,    god_sld_gas3(15) TYPE c,    god_sld_gas4(15) TYPE c,

         net_rev_oil1(15)  TYPE c,     net_rev_oil2(15) TYPE c,    net_rev_oil3(15) TYPE c,    net_rev_oil4(15) TYPE c, "Net Operating margin VIII (I-VII)
         net_rev_gas1(15)  TYPE c,     net_rev_gas2(15) TYPE c,    net_rev_gas3(15) TYPE c,    net_rev_gas4(15) TYPE c,

         tot_otin_oil1(15) TYPE c,    tot_otin_oil2(15) TYPE c,   tot_otin_oil3(15) TYPE c,   tot_otin_oil4(15) TYPE c, "Total Other Income/ Expense (IX)
         tot_otin_gas1(15) TYPE c,    tot_otin_gas2(15) TYPE c,   tot_otin_gas3(15) TYPE c,   tot_otin_gas4(15) TYPE c,

         net_btax_oil1(15) TYPE c,    net_btax_oil2(15) TYPE c,   net_btax_oil3(15) TYPE c,   net_btax_oil4(15) TYPE c, "Net Profit Before Tax X (VIII-IX)
         net_btax_gas1(15) TYPE c,    net_btax_gas2(15) TYPE c,   net_btax_gas3(15) TYPE c,   net_btax_gas4(15) TYPE c,

         in_tax_oil1(15)   TYPE c,      in_tax_oil2(15) TYPE c,     in_tax_oil3(15) TYPE c,     in_tax_oil4(15) TYPE c, "Income Tax (XI) (20%)
         in_tax_gas1(15)   TYPE c,      in_tax_gas2(15) TYPE c,     in_tax_gas3(15) TYPE c,     in_tax_gas4(15) TYPE c,

         imploss_oil1(15)  TYPE c,     imploss_oil2(15) TYPE c,    imploss_oil3(15) TYPE c,    imploss_oil4(15) TYPE c, "Impairment loss/(reversal)
         imploss_gas1(15)  TYPE c,     imploss_gas2(15) TYPE c,    imploss_gas3(15) TYPE c,    imploss_gas4(15) TYPE c,

         net_atax_oil1(15) TYPE c,    net_atax_oil2(15) TYPE c,   net_atax_oil3(15) TYPE c,   net_atax_oil4(15) TYPE c, "Net Profit/(Loss) after tax XII (X-XI)
         net_atax_gas1(15) TYPE c,    net_atax_gas2(15) TYPE c,   net_atax_gas3(15) TYPE c,   net_atax_gas4(15) TYPE c,

         oth_tax_oil1(15)  TYPE c,     oth_tax_oil2(15) TYPE c,   oth_tax_oil3(15) TYPE c,    oth_tax_oil4(15) TYPE c, " other tax if applicable
         oth_tax_gas1(15)  TYPE c,     oth_tax_gas2(15) TYPE c,   oth_tax_gas3(15) TYPE c,    oth_tax_gas4(15) TYPE c.

  CLEAR wa_final_bar.

  IF it_final_bar1[] IS NOT INITIAL.

    DATA : lv_sh_lift1 TYPE zpnl_qi_oil-sh_lift,
           lv_sh_lift2 TYPE zpnl_qi_oil-sh_lift.

    REFRESH it_final_per_bar[].
    CLEAR wa_final_per_bar.
    LOOP AT it_final_bar1 INTO DATA(wa_per_bar).

      wa_final_per_bar-per  = wa_per_bar-per.
      wa_final_per_bar-oil1 = wa_per_bar-oil1.
      wa_final_per_bar-oil2 = wa_per_bar-oil2.
      wa_final_per_bar-oil3 = wa_per_bar-oil3.
      wa_final_per_bar-oil4 = wa_per_bar-oil4.

      wa_final_per_bar-gas1 = wa_per_bar-gas1.
      wa_final_per_bar-gas2 = wa_per_bar-gas2.
      wa_final_per_bar-gas3 = wa_per_bar-gas3.
      wa_final_per_bar-gas4 = wa_per_bar-gas4.

      APPEND wa_final_per_bar TO it_final_per_bar.
      CLEAR : wa_final_per_bar,wa_per_bar.
    ENDLOOP.

    CLEAR : wa_assoct_gas1,wa_assoct_gas2,wa_assoct_gas3,wa_assoct_gas4.

    IF peri1_2 EQ s_period-low AND s_period-low IS NOT INITIAL.
      READ TABLE it_assoct_gas INTO wa_assoct_gas1 WITH KEY fisyear = p_year1 zperiod = s_period-low.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv1) WITH KEY fisyear = p_year1 zperiod = s_period-low.

      wa_assoct_gas1-sh_prod = wa_assoct_gas1-sh_prod * wa_assoct_cnv1-mmscm_mmbtu.
      wa_assoct_gas1-sh_lift = ( wa_assoct_gas1-tot_sal - wa_assoct_gas1-sh_lift ) * wa_assoct_cnv1-mmscm_mmbtu.

    ELSEIF s_period-low IS NOT INITIAL.
      READ TABLE it_assoct_cnv INTO wa_assoct_cnv1 WITH KEY fisyear = p_year1 zperiod = peri1_2.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

      READ TABLE it_assoct_gas INTO wa_assoct_gas1 WITH KEY fisyear = p_year1 zperiod = peri1_2.
      READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas1_1) WITH KEY fisyear = p_year1 zperiod = peri1_1.

      IF wa_assoct_gas1 IS NOT INITIAL.
        wa_assoct_gas1-sh_prod = ( wa_assoct_gas1-sh_prod * wa_assoct_cnv1-mmscm_mmbtu ) - ( wa_assoct_gas1_1-sh_prod * wa_assoct_cnv1_1-mmscm_mmbtu ).

        CLEAR : lv_sh_lift1,lv_sh_lift2.
        lv_sh_lift1 = ( wa_assoct_gas1-tot_sal - wa_assoct_gas1-sh_lift ) * wa_assoct_cnv1-mmscm_mmbtu.
        lv_sh_lift2 = ( wa_assoct_gas1_1-tot_sal - wa_assoct_gas1_1-sh_lift ) * wa_assoct_cnv1_1-mmscm_mmbtu.

        wa_assoct_gas1-sh_lift = lv_sh_lift1 - lv_sh_lift2.

      ENDIF.
    ENDIF.

    IF peri2_2 EQ s_period_low2 AND s_period_low2 IS NOT INITIAL.
      READ TABLE it_assoct_gas INTO wa_assoct_gas2 WITH KEY fisyear = p_year2 zperiod = s_period_low2.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv2) WITH KEY fisyear = p_year2 zperiod = s_period_low2.

      wa_assoct_gas2-sh_prod = wa_assoct_gas2-sh_prod * wa_assoct_cnv2-mmscm_mmbtu.
      wa_assoct_gas2-sh_lift =  ( wa_assoct_gas2-tot_sal - wa_assoct_gas2-sh_lift ) * wa_assoct_cnv2-mmscm_mmbtu.

    ELSEIF s_period_low2 IS NOT INITIAL.
      READ TABLE it_assoct_cnv INTO wa_assoct_cnv2 WITH KEY fisyear = p_year1 zperiod = peri2_2.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv2_1) WITH KEY fisyear = p_year1 zperiod = peri2_1.

      READ TABLE it_assoct_gas INTO wa_assoct_gas2 WITH KEY fisyear = p_year1 zperiod = peri2_2.
      READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas2_1) WITH KEY fisyear = p_year1 zperiod = peri2_1.

      IF wa_assoct_gas2 IS NOT INITIAL.
        wa_assoct_gas2-sh_prod = ( wa_assoct_gas2-sh_prod * wa_assoct_cnv2-mmscm_mmbtu ) - ( wa_assoct_gas2_1-sh_prod * wa_assoct_cnv2_1-mmscm_mmbtu ).

        CLEAR : lv_sh_lift1,lv_sh_lift2.
        lv_sh_lift1 = ( wa_assoct_gas2-tot_sal - wa_assoct_gas2-sh_lift ) * wa_assoct_cnv2-mmscm_mmbtu.
        lv_sh_lift2 = ( wa_assoct_gas2_1-tot_sal - wa_assoct_gas2_1-sh_lift ) * wa_assoct_cnv2_1-mmscm_mmbtu.

        wa_assoct_gas2-sh_lift = lv_sh_lift1 - lv_sh_lift2.

      ENDIF.
    ENDIF.

    IF peri3_2 EQ s_period_low3 AND s_period_low3 IS NOT INITIAL.
      READ TABLE it_assoct_gas INTO wa_assoct_gas3 WITH KEY fisyear = p_year3 zperiod = s_period_low3.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv3) WITH KEY fisyear = p_year3 zperiod = s_period_low3.

      wa_assoct_gas3-sh_prod = wa_assoct_gas3-sh_prod * wa_assoct_cnv3-mmscm_mmbtu.
      wa_assoct_gas3-sh_lift =  ( wa_assoct_gas3-tot_sal - wa_assoct_gas3-sh_lift ) * wa_assoct_cnv3-mmscm_mmbtu.

    ELSEIF s_period_low3 IS NOT INITIAL.
      READ TABLE it_assoct_cnv INTO wa_assoct_cnv3 WITH KEY fisyear = p_year3 zperiod = peri3_2.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv3_1) WITH KEY fisyear = p_year3 zperiod = peri3_1.

      READ TABLE it_assoct_gas INTO wa_assoct_gas3 WITH KEY fisyear = p_year3 zperiod = peri3_2.
      READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas3_1) WITH KEY fisyear = p_year3 zperiod = peri3_1.

      IF wa_assoct_gas3 IS NOT INITIAL.
        wa_assoct_gas3-sh_prod = ( wa_assoct_gas3-sh_prod * wa_assoct_cnv3-mmscm_mmbtu ) - ( wa_assoct_gas3_1-sh_prod * wa_assoct_cnv3_1-mmscm_mmbtu ).

        CLEAR : lv_sh_lift1,lv_sh_lift2.
        lv_sh_lift1 = ( wa_assoct_gas3-tot_sal - wa_assoct_gas3-sh_lift ) * wa_assoct_cnv3-mmscm_mmbtu.
        lv_sh_lift2 = ( wa_assoct_gas3_1-tot_sal - wa_assoct_gas3_1-sh_lift ) * wa_assoct_cnv3_1-mmscm_mmbtu.

        wa_assoct_gas3-sh_lift = lv_sh_lift1 - lv_sh_lift2.

      ENDIF.
    ENDIF.

    IF peri4_2 EQ s_period_low4 AND s_period_low4 IS NOT INITIAL.
      READ TABLE it_assoct_gas INTO wa_assoct_gas4 WITH KEY fisyear = p_year4 zperiod = s_period_low4.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv4) WITH KEY fisyear = p_year4 zperiod = s_period_low4.

      wa_assoct_gas4-sh_prod = wa_assoct_gas4-sh_prod * wa_assoct_cnv4-mmscm_mmbtu.
      wa_assoct_gas4-sh_lift =  ( wa_assoct_gas4-tot_sal - wa_assoct_gas4-sh_lift ) * wa_assoct_cnv4-mmscm_mmbtu.

    ELSEIF s_period_low4 IS NOT INITIAL.
      READ TABLE it_assoct_cnv INTO wa_assoct_cnv4 WITH KEY fisyear = p_year4 zperiod = peri4_2.
      READ TABLE it_assoct_cnv INTO DATA(wa_assoct_cnv4_1) WITH KEY fisyear = p_year4 zperiod = peri4_1.

      READ TABLE it_assoct_gas INTO wa_assoct_gas4 WITH KEY fisyear = p_year4 zperiod = peri4_2.
      READ TABLE it_assoct_gas INTO DATA(wa_assoct_gas4_1) WITH KEY fisyear = p_year4 zperiod = peri4_1.

      IF wa_assoct_gas4 IS NOT INITIAL.
        wa_assoct_gas4-sh_prod = ( wa_assoct_gas4-sh_prod * wa_assoct_cnv4-mmscm_mmbtu ) - ( wa_assoct_gas4_1-sh_prod * wa_assoct_cnv4_1-mmscm_mmbtu ).

        CLEAR : lv_sh_lift1,lv_sh_lift2.
        lv_sh_lift1 = ( wa_assoct_gas4-tot_sal - wa_assoct_gas4-sh_lift ) * wa_assoct_cnv4-mmscm_mmbtu.
        lv_sh_lift2 = ( wa_assoct_gas4_1-tot_sal - wa_assoct_gas4_1-sh_lift ) * wa_assoct_cnv4_1-mmscm_mmbtu.

        wa_assoct_gas4-sh_lift = lv_sh_lift1 - lv_sh_lift2.

      ENDIF.
    ENDIF.

  ENDIF.

  PERFORM check_alloc_values . ""Check weather the values are not zero to avoid divide by zero error

  LOOP AT it_final_per_bar INTO wa_final_per_bar.
    CASE sy-tabix.

      WHEN 1."Revenue from Crude Oil

        net_slrl_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        net_slrl_oil2 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        net_slrl_oil3 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        net_slrl_oil4 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.

      WHEN 2."Revenue from Natural Gas

        net_slrl_gas1 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        net_slrl_gas2 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        net_slrl_gas3 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        net_slrl_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 3."Less: Profit Oil paid in cash

        wa_final_per_bar-oilp1 = net_slrl_oil1 .
        wa_final_per_bar-gasp1 = net_slrl_gas1 .
        wa_final_per_bar-oilp2 = net_slrl_oil2 .
        wa_final_per_bar-gasp2 = net_slrl_gas2 .
        wa_final_per_bar-oilp3 = net_slrl_oil3 .
        wa_final_per_bar-gasp3 = net_slrl_gas3 .
        wa_final_per_bar-oilp4 = net_slrl_oil4 .
        wa_final_per_bar-gasp4 = net_slrl_gas4 .

      WHEN 4."Sale of VAP

      WHEN 5."Other Operating Revenue

      WHEN 6."Net Sales Realisation(I)

        wa_final_per_bar-oilp1 = net_slrl_oil1 .
        wa_final_per_bar-gasp1 = net_slrl_gas1 .
        wa_final_per_bar-oilp2 = net_slrl_oil2 .
        wa_final_per_bar-gasp2 = net_slrl_gas2 .
        wa_final_per_bar-oilp3 = net_slrl_oil3 .
        wa_final_per_bar-gasp3 = net_slrl_gas3 .
        wa_final_per_bar-oilp4 = net_slrl_oil4 .
        wa_final_per_bar-gasp4 = net_slrl_gas4 .

*      When 8."Operating Expenses:
      WHEN 9."Royalty

        tot_oprx_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        tot_oprx_gas1 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        tot_oprx_oil2 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        tot_oprx_gas2 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        tot_oprx_oil3 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        tot_oprx_gas3 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        tot_oprx_oil4 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        tot_oprx_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

      WHEN 10."Other taxes(as applicable)


****************** code added by sandeep as on 18.01.2024*****************


        READ TABLE it_final_bar1 INTO DATA(wa_final_bar11) INDEX 10.
        READ TABLE it_pro_ana INTO DATA(wa_pro_ana1) INDEX 6.

        IF wa_pro_ana1-oil1  <> 0.
          wa_final_per_bar-oilp1 =  ( ( wa_final_bar11-oil1 * 1000000 ) / wa_pro_ana1-oil1 ).
          oth_tax_oil1 = wa_final_per_bar-oilp1.
        ELSE.
          wa_final_per_bar-oilp1 =   ( wa_final_bar11-oil1 * 1000000 ).
          oth_tax_oil1 = wa_final_per_bar-oilp1.
        ENDIF.
        IF  wa_pro_ana1-oil2 <> 0.
          wa_final_per_bar-oilp2 =  ( ( wa_final_bar11-oil2 * 1000000 ) / wa_pro_ana1-oil2 ).
          oth_tax_oil2 = wa_final_per_bar-oilp2.
        ELSE.
          wa_final_per_bar-oilp2 =   ( wa_final_bar11-oil2 * 1000000 ).
          oth_tax_oil2 = wa_final_per_bar-oilp2.
        ENDIF.
        IF wa_pro_ana1-oil3 <> 0.
          wa_final_per_bar-oilp3 =  ( ( wa_final_bar11-oil3 * 1000000 ) / wa_pro_ana1-oil3 ).
          oth_tax_oil3 = wa_final_per_bar-oilp3.
        ELSE.
          wa_final_per_bar-oilp3 =   ( wa_final_bar11-oil3 * 1000000 ).
          oth_tax_oil3 = wa_final_per_bar-oilp3.
        ENDIF.
        IF wa_pro_ana1-oil4 <> 0.
          wa_final_per_bar-oilp4 =  ( ( wa_final_bar11-oil4 * 1000000 ) / wa_pro_ana1-oil4 ).
          oth_tax_oil4 = wa_final_per_bar-oilp4.
        ELSE.
          wa_final_per_bar-oilp4 =  ( wa_final_bar11-oil4 * 1000000 ).
          oth_tax_oil4 = wa_final_per_bar-oilp4.
        ENDIF.

****************** code added by sandeep as on 18.01.2024*****************

*-----------------------" Changes begins by Aparna Anand on 18.07.2024 "-------------------------*

        IF wa_pro_ana1-gas1  <> 0.
          wa_final_per_bar-gasp1 =   ( wa_final_bar11-gas1  / wa_pro_ana1-gas1 ).
          oth_tax_gas1 = wa_final_per_bar-gasp1.
        ELSE.
          wa_final_per_bar-gasp1 =    wa_final_bar11-gas1 .
          oth_tax_gas1 = wa_final_per_bar-gasp1.
        ENDIF.
        IF  wa_pro_ana1-gas2 <> 0.
          wa_final_per_bar-gasp2 =   ( wa_final_bar11-gas2  / wa_pro_ana1-gas2 ).
          oth_tax_gas2 = wa_final_per_bar-gasp2.
        ELSE.
          wa_final_per_bar-gasp2 =    wa_final_bar11-gas2 .
          oth_tax_gas2 = wa_final_per_bar-gasp2.
        ENDIF.
        IF wa_pro_ana1-gas3 <> 0.
          wa_final_per_bar-gasp3 =  (  wa_final_bar11-gas3  / wa_pro_ana1-gas3 ).
          oth_tax_gas3 = wa_final_per_bar-gasp3.
        ELSE.
          wa_final_per_bar-gasp3 =    wa_final_bar11-gas3 .
          oth_tax_gas3 = wa_final_per_bar-gasp3.
        ENDIF.
        IF wa_pro_ana1-gas4 <> 0.
          wa_final_per_bar-gasp4 =   ( wa_final_bar11-gas4  / wa_pro_ana1-gas4 ).
          oth_tax_gas4 = wa_final_per_bar-gasp4.
        ELSE.
          wa_final_per_bar-gasp4 =   wa_final_bar11-gas4 .
          oth_tax_gas4 = wa_final_per_bar-gasp4.
        ENDIF.

*-----------------------" Changes ended  by Aparna Anand on 18.07.2024 "-------------------------*

*       WA_FINAL_PER_BAR-OILP1 =  ( ( WA_FINAL_BAR11-OIL1 * 1000000 ) / WA_FINAL_BAR3-OIL1 ).
*       WA_FINAL_PER_BAR-OILP2 =  ( ( WA_FINAL_BAR11-OIL2 * 1000000 ) / WA_FINAL_BAR3-OIL2 ).
*       WA_FINAL_PER_BAR-OILP3 =  ( ( WA_FINAL_BAR11-OIL3 * 1000000 ) / WA_FINAL_BAR3-OIL3 ).
*       WA_FINAL_PER_BAR-OILP4 =  ( ( WA_FINAL_BAR11-OIL4 * 1000000 ) / WA_FINAL_BAR3-OIL4 ).

****************** code added by sandeep as on 18.01.2024*****************

*        TOT_OPRX_OIL1 = WA_FINAL_PER_BAR-OILP1 = WA_FINAL_PER_BAR-OIL1 / WA_ASSOCT_OIL1-SH_PROD.
*        TOT_OPRX_GAS1 = WA_FINAL_PER_BAR-GASP1 = WA_FINAL_PER_BAR-GAS1 / WA_ASSOCT_GAS1-SH_PROD.
*        TOT_OPRX_OIL2 = WA_FINAL_PER_BAR-OILP2 = WA_FINAL_PER_BAR-OIL2 / WA_ASSOCT_OIL2-SH_PROD.
*        TOT_OPRX_GAS2 = WA_FINAL_PER_BAR-GASP2 = WA_FINAL_PER_BAR-GAS2 / WA_ASSOCT_GAS2-SH_PROD.
*        TOT_OPRX_OIL3 = WA_FINAL_PER_BAR-OILP3 = WA_FINAL_PER_BAR-OIL3 / WA_ASSOCT_OIL3-SH_PROD.
*        TOT_OPRX_GAS3 = WA_FINAL_PER_BAR-GASP3 = WA_FINAL_PER_BAR-GAS3 / WA_ASSOCT_GAS3-SH_PROD.
*        TOT_OPRX_OIL4 = WA_FINAL_PER_BAR-OILP4 = WA_FINAL_PER_BAR-OIL4 / WA_ASSOCT_OIL4-SH_PROD.
*        TOT_OPRX_GAS4 = WA_FINAL_PER_BAR-GASP4 = WA_FINAL_PER_BAR-GAS4 / WA_ASSOCT_GAS4-SH_PROD.




****************** code added by sandeep as on 18.01.2024*****************

      WHEN 11."Production expense

        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_per_bar-oilp1.
        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_per_bar-gasp1.
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_per_bar-oilp2.
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_per_bar-gasp2.
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_per_bar-oilp3.
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_per_bar-gasp3.
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_per_bar-oilp4.
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_per_bar-gasp4.

      WHEN 12."Other Operating Expenses

        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_per_bar-oilp1.
        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_per_bar-gasp1.
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_per_bar-oilp2.
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_per_bar-gasp2.
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_per_bar-oilp3.
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_per_bar-gasp3.
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_per_bar-oilp4.
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_per_bar-gasp4.

      WHEN 13."Transportation expense

        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.

        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

        tot_oprx_oil1 = tot_oprx_oil1 + wa_final_per_bar-oilp1.
        tot_oprx_gas1 = tot_oprx_gas1 + wa_final_per_bar-gasp1.
        tot_oprx_oil2 = tot_oprx_oil2 + wa_final_per_bar-oilp2.
        tot_oprx_gas2 = tot_oprx_gas2 + wa_final_per_bar-gasp2.
        tot_oprx_oil3 = tot_oprx_oil3 + wa_final_per_bar-oilp3.
        tot_oprx_gas3 = tot_oprx_gas3 + wa_final_per_bar-gasp3.
        tot_oprx_oil4 = tot_oprx_oil4 + wa_final_per_bar-oilp4.
        tot_oprx_gas4 = tot_oprx_gas4 + wa_final_per_bar-gasp4.

      WHEN 14."Internal consumption of Gas

      WHEN 15."Total Operating Expenses(II)

        READ TABLE it_final_per_bar INTO DATA(ls_final_per_bar) INDEX 10.  "" ADDN BY SANDEEP AS ON 08.02.2024 TO ADD OTHER TAXES VALUE

        wa_final_per_bar-oilp1 = tot_oprx_oil1 + ls_final_per_bar-oilp1.
        wa_final_per_bar-gasp1 = tot_oprx_gas1 + ls_final_per_bar-gasp1.
        wa_final_per_bar-oilp2 = tot_oprx_oil2 + ls_final_per_bar-oilp2.
        wa_final_per_bar-gasp2 = tot_oprx_gas2 + ls_final_per_bar-gasp2.
        wa_final_per_bar-oilp3 = tot_oprx_oil3 + ls_final_per_bar-oilp3.
        wa_final_per_bar-gasp3 = tot_oprx_gas3 + ls_final_per_bar-gasp3.
        wa_final_per_bar-oilp4 = tot_oprx_oil4 + ls_final_per_bar-oilp4.
        wa_final_per_bar-gasp4 = tot_oprx_gas4 + ls_final_per_bar-gasp4.

        CLEAR ls_final_per_bar.

*      When 17."DDA & Exploration:
      WHEN 18."Depletion

        tot_dda_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        tot_dda_gas1 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        tot_dda_oil2 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        tot_dda_gas2 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        tot_dda_oil3 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        tot_dda_gas3 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        tot_dda_oil4 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        tot_dda_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

      WHEN 19."Depreciation and Amortisation

        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

        tot_dda_oil1 = tot_dda_oil1 + wa_final_per_bar-oilp1.
        tot_dda_gas1 = tot_dda_gas1 + wa_final_per_bar-gasp1.
        tot_dda_oil2 = tot_dda_oil2 + wa_final_per_bar-oilp2.
        tot_dda_gas2 = tot_dda_gas2 + wa_final_per_bar-gasp2.
        tot_dda_oil3 = tot_dda_oil3 + wa_final_per_bar-oilp3.
        tot_dda_gas3 = tot_dda_gas3 + wa_final_per_bar-gasp3.
        tot_dda_oil4 = tot_dda_oil4 + wa_final_per_bar-oilp4.
        tot_dda_gas4 = tot_dda_gas4 + wa_final_per_bar-gasp4.


      WHEN 20."Exploration Costs (Survey)

        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

        tot_dda_oil1 = tot_dda_oil1 + wa_final_per_bar-oilp1.
        tot_dda_gas1 = tot_dda_gas1 + wa_final_per_bar-gasp1.
        tot_dda_oil2 = tot_dda_oil2 + wa_final_per_bar-oilp2.
        tot_dda_gas2 = tot_dda_gas2 + wa_final_per_bar-gasp2.
        tot_dda_oil3 = tot_dda_oil3 + wa_final_per_bar-oilp3.
        tot_dda_gas3 = tot_dda_gas3 + wa_final_per_bar-gasp3.
        tot_dda_oil4 = tot_dda_oil4 + wa_final_per_bar-oilp4.
        tot_dda_gas4 = tot_dda_gas4 + wa_final_per_bar-gasp4.

      WHEN 21."EXPLORATION COSTS(DRY WELL)

        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_prod.
        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_prod.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_prod.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_prod.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_prod.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_prod.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_prod.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_prod.

        tot_dda_oil1 = tot_dda_oil1 + wa_final_per_bar-oilp1.
        tot_dda_gas1 = tot_dda_gas1 + wa_final_per_bar-gasp1.
        tot_dda_oil2 = tot_dda_oil2 + wa_final_per_bar-oilp2.
        tot_dda_gas2 = tot_dda_gas2 + wa_final_per_bar-gasp2.
        tot_dda_oil3 = tot_dda_oil3 + wa_final_per_bar-oilp3.
        tot_dda_gas3 = tot_dda_gas3 + wa_final_per_bar-gasp3.
        tot_dda_oil4 = tot_dda_oil4 + wa_final_per_bar-oilp4.
        tot_dda_gas4 = tot_dda_gas4 + wa_final_per_bar-gasp4.

      WHEN 22."Total DDA & Exploration(III)

        wa_final_per_bar-oilp1 = tot_dda_oil1.
        wa_final_per_bar-gasp1 = tot_dda_gas1.
        wa_final_per_bar-oilp2 = tot_dda_oil2.
        wa_final_per_bar-gasp2 = tot_dda_gas2.
        wa_final_per_bar-oilp3 = tot_dda_oil3.
        wa_final_per_bar-gasp3 = tot_dda_gas3.
        wa_final_per_bar-oilp4 = tot_dda_oil4.
        wa_final_per_bar-gasp4 = tot_dda_gas4.

      WHEN 24."OPERATING COST (IV)

        wa_final_per_bar-oilp1 = tot_oprx_oil1 + tot_dda_oil1 + oth_tax_oil1.
        wa_final_per_bar-gasp1 = tot_oprx_gas1 + tot_dda_gas1 + oth_tax_gas1.
        wa_final_per_bar-oilp2 = tot_oprx_oil2 + tot_dda_oil2 + oth_tax_oil2.
        wa_final_per_bar-gasp2 = tot_oprx_gas2 + tot_dda_gas2 + oth_tax_gas2.
        wa_final_per_bar-oilp3 = tot_oprx_oil3 + tot_dda_oil3 + oth_tax_oil3.
        wa_final_per_bar-gasp3 = tot_oprx_gas3 + tot_dda_gas3 + oth_tax_gas3.
        wa_final_per_bar-oilp4 = tot_oprx_oil4 + tot_dda_oil4 + oth_tax_oil4.
        wa_final_per_bar-gasp4 = tot_oprx_gas4 + tot_dda_gas4 + oth_tax_gas4.

*      WHEN 25."Adjustment for cost of sales:
      WHEN 26 ."Change in inventories (V)

      WHEN 27."Overlift/(Underlift) (VI)

      WHEN 28."Cost of Goods Sold VII(IV+V+VI)

        god_sld_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        god_sld_gas1 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        god_sld_oil2 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        god_sld_gas2 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        god_sld_oil3 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        god_sld_gas3 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        god_sld_oil4 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.
        god_sld_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 30."Net Operating margin VIII (I-VII)

        net_rev_oil1 = wa_final_per_bar-oilp1 = net_slrl_oil1 - god_sld_oil1.
        net_rev_gas1 = wa_final_per_bar-gasp1 = net_slrl_gas1 - god_sld_gas1.
        net_rev_oil2 = wa_final_per_bar-oilp2 = net_slrl_oil2 - god_sld_oil2.
        net_rev_gas2 = wa_final_per_bar-gasp2 = net_slrl_gas2 - god_sld_gas2.
        net_rev_oil3 = wa_final_per_bar-oilp3 = net_slrl_oil3 - god_sld_oil3.
        net_rev_gas3 = wa_final_per_bar-gasp3 = net_slrl_gas3 - god_sld_gas3.
        net_rev_oil4 = wa_final_per_bar-oilp4 = net_slrl_oil4 - god_sld_oil4.
        net_rev_gas4 = wa_final_per_bar-gasp4 = net_slrl_gas4 - god_sld_gas4.

*      When 34. "Other Income/ Expense:
      WHEN 33."Other Income
        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.

        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 34."Finance Cost
        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.

        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 35."Provisions, Write off and Other Impairment
        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.

        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 36."Other Expenses (incl. exchange fluctuation)
        wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.

        wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 37."Total Other Income/ Expense (IX)

        CLEAR wa_final_bar1.
        READ TABLE it_final_bar1 INTO wa_final_bar1 INDEX 37.

        IF assoct = '1' OR assoct = '3' OR assoct = '4'.
          wa_final_per_bar-oil1 = wa_final_bar1-total1.
          wa_final_per_bar-oil2 = wa_final_bar1-total2.
          wa_final_per_bar-oil3 = wa_final_bar1-total3.
          wa_final_per_bar-oil4 = wa_final_bar1-total4.

        ELSEIF assoct = '2' OR assoct = '5'.
          wa_final_per_bar-gas1 = wa_final_bar1-total1.
          wa_final_per_bar-gas2 = wa_final_bar1-total2.
          wa_final_per_bar-gas3 = wa_final_bar1-total3.
          wa_final_per_bar-gas4 = wa_final_bar1-total4.

        ENDIF.

        tot_otin_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        tot_otin_gas1 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        tot_otin_oil2 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        tot_otin_gas2 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        tot_otin_oil3 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        tot_otin_gas3 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        tot_otin_oil4 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.
        tot_otin_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 39."Net Profit Before Tax X (VIII-IX)

        net_btax_oil1 = wa_final_per_bar-oilp1 = net_rev_oil1 - tot_otin_oil1.
        net_btax_gas1 = wa_final_per_bar-gasp1 = net_rev_gas1 - tot_otin_gas1.
        net_btax_oil2 = wa_final_per_bar-oilp2 = net_rev_oil2 - tot_otin_oil2.
        net_btax_gas2 = wa_final_per_bar-gasp2 = net_rev_gas2 - tot_otin_gas2.
        net_btax_oil3 = wa_final_per_bar-oilp3 = net_rev_oil3 - tot_otin_oil3.
        net_btax_gas3 = wa_final_per_bar-gasp3 = net_rev_gas3 - tot_otin_gas3.
        net_btax_oil4 = wa_final_per_bar-oilp4 = net_rev_oil4 - tot_otin_oil4.
        net_btax_gas4 = wa_final_per_bar-gasp4 = net_rev_gas4 - tot_otin_gas4.

      WHEN 41."Income Tax (XI)

        in_tax_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        in_tax_gas1 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        in_tax_oil2 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        in_tax_gas2 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        in_tax_oil3 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        in_tax_gas3 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        in_tax_oil4 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.
        in_tax_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 43."Net Profit/(Loss) after tax XII (X-XI)

        net_atax_oil1 = wa_final_per_bar-oilp1 = net_btax_oil1 - in_tax_oil1.
        net_atax_gas1 = wa_final_per_bar-gasp1 = net_btax_gas1 - in_tax_gas1.
        net_atax_oil2 = wa_final_per_bar-oilp2 = net_btax_oil2 - in_tax_oil2.
        net_atax_gas2 = wa_final_per_bar-gasp2 = net_btax_gas2 - in_tax_gas2.
        net_atax_oil3 = wa_final_per_bar-oilp3 = net_btax_oil3 - in_tax_oil3.
        net_atax_gas3 = wa_final_per_bar-gasp3 = net_btax_gas3 - in_tax_gas3.
        net_atax_oil4 = wa_final_per_bar-oilp4 = net_btax_oil4 - in_tax_oil4.
        net_atax_gas4 = wa_final_per_bar-gasp4 = net_btax_gas4 - in_tax_gas4.

      WHEN 45."Impairment loss/(reversal)

        imploss_oil1 = wa_final_per_bar-oilp1 = wa_final_per_bar-oil1 / wa_assoct_oil1-sh_lift.
        imploss_oil2 = wa_final_per_bar-gasp1 = wa_final_per_bar-gas1 / wa_assoct_gas1-sh_lift.
        imploss_oil3 = wa_final_per_bar-oilp2 = wa_final_per_bar-oil2 / wa_assoct_oil2-sh_lift.
        imploss_oil4 = wa_final_per_bar-gasp2 = wa_final_per_bar-gas2 / wa_assoct_gas2-sh_lift.
        imploss_gas1 = wa_final_per_bar-oilp3 = wa_final_per_bar-oil3 / wa_assoct_oil3-sh_lift.
        imploss_gas2 = wa_final_per_bar-gasp3 = wa_final_per_bar-gas3 / wa_assoct_gas3-sh_lift.
        imploss_gas3 = wa_final_per_bar-oilp4 = wa_final_per_bar-oil4 / wa_assoct_oil4-sh_lift.
        imploss_gas4 = wa_final_per_bar-gasp4 = wa_final_per_bar-gas4 / wa_assoct_gas4-sh_lift.

      WHEN 47."Net Profit/(Loss) After Tax-before Impairment

        wa_final_per_bar-oilp1 = net_atax_oil1 - imploss_oil1.
        wa_final_per_bar-gasp1 = net_atax_gas1 - imploss_oil2.
        wa_final_per_bar-oilp2 = net_atax_oil2 - imploss_oil3.
        wa_final_per_bar-gasp2 = net_atax_gas2 - imploss_oil4.
        wa_final_per_bar-oilp3 = net_atax_oil3 - imploss_gas1.
        wa_final_per_bar-gasp3 = net_atax_gas3 - imploss_gas2.
        wa_final_per_bar-oilp4 = net_atax_oil4 - imploss_gas3.
        wa_final_per_bar-gasp4 = net_atax_gas4 - imploss_gas4.

    ENDCASE.

    wa_final_per_bar-oilp1 = round( val = wa_final_per_bar-oilp1 dec = '2' ) .
    wa_final_per_bar-oilp2 = round( val = wa_final_per_bar-oilp2 dec = '2' ) .
    wa_final_per_bar-oilp3 = round( val = wa_final_per_bar-oilp3 dec = '2' ) .
    wa_final_per_bar-oilp4 = round( val = wa_final_per_bar-oilp4 dec = '2' ) .

    wa_final_per_bar-gasp1 = round( val = wa_final_per_bar-gasp1 dec = '2' ) .
    wa_final_per_bar-gasp2 = round( val = wa_final_per_bar-gasp2 dec = '2' ) .
    wa_final_per_bar-gasp3 = round( val = wa_final_per_bar-gasp3 dec = '2' ) .
    wa_final_per_bar-gasp4 = round( val = wa_final_per_bar-gasp4 dec = '2' ) .

    MODIFY it_final_per_bar FROM wa_final_per_bar TRANSPORTING oilp1 oilp2 oilp3 oilp4 gasp1 gasp2 gasp3 gasp4.
    CLEAR wa_final_per_bar.

  ENDLOOP.

ENDFORM. "CRE_PER_BARL

FORM fcat_fill_per_bar.
  DATA bar_h TYPE string.

  CLEAR bar_h.
  PERFORM period_text USING s_period-low p_year1.

  CLEAR bar_h.
  CONCATENATE per_text 'Crude Oil' INTO bar_h SEPARATED BY space.
  PERFORM alv_fcat_per_bar USING : 'PER'       'Particulars',
                                   'OIL1'      bar_h.

  CLEAR bar_h.
  CONCATENATE per_text 'Per BBL Crude Oil' INTO bar_h SEPARATED BY space.
  PERFORM alv_fcat_per_bar USING : 'OILP1'     bar_h.

  CLEAR bar_h.
  CONCATENATE per_text 'Gas' INTO bar_h SEPARATED BY space.
  PERFORM alv_fcat_per_bar USING : 'GAS1'      bar_h.

  CLEAR bar_h.
  CONCATENATE per_text 'Per BBL Gas' INTO bar_h SEPARATED BY space.
  PERFORM alv_fcat_per_bar USING : 'GASP1'     bar_h.

  IF  p_year2 IS NOT INITIAL.

    CLEAR bar_h.
    PERFORM period_text USING s_period_low2 p_year2.

    CLEAR bar_h.
    CONCATENATE per_text 'Crude Oil' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'OIL2'      bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Per BBL Crude Oil' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'OILP2'     bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Gas' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'GAS2'      bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Per BBL Gas' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'GASP2'     bar_h.

  ENDIF.

  IF  p_year3 IS NOT INITIAL.

    CLEAR bar_h.
    PERFORM period_text USING s_period_low3 p_year3.

    CLEAR bar_h.
    CONCATENATE per_text 'Crude Oil' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'OIL3'      bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Per BBL Crude Oil' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'OILP3'     bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Gas' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'GAS3'      bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'PER BBL Gas' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'GASP3'     bar_h.

  ENDIF.

  IF  p_year4 IS NOT INITIAL.
    CLEAR bar_h.
    PERFORM period_text USING s_period_low4 p_year4.

    CLEAR bar_h.
    CONCATENATE per_text 'Crude Oil' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'OIL4'      bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Per BBL Crude Oil' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'OILP4'     bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Gas' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'GAS4'      bar_h.

    CLEAR bar_h.
    CONCATENATE per_text 'Per BBL Gas' INTO bar_h SEPARATED BY space.
    PERFORM alv_fcat_per_bar USING : 'GASP4'     bar_h.

  ENDIF.

ENDFORM."fcat_fill_per_bar

FORM alv_fcat_per_bar USING VALUE(p_011)
                            VALUE(p_012).

  wa_fcat-fieldname   = p_011.
  wa_fcat-seltext_l   = p_012.
  wa_fcat-no_zero     = 'X'.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

ENDFORM." alv_fcat_PER_BAR

FORM alv_display_per_bar.

  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.
  CLEAR : it_final_bar,it_final_bar1.
  REFRESH : it_final_bar[],it_final_bar1[].

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-cprog
      i_callback_top_of_page = 'TOP_OF_PAGE_PER_BAR'
      is_layout              = wa_layout
      it_fieldcat            = it_fcat
      i_default              = 'X'
      i_save                 = 'U'
    TABLES
      t_outtab               = it_final_per_bar
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM. "alv_display_per_bar

FORM top_of_page_per_bar.

  REFRESH int_header[].
  fs_header-typ = 'H'.
  fs_header-info = 'Profitability Statement - Per Barrel Analysis'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp
                       WHERE bukrs = p_comp1.

  READ TABLE it_comp INTO DATA(wa_comp) WITH KEY bukrs = p_comp1.
  fs_header-typ = 'S'.
  CONCATENATE 'Company code :- ' wa_comp-bukrs ' - ' wa_comp-txtcc INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE jvnam = p_proj1-low.

  READ TABLE it_proj INTO DATA(wa_proj) WITH KEY jvnam = p_proj1-low.
  fs_header-typ = 'S'.
  CONCATENATE 'Project :- ' wa_proj-jvnam ' - ' wa_proj-txtjv  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  CONCATENATE '(Amount in' 'US$ Mn.)'  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = int_header.


ENDFORM. "TOP_OF_PAGE_PER_BAR

FORM set_for_disp .

  IF it_prof_prd[] IS NOT INITIAL.
    REFRESH it_prof_prd2[].
    MOVE-CORRESPONDING it_prof_prd[] TO it_prof_prd2[].

    DO 6 TIMES.
      DATA(del_lines) = 1.
      DELETE it_prof_prd2 INDEX del_lines.
    ENDDO.
    CLEAR del_lines.

*        REFRESH IT_PROF_PRD3[].
*        MOVE-CORRESPONDING IT_PROF_PRD3[] TO IT_PROF_PRD3[].
  ENDIF.

ENDFORM. "SET_FOR_DISP

FORM check_alloc_values . ""Check weather the values are not zero to avoid divide by zero error

  DATA : wa_a_o1 TYPE ty_alloct2,wa_a_g1 TYPE ty_alloct2,
         wa_a_o2 TYPE ty_alloct2,wa_a_g2 TYPE ty_alloct2,
         wa_a_o3 TYPE ty_alloct2,wa_a_g3 TYPE ty_alloct2,
         wa_a_o4 TYPE ty_alloct2,wa_a_g4 TYPE ty_alloct2.


  MOVE-CORRESPONDING wa_assoct_oil1 TO wa_a_o1.
  MOVE-CORRESPONDING wa_assoct_oil2 TO wa_a_o2.
  MOVE-CORRESPONDING wa_assoct_oil3 TO wa_a_o3.
  MOVE-CORRESPONDING wa_assoct_oil4 TO wa_a_o4.

  MOVE-CORRESPONDING wa_assoct_gas1 TO wa_a_g1.
  MOVE-CORRESPONDING wa_assoct_gas2 TO wa_a_g2.
  MOVE-CORRESPONDING wa_assoct_gas3 TO wa_a_g3.
  MOVE-CORRESPONDING wa_assoct_gas4 TO wa_a_g4.


* CONDENSE : WA_ASSOCT_OIL1-SH_LIFT,
*            WA_ASSOCT_OIL2-SH_LIFT,
*            WA_ASSOCT_OIL3-SH_LIFT,
*            WA_ASSOCT_OIL4-SH_LIFT,
*
*            WA_ASSOCT_GAS1-SH_LIFT,
*            WA_ASSOCT_GAS2-SH_LIFT,
*            WA_ASSOCT_GAS3-SH_LIFT,
*            WA_ASSOCT_GAS4-SH_LIFT,
*
*            WA_ASSOCT_OIL1-SH_PROD,
*            WA_ASSOCT_OIL2-SH_PROD,
*            WA_ASSOCT_OIL3-SH_PROD,
*            WA_ASSOCT_OIL4-SH_PROD,
*
*            WA_ASSOCT_GAS1-SH_PROD,
*            WA_ASSOCT_GAS2-SH_PROD,
*            WA_ASSOCT_GAS3-SH_PROD,
*            WA_ASSOCT_GAS4-SH_PROD,
*
*            WA_ASSOCT_OIL1-TOT_SAL,
*            WA_ASSOCT_OIL2-TOT_SAL,
*            WA_ASSOCT_OIL3-TOT_SAL,
*            WA_ASSOCT_OIL4-TOT_SAL,
*
*            WA_ASSOCT_GAS1-TOT_SAL,
*            WA_ASSOCT_GAS2-TOT_SAL,
*            WA_ASSOCT_GAS3-TOT_SAL,
*            WA_ASSOCT_GAS4-TOT_SAL.

  IF wa_a_g1-sh_prod = 0   .
    wa_assoct_gas1-sh_prod = '1'.
  ENDIF.
  IF wa_a_g1-tot_sal = 0.
    wa_assoct_gas1-tot_sal = '1'.
  ENDIF.
  IF wa_a_g1-sh_lift = 0.
    wa_assoct_gas1-sh_lift = '1'.
  ENDIF.
  IF wa_a_o1-sh_prod = 0.
    wa_assoct_oil1-sh_prod = '1'.
  ENDIF.
  IF wa_a_o1-tot_sal = 0.
    wa_assoct_oil1-tot_sal = '1'.
  ENDIF.
  IF wa_a_o1-sh_lift = 0.
    wa_assoct_oil1-sh_lift = '1'.
  ENDIF.

  IF wa_a_g2-sh_prod = 0.
    wa_assoct_gas2-sh_prod = '1'.
  ENDIF.
  IF wa_a_g2-tot_sal = 0.
    wa_assoct_gas2-tot_sal = '1'.
  ENDIF.
  IF wa_a_g2-sh_lift = 0.
    wa_assoct_gas2-sh_lift = '1'.
  ENDIF.
  IF wa_a_o2-sh_prod = 0.
    wa_assoct_oil2-sh_prod = '1'.
  ENDIF.
  IF wa_a_o2-tot_sal = 0.
    wa_assoct_oil2-tot_sal = '1'.
  ENDIF.
  IF wa_a_o2-sh_lift = 0.
    wa_assoct_oil2-sh_lift = '1'.
  ENDIF.

  IF wa_a_g3-sh_prod = 0.
    wa_assoct_gas3-sh_prod = '1'.
  ENDIF.
  IF wa_a_g3-tot_sal = 0.
    wa_assoct_gas3-tot_sal = '1'.
  ENDIF.
  IF wa_a_g3-sh_lift = 0.
    wa_assoct_gas3-sh_lift = '1'.
  ENDIF.
  IF wa_a_o3-sh_prod = 0.
    wa_assoct_oil3-sh_prod = '1'.
  ENDIF.
  IF wa_a_o3-tot_sal = 0.
    wa_assoct_oil3-tot_sal = '1'.
  ENDIF.
  IF wa_a_o3-sh_lift = 0.
    wa_assoct_oil3-sh_lift = '1'.
  ENDIF.

  IF wa_a_g4-sh_prod = 0.
    wa_assoct_gas4-sh_prod = '1'.
  ENDIF.
  IF wa_a_g4-tot_sal = 0.
    wa_assoct_gas4-tot_sal = '1'.
  ENDIF.
  IF wa_a_g4-sh_lift = 0.
    wa_assoct_gas4-sh_lift = '1'.
  ENDIF.
  IF wa_a_o4-sh_prod = 0.
    wa_assoct_oil4-sh_prod = '1'.
  ENDIF.
  IF wa_a_o4-tot_sal = 0.
    wa_assoct_oil4-tot_sal = '1'.
  ENDIF.
  IF wa_a_o4-sh_lift = 0.
    wa_assoct_oil4-sh_lift = '1'.
  ENDIF.

  CLEAR : wa_a_o1,wa_a_g1,
          wa_a_o2,wa_a_g2,
          wa_a_o3,wa_a_g3,
          wa_a_o4,wa_a_g4.

ENDFORM. "CHECK_ALLOC_VALUES .

FORM get_gls . "Get GLs from set which are to be seperated in oil and gas fields

  REFRESH it_setgls[].

  SELECT a~setname
         a~lineid
         a~valfrom
         a~valto
         b~descript
         FROM setleaf AS a
         INNER JOIN setlinet AS b ON a~setname = b~setname
                                 AND a~lineid  = b~lineid
         INTO CORRESPONDING FIELDS OF TABLE it_setgls
         WHERE a~setname = 'ZFI_PNL_GLS'.

ENDFORM."Get GLS
*&---------------------------------------------------------------------*
*&      Form  AUTH_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM auth_check . "Authorization check for Create/Change/Display/Approve/Freeze
  DATA(lv_qt_cre) = 'Z:FI_PL_CRE'.
  DATA(lv_qt_dis) = 'Z:FI_PL_DIS'.
  DATA(lv_qt_app) = 'Z:FI_PL_APP'.
  DATA(lv_qt_frz) = 'Z:FI_PL_FRZ'.

  DATA(lv_bu_apac) = 'Z:FI_PL_APAC'.
  DATA(lv_bu_mena) = 'Z:FI_PL_MENA'.
  DATA(lv_bu_cis)  = 'Z:FI_PL_CIS'.
  DATA(lv_bu_col)  = 'Z:FI_PL_COL'.
  DATA(lv_bu_lac)  = 'Z:FI_PL_LAC'.
  DATA(lv_bu_rus)  = 'Z:FI_PL_RUS'.
  DATA(lv_bu_moz)  = 'Z:FI_PL_MOZ'.
  DATA(lv_bu_corp) = 'Z:FI_PL_CORP'.

  DATA(lv_ap_corp) = 'Z:FI_PL_CHG_CORP'.

*  added by APARNA on 03.07.24 on request of Rahul Pauranik

  DATA(lv_qt_rp_cre) = 'Z:FI_PL_RP_CRE'.
  DATA(lv_qt_rp_dis) = 'Z:FI_PL_RP_DIS'.
  DATA(lv_qt_rp_app) = 'Z:FI_PL_RP_APP'.
  DATA(lv_qt_rp_frz) = 'Z:FI_PL_RP_FRZ'.

  DATA(lv_bu_rp_apac) = 'Z:FI_PL_RP_APAC'.
  DATA(lv_bu_rp_mena) = 'Z:FI_PL_RP_MENA'.
  DATA(lv_bu_rp_cis)  = 'Z:FI_PL_RP_CIS'.
  DATA(lv_bu_rp_col)  = 'Z:FI_PL_RP_COL'.
  DATA(lv_bu_rp_lac)  = 'Z:FI_PL_RP_LAC'.
  DATA(lv_bu_rp_rus)  = 'Z:FI_PL_RP_RUS'.
  DATA(lv_bu_rp_moz)  = 'Z:FI_PL_RP_MOZ'.
  DATA(lv_bu_rp_corp) = 'Z:FI_PL_RP_CORP'.
  DATA(lv_ap_rp_corp) = 'Z:FI_PL_RP_CHG_CORP'.
*  ended by Aparna on 03.07.24 on request of Rahul Pauranik
  IF sy-ucomm = 'CREATE' OR sy-ucomm = 'CHANGE'.
    SELECT SINGLE * FROM agr_users INTO @DATA(lv_cre_qt)
                  WHERE uname = @sy-uname
                  AND agr_name = @lv_qt_cre.

    SELECT SINGLE * FROM zpnl_qi_oil
           INTO @DATA(chk_cre_quant)
           WHERE company = @p_company
             AND bukrs   = @p_comp
             AND pro_nam = @p_proj
             AND fisyear = @p_year
             AND zperiod = @s_period_low.

    IF chk_cre_quant-approved_by IS NOT INITIAL AND sy-ucomm = 'CHANGE'.
      SELECT SINGLE * FROM agr_users INTO @DATA(lv_app_corp)
              WHERE uname = @sy-uname
              AND agr_name = @lv_ap_corp.
      IF lv_app_corp IS INITIAL.
        MESSAGE 'You cannot change the approved data' TYPE 'E' DISPLAY LIKE 'I'.
      ENDIF.
    ENDIF.

    IF lv_cre_qt IS INITIAL.
      MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
    ENDIF.

  ELSEIF sy-ucomm =  'APPROVE'.
    SELECT SINGLE * FROM agr_users INTO @DATA(lv_app_qt)
             WHERE uname = @sy-uname
             AND agr_name = @lv_qt_app.

    IF lv_app_qt IS NOT INITIAL.
      SELECT uname,agr_name FROM agr_users INTO TABLE @DATA(lt_app_bu)
             WHERE uname = @sy-uname
             AND agr_name IN ( @lv_bu_apac,@lv_bu_mena,@lv_bu_cis,@lv_bu_col,@lv_bu_lac,@lv_bu_rus,@lv_bu_moz,@lv_bu_corp ).

      IF lt_app_bu IS NOT INITIAL.

        SELECT SINGLE busuni FROM zfi_pnl_proj INTO @DATA(lv_busuni) WHERE company = @p_company AND jvnam = @p_proj AND bukrs = @p_comp.
*        IF lv_busuni IS NOT INITIAL.
*          CONCATENATE 'Z:FI_PL_' lv_busuni INTO DATA(lv_agr_name).
*          READ TABLE lt_app_bu INTO DATA(ls_app_bu) WITH KEY agr_name = lv_agr_name.
*          IF lv_busuni NE ls_app_bu-agr_name+8(4).
*            MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
*          ENDIF.
*
*        ELSE.
*          MESSAGE 'No BU entred in project maintanance for given project' TYPE 'E' DISPLAY LIKE 'I'.
*        ENDIF.

      ELSE.
        MESSAGE 'You are not authorized(No BU role assigned)' TYPE 'E'.
      ENDIF.
    ENDIF.

    REFRESH : lt_app_bu.
    CLEAR : lv_busuni ."ls_app_bu lv_agr_name
****************************    ADDED BY APARNA ON 03.07.2024 ON REQUEST OF RAHUL PAURANIK
  ELSEIF sy-ucomm =  'APPROVEFI'.
    SELECT SINGLE * FROM agr_users INTO @lv_app_qt
             WHERE uname = @sy-uname
             AND agr_name = @lv_qt_rp_app.

    IF lv_app_qt IS INITIAL.
      MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
    ENDIF.
    IF lv_app_qt IS NOT INITIAL.
      SELECT uname,agr_name FROM agr_users INTO TABLE @lt_app_bu
             WHERE uname = @sy-uname
             AND agr_name IN ( @lv_bu_rp_apac,@lv_bu_rp_mena,@lv_bu_rp_cis,@lv_bu_rp_col,@lv_bu_rp_lac,@lv_bu_rp_rus,@lv_bu_rp_moz,@lv_bu_rp_corp ).

      IF lt_app_bu IS NOT INITIAL.

        SELECT SINGLE busuni FROM zfi_pnl_proj INTO @lv_busuni WHERE company = @p_company AND jvnam = @p_proj AND bukrs = @p_comp.
*        IF lv_busuni IS NOT INITIAL.
*          CONCATENATE 'Z:FI_PL_RP_' lv_busuni INTO lv_agr_name.
*          READ TABLE lt_app_bu INTO ls_app_bu WITH KEY agr_name = lv_agr_name.
*          IF lv_busuni NE ls_app_bu-agr_name+11(4).
*            MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
*          ENDIF.
*
*        ELSE.
*          MESSAGE 'No BU entred in project maintanance for given project' TYPE 'E' DISPLAY LIKE 'I'.
*        ENDIF.

      ELSE.
        MESSAGE 'You are not authorized(No BU role assigned)' TYPE 'E'.
      ENDIF.
    ENDIF.

    REFRESH : lt_app_bu.
    CLEAR : lv_busuni ."lv_agr_name,ls_app_bu.
************************ ENDED BY APARNA ON 03.07.2024 ON REQUEST OF RAHUL PAURANIK

  ELSEIF sy-ucomm =  'FREEZE'.
    SELECT SINGLE * FROM agr_users INTO @DATA(lv_frz_qt)
             WHERE uname = @sy-uname
             AND agr_name = @lv_qt_frz.

    IF lv_frz_qt IS INITIAL.
      MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
    ENDIF.

  ELSEIF sy-ucomm =  'DISPLAY'.
    SELECT SINGLE * FROM agr_users INTO @DATA(lv_dis_qt)
             WHERE uname = @sy-uname
             AND agr_name = @lv_qt_dis.

    IF lv_dis_qt IS INITIAL.
      MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
    ENDIF.

  ENDIF.
  IF pnl = 'VAR_PRD' OR pnl = 'VAR_NON'.
    IF  sy-ucomm =  'DISPLAY'.
      SELECT SINGLE * FROM agr_users INTO @lv_dis_qt
               WHERE uname = @sy-uname
               AND agr_name = @lv_qt_dis.

      IF lv_dis_qt IS INITIAL.
        MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
      ENDIF.
    ENDIF.
    IF sy-ucomm =  'APPROVE'.
      SELECT SINGLE * FROM agr_users INTO @lv_dis_qt
            WHERE uname = @sy-uname
            AND agr_name = @lv_qt_app.

      IF lv_dis_qt IS INITIAL.
        MESSAGE 'You are not authorized' TYPE 'E' DISPLAY LIKE 'I'.
      ENDIF.
    ENDIF.
  ENDIF.
  CLEAR : lv_qt_cre,lv_cre_qt,
          lv_qt_dis,lv_dis_qt,
          lv_qt_app,lv_app_qt,
          lv_qt_frz,lv_frz_qt.

ENDFORM. "AUTH_CHECK.
*&---------------------------------------------------------------------*
*&      Form  CREATE_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_layout . "Create the Report Layout/Screen

*Preparing the Report Layout/Screen
  READ TABLE it_prod_f4 INTO DATA(wa_prod_f4) WITH KEY text_no = '103'.
  wa_final_bar-per = wa_prod_f4-prod_proj."'Revenue from Crude Oil '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '115'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Revenue from Natural Gas'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '104'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Less: Profit Oil paid in cash'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  wa_final_bar-per = 'SALE OF VAP'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '117'.
  wa_final_bar-per = wa_prod_f4-prod_proj . "'Other Operating Revenue'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  wa_final_bar-per = '(I) SALES REALISATION'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '  '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = 'OPREATING EXPENSE :'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '102'.
  wa_final_bar-per = wa_prod_f4-prod_proj  ."'Royalty'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  wa_final_bar-per = 'OTHER TAXES (AS APPLICABLE)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '101'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Production expense'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '119'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."Other Operating Expenses.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '107'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Transport Expense'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  wa_final_bar-per = 'INTERNAL CONSUMPTION OF GAS'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(II) TOTAL OPERATING EXPENSES'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = 'DDA & EXPLORATION :'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '113'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Depletion'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '114'.
  wa_final_bar-per = wa_prod_f4-prod_proj  ."'Depreciation and Amortisation'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  "Spliting Exploration Costs (Survey & Dry well) to survey and dry well
  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '106'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Exploration Costs (Survey)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '124'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Exploration Costs (Dry well)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  wa_final_bar-per = '(III) TOTAL DDA & EXPLORATION'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(IV) OPERATING COST'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = 'ADJUSTMENT FOR COST OF SALES:'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '120'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Change in inventories'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '112'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Overlift/(Underlift)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  wa_final_bar-per = '(VII) COST OF GOODS SOLD (IV+V+VI)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(VIII) NET OPERATING MARGIN (I-VII)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = 'OTHER INCOME/ EXPENSE :'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '116'.
  wa_final_bar-per = wa_prod_f4-prod_proj ."'Other Income'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '108'.
  wa_final_bar-per = wa_prod_f4-prod_proj  ."'Finance Cost'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '109'.
  wa_final_bar-per = wa_prod_f4-prod_proj  ."'Provision & Write-off (incl. impairment)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '111'.
  wa_final_bar-per = wa_prod_f4-prod_proj  ."'Other Expenses (incl. exchange fluctuation)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(IX) TOTAL OTHER INCOME/ EXPENSE'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(X) NET PROFIT BEFORE TAX (VIII-IX)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(XI) INCOME TAX' ."'Income Tax (VIII) (20%)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = '(XII) NET PROFIT/(LOSS) AFTER TAX (X-XI)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar,wa_prod_f4.

  READ TABLE it_prod_f4 INTO wa_prod_f4 WITH KEY text_no = '110'.
  wa_final_bar-per = wa_prod_f4-prod_proj  ."'Impairment loss/(reversal)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

  wa_final_bar-per = 'NET PROFIT/(LOSS) AFTER TAX-BEFORE IMPAIRMENT'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR wa_final_bar.

ENDFORM. "CREATE_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  CREATE_QUANT_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_quant_layout .  "Create Quantitaive Information layout for Profitablility Analysis

  wa_final_bar-per = '1 Opening inventory:'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '1a Stock in Storage tanks/locations/FPSO'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '1b Stock in pipelines/linefill'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '2 Share of Production'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '3 Profit Oil/Gas:'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '3a State/Govt.share-lifted by OVL(applicable for Sakhalin1)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '3b State/Govt. share-taken by state in kind'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '4 Share of entitled production (entitlement) (2-3)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '5 Transit Loss & Flaring:'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '5a Transit loss'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '5b Flaring/vented'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '6 Production quantity after transit loss & flaring (4-5)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '7 Internal consumption:'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '7a Production activity'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '7b Others'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '8 Net production quantity available (6-7)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '9 Closing Stock:'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '9a Stock in Storage tanks/locations/FPSO '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '9b Stock in pipelines/linefill'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '10 Adj. for Changes in Inventories/Other adj.'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '11 Net quantity available for sale (8-9-10+1+3a)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '12 Overlift/(underlift) quantity (13-11)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '13 Total Sales quantity'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = ' '.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

  wa_final_bar-per = '14 Total Sales quantity-net of state share (13-3a)'.
  APPEND wa_final_bar TO it_final_bar.
  CLEAR : wa_final_bar.

ENDFORM.  "CREATE_QUANT_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  CRE_QUANT_FIGS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cre_quant_figs.

  DATA(lv_q_count) = 1.

  IF s_period-low IS NOT INITIAL.
    CLEAR : lv_s_period,mode,lv_p_year.
    mode = 'DIS'.
    lv_p_year   = p_year1.
    lv_s_period = s_period-low.
    PERFORM create_quant.
    PERFORM fetch_quant.
    PERFORM cal_quant.

    LOOP AT it_quant INTO DATA(wa_q_ana).
      wa_pro_ana-sr_no = wa_q_ana-sr_no.
      wa_pro_ana-per   = wa_q_ana-data.
      wa_pro_ana-oil1  = wa_q_ana-bbl.
      wa_pro_ana-gas1  = wa_q_ana-mmbtu.

      APPEND wa_pro_ana TO it_pro_ana.
      CLEAR:wa_pro_ana,wa_q_ana.
    ENDLOOP.
  ENDIF.

  IF s_period_low2 IS NOT INITIAL.
    CLEAR : lv_s_period,mode,lv_q_count,lv_p_year.
    mode = 'DIS'.
    lv_p_year   = p_year2.
    lv_s_period = s_period_low2.
    PERFORM create_quant.
    PERFORM fetch_quant.
    PERFORM cal_quant.

    lv_q_count = 1.

    LOOP AT it_quant INTO wa_q_ana.
      lv_q_count = lv_q_count + 1.
      READ TABLE it_pro_ana INTO wa_pro_ana INDEX lv_q_count.
      wa_pro_ana-oil2 = wa_q_ana-bbl.
      wa_pro_ana-gas2 = wa_q_ana-mmbtu.

      MODIFY it_pro_ana FROM wa_pro_ana INDEX lv_q_count TRANSPORTING oil2 gas2.
      CLEAR:wa_pro_ana,wa_q_ana.
    ENDLOOP.
    CLEAR lv_q_count.
  ENDIF.

  IF s_period_low3 IS NOT INITIAL.
    CLEAR : lv_s_period,mode,lv_q_count,lv_p_year.
    mode = 'DIS'.
    lv_p_year   = p_year3.
    lv_s_period = s_period_low3.
    PERFORM create_quant.
    PERFORM fetch_quant.
    PERFORM cal_quant.

    lv_q_count = 1.

    LOOP AT it_quant INTO wa_q_ana.
      lv_q_count = lv_q_count + 1.
      READ TABLE it_pro_ana INTO wa_pro_ana INDEX lv_q_count.
      wa_pro_ana-oil3 = wa_q_ana-bbl.
      wa_pro_ana-gas3 = wa_q_ana-mmbtu.

      MODIFY it_pro_ana FROM wa_pro_ana INDEX lv_q_count TRANSPORTING oil3 gas3 .
      CLEAR:wa_pro_ana,wa_q_ana.
    ENDLOOP.
    CLEAR lv_q_count.
  ENDIF.

  IF s_period_low4 IS NOT INITIAL.
    CLEAR : lv_s_period,mode,lv_q_count,lv_p_year.
    mode = 'DIS'.
    lv_p_year   = p_year4.
    lv_s_period = s_period_low4.
    PERFORM create_quant.
    PERFORM fetch_quant.
    PERFORM cal_quant.

    lv_q_count = 1.

    LOOP AT it_quant INTO wa_q_ana.
      lv_q_count = lv_q_count + 1.
      READ TABLE it_pro_ana INTO wa_pro_ana INDEX lv_q_count.
      wa_pro_ana-oil4 = wa_q_ana-bbl.
      wa_pro_ana-gas4 = wa_q_ana-mmbtu.

      MODIFY it_pro_ana FROM wa_pro_ana INDEX lv_q_count  TRANSPORTING oil4 gas4.
      CLEAR:wa_pro_ana,wa_q_ana.
    ENDLOOP.
    CLEAR lv_q_count.
  ENDIF.

ENDFORM. "CRE_QUANT_FIGS

*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_PRO_ANA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display_pro_ana .

  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.
  CLEAR : it_final_bar,it_final_bar1,it_final_per_bar.
  REFRESH : it_final_bar[],it_final_bar1[],it_final_per_bar[].

  DATA(user_lay) = 'U'.
  IF sy-uname = 'BASIS'.
    user_lay = 'A'.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-cprog
      i_callback_top_of_page = 'TOP_OF_PAGE_PRO_ANA'
      is_layout              = wa_layout
      it_fieldcat            = it_fcat
      i_default              = 'X'
      i_save                 = user_lay
    TABLES
      t_outtab               = it_pro_ana
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM. "ALV_DISPLAY_PRO_ANA

*&---------------------------------------------------------------------*
*&      Form  TOP_OF_PAGE_PRO_ANA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM top_of_page_pro_ana .

  REFRESH int_header[].
  IF lv_profitabilty = 'X'.     " Start of changes Madhu
    fs_header-typ = 'H'.
    fs_header-info = 'Profitability Analysis Report'.
    APPEND fs_header TO int_header.
    CLEAR fs_header.
    " Start of changes Madhu
  ELSE.
    fs_header-typ = 'H'.
    fs_header-info = 'Variance Analysis Report'.
    APPEND fs_header TO int_header.
    CLEAR fs_header.

    fs_header-typ = 'S'.
    fs_header-info = '"FOR SAVING THE REMARKS, SELECT ALL CELLS AND THEN CLICK ON SAVE"'.
    APPEND fs_header TO int_header.
    CLEAR fs_header.
  ENDIF.
  " End of changes Madhu

  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp
                       WHERE bukrs = p_comp1.

  READ TABLE it_comp INTO DATA(wa_comp) WITH KEY bukrs = p_comp1.
  fs_header-typ = 'S'.
  CONCATENATE 'Company code :- ' wa_comp-bukrs ' - ' wa_comp-txtcc INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE jvnam = p_proj1-low.

  READ TABLE it_proj INTO DATA(wa_proj) WITH KEY jvnam = p_proj1-low.
  fs_header-typ = 'S'.
  CONCATENATE 'Project :- ' wa_proj-jvnam ' - ' wa_proj-txtjv  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  CONCATENATE '(Amount in' 'US$ Mn.)' INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = int_header.

ENDFORM. "TOP_OF_PAGE_PRO_ANA
FORM top_of_page_html USING document TYPE REF TO cl_dd_document.  " added by aparna  on 26.06.2024
  DATA: lo_table_area TYPE REF TO cl_dd_table_area,
        lo_text       TYPE sdydo_text_element.

  CALL METHOD document->add_text
    EXPORTING
      text         = 'Variance Analysis Report'    " Single Text, Up To 255 Characters Long
      sap_color    = cl_dd_area=>list_heading_int   " Not Release 99
      sap_fontsize = cl_dd_area=>large
      sap_emphasis = cl_dd_area=>strong.

  CALL METHOD document->new_line.

  CALL METHOD document->add_text
    EXPORTING
      text         = '"FOR SAVING THE REMARKS, SELECT ALL CELLS AND THEN CLICK ON SAVE"'    " Single Text, Up To 255 Characters Long
      sap_color    = cl_dd_area=>list_heading_int
      sap_fontsize = cl_dd_area=>large
      sap_emphasis = cl_dd_area=>strong.
*      sap_style     = cl_dd_area=>heading.

  CALL METHOD document->new_line.

  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp
                       WHERE bukrs = p_comp1.
  READ TABLE it_comp INTO DATA(wa_comp) WITH KEY bukrs = p_comp1.
  CONCATENATE 'Company code :- ' wa_comp-bukrs ' - ' wa_comp-txtcc INTO lo_text SEPARATED BY space.
  CALL METHOD document->add_text
    EXPORTING
      text = lo_text.   " Single Text, Up To 255 Characters Long


  CALL METHOD document->new_line.
  CLEAR lo_text.

  SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE jvnam = p_proj1-low.

  READ TABLE it_proj INTO DATA(wa_proj) WITH KEY jvnam = p_proj1-low.
  CONCATENATE 'Project :- ' wa_proj-jvnam ' - ' wa_proj-txtjv  INTO lo_text SEPARATED BY space.

  CALL METHOD document->add_text
    EXPORTING
      text = lo_text.    " Single Text, Up To 255 Characters Long

  CALL METHOD document->new_line.
  CLEAR lo_text.
  CONCATENATE '(Amount in' 'US$ Mn.)' INTO lo_text SEPARATED BY space.
  CALL METHOD document->add_text
    EXPORTING
      text = lo_text.    " Single Text, Up To 255 Characters Long

ENDFORM." ended by aparna on 27.06.2024 " for gicing colour on top of page
*&---------------------------------------------------------------------*
*&      Form  GET_PEND_REP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_pend_rep .
  REFRESH lt_pend_fin[].

  IF r_pqi = 'X'.

    SELECT * FROM zfi_pnl_proj INTO TABLE @DATA(lt_proj1).

    REFRESH lt_pend[].
    SELECT company,
           pro_nam,
           fisyear,
           zperiod,
           bukrs,
           created_by,
           created_on,
           approved_by,
           approved_on,
           approved_by_rp,
           approved_on_rp
      FROM zpnl_qi_oil INTO CORRESPONDING FIELDS OF TABLE @lt_pend
      WHERE fisyear = @p_year1
        AND zperiod IN @s_period.

    IF lt_pend[] IS INITIAL.
      SELECT company,
             pro_nam,
             fisyear,
             zperiod,
             bukrs,
             created_by,
             created_on,
             approved_by,
             approved_on,
            approved_by_rp,
           approved_on_rp
        FROM zpnl_qi_gas INTO CORRESPONDING FIELDS OF TABLE @lt_pend
        WHERE fisyear =  @p_year1
          AND zperiod IN @s_period.
    ENDIF.

  ELSEIF r_ppp = 'X'.

    REFRESH lt_proj1[].
    SELECT *
    FROM   zfi_pnl_proj
    INTO   TABLE lt_proj1
           WHERE manual = 'YES'
           AND   prod   = 'YES'.

    REFRESH lt_pend[].
    SELECT company,
           pro_nam,
           fisyear,
           zperiod,
           bukrs,
           created_by,
           created_on,
           approved_by,
           approved_on,
           approved_by_rp,
           approved_on_rp
      FROM zpnl_prd_oil
      INTO CORRESPONDING FIELDS OF TABLE @lt_pend
           WHERE fisyear =  @p_year1
           AND   zperiod IN @s_period.

    IF lt_pend[] IS INITIAL.
      SELECT company,
             pro_nam,
             fisyear,
             zperiod,
             bukrs,
             created_by,
             created_on,
             approved_by,
             approved_on,
             approved_by_rp,
             approved_on_rp
        FROM zpnl_prd_gas
        INTO CORRESPONDING FIELDS OF TABLE @lt_pend
             WHERE fisyear =  @p_year1
             AND   zperiod IN @s_period.
    ENDIF.

  ELSEIF r_pop = 'X'.

    REFRESH lt_proj1[].
    SELECT *
    FROM   zfi_pnl_proj
    INTO   TABLE lt_proj1
           WHERE manual = 'YES'
           AND   prod   = 'NO'.

    REFRESH lt_pend[].
    SELECT  company,
            pro_nam,
            fisyear,
            zperiod,
            bukrs,
            created_by,
            created_on,
            approve_by,
            approve_on,
            approved_by_rp,
            approved_on_rp
      FROM  zpnl_oth_proj
      INTO  TABLE @DATA(lt_other)
            WHERE fisyear =  @p_year1
            AND   zperiod IN @s_period.

  ELSEIF r_var = 'X'.

    REFRESH lt_proj1[].

    SELECT *
    FROM   zfi_pnl_proj
    INTO   TABLE lt_proj1.
*           WHERE   prod   = 'YES'.

    REFRESH lt_pend[].

    SELECT *
    FROM   zfi_pl_status
    INTO   TABLE @DATA(lt_var)
           WHERE fiscal =  @p_year1
           AND   period IN @s_period.

  ELSEIF r_nvar = 'X'.

    REFRESH lt_proj1[].

    SELECT *
    FROM   zfi_pnl_proj
    INTO   TABLE lt_proj1.
*           WHERE  prod   = 'NO'.

    REFRESH lt_pend[].

    SELECT *
    FROM   zfi_pl_status_n
    INTO   TABLE @DATA(lt_nvar)
           WHERE fiscal =  @p_year1
           AND   period IN @s_period.

  ENDIF.

  IF p_compy1 IS NOT INITIAL.
    DELETE lt_pend[] WHERE company NE p_compy1.
    DELETE lt_proj1[] WHERE company NE p_compy1.
  ENDIF.
  IF p_proj1-low IS NOT INITIAL.
    DELETE lt_pend[] WHERE pro_nam NE p_proj1-low.
    DELETE lt_proj1[] WHERE jvnam NE p_proj1-low.
  ENDIF.

  IF r_pop = 'X'.

    LOOP AT lt_proj1 INTO DATA(ls_proj1).
      READ TABLE lt_other INTO DATA(ls_other) WITH KEY pro_nam = ls_proj1-jvnam zperiod = s_period-low.
      IF ls_other-approve_by IS NOT INITIAL.
        ls_pend-status = 'Approved'.
      ELSE.
        ls_pend-status  = 'Pending'.
      ENDIF.
      ls_pend-company = ls_proj1-company.
      ls_pend-bukrs   = ls_proj1-bukrs.
      ls_pend-pro_nam = ls_proj1-jvnam.
      ls_pend-fisyear = p_year1.
      ls_pend-zperiod = s_period-low.
      ls_pend-approved_by  = ls_other-approve_by.
      ls_pend-approved_on  = ls_other-approve_on.
      ls_pend-approved_by_rp  = ls_other-approved_by_rp.
      ls_pend-approved_on_rp  = ls_other-approved_on_rp.
      ls_pend-created_by  = ls_other-created_by.
      ls_pend-created_on  = ls_other-created_on.


      APPEND ls_pend TO lt_pend_fin.
      CLEAR ls_pend.
    ENDLOOP.
  ELSEIF r_var = 'X'.
    LOOP AT lt_proj1 INTO ls_proj1.
      LOOP AT lt_var INTO DATA(ls_var) WHERE  proj = ls_proj1-jvnam  AND period = s_period-low.
        IF ls_var-approved_by IS NOT INITIAL.
          ls_pend-status = 'Approved'.
        ELSE.
          ls_pend-status  = 'Pending'.
        ENDIF.
        ls_pend-company = ls_proj1-company.
        ls_pend-bukrs   = ls_proj1-bukrs.
        ls_pend-pro_nam = ls_proj1-jvnam.
        ls_pend-fisyear = p_year1.
        ls_pend-fisyear1 = ls_var-fiscal2.
        ls_pend-zperiod = s_period-low.
        ls_pend-zperiod1 = ls_var-period2.
        ls_pend-approved_by  = ls_var-approved_by.
        ls_pend-approved_on  = ls_var-approved_on.
        ls_pend-approved_by_rp  = ls_var-approved_by_rp.
        ls_pend-approved_on_rp  = ls_var-approved_on_rp.
        ls_pend-created_by  = ls_var-created_by.
        ls_pend-created_on  = ls_var-created_on.
        APPEND ls_pend TO lt_pend_fin.
        CLEAR ls_pend.
      ENDLOOP.
    ENDLOOP.
  ELSEIF r_nvar = 'X'.
    LOOP AT lt_proj1 INTO ls_proj1.
      LOOP AT lt_nvar INTO DATA(ls_nvar) WHERE  proj = ls_proj1-jvnam AND period = s_period-low.
        IF ls_nvar-approved_by IS NOT INITIAL.
          ls_pend-status = 'Approved'.
        ELSE.
          ls_pend-status  = 'Pending'.
        ENDIF.
        ls_pend-company = ls_proj1-company.
        ls_pend-bukrs   = ls_proj1-bukrs.
        ls_pend-pro_nam = ls_proj1-jvnam.
        ls_pend-fisyear = p_year1.
        ls_pend-zperiod = s_period-low.
        ls_pend-approved_by  = ls_nvar-approved_by.
        ls_pend-approved_on  = ls_nvar-approved_on.
        ls_pend-approved_by_rp  = ls_nvar-approved_by_rp.
        ls_pend-approved_on_rp  = ls_nvar-approved_on_rp.
        ls_pend-created_by  = ls_nvar-created_by.
        ls_pend-created_on  = ls_nvar-created_on.
        APPEND ls_pend TO lt_pend_fin.
        CLEAR ls_pend.
      ENDLOOP.
    ENDLOOP.
  ELSE.
    LOOP AT lt_proj1 INTO ls_proj1.
      READ TABLE lt_pend INTO DATA(ls_pend) WITH KEY pro_nam = ls_proj1-jvnam zperiod = s_period-low.
      IF ls_pend-approved_by IS NOT INITIAL.
        ls_pend-status = 'Approved'.
      ELSE.
        ls_pend-company = ls_proj1-company.
        ls_pend-bukrs   = ls_proj1-bukrs.
        ls_pend-pro_nam = ls_proj1-jvnam.
        ls_pend-fisyear = p_year1.
        ls_pend-zperiod = s_period-low.
        ls_pend-status  = 'Pending'.
      ENDIF.

      APPEND ls_pend TO lt_pend_fin.
      CLEAR ls_pend.
    ENDLOOP.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FCAT_FILL_PEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fcat_fill_pend .
  IF r_var = 'X' OR r_nvar = 'X'.


    REFRESH it_fcat[].
    PERFORM alv_fcat_pend USING :  'COMPANY'       'Company',
                                   'BUKRS'         'Company Code',
                                   'PRO_NAM'       'Joint Venture',
                                   'FISYEAR'       'Fiscal Year',
                                   'ZPERIOD'       'Period',
                                   'FISYEAR1'      'Comparison Year',
                                   'ZPERIOD1'      'Comparison Period',
                                   'STATUS'        'Status',
                                   'CREATED_BY'    'Created By',
                                   'CREATED_ON'    'Created On',
                                   'APPROVED_BY'   'Approved By(I/C FIN)',
                                   'APPROVED_ON'   'Approved On(I/C FIN)',
                                   'APPROVED_BY_RP' 'Approved By(RP)',
                                   'APPROVED_ON_RP'  'Approved On(RP)'.
  ELSE.

    REFRESH it_fcat[].
    PERFORM alv_fcat_pend USING :  'COMPANY'       'Company',
                                   'BUKRS'         'Company Code',
                                   'PRO_NAM'       'Joint Venture',
                                   'FISYEAR'       'Fiscal Year',
                                   'ZPERIOD'       'Period',
                                   'STATUS'        'Status',
                                   'CREATED_BY'    'Created By',
                                   'CREATED_ON'    'Created On',
                                   'APPROVED_BY'   'Approved By(I/C FIN)',
                                   'APPROVED_ON'   'Approved On(I/C FIN)',
                                   'APPROVED_BY_RP' 'Approved By(RP)',
                                   'APPROVED_ON_RP'  'Approved On(RP)'.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_FCAT_PEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2299   text
*      -->P_2300   text
*----------------------------------------------------------------------*
FORM alv_fcat_pend  USING    VALUE(p_2299)
                             VALUE(p_2300).

  wa_fcat-fieldname   = p_2299.
  wa_fcat-seltext_l   = p_2300.
  wa_fcat-no_zero     = 'X'.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_PEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display_pend .
  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.
  CLEAR lt_pend.
  REFRESH lt_pend[].

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-cprog
      i_callback_top_of_page = 'TOP_OF_PAGE_PEND'
      is_layout              = wa_layout
      it_fieldcat            = it_fcat
      i_default              = 'X'
      i_save                 = 'U'
    TABLES
      t_outtab               = lt_pend_fin
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
    MESSAGE 'Data not Found' TYPE 'E'  DISPLAY LIKE 'I'.
* Implement suitable error handling here
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_PEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM top_of_page_pend .

  REFRESH int_header[].
  fs_header-typ = 'H'.
  fs_header-info = 'Pending Inputs Report'.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  CONCATENATE 'Fiscal Year :- ' p_year1 INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  fs_header-typ = 'S'.
  CONCATENATE 'Period :- ' s_period-low INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtcc bukrs FROM zfi_pnl_proj INTO TABLE it_comp
                       WHERE bukrs = p_comp1.

  READ TABLE it_comp INTO DATA(wa_comp) WITH KEY bukrs = p_comp1.
  fs_header-typ = 'S'.
  CONCATENATE 'Company code :- ' wa_comp-bukrs ' - ' wa_comp-txtcc INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.

  SELECT txtjv jvnam FROM zfi_pnl_proj INTO TABLE it_proj
                       WHERE jvnam = p_proj1-low.

  READ TABLE it_proj INTO DATA(wa_proj) WITH KEY jvnam = p_proj1-low.
  fs_header-typ = 'S'.
  CONCATENATE 'Project :- ' wa_proj-jvnam ' - ' wa_proj-txtjv  INTO fs_header-info SEPARATED BY space.
  APPEND fs_header TO int_header.
  CLEAR fs_header.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = int_header.


ENDFORM. "TOP_OF_PAGE_PEND
*&---------------------------------------------------------------------*
*&      Form  ATTACHMENTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM attachments.

  IF mode = 'CHA' OR mode = 'APP' OR mode = 'APF'.

    DATA lv_ip_mode TYPE c.
    CLEAR : lv_attano,la_gos_dis.

    la_gos_dis-objtype = 'ZGOS2'.
    CONCATENATE 'ZFIPL' p_proj p_year s_period_low INTO lv_attano.
    la_gos_dis-instid  = lv_attano.
    la_gos_dis-catid  = 'BO'.

    IF ( mode = 'APP'  OR mode = 'APF') AND ( stat = 'APPROVED' OR stat = 'FREEZED' ). "" cannot delete/create attachments after data is approved
      lv_ip_mode = 'D'.
    ELSE.
      lv_ip_mode = 'C'.         "" create/change/display/delete
    ENDIF.

    CALL FUNCTION 'GOS_ATTACHMENT_LIST_POPUP'
      EXPORTING
        is_object      = la_gos_dis
        ip_attachments = 'X'
        ip_mode        = lv_ip_mode.


  ELSEIF mode = 'DIS' OR mode = 'FRE'.
    CLEAR : lv_attano,la_gos_dis.

    la_gos_dis-objtype = 'ZGOS2'.
    CONCATENATE 'ZFIPL' p_proj p_year s_period_low INTO lv_attano.
    la_gos_dis-instid  = lv_attano.
    la_gos_dis-catid  = 'BO'.

    CALL FUNCTION 'GOS_ATTACHMENT_LIST_POPUP'
      EXPORTING
        is_object = la_gos_dis.


  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PROCESS_GUIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_guide .

  IF sy-uname CA sy-abcde.

    DATA lv_ip_mode TYPE c.
    CLEAR : lv_attano,la_gos_dis.

    la_gos_dis-objtype = 'ZGOS2'.
    lv_attano = 'ZFIPLPROCESSGUIDE'.
    la_gos_dis-instid  = lv_attano.
    la_gos_dis-catid  = 'BO'.
    lv_ip_mode = 'C'. "create/change/display/delete

    CALL FUNCTION 'GOS_ATTACHMENT_LIST_POPUP'
      EXPORTING
        is_object      = la_gos_dis
        ip_attachments = 'X'
        ip_mode        = lv_ip_mode.

  ELSE.

    MESSAGE 'To update attachment list contact SAP core team. Continue to view process guide.' TYPE 'S'.

    CLEAR : lv_attano,la_gos_dis.

    la_gos_dis-objtype = 'ZGOS2'.
    lv_attano = 'ZFIPLPROCESSGUIDE'.
    la_gos_dis-instid  = lv_attano.
    la_gos_dis-catid  = 'BO'.

    CALL FUNCTION 'GOS_ATTACHMENT_LIST_POPUP'
      EXPORTING
        is_object = la_gos_dis.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_FCAT_VAR_PRD1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_6969   text
*      -->P_6970   text
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  APPROVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM approver .
  BREAK abapuser02.
  SELECT SINGLE * FROM zfi_pl_status INTO @DATA(wa_status) WHERE period = @s_period-low
                                            AND period2 = @s_period_low2
                                            AND fiscal = @p_year1
                                            AND fiscal2 = @p_year2
                                            AND proj = @p_proj1-low
                                            AND p_compy1 = @p_compy1
                                            AND comp = @p_comp1.
  IF wa_status-status IS NOT INITIAL.
    MESSAGE 'Data has been already Approved' TYPE 'E'.
  ENDIF.

  wa_zfi_status-mandt  = sy-mandt.
  wa_zfi_status-period = s_period-low.
  wa_zfi_status-period2 = s_period_low2.
  wa_zfi_status-fiscal = p_year1.
  wa_zfi_status-fiscal2 = p_year2.
  wa_zfi_status-proj = p_proj1-low.
  wa_zfi_status-comp = p_comp1.
  wa_zfi_status-p_compy1 = p_compy1.
  wa_zfi_status-approved_on = sy-datum.
  wa_zfi_status-approved_by = sy-uname.
  wa_zfi_status-created_on = wa_status-created_on.
  wa_zfi_status-created_by = wa_status-created_by.


  wa_zfi_status-status_cre = 'X'.
  wa_zfi_status-status = 'X'.
  APPEND wa_zfi_status TO  it_zfi_status  .
  CLEAR  wa_zfi_status.

  MODIFY zfi_pl_status FROM TABLE it_zfi_status.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Data Approved Successfully' TYPE 'S'.
    CLEAR: wa_zfi_status.
    REFRESH : it_zfi_status.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  APPROVER1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM approver1 .
  SELECT SINGLE * FROM zfi_pl_status_n INTO @DATA(wa_status1) WHERE period = @s_period-low
                                              AND period2  = @s_period_low2
                                              AND fiscal   = @p_year1
                                              AND fiscal2   = @p_year2
                                              AND proj     = @p_proj1-low
                                              AND p_compy1 = @p_compy1
                                              AND comp     = @p_comp1.
  IF wa_status1-status IS NOT INITIAL.
    MESSAGE 'Data has been already Approved' TYPE 'E'.
  ENDIF.

  wa_zfi_status1-mandt    = sy-mandt.
  wa_zfi_status1-period   = s_period-low.
  wa_zfi_status1-period2  = s_period_low2.
  wa_zfi_status1-fiscal   = p_year1.
  wa_zfi_status1-fiscal2   = p_year2.
  wa_zfi_status1-proj     = p_proj1-low.
  wa_zfi_status1-comp     = p_comp1.
  wa_zfi_status1-p_compy1 = p_compy1.
  wa_zfi_status1-approved_on = sy-datum.
  wa_zfi_status1-approved_by = sy-uname.
  wa_zfi_status1-created_on = wa_status1-created_on.
  wa_zfi_status1-created_by = wa_status1-created_by.
  wa_zfi_status1-status_cre = 'X'.
  wa_zfi_status1-status = 'X'.
  APPEND wa_zfi_status1 TO  it_zfi_status1  .
  CLEAR  wa_zfi_status1.

  MODIFY zfi_pl_status_n FROM TABLE it_zfi_status1.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Data Approved Successfully' TYPE 'S'.
    CLEAR: wa_zfi_status1.
    REFRESH : it_zfi_status1.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_9001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9001 OUTPUT.
  CLEAR :    id ,language,name,object,lv_ucomm2.
  REFRESH it_lines .

  IF sy-ucomm = 'LONGTEXT'.
    CLEAR: g_editor, g_mycontainer, wa_texttable.
    REFRESH : i_texttable[].

    IF g_editor IS INITIAL.
      IMPORT lv_ucomm TO lv_ucomm2 FROM MEMORY ID 'A1'.
      IF lv_ucomm2 = 'DISPLAY'.
        SET PF-STATUS 'STATUS_T' EXCLUDING 'SAVE'.
      ELSE.
        SET PF-STATUS 'STATUS_T'.

      ENDIF.
      FREE MEMORY ID 'A1'.
      SET TITLEBAR 'TITLE2'.

      CREATE OBJECT g_editor_container
        EXPORTING
          container_name              = 'EDIT_CONT2'
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.
      IF sy-subrc NE 0.
      ENDIF.
      g_mycontainer = 'EDIT_CONT2'.

      CREATE OBJECT g_editor
        EXPORTING
          parent                     = g_editor_container
          wordwrap_mode              =
                                       cl_gui_textedit=>wordwrap_at_fixed_position
          wordwrap_position          = '50'
          wordwrap_to_linebreak_mode = cl_gui_textedit=>true.

      g_container_linked = 1.

      REFRESH g_mytable.

    ENDIF.


    CALL METHOD g_editor_container->link
      EXPORTING
        repid     = g_repid
        container = g_mycontainer.

    CALL METHOD g_editor->set_toolbar_mode
      EXPORTING
        toolbar_mode = cl_gui_textedit=>false.

    CALL METHOD g_editor->set_statusbar_mode
      EXPORTING
        statusbar_mode = cl_gui_textedit=>false.


    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.

    CALL METHOD g_editor->delete_text
      EXCEPTIONS
        error_cntl_call_method = 1                " Error while setting property of TextEdit control!
        OTHERS                 = 2.


    READ TABLE it_final_non INTO wa_final_non WITH KEY sel = 'X'.
    IF sy-subrc = 0.
      object = 'ZREMARK1'.
      id = 'ZAD1'.
      language = sy-langu.
      CONCATENATE p_proj1-low  s_period-low  s_period_low2  p_year1 wa_final_non-per INTO name.
*      name =  wa_final_non-per.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          client                  = sy-mandt
          id                      = id
          language                = language
          name                    = name
          object                  = object
        TABLES
          lines                   = it_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      IF it_lines IS NOT INITIAL.

        REFRESH: g_mytable,i_texttable.

        CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
          EXPORTING
            language    = sy-langu
          TABLES
            itf_text    = it_lines
            text_stream = i_texttable.

        CALL METHOD cl_gui_cfw=>flush
          EXCEPTIONS
            OTHERS = 1.

        IF sy-subrc NE 0.

        ENDIF.

        CALL METHOD g_editor->set_text_as_r3table
          EXPORTING
            table           = i_texttable                 " table with text
          EXCEPTIONS
            error_dp        = 1                " Error while sending R/3 table to TextEdit control!
            error_dp_create = 2                " ERROR_DP_CREATE
            OTHERS          = 3.

        IF sy-subrc <> 0.

        ENDIF.

        CALL METHOD g_editor->get_text_as_stream
          IMPORTING
            text                   = i_texttable        " text as stream with carrige retruns and linefeeds
            is_modified            = val1               " modify status of text
          EXCEPTIONS
            error_dp               = 1                  " Error while retrieving text table via DataProvider control!
            error_cntl_call_method = 2                  " Error while retrieving a property from TextEdit control
            OTHERS                 = 3.

        IF sy-subrc <> 0.

        ENDIF.
      ELSE.

        wa_texttable-line = wa_final_non-remark.
        APPEND wa_texttable TO i_texttable.
        CLEAR  wa_texttable.
      ENDIF.

      IF i_texttable IS NOT INITIAL.
        CALL METHOD g_editor->set_text_as_r3table
          EXPORTING
            table           = i_texttable                 " table with text
          EXCEPTIONS
            error_dp        = 1                " Error while sending R/3 table to TextEdit control!
            error_dp_create = 2                " ERROR_DP_CREATE
            OTHERS          = 3.
        IF sy-subrc <> 0.

        ENDIF.

        CALL METHOD g_editor->get_text_as_stream
          IMPORTING
            text                   = i_texttable        " text as stream with carrige retruns and linefeeds
            is_modified            = val1               " modify status of text
          EXCEPTIONS
            error_dp               = 1                  " Error while retrieving text table via DataProvider control!
            error_cntl_call_method = 2                  " Error while retrieving a property from TextEdit control
            OTHERS                 = 3.
        IF sy-subrc <> 0.

        ENDIF.

      ENDIF.

    ENDIF.
    REFRESH it_lines.
    CLEAR :id , object  ,name .
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9001 INPUT.
  CASE sy-ucomm.
    WHEN 'CLOSE'.
      PERFORM clear_container.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM editor_to_alv1.
      PERFORM clear_container.
      LEAVE TO SCREEN 0.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  CRE_PRD_QTY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cre_prd_qty .
  BREAK abapuser02.
*  PERFORM fetch_quant.
  SELECT txtjv
         jvnam
  FROM   zfi_pnl_proj
  INTO   TABLE it_proj
         WHERE
        prod  = 'YES'.

  IF it_proj IS NOT INITIAL.
    SELECT *
    FROM   zpnl_qi_oil
    INTO   TABLE @DATA(it_q1)
           FOR ALL ENTRIES IN @it_proj
           WHERE pro_nam = @it_proj-jvnam
           AND   fisyear = @p_year1
           AND   zperiod = @s_period-low .
*           AND   bukrs = @p_comp.

    SELECT *
    FROM   zpnl_qi_oil
    INTO   TABLE @DATA(it_q2)
           FOR ALL ENTRIES IN @it_proj
           WHERE pro_nam = @it_proj-jvnam
           AND   fisyear = @p_year2
           AND zperiod = @s_period_low2.
*           bukrs = @p_comp.

    SELECT *
   FROM   zpnl_qi_oil
   INTO   TABLE @DATA(it_h1)
          FOR ALL ENTRIES IN @it_proj
          WHERE pro_nam = @it_proj-jvnam
          AND   fisyear = @p_year2
          AND zperiod = 'H1'.

    SELECT *
     FROM   zpnl_qi_oil
     INTO   TABLE @DATA(it_9m)
            FOR ALL ENTRIES IN @it_proj
            WHERE pro_nam = @it_proj-jvnam
            AND   fisyear = @p_year2
            AND zperiod = '9M'.
    SELECT *
FROM   zpnl_qi_oil
INTO   TABLE @DATA(it_q11)
      FOR ALL ENTRIES IN @it_proj
      WHERE pro_nam = @it_proj-jvnam
      AND   fisyear = @p_year2
      AND zperiod = 'Q1'.

    SELECT *
 FROM   zpnl_qi_gas
 INTO   TABLE @DATA(it_q3)
        FOR ALL ENTRIES IN @it_proj
        WHERE pro_nam = @it_proj-jvnam
        AND   fisyear = @p_year1
        AND   zperiod = @s_period-low .
*           AND   bukrs = @p_comp.

    SELECT *
    FROM   zpnl_qi_gas
    INTO   TABLE @DATA(it_q4)
           FOR ALL ENTRIES IN @it_proj
           WHERE pro_nam = @it_proj-jvnam
           AND   fisyear = @p_year2
           AND zperiod = @s_period_low2.
*           bukrs = @p_comp.
  ENDIF.
  REFRESH : it_oil.
  LOOP AT it_proj INTO DATA(wa_proj).
    wa_oil-jv = wa_proj-txtjv.
    wa_oil-jv_name = wa_proj-jvnam.

    TRY.
        DATA(wa_q1) = it_q1[ pro_nam = wa_proj-jvnam ].
        CONDENSE: wa_q1-sh_prod,wa_q1-tot_sal.
        wa_oil-sh_prd_q1  = wa_q1-sh_prod * '0.000001'.
        wa_oil-tot_sal_q1 = wa_q1-tot_sal * '0.000001'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
    IF s_period_low2 = 'Q2'.

      TRY.
          DATA(wa_h1) = it_h1[ pro_nam = wa_proj-jvnam ].
*          CONDENSE: wa_q2-sh_prod,wa_q2-tot_sal.
*          wa_oil-sh_prd_q2  = wa_q2-sh_prod * '0.000001'.
*          wa_oil-tot_sal_q2 = wa_q2-tot_sal * '0.000001'.

        CATCH cx_sy_itab_line_not_found.
      ENDTRY.

      TRY.
          DATA(wa_q11) = it_q11[ pro_nam = wa_proj-jvnam ].
*          CONDENSE: wa_q2-sh_prod,wa_q2-tot_sal.
*          wa_oil-sh_prd_q2  = wa_q2-sh_prod * '0.000001'.
*          wa_oil-tot_sal_q2 = wa_q2-tot_sal * '0.000001'.

        CATCH cx_sy_itab_line_not_found.
          wa_oil-sh_prd_q2  = ( wa_h1-sh_prod - wa_q11-sh_prod ) * '0.000001'.
          wa_oil-tot_sal_q2 = ( wa_h1-tot_sal - wa_q11-tot_sal )  * '0.000001'.
      ENDTRY.


*      CONDENSE:  wa_q2-sh_prod ,wa_q2-tot_sal.
      wa_oil-sh_prd_q2  = ( wa_h1-sh_prod - wa_q11-sh_prod ) * '0.000001'.
      wa_oil-tot_sal_q2 = ( wa_h1-tot_sal - wa_q11-tot_sal )  * '0.000001'.

    ELSE.
      TRY.
          DATA(wa_q2) = it_q2[ pro_nam = wa_proj-jvnam ].
          CONDENSE: wa_q2-sh_prod,wa_q2-tot_sal.
          wa_oil-sh_prd_q2  = wa_q2-sh_prod * '0.000001'.
          wa_oil-tot_sal_q2 = wa_q2-tot_sal * '0.000001'.

        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
    ENDIF.
    TRY.
        DATA(wa_q3) = it_q3[ pro_nam = wa_proj-jvnam ].
        CONDENSE: wa_q3-sh_prod,wa_q3-tot_sal.
        wa_oil-gas1 = wa_q3-sh_prod * '0.006290'.
        wa_oil-gas2 = wa_q3-tot_sal * '0.006290'.
        wa_oil-gas3 = wa_q3-sh_prod.
        wa_oil-gas4 = wa_q3-tot_sal.
        wa_oil-gas5 = wa_q3-sh_prod * wa_final_conv-mmscm_mmbtu.
        wa_oil-gas6 =  wa_q3-tot_sal * wa_final_conv-mmscm_mmbtu.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        DATA(wa_q4) = it_q4[ pro_nam = wa_proj-jvnam ].
        CONDENSE: wa_q4-sh_prod,wa_q4-tot_sal.
        wa_oil-gas7 = wa_q3-sh_prod * '0.006290'.
        wa_oil-gas8 = wa_q3-tot_sal * '0.006290'.
        wa_oil-gas9 = wa_q3-sh_prod.
        wa_oil-gas10 = wa_q3-tot_sal.
        wa_oil-gas11 = wa_q3-sh_prod * wa_final_conv-mmscm_mmbtu.
        wa_oil-gas12 =  wa_q3-tot_sal * wa_final_conv-mmscm_mmbtu.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    APPEND wa_oil TO it_oil.
    CLEAR : wa_oil , wa_h1 , wa_q11.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FCAT_FILL_PRD_QTY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fcat_fill_prd_qty .

  wa_fcat-fieldname   = 'JV_NAME'.
  wa_fcat-seltext_l   = 'VENTURE NAME'.
  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  wa_fcat-fieldname   = 'JV'.
  wa_fcat-seltext_l   = 'JOINT VENTURE'.
  wa_fcat-no_zero     = 'X'.
*  wa_fcat-outputlen = 20.
  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'CRUDE OIL(MMBBL)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'SH_PRD_Q1'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(MMBBL)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'SH_PRD_Q2'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(MMBBL)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'TOT_SAL_Q1'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(MMBBL)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'TOT_SAL_Q2'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(MMBOE)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS1'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(MMBOE)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS7'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(MMBOE)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS2'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year2 s_period_low2 'GAS(MMBOE)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS8'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'GAS(MMSCM)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS3'.
*  wa_fcat-seltext_l   = 'GAS(MMSCM)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year2 s_period_low2 'GAS(MMSCM)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS9'.
*  wa_fcat-seltext_l   = 'GAS(MMSCM)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(MMSCM)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS4'.
*
*  wa_fcat-seltext_l   = 'GAS(MMSCM)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(MMSCM)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS10'.
*  wa_fcat-seltext_l   = 'GAS(MMSCM)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(MMBTU)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS5'.
*  wa_fcat-seltext_l   = 'GAS(MMBTU)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(MMBTU)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS11'.
*  wa_fcat-seltext_l   = 'GAS(MMBTU)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(MMBTU)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS6'.
*  wa_fcat-seltext_l   = 'GAS(MMBTU)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(MMBTU)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS12'.
*  wa_fcat-seltext_l   = 'GAS(MMBTU)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_PRD_QTY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display_prd_qty .
  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-cprog
      is_layout          = wa_layout
      it_fieldcat        = it_fcat
      i_default          = 'X'
      i_save             = 'A'
    TABLES
      t_outtab           = it_oil
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRE_REV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cre_rev .
  BREAK abapuser02.

  SELECT txtjv
         jvnam
  FROM   zfi_pnl_proj
  INTO   TABLE it_proj
         WHERE prod  = 'YES'.

  IF it_proj IS NOT INITIAL.

***************** FOR FIRST PERIOD <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda1)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal1 = @p_year1
    AND   period1 = @s_period-low
    AND   per_key = 'A2'.

    IF it_agenda1 IS INITIAL.

      SELECT *
      FROM   zfi_agenda
      INTO   TABLE @DATA(it_agenda2)
             FOR ALL ENTRIES IN @it_proj
      WHERE proj    = @it_proj-jvnam
      AND   fiscal2 = @p_year1
      AND   period2 = @s_period-low
      AND   per_key = 'A2'.
    ENDIF.

    IF it_agenda2 IS INITIAL.

      SELECT *
      FROM   zfi_agenda
      INTO   TABLE @DATA(it_agenda3)
             FOR ALL ENTRIES IN @it_proj
      WHERE proj    = @it_proj-jvnam
      AND   fiscal3 = @p_year1
      AND   period3 = @s_period-low
      AND   per_key = 'A2'.

    ENDIF.
    IF it_agenda3 IS INITIAL.

      SELECT *
      FROM   zfi_agenda
      INTO   TABLE @DATA(it_agenda4)
             FOR ALL ENTRIES IN @it_proj
      WHERE proj    = @it_proj-jvnam
      AND   fiscal4 = @p_year1
      AND   period4 = @s_period-low
      AND   per_key = 'A2'.
    ENDIF.

************************************* FOR SECOND PERIOD<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda5)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal1 = @p_year2
    AND period1  = @s_period_low2
    AND   per_key = 'A2'.

    IF it_agenda5 IS INITIAL.
      SELECT *
        FROM   zfi_agenda
        INTO   TABLE @DATA(it_agenda6)
               FOR ALL ENTRIES IN @it_proj
        WHERE proj    = @it_proj-jvnam
        AND   fiscal2 = @p_year2
        AND period2  = @s_period_low2
        AND   per_key = 'A2'.

    ENDIF.

    IF it_agenda6 IS INITIAL.
      SELECT *
       FROM   zfi_agenda
       INTO   TABLE @DATA(it_agenda7)
              FOR ALL ENTRIES IN @it_proj
       WHERE proj    = @it_proj-jvnam
       AND   fiscal3 = @p_year2
       AND period3  = @s_period_low2
       AND   per_key = 'A2'.

    ENDIF.

    IF it_agenda7 IS INITIAL.
      SELECT *
       FROM   zfi_agenda
       INTO   TABLE @DATA(it_agenda8)
              FOR ALL ENTRIES IN @it_proj
       WHERE proj    = @it_proj-jvnam
       AND   fiscal4 = @p_year2
       AND period4  = @s_period_low2
       AND   per_key = 'A2'.

    ENDIF.

  ENDIF.
  REFRESH it_oil1.
  LOOP AT it_proj INTO DATA(wa_proj).
    wa_oil1-jv       = wa_proj-jvnam.
    wa_oil1-jv_name  = wa_proj-txtjv.
*
*    TRY.
*        wa_oil1-sh_prd_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ]-crude_oil1.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        wa_oil1-tot_sal_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' ]-gas1.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        wa_oil1-sh_prd_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ]-crude_oil2.
*
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*    TRY.
*        wa_oil1-tot_sal_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' ]-gas2.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.

    LOOP AT it_agenda1 INTO DATA(wa_agenda) WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil1.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-gas1.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil1.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil1.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil1.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil1.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil1.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil1.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil1.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil1.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas1      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.

*****************    FOR Q2
    LOOP AT it_agenda2 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil2.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-gas2.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil2.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil2.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil2.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil2.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil2.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil2.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil2.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil2.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas2      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.

************************FOR Q3

    LOOP AT it_agenda3 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil3.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-crude_oil3.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil3.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil3.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil3.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil3.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil3.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil3.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil3.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil3.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas3      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.
*************************FOR Q4

    LOOP AT it_agenda4 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil4.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-crude_oil4.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil4.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil4.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas4     .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil4.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil4.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil4.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil4.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil4.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil4.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas4      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.


*    CLEAR: wa_agenda.
****************** FOR Q1
    LOOP AT it_agenda5 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil1.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas1.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil1.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil1.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil1.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil1.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil1.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil1.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil1.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil1.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas1      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
***************    FOR Q2
    LOOP AT it_agenda6 INTO wa_agenda WHERE proj = wa_proj-jvnam.

      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil2.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas2.
      ENDIF.

      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil2.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil2.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil2.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas2     .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil2.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas2     .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil2.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil2.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas2     .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil2.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil2.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas2      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
******************    FOR Q3

    LOOP AT it_agenda7 INTO wa_agenda WHERE proj = wa_proj-jvnam.

      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil3.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas3.
      ENDIF.

      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil3.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil3.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil3.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil3.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil3.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil3.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil3.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil3.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas3      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
************************    FOR Q4
    LOOP AT it_agenda8 INTO wa_agenda WHERE proj = wa_proj-jvnam.

      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil4.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas4.
      ENDIF.

      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil4.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil4.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil4.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil4.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil4.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil4.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil4.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil4.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas4      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
    APPEND wa_oil1 TO it_oil1.
    CLEAR: wa_oil1, wa_proj, wa_agenda.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FCAT_FILL_REV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fcat_fill_rev .


  wa_fcat-fieldname   = 'JV'.
  wa_fcat-seltext_l   = 'JOINT VENTURE'.
  wa_fcat-no_zero     = 'X'.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  wa_fcat-fieldname   = 'JV_NAME'.
  wa_fcat-seltext_l   = 'VENTURE NAME'.
*  wa_fcat-no_zero     = 'X'.
*  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(SR)' INTO  wa_fcat-seltext_l SEPARATED BY space..
  wa_fcat-fieldname   = 'SH_PRD_Q1'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(SR)' INTO  wa_fcat-seltext_l SEPARATED BY space..
  wa_fcat-fieldname   = 'SH_PRD_Q2'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS1'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS13'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS3'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS15'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS5'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS17'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'CRUDE OIL(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS7'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS19'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'CRUDE OIL(S&DW)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS9'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(S&DW)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS21'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(OC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS11'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(OC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS23'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS25'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS27'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS29'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS31'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(SR)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'TOT_SAL_Q1'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(SR)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'TOT_SAL_Q2'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year1 s_period-low'GAS(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS2'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS14'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.





  CONCATENATE p_year1 s_period-low 'GAS(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS4'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS16'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'GAS(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS6'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS18'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year1 s_period-low 'GAS(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS8'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS20'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.




  CONCATENATE p_year1 s_period-low 'GAS(S&DW)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS10'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.




  CONCATENATE p_year2 s_period_low2 'GAS(S&DW)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS22'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'GAS(OC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS12'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(OC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS24'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS26'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS28'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS30'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS32'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_REV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display_rev .

  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-cprog
      is_layout          = wa_layout
      it_fieldcat        = it_fcat
      i_default          = 'X'
      i_save             = 'A'
    TABLES
      t_outtab           = it_oil1
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRE_BAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cre_bar .
  BREAK abapuser02.
  BREAK abapuser02.
  SELECT txtjv
         jvnam
  FROM   zfi_pnl_proj
  INTO   TABLE it_proj
         WHERE prod  = 'YES'.

  IF it_proj IS NOT INITIAL.

***************** FOR FIRST PERIOD <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda1)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal1 = @p_year1
    AND   period1 = @s_period-low
    AND   per_key = 'A3'.

    IF it_agenda1 IS INITIAL.

      SELECT *
      FROM   zfi_agenda
      INTO   TABLE @DATA(it_agenda2)
             FOR ALL ENTRIES IN @it_proj
      WHERE proj    = @it_proj-jvnam
      AND   fiscal2 = @p_year1
      AND   period2 = @s_period-low
      AND   per_key = 'A3'.
    ENDIF.

    IF it_agenda2 IS INITIAL.

      SELECT *
      FROM   zfi_agenda
      INTO   TABLE @DATA(it_agenda3)
             FOR ALL ENTRIES IN @it_proj
      WHERE proj    = @it_proj-jvnam
      AND   fiscal3 = @p_year1
      AND   period3 = @s_period-low
      AND   per_key = 'A3'.

    ENDIF.
    IF it_agenda3 IS INITIAL.

      SELECT *
      FROM   zfi_agenda
      INTO   TABLE @DATA(it_agenda4)
             FOR ALL ENTRIES IN @it_proj
      WHERE proj    = @it_proj-jvnam
      AND   fiscal4 = @p_year1
      AND   period4 = @s_period-low
      AND   per_key = 'A3'.
    ENDIF.

************************************* FOR SECOND PERIOD<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda5)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal1 = @p_year2
    AND period1  = @s_period_low2
    AND   per_key = 'A3'.

    IF it_agenda5 IS INITIAL.
      SELECT *
        FROM   zfi_agenda
        INTO   TABLE @DATA(it_agenda6)
               FOR ALL ENTRIES IN @it_proj
        WHERE proj    = @it_proj-jvnam
        AND   fiscal2 = @p_year2
        AND period2  = @s_period_low2
        AND   per_key = 'A3'.

    ENDIF.

    IF it_agenda6 IS INITIAL.
      SELECT *
       FROM   zfi_agenda
       INTO   TABLE @DATA(it_agenda7)
              FOR ALL ENTRIES IN @it_proj
       WHERE proj    = @it_proj-jvnam
       AND   fiscal3 = @p_year2
       AND period3  = @s_period_low2
       AND   per_key = 'A3'.

    ENDIF.

    IF it_agenda7 IS INITIAL.
      SELECT *
       FROM   zfi_agenda
       INTO   TABLE @DATA(it_agenda8)
              FOR ALL ENTRIES IN @it_proj
       WHERE proj    = @it_proj-jvnam
       AND   fiscal4 = @p_year2
       AND period4  = @s_period_low2
       AND   per_key = 'A3'.

    ENDIF.

  ENDIF.
  REFRESH it_oil1.
  LOOP AT it_proj INTO DATA(wa_proj).
    wa_oil1-jv       = wa_proj-jvnam.
    wa_oil1-jv_name  = wa_proj-txtjv.
*
*    TRY.
*        wa_oil1-sh_prd_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ]-crude_oil1.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        wa_oil1-tot_sal_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' ]-gas1.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        wa_oil1-sh_prd_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ]-crude_oil2.
*
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*    TRY.
*        wa_oil1-tot_sal_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' ]-gas2.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.

    LOOP AT it_agenda1 INTO DATA(wa_agenda) WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil1.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-gas1.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil1.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil1.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil1.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil1.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil1.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil1.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil1.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil1.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas1      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.

*****************    FOR Q2
    LOOP AT it_agenda2 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil2.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-gas2.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil2.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil2.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil2.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil2.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil2.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil2.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil2.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil2.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas2      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.

************************FOR Q3

    LOOP AT it_agenda3 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil3.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-crude_oil3.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil3.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil3.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil3.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil3.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil3.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil3.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil3.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil3.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas3      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.
*************************FOR Q4

    LOOP AT it_agenda4 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q1 = wa_agenda-crude_oil4.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q1 = wa_agenda-crude_oil4.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil4.
        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil4.
        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas4     .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil4.
        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil4.
        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil4.
        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas11  = wa_oil1-gas11  + wa_agenda-crude_oil4.
        wa_oil1-gas12 = wa_oil1-gas12 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil4.
        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil4.
        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas4      .
      ENDIF.

*      CLEAR wa_agenda.
    ENDLOOP.


*    CLEAR: wa_agenda.
****************** FOR Q1
    LOOP AT it_agenda5 INTO wa_agenda WHERE proj = wa_proj-jvnam.
      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil1.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas1.
      ENDIF.
      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil1.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil1.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil1.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil1.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil1.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil1.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil1.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas1      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil1.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas1      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
***************    FOR Q2
    LOOP AT it_agenda6 INTO wa_agenda WHERE proj = wa_proj-jvnam.

      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil2.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas2.
      ENDIF.

      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil2.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil2.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil2.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas2     .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil2.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas2     .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil2.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil2.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas2     .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil2.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas2      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil2.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas2      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
******************    FOR Q3

    LOOP AT it_agenda7 INTO wa_agenda WHERE proj = wa_proj-jvnam.

      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil3.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas3.
      ENDIF.

      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil3.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil3.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil3.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil3.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil3.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil3.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas3      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil3.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas3     .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil3.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas3      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
************************    FOR Q4
    LOOP AT it_agenda8 INTO wa_agenda WHERE proj = wa_proj-jvnam.

      IF wa_agenda-per =  'REVENUE FROM CRUDE OIL'.
        wa_oil1-sh_prd_q2 = wa_agenda-crude_oil4.
      ENDIF.

      IF wa_agenda-per =  'REVENUE FROM NATURAL GAS'.
        wa_oil1-tot_sal_q2 = wa_agenda-gas4.
      ENDIF.

      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil4.
        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil4.
        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil4.
        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil4.
        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil4.
        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(IV) OPERATING COST' .
        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil4.
        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
        wa_oil1-gas29  = wa_oil1-gas29  + wa_agenda-crude_oil4.
        wa_oil1-gas30 = wa_oil1-gas30 + wa_agenda-gas4      .
      ENDIF.
      IF wa_agenda-per = '(VIII) NET OPERATING MARGIN (I-VII)' .
        wa_oil1-gas31  = wa_oil1-gas31 + wa_agenda-crude_oil4.
        wa_oil1-gas32 = wa_oil1-gas32 + wa_agenda-gas4      .
      ENDIF.
*      CLEAR wa_agenda.
    ENDLOOP.
    APPEND wa_oil1 TO it_oil1.
    CLEAR: wa_oil1, wa_proj, wa_agenda.
  ENDLOOP.
*  SELECT txtjv
*         jvnam
*  FROM   zfi_pnl_proj
*  INTO   TABLE it_proj
*         WHERE prod  = 'YES'.
*
*  IF it_proj IS NOT INITIAL.
*
*    SELECT *
*    FROM   zfi_agenda
*    INTO   TABLE @DATA(it_agenda)
*           FOR ALL ENTRIES IN @it_proj
*    WHERE proj    = @it_proj-jvnam
*    AND   fiscal1 = @p_year1
*    AND   period1 = @s_period-low
*    AND   per_key = 'A3'.
*
*    SELECT *
*    FROM   zfi_agenda
*    INTO   TABLE @DATA(it_agenda2)
*           FOR ALL ENTRIES IN @it_proj
*    WHERE proj    = @it_proj-jvnam
*    AND   fiscal1 = @p_year2
*    AND   period1 = @s_period_low2
*    AND   per_key = 'A3'.
*
*  ENDIF.
*  REFRESH it_oil1.
*  LOOP AT it_proj INTO DATA(wa_proj).
*    wa_oil1-jv       = wa_proj-jvnam.
*    wa_oil1-jv_name  = wa_proj-txtjv.
*
*    TRY.
*        wa_oil1-sh_prd_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ]-crude_oil1.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        wa_oil1-tot_sal_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' ]-gas1.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    TRY.
*        wa_oil1-sh_prd_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ]-crude_oil2.
*******        DATA(wa_agenda2) = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' ].
*******        if wa_agenda2-crude_oil3 IS INITIAL and wa_agenda2-crude_oil4 IS INITIAL.
*******          wa_oil1-sh_prd_q2 = wa_agenda-crude_oil2.
*******        ELSEIF wa_agenda2-crude_oil2 IS INITIAL and wa_agenda2-crude_oil3 IS INITIAL.
*******           wa_oil1-sh_prd_q2 = wa_agenda-crude_oil4.
*******        ELSEIF wa_agenda2-crude_oil2 IS INITIAL and wa_agenda2-crude_oil4 IS INITIAL.
*******           wa_oil1-sh_prd_q2 = wa_agenda-crude_oil3.
*******        ENDIF.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*    TRY.
*        wa_oil1-tot_sal_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' ]-gas2.
*      CATCH cx_sy_itab_line_not_found.
*    ENDTRY.
*
*    LOOP AT it_agenda INTO DATA(wa_agenda) WHERE proj = wa_proj-jvnam..
*      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
*        wa_oil1-gas1 = wa_oil1-gas1 + wa_agenda-crude_oil1.
*        wa_oil1-gas2 = wa_oil1-gas2 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
*        wa_oil1-gas3 = wa_oil1-gas3 + wa_agenda-crude_oil1.
*        wa_oil1-gas4 = wa_oil1-gas4 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
*        wa_oil1-gas5 = wa_oil1-gas5 + wa_agenda-crude_oil1.
*        wa_oil1-gas6 = wa_oil1-gas6 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
*        wa_oil1-gas7 = wa_oil1-gas7 + wa_agenda-crude_oil1.
*        wa_oil1-gas8 = wa_oil1-gas8 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
*        wa_oil1-gas9  = wa_oil1-gas9  + wa_agenda-crude_oil1.
*        wa_oil1-gas10 = wa_oil1-gas10 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = '(IV) OPERATING COST' .
*        wa_oil1-gas11  = wa_oil1-gas9  + wa_agenda-crude_oil1.
*        wa_oil1-gas12 = wa_oil1-gas10 + wa_agenda-gas1      .
*      ENDIF.
*
*      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
*        wa_oil1-gas25  = wa_oil1-gas25  + wa_agenda-crude_oil1.
*        wa_oil1-gas26 = wa_oil1-gas26 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = '(XII) NET PROFIT/(LOSS) AFTER TAX (X-XI)' .
*        wa_oil1-gas27  = wa_oil1-gas27  + wa_agenda-crude_oil1.
*        wa_oil1-gas28 = wa_oil1-gas28 + wa_agenda-gas1      .
*      ENDIF.
*    ENDLOOP.
*
*    CLEAR: wa_agenda.
*    LOOP AT it_agenda2 INTO wa_agenda WHERE  proj = wa_proj-jvnam..
*      IF wa_agenda-per = 'PRODUCTION EXPENSES' OR wa_agenda-per = 'OTHER OPERATING EXPENSE'.
*        wa_oil1-gas13  = wa_oil1-gas13 + wa_agenda-crude_oil1.
*        wa_oil1-gas14  = wa_oil1-gas14 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'ROYALTY' OR wa_agenda-per = 'OTHER TAXES (AS APPLICABLE)'.
*        wa_oil1-gas15  = wa_oil1-gas15 + wa_agenda-crude_oil1.
*        wa_oil1-gas16  = wa_oil1-gas16 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'TRANSPORTATION EXPENSES'.
*        wa_oil1-gas17  = wa_oil1-gas17 + wa_agenda-crude_oil1.
*        wa_oil1-gas18  = wa_oil1-gas18 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'DEPLETION' OR wa_agenda-per = 'DEPRECIATION AND AMORTISATION'.
*        wa_oil1-gas19  = wa_oil1-gas19 + wa_agenda-crude_oil1.
*        wa_oil1-gas20  = wa_oil1-gas20 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = 'EXPLORATION COSTS(SURVEY)' OR wa_agenda-per = 'EXPLORATION COSTS(DRY WELL)'.
*        wa_oil1-gas21  = wa_oil1-gas21  + wa_agenda-crude_oil1.
*        wa_oil1-gas22  = wa_oil1-gas22  + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = '(IV) OPERATING COST' .
*        wa_oil1-gas23  = wa_oil1-gas23  + wa_agenda-crude_oil1.
*        wa_oil1-gas24  = wa_oil1-gas24  + wa_agenda-gas1      .
*      ENDIF.
*
*      IF wa_agenda-per = '(VII) COST OF GOODS SOLD (IV+V+VI)' .
*        wa_oil1-gas29  = wa_oil1-gas25  + wa_agenda-crude_oil1.
*        wa_oil1-gas30 = wa_oil1-gas26 + wa_agenda-gas1      .
*      ENDIF.
*      IF wa_agenda-per = '(XII) NET PROFIT/(LOSS) AFTER TAX (X-XI)' .
*        wa_oil1-gas31  = wa_oil1-gas27  + wa_agenda-crude_oil1.
*        wa_oil1-gas32 = wa_oil1-gas28 + wa_agenda-gas1      .
*      ENDIF.
*    ENDLOOP.
*
*    APPEND wa_oil1 TO it_oil1.
*    CLEAR: wa_oil1, wa_proj, wa_agenda.
*  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FCAT_FILL_BAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fcat_fill_bar .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_BAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display_bar .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRE_AGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cre_age .
  BREAK abapuser02.
  SELECT txtjv
        jvnam
 FROM   zfi_pnl_proj
 INTO   TABLE it_proj
        WHERE prod  = 'YES'.

  IF it_proj IS NOT INITIAL.

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal1 = @p_year1
    AND   period1 = @s_period-low
*    AND   per_key = 'A3'.
    AND   per_key IN ('A1','A2','A3').

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda2)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal1 = @p_year2
    AND   period1 = @s_period_low2
*    AND   per_key = 'A3'.
    AND   per_key IN ('A1','A2','A3').

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda3)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal2 = @p_year1
    AND   period2 = @s_period-low
    AND   per_key IN ('A1' ,'A2' ,'A3' ).

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda4)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal2 = @p_year2
    AND   period2 = @s_period_low2
    AND   per_key IN ('A1' ,'A2','A3').

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda5)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal3 = @p_year1
    AND   period3 = @s_period-low
    AND   per_key IN ('A1' ,'A2' ,'A3' ).

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda6)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal3 = @p_year2
    AND   period3 = @s_period_low2
    AND   per_key IN ('A1' ,'A2','A3').

    SELECT *
   FROM   zfi_agenda
   INTO   TABLE @DATA(it_agenda7)
          FOR ALL ENTRIES IN @it_proj
   WHERE proj    = @it_proj-jvnam
   AND   fiscal4 = @p_year1
   AND   period4 = @s_period-low
   AND   per_key IN ('A1' ,'A2' ,'A3' ).

    SELECT *
    FROM   zfi_agenda
    INTO   TABLE @DATA(it_agenda8)
           FOR ALL ENTRIES IN @it_proj
    WHERE proj    = @it_proj-jvnam
    AND   fiscal4 = @p_year2
    AND   period4 = @s_period_low2
    AND   per_key IN ('A1' ,'A2','A3').

  ENDIF.

  REFRESH it_oil2.
  LOOP AT it_proj INTO DATA(wa_proj).

    wa_oil2-jv       = wa_proj-jvnam.
    wa_oil2-jv_name  = wa_proj-txtjv.

    TRY.
        wa_oil2-sh_prd_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL'  per_key = 'A3'  ]-crude_oil1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-sh_prd_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' per_key = 'A3']-crude_oil2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-tot_sal_q1 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' per_key = 'A2' ]-crude_oil1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-tot_sal_q2 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' per_key = 'A2' ]-crude_oil2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas1 = it_agenda[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-crude_oil1.
        wa_oil2-gas1  =  wa_oil2-gas1 / '1000000'.

      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas2 = it_agenda2[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-crude_oil2.
        wa_oil2-gas2  =  wa_oil2-gas2 / '1000000'.

      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas3 = it_agenda[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-crude_oil1.

        wa_oil2-gas3  =  wa_oil2-gas3 / '1000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas4 = it_agenda2[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-crude_oil2.
        wa_oil2-gas4  =  wa_oil2-gas4 / '1000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas5 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A3' ]-gas1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


    TRY.
        wa_oil2-gas6 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A3' ]-gas2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


    TRY.
        wa_oil2-gas7 = it_agenda[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A2' ]-gas1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.



    TRY.
        wa_oil2-gas8 = it_agenda2[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A2' ]-gas2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas9 = it_agenda[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-gas1.
        wa_oil2-gas9  =  wa_oil2-gas9 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas10 = it_agenda2[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-gas2.
        wa_oil2-gas10 =  wa_oil2-gas10 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas11 = it_agenda[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-gas1.
        wa_oil2-gas11  =  wa_oil2-gas11 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas12 = it_agenda2[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-gas2.
        wa_oil2-gas12  =  wa_oil2-gas12 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

************************************for second********************************************

    TRY.
        wa_oil2-sh_prd_q1 = it_agenda3[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL'  per_key = 'A3'  ]-crude_oil1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-sh_prd_q2 = it_agenda4[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' per_key = 'A3']-crude_oil2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-tot_sal_q1 = it_agenda3[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' per_key = 'A2' ]-crude_oil1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-tot_sal_q2 = it_agenda4[ proj = wa_proj-jvnam per = 'REVENUE FROM CRUDE OIL' per_key = 'A2' ]-crude_oil2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas1 = it_agenda3[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-crude_oil1.
        wa_oil2-gas1  =  wa_oil2-gas1 / '1000000'.

      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas2 = it_agenda4[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-crude_oil2.
        wa_oil2-gas2  =  wa_oil2-gas2 / '1000000'.

      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas3 = it_agenda3[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-crude_oil1.

        wa_oil2-gas3  =  wa_oil2-gas3 / '1000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas4 = it_agenda4[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-crude_oil2.
        wa_oil2-gas4  =  wa_oil2-gas4 / '1000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas5 = it_agenda3[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A3' ]-gas1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


    TRY.
        wa_oil2-gas6 = it_agenda4[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A3' ]-gas2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.


    TRY.
        wa_oil2-gas7 = it_agenda3[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A2' ]-gas1.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.



    TRY.
        wa_oil2-gas8 = it_agenda4[ proj = wa_proj-jvnam per = 'REVENUE FROM NATURAL GAS' per_key = 'A2' ]-gas2.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas9 = it_agenda3[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-gas1.
        wa_oil2-gas9  =  wa_oil2-gas9 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas10 = it_agenda4[ proj = wa_proj-jvnam per = 'Total Sales quantity' per_key = 'A1' ]-gas2.
        wa_oil2-gas10 =  wa_oil2-gas10 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas11 = it_agenda3[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-gas1.
        wa_oil2-gas11  =  wa_oil2-gas11 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    TRY.
        wa_oil2-gas12 = it_agenda4[ proj = wa_proj-jvnam per = 'Share of Production' per_key = 'A1' ]-gas2.
        wa_oil2-gas12  =  wa_oil2-gas12 *  '2.000000'.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.



******************************************************************************************

    APPEND wa_oil2 TO it_oil2.
    CLEAR: wa_oil2, wa_proj, wa_agenda.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FCAT_FILL_AGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fcat_fill_age .

  wa_fcat-fieldname   = 'JV'.
  wa_fcat-seltext_l   = 'JOINT VENTURE'.
  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  wa_fcat-fieldname   = 'JV_NAME'.
  wa_fcat-seltext_l   = 'VENTURE NAME'.
  wa_fcat-no_zero     = 'X'.
*  wa_fcat-outputlen = 20.
  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'CRUDE OIL(SR)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'SH_PRD_Q1'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(SR)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'SH_PRD_Q2'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(REVENUE)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'TOT_SAL_Q1'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(REVENUE)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'TOT_SAL_Q2'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(MMT)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS1'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(MMT)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS2'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(MMT)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS3'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(MMT)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS4'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'GAS(SR)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS5'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(SR)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS6'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(REVENUE)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS7'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(REVENUE)' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS8'.
*  wa_fcat-seltext_l   = 'CRUDE OIL(MMBBL)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(BCM)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS9'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(BCM)TOT_SAL' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS10'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(BCM)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS11'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year2 s_period_low2 'GAS(BCM)SH_PROD' INTO  wa_fcat-seltext_l.
  wa_fcat-fieldname   = 'GAS12'.
*  wa_fcat-seltext_l   = 'GAS(MMBOE)'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 6.
*  wa_fcat-round        = 2.

  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.




ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY_AGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display_age .
  wa_layout-info_fieldname     = 'LINE_COLOR'.
  wa_layout-colwidth_optimize  = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-cprog
      is_layout          = wa_layout
      it_fieldcat        = it_fcat
      i_default          = 'X'
      i_save             = 'A'
    TABLES
      t_outtab           = it_oil2
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FCAT_FILL_BAR_REP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fcat_fill_bar_rep .
  wa_fcat-fieldname   = 'JV'.
  wa_fcat-seltext_l   = 'JOINT VENTURE'.
  wa_fcat-no_zero     = 'X'.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  wa_fcat-fieldname   = 'JV_NAME'.
  wa_fcat-seltext_l   = 'VENTURE NAME'.
*  wa_fcat-no_zero     = 'X'.
*  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(RP)' INTO  wa_fcat-seltext_l SEPARATED BY space..
  wa_fcat-fieldname   = 'SH_PRD_Q1'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(RP)' INTO  wa_fcat-seltext_l SEPARATED BY space..
  wa_fcat-fieldname   = 'SH_PRD_Q2'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS1'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS13'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS3'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS15'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS5'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS17'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'CRUDE OIL(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS7'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS19'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'CRUDE OIL(SC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS9'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(SC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS21'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS11'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS23'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(TOGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS25'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(TOGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS27'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'CRUDE OIL(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS29'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'CRUDE OIL(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS31'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(RP)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'TOT_SAL_Q1'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(RP)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'TOT_SAL_Q2'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year1 s_period-low'GAS(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS2'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(PC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS14'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.





  CONCATENATE p_year1 s_period-low 'GAS(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS4'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(Royality)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS16'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'GAS(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS6'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(TC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS18'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year1 s_period-low 'GAS(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS8'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(DDA)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS20'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.




  CONCATENATE p_year1 s_period-low 'GAS(SC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS10'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.




  CONCATENATE p_year2 s_period_low2 'GAS(SC)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS22'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.


  CONCATENATE p_year1 s_period-low 'GAS(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS12'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.



  CONCATENATE p_year2 s_period_low2 'GAS(COGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS24'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(TOGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS26'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(TOGS)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS28'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year1 s_period-low 'GAS(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS30'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.

  CONCATENATE p_year2 s_period_low2 'GAS(PM)' INTO  wa_fcat-seltext_l SEPARATED BY space.
  wa_fcat-fieldname   = 'GAS32'.
*  wa_fcat-no_zero     = 'X'.
  wa_fcat-decimals_out = 2.
  wa_fcat-round        = 2.
  APPEND wa_fcat TO it_fcat.
  CLEAR wa_fcat.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  APPROVEFI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM approvefi .

  SELECT SINGLE * FROM zfi_pl_status_n INTO @DATA(wa_status1) WHERE period = @s_period-low
                                               AND period2  = @s_period_low2
                                               AND fiscal   = @p_year1
                                               AND fiscal2   = @p_year2
                                               AND proj     = @p_proj1-low
                                               AND p_compy1 = @p_compy1
                                               AND comp     = @p_comp1.
  IF wa_status1-status_rp IS NOT INITIAL.
    MESSAGE 'Data has been already Approved' TYPE 'E'.
  ENDIF.

  wa_zfi_status1-mandt    = sy-mandt.
  wa_zfi_status1-period   = s_period-low.
  wa_zfi_status1-period2  = s_period_low2.
  wa_zfi_status1-fiscal   = p_year1.
  wa_zfi_status1-fiscal2   = p_year2.
  wa_zfi_status1-proj     = p_proj1-low.
  wa_zfi_status1-comp     = p_comp1.
  wa_zfi_status1-p_compy1 = p_compy1.
  wa_zfi_status1-approved_by_rp = sy-uname.
  wa_zfi_status1-approved_on_rp = sy-datum.
  wa_zfi_status1-approved_by = wa_status1-approved_by.
  wa_zfi_status1-approved_on = wa_status1-approved_on.
  wa_zfi_status1-created_on = wa_status1-created_on.
  wa_zfi_status1-created_by = wa_status1-created_by.
  wa_zfi_status1-status = wa_status1-status.
  wa_zfi_status1-status_cre = 'X'.
  wa_zfi_status1-status_rp = 'X'.
  APPEND wa_zfi_status1 TO  it_zfi_status1  .
  CLEAR  wa_zfi_status1.

  MODIFY zfi_pl_status_n FROM TABLE it_zfi_status1.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Data Approved Successfully' TYPE 'S'.
    CLEAR: wa_zfi_status1.
    REFRESH : it_zfi_status1.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  APPROVERFI1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM approverfi1 .
  BREAK abapuser02.
  SELECT SINGLE * FROM zfi_pl_status INTO @DATA(wa_status) WHERE period = @s_period-low
                                            AND period2 = @s_period_low2
                                            AND fiscal = @p_year1
                                            AND fiscal2 = @p_year2
                                            AND proj = @p_proj1-low
                                            AND p_compy1 = @p_compy1
                                            AND comp = @p_comp1.
  IF wa_status-status_rp IS NOT INITIAL.
    MESSAGE 'Data has been already Approved' TYPE 'E'.
  ENDIF.

  wa_zfi_status-mandt  = sy-mandt.
  wa_zfi_status-period = s_period-low.
  wa_zfi_status-period2 = s_period_low2.
  wa_zfi_status-fiscal = p_year1.
  wa_zfi_status-fiscal2 = p_year2.
  wa_zfi_status-proj = p_proj1-low.
  wa_zfi_status-comp = p_comp1.
  wa_zfi_status-p_compy1 = p_compy1.
  wa_zfi_status-approved_by_rp = sy-uname.
  wa_zfi_status-approved_on_rp = sy-datum.
  wa_zfi_status-approved_by = wa_status-approved_by.
  wa_zfi_status-approved_on = wa_status-approved_on.
  wa_zfi_status-created_on = wa_status-created_on.
  wa_zfi_status-created_by = wa_status-created_by.
  wa_zfi_status-status = wa_status-status.
  wa_zfi_status-status_cre = 'X'.

  wa_zfi_status-status_rp = 'X'.
  APPEND wa_zfi_status TO  it_zfi_status  .
  CLEAR  wa_zfi_status.

  MODIFY zfi_pl_status FROM TABLE it_zfi_status.
  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Data Approved Successfully' TYPE 'S'.
    CLEAR: wa_zfi_status.
    REFRESH : it_zfi_status.
  ENDIF.
ENDFORM.
