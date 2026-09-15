CLASS zcl_pp_fcst DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS: BEGIN OF gc_mode,
                 annual    TYPE char1 VALUE 'A',
                 quarterly TYPE char1 VALUE 'Q',
                 monthly   TYPE char1 VALUE 'M',
               END OF gc_mode.

    CONSTANTS gc_shkzg_ne_blank TYPE abap_bool VALUE abap_false.

    CONSTANTS: gc_bwart_default TYPE bwart   VALUE '601',
               gc_vkorg_default TYPE vkorg   VALUE '1100',
               gc_msgid         TYPE symsgid VALUE 'ZPP_FCST'.

    TYPES: BEGIN OF ty_alv,
             mark      TYPE abap_bool,
             light     TYPE char1,
             status    TYPE char1,
             message   TYPE char100,

             fcst_no   TYPE zde_fcst_no,
             werks     TYPE werks_d,
             matnr     TYPE matnr,
             maktx     TYPE maktx,
             matkl     TYPE matkl,
             gewei     TYPE gewei,
             ntgew     TYPE ntgew,
             meins     TYPE meins,

             mvgr1     TYPE mvgr1,
             mvgr2     TYPE mvgr2,
             mvgr3     TYPE mvgr3,
             mvgr4     TYPE mvgr4,
             mvgr5     TYPE mvgr5,
             mvgr1_txt TYPE bezei20,
             mvgr2_txt TYPE bezei20,
             mvgr3_txt TYPE bezei20,
             mvgr4_txt TYPE bezei20,
             mvgr5_txt TYPE bezei20,

             fyear     TYPE zde_fyear,
             gjahr     TYPE gjahr,
             quarter   TYPE zde_quarter,
             period    TYPE poper,

             prod_cat  TYPE zde_prod_cat,
             load_fct  TYPE zde_load_fct,
             mts_mto   TYPE zde_mts_mto,
             price     TYPE p LENGTH 13 DECIMALS 2,

             m01        TYPE zde_fcst_qty,
             m02        TYPE zde_fcst_qty,
             m03        TYPE zde_fcst_qty,
             m04        TYPE zde_fcst_qty,
             m05        TYPE zde_fcst_qty,
             m06        TYPE zde_fcst_qty,
             m07        TYPE zde_fcst_qty,
             m08        TYPE zde_fcst_qty,
             m09        TYPE zde_fcst_qty,
             m10        TYPE zde_fcst_qty,
             m11        TYPE zde_fcst_qty,
             m12        TYPE zde_fcst_qty,
             ly_total   TYPE zde_fcst_qty,
             fcst_total TYPE zde_fcst_qty,
             m01_fcst   TYPE zde_fcst_qty,
             m02_fcst   TYPE zde_fcst_qty,
             m03_fcst   TYPE zde_fcst_qty,
             m04_fcst   TYPE zde_fcst_qty,
             m05_fcst   TYPE zde_fcst_qty,
             m06_fcst   TYPE zde_fcst_qty,
             m07_fcst   TYPE zde_fcst_qty,
             m08_fcst   TYPE zde_fcst_qty,
             m09_fcst   TYPE zde_fcst_qty,
             m10_fcst   TYPE zde_fcst_qty,
             m11_fcst   TYPE zde_fcst_qty,
             m12_fcst   TYPE zde_fcst_qty,
             m01_ton    TYPE zde_fcst_qty,
             m02_ton    TYPE zde_fcst_qty,
             m03_ton    TYPE zde_fcst_qty,
             m04_ton    TYPE zde_fcst_qty,
             m05_ton    TYPE zde_fcst_qty,
             m06_ton    TYPE zde_fcst_qty,
             m07_ton    TYPE zde_fcst_qty,
             m08_ton    TYPE zde_fcst_qty,
             m09_ton    TYPE zde_fcst_qty,
             m10_ton    TYPE zde_fcst_qty,
             m11_ton    TYPE zde_fcst_qty,
             m12_ton    TYPE zde_fcst_qty,

             m4_last      TYPE zde_fcst_qty,
             m5_last      TYPE zde_fcst_qty,
             m6_last      TYPE zde_fcst_qty,
             ly_qtr_tot   TYPE zde_fcst_qty,
             m1_curr      TYPE zde_fcst_qty,
             m2_curr      TYPE zde_fcst_qty,
             m3_curr      TYPE zde_fcst_qty,
             l3m_tot      TYPE zde_fcst_qty,
             l3m_avg      TYPE zde_fcst_qty,
             max_qty      TYPE zde_fcst_qty,
             fcst_qty     TYPE zde_fcst_qty,
             bus_fcst     TYPE zde_fcst_qty,
             bus_fcst_add TYPE zde_fcst_qty,
             final_qty    TYPE zde_fcst_qty,
             total_qty    TYPE zde_fcst_qty,
             m4_fcst      TYPE zde_fcst_qty,
             m5_fcst      TYPE zde_fcst_qty,
             m6_fcst      TYPE zde_fcst_qty,
             m4_ton       TYPE zde_fcst_qty,
             m5_ton       TYPE zde_fcst_qty,
             m6_ton       TYPE zde_fcst_qty,
             reason       TYPE zde_fcst_reason,
             bus_fcst_add1 TYPE zde_fcst_qty,
             bus_fcst_add2 TYPE zde_fcst_qty,
             bus_fcst_add3 TYPE zde_fcst_qty,
             m4_fcst_final TYPE zde_fcst_qty,
             m5_fcst_final TYPE zde_fcst_qty,
             m6_fcst_final TYPE zde_fcst_qty,
             m4_val        TYPE p LENGTH 13 DECIMALS 2,
             m5_val        TYPE p LENGTH 13 DECIMALS 2,
             m6_val        TYPE p LENGTH 13 DECIMALS 2,
             m4_ton_val    TYPE p LENGTH 13 DECIMALS 2,
             m5_ton_val    TYPE p LENGTH 13 DECIMALS 2,
             m6_ton_val    TYPE p LENGTH 13 DECIMALS 2,
           END OF ty_alv,
           tt_alv   TYPE STANDARD TABLE OF ty_alv WITH DEFAULT KEY,
           tr_werks TYPE RANGE OF werks_d,
           tr_matnr TYPE RANGE OF matnr,
           tr_shkzg TYPE RANGE OF vbrp-shkzg.

    METHODS generate_annual
      IMPORTING ir_werks   TYPE tr_werks
                ir_matnr   TYPE tr_matnr
                iv_fyear   TYPE zde_fyear
                iv_legacy  TYPE abap_bool DEFAULT abap_false
                iv_tonnage TYPE abap_bool DEFAULT abap_false
      EXPORTING et_alv     TYPE tt_alv
                et_msg     TYPE bapiret2_t.

    METHODS generate_quarterly
      IMPORTING ir_werks   TYPE tr_werks
                ir_matnr   TYPE tr_matnr
                iv_fyear   TYPE zde_fyear
                iv_quarter TYPE zde_quarter
                iv_legacy  TYPE abap_bool DEFAULT abap_false
                iv_tonnage TYPE abap_bool DEFAULT abap_false
      EXPORTING et_alv     TYPE tt_alv
                et_msg     TYPE bapiret2_t.

    METHODS generate_monthly
      IMPORTING ir_werks   TYPE tr_werks
                ir_matnr   TYPE tr_matnr
                iv_fyear   TYPE zde_fyear
                iv_period  TYPE poper
                iv_legacy  TYPE abap_bool DEFAULT abap_false
                iv_tonnage TYPE abap_bool DEFAULT abap_false
      EXPORTING et_alv     TYPE tt_alv
                et_msg     TYPE bapiret2_t.

    METHODS save
      IMPORTING iv_mode       TYPE char1
      CHANGING  ct_alv        TYPE tt_alv
      RETURNING VALUE(rt_msg) TYPE bapiret2_t.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_hist,
             werks TYPE werks_d,
             matnr TYPE matnr,
             gjahr TYPE gjahr,
             month TYPE numc2,
             qty   TYPE zde_fcst_qty,
             meins TYPE meins,
           END OF ty_hist,
           tt_hist TYPE SORTED TABLE OF ty_hist
                     WITH UNIQUE KEY werks matnr gjahr month,

           BEGIN OF ty_scope,
             werks TYPE werks_d,
             matnr TYPE matnr,
           END OF ty_scope,
           tt_scope TYPE STANDARD TABLE OF ty_scope WITH DEFAULT KEY.

    DATA: mt_hist TYPE tt_hist,
          mv_vkorg TYPE vkorg,
          mv_bwart TYPE bwart.

    METHODS read_config
      IMPORTING ir_werks TYPE tr_werks.

    METHODS read_billing
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
      RETURNING VALUE(rt_hist) TYPE tt_hist.

    METHODS read_matdoc
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
      RETURNING VALUE(rt_hist) TYPE tt_hist.

    METHODS read_legacy
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
      RETURNING VALUE(rt_hist) TYPE tt_hist.

    METHODS add_old_material_qty
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
                iv_use_billing TYPE abap_bool DEFAULT abap_true
      CHANGING  ct_hist        TYPE tt_hist.

    METHODS build_scope
      IMPORTING ir_werks        TYPE tr_werks
                ir_matnr        TYPE tr_matnr
      RETURNING VALUE(rt_scope) TYPE tt_scope.

    METHODS merge_missing
      IMPORTING it_from  TYPE tt_hist
      EXPORTING ev_added TYPE i
      CHANGING  ct_hist  TYPE tt_hist.

    METHODS fill_master_data
      CHANGING cs_alv TYPE ty_alv.

    METHODS fill_category
      CHANGING cs_alv TYPE ty_alv.

    METHODS hist_qty
      IMPORTING iv_werks      TYPE werks_d
                iv_matnr      TYPE matnr
                iv_gjahr      TYPE gjahr
                iv_month      TYPE numc2
      RETURNING VALUE(rv_qty) TYPE zde_fcst_qty.

    METHODS build_shkzg_range
      RETURNING VALUE(rt_range) TYPE tr_shkzg.

    METHODS annual_number
      IMPORTING iv_werks     TYPE werks_d
                iv_matnr     TYPE matnr
                iv_fyear     TYPE zde_fyear
      RETURNING VALUE(rv_no) TYPE zde_fcst_no.

    METHODS number_get
      IMPORTING iv_fyear     TYPE zde_fyear
      RETURNING VALUE(rv_no) TYPE zde_fcst_no.

    METHODS number_from_table
      IMPORTING iv_fyear     TYPE zde_fyear
      RETURNING VALUE(rv_no) TYPE zde_fcst_no.

    METHODS add_msg
      IMPORTING iv_type   TYPE bapi_mtype DEFAULT 'E'
                iv_number TYPE symsgno
                iv_v1     TYPE any OPTIONAL
                iv_v2     TYPE any OPTIONAL
                iv_v3     TYPE any OPTIONAL
                iv_v4     TYPE any OPTIONAL
      CHANGING  ct_msg    TYPE bapiret2_t.

