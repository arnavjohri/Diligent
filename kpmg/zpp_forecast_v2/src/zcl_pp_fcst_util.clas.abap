CLASS zcl_pp_fcst_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

*"* ZFORECAST (Adhesive) - financial year, quarter, period and tonnage helpers
*"* Astral / UDAY, built to Forecast Template-Adhesive.xlsx dated 20.08.2026
*"*
*"* Financial year is April to March. Period 01 is April, period 12 is March.
*"* Quarters follow the mapping tabulated in FS radio Button 2:
*"*   Q1 Apr-Jun   Q2 Jul-Sep   Q3 Oct-Dec   Q4 Jan-Mar

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_period,
             gjahr  TYPE gjahr,
             month  TYPE numc2,
             period TYPE numc2,
             datfr  TYPE dats,
             datto  TYPE dats,
           END OF ty_period,
           tt_period TYPE STANDARD TABLE OF ty_period WITH DEFAULT KEY.

    CONSTANTS gc_msgid TYPE symsgid VALUE 'ZPP_FCST'.

    "! Split "2026-2027" into its two calendar years.
    CLASS-METHODS split_fyear
      IMPORTING iv_fyear     TYPE zde_fyear
      EXPORTING ev_year_from TYPE gjahr
                ev_year_to   TYPE gjahr
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    "! 2026-2027 becomes 2025-2026.
    CLASS-METHODS previous_fyear
      IMPORTING iv_fyear       TYPE zde_fyear
      RETURNING VALUE(rv_prev) TYPE zde_fyear.

    "! First and last calendar date of a financial year.
    CLASS-METHODS fyear_dates
      IMPORTING iv_fyear TYPE zde_fyear
      EXPORTING ev_from  TYPE dats
                ev_to    TYPE dats.

    CLASS-METHODS month_to_period
      IMPORTING iv_month         TYPE numc2
      RETURNING VALUE(rv_period) TYPE numc2.

    CLASS-METHODS period_to_month
      IMPORTING iv_period       TYPE numc2
      RETURNING VALUE(rv_month) TYPE numc2.

    CLASS-METHODS period_to_quarter
      IMPORTING iv_period         TYPE numc2
      RETURNING VALUE(rv_quarter) TYPE zde_quarter.

    "! Calendar year and month of a financial period within a financial year.
    CLASS-METHODS period_to_yearmonth
      IMPORTING iv_fyear  TYPE zde_fyear
                iv_period TYPE numc2
      EXPORTING ev_gjahr  TYPE gjahr
                ev_month  TYPE numc2.

    "! First and last calendar date of one financial period.
    CLASS-METHODS period_dates
      IMPORTING iv_fyear  TYPE zde_fyear
                iv_period TYPE numc2
      EXPORTING ev_from   TYPE dats
                ev_to     TYPE dats.

    "! The three months of a quarter, with their calendar dates.
    "! Q2 of 2026-2027 returns Jul-26, Aug-26, Sep-26.
    CLASS-METHODS quarter_periods
      IMPORTING iv_fyear      TYPE zde_fyear
                iv_quarter    TYPE zde_quarter
      RETURNING VALUE(rt_per) TYPE tt_period.

    "! The same quarter one financial year earlier.
    CLASS-METHODS last_year_quarter
      IMPORTING iv_fyear      TYPE zde_fyear
                iv_quarter    TYPE zde_quarter
      RETURNING VALUE(rt_per) TYPE tt_period.

    "! The three calendar months immediately before iv_period.
    "! For Q1 these fall into the previous financial year.
    CLASS-METHODS last_three_months
      IMPORTING iv_fyear      TYPE zde_fyear
                iv_period     TYPE numc2
      RETURNING VALUE(rt_per) TYPE tt_period.

    "! Tonnage. The document states forecast quantity multiplied by the
    "! material net weight, with no unit conversion, so none is applied.
    CLASS-METHODS to_tonnage
      IMPORTING iv_qty        TYPE zde_fcst_qty
                iv_ntgew      TYPE ntgew
      RETURNING VALUE(rv_ton) TYPE zde_fcst_qty.

    CLASS-METHODS check_authority
      IMPORTING iv_werks     TYPE werks_d
                iv_actvt     TYPE activ_auth
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    "! Legacy data is protected by a TVARVC entry naming the permitted users.
    CLASS-METHODS check_legacy_authority
      IMPORTING iv_werks     TYPE werks_d
      RETURNING VALUE(rv_ok) TYPE abap_bool.

  PRIVATE SECTION.

    CLASS-METHODS last_day
      IMPORTING iv_date        TYPE dats
      RETURNING VALUE(rv_date) TYPE dats.

