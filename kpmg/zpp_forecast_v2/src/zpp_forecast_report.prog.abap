*&---------------------------------------------------------------------*
*& Report  ZPP_FORECAST_REPORT   Transaction  ZFCST_RPT
*& ZFORECAST (Adhesive) - final forecast report
*&
*& Consolidates the annual, quarterly and monthly forecasts with their
*& additional quantities, per the "Final ALV" sheet.
*&---------------------------------------------------------------------*
REPORT zpp_forecast_report MESSAGE-ID zpp_fcst.

TABLES: marc, mara, zppt_fcst_yr, zppt_fcst_qt, zppt_fcst_mn.

TYPES: BEGIN OF ty_out,
         fcst_no    TYPE zde_fcst_no,
         werks      TYPE werks_d,
         matnr      TYPE matnr,
         maktx      TYPE maktx,
         matkl      TYPE matkl,
*BOC By Arnav on 31/08/26
*        MTS / MTO on the Final ALV as well as on the three planning
*        modes. It sits with the material attributes, which is where the
*        annual sheet draws it.
         mts_mto    TYPE zde_mts_mto,
*EOC By Arnav on 31/08/26
         mvgr1_txt  TYPE bezei20,
         mvgr2_txt  TYPE bezei20,
         mvgr3_txt  TYPE bezei20,
         mvgr4_txt  TYPE bezei20,
         mvgr5_txt  TYPE bezei20,
         fyear      TYPE zde_fyear,
         period     TYPE poper,
         quarter    TYPE zde_quarter,
         annual     TYPE zde_fcst_qty,
         qtr_fcst   TYPE zde_fcst_qty,
         qtr_add    TYPE zde_fcst_qty,
         qtr_total  TYPE zde_fcst_qty,
         mth_fcst   TYPE zde_fcst_qty,
         mth_add    TYPE zde_fcst_qty,
         mth_total  TYPE zde_fcst_qty,
         meins      TYPE meins,
*BOC By Arnav on 31/08/26
*        Price, asked for on the Final ALV as well. Drawn last, as it is
*        on the three planning modes, and EMPTY for the same reason -
*        where the figure comes from is still open with the functional
*        team. Typed as a plain packed field and not over a CURR data
*        element: a CURR column with no currency reference field makes
*        SALV raise CX_SALV_DATA_ERROR.
*        " ASSUMPTION: price is per base unit of measure, in the company
*        " code currency. To be confirmed before the logic is written.
         price      TYPE p LENGTH 13 DECIMALS 2,
*EOC By Arnav on 31/08/26
       END OF ty_out,
       tt_out TYPE STANDARD TABLE OF ty_out WITH DEFAULT KEY.

DATA gt_out TYPE tt_out.

*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
* The material group, quarter and period filters were declared over
* ZPPT_FCST_YR-FCST_NO and MARC-MATNR, which gave them the wrong length
* and a value help listing forecast numbers and materials. Each now sits
* on the field it actually filters, so the dictionary help is correct.
SELECT-OPTIONS: s_werks  FOR marc-werks,
                s_matnr  FOR marc-matnr,
                s_fcstno FOR zppt_fcst_yr-fcst_no,
                s_matkl  FOR mara-matkl NO INTERVALS.
PARAMETERS:     p_fyear  TYPE zde_fyear.
SELECT-OPTIONS: s_quart  FOR zppt_fcst_qt-quarter NO INTERVALS,
                s_perio  FOR zppt_fcst_mn-period  NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

*&---------------------------------------------------------------------*
INITIALIZATION.

  DATA(gv_y) = CONV i( sy-datum(4) ).
  IF sy-datum+4(2) < '04'.
    gv_y = gv_y - 1.
  ENDIF.
  p_fyear = |{ gv_y }-{ gv_y + 1 }|.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fyear.

  PERFORM f4_fyear.

*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  IF s_werks[] IS INITIAL.
    MESSAGE e001.
  ENDIF.

  IF zcl_pp_fcst_util=>split_fyear( p_fyear ) = abap_false.
    MESSAGE e002 WITH p_fyear.
  ENDIF.

  LOOP AT s_werks INTO DATA(ls_w).
    IF zcl_pp_fcst_util=>check_authority( iv_werks = ls_w-low
                                          iv_actvt = '03' ) = abap_false.
      MESSAGE e010 WITH ls_w-low '03'.
    ENDIF.
  ENDLOOP.

