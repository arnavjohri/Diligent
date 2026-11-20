*----------------------------------------------------------------------*
*   INCLUDE ZFI_CP_MAS_VEN_E0001                                       *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  cal_tot_amt
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cal_tot_amt.

  CLEAR ist_srcbsik.
  CLEAR g_tot_amt.

  CLEAR g_count2 .
  LOOP AT ist_srcbsik WHERE selcbox = 'X'.
    g_count2 =  g_count2 + 1 .
  ENDLOOP.

  IF g_count2  = 0.
    MESSAGE e286(zfi).
  ENDIF.


  CLEAR g_tot_amt.
  LOOP AT ist_srcbsik  WHERE  selcbox = 'X'.
    IF sy-subrc = 0.
      g_tot_amt = g_tot_amt  +  ist_srcbsik-amount .
    ENDIF.
  ENDLOOP.
ENDFORM.               " cal_tot_amt
*&---------------------------------------------------------------------*
*&      Form  get_confirmation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_confirmation.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Confirmation for posting'
      text_question         = text-001
      display_cancel_button = ' '
      start_column          = 25
      start_row             = 6
    IMPORTING
      answer                = g_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " get_confirmation
*&---------------------------------------------------------------------*
*&      Form  rem_pay_block
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rem_pay_block.

  DATA : l_tabix TYPE sy-tabix.

  CHECK NOT ist_srcbsik[] IS INITIAL.

  CLEAR  ist_bsiks.
  REFRESH ist_bsiks.

  ist_bsiks[] = ist_srcbsik[].

  DELETE ist_bsiks WHERE  selcbox <> 'X'.
*perform check if pyord exists if so do not pass those records to BDC
  clear : ist_bsiks_omit,ist_bsiks_vblk.
  refresh : ist_bsiks_omit,ist_bsiks_vblk.

  loop at ist_bsiks into wa_bsik.
    select single * FROM zfi_bcm_payordr
      where lifnr = wa_bsik-lifnr
        and belnr = wa_bsik-belnr
      and pyord <> ''
      and zstatus in ('001','002').

    if sy-subrc = 0.
      append wa_bsik to ist_bsiks_omit.
      delete ist_bsiks
      where lifnr = wa_bsik-lifnr
              and belnr = wa_bsik-belnr.
    endif.
    select single *
      from lfa1
      where lifnr = wa_bsik-lifnr
      and sperr = 'X'.
    if sy-subrc = 0.
      append wa_bsik to ist_bsiks_vblk.
      delete ist_bsiks
      where lifnr = wa_bsik-lifnr.
    endif.
  endloop.
  IF NOT ist_bsiks[] IS  INITIAL.

    CLEAR bsik.
    CLEAR wa_bsik_t.

    SELECT * INTO TABLE ist_bsik   FROM bsik
      FOR ALL ENTRIES  IN  ist_bsiks
      WHERE   lifnr = ist_bsiks-lifnr
            AND  bukrs  =  p_bukrs
             AND gjahr = ist_bsiks-gjahr
             AND belnr = ist_bsiks-belnr
             AND buzei = ist_bsiks-buzei.

    IF NOT ist_bsik IS INITIAL.

      CLEAR l_tabix.
      LOOP AT ist_bsik INTO wa_bsik_t.
        l_tabix = sy-tabix.
        IF wa_bsik_t-zlspr = g_zlspr_x.
          wa_bsik_t-zlspr =  g_zlspr_s.
          MODIFY ist_bsik  FROM  wa_bsik_t INDEX l_tabix  TRANSPORTING zlspr.
        ENDIF.
      ENDLOOP.


*      MODIFY  bsik FROM TABLE ist_bsik.
    ENDIF.

    CLEAR bseg.
    CLEAR wa_bseg.

*--- BEGIN OF CHANGE BY SAP_ABAP 08.08.2026 FOR ATC ---
    SELECT * INTO TABLE ist_bseg   FROM bseg
      FOR ALL ENTRIES  IN  ist_bsiks
      WHERE   lifnr = ist_bsiks-lifnr
            AND  bukrs  =  p_bukrs
             AND gjahr = ist_bsiks-gjahr
             AND belnr = ist_bsiks-belnr
             AND buzei = ist_bsiks-buzei ORDER BY PRIMARY KEY.  "#EC CI_DB_OPERATION_OK[2431747]
