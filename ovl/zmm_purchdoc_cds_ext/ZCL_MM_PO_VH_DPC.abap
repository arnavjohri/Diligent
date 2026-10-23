*----------------------------------------------------------------------*
* Class      : ZCL_MM_PO_VH_DPC
* Title      : Data for the value-help entity sets that ZCL_MM_PO_VH_MPC
*              adds to the model of MM_PUR_PO_MAINT_V2_SRV
* Author     : Arnav Johri (Diligent)      Created: 22.10.2026
* Project    : OVL - Fiori F4 on EKKO custom fields (ZC_PURCHASEORDERTP_EXT)
* Ships by   : paste (ADT global class). Called from ZEI_MM_PO_VH_DPC v3,
*              the enhancement at the START of GET_ENTITYSET in
*              CL_MM_PUR_PO_MAINT_V2_DPC_EXT.
*----------------------------------------------------------------------*
* Two families of sets, both read from a CDS view by its DDL name:
*   ZVH_<DOMAIN>  fixed values of one domain from ZI_DOM_FIXVAL_VH
*                 (DD07T); the domain comes from the set name.
*   ZVT_<NAME>    one value-help view per set, see SET_SOURCE.
* The dialog's $filter arrives as an Open SQL WHERE clause (converted to
* the ABAP field names by the request context) and goes to the DB; the
* rows are then sorted and paged in memory with the framework utilities.
* ER_ENTITYSET is created here with the SQL view's structure, which is
* what the DPC's COPY_DATA_TO_REF would have done.
*
* ASSUMPTION A1: the SQL view names (structures) below match the DDL
*   sources in ovl/zmm_purchdoc_cds_ext/. ZINATPROCVH belongs to
*   ZI_NAT_PROC_VH, whose fields were taken from the GUI module, not
*   from SE11 - confirm the view activates before relying on it.
* ASSUMPTION A2: an empty dynamic WHERE string selects all rows.
* Change: 22/10/26 v2 - ZVT_GEM_ORDER (GEM PO No., view ZI_GEM_ORDER_VH).
*         23/10/26 v3 - ZVT_ADRC goes live (four address fields). ADRC
*         holds every address in the system, so a page request without
*         $orderby now reads only up to the requested page from the
*         database, sorted there, and counts with COUNT(*). Everything
*         else (dropdowns without $top, dialog sorted by a column) takes
*         the v2 path unchanged.
*         23/10/26 v4 - F4 on the address fields: "No data found". The
*         dialog always sends $orderby on its key column (sort arrow on
*         Address Number), so the v3 path never ran and every dialog
*         read all of ADRC into memory. The $orderby now goes to the
*         database as well (DB_ORDER_BY); only a sort on a property
*         that is not a column of the view still takes the v2 path.
*         Same version: the SQL view of a CDS view over a client table
*         (ADRC, T16FC, ZGEM_ORDERDET ...) starts with MANDT, the CDS
*         entity does not. SELECT * FROM the entity INTO a table of the
*         SQL view's type was therefore one column off; both reads now
*         fill by name (CORRESPONDING FIELDS). ZI_DOM_FIXVAL_VH (DD07L,
*         no client) was the only set tested and never had the gap.
*         23/10/26 v5 - Tender Process (ZVT_NAT_PROC): its properties
*         TenderProcess / TenderProcessText are not the view's column
*         names (ZZNAT_PROC / NAT_PROC_DESC). A $orderby on them went
*         to /IWBEP/CL_MGW_DATA_UTIL=>ORDERBY, which sorts by component
*         name and has no such column. A sort that DB_ORDER_BY cannot
*         map is now left out; the list keeps its default order
*         (SERIAL_NO, as in the GUI F4).
*----------------------------------------------------------------------*
CLASS zcl_mm_po_vh_dpc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Serve one value-help entity set. EV_SERVED = abap_false when the set
    "! name is none of ours (the caller then lets SAP's code run).
    CLASS-METHODS get_entityset
      IMPORTING
        iv_entity_set_name TYPE csequence
        iv_osql_where      TYPE string                      "$filter as Open SQL, ABAP names
        it_order           TYPE /iwbep/t_mgw_sorting_order
        is_paging          TYPE /iwbep/s_mgw_paging
      EXPORTING
        er_entityset       TYPE REF TO data
        ev_count           TYPE i                           "rows before paging ($inlinecount)
        ev_served          TYPE abap_bool.

  PRIVATE SECTION.
    "! CDS view, SQL view (structure) and default sort field of one ZVT_ set
    CLASS-METHODS set_source
      IMPORTING
        iv_entity_set_name TYPE csequence
      EXPORTING
        ev_view            TYPE string
        ev_structure       TYPE string
        ev_sort_field      TYPE string.

    "! ORDER BY for the database (v4): the dialog's $orderby when every
    "! property in it is a column of the SQL view, the default sort field
    "! when there is no $orderby, and initial when a property cannot be
    "! mapped (the caller then sorts in memory, as in v2)
    CLASS-METHODS db_order_by
      IMPORTING
        it_order        TYPE /iwbep/t_mgw_sorting_order
        iv_structure    TYPE string
        iv_default      TYPE string
      RETURNING
        VALUE(rv_order) TYPE string.
