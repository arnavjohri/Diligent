METHOD update_amount.
*BOC By Arnav on 30/09/26
*    DATA(ls_bseg) = VALUE #( t_bseg[ 1 ] OPTIONAL ).
*
*    IF ls_bseg IS NOT INITIAL.
*      DATA : lv_obj TYPE awkey,
*             lv_gl  TYPE bseg-saknr.
*
*      lv_obj =  ls_bseg-belnr && ls_bseg-bukrs && ls_bseg-gjahr .
*
*      SELECT SINGLE enduser,fileid,invoiceid  FROM zinv_i_gl_valid
*        WHERE objkey = @lv_obj
*        INTO @DATA(ls_glvalid).
*      IF sy-subrc EQ 0.
*        SELECT * FROM zinv_post_gl
*          WHERE enduser = @ls_glvalid-enduser
*          AND fileid = @ls_glvalid-fileid
*          AND documentid = @ls_glvalid-invoiceid
*          INTO TABLE @DATA(lt_glpost).
*        IF sy-subrc EQ 0.
*          LOOP AT lt_glpost INTO DATA(ls_post).
*            lv_gl = CONV #( ls_post-glaccount ).
*            IF ls_post-amt_doc_curr IS NOT INITIAL AND ls_post-amt_loc_curr IS NOT INITIAL .
*              READ TABLE t_bseg ASSIGNING FIELD-SYMBOL(<fs_bseg>) WITH KEY saknr = lv_gl.
*              IF sy-subrc EQ 0.
*                <fs_bseg>-dmbtr = ls_post-amt_loc_curr.
*                <fs_bseg>-wrbtr = ls_post-amt_doc_curr.
*                IF ls_post-amt_gp_curr IS NOT INITIAL.
*                  <fs_bseg>-dmbe2  = ls_post-amt_gp_curr.
*                ENDIF.
*              ELSE.
*                READ TABLE t_bseg ASSIGNING <fs_bseg> WITH KEY hkont = lv_gl.
*                IF sy-subrc EQ 0.
*                  <fs_bseg>-dmbtr = ls_post-amt_loc_curr.
*                  <fs_bseg>-wrbtr = ls_post-amt_doc_curr.
*                  IF ls_post-amt_gp_curr IS NOT INITIAL.
*                    <fs_bseg>-dmbe2  = ls_post-amt_gp_curr.
*                  ENDIF.
*                ENDIF.
*              ENDIF.
*            ENDIF.
*
*          ENDLOOP.
*        ENDIF.
*      ENDIF.
*
*    ENDIF.
*
* Puts the Excel amounts (ZINV_POST_GL) back on the line items of a journal
* entry from the GL mass-upload tile when it is finally posted. Needed because
* editing the parked document after a rejection re-derives local and group
* amounts from TCURR.
* Works per G/L account, not per line: FI summarization merges Excel lines
* (e.g. two lines of 100 on one G/L post as one line of 200), so the Excel
* lines and the line items are not 1:1.
*    TYPES: BEGIN OF lty_sum,
*             gl      TYPE bseg-saknr,
*             doc     TYPE bseg-wrbtr,
*             loc     TYPE bseg-dmbtr,
*             gp      TYPE bseg-dmbe2,
*             loc_all TYPE abap_bool,
*             gp_all  TYPE abap_bool,
*           END OF lty_sum.

*    DATA: lv_obj      TYPE awkey,
*          lv_gl       TYPE bseg-saknr,
*          lt_sum      TYPE SORTED TABLE OF lty_sum WITH UNIQUE KEY gl,
*          lv_bseg_doc TYPE bseg-wrbtr,
*          lv_lines    TYPE i,
*          lv_count    TYPE i,
*          lv_loc      TYPE bseg-dmbtr,
*          lv_gp       TYPE bseg-dmbe2,
*          lv_left_loc TYPE bseg-dmbtr,
*          lv_left_gp  TYPE bseg-dmbe2,
*          lv_set_gp   TYPE abap_bool,
*          lv_bal_loc  TYPE bseg-dmbtr,
*          lv_bal_gp   TYPE bseg-dmbe2.

*    DATA(ls_bseg) = VALUE #( t_bseg[ 1 ] OPTIONAL ).
*    IF ls_bseg IS INITIAL.
*      RETURN.
*    ENDIF.

*    lv_obj = ls_bseg-belnr && ls_bseg-bukrs && ls_bseg-gjahr.

*    SELECT SINGLE fileid, invoiceid FROM zinv_i_gl_valid
*      WHERE objkey = @lv_obj
*      INTO @DATA(ls_glvalid).
*    IF sy-subrc <> 0.
*      RETURN.                 "not a document from the GL upload tile
*    ENDIF.

* ASSUMPTION: FILEID is a UUID (EARLYNUMBERING_CREATE), so FILEID + DOCUMENTID
* identify the lines on their own. ENDUSER is no longer in the WHERE: the
* upload table keeps the file creator, ZINV_GL_VALID the user who saved it.
*    SELECT glaccount, amt_doc_curr, amt_loc_curr, amt_gp_curr FROM zinv_post_gl
*      WHERE fileid     = @ls_glvalid-fileid
*        AND documentid = @ls_glvalid-invoiceid
*      INTO TABLE @DATA(lt_glpost).
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.

