*&---------------------------------------------------------------------*
*& Include ZFI_03_CUSTINV_FORM
*&---------------------------------------------------------------------*


FORM f_initial_values.
  "Internal Table
  REFRESH:
      gt_acdoca,
      i_param,
      i_param2,
      i_param3,
      i_param4,
      i_param5,
      gt_t001,
      gt_adrc_comadd,
      gt_adrc_billto_add,
      gt_cepct,
      gt_but020,
      gt_dfkkbptaxnum,
      gt_stxh,
      gt_zsigntab,
      gt_t003,
      gt_nriv,
      gt_acdoca_asterisk,
      gt_doctype,
      gt_t001z,
      gt_but000,
      gt_acdoca_sr,
      gt_acdoca_temp,
      gt_stxh2,
      gt_email,
      gt_adr6,
      gt_detail,
      gt_tcurt.

  "Work Area
  CLEAR:
    gs_acdoca,
    gs_param,
    gs_param2,
    gs_param3,
    gs_param4,
    gs_param5,
    gs_t001,
    gs_adrc_comadd,
    gs_adrc_billto_add,
    gs_cepct,
    gs_but020,
    gs_dfkkbptaxnum,
    gs_stxh,
    gs_zsigntab,
    gs_t003,
    gs_nriv,
    gs_acdoca_asterisk,
    gs_doctype,
    gs_t001z,
    gs_but000,
    gs_acdoca_sr,
    gs_acdoca_temp,
    gs_stxh2,
    gs_email,
    gs_adr6,
    gs_detail,
    gs_header,
    gs_detail-descr,
    gs_tcurt.

  "Variable
  CLEAR:
    gv_vatsales,
    gv_vat12,
    gv_zerosales,
    gv_xmptsales,
    gv_vattotal,
    gv_totalamt,
    gv_descr,
    gv_qty,
    gv_ucost,
    gv_vat,
    gv_currency,
    gv_tamount,
    gv_tamtfig,
    gv_tamtdec.

ENDFORM.

FORM user_check.

*USER AUTHENTICATION

*  AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
**  FOR USER sy-uname
*  ID 'BUKRS' FIELD 'PR01'
*  ID 'ACTVT' FIELD '03'.
*
*  IF sy-subrc <> 0. "auth check failed for PR01
*
*    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK' "check for 2P01
**    FOR USER sy-uname
*    ID 'BUKRS' FIELD '2P01'
*    ID 'ACTVT' FIELD '03'. "'03' for display '02' for change
*
*    IF sy-subrc <> 0. "auth check failed for 2P01
*
*    ELSE.
*      IF p_rbukrs = 'PR01'.
*        MESSAGE s015 DISPLAY LIKE 'E'. "No Authorization for company code PR01.
*        STOP.
*      ENDIF.
*    ENDIF.
*  ""
*  ELSE.
*    IF p_rbukrs = '2P01'.
*        MESSAGE s016 DISPLAY LIKE 'E'. "No Authorization for company code PR01.
*        STOP.
*    ENDIF.
*  ENDIF.

  AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
    ID 'BUKRS' FIELD p_rbukrs
    ID 'ACTVT' FIELD '01'.

  IF sy-subrc <> 0. "auth check failed
    MESSAGE s016 WITH p_rbukrs DISPLAY LIKE 'E'. "No Authorization for company code PR01.
    STOP.
  ENDIF.

ENDFORM.

FORM hbank_f4                                         "Added by Paul 4/12/2023
  CHANGING
  cv_hbkid TYPE hbkid.

  DATA:
    lt_hbank   TYPE STANDARD TABLE OF ty_hbank,
    lt_rehbank TYPE STANDARD TABLE OF ddshretval.

  SELECT t1~bukrs
       t1~hbkid
       t2~banks
       t2~bankl
       t3~banka
       t3~ort01
  FROM t012k AS t1
  INNER JOIN t012 AS t2
  ON t1~bukrs = t2~bukrs
  AND t1~hbkid = t2~hbkid
  INNER JOIN bnka AS t3
  ON t2~banks = t3~banks
  AND t2~bankl = t3~bankl
  INTO TABLE lt_hbank
  WHERE t1~bukrs EQ p_rbukrs.

  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'HBKID'    " Name of field in VALUE_TAB
      value_org       = 'S'        " Value return: C: cell by cell, S: structured
    TABLES
      value_tab       = lt_hbank  " Table of values: entries cell by cell
      return_tab      = lt_rehbank  " Return the selected value
    EXCEPTIONS
      parameter_error = 1          " Incorrect parameter
      no_values_found = 2          " No values found
      OTHERS          = 3.

  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  READ TABLE lt_rehbank INTO DATA(ls_rehbank) INDEX 1.
  cv_hbkid = ls_rehbank-fieldval.

ENDFORM.

FORM accid_f4                                     "Added by Paul 4/12/2023
  CHANGING
    cv_hktid TYPE hktid.

  DATA:
    lt_accid   TYPE STANDARD TABLE OF ty_accid,
    lt_reaccid TYPE STANDARD TABLE OF ddshretval.

  SELECT bukrs
         hbkid
         hktid
         text1
    FROM t012t
    INTO TABLE lt_accid
    WHERE bukrs EQ p_rbukrs.

  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'HKTID'    " Name of field in VALUE_TAB
      value_org       = 'S'        " Value return: C: cell by cell, S: structured
    TABLES
      value_tab       = lt_accid  " Table of values: entries cell by cell
      return_tab      = lt_reaccid  " Return the selected value
    EXCEPTIONS
      parameter_error = 1          " Incorrect parameter
      no_values_found = 2          " No values found
      OTHERS          = 3.

  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  READ TABLE lt_reaccid INTO DATA(ls_reaccid) INDEX 1.
  cv_hktid = ls_reaccid-fieldval.

ENDFORM.

FORM f_get_data.
*------------------------------------------------------------------*
*                SELECT STATEMENT (REQUIREMENT)
*------------------------------------------------------------------*

  PERFORM user_check.

*  get zpm_low zglbparam
  RANGES:
*     lr_blart FOR acdoca-blart,
     lr_acdoca FOR stxh-tdname,
     lr_acdoca2 FOR stxh-tdname.

*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026

*Get PEZA Address and TIN from ZGLBPARAM Table
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
    FROM zglbparam
    INTO TABLE i_peza_param
    WHERE ( zparam_id EQ 'ZFI_PEZA_ADD'
       OR zparam_id EQ 'ZFI_PEZA_TIN'
       OR zparam_id EQ 'ZFI_PEZA_PRCTR'
       OR zparam_id EQ 'ZFI_PEZA_MWSKZ'
       OR zparam_id EQ 'ZFI_PEZA_GL' ).
*End of Changes

*  get zpm_low zglbparam
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param
  WHERE ( zparam_id EQ 'ZFIDOCTYPE_BS'
    OR zparam_id EQ 'ZFIDOCTYPE_CM'
    OR zparam_id EQ 'ZFIDOCTYPE_DM'
    OR zparam_id EQ 'ZBS_SURPLUS'
    OR zparam_id EQ 'ZBIRPTUDATE'
    OR zparam_id EQ 'ZBIRPTU')
    AND bukrs EQ p_rbukrs.
  IF sy-subrc EQ 0.
*    REFRESH lr_blart.
*    LOOP AT i_param INTO gs_param
*      WHERE zparam_id EQ 'ZFIDOCTYPE_BS'
*      OR zparam_id EQ 'ZFIDOCTYPE_CM'
*      OR zparam_id EQ 'ZFIDOCTYPE_DM'.
*
*      lr_blart-sign   = 'I'.
*      lr_blart-option = 'EQ'.
*      lr_blart-low    = gs_param-zpm_low.
*      APPEND lr_blart.
*      CLEAR lr_blart.
*    ENDLOOP.
  ENDIF.

*  get zpm_low i_param2 zglbparam
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param2
  WHERE ( zparam_id EQ 'ZFI_TAXABLE'
    OR zparam_id EQ 'ZFI_ZERORATED'
    OR zparam_id EQ 'ZFI_EXEMPT'
    OR zparam_id EQ 'ZFIDM_INTRST'
    OR zparam_id EQ 'ZFI_BS_SPLIT'
    OR zparam_id EQ 'ZFI_BS_GL'
    OR zparam_id EQ 'ZFI_WHT'). "Additional for Interest 02/28/2023

*      get zpm_low i_param3 zglbparam
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param3
  WHERE zparam_id EQ 'ZFIBS_CC'
  AND bukrs = p_rbukrs.


*      get zpm_low i_param4 email sender
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param4
  WHERE zparam_id EQ 'ZFIEMAILSENDER'
  AND bukrs = p_rbukrs.

*      get zpm_low i_param6 customer code
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param6
  WHERE zparam_id EQ 'ZFIAR_EXCLUDE'
  AND bukrs = p_rbukrs.

  IF so_kunnr IS NOT INITIAL AND p_cag IS NOT INITIAL.
    SELECT partner
           bu_group
      FROM but000
      INTO TABLE gt_but000_cag
      WHERE bu_group = p_cag
      AND partner IN so_kunnr.
    IF sy-subrc = 0.
      SELECT rldnr                "Ledger in General Ledger Accounting
         rbukrs                   "Company Code
         gjahr                    "Fiscal Year
         belnr                    "Accounting Document Number
         docln
         blart                    "Document Type
         buzei                    "Item no.
         bldat                    "Document Type
         kunnr                    "Customer Number
         netdt                    "Net Due Date
         prctr                    "Profit Center
         rwcur                    "Transaction Currency
         sgtxt                    "Item Text
         xreversed                "Indicator: Item is Reversed
         usnam                    "User Name
         koart                    "Account type
         racct
         zuonr
         wsl
         ktosl
         mwskz
         glaccount_type
         hbkid
         hktid
         drcrk
    FROM acdoca
    INTO TABLE gt_acdoca
    FOR ALL ENTRIES IN gt_but000_cag
    WHERE rbukrs EQ p_rbukrs
    AND belnr IN so_belnr
    AND gjahr EQ p_gjahr
    AND bldat IN so_bldat
     AND rldnr = '0L'
*    AND blart IN lr_blart
    AND blart IN so_blart
    AND kunnr = gt_but000_cag-partner.

    ENDIF.
  ELSEIF so_kunnr IS NOT INITIAL.
    "acdoca details GL account details
    SELECT rldnr                    "Ledger in General Ledger Accounting
           rbukrs                   "Company Code
           gjahr                    "Fiscal Year
           belnr                    "Accounting Document Number
           docln
           blart                    "Document Type
           buzei                    "Item no.
           bldat                    "Document Type
           kunnr                    "Customer Number
           netdt                    "Net Due Date
           prctr                    "Profit Center
           rwcur                    "Transaction Currency
           sgtxt                    "Item Text
           xreversed                "Indicator: Item is Reversed
           usnam                    "User Name
           koart                    "Account type
           racct
           zuonr
           wsl
           ktosl
           mwskz
           glaccount_type
           hbkid
           hktid
           drcrk
      FROM acdoca
      INTO TABLE gt_acdoca_kunnr
      WHERE rbukrs EQ p_rbukrs
      AND belnr IN so_belnr
      AND gjahr EQ p_gjahr
      AND kunnr IN so_kunnr
      AND bldat IN so_bldat
      AND rldnr = '0L'
*      AND blart IN lr_blart.
      AND blart IN so_blart.
    IF sy-subrc = 0.
      SELECT rldnr                    "Ledger in General Ledger Accounting
           rbukrs                   "Company Code
           gjahr                    "Fiscal Year
           belnr                    "Accounting Document Number
           docln
           blart                    "Document Type
           buzei                    "Item no.
           bldat                    "Document Type
           kunnr                    "Customer Number
           netdt                    "Net Due Date
           prctr                    "Profit Center
           rwcur                    "Transaction Currency
           sgtxt                    "Item Text
           xreversed                "Indicator: Item is Reversed
           usnam                    "User Name
           koart                    "Account type
           racct
           zuonr
           wsl
           ktosl
           mwskz
           glaccount_type
           hbkid
           hktid
           drcrk
      FROM acdoca
      INTO TABLE gt_acdoca
      FOR ALL ENTRIES IN gt_acdoca_kunnr
      WHERE rbukrs = gt_acdoca_kunnr-rbukrs
      AND belnr = gt_acdoca_kunnr-belnr
      AND gjahr = gt_acdoca_kunnr-gjahr
      AND rldnr = '0L'
      AND kunnr = gt_acdoca_kunnr-kunnr.
    ENDIF.

  ELSEIF p_cag IS NOT INITIAL.
    SELECT partner
           bu_group
      FROM but000
      INTO TABLE gt_but000_cag
      WHERE bu_group = p_cag.
    IF sy-subrc = 0.
      SELECT rldnr                "Ledger in General Ledger Accounting
         rbukrs                   "Company Code
         gjahr                    "Fiscal Year
         belnr                    "Accounting Document Number
         docln
         blart                    "Document Type
         buzei                    "Item no.
         bldat                    "Document Type
         kunnr                    "Customer Number
         netdt                    "Net Due Date
         prctr                    "Profit Center
         rwcur                    "Transaction Currency
         sgtxt                    "Item Text
         xreversed                "Indicator: Item is Reversed
         usnam                    "User Name
         koart                    "Account type
         racct
         zuonr
         wsl
         ktosl
         mwskz
         glaccount_type
         hbkid
         hktid
         drcrk
      FROM acdoca
      INTO TABLE gt_acdoca
      FOR ALL ENTRIES IN gt_but000_cag
      WHERE rbukrs EQ p_rbukrs
      AND belnr IN so_belnr
      AND gjahr EQ p_gjahr
        AND rldnr = '0L'
      AND bldat IN so_bldat
*      AND blart IN lr_blart
      AND blart IN so_blart
      AND kunnr = gt_but000_cag-partner.
    ENDIF.

  ELSE.
    "acdoca details GL account details
    SELECT rldnr                    "Ledger in General Ledger Accounting
           rbukrs                   "Company Code
           gjahr                    "Fiscal Year
           belnr                    "Accounting Document Number
           docln
           blart                    "Document Type
           buzei                    "Item no.
           bldat                    "Document Type
           kunnr                    "Customer Number
           netdt                    "Net Due Date
           prctr                    "Profit Center
           rwcur                    "Transaction Currency
           sgtxt                    "Item Text
           xreversed                "Indicator: Item is Reversed
           usnam                    "User Name
           koart                    "Account type
           racct
           zuonr
           wsl
           ktosl
           mwskz
           glaccount_type
           hbkid
           hktid
           drcrk
      FROM acdoca
      INTO TABLE gt_acdoca
      WHERE rbukrs EQ p_rbukrs
      AND belnr IN so_belnr
      AND gjahr EQ p_gjahr
      AND rldnr = '0L'
*      AND kunnr IN so_kunnr
      AND bldat IN so_bldat
*      AND blart IN lr_blart.
      AND blart IN so_blart.
  ENDIF.

  IF sy-subrc = 0.
    gt_acdoca_temp = gt_acdoca.
    SORT gt_acdoca_temp BY kunnr rbukrs gjahr belnr. "(EDITED: 03/16/2023)
    DELETE gt_acdoca_temp WHERE kunnr = ''.
*    SORT gt_acdoca_temp BY rbukrs gjahr belnr docln.
    DELETE ADJACENT DUPLICATES FROM gt_acdoca_temp COMPARING rbukrs gjahr belnr.

*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026

*Get VAT on Local Sales
    SELECT rbukrs,
           gjahr,
           belnr,
           blart,
           mwskz,
           racct,
           wsl,
           ktosl
      INTO TABLE @gt_acdoca_vat
      FROM acdoca
      WHERE rldnr = '0L'
      AND rbukrs EQ @p_rbukrs
      AND belnr IN @so_belnr
      AND gjahr EQ @p_gjahr
      AND blart = 'DR'
      AND ( ktosl = 'MWS'
       OR ktosl = 'WIT' ).
*End of Changes

    "get Currency
    SELECT spras
           waers
           ltext
           ktext
      FROM tcurt
      INTO TABLE gt_tcurt
       FOR ALL ENTRIES IN gt_acdoca
      WHERE spras = 'E'
      AND waers = gt_acdoca-rwcur.
    IF sy-subrc = 0.
    ENDIF.

    "get t001z VAT TIN
    SELECT bukrs                        "Company Code
           party                        "Parameter Type
           paval                        "VAT Registration Number
       FROM t001z
      INTO TABLE gt_t001z
      FOR ALL ENTRIES IN gt_acdoca
      WHERE bukrs = gt_acdoca-rbukrs
      AND party = 'SAPI14'.
    IF sy-subrc = 0.
    ENDIF.

    "get t001 company details
    SELECT bukrs                        "Company Code
           adrnr                        "Address
           stceg                        "VAT Registration Number
           butxt                        "Name of Company Code or Company
           land1                      "Country name
       FROM t001
      INTO TABLE gt_t001
      FOR ALL ENTRIES IN gt_acdoca
      WHERE bukrs = gt_acdoca-rbukrs.
    IF sy-subrc = 0.
      "get adrc company address
      SELECT a~addrnumber ,                "Address Number
             a~date_from   ,               "Valid-from date - in current Release only 00010101 possible
             a~nation       ,              "Version ID for International Addresses
             a~str_suppl1,
             a~str_suppl2,
             a~str_suppl3 ,                "Street 4
             a~street      ,               "Street
             a~city1        ,              "City
             a~post_code1    ,             "City Postal Code
             a~region,
             a~city2,                    "district name
             a~name1  ,                    "Name 1
             a~location,
             a~country,
             t~landx
        FROM adrc AS a INNER JOIN t005t AS t ON a~country = t~land1 FOR ALL ENTRIES IN @gt_t001
        WHERE t~spras = @sy-langu  AND
         a~addrnumber = @gt_t001-adrnr
         INTO TABLE @gt_adrc_comadd.

    ENDIF.

    "get CEPCT
    SELECT spras                    "Language Key
           prctr                    "Profit Center
           datbi                    "Valid To Date
           kokrs                    "Controlling Area
           ltext                    "Long Text
       FROM cepct
      INTO TABLE gt_cepct
      FOR ALL ENTRIES IN gt_acdoca
      WHERE prctr = gt_acdoca-prctr
      AND spras = 'E'.              "SPRAS = 'EN'
    IF sy-subrc = 0.
    ENDIF.

    "get BUT000
    SELECT partner                    "Business Partner Number
           type
********************
           name_org4
*********************
           name_first
           namemiddle
           name_last
           bu_group
       FROM but000
      INTO TABLE gt_but000
      FOR ALL ENTRIES IN gt_acdoca
      WHERE partner = gt_acdoca-kunnr.
    IF sy-subrc = 0.
    ENDIF.

    "get BUT020
    SELECT partner                    "Business Partner Number
           addrnumber                 "Address Number
       FROM but020
      INTO TABLE gt_but020
      FOR ALL ENTRIES IN gt_acdoca
      WHERE partner = gt_acdoca-kunnr.
    IF sy-subrc = 0.
      "get ADRC (9) Bill to and (12) Address
      SELECT addrnumber                 "Address Number
             date_from                  "Valid-from date - in current Release only 00010101 possible
             nation                     "Version ID for International Addresses
             name1                      "Name1
             name2                      "Name2
             name3                      "Name3
             name4                      "Name4
             street                     "Street
             str_suppl1                 "Street 2
             str_suppl2                 "Street 3
             str_suppl3                 "Street 4
             city2                      "District
             city1                      "City
             post_code1                 "City postal code
         FROM adrc
        INTO TABLE gt_adrc_billto_add
        FOR ALL ENTRIES IN gt_but020
        WHERE addrnumber = gt_but020-addrnumber.
      IF sy-subrc = 0.
      ENDIF.
    ENDIF.

    "get ADR6
    SELECT addrnumber                 "Address Number
           smtp_addr                  "E-Mail Address
           flgdefault
       FROM adr6
      INTO TABLE gt_adr6
      FOR ALL ENTRIES IN gt_but020
      WHERE addrnumber = gt_but020-addrnumber.
    IF sy-subrc = 0.
    ENDIF.

    "get DFKKBPTAXNUM
    SELECT partner                 "Business Partner Number
           taxtype                 "Tax Number Category
           taxnum                  "Business Partner Tax Number
       FROM dfkkbptaxnum
      INTO TABLE gt_dfkkbptaxnum
      FOR ALL ENTRIES IN gt_acdoca
      WHERE partner = gt_acdoca-kunnr.
    IF sy-subrc = 0.
    ENDIF.

    "get ZSIGNTAB
    SELECT user_id                    "User ID for Signatories
           lastname                   "Last Name
           firstname                  "First Name
           releasecode                "Release code
           mi                         "Middle Initial
           esignature                 "E-signature Image ID
           zposition
       FROM zsigntab
      INTO TABLE gt_zsigntab
      FOR ALL ENTRIES IN gt_acdoca
      WHERE user_id = gt_acdoca-usnam.
    IF sy-subrc = 0.
    ENDIF.


*--- House Bank and AccountID in ACDOCA --- Start - Added by Paul 4/13/2023
    SELECT bukrs            "Company Code
           hbkid            "House Bank
           hktid            "Account ID
           bankn            "Bank account number
           waers            "Currency
      FROM t012k
      INTO TABLE gt_t012k
      FOR ALL ENTRIES IN gt_acdoca
      WHERE bukrs EQ gt_acdoca-rbukrs
      AND hbkid EQ gt_acdoca-hbkid
      AND hktid EQ gt_acdoca-hktid.
    IF sy-subrc = 0.
      SELECT bukrs            "Company Code
           hbkid              "House Bank
           banks              "Bank Country/Region
           bankl              "Bank Key
        FROM t012
        INTO TABLE gt_t012
        FOR ALL ENTRIES IN gt_t012k
        WHERE bukrs EQ gt_t012k-bukrs
        AND hbkid EQ gt_t012k-hbkid.
      IF sy-subrc = 0.
        SELECT banks          "Bank Country/Region
           bankl              "Bank Key
           banka              "Bank Name
           swift              "SWIFT/BIC for International Payments
           bnklz              "Bank Number
          FROM bnka
          INTO TABLE gt_bnka
          FOR ALL ENTRIES IN gt_t012
          WHERE banks EQ gt_t012-banks
          AND bankl EQ gt_t012-bankl.
        IF sy-subrc = 0.
        ENDIF.
      ENDIF.


**For Creditable Withholding tax
      SELECT wt_qbshb
         FROM with_item
        INTO TABLE @DATA(gt_cwt) FOR ALL ENTRIES IN @gt_acdoca
        WHERE bukrs = @gt_acdoca-rbukrs
        AND belnr =   @gt_acdoca-belnr
        AND gjahr = @gt_acdoca-gjahr
        AND witht IN ('PG', 'PE')
        AND wt_withcd NE ''.


      SELECT bukrs
          adrnr
          stceg
          butxt
        FROM t001
        INTO TABLE gt_t001acname
        FOR ALL ENTRIES IN gt_t012k
        WHERE bukrs EQ gt_t012k-bukrs.
      IF sy-subrc = 0.
      ENDIF.
    ENDIF.