ENDCLASS.


CLASS zcl_mm_po_vh_dpc IMPLEMENTATION.

  METHOD get_entityset.
    DATA lv_view       TYPE string.
    DATA lv_structure  TYPE string.
    DATA lv_sort_field TYPE string.
    DATA lv_where      TYPE string.
    DATA lv_rows       TYPE i.
    DATA lv_order      TYPE string.
    FIELD-SYMBOLS <lt_rows> TYPE STANDARD TABLE.

    CLEAR: er_entityset, ev_count, ev_served.

    IF iv_entity_set_name CP 'ZVH_*'.
      " fixed values of one domain: the domain is the rest of the set name
      lv_view       = 'ZI_DOM_FIXVAL_VH'.
      lv_structure  = 'ZIDOMFIXVALVH'.
      lv_sort_field = 'VALUEPOSITION'.
      lv_where      = |DOMAINNAME = '{ iv_entity_set_name+4 }'|.
    ELSE.
      set_source( EXPORTING iv_entity_set_name = iv_entity_set_name
                  IMPORTING ev_view            = lv_view
                            ev_structure       = lv_structure
                            ev_sort_field      = lv_sort_field ).
      IF lv_view IS INITIAL.
        RETURN.                                   "not ours
      ENDIF.
    ENDIF.
    ev_served = abap_true.

    " the dialog's filters, pushed to the database
    IF iv_osql_where IS NOT INITIAL.
      IF lv_where IS INITIAL.
        lv_where = iv_osql_where.
      ELSE.
        lv_where = |{ lv_where } AND ( { iv_osql_where } )|.
      ENDIF.
    ENDIF.

    CREATE DATA er_entityset TYPE STANDARD TABLE OF (lv_structure).
    ASSIGN er_entityset->* TO <lt_rows>.

*BOC By SAP_ABAP on 23/10/26
    " a page of a large list (ADRC): sort and cut on the database, count
    " there, and hand only the requested page back
*   IF it_order IS INITIAL AND is_paging-top > 0 AND lv_sort_field IS NOT INITIAL.
    " v4: the dialog always sends $orderby on its key column, so the
    " condition above never held for a dialog; the sort goes to the DB too
    lv_order = db_order_by( it_order     = it_order
                            iv_structure = lv_structure
                            iv_default   = lv_sort_field ).
    IF is_paging-top > 0 AND lv_order IS NOT INITIAL.
      SELECT COUNT(*) FROM (lv_view)
        WHERE (lv_where)                                                "ASSUMPTION A2
        INTO @ev_count.

      lv_rows = is_paging-skip + is_paging-top.
      SELECT * FROM (lv_view)
        WHERE (lv_where)
*       ORDER BY (lv_sort_field)
        ORDER BY (lv_order)
*       INTO TABLE @<lt_rows>
        INTO CORRESPONDING FIELDS OF TABLE @<lt_rows>   "v4: MANDT in the SQL view
        UP TO @lv_rows ROWS.

      /iwbep/cl_mgw_data_util=>paging( EXPORTING is_paging = is_paging
                                       CHANGING  ct_data   = <lt_rows> ).
      RETURN.
    ENDIF.
*EOC By SAP_ABAP on 23/10/26

*BOC By SAP_ABAP on 23/10/26
*   SELECT * FROM (lv_view)
*     WHERE (lv_where)                                                  "ASSUMPTION A2
*     INTO TABLE @<lt_rows>.
    " v4: by name - the SQL view of a client table has MANDT first, the
    " CDS entity does not
    SELECT * FROM (lv_view)
      WHERE (lv_where)                                                  "ASSUMPTION A2
      INTO CORRESPONDING FIELDS OF TABLE @<lt_rows>.
