*&---------------------------------------------------------------------*
*& Report         : ZR_ICF_URL_LIST
*& Title          : All ICF service URLs of the system as a flat list
*& Project        : Internal developer utility       Module: BC
*& Related FS     : None - developer tool (CPI needs the valid URL list)
*& Author         : Arnav Johri                  Date: 02.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Reads the ICF service tree (table ICFSERVICE - the tree SICF shows)
*&   and lists every node as a full URL path, one row per node, in an
*&   ALV that exports to Excel. Each row says whether the node itself is
*&   active, whether every node above it is active too (only then the
*&   URL answers), whether it is an end node, and its virtual host.
*&   Optional base URL (scheme://host:port from SMICM) is prefixed so
*&   the list can be handed over as it is. Read-only: nothing in the
*&   system is changed.
*&
*& CHANGE HISTORY
*&   02.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zr_icf_url_list.

* One ICF node as stored in ICFSERVICE
TYPES: BEGIN OF ty_svc,
         icf_name   TYPE icfservice-icf_name,
         icfparguid TYPE icfservice-icfparguid,
         icfnodguid TYPE icfservice-icfnodguid,
         icfactive  TYPE icfservice-icfactive,
       END OF ty_svc.
TYPES ty_t_svc TYPE SORTED TABLE OF ty_svc
        WITH NON-UNIQUE KEY icfnodguid
        WITH NON-UNIQUE SORTED KEY par COMPONENTS icfparguid.

* Path segments collected while walking up the tree (leaf first)
TYPES ty_t_seg TYPE STANDARD TABLE OF icfservice-icf_name WITH DEFAULT KEY.

* One output row
TYPES: BEGIN OF ty_out,
         vhost  TYPE c LENGTH 40,            "virtual host the node hangs under
         url    TYPE c LENGTH 255,           "base URL + path
         path   TYPE c LENGTH 255,           "/sap/bc/... as SICF shows it
         node   TYPE icfservice-icf_name,    "last segment
         active TYPE c LENGTH 1,             "node itself active
         chain  TYPE c LENGTH 1,             "node and all parents active
         leaf   TYPE c LENGTH 1,             "no children below
         depth  TYPE i,                      "number of path segments
       END OF ty_out.
TYPES ty_t_out TYPE STANDARD TABLE OF ty_out WITH DEFAULT KEY.

DATA: gt_svc    TYPE ty_t_svc,
      gt_out    TYPE ty_t_out,
      gv_vhosts TYPE abap_bool,     "virtual hosts are rows of ICFSERVICE
      go_alv    TYPE REF TO cl_salv_table.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_base(100) TYPE c LOWER CASE,
            p_patt(100) TYPE c LOWER CASE,
            p_chain     TYPE abap_bool AS CHECKBOX DEFAULT abap_true,
            p_leaf      TYPE abap_bool AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.
* Selection texts (maintain in SE38 -> Text elements -> Selection texts):
*   P_BASE  Base URL (scheme://host:port)
*   P_PATT  Path starts with (* and + allowed)
*   P_CHAIN Only URLs active end to end
*   P_LEAF  Only end nodes (no children)
*   TEXT-001 Selection

START-OF-SELECTION.
  PERFORM read_tree.
  IF gt_svc IS INITIAL.
    MESSAGE 'No ICF nodes found - table ICFSERVICE is empty' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM build_list.
  IF gt_out IS INITIAL.
    MESSAGE 'No URL matches the selection' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM display_alv.

*&---------------------------------------------------------------------*
*& Form READ_TREE
*&---------------------------------------------------------------------*
*  Loads the whole ICF service tree and finds out how the virtual hosts
*  are stored, so the path builder knows whether to drop the top node.
*----------------------------------------------------------------------*
FORM read_tree.

  SELECT icf_name, icfparguid, icfnodguid, icfactive
    FROM icfservice
    INTO TABLE @gt_svc.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

* ASSUMPTION: the virtual hosts (default_host, ...) are rows of ICFSERVICE
* whose parent GUID points nowhere, so the top node of every chain is the
* virtual host and is NOT part of the URL. default_host exists on every
* system, so its presence in the table confirms this. If it is absent the
* virtual hosts live elsewhere and every segment found belongs to the URL.
  gv_vhosts = abap_false.
  LOOP AT gt_svc INTO DATA(ls_svc).
    IF to_lower( ls_svc-icf_name ) = 'default_host'.
      gv_vhosts = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_LIST
*&---------------------------------------------------------------------*
*  One output row per node: walk up to the root collecting the names,
*  then read them root-first into the path.
*----------------------------------------------------------------------*
FORM build_list.

  DATA: ls_out    TYPE ty_out,
        ls_par    TYPE ty_svc,
        lt_seg    TYPE ty_t_seg,
        lv_seg    TYPE icfservice-icf_name,
        lv_guid   TYPE icfservice-icfparguid,
        lv_path   TYPE string,
        lv_base   TYPE string,
        lv_patt   TYPE string,
        lv_chain  TYPE abap_bool,
        lv_orphan TYPE abap_bool,
        lv_top    TYPE i,
        lv_idx    TYPE i,
        lv_len    TYPE i.

* Base URL without a trailing slash - the path always starts with one
  lv_base = p_base.
  CONDENSE lv_base NO-GAPS.
  lv_len = strlen( lv_base ).
  IF lv_len > 0.
    lv_len = lv_len - 1.
    IF lv_base+lv_len(1) = '/'.
      lv_base = lv_base(lv_len).
    ENDIF.
  ENDIF.

* Path filter: a value without a wildcard means "starts with"
  lv_patt = p_patt.
  CONDENSE lv_patt NO-GAPS.
  IF lv_patt IS NOT INITIAL AND lv_patt NA '*'.
    CONCATENATE lv_patt '*' INTO lv_patt.
  ENDIF.

  LOOP AT gt_svc INTO DATA(ls_svc).
    CLEAR: ls_out, lt_seg, lv_orphan, lv_path.
    lv_chain = ls_svc-icfactive.
    APPEND ls_svc-icf_name TO lt_seg.
    lv_guid = ls_svc-icfparguid.

*   Walk up: parent of parent ... until the root GUID or a missing row
    DO 64 TIMES.
      IF lv_guid IS INITIAL OR lv_guid CO '0 '.
        EXIT.                                "top of the tree reached
      ENDIF.
      READ TABLE gt_svc INTO ls_par WITH TABLE KEY icfnodguid = lv_guid.
      IF sy-subrc <> 0.
        lv_orphan = abap_true.               "parent row does not exist
        EXIT.
      ENDIF.
      APPEND ls_par-icf_name TO lt_seg.
      IF ls_par-icfactive <> abap_true.
        lv_chain = abap_false.
      ENDIF.
      lv_guid = ls_par-icfparguid.
      IF sy-index = 64.
        lv_orphan = abap_true.               "cycle guard - tree is deeper than 64
      ENDIF.
    ENDDO.

*   Top segment: the virtual host (dropped from the URL) or already a path
    lv_top = lines( lt_seg ).
    IF gv_vhosts = abap_true AND lv_orphan = abap_false.
      IF lv_top = 1.
        CONTINUE.                            "the row IS a virtual host
      ENDIF.
      ls_out-vhost = lt_seg[ lv_top ].
      DELETE lt_seg INDEX lv_top.
    ELSEIF lv_orphan = abap_true.
      ls_out-vhost = '? parent missing'.
    ELSE.
      ls_out-vhost = '(not in ICFSERVICE)'.
    ENDIF.

*   Segments were collected leaf first - the URL reads root first
    lv_idx = lines( lt_seg ).
    WHILE lv_idx > 0.
      READ TABLE lt_seg INDEX lv_idx INTO lv_seg.
      CONCATENATE lv_path '/' lv_seg INTO lv_path.
      lv_idx = lv_idx - 1.
    ENDWHILE.

*   Filters
    IF p_chain = abap_true AND lv_chain <> abap_true.
      CONTINUE.
    ENDIF.
    IF lv_patt IS NOT INITIAL AND lv_path NP lv_patt.
      CONTINUE.
    ENDIF.
    READ TABLE gt_svc TRANSPORTING NO FIELDS
         WITH KEY par COMPONENTS icfparguid = ls_svc-icfnodguid.
    IF sy-subrc <> 0.
      ls_out-leaf = abap_true.
    ENDIF.
    IF p_leaf = abap_true AND ls_out-leaf <> abap_true.
      CONTINUE.
    ENDIF.

    ls_out-path   = lv_path.
    ls_out-node   = ls_svc-icf_name.
    ls_out-active = ls_svc-icfactive.
    ls_out-chain  = lv_chain.
    ls_out-depth  = lines( lt_seg ).
    IF lv_base IS NOT INITIAL.
      CONCATENATE lv_base lv_path INTO ls_out-url.
    ELSE.
      ls_out-url = lv_path.
    ENDIF.
    APPEND ls_out TO gt_out.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM display_alv.

  DATA lo_col TYPE REF TO cl_salv_column.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                              CHANGING  t_table      = gt_out ).

      go_alv->get_functions( )->set_all( abap_true ).
      go_alv->get_columns( )->set_optimize( abap_true ).
      go_alv->get_display_settings( )->set_striped_pattern( abap_true ).
      go_alv->get_display_settings( )->set_list_header( 'ICF service URLs of this system' ).

      lo_col = go_alv->get_columns( )->get_column( 'VHOST' ).
      lo_col->set_short_text( 'Virt. host' ).
      lo_col->set_medium_text( 'Virtual host' ).
      lo_col->set_long_text( 'Virtual host' ).

      lo_col = go_alv->get_columns( )->get_column( 'URL' ).
      lo_col->set_short_text( 'URL' ).
      lo_col->set_medium_text( 'Full URL' ).
      lo_col->set_long_text( 'Full URL (base + path)' ).

      lo_col = go_alv->get_columns( )->get_column( 'PATH' ).
      lo_col->set_short_text( 'Path' ).
      lo_col->set_medium_text( 'Service path' ).
      lo_col->set_long_text( 'Service path as in SICF' ).

      lo_col = go_alv->get_columns( )->get_column( 'NODE' ).
      lo_col->set_short_text( 'Node' ).
      lo_col->set_medium_text( 'Service node' ).
      lo_col->set_long_text( 'Service node (last segment)' ).

      lo_col = go_alv->get_columns( )->get_column( 'ACTIVE' ).
      lo_col->set_short_text( 'Active' ).
      lo_col->set_medium_text( 'Node active' ).
      lo_col->set_long_text( 'Node itself active' ).

      lo_col = go_alv->get_columns( )->get_column( 'CHAIN' ).
      lo_col->set_short_text( 'Valid' ).
      lo_col->set_medium_text( 'Valid end to end' ).
      lo_col->set_long_text( 'Valid: node and all parents active' ).

      lo_col = go_alv->get_columns( )->get_column( 'LEAF' ).
      lo_col->set_short_text( 'End node' ).
      lo_col->set_medium_text( 'End node' ).
      lo_col->set_long_text( 'End node (no children)' ).

      lo_col = go_alv->get_columns( )->get_column( 'DEPTH' ).
      lo_col->set_short_text( 'Depth' ).
      lo_col->set_medium_text( 'Depth' ).
      lo_col->set_long_text( 'Depth (number of segments)' ).

      go_alv->get_sorts( )->add_sort( 'PATH' ).

      go_alv->display( ).

    CATCH cx_salv_msg cx_salv_not_found cx_salv_existing
          cx_salv_data_error INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.
