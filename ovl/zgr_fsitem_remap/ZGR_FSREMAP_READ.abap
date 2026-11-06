*&---------------------------------------------------------------------*
*& Report         : ZGR_FSREMAP_READ
*& Title          : Group Reporting - FS item remap: read the cube
*& Project        : OVL                          Module: FI-CS (Group Reporting)
*& Related FS     : None - request in chat, 06.11.2026
*&                  (repo: ovl/zgr_fsitem_remap/NOTES.md)
*& Author         : Arnav Johri                  Date: 06.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Reads ZI_GR_FSREMAP_CUBE (customer copy of the Group Data Analysis
*&   cube with the remapped FS item) for one ledger, dimension, version
*&   and fiscal year, a period range and optional consolidation units
*&   and FS items. Sums the amounts in local and group currency per
*&   unit, FS item, new FS item and period and shows them in an ALV
*&   with a "Remapped" flag where the new item differs from the posted
*&   one. Every filter that HANA pushes into the ACDOCU key is
*&   obligatory, so the cube is never read unfiltered (that read dumps
*&   DBSQL_SQL_INTERNAL_DB_ERROR, HANA statement memory, 06.11.2026).
*&
*& CHANGE HISTORY
*&   06.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zgr_fsremap_read.

*----------------------------------------------------------------------*
* Types and data
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_result,
         consolidationunit         TYPE zi_gr_fsremap_cube-consolidationunit,
         financialstatementitem    TYPE zi_gr_fsremap_cube-financialstatementitem,
         newfinancialstatementitem TYPE zi_gr_fsremap_cube-newfinancialstatementitem,
         fiscalyearperiod          TYPE zi_gr_fsremap_cube-fiscalyearperiod,
         localcurrency             TYPE zi_gr_fsremap_cube-localcurrency,
         amountinlocalcurrency     TYPE zi_gr_fsremap_cube-amountinlocalcurrency,
         groupcurrency             TYPE zi_gr_fsremap_cube-groupcurrency,
         amountingroupcurrency     TYPE zi_gr_fsremap_cube-amountingroupcurrency,
         remapped                  TYPE abap_bool,
       END OF ty_result,
       ty_t_result TYPE STANDARD TABLE OF ty_result WITH DEFAULT KEY.

DATA: gt_result TYPE ty_t_result,
      gv_poper  TYPE zi_gr_fsremap_cube-fiscalperiod,
      gv_bunit  TYPE zi_gr_fsremap_cube-consolidationunit,
      gv_ritem  TYPE zi_gr_fsremap_cube-financialstatementitem,
      gv_tt1    TYPE c LENGTH 40,
      gv_tt2    TYPE c LENGTH 40.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE gv_tt1.
PARAMETERS: p_rldnr TYPE zi_gr_fsremap_cube-consolidationledger    OBLIGATORY,
            p_dimen TYPE zi_gr_fsremap_cube-consolidationdimension OBLIGATORY,
            p_rvers TYPE zi_gr_fsremap_cube-consolidationversion   OBLIGATORY,
            p_ryear TYPE zi_gr_fsremap_cube-fiscalyear             OBLIGATORY.
SELECT-OPTIONS: s_poper FOR gv_poper OBLIGATORY,
                s_bunit FOR gv_bunit,
                s_ritem FOR gv_ritem.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE gv_tt2.
PARAMETERS: p_cuhry TYPE fincs_hryid_consunit,
            p_pchry TYPE fincs_hryid_profitcenter,
            p_sghry TYPE fincs_hryid_segment,
            p_keydt TYPE vdm_v_key_date.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* Events
*----------------------------------------------------------------------*
INITIALIZATION.
  gv_tt1  = 'Selection'.
  gv_tt2  = 'Cube parameters ($ = no hierarchy)'.
  p_cuhry = '$'.
  p_pchry = '$'.
  p_sghry = '$'.
  p_keydt = sy-datum.

AT SELECTION-SCREEN.
  IF p_cuhry IS INITIAL OR p_pchry IS INITIAL OR p_sghry IS INITIAL.
    MESSAGE 'Enter $ in the hierarchy fields when no hierarchy is to be used' TYPE 'E'.
  ENDIF.
  IF p_keydt IS INITIAL.
    MESSAGE 'Enter a key date' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM fetch_data.
  IF gt_result IS INITIAL.
    MESSAGE 'No data found for the given selection' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

END-OF-SELECTION.
  PERFORM display_alv.

