CLASS zcl_pp_fcst_pnt DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

*"* ZFORECAST (Paints) - the Paints columns on top of the Adhesive engine
*"* Astral / UDAY, built to Forecast_Template-Paints_1.xlsx received 19.10.2026
*"* (Sheet1 is the authority; the mode sheets fill in what it abbreviates).
*"* Author Arnav Johri, 19.10.2026. 22.10.2026: sales organisation 4000
*"* hardcoded as the FS states, material groups re-read with it, save into
*"* the Paints tables.
*"*
*"* ZCL_PP_FCST generates and saves exactly as it does for Adhesive and is
*"* NOT changed. This class adds, for display only, after the engine has run:
*"*
*"*   NAME1        T001W-NAME1 of the row's plant
*"*   BRAND        ZPPT_BRAND by plant and material, blank when not maintained
*"*   MVGR1..5     MVKE of sales organisation 4000 (FS row 91), with the
*"*                descriptions from TVM1T..TVM5T - overwrites what the engine
*"*                read with its own sales organisation
*"*   QTY_CARTON   MVKE-AUMNG of sales organisation 4000 where MVGR1 is filled
*"*   PACK_SIZE    MARM-UMREN / UMREZ of the material's volume or weight unit
*"*                (L, ML, KG, G in that order of preference), ML and G divided
*"*                by 1000, so the figure is litres or kilograms per piece
*"*   BRGEW        MARA-BRGEW, the gross weight per piece
*"*   PRICE (DPL)  A923 latest DATAB -> KONP-KBETR, read here for the ANNUAL
*"*                mode only; quarterly and monthly rows already carry it from
*"*                the engine's READ_PRICES
*"*   Mnn_TON      quantity x gross weight / 1000 - overwrites the engine's
*"*                net-weight tonnage, for Paints only
*"*   Mnn_KL       quantity x pack size / 1000
*"*   Mnn_CR       DPL x quantity / 1,00,00,000
*"*
*"* The quantity is the month's FINAL (forecast plus additional) in quarterly,
*"* the month's total (final plus additional plus MSL) in monthly, and the
*"* month's forecast in annual - the same quantity the engine prices.
*"*
*"* SAVE_PAINTS writes the saved rows, shaped as the list, into
*"* ZPPT_PNT_FCST_YR / _QT / _MN after the engine has written the shared tables.

  PUBLIC SECTION.

    CONSTANTS gc_msgid TYPE symsgid VALUE 'ZPP_FCST'.

*   The Paints sales organisation. FS (RADIO BUTTON 1 ANNUAL, row 91):
*   "VKORG=4000" - hardcoded as the FS states, Arnav's call of 22/10/26.
*   Used for the material groups and the quantity per carton. No
*   ZPPT_FCST_CFG row is needed for a Paints plant.
    CONSTANTS gc_vkorg TYPE vkorg VALUE '4000'.

    TYPES: ty_kl TYPE p LENGTH 13 DECIMALS 3,
           ty_cr TYPE p LENGTH 13 DECIMALS 4.

