* Reference only: method DEFINE of SAP standard class CL_MM_PUR_PO_MAINT_V2_MPC_EXT
* as displayed in SE24 on OCQ 500, 22/10/26 (pasted by Arnav). Never edited here.
* Facts taken from it: super->define( ) first; attribute "model" used directly;
* entity type C_PurchaseOrderTPType / set C_PurchaseOrderTP; fixed-values flag set with
* lo_property->set_value_list( /iwbep/if_mgw_odata_property=>gcs_value_list_type_property-fixed_values ).
* The implicit enhancement for ZEI_MM_PO_VH_MPC sits after the final ENDTRY, before ENDMETHOD.
  METHOD define.

    DATA lo_annotation TYPE REF TO /iwbep/if_mgw_odata_annotation.
    DATA lo_property   TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set TYPE REF TO /iwbep/if_mgw_odata_entity_set.
    DATA lo_entity     TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA : lo_model_refobj   TYPE REF TO object,
           ls_model_features TYPE /iwbep/if_mgw_appl_types=>ty_s_model_features.

    super->define( ).

*   C_PurchaseOrderNoteTPType
    DATA(lo_header_entitytype) = me->model->get_entity_type( 'C_PurchaseOrderNoteTPType' ).
    lo_property = lo_header_entitytype->create_property( iv_property_name = 'Note_Long' iv_abap_fieldname = 'NOTE_LONG' ).
    lo_property->set_internal_type( iv_type = 'g' ).
    lo_property->set_type_edm_string( ).

*   C_PurchaseOrderItemNoteTPType
    lo_header_entitytype = me->model->get_entity_type( 'C_PurchaseOrderItemNoteTPType' ).
    lo_property = lo_header_entitytype->create_property( iv_property_name = 'Note_Long' iv_abap_fieldname = 'NOTE_LONG' ).
    lo_property->set_internal_type( iv_type = 'g' ).
    lo_property->set_type_edm_string( ).

*   C_PurchaseOrderItemTPType
    lo_property = model->get_entity_type( 'C_PurchaseOrderItemTPType' )->get_property( 'SupplierConfirmationControlKey' ).
    lo_property->set_value_list( /iwbep/if_mgw_odata_property=>gcs_value_list_type_property-fixed_values ).

*   enable soft state
    model->set_soft_state_enabled( iv_soft_state_enabled = abap_true ).

*   C_PurchaseOrderTPType: ExchangeRateForEdit
    TRY.
        TEST-SEAM get_entity_type1.
          lo_entity = model->get_entity_type( iv_entity_name = 'C_PurchaseOrderTPType' ).
        END-TEST-SEAM.
        IF lo_entity IS BOUND.
          CLEAR lo_property.
          lo_property = lo_entity->get_property( iv_property_name = 'ExchangeRateForEdit' ).
          lo_property->set_type_edm_string( ).
          lo_property->set_internal_type( iv_type = cl_abap_typedescr=>typekind_char ).
          lo_property->set_internal_length( iv_internal_length = '12' ).
          lo_property->set_conversion_exit(
            EXPORTING
              iv_conv_exit = 'EXCRT'
          ).
        ENDIF.
      CATCH /iwbep/cx_mgw_med_exception.
    ENDTRY.

*   C_PurOrdPricingElementTPType
    DATA(lo_pricing_mpc) = cl_pricing_odata_factory=>get_instance( )->get_pricing_mpc_instance( ).
    lo_pricing_mpc->define_pricing_elements(
      EXPORTING
        io_model       = model    " definition class to define programmatically a meta model
        iv_entity_name = 'C_PurOrdPricingElementTPType'
    ).

*   create annotation for enabling/disabling of CREATE operation of account assignment lines for entity type "C_PurchaseOrderItemTPType"
    TRY.
        TEST-SEAM get_entity_type2.
          lo_entity = model->get_entity_type( iv_entity_name = 'C_PurchaseOrderItemTPType' ).
        END-TEST-SEAM.
        IF lo_entity IS BOUND.
          DATA(lo_nav_property) = lo_entity->get_navigation_property( 'to_PurOrdAcctAssignmentTP' ).
          lo_annotation = lo_nav_property->create_annotation( 'sap' ).
          lo_annotation->add( iv_key = 'creatable-path' iv_value = 'AccountAssignmentIsAddable' ) ##NO_TEXT.
        ENDIF.
      CATCH /iwbep/cx_mgw_med_exception.
    ENDTRY.

