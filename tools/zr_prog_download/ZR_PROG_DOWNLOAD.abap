*&---------------------------------------------------------------------*
*& Report         : ZR_PROG_DOWNLOAD
*& Title          : Mass download of ABAP sources with include tree
*& Project        : Internal developer utility       Module: BC
*& Related FS     : None - developer tool
*& Author         : Arnav Johri                  Date: 19.10.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Downloads programs (with their complete include tree), function
*&   groups, classes and CDS DDL sources to the PC or to the application
*&   server, one file per object, in the "print with includes" listing
*&   layout: a banner per unit (main program or include) with level,
*&   line count, system, user and timestamp, then the numbered source
*&   lines and an end marker. Objects are chosen by name list or by
*&   package. Read-only: nothing in the system is changed.
*&
*& CHANGE HISTORY
*&   19.10.2026  Arnav Johri  <TR>  Rewritten - the earlier version was
*&                                  not kept in the repository. CDS DDL
*&                                  sources (DDLS) added.
*&---------------------------------------------------------------------*
REPORT zr_prog_download LINE-SIZE 255.

TYPES: ty_t_line TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
       ty_t_name TYPE STANDARD TABLE OF progname WITH DEFAULT KEY,
       ty_t_tok  TYPE STANDARD TABLE OF stokex WITH DEFAULT KEY,
       ty_t_stm  TYPE STANDARD TABLE OF sstmnt WITH DEFAULT KEY.

* One object to download
TYPES: BEGIN OF ty_obj,
         otype TYPE trobjtype,      "PROG / INCL / FUGR / CLAS / DDLS
         name  TYPE sobj_name,
         main  TYPE progname,       "program read first (SAPL.., ..CP)
       END OF ty_obj.
TYPES ty_t_obj TYPE STANDARD TABLE OF ty_obj WITH DEFAULT KEY.

* Result line per object
TYPES: BEGIN OF ty_log,
         otype  TYPE trobjtype,
         name   TYPE sobj_name,
         incl   TYPE i,            "includes written below the main unit
         lines  TYPE i,            "source lines written
         status TYPE string,
         file   TYPE string,
       END OF ty_log.

DATA: gt_obj   TYPE ty_t_obj,
      gt_incl  TYPE ty_t_obj,       "package mode: includes, written only if not reached
      gt_log   TYPE STANDARD TABLE OF ty_log WITH DEFAULT KEY,
      gt_done  TYPE HASHED TABLE OF progname WITH UNIQUE KEY table_line,  "per object
      gt_seen  TYPE HASHED TABLE OF progname WITH UNIQUE KEY table_line,  "whole run
      gv_rule  TYPE string,
      gv_stamp TYPE string,
      gv_page  TYPE i,
      gv_main  TYPE progname,
      gv_otype TYPE trobjtype.

* Reference fields for the SELECT-OPTIONS
DATA: gv_prog TYPE progname,
      gv_fugr TYPE rs38l_area,
      gv_clas TYPE seoclsname,
      gv_ddls TYPE ddlname,
      gv_devc TYPE devclass.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_byname RADIOBUTTON GROUP sel DEFAULT 'X' USER-COMMAND sel,
            p_bypack RADIOBUTTON GROUP sel.
SELECT-OPTIONS: s_prog FOR gv_prog NO INTERVALS MODIF ID nam,
                s_fugr FOR gv_fugr NO INTERVALS MODIF ID nam,
                s_clas FOR gv_clas NO INTERVALS MODIF ID nam,
                s_ddls FOR gv_ddls NO INTERVALS MODIF ID nam,
                s_devc FOR gv_devc NO INTERVALS MODIF ID pak.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS: p_tprog AS CHECKBOX DEFAULT 'X' MODIF ID pak,
            p_tfugr AS CHECKBOX DEFAULT 'X' MODIF ID pak,
            p_tclas AS CHECKBOX DEFAULT 'X' MODIF ID pak,
            p_tddls AS CHECKBOX DEFAULT 'X' MODIF ID pak.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.
PARAMETERS: p_front RADIOBUTTON GROUP dst DEFAULT 'X' USER-COMMAND dst,
            p_fdir  TYPE c LENGTH 255 LOWER CASE MODIF ID fro,
            p_appl  RADIOBUTTON GROUP dst,
            p_adir  TYPE c LENGTH 255 LOWER CASE MODIF ID app,
            p_ext   TYPE c LENGTH 10 LOWER CASE DEFAULT 'abap'.