*   The engine's row with the Paints columns appended. CORRESPONDING maps
*   the engine's output in and the rows back out for SAVE.
    TYPES: BEGIN OF ty_alv.
             INCLUDE TYPE zcl_pp_fcst=>ty_alv.
    TYPES:   name1      TYPE name1,
             brand      TYPE zde_brand,
             pack_size  TYPE ty_kl,
             pack_unit  TYPE meinh,
             qty_carton TYPE ty_kl,
             brgew      TYPE brgew,
             "--- annual, one per forecast month ----------------------
             m01_kl     TYPE ty_kl,
             m02_kl     TYPE ty_kl,
             m03_kl     TYPE ty_kl,
             m04_kl     TYPE ty_kl,
             m05_kl     TYPE ty_kl,
             m06_kl     TYPE ty_kl,
             m07_kl     TYPE ty_kl,
             m08_kl     TYPE ty_kl,
             m09_kl     TYPE ty_kl,
             m10_kl     TYPE ty_kl,
             m11_kl     TYPE ty_kl,
             m12_kl     TYPE ty_kl,
             m01_cr     TYPE ty_cr,
             m02_cr     TYPE ty_cr,
             m03_cr     TYPE ty_cr,
             m04_cr     TYPE ty_cr,
             m05_cr     TYPE ty_cr,
             m06_cr     TYPE ty_cr,
             m07_cr     TYPE ty_cr,
             m08_cr     TYPE ty_cr,
             m09_cr     TYPE ty_cr,
             m10_cr     TYPE ty_cr,
             m11_cr     TYPE ty_cr,
             m12_cr     TYPE ty_cr,
             "--- quarterly (three months) and monthly (M4 only) -------
             m4_kl      TYPE ty_kl,
             m5_kl      TYPE ty_kl,
             m6_kl      TYPE ty_kl,
             m4_cr      TYPE ty_cr,
             m5_cr      TYPE ty_cr,
             m6_cr      TYPE ty_cr,
           END OF ty_alv,
           tt_alv TYPE STANDARD TABLE OF ty_alv WITH DEFAULT KEY.

    "! Fill the Paints columns of every row. IV_MODE is ZCL_PP_FCST=>GC_MODE.
    "! CT_MSG is kept for the caller's run log; nothing is written to it
    "! since the sales organisation became a constant (22/10/26).
    METHODS enrich
      IMPORTING iv_mode TYPE char1
      CHANGING  ct_alv  TYPE tt_alv
                ct_msg  TYPE bapiret2_t.

    "! Write the rows carrying MARK = X and a forecast number into the Paints
    "! tables ZPPT_PNT_FCST_YR / _QT / _MN - the list, column for column.
    "! Called by ZPP_FORECAST_PAINTS right after ZCL_PP_FCST=>SAVE, which has
    "! already drawn the number and written the shared tables that the engine,
    "! the uploads and the final report read. MARK is cleared on every row
    "! processed; a row the database refuses gets LIGHT 1 and a message.
    "! Commits its own work.
    METHODS save_paints
      IMPORTING iv_mode TYPE char1
      CHANGING  ct_alv  TYPE tt_alv
                ct_msg  TYPE bapiret2_t.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_plant,
             werks TYPE werks_d,
           END OF ty_plant,
           tt_plant TYPE STANDARD TABLE OF ty_plant WITH DEFAULT KEY,

           BEGIN OF ty_mat,
             matnr TYPE matnr,
           END OF ty_mat,
           tt_mat TYPE STANDARD TABLE OF ty_mat WITH DEFAULT KEY,

           BEGIN OF ty_key,
             werks TYPE werks_d,
             matnr TYPE matnr,
           END OF ty_key,
           tt_key TYPE STANDARD TABLE OF ty_key WITH DEFAULT KEY,

           BEGIN OF ty_name,
             werks TYPE werks_d,
             name1 TYPE name1,
           END OF ty_name,
           tt_name TYPE STANDARD TABLE OF ty_name WITH DEFAULT KEY,

           BEGIN OF ty_brand,
             werks TYPE werks_d,
             matnr TYPE matnr,
             brand TYPE zde_brand,
           END OF ty_brand,
           tt_brand TYPE STANDARD TABLE OF ty_brand WITH DEFAULT KEY,

           BEGIN OF ty_mara,
             matnr TYPE matnr,
             meins TYPE meins,
             brgew TYPE brgew,
             gewei TYPE gewei,
           END OF ty_mara,
           tt_mara TYPE STANDARD TABLE OF ty_mara WITH DEFAULT KEY,

           BEGIN OF ty_pack,
             matnr TYPE matnr,
             meinh TYPE meinh,
             pack  TYPE ty_kl,
           END OF ty_pack,
           tt_pack TYPE STANDARD TABLE OF ty_pack WITH DEFAULT KEY,

           BEGIN OF ty_marm,
             matnr TYPE matnr,
             meinh TYPE meinh,
             umrez TYPE umrez,
             umren TYPE umren,
           END OF ty_marm,
           tt_marm TYPE STANDARD TABLE OF ty_marm WITH DEFAULT KEY,

*          The sales view of sales organisation 4000: material groups and
*          the quantity per carton in one read
           BEGIN OF ty_mvke,
             matnr TYPE matnr,
             mvgr1 TYPE mvgr1,
             mvgr2 TYPE mvgr2,
             mvgr3 TYPE mvgr3,
             mvgr4 TYPE mvgr4,
             mvgr5 TYPE mvgr5,
             aumng TYPE aumng,
           END OF ty_mvke,
           tt_mvke TYPE STANDARD TABLE OF ty_mvke WITH DEFAULT KEY,