ENDCLASS.

CLASS zcl_pp_fcst IMPLEMENTATION.

  METHOD generate_annual.

    CLEAR: et_alv, et_msg.

    read_config( ir_werks ).

    DATA(lv_prev) = zcl_pp_fcst_util=>previous_fyear( iv_fyear ).
    IF lv_prev IS INITIAL.
      add_msg( EXPORTING iv_number = 002 iv_v1 = iv_fyear CHANGING ct_msg = et_msg ).
      RETURN.
    ENDIF.

    zcl_pp_fcst_util=>fyear_dates( EXPORTING iv_fyear = lv_prev
                                   IMPORTING ev_from  = DATA(lv_from)
                                             ev_to    = DATA(lv_to) ).

    DATA: lt_std   TYPE tt_hist,
          lv_gaps  TYPE i.

    CLEAR: mt_hist, lt_std, lv_gaps.

    IF iv_legacy = abap_true.
      mt_hist = read_legacy( ir_werks = ir_werks ir_matnr = ir_matnr
                             iv_from = lv_from iv_to = lv_to ).
    ENDIF.

    lt_std = read_billing( ir_werks = ir_werks ir_matnr = ir_matnr
                           iv_from = lv_from iv_to = lv_to ).
    add_old_material_qty( EXPORTING ir_werks = ir_werks ir_matnr = ir_matnr
                                    iv_from = lv_from iv_to = lv_to
                          CHANGING  ct_hist = lt_std ).

    IF iv_legacy = abap_true.
      merge_missing( EXPORTING it_from  = lt_std
                     IMPORTING ev_added = lv_gaps
                     CHANGING  ct_hist  = mt_hist ).
      IF lv_gaps > 0.
        add_msg( EXPORTING iv_type = 'W' iv_number = 023 iv_v1 = lv_gaps
                 CHANGING  ct_msg = et_msg ).
      ENDIF.
    ELSE.
      mt_hist = lt_std.
    ENDIF.

    DATA(lt_scope) = build_scope( ir_werks = ir_werks ir_matnr = ir_matnr ).

    LOOP AT lt_scope INTO DATA(ls_scope).

      DATA(ls_alv) = VALUE ty_alv( werks = ls_scope-werks
                                   matnr = ls_scope-matnr
                                   fyear = iv_fyear ).

      fill_master_data( CHANGING cs_alv = ls_alv ).
      fill_category( CHANGING cs_alv = ls_alv ).

      DO 12 TIMES.

        DATA(lv_p) = CONV numc2( sy-index ).

        zcl_pp_fcst_util=>period_to_yearmonth(
          EXPORTING iv_fyear  = lv_prev
                    iv_period = lv_p
          IMPORTING ev_gjahr  = DATA(lv_gjahr)
                    ev_month  = DATA(lv_month) ).

        DATA(lv_qty) = hist_qty( iv_werks = ls_scope-werks
                                 iv_matnr = ls_scope-matnr
                                 iv_gjahr = lv_gjahr
                                 iv_month = lv_month ).

        ASSIGN COMPONENT |M{ lv_p }| OF STRUCTURE ls_alv TO FIELD-SYMBOL(<lv_m>).
        IF sy-subrc = 0.
          <lv_m> = lv_qty.
        ENDIF.

        ls_alv-ly_total = ls_alv-ly_total + lv_qty.

      ENDDO.

      ls_alv-fcst_total = ls_alv-ly_total * ls_alv-load_fct.

      DO 12 TIMES.

        lv_p = sy-index.

        ASSIGN COMPONENT |M{ lv_p }|      OF STRUCTURE ls_alv TO <lv_m>.
        ASSIGN COMPONENT |M{ lv_p }_FCST| OF STRUCTURE ls_alv TO FIELD-SYMBOL(<lv_f>).
        ASSIGN COMPONENT |M{ lv_p }_TON|  OF STRUCTURE ls_alv TO FIELD-SYMBOL(<lv_t>).

        CHECK <lv_m> IS ASSIGNED AND <lv_f> IS ASSIGNED.

        IF ls_alv-ly_total > 0.
          <lv_f> = <lv_m> / ls_alv-ly_total * ls_alv-fcst_total.
        ELSE.
          <lv_f> = ls_alv-fcst_total / 12.
        ENDIF.

        IF iv_tonnage = abap_true AND <lv_t> IS ASSIGNED.
          <lv_t> = zcl_pp_fcst_util=>to_tonnage( iv_qty   = <lv_f>
                                                 iv_ntgew = ls_alv-ntgew ).
        ENDIF.

      ENDDO.

      ls_alv-fcst_no = annual_number( iv_werks = ls_scope-werks
                                      iv_matnr = ls_scope-matnr
                                      iv_fyear = iv_fyear ).
      IF ls_alv-fcst_no IS NOT INITIAL.
        ls_alv-status  = 'S'.
        ls_alv-light   = '3'.
        ls_alv-message = |Already saved, will be overwritten|.
      ELSE.
        ls_alv-light = '2'.
      ENDIF.

      APPEND ls_alv TO et_alv.

    ENDLOOP.

    IF et_alv IS INITIAL.
      add_msg( EXPORTING iv_type = 'I' iv_number = 008 CHANGING ct_msg = et_msg ).
    ENDIF.

  ENDMETHOD.

  METHOD generate_quarterly.

    CLEAR: et_alv, et_msg.

    read_config( ir_werks ).

    DATA(lt_qtr)  = zcl_pp_fcst_util=>quarter_periods( iv_fyear = iv_fyear
                                                       iv_quarter = iv_quarter ).
    DATA(lt_ly)   = zcl_pp_fcst_util=>last_year_quarter( iv_fyear = iv_fyear
                                                         iv_quarter = iv_quarter ).
    DATA(lt_l3m)  = zcl_pp_fcst_util=>last_three_months(
                      iv_fyear  = iv_fyear
                      iv_period = VALUE #( lt_qtr[ 1 ]-period OPTIONAL ) ).

    DATA(lv_from) = VALUE dats( lt_ly[ 1 ]-datfr OPTIONAL ).
    DATA(lv_to)   = VALUE dats( lt_l3m[ 3 ]-datto OPTIONAL ).
    IF lv_to < lv_from.
      DATA(lv_swap) = lv_from. lv_from = lv_to. lv_to = lv_swap.
    ENDIF.

    DATA: lt_std  TYPE tt_hist,
          lv_gaps TYPE i.

    CLEAR: mt_hist, lt_std, lv_gaps.

    IF iv_legacy = abap_true.
      mt_hist = read_legacy( ir_werks = ir_werks ir_matnr = ir_matnr
                             iv_from = lv_from iv_to = lv_to ).
    ENDIF.

    lt_std = read_billing( ir_werks = ir_werks ir_matnr = ir_matnr
                           iv_from = lv_from iv_to = lv_to ).
    add_old_material_qty( EXPORTING ir_werks = ir_werks ir_matnr = ir_matnr
                                    iv_from = lv_from iv_to = lv_to
                          CHANGING  ct_hist = lt_std ).

    IF iv_legacy = abap_true.
      merge_missing( EXPORTING it_from  = lt_std
                     IMPORTING ev_added = lv_gaps
                     CHANGING  ct_hist  = mt_hist ).
      IF lv_gaps > 0.
        add_msg( EXPORTING iv_type = 'W' iv_number = 023 iv_v1 = lv_gaps
                 CHANGING  ct_msg = et_msg ).
      ENDIF.
    ELSE.
      mt_hist = lt_std.
    ENDIF.

    DATA(lt_scope) = build_scope( ir_werks = ir_werks ir_matnr = ir_matnr ).

    LOOP AT lt_scope INTO DATA(ls_scope).

      DATA(lv_no) = annual_number( iv_werks = ls_scope-werks
                                   iv_matnr = ls_scope-matnr
                                   iv_fyear = iv_fyear ).

      DATA(ls_alv) = VALUE ty_alv( werks   = ls_scope-werks
                                   matnr   = ls_scope-matnr
                                   fyear   = iv_fyear
                                   quarter = iv_quarter
                                   fcst_no = lv_no ).

      zcl_pp_fcst_util=>split_fyear( EXPORTING iv_fyear = iv_fyear
                                     IMPORTING ev_year_from = ls_alv-gjahr ).

      fill_master_data( CHANGING cs_alv = ls_alv ).
      fill_category( CHANGING cs_alv = ls_alv ).

      DATA lt_ly_month TYPE STANDARD TABLE OF zde_fcst_qty.
      CLEAR lt_ly_month.

      LOOP AT lt_ly INTO DATA(ls_ly).
        DATA(lv_q) = hist_qty( iv_werks = ls_scope-werks iv_matnr = ls_scope-matnr
                               iv_gjahr = ls_ly-gjahr    iv_month = ls_ly-month ).
        APPEND lv_q TO lt_ly_month.
        ls_alv-ly_qtr_tot = ls_alv-ly_qtr_tot + lv_q.
      ENDLOOP.

      ls_alv-m4_last = VALUE #( lt_ly_month[ 1 ] OPTIONAL ).
      ls_alv-m5_last = VALUE #( lt_ly_month[ 2 ] OPTIONAL ).
      ls_alv-m6_last = VALUE #( lt_ly_month[ 3 ] OPTIONAL ).

      DATA lt_cur_month TYPE STANDARD TABLE OF zde_fcst_qty.
      CLEAR lt_cur_month.

      LOOP AT lt_l3m INTO DATA(ls_l3).
        lv_q = hist_qty( iv_werks = ls_scope-werks iv_matnr = ls_scope-matnr
                         iv_gjahr = ls_l3-gjahr    iv_month = ls_l3-month ).
        APPEND lv_q TO lt_cur_month.
        ls_alv-l3m_tot = ls_alv-l3m_tot + lv_q.
      ENDLOOP.

      ls_alv-m1_curr = VALUE #( lt_cur_month[ 1 ] OPTIONAL ).
      ls_alv-m2_curr = VALUE #( lt_cur_month[ 2 ] OPTIONAL ).
      ls_alv-m3_curr = VALUE #( lt_cur_month[ 3 ] OPTIONAL ).

      ls_alv-max_qty  = nmax( val1 = ls_alv-ly_qtr_tot val2 = ls_alv-l3m_tot ).
      ls_alv-fcst_qty = ls_alv-max_qty * ls_alv-load_fct.

      SELECT SINGLE bus_fcst, bus_fcst_add1, bus_fcst_add2, bus_fcst_add3,
                    reason, price
        FROM zppt_fcst_qt
        INTO ( @ls_alv-bus_fcst,
               @ls_alv-bus_fcst_add1, @ls_alv-bus_fcst_add2,
               @ls_alv-bus_fcst_add3,
               @ls_alv-reason, @ls_alv-price )
        WHERE werks = @ls_scope-werks AND matnr = @ls_scope-matnr
          AND gjahr = @ls_alv-gjahr   AND quarter = @iv_quarter.

      ls_alv-final_qty = nmax( val1 = ls_alv-fcst_qty val2 = ls_alv-bus_fcst ).
      ls_alv-total_qty = ls_alv-final_qty
                       + ls_alv-bus_fcst_add1
                       + ls_alv-bus_fcst_add2
                       + ls_alv-bus_fcst_add3.

      DO 3 TIMES.

        DATA(lv_i) = sy-index.
        DATA(lv_share) = CONV zde_fcst_qty( 0 ).

        IF ls_alv-ly_qtr_tot > 0.
          lv_share = VALUE zde_fcst_qty( lt_ly_month[ lv_i ] OPTIONAL )
                     / ls_alv-ly_qtr_tot * ls_alv-final_qty.
        ELSE.
          lv_share = ls_alv-final_qty / 3.
        ENDIF.

        ASSIGN COMPONENT |M{ lv_i + 3 }_FCST| OF STRUCTURE ls_alv TO FIELD-SYMBOL(<lv_f>).
        ASSIGN COMPONENT |M{ lv_i + 3 }_TON|  OF STRUCTURE ls_alv TO FIELD-SYMBOL(<lv_t>).

        IF <lv_f> IS ASSIGNED.
          <lv_f> = lv_share.
        ENDIF.
        IF iv_tonnage = abap_true AND <lv_t> IS ASSIGNED.
          <lv_t> = zcl_pp_fcst_util=>to_tonnage( iv_qty = lv_share iv_ntgew = ls_alv-ntgew ).
        ENDIF.

        ASSIGN COMPONENT |BUS_FCST_ADD{ lv_i }|      OF STRUCTURE ls_alv
          TO FIELD-SYMBOL(<lv_a>).
        ASSIGN COMPONENT |M{ lv_i + 3 }_FCST_FINAL|  OF STRUCTURE ls_alv
          TO FIELD-SYMBOL(<lv_ff>).
        ASSIGN COMPONENT |M{ lv_i + 3 }_VAL|         OF STRUCTURE ls_alv
          TO FIELD-SYMBOL(<lv_v>).
        ASSIGN COMPONENT |M{ lv_i + 3 }_TON_VAL|     OF STRUCTURE ls_alv
          TO FIELD-SYMBOL(<lv_tv>).

        IF <lv_a> IS ASSIGNED AND <lv_ff> IS ASSIGNED.

          DATA(lv_final) = CONV zde_fcst_qty( lv_share + <lv_a> ).
          <lv_ff> = lv_final.

          IF <lv_v> IS ASSIGNED.
            <lv_v> = lv_final * ls_alv-price.
          ENDIF.

          IF <lv_tv> IS ASSIGNED.
            DATA(lv_fton) = zcl_pp_fcst_util=>to_tonnage( iv_qty   = lv_final
                                                          iv_ntgew = ls_alv-ntgew ).
            <lv_tv> = lv_fton * ls_alv-price.
          ENDIF.

        ENDIF.

      ENDDO.

      ls_alv-light = '2'.
      APPEND ls_alv TO et_alv.

    ENDLOOP.

    IF et_alv IS INITIAL.
      add_msg( EXPORTING iv_type = 'I' iv_number = 008 CHANGING ct_msg = et_msg ).
    ENDIF.

  ENDMETHOD.

  METHOD generate_monthly.

    CLEAR: et_alv, et_msg.

    read_config( ir_werks ).

    DATA(lv_quarter) = zcl_pp_fcst_util=>period_to_quarter( CONV #( iv_period ) ).
    DATA(lt_ly)      = zcl_pp_fcst_util=>last_year_quarter( iv_fyear = iv_fyear
                                                            iv_quarter = lv_quarter ).
    DATA(lt_l3m)     = zcl_pp_fcst_util=>last_three_months( iv_fyear = iv_fyear
                                                            iv_period = CONV #( iv_period ) ).

    DATA(lv_prev) = zcl_pp_fcst_util=>previous_fyear( iv_fyear ).
    zcl_pp_fcst_util=>period_to_yearmonth( EXPORTING iv_fyear  = lv_prev
                                                     iv_period = CONV #( iv_period )
                                           IMPORTING ev_gjahr  = DATA(lv_ly_year)
                                                     ev_month  = DATA(lv_ly_month) ).

    DATA(lv_from) = VALUE dats( lt_ly[ 1 ]-datfr OPTIONAL ).
    DATA(lv_to)   = VALUE dats( lt_l3m[ 3 ]-datto OPTIONAL ).
    IF lv_to < lv_from.
      DATA(lv_swap) = lv_from. lv_from = lv_to. lv_to = lv_swap.
    ENDIF.

    DATA: lt_std  TYPE tt_hist,
          lv_gaps TYPE i.

    CLEAR: mt_hist, lt_std, lv_gaps.

    IF iv_legacy = abap_true.
      mt_hist = read_legacy( ir_werks = ir_werks ir_matnr = ir_matnr
                             iv_from = lv_from iv_to = lv_to ).
    ENDIF.

    lt_std = read_matdoc( ir_werks = ir_werks ir_matnr = ir_matnr
                          iv_from = lv_from iv_to = lv_to ).
    add_old_material_qty( EXPORTING ir_werks       = ir_werks
                                    ir_matnr       = ir_matnr
                                    iv_from        = lv_from
                                    iv_to          = lv_to
                                    iv_use_billing = abap_false
                          CHANGING  ct_hist        = lt_std ).

    IF iv_legacy = abap_true.
      merge_missing( EXPORTING it_from  = lt_std
                     IMPORTING ev_added = lv_gaps
                     CHANGING  ct_hist  = mt_hist ).
      IF lv_gaps > 0.
        add_msg( EXPORTING iv_type = 'W' iv_number = 023 iv_v1 = lv_gaps
                 CHANGING  ct_msg = et_msg ).
      ENDIF.
    ELSE.
      mt_hist = lt_std.
    ENDIF.

    DATA(lt_scope) = build_scope( ir_werks = ir_werks ir_matnr = ir_matnr ).

    LOOP AT lt_scope INTO DATA(ls_scope).

      DATA(lv_no) = annual_number( iv_werks = ls_scope-werks
                                   iv_matnr = ls_scope-matnr
                                   iv_fyear = iv_fyear ).

      DATA(ls_alv) = VALUE ty_alv( werks   = ls_scope-werks
                                   matnr   = ls_scope-matnr
                                   fyear   = iv_fyear
                                   period  = iv_period
                                   quarter = lv_quarter
                                   fcst_no = lv_no ).

      zcl_pp_fcst_util=>split_fyear( EXPORTING iv_fyear = iv_fyear
                                     IMPORTING ev_year_from = ls_alv-gjahr ).

      fill_master_data( CHANGING cs_alv = ls_alv ).
      fill_category( CHANGING cs_alv = ls_alv ).

      DATA lt_ly_month TYPE STANDARD TABLE OF zde_fcst_qty.
      CLEAR lt_ly_month.

      LOOP AT lt_ly INTO DATA(ls_ly).
        DATA(lv_q) = hist_qty( iv_werks = ls_scope-werks iv_matnr = ls_scope-matnr
                               iv_gjahr = ls_ly-gjahr    iv_month = ls_ly-month ).
        APPEND lv_q TO lt_ly_month.
        ls_alv-ly_qtr_tot = ls_alv-ly_qtr_tot + lv_q.
      ENDLOOP.

      ls_alv-m4_last = VALUE #( lt_ly_month[ 1 ] OPTIONAL ).
      ls_alv-m5_last = VALUE #( lt_ly_month[ 2 ] OPTIONAL ).
      ls_alv-m6_last = VALUE #( lt_ly_month[ 3 ] OPTIONAL ).

      DATA lt_cur_month TYPE STANDARD TABLE OF zde_fcst_qty.
      CLEAR lt_cur_month.

      LOOP AT lt_l3m INTO DATA(ls_l3).
        lv_q = hist_qty( iv_werks = ls_scope-werks iv_matnr = ls_scope-matnr
                         iv_gjahr = ls_l3-gjahr    iv_month = ls_l3-month ).
        APPEND lv_q TO lt_cur_month.
        ls_alv-l3m_tot = ls_alv-l3m_tot + lv_q.
      ENDLOOP.

      ls_alv-m1_curr = VALUE #( lt_cur_month[ 1 ] OPTIONAL ).
      ls_alv-m2_curr = VALUE #( lt_cur_month[ 2 ] OPTIONAL ).
      ls_alv-m3_curr = VALUE #( lt_cur_month[ 3 ] OPTIONAL ).

      ls_alv-l3m_avg = ls_alv-l3m_tot / 3.

      ls_alv-max_qty = ls_alv-l3m_avg * ls_alv-load_fct.

      DATA(lv_ly_same) = hist_qty( iv_werks = ls_scope-werks
                                   iv_matnr = ls_scope-matnr
                                   iv_gjahr = lv_ly_year
                                   iv_month = lv_ly_month ).

      ls_alv-fcst_qty = nmax( val1 = lv_ly_same val2 = ls_alv-max_qty ).

      SELECT SINGLE bus_fcst, bus_fcst_add FROM zppt_fcst_mn
        INTO ( @ls_alv-bus_fcst, @ls_alv-bus_fcst_add )
        WHERE werks = @ls_scope-werks AND matnr = @ls_scope-matnr
          AND gjahr = @ls_alv-gjahr   AND period = @iv_period.

      ls_alv-final_qty = nmax( val1 = ls_alv-fcst_qty val2 = ls_alv-bus_fcst ).
      ls_alv-total_qty = ls_alv-final_qty + ls_alv-bus_fcst_add.

      ls_alv-m4_fcst = ls_alv-final_qty.
      IF iv_tonnage = abap_true.
        ls_alv-m4_ton = zcl_pp_fcst_util=>to_tonnage( iv_qty   = ls_alv-final_qty
                                                      iv_ntgew = ls_alv-ntgew ).
      ENDIF.

      ls_alv-light = '2'.
      APPEND ls_alv TO et_alv.

    ENDLOOP.

    IF et_alv IS INITIAL.
      add_msg( EXPORTING iv_type = 'I' iv_number = 008 CHANGING ct_msg = et_msg ).
    ENDIF.

  ENDMETHOD.

  METHOD save.

    DATA lv_saved TYPE i.
    DATA lv_refused TYPE i.

    LOOP AT ct_alv ASSIGNING FIELD-SYMBOL(<ls>) WHERE mark = abap_true.

      IF zcl_pp_fcst_util=>check_authority( iv_werks = <ls>-werks
                                            iv_actvt = '01' ) = abap_false.
        add_msg( EXPORTING iv_number = 010 iv_v1 = <ls>-werks iv_v2 = '01'
                 CHANGING  ct_msg = rt_msg ).
        <ls>-light = '1'.
        lv_refused = lv_refused + 1.
        CONTINUE.
      ENDIF.

      CASE iv_mode.

        WHEN gc_mode-annual.

          IF <ls>-fcst_no IS INITIAL.
            <ls>-fcst_no = number_get( <ls>-fyear ).
          ENDIF.

          IF <ls>-fcst_no IS INITIAL.
            add_msg( EXPORTING iv_number = 021 iv_v1 = <ls>-fyear
                     CHANGING  ct_msg = rt_msg ).
            <ls>-light = '1'.
            lv_refused = lv_refused + 1.
            CONTINUE.
          ENDIF.

          DATA(ls_yr) = CORRESPONDING zppt_fcst_yr( <ls> ).
          ls_yr-aenam = sy-uname.
          ls_yr-aedat = sy-datum.
          SELECT SINGLE ernam, erdat FROM zppt_fcst_yr
            INTO ( @ls_yr-ernam, @ls_yr-erdat )
            WHERE werks = @<ls>-werks AND matnr = @<ls>-matnr
              AND fyear = @<ls>-fyear.
          IF ls_yr-ernam IS INITIAL.
            ls_yr-ernam = sy-uname.
            ls_yr-erdat = sy-datum.
          ENDIF.
          MODIFY zppt_fcst_yr FROM @ls_yr.

        WHEN gc_mode-quarterly.

          IF <ls>-fcst_no IS INITIAL.
            <ls>-fcst_no = annual_number( iv_werks = <ls>-werks
                                          iv_matnr = <ls>-matnr
                                          iv_fyear = <ls>-fyear ).
          ENDIF.
          IF <ls>-fcst_no IS INITIAL.
            add_msg( EXPORTING iv_number = 005 iv_v1 = <ls>-werks
                               iv_v2 = <ls>-matnr iv_v3 = <ls>-fyear
                     CHANGING  ct_msg = rt_msg ).
            <ls>-light = '1'.
            lv_refused = lv_refused + 1.
            CONTINUE.
          ENDIF.

          DATA(ls_qt) = CORRESPONDING zppt_fcst_qt( <ls> ).
          ls_qt-aenam = sy-uname.
          ls_qt-aedat = sy-datum.
          MODIFY zppt_fcst_qt FROM @ls_qt.

        WHEN gc_mode-monthly.

          IF <ls>-fcst_no IS INITIAL.
            <ls>-fcst_no = annual_number( iv_werks = <ls>-werks
                                          iv_matnr = <ls>-matnr
                                          iv_fyear = <ls>-fyear ).
          ENDIF.
          IF <ls>-fcst_no IS INITIAL.
            add_msg( EXPORTING iv_number = 005 iv_v1 = <ls>-werks
                               iv_v2 = <ls>-matnr iv_v3 = <ls>-fyear
                     CHANGING  ct_msg = rt_msg ).
            <ls>-light = '1'.
            lv_refused = lv_refused + 1.
            CONTINUE.
          ENDIF.

          DATA(ls_mn) = CORRESPONDING zppt_fcst_mn( <ls> ).
          ls_mn-aenam = sy-uname.
          ls_mn-aedat = sy-datum.
          MODIFY zppt_fcst_mn FROM @ls_mn.

      ENDCASE.

      IF sy-subrc = 0.
        <ls>-status  = 'S'.
        <ls>-light   = '3'.
        <ls>-message = |Saved under forecast { <ls>-fcst_no }|.
        CLEAR <ls>-mark.
        lv_saved = lv_saved + 1.
      ELSE.
        <ls>-light   = '1'.
        <ls>-message = |Save failed|.
        lv_refused   = lv_refused + 1.
      ENDIF.

    ENDLOOP.

    IF lv_saved > 0.
      COMMIT WORK AND WAIT.
      add_msg( EXPORTING iv_type = 'S' iv_number = 009
                         iv_v1 = lv_saved
               CHANGING  ct_msg = rt_msg ).
    ELSE.
      ROLLBACK WORK.
      IF lv_refused > 0.
        add_msg( EXPORTING iv_number = 022 iv_v1 = lv_refused
                 CHANGING  ct_msg = rt_msg ).
      ELSE.
        add_msg( EXPORTING iv_number = 017 CHANGING ct_msg = rt_msg ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD read_config.

    SELECT SINGLE vkorg, bwart FROM zppt_fcst_cfg
      INTO ( @mv_vkorg, @mv_bwart )
      WHERE werks IN @ir_werks.

    IF mv_vkorg IS INITIAL.
      mv_vkorg = gc_vkorg_default.
    ENDIF.
    IF mv_bwart IS INITIAL.
      mv_bwart = gc_bwart_default.
    ENDIF.

  ENDMETHOD.

  METHOD build_shkzg_range.

    IF gc_shkzg_ne_blank = abap_true.
      rt_range = VALUE #( ( sign = 'E' option = 'EQ' low = space ) ).
    ELSE.
      rt_range = VALUE #( ( sign = 'I' option = 'EQ' low = space ) ).
    ENDIF.

  ENDMETHOD.

  METHOD read_billing.

    DATA(lr_shkzg) = build_shkzg_range( ).

    SELECT k~fkdat, p~werks, p~matnr, p~fkimg, p~meins
      FROM vbrk AS k
      INNER JOIN vbrp AS p ON p~vbeln = k~vbeln
      INTO TABLE @DATA(lt_bill)
      WHERE k~fkdat BETWEEN @iv_from AND @iv_to
        AND k~fksto  = @space
        AND k~vbtyp <> 'U'
        AND p~werks IN @ir_werks
        AND p~matnr IN @ir_matnr
        AND p~shkzg IN @lr_shkzg.

    LOOP AT lt_bill INTO DATA(ls).

      READ TABLE rt_hist ASSIGNING FIELD-SYMBOL(<ls_h>)
        WITH TABLE KEY werks = ls-werks matnr = ls-matnr
                       gjahr = ls-fkdat(4) month = ls-fkdat+4(2).
      IF sy-subrc <> 0.
        INSERT VALUE #( werks = ls-werks matnr = ls-matnr
                        gjahr = ls-fkdat(4) month = ls-fkdat+4(2)
                        meins = ls-meins ) INTO TABLE rt_hist ASSIGNING <ls_h>.
      ENDIF.
      <ls_h>-qty = <ls_h>-qty + ls-fkimg.

    ENDLOOP.

  ENDMETHOD.

  METHOD read_matdoc.

    SELECT budat, werks, matnr, menge, meins
      FROM matdoc
      INTO TABLE @DATA(lt_mat)
      WHERE budat BETWEEN @iv_from AND @iv_to
        AND bwart     = @mv_bwart
        AND cancelled = @space
        AND werks    IN @ir_werks
        AND matnr    IN @ir_matnr.

    LOOP AT lt_mat INTO DATA(ls).

      READ TABLE rt_hist ASSIGNING FIELD-SYMBOL(<ls_h>)
        WITH TABLE KEY werks = ls-werks matnr = ls-matnr
                       gjahr = ls-budat(4) month = ls-budat+4(2).
      IF sy-subrc <> 0.
        INSERT VALUE #( werks = ls-werks matnr = ls-matnr
                        gjahr = ls-budat(4) month = ls-budat+4(2)
                        meins = ls-meins ) INTO TABLE rt_hist ASSIGNING <ls_h>.
      ENDIF.
      <ls_h>-qty = <ls_h>-qty + ls-menge.

    ENDLOOP.

  ENDMETHOD.

  METHOD read_legacy.

    SELECT * FROM zppt_sls_hist
      INTO TABLE @DATA(lt_leg)
      WHERE werks IN @ir_werks
        AND matnr IN @ir_matnr.

    LOOP AT lt_leg INTO DATA(ls).

      DO 12 TIMES.

        DATA(lv_p)     = CONV numc2( sy-index ).
        DATA(lv_month) = zcl_pp_fcst_util=>period_to_month( lv_p ).

        DATA(lv_year) = COND gjahr( WHEN lv_p <= 9 THEN ls-gjahr ELSE ls-gjahr + 1 ).
        DATA(lv_date) = CONV dats( |{ lv_year }{ lv_month }01| ).

        CHECK lv_date >= iv_from AND lv_date <= iv_to.

        ASSIGN COMPONENT |M{ lv_p }| OF STRUCTURE ls TO FIELD-SYMBOL(<lv_q>).
        CHECK sy-subrc = 0 AND <lv_q> IS NOT INITIAL.

        READ TABLE rt_hist ASSIGNING FIELD-SYMBOL(<ls_h>)
          WITH TABLE KEY werks = ls-werks matnr = ls-matnr
                         gjahr = lv_year  month = lv_month.
        IF sy-subrc <> 0.
          INSERT VALUE #( werks = ls-werks matnr = ls-matnr
                          gjahr = lv_year  month = lv_month
                          meins = ls-meins ) INTO TABLE rt_hist ASSIGNING <ls_h>.
        ENDIF.
        <ls_h>-qty = <ls_h>-qty + <lv_q>.

      ENDDO.

    ENDLOOP.

  ENDMETHOD.

  METHOD add_old_material_qty.

    SELECT werks, new_matnr,
           old_matnr1, old_matnr2, old_matnr3, old_matnr4, old_matnr5
      FROM zppt_mat_track
      INTO TABLE @DATA(lt_track)
      WHERE werks     IN @ir_werks
        AND new_matnr IN @ir_matnr.

    CHECK lt_track IS NOT INITIAL.

    LOOP AT lt_track INTO DATA(ls_track).

      DATA: lr_old TYPE tr_matnr,
            lr_wrk TYPE tr_werks,
            lt_old TYPE tt_hist.

      CLEAR: lr_old, lr_wrk, lt_old.

      DO 5 TIMES.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_track
          TO FIELD-SYMBOL(<lv_o>).
        CHECK sy-subrc = 0.
        IF <lv_o> IS NOT INITIAL AND <lv_o> <> ls_track-new_matnr.
          APPEND VALUE #( sign = 'I' option = 'EQ' low = <lv_o> ) TO lr_old.
        ENDIF.
      ENDDO.
      CHECK lr_old IS NOT INITIAL.

      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_track-werks ) TO lr_wrk.

      IF iv_use_billing = abap_true.
        lt_old = read_billing( ir_werks = lr_wrk
                               ir_matnr = lr_old
                               iv_from  = iv_from
                               iv_to    = iv_to ).
      ELSE.
        lt_old = read_matdoc( ir_werks = lr_wrk
                              ir_matnr = lr_old
                              iv_from  = iv_from
                              iv_to    = iv_to ).
      ENDIF.

      LOOP AT lt_old INTO DATA(ls_old).

        READ TABLE ct_hist ASSIGNING FIELD-SYMBOL(<ls_h>)
          WITH TABLE KEY werks = ls_track-werks
                         matnr = ls_track-new_matnr
                         gjahr = ls_old-gjahr
                         month = ls_old-month.
        IF sy-subrc <> 0.
          INSERT VALUE #( werks = ls_track-werks
                          matnr = ls_track-new_matnr
                          gjahr = ls_old-gjahr
                          month = ls_old-month
                          meins = ls_old-meins ) INTO TABLE ct_hist ASSIGNING <ls_h>.
        ENDIF.
        <ls_h>-qty = <ls_h>-qty + ls_old-qty.

      ENDLOOP.

      DO 5 TIMES.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_track
          TO FIELD-SYMBOL(<lv_d>).
        CHECK sy-subrc = 0.
        IF <lv_d> IS NOT INITIAL AND <lv_d> <> ls_track-new_matnr.
          DELETE ct_hist WHERE werks = ls_track-werks AND matnr = <lv_d>.
        ENDIF.
      ENDDO.

    ENDLOOP.

  ENDMETHOD.

  METHOD build_scope.

    DATA: ls_scope TYPE ty_scope,
          lt_cat   TYPE STANDARD TABLE OF ty_scope WITH DEFAULT KEY,
          lt_excl  TYPE STANDARD TABLE OF ty_scope WITH DEFAULT KEY.

    CLEAR rt_scope.

    LOOP AT mt_hist INTO DATA(ls_hist).
      CLEAR ls_scope.
      ls_scope-werks = ls_hist-werks.
      ls_scope-matnr = ls_hist-matnr.
      APPEND ls_scope TO rt_scope.
    ENDLOOP.

    SELECT werks, matnr
      FROM zppt_prod_cat
      INTO TABLE @lt_cat
      WHERE werks IN @ir_werks
        AND matnr IN @ir_matnr.

    LOOP AT lt_cat INTO ls_scope.
      APPEND ls_scope TO rt_scope.
    ENDLOOP.

    SORT rt_scope BY werks matnr.
    DELETE ADJACENT DUPLICATES FROM rt_scope COMPARING werks matnr.

    SELECT werks, matnr
      FROM zppt_mat_excl
      INTO TABLE @lt_excl
      WHERE werks IN @ir_werks
        AND matnr IN @ir_matnr.

    LOOP AT lt_excl INTO ls_scope.
      DELETE rt_scope WHERE werks = ls_scope-werks
                        AND matnr = ls_scope-matnr.
    ENDLOOP.

    SELECT werks,
           old_matnr1, old_matnr2, old_matnr3, old_matnr4, old_matnr5
      FROM zppt_mat_track
      INTO TABLE @DATA(lt_trk)
      WHERE werks IN @ir_werks.

    LOOP AT lt_trk INTO DATA(ls_trk).
      DO 5 TIMES.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_trk
          TO FIELD-SYMBOL(<lv_s>).
        CHECK sy-subrc = 0.
        IF <lv_s> IS NOT INITIAL.
          DELETE rt_scope WHERE werks = ls_trk-werks AND matnr = <lv_s>.
        ENDIF.
      ENDDO.
    ENDLOOP.

  ENDMETHOD.

  METHOD fill_master_data.

    SELECT SINGLE matkl, meins, ntgew, gewei FROM mara
      INTO ( @cs_alv-matkl, @cs_alv-meins, @cs_alv-ntgew, @cs_alv-gewei )
      WHERE matnr = @cs_alv-matnr.

    SELECT SINGLE maktx FROM makt INTO @cs_alv-maktx
      WHERE matnr = @cs_alv-matnr AND spras = @sy-langu.

    SELECT SINGLE mvgr1, mvgr2, mvgr3, mvgr4, mvgr5 FROM mvke
      INTO ( @cs_alv-mvgr1, @cs_alv-mvgr2, @cs_alv-mvgr3,
             @cs_alv-mvgr4, @cs_alv-mvgr5 )
      WHERE matnr = @cs_alv-matnr AND vkorg = @mv_vkorg.

    IF cs_alv-mvgr1 IS NOT INITIAL.
      SELECT SINGLE bezei FROM tvm1t INTO @cs_alv-mvgr1_txt
        WHERE spras = @sy-langu AND mvgr1 = @cs_alv-mvgr1.
    ENDIF.
    IF cs_alv-mvgr2 IS NOT INITIAL.
      SELECT SINGLE bezei FROM tvm2t INTO @cs_alv-mvgr2_txt
        WHERE spras = @sy-langu AND mvgr2 = @cs_alv-mvgr2.
    ENDIF.
    IF cs_alv-mvgr3 IS NOT INITIAL.
      SELECT SINGLE bezei FROM tvm3t INTO @cs_alv-mvgr3_txt
        WHERE spras = @sy-langu AND mvgr3 = @cs_alv-mvgr3.
    ENDIF.
    IF cs_alv-mvgr4 IS NOT INITIAL.
      SELECT SINGLE bezei FROM tvm4t INTO @cs_alv-mvgr4_txt
        WHERE spras = @sy-langu AND mvgr4 = @cs_alv-mvgr4.
    ENDIF.
    IF cs_alv-mvgr5 IS NOT INITIAL.
      SELECT SINGLE bezei FROM tvm5t INTO @cs_alv-mvgr5_txt
        WHERE spras = @sy-langu AND mvgr5 = @cs_alv-mvgr5.
    ENDIF.

  ENDMETHOD.

  METHOD fill_category.

    SELECT SINGLE prod_cat, load_fct, mts_mto FROM zppt_prod_cat
      INTO ( @cs_alv-prod_cat, @cs_alv-load_fct, @cs_alv-mts_mto )
      WHERE werks = @cs_alv-werks AND matnr = @cs_alv-matnr.

    IF sy-subrc <> 0.
      cs_alv-message = |No product category maintained|.
      cs_alv-light   = '1'.
    ENDIF.

    IF cs_alv-load_fct IS INITIAL.
      cs_alv-load_fct = 1.
    ENDIF.

  ENDMETHOD.

  METHOD hist_qty.

    READ TABLE mt_hist INTO DATA(ls) WITH TABLE KEY werks = iv_werks
                                                    matnr = iv_matnr
                                                    gjahr = iv_gjahr
                                                    month = iv_month.
    IF sy-subrc = 0.
      rv_qty = ls-qty.
    ENDIF.

  ENDMETHOD.

  METHOD annual_number.

    SELECT SINGLE fcst_no FROM zppt_fcst_yr INTO @rv_no
      WHERE werks = @iv_werks AND matnr = @iv_matnr AND fyear = @iv_fyear.

  ENDMETHOD.

  METHOD number_get.

    zcl_pp_fcst_util=>split_fyear( EXPORTING iv_fyear = iv_fyear
                                   IMPORTING ev_year_from = DATA(lv_year) ).
    CHECK lv_year IS NOT INITIAL.

    DATA(lv_range) = CONV nrnr( lv_year+2(2) ).

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING  nr_range_nr             = lv_range
                 object                  = 'ZPPFCST'
      IMPORTING  number                  = rv_no
      EXCEPTIONS interval_not_found      = 1
                 number_range_not_intern = 2
                 object_not_found        = 3
                 OTHERS                  = 4.

    IF sy-subrc <> 0.
      rv_no = number_from_table( iv_fyear ).
    ELSE.
      rv_no = |{ rv_no ALPHA = IN }|.
    ENDIF.

  ENDMETHOD.

  METHOD number_from_table.

    DATA: lv_max  TYPE zde_fcst_no,
          lv_char TYPE char10,
          lv_num  TYPE n LENGTH 10.

    CLEAR rv_no.

    SELECT MAX( fcst_no ) FROM zppt_fcst_yr INTO @lv_max
      WHERE fyear = @iv_fyear.

    IF lv_max IS INITIAL.

      zcl_pp_fcst_util=>split_fyear( EXPORTING iv_fyear     = iv_fyear
                                     IMPORTING ev_year_from = DATA(lv_year) ).
      CHECK lv_year IS NOT INITIAL.

      CONCATENATE lv_year+2(2) '00000001' INTO lv_char.
      rv_no = lv_char.
      RETURN.

    ENDIF.

    TRY.
        lv_num = lv_max.
      CATCH cx_sy_conversion_no_number.
        RETURN.
    ENDTRY.

    lv_num = lv_num + 1.
    rv_no  = lv_num.

  ENDMETHOD.

  METHOD merge_missing.

    CLEAR ev_added.

    LOOP AT it_from INTO DATA(ls_from).

      READ TABLE ct_hist TRANSPORTING NO FIELDS
        WITH TABLE KEY werks = ls_from-werks
                       matnr = ls_from-matnr
                       gjahr = ls_from-gjahr
                       month = ls_from-month.

      CHECK sy-subrc <> 0.

      INSERT ls_from INTO TABLE ct_hist.
      ev_added = ev_added + 1.

    ENDLOOP.

  ENDMETHOD.

  METHOD add_msg.

    DATA(ls_msg) = VALUE bapiret2( id = gc_msgid type = iv_type number = iv_number
                                   message_v1 = iv_v1 message_v2 = iv_v2
                                   message_v3 = iv_v3 message_v4 = iv_v4 ).

    MESSAGE ID ls_msg-id TYPE 'S' NUMBER ls_msg-number
      WITH iv_v1 iv_v2 iv_v3 iv_v4 INTO ls_msg-message.

    APPEND ls_msg TO ct_msg.

  ENDMETHOD.

ENDCLASS.
