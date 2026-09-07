*&---------------------------------------------------------------------*
*& Report/Include : ZSD_EXC_APPR_PAINTS
*& Title          : Exceptional Approval Report - Paints
*& Project        : KPMG / UDAY - Astral Limited        Module: SD
*& Related FS     : WRICEF 141.B - Exceptional approval format, Paints
*& Build spec     : BUILD_SPEC_141B.md section 6 (locked - wins over FS)
*& Author         : Arnav Johri                         Date: 02.09.2026
*& Transport      : <TR to be filled by Arnav>
*& Ships by       : PASTE (screen-free; see BUILD_SPEC_141B.md for the ZIP note)
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Lists the exceptional credit approvals maintained in the custom
*&   table ZSD_EXP_PAINTS for the selected customers, company code,
*&   sales organisation, division and customer groups. For every
*&   approval row the report shows the actual credit limit of the
*&   chosen credit segment, the actual collection posted inside that
*&   row's OWN approval-to-commitment window, the non-fulfilment
*&   amount, the default percentage and the two status ladders.
*&
*& SIBLING OBJECT
*&   ZSD_EXC_APPR_ADHESIVE (WRICEF 141.A) is the same report for the
*&   Adhesives division. It reads BP3100; this one reads ZSD_EXP_PAINTS
*&   and adds Actual Collection from ACDOCA plus Status-1 / Status-2.
*&   FORM naming, ALV construction and text symbol style are kept
*&   deliberately identical so the two can be maintained together.
*&
*& SE38 ATTRIBUTES - please check on creation
*&   "Fixed point arithmetic" must be ON. F_BUILD_OUTPUT divides packed
*&   amounts to derive DEF_PERC and needs it to avoid truncation.
*&
*& PREREQUISITE OBJECTS
*&   Table ZSD_EXP_PAINTS must already exist and be active (build sheet
*&   ZSD_EXP_PAINTS_DDIC.md, objects 1 to 3). This program will not
*&   syntax check before it does.
*&
*& RUNTIME SAFETY
*&   Every read that can legitimately come back empty (no customers, no
*&   approvals, no credit limit row, no collection posting) is guarded
*&   and degrades to a blank or zero field, or to a message plus LEAVE
*&   LIST-PROCESSING - never a short dump and never a silently wrong
*&   number. See the ASSUMPTION notes at each such point.
*&
*& TEXT ELEMENTS
*&   Every user visible string is a text symbol with a literal default,
*&   so the program runs correctly even before Goto -> Text Elements is
*&   maintained. The list ships as ZSD_EXC_APPR_PAINTS_TEXTS.md.
*&
*& CHANGE HISTORY
*&   02.09.2026  Arnav Johri  <TR>  Initial development
*&   07.09.2026  Arnav Johri  <TR>  Credit segment defaulted to 2000
*&                                  (confirmed by functional). Sales
*&                                  hierarchy read built as a background
*&                                  SUBMIT with the source name held in
*&                                  the GC_HIER_* constants.
*&---------------------------------------------------------------------*
REPORT zsd_exc_appr_paints.

*&---------------------------------------------------------------------*
*& Tables - only for the SELECT-OPTIONS reference fields
*&---------------------------------------------------------------------*
TABLES: knvv,
        zsd_exp_paints,
        acdoca.

*&---------------------------------------------------------------------*
*& Types
*&---------------------------------------------------------------------*
* Single key column helper, used for the KNB1 / KNVV pre-reads and for
* the deduplicated partner list that drives the KNA1 and UKMBP_CMS_SGM
* reads.
TYPES: BEGIN OF ty_kunnr,
         kunnr TYPE kna1-kunnr,
       END OF ty_kunnr.

TYPES ty_t_kunnr TYPE STANDARD TABLE OF ty_kunnr WITH DEFAULT KEY.

* Customer key list. F_GET_HIERARCHY writes L4/L5/L6 here after running
* the hierarchy report; they stay blank while its name is unconfirmed.
* This is also the driver table for the ACDOCA collection read - build
* spec 6.3 point 7 fixes FOR ALL ENTRIES IN @gt_cust.
TYPES: BEGIN OF ty_cust,
         kunnr   TYPE kna1-kunnr,
         l4_name TYPE char40,
         l5_name TYPE char40,
         l6_name TYPE char40,
       END OF ty_cust.

TYPES ty_t_cust TYPE STANDARD TABLE OF ty_cust WITH DEFAULT KEY.

* Approval rows read from ZSD_EXP_PAINTS, in the DDIC field order of
* the table build sheet. The component order below MUST stay identical
* to the SELECT field list in FORM f_get_approvals - strict Open SQL
* fills the target by POSITION, not by name.
* ZEX_AMNT is deliberately NOT read: no output column uses it (build
* spec deviation 9, open issue 8).
TYPES: BEGIN OF ty_appr,
         zsrn            TYPE zsd_exp_paints-zsrn,
         zcustomer       TYPE zsd_exp_paints-zcustomer,
         zexc_appr_month TYPE zsd_exp_paints-zexc_appr_month,
         zexc_appr_type  TYPE zsd_exp_paints-zexc_appr_type,
         zexc_date_from  TYPE zsd_exp_paints-zexc_date_from,
         zexc_date_to    TYPE zsd_exp_paints-zexc_date_to,
         zexc_amount     TYPE zsd_exp_paints-zexc_amount,
         zcommit_date    TYPE zsd_exp_paints-zcommit_date,
         zcm_amnt        TYPE zsd_exp_paints-zcm_amnt,
         zremarks        TYPE zsd_exp_paints-zremarks,
       END OF ty_appr.

TYPES: BEGIN OF ty_name,
         kunnr TYPE kna1-kunnr,
         name1 TYPE kna1-name1,
       END OF ty_name.