*&---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM collect.

  IF gt_out IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  PERFORM display.


*&---------------------------------------------------------------------*
FORM collect.

  CLEAR gt_out.

  " Annual is the anchor - one row per plant, material and year
  SELECT * FROM zppt_fcst_yr INTO TABLE @DATA(lt_yr)
    WHERE werks   IN @s_werks
      AND matnr   IN @s_matnr
      AND fyear    = @p_fyear
      AND fcst_no IN @s_fcstno.

  IF lt_yr IS INITIAL.
    RETURN.
  ENDIF.

  SELECT * FROM zppt_fcst_qt INTO TABLE @DATA(lt_qt)
    FOR ALL ENTRIES IN @lt_yr
    WHERE werks = @lt_yr-werks AND matnr = @lt_yr-matnr.

  SELECT * FROM zppt_fcst_mn INTO TABLE @DATA(lt_mn)
    FOR ALL ENTRIES IN @lt_yr
    WHERE werks = @lt_yr-werks AND matnr = @lt_yr-matnr.

*BOC By Arnav on 31/08/26
* MTS / MTO is stored with the annual forecast, so most rows cost
* nothing. A forecast saved before the category was maintained carries a
* blank, and ZPPT_PROD_CAT fills it in - read ONCE with FOR ALL ENTRIES
* rather than a SELECT SINGLE per row. LT_YR is guaranteed non-initial
* by the RETURN a few lines above, which is the guard for all three of
* these reads.
  SELECT werks, matnr, mts_mto FROM zppt_prod_cat
    INTO TABLE @DATA(lt_cat)
    FOR ALL ENTRIES IN @lt_yr
    WHERE werks = @lt_yr-werks AND matnr = @lt_yr-matnr.
*EOC By Arnav on 31/08/26

  LOOP AT lt_yr INTO DATA(ls_yr).

    CHECK s_matkl[] IS INITIAL OR ls_yr-matkl IN s_matkl.

*BOC By Arnav on 31/08/26
*   Worked out once per material rather than inside the month loop below
    DATA(lv_mts) = ls_yr-mts_mto.
    IF lv_mts IS INITIAL.
      READ TABLE lt_cat INTO DATA(ls_cat) WITH KEY werks = ls_yr-werks
                                                   matnr = ls_yr-matnr.
      IF sy-subrc = 0.
        lv_mts = ls_cat-mts_mto.
      ENDIF.
    ENDIF.