*--- END OF CHANGE BY SAP_ABAP 08.08.2026 FOR ATC ---

    IF NOT ist_bseg IS INITIAL.

      CLEAR l_tabix.
      LOOP AT ist_bseg INTO wa_bseg.
        l_tabix = sy-tabix.
        IF wa_bseg-zlspr = g_zlspr_x.
          wa_bseg-zlspr =  g_zlspr_s.
          MODIFY ist_bseg  FROM  wa_bseg INDEX l_tabix  TRANSPORTING zlspr.
        ENDIF.
      ENDLOOP.


" Code Remediation changes S4 2025_1_P Conversion **BEGIN OF CHANGE BY SAP_ABAP 16.06.2026  for ATC
* S/4: BSEG payment block (ZLSPR) via FI_DOCUMENT_CHANGE (FB02); direct write not allowed.
*      MODIFY  bseg FROM TABLE ist_bseg.
      LOOP AT ist_bseg INTO wa_bseg.
        PERFORM zz_s4_bseg_zlspr USING wa_bseg-bukrs wa_bseg-belnr wa_bseg-gjahr wa_bseg-buzei wa_bseg-zlspr.
      ENDLOOP.
      COMMIT WORK.
" Code Remediation changes S4 2025_1_P Conversion * *END OF CHANGE BY SAP_ABAP 16.06.2026 for ATC

    ENDIF.

  ENDIF.
ENDFORM.                    " rem_pay_block
*&---------------------------------------------------------------------*
*&      Form  bdc_f53
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM bdc_f53.

  CLEAR bdcdata.
  REFRESH bdcdata.

  DESCRIBE TABLE  ist_bsiks LINES g_count3.

  DATA : l_setdat(10).
  DATA : l_count(1).

if not ist_bsiks[] is initial.

  WRITE p_budat TO l_setdat  DD/MM/YYYY.



  PERFORM bdc_dynpro      USING 'SAPMF05A' '0103'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05A-XPOS1(03)'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=PA'.
  PERFORM bdc_field       USING 'BKPF-BLDAT'
                                l_setdat.
  PERFORM bdc_field       USING 'BKPF-BLART'
                                'BP'.
  PERFORM bdc_field       USING 'BKPF-BUKRS'
                                p_bukrs.
  PERFORM bdc_field       USING 'BKPF-BUDAT'
                                l_setdat.
*perform bdc_field       using 'BKPF-MONAT'
*                              '12'.
  PERFORM bdc_field       USING 'BKPF-WAERS'
                                'INR'.
  PERFORM bdc_field       USING 'RF05A-KONTO'
                                 p_bhkont.
  PERFORM bdc_field       USING 'BSEG-WRBTR'
                                 g_tot_amt.
  PERFORM bdc_field       USING 'BSEG-VALUT'
                                l_setdat.
*read table  ist_bsiks index 1.

  PERFORM bdc_field       USING 'RF05A-AGKON'
                                g_lifnr.
  PERFORM bdc_field       USING 'RF05A-AGKOA'
                                'K'.
  PERFORM bdc_field       USING 'RF05A-AGUMS'
                                'PF'.               "+ Change on 05-07-2013 by Vikas
  PERFORM bdc_field       USING 'RF05A-XNOPS'
                                'X'.
  PERFORM bdc_field       USING 'RF05A-XPOS1(01)'
                                ''.
  PERFORM bdc_field       USING 'RF05A-XPOS1(03)'
                                'X'.

  PERFORM bdc_dynpro      USING 'SAPMF05A' '0731'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05A-SEL01(01)'.

  l_count = 0.
  LOOP AT ist_bsiks.

    IF l_count = 6.


      PERFORM bdc_dynpro      USING 'SAPMF05A' '0731'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'RF05A-SEL01(01)'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=SL2'.

      PERFORM bdc_dynpro      USING 'SAPMF05A' '0608'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'RF05A-XPOS1(02)'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=ENTR'.
      PERFORM bdc_field       USING 'RF05A-XPOS1(01)'
                                    ''.
      PERFORM bdc_field       USING 'RF05A-XPOS1(02)'
                                    'X'.

      l_count = 0.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '0731'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                 'RF05A-SEL01(01)'.

    ENDIF.

    l_count = l_count + 1.
    CONCATENATE 'RF05A-SEL01(0' l_count ')' INTO g_syvar.
    PERFORM bdc_field       USING g_syvar ist_bsiks-belnr.


  ENDLOOP.

  PERFORM bdc_dynpro      USING 'SAPMF05A' '0731'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05A-SEL01(01)'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=PA'.

  PERFORM bdc_dynpro      USING 'SAPDF05X' '3100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=BS'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'DF05B-PSSKT(01)'.
  PERFORM bdc_field       USING 'RF05A-ABPOS'
                                '1'.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '0700'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RF05A-NEWBS'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=BU'.
  PERFORM bdc_transaction USING 'F-53'.