* Step 1: Excel totals per G/L account
* ASSUMPTION: Excel amounts are unsigned, like WRBTR / DMBTR / DMBE2 in BSEG.
*    LOOP AT lt_glpost INTO DATA(ls_post).
*     Excel gives 54182010, the line item holds 0054182010
*      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*        EXPORTING
*          input  = ls_post-glaccount
*        IMPORTING
*          output = lv_gl.

*      READ TABLE lt_sum ASSIGNING FIELD-SYMBOL(<ls_sum>)
*           WITH TABLE KEY gl = lv_gl.
*      IF sy-subrc <> 0.
*        INSERT VALUE #( gl = lv_gl loc_all = abap_true gp_all = abap_true )
*               INTO TABLE lt_sum ASSIGNING <ls_sum>.
*      ENDIF.

*      <ls_sum>-doc = <ls_sum>-doc + ls_post-amt_doc_curr.
*      IF ls_post-amt_loc_curr IS INITIAL.
*        <ls_sum>-loc_all = abap_false.     "a line without local amount
*      ELSE.
*        <ls_sum>-loc = <ls_sum>-loc + ls_post-amt_loc_curr.
*      ENDIF.
*      IF ls_post-amt_gp_curr IS INITIAL.
*        <ls_sum>-gp_all = abap_false.      "a line without group amount
*      ELSE.
*        <ls_sum>-gp = <ls_sum>-gp + ls_post-amt_gp_curr.
*      ENDIF.
*    ENDLOOP.

* Step 2: spread each G/L total over that G/L's line items, on a copy
*    DATA(lt_new) = t_bseg.

*    LOOP AT lt_sum ASSIGNING <ls_sum>.
*      IF <ls_sum>-doc IS INITIAL.
*        CONTINUE.
*      ENDIF.

* ASSUMPTION: files saved before the behaviour pool fix (amt_gp_curr mapped
* from amtloccurr) carry the LOCAL amount in AMT_GP_CURR. Group equal to local
* while the document amount differs is that bug, not a group amount, so SAP's
* DMBE2 is kept for that G/L instead of writing a local amount into it.
*      lv_set_gp = <ls_sum>-gp_all.
*      IF <ls_sum>-gp = <ls_sum>-loc AND <ls_sum>-gp <> <ls_sum>-doc.
*        lv_set_gp = abap_false.
*      ENDIF.
*      IF <ls_sum>-loc_all = abap_false AND lv_set_gp = abap_false.
*        CONTINUE.             "no Excel local / group amount for this G/L
*      ENDIF.

*     The line items must carry the same document amount as the Excel lines,
*     otherwise the Excel cannot be mapped onto them: change nothing at all.
*      CLEAR: lv_bseg_doc, lv_lines.
*      LOOP AT lt_new INTO DATA(ls_new)
*           WHERE saknr = <ls_sum>-gl OR hkont = <ls_sum>-gl.
*        lv_bseg_doc = lv_bseg_doc + ls_new-wrbtr.
*        lv_lines    = lv_lines + 1.
*      ENDLOOP.
*      IF lv_lines = 0 OR lv_bseg_doc <> <ls_sum>-doc.
*        RETURN.
*      ENDIF.

*     Share by document amount; the last line item takes the rounding
*     remainder, so the G/L total equals the Excel total to the cent.
*      lv_left_loc = <ls_sum>-loc.
*      lv_left_gp  = <ls_sum>-gp.
*      lv_count    = 0.
*      LOOP AT lt_new ASSIGNING FIELD-SYMBOL(<fs_new>)
*           WHERE saknr = <ls_sum>-gl OR hkont = <ls_sum>-gl.
*        lv_count = lv_count + 1.
*        IF lv_count = lv_lines.
*          lv_loc = lv_left_loc.
*          lv_gp  = lv_left_gp.
*        ELSE.
*          lv_loc = <fs_new>-wrbtr * <ls_sum>-loc / <ls_sum>-doc.
*          lv_gp  = <fs_new>-wrbtr * <ls_sum>-gp / <ls_sum>-doc.
*        ENDIF.
*        lv_left_loc = lv_left_loc - lv_loc.
*        lv_left_gp  = lv_left_gp - lv_gp.

*        IF <ls_sum>-loc_all = abap_true.
*          <fs_new>-dmbtr = lv_loc.
*        ENDIF.
*        IF lv_set_gp = abap_true.
*          <fs_new>-dmbe2 = lv_gp.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.

* Step 3: take the copy only if the document still balances in local and
* group currency. No MESSAGE here - this runs inside the posting (often as
* WF-BATCH), where an E message would cancel the posting itself.
*    LOOP AT lt_new INTO ls_new.
*      IF ls_new-shkzg = 'H'.
*        lv_bal_loc = lv_bal_loc - ls_new-dmbtr.
*        lv_bal_gp  = lv_bal_gp - ls_new-dmbe2.
*      ELSE.
*        lv_bal_loc = lv_bal_loc + ls_new-dmbtr.
*        lv_bal_gp  = lv_bal_gp + ls_new-dmbe2.
*      ENDIF.
*    ENDLOOP.
*    IF lv_bal_loc <> 0 OR lv_bal_gp <> 0.
*      RETURN.
*    ENDIF.

