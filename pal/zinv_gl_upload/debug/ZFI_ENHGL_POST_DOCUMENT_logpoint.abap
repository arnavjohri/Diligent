* Enhancement ZFI_ENHGL_POST_DOCUMENT (implicit, start of FM POST_DOCUMENT)
* TEMPORARY instrumentation 12/10/26 - remove once the Verify-app path is understood.
* Replace the whole enhancement body with this block.
*BOC By Arnav on 12/10/26
  DATA: ls_dbg_bseg TYPE bseg,
        lv_dbg_sub  TYPE string,
        lv_dbg_cnt  TYPE i.

  IF t_bseg[] IS NOT INITIAL.
    ls_dbg_bseg = t_bseg[ 1 ].
    lv_dbg_cnt  = lines( t_bseg[] ).
    lv_dbg_sub  = 'ENH-' && ls_dbg_bseg-belnr.
*   Proves whether POST_DOCUMENT is reached at all on this path, by whom
*   (WF-BATCH vs the Fiori user) and with which document key.
    LOG-POINT ID zgl_amt SUBKEY lv_dbg_sub
      FIELDS sy-uname sy-tcode sy-batch sy-cprog
             ls_dbg_bseg-bukrs ls_dbg_bseg-belnr ls_dbg_bseg-gjahr
             ls_dbg_bseg-hkont ls_dbg_bseg-wrbtr ls_dbg_bseg-dmbtr
             ls_dbg_bseg-dmbe2 lv_dbg_cnt.

    zcl_gl_exchange_amount_det=>update_amount(
      CHANGING
        t_bseg = t_bseg[] ).

*   Same line item after the method: did it change anything?
    ls_dbg_bseg = t_bseg[ 1 ].
    lv_dbg_sub  = 'AFT-' && ls_dbg_bseg-belnr.
    LOG-POINT ID zgl_amt SUBKEY lv_dbg_sub
      FIELDS ls_dbg_bseg-hkont ls_dbg_bseg-wrbtr ls_dbg_bseg-dmbtr
             ls_dbg_bseg-dmbe2.
  ENDIF.
*EOC By Arnav on 12/10/26
