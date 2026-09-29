METHOD update_amount.
*BOC By Arnav on 29/09/26
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
    TYPES: BEGIN OF lty_hit,
             bseg_ix TYPE sy-tabix,
             post_ix TYPE sy-tabix,
           END OF lty_hit.

    DATA: lv_obj     TYPE awkey,
          lv_gl      TYPE bseg-saknr,
          lv_post_ix TYPE sy-tabix,
          lv_bseg_ix TYPE sy-tabix,
          lt_used    TYPE SORTED TABLE OF sy-tabix WITH UNIQUE KEY table_line,
          lt_hit     TYPE STANDARD TABLE OF lty_hit WITH EMPTY KEY.

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

* Pass 1: pair every Excel line with its own line item, changing nothing yet
    LOOP AT lt_glpost INTO DATA(ls_post).
      lv_post_ix = sy-tabix.

      IF ls_post-amt_loc_curr IS INITIAL AND ls_post-amt_gp_curr IS INITIAL.
        CONTINUE.             "no Excel local / group amount on this line
      ENDIF.

*     Excel gives 54182010, the line item holds 0054182010
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_post-glaccount
        IMPORTING
          output = lv_gl.

*     Same G/L and same document amount, not taken by an earlier Excel line.
*     A G/L can occur several times in one document (e.g. 54182010 twice).
      CLEAR lv_bseg_ix.
      LOOP AT t_bseg TRANSPORTING NO FIELDS
           WHERE ( saknr = lv_gl OR hkont = lv_gl )
             AND wrbtr = ls_post-amt_doc_curr.
        IF NOT line_exists( lt_used[ table_line = sy-tabix ] ).
          lv_bseg_ix = sy-tabix.
          EXIT.
        ENDIF.
      ENDLOOP.

*     Fallback: same G/L only, first line item not taken yet
      IF lv_bseg_ix IS INITIAL.
        LOOP AT t_bseg TRANSPORTING NO FIELDS
             WHERE saknr = lv_gl OR hkont = lv_gl.
          IF NOT line_exists( lt_used[ table_line = sy-tabix ] ).
            lv_bseg_ix = sy-tabix.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.

*     An Excel line without a line item: correcting only the others would put
*     the document out of balance in local / group currency. Leave it all as
*     SAP derived it. No MESSAGE here - this runs inside the posting (often as
*     WF-BATCH), where an E message would cancel the posting itself.
      IF lv_bseg_ix IS INITIAL.
        RETURN.
      ENDIF.

      INSERT lv_bseg_ix INTO TABLE lt_used.
      APPEND VALUE #( bseg_ix = lv_bseg_ix post_ix = lv_post_ix ) TO lt_hit.
    ENDLOOP.

* Pass 2: every Excel line found its line item - apply the amounts
    LOOP AT lt_hit INTO DATA(ls_hit).
      READ TABLE lt_glpost INTO ls_post INDEX ls_hit-post_ix.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      READ TABLE t_bseg ASSIGNING FIELD-SYMBOL(<fs_bseg>) INDEX ls_hit-bseg_ix.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_post-amt_doc_curr IS NOT INITIAL.
        <fs_bseg>-wrbtr = ls_post-amt_doc_curr.
      ENDIF.
      IF ls_post-amt_loc_curr IS NOT INITIAL.
        <fs_bseg>-dmbtr = ls_post-amt_loc_curr.
      ENDIF.

* ASSUMPTION: files saved before the behaviour pool fix (amt_gp_curr mapped
* from amtloccurr) carry the LOCAL amount in AMT_GP_CURR. Group equal to local
* while the document amount differs is that bug, not a group amount, so SAP's
* DMBE2 is kept for those lines instead of writing a local amount into it.
      IF ls_post-amt_gp_curr IS NOT INITIAL
         AND NOT (     ls_post-amt_gp_curr =  ls_post-amt_loc_curr
                   AND ls_post-amt_gp_curr <> ls_post-amt_doc_curr ).
        <fs_bseg>-dmbe2 = ls_post-amt_gp_curr.
      ENDIF.
    ENDLOOP.
*EOC By Arnav on 29/09/26

  ENDMETHOD.