* Row by row: T_BSEG cannot be assigned as a whole (activation error 30/09/26)
*    LOOP AT t_bseg ASSIGNING FIELD-SYMBOL(<fs_bseg>).
*      READ TABLE lt_new INTO ls_new INDEX sy-tabix.
*      IF sy-subrc = 0.
*        <fs_bseg>-dmbtr = ls_new-dmbtr.
*        <fs_bseg>-dmbe2 = ls_new-dmbe2.
*      ENDIF.
*    ENDLOOP.
*EOC By Arnav on 30/09/26
*BOC By Arnav on 14/10/26
* Puts the Excel amounts (ZINV_POST_GL) back on the line items of a journal
* entry from the GL mass-upload tile when it is finally posted. Needed because
* editing the parked document after a rejection re-derives local and group
* amounts from TCURR.
*
* How line items relate to Excel lines: ZCL_INV_UTILITY merges Excel lines
* with the same G/L, cost object (cost centre / profit centre / WBS),
* assignment and item text into ONE item, netting debit and credit, and OBCY
* summarisation may merge further. So one line item carries one or more Excel
* lines and its Excel local / group amount is the sum over those lines.
* The code below finds, per G/L account, which Excel lines sit behind which
* line item: the document amounts must add up exactly, and the cost object /
* assignment / text of an Excel line must match the line item where SAP
* carries them. Exactly one distribution fits -> it is taken, amounts as
* entered (sums where lines were merged). None fits (document amounts no
* longer match the Excel) or several fit with different results -> nothing
* is changed. Every outcome for a tile document is written to the
* application log: SLG1, object blank, external ID = company code,
* document number, fiscal year.
*
* Never written: the local amount when document currency = local currency,
* the group amount when there is no second local currency or it equals the
* document or local currency. SAP sets those 1:1 and they cannot differ.
* No MESSAGE here: this runs inside the posting (update task), an E message
* would terminate the update and leave the document parked.
    TYPES: lty_strtab TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    TYPES: BEGIN OF lty_map,               "Excel field -> BSEG field
             zname TYPE string,            "component of ZINV_POST_GL
             bname TYPE string,            "component of BSEG
             alpha TYPE abap_bool,         "numeric value needs leading zeros
             hard  TYPE abap_bool,         "still compared at fallback level 2
           END OF lty_map.

    TYPES: BEGIN OF lty_xl,                "one Excel line in BSEG format
             gl   TYPE bseg-hkont,
             sdoc TYPE bseg-wrbtr,         "signed: debit +, credit -
             sloc TYPE bseg-dmbtr,
             sgp  TYPE bseg-dmbe2,
             keys TYPE lty_strtab,         "one entry per lt_map row
             sig  TYPE string,             "identical lines are interchangeable
             bidx TYPE i,                  "line item chosen (index in lt_li)
           END OF lty_xl.

    TYPES: BEGIN OF lty_li,                "one line item of T_BSEG
             gl    TYPE bseg-hkont,
             tabix TYPE i,                 "index in T_BSEG
             sdoc  TYPE bseg-wrbtr,        "signed WRBTR
             cap   TYPE bseg-wrbtr,        "still to be covered by Excel lines
             rloc  TYPE bseg-dmbtr,        "Excel local sum of the current fit
             rgp   TYPE bseg-dmbe2,
             floc  TYPE bseg-dmbtr,        "Excel local sum of the first fit
             fgp   TYPE bseg-dmbe2,
             keys  TYPE lty_strtab,
           END OF lty_li.

    DATA: lt_map         TYPE STANDARD TABLE OF lty_map,
          ls_map         TYPE lty_map,
          lt_xl_all      TYPE STANDARD TABLE OF lty_xl,
          lt_xl          TYPE STANDARD TABLE OF lty_xl,
          ls_xl          TYPE lty_xl,
          lt_li_all      TYPE STANDARD TABLE OF lty_li,
          lt_li          TYPE STANDARD TABLE OF lty_li,
          ls_li          TYPE lty_li,
          lt_new         TYPE bseg_t,
          ls_new         TYPE bseg,
          lt_gl          TYPE STANDARD TABLE OF bseg-hkont,
          lv_gl          TYPE bseg-hkont,
          lt_xl_has      TYPE STANDARD TABLE OF abap_bool, "Excel fills field k
          lt_li_has      TYPE STANDARD TABLE OF abap_bool, "line items carry k
          lt_use         TYPE STANDARD TABLE OF abap_bool, "field k usable
          lt_use_lvl     TYPE STANDARD TABLE OF abap_bool, "compared this level
          lt_use_prev    TYPE STANDARD TABLE OF abap_bool,
          lv_use         TYPE abap_bool,
          lv_use2        TYPE abap_bool,
          lv_obj         TYPE awkey,
          lv_tabix       TYPE i,
          lv_dc_known    TYPE abap_bool,
          lv_loc_missing TYPE abap_bool,
          lv_gp_missing  TYPE abap_bool,
          lv_gp_eq_loc   TYPE abap_bool,
          lv_set_loc     TYPE abap_bool,
          lv_set_gp      TYPE abap_bool,
          lv_s           TYPE string,
          lv_s2          TYPE string,
          lv_c100        TYPE char100,
          lv_c10         TYPE char10,
          lv_k           TYPE i,
          lv_level       TYPE i,
          lv_state       TYPE char1,       "S fit, F no fit, A ambiguous, L limit
          lv_reason      TYPE string,
          lv_i           TYPE i,
          lv_prev        TYPE i,
          lv_j           TYPE i,
          lv_n           TYPE i,
          lv_m           TYPE i,
          lv_nodes       TYPE i,
          lv_nsol        TYPE i,
          lv_p_rem       TYPE bseg-wrbtr,  "positive Excel amounts still open
          lv_n_rem       TYPE bseg-wrbtr,  "negative Excel amounts still open
          lv_p2          TYPE bseg-wrbtr,
          lv_n2          TYPE bseg-wrbtr,
          lv_cap         TYPE bseg-wrbtr,
          lv_sum_xl      TYPE bseg-wrbtr,
          lv_sum_li      TYPE bseg-wrbtr,
          lv_found       TYPE abap_bool,
          lv_fits        TYPE abap_bool,
          lv_bal_loc     TYPE bseg-dmbtr,
          lv_bal_gp      TYPE bseg-dmbe2,
          lv_cnt_loc     TYPE i,
          lv_cnt_gp      TYPE i,
          lv_fields      TYPE string,
          lv_msgty       TYPE symsgty,
          lv_text        TYPE char200,
          lt_text        TYPE STANDARD TABLE OF char200,
          ls_log         TYPE bal_s_log,
          lv_handle      TYPE balloghndl,
          lt_handle      TYPE bal_t_logh.

    FIELD-SYMBOLS: <lv_val>  TYPE any,
                   <lv_has>  TYPE abap_bool,
                   <ls_xl>   TYPE lty_xl,
                   <ls_prev> TYPE lty_xl,
                   <ls_li>   TYPE lty_li,
                   <ls_new>  TYPE bseg.

    DATA(ls_bseg) = VALUE #( t_bseg[ 1 ] OPTIONAL ).
    IF ls_bseg IS INITIAL.
      RETURN.
    ENDIF.

    lv_obj = ls_bseg-belnr && ls_bseg-bukrs && ls_bseg-gjahr.

    SELECT SINGLE fileid, invoiceid FROM zinv_i_gl_valid
      WHERE objkey = @lv_obj
      INTO @DATA(ls_glvalid).
    IF sy-subrc <> 0.
      RETURN.                 "not a document from the GL upload tile
    ENDIF.

    lv_msgty = 'E'.           "until the amounts are actually written