*--- House Bank and AccountID in ACDOCA --- End - Added by Paul 4/13/2023

  ELSE.
    MESSAGE s003 DISPLAY LIKE 'E'. "M - Document does not exist.
  ENDIF.

  "Insert records in gt_acdoca_asterisk
  LOOP AT gt_acdoca ASSIGNING FIELD-SYMBOL(<lfs_acdoca>).
    CHECK <lfs_acdoca>-kunnr IS NOT INITIAL.


    MOVE <lfs_acdoca>-rldnr TO gs_acdoca_asterisk-rldnr.
    MOVE <lfs_acdoca>-rbukrs TO gs_acdoca_asterisk-nrivr_bukrs.
    MOVE <lfs_acdoca>-gjahr TO gs_acdoca_asterisk-gjahr.
    MOVE <lfs_acdoca>-belnr TO gs_acdoca_asterisk-belnr.
    CONCATENATE '*' <lfs_acdoca>-kunnr '*' INTO gs_acdoca_asterisk-asterisk_kunnr.
    CONCATENATE '*' <lfs_acdoca>-rbukrs  <lfs_acdoca>-belnr <lfs_acdoca>-gjahr '*'
    INTO  gs_acdoca_asterisk-asterisk_rbg.
    CONCATENATE <lfs_acdoca>-rbukrs  <lfs_acdoca>-belnr <lfs_acdoca>-gjahr <lfs_acdoca>-buzei
    INTO  gs_acdoca_asterisk-asterisk_desc.
    MOVE <lfs_acdoca>-kunnr TO gs_acdoca_asterisk-kunnr.

    lr_acdoca-sign   = 'I'.
    lr_acdoca-option = 'CP'.
    lr_acdoca-low    = gs_acdoca_asterisk-asterisk_kunnr.
    APPEND lr_acdoca.
    CLEAR lr_acdoca.

    lr_acdoca2-sign   = 'I'.
    lr_acdoca2-option = 'CP'.
    lr_acdoca2-low    = gs_acdoca_asterisk-asterisk_rbg.
    APPEND lr_acdoca2.
    CLEAR lr_acdoca2.

    APPEND gs_acdoca_asterisk TO gt_acdoca_asterisk.
  ENDLOOP.

  SELECT tdobject                  "tEXTS: APPLICATION OBJECT
         tdname                    "nAME
         tdid                      "tEXT id
         tdspras                   "lANGUAGE kEY
     FROM stxh
    INTO TABLE gt_stxh ##TOO_MANY_ITAB_FIELDS
    WHERE tdname IN lr_acdoca
    AND tdobject EQ 'BUT000'.
  IF sy-subrc = 0.
    gs_stxh-asterisk_kunnr = gs_acdoca_asterisk-asterisk_kunnr.
  ENDIF.

  SELECT tdobject                  "tEXTS: APPLICATION OBJECT
           tdname                    "nAME
           tdid                      "tEXT id
           tdspras                   "lANGUAGE kEY
       FROM stxh
      INTO TABLE gt_stxh2 ##TOO_MANY_ITAB_FIELDS
      WHERE tdname IN lr_acdoca2.
  IF sy-subrc = 0.
    gs_stxh2-asterisk_rbg = gs_acdoca_asterisk-asterisk_rbg.
  ENDIF.

  SELECT rldnr                    "Ledger in General Ledger Accounting
         rbukrs                   "Company Code
         gjahr                    "Fiscal Year
         blart                    "Document Type
      FROM acdoca
      INTO TABLE gt_acdoca_sr
      WHERE rbukrs EQ p_rbukrs
      AND belnr IN so_belnr
      AND gjahr EQ p_gjahr
      AND kunnr IN so_kunnr
      AND bldat IN so_bldat
*      AND blart IN lr_blart.
      AND blart IN so_blart.

  IF sy-subrc = 0.
    "Join t003(Document Types) and NRIV(   Number Range Intervals)
    SELECT t1~blart                    "Document Type
           t1~numkr                    "Number Range
           t2~object                   "Number Range Object
           t2~subobject                "Number range object subobject value
           t2~nrrangenr                "Number range number
           t2~toyear                   "To fiscal year
           t2~fromnumber               "From number
           t2~tonumber                  "To number
       FROM t003 AS t1
      INNER JOIN nriv AS t2
      ON t1~numkr = t2~nrrangenr
      INTO TABLE gt_t003
      FOR ALL ENTRIES IN gt_acdoca_sr
      WHERE t1~blart = gt_acdoca_sr-blart
      AND t2~object = 'RF_BELEG'
      AND t2~subobject = gt_acdoca_sr-rbukrs
      AND t2~toyear = gt_acdoca_sr-gjahr.
    IF sy-subrc = 0.
    ENDIF.
  ENDIF.

*GET EMAIL
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param5
  WHERE zparam_id = 'ZFIBS_EMAILADD'
    AND bukrs = p_rbukrs.
  IF sy-subrc = 0.
  ENDIF.

**********get bank details for email.************************
  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
  FROM zglbparam
  INTO TABLE i_param7
  WHERE zparam_id IN ( 'ZFI_BANKNAME', 'ZFI_ACCNAME' , 'ZFI_ACCNUMBER', 'ZFI_SWIFTCODE', 'ZFI_ADDRESS' ).

  IF sy-subrc = 0.
  ENDIF.

*--- House Bank and AccountID in selection-screen --- Start - Added by Paul 4/13/2023
  SELECT bukrs            "Company Code
         hbkid            "House Bank
         hktid            "Account ID
         bankn            "Bank account number
         waers            "Currency
    FROM t012k
    INTO TABLE gt_t012kbh
    WHERE bukrs EQ p_rbukrs
    AND hbkid EQ p_hbank
    AND hktid EQ p_accid.
  IF sy-subrc = 0.
    SELECT bukrs            "Company Code
           hbkid              "House Bank
           banks              "Bank Country/Region
           bankl              "Bank Key
        FROM t012
        INTO TABLE gt_t012bh
        FOR ALL ENTRIES IN gt_t012kbh
        WHERE bukrs EQ gt_t012kbh-bukrs
        AND hbkid EQ gt_t012kbh-hbkid.
    IF sy-subrc = 0.
      SELECT banks          "Bank Country/Region
         bankl              "Bank Key
         banka              "Bank Name
         swift              "SWIFT/BIC for International Payments
         bnklz              "Bank Number
        FROM bnka
        INTO TABLE gt_bnkabh
        FOR ALL ENTRIES IN gt_t012bh
        WHERE banks EQ gt_t012bh-banks
        AND bankl EQ gt_t012bh-bankl.
      IF sy-subrc = 0.
      ENDIF.
    ENDIF.

    SELECT bukrs
         adrnr
         stceg
         butxt
       FROM t001
       INTO TABLE gt_t001acnamebh
       FOR ALL ENTRIES IN gt_t012kbh
       WHERE bukrs EQ gt_t012kbh-bukrs.
    IF sy-subrc = 0.
    ENDIF.
  ENDIF.
*--- House Bank and AccountID in selection-screen --- End - Added by Paul 4/13/2023

ENDFORM.

FORM f_process_data.

*************** PROCESS DATA ***************
*------------------------------------------------------------------*
*                Layout in Smartforms Header
*------------------------------------------------------------------*
  DATA: tdline  LIKE TABLE OF tline,
        tdline2 LIKE TABLE OF tline.

  DATA: lv_vat2        TYPE char1 ##NEEDED,
        lv_vatsales    TYPE char40,             "Start BREAKDOWN OF TRANSACTIONS
        lv_vat12       TYPE char40,
        lv_zerosales   TYPE char40,
        lv_xmptsales   TYPE char40,
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
        lv_locsales    TYPE char40,
        lv_locsalesbir TYPE char40,
*End of Changes
        lv_vattotal    TYPE char40,             "End BREAKDOWN OF TRANSACTIONS
        lv_ucostdesc   TYPE char40,             "Start Detail
        lv_vatdesc     TYPE char40,
        lv_tamtdec     TYPE char40,             "End Detail
        lv_sgtxt       TYPE tdline,
        lv_sgtxt2      TYPE tdline,
        lv_racct       TYPE zglbparam-zpm_low,
        lv_racct2      TYPE zglbparam-zpm_low,
        lv_racct3      TYPE zglbparam-zpm_low,
        lv_dueamount   TYPE with_item-wt_qbshb,
        lv_cwt1        TYPE with_item-wt_qbshb,
        gv_cwt         TYPE with_item-wt_qbshb,
        lv_cwt         TYPE char40,
        lv_zuonr       TYPE acdoca-zuonr ##NEEDED,
        lv_tcurr       TYPE char40 ##NEEDED,
        gv_tamtwords   TYPE string.

*For Total Amount
  DATA: lv_tamount     TYPE bapicurr-bapicurr,
        lv_tamountstr  TYPE char40,
        lv_tamount1    TYPE char40,
        lv_tamount1cnv TYPE wrbtr,
        lv_tamount2    TYPE char40 ##NEEDED,
        lv_convertamt1 TYPE wrbtr,
        lv_convertamt2 TYPE wrbtr,
        gv_amountcnv   TYPE i.

  DATA: gv_col19_cnv       TYPE bapicurr-bapicurr,
        gv_vatsales_cnv    TYPE bapicurr-bapicurr,
        gv_vatsales_i      TYPE i,
        lv_vatsales_str    TYPE char40,
        lv_vatsales_cnv    TYPE wrbtr,
        lv_vatsales_1      TYPE char40,
        lv_vatsales_2      TYPE char40 ##NEEDED,
        gv_ucost_cnv       TYPE bapicurr-bapicurr,
        gv_amountdue       TYPE bapicurr-bapicurr,
        gv_ucost_i         TYPE i,
        lv_ucost_str       TYPE char40,
        lv_ucost_cnv       TYPE wrbtr,
        lv_ucost_1         TYPE char40,
        lv_ucost_2         TYPE char40 ##NEEDED,
        gv_vat_cnv         TYPE bapicurr-bapicurr,
        gv_vat_i           TYPE i,
        lv_vat_str         TYPE char40,
        lv_vat_cnv         TYPE wrbtr,
        lv_vat_1           TYPE char40,
        lv_vat_2           TYPE char40 ##NEEDED,
        gv_vat12_cnv       TYPE bapicurr-bapicurr,
        gv_vat12_i         TYPE i,
        lv_vat12_str       TYPE char40,
        lv_vat12_cnv       TYPE wrbtr,
        lv_vat12_1         TYPE char40,
        lv_vat12_2         TYPE char40 ##NEEDED,
        gv_zerosales_cnv   TYPE bapicurr-bapicurr,
        gv_zerosales_i     TYPE i,
        lv_zerosales_str   TYPE char40,
        lv_zerosales_cnv   TYPE wrbtr,
        lv_zerosales_1     TYPE char40,
        lv_zerosales_2     TYPE char40 ##NEEDED,
        gv_xmptsales_cnv   TYPE bapicurr-bapicurr,
        gv_xmptsales_i     TYPE i,
        lv_xmptsales_str   TYPE char40,
        lv_xmptsales_cnv   TYPE wrbtr,
        lv_xmptsales_1     TYPE char40,
        lv_xmptsales_2     TYPE char40 ##NEEDED,
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
        gv_vatlocal_cnv    TYPE bapicurr-bapicurr,
        gv_vatlocal_i      TYPE i,
        lv_locsales_str    TYPE char40,
        lv_locsales_cnv    TYPE wrbtr,
        lv_locsales_1      TYPE char40,
        lv_locsales_2      TYPE char40 ##NEEDED,
        gv_vatlocalbir_cnv TYPE bapicurr-bapicurr,
        gv_vatlocalbir_i   TYPE i,
        lv_locsalesbir_str TYPE char40,
        lv_locsalesbir_cnv TYPE wrbtr,
        lv_locsalesbir_1   TYPE char40,
        lv_locsalesbir_2   TYPE char40 ##NEEDED,
*End of Changes
        gv_vattotal_i      TYPE i,
        lv_vattotal_cnv    TYPE wrbtr.

  DATA: lv_var1(200),
        lv_var2(200),
        lv_concat_word(200),
        lv_tamtwords        TYPE acdoca-wsl ##NEEDED,
        lv_kunnr1           TYPE string.

  DESCRIBE TABLE gt_acdoca_temp LINES DATA(lv_line). "For range validation.

  LOOP AT gt_acdoca_temp INTO gs_acdoca_temp.

    IF gs_acdoca_temp-xreversed EQ 'X' AND lv_line EQ 1.
      MESSAGE s008 DISPLAY LIKE 'E'. "M - Document has been reversed.
      CONTINUE.
    ELSEIF gs_acdoca_temp-xreversed EQ 'X' AND lv_line GT 1.
      CONTINUE.
    ENDIF.

*---6 - Customer Code/No. (11)
    lv_kunnr1 = gs_acdoca_temp-kunnr(1).
    READ TABLE i_param6 INTO gs_param6 WITH KEY zparam_id = 'ZFIAR_EXCLUDE'.
    IF sy-subrc = 0.
      IF lv_kunnr1 = gs_param6-zpm_low.
        MOVE gs_acdoca_temp-kunnr+1 TO gs_header-ccode.
        SHIFT gs_header-ccode LEFT DELETING LEADING '0'.
      ELSE.
        MOVE gs_acdoca_temp-kunnr TO gs_header-ccode.
        SHIFT gs_header-ccode LEFT DELETING LEADING '0'.
      ENDIF.
    ENDIF.
*    MOVE gs_acdoca_temp-kunnr TO gs_header-ccode.

    READ TABLE i_param INTO gs_param
    WITH KEY bukrs   = gs_acdoca_temp-rbukrs
             zpm_low = gs_acdoca_temp-blart.

    APPEND gs_param TO gt_doctype.

    IF sy-subrc = 0.
      IF gs_acdoca_temp-blart = 'DR'.
        DATA(lv_blart) = c_bs.
      ELSEIF gs_acdoca_temp-blart = 'DG'.
        lv_blart = c_cm.
      ELSEIF gs_acdoca_temp-blart = 'SA'.
        lv_blart = c_dm.
      ENDIF.
*      DATA(lv_blart) = gs_param-zparam_id.        "Modify by Paul 10-19-2022
    ELSE.
      MESSAGE s002 DISPLAY LIKE 'E'. "M - Invalid document type
      STOP.
    ENDIF.

    gv_blart = lv_blart.

****Start-Modify by Paul 10-19-2022
*    CASE gv_blart.
*      WHEN c_bs.
*        gv_formname = c_fbill.   "Form Assignment (Billing Statement)
**        CONCATENATE p_path '\' c_pdfinv gs_header-ccode '_' gs_acdoca_temp-gjahr gs_acdoca_temp-belnr '.pdf' INTO full_path.
*        CONCATENATE p_path '\' c_pdfinv gs_header-ccode '.pdf' INTO full_path.
*      WHEN c_cm.
*        gv_formname = c_fcredit. "Form Assignment (Credit Memo)
*        CONCATENATE p_path '\' c_pdfcm gs_header-ccode '_' gs_acdoca_temp-gjahr gs_acdoca_temp-belnr '.pdf' INTO full_path.
*      WHEN c_dm.
*        gv_formname = c_fdebit.  "Form Assignment (Debit Memo)
*        CONCATENATE p_path '\' c_pdfdm gs_header-ccode '_' gs_acdoca_temp-gjahr gs_acdoca_temp-belnr '.pdf' INTO full_path.
*      WHEN OTHERS.
*        MESSAGE s002 DISPLAY LIKE 'E'. "M - Invalid document type
*        STOP.
*    ENDCASE.
****End-Modify by Paul 10-19-2022

*---0 - Password

    DATA: l_month   TYPE char5,
          l_date_pw TYPE char10.

    CASE gs_acdoca_temp-bldat+4(2).
      WHEN '01'.
        l_month = 'JAN'.
      WHEN '02'.
        l_month = 'FEB'.
      WHEN '03'.
        l_month = 'MAR'.
      WHEN '04'.
        l_month = 'APR'.
      WHEN '05'.
        l_month = 'MAY'.
      WHEN '06'.
        l_month = 'JUN'.
      WHEN '07'.
        l_month = 'JUL'.
      WHEN '08'.
        l_month = 'AUG'.
      WHEN '09'.
        l_month = 'SEP'.
      WHEN '10'.
        l_month = 'OCT'.
      WHEN '11'.
        l_month = 'NOV'.
      WHEN '12'.
        l_month = 'DEC'.
    ENDCASE.

    l_date_pw = |{ gs_acdoca_temp-bldat+6(2) }{ l_month }{ gs_acdoca_temp-bldat+2(2) }|.

    gv_password = gs_header-ccode && l_date_pw.

*---0 - Reprint Copy
    IF cb_print = abap_true.
      gs_header-reprint = c_reprint.
    ELSE.
      gs_header-reprint = c_blank.
    ENDIF.

*---1 - Company Logo (1)
    IF p_rbukrs = c_pr01.
      gs_header-logo = c_logo_pal.
    ELSEIF p_rbukrs = c_2p01.
      gs_header-logo = c_logo_palex.
    ENDIF.

*---2 - Company Address (2)
    DATA: lv_vat    TYPE string,
          lv_output TYPE string.

    LOOP AT gt_t001 INTO gs_t001.
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
      DATA: lv_address TYPE string,
            lv_line1   TYPE string,
            lv_line2   TYPE string.

      READ TABLE i_peza_param INTO DATA(wa_peza_p) WITH KEY zparam_id = 'ZFI_PEZA_PRCTR'
                                                            bukrs = gs_acdoca_temp-rbukrs
                                                            zpm_low = gs_acdoca_temp-prctr.
      IF sy-subrc = 0.
        READ TABLE i_peza_param INTO DATA(wa_peza_a) WITH KEY zparam_id = 'ZFI_PEZA_ADD' bukrs = wa_peza_p-bukrs.
        IF sy-subrc = 0.
*Changes made for
*by ARAO on 27/08/2026
*           lv_address = wa_peza_a-zpm_low.
*          DATA(lv_phrase) = 'Owned and Operated by'.
*
*          FIND FIRST OCCURRENCE OF lv_phrase IN lv_address
*               MATCH OFFSET DATA(lv_offset).
*
*          IF sy-subrc = 0.
*            lv_line1 = lv_address+0(lv_offset).
*
*            lv_line2 = lv_address+lv_offset.
*
*            REPLACE ALL OCCURRENCES OF ';' IN lv_line1 WITH cl_abap_char_utilities=>newline.
*            CONDENSE lv_line1.
*            CONDENSE lv_line2.
*
*         ENDIF.
*         CONCATENATE lv_line1 cl_abap_char_utilities=>newline lv_line2 INTO gs_header-addhdr1.
          gs_header-addhdr1 = wa_peza_a-zpm_low.
          REPLACE ALL OCCURRENCES OF ';' IN gs_header-addhdr1 WITH cl_abap_char_utilities=>newline.

        ENDIF.
        READ TABLE i_peza_param INTO DATA(wa_peza_v) WITH KEY zparam_id = 'ZFI_PEZA_TIN' bukrs = wa_peza_p-bukrs.
        IF sy-subrc = 0.
          CONCATENATE c_vat wa_peza_v-zpm_low INTO lv_vat SEPARATED BY ' '.
        ENDIF.

        CONCATENATE gs_header-addhdr1 cl_abap_char_utilities=>newline lv_vat INTO gs_header-addhdr2.
      ELSE.
*End of Changes
        READ TABLE gt_adrc_comadd INTO gs_adrc_comadd
        WITH KEY addrnumber = gs_t001-adrnr.
        IF sy-subrc = 0.

          REPLACE ALL OCCURRENCES OF '8F' IN gs_adrc_comadd-str_suppl3 WITH space. "REMOVE (8F)
          TRANSLATE gs_adrc_comadd-landx TO UPPER CASE .
          CONCATENATE: gs_adrc_comadd-street ','         "Street
                      gs_adrc_comadd-str_suppl1  "street2
                       gs_adrc_comadd-str_suppl2  "street3
                      gs_adrc_comadd-str_suppl3    "Street 4
                      cl_abap_char_utilities=>newline
                      gs_adrc_comadd-post_code1       "City postal code
                       gs_adrc_comadd-city1 ','            "City
                        gs_adrc_comadd-region ','            "region
                       gs_adrc_comadd-city2 ','
                      gs_adrc_comadd-landx          "Country
  "                  gs_adrc_comadd-location         "location


       INTO gs_header-addhdr1 SEPARATED BY ' '.
          REPLACE REGEX '\n\s+' IN gs_header-addhdr1 WITH cl_abap_char_utilities=>newline.
          CONDENSE gs_header-addhdr1.


*  ---3 - Company Name, TIN Number (3,4)
          READ TABLE gt_t001z INTO gs_t001z
          WITH KEY bukrs = p_rbukrs
                   party = 'SAPI14'.
          CONCATENATE: c_address                    "Constant
                       gs_adrc_comadd-name1         "Company Name
*                       c_vat                        "Constant
*                       gs_t001z-paval               "VAT Registration Number
          INTO gs_header-addhdr2 SEPARATED BY ' '.

          lv_output = gs_t001z-paval+0(3) && '-' && gs_t001z-paval+3(3) && '-' && gs_t001z-paval+6(3) && '-' && gs_t001z-paval+9(5).
          CONCATENATE: c_vat                        "Constant
  "                     gs_t001z-paval               "VAT Registration Number
                       lv_output
                       INTO lv_vat SEPARATED BY ' '.
*  **************** ADDED CONCATENATE STATEMENT ************************
          CONCATENATE gs_header-addhdr1 cl_abap_char_utilities=>newline gs_header-addhdr2 cl_abap_char_utilities=>newline lv_vat INTO gs_header-addhdr2. "SEPARATED BY space.
          REPLACE REGEX '\n\s+' IN gs_header-addhdr2 WITH cl_abap_char_utilities=>newline.
        ENDIF.
      ENDIF.
    ENDLOOP.



***Start-Comment by Paul 04-24-2024
*---5 - Billing Office: (6)
*    CLEAR gs_cepct.
*    READ TABLE gt_cepct INTO gs_cepct
*    WITH KEY prctr = gs_acdoca_temp-prctr.
*    IF sy-subrc = 0.
*      MOVE gs_cepct-ltext TO gs_header-billofc.
*    ENDIF.
***End-Comment by Paul 04-24-2024




*---5 - Billing Office: (6)
    READ TABLE gt_billoff INTO gs_billoff
            WITH KEY bukrs = p_rbukrs
             zcounter = p_billto.
    IF sy-subrc = 0.
      MOVE gs_billoff-zpm_low TO gs_header-billofc.
    ENDIF.

*---5 - Document Date: (7)
    IF gs_acdoca_temp-xreversed = ' '.
      lv_day(2)   = gs_acdoca_temp-bldat+6(2).
      lv_month(2) = gs_acdoca_temp-bldat+4(2).
      lv_year(4)  = gs_acdoca_temp-bldat(4).

      CASE lv_month.
        WHEN '01'.
          lv_month = 'JAN'.
        WHEN '02'.
          lv_month = 'FEB'.
        WHEN '03'.
          lv_month = 'MAR'.
        WHEN '04'.
          lv_month = 'APR'.
        WHEN '05'.
          lv_month = 'MAY'.
        WHEN '06'.
          lv_month = 'JUN'.
        WHEN '07'.
          lv_month = 'JUL'.
        WHEN '08'.
          lv_month = 'AUG'.
        WHEN '09'.
          lv_month = 'SEP'.
        WHEN '10'.
          lv_month = 'OCT'.
        WHEN '11'.
          lv_month = 'NOV'.
        WHEN '12'.
          lv_month = 'DEC'.
      ENDCASE.

      CONCATENATE: lv_day lv_month lv_year
      INTO DATA(gv_docdate) SEPARATED BY '-'.
      MOVE gv_docdate TO gs_header-docdate.
    ENDIF.

*---5 - Document No.: (8)
*************CHANGE BY PRIYA*****************
    CASE gv_blart.
      WHEN c_bs.
        gv_formname = c_fbill.
        CONCATENATE 'CH- ' gs_acdoca_temp-belnr
       INTO DATA(gv_docnum).
        MOVE gv_docnum TO gs_header-docnum.
      WHEN c_cm.
        gv_formname = c_fcredit .
        CONCATENATE 'CM- ' gs_acdoca_temp-belnr
          INTO gv_docnum.
        MOVE gv_docnum TO gs_header-docnum.
      WHEN c_dm.
        gv_formname = c_fdebit.
        CONCATENATE 'DM- ' gs_acdoca_temp-belnr
         INTO gv_docnum.
        MOVE gv_docnum TO gs_header-docnum.

    ENDCASE.
