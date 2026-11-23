FUNCTION ZFI_BP_DOCUMENT_CLOSE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      T_ACCHD STRUCTURE  ACCHD
*"      T_ACCIT STRUCTURE  ACCIT
*"      T_ACCCR STRUCTURE  ACCCR
*"----------------------------------------------------------------------
****
****DATA: LD_SUBRC LIKE SY-SUBRC.
****
****  SORT: T_ACCHD BY MANDT AWTYP AWREF AWORG,
****        T_ACCIT BY MANDT AWTYP AWREF AWORG POSNR,
****        T_ACCCR BY MANDT AWTYP AWREF AWORG POSNR CURTP.
****
****  CLEAR LD_SUBRC.



******  PERFORM BP_INIT TABLES T_ACCIT
******                  USING  LD_SUBRC.
******  CHECK LD_SUBRC = 0.
******  PERFORM BP_BUILD TABLES T_ACCHD T_ACCIT T_ACCCR.
******  PERFORM BP_CALL.
DATA it_accit TYPE TABLE OF accit.
  DATA: lt_comp    TYPE STANDARD TABLE OF bukrs.
  DATA l_v TYPE i.
  DATA l_v1 TYPE i.
  DATA l_wrbtr TYPE wrbtr.
  DATA l_wrbtr_1 TYPE wrbtr.
    FIELD-SYMBOLS <fs_b> TYPE bseg.

*BOC By Arnav on 23/11/26
* Business area / profit center on the tax lines of a logistics
* invoice (MIRO/MIR7) from ZFI_BAPC1 - same rule as substitution exit
* UF122 in ZFI_RGGBS000_USEREXIT. Only blank fields are filled.
* ASSUMPTION: this function module runs BEFORE the document splitter
* checks the balancing fields. If it runs after, this block has no
* effect on the error "Balancing field Business Area not filled".
* ASSUMPTION: scope is reference transaction RMRP only; FI invoices
* (FB60 etc.) are deliberately left as they are.
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

* Reference transaction of logistics invoice verification, and the
* line item identifier of an automatically created tax line
  CONSTANTS: lc_zz_awtyp_liv TYPE c LENGTH 5 VALUE 'RMRP',
             lc_zz_buzid_tax TYPE c LENGTH 1 VALUE 'T'.

  FIELD-SYMBOLS <ls_zz_it> TYPE accit.

* 1. Collect the tax lines that still miss an assignment
  LOOP AT t_accit[] ASSIGNING <ls_zz_it>
       WHERE awtyp = lc_zz_awtyp_liv
         AND buzid = lc_zz_buzid_tax
         AND kstat = space.
    IF <ls_zz_it>-gsber IS INITIAL
       OR <ls_zz_it>-prctr IS INITIAL.
      CLEAR ls_zz_key.
      ls_zz_key-bukrs = <ls_zz_it>-bukrs.
      ls_zz_key-hkont = <ls_zz_it>-hkont.
      APPEND ls_zz_key TO lt_zz_key.
    ENDIF.
  ENDLOOP.

  IF lt_zz_key IS NOT INITIAL.
    SORT lt_zz_key BY bukrs hkont.
    DELETE ADJACENT DUPLICATES FROM lt_zz_key COMPARING bukrs hkont.

*   2. One read of ZFI_BAPC1 for all of them
    SELECT bukrs, hkont, begda, gsber, prctr
      FROM zfi_bapc1
      FOR ALL ENTRIES IN @lt_zz_key
      WHERE bukrs = @lt_zz_key-bukrs
        AND hkont = @lt_zz_key-hkont
      INTO TABLE @lt_zz_bapc.

*   Same row as UF122 takes: the earliest start date per account
    SORT lt_zz_bapc BY bukrs hkont begda.

*   3. Fill only what is blank
    LOOP AT t_accit[] ASSIGNING <ls_zz_it>
         WHERE awtyp = lc_zz_awtyp_liv
           AND buzid = lc_zz_buzid_tax
           AND kstat = space.
      IF <ls_zz_it>-gsber IS NOT INITIAL
         AND <ls_zz_it>-prctr IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      READ TABLE lt_zz_bapc INTO ls_zz_bapc
           WITH KEY bukrs = <ls_zz_it>-bukrs
                    hkont = <ls_zz_it>-hkont
           BINARY SEARCH.
      IF sy-subrc <> 0.
*       No entry in ZFI_BAPC1: leave the line as it is. The standard
*       message "Balancing field ... not filled" then tells the user.
        CONTINUE.
      ENDIF.