* DO 1 TIMES: every EXIT below ends the restore and falls through to the
* application log at the end of the method.
    DO 1 TIMES.

* ASSUMPTION: FILEID is a UUID (EARLYNUMBERING_CREATE), so FILEID + DOCUMENTID
* identify the lines on their own. ENDUSER is not in the WHERE: the upload
* table keeps the file creator, ZINV_GL_VALID the user who saved it.
      SELECT * FROM zinv_post_gl
        WHERE fileid     = @ls_glvalid-fileid
          AND documentid = @ls_glvalid-invoiceid
        INTO TABLE @DATA(lt_post).
      IF sy-subrc <> 0.
        lv_text = |Not restored: no Excel lines in ZINV_POST_GL for file | &&
                  |{ ls_glvalid-fileid } document { ls_glvalid-invoiceid }|.
        APPEND lv_text TO lt_text.
        EXIT.
      ENDIF.

*     Currencies of the document being posted. The parked document has its
*     BKPF row (BSTAT = 'V'); nothing of this LUW is written yet.
      SELECT SINGLE waers, hwaer, hwae2 FROM bkpf
        WHERE bukrs = @ls_bseg-bukrs
          AND belnr = @ls_bseg-belnr
          AND gjahr = @ls_bseg-gjahr
        INTO @DATA(ls_bkpf).
      IF sy-subrc <> 0.
        lv_text = 'Not restored: BKPF header of the parked document not found'.
        APPEND lv_text TO lt_text.
        EXIT.
      ENDIF.

*     Excel fields that SAP carries on the line item. A name missing in
*     ZINV_POST_GL is simply not used (ASSIGN COMPONENT fails, no dump).
*     Order matters: KEYS of Excel lines and line items are positional.
      lt_map = VALUE #( ( zname = 'COSTCENTER'   bname = 'KOSTL' alpha = abap_true hard = abap_true )
                        ( zname = 'WBSELEMENT'   bname = 'PROJK' hard = abap_true )
                        ( zname = 'PROFITCENT'   bname = 'PRCTR' alpha = abap_true )
                        ( zname = 'GLASSIGNMENT' bname = 'ZUONR' )
                        ( zname = 'GLITMTXT'     bname = 'SGTXT' ) ).
      lv_n = lines( lt_map ).
      DO lv_n TIMES.
        APPEND abap_false TO: lt_xl_has, lt_li_has, lt_use.
      ENDDO.

* Step 1: Excel lines in BSEG format
* ASSUMPTION: Excel amounts are unsigned, like WRBTR / DMBTR / DMBE2 in BSEG;
* DEB_CRE ('S' / 'H') gives the side. When the table has no DEB_CRE, lines
* and items are matched unsigned, which is exact unless debit and credit
* lines were netted into one item.
      lv_gp_eq_loc = abap_true.
      LOOP AT lt_post ASSIGNING FIELD-SYMBOL(<ls_post>).
        IF <ls_post>-amt_doc_curr IS INITIAL.
          CONTINUE.             "nothing to match a line item by
        ENDIF.
        CLEAR ls_xl.
