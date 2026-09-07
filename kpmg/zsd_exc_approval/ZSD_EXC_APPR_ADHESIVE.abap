*&---------------------------------------------------------------------*
*& Report/Include : ZSD_EXC_APPR_ADHESIVE
*& Title          : Exceptional Approval Report - Adhesives
*& Project        : KPMG / UDAY - Astral Limited        Module: SD
*& Related FS     : WRICEF 141.A - Exceptional approval format, Adhesives
*& Build spec     : BUILD_SPEC_141A.md (locked contract - wins over FS)
*& Author         : Arnav Johri                         Date: 02.09.2026
*& Transport      : <TR to be filled by Arnav>
*& Ships by       : PASTE (screen-free; see BUILD_SPEC_141A.md for the ZIP note)
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Lists the exceptional credit approvals maintained in the business
*&   partner credit management "Additional Information" (table BP3100)
*&   for the selected customers, information category and information
*&   type. For every approval row the report shows the actual credit
*&   limit of the chosen credit segment, the actual outstanding as on
*&   the commitment date, the non-fulfilment amount, the default
*&   percentage and the resulting status.
*&
*& SE38 ATTRIBUTES - please check on creation
*&   "Fixed point arithmetic" must be ON. F_BUILD_OUTPUT divides packed
*&   amounts to derive DEF_PERC and needs it to avoid truncation.
*&
*& TEXT ELEMENTS
*&   Every user visible string is a text symbol with a literal default,
*&   so the program runs correctly even before Goto -> Text Elements is
*&   maintained. The list ships as ZSD_EXC_APPR_ADHESIVE_TEXTS.md.
*&
*& CHANGE HISTORY
*&   02.09.2026  Arnav Johri  <TR>  Initial development
*&   07.09.2026  Arnav Johri  <TR>  Credit segment defaulted to 2000
*&                                  (confirmed by functional). Sales
*&                                  hierarchy read built as a background
*&                                  SUBMIT with the source name held in
*&                                  the GC_HIER_* constants.
*&---------------------------------------------------------------------*
REPORT zsd_exc_appr_adhesive.

*&---------------------------------------------------------------------*
*& Tables - only for the SELECT-OPTIONS reference fields
*&---------------------------------------------------------------------*
TABLES: knvv,
        bp3100.

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
TYPES: BEGIN OF ty_cust,
         kunnr   TYPE kna1-kunnr,
         l4_name TYPE char40,
         l5_name TYPE char40,
         l6_name TYPE char40,
       END OF ty_cust.

TYPES ty_t_cust TYPE STANDARD TABLE OF ty_cust WITH DEFAULT KEY.

* Approval rows read from BP3100. The component order below MUST stay
* identical to the SELECT field list in FORM f_get_approvals - strict
* Open SQL fills the target by POSITION, not by name.
TYPES: BEGIN OF ty_appr,
         partner TYPE bp3100-partner,
         counter TYPE bp3100-counter,
         datefr  TYPE bp3100-datefr,
         dateto  TYPE bp3100-dateto,
         amnt    TYPE bp3100-amnt,
         text    TYPE bp3100-text,
       END OF ty_appr.

* Parsed commitment date per approval row (BP3100-TEXT is free text).
TYPES: BEGIN OF ty_cdate,
         partner     TYPE bp3100-partner,
         counter     TYPE bp3100-counter,
         commit_date TYPE dats,
       END OF ty_cdate.

TYPES: BEGIN OF ty_name,
         kunnr TYPE kna1-kunnr,
         name1 TYPE kna1-name1,
       END OF ty_name.

TYPES: BEGIN OF ty_climit,
         partner      TYPE ukmbp_cms_sgm-partner,
         credit_sgmnt TYPE ukmbp_cms_sgm-credit_sgmnt,
         credit_limit TYPE ukmbp_cms_sgm-credit_limit,
       END OF ty_climit.

* Open item as it stands today (BSID).
TYPES: BEGIN OF ty_item,
         bukrs TYPE bsid-bukrs,
         kunnr TYPE bsid-kunnr,
         belnr TYPE bsid-belnr,
         buzei TYPE bsid-buzei,
         budat TYPE bsid-budat,
         wrbtr TYPE bsid-wrbtr,
         dmbtr TYPE bsid-dmbtr,
         shkzg TYPE bsid-shkzg,
         rebzg TYPE bsid-rebzg,
       END OF ty_item.

* Item already cleared (BSAD) - same list plus the clearing date.
TYPES: BEGIN OF ty_clritem,
         bukrs TYPE bsad-bukrs,
         kunnr TYPE bsad-kunnr,
         belnr TYPE bsad-belnr,
         buzei TYPE bsad-buzei,
         budat TYPE bsad-budat,
         wrbtr TYPE bsad-wrbtr,
         dmbtr TYPE bsad-dmbtr,
         shkzg TYPE bsad-shkzg,
         rebzg TYPE bsad-rebzg,
         augdt TYPE bsad-augdt,
       END OF ty_clritem.

* F4 helper tables.
TYPES: BEGIN OF ty_f4_infcat,
         infocategory TYPE ukm_infocat-infocategory,
       END OF ty_f4_infcat.

