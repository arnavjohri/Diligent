*&---------------------------------------------------------------------*
*& Enhancement    : ZFI_ENH_SPLIT_TAX_BAPC
*& Title          : Business area / profit center on tax lines before
*&                  the document-splitting mandatory check
*& Project        : OVL                          Module: FI / MM-LIV
*& Related FS     : Issue 20.11.2026 - MIR7/MIRO "Balancing field
*&                  Business Area in line item 003 not filled"
*& Author         : Arnav Johri                  Date: 20.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& WHERE IT GOES
*&   Function module  G_BEB_SPLIT_DOCUMENT_CALC   (function group GLT0)
*&   Enhancement point G_BEB_SPLIT_DOCUMENT_CALC_01, spot ES_SAPLGLT0
*&   As a NEW implementation - not inside SAP's JVA_BEB_SPLIT_01.
*&   Paste this whole file between the two lines the editor generates:
*&   ENHANCEMENT n ZFI_ENH_SPLIT_TAX_BAPC.  and  ENDENHANCEMENT.
*&
*& DESCRIPTION
*&   On a logistics invoice the input tax line reaches the splitter
*&   with a profit center but no business area. Because it is already
*&   partly assigned, the rule-based split and inheritance leave it
*&   alone, and the mandatory check then rejects the document.
*&   Substitution exit UF122 (ZFI_RGGBS000_USEREXIT) would fill it from
*&   ZFI_BAPC1, but FI substitution runs after this check.
*&   This enhancement applies the UF122 rule here, before the check:
*&   tax lines only, and only fields that are still blank.
*&
*& CHANGE HISTORY
*&   20.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
*BOC By Arnav on 20/11/26
  TYPES: BEGIN OF lty_zz_bapc,
           bukrs TYPE zfi_bapc1-bukrs,
           hkont TYPE zfi_bapc1-hkont,
           begda TYPE zfi_bapc1-begda,
           gsber TYPE zfi_bapc1-gsber,
           prctr TYPE zfi_bapc1-prctr,
         END OF lty_zz_bapc.

  DATA: lt_zz_key  TYPE STANDARD TABLE OF lty_zz_bapc,
        ls_zz_key  TYPE lty_zz_bapc,
        lt_zz_bapc TYPE STANDARD TABLE OF lty_zz_bapc,
        ls_zz_bapc TYPE lty_zz_bapc.

* Reference transaction of logistics invoice verification (MIRO/MIR7)
* and the splitting item category of tax lines (Taxes on Sales/Purch.)
  CONSTANTS: lc_zz_awtyp_liv TYPE c LENGTH 5 VALUE 'RMRP',
             lc_zz_ltype_tax TYPE c LENGTH 5 VALUE '05100'.

  FIELD-SYMBOLS <ls_zz_ex> TYPE glt0_accit_ex.

* ASSUMPTION: scope is logistics invoice verification only (reference
* transaction RMRP), because that is where the issue was reported and
* tested. FI invoices (FB60 etc.) are deliberately left as they are.
* ASSUMPTION: nothing between this point and the mandatory check
* (CLEAR_ASSIGNMENTS, HANDLE_SQUAN) removes the business area again.
* The other lines keep theirs through the same code; to be confirmed
* by the test posting.
  IF i_acchd_ex-acchd-awtyp = lc_zz_awtyp_liv
     AND i_acchd_ex-reverse IS INITIAL.

*   1. Collect the tax lines that still miss an assignment
    LOOP AT t_accit_ex[] ASSIGNING <ls_zz_ex>
         WHERE accit-linetype = lc_zz_ltype_tax
           AND accit-kstat    = space.
      IF <ls_zz_ex>-accit-gsber IS INITIAL
         OR <ls_zz_ex>-accit-prctr IS INITIAL.
        CLEAR ls_zz_key.
        ls_zz_key-bukrs = <ls_zz_ex>-accit-bukrs.
        ls_zz_key-hkont = <ls_zz_ex>-accit-hkont.
        APPEND ls_zz_key TO lt_zz_key.
      ENDIF.
    ENDLOOP.

    IF lt_zz_key IS NOT INITIAL.
      SORT lt_zz_key BY bukrs hkont.
      DELETE ADJACENT DUPLICATES FROM lt_zz_key COMPARING bukrs hkont.

*     2. One read of ZFI_BAPC1 for all of them
      SELECT bukrs, hkont, begda, gsber, prctr
        FROM zfi_bapc1
        FOR ALL ENTRIES IN @lt_zz_key
        WHERE bukrs = @lt_zz_key-bukrs
          AND hkont = @lt_zz_key-hkont
        INTO TABLE @lt_zz_bapc.

*     Same row as UF122 takes: the earliest start date per account.
*     UF122 still runs afterwards, so both must agree.
      SORT lt_zz_bapc BY bukrs hkont begda.

*     3. Fill only what is blank
      LOOP AT t_accit_ex[] ASSIGNING <ls_zz_ex>
           WHERE accit-linetype = lc_zz_ltype_tax
             AND accit-kstat    = space.
        IF <ls_zz_ex>-accit-gsber IS NOT INITIAL
           AND <ls_zz_ex>-accit-prctr IS NOT INITIAL.
          CONTINUE.
        ENDIF.

        READ TABLE lt_zz_bapc INTO ls_zz_bapc
             WITH KEY bukrs = <ls_zz_ex>-accit-bukrs
                      hkont = <ls_zz_ex>-accit-hkont
             BINARY SEARCH.
        IF sy-subrc <> 0.
*         No entry in ZFI_BAPC1: leave the line as it is. The standard
*         message "Balancing field ... not filled" then tells the user.
          CONTINUE.
        ENDIF.

*       Entry not yet valid on the posting date (as in UF122)
        IF <ls_zz_ex>-accit-budat < ls_zz_bapc-begda.
          CONTINUE.
        ENDIF.

        IF <ls_zz_ex>-accit-gsber IS INITIAL
           AND ls_zz_bapc-gsber IS NOT INITIAL.
          <ls_zz_ex>-accit-gsber = ls_zz_bapc-gsber.
        ENDIF.
        IF <ls_zz_ex>-accit-prctr IS INITIAL
           AND ls_zz_bapc-prctr IS NOT INITIAL.
          <ls_zz_ex>-accit-prctr = ls_zz_bapc-prctr.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*EOC By Arnav on 20/11/26