TYPES: BEGIN OF ty_climit,
         partner      TYPE ukmbp_cms_sgm-partner,
         credit_sgmnt TYPE ukmbp_cms_sgm-credit_sgmnt,
         credit_limit TYPE ukmbp_cms_sgm-credit_limit,
       END OF ty_climit.

* Collection document lines read once from ACDOCA for the whole
* customer set (build spec 6.3 point 7). The component order below MUST
* stay identical to the SELECT field list in FORM f_get_collections.
TYPES: BEGIN OF ty_coll,
         rbukrs TYPE acdoca-rbukrs,
         gjahr  TYPE acdoca-gjahr,
         belnr  TYPE acdoca-belnr,
         docln  TYPE acdoca-docln,
         budat  TYPE acdoca-budat,
         blart  TYPE acdoca-blart,
         kunnr  TYPE acdoca-kunnr,
         hsl    TYPE acdoca-hsl,
       END OF ty_coll.

* Output structure - declared in the exact order fixed by the build
* spec section 6.2. WAERS is last on purpose: it is the ALV currency
* reference for the amount columns, not a business column, and is
* marked NO_OUT in the field catalogue.
TYPES: BEGIN OF ty_output,
         kunnr        TYPE kna1-kunnr,
         name1        TYPE kna1-name1,
         l4_name      TYPE char40,
         l5_name      TYPE char40,
         l6_name      TYPE char40,
         exc_month    TYPE char7,
         exc_no       TYPE zsd_exp_paints-zsrn,
         exc_type     TYPE char30,
         date_from    TYPE zsd_exp_paints-zexc_date_from,
         date_to      TYPE zsd_exp_paints-zexc_date_to,
         exc_amnt     TYPE zsd_exp_paints-zexc_amount,
         cm_amnt      TYPE zsd_exp_paints-zcm_amnt,
         commit_date  TYPE zsd_exp_paints-zcommit_date,
         credit_limit TYPE ukmbp_cms_sgm-credit_limit,
         act_coll     TYPE acdoca-hsl,
         non_fulfil   TYPE acdoca-hsl,
         def_perc     TYPE p LENGTH 7 DECIMALS 2,
         status1      TYPE char25,
         status2      TYPE char15,
         remarks      TYPE zsd_exp_paints-zremarks,
         waers        TYPE t001-waers,
       END OF ty_output.

*&---------------------------------------------------------------------*
*& Global data
*&---------------------------------------------------------------------*
* GT_KNA1, GT_CLIMIT and GT_COLL are SORTED so that f_build_output and
* f_calc_collection do keyed reads instead of a linear scan per output
* row. NON-UNIQUE, because a data constellation must never dump on the
* SELECT ... INTO TABLE.
DATA: gt_cust    TYPE ty_t_cust,
      gt_partner TYPE ty_t_kunnr,
      gt_appr    TYPE STANDARD TABLE OF ty_appr,
      gt_kna1    TYPE SORTED TABLE OF ty_name
                      WITH NON-UNIQUE KEY kunnr,
      gt_climit  TYPE SORTED TABLE OF ty_climit
                      WITH NON-UNIQUE KEY partner,
      gt_coll    TYPE SORTED TABLE OF ty_coll
                      WITH NON-UNIQUE KEY kunnr,
      gt_output  TYPE STANDARD TABLE OF ty_output.

DATA: gv_waers TYPE t001-waers,
      gv_repid TYPE sy-repid.

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& Sales hierarchy source - NOT CONFIRMED BY FUNCTIONAL (open issue 1)
*&---------------------------------------------------------------------*
* ASSUMPTION: the FS says "Submit program SAPLSLVC_FULLSCREEN pass
* VKORG = 1000, 1100, 1200, 1300 fetch L4 Name". SAPLSLVC_FULLSCREEN is
* the generic ALV full-screen FUNCTION GROUP. It is not an executable
* report, it cannot be SUBMITted, and it holds no hierarchy data. The
* name is carried here EXACTLY as the FS gives it so that the reading
* logic below can be tested end to end, and so that correcting it is a
* change to this block alone. All six values are unconfirmed and must
* be replaced when functional names the real source:
*   GC_HIER_PROG     the executable report that lists the hierarchy
*   GC_HIER_SELNAME  its SELECT-OPTION name for sales organisation
*   GC_HIER_F_KUNNR  the customer field in its ALV output
*   GC_HIER_F_L4/5/6 the three level name fields in its ALV output
* Until they are replaced F_GET_HIERARCHY finds no executable report,
* issues ONE status message and leaves L4/L5/L6 blank. It never dumps
* and it never guesses a table.
CONSTANTS: gc_hier_prog    TYPE trdir-name       VALUE 'SAPLSLVC_FULLSCREEN',
           gc_hier_selname TYPE rsparams-selname VALUE 'S_VKORG',
           gc_hier_f_kunnr TYPE dfies-fieldname  VALUE 'KUNNR',
           gc_hier_f_l4    TYPE dfies-fieldname  VALUE 'L4_NAME',
           gc_hier_f_l5    TYPE dfies-fieldname  VALUE 'L5_NAME',
           gc_hier_f_l6    TYPE dfies-fieldname  VALUE 'L6_NAME',
           gc_subc_report  TYPE trdir-subc       VALUE '1'.
*EOC By Arnav on 07/09/26

