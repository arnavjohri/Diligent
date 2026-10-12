CLASS zcl_inv_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      gtt_data_db    TYPE TABLE OF zinv_post_cust .
    TYPES:
      gtt_data_db_gl    TYPE TABLE OF zinv_post_gl .

    DATA gs_doc_header TYPE bapiache09 .
    DATA gt_acc_payable TYPE bapiacap09_tab .
    DATA gt_gl_account TYPE bapiacgl09_tab .
    DATA gt_acc_tax TYPE bapiactx09_tab .
    DATA gt_curr_amt TYPE bapiaccr09_tab .
    DATA:
      gt_vend_act TYPE TABLE OF bapiacap09 .
    DATA:
      gt_acc_rec  TYPE STANDARD TABLE OF bapiacar09 .
    DATA:
*       DATA: gt_curr_amt TYPE TABLE OF bapiaccr09.
      gt_acct_wt  TYPE TABLE OF bapiacwt09 .
    DATA:
      gt_custcpd     TYPE STANDARD TABLE OF bapiacpa09 .
    DATA:
      gt_criteria    TYPE STANDARD TABLE OF bapiackec9 .
    DATA gs_custcpd TYPE bapiacpa09 .

    METHODS process_invoice_data
      IMPORTING
        !it_account_gl         TYPE bapiacgl09_tab
        !it_account_receivable TYPE bapiacar09_tab OPTIONAL
        !it_account_payable    TYPE bapiacap09_tab OPTIONAL
        !it_account_tax        TYPE bapiactx09_tab OPTIONAL
        !it_currency_amount    TYPE bapiaccr09_tab
        !it_criteria           TYPE bapiackec9_tab OPTIONAL
        !it_valuefield         TYPE bapiackev9_tab OPTIONAL
        !it_extension1         TYPE bapiacextc_tab OPTIONAL
        !it_paymentcard        TYPE bapiacpc09_tab OPTIONAL
        !is_documentheader     TYPE bapiache09
        !is_customercpd        TYPE bapiacpa09 OPTIONAL
        !is_contractheader     TYPE bapiaccahd OPTIONAL
      EXPORTING
        !et_message            TYPE ztt_inv_log
        !et_out                TYPE p04p_bapiache09_tt
        !et_return             TYPE bapiret2_tab .
*        !ct_log             TYPE zinv_cl_bp_post_user=>gtt_gr_error optional.
    METHODS get_record_status
      IMPORTING
        !it_data         TYPE gtt_data_db OPTIONAL
        !iv_status       TYPE char40 OPTIONAL
        !it_data_gl      TYPE gtt_data_db_gl OPTIONAL
      RETURNING
        VALUE(rv_status) TYPE char40 .
    METHODS transform_inv_data
      CHANGING
        !ct_data TYPE zinv_cl_bp_post_user=>gtt_gr_xl .
    METHODS validate_excel_header_sup
      IMPORTING
        !it_excel_data TYPE zinv_cl_bp_post_user=>gtt_gr_xl
      EXPORTING
        !ev_has_error  TYPE boole_d .
    METHODS convert_itab_to_xstring
      IMPORTING
        !ir_data          TYPE REF TO data
      RETURNING
        VALUE(rv_xstring) TYPE zde_rawstring .
    METHODS validate_inv_data_copy
      IMPORTING
        !iv_stage              TYPE char15 OPTIONAL
        !iv_existing_status    TYPE char40 OPTIONAL
      EXPORTING
        !es_documentheader     TYPE bapiache09
        !es_customercpd        TYPE bapiacpa09
        !es_contractheader     TYPE bapiaccahd
        !ev_errorcount         TYPE int4
        !ev_status             TYPE char1
        !et_account_gl         TYPE bapiacgl09_tab
        !et_account_receivable TYPE bapiacar09_tab
        !et_account_payable    TYPE bapiacap09_tab
        !et_account_tax        TYPE bapiactx09_tab
        !et_currency_amount    TYPE bapiaccr09_tab
        !et_criteria           TYPE bapiackec9_tab
        !et_valuefield         TYPE bapiackev9_tab
        !et_extension1         TYPE bapiacextc_tab
        !et_extension2         TYPE bapiparex_tab
        !et_paymentcard        TYPE bapiacpc09_tab
        !et_accountwt          TYPE bapiacwt09_tab
      CHANGING
        !ct_log                TYPE zinv_cl_bp_post_user=>gtt_gr_error OPTIONAL
        !ct_data               TYPE ztt_inv_input_sup OPTIONAL .
    METHODS transform_inv_data_gl
      CHANGING
        !ct_data TYPE zinv_cl_bp_gl_user=>gtt_gr_xl_gl .
    METHODS validate_inv_data_gl
      IMPORTING
        !iv_stage              TYPE char15
        !iv_existing_status    TYPE char40 OPTIONAL
      EXPORTING
        !es_documentheader     TYPE bapiache09
        !es_contractheader     TYPE bapiaccahd
        !ev_errorcount         TYPE int4
        !et_account_gl         TYPE bapiacgl09_tab
        !et_account_receivable TYPE bapiacar09_tab
        !et_account_tax        TYPE bapiactx09_tab
        !et_currency_amount    TYPE bapiaccr09_tab
        !ev_status             TYPE char1
        !et_criteria           TYPE bapiackec9_tab
        !et_valuefield         TYPE bapiackev9_tab
        !et_extension1         TYPE bapiacextc_tab
        !et_extension2         TYPE bapiparex_tab
        !et_paymentcard        TYPE bapiacpc09_tab
      CHANGING
        !ct_log                TYPE zinv_cl_bp_post_user=>gtt_gr_error
        !ct_data               TYPE ztt_inv_inp_gl .
    METHODS validate_inv_data_ar
      IMPORTING
        !iv_stage              TYPE char15 OPTIONAL
        !iv_existing_status    TYPE char40 OPTIONAL
      EXPORTING
        !es_documentheader     TYPE bapiache09
        !es_customercpd        TYPE bapiacpa09
        !es_contractheader     TYPE bapiaccahd
        !ev_errorcount         TYPE int4
        !ev_status             TYPE char1
        !et_account_gl         TYPE bapiacgl09_tab
        !et_account_receivable TYPE bapiacar09_tab
        !et_account_payable    TYPE bapiacap09_tab
        !et_account_tax        TYPE bapiactx09_tab
        !et_currency_amount    TYPE bapiaccr09_tab
        !et_criteria           TYPE bapiackec9_tab
        !et_valuefield         TYPE bapiackev9_tab
        !et_extension1         TYPE bapiacextc_tab
        !et_extension2         TYPE bapiparex_tab
        !et_paymentcard        TYPE bapiacpc09_tab
        !et_accountwt          TYPE bapiacwt09_tab
      CHANGING
        !ct_log                TYPE zinv_cl_bp_post_user=>gtt_gr_error OPTIONAL
        !ct_data               TYPE zstt_inv_inp_ar OPTIONAL .
    METHODS transform_inv_data_ar
      CHANGING
        !ct_data TYPE zinv_cl_bp_ar_user=>gtt_gr_xl .
    METHODS validate_inv_data_ap
      IMPORTING
        !iv_stage           TYPE char15 OPTIONAL
        !iv_existing_status TYPE char40 OPTIONAL
      EXPORTING
        !es_documentheader  TYPE bapiache09
        !es_customercpd     TYPE bapiacpa09
        !es_contractheader  TYPE bapiaccahd
        !ev_errorcount      TYPE int4
        !ev_status          TYPE char1
        !et_account_gl      TYPE bapiacgl09_tab
        !et_account_payable TYPE bapiacap09_tab
        !et_account_tax     TYPE bapiactx09_tab
        !et_currency_amount TYPE bapiaccr09_tab
        !et_criteria        TYPE bapiackec9_tab
        !et_valuefield      TYPE bapiackev9_tab
        !et_extension1      TYPE bapiacextc_tab
        !et_extension2      TYPE bapiparex_tab
        !et_paymentcard     TYPE bapiacpc09_tab
        !et_accountwt       TYPE bapiacwt09_tab
      CHANGING
        !ct_log             TYPE zinv_cl_bp_post_user=>gtt_gr_error OPTIONAL
        !ct_data            TYPE ztt_inv_input_sup OPTIONAL .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_INV_UTILITY IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->GET_RECORD_STATUS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_DATA                        TYPE        GTT_DATA_DB(optional)
* | [--->] IV_STATUS                      TYPE        CHAR40(optional)
* | [--->] IT_DATA_GL                     TYPE        GTT_DATA_DB_GL(optional)
* | [<-()] RV_STATUS                      TYPE        CHAR40
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_record_status.
*        READ TABLE it_Data INTO DATA(ls_Data)." WITH KEY stage = zinv_cl_bp_post_user=>gc_process_stage. " 'PROCESSING'.
*    IF sy-subrc = 0.
** Processing has started
*    ELSE.
*    IF iv_module_id = 'AP'.
    LOOP AT it_data INTO DATA(ls_data) WHERE status IS NOT INITIAL AND status <> 'S'.
    ENDLOOP.
    IF sy-subrc = 0.
      rv_status = zinv_cl_bp_post_user=>gc_vali_err ."'Validation Error'.
    ELSE.
      READ TABLE it_data TRANSPORTING NO FIELDS WITH KEY status = ''.
      IF sy-subrc = 0.
        READ TABLE it_data TRANSPORTING NO FIELDS WITH KEY status = 'S'.
        IF sy-subrc = 0.
          rv_status = 'Validation Partially Success'.
        ENDIF.
      ELSE.
        rv_status = zinv_cl_bp_post_user=>gc_vali_suc. " 'Validation Success'.
      ENDIF.
    ENDIF.
*    ELSEIF iv_module_id = 'GL'.


*    ENDIF.
    IF rv_status IS INITIAL.
      rv_status = iv_status.
    ENDIF.
*    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->PROCESS_INVOICE_DATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_ACCOUNT_GL                  TYPE        BAPIACGL09_TAB
* | [--->] IT_ACCOUNT_RECEIVABLE          TYPE        BAPIACAR09_TAB(optional)
* | [--->] IT_ACCOUNT_PAYABLE             TYPE        BAPIACAP09_TAB(optional)
* | [--->] IT_ACCOUNT_TAX                 TYPE        BAPIACTX09_TAB(optional)
* | [--->] IT_CURRENCY_AMOUNT             TYPE        BAPIACCR09_TAB
* | [--->] IT_CRITERIA                    TYPE        BAPIACKEC9_TAB(optional)
* | [--->] IT_VALUEFIELD                  TYPE        BAPIACKEV9_TAB(optional)
* | [--->] IT_EXTENSION1                  TYPE        BAPIACEXTC_TAB(optional)
* | [--->] IT_PAYMENTCARD                 TYPE        BAPIACPC09_TAB(optional)
* | [--->] IS_DOCUMENTHEADER              TYPE        BAPIACHE09
* | [--->] IS_CUSTOMERCPD                 TYPE        BAPIACPA09(optional)
* | [--->] IS_CONTRACTHEADER              TYPE        BAPIACCAHD(optional)
* | [<---] ET_MESSAGE                     TYPE        ZTT_INV_LOG
* | [<---] ET_OUT                         TYPE        P04P_BAPIACHE09_TT
* | [<---] ET_RETURN                      TYPE        BAPIRET2_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD process_invoice_data.
    DATA:
      ls_out    TYPE bapiache09-obj_key,
      lt_return TYPE bapiret2_tab.
*    DATA:
*      lv_item    TYPE posnr_acc,
*      lo_msg     TYPE REF TO /iwbep/if_message_container,
*      lv_message TYPE string,
*      ls_message TYPE zinv_cl_bp_post_user=>gty_gr_error,
*      lt_message TYPE zinv_cl_bp_post_user=>gtt_gr_error.

*    IF ct_data IS NOT INITIAL.
*      SELECT lifnr,
*         bukrs,
*         akont
*    FROM lfb1
*    INTO TABLE @DATA(lt_lfb1)
*     FOR ALL ENTRIES IN @ct_data
*     WHERE lifnr EQ @ct_data-invoicing_party
*     AND bukrs EQ @ct_data-comp_code.
*    ENDIF.
*    IF sy-subrc EQ 0.
*      SELECT ktopl,
*             koart,
*             umskz,
*             hkont,
*             skont
*        FROM t074
*        INTO TABLE @DATA(lt_t074)
*         FOR ALL ENTRIES IN @lt_lfb1
*       WHERE ktopl EQ 'PHOP'
*         AND koart EQ 'K'
*         AND ( umskz NE 'A'
*         AND   umskz NE 'F' )
*         AND hkont EQ @lt_lfb1-akont.
*    ENDIF.
*    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<fs_data>).
*      CLEAR lv_inv_type.
*
**      CASE <fs_pyodocs>-zstatus.
**        WHEN '0009'. "For Accounting Processing
*
*
*      ls_doc_header-doc_status = '2'.   "Parked
*      ls_doc_header-bus_act    = 'RFBU'.
*      ls_doc_header-username   = sy-uname.
*      ls_doc_header-doc_date   = <fs_data>-document_date.
*      ls_doc_header-pstng_date = <fs_data>-posting_date.
*      ls_doc_header-fisc_year  = <fs_data>-posting_date+0(4).
**         data(lv_pos_date) = |{ <fs_data>-posting_date+6(4) }{ <fs_data>-posting_date+3(2) }{ <fs_data>-posting_date+0(2) }|.
**            ls_doc_header-trans_dat = <fs_pyodocs>-ztran_date.
*      ls_doc_header-comp_code  = <fs_data>-comp_code.
**            ls_doc_header-ref_doc_no = <fs_data>-r(16).
*      ls_doc_header-header_txt =  <fs_data>-docu_hdr_text+16(9).
*      ls_doc_header-doc_type   = <fs_data>-document_type.
*
*      ADD 1 TO lv_item.
*      APPEND INITIAL LINE TO lt_acc_payable ASSIGNING FIELD-SYMBOL(<fs_accpay>).
*      <fs_accpay>-itemno_acc = |{ lv_item ALPHA = IN }|.
*      <fs_accpay>-vendor_no  = <fs_data>-invoicing_party.
*      <fs_accpay>-item_text  = <fs_data>-item_text.
*      <fs_accpay>-pmnttrms   = <fs_data>-terms_payment.
*      <fs_accpay>-bline_date = <fs_data>-baseline_date.
*      <fs_accpay>-alloc_nmbr = <fs_data>-assign_number.
*      <fs_accpay>-profit_ctr = <fs_data>-profit_cent.
*      <fs_accpay>-pymt_meth  = <fs_data>-payment_method.
*
*
*
*      "Currency Amount for Vendor
*      APPEND INITIAL LINE TO lt_curr_amt ASSIGNING FIELD-SYMBOL(ls_curr_amt).
*      ls_curr_amt-itemno_acc = |{ lv_item ALPHA = IN }|.
*      ls_curr_amt-currency   = <fs_data>-currency.
*      ls_curr_amt-curr_type  = '00'.
*      ls_curr_amt-amt_doccur = <fs_data>-gross_inv_amount.
*
*      IF ls_doc_header-doc_type EQ 'KR'
*      OR ls_doc_header-doc_type EQ 'KG'.
*        MULTIPLY ls_curr_amt-amt_doccur BY -1.
*      ENDIF.
*      "One Time Vendor
*      IF <fs_data>-name IS NOT INITIAL.
**              ls_custcpd-title      = <fs_data>-.
*        ls_custcpd-name       = <fs_data>-name.
*        ls_custcpd-city       = <fs_data>-city.
*        ls_custcpd-country    = <fs_data>-country.
*        ls_custcpd-bank_no    = <fs_data>-bank_key.
*        ls_custcpd-bank_ctry  = <fs_data>-bank_reg.
*        ls_custcpd-bank_acct  = <fs_data>-bank_acc.
*        ls_custcpd-bank_ref   = <fs_data>-bank_ref.
*      ENDIF.
*      ADD 1 TO lv_item.
*      APPEND INITIAL LINE TO lt_gl_account ASSIGNING FIELD-SYMBOL(<fs_accgl>).
*      <fs_accgl>-itemno_acc = |{ lv_item ALPHA = IN }|.
*      <fs_accgl>-gl_account = <fs_data>-gl_account.
*      <fs_accgl>-costcenter = <fs_data>-cost_center.
*      <fs_accgl>-profit_ctr = <fs_data>-profit_cent.
*      <fs_accgl>-item_text  = <fs_data>-gl_itm_txt.
*      <fs_accgl>-alloc_nmbr = <fs_data>-gl_assignment.
*      <fs_accgl>-fisc_year  = <fs_data>-posting_date+0(4).
*
*      lt_criteria = VALUE #( BASE lt_criteria[]
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_origin_mse          fieldname = 'ZZ1_ORIGIN_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_subfleet_mse        fieldname = 'ZZ1_SUBFLEET_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_route_mse           fieldname = 'ZZ1_ROUTE_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_tailnumber_mse      fieldname = 'ZZ1_ROUTE_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_flightdate_mse      fieldname = 'ZZ1_FLIGHTDATE_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_flighttype_mse      fieldname = 'ZZ1_FLIGHTTYPE_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_destination_mse     fieldname = 'ZZ1_DESTINATION_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_bodytype_mse        fieldname = 'ZZ1_BODYTYPE_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_sector_mse          fieldname = 'ZZ1_SECTOR_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_aircrafttype_mse    fieldname = 'ZZ1_AIRCRAFTTYPE_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_flightnumber_mse    fieldname = 'ZZ1_FLIGHTNUMBER_MSE' )
*                              ( itemno_acc = lv_item character = <fs_data>-zz1_flightindicator_mse fieldname = 'ZZ1_FLIGHTINDICATOR_MSE' )
*                              ).
*
*    ENDLOOP.
*    CALL FUNCTION 'BAPI_ACC_DOCUMENT_CHECK'
*      EXPORTING
*        documentheader = ls_doc_header
*      TABLES
*        accountgl      = lt_gl_account
*        accountpayable = lt_acc_payable
*        accounttax     = lt_acc_tax
*        currencyamount = lt_curr_amt
*        criteria       = lt_criteria
*        return         = lt_return.
**        extension2        = li_extension.

    CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
      EXPORTING
        documentheader = is_documentheader
        customercpd    = is_customercpd
      IMPORTING
        obj_key        = ls_out
      TABLES
        accountgl      = it_account_gl
        accountpayable = it_account_payable
        currencyamount = it_currency_amount
*       criteria       = gt_criteria
        return         = et_return.

    READ TABLE et_return INTO DATA(ls_return)
    WITH KEY type = 'E'.
    IF sy-subrc EQ 0.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      APPEND VALUE #(
        status              = 'E'
        message             = 'Invoice not posted due to errors'
        ) TO et_message.
*      LOOP AT lt_return INTO ls_return.
**        lo_msg->add_message(
**          EXPORTING
**            iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-error
**            iv_msg_id                 = ls_return-id
**            iv_msg_number             = ls_return-number
**            iv_msg_v1                 = ls_return-message_v1
**            iv_msg_v2                 = ls_return-message_v2
**            iv_msg_v3                 = ls_return-message_v3
**            iv_msg_v4                 = ls_return-message_v4
**            iv_add_to_response_header = abap_true
**        ).
*
*        CALL FUNCTION 'MESSAGE_TEXT_BUILD'
*          EXPORTING
*            msgid               = ls_return-id
*            msgnr               = ls_return-number
*            msgv1               = ls_return-message_v1
*            msgv2               = ls_return-message_v2
*            msgv3               = ls_return-message_v3
*            msgv4               = ls_return-message_v4
*          IMPORTING
*            message_text_output = lv_message.
*        APPEND VALUE #(
*                      status              = 'E'
*                      invoice_id          = <fs_data>-invoice_id
*                      message             = lv_message
*                      ) TO et_message.
*      ENDLOOP.

    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
      APPEND ls_out TO et_out.
      LOOP AT et_out INTO ls_out.
        APPEND VALUE #(
                    status              = 'S'
                    obj_key             = ls_out
                    message             = 'Invoice Posted Successfully'
                    ) TO et_message.
      ENDLOOP.
    ENDIF.



  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->CONVERT_ITAB_TO_XSTRING
* +-------------------------------------------------------------------------------------------------+
* | [--->] IR_DATA                        TYPE REF TO DATA
* | [<-()] RV_XSTRING                     TYPE        ZDE_RAWSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD convert_itab_to_xstring.
    DATA:
*      lv_length       TYPE i,
*      lv_xml          TYPE xstring,
*      lv_sname        TYPE tabname,

*      lv_file         TYPE string VALUE 'C:/MYDOWNLOAD.DATA.XLSX',
      lt_fieldcatalog TYPE lvc_t_fcat,
*      lt_xml_stream   TYPE xml_rawdata,
      lr_result_data  TYPE REF TO cl_salv_bs_result_data_table.


    DATA: lr_data TYPE REF TO data.

    FIELD-SYMBOLS: <fs_data> TYPE ANY TABLE.

    CLEAR rv_xstring.

    ASSIGN ir_data->* TO <fs_data>.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = DATA(lo_table)
          CHANGING
            t_table      = <fs_data> ).

        DATA(lt_fcat) =
          cl_salv_controller_metadata=>get_lvc_fieldcatalog(
          r_columns      = lo_table->get_columns( )
          r_aggregations = lo_table->get_aggregations( ) ).

*        CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
*          EXPORTING
*            i_structure_name       = 'ZSTR_INV_INPUT'
*            i_bypassing_buffer     = 'X'
*          CHANGING
*            ct_fieldcat            = lt_fieldcatalog
*          EXCEPTIONS
*            inconsistent_interface = 1
*            program_error          = 2
*            OTHERS                 = 3.
        cl_salv_ex_util=>factory_result_data_table(
          EXPORTING
            r_data              = ir_data
            t_fieldcatalog      = lt_fieldcatalog
          RECEIVING
            r_result_data_table = lr_result_data ).

        CALL METHOD cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform
          EXPORTING
            xml_type      = if_salv_bs_xml=>c_type_xlsx
            xml_version   = if_salv_bs_xml=>version_26
            r_result_data = lr_result_data
            xml_flavour   = if_salv_bs_c_tt=>c_tt_xml_flavour_export
            gui_type      = if_salv_bs_xml=>c_gui_type_gui
          IMPORTING
            xml           = rv_xstring.
      CATCH cx_root.
        CLEAR rv_xstring.
    ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->TRANSFORM_INV_DATA
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CT_DATA                        TYPE        ZINV_CL_BP_POST_USER=>GTT_GR_XL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD transform_inv_data.

    DATA: lv_doc_curr TYPE wrbtr.
    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<fs_data>).

      IF <fs_data>-doc_date IS NOT INITIAL.
        <fs_data>-doc_date = |{ <fs_data>-doc_date+6(4) }{ <fs_data>-doc_date+3(2) }{ <fs_data>-doc_date+0(2) }|.
      ENDIF.
      IF <fs_data>-posting_date IS NOT INITIAL.
        <fs_data>-posting_date = |{ <fs_data>-posting_date+6(4) }{ <fs_data>-posting_date+3(2) }{ <fs_data>-posting_date+0(2) }|.
      ENDIF.
      IF <fs_data>-baseline_date IS NOT INITIAL.
        <fs_data>-baseline_date = |{ <fs_data>-baseline_date+6(4) }{ <fs_data>-baseline_date+3(2) }{ <fs_data>-baseline_date+0(2) }|.
      ENDIF.
      IF <fs_data>-gl_amount = '7.0000000000000007E-2'.
        lv_doc_curr = '0.07'.
        <fs_data>-gl_amount = lv_doc_curr.
        CLEAR lv_doc_curr.
      ENDIF.

      IF <fs_data>-gross_inv_amt  = '7.0000000000000007E-2'.
        lv_doc_curr = '0.07'.
        <fs_data>-gross_inv_amt = lv_doc_curr.
        CLEAR lv_doc_curr.
      ENDIF.

      IF <fs_data>-zz1_flightdate_mse IS NOT INITIAL.
        <fs_data>-zz1_flightdate_mse = |{ <fs_data>-zz1_flightdate_mse+6(4) }{ <fs_data>-zz1_flightdate_mse+3(2) }{ <fs_data>-zz1_flightdate_mse+0(2) }|.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->VALIDATE_EXCEL_HEADER_SUP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_EXCEL_DATA                  TYPE        ZINV_CL_BP_POST_USER=>GTT_GR_XL
* | [<---] EV_HAS_ERROR                   TYPE        BOOLE_D
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD validate_excel_header_sup.
    FIELD-SYMBOLS: <lfs_col_header> TYPE string.
    "Validate Header record
*    DATA(ls_excel) = VALUE #( it_excel_data[ 4 ] OPTIONAL ).
    DATA(ls_excel) = VALUE #( it_excel_data[ 4 ] OPTIONAL ).
*    IF ls_excel-module_id = 'AL'.
    IF ls_excel IS NOT INITIAL.
      DATA(lv_index) = sy-index.
      ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
      CHECK <lfs_col_header> IS ASSIGNED.
      DATA(lv_value) =  <lfs_col_header> .
      DATA(lv_has_error) = abap_false.
      CASE lv_index.
        WHEN 1.
          lv_has_error = COND #( WHEN lv_value <> 'Line Number' THEN abap_true ELSE lv_has_error ).
        WHEN 2.
          lv_has_error = COND #( WHEN lv_value <> 'Invoice ID' THEN abap_true ELSE lv_has_error ).
        WHEN 3.
          lv_has_error = COND #( WHEN lv_value <> 'Company Code' THEN abap_true ELSE lv_has_error ).
        WHEN 4.
          lv_has_error = COND #( WHEN lv_value <> 'Posting Key' THEN abap_true ELSE lv_has_error ).
        WHEN 5.
          lv_has_error = COND #( WHEN lv_value <> 'Invoicing Party' THEN abap_true ELSE lv_has_error ).
        WHEN 6.
          lv_has_error = COND #( WHEN lv_value <> 'Reference' THEN abap_true ELSE lv_has_error ).
        WHEN 7.
          lv_has_error = COND #( WHEN lv_value <> 'Document Date' THEN abap_true ELSE lv_has_error ).
        WHEN 8.
          lv_has_error = COND #( WHEN lv_value <> 'Posting Date' THEN abap_true ELSE lv_has_error ).
        WHEN 9.
          lv_has_error = COND #( WHEN lv_value <> 'Document Type' THEN abap_true ELSE lv_has_error ).
        WHEN 10.
          lv_has_error = COND #( WHEN lv_value <> 'Document Header Text' THEN abap_true ELSE lv_has_error ).
        WHEN 11.
          lv_has_error = COND #( WHEN lv_value <> 'Currency' THEN abap_true ELSE lv_has_error ).
        WHEN 12.
          lv_has_error = COND #( WHEN lv_value <> 'Gross Invoice Amount' THEN abap_true ELSE lv_has_error ).
        WHEN 13.
          lv_has_error = COND #( WHEN lv_value <> 'Status' THEN abap_true ELSE lv_has_error ).
        WHEN 14.
          lv_has_error = COND #( WHEN lv_value <> 'Message' THEN abap_true ELSE lv_has_error ).
*          WHEN 9.
*            lv_has_error = COND #( WHEN lv_value <> 'Service Provider' THEN abap_true ELSE lv_has_error ).
*          WHEN 10.
*            lv_has_error = COND #( WHEN lv_value <> 'Service Code' THEN abap_true ELSE lv_has_error ).
*          WHEN 11.
*            lv_has_error = COND #( WHEN lv_value <> 'Quantity' THEN abap_true ELSE lv_has_error ).
*          WHEN 12.
*            lv_has_error = COND #( WHEN lv_value <> 'Unit' THEN abap_true ELSE lv_has_error ).
*          WHEN 13.
*            lv_has_error = COND #( WHEN lv_value <> 'Service Cost' THEN abap_true ELSE lv_has_error ).
*          WHEN 14.
*            lv_has_error = COND #( WHEN lv_value <> 'Currency' THEN abap_true ELSE lv_has_error ).
*          WHEN 15.
*            lv_has_error = COND #( WHEN lv_value <> 'Flight Indicator Info' THEN abap_true ELSE lv_has_error ).
*          WHEN 16.
*            lv_has_error = COND #( WHEN lv_value <> 'Cost Center' THEN abap_true ELSE lv_has_error ).
*          WHEN 17.
*            lv_has_error = COND #( WHEN lv_value <> 'Overwrite' THEN abap_true ELSE lv_has_error ).
**          WHEN 18. "More than 17 columns (error)
**            lv_has_error = abap_true.
      ENDCASE.

      ev_has_error = abap_true.

    ENDIF.