SELECTION-SCREEN END OF BLOCK b3.

*----------------------------------------------------------------------*
* Selection screen events
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'NAM'.
        IF p_bypack = abap_true.
          screen-input = 0.
        ENDIF.
      WHEN 'PAK'.
        IF p_byname = abap_true.
          screen-input = 0.
        ENDIF.
      WHEN 'FRO'.
        IF p_appl = abap_true.
          screen-input = 0.
        ENDIF.
      WHEN 'APP'.
        IF p_front = abap_true.
          screen-input = 0.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fdir.
  PERFORM f4_folder.

AT SELECTION-SCREEN.
  IF sy-ucomm = 'SEL' OR sy-ucomm = 'DST'.
    RETURN.                       "radio button click only redraws the screen
  ENDIF.
  IF p_byname = abap_true
     AND s_prog[] IS INITIAL AND s_fugr[] IS INITIAL
     AND s_clas[] IS INITIAL AND s_ddls[] IS INITIAL.
    MESSAGE 'Enter at least one program, function group, class or DDL source'(m02) TYPE 'E'.
  ENDIF.
  IF p_bypack = abap_true AND s_devc[] IS INITIAL.
    MESSAGE 'Enter at least one package'(m03) TYPE 'E'.
  ENDIF.
  IF p_front = abap_true AND p_fdir IS INITIAL.
    MESSAGE 'Enter the folder on the PC'(m04) TYPE 'E'.
  ENDIF.
  IF p_appl = abap_true AND p_adir IS INITIAL.
    MESSAGE 'Enter the directory on the application server'(m05) TYPE 'E'.
  ENDIF.

*----------------------------------------------------------------------*
* Main
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM init_run.
  PERFORM collect_objects.
  IF gt_obj IS INITIAL AND gt_incl IS INITIAL.
    MESSAGE 'No object matched the selection'(m01) TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_obj INTO DATA(gs_obj).
    PERFORM download_object USING gs_obj.
  ENDLOOP.

* Package mode: includes of the package that no main program pulled in
  LOOP AT gt_incl INTO gs_obj.
    READ TABLE gt_seen TRANSPORTING NO FIELDS WITH TABLE KEY table_line = gs_obj-main.
    IF sy-subrc <> 0.
      PERFORM download_object USING gs_obj.
    ENDIF.
  ENDLOOP.

  PERFORM show_log.

*&---------------------------------------------------------------------*
*& Form INIT_RUN
*&---------------------------------------------------------------------*
FORM init_run.
  CLEAR: gt_obj, gt_incl, gt_log, gt_seen.
  gv_rule  = repeat( val = '-' occ = 100 ).
  gv_stamp = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }|
          && | { sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }|.
  IF p_ext IS INITIAL.
    p_ext = 'abap'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_FOLDER - folder picker for the PC download
*&---------------------------------------------------------------------*
FORM f4_folder.
  DATA lv_dir TYPE string.

  CALL METHOD cl_gui_frontend_services=>directory_browse
    EXPORTING
      window_title         = 'Download folder'(t01)
    CHANGING
      selected_folder      = lv_dir
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc = 0 AND lv_dir IS NOT INITIAL.
    p_fdir = lv_dir.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form COLLECT_OBJECTS
*&---------------------------------------------------------------------*
FORM collect_objects.
  IF p_byname = abap_true.
    PERFORM collect_by_name.
  ELSE.
    PERFORM collect_by_package.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form COLLECT_BY_NAME - name lists -> GT_OBJ, unknown names -> log
*&---------------------------------------------------------------------*
FORM collect_by_name.
  DATA: ls_obj TYPE ty_obj,
        ls_log TYPE ty_log.