*&---------------------------------------------------------------------*
*& Selection screen
*&---------------------------------------------------------------------*
* ASSUMPTION (FS deviation 2, build spec C3): the FS marks Info
* Category and Info Type as required selection fields. ZSD_EXP_PAINTS
* carries neither field, so neither can filter anything and both are
* deliberately absent here - see open issue 10. Two mandatory fields
* that filter nothing would tell the user the list is narrower than it
* really is. The two reversals - add ZINFOCAT / ZINFOTYPE to the table,
* or drop them from the FS - both belong to functional.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS s_kunnr FOR knvv-kunnr.
SELECT-OPTIONS s_date  FOR zsd_exp_paints-zexc_date_from OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS     p_bukrs TYPE knb1-bukrs OBLIGATORY.
SELECT-OPTIONS s_vkorg FOR knvv-vkorg OBLIGATORY.
SELECT-OPTIONS s_spart FOR knvv-spart OBLIGATORY.
SELECT-OPTIONS s_kvgr1 FOR knvv-kvgr1.
SELECT-OPTIONS s_kvgr2 FOR knvv-kvgr2.
*BOC By Arnav on 07/09/26
* FS deviation 13: the FS names no credit segment, but UKMBP_CMS_SGM is
* keyed by partner AND credit segment, so CREDIT_LIMIT is ambiguous
* without one. Functional confirmed segment 2000 on 07/09/26, closing
* open issue 16. It stays a SELECTION PARAMETER carrying 2000 as its
* default rather than a constant, so a second segment costs no code
* change and the tester can see and override what is being read.
* Kept identical to the Adhesives report on purpose.
* Old code:
** ASSUMPTION (FS deviation 13): the FS names no credit segment, but
** UKMBP_CMS_SGM is keyed by partner AND credit segment, so CREDIT_LIMIT
** is ambiguous without one. The segment is therefore asked for on the
** selection screen. No default is hardcoded - see open issue 16.
**PARAMETERS     p_segmnt TYPE ukmbp_cms_sgm-credit_sgmnt OBLIGATORY.
PARAMETERS     p_segmnt TYPE ukmbp_cms_sgm-credit_sgmnt OBLIGATORY
                        DEFAULT '2000'.
*EOC By Arnav on 07/09/26
SELECTION-SCREEN END OF BLOCK b2.

* ASSUMPTION (FS deviation 7): the FS names ledger '0L' and document
* type 'DZ' for the collection documents. Neither is hardcoded - both
* are selection screen fields carrying the FS value as their default,
* so a second ledger or a second collection document type needs no code
* change. Neither is existence checked: the ledger customizing table
* name is not confirmed on this landscape, and an unknown ledger simply
* returns no collection rows rather than a wrong figure.
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
PARAMETERS     p_rldnr TYPE acdoca-rldnr DEFAULT '0L' OBLIGATORY.
SELECT-OPTIONS s_blart FOR acdoca-blart DEFAULT 'DZ' OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b3.

*&---------------------------------------------------------------------*
*& Initialization
*&---------------------------------------------------------------------*
INITIALIZATION.

  gv_repid = sy-repid.

*&---------------------------------------------------------------------*
*& Selection screen validation
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON p_bukrs.

  DATA lv_chk_bukrs TYPE t001-bukrs.

  CLEAR lv_chk_bukrs.

  SELECT SINGLE bukrs
    FROM t001
    WHERE bukrs = @p_bukrs
    INTO @lv_chk_bukrs.

  IF sy-subrc <> 0.
    MESSAGE 'Company code does not exist'(m03) TYPE 'E'.
  ENDIF.

* P_SEGMNT, P_RLDNR and S_BLART are deliberately NOT existence checked -
* their customizing / check tables are not confirmed on this landscape.
* Same treatment as ZSD_EXC_APPR_ADHESIVE section 1.2.

*&---------------------------------------------------------------------*
*& Main flow
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  gv_repid = sy-repid.

  PERFORM f_get_customers.
  PERFORM f_get_approvals.
  PERFORM f_get_names.
  PERFORM f_get_credit_limits.
  PERFORM f_get_company_currency.
  PERFORM f_get_hierarchy CHANGING gt_cust.
  PERFORM f_get_collections.
  PERFORM f_build_output.

END-OF-SELECTION.

  PERFORM f_display_alv.

*&---------------------------------------------------------------------*
*& Form F_GET_CUSTOMERS
*&---------------------------------------------------------------------*
*& Company code customers from KNB1, restricted by the sales area,
*& division and customer group selections on KNVV. One row per
*& customer.
*&---------------------------------------------------------------------*
FORM f_get_customers.

  DATA: lt_knb1 TYPE ty_t_kunnr,
        lt_knvv TYPE ty_t_kunnr,
        ls_knvv TYPE ty_kunnr,
        ls_cust TYPE ty_cust.

  CLEAR: gt_cust, lt_knb1, lt_knvv, ls_knvv, ls_cust.

  SELECT kunnr
    FROM knb1
    WHERE bukrs = @p_bukrs
      AND kunnr IN @s_kunnr
    INTO TABLE @lt_knb1.

  IF lt_knb1 IS INITIAL.
    MESSAGE 'No customers match the selection'(m01)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  SELECT kunnr
    FROM knvv
    FOR ALL ENTRIES IN @lt_knb1
    WHERE kunnr = @lt_knb1-kunnr
      AND vkorg IN @s_vkorg
      AND spart IN @s_spart
      AND kvgr1 IN @s_kvgr1
      AND kvgr2 IN @s_kvgr2
    INTO TABLE @lt_knvv.

  IF lt_knvv IS INITIAL.
    MESSAGE 'No customers match the selection'(m01)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* KNVV is sales-area dependent, so a customer extended to several sales
* areas comes back more than once. It must appear exactly once in the
* report - see open issue 13.
  SORT lt_knvv BY kunnr.
  DELETE ADJACENT DUPLICATES FROM lt_knvv COMPARING kunnr.

  LOOP AT lt_knvv INTO ls_knvv.
    CLEAR ls_cust.
    ls_cust-kunnr = ls_knvv-kunnr.
    APPEND ls_cust TO gt_cust.
  ENDLOOP.

* GT_CUST inherits the order of LT_KNVV, but the BINARY SEARCH in
* f_build_output depends on that order, so it is stated here rather
* than assumed. GT_CUST also drives the ACDOCA read.
  SORT gt_cust BY kunnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_APPROVALS
