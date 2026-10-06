CLASS zcl_zpra_daily_prod_dpc_ext DEFINITION
  PUBLIC
  INHERITING FROM zcl_zpra_daily_prod_dpc
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      tt_prd TYPE STANDARD TABLE OF zpra_t_dly_prd WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_map,
        field   TYPE string,
        product TYPE zpra_t_dly_prd-product,
        vltype  TYPE zpra_t_dly_prd-prd_vl_type,
      END OF ty_map .
    TYPES:
      tt_map TYPE STANDARD TABLE OF ty_map WITH DEFAULT KEY .

    METHODS /iwbep/if_mgw_core_srv_runtime~changeset_begin
        REDEFINITION .
    METHODS /iwbep/if_mgw_core_srv_runtime~changeset_end
        REDEFINITION .
    METHODS /iwbep/if_mgw_core_srv_runtime~changeset_process
        REDEFINITION .

  PROTECTED SECTION.

    METHODS dailyproductions_create_entity
        REDEFINITION .
    METHODS dailyproductions_get_entityset
        REDEFINITION .

  PRIVATE SECTION.

*--- batch state: set in CHANGESET_BEGIN, consumed in CHANGESET_END
    DATA mv_in_changeset TYPE abap_bool .
    DATA mv_op_no        TYPE i .
    DATA mv_err_recs     TYPE i .
    DATA mt_prd_buffer   TYPE tt_prd .
    DATA mt_error        TYPE string_table .

    METHODS get_prod_uom
      IMPORTING
        !iv_asset     TYPE string
        !iv_product   TYPE zpra_pro
        !iv_vltype    TYPE zvl_type_cd
      RETURNING
        VALUE(rv_uom) TYPE string .

    METHODS build_prod_rows
      IMPORTING
        is_item   TYPE zcl_zpra_daily_prod_mpc_ext=>ts_dailyproduction
        iv_ts     TYPE zpra_t_dly_prd-timestamp
        iv_row_no TYPE i
      EXPORTING
        et_prd    TYPE tt_prd
        et_error  TYPE string_table .

    METHODS apply_change_info
      CHANGING
        ct_prd TYPE tt_prd .

    METHODS raise_error
      IMPORTING
        it_message TYPE string_table
      RAISING
        /iwbep/cx_mgw_busi_exception .

ENDCLASS.



CLASS ZCL_ZPRA_DAILY_PROD_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_core_srv_runtime~changeset_begin.

*--------------------------------------------------------------------*
* Start of a $batch changeset.
*
* cv_defer_mode = abap_false -> every operation is still dispatched to
* DAILYPRODUCTIONS_CREATE_ENTITY, but that method only VALIDATES and
* BUFFERS. CHANGESET_END then writes every record that passed and
* reports every record that did not, in one consolidated message.
*--------------------------------------------------------------------*
    CLEAR: mt_prd_buffer, mt_error, mv_op_no, mv_err_recs.
    mv_in_changeset = abap_true.

    cv_defer_mode = abap_false.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_core_srv_runtime~changeset_process.

*--------------------------------------------------------------------*
* Not used. With cv_defer_mode = abap_false the framework never calls
* this method - all operations go through DAILYPRODUCTIONS_CREATE_ENTITY.
* Redefined with an empty body so the default implementation (which
* rejects changesets with more than one operation) can never fire.
*--------------------------------------------------------------------*
    RETURN.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_core_srv_runtime~changeset_end.

    DATA: lt_msg  TYPE string_table,
          lv_msg  TYPE string,
          lv_rows TYPE i,
          lv_ok   TYPE i.

    mv_in_changeset = abap_false.

*--------------------------------------------------------------------*
* 1. Write every record that PASSED validation.
*
*    The COMMIT deliberately happens BEFORE the error is raised below:
*    once the LUW is committed, the exception cannot undo it, so the
*    good rows survive while the changeset still reports a failure.
*--------------------------------------------------------------------*
    IF mt_prd_buffer IS NOT INITIAL.

*--- de-duplicate inside the batch (sorted first, also avoids deadlocks)
      SORT mt_prd_buffer BY production_date asset block product prd_vl_type.
      DELETE ADJACENT DUPLICATES FROM mt_prd_buffer
        COMPARING production_date asset block product prd_vl_type.