TYPES: BEGIN OF ty_f4_infotyp,
         infotype TYPE ukm_infotyp-infotype,
       END OF ty_f4_infotyp.

* Output structure - declared in the exact order fixed by the build
* spec section 2. WAERS is last on purpose: it is the ALV currency
* reference for the amount columns, not a business column, and is
* marked NO_OUT in the field catalogue.
TYPES: BEGIN OF ty_output,
         kunnr        TYPE kna1-kunnr,
         name1        TYPE kna1-name1,
         l4_name      TYPE char40,
         l5_name      TYPE char40,
         l6_name      TYPE char40,
         exc_month    TYPE char7,
         exc_no       TYPE bp3100-counter,
         exc_type     TYPE char30,
         date_from    TYPE bp3100-datefr,
         date_to      TYPE bp3100-dateto,
         exc_amnt     TYPE bp3100-amnt,
         commit_date  TYPE dats,
         commit_text  TYPE bp3100-text,
         credit_limit TYPE ukmbp_cms_sgm-credit_limit,
         act_os       TYPE dmbtr,
         non_fulfil   TYPE dmbtr,
         def_perc     TYPE p LENGTH 7 DECIMALS 2,
         status       TYPE char15,
         waers        TYPE t001-waers,
       END OF ty_output.

*&---------------------------------------------------------------------*
*& Global data
*&---------------------------------------------------------------------*
* GT_BSID and GT_BSAD are SORTED on KUNNR so that f_calc_open_amount is
* a keyed access per output row and not a linear scan of the whole item
* set. NON-UNIQUE, because a data constellation must never dump on the
* SELECT ... INTO TABLE.
DATA: gt_cust    TYPE ty_t_cust,
      gt_partner TYPE ty_t_kunnr,
      gt_appr    TYPE STANDARD TABLE OF ty_appr,
      gt_cdate   TYPE SORTED TABLE OF ty_cdate
                      WITH NON-UNIQUE KEY partner counter,
      gt_kna1    TYPE SORTED TABLE OF ty_name
                      WITH NON-UNIQUE KEY kunnr,
      gt_climit  TYPE SORTED TABLE OF ty_climit
                      WITH NON-UNIQUE KEY partner,
      gt_bsid    TYPE SORTED TABLE OF ty_item
                      WITH NON-UNIQUE KEY kunnr,
      gt_bsad    TYPE SORTED TABLE OF ty_clritem
                      WITH NON-UNIQUE KEY kunnr,
      gt_output  TYPE STANDARD TABLE OF ty_output.

DATA: gv_waers TYPE t001-waers,
      gv_repid TYPE sy-repid.

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& Sales hierarchy source - PROGRAM CONFIRMED, FIELD NAMES ARE NOT
*&---------------------------------------------------------------------*
* The FS says "Submit program SAPLSLVC_FULLSCREEN pass VKORG = 1000,
* 1100, 1200, 1300 fetch L4 Name". That name is wrong - it is the
* generic ALV full-screen FUNCTION GROUP, not an executable report.
* Arnav gave the real source on 07/09/26: ZSD_CUSTOMER_DATA.
*
* GC_HIER_PROG is therefore CONFIRMED. The other four are still
* PLACEHOLDERS - nobody has confirmed what ZSD_CUSTOMER_DATA calls its
* sales-organisation select-option or its ALV output fields, and this
* program deliberately does not guess:
*   GC_HIER_SELNAME  its SELECT-OPTION name for sales organisation
*   GC_HIER_F_KUNNR  the customer field in its ALV output
*   GC_HIER_F_L4/5/6 the three level name fields in its ALV output
*
* What a wrong placeholder costs, none of it a dump:
*   GC_HIER_SELNAME wrong - SUBMIT ignores the unknown SELNAME, so the
*     callee runs unfiltered. Slower, but the merge is on customer key
*     so the reported names are still right.
*   GC_HIER_F_KUNNR wrong - nothing maps. F_GET_HIERARCHY says so with
*     one status message rather than silently showing blank columns.
*   GC_HIER_F_L4/5/6 wrong - that level comes back blank.
*
* To confirm them: run ZSD_CUSTOMER_DATA, then on its ALV use
* Settings -> Layout -> Current for the technical field names, and F1
* on its sales organisation field for the select-option name.
CONSTANTS: gc_hier_prog    TYPE trdir-name       VALUE 'ZSD_CUSTOMER_DATA',
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
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS s_kunnr FOR knvv-kunnr.
PARAMETERS     p_infcat TYPE ukm_infocat-infocategory OBLIGATORY.
PARAMETERS     p_inftyp TYPE ukm_infotyp-infotype OBLIGATORY.
SELECT-OPTIONS s_date FOR bp3100-datefr OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS     p_bukrs TYPE knb1-bukrs OBLIGATORY.
SELECT-OPTIONS s_vkorg FOR knvv-vkorg OBLIGATORY.
SELECT-OPTIONS s_kvgr1 FOR knvv-kvgr1.
SELECT-OPTIONS s_kvgr2 FOR knvv-kvgr2.
*BOC By Arnav on 07/09/26
* FS deviation 7: the FS names no credit segment, but UKMBP_CMS_SGM is
* keyed by partner AND credit segment, so CREDIT_LIMIT is ambiguous
* without one. Functional confirmed segment 2000 on 07/09/26, closing
* open issue 16. It stays a SELECTION PARAMETER carrying 2000 as its
* default rather than a constant, so a second segment costs no code
* change and the tester can see and override what is being read.
* Old code:
** ASSUMPTION (FS deviation 7): the FS names no credit segment, but
** UKMBP_CMS_SGM is keyed by partner AND credit segment, so CREDIT_LIMIT
** is ambiguous without one. The segment is therefore asked for on the
** selection screen. No default is hardcoded - see open issue 16.
**PARAMETERS     p_segmnt TYPE ukmbp_cms_sgm-credit_sgmnt OBLIGATORY.
PARAMETERS     p_segmnt TYPE ukmbp_cms_sgm-credit_sgmnt OBLIGATORY
                        DEFAULT '2000'.