*      ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->VALIDATE_INV_DATA_COPY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_STAGE                       TYPE        CHAR15(optional)
* | [--->] IV_EXISTING_STATUS             TYPE        CHAR40(optional)
* | [<---] ES_DOCUMENTHEADER              TYPE        BAPIACHE09
* | [<---] ES_CUSTOMERCPD                 TYPE        BAPIACPA09
* | [<---] ES_CONTRACTHEADER              TYPE        BAPIACCAHD
* | [<---] EV_ERRORCOUNT                  TYPE        INT4
* | [<---] EV_STATUS                      TYPE        CHAR1
* | [<---] ET_ACCOUNT_GL                  TYPE        BAPIACGL09_TAB
* | [<---] ET_ACCOUNT_RECEIVABLE          TYPE        BAPIACAR09_TAB
* | [<---] ET_ACCOUNT_PAYABLE             TYPE        BAPIACAP09_TAB
* | [<---] ET_ACCOUNT_TAX                 TYPE        BAPIACTX09_TAB
* | [<---] ET_CURRENCY_AMOUNT             TYPE        BAPIACCR09_TAB
* | [<---] ET_CRITERIA                    TYPE        BAPIACKEC9_TAB
* | [<---] ET_VALUEFIELD                  TYPE        BAPIACKEV9_TAB
* | [<---] ET_EXTENSION1                  TYPE        BAPIACEXTC_TAB
* | [<---] ET_EXTENSION2                  TYPE        BAPIPAREX_TAB
* | [<---] ET_PAYMENTCARD                 TYPE        BAPIACPC09_TAB
* | [<---] ET_ACCOUNTWT                   TYPE        BAPIACWT09_TAB
* | [<-->] CT_LOG                         TYPE        ZINV_CL_BP_POST_USER=>GTT_GR_ERROR(optional)
* | [<-->] CT_DATA                        TYPE        ZTT_INV_INPUT_SUP(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD validate_inv_data_copy.


    TYPES: BEGIN OF lty_vendor,
             comp_code        TYPE bukrs,
             posting_date     TYPE budat,
             acc_type         TYPE koart,
             document_type    TYPE blart,
             invoice_id       TYPE num10,
             posting_key      TYPE bschl,
             invoicing_party  TYPE string,
             assign_number    TYPE dzuonr,
             gross_inv_amount TYPE  wrbtr,

           END OF lty_vendor.

    DATA: ltt_vendor TYPE TABLE OF lty_vendor.

    TYPES: BEGIN OF lty_gl_tax_code,


             gl_tax_cd TYPE mwskz,


           END OF lty_gl_tax_code.

    TYPES: BEGIN OF lty_gl_tax,

             item     TYPE num10,
             tax_code TYPE mwskz,
             base_amt TYPE wrbtr,
             tax_amt  TYPE wrbtr,

           END OF lty_gl_tax.

    DATA: ltt_gl_tax TYPE TABLE OF lty_gl_tax.

    TYPES: BEGIN OF lty_gl_assign,

             item      TYPE num10,
             base_amt  TYPE wrbtr,
             assign_nr TYPE dzuonr,
             tax_code  TYPE mwskz,

           END OF lty_gl_assign.

    DATA: ltt_gl_assign TYPE TABLE OF lty_gl_assign.

    TYPES: BEGIN OF lty_gl_det,
             invoice_id              TYPE num10,
             gl_comp_code            TYPE bukrs,
             gl_account              TYPE hkont,
             gl_itm_txt              TYPE sgtxt,
             deb_cre                 TYPE shkzg,
             gl_curr                 TYPE waers,
*  @Semantics.amount.currencyCode : 'zstr_gl_account.gl_curr'
             gl_amount               TYPE wrbtr,
             gl_tax_cd               TYPE mwskz,
             gl_assignment           TYPE dzuonr,
             cost_center             TYPE kostl,
             profit_cent             TYPE prctr,
             wbs_element             TYPE ps_posid,
*  @Semantics.amount.currencyCode : 'zstr_gl_account.gl_curr'
             tax_bs_amt              TYPE txbhw,
             business_place          TYPE bupla,
             zz1_origin_mse          TYPE zz1_origin,
             zz1_subfleet_mse        TYPE zz1_subfleet,
             zz1_route_mse           TYPE zz1_route,
             zz1_tailnumber_mse      TYPE zz1_tailnumber,
             zz1_flightdate_mse      TYPE zz1_flightdate,
             zz1_flighttype_mse      TYPE zz1_flighttype,
             zz1_destination_mse     TYPE zz1_destination,
             zz1_bodytype_mse        TYPE zz1_bodytype,
             zz1_sector_mse          TYPE zz1_sector,
             zz1_aircrafttype_mse    TYPE zz1_aircrafttype,
             zz1_flightnumber_mse    TYPE zz1_flightnumber,
             zz1_flightindicator_mse TYPE zz1_flightindicator,
             cb_aircrafttype         TYPE yy1_cb_aircrafttype,
             cb_pos                  TYPE yy1_cb_pos,
             cb_apttaxcode           TYPE yy1_apttaxcode,
             cb_tailnumber           TYPE yy1_cb_tailnumber,
             cb_aptstation           TYPE yy1_cb_aptstation,
             cb_ref4                 TYPE xblnr,
             cb_ref5                 TYPE xblnr,
             cb_ref6                 TYPE xblnr,
             copa_ind                TYPE char1,
             cb_ind                  TYPE char1,
           END OF lty_gl_det.

    FIELD-SYMBOLS: <fs_curramt> TYPE bapiaccr09.

    DATA: lt_message      TYPE zinv_cl_bp_post_user=>gtt_gr_error,
          ls_message      TYPE zinv_cl_bp_post_user=>gty_gr_error,
          lv_posting_date TYPE sy-datum,
          lv_year         TYPE char4.

    DATA: lv_inv_type     TYPE bapiache09-doc_type,
          ls_doc_header   TYPE bapiache09,
          ls_gl_account   TYPE bapiacgl09,
          lt_gl_account   TYPE TABLE OF  bapiacgl09,
          ls_acc_payable  TYPE bapiacap09,
          lt_acc_payable  TYPE TABLE OF bapiacap09,
          ls_acc_tax      TYPE bapiactx09,
          lt_acc_tax      TYPE TABLE OF bapiactx09,
          ls_curr_amt     TYPE bapiaccr09,
          lt_curr_amt     TYPE TABLE OF bapiaccr09,
          ls_acct_wt      TYPE  bapiacwt09,
          lt_acct_wt      TYPE TABLE OF bapiacwt09,
          lt_acc_rec      TYPE  TABLE OF bapiacar09,
          ls_acc_rec      TYPE  bapiacar09,
          ls_custcpd      TYPE bapiacpa09,
          lt_custcpd      TYPE STANDARD TABLE OF bapiacpa09,
          lt_criteria     TYPE STANDARD TABLE OF bapiackec9,
          ls_extension    TYPE bapiparex,
          lt_extension    TYPE TABLE OF bapiparex,
          ls_out          TYPE bapiache09-obj_key,
          lt_return       TYPE bapiret2_tab,
          lt_gl_det       TYPE TABLE OF lty_gl_det,
          lt_gl_tax_code  TYPE TABLE OF lty_gl_tax_code,
          lv_total_gross  TYPE wrbtr,
          lv_total_gl_amt TYPE wrbtr,
          lv_net_sum      TYPE wrbtr.
    DATA:
      lv_item      TYPE posnr_acc,
      lv_item_gl   TYPE posnr_acc,
      lv_item_copy TYPE posnr_acc,
      lo_msg       TYPE REF TO /iwbep/if_message_container,
      lv_message   TYPE string.

    IF ct_data IS NOT INITIAL.

      ev_status = 'S'.

      DATA(lt_data_copy) = ct_data.

      SORT ct_data BY invoice_id ASCENDING.
      DATA: lv_blart TYPE blart.
      DATA: lv_zuonr TYPE dzuonr.

      ltt_vendor = CORRESPONDING #( lt_data_copy ).
      DELETE ltt_vendor WHERE invoicing_party IS INITIAL.
      SORT ltt_vendor BY invoicing_party.
      DELETE ADJACENT DUPLICATES FROM ltt_vendor COMPARING invoicing_party.

      SELECT  bukrs, gjahr, h_blart, koart, zuonr
          FROM bseg INTO TABLE @DATA(lt_bseg)
           FOR ALL ENTRIES IN  @ltt_vendor
             WHERE        bukrs = @ltt_vendor-comp_code AND
                          gjahr = @ltt_vendor-posting_date+0(4) AND
                          h_blart = @ltt_vendor-document_type AND
                          koart = @ltt_vendor-acc_type AND
                          zuonr = @ltt_vendor-assign_number.

      SELECT code FROM zz1_flightindicator_v  WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltind).
      SELECT code FROM zz1_tailnumber_v       WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_flttailnb).
      SELECT code FROM zz1_aircrafttype_v     WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltartyp).
      SELECT code FROM zz1_flightnumber_v     WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltnb).

      SELECT bukrs,zpm_low INTO TABLE @DATA(lt_round) FROM zglbparam WHERE zparam_id = 'ZFIAPMASSUL_CURR'.
      LOOP AT ltt_vendor INTO DATA(ls_vendor_dup).
        DATA(lv_dup_error) = abap_false.
        LOOP AT lt_data_copy INTO DATA(ls_data_dup) WHERE invoice_id = ls_vendor_dup-invoice_id AND
                                                          invoicing_party IS NOT INITIAL.

          IF ls_data_dup-invoicing_party NE ls_vendor_dup-invoicing_party.
            ls_message-line_no = ls_data_dup-linenumber.
            ls_message-line_id = ls_data_dup-lineid.
            ls_message-invoice_id = ls_data_dup-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Maintain unique Invoice Id for Vendor &1'.
            REPLACE '&' WITH ls_vendor_dup-invoicing_party INTO ls_message-message.
            APPEND ls_message TO lt_message.
            lv_dup_error = abap_true.
*            EXIT.
            CONTINUE.
          ENDIF.
        ENDLOOP.
        IF lv_dup_error EQ abap_true.
          ev_errorcount = ev_errorcount + 1.
          ev_status = 'E'.
          ls_data_dup-status = 'E'.
          ls_data_dup-invoicing_party = ls_vendor_dup-invoicing_party.
          MODIFY  ct_data FROM ls_data_dup TRANSPORTING  status WHERE invoicing_party = ls_data_dup-invoicing_party.
        ENDIF.
        CLEAR:ls_data_dup.
      ENDLOOP.

      REFRESH:ltt_vendor[].

      LOOP AT lt_data_copy ASSIGNING FIELD-SYMBOL(<fs_data>).
        DATA(lt_data) = lt_data_copy.
        DATA(lv_invoice_id) = <fs_data>-invoice_id.
        DATA(lv_currency) = <fs_data>-currency.
        DELETE lt_data WHERE invoice_id NE lv_invoice_id.

        CLEAR: et_account_gl, et_account_payable, et_account_tax,
        et_currency_amount, es_documentheader,es_customercpd, lv_item.
        lt_gl_det = CORRESPONDING #( lt_data_copy ).
        DELETE lt_gl_det WHERE invoice_id NE <fs_data>-invoice_id.

        DESCRIBE TABLE lt_gl_det LINES DATA(lv_gl_index).
        LOOP AT lt_gl_det ASSIGNING FIELD-SYMBOL(<fs_gl_det>).
*         IF lv_currency = 'KRW'.
*            <fs_gl_det>-gl_amount = <fs_gl_det>-gl_amount / 100.
*          ENDIF.
          IF <fs_gl_det>-deb_cre EQ 'H'.
            <fs_gl_det>-gl_amount = <fs_gl_det>-gl_amount * -1.
          ENDIF.
        ENDLOOP.
        lv_total_gl_amt = REDUCE tslxx9( INIT sum TYPE tslxx9
                                 FOR ls_gl_sum IN lt_gl_det
                                 NEXT sum = sum + ls_gl_sum-gl_amount ).

        ltt_vendor = CORRESPONDING #( lt_data_copy ).
        SORT ltt_vendor BY invoicing_party assign_number ASCENDING.
        DELETE ADJACENT DUPLICATES FROM ltt_vendor.
        DELETE ltt_vendor WHERE assign_number IS INITIAL.
        DELETE ltt_vendor WHERE invoice_id NE <fs_data>-invoice_id.
        DESCRIBE TABLE ltt_vendor LINES DATA(lv_acc_pay).
*        DATA(ltt_vendor_1) = ltt_vendor.
        LOOP AT ltt_vendor ASSIGNING FIELD-SYMBOL(<fs_vendor>).
          DATA(lv_posting_key) = <fs_vendor>-posting_key.
**          KRW currency changes
*          IF lv_currency = 'KRW'.
*            <fs_vendor>-gross_inv_amount = <fs_vendor>-gross_inv_amount / 100.
*          ENDIF.
          IF <fs_vendor>-posting_key EQ '31'.
            <fs_vendor>-gross_inv_amount = <fs_vendor>-gross_inv_amount * -1.
          ENDIF.
        ENDLOOP.

*Validation for Incorrect Assignment Number
        LOOP AT lt_gl_det INTO DATA(ls_gl).
          READ TABLE ltt_vendor INTO DATA(ls_vendor_1) WITH KEY assign_number = ls_gl-gl_assignment.
          IF sy-subrc NE 0.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Assignment Number incorrect for Invoice Id &'.
            REPLACE '&' WITH lv_invoice_id INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
            EXIT.
          ENDIF.
        ENDLOOP.

        lv_total_gross = REDUCE tslxx9( INIT sum TYPE tslxx9
                                    FOR ls_vendor IN ltt_vendor
                                    NEXT sum = sum + ls_vendor-gross_inv_amount ).

        lt_gl_tax_code = CORRESPONDING #( lt_gl_det ).
        SORT lt_gl_tax_code BY gl_tax_cd.
        DELETE ADJACENT DUPLICATES FROM lt_gl_tax_code.
        DESCRIBE TABLE lt_gl_tax_code LINES DATA(lv_gl_tc_index).

        IF <fs_data> IS ASSIGNED.
          <fs_data>-status = 'S'.
          <fs_data>-stage = 'Validation'.
          IF <fs_data>-invoice_id IS INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Invoice Id is Mandatory'.
            REPLACE '&' WITH TEXT-003 INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*            EXIT.
            CONTINUE.

          ENDIF.
          lv_net_sum = lv_total_gross + lv_total_gl_amt.
*          IF lv_total_gross NE lv_total_gl_amt.
          IF lv_net_sum NE 0.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Total gross amount does not match with Cumulative GL amount for invoice id &'.
            REPLACE '&' WITH <fs_data>-invoice_id INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*            EXIT.
            CONTINUE.
          ENDIF.

          lv_posting_date = <fs_data>-posting_date.
          lv_year = lv_posting_date+0(4).
          lv_blart = <fs_data>-document_type.
          DATA(lv_acc_type) = <fs_data>-acc_type.

*          SELECT SINGLE bukrs, gjahr, h_blart, koart, zuonr
*           FROM bseg INTO @DATA(ls_bseg)
*            WHERE bukrs = @<fs_data>-comp_code AND
*                  gjahr = @lv_year AND
*                  h_blart = @lv_blart AND
*                  koart = @lv_acc_type AND
*                  zuonr = @<fs_data>-assign_number.
*
*          IF ls_bseg IS NOT INITIAL.
*            ls_message-line_no = <fs_data>-linenumber.
*            ls_message-line_id = <fs_data>-lineid.
*            ls_message-invoice_id = <fs_data>-invoice_id.
*            ls_message-status = 'Error'.
*            ls_message-code = '1'.
*            ls_message-message = 'Duplicate invoice entry &1'.
*            REPLACE '&' WITH ls_bseg-zuonr INTO ls_message-message.
*            APPEND ls_message TO lt_message.
*
*            ev_errorcount = ev_errorcount + 1.
*            ev_status = 'E'.
*            <fs_data>-status = 'E'.
*            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*            EXIT.
*          ENDIF.

*          SELECT  bukrs, gjahr, h_blart, koart, zuonr
*            FROM bseg INTO TABLE @DATA(lt_bseg)
*             FOR ALL ENTRIES IN  @ltt_vendor
*               WHERE        bukrs = @ltt_vendor-comp_code AND
*                            gjahr = @ltt_vendor-posting_date+0(4) AND
*                            h_blart = @ltt_vendor-document_type AND
*                            koart = @ltt_vendor-acc_type AND
*                            zuonr = @ltt_vendor-assign_number.

          IF lt_bseg IS NOT INITIAL.
            READ TABLE lt_bseg INTO DATA(ls_bseg)
                     WITH KEY
                     bukrs = <fs_data>-comp_code
                     gjahr = <fs_data>-posting_date+0(4)
                     h_blart = <fs_data>-document_type
                     koart = <fs_data>-acc_type
                     zuonr = <fs_data>-assign_number.
            IF sy-subrc = 0.
*            LOOP AT lt_bseg INTO DATA(ls_bseg).
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Duplicate invoice entry &1'.
*              REPLACE '&' WITH ls_bseg-zuonr INTO ls_message-message.
              REPLACE '&' WITH ls_bseg INTO ls_message-message.
              APPEND ls_message TO lt_message.

              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*            EXIT.
              CONTINUE.
*            ENDLOOP.
            ENDIF.
          ENDIF.


*          Cost Center Validation
          READ TABLE lt_gl_det INTO DATA(ls_cost_cent) WITH KEY cost_center = ' '.
          IF sy-subrc IS INITIAL.
            IF ls_cost_cent-wbs_element IS INITIAL  AND ls_cost_cent-profit_cent IS INITIAL .
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Cost Center or WBS is Mandatory for invoice id &'.
              REPLACE '&' WITH <fs_data>-invoice_id INTO ls_message-message.
              APPEND ls_message TO lt_message.
              CLEAR: lv_message.

              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*            EXIT.
              CONTINUE.
            ENDIF.
          ENDIF.

          DATA(lt_data_tax) = lt_data_copy.
          DATA(lt_data_no_tax) = lt_data_copy.

          DELETE lt_data_tax WHERE invoice_id NE <fs_data>-invoice_id.
          DELETE lt_data_no_tax WHERE invoice_id NE <fs_data>-invoice_id.

          DELETE lt_data_tax WHERE gl_tax_cd IS INITIAL.
          DELETE lt_data_no_tax WHERE gl_tax_cd IS NOT INITIAL.
          IF <fs_data>-tax_rpt_ctry IS NOT INITIAL .
            DATA(lv_tax_cntry) = <fs_data>-tax_rpt_ctry.
          ENDIF.
*          IF <fs_data>-tax_rpt_ctry IS NOT INITIAL.
          IF lv_tax_cntry IS NOT INITIAL.
            IF ( lt_data_tax IS NOT INITIAL AND lt_data_no_tax IS NOT INITIAL ) OR
               ( <fs_data>-tax_rpt_ctry IS NOT INITIAL AND lt_data_tax IS INITIAL ).
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Tax reporting country has been entered. So maintain the tax codes for all the line items '.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              CONTINUE.
            ENDIF.
          ELSEIF lt_data_tax IS NOT INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Tax reporting country has not been entered'.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
            CONTINUE.
            REFRESH: lt_data_tax,lt_data_no_tax .
          ENDIF.

          "COPA and Coding Block validation
          DATA(lv_copa_cb) = abap_true.
          IF <fs_data>-zz1_tailnumber_mse IS NOT INITIAL.
            READ TABLE lt_flttailnb INTO DATA(ls_flttailnb) WITH KEY code = <fs_data>-zz1_tailnumber_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect TailNumber & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_tailnumber_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1_aircrafttype_mse IS NOT INITIAL.
            READ TABLE lt_fltartyp INTO DATA(ls_fltartyp) WITH KEY code = <fs_data>-zz1_aircrafttype_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Aircraft Type & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_aircrafttype_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1_flightnumber_mse IS NOT INITIAL.
            READ TABLE lt_fltnb INTO DATA(ls_fltnb) WITH KEY code = <fs_data>-zz1_flightnumber_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Flight Number & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_flightnumber_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1_flightindicator_mse IS NOT INITIAL.
            READ TABLE lt_fltind INTO DATA(ls_fltind) WITH KEY code = <fs_data>-zz1_flightindicator_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Flight Indicator & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_flightindicator_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-cb_aircrafttype IS NOT INITIAL.
            READ TABLE lt_fltartyp INTO ls_fltartyp WITH KEY code = <fs_data>-cb_aircrafttype.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Coding Block Aircraft Type & for Line Item &'.
              REPLACE '&' WITH <fs_data>-cb_aircrafttype INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-cb_tailnumber IS NOT INITIAL.
            READ TABLE lt_flttailnb INTO ls_flttailnb WITH KEY code = <fs_data>-cb_tailnumber.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Coding Block TailNumber & for Line Item &'.
              REPLACE '&' WITH <fs_data>-cb_tailnumber INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.
          IF lv_copa_cb = abap_false.
            CONTINUE.
          ENDIF.

          ls_doc_header-bus_act       = 'RFBU'.
          ls_doc_header-username      = sy-uname.
          ls_doc_header-doc_date      = <fs_data>-document_date."sy-datum.   "pc INVOICE date
          ls_doc_header-doc_type      = <fs_data>-document_type.   " Document Type   "EKKO-BSART
          ls_doc_header-comp_code     = <fs_data>-comp_code." Company code
          ls_doc_header-header_txt    = <fs_data>-docu_hdr_text.
          ls_doc_header-pstng_date    = <fs_data>-posting_date.
          ls_doc_header-fisc_year     = <fs_data>-posting_date+0(4).
          ls_doc_header-ref_doc_no    = <fs_data>-reference.  "need to ask

          MOVE-CORRESPONDING ls_doc_header TO es_documentheader.

          DATA(lv_index) = 1.
          READ TABLE lt_data INTO DATA(ls_data) WITH KEY invoice_id = <fs_data>-invoice_id.
          IF sy-subrc = 0.
            DATA(lv_data_index) = sy-tabix.

            LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>) FROM lv_data_index.
              IF <ls_data>-invoice_id NE <fs_data>-invoice_id.
                EXIT.
              ENDIF.

*           ACCOUNTPAYABLE
              IF <ls_data>-invoicing_party IS NOT INITIAL.

                DESCRIBE TABLE lt_acc_payable LINES DATA(lv_acc_pay_count).

                lv_item = lv_acc_pay_count + 1.
                ls_acc_payable-itemno_acc = lv_item.
                ls_acc_payable-comp_code = <ls_data>-comp_code.
                ls_acc_payable-bline_date = <ls_data>-baseline_date.
                ls_acc_payable-pmnt_block = <ls_data>-payment_block_key.
                ls_acc_payable-paymt_ref = <ls_data>-payment_ref.
                ls_acc_payable-bank_id = <ls_data>-short_key_hsb.
                ls_acc_payable-pymt_meth = <ls_data>-payment_method.
                ls_acc_payable-partner_bk = <ls_data>-part_bank_type.
                ls_acc_payable-housebankacctid = <ls_data>-id_acc_det.
                ls_acc_payable-item_text = <ls_data>-item_text.
                ls_acc_payable-businessplace = <ls_data>-business_place.

                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = <ls_data>-terms_payment
                  IMPORTING
                    output = ls_acc_payable-pmnttrms.
                ls_acc_payable-vendor_no = <ls_data>-invoicing_party.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = <ls_data>-invoicing_party
                  IMPORTING
                    output = ls_acc_payable-vendor_no.

                ls_acc_payable-alloc_nmbr = <ls_data>-assign_number.

                APPEND ls_acc_payable      TO lt_acc_payable.
                SORT lt_acc_payable BY itemno_acc.
                et_account_payable = lt_acc_payable.

**Withholding Tax

                IF <ls_data>-withold_tax_code IS NOT INITIAL AND <ls_data>-withold_tax_type IS NOT INITIAL.
                  DESCRIBE TABLE lt_acct_wt LINES DATA(lv_wt_count).

                  lv_item = lv_wt_count + 1.
                  ls_acct_wt-itemno_acc = lv_item.
                  ls_acct_wt-wt_code = <ls_data>-withold_tax_code.
                  ls_acct_wt-wt_type = <ls_data>-withold_tax_type.

                  IF <ls_data>-withold_tax_base IS NOT INITIAL.
                    ls_acct_wt-man_amt_tc = <ls_data>-withold_tax_amount_dc.
                    ls_acct_wt-bas_amt_tc = <ls_data>-withold_tax_base.
                  ELSE.
                    ls_acct_wt-bas_amt_tc = <ls_data>-gross_inv_amount.
*                  ls_acct_wt-bas_amt_tc = <ls_data>-withold_tax_base.*
                  ENDIF.

                  APPEND ls_acct_wt      TO lt_acct_wt.
                  SORT lt_acct_wt BY itemno_acc.
                  et_accountwt = lt_acct_wt.

                  CLEAR: ls_acct_wt,lv_item.
                ENDIF.
* Withholding tax

                CLEAR ls_acc_payable.

                IF <ls_data>-name IS NOT INITIAL.
                  ls_custcpd-name = <ls_data>-name.
                  ls_custcpd-city = <ls_data>-city.
                  ls_custcpd-country = <ls_data>-country.
                  ls_custcpd-bank_acct = <ls_data>-bank_acc.
                  ls_custcpd-bank_no = <ls_data>-bank_key.
                  ls_custcpd-bank_ctry = <ls_data>-bank_reg.
                  ls_custcpd-swift_code = <fs_data>-swift_cd.
*                    ls_custcpd-iban = <ls_data>-iban.

                  MOVE-CORRESPONDING ls_custcpd TO es_customercpd.
                ENDIF.
              ENDIF.
*          SORT gt_acc_payable BY  itemno_acc.
* ACCOUNTPAYABLE

              LOOP AT lt_gl_det INTO DATA(ls_gl_det) WHERE gl_assignment = <ls_data>-assign_number.
* GLAccount
                lv_index = sy-tabix.

                DESCRIBE TABLE lt_gl_account LINES DATA(lv_gl_acc_index).
                lv_item = lv_acc_pay + lv_gl_acc_index + 1.

                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_gl_det-gl_account
                  IMPORTING
                    output = ls_gl_det-gl_account.

                READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_det-gl_account
                                                                         costcenter = ls_gl_det-cost_center
                                                                         profit_ctr = ls_gl_det-profit_cent
                                                                         wbs_element = ls_gl_det-wbs_element
                                                                         item_text = ls_gl_det-gl_itm_txt.
                IF sy-subrc NE 0.

                  ls_gl_account-itemno_acc = lv_item.
                  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                    EXPORTING
                      input  = ls_gl_det-gl_account
                    IMPORTING
                      output = ls_gl_account-gl_account.

                  ls_gl_account-wbs_element = ls_gl_det-wbs_element.
                  ls_gl_account-costcenter = ls_gl_det-cost_center.
                  ls_gl_account-profit_ctr  = ls_gl_det-profit_cent.
                  ls_gl_account-item_text   = ls_gl_det-gl_itm_txt.
                  ls_gl_account-comp_code = ls_gl_det-gl_comp_code.
                  ls_gl_account-fisc_year = lv_year.
                  ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                  ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                  APPEND ls_gl_account TO lt_gl_account.
                  SORT lt_gl_account BY itemno_acc.
                  et_account_gl = lt_gl_account.

                  IF ls_gl_account IS INITIAL.
                    CLEAR: ls_gl_det-copa_ind, ls_gl_det-cb_ind.
                  ENDIF.
                  CLEAR ls_gl_account.
*                  GL Account

*                Criteria- CoPA

                  IF ls_gl_det-copa_ind = abap_true.
                    READ TABLE lt_criteria TRANSPORTING NO FIELDS WITH KEY itemno_acc = lv_item.
                    IF sy-subrc <> 0.
                      lt_criteria = VALUE #( BASE lt_criteria[]
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_origin_mse          fieldname = 'ZZ1_ORIGIN_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_subfleet_mse        fieldname = 'ZZ1_SUBFLEET_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_route_mse           fieldname = 'ZZ1_ROUTE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_tailnumber_mse      fieldname = 'ZZ1_TAILNUMBER_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flightdate_mse      fieldname = 'ZZ1_FLIGHTDATE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flighttype_mse      fieldname = 'ZZ1_FLIGHTTYPE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_destination_mse     fieldname = 'ZZ1_DESTINATION_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_bodytype_mse        fieldname = 'ZZ1_BODYTYPE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_sector_mse          fieldname = 'ZZ1_SECTOR_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_aircrafttype_mse    fieldname = 'ZZ1_AIRCRAFTTYPE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flightnumber_mse    fieldname = 'ZZ1_FLIGHTNUMBER_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flightindicator_mse fieldname = 'ZZ1_FLIGHTINDICATOR_MSE' )
                                              ).
                      SORT lt_criteria BY itemno_acc.
                      et_criteria = lt_criteria.
                    ENDIF.
                  ENDIF.
