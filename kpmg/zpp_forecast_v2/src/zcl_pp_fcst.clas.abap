CLASS zcl_pp_fcst DEFINITION
  PUBLIC
  CREATE PUBLIC.

*"* ZFORECAST (Adhesive) - calculation engine
*"* Astral / UDAY, built to Forecast Template-Adhesive.xlsx dated 20.08.2026
*"*
*"* Shared by ZPP_FORECAST, ZPP_FORECAST_REPORT and ZPP_FORECAST_UPLOAD so the
*"* three cannot diverge.
*"*
*"* Sources, exactly as the document specifies:
*"*   Annual      VBRK / VBRP        sum VBRP-FKIMG
*"*   Quarterly   VBRK / VBRP        sum VBRP-FKIMG
*"*   Monthly     MATDOC BWART 601   sum MATDOC-MENGE
*"*   Old codes   MATDOC             sum MATDOC-MENGE   (all three modes)
*"*   Legacy flag ZPPT_SLS_HIST      M01 to M12
*"*
*"* Formulae - see section 9 of 00_TECHNICAL_OBJECTS.md for the two places
*"* where the document's prose and its worked example disagree.

  PUBLIC SECTION.

    CONSTANTS: BEGIN OF gc_mode,
                 annual    TYPE char1 VALUE 'A',
                 quarterly TYPE char1 VALUE 'Q',
                 monthly   TYPE char1 VALUE 'M',
               END OF gc_mode.

    "! The FS states "VBRP-SHKZG is not equal to blank". Verified against
    "! VBRP in the system on 21.08.2026: SHKZG is blank on normal sales and
    "! X on returns, so the FS condition as written would have built the
    "! forecast from returns only. Set to abap_false, which excludes
    "! returns and includes normal sales. See 9.3.
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
*BOC By Arnav on 31/08/26
*            Price column asked for on all three radio buttons. Where it
*            comes from and how it is worked out is still open with the
*            functional team, so the column is declared and displayed but
*            nothing fills it yet.
*
*            Typed as a plain packed field and NOT over a CURR data
*            element on purpose: a CURR column with no currency reference
*            field makes SALV raise CX_SALV_DATA_ERROR. It is display
*            only and is written to no table, so no DDIC change is needed
*            and the abapGit ZIP is unaffected.
*            " ASSUMPTION: price is per base unit of measure, in the
*            " company code currency. To be confirmed before the logic
*            " is written.
             price     TYPE p LENGTH 13 DECIMALS 2,
*EOC By Arnav on 31/08/26

             "--- annual -------------------------------------------------
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

             "--- quarterly and monthly ----------------------------------
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
*            FS radio button 3 draws TWO finals, column O "Final
*            Forecast Qty" and column Q "final forecast qty", with the
*            additional plan quantity between them. FINAL_QTY is O,
*            TOTAL_QTY is Q. Display only - it is FINAL_QTY plus
*            BUS_FCST_ADD, both of which are stored, so nothing new is
*            written to the database.
             total_qty    TYPE zde_fcst_qty,
             m4_fcst      TYPE zde_fcst_qty,
             m5_fcst      TYPE zde_fcst_qty,
             m6_fcst      TYPE zde_fcst_qty,
             m4_ton       TYPE zde_fcst_qty,
             m5_ton       TYPE zde_fcst_qty,
             m6_ton       TYPE zde_fcst_qty,
             reason       TYPE zde_fcst_reason,
*BOC By Arnav on 03/09/26
*            Quarterly splits the additional plan quantity by month.
*            BUS_FCST_ADD above is left for the MONTHLY sheet -
*            ZPPT_FCST_MN is one row per month already and has nothing
*            to split. REASON stays SINGLE on both tables: the CR did
*            not ask for one per month. A quarter changed three times
*            therefore keeps the reason from the LAST row uploaded.
             bus_fcst_add1 TYPE zde_fcst_qty,
             bus_fcst_add2 TYPE zde_fcst_qty,
             bus_fcst_add3 TYPE zde_fcst_qty,
             m4_fcst_final TYPE zde_fcst_qty,
             m5_fcst_final TYPE zde_fcst_qty,
             m6_fcst_final TYPE zde_fcst_qty,