****************END OF CHANGE *****************
*       MOVE gv_docnum TO gs_header-docnum.
*---6 - Bill To: (9)
*    DATA gv_billto TYPE string ##NEEDED.

    READ TABLE gt_but000 INTO gs_but000
    WITH KEY partner = gs_acdoca_temp-kunnr.
    IF sy-subrc = 0.
******************for constomer contact person********************
      gs_header-comcontperson = gs_but000-name_first.
***ADDED (APRIL 11,2023 DAGOYAOY)

      gv_group = gs_but000-bu_group.

      READ TABLE i_param5 INTO gs_param5
      WITH KEY bukrs = p_rbukrs
               zpm_high = gv_group.
      IF sy-subrc = 0.
        gv_emailadd = gs_param5-zpm_low.
      ELSE.
        READ TABLE i_param5 INTO gs_param5
        WITH KEY bukrs = p_rbukrs
         zpm_high = ' '.
        IF sy-subrc = 0.
          gv_emailadd = gs_param5-zpm_low.
        ENDIF.
      ENDIF.

*********************************
      IF gs_but000-type = 1.
        CONCATENATE gs_but000-name_first
                    gs_but000-namemiddle
                    gs_but000-name_last
                    INTO gs_header-billto SEPARATED BY space.

      ELSEIF gs_but000-type = 2 OR gs_but000-type = space.
        READ TABLE gt_but020 INTO gs_but020
        WITH KEY partner = gs_acdoca_temp-kunnr.
        IF sy-subrc = 0.

          READ TABLE gt_adrc_billto_add INTO gs_adrc_billto_add
          WITH KEY addrnumber = gs_but020-addrnumber.
          CONCATENATE: gs_adrc_billto_add-name1           "name1
                       gs_adrc_billto_add-name2           "name2
                       gs_adrc_billto_add-name3           "name3
*                       gs_adrc_billto_add-name4           "name4
                       INTO gs_header-billto SEPARATED BY space.
        ENDIF.
      ENDIF.
    ENDIF.

***Start-Modify by Paul 10-19-2022
    DATA(lv_date) = gs_header-docdate.
    REPLACE ALL OCCURRENCES OF '/' IN lv_date  WITH '-'.
    CASE gv_blart.
      WHEN c_bs.
        gv_formname = c_fbill.   "Form Assignment (Billing Statement)
*        CONCATENATE p_path '\' c_pdfinv gs_header-ccode '_' gs_acdoca_temp-gjahr gs_acdoca_temp-belnr '.pdf' INTO full_path.
*        CONCATENATE p_path '\' gs_header-billto '_' gs_header-ccode '.pdf' INTO full_path.
        CONCATENATE p_path '\' c_inv '_' gs_header-billto '_' lv_date '.pdf' INTO full_path.
      WHEN c_cm.
        gv_formname = c_fcredit. "Form Assignment (Credit Memo)
*        CONCATENATE p_path '\' gs_header-billto '_' gs_header-ccode '.pdf' INTO full_path.
        CONCATENATE p_path '\' c_credit '_' gs_header-billto '_' lv_date '.pdf' INTO full_path.
      WHEN c_dm.
        gv_formname = c_fdebit.  "Form Assignment (Debit Memo)
*        CONCATENATE p_path '\' gs_header-billto '_' gs_header-ccode '.pdf' INTO full_path.
        CONCATENATE p_path '\' c_debit '_' gs_header-billto '_' lv_date '.pdf' INTO full_path.
      WHEN OTHERS.
        MESSAGE s002 DISPLAY LIKE 'E'. "M - Invalid document type
        STOP.
    ENDCASE.
***Start-Modify by Paul 10-19-2022

*---6 - TIN (10)
    CLEAR gs_dfkkbptaxnum.
    READ TABLE gt_dfkkbptaxnum INTO gs_dfkkbptaxnum
    WITH KEY partner = gs_acdoca_temp-kunnr.
    IF sy-subrc = 0.
      DATA(lv_tin) = gs_dfkkbptaxnum-taxnum.
      CONCATENATE lv_tin+0(3) c_dash lv_tin+3(3) c_dash lv_tin+6(3) c_dash lv_tin+9(3) INTO DATA(gv_tinnum).
      MOVE gv_tinnum TO gs_header-tinnum.
      "      REPLACE ALL OCCURRENCES OF '-' IN gs_header-tinnum WITH ''.
    ENDIF.


*---7 - Address (12)
    READ TABLE gt_but020 INTO gs_but020
    WITH KEY partner = gs_acdoca_temp-kunnr.

    IF sy-subrc EQ 0.
      READ TABLE gt_adrc_billto_add INTO gs_adrc_billto_add
      WITH KEY addrnumber = gs_but020-addrnumber.
      IF sy-subrc = 0.
        DATA: lv_adrc_add TYPE string.
        CONCATENATE: gs_adrc_billto_add-street           "Street
                     gs_adrc_billto_add-str_suppl1       "Street 2
                     gs_adrc_billto_add-str_suppl2       "Street 3
                     gs_adrc_billto_add-str_suppl3       "Street 4
                     gs_adrc_billto_add-city2            "District
                     gs_adrc_billto_add-city1            "City
                     gs_adrc_billto_add-post_code1       "City postal code
                     INTO lv_adrc_add SEPARATED BY space.
        MOVE lv_adrc_add TO gs_header-address.
      ENDIF.

      READ TABLE gt_adr6 INTO gs_adr6 WITH KEY addrnumber = gs_but020-addrnumber
                                               default = 'X'.
      IF  sy-subrc = 0.
        gs_header-email = gs_adr6-smtp_addr.
      ELSE.
        READ TABLE gt_adr6 INTO gs_adr6 WITH KEY addrnumber = gs_but020-addrnumber.
        IF sy-subrc = 0.
          gs_header-email = gs_adr6-smtp_addr.
        ENDIF.
      ENDIF.
    ENDIF.

*---7 - Business Style (13) ***********************
    LOOP AT gt_acdoca_asterisk INTO gs_acdoca_asterisk
              WHERE kunnr = gs_acdoca_temp-kunnr
              AND nrivr_bukrs = gs_acdoca_temp-rbukrs
              AND gjahr = gs_acdoca_temp-gjahr
              AND belnr = gs_acdoca_temp-belnr.

      REFRESH tdline.
      READ TABLE gt_stxh INTO gs_stxh
        WITH KEY tdname = gs_acdoca_asterisk-kunnr
                 tdid = 'ZBST'.

      IF sy-subrc = 0.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = gs_stxh-tdid
            language                = gs_stxh-tdspras
            name                    = gs_stxh-tdname
            object                  = gs_stxh-tdobject
          TABLES
            lines                   = tdline
          EXCEPTIONS
            id                      = 1
            language                = 2
            name                    = 3
            not_found               = 4
            object                  = 5
            reference_check         = 6
            wrong_access_to_archive = 7
            OTHERS                  = 8.
        IF sy-subrc = 0.
          LOOP AT tdline ASSIGNING FIELD-SYMBOL(<lwa_tline2>).
            IF lv_sgtxt2 IS INITIAL.
              lv_sgtxt2 = <lwa_tline2>-tdline.
            ELSE.
              IF lv_sgtxt2 <> <lwa_tline2>-tdline.
                lv_sgtxt2 = |{ lv_sgtxt2 } { <lwa_tline2>-tdline }|.
              ENDIF.
            ENDIF.
          ENDLOOP.
          MOVE lv_sgtxt2 TO gs_header-busstyle.
        ENDIF.
      ENDIF.
    ENDLOOP.

*------------------------------------------------------------------*
*                Layout in Smartforms Detail
*------------------------------------------------------------------*

    LOOP AT gt_acdoca INTO gs_acdoca WHERE rldnr = '0L' AND
                                          rbukrs = gs_acdoca_temp-rbukrs
                                      AND gjahr = gs_acdoca_temp-gjahr
                                      AND belnr = gs_acdoca_temp-belnr.

*---9 - Description (14)
*IF sy-subrc eq 0.
*    gs_detail-descr = gs_acdoca-sgtxt.
*ENDIF.




      IF gs_acdoca-xreversed = ' '.

        LOOP AT gt_acdoca_asterisk INTO gs_acdoca_asterisk
              WHERE kunnr = gs_acdoca-kunnr
              AND nrivr_bukrs = gs_acdoca_temp-rbukrs
              AND gjahr = gs_acdoca_temp-gjahr
              AND belnr = gs_acdoca_temp-belnr.

          REFRESH tdline2.
          READ TABLE gt_stxh2 INTO gs_stxh2
          WITH KEY tdname = gs_acdoca_asterisk-asterisk_desc.

          IF sy-subrc = 0.
            CALL FUNCTION 'READ_TEXT'
              EXPORTING
                id                      = gs_stxh2-tdid
                language                = gs_stxh2-tdspras
                name                    = gs_stxh2-tdname
                object                  = gs_stxh2-tdobject
              TABLES
                lines                   = tdline2
              EXCEPTIONS
                id                      = 1
                language                = 2
                name                    = 3
                not_found               = 4
                object                  = 5
                reference_check         = 6
                wrong_access_to_archive = 7
                OTHERS                  = 8.
            IF sy-subrc = 0.

              LOOP AT tdline2 ASSIGNING FIELD-SYMBOL(<lwa_tline>).
                IF lv_sgtxt IS INITIAL.
                  lv_sgtxt = <lwa_tline>-tdline.
                ELSE.
                  IF lv_sgtxt <> <lwa_tline>-tdline.
                    lv_sgtxt = |{ lv_sgtxt } { <lwa_tline>-tdline }|.
                  ENDIF.
                ENDIF.
                CONCATENATE gs_acdoca_temp-sgtxt lv_sgtxt INTO
               gs_detail-descr SEPARATED BY space.
              ENDLOOP.
            ENDIF.
          ELSE.
            gs_detail-descr = gs_acdoca_temp-sgtxt.
          ENDIF.
        ENDLOOP.
      ENDIF.


      "Start-Comment by Paul 10/27/2022
**---9 - QTY (15)- UNIT COST (16)
*      IF gs_acdoca-xreversed = ' '.
*        lv_racct = gs_acdoca-racct+2.
*        READ TABLE i_param INTO gs_param WITH KEY zparam_id = 'ZBS_SURPLUS'
*                                                  zpm_low = lv_racct.
*        IF sy-subrc = 0.
*          gv_qty = 1.
*          gv_ucost = gs_acdoca-wsl.
*        ENDIF.
*      ENDIF.
      "End-Comment by Paul 10/27/2022

      "Start-Modify by Paul 10/27/2022
*---9 - QTY (15)
*      GV_QTY = gs_acdoca-docln.
      gv_qty = 1.

*---9 - UNIT COST (16)
      IF gs_acdoca-xreversed = ' '.
        lv_racct = gs_acdoca-racct+2.
        READ TABLE i_param INTO gs_param WITH KEY zparam_id = 'ZBS_SURPLUS'
                                                  zpm_low = lv_racct.
        IF sy-subrc = 0.
*          gv_ucost = gs_acdoca-wsl.
        ELSE.
          IF gv_blart = c_dm.
            READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFIDM_INTRST'
                                                      zpm_low = lv_racct.
            IF sy-subrc = 0.
              gv_ucost = gs_acdoca-wsl.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      "End-Modify by Paul 10/27/2022

*---9 - VAT (17)
      IF gs_acdoca-xreversed = ' ' AND gs_acdoca-ktosl = 'MWS'
                                   OR gs_acdoca-ktosl = 'VST'.      "Added by Paul 07/23/2023
*      OR gs_acdoca-xreversed = ' ' AND gs_acdoca-ktosl = 'VST'. "ADDITIONAL 07/13/2023
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
                                                    zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          gv_vat = gs_acdoca-wsl + gv_vat.
        ENDIF.
      ENDIF.

*---Due Date (18)
      IF gs_acdoca-koart = 'D'.
        lv_daydue(2)   = gs_acdoca-netdt+6(2).
        lv_monthdue(2) = gs_acdoca-netdt+4(2).
        lv_yeardue(4)  = gs_acdoca-netdt(4).

        CASE lv_monthdue.
          WHEN '01'.
            lv_monthdue = 'JAN'.
          WHEN '02'.
            lv_monthdue = 'FEB'.
          WHEN '03'.
            lv_monthdue = 'MAR'.
          WHEN '04'.
            lv_monthdue = 'APR'.
          WHEN '05'.
            lv_monthdue = 'MAY'.
          WHEN '06'.
            lv_monthdue = 'JUN'.
          WHEN '07'.
            lv_monthdue = 'JUL'.
          WHEN '08'.
            lv_monthdue = 'AUG'.
          WHEN '09'.
            lv_monthdue = 'SEP'.
          WHEN '10'.
            lv_monthdue = 'OCT'.
          WHEN '11'.
            lv_monthdue = 'NOV'.
          WHEN '12'.
            lv_monthdue = 'DEC'.
        ENDCASE.

        CONCATENATE: lv_daydue lv_monthdue lv_yeardue
        INTO DATA(gv_duedate) SEPARATED BY '-'.
        MOVE gv_duedate TO gs_header-duedate.
        CLEAR: lv_daydue, lv_monthdue, lv_yeardue.
      ENDIF.

*---9 - TOTAL AMOUNT (19)
      IF gs_acdoca-xreversed = ' '.
        lv_racct2 = gs_acdoca-racct+2.
        READ TABLE i_param INTO gs_param WITH KEY zparam_id = 'ZBS_SURPLUS'
                                                  zpm_low = lv_racct2.
        IF sy-subrc = 0.
          gv_currency = gs_acdoca-rwcur.
          gv_tamount = gs_acdoca-wsl + gv_tamount.
*          gv_qty = gs_acdoca-zuonr.
        ELSEIF gs_acdoca-glaccount_type = 'P'.
          gv_currency = gs_acdoca-rwcur.
          gv_tamount = gs_acdoca-wsl + gv_tamount.
        ELSEIF gs_acdoca-glaccount_type = 'X'.
          READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_BS_GL'
                                                      bukrs = gs_acdoca-rbukrs
                                                      zpm_low = lv_racct2.
          IF sy-subrc = 0.
            gv_currency = gs_acdoca-rwcur.
*Changes made for INC01772 : Charge Invoice Total Amount Invariance for Invoice & CM
*by ARAO on 17/09/2026
*            gv_tamount = gs_acdoca-wsl + gv_tamount.
            IF gs_acdoca-ktosl NE 'MWS' AND gs_acdoca-ktosl NE 'WIT'.
              gv_tamount = gs_acdoca-wsl + gv_tamount.
            ENDIF.
*End of Changes
          ENDIF.
*          CLEAR: gv_qty.
        ELSE.
          IF gv_blart = c_dm.
            READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFIDM_INTRST'
                                                      zpm_low = lv_racct2.
            IF sy-subrc = 0.
              gv_currency = gs_acdoca-rwcur.
              gv_tamount = gs_acdoca-wsl.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

*---13 - VATable Sales (24)
      IF gs_acdoca-glaccount_type = 'P'.
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
                                                    zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          gv_vatsales = gs_acdoca-wsl + gv_vatsales.
        ENDIF.

*---15 - VAT Zero-rated Sales (26)
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_ZERORATED'
                                                    zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          gv_zerosales = gs_acdoca-wsl + gv_zerosales.
        ENDIF.

*---16 - VAT Exempt Sales (27)
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_EXEMPT'
                                                      zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          gv_xmptsales = gs_acdoca-wsl + gv_xmptsales.
        ENDIF.

*---9 - UNIT COST (16)
        "Added by Paul 10/27/2022 for UNIT COST
        gv_ucost = gs_acdoca-wsl + gv_ucost.
      ELSEIF gs_acdoca-glaccount_type = 'X' AND gs_acdoca-ktosl IS INITIAL AND gs_acdoca-kunnr IS INITIAL.
*---13 - VATable Sales (24)
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_BS_GL'
                                                    bukrs = gs_acdoca-rbukrs
                                                    zpm_low = lv_racct2.
        IF sy-subrc = 0.
          READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
                                                      zpm_low = gs_acdoca-mwskz.
          IF sy-subrc = 0.
            gv_vatsales = gs_acdoca-wsl + gv_vatsales.
          ENDIF.
*---15 - VAT Zero-rated Sales (26)
          READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_ZERORATED'
                                                      zpm_low = gs_acdoca-mwskz.
          IF sy-subrc = 0.
            gv_zerosales = gs_acdoca-wsl + gv_zerosales.
          ENDIF.

*---16 - VAT Exempt Sales (27)
          READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_EXEMPT'
                                                        zpm_low = gs_acdoca-mwskz.
          IF sy-subrc = 0.
            gv_xmptsales = gs_acdoca-wsl + gv_xmptsales.
          ENDIF.
          gv_ucost = gs_acdoca-wsl + gv_ucost.

        ENDIF.

      ELSE.
        lv_racct3 = gs_acdoca-racct+2.
*---13 - VATable Sales (24)
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
                                                  zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          IF gv_blart = c_dm.
            READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFIDM_INTRST'
                                                      zpm_low = lv_racct3.
            IF sy-subrc = 0.
              gv_vatsales = gs_acdoca-wsl.
            ENDIF.
          ENDIF.
        ENDIF.

*---15 - VAT Zero-rated Sales (26)
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_ZERORATED'
                                                   zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          IF gv_blart = c_dm.
            READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFIDM_INTRST'
                                                      zpm_low = lv_racct3.
            IF sy-subrc = 0.
              gv_zerosales = gs_acdoca-wsl.
            ENDIF.
          ENDIF.
        ENDIF.

*---16 - VAT Exempt Sales (27)
        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_EXEMPT'
                                                              zpm_low = gs_acdoca-mwskz.
        IF sy-subrc = 0.
          IF gv_blart = c_dm.
            READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFIDM_INTRST'
                                                      zpm_low = lv_racct3.
            IF sy-subrc = 0.
              gv_xmptsales = gs_acdoca-wsl.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
*---14 - VAT (12%) (25)
*      IF gs_acdoca-ktosl = 'MWS' OR gs_acdoca-ktosl = 'VST'.      "Added by Paul 07/23/2023.
*        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
*                                                    zpm_low = gs_acdoca-mwskz.
*        IF sy-subrc = 0.
*          gv_vat12 = gs_acdoca-wsl + gv_vat12.
*        ENDIF.
*      ENDIF.

*VAT on Local Sales
      LOOP AT gt_acdoca_vat INTO DATA(wa_vat) WHERE rbukrs = gs_acdoca-rbukrs
                                                AND gjahr  = gs_acdoca-gjahr
                                                AND belnr  = gs_acdoca-belnr
                                                AND blart  = 'DR'
                                                AND ktosl  = gs_acdoca-ktosl
                                                AND mwskz  = gs_acdoca-mwskz
                                                AND racct  = gs_acdoca-racct.
*        IF sy-subrc = 0.
        IF wa_vat-ktosl = 'MWS'.
          READ TABLE i_peza_param INTO DATA(wa_peza) WITH KEY zparam_id = 'ZFI_PEZA_MWSKZ'
                                                              zpm_low = wa_vat-mwskz.
          IF sy-subrc = 0.
            gv_vatlocal = wa_vat-wsl + gv_vatlocal.
          ENDIF.
        ELSEIF wa_vat-ktosl = 'WIT'.
          READ TABLE i_peza_param INTO wa_peza WITH KEY zparam_id = 'ZFI_PEZA_GL'
                                                              bukrs = wa_vat-rbukrs
                                                              zpm_low = wa_vat-racct.
          IF sy-subrc = 0.
            gv_vatlocal_bir = wa_vat-wsl + gv_vatlocal_bir.
          ENDIF.
        ENDIF.
*        ENDIF.
      ENDLOOP.

*---14 - VAT (12%) (25)
      READ TABLE i_peza_param INTO wa_peza WITH KEY zparam_id = 'ZFI_PEZA_MWSKZ'
                                                    zpm_low = gs_acdoca-mwskz.
      IF sy-subrc NE 0.
        IF gs_acdoca-ktosl = 'MWS' OR gs_acdoca-ktosl = 'VST'.      "Added by Paul 07/23/2023.
          READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
                                                      zpm_low = gs_acdoca-mwskz.
          IF sy-subrc = 0.
            gv_vat12 = gs_acdoca-wsl + gv_vat12.
          ENDIF.
        ENDIF.
      ENDIF.
*End of Changes
    ENDLOOP.

*---- Move Details in Internal Table
*    IF lv_vat2 = abap_true.
    gv_tamount = gv_tamount + gv_vat.
    gv_tamtdec = gv_tamount.

*---- QTY (15)
    MOVE gv_qty TO gs_detail-qty.

*---- TOTAL AMOUNT (19) currency
    MOVE gv_currency TO gs_detail-currency.

*----15  cwt
    SELECT SUM( w~wt_qbshb )
      FROM with_item AS w
      INNER JOIN zglbparam AS z
        ON z~zpm_low = w~witht
    WHERE z~zparam_id = 'ZFI_WHT'
       AND w~bukrs     = @gs_acdoca-rbukrs
       AND w~belnr     = @gs_acdoca-belnr
       AND w~gjahr     = @gs_acdoca-gjahr
       AND w~wt_withcd IS NOT INITIAL   INTO @lv_cwt1.

    IF sy-subrc = 0 AND lv_cwt1 IS NOT INITIAL.
      gv_cwt = gv_cwt + lv_cwt1.
      gs_header-cwt = gv_cwt.
      WRITE: gv_cwt CURRENCY gv_currency TO gs_header-cwt.
      CONDENSE gs_header-cwt.
    ELSEIF lv_cwt1 IS INITIAL.
      gv_cwt = '0.00'.
      gs_header-cwt = gv_cwt.
      CONDENSE  gs_header-cwt.
    ENDIF.

*---- TOTAL AMOUNT (19) tamount

*###################################################################################################*
*CONDITION FOR CURRENCY *****************************************************************************
*###################################################################################################*

    lv_tamtdec = gv_tamtdec. "TOTAL AMOUNT
    CONDENSE lv_tamtdec.

    REPLACE ALL OCCURRENCES OF '-' IN lv_tamtdec WITH space. "REMOVE (-)

***amount due
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 18/08/2026
*    lv_dueamount = lv_tamtdec - gv_cwt.
    lv_dueamount = lv_tamtdec - gv_cwt - gv_vatlocal_bir.
*End of Changes
    WRITE lv_dueamount TO gs_header-amountdue CURRENCY gv_currency.
    "    gs_header-amountdue =  lv_dueamount.
    CONDENSE gs_header-amountdue.
    gs_header-amountdue_conv = gs_header-amountdue.

    CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
      EXPORTING
        currency        = gv_currency
        amount_internal = lv_tamtdec
      IMPORTING
        amount_external = lv_tamount.

    lv_convertamt1 = lv_tamtdec. "UNCOVERTED VALUE
    lv_convertamt2 = lv_tamount. "CONVERTED VALUE

*###################################################################################################*
*CURRENCY (UNCONVERTED VALUE)************************************************************************
*###################################################################################################*

    IF lv_convertamt1 EQ lv_convertamt2.
      gv_tamtdec = lv_tamtdec.
      WRITE gv_tamtdec TO gs_detail-tamount.

*---- UNIT COST (16)
      lv_ucostdesc = gv_ucost.
      REPLACE ALL OCCURRENCES OF '-' IN lv_ucostdesc WITH ' '.
      gv_ucost = lv_ucostdesc.
      WRITE gv_ucost TO gs_detail-ucost ##UOM_IN_MES.