*EOC By Arnav on 31/08/26

    " One output row per monthly forecast, so the report reads month wise
    " as the Final ALV layout shows. Where no monthly forecast exists the
    " annual figures are still shown on a single row.
    DATA(lv_any) = abap_false.

    LOOP AT lt_mn INTO DATA(ls_mn) WHERE werks = ls_yr-werks
                                     AND matnr = ls_yr-matnr.

      CHECK s_perio[] IS INITIAL OR ls_mn-period IN s_perio.

      DATA(lv_qtr) = zcl_pp_fcst_util=>period_to_quarter( CONV #( ls_mn-period ) ).
      CHECK s_quart[] IS INITIAL OR lv_qtr IN s_quart.

      DATA(ls_out) = VALUE ty_out( fcst_no = ls_yr-fcst_no
                                   werks   = ls_yr-werks
                                   matnr   = ls_yr-matnr
                                   maktx   = ls_yr-maktx
                                   matkl   = ls_yr-matkl
                                   mts_mto = lv_mts   "Changes by Arnav on 31/08/26
                                   fyear   = ls_yr-fyear
                                   meins   = ls_yr-meins
                                   annual  = ls_yr-fcst_total
                                   period  = ls_mn-period
                                   quarter = lv_qtr
                                   mth_fcst = ls_mn-final_qty
                                   mth_add  = ls_mn-bus_fcst_add ).

      ls_out-mth_total = ls_out-mth_fcst + ls_out-mth_add.

      READ TABLE lt_qt INTO DATA(ls_qt) WITH KEY werks   = ls_yr-werks
                                                 matnr   = ls_yr-matnr
                                                 quarter = lv_qtr.
      IF sy-subrc = 0.
        ls_out-qtr_fcst = ls_qt-final_qty.
*BOC By Arnav on 03/09/26
*       ls_out-qtr_add  = ls_qt-bus_fcst_add.
*       The quarterly table splits the additional plan quantity across
*       the three months. This report shows the quarter on one line, so
*       the three are added back together here.
        ls_out-qtr_add  = ls_qt-bus_fcst_add1
                        + ls_qt-bus_fcst_add2
                        + ls_qt-bus_fcst_add3.
*EOC By Arnav on 03/09/26
      ENDIF.
      ls_out-qtr_total = ls_out-qtr_fcst + ls_out-qtr_add.

      PERFORM fill_groups CHANGING ls_out.

      APPEND ls_out TO gt_out.
      lv_any = abap_true.

    ENDLOOP.

    IF lv_any = abap_false AND s_perio[] IS INITIAL AND s_quart[] IS INITIAL.
      ls_out = VALUE ty_out( fcst_no = ls_yr-fcst_no
                             werks   = ls_yr-werks
                             matnr   = ls_yr-matnr
                             maktx   = ls_yr-maktx
                             matkl   = ls_yr-matkl
                             mts_mto = lv_mts   "Changes by Arnav on 31/08/26
                             fyear   = ls_yr-fyear
                             meins   = ls_yr-meins
                             annual  = ls_yr-fcst_total ).
      PERFORM fill_groups CHANGING ls_out.
      APPEND ls_out TO gt_out.
    ENDIF.

  ENDLOOP.

  SORT gt_out BY werks matnr period.

ENDFORM.


*&---------------------------------------------------------------------*
FORM fill_groups CHANGING cs_out TYPE ty_out.

  SELECT SINGLE vkorg FROM zppt_fcst_cfg INTO @DATA(lv_vkorg)
    WHERE werks = @cs_out-werks.
  IF lv_vkorg IS INITIAL.
    lv_vkorg = zcl_pp_fcst=>gc_vkorg_default.
  ENDIF.

  SELECT SINGLE mvgr1, mvgr2, mvgr3, mvgr4, mvgr5 FROM mvke
    INTO @DATA(ls_mvke)
    WHERE matnr = @cs_out-matnr AND vkorg = @lv_vkorg.

  CHECK sy-subrc = 0.

  IF ls_mvke-mvgr1 IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvm1t INTO @cs_out-mvgr1_txt
      WHERE spras = @sy-langu AND mvgr1 = @ls_mvke-mvgr1.
  ENDIF.
  IF ls_mvke-mvgr2 IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvm2t INTO @cs_out-mvgr2_txt
      WHERE spras = @sy-langu AND mvgr2 = @ls_mvke-mvgr2.
  ENDIF.
  IF ls_mvke-mvgr3 IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvm3t INTO @cs_out-mvgr3_txt
      WHERE spras = @sy-langu AND mvgr3 = @ls_mvke-mvgr3.
  ENDIF.
  IF ls_mvke-mvgr4 IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvm4t INTO @cs_out-mvgr4_txt
      WHERE spras = @sy-langu AND mvgr4 = @ls_mvke-mvgr4.
  ENDIF.
  IF ls_mvke-mvgr5 IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvm5t INTO @cs_out-mvgr5_txt
      WHERE spras = @sy-langu AND mvgr5 = @ls_mvke-mvgr5.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM display.

  DATA lo_alv TYPE REF TO cl_salv_table.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_out ).

      lo_alv->get_functions( )->set_all( ).
      DATA(lo_cols) = lo_alv->get_columns( ).
      lo_cols->set_optimize( ).

      PERFORM txt USING lo_cols 'FCST_NO'   'Forecast Number'.
      PERFORM txt USING lo_cols 'WERKS'     'Plant'.
      PERFORM txt USING lo_cols 'MATNR'     'Material'.
      PERFORM txt USING lo_cols 'MAKTX'     'Material Description'.
      PERFORM txt USING lo_cols 'MATKL'     'Material Group'.
*BOC By Arnav on 31/08/26
      PERFORM txt USING lo_cols 'MTS_MTO'   'MTS / MTO'.
      PERFORM txt USING lo_cols 'PRICE'     'Price'.