endif.
ENDFORM.                                                    " bdc_f53
*&---------------------------------------------------------------------*
*&      Form  bdc_dynpro
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0403   text
*      -->P_0404   text
*----------------------------------------------------------------------*
FORM bdc_field USING fnam fval.

  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.

ENDFORM.    "bdc_field

*&---------------------------------------------------------------------*
*&      Form  bdc_dynpro
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0480   text
*      -->P_0481   text
*----------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                  " bdcdynpro
*&---------------------------------------------------------------------*
*&      Form  bdc_transaction
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0495   text
*----------------------------------------------------------------------*
FORM bdc_transaction USING tcode .
  REFRESH ist_msgs.
  CLEAR ist_msgs.
  CALL TRANSACTION tcode USING bdcdata
                   MODE  'N'  " later oit should be 'E' CTUMODE
                   UPDATE 'S' " CUPDATE
                   MESSAGES INTO  ist_msgs. "ist_msg_f53.

ENDFORM.                    " bdc_transaction
*&---------------------------------------------------------------------*
*&      Form  get_mesg_f53
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_mesg_f53.
  data l_msg type string.
  CLEAR ist_msg_f53.
  REFRESH ist_msg_f53 .
  ist_msg_f53[] = ist_msgs[].
  clear g_refdoc.
  READ TABLE ist_msg_f53   WITH  KEY
                                msgtyp = 'S'
                                msgid = 'F5'
                                msgnr = '312'.
  IF sy-subrc = 0.
    CONCATENATE ist_msg_f53-msgv1 text-002 INTO  g_msgd.
    g_refdoc =  ist_msg_f53-msgv1.
    write :/ g_refdoc.
    loop at ist_srcbsik where selcbox = 'X'.
      wa_doc-bukrs = p_bukrs.
      wA_doc-lifnr = g_lifnr.
      wa_doc-budat = p_budat.
      wa_doc-belnr = ist_srcbsik-belnr .
      wa_doc-pdocnr = g_refdoc.
      append wa_doc  to ist_doc.
      clear wa_doc.
    endloop.


    modify zfi_cp_vend_docs  from  table ist_doc .

  ELSE.
    PERFORM put_payblock.
    leave to list-processing .
    format color col_heading.
    write :/ text-004.
    format color col_normal.
    Loop at ist_srcbsik where selcbox = 'X'.
      write :/ ist_srcbsik-belnr.
    endloop.
    format color col_heading.
* Begin of <RD1K985128>
    loop at ist_msg_f53 where msgtyp = 'E'.
      clear l_msg.
      CALL FUNCTION 'FORMAT_MESSAGE'
        EXPORTING
          ID        = ist_msg_f53-MSGID
          LANG      = 'EN'
          NO        = ist_msg_f53-MSGNR
          V1        = ist_msg_f53-MSGV1
          V2        = ist_msg_f53-MSGV2
          V3        = ist_msg_f53-MSGV3
          V4        = ist_msg_f53-MSGV4
        IMPORTING
          MSG       = l_msg
        EXCEPTIONS
          NOT_FOUND = 1
          OTHERS    = 2.
      IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

*    write :/ text-005.
      CONCATENATE ist_msg_f53-MSGID '(' ist_msg_f53-MSGNR ')-' l_msg INTO l_msg.
      write :/ l_msg.
*          write :/ 'Please contact - ICE-FI, Coreteam'.
    endloop.
    if not ist_bsiks_omit[] is INITIAL.
      loop at ist_bsiks_omit into wa_bsik.
        clear l_msg.
        CONCATENATE wa_bsik-BELNR 'PayOrder already created Pls Check ZFIAPP_PAYREP' into l_msg.
        write :/ l_msg.
      ENDLOOP.