*            Final quantity x PRICE, and final tonnage x PRICE. Both are
*            0 until the price logic lands.
*
*            Typed the same way as PRICE above and NOT over the CURR
*            data element ZDE_FCST_VAL, for the reason the 31/08 note
*            gives: a CURR column with no currency reference field in
*            the structure makes SALV raise CX_SALV_DATA_ERROR. The
*            table fields are CURR; these are display only and
*            CORRESPONDING converts between them.
             m4_val        TYPE p LENGTH 13 DECIMALS 2,
             m5_val        TYPE p LENGTH 13 DECIMALS 2,
             m6_val        TYPE p LENGTH 13 DECIMALS 2,
             m4_ton_val    TYPE p LENGTH 13 DECIMALS 2,
             m5_ton_val    TYPE p LENGTH 13 DECIMALS 2,
             m6_ton_val    TYPE p LENGTH 13 DECIMALS 2,
*EOC By Arnav on 03/09/26
           END OF ty_alv,
           tt_alv   TYPE STANDARD TABLE OF ty_alv WITH DEFAULT KEY,
           tr_werks TYPE RANGE OF werks_d,
           tr_matnr TYPE RANGE OF matnr,
           tr_shkzg TYPE RANGE OF vbrp-shkzg.

    "! Annual forecast - FS radio Button 1
    METHODS generate_annual
      IMPORTING ir_werks   TYPE tr_werks
                ir_matnr   TYPE tr_matnr
                iv_fyear   TYPE zde_fyear
                iv_legacy  TYPE abap_bool DEFAULT abap_false
                iv_tonnage TYPE abap_bool DEFAULT abap_false
      EXPORTING et_alv     TYPE tt_alv
                et_msg     TYPE bapiret2_t.

    "! Quarterly forecast - FS radio Button 2
    METHODS generate_quarterly
      IMPORTING ir_werks   TYPE tr_werks
                ir_matnr   TYPE tr_matnr
                iv_fyear   TYPE zde_fyear
                iv_quarter TYPE zde_quarter
                iv_legacy  TYPE abap_bool DEFAULT abap_false
                iv_tonnage TYPE abap_bool DEFAULT abap_false
      EXPORTING et_alv     TYPE tt_alv
                et_msg     TYPE bapiret2_t.

    "! Monthly forecast - FS radio button 3
    METHODS generate_monthly
      IMPORTING ir_werks   TYPE tr_werks
                ir_matnr   TYPE tr_matnr
                iv_fyear   TYPE zde_fyear
                iv_period  TYPE poper
                iv_legacy  TYPE abap_bool DEFAULT abap_false
                iv_tonnage TYPE abap_bool DEFAULT abap_false
      EXPORTING et_alv     TYPE tt_alv
                et_msg     TYPE bapiret2_t.

    "! Update or insert. Where a forecast already exists for the plant,
    "! material and year the existing number is reused and the row is
    "! overwritten, exactly as the document requires.
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

    "! Billing quantity by plant, material and calendar month.
    METHODS read_billing
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
      RETURNING VALUE(rt_hist) TYPE tt_hist.

    "! Goods issue quantity by plant, material and calendar month.
    METHODS read_matdoc
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
      RETURNING VALUE(rt_hist) TYPE tt_hist.

    "! Uploaded legacy history, twelve months per row.
    METHODS read_legacy
      IMPORTING ir_werks       TYPE tr_werks
                ir_matnr       TYPE tr_matnr
                iv_from        TYPE dats
                iv_to          TYPE dats
      RETURNING VALUE(rt_hist) TYPE tt_hist.

    "! Adds the quantities of superseded material codes into the buckets of
    "! their successor, from MATDOC as the document specifies.
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

*BOC By Arnav on 31/08/26
    "! Adds the buckets of IT_FROM that CT_HIST does not already carry.
    "! Nothing already in CT_HIST is touched, so the legacy figure always
    "! wins over the standard one for the same plant, material and month.
    METHODS merge_missing
      IMPORTING it_from  TYPE tt_hist
      EXPORTING ev_added TYPE i
      CHANGING  ct_hist  TYPE tt_hist.