*--- existing rows -> update, keeping their original creation data
      apply_change_info( CHANGING ct_prd = mt_prd_buffer ).

      lv_rows = lines( mt_prd_buffer ).

      MODIFY zpra_t_dly_prd FROM TABLE mt_prd_buffer.
      IF sy-subrc <> 0.
        ROLLBACK WORK.
        lv_msg = |Update of ZPRA_T_DLY_PRD failed ({ lv_rows } rows)|.
        APPEND lv_msg TO lt_msg.
        APPEND LINES OF mt_error TO lt_msg.
        CLEAR: mt_prd_buffer, mt_error, mv_op_no, mv_err_recs.
        raise_error( lt_msg ).
      ENDIF.

      COMMIT WORK AND WAIT.

    ENDIF.

*--------------------------------------------------------------------*
* 2. Good rows are committed. Now report every REJECTED record in one
*    consolidated message, so the batch is never signalled as clean.
*--------------------------------------------------------------------*
    IF mt_error IS NOT INITIAL.

      lv_ok  = mv_op_no - mv_err_recs.
      lv_msg = |{ lv_ok } of { mv_op_no } record(s) posted | &&
               |({ lv_rows } rows), { mv_err_recs } rejected:|.
      APPEND lv_msg TO lt_msg.
      APPEND LINES OF mt_error TO lt_msg.

      CLEAR: mt_prd_buffer, mt_error, mv_op_no, mv_err_recs.
      raise_error( lt_msg ).

    ENDIF.

    CLEAR: mt_prd_buffer, mt_error, mv_op_no, mv_err_recs.

  ENDMETHOD.


  METHOD dailyproductions_create_entity.

    DATA: ls_data TYPE zcl_zpra_daily_prod_mpc_ext=>ts_dailyproduction,
          lt_prd  TYPE tt_prd,
          lt_err  TYPE string_table,
          lv_ts   TYPE zpra_t_dly_prd-timestamp.

*--- operation counter, used to identify the record in error texts
    IF mv_in_changeset = abap_true.
      mv_op_no = mv_op_no + 1.
    ELSE.
      mv_op_no = 1.
    ENDIF.

*--------------------------------------------------------------------*
* Read payload
*--------------------------------------------------------------------*
    IF io_data_provider IS BOUND.
      io_data_provider->read_entry_data( IMPORTING es_data = ls_data ).
    ENDIF.

    IF ls_data IS INITIAL.
      APPEND |Row { mv_op_no }: no data received in POST request| TO lt_err.
      IF mv_in_changeset = abap_true.
        mv_err_recs = mv_err_recs + 1.
        APPEND LINES OF lt_err TO mt_error.
        RETURN.
      ENDIF.
      raise_error( lt_err ).
    ENDIF.

    GET TIME STAMP FIELD lv_ts.

    build_prod_rows( EXPORTING is_item   = ls_data
                               iv_ts     = lv_ts
                               iv_row_no = mv_op_no
                     IMPORTING et_prd    = lt_prd
                               et_error  = lt_err ).

*--------------------------------------------------------------------*
* Bad record
*--------------------------------------------------------------------*
    IF lt_err IS NOT INITIAL.

      IF mv_in_changeset = abap_true.
*       Collect and keep going, so the caller gets EVERY bad record in
*       one response instead of only the first. This record contributes
*       NO rows to the buffer, so it is simply never written; the good
*       records still are.
        mv_err_recs = mv_err_recs + 1.
        APPEND LINES OF lt_err TO mt_error.
        er_entity = ls_data.
        RETURN.
      ENDIF.

      raise_error( lt_err ).

    ENDIF.

*--------------------------------------------------------------------*
* Inside a $batch changeset -> buffer only, CHANGESET_END writes
*--------------------------------------------------------------------*
    IF mv_in_changeset = abap_true.
      APPEND LINES OF lt_prd TO mt_prd_buffer.
      er_entity = ls_data.
      RETURN.
    ENDIF.

*--------------------------------------------------------------------*
* Single (non-batch) POST -> write and commit here
*--------------------------------------------------------------------*
    IF lt_prd IS NOT INITIAL.

      apply_change_info( CHANGING ct_prd = lt_prd ).

      MODIFY zpra_t_dly_prd FROM TABLE lt_prd.
      IF sy-subrc <> 0.
        ROLLBACK WORK.
        CLEAR lt_err.
        APPEND |Update of ZPRA_T_DLY_PRD failed| TO lt_err.
        raise_error( lt_err ).
      ENDIF.

      COMMIT WORK AND WAIT.

    ENDIF.

    er_entity = ls_data.

  ENDMETHOD.


  METHOD dailyproductions_get_entityset.