* Programs - an include named directly is downloaded on its own
  IF s_prog[] IS NOT INITIAL.
    SELECT name, subc
      FROM trdir
      WHERE name IN @s_prog
      ORDER BY name
      INTO TABLE @DATA(lt_dir).
    LOOP AT lt_dir INTO DATA(ls_dir).
      CLEAR ls_obj.
      IF ls_dir-subc = 'I'.
        ls_obj-otype = 'INCL'.
      ELSE.
        ls_obj-otype = 'PROG'.
      ENDIF.
      ls_obj-name = ls_dir-name.
      ls_obj-main = ls_dir-name.
      APPEND ls_obj TO gt_obj.
    ENDLOOP.
    LOOP AT s_prog INTO DATA(ls_rp) WHERE sign = 'I' AND option = 'EQ'.
      READ TABLE lt_dir TRANSPORTING NO FIELDS WITH KEY name = ls_rp-low.
      IF sy-subrc <> 0.
        CLEAR ls_log.
        ls_log-otype  = 'PROG'.
        ls_log-name   = ls_rp-low.
        ls_log-status = 'Program does not exist'(s02).
        APPEND ls_log TO gt_log.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Function groups -> main program SAPL<group>
  IF s_fugr[] IS NOT INITIAL.
    SELECT area
      FROM tlibg
      WHERE area IN @s_fugr
      ORDER BY area
      INTO TABLE @DATA(lt_fg).
    LOOP AT lt_fg INTO DATA(ls_fg).
      CLEAR ls_obj.
      ls_obj-otype = 'FUGR'.
      ls_obj-name  = ls_fg-area.
      PERFORM fugr_main_program USING ls_fg-area CHANGING ls_obj-main.
      APPEND ls_obj TO gt_obj.
    ENDLOOP.
    LOOP AT s_fugr INTO DATA(ls_rf) WHERE sign = 'I' AND option = 'EQ'.
      READ TABLE lt_fg TRANSPORTING NO FIELDS WITH KEY area = ls_rf-low.
      IF sy-subrc <> 0.
        CLEAR ls_log.
        ls_log-otype  = 'FUGR'.
        ls_log-name   = ls_rf-low.
        ls_log-status = 'Function group does not exist'(s06).
        APPEND ls_log TO gt_log.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Classes -> class pool <class>====...CP
  IF s_clas[] IS NOT INITIAL.
    SELECT clsname
      FROM seoclass
      WHERE clsname IN @s_clas
        AND clstype = '0'
      ORDER BY clsname
      INTO TABLE @DATA(lt_cl).
    LOOP AT lt_cl INTO DATA(ls_cl).
      CLEAR ls_obj.
      ls_obj-otype = 'CLAS'.
      ls_obj-name  = ls_cl-clsname.
      PERFORM class_pool_name USING ls_cl-clsname CHANGING ls_obj-main.
      APPEND ls_obj TO gt_obj.
    ENDLOOP.
    LOOP AT s_clas INTO DATA(ls_rc) WHERE sign = 'I' AND option = 'EQ'.
      READ TABLE lt_cl TRANSPORTING NO FIELDS WITH KEY clsname = ls_rc-low.
      IF sy-subrc <> 0.
        CLEAR ls_log.
        ls_log-otype  = 'CLAS'.
        ls_log-name   = ls_rc-low.
        ls_log-status = 'Class does not exist'(s07).
        APPEND ls_log TO gt_log.
      ENDIF.
    ENDLOOP.
  ENDIF.

* CDS DDL sources - active version only
  IF s_ddls[] IS NOT INITIAL.
    SELECT ddlname
      FROM ddddlsrc
      WHERE ddlname IN @s_ddls
        AND as4local = 'A'
      ORDER BY ddlname
      INTO TABLE @DATA(lt_dd).
    LOOP AT lt_dd INTO DATA(ls_dd).
      CLEAR ls_obj.
      ls_obj-otype = 'DDLS'.
      ls_obj-name  = ls_dd-ddlname.
      ls_obj-main  = ls_dd-ddlname.
      APPEND ls_obj TO gt_obj.
    ENDLOOP.
    LOOP AT s_ddls INTO DATA(ls_rd) WHERE sign = 'I' AND option = 'EQ'.
      READ TABLE lt_dd TRANSPORTING NO FIELDS WITH KEY ddlname = ls_rd-low.
      IF sy-subrc <> 0.
        CLEAR ls_log.
        ls_log-otype  = 'DDLS'.
        ls_log-name   = ls_rd-low.
        ls_log-status = 'DDL source does not exist (active)'(s03).
        APPEND ls_log TO gt_log.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form COLLECT_BY_PACKAGE - TADIR of the packages -> GT_OBJ / GT_INCL
