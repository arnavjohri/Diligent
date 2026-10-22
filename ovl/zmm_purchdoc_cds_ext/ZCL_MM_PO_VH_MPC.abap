*----------------------------------------------------------------------*
* Class      : ZCL_MM_PO_VH_MPC
* Title      : Value-help entity set + Common.ValueList annotation for
*              the custom PO header fields, added at runtime to the model
*              of MM_PUR_PO_MAINT_V2_SRV (Manage Purchase Orders)
* Author     : Arnav Johri (Diligent)      Created: 22.10.2026
* Project    : OVL - Fiori F4 on EKKO custom fields (ZC_PURCHASEORDERTP_EXT)
* Ships by   : paste (ADT global class). Object 1 of 3.
* Change     : 22/10/26 v2 - activation error "type STRING of
*              GC_VH_ENTITY_TYPE is not compatible with C(40) of
*              IV_ENTITY_TYPE_NAME": the metadata (MED) API takes CHAR
*              names by reference, so a STRING cannot be passed. Names
*              into the MED API are now literals or C LENGTH 40; STRING
*              only where the vocabulary (VOCAN) API takes it.
*              22/10/26 v3 - interface is /IWBEP/IF_MGW_ODATA_ANNOTATABL
*              (30-char name); GET_SCHEMA_NAMESPACE has no RETURNING
*              parameter, so the schema namespace is a constant (A5).
*----------------------------------------------------------------------*
* Why: the app runs on SAP's generated SEGW project (referenced data
* source). Its entity sets are fixed at generation, so the value-help
* view ZI_DOM_FIXVAL_VH never becomes an entity set and the
* @Consumption.valueHelpDefinition on zzinsp_typ is dropped by the
* runtime. This class adds the set and the annotation to the model
* after SADL has built it. Called from one implicit enhancement at the
* END of method DEFINE of the model provider class (object 2):
*
*   zcl_mm_po_vh_mpc=>add_value_helps( io_model       = model
*                                      io_vocan_model = vocab_anno_model ).
*
* Data for the new set is served by the data provider (object 3).
* Nothing here can break the PO service: every step is inside TRY; on
* failure the value help is skipped, the standard model is returned
* unchanged and the reason is kept in GV_LAST_ERROR (debugger).
* Test: /IWFND/GW_CLIENT, $metadata of ZMM_PUR_PO_MAINT_V2_SRV shows
* EntitySet ZI_DOM_FIXVAL_VH and Common.ValueList on zzinsp_typ.
*
* ASSUMPTION A1: the PO header entity type is C_PurchaseOrderTPType and
*   the property is zzinsp_typ, as SADL names them. Verify in $metadata.
*   The names stand at the places marked "A1": the constant (used in
*   the annotation target) and the literals in ADD_VALUE_HELPS.
* ASSUMPTION A2: SQL view of ZI_DOM_FIXVAL_VH is ZIDOMFIXVALVH with the
*   columns DOMAINNAME, DOMAINVALUE, DOMAINVALUETEXT, VALUEPOSITION.
* ASSUMPTION A3: the Common vocabulary is already referenced by SAP's
*   model (its own fields carry Common.ValueList); none is created here.
* ASSUMPTION A4: the domain of ZZINSP_TYP is ZINSP_TYP (SE11, 21/10/26).
* ASSUMPTION A5: the schema namespace of the service is
*   MM_PUR_PO_MAINT_V2_SRV (SEGW project name + _SRV; the hub alias
*   ZMM_PUR_PO_MAINT_V2_SRV does not rename it). Verify once in
*   $metadata, <Schema Namespace="...">, and correct GC_SCHEMA_NAMESPACE
*   if it differs - a wrong namespace leaves the annotation unmatched.
* ASSUMPTION A6: the VOCAN API (annotations target, record, property,
*   simple value) takes STRING. If activation reports a STRING / C(n)
*   mismatch on one of those lines, change that one actual to a literal.
* Not in this version: search support in the value help (two rows) and
*   the per-field view copies; the Constant parameter on DomainName
*   already restricts a shared set per field once the view's WHERE is
*   widened again.
*----------------------------------------------------------------------*
CLASS zcl_mm_po_vh_mpc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Reason of the last skipped value help; initial when all was added
    CLASS-DATA gv_last_error TYPE string READ-ONLY.

    "! Add the value-help entity set and the ValueList annotation(s).
    "! Never raises: a failure skips the value help and sets GV_LAST_ERROR.
    CLASS-METHODS add_value_helps
      IMPORTING
        io_model       TYPE REF TO /iwbep/if_mgw_odata_model
        io_vocan_model TYPE REF TO /iwbep/if_mgw_vocan_model.

  PRIVATE SECTION.
    CONSTANTS:
      gc_po_entity_type TYPE string VALUE 'C_PurchaseOrderTPType',   "ASSUMPTION A1 (VOCAN only)
      gc_vh_entity_set  TYPE string VALUE 'ZI_DOM_FIXVAL_VH',        "VOCAN only
      gc_common         TYPE string VALUE 'com.sap.vocabularies.Common.v1',
      gc_schema_namespace TYPE string VALUE 'MM_PUR_PO_MAINT_V2_SRV'.   "ASSUMPTION A5

    "! Entity type and entity set ZI_DOM_FIXVAL_VH (DD07T fixed values)
    CLASS-METHODS create_dom_fixval_vh
      IMPORTING
        io_model TYPE REF TO /iwbep/if_mgw_odata_model
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Flags shared by every property of the value-help set
    CLASS-METHODS set_vh_flags
      IMPORTING
        io_property TYPE REF TO /iwbep/if_mgw_odata_property
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Common.ValueList on one PO property, pointing at the value-help set
    CLASS-METHODS annotate_value_list
      IMPORTING
        io_model       TYPE REF TO /iwbep/if_mgw_odata_model
        io_vocan_model TYPE REF TO /iwbep/if_mgw_vocan_model
        io_po_property TYPE REF TO /iwbep/if_mgw_odata_property
        iv_property    TYPE string        "PO property, e.g. zzinsp_typ
        iv_label       TYPE string        "title of the value help
        iv_domain      TYPE string        "domain whose fixed values apply
      RAISING
        /iwbep/cx_mgw_med_exception.