*          Material group descriptions, group number 1..5 and code
           BEGIN OF ty_grptxt,
             nr    TYPE i,
             code  TYPE mvgr1,
             bezei TYPE bezei20,
           END OF ty_grptxt,
           tt_grptxt TYPE STANDARD TABLE OF ty_grptxt WITH DEFAULT KEY,

           BEGIN OF ty_price,
             matnr TYPE matnr,
             kbetr TYPE kbetr,
           END OF ty_price,
           tt_price TYPE STANDARD TABLE OF ty_price WITH DEFAULT KEY,

           BEGIN OF ty_unit,
             meinh TYPE meinh,
             div   TYPE i,
           END OF ty_unit,
           tt_unit TYPE STANDARD TABLE OF ty_unit WITH DEFAULT KEY.

    METHODS read_names
      IMPORTING it_plant       TYPE tt_plant
      RETURNING VALUE(rt_name) TYPE tt_name.

    METHODS read_brands
      IMPORTING it_key          TYPE tt_key
      RETURNING VALUE(rt_brand) TYPE tt_brand.

    METHODS read_mara
      IMPORTING it_mat         TYPE tt_mat
      RETURNING VALUE(rt_mara) TYPE tt_mara.

    "! Pack size per material from MARM - see the note on the method
    METHODS read_pack_sizes
      IMPORTING it_mat         TYPE tt_mat
                it_mara        TYPE tt_mara
      RETURNING VALUE(rt_pack) TYPE tt_pack.

    "! MVKE of sales organisation 4000: material groups 1..5 and AUMNG
    METHODS read_sales_view
      IMPORTING it_mat         TYPE tt_mat
      RETURNING VALUE(rt_mvke) TYPE tt_mvke.

    "! TVM1T..TVM5T in the logon language - small customising tables,
    "! read whole
    METHODS read_group_texts
      RETURNING VALUE(rt_txt) TYPE tt_grptxt.

    "! A923 latest DATAB -> KONP-KBETR, the same rule as ZCL_PP_FCST=>READ_PRICES.
    "! Re-implemented here because that method is private and the Adhesive
    "! class is not to be changed.
    METHODS read_prices
      IMPORTING it_mat          TYPE tt_mat
      RETURNING VALUE(rt_price) TYPE tt_price.

ENDCLASS.



CLASS zcl_pp_fcst_pnt IMPLEMENTATION.


  METHOD enrich.

    DATA: lt_plant TYPE tt_plant,
          lt_mat   TYPE tt_mat,
          lt_key   TYPE tt_key,
          ls_plant TYPE ty_plant,
          ls_mat   TYPE ty_mat,
          ls_key   TYPE ty_key,
          ls_txt   TYPE ty_grptxt,
          lv_qty   TYPE zde_fcst_qty,
          lv_p     TYPE numc2,
          lv_m     TYPE i,
          lv_div   TYPE ty_kl VALUE 1000,
          lv_crore TYPE ty_cr VALUE 10000000.

    FIELD-SYMBOLS: <ls>    TYPE ty_alv,
                   <lv_q>  TYPE any,
                   <lv_t>  TYPE any,
                   <lv_kl> TYPE any,
                   <lv_cr> TYPE any.

    CHECK ct_alv IS NOT INITIAL.

*   ---- what the run touches ------------------------------------------
    LOOP AT ct_alv ASSIGNING <ls>.
      ls_plant-werks = <ls>-werks.
      APPEND ls_plant TO lt_plant.
      ls_mat-matnr = <ls>-matnr.
      APPEND ls_mat TO lt_mat.
      ls_key-werks = <ls>-werks.
      ls_key-matnr = <ls>-matnr.
      APPEND ls_key TO lt_key.
    ENDLOOP.

    SORT lt_plant BY werks.
    DELETE ADJACENT DUPLICATES FROM lt_plant COMPARING werks.
    SORT lt_mat BY matnr.
    DELETE ADJACENT DUPLICATES FROM lt_mat COMPARING matnr.
    SORT lt_key BY werks matnr.
    DELETE ADJACENT DUPLICATES FROM lt_key COMPARING werks matnr.

*   ---- one read each, never inside the row loop ----------------------
    DATA(lt_name)  = read_names( lt_plant ).
    DATA(lt_brand) = read_brands( lt_key ).
    DATA(lt_mara)  = read_mara( lt_mat ).
    DATA(lt_pack)  = read_pack_sizes( it_mat  = lt_mat
                                      it_mara = lt_mara ).
    DATA(lt_mvke)  = read_sales_view( lt_mat ).
    DATA(lt_txt)   = read_group_texts( ).

    DATA(lt_price) = VALUE tt_price( ).
    IF iv_mode = zcl_pp_fcst=>gc_mode-annual.
      lt_price = read_prices( lt_mat ).
    ENDIF.

    SORT: lt_name  BY werks,
          lt_brand BY werks matnr,
          lt_mara  BY matnr,
          lt_pack  BY matnr,
          lt_mvke  BY matnr,
          lt_txt   BY nr code,
          lt_price BY matnr.