*&---------------------------------------------------------------------*
FORM collect_by_package.
  DATA: ls_obj TYPE ty_obj,
        lt_pn  TYPE ty_t_name,
        lt_dir TYPE STANDARD TABLE OF trdir WITH DEFAULT KEY.

  SELECT object, obj_name
    FROM tadir
    WHERE pgmid    = 'R3TR'
      AND object   IN ( 'PROG', 'FUGR', 'CLAS', 'DDLS' )
      AND devclass IN @s_devc
      AND delflag  = @space
    ORDER BY object, obj_name
    INTO TABLE @DATA(lt_tadir).

* Program type decides main program vs include
  LOOP AT lt_tadir INTO DATA(ls_td) WHERE object = 'PROG'.
    APPEND ls_td-obj_name TO lt_pn.
  ENDLOOP.
  IF lt_pn IS NOT INITIAL.
    SELECT name, subc
      FROM trdir
      FOR ALL ENTRIES IN @lt_pn
      WHERE name = @lt_pn-table_line
      INTO CORRESPONDING FIELDS OF TABLE @lt_dir.
  ENDIF.
  SORT lt_dir BY name.

  LOOP AT lt_tadir INTO ls_td.
    CLEAR ls_obj.
    ls_obj-name = ls_td-obj_name.
    CASE ls_td-object.
      WHEN 'PROG'.
        IF p_tprog = abap_false.
          CONTINUE.
        ENDIF.
        ls_obj-main = ls_td-obj_name.
        READ TABLE lt_dir INTO DATA(ls_dir) WITH KEY name = ls_obj-main BINARY SEARCH.
        IF sy-subrc = 0 AND ls_dir-subc = 'I'.
          ls_obj-otype = 'INCL'.
          APPEND ls_obj TO gt_incl.
        ELSE.
          ls_obj-otype = 'PROG'.
          APPEND ls_obj TO gt_obj.
        ENDIF.
      WHEN 'FUGR'.
        IF p_tfugr = abap_false.
          CONTINUE.
        ENDIF.
        ls_obj-otype = 'FUGR'.
        PERFORM fugr_main_program USING ls_td-obj_name CHANGING ls_obj-main.
        APPEND ls_obj TO gt_obj.
      WHEN 'CLAS'.
        IF p_tclas = abap_false.
          CONTINUE.
        ENDIF.
        ls_obj-otype = 'CLAS'.
        PERFORM class_pool_name USING ls_td-obj_name CHANGING ls_obj-main.
        APPEND ls_obj TO gt_obj.
      WHEN 'DDLS'.
        IF p_tddls = abap_false.
          CONTINUE.
        ENDIF.
        ls_obj-otype = 'DDLS'.
        ls_obj-main  = ls_td-obj_name.
        APPEND ls_obj TO gt_obj.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FUGR_MAIN_PROGRAM - ZXX -> SAPLZXX, /NS/XX -> /NS/SAPLXX
*&---------------------------------------------------------------------*
FORM fugr_main_program USING iv_area TYPE clike CHANGING cv_main TYPE progname.
  DATA: lv_area TYPE string,
        lv_rest TYPE string,
        lv_pos  TYPE i.

  lv_area = iv_area.
  IF lv_area(1) = '/'.
    lv_rest = lv_area+1.
    FIND '/' IN lv_rest MATCH OFFSET lv_pos.
    IF sy-subrc = 0.
      lv_pos  = lv_pos + 2.                   "length of '/NS/'
      cv_main = lv_area(lv_pos) && 'SAPL' && lv_area+lv_pos.
      RETURN.
    ENDIF.
  ENDIF.
  cv_main = 'SAPL' && lv_area.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form CLASS_POOL_NAME - ZCL_X -> ZCL_X=====================CP
*&---------------------------------------------------------------------*
FORM class_pool_name USING iv_class TYPE clike CHANGING cv_main TYPE progname.
  DATA lv_pool TYPE c LENGTH 30.

  lv_pool = iv_class.
  TRANSLATE lv_pool USING ' ='.
  cv_main = lv_pool && 'CP'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form DOWNLOAD_OBJECT - build the listing of one object, write it