ENDCLASS.


CLASS zcl_mm_po_vh_mpc IMPLEMENTATION.

  METHOD add_value_helps.
    CLEAR gv_last_error.
    IF io_model IS NOT BOUND OR io_vocan_model IS NOT BOUND.
      gv_last_error = 'Model references not bound'.
      RETURN.
    ENDIF.

    TRY.
        create_dom_fixval_vh( io_model ).

        " One block per custom field. A further fixed-value field is one
        " more block here; the WHERE of ZI_DOM_FIXVAL_VH must then admit
        " its domain as well (the Constant parameter does the filtering).
        DATA(lo_po_property) = io_model->get_entity_type( 'C_PurchaseOrderTPType'   "ASSUMPTION A1
                                 )->get_property( 'zzinsp_typ' ).          "ASSUMPTION A1
        annotate_value_list( io_model       = io_model
                             io_vocan_model = io_vocan_model
                             io_po_property = lo_po_property
                             iv_property    = 'zzinsp_typ'                 "ASSUMPTION A1
                             iv_label       = 'Inspection Type'
                             iv_domain      = 'ZINSP_TYP' ).               "ASSUMPTION A4

      CATCH cx_root INTO DATA(lx_any).
        " Deliberate: the PO service must come up even if the value help
        " cannot be added. The missing set in $metadata is the signal.
        gv_last_error = lx_any->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD create_dom_fixval_vh.
    DATA lo_property TYPE REF TO /iwbep/if_mgw_odata_property.

    DATA(lo_entity_type) = io_model->create_entity_type(
                             iv_entity_type_name = 'ZI_DOM_FIXVAL_VH'
                             iv_def_entity_set   = abap_false ).

    " Names into the MED API are literals on purpose: its parameters are
    " CHAR and take no STRING by reference (activation error, 22/10/26).
    lo_property = lo_entity_type->create_property( iv_property_name  = 'DomainName'
                                                   iv_abap_fieldname = 'DOMAINNAME' ).
    lo_property->set_is_key( ).
    lo_property->set_maxlength( 30 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Domain' ).

    lo_property = lo_entity_type->create_property( iv_property_name  = 'DomainValue'
                                                   iv_abap_fieldname = 'DOMAINVALUE' ).
    lo_property->set_is_key( ).
    lo_property->set_maxlength( 10 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Value' ).

    lo_property = lo_entity_type->create_property( iv_property_name  = 'DomainValueText'
                                                   iv_abap_fieldname = 'DOMAINVALUETEXT' ).
    lo_property->set_maxlength( 60 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Description' ).

    lo_property = lo_entity_type->create_property( iv_property_name  = 'ValuePosition'
                                                   iv_abap_fieldname = 'VALUEPOSITION' ).
    lo_property->set_maxlength( 4 ).
    set_vh_flags( lo_property ).
    lo_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Sequence' ).

    lo_entity_type->bind_structure( iv_structure_name = 'ZIDOMFIXVALVH' ).  "ASSUMPTION A2

    DATA(lo_entity_set) = lo_entity_type->create_entity_set( 'ZI_DOM_FIXVAL_VH' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).
  ENDMETHOD.


  METHOD set_vh_flags.
    io_property->set_type_edm_string( ).
    io_property->set_creatable( abap_false ).
    io_property->set_updatable( abap_false ).
    io_property->set_filterable( abap_true ).
    io_property->set_sortable( abap_true ).
    io_property->set_nullable( abap_false ).
  ENDMETHOD.


  METHOD annotate_value_list.
    " 1. sap:value-list on the PO property. 'fixed-values' renders a
    "    dropdown, like the GUI popup with its two entries. For the
    "    value-help dialog instead, use 'standard'.
    io_po_property->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'value-list' iv_value = 'fixed-values' ).

    " 2. Common.ValueList, the way SAP's own fields carry it.
    "    The VOCAN API takes strings (ASSUMPTION A6): only here are the
    "    STRING constants used.
    DATA(lv_target) = |{ gc_po_entity_type }/{ iv_property }|.
    DATA(lo_ann_target) = io_vocan_model->create_annotations_target( lv_target ).
    lo_ann_target->set_namespace_qualifier( gc_schema_namespace ).           "ASSUMPTION A5

    DATA(lo_annotation) = lo_ann_target->create_annotation( |{ gc_common }.ValueList| ).
    DATA(lo_record) = lo_annotation->create_record( ).
    lo_record->create_property( 'Label' )->create_simple_value( )->set_string( iv_label ).
    lo_record->create_property( 'CollectionPath' )->create_simple_value( )->set_string( gc_vh_entity_set ).
    lo_record->create_property( 'SearchSupported' )->create_simple_value( )->set_boolean( abap_false ).

    DATA(lo_parameters) = lo_record->create_property( 'Parameters' )->create_collection( ).

    " In/out: PO field <-> value
    DATA(lo_param) = lo_parameters->create_record( |{ gc_common }.ValueListParameterInOut| ).
    lo_param->create_property( 'LocalDataProperty' )->create_simple_value( )->set_property_path( iv_property ).
    lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( 'DomainValue' ).

    " Display only: the text
    lo_param = lo_parameters->create_record( |{ gc_common }.ValueListParameterDisplayOnly| ).
    lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( 'DomainValueText' ).

    " Constant: this field's domain, so one set can serve every field
    lo_param = lo_parameters->create_record( |{ gc_common }.ValueListParameterConstant| ).
    lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( 'DomainName' ).
    lo_param->create_property( 'Constant' )->create_simple_value( )->set_string( iv_domain ).
  ENDMETHOD.

ENDCLASS.