*    write :/ 'Please contact - ICE-FI, Coreteam'.
    endif.
    if not ist_bsiks_vblk[] is INITIAL.
      loop at ist_bsiks_vblk into wa_bsik.
        clear l_msg.
        CONCATENATE wa_bsik-lifnr 'Vendor is blocked' into l_msg SEPARATED BY SPACE.
        write :/ l_msg.
      ENDLOOP.
*          write :/ 'Please contact - ICE-FI, Coreteam'.
    endif.
    write :/ 'Please contact - ICE-FI, Coreteam'.
* End of <RD1K985128>
  ENDIF.


ENDFORM.                    " get_mesg_f53
*&---------------------------------------------------------------------*
*&      Form  put_payblock
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM put_payblock.

  DATA : l_tabix LIKE sy-tabix .

  IF NOT ist_bsiks[] IS  INITIAL.
    CLEAR ist_bsik.
    CLEAR wa_bsik_t.

    SELECT * INTO TABLE ist_bsik   FROM bsik
      FOR ALL ENTRIES  IN  ist_bsiks
      WHERE   lifnr = ist_bsiks-lifnr
            AND  bukrs  =  p_bukrs
             AND gjahr = ist_bsiks-gjahr
             AND belnr = ist_bsiks-belnr
             AND buzei = ist_bsiks-buzei.

    IF NOT ist_bsik IS INITIAL.

      CLEAR l_tabix.
      LOOP AT ist_bsik INTO wa_bsik_t.
        l_tabix = sy-tabix.
        IF wa_bsik_t-zlspr = g_zlspr_s.
          wa_bsik_t-zlspr =  g_zlspr_x.
          MODIFY ist_bsik  FROM  wa_bsik_t INDEX l_tabix  TRANSPORTING zlspr.
        ENDIF.
      ENDLOOP.


*      MODIFY  bsik FROM TABLE ist_bsik.
    ENDIF.

    CLEAR ist_bseg.
    CLEAR wa_bseg.

*--- BEGIN OF CHANGE BY SAP_ABAP 08.08.2026 FOR ATC ---
    SELECT * INTO TABLE ist_bseg   FROM bseg
        FOR ALL ENTRIES  IN  ist_bsiks
        WHERE   lifnr = ist_bsiks-lifnr
              AND  bukrs  =  p_bukrs
               AND gjahr = ist_bsiks-gjahr
               AND belnr = ist_bsiks-belnr
               AND buzei = ist_bsiks-buzei ORDER BY PRIMARY KEY.  "#EC CI_DB_OPERATION_OK[2431747]
*--- END OF CHANGE BY SAP_ABAP 08.08.2026 FOR ATC ---

    IF NOT ist_bseg IS INITIAL.

      CLEAR l_tabix.
      LOOP AT ist_bseg INTO wa_bseg.
        l_tabix = sy-tabix.
        IF wa_bseg-zlspr = g_zlspr_s.
          wa_bseg-zlspr =  g_zlspr_x.
          MODIFY ist_bseg  FROM  wa_bseg INDEX l_tabix  TRANSPORTING zlspr.
        ENDIF.
      ENDLOOP.


" Code Remediation changes S4 2025_1_P Conversion **BEGIN OF CHANGE BY SAP_ABAP 16.06.2026  for ATC
* S/4: BSEG payment block (ZLSPR) via FI_DOCUMENT_CHANGE (FB02); direct write not allowed.
*      MODIFY  bseg FROM TABLE ist_bseg.
      LOOP AT ist_bseg INTO wa_bseg.
        PERFORM zz_s4_bseg_zlspr USING wa_bseg-bukrs wa_bseg-belnr wa_bseg-gjahr wa_bseg-buzei wa_bseg-zlspr.
      ENDLOOP.
      COMMIT WORK.
" Code Remediation changes S4 2025_1_P Conversion * *END OF CHANGE BY SAP_ABAP 16.06.2026 for ATC

    ENDIF.

  ENDIF.

ENDFORM.                    " put_payblock
*&---------------------------------------------------------------------*
*&      Form  gen_chec_number
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM gen_chec_number.

*---find prsent checueq no by cheq  lot no.
  PERFORM   find_chec_no.

  PERFORM   bdc_fch5.