*   ---- row by row ----------------------------------------------------
    LOOP AT ct_alv ASSIGNING <ls>.

      READ TABLE lt_name INTO DATA(ls_name)
        WITH KEY werks = <ls>-werks BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-name1 = ls_name-name1.
      ENDIF.

      READ TABLE lt_brand INTO DATA(ls_brand)
        WITH KEY werks = <ls>-werks matnr = <ls>-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-brand = ls_brand-brand.
      ENDIF.

      READ TABLE lt_mara INTO DATA(ls_mara)
        WITH KEY matnr = <ls>-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-brgew = ls_mara-brgew.
      ENDIF.

      READ TABLE lt_pack INTO DATA(ls_pack)
        WITH KEY matnr = <ls>-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-pack_size = ls_pack-pack.
        <ls>-pack_unit = ls_pack-meinh.
      ENDIF.

*     Material groups and quantity per carton from sales organisation
*     4000. The engine read MVKE with its own sales organisation; for
*     Paints the FS names 4000, so the groups are replaced here.
      CLEAR: <ls>-mvgr1, <ls>-mvgr2, <ls>-mvgr3, <ls>-mvgr4, <ls>-mvgr5,
             <ls>-mvgr1_txt, <ls>-mvgr2_txt, <ls>-mvgr3_txt,
             <ls>-mvgr4_txt, <ls>-mvgr5_txt.

      READ TABLE lt_mvke INTO DATA(ls_mvke)
        WITH KEY matnr = <ls>-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-mvgr1 = ls_mvke-mvgr1.
        <ls>-mvgr2 = ls_mvke-mvgr2.
        <ls>-mvgr3 = ls_mvke-mvgr3.
        <ls>-mvgr4 = ls_mvke-mvgr4.
        <ls>-mvgr5 = ls_mvke-mvgr5.
*       FS row 91: AUMNG where MVGR1 is not blank
        IF ls_mvke-mvgr1 IS NOT INITIAL.
          <ls>-qty_carton = ls_mvke-aumng.
        ENDIF.

        READ TABLE lt_txt INTO ls_txt
          WITH KEY nr = 1 code = ls_mvke-mvgr1 BINARY SEARCH.
        IF sy-subrc = 0.
          <ls>-mvgr1_txt = ls_txt-bezei.
        ENDIF.
        READ TABLE lt_txt INTO ls_txt
          WITH KEY nr = 2 code = ls_mvke-mvgr2 BINARY SEARCH.
        IF sy-subrc = 0.
          <ls>-mvgr2_txt = ls_txt-bezei.
        ENDIF.
        READ TABLE lt_txt INTO ls_txt
          WITH KEY nr = 3 code = ls_mvke-mvgr3 BINARY SEARCH.
        IF sy-subrc = 0.
          <ls>-mvgr3_txt = ls_txt-bezei.
        ENDIF.
        READ TABLE lt_txt INTO ls_txt
          WITH KEY nr = 4 code = ls_mvke-mvgr4 BINARY SEARCH.
        IF sy-subrc = 0.
          <ls>-mvgr4_txt = ls_txt-bezei.
        ENDIF.
        READ TABLE lt_txt INTO ls_txt
          WITH KEY nr = 5 code = ls_mvke-mvgr5 BINARY SEARCH.
        IF sy-subrc = 0.
          <ls>-mvgr5_txt = ls_txt-bezei.
        ENDIF.
      ENDIF.

      IF iv_mode = zcl_pp_fcst=>gc_mode-annual.
        READ TABLE lt_price INTO DATA(ls_price)
          WITH KEY matnr = <ls>-matnr BINARY SEARCH.
        IF sy-subrc = 0.
          <ls>-price = ls_price-kbetr.
        ENDIF.
      ENDIF.

*     ---- tonnage, KL and crores per forecast month --------------------
      CASE iv_mode.

        WHEN zcl_pp_fcst=>gc_mode-annual.