* Criteria-CoPA

* Extensions2
                  IF ls_gl_det-cb_ind = abap_true.
                    READ TABLE lt_extension TRANSPORTING NO FIELDS WITH KEY valuepart1 = lv_item.
                    IF sy-subrc <> 0.
                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'BUPLA'.
                      ls_extension-valuepart3 = <fs_data>-business_place.  " ls_gl_det-business_place.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_AIRCRAFTTYPE_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_aircrafttype.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_POS_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_pos.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_APTTAXCODE_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_apttaxcode.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_TAILNUMBER_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_tailnumber.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_APTSTATION_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_aptstation.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_REFERENCE4_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_ref4.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_REFERENCE5_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_ref5.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_REFERENCE6_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_ref6.
                      APPEND ls_extension TO lt_extension.
                      SORT lt_extension BY valuepart1.
                      et_extension2 = lt_extension.
                    ENDIF.
                  ENDIF.

* Extensions2
*                  Tax Calculation
                  DATA: lt_mwdat         TYPE fm_tt_rtax1u15.
                  DATA: lt_mwdat_cpy         TYPE fm_tt_rtax1u15.
                  DATA: ls_mwdat_cpy     TYPE rtax1u15.
                  DATA: lv_lstml         TYPE land1_stml.
                  DATA: lv_amount_doccur TYPE bapidoccur.
*                  DATA: lv_amount_tax    TYPE bapi_rmwwr.
                  DATA: lv_amount_tax    TYPE wrbtr.
                  DATA: lv_amount_tax_rd TYPE wrbtr.
                  DATA: lv_calc_tax      TYPE fwste.
                  DATA: lv_wrbtr         TYPE wrbtr.
                  DATA: lv_total_tax TYPE fwste,
                        ls_gl_assign TYPE lty_gl_assign.
                  lv_lstml   = <ls_data>-tax_rpt_ctry.
*Calculate tax - Vendor

                  IF lv_lstml IS INITIAL AND ls_gl_det-gl_tax_cd IS INITIAL.
                    ls_mwdat_cpy-msatz = 0.
                    ls_mwdat_cpy-kawrt = ls_gl_det-gl_amount.
                    APPEND ls_mwdat_cpy TO lt_mwdat_cpy.
                  ENDIF.

                  CALL FUNCTION 'Z_CALCULATE_TAX_FRM_NET'
                    EXPORTING
                      i_bukrs                 = ls_gl_det-gl_comp_code " <ls_data>-comp_code
                      i_mwskz                 = ls_gl_det-gl_tax_cd
                      i_waers                 = <ls_data>-currency
                      i_wrbtr                 = ls_gl_det-gl_amount
                      i_lstml                 = lv_lstml
                    TABLES
                      t_mwdat                 = lt_mwdat
                    EXCEPTIONS
                      bukrs_not_found         = 1
                      country_not_found       = 2
                      mwskz_not_defined       = 3
                      mwskz_not_valid         = 4
                      account_not_found       = 5
                      different_discount_base = 6
                      different_tax_base      = 7
                      txjcd_not_valid         = 8
                      not_found               = 9
                      ktosl_not_found         = 10
                      kalsm_not_found         = 11
                      parameter_error         = 12
                      knumh_not_found         = 13
                      kschl_not_found         = 14
                      unknown_error           = 15
                      OTHERS                  = 16.
                  IF lt_mwdat IS INITIAL AND lt_mwdat_cpy IS INITIAL. "sy-subrc <> 0.
*            PERFORM populate_error USING TEXT-013.
                  ELSE.
                    IF lt_mwdat IS INITIAL.
                      lt_mwdat = lt_mwdat_cpy.
                    ENDIF.
                    READ TABLE lt_mwdat INTO DATA(ls_mwdat) INDEX 1.
                    IF sy-subrc = 0.
                      DATA(lv_tax_rate) = ls_mwdat-msatz.
*                      lv_amount_tax = ls_gl_det-gl_amount * lv_tax_rate / 100.
                      lv_amount_tax = ls_mwdat-kawrt * lv_tax_rate / 100.
                      READ TABLE lt_round INTO DATA(ls_round) WITH KEY zpm_low = lv_currency
                                                                       bukrs = <fs_data>-comp_code.
                      IF sy-subrc EQ 0.
                        lv_amount_tax_rd = round(
                                      val  = lv_amount_tax
                                      dec  = 0
                                      mode = cl_abap_math=>round_half_up
                                    ).
                        lv_amount_tax = lv_amount_tax_rd.
                      ENDIF.
*                  lv_item = lv_index.
                      READ TABLE ltt_gl_assign ASSIGNING FIELD-SYMBOL(<fs_gl_assign>) WITH KEY assign_nr = ls_gl_det-gl_assignment."tax_code = ls_gl_det-gl_tax_cd.
                      IF sy-subrc = 0.
                        lv_item = <fs_gl_assign>-item.
                        <fs_gl_assign>-base_amt =  <fs_gl_assign>-base_amt + ls_gl_det-gl_amount + lv_amount_tax.
                      ELSE.
                        DESCRIBE TABLE ltt_gl_assign LINES DATA(lv_assign_ct).
                        lv_item = lv_assign_ct + 1.
                        ls_gl_assign-item =  lv_item.
                        ls_gl_assign-assign_nr = ls_gl_det-gl_assignment.
                        ls_gl_assign-tax_code = ls_gl_det-gl_tax_cd.
                        ls_gl_assign-base_amt =  ls_gl_assign-base_amt + ls_gl_det-gl_amount + lv_amount_tax.
                        APPEND ls_gl_assign TO ltt_gl_assign.
                        CLEAR: lv_amount_doccur, ls_gl_assign.
                        UNASSIGN: <fs_gl_assign>.
                      ENDIF.

                      READ TABLE lt_curr_amt ASSIGNING FIELD-SYMBOL(<fs_curr_amt>) WITH KEY itemno_acc = lv_item.
                      IF sy-subrc NE 0.
                        ls_curr_amt-itemno_acc = lv_item.
                        lv_amount_doccur =  lv_amount_doccur + ls_gl_det-gl_amount + lv_amount_tax.
                        ls_curr_amt-currency = <ls_data>-currency."ls_gl_det-gl_curr.
*Changes by Gaurav Sharma
*                        IF ls_gl_det-deb_cre = 'H'.
                        ls_curr_amt-amt_doccur =    lv_amount_doccur.
*                        ELSEIF ls_gl_det-deb_cre = 'S'.
*                          ls_curr_amt-amt_doccur = lv_amount_doccur  * -1.
*                        ENDIF.
*Changes by Gaurav Sharma
                        APPEND ls_curr_amt TO lt_curr_amt.
                        CLEAR: ls_curr_amt.
                      ELSEIF <fs_curr_amt> IS ASSIGNED.
*Changes by Gaurav Sharma
*                        IF ls_gl_det-deb_cre = 'H'.
                        <fs_curr_amt>-amt_doccur = (  lv_amount_doccur + ls_gl_det-gl_amount + lv_amount_tax ).
*                        ELSE.
*                          <fs_curr_amt>-amt_doccur = (  lv_amount_doccur + ls_gl_det-gl_amount + lv_amount_tax ) * -1.
*                        ENDIF.
*Changes by Gaurav Sharma
                        lv_amount_doccur =   lv_amount_doccur + ls_gl_det-gl_amount + lv_amount_tax.

                      ENDIF.
                      UNASSIGN <fs_curr_amt>.


                      lv_item = lv_index + lv_acc_pay.
                      ls_curr_amt-itemno_acc = lv_item.
                      ls_curr_amt-currency =  <ls_data>-currency.
*Changes by Gaurav Sharma
*                      IF ls_gl_det-deb_cre = 'S'.
                      ls_curr_amt-amt_doccur =  ls_gl_det-gl_amount.
*                      ELSE.
*                        ls_curr_amt-amt_doccur =  ls_gl_det-gl_amount * -1.
*                      ENDIF.
*Changes by Gaurav Sharma
                      APPEND ls_curr_amt TO lt_curr_amt.
                      CLEAR: ls_curr_amt.
                      lv_item = lv_acc_pay + lv_gl_index.
                      DESCRIBE TABLE ltt_gl_tax LINES DATA(lv_gl_tax).
                      lv_item_copy = lv_item + lv_gl_tax + 1.

                      DATA ls_gl_tax TYPE lty_gl_tax.
                      READ TABLE ltt_gl_tax ASSIGNING FIELD-SYMBOL(<fs_gl_tax>) WITH KEY tax_code = ls_gl_det-gl_tax_cd.
                      IF sy-subrc NE 0.

                        lv_item = lv_item_copy.
                        ls_gl_tax-tax_code = ls_gl_det-gl_tax_cd.
                        ls_gl_tax-item = lv_item.
                        ls_gl_tax-tax_amt = lv_amount_tax.
                        ls_gl_tax-base_amt = ls_gl_det-gl_amount.
                        APPEND ls_gl_tax TO ltt_gl_tax.

                        ls_acc_tax-itemno_acc = lv_item.
                        ls_acc_tax-tax_code = ls_gl_det-gl_tax_cd.
                        ls_acc_tax-gl_account = ls_mwdat-hkont.
                        ls_acc_tax-acct_key = ls_mwdat-ktosl.
                        ls_acc_tax-cond_key = ls_mwdat-kschl.
                        ls_acc_tax-tax_country = <ls_data>-tax_rpt_ctry.
                        APPEND ls_acc_tax TO lt_acc_tax.

                        ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc. " lv_item.
                        ls_curr_amt-currency =  <ls_data>-currency.
*Changes by Gaurav Sharma
*                        IF ls_gl_det-deb_cre = 'H'.
*                          lv_amount_tax = lv_amount_tax * -1.
*                          ls_gl_det-gl_amount = ls_gl_det-gl_amount * -1.
*                        ENDIF.
*Changes by Gaurav Sharma
                        ls_curr_amt-amt_doccur =  lv_amount_tax .
                        ls_curr_amt-amt_base = ls_gl_det-gl_amount.

                        APPEND ls_curr_amt TO lt_curr_amt.
                        CLEAR: ls_curr_amt.
                      ELSE.
                        READ TABLE lt_acc_tax ASSIGNING FIELD-SYMBOL(<fs_acc_tax>) WITH KEY tax_code = ls_gl_det-gl_tax_cd.
                        IF sy-subrc = 0.
*                        READ TABLE lt_curr_amt ASSIGNING <fs_curr_amt> WITH KEY amt_doccur = <fs_gl_tax>-tax_amt amt_base = <fs_gl_tax>-base_amt.
                          READ TABLE lt_curr_amt ASSIGNING <fs_curr_amt> WITH KEY itemno_acc = <fs_acc_tax>-itemno_acc.
                          IF sy-subrc = 0.
                            lv_item_copy = <fs_curr_amt>-itemno_acc.
                            <fs_curr_amt>-currency = <ls_data>-currency.
*Changes by Gaurav Sharma
*                            IF ls_gl_det-deb_cre = 'H'.
*                              lv_amount_tax = lv_amount_tax * -1.
*                              ls_gl_det-gl_amount = ls_gl_det-gl_amount * -1.
*                            ENDIF.
*Changes by Gaurav Sharma
                            <fs_curr_amt>-amt_doccur =  <fs_gl_tax>-tax_amt + lv_amount_tax.
                            <fs_curr_amt>-amt_base = <fs_gl_tax>-base_amt + ls_gl_det-gl_amount.
                            <fs_gl_tax>-tax_amt =   <fs_curr_amt>-amt_doccur .
                            <fs_gl_tax>-base_amt =  <fs_curr_amt>-amt_base .

                          ENDIF.
                        ENDIF.
                      ENDIF.
                    ENDIF.
                    READ TABLE lt_mwdat INTO ls_mwdat INDEX 2.
                    IF sy-subrc = 0.
                      lv_tax_rate = ls_mwdat-msatz.
                      lv_amount_tax = ls_mwdat-kawrt * lv_tax_rate / 100.
                      READ TABLE ltt_gl_assign ASSIGNING <fs_gl_assign> WITH KEY assign_nr = ls_gl_det-gl_assignment.
                      IF sy-subrc = 0.
                        lv_item = <fs_gl_assign>-item.
                        READ TABLE lt_curr_amt ASSIGNING <fs_curr_amt> WITH  KEY itemno_acc = lv_item.
                        IF sy-subrc = 0.
                          <fs_gl_assign>-base_amt = <fs_gl_assign>-base_amt + lv_amount_tax.
                          lv_amount_doccur = <fs_gl_assign>-base_amt.
*Changes by Gaurav Sharma
*                          IF ls_gl_det-deb_cre = 'H'.
                          <fs_curr_amt>-amt_doccur = lv_amount_doccur.
*                          ELSE.
*                            <fs_curr_amt>-amt_doccur =  lv_amount_doccur  * -1.
*                          ENDIF.
*Changes by Gaurav Sharma
                        ENDIF.
                      ENDIF.
                      lv_item = lv_item_copy + 1.
                      lv_item_copy = lv_item.

                      READ TABLE ltt_gl_tax ASSIGNING <fs_gl_tax> WITH KEY tax_code = ls_gl_det-gl_tax_cd item = lv_item.
                      IF sy-subrc EQ 0.

                        READ TABLE lt_curr_amt ASSIGNING <fs_curr_amt> WITH  KEY itemno_acc = lv_item.
                        IF sy-subrc = 0.
                          <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur + lv_amount_tax.
                          <fs_curr_amt>-amt_base = <fs_curr_amt>-amt_base + lv_amount_tax.
                          <fs_gl_tax>-base_amt = <fs_curr_amt>-amt_base.
                          <fs_gl_tax>-tax_amt =  <fs_curr_amt>-amt_doccur.
                        ENDIF.

                      ELSE.

                        ls_gl_tax-tax_code = ls_gl_det-gl_tax_cd.
                        ls_gl_tax-item = lv_item.
                        ls_gl_tax-tax_amt = lv_amount_tax.
                        ls_gl_tax-base_amt = ls_gl_det-gl_amount.
                        APPEND ls_gl_tax TO ltt_gl_tax.
                        CLEAR: ls_gl_tax.

                        ls_acc_tax-itemno_acc = lv_item.
                        ls_acc_tax-gl_account = ls_mwdat-hkont.
                        ls_acc_tax-acct_key = ls_mwdat-ktosl.
                        ls_acc_tax-cond_key = ls_mwdat-kschl.
                        ls_acc_tax-tax_code = ls_gl_det-gl_tax_cd.
                        ls_acc_tax-tax_country = <ls_data>-tax_rpt_ctry.
                        APPEND ls_acc_tax TO lt_acc_tax.

                        ls_curr_amt-itemno_acc =   ls_acc_tax-itemno_acc. "lv_item.
                        ls_curr_amt-amt_base = lv_amount_tax.
                        ls_curr_amt-amt_doccur = lv_amount_tax.
                        ls_curr_amt-currency = <ls_data>-currency.
                        APPEND ls_curr_amt TO lt_curr_amt.
                        CLEAR: ls_curr_amt.
                      ENDIF.
                    ENDIF.
                  ENDIF.

                  CLEAR: ls_gl_tax.
*CURRENCYAMOUNT

                  SORT lt_curr_amt BY currency itemno_acc.
                  DELETE lt_curr_amt WHERE itemno_acc IS INITIAL.
                  et_currency_amount = lt_curr_amt.

*                  ACCOUNTTAX

                  SORT lt_acc_tax BY itemno_acc.
                  et_account_tax = lt_acc_tax.
                  CLEAR: lv_item, lv_item_copy.
                ENDIF.
                lv_data_index += 1.
              ENDLOOP.
            ENDLOOP.
          ENDIF.
          IF lt_mwdat_cpy[] IS NOT INITIAL.
            LOOP AT lt_acc_tax ASSIGNING <fs_acc_tax> WHERE gl_account IS INITIAL.
              READ TABLE lt_curr_amt ASSIGNING <fs_curr_amt> WITH KEY itemno_acc = <fs_acc_tax>-itemno_acc.
              IF sy-subrc EQ 0.
                CLEAR: <fs_curr_amt>-itemno_acc.
              ENDIF.
              CLEAR: <fs_acc_tax>-itemno_acc.
            ENDLOOP.
            DELETE lt_acc_tax WHERE itemno_acc IS INITIAL.
            DELETE lt_curr_amt WHERE itemno_acc IS INITIAL.
            LOOP AT lt_acc_payable INTO ls_acc_payable.
              READ TABLE lt_curr_amt ASSIGNING  <fs_curr_amt> WITH KEY itemno_acc = ls_acc_payable-itemno_acc.
              IF sy-subrc EQ 0.
                READ TABLE ltt_vendor ASSIGNING <fs_vendor> INDEX 1.
                IF sy-subrc EQ 0.
                  <fs_curr_amt>-amt_doccur = <fs_vendor>-gross_inv_amount.
                ENDIF.
              ENDIF.
            ENDLOOP.
            et_currency_amount = lt_curr_amt.
            et_account_tax = lt_acc_tax.
          ELSE.
            LOOP AT lt_acc_payable INTO ls_acc_payable.
              READ TABLE lt_curr_amt ASSIGNING  <fs_curr_amt> WITH KEY itemno_acc = ls_acc_payable-itemno_acc.
              IF sy-subrc EQ 0.
                IF lv_posting_key EQ '31' AND <fs_curr_amt>-amt_doccur GE 0.
                  <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur * -1.
                ELSEIF lv_posting_key EQ '21' AND <fs_curr_amt>-amt_doccur LE 0.
                  <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur * -1.
                ENDIF.
              ENDIF.
            ENDLOOP.
            et_currency_amount = lt_curr_amt.
          ENDIF.

          CALL FUNCTION 'ZFM_INV_DOC_CHECK' DESTINATION 'NONE'
            EXPORTING
              documentheader = ls_doc_header
              customercpd    = ls_custcpd
            TABLES
              accountgl      = lt_gl_account
              accountpayable = lt_acc_payable
              accounttax     = lt_acc_tax
              currencyamount = lt_curr_amt
              criteria       = lt_criteria
              return         = lt_return
              extension2     = lt_extension
              accountwt      = lt_acct_wt.

          CLEAR: ls_doc_header, ls_custcpd, lt_gl_account, lt_acc_rec, lt_criteria, lt_extension,
          lt_acc_tax, lt_acct_wt, lt_curr_amt, lt_acc_payable, ltt_gl_assign, ltt_gl_tax, lv_amount_doccur, lv_index,
          lv_posting_key.

          READ TABLE lt_return INTO DATA(ls_max_error) WITH  KEY id = 'F5' number = '727'.
          IF sy-subrc = 0.
            DELETE lt_return WHERE type = 'E' AND id = 'F5'  AND number = '727'.

          ENDIF.
          READ TABLE lt_return INTO ls_max_error WITH  KEY id = 'RW' number = '609'.
          IF sy-subrc = 0.
            DELETE lt_return WHERE type = 'E' AND id = 'RW'  AND number = '609'.
          ENDIF.
          READ TABLE lt_return INTO DATA(ls_return)
                    WITH KEY type = 'E'.


          IF sy-subrc EQ 0.
            LOOP AT lt_return INTO ls_return.

              CALL FUNCTION 'MESSAGE_TEXT_BUILD'
                EXPORTING
                  msgid               = ls_return-id
                  msgnr               = ls_return-number
                  msgv1               = ls_return-message_v1
                  msgv2               = ls_return-message_v2
                  msgv3               = ls_return-message_v3
                  msgv4               = ls_return-message_v4
                IMPORTING
                  message_text_output = lv_message.

              ls_message-invoice_id = <fs_data>-invoice_id.
*              ls_message-line_no = <fs_data>-linenumber.
              IF ls_return-type = 'E'.
                ls_message-status = 'Error'.
              ELSEIF ls_return-type = 'W'.
                ls_message-status = 'Warning'.
              ELSEIF ls_return-type = 'A'.
                ls_message-status = 'Terminated'.
              ELSE.
                ls_message-status = 'Success'.
              ENDIF.

              ls_message-code = '1'.
              ls_message-message = lv_message.
              REPLACE '&' WITH TEXT-003 INTO ls_message-message.
              APPEND ls_message TO lt_message.
              READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Error' invoice_id = <fs_data>-invoice_id.
              IF sy-subrc = 0.
                ev_errorcount = ev_errorcount + 1.
                ev_status = 'E'.
                <fs_data>-status = 'E'.
              ENDIF.

              READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Terminated' invoice_id = <fs_data>-invoice_id.
              IF sy-subrc = 0.
                ev_errorcount = ev_errorcount + 1.
                ev_status = 'A'.
                <fs_data>-status = 'A'.
              ENDIF.
              DATA(ls_modify) = <fs_data>.
              MODIFY  ct_data FROM ls_modify TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
            ENDLOOP.

            CLEAR: lt_return.

          ENDIF.

          DELETE lt_data_copy WHERE invoice_id = lv_invoice_id.
          CLEAR: lv_data_index,lv_currency.
        ENDIF.
      ENDLOOP.
    ENDIF.
    SORT lt_message BY invoice_id.
    APPEND LINES OF lt_message TO ct_log.
    CLEAR lt_message.
    SORT ct_log BY invoice_id ASCENDING.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->TRANSFORM_INV_DATA_GL
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CT_DATA                        TYPE        ZINV_CL_BP_GL_USER=>GTT_GR_XL_GL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD transform_inv_data_gl.

    DATA: lv_doc_curr TYPE wrbtr.
    DATA: lv_loc_curr TYPE wrbtr.
    DATA: lv_gp_curr TYPE dmbe2.
    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<fs_data>).
      IF <fs_data>-journal_entry_date IS NOT INITIAL.
        <fs_data>-journal_entry_date = |{ <fs_data>-journal_entry_date+6(4) }{ <fs_data>-journal_entry_date+3(2) }{ <fs_data>-journal_entry_date+0(2) }|.
      ENDIF.
      IF <fs_data>-posting_date IS NOT INITIAL.
        <fs_data>-posting_date = |{ <fs_data>-posting_date+6(4) }{ <fs_data>-posting_date+3(2) }{ <fs_data>-posting_date+0(2) }|.
      ENDIF.

      IF <fs_data>-amt_doc_curr = '7.0000000000000007E-2'.
        lv_doc_curr = '0.07'.
        <fs_data>-amt_doc_curr = lv_doc_curr.
      ENDIF.


      IF <fs_data>-amt_loc_curr  = '7.0000000000000007E-2'.
        lv_loc_curr = '0.07'.
        <fs_data>-amt_loc_curr = lv_loc_curr.
      ENDIF.


      IF <fs_data>-amt_gp_curr   = '7.0000000000000007E-2'.
        lv_gp_curr = '0.07'.
        <fs_data>-amt_gp_curr = lv_gp_curr.
      ENDIF.

      IF <fs_data>-zz1_flightdate_mse IS NOT INITIAL.
        <fs_data>-zz1_flightdate_mse = |{ <fs_data>-zz1_flightdate_mse+6(4) }{ <fs_data>-zz1_flightdate_mse+3(2) }{ <fs_data>-zz1_flightdate_mse+0(2) }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->VALIDATE_INV_DATA_GL
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_STAGE                       TYPE        CHAR15
* | [--->] IV_EXISTING_STATUS             TYPE        CHAR40(optional)
* | [<---] ES_DOCUMENTHEADER              TYPE        BAPIACHE09
* | [<---] ES_CONTRACTHEADER              TYPE        BAPIACCAHD
* | [<---] EV_ERRORCOUNT                  TYPE        INT4
* | [<---] ET_ACCOUNT_GL                  TYPE        BAPIACGL09_TAB
* | [<---] ET_ACCOUNT_RECEIVABLE          TYPE        BAPIACAR09_TAB
* | [<---] ET_ACCOUNT_TAX                 TYPE        BAPIACTX09_TAB
* | [<---] ET_CURRENCY_AMOUNT             TYPE        BAPIACCR09_TAB
* | [<---] EV_STATUS                      TYPE        CHAR1
* | [<---] ET_CRITERIA                    TYPE        BAPIACKEC9_TAB
* | [<---] ET_VALUEFIELD                  TYPE        BAPIACKEV9_TAB
* | [<---] ET_EXTENSION1                  TYPE        BAPIACEXTC_TAB
* | [<---] ET_EXTENSION2                  TYPE        BAPIPAREX_TAB
* | [<---] ET_PAYMENTCARD                 TYPE        BAPIACPC09_TAB
* | [<-->] CT_LOG                         TYPE        ZINV_CL_BP_POST_USER=>GTT_GR_ERROR
* | [<-->] CT_DATA                        TYPE        ZTT_INV_INP_GL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD validate_inv_data_gl.

    TYPES: BEGIN OF lty_vendor,
             documentid       TYPE num10,
             invoicing_party  TYPE string,
             assign_number    TYPE string,
             gross_inv_amount TYPE  wrbtr,
           END OF lty_vendor.

    DATA: ltt_vendor TYPE TABLE OF lty_vendor.

    TYPES: BEGIN OF lty_gl_tax,
             gltaxcd TYPE mwskz,
           END OF lty_gl_tax.

    DATA: ltt_gl_tax TYPE TABLE OF lty_gl_tax.

    TYPES: BEGIN OF lty_gl_assign,
             item      TYPE num10,
             curr_type TYPE curtp,
             base_amt  TYPE wrbtr,
             assign_nr TYPE dzuonr,
             tax_code  TYPE mwskz,
           END OF lty_gl_assign.

    DATA: ltt_gl_assign TYPE TABLE OF lty_gl_assign.

    TYPES: BEGIN OF lty_gl_det,
             documentid            TYPE num10,
             currency              TYPE waers,
             loc_curr              TYPE waers,
             gp_curr               TYPE waers,
             glcompcode            TYPE bukrs,
             glaccount             TYPE hkont,
             glitmtxt              TYPE sgtxt,
             deb_cre               TYPE shkzg,
             amt_doc_curr          TYPE wrbtr,
             amt_loc_curr          TYPE wrbtr,
             amt_gp_curr           TYPE dmbe2,
             gltaxcd               TYPE mwskz,
             glassignment          TYPE dzuonr,
             costcenter            TYPE kostl,
             profitcent            TYPE prctr,
             wbselement            TYPE ps_posid,
             tax_bs_amt            TYPE txbhw,
             business_place        TYPE bupla,
             zz1originmse          TYPE zz1_origin,
             zz1subfleetmse        TYPE zz1_subfleet,
             zz1routemse           TYPE zz1_route,
             zz1tailnumbermse      TYPE zz1_tailnumber,
             zz1flightdatemse      TYPE zz1_flightdate,
             zz1flighttypemse      TYPE zz1_flighttype,
             zz1destinationmse     TYPE zz1_destination,
             zz1bodytypemse        TYPE zz1_bodytype,
             zz1sectormse          TYPE zz1_sector,
             zz1aircrafttypemse    TYPE zz1_aircrafttype,
             zz1flightnumbermse    TYPE zz1_flightnumber,
             zz1flightindicatormse TYPE zz1_flightindicator,
             cbaircrafttype        TYPE yy1_cb_aircrafttype,
             cbpos                 TYPE yy1_cb_pos,
             cbapttaxcode          TYPE yy1_apttaxcode,
             cbtailnumber          TYPE yy1_cb_tailnumber,
             cbaptstation          TYPE yy1_cb_aptstation,
             cbref4                TYPE xblnr,
             cbref5                TYPE xblnr,
             cbref6                TYPE xblnr,
             copa_ind              TYPE char1,
             coding_ind            TYPE char1,
           END OF lty_gl_det.

    TYPES : BEGIN OF lty_tax,
              tax_code TYPE mwskz.
              INCLUDE  TYPE rtax1u15.
    TYPES :  END OF lty_tax.

    TYPES : BEGIN OF lty_tax_cal,
              assign_id   TYPE dzuonr,
              tax_amt     TYPE wrbtr,
              tax_amt_loc TYPE wrbtr,
              tax_amt_gp  TYPE dmbe2,
              db_cre_in   TYPE char1.
    TYPES :  END OF lty_tax_cal.

    TYPES : BEGIN OF lty_tax_excl,
              tax_code TYPE mwskz.
    TYPES :  END OF lty_tax_excl.

    FIELD-SYMBOLS: <fs_curramt> TYPE bapiaccr09.

    DATA: lt_message      TYPE zinv_cl_bp_post_user=>gtt_gr_error,
          ls_message      TYPE zinv_cl_bp_post_user=>gty_gr_error,
          lv_posting_date TYPE sy-datum,
          lv_year         TYPE char4.

    DATA: lv_inv_type    TYPE bapiache09-doc_type,
          ls_doc_header  TYPE bapiache09,
          ls_gl_account  TYPE bapiacgl09,
          lt_gl_account  TYPE TABLE OF  bapiacgl09,
          ls_acc_payable TYPE bapiacap09,
          lt_acc_payable TYPE TABLE OF bapiacap09,
          ls_acc_tax     TYPE bapiactx09,
          lt_acc_tax     TYPE TABLE OF bapiactx09,
          ls_curr_amt    TYPE bapiaccr09,
          lt_curr_amt    TYPE TABLE OF bapiaccr09,
          ls_acct_wt     TYPE  bapiacwt09,
          lt_acct_wt     TYPE TABLE OF bapiacwt09,
          lt_tax_excl    TYPE STANDARD TABLE OF lty_tax_excl,
          ls_tax_excl    TYPE lty_tax_excl,
          lt_acc_rec     TYPE  TABLE OF bapiacar09,
          ls_acc_rec     TYPE  bapiacar09,
          ls_custcpd     TYPE bapiacpa09,
          lt_custcpd     TYPE STANDARD TABLE OF bapiacpa09,
          lt_criteria    TYPE STANDARD TABLE OF bapiackec9,
          ls_extension   TYPE bapiparex,
          lt_extension   TYPE TABLE OF bapiparex,
          ls_out         TYPE bapiache09-obj_key,
          lt_return      TYPE bapiret2_tab,
          lt_gl_det      TYPE TABLE OF lty_gl_det.
    DATA:
      lv_item        TYPE posnr_acc,
      lo_msg         TYPE REF TO /iwbep/if_message_container,
      lv_message     TYPE string,
      gt_mwdat       TYPE STANDARD TABLE OF lty_tax,
      gt_tax_cal     TYPE STANDARD TABLE OF lty_tax_cal,
      gs_tax_cal     TYPE lty_tax_cal,
      gs_mwdat       TYPE lty_tax,
      lv_amt_00      TYPE wrbtr,
      lv_amt_10      TYPE wrbtr,
      lv_amt_30      TYPE dmbe2,
      lv_tax_00      TYPE wrbtr,
      lv_tax_10      TYPE wrbtr,
      lv_tax_30      TYPE dmbe2,
      lv_deb_cre     TYPE c,
      lv_gl          TYPE hkont,
      lv_curr        TYPE waers,
      lv_curr_loc    TYPE waers,
      lv_curr_gp     TYPE waers,
      lv_amount_h_00 TYPE wrbtr,
      lv_amount_h_10 TYPE wrbtr,
      lv_amount_h_30 TYPE dmbe2,
      lv_amount_s_00 TYPE wrbtr,
      lv_amount_s_10 TYPE wrbtr,
      lv_amount_s_30 TYPE dmbe2.

    DATA: lv_lstml         TYPE land1_stml.
    DATA: lv_bukrs         TYPE bukrs.
    DATA: lv_currency      TYPE waers.

    IF ct_data IS NOT INITIAL.
      ev_status = 'S'.

      SORT ct_data BY linenumber documentid.
      DATA(lt_data_copy) = ct_data.

      DATA: lv_blart TYPE blart.
      DATA: lv_zuonr TYPE dzuonr.

      SELECT kokrs,kstar FROM cskb INTO TABLE @DATA(lt_rev_gl) WHERE kokrs = 'PH00'  AND katyp = '11'.
      SELECT code FROM zz1_flightindicator_v  WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltind).
      SELECT code FROM zz1_tailnumber_v       WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_flttailnb).
      SELECT code FROM zz1_aircrafttype_v     WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltartyp).
      SELECT code FROM zz1_flightnumber_v     WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltnb).

      LOOP AT lt_data_copy ASSIGNING FIELD-SYMBOL(<fs_data>).

        DATA(lv_doc_id) = <fs_data>-documentid.
        DATA(lt_data) = lt_data_copy.

        DELETE lt_data WHERE documentid NE lv_doc_id.