*       Excel gives 54182010, the line item holds 0054182010
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = <ls_post>-glaccount
          IMPORTING
            output = ls_xl-gl.
        ls_xl-sdoc = <ls_post>-amt_doc_curr.
        ls_xl-sloc = <ls_post>-amt_loc_curr.
        ls_xl-sgp  = <ls_post>-amt_gp_curr.
        IF ls_xl-sloc IS INITIAL.
          lv_loc_missing = abap_true.
        ENDIF.
        IF ls_xl-sgp IS INITIAL.
          lv_gp_missing = abap_true.
        ENDIF.
        IF ls_xl-sgp <> ls_xl-sloc.
          lv_gp_eq_loc = abap_false.
        ENDIF.
        ASSIGN COMPONENT 'DEB_CRE' OF STRUCTURE <ls_post> TO <lv_val>.
        IF sy-subrc = 0.
          lv_dc_known = abap_true.
          IF <lv_val> = 'H'.
            ls_xl-sdoc = ls_xl-sdoc * -1.
            ls_xl-sloc = ls_xl-sloc * -1.
            ls_xl-sgp  = ls_xl-sgp  * -1.
          ENDIF.
        ENDIF.
*       Key fields, normalised to how BSEG carries them
        lv_k = 0.
        LOOP AT lt_map INTO ls_map.
          lv_k = lv_k + 1.
          CLEAR lv_s.
          ASSIGN COMPONENT ls_map-zname OF STRUCTURE <ls_post> TO <lv_val>.
          IF sy-subrc = 0 AND <lv_val> IS NOT INITIAL.
            lv_c100 = <lv_val>.
            IF ls_map-alpha = abap_true.
              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = lv_c100
                IMPORTING
                  output = lv_c10.
              lv_c100 = lv_c10.
            ENDIF.
            lv_s = lv_c100.
            lv_s = to_upper( condense( lv_s ) ).
            IF ls_map-bname = 'PROJK'.
*             WBS: compare letters and digits only, the edit mask differs
              REPLACE ALL OCCURRENCES OF REGEX '[^A-Z0-9]' IN lv_s WITH ''.
            ENDIF.
            IF lv_s IS NOT INITIAL.
              READ TABLE lt_xl_has ASSIGNING <lv_has> INDEX lv_k.
              <lv_has> = abap_true.
            ENDIF.
          ENDIF.
          APPEND lv_s TO ls_xl-keys.
        ENDLOOP.
        ls_xl-sig = |{ ls_xl-gl }/{ ls_xl-sdoc }/{ ls_xl-sloc }/{ ls_xl-sgp }|.
        LOOP AT ls_xl-keys INTO lv_s.
          ls_xl-sig = |{ ls_xl-sig }/{ lv_s }|.
        ENDLOOP.
        APPEND ls_xl TO lt_xl_all.
      ENDLOOP.

      IF lt_xl_all IS INITIAL.
        lv_text = 'Not restored: the Excel lines carry no document amounts'.
        APPEND lv_text TO lt_text.
        EXIT.
      ENDIF.

      SORT lt_xl_all BY gl sig.
      LOOP AT lt_xl_all INTO ls_xl.
        APPEND ls_xl-gl TO lt_gl.
      ENDLOOP.
      SORT lt_gl.
      DELETE ADJACENT DUPLICATES FROM lt_gl.

* Step 2: line items of the Excel G/L accounts, same format
      LOOP AT t_bseg ASSIGNING FIELD-SYMBOL(<fs_bseg>).
        lv_tabix = sy-tabix.
        READ TABLE lt_gl TRANSPORTING NO FIELDS WITH KEY table_line = <fs_bseg>-hkont.
        IF sy-subrc <> 0.
          CONTINUE.             "G/L the Excel does not have (tax etc.): stays
        ENDIF.
        CLEAR ls_li.
        ls_li-gl    = <fs_bseg>-hkont.
        ls_li-tabix = lv_tabix.
        ls_li-sdoc  = <fs_bseg>-wrbtr.
        IF lv_dc_known = abap_true AND <fs_bseg>-shkzg = 'H'.
          ls_li-sdoc = ls_li-sdoc * -1.
        ENDIF.
        lv_k = 0.
        LOOP AT lt_map INTO ls_map.
          lv_k = lv_k + 1.
          CLEAR lv_s.
          ASSIGN COMPONENT ls_map-bname OF STRUCTURE <fs_bseg> TO <lv_val>.
          IF sy-subrc = 0 AND <lv_val> IS NOT INITIAL.
            IF ls_map-bname = 'PROJK'.
*             internal WBS number -> external ID, as the Excel has it
              CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
                EXPORTING
                  input  = <lv_val>
                IMPORTING
                  output = lv_c100.
            ELSE.
              lv_c100 = <lv_val>.
            ENDIF.
            lv_s = lv_c100.
            lv_s = to_upper( condense( lv_s ) ).
            IF ls_map-bname = 'PROJK'.
              REPLACE ALL OCCURRENCES OF REGEX '[^A-Z0-9]' IN lv_s WITH ''.
            ENDIF.
            IF lv_s IS NOT INITIAL.
              READ TABLE lt_li_has ASSIGNING <lv_has> INDEX lv_k.
              <lv_has> = abap_true.
            ENDIF.
          ENDIF.
          APPEND lv_s TO ls_li-keys.
        ENDLOOP.
        APPEND ls_li TO lt_li_all.
      ENDLOOP.