ENDFORM.                    " gen_chec_number
*&---------------------------------------------------------------------*
*&      Form  find_chec_no
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM find_chec_no.
* Begin of RD1K971753 CAB_ALOK CR30004067.
  data len type i.
  data len_g_checl type i.
  data len_diff type i.
* End of RD1K971753 CAB_ALOK CR30004067.
  clear g_checl.
  SELECT SINGLE  * FROM pcec WHERE zbukr = p_bukrs
                             AND hbkid = p_hbkid
                          AND hktid = p_hktid
                          AND stapl = p_stapl.
  IF sy-subrc = 0.
* Begin of RD1K971753 CAB_ALOK CR30004067.
*    g_checl =  pcec-checl.
*    g_checl = g_checl + 1.
*    condense g_checl.

*  Requirement
*  if checl is SPACE then take g_checl = PCEC-CHECF
*      else take g_checl = pcec-checl + 1.
*   and preserve leading zeros of g_checl.
    if pcec-checl = SPACE.
      len = strlen( PCEC-CHECF ).  "required length of g_checl
      g_checl = PCEC-CHECF.
      condense g_checl.
      len_g_checl = strlen(  g_checl ). " current length of g_checl without spaces
*      Concat ZEROs
      if len <> len_g_checl .
        len_diff = len - len_g_checl.  "number of ZEROs to be added
        do len_diff times.
          CONCATENATE  '0' g_checl INTO g_checl .
        enddo.
      endif.
    else .
      len = strlen( PCEC-CHECL ).
      g_checl = pcec-checl + 1.
      condense g_checl.
      len_g_checl = strlen(  g_checl ).
*      Concat ZEROs
      if len <> len_g_checl .
        len_diff = len - len_g_checl.
        do len_diff times.
          CONCATENATE  '0' g_checl INTO g_checl .
        enddo.

      endif.

    endif.

* End of RD1K971753 CAB_ALOK CR30004067.
  ENDIF.
ENDFORM.                    " find_chec_no
*&---------------------------------------------------------------------*
*&      Form  bdc_fch5
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM bdc_fch5.
  IF NOT g_checl IS INITIAL.

    CALL FUNCTION 'DATE_TO_PERIOD_CONVERT'
      EXPORTING
        i_date   = p_budat
*       I_MONMIT = 00
        i_periv  = 'V3'
      IMPORTING
*       E_BUPER  =
        e_gjahr  = g_gjahr.
* EXCEPTIONS
*   INPUT_FALSE          = 1
*   T009_NOTFOUND        = 2
*   T009B_NOTFOUND       = 3
*   OTHERS               = 4
    .
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.



    CLEAR bdcdata .
    REFRESH bdcdata .


    PERFORM bdc_dynpro      USING 'SAPMFCHK' '0500'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'PAYR-CHECT'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=UPDA'.
    PERFORM bdc_field       USING 'PAYR-VBLNR'
                                  g_refdoc. "'1705000172'.
    PERFORM bdc_field       USING 'PAYR-ZBUKR'
                                  p_bukrs . "'mum'.
    PERFORM bdc_field       USING 'PAYR-GJAHR'
                                  g_gjahr .                 "'2007'.
    PERFORM bdc_field       USING 'PAYR-HBKID'
                                  p_hbkid .                 "'hb_01'.
    PERFORM bdc_field       USING 'PAYR-HKTID'
                                  p_hktid .                 "'hb001'.
    PERFORM bdc_field       USING 'PAYR-CHECT'       "################
                                  g_checl.                  "'10180'.
    PERFORM bdc_transaction USING 'FCH5'.


  ENDIF.


  ist_msg_fch[] = ist_msgs[].
  READ TABLE ist_msg_fch  WITH KEY msgtyp = 'S'
                                   msgid  ='FS'
                                   msgnr = '568'.
  IF sy-subrc = 0.
    g_cheq = ist_msg_fch-msgv4.
    clear ist_doc .
    refresh ist_doc.
    if not ist_bsiks[]  is initial.
      select *  into  table ist_doc from  zfi_cp_vend_docs
             for all entries in ist_bsiks
                        where  bukrs = p_bukrs
                        and  lifnr = g_lifnr
                        and  belnr =  ist_bsiks-belnr.  "#EC CI_NOORDER
      loop at ist_doc .
        ist_doc-checl =  g_cheq.
        modify ist_doc index sy-tabix  transporting checl.
      endloop.

      modify zfi_cp_vend_docs  from  ist_doc.
    endif.
  endif.
