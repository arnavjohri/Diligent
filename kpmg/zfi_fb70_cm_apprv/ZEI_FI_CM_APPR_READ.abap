*----------------------------------------------------------------------*
* Enhancement implementation : ZEI_FI_CM_APPR_READ   (new)
* Spot                       : implicit, END of static method
*   CL_FDC_ACCDOC_PARK_ACCESS=>READ
* Author / date              : Arnav Johri, 23/10/26
* Why: the Verify General Journal Entries app opens a parked document
*   through CL_FAC_FINANCIALS_POST_DPC_EXT->ACCDOC_FUNC_PARKD_DOC_READ_UPD.
*   That method calls READ and then refuses the document when the
*   account types READ returns (EV_KOARS) are not all in
*   CL_FDC_ACCDOC_PARK_ACCESS=>CO_ALLOWED_ACCT_TY_FOR_PARKING:
*     ELSEIF NOT lv_koars CO ...co_allowed_acct_ty_for_parking.
*       MESSAGE e092(fdc_posting_001) ...
*   A customer credit memo carries account type 'D'. The check sits in
*   the middle of that method, so no implicit enhancement reaches it;
*   this block removes 'D' from EV_KOARS at the end of READ instead,
*   only for our credit memos and only when the document is opened for
*   change (IV_FOR_POST initial). The items are not touched.
* Decision 23/10/26: correction after rejection in the Verify app only.
* Not touched: the posting path (IV_FOR_POST = X) keeps the standard
*   092 as a safety net; DG posting runs in ZEI_FI_CM_APPR_POST.
* RISK: the app edits documents in the G/L posting model. Whether it
*   shows and keeps the customer line is first seen on this test.
*   Open and inspect before changing or submitting.
* Create via: SE24, CL_FDC_ACCDOC_PARK_ACCESS, method READ, Display,
*   Enhance (spiral), Edit -> Enhancement Operations -> Show Implicit
*   Enhancement Options, right-click the line before ENDMETHOD,
*   Enhancement Implementation -> Create Implementation, Code, name
*   ZEI_FI_CM_APPR_READ, Z package and request. Paste the block between
*   ENHANCEMENT and ENDENHANCEMENT. Activate.
* Switch-off: deactivate the implementation (SE19) - standard returns.
* Checked 23/10/26 against the pasted READ source: EV_KOARS =
*   VBKPF-KOARS; ES_ACCDOC_HDR_WA-TCODE = VBKPF-TCODE (MOVE-CORRESPONDING,
*   not on the copy-with-reference path, hence IV_FOR_CREATE_WITH_REF
*   excluded); non-G/L lines are carried into the item table (the
*   ASSERT for them is commented out by SAP, CE2302).
*----------------------------------------------------------------------*
ENHANCEMENT 1  ZEI_FI_CM_APPR_READ.    "active version
*BOC By Arnav on 23/10/26
* ASSUMPTION: credit memo document type 'DG', same constant as the BTE
*             module and ZEI_FI_CM_APPR_POST.
* ASSUMPTION: a document entered in the Fiori G/L app never carries
*             account type 'D'; with the app code and type DG this
*             block only meets documents from our trigger.
  CONSTANTS lc_zcm_blart TYPE vbkpf-blart VALUE 'DG'.

  DATA lv_zcm_blart TYPE vbkpf-blart.

  CLEAR lv_zcm_blart.

  IF iv_for_post = abap_false
     AND iv_for_create_with_ref = abap_false             "Changes by Arnav on 23/10/26
     AND ev_error_occurred IS INITIAL
     AND ev_koars CA 'D'
     AND es_accdoc_hdr_wa-tcode = cl_fdc_posting_impl=>co_fdc_s_accdoc_hdr_tcode-gl_posting.

    SELECT SINGLE blart
      FROM vbkpf
      WHERE bukrs = @iv_bukrs
        AND belnr = @iv_belnr
        AND gjahr = @iv_gjahr
      INTO @lv_zcm_blart.

    IF sy-subrc = 0 AND lv_zcm_blart = lc_zcm_blart.
*     Empty string literal: removes the character, no blank left behind
      REPLACE ALL OCCURRENCES OF 'D' IN ev_koars WITH ``.
    ENDIF.

  ENDIF.
*EOC By Arnav on 23/10/26
ENDENHANCEMENT.