*     A field is compared only when the Excel fills it somewhere AND the line
*     items carry it somewhere. Blank on every line item while the Excel has
*     it = cleared by OBCY summarisation (or dropped by the upload): ignored.
*     That follows a Customizing change without any code change.
      lv_k = 0.
      LOOP AT lt_map INTO ls_map.
        lv_k = lv_k + 1.
        READ TABLE lt_xl_has INTO lv_use  INDEX lv_k.
        READ TABLE lt_li_has INTO lv_use2 INDEX lv_k.
        IF lv_use = abap_true AND lv_use2 = abap_true.
          READ TABLE lt_use ASSIGNING <lv_has> INDEX lv_k.
          <lv_has> = abap_true.
          lv_fields = |{ lv_fields }{ ls_map-bname } |.
        ENDIF.
      ENDLOOP.

* Step 3: what may be written at all
      IF ls_bkpf-waers <> ls_bkpf-hwaer AND lv_loc_missing = abap_false.
        lv_set_loc = abap_true.
      ENDIF.
* ASSUMPTION: files saved before the behaviour pool fix of 29/09/26 carry the
* LOCAL amount in AMT_GP_CURR on every line. Group equal to local on every
* line is that bug, not a group amount (PHP and USD never coincide), so the
* group amount SAP derived stays for such a file.
      IF ls_bkpf-hwae2 IS NOT INITIAL AND ls_bkpf-hwae2 <> ls_bkpf-waers AND
         ls_bkpf-hwae2 <> ls_bkpf-hwaer AND lv_gp_missing = abap_false AND
         lv_gp_eq_loc = abap_false.
        lv_set_gp = abap_true.
      ENDIF.
      IF lv_set_loc = abap_false AND lv_set_gp = abap_false.
        lv_msgty = 'I'.
        lv_text = |Nothing to restore: document { ls_bkpf-waers }, local { ls_bkpf-hwaer }, | &&
                  |group { ls_bkpf-hwae2 }; local missing { lv_loc_missing }, | &&
                  |group missing { lv_gp_missing }, group = local { lv_gp_eq_loc }|.
        APPEND lv_text TO lt_text.
        EXIT.
      ENDIF.

* Step 4: per G/L account, find the Excel lines behind each line item.
* Level 1 compares every usable key field, level 2 only cost centre and WBS
* (profit centre, assignment and text can be derived or changed by SAP),
* level 3 amounts only. A level is retried only when no fit was found.
      lv_level = 0.
      WHILE lv_level < 3.
        lv_level = lv_level + 1.
        lt_use_prev = lt_use_lvl.
        CLEAR lt_use_lvl.
        lv_k = 0.
        LOOP AT lt_map INTO ls_map.
          lv_k = lv_k + 1.
          READ TABLE lt_use INTO lv_use INDEX lv_k.
          IF lv_level = 3 OR ( lv_level = 2 AND ls_map-hard = abap_false ).
            lv_use = abap_false.
          ENDIF.
          APPEND lv_use TO lt_use_lvl.
        ENDLOOP.
        IF lv_level > 1 AND lt_use_lvl = lt_use_prev.
          CONTINUE.             "same constraints as before, same result
        ENDIF.

        lt_new   = t_bseg.
        lv_state = 'S'.
        CLEAR: lv_cnt_loc, lv_cnt_gp.

        LOOP AT lt_gl INTO lv_gl.
          CLEAR: lt_xl, lt_li, lv_sum_xl, lv_sum_li, lv_p_rem, lv_n_rem.
          LOOP AT lt_xl_all INTO ls_xl WHERE gl = lv_gl.
            CLEAR ls_xl-bidx.
            APPEND ls_xl TO lt_xl.
            lv_sum_xl = lv_sum_xl + ls_xl-sdoc.
            IF ls_xl-sdoc > 0.
              lv_p_rem = lv_p_rem + ls_xl-sdoc.
            ELSE.
              lv_n_rem = lv_n_rem - ls_xl-sdoc.
            ENDIF.
          ENDLOOP.
          LOOP AT lt_li_all INTO ls_li WHERE gl = lv_gl.
            ls_li-cap = ls_li-sdoc.
            CLEAR: ls_li-rloc, ls_li-rgp, ls_li-floc, ls_li-fgp.
            APPEND ls_li TO lt_li.
            lv_sum_li = lv_sum_li + ls_li-sdoc.
          ENDLOOP.
          lv_n = lines( lt_xl ).
          lv_m = lines( lt_li ).
          IF lv_m = 0 OR lv_sum_xl <> lv_sum_li.
            lv_state  = 'F'.
            lv_reason = |G/L { lv_gl }: Excel document amount { lv_sum_xl } | &&
                        |vs { lv_m } line items { lv_sum_li }|.
            EXIT.
          ENDIF.

*         Backtracking over the Excel lines of this G/L: line i goes to line
*         item j when its key fields fit and every line item can still be
*         covered by the Excel lines not yet placed. A complete fit gives the
*         Excel local / group sum per line item; a second fit with different
*         sums means the Excel cannot be mapped unambiguously.
          lv_i    = 1.
          lv_nsol = 0.
          WHILE lv_i >= 1.
            lv_nodes = lv_nodes + 1.
            IF lv_nodes > 200000.
              lv_state  = 'L'.
              lv_reason = |G/L { lv_gl }: search limit reached ({ lv_n } Excel lines, { lv_m } line items)|.
              EXIT.
            ENDIF.
            READ TABLE lt_xl ASSIGNING <ls_xl> INDEX lv_i.
            IF <ls_xl>-bidx > 0.
