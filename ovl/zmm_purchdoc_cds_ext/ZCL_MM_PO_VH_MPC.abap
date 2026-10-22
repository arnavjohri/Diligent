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
*              22/10/26 v8 - all ten fixed-value fields, one entity set
*              per domain ZVH_<DOMAIN>; proven (ZVH_ZT_NATURE, ten rows).
*              22/10/26 v9 - table-based value helps: entity types bound
*              to the value-help views (ZVT_NAT_PROC, ZVT_RELCODE,
*              ZVT_PERNR, ZVT_ADRC) and the user-ID field annotated
*              against SAP's own set C_PurOrdCreatedByValHelp. Needs the
*              four views active and ZCL_MM_PO_VH_DPC + ZEI_MM_PO_VH_DPC
*              v3 before it. Each block has its own TRY: a view that is
*              not there yet costs only its own value help.
*              22/10/26 v10 - 'Unable to interpret "40"': a method
*              parameter takes no LENGTH (MEMORY 4.1). Named types
*              TY_NAME40 / TY_FIELD30 instead.
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
* Rows are served by ZCL_MM_PO_VH_DPC via ZEI_MM_PO_VH_DPC (object 3).
* Nothing here can break the PO service: every block is inside TRY; a
* failing field is skipped and named in GV_LAST_ERROR (debugger).
*
* ASSUMPTION A1: the PO header entity type is C_PurchaseOrderTPType
*   (confirmed in SAP's DEFINE) and the properties are the CDS element
*   names of ZC_PURCHASEORDERTP_EXT (zzt_nature ...), as SADL names them.
* ASSUMPTION A2: SQL view names: ZIDOMFIXVALVH, ZINATPROCVH, ZIRELCODEVH,
*   ZIPERNRVH, ZIADRCVH, with the columns named in the type methods.
*   ZINATPROCVH's columns come from the GUI module, not from SE11.
* ASSUMPTION A3: the Common vocabulary is already referenced by SAP's
*   model (its own fields carry Common.ValueList); none is created here.
* ASSUMPTION A5: schema namespace MM_PUR_PO_MAINT_V2_SRV (confirmed by the
*   __metadata.type of the first set, 22/10/26).
* ASSUMPTION A6: the VOCAN API takes STRING (proven on v7).
* ASSUMPTION A8: names into the MED API are passed as C LENGTH 40
*   (property, entity set) and C LENGTH 30 (ABAP field). If activation
*   reports another length, change the DATA / parameter length it names.
* ASSUMPTION A9: SAP's set C_PurOrdCreatedByValHelp has the key property
*   UserID (from the association _CreatedByValueHelp in C_PurchaseOrderTP).
*   If the dialog on PO Signing Authority stays empty, read the property
*   name in $metadata and correct the one literal in ADD_VALUE_HELPS.
* Pending decisions (functional lead): ZVT_ADRC (address numbers as a
*   Fiori input?) and ZVT_PERNR (employee names visible to PO users?).
*   Until then, the two blocks can be left in: without their views they
*   skip themselves and are named in GV_LAST_ERROR.
*----------------------------------------------------------------------*
CLASS zcl_mm_po_vh_mpc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Fields skipped in the last run, with the reason; initial when all went in
    CLASS-DATA gv_last_error TYPE string READ-ONLY.

    "! Add the value-help entity sets and the ValueList annotations.
    "! Never raises: a failing block is skipped and named in GV_LAST_ERROR.
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
      tt_field  TYPE STANDARD TABLE OF ty_field WITH DEFAULT KEY,
      ty_name40  TYPE c LENGTH 40,     "OData names into the MED API   - ASSUMPTION A8
      ty_field30 TYPE c LENGTH 30.     "ABAP field names into the MED API

    CONSTANTS:
      gc_po_entity_type   TYPE string VALUE 'C_PurchaseOrderTPType',     "ASSUMPTION A1 (VOCAN only)
      gc_common           TYPE string VALUE 'com.sap.vocabularies.Common.v1',
      gc_schema_namespace TYPE string VALUE 'MM_PUR_PO_MAINT_V2_SRV'.    "ASSUMPTION A5

    "! The fixed-value fields: PO property, label, domain (DD04L 22/10/26)
    CLASS-METHODS fixed_value_fields
      RETURNING
        VALUE(rt_fields) TYPE tt_field.

    "! Shared entity type ZI_DOM_FIXVAL_VH (DD07T fixed values)
    CLASS-METHODS create_dom_fixval_type
      IMPORTING
        io_model              TYPE REF TO /iwbep/if_mgw_odata_model
      RETURNING
        VALUE(ro_entity_type) TYPE REF TO /iwbep/if_mgw_odata_entity_typ
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Entity type for ZI_NAT_PROC_VH (Tender Process, table ZNAT_PROC)
    CLASS-METHODS create_nat_proc_type
      IMPORTING
        io_model              TYPE REF TO /iwbep/if_mgw_odata_model
      RETURNING
        VALUE(ro_entity_type) TYPE REF TO /iwbep/if_mgw_odata_entity_typ
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Entity type for ZI_REL_CODE_VH (release codes, T16FC / T16FD)
    CLASS-METHODS create_rel_code_type
      IMPORTING
        io_model              TYPE REF TO /iwbep/if_mgw_odata_model
      RETURNING
        VALUE(ro_entity_type) TYPE REF TO /iwbep/if_mgw_odata_entity_typ
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Entity type for ZI_PERNR_VH (personnel numbers, PA0002)
    CLASS-METHODS create_pernr_type
      IMPORTING
        io_model              TYPE REF TO /iwbep/if_mgw_odata_model
      RETURNING
        VALUE(ro_entity_type) TYPE REF TO /iwbep/if_mgw_odata_entity_typ
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Entity type for ZI_ADRC_VH (address numbers, ADRC)
    CLASS-METHODS create_adrc_type
      IMPORTING
        io_model              TYPE REF TO /iwbep/if_mgw_odata_model
      RETURNING
        VALUE(ro_entity_type) TYPE REF TO /iwbep/if_mgw_odata_entity_typ
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! One property of a value-help type: string, read-only, filterable;
    "! length 0 = take it from the bound structure. Labels are added by the
    "! caller with literals (the annotation API takes no variables).
    CLASS-METHODS add_property
      IMPORTING
        io_entity_type     TYPE REF TO /iwbep/if_mgw_odata_entity_typ
        iv_name            TYPE ty_name40                   "ASSUMPTION A8
        iv_field           TYPE ty_field30                  "ASSUMPTION A8
        iv_length          TYPE i DEFAULT 0
        iv_is_key          TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(ro_property) TYPE REF TO /iwbep/if_mgw_odata_property
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Flags shared by every value-help entity set
    CLASS-METHODS set_vh_set_flags
      IMPORTING
        io_entity_set TYPE REF TO /iwbep/if_mgw_odata_entity_set
      RAISING
        /iwbep/cx_mgw_med_exception.

    "! Common.ValueList + value-list kind + text arrangement on one PO property
    CLASS-METHODS annotate_value_list
      IMPORTING
        io_vocan_model TYPE REF TO /iwbep/if_mgw_vocan_model
        io_po_property TYPE REF TO /iwbep/if_mgw_odata_property
        iv_property    TYPE string        "PO property, e.g. zzinsp_typ
        iv_label       TYPE string        "title of the value help
        iv_vh_set      TYPE string        "entity set that serves it
        iv_vh_key      TYPE string        "key property of that set
        iv_vh_text     TYPE string OPTIONAL   "its description property, if any
        iv_dropdown    TYPE abap_bool DEFAULT abap_false   "dropdown instead of dialog
      RAISING
        /iwbep/cx_mgw_med_exception.
ENDCLASS.


CLASS zcl_mm_po_vh_mpc IMPLEMENTATION.

  METHOD add_value_helps.
    DATA lv_set_name  TYPE ty_name40.                                      "ASSUMPTION A8
    DATA lv_prop_name TYPE ty_name40.                                      "ASSUMPTION A8
    DATA lo_vh_type   TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_entity_set TYPE REF TO /iwbep/if_mgw_odata_entity_set.

    CLEAR gv_last_error.
    IF io_model IS NOT BOUND OR io_vocan_model IS NOT BOUND.
      gv_last_error = 'Model references not bound'.
      RETURN.
    ENDIF.

    " 0. The PO entity type - without it there is nothing to annotate
    TRY.
        DATA(lo_po_type) = io_model->get_entity_type( 'C_PurchaseOrderTPType' ).  "ASSUMPTION A1
      CATCH cx_root INTO DATA(lx_setup).
        " Deliberate: the PO service must come up even if the value helps
        " cannot be added. The missing sets in $metadata are the signal.
        gv_last_error = lx_setup->get_text( ).
        RETURN.
    ENDTRY.

    " 1. Fixed values of a domain: one shared type, one set per domain
    TRY.
        lo_vh_type = create_dom_fixval_type( io_model ).
        LOOP AT fixed_value_fields( ) INTO DATA(ls_field).
          TRY.
              lv_set_name  = |ZVH_{ ls_field-domain }|.
              lv_prop_name = ls_field-property.
              lo_entity_set = lo_vh_type->create_entity_set( lv_set_name ).
              set_vh_set_flags( lo_entity_set ).
              annotate_value_list( io_vocan_model = io_vocan_model
                                   io_po_property = lo_po_type->get_property( lv_prop_name )
                                   iv_property    = ls_field-property
                                   iv_label       = ls_field-label
                                   iv_vh_set      = |{ lv_set_name }|
                                   iv_vh_key      = 'DomainValue'
                                   iv_vh_text     = 'DomainValueText'
                                   iv_dropdown    = abap_true ).
            CATCH cx_root INTO DATA(lx_field).
              gv_last_error = |{ gv_last_error }{ ls_field-property }: { lx_field->get_text( ) }; |.
          ENDTRY.
        ENDLOOP.
      CATCH cx_root INTO DATA(lx_dom).
        gv_last_error = |{ gv_last_error }ZI_DOM_FIXVAL_VH: { lx_dom->get_text( ) }; |.
    ENDTRY.

    " 2. Tender Process - table ZNAT_PROC through ZI_NAT_PROC_VH, dropdown
    TRY.
        lo_vh_type = create_nat_proc_type( io_model ).
        lo_entity_set = lo_vh_type->create_entity_set( 'ZVT_NAT_PROC' ).
        set_vh_set_flags( lo_entity_set ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zznat_proc' )
                             iv_property    = 'zznat_proc'
                             iv_label       = 'Tender Process'
                             iv_vh_set      = 'ZVT_NAT_PROC'
                             iv_vh_key      = 'TenderProcess'
                             iv_vh_text     = 'TenderProcessText'
                             iv_dropdown    = abap_true ).
      CATCH cx_root INTO DATA(lx_nat).
        gv_last_error = |{ gv_last_error }zznat_proc: { lx_nat->get_text( ) }; |.
    ENDTRY.

    " 3. Final Release Code - T16FC through ZI_REL_CODE_VH, dialog
    TRY.
        lo_vh_type = create_rel_code_type( io_model ).
        lo_entity_set = lo_vh_type->create_entity_set( 'ZVT_RELCODE' ).
        set_vh_set_flags( lo_entity_set ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzrelcode' )
                             iv_property    = 'zzrelcode'
                             iv_label       = 'Final Release Code'
                             iv_vh_set      = 'ZVT_RELCODE'
                             iv_vh_key      = 'ReleaseCode'
                             iv_vh_text     = 'ReleaseCodeText' ).
      CATCH cx_root INTO DATA(lx_rel).
        gv_last_error = |{ gv_last_error }zzrelcode: { lx_rel->get_text( ) }; |.
    ENDTRY.

    " 4. Contact Person / Indenting Person - PA0002 through ZI_PERNR_VH,
    "    dialog; one set, two fields (pending the HR decision, see header)
    TRY.
        lo_vh_type = create_pernr_type( io_model ).
        lo_entity_set = lo_vh_type->create_entity_set( 'ZVT_PERNR' ).
        set_vh_set_flags( lo_entity_set ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzcpo' )
                             iv_property    = 'zzcpo'
                             iv_label       = 'Contact Person'
                             iv_vh_set      = 'ZVT_PERNR'
                             iv_vh_key      = 'PersonnelNumber'
                             iv_vh_text     = 'EmployeeName' ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzindper' )
                             iv_property    = 'zzindper'
                             iv_label       = 'Indenting Person'
                             iv_vh_set      = 'ZVT_PERNR'
                             iv_vh_key      = 'PersonnelNumber'
                             iv_vh_text     = 'EmployeeName' ).
      CATCH cx_root INTO DATA(lx_pernr).
        gv_last_error = |{ gv_last_error }zzcpo/zzindper: { lx_pernr->get_text( ) }; |.
    ENDTRY.

    " 5. The four address-number fields - ADRC through ZI_ADRC_VH, dialog;
    "    one set, four fields (pending the functional decision, see header)
    TRY.
        lo_vh_type = create_adrc_type( io_model ).
        lo_entity_set = lo_vh_type->create_entity_set( 'ZVT_ADRC' ).
        set_vh_set_flags( lo_entity_set ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zztpi_add' )
                             iv_property    = 'zztpi_add'
                             iv_label       = 'Third Party Inspection address'
                             iv_vh_set      = 'ZVT_ADRC'
                             iv_vh_key      = 'AddressNumber'
                             iv_vh_text     = 'Name' ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzqad_det' )
                             iv_property    = 'zzqad_det'
                             iv_label       = 'QAD Department'
                             iv_vh_set      = 'ZVT_ADRC'
                             iv_vh_key      = 'AddressNumber'
                             iv_vh_text     = 'Name' ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzport_con' )
                             iv_property    = 'zzport_con'
                             iv_label       = 'Port Consignee'
                             iv_vh_set      = 'ZVT_ADRC'
                             iv_vh_key      = 'AddressNumber'
                             iv_vh_text     = 'Name' ).
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzult_con' )
                             iv_property    = 'zzult_con'
                             iv_label       = 'Ultimate consignee'
                             iv_vh_set      = 'ZVT_ADRC'
                             iv_vh_key      = 'AddressNumber'
                             iv_vh_text     = 'Name' ).
      CATCH cx_root INTO DATA(lx_adrc).
        gv_last_error = |{ gv_last_error }address fields: { lx_adrc->get_text( ) }; |.
    ENDTRY.

    " 6. PO Signing Authority - a user ID: SAP's own set, annotation only
    TRY.
        annotate_value_list( io_vocan_model = io_vocan_model
                             io_po_property = lo_po_type->get_property( 'zzpsa' )
                             iv_property    = 'zzpsa'
                             iv_label       = 'PO Signing Authority'
                             iv_vh_set      = 'C_PurOrdCreatedByValHelp'
                             iv_vh_key      = 'UserID' ).                 "ASSUMPTION A9
      CATCH cx_root INTO DATA(lx_user).
        gv_last_error = |{ gv_last_error }zzpsa: { lx_user->get_text( ) }; |.
    ENDTRY.
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
    ro_entity_type = io_model->create_entity_type( iv_entity_type_name = 'ZI_DOM_FIXVAL_VH'
                                                   iv_def_entity_set   = abap_false ).

    add_property( io_entity_type = ro_entity_type iv_name = 'DomainName' iv_field = 'DOMAINNAME'
                  iv_length = 30 iv_is_key = abap_true
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Domain' ).

    " One 'sap' annotation object, two keys: label, and text = the
    " description property, which gives the dropdown its wording
    DATA(lo_sap_anno) = add_property( io_entity_type = ro_entity_type iv_name = 'DomainValue'
                                      iv_field = 'DOMAINVALUE' iv_length = 10 iv_is_key = abap_true
                          )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap' ).
    lo_sap_anno->add( iv_key = 'label' iv_value = 'Value' ).
    lo_sap_anno->add( iv_key = 'text'  iv_value = 'DomainValueText' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'DomainValueText'
                  iv_field = 'DOMAINVALUETEXT' iv_length = 60
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Description' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'ValuePosition'
                  iv_field = 'VALUEPOSITION' iv_length = 4
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Sequence' ).

    ro_entity_type->bind_structure( iv_structure_name = 'ZIDOMFIXVALVH' ).  "ASSUMPTION A2
  ENDMETHOD.


  METHOD create_nat_proc_type.
    ro_entity_type = io_model->create_entity_type( iv_entity_type_name = 'ZI_NAT_PROC_VH'
                                                   iv_def_entity_set   = abap_false ).

    DATA(lo_sap_anno) = add_property( io_entity_type = ro_entity_type iv_name = 'TenderProcess'
                                      iv_field = 'ZZNAT_PROC' iv_length = 2 iv_is_key = abap_true
                          )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap' ).
    lo_sap_anno->add( iv_key = 'label' iv_value = 'Tender Process' ).
    lo_sap_anno->add( iv_key = 'text'  iv_value = 'TenderProcessText' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'TenderProcessText'
                  iv_field = 'NAT_PROC_DESC'
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Description' ).

    ro_entity_type->bind_structure( iv_structure_name = 'ZINATPROCVH' ).    "ASSUMPTION A2
  ENDMETHOD.


  METHOD create_rel_code_type.
    ro_entity_type = io_model->create_entity_type( iv_entity_type_name = 'ZI_REL_CODE_VH'
                                                   iv_def_entity_set   = abap_false ).

    add_property( io_entity_type = ro_entity_type iv_name = 'ReleaseGroup' iv_field = 'RELEASEGROUP'
                  iv_length = 2 iv_is_key = abap_true
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Release Group' ).

    DATA(lo_sap_anno) = add_property( io_entity_type = ro_entity_type iv_name = 'ReleaseCode'
                                      iv_field = 'RELEASECODE' iv_length = 2 iv_is_key = abap_true
                          )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap' ).
    lo_sap_anno->add( iv_key = 'label' iv_value = 'Release Code' ).
    lo_sap_anno->add( iv_key = 'text'  iv_value = 'ReleaseCodeText' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'ReleaseCodeText'
                  iv_field = 'RELEASECODETEXT'
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Description' ).

    ro_entity_type->bind_structure( iv_structure_name = 'ZIRELCODEVH' ).    "ASSUMPTION A2
  ENDMETHOD.


  METHOD create_pernr_type.
    ro_entity_type = io_model->create_entity_type( iv_entity_type_name = 'ZI_PERNR_VH'
                                                   iv_def_entity_set   = abap_false ).

    DATA(lo_sap_anno) = add_property( io_entity_type = ro_entity_type iv_name = 'PersonnelNumber'
                                      iv_field = 'PERSONNELNUMBER' iv_length = 8 iv_is_key = abap_true
                          )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap' ).
    lo_sap_anno->add( iv_key = 'label' iv_value = 'Personnel Number' ).
    lo_sap_anno->add( iv_key = 'text'  iv_value = 'EmployeeName' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'LastName' iv_field = 'LASTNAME'
                  iv_length = 40
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Last Name' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'FirstName' iv_field = 'FIRSTNAME'
                  iv_length = 40
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'First Name' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'EmployeeName' iv_field = 'EMPLOYEENAME'
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Name' ).

    ro_entity_type->bind_structure( iv_structure_name = 'ZIPERNRVH' ).      "ASSUMPTION A2
  ENDMETHOD.


  METHOD create_adrc_type.
    ro_entity_type = io_model->create_entity_type( iv_entity_type_name = 'ZI_ADRC_VH'
                                                   iv_def_entity_set   = abap_false ).

    DATA(lo_sap_anno) = add_property( io_entity_type = ro_entity_type iv_name = 'AddressNumber'
                                      iv_field = 'ADDRESSNUMBER' iv_length = 10 iv_is_key = abap_true
                          )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap' ).
    lo_sap_anno->add( iv_key = 'label' iv_value = 'Address Number' ).
    lo_sap_anno->add( iv_key = 'text'  iv_value = 'Name' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'Name' iv_field = 'NAME' iv_length = 40
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Name' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'City' iv_field = 'CITY' iv_length = 40
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'City' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'Street' iv_field = 'STREET' iv_length = 60
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Street' ).

    add_property( io_entity_type = ro_entity_type iv_name = 'PostalCode' iv_field = 'POSTALCODE'
                  iv_length = 10
      )->/iwbep/if_mgw_odata_annotatabl~create_annotation( 'sap'
      )->add( iv_key = 'label' iv_value = 'Postal Code' ).

    ro_entity_type->bind_structure( iv_structure_name = 'ZIADRCVH' ).       "ASSUMPTION A2
  ENDMETHOD.


  METHOD add_property.
    ro_property = io_entity_type->create_property( iv_property_name  = iv_name
                                                   iv_abap_fieldname = iv_field ).
    IF iv_is_key = abap_true.
      ro_property->set_is_key( ).
    ENDIF.
    ro_property->set_type_edm_string( ).
    IF iv_length > 0.
      ro_property->set_maxlength( iv_length ).
    ENDIF.
    ro_property->set_creatable( abap_false ).
    ro_property->set_updatable( abap_false ).
    ro_property->set_filterable( abap_true ).
    ro_property->set_sortable( abap_true ).
    ro_property->set_nullable( abap_false ).
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
    "    uses. FIXED_VALUES renders a dropdown, STANDARD the dialog.
    IF iv_dropdown = abap_true.
      io_po_property->set_value_list( /iwbep/if_mgw_odata_property=>gcs_value_list_type_property-fixed_values ).
    ELSE.
      io_po_property->set_value_list( /iwbep/if_mgw_odata_property=>gcs_value_list_type_property-standard ).
    ENDIF.

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

    " In/out: PO field <-> key of the value help
    DATA(lo_param) = lo_parameters->create_record( |{ gc_common }.ValueListParameterInOut| ).
    lo_param->create_property( 'LocalDataProperty' )->create_simple_value( )->set_property_path( iv_property ).
    lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( iv_vh_key ).

    " Display only: the description, where the value help has one
    IF iv_vh_text IS NOT INITIAL.
      lo_param = lo_parameters->create_record( |{ gc_common }.ValueListParameterDisplayOnly| ).
      lo_param->create_property( 'ValueListProperty' )->create_simple_value( )->set_string( iv_vh_text ).
    ENDIF.

    " 3. Text arrangement of the PO field: key and description together,
    "    key first, as in the GUI popup ("1 Source Inspection").
    lo_ann_target->create_annotation( 'com.sap.vocabularies.UI.v1.TextArrangement'
      )->create_simple_value( )->set_enum_member_by_name(
        'com.sap.vocabularies.UI.v1.TextArrangementType/TextLast' ).
  ENDMETHOD.

ENDCLASS.