*&---------------------------------------------------------------------*
*& Exceptional approval rows from ZSD_EXP_PAINTS for the selected
*& customers and the approval date-from range.
*&---------------------------------------------------------------------*
FORM f_get_approvals.

  DATA: ls_appr    TYPE ty_appr,
        ls_partner TYPE ty_kunnr.

  CLEAR: gt_appr, gt_partner, ls_appr, ls_partner.

  IF gt_cust IS INITIAL.
    MESSAGE 'No customers match the selection'(m01)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* The field list below matches TY_APPR component for component. Adding
* a field here without adding it at the same index of TY_APPR fills the
* wrong component.
* ASSUMPTION (FS deviation 8, build spec C4): the output mapping of the
* FS calls the exceptional amount ZEXC_AMNT while the table definition
* declares ZEXC_AMOUNT. The DDIC name ZEXC_AMOUNT is authoritative and
* is the only one used here - see open issue 8.
  SELECT zsrn, zcustomer, zexc_appr_month, zexc_appr_type,
         zexc_date_from, zexc_date_to, zexc_amount, zcommit_date,
         zcm_amnt, zremarks
    FROM zsd_exp_paints
    FOR ALL ENTRIES IN @gt_cust
    WHERE zcustomer      = @gt_cust-kunnr
      AND zexc_date_from IN @s_date
    INTO TABLE @gt_appr.

  IF gt_appr IS INITIAL.
    MESSAGE 'No exceptional approvals found for the selection'(m02)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* The database returns the rows in no guaranteed order, so the list is
* sorted here. Without it two runs of the same selection can produce
* the same rows in a different sequence, which makes the output hard to
* compare against the previous month's copy.
  SORT gt_appr BY zcustomer zsrn.

* One entry per customer that actually carries an approval. This list
* drives the KNA1 and UKMBP_CMS_SGM reads, so those two FOR ALL ENTRIES
* run over the smallest possible driver table.
  LOOP AT gt_appr INTO ls_appr.
    CLEAR ls_partner.
    ls_partner-kunnr = ls_appr-zcustomer.
    APPEND ls_partner TO gt_partner.
  ENDLOOP.

  SORT gt_partner BY kunnr.
  DELETE ADJACENT DUPLICATES FROM gt_partner COMPARING kunnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_NAMES
*&---------------------------------------------------------------------*
*& Customer names for the customers that actually carry an approval.
*&---------------------------------------------------------------------*
FORM f_get_names.

  CLEAR gt_kna1.

  IF gt_partner IS INITIAL.
    RETURN.
  ENDIF.

  SELECT kunnr, name1
    FROM kna1
    FOR ALL ENTRIES IN @gt_partner
    WHERE kunnr = @gt_partner-kunnr
    INTO TABLE @gt_kna1.

* A customer without a KNA1 row is not an error: f_build_output reads
* defensively and simply leaves the name blank.
  IF sy-subrc <> 0.
    CLEAR gt_kna1.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_CREDIT_LIMITS
*&---------------------------------------------------------------------*
*& Actual credit limit per customer for the credit segment entered on
*& the selection screen.
*&---------------------------------------------------------------------*
FORM f_get_credit_limits.

  CLEAR gt_climit.

  IF gt_partner IS INITIAL.
    RETURN.
  ENDIF.

  SELECT partner, credit_sgmnt, credit_limit
    FROM ukmbp_cms_sgm
    FOR ALL ENTRIES IN @gt_partner
    WHERE partner      = @gt_partner-kunnr
      AND credit_sgmnt = @p_segmnt
    INTO TABLE @gt_climit.

* A customer with no limit in this segment is not an error either -
* f_build_output leaves the limit at zero and guards the division.
  IF sy-subrc <> 0.
    CLEAR gt_climit.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_COMPANY_CURRENCY
*&---------------------------------------------------------------------*
*& Company code currency, used as the ALV currency reference for every
*& amount column.
*&---------------------------------------------------------------------*
FORM f_get_company_currency.

  CLEAR gv_waers.

  SELECT SINGLE waers
    FROM t001
    WHERE bukrs = @p_bukrs
    INTO @gv_waers.

* P_BUKRS is validated on the selection screen, so this is a defensive
* fallback only. The amounts are still shown, without a currency.
  IF sy-subrc <> 0.
    MESSAGE 'Company code currency could not be read'(m04)
            TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_HIERARCHY
*&---------------------------------------------------------------------*
*& Runs the sales hierarchy report in background and merges its L4/L5/L6
*& names into the customer list. Source names are the GC_HIER_* block.
*&---------------------------------------------------------------------*
FORM f_get_hierarchy CHANGING ct_cust TYPE ty_t_cust.

*BOC By Arnav on 07/09/26
* Functional confirmed on 07/09/26 that the hierarchy report is to be
* called in background and its output read, and that the program name
* in the FS is wrong and will be corrected. The call is therefore built
* in full here, with every unconfirmed name held in the CONSTANTS block
* GC_HIER_* above. Correcting the source is a change to that block.
*
* HOW IT WORKS
*   1. TRDIR is checked first. SAPLSLVC_FULLSCREEN is SUBC 'F' (function
*      group), not '1' (executable), so today the check fails, one status
*      message is issued and L4/L5/L6 stay blank. No dump.
*   2. Once GC_HIER_PROG names a real report, the sales organisations
*      from S_VKORG are passed to it in a RSPARAMS selection table under
*      the name GC_HIER_SELNAME.
*   3. CL_SALV_BS_RUNTIME_INFO suppresses the callee display and hands
*      back its ALV result table, which is read by field NAME through
*      ASSIGN COMPONENT - so the callee structure need not be known at
*      compile time.
*   4. The result is keyed on customer and merged into CT_CUST.
*
* ASSUMPTION: the callee is an ALV report. A classic WRITE list returns
* no ALV data and lands on message (m09) - blank columns, no dump.
* ASSUMPTION: the callee has no OBLIGATORY selection field other than
* the sales organisation. If it has, SUBMIT stops on its own selection
* screen and functional must tell us what else to pass.
* Kept identical to the Adhesives stub replacement on purpose, so that
* one confirmed source fills both reports in one change.

  DATA: lv_subc TYPE trdir-subc,
        lt_selt TYPE TABLE OF rsparams,
        ls_selt TYPE rsparams,
        lr_data TYPE REF TO data,
        lt_hier TYPE SORTED TABLE OF ty_cust
                     WITH NON-UNIQUE KEY kunnr,
        ls_hier TYPE ty_cust.

  FIELD-SYMBOLS: <lt_any>  TYPE ANY TABLE,
                 <ls_any>  TYPE any,
                 <lv_fld>  TYPE any,
                 <ls_cust> TYPE ty_cust.