*--------------------------------------------------------------------*
* Not implemented - this is an inbound-only interface.
* A GET on DailyProductionSet returns an empty collection.
*--------------------------------------------------------------------*
    RETURN.

  ENDMETHOD.


  METHOD apply_change_info.

*--------------------------------------------------------------------*
* Upsert bookkeeping.
*
* MODIFY replaces the whole row, so without this a re-sent record would
* overwrite CREATED_BY / CREATED_ON with today's values. Rows that
* already exist keep their original creation data and get CHANGED_BY /
* CHANGED_ON instead; genuinely new rows keep CREATED_* only.
*--------------------------------------------------------------------*
    DATA: lt_exist TYPE tt_prd,
          ls_exist TYPE zpra_t_dly_prd.

    IF ct_prd IS INITIAL.
      RETURN.
    ENDIF.

    SELECT * FROM zpra_t_dly_prd INTO TABLE lt_exist
      FOR ALL ENTRIES IN ct_prd
      WHERE production_date = ct_prd-production_date
        AND asset           = ct_prd-asset
        AND block           = ct_prd-block
        AND product         = ct_prd-product
        AND prd_vl_type     = ct_prd-prd_vl_type.

    LOOP AT ct_prd ASSIGNING FIELD-SYMBOL(<ls_prd>).

      READ TABLE lt_exist INTO ls_exist
        WITH KEY production_date = <ls_prd>-production_date
                 asset           = <ls_prd>-asset
                 block           = <ls_prd>-block
                 product         = <ls_prd>-product
                 prd_vl_type     = <ls_prd>-prd_vl_type.

      IF sy-subrc = 0.
*       existing row -> update
        <ls_prd>-created_by = ls_exist-created_by.
        <ls_prd>-created_on = ls_exist-created_on.
        <ls_prd>-changed_by = sy-uname.
        <ls_prd>-changed_on = sy-datum.
      ELSE.
*       new row -> no change data
        CLEAR: <ls_prd>-changed_by, <ls_prd>-changed_on.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_prod_rows.

    DATA: ls_prd  TYPE zpra_t_dly_prd,
          lv_key  TYPE string,
          lv_c10  TYPE c LENGTH 10,
          lv_date TYPE dats,
          lv_val  TYPE string.

    CLEAR: et_prd, et_error.

    lv_key = |{ is_item-reporting_date }/{ is_item-asset }/{ is_item-block }|.

    DATA(lt_map) = VALUE tt_map(
      ( field = 'NET_PROD'   product = '722000001' vltype = 'NET_PROD'   )
      ( field = 'WATER_INJ'  product = '722000001' vltype = 'WATER_INJ'  )
      ( field = 'GAS_INJ'    product = '722000004' vltype = 'GAS_INJ'    )
      ( field = 'GROSS_PROD' product = '722000004' vltype = 'GROSS_PROD' )
      ( field = 'GAS_FLARE'  product = '722000004' vltype = 'GAS_FLARE'  )
      ( field = 'INT_CONS'   product = '722000004' vltype = 'INT_CONS'   ) ).

*--- mandatory fields
    IF is_item-reporting_date IS INITIAL OR
       is_item-asset          IS INITIAL OR
       is_item-block          IS INITIAL.
      APPEND |Row { iv_row_no }: REPORTING_DATE, ASSET and BLOCK are mandatory| TO et_error.
      RETURN.
    ENDIF.

*--- DD.MM.YYYY -> YYYYMMDD
    lv_c10 = is_item-reporting_date.
    CONDENSE lv_c10 NO-GAPS.
    IF lv_c10 CA '.'.
      lv_date = lv_c10+6(4) && lv_c10+3(2) && lv_c10+0(2).
    ELSE.
      lv_date = lv_c10.
    ENDIF.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING  date                      = lv_date
      EXCEPTIONS plausibility_check_failed = 1
                 OTHERS                    = 2.
    IF sy-subrc <> 0.
      APPEND |Row { iv_row_no } ({ lv_key }): invalid REPORTING_DATE '{ is_item-reporting_date }'| TO et_error.
      RETURN.
    ENDIF.

