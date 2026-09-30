*----------------------------------------------------------------------*
* ZFI_JV_TB (ZJVTB) - Issue 3 / Observation 1 - patch sheet 28/09/26
* GL 300100 missing from RISE output. Cause: JV_JVTO1_ACDOCA_SWITCH_2
* returns no row for an account whose postings in p_year net to zero
* (SE16N 28/09/26: no 2026 row for 300100 / CP0001). The GL list lt_jvt
* is built from that view only, so the account never entered the list
* although its line items (Dr = Cr = USD 90,614.36) are in
* JV_JVSO1_ACDOCA. ECC's JVTO1 kept a totals record for it, hence the
* zero row in the ECC output.
*
* Paste target: FORM get_data. Insert the block below AFTER the
* "*EOC By SAP_ABAP on 25/09/26" that closes the LOOP AT lt_jvto1 block,
* and BEFORE the line
*     SORT lt_jvt BY racct ASCENDING.
* The existing SORT + DELETE ADJACENT DUPLICATES COMPARING racct that
* follow remove the duplicates this select adds. No new variables.
* Fragment, paste-only - the OCP source on hand is an SE38 list print
* truncated at 72 characters, so a whole-file paste is not possible yet.
*----------------------------------------------------------------------*

*BOC By SAP_ABAP on 28/09/26
* Accounts whose postings in p_year net to zero have no row in
* JV_JVTO1_ACDOCA_SWITCH_2 but do have Dr/Cr in the selected periods
* (e.g. 300100 / CP0001, H/S pairs). Take the account list from the
* line items as well; the SORT / DELETE ADJACENT DUPLICATES below
* remove the overlap.
  SELECT DISTINCT racct
    FROM jv_jvso1_acdoca
    APPENDING CORRESPONDING FIELDS OF TABLE @lt_jvt
    WHERE ryear  =  @p_year
      AND rbukrs =  @p_bukrs
      AND rjvnam IN @p_jvnam
      AND poper  BETWEEN @s_period-low AND @s_period-high
      AND rldnr  =  '4A'
      AND rrcty  =  '0'
      AND rrecin IN @p_rrecin.
*EOC By SAP_ABAP on 28/09/26