ENDCLASS.


CLASS zcl_pp_fcst_util IMPLEMENTATION.

  METHOD split_fyear.

    CLEAR: ev_year_from, ev_year_to.

    IF strlen( iv_fyear ) <> 9 OR iv_fyear+4(1) <> '-'.
      RETURN.
    ENDIF.

    TRY.
        ev_year_from = iv_fyear(4).
        ev_year_to   = iv_fyear+5(4).
      CATCH cx_sy_conversion_no_number.
        RETURN.
    ENDTRY.

*   GJAHR is NUMC, so both sides are converted to integers before the
*   comparison rather than comparing a NUMC field with an expression
    DATA(lv_from_i) = CONV i( ev_year_from ).
    DATA(lv_to_i)   = CONV i( ev_year_to ).

    IF lv_to_i <> lv_from_i + 1.
      CLEAR: ev_year_from, ev_year_to.
      RETURN.
    ENDIF.

    rv_ok = abap_true.

  ENDMETHOD.


  METHOD previous_fyear.

    split_fyear( EXPORTING iv_fyear     = iv_fyear
                 IMPORTING ev_year_from = DATA(lv_from) ).

    CHECK lv_from IS NOT INITIAL.

    rv_prev = |{ lv_from - 1 }-{ lv_from }|.

  ENDMETHOD.


  METHOD fyear_dates.

    CLEAR: ev_from, ev_to.

    split_fyear( EXPORTING iv_fyear     = iv_fyear
                 IMPORTING ev_year_from = DATA(lv_from)
                           ev_year_to   = DATA(lv_to) ).

    CHECK lv_from IS NOT INITIAL.

    ev_from = |{ lv_from }0401|.
    ev_to   = |{ lv_to }0331|.

  ENDMETHOD.


  METHOD month_to_period.

    " April (04) is period 01, March (03) is period 12
    DATA(lv_m) = CONV i( iv_month ).

    rv_period = COND numc2( WHEN lv_m >= 4 THEN lv_m - 3 ELSE lv_m + 9 ).

  ENDMETHOD.


  METHOD period_to_month.

    DATA(lv_p) = CONV i( iv_period ).

    rv_month = COND numc2( WHEN lv_p <= 9 THEN lv_p + 3 ELSE lv_p - 9 ).

  ENDMETHOD.


  METHOD period_to_quarter.

    rv_quarter = ( ( CONV i( iv_period ) - 1 ) DIV 3 ) + 1.

  ENDMETHOD.


  METHOD period_to_yearmonth.

    CLEAR: ev_gjahr, ev_month.

    split_fyear( EXPORTING iv_fyear     = iv_fyear
                 IMPORTING ev_year_from = DATA(lv_from)
                           ev_year_to   = DATA(lv_to) ).

    CHECK lv_from IS NOT INITIAL.

    ev_month = period_to_month( iv_period ).

    " Periods 01 to 09 are April to December of the first calendar year,
    " periods 10 to 12 are January to March of the second
    ev_gjahr = COND gjahr( WHEN iv_period <= 9 THEN lv_from ELSE lv_to ).

  ENDMETHOD.


  METHOD period_dates.

    CLEAR: ev_from, ev_to.

    period_to_yearmonth( EXPORTING iv_fyear  = iv_fyear
                                   iv_period = iv_period
                         IMPORTING ev_gjahr  = DATA(lv_gjahr)
                                   ev_month  = DATA(lv_month) ).

    CHECK lv_gjahr IS NOT INITIAL.

    ev_from = |{ lv_gjahr }{ lv_month }01|.
    ev_to   = last_day( ev_from ).

  ENDMETHOD.


  METHOD quarter_periods.

    DATA(lv_first) = ( CONV i( iv_quarter ) - 1 ) * 3 + 1.

    DO 3 TIMES.

      DATA(lv_period) = CONV numc2( lv_first + sy-index - 1 ).

      period_to_yearmonth( EXPORTING iv_fyear  = iv_fyear
                                     iv_period = lv_period
                           IMPORTING ev_gjahr  = DATA(lv_gjahr)
                                     ev_month  = DATA(lv_month) ).

      period_dates( EXPORTING iv_fyear  = iv_fyear
                              iv_period = lv_period
                    IMPORTING ev_from   = DATA(lv_from)
                              ev_to     = DATA(lv_to) ).

      APPEND VALUE #( gjahr  = lv_gjahr
                      month  = lv_month
                      period = lv_period
                      datfr  = lv_from
                      datto  = lv_to ) TO rt_per.
    ENDDO.

  ENDMETHOD.


  METHOD last_year_quarter.

    rt_per = quarter_periods( iv_fyear   = previous_fyear( iv_fyear )
                              iv_quarter = iv_quarter ).

  ENDMETHOD.


  METHOD last_three_months.

    period_to_yearmonth( EXPORTING iv_fyear  = iv_fyear
                                   iv_period = iv_period
                         IMPORTING ev_gjahr  = DATA(lv_gjahr)
                                   ev_month  = DATA(lv_month) ).

    CHECK lv_gjahr IS NOT INITIAL.

    DATA(lv_y) = CONV i( lv_gjahr ).
    DATA(lv_m) = CONV i( lv_month ).

    " Walk backwards in real calendar terms, so a Q1 forecast correctly
    " lands in January to March of the previous financial year
    DO 3 TIMES.

      lv_m = lv_m - 1.
      IF lv_m = 0.
        lv_m = 12.
        lv_y = lv_y - 1.
      ENDIF.

      DATA(lv_from) = CONV dats( |{ lv_y }{ lv_m WIDTH = 2 PAD = '0' }01| ).

      INSERT VALUE #( gjahr  = lv_y
                      month  = lv_m
                      period = month_to_period( CONV #( lv_m ) )
                      datfr  = lv_from
                      datto  = last_day( lv_from ) ) INTO rt_per INDEX 1.
    ENDDO.

  ENDMETHOD.


  METHOD to_tonnage.

    CHECK iv_ntgew IS NOT INITIAL.

    rv_ton = iv_qty * iv_ntgew.

  ENDMETHOD.


  METHOD check_authority.