*EOC By SAP_ABAP on 23/10/26

    " default order of the list, then $orderby if the dialog sorts
    IF lv_sort_field IS NOT INITIAL.
      SORT <lt_rows> BY (lv_sort_field).
    ENDIF.
*BOC By SAP_ABAP on 23/10/26
*   /iwbep/cl_mgw_data_util=>orderby( EXPORTING it_order = it_order
*                                     CHANGING  ct_data  = <lt_rows> ).
    " v5: only a sort whose properties are columns of the view (initial
    " LV_ORDER = DB_ORDER_BY could not map one, e.g. TenderProcess)
    IF lv_order IS NOT INITIAL.
      /iwbep/cl_mgw_data_util=>orderby( EXPORTING it_order = it_order
                                        CHANGING  ct_data  = <lt_rows> ).
    ENDIF.
*EOC By SAP_ABAP on 23/10/26

    ev_count = lines( <lt_rows> ).

    /iwbep/cl_mgw_data_util=>paging( EXPORTING is_paging = is_paging
                                     CHANGING  ct_data   = <lt_rows> ).
  ENDMETHOD.


  METHOD set_source.
    CLEAR: ev_view, ev_structure, ev_sort_field.
    CASE iv_entity_set_name.
      WHEN 'ZVT_NAT_PROC'.                        "Tender Process (ZNAT_PROC)
        ev_view       = 'ZI_NAT_PROC_VH'.
        ev_structure  = 'ZINATPROCVH'.           "ASSUMPTION A1
        ev_sort_field = 'SERIAL_NO'.
      WHEN 'ZVT_RELCODE'.                         "Final Release Code (T16FC)
        ev_view       = 'ZI_REL_CODE_VH'.
        ev_structure  = 'ZIRELCODEVH'.
        ev_sort_field = 'RELEASEGROUP'.
      WHEN 'ZVT_PERNR'.                           "Contact / Indenting person (PA0002)
        ev_view       = 'ZI_PERNR_VH'.
        ev_structure  = 'ZIPERNRVH'.
        ev_sort_field = 'LASTNAME'.
      WHEN 'ZVT_ADRC'.                            "Address numbers (ADRC)
        ev_view       = 'ZI_ADRC_VH'.
        ev_structure  = 'ZIADRCVH'.
        ev_sort_field = 'NAME'.
      WHEN 'ZVT_GEM_ORDER'.                       "GEM PO No. (ZGEM_ORDERDET)
        ev_view       = 'ZI_GEM_ORDER_VH'.
        ev_structure  = 'ZIGEMORDERVH'.
        ev_sort_field = 'GEMORDERID'.
      " next: ZVT_MSE (ZMSE_EKKO), ZVT_TENDER (ZMM_PUR_TENDER_D) - once
      " their fields are known and the views exist
    ENDCASE.
  ENDMETHOD.


  METHOD db_order_by.
    DATA lo_descr  TYPE REF TO cl_abap_typedescr.
    DATA lo_struct TYPE REF TO cl_abap_structdescr.
    DATA lv_column TYPE string.
    DATA lv_dir    TYPE string.

    rv_order = iv_default.
    IF it_order IS INITIAL.
      RETURN.                                     "no $orderby: default sort
    ENDIF.

    CLEAR rv_order.
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = iv_structure
                                         RECEIVING  p_descr_ref    = lo_descr
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0 OR lo_descr IS NOT BOUND OR lo_descr->kind <> cl_abap_typedescr=>kind_struct.
      RETURN.                                     "initial: sort in memory
    ENDIF.
    lo_struct ?= lo_descr.

    " the value-help properties are the view's columns in mixed case
    " (AddressNumber = ADDRESSNUMBER); a property that is not a column
    " leaves the whole sort to the in-memory path
    LOOP AT it_order INTO DATA(ls_order).
      lv_column = to_upper( ls_order-property ).
      IF NOT line_exists( lo_struct->components[ name = lv_column ] ).
        CLEAR rv_order.
        RETURN.
      ENDIF.
      IF to_lower( ls_order-order ) = 'desc'.
        lv_dir = 'DESCENDING'.
      ELSE.
        lv_dir = 'ASCENDING'.
      ENDIF.
      IF rv_order IS NOT INITIAL.
        rv_order = |{ rv_order }, |.
      ENDIF.
      rv_order = |{ rv_order }{ lv_column } { lv_dir }|.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