*EOC By Arnav on 07/09/26
SELECTION-SCREEN END OF BLOCK b2.

*&---------------------------------------------------------------------*
*& Initialization
*&---------------------------------------------------------------------*
INITIALIZATION.

  gv_repid = sy-repid.

*&---------------------------------------------------------------------*
*& F4 help - information category
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infcat.

  DATA: lt_f4cat  TYPE STANDARD TABLE OF ty_f4_infcat,
        lt_retcat TYPE STANDARD TABLE OF ddshretval,
        ls_retcat TYPE ddshretval.

  CLEAR: lt_f4cat, lt_retcat, ls_retcat.

* No text table is read here - its name is not confirmed on this
* landscape, so only the key values are offered (build spec 1.1).
  SELECT DISTINCT infocategory
    FROM ukm_infocat
    ORDER BY infocategory
    INTO TABLE @lt_f4cat.

  IF lt_f4cat IS INITIAL.
    MESSAGE 'No information categories are maintained'(m08)
            TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'INFOCATEGORY'
        dynpprog        = gv_repid
        dynpnr          = sy-dynnr
        dynprofield     = 'P_INFCAT'
        value_org       = 'S'
      TABLES
        value_tab       = lt_f4cat
        return_tab      = lt_retcat
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.

    IF sy-subrc <> 0.
      MESSAGE 'Value help could not be displayed'(m09)
              TYPE 'S' DISPLAY LIKE 'W'.
    ELSE.
      READ TABLE lt_retcat INTO ls_retcat INDEX 1.
      IF sy-subrc = 0.
        p_infcat = ls_retcat-fieldval.
      ENDIF.
    ENDIF.
  ENDIF.

*&---------------------------------------------------------------------*
*& F4 help - information type, dependent on the information category
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_inftyp.

  DATA: lt_f4typ  TYPE STANDARD TABLE OF ty_f4_infotyp,
        lt_rettyp TYPE STANDARD TABLE OF ddshretval,
        ls_rettyp TYPE ddshretval,
        lt_dynp   TYPE STANDARD TABLE OF dynpread,
        ls_dynp   TYPE dynpread,
        lv_infcat TYPE ukm_infocat-infocategory.

  CLEAR: lt_f4typ, lt_rettyp, ls_rettyp, lt_dynp, ls_dynp, lv_infcat.

* Read the category straight off the screen so the F4 reflects what the
* user has typed but not yet confirmed with ENTER (build spec 1.1).
  ls_dynp-fieldname = 'P_INFCAT'.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname             = gv_repid
      dynumb             = sy-dynnr
      translate_to_upper = abap_true
    TABLES
      dynpfields         = lt_dynp
    EXCEPTIONS
      OTHERS             = 1.

  IF sy-subrc = 0.
    READ TABLE lt_dynp INTO ls_dynp WITH KEY fieldname = 'P_INFCAT'.
    IF sy-subrc = 0.
      lv_infcat = ls_dynp-fieldvalue.
    ENDIF.
  ENDIF.

* Fall back to the ABAP field if the screen could not be read.
  IF lv_infcat IS INITIAL.
    lv_infcat = p_infcat.
  ENDIF.

  IF lv_infcat IS INITIAL.
    MESSAGE 'Enter the information category first'(m03)
            TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    SELECT DISTINCT infotype
      FROM ukm_infotyp
      WHERE infocategory = @lv_infcat
      ORDER BY infotype
      INTO TABLE @lt_f4typ.

    IF lt_f4typ IS INITIAL.
      MESSAGE 'No information types for this category'(m10)
              TYPE 'S' DISPLAY LIKE 'W'.
    ELSE.
      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield        = 'INFOTYPE'
          dynpprog        = gv_repid
          dynpnr          = sy-dynnr
          dynprofield     = 'P_INFTYP'
          value_org       = 'S'
        TABLES
          value_tab       = lt_f4typ
          return_tab      = lt_rettyp
        EXCEPTIONS
          parameter_error = 1
          no_values_found = 2
          OTHERS          = 3.

      IF sy-subrc <> 0.
        MESSAGE 'Value help could not be displayed'(m09)
                TYPE 'S' DISPLAY LIKE 'W'.
      ELSE.
        READ TABLE lt_rettyp INTO ls_rettyp INDEX 1.
        IF sy-subrc = 0.
          p_inftyp = ls_rettyp-fieldval.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