*         M01_FCST .. M12_FCST, the month's forecast quantity. LV_P is
*         NUMC2 so the name keeps its leading zero (M01, not M1).
          DO 12 TIMES.
            lv_p = sy-index.
            UNASSIGN: <lv_q>, <lv_t>, <lv_kl>, <lv_cr>.
            ASSIGN COMPONENT |M{ lv_p }_FCST| OF STRUCTURE <ls> TO <lv_q>.
            ASSIGN COMPONENT |M{ lv_p }_TON|  OF STRUCTURE <ls> TO <lv_t>.
            ASSIGN COMPONENT |M{ lv_p }_KL|   OF STRUCTURE <ls> TO <lv_kl>.
            ASSIGN COMPONENT |M{ lv_p }_CR|   OF STRUCTURE <ls> TO <lv_cr>.
            CHECK <lv_q> IS ASSIGNED.
            lv_qty = <lv_q>.
            IF <lv_t> IS ASSIGNED.
              <lv_t>  = lv_qty * <ls>-brgew / lv_div.
            ENDIF.
            IF <lv_kl> IS ASSIGNED.
              <lv_kl> = lv_qty * <ls>-pack_size / lv_div.
            ENDIF.
            IF <lv_cr> IS ASSIGNED.
              <lv_cr> = <ls>-price * lv_qty / lv_crore.
            ENDIF.
          ENDDO.

        WHEN zcl_pp_fcst=>gc_mode-quarterly.

*         M4_FCST_FINAL .. M6_FCST_FINAL, the month's forecast plus its
*         additional plan quantity - the figure the engine prices. LV_M is
*         I, not NUMC, so the name is M4 and not M04.
          DO 3 TIMES.
            lv_m = sy-index + 3.
            UNASSIGN: <lv_q>, <lv_t>, <lv_kl>, <lv_cr>.
            ASSIGN COMPONENT |M{ lv_m }_FCST_FINAL| OF STRUCTURE <ls> TO <lv_q>.
            ASSIGN COMPONENT |M{ lv_m }_TON|        OF STRUCTURE <ls> TO <lv_t>.
            ASSIGN COMPONENT |M{ lv_m }_KL|         OF STRUCTURE <ls> TO <lv_kl>.
            ASSIGN COMPONENT |M{ lv_m }_CR|         OF STRUCTURE <ls> TO <lv_cr>.
            CHECK <lv_q> IS ASSIGNED.
            lv_qty = <lv_q>.
            IF <lv_t> IS ASSIGNED.
              <lv_t>  = lv_qty * <ls>-brgew / lv_div.
            ENDIF.
            IF <lv_kl> IS ASSIGNED.
              <lv_kl> = lv_qty * <ls>-pack_size / lv_div.
            ENDIF.
            IF <lv_cr> IS ASSIGNED.
              <lv_cr> = <ls>-price * lv_qty / lv_crore.
            ENDIF.
          ENDDO.

        WHEN zcl_pp_fcst=>gc_mode-monthly.

*         TOTAL_QTY - final plus additional plus MSL, the figure the
*         engine prices in M4_VAL. One month, drawn in the M4 columns.
          lv_qty      = <ls>-total_qty.
          <ls>-m4_ton = lv_qty * <ls>-brgew / lv_div.
          <ls>-m4_kl  = lv_qty * <ls>-pack_size / lv_div.
          <ls>-m4_cr  = <ls>-price * lv_qty / lv_crore.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.


  METHOD save_paints.

    DATA: lv_saved TYPE i,
          lv_fail  TYPE i,
          lv_rc    TYPE sy-subrc,
          ls_yr    TYPE zppt_pnt_fcst_yr,
          ls_qt    TYPE zppt_pnt_fcst_qt,
          ls_mn    TYPE zppt_pnt_fcst_mn,
          ls_msg   TYPE bapiret2.

    FIELD-SYMBOLS <ls> TYPE ty_alv.

    LOOP AT ct_alv ASSIGNING <ls> WHERE mark = abap_true.

      CLEAR <ls>-mark.
      CHECK <ls>-fcst_no IS NOT INITIAL.

      lv_rc = 4.

      CASE iv_mode.

        WHEN zcl_pp_fcst=>gc_mode-annual.
          CLEAR ls_yr.
          ls_yr = CORRESPONDING zppt_pnt_fcst_yr( <ls> ).