*&---------------------------------------------------------------------*
*& Form fetch_data
*&---------------------------------------------------------------------*
*  Read the cube with every pushdown filter set, aggregated per unit /
*  FS item / new FS item / period. INTO CORRESPONDING FIELDS on purpose:
*  the result structure carries one more component (REMAPPED) than the
*  field list, so a position-based INTO would not match.
*----------------------------------------------------------------------*
FORM fetch_data.
  CLEAR gt_result.

  SELECT consolidationunit,
         financialstatementitem,
         newfinancialstatementitem,
         fiscalyearperiod,
         localcurrency,
         SUM( amountinlocalcurrency ) AS amountinlocalcurrency,
         groupcurrency,
         SUM( amountingroupcurrency ) AS amountingroupcurrency
    FROM zi_gr_fsremap_cube( p_consolidationunithierarchy = @p_cuhry,
                             p_consolidationprftctrhier   = @p_pchry,
                             p_consolidationsegmenthier   = @p_sghry,
                             p_keydate                    = @p_keydt )
    WHERE consolidationledger     = @p_rldnr
      AND consolidationdimension  = @p_dimen
      AND consolidationversion    = @p_rvers
      AND fiscalyear              = @p_ryear
      AND fiscalperiod           IN @s_poper
      AND consolidationunit      IN @s_bunit
      AND financialstatementitem IN @s_ritem
    GROUP BY consolidationunit,
             financialstatementitem,
             newfinancialstatementitem,
             fiscalyearperiod,
             localcurrency,
             groupcurrency
    ORDER BY consolidationunit,
             financialstatementitem,
             newfinancialstatementitem,
             fiscalyearperiod
    INTO CORRESPONDING FIELDS OF TABLE @gt_result.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<ls_result>).
    IF <ls_result>-newfinancialstatementitem <> <ls_result>-financialstatementitem.
      <ls_result>-remapped = abap_true.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column_table,
        lv_title   TYPE lvc_title,
        lv_msg     TYPE string.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_result ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      lv_msg = lx_msg->get_text( ).
      MESSAGE lv_msg TYPE 'E'.
  ENDTRY.

  lo_alv->get_functions( )->set_all( abap_true ).
  lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
  lv_title = |FS item remap - ledger { p_rldnr } dim. { p_dimen } version { p_rvers } year { p_ryear }|.
  lo_alv->get_display_settings( )->set_list_header( lv_title ).

  lo_columns = lo_alv->get_columns( ).
  lo_columns->set_optimize( abap_true ).

  PERFORM set_column_text USING lo_columns 'CONSOLIDATIONUNIT'
                                'Cons.Unit' 'Cons. Unit' 'Consolidation Unit'.
  PERFORM set_column_text USING lo_columns 'FINANCIALSTATEMENTITEM'
                                'FS Item' 'FS Item (posted)' 'FS Item as posted'.
  PERFORM set_column_text USING lo_columns 'NEWFINANCIALSTATEMENTITEM'
                                'New Item' 'New FS Item' 'New FS Item (remapped)'.
  PERFORM set_column_text USING lo_columns 'FISCALYEARPERIOD'
                                'Year/Per.' 'Fiscal Year/Period' 'Fiscal Year / Period'.
  PERFORM set_column_text USING lo_columns 'LOCALCURRENCY'
                                'LC' 'Local Currency' 'Local Currency'.
  PERFORM set_column_text USING lo_columns 'AMOUNTINLOCALCURRENCY'
                                'Amt LC' 'Amount in LC' 'Amount in Local Currency'.
  PERFORM set_column_text USING lo_columns 'GROUPCURRENCY'
                                'GC' 'Group Currency' 'Group Currency'.
  PERFORM set_column_text USING lo_columns 'AMOUNTINGROUPCURRENCY'
                                'Amt GC' 'Amount in GC' 'Amount in Group Currency'.
  PERFORM set_column_text USING lo_columns 'REMAPPED'
                                'Remapped' 'Remapped' 'Remapped (new item differs)'.

  TRY.
      lo_column ?= lo_columns->get_column( 'AMOUNTINLOCALCURRENCY' ).
      lo_column->set_currency_column( 'LOCALCURRENCY' ).
      lo_column ?= lo_columns->get_column( 'AMOUNTINGROUPCURRENCY' ).
      lo_column->set_currency_column( 'GROUPCURRENCY' ).
      lo_column ?= lo_columns->get_column( 'REMAPPED' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>checkbox ).
    CATCH cx_salv_not_found INTO DATA(lx_not_found).
      lv_msg = lx_not_found->get_text( ).
      MESSAGE lv_msg TYPE 'E'.
  ENDTRY.

  lo_alv->display( ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_column_text
*&---------------------------------------------------------------------*
*  Readable column headings; a column that is not found is reported,
*  not skipped silently.
*----------------------------------------------------------------------*
FORM set_column_text USING po_columns TYPE REF TO cl_salv_columns_table
                           pv_name    TYPE lvc_fname
                           pv_short   TYPE scrtext_s
                           pv_medium  TYPE scrtext_m
                           pv_long    TYPE scrtext_l.
  DATA: lo_column TYPE REF TO cl_salv_column,
        lv_msg    TYPE string.

  TRY.
      lo_column = po_columns->get_column( pv_name ).
      lo_column->set_short_text( pv_short ).
      lo_column->set_medium_text( pv_medium ).
      lo_column->set_long_text( pv_long ).
    CATCH cx_salv_not_found INTO DATA(lx_not_found).
      lv_msg = lx_not_found->get_text( ).
      MESSAGE lv_msg TYPE 'E'.
  ENDTRY.
ENDFORM.