*EOC By Arnav on 31/08/26

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

*BOC By Arnav on 31/08/26
    "! Next forecast number derived from ZPPT_FCST_YR itself. Used only
    "! when number range object ZPPFCST is not available, so that a
    "! missing SNRO entry does not stop the user saving.
    METHODS number_from_table
      IMPORTING iv_fyear     TYPE zde_fyear
      RETURNING VALUE(rv_no) TYPE zde_fcst_no.
*EOC By Arnav on 31/08/26

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

*&---------------------------------------------------------------------*
*& Annual - FS radio Button 1
*&---------------------------------------------------------------------*
  METHOD generate_annual.

    CLEAR: et_alv, et_msg.

    read_config( ir_werks ).

    " The ALV columns run April to March of the PREVIOUS financial year,
    " so history is taken from that year's date range - see 9.4
    DATA(lv_prev) = zcl_pp_fcst_util=>previous_fyear( iv_fyear ).
    IF lv_prev IS INITIAL.
      add_msg( EXPORTING iv_number = 002 iv_v1 = iv_fyear CHANGING ct_msg = et_msg ).
      RETURN.
    ENDIF.

    zcl_pp_fcst_util=>fyear_dates( EXPORTING iv_fyear = lv_prev
                                   IMPORTING ev_from  = DATA(lv_from)
                                             ev_to    = DATA(lv_to) ).

*BOC By Arnav on 31/08/26
*   Legacy used to be exclusive - a plant, material and month that
*   ZPPT_SLS_HIST did not carry was reported as zero, and a material with
*   no legacy row at all disappeared from the run:
*
*    IF iv_legacy = abap_true.
*      mt_hist = read_legacy( ir_werks = ir_werks ir_matnr = ir_matnr
*                             iv_from = lv_from iv_to = lv_to ).
*    ELSE.
*      mt_hist = read_billing( ir_werks = ir_werks ir_matnr = ir_matnr
*                              iv_from = lv_from iv_to = lv_to ).
*      add_old_material_qty( EXPORTING ir_werks = ir_werks ir_matnr = ir_matnr
*                                      iv_from = lv_from iv_to = lv_to
*                            CHANGING  ct_hist = mt_hist ).
*    ENDIF.
*
*   Legacy is now the PREFERRED source rather than the only one. Every
*   bucket legacy does not cover is filled from the standard tables, so a
*   part loaded legacy file no longer hides the SAP history behind it.
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
*EOC By Arnav on 31/08/26

    DATA(lt_scope) = build_scope( ir_werks = ir_werks ir_matnr = ir_matnr ).

    LOOP AT lt_scope INTO DATA(ls_scope).

      DATA(ls_alv) = VALUE ty_alv( werks = ls_scope-werks
                                   matnr = ls_scope-matnr
                                   fyear = iv_fyear ).

      fill_master_data( CHANGING cs_alv = ls_alv ).
      fill_category( CHANGING cs_alv = ls_alv ).

      " Twelve months of last year, and the running total
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

      " Forecast Qty = Total LY Sales Qty x Load Factor
      ls_alv-fcst_total = ls_alv-ly_total * ls_alv-load_fct.

      " Split: each forecast month takes its own share of last year.
      " The document repeats "april 25" for all twelve months; its own
      " figures prove each month uses its own value - see 9.1 and the note
      " in the technical object list.
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

      " Already saved?
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


*&---------------------------------------------------------------------*
*& Quarterly - FS radio Button 2
*& Load factor is applied AFTER the max, per the worked example.
*&---------------------------------------------------------------------*
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

    " One read spanning both comparison windows
    DATA(lv_from) = VALUE dats( lt_ly[ 1 ]-datfr OPTIONAL ).
    DATA(lv_to)   = VALUE dats( lt_l3m[ 3 ]-datto OPTIONAL ).
    IF lv_to < lv_from.
      DATA(lv_swap) = lv_from. lv_from = lv_to. lv_to = lv_swap.
    ENDIF.