*&---------------------------------------------------------------------*
*& Selection screen validation (build spec 1.2)
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON p_bukrs.

  DATA lv_chk_bukrs TYPE t001-bukrs.

  CLEAR lv_chk_bukrs.

  SELECT SINGLE bukrs
    FROM t001
    WHERE bukrs = @p_bukrs
    INTO @lv_chk_bukrs.

  IF sy-subrc <> 0.
    MESSAGE 'Company code does not exist'(m04) TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON p_infcat.

  DATA lv_chk_cat TYPE ukm_infocat-infocategory.

  CLEAR lv_chk_cat.

  SELECT SINGLE infocategory
    FROM ukm_infocat
    WHERE infocategory = @p_infcat
    INTO @lv_chk_cat.

  IF sy-subrc <> 0.
    MESSAGE 'Information category does not exist'(m05) TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON p_inftyp.

  DATA lv_chk_typ TYPE ukm_infotyp-infotype.

  CLEAR lv_chk_typ.

* Only checked once the category itself is filled - otherwise the user
* would get two errors for one mistake.
  IF p_infcat IS NOT INITIAL.
    SELECT SINGLE infotype
      FROM ukm_infotyp
      WHERE infocategory = @p_infcat
        AND infotype     = @p_inftyp
      INTO @lv_chk_typ.

    IF sy-subrc <> 0.
      MESSAGE 'Information type not valid for this category'(m06)
              TYPE 'E'.
    ENDIF.
  ENDIF.

* p_segmnt is deliberately NOT existence checked - the customizing
* table that holds the credit segments is not confirmed on this
* landscape (build spec 1.2).

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
  PERFORM f_get_open_items.
  PERFORM f_build_output.

END-OF-SELECTION.

  PERFORM f_display_alv.

*&---------------------------------------------------------------------*
*& Form F_GET_CUSTOMERS
*&---------------------------------------------------------------------*
*& Company code customers from KNB1, restricted by the sales area and
*& customer group selections on KNVV. One row per customer.
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

* GT_CUST stays sorted by KUNNR, so the reads in f_build_output can use
* BINARY SEARCH.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_APPROVALS
*&---------------------------------------------------------------------*
*& Exceptional approval rows from BP3100 for the selected customers,
*& information category, information type and approval date range.
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
  SELECT partner, counter, datefr, dateto, amnt, text
    FROM bp3100
    FOR ALL ENTRIES IN @gt_cust
    WHERE partner      = @gt_cust-kunnr
      AND infocategory = @p_infcat
      AND infotype     = @p_inftyp
      AND datefr      IN @s_date
    INTO TABLE @gt_appr.

  IF gt_appr IS INITIAL.
    MESSAGE 'No exceptional approvals found for the selection'(m02)
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

* One entry per partner that actually carries an approval. This list
* drives the KNA1 and UKMBP_CMS_SGM reads, so those two FOR ALL ENTRIES
* run over the smallest possible driver table.
  LOOP AT gt_appr INTO ls_appr.
    CLEAR ls_partner.
    ls_partner-kunnr = ls_appr-partner.
    APPEND ls_partner TO gt_partner.
  ENDLOOP.

  SORT gt_partner BY kunnr.
  DELETE ADJACENT DUPLICATES FROM gt_partner COMPARING kunnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_NAMES
*&---------------------------------------------------------------------*
*& Customer names for the partners that actually carry an approval.
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

* A partner without a KNA1 row is not an error: f_build_output reads
* defensively and simply leaves the name blank.
  IF sy-subrc <> 0.
    CLEAR gt_kna1.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_CREDIT_LIMITS
*&---------------------------------------------------------------------*
*& Actual credit limit per partner for the credit segment entered on
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