* --- 1. the source must exist and be an executable report -------------
  SELECT SINGLE subc
    FROM trdir
    WHERE name = @gc_hier_prog
    INTO @lv_subc.

  IF sy-subrc <> 0.
    MESSAGE 'Sales hierarchy report not found - L4/L5/L6 left blank'(m07)
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF lv_subc <> gc_subc_report.
    MESSAGE 'Hierarchy source is not an executable report - see TS'(m08)
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

* --- 2. pass our own sales organisations to the callee -----------------
  LOOP AT s_vkorg INTO DATA(ls_vkorg).
    CLEAR ls_selt.
    ls_selt-selname = gc_hier_selname.
    ls_selt-kind    = 'S'.
    ls_selt-sign    = ls_vkorg-sign.
    ls_selt-option  = ls_vkorg-option.
    ls_selt-low     = ls_vkorg-low.
    ls_selt-high    = ls_vkorg-high.
    APPEND ls_selt TO lt_selt.
  ENDLOOP.

* --- 3. run it with the display suppressed and take its ALV data -------
* CLEAR_ALL is called on EVERY path below. If the capture were left
* armed, the report's OWN ALV in f_display_alv would be swallowed
* instead of shown.
  cl_salv_bs_runtime_info=>set( EXPORTING display  = abap_false
                                          metadata = abap_false
                                          data     = abap_true ).

  SUBMIT (gc_hier_prog) WITH SELECTION-TABLE lt_selt
                        AND RETURN.                     "#EC CI_SUBMIT

  TRY.
      cl_salv_bs_runtime_info=>get_data_ref( IMPORTING r_data = lr_data ).
    CATCH cx_salv_bs_sc_runtime_info.
      CLEAR lr_data.
  ENDTRY.

  cl_salv_bs_runtime_info=>clear_all( ).

  IF lr_data IS NOT BOUND.
    MESSAGE 'Hierarchy report returned no ALV data - L4/L5/L6 blank'(m09)
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  ASSIGN lr_data->* TO <lt_any>.
  IF <lt_any> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

* --- 4. map by field NAME, so the callee structure is not hardcoded ----
  LOOP AT <lt_any> ASSIGNING <ls_any>.

    CLEAR ls_hier.

    ASSIGN COMPONENT gc_hier_f_kunnr OF STRUCTURE <ls_any> TO <lv_fld>.
    IF sy-subrc = 0.
      ls_hier-kunnr = <lv_fld>.
    ENDIF.

    ASSIGN COMPONENT gc_hier_f_l4 OF STRUCTURE <ls_any> TO <lv_fld>.
    IF sy-subrc = 0.
      ls_hier-l4_name = <lv_fld>.
    ENDIF.

    ASSIGN COMPONENT gc_hier_f_l5 OF STRUCTURE <ls_any> TO <lv_fld>.
    IF sy-subrc = 0.
      ls_hier-l5_name = <lv_fld>.
    ENDIF.

    ASSIGN COMPONENT gc_hier_f_l6 OF STRUCTURE <ls_any> TO <lv_fld>.
    IF sy-subrc = 0.
      ls_hier-l6_name = <lv_fld>.
    ENDIF.

    CHECK ls_hier-kunnr IS NOT INITIAL.

*   The callee may return the customer without leading zeros. CT_CUST
*   holds the internal KNA1 format, so convert before the key match.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_hier-kunnr
      IMPORTING
        output = ls_hier-kunnr.

    INSERT ls_hier INTO TABLE lt_hier.

  ENDLOOP.

  IF lt_hier IS INITIAL.
    RETURN.
  ENDIF.

* --- 5. merge into the customer list ----------------------------------
  LOOP AT ct_cust ASSIGNING <ls_cust>.
    READ TABLE lt_hier INTO ls_hier
         WITH KEY kunnr = <ls_cust>-kunnr.
    IF sy-subrc = 0.
      <ls_cust>-l4_name = ls_hier-l4_name.
      <ls_cust>-l5_name = ls_hier-l5_name.
      <ls_cust>-l6_name = ls_hier-l6_name.
    ENDIF.
  ENDLOOP.
*EOC By Arnav on 07/09/26

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_COLLECTIONS
*&---------------------------------------------------------------------*
*& Reads the collection document lines ONCE for the whole customer set.
*& The read is bounded by the lowest approval date-from and the highest
*& commitment date across ALL approval rows, so the per-row windows
*& applied later in f_calc_collection are always a subset of what was
*& read. No SELECT inside a LOOP.
*&---------------------------------------------------------------------*
FORM f_get_collections.

  DATA: ls_appr     TYPE ty_appr,
        lv_min_date TYPE dats,
        lv_max_date TYPE dats.

  CLEAR: gt_coll, ls_appr, lv_min_date, lv_max_date.

  IF gt_cust IS INITIAL OR gt_appr IS INITIAL.
    RETURN.
  ENDIF.