*         Created-by and created-on of an existing row are kept; only
*         changed-by and changed-on move
          SELECT SINGLE ernam, erdat FROM zppt_pnt_fcst_yr
            INTO ( @ls_yr-ernam, @ls_yr-erdat )
            WHERE werks = @<ls>-werks
              AND matnr = @<ls>-matnr
              AND fyear = @<ls>-fyear.
          IF ls_yr-ernam IS INITIAL.
            ls_yr-ernam = sy-uname.
            ls_yr-erdat = sy-datum.
          ENDIF.
          ls_yr-aenam = sy-uname.
          ls_yr-aedat = sy-datum.
          MODIFY zppt_pnt_fcst_yr FROM @ls_yr.
          lv_rc = sy-subrc.

        WHEN zcl_pp_fcst=>gc_mode-quarterly.
          CLEAR ls_qt.
          ls_qt = CORRESPONDING zppt_pnt_fcst_qt( <ls> ).
          SELECT SINGLE ernam, erdat FROM zppt_pnt_fcst_qt
            INTO ( @ls_qt-ernam, @ls_qt-erdat )
            WHERE werks   = @<ls>-werks
              AND matnr   = @<ls>-matnr
              AND gjahr   = @<ls>-gjahr
              AND quarter = @<ls>-quarter.
          IF ls_qt-ernam IS INITIAL.
            ls_qt-ernam = sy-uname.
            ls_qt-erdat = sy-datum.
          ENDIF.
          ls_qt-aenam = sy-uname.
          ls_qt-aedat = sy-datum.
          MODIFY zppt_pnt_fcst_qt FROM @ls_qt.
          lv_rc = sy-subrc.

        WHEN zcl_pp_fcst=>gc_mode-monthly.
          CLEAR ls_mn.
          ls_mn = CORRESPONDING zppt_pnt_fcst_mn( <ls> ).
          SELECT SINGLE ernam, erdat FROM zppt_pnt_fcst_mn
            INTO ( @ls_mn-ernam, @ls_mn-erdat )
            WHERE werks  = @<ls>-werks
              AND matnr  = @<ls>-matnr
              AND gjahr  = @<ls>-gjahr
              AND period = @<ls>-period.
          IF ls_mn-ernam IS INITIAL.
            ls_mn-ernam = sy-uname.
            ls_mn-erdat = sy-datum.
          ENDIF.
          ls_mn-aenam = sy-uname.
          ls_mn-aedat = sy-datum.
          MODIFY zppt_pnt_fcst_mn FROM @ls_mn.
          lv_rc = sy-subrc.

      ENDCASE.

      IF lv_rc = 0.
        lv_saved = lv_saved + 1.
      ELSE.
        lv_fail = lv_fail + 1.
        <ls>-light   = '1'.
        <ls>-message = |Saved under forecast { <ls>-fcst_no }, Paints table not updated|.
      ENDIF.

    ENDLOOP.

    IF lv_saved > 0.
      COMMIT WORK AND WAIT.
    ENDIF.

    IF lv_fail > 0.
      CLEAR ls_msg.
      ls_msg-type    = 'E'.
      ls_msg-id      = gc_msgid.
      ls_msg-message = |{ lv_fail } row(s) not written to the Paints forecast table|.
      APPEND ls_msg TO ct_msg.
    ENDIF.

  ENDMETHOD.


  METHOD read_names.

    CLEAR rt_name.
    CHECK it_plant IS NOT INITIAL.

    SELECT werks, name1
      FROM t001w
      FOR ALL ENTRIES IN @it_plant
      WHERE werks = @it_plant-werks
      INTO TABLE @rt_name.

  ENDMETHOD.


  METHOD read_brands.

    CLEAR rt_brand.
    CHECK it_key IS NOT INITIAL.

    SELECT werks, matnr, brand
      FROM zppt_brand
      FOR ALL ENTRIES IN @it_key
      WHERE werks = @it_key-werks
        AND matnr = @it_key-matnr
      INTO TABLE @rt_brand.

  ENDMETHOD.


  METHOD read_mara.

    CLEAR rt_mara.
    CHECK it_mat IS NOT INITIAL.

    SELECT matnr, meins, brgew, gewei
      FROM mara
      FOR ALL ENTRIES IN @it_mat
      WHERE matnr = @it_mat-matnr
      INTO TABLE @rt_mara.

  ENDMETHOD.