*BOC By Arnav on 31/08/26
*   Legacy is the preferred source, not the only one - see the note in
*   GENERATE_ANNUAL. The standard tables fill every plant, material and
*   month the legacy upload does not carry.
*
*    IF iv_legacy = abap_true.
*      mt_hist = read_legacy( ir_werks = ir_werks ir_matnr = ir_matnr
*                             iv_from = lv_from iv_to = lv_to ).
*    ELSE.
*      mt_hist = read_billing( ir_werks = ir_werks ir_matnr = ir_matnr
*                              iv_from = lv_from iv_to = lv_to ).
*      add_old_material_qty( EXPORTING ir_werks = ir_werks ir_matnr = ir_matnr
*                                      iv_from = lv_from iv_to = lv_to
*                            CHANGING  ct_hist = mt_hist ).
*    ENDIF.
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
*EOC By Arnav on 31/08/26

    DATA(lt_scope) = build_scope( ir_werks = ir_werks ir_matnr = ir_matnr ).

    LOOP AT lt_scope INTO DATA(ls_scope).

*     The forecast number is carried across from the annual table, per
*     the FS: "Insert the data with same forecast number by passing the
*     fiscal year to ZPP_ADH_FORECAST_YEAR and take FORECAST number".
*     That is a SAVE rule, not a display rule - the quarterly ALV does
*     not draw the forecast number at all - so a material with no annual
*     forecast is still calculated and shown here. SAVE is where it is
*     refused.
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

      " Last year, same quarter - kept month by month because the split
      " back into months is proportional to them
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

      " Current year, last three months
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

      "--- Max, then load factor -----------------------------------------
      ls_alv-max_qty  = nmax( val1 = ls_alv-ly_qtr_tot val2 = ls_alv-l3m_tot ).
      ls_alv-fcst_qty = ls_alv-max_qty * ls_alv-load_fct.

      "--- Business forecast already uploaded ----------------------------
*BOC By Arnav on 03/09/26
*     SELECT SINGLE bus_fcst, bus_fcst_add FROM zppt_fcst_qt
*       INTO ( @ls_alv-bus_fcst, @ls_alv-bus_fcst_add )
*       WHERE werks = @ls_scope-werks AND matnr = @ls_scope-matnr
*         AND gjahr = @ls_alv-gjahr   AND quarter = @iv_quarter.
*
*     ls_alv-final_qty = nmax( val1 = ls_alv-fcst_qty val2 = ls_alv-bus_fcst ).
*     ls_alv-total_qty = ls_alv-final_qty + ls_alv-bus_fcst_add.
*     The additional plan quantity is per month now. REASON, WAERS and
*     PRICE are read back too - SAVE writes the row with CORRESPONDING,
*     so anything not read here would be blanked by the next save.
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
*EOC By Arnav on 03/09/26

      "--- Split back into the three months ------------------------------
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

*BOC By Arnav on 03/09/26
*       Final of a month = that month's forecast plus that month's
*       additional plan quantity. The value columns are the final
*       quantity, and the final quantity in tonnes, times PRICE. PRICE
*       is still not filled by anything, so both read 0.
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
*EOC By Arnav on 03/09/26

      ENDDO.

      ls_alv-light = '2'.
      APPEND ls_alv TO et_alv.

    ENDLOOP.

    IF et_alv IS INITIAL.
      add_msg( EXPORTING iv_type = 'I' iv_number = 008 CHANGING ct_msg = et_msg ).
    ENDIF.

  ENDMETHOD.