* A partner with no limit in this segment is not an error either -
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
    MESSAGE 'Company code currency could not be read'(m11)
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
* printed in the FS is wrong. Arnav gave the real source the same day:
* ZSD_CUSTOMER_DATA. The call is built in full here, with every source
* name - the confirmed program and the four placeholders alike - held
* in the CONSTANTS block GC_HIER_* above. Correcting any of them is a
* change to that block alone.
*
* HOW IT WORKS
*   1. TRDIR is checked first. Unless GC_HIER_PROG exists AND is SUBC
*      '1' (executable), one status message is issued and L4/L5/L6 stay
*      blank. No SUBMIT is attempted and nothing dumps.
*   2. The sales organisations from S_VKORG are passed to the callee in
*      a RSPARAMS selection table under the name GC_HIER_SELNAME. An
*      unknown SELNAME is ignored by SUBMIT, it does not dump.
*   3. CL_SALV_BS_RUNTIME_INFO suppresses the callee display and hands
*      back its ALV result table, which is read by field NAME through
*      ASSIGN COMPONENT - so the callee structure need not be known at
*      compile time.
*   4. The result is keyed on customer and merged into CT_CUST.
*
* ASSUMPTION: ZSD_CUSTOMER_DATA is an ALV report. A classic WRITE list
* returns no ALV data and lands on message (m15) - blank columns, no dump.
* ASSUMPTION: ZSD_CUSTOMER_DATA has no OBLIGATORY selection field other
* than the sales organisation. If it has, SUBMIT stops on its own
* selection screen and functional must tell us what else to pass. This
* is the one case that needs watching in functional testing, because the
* program name is now real and the SUBMIT genuinely runs.

  DATA: lv_subc TYPE trdir-subc,
        lt_selt TYPE TABLE OF rsparams,
        ls_selt TYPE rsparams,
        lr_data TYPE REF TO data,
        lt_hier TYPE SORTED TABLE OF ty_cust
                     WITH NON-UNIQUE KEY kunnr,
        ls_hier TYPE ty_cust,
        lv_mapped TYPE abap_bool.

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
    MESSAGE 'Sales hierarchy report not found - L4/L5/L6 left blank'(m13)
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF lv_subc <> gc_subc_report.
    MESSAGE 'Hierarchy source is not an executable report - see TS'(m14)
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
    MESSAGE 'Hierarchy report returned no ALV data - L4/L5/L6 blank'(m15)
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
      lv_mapped     = abap_true.
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

* GC_HIER_F_KUNNR did not match any component of the callee output, so
* nothing could be keyed. Say so - a silent blank column would look like
* missing master data rather than a wrong field name.
  IF lv_mapped <> abap_true.
    MESSAGE 'Hierarchy field names do not match the report output'(m16)
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

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
*& Form F_PARSE_COMMIT_DATE
*&---------------------------------------------------------------------*
*& Defensive parse of the free-text commitment date held in BP3100-TEXT.
*& Returns an initial date when nothing usable is found - never dumps
*& and never messages per row.
*&---------------------------------------------------------------------*
FORM f_parse_commit_date  USING    iv_text TYPE bp3100-text
                          CHANGING cv_date TYPE dats.

* ASSUMPTION (FS deviation 6): the FS maps the commitment date to
* BP3100-TEXT, which is free text with no agreed entry format. This
* routine accepts DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY and an 8 digit
* YYYYMMDD token anywhere inside the text, validates day and month
* against the calendar and returns initial on anything else - see open
* issue 3. No regular expression is used: the token scan below is the
* same logic without the escaping risk.

  DATA: lv_string TYPE string,
        lt_token  TYPE STANDARD TABLE OF string,
        lv_token  TYPE string,
        lt_part   TYPE STANDARD TABLE OF string,
        lv_clean  TYPE string,
        lv_tmp    TYPE string,
        lv_p1     TYPE string,
        lv_p2     TYPE string,
        lv_p3     TYPE string,
        lv_char   TYPE c LENGTH 1,
        lv_len    TYPE i,
        lv_pos    TYPE i,
        lv_day    TYPE i,
        lv_mon    TYPE i,
        lv_year   TYPE i,
        lv_ok     TYPE abap_bool,
        lv_nday   TYPE n LENGTH 2,
        lv_nmon   TYPE n LENGTH 2,
        lv_nyear  TYPE n LENGTH 4,
        lv_cand   TYPE c LENGTH 8.

  CLEAR cv_date.

  lv_string = iv_text.
  IF lv_string IS INITIAL.
    RETURN.
  ENDIF.

* Normalise the two alternative separators onto '.' so that only one
* separated form has to be handled below.
  REPLACE ALL OCCURRENCES OF '/' IN lv_string WITH '.'.
  REPLACE ALL OCCURRENCES OF '-' IN lv_string WITH '.'.

  SPLIT lv_string AT space INTO TABLE lt_token.

  LOOP AT lt_token INTO lv_token.

*   Strip everything that is not a digit or a separator, and never let
*   the cleaned token start with a separator. Surrounding words are
*   therefore ignored even when they are glued to the date.
    CLEAR lv_clean.
    lv_len = strlen( lv_token ).
    lv_pos = 0.
    WHILE lv_pos < lv_len.
      lv_char = lv_token+lv_pos(1).
      IF lv_char CA '0123456789'.
        CONCATENATE lv_clean lv_char INTO lv_clean.
      ELSEIF lv_char = '.' AND lv_clean IS NOT INITIAL.
        CONCATENATE lv_clean lv_char INTO lv_clean.
      ENDIF.
      lv_pos = lv_pos + 1.
    ENDWHILE.

    IF lv_clean IS INITIAL.
      CONTINUE.
    ENDIF.

*   Drop a single trailing separator left behind by punctuation.
    lv_len = strlen( lv_clean ).
    lv_pos = lv_len - 1.
    IF lv_clean+lv_pos(1) = '.'.
      lv_tmp   = lv_clean(lv_pos).
      lv_clean = lv_tmp.
    ENDIF.

    IF lv_clean IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR: lv_day, lv_mon, lv_year, lv_p1, lv_p2, lv_p3, lv_ok.

    IF lv_clean CS '.'.