*---- VAT (17)
      lv_vatdesc = gv_vat.
      REPLACE ALL OCCURRENCES OF '-' IN lv_vatdesc WITH ' '.
      gv_vat = lv_vatdesc.
      WRITE gv_vat TO gs_detail-vat ##UOM_IN_MES.

*---10 - TOTAL AMOUNT IN FIGURES (20)
      WRITE gv_tamtdec TO gs_header-tamtfigure ##UOM_IN_MES.
      CONDENSE gs_header-tamtfigure.

*      WRITE gv_duedec TO gs_header-amountdue.
*---10 - TOTAL AMOUNT IN WORDS: (21)

*      READ TABLE gt_tcurt INTO gs_tcurt
*      WITH KEY spras = 'E'
*               waers = gs_acdoca-rwcur.
*      IF sy-subrc = 0.
*        lv_tcurr = gs_tcurt-ktext.
*        TRANSLATE lv_tcurr TO UPPER CASE.
*      ENDIF.

      gv_col19 = gv_tamount.
      MOVE gv_col19 TO gv_col19_char.
      SPLIT gv_col19_char AT '.' INTO lv_var1 lv_var2.
      CONDENSE lv_var1.
      MOVE lv_var1 TO gv_var1_int.

      PERFORM convert_to_words.

      REPLACE ALL OCCURRENCES OF 'BILLIONS' IN gv_rword-word WITH 'BILLION'.
      REPLACE ALL OCCURRENCES OF '-' IN lv_var2 WITH ' '.
*      CONCATENATE: gv_rword-word lv_tcurr 'AND' lv_var2 INTO lv_concat_word SEPARATED BY space.
      CONCATENATE: gs_acdoca-rwcur ':' gv_rword-word 'AND' lv_var2 INTO lv_concat_word SEPARATED BY space.

      gv_tamtwords = lv_concat_word && '/100 ONLY'.

      MOVE gv_tamtwords TO gs_header-tamtwords.

*--- ASSIGN DATA
      lv_vatsales = gv_vatsales.                                "VATable Sales (24)
      REPLACE ALL OCCURRENCES OF '-' IN lv_vatsales WITH ' '.
      gv_vatsales = lv_vatsales.
      WRITE gv_vatsales TO gs_header-vatsales ##UOM_IN_MES.
      CONDENSE gs_header-vatsales.

      lv_vat12 = gv_vat12.                                      "VAT (12%) (25)
      REPLACE ALL OCCURRENCES OF '-' IN lv_vat12 WITH ' '.
      gv_vat12 = lv_vat12.
      WRITE gv_vat12 TO gs_header-vat12 ##UOM_IN_MES.
      CONDENSE gs_header-vat12.

      lv_zerosales = gv_zerosales.                              "VAT Zero-rated Sales (26)
      REPLACE ALL OCCURRENCES OF '-' IN lv_zerosales WITH ' '.
      gv_zerosales = lv_zerosales.
      WRITE gv_zerosales TO gs_header-zerosales ##UOM_IN_MES.
      CONDENSE gs_header-zerosales.

      lv_xmptsales = gv_xmptsales.                              "VAT Exempt Sales (27)
      REPLACE ALL OCCURRENCES OF '-' IN lv_xmptsales WITH ' '.
      gv_xmptsales = lv_xmptsales.
      WRITE gv_xmptsales TO gs_header-xmptsales ##UOM_IN_MES.
      CONDENSE gs_header-xmptsales.

*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026

      lv_locsales = gv_vatlocal.                              "VAT Local Sales
      REPLACE ALL OCCURRENCES OF '-' IN lv_locsales WITH ' '.
      gv_vatlocal = lv_locsales.
      WRITE gv_vatlocal TO gs_header-vatlocal ##UOM_IN_MES.
      CONDENSE gs_header-vatlocal.

      lv_locsalesbir = gv_vatlocal_bir.                              "VAT Local Sales(Due to BIR)
      REPLACE ALL OCCURRENCES OF '-' IN lv_locsalesbir WITH ' '.
      gv_vatlocal_bir = lv_locsalesbir.
      WRITE gv_vatlocal_bir TO gs_header-vatlocalbir ##UOM_IN_MES.
      CONDENSE gs_header-vatlocalbir.

*End of Changes

*---17 - TOTAL (28)
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
*      gv_vattotal = gv_vatsales + gv_vat12 + gv_zerosales + gv_xmptsales.
      gv_vattotal = gv_vatsales + gv_vat12 + gv_zerosales + gv_xmptsales + gv_vatlocal.
*End of Changes
      lv_vattotal = gv_vattotal.
      REPLACE ALL OCCURRENCES OF '-' IN lv_vattotal WITH ' '.
      gv_vattotal = lv_vattotal.
*      gv_vattotal = gv_vattotal - gv_wt_qbshb.
      WRITE gv_vattotal TO gs_header-total ##UOM_IN_MES.
      CONDENSE gs_header-total.

*###################################################################################################*
*CURRENCY (CONVERTED VALUE)**************************************************************************
*###################################################################################################*

    ELSE.
      lv_tamountstr = lv_tamount.
      CONDENSE lv_tamountstr.

      SPLIT lv_tamountstr AT '.' INTO lv_tamount1 lv_tamount2.
      lv_tamount1cnv = lv_tamount1.
      gv_amountcnv = trunc( lv_tamount1cnv ).
      WRITE gv_amountcnv TO gs_detail-tamount.

*---- UNIT COST (16)
      lv_ucostdesc = gv_ucost.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_ucostdesc
        IMPORTING
          amount_external = gv_ucost_cnv.

      lv_ucost_str = gv_ucost_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_ucost_str WITH space.

      SPLIT lv_ucost_str AT '.' INTO lv_ucost_1 lv_ucost_2.
      lv_ucost_cnv = lv_ucost_1.
      gv_ucost_i = trunc( lv_ucost_cnv ).
      WRITE gv_ucost_i TO gs_detail-ucost ##UOM_IN_MES.

*---- VAT (17)
      lv_vatdesc = gv_vat.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_vatdesc
        IMPORTING
          amount_external = gv_vat_cnv.

      lv_vat_str = gv_vat_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_vat_str WITH space.

      SPLIT lv_vat_str AT '.' INTO lv_vat_1 lv_vat_2.
      lv_vat_cnv = lv_vat_1.
      gv_vat_i = trunc( lv_vat_cnv ).
      WRITE gv_vat_i TO gs_detail-vat ##UOM_IN_MES.

*---10 - TOTAL AMOUNT IN FIGURES (20)
      WRITE gv_amountcnv TO gs_header-tamtfigure ##UOM_IN_MES.

*---10 - TOTAL AMOUNT IN WORDS: (21)

*      READ TABLE gt_tcurt INTO gs_tcurt
*      WITH KEY spras = 'E'
*               waers = gs_acdoca-rwcur.
*      IF sy-subrc = 0.
*       LIT gv_col19_char AT '.' INTO lv_var1 lv_var2.
      CONDENSE lv_var1.
      MOVE lv_var1 TO gv_var1_int.

      PERFORM convert_to_words. lv_tcurr = gs_tcurt-ktext.
*        TRANSLATE lv_tcurr TO UPPER CASE.
*      ENDIF.

      gv_col19 = gv_tamount.

      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = gv_col19
        IMPORTING
          amount_external = gv_col19_cnv.

      MOVE gv_col19_cnv TO gv_col19_char.

**      REPLACE ALL OCCURRENCES OF 'BILLIONS' IN gv_rword-word WITH 'BILLION'.
**      CONCATENATE: gv_rword-word lv_tcurr INTO lv_concat_word SEPARATED BY space.
**      CONCATENATE: gs_acdoca-rwcur ':' gv_rword-word INTO lv_concat_word SEPARATED BY space.
**      gv_tamtwords = lv_concat_word.
**
**      MOVE gv_tamtwords TO gs_header-tamtwords.

*--- ASSIGN DATA
*VATable Sales (24)
      lv_vatsales = gv_vatsales.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_vatsales
        IMPORTING
          amount_external = gv_vatsales_cnv.

      lv_vatsales_str = gv_vatsales_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_vatsales_str WITH space.

      SPLIT lv_vatsales_str AT '.' INTO lv_vatsales_1 lv_vatsales_2.
      lv_vatsales_cnv = lv_vatsales_1.
      gv_vatsales_i = trunc( lv_vatsales_cnv ).
      WRITE gv_vatsales_i TO gs_header-vatsales ##UOM_IN_MES.

*VAT (12%) (25)
      lv_vat12 = gv_vat12.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_vat12
        IMPORTING
          amount_external = gv_vat12_cnv.

      lv_vat12_str = gv_vat12_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_vat12_str WITH space.

      SPLIT lv_vat12_str AT '.' INTO lv_vat12_1 lv_vat12_2.
      lv_vat12_cnv = lv_vat12_1.
      gv_vat12_i = trunc( lv_vat12_cnv ).
      WRITE gv_vat12_i TO gs_header-vat12 ##UOM_IN_MES.

*VAT Zero-rated Sales (26)
      lv_zerosales = gv_zerosales.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_zerosales
        IMPORTING
          amount_external = gv_zerosales_cnv.

      lv_zerosales_str = gv_zerosales_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_zerosales_str WITH space.

      SPLIT lv_zerosales_str AT '.' INTO lv_zerosales_1 lv_zerosales_2.
      lv_zerosales_cnv = lv_zerosales_1.
      gv_zerosales_i = trunc( lv_zerosales_cnv ).
      WRITE gv_zerosales_i TO gs_header-zerosales ##UOM_IN_MES.

*VAT Exempt Sales (27)
      lv_xmptsales = gv_xmptsales.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_xmptsales
        IMPORTING
          amount_external = gv_xmptsales_cnv.

      lv_xmptsales_str = gv_xmptsales_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_xmptsales_str WITH space.

      SPLIT lv_xmptsales_str AT '.' INTO lv_xmptsales_1 lv_xmptsales_2.
      lv_xmptsales_cnv = lv_xmptsales_1.
      gv_xmptsales_i = trunc( lv_xmptsales_cnv ).
      WRITE gv_xmptsales_i TO gs_header-xmptsales ##UOM_IN_MES.

*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
*VAT on Local Sales
      lv_locsales = gv_vatlocal.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_locsales
        IMPORTING
          amount_external = gv_vatlocal_cnv.

      lv_locsales_str = gv_vatlocal_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_locsales_str WITH space.

      SPLIT lv_locsales_str AT '.' INTO lv_locsales_1 lv_locsales_2.
      lv_locsales_cnv = lv_locsales_1.
      gv_vatlocal_i = trunc( lv_locsales_cnv ).
      WRITE gv_vatlocal_i TO gs_header-vatlocal ##UOM_IN_MES.

*VAT on Local Sales(Due to BIR)
      lv_locsalesbir = gv_vatlocal_bir.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL' "GET UNCONVERTED
        EXPORTING
          currency        = gv_currency
          amount_internal = lv_locsalesbir
        IMPORTING
          amount_external = gv_vatlocalbir_cnv.

      lv_locsalesbir_str = gv_vatlocalbir_cnv.
      REPLACE ALL OCCURRENCES OF '-' IN lv_locsalesbir_str WITH space.

      SPLIT lv_locsalesbir_str AT '.' INTO lv_locsalesbir_1 lv_locsalesbir_2.
      lv_locsalesbir_cnv = lv_locsalesbir_1.
      gv_vatlocalbir_i = trunc( lv_locsalesbir_cnv ).
      WRITE gv_vatlocalbir_i TO gs_header-vatlocalbir ##UOM_IN_MES.
*End of Changes

*---17 - TOTAL (28)
*Changes made for INC01120: PEZA address and branch TIN on invoice
*by ARAO on 13/08/2026
*      lv_vattotal_cnv = gv_vatsales_i + gv_vat12_i + gv_zerosales_i + gv_xmptsales_i.
      lv_vattotal_cnv = gv_vatsales_i + gv_vat12_i + gv_zerosales_i + gv_xmptsales_i + gv_vatlocal_i.
*End of Changes
      gv_vattotal_i = trunc( lv_vattotal_cnv ).
      WRITE gv_vattotal_i TO gs_header-total ##UOM_IN_MES.

*################################################################################################*

    ENDIF.
    APPEND gs_detail TO gt_detail.
    CLEAR: gs_detail-descr.

*################################################################################################*

*---14 - Certified Correct By: (22)
    READ TABLE gt_zsigntab INTO gs_zsigntab
    WITH KEY user_id = gs_acdoca-usnam.
    IF sy-subrc = 0.

      lv_day(2) = sy-datum+6(2).
      lv_month(2) = sy-datum+4(2).
      lv_year(4) =  sy-datum(4).
      CONCATENATE: lv_day lv_month lv_year INTO DATA(lv_currdate) SEPARATED BY '/'.
      CONCATENATE: gs_zsigntab-mi '.' INTO gs_zsigntab-mi.
      CONCATENATE: '-' gs_zsigntab-zposition INTO gs_zsigntab-zposition SEPARATED BY ' '.

      CONCATENATE: gs_zsigntab-firstname gs_zsigntab-lastname INTO gs_header-preparedby SEPARATED BY ' '.
      "      MOVE gs_zsigntab-user_id TO gs_header-preparedby.
      MOVE gs_zsigntab-esignature TO gs_header-sign.
      MOVE gs_zsigntab-firstname TO gs_header-fname.
      MOVE gs_zsigntab-mi TO gs_header-miname.
      MOVE gs_zsigntab-lastname TO gs_header-lname.
      MOVE lv_currdate TO gs_header-currdate.
      MOVE gs_zsigntab-zposition TO gs_header-aposition.
    ELSE.
      gs_zsigntab-esignature = 'NOSIGN'.
      MOVE gs_zsigntab-esignature TO gs_header-sign.
    ENDIF.


    CLEAR: gv_vatsales,
          gv_vat12,
          gv_zerosales,
          gv_xmptsales,
          gv_vatlocal,
          gv_vatlocal_bir,
          gv_vattotal,
          gv_qty,
          gv_ucost,
          gv_vat,
          gv_tamtdec,
          lv_daydue,
          lv_monthdue,
          lv_yeardue,
          lv_sgtxt2,
          gv_tamount.

*--- Bank INFO --- Start - Modify by Paul 4/13/2023
    IF gs_acdoca_temp-hbkid IS NOT INITIAL.

      LOOP AT gt_bnka INTO gs_bnka.
*---17 - Name of Bank (30)
        MOVE gs_bnka-banka TO gs_header-bankname.

*---20 - Swift Code (33)
        MOVE gs_bnka-swift TO gs_header-swfcode.

*---21 - Bank Code(34)
        MOVE gs_bnka-bnklz TO gs_header-bnkcode.
      ENDLOOP.

*---18 - Account Name (31)
      READ TABLE gt_t001acname INTO gs_t001acname
      WITH KEY bukrs = gs_acdoca_temp-rbukrs.
      IF sy-subrc = 0.
        MOVE gs_t001acname-butxt TO gs_header-accname.
      ENDIF.

*---19 - Account Number (32)
      READ TABLE gt_t012k INTO gs_t012k
      WITH KEY bukrs = gs_acdoca_temp-rbukrs
               hbkid = gs_acdoca_temp-hbkid
               hktid = gs_acdoca_temp-hktid.
      IF sy-subrc = 0.
        CONCATENATE gs_t012k-bankn+0(4) c_dash gs_t012k-bankn+4(4) c_dash gs_t012k-bankn+8(4) INTO DATA(gv_bankn).
        CONCATENATE gs_t012k-waers gv_bankn INTO DATA(gv_accnum) SEPARATED BY ' '.
        MOVE gv_accnum TO gs_header-accnum.
      ENDIF.

    ELSE.               "If hbkid and hktid has no value.

      LOOP AT gt_bnkabh INTO gs_bnkabh.
*---17 - Name of Bank (30)
        MOVE gs_bnkabh-banka TO gs_header-bankname.

*---20 - Swift Code (33)
        MOVE gs_bnkabh-swift TO gs_header-swfcode.

*---21 - Bank Code(34)
        MOVE gs_bnkabh-bnklz TO gs_header-bnkcode.
      ENDLOOP.

*---18 - Account Name (31)
      READ TABLE gt_t001acnamebh INTO gs_t001acnamebh
      WITH KEY bukrs = gs_acdoca_temp-rbukrs.
      IF sy-subrc = 0.
        MOVE gs_t001acnamebh-butxt TO gs_header-accname.
      ENDIF.
    ENDIF.
*--- Bank INFO --- End - Modify by Paul 4/13/2023

*---19 - Account Number (32)
    READ TABLE gt_t012kbh INTO gs_t012kbh
    WITH KEY bukrs = gs_acdoca_temp-rbukrs.
    IF sy-subrc = 0.
      CONCATENATE gs_t012kbh-bankn+0(4) c_dash gs_t012kbh-bankn+4(4) c_dash gs_t012kbh-bankn+8(4) INTO DATA(gv_banknbh).
      CONCATENATE gs_t012kbh-waers gv_banknbh INTO DATA(gv_accnumbh) SEPARATED BY ' '.
      MOVE gv_accnumbh TO gs_header-accnum.
    ENDIF.


*---22 - Acknowledgement Certificate (35)
    READ TABLE i_param INTO gs_param WITH KEY zparam_id = 'ZBIRPTU'
                                                bukrs = gs_acdoca-rbukrs.
    IF sy-subrc = 0.
      MOVE gs_param-zpm_low TO gs_header-ackcert.
    ENDIF.

*---23 - Date Issued (35)
    READ TABLE i_param INTO gs_param WITH KEY zparam_id = 'ZBIRPTUDATE'
                                                bukrs = gs_acdoca-rbukrs.
    IF sy-subrc = 0.
      MOVE gs_param-zpm_low TO gs_header-dateiss.
    ENDIF.


*---24 - Series Range (36)
    LOOP AT gt_acdoca_sr INTO gs_acdoca_sr.
      READ TABLE gt_t003 INTO gs_t003 WITH KEY blart = gs_acdoca_sr-blart.

      IF sy-subrc EQ 0.
        MOVE gs_t003-fromnumber TO gs_header-sfrnum.
        MOVE gs_t003-tonumber TO gs_header-stonum.
      ENDIF.
    ENDLOOP.

    "    DATA: gv_descr TYPE char200.
    DATA(gt_acdoca_temp_1) = gt_acdoca.
    DATA: lt_mwdat         TYPE fm_tt_rtax1u15.
    CLEAR: lv_line.
    DELETE gt_acdoca_temp_1 WHERE mwskz IS INITIAL .
    DELETE gt_acdoca_temp_1 WHERE kunnr IS NOT INITIAL .
    DELETE gt_acdoca_temp_1 WHERE ktosl EQ 'MWS' .
    DELETE gt_acdoca_temp_1 WHERE ktosl EQ 'VST' .
    DESCRIBE TABLE gt_acdoca_temp_1 LINES lv_line.
*IF more than 2 expense line item in document then split the details section
    IF lv_line GT 1.
      CLEAR: gv_descr.
      DATA(gt_detail_1) = gt_detail[].
      REFRESH  gt_detail_1[].
      SELECT mwskz, land1 FROM t030k INTO TABLE @DATA(gt_t030k) FOR ALL ENTRIES IN @gt_acdoca_temp_1
                                                                 WHERE ktopl = 'PHOP' AND mwskz = @gt_acdoca_temp_1-mwskz.
      LOOP AT gt_acdoca_temp_1 INTO  gs_acdoca WHERE rldnr = '0L' AND
                                            rbukrs = gs_acdoca_temp-rbukrs
                                        AND gjahr = gs_acdoca_temp-gjahr
                                        AND belnr = gs_acdoca_temp-belnr.

        IF gs_header-curr1 IS INITIAL.
          gs_header-curr1 = gs_acdoca-rwcur.
        ENDIF.

        " --- Description
        gs_detail-descr = gs_acdoca-sgtxt.

        " --- Quantity fixed as 1
        gv_qty = 1.
        gs_detail-qty = gv_qty.
        CONDENSE gs_detail-qty.

        " --- Unit Cost
        IF gs_acdoca-xreversed = ' '.
          lv_racct = gs_acdoca-racct+2.
          READ TABLE i_param INTO gs_param WITH KEY zparam_id = 'ZBS_SURPLUS'
                                                    zpm_low = lv_racct.
          IF sy-subrc = 0.
            gv_ucost = abs( gs_acdoca-wsl ).
          ELSE.
            IF gv_blart = c_dm.
              READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFIDM_INTRST'
                                                        zpm_low = lv_racct.
              IF sy-subrc = 0.
                gv_ucost = abs( gs_acdoca-wsl ).
              ENDIF.
            ELSE.
              IF gv_blart = c_bs.
                READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_BS_SPLIT'
                                                          zpm_low = lv_racct.
                IF sy-subrc = 0.
                  gv_ucost = abs( gs_acdoca-wsl ).
                ELSE.
                  READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_BS_GL'
                                                              bukrs = gs_acdoca-rbukrs
                                                              zpm_low = lv_racct.
                  IF sy-subrc = 0.
                    gv_ucost = abs( gs_acdoca-wsl ).
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
        "      gs_acdoca-wsl =  ls_split_lin-wsl.
        "      gv_ucost = ls_split_line-wsl.
        gs_detail-ucost = gv_ucost.
        WRITE gv_ucost CURRENCY gv_currency TO gs_detail-ucost.

*---9 - VAT (17)

        IF gs_acdoca-xreversed = ' '  AND gs_acdoca-mwskz IS NOT INITIAL ."AND gs_acdoca-ktosl = 'MWS'.

          "OR gs_acdoca-ktosl = 'VST'.      "Added by Paul 07/23/2023
*      OR gs_acdoca-xreversed = ' ' AND gs_acdoca-ktosl = 'VST'. "ADDITIONAL 07/13/2023
*        READ TABLE i_param2 INTO gs_param2 WITH KEY zparam_id = 'ZFI_TAXABLE'
*                                                    zpm_low = gs_acdoca-mwskz.
*        IF sy-subrc = 0.
*          gv_vat = abs( gs_acdoca-wsl ).
*        ENDIF.
          READ TABLE gt_t030k INTO DATA(ls_t030k)
              WITH KEY mwskz = gs_acdoca-mwskz.
          IF sy-subrc = 0.
            CALL FUNCTION 'Z_CALCULATE_TAX_FRM_NET'
              EXPORTING
                i_bukrs           = gs_acdoca-rbukrs
                i_mwskz           = gs_acdoca-mwskz
                i_waers           = gv_currency
                i_wrbtr           = gv_ucost
                i_lstml           = ls_t030k-land1
              IMPORTING
                e_fwste           = gv_vat
              TABLES
                t_mwdat           = lt_mwdat
              EXCEPTIONS
                bukrs_not_found   = 1
                country_not_found = 2
                mwskz_not_valid   = 3
                mwskz_not_defined = 4
                OTHERS            = 5.
            IF sy-subrc <> 0.
* Implement suitable error handling here
            ENDIF.

            " gv_vat = abs( ls_bset-fwste ).
          ENDIF.
        ENDIF.
        LOOP AT lt_mwdat INTO DATA(gs_mwdat) WHERE msatz LT 0.
          DATA(lv_skip_vat) = abap_true.

        ENDLOOP.
        IF lv_skip_vat EQ abap_false.
          gs_detail-vat = gv_vat.

        ENDIF.
        WRITE gv_vat CURRENCY gv_currency TO gs_detail-vat.
        gv_tamount =   gv_vat + gv_ucost.
        gv_tamount1 = gv_tamount1 + gv_tamount.
        gs_detail-tamount = gv_tamount.
        WRITE gv_tamount CURRENCY gv_currency TO gs_detail-tamount.
        CONDENSE gs_detail-tamount.

        IF gv_vat IS NOT INITIAL OR gv_ucost IS NOT INITIAL.