*  ---------------------------------------------------------------------
*  Pack size
*
*  FS (RADIO BUTTON 1 ANNUAL, row 88): "Pass ALV MATNR to MARM-MATNR where
*  MEINH is not equal to ALV UOM and take MARM-UMREN. If the MEINH is
*  equal to ML or GM, then divide the value with 1000."
*
*  ASSUMPTION (query M5, unanswered): a material usually has several
*  alternative units (carton, litre, kilogram), and the FS does not say
*  which one. The volume or weight unit is taken, in this order of
*  preference: L, ML, KG, G. ML and G are divided by 1000 so the figure is
*  litres or kilograms per piece. The base unit itself is never used.
*
*  ASSUMPTION: the unit codes are the internal MSEHI values L, ML, KG and
*  G (gram is G in standard SAP; the FS writes GM). Check T006 and change
*  the four entries in LT_UNITS below if the system differs.
*
*  Pack size = UMREN / UMREZ. For 1 piece = 4 L the material carries
*  UMREZ 1, UMREN 4 against unit L, so this is UMREN exactly as the FS
*  says whenever UMREZ is 1, and still right when it is not.
*  ---------------------------------------------------------------------
  METHOD read_pack_sizes.

    DATA: lt_marm  TYPE tt_marm,
          lt_units TYPE tt_unit,
          ls_unit  TYPE ty_unit,
          ls_pack  TYPE ty_pack,
          lr_unit  TYPE RANGE OF meinh,
          ls_r     LIKE LINE OF lr_unit,
          lv_pack  TYPE ty_kl.

    CLEAR rt_pack.
    CHECK it_mat IS NOT INITIAL.

*   Preference order and divisor. Structured rows - fine on this release.
    ls_unit-meinh = 'L'.  ls_unit-div = 1.    APPEND ls_unit TO lt_units.
    ls_unit-meinh = 'ML'. ls_unit-div = 1000. APPEND ls_unit TO lt_units.
    ls_unit-meinh = 'KG'. ls_unit-div = 1.    APPEND ls_unit TO lt_units.
    ls_unit-meinh = 'G'.  ls_unit-div = 1000. APPEND ls_unit TO lt_units.

    ls_r-sign   = 'I'.
    ls_r-option = 'EQ'.
    LOOP AT lt_units INTO ls_unit.
      ls_r-low = ls_unit-meinh.
      APPEND ls_r TO lr_unit.
    ENDLOOP.

    SELECT matnr, meinh, umrez, umren
      FROM marm
      FOR ALL ENTRIES IN @it_mat
      WHERE matnr = @it_mat-matnr
        AND meinh IN @lr_unit
      INTO TABLE @lt_marm.

    CHECK lt_marm IS NOT INITIAL.
    SORT lt_marm BY matnr meinh.

    LOOP AT it_mat INTO DATA(ls_mat).

      READ TABLE it_mara INTO DATA(ls_mara)
        WITH KEY matnr = ls_mat-matnr.
      IF sy-subrc <> 0.
        CLEAR ls_mara.
      ENDIF.

*     First unit of the preference list the material carries, and
*     which is not its base unit
      LOOP AT lt_units INTO ls_unit.

        CHECK ls_unit-meinh <> ls_mara-meins.

        READ TABLE lt_marm INTO DATA(ls_marm)
          WITH KEY matnr = ls_mat-matnr meinh = ls_unit-meinh BINARY SEARCH.
        CHECK sy-subrc = 0.
        CHECK ls_marm-umrez > 0 AND ls_marm-umren > 0.

        lv_pack = ls_marm-umren / ls_marm-umrez.
        lv_pack = lv_pack / ls_unit-div.

        CLEAR ls_pack.
        ls_pack-matnr = ls_mat-matnr.
        ls_pack-meinh = ls_unit-meinh.
        ls_pack-pack  = lv_pack.
        APPEND ls_pack TO rt_pack.
        EXIT.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


*  ---------------------------------------------------------------------
*  The sales view of sales organisation 4000
*
*  FS row 91: "Pass VBRP-MATNR to MVKE-MATNR for MVGR1 is not equal to
*  blank and VKORG=4000 and take AUMNG." FS quarter sheet rows 30-34:
*  the material groups 1 to 5 from MVKE and their descriptions from
*  TVM1T to TVM5T. Both from the same row, read once per material.
*  AUMNG is "minimum order quantity" in the dictionary - query Q2.
*  ---------------------------------------------------------------------
  METHOD read_sales_view.

    CLEAR rt_mvke.
    CHECK it_mat IS NOT INITIAL.

    SELECT matnr, mvgr1, mvgr2, mvgr3, mvgr4, mvgr5, aumng
      FROM mvke
      FOR ALL ENTRIES IN @it_mat
      WHERE matnr = @it_mat-matnr
        AND vkorg = @gc_vkorg
      INTO TABLE @rt_mvke.