*        ****Changes by gaurav Sharma
        DATA(lt_data_tax) = lt_data.
        DATA(lt_data_no_tax) = lt_data.
        DATA(lt_tax_rep_cty) = lt_data.

        DELETE lt_data_tax WHERE gltaxcd IS INITIAL.
        DELETE lt_data_no_tax WHERE gltaxcd IS NOT INITIAL.

        IF <fs_data>-taxrptctry IS NOT INITIAL.
          lv_lstml = <fs_data>-taxrptctry.
        ENDIF.

        IF <fs_data>-compcode IS NOT INITIAL.
          lv_bukrs = <fs_data>-compcode.
        ENDIF.

        IF <fs_data>-currency IS NOT INITIAL.
          lv_currency = <fs_data>-currency.
        ENDIF.

*        IF <fs_data>-taxrptctry IS NOT INITIAL.
        IF lv_lstml IS NOT INITIAL.
          IF ( lt_data_tax IS NOT INITIAL AND lt_data_no_tax IS NOT INITIAL ) OR
             ( <fs_data>-taxrptctry IS NOT INITIAL AND lt_data_tax IS INITIAL ).
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-documentid.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Tax reporting country has been entered. So maintain the tax codes for all the line items '.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            CONTINUE.
*            EXIT.
          ELSEIF lt_data_tax IS INITIAL AND lt_data_no_tax IS NOT INITIAL.
            DATA(lv_no_tax) = abap_true.
          ENDIF.
          REFRESH: lt_data_tax,lt_data_no_tax .
        ENDIF.

        CLEAR: et_account_gl, et_account_tax,
        et_currency_amount, es_documentheader, lv_item.
        lt_gl_det = CORRESPONDING #( lt_data_copy ).

*      sort lt_gl_det by gl_assignment ascending.
        DELETE lt_gl_det WHERE documentid NE <fs_data>-documentid.
        ltt_gl_tax = CORRESPONDING #( lt_gl_det ).
        SORT ltt_gl_tax BY gltaxcd.
        DELETE ADJACENT DUPLICATES FROM ltt_gl_tax.
        DESCRIBE TABLE lt_gl_det LINES DATA(lv_gl_index).

        DATA(lv_total_gl_debit) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                 FOR ls_gl_sum IN lt_gl_det WHERE ( deb_cre = 'S' )
                                 NEXT sum = sum + ls_gl_sum-amt_doc_curr  ) .



        DATA(lv_total_gl_credit) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                FOR ls_gl_sum IN lt_gl_det WHERE ( deb_cre = 'H' )
                                NEXT sum = sum + ls_gl_sum-amt_doc_curr ).

        IF <fs_data>-loc_curr IS NOT INITIAL AND <fs_data>-gp_curr IS NOT INITIAL.
          DATA(lt_gl_det_copy) = lt_gl_det.
          DELETE lt_gl_det_copy WHERE amt_loc_curr IS INITIAL AND amt_gp_curr IS INITIAL.
          DESCRIBE TABLE lt_gl_det_copy LINES DATA(lv_gl_lg_curr).
          IF lv_gl_index NE lv_gl_lg_curr.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-documentid.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Provide the amount for Group and Local Currency for Document Id &'.
            REPLACE '&' WITH <fs_data>-documentid INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            CONTINUE.
*            EXIT.
          ENDIF.

          IF <fs_data>-loc_curr NE 'PHP' OR  <fs_data>-gp_curr NE 'USD'.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-documentid.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Incorrect Group / Local Currency for Document Id &'.
            REPLACE '&' WITH <fs_data>-documentid INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            CONTINUE.
*            EXIT.
          ELSEIF <fs_data>-loc_curr EQ 'PHP' AND  <fs_data>-gp_curr EQ 'USD'.
            DATA(lv_total_gl_loc_d) = REDUCE tslxx9( INIT sum TYPE tslxx9
                              FOR ls_gl_sum IN lt_gl_det WHERE ( deb_cre = 'S' )
                              NEXT sum = sum + ls_gl_sum-amt_loc_curr  ) .

            DATA(lv_total_gl_loc_c) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                    FOR ls_gl_sum IN lt_gl_det WHERE ( deb_cre = 'H' )
                                    NEXT sum = sum + ls_gl_sum-amt_loc_curr ).

            DATA(lv_total_gl_gp_d) = REDUCE tslxx9( INIT sum TYPE tslxx9
                          FOR ls_gl_sum IN lt_gl_det WHERE ( deb_cre = 'S' )
                          NEXT sum = sum + ls_gl_sum-amt_gp_curr  ) .


            DATA(lv_total_gl_gp_c) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                    FOR ls_gl_sum IN lt_gl_det WHERE ( deb_cre = 'H' )
                                    NEXT sum = sum + ls_gl_sum-amt_gp_curr ).

          ENDIF.
        ENDIF.

        IF <fs_data> IS ASSIGNED.
          <fs_data>-status = 'S'.
          <fs_data>-stage = 'Validation'.
          IF <fs_data>-documentid IS INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-documentid.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Document Id is Mandatory'.
            REPLACE '&' WITH TEXT-003 INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            EXIT.
          ENDIF.

          IF lv_total_gl_credit NE lv_total_gl_debit OR lv_total_gl_loc_c NE lv_total_gl_loc_d
            OR lv_total_gl_gp_c NE lv_total_gl_gp_d .
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-documentid.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Total gross amount does not match with Cumulative GL amount for Document id &1'.
            REPLACE '&1' WITH <fs_data>-documentid INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            CONTINUE.
*            EXIT.
          ENDIF.
          lv_posting_date = <fs_data>-postingdate.
          lv_year = lv_posting_date+0(4).
          lv_blart = <fs_data>-jnlenttype.
          DATA(lv_acc_type) = <fs_data>-acc_type.

          SELECT SINGLE bukrs, gjahr, h_blart, koart, zuonr
           FROM bseg INTO @DATA(ls_bseg)
            WHERE bukrs = @<fs_data>-compcode AND
                  gjahr = @lv_year AND
                  h_blart = @lv_blart AND
                  koart = @lv_acc_type AND
                  zuonr = @<fs_data>-glassignment.

          IF ls_bseg IS NOT INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-documentid.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Duplicate invoice entry &1'.
            REPLACE '&' WITH ls_bseg-zuonr INTO ls_message-message.
            APPEND ls_message TO lt_message.

            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            CONTINUE.
*            EXIT.
          ENDIF.

*          Cost Center Validation
          READ TABLE lt_gl_det INTO DATA(ls_cost_cent) WITH KEY costcenter = ' '.
          IF sy-subrc IS INITIAL.
            IF ls_cost_cent-wbselement IS INITIAL AND ls_cost_cent-profitcent IS INITIAL .
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Cost Center or WBS is Mandatory for invoice id &'.
              REPLACE '&' WITH <fs_data>-documentid INTO ls_message-message.
              APPEND ls_message TO lt_message.
              CLEAR: lv_message.

              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
              CONTINUE.
*            EXIT.
            ENDIF.
          ENDIF.

          "COPA and Coding Block validation
          DATA(lv_copa_cb) = abap_true.
          IF <fs_data>-zz1tailnumbermse IS NOT INITIAL.
            READ TABLE lt_flttailnb INTO DATA(ls_flttailnb) WITH KEY code = <fs_data>-zz1tailnumbermse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect TailNumber & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1tailnumbermse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1aircrafttypemse IS NOT INITIAL.
            READ TABLE lt_fltartyp INTO DATA(ls_fltartyp) WITH KEY code = <fs_data>-zz1aircrafttypemse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Aircraft Type & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1aircrafttypemse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1flightnumbermse IS NOT INITIAL.
            READ TABLE lt_fltnb INTO DATA(ls_fltnb) WITH KEY code = <fs_data>-zz1flightnumbermse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Flight Number & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1flightnumbermse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1flightindicatormse IS NOT INITIAL.
            READ TABLE lt_fltind INTO DATA(ls_fltind) WITH KEY code = <fs_data>-zz1flightindicatormse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Flight Indicator & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1flightindicatormse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-cbaircrafttype IS NOT INITIAL.
            READ TABLE lt_fltartyp INTO ls_fltartyp WITH KEY code = <fs_data>-cbaircrafttype.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Coding Block Aircraft Type & for Line Item &'.
              REPLACE '&' WITH <fs_data>-cbaircrafttype INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING status WHERE documentid = <fs_data>-documentid.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-cbtailnumber IS NOT INITIAL.
            READ TABLE lt_flttailnb INTO ls_flttailnb WITH KEY code = <fs_data>-cbtailnumber.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-documentid.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Coding Block TailNumber & for Line Item &'.
              REPLACE '&' WITH <fs_data>-cbtailnumber INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.
          IF lv_copa_cb = abap_false.
            CONTINUE.
          ENDIF.
          IF lt_message[] IS NOT INITIAL.
            CONTINUE.
          ENDIF.
          ls_doc_header-bus_act       = 'RFBV'.
          ls_doc_header-doc_status    = '2'.
          ls_doc_header-username      =  sy-uname.
          ls_doc_header-doc_date      = <fs_data>-jnlentdate.
          ls_doc_header-doc_type      = <fs_data>-jnlenttype.
          ls_doc_header-comp_code     = <fs_data>-compcode.
          ls_doc_header-header_txt    = <fs_data>-docuhdrtext.
          ls_doc_header-pstng_date    = <fs_data>-postingdate.
          ls_doc_header-fisc_year     = <fs_data>-postingdate+0(4).
          ls_doc_header-ref_doc_no    = <fs_data>-refdocnum.


          MOVE-CORRESPONDING ls_doc_header TO es_documentheader.

          DATA(lv_index) = 0.
          READ TABLE lt_data INTO DATA(ls_data) WITH KEY documentid = <fs_data>-documentid.
          IF sy-subrc = 0.
            DATA(lv_data_index) = sy-tabix.

            LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>) FROM lv_data_index.
              IF <ls_data>-documentid NE <fs_data>-documentid.
                EXIT.
              ENDIF.

              CLEAR: lv_index.
              LOOP AT lt_gl_det INTO DATA(ls_gl_det) WHERE glassignment = <ls_data>-glassignment.
* GLAccount
                lv_index = lv_index + 1.

                DESCRIBE TABLE lt_gl_account LINES DATA(lv_gl_acc_index).
                lv_item =  lv_gl_acc_index + 1.

                ls_gl_account-itemno_acc = lv_item.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_gl_det-glaccount
                  IMPORTING
                    output = ls_gl_account-gl_account.

                DATA(lv_rev_gl) = ls_gl_account-gl_account.

                IF ls_gl_det-costcenter IS NOT INITIAL.
                  READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                           costcenter = ls_gl_det-costcenter
                                                                           alloc_nmbr = ls_gl_det-glassignment
                                                                           item_text = ls_gl_det-glitmtxt.
                  IF sy-subrc NE 0.
                    ls_gl_account-costcenter = ls_gl_det-costcenter.
                    ls_gl_account-item_text   = ls_gl_det-glitmtxt.
                    ls_gl_account-comp_code = ls_gl_det-glcompcode.
                    ls_gl_account-fisc_year = lv_year.
                    ls_gl_account-tax_code = ls_gl_det-gltaxcd.
                    ls_gl_account-alloc_nmbr = ls_gl_det-glassignment.
                    APPEND ls_gl_account TO lt_gl_account.
                    SORT lt_gl_account BY itemno_acc.

                    et_account_gl = lt_gl_account.

                  ENDIF.
                ELSEIF ls_gl_det-profitcent IS NOT INITIAL.
                  READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                           profit_ctr = ls_gl_det-profitcent
                                                                           alloc_nmbr = ls_gl_det-glassignment
                                                                           item_text = ls_gl_det-glitmtxt.

                  IF sy-subrc NE 0.
                    ls_gl_account-profit_ctr  = ls_gl_det-profitcent.
                    ls_gl_account-item_text   = ls_gl_det-glitmtxt.
                    ls_gl_account-comp_code = ls_gl_det-glcompcode.
                    ls_gl_account-fisc_year = lv_year.
                    ls_gl_account-tax_code = ls_gl_det-gltaxcd.
                    ls_gl_account-alloc_nmbr = ls_gl_det-glassignment.
                    APPEND ls_gl_account TO lt_gl_account.
                    SORT lt_gl_account BY itemno_acc.

                    et_account_gl = lt_gl_account.

                  ENDIF.
                ELSEIF ls_gl_det-wbselement IS NOT INITIAL.
                  READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                           wbs_element = ls_gl_det-wbselement
                                                                           alloc_nmbr = ls_gl_det-glassignment
                                                                           item_text = ls_gl_det-glitmtxt.
                  IF sy-subrc NE 0.
                    ls_gl_account-wbs_element = ls_gl_det-wbselement.
                    ls_gl_account-item_text   = ls_gl_det-glitmtxt.
                    ls_gl_account-comp_code = ls_gl_det-glcompcode.
                    ls_gl_account-fisc_year = lv_year.
                    ls_gl_account-tax_code = ls_gl_det-gltaxcd.
                    ls_gl_account-alloc_nmbr = ls_gl_det-glassignment.
                    APPEND ls_gl_account TO lt_gl_account.
                    SORT lt_gl_account BY itemno_acc.
                    et_account_gl = lt_gl_account.
                  ENDIF.
                ENDIF.
                IF ls_gl_account IS INITIAL.
                  CLEAR: ls_gl_det-copa_ind, ls_gl_det-coding_ind.
                ENDIF.
                CLEAR ls_gl_account.
*                  GL Account

*                Criteria- CoPA

                IF ls_gl_det-copa_ind = abap_true.

                  lt_criteria = VALUE #( BASE lt_criteria[]
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1originmse          fieldname = 'ZZ1_ORIGIN_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1subfleetmse        fieldname = 'ZZ1_SUBFLEET_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1routemse           fieldname = 'ZZ1_ROUTE_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1tailnumbermse      fieldname = 'ZZ1_TAILNUMBER_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1flightdatemse      fieldname = 'ZZ1_FLIGHTDATE_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1flighttypemse      fieldname = 'ZZ1_FLIGHTTYPE_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1destinationmse     fieldname = 'ZZ1_DESTINATION_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1bodytypemse        fieldname = 'ZZ1_BODYTYPE_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1sectormse          fieldname = 'ZZ1_SECTOR_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1aircrafttypemse    fieldname = 'ZZ1_AIRCRAFTTYPE_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1flightnumbermse    fieldname = 'ZZ1_FLIGHTNUMBER_MSE' )
                                          ( itemno_acc = lv_item character = ls_gl_det-zz1flightindicatormse fieldname = 'ZZ1_FLIGHTINDICATOR_MSE' )
                                          ).
                  CLEAR:lv_rev_gl.
                  SORT lt_criteria BY itemno_acc.
                  et_criteria = lt_criteria.
                ENDIF.
                READ TABLE lt_rev_gl INTO DATA(ls_rev_gl) WITH KEY kstar = lv_rev_gl.
                IF sy-subrc EQ 0.
                  APPEND INITIAL LINE TO lt_criteria ASSIGNING FIELD-SYMBOL(<fs_criteria>).
                  <fs_criteria>-itemno_acc = lv_item.
                  <fs_criteria>-fieldname = 'PRCTR'.
                  <fs_criteria>-character = ls_gl_det-profitcent.
                  SORT lt_criteria BY itemno_acc.
                  APPEND <fs_criteria> TO et_criteria.
                  SORT et_criteria BY itemno_acc.
                ENDIF.
                CLEAR:lv_rev_gl,ls_rev_gl.
* Criteria-CoPA

* Extensions2
                IF ls_gl_det-coding_ind = abap_true.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_AIRCRAFTTYPE_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbaircrafttype.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_POS_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbpos.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_APTTAXCODE_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbapttaxcode.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_TAILNUMBER_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbtailnumber.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_APTSTATION_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbaptstation.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_REFERENCE4_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbref4.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_REFERENCE5_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbref5.
                  APPEND ls_extension TO lt_extension.

                  ls_extension-structure = 'ACCIT'.
                  ls_extension-valuepart1 = lv_item.
                  ls_extension-valuepart2 = 'YY1_CB_REFERENCE6_COB'.
                  ls_extension-valuepart3 = ls_gl_det-cbref6.
                  APPEND ls_extension TO lt_extension.
                  SORT lt_extension BY valuepart1.
                  et_extension2 = lt_extension.
                ENDIF.

                DESCRIBE TABLE lt_gl_account LINES lv_gl_acc_index.
                DATA(lv_item_tax) = lv_gl_acc_index + 1.
              ENDLOOP.
* Extensions2
              lv_data_index += 1.
              DELETE lt_data WHERE glassignment = ls_gl_det-glassignment.
            ENDLOOP.
          ENDIF.
*** Account Tax

          LOOP AT ltt_gl_tax INTO DATA(ls_gl_tax).
            DATA: lt_mwdat         TYPE fm_tt_rtax1u15.

            IF lv_bukrs IS NOT INITIAL AND lv_lstml IS NOT INITIAL AND
               lv_currency IS NOT INITIAL.

              CALL FUNCTION 'Z_CALCULATE_TAX_FRM_NET'
                EXPORTING
                  i_bukrs                 = lv_bukrs
                  i_mwskz                 = ls_gl_tax-gltaxcd
                  i_waers                 = lv_currency
                  i_wrbtr                 = 100
                  i_lstml                 = lv_lstml
                TABLES
                  t_mwdat                 = lt_mwdat
                EXCEPTIONS
                  bukrs_not_found         = 1
                  country_not_found       = 2
                  mwskz_not_defined       = 3
                  mwskz_not_valid         = 4
                  account_not_found       = 5
                  different_discount_base = 6
                  different_tax_base      = 7
                  txjcd_not_valid         = 8
                  not_found               = 9
                  ktosl_not_found         = 10
                  kalsm_not_found         = 11
                  parameter_error         = 12
                  knumh_not_found         = 13
                  kschl_not_found         = 14
                  unknown_error           = 15
                  OTHERS                  = 16.
              IF sy-subrc <> 0.

              ELSE.

                LOOP AT lt_mwdat INTO DATA(ls_mwdat).
                  READ TABLE lt_acc_tax TRANSPORTING NO FIELDS WITH KEY tax_code = ls_gl_tax-gltaxcd acct_key = ls_mwdat-ktosl.
                  IF sy-subrc NE 0.
                    ls_acc_tax-itemno_acc = lv_item_tax.
                    ls_acc_tax-tax_code = ls_gl_tax-gltaxcd.
                    ls_acc_tax-gl_account = ls_mwdat-hkont.
                    ls_acc_tax-acct_key = ls_mwdat-ktosl.
                    ls_acc_tax-cond_key = ls_mwdat-kschl.
                    ls_acc_tax-tax_country = <fs_data>-taxrptctry.
                    APPEND ls_acc_tax TO lt_acc_tax.
                    lv_item_tax = lv_item_tax + 1.
                  ENDIF.
                  MOVE-CORRESPONDING ls_mwdat TO gs_mwdat.
                  gs_mwdat-tax_code = ls_gl_tax-gltaxcd.
                  APPEND gs_mwdat TO gt_mwdat.

                  IF ls_mwdat-msatz LT 0.
                    ls_tax_excl-tax_code = ls_gl_tax-gltaxcd.
                    APPEND ls_tax_excl TO lt_tax_excl.
                  ENDIF.

                  CLEAR:gs_mwdat,ls_tax_excl.
                ENDLOOP.
              ENDIF.
            ENDIF.
          ENDLOOP.
          SORT lt_acc_tax BY itemno_acc gl_account acct_key cond_key.
          DELETE ADJACENT DUPLICATES FROM lt_acc_tax.
          et_account_tax = lt_acc_tax.
          CLEAR: lv_item, lv_item_tax.
