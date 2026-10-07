*&---------------------------------------------------------------------*
*& Report         : ZR_FIND_ENH
*& Title          : Enhancement finder - FM / method / program call tree
*& Project        : Internal developer utility       Module: BC
*& Related FS     : None - developer tool
*& Author         : Arnav Johri                  Date: 07.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Starts from a function module, a class method or a program, reads
*&   its source and follows CALL FUNCTION / PERFORM / method calls down
*&   to the chosen depth. Every enhancement option met on the way is
*&   listed in an ALV: customer exits (with SMOD/CMOD), classic BAdIs
*&   (with SE19 implementations), new BAdIs, explicit enhancement
*&   points/sections, BTE events, screen exits, USEREXIT_* forms and,
*&   optionally, implicit options at the start/end of each routine.
*&   Read-only. Static analysis: dynamic calls are counted, not followed.
*&
*& CHANGE HISTORY
*&   07.10.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zr_find_enh.

TYPES: ty_t_tok  TYPE STANDARD TABLE OF stokes WITH DEFAULT KEY,
       ty_t_stm  TYPE STANDARD TABLE OF sstmnt WITH DEFAULT KEY,
       ty_t_code TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
       ty_t_str  TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

* One routine to scan: an FM, a method, a FORM or a whole program
TYPES: BEGIN OF ty_unit,
         kind    TYPE c LENGTH 4,          "FUNC / METH / FORM / PROG
         name    TYPE string,
         disp    TYPE string,
         cls     TYPE seoclsname,          "owning class (METH only)
         main    TYPE progname,            "main program, for PERFORM
         include TYPE progname,
         row_fr  TYPE i,                   "0 = whole include
         row_to  TYPE i,
         depth   TYPE i,
         path    TYPE string,
       END OF ty_unit.

* Scanned source, cached per include
TYPES: BEGIN OF ty_src,
         include TYPE progname,
         ok      TYPE abap_bool,
         tok     TYPE ty_t_tok,
         stm     TYPE ty_t_stm,
       END OF ty_src.

* Where each FORM of a main program lives
TYPES: BEGIN OF ty_form,
         main    TYPE progname,
         frm     TYPE string,
         include TYPE progname,
         row_fr  TYPE i,
         row_to  TYPE i,
       END OF ty_form.

TYPES: BEGIN OF ty_inc,
         main    TYPE progname,
         include TYPE progname,
       END OF ty_inc.

TYPES: BEGIN OF ty_out,
         depth    TYPE i,
         enh_type TYPE c LENGTH 20,
         enh_name TYPE c LENGTH 70,
         detail   TYPE string,
         unit     TYPE string,
         include  TYPE progname,
         line     TYPE i,
         path     TYPE string,
       END OF ty_out.