*     Separated form - DD.MM.YYYY after normalisation.
      CLEAR lt_part.
      SPLIT lv_clean AT '.' INTO TABLE lt_part.
      IF lines( lt_part ) <> 3.
        CONTINUE.
      ENDIF.

      READ TABLE lt_part INTO lv_p1 INDEX 1.
      READ TABLE lt_part INTO lv_p2 INDEX 2.
      READ TABLE lt_part INTO lv_p3 INDEX 3.

      IF lv_p1 IS INITIAL OR lv_p2 IS INITIAL OR lv_p3 IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_p1 CN '0123456789' OR lv_p2 CN '0123456789'
                               OR lv_p3 CN '0123456789'.
        CONTINUE.
      ENDIF.
      IF strlen( lv_p1 ) > 2 OR strlen( lv_p2 ) > 2
                             OR strlen( lv_p3 ) <> 4.
        CONTINUE.
      ENDIF.

      lv_day  = lv_p1.
      lv_mon  = lv_p2.
      lv_year = lv_p3.

    ELSE.

*     Plain 8 digit form - YYYYMMDD.
      IF strlen( lv_clean ) <> 8.
        CONTINUE.
      ENDIF.
      IF lv_clean CN '0123456789'.
        CONTINUE.
      ENDIF.

      lv_year = lv_clean(4).
      lv_mon  = lv_clean+4(2).
      lv_day  = lv_clean+6(2).

    ENDIF.

    PERFORM f_check_date USING    lv_year
                                  lv_mon
                                  lv_day
                         CHANGING lv_ok.

    IF lv_ok <> abap_true.
      CONTINUE.
    ENDIF.

    lv_nyear = lv_year.
    lv_nmon  = lv_mon.
    lv_nday  = lv_day.
    CONCATENATE lv_nyear lv_nmon lv_nday INTO lv_cand.

    cv_date = lv_cand.

*   Belt and braces - 00000000 is never accepted as a date.
    IF cv_date IS INITIAL.
      CONTINUE.
    ENDIF.

*   First token that parses wins.
    EXIT.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CHECK_DATE
*&---------------------------------------------------------------------*
*& Calendar validation of a year / month / day triple. Leap year aware.
*& Helper for f_parse_commit_date only.
*&---------------------------------------------------------------------*
FORM f_check_date  USING    iv_year  TYPE i
                            iv_month TYPE i
                            iv_day   TYPE i
                   CHANGING cv_ok    TYPE abap_bool.

  DATA lv_maxday TYPE i.

  CLEAR cv_ok.

* A four digit year outside this window is text that happens to look
* like a date, not a commitment date.
  IF iv_year < 1900 OR iv_year > 9999.
    RETURN.
  ENDIF.

  IF iv_month < 1 OR iv_month > 12.
    RETURN.
  ENDIF.

  IF iv_day < 1.
    RETURN.
  ENDIF.

  lv_maxday = 31.
  CASE iv_month.
    WHEN 4 OR 6 OR 9 OR 11.
      lv_maxday = 30.
    WHEN 2.
      IF ( iv_year MOD 4 = 0 AND iv_year MOD 100 <> 0 )
         OR iv_year MOD 400 = 0.
        lv_maxday = 29.
      ELSE.
        lv_maxday = 28.
      ENDIF.
    WHEN OTHERS.
      lv_maxday = 31.
  ENDCASE.

  IF iv_day > lv_maxday.
    RETURN.
  ENDIF.

  cv_ok = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_OPEN_ITEMS
*&---------------------------------------------------------------------*
*& Parses every commitment date once, then reads the customer line items
*& ONCE for the whole customer set. The reads are bounded by the lowest
*& and the highest parsed commitment date. No SELECT inside a LOOP.
*&---------------------------------------------------------------------*
FORM f_get_open_items.

  DATA: ls_appr     TYPE ty_appr,
        ls_cdate    TYPE ty_cdate,
        lv_min_date TYPE dats,
        lv_max_date TYPE dats.

  CLEAR: gt_cdate, gt_bsid, gt_bsad, lv_min_date, lv_max_date.

* Parse first: f_build_output reads the parsed dates from GT_CDATE and
* must never parse the same text twice.
  LOOP AT gt_appr INTO ls_appr.
    CLEAR ls_cdate.
    ls_cdate-partner = ls_appr-partner.
    ls_cdate-counter = ls_appr-counter.
    PERFORM f_parse_commit_date USING    ls_appr-text
                                CHANGING ls_cdate-commit_date.
    INSERT ls_cdate INTO TABLE gt_cdate.
  ENDLOOP.

  IF gt_cust IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT gt_cdate INTO ls_cdate.
    IF ls_cdate-commit_date IS INITIAL.
      CONTINUE.
    ENDIF.
    IF lv_min_date IS INITIAL OR ls_cdate-commit_date < lv_min_date.
      lv_min_date = ls_cdate-commit_date.
    ENDIF.
    IF ls_cdate-commit_date > lv_max_date.
      lv_max_date = ls_cdate-commit_date.
    ENDIF.
  ENDLOOP.