*&---------------------------------------------------------------------*
*& Monthly - FS radio button 3
*& Source is MATDOC movement 601, and the load factor is applied to the
*& average BEFORE the max. See 9.1 - this is the reading that reproduces
*& the document's own figure of 1,200 for product M2.
*&---------------------------------------------------------------------*
  METHOD generate_monthly.

    CLEAR: et_alv, et_msg.

    read_config( ir_werks ).

    DATA(lv_quarter) = zcl_pp_fcst_util=>period_to_quarter( CONV #( iv_period ) ).
    DATA(lt_ly)      = zcl_pp_fcst_util=>last_year_quarter( iv_fyear = iv_fyear
                                                            iv_quarter = lv_quarter ).
    DATA(lt_l3m)     = zcl_pp_fcst_util=>last_three_months( iv_fyear = iv_fyear
                                                            iv_period = CONV #( iv_period ) ).

    " Last year, same month
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

*BOC By Arnav on 31/08/26
*   Legacy is the preferred source, not the only one - see the note in
*   GENERATE_ANNUAL. Monthly reads material documents rather than
*   invoices, so the gaps are filled from MATDOC.
*
*    IF iv_legacy = abap_true.
*      mt_hist = read_legacy( ir_werks = ir_werks ir_matnr = ir_matnr
*                             iv_from = lv_from iv_to = lv_to ).
*    ELSE.
*      mt_hist = read_matdoc( ir_werks = ir_werks ir_matnr = ir_matnr
*                             iv_from = lv_from iv_to = lv_to ).
*      add_old_material_qty( EXPORTING ir_werks       = ir_werks
*                                      ir_matnr       = ir_matnr
*                                      iv_from        = lv_from
*                                      iv_to          = lv_to
*                                      iv_use_billing = abap_false
*                            CHANGING  ct_hist        = mt_hist ).
*    ENDIF.
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
*EOC By Arnav on 31/08/26

    DATA(lt_scope) = build_scope( ir_werks = ir_werks ir_matnr = ir_matnr ).

    LOOP AT lt_scope INTO DATA(ls_scope).

*     Same as quarterly - read the number if it is there, but do not
*     refuse to calculate without it. SAVE enforces the dependency.
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

      " Last year quarter, shown for reference
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

      " Current year, last three months
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

      "--- Load factor on the average, THEN the max ----------------------
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


*&---------------------------------------------------------------------*
*& Save - update or insert
*&---------------------------------------------------------------------*
  METHOD save.

    DATA lv_saved TYPE i.
*BOC By Arnav on 31/08/26
    DATA lv_refused TYPE i.
*EOC By Arnav on 31/08/26

    LOOP AT ct_alv ASSIGNING FIELD-SYMBOL(<ls>) WHERE mark = abap_true.

      IF zcl_pp_fcst_util=>check_authority( iv_werks = <ls>-werks
                                            iv_actvt = '01' ) = abap_false.
        add_msg( EXPORTING iv_number = 010 iv_v1 = <ls>-werks iv_v2 = '01'
                 CHANGING  ct_msg = rt_msg ).
        <ls>-light = '1'.
        lv_refused = lv_refused + 1.   "Changes by Arnav on 31/08/26
        CONTINUE.
      ENDIF.

      CASE iv_mode.

        WHEN gc_mode-annual.

          " Reuse the existing number, or draw a new one
          IF <ls>-fcst_no IS INITIAL.
            <ls>-fcst_no = number_get( <ls>-fyear ).
          ENDIF.

*         NUMBER_GET_NEXT clears the number when the object or the
*         interval is missing. Writing the row anyway put a blank
*         forecast number into the table, reported success, and left
*         quarterly reporting "annual forecast does not exist" two steps
*         later with nothing to point at. The row is refused instead.
          IF <ls>-fcst_no IS INITIAL.
            add_msg( EXPORTING iv_number = 021 iv_v1 = <ls>-fyear
                     CHANGING  ct_msg = rt_msg ).
            <ls>-light = '1'.
            lv_refused = lv_refused + 1.   "Changes by Arnav on 31/08/26
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

*         The FS stores the quarterly row under the annual forecast
*         number, so there has to be one. Refused here rather than at
*         generation, so the user can still see and check the figures.
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
            lv_refused = lv_refused + 1.   "Changes by Arnav on 31/08/26
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
            lv_refused = lv_refused + 1.   "Changes by Arnav on 31/08/26
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
        lv_refused   = lv_refused + 1.   "Changes by Arnav on 31/08/26
      ENDIF.

    ENDLOOP.

    IF lv_saved > 0.
      COMMIT WORK AND WAIT.
*     The forecast number is per plant, material and financial year -
*     that is the key of ZPPT_FCST_YR - so a run over ten materials
*     draws ten numbers. Naming only the first one here read as though
*     that single number covered them all. The count is reported and
*     each row carries its own number in the Forecast Number column.
      add_msg( EXPORTING iv_type = 'S' iv_number = 009
                         iv_v1 = lv_saved
               CHANGING  ct_msg = rt_msg ).
    ELSE.
      ROLLBACK WORK.
*BOC By Arnav on 31/08/26
*     017 is "Select at least one line", which is what the user was told
*     even when they had selected rows and every one of them had been
*     refused for a reason already sitting in RT_MSG. The two cases are
*     now told apart.
*      add_msg( EXPORTING iv_number = 017 CHANGING ct_msg = rt_msg ).
      IF lv_refused > 0.
        add_msg( EXPORTING iv_number = 022 iv_v1 = lv_refused
                 CHANGING  ct_msg = rt_msg ).
      ELSE.
        add_msg( EXPORTING iv_number = 017 CHANGING ct_msg = rt_msg ).
      ENDIF.
*EOC By Arnav on 31/08/26
    ENDIF.

  ENDMETHOD.


*&---------------------------------------------------------------------*
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


*&---------------------------------------------------------------------*
  METHOD build_shkzg_range.

    " FS states SHKZG is not equal to blank. See gc_shkzg_ne_blank.
    IF gc_shkzg_ne_blank = abap_true.
      rt_range = VALUE #( ( sign = 'E' option = 'EQ' low = space ) ).
    ELSE.
      rt_range = VALUE #( ( sign = 'I' option = 'EQ' low = space ) ).
    ENDIF.

  ENDMETHOD.


*&---------------------------------------------------------------------*
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


*&---------------------------------------------------------------------*
  METHOD read_matdoc.

    " CANCELLED - confirm the field name in this release, see 9.5
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


*&---------------------------------------------------------------------*
  METHOD read_legacy.

    SELECT * FROM zppt_sls_hist
      INTO TABLE @DATA(lt_leg)
      WHERE werks IN @ir_werks
        AND matnr IN @ir_matnr.

    LOOP AT lt_leg INTO DATA(ls).

      DO 12 TIMES.

        DATA(lv_p)     = CONV numc2( sy-index ).
        DATA(lv_month) = zcl_pp_fcst_util=>period_to_month( lv_p ).

        " Periods 01 to 09 are in GJAHR, periods 10 to 12 in the next year
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


*&---------------------------------------------------------------------*
*& Superseded material codes. Their quantities are added into the buckets
*& of the successor code, from MATDOC as the document specifies - note
*& that this applies even in the billing based modes, query M2.
*&---------------------------------------------------------------------*
  METHOD add_old_material_qty.

*BOC By Arnav on 03/09/26  - five superseded codes per successor, not two
*   SELECT werks, new_matnr, old_matnr1, old_matnr2
    SELECT werks, new_matnr,
           old_matnr1, old_matnr2, old_matnr3, old_matnr4, old_matnr5
*EOC By Arnav on 03/09/26
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

*BOC By Arnav on 03/09/26
*     IF ls_track-old_matnr1 IS NOT INITIAL
*    AND ls_track-old_matnr1 <> ls_track-new_matnr.
*       APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_track-old_matnr1 ) TO lr_old.
*     ENDIF.
*     IF ls_track-old_matnr2 IS NOT INITIAL
*    AND ls_track-old_matnr2 <> ls_track-new_matnr.
*       APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_track-old_matnr2 ) TO lr_old.
*     ENDIF.
*     Walked, so a sixth old code is one number and not another block.
      DO 5 TIMES.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_track
          TO FIELD-SYMBOL(<lv_o>).
        CHECK sy-subrc = 0.
        IF <lv_o> IS NOT INITIAL AND <lv_o> <> ls_track-new_matnr.
          APPEND VALUE #( sign = 'I' option = 'EQ' low = <lv_o> ) TO lr_old.
        ENDIF.
      ENDDO.