*                  ACCOUNTTAX

          READ TABLE lt_data_copy INTO ls_data WITH KEY documentid = lv_doc_id.
          IF  sy-subrc EQ 0.
            IF ls_data-currency IS NOT INITIAL AND
               ls_data-loc_curr IS INITIAL AND
               ls_data-gp_curr IS INITIAL.
              IF ls_data-amt_doc_curr IS NOT INITIAL AND
              ls_data-amt_loc_curr IS INITIAL AND
              ls_data-amt_gp_curr IS INITIAL.
                DATA(lv_no_curr) = abap_true.
              ENDIF.
            ENDIF.
          ENDIF.

          IF lt_acc_tax IS NOT INITIAL.
            DATA(lt_data_1) = lt_data_copy.
            LOOP AT lt_data_1 INTO ls_data WHERE documentid = lv_doc_id.
              IF ls_data-gltaxcd IS NOT INITIAL.
                READ TABLE lt_tax_excl INTO ls_tax_excl WITH KEY tax_code = ls_data-gltaxcd.
                IF sy-subrc NE 0.
                  READ TABLE gt_mwdat INTO gs_mwdat WITH KEY tax_code = ls_data-gltaxcd .
                  IF sy-subrc EQ 0.
                    gs_tax_cal-assign_id = ls_data-glassignment.
                    gs_tax_cal-db_cre_in = ls_data-deb_cre.
                    gs_tax_cal-tax_amt = ls_data-amt_doc_curr * ( gs_mwdat-msatz / 100 ).
                    gs_tax_cal-tax_amt_gp = ls_data-amt_gp_curr * ( gs_mwdat-msatz / 100 ).
                    gs_tax_cal-tax_amt_loc = ls_data-amt_loc_curr * ( gs_mwdat-msatz / 100 ).
                    APPEND gs_tax_cal TO gt_tax_cal.
                    CLEAR:gs_tax_cal.
                  ENDIF.
                ENDIF.
              ENDIF.
              CLEAR:ls_data.
            ENDLOOP.
            SORT gt_tax_cal BY assign_id db_cre_in.
            DATA(gt_tax_cal_s) = gt_tax_cal.
            DATA(gt_tax_cal_h) = gt_tax_cal.
            DATA(ls_tax_cal) = gs_tax_cal.
            REFRESH:gt_tax_cal_s[],gt_tax_cal_h[].

            CLEAR:ls_tax_cal.
            DATA(gt_tax_cal_1) = gt_tax_cal[].
            DELETE gt_tax_cal_1 WHERE db_cre_in EQ 'H'.

            LOOP AT gt_tax_cal_1 INTO gs_tax_cal WHERE db_cre_in = 'S'.
              ls_tax_cal-tax_amt = ls_tax_cal-tax_amt + gs_tax_cal-tax_amt.
              ls_tax_cal-tax_amt_gp = ls_tax_cal-tax_amt_gp + gs_tax_cal-tax_amt_gp.
              ls_tax_cal-tax_amt_loc = ls_tax_cal-tax_amt_loc + gs_tax_cal-tax_amt_loc.
              AT END OF assign_id.
                ls_tax_cal-assign_id = gs_tax_cal-assign_id.
                ls_tax_cal-db_cre_in =  gs_tax_cal-db_cre_in.
                IF ls_tax_cal-tax_amt = 0 AND ls_tax_cal-tax_amt_gp = 0 AND
                  ls_tax_cal-tax_amt_loc = 0.
                  CONTINUE.
                ELSE.
                  APPEND ls_tax_cal TO gt_tax_cal_s.
                ENDIF.
                CLEAR:ls_tax_cal.
              ENDAT.
            ENDLOOP.

            CLEAR:ls_tax_cal,gt_tax_cal_1.
            gt_tax_cal_1 = gt_tax_cal[].
            DELETE gt_tax_cal_1 WHERE db_cre_in EQ 'S'.

            LOOP AT gt_tax_cal_1 INTO gs_tax_cal WHERE db_cre_in = 'H'.
              ls_tax_cal-tax_amt = ls_tax_cal-tax_amt + gs_tax_cal-tax_amt.
              ls_tax_cal-tax_amt_gp = ls_tax_cal-tax_amt_gp + gs_tax_cal-tax_amt_gp.
              ls_tax_cal-tax_amt_loc = ls_tax_cal-tax_amt_loc + gs_tax_cal-tax_amt_loc.
              AT END OF assign_id.
                ls_tax_cal-assign_id = gs_tax_cal-assign_id.
                ls_tax_cal-db_cre_in =  gs_tax_cal-db_cre_in.
                IF ls_tax_cal-tax_amt = 0 AND ls_tax_cal-tax_amt_gp = 0 AND
                  ls_tax_cal-tax_amt_loc = 0.
                  CONTINUE.
                ELSE.
                  APPEND ls_tax_cal TO gt_tax_cal_h.
                ENDIF.
                CLEAR:ls_tax_cal.
              ENDAT.
            ENDLOOP.

            IF gt_tax_cal_h IS NOT INITIAL.
              LOOP AT gt_tax_cal_h INTO ls_tax_cal.
                READ TABLE lt_data_1 ASSIGNING FIELD-SYMBOL(<fs_data_1>) WITH KEY documentid = lv_doc_id
                                                                                  deb_cre = 'S'
                                                                                  glassignment = ls_tax_cal-assign_id.
                IF sy-subrc EQ 0.
                  <fs_data_1>-amt_doc_curr = <fs_data_1>-amt_doc_curr + ls_tax_cal-tax_amt.
                  <fs_data_1>-amt_loc_curr = <fs_data_1>-amt_loc_curr + ls_tax_cal-tax_amt_loc.
                  <fs_data_1>-amt_gp_curr = <fs_data_1>-amt_loc_curr +  ls_tax_cal-tax_amt_gp.
                ENDIF.
              ENDLOOP.

            ENDIF.

            IF gt_tax_cal_s IS NOT INITIAL.
              LOOP AT gt_tax_cal_s INTO ls_tax_cal.
                READ TABLE lt_data_1 ASSIGNING <fs_data_1> WITH KEY documentid = lv_doc_id
                                                                       deb_cre = 'H'
                                                                  glassignment = ls_tax_cal-assign_id.
                IF sy-subrc EQ 0.
                  <fs_data_1>-amt_doc_curr = <fs_data_1>-amt_doc_curr + ls_tax_cal-tax_amt.
                  <fs_data_1>-amt_loc_curr = <fs_data_1>-amt_loc_curr + ls_tax_cal-tax_amt_loc.
                  <fs_data_1>-amt_gp_curr = <fs_data_1>-amt_gp_curr +  ls_tax_cal-tax_amt_gp.
                ENDIF.
              ENDLOOP.
            ENDIF.

          ENDIF.
          IF lt_data_1 IS INITIAL.
            lt_data_1[] = lt_data_copy[].
          ENDIF.

          LOOP AT lt_gl_account INTO ls_gl_account.
            CLEAR:lv_gl.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
              EXPORTING
                input  = ls_gl_account-gl_account
              IMPORTING
                output = lv_gl.

            CONDENSE lv_gl.

            LOOP AT lt_data_1 INTO ls_data WHERE glaccount = lv_gl AND
                                                 costcenter = ls_gl_account-costcenter AND
                                                 glassignment = ls_gl_account-alloc_nmbr AND
                                                 profitcent = ls_gl_account-profit_ctr AND
                                                 wbselement = ls_gl_account-wbs_element AND
                                                 documentid = lv_doc_id AND
                                                 glitmtxt = ls_gl_account-item_text.
              IF ls_data-deb_cre EQ 'H'.
                lv_amt_00 = lv_amt_00 + ( ls_data-amt_doc_curr * -1 ).
                lv_amt_10 = lv_amt_10 + ( ls_data-amt_loc_curr * -1 ).
                lv_amt_30 = lv_amt_30 + ( ls_data-amt_gp_curr * -1 ).
              ELSE.
                lv_amt_00 = lv_amt_00 + ls_data-amt_doc_curr .
                lv_amt_10 = lv_amt_10 + ls_data-amt_loc_curr.
                lv_amt_30 = lv_amt_30 + ls_data-amt_gp_curr .
              ENDIF.
              IF lv_curr IS INITIAL.
                lv_curr = ls_data-currency.
              ENDIF.
              IF lv_curr_loc IS INITIAL.
                lv_curr_loc = ls_data-loc_curr.
              ENDIF.
              IF lv_curr_gp IS INITIAL.
                lv_curr_gp = ls_data-gp_curr.
              ENDIF.
            ENDLOOP.

            CLEAR:ls_curr_amt.
            ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
            ls_curr_amt-currency = lv_curr.
            ls_curr_amt-amt_doccur = lv_amt_00.
            ls_curr_amt-amt_doccur_long = lv_amt_00.
            IF lv_no_curr EQ abap_false.
              ls_curr_amt-curr_type = '00'.
            ENDIF.
            APPEND ls_curr_amt TO lt_curr_amt.

            IF lv_no_curr EQ abap_false.
              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
              ls_curr_amt-currency = 'PHP'.
              ls_curr_amt-amt_doccur = lv_amt_10.
              ls_curr_amt-amt_doccur_long = lv_amt_10.
              ls_curr_amt-curr_type = '10'.
              APPEND ls_curr_amt TO lt_curr_amt.

              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
              ls_curr_amt-currency = 'USD'.
              ls_curr_amt-amt_doccur = lv_amt_30.
              ls_curr_amt-amt_doccur_long = lv_amt_30.
              ls_curr_amt-curr_type = '30'.
              APPEND ls_curr_amt TO lt_curr_amt.
            ENDIF.
            CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_gl_account,lv_gl,ls_data.
          ENDLOOP.
          CLEAR: lv_curr,lv_curr_loc,lv_curr_gp.

          LOOP AT lt_acc_tax INTO ls_acc_tax.
            READ TABLE gt_mwdat INTO gs_mwdat WITH KEY hkont = ls_acc_tax-gl_account
                                                       tax_code = ls_acc_tax-tax_code.
            IF sy-subrc EQ 0.
              LOOP AT lt_data_1 INTO ls_data WHERE gltaxcd = ls_acc_tax-tax_code AND
*                                                      deb_cre = lv_deb_cre AND
                                                      documentid = lv_doc_id.

                IF ls_data-deb_cre EQ 'H'.
                  lv_amt_00 = lv_amt_00 + ( ls_data-amt_doc_curr * -1 ).
                  lv_amt_10 = lv_amt_10 + ( ls_data-amt_loc_curr * -1 ).
                  lv_amt_30 = lv_amt_30 + ( ls_data-amt_gp_curr * -1 ).
                ELSE.
                  lv_amt_00 = lv_amt_00 + ls_data-amt_doc_curr .
                  lv_amt_10 = lv_amt_10 + ls_data-amt_loc_curr.
                  lv_amt_30 = lv_amt_30 + ls_data-amt_gp_curr .
                ENDIF.
                IF lv_curr IS INITIAL.
                  lv_curr = ls_data-currency.
                ENDIF.
                IF lv_curr_loc IS INITIAL.
                  lv_curr_loc = ls_data-loc_curr.
                ENDIF.
                IF lv_curr_gp IS INITIAL.
                  lv_curr_gp = ls_data-gp_curr.
                ENDIF.
                IF lv_deb_cre IS INITIAL.
                  lv_deb_cre = ls_data-deb_cre.
                ENDIF.
              ENDLOOP.
              READ TABLE lt_tax_excl INTO ls_tax_excl WITH KEY tax_code = ls_acc_tax-tax_code .
              IF sy-subrc NE 0.
                lv_tax_00 = lv_amt_00 * ( gs_mwdat-msatz / 100 ).
                lv_tax_10 = lv_amt_10 * ( gs_mwdat-msatz / 100 ).
                lv_tax_30 = lv_amt_30 * ( gs_mwdat-msatz / 100 ).
              ELSE.
                IF gs_mwdat-msatz GT 0.
                  lv_tax_00 = lv_amt_00 * ( gs_mwdat-msatz / 100 ).
                  lv_tax_10 = lv_amt_10 * ( gs_mwdat-msatz / 100 ).
                  lv_tax_30 = lv_amt_30 * ( gs_mwdat-msatz / 100 ).
                ELSE.
                  LOOP AT gt_mwdat INTO gs_mwdat WHERE tax_code = ls_tax_excl-tax_code AND
                                                        msatz GT 0.
                    IF gs_mwdat-msatz IS NOT INITIAL AND gs_mwdat-msatz GT 0.
                      EXIT.
                    ENDIF.
                  ENDLOOP.
                  lv_amt_00 = lv_amt_00 * -1.
                  lv_amt_10 = lv_amt_10 * -1.
                  lv_amt_30 = lv_amt_30 * -1.
                  lv_tax_00 = lv_amt_00 * ( gs_mwdat-msatz / 100 ).
                  lv_tax_10 = lv_amt_10 * ( gs_mwdat-msatz / 100 ) .
                  lv_tax_30 = lv_amt_30 * ( gs_mwdat-msatz / 100 ).
                ENDIF.
              ENDIF.

              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
              IF lv_curr IS INITIAL.
                READ TABLE lt_data_1 INTO ls_data WITH KEY documentid = lv_doc_id.
                IF sy-subrc EQ 0.
                  lv_curr = ls_data-currency.
                ENDIF.
              ENDIF.
              ls_curr_amt-currency = lv_curr.
              IF lv_deb_cre = 'S'.
                ls_curr_amt-amt_base = lv_amt_00.
              ELSE.
                ls_curr_amt-amt_base = lv_tax_00.
              ENDIF.
              ls_curr_amt-amt_doccur = lv_tax_00.
              ls_curr_amt-amt_doccur_long = lv_tax_00.
              IF lv_no_curr EQ abap_false.
                ls_curr_amt-curr_type = '00'.
              ENDIF.
              APPEND ls_curr_amt TO lt_curr_amt.

              IF lv_no_curr EQ abap_false.
                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
*              ls_curr_amt-currency = lv_curr_loc.
                ls_curr_amt-currency = 'PHP'.
                IF lv_deb_cre = 'S'.
                  ls_curr_amt-amt_base = lv_amt_10.
                ELSE.
                  ls_curr_amt-amt_base = lv_tax_10.
                ENDIF.
                ls_curr_amt-amt_doccur = lv_tax_10.
                ls_curr_amt-amt_doccur_long = lv_tax_10.
                ls_curr_amt-curr_type = '10'.
                APPEND ls_curr_amt TO lt_curr_amt.

                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
*              ls_curr_amt-currency = lv_curr_gp.
                ls_curr_amt-currency = 'USD'.
                IF lv_deb_cre = 'S'.
                  ls_curr_amt-amt_base = lv_amt_30.
                ELSE.
                  ls_curr_amt-amt_base = lv_tax_30.
                ENDIF.
                ls_curr_amt-amt_doccur = lv_tax_30.
                ls_curr_amt-amt_doccur_long = lv_tax_30.
                ls_curr_amt-curr_type = '30'.
                APPEND ls_curr_amt TO lt_curr_amt.
              ENDIF.
              CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_acc_tax,lv_gl,ls_data,
              lv_tax_00,lv_tax_10,lv_tax_30,gs_mwdat,lv_deb_cre.
            ENDIF.
          ENDLOOP.

          CLEAR: lv_curr,lv_curr_loc,lv_curr_gp,lv_no_curr.
          IF  lt_curr_amt IS NOT INITIAL.
            et_currency_amount[] = lt_curr_amt[] .
          ENDIF.

          CALL FUNCTION 'ZFM_INV_DOC_CHECK' DESTINATION 'NONE'
            EXPORTING
              documentheader = ls_doc_header
            TABLES
              accountgl      = lt_gl_account
              accounttax     = lt_acc_tax
              currencyamount = lt_curr_amt
              criteria       = lt_criteria
              return         = lt_return
              extension2     = lt_extension.

          CLEAR: ls_doc_header, ls_custcpd, lt_gl_account, lt_acc_rec,lt_curr_amt, lt_criteria, lt_extension,
          lt_acc_tax, lt_acct_wt, lt_curr_amt, lt_acc_payable, ltt_gl_assign, ltt_gl_tax,lv_index, lt_data_tax, lt_data_no_tax.

          READ TABLE lt_return INTO DATA(ls_max_error) WITH  KEY id = 'F5' number = '727'.
          IF sy-subrc = 0.
            DELETE lt_return WHERE type = 'E' AND id = 'F5'  AND number = '727'.
          ENDIF.
          READ TABLE lt_return INTO ls_max_error WITH  KEY id = 'RW' number = '609'.
          IF sy-subrc = 0.
            DELETE lt_return WHERE type = 'E' AND id = 'RW'  AND number = '609'.
          ENDIF.
          READ TABLE lt_return INTO DATA(ls_return)
                    WITH KEY type = 'E'.

          IF sy-subrc EQ 0.

            LOOP AT lt_return INTO ls_return.

              CALL FUNCTION 'MESSAGE_TEXT_BUILD'
                EXPORTING
                  msgid               = ls_return-id
                  msgnr               = ls_return-number
                  msgv1               = ls_return-message_v1
                  msgv2               = ls_return-message_v2
                  msgv3               = ls_return-message_v3
                  msgv4               = ls_return-message_v4
                IMPORTING
                  message_text_output = lv_message.

              ls_message-invoice_id = <fs_data>-documentid.
              IF ls_return-type = 'E'.
                ls_message-status = 'Error'.
              ELSEIF ls_return-type = 'W'.
                ls_message-status = 'Warning'.
              ELSEIF ls_return-type = 'W'.
                ls_message-status = 'Terminated'.
              ELSE.
                ls_message-status = 'Success'.
              ENDIF.

              ls_message-code = '1'.
              ls_message-message = lv_message.
              REPLACE '&' WITH TEXT-003 INTO ls_message-message.
              APPEND ls_message TO lt_message.
              READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Error' invoice_id = <fs_data>-documentid.
              IF sy-subrc = 0.
                ev_errorcount = ev_errorcount + 1.
                ev_status = 'E'.
                <fs_data>-status = 'E'.
              ENDIF.
              READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Terminated' invoice_id = <fs_data>-documentid.
              IF sy-subrc = 0.
                ev_errorcount = ev_errorcount + 1.
                ev_status = 'A'.
                <fs_data>-status = 'A'.
              ENDIF.
              DATA(ls_modify) = <fs_data>.
              MODIFY  ct_data FROM ls_modify TRANSPORTING  status WHERE documentid = <fs_data>-documentid.
            ENDLOOP.
            CLEAR: lt_return.
          ENDIF.
*          DELETE lt_data_copy FROM 1 TO lv_data_index - 1.
          DELETE lt_data_copy WHERE documentid = lv_doc_id.

          CLEAR: lv_data_index.
        ENDIF.
      ENDLOOP.
    ENDIF.

    APPEND LINES OF lt_message TO ct_log.
    CLEAR lt_message.
    SORT ct_log BY invoice_id status ASCENDING.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->VALIDATE_INV_DATA_AR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_STAGE                       TYPE        CHAR15(optional)
* | [--->] IV_EXISTING_STATUS             TYPE        CHAR40(optional)
* | [<---] ES_DOCUMENTHEADER              TYPE        BAPIACHE09
* | [<---] ES_CUSTOMERCPD                 TYPE        BAPIACPA09
* | [<---] ES_CONTRACTHEADER              TYPE        BAPIACCAHD
* | [<---] EV_ERRORCOUNT                  TYPE        INT4
* | [<---] EV_STATUS                      TYPE        CHAR1
* | [<---] ET_ACCOUNT_GL                  TYPE        BAPIACGL09_TAB
* | [<---] ET_ACCOUNT_RECEIVABLE          TYPE        BAPIACAR09_TAB
* | [<---] ET_ACCOUNT_PAYABLE             TYPE        BAPIACAP09_TAB
* | [<---] ET_ACCOUNT_TAX                 TYPE        BAPIACTX09_TAB
* | [<---] ET_CURRENCY_AMOUNT             TYPE        BAPIACCR09_TAB
* | [<---] ET_CRITERIA                    TYPE        BAPIACKEC9_TAB
* | [<---] ET_VALUEFIELD                  TYPE        BAPIACKEV9_TAB
* | [<---] ET_EXTENSION1                  TYPE        BAPIACEXTC_TAB
* | [<---] ET_EXTENSION2                  TYPE        BAPIPAREX_TAB
* | [<---] ET_PAYMENTCARD                 TYPE        BAPIACPC09_TAB
* | [<---] ET_ACCOUNTWT                   TYPE        BAPIACWT09_TAB
* | [<-->] CT_LOG                         TYPE        ZINV_CL_BP_POST_USER=>GTT_GR_ERROR(optional)
* | [<-->] CT_DATA                        TYPE        ZSTT_INV_INP_AR(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD validate_inv_data_ar.


    TYPES: BEGIN OF lty_vendor,
             invoice_id       TYPE num10,
             posting_key      TYPE bschl,
             invoicing_party  TYPE string,
             assign_number    TYPE string,
             gross_inv_amount TYPE  wrbtr,
             amt_loc_curr     TYPE  wrbtr,
             amt_gp_curr      TYPE  dmbe2,

           END OF lty_vendor.

    DATA: ltt_vendor TYPE TABLE OF lty_vendor.

    TYPES: BEGIN OF lty_gl_tax_code,
             gl_tax_cd TYPE mwskz,
           END OF lty_gl_tax_code.

    TYPES: BEGIN OF lty_gl_tax,
             item     TYPE num10,
             tax_code TYPE mwskz,
             base_amt TYPE wrbtr,
             tax_amt  TYPE wrbtr,
           END OF lty_gl_tax.

    DATA: ltt_gl_tax TYPE TABLE OF lty_gl_tax.
    DATA: ltt_gl_tax_code TYPE TABLE OF lty_gl_tax_code.

    TYPES : BEGIN OF lty_tax_cal,
              assign_id   TYPE dzuonr,
              tax_amt     TYPE wrbtr,
              tax_amt_loc TYPE wrbtr,
              tax_amt_gp  TYPE dmbe2,
              db_cre_in   TYPE char1.
    TYPES :  END OF lty_tax_cal.
    TYPES : BEGIN OF lty_tax,
              tax_code TYPE mwskz.
              INCLUDE  TYPE rtax1u15.
    TYPES :  END OF lty_tax.

    TYPES: BEGIN OF lty_gl_det,
             invoice_id              TYPE num10,
             gl_comp_code            TYPE bukrs,
             gl_account              TYPE hkont,
             gl_itm_txt              TYPE sgtxt,
             deb_cre                 TYPE shkzg,

*  @Semantics.amount.currencyCode : 'zstr_gl_account.gl_curr'
             gl_amt_doc_curr         TYPE wrbtr,
             gl_amt_loc_curr         TYPE wrbtr,
             gl_amt_gp_curr          TYPE dmbe2,
             gl_tax_cd               TYPE mwskz,
             gl_assignment           TYPE dzuonr,
             cost_center             TYPE kostl,
             profit_cent             TYPE prctr,
             wbs_element             TYPE zinv_ps_posid,
*  @Semantics.amount.currencyCode : 'zstr_gl_account.gl_curr'
             tax_bs_amt              TYPE txbhw,
             business_place          TYPE bupla,
             zz1_origin_mse          TYPE zz1_origin,
             zz1_subfleet_mse        TYPE zz1_subfleet,
             zz1_route_mse           TYPE zz1_route,
             zz1_tailnumber_mse      TYPE zz1_tailnumber,
             zz1_flightdate_mse      TYPE zz1_flightdate,
             zz1_flighttype_mse      TYPE zz1_flighttype,
             zz1_destination_mse     TYPE zz1_destination,
             zz1_bodytype_mse        TYPE zz1_bodytype,
             zz1_sector_mse          TYPE zz1_sector,
             zz1_aircrafttype_mse    TYPE zz1_aircrafttype,
             zz1_flightnumber_mse    TYPE zz1_flightnumber,
             zz1_flightindicator_mse TYPE zz1_flightindicator,
             cb_aircrafttype         TYPE yy1_cb_aircrafttype,
             cb_pos                  TYPE yy1_cb_pos,
             cb_apttaxcode           TYPE yy1_apttaxcode,
             cb_tailnumber           TYPE yy1_cb_tailnumber,
             cb_aptstation           TYPE yy1_cb_aptstation,
             cb_ref4                 TYPE xblnr,
             cb_ref5                 TYPE xblnr,
             cb_ref6                 TYPE xblnr,
             copa_ind                TYPE char1,
             cb_ind                  TYPE char1,
           END OF lty_gl_det.

    FIELD-SYMBOLS: <fs_curramt> TYPE bapiaccr09.

    DATA: lt_message      TYPE zinv_cl_bp_post_user=>gtt_gr_error,
          ls_message      TYPE zinv_cl_bp_post_user=>gty_gr_error,
          lv_posting_date TYPE sy-datum,
          lv_year         TYPE char4.

    DATA: lv_inv_type       TYPE bapiache09-doc_type,
          ls_doc_header     TYPE bapiache09,
          ls_gl_account     TYPE bapiacgl09,
          lt_gl_account     TYPE TABLE OF  bapiacgl09,
          ls_acc_payable    TYPE bapiacap09,
          lt_acc_payable    TYPE TABLE OF bapiacap09,
          ls_acc_tax        TYPE bapiactx09,
          lt_acc_tax        TYPE TABLE OF bapiactx09,
          ls_curr_amt       TYPE bapiaccr09,
          lt_curr_amt       TYPE TABLE OF bapiaccr09,
          ls_acct_wt        TYPE  bapiacwt09,
          lt_acct_wt        TYPE TABLE OF bapiacwt09,
          lt_acc_receivable TYPE  TABLE OF bapiacar09,
          ls_acc_receivable TYPE  bapiacar09,
          ls_custcpd        TYPE bapiacpa09,
          lt_custcpd        TYPE STANDARD TABLE OF bapiacpa09,
          lt_criteria       TYPE STANDARD TABLE OF bapiackec9,
          ls_extension      TYPE bapiparex,
          lt_extension      TYPE TABLE OF bapiparex,
          ls_out            TYPE bapiache09-obj_key,
          lt_return         TYPE bapiret2_tab,
          lt_gl_det         TYPE TABLE OF lty_gl_det,
          lt_gl_tax_code    TYPE TABLE OF lty_gl_tax_code,
          lv_total_gross    TYPE wrbtr,
          lv_total_gl_amt   TYPE wrbtr. " zstr_gl_account.
    DATA:
      lv_item        TYPE posnr_acc,
      lv_item_gl     TYPE posnr_acc,
      lo_msg         TYPE REF TO /iwbep/if_message_container,
      lv_message     TYPE string,
      gs_mwdat       TYPE lty_tax,
      gt_mwdat       TYPE STANDARD TABLE OF lty_tax,
      gt_tax_cal     TYPE STANDARD TABLE OF lty_tax_cal,
      gs_tax_cal     TYPE lty_tax_cal,
      lv_amt_00      TYPE wrbtr,
      lv_amt_10      TYPE wrbtr,
      lv_amt_30      TYPE dmbe2,
      lv_tax_00      TYPE wrbtr,
      lv_tax_rec     TYPE wrbtr,
      lv_tax_10      TYPE wrbtr,
      lv_tax_30      TYPE dmbe2,
      lv_deb_cre     TYPE c,
      lv_item_tax    TYPE posnr_acc,
      lv_curr        TYPE waers,
      lv_curr_loc    TYPE waers,
      lv_curr_gp     TYPE waers,
      lv_amount_h_00 TYPE wrbtr,
      lv_amount_h_10 TYPE wrbtr,
      lv_amount_h_30 TYPE dmbe2,
      lv_amount_s_00 TYPE wrbtr,
      lv_amount_s_10 TYPE wrbtr,
      lv_amount_s_30 TYPE dmbe2.

    DATA: lt_mwdat         TYPE fm_tt_rtax1u15.
    DATA: lv_lstml         TYPE land1_stml.
    DATA: lv_bukrs         TYPE bukrs.
    DATA: lv_currency      TYPE waers.

    IF ct_data IS NOT INITIAL.

      ev_status = 'S'.

      DATA(lt_data_copy) = ct_data.
      SORT ct_data BY invoice_id ASCENDING.
      DATA: lv_blart TYPE blart.
      DATA: lv_zuonr TYPE dzuonr.

      SELECT kokrs,kstar FROM cskb INTO TABLE @DATA(lt_rev_gl) WHERE kokrs = 'PH00'  AND katyp = '11'.
      SELECT code FROM zz1_flightindicator_v  WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltind).
      SELECT code FROM zz1_tailnumber_v       WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_flttailnb).
      SELECT code FROM zz1_aircrafttype_v     WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltartyp).
      SELECT code FROM zz1_flightnumber_v     WHERE isdisabled IS INITIAL INTO TABLE @DATA(lt_fltnb).

      LOOP AT lt_data_copy ASSIGNING FIELD-SYMBOL(<fs_data>).
        DATA(lt_data) = lt_data_copy.
        DATA(lv_invoice_id) = <fs_data>-invoice_id.
        DELETE lt_data WHERE invoice_id NE lv_invoice_id.


        DATA(lt_data_tax) = lt_data.
        DATA(lt_data_no_tax) = lt_data.

        DELETE lt_data_tax WHERE gl_tax_cd IS INITIAL.
        DELETE lt_data_no_tax WHERE gl_tax_cd IS NOT INITIAL.

        IF <fs_data>-tax_rpt_ctry IS NOT INITIAL.
          lv_lstml = <fs_data>-tax_rpt_ctry.
        ENDIF.

        IF <fs_data>-comp_code IS NOT INITIAL.
          lv_bukrs = <fs_data>-comp_code.
        ENDIF.

        IF <fs_data>-currency IS NOT INITIAL.
          lv_currency = <fs_data>-currency.
        ENDIF.

        CLEAR: et_account_gl, et_account_payable, et_account_tax,
        et_currency_amount, es_documentheader,es_customercpd, lv_item.
        lt_gl_det = CORRESPONDING #( lt_data_copy ).
        DELETE lt_gl_det WHERE invoice_id NE <fs_data>-invoice_id.

        DESCRIBE TABLE lt_gl_det LINES DATA(lv_gl_index).
        LOOP AT lt_gl_det ASSIGNING FIELD-SYMBOL(<fs_gl_det>).
          IF <fs_gl_det>-deb_cre EQ 'H'.
            <fs_gl_det>-gl_amt_doc_curr = <fs_gl_det>-gl_amt_doc_curr * -1.
            <fs_gl_det>-gl_amt_loc_curr = <fs_gl_det>-gl_amt_loc_curr * -1.
            <fs_gl_det>-gl_amt_gp_curr = <fs_gl_det>-gl_amt_gp_curr * -1.
          ENDIF.
        ENDLOOP.

        lv_total_gl_amt = REDUCE tslxx9( INIT sum TYPE tslxx9
                                 FOR ls_gl_sum IN lt_gl_det
                                 NEXT sum = sum + ls_gl_sum-gl_amt_doc_curr ).

        ltt_vendor = CORRESPONDING #( lt_data_copy ).

        SORT ltt_vendor BY invoicing_party assign_number ASCENDING.
        DELETE ADJACENT DUPLICATES FROM ltt_vendor.
        DELETE ltt_vendor WHERE assign_number IS INITIAL.
        DELETE ltt_vendor WHERE invoice_id NE <fs_data>-invoice_id.
        DESCRIBE TABLE ltt_vendor LINES DATA(lv_acc_pay).
        LOOP AT ltt_vendor ASSIGNING FIELD-SYMBOL(<fs_vendor>).
          IF <fs_vendor>-posting_key EQ '11'.
            <fs_vendor>-gross_inv_amount = <fs_vendor>-gross_inv_amount * -1.
            <fs_vendor>-amt_loc_curr = <fs_vendor>-amt_loc_curr * -1.
            <fs_vendor>-amt_gp_curr = <fs_vendor>-amt_gp_curr * -1.
          ENDIF.
        ENDLOOP.
        lv_total_gross = REDUCE tslxx9( INIT sum TYPE tslxx9
                                    FOR ls_vendor IN ltt_vendor
                                    NEXT sum = sum + ls_vendor-gross_inv_amount ).

        ltt_gl_tax_code = CORRESPONDING #( lt_gl_det ).
        SORT ltt_gl_tax_code BY gl_tax_cd.
        DELETE ADJACENT DUPLICATES FROM ltt_gl_tax_code.

        IF <fs_data>-loc_curr IS NOT INITIAL AND <fs_data>-gp_curr IS NOT INITIAL.
          IF <fs_data>-amt_loc_curr IS INITIAL OR <fs_data>-amt_gp_curr IS INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Provide the amount for Group and Local Currency for Document Id &'.
            REPLACE '&' WITH <fs_data>-invoice_id INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*              EXIT.
            CONTINUE.

          ENDIF.

          IF <fs_data>-loc_curr NE 'PHP' OR  <fs_data>-gp_curr NE 'USD'.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Incorrect Group / Local Currency for Document Id &'.
            REPLACE '&' WITH <fs_data>-invoice_id INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*              EXIT.
            CONTINUE.
          ELSEIF <fs_data>-loc_curr EQ 'PHP' AND  <fs_data>-gp_curr EQ 'USD'.

            DATA(lv_total_gl_amt_lc) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                     FOR ls_gl_sum IN lt_gl_det
                                     NEXT sum = sum + ls_gl_sum-gl_amt_loc_curr ).


            DATA(lv_total_gl_amt_gc) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                     FOR ls_gl_sum IN lt_gl_det
                                     NEXT sum = sum + ls_gl_sum-gl_amt_gp_curr ).

            DATA(lv_total_gross_lc) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                             FOR ls_vendor IN ltt_vendor
                                             NEXT sum = sum + ls_vendor-amt_loc_curr ).


            DATA(lv_total_gross_gc) = REDUCE tslxx9( INIT sum TYPE tslxx9
                                        FOR ls_vendor IN ltt_vendor
                                        NEXT sum = sum + ls_vendor-amt_gp_curr ).

          ENDIF.
        ENDIF.

        lt_gl_tax_code = CORRESPONDING #( lt_gl_det ).
        SORT lt_gl_tax_code BY gl_tax_cd.
        DELETE ADJACENT DUPLICATES FROM lt_gl_tax_code.
        DESCRIBE TABLE lt_gl_tax_code LINES DATA(lv_gl_tc_index).

        IF <fs_data> IS ASSIGNED.
          <fs_data>-status = 'S'.
          <fs_data>-stage = 'Validation'.
          IF <fs_data>-invoice_id IS INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Invoice Id is Mandatory'.
            REPLACE '&' WITH TEXT-003 INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*              EXIT.
            CONTINUE.

          ENDIF.