* Nothing parsed - there is no as-on date to report against, so the
* whole open item read is skipped.
  IF lv_min_date IS INITIAL OR lv_max_date IS INITIAL.
    RETURN.
  ENDIF.

* ASSUMPTION (FS deviation 2): the FS reads BSID by GJAHR only. BSID
* holds the items that are open NOW, so an item that was open on the
* commitment date but has been cleared since would be lost, and a
* GJAHR filter would drop items that span fiscal years. The read is
* therefore BSID plus BSAD, bounded by BUDAT and AUGDT and not by
* GJAHR - see open issue 4.
* ASSUMPTION (FS deviation 4): the FS splits the read into REBZG blank
* and REBZG not blank. Together those two steps are simply "all items",
* so REBZG is selected but not filtered on - the sum is identical.
* ASSUMPTION (FS deviation 3): WRBTR is selected for reference but the
* arithmetic uses DMBTR. WRBTR is document currency while the credit
* limit is not, so only the company code currency amount is comparable.
* Switching back is a one line change in f_calc_open_amount.
* NOTE: FOR ALL ENTRIES suppresses duplicate result rows. BUDAT is in
* the field list, so two documents that share BELNR / BUZEI across
* fiscal years are still returned separately.
  SELECT bukrs, kunnr, belnr, buzei, budat, wrbtr, dmbtr, shkzg, rebzg
    FROM bsid
    FOR ALL ENTRIES IN @gt_cust
    WHERE bukrs = @p_bukrs
      AND kunnr = @gt_cust-kunnr
      AND budat <= @lv_max_date
    INTO TABLE @gt_bsid.

  IF sy-subrc <> 0.
    CLEAR gt_bsid.
  ENDIF.

  SELECT bukrs, kunnr, belnr, buzei, budat, wrbtr, dmbtr, shkzg,
         rebzg, augdt
    FROM bsad
    FOR ALL ENTRIES IN @gt_cust
    WHERE bukrs = @p_bukrs
      AND kunnr = @gt_cust-kunnr
      AND budat <= @lv_max_date
      AND augdt >  @lv_min_date
    INTO TABLE @gt_bsad.

  IF sy-subrc <> 0.
    CLEAR gt_bsad.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CALC_OPEN_AMOUNT
*&---------------------------------------------------------------------*
*& Pure in-memory arithmetic over the line items read in
*& f_get_open_items. No database access.
*&---------------------------------------------------------------------*
FORM f_calc_open_amount  USING    iv_kunnr  TYPE kna1-kunnr
                                  iv_date   TYPE dats
                         CHANGING cv_amount TYPE dmbtr.

  DATA: ls_bsid TYPE ty_item,
        ls_bsad TYPE ty_clritem.

  CLEAR cv_amount.

  IF iv_kunnr IS INITIAL OR iv_date IS INITIAL.
    RETURN.
  ENDIF.

* Still open today and posted on or before the commitment date.
* GT_BSID is a sorted table keyed on KUNNR, so the WHERE below is a
* keyed access and not a full scan per output row.
  LOOP AT gt_bsid INTO ls_bsid WHERE kunnr = iv_kunnr.
    IF ls_bsid-budat > iv_date.
      CONTINUE.
    ENDIF.
    IF ls_bsid-shkzg = 'S'.
      cv_amount = cv_amount + ls_bsid-dmbtr.
    ELSEIF ls_bsid-shkzg = 'H'.
      cv_amount = cv_amount - ls_bsid-dmbtr.
    ENDIF.
  ENDLOOP.

* Cleared since, but still open on the commitment date.
  LOOP AT gt_bsad INTO ls_bsad WHERE kunnr = iv_kunnr.
    IF ls_bsad-budat > iv_date.
      CONTINUE.
    ENDIF.
    IF ls_bsad-augdt <= iv_date.
      CONTINUE.
    ENDIF.
    IF ls_bsad-shkzg = 'S'.
      cv_amount = cv_amount + ls_bsad-dmbtr.
    ELSEIF ls_bsad-shkzg = 'H'.
      cv_amount = cv_amount - ls_bsad-dmbtr.
    ENDIF.
  ENDLOOP.

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
        ls_cdate  TYPE ty_cdate,
        lv_amount TYPE dmbtr,
        lv_perc   TYPE p LENGTH 15 DECIMALS 2.

  CLEAR gt_output.

  LOOP AT gt_appr INTO ls_appr.

    CLEAR: ls_out, ls_cust, ls_name, ls_climit, ls_cdate,
           lv_amount, lv_perc.

    ls_out-kunnr = ls_appr-partner.

    READ TABLE gt_kna1 INTO ls_name
         WITH KEY kunnr = ls_appr-partner.
    IF sy-subrc = 0.
      ls_out-name1 = ls_name-name1.
    ENDIF.