*   One row per material. Several distribution channels under the same
*   sales organisation would give several rows; the first is taken.
    SORT rt_mvke BY matnr.
    DELETE ADJACENT DUPLICATES FROM rt_mvke COMPARING matnr.

  ENDMETHOD.


  METHOD read_group_texts.

    DATA ls_txt TYPE ty_grptxt.

    CLEAR rt_txt.

    SELECT mvgr1, bezei FROM tvm1t
      WHERE spras = @sy-langu
      INTO TABLE @DATA(lt_t1).
    LOOP AT lt_t1 INTO DATA(ls_t1).
      ls_txt-nr    = 1.
      ls_txt-code  = ls_t1-mvgr1.
      ls_txt-bezei = ls_t1-bezei.
      APPEND ls_txt TO rt_txt.
    ENDLOOP.

    SELECT mvgr2, bezei FROM tvm2t
      WHERE spras = @sy-langu
      INTO TABLE @DATA(lt_t2).
    LOOP AT lt_t2 INTO DATA(ls_t2).
      ls_txt-nr    = 2.
      ls_txt-code  = ls_t2-mvgr2.
      ls_txt-bezei = ls_t2-bezei.
      APPEND ls_txt TO rt_txt.
    ENDLOOP.

    SELECT mvgr3, bezei FROM tvm3t
      WHERE spras = @sy-langu
      INTO TABLE @DATA(lt_t3).
    LOOP AT lt_t3 INTO DATA(ls_t3).
      ls_txt-nr    = 3.
      ls_txt-code  = ls_t3-mvgr3.
      ls_txt-bezei = ls_t3-bezei.
      APPEND ls_txt TO rt_txt.
    ENDLOOP.

    SELECT mvgr4, bezei FROM tvm4t
      WHERE spras = @sy-langu
      INTO TABLE @DATA(lt_t4).
    LOOP AT lt_t4 INTO DATA(ls_t4).
      ls_txt-nr    = 4.
      ls_txt-code  = ls_t4-mvgr4.
      ls_txt-bezei = ls_t4-bezei.
      APPEND ls_txt TO rt_txt.
    ENDLOOP.

    SELECT mvgr5, bezei FROM tvm5t
      WHERE spras = @sy-langu
      INTO TABLE @DATA(lt_t5).
    LOOP AT lt_t5 INTO DATA(ls_t5).
      ls_txt-nr    = 5.
      ls_txt-code  = ls_t5-mvgr5.
      ls_txt-bezei = ls_t5-bezei.
      APPEND ls_txt TO rt_txt.
    ENDLOOP.

    SORT rt_txt BY nr code.

  ENDMETHOD.


*  ---------------------------------------------------------------------
*  DPL - the dealer price
*
*  FS row 90: "Pass material to A923-MATNR and take KNUMH by doing a
*  descending on DATAB. Pass KNUMH to KONP-KNUMH and take KBETR."
*
*  The same rule, line for line, as ZCL_PP_FCST=>READ_PRICES (15/09/26):
*  the record with the latest DATAB, its lowest KOPOS line. Read on the
*  material alone - no condition type, sales organisation, valid-to,
*  KPEIN or KONWA - exactly as worded, and flagged there as well.
*  ASSUMPTION (query Q1): A923 holds the Paints dealer price list.
*  ---------------------------------------------------------------------
  METHOD read_prices.

    DATA ls_price TYPE ty_price.

    CLEAR rt_price.
    CHECK it_mat IS NOT INITIAL.

    SELECT matnr, datab, knumh
      FROM a923
      FOR ALL ENTRIES IN @it_mat
      WHERE matnr = @it_mat-matnr
      INTO TABLE @DATA(lt_a923).

    CHECK lt_a923 IS NOT INITIAL.

    SORT lt_a923 BY matnr datab DESCENDING knumh DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_a923 COMPARING matnr.

    SELECT knumh, kopos, kbetr
      FROM konp
      FOR ALL ENTRIES IN @lt_a923
      WHERE knumh = @lt_a923-knumh
      INTO TABLE @DATA(lt_konp).

    CHECK lt_konp IS NOT INITIAL.

    SORT lt_konp BY knumh kopos.
    DELETE ADJACENT DUPLICATES FROM lt_konp COMPARING knumh.

    LOOP AT lt_a923 INTO DATA(ls_a923).
      READ TABLE lt_konp INTO DATA(ls_konp)
        WITH KEY knumh = ls_a923-knumh BINARY SEARCH.
      IF sy-subrc = 0.
        CLEAR ls_price.
        ls_price-matnr = ls_a923-matnr.
        ls_price-kbetr = ls_konp-kbetr.
        APPEND ls_price TO rt_price.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
