*----------------------------------------------------------------------*
* BAdI            : FI_ITEMS_CH_DATA (classic, SE18/SE19)
* Implementation  : ZFI_FBL3N_ACDOCA_U
* Class           : ZCL_IM_FI_FBL3N_ACDOCA_U
* Method          : IF_EX_FI_ITEMS_CH_DATA~CHANGE_ITEMS
* Project         : <placeholder - confirm OVL / KPMG>   Module: FI
* Author          : Arnav Johri                  Date: 19.10.2026
* Transport       : <TR>
*----------------------------------------------------------------------*
* DESCRIPTION
*   FBL3N (RFITEMGL) builds its list from BSIS/BSAS, i.e. only from
*   lines that have a BSEG item. Journal entries that exist in ACDOCA
*   only, document status BSTAT = 'U', never reach the list.
*   This BAdI reads those ACDOCA lines for the G/L accounts, company
*   codes and posting dates entered on the FBL3N selection screen and
*   appends them to CT_ITEMS so they are displayed with the rest.
*   Active for transaction FBL3N only. FBL1N / FBL5N are untouched.
*
* CREATE VIA
*   SE19 -> Classic BAdI -> FI_ITEMS_CH_DATA -> Create implementation
*   ZFI_FBL3N_ACDOCA_U, implementing class ZCL_IM_FI_FBL3N_ACDOCA_U.
*   Open method CHANGE_ITEMS and paste the lines between METHOD and
*   ENDMETHOD below. Activate the class, then activate the
*   implementation (SE19 -> Activate).
*   FI_ITEMS_CH_DATA is not multiple-use: if an implementation already
*   exists, paste the body into its CHANGE_ITEMS instead (see NOTES.md).
*
* CHANGE HISTORY
*   19.10.2026  Arnav Johri  <TR>  Initial development
*----------------------------------------------------------------------*
  METHOD if_ex_fi_items_ch_data~change_items.

    CONSTANTS:
      gc_tcode_fbl3n TYPE sy-tcode     VALUE 'FBL3N',
      gc_bstat_u     TYPE acdoca-bstat VALUE 'U',
      gc_koart_gl    TYPE rfposxext-koart VALUE 'S',
      gc_actvt_disp  TYPE activ_auth   VALUE '03'.

    TYPES: BEGIN OF ty_key,
             bukrs TYPE rfposxext-bukrs,
             belnr TYPE rfposxext-belnr,
             gjahr TYPE rfposxext-gjahr,
             buzei TYPE rfposxext-buzei,
           END OF ty_key.

*   Field list and this type are matched BY POSITION by the SELECT
*   below - keep both lists in the same order.
    TYPES: BEGIN OF ty_acdoca,
             rbukrs  TYPE acdoca-rbukrs,
             belnr   TYPE acdoca-belnr,
             gjahr   TYPE acdoca-gjahr,
             docln   TYPE acdoca-docln,
             racct   TYPE acdoca-racct,
             budat   TYPE acdoca-budat,
             bldat   TYPE acdoca-bldat,
             blart   TYPE acdoca-blart,
             poper   TYPE acdoca-poper,
             drcrk   TYPE acdoca-drcrk,
             hsl     TYPE acdoca-hsl,
             wsl     TYPE acdoca-wsl,
             rhcur   TYPE acdoca-rhcur,
             rwcur   TYPE acdoca-rwcur,
             sgtxt   TYPE acdoca-sgtxt,
             zuonr   TYPE acdoca-zuonr,
             rcntr   TYPE acdoca-rcntr,
             prctr   TYPE acdoca-prctr,
             aufnr   TYPE acdoca-aufnr,
             rbusa   TYPE acdoca-rbusa,
             segment TYPE acdoca-segment,
             bschl   TYPE acdoca-bschl,
             mwskz   TYPE acdoca-mwskz,
             bstat   TYPE acdoca-bstat,
             xblnr   TYPE bkpf-xblnr,
             bktxt   TYPE bkpf-bktxt,
             cpudt   TYPE bkpf-cpudt,
             usnam   TYPE bkpf-usnam,
             monat   TYPE bkpf-monat,
           END OF ty_acdoca.

    DATA: lt_acdoca   TYPE STANDARD TABLE OF ty_acdoca,
          ls_acdoca   TYPE ty_acdoca,
          lt_exist    TYPE HASHED TABLE OF ty_key
                           WITH UNIQUE KEY bukrs belnr gjahr buzei,
          ls_key      TYPE ty_key,
          ls_item     TYPE rfposxext,
          lv_rldnr    TYPE t881-rldnr,
          lt_saknr    TYPE RANGE OF acdoca-racct,
          lt_bukrs    TYPE RANGE OF acdoca-rbukrs,
          lt_budat    TYPE RANGE OF acdoca-budat,
          ls_budat    LIKE LINE OF lt_budat,
          lt_noauth   TYPE RANGE OF acdoca-rbukrs,
          ls_noauth   LIKE LINE OF lt_noauth,
          lv_bukrs    TYPE acdoca-rbukrs.

    FIELD-SYMBOLS: <lt_sel>  TYPE STANDARD TABLE,
                   <lv_flag> TYPE any,
                   <lv_date> TYPE any,
                   <ls_item> TYPE rfposxext.

