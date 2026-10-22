*----------------------------------------------------------------------*
* Class      : ZCL_MM_PO_VH_MPC
* Title      : Value-help entity sets + Common.ValueList annotations for
*              the custom PO header fields, added at runtime to the model
*              of MM_PUR_PO_MAINT_V2_SRV (Manage Purchase Orders)
* Author     : Arnav Johri (Diligent)      Created: 22.10.2026
* Project    : OVL - Fiori F4 on EKKO custom fields (ZC_PURCHASEORDERTP_EXT)
* Ships by   : paste (ADT global class). Object 1 of 3.
* Change     : 22/10/26 v2-v7 - API corrections on the first field
*              (MED names are CHAR, not STRING; interface is
*              /IWBEP/IF_MGW_ODATA_ANNOTATABL; GET_SCHEMA_NAMESPACE has no
*              RETURNING; SET_VALUE_LIST as in SAP's DEFINE; sap:text on
*              the key; UI.TextArrangement via SET_ENUM_MEMBER_BY_NAME).
*              v7 proven in the app: "1 (Source Inspection)".
*              22/10/26 v8 - all ten fixed-value fields of the Customers
*              tab (DD04L / DD01L / DD07T extracts of 22/10/26, filed under
*              original/). One entity set per domain, ZVH_<DOMAIN>, on
*              the shared entity type; the DPC (ZEI_MM_PO_VH_DPC v2)
*              reads the domain from the set name and filters. The first
*              set ZI_DOM_FIXVAL_VH becomes ZVH_ZINSP_TYP; the Constant
*              parameter is dropped. Each field has its own TRY, so one
*              failing field no longer takes the others down.
*              Order: DPC v2 active -> this class -> widen the WHERE of
*              ZI_DOM_FIXVAL_VH (view v2).
*----------------------------------------------------------------------*
* Why: the app runs on SAP's generated SEGW project (referenced data
* source). Its entity sets are fixed at generation, so no value-help
* view ever becomes an entity set through CDS alone. This class adds the
* sets and the annotations to the model after SADL has built it. Called
* from one implicit enhancement at the END of DEFINE of
* CL_MM_PUR_PO_MAINT_V2_MPC_EXT (object 2):
*
*   zcl_mm_po_vh_mpc=>add_value_helps( io_model       = model
*                                      io_vocan_model = vocab_anno_model ).
*
* Rows are served by ZEI_MM_PO_VH_DPC (object 3). Nothing here can break
* the PO service: every step is inside TRY; a failing field is skipped
* and named in GV_LAST_ERROR (debugger), the rest go through.
* Test: $metadata of ZMM_PUR_PO_MAINT_V2_SRV shows EntitySet ZVH_ZT_NATURE
* ... ZVH_ZZDMEP and Common.ValueList on each annotated property;
* /ZVH_ZT_NATURE?$format=json returns ten rows.
*
* ASSUMPTION A1: the PO header entity type is C_PurchaseOrderTPType
*   (confirmed in SAP's DEFINE) and the properties are the CDS element
*   names of ZC_PURCHASEORDERTP_EXT (zzt_nature ...), as SADL names them.
* ASSUMPTION A2: SQL view of ZI_DOM_FIXVAL_VH is ZIDOMFIXVALVH with the
*   columns DOMAINNAME, DOMAINVALUE, DOMAINVALUETEXT, VALUEPOSITION.
* ASSUMPTION A3: the Common vocabulary is already referenced by SAP's
*   model (its own fields carry Common.ValueList); none is created here.
* ASSUMPTION A5: schema namespace MM_PUR_PO_MAINT_V2_SRV (confirmed by the
*   __metadata.type of the first set, 22/10/26).
* ASSUMPTION A6: the VOCAN API takes STRING (proven on v7).
* ASSUMPTION A8: computed names into the MED API (entity set, property)
*   are passed as C LENGTH 40, the length the compiler reported for
*   IV_ENTITY_TYPE_NAME. If activation reports another length for
*   CREATE_ENTITY_SET or GET_PROPERTY, change the two DATA lengths in
*   ADD_VALUE_HELPS only.
* Watch-out: domain ZARBIT has a fixed value with a BLANK key
*   (No Arbitration, position 1). It comes through as a row whose key
*   DomainValue is ''. If the dropdown rejects it, exclude blank keys in
*   the DPC - the empty field then simply means No Arbitration.
*----------------------------------------------------------------------*
CLASS zcl_mm_po_vh_mpc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Fields skipped in the last run, with the reason; initial when all went in
    CLASS-DATA gv_last_error TYPE string READ-ONLY.

    "! Add the value-help entity sets and the ValueList annotations.
    "! Never raises: a failing field is skipped and named in GV_LAST_ERROR.
    CLASS-METHODS add_value_helps
      IMPORTING
        io_model       TYPE REF TO /iwbep/if_mgw_odata_model
        io_vocan_model TYPE REF TO /iwbep/if_mgw_vocan_model.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_field,
        property TYPE string,    "PO property as in $metadata
        label    TYPE string,    "title of the value help
        domain   TYPE string,    "domain whose fixed values apply
      END OF ty_field,
      tt_field TYPE STANDARD TABLE OF ty_field WITH DEFAULT KEY.

    CONSTANTS:
      gc_po_entity_type   TYPE string VALUE 'C_PurchaseOrderTPType',     "ASSUMPTION A1 (VOCAN only)
      gc_common           TYPE string VALUE 'com.sap.vocabularies.Common.v1',
      gc_schema_namespace TYPE string VALUE 'MM_PUR_PO_MAINT_V2_SRV'.    "ASSUMPTION A5

    "! The fixed-value fields: PO property, label, domain (DD04L 22/10/26)
    CLASS-METHODS fixed_value_fields
      RETURNING
        VALUE(rt_fields) TYPE tt_field.

    "! Shared entity type ZI_DOM_FIXVAL_VH (DD07T fixed values), bound to
    "! the SQL view; the entity sets per domain are created on it
    CLASS-METHODS create_dom_fixval_type
      IMPORTING
        io_model              TYPE REF TO /iwbep/if_mgw_odata_model
      RETURNING
        VALUE(ro_entity_type) TYPE REF TO /iwbep/if_mgw_odata_entity_typ
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Flags shared by every property of the value-help type
    CLASS-METHODS set_vh_flags
      IMPORTING
        io_property TYPE REF TO /iwbep/if_mgw_odata_property
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Flags shared by every value-help entity set
    CLASS-METHODS set_vh_set_flags
      IMPORTING
        io_entity_set TYPE REF TO /iwbep/if_mgw_odata_entity_set
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Common.ValueList + text arrangement on one PO property
    CLASS-METHODS annotate_value_list
      IMPORTING
        io_vocan_model TYPE REF TO /iwbep/if_mgw_vocan_model
        io_po_property TYPE REF TO /iwbep/if_mgw_odata_property
        iv_property    TYPE string        "PO property, e.g. zzinsp_typ
        iv_label       TYPE string        "title of the value help
        iv_vh_set      TYPE string        "entity set that serves it
      RAISING
        /iwbep/cx_mgw_med_exception.
ENDCLASS.


CLASS zcl_mm_po_vh_mpc IMPLEMENTATION.

  METHOD add_value_helps.
    DATA lv_set_name  TYPE c LENGTH 40.                                    "ASSUMPTION A8
    DATA lv_prop_name TYPE c LENGTH 40.                                    "ASSUMPTION A8

    CLEAR gv_last_error.
    IF io_model IS NOT BOUND OR io_vocan_model IS NOT BOUND.
      gv_last_error = 'Model references not bound'.
      RETURN.
    ENDIF.

    " 1. The shared entity type and the PO entity type - without them
    "    there is nothing to add, so stop here (the PO model is intact).
    TRY.
        DATA(lo_vh_type) = create_dom_fixval_type( io_model ).
        DATA(lo_po_type) = io_model->get_entity_type( 'C_PurchaseOrderTPType' ).  "ASSUMPTION A1
      CATCH cx_root INTO DATA(lx_setup).
        " Deliberate: the PO service must come up even if the value helps
        " cannot be added. The missing sets in $metadata are the signal.
        gv_last_error = lx_setup->get_text( ).
        RETURN.
    ENDTRY.

    " 2. One entity set and one annotation per field. A field that fails
    "    is skipped and named; the others still go in.
    LOOP AT fixed_value_fields( ) INTO DATA(ls_field).
      TRY.
          lv_set_name  = |ZVH_{ ls_field-domain }|.
          lv_prop_name = ls_field-property.

          DATA(lo_entity_set) = lo_vh_type->create_entity_set( lv_set_name ).
          set_vh_set_flags( lo_entity_set ).

          DATA(lo_po_property) = lo_po_type->get_property( lv_prop_name ).
          annotate_value_list( io_vocan_model = io_vocan_model
                               io_po_property = lo_po_property
                               iv_property    = ls_field-property
                               iv_label       = ls_field-label
                               iv_vh_set      = |{ lv_set_name }| ).
        CATCH cx_root INTO DATA(lx_field).
          gv_last_error = |{ gv_last_error }{ ls_field-property }: { lx_field->get_text( ) }; |.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD fixed_value_fields.
    " Labels as on the Customers tab of the app. Domains from DD04L,
    " values from DD07T (original/DD07T_extract_2026-10-22.txt).
    rt_fields = VALUE #(
      ( property = 'zzinsp_typ'   label = 'Inspection Type'        domain = 'ZINSP_TYP' )
      ( property = 'zzt_nature'   label = 'Nature of tender'       domain = 'ZT_NATURE' )
      ( property = 'zzbd_type'    label = 'Bidding System'         domain = 'ZBD_TYPE' )
      ( property = 'zzt_duration' label = 'Tender Duration type'   domain = 'ZT_DURATION' )
      ( property = 'zzvend_cat'   label = 'Vendor Category'        domain = 'ZVEND_CAT' )
      ( property = 'zzinsp_auth'  label = 'Inspection Authority'   domain = 'ZINSP_AUTH' )
      ( property = 'zzarbit'      label = 'Arbitration cases'      domain = 'ZARBIT' )
      ( property = 'zzbider_agr'  label = 'Bidder Agreement'       domain = 'ZBIDERAGR' )
      ( property = 'zzepc'        label = 'EPC approval OLD Value' domain = 'ZZEPC' )
      ( property = 'zzdmep'       label = 'DMEP'                   domain = 'ZZDMEP' ) ).
  ENDMETHOD.


  METHOD create_dom_fixval_type.
    DATA lo_property TYPE REF TO /iwbep/if_mgw_odata_property.

    ro_entity_type = io_model->create_entity_type( iv_entity_type_name = 'ZI_DOM_FIXVAL_VH'
                                                   iv_def_entity_set   = abap_false ).

    " Names into the MED API are literals on purpose: its parameters are
    " CHAR and take no STRING by reference (activation error, 22/10/26).
    lo_property = ro_entity_type->create_property( iv_property_name  = 'DomainName'
                                                   iv_abap_fieldname = 'DOMAINNAME' ).
    lo_property->set_is_key( ).
    lo_property->set_maxlength( 30 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Domain' ).

    lo_property = ro_entity_type->create_property( iv_property_name  = 'DomainValue'
                                                   iv_abap_fieldname = 'DOMAINVALUE' ).
    lo_property->set_is_key( ).
    lo_property->set_maxlength( 10 ).
    set_vh_flags( lo_property ).
    " One 'sap' annotation object, two keys: label, and text = the
    " description property, which gives the dropdown its wording
    DATA(lo_sap_anno) = lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap' ).
    lo_sap_anno->add( iv_key = 'label' iv_value = 'Value' ).
    lo_sap_anno->add( iv_key = 'text'  iv_value = 'DomainValueText' ).

    lo_property = ro_entity_type->create_property( iv_property_name  = 'DomainValueText'
                                                   iv_abap_fieldname = 'DOMAINVALUETEXT' ).
    lo_property->set_maxlength( 60 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Description' ).

    lo_property = ro_entity_type->create_property( iv_property_name  = 'ValuePosition'
                                                   iv_abap_fieldname = 'VALUEPOSITION' ).
    lo_property->set_maxlength( 4 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Sequence' ).

    ro_entity_type->bind_structure( iv_structure_name = 'ZIDOMFIXVALVH' ).  "ASSUMPTION A2
  ENDMETHOD.


  METHOD set_vh_flags.
    io_property->set_type_edm_string( ).
    io_property->set_creatable( abap_false ).
    io_property->set_updatable( abap_false ).
    io_property->set_filterable( abap_true ).
    io_property->set_sortable( abap_true ).
    io_property->set_nullable( abap_false ).
  ENDMETHOD.


  METHOD set_vh_set_flags.
    io_entity_set->set_creatable( abap_false ).
    io_entity_set->set_updatable( abap_false ).
    io_entity_set->set_deletable( abap_false ).
    io_entity_set->set_pageable( abap_true ).
    io_entity_set->set_addressable( abap_true ).
    io_entity_set->set_subscribable( abap_false ).
    io_entity_set->set_has_ftxt_search( abap_false ).
    io_entity_set->set_filter_required( abap_false ).
  ENDMETHOD.


  METHOD annotate_value_list.
    " 1. sap:value-list on the PO property, with the API SAP's own DEFINE
    "    uses for SupplierConfirmationControlKey. FIXED_VALUES renders a
    "    dropdown, like the GUI popup; STANDARD would open the dialog.
    io_po_property->set_value_list( /iwbep/if_mgw_odata_property=>gcs_value_list_type_property-fixed_values ).

    " 2. Common.ValueList, the way SAP's own fields carry it (VOCAN API,
    "    strings - ASSUMPTION A6)
    DATA(lv_target) = |{ gc_po_entity_type }/{ iv_property }|.
    DATA(lo_ann_target) = io_vocan_model->create_annotations_target( lv_target ).
    lo_ann_target->set_namespace_qualifier( gc_schema_namespace ).           "ASSUMPTION A5

    DATA(lo_annotation) = lo_ann_target->create_annotation( |{ gc_common }.ValueList| ).
    DATA(lo_record) = lo_annotation->create_record( ).
    lo_record->create_property( 'Label' )->create_simple_value( )->set_string( iv_label ).
    lo_record->create_property( 'CollectionPath' )->create_simple_value( )->set_string( iv_vh_set ).
    lo_record->create_property( 'SearchSupported' )->create_simple_value( )->set_boolean( abap_false ).

    DATA(lo_parameters) = lo_record->create_property( 'Parameters' )->create_collection( ).

    " In/out: PO field <-> value
    DATA(lo_param) = lo_parameters->create_record( |{ gc_common }.ValueListParameterInOut| ).
    lo_param->create_property( 'LocalDataProperty' )->create_simple_value( )->set_property_path( iv_property ).
    lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( 'DomainValue' ).

    " Display only: the text
    lo_param = lo_parameters->create_record( |{ gc_common }.ValueListParameterDisplayOnly| ).
    lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( 'DomainValueText' ).

    " 3. Text arrangement of the PO field: key and description together,
    "    key first, as in the GUI popup ("1 Source Inspection"). TextFirst
    "    gives "Source Inspection (1)", TextOnly the description alone.
    lo_ann_target->create_annotation( 'com.sap.vocabularies.UI.v1.TextArrangement'
      )->create_simple_value( )->set_enum_member_by_name(
        'com.sap.vocabularies.UI.v1.TextArrangementType/TextLast' ).
  ENDMETHOD.

ENDCLASS.
