METHOD update_amount.
    DATA(ls_bseg) = VALUE #( t_bseg[ 1 ] OPTIONAL ).

    IF ls_bseg IS NOT INITIAL.
      DATA : lv_obj TYPE awkey,
             lv_gl  TYPE bseg-saknr.

      lv_obj =  ls_bseg-belnr && ls_bseg-bukrs && ls_bseg-gjahr .

      SELECT SINGLE enduser,fileid,invoiceid  FROM zinv_i_gl_valid
        WHERE objkey = @lv_obj
        INTO @DATA(ls_glvalid).
      IF sy-subrc EQ 0.
        SELECT * FROM zinv_post_gl
          WHERE enduser = @ls_glvalid-enduser
          AND fileid = @ls_glvalid-fileid
          AND documentid = @ls_glvalid-invoiceid
          INTO TABLE @DATA(lt_glpost).
        IF sy-subrc EQ 0.
          LOOP AT lt_glpost INTO DATA(ls_post).
            lv_gl = CONV #( ls_post-glaccount ).
            IF ls_post-amt_doc_curr IS NOT INITIAL AND ls_post-amt_loc_curr IS NOT INITIAL .
              READ TABLE t_bseg ASSIGNING FIELD-SYMBOL(<fs_bseg>) WITH KEY saknr = lv_gl.
              IF sy-subrc EQ 0.
                <fs_bseg>-dmbtr = ls_post-amt_loc_curr.
                <fs_bseg>-wrbtr = ls_post-amt_doc_curr.
                IF ls_post-amt_gp_curr IS NOT INITIAL.
                  <fs_bseg>-dmbe2  = ls_post-amt_gp_curr.
                ENDIF.
              ELSE.
                READ TABLE t_bseg ASSIGNING <fs_bseg> WITH KEY hkont = lv_gl.
                IF sy-subrc EQ 0.
                  <fs_bseg>-dmbtr = ls_post-amt_loc_curr.
                  <fs_bseg>-wrbtr = ls_post-amt_doc_curr.
                  IF ls_post-amt_gp_curr IS NOT INITIAL.
                    <fs_bseg>-dmbe2  = ls_post-amt_gp_curr.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.

          ENDLOOP.
        ENDIF.
      ENDIF.

    ENDIF.

  ENDMETHOD.