*--- 1. FBL3N only. FBL1N / FBL5N share this BAdI and must not change.
    IF sy-tcode <> gc_tcode_fbl3n.
      RETURN.
    ENDIF.

*--- 2. Read the FBL3N selection screen (program RFITEMGL).
* ASSUMPTION: technical names on the FBL3N screen are
*   SD_SAKNR (G/L account), SD_BUKRS (company code)  - LDB SDF,
*   X_OPSEL / PA_STIDA (open items, key date),
*   X_CLSEL (cleared items), X_AISEL / SO_BUDAT (all items, posting
*   date). Verify each with F1 -> Technical Information on the FBL3N
*   screen; a wrong name is reported by the message in step 2c, not
*   by a dump.
    ASSIGN ('(RFITEMGL)SD_SAKNR[]') TO <lt_sel>.
    IF sy-subrc = 0.
      lt_saknr = <lt_sel>.
    ELSE.
      MESSAGE i398(00) WITH 'ZFI_FBL3N_ACDOCA_U:'
                            'G/L account selection not found,'
                            'ACDOCA status U items not added'.
      RETURN.
    ENDIF.

    ASSIGN ('(RFITEMGL)SD_BUKRS[]') TO <lt_sel>.
    IF sy-subrc = 0.
      lt_bukrs = <lt_sel>.
    ELSE.
      MESSAGE i398(00) WITH 'ZFI_FBL3N_ACDOCA_U:'
                            'Company code selection not found,'
                            'ACDOCA status U items not added'.
      RETURN.
    ENDIF.

*--- 2a. Cleared items: an ACDOCA-only line is never cleared, so there
*        is nothing to add for this status.
    ASSIGN ('(RFITEMGL)X_CLSEL') TO <lv_flag>.
    IF sy-subrc = 0 AND <lv_flag> = abap_true.
      RETURN.
    ENDIF.

*--- 2b. Open items: everything posted up to the key date.
    ASSIGN ('(RFITEMGL)X_OPSEL') TO <lv_flag>.
    IF sy-subrc = 0 AND <lv_flag> = abap_true.
      ASSIGN ('(RFITEMGL)PA_STIDA') TO <lv_date>.
      IF sy-subrc = 0 AND <lv_date> IS NOT INITIAL.
        CLEAR ls_budat.
        ls_budat-sign   = 'I'.
        ls_budat-option = 'LE'.
        ls_budat-low    = <lv_date>.
        APPEND ls_budat TO lt_budat.
      ENDIF.
    ELSE.
*--- 2c. All items: posting date range as entered.
      ASSIGN ('(RFITEMGL)SO_BUDAT[]') TO <lt_sel>.
      IF sy-subrc = 0.
        lt_budat = <lt_sel>.
      ELSE.
        MESSAGE i398(00) WITH 'ZFI_FBL3N_ACDOCA_U:'
                              'Posting date selection not found,'
                              'ACDOCA status U items not added'.
        RETURN.
      ENDIF.
    ENDIF.

*--- 3. Leading ledger. ACDOCA carries one line per ledger; FBL3N is
*      the entry view, so one ledger only or every line doubles.
* ASSUMPTION: leading ledger from T881-XLEADING, not hardcoded '0L'.
    SELECT SINGLE rldnr FROM t881
      WHERE xleading = @abap_true
      INTO @lv_rldnr.
    IF sy-subrc <> 0.
      MESSAGE i398(00) WITH 'ZFI_FBL3N_ACDOCA_U:'
                            'Leading ledger not found in T881,'
                            'ACDOCA status U items not added'.
      RETURN.
    ENDIF.

*--- 4. ACDOCA lines with document status U. BKPF is outer-joined for
*      the header fields; a line without a header is still listed.
    SELECT a~rbukrs, a~belnr, a~gjahr, a~docln, a~racct,
           a~budat, a~bldat, a~blart, a~poper, a~drcrk,
           a~hsl, a~wsl, a~rhcur, a~rwcur, a~sgtxt, a~zuonr,
           a~rcntr, a~prctr, a~aufnr, a~rbusa, a~segment,
           a~bschl, a~mwskz, a~bstat,
           b~xblnr, b~bktxt, b~cpudt, b~usnam, b~monat
      FROM acdoca AS a
      LEFT OUTER JOIN bkpf AS b
        ON  b~bukrs = a~rbukrs
        AND b~belnr = a~belnr
        AND b~gjahr = a~gjahr
      WHERE a~rldnr  = @lv_rldnr
        AND a~rbukrs IN @lt_bukrs
        AND a~racct  IN @lt_saknr
        AND a~bstat  = @gc_bstat_u
        AND a~budat  IN @lt_budat
      ORDER BY a~rbukrs, a~racct, a~budat, a~belnr, a~docln
      INTO TABLE @lt_acdoca.
    IF sy-subrc <> 0.
      RETURN.                      " nothing to add - normal case
    ENDIF.

