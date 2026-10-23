*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_GL_WORKLFOW_INTR  (existing, team's)
* Spot                       : implicit, end of method
*   CL_FDC_ACCDOC_VER_SERVICES->IS_DOC_VALID_FOR_NEW_WORKFLOW
* Change by Arnav, 23/10/26  : second branch so the Verify General
*   Journal Entries app can open a customer credit memo (DG) from our
*   trigger. Decision 23/10/26: correction after rejection in that app
*   only, no FBV2.
* Why here: SE91 where-used of FDC_POSTING_001 092 "Parked document is
*   no GL posting" lists this method only. The standard accepts only
*   the account types in CL_FDC_ACCDOC_PARK_ACCESS=>
*   CO_ALLOWED_ACCT_TY_FOR_PARKING (G/L and supplier); the customer line
*   'D' fails that check. The team's branch above clears the error for
*   post mode 2 only.
* RISK (stated 23/10/26): the app edits documents in the G/L posting
*   model. Whether it shows and keeps the customer line is not known
*   until the first test. Open and look before changing or submitting.
* Paste-only: SE24 -> method -> Enhance -> edit the existing
*   implementation. Whole implementation below, first line to last.
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_GL_WORKLFOW_INTR.    "active version
IF lv_tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting AND iv_post_mode = '2'
  AND ev_error_occurred = abap_true AND rv_result = abap_false AND lv_dummy IS NOT INITIAL.
  CLEAR: lv_dummy,ev_error_occurred.
  rv_result = abap_true.
ENDIF.

*BOC By Arnav on 23/10/26
* Customer credit memo submitted to the GL verification scenario by
* ZCL_CM_WORKFLOW (app transaction code on the document). Clears only
* the 092 of the account type check: account types G/L and customer
* only, post modes the standard allows (1, 3, 6) plus 2 as above.
* ASSUMPTION: a document entered in the Fiori G/L app never carries
*             account type 'D', so this branch only meets documents
*             from our trigger.
IF lv_tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting
  AND iv_koars CA 'D'
  AND iv_koars CO 'SD'
  AND iv_post_mode CA '1236'
  AND ev_error_occurred = abap_true AND rv_result = abap_false
  AND sy-msgid = 'FDC_POSTING_001' AND sy-msgno = '092'.
  CLEAR: lv_dummy, ev_error_occurred.
  rv_result = abap_true.
ENDIF.
*EOC By Arnav on 23/10/26

ENDENHANCEMENT.