*&---------------------------------------------------------------------*
FORM download_object USING is_obj TYPE ty_obj.
  DATA: lt_out   TYPE ty_t_line,
        ls_log   TYPE ty_log,
        lv_units TYPE i,
        lv_lines TYPE i.

  CLEAR gt_done.
  gv_page  = 0.
  gv_main  = is_obj-main.
  gv_otype = is_obj-otype.
  ls_log-otype = is_obj-otype.
  ls_log-name  = is_obj-name.

  IF is_obj-otype = 'DDLS'.
    PERFORM add_ddl_source USING is_obj-name
                           CHANGING lt_out lv_units lv_lines ls_log-status.
  ELSE.
    PERFORM add_program USING is_obj-main 0
                        CHANGING lt_out lv_units lv_lines ls_log-status.
  ENDIF.

  IF lv_units = 0.
    IF ls_log-status IS INITIAL.
      ls_log-status = 'Source not found'(s01).
    ENDIF.
    APPEND ls_log TO gt_log.
    RETURN.
  ENDIF.

  PERFORM build_file_name USING is_obj CHANGING ls_log-file.
  PERFORM write_file USING lt_out ls_log-file CHANGING ls_log-status.
  ls_log-incl  = lv_units - 1.
  ls_log-lines = lv_lines.
  APPEND ls_log TO gt_log.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_PROGRAM - one unit (main or include) + its includes, recursive
*&---------------------------------------------------------------------*
FORM add_program USING iv_prog  TYPE progname
                       iv_depth TYPE i
                 CHANGING ct_out    TYPE ty_t_line
                          cv_units  TYPE i
                          cv_lines  TYPE i
                          cv_status TYPE string.
  DATA: lt_src   TYPE ty_t_line,
        lt_tok   TYPE ty_t_tok,
        lt_stm   TYPE ty_t_stm,
        lt_meth  TYPE ty_t_name,
        ls_tok   TYPE stokex,
        lv_name  TYPE progname,
        lv_label TYPE c LENGTH 17,
        lv_count TYPE i,
        lv_no    TYPE i,
        lv_idx   TYPE i,
        lv_next  TYPE i.

* Each include once per file, even if included from several places
  READ TABLE gt_done TRANSPORTING NO FIELDS WITH TABLE KEY table_line = iv_prog.
  IF sy-subrc = 0.
    RETURN.
  ENDIF.
  INSERT iv_prog INTO TABLE gt_done.
  INSERT iv_prog INTO TABLE gt_seen.          "sy-subrc 4 when already there - fine

  READ REPORT iv_prog INTO lt_src.
  IF sy-subrc <> 0.
    IF iv_depth = 0.
      cv_status = 'Program does not exist'(s02).
    ELSE.
      APPEND |*--- Include { iv_prog } not found ---| TO ct_out.
      APPEND INITIAL LINE TO ct_out.
    ENDIF.
    RETURN.
  ENDIF.

* Banner + numbered source
  lv_count = lines( lt_src ).
  gv_page  = gv_page + 1.
  IF iv_depth = 0 AND gv_otype <> 'INCL'.
    lv_label = 'Main program'.
  ELSE.
    lv_label = 'Include'.
  ENDIF.
  PERFORM add_banner USING lv_label iv_prog iv_depth lv_count CHANGING ct_out.
  LOOP AT lt_src INTO DATA(lv_line).
    lv_no = lv_no + 1.
    APPEND |{ lv_no WIDTH = 7 ALIGN = LEFT }{ lv_line }| TO ct_out.
  ENDLOOP.
  APPEND |*--- End of { iv_prog } - { lv_count } lines ---| TO ct_out.
  APPEND INITIAL LINE TO ct_out.
  cv_units = cv_units + 1.
  cv_lines = cv_lines + lv_count.

* Follow INCLUDE statements in source order
  SCAN ABAP-SOURCE lt_src TOKENS INTO lt_tok STATEMENTS INTO lt_stm.
  IF sy-subrc <> 0.
    APPEND |*--- Note: { iv_prog } could not be scanned, its includes are not expanded ---| TO ct_out.
    APPEND INITIAL LINE TO ct_out.
    RETURN.
  ENDIF.

  lv_next = iv_depth + 1.
  LOOP AT lt_stm INTO DATA(ls_stm).
    READ TABLE lt_tok INTO ls_tok INDEX ls_stm-from.
    IF sy-subrc <> 0 OR ls_tok-str <> 'INCLUDE' OR ls_stm-to <= ls_stm-from.
      CONTINUE.
    ENDIF.
    lv_idx = ls_stm-from + 1.
    READ TABLE lt_tok INTO ls_tok INDEX lv_idx.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    lv_name = ls_tok-str.
    TRANSLATE lv_name TO UPPER CASE.
    CASE lv_name.
      WHEN 'STRUCTURE' OR 'TYPE'.           "INCLUDE STRUCTURE / INCLUDE TYPE in a declaration
        CONTINUE.
      WHEN 'METHODS'.                       "class pool: every method implementation include
        PERFORM method_includes USING iv_prog CHANGING lt_meth.
        LOOP AT lt_meth INTO DATA(lv_meth).
          PERFORM add_program USING lv_meth lv_next
                              CHANGING ct_out cv_units cv_lines cv_status.
        ENDLOOP.
        CONTINUE.
    ENDCASE.
    IF lv_name(1) = '<' OR lv_name(1) = '%'.  "system / generated includes: not downloaded
      CONTINUE.
    ENDIF.
    PERFORM add_program USING lv_name lv_next
                        CHANGING ct_out cv_units cv_lines cv_status.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form METHOD_INCLUDES - CM### includes of the class behind a class pool