*   L4/L5/L6 come from the customer table, filled by f_get_hierarchy.
*   They stay blank while GC_HIER_PROG names no executable report.
*   GT_CUST is sorted by KUNNR.
    READ TABLE gt_cust INTO ls_cust
         WITH KEY kunnr = ls_appr-partner BINARY SEARCH.
    IF sy-subrc = 0.
      ls_out-l4_name = ls_cust-l4_name.
      ls_out-l5_name = ls_cust-l5_name.
      ls_out-l6_name = ls_cust-l6_name.
    ENDIF.

*   Approval month as MM/YYYY, taken from the approval date from.
    IF ls_appr-datefr IS NOT INITIAL.
      ls_out-exc_month = ls_appr-datefr+4(2) && '/' && ls_appr-datefr(4).
    ENDIF.

    ls_out-exc_no = ls_appr-counter.

* ASSUMPTION (FS deviation 5): the FS shows an "Exceptional Approval
* Type" column with values Credit Limit / Order / Both but names no
* source field for it. The column is kept so the layout matches the FS
* and is left blank until functional confirms the field - open issue 2.
    CLEAR ls_out-exc_type.

    ls_out-date_from   = ls_appr-datefr.
    ls_out-date_to     = ls_appr-dateto.
    ls_out-exc_amnt    = ls_appr-amnt.
    ls_out-commit_text = ls_appr-text.

    READ TABLE gt_cdate INTO ls_cdate
         WITH KEY partner = ls_appr-partner
                  counter = ls_appr-counter.
    IF sy-subrc = 0.
      ls_out-commit_date = ls_cdate-commit_date.
    ENDIF.

    READ TABLE gt_climit INTO ls_climit
         WITH KEY partner = ls_appr-partner.
    IF sy-subrc = 0.
      ls_out-credit_limit = ls_climit-credit_limit.
    ENDIF.

    IF ls_out-commit_date IS NOT INITIAL.

*     LS_OUT-KUNNR carries the same value as LS_APPR-PARTNER but with
*     the KUNNR type, which is what the FORM signature expects.
      PERFORM f_calc_open_amount USING    ls_out-kunnr
                                          ls_out-commit_date
                                 CHANGING lv_amount.

      ls_out-act_os     = lv_amount.
      ls_out-non_fulfil = ls_out-act_os - ls_out-credit_limit.

      IF ls_out-credit_limit <> 0.
*       Computed in a wider packed field first. A limit that is a tiny
*       fraction of the outstanding could otherwise overflow DEF_PERC
*       and short dump instead of reporting.
        lv_perc = ( ls_out-non_fulfil * 100 ) / ls_out-credit_limit.
        IF lv_perc > 99999999999 OR lv_perc < -99999999999.
          CLEAR ls_out-def_perc.
        ELSE.
          ls_out-def_perc = lv_perc.
        ENDIF.
      ELSE.
*       Never divide by zero - the FS gives no rule for a zero limit.
        CLEAR ls_out-def_perc.
      ENDIF.

* ASSUMPTION (FS deviation 8): the FS defines the status only for a
* positive and a negative non-fulfilment amount. Exactly zero means
* nothing is outstanding above the limit, so it is reported as
* Fulfilled - see open issue 12.
      IF ls_out-non_fulfil > 0.
        ls_out-status = 'Not Fulfilled'(s01).
      ELSE.
        ls_out-status = 'Fulfilled'(s02).
      ENDIF.

    ELSE.

*     Commitment date could not be parsed. The row is still reported so
*     the user can see the text that was typed, but the as-on-date
*     figures and the status stay empty rather than showing a wrong
*     number.
      CLEAR: ls_out-act_os,
             ls_out-non_fulfil,
             ls_out-def_perc,
             ls_out-status.

    ENDIF.

* ASSUMPTION: the amount columns are shown in the company code currency
* of P_BUKRS. The credit limit of UKMBP_CMS_SGM is held in the credit
* segment currency, which is normally the same, but is not read here
* because the segment currency field name is not confirmed.
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
    MESSAGE 'No data to display for the selection'(m12)
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
  PERFORM f_add_fcat USING  7 'EXC_NO'       'Exception Number'(c07)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  8 'EXC_TYPE'     'Approval Type'(c08)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING  9 'DATE_FROM'    'Approval Date From'(c09)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 10 'DATE_TO'      'Approval Date To'(c10)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 11 'EXC_AMNT'     'Exceptional Amount'(c11)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 12 'COMMIT_DATE'  'Commitment Date'(c12)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 13 'COMMIT_TEXT'  'Commitment Text'(c13)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 14 'CREDIT_LIMIT' 'Actual Credit Limit'(c14)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 15 'ACT_OS'       'Actual OS on Commit Date'(c15)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 16 'NON_FULFIL'   'Non-Fulfilment Amount'(c16)
                              'WAERS' space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 17 'DEF_PERC'     'Default % Non-Fulfilment'(c17)
                              space   space   CHANGING lt_fcat.
  PERFORM f_add_fcat USING 18 'STATUS'       'Status'(c18)
                              space   space   CHANGING lt_fcat.

* WAERS is the currency reference for the amount columns above and is
* not a business column, so it is not displayed.
  PERFORM f_add_fcat USING 19 'WAERS'        'Currency'(c19)
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
    MESSAGE 'The report list could not be displayed'(m07)
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