*             take back the previous choice of this line
              READ TABLE lt_li ASSIGNING <ls_li> INDEX <ls_xl>-bidx.
              <ls_li>-cap  = <ls_li>-cap  + <ls_xl>-sdoc.
              <ls_li>-rloc = <ls_li>-rloc - <ls_xl>-sloc.
              <ls_li>-rgp  = <ls_li>-rgp  - <ls_xl>-sgp.
              IF <ls_xl>-sdoc > 0.
                lv_p_rem = lv_p_rem + <ls_xl>-sdoc.
              ELSE.
                lv_n_rem = lv_n_rem - <ls_xl>-sdoc.
              ENDIF.
            ENDIF.
            lv_j = <ls_xl>-bidx + 1.
*           identical Excel lines are interchangeable: keep them in order
            IF lv_i > 1.
              lv_prev = lv_i - 1.
              READ TABLE lt_xl ASSIGNING <ls_prev> INDEX lv_prev.
              IF <ls_prev>-sig = <ls_xl>-sig AND lv_j < <ls_prev>-bidx.
                lv_j = <ls_prev>-bidx.
              ENDIF.
            ENDIF.
            lv_found = abap_false.
            WHILE lv_j <= lv_m.
              READ TABLE lt_li ASSIGNING <ls_li> INDEX lv_j.
              lv_fits = abap_true.
*             key fields: an Excel value must be found on the line item;
*             a blank Excel value fits anything (SAP may have derived it)
              lv_k = 0.
              LOOP AT lt_use_lvl INTO lv_use.
                lv_k = lv_k + 1.
                IF lv_use = abap_false.
                  CONTINUE.
                ENDIF.
                READ TABLE <ls_xl>-keys INTO lv_s INDEX lv_k.
                IF lv_s IS INITIAL.
                  CONTINUE.
                ENDIF.
                READ TABLE <ls_li>-keys INTO lv_s2 INDEX lv_k.
                IF lv_s <> lv_s2.
                  lv_fits = abap_false.
                  EXIT.
                ENDIF.
              ENDLOOP.
*             amounts: with this line placed, what every line item still
*             needs must lie between the negative and the positive Excel
*             amounts not yet placed (0 on both sides after the last line)
              IF lv_fits = abap_true.
                lv_p2 = lv_p_rem.
                lv_n2 = lv_n_rem.
                IF <ls_xl>-sdoc > 0.
                  lv_p2 = lv_p2 - <ls_xl>-sdoc.
                ELSE.
                  lv_n2 = lv_n2 + <ls_xl>-sdoc.
                ENDIF.
                LOOP AT lt_li INTO ls_li.
                  lv_cap = ls_li-cap.
                  IF sy-tabix = lv_j.
                    lv_cap = lv_cap - <ls_xl>-sdoc.
                  ENDIF.
                  IF lv_cap > lv_p2 OR lv_cap + lv_n2 < 0.
                    lv_fits = abap_false.
                    EXIT.
                  ENDIF.
                ENDLOOP.
              ENDIF.
              IF lv_fits = abap_true.
                lv_found = abap_true.
                EXIT.
              ENDIF.
              lv_j = lv_j + 1.
            ENDWHILE.

            IF lv_found = abap_true.
              READ TABLE lt_li ASSIGNING <ls_li> INDEX lv_j.
              <ls_xl>-bidx = lv_j.
              <ls_li>-cap  = <ls_li>-cap  - <ls_xl>-sdoc.
              <ls_li>-rloc = <ls_li>-rloc + <ls_xl>-sloc.
              <ls_li>-rgp  = <ls_li>-rgp  + <ls_xl>-sgp.
              IF <ls_xl>-sdoc > 0.
                lv_p_rem = lv_p_rem - <ls_xl>-sdoc.
              ELSE.
                lv_n_rem = lv_n_rem + <ls_xl>-sdoc.
              ENDIF.
              IF lv_i < lv_n.
                lv_i = lv_i + 1.
              ELSE.
*               complete fit: the amount check left every line item at 0
                IF lv_nsol = 0.
                  LOOP AT lt_li ASSIGNING <ls_li>.
                    <ls_li>-floc = <ls_li>-rloc.
                    <ls_li>-fgp  = <ls_li>-rgp.
                  ENDLOOP.
                  lv_nsol = 1.
                ELSE.
                  LOOP AT lt_li ASSIGNING <ls_li>.
                    IF ( lv_set_loc = abap_true AND <ls_li>-floc <> <ls_li>-rloc ) OR
                       ( lv_set_gp  = abap_true AND <ls_li>-fgp  <> <ls_li>-rgp ).
                      lv_state = 'A'.
                      EXIT.
                    ENDIF.
                  ENDLOOP.
                  IF lv_state = 'A'.
                    lv_reason = |G/L { lv_gl }: more than one way to spread { lv_n } Excel lines | &&
                                |over { lv_m } line items with different amounts|.
                    EXIT.
                  ENDIF.
                ENDIF.
*               stay on the last line to try its next line item
              ENDIF.
            ELSE.
              <ls_xl>-bidx = 0.
              lv_i = lv_i - 1.
            ENDIF.
          ENDWHILE.

          IF lv_state <> 'S'.
            EXIT.
          ENDIF.
          IF lv_nsol = 0.
            lv_state  = 'F'.
            lv_reason = |G/L { lv_gl }: no distribution of { lv_n } Excel lines over { lv_m } line items | &&
                        |fits (keys { lv_fields }, D/C known { lv_dc_known })|.
            EXIT.
          ENDIF.