*&---------------------------------------------------------------------*
FORM method_includes USING iv_pool TYPE progname CHANGING ct_inc TYPE ty_t_name.
  DATA lv_cls TYPE seoclsname.

  CLEAR ct_inc.
  lv_cls = iv_pool(30).
  TRANSLATE lv_cls USING '= '.
* ASSUMPTION: CL_OO_CLASSNAME_SERVICE=>GET_ALL_METHOD_INCLUDES returns
* SEOP_METHODS_W_INCLUDE with component INCNAME (as used by abapGit).
  DATA(lt_meth) = cl_oo_classname_service=>get_all_method_includes( clsname = lv_cls ).
  LOOP AT lt_meth INTO DATA(ls_meth).
    APPEND ls_meth-incname TO ct_inc.
  ENDLOOP.
  SORT ct_inc.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_DDL_SOURCE - one CDS DDL source, same banner layout
*&---------------------------------------------------------------------*
FORM add_ddl_source USING iv_name TYPE sobj_name
                    CHANGING ct_out    TYPE ty_t_line
                             cv_units  TYPE i
                             cv_lines  TYPE i
                             cv_status TYPE string.
  DATA: lv_ddl    TYPE ddlname,
        lv_source TYPE string,
        lt_src    TYPE ty_t_line,
        lv_label  TYPE c LENGTH 17,
        lv_count  TYPE i,
        lv_no     TYPE i.

  lv_ddl = iv_name.
* ASSUMPTION: DDDDLSRC keyed DDLNAME / AS4LOCAL ('A' = active), source in column SOURCE.
  SELECT SINGLE source
    FROM ddddlsrc
    WHERE ddlname  = @lv_ddl
      AND as4local = 'A'
    INTO @lv_source.
  IF sy-subrc <> 0.
    cv_status = 'DDL source does not exist (active)'(s03).
    RETURN.
  ENDIF.

  REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_source
    WITH cl_abap_char_utilities=>newline.
  SPLIT lv_source AT cl_abap_char_utilities=>newline INTO TABLE lt_src.
  lv_count = lines( lt_src ).
  gv_page  = gv_page + 1.
  lv_label = 'DDL source'.
  PERFORM add_banner USING lv_label iv_name 0 lv_count CHANGING ct_out.
  LOOP AT lt_src INTO DATA(lv_line).
    lv_no = lv_no + 1.
    APPEND |{ lv_no WIDTH = 7 ALIGN = LEFT }{ lv_line }| TO ct_out.
  ENDLOOP.
  APPEND |*--- End of { iv_name } - { lv_count } lines ---| TO ct_out.
  APPEND INITIAL LINE TO ct_out.
  cv_units = 1.
  cv_lines = lv_count.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_BANNER - the 5-line header of every unit
*&---------------------------------------------------------------------*
FORM add_banner USING iv_label TYPE clike
                      iv_name  TYPE clike
                      iv_level TYPE i
                      iv_count TYPE i
                CHANGING ct_out TYPE ty_t_line.
  APPEND gv_rule TO ct_out.
  APPEND |{ iv_label WIDTH = 17 }{ iv_name WIDTH = 42 }Level { iv_level }    Page { gv_page }| TO ct_out.
  APPEND |{ 'Object' WIDTH = 17 }{ gv_main WIDTH = 42 }Lines { iv_count }| TO ct_out.
  APPEND |{ 'System' WIDTH = 17 }{ sy-sysid } / { sy-mandt }   User { sy-uname }   { gv_stamp }| TO ct_out.
  APPEND gv_rule TO ct_out.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_FILE_NAME - <folder><name>.<ext>, namespace '/' -> '#'