*EOC By Arnav on 03/09/26
      CHECK lr_old IS NOT INITIAL.

      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_track-werks ) TO lr_wrk.

*     The superseded code is read from the SAME source as its successor,
*     so the absorbed history is comparable. Annual and quarterly read
*     invoices, monthly reads material documents.
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

*     Absorb the old quantities into the successor month by month
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

*     The old code is retired and its history now belongs to the
*     successor, so it must not remain in its own right. Without this it
*     would be counted twice and would receive a forecast of its own.
*BOC By Arnav on 03/09/26
*     IF ls_track-old_matnr1 IS NOT INITIAL
*    AND ls_track-old_matnr1 <> ls_track-new_matnr.
*       DELETE ct_hist WHERE werks = ls_track-werks
*                        AND matnr = ls_track-old_matnr1.
*     ENDIF.
*     IF ls_track-old_matnr2 IS NOT INITIAL
*    AND ls_track-old_matnr2 <> ls_track-new_matnr.
*       DELETE ct_hist WHERE werks = ls_track-werks
*                        AND matnr = ls_track-old_matnr2.
*     ENDIF.
      DO 5 TIMES.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_track
          TO FIELD-SYMBOL(<lv_d>).
        CHECK sy-subrc = 0.
        IF <lv_d> IS NOT INITIAL AND <lv_d> <> ls_track-new_matnr.
          DELETE ct_hist WHERE werks = ls_track-werks AND matnr = <lv_d>.
        ENDIF.
      ENDDO.