CONSTANTS gc_quote TYPE c LENGTH 2 VALUE '''`'.

DATA: gt_queue TYPE STANDARD TABLE OF ty_unit WITH DEFAULT KEY,
      gt_seen  TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line,
      gt_src   TYPE HASHED TABLE OF ty_src WITH UNIQUE KEY include,
      gt_form  TYPE HASHED TABLE OF ty_form WITH UNIQUE KEY main frm,
      gt_inc   TYPE SORTED TABLE OF ty_inc WITH NON-UNIQUE KEY main,
      gt_mdone TYPE HASHED TABLE OF progname WITH UNIQUE KEY table_line,
      gt_out   TYPE STANDARD TABLE OF ty_out WITH DEFAULT KEY,
      gv_units TYPE i,
      gv_nf    TYPE i,
      gv_trunc TYPE abap_bool.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
  PARAMETERS: p_rfm  RADIOBUTTON GROUP st DEFAULT 'X' USER-COMMAND rad,
              p_fm   TYPE rs38l_fnam MODIF ID fm,
              p_rmt  RADIOBUTTON GROUP st,
              p_cls  TYPE seoclsname MODIF ID mt,
              p_mth  TYPE seocpdname MODIF ID mt,
              p_rpg  RADIOBUTTON GROUP st,
              p_prog TYPE progname MODIF ID pg.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
  PARAMETERS: p_depth TYPE i DEFAULT 4,
              p_max   TYPE i DEFAULT 1000,
              p_zcall AS CHECKBOX,
              p_impl  AS CHECKBOX,
              p_nf    AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b2.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'FM'.
        screen-input = COND #( WHEN p_rfm = abap_true THEN 1 ELSE 0 ).
      WHEN 'MT'.
        screen-input = COND #( WHEN p_rmt = abap_true THEN 1 ELSE 0 ).
      WHEN 'PG'.
        screen-input = COND #( WHEN p_rpg = abap_true THEN 1 ELSE 0 ).
      WHEN OTHERS.
        CONTINUE.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.
  IF p_depth < 0 OR p_max < 1.
    MESSAGE 'Depth must be 0 or more and the routine limit at least 1' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  PERFORM add_start.
  IF gt_queue IS INITIAL.
    RETURN.
  ENDIF.
  PERFORM walk.
  PERFORM display.

*&---------------------------------------------------------------------*
*& Form ADD_START - put the routine from the selection screen in queue
*&---------------------------------------------------------------------*
FORM add_start.
  DATA: lv_rc   TYPE i,
        lv_main TYPE progname,
        lv_name TYPE progname.

  CASE abap_true.
    WHEN p_rfm.
      IF p_fm IS INITIAL.
        MESSAGE 'Enter a function module' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      PERFORM add_fm USING p_fm 0 `` CHANGING lv_rc.
      IF lv_rc <> 0.
        MESSAGE |Function module { p_fm } does not exist| TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    WHEN p_rmt.
      IF p_cls IS INITIAL OR p_mth IS INITIAL.
        MESSAGE 'Enter a class and a method' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      PERFORM add_meth USING p_cls p_mth 0 `` CHANGING lv_rc.
      IF lv_rc <> 0.
        MESSAGE |Method { p_cls }=>{ p_mth } not found (local class or interface?)|
          TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    WHEN p_rpg.
      SELECT SINGLE name FROM trdir WHERE name = @p_prog INTO @lv_name.
      IF sy-subrc <> 0.
        MESSAGE |Program { p_prog } does not exist| TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
*     An include is scanned alone; its FORMs are looked up in its master
      SELECT SINGLE master FROM d010inc WHERE include = @p_prog INTO @lv_main.
      IF sy-subrc <> 0.
        lv_main = p_prog.
      ENDIF.
      PERFORM add_unit USING 'PROG' p_prog '' lv_main p_prog 0 0 0 ``.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_UNIT - queue a routine once (visited check)
*&---------------------------------------------------------------------*
FORM add_unit USING iv_kind  TYPE clike
                    iv_name  TYPE clike
                    iv_cls   TYPE clike
                    iv_main  TYPE clike
                    iv_inc   TYPE clike
                    iv_fr    TYPE i
                    iv_to    TYPE i
                    iv_depth TYPE i
                    iv_path  TYPE csequence.
  DATA: ls_unit TYPE ty_unit,
        lv_key  TYPE string.

  ls_unit-kind    = iv_kind.
  ls_unit-name    = iv_name.
  ls_unit-cls     = iv_cls.
  ls_unit-main    = iv_main.
  ls_unit-include = iv_inc.
  ls_unit-row_fr  = iv_fr.
  ls_unit-row_to  = iv_to.
  ls_unit-depth   = iv_depth.

  lv_key = |{ ls_unit-kind }\|{ ls_unit-main }\|{ ls_unit-name }|.
  INSERT lv_key INTO TABLE gt_seen.
  IF sy-subrc <> 0.
    RETURN.                            "already scanned via another path
  ENDIF.

  CASE ls_unit-kind.
    WHEN 'FORM'.
      ls_unit-disp = |FORM { ls_unit-name } ({ ls_unit-main })|.
    WHEN OTHERS.
      ls_unit-disp = ls_unit-name.
  ENDCASE.
  IF iv_path IS INITIAL.
    ls_unit-path = ls_unit-disp.
  ELSE.
    ls_unit-path = |{ iv_path } > { ls_unit-disp }|.
  ENDIF.
  APPEND ls_unit TO gt_queue.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_FM - resolve a function module to its include and queue it
*&---------------------------------------------------------------------*
FORM add_fm USING iv_fm    TYPE csequence
                  iv_depth TYPE i
                  iv_path  TYPE csequence
         CHANGING cv_rc    TYPE i.
  DATA: lv_fm   TYPE rs38l_fnam,
        lv_grp  TYPE string,
        lv_ns   TYPE string,
        lv_rest TYPE string,
        lv_inc  TYPE progname.

  cv_rc = 4.
  lv_fm = to_upper( iv_fm ).
  SELECT SINGLE pname, include FROM tfdir WHERE funcname = @lv_fm INTO @DATA(ls_fd).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

* SAPLXXXX -> LXXXXUnn ; SAPL/NS/XXXX -> /NS/LXXXXUnn
  lv_grp = ls_fd-pname+4.
  IF lv_grp IS NOT INITIAL AND lv_grp(1) = '/'.
    FIND REGEX '^(/[^/]+/)(.*)$' IN lv_grp SUBMATCHES lv_ns lv_rest.
    lv_inc = |{ lv_ns }L{ lv_rest }U{ ls_fd-include }|.
  ELSE.
    lv_inc = |L{ lv_grp }U{ ls_fd-include }|.
  ENDIF.

  cv_rc = 0.
  PERFORM add_unit USING 'FUNC' lv_fm '' ls_fd-pname lv_inc 0 0 iv_depth iv_path.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_METH - resolve a method (walking up superclasses) and queue
*&---------------------------------------------------------------------*
FORM add_meth USING iv_cls   TYPE csequence
                    iv_mth   TYPE csequence
                    iv_depth TYPE i
                    iv_path  TYPE csequence
           CHANGING cv_rc    TYPE i.
  DATA: ls_key  TYPE seocpdkey,
        lv_cls  TYPE seoclsname,
        lv_inc  TYPE progname,
        lv_main TYPE progname,
        lv_name TYPE string,
        lv_rc   TYPE i.

  cv_rc  = 4.
  lv_cls = to_upper( iv_cls ).
  DO 15 TIMES.
    ls_key-clsname = lv_cls.
    ls_key-cpdname = to_upper( iv_mth ).
    cl_oo_classname_service=>get_method_include(
      EXPORTING
        mtdkey              = ls_key
      RECEIVING
        result              = lv_inc
      EXCEPTIONS
        class_not_existing  = 1
        method_not_existing = 2
        OTHERS              = 3 ).
    lv_rc = sy-subrc.
    IF lv_rc = 0.
      cv_rc = 0.
      EXIT.
    ENDIF.
    IF lv_rc <> 2.
      EXIT.
    ENDIF.
*   Inherited, not redefined: the code sits in the superclass
*   ASSUMPTION: SEOMETAREL RELTYPE '2' = inheritance, REFCLSNAME = superclass
    SELECT SINGLE refclsname FROM seometarel
      WHERE clsname = @lv_cls
        AND reltype = '2'
      INTO @lv_cls.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
  ENDDO.
  IF cv_rc <> 0.
    RETURN.
  ENDIF.

  lv_main = |{ lv_cls WIDTH = 30 PAD = '=' }CP|.   "class pool name
  lv_name = |{ lv_cls }=>{ ls_key-cpdname }|.
  PERFORM add_unit USING 'METH' lv_name lv_cls lv_main lv_inc 0 0 iv_depth iv_path.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_FORM - locate a FORM in its main program and queue it
*&---------------------------------------------------------------------*
FORM add_form USING iv_main  TYPE csequence
                    iv_form  TYPE csequence
                    iv_depth TYPE i
                    iv_path  TYPE csequence
           CHANGING cv_rc    TYPE i.
  DATA: lv_main TYPE progname,
        lv_form TYPE string.

  cv_rc   = 4.
  lv_main = to_upper( iv_main ).
  lv_form = to_upper( iv_form ).
  PERFORM index_main USING lv_main.
  READ TABLE gt_form INTO DATA(ls_form) WITH TABLE KEY main = lv_main frm = lv_form.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  cv_rc = 0.
  PERFORM add_unit USING 'FORM' lv_form '' lv_main ls_form-include
                         ls_form-row_fr ls_form-row_to iv_depth iv_path.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form INDEX_MAIN - read every include of a main program, map its FORMs
*&---------------------------------------------------------------------*
FORM index_main USING iv_main TYPE progname.
  DATA: lt_inc  TYPE STANDARD TABLE OF progname WITH DEFAULT KEY,
        ls_inc  TYPE ty_inc,
        ls_form TYPE ty_form,
        lv_idx  TYPE i.
  FIELD-SYMBOLS: <ls_src> TYPE ty_src,
                 <ls_stm> TYPE sstmnt,
                 <ls_tok> TYPE stokes,
                 <ls_t2>  TYPE stokes.

  INSERT iv_main INTO TABLE gt_mdone.
  IF sy-subrc <> 0.
    RETURN.                            "already indexed
  ENDIF.

  SELECT include FROM d010inc WHERE master = @iv_main INTO TABLE @lt_inc.
  APPEND iv_main TO lt_inc.
  SORT lt_inc.
  DELETE ADJACENT DUPLICATES FROM lt_inc.

  LOOP AT lt_inc INTO DATA(lv_inc).
    ls_inc-main    = iv_main.
    ls_inc-include = lv_inc.
    INSERT ls_inc INTO TABLE gt_inc.

    PERFORM load_src USING lv_inc.
    READ TABLE gt_src ASSIGNING <ls_src> WITH TABLE KEY include = lv_inc.
    IF sy-subrc <> 0 OR <ls_src>-ok = abap_false.
      CONTINUE.
    ENDIF.

    CLEAR ls_form.
    LOOP AT <ls_src>-stm ASSIGNING <ls_stm>.
      READ TABLE <ls_src>-tok ASSIGNING <ls_tok> INDEX <ls_stm>-from.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      CASE <ls_tok>-str.
        WHEN 'FORM'.
          lv_idx = <ls_stm>-from + 1.
          READ TABLE <ls_src>-tok ASSIGNING <ls_t2> INDEX lv_idx.
          IF sy-subrc = 0.
            ls_form-main    = iv_main.
            ls_form-frm     = <ls_t2>-str.
            ls_form-include = lv_inc.
            ls_form-row_fr  = <ls_tok>-row.
          ENDIF.
        WHEN 'ENDFORM'.
          IF ls_form-frm IS NOT INITIAL.
            ls_form-row_to = <ls_tok>-row.
            INSERT ls_form INTO TABLE gt_form.
            CLEAR ls_form.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOAD_SRC - READ REPORT + SCAN once per include
*&---------------------------------------------------------------------*
FORM load_src USING iv_inc TYPE progname.
  DATA: ls_src  TYPE ty_src,
        lt_code TYPE ty_t_code.

  READ TABLE gt_src TRANSPORTING NO FIELDS WITH TABLE KEY include = iv_inc.
  IF sy-subrc = 0.
    RETURN.
  ENDIF.

  ls_src-include = iv_inc.
  READ REPORT iv_inc INTO lt_code.
  IF sy-subrc = 0.
*   sy-subrc 4/8 from SCAN = syntax trouble; keep what was tokenised
    SCAN ABAP-SOURCE lt_code TOKENS INTO ls_src-tok STATEMENTS INTO ls_src-stm.
    ls_src-ok = abap_true.
  ENDIF.
  INSERT ls_src INTO TABLE gt_src.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form WALK - breadth-first over the queue (it grows while scanning)
*&---------------------------------------------------------------------*
FORM walk.
  DATA: lv_idx  TYPE i,
        ls_unit TYPE ty_unit.

  WHILE lv_idx < lines( gt_queue ).
    IF lv_idx >= p_max.
      gv_trunc = abap_true.
      EXIT.
    ENDIF.
    lv_idx = lv_idx + 1.
    READ TABLE gt_queue INTO ls_unit INDEX lv_idx.
    PERFORM scan_unit USING ls_unit.
  ENDWHILE.
  gv_units = lv_idx.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SCAN_UNIT - look at every statement of one routine
*&---------------------------------------------------------------------*
FORM scan_unit USING is_unit TYPE ty_unit.
  DATA: lv_t1  TYPE string,
        lv_t2  TYPE string,
        lv_t3  TYPE string,
        lv_row TYPE i,
        lv_det TYPE string.
  FIELD-SYMBOLS: <ls_src> TYPE ty_src,
                 <ls_stm> TYPE sstmnt,
                 <ls_tok> TYPE stokes.

  PERFORM load_src USING is_unit-include.
  READ TABLE gt_src ASSIGNING <ls_src> WITH TABLE KEY include = is_unit-include.
  IF sy-subrc <> 0 OR <ls_src>-ok = abap_false.
    lv_det = `Source could not be read (READ REPORT failed)`.
    PERFORM add_hit USING is_unit 'NOT READ' is_unit-include lv_det 0.
    RETURN.
  ENDIF.

  IF p_impl = abap_true.
    lv_det = `Start/end of routine - Edit > Enhancement Operations > Show Implicit Enh. Options`.
    PERFORM add_hit USING is_unit 'IMPLICIT' is_unit-name lv_det is_unit-row_fr.
  ENDIF.

  LOOP AT <ls_src>-stm ASSIGNING <ls_stm>.
    READ TABLE <ls_src>-tok ASSIGNING <ls_tok> INDEX <ls_stm>-from.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    lv_row = <ls_tok>-row.
    IF is_unit-row_fr > 0 AND ( lv_row < is_unit-row_fr OR lv_row > is_unit-row_to ).
      CONTINUE.                        "outside this FORM
    ENDIF.

    lv_t1 = <ls_tok>-str.
    PERFORM tok USING <ls_src>-tok <ls_stm>-from 1 <ls_stm>-to CHANGING lv_t2.
    PERFORM tok USING <ls_src>-tok <ls_stm>-from 2 <ls_stm>-to CHANGING lv_t3.

    CASE lv_t1.
      WHEN 'CALL'.
        CASE lv_t2.
          WHEN 'FUNCTION'.
            PERFORM on_call_function USING is_unit <ls_src>-tok <ls_stm> lv_row.
          WHEN 'CUSTOMER-FUNCTION'.
            PERFORM on_customer_exit USING is_unit lv_t3 lv_row.
          WHEN 'CUSTOMER-SUBSCREEN'.
            lv_det = `Customer subscreen - screen exit, see SMOD/CMOD`.
            PERFORM add_hit USING is_unit 'SCREEN EXIT' lv_t3 lv_det lv_row.
          WHEN 'BADI'.
            lv_det = `CALL BADI - the BAdI name is on the matching GET BADI row`.
            PERFORM add_hit USING is_unit 'NEW BADI CALL' lv_t3 lv_det lv_row.
          WHEN 'METHOD'.
            PERFORM on_call_method USING is_unit <ls_src>-tok <ls_stm> lv_t3 lv_row.
        ENDCASE.
      WHEN 'GET'.
        IF lv_t2 = 'BADI'.
          PERFORM on_get_badi USING is_unit lv_t3 lv_row.
        ENDIF.
      WHEN 'PERFORM'.
        PERFORM on_perform USING is_unit <ls_src>-tok <ls_stm> lv_row.
      WHEN 'ENHANCEMENT-POINT' OR 'ENHANCEMENT-SECTION'.
        PERFORM on_enh_point USING is_unit <ls_src>-tok <ls_stm> lv_t1 lv_row.
    ENDCASE.

*   Functional method calls can sit inside any statement
    IF NOT ( lv_t1 = 'CALL' AND lv_t2 = 'METHOD' ).
      PERFORM on_functional USING is_unit <ls_src>-tok <ls_stm> lv_row.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form TOK - token at statement start + offset, blank past the end
*&---------------------------------------------------------------------*
FORM tok USING it_tok  TYPE ty_t_tok
               iv_from TYPE numeric
               iv_off  TYPE i
               iv_to   TYPE numeric
      CHANGING cv_str  TYPE string.
  DATA lv_idx TYPE i.

  CLEAR cv_str.
  lv_idx = iv_from + iv_off.
  IF lv_idx > iv_to.
    RETURN.
  ENDIF.
  READ TABLE it_tok ASSIGNING FIELD-SYMBOL(<ls_t>) INDEX lv_idx.
  IF sy-subrc = 0.
    cv_str = <ls_t>-str.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form LITERAL - 'TEXT' / `TEXT` -> TEXT ; anything else -> blank
*&---------------------------------------------------------------------*
FORM literal USING iv_raw TYPE string
          CHANGING cv_val TYPE string.
  DATA lv_len TYPE i.

  CLEAR cv_val.
  lv_len = strlen( iv_raw ).
  IF lv_len < 3.
    RETURN.
  ENDIF.
  IF iv_raw(1) CA gc_quote.
    cv_val = substring( val = iv_raw off = 1 len = lv_len - 2 ).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form NOT_FOLLOWED - count a call that cannot be resolved statically
*&---------------------------------------------------------------------*
FORM not_followed USING is_unit TYPE ty_unit
                        iv_name TYPE clike
                        iv_det  TYPE clike
                        iv_row  TYPE i.
  gv_nf = gv_nf + 1.
  IF p_nf = abap_true.
    PERFORM add_hit USING is_unit 'NOT FOLLOWED' iv_name iv_det iv_row.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_CALL_FUNCTION - BTE events, else follow the FM
*&---------------------------------------------------------------------*
FORM on_call_function USING is_unit TYPE ty_unit
                            it_tok  TYPE ty_t_tok
                            is_stm  TYPE sstmnt
                            iv_row  TYPE i.
  DATA: lv_raw   TYPE string,
        lv_fm    TYPE string,
        lv_det   TYPE string,
        lv_ev    TYPE string,
        lv_s     TYPE string,
        lv_n1    TYPE string,
        lv_n2    TYPE string,
        lv_i     TYPE i,
        lv_rc    TYPE i,
        lv_depth TYPE i.

  PERFORM tok USING it_tok is_stm-from 2 is_stm-to CHANGING lv_raw.
  PERFORM literal USING lv_raw CHANGING lv_fm.
  IF lv_fm IS INITIAL.
    lv_det = `Dynamic CALL FUNCTION - name only known at runtime`.
    PERFORM not_followed USING is_unit lv_raw lv_det iv_row.
    RETURN.
  ENDIF.
  lv_fm = to_upper( lv_fm ).

* Business Transaction Events: OPEN_FI_PERFORM_<event>_<P|E> etc.
  IF lv_fm CP 'OPEN_FI_PERFORM_*' OR lv_fm CP 'OUTBOUND_CALL_*'.
    FIND REGEX '_(\d{8})_' IN lv_fm SUBMATCHES lv_ev.
    lv_det = |BTE event { lv_ev } - FIBF > Settings > P/S modules or Process modules|.
    PERFORM add_hit USING is_unit 'BTE' lv_fm lv_det iv_row.
    RETURN.
  ENDIF.
  IF lv_fm = 'BF_FUNCTIONS_FIND'.
    lv_i = is_stm-from.
    WHILE lv_i <= is_stm-to.
      PERFORM tok USING it_tok lv_i 0 is_stm-to CHANGING lv_s.
      PERFORM tok USING it_tok lv_i 1 is_stm-to CHANGING lv_n1.
      PERFORM tok USING it_tok lv_i 2 is_stm-to CHANGING lv_n2.
      IF lv_s = 'I_EVENT' AND lv_n1 = '='.
        PERFORM literal USING lv_n2 CHANGING lv_ev.
        IF lv_ev IS INITIAL.
          lv_ev = lv_n2.
        ENDIF.
        EXIT.
      ENDIF.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_det = |BTE event { lv_ev } - FIBF > Settings > P/S modules or Process modules|.
    PERFORM add_hit USING is_unit 'BTE' lv_fm lv_det iv_row.
    RETURN.
  ENDIF.

  IF is_unit-depth >= p_depth.
    RETURN.
  ENDIF.
  IF p_zcall = abap_false AND ( lv_fm CP 'Z*' OR lv_fm CP 'Y*' ).
    RETURN.
  ENDIF.
  lv_depth = is_unit-depth + 1.
  PERFORM add_fm USING lv_fm lv_depth is_unit-path CHANGING lv_rc.
  IF lv_rc <> 0.
    lv_det = `Function module not in TFDIR (remote-only or deleted)`.
    PERFORM not_followed USING is_unit lv_fm lv_det iv_row.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_CUSTOMER_EXIT - CALL CUSTOMER-FUNCTION 'nnn'
*&---------------------------------------------------------------------*
FORM on_customer_exit USING is_unit TYPE ty_unit
                            iv_raw  TYPE string
                            iv_row  TYPE i.
  DATA: lv_no     TYPE string,
        lv_exit   TYPE string,
        lv_det    TYPE string,
        lv_list   TYPE string,
        lv_member TYPE modsap-member,
        lv_enh    TYPE modsap-name,
        lt_proj   TYPE STANDARD TABLE OF modact-name WITH DEFAULT KEY.

  PERFORM literal USING iv_raw CHANGING lv_no.
  lv_exit   = |EXIT_{ is_unit-main }_{ lv_no }|.
  lv_member = lv_exit.

  SELECT SINGLE name FROM modsap WHERE member = @lv_member INTO @lv_enh.
  IF sy-subrc = 0.
*   ASSUMPTION: MODACT-NAME = CMOD project, MODACT-MEMBER = SMOD enhancement
    SELECT name FROM modact WHERE member = @lv_enh INTO TABLE @lt_proj.
    IF lt_proj IS INITIAL.
      lv_det = |SMOD enhancement { lv_enh } - not in any CMOD project|.
    ELSE.
      CONCATENATE LINES OF lt_proj INTO lv_list SEPARATED BY ', '.
      lv_det = |SMOD enhancement { lv_enh } - CMOD project(s): { lv_list }|.
    ENDIF.
  ELSE.
    lv_det = `Exit FM not assigned to an SMOD enhancement`.
  ENDIF.
  PERFORM add_hit USING is_unit 'CUSTOMER EXIT' lv_exit lv_det iv_row.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_GET_BADI - GET BADI <var>: name comes from the var's type
*&---------------------------------------------------------------------*
FORM on_get_badi USING is_unit TYPE ty_unit
                       iv_var  TYPE string
                       iv_row  TYPE i.
  DATA: lv_type TYPE string,
        lv_det  TYPE string.

  PERFORM ref_type USING is_unit iv_var CHANGING lv_type.
  IF lv_type IS INITIAL.
    lv_det = |BAdI variable { iv_var } - type not resolved, check its DATA declaration|.
    PERFORM add_hit USING is_unit 'NEW BADI' iv_var lv_det iv_row.
  ELSE.
    lv_det = `SE18: BAdI definition and its implementations (Enhancement Implementations)`.
    PERFORM add_hit USING is_unit 'NEW BADI' lv_type lv_det iv_row.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form REF_TYPE - find "<var> TYPE REF TO <type>" in the main program
*&---------------------------------------------------------------------*
FORM ref_type USING is_unit TYPE ty_unit
                    iv_var  TYPE string
           CHANGING cv_type TYPE string.
  DATA: lt_inc TYPE STANDARD TABLE OF progname WITH DEFAULT KEY,
        lv_var TYPE string,
        lv_i   TYPE i,
        lv_n   TYPE i,
        lv_cnt TYPE i,
        lv_t1  TYPE string,
        lv_t2  TYPE string,
        lv_t3  TYPE string.
  FIELD-SYMBOLS: <ls_src> TYPE ty_src,
                 <ls_tok> TYPE stokes.

  CLEAR cv_type.
  lv_var = to_upper( iv_var ).
  IF lv_var CP 'ME->*'.
    lv_var = substring( val = lv_var off = 4 ).
  ENDIF.

  PERFORM index_main USING is_unit-main.
  APPEND is_unit-include TO lt_inc.            "own include first
  LOOP AT gt_inc INTO DATA(ls_inc) WHERE main = is_unit-main.
    APPEND ls_inc-include TO lt_inc.
  ENDLOOP.

  LOOP AT lt_inc INTO DATA(lv_inc).
    PERFORM load_src USING lv_inc.
    READ TABLE gt_src ASSIGNING <ls_src> WITH TABLE KEY include = lv_inc.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    lv_cnt = lines( <ls_src>-tok ).
    lv_n   = lv_cnt - 4.
    LOOP AT <ls_src>-tok ASSIGNING <ls_tok> WHERE str = lv_var.
      lv_i = sy-tabix.
      IF lv_i > lv_n.
        EXIT.
      ENDIF.
      PERFORM tok USING <ls_src>-tok lv_i 1 lv_cnt CHANGING lv_t1.
      PERFORM tok USING <ls_src>-tok lv_i 2 lv_cnt CHANGING lv_t2.
      PERFORM tok USING <ls_src>-tok lv_i 3 lv_cnt CHANGING lv_t3.
      IF lv_t1 = 'TYPE' AND lv_t2 = 'REF' AND lv_t3 = 'TO'.
        PERFORM tok USING <ls_src>-tok lv_i 4 lv_cnt CHANGING cv_type.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_PERFORM - USEREXIT_* forms, else follow the FORM
*&---------------------------------------------------------------------*
FORM on_perform USING is_unit TYPE ty_unit
                      it_tok  TYPE ty_t_tok
                      is_stm  TYPE sstmnt
                      iv_row  TYPE i.
  DATA: lv_t2    TYPE string,
        lv_t3    TYPE string,
        lv_t4    TYPE string,
        lv_t5    TYPE string,
        lv_form  TYPE string,
        lv_prog  TYPE string,
        lv_main  TYPE progname,
        lv_det   TYPE string,
        lv_rc    TYPE i,
        lv_depth TYPE i.

  PERFORM tok USING it_tok is_stm-from 1 is_stm-to CHANGING lv_t2.
  PERFORM tok USING it_tok is_stm-from 2 is_stm-to CHANGING lv_t3.
  PERFORM tok USING it_tok is_stm-from 3 is_stm-to CHANGING lv_t4.
  PERFORM tok USING it_tok is_stm-from 4 is_stm-to CHANGING lv_t5.

  IF lv_t2 IS INITIAL OR lv_t3 = 'OF'.
    RETURN.                            "PERFORM n OF f1 f2 ... - list form
  ENDIF.

  IF lv_t2 CA '('.
    IF lv_t2(1) = '('.
      lv_det = `Dynamic PERFORM - FORM name only known at runtime`.
      PERFORM not_followed USING is_unit lv_t2 lv_det iv_row.
      RETURN.
    ENDIF.
    SPLIT lv_t2 AT '(' INTO lv_form lv_prog.        "form(prog)
    REPLACE ALL OCCURRENCES OF ')' IN lv_prog WITH ''.
    IF lv_prog IS NOT INITIAL AND lv_prog(1) = '('.
      lv_det = `Dynamic PERFORM - program name only known at runtime`.
      PERFORM not_followed USING is_unit lv_t2 lv_det iv_row.
      RETURN.
    ENDIF.
  ELSE.
    lv_form = lv_t2.
    IF lv_t3 = 'IN' AND lv_t4 = 'PROGRAM'.
      IF lv_t5 IS INITIAL OR lv_t5(1) = '('.
        lv_det = `Dynamic PERFORM IN PROGRAM - program only known at runtime`.
        PERFORM not_followed USING is_unit lv_t2 lv_det iv_row.
        RETURN.
      ENDIF.
      lv_prog = lv_t5.
    ENDIF.
  ENDIF.

  IF lv_prog IS INITIAL.
    lv_main = is_unit-main.
  ELSE.
    lv_main = to_upper( lv_prog ).
  ENDIF.
  lv_form = to_upper( lv_form ).

* Modification-based user exits (MV45AFZZ, RV60AFZZ, ...)
  IF lv_form CP 'USEREXIT*'.
    PERFORM index_main USING lv_main.
    READ TABLE gt_form INTO DATA(ls_form) WITH TABLE KEY main = lv_main frm = lv_form.
    IF sy-subrc = 0.
      lv_det = |User exit FORM in include { ls_form-include } - modification, needs access key|.
    ELSE.
      lv_det = |User exit FORM, not located in { lv_main }|.
    ENDIF.
    PERFORM add_hit USING is_unit 'USER EXIT (FORM)' lv_form lv_det iv_row.
  ENDIF.

  IF is_unit-depth >= p_depth.
    RETURN.
  ENDIF.
  IF p_zcall = abap_false AND ( lv_main CP 'Z*' OR lv_main CP 'Y*' ).
    RETURN.
  ENDIF.
  lv_depth = is_unit-depth + 1.
  PERFORM add_form USING lv_main lv_form lv_depth is_unit-path CHANGING lv_rc.
  IF lv_rc <> 0.
    lv_det = |FORM not found in { lv_main }|.
    PERFORM not_followed USING is_unit lv_form lv_det iv_row.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_ENH_POINT - ENHANCEMENT-POINT / -SECTION <name> SPOTS <spot>
*&---------------------------------------------------------------------*
FORM on_enh_point USING is_unit TYPE ty_unit
                        it_tok  TYPE ty_t_tok
                        is_stm  TYPE sstmnt
                        iv_kw   TYPE string
                        iv_row  TYPE i.
  DATA: lv_name  TYPE string,
        lv_spots TYPE string,
        lv_s     TYPE string,
        lv_in    TYPE abap_bool,
        lv_i     TYPE i,
        lv_det   TYPE string,
        lv_type  TYPE c LENGTH 20.

  PERFORM tok USING it_tok is_stm-from 1 is_stm-to CHANGING lv_name.
  lv_i = is_stm-from + 2.
  WHILE lv_i <= is_stm-to.
    PERFORM tok USING it_tok lv_i 0 is_stm-to CHANGING lv_s.
    IF lv_s = 'SPOTS'.
      lv_in = abap_true.
    ELSEIF lv_s = 'STATIC' OR lv_s = 'INCLUDE' OR lv_s = 'BOUND'.
      lv_in = abap_false.
    ELSEIF lv_in = abap_true.
      lv_spots = |{ lv_spots } { lv_s }|.
    ENDIF.
    lv_i = lv_i + 1.
  ENDWHILE.

  IF iv_kw = 'ENHANCEMENT-POINT'.
    lv_type = 'ENH POINT'.
  ELSE.
    lv_type = 'ENH SECTION'.
  ENDIF.
  lv_det = |Spot:{ lv_spots } - SE18 (spot) / SE19 (implementations)|.
  PERFORM add_hit USING is_unit lv_type lv_name lv_det iv_row.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_CALL_METHOD - CALL METHOD <x>
*&---------------------------------------------------------------------*
FORM on_call_method USING is_unit TYPE ty_unit
                          it_tok  TYPE ty_t_tok
                          is_stm  TYPE sstmnt
                          iv_raw  TYPE string
                          iv_row  TYPE i.
  DATA lv_call TYPE string.

  lv_call = iv_raw.
  IF lv_call CP '*('.
    lv_call = substring( val = lv_call len = strlen( lv_call ) - 1 ).
  ENDIF.
  IF lv_call IS INITIAL.
    RETURN.
  ENDIF.
  PERFORM on_method_name USING is_unit it_tok is_stm lv_call iv_row.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_FUNCTIONAL - x=>meth( ) / x->meth( ) anywhere in a statement
*&---------------------------------------------------------------------*
FORM on_functional USING is_unit TYPE ty_unit
                         it_tok  TYPE ty_t_tok
                         is_stm  TYPE sstmnt
                         iv_row  TYPE i.
  DATA: lv_i   TYPE i,
        lv_s   TYPE string,
        lv_len TYPE i.

  lv_i = is_stm-from.
  WHILE lv_i <= is_stm-to.
    PERFORM tok USING it_tok lv_i 0 is_stm-to CHANGING lv_s.
    lv_len = strlen( lv_s ).
    IF lv_len > 3 AND lv_s CP '*(' AND lv_s(1) <> ')' AND lv_s(1) NA gc_quote
       AND ( lv_s CS '->' OR lv_s CS '=>' ).
      lv_s = substring( val = lv_s len = lv_len - 1 ).
      PERFORM on_method_name USING is_unit it_tok is_stm lv_s iv_row.
    ENDIF.
    lv_i = lv_i + 1.
  ENDWHILE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_METHOD_NAME - classic BAdI check, else resolve and follow
*&---------------------------------------------------------------------*
FORM on_method_name USING is_unit TYPE ty_unit
                          it_tok  TYPE ty_t_tok
                          is_stm  TYPE sstmnt
                          iv_call TYPE string
                          iv_row  TYPE i.
  DATA: lv_call  TYPE string,
        lv_left  TYPE string,
        lv_arrow TYPE string,
        lv_meth  TYPE string,
        lv_cls   TYPE seoclsname,
        lv_det   TYPE string,
        lv_rc    TYPE i,
        lv_depth TYPE i,
        lt_cls   TYPE ty_t_str.

  lv_call = to_upper( iv_call ).
  IF lv_call CS '->(' OR lv_call CS '=>('.
    lv_det = `Dynamic method call - name only known at runtime`.
    PERFORM not_followed USING is_unit lv_call lv_det iv_row.
    RETURN.
  ENDIF.

  FIND REGEX '^(.*)(->|=>)([^>]+)$' IN lv_call SUBMATCHES lv_left lv_arrow lv_meth.
  IF sy-subrc <> 0.
    lv_left  = 'ME'.                   "CALL METHOD meth - own class
    lv_arrow = '->'.
    lv_meth  = lv_call.
  ENDIF.

  IF lv_arrow = '=>' AND lv_left NS '->' AND lv_left NS '=>'.
    lv_cls = lv_left.                  "static call on a class
  ELSEIF lv_left = 'ME'.
    lv_cls = is_unit-cls.
  ELSEIF lv_left = 'SUPER' AND is_unit-cls IS NOT INITIAL.
*   ASSUMPTION: SEOMETAREL RELTYPE '2' = inheritance (see ADD_METH)
    SELECT SINGLE refclsname FROM seometarel
      WHERE clsname = @is_unit-cls
        AND reltype = '2'
      INTO @lv_cls.
  ENDIF.

* Classic BAdI instantiation - report it, do not follow into the handler
  IF lv_cls = 'CL_EXITHANDLER' AND lv_meth = 'GET_INSTANCE'.
    PERFORM on_classic_badi USING is_unit it_tok is_stm iv_row.
    RETURN.
  ENDIF.

  IF is_unit-depth >= p_depth.
    RETURN.
  ENDIF.

  IF lv_cls IS NOT INITIAL.
    APPEND lv_cls TO lt_cls.
  ELSE.
    PERFORM xref_classes USING is_unit-include lv_meth CHANGING lt_cls.
  ENDIF.
  IF lt_cls IS INITIAL.
    lv_det = `Instance call - class not resolvable statically (no where-used entry)`.
    PERFORM not_followed USING is_unit lv_call lv_det iv_row.
    RETURN.
  ENDIF.

  lv_depth = is_unit-depth + 1.
  LOOP AT lt_cls INTO DATA(lv_cname).
    IF p_zcall = abap_false AND ( lv_cname CP 'Z*' OR lv_cname CP 'Y*' ).
      CONTINUE.
    ENDIF.
    PERFORM add_meth USING lv_cname lv_meth lv_depth is_unit-path CHANGING lv_rc.
    IF lv_rc <> 0.
      lv_det = |{ lv_cname }=>{ lv_meth } not found (local class or interface method)|.
      PERFORM not_followed USING is_unit lv_call lv_det iv_row.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form XREF_CLASSES - classes whose method <meth> this include calls
*&---------------------------------------------------------------------*
FORM xref_classes USING iv_inc  TYPE progname
                        iv_meth TYPE string
               CHANGING ct_cls  TYPE ty_t_str.
  DATA: lt_name TYPE STANDARD TABLE OF wbcrossgt-name WITH DEFAULT KEY,
        lv_sfx  TYPE string,
        lv_like TYPE string,
        lv_full TYPE string,
        lv_cls  TYPE string,
        lv_rest TYPE string.

* Where-used index (filled by SAPRSEUB / on activation).
* ASSUMPTION: method refs are stored as OTYPE 'ME', NAME '<CLASS>\ME:<METHOD>'
  lv_sfx  = |\\ME:{ iv_meth }|.
  lv_like = |%{ lv_sfx }|.
  SELECT name FROM wbcrossgt
    WHERE otype   = 'ME'
      AND include = @iv_inc
      AND name LIKE @lv_like
    INTO TABLE @lt_name.

  LOOP AT lt_name INTO DATA(lv_name).
    lv_full = lv_name.
    SPLIT lv_full AT '\' INTO lv_cls lv_rest.
    IF lv_full = |{ lv_cls }{ lv_sfx }|.      "'_' in LIKE is a wildcard
      APPEND lv_cls TO ct_cls.
    ENDIF.
  ENDLOOP.
  SORT ct_cls.
  DELETE ADJACENT DUPLICATES FROM ct_cls.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ON_CLASSIC_BADI - CL_EXITHANDLER=>GET_INSTANCE
*&---------------------------------------------------------------------*
FORM on_classic_badi USING is_unit TYPE ty_unit
                           it_tok  TYPE ty_t_tok
                           is_stm  TYPE sstmnt
                           iv_row  TYPE i.
  DATA: lv_i    TYPE i,
        lv_s    TYPE string,
        lv_n1   TYPE string,
        lv_n2   TYPE string,
        lv_exit TYPE string,
        lv_var  TYPE string,
        lv_type TYPE string,
        lv_det  TYPE string,
        lv_list TYPE string,
        lt_imp  TYPE STANDARD TABLE OF sxc_exit-imp_name WITH DEFAULT KEY.

  lv_i = is_stm-from.
  WHILE lv_i <= is_stm-to.
    PERFORM tok USING it_tok lv_i 0 is_stm-to CHANGING lv_s.
    PERFORM tok USING it_tok lv_i 1 is_stm-to CHANGING lv_n1.
    PERFORM tok USING it_tok lv_i 2 is_stm-to CHANGING lv_n2.
    IF lv_n1 = '='.
      IF lv_s = 'EXIT_NAME'.
        PERFORM literal USING lv_n2 CHANGING lv_exit.
      ELSEIF lv_s = 'INSTANCE'.
        lv_var = lv_n2.
      ENDIF.
    ENDIF.
    lv_i = lv_i + 1.
  ENDWHILE.

* No EXIT_NAME literal: the BAdI is IF_EX_<name> on the instance variable
  IF lv_exit IS INITIAL AND lv_var IS NOT INITIAL.
    PERFORM ref_type USING is_unit lv_var CHANGING lv_type.
    IF lv_type CP 'IF_EX_*'.
      lv_exit = substring( val = lv_type off = 6 ).
    ENDIF.
  ENDIF.

  IF lv_exit IS INITIAL.
    lv_exit = lv_var.
    lv_det  = `Classic BAdI - name not resolved, read EXIT_NAME/INSTANCE at this line`.
  ELSE.
    lv_exit = to_upper( lv_exit ).
    SELECT imp_name FROM sxc_exit WHERE exit_name = @lv_exit INTO TABLE @lt_imp.
    IF lt_imp IS INITIAL.
      lv_det = `SE18 - no implementation exists yet`.
    ELSE.
      CONCATENATE LINES OF lt_imp INTO lv_list SEPARATED BY ', '.
      lv_det = |Implementation(s): { lv_list } - check Active in SE19|.
    ENDIF.
  ENDIF.
  PERFORM add_hit USING is_unit 'CLASSIC BADI' lv_exit lv_det iv_row.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_HIT - one output row
*&---------------------------------------------------------------------*
FORM add_hit USING is_unit TYPE ty_unit
                   iv_type TYPE clike
                   iv_name TYPE clike
                   iv_det  TYPE clike
                   iv_row  TYPE i.
  DATA ls_out TYPE ty_out.

  ls_out-depth    = is_unit-depth.
  ls_out-enh_type = iv_type.
  ls_out-enh_name = iv_name.
  ls_out-detail   = iv_det.
  ls_out-unit     = is_unit-disp.
  ls_out-include  = is_unit-include.
  ls_out-line     = iv_row.
  ls_out-path     = is_unit-path.
  APPEND ls_out TO gt_out.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY - SALV list + run summary
*&---------------------------------------------------------------------*
FORM display.
  DATA: lo_alv   TYPE REF TO cl_salv_table,
        lx_msg   TYPE REF TO cx_salv_msg,
        lv_title TYPE lvc_title,
        lv_msg   TYPE string.

  lv_msg = |{ gv_units } routine(s) scanned, { lines( gt_out ) } row(s), |
        && |{ gv_nf } call(s) not followed|.
  IF gv_trunc = abap_true.
    lv_msg = |{ lv_msg } - stopped at the limit of { p_max } routines|.
  ENDIF.

  IF gt_out IS INITIAL.
    MESSAGE |No enhancement options found. { lv_msg }| TYPE 'S'.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = gt_out ).
    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE lx_msg TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_alv->get_functions( )->set_all( abap_true ).
  lo_alv->get_columns( )->set_optimize( abap_true ).
  PERFORM col_text USING lo_alv 'DEPTH'    'Depth'     'Depth'        'Call depth'.
  PERFORM col_text USING lo_alv 'ENH_TYPE' 'Type'      'Enh. type'    'Enhancement type'.
  PERFORM col_text USING lo_alv 'ENH_NAME' 'Name'      'Enh. name'    'Exit / BAdI / point name'.
  PERFORM col_text USING lo_alv 'DETAIL'   'Detail'    'Where to look' 'Detail / where to look'.
  PERFORM col_text USING lo_alv 'UNIT'     'Found in'  'Found in'     'Routine (FM / method / FORM)'.
  PERFORM col_text USING lo_alv 'INCLUDE'  'Include'   'Include'      'Include'.
  PERFORM col_text USING lo_alv 'LINE'     'Line'      'Line'         'Line in include'.
  PERFORM col_text USING lo_alv 'PATH'     'Call path' 'Call path'    'Call path from start'.

  lv_title = lv_msg.
  lo_alv->get_display_settings( )->set_list_header( lv_title ).
  MESSAGE lv_msg TYPE 'S'.
  lo_alv->display( ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form COL_TEXT - readable column headings
*&---------------------------------------------------------------------*
FORM col_text USING io_alv  TYPE REF TO cl_salv_table
                    iv_col  TYPE clike
                    iv_shrt TYPE clike
                    iv_med  TYPE clike
                    iv_long TYPE clike.
  DATA: lo_col  TYPE REF TO cl_salv_column,
        lv_name TYPE lvc_fname,
        lv_s    TYPE scrtext_s,
        lv_m    TYPE scrtext_m,
        lv_l    TYPE scrtext_l.

  lv_name = iv_col.
  lv_s    = iv_shrt.
  lv_m    = iv_med.
  lv_l    = iv_long.
  TRY.
      lo_col = io_alv->get_columns( )->get_column( lv_name ).
      lo_col->set_short_text( lv_s ).
      lo_col->set_medium_text( lv_m ).
      lo_col->set_long_text( lv_l ).
    CATCH cx_salv_not_found.
*     Column names are fixed in TY_OUT - cannot happen
      RETURN.
  ENDTRY.
ENDFORM.