*          Cost Center Validation
          READ TABLE lt_gl_det INTO DATA(ls_cost_cent) WITH KEY cost_center = ' '.
          IF sy-subrc IS INITIAL.
            IF ls_cost_cent-wbs_element IS INITIAL  AND ls_cost_cent-profit_cent IS INITIAL .
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Cost Center or WBS is Mandatory for invoice id &'.
              REPLACE '&' WITH <fs_data>-invoice_id INTO ls_message-message.
              APPEND ls_message TO lt_message.
              CLEAR: lv_message.

              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*              EXIT.
              CONTINUE.
            ENDIF.
          ENDIF.

          lv_total_gross = abs( lv_total_gross ).
          lv_total_gl_amt = abs( lv_total_gl_amt ).
          lv_total_gl_amt_lc = abs( lv_total_gl_amt_lc ).
          lv_total_gross_lc = abs( lv_total_gross_lc ).
          lv_total_gl_amt_gc = abs( lv_total_gl_amt_gc ).
          lv_total_gross_gc = abs( lv_total_gross_gc ).

          IF lv_total_gross NE lv_total_gl_amt  OR lv_total_gl_amt_lc NE lv_total_gross_lc
            OR lv_total_gl_amt_gc NE lv_total_gross_gc .
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Total gross amount does not match with Cumulative GL amount for invoice id &1'.
            REPLACE '&1' WITH <fs_data>-invoice_id INTO ls_message-message.
*            REPLACE '&2' WITH <fs_data>-gl_assignment INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*              EXIT.
            CONTINUE.
          ENDIF.
          lv_posting_date = <fs_data>-posting_date.
          lv_year = lv_posting_date+0(4).
          lv_blart = <fs_data>-document_type.
          DATA(lv_acc_type) = <fs_data>-acc_type.

          SELECT SINGLE bukrs, gjahr, h_blart, koart, zuonr
           FROM bseg INTO @DATA(ls_bseg)
            WHERE bukrs = @<fs_data>-comp_code AND
                  gjahr = @lv_year AND
                  h_blart = @lv_blart AND
                  koart = @lv_acc_type AND
                  zuonr = @<fs_data>-assign_number.

          IF ls_bseg IS NOT INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Duplicate invoice entry &1'.
            REPLACE '&' WITH ls_bseg-zuonr INTO ls_message-message.
            APPEND ls_message TO lt_message.

            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
*              EXIT.
            CONTINUE.
          ENDIF.

          "COPA and Coding Block validation
          DATA(lv_copa_cb) = abap_true.
          IF <fs_data>-zz1_tailnumber_mse IS NOT INITIAL.
            READ TABLE lt_flttailnb INTO DATA(ls_flttailnb) WITH KEY code = <fs_data>-zz1_tailnumber_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect TailNumber & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_tailnumber_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1_aircrafttype_mse IS NOT INITIAL.
            READ TABLE lt_fltartyp INTO DATA(ls_fltartyp) WITH KEY code = <fs_data>-zz1_aircrafttype_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Aircraft Type & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_aircrafttype_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1_flightnumber_mse IS NOT INITIAL.
            READ TABLE lt_fltnb INTO DATA(ls_fltnb) WITH KEY code = <fs_data>-zz1_flightnumber_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Flight Number & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_flightnumber_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-zz1_flightindicator_mse IS NOT INITIAL.
            READ TABLE lt_fltind INTO DATA(ls_fltind) WITH KEY code = <fs_data>-zz1_flightindicator_mse.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Flight Indicator & for Line Item &'.
              REPLACE '&' WITH <fs_data>-zz1_flightindicator_mse INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-cb_aircrafttype IS NOT INITIAL.
            READ TABLE lt_fltartyp INTO ls_fltartyp WITH KEY code = <fs_data>-cb_aircrafttype.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Coding Block Aircraft Type & for Line Item &'.
              REPLACE '&' WITH <fs_data>-cb_aircrafttype INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.

          IF <fs_data>-cb_tailnumber IS NOT INITIAL.
            READ TABLE lt_flttailnb INTO ls_flttailnb WITH KEY code = <fs_data>-cb_tailnumber.
            IF sy-subrc NE 0.
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Incorrect Coding Block TailNumber & for Line Item &'.
              REPLACE '&' WITH <fs_data>-cb_tailnumber INTO ls_message-message.
              REPLACE '&' WITH <fs_data>-linenumber INTO ls_message-message.
              APPEND ls_message TO lt_message.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              lv_copa_cb = abap_false.
            ENDIF.
          ENDIF.
          IF lv_copa_cb = abap_false.
            CONTINUE.
          ENDIF.

          IF lt_message[] IS NOT INITIAL.
            CONTINUE.
          ENDIF.
          ls_doc_header-bus_act       = 'RFBU'.
          ls_doc_header-username      = sy-uname.
          ls_doc_header-doc_date      = <fs_data>-document_date."sy-datum.   "pc INVOICE date
          ls_doc_header-doc_type      = <fs_data>-document_type.   " Document Type   "EKKO-BSART
          ls_doc_header-comp_code     = <fs_data>-comp_code." Company code
          ls_doc_header-header_txt    = <fs_data>-docu_hdr_text.
          ls_doc_header-pstng_date    = <fs_data>-posting_date.
          ls_doc_header-fisc_year     = <fs_data>-posting_date+0(4).
          ls_doc_header-ref_doc_no    = <fs_data>-reference.

          MOVE-CORRESPONDING ls_doc_header TO es_documentheader.

          DATA(lv_index) = 1.
          READ TABLE lt_data INTO DATA(ls_data) WITH KEY invoice_id = <fs_data>-invoice_id.
          IF sy-subrc = 0.
            DATA(lv_data_index) = sy-tabix.

            LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>) FROM lv_data_index.
              IF <ls_data>-invoice_id NE <fs_data>-invoice_id.
                EXIT.
              ENDIF.

*           ACCOUNTPAYABLE
              IF <ls_data>-invoicing_party IS NOT INITIAL.

                DESCRIBE TABLE lt_acc_receivable LINES DATA(lv_acc_pay_count).

                lv_item = lv_acc_pay_count + 1.
                ls_acc_receivable-itemno_acc = lv_item.
                ls_acc_receivable-comp_code = <ls_data>-comp_code.
                ls_acc_receivable-bline_date = <ls_data>-baseline_date.
                ls_acc_receivable-pmnt_block = <ls_data>-payment_block_key.
                ls_acc_receivable-paymt_ref = <ls_data>-payment_ref.
                ls_acc_receivable-bank_id = <ls_data>-short_key_hsb.
                ls_acc_receivable-pymt_meth = <ls_data>-payment_method.
                ls_acc_receivable-partner_bk = <ls_data>-part_bank_type.
                ls_acc_receivable-housebankacctid = <ls_data>-id_acc_det.
                ls_acc_receivable-item_text = <ls_data>-item_text.
                ls_acc_receivable-businessplace = <ls_data>-business_place.
                ls_acc_receivable-ref_key_1 = <ls_data>-ref_key1.
                ls_acc_receivable-ref_key_2 = <ls_data>-ref_key2.
                ls_acc_receivable-ref_key_3 = <ls_data>-ref_key3.

                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = <ls_data>-terms_payment
                  IMPORTING
                    output = ls_acc_receivable-pmnttrms.

                ls_acc_receivable-customer = <ls_data>-invoicing_party.

                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = <ls_data>-invoicing_party
                  IMPORTING
                    output = ls_acc_receivable-customer.

                ls_acc_receivable-alloc_nmbr = <ls_data>-assign_number.

                APPEND ls_acc_receivable      TO lt_acc_receivable.

                CLEAR ls_acc_receivable.
                SORT lt_acc_receivable BY itemno_acc.
                et_account_receivable = lt_acc_receivable.

**Withholding Tax
                IF <ls_data>-withold_tax_code IS NOT INITIAL AND <ls_data>-withold_tax_type IS NOT INITIAL.
                  DESCRIBE TABLE lt_acct_wt LINES DATA(lv_wt_count).

                  lv_item = lv_wt_count + 1.
                  ls_acct_wt-itemno_acc = lv_item.
                  ls_acct_wt-wt_code = <ls_data>-withold_tax_code.
                  ls_acct_wt-wt_type = <ls_data>-withold_tax_type.
* Document Currency
                  IF <ls_data>-withold_tax_base IS NOT INITIAL.
                    ls_acct_wt-man_amt_tc = <ls_data>-withold_tax_amount_dc.
                    ls_acct_wt-bas_amt_tc = <ls_data>-withold_tax_base.
                  ELSE.
                    ls_acct_wt-bas_amt_tc = <ls_data>-gross_inv_amount.
                  ENDIF.

*                  Local Currency
                  IF <ls_data>-loc_curr IS NOT INITIAL.
                    IF <ls_data>-withold_tax_base_cc IS NOT INITIAL.
                      ls_acct_wt-man_amt_lc = <ls_data>-wt_tax_amt_cc.
                      ls_acct_wt-bas_amt_lc = <ls_data>-withold_tax_base_cc.
                    ELSE.
                      ls_acct_wt-bas_amt_lc = <ls_data>-amt_loc_curr.
                    ENDIF.
                  ENDIF.

                  APPEND ls_acct_wt  TO lt_acct_wt.
                  SORT lt_acct_wt BY itemno_acc.
                  et_accountwt = lt_acct_wt.

                  CLEAR: ls_acct_wt,lv_item.
                ENDIF.
* Withholding tax

                CLEAR ls_acc_payable.

                IF <ls_data>-name IS NOT INITIAL.
                  ls_custcpd-name = <ls_data>-name.
                  ls_custcpd-city = <ls_data>-city.
                  ls_custcpd-country = <ls_data>-country.
                  ls_custcpd-bank_acct = <ls_data>-bank_acc.
                  ls_custcpd-bank_no = <ls_data>-bank_key.
                  ls_custcpd-bank_ctry = <ls_data>-bank_reg.
                  ls_custcpd-swift_code = <fs_data>-swift_cd.
                  MOVE-CORRESPONDING ls_custcpd TO es_customercpd.
                ENDIF.
              ENDIF.
* ACCOUNTPAYABLE

              LOOP AT lt_gl_det INTO DATA(ls_gl_det) WHERE gl_assignment = <ls_data>-assign_number.
* GLAccount
                lv_index = sy-tabix.

                DESCRIBE TABLE lt_gl_account LINES DATA(lv_gl_acc_index).
                lv_item = lv_acc_pay + lv_gl_acc_index + 1.

                READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_det-gl_account.

                IF sy-subrc NE 0.

                  ls_gl_account-itemno_acc = lv_item.
                  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                    EXPORTING
                      input  = ls_gl_det-gl_account
                    IMPORTING
                      output = ls_gl_account-gl_account.

                  DATA(lv_rev_gl) = ls_gl_account-gl_account.
                  DATA(lv_add_ext) = abap_false.

                  IF ls_gl_det-cost_center IS NOT INITIAL.
                    READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                             costcenter = ls_gl_det-cost_center
                                                                             item_text = ls_gl_det-gl_itm_txt.
                    IF sy-subrc NE 0.
                      ls_gl_account-costcenter = ls_gl_det-cost_center."<ls_data>-cost_center.
                      ls_gl_account-item_text   = ls_gl_det-gl_itm_txt."<ls_data>-gl_itm_txt.
                      ls_gl_account-comp_code = ls_gl_det-gl_comp_code. "<ls_data>-comp_code.
                      ls_gl_account-fisc_year = lv_year.
                      ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                      ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                      APPEND ls_gl_account TO lt_gl_account.
                      SORT lt_gl_account BY itemno_acc.

                      et_account_gl = lt_gl_account.

                    ENDIF.
                  ELSEIF ls_gl_det-profit_cent IS NOT INITIAL.
                    READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                             profit_ctr = ls_gl_det-profit_cent
                                                                             item_text = ls_gl_det-gl_itm_txt.

                    IF sy-subrc NE 0.
*
                      ls_gl_account-profit_ctr  = ls_gl_det-profit_cent.
                      ls_gl_account-item_text   = ls_gl_det-gl_itm_txt."<ls_data>-gl_itm_txt.
                      ls_gl_account-comp_code = ls_gl_det-gl_comp_code. "<ls_data>-comp_code.
                      ls_gl_account-fisc_year = lv_year.
                      ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                      ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                      APPEND ls_gl_account TO lt_gl_account.
                      SORT lt_gl_account BY itemno_acc.

                      et_account_gl = lt_gl_account.

                    ENDIF.
                  ELSEIF ls_gl_det-wbs_element IS NOT INITIAL.
                    READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                             wbs_element = ls_gl_det-wbs_element
                                                                             item_text = ls_gl_det-gl_itm_txt.
                    IF sy-subrc NE 0.
                      ls_gl_account-wbs_element = ls_gl_det-wbs_element.
                      ls_gl_account-item_text   = ls_gl_det-gl_itm_txt."<ls_data>-gl_itm_txt.
                      ls_gl_account-comp_code = ls_gl_det-gl_comp_code. "<ls_data>-comp_code.
                      ls_gl_account-fisc_year = lv_year.
                      ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                      ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                      APPEND ls_gl_account TO lt_gl_account.
                      SORT lt_gl_account BY itemno_acc.
                      et_account_gl = lt_gl_account.
                    ENDIF.
                  ENDIF.
                  IF ls_gl_account IS INITIAL.
                    CLEAR: ls_gl_det-copa_ind, ls_gl_det-cb_ind.
                  ENDIF.
                  IF ls_gl_account-comp_code IS NOT INITIAL.
                    lv_add_ext = abap_true.
                  ENDIF.
                  CLEAR ls_gl_account.
*                  GL Account

*                Criteria- CoPA
                  IF lv_add_ext = abap_true.
                    IF ls_gl_det-copa_ind = abap_true.
                      READ TABLE lt_criteria TRANSPORTING NO FIELDS WITH KEY itemno_acc = lv_item.
                      IF sy-subrc <> 0.
                        lt_criteria = VALUE #( BASE lt_criteria[]
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_origin_mse          fieldname = 'ZZ1_ORIGIN_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_subfleet_mse        fieldname = 'ZZ1_SUBFLEET_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_route_mse           fieldname = 'ZZ1_ROUTE_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_tailnumber_mse      fieldname = 'ZZ1_TAILNUMBER_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_flightdate_mse      fieldname = 'ZZ1_FLIGHTDATE_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_flighttype_mse      fieldname = 'ZZ1_FLIGHTTYPE_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_destination_mse     fieldname = 'ZZ1_DESTINATION_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_bodytype_mse        fieldname = 'ZZ1_BODYTYPE_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_sector_mse          fieldname = 'ZZ1_SECTOR_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_aircrafttype_mse    fieldname = 'ZZ1_AIRCRAFTTYPE_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_flightnumber_mse    fieldname = 'ZZ1_FLIGHTNUMBER_MSE' )
                                                ( itemno_acc = lv_item character = ls_gl_det-zz1_flightindicator_mse fieldname = 'ZZ1_FLIGHTINDICATOR_MSE' )
                                                ).
                        SORT lt_criteria BY itemno_acc.
                        et_criteria = lt_criteria.
                      ENDIF.
                    ENDIF.
                    READ TABLE lt_rev_gl INTO DATA(ls_rev_gl) WITH KEY kstar = lv_rev_gl.
                    IF sy-subrc EQ 0.
                      APPEND INITIAL LINE TO lt_criteria ASSIGNING FIELD-SYMBOL(<fs_criteria>).
                      <fs_criteria>-itemno_acc = lv_item.
                      <fs_criteria>-fieldname = 'PRCTR'.
                      <fs_criteria>-character = ls_gl_det-profit_cent.
                      SORT lt_criteria BY itemno_acc.
                      APPEND <fs_criteria> TO et_criteria.
                      SORT et_criteria BY itemno_acc.
                    ENDIF.
                    CLEAR:lv_rev_gl,ls_rev_gl.
* Criteria-CoPA

* Extensions2
                    IF ls_gl_det-cb_ind = abap_true.
                      READ TABLE lt_extension TRANSPORTING NO FIELDS WITH KEY valuepart1 = lv_item.
                      IF sy-subrc <> 0.
                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'BUPLA'.
                        ls_extension-valuepart3 = <fs_data>-business_place.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_AIRCRAFTTYPE_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_aircrafttype.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_POS_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_pos.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_APTTAXCODE_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_apttaxcode.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_TAILNUMBER_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_tailnumber.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_APTSTATION_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_aptstation.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_REFERENCE4_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_ref4.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_REFERENCE5_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_ref5.
                        APPEND ls_extension TO lt_extension.

                        ls_extension-structure = 'ACCIT'.
                        ls_extension-valuepart1 = lv_item.
                        ls_extension-valuepart2 = 'YY1_CB_REFERENCE6_COB'.
                        ls_extension-valuepart3 = ls_gl_det-cb_ref6.
                        APPEND ls_extension TO lt_extension.
                        SORT lt_extension BY valuepart1.
                        et_extension2 = lt_extension.
                      ENDIF.
                    ENDIF.
                  ENDIF.
*                   Extensions2
                ENDIF.
                DESCRIBE TABLE lt_gl_account LINES lv_gl_acc_index.
                READ TABLE lt_gl_account INTO DATA(ls_gl_account_1) INDEX lv_gl_acc_index.
*                DATA(lv_item_tax) = lv_gl_acc_index + 1.
                lv_item_tax = ls_gl_account_1-itemno_acc + 1.
              ENDLOOP.
              lv_data_index += 1.
*              DELETE lt_data WHERE gl_assignment = ls_gl_det-gl_assignment.
            ENDLOOP.
          ENDIF.

          LOOP AT ltt_gl_tax_code INTO DATA(ls_gl_tax).

            IF lv_bukrs IS NOT INITIAL AND lv_lstml IS NOT INITIAL AND
               lv_currency IS NOT INITIAL.

              CALL FUNCTION 'Z_CALCULATE_TAX_FRM_NET'
                EXPORTING
                  i_bukrs                 = lv_bukrs
                  i_mwskz                 = ls_gl_tax-gl_tax_cd
                  i_waers                 = lv_currency
                  i_wrbtr                 = 100
                  i_lstml                 = lv_lstml
                TABLES
                  t_mwdat                 = lt_mwdat
                EXCEPTIONS
                  bukrs_not_found         = 1
                  country_not_found       = 2
                  mwskz_not_defined       = 3
                  mwskz_not_valid         = 4
                  account_not_found       = 5
                  different_discount_base = 6
                  different_tax_base      = 7
                  txjcd_not_valid         = 8
                  not_found               = 9
                  ktosl_not_found         = 10
                  kalsm_not_found         = 11
                  parameter_error         = 12
                  knumh_not_found         = 13
                  kschl_not_found         = 14
                  unknown_error           = 15
                  OTHERS                  = 16.
              IF sy-subrc <> 0.

              ELSE.

                LOOP AT lt_mwdat INTO DATA(ls_mwdat).
                  READ TABLE lt_acc_tax TRANSPORTING NO FIELDS WITH KEY tax_code = ls_gl_tax-gl_tax_cd acct_key = ls_mwdat-ktosl.
                  IF sy-subrc NE 0.
                    ls_acc_tax-itemno_acc = lv_item_tax.
                    ls_acc_tax-tax_code = ls_gl_tax-gl_tax_cd.
                    ls_acc_tax-gl_account = ls_mwdat-hkont.
                    ls_acc_tax-acct_key = ls_mwdat-ktosl.
                    ls_acc_tax-cond_key = ls_mwdat-kschl.
                    ls_acc_tax-tax_country = <fs_data>-tax_rpt_ctry.
                    APPEND ls_acc_tax TO lt_acc_tax.
                    lv_item_tax = lv_item_tax + 1.
                  ENDIF.
                  MOVE-CORRESPONDING ls_mwdat TO gs_mwdat.
                  gs_mwdat-tax_code = ls_gl_tax-gl_tax_cd.
                  APPEND gs_mwdat TO gt_mwdat.
                  CLEAR:gs_mwdat.
                ENDLOOP.
              ENDIF.
            ENDIF.
          ENDLOOP.
          SORT lt_acc_tax BY itemno_acc gl_account acct_key cond_key.
          DELETE ADJACENT DUPLICATES FROM lt_acc_tax.
          et_account_tax = lt_acc_tax.
          CLEAR: lv_item, lv_item_tax.
*                  ACCOUNTTAX

          READ TABLE lt_data_copy INTO ls_data WITH KEY invoice_id = lv_invoice_id.
          IF  sy-subrc EQ 0.
            IF ls_data-currency IS NOT INITIAL AND
               ls_data-loc_curr IS INITIAL AND
               ls_data-gp_curr IS INITIAL.
              IF ls_data-gross_inv_amount IS NOT INITIAL AND
              ls_data-amt_loc_curr IS INITIAL AND
              ls_data-amt_gp_curr IS INITIAL.
                DATA(lv_no_curr) = abap_true.
              ENDIF.
            ENDIF.
          ENDIF.
          DATA lv_customer TYPE kunnr.

          IF lt_acc_receivable IS NOT INITIAL.
            DATA(lt_data_rec) = lt_data_copy.
            LOOP AT lt_acc_receivable INTO ls_acc_receivable.
              CLEAR:lv_customer.
              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
                EXPORTING
                  input  = ls_acc_receivable-customer
                IMPORTING
                  output = lv_customer.

              CONDENSE lv_customer.

              LOOP AT lt_data_rec INTO ls_data WHERE   invoice_id = lv_invoice_id AND
                                                       invoicing_party = lv_customer AND
                                                       comp_code = ls_acc_receivable-comp_code AND
                                                       assign_number = ls_acc_receivable-alloc_nmbr.
*                IF ls_data-deb_cre EQ 'H'.
                IF ls_data-posting_key EQ '11'.
                  lv_amt_00 = lv_amt_00 + ( ls_data-gross_inv_amount * -1 ).
                  lv_amt_10 = lv_amt_10 + ( ls_data-amt_loc_curr * -1 ).
                  lv_amt_30 = lv_amt_30 + ( ls_data-amt_gp_curr * -1 ).
                ELSEIF ls_data-posting_key EQ '01'.
                  lv_amt_00 = lv_amt_00 + ls_data-gross_inv_amount .
                  lv_amt_10 = lv_amt_10 + ls_data-amt_loc_curr.
                  lv_amt_30 = lv_amt_30 + ls_data-amt_gp_curr .
                ENDIF.
                IF lv_curr IS INITIAL.
                  lv_curr = ls_data-currency.
                ENDIF.
                IF lv_curr_loc IS INITIAL.
                  lv_curr_loc = ls_data-loc_curr.
                ENDIF.
                IF lv_curr_gp IS INITIAL.
                  lv_curr_gp = ls_data-gp_curr.
                ENDIF.
              ENDLOOP.

              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_acc_receivable-itemno_acc.
              ls_curr_amt-currency = lv_curr.
              ls_curr_amt-amt_doccur = lv_amt_00.
              ls_curr_amt-amt_doccur_long = lv_amt_00.
              IF lv_no_curr EQ abap_false.
                ls_curr_amt-curr_type = '00'.
              ENDIF.
              APPEND ls_curr_amt TO lt_curr_amt.

              IF lv_no_curr EQ abap_false.
                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_receivable-itemno_acc.
                ls_curr_amt-currency = 'PHP'.
                ls_curr_amt-amt_doccur = lv_amt_10.
                ls_curr_amt-amt_doccur_long = lv_amt_10.
                ls_curr_amt-curr_type = '10'.
                APPEND ls_curr_amt TO lt_curr_amt.

                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_receivable-itemno_acc.
                ls_curr_amt-currency = 'USD'.
                ls_curr_amt-amt_doccur = lv_amt_30.
                ls_curr_amt-amt_doccur_long = lv_amt_30.
                ls_curr_amt-curr_type = '30'.
                APPEND ls_curr_amt TO lt_curr_amt.
              ENDIF.
              CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_gl_account,ls_data.

            ENDLOOP.
            CLEAR: lv_curr,lv_curr_loc,lv_curr_gp.
          ENDIF.

          DATA(lt_data_1) = lt_data_copy.
          DATA : lv_gl TYPE hkont.
          LOOP AT lt_gl_account INTO ls_gl_account.
