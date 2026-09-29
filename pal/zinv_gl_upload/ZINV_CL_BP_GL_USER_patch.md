# ZINV_CL_BP_GL_USER — patch sheet (29/09/26)

Behaviour pool: edit in ADT only (SAP GUI refuses: "is a behavior pool, it cannot be
changed in SAP GUI"). Tab **Local Types**, class `lsc_zinv_i_user_gl`, method
`save_modified`, the `lt_excel_data_gl = CORRESPONDING #( lt_existing_xlgldata MAPPING ...`
statement (locate by that text, not by line number — was line 972 on 29/09/26).

Replace

        amt_gp_curr    = amtloccurr

with

*BOC By Arnav on 29/09/26
*        amt_gp_curr    = amtloccurr
        amt_gp_curr    = amtgpcurr
*EOC By Arnav on 29/09/26

`amtgpcurr` is already used by the `lt_inv_inp_gl` mapping further down the same method.
Only files saved after this fix store the correct group amount in ZINV_POST_GL.
