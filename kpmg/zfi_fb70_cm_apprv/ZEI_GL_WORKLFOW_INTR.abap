*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_GL_WORKLFOW_INTR  (existing, team's)
* Spot                       : implicit, end of method
*   CL_FDC_ACCDOC_VER_SERVICES->IS_DOC_VALID_FOR_NEW_WORKFLOW
* Change by Arnav, 16/10/26  : second branch for a customer credit memo
*   submitted to the GL verification scenario by Z_FI_CM_APPR_START_WF.
*   The standard allows only the account types in
*   CL_FDC_ACCDOC_PARK_ACCESS=>CO_ALLOWED_ACCT_TY_FOR_PARKING (G/L and
*   supplier); the customer line 'D' raises FDC_POSTING_001 092.
* Paste-only: SE24 -> method -> Enhance -> edit the existing
*   implementation. Whole implementation below, first line to last.
* PRECONDITION: confirm in the debugger (SWIA restart of the failed
*   posting work item) that 092 is raised here and nowhere else.
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_GL_WORKLFOW_INTR.    "active version
IF lv_tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting AND iv_post_mode = '2'
  AND ev_error_occurred = abap_true AND rv_result = abap_false AND lv_dummy IS NOT INITIAL.
  CLEAR: lv_dummy,ev_error_occurred.
  rv_result = abap_true.
ENDIF.

*BOC By Arnav on 16/10/26
* Customer credit memo parked in FB70 and submitted to the GL
* verification scenario (Z_FI_CM_APPR_START_WF rewrites TCODE to the
* app code). Account types are G/L + customer only, no supplier, asset
* or material line. Post modes as the standard allows for its own
* documents plus 2 (post from workflow), as in the branch above.
* ASSUMPTION: a genuine Fiori GL document never carries account type
*             'D', so this branch only meets documents from our trigger.
IF lv_tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting
  AND iv_koars CA 'D'
  AND iv_koars CO 'SD'
  AND iv_post_mode CA '1236'
  AND ev_error_occurred = abap_true AND rv_result = abap_false AND lv_dummy IS NOT INITIAL.
  CLEAR: lv_dummy, ev_error_occurred.
  rv_result = abap_true.
ENDIF.
*EOC By Arnav on 16/10/26

ENDENHANCEMENT.