*         take the fit into the copy
          LOOP AT lt_li INTO ls_li.
            IF ls_li-sdoc = 0.
              CONTINUE.
            ENDIF.
            READ TABLE lt_new ASSIGNING <ls_new> INDEX ls_li-tabix.
            IF lv_set_loc = abap_true.
              IF ls_li-floc = 0 OR ( ls_li-floc > 0 AND ls_li-sdoc < 0 ) OR
                 ( ls_li-floc < 0 AND ls_li-sdoc > 0 ).
                lv_state  = 'F'.
                lv_reason = |G/L { lv_gl }: Excel local amount { ls_li-floc } cannot sit on a line item | &&
                            |with document amount { ls_li-sdoc }|.
                EXIT.
              ENDIF.
              <ls_new>-dmbtr = abs( ls_li-floc ).
              lv_cnt_loc = lv_cnt_loc + 1.
            ENDIF.
            IF lv_set_gp = abap_true.
              IF ls_li-fgp = 0 OR ( ls_li-fgp > 0 AND ls_li-sdoc < 0 ) OR
                 ( ls_li-fgp < 0 AND ls_li-sdoc > 0 ).
                lv_state  = 'F'.
                lv_reason = |G/L { lv_gl }: Excel group amount { ls_li-fgp } cannot sit on a line item | &&
                            |with document amount { ls_li-sdoc }|.
                EXIT.
              ENDIF.
              <ls_new>-dmbe2 = abs( ls_li-fgp ).
              lv_cnt_gp = lv_cnt_gp + 1.
            ENDIF.
          ENDLOOP.
          IF lv_state <> 'S'.
            EXIT.
          ENDIF.
        ENDLOOP.                "lt_gl

        IF lv_state <> 'F'.
          EXIT.                 "S: done. A / L: fewer constraints cannot help
        ENDIF.
      ENDWHILE.                 "levels

      IF lv_state <> 'S'.
        lv_text = |Not restored (level { lv_level }): { lv_reason }|.
        APPEND lv_text TO lt_text.
        EXIT.
      ENDIF.

* Step 5: the restored document must still balance in local and group
      LOOP AT lt_new INTO ls_new.
        IF ls_new-shkzg = 'H'.
          lv_bal_loc = lv_bal_loc - ls_new-dmbtr.
          lv_bal_gp  = lv_bal_gp  - ls_new-dmbe2.
        ELSE.
          lv_bal_loc = lv_bal_loc + ls_new-dmbtr.
          lv_bal_gp  = lv_bal_gp  + ls_new-dmbe2.
        ENDIF.
      ENDLOOP.
      IF ( lv_set_loc = abap_true AND lv_bal_loc <> 0 ) OR
         ( lv_set_gp  = abap_true AND lv_bal_gp  <> 0 ).
        lv_text = |Not restored: Excel amounts do not balance over the whole document | &&
                  |(local { lv_bal_loc }, group { lv_bal_gp })|.
        APPEND lv_text TO lt_text.
        EXIT.
      ENDIF.

* Step 6: row by row into T_BSEG (it cannot be assigned as a whole)
      LOOP AT t_bseg ASSIGNING <fs_bseg>.
        READ TABLE lt_new INTO ls_new INDEX sy-tabix.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        IF lv_set_loc = abap_true.
          <fs_bseg>-dmbtr = ls_new-dmbtr.
          IF <fs_bseg>-pswsl = ls_bkpf-hwaer.
            <fs_bseg>-pswbt = ls_new-dmbtr.   "G/L updated in local currency only
          ENDIF.
        ENDIF.
        IF lv_set_gp = abap_true.
          <fs_bseg>-dmbe2 = ls_new-dmbe2.
        ENDIF.
      ENDLOOP.
      lv_msgty = 'S'.
      lv_text  = |Excel amounts restored: local on { lv_cnt_loc } line items, group on { lv_cnt_gp } | &&
                 |(level { lv_level }, keys { lv_fields }, D/C known { lv_dc_known })|.
      APPEND lv_text TO lt_text.
    ENDDO.

* Application log, written with the posting (same LUW). SLG1: object blank,
* external ID "<company code> <document number> <fiscal year>".
    IF lt_text IS NOT INITIAL.
      CLEAR ls_log.
      ls_log-extnumber = |{ ls_bseg-bukrs } { ls_bseg-belnr } { ls_bseg-gjahr }|.
      ls_log-aluser    = sy-uname.
      ls_log-alprog    = sy-repid.
      ls_log-altcode   = sy-tcode.
      CALL FUNCTION 'BAL_LOG_CREATE'
        EXPORTING
          i_s_log      = ls_log
        IMPORTING
          e_log_handle = lv_handle
        EXCEPTIONS
          OTHERS       = 1.
      IF sy-subrc = 0.
        LOOP AT lt_text INTO lv_text.
          CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
            EXPORTING
              i_log_handle = lv_handle
              i_msgty      = lv_msgty
              i_probclass  = '2'
              i_text       = lv_text
            EXCEPTIONS
              OTHERS       = 1.
        ENDLOOP.
        APPEND lv_handle TO lt_handle.
        CALL FUNCTION 'BAL_DB_SAVE'
          EXPORTING
            i_t_log_handle = lt_handle
          EXCEPTIONS
            OTHERS         = 1.
      ENDIF.
    ENDIF.
*EOC By Arnav on 14/10/26

  ENDMETHOD.
