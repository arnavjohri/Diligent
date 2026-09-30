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
    TYPES: BEGIN OF lty_sum,
             gl      TYPE bseg-saknr,
             doc     TYPE bseg-wrbtr,
             loc     TYPE bseg-dmbtr,
             gp      TYPE bseg-dmbe2,
             loc_all TYPE abap_bool,
             gp_all  TYPE abap_bool,
           END OF lty_sum.

    DATA: lv_obj      TYPE awkey,
          lv_gl       TYPE bseg-saknr,
          lt_sum      TYPE SORTED TABLE OF lty_sum WITH UNIQUE KEY gl,
          lv_bseg_doc TYPE bseg-wrbtr,
          lv_lines    TYPE i,
          lv_count    TYPE i,
          lv_loc      TYPE bseg-dmbtr,
          lv_gp       TYPE bseg-dmbe2,
          lv_left_loc TYPE bseg-dmbtr,
          lv_left_gp  TYPE bseg-dmbe2,
          lv_set_gp   TYPE abap_bool,
          lv_bal_loc  TYPE bseg-dmbtr,
          lv_bal_gp   TYPE bseg-dmbe2.

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

* ASSUMPTION: FILEID is a UUID (EARLYNUMBERING_CREATE), so FILEID + DOCUMENTID
* identify the lines on their own. ENDUSER is no longer in the WHERE: the
* upload table keeps the file creator, ZINV_GL_VALID the user who saved it.
    SELECT glaccount, amt_doc_curr, amt_loc_curr, amt_gp_curr FROM zinv_post_gl
      WHERE fileid     = @ls_glvalid-fileid
        AND documentid = @ls_glvalid-invoiceid
      INTO TABLE @DATA(lt_glpost).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

* Step 1: Excel totals per G/L account
* ASSUMPTION: Excel amounts are unsigned, like WRBTR / DMBTR / DMBE2 in BSEG.
    LOOP AT lt_glpost INTO DATA(ls_post).
*     Excel gives 54182010, the line item holds 0054182010
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_post-glaccount
        IMPORTING
          output = lv_gl.

      READ TABLE lt_sum ASSIGNING FIELD-SYMBOL(<ls_sum>)
           WITH TABLE KEY gl = lv_gl.
      IF sy-subrc <> 0.
        INSERT VALUE #( gl = lv_gl loc_all = abap_true gp_all = abap_true )
               INTO TABLE lt_sum ASSIGNING <ls_sum>.
      ENDIF.

      <ls_sum>-doc = <ls_sum>-doc + ls_post-amt_doc_curr.
      IF ls_post-amt_loc_curr IS INITIAL.
        <ls_sum>-loc_all = abap_false.     "a line without local amount
      ELSE.
        <ls_sum>-loc = <ls_sum>-loc + ls_post-amt_loc_curr.
      ENDIF.
      IF ls_post-amt_gp_curr IS INITIAL.
        <ls_sum>-gp_all = abap_false.      "a line without group amount
      ELSE.
        <ls_sum>-gp = <ls_sum>-gp + ls_post-amt_gp_curr.
      ENDIF.
    ENDLOOP.

* Step 2: spread each G/L total over that G/L's line items, on a copy
    DATA(lt_new) = t_bseg.

    LOOP AT lt_sum ASSIGNING <ls_sum>.
      IF <ls_sum>-doc IS INITIAL.
        CONTINUE.
      ENDIF.

* ASSUMPTION: files saved before the behaviour pool fix (amt_gp_curr mapped
* from amtloccurr) carry the LOCAL amount in AMT_GP_CURR. Group equal to local
* while the document amount differs is that bug, not a group amount, so SAP's
* DMBE2 is kept for that G/L instead of writing a local amount into it.
      lv_set_gp = <ls_sum>-gp_all.
      IF <ls_sum>-gp = <ls_sum>-loc AND <ls_sum>-gp <> <ls_sum>-doc.
        lv_set_gp = abap_false.
      ENDIF.
      IF <ls_sum>-loc_all = abap_false AND lv_set_gp = abap_false.
        CONTINUE.             "no Excel local / group amount for this G/L
      ENDIF.

*     The line items must carry the same document amount as the Excel lines,
*     otherwise the Excel cannot be mapped onto them: change nothing at all.
      CLEAR: lv_bseg_doc, lv_lines.
      LOOP AT lt_new INTO DATA(ls_new)
           WHERE saknr = <ls_sum>-gl OR hkont = <ls_sum>-gl.
        lv_bseg_doc = lv_bseg_doc + ls_new-wrbtr.
        lv_lines    = lv_lines + 1.
      ENDLOOP.
      IF lv_lines = 0 OR lv_bseg_doc <> <ls_sum>-doc.
        RETURN.
      ENDIF.

*     Share by document amount; the last line item takes the rounding
*     remainder, so the G/L total equals the Excel total to the cent.
      lv_left_loc = <ls_sum>-loc.
      lv_left_gp  = <ls_sum>-gp.
      lv_count    = 0.
      LOOP AT lt_new ASSIGNING FIELD-SYMBOL(<fs_new>)
           WHERE saknr = <ls_sum>-gl OR hkont = <ls_sum>-gl.
        lv_count = lv_count + 1.
        IF lv_count = lv_lines.
          lv_loc = lv_left_loc.
          lv_gp  = lv_left_gp.
        ELSE.
          lv_loc = <fs_new>-wrbtr * <ls_sum>-loc / <ls_sum>-doc.
          lv_gp  = <fs_new>-wrbtr * <ls_sum>-gp / <ls_sum>-doc.
        ENDIF.
        lv_left_loc = lv_left_loc - lv_loc.
        lv_left_gp  = lv_left_gp - lv_gp.

        IF <ls_sum>-loc_all = abap_true.
          <fs_new>-dmbtr = lv_loc.
        ENDIF.
        IF lv_set_gp = abap_true.
          <fs_new>-dmbe2 = lv_gp.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

* Step 3: take the copy only if the document still balances in local and
* group currency. No MESSAGE here - this runs inside the posting (often as
* WF-BATCH), where an E message would cancel the posting itself.
    LOOP AT lt_new INTO ls_new.
      IF ls_new-shkzg = 'H'.
        lv_bal_loc = lv_bal_loc - ls_new-dmbtr.
        lv_bal_gp  = lv_bal_gp - ls_new-dmbe2.
      ELSE.
        lv_bal_loc = lv_bal_loc + ls_new-dmbtr.
        lv_bal_gp  = lv_bal_gp + ls_new-dmbe2.
      ENDIF.
    ENDLOOP.
    IF lv_bal_loc <> 0 OR lv_bal_gp <> 0.
      RETURN.
    ENDIF.

* Row by row: T_BSEG cannot be assigned as a whole (activation error 30/09/26)
    LOOP AT t_bseg ASSIGNING FIELD-SYMBOL(<fs_bseg>).
      READ TABLE lt_new INTO ls_new INDEX sy-tabix.
      IF sy-subrc = 0.
        <fs_bseg>-dmbtr = ls_new-dmbtr.
        <fs_bseg>-dmbe2 = ls_new-dmbe2.
      ENDIF.
    ENDLOOP.
*EOC By Arnav on 30/09/26

  ENDMETHOD.