*            DATA(lv_gl) = ls_gl_account-gl_account+2(8).
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
              EXPORTING
                input  = ls_gl_account-gl_account
              IMPORTING
                output = lv_gl.

            CONDENSE lv_gl.

            LOOP AT lt_data_1 INTO ls_data WHERE    gl_account    = lv_gl AND
                                                    cost_center   = ls_gl_account-costcenter  AND
                                                    gl_assignment = ls_gl_account-alloc_nmbr  AND
                                                    profit_cent   = ls_gl_account-profit_ctr  AND
                                                    wbs_element   = ls_gl_account-wbs_element AND
                                                    invoice_id    = lv_invoice_id AND
                                                    gl_itm_txt    = ls_gl_account-item_text.
              IF ls_data-deb_cre EQ 'H'.
                lv_amt_00 = lv_amt_00 + ( ls_data-gl_amt_doc_curr * -1 ).
                lv_amt_10 = lv_amt_10 + ( ls_data-gl_amt_loc_curr * -1 ).
                lv_amt_30 = lv_amt_30 + ( ls_data-gl_amt_gp_curr * -1 ).
              ELSE.
                lv_amt_00 = lv_amt_00 + ls_data-gl_amt_doc_curr .
                lv_amt_10 = lv_amt_10 + ls_data-gl_amt_loc_curr.
                lv_amt_30 = lv_amt_30 + ls_data-gl_amt_gp_curr .
              ENDIF.
              IF lv_curr IS INITIAL.
                lv_curr = ls_data-currency.
              ENDIF.
              IF lv_curr_loc IS INITIAL.
                lv_curr_loc = ls_data-loc_curr.
              ENDIF.
              IF lv_curr_gp IS INITIAL.
                lv_curr_gp = ls_data-gp_curr.
              ENDIF.
            ENDLOOP.

            CLEAR:ls_curr_amt.
            ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
            ls_curr_amt-currency = lv_curr.
            ls_curr_amt-amt_doccur = lv_amt_00.
            ls_curr_amt-amt_doccur_long = lv_amt_00.
            IF lv_no_curr EQ abap_false.
              ls_curr_amt-curr_type = '00'.
            ENDIF.
            APPEND ls_curr_amt TO lt_curr_amt.

            IF lv_no_curr EQ abap_false.
              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
              ls_curr_amt-currency = 'PHP'.
              ls_curr_amt-amt_doccur = lv_amt_10.
              ls_curr_amt-amt_doccur_long = lv_amt_10.
              ls_curr_amt-curr_type = '10'.
              APPEND ls_curr_amt TO lt_curr_amt.

              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
              ls_curr_amt-currency = 'USD'.
              ls_curr_amt-amt_doccur = lv_amt_30.
              ls_curr_amt-amt_doccur_long = lv_amt_30.
              ls_curr_amt-curr_type = '30'.
              APPEND ls_curr_amt TO lt_curr_amt.
            ENDIF.
            CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_gl_account,lv_gl,ls_data.
          ENDLOOP.

          CLEAR: lv_curr,lv_curr_loc,lv_curr_gp.

          LOOP AT lt_acc_tax INTO ls_acc_tax.
            READ TABLE gt_mwdat INTO gs_mwdat WITH KEY hkont = ls_acc_tax-gl_account
                                                       tax_code = ls_acc_tax-tax_code.
            IF sy-subrc EQ 0.
              LOOP AT lt_data_1 INTO ls_data WHERE gl_tax_cd = ls_acc_tax-tax_code AND
                                                     invoice_id = lv_invoice_id.
                IF ls_data-deb_cre EQ 'H'.
                  lv_amt_00 = lv_amt_00 + ( ls_data-gl_amt_doc_curr * -1 ).
                  lv_amt_10 = lv_amt_10 + ( ls_data-gl_amt_loc_curr * -1 ).
                  lv_amt_30 = lv_amt_30 + ( ls_data-gl_amt_gp_curr * -1 ).
                ELSEIF ls_data-deb_cre EQ 'S'.
                  lv_amt_00 = lv_amt_00 + ls_data-gl_amt_doc_curr .
                  lv_amt_10 = lv_amt_10 + ls_data-gl_amt_loc_curr.
                  lv_amt_30 = lv_amt_30 + ls_data-gl_amt_gp_curr .
                ENDIF.
                IF lv_curr IS INITIAL.
                  lv_curr = ls_data-currency.
                ENDIF.
                IF lv_curr_loc IS INITIAL.
                  lv_curr_loc = ls_data-loc_curr.
                ENDIF.
                IF lv_curr_gp IS INITIAL.
                  lv_curr_gp = ls_data-gp_curr.
                ENDIF.
                IF lv_deb_cre IS INITIAL.
                  lv_deb_cre = ls_data-deb_cre.
                ENDIF.
*                READ TABLE lt_acc_receivable INTO ls_acc_receivable WITH KEY alloc_nmbr = ls_data-assign_number.
                IF lv_curr IS NOT INITIAL AND lv_curr_loc IS NOT INITIAL AND lv_curr_gp IS NOT INITIAL.
                  DATA(lv_mul_active) = abap_true.
                ENDIF.
                READ TABLE lt_acc_receivable INTO ls_acc_receivable WITH KEY alloc_nmbr = ls_data-gl_assignment.
                IF sy-subrc EQ 0.
                  LOOP AT lt_curr_amt ASSIGNING FIELD-SYMBOL(<fs_curr_amt>) WHERE itemno_acc = ls_acc_receivable-itemno_acc.
*                    lv_tax_rec = ( <fs_curr_amt>-amt_doccur * ( gs_mwdat-msatz / 100 ) ).
                    IF lv_mul_active EQ abap_false.
                      lv_tax_rec = ( ls_data-gl_amt_doc_curr * ( gs_mwdat-msatz / 100 ) ).
                      IF ls_data-deb_cre EQ 'S'.
                        lv_tax_rec = lv_tax_rec * -1.
                      ENDIF.
                      <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur + lv_tax_rec.
                      <fs_curr_amt>-amt_doccur_long = <fs_curr_amt>-amt_doccur.
                    ELSE.

                      IF <fs_curr_amt>-curr_type EQ '00'.
                        lv_tax_rec = ( ls_data-gl_amt_doc_curr * ( gs_mwdat-msatz / 100 ) ).
                        IF ls_data-deb_cre EQ 'S'.
                          lv_tax_rec = lv_tax_rec * -1.
                        ENDIF.
                        <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur + lv_tax_rec.
                        <fs_curr_amt>-amt_doccur_long = <fs_curr_amt>-amt_doccur.
                      ENDIF.

                      IF <fs_curr_amt>-curr_type EQ '10'.
                        lv_tax_rec = ( ls_data-gl_amt_loc_curr * ( gs_mwdat-msatz / 100 ) ).
                        IF ls_data-deb_cre EQ 'S'.
                          lv_tax_rec = lv_tax_rec * -1.
                        ENDIF.
                        <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur + lv_tax_rec.
                        <fs_curr_amt>-amt_doccur_long = <fs_curr_amt>-amt_doccur.
                      ENDIF.

                      IF <fs_curr_amt>-curr_type EQ '30'.
                        lv_tax_rec = ( ls_data-gl_amt_gp_curr * ( gs_mwdat-msatz / 100 ) ).
                        IF ls_data-deb_cre EQ 'S'.
                          lv_tax_rec = lv_tax_rec * -1.
                        ENDIF.
                        <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur + lv_tax_rec.
                        <fs_curr_amt>-amt_doccur_long = <fs_curr_amt>-amt_doccur.
                      ENDIF.
                    ENDIF.

                  ENDLOOP.
                ENDIF.
              ENDLOOP.

              lv_tax_00 = lv_amt_00 * ( gs_mwdat-msatz / 100 ).
              lv_tax_10 = lv_amt_10 * ( gs_mwdat-msatz / 100 ).
              lv_tax_30 = lv_amt_30 * ( gs_mwdat-msatz / 100 ).

              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
              IF lv_curr IS INITIAL.
                READ TABLE lt_data_1 INTO ls_data WITH KEY invoice_id = lv_invoice_id.
                IF sy-subrc EQ 0.
                  lv_curr = ls_data-currency.
                ENDIF.
              ENDIF.
              ls_curr_amt-currency = lv_curr.
              IF ls_data-deb_cre EQ 'S'.
                ls_curr_amt-amt_base = lv_amt_00.
              ELSEIF ls_data-deb_cre EQ 'H'.
                ls_curr_amt-amt_base = lv_amt_00 * -1.
              ENDIF.
              ls_curr_amt-amt_doccur = lv_tax_00.
              ls_curr_amt-amt_doccur_long = lv_tax_00.
              IF lv_no_curr EQ abap_false.
                ls_curr_amt-curr_type = '00'.
              ENDIF.
              APPEND ls_curr_amt TO lt_curr_amt.

              IF lv_no_curr EQ abap_false.
                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
                ls_curr_amt-currency = 'PHP'.
                IF lv_deb_cre = 'S'.
                  ls_curr_amt-amt_base = lv_amt_10.
                ELSE.
*                  ls_curr_amt-amt_base = lv_tax_10.
                  ls_curr_amt-amt_base = lv_amt_10 * -1.
                ENDIF.
                ls_curr_amt-amt_doccur = lv_tax_10.
                ls_curr_amt-amt_doccur_long = lv_tax_10.
                ls_curr_amt-curr_type = '10'.
                APPEND ls_curr_amt TO lt_curr_amt.

                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
                ls_curr_amt-currency = 'USD'.
                IF lv_deb_cre = 'S'.
                  ls_curr_amt-amt_base = lv_amt_30.
                ELSE.
*                  ls_curr_amt-amt_base = lv_tax_30.
                  ls_curr_amt-amt_base = lv_amt_30 * -1.
                ENDIF.
                ls_curr_amt-amt_doccur = lv_tax_30.
                ls_curr_amt-amt_doccur_long = lv_tax_30.
                ls_curr_amt-curr_type = '30'.
                APPEND ls_curr_amt TO lt_curr_amt.
              ENDIF.
              CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_acc_tax,lv_gl,ls_data,
              lv_tax_00,lv_tax_10,lv_tax_30,gs_mwdat,lv_deb_cre.
            ENDIF.
          ENDLOOP.

          CLEAR: lv_curr,lv_curr_loc,lv_curr_gp,lv_no_curr.
          IF  lt_curr_amt IS NOT INITIAL.
            et_currency_amount[] = lt_curr_amt[] .
          ENDIF.
        ENDIF.

        CALL FUNCTION 'ZFM_INV_DOC_CHECK' DESTINATION 'NONE'
          EXPORTING
            documentheader    = ls_doc_header
            customercpd       = ls_custcpd
          TABLES
            accountgl         = lt_gl_account
            accountreceivable = lt_acc_receivable
            accounttax        = lt_acc_tax
            currencyamount    = lt_curr_amt
            criteria          = lt_criteria
            return            = lt_return
            extension2        = lt_extension
            accountwt         = lt_acct_wt.


        CLEAR: ls_doc_header, ls_custcpd, lt_gl_account, lt_acc_receivable,lt_curr_amt, lt_criteria, lt_extension,
        lt_acc_tax, lt_acct_wt, lt_curr_amt, lt_acc_payable,  ltt_gl_tax,lv_index, lt_data_tax, lt_data_no_tax,
        lv_bukrs,lv_currency,lv_lstml.

        READ TABLE lt_return INTO DATA(ls_max_error) WITH  KEY id = 'F5' number = '727'.
        IF sy-subrc = 0.
          DELETE lt_return WHERE type = 'E' AND id = 'F5'  AND number = '727'.
        ENDIF.
        READ TABLE lt_return INTO ls_max_error WITH  KEY id = 'RW' number = '609'.
        IF sy-subrc = 0.
          DELETE lt_return WHERE type = 'E' AND id = 'RW'  AND number = '609'.
        ENDIF.
        READ TABLE lt_return INTO DATA(ls_return)
                  WITH KEY type = 'E'.

        IF sy-subrc EQ 0.

          LOOP AT lt_return INTO ls_return.

            CALL FUNCTION 'MESSAGE_TEXT_BUILD'
              EXPORTING
                msgid               = ls_return-id
                msgnr               = ls_return-number
                msgv1               = ls_return-message_v1
                msgv2               = ls_return-message_v2
                msgv3               = ls_return-message_v3
                msgv4               = ls_return-message_v4
              IMPORTING
                message_text_output = lv_message.

            ls_message-invoice_id = <fs_data>-invoice_id.
*              ls_message-line_no = <fs_data>-linenumber.
            IF ls_return-type = 'E'.
              ls_message-status = 'Error'.
            ELSEIF ls_return-type = 'W'.
              ls_message-status = 'Warning'.
            ELSEIF ls_return-type = 'W'.
              ls_message-status = 'Terminated'.
            ELSE.
              ls_message-status = 'Success'.
            ENDIF.

            ls_message-code = '1'.
            ls_message-message = lv_message.
            REPLACE '&' WITH TEXT-003 INTO ls_message-message.
            APPEND ls_message TO lt_message.
            READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Error' invoice_id = <fs_data>-invoice_id.
            IF sy-subrc = 0.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
            ENDIF.
            READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Terminated' invoice_id = <fs_data>-invoice_id.
            IF sy-subrc = 0.
              ev_errorcount = ev_errorcount + 1.
              ev_status = 'A'.
              <fs_data>-status = 'A'.
            ENDIF.
            DATA(ls_modify) = <fs_data>.
            MODIFY  ct_data FROM ls_modify TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
          ENDLOOP.
          CLEAR: lt_return.
        ENDIF.

        DELETE lt_data_copy WHERE invoice_id = lv_invoice_id.
        CLEAR: lv_data_index.
      ENDLOOP.
    ENDIF.

    DELETE ADJACENT DUPLICATES FROM lt_message COMPARING invoice_id status message.
    APPEND LINES OF lt_message TO ct_log.
    CLEAR lt_message.
    SORT ct_log BY invoice_id ASCENDING.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->TRANSFORM_INV_DATA_AR
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CT_DATA                        TYPE        ZINV_CL_BP_AR_USER=>GTT_GR_XL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD transform_inv_data_ar.
    DATA: lv_doc_curr TYPE wrbtr.
    DATA: lv_loc_curr TYPE wrbtr.
    DATA: lv_gp_curr TYPE dmbe2.

    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<fs_data>).
*
      IF <fs_data>-doc_date IS NOT INITIAL.
        <fs_data>-doc_date = |{ <fs_data>-doc_date+6(4) }{ <fs_data>-doc_date+3(2) }{ <fs_data>-doc_date+0(2) }|.
      ENDIF.
      IF <fs_data>-posting_date IS NOT INITIAL.
        <fs_data>-posting_date = |{ <fs_data>-posting_date+6(4) }{ <fs_data>-posting_date+3(2) }{ <fs_data>-posting_date+0(2) }|.
      ENDIF.
      IF <fs_data>-baseline_date IS NOT INITIAL.
        <fs_data>-baseline_date = |{ <fs_data>-baseline_date+6(4) }{ <fs_data>-baseline_date+3(2) }{ <fs_data>-baseline_date+0(2) }|.
      ENDIF.

      IF <fs_data>-amt_loc_curr = '7.0000000000000007E-2'.
        lv_loc_curr = '0.07'.
        <fs_data>-amt_loc_curr = lv_loc_curr.
        CLEAR lv_loc_curr.
      ENDIF.

      IF <fs_data>-gross_inv_amount  = '7.0000000000000007E-2'.
        lv_doc_curr = '0.07'.
        <fs_data>-gross_inv_amount = lv_doc_curr.
        CLEAR lv_doc_curr.
      ENDIF.

      IF <fs_data>-amt_gp_curr  = '7.0000000000000007E-2'.
        lv_gp_curr = '0.07'.
        <fs_data>-amt_gp_curr = lv_gp_curr.
        CLEAR lv_gp_curr.
      ENDIF.

      IF <fs_data>-gl_amt_loc_cur = '7.0000000000000007E-2'.
        lv_loc_curr = '0.07'.
        <fs_data>-amt_loc_curr = lv_loc_curr.
        CLEAR lv_loc_curr.
      ENDIF.

      IF <fs_data>-gl_amt_doc_cur  = '7.0000000000000007E-2'.
        lv_doc_curr = '0.07'.
        <fs_data>-gl_amt_doc_cur = lv_doc_curr.
        CLEAR lv_doc_curr.
      ENDIF.

      IF <fs_data>-gl_amt_gp_cur  = '7.0000000000000007E-2'.
        lv_gp_curr = '0.07'.
        <fs_data>-gl_amt_gp_cur = lv_gp_curr.
        CLEAR lv_gp_curr.
      ENDIF.

      IF <fs_data>-zz1_flightdate_mse IS NOT INITIAL.
        <fs_data>-zz1_flightdate_mse = |{ <fs_data>-zz1_flightdate_mse+6(4) }{ <fs_data>-zz1_flightdate_mse+3(2) }{ <fs_data>-zz1_flightdate_mse+0(2) }|.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_INV_UTILITY->VALIDATE_INV_DATA_AP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_STAGE                       TYPE        CHAR15(optional)
* | [--->] IV_EXISTING_STATUS             TYPE        CHAR40(optional)
* | [<---] ES_DOCUMENTHEADER              TYPE        BAPIACHE09
* | [<---] ES_CUSTOMERCPD                 TYPE        BAPIACPA09
* | [<---] ES_CONTRACTHEADER              TYPE        BAPIACCAHD
* | [<---] EV_ERRORCOUNT                  TYPE        INT4
* | [<---] EV_STATUS                      TYPE        CHAR1
* | [<---] ET_ACCOUNT_GL                  TYPE        BAPIACGL09_TAB
* | [<---] ET_ACCOUNT_PAYABLE             TYPE        BAPIACAP09_TAB
* | [<---] ET_ACCOUNT_TAX                 TYPE        BAPIACTX09_TAB
* | [<---] ET_CURRENCY_AMOUNT             TYPE        BAPIACCR09_TAB
* | [<---] ET_CRITERIA                    TYPE        BAPIACKEC9_TAB
* | [<---] ET_VALUEFIELD                  TYPE        BAPIACKEV9_TAB
* | [<---] ET_EXTENSION1                  TYPE        BAPIACEXTC_TAB
* | [<---] ET_EXTENSION2                  TYPE        BAPIPAREX_TAB
* | [<---] ET_PAYMENTCARD                 TYPE        BAPIACPC09_TAB
* | [<---] ET_ACCOUNTWT                   TYPE        BAPIACWT09_TAB
* | [<-->] CT_LOG                         TYPE        ZINV_CL_BP_POST_USER=>GTT_GR_ERROR(optional)
* | [<-->] CT_DATA                        TYPE        ZTT_INV_INPUT_SUP(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD validate_inv_data_ap.



    TYPES: BEGIN OF lty_vendor,
             invoice_id       TYPE num10,
             posting_key      TYPE bschl,
             invoicing_party  TYPE string,
             assign_number    TYPE string,
             gross_inv_amount TYPE  wrbtr,
             amt_loc_curr     TYPE  wrbtr,
             amt_gp_curr      TYPE  dmbe2,

           END OF lty_vendor.

    DATA: ltt_vendor TYPE TABLE OF lty_vendor.

    TYPES: BEGIN OF lty_gl_tax_code,
             gl_tax_cd TYPE mwskz,
           END OF lty_gl_tax_code.

    TYPES: BEGIN OF lty_gl_tax,
             item     TYPE num10,
             tax_code TYPE mwskz,
             base_amt TYPE wrbtr,
             tax_amt  TYPE wrbtr,
           END OF lty_gl_tax.

    DATA: ltt_gl_tax TYPE TABLE OF lty_gl_tax.
    DATA: ltt_gl_tax_code TYPE TABLE OF lty_gl_tax_code.

    TYPES : BEGIN OF lty_tax_cal,
              assign_id   TYPE dzuonr,
              tax_amt     TYPE wrbtr,
              tax_amt_loc TYPE wrbtr,
              tax_amt_gp  TYPE dmbe2,
              db_cre_in   TYPE char1.
    TYPES :  END OF lty_tax_cal.
    TYPES : BEGIN OF lty_tax,
              tax_code TYPE mwskz.
              INCLUDE  TYPE rtax1u15.
    TYPES :  END OF lty_tax.

    TYPES: BEGIN OF lty_gl_det,
             invoice_id              TYPE num10,
             gl_comp_code            TYPE bukrs,
             gl_account              TYPE hkont,
             gl_itm_txt              TYPE sgtxt,
             deb_cre                 TYPE shkzg,
             gl_curr                 TYPE waers,
*  @Semantics.amount.currencyCode : 'zstr_gl_account.gl_curr'
             gl_amount               TYPE wrbtr,
             gl_tax_cd               TYPE mwskz,
             gl_assignment           TYPE dzuonr,
             cost_center             TYPE kostl,
             profit_cent             TYPE prctr,
             wbs_element             TYPE ps_posid,
*  @Semantics.amount.currencyCode : 'zstr_gl_account.gl_curr'
             tax_bs_amt              TYPE txbhw,
             business_place          TYPE bupla,
             zz1_origin_mse          TYPE zz1_origin,
             zz1_subfleet_mse        TYPE zz1_subfleet,
             zz1_route_mse           TYPE zz1_route,
             zz1_tailnumber_mse      TYPE zz1_tailnumber,
             zz1_flightdate_mse      TYPE zz1_flightdate,
             zz1_flighttype_mse      TYPE zz1_flighttype,
             zz1_destination_mse     TYPE zz1_destination,
             zz1_bodytype_mse        TYPE zz1_bodytype,
             zz1_sector_mse          TYPE zz1_sector,
             zz1_aircrafttype_mse    TYPE zz1_aircrafttype,
             zz1_flightnumber_mse    TYPE zz1_flightnumber,
             zz1_flightindicator_mse TYPE zz1_flightindicator,
             cb_aircrafttype         TYPE yy1_cb_aircrafttype,
             cb_pos                  TYPE yy1_cb_pos,
             cb_apttaxcode           TYPE yy1_apttaxcode,
             cb_tailnumber           TYPE yy1_cb_tailnumber,
             cb_aptstation           TYPE yy1_cb_aptstation,
             cb_ref4                 TYPE xblnr,
             cb_ref5                 TYPE xblnr,
             cb_ref6                 TYPE xblnr,
             copa_ind                TYPE char1,
             cb_ind                  TYPE char1,
           END OF lty_gl_det.

    FIELD-SYMBOLS: <fs_curramt> TYPE bapiaccr09.

    DATA: lt_message      TYPE zinv_cl_bp_post_user=>gtt_gr_error,
          ls_message      TYPE zinv_cl_bp_post_user=>gty_gr_error,
          lv_posting_date TYPE sy-datum,
          lv_year         TYPE char4.

    DATA: lv_inv_type     TYPE bapiache09-doc_type,
          ls_doc_header   TYPE bapiache09,
          ls_gl_account   TYPE bapiacgl09,
          lt_gl_account   TYPE TABLE OF  bapiacgl09,
          ls_acc_payable  TYPE bapiacap09,
          lt_acc_payable  TYPE TABLE OF bapiacap09,
          ls_acc_tax      TYPE bapiactx09,
          lt_acc_tax      TYPE TABLE OF bapiactx09,
          ls_curr_amt     TYPE bapiaccr09,
          lt_curr_amt     TYPE TABLE OF bapiaccr09,
          ls_acct_wt      TYPE  bapiacwt09,
          lt_acct_wt      TYPE TABLE OF bapiacwt09,

          ls_custcpd      TYPE bapiacpa09,
          lt_custcpd      TYPE STANDARD TABLE OF bapiacpa09,
          lt_criteria     TYPE STANDARD TABLE OF bapiackec9,
          ls_extension    TYPE bapiparex,
          lt_extension    TYPE TABLE OF bapiparex,
          ls_out          TYPE bapiache09-obj_key,
          lt_return       TYPE bapiret2_tab,
          lt_gl_det       TYPE TABLE OF lty_gl_det,
          lt_gl_tax_code  TYPE TABLE OF lty_gl_tax_code,
          lv_total_gross  TYPE wrbtr,
          lv_total_gl_amt TYPE wrbtr. " zstr_gl_account.
    DATA:
      lv_item        TYPE posnr_acc,
      lv_item_gl     TYPE posnr_acc,
      lo_msg         TYPE REF TO /iwbep/if_message_container,
      lv_message     TYPE string,
      gs_mwdat       TYPE lty_tax,
      gt_mwdat       TYPE STANDARD TABLE OF lty_tax,
      gt_tax_cal     TYPE STANDARD TABLE OF lty_tax_cal,
      gs_tax_cal     TYPE lty_tax_cal,
      lv_amt_00      TYPE wrbtr,
      lv_amt_10      TYPE wrbtr,
      lv_amt_30      TYPE dmbe2,
      lv_tax_00      TYPE wrbtr,
      lv_tax_rec     TYPE wrbtr,
      lv_tax_10      TYPE wrbtr,
      lv_tax_30      TYPE dmbe2,
      lv_deb_cre     TYPE c,
      lv_curr        TYPE waers,
      lv_curr_loc    TYPE waers,
      lv_curr_gp     TYPE waers,
      lv_amount_h_00 TYPE wrbtr,
      lv_amount_h_10 TYPE wrbtr,
      lv_amount_h_30 TYPE dmbe2,
      lv_amount_s_00 TYPE wrbtr,
      lv_amount_s_10 TYPE wrbtr,
      lv_amount_s_30 TYPE dmbe2.

    IF ct_data IS NOT INITIAL.

      ev_status = 'S'.

      DATA(lt_data_copy) = ct_data.
      SORT ct_data BY invoice_id ASCENDING.
      DATA: lv_blart TYPE blart.
      DATA: lv_zuonr TYPE dzuonr.

      SELECT kokrs,kstar FROM cskb INTO TABLE @DATA(lt_rev_gl) WHERE kokrs = 'PH00'  AND katyp = '11'.

      LOOP AT lt_data_copy ASSIGNING FIELD-SYMBOL(<fs_data>).
        DATA(lt_data) = lt_data_copy.
        DATA(lv_invoice_id) = <fs_data>-invoice_id.
        DELETE lt_data WHERE invoice_id NE lv_invoice_id.


        DATA(lt_data_tax) = lt_data.
        DATA(lt_data_no_tax) = lt_data.

        DELETE lt_data_tax WHERE gl_tax_cd IS INITIAL.
        DELETE lt_data_no_tax WHERE gl_tax_cd IS NOT INITIAL.


        CLEAR: et_account_gl, et_account_payable, et_account_tax,
        et_currency_amount, es_documentheader,es_customercpd, lv_item.
        lt_gl_det = CORRESPONDING #( lt_data_copy ).
        DELETE lt_gl_det WHERE invoice_id NE <fs_data>-invoice_id.

        DESCRIBE TABLE lt_gl_det LINES DATA(lv_gl_index).
        LOOP AT lt_gl_det ASSIGNING FIELD-SYMBOL(<fs_gl_det>).
          IF <fs_gl_det>-deb_cre EQ 'H'.
            <fs_gl_det>-gl_amount = <fs_gl_det>-gl_amount * -1.
          ENDIF.
        ENDLOOP.

        lv_total_gl_amt = REDUCE tslxx9( INIT sum TYPE tslxx9
                                 FOR ls_gl_sum IN lt_gl_det
                                 NEXT sum = sum + ls_gl_sum-gl_amount ).

        ltt_vendor = CORRESPONDING #( lt_data_copy ).

        SORT ltt_vendor BY invoicing_party assign_number ASCENDING.
        DELETE ADJACENT DUPLICATES FROM ltt_vendor.
        DELETE ltt_vendor WHERE assign_number IS INITIAL.
        DELETE ltt_vendor WHERE invoice_id NE <fs_data>-invoice_id.
        DESCRIBE TABLE ltt_vendor LINES DATA(lv_acc_pay).
        LOOP AT ltt_vendor ASSIGNING FIELD-SYMBOL(<fs_vendor>).
          IF <fs_vendor>-posting_key EQ '31'.
            <fs_vendor>-gross_inv_amount = <fs_vendor>-gross_inv_amount * -1.
          ENDIF.
        ENDLOOP.
        lv_total_gross = REDUCE tslxx9( INIT sum TYPE tslxx9
                                    FOR ls_vendor IN ltt_vendor
                                    NEXT sum = sum + ls_vendor-gross_inv_amount ).

        ltt_gl_tax_code = CORRESPONDING #( lt_gl_det ).
        SORT ltt_gl_tax_code BY gl_tax_cd.
        DELETE ADJACENT DUPLICATES FROM ltt_gl_tax_code.


        lt_gl_tax_code = CORRESPONDING #( lt_gl_det ).
        SORT lt_gl_tax_code BY gl_tax_cd.
        DELETE ADJACENT DUPLICATES FROM lt_gl_tax_code.
        DESCRIBE TABLE lt_gl_tax_code LINES DATA(lv_gl_tc_index).

        IF <fs_data> IS ASSIGNED.
          <fs_data>-status = 'S'.
          <fs_data>-stage = 'Validation'.
          IF <fs_data>-invoice_id IS INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Invoice Id is Mandatory'.
            REPLACE '&' WITH TEXT-003 INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
            EXIT.

          ENDIF.
          lv_total_gross = abs( lv_total_gross ).
          lv_total_gl_amt = abs( lv_total_gl_amt ).


          IF lv_total_gross NE lv_total_gl_amt .
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Total gross amount does not match with Cumulative GL amount for invoice id &1'.
            REPLACE '&1' WITH <fs_data>-invoice_id INTO ls_message-message.
*            REPLACE '&2' WITH <fs_data>-gl_assignment INTO ls_message-message.
            APPEND ls_message TO lt_message.
            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
            EXIT.
          ENDIF.
          lv_posting_date = <fs_data>-posting_date.
          lv_year = lv_posting_date+0(4).
          lv_blart = <fs_data>-document_type.
          DATA(lv_acc_type) = <fs_data>-acc_type.

          SELECT SINGLE bukrs, gjahr, h_blart, koart, zuonr
           FROM bseg INTO @DATA(ls_bseg)
            WHERE bukrs = @<fs_data>-comp_code AND
                  gjahr = @lv_year AND
                  h_blart = @lv_blart AND
                  koart = @lv_acc_type AND
                  zuonr = @<fs_data>-assign_number.

          IF ls_bseg IS NOT INITIAL.
            ls_message-line_no = <fs_data>-linenumber.
            ls_message-line_id = <fs_data>-lineid.
            ls_message-invoice_id = <fs_data>-invoice_id.
            ls_message-status = 'Error'.
            ls_message-code = '1'.
            ls_message-message = 'Duplicate invoice entry &1'.
            REPLACE '&' WITH ls_bseg-zuonr INTO ls_message-message.
            APPEND ls_message TO lt_message.

            ev_errorcount = ev_errorcount + 1.
            ev_status = 'E'.
            <fs_data>-status = 'E'.
            MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
            EXIT.
          ENDIF.

*          Cost Center Validation
          READ TABLE lt_gl_det INTO DATA(ls_cost_cent) WITH KEY cost_center = ' '.
          IF sy-subrc IS INITIAL.
            IF ls_cost_cent-wbs_element IS INITIAL  AND ls_cost_cent-profit_cent IS INITIAL .
              ls_message-line_no = <fs_data>-linenumber.
              ls_message-line_id = <fs_data>-lineid.
              ls_message-invoice_id = <fs_data>-invoice_id.
              ls_message-status = 'Error'.
              ls_message-code = '1'.
              ls_message-message = 'Cost Center or WBS is Mandatory for invoice id &'.
              REPLACE '&' WITH <fs_data>-invoice_id INTO ls_message-message.
              APPEND ls_message TO lt_message.
              CLEAR: lv_message.

              ev_errorcount = ev_errorcount + 1.
              ev_status = 'E'.
              <fs_data>-status = 'E'.
              MODIFY  ct_data FROM <fs_data> TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              EXIT.
            ENDIF.
          ENDIF.
        ENDIF.
        ls_doc_header-bus_act       = 'RFBU'.
        ls_doc_header-username      = sy-uname.
        ls_doc_header-doc_date      = <fs_data>-document_date."sy-datum.   "pc INVOICE date
        ls_doc_header-doc_type      = <fs_data>-document_type.   " Document Type   "EKKO-BSART
        ls_doc_header-comp_code     = <fs_data>-comp_code." Company code
        ls_doc_header-header_txt    = <fs_data>-docu_hdr_text.
        ls_doc_header-pstng_date    = <fs_data>-posting_date.
        ls_doc_header-fisc_year     = <fs_data>-posting_date+0(4).
        ls_doc_header-ref_doc_no    = <fs_data>-reference.

        MOVE-CORRESPONDING ls_doc_header TO es_documentheader.

        DATA(lv_index) = 1.
        READ TABLE lt_data INTO DATA(ls_data) WITH KEY invoice_id = <fs_data>-invoice_id.
        IF sy-subrc = 0.
          DATA(lv_data_index) = sy-tabix.

          LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>) FROM lv_data_index.
            IF <ls_data>-invoice_id NE lv_invoice_id." <fs_data>-invoice_id.
              EXIT.
            ENDIF.