*EOC By Arnav on 31/08/26
      PERFORM txt USING lo_cols 'MVGR1_TXT' 'Material Group 1'.
      PERFORM txt USING lo_cols 'MVGR2_TXT' 'Material Group 2'.
      PERFORM txt USING lo_cols 'MVGR3_TXT' 'Material Group 3'.
      PERFORM txt USING lo_cols 'MVGR4_TXT' 'Material Group 4'.
      PERFORM txt USING lo_cols 'MVGR5_TXT' 'Material Group 5'.
      PERFORM txt USING lo_cols 'FYEAR'     'Financial Year'.
      PERFORM txt USING lo_cols 'PERIOD'    'Month'.
      PERFORM txt USING lo_cols 'QUARTER'   'Quarter'.
      PERFORM txt USING lo_cols 'ANNUAL'    'Annual Forecast'.
      PERFORM txt USING lo_cols 'QTR_FCST'  'Quarter Forecast'.
      PERFORM txt USING lo_cols 'QTR_ADD'   'Quarter Additional Forecast'.
      PERFORM txt USING lo_cols 'QTR_TOTAL' 'Final Quarter Forecast'.
      PERFORM txt USING lo_cols 'MTH_FCST'  'Monthly Forecast'.
      PERFORM txt USING lo_cols 'MTH_ADD'   'Additional Monthly Forecast'.
      PERFORM txt USING lo_cols 'MTH_TOTAL' 'Final Monthly Forecast'.

      lo_alv->get_display_settings( )->set_list_header(
        |Forecast Report - Financial Year { p_fyear }| ).

      lo_alv->display( ).

    CATCH cx_salv_msg cx_salv_not_found cx_salv_data_error.
      MESSAGE e008.
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
*& Financial year is a custom type with no check table, so its value
*& help is built by hand. Plant, material, material group, forecast
*& number, quarter and period all take theirs from the dictionary now
*& that each is declared over the right field.
*&---------------------------------------------------------------------*
FORM f4_fyear.

  TYPES: BEGIN OF ty_f4,
           fyear TYPE char9,
           text  TYPE char30,
         END OF ty_f4.

  DATA: lt_f4  TYPE STANDARD TABLE OF ty_f4 WITH DEFAULT KEY,
        ls_f4  TYPE ty_f4,
        lt_ret TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY,
        ls_ret TYPE ddshretval,
        lv_y   TYPE i,
        lv_nx  TYPE i.

  lv_y = sy-datum(4).
  IF sy-datum+4(2) < '04'.
    lv_y = lv_y - 1.
  ENDIF.

  lv_y = lv_y - 5.

  DO 11 TIMES.
    CLEAR ls_f4.
    lv_nx = lv_y + 1.
    ls_f4-fyear = |{ lv_y }-{ lv_nx }|.
    ls_f4-text  = |April { lv_y } to March { lv_nx }|.
    APPEND ls_f4 TO lt_f4.
    lv_y = lv_y + 1.
  ENDDO.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING  retfield        = 'FYEAR'
               dynpprog        = sy-repid
               dynpnr          = sy-dynnr
               dynprofield     = 'P_FYEAR'
               value_org       = 'S'
    TABLES     value_tab       = lt_f4
               return_tab      = lt_ret
    EXCEPTIONS parameter_error = 1
               no_values_found = 2
               OTHERS          = 3.

  IF sy-subrc = 0.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    IF sy-subrc = 0.
      p_fyear = ls_ret-fieldval.
    ENDIF.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
FORM txt USING po_cols TYPE REF TO cl_salv_columns_table
               pv_name TYPE any
               pv_text TYPE any.

  DATA: lv_txt TYPE string,
        lv_len TYPE lvc_outlen.

* ALV picks WHICH of the three heading texts to draw from the column
* output length - the short one below 10 characters, the medium one
* below 20, the long one above that. A long heading on a narrow numeric
* column was therefore drawn from the short text and cut off. The width
* is set from the heading so the long text is chosen, and set_optimize
* then widens further where the data needs it.
  lv_txt = pv_text.
  lv_len = strlen( lv_txt ).
  IF lv_len < 10.
    lv_len = 10.
  ELSEIF lv_len > 40.
    lv_len = 40.
  ENDIF.

  TRY.
      DATA(lo_col) = po_cols->get_column( CONV lvc_fname( pv_name ) ).
      lo_col->set_long_text( CONV scrtext_l( lv_txt ) ).
      lo_col->set_medium_text( CONV scrtext_m( lv_txt ) ).
      lo_col->set_short_text( CONV scrtext_s( lv_txt ) ).
      lo_col->set_output_length( lv_len ).
    CATCH cx_salv_not_found.
  ENDTRY.

ENDFORM.