*&---------------------------------------------------------------------*
FORM build_file_name USING is_obj TYPE ty_obj CHANGING cv_file TYPE string.
  DATA: lv_dir  TYPE string,
        lv_sep  TYPE c LENGTH 1,
        lv_name TYPE string,
        lv_ext  TYPE string,
        lv_last TYPE i.

  IF p_front = abap_true.
    lv_dir = p_fdir.
  ELSE.
    lv_dir = p_adir.
  ENDIF.
  IF lv_dir CA '/'.
    lv_sep = '/'.
  ELSE.
    lv_sep = '\'.
  ENDIF.
  lv_last = strlen( lv_dir ) - 1.
  IF lv_dir+lv_last(1) <> lv_sep.
    lv_dir = lv_dir && lv_sep.
  ENDIF.

  IF is_obj-otype = 'FUGR'.
    lv_name = is_obj-main.                    "SAPL<group>
  ELSE.
    lv_name = is_obj-name.
  ENDIF.
  REPLACE ALL OCCURRENCES OF '/' IN lv_name WITH '#'.
  IF is_obj-otype = 'DDLS'.
    lv_ext = 'ddls.asddls'.
  ELSE.
    lv_ext = p_ext.
  ENDIF.
  cv_file = lv_dir && lv_name && '.' && lv_ext.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form WRITE_FILE - PC (GUI_DOWNLOAD, UTF-8) or application server
*&---------------------------------------------------------------------*
FORM write_file USING it_out  TYPE ty_t_line
                      iv_file TYPE string
                CHANGING cv_status TYPE string.
  DATA: lt_data TYPE ty_t_line,
        lv_msg  TYPE string.

  IF p_front = abap_true.
    lt_data = it_out.
    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename         = iv_file
        filetype         = 'ASC'
        codepage         = '4110'
      CHANGING
        data_tab         = lt_data
      EXCEPTIONS
        file_write_error = 1
        no_authority     = 2
        access_denied    = 3
        disk_full        = 4
        error_no_gui     = 5
        OTHERS           = 6.
    CASE sy-subrc.
      WHEN 0.
        cv_status = 'Downloaded'(s04).
      WHEN 1.
        cv_status = 'File write error'(e01).
      WHEN 2 OR 3.
        cv_status = 'No authority / access denied'(e02).
      WHEN 4.
        cv_status = 'Disk full'(e03).
      WHEN 5.
        cv_status = 'No SAP GUI - use the application server option'(e04).
      WHEN OTHERS.
        cv_status = |Download failed (rc { sy-subrc })|.
    ENDCASE.
    RETURN.
  ENDIF.

  TRY.
      OPEN DATASET iv_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8 MESSAGE lv_msg.
      IF sy-subrc <> 0.
        cv_status = |Cannot open file: { lv_msg }|.
        RETURN.
      ENDIF.
      LOOP AT it_out INTO DATA(lv_line).
        TRANSFER lv_line TO iv_file.
      ENDLOOP.
      CLOSE DATASET iv_file.
      cv_status = 'Written on application server'(s05).
    CATCH cx_sy_file_access_error INTO DATA(lx_file).
      cv_status = lx_file->get_text( ).
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_LOG - one line per object
*&---------------------------------------------------------------------*
FORM show_log.
  DATA: lv_ok    TYPE i,
        lv_total TYPE i.

  WRITE: / 'Type'(h01), 7 'Object'(h02), 50 'Includes'(h03), 62 'Lines'(h04),
         75 'Status'(h05), 120 'File'(h06).
  ULINE.
  LOOP AT gt_log INTO DATA(ls_log).
    WRITE: / ls_log-otype, 7 ls_log-name, 50 ls_log-incl, 62 ls_log-lines,
           75 ls_log-status, 120 ls_log-file.
    IF ls_log-status = 'Downloaded'(s04)
       OR ls_log-status = 'Written on application server'(s05).
      lv_ok = lv_ok + 1.
    ENDIF.
  ENDLOOP.
  ULINE.
  lv_total = lines( gt_log ).
  WRITE: / lv_ok, 'of'(h07), lv_total, 'object(s) downloaded'(h08).
ENDFORM.