*           ACCOUNTPAYABLE
            IF <ls_data>-invoicing_party IS NOT INITIAL.

              DESCRIBE TABLE lt_acc_payable LINES DATA(lv_acc_pay_count).

              lv_item = lv_acc_pay_count + 1.
              ls_acc_payable-itemno_acc = lv_item.
              ls_acc_payable-comp_code = <ls_data>-comp_code.
              ls_acc_payable-bline_date = <ls_data>-baseline_date.
              ls_acc_payable-pmnt_block = <ls_data>-payment_block_key.
              ls_acc_payable-paymt_ref = <ls_data>-payment_ref.
              ls_acc_payable-bank_id = <ls_data>-short_key_hsb.
              ls_acc_payable-pymt_meth = <ls_data>-payment_method.
              ls_acc_payable-partner_bk = <ls_data>-part_bank_type.
              ls_acc_payable-housebankacctid = <ls_data>-id_acc_det.
              ls_acc_payable-item_text = <ls_data>-item_text.
              ls_acc_payable-businessplace = <ls_data>-business_place.


              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = <ls_data>-terms_payment
                IMPORTING
                  output = ls_acc_payable-pmnttrms.

              ls_acc_payable-vendor_no = <ls_data>-invoicing_party.
              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = <ls_data>-invoicing_party
                IMPORTING
                  output = ls_acc_payable-vendor_no.

              ls_acc_payable-alloc_nmbr = <ls_data>-assign_number.

              APPEND ls_acc_payable      TO lt_acc_payable.

              CLEAR ls_acc_payable.
              SORT lt_acc_payable BY itemno_acc.
              et_account_payable = lt_acc_payable.

**Withholding Tax
              IF <ls_data>-withold_tax_code IS NOT INITIAL AND <ls_data>-withold_tax_type IS NOT INITIAL.
                DESCRIBE TABLE lt_acct_wt LINES DATA(lv_wt_count).

                lv_item = lv_wt_count + 1.
                ls_acct_wt-itemno_acc = lv_item.
                ls_acct_wt-wt_code = <ls_data>-withold_tax_code.
                ls_acct_wt-wt_type = <ls_data>-withold_tax_type.
* Document Currency
                IF <ls_data>-withold_tax_base IS NOT INITIAL.
                  ls_acct_wt-man_amt_tc = <ls_data>-withold_tax_amount_dc.
                  ls_acct_wt-bas_amt_tc = <ls_data>-withold_tax_base.
                ELSE.
                  ls_acct_wt-bas_amt_tc = <ls_data>-gross_inv_amount.
                ENDIF.


                APPEND ls_acct_wt  TO lt_acct_wt.
                SORT lt_acct_wt BY itemno_acc.
                et_accountwt = lt_acct_wt.

                CLEAR: ls_acct_wt,lv_item.
              ENDIF.
* Withholding tax



              IF <ls_data>-name IS NOT INITIAL.
                ls_custcpd-name = <ls_data>-name.
                ls_custcpd-city = <ls_data>-city.
                ls_custcpd-country = <ls_data>-country.
                ls_custcpd-bank_acct = <ls_data>-bank_acc.
                ls_custcpd-bank_no = <ls_data>-bank_key.
                ls_custcpd-bank_ctry = <ls_data>-bank_reg.
                ls_custcpd-swift_code = <ls_data>-swift_cd.
*                ls_custcpd-iban = <ls_data>-iban.

                MOVE-CORRESPONDING ls_custcpd TO es_customercpd.
              ENDIF.
            ENDIF.
* ACCOUNTPAYABLE

            LOOP AT lt_gl_det INTO DATA(ls_gl_det) WHERE gl_assignment = <ls_data>-assign_number.
* GLAccount
              lv_index = sy-tabix.

              DESCRIBE TABLE lt_gl_account LINES DATA(lv_gl_acc_index).
              lv_item = lv_acc_pay + lv_gl_acc_index + 1.

              READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_det-gl_account.

              IF sy-subrc NE 0.

                ls_gl_account-itemno_acc = lv_item.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                  EXPORTING
                    input  = ls_gl_det-gl_account
                  IMPORTING
                    output = ls_gl_account-gl_account.

                DATA(lv_rev_gl) = ls_gl_account-gl_account.
                DATA(lv_add_ext) = abap_false.

                IF ls_gl_det-cost_center IS NOT INITIAL.
                  READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                           costcenter = ls_gl_det-cost_center
                                                                           item_text = ls_gl_det-gl_itm_txt.
                  IF sy-subrc NE 0.
                    ls_gl_account-costcenter = ls_gl_det-cost_center."<ls_data>-cost_center.
                    ls_gl_account-item_text   = ls_gl_det-gl_itm_txt."<ls_data>-gl_itm_txt.
                    ls_gl_account-comp_code = ls_gl_det-gl_comp_code. "<ls_data>-comp_code.
                    ls_gl_account-fisc_year = lv_year.
                    ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                    ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                    APPEND ls_gl_account TO lt_gl_account.
                    SORT lt_gl_account BY itemno_acc.

                    et_account_gl = lt_gl_account.

                  ENDIF.
                ELSEIF ls_gl_det-profit_cent IS NOT INITIAL.
                  READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                           profit_ctr = ls_gl_det-profit_cent
                                                                           item_text = ls_gl_det-gl_itm_txt.

                  IF sy-subrc NE 0.
*
                    ls_gl_account-profit_ctr  = ls_gl_det-profit_cent.
                    ls_gl_account-item_text   = ls_gl_det-gl_itm_txt."<ls_data>-gl_itm_txt.
                    ls_gl_account-comp_code = ls_gl_det-gl_comp_code. "<ls_data>-comp_code.
                    ls_gl_account-fisc_year = lv_year.
                    ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                    ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                    APPEND ls_gl_account TO lt_gl_account.
                    SORT lt_gl_account BY itemno_acc.

                    et_account_gl = lt_gl_account.

                  ENDIF.
                ELSEIF ls_gl_det-wbs_element IS NOT INITIAL.
                  READ TABLE lt_gl_account TRANSPORTING NO FIELDS WITH KEY gl_account = ls_gl_account-gl_account
                                                                           wbs_element = ls_gl_det-wbs_element
                                                                           item_text = ls_gl_det-gl_itm_txt.
                  IF sy-subrc NE 0.
                    ls_gl_account-wbs_element = ls_gl_det-wbs_element.
                    ls_gl_account-item_text   = ls_gl_det-gl_itm_txt."<ls_data>-gl_itm_txt.
                    ls_gl_account-comp_code = ls_gl_det-gl_comp_code. "<ls_data>-comp_code.
                    ls_gl_account-fisc_year = lv_year.
                    ls_gl_account-tax_code = ls_gl_det-gl_tax_cd.
                    ls_gl_account-alloc_nmbr = ls_gl_det-gl_assignment.
                    APPEND ls_gl_account TO lt_gl_account.
                    SORT lt_gl_account BY itemno_acc.
                    et_account_gl = lt_gl_account.
                  ENDIF.
                ENDIF.
                IF ls_gl_account IS INITIAL.
                  CLEAR: ls_gl_det-copa_ind, ls_gl_det-cb_ind.
                ENDIF.
                IF ls_gl_account-comp_code IS NOT INITIAL.
                  lv_add_ext = abap_true.
                ENDIF.
                CLEAR ls_gl_account.
*                  GL Account

*                Criteria- CoPA
                IF lv_add_ext = abap_true.
                  IF ls_gl_det-copa_ind = abap_true.

                    READ TABLE lt_criteria TRANSPORTING NO FIELDS WITH KEY itemno_acc = lv_item.
                    IF sy-subrc <> 0.
                      lt_criteria = VALUE #( BASE lt_criteria[]
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_origin_mse          fieldname = 'ZZ1_ORIGIN_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_subfleet_mse        fieldname = 'ZZ1_SUBFLEET_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_route_mse           fieldname = 'ZZ1_ROUTE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_tailnumber_mse      fieldname = 'ZZ1_TAILNUMBER_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flightdate_mse      fieldname = 'ZZ1_FLIGHTDATE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flighttype_mse      fieldname = 'ZZ1_FLIGHTTYPE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_destination_mse     fieldname = 'ZZ1_DESTINATION_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_bodytype_mse        fieldname = 'ZZ1_BODYTYPE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_sector_mse          fieldname = 'ZZ1_SECTOR_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_aircrafttype_mse    fieldname = 'ZZ1_AIRCRAFTTYPE_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flightnumber_mse    fieldname = 'ZZ1_FLIGHTNUMBER_MSE' )
                                              ( itemno_acc = lv_item character = ls_gl_det-zz1_flightindicator_mse fieldname = 'ZZ1_FLIGHTINDICATOR_MSE' )
                                              ).
                      SORT lt_criteria BY itemno_acc.
                      et_criteria = lt_criteria.
                    ENDIF.
                  ENDIF.
                  READ TABLE lt_rev_gl INTO DATA(ls_rev_gl) WITH KEY kstar = lv_rev_gl.
                  IF sy-subrc EQ 0.
                    APPEND INITIAL LINE TO lt_criteria ASSIGNING FIELD-SYMBOL(<fs_criteria>).
                    <fs_criteria>-itemno_acc = lv_item.
                    <fs_criteria>-fieldname = 'PRCTR'.
                    <fs_criteria>-character = ls_gl_det-profit_cent.
                    SORT lt_criteria BY itemno_acc.
                    APPEND <fs_criteria> TO et_criteria.
                    SORT et_criteria BY itemno_acc.
                  ENDIF.
                  CLEAR:lv_rev_gl,ls_rev_gl.
* Criteria-CoPA

* Extensions2
                  IF ls_gl_det-cb_ind = abap_true.
                    READ TABLE lt_extension TRANSPORTING NO FIELDS WITH KEY valuepart1 = lv_item.
                    IF sy-subrc <> 0.
                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'BUPLA'.
                      ls_extension-valuepart3 = <fs_data>-business_place.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_AIRCRAFTTYPE_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_aircrafttype.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_POS_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_pos.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_APTTAXCODE_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_apttaxcode.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_TAILNUMBER_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_tailnumber.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_APTSTATION_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_aptstation.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_REFERENCE4_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_ref4.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_REFERENCE5_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_ref5.
                      APPEND ls_extension TO lt_extension.

                      ls_extension-structure = 'ACCIT'.
                      ls_extension-valuepart1 = lv_item.
                      ls_extension-valuepart2 = 'YY1_CB_REFERENCE6_COB'.
                      ls_extension-valuepart3 = ls_gl_det-cb_ref6.
                      APPEND ls_extension TO lt_extension.
                      SORT lt_extension BY valuepart1.
                      et_extension2 = lt_extension.
                    ENDIF.
                  ENDIF.
                ENDIF.
*                   Extensions2
              ENDIF.

            ENDLOOP.
            DESCRIBE TABLE lt_acc_payable LINES DATA(lv_acc_index).
*              READ TABLE lt_gl_account INTO DATA(ls_gl_account_1) INDEX lv_gl_acc_index.
**                DATA(lv_item_tax) = lv_gl_acc_index + 1.
            DATA(lv_item_tax) = lv_gl_index + lv_acc_index + 1.

            LOOP AT ltt_gl_tax_code INTO DATA(ls_gl_tax).
              DATA: lt_mwdat         TYPE fm_tt_rtax1u15.
              DATA: lv_lstml         TYPE land1_stml.
              CALL FUNCTION 'Z_CALCULATE_TAX_FRM_NET'
                EXPORTING
                  i_bukrs                 = <fs_data>-comp_code
                  i_mwskz                 = ls_gl_tax-gl_tax_cd
                  i_waers                 = <fs_data>-currency
                  i_wrbtr                 = 100
                  i_lstml                 = <fs_data>-tax_rpt_ctry
                TABLES
                  t_mwdat                 = lt_mwdat
                EXCEPTIONS
                  bukrs_not_found         = 1
                  country_not_found       = 2
                  mwskz_not_defined       = 3
                  mwskz_not_valid         = 4
                  account_not_found       = 5
                  different_discount_base = 6
                  different_tax_base      = 7
                  txjcd_not_valid         = 8
                  not_found               = 9
                  ktosl_not_found         = 10
                  kalsm_not_found         = 11
                  parameter_error         = 12
                  knumh_not_found         = 13
                  kschl_not_found         = 14
                  unknown_error           = 15
                  OTHERS                  = 16.
              IF sy-subrc <> 0.

              ELSE.

                LOOP AT lt_mwdat INTO DATA(ls_mwdat).
                  READ TABLE lt_acc_tax TRANSPORTING NO FIELDS WITH KEY tax_code = ls_gl_tax-gl_tax_cd acct_key = ls_mwdat-ktosl.
                  IF sy-subrc NE 0.
                    ls_acc_tax-itemno_acc = lv_item_tax.
                    ls_acc_tax-tax_code = ls_gl_tax-gl_tax_cd.
                    ls_acc_tax-gl_account = ls_mwdat-hkont.
                    ls_acc_tax-acct_key = ls_mwdat-ktosl.
                    ls_acc_tax-cond_key = ls_mwdat-kschl.
                    ls_acc_tax-tax_country = <fs_data>-tax_rpt_ctry.
                    APPEND ls_acc_tax TO lt_acc_tax.
                    lv_item_tax = lv_item_tax + 1.
                  ENDIF.
                  MOVE-CORRESPONDING ls_mwdat TO gs_mwdat.
                  gs_mwdat-tax_code = ls_gl_tax-gl_tax_cd.
                  APPEND gs_mwdat TO gt_mwdat.
                  CLEAR:gs_mwdat.
                ENDLOOP.
              ENDIF.
            ENDLOOP.
            SORT lt_acc_tax BY itemno_acc gl_account acct_key cond_key.
            DELETE ADJACENT DUPLICATES FROM lt_acc_tax.
            et_account_tax = lt_acc_tax.
            CLEAR: lv_item, lv_item_tax.
*                  ACCOUNTTAX

            READ TABLE lt_data_copy INTO ls_data WITH KEY invoice_id = lv_invoice_id.
            IF  sy-subrc EQ 0.
              IF ls_data-currency IS NOT INITIAL .
                IF ls_data-gross_inv_amount IS NOT INITIAL.
                  DATA(lv_no_curr) = abap_true.
                ENDIF.
              ENDIF.
            ENDIF.
            DATA lv_vendor TYPE lifnr.

            IF lt_acc_payable IS NOT INITIAL.
              DATA(lt_data_rec) = lt_data_copy.
              LOOP AT lt_acc_payable INTO ls_acc_payable.
                CLEAR:lv_vendor.
                CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
                  EXPORTING
                    input  = ls_acc_payable-vendor_no
                  IMPORTING
                    output = lv_vendor.

                CONDENSE lv_vendor.

                LOOP AT lt_data_rec INTO ls_data WHERE   invoice_id = lv_invoice_id AND
                                                         invoicing_party = lv_vendor AND
                                                         comp_code = ls_acc_payable-comp_code AND
                                                         assign_number = ls_acc_payable-alloc_nmbr.
*                IF ls_data-deb_cre EQ 'H'.
                  IF ls_data-posting_key EQ '31'.
                    lv_amt_00 = lv_amt_00 + ( ls_data-gross_inv_amount * -1 ).

                  ELSE. "IF ls_data-posting_key EQ '21'.
                    lv_amt_00 = lv_amt_00 + ls_data-gross_inv_amount .

                  ENDIF.
                  IF lv_curr IS INITIAL.
                    lv_curr = ls_data-currency.
                  ENDIF.

                ENDLOOP.

                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_payable-itemno_acc.
                ls_curr_amt-currency = lv_curr.
                ls_curr_amt-amt_doccur = lv_amt_00.
                ls_curr_amt-amt_doccur_long = lv_amt_00.
                APPEND ls_curr_amt TO lt_curr_amt.
                CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_gl_account,ls_data.

              ENDLOOP.
              CLEAR: lv_curr,lv_curr_loc,lv_curr_gp.
            ENDIF.

            DATA(lt_data_1) = lt_data_copy.
            DATA : lv_gl TYPE hkont.
            LOOP AT lt_gl_account INTO ls_gl_account.
*            DATA(lv_gl) = ls_gl_account-gl_account+2(8).
              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
                EXPORTING
                  input  = ls_gl_account-gl_account
                IMPORTING
                  output = lv_gl.

              CONDENSE lv_gl.

              LOOP AT lt_data_1 INTO ls_data WHERE    gl_account    = lv_gl AND
                                                      cost_center   = ls_gl_account-costcenter  AND
                                                      gl_assignment = ls_gl_account-alloc_nmbr  AND
                                                      profit_cent   = ls_gl_account-profit_ctr  AND
                                                      wbs_element   = ls_gl_account-wbs_element AND
                                                      invoice_id    = lv_invoice_id AND
                                                      gl_itm_txt    = ls_gl_account-item_text.
                IF ls_data-deb_cre EQ 'H'.
                  lv_amt_00 = lv_amt_00 + ( ls_data-gl_amount * -1 ).

                ELSE.
                  lv_amt_00 = lv_amt_00 + ls_data-gl_amount .

                ENDIF.
                IF lv_curr IS INITIAL.
                  lv_curr = ls_data-currency.
                ENDIF.

              ENDLOOP.

              CLEAR:ls_curr_amt.
              ls_curr_amt-itemno_acc = ls_gl_account-itemno_acc.
              ls_curr_amt-currency = lv_curr.
              ls_curr_amt-amt_doccur = lv_amt_00.
              ls_curr_amt-amt_doccur_long = lv_amt_00.
              APPEND ls_curr_amt TO lt_curr_amt.
              CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_gl_account,lv_gl,ls_data.
            ENDLOOP.

            CLEAR: lv_curr,lv_curr_loc,lv_curr_gp.

            LOOP AT lt_acc_tax INTO ls_acc_tax.
              READ TABLE gt_mwdat INTO gs_mwdat WITH KEY hkont = ls_acc_tax-gl_account
                                                         tax_code = ls_acc_tax-tax_code
                                                         ktosl = ls_acc_tax-acct_key.

              IF sy-subrc EQ 0.
                IF sy-tabix = 2.
                  LOOP AT lt_data_1 INTO ls_data WHERE gl_tax_cd = ls_acc_tax-tax_code AND
                                                        invoice_id = lv_invoice_id.
                    IF lv_curr IS INITIAL.
                      lv_curr = ls_data-currency.
                    ENDIF.
                    IF lv_deb_cre IS INITIAL.
                      lv_deb_cre = ls_data-deb_cre.
                    ENDIF.
                    IF ls_data-deb_cre EQ 'H'.

                      lv_amt_00 = lv_amt_00 + ls_data-gross_inv_amount * ( gs_mwdat-wmwst / 100 ) .

*
                    ELSEIF ls_data-deb_cre EQ 'S'.
                      lv_amt_00 = lv_amt_00 + ls_data-gross_inv_amount * ( gs_mwdat-wmwst / 100 ) * -1 .

                    ENDIF.
                    lv_tax_00 = lv_tax_00 + ls_data-gross_inv_amount * ( gs_mwdat-wmwst / 100 ) * -1.

                  ENDLOOP.
                ELSE.
                  LOOP AT lt_data_1 INTO ls_data WHERE gl_tax_cd = ls_acc_tax-tax_code AND
                                                         invoice_id = lv_invoice_id.
                    IF ls_data-deb_cre EQ 'H'.
                      lv_amt_00 = lv_amt_00 + ( ls_data-gross_inv_amount * -1 ).

                    ELSEIF ls_data-deb_cre EQ 'S'.
                      lv_amt_00 = lv_amt_00 + ls_data-gross_inv_amount .

                    ENDIF.
                    IF lv_curr IS INITIAL.
                      lv_curr = ls_data-currency.
                    ENDIF.

                    IF lv_deb_cre IS INITIAL.
                      lv_deb_cre = ls_data-deb_cre.
                    ENDIF.
                    READ TABLE lt_acc_payable INTO ls_acc_payable WITH KEY alloc_nmbr = ls_data-assign_number.
                    IF sy-subrc EQ 0.
                      LOOP AT lt_curr_amt ASSIGNING FIELD-SYMBOL(<fs_curr_amt>) WHERE itemno_acc = ls_acc_payable-itemno_acc.
                        lv_tax_rec = ( <fs_curr_amt>-amt_doccur * ( gs_mwdat-msatz / 100 ) ).
                        <fs_curr_amt>-amt_doccur = <fs_curr_amt>-amt_doccur + lv_tax_rec.
                        <fs_curr_amt>-amt_doccur_long = <fs_curr_amt>-amt_doccur.
                      ENDLOOP.
                    ENDIF.
                  ENDLOOP.

                  lv_tax_00 = lv_amt_00 * ( gs_mwdat-msatz / 100 ).
                ENDIF.

                CLEAR:ls_curr_amt.
                ls_curr_amt-itemno_acc = ls_acc_tax-itemno_acc.
                IF lv_curr IS INITIAL.
                  READ TABLE lt_data_1 INTO ls_data WITH KEY invoice_id = lv_invoice_id.
                  IF sy-subrc EQ 0.
                    lv_curr = ls_data-currency.
                  ENDIF.
                ENDIF.
                ls_curr_amt-currency = lv_curr.
                IF ls_data-deb_cre EQ 'S'.
                  ls_curr_amt-amt_base = lv_amt_00.
                ELSEIF ls_data-deb_cre EQ 'H'.
                  ls_curr_amt-amt_base = lv_amt_00 * -1.
                ENDIF.
                ls_curr_amt-amt_doccur = lv_tax_00.
                ls_curr_amt-amt_doccur_long = lv_tax_00.

                APPEND ls_curr_amt TO lt_curr_amt.
                CLEAR:ls_curr_amt,lv_amt_00,lv_amt_10,lv_amt_30,ls_acc_tax,lv_gl,ls_data,
                lv_tax_00,lv_tax_10,lv_tax_30,gs_mwdat,lv_deb_cre.

              ENDIF.
            ENDLOOP.

            CLEAR: lv_curr,lv_curr_loc,lv_curr_gp,lv_no_curr.
            IF  lt_curr_amt IS NOT INITIAL.
              et_currency_amount[] = lt_curr_amt[] .
            ENDIF.

*
*            ENDLOOP.

            CALL FUNCTION 'ZFM_INV_DOC_CHECK' DESTINATION 'NONE'
              EXPORTING
                documentheader = ls_doc_header
                customercpd    = ls_custcpd
              TABLES
                accountgl      = lt_gl_account
                accountpayable = lt_acc_payable
                accounttax     = lt_acc_tax
                currencyamount = lt_curr_amt
                criteria       = lt_criteria
                return         = lt_return
                extension2     = lt_extension
                accountwt      = lt_acct_wt.


            CLEAR: ls_doc_header, ls_custcpd, lt_gl_account, lt_acc_payable,lt_curr_amt, lt_criteria, lt_extension,
            lt_acc_tax, lt_acct_wt, lt_curr_amt, lt_acc_payable,  ltt_gl_tax,lv_index, lt_data_tax, lt_data_no_tax.

            READ TABLE lt_return INTO DATA(ls_max_error) WITH  KEY id = 'F5' number = '727'.
            IF sy-subrc = 0.
              DELETE lt_return WHERE type = 'E' AND id = 'F5'  AND number = '727'.
            ENDIF.
            READ TABLE lt_return INTO ls_max_error WITH  KEY id = 'RW' number = '609'.
            IF sy-subrc = 0.
              DELETE lt_return WHERE type = 'E' AND id = 'RW'  AND number = '609'.
            ENDIF.
            READ TABLE lt_return INTO DATA(ls_return)
                      WITH KEY type = 'E'.

            IF sy-subrc EQ 0.

              LOOP AT lt_return INTO ls_return.

                CALL FUNCTION 'MESSAGE_TEXT_BUILD'
                  EXPORTING
                    msgid               = ls_return-id
                    msgnr               = ls_return-number
                    msgv1               = ls_return-message_v1
                    msgv2               = ls_return-message_v2
                    msgv3               = ls_return-message_v3
                    msgv4               = ls_return-message_v4
                  IMPORTING
                    message_text_output = lv_message.

                ls_message-invoice_id = <fs_data>-invoice_id.
*              ls_message-line_no = <fs_data>-linenumber.
                IF ls_return-type = 'E'.
                  ls_message-status = 'Error'.
                ELSEIF ls_return-type = 'W'.
                  ls_message-status = 'Warning'.
                ELSEIF ls_return-type = 'W'.
                  ls_message-status = 'Terminated'.
                ELSE.
                  ls_message-status = 'Success'.
                ENDIF.

                ls_message-code = '1'.
                ls_message-message = lv_message.
                REPLACE '&' WITH TEXT-003 INTO ls_message-message.
                APPEND ls_message TO lt_message.
                READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Error' invoice_id = <fs_data>-invoice_id.
                IF sy-subrc = 0.
                  ev_errorcount = ev_errorcount + 1.
                  ev_status = 'E'.
                  <fs_data>-status = 'E'.
                ENDIF.
                READ TABLE lt_message TRANSPORTING NO FIELDS WITH KEY status = 'Terminated' invoice_id = <fs_data>-invoice_id.
                IF sy-subrc = 0.
                  ev_errorcount = ev_errorcount + 1.
                  ev_status = 'A'.
                  <fs_data>-status = 'A'.
                ENDIF.
                DATA(ls_modify) = <fs_data>.
                MODIFY  ct_data FROM ls_modify TRANSPORTING  status WHERE invoice_id = <fs_data>-invoice_id.
              ENDLOOP.
              CLEAR: lt_return.
            ENDIF.
            lv_data_index += 1.
            DELETE lt_data WHERE invoice_id = lv_invoice_id.

          ENDLOOP.
        ENDIF.
        DELETE lt_data_copy WHERE invoice_id = lv_invoice_id.
        CLEAR: lv_data_index.

      ENDLOOP.
    ENDIF.
    APPEND LINES OF lt_message TO ct_log.
    CLEAR lt_message.
    SORT ct_log BY invoice_id ASCENDING.

  ENDMETHOD.
ENDCLASS.