* The outer window: lowest ZEXC_DATE_FROM to highest ZCOMMIT_DATE.
* A row whose date is initial is skipped here - it carries no usable
* window of its own and f_calc_collection returns zero for it.
  LOOP AT gt_appr INTO ls_appr.

    IF ls_appr-zexc_date_from IS NOT INITIAL.
      IF lv_min_date IS INITIAL
         OR ls_appr-zexc_date_from < lv_min_date.
        lv_min_date = ls_appr-zexc_date_from.
      ENDIF.
    ENDIF.

    IF ls_appr-zcommit_date IS NOT INITIAL.
      IF ls_appr-zcommit_date > lv_max_date.
        lv_max_date = ls_appr-zcommit_date.
      ENDIF.
    ENDIF.

  ENDLOOP.

* No usable outer window - no approval row has both ends of a window,
* so there is nothing to read and every Actual Collection stays zero.
  IF lv_min_date IS INITIAL OR lv_max_date IS INITIAL.
    RETURN.
  ENDIF.

* A window that starts after it ends selects nothing. Guard it rather
* than sending an impossible BETWEEN to the database.
  IF lv_min_date > lv_max_date.
    RETURN.
  ENDIF.

* ASSUMPTION (FS deviation 6): the FS filters ACDOCA by GJAHR. A
* collection window that crosses a fiscal year boundary would then
* silently lose its rows, so there is no GJAHR filter here - the read
* is bounded by BUDAT instead, which is what the window is expressed
* in. GJAHR is still selected because it is part of the document key.
* ASSUMPTION (FS deviation 3, build spec C1): BUDAT is bounded here by
* the WIDEST window across all approval rows so that the read happens
* once. The per-row window - that row's own ZEXC_DATE_FROM to its own
* ZCOMMIT_DATE - is applied afterwards, in memory, in
* f_calc_collection, and never here.
* NOTE: the field list below matches TY_COLL component for component.
* NOTE: KUNNR <> SPACE is redundant next to KUNNR = GT_CUST-KUNNR, but
* it is part of the locked WHERE clause in build spec 6.3 point 7 and
* is kept so the code and the contract read the same.
  SELECT rbukrs, gjahr, belnr, docln, budat, blart, kunnr, hsl
    FROM acdoca
    FOR ALL ENTRIES IN @gt_cust
    WHERE rldnr  = @p_rldnr
      AND rbukrs = @p_bukrs
      AND kunnr  = @gt_cust-kunnr
      AND budat  BETWEEN @lv_min_date AND @lv_max_date
      AND blart IN @s_blart
      AND kunnr <> @space
    INTO TABLE @gt_coll.

* No collection document in the whole window is a normal business
* result, not an error: every Actual Collection is then zero and the
* status ladders report the shortfall.
  IF sy-subrc <> 0.
    CLEAR gt_coll.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CALC_COLLECTION
*&---------------------------------------------------------------------*
*& Actual collection for ONE approval row. Pure in-memory arithmetic
*& over the lines read in f_get_collections - no database access.
*&---------------------------------------------------------------------*
FORM f_calc_collection  USING    iv_kunnr       TYPE kna1-kunnr
                                 iv_date_from   TYPE dats
                                 iv_commit_date TYPE dats
                        CHANGING cv_amount      TYPE acdoca-hsl.

  DATA: ls_coll TYPE ty_coll,
        lv_sum  TYPE acdoca-hsl.

  CLEAR: cv_amount, ls_coll, lv_sum.

* ASSUMPTION (FS deviation 3, build spec C1): the output mapping of the
* FS takes the posting date of the collection from the selection
* screen. Parth Shah's document comment says "Collection received
* during the approval date & Commitment date", which is what is applied
* here: the window is per row, ZEXC_DATE_FROM to ZCOMMIT_DATE
* inclusive. A single selection screen range would double count a
* collection across two overlapping approvals for the same customer -
* see open issue 5. Both dates are required; a row without a commitment
* date reports no collection rather than an unbounded one.
  IF iv_kunnr IS INITIAL
     OR iv_date_from IS INITIAL
     OR iv_commit_date IS INITIAL.
    RETURN.
  ENDIF.

* A window that starts after it ends (bad master data) can hold no
* posting at all - report zero without scanning for one.
  IF iv_date_from > iv_commit_date.
    RETURN.
  ENDIF.

* GT_COLL is a sorted table keyed on KUNNR, so the WHERE below is a
* keyed access and not a full scan per output row.
  LOOP AT gt_coll INTO ls_coll WHERE kunnr = iv_kunnr.

    IF ls_coll-budat < iv_date_from.
      CONTINUE.
    ENDIF.

    IF ls_coll-budat > iv_commit_date.
      CONTINUE.
    ENDIF.

    lv_sum = lv_sum + ls_coll-hsl.

  ENDLOOP.