*   create annotation for enabling/disabling of CREATE operation of schedule lines for entity type "C_PurchaseOrderItemTPType"
    TRY.
        TEST-SEAM get_entity_type3.
          lo_entity = model->get_entity_type( iv_entity_name = 'C_PurchaseOrderItemTPType' ).
        END-TEST-SEAM.
        IF lo_entity IS BOUND.
          lo_nav_property = lo_entity->get_navigation_property( 'to_PurOrdScheduleLineTP' ).
          lo_annotation = lo_nav_property->create_annotation( 'sap' ).
          lo_annotation->add( iv_key = 'creatable-path' iv_value = 'ScheduleLineIsAddable' ) ##NO_TEXT.
        ENDIF.
      CATCH /iwbep/cx_mgw_med_exception.
    ENDTRY.

*   create annotation for "SubcontractingCompIsAddable" of entity type "C_PurOrdScheduleLineTPType"
    TRY.
        TEST-SEAM get_entity_type4.
          lo_entity = model->get_entity_type( iv_entity_name = 'C_PurOrdScheduleLineTPType' ).
        END-TEST-SEAM.
        IF lo_entity IS BOUND.
          lo_nav_property = lo_entity->get_navigation_property( 'to_SubcontractingComponent' ).
          lo_annotation = lo_nav_property->create_annotation( 'sap' ).
          lo_annotation->add( iv_key = 'creatable-path' iv_value = 'SubcontractingCompIsAddable' ) ##NO_TEXT.
        ENDIF.
      CATCH /iwbep/cx_mgw_med_exception.
    ENDTRY.

*   create annotation for "NextPlantIsAddable" of entity type "C_PurOrdItmRetProcNxtPlantTPType"
    TRY.
        TEST-SEAM get_entity_type5.
          lo_entity = model->get_entity_type( iv_entity_name = 'C_PurchaseOrderItemReturnTPType' ).
        END-TEST-SEAM.
        IF lo_entity IS BOUND.
          lo_nav_property = lo_entity->get_navigation_property( 'to_PurOrdItmRetProcNxtPlant' ).
          lo_annotation = lo_nav_property->create_annotation( 'sap' ).
          lo_annotation->add( iv_key = 'creatable-path' iv_value = 'NextPlantIsAddable' ) ##NO_TEXT.
        ENDIF.
      CATCH /iwbep/cx_mgw_med_exception.
    ENDTRY.

*   set non-error-tolerant conversion for entity set "C_PurchaseOrderTP"
*   remark: this is done to avoid dump when entering character-like data in field "Exchange rate", see e.g. internal BCP incident "1970083589"
    CLEAR lo_entity_set.
    TEST-SEAM get_entity_set.
      lo_entity_set = model->get_entity_set( iv_entity_set_name = 'C_PurchaseOrderTP' ).
    END-TEST-SEAM.
    IF lo_entity_set IS BOUND.
      DATA ls_entity_set_features TYPE /iwbep/if_mgw_appl_types=>ty_s_entity_set_features.
      ls_entity_set_features-use_error_tolerant_conv = abap_false.
      lo_entity_set->set_entity_set_features( is_entity_set_features = ls_entity_set_features ).
    ENDIF.

*   adjustments for a correct currency handling
    cl_s4hana_odata_util=>set_variablescale_no_curr_conv( model ).

    TRY.
        lo_model_refobj ?= model.
        CALL METHOD lo_model_refobj->('/IWBEP/IF_MGW_ODATA_FW_MODEL~GET_MODEL_FEATURES')
          IMPORTING
            es_model_features = ls_model_features.

        ls_model_features-use_reference_across_changeset = abap_true.
        ls_model_features-use_ranges_4_filter_conversion = abap_true.
        model->set_model_features( is_model_features = ls_model_features ).

      CATCH cx_root INTO DATA(lx_enable_ref_ax_changeset_err).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_med_exception
          EXPORTING
            previous = lx_enable_ref_ax_changeset_err.

    ENDTRY.

  ENDMETHOD.