*        APPEND gs_detail TO gt_detail.
          APPEND gs_detail TO gt_detail_1.
        ENDIF.
        CLEAR: gs_detail, gv_vat, gv_ucost, lv_skip_vat.
        REFRESH: lt_mwdat.
      ENDLOOP.
    ENDIF.

    IF gt_detail_1[] IS NOT INITIAL.
      REFRESH gt_detail[].
      APPEND LINES OF gt_detail_1 TO gt_detail.
    ENDIF.

    IF gv_blart = c_dm.
      IF gv_tamount1 NE gv_tamtdec.
        WRITE gv_tamount1 TO gs_header-tamtfigure ##UOM_IN_MES.
        CONDENSE gs_header-tamtfigure.
        CLEAR:  gv_col19, gv_col19_char, lv_var1, lv_var2, gv_var1_int, lv_concat_word, gv_tamtwords .
        gv_col19 = gv_tamount1.
        MOVE gv_col19 TO gv_col19_char.
        SPLIT gv_col19_char AT '.' INTO lv_var1 lv_var2.
        CONDENSE lv_var1.
        MOVE lv_var1 TO gv_var1_int.

        PERFORM convert_to_words.

        REPLACE ALL OCCURRENCES OF 'BILLIONS' IN gv_rword-word WITH 'BILLION'.
        REPLACE ALL OCCURRENCES OF '-' IN lv_var2 WITH ' '.
*      CONCATENATE: gv_rword-word lv_tcurr 'AND' lv_var2 INTO lv_concat_word SEPARATED BY space.
        CONCATENATE: gs_header-curr1 ':' gv_rword-word 'AND' lv_var2 INTO lv_concat_word SEPARATED BY space.

        gv_tamtwords = lv_concat_word && '/100 ONLY'.

        MOVE gv_tamtwords TO gs_header-tamtwords.



      ENDIF.

    ENDIF.



*------------------------------------------------------------------*
*                        OUTPUT CONDITION
*------------------------------------------------------------------*

    CASE abap_true.

      WHEN rb_view.  "PRINT PREVIEW
        "        PERFORM f_smartform.
        PERFORM f_adobeform.
        PERFORM f_print.

      WHEN rb_print. "PRINT SMARTFORMS
        "        PERFORM f_smartform.\
        PERFORM f_adobeform.
        PERFORM f_print.

      WHEN rb_pdf.   "SAVE AS PDF
        "        PERFORM f_smartform.
        PERFORM f_adobeform.
        PERFORM f_save_file.

      WHEN rb_email. "SEND EMAIL
        "                PERFORM f_smartform.
        PERFORM f_adobeform.
        PERFORM f_send_email.
        "        PERFORM f_send_email_1.


      WHEN cb_late.  "LATE PAYMENT EMAIL NOTE

    ENDCASE.

    CLEAR gs_header.
    CLEAR gt_detail.
    CLEAR gs_param.
    CLEAR lv_blart.
    CLEAR gv_blart.

  ENDLOOP.

*for ALV DISPLAY
  IF rb_email = abap_true.
    PERFORM display_settings.
    PERFORM display_alv_report.
  ENDIF.

ENDFORM.

FORM f_parameter.

  DATA gt_acdoca_par TYPE STANDARD TABLE OF acdoca.
  DATA gs_acdoca_par TYPE acdoca.
  DATA gt_t012k_par  TYPE STANDARD TABLE OF t012k.
  DATA gs_t012k_par  TYPE t012k.

  IF so_belnr-low IS NOT INITIAL.

    SELECT * FROM acdoca INTO TABLE gt_acdoca_par
      WHERE belnr = so_belnr-low AND rbukrs = p_rbukrs AND gjahr = p_gjahr AND kunnr <> ''.
    IF sy-subrc = 0.

      DELETE ADJACENT DUPLICATES FROM gt_acdoca_par COMPARING belnr.

      LOOP AT gt_acdoca_par INTO gs_acdoca_par.
        "Internal table (with data)
*
        IF gs_acdoca_par-hbkid IS NOT INITIAL AND gs_acdoca_par-hktid IS NOT INITIAL.
          p_hbank = gs_acdoca_par-hbkid.
          p_accid = gs_acdoca_par-hktid.

          "Internal table (without data)
        ELSEIF gs_acdoca_par-hbkid IS INITIAL AND gs_acdoca_par-hktid IS INITIAL.
          "Manual Input Ondition
          IF p_hbank IS NOT INITIAL AND p_accid IS INITIAL. "HBANK IS INPUTTED
            SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hbkid = p_hbank.
            IF sy-subrc = 0.
              READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hbkid = p_hbank.
              IF sy-subrc = 0.
                p_accid = gs_t012k_par-hktid.
              ENDIF.
            ENDIF.
          ELSEIF p_hbank IS INITIAL AND p_accid IS NOT INITIAL. "ACCID IS INPUTTED
            SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hktid = p_accid.
            IF sy-subrc = 0.
              READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hktid = p_accid.
              IF sy-subrc = 0.
                p_hbank = gs_t012k_par-hbkid.
              ENDIF.
            ENDIF.
          ELSE.
            IF p_hbank IS NOT INITIAL AND p_accid IS NOT INITIAL.
*              p_hbank = gs_acdoca_par-hbkid.
*              p_accid = gs_acdoca_par-hktid.
              EXIT.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ELSE.
      IF p_hbank IS INITIAL AND p_accid IS INITIAL AND so_belnr-high IS NOT INITIAL.
        SELECT * FROM acdoca INTO TABLE gt_acdoca_par
          WHERE belnr = so_belnr-high AND rbukrs = p_rbukrs AND gjahr = p_gjahr AND kunnr <> ''.
        IF sy-subrc = 0.

          DELETE ADJACENT DUPLICATES FROM gt_acdoca_par COMPARING belnr.

          LOOP AT gt_acdoca_par INTO gs_acdoca_par.
            "Internal table (with data)
            IF gs_acdoca_par-hbkid IS NOT INITIAL AND gs_acdoca_par-hktid IS NOT INITIAL.
              p_hbank = gs_acdoca_par-hbkid.
              p_accid = gs_acdoca_par-hktid.

              "Internal table (without data)
            ELSEIF gs_acdoca_par-hbkid IS INITIAL AND gs_acdoca_par-hktid IS INITIAL.
              "Manual Input Ondition
              IF p_hbank IS NOT INITIAL AND p_accid IS INITIAL. "HBANK IS INPUTTED
                SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hbkid = p_hbank.
                IF sy-subrc = 0.
                  READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hbkid = p_hbank.
                  IF sy-subrc = 0.
                    p_accid = gs_t012k_par-hktid.
                  ENDIF.
                ENDIF.
              ELSEIF p_hbank IS INITIAL AND p_accid IS NOT INITIAL. "ACCID IS INPUTTED
                SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hktid = p_accid.
                IF sy-subrc = 0.
                  READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hktid = p_accid.
                  IF sy-subrc = 0.
                    p_hbank = gs_t012k_par-hbkid.
                  ENDIF.
                ENDIF.
              ELSE.
                p_hbank = gs_acdoca_par-hbkid.
                p_accid = gs_acdoca_par-hktid.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.

      ELSE.
        "Manual Input Ondition
        IF p_hbank IS NOT INITIAL AND p_accid IS INITIAL. "HBANK IS INPUTTED
          SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hbkid = p_hbank.
          IF sy-subrc = 0.
            READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hbkid = p_hbank.
            IF sy-subrc = 0.
              p_accid = gs_t012k_par-hktid.
            ENDIF.
          ENDIF.
        ELSEIF p_hbank IS INITIAL AND p_accid IS NOT INITIAL. "ACCID IS INPUTTED
          SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hktid = p_accid.
          IF sy-subrc = 0.
            READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hktid = p_accid.
            IF sy-subrc = 0.
              p_hbank = gs_t012k_par-hbkid.
            ENDIF.
          ENDIF.
        ELSE.
          SELECT * FROM t012k INTO TABLE gt_t012k_par WHERE hbkid = p_hbank.
          IF sy-subrc = 0.
            READ TABLE gt_t012k_par INTO gs_t012k_par WITH KEY hbkid = p_hbank.
            IF sy-subrc = 0.
              p_accid = gs_t012k_par-hktid.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


********* HIDE AND UNHIDE PARAMETERS *********
  LOOP AT SCREEN.

    IF rb_pdf NE abap_true.
      IF screen-name CS TEXT-004.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

  ENDLOOP.

ENDFORM.


FORM f_billto.

  DATA: g_id       TYPE vrm_id,
        gt_values  TYPE vrm_values,
        gs_values  LIKE LINE OF gt_values,
        lv_counter TYPE i.

  SELECT zparam_id
         zwricef_id
         bukrs
         zcounter
         zprog
         zpm_low
         zpm_high
    FROM zglbparam INTO TABLE gt_billoff
    WHERE zparam_id = 'ZFIBILLOFF'
    AND bukrs = p_rbukrs.

  SORT gt_billoff BY zpm_low.

  IF sy-subrc = 0.
    LOOP AT gt_billoff INTO gs_billoff.
      lv_counter = gs_billoff-zcounter.
      gs_values-key = lv_counter.
      SHIFT gs_values-key LEFT DELETING LEADING space.
      gs_values-text = gs_billoff-zpm_low.
      APPEND gs_values TO gt_values.
      CLEAR gs_values.
    ENDLOOP.
  ENDIF.

  CLEAR lv_counter.

*  IF sy-subrc = 0.
*    LOOP AT gt_billoff INTO gs_billoff.
*      gs_values-key = gs_billoff-zcounter.
*      SHIFT gs_values-key LEFT DELETING LEADING space.
*      gs_values-text = gs_billoff-zpm_low.
*      APPEND gs_values TO gt_values.
*      CLEAR gs_values.
*    ENDLOOP.
*  ENDIF.

  g_id = 'P_BILLTO'.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = g_id
      values = gt_values.

ENDFORM.

FORM f_filepath.

  IF rb_pdf EQ abap_true.

    DATA: lv_fpath TYPE string.

    CONSTANTS c_select_dir TYPE string VALUE 'Select Directory' ##NO_TEXT.

    CALL METHOD cl_gui_frontend_services=>directory_browse
      EXPORTING
        window_title         = c_select_dir
        initial_folder       = 'c:\temp\'
      CHANGING
        selected_folder      = lv_fpath
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4.

********** ASSIGNING PDF FILE NAME ***********
    IF sy-subrc = 0.
      p_path = lv_fpath.
    ENDIF.

  ENDIF.

ENDFORM.

*------------------------------------------------------------------*
*              SMARTFORMS PRINT AND PRINT PREVIEW
*------------------------------------------------------------------*
FORM f_smartform.

*************** GET FORM NAME ****************
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = gv_formname
    IMPORTING
      fm_name            = gv_fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

************** GET DEVICE TYPE ***************
  CALL FUNCTION 'SSF_GET_DEVICE_TYPE'
    EXPORTING
      i_language             = sy-langu
    IMPORTING
      e_devtype              = gv_devtype
    EXCEPTIONS
      no_language            = 1
      language_not_installed = 2
      no_devtype_found       = 3
      system_error           = 4
      OTHERS                 = 5.

  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

******* CONDITION FOR PRINT OPTION *********

*Output Device
  DATA gv_printer TYPE string.

  SELECT bname,
         spld
    FROM usr01
    INTO TABLE @DATA(gt_usr01)
    WHERE bname = @sy-uname.

  READ TABLE gt_usr01 INTO DATA(gv_outdev) WITH KEY bname = sy-uname.
  IF sy-subrc = 0.
    gv_printer = gv_outdev-spld.
  ENDIF.

  CASE abap_true.

    WHEN rb_view.
      gwa_control-device = 'PRINTER'.
      gwa_control-preview = 'X'.
      gwa_control-no_dialog = 'X'.
      gwa_ssfcompop-tddest = gv_printer.
    WHEN rb_print.
      gwa_control-no_dialog = 'X'.
      gwa_ssfcompop-tdimmed = 'X'.
      gwa_ssfcompop-tdnoprev = 'X'.
      gwa_ssfcompop-tddest = gv_printer.
    WHEN rb_pdf.
      gwa_ssfcompop-tdprinter = gv_devtype.
      gwa_control-no_dialog = 'X'.
      gwa_control-getotf = 'X'.
    WHEN rb_email.
      gwa_ssfcompop-tdprinter = gv_devtype.
      gwa_control-no_dialog = 'X'.
      gwa_control-getotf = 'X'.

  ENDCASE.

************* TRIGGER SMARTFORM **************
  CALL FUNCTION gv_fm_name
    EXPORTING
      control_parameters = gwa_control
      output_options     = gwa_ssfcompop
      user_settings      = ' '
      wa_form            = gs_header
    IMPORTING
      job_output_info    = gv_job_output
    TABLES
      it_form2           = gt_detail
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    IF rb_print = abap_true.
      MESSAGE s005. "M - Form is printed.
      EXIT.
    ENDIF.
  ENDIF.

ENDFORM.

*FORM f_print.
*
*  CALL FUNCTION 'SSF_CLOSE'
** IMPORTING
**   JOB_OUTPUT_INFO        =
*    EXCEPTIONS
*      formatting_error = 1
*      internal_error   = 2
*      send_error       = 3
*      OTHERS           = 4.
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.
*
*ENDFORM.




FORM convert_to_words.

  CALL FUNCTION 'SPELL_AMOUNT'
    EXPORTING
*     amount    = gv_col19
      amount    = gv_var1_int
*     CURRENCY  = ' '
*     FILLER    = ' '
      language  = sy-langu
    IMPORTING
      in_words  = gv_rword
    EXCEPTIONS
      not_found = 1
      too_large = 2
      OTHERS    = 3.

  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.

*&----------------------------------------------------------------------------------------------*
*&        CREATE HEADER FOR ALV                                                                      *
*&----------------------------------------------------------------------------------------------*
CLASS lcl_application DEFINITION.

*-------------------CREATE HEADER---------------------*

  PUBLIC SECTION.
    METHODS:
      set_pf_status
        CHANGING
          co_alv TYPE REF TO cl_salv_table.
* SALV TOP HEADER
    METHODS:
      set_top_of_page
        CHANGING
          co_alv TYPE REF TO cl_salv_table.

ENDCLASS.

CLASS lcl_application IMPLEMENTATION.

*-------------------CREATE HEADER---------------------*

  METHOD set_pf_status.

    DATA: lo_functions TYPE REF TO cl_salv_functions_list.
*   Default Functions
    lo_functions = co_alv->get_functions( ).
    lo_functions->set_default( abap_true ).

  ENDMETHOD.                    "set_pf_status

  METHOD set_top_of_page.

*-------------------HEADER LAYOUT---------------------*

    DATA: lo_header  TYPE REF TO cl_salv_form_layout_grid,
          lo_h_label TYPE REF TO cl_salv_form_label,
          lo_h_flow  TYPE REF TO cl_salv_form_layout_flow ##NEEDED.

    CREATE OBJECT lo_header.

    lo_h_label = lo_header->create_label( row = 1 column = 1 ).
    lo_h_label->set_text( TEXT-005 ).


*SET FIXED HEADER SIZE
    lo_h_flow = lo_header->create_flow( row = 2  column = 1 ).

    co_alv->set_top_of_list( lo_header ).

    co_alv->set_top_of_list_print( lo_header ).
*
  ENDMETHOD.                    "set_top_of_page

ENDCLASS.

*&----------------------------------------------------------------------------------------------*
*&        DISPLAY DATA USING ALV                                                                *
*&----------------------------------------------------------------------------------------------*
FORM display_settings.
  DATA: err_message   TYPE REF TO cx_salv_msg ##NEEDED.
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = alv_table
        CHANGING
          t_table      = gt_email ).
      alv_columns = alv_table->get_columns( ).
      PERFORM set_column_name.
    CATCH cx_salv_msg INTO err_message.

      IF gt_email IS INITIAL.
        MESSAGE e005. "No Records Found
        EXIT.
      ENDIF.
  ENDTRY.

  DATA(lo_application) = NEW lcl_application( ).
  CALL METHOD lo_application->set_pf_status
    CHANGING
      co_alv = alv_table.
*
*   Calling the top of page method
  CALL METHOD lo_application->set_top_of_page
    CHANGING
      co_alv = alv_table.


ENDFORM.

FORM display_alv_report.
  alv_columns->set_optimize( ). "optimise the column width
  alv_table->display( ).
ENDFORM.

FORM set_column_name.