*EOC By Arnav on 03/09/26

    ENDLOOP.

  ENDMETHOD.


*&---------------------------------------------------------------------*
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

*   Superseded material codes never appear in their own right. Their
*   history has been absorbed into the successor, so a single row is
*   shown for the successor carrying the full twelve months. This also
*   covers the case where the old code still has a category maintained,
*   which would otherwise add it back.
*BOC By Arnav on 03/09/26
*   SELECT werks, old_matnr1, old_matnr2
    SELECT werks,
           old_matnr1, old_matnr2, old_matnr3, old_matnr4, old_matnr5
*EOC By Arnav on 03/09/26
      FROM zppt_mat_track
      INTO TABLE @DATA(lt_trk)
      WHERE werks IN @ir_werks.

    LOOP AT lt_trk INTO DATA(ls_trk).
*BOC By Arnav on 03/09/26
*     IF ls_trk-old_matnr1 IS NOT INITIAL.
*       DELETE rt_scope WHERE werks = ls_trk-werks
*                         AND matnr = ls_trk-old_matnr1.
*     ENDIF.
*     IF ls_trk-old_matnr2 IS NOT INITIAL.
*       DELETE rt_scope WHERE werks = ls_trk-werks
*                         AND matnr = ls_trk-old_matnr2.
*     ENDIF.
      DO 5 TIMES.
        ASSIGN COMPONENT |OLD_MATNR{ sy-index }| OF STRUCTURE ls_trk
          TO FIELD-SYMBOL(<lv_s>).
        CHECK sy-subrc = 0.
        IF <lv_s> IS NOT INITIAL.
          DELETE rt_scope WHERE werks = ls_trk-werks AND matnr = <lv_s>.
        ENDIF.
      ENDDO.
*EOC By Arnav on 03/09/26
    ENDLOOP.

  ENDMETHOD.


*&---------------------------------------------------------------------*
  METHOD fill_master_data.

*BOC By Arnav on 31/08/26
*   Net weight is MARA-NTGEW and its unit MARA-GEWEI, confirmed with the
*   functional team on 31/08/26. It is read here, shown in the Net Weight
*   column of all three modes and is the only figure ZCL_PP_FCST_UTIL
*   =>TO_TONNAGE multiplies by, so a material with no net weight in MARA
*   reports zero tonnage rather than a wrong one.
*   Field list and target list are matched by POSITION - MATKL, MEINS,
*   NTGEW, GEWEI in both.
*EOC By Arnav on 31/08/26
    SELECT SINGLE matkl, meins, ntgew, gewei FROM mara
      INTO ( @cs_alv-matkl, @cs_alv-meins, @cs_alv-ntgew, @cs_alv-gewei )
      WHERE matnr = @cs_alv-matnr.

    SELECT SINGLE maktx FROM makt INTO @cs_alv-maktx
      WHERE matnr = @cs_alv-matnr AND spras = @sy-langu.

    SELECT SINGLE mvgr1, mvgr2, mvgr3, mvgr4, mvgr5 FROM mvke
      INTO ( @cs_alv-mvgr1, @cs_alv-mvgr2, @cs_alv-mvgr3,
             @cs_alv-mvgr4, @cs_alv-mvgr5 )
      WHERE matnr = @cs_alv-matnr AND vkorg = @mv_vkorg.

    " Descriptions, as the document asks for BEZEI rather than the code
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