*     Entry not yet valid on the posting date (as in UF122)
      IF <ls_zz_it>-budat < ls_zz_bapc-begda.
        CONTINUE.
      ENDIF.

      IF <ls_zz_it>-gsber IS INITIAL
         AND ls_zz_bapc-gsber IS NOT INITIAL.
        <ls_zz_it>-gsber = ls_zz_bapc-gsber.
      ENDIF.
      IF <ls_zz_it>-prctr IS INITIAL
         AND ls_zz_bapc-prctr IS NOT INITIAL.
        <ls_zz_it>-prctr = ls_zz_bapc-prctr.
      ENDIF.
    ENDLOOP.
  ENDIF.
*EOC By Arnav on 23/11/26

 SORT: t_accit BY bukrs.

   LOOP AT t_accit[] INTO DATA(ls_accit).
    APPEND ls_accit-bukrs TO lt_comp.
  ENDLOOP.

  SORT lt_comp.
  DELETE ADJACENT DUPLICATES FROM lt_comp.

 MOVE t_accit[] TO it_accit[].
  SORT it_accit BY vbund.
  DELETE ADJACENT DUPLICATES FROM it_accit COMPARING vbund.
  DELETE it_accit WHERE vbund IS INITIAL.
  DESCRIBE TABLE it_accit LINES l_v.
  DESCRIBE TABLE lt_comp LINES l_v1.
  IF l_v > 1 AND l_v1 = 1 .
    LOOP AT it_accit INTO DATA(wa_accit).
      IF sy-tabix = 1.
        LOOP AT t_accit INTO DATA(wa_accit_1) WHERE vbund = wa_accit-vbund.
          l_wrbtr = l_wrbtr + wa_accit_1-pswbt.
        ENDLOOP.
      ELSE.
        LOOP AT t_accit INTO DATA(wa_accit_11) WHERE vbund = wa_accit-vbund.
          l_wrbtr_1 = l_wrbtr_1 + wa_accit_11-pswbt.
        ENDLOOP.

        IF l_wrbtr <> l_wrbtr_1.
          MESSAGE ' Please balance the document at trading partner level ' TYPE 'W'.

        ENDIF.

      ENDIF.
      CLEAR l_wrbtr_1.
    ENDLOOP.
  ENDIF.


  IF t_accit[] IS NOT INITIAL AND l_v = 1.
    DATA:lv_flag_temp TYPE c VALUE IS INITIAL.
    SELECT * FROM zfi_trd_prtnr INTO TABLE @DATA(lt_trd) WHERE fisteps IN ( 'ICTGL','TCODE','TCCLRG' )
                                                         AND operator EQ 'EQ'.
    IF lt_trd[] IS NOT INITIAL.
      DATA(lt_trd_temp) = lt_trd[].
      DELETE lt_trd_temp WHERE fisteps NE 'TCODE'.
      READ TABLE lt_trd_temp INTO DATA(ls_trd_temp) WITH KEY value1 = sy-tcode.
      IF sy-subrc = 0.
        LOOP AT t_accit INTO DATA(ls_acc).
          IF ls_acc-kunnr IS NOT INITIAL.
            SELECT SINGLE vbund FROM kna1 INTO @DATA(lv_vbun) WHERE kunnr EQ @ls_acc-kunnr.
            IF lv_vbun IS NOT INITIAL.
              lv_flag_temp = abap_true.
              LOOP AT t_accit ASSIGNING FIELD-SYMBOL(<fs_acc>).
                <fs_acc>-vbund = lv_vbun.
              ENDLOOP.
            ENDIF.
          ELSEIF ls_acc-lifnr IS NOT INITIAL.
            SELECT SINGLE vbund FROM lfa1 INTO lv_vbun WHERE lifnr EQ ls_acc-lifnr.
            IF lv_vbun IS NOT INITIAL.
              lv_flag_temp = abap_true.
              LOOP AT t_accit ASSIGNING <fs_acc>.
                <fs_acc>-vbund = lv_vbun.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ENDLOOP.
        CLEAR:ls_acc.

      ENDIF.
      CLEAR:ls_trd_temp.
    ENDIF.

    DATA:lv_vbun_temp TYPE rassc,
         lv_vbun_flag TYPE c VALUE IS INITIAL.
    DATA(lt_trd_temp2) = lt_trd[].
    DELETE lt_trd_temp2 WHERE fisteps NE 'TCCLRG'.
    READ TABLE lt_trd_temp2 INTO ls_trd_temp WITH KEY value1 = sy-tcode.
    IF sy-subrc = 0.
      DATA(lt_acc_temp) = t_accit[].
      DELETE lt_acc_temp[] WHERE vbund IS INITIAL.
      LOOP AT lt_acc_temp INTO ls_acc.
        IF sy-tabix EQ 1.
          lv_vbun_temp = ls_acc-vbund.
        ELSE.
          IF ls_acc-vbund NE lv_vbun_temp.
            lv_vbun_flag = abap_true.
            EXIT.
          ENDIF.
        ENDIF.
        CLEAR:ls_acc.
      ENDLOOP.
      IF lv_vbun_flag IS NOT INITIAL.
        DATA(lt_acc_kna1) = t_accit[].
        DELETE lt_acc_kna1 WHERE kunnr IS INITIAL.
        DATA(lt_acc_lfa1) = t_accit[].
        DELETE lt_acc_lfa1 WHERE lifnr IS INITIAL.
        DATA(lt_acc_ska1) = t_accit[].
        DELETE lt_acc_ska1 WHERE saknr IS INITIAL.
        IF lt_acc_kna1 IS NOT INITIAL.
          SELECT kunnr , vbund FROM kna1 INTO TABLE @DATA(lt_kna1_temp) FOR ALL ENTRIES IN @lt_acc_kna1
                                                             WHERE kunnr EQ @lt_acc_kna1-kunnr.
        ENDIF.
        IF lt_acc_lfa1 IS NOT INITIAL.
          SELECT lifnr , vbund FROM lfa1 INTO TABLE @DATA(lt_lfa1_temp) FOR ALL ENTRIES IN @lt_acc_lfa1
                                                            WHERE lifnr EQ @lt_acc_lfa1-lifnr.
        ENDIF.
        IF lt_acc_ska1 IS NOT INITIAL.

          SELECT saknr , vbund FROM ska1
             INTO TABLE @DATA(lt_ska1_temp) FOR ALL ENTRIES IN @lt_acc_ska1
                                                          WHERE saknr EQ @lt_acc_ska1-saknr.

        ENDIF.
        LOOP AT t_accit ASSIGNING <fs_acc>.
          IF <fs_acc>-bschl NE '70' AND <fs_acc>-BSCHL NE '75'. " Added By Arnav on 30.06.2026
          READ TABLE lt_lfa1_temp INTO DATA(ls_lfa1_temp) WITH KEY lifnr = <fs_acc>-lifnr.
          IF sy-subrc = 0.
            lv_flag_temp = abap_true.
            IF ls_lfa1_temp-vbund IS NOT INITIAL.
              <fs_acc>-vbund = ls_lfa1_temp-vbund.
            ELSE.
              CLEAR:<fs_acc>-vbund.
            ENDIF.
          ELSE.
            READ TABLE lt_kna1_temp INTO DATA(ls_kna1_temp) WITH KEY kunnr = <fs_acc>-kunnr.
            IF sy-subrc = 0.
              lv_flag_temp = abap_true.
              IF ls_kna1_temp-vbund IS NOT INITIAL.
                <fs_acc>-vbund = ls_kna1_temp-vbund.
              ELSE.
                CLEAR:<fs_acc>-vbund.
              ENDIF.
            ELSE.
              READ TABLE lt_ska1_temp INTO DATA(ls_ska1_temp) WITH KEY saknr = <fs_acc>-saknr.
              IF sy-subrc = 0.
                lv_flag_temp = abap_true.
                IF ls_ska1_temp-vbund IS NOT INITIAL.
                  <fs_acc>-vbund = ls_ska1_temp-vbund.
                ELSE.
                  CLEAR:<fs_acc>-vbund.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
          CLEAR:ls_lfa1_temp,ls_kna1_temp,ls_ska1_temp.
         ENDIF.
        ENDLOOP.

      ENDIF.
    ENDIF.


    IF lv_flag_temp IS INITIAL.
      DATA:lv_hkont TYPE hkont.
      SELECT * FROM kna1 INTO TABLE @DATA(lt_kna1) FOR ALL ENTRIES IN @t_accit
                                                   WHERE kunnr EQ @t_accit-kunnr.
      SELECT * FROM lfa1 INTO TABLE @DATA(lt_lfa1) FOR ALL ENTRIES IN @t_accit
                                                   WHERE lifnr EQ @t_accit-lifnr.
      DATA ls_kna1 TYPE kna1.
      CLEAR ls_kna1.
      LOOP AT t_accit ASSIGNING FIELD-SYMBOL(<fs_accit>).

        IF  <fs_accit>-kunnr IS NOT INITIAL.
          READ TABLE lt_kna1 INTO ls_kna1 WITH KEY kunnr = <fs_accit>-kunnr.
          IF sy-subrc = 0.
            IF ls_kna1-vbund IS NOT INITIAL.
              <fs_accit>-vbund = ls_kna1-vbund.
              LOOP AT t_accit  ASSIGNING FIELD-SYMBOL(<fs_b1>).
              IF <fs_accit>-bschl NE '70' AND <fs_accit>-BSCHL NE '75'. " Added By Arnav on 30.06.2026
                MOVE <fs_accit>-hkont TO lv_hkont.
                IF lv_hkont IS NOT INITIAL.
                  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
                    EXPORTING
                      input  = lv_hkont
                    IMPORTING
                      output = lv_hkont.
                ENDIF.
                READ TABLE lt_trd INTO DATA(ls_trd) WITH KEY value1 = lv_hkont.

                IF ls_trd-fisteps NE 'ICTGL' AND <fs_b1>-kunnr IS INITIAL.
                  <fs_b1>-vbund = ls_kna1-vbund.
                ENDIF.
                ENDIF.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ELSEIF <fs_accit>-lifnr IS NOT INITIAL.
          READ TABLE lt_lfa1 INTO DATA(ls_lfa1) WITH KEY lifnr = <fs_accit>-lifnr.
          IF sy-subrc = 0.
            IF ls_lfa1-vbund IS NOT INITIAL.
              <fs_accit>-vbund = ls_lfa1-vbund.
              LOOP AT t_accit  ASSIGNING  <fs_b1>.
                IF <fs_b1>-bschl NE '70' AND <fs_b1>-BSCHL NE '75'. " Added By Arnav on 30.06.2026
                MOVE <fs_accit>-hkont TO lv_hkont.
                IF lv_hkont IS NOT INITIAL.
                  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
                    EXPORTING
                      input  = lv_hkont
                    IMPORTING
                      output = lv_hkont.
                ENDIF.
                CLEAR ls_trd.
                READ TABLE lt_trd INTO ls_trd WITH KEY value1 = lv_hkont.

                IF ls_trd-fisteps NE 'ICTGL' AND <fs_b1>-lifnr IS INITIAL.
                  <fs_b1>-vbund = ls_lfa1-vbund.
                ENDIF.
                endif.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ENDIF.
        CLEAR:ls_lfa1,ls_trd,lv_hkont,ls_kna1.
      ENDLOOP.
    ENDIF.
  ENDIF.

  SELECT
  value1
  FROM Zfi_trd_prtnr
  INTO TABLE @DATA(lt_match)
        WHERE fisteps = 'GLMAND'.

  SELECT
  value1
  FROM Zfi_trd_prtnr
  INTO TABLE @DATA(lt_TP_OBS)
        WHERE fisteps = 'OBSTP'.