*--- common fields
    ls_prd-production_date = lv_date.
    ls_prd-asset           = is_item-asset.
    ls_prd-block           = is_item-block.
    ls_prd-comments        = is_item-comment.
    ls_prd-created_by      = sy-uname.
    ls_prd-created_on      = sy-datum.
    ls_prd-timestamp       = iv_ts.

*--- fan out the six measures
    LOOP AT lt_map INTO DATA(ls_map).

      ASSIGN COMPONENT ls_map-field OF STRUCTURE is_item TO FIELD-SYMBOL(<lv_raw>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_val = <lv_raw>.
      REPLACE ALL OCCURRENCES OF ',' IN lv_val WITH ''.
      CONDENSE lv_val NO-GAPS.

      IF lv_val IS INITIAL OR lv_val = '0'.
        CONTINUE.
      ENDIF.

      ls_prd-product     = ls_map-product.
      ls_prd-prd_vl_type = ls_map-vltype.

      TRY.
          ls_prd-prod_vl_qty1 = lv_val.
        CATCH cx_sy_conversion_error.
          APPEND |Row { iv_row_no } ({ lv_key }): { ls_map-field } has non-numeric value '{ <lv_raw> }'| TO et_error.
          CONTINUE.
      ENDTRY.

      ls_prd-prod_vl_uom1 = get_prod_uom( iv_asset   = is_item-asset
                                          iv_product = ls_prd-product
                                          iv_vltype  = ls_prd-prd_vl_type ).

      APPEND ls_prd TO et_prd.

    ENDLOOP.

  ENDMETHOD.


  METHOD raise_error.

*--------------------------------------------------------------------*
* iv_msg_text of ADD_MESSAGE_TEXT_ONLY is BAPI_MSG (CHAR220), not
* STRING - the conversion has to happen here.
*--------------------------------------------------------------------*
    DATA: lv_msg TYPE bapi_msg.

    DATA(lo_mc) = mo_context->get_message_container( ).

    LOOP AT it_message INTO DATA(lv_text).
      lv_msg = lv_text.
      lo_mc->add_message_text_only( iv_msg_type = 'E'
                                    iv_msg_text = lv_msg ).
    ENDLOOP.

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING message_container = lo_mc.

  ENDMETHOD.


  METHOD get_prod_uom.

    CLEAR rv_uom.

    CASE iv_asset.

      WHEN 'AZE_ACG' OR 'VEN_CAR' OR 'VEN_SAN'.
        CASE iv_product.
          WHEN '722000001'. rv_uom = 'BBL'.
          WHEN '722000004'. rv_uom = 'MCF'.
        ENDCASE.

      WHEN 'BRA_BC1' OR 'BRA_BC2'.
        CASE iv_product.
          WHEN '722000001'. rv_uom = 'BBL'.
          WHEN '722000004'. rv_uom = 'MCM'.
        ENDCASE.

      WHEN 'COL_CPO'.
        CASE iv_product.
          WHEN '722000001'. rv_uom = 'BBL'.
          WHEN '722000004'. rv_uom = 'M3'.
        ENDCASE.

      WHEN 'COL_MEC'.
        IF iv_product = '722000001'.
          rv_uom = 'BBL'.
        ENDIF.

      WHEN 'MMR_BA1' OR 'MMR_BA3'.
        IF iv_product = '722000004'.
          rv_uom = 'MCF'.
        ENDIF.

      WHEN 'RUS_IEC' OR 'RUS_SK1'.
        CASE iv_product.
          WHEN '722000001'. rv_uom = 'BBL'.
          WHEN '722000004'. rv_uom = 'M3'.
        ENDCASE.

      WHEN 'RUS_VAN'.
        CASE iv_product.
          WHEN '722000001'.
            CASE iv_vltype.
              WHEN 'NET_PROD'.   rv_uom = 'BBL'.
              WHEN 'WATER_INJ'.  rv_uom = 'M3'.
            ENDCASE.
          WHEN '722000004'.
            rv_uom = 'M3'.
        ENDCASE.

      WHEN 'SSU_GPO' OR 'SSU_SPO' OR 'SUD_GNP' OR 'UAE_LZC'.
        IF iv_product = '722000001'.
          rv_uom = 'BBL'.
        ENDIF.

      WHEN 'VNM_B06'.
        CASE iv_product.
          WHEN '722000003'. rv_uom = 'BBL'.
          WHEN '722000004'. rv_uom = 'MCM'.
          WHEN 'WATER'.     rv_uom = 'BBL'.
        ENDCASE.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