*--- 5. Company code authorisation, as the logical database SDF does
*      for the standard items. Unauthorised company codes are dropped.
*      Account authorisation groups (F_BKPF_BES) are not checked here.
    CLEAR lv_bukrs.
    LOOP AT lt_acdoca INTO ls_acdoca.
      IF ls_acdoca-rbukrs = lv_bukrs.
        CONTINUE.                  " sorted by company code
      ENDIF.
      lv_bukrs = ls_acdoca-rbukrs.
      AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
        ID 'BUKRS' FIELD lv_bukrs
        ID 'ACTVT' FIELD gc_actvt_disp.
      IF sy-subrc <> 0.
        CLEAR ls_noauth.
        ls_noauth-sign   = 'I'.
        ls_noauth-option = 'EQ'.
        ls_noauth-low    = lv_bukrs.
        APPEND ls_noauth TO lt_noauth.
      ENDIF.
    ENDLOOP.
    IF lt_noauth IS NOT INITIAL.
      DELETE lt_acdoca WHERE rbukrs IN lt_noauth.
    ENDIF.

*--- 6. Keys already in the list, so a line is never shown twice.
    LOOP AT ct_items ASSIGNING <ls_item>.
      CLEAR ls_key.
      ls_key-bukrs = <ls_item>-bukrs.
      ls_key-belnr = <ls_item>-belnr.
      ls_key-gjahr = <ls_item>-gjahr.
      ls_key-buzei = <ls_item>-buzei.
      INSERT ls_key INTO TABLE lt_exist.
    ENDLOOP.

*--- 7. Map to the line item structure and append.
* ASSUMPTION: an ACDOCA-only line has no BSEG item, so BUZEI is taken
*   from the last three digits of DOCLN (a document with more than
*   999 lines would collide - not expected for CO postings).
* ASSUMPTION: sign convention is the same on both sides - debit
*   positive, credit negative in HSL/WSL and in DMSHB/WRSHB.
* ASSUMPTION: RFPOSXEXT carries HWAER and SEGMENT on this release.
*   If activation reports either as unknown, delete that one line.
    LOOP AT lt_acdoca INTO ls_acdoca.
      CLEAR ls_key.
      ls_key-bukrs = ls_acdoca-rbukrs.
      ls_key-belnr = ls_acdoca-belnr.
      ls_key-gjahr = ls_acdoca-gjahr.
      ls_key-buzei = ls_acdoca-docln+3(3).
      READ TABLE lt_exist WITH TABLE KEY bukrs = ls_key-bukrs
                                         belnr = ls_key-belnr
                                         gjahr = ls_key-gjahr
                                         buzei = ls_key-buzei
                          TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      CLEAR ls_item.
      ls_item-bukrs   = ls_key-bukrs.
      ls_item-belnr   = ls_key-belnr.
      ls_item-gjahr   = ls_key-gjahr.
      ls_item-buzei   = ls_key-buzei.
      ls_item-koart   = gc_koart_gl.
      ls_item-konto   = ls_acdoca-racct.
      ls_item-hkont   = ls_acdoca-racct.
      ls_item-budat   = ls_acdoca-budat.
      ls_item-bldat   = ls_acdoca-bldat.
      ls_item-blart   = ls_acdoca-blart.
      IF ls_acdoca-monat IS NOT INITIAL.
        ls_item-monat = ls_acdoca-monat.
      ELSE.
        ls_item-monat = ls_acdoca-poper+1(2).
      ENDIF.
      ls_item-xblnr   = ls_acdoca-xblnr.
      ls_item-bktxt   = ls_acdoca-bktxt.
      ls_item-cpudt   = ls_acdoca-cpudt.
      ls_item-usnam   = ls_acdoca-usnam.
      ls_item-shkzg   = ls_acdoca-drcrk.
      ls_item-waers   = ls_acdoca-rwcur.
      ls_item-hwaer   = ls_acdoca-rhcur.
      ls_item-dmshb   = ls_acdoca-hsl.
      ls_item-wrshb   = ls_acdoca-wsl.
      ls_item-dmbtr   = abs( ls_acdoca-hsl ).
      ls_item-wrbtr   = abs( ls_acdoca-wsl ).
      ls_item-sgtxt   = ls_acdoca-sgtxt.
      ls_item-zuonr   = ls_acdoca-zuonr.
      ls_item-kostl   = ls_acdoca-rcntr.
      ls_item-prctr   = ls_acdoca-prctr.
      ls_item-aufnr   = ls_acdoca-aufnr.
      ls_item-gsber   = ls_acdoca-rbusa.
      ls_item-segment = ls_acdoca-segment.
      ls_item-bschl   = ls_acdoca-bschl.
      ls_item-mwskz   = ls_acdoca-mwskz.
      ls_item-bstat   = ls_acdoca-bstat.
      APPEND ls_item TO ct_items.

      INSERT ls_key INTO TABLE lt_exist.
    ENDLOOP.

  ENDMETHOD.