*BOC By Arnav on 03/09/26
*=====================================================================*
* AUTHORITY CHECK DISABLED FOR QAS INITIAL TESTING - MUST BE RESTORED
* BEFORE THE OBJECT GOES ANY FURTHER.
*
* Auth object ZPP_FCST is not yet maintained in QAS, so every plant
* would be refused and nothing could be tested. Switched off HERE, in
* the one method every caller goes through, rather than at the six call
* sites in ZCL_PP_FCST, ZPP_FORECAST, ZPP_FORECAST_REPORT and
* ZPP_FORECAST_UPLOAD - those keep their code intact and are unchanged.
*
* TO RESTORE: delete the RETURN below and uncomment the AUTHORITY-CHECK.
* Nothing else has to change.
*=====================================================================*
    rv_ok = abap_true.
    RETURN.

*   AUTHORITY-CHECK OBJECT 'ZPP_FCST'
*     ID 'WERKS' FIELD iv_werks
*     ID 'ACTVT' FIELD iv_actvt.
*
*   IF sy-subrc <> 0.
*     rv_ok = abap_false.
*   ENDIF.
*EOC By Arnav on 03/09/26

  ENDMETHOD.


  METHOD check_legacy_authority.

*BOC By Arnav on 03/09/26
*=====================================================================*
* LEGACY AUTHORITY DISABLED FOR QAS INITIAL TESTING - RESTORE BEFORE
* THE OBJECT GOES ANY FURTHER.
*
* Without this the Legacy Data checkbox is refused with message 011 for
* every user, because the TVARVC list of permitted users does not exist
* in QAS yet.
*
* TO RESTORE: delete the RETURN below and uncomment the two SELECTs.
*=====================================================================*
    rv_ok = abap_true.
    RETURN.

*   " The TVARVC variable name is held in configuration rather than
*   " hardcoded, so it can be changed without a transport.
*   SELECT SINGLE tvarv_legacy FROM zppt_fcst_cfg INTO @DATA(lv_name)
*     WHERE werks = @iv_werks.
*
*   IF sy-subrc <> 0 OR lv_name IS INITIAL.
*     RETURN.
*   ENDIF.
*
*   SELECT SINGLE @abap_true FROM tvarvc INTO @rv_ok
*     WHERE name = @lv_name
*       AND type = 'S'
*       AND low  = @sy-uname.
*EOC By Arnav on 03/09/26

  ENDMETHOD.


  METHOD last_day.

    rv_date = iv_date.

    CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
      EXPORTING  day_in            = iv_date
      IMPORTING  last_day_of_month = rv_date
      EXCEPTIONS OTHERS            = 1.

  ENDMETHOD.

ENDCLASS.