* A customer collection is a credit posting and is held negative in
* ACDOCA. The FS reports it as a positive receipt, so the sign is
* removed here and nowhere else (build spec 6.3 point 8).
  cv_amount = abs( lv_sum ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CALC_STATUS
*&---------------------------------------------------------------------*
*& The two status ladders. Pure in-memory derivation, no database
*& access. Evaluated in the exact order fixed by build spec 6.3 point 9
*& - the order is part of the specification, not an implementation
*& detail, because the first two Status-1 conditions can both be true
*& at the same time.
*&---------------------------------------------------------------------*
FORM f_calc_status  USING    iv_cm_amnt     TYPE zsd_exp_paints-zcm_amnt
                             iv_act_coll    TYPE acdoca-hsl
                             iv_commit_date TYPE dats
                    CHANGING cv_status1     TYPE char25
                             cv_status2     TYPE char15.

  CLEAR: cv_status1, cv_status2.

* Without a commitment date there is no due date to judge against, so
* both statuses stay blank rather than showing a status derived from an
* initial date. The amount columns are still reported - see the note in
* f_build_output.
  IF iv_commit_date IS INITIAL.
    RETURN.
  ENDIF.

* Status-1, in the specified order.
  IF iv_cm_amnt - iv_act_coll <= 0.
    cv_status1 = 'Collection Received'(s01).
  ELSEIF iv_commit_date > sy-datum.
    cv_status1 = 'Commitment Not due'(s02).
  ELSE.
    cv_status1 = 'Commitment Overdue'(s03).
  ENDIF.

* ASSUMPTION (FS deviation 12): the FS defines Status-2 only for
* "collection greater than commitment" and "collection less than
* commitment". Exact equality is undefined and is treated here as
* Fulfilled, because the committed amount has been received in full -
* see open issue 12.
  IF iv_commit_date > sy-datum.
*   The commitment has not fallen due yet, so it is neither fulfilled
*   nor unfulfilled. Blank, not 'Not Fulfilled'.
    CLEAR cv_status2.
  ELSEIF iv_act_coll >= iv_cm_amnt.
    cv_status2 = 'Fulfilled'(s04).
  ELSE.
    cv_status2 = 'Not Fulfilled'(s05).
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_BUILD_OUTPUT
*&---------------------------------------------------------------------*
*& One output row per approval row.
*&---------------------------------------------------------------------*
FORM f_build_output.

  DATA: ls_appr   TYPE ty_appr,
        ls_out    TYPE ty_output,
        ls_cust   TYPE ty_cust,
        ls_name   TYPE ty_name,
        ls_climit TYPE ty_climit,
        lv_amount TYPE acdoca-hsl,
        lv_perc   TYPE p LENGTH 15 DECIMALS 2,
        lv_month  TYPE n LENGTH 2.

  CLEAR gt_output.

  LOOP AT gt_appr INTO ls_appr.

    CLEAR: ls_out, ls_cust, ls_name, ls_climit,
           lv_amount, lv_perc, lv_month.

    ls_out-kunnr = ls_appr-zcustomer.

    READ TABLE gt_kna1 INTO ls_name
         WITH KEY kunnr = ls_appr-zcustomer.
    IF sy-subrc = 0.
      ls_out-name1 = ls_name-name1.
    ENDIF.

*   L4/L5/L6 come from the customer table, filled by f_get_hierarchy.
*   They stay blank while GC_HIER_PROG names no executable report.
*   GT_CUST is sorted by KUNNR.
    READ TABLE gt_cust INTO ls_cust
         WITH KEY kunnr = ls_appr-zcustomer BINARY SEARCH.
    IF sy-subrc = 0.
      ls_out-l4_name = ls_cust-l4_name.
      ls_out-l5_name = ls_cust-l5_name.
      ls_out-l6_name = ls_cust-l6_name.
    ENDIF.

*   ZEXC_APPR_MONTH is stored NUMC 6 as YYYYMM so that it sorts and
*   compares correctly, and is DISPLAYED as MM-YYYY. On a 6 character
*   field the year is offset 0 length 4 and the month is offset 4
*   length 2 - the month is the TAIL, not the head.
*   A stored month outside 01-12 (bad master data written past the
*   upload report's validation) is shown blank rather than as a
*   misleading MM-YYYY string.
    IF ls_appr-zexc_appr_month IS NOT INITIAL.
      lv_month = ls_appr-zexc_appr_month+4(2).
      IF lv_month >= 1 AND lv_month <= 12.
        ls_out-exc_month = ls_appr-zexc_appr_month+4(2)
                        && '-' && ls_appr-zexc_appr_month(4).
      ENDIF.
    ENDIF.

    ls_out-exc_no = ls_appr-zsrn.

*   Approval type description from the fixed values of domain
*   ZSD_DO_EXC_TYPE, read from text symbols and never from DD07T
*   (build spec 6.3 point 10), so the report does not depend on the
*   domain texts being maintained or translated.
    CASE ls_appr-zexc_appr_type.
      WHEN '1'.
        ls_out-exc_type = 'Credit Limit'(t01).
      WHEN '2'.
        ls_out-exc_type = 'Overdue'(t02).
      WHEN '3'.
        ls_out-exc_type = 'Credit Limit & Overdue'(t03).
      WHEN OTHERS.
*       An unexpected code is shown as it stands rather than blanked,
*       so that bad master data is visible to the user instead of
*       looking like a row that simply has no type.
        ls_out-exc_type = ls_appr-zexc_appr_type.
    ENDCASE.

    ls_out-date_from   = ls_appr-zexc_date_from.
    ls_out-date_to     = ls_appr-zexc_date_to.
    ls_out-exc_amnt    = ls_appr-zexc_amount.
    ls_out-cm_amnt     = ls_appr-zcm_amnt.
    ls_out-commit_date = ls_appr-zcommit_date.
    ls_out-remarks     = ls_appr-zremarks.

    READ TABLE gt_climit INTO ls_climit
         WITH KEY partner = ls_appr-zcustomer.
    IF sy-subrc = 0.
      ls_out-credit_limit = ls_climit-credit_limit.
    ENDIF.

*   Actual Collection over THIS row's own window. LS_OUT-KUNNR carries
*   the same value as LS_APPR-ZCUSTOMER but with the KUNNR type, which
*   is what the FORM signature expects.
    PERFORM f_calc_collection USING    ls_out-kunnr
                                       ls_out-date_from
                                       ls_out-commit_date
                              CHANGING lv_amount.

    ls_out-act_coll = lv_amount.

* ASSUMPTION (FS deviation 4, build spec C2): the formula row of the FS
* says Non-Fulfilment = Collection Commitment minus Actual Collection,
* and the reviewer comment restates it. The sample row implies Actual
* minus Credit Limit, which is the Adhesives formula copy-pasted. The
* stated formula wins - see open issue 6.
    ls_out-non_fulfil = ls_out-cm_amnt - ls_out-act_coll.

* ASSUMPTION: unlike the Adhesives report, the amount columns are NOT
* cleared when the commitment date is initial. Build spec 6.3 point 9
* restricts the blank rule to the two statuses, so such a row shows
* Actual Collection zero and Non-Fulfilment equal to the full
* commitment, with both statuses blank to mark it as incomplete.
* Functional to confirm whether it should instead report blank amounts.
* Changing it means clearing ACT_COLL, NON_FULFIL and DEF_PERC in this
* one place.

* ASSUMPTION (FS deviation 5): the FS derives the default percentage
* from the ACTUAL CREDIT LIMIT even though the numerator is a
* collection shortfall. That looks like the wrong denominator, but it
* is what the FS states, so it is followed as written and guarded
* against a zero limit - see open issue 7.
    IF ls_out-credit_limit <> 0.
*     Computed in a wider packed field first. A limit that is a tiny
*     fraction of the shortfall could otherwise overflow DEF_PERC and
*     short dump instead of reporting.
      lv_perc = ( ls_out-non_fulfil * 100 ) / ls_out-credit_limit.
      IF lv_perc > 99999999999 OR lv_perc < -99999999999.
        CLEAR ls_out-def_perc.
      ELSE.
        ls_out-def_perc = lv_perc.
      ENDIF.
    ELSE.
*     Never divide by zero - the FS gives no rule for a zero limit.
      CLEAR ls_out-def_perc.
    ENDIF.

    PERFORM f_calc_status USING    ls_out-cm_amnt
                                   ls_out-act_coll
                                   ls_out-commit_date
                          CHANGING ls_out-status1
                                   ls_out-status2.

* ASSUMPTION: the amount columns are shown in the company code currency
* of P_BUKRS. ACDOCA-HSL is already in that currency. The credit limit
* of UKMBP_CMS_SGM is held in the credit segment currency and the
* ZSD_EXP_PAINTS amounts in their own WAERS; both are normally the same
* company code currency, but neither is converted here. If the table
* WAERS can differ from the company code currency, the conversion has
* to be agreed with functional before this report is signed off.
    ls_out-waers = gv_waers.

    APPEND ls_out TO gt_output.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_DISPLAY_ALV
*&---------------------------------------------------------------------*
*& Hand built LVC field catalogue and full screen grid display.
*&---------------------------------------------------------------------*
FORM f_display_alv.

  DATA: lt_fcat    TYPE lvc_t_fcat,
        ls_layout  TYPE lvc_s_layo,
        ls_variant TYPE disvariant.

  CLEAR: lt_fcat, ls_layout, ls_variant.

  IF gt_output IS INITIAL.
    MESSAGE 'No data to display for the selection'(m05)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* Column order follows TY_OUTPUT. The fourth argument is the currency
* reference field, the fifth the "do not display" flag.
  PERFORM f_add_fcat USING  1 'KUNNR'        'Customer Code'(c01)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  2 'NAME1'        'Customer Name'(c02)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  3 'L4_NAME'      'L4 Name'(c03)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  4 'L5_NAME'      'L5 Name'(c04)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  5 'L6_NAME'      'L6 Name'(c05)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  6 'EXC_MONTH'    'Approval Month'(c06)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  7 'EXC_NO'       'Serial Number'(c07)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  8 'EXC_TYPE'     'Approval Type'(c08)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  9 'DATE_FROM'    'Approval Date From'(c09)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 10 'DATE_TO'      'Approval Date To'(c10)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 11 'EXC_AMNT'     'Exceptional Amount'(c11)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 12 'CM_AMNT'      'Collection Commitment'(c12)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 13 'COMMIT_DATE'  'Commitment Date'(c13)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 14 'CREDIT_LIMIT' 'Actual Credit Limit'(c14)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 15 'ACT_COLL'     'Actual Collection'(c15)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 16 'NON_FULFIL'   'Non-Fulfilment Amount'(c16)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 17 'DEF_PERC'     'Default % Non-Fulfilment'(c17)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 18 'STATUS1'      'Status-1'(c18)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 19 'STATUS2'      'Status-2'(c19)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 20 'REMARKS'      'Remarks'(c20)
                              space   space   CHANGING lt_fcat.

* WAERS is the currency reference for the amount columns above and is
* not a business column, so it is not displayed.
  PERFORM f_add_fcat USING 21 'WAERS'        'Currency'(c21)
                              space   'X'    CHANGING lt_fcat.

  ls_layout-zebra      = abap_true.
  ls_layout-cwidth_opt = abap_true.

* IS_VARIANT must carry the report name for I_SAVE = 'A' to be able to
* store a layout.
  ls_variant-report = gv_repid.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program = gv_repid
      is_layout_lvc      = ls_layout
      it_fieldcat_lvc    = lt_fcat
      i_save             = 'A'
      is_variant         = ls_variant
    TABLES
      t_outtab           = gt_output
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE 'The report list could not be displayed'(m06)
            TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_ADD_FCAT
*&---------------------------------------------------------------------*
*& Builds one LVC_S_FCAT entry so that f_display_alv stays a readable
*& list of column definitions. The parameters are typed generically
*& (CLIKE) so that literals, text symbols and SPACE can all be passed.
*&---------------------------------------------------------------------*
FORM f_add_fcat  USING    iv_pos   TYPE i
                          iv_field TYPE clike
                          iv_text  TYPE clike
                          iv_curr  TYPE clike
                          iv_noout TYPE clike
                 CHANGING ct_fcat  TYPE lvc_t_fcat.

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR ls_fcat.

  ls_fcat-col_pos   = iv_pos.
  ls_fcat-fieldname = iv_field.
  ls_fcat-scrtext_l = iv_text.
  ls_fcat-scrtext_m = iv_text.
  ls_fcat-scrtext_s = iv_text.
  ls_fcat-reptext   = iv_text.

  IF iv_curr IS NOT INITIAL.
    ls_fcat-cfieldname = iv_curr.
  ENDIF.

  IF iv_noout = abap_true.
    ls_fcat-no_out = abap_true.
  ENDIF.

  APPEND ls_fcat TO ct_fcat.

ENDFORM.