*&---------------------------------------------------------------------*
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


*&---------------------------------------------------------------------*
  METHOD hist_qty.

    READ TABLE mt_hist INTO DATA(ls) WITH TABLE KEY werks = iv_werks
                                                    matnr = iv_matnr
                                                    gjahr = iv_gjahr
                                                    month = iv_month.
    IF sy-subrc = 0.
      rv_qty = ls-qty.
    ENDIF.

  ENDMETHOD.


*&---------------------------------------------------------------------*
  METHOD annual_number.

    SELECT SINGLE fcst_no FROM zppt_fcst_yr INTO @rv_no
      WHERE werks = @iv_werks AND matnr = @iv_matnr AND fyear = @iv_fyear.

  ENDMETHOD.


*&---------------------------------------------------------------------*
*& Forecast number, financial year dependent. The interval number is the
*& last two digits of the year the financial year starts in, so
*& 2026-2027 draws from interval 26.
*&---------------------------------------------------------------------*
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
*BOC By Arnav on 31/08/26
*     A missing SNRO object or interval used to clear the number, the row
*     was then refused, and the user reported that the system would not
*     let them save anything at all. SNRO stays the right source and is
*     still tried first; when it is not there the number is derived from
*     ZPPT_FCST_YR so the forecast can still be saved.
*      CLEAR rv_no.
      rv_no = number_from_table( iv_fyear ).
*EOC By Arnav on 31/08/26
    ELSE.
      rv_no = |{ rv_no ALPHA = IN }|.
    ENDIF.

  ENDMETHOD.


*&---------------------------------------------------------------------*
*& Forecast number without SNRO
*&
*& Only reached when NUMBER_GET_NEXT could not serve the number. The
*& highest number already stored for the financial year is taken and one
*& is added; the first number of a year is the last two digits of the
*& year the financial year starts in followed by 00000001, which is the
*& shape the number range gives.
*&
*& " ASSUMPTION: this is a fallback, not a replacement. Two users saving
*& " in the same second could draw the same number, so number range
*& " object ZPPFCST must still be created in SNRO - see NOTES.md.
*&---------------------------------------------------------------------*
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

*   A number written by an earlier release, or by hand, may not be
*   numeric. Rather than dump, the row is refused as it was before.
    TRY.
        lv_num = lv_max.
      CATCH cx_sy_conversion_no_number.
        RETURN.
    ENDTRY.

    lv_num = lv_num + 1.
    rv_no  = lv_num.

  ENDMETHOD.


*&---------------------------------------------------------------------*
*& Fill the buckets one source does not cover from another
*&---------------------------------------------------------------------*
  METHOD merge_missing.

    CLEAR ev_added.

    LOOP AT it_from INTO DATA(ls_from).

      READ TABLE ct_hist TRANSPORTING NO FIELDS
        WITH TABLE KEY werks = ls_from-werks
                       matnr = ls_from-matnr
                       gjahr = ls_from-gjahr
                       month = ls_from-month.

*     Already carried by the preferred source, which wins
      CHECK sy-subrc <> 0.

      INSERT ls_from INTO TABLE ct_hist.
      ev_added = ev_added + 1.

    ENDLOOP.

  ENDMETHOD.


*&---------------------------------------------------------------------*
  METHOD add_msg.

    DATA(ls_msg) = VALUE bapiret2( id = gc_msgid type = iv_type number = iv_number
                                   message_v1 = iv_v1 message_v2 = iv_v2
                                   message_v3 = iv_v3 message_v4 = iv_v4 ).

    MESSAGE ID ls_msg-id TYPE 'S' NUMBER ls_msg-number
      WITH iv_v1 iv_v2 iv_v3 iv_v4 INTO ls_msg-message.

    APPEND ls_msg TO ct_msg.

  ENDMETHOD.

ENDCLASS.