ENDFORM.                                                    " bdc_fch5
*&---------------------------------------------------------------------*
*&      Form  get_vendors
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_vendors.
  data :l_tabix like sy-tabix.
  SELECT lifnr  INTO  TABLE  ist_lifnr FROM   lfb1 WHERE   bukrs = p_bukrs
                                                    AND  lifnr IN s_lifnr.  "#EC CI_NOORDER
  IF NOT ist_lifnr[] IS INITIAL.

    SELECT *
     APPENDING CORRESPONDING FIELDS OF  TABLE ist_lifnr1
     FROM lfa1
        FOR ALL ENTRIES IN ist_lifnr
        WHERE  lifnr  =  ist_lifnr-lifnr .
  ENDIF.

  SORT ist_lifnr1 BY lifnr.
  DELETE ADJACENT DUPLICATES FROM ist_lifnr1.

  clear l_tabix.
  loop at ist_lifnr1 .
    l_tabix = sy-tabix.
    select single * from bsik where bukrs = p_bukrs
                              and lifnr = ist_lifnr1-lifnr.
    if sy-subrc = 0.
      continue.
    else.
      delete  ist_lifnr1  index l_tabix.
    endif.
  endloop.


  DESCRIBE TABLE ist_lifnr1  LINES g_tclin.


ENDFORM.                    " get_vendors
*&---------------------------------------------------------------------*
*&      Form  PRE_POST_CHECKS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PRE_POST_CHECKS .
  data : lv_ans type c.
  LOOP AT ist_srcbsik  WHERE  selcbox = 'X'.
*   N or S or L
    if ist_srcbsik-zwels = 'N' or ist_srcbsik-zwels = 'S' or ist_srcbsik-zwels = 'L'.
*    MESSAGE e100(zfi) with text-016.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
         TITLEBAR                    = 'Confirmation'
*         DIAGNOSE_OBJECT             = ' '
          TEXT_QUESTION               = text-017
         TEXT_BUTTON_1               = 'YES'(018)
         ICON_BUTTON_1               = ' '
         TEXT_BUTTON_2               = 'NO'(019)
         ICON_BUTTON_2               = ' '
         DEFAULT_BUTTON              = '1'
         DISPLAY_CANCEL_BUTTON       = ''
*         USERDEFINED_F1_HELP         = ' '
*         START_COLUMN                = 25
*         START_ROW                   = 6
*         POPUP_TYPE                  =
*         IV_QUICKINFO_BUTTON_1       = ' '
*         IV_QUICKINFO_BUTTON_2       = ' '
       IMPORTING
         ANSWER                      = lv_ans
*       TABLES
*         PARAMETER                   =
*       EXCEPTIONS
*         TEXT_NOT_FOUND              = 1
*         OTHERS                      = 2
                .
      IF SY-SUBRC <> 0.
* Implement suitable error handling here

      ENDIF.
      if lv_ans = '1'.

      else.
        l_flag = 'N'.
        exit.
      endif.
    endif.
*set to omit vendors LAQ RENT, LAQ DAMAGE, CSR VENDOR & OTHERS
    clear l_err.

    SELECT * FROM setleaf
INTO CORRESPONDING FIELDS OF TABLE ist_setleaf
WHERE setclass = g_setclass
  AND setname = g_setname.
    READ TABLE ist_setleaf WITH KEY setclass = g_setclass
                                    setname  = g_setname
                                    valfrom  = ist_srcbsik-lifnr.
    CHECK sy-subrc EQ 0.
    clear l_c.
    loop at ist_srcbsik into wa_bsik where selcbox = 'X'.
*      and belnr = ist_srcbsik-belnr.
      l_c = l_c + 1.
    endloop.
    if l_c > 1.
      loop at ist_srcbsik into WA_BSIK where selcbox = 'X'.
        WA_BSIK-selcbox = ''.
        modify ist_srcbsik from WA_BSIK TRANSPORTING selcbox.
      endloop.
      REFRESH CONTROL 'TC_OP_IT' FROM SCREEN '0200'.
      l_err = 'X'.
      MESSAGE e100(zfi) with text-020.
    endif.
  ENDLOOP.