*-----------ASSIGNING HEADER NAME FOR SALV------------*

  DATA not_found TYPE REF TO cx_salv_not_found ##NEEDED.
  TRY.
      single_column = alv_columns->get_column( 'STATUS' ).
      single_column->set_long_text( TEXT-006 ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'DOCNUM' ).
      single_column->set_long_text( | { TEXT-007 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'FISCAL' ).
      single_column->set_long_text( | { TEXT-008 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'CCODE' ).
      single_column->set_long_text( | { TEXT-009 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'CNAME' ).
      single_column->set_long_text( | { TEXT-010 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'SENDMAIL' ).
      single_column->set_long_text( | { TEXT-011 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'RECMAIL' ).
      single_column->set_long_text( | { TEXT-012 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

      single_column = alv_columns->get_column( 'MESSAGE' ).
      single_column->set_long_text( | { TEXT-013 } | ).
      single_column->set_medium_text('').
      single_column->set_short_text('').

    CATCH cx_salv_not_found INTO not_found ##NO_HANDLER.
      " error handling
  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_adobeform
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_adobeform .

******* CONDITION FOR PRINT OPTION *********

*Output Device
  DATA gv_printer TYPE string.

  SELECT bname,
         spld
    FROM usr01
    INTO TABLE @DATA(gt_usr01)
    WHERE bname = @sy-uname.

  READ TABLE gt_usr01 INTO DATA(gv_outdev) WITH KEY bname = sy-uname.
  IF sy-subrc = 0.
    gv_printer = gv_outdev-spld.
  ENDIF.

  CASE abap_true.

    WHEN rb_view.
      gs_docparams-device = 'PRINTER'.
      gs_docparams-preview = 'X'.
      gs_docparams-nodialog = 'X'.
      gs_docparams-dest = gv_printer.
    WHEN rb_print.
      gs_docparams-nodialog = 'X'.
      gs_docparams-reqimm = 'X'.
      gs_docparams-nopreview = 'X'.
      gs_docparams-dest = gv_printer.
    WHEN rb_pdf.
      gs_docparams-device = gv_devtype.
      gs_docparams-nodialog = 'X'.
      gs_docparams-getpdf = 'X'.
    WHEN rb_email.
      gs_docparams-device = gv_devtype.
      gs_docparams-nodialog = 'X'.
      gs_docparams-getpdf = 'X'.
*      gs_docparams-preview = 'X'.
  ENDCASE.


  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = gs_docparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
*
  IF sy-subrc <> 0.
    MESSAGE 'Error starting Adobe Form job' TYPE 'E'.
  ENDIF.

  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = gv_formname
    IMPORTING
      e_funcname = gv_funcname.

****************trigger adobe form*********************
  CALL FUNCTION gv_funcname
    EXPORTING
      "     /1bcdwb/docparams  = gs_docparams
      wa_form            = gs_header
      gt_form            = gt_detail
    IMPORTING
      /1bcdwb/formoutput = gv_form_output
    EXCEPTIONS
      usage_error        = 1
      system_error       = 2
      internal_error     = 3
      OTHERS             = 4.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  CALL FUNCTION 'FP_JOB_CLOSE'
*    IMPORTING
*      e_result       = gv_result
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.
FORM f_print.

ENDFORM.
*
FORM f_save_file.
*
*
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = gv_form_output-pdf
*     APPEND_TO_TABLE       = ' '
    IMPORTING
      output_length = gv_size
    TABLES
      binary_tab    = lt_pdf_binary.
  .

  IF p_path IS INITIAL.
    MESSAGE s001 DISPLAY LIKE 'E'. "M - Select Filepath
    STOP.
  ENDIF.

********* CREATE FILE TO LOCAL PATH **********
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      bin_filesize            = gv_size
      filename                = full_path
      filetype                = 'BIN'
    TABLES
      data_tab                = lt_pdf_binary
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.


  IF sy-subrc = 0.
    MESSAGE s006. "M - Form is downloaded.
  ENDIF.

ENDFORM.
FORM f_send_email.

********** VARIABLES FOR EMAIL DATA **********
  DATA: lv_sender          TYPE adr6-smtp_addr,
        lv_recipient_email TYPE ad_smtpadr,
        lv_sender2         TYPE adr6-smtp_addr ##NEEDED,
        lv_cc              TYPE ad_smtpadr,
        lv_subject         TYPE string,
*        lv_message         TYPE bcsy_text.
        lv_message         TYPE soli_tab.

  DATA: bcs_error TYPE REF TO cx_send_req_bcs ##NEEDED.

*#################################################################################################################################################
* EMAIL BODY CONSTANTS
*#################################################################################################################################################


  DATA: gv_email_docdate TYPE string,
        gv_email_duedate TYPE string.

  gv_email_docdate = gs_header-docdate.
  gv_email_duedate = gs_header-duedate.

  SHIFT gv_email_docdate BY 1 PLACES RIGHT.
  SHIFT gv_email_duedate BY 1 PLACES RIGHT.

  CONSTANTS: c_email_1a                   TYPE string VALUE 'Dear <B>Valued Partner,</B><br><br>' ##NO_TEXT,
             c_email_2a                   TYPE string VALUE '<B>Mabuhay!</B><br><br>' ##NO_TEXT,
*             c_email_3a_ebill  TYPE string VALUE 'Please see attached eBilling dated' ##NO_TEXT,
             c_email_3a_ebill             TYPE string VALUE 'Please see attached <B>invoice</B> dated<b>' ##NO_TEXT,
             c_email_3b_ebill             TYPE string VALUE '.</b>' ##NO_TEXT,
             c_email_3a_cm                TYPE string VALUE 'Please see attached <B>credit memo</B> dated<b>' ##NO_TEXT,
             c_email_3b_cm                TYPE string VALUE '.</b>' ##NO_TEXT,
             c_email_3a_dm                TYPE string VALUE 'Please see attached <B>debit memo</B> dated<b>' ##NO_TEXT,
             c_email_3b                   TYPE string VALUE 'To access it, open the attachment and enter your ' ##NO_TEXT,
*            c_email_4a             TYPE string VALUE 'customer code and billing date. For example, 283123415SEP22 (CUSTOMERCODE+DDMMMYY).<br><br>' ##NO_TEXT,
             c_email_4a                   TYPE string VALUE ' customer code and document date. For example, 283123420NOV25 (CUSTOMERCODE+DDMMMYY).<br><br>' ##NO_TEXT,
             c_email_4a_credit            TYPE string VALUE ' customer code and document date. For example, 283123415SEP22 (CUSTOMERCODE+DDMMMYY).<br><br>' ##NO_TEXT,
             c_email_5a                   TYPE string VALUE 'Payment is due on or before <b>' ##NO_TEXT,
             c_email_5b                   TYPE string VALUE '.</b><br><br>' ##NO_TEXT,
             c_email_5aa                  TYPE string VALUE 'To settle your account, kindly remit your payment to the designated bank account indicated below. Any bank ',
             c_email_5ab                  TYPE string VALUE 'charges arising from the remittance should be shouldered by the payor and should not reduce the invoice',
             c_email_5ac                  TYPE string VALUE ' amount.<br><br>',
             c_email_5b_ebill             TYPE string VALUE '<B>For the Local Partners:</B><br><br>',
             "             c_email_5b_ebill       TYPE string VALUE 'You may deposit your payment to the bank account below. Please do not deduct or charge any bank<br>' ##No_TEXT,
             "             c_email_5bb_ebill      TYPE string VALUE 'fees.<br><br>' ##No_TEXT,
             c_email_ebill_detail1        TYPE string VALUE 'Name of the bank:               PHILIPPINE NATIONAL BANK' ##NO_TEXT,
             c_email_ebill_detail1a       TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail2        TYPE string VALUE 'Branch:                         PNB Makati Center' ##NO_TEXT,
             c_email_ebill_detail2a       TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail3        TYPE string VALUE 'Account Name:                   PHILIPPINE AIRLINES, INC.' ##NO_TEXT,
             c_email_ebill_detail3a       TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail4        TYPE string VALUE 'Account Number(USD):            1111-6015-6112' ##NO_TEXT,
             c_email_ebill_detail4a       TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail4aa      TYPE string VALUE 'Account Number (PHP):          1111-7000-2812',
             c_email_ebill_detail4ab      TYPE string VALUE '<br><br>' ##NO_TEXT,
             "             c_email_ebill_detail5  TYPE string VALUE '<b>Currency:</b>' ##NO_TEXT,
             "             c_email_ebill_detail5a TYPE string VALUE '<br>' ##NO_TEXT,
             c_email_ebill_detail6        TYPE string VALUE 'Swift Code:                      PNBMPHMM' ##NO_TEXT,
             c_email_ebill_detail6a       TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail7        TYPE string VALUE 'Bank Code:                    1888' ##NO_TEXT,
             c_email_ebill_detail7a       TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail1palex   TYPE string VALUE 'Name of the bank:               PHILIPPINE NATIONAL BANK' ##NO_TEXT,
             c_email_ebill_detail1apalex  TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail2palex   TYPE string VALUE 'Branch:                         Makati - Allied Bank Center' ##NO_TEXT,
             c_email_ebill_detail2apalex  TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail3palex   TYPE string VALUE 'Account Name:                   PAL express' ##NO_TEXT,
             c_email_ebill_detail3apalex  TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail4palex   TYPE string VALUE 'Account Number(USD):            1111-6015-8361' ##NO_TEXT,
             c_email_ebill_detail4apalex  TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail4aapalex TYPE string VALUE 'Account Number (PHP):           1111-7000-9606',
             c_email_ebill_detail4abpalex TYPE string VALUE '<br><br>' ##NO_TEXT,
             "             c_email_ebill_detail5  TYPE string VALUE '<b>Currency:</b>' ##NO_TEXT,
             "             c_email_ebill_detail5a TYPE string VALUE '<br>' ##NO_TEXT,
             c_email_ebill_detail6palex   TYPE string VALUE 'Swift Code:                      PNBMPHMM</b>' ##NO_TEXT,
             c_email_ebill_detail6apalex  TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail7ab      TYPE string VALUE '<B>For the International Partners:</B>' ##NO_TEXT,
             c_email_ebill_detail7ac      TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail7b       TYPE string VALUE 'Name of the bank:               JPMORGAN CHASE BANK, N.A.' ##NO_TEXT,
             c_email_ebill_detail7ba      TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail7bb      TYPE string VALUE 'Branch:                         JP Morgan New York' ##NO_TEXT,
             c_email_ebill_detail7bc      TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detai17bd      TYPE string VALUE 'Account Name:                   PHILIPPINE AIRLINES, INC.' ##NO_TEXT,
             c_email_ebill_detail7be      TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail7bf      TYPE string VALUE 'Account Number(USD):            949-2-415873' ##NO_TEXT,
             c_email_ebill_detail7bg      TYPE string VALUE '<br><br>' ##NO_TEXT,
*             c_email_ebill_detail7bh      TYPE string VALUE 'Account Number (PHP):           1111-7000-2812',
*             c_email_ebill_detail4bi      TYPE string VALUE '<br><br>' ##NO_TEXT,
             "             c_email_ebill_detail5  TYPE string VALUE '<b>Currency:</b>' ##NO_TEXT,
             "             c_email_ebill_detail5a TYPE string VALUE '<br>' ##NO_TEXT,
             c_email_ebill_detail7bj      TYPE string VALUE 'Swift Code:                     CHASUS33</b>' ##NO_TEXT,
             c_email_ebill_detail7bk      TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail7bl      TYPE string VALUE 'ABA:                            021000021' ##NO_TEXT,
             c_email_ebill_detail7bm      TYPE string VALUE '<br><br>' ##NO_TEXT,
             c_email_ebill_detail8        TYPE string VALUE '<B>For the Partners with a Lockbox Setup (DTP, DSA, Corporate and Government):</B>.<br><br>' ##NO_TEXT,
             c_email_ebill_detail8a       TYPE string VALUE 'Please continue to follow the agreed settlement setup, including the submission of the proof of payment and all necessary supporting reports.<br><br>',
             c_email_ebill_detail8ab      TYPE string VALUE '<b>Important Reminder:</b><br><br>',
             c_email_ebill_detail8bb      TYPE string VALUE 'If payment is not received by the stated due date, a delayed penalty fee, along with any applicable fees',
             c_email_ebill_detail8cc      TYPE string VALUE 'stipulated in the contract, will be applied to the outstanding balance. The total amount due, including',
             c_email_ebill_detail8dd      TYPE string VALUE 'penalties, must be settled immediately upon assessment to avoid further additional charges. <br><br>',
             c_email_ebill_detail9        TYPE string VALUE  'Upon payment (except Partners with a Lockbox Setup), kindly e-mail the proof of payment and the ' ##NO_TEXT,
             c_email_ebill_detail10       TYPE string VALUE  'electronically signed tax certificate, if any, to <b>collections@pal.com.ph</b> using the subject line:<br><br>' ##NO_TEXT,
             c_email_ebill_detail9palex   TYPE string VALUE 'Upon payment, kindly e-mail the proof of payment and the electronically signed tax certificate, if any, to' ##NO_TEXT,
             c_email_ebill_detail10palex  TYPE string VALUE '<b>treas.collection@pal.com.ph</b> using the subject line: <br><br>' ##NO_TEXT,
             c_email_ebill_detail11       TYPE string VALUE 'Payment  [Name of Partner]  [Invoice Number]  [Date of Payment (MM/DD/YYYY)]<br><br>' ##NO_TEXT,
             c_email_ebill_detail12       TYPE string VALUE 'Please acknowledge receipt of this invoice by sending an email to <b>pal_disputes@pal.com.ph,</b> along with any' ##NO_TEXT,
             "          c_email_11a_pal        TYPE string VALUE '<b>Kindly acknowledge receipt by sending email to pal_disputes@pal.com.ph, along with your</b><br>' ##NO_TEXT,
             c_email_11a_palex            TYPE string VALUE 'Please acknowledge receipt of this invoice by sending an email to <b>palex_disputes@pal.com.ph,</b> along with any' ##NO_TEXT,
             c_email_11a_credit           TYPE string VALUE 'Kindly acknowledge receipt of this document by sending an email to <strong>pal_disputes@pal.com.ph,</strong> along with any' ##NO_TEXT,
             c_email_11a_palex_credit     TYPE string VALUE 'Kindly acknowledge receipt of this document by sending an email to <strong>palex_disputes@pal.com.ph, </strong> along with any' ##NO_TEXT,
*             c_email_12a       TYPE string VALUE '<b>questions or clarifications, if any.</b><br><br><br>' ##NO_TEXT,
             c_email_12a                  TYPE string VALUE 'requests, questions or clarifications you may have. If we do not receive a response within seven (7) calendar days' ##NO_TEXT,
             c_email_12aa                 TYPE string VALUE 'from the receipt of this email, the contents of the attached document shall be consider correct,' ##NO_TEXT,
             c_email_12ab                 TYPE string VALUE 'binding, and final.</b><br><br>' ##NO_TEXT,
             c_email_12_credit_ab         TYPE string VALUE 'Once the details have been verified, please provide the specific invoice number to which this credit memo will be applied',
             c_email_12_credit_ac         TYPE string VALUE ' so we can accurately update our records.<br><br>',
             c_email_13a                  TYPE string VALUE 'Thank you for your usual support and cooperation.<br><br><br>' ##NO_TEXT,
             "          c_email_14a            TYPE string VALUE 'Keep safe!<br>' ##NO_TEXT,
             c_email_15a                  TYPE string VALUE '<B>***This is a system-generated email. Please do not reply***</B><br><br>' ##NO_TEXT,
             c_email_16a                  TYPE string VALUE 'Sincerely,<br><br>' ##NO_TEXT,
             c_email_17a_pal              TYPE string VALUE '<b>Philippine Airlines, Inc.</b><br><br><br>' ##NO_TEXT,
             c_email_17a_palex            TYPE string VALUE '<b>Air Philippines Corporation</b><br><br><br>' ##NO_TEXT,
             c_email_latepay1             TYPE string VALUE 'May we remind you that a late payment charge will be assessed by way of penalty for remittances<br>' ##NO_TEXT,
             c_email_latepay2             TYPE string VALUE 'received after the due date as agreed.<br><br>' ##NO_TEXT.


*#################################################################################################################################################

***************************************************************************************************************************
*BILLING STATEMENT (PAL)
***************************************************************************************************************************
  IF gv_formname = c_fbill AND p_rbukrs = c_pr01.

*Subject
    CONCATENATE 'Charge Invoice-'gs_acdoca_temp-belnr'-'gs_header-billto INTO lv_subject SEPARATED BY space.
    CONDENSE lv_subject.

*Body
    APPEND c_email_1a TO lv_message.
    APPEND c_email_2a TO lv_message.
    APPEND c_email_3a_ebill && gv_email_docdate && c_email_3b_ebill TO lv_message. "eBILL
    "    APPEND c_email_4a TO lv_message.
    APPEND c_email_5a && gv_email_duedate && c_email_5b TO lv_message.
    "    APPEND c_email_3b && c_email_4a TO lv_message.
    APPEND c_email_5aa TO lv_message.
    APPEND c_email_5ab TO lv_message.
    APPEND c_email_5ac TO lv_message.
    APPEND c_email_5b_ebill TO lv_message.
    "    APPEND c_email_5bb_ebill TO lv_message.
    APPEND c_email_ebill_detail1 && c_email_ebill_detail1a TO lv_message.
    APPEND c_email_ebill_detail2 && c_email_ebill_detail2a TO lv_message.
    APPEND c_email_ebill_detail3 && c_email_ebill_detail3a TO lv_message.
    APPEND c_email_ebill_detail4  && c_email_ebill_detail4a TO lv_message.
    APPEND c_email_ebill_detail4aa  && c_email_ebill_detail4ab TO lv_message.
    APPEND c_email_ebill_detail6 && c_email_ebill_detail6a TO lv_message.
    APPEND c_email_ebill_detail7 && c_email_ebill_detail7a TO lv_message.
    APPEND c_email_ebill_detail7ab && c_email_ebill_detail7ac TO lv_message.
    APPEND c_email_ebill_detail7b && c_email_ebill_detail7ba TO lv_message.
    APPEND c_email_ebill_detail7bb && c_email_ebill_detail7bc TO lv_message.
    APPEND c_email_ebill_detai17bd && c_email_ebill_detail7be TO lv_message.
    APPEND c_email_ebill_detail7bf && c_email_ebill_detail7bg TO lv_message.
    "    APPEND c_email_ebill_detail7bh && c_email_ebill_detail4bi TO lv_message.
    APPEND c_email_ebill_detail7bj && c_email_ebill_detail7bk TO lv_message.
    APPEND c_email_ebill_detail7bl && c_email_ebill_detail7bm TO lv_message.
    APPEND c_email_ebill_detail8 TO lv_message.
    APPEND c_email_ebill_detail8a TO lv_message.
    APPEND c_email_ebill_detail8ab TO lv_message.
    APPEND c_email_ebill_detail8bb TO lv_message.
    APPEND c_email_ebill_detail8cc TO lv_message.
    APPEND c_email_ebill_detail8dd TO lv_message.
    APPEND c_email_ebill_detail9 TO lv_message.
    APPEND c_email_ebill_detail10 TO lv_message.
    APPEND c_email_ebill_detail11 TO lv_message.
    APPEND c_email_ebill_detail12 TO lv_message.

    IF cb_late EQ abap_true.
      APPEND c_email_latepay1 TO lv_message.
      APPEND c_email_latepay2 TO lv_message.
    ENDIF.

    APPEND c_email_12a TO lv_message.
    APPEND c_email_12aa TO lv_message.
    APPEND c_email_12ab TO lv_message.
    APPEND c_email_13a TO lv_message.
    "    APPEND c_email_14a TO lv_message.
    APPEND c_email_16a TO lv_message.
    APPEND c_email_17a_pal TO lv_message. "PAL'
    APPEND c_email_15a TO lv_message.

*PDF File name
*    CONCATENATE gs_header-billto(40) '_' gs_header-ccode INTO gv_pdfname.

    CONCATENATE  c_inv '_' gs_header-billto(40) '_' gs_header-docdate INTO gv_pdfname.

  ENDIF.
****************************************************************************************************************************

****************************************************************************************************************************
*BILLING STATEMENT (PALEX)
****************************************************************************************************************************
  IF gv_formname = c_fbill AND p_rbukrs = c_2p01.
*Subject
    CONCATENATE 'Charge Invoice-'gs_acdoca_temp-belnr'-'gs_header-billto INTO lv_subject SEPARATED BY space.
    CONDENSE lv_subject.

*Body
    APPEND c_email_1a TO lv_message.
    APPEND c_email_2a TO lv_message.
    APPEND c_email_3a_ebill && gv_email_docdate && c_email_3b_ebill TO lv_message. "eBILL
    "    APPEND c_email_4a TO lv_message.
    APPEND c_email_5a && gv_email_duedate && c_email_5b TO lv_message.
    "    APPEND c_email_3b && c_email_4a TO lv_message.
    APPEND c_email_5aa TO lv_message.
    APPEND c_email_5ab TO lv_message.
    APPEND c_email_5ac TO lv_message.
    APPEND c_email_ebill_detail1palex && c_email_ebill_detail1apalex TO lv_message.
    APPEND c_email_ebill_detail2palex  &&  c_email_ebill_detail2apalex TO lv_message.
    APPEND c_email_ebill_detail3palex  && c_email_ebill_detail3apalex TO lv_message.
    APPEND c_email_ebill_detail4palex  && c_email_ebill_detail4apalex TO lv_message.
    APPEND c_email_ebill_detail4aapalex && c_email_ebill_detail4abpalex TO lv_message.
    APPEND c_email_ebill_detail6 && c_email_ebill_detail6apalex TO lv_message.
    APPEND c_email_ebill_detail8ab TO lv_message.
    APPEND c_email_ebill_detail8bb TO lv_message.
    APPEND c_email_ebill_detail8cc TO lv_message.
    APPEND c_email_ebill_detail8dd TO lv_message.
    APPEND c_email_ebill_detail9palex TO lv_message.
    APPEND c_email_ebill_detail10palex TO lv_message.
    APPEND c_email_ebill_detail11 TO lv_message.
    "    APPEND c_email_ebill_detail12 TO lv_message.

    IF cb_late EQ abap_true.
      APPEND c_email_latepay1 TO lv_message.
      APPEND c_email_latepay2 TO lv_message.
    ENDIF.

    APPEND c_email_11a_palex TO lv_message. "PALEX
    APPEND c_email_12a TO lv_message.
    APPEND c_email_12aa TO lv_message.
    APPEND c_email_12ab TO lv_message.
    APPEND c_email_13a TO lv_message.
    "    APPEND c_email_14a TO lv_message.
    APPEND c_email_16a TO lv_message.
    APPEND c_email_17a_palex TO lv_message. "PALEX
    APPEND c_email_15a TO lv_message.


*PDF File name
    CONCATENATE c_inv '_' gs_header-billto(40) '_' gs_header-docdate INTO gv_pdfname.

  ENDIF.
****************************************************************************************************************************

****************************************************************************************************************************
*CEDIT MEMO (PAL)
****************************************************************************************************************************
  IF gv_formname = c_fcredit AND p_rbukrs = c_pr01.

*Subject
    CONCATENATE 'Credit Memo-'gs_acdoca_temp-belnr'-'gs_header-billto INTO lv_subject SEPARATED BY space.
    CONDENSE lv_subject.

*Body
    APPEND c_email_1a TO lv_message.
    APPEND c_email_2a TO lv_message.
    APPEND c_email_3a_cm && gv_email_docdate &&  c_email_5b  TO lv_message. "CREDIT
    "    APPEND c_email_3b &&  c_email_4a_credit  TO lv_message. "CREDIT
    APPEND c_email_11a_credit TO lv_message.
    APPEND c_email_12a TO lv_message.
    APPEND c_email_12aa TO lv_message.
    APPEND c_email_12ab TO lv_message.
    APPEND c_email_12_credit_ab TO lv_message.
    APPEND c_email_12_credit_ac TO lv_message.
    APPEND c_email_13a TO lv_message.
    "    APPEND c_email_14a TO lv_message.
    APPEND c_email_16a TO lv_message.
    APPEND c_email_17a_pal TO lv_message. "PAL
    APPEND c_email_15a TO lv_message.

*PDF File name
    CONCATENATE c_credit '_' gs_header-billto(40) '_' gs_header-docdate INTO gv_pdfname.

  ENDIF.
****************************************************************************************************************************

****************************************************************************************************************************
*CEDIT MEMO (PALEX)
****************************************************************************************************************************
  IF gv_formname = c_fcredit AND p_rbukrs = c_2p01.

*Subject
    CONCATENATE 'Credit Memo-'gs_acdoca_temp-belnr'-'gs_header-billto INTO lv_subject SEPARATED BY space.
    CONDENSE lv_subject.

*Body
    APPEND c_email_1a TO lv_message.
    APPEND c_email_2a TO lv_message.
    APPEND c_email_3a_cm && gv_email_docdate &&  c_email_5b  TO lv_message. "CREDIT
    "    APPEND c_email_3b &&  c_email_4a_credit  TO lv_message. "CREDIT
    APPEND  c_email_11a_palex_credit TO lv_message.
    APPEND c_email_12a TO lv_message.
    APPEND c_email_12aa TO lv_message.
    APPEND c_email_12ab TO lv_message.
    APPEND c_email_12_credit_ab TO lv_message.
    APPEND c_email_12_credit_ac TO lv_message.
    APPEND c_email_13a TO lv_message.
    "    APPEND c_email_14a TO lv_message.
    APPEND c_email_16a TO lv_message.
    APPEND c_email_17a_palex TO lv_message. "PALEX
    APPEND c_email_15a TO lv_message.

*PDF File name
    CONCATENATE c_credit '_' gs_header-billto(40) '_' gs_header-docdate INTO gv_pdfname.

  ENDIF.
****************************************************************************************************************************

****************************************************************************************************************************
*DEBIT MEMO (PAL)
****************************************************************************************************************************
  IF gv_formname = c_fdebit AND p_rbukrs = c_pr01.

*Subject
    CONCATENATE 'Debit Memo-'gs_acdoca_temp-belnr'-'gs_header-billto INTO lv_subject SEPARATED BY space.
    CONDENSE lv_subject.

*Body
    APPEND c_email_1a TO lv_message.
    APPEND c_email_2a TO lv_message.
    APPEND c_email_3a_dm && gv_email_docdate && c_email_3b_cm TO lv_message. "DEBIT
    APPEND c_email_5a && gv_email_duedate && c_email_5b TO lv_message.
    "    APPEND c_email_3b to lv_message.
    "    APPEND c_email_4a TO lv_message.
    APPEND c_email_5aa TO lv_message.
    APPEND c_email_5ab TO lv_message.
    APPEND c_email_5ac TO lv_message.
    APPEND c_email_5b_ebill TO lv_message.
    "    APPEND c_email_5bb_ebill TO lv_message.
    APPEND c_email_ebill_detail1 && c_email_ebill_detail1a TO lv_message.
    APPEND c_email_ebill_detail2 && c_email_ebill_detail2a TO lv_message.
    APPEND c_email_ebill_detail3 && c_email_ebill_detail3a TO lv_message.
    APPEND c_email_ebill_detail4  && c_email_ebill_detail4a TO lv_message.
    APPEND c_email_ebill_detail4aa  && c_email_ebill_detail4ab TO lv_message.
    APPEND c_email_ebill_detail6 && c_email_ebill_detail6a TO lv_message.
    APPEND c_email_ebill_detail7 && c_email_ebill_detail7a TO lv_message.
    APPEND c_email_ebill_detail7ab && c_email_ebill_detail7ac TO lv_message.
    APPEND c_email_ebill_detail7b && c_email_ebill_detail7ba TO lv_message.
    APPEND c_email_ebill_detail7bb && c_email_ebill_detail7bc TO lv_message.
    APPEND c_email_ebill_detai17bd && c_email_ebill_detail7be TO lv_message.
    APPEND c_email_ebill_detail7bf && c_email_ebill_detail7bg TO lv_message.
    "    APPEND c_email_ebill_detail7bh && c_email_ebill_detail4bi TO lv_message.
    APPEND c_email_ebill_detail7bj && c_email_ebill_detail7bk TO lv_message.
    APPEND c_email_ebill_detail7bl && c_email_ebill_detail7bm TO lv_message.
    APPEND c_email_ebill_detail8 TO lv_message.
    APPEND c_email_ebill_detail8a TO lv_message.
    APPEND c_email_ebill_detail8ab TO lv_message.
    APPEND c_email_ebill_detail8bb TO lv_message.
    APPEND c_email_ebill_detail8cc TO lv_message.
    APPEND c_email_ebill_detail8dd TO lv_message.
    APPEND c_email_ebill_detail9 TO lv_message.
    APPEND c_email_ebill_detail10 TO lv_message.
    APPEND c_email_ebill_detail11 TO lv_message.
    APPEND c_email_ebill_detail12 TO lv_message.

    IF cb_late EQ abap_true.
      APPEND c_email_latepay1 TO lv_message.
      APPEND c_email_latepay2 TO lv_message.
    ENDIF.

    APPEND c_email_12a TO lv_message.
    APPEND c_email_12aa TO lv_message.
    APPEND c_email_12ab TO lv_message.
    APPEND c_email_13a TO lv_message.
    "    APPEND c_email_14a TO lv_message.
    APPEND c_email_16a TO lv_message.
    APPEND c_email_17a_pal TO lv_message. "PAL'
    APPEND c_email_15a TO lv_message.

*PDF File name
    CONCATENATE c_debit '_' gs_header-billto(40) '_' gs_header-docdate INTO gv_pdfname.

  ENDIF.
****************************************************************************************************************************

****************************************************************************************************************************
*DEBIT MEMO (PALEX)
****************************************************************************************************************************
  IF gv_formname = c_fdebit AND p_rbukrs = c_2p01.

*Subject
    CONCATENATE 'Debit Memo-'gs_acdoca_temp-belnr'-'gs_header-billto INTO lv_subject SEPARATED BY space.
    CONDENSE lv_subject.

*Body
    APPEND c_email_1a TO lv_message.
    APPEND c_email_2a TO lv_message.
    APPEND c_email_3a_dm && gv_email_docdate && c_email_3b_ebill TO lv_message. "DEBIT
    APPEND c_email_5a && gv_email_duedate && c_email_5b TO lv_message.
    "    APPEND c_email_3b && c_email_4a TO lv_message.
    APPEND c_email_5aa TO lv_message.
    APPEND c_email_5ab TO lv_message.
    APPEND c_email_5ac TO lv_message.
    APPEND c_email_ebill_detail1palex && c_email_ebill_detail1apalex TO lv_message.
    APPEND c_email_ebill_detail2palex  &&  c_email_ebill_detail2apalex TO lv_message.
    APPEND c_email_ebill_detail3palex  && c_email_ebill_detail3apalex TO lv_message.
    APPEND c_email_ebill_detail4palex  && c_email_ebill_detail4apalex TO lv_message.
    APPEND c_email_ebill_detail4aapalex && c_email_ebill_detail4abpalex TO lv_message.
    APPEND c_email_ebill_detail6 && c_email_ebill_detail6apalex TO lv_message.
    APPEND c_email_ebill_detail8ab TO lv_message.
    APPEND c_email_ebill_detail8bb TO lv_message.
    APPEND c_email_ebill_detail8cc TO lv_message.
    APPEND c_email_ebill_detail8dd TO lv_message.
    APPEND c_email_ebill_detail9palex TO lv_message.
    APPEND c_email_ebill_detail10palex TO lv_message.
    APPEND c_email_ebill_detail11 TO lv_message.
    "    APPEND c_email_ebill_detail12 TO lv_message.

    IF cb_late EQ abap_true.
      APPEND c_email_latepay1 TO lv_message.
      APPEND c_email_latepay2 TO lv_message.
    ENDIF.

    APPEND c_email_11a_palex TO lv_message. "PALEX
    APPEND c_email_12a TO lv_message.
    APPEND c_email_12aa TO lv_message.
    APPEND c_email_12ab TO lv_message.
    APPEND c_email_13a TO lv_message.
    "    APPEND c_email_14a TO lv_message.
    APPEND c_email_16a TO lv_message.
    APPEND c_email_17a_palex TO lv_message. "PALEX
    APPEND c_email_15a TO lv_message.

*PDF File name
    CONCATENATE c_debit '_' gs_header-billto(40) '_' gs_header-docdate INTO gv_pdfname.

  ENDIF.
***************************************************************************************************************************

*********************************************************************************
* EMAIL (PDF ENCRYPTION) Added: 06/20/2023                                      *
*********************************************************************************
  DATA: l_attname     TYPE sood-objdes,
        lt_pdf        TYPE solix_tab,
        lt_body       TYPE soli_tab,
        l_subject     TYPE so_obj_des,
        l_tdname      TYPE thead-tdname,
        l_zipfilename TYPE rcgiedial-iefile,
        l_pdffilename TYPE rcgiedial-iefile,
        l_date_pw     TYPE char10,
        lo_exception  TYPE REF TO cx_document_bcs.
  DATA: l_orln      TYPE drao-orln,
        li_data_tab TYPE STANDARD TABLE OF rcgrepfile,
        l_lines     TYPE i.

  DATA: ld_buffer TYPE xstring,
        lv_orln   TYPE i.

  DATA: content_hex TYPE solix_tab.
  " DATA: content_hex TYPE STANDARD TABLE OF solix.

  DATA:
    lv_objkey            TYPE borident-objkey,
    lt_gos_connections   TYPE STANDARD TABLE OF bdn_con,
    ls_gos_connection    TYPE bdn_con,
    ls_document_data     TYPE sofolenti1,
    lt_object_header     TYPE STANDARD TABLE OF solisti1,
    lt_object_content    TYPE STANDARD TABLE OF solisti1,
    lt_attachment_list   TYPE STANDARD TABLE OF soattlsti1,
    lt_contents_hex      TYPE STANDARD TABLE OF solix,
    lv_filename          TYPE string,
    lv_attachment_type   TYPE so_obj_tp,
    lt_attachment_header TYPE soli_tab,
    lv_document_id       TYPE sofolenti1-doc_id,
    lv_attachment_count  TYPE i VALUE 0.

  REPLACE ALL OCCURRENCES OF '/' IN gv_pdfname WITH '-'.

  DATA(l_filename) = gv_pdfname.
  DATA(l_password) = gv_password.

*   CALL FUNCTION 'CONVERT_OTF' " For Email
*    EXPORTING
*      format                = 'PDF'
*      max_linewidth         = 132
*    IMPORTING
*      bin_filesize          = w_bin_filesize
*    TABLES
*      otf                   = gv_job_output-otfdata
*      lines                 = i_tline
*    EXCEPTIONS
*      err_max_linewidth     = 1
*      err_format            = 2
*      err_conv_not_possible = 3
*      err_bad_otf           = 4.


  DATA(gr_zipper) = NEW cl_abap_zip(  ).
  gr_zipper->add( name    = gv_pdfname
                  content = gv_form_output-pdf ).
  "             content = lv_zip_xstring ).
  DATA(lv_zip_xstring) = gr_zipper->save( ).

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = gv_form_output-pdf
      "buffer        = lv_zip_xstring
*     APPEND_TO_TABLE       = ' '
    IMPORTING
      output_length = gv_size
    TABLES
      "    binary_tab    = i_tline1.
      "     binary_tab    = content_hex.
      binary_tab    = i_tline.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
*  REFRESH : li_content_txt.
*
  PERFORM f_encrypt USING i_tline
*  PERFORM f_encrypt USING i_tline1
*  PERFORM f_encrypt USING content_hex
                l_filename
                l_password
          CHANGING
                l_zipfilename
                l_pdffilename.


  sy-cprog = 'RC1TCG3Y'.
  CALL FUNCTION 'C13Z_RAWDATA_READ'
    EXPORTING
      i_file           = l_pdffilename        "l_zipfilename
*     I_LOG_FILENAME   =
    IMPORTING
      e_file_size      = l_orln
      e_lines          = l_lines
    TABLES
      e_rcgrepfile_tab = li_data_tab
    EXCEPTIONS
      no_permission    = 1
      open_failed      = 2
      read_error       = 3
      path_error       = 4
      OTHERS           = 5.
  sy-cprog = sy-repid.


  CLEAR:ld_buffer,lv_orln.

  lv_orln = l_orln.


  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_orln
    IMPORTING
      buffer       = ld_buffer
    TABLES
      binary_tab   = li_data_tab
    EXCEPTIONS
      failed       = 1.

  "  REFRESH: content_hex[].

  CALL METHOD cl_bcs_convert=>xstring_to_solix
    EXPORTING
      iv_xstring = ld_buffer
"     iv_xstring = gv_form_output-pdf
    RECEIVING
      "      et_solix   = content_hex.
      et_solix   = i_tline.

*********************************************************************************

  CONSTANTS: c_no_email       TYPE string VALUE 'No customer email address maintained' ##NO_TEXT,
             c_email_status_s TYPE string VALUE 'Successful' ##NO_TEXT,
             c_email_status_f TYPE string VALUE 'Failed' ##NO_TEXT,
             c_email_msg_s    TYPE string VALUE 'Email is successfully sent.' ##NO_TEXT,
             c_email_msg_f    TYPE string VALUE 'Failed to send email.' ##NO_TEXT ##NEEDED.

  DATA gv_email_sender TYPE string.

*---Sender Email
  READ TABLE i_param4 INTO gs_param4 WITH KEY zparam_id = 'ZFIEMAILSENDER'
                                              bukrs = gs_acdoca-rbukrs.
  IF sy-subrc = 0.
    MOVE gs_param4-zpm_low TO gv_email_sender.
  ENDIF.


******** SEND EMAIL WITH ATTACHMENT **********

*Changes made for INC01036 to add all the email addresses in TO
*by ARAO on 31/07/2026
*  LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber.
*    IF sy-subrc = 0.
*      gv_elog_recmail = gs_adr6-smtp_addr.
*    ENDIF.
*End of changes

*OTHER EMAIL LOG DATA
  gv_elog_docnum   = gs_header-docnum+8.
  gv_elog_fiscal   = gs_acdoca_temp-gjahr.
  gv_elog_ccode    = gs_header-ccode.
  gv_elog_cname    = gs_header-billto.
  gv_elog_sendmail = gv_email_sender.

************ EMAIL INFORMATION ***************
*SENDER EMAIL
  lv_sender = gv_elog_sendmail.

*RECIEVER EMAIL
*Changes made for INC01036 to add all the email addresses in TO
*by ARAO on 31/07/2026
*    lv_recipient_email = gv_elog_recmail.
*End of changes

  TRY.

*Create Document
      DATA(o_document) = cl_document_bcs=>create_document( i_type    = 'HTM'
                                                           i_text    = lv_message
                                                           i_subject = CONV so_obj_des( lv_subject ) ).

*Create Attachment
      DATA: gv_zipsize TYPE sood-objlen.

      o_document->add_attachment( i_attachment_type = 'PDF'
                                  i_attachment_subject = |{ gv_pdfname }|
       "                           i_att_content_hex = content_hex
                                  i_attachment_size    = gv_zipsize
       "                           i_attachment_size    = gv_size
        "                           i_att_content_hex = content_hex ). "li_content_hex
                                        i_att_content_hex = i_tline ).
      "                                    i_attachment_size    = gv_zipsize ). "li_content_hex

**Logic to add document additional supporting FI document
      CLEAR: lv_objkey.
      CONCATENATE gs_acdoca-rbukrs
                  gs_acdoca-belnr
                  gs_acdoca-gjahr
             INTO lv_objkey.

      CLEAR lt_gos_connections.

      CALL FUNCTION 'BDS_GOS_CONNECTIONS_GET'
        EXPORTING
          classname          = 'BKPF'
          objkey             = lv_objkey
          client             = sy-mandt
        TABLES
          gos_connections    = lt_gos_connections
        EXCEPTIONS
          no_objects_found   = 1
          internal_error     = 2
          internal_gos_error = 3
          OTHERS             = 4.

      IF lt_gos_connections[] IS NOT INITIAL.

        LOOP AT lt_gos_connections INTO ls_gos_connection.

          CLEAR:
            ls_document_data,
            lt_object_header,
            lt_object_content,
            lt_attachment_list,
            lt_contents_hex,
            lv_filename,
            lv_attachment_type,
            lt_attachment_header.

*---------------------------------------------------------------------*
* Get SAPoffice document ID
*---------------------------------------------------------------------*

          lv_document_id =
            CONV sofolenti1-doc_id(
              ls_gos_connection-loio_id ).

*---------------------------------------------------------------------*
* Read SAPoffice/GOS document
*---------------------------------------------------------------------*

          CALL FUNCTION 'SO_DOCUMENT_READ_API1'
            EXPORTING
              document_id                = lv_document_id
            IMPORTING
              document_data              = ls_document_data
            TABLES
              object_header              = lt_object_header
              object_content             = lt_object_content
              attachment_list            = lt_attachment_list
              contents_hex               = lt_contents_hex
            EXCEPTIONS
              document_id_not_exist      = 1
              operation_no_authorization = 2
              x_error                    = 3
              OTHERS                     = 4.

          IF sy-subrc <> 0.

            CONTINUE.

          ENDIF.

*---------------------------------------------------------------------*
* Get original filename
*---------------------------------------------------------------------*

          PERFORM get_filename
            USING lt_object_header
            CHANGING lv_filename.

*---------------------------------------------------------------------*
* Fallback filename
*---------------------------------------------------------------------*

          IF lv_filename IS INITIAL.

            lv_filename = ls_document_data-obj_descr.

          ENDIF.

*---------------------------------------------------------------------*
* Determine attachment type
*---------------------------------------------------------------------*

          lv_attachment_type = ls_document_data-obj_type.

          IF lv_attachment_type IS INITIAL.

            PERFORM get_attachment_type
              USING lv_filename
              CHANGING lv_attachment_type.

          ENDIF.

*---------------------------------------------------------------------*
* If type is still unknown use BIN
*---------------------------------------------------------------------*

          IF lv_attachment_type IS INITIAL.

            lv_attachment_type = 'BIN'.

          ENDIF.

*---------------------------------------------------------------------*
* Build attachment header
* This preserves the original filename.
*---------------------------------------------------------------------*

          APPEND |&SO_FILENAME={ lv_filename }|
            TO lt_attachment_header.

*---------------------------------------------------------------------*
* Add attachment to email
*---------------------------------------------------------------------*

          TRY.

              o_document->add_attachment(
                EXPORTING
                  i_attachment_type    = lv_attachment_type
                  i_attachment_subject = CONV so_obj_des(
                                           lv_filename )
                  i_att_content_hex    = lt_contents_hex
                  i_attachment_header  = lt_attachment_header ).

              lv_attachment_count =
                lv_attachment_count + 1.

            CATCH cx_document_bcs INTO DATA(lx_document).

              WRITE:
                / 'ERROR adding attachment:',
                  lv_filename,
                / lx_document->get_text( ).

              CONTINUE.

          ENDTRY.

        ENDLOOP.
      ENDIF.
**Logic to add document additional supporting FI document

*Create Send Request
      DATA(o_send_request) = cl_bcs=>create_persistent( ).
      o_send_request->set_message_subject( ip_subject = lv_subject ).
      o_send_request->set_document( o_document ).

*SAP User as sender
*      DATA(o_sender) = cl_sapuser_bcs=>create( lv_sender ).
      DATA lv_sender_email TYPE adr6-smtp_addr.
      lv_sender_email = lv_sender.
      DATA(o_sender) = cl_cam_address_bcs=>create_internet_address( i_address_string = lv_sender_email ).
      o_send_request->set_sender( o_sender ).

*Set Recipient
*Changes made for INC01036 to add all the email addresses in TO
*by ARAO on 31/07/2026
*        DATA(o_recipient) = cl_cam_address_bcs=>create_internet_address( lv_recipient_email ).
*        o_send_request->add_recipient( i_recipient = o_recipient
*                                       i_express   = abap_true ).
*        o_send_request->set_send_immediately( abap_true ).
*Changes made for INC01368 to add default email address in TO & others in CC
*by ARAO on 07/08/2026
*        LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber.
*Changes made for INC01743 to accomodate multiple default email address
*by ARAO on 15/09/2026
*         READ TABLE gt_adr6 INTO gs_adr6 WITH KEY addrnumber = gs_but020-addrnumber
*                                                  default = 'X'.
*         IF sy-subrc = 0.
      LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber
                                     AND default    = 'X'.
*End of Changes
        lv_recipient_email = gs_adr6-smtp_addr.

        IF lv_recipient_email IS NOT INITIAL.
          TRY.
              DATA(o_recipient) = cl_cam_address_bcs=>create_internet_address( lv_recipient_email ).

              o_send_request->add_recipient( i_recipient = o_recipient
                                             i_express   = abap_true ).
              o_send_request->set_send_immediately( abap_true ).

            CATCH cx_send_req_bcs INTO bcs_error ##NO_HANDLER.
            CATCH cx_address_bcs ##NO_HANDLER.
            CATCH cx_root INTO DATA(e_text1) .
              WRITE: / e_text1->get_text( ).
              EXIT.
          ENDTRY.
          CLEAR lv_recipient_email.
        ENDIF.
*         ENDIF.
      ENDLOOP.
*End of changes

*Set Recipient (CC)

*Changes made for INC01368 to add default email address in TO & others in CC
*by ARAO on 07/08/2026
*        LOOP AT i_param3 INTO gs_param3 WHERE zparam_id = 'ZFIBS_CC' AND bukrs = p_rbukrs.
*          lv_cc = gs_param3-zpm_low.
      LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber AND default NE 'X'.
        lv_cc = gs_adr6-smtp_addr.
*End of Changes
        IF lv_cc IS NOT INITIAL.
          TRY.
              DATA(o_recipient_cc) = cl_cam_address_bcs=>create_internet_address( i_address_string = lv_cc ).
              o_send_request->add_recipient( i_recipient = o_recipient_cc
                                             i_copy      = abap_true
                                             i_express   = abap_true ).
              o_send_request->set_send_immediately( abap_true ).
            CATCH cx_send_req_bcs INTO bcs_error ##NO_HANDLER.
            CATCH cx_address_bcs ##NO_HANDLER.
            CATCH cx_root INTO DATA(e_text2) .
              WRITE: / e_text2->get_text( ).
              EXIT.
          ENDTRY.
        ENDIF.
      ENDLOOP.

*Send Document (email)
      o_send_request->send( i_with_error_screen = abap_true ).
      COMMIT WORK ##SUBRC_AFTER_COMMIT.

      IF sy-subrc = 0.
        MESSAGE s009. "M - Email has been sent!
        gv_elog_status = c_email_status_s.
        gv_elog_message = c_email_msg_s.
      ENDIF.

    CATCH cx_root INTO DATA(e_text) .
      WRITE: / e_text->get_text( ).

  ENDTRY.

*Email Log Data (Recipient)

*Changes made for INC01036 to add all the email addresses in TO
*by ARAO on 31/07/2026
*    LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber.
*Changes made for INC01368 to add default email address in TO
*by ARAO on 07/08/2026
  LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber
                                 AND default = 'X'.
*End of Changes
    gv_elog_recmail = gs_adr6-smtp_addr.
    IF gv_elog_recmail IS NOT INITIAL.
      gs_email-status    = gv_elog_status.
      gs_email-docnum    = gv_elog_docnum.
      gs_email-fiscal    = gv_elog_fiscal.
      gs_email-ccode     = gv_elog_ccode.
      gs_email-cname     = gv_elog_cname.
      gs_email-sendmail  = gv_elog_sendmail.
      gs_email-recmail   = gv_elog_recmail.
      gs_email-message   = gv_elog_message.

      APPEND gs_email TO gt_email.
    ENDIF.
  ENDLOOP.
*End of changes

*Email Log Data (CC)

*Changes made for INC01368 to add default email address in TO
*by ARAO on 07/08/2026
*    LOOP AT i_param3 INTO gs_param3 WHERE zparam_id = 'ZFIBS_CC' AND bukrs = p_rbukrs.
*      lv_cc = gs_param3-zpm_low.
  LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber
                                 AND default NE 'X'.
    lv_cc = gs_adr6-smtp_addr.
*End of Changes
    IF lv_cc IS NOT INITIAL.
      gs_email-status    = gv_elog_status.
      gs_email-docnum    = gv_elog_docnum.
      gs_email-fiscal    = gv_elog_fiscal.
      gs_email-ccode     = gv_elog_ccode.
      gs_email-cname     = gv_elog_cname.
      gs_email-sendmail  = gv_elog_sendmail.
      gs_email-recmail   = lv_cc.
      gs_email-message   = gv_elog_message.

      APPEND gs_email TO gt_email.
    ENDIF.
  ENDLOOP.

*Changes made for INC01036 to add all the email addresses in TO
*by ARAO on 31/07/2026
*ENDLOOP.
*End of Changes
************* FAILED EMAIL ***************
  IF sy-subrc NE 0.
    gv_elog_recmail = ' '.
    gv_elog_message = c_no_email.
    gv_elog_status = c_email_status_f.

*OTHER EMAIL LOG DATA
    gv_elog_docnum   = gs_header-docnum+8.
    gv_elog_fiscal   = gs_acdoca_temp-gjahr.
    gv_elog_ccode    = gs_header-ccode.
    gv_elog_cname    = gs_header-billto.
    gv_elog_sendmail = gv_email_sender.

*MAIN DATA
    gs_email-status    = gv_elog_status.
    gs_email-docnum    = gv_elog_docnum.
    gs_email-fiscal    = gv_elog_fiscal.
    gs_email-ccode     = gv_elog_ccode.
    gs_email-cname     = gv_elog_cname.
    gs_email-sendmail  = gv_elog_sendmail.
    gs_email-recmail   = gv_elog_recmail.
    gs_email-message   = gv_elog_message.

    APPEND gs_email TO gt_email.
  ENDIF.

ENDFORM.
FORM f_encrypt USING fp_tline
                     fp_filename
                     fp_password
          CHANGING cv_zipfilename
                    cv_pdffilename.
  "  DATA: li_tline TYPE STANDARD TABLE OF tline.
  DATA: li_tline TYPE solix_tab.




**************************************************
*        li_tline1 TYPE STANDARD TABLE OF solix.
******************************************************
  DATA: l_file         TYPE string,
        l_file_zip     TYPE string,
        l_filename_pdf TYPE char255,
        l_filename_zip TYPE char255,
        l_filename_tmp TYPE string.

  DATA: l_dir_input      TYPE sxpgcolist-parameters.
  DATA: l_orln      TYPE drao-orln,
        li_data_tab TYPE STANDARD TABLE OF rcgrepfile,
        l_lines     TYPE i.
  DATA: t_result         TYPE STANDARD TABLE OF btcxpm.

  DATA: li_command_list TYPE STANDARD TABLE OF sxpgcolist.

  DATA: status      LIKE btcxp3-exitstat,
        commandname LIKE sxpgcolist-name VALUE 'ZDJ_ENCRYPTPDF',
        sel_no      LIKE sy-tabix.

  CONSTANTS: c_extcom TYPE sxpgcolist-name VALUE 'ZDJ_ENCRYPTPDF',
             c_oper   TYPE syopsys VALUE 'Linux'.


  li_tline = fp_tline.


  l_filename_tmp = fp_filename.
  TRANSLATE l_filename_tmp USING ' _'.
  l_filename_pdf = l_filename_tmp.
  "  l_filename_zip = l_filename_tmp.

*  SELECT SINGLE zpm_low FROM zglbparam
*    INTO @DATA(l_tmp_dir)
*    WHERE zparam_id = 'ZTMP_DIR'
*    AND zprog = 'ZFI005' .

  IF sy-sysid = 'DS4'.
    SELECT SINGLE zpm_low FROM zglbparam
  INTO @DATA(l_tmp_dir)
  WHERE zparam_id = 'ZTMP_DIR'
  AND zprog = 'ZFI005' AND zcounter = '001' .
  ELSEIF sy-sysid = 'QS4'.
    SELECT SINGLE zpm_low FROM zglbparam
    INTO l_tmp_dir
    WHERE zparam_id = 'ZTMP_DIR'
    AND zprog = 'ZFI005' AND zcounter = '002' .
  ELSEIF sy-sysid = 'PS4'.
    SELECT SINGLE zpm_low FROM zglbparam
    INTO l_tmp_dir
    WHERE zparam_id = 'ZTMP_DIR'
    AND zprog = 'ZFI005' AND zcounter = '003' .

  ENDIF.

  "  CONCATENATE l_tmp_dir '/' l_filename_zip '''.ZIP'  INTO l_file_zip.
  CONCATENATE l_tmp_dir '/' l_filename_pdf '''.PDF'  INTO l_file.
  " CONCATENATE l_tmp_dir '/' l_filename_pdf '''.pdF'  INTO l_file.
  REPLACE ALL OCCURRENCES OF '''' IN l_file WITH space.
  "  REPLACE ALL OCCURRENCES OF '''' IN l_file_zip WITH space.
  "  cv_zipfilename = l_file_zip .
  cv_pdffilename = l_file.


  TRY.
      OPEN DATASET l_file FOR OUTPUT IN BINARY MODE  .
      IF  sy-subrc = 0 .
        LOOP AT li_tline INTO DATA(lst_tline).
          TRANSFER lst_tline TO l_file .
        ENDLOOP.
        CLOSE DATASET l_file  .
      ELSE.
        WRITE : / 'operating system could not open file' .
      ENDIF.



    CATCH cx_sy_file_authority.
  ENDTRY.

*DATA: lt_file_raw TYPE solix_tab,
*      ls_raw_zip TYPE solix.
*
*OPEN DATASET l_file FOR INPUT IN BINARY MODE.
*
*DO.
*  READ DATASET l_file INTO ls_raw_zip.
*  IF sy-subrc <> 0.
*    EXIT.
*  ENDIF.
*  APPEND ls_raw_zip TO lt_file_raw.
*ENDDO.



  CALL FUNCTION 'SXPG_COMMAND_LIST_GET'
    EXPORTING
      commandname     = commandname
      operatingsystem = sy-opsys
    TABLES
      command_list    = li_command_list
    EXCEPTIONS
      OTHERS          = 1.

  DATA: l_commandname TYPE sxpgcolist-name.

  l_commandname = VALUE #( li_command_list[ 1 ]-name OPTIONAL ).


  CALL FUNCTION 'SXPG_COMMAND_CHECK'
    EXPORTING
      commandname                = l_commandname
      operatingsystem            = sy-opsys
    EXCEPTIONS
      no_permission              = 1
      command_not_found          = 2
      parameters_too_long        = 3
      security_risk              = 4
      wrong_check_call_interface = 5
      x_error                    = 6
      too_many_parameters        = 7
      parameter_expected         = 8
      illegal_command            = 9
      communication_failure      = 10
      system_failure             = 11
      OTHERS                     = 12.

  CLEAR li_command_list.
  REFRESH li_command_list.

  CLEAR: l_dir_input,l_orln,l_lines.
  REFRESH:li_data_tab[].

  li_command_list = VALUE #( ( name = 'ZDJ_ENCRYPTPDF' opsystem = 'Linux' ) ).

*  CONCATENATE '-j' '-P' 'TEST' l_file_zip l_file INTO l_dir_input SEPARATED BY space.
  "  CONCATENATE '-j' '-P' fp_password l_file_zip l_file INTO l_dir_input SEPARATED BY space.
  l_dir_input = |-j -P { fp_password } "{ l_file_zip }" "{ l_file }"|.


  CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
    EXPORTING
      commandname                   = c_extcom
      additional_parameters         = l_dir_input
      operatingsystem               = c_oper
    TABLES
      exec_protocol                 = t_result
    EXCEPTIONS
      no_permission                 = 1
      command_not_found             = 2
      parameters_too_long           = 3
      security_risk                 = 4
      wrong_check_call_interface    = 5
      program_start_error           = 6
      program_termination_error     = 7
      x_error                       = 8
      parameter_expected            = 9
      too_many_parameters           = 10
      illegal_command               = 11
      wrong_asynchronous_parameters = 12
      cant_enq_tbtco_entry          = 13
      jobcount_generation_error     = 14
      OTHERS                        = 15.

  WAIT UP TO 2 SECONDS.

ENDFORM.
*FORM f_delete_file  USING    p_l_filename.
*  DELETE DATASET p_l_filename.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_send_email_1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM f_send_email_1 .
*  DATA: i_otf    TYPE itcoo OCCURS 0 WITH HEADER LINE,
*        i_tline  TYPE TABLE OF tline WITH HEADER LINE,
*        v_len_in LIKE sood-objlen.
*
*  CALL FUNCTION 'CONVERT_OTF'
*    EXPORTING
*      format                = 'PDF'
*      max_linewidth         = 132
*    IMPORTING
*      bin_filesize          = v_len_in
*    TABLES
*      otf                   = i_otf
*      lines                 = i_tline
*    EXCEPTIONS
*      err_max_linewidth     = 1
*      err_format            = 2
*      err_conv_not_possible = 3
*      OTHERS                = 4.
*
*  DATA: l_file       TYPE string,
*        l_file_zip   TYPE string,
*        itab_attach  TYPE xstring,
*        t_attachment TYPE solix_tab,
*        ld_buffer    TYPE xstring.
*
*
*  TYPES: BEGIN OF ty_final,
*           pernr       TYPE pernr_d,
*           civil_id    TYPE char15,  "or TYPE string
*           passport_no TYPE char15,
*           ename       TYPE string,
**         amount   TYPE curr13,
*         END OF ty_final.
*
*  DATA: wa_final TYPE ty_final.
*
*  CLEAR:l_file,l_file_zip,itab_attach.
*  REFRESH:t_attachment[].
*
*  CONCATENATE '/tmp/' wa_final-pernr '''.PDF'  INTO l_file.
*  CONCATENATE '/tmp/' wa_final-pernr '''.ZIP'  INTO l_file_zip.
*  REPLACE ALL OCCURRENCES OF '''' IN l_file WITH space.
*  REPLACE ALL OCCURRENCES OF '''' IN l_file_zip WITH space.
*
*****code move PDF to server location***
*  OPEN DATASET l_file FOR OUTPUT IN BINARY MODE  .
*  IF  sy-subrc = 0 .
*    LOOP AT i_tline.
*      TRANSFER i_tline TO l_file .
*    ENDLOOP.
*    CLOSE DATASET l_file  .
*  ELSE.
*    WRITE : / 'operating system could not open file' .
*  ENDIF.
*
*  DATA: BEGIN OF command_list OCCURS 0.
*          INCLUDE STRUCTURE sxpgcolist.
*  DATA: END OF command_list .
*
*  DATA: BEGIN OF exec_protocol OCCURS 0.
*          INCLUDE STRUCTURE btcxpm.
*  DATA: END OF exec_protocol.
*
*  DATA: status      LIKE btcxp3-exitstat,
*        commandname LIKE sxpgcolist-name VALUE 'ZDJ_ENCRYPTPDF',
*        sel_no      LIKE sy-tabix.
*
*  CONSTANTS: c_no_email       TYPE string VALUE 'No customer email address maintained' ##NO_TEXT,
*             c_email_status_s TYPE string VALUE 'Successful' ##NO_TEXT,
*             c_email_status_f TYPE string VALUE 'Failed' ##NO_TEXT,
*             c_email_msg_s    TYPE string VALUE 'Email is successfully sent.' ##NO_TEXT,
*             c_email_msg_f    TYPE string VALUE 'Failed to send email.' ##NO_TEXT ##NEEDED.
*
** GET LIST OF EXTERNAL COMMANDS
*
*  CALL FUNCTION 'SXPG_COMMAND_LIST_GET'
*    EXPORTING
*      commandname     = commandname
*      operatingsystem = sy-opsys
*    TABLES
*      command_list    = command_list
*    EXCEPTIONS
*      OTHERS          = 1.
*
*  CALL FUNCTION 'SXPG_COMMAND_CHECK'
*    EXPORTING
*      commandname                = command_list-name
*      operatingsystem            = sy-opsys
*    EXCEPTIONS
*      no_permission              = 1
*      command_not_found          = 2
*      parameters_too_long        = 3
*      security_risk              = 4
*      wrong_check_call_interface = 5
*      x_error                    = 6
*      too_many_parameters        = 7
*      parameter_expected         = 8
*      illegal_command            = 9
*      communication_failure      = 10
*      system_failure             = 11
*      OTHERS                     = 12.
*
*
*  CLEAR command_list.
*  REFRESH command_list.
*
*  DATA: v_dir_input      TYPE sxpgcolist-parameters.
*  DATA:l_orln     LIKE drao-orln,
*       l_data_tab LIKE rcgrepfile OCCURS 10 WITH HEADER LINE,
*       l_lines    TYPE i.
*
*  CLEAR: v_dir_input,l_orln,l_lines.
*  REFRESH:l_data_tab[].
*
*  command_list-name = 'ZDJ_ENCRYPTPDF'.  " External command u have created
*  command_list-opsystem = 'Linux'.
*
*
*  CONSTANTS: c_extcom TYPE sxpgcolist-name VALUE 'ZDJ_ENCRYPTPDF',
*             c_oper   TYPE syopsys VALUE 'Linux'.
*
**encrypting the file using some number- Civil ID here is social security ID, AAdhar ID country specific
*  IF wa_final-civil_id IS NOT INITIAL.
*    CONCATENATE '-P' wa_final-civil_id l_file_zip l_file INTO v_dir_input SEPARATED BY space.
*  ENDIF.
**encrypting the file using passport number if no ID available
*  IF wa_final-civil_id IS INITIAL.
*    CONCATENATE '-P' wa_final-passport_no l_file_zip l_file INTO v_dir_input SEPARATED BY space.
*  ENDIF.
*
*
*  DATA: t_result         TYPE STANDARD TABLE OF btcxpm.
*  REFRESH:t_result[].
*
*  CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
*    EXPORTING
*      commandname                   = c_extcom
*      additional_parameters         = v_dir_input
*      operatingsystem               = c_oper
*    TABLES
*      exec_protocol                 = t_result
*    EXCEPTIONS
*      no_permission                 = 1
*      command_not_found             = 2
*      parameters_too_long           = 3
*      security_risk                 = 4
*      wrong_check_call_interface    = 5
*      program_start_error           = 6
*      program_termination_error     = 7
*      x_error                       = 8
*      parameter_expected            = 9
*      too_many_parameters           = 10
*      illegal_command               = 11
*      wrong_asynchronous_parameters = 12
*      cant_enq_tbtco_entry          = 13
*      jobcount_generation_error     = 14
*      OTHERS                        = 15.
*
*  DATA: i_file_appl TYPE rcgiedial-iefile.
*  sy-cprog = 'RC1TCG3Y'.
*  CALL FUNCTION 'C13Z_RAWDATA_READ'
*    EXPORTING
*      i_file           = i_file_appl
*    IMPORTING
*      e_file_size      = l_orln
*      e_lines          = l_lines
*    TABLES
*      e_rcgrepfile_tab = l_data_tab
*    EXCEPTIONS
*      no_permission    = 1
*      open_failed      = 2
*      read_error       = 3
** Begin Correction 24.09.2010 1505368 ********************
*      path_error       = 4
*      OTHERS           = 5.
*  sy-cprog = sy-repid.
*
*  sy-cprog = 'RC1TCG3Y'.
*  CALL FUNCTION 'C13Z_RAWDATA_READ'
*    EXPORTING
*      i_file           = i_file_appl
*    IMPORTING
*      e_file_size      = l_orln
*      e_lines          = l_lines
*    TABLES
*      e_rcgrepfile_tab = l_data_tab
*    EXCEPTIONS
*      no_permission    = 1
*      open_failed      = 2
*      read_error       = 3
** Begin Correction 24.09.2010 1505368 ********************
*      path_error       = 4
*      OTHERS           = 5.
*  sy-cprog = sy-repid.
*
*
*  DATA content_hex TYPE solix_tab.
*
*  REFRESH:content_hex[].
*
*
*  CALL METHOD cl_bcs_convert=>xstring_to_solix
*    EXPORTING
*      iv_xstring = ld_buffer
*    RECEIVING
*      et_solix   = content_hex.
*
*
*  DATA: lv_sender          TYPE adr6-smtp_addr,
*        lv_recipient_email TYPE ad_smtpadr,
*        lv_sender2         TYPE adr6-smtp_addr ##NEEDED,
*        lv_cc              TYPE ad_smtpadr,
*        lv_subject         TYPE string,
*        lv_message         TYPE bcsy_text.
*
*  DATA: lo_send_request TYPE REF TO cl_bcs
*        ,lo_document     TYPE REF TO cl_document_bcs
*       ",lo_sender       TYPE REF TO if_sender_bcs
*       ",lo_recipient    TYPE REF TO if_recipient_bcs      ,
*       ,lt_message_body TYPE bcsy_text
*       ,lx_document_bcs TYPE REF TO cx_document_bcs
*       ,lv_send         TYPE ad_smtpadr VALUE 'xyz@gmail.com'
*       ,lv_sent_to_all  TYPE os_boolean     .
*
*  DATA: bcs_error TYPE REF TO cx_send_req_bcs ##NEEDED.
*  DATA recipient      TYPE REF TO if_recipient_bcs.
*  "create send request
*  lo_send_request = cl_bcs=>create_persistent( ).
*
*  DATA: gv_message TYPE string.
*  "lv_message         TYPE bcsy_text.
*  DATA: gv_subject TYPE so_obj_des.
*  DATA: gv_subject1 TYPE so_obj_des.
*  CLEAR:gv_message,gv_subject,gv_subject1.
*
*  "create message body and subject
*  CONCATENATE 'Dear' wa_final-ename INTO gv_message SEPARATED BY space.
*  CONCATENATE gv_message ',' INTO gv_message..
*  APPEND gv_message   TO lt_message_body.
*  CLEAR:gv_message.
*  APPEND INITIAL LINE TO lt_message_body.
*
*  CONCATENATE 'Please find your payslip for the month of'  lv_month lv_year 'attached with the mail.' INTO gv_message SEPARATED BY space.
*  APPEND gv_message   TO lt_message_body.
*  CLEAR:gv_message.
*  APPEND INITIAL LINE TO lt_message_body.
*
*  IF wa_final-civil_id IS NOT INITIAL.
*    APPEND 'For added security concerns, your payslip is protected by a unique password, which is your Civil ID number.' TO lt_message_body.
*  ENDIF.
*
*  IF wa_final-civil_id IS INITIAL.
*    APPEND 'For added security concerns, your payslip is protected by a unique password, which is your Passport number.' TO lt_message_body.
*  ENDIF.
*
*  APPEND INITIAL LINE TO lt_message_body.
*
*  APPEND 'Regards,' TO lt_message_body.
*  APPEND 'HR Department' TO lt_message_body.
*
*  CONCATENATE 'Your Payslip for' lv_month lv_year INTO gv_subject SEPARATED BY space.
*
*  "put your text into the document
*  lo_document = cl_document_bcs=>create_document(
*  i_type = 'RAW'
*  i_text = lt_message_body
*  i_subject = gv_subject ).
*
*
*  CONCATENATE 'YourPayslip_' lv_month lv_year INTO gv_subject1.
*  CONDENSE gv_subject1.
*
*  TRY.
*      lo_document->add_attachment(
*      EXPORTING
*        i_attachment_type = 'ZIP'
*        i_attachment_subject = gv_subject
*        i_att_content_hex = content_hex ).
*
*    CATCH cx_document_bcs INTO lx_document_bcs.
*  ENDTRY.
*
*
*  DATA gv_email_sender TYPE string.
*
**---Sender Email
*  READ TABLE i_param4 INTO gs_param4 WITH KEY zparam_id = 'ZFIEMAILSENDER'
*                                              bukrs = gs_acdoca-rbukrs.
*  IF sy-subrc = 0.
*    MOVE gs_param4-zpm_low TO gv_email_sender.
*  ENDIF.
*
*
********* SEND EMAIL WITH ATTACHMENT **********
*  LOOP AT gt_adr6 INTO gs_adr6 WHERE addrnumber = gs_but020-addrnumber.
*    IF sy-subrc = 0.
*      gv_elog_recmail = gs_adr6-smtp_addr.
*    ENDIF.
*
**OTHER EMAIL LOG DATA
*    gv_elog_docnum   = gs_header-docnum+8.
*    gv_elog_fiscal   = gs_acdoca_temp-gjahr.
*    gv_elog_ccode    = gs_header-ccode.
*    gv_elog_cname    = gs_header-billto.
*    gv_elog_sendmail = gv_email_sender.
*
************* EMAIL INFORMATION ***************
**SENDER EMAIL
*    lv_sender = gv_elog_sendmail.
*
**RECIEVER EMAIL
*    lv_recipient_email = gv_elog_recmail.
*
*
*    TRY.
*
**Create Document
*        DATA(o_document) = cl_document_bcs=>create_document( i_type = 'HTM'
*                                                             i_text = lv_message
*                                                             i_subject = CONV so_obj_des( lv_subject ) ).
*
**Create Attachment
*        DATA: gv_zipsize TYPE sood-objlen.
*
*        o_document->add_attachment( i_attachment_type = 'ZIP'
*                                    i_attachment_subject = |{ gv_pdfname }|
*         "                           i_att_content_hex = content_hex
*                                    i_attachment_size    = gv_zipsize
*                                     i_att_content_hex = i_tline ). "li_content_hex
*        "                               i_attachment_size    = gv_zipsize
*        "                                   i_att_content_hex = i_tline1 ).
*        "                                    i_attachment_size    = gv_zipsize ). "li_content_hex
*
**Create Send Request
*        DATA(o_send_request) = cl_bcs=>create_persistent( ).
*        o_send_request->set_message_subject( ip_subject = lv_subject ).
*        o_send_request->set_document( o_document ).
*
**SAP User as sender
**      DATA(o_sender) = cl_sapuser_bcs=>create( lv_sender ).
*        DATA lv_sender_email TYPE adr6-smtp_addr.
*        lv_sender_email = lv_sender.
*        DATA(o_sender) = cl_cam_address_bcs=>create_internet_address( i_address_string = lv_sender_email ).
*        o_send_request->set_sender( o_sender ).
*
**Set Recipient
*        DATA(o_recipient) = cl_cam_address_bcs=>create_internet_address( lv_recipient_email ).
*        o_send_request->add_recipient( i_recipient = o_recipient
*                                       i_express = abap_true ).
*        o_send_request->set_send_immediately( abap_true ).
*
**Set Recipient (CC)
*
*        LOOP AT i_param3 INTO gs_param3 WHERE zparam_id = 'ZFIBS_CC' AND bukrs = p_rbukrs.
*          lv_cc = gs_param3-zpm_low.
*          IF lv_cc IS NOT INITIAL.
*            TRY.
*                DATA(o_recipient_cc) = cl_cam_address_bcs=>create_internet_address( i_address_string = lv_cc ).
*                o_send_request->add_recipient( i_recipient = o_recipient_cc
*                                               i_copy = abap_true
*                                               i_express = abap_true ).
*                o_send_request->set_send_immediately( abap_true ).
*              CATCH cx_send_req_bcs INTO bcs_error ##NO_HANDLER.
*              CATCH cx_address_bcs ##NO_HANDLER.
*              CATCH cx_root INTO DATA(e_text2) .
*                WRITE: / e_text2->get_text( ).
*                EXIT.
*            ENDTRY.
*          ENDIF.
*        ENDLOOP.
*
**Send Document (email)
*        o_send_request->send( i_with_error_screen = abap_true ).
*        COMMIT WORK ##SUBRC_AFTER_COMMIT.
*
*        IF sy-subrc = 0.
*          MESSAGE s009. "M - Email has been sent!
*          gv_elog_status = c_email_status_s.
*          gv_elog_message = c_email_msg_s.
*        ENDIF.
*
*      CATCH cx_root INTO DATA(e_text) .
*        WRITE: / e_text->get_text( ).
*
*    ENDTRY.
*
**Email Log Data (Recipient)
*    gs_email-status    = gv_elog_status.
*    gs_email-docnum    = gv_elog_docnum.
*    gs_email-fiscal    = gv_elog_fiscal.
*    gs_email-ccode     = gv_elog_ccode.
*    gs_email-cname     = gv_elog_cname.
*    gs_email-sendmail  = gv_elog_sendmail.
*    gs_email-recmail   = gv_elog_recmail.
*    gs_email-message   = gv_elog_message.
*
*    APPEND gs_email TO gt_email.
*
**Email Log Data (CC)
*    LOOP AT i_param3 INTO gs_param3 WHERE zparam_id = 'ZFIBS_CC' AND bukrs = p_rbukrs.
*      lv_cc = gs_param3-zpm_low.
*      IF lv_cc IS NOT INITIAL.
*        gs_email-status    = gv_elog_status.
*        gs_email-docnum    = gv_elog_docnum.
*        gs_email-fiscal    = gv_elog_fiscal.
*        gs_email-ccode     = gv_elog_ccode.
*        gs_email-cname     = gv_elog_cname.
*        gs_email-sendmail  = gv_elog_sendmail.
*        gs_email-recmail   = lv_cc.
*        gs_email-message   = gv_elog_message.
*
*        APPEND gs_email TO gt_email.
*      ENDIF.
*    ENDLOOP.
*
*  ENDLOOP.
*
************** FAILED EMAIL ***************
*  IF sy-subrc NE 0.
*    gv_elog_recmail = ' '.
*    gv_elog_message = c_no_email.
*    gv_elog_status = c_email_status_f.
*
**OTHER EMAIL LOG DATA
*    gv_elog_docnum   = gs_header-docnum+8.
*    gv_elog_fiscal   = gs_acdoca_temp-gjahr.
*    gv_elog_ccode    = gs_header-ccode.
*    gv_elog_cname    = gs_header-billto.
*    gv_elog_sendmail = gv_email_sender.
*
**MAIN DATA
*    gs_email-status    = gv_elog_status.
*    gs_email-docnum    = gv_elog_docnum.
*    gs_email-fiscal    = gv_elog_fiscal.
*    gs_email-ccode     = gv_elog_ccode.
*    gs_email-cname     = gv_elog_cname.
*    gs_email-sendmail  = gv_elog_sendmail.
*    gs_email-recmail   = gv_elog_recmail.
*    gs_email-message   = gv_elog_message.
*
*    APPEND gs_email TO gt_email.
*  ENDIF.
*
*
*
*
*
*
*
*
*** Add attachment
*** Pass the document to send request
**  lo_send_request->set_document( lo_document ).
**
**  lo_sender = cl_cam_address_bcs=>create_internet_address( 'sap.support@domain.com' ).
**
**  lo_send_request->set_sender( lo_sender ).
**
**
**
**
***--------- add recipient (e-mail address) -----------------------
***     create recipient object
**  DATA:lv_email TYPE pa0105-usrid_long.
**  CLEAR:lv_email.
**  SELECT SINGLE usrid_long FROM pa0105 INTO lv_email WHERE pernr = wa_final-pernr  AND  subty ='0010' AND endda = '99991231'.
**
**  IF lv_email IS NOT INITIAL.
**    recipient = cl_cam_address_bcs=>create_internet_address( lv_email ).
**
**    lo_send_request->add_recipient( recipient ).
**    DATA sent_to_all    TYPE os_boolean.
**
**    sent_to_all = lo_send_request->send( i_with_error_screen = 'X' ).
**
**    COMMIT WORK.
**  ENDIF.
*
*  DELETE DATASET l_file.
*  DELETE DATASET l_file_zip.
*
*
*
*
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_filename
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_OBJECT_HEADER
*&      <-- LV_FILENAME
*&---------------------------------------------------------------------*
FORM get_filename
  USING
    it_object_header TYPE STANDARD TABLE
  CHANGING
    cv_filename TYPE string.

  DATA:
    ls_header TYPE solisti1.

  CLEAR cv_filename.

  LOOP AT it_object_header INTO ls_header.

    IF strlen( ls_header-line ) >= 13
       AND ls_header-line(13) = '&SO_FILENAME='.

      cv_filename = ls_header-line+13.
      EXIT.

    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_attachment_type
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_FILENAME
*&      <-- LV_ATTACHMENT_TYPE
*&---------------------------------------------------------------------*
FORM get_attachment_type
USING
    iv_filename TYPE string
  CHANGING
    cv_type TYPE so_obj_tp.

  DATA:
    lv_extension TYPE string.

  CLEAR cv_type.

  FIND REGEX '\.([^.]+)$'
       IN iv_filename
       SUBMATCHES lv_extension.

  IF sy-subrc <> 0.

    cv_type = 'BIN'.
    RETURN.

  ENDIF.

  TRANSLATE lv_extension TO UPPER CASE.

*---------------------------------------------------------------------*
* Standard SAPoffice document types
*---------------------------------------------------------------------*

  CASE lv_extension.

    WHEN 'PDF'.
      cv_type = 'PDF'.

    WHEN 'XLS' OR 'XLSX'.
      cv_type = 'XLS'.

    WHEN 'DOC' OR 'DOCX'.
      cv_type = 'DOC'.

    WHEN 'TXT'.
      cv_type = 'TXT'.

    WHEN 'CSV'.
      cv_type = 'CSV'.

    WHEN 'JPG' OR 'JPEG'.
      cv_type = 'JPG'.

    WHEN 'PNG'.
      cv_type = 'PNG'.

    WHEN 'ZIP'.
      cv_type = 'ZIP'.

    WHEN 'XML'.
      cv_type = 'XML'.

    WHEN 'HTML' OR 'HTM'.
      cv_type = 'HTM'.

    WHEN OTHERS.
      cv_type = 'BIN'.

  ENDCASE.

ENDFORM.