LOOP AT t_accit ASSIGNING FIELD-SYMBOL(<ls_accit_1>).
          IF <ls_accit_1>-vbund IS INITIAL.
          READ TABLE lt_match TRANSPORTING NO FIELDS WITH KEY value1 = |{ <ls_accit_1>-hkont ALPHA = OUT }|.
          IF sy-subrc = 0.
            MESSAGE |Please enter the trading partner IN { <ls_accit_1>-hkont } .| TYPE 'E'.
          ENDIF.
          ELSE.
            READ TABLE lt_TP_OBS TRANSPORTING NO FIELDS WITH KEY value1 = |{ <ls_accit_1>-vbund ALPHA = OUT }|.
             IF sy-subrc = 0.
            MESSAGE |Please correct the trading partner { <ls_accit_1>-VBUND } .| TYPE 'E'.
          ENDIF.
        ENDIF.
        ENDLOOP.


  FIELD-SYMBOLS <fs_bseg> TYPE table.
  ASSIGN ('(SAPLFACG)T_BSEG[]') TO <fs_bseg>[].
  IF <fs_bseg> IS ASSIGNED.
    LOOP AT <fs_bseg> ASSIGNING <fs_b>.
      READ TABLE t_accit INTO DATA(l_accit) WITH KEY
      belnr = <fs_b>-belnr buzei = <fs_b>-buzei bukrs = <fs_b>-bukrs gjahr = <fs_b>-gjahr.
      IF sy-subrc  = 0.
        <fs_b>-vbund = l_accit-vbund.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