ENDFORM.                    " PRE_POST_CHECKS
*&---------------------------------------------------------------------*
*&      Form  FILTER_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILTER_DATA .
  clear : sval_tab.
  refresh : sval_tab.

  sval_tab-tabname    = 'BSIK'.
  sval_tab-fieldname  = 'LIFNR'.
  sval_tab-fieldtext  = 'VENDOR'(008).
  append sval_tab.

  call function 'POPUP_GET_VALUES_USER_HELP'
            exporting
*           F1_FORMNAME               = ' '
*           F1_PROGRAMNAME            = ' '
*           F4_FORMNAME               = ' '
*           F4_PROGRAMNAME            = ' '
*           FORMNAME                  = ' '
                 popup_title               = 'Filter Criteria'(014)
*           PROGRAMNAME               = ' '
*           START_COLUMN              = '5'
*           START_ROW                 = '5'
*           NO_CHECK_FOR_FIXED_VALUES = ' '
*      IMPORTING
*           RETURNCODE                =
            tables
                 fields                    = sval_tab
*      EXCEPTIONS
*           ERROR_IN_FIELDS           = 1
*           OTHERS                    = 2
                 .

  if rcode eq 'A'.                     "user cancels from pop up box
    exit.
  endif.

  loop at ist_lifnr1 into wa_lfa1 where mark = 'X'.
    wa_lfa1-mark = ''.
    modify ist_lifnr1 from wa_lfa1 TRANSPORTING mark.
  endloop.

  loop at sval_tab.
*    read table trtc_tab with key tr_no = sval_tab-value.
    read TABLE sval_tab WITH KEY fieldname = 'LIFNR'.
    if sy-subrc = 0.
      if not sval_tab-value is initial.
        read table ist_lifnr1 with key lifnr = sval_tab-value.
      endif.
*      tc_vend-top_line = sy-tabix.
      loop at ist_lifnr1 into wa_lfa1 where lifnr = sval_tab-value.
        wa_lfa1-mark = 'X'.
        modify ist_lifnr1 from wa_lfa1 TRANSPORTING mark.
      endloop.
      tc_vend-top_line = sy-tabix.
      exit.
    endif.
  Endloop.

ENDFORM.                    " FILTER_DATA

*-- S/4 helper: change BSEG payment block via FI_DOCUMENT_CHANGE - SAP_ABAP 16.06.2026 --
FORM zz_s4_bseg_zlspr USING p_bukrs p_belnr p_gjahr p_buzei p_zlspr.
  DATA: lt_acchg TYPE STANDARD TABLE OF accchg, ls_acchg TYPE accchg.
  REFRESH lt_acchg. CLEAR ls_acchg.
  ls_acchg-fdname = 'ZLSPR'. ls_acchg-newval = p_zlspr.
  APPEND ls_acchg TO lt_acchg.
*BOC By SAP_ABAP on 20/11/26
* ST22 CALL_FUNCTION_PARM_MISSING / CX_SY_DYN_CALL_PARAM_MISSING in ZFIAPP:
* the TABLES parameter name was misspelled (T_ACCHG), so the mandatory
* T_ACCCHG table never reached FI_DOCUMENT_CHANGE and the call dumped
* instead of changing the payment block.
* ASSUMPTION: FI_DOCUMENT_CHANGE applies NEWVAL with OLDVAL left blank.
* Not verified - check FORM DOCUMENT_CHANGE (SE37) for T_ACCCHG-OLDVAL.
*  CALL FUNCTION 'FI_DOCUMENT_CHANGE' EXPORTING i_bukrs = p_bukrs i_belnr = p_belnr i_gjahr = p_gjahr
*       i_buzei = p_buzei TABLES t_acchg = lt_acchg EXCEPTIONS OTHERS = 0.
  CALL FUNCTION 'FI_DOCUMENT_CHANGE'
    EXPORTING i_bukrs = p_bukrs i_belnr = p_belnr i_gjahr = p_gjahr i_buzei = p_buzei
    TABLES    t_accchg = lt_acchg
    EXCEPTIONS OTHERS = 0.
*EOC By SAP_ABAP on 20/11/26
ENDFORM.
