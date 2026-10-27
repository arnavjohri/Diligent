METHOD if_ex_me_process_po_cust~check.
***********************************************************************
* CHANGE HISTORY                                                      *
*                                                                     *
* Mod Date    Changed by    Description                 Chng ID       *
* 30.12.2011  CAB_SPYADAV   Changes as per CR No.       SPP002        *
*                           30006706                                  *
*19.12.2012  CAB_LIPSY     Changes as per CR No.                      *
*                           30007809                                  *
*10.5.2013  CAB_DHIRAJ     Changes as per CR No.                      *
*                           30009068                                  *
*                                                                     *
* 30.12.2011  CAB_SPYADAV   Changes as per CR No.       SP005         *
*                           30011059                                  *
*
* 11.06.2014  CAB_LIPSY    Changes as per CR NO.
*                           30011059                                  *
* 31.07.2014  CAB_LIPSY    Changes as per CR NO.
*                          30011534
*03.09.2014   CAB_DNS     Made route feild compulsory   CR#30010908  <RD1K992655>
*                          for document type MSDM
*13.01.2015  CAB_SPYADAV   Collective no error        CR 30012236(LIPSY)  <RD1K995884>
*16.01.2015  CAB_SPYADAV  including E9 and above in mm CR 30012248(LIPSY)  <RD1K995934>
*29.01.2015 CAB_SPYADAV   FOR Modification in GL acocunt for C2-C3(Anamika) <RD1K996103 >
*02.03.2015  CAB_SPYADAV  Changes as per CR No.30012147(lipsy) <RD1K995870>
*10.04.2015  CAB_SPYADAV  Changes as per CR No.30012642(Anamika) <RD1K996938>
*
*11.05.2015  CAB_SPYADAV  Changes as per CR No.30012727(lipsy)<RD1K997136>*
*25.05.2015  CAB_SPYADAV  Changes as per CR No.30012811(lipsy) <RD1K997320>
*27.05.2015  CAB_SPYADAV  Changes as per CR No.30012757(lipsy) <RD1K997318>
*18.06.2015  CAB_SPYADAV  Changes as per CR No.30012897(lipsy) <RD1K997583>
*10.07.2015  CAB_SPYADAV  Changes as per CR No.30012989(lipsy) <RD1K997763>*
*1.08.2015   CAB_SPYADAV  Changes as per CR No.30013159(lipsy) <RD1K998103>
* 22/1/2016  CAB_SPYADAV  Changes as per CR No. 30013210(lipsy)<RD1K998289>*
*
***********************************************************************
  INCLUDE mm_messages_mac.
  DATA: t_text TYPE STANDARD TABLE OF mmpur_textlines.
  DATA: ls_mepoheader TYPE mepoheader.
  FIELD-SYMBOLS: <fs_text> TYPE mmpur_textlines.
  DATA: flag(1) TYPE c,
        lv_date TYPE sy-datum.
  DATA: lt_mepoitem TYPE STANDARD TABLE OF mepoitem,
        ls_mepoitem TYPE mepoitem.

  "start of addition by lipsy on 19.12.2012 for message e517  for all line items <RD1K982318>

  DATA: ls_mepoitem1  TYPE mepoitem,
        lt_mepoitem1  TYPE STANDARD TABLE OF mepoitem,
        v_check_kunnr TYPE char1.
  "end of addition by lipsy on 19.12.2012 for message e517  for all line items <RD1K982318>

  """"""""""""""""""""""""""""""""""""""""""""""""""""
  "start of addition by lipsy on 20.05.2015 RD1K997136
  DATA: ls_mepoitem2 TYPE mepoitem,
        v_check_del  TYPE char1.
  "end of addition by lipsy on 20.05.2015 RD1K997136
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  DATA: item TYPE STANDARD TABLE OF purchase_order_item.
  FIELD-SYMBOLS: <fs_item> TYPE purchase_order_item.

  DATA: lt_komv  TYPE STANDARD TABLE OF komv,
        ls_komv  TYPE komv,
        tmp_komv TYPE STANDARD TABLE OF komv.

  DATA: lt_schedule_ref  TYPE  purchase_order_schedules,
        tmp_schedule_ref TYPE  purchase_order_schedules.

  FIELD-SYMBOLS: <fs_schedule> TYPE purchase_order_schedule.

  DATA: ls_eket TYPE meposchedule,
        lt_eket TYPE STANDARD TABLE OF meposchedule.

  DATA: lt_accounting_ref  TYPE purchase_order_accountings,
        tmp_accounting_ref TYPE purchase_order_accountings.


  DATA : lt_shipping TYPE STANDARD TABLE OF ekpv,
         temp_ekpv   TYPE ekpv,
         wa_ekpv     LIKE LINE OF  lt_shipping. "cab_dns.

  FIELD-SYMBOLS: <fs_accounting> TYPE purchase_order_accounting.
  DATA: lt_accounting TYPE STANDARD TABLE OF mepoaccounting,
        ls_accounting TYPE mepoaccounting.
  FIELD-SYMBOLS: <fs_ekpo> TYPE mepoitem,
                 <fs_eket> TYPE meposchedule.
  FIELD-SYMBOLS: <fs_mepoitem> TYPE mepoitem,
                 <fs_komv>     TYPE komv.
*+SPP002 : Start
  DATA : l_txt_1(80),
         l_txt_2(80),
         l_txt_3(80),
         l_txt_4(80).
  DATA : g_flag.
*+SPP002 : End
*{ 30008447
  DATA : l_rel_stat TYPE zmm_tms-rel_stat.
*} 30008447
*{
  TYPES : BEGIN OF ty_data,
            pernr        TYPE pa0027-pernr,
            begda        TYPE pa0001-begda,
            endda        TYPE pa0001-endda,
            name         TYPE pa0001-ename,
            bukrs        TYPE pa0001-bukrs,
            werks        TYPE pa0001-werks,
            persk        TYPE pa0001-persk,
            kbu01        TYPE pa0027-kbu01,
            kgb01        TYPE pa0027-kgb01,
            kst01        TYPE pa0027-kst01,
            designo      TYPE pa9930-designo,
            r_p_cd       TYPE pa9930-r_p_cd,
            version      TYPE pa9930-version,
            designation  TYPE zdesignation_rev-sdesig_text,
            adesignation TYPE zdesignation_rev-adesig_text,
            disc_cd      TYPE zdesignation_rev-disc_cd,
            sbmod        TYPE pa0001-sbmod,
            """"""""""""""""""""""""""""""""""""""""""""""""""""
            "addition by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
            grade        TYPE zdesignation_rev-grade,
            "end of addition  by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
            """"""""""""""""""""""""""""""""""""""""""""""""""""

          END OF ty_data.

  TYPES : BEGIN OF ty_mm_ind,
            pernr   TYPE pa0027-pernr,
            disc_cd TYPE zdesignation_rev-disc_cd,
          END OF ty_mm_ind.
  DATA : ist_mm TYPE STANDARD  TABLE OF ty_mm_ind ."WITH HEADER LINE.
  DATA : wa_mm TYPE ty_mm_ind.
  DATA : ist_ind TYPE STANDARD  TABLE OF ty_mm_ind ."WITH HEADER LINE.
  DATA : wa_ind TYPE ty_mm_ind.

  DATA : ist_data TYPE STANDARD  TABLE OF ty_data ."WITH HEADER LINE.
  DATA : wa_data TYPE ty_data.
  DATA : l_sydate TYPE sy-datum.
  DATA : l_1         TYPE zmm_tms-tc_member1,
         l_1s        TYPE zmm_tms-tc_member1_s,
         l_2         TYPE zmm_tms-tc_member1,
         l_2s        TYPE zmm_tms-tc_member1_s,
         l_3         TYPE zmm_tms-tc_member1,
         l_3s        TYPE zmm_tms-tc_member1_s,
         l_4         TYPE zmm_tms-tc_member1,
         l_4s        TYPE zmm_tms-tc_member1_s,
         l_5         TYPE zmm_tms-tc_member1,
         l_5s        TYPE zmm_tms-tc_member1_s,
         l_mm,l_fi,l_indentor,l_er,l_f_cpa,l_f_cpa_err.

  DATA :  l_pernr TYPE pa0001-pernr.
*}




  """"""""""""""""""""""""""""""""""""""""""""""""""""
  "addition by Anamika on 29.01.2015 RD1K996103 FOR Modification in GL acocunt for C2-C3

  TYPES : BEGIN OF ty_gl_po,
            sakto TYPE zmm_gl_po_aa-sakto,

          END OF ty_gl_po.
  DATA : igl_mm TYPE STANDARD  TABLE OF ty_gl_po ."WITH HEADER LINE.
  DATA : wagl_mm TYPE ty_gl_po.

  DATA : v_line TYPE i,
         v_msg  TYPE string.
  DATA : pdyear(4) TYPE c,
         peyear(4) TYPE c,
         pryear(4) TYPE c.



  SELECT sakto INTO CORRESPONDING FIELDS OF TABLE igl_mm FROM zmm_gl_po_aa.

****   if not IGL_mm[] is initial.
****
****      READ TABLE IGL_mm into waGL_mm index 1.
****
****ENDIF.
  "end of addition  by Anamika on 29.01.2015 RD1K996103 FOR Modification in GL acocunt for C2-C3
  """"""""""""""""""""""""""""""""""""""""""""""""""""


  """"""""""""""""""""""""""""
  "added by lipsy on 30.03.2015 for less than 1000000 tender RD1K995870
  DATA:v_cpa TYPE c.
  "end of addition by lipsy on 30.03.2015 for less than 1000000 tender RD1K995870.

  """""""""""""""""""""""""""""""""

  DATA: lt_setleaf TYPE STANDARD TABLE OF setleaf,
        wa_setleaf TYPE setleaf.
  TYPES: BEGIN OF ty_bsart,
           sign(1),
           option(2),
           low       TYPE ekko-bsart,
           high      TYPE ekko-bsart,
         END OF ty_bsart.
  DATA: r_bsart TYPE TABLE OF ty_bsart,
        w_bsart TYPE ty_bsart.
  DATA: f_mandt(1) TYPE c.












******************************************************************************************************************************************
* Get PO Header and Item data, Condition data for validation
******************************************************************************************************************************************
  ls_mepoheader = im_header->get_data( ).  "GET HEADER DATA
  CALL METHOD im_header->get_conditions( IMPORTING ex_conditions = tmp_komv ). "
  APPEND LINES OF tmp_komv TO lt_komv.
  CLEAR tmp_komv[].
  item = im_header->get_items( ).
  LOOP AT item ASSIGNING <fs_item>.
    ls_mepoitem = <fs_item>-item->get_data( ).  "GET ITEM DATA
    CALL METHOD <fs_item>-item->get_conditions( IMPORTING ex_conditions = tmp_komv ). "

    tmp_schedule_ref =  <fs_item>-item->get_schedules( ).
    tmp_accounting_ref = <fs_item>-item->get_accountings( ).
    wa_ekpv = <fs_item>-item->get_shipping_data( ).
    APPEND LINES OF tmp_accounting_ref TO lt_accounting_ref.
    APPEND LINES OF tmp_schedule_ref TO lt_schedule_ref.
    APPEND LINES OF tmp_komv TO lt_komv.
    APPEND wa_ekpv TO lt_shipping.
    APPEND ls_mepoitem TO lt_mepoitem.
    CLEAR: ls_mepoitem, tmp_komv[], tmp_schedule_ref[], tmp_accounting_ref[],wa_ekpv.
  ENDLOOP.



*  DESCRIBE TABLE lt_mepoitem LINES v_line.


  IF g_trtyp = 'V' OR g_trtyp = 'H' .
    IF ls_mepoheader-bsart+0(1) = 'S' AND ls_mepoheader-frgke NE 'S'.
      IF  ls_mepoheader-kdatb IS INITIAL OR ls_mepoheader-kdate IS INITIAL.

*  Change for Lean.

*        MESSAGE e523(zmm).
         Message W523(zmm).
*  End Change for Lean.

        ch_failed = 'X'.
      ENDIF.
    ENDIF.

    IF ls_mepoheader-frgke NE 'S'.
      IF ls_mepoheader-zzvend_cat IS NOT INITIAL.
        IF ls_mepoheader-zzvend_cat = '5' OR ls_mepoheader-zzvend_cat = '6' OR ls_mepoheader-zzvend_cat = '7' OR ls_mepoheader-zzvend_cat = '13'.
          SELECT SINGLE brsch FROM lfa1 INTO @DATA(v_brsch) WHERE lifnr = @ls_mepoheader-lifnr.
          IF v_brsch = 'Z025' OR
             v_brsch = 'Z026' OR
             v_brsch = 'Z027' OR
             v_brsch = 'Z028' OR
             v_brsch = 'Z029' OR
             v_brsch = 'Z030' OR
             v_brsch = 'Z031' OR
            v_brsch = 'Z032' OR
            v_brsch = 'Z033' OR
            v_brsch = 'Z034' .
          ELSE.
            MESSAGE 'Vendor category does not match with vendor master data' TYPE 'E'.
            ch_failed = 'X'.
          ENDIF.
        ENDIF.

      ELSE.

        MESSAGE e322(zmm). "Line unCommented by Deepika on 14.05.2025
        ch_failed = 'X'.

      ENDIF.
    ENDIF.

    IF ls_mepoheader-frgke NE 'S'.


      lt_mepoitem1[] = lt_mepoitem[].

      SORT lt_mepoitem1 DESCENDING BY eindt.

      READ TABLE lt_mepoitem1 INTO ls_mepoitem1 INDEX 1.

      IF ls_mepoheader-bsart = 'SWO' AND ls_mepoheader-kdatb IS NOT INITIAL AND ls_mepoheader-kdate IS NOT INITIAL.

*        SELECT SINGLE * FROM ekpo INTO @DATA(v_ekpo) WHERE ebeln = @ls_mepoitem1-ebeln AND ebelp = @ls_mepoitem1-ebelp.
        IF   ls_mepoitem1-konnr IS NOT INITIAL.
          SELECT SINGLE * FROM ekko INTO @DATA(v_ekko) WHERE ebeln = @ls_mepoitem1-konnr.
          IF v_ekko-ebeln IS NOT INITIAL.
            IF ls_mepoheader-kdatb LT v_ekko-kdatb OR ls_mepoheader-kdatb GT v_ekko-kdate .
              MESSAGE 'PO validity start date outside OLA validity' TYPE 'E'.
            ELSEIF ls_mepoheader-kdate LT v_ekko-kdatb OR ls_mepoheader-kdate GT v_ekko-kdate.
              MESSAGE 'PO validity end date outside OLA validity' TYPE 'E'.
            ENDIF.
          ENDIF.
        ENDIF.

      ENDIF.

      CALL FUNCTION 'GM_GET_FISCAL_YEAR'
        EXPORTING
          i_date                     = ls_mepoitem1-eindt
          i_fyv                      = 'V3'
        IMPORTING
          e_fy                       = pdyear
        EXCEPTIONS
          fiscal_year_does_not_exist = 1
          not_defined_for_date       = 2
          OTHERS                     = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

      CALL FUNCTION 'GM_GET_FISCAL_YEAR'
        EXPORTING
          i_date                     = ls_mepoheader-kdate
          i_fyv                      = 'V3'
        IMPORTING
          e_fy                       = peyear
        EXCEPTIONS
          fiscal_year_does_not_exist = 1
          not_defined_for_date       = 2
          OTHERS                     = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.


      IF ls_mepoheader-bsart+0(1) = 'S' AND pdyear NE peyear.
        MESSAGE e525(zmm) WITH pdyear peyear ls_mepoitem1-ebelp .
      ENDIF.

      IF ls_mepoheader-bsart+0(1) = 'S' AND ls_mepoheader-kdate LT ls_mepoitem1-eindt.
        MESSAGE 'PO validity date cannot be less than the highest of the delivery dates in PO.' TYPE 'E'.
      ENDIF.

      IF ( g_trtyp = 'V' OR g_trtyp = 'H' )."" AND ls_mepoheader-frgke NE 'S'.



        SELECT SINGLE * FROM eban INTO @DATA(v_eban) WHERE banfn = @ls_mepoitem-banfn AND
                                                           bnfpo = @ls_mepoitem-bnfpo AND
                                                           loekz = ' ' .

        CALL FUNCTION 'GM_GET_FISCAL_YEAR'
          EXPORTING
            i_date                     = v_eban-lfdat
            i_fyv                      = 'V3'
          IMPORTING
            e_fy                       = pryear
          EXCEPTIONS
            fiscal_year_does_not_exist = 1
            not_defined_for_date       = 2
            OTHERS                     = 3.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

        IF v_eban-lfdat IS NOT INITIAL AND ls_mepoitem1-eindt IS NOT INITIAL.
          IF pryear NE pdyear.
*        mmpur_message_forced 'E' 'ZMM' '524' ls_mepoitem-ebelp '' '' ''.
*        CALL METHOD im_item->invalidate( ).
            CONCATENATE 'PO delivery date and PR delivery date in different fiscal years, check item' ls_mepoitem1-ebelp INTO v_msg SEPARATED BY space.
            MESSAGE v_msg TYPE 'E'.
          ENDIF.
        ENDIF.
      ENDIF.

    ENDIF.

    CLEAR: lt_setleaf[], wa_setleaf, w_bsart, r_bsart.

    SELECT * FROM setleaf INTO TABLE lt_setleaf WHERE setname = 'ZMM_CUST_DATA'.
    LOOP AT lt_setleaf INTO wa_setleaf.
      w_bsart-sign = wa_setleaf-valsign.
      w_bsart-option = wa_setleaf-valoption.
      w_bsart-low = wa_setleaf-valfrom.
      w_bsart-high = wa_setleaf-valto.
      APPEND w_bsart TO r_bsart.
    ENDLOOP.
    CLEAR: f_mandt, w_bsart.
    LOOP AT r_bsart INTO w_bsart.
      IF ls_mepoheader-bsart EQ w_bsart-low.
        f_mandt = 'X'.
      ENDIF.
    ENDLOOP.
    IF f_mandt IS INITIAL.
      IF ls_mepoheader-zzinsp_typ IS INITIAL.

        IF ls_mepoheader-bsart+0(1) NE 'S'.
          mmpur_metafield 90000121.
          mmpur_message 'E' 'ZMM' '877' '' '' '' ''.
        ENDIF.

      ENDIF.
    ENDIF.

  ENDIF.

*  clear ls_mepoitem1.

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
**  break abapuser02.
  TYPES : BEGIN OF ty_log,
            wmwst      TYPE wmwst,
            msatz      TYPE msatz_f05l,
            ktosl      TYPE ktosl,
            txjcd      TYPE txjcd,
            knumh      TYPE knumh,
            kbetr      TYPE kbetr_kond,
            kawrt      TYPE kawrt,
            hkont      TYPE hkont,
            kschl      TYPE kschl,
            txjcd_deep TYPE txjcd,
            txjlv      TYPE txjcd_level,
          END OF ty_log.

  TYPES : BEGIN OF ty_pop,
*            line     TYPE ebelp,
            netprice TYPE dmbtr,
            gst_tx   TYPE dmbtr,
            tcs      TYPE dmbtr,
            tot_amt  TYPE dmbtr,
          END OF ty_pop.
  TYPE-POOLS slis.
  DATA : i_log TYPE TABLE OF ty_log,
         w_log TYPE          ty_log,
         i_pop TYPE TABLE OF ty_pop,
         w_pop TYPE          ty_pop.

  DATA : cgst TYPE dmbtr,
         sgst TYPE dmbtr,
         igst TYPE dmbtr.
  DATA : cchoice LIKE sy-tabix,
         i_wrbtr TYPE bseg-wrbtr.
  DATA v_indx LIKE sy-index.



  LOOP AT lt_mepoitem INTO ls_mepoitem WHERE loekz IS INITIAL.

    w_pop-netprice = ls_mepoitem-netpr * ls_mepoitem-menge .
*    ls_mepoitem-netpr = ls_mepoitem-netpr * ls_mepoitem-menge.
    i_wrbtr  = w_pop-netprice.

*    w_pop-line = ls_mepoitem-ebelp.
*    w_pop-netprice = ls_mepoitem-netpr.


    REFRESH i_log.
    CALL FUNCTION 'CALCULATE_TAX_FROM_NET_AMOUNT'
      EXPORTING
        i_bukrs           = ls_mepoitem-bukrs
        i_mwskz           = ls_mepoitem-mwskz
*       I_TXJCD           = ' '
        i_waers           = ls_mepoitem-waers
        i_wrbtr           = i_wrbtr
*       I_ZBD1P           = 0
*       I_PRSDT           =
*       I_PROTOKOLL       =
*       I_TAXPS           =
*       I_ACCNT_EXT       =
*       I_ACCDATA         =
*       I_PRICING_REFRESH_TX       = ' '
* IMPORTING
*       E_FWNAV           =
*       E_FWNVV           =
*       E_FWSTE           =
*       E_FWAST           =
      TABLES
        t_mwdat           = i_log
      EXCEPTIONS
        bukrs_not_found   = 1
        country_not_found = 2
        mwskz_not_defined = 3
        mwskz_not_valid   = 4
        ktosl_not_found   = 5
        kalsm_not_found   = 6
        parameter_error   = 7
        knumh_not_found   = 8
        kschl_not_found   = 9
        unknown_error     = 10
        account_not_found = 11
        txjcd_not_valid   = 12
        OTHERS            = 13.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    LOOP AT i_log INTO w_log WHERE kschl = 'JICG' OR  kschl = 'JISG' OR  kschl = 'JIIG'
                               OR  kschl = 'JIUG' OR  kschl = 'JISN' OR  kschl = 'JICN'
                               OR  kschl = 'JIIN' OR  kschl = 'JIUN'.
      w_pop-gst_tx =  w_pop-gst_tx + w_log-wmwst.

    ENDLOOP.

    LOOP AT i_log INTO w_log WHERE kschl = 'JITC'.  "#EC CI_USAGE_OK[3159740]
      w_pop-tcs =  w_pop-tcs + w_log-wmwst.

    ENDLOOP.



    w_pop-tot_amt =  w_pop-gst_tx  + w_pop-netprice + w_pop-tcs.


*    APPEND w_pop TO i_pop.
    COLLECT w_pop INTO i_pop.
    CLEAR : sgst,cgst,igst,w_pop.
  ENDLOOP.
  CLEAR : sgst,cgst,igst,w_pop.
  CLEAR cchoice.


  DATA: net_v   TYPE string,
        gst_v   TYPE string,
        tcs_v   TYPE string,
        tot_v   TYPE string,
        final_v TYPE string,
        ans     TYPE string.
  CLEAR : net_v , gst_v ,tcs_v,tot_v,final_v .


  READ TABLE i_pop INTO w_pop INDEX 1.
  net_v = w_pop-netprice.
  gst_v = w_pop-gst_tx.
  tcs_v = w_pop-tcs.
  tot_v = w_pop-tot_amt.
  IF w_pop-tcs IS INITIAL.
    CONCATENATE 'Net Amt ( ' net_v ' ) GST  ( ' gst_v ' )  Total Amt ( ' tot_v  ' ) '
    INTO final_v SEPARATED BY space.

  ELSE.
    CONCATENATE 'Net Amt ( ' net_v ' ) GST  ( ' gst_v ' )  Total Amt ( ' tot_v  ' ). TCS of Rs' tcs_v
    'is also applicable.'
INTO final_v SEPARATED BY space.
  ENDIF.

*l_msg = 'Do you want to continue in new line'.  " your text

  IF sy-tcode EQ 'ME21N' OR sy-tcode EQ 'ME22N'.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = ''
        text_question         = final_v
        text_button_1         = 'Agree'
        text_button_2         = 'Disagree'
        default_button        = '1'
        display_cancel_button = ''
      IMPORTING
        answer                = ans.

    IF ans = '2'..
      LEAVE TO SCREEN sy-dynnr.
    ENDIF.

  ENDIF.
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  DATA : wa_zmm_tms TYPE zmm_tms,
         l_sy_uname TYPE sy-uname,
         l_mem      TYPE sy-uname,
         l_mem_s    TYPE sy-uname,
         l_frgzu    TYPE ekko-frgzu.
  DATA : l_res_flag .
  DATA :l_res_mem,l_res_exp,

        l_frggr      TYPE ekko-frggr,
        l_frgke      TYPE ekko-frgke,
        l_frgsx      TYPE ekko-frgsx,
        l_omit_bednr,
        l_omit_konnr,
        l_omit.

  DATA : l_po_ff_rel_dt TYPE zmm_tms_general-po_ff_rel_dt.

  """"""""""""""""""
  "ADDED BY LIPSY ON 9.05.2015 RD1K997136

  DATA:itab_t024 TYPE TABLE OF t024,
       wa_t024   LIKE LINE OF itab_t024.

  "END OF ADDITION BY LIPSY ON 9.05.2015 RD1K997136
  """"""""""""""""""""""""

  SELECT SINGLE frgke frgzu frggr frgsx
        FROM ekko
        INTO (l_frgke , l_frgzu , l_frggr , l_frgsx)
        WHERE ebeln =  ls_mepoheader-ebeln.

*---------------------------------------------------------------*
* Macro declaration for BDCDATA
*---------------------------------------------------------------*
  DEFINE disccd_.

    l_pernr = &1.

    CLEAR :  ist_data , wa_data.
    REFRESH : ist_data.

    """"""""""""""""""""""""

    """"""""""""""""
    MOVE sy-datum TO l_sydate.
    SELECT a~pernr a~begda a~endda a~ename AS name a~bukrs  a~werks
             a~persk a~sbmod  c~designo c~r_p_cd c~version
           d~sdesig_text AS designation d~adesig_text AS adesignation
           d~disc_cd AS disc_cd
  """""""""""""""""""""""""""""""""""""""""""""
 "addition  by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
      d~grade AS grade
 "end of addition  by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
  """"""""""""""""""""""""""""""""""""""""""""""""

             INTO CORRESPONDING FIELDS OF TABLE ist_data
        FROM ( ( pa0001 AS a INNER JOIN pa9930 AS c
              ON a~pernr = c~pernr ) INNER JOIN zdesignation_rev AS d
                 ON c~designo = d~desig_code AND
                     c~r_p_cd  = d~r_p_cd AND
                     c~version = d~version )
                  WHERE a~pernr =  &1 AND
                        a~sprps = ' '     AND
*Begin of <RD1K964434>.
*                        a~endda = '99991231' AND
                         a~endda GE l_sydate AND
*End of <RD1K964434>.
                         c~sprps = ' ' AND
*Begin of <RD1K964434>.
*                        c~endda = '99991231' .
                         c~endda GE l_sydate .
    IF NOT ist_data[] IS INITIAL.
      SORT ist_data BY endda DESCENDING.
      READ TABLE ist_data INTO wa_data INDEX 1.

      """"""""""""""""""""""

      """"""""""""""""""""
      "comment by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
*      IF wa_DATA-DISC_CD = '36'.
      "end of comment by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
      """""""""""""""""""""""""""""""""""""""""""""""""
      """"""""""""""""""""""""""""""""""""""""
      "addition by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
      IF wa_data-disc_cd = '36' OR wa_data-grade = 'E9' OR wa_data-grade = 'D'.
        "end of addition  by lipsy on 16.01.2015 RD1K995934 FOR INCLUDING E9 AND ABOVE
        """""""""""""""""""""""""""""""""""""
        l_mm = 'X'.
      ENDIF.
      IF wa_data-disc_cd = '13'.
        l_fi = 'X'.
      ENDIF.
      IF ( wa_data-disc_cd <> '13' AND wa_data-disc_cd <> '36' ).
        l_indentor = 'X'.
      ENDIF.
    ENDIF.

*    IF wa_DATA-DISC_CD <> '36'.
*      clear P_ZMM_TMS_TC_TC_MEMBER1.
*      message e206(zmm_oth) with text-202.
*    endif.
*    clear ls_bdcdata.
*    if &3 is initial.
*      ls_bdcdata-fnam  = &1.
*      ls_bdcdata-fval   = &2.
*    else.
*      ls_bdcdata-program  = &1.
*      ls_bdcdata-dynpro   = &2.
*      ls_bdcdata-dynbegin = &3.
*    endif.
*    append ls_bdcdata to lt_bdcdata.
  END-OF-DEFINITION.

  DEFINE set_mm_.
    IF NOT ist_data[] IS INITIAL.
      SORT ist_data BY endda DESCENDING.
      READ TABLE ist_data INTO wa_data INDEX 1.

      IF wa_data-disc_cd = '36'.
        l_mm = 'X'.
        wa_mm-disc_cd = wa_data-disc_cd.
        wa_mm-pernr = l_pernr.
        APPEND wa_mm TO ist_mm.
      ENDIF.
      IF wa_data-disc_cd <> '36'.
        l_indentor = 'X'.
        wa_ind-disc_cd = wa_data-disc_cd.
        wa_ind-pernr = l_pernr.
        APPEND wa_ind TO ist_ind.
      ENDIF.

    ENDIF.
  END-OF-DEFINITION.
  DEFINE set_fi_.
    IF NOT ist_data[] IS INITIAL.
      SORT ist_data BY endda DESCENDING.
      READ TABLE ist_data INTO wa_data INDEX 1.

      IF wa_data-disc_cd = '13'.
        l_fi = 'X'.
      ENDIF.
*      IF ( wa_DATA-DISC_CD <> '13' and wa_DATA-DISC_CD <> '36' ).
*        l_indentor = 'X'.
*      endif.
    ENDIF.
  END-OF-DEFINITION.
*{ tc_member_check.

  CLEAR wa_zmm_tms.
  DATA : wa_zmm_pur_tender_d TYPE zmm_pur_tender_d.
  DATA : l_cpa TYPE sy-uname.
  SELECT SINGLE * FROM zmm_tms
    INTO wa_zmm_tms
    WHERE submi = ls_mepoheader-submi.

  l_sy_uname = sy-uname.
  l_er = 'X'.
  l_1 = wa_zmm_tms-tc_member1.
  l_mem = l_1 .

  """""""""""""""""""""""""

  """""""""""""""""""""""
  SELECT SINGLE * FROM zmm_pur_tender_d
           INTO wa_zmm_pur_tender_d
             WHERE submi = ls_mepoheader-submi.
  IF sy-subrc = 0.

    """""""""""""""""""""""""""""""""""""""""""""""
    "commented by lipsy on 27.02.2015 for amount 1000000 RD1K995870.
*    IF WA_zmm_pur_tender_d-TNDR_VAL <= '500000'.
    "end of comment by lipsy on 27.02.2015 for amount 1000000 RD1K995870.
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""

    """""""""""""""""""""""""""""""""""""""""""""""""""
    "added by lipsy on 27.02.2015 for amount 1000000 RD1K995870.
    IF wa_zmm_pur_tender_d-tndr_val <= '1000000'.
      "end of addition by lipsy on 27.02.2015 for amount 1000000 RD1K995870.
      """"""""""""""""""""""""""""""""""""""""""""""""""""
*BREAK-POINT.


      l_cpa = wa_zmm_tms-cpa.
      SHIFT l_cpa LEFT DELETING LEADING '0'.
      IF ( l_cpa <> l_sy_uname ).
        l_f_cpa = ''.
        l_f_cpa_err = 'X'.
      ELSEIF ( l_cpa = l_sy_uname )..
        l_f_cpa = 'X'.
        l_f_cpa_err = ''.
      ENDIF.
      """""""""""""""""""""""""""""""""""

      "added by lipsy on 27.02.2015 for amount 1000000 RD1K995870.
    ELSE.
      l_cpa = wa_zmm_tms-cpa.
      SHIFT l_cpa LEFT DELETING LEADING '0'.
      IF ( l_cpa <> sy-uname ).
        v_cpa = 'N'.
      ELSEIF ( l_cpa = sy-uname ).
        v_cpa = 'Y'.
      ENDIF.

      "eadded by lipsy on 27.02.2015 for amount 1000000 RD1K995870.



      """"""""""""""""""""""""""""""""""""""""""""""


    ENDIF.
  ENDIF.

  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_1s = wa_zmm_tms-tc_member1_s.
  l_mem = l_1s .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_2 = wa_zmm_tms-tc_member2.
  l_mem = l_2 .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_2s = wa_zmm_tms-tc_member2_s.
  l_mem = l_2s.
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_3 = wa_zmm_tms-tc_member3.
  l_mem = l_3 .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_3s = wa_zmm_tms-tc_member3_s.
  l_mem = l_3s .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_4 = wa_zmm_tms-tc_member4.
  l_mem = l_4 .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_4s = wa_zmm_tms-tc_member4_s.
  l_mem = l_4s .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_5 = wa_zmm_tms-tc_member5.
  l_mem = l_5 .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.
  l_5s = wa_zmm_tms-tc_member5_s.
  l_mem = l_5s .
  IF l_mem <> '00000000' AND l_er = 'X'.
    SHIFT l_mem LEFT DELETING LEADING '0'.
    IF l_mem = l_sy_uname.
      l_er = ''.
    ENDIF.
  ENDIF.

  """""""""""""""""""

  """"""""""""""""""""""
**1.GET THE DISC_CD FOR EACH FIND IF HE IS MM
  disccd_ l_1.
  set_mm_ .
  IF l_mm IS INITIAL.
    disccd_ l_1s.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_2.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_2s.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_3.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_3s.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_4.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_4s.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_5.
    set_mm_ .
  ENDIF.
  IF l_mm IS INITIAL.
    disccd_ l_5s.
    set_mm_ .
  ENDIF.
**2.SEE IF SY-UNAME IS A TC MEMBER
**IF 1 & 2 NOT SATISFIED THEN RAISE MESSAGE

*if not  P_ZMM_TMS_TC_TC_MEMBER1 is initial.
*endif.

  LOOP AT  lt_mepoitem INTO ls_mepoitem1.
    IF ls_mepoitem1-loekz IS INITIAL.
      IF  NOT ls_mepoitem1-konnr       IS INITIAL.
        l_omit_konnr = 'X'.
      ENDIF.
      IF ls_mepoitem1-bednr       CP 'S15*'. ""
        l_omit_bednr = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.
*}


  """"""""""""""""""""""""""""""""
  "added by lipsy on 20.05.2015 for removing release strategy error in all deleted items RD1K997136
  IF lt_mepoitem[] IS NOT INITIAL.
    v_check_del = 'X'.
  ENDIF.

  LOOP AT lt_mepoitem INTO ls_mepoitem2 WHERE loekz IS INITIAL.
    v_check_del = ''.
  ENDLOOP.

  "end of addition by lipsy on 20.05.2015 RD1K997136
  """"""""""""""""""""""""""""""""""""""

  IF ls_mepoheader-ekgrp+0(1) <> 'O'.
    IF l_frgke <> 'S' AND NOT l_frgke IS INITIAL .
      IF l_frggr <> 'IO' .

        IMPORT l_res_flag TO l_res_mem FROM MEMORY ID 'ZERR_RESET'.
        IF sy-ucomm <> 'MERESET'.
          IF l_res_mem = 'X' AND sy-ucomm = 'MESAVE'.
          ELSE.
            IF ls_mepoheader-frggr <> 'IO'.

              """"""""""""""""""""""""""""""""
              "comment  by lipsy on 2.03.2015 for changing message "RD1K995870
*              MESSAGE e940(zmm) WITH 'Get new strategy by increasing' 'value by Re1;Afterwards may revert back to old value' .
              "end of comment by lipsy on 2.03.2015 for changing message "RD1K995870
              """""""""""""""""""""""""""""""""""""""""""""""
              """""""""""""""
              "added  by lipsy on 2.03.2015 for changing message "RD1K995870

              """"""""""""""""""""""""""""
              "added by lipsy on 20.05.2015 for removing release strategy error in all deleted items RD1K997136

              IF  v_check_del IS NOT INITIAL.

              ELSE.
                "end of addition by lipsy on 20.05.2015 RD1K997136
                """"""""""""""""""""""""""""""

                MESSAGE e940(zmm) WITH 'Get new strategy by Changing' 'value by Re1;Afterwards may revert back to old value' .

                """"""""""""""""""""""""""""
                "added by lipsy on 20.05.2015 for removing release strategy error in all deleted items RD1K997136

              ENDIF.
              "end of addition by lipsy on 20.05.2015  RD1K997136

              """"""""""""""""""""""""""""""

              "end of addition  by lipsy on 2.03.2015 for changing message "RD1K995870

              """""""""""""""
            ENDIF.
          ENDIF.
        ELSE.
          l_res_flag = 'X'.
          l_res_exp = 'X'.
          EXPORT l_res_flag = l_res_exp TO MEMORY ID 'ZERR_RESET'.

        ENDIF.
      ELSE.

        IF ls_mepoheader-bsart <> 'SWO'  .
          IF  ls_mepoheader-bsart <> 'MPOI'.

            SELECT SINGLE frgzu
              FROM ekko
              INTO l_frgzu
              WHERE ebeln = ls_mepoheader-ebeln.

*    if LS_MEPOHEADER-FRGZU = 'XX'.

            """"""""""""""""""""""
            " "addition by lipsy on 13.01.2015 for collective no
                                                            "RD1K995884
            IF ls_mepoheader-submi IS INITIAL.
              IF ( l_omit_konnr <> 'X' AND l_omit_bednr <> 'X' ) .
                IF l_frgzu = ''.
                  """"""""""
                  "add by lipsy on 1.04.2015 ""RD1K995870
                  IF   ls_mepoheader-zznat_proc = '10'.
                  ELSE.
                    "end of addition by lipsy on 1.04.2015 ""RD1K995870
                    """"""""""""""""
                    MESSAGE e803(zmm) WITH 'Enter Collective No. in Header Additional Data'.

                    """"""""""""""
                    "add by lipsy on 1.04.2015 ""RD1K995870
                  ENDIF.
                  "end of addition by lipsy on 1.04.2015 ""RD1K995870
                  """"""""""""""""
                ELSE.
                  MESSAGE i803(zmm) WITH 'Enter Collective No. in Header Additional Data after dereleasing.'.
                ENDIF.
              ENDIF.
            ELSE.
            ENDIF.


            "end of addition by lipsy on 13.01.2015 for collective no
                                                            "RD1K995884
            """"""""""""""""""""""""""
            IF l_frgzu = 'XX'.
              l_sy_uname = sy-uname.

              IF  ( l_omit_konnr = 'X' OR l_omit_bednr = 'X' ).
                l_omit = 'X'.
              ENDIF.

              IF ls_mepoheader-submi IS INITIAL.
                """"""""""""""""""""""""""""""""""""""""
                "commented by lipsy on 13.01.2015 for collective no
                                                            "RD1K995884
*              if ( l_omit_konnr <> 'X' and l_omit_bednr <> 'X' ) .
*                MESSAGE e803(zmm) WITH 'Enter Collective No. in Header Additional Data'.
**              MESSAGE i803(zmm) WITH 'Enter Collective No.  in Header Additional Data'.
*              endif.
                "end of comment by lipsy on 13.01.2015 for collective no
                                                            "RD1K995884
                """""""""""""""""""""""""""""""""""""""
              ELSE.

*              select SINGLE * from zmm_tms
*                into wa_zmm_tms
*                where submi = ls_mepoheader-submi.
*              if ( ls_mepoheader-bsart = 'SNB' or ls_mepoheader-bsart = 'MPOI' ).
*                l_mem = wa_zmm_tms-tc_member3.
*                l_mem_s = wa_zmm_tms-tc_member3_s.
*                if l_mem = '00000000'.
*                  l_mem = wa_zmm_tms-tc_member1.
*                  l_mem_s = wa_zmm_tms-tc_member1_s.
*                endif.
*              else.
*                l_mem = wa_zmm_tms-tc_member1.
*                l_mem_s = wa_zmm_tms-tc_member1_s.
*              endif.



*              if ( l_mm <> 'X' and l_indentor <> 'X' ) or ( l_er = 'X').
*                if ( l_omit_konnr <> 'X' and l_omit_bednr <> 'X' ).
*
**                  MESSAGE e940(zmm) WITH 'Only TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.
*                endif.
*              endif.

                """"""""""""""""""""""""""
                "added by lipsy on 31.03.2015 for emergency  cases RD1K995870
                "added by lipsy on 1.04.2015 for derelease""RD1K995870

                IF ls_mepoheader-frgke = 'S'.
                ELSE.

                  IF ls_mepoheader-bsart = 'MEMI' OR ls_mepoheader-bsart = 'SEM'.
******************   anamika***************
*    IF  v_cpa NE 'Y'.
* MESSAGE e940(zmm) WITH 'Only CPA can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.
* ENDIF.
******************   anamika***************
                  ENDIF.

                ENDIF.
                """""""""""""""""""""""""""""
                """""""""""
                """""""""""""""""""""""""""
                "added by lipsy on 9.05.2015 for swo RD1K997136

                REFRESH :itab_t024[].
                CLEAR:wa_t024.

                IF ls_mepoheader-ekgrp IS NOT INITIAL.
                  SELECT  * FROM t024 INTO CORRESPONDING FIELDS OF TABLE itab_t024
                  WHERE  ekgrp = ls_mepoheader-ekgrp.
                ENDIF.


                READ TABLE itab_t024 INTO wa_t024 WITH  KEY  ekgrp = ls_mepoheader-ekgrp.
                SEARCH wa_t024-eknam FOR 'MM'.
                IF sy-subrc = 0.
                  """"""""""""""""""""""""""""""""""""""""""""""""mmgrp"""""""""""""""""""
                ELSE.


                  """""""""""""""""""mmgrp"""""""""""""""""""""""""""""""""""""""""""""""""""
                  "end of addition  by lipsy on 9.05.2015 for swo RD1K997136
                  """"""""""""""""""""""""""

                  """""""""""""""

                  IF l_f_cpa = ''.

                    IF l_f_cpa_err = 'X'.
                      IF ( sy-ucomm = 'MERESET' OR sy-ucomm = 'MESAVE' ).
                      ELSE.
                        """"""""""""""""
                        "added  by lipsy on 30.03.2015 ""RD1K995870
******Start of Comment by Anamika on 13.04.2015 RD1K996938 for Changes in the PO for Audi**********
*   if  ls_mepoheader-ZZNAT_PROC = '10' or ls_mepoheader-ZZNAT_PROC = '13'.
******End of Comment by Anamika on 13.04.2015 RD1K996938 for Changes in the PO for Audi**********
******Start of addition by Anamika on 13.04.2015 RD1K996938 for Changes in the PO for Audi**********
                        IF  ls_mepoheader-zznat_proc = '10' .
******End of addition by Anamika on 13.04.2015 RD1K996938 for Changes in the PO for Audi**********

                          "end of addition  by lipsy on 30.03.2015  """RD1K995870
                          """"""""""""""""""
                          MESSAGE e940(zmm) WITH 'Only CPA can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.

                          """""""""""""""""""""""
                          "added  by lipsy on 30.03.2015 ""RD1K995870
                        ENDIF.
                        "end of addition  by lipsy on 30.03.2015  """RD1K995870
                        """""""""""""""""""""""""""


                        """"""""""""""""""""""""""""""""""""""""""""""
                        "added  by lipsy on 15.05.2015
                        IF  ls_mepoheader-zznat_proc = '9' .
                          MESSAGE e940(zmm) WITH 'Only CPA can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.
                        ENDIF.
                        "end of addition  by lipsy on 15.05.2015
                        """""""""""""""""""""""""""""""""""""""""""""""""""""
                      ENDIF.
                      """"""""""""""""""
                      """""""""""""""""""""""""""""""""""""greater than 1000000 tender value
                      "added  by lipsy on 30.03.2015 ""RD1K995870
                    ELSE.
                      IF ( sy-ucomm = 'MERESET' OR sy-ucomm = 'MESAVE' ).
                      ELSE.
                        IF v_cpa = 'N'.
******Start of Comment by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
*                         if  ls_mepoheader-ZZNAT_PROC = '10' or ls_mepoheader-ZZNAT_PROC = '13'.
******End of Comment by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
******Start of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
                          IF  ls_mepoheader-zznat_proc = '10' .
******End of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
                            MESSAGE e940(zmm) WITH 'Only CPA can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.
                          ENDIF.
                        ENDIF.
                      ENDIF.
                      """end of addition by lipsy on 30.03.2015 ""RD1K995870
                      """"""""""""""""""""""""""""""""""""""""""""""""""""
                      """""""""""""""""""""""""
                    ENDIF.
                  ENDIF.


                  IF l_f_cpa <> 'X'.
                    IF ( ( sy-ucomm = 'MERESET' OR sy-ucomm = 'MESAVE' ) AND ( l_frgzu = 'XX' OR l_frgzu = 'X' ) ).
                    ELSE.
                      IF ( l_mm <> 'X' AND l_omit <> 'X' )  OR ( l_er = 'X')   .

                        IF ( l_omit_konnr <> 'X' AND l_omit_bednr <> 'X' ).
*                 if ( ls_mepoheader-bsart = 'SNB' or ls_mepoheader-bsart = 'MPOI' ).
                          """""""""""""""""""""""""""""""""""""""""
                          "addition  by lipsy on 14.01.2015 for removing error in case of mm field null"RD1K995884
                          IF l_mm <> 'X'.
                            """""""""""""""""""""""
                            "added  by lipsy on 30.03.2015 ""RD1K995870
                            IF ls_mepoheader-bsart = 'MPOI'.
                            ELSE.

                              IF  ls_mepoheader-zznat_proc = '11' OR ls_mepoheader-zznat_proc = '8' OR ls_mepoheader-zznat_proc = '12'.

                                MESSAGE e940(zmm) WITH 'Only MM/Indentor TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.

                              ELSE.
                              ENDIF.
                            ENDIF.
                            "end of addition  by lipsy on 30.03.2015 ""RD1K995870
                            """""""""""""""""""""""""""""""""""""""""""""

                          ELSE.

                            "end of addition  by lipsy on 14.01.2015 for removing error in case of mm field null"RD1K995884
                            """"""""""""""""""""""""""""""""""""""""""
                            """"""""""""""""""""""""""""""


                            """"""""""""""""""""""""""""""""""
                            IF ls_mepoheader-bsart = 'MPOI'.


                              MESSAGE e940(zmm) WITH 'Only TC Member of Indenting Section can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.
                            ELSE.
                              """"""""""""""""""""""""""
                              "added  by lipsy on 30.03.2015 ""RD1K995870
                              IF  ls_mepoheader-zznat_proc = '11' OR ls_mepoheader-zznat_proc = '8' OR ls_mepoheader-zznat_proc = '12'.
*                         end of addition  by lipsy on 30.03.2015 ""RD1K995870

                                """"""""""""""""""""""""""""""
                                MESSAGE e940(zmm) WITH 'Only MM/Indentor TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.

                                """""""""""""""""""
                                "added  by lipsy on 30.03.2015 ""RD1K995870
                              ELSE.
                              ENDIF.
                              "end of addition  by lipsy on 30.03.2015 ""RD1K995870

                              """"""""""""""""""""""""
                            ENDIF.

                            """""""""""""""""""""""""""""""""""""""""""""
                            "addition  by lipsy on 14.01.2015 for removing error in case of mm field null"RD1K995884
                          ENDIF.
                          "end of addition  by lipsy on 14.01.2015 for removing error in case of mm field null"RD1K995884
                          """""""""""""""""""""""""""""""""""""""""""""""

                        ENDIF.



                        IF ( l_indentor <> 'X' AND l_frgsx <> '01' AND ( l_omit <> 'X' ) )

    """""""""""""""""""""""""""""""""""""""
    "added BY LIPSY ON 11.05.2015 RD1K997136
                          .
* *End of addition BY LIPSY ON 11.05.2015 RD1K997136
                          """"""""""""""""""""""""""""""
                          "COMMENT BY LIPSY ON 11.05.2015 RD1K997136
*                       or ( l_er = 'X') .
*                      End of COMMENT BY LIPSY ON 11.05.2015 RD1K997136
                          """""""""""
*                if ( ls_mepoheader-bsart = 'SNB' or ls_mepoheader-bsart = 'MPOI' ).
                          IF ls_mepoheader-bsart = 'MPOI'.
                            MESSAGE e940(zmm) WITH 'Only TC Member of Indenting Section can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.
                          ELSE.
                            """"""""""""""""""""
                            "added  by lipsy on 30.03.2015 ""RD1K995870
                            IF  ls_mepoheader-zznat_proc = '11' OR ls_mepoheader-zznat_proc = '8' OR ls_mepoheader-zznat_proc = '12'.
                              "end of addition  by lipsy on 30.03.2015 ""RD1K995870
                              """""""""""""""""""""
                              MESSAGE e940(zmm) WITH 'Only MM/Indentor TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.
                              """""""""""
                              "added  by lipsy on 30.03.2015 ""RD1K995870
                            ELSE.
                            ENDIF.
                            "end of addition  by lipsy on 30.03.2015 ""RD1K995870
                            """""""""""""""
                          ENDIF.
                        ENDIF.
                      ENDIF.
                    ENDIF.
                  ENDIF.

**        if not wa_zmm_tms-tc_member1 is initial.
**          if not l_mem is initial.
*              if  l_mem <> '00000000'.
*                shift l_mem left deleting leading '0'.
***      if wa_zmm_tms-tc_member1 <> l_sy_uname.
**                if l_mem <> l_sy_uname .
*                if ( l_mm <> 'X' or l_indentor <> 'X' ).
*                  if ( ls_mepoheader-bsart = 'SNB' or ls_mepoheader-bsart = 'MPOI' ).
*                    MESSAGE e940(zmm) WITH 'Only TC Member of Indenting Section can Release' 'the PO. Refer Tender No:' ls_mepoheader-submi.
*                  else.
*                    MESSAGE e940(zmm) WITH 'Only MM TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.
*                  endif.
*                endif.
**            if not l_mem_s is initial.
*                if l_mem_s <> '00000000'.
*                  shift l_mem_s left deleting leading '0'.
**                  if l_mem_s <> l_sy_uname .
*                  if ( l_mm <> 'X' or l_indentor <> 'X' ).
*                    if ( ls_mepoheader-bsart = 'SNB' or ls_mepoheader-bsart = 'MPOI' ).
*                      MESSAGE e940(zmm) WITH 'Only TC Member of Indenting Section can Release'  'the PO. Refer Tender No:' ls_mepoheader-submi.
*                    else.
*                      MESSAGE e940(zmm) WITH 'Only MM TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.
*                    endif.
*                  endif.
*                endif.
*              else.
*                MESSAGE e940(zmm) WITH 'Only TC Member can Release the PO. Refer Tender No:' ls_mepoheader-submi.
*              endif.


                  """""""""""""""""""""""""
                  "added by lipsy on 9.05.2015 RD1K997136
                ENDIF.

                "end of addition by lipsy on 9.05.2015 RD1K997136
                """"""""""""""""""""""
              ENDIF.



            ENDIF.

            "
          ENDIF.
          "
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

  LOOP AT lt_schedule_ref ASSIGNING <fs_schedule>.
*    CALL METHOD <FS_SCHEDULE>-SCHEDULE->GET_DATA( RECEIVING RE_DATA = LS_EKET ).
    ls_eket = <fs_schedule>-schedule->get_data( ).
    APPEND ls_eket TO lt_eket.
    CLEAR ls_eket.
  ENDLOOP.

  LOOP AT lt_accounting_ref ASSIGNING <fs_accounting>.
    ls_accounting = <fs_accounting>-accounting->get_data( ).
    APPEND ls_accounting TO lt_accounting.
    CLEAR ls_accounting.
  ENDLOOP.
*  Added By Rahul Gupta
*  IF sy-tcode = 'ME21N' .
  LOOP AT lt_accounting INTO ls_accounting.
    IF ls_accounting-sakto = '200905' OR ls_accounting-sakto = '201491'.
      IF ls_accounting-aufnr IS INITIAL OR ls_accounting-aufnr <> 'OVLBD0001SOU' OR ls_accounting-aufnr <> 'OVLBD0002SOU'.
        MESSAGE 'Please maintain order OVLBD0001SOU / OVLBD0002SOU for DEV-SOU/DEV-Non SOU in Account assignment..' TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDLOOP.
*  ENDIF.
*  end of add
******************************************************************************************************************************************
* Check to make Text field F17 mandatory for Document type 'MS*'
******************************************************************************************************************************************
*  CLEAR FLAG.
*  IF G_TRTYP = 'H' OR G_TRTYP = 'V'.
**    LV_DATE = '20090522'.
*    LS_MEPOHEADER = IM_HEADER->GET_DATA( ).
**    IF LS_MEPOHEADER-AEDAT > LV_DATE.
*    IF LS_MEPOHEADER-MEMORY EQ 'X'.
*
*    ELSE.
*      IF LS_MEPOHEADER-BSART+0(2) NE 'MS'.
*        CALL METHOD IM_HEADER->IF_LONGTEXTS_MM~GET_TEXT( EXPORTING IM_TDID = 'F17' IMPORTING EX_TEXTLINES = T_TEXT ).
*        IF T_TEXT[] IS NOT INITIAL.
*          LOOP AT T_TEXT ASSIGNING <FS_TEXT>.
*            IF <FS_TEXT>-TDLINE NE SPACE.
*              FLAG = 'X'.
*            ENDIF.
*          ENDLOOP.
*        ENDIF.
*        IF FLAG IS INITIAL.
*          CALL FUNCTION 'FC_POPUP_ERR_WARN_MESSAGE'
*            EXPORTING
*              POPUP_TITLE  = 'Error'
*              IS_ERROR     = 'X'
*              MESSAGE_TEXT = TEXT-020
*              START_COLUMN = 30
*              START_ROW    = 8.
*          IF SY-TCODE EQ 'ME21N' OR SY-TCODE EQ 'ME22N' OR SY-TCODE EQ 'ME23N'  .
*            MMPUR_METAFIELD 357.
*            MMPUR_MESSAGE 'E' 'ZMM' '875' '' '' '' ''.
**              CALL METHOD CALL_VIEW->HANDLE_EVENT( 'PAI' ).
**            LEAVE TO SCREEN 0014.
*
**            MMPUR_MESSAGE_ENACO 'E' 'ZMM' '102'  TEXT-001 TEXT-002 TEXT-003 'E'.
*          ENDIF.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ENDIF.
*    ENDIF.
*  ENDIF.

******************************************************************************************************************************************
*Check Vendor Status - Based On Vendor Evaluation
******************************************************************************************************************************************
  DATA: l_date TYPE sy-datum.
  DATA: ls_zmm_ve_vnstatus TYPE zmm_ve_vnstatus.
  l_date = '20050724'.
*  IF SY-DATUM GE L_DATE AND I_TRTYP = 'H'.
  IF sy-datum GE l_date AND g_trtyp = 'H'.
*    LS_MEPOHEADER = IM_HEADER->GET_DATA( ).
    SELECT SINGLE * FROM zmm_ve_vnstatus INTO ls_zmm_ve_vnstatus
            WHERE bukrs = ls_mepoheader-bukrs AND
                  ekorg = ls_mepoheader-ekorg AND
                  lifnr = ls_mepoheader-lifnr.
    IF sy-subrc = 0.
      IF ls_mepoheader-bstyp = 'F' AND ls_zmm_ve_vnstatus-po = 'X'.
        MESSAGE e781(zmm) WITH ls_mepoheader-lifnr ls_mepoheader-bukrs ls_mepoheader-ekorg 'PO'                                                                     .
      ENDIF.
      IF ls_mepoheader-bstyp = 'A' AND ls_zmm_ve_vnstatus-rfq = 'X'.
        MESSAGE e781(zmm) WITH ls_mepoheader-lifnr ls_mepoheader-bukrs ls_mepoheader-ekorg 'RFQ'                                                                   .
      ENDIF.
      IF ls_mepoheader-bstyp = 'K' AND ls_zmm_ve_vnstatus-po = 'X'.
        MESSAGE e781(zmm) WITH ls_mepoheader-lifnr ls_mepoheader-bukrs ls_mepoheader-ekorg 'CONTRACT'.
      ENDIF.
    ENDIF.
  ENDIF.

******************************************************************************************************************************************
* For shipping data check ROUTE feild is not empty for Txn ME22n and Me21n.
******************************************************************************************************************************************
*  IF     ( sy-tcode = 'ME21N' OR sy-tcode = 'ME22N' )  AND
*                          ( ls_mepoheader-bsart = 'MSDM' OR ls_mepoheader-bsart = 'MSIM' ) .
*
*    LOOP AT lt_shipping INTO wa_ekpv.
*        IF wa_ekpv-ROUTE is INITIAL.
*            READ TABLE lt_mepoitem ASSIGNING <fs_ekpo> WITH KEY ebeln = wa_ekpv-EBeln ebelp = wa_ekpv-EBELP .
*            MESSAGE e533(ZMM) with <fs_ekpo>-TXZ01.
*        ENDIF.
*    ENDLOOP.
*
*
* ENDIF.






******************************************************************************************************************************************
* SWO check
******************************************************************************************************************************************
  TYPES : BEGIN OF ty_eban,
            banfn TYPE eban-banfn,
            bnfpo TYPE eban-bnfpo,
            bsart TYPE eban-bsart,
            badat TYPE eban-badat,
            preis TYPE eban-preis,
            loekz TYPE eban-loekz,
            waers TYPE eban-waers,
          END OF ty_eban.
  DATA: ist_eban TYPE STANDARD TABLE OF ty_eban,
        wa_eban  TYPE ty_eban,
        line     TYPE i.

  DATA: l_bukrs TYPE t001k-bukrs.
  DATA: wa_ekko   TYPE mepoheader,
        ist_tekpo TYPE STANDARD TABLE OF mepoitem,
        ist_teket TYPE STANDARD TABLE OF meposchedule,
        lv_mara   TYPE mara.
  DATA: ls_zmm_pur_tender_d TYPE zmm_pur_tender_d.
  CONSTANTS : c_error(1) VALUE 'W' .
  DATA: g_greater_apr(1) TYPE c.  "Flag whether PO has been created after April 1
  DATA : l_sy_subrc TYPE sy-subrc,
         l_apr_date TYPE sy-datum VALUE '20040401'.
  DATA: l_memory TYPE ekko-memory,
        ls_ekpo  TYPE ekpo.

  DATA : ist_mcon TYPE STANDARD TABLE OF zmm_mcon.
  FIELD-SYMBOLS: <fs_mcon> TYPE zmm_mcon.
  DATA: l_ekpo TYPE STANDARD TABLE OF ekpo,
        w_ekpo TYPE ekpo,
        w_ekko TYPE ekko,
        t_ekkn TYPE STANDARD TABLE OF ekkn.
  FIELD-SYMBOLS: <fs_ekkn> TYPE ekkn.

  DATA: l_eban TYPE STANDARD TABLE OF eban,
        w_eban TYPE eban.

  TYPES: BEGIN OF ty_range,
           sign(1)   TYPE c,
           option(2) TYPE c,
           low       TYPE ekpo-werks,
           high      TYPE ekpo-werks,
         END OF ty_range.
  DATA: wa_werks_wshp TYPE ty_range.
  DATA: r_werks_wshp TYPE RANGE OF ekpo-werks.
  DATA: r_werks TYPE RANGE OF ekpo-werks,
        w_werks TYPE ty_range.

  TYPES: BEGIN OF ty_werks,
           valfrom TYPE ekpo-werks,
           valto   TYPE ekpo-werks,
         END OF ty_werks.
  DATA: ist_werks TYPE STANDARD TABLE OF ty_werks,
        wa_werks  TYPE ty_werks.
  DATA: ls_mchb TYPE mchb.
  CONSTANTS: c_000 TYPE setheader-setclass VALUE '0000',
             c_set TYPE setheader-setname  VALUE 'ZMM_ENTRY_TAX_PLANTS'.
  DATA : "L_FISTL TYPE EBAN-FISTL,
*           L_FIPOS TYPE EBAN-FIPOS,
    l_tabix    TYPE sy-tabix,
    l_poyear   TYPE bseg-gjahr,
    l_pryear   TYPE bseg-gjahr,
    l_lfdat    TYPE eban-lfdat,
    l_lfdatscr TYPE eban-lfdat,

    """""""""""""""""""""""""""""""""""""""""""""
    "added by lipsy on 30.07.2014 for currency conversion
    """""""""""""""""for same currency in po pr RD1K994119

    l_waers    TYPE eban-waers,
    "end of addition by lipsy on 30.07.2014 for currency conversion
    """""""""""""""""for same currency in po pr RD1K994119

    """"""""""""""""""""""""""""""""""""""""
    "added by lipsy on 18.06.2015 RD1K997583
    v_delvdate TYPE eban-lfdat,

    "end of addition by lipsy on 18.06.2015 RD1K997583
    """""""""""""""""""""""""""""""""""""""

    """"""""""""""""""""""""""""""""""""""""""""""""""""
    g_badat    TYPE eban-badat.

  TYPES: BEGIN OF ty_eban1,
           l_fistl TYPE eban-fistl,
           l_fipos TYPE eban-fipos,
           l_lfdat TYPE eban-lfdat,
           g_badat TYPE eban-badat,
           """""""""""""""""""""""""""""""""""""""""""""
           "added by lipsy on 30.07.2014  for currency conversion
           """""""""""""""""for same currency in po pr RD1K994119

           l_waers TYPE eban-waers,

           "end of addition by lipsy on 30.07.2014 for currency conversion
           """""""""""""""""for same currency in po pr RD1K994119


           """"""""""""""""""""""""""""""""""""""""""""""""""""""""
         END OF ty_eban1.

  DATA: ls_eban TYPE ty_eban1.
  TYPES: BEGIN OF ty_cdpos,
           objectid   TYPE cdpos-objectid,
           objectclas TYPE cdpos-objectclas,
           tabname    TYPE cdpos-tabname,
           fname      TYPE cdpos-fname,
           value_old  TYPE cdpos-value_old,
           changenr   TYPE cdpos-changenr,
         END OF ty_cdpos.


  TYPES: BEGIN OF ty_cdhdr,
           objectid   TYPE cdpos-objectid,
           objectclas TYPE cdpos-objectclas,
           changenr   TYPE cdpos-changenr,
           udate      TYPE cdhdr-udate,
           utime      TYPE cdhdr-utime,
         END OF ty_cdhdr.
  DATA: ist_cdpos TYPE STANDARD TABLE OF ty_cdpos,
        ist_cdhdr TYPE STANDARD TABLE OF ty_cdhdr,
        wa_cdhdr  TYPE ty_cdhdr.

  TYPES : BEGIN OF ty_ekpo,            "current PO data
            ebeln TYPE ekpo-ebeln,      "doc. no
            ebelp TYPE ekpo-ebelp,      "Item Number
            matnr TYPE ekpo-matnr,      "Material No
            loekz TYPE ekpo-loekz,      "Deletion Indi.
            netpr TYPE ekpo-netpr,
          END OF ty_ekpo.
  TYPES : BEGIN OF ty_ekbe,            "current PO data
            ebeln TYPE ekbe-ebeln,      "doc. no
            ebelp TYPE ekbe-ebelp,      "Item Number
            menge TYPE ekbe-menge,      "Quantity
            vgabe TYPE ekbe-vgabe,      "Tran./event type, PO history
            bwart TYPE ekbe-bwart,      "Movement Type
            shkzg TYPE ekbe-shkzg,      "Debit/credit indicator
          END OF ty_ekbe.

  TYPES : BEGIN OF ty_mara,            "Material Master
            matnr TYPE mara-matnr,      "Material no
            mtart TYPE mara-mtart,      "Material type
          END OF ty_mara.
  DATA: ist_ekpo TYPE TABLE OF ty_ekpo,
        wa_ekpo  TYPE ty_ekpo,
        ist_ekbe TYPE TABLE OF ty_ekbe,
        wa_ekbe  TYPE ty_ekbe,
        ist_mara TYPE TABLE OF ty_mara,
        wa_mara  TYPE ty_mara,
*Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 11.06.2026

        ist_konv TYPE TABLE OF prcd_elements,
        wa_konv  TYPE prcd_elements.
*Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 11.06.2026
  DATA: l_grqty TYPE ekpo-menge,
        l_ivqty TYPE ekpo-menge.

  IF sy-tcode = 'ME31K' OR sy-tcode = 'ME32K' .
*    CLEAR : L_PRTOT, L_CNTOT.
    DESCRIBE TABLE lt_mepoitem LINES line.
*    LOOP AT LT_MEPOITEM INTO LS_MEPOITEM.
*    ENDLOOP.
    READ TABLE lt_mepoitem INTO ls_mepoitem INDEX line.

    IF ls_mepoitem-banfn <> ''.
      SELECT banfn bnfpo bsart badat preis loekz waers FROM eban
        INTO TABLE ist_eban
        FOR ALL ENTRIES IN lt_mepoitem
        WHERE banfn = lt_mepoitem-banfn AND
              loekz = ''.
      READ TABLE ist_eban INTO wa_eban WITH KEY bsart = 'SWO'.
      IF sy-subrc = 0 .
        IF wa_eban-bsart = 'SWO'.
          MESSAGE e743(zmm).
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
******************************************************************************************************************************************
  DATA: lv_bsart TYPE mepoheader-bsart,
        l_ebeln  TYPE  mepoheader-ebeln,
        l_flg(1) TYPE c.
*BREAK abapuser01.
  IF sy-tcode = 'ME21N' OR sy-tcode = 'ME22N' OR sy-tcode = 'ME23N' OR sy-tcode = 'ME29N' OR sy-tcode = 'ME28N'.

    TYPES : BEGIN OF ty_lfa1,
              lifnr	TYPE lifnr,
              land1	TYPE land1_gp,
            END OF ty_lfa1.
    DATA : lt_t024 TYPE TABLE OF t024,
           ls_t024 TYPE          t024,
           ls_lfa1 TYPE          ty_lfa1.


    SELECT SINGLE lifnr
           land1 FROM lfa1 INTO ls_lfa1
           WHERE lifnr = ls_mepoheader-lifnr.

    IF sy-subrc = 0.
      SELECT SINGLE * FROM t024 INTO ls_t024
           WHERE ekgrp = ls_mepoheader-ekgrp.

      IF ls_t024-tel_extens  <> ls_lfa1-land1.

        ls_mepoheader-kalsm = 'ZIMP'.

      ELSE.
        ls_mepoheader-kalsm = 'ZIND'.
      ENDIF.
    ENDIF.

  ENDIF.


  " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*  IF ( sy-tcode <> 'ME28' ) AND ( sy-tcode <> 'ZMMME28' )
  IF ( sy-tcode <> 'ME28' ) AND ( sy-tcode <> 'ZMMME28' ) "#EC CI_USAGE_OK[1803189]
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
                            AND ( sy-tcode <> 'ME35K' )
                            AND ( sy-tcode <> 'ZMMME35K' )
                            AND ( sy-uname+0(3) <> 'CMM' ) .
*This will apply for POs of Import type
*    CALL METHOD IM_HEADER->GET_CONDITIONS( IMPORTING EX_CONDITIONS = LT_KOMV ).

    IF ( ls_mepoheader-kalsm = 'ZIMP' ) AND ( ls_mepoheader-ekorg = 'PMAT' )
                                 AND ( ls_mepoheader-bstyp = 'F' ) .

      LOOP AT lt_mepoitem ASSIGNING <fs_mepoitem> WHERE ( loekz = ' ' ) AND ( pstyp = '0' ).
*  To bypass the check on conditions, when PR Doc. type is 'MRCS'.
        CLEAR lv_bsart.

        SELECT SINGLE bsart INTO lv_bsart FROM eban WHERE
            banfn = <fs_mepoitem>-banfn AND bnfpo = <fs_mepoitem>-bnfpo.
        IF lv_bsart = 'MRCS'.
          EXIT.
        ELSE.
          " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*
** Quick Fix Replace this statement by a SELECT statement with ORDER BY
** 05.06.2026 12:26:48 SAP_ABAP
          SELECT ebeln FROM ekbe UP TO 1 ROWS  INTO @l_ebeln WHERE
         ebeln = @<fs_mepoitem>-ebeln AND ebelp = @<fs_mepoitem>-ebelp AND ( (
         vgabe = '1' ) OR ( vgabe = '2' ) )  ORDER BY
         ebeln, ebelp, zekkn, vgabe, gjahr, belnr, buzei .   ENDSELECT.
          " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
* End of Quick Fix

          IF ( sy-subrc <> 0 ) .

*Checking for Overseas Freight
            l_flg = 0 .

            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                        ( ( kschl = 'ZFR1' ) OR ( kschl = 'ZFR2' ) OR
                          ( kschl = 'ZFR3' ) OR ( kschl = 'ZFOH' ) ) .
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
              MESSAGE e138(zmm) WITH <fs_mepoitem>-ebelp .
            ENDIF .
*Checking for Overseas Insurance
            l_flg = 0 .
            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                         ( ( kschl = 'ZIN4' ) OR ( kschl = 'ZIN5' ) ).
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
              MESSAGE e141(zmm) WITH <fs_mepoitem>-ebelp .
            ENDIF .
*Checking for Basic Customs Duty/ Countervailing Duty/ Spl Addnal Duty
            l_flg = 0 .
            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                           ( ( kschl = 'JCDB' ) OR ( kschl = 'JCV1' )
                        OR ( kschl = 'JCV2' ) OR ( kschl = 'ZSAD' ) ).
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
              MESSAGE e142(zmm) WITH <fs_mepoitem>-ebelp .
            ENDIF .
*Checking for Port Charges
            l_flg = 0 .
            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                         ( ( kschl = 'ZPRT' ) OR ( kschl = 'ZZ17' ) ).
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
              MESSAGE e144(zmm) WITH <fs_mepoitem>-ebelp .
            ENDIF .
*Checking for Inland Freight
            l_flg = 0 .
            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                        ( ( kschl = 'ZFR4' ) OR ( kschl = 'ZFR5' ) OR
                           ( kschl = 'ZFR6' ) OR ( kschl = 'ZFRH' ) ).
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
              MESSAGE e145(zmm) WITH <fs_mepoitem>-ebelp .
            ENDIF .
*Checking for Octroi
            l_flg = 0 .
*Octroi condition will be checked only for Company Code MUM/AMD/BDA/BDW
            SELECT SINGLE bukrs INTO l_bukrs
                             FROM t001k WHERE bwkey = <fs_mepoitem>-werks .
            IF ( l_bukrs = 'MUM' ) OR ( l_bukrs = 'AMD' )
            OR ( l_bukrs = 'BDA' ) OR ( l_bukrs = 'BDW' ).
              LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                        ( ( kschl = 'ZOC1' ) OR ( kschl = 'ZOC2' ) OR
                              ( kschl = 'ZOCH' ) ).
                l_flg = l_flg + 1 .
              ENDLOOP .
              IF l_flg = 0 .
                MESSAGE e146(zmm) WITH <fs_mepoitem>-ebelp .
              ENDIF .
            ENDIF.
          ENDIF.
*---------------------------------------------------------------------*
        ENDIF.
      ENDLOOP .
    ENDIF .
    " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
****Checking for mandatory conditions in Indigenous pricing procedure
*    IF ( ls_mepoheader-kalsm+0(4) = 'ZIND' ) AND ( ls_mepoheader-ekorg = 'PMAT' )
*                                      AND ( ls_mepoheader-bstyp = 'F' ).
    IF ( ls_mepoheader-kalsm+0(4) = 'ZIND' ) AND ( ls_mepoheader-ekorg =
   'PMAT' ) AND ( ls_mepoheader-bstyp = 'F' ).
      " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC

      LOOP AT lt_mepoitem ASSIGNING <fs_mepoitem> WHERE ( loekz = ' ' ) AND ( pstyp = '0' ).
*  To bypass the check on conditions, when PR Doc. type is 'MRCS'.
        CLEAR lv_bsart.
        SELECT SINGLE bsart INTO lv_bsart FROM eban WHERE
            banfn = ls_mepoitem-banfn AND bnfpo = <fs_mepoitem>-bnfpo.
        IF lv_bsart = 'MRCS'.
          EXIT.
        ELSE.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*          SELECT SINGLE ebeln INTO l_ebeln FROM ekbe WHERE
*              ebeln = <fs_mepoitem>-ebeln AND ebelp = <fs_mepoitem>-ebelp AND
*              ( ( vgabe = '1' ) OR ( vgabe = '2' ) ).

          SELECT ebeln INTO l_ebeln FROM ekbe UP TO 1 ROWS WHERE
           ebeln = <fs_mepoitem>-ebeln AND ebelp = <fs_mepoitem>-ebelp AND ( ( vgabe = '1' ) OR ( vgabe = '2' ) )
           ORDER BY PRIMARY KEY .
          ENDSELECT.
* End of Quick Fix
          " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
          " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
          IF ( sy-subrc <> 0 ) .
*Checking for Insurance
            l_flg = 0 .
*            CALL METHOD IM_HEADER->GET_CONDITIONS( IMPORTING EX_CONDITIONS = LT_KOMV ).
            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                        ( ( kschl = 'ZIN1' ) OR ( kschl = 'ZIN2' ) OR
                           ( kschl = 'ZIN3' ) OR ( kschl = 'ZINH' ) ).
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
*              Changed By Rahul Gupta on 24 May 2019 Functional Vibha
*              Description Changed error to Warning for Order type MAT BOARD PO.
*              MESSAGE e147(zmm) WITH <fs_mepoitem>-ebelp .
              IF ls_mepoheader-bsart = 'MBPM' OR ls_mepoheader-bsart = 'MMGM' OR ls_mepoheader-bsart = 'MMGS'.
                MESSAGE w147(zmm) WITH <fs_mepoitem>-ebelp .
              ELSE.
                MESSAGE e147(zmm) WITH <fs_mepoitem>-ebelp .
              ENDIF.
            ENDIF .
*Checking for Freight
            l_flg = 0 .
            LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                        ( ( kschl = 'FRA1' ) OR ( kschl = 'FRA2' ) OR
                          ( kschl = 'FRB1' ) OR ( kschl = 'FRC1' ) OR   "#EC CI_USAGE_OK[2296016]
                                  ( kschl = 'ZFRH' ) ).
              l_flg = l_flg + 1 .
            ENDLOOP .
            IF l_flg = 0 .
              IF ls_mepoheader-bsart = 'MMGM' OR ls_mepoheader-bsart = 'MMGS'.
                MESSAGE w148(zmm) WITH <fs_mepoitem>-ebelp .
              ELSE.
                MESSAGE e148(zmm) WITH <fs_mepoitem>-ebelp .
              ENDIF.

*              MESSAGE e148(zmm) WITH <fs_mepoitem>-ebelp .
            ENDIF .
*Checking for Octroi
            l_flg = 0 .
*Octroi condition will be checked for Company Codes MUM/AMD/BDA/BDW
            SELECT SINGLE bukrs INTO l_bukrs
                             FROM t001k WHERE bwkey = <fs_mepoitem>-werks .
            IF ( l_bukrs = 'MUM' ) OR ( l_bukrs = 'AMD' ) OR
               ( l_bukrs = 'BDA' ) OR ( l_bukrs = 'BDW' ).

              LOOP AT lt_komv ASSIGNING <fs_komv> WHERE ( kposn = <fs_mepoitem>-ebelp ) AND
                        ( ( kschl = 'ZOC1' ) OR ( kschl = 'ZOC2' ) OR
                              ( kschl = 'ZOCH' ) ).
                " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
                " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
              ENDLOOP .
              IF l_flg = 0 .
                MESSAGE e146(zmm) WITH <fs_mepoitem>-ebelp .
              ENDIF .
            ENDIF.
          ENDIF.
*---------------------------------------------------------------------*
        ENDIF.
      ENDLOOP.
    ENDIF.

* Validation that QAD "Non SAP" should not be used

    IF ( g_trtyp = 'H' ) OR ( ls_mepoheader-memory <> ' ' ).
      IF ls_mepoheader-zzinsp_auth = '8' .
        MESSAGE e194(zmm).
      ENDIF.
    ENDIF.

  ENDIF .


*start-Valid of Acct Assgnt Cat for JVA Plant POs & PRs CHG ID RK +001*
  IF ( sy-tcode <> 'ME28' ) AND  ( sy-tcode <> 'ZMMME28' ) AND   "#EC CI_USAGE_OK[1803189]
     ( sy-tcode <> 'ME35K' ) AND ( sy-tcode <> 'ZMMME35K' ) AND
     ( ls_mepoheader-bstyp = 'F' ).

    LOOP AT lt_mepoitem ASSIGNING <fs_mepoitem>  WHERE ( pstyp <> '7' ) AND ( loekz <> 'L' ).
      IF <fs_mepoitem>-werks+2(1) = 'J'.
        IF <fs_mepoitem>-pstyp EQ '9'.
          IF <fs_mepoitem>-knttp NE 'P'.
            MESSAGE e139(zmm).
          ENDIF.
        ELSE.
          IF <fs_mepoitem>-knttp NE 'Q'.
            MESSAGE e140(zmm).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

*Indentor PO - Batch mandatory for Cap items & Valn type shd be same

    wa_ekko   = ls_mepoheader .
    ist_tekpo = lt_mepoitem .
    ist_teket = lt_eket .

    IF ( ( wa_ekko-bsart = 'MEPI' ) OR ( wa_ekko-bsart = 'MEMI' )
      OR ( wa_ekko-bsart = 'MPOI' ) OR ( wa_ekko-bsart = 'MSUB' )
      OR ( wa_ekko-bsart = 'MBPM' ) ).
      LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE ( loekz = ' ' ).
        IF <fs_ekpo>-matnr+0(2) = '0C' .
          LOOP AT ist_teket ASSIGNING <fs_eket> WHERE ebelp = <fs_ekpo>-ebelp.
            IF <fs_eket>-charg = ' '.
              MESSAGE e159(zmm) WITH <fs_ekpo>-ebelp .
            ELSEIF ( <fs_eket>-charg <> <fs_ekpo>-bwtar ) AND
                   ( <fs_ekpo>-bwtar <> ' ' ) .
              MESSAGE e133(zmm) WITH <fs_ekpo>-ebelp.
*          ELSEIF ( ( ist_tekpo-bwtar+0(2) = 'SP' ) OR
*                   ( ist_tekpo-bwtar+0(2) = 'ST' ) ).
            ENDIF.
            IF <fs_ekpo>-charg CA '1234567890'.
            ELSE.
              MESSAGE e204(zmm) WITH <fs_ekpo>-ebelp.
            ENDIF.
          ENDLOOP.
        ELSEIF ( <fs_ekpo>-matnr+0(2) <> '0C' ) AND
               ( <fs_ekpo>-matnr <> ' ' ) AND ( <fs_ekpo>-mtart <> 'ZNBW' ) AND
             ( <fs_ekpo>-bwtar  = ' ' ) .
          MESSAGE e196(zmm) WITH <fs_ekpo>-ebelp .
        ENDIF.
      ENDLOOP.
    ENDIF.
* stores/spares POs-ensuring batch, valn type are consistent-cap items
    IF  ( wa_ekko-bsart = 'MPOM' ) OR ( wa_ekko-bsart = 'MIMM' ) .
      LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE loekz = ' ' .
        IF  <fs_ekpo>-matnr+0(2) = '0C' .
          IF <fs_ekpo>-charg = space .
            MESSAGE e198(zmm) WITH <fs_ekpo>-ebelp .
          ELSEIF <fs_ekpo>-bwtar NE <fs_ekpo>-charg AND
                 <fs_ekpo>-bwtar NE space.
            MESSAGE e133(zmm) WITH <fs_ekpo>-ebelp.
          ENDIF.
          IF <fs_ekpo>-charg CA '1234567890'.
          ELSE.
            MESSAGE e204(zmm) WITH <fs_ekpo>-ebelp.
          ENDIF.
*        ELSEIF ist_tekpo-bwtar EQ 'ST' OR
*               ist_tekpo-bwtar EQ 'SP'.
*          MESSAGE e133(zmm) WITH ist_tekpo-ebelp.
*        ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
* Capital items PO - ensuring stores/spares items have valid valn type

    IF  ( wa_ekko-bsart = 'MICM' ) OR ( wa_ekko-bsart = 'MPCM' ).
      LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE ( loekz = ' ' ).
        IF  <fs_ekpo>-matnr+0(2) <> '0C' .
          SELECT SINGLE * FROM mara INTO lv_mara WHERE matnr = <fs_ekpo>-matnr.
*        if mara-mtart = 'ZSTO'.  "nitesh 27/10/2005
          IF lv_mara-mtart = 'ZSTO' AND sy-subrc = 0.
            IF <fs_ekpo>-bwtar = 'STID-NEW' OR
               <fs_ekpo>-bwtar = 'STIM-NEW' OR
               <fs_ekpo>-bwtar = 'STID-PLNEW' OR
               <fs_ekpo>-bwtar = 'STIM-PLNEW'.
            ELSE.
              MESSAGE e199(zmm) WITH <fs_ekpo>-ebelp.
            ENDIF.
            " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
            " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
*        elseif mara-mtart = 'ZSPR'. "nitesh 27/10/2005
          ELSEIF lv_mara-mtart = 'ZSPR' AND sy-subrc = 0.
            IF <fs_ekpo>-bwtar = 'SPID-NEW' OR
               <fs_ekpo>-bwtar = 'SPIM-NEW' OR
               <fs_ekpo>-bwtar = 'SPID-PLNEW' OR
               <fs_ekpo>-bwtar = 'SPIM-PLNEW'.
            ELSE.
              MESSAGE e199(zmm) WITH <fs_ekpo>-ebelp.
            ENDIF.
          ENDIF.
* Validation of numeric batch no. for capital items  - start
        ELSE.
          IF <fs_ekpo>-charg CA '1234567890'.
          ELSE.
            MESSAGE e204(zmm) WITH <fs_ekpo>-ebelp.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
*End of indentor PO capital item validation
  ENDIF.

  CLEAR: wa_ekko, ist_tekpo, ist_teket.
  IF ( sy-tcode <> 'ME28' ) AND  ( sy-tcode <> 'ZMMME28' ) AND  "#EC CI_USAGE_OK[1803189]
   ( sy-tcode <> 'ME35K' ) AND ( sy-tcode <> 'ZMMME35K' ) .
    IF ls_mepoheader-bstyp EQ 'A'.
      SELECT SINGLE * FROM zmm_pur_tender_d INTO ls_zmm_pur_tender_d WHERE submi = ls_mepoheader-submi.
      IF sy-subrc NE 0.
        MESSAGE e003(zmmpurtdr) WITH ls_mepoheader-submi.
      ENDIF.
*----------Checking Tender Status
      IF ls_zmm_pur_tender_d-tdrsts = 'C' OR
         ls_zmm_pur_tender_d-tdrsts = 'X' OR
         ls_zmm_pur_tender_d-tdrsts = 'D' .

        CALL FUNCTION 'CUSTOMIZED_MESSAGE'
          EXPORTING
            i_arbgb = 'ZMMPURTDR'
            i_dtype = c_error
            i_msgnr = '011'
            i_var01 = ' '
            i_var02 = ' '.
      ENDIF.
*----------checking last date of tender selling
      IF NOT ls_zmm_pur_tender_d-lt_sel_dt IS INITIAL.
        IF ls_mepoheader-aedat GT ls_zmm_pur_tender_d-lt_sel_dt.
          CALL FUNCTION 'CUSTOMIZED_MESSAGE'
            EXPORTING
              i_arbgb = 'ZMMPURTDR'
              i_dtype = c_error
              i_msgnr = '004'
              i_var01 = ls_mepoheader-submi
              i_var02 = 0.
        ENDIF.
      ENDIF.
*----------checking document type
      IF ls_zmm_pur_tender_d-bsart NE ls_mepoheader-bsart.
        CALL FUNCTION 'CUSTOMIZED_MESSAGE'
          EXPORTING
            i_arbgb = 'ZMMPURTDR'
            i_dtype = c_error
            i_msgnr = '007'
            i_var01 = ls_mepoheader-bsart
            i_var02 = ls_mepoheader-submi.

      ENDIF.
*----------checking purchasing group
      IF ls_zmm_pur_tender_d-ekgrp NE ls_mepoheader-ekgrp.
        CALL FUNCTION 'CUSTOMIZED_MESSAGE'
          EXPORTING
            i_arbgb = 'ZMMPURTDR'
            i_dtype = c_error
            i_msgnr = '005'
            i_var01 = ls_mepoheader-ekgrp
            i_var02 = ls_mepoheader-submi.
      ENDIF.
*----------checking purchasing organization
      IF ls_mepoheader-bsart+0(1) = 'M'.
        IF ls_mepoheader-ekorg  NE 'PMAT' AND
           ls_mepoheader-ekorg  NE 'PDEV'.
        ENDIF.
      ENDIF.

      IF ls_mepoheader-bsart+0(1) = 'S'.
        IF ls_mepoheader-ekorg  NE 'PSRV'
           AND ls_mepoheader-ekorg  NE 'PDEV'.
          CALL FUNCTION 'CUSTOMIZED_MESSAGE'
            EXPORTING
              i_arbgb = 'ZMMPURTDR'
              i_dtype = c_error
              i_msgnr = '006'
              i_var01 = ls_mepoheader-ekorg
              i_var02 = ls_mepoheader-submi.

        ENDIF.
      ENDIF.

      IF ls_mepoheader-bsart = 'MOLM' OR ls_mepoheader-bsart = 'MOLN'
      OR ls_mepoheader-bsart = 'MOMM' OR ls_mepoheader-bsart = 'MOMN'
      OR ls_mepoheader-bsart = 'MRCO'
      OR ls_mepoheader-bsart = 'SGO'  OR ls_mepoheader-bsart = 'SOT' .

        IF ls_mepoheader-zzlst_sel_date <> ls_zmm_pur_tender_d-lt_sel_dt.
          MESSAGE e012(zmmpurtdr) WITH
           ls_zmm_pur_tender_d-lt_sel_dt .
          ls_mepoheader-zzlst_sel_date = ls_zmm_pur_tender_d-lt_sel_dt.
        ENDIF.

      ENDIF.
    ENDIF.

    IF ls_mepoheader-bsart = 'MBPM' OR ls_mepoheader-bsart = 'MEMI' OR
        ls_mepoheader-bsart = 'MEPI' OR ls_mepoheader-bsart = 'MICM' OR
        ls_mepoheader-bsart = 'MIMM' OR ls_mepoheader-bsart = 'MPCM' OR
        ls_mepoheader-bsart = 'MPOI' OR ls_mepoheader-bsart = 'MPOM'
        OR ls_mepoheader-bsart = 'MSUB' .

      IF ls_mepoheader-zzinsp_auth =  ' ' .
        MESSAGE e114(zmm) .
      ENDIF .

*       LOOP AT LT_MEPOITEM ASSIGNING <FS_EKPO>.
*        <FS_EKPO>-ZZULT_CON = LS_MEPOHEADER-ZZULT_CON.
*      ENDLOOP.

*      LOOP AT ITEM ASSIGNING <FS_ITEM>.
*        CLEAR: LS_MEPOITEM.
*        LS_MEPOITEM = <FS_ITEM>-ITEM->GET_DATA( ).
*        LS_MEPOITEM-ZZULT_CON = LS_MEPOHEADER-ZZULT_CON.
*        <FS_ITEM>-ITEM->SET_DATA( LS_MEPOITEM ).
*      ENDLOOP.
      CLEAR lt_mepoitem[].
      LOOP AT item ASSIGNING <fs_item>.
        CLEAR ls_mepoitem.
        ls_mepoitem = <fs_item>-item->get_data( ).
        IF ls_mepoitem IS NOT INITIAL.
          APPEND ls_mepoitem TO lt_mepoitem.
        ENDIF.
      ENDLOOP.


      LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> WHERE zzzult_con = space.
        MESSAGE e115(zmm).
      ENDLOOP.
*{+rk002
    ELSE.
      """""""""""""""
      "added by lipsy on 1.04.2015 for derelease""RD1K995870

      IF ls_mepoheader-frgke = 'S'.
      ELSE.
        "end of addition by lipsy on 1.04.2015 for derelease""RD1K995870
        """""""""""""""""""""""
        IF ls_mepoheader-zzbider_agr = ' ' AND
           ( ls_mepoheader-bsart = 'SEM' OR ls_mepoheader-bsart = 'SNB' OR
             ls_mepoheader-bsart = 'SPM' OR ls_mepoheader-bsart = 'SRR2' OR
             ls_mepoheader-bsart = 'STK' OR ls_mepoheader-bsart = 'SUS' ).
          MESSAGE e518(zmm).
        ENDIF.
        """"""""""""""""
        "added by lipsy on 1.04.2015 for derelease""RD1K995870

      ENDIF.

      "end of addition by lipsy on 1.04.2015 for derelease""RD1K995870
      """""""""""""""""""""""
*}+rk002
    ENDIF .

    IF ls_mepoheader-bsart = 'MLLM' OR ls_mepoheader-bsart = 'MLLN' OR
       ls_mepoheader-bsart = 'MLMM' OR ls_mepoheader-bsart = 'MLMN' OR
       ls_mepoheader-bsart = 'MOLM' OR ls_mepoheader-bsart = 'MOLN' OR
       ls_mepoheader-bsart = 'MOMM' OR ls_mepoheader-bsart = 'MOMN' OR
       ls_mepoheader-bsart = 'MSTA' OR ls_mepoheader-bsart = 'PMNS'.

      LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> WHERE zzzult_con = space.
        MESSAGE e115(zmm).
      ENDLOOP.
    ENDIF.

* Checking if the PRs being referenced are all fully released.

*Start of Addition NN 19.12.03 as per FS-MM-SRV-011
    IF ls_mepoheader-bsart NE 'MDGS'.

      CLEAR g_greater_apr .

      IF ls_mepoheader-aedat > l_apr_date .
        g_greater_apr = 'X' .
      ENDIF.

      CLEAR l_memory.

      SELECT SINGLE memory FROM ekko INTO l_memory
                           WHERE ebeln = ls_mepoheader-ebeln.

** start of change as on 01/03/2005 by harish
      IF l_memory EQ space .
        LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> WHERE loekz EQ space.
          SELECT SINGLE * FROM ekpo INTO ls_ekpo WHERE ebeln = <fs_ekpo>-ebeln AND
                                          ebelp = <fs_ekpo>-ebelp.
          IF sy-subrc NE 0.
            l_memory = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
** end of change.
      IF ( ls_mepoheader-bstyp = 'F' ). " OR ( i_bstyp = 'K' ) .
*+sp001 - Further validation on PO/PR for Condensate Purchase - Start


        IF ls_mepoheader-bsart <> 'MCON'.
          SELECT * FROM zmm_mcon INTO TABLE ist_mcon.

          SORT ist_mcon.

          LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
            READ TABLE ist_mcon ASSIGNING <fs_mcon> WITH KEY matnr = <fs_ekpo>-matnr
                                                             werks = <fs_ekpo>-werks.
            IF sy-subrc = 0.
              MESSAGE e840(zmm) WITH <fs_ekpo>-matnr.
              EXIT.
            ENDIF.
          ENDLOOP.
        ENDIF.

*--- Allow creation of PO with PR in case of Condensate Purchase.
        IF ls_mepoheader-bsart = 'MCON'.
*   DATA :
*     ist_mcon type STANDARD TABLE OF zmm_mcon WITH HEADER LINE. "-sp001

          SELECT * FROM zmm_mcon INTO TABLE ist_mcon WHERE
                                            bsart = 'MCON'.
          SORT ist_mcon.
          LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
*Start Commented by SAB_RAMESH on 17.06.2006
*for material&plant validation
            READ TABLE ist_mcon ASSIGNING <fs_mcon> WITH KEY matnr = <fs_ekpo>-matnr
                                                             werks = <fs_ekpo>-werks.
            IF sy-subrc <> 0.
              MESSAGE e840(zmm) WITH <fs_ekpo>-matnr.
              EXIT.
            ENDIF.
          ENDLOOP.
        ELSE.
*}+rk003
*+sp001 - uncommented as per FS-MM-PUR-229 - end
* BREAK-POINT.

          IF ( ls_mepoheader-bsart <> 'MSDM' ) AND
             ( ls_mepoheader-bsart <> 'MSIM' ) AND
             ( ls_mepoheader-bsart <> 'MSUB' ) AND
             ( ls_mepoheader-bsart <> 'MNBM' ) AND
             ( g_greater_apr = 'X' ) AND
             ( ls_mepoheader-ernam+0(3) <> 'CMM' ) AND
             ( ls_mepoheader-ernam+0(3) <> 'RMM' ) AND
             ( ls_mepoheader-ernam+0(2) <> 'C_' )  AND
             ( ( g_trtyp = 'H' ) OR ( l_memory <> ' ' ) ).
            CALL FUNCTION 'ZMM_PUR_CHECK_READ'
              EXPORTING
                i_bstyp          = ls_mepoheader-bstyp
                i_bsart          = ls_mepoheader-bsart
                i_bname          = ls_mepoheader-ernam
                i_idatbi         = ls_mepoheader-aedat
              EXCEPTIONS
                no_authorization = 1
                OTHERS           = 2.
            IF sy-subrc NE 1.
              l_sy_subrc = sy-subrc.
              LOOP AT  lt_mepoitem ASSIGNING <fs_ekpo>.
                IF <fs_ekpo>-banfn IS INITIAL OR <fs_ekpo>-bnfpo IS INITIAL.
                  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                  """"""""""added by lipsy on 27.02.2015 for removing message in deleted item RD1K995870
*    if <fs_ekpo>-loekz is INITIAL.
*   BREAK-POINT.
                  IF <fs_ekpo>-loekz IS NOT INITIAL.

                  ELSE.
                    """"""""""end of addition by lipsy on 27.02.2015 for removing message in deleted item RD1K995870
                    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

                    MESSAGE e025(zmmpurtdr).
                    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                    """"""""""added by lipsy on 27.02.2015 for removing message in deleted item RD1K995870
                  ENDIF.
                  """"""""""end of addition by lipsy on 27.02.2015 for removing message in deleted item RD1K995870

                  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


                ENDIF.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
*=======================================================================
*Requirement  -  FS-MM-INV-205 for funds centre PO/ PR validations
*=======================================================================
    DATA: ist_tekkn TYPE STANDARD TABLE OF mepoaccounting.
    DATA : l_fistl TYPE eban-fistl,
           l_fipos TYPE eban-fipos.
    DATA : g_amt   TYPE ekko-ktwrt ,  " Gross amount for comparison
           g_pramt TYPE ekko-ktwrt. " Sanctioned amount for the PR

    TYPES : BEGIN OF ty_amtchk  ,
              banfn      TYPE eban-banfn , "PR NO
              poitem     TYPE ekpo-ebelp ,  "line item in PO
              fistl      TYPE ekpo-fistl , "fund centre
              fipos      TYPE ekpo-fipos , "committment item
              fyear      TYPE bseg-gjahr , "fiscal year
              sanct      TYPE ekko-ktwrt , "Sanctioned amt
              olamt      TYPE ekko-ktwrt , "old PO's amount used up
              cuamt      TYPE ekko-ktwrt , " current PO - amount being used up
              zzpr_escln TYPE ekpo-zzzpr_escln,
            END OF ty_amtchk .
    DATA: ist_amtchk TYPE STANDARD TABLE OF ty_amtchk,
          wa_amtchk  TYPE ty_amtchk.
    DATA: lt_cdpos TYPE TABLE OF cdpos,
          ls_cdpos TYPE cdpos.
    DATA : l_t001k TYPE t001k.



    DATA: l_year TYPE bseg-gjahr .

    DATA: lt_eban TYPE STANDARD TABLE OF eban,
          lv_eban TYPE eban,
          lt_ebkn TYPE STANDARD TABLE OF ebkn,
          wa_ebkn TYPE ebkn.
    FIELD-SYMBOLS: <fs_eban> TYPE eban,
                   <fs_ebkn> TYPE ebkn.

    DATA: lt_ekpo TYPE STANDARD TABLE OF ekpo,
          "WA_EKPO TYPE EKPO,
*          LT_EKKN TYPE STANDARD TABLE OF EKKN,
          wa_ekkn TYPE ekkn,
          "W_EKKO TYPE EKKO,
          w_eket  TYPE eket.
    FIELD-SYMBOLS: "<FS_EKKN> TYPE EKKN,
                  <f_ekpo> TYPE ekpo.
    DATA : gv_bsart TYPE eban-bsart.
    DATA: ls_ebkn TYPE ebkn.
    DATA: "L_EKPO TYPE TABLE OF EKPO,
      l_ekkn TYPE TABLE OF ekkn,
      l_ekko TYPE ekko,
      l_eket TYPE eket.
    FIELD-SYMBOLS: "<F_EKPO> TYPE EKPO,
                   <f_ekkn> TYPE ekkn.
    DATA: l_oldpoyear TYPE bseg-gjahr.
    DATA: lv_knttp TYPE eban-knttp.
*    DATA : WA_AMTCHK TYPE TY_AMTCHK .
    DATA : l_sumamt      TYPE ekko-ktwrt,
           ls_setleaf    TYPE setleaf,
           ls_zmm_ekgrp  TYPE zmm_ekgrp,
           lt_zmm_epclog TYPE TABLE OF zmm_epclog,
           ls_zmm_epclog TYPE zmm_epclog.
    DATA : l_sanct_c(12).                                   "RK +001
    DATA : l_sumamt_c(12).                                  "RK +001
    DATA : l_round_val TYPE f VALUE '.1'.                   "RK +001

    DATA: wa_cdpos TYPE cdpos.

    DATA l_flg1(1) TYPE c.

    DATA : l_chk(1),
           l_ans(1).                                        "+SPP001

*EPC change history
    DATA : l_epc   TYPE zmm_epclog-epc_old,
           l_versn TYPE zmm_epclog-versn.

    DATA : l_tstamp TYPE timestamp,
           l_d      TYPE d,
           l_t      TYPE t.
    DATA : pstyp TYPE bekpo-pstyp.
    DATA: wa_ebeln TYPE ekko-ebeln.
    DATA: l_lifnr  TYPE ekko-lifnr.
    DATA: l_kunnr  TYPE ekpo-kunnr.
    DATA: l_bednr  TYPE ekpo-bednr.
    DATA: l_flag(1) TYPE c.

    TYPES: BEGIN OF ty_ebeln,
             ebeln TYPE ekko-ebeln,
           END OF ty_ebeln.
    TYPES: BEGIN OF ty_ebeln1,
             ebeln TYPE ekko-ebeln,
             loekz TYPE ekko-loekz,
           END OF ty_ebeln1.
    DATA: itab_ebeln TYPE TABLE OF ty_ebeln.
    DATA: lt_ebeln TYPE TABLE OF ty_ebeln1.

    DATA: s_mm(2) TYPE c,
          s_yy(4) TYPE c,
          e_mm(2) TYPE c,
          e_yy(4) TYPE c,
          l_from  TYPE s034-spmon,
          l_upto  TYPE s034-spmon.
    DATA: l_cmgvbr     TYPE s034-cmgvbr,
          l_cmbwbest   TYPE s035-cmbwbest,
          l_avg_consum TYPE s035-cmbwbest,
          l_sto_consum TYPE zmm_sto_consum.

    TYPES: BEGIN OF typ_ekbe,
             ebeln TYPE ekbe-ebeln,
             matnr TYPE ekbe-matnr,
             menge TYPE ekbe-menge,
             bewtp TYPE ekbe-bewtp,
             budat TYPE ekbe-budat,
             shkzg TYPE ekbe-shkzg,
           END OF typ_ekbe.
    DATA: itab_ekbe  TYPE TABLE OF typ_ekbe.
    DATA: itab_ekbe_2  TYPE TABLE OF typ_ekbe.
    DATA: itab_ekbe_gr TYPE TABLE OF typ_ekbe.
    DATA: itab_ekbe_gi TYPE TABLE OF typ_ekbe.
    DATA: l_menge_gr   TYPE ekbe-menge.
    DATA: l_menge_gi   TYPE ekbe-menge.
    DATA: w_ekbe    TYPE  typ_ekbe.
    TYPES: BEGIN OF mat,
             matnr TYPE ekbe-matnr,
             menge TYPE ekbe-menge,
           END OF mat.
    DATA: wa_matab  TYPE mat.
    DATA: matrl TYPE mat,
          matab TYPE HASHED TABLE OF mat
                                    WITH UNIQUE KEY matnr.

    DATA: itab_sto TYPE TABLE OF ekpo-ebeln.
    DATA: l_days TYPE i.
    DATA: l_lines TYPE i.
    CLEAR: l_lines, wa_ekbe.
    DATA: lv_netpr   TYPE ekpo-netpr VALUE 1,
          lv_bdcflag TYPE sy-datum.
    DATA : lv_tabix TYPE sy-tabix.

    TYPES: BEGIN OF ty_eban_mrcs,
             banfn     TYPE eban-banfn,       "PR No.
             bnfpo     TYPE eban-bnfpo,       "PR Item
             matnr     TYPE eban-matnr,       "Material Number
             bsart     TYPE eban-bsart,       "Document type
             bednr     TYPE eban-bednr,       "Tracking Number
             repos     TYPE eban-repos,       "Invoice Reciept Indicator
             zzsrmmark TYPE eban-zzsrmmark,   "SRM PR Indicator
           END OF ty_eban_mrcs.

    DATA: wa_eban_mrcs TYPE ty_eban_mrcs,
          it_eban_mrcs TYPE TABLE OF ty_eban_mrcs.

    TYPES: BEGIN OF ty_ekpo_mrcs,
             ebeln         TYPE ekko-ebeln,          "PO Number
             ebelp         TYPE ekpo-ebelp,          "PO Item number
             matnr         TYPE ekpo-matnr,          "Material Number
             menge         TYPE ekpo-menge,          "Quantity
             netpr         TYPE ekpo-netpr,          "Net Price
             zzexchng_rate TYPE ekko-zzexchng_rate,   "SRM Exchange Rate
             zzsrmmark     TYPE ekpo-zzzsrmmark,      "SRM PO Indicator
             banfn         TYPE eban-banfn,       "PR No.
             bnfpo         TYPE eban-bnfpo,       "PR Item
           END OF ty_ekpo_mrcs.

    DATA: wa_ekpo_mrcs TYPE ty_ekpo_mrcs,
          it_ekpo_mrcs TYPE TABLE OF ty_ekpo_mrcs.
    DATA : l_werks TYPE ekpo-werks.
    DATA : l_ebelp TYPE ekpo-ebelp.
    DATA: l_val_date LIKE sy-datum.
    DATA: w_mara TYPE mara,
          w_lfa1 TYPE lfa1.

    """"""""""""""""""""""""""""""""""
    "ADDED BY LIPSY 21.1.2016
    DATA: wa_eban_rerror TYPE eban,
          lv_base_price  TYPE zcat_price.
    DATA: lv_discount TYPE zcat_price.
    DATA: lv_escalat TYPE zcat_price.
    DATA: lv_custom TYPE zcat_price.
    "EADD BY LIPSY 21.1.2016
    """"""""""""""""""""""""""""""""""""








    wa_ekko =  ls_mepoheader .
    ist_tekpo = lt_mepoitem .
    ist_tekkn = lt_accounting .
    ist_teket = lt_eket .







*    MOVE-CORRESPONDING IST_TEKKN[] TO T_EKKN[].

    DATA: wamepoaccounting TYPE mepoaccounting.

    LOOP AT ist_tekkn INTO wamepoaccounting.
      MOVE-CORRESPONDING wamepoaccounting TO wa_ekkn.
      APPEND wa_ekkn TO t_ekkn.
      CLEAR: wamepoaccounting, wa_ekkn.
    ENDLOOP.


*    LOOP AT ITEM ASSIGNING <FS_ITEM>.
*      CLEAR LS_MEPOITEM.
*      LS_MEPOITEM = <FS_ITEM>-ITEM->GET_DATA( ).
*      READ TABLE T_EKKN INTO WA_EKKN WITH KEY EBELN = LS_MEPOITEM-EBELN EBELP = LS_MEPOITEM-EBELP.
*      IF LS_MEPOITEM-NETPR > WA_EKKN-NETWR.
*        LS_MEPOITEM-NETPR = WA_EKKN-NETWR.
*        <FS_ITEM>-ITEM->SET_DATA( LS_MEPOITEM ).
*      ENDIF.
*    ENDLOOP.



    CLEAR : l_fistl , l_fipos, g_amt , g_pramt.

    CLEAR: ist_amtchk[], wa_amtchk.
*Validation for the Vendor Material field in RFQs, POs & Contracts
*Also if the PR being referred is not released, error message issued
*    TABLES : CDPOS.
    DATA : l_bsart TYPE eban-bsart.
    """""""""""""""""""""""""""""""""""
*    added by lipsy on 14.03.2013 for release RD1K984170
    DATA : l_frgkz     TYPE eban-frgkz,
           wa_ekko_rel TYPE ekko.
    "end of add by lipsy on 14.03.2013 RD1K984170
    """""""""""""""""""""""""""""""""""

    IF ( ls_mepoheader-bstyp = 'F' ) OR ( ls_mepoheader-bstyp = 'K' ) OR ( ls_mepoheader-bstyp = 'A' ) .
      IF ( g_greater_apr = 'X' ) .
        " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*        LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE ( loekz = ' ' ).
        LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE ( loekz = ' ' ).
          " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
          IF ( <fs_ekpo>-idnlf <> ' ' ) AND
             ( <fs_ekpo>-idnlf <> 'PEL/ML' ) .
            MESSAGE e137(zmm) WITH <fs_ekpo>-ebelp .
          ENDIF.

          IF NOT <fs_ekpo>-banfn IS INITIAL .

            " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*            """""""""
*            "commented by lipsy on 14.03.2013 for release of pr RD1K984170
            SELECT * FROM ekko   UP TO 1 ROWS INTO wa_ekko_rel WHERE ebeln =
           <fs_ekpo>-ebeln AND loekz = ' '   ORDER BY  ebeln .   ENDSELECT.
            " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
            IF wa_ekko_rel-frgke = 'S'.
            ELSE.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*              SELECT SINGLE frgkz INTO l_frgkz
*                FROM eban
*                WHERE banfn = <fs_ekpo>-banfn.

              SELECT frgkz INTO l_frgkz
               FROM eban UP TO 1 ROWS WHERE banfn = <fs_ekpo>-banfn
               ORDER BY PRIMARY KEY .
              ENDSELECT.
* End of Quick Fix

              IF l_frgkz <> 'B' ."or l_frgkz <> '2'.
                "end of add by lipsy on 14.03.2013 for release of pr RD1K984170
                """""""""""""""""""""""""""""

                """""""""""""""""""""""""""""""

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*                SELECT SINGLE bsart INTO l_bsart FROM eban
*                WHERE banfn = <fs_ekpo>-banfn.

                SELECT bsart INTO l_bsart FROM eban UP TO 1 ROWS
                 WHERE banfn = <fs_ekpo>-banfn
                 ORDER BY PRIMARY KEY .
                ENDSELECT.
* End of Quick Fix

                IF l_bsart <> 'MRNT'.
                  MESSAGE e192(zmm) WITH <fs_ekpo>-banfn .
                ENDIF.
                """"""""""""""""""""""""""""""""""""

              ENDIF.
              """"""""""""""""""""""""""""""""""""""""""""""
              """"""""added by lipsy on 14.03.2013 for release of pr RD1K984170
            ENDIF.
            """"""""""""END OF add by lipsy on 14.03.2013 for release of pr RD1K984170
            """""""""""""""""""""""""""""

            """""""""""""""""""""""""""""""""""
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

* FS-MM-PLI-011 Ver1.1 - Kalpesh.
    IF ls_mepoheader-bstyp = 'F' OR ls_mepoheader-bstyp = 'K'.
*
***While entering a material line item, Account Assignment should not be
*  blank, for Company Codes OVL as per FS-MM-PLI-011 Nitin .


      LOOP AT ist_tekpo ASSIGNING <fs_ekpo>.
        IF NOT <fs_ekpo>-werks IS INITIAL.
          CALL FUNCTION 'T001K_SINGLE_READ'
            EXPORTING
              bwkey      = <fs_ekpo>-werks
            IMPORTING
              wt001k     = l_t001k
            EXCEPTIONS
              not_found  = 1
              wrong_call = 2
              OTHERS     = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

          IF l_t001k-bukrs EQ 'OVL'.
            IF <fs_ekpo>-knttp IS INITIAL AND <fs_ekpo>-werks = '90R1' .
              MESSAGE e186(zmm) WITH <fs_ekpo>-ebelp.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDLOOP.

    ENDIF.

***Check for ensuring Valuation Type is entered correctly while creating
***an STO for Capital Items.

*    REFRESH R_WERKS_WSHP.
    CLEAR   r_werks_wshp.
*    REFRESH IST_WERKS.
    CLEAR   ist_werks.

    SELECT valfrom valto  FROM  setleaf CLIENT SPECIFIED
     INTO TABLE ist_werks
     WHERE  mandt    = sy-mandt
     AND    setclass = c_000
     AND    setname  = 'ZMM_WORKSHOP_PLANTCODES' .

    LOOP AT ist_werks INTO wa_werks .
      wa_werks_wshp-low = wa_werks-valfrom.
      wa_werks_wshp-high = wa_werks-valto.
      wa_werks_wshp-sign = 'I'.
      wa_werks_wshp-option = 'BT'.
      APPEND wa_werks_wshp TO r_werks_wshp.
      CLEAR wa_werks_wshp.
    ENDLOOP.

    IF ( ls_mepoheader-bstyp = 'F' ) AND ( ( wa_ekko-bsart = 'MSDM' )
                            OR ( wa_ekko-bsart = 'MSIM' ) )
                         AND NOT ( wa_ekko-reswk IN r_werks_wshp )
                         AND ( g_greater_apr = 'X' ) .

      LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE ( loekz = ' ' ).
        IF <fs_ekpo>-matnr+0(2) = '0C'.
          SELECT SINGLE * FROM mchb INTO ls_mchb WHERE ( matnr = <fs_ekpo>-matnr )
                                        AND ( werks = wa_ekko-reswk )
                                      AND ( charg = <fs_ekpo>-bwtar )
                                    AND ( clabs >= <fs_ekpo>-menge ) .
          IF ( sy-subrc <> 0 ).
            MESSAGE e134(zmm) WITH <fs_ekpo>-ebelp wa_ekko-reswk .
          ENDIF.
          LOOP AT ist_teket ASSIGNING <fs_eket> WHERE ebelp = <fs_ekpo>-ebelp .
            IF ( <fs_eket>-charg <> <fs_ekpo>-bwtar )
            AND ( <fs_eket>-charg <> ' ' ) .
              MESSAGE e133(zmm) WITH <fs_ekpo>-ebelp .
            ENDIF .
          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ENDIF .
***End of code for checking that Valuation Type & Batch are the same in
***STOs for Capital Items






    CHECK ls_mepoheader-bstyp EQ 'F'.              "check only for Purchase Order


    LOOP AT ist_tekpo ASSIGNING <fs_ekpo> WHERE ( loekz = ' ' ) AND ( banfn <> ' ' )
                                            AND ( bnfpo <> ' ' )
                                            AND ( pstyp <> '7' ).
      IF NOT <fs_ekpo>-werks IS INITIAL.
        CALL FUNCTION 'T001K_SINGLE_READ'
          EXPORTING
            bwkey      = <fs_ekpo>-werks
          IMPORTING
            wt001k     = l_t001k
          EXCEPTIONS
            not_found  = 1
            wrong_call = 2
            OTHERS     = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.
*For standard, consignment and subcontracting POs without acct
*assignment, the first subroutine will be executed.
      IF ( <fs_ekpo>-pstyp = '0' OR         "Standard
*         ist_tekpo-pstyp = '2' OR         "Consignment
           <fs_ekpo>-pstyp = '3' ) AND      "Subcontracting
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*           ( <fs_ekpo>-knttp = ' ' ) .
( <fs_ekpo>-knttp = ' ' ).
        " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
        CLEAR : l_fistl, l_fipos, l_lfdat, g_pramt, g_amt, g_badat.



        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "commented by lipsy on 30.07.2014 for currency conversion RD1K994119
        "for same currency in po pr
*        SELECT SINGLE fistl fipos lfdat badat INTO ls_eban
*                         FROM eban WHERE banfn = <fs_ekpo>-banfn AND
*                                         bnfpo = <fs_ekpo>-bnfpo AND
*                                         loekz = ' ' .
        "end of comment by lipsy on 30.07.2014 for currency conversion RD1K994119
        "for same currency in po pr
        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        """""""""""""""""""""""""""""""""""""""""""""""""""""
        "added by lipsy on 30.07.2014 for currency conversion RD1K994119
        "for same currency in po pr

        SELECT SINGLE fistl fipos lfdat badat waers INTO ls_eban
                             FROM eban WHERE banfn = <fs_ekpo>-banfn AND
                                             bnfpo = <fs_ekpo>-bnfpo AND
                                             loekz = ' ' .


        "end of addition by lipsy on 30.07.2014 for currency conversion RD1K994119
        " for same currency in po pr

        """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


        l_fistl = ls_eban-l_fistl.
        l_fipos = ls_eban-l_fipos.
        l_lfdat = ls_eban-l_lfdat.
        g_badat = ls_eban-g_badat.

        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        "added by lipsy on 30.07.2014 for currency conversion
        """""""""""""""""for same currency in po pr RD1K994119

        l_waers = ls_eban-l_waers.
        "end of addition by lipsy on 30.07.2014 for currency conversion
        """""""""""""""""for same currency in po pr RD1K994119

        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""




* Quick Fix Append ORDER BY PRIMARY KEY to the SELECT statement
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*        SELECT * FROM cdpos INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
*         WHERE objectid EQ <fs_ekpo>-banfn AND
*               objectclas EQ 'BANF' AND
*               tabname EQ 'EBAN' AND
*               fname EQ 'FRGZU' AND
*               value_old = ' '.
        SELECT * FROM cdpos INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
         WHERE objectid EQ <fs_ekpo>-banfn AND
               objectclas EQ 'BANF' AND
               tabname EQ 'EBAN' AND
               fname EQ 'FRGZU' AND
               value_old = ' ' ORDER BY PRIMARY KEY.
* End of Quick Fix

        IF sy-subrc = 0 .
          SELECT * FROM cdhdr
                 INTO CORRESPONDING FIELDS OF TABLE ist_cdhdr
                 FOR ALL ENTRIES IN ist_cdpos
                 WHERE changenr EQ ist_cdpos-changenr AND
                       objectclas = 'BANF' AND
                       objectid EQ <fs_ekpo>-banfn.

          SORT ist_cdhdr BY udate utime ASCENDING .
          READ TABLE ist_cdhdr INTO wa_cdhdr INDEX 1 .
          IF sy-subrc EQ 0.
            g_badat = wa_cdhdr-udate .
          ENDIF.
        ENDIF.


        IF NOT ( ( <fs_ekpo>-fistl = l_fistl ) AND
                   ( <fs_ekpo>-fipos = l_fipos ) ).
          MESSAGE e335(zmm) WITH <fs_ekpo>-fistl <fs_ekpo>-fipos
                                 <fs_ekpo>-banfn <fs_ekpo>-bnfpo .
        ENDIF.

        CALL FUNCTION 'GET_CURRENT_YEAR'
          EXPORTING
            bukrs = ls_mepoheader-bukrs
            date  = l_lfdat
          IMPORTING
            curry = l_pryear.

* Loop thru delry schedule & ensure all delvries are in sanctioned year

        LOOP AT lt_eket ASSIGNING <fs_eket> WHERE ebelp = <fs_ekpo>-ebelp AND loekz = ' ' .

* Error if multiple PRs referred in PO line item thru delivery schedule
          .
          IF ( <fs_eket>-banfn <> <fs_ekpo>-banfn ) OR
                 ( <fs_eket>-bnfpo <> <fs_ekpo>-bnfpo ).
            MESSAGE e318(zmm) WITH <fs_ekpo>-ebelp .
          ENDIF .

          CONCATENATE ls_mepoitem-eeind+6(4) ls_mepoitem-eeind+3(2) ls_mepoitem-eeind(2) INTO l_lfdatscr.
          CALL FUNCTION 'GET_CURRENT_YEAR'
            EXPORTING
              bukrs = ls_mepoheader-bukrs
              date  = <fs_ekpo>-eindt        "L_LFDATSCR "L_LFDAT 120310
            IMPORTING
              curry = l_poyear.
* If fiscal years don't match, raise error
          IF ( l_poyear <> l_pryear ) AND ( g_greater_apr = 'X' ).
            """"""""""""""""""""""""""""""""""""""""""""
            """""""""added by lipsy on 27.02.2015  for removing error if released RD1K995870
*       if ls_mepoheader-frgke = 'S'.
            IF l_frgke  = 'S'.
            ELSE.

              """""""""end of addition by lipsy on 27.02.2015  for removing error if released RD1K995870
              """"""""""""""""""""""""""""""""""""""""""""""""""

              MESSAGE e336(zmm) WITH l_poyear l_pryear <fs_eket>-ebelp.

              """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
              """""""""added by lipsy on 27.02.2015  for removing error if released RD1K995870

            ENDIF.
            """""""""end of addition by lipsy on 27.02.2015  for removing error if released RD1K995870
            """""""""""""""""""""""""""""""""""""""""""""""""""""

          ENDIF .
        ENDLOOP.

        """""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        """""""""added by lipsy on 30.07.2014 for currency conversion
        """""""""""""""""for same currency in po pr RD1K994119

        IF <fs_ekpo>-waers <> l_waers.
          """""""""""end of addition by lipsy on 30.07.2014 for currency conversion
          """""""""""""""""for same currency in po pr RD1K994119

          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

          IF ls_mepoheader-waers <> 'INR' .
            CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
              EXPORTING
                client           = sy-mandt
                date             = g_badat
                foreign_amount   = <fs_ekpo>-kzwi6
                foreign_currency = ls_mepoheader-waers
                local_currency   = 'INR'
                type_of_rate     = 'M'
                read_tcurr       = 'X'
              IMPORTING
                local_amount     = <fs_ekpo>-kzwi6
              EXCEPTIONS
                no_rate_found    = 1
                overflow         = 2
                no_factors_found = 3
                no_spread_found  = 4
                derived_2_times  = 5
                OTHERS           = 6.
            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDIF.

          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          """""""""added by lipsy on 30.07.2014 for currency conversion
          """""""""""""""""for same currency in po pr RD1K994119

        ENDIF.
        """""""""""end of addition by lipsy on 30.07.2014 for currency conversion
        """""""""""""""""for same currency in po pr RD1K994119

        """""""""""""""""""""""""""""""""""""""""""""""""""""""



*If PO created after 01.04.04, ist_amtchk records sanctn fiscal yr wise
        IF ( g_greater_apr = 'X' ) .
          READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
                                         fistl = <fs_ekpo>-fistl
                                         fipos = <fs_ekpo>-fipos
                                         fyear = l_pryear.
        ELSE .
* If PO created before 01.04.04, ist_amtchk doesn't record funds yr wise
          READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
                                         fistl = <fs_ekpo>-fistl
                                         fipos = <fs_ekpo>-fipos .
        ENDIF.


        IF sy-subrc = 0.
          l_tabix = sy-tabix .
* If entry alrdy exists in ist_amtchk only funds consumed is to be added
          wa_amtchk-cuamt = wa_amtchk-cuamt + <fs_ekpo>-kzwi6.
*          Added by Yogesh
* Commented ny Sudhir Sharma CR No. <30003015> on 211009
*          WA_AMTCHK-SANCT = WA_AMTCHK-SANCT + <FS_EKPO>-KZWI6.
* End of Comment
*         end of addition yOGESH
*          MODIFY IST_AMTCHK FROM WA_AMTCHK INDEX L_TABIX TRANSPORTING CUAMT .
          MODIFY ist_amtchk FROM wa_amtchk INDEX l_tabix TRANSPORTING cuamt sanct . "added by yogesh
        ELSE.
          IF ( g_greater_apr <> 'X' ) .
* If PO created before 01.04.04, below subroutine will be used
*            PERFORM CHECK_FC_CI_IN_PR USING L_PRNO
*                                            IST_TEKPO-FISTL
*                                            IST_TEKPO-FIPOS .
* Find all line items in the PR being referenced for which FC & CI is
* the same as in runtime PO. Cumulate the amount sanctioned.

            SELECT  * FROM eban INTO TABLE l_eban WHERE banfn = <fs_ekpo>-banfn AND fistl = <fs_ekpo>-fistl AND
                                      fipos = <fs_ekpo>-fipos AND loekz = ' ' .
            LOOP AT l_eban INTO w_eban.
* If amt sanctioned in INR, add to the Total amt sanctioned in PR
              IF w_eban-waers  = 'INR' .
                g_pramt = g_pramt +  ( w_eban-preis * w_eban-menge ) .
              ELSE .
* If amt sancioned is in difft crrncy, convert to INR & then add
                """"""""""""""""""""""""""""""""""""""""""""""""


                """""""""""""""""""""""""""""""""""""""""""""""""""


                CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                  EXPORTING
                    client           = sy-mandt
                    date             = g_badat
                    foreign_amount   = w_eban-preis
                    foreign_currency = w_eban-waers
                    local_currency   = 'INR'
                    type_of_rate     = 'M'
                    read_tcurr       = 'X'
                  IMPORTING
                    local_amount     = w_eban-preis
                  EXCEPTIONS
                    no_rate_found    = 1
                    overflow         = 2
                    no_factors_found = 3
                    no_spread_found  = 4
                    derived_2_times  = 5
                    OTHERS           = 6.
                IF sy-subrc <> 0.
                  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                ENDIF.

                """""""""""""""""""""""""""""""""""""""""""""


                """"""""""""""""""""""""""""""""""""""""""""""""""
                g_pramt = g_pramt +  ( w_eban-preis * w_eban-menge ) .
              ENDIF .
            ENDLOOP.
*After finding the funds sactioned in PR, find old POs utlizing the fund
*              PERFORM OLD_PO_FOR_PR USING L_PRNO
*                                          L_FCTR
*                                          L_CI
*                                 CHANGING G_AMT .

* Find all old PO items utilizing the funds sanctioned in the PR
            SELECT * FROM ekpo INTO TABLE l_ekpo WHERE banfn = <fs_ekpo>-banfn AND fistl = <fs_ekpo>-fistl AND
                                     fipos = <fs_ekpo>-fipos AND loekz = ' ' AND
                                     ( ebeln <> <fs_ekpo>-ebeln ).
* Find the year in which funds are being utilized in the old POs
            IF sy-subrc = 0 .
* Get the currency & convert utilized amt if it is not in INR .
              LOOP AT l_ekpo INTO w_ekpo.
                SELECT SINGLE * FROM ekko INTO w_ekko WHERE ebeln = w_ekpo-ebeln AND loekz = ' ' .
                IF sy-subrc = 0 .
                  IF w_ekko-waers = 'INR' .
                    g_amt = g_amt + w_ekpo-kzwi6 .
                  ELSE .
                    CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                      EXPORTING
                        client           = sy-mandt
                        date             = g_badat
                        foreign_amount   = w_ekpo-kzwi6
                        foreign_currency = w_ekko-waers
                        local_currency   = 'INR'
                        type_of_rate     = 'M'
                        read_tcurr       = 'X'
                      IMPORTING
                        local_amount     = w_ekpo-kzwi6
                      EXCEPTIONS
                        no_rate_found    = 1
                        overflow         = 2
                        no_factors_found = 3
                        no_spread_found  = 4
                        derived_2_times  = 5
                        OTHERS           = 6.
                    IF sy-subrc <> 0.
                      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                    ENDIF.
                    g_amt = g_amt + w_ekpo-kzwi6 .
                  ENDIF .
                ENDIF .
              ENDLOOP.
            ENDIF.

          ELSE .
* If PO created after 01.04.04, below subroutine will be used
*            PERFORM CHECK_FC_CI_IN_PR1 USING L_PRNO
*                                        IST_TEKPO-FISTL
*                                        IST_TEKPO-FIPOS
*                                        L_PRYEAR.
*            CALL METHOD CHECK_FC_CI_IN_PR(
*              EXPORTING  LS_EKKO = LS_MEPOHEADER
*                         LS_EKPO = <FS_EKPO>
*                         G_GREATER_APR = G_GREATER_APR
*                         L_PRYEAR = L_PRYEAR
*                         G_BADAT = G_BADAT
*              IMPORTING  LT_EKKN = T_EKKN
*              CHANGING  G_PRAMT = G_PRAMT ).

* Find all line items in the PR being referenced for which FC & CI is
* the same as in runtime PO. Cumulate the amount sanctioned.
            SELECT  * FROM eban INTO TABLE lt_eban WHERE banfn = <fs_ekpo>-banfn AND fistl = <fs_ekpo>-fistl AND
                                      fipos = <fs_ekpo>-fipos AND loekz = ' ' .


            LOOP AT lt_eban ASSIGNING <fs_eban>.

              CALL FUNCTION 'GET_CURRENT_YEAR'
                EXPORTING
                  bukrs = ls_mepoheader-bukrs
                  date  = <fs_eban>-lfdat
                  " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                IMPORTING
*                 curry = l_year.
                IMPORTING
                  curry = l_year.
              " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC


*Amount sanctioned shd be cumulated if it is in the same fiscal year.
              IF l_pryear = l_year .
                IF <fs_eban>-waers  = 'INR' .
                  g_pramt = g_pramt +  ( <fs_eban>-preis * <fs_eban>-menge ) .
                ELSE .
* If amt sancioned is in difft crrncy, convert to INR & then add
                  """""""""""""""""""""""""""""""""""""""""""""""
                  """"""""""added by lipsy on 30.07.2014 for currency  conversion
                  """""""""""""""""for same currency in po pr RD1K994119

                  IF <fs_ekpo>-waers <> <fs_eban>-waers.
                    """""""""end of addition by lipsy on 30.07.2014 for currency  conversion
                    """""""""""""""""for same currency in po pr RD1K994119


                    """"""""""""""""""""""""""""""""""""""
                    CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                      EXPORTING
                        client           = sy-mandt
                        date             = g_badat
                        foreign_amount   = <fs_eban>-preis
                        foreign_currency = <fs_eban>-waers
                        local_currency   = 'INR'
                        type_of_rate     = 'M'
                        read_tcurr       = 'X'
                      IMPORTING
                        local_amount     = <fs_eban>-preis
                      EXCEPTIONS
                        no_rate_found    = 1
                        overflow         = 2
                        no_factors_found = 3
                        no_spread_found  = 4
                        derived_2_times  = 5
                        OTHERS           = 6.
                    IF sy-subrc <> 0.
                      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                    ENDIF.
                    """""""""""""""""""""""""""""""""""""""""""""""""""
                    """"""""""added by lipsy on 30.07.2014 for currency  conversion
                    """""""for same currency in po pr RD1K994119

                  ENDIF.

                  """""""""end of addition by lipsy on 30.07.2014 for currency  conversion
                  """""for same currency in po pr RD1K994119

                  """"""""""""""""""""""""""""""""""""""""

                  g_pramt = g_pramt +  ( <fs_eban>-preis * <fs_eban>-menge ) .
                ENDIF .
              ENDIF .
            ENDLOOP.
*
**Begin of addition 28.12.2005 to correct bug as recommended by
**consultant Akhil
            CLEAR lv_eban.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*            SELECT SINGLE * FROM eban INTO lv_eban WHERE banfn = <fs_ekpo>-banfn AND knttp <> ' '
*                                     AND loekz = ' '.

            SELECT * FROM eban INTO lv_eban UP TO 1 ROWS WHERE banfn = <fs_ekpo>-banfn AND knttp <> ' '
             AND loekz = ' '
             ORDER BY PRIMARY KEY .
            ENDSELECT.
* End of Quick Fix

            IF sy-subrc = 0 .
*    PERFORM CHECK_FC_CI_IN_SRV1 USING L_PRNO L_FCTR
*                                      L_CI L_POYEAR .

* All PR service lines

* Select all PR items where funds have been sanctioned under the FC/CI
              SELECT  * FROM ebkn INTO TABLE lt_ebkn WHERE banfn = <fs_ekpo>-banfn AND fistl = <fs_ekpo>-fistl AND
                                        fipos = <fs_ekpo>-fipos AND loekz = ' ' .
              IF sy-subrc = 0 .
* Find corresponding details (like delry date, currency) at EBAN level
                LOOP AT lt_ebkn ASSIGNING <fs_ebkn>.
                  SELECT SINGLE * FROM eban INTO lv_eban WHERE banfn = <fs_ekpo>-banfn AND
                                                  bnfpo = <fs_ebkn>-bnfpo AND
                                                  pstyp = '9'   AND
                                                  loekz = ' ' .
                  CLEAR l_year .
*Total funds sanctioned calculated & cumulated only for PO fiscal year
                  IF sy-subrc = 0 .
*          PERFORM PO_DELY_DATE_FISCL_YR USING WA_EKKO-BUKRS
*                                              EBAN-LFDAT
*                                     CHANGING L_PRYEAR .

                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = ls_mepoheader-bukrs
                        date  = lv_eban-lfdat
                      IMPORTING
                        curry = l_year.


*Cumulate the sanctioned amount only if sanctioned in PO year
                    IF ( l_pryear = l_year ) AND lv_eban-loekz = ' ' .
                      IF ( lv_eban-waers  = 'INR' ) AND lv_eban-loekz = ' ' .
                        " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                        g_pramt = g_pramt +  <fs_ebkn>-netwr .
                        g_pramt = g_pramt + <fs_ebkn>-netwr.
                        " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
                      ELSE .
* If amt sanctioned is not in INR, convert into INR before adding
*              PERFORM CONVERT_TO_LOCAL_CURRENCY USING EBAN-WAERS
*                                                      G_BADAT
*                                                      EBKN-NETWR
*                                                CHANGING EBKN-NETWR .

                        CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                          EXPORTING
                            client           = sy-mandt
                            date             = g_badat
                            foreign_amount   = <fs_ebkn>-netwr
                            foreign_currency = <fs_eban>-waers
                            local_currency   = 'INR'
                            type_of_rate     = 'M'
                            read_tcurr       = 'X'
                          IMPORTING
                            local_amount     = <fs_ebkn>-netwr
                          EXCEPTIONS
                            no_rate_found    = 1
                            overflow         = 2
                            no_factors_found = 3
                            no_spread_found  = 4
                            derived_2_times  = 5
                            OTHERS           = 6.
                        IF sy-subrc <> 0.
                          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                        ENDIF.

                        g_pramt = g_pramt +  <fs_ebkn>-netwr .
                      ENDIF .
                    ENDIF .
                  ENDIF .
                ENDLOOP.
              ENDIF.

*Now to get the amt utilized in old POs for the PR
*    PERFORM OLD_PO_FOR_PR_SRV1 USING L_SRVPR
*                                L_SRVFISTL
*                                L_SRVFIPOS
*                                L_POYEAR
*                          CHANGING G_AMT .
              CLEAR: l_year.

              SELECT  * FROM ekpo INTO TABLE lt_ekpo WHERE ( banfn = <fs_ekpo>-banfn ) AND ( loekz = ' ' )
                             AND ( ebeln <> <fs_ekpo>-ebeln ) AND ( pstyp = '9' ).

              IF sy-subrc = 0 .
                SELECT * FROM ekkn INTO TABLE t_ekkn FOR ALL ENTRIES IN lt_ekpo WHERE ebeln = lt_ekpo-ebeln AND
                                         ebelp = lt_ekpo-ebelp AND
                                         fistl = <fs_ekpo>-fistl AND
                                         fipos = <fs_ekpo>-fipos AND
                                         loekz = ' ' .


                IF sy-subrc = 0 .
                  LOOP AT lt_ekpo ASSIGNING <f_ekpo>.

*    Get currency
                    LOOP AT t_ekkn ASSIGNING <fs_ekkn> WHERE ebeln = <f_ekpo>-ebeln
                                                       AND ebelp = <f_ekpo>-ebelp
                                                       AND fistl = <fs_ekpo>-fistl
                                                       AND fipos = <fs_ekpo>-fipos  .
                      CLEAR: w_ekko.

                      SELECT SINGLE * FROM ekko INTO w_ekko WHERE ebeln = <fs_ekkn>-ebeln AND
                                                      loekz = ' '.
                      IF sy-subrc = 0 .

* Check that financial year also matches. Only then should the utilized
* amount be summed up

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
                        " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
** Transport OCQK901318 SAP - ATC Correction 01.06.2026
                        SELECT * FROM eket   UP TO 1 ROWS INTO w_eket WHERE ebeln
                       = <fs_ekkn>-ebeln AND ebelp = <fs_ekkn>-ebelp
                       ORDER BY  ebeln ebelp etenr .   ENDSELECT.
                        " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
* End of Quick Fix


*              PERFORM PO_DELY_DATE_FISCL_YR USING EKKO-BUKRS
*                                                  EKET-EINDT
*                                         CHANGING L_PRYEAR .

                        CALL FUNCTION 'GET_CURRENT_YEAR'
                          EXPORTING
                            bukrs = ls_mepoheader-bukrs
                            date  = w_eket-eindt
                          IMPORTING
                            curry = l_year.

* Only if Old POs are utilizing funds in the PO year, amt will be added
                        IF ( l_pryear = l_year ).
                          IF ls_mepoheader-waers = 'INR' .
                            g_pramt = g_pramt + <fs_ekkn>-netwr .
                          ELSE .
* if amt is not in INR, it should be converted before adding
*                  PERFORM CONVERT_TO_LOCAL_CURRENCY USING EKKO-WAERS
*                                                          G_BADAT
*                                                          EKKN-NETWR
*                                                    CHANGING EKKN-NETWR .

                            CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                              EXPORTING
                                client           = sy-mandt
                                date             = g_badat
                                foreign_amount   = <fs_ekkn>-netwr
                                foreign_currency = ls_mepoheader-waers
                                local_currency   = 'INR'
                                type_of_rate     = 'M'
                                read_tcurr       = 'X'
                              IMPORTING
                                local_amount     = <fs_ekkn>-netwr
                              EXCEPTIONS
                                no_rate_found    = 1
                                overflow         = 2
                                no_factors_found = 3
                                no_spread_found  = 4
                                derived_2_times  = 5
                                OTHERS           = 6.
                            IF sy-subrc <> 0.
                              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                            ENDIF.
                            g_pramt = g_pramt + <fs_ekkn>-netwr .
                          ENDIF .
                        ENDIF .

                      ENDIF .
                    ENDLOOP.
                  ENDLOOP.
                ENDIF.

              ENDIF .
            ENDIF.
*
**End of addition 28.12.2005
*
**After finding the funds sactioned in PR, find old POs utlizing the fund
*  PERFORM OLD_PO_FOR_PR1 USING L_PRNO
*                              L_FCTR
*                              L_CI
*                              L_POYEAR
*                        CHANGING G_AMT .

            CLEAR: l_year, lt_ekpo[], w_eket, w_ekko.
** Find all old PO items utilizing the funds sanctioned in the PR
            SELECT * FROM ekpo INTO TABLE lt_ekpo WHERE banfn = <fs_ekpo>-banfn AND fistl = <fs_ekpo>-fistl AND
                                     fipos = <fs_ekpo>-fipos AND loekz = ' ' AND
                                     ( ebeln <> <fs_ekpo>-ebeln ).
* Find the year in which funds are being utilized in the old POs
            IF sy-subrc = 0 .
              LOOP AT lt_ekpo ASSIGNING <f_ekpo>.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*                SELECT SINGLE * FROM eket INTO w_eket WHERE ebeln = <f_ekpo>-ebeln AND
*                                                ebelp = <f_ekpo>-ebelp .

                SELECT * FROM eket INTO w_eket UP TO 1 ROWS WHERE ebeln = <f_ekpo>-ebeln AND
                 ebelp = <f_ekpo>-ebelp
                 ORDER BY PRIMARY KEY .
                ENDSELECT.
* End of Quick Fix


*      PERFORM PO_DELY_DATE_FISCL_YR USING WA_EKKO-BUKRS EKET-EINDT
*                                 CHANGING L_OLDPOYR .

                CALL FUNCTION 'GET_CURRENT_YEAR'
                  EXPORTING
                    bukrs = ls_mepoheader-bukrs
                    date  = w_eket-eindt
                  IMPORTING
                    curry = l_year.

* If fund utilized in old PO is in same fiscal yr, add to utilized amt.
                IF l_pryear = l_year .
* Get the currency & convert utilized amt if it is not in INR .
                  SELECT SINGLE * FROM ekko INTO w_ekko WHERE ebeln = <f_ekpo>-ebeln
                                              AND loekz = ' ' .
                  IF sy-subrc = 0 .
                    IF w_ekko-waers = 'INR' .
                      g_pramt = g_pramt + <f_ekpo>-kzwi6 .
                    ELSE .
*            PERFORM CONVERT_TO_LOCAL_CURRENCY USING EKKO-WAERS
*                                                    G_BADAT
*                                                    EKPO-KZWI6
*                                           CHANGING EKPO-KZWI6 .
                      CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                        EXPORTING
                          client           = sy-mandt
                          date             = g_badat
                          foreign_amount   = <f_ekpo>-kzwi6
                          foreign_currency = w_ekko-waers
                          local_currency   = 'INR'
                          type_of_rate     = 'M'
                          read_tcurr       = 'X'
                        IMPORTING
                          local_amount     = <f_ekpo>-kzwi6
                        EXCEPTIONS
                          no_rate_found    = 1
                          overflow         = 2
                          no_factors_found = 3
                          no_spread_found  = 4
                          derived_2_times  = 5
                          OTHERS           = 6.
                      IF sy-subrc <> 0.
                        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                      ENDIF.


                      g_pramt = g_pramt + <f_ekpo>-kzwi6 .
                    ENDIF .
                  ENDIF .
                ENDIF .
              ENDLOOP.
            ENDIF .
            " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*          ENDIF .
          ENDIF.
          " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
*          PERFORM APPEND_IST_AMT_CHK USING IST_TEKPO-BANFN IST_TEKPO-FISTL
*                    IST_TEKPO-FIPOS L_PRYEAR G_PRAMT G_AMT IST_TEKPO-KZWI6.
          wa_amtchk-banfn = <fs_ekpo>-banfn .
          wa_amtchk-fistl = <fs_ekpo>-fistl .
          wa_amtchk-fipos = <fs_ekpo>-fipos .
* Fiscal yr will come into picture if PO created after 01.04.04
          IF ( g_greater_apr = 'X' ) .
            wa_amtchk-fyear = l_poyear .
          ENDIF .
          wa_amtchk-sanct = g_pramt .         "Total funds sanctioned in PR
          wa_amtchk-olamt = g_amt .         "Total funds used in old POs
          wa_amtchk-cuamt = <fs_ekpo>-kzwi6 .     "Funds used in runtime PO
          APPEND wa_amtchk TO ist_amtchk .
          CLEAR : g_pramt , g_amt .
        ENDIF.
*For consignment and subcontracting orders, acct assignment is not
*allowed. This area takes care of that.
      ELSEIF ( <fs_ekpo>-pstyp = '2' OR
           <fs_ekpo>-pstyp = '3' ) AND ( <fs_ekpo>-knttp <> ' ' ) .
        MESSAGE e129(zmm) .
*Validation for Acct Assigned Material PO - only books/medicines.
      ELSEIF ( <fs_ekpo>-pstyp = '0' ) AND ( <fs_ekpo>-knttp <> ' ' ) .

        IF ( l_t001k-bukrs NE 'OVL' ) OR ( <fs_ekpo>-werks+0(2) NE '91' ).
          "+ shibu 001 17/11/05.
*          PERFORM ACCT_ASSGN_VALDN .

*  CHECK NOT IST_TEKPO-WERKS+0(2) EQ '91'.
****Changes made on 26.12.2005 after discussion with Sri S.Meyyappan
****M(MM)

**** Start of change code commented for OVL 21.07.2016
*          CHECK NOT ( <fs_ekpo>-werks+0(2) EQ '91'  OR
*                      <fs_ekpo>-werks      EQ '90R1' ).
***
*          IF <fs_ekpo>-knttp <> 'Q' .
*            LOOP AT t_ekkn ASSIGNING <fs_ekkn> WHERE ebelp = <fs_ekpo>-ebelp.
*
*
*              """"""""""""""""""""""""""""""""""""""""""""""""""""
*              "addition by Anamika on 29.01.2015 RD1K996103 FOR Modification in GL acocunt for C2-C3
*
*
*              READ TABLE igl_mm INTO wagl_mm  WITH KEY  sakto = <fs_ekkn>-sakto   .
***       IF    <fs_ekkn>-sakto <> waGL_mm-SAKTO.
*              IF sy-subrc NE 0 .
*                MESSAGE e130(zmm) WITH <fs_ekkn>-sakto .
*              ENDIF.
*
*
*
*
*              """"""""""""""""""""""""""""""""""""""""""""""""""""
*              "addition by Anamika on 29.01.2015 RD1K996103 FOR Modification in GL acocunt for C2-C3
*
*
*
*
*
*
*
*
*              """"""""""""""""""""""""""""""""""""""""""""""""""""
*              "Commented by Anamika on 29.01.2015 RD1K996103 FOR Modification in GL acocunt for C2-C3
**********              IF   ( <fs_ekkn>-sakto <> '0000201418' ) AND
**********                   ( <fs_ekkn>-sakto <> '0000200301' ) AND
**********                   ( <fs_ekkn>-sakto <> '0000201419' ) .
*              """"""""""""""""""""""""""""""""""""""""""""""""""""
*              "Commented by Anamika on 29.01.2015 RD1K996103 FOR Modification in GL acocunt for C2-C3
*
*
*
*
*
*            ENDLOOP .
*          ENDIF .
**** End of change code commented for OVL 21.07.2016
        ENDIF.

**Funds validation in the case of account assigned material POs.
*        PERFORM FUND_COMT_ACTASGN USING IST_TEKPO-BANFN
*                                        IST_TEKPO-BNFPO .

        CLEAR: l_lfdat, g_badat, gv_bsart.
        SELECT SINGLE lfdat badat bsart
          INTO (l_lfdat, g_badat, gv_bsart)
          FROM eban
         WHERE banfn = <fs_ekpo>-banfn
           AND bnfpo = <fs_ekpo>-bnfpo
           AND loekz = ' ' .

        IF sy-subrc <> 0.
          MESSAGE e131(zmm) WITH <fs_ekpo>-ebelp .
        ENDIF.
*PERFORM get_pr_first_rel_date USING l_prno CHANGING g_badat.


* Quick Fix Append ORDER BY PRIMARY KEY to the SELECT statement
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*        SELECT * FROM cdpos
*        INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
*        WHERE objectid EQ <fs_ekpo>-banfn AND
*              objectclas EQ 'BANF' AND
*              tabname EQ 'EBAN' AND
*              fname EQ 'FRGZU' AND
*              value_old = ' '.
        SELECT * FROM cdpos
        INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
        WHERE objectid EQ <fs_ekpo>-banfn AND
              objectclas EQ 'BANF' AND
              tabname EQ 'EBAN' AND
              fname EQ 'FRGZU' AND
              value_old = ' ' ORDER BY PRIMARY KEY.
* End of Quick Fix


        IF sy-subrc = 0 .
          SELECT * FROM cdhdr
                 INTO CORRESPONDING FIELDS OF TABLE ist_cdhdr
                 FOR ALL ENTRIES IN ist_cdpos
                 WHERE changenr EQ ist_cdpos-changenr AND
                       objectclas = 'BANF' AND
                       objectid EQ <fs_ekpo>-banfn.

          SORT ist_cdhdr BY udate utime ASCENDING .
          READ TABLE ist_cdhdr INTO wa_cdhdr INDEX 1 .
          IF sy-subrc EQ 0.
            g_badat = wa_cdhdr-udate .
          ENDIF.
        ENDIF.

* Get the fiscal year of Funds sanctioned in PR.
*  PERFORM po_dely_date_fiscl_yr USING wa_ekko-bukrs
*                                      l_lfdat
*                             CHANGING l_pryear .

        CALL FUNCTION 'GET_CURRENT_YEAR'
          EXPORTING
            bukrs = ls_mepoheader-bukrs
            date  = l_lfdat
          IMPORTING
            curry = l_pryear.


* Loop thru delry schedule & ensure all delvries are in sanctioned year

        LOOP AT lt_eket ASSIGNING <fs_eket> WHERE ebelp = <fs_ekpo>-ebelp AND loekz =' ' .

* Error if multiple PRs referred in PO line item thru delivery schedule
          .
          IF ( <fs_eket>-banfn <> <fs_ekpo>-banfn ) OR
                 ( <fs_eket>-bnfpo <> <fs_ekpo>-bnfpo ).
            MESSAGE e318(zmm) WITH <fs_ekpo>-ebelp .
          ENDIF .

          CONCATENATE ls_mepoitem-eeind+6(4) ls_mepoitem-eeind+3(2) ls_mepoitem-eeind(2) INTO l_lfdatscr.
          CALL FUNCTION 'GET_CURRENT_YEAR'
            EXPORTING
              bukrs = ls_mepoheader-bukrs
              date  = <fs_ekpo>-eindt       "L_LFDATSCR "L_LFDAT 120310
            IMPORTING
              curry = l_poyear.
* If fiscal years don't match, raise error
          IF ( l_poyear <> l_pryear ) AND ( g_greater_apr = 'X' ).
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            """""""""added by lipsy on 27.02.2015  for removing error if released RD1K995870.
*       if ls_mepoheader-frgke = 'S'.
            IF l_frgke  = 'S'.
            ELSE.

              """""""""end of addition by lipsy on 27.02.2015  for removing error if released RD1K995870.
              """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

              MESSAGE e336(zmm) WITH l_poyear l_pryear <fs_eket>-ebelp.

              """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
              """""""""added by lipsy on 27.02.2015  for removing error if released RD1K995870.
            ENDIF.

            """""""""end of addition by lipsy on 27.02.2015  for removing error if released RD1K995870.

            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          ENDIF .
        ENDLOOP.

        DATA: w_ekkn TYPE ekkn,
              w_ebkn TYPE ebkn.


        LOOP AT t_ekkn INTO w_ekkn WHERE ebelp = <fs_ekpo>-ebelp AND loekz = ' ' .
          CLEAR w_ebkn .
* Check if there is a corresponding entry in the PR for the FC/CI .
          SELECT SINGLE * FROM ebkn INTO w_ebkn WHERE banfn = <fs_ekpo>-banfn AND
                                          bnfpo = <fs_ekpo>-bnfpo AND
                                          fistl = w_ekkn-fistl AND
                                          fipos = w_ekkn-fipos AND
                                          loekz = ' ' .
          IF sy-subrc <> 0.
            MESSAGE e335(zmm) WITH w_ekkn-fistl w_ekkn-fipos <fs_ekpo>-banfn <fs_ekpo>-bnfpo.
          ENDIF.

          CLEAR wa_amtchk .
          IF ( ls_mepoheader-waers  <> 'INR' ).
*            PERFORM CONVERT_TO_LOCAL_CURRENCY USING WA_EKKO-WAERS
*                                                    G_BADAT
*                                                    IST_TEKPO-KZWI6
*                                              CHANGING IST_TEKPO-KZWI6.

            CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
              EXPORTING
                client           = sy-mandt
                date             = g_badat
                foreign_amount   = <fs_ekpo>-kzwi6
                foreign_currency = ls_mepoheader-waers
                local_currency   = 'INR'
                type_of_rate     = 'M'
                read_tcurr       = 'X'
              IMPORTING
                local_amount     = <fs_ekpo>-kzwi6
              EXCEPTIONS
                no_rate_found    = 1
                overflow         = 2
                no_factors_found = 3
                no_spread_found  = 4
                derived_2_times  = 5
                OTHERS           = 6.
            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDIF .
*If entry alrdy exists in ist_amtchk for PR/FC/CI/yr, just cumulate amt
          IF ( g_greater_apr <> 'X' ) .
* If PO created before 01.04.04, yrwise tallying won't be there
            " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*            READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
*                                           fistl = w_ekkn-fistl
*                                           fipos = w_ekkn-fipos .
            READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
            fistl = w_ekkn-fistl
            fipos = w_ekkn-fipos.
            " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
          ELSE .
* If PO created after 01.04.04, yrwise tallying will be there
            READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
                                           fistl = w_ekkn-fistl
                                           fipos = w_ekkn-fipos
                                           fyear = l_poyear.
          ENDIF.
          IF sy-subrc = 0.
*While cumulating, change amt to local currency if necessary
*            L_TABX = SY-TABIX .
* Modify the internal table with the new amount.
            wa_amtchk-cuamt = wa_amtchk-cuamt + <fs_ekpo>-kzwi6 .
            MODIFY ist_amtchk FROM wa_amtchk INDEX sy-tabix TRANSPORTING cuamt.
            CLEAR wa_amtchk .
          ELSE .
            IF ( g_greater_apr <> 'X' ) .
* If entry doesn't already exist, find out PR, old POs etc
* If PO created before 01.04.04, following subroutine will be used
*              PERFORM CHECK_FC_CI_IN_ACCT_ASSGN USING IST_TEKPO-BANFN
*                                               IST_TEKKN-FISTL
*                                               IST_TEKKN-FIPOS .

* Select all PR items where funds have been sanctioned under the FC/CI
              SELECT  * FROM ebkn INTO TABLE lt_ebkn WHERE banfn = <fs_ekpo>-banfn AND fistl = w_ekkn-fistl AND
                                        fipos = w_ekkn-fipos AND loekz = ' ' .
              IF sy-subrc = 0 .
                LOOP AT lt_ebkn ASSIGNING <fs_ebkn>.
* Find corresponding details (like delry date, currency) at EBAN level
                  CLEAR: w_eban.
                  SELECT SINGLE * FROM eban INTO w_eban WHERE banfn = <fs_ekpo>-banfn AND
                                                  bnfpo = <fs_ebkn>-bnfpo AND
                                                  loekz = ' ' .
                  CLEAR l_pryear .
*Total funds sanctioned calculated & cumulated only for PO fiscal year
                  IF sy-subrc = 0 .
*        PERFORM po_dely_date_fiscl_yr USING wa_ekko-bukrs
*                                            eban-lfdat
*                                   CHANGING l_pryear .

                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = ls_mepoheader-bukrs
                        date  = w_eban-lfdat
                      IMPORTING
                        curry = l_pryear.

                    IF ( w_eban-waers  = 'INR' ).
                      g_pramt = g_pramt +  ( w_eban-preis * w_eban-menge ) .
                    ELSE .
* If amt sanctioned is not in INR, convert into INR before adding
*          PERFORM convert_to_local_currency USING eban-waers
*                                                  g_badat
*                                                  eban-preis
*                                            CHANGING eban-preis .

                      CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                        EXPORTING
                          client           = sy-mandt
                          date             = g_badat
                          foreign_amount   = w_eban-preis
                          foreign_currency = w_eban-waers
                          local_currency   = 'INR'
                          type_of_rate     = 'M'
                          read_tcurr       = 'X'
                        IMPORTING
                          local_amount     = w_eban-preis
                        EXCEPTIONS
                          no_rate_found    = 1
                          overflow         = 2
                          no_factors_found = 3
                          no_spread_found  = 4
                          derived_2_times  = 5
                          OTHERS           = 6.
                      IF sy-subrc <> 0.
                        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                      ENDIF.

                      g_pramt = g_pramt +  ( w_eban-preis * w_eban-menge ) .
                    ENDIF .
                  ENDIF .
                ENDLOOP.
              ENDIF.

*Now to get the amt utilized in old POs for the PR
*  PERFORM old_po_for_pr_acct_assgn USING l_pr
*                                         l_fistl
*                                         l_fipos
*                                CHANGING g_amt .
* Select all POs referencing PR
              SELECT  * FROM ekpo INTO TABLE  l_ekpo WHERE ( banfn = <fs_ekpo>-banfn ) AND ( loekz = ' ' )
                                AND ( ebeln <> <fs_ekpo>-ebeln ) .
              IF sy-subrc = 0 .
                SELECT * FROM ekkn INTO TABLE l_ekkn FOR ALL ENTRIES IN l_ekpo WHERE ebeln = l_ekpo-ebeln AND
                                         ebelp = l_ekpo-ebelp AND
                                         fistl = w_ekkn-fistl AND
                                         fipos = w_ekkn-fipos AND
                                         loekz = ' ' .
              ENDIF.
              LOOP AT l_ekpo ASSIGNING <f_ekpo>.

                LOOP AT l_ekkn ASSIGNING <f_ekkn> WHERE ebeln = <f_ekpo>-ebeln AND ebelp = <f_ekpo>-ebelp.
*    Get currency
                  SELECT SINGLE * FROM ekko INTO l_ekko WHERE ebeln = <f_ekkn>-ebeln AND
                                                  loekz = ' '.
                  IF sy-subrc = 0 .
* Check that financial year also matches. Only then should the utilized
* amount be summed up

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*                    SELECT SINGLE * FROM eket INTO l_eket WHERE ebeln = <f_ekpo>-ebeln AND
*                                                    ebelp = <f_ekpo>-ebelp .

                    SELECT * FROM eket INTO l_eket UP TO 1 ROWS WHERE ebeln = <f_ekpo>-ebeln AND
                     ebelp = <f_ekpo>-ebelp
                     ORDER BY PRIMARY KEY .
                    ENDSELECT.
* End of Quick Fix


*            PERFORM po_dely_date_fiscl_yr USING ekko-bukrs
*                                                eket-eindt
*                                       CHANGING l_oldpoyear .
                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = l_ekko-bukrs
                        date  = l_eket-eindt
                      IMPORTING
                        curry = l_oldpoyear.
* If amt is in INR, it can be directly added.
                    IF l_ekko-waers = 'INR' .
                      g_amt = g_amt + <f_ekpo>-kzwi6 .
                    ELSE .
* if amt is not in INR, it should be converted before adding
*              PERFORM convert_to_local_currency USING ekko-waers
*                                                      g_badat
*                                                      ekpo-kzwi6
                      " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
**                                                CHANGING ekpo-kzwi6 .
                      CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                        EXPORTING
                          client           = sy-mandt
                          date             = g_badat
                          foreign_amount   = <f_ekpo>-kzwi6
                          foreign_currency =
                                             l_ekko-waers
                          local_currency   = 'INR'
                          type_of_rate     = 'M'
                          read_tcurr       = 'X'
                        IMPORTING
                          local_amount     = <f_ekpo>-kzwi6
                        EXCEPTIONS
                          no_rate_found    = 1
                          overflow         = 2
                          no_factors_found = 3
                          no_spread_found  = 4
                          derived_2_times  = 5
                          OTHERS           = 6.
                      " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
                      g_amt = g_amt + <f_ekpo>-kzwi6 .
                    ENDIF .
                  ENDIF .
                ENDLOOP.
              ENDLOOP.
*              CLEAR: L_EKPO1, L_EKKN, L_EKKO, L_EKET.

            ELSE .
* If PO created after 01.04.04, following subroutine will be used
*              PERFORM CHECK_FC_CI_IN_ACCT_ASSGN1 USING IST_TEKPO-BANFN
*                                               IST_TEKKN-FISTL
*                                               IST_TEKKN-FIPOS
*                                               L_POYEAR.

              CLEAR: lt_ebkn, ls_ebkn, w_eban.
              SELECT  * FROM ebkn INTO TABLE lt_ebkn WHERE banfn = <fs_ekpo>-banfn AND fistl = w_ekkn-fistl AND
                                         fipos = w_ekkn-fipos AND loekz = ' ' .
              IF sy-subrc = 0 .
                LOOP AT lt_ebkn INTO ls_ebkn.
* Find corresponding details (like delry date, currency) at EBAN level
                  SELECT SINGLE * FROM eban INTO w_eban WHERE banfn = <fs_ekpo>-banfn AND
                                                  bnfpo = ls_ebkn-bnfpo AND
                                                  loekz = ' ' .
                  CLEAR l_pryear .
*Total funds sanctioned calculated & cumulated only for PO fiscal year
                  IF sy-subrc = 0 .
*                    PERFORM PO_DELY_DATE_FISCL_YR USING WA_EKKO-BUKRS
*                                                        EBAN-LFDAT
*                                               CHANGING L_PRYEAR .
                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = ls_mepoheader-bukrs
                        date  = w_eban-lfdat
                      IMPORTING
                        curry = l_pryear.

*Cumulate the sanctioned amount only if sanctioned in PO year
                    IF ( l_pryear = l_poyear ) AND w_eban-loekz = ' ' .
                      IF ( w_eban-waers  = 'INR' ).
                        g_pramt = g_pramt +  ( w_eban-preis * w_eban-menge ) .
                      ELSE .
* If amt sanctioned is not in INR, convert into INR before adding

                        IF gv_bsart = 'MRCS'.
                          w_eban-preis = w_eban-preis * wa_ekko-zzexchng_rate.
                        ELSE.
*                          PERFORM CONVERT_TO_LOCAL_CURRENCY USING EBAN-WAERS
*                                                                  G_BADAT
*                                                                  EBAN-PREIS
*                                                          CHANGING EBAN-PREIS .

                          CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                            EXPORTING
                              client           = sy-mandt
                              date             = g_badat
                              foreign_amount   = w_eban-preis
                              foreign_currency = w_eban-waers
                              local_currency   = 'INR'
                              type_of_rate     = 'M'
                              read_tcurr       = 'X'
                            IMPORTING
                              local_amount     = w_eban-preis
                            EXCEPTIONS
                              no_rate_found    = 1
                              overflow         = 2
                              no_factors_found = 3
                              no_spread_found  = 4
                              derived_2_times  = 5
                              OTHERS           = 6.

                        ENDIF.
                        g_pramt = g_pramt +  ( w_eban-preis * w_eban-menge ) .
                      ENDIF .
                    ENDIF .
                  ENDIF .
                ENDLOOP.
              ENDIF.

*Now to get the amt utilized in old POs for the PR
*              PERFORM OLD_PO_FOR_PR_ACCT_ASSGN1 USING L_PR
*                                          L_FISTL
*                                          L_FIPOS
*                                          L_POYEAR
*                                    CHANGING G_AMT .

* Select all POs referencing PR
              SELECT  * FROM ekpo INTO TABLE  l_ekpo WHERE ( banfn = <fs_ekpo>-banfn ) AND ( loekz = ' ' )
                                           AND ( ebeln <> <fs_ekpo>-ebeln ) .
              IF sy-subrc = 0 .
                SELECT * FROM ekkn INTO TABLE l_ekkn FOR ALL ENTRIES IN l_ekpo WHERE ebeln = l_ekpo-ebeln AND
                                         ebelp = l_ekpo-ebelp AND
                                         fistl = w_ekkn-fistl AND
                                         fipos = w_ekkn-fipos AND
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                                         loekz = ' ' .
loekz = ' '
      ORDER BY PRIMARY KEY.
                " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
              ENDIF.
              LOOP AT l_ekpo ASSIGNING <f_ekpo>.

                LOOP AT l_ekkn ASSIGNING <f_ekkn> WHERE ebeln = <f_ekpo>-ebeln AND ebelp = <f_ekpo>-ebelp.
*    Get currency
                  SELECT SINGLE * FROM ekko INTO l_ekko WHERE ebeln = <f_ekkn>-ebeln AND
                                                  loekz = ' '.
                  IF sy-subrc = 0 .
* Check that financial year also matches. Only then should the utilized
* amount be summed up

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*                    SELECT SINGLE * FROM eket INTO l_eket WHERE ebeln = <f_ekpo>-ebeln AND
*                                                    ebelp = <f_ekpo>-ebelp .

                    SELECT * FROM eket INTO l_eket UP TO 1 ROWS WHERE ebeln = <f_ekpo>-ebeln AND
                     ebelp = <f_ekpo>-ebelp
                     ORDER BY PRIMARY KEY .
                    ENDSELECT.
* End of Quick Fix


*            PERFORM po_dely_date_fiscl_yr USING ekko-bukrs
*                                                eket-eindt
*                                       CHANGING l_oldpoyear .
                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = l_ekko-bukrs
                        date  = l_eket-eindt
                      IMPORTING
                        curry = l_oldpoyear.
* If amt is in INR, it can be directly added.
                    IF ( l_oldpoyear = l_poyear ).

                      IF l_ekko-waers = 'INR' .
                        g_amt = g_amt + <f_ekpo>-kzwi6 .
                      ELSE .
* if amt is not in INR, it should be converted before adding
*              PERFORM convert_to_local_currency USING ekko-waers
*                                                      g_badat
*                                                      ekpo-kzwi6
*                                                CHANGING ekpo-kzwi6 .
                        CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                          EXPORTING
                            client           = sy-mandt
                            date             = g_badat
                            foreign_amount   = <f_ekpo>-kzwi6
                            foreign_currency = l_ekko-waers
                            local_currency   = 'INR'
                            type_of_rate     = 'M'
                            read_tcurr       = 'X'
                          IMPORTING
                            local_amount     = <f_ekpo>-kzwi6
                          EXCEPTIONS
                            no_rate_found    = 1
                            overflow         = 2
                            no_factors_found = 3
                            no_spread_found  = 4
                            derived_2_times  = 5
                            OTHERS           = 6.
                        g_amt = g_amt + <f_ekpo>-kzwi6 .
                      ENDIF .
                    ENDIF.
                  ENDIF .
                ENDLOOP.
              ENDLOOP.
            ENDIF.
*            PERFORM APPEND_IST_AMT_CHK USING IST_TEKPO-BANFN
*                        IST_TEKKN-FISTL IST_TEKKN-FIPOS L_POYEAR
*                        G_PRAMT G_AMT IST_TEKPO-KZWI6 .

            wa_amtchk-banfn = <fs_ekpo>-banfn .
            wa_amtchk-fistl = w_ekkn-fistl .
            wa_amtchk-fipos = w_ekkn-fipos .
* Fiscal yr will come into picture if PO created after 01.04.04
            IF ( g_greater_apr = 'X' ) .
              wa_amtchk-fyear = l_poyear .
            ENDIF .

            wa_amtchk-sanct = g_pramt.         "Total funds sanctioned in PR
            wa_amtchk-olamt = g_amt.         "Total funds used in old POs
            wa_amtchk-cuamt = <fs_ekpo>-kzwi6.     "Funds used in runtime PO
            APPEND wa_amtchk TO ist_amtchk .
            CLEAR : g_pramt , g_amt .
          ENDIF .
        ENDLOOP .

*Funds validation for service POs.
      ELSEIF ( <fs_ekpo>-pstyp = '9' ).    "Service
*        PERFORM FUND_COMT_EBKN USING IST_TEKPO-BANFN IST_TEKPO-BNFPO .




        CLEAR : g_pramt, g_amt , w_eban.
** Check if PR Acct Assignment Category is U & if so, raise error
*        PERFORM PR_ACCT_ASSNMT_SRV USING IST_TEKPO-BANFN IST_TEKPO-BNFPO .

        SELECT SINGLE knttp INTO lv_knttp FROM eban WHERE banfn = <fs_ekpo>-banfn AND
                                                       bnfpo = <fs_ekpo>-bnfpo .
        IF lv_knttp = 'U' .
          MESSAGE e118(zmm) WITH <fs_ekpo>-banfn <fs_ekpo>-bnfpo .
        ENDIF.


** Get the delivery date from table EKET
        READ TABLE lt_eket INTO ls_eket WITH KEY ebelp = <fs_ekpo>-ebelp .
** Get the fiscal yr (for dely date) in which PO is trying to use funds
*        PERFORM PO_DELY_DATE_FISCL_YR USING WA_EKKO-BUKRS
*                                            IST_TEKET-EINDT
*                                   CHANGING L_POYEAR .
        CALL FUNCTION 'GET_CURRENT_YEAR'
          EXPORTING
            bukrs = ls_mepoheader-bukrs
            date  = ls_eket-eindt
          IMPORTING
            curry = l_poyear.

** Get the PR delivery date from the EBAN table
        SELECT SINGLE lfdat badat INTO (w_eban-lfdat, g_badat) FROM eban WHERE
                                               banfn = <fs_ekpo>-banfn AND
                                               bnfpo = <fs_ekpo>-bnfpo AND
                                               loekz = ' ' .
        IF sy-subrc <> 0 .
          MESSAGE e131(zmm) WITH <fs_ekpo>-ebelp .
        ENDIF .

* Inserted by consultant Akhil 18.01.05 for logic for currency conversio

*        PERFORM GET_PR_FIRST_REL_DATE USING L_PRNO CHANGING G_BADAT.


* Quick Fix Append ORDER BY PRIMARY KEY to the SELECT statement
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*        SELECT * FROM cdpos
*                  INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
*                  WHERE objectid EQ <fs_ekpo>-banfn AND
*                        objectclas EQ 'BANF' AND
*                        tabname EQ 'EBAN' AND
*                        fname EQ 'FRGZU' AND
*                        value_old = ' '.
        SELECT * FROM cdpos
                  INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
                  WHERE objectid EQ <fs_ekpo>-banfn AND
                        objectclas EQ 'BANF' AND
                        tabname EQ 'EBAN' AND
                        fname EQ 'FRGZU' AND
                        value_old = ' ' ORDER BY PRIMARY KEY.
* End of Quick Fix


        IF sy-subrc = 0 .
          SELECT * FROM cdhdr
                 INTO CORRESPONDING FIELDS OF TABLE ist_cdhdr
                 FOR ALL ENTRIES IN ist_cdpos
                 WHERE changenr EQ ist_cdpos-changenr AND
                       objectclas = 'BANF' AND
                       objectid EQ <fs_ekpo>-banfn.

          SORT ist_cdhdr BY udate utime ASCENDING .
          READ TABLE ist_cdhdr INTO wa_cdhdr INDEX 1 .
          g_badat = wa_cdhdr-udate .
        ENDIF.
* End of insertion on 18.01.05

** Get the fiscal year in which PR funds have been sanctioned
*        PERFORM PO_DELY_DATE_FISCL_YR USING WA_EKKO-BUKRS EBAN-LFDAT
*                                   CHANGING L_PRYEAR .
        CALL FUNCTION 'GET_CURRENT_YEAR'
          EXPORTING
            bukrs = ls_mepoheader-bukrs
            date  = w_eban-lfdat
          IMPORTING
            curry = l_pryear.
** If PO & PR delivery dates in difft yrs, error (if PO after 01.04.04)
        IF ( l_poyear <> l_pryear ) AND ( g_greater_apr = 'X' ).
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          """""""""added by lipsy on 27.02.2015  for removing error if released RD1K995870.
*       if ls_mepoheader-frgke = 'S'.
          IF l_frgke = 'S'.
          ELSE.

            """""""""end of addition by lipsy on 27.02.2015  for removing error if released RD1K995870.
            """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

            MESSAGE e336(zmm) WITH l_poyear l_pryear <fs_ekpo>-bnfpo .
            """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            """""""""added by lipsy on 27.02.2015  for removing error if released RD1K995870.
          ENDIF.

          """""""""end of addition by lipsy on 27.02.2015  for removing error if released RD1K995870.
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


        ENDIF .

        LOOP AT t_ekkn INTO w_ekkn WHERE ebelp = <fs_ekpo>-ebelp AND loekz = ' ' .
* Check if there is a corresponding entry in the PR for the FC/CI .
          CLEAR w_ebkn .
          SELECT SINGLE * FROM ebkn INTO w_ebkn WHERE banfn = <fs_ekpo>-banfn AND
                                          bnfpo = <fs_ekpo>-bnfpo AND
                                          fistl = w_ekkn-fistl AND
                                          fipos = w_ekkn-fipos AND
                                          loekz = ' ' .
          IF sy-subrc <> 0.
            MESSAGE e335(zmm) WITH w_ekkn-fistl w_ekkn-fipos <fs_ekpo>-banfn <fs_ekpo>-bnfpo.
          ENDIF.

          CLEAR wa_amtchk .



          IF ( ls_mepoheader-waers  <> 'INR' ).
*            PERFORM CONVERT_TO_LOCAL_CURRENCY USING WA_EKKO-WAERS
*                                                    G_BADAT
*                                                    IST_TEKKN-NETWR
*                                              CHANGING IST_TEKKN-NETWR.

            CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
              EXPORTING
                client           = sy-mandt
                date             = g_badat
                foreign_amount   = w_ekkn-netwr
                foreign_currency = ls_mepoheader-waers
                local_currency   = 'INR'
                type_of_rate     = 'M'
                read_tcurr       = 'X'
              IMPORTING
                local_amount     = w_ekkn-netwr
              EXCEPTIONS
                no_rate_found    = 1
                overflow         = 2
                no_factors_found = 3
                no_spread_found  = 4
                derived_2_times  = 5
                OTHERS           = 6.
          ENDIF .
*If entry alrdy exists in ist_amtchk for PR/FC/CI/yr, just cumulate amt
          IF ( g_greater_apr <> 'X' ).
* If PO created before 01.04.04, yr wise aggregation not there
            READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
                                           fistl = w_ekkn-fistl
                                           fipos = w_ekkn-fipos .
          ELSE .
* If PO created after 01.04.04, yr wise data stored in ist_amtchk
            READ TABLE ist_amtchk INTO wa_amtchk WITH KEY banfn = <fs_ekpo>-banfn
                                            fistl = w_ekkn-fistl
                                            fipos = w_ekkn-fipos
                                            fyear = l_poyear.
          ENDIF .
          IF sy-subrc = 0.
*While cumulating, change amt to local currency if necessary

* Modify the internal table with the new amount.
            wa_amtchk-cuamt = wa_amtchk-cuamt + w_ekkn-netwr .
            MODIFY ist_amtchk FROM wa_amtchk INDEX sy-tabix TRANSPORTING cuamt.
            CLEAR wa_amtchk .
          ELSE .
            IF ( g_greater_apr <> 'X' ) .
*If entry doesn't already exist, find out PR, old POs etc
*              PERFORM CHECK_FC_CI_IN_SRV USING IST_TEKPO-BANFN
*                                               IST_TEKKN-FISTL
*                                               IST_TEKKN-FIPOS .

              CLEAR: w_eban.

* Select all PR items where funds have been sanctioned under the FC/CI
              SELECT  * FROM ebkn INTO TABLE lt_ebkn WHERE banfn = <fs_ekpo>-banfn AND fistl = w_ekkn-fistl AND
                                        fipos = w_ekkn-fipos AND loekz = ' ' .
              IF sy-subrc = 0 .
* Find corresponding details (like delry date, currency) at EBAN level
                LOOP AT lt_ebkn ASSIGNING <fs_ebkn>.
                  CLEAR w_eban .
                  SELECT SINGLE * FROM eban INTO w_eban WHERE banfn = <fs_ekpo>-banfn AND
                                                   bnfpo = <fs_ebkn>-bnfpo AND
                                                   pstyp = '9' AND
                                                   loekz = ' ' .
*                  CLEAR L_PRYEAR .
*Total funds sanctioned calculated & cumulated only for PO fiscal year
                  IF sy-subrc = 0 .
*If amt sanctioned is in INR, add as such.
                    IF ( w_eban-waers  = 'INR' ) AND w_eban-loekz = ' ' .
                      g_pramt = g_pramt +  <fs_ebkn>-netwr .
                    ELSE .
* If amt sanctioned is not in INR, convert into INR before adding
*                      PERFORM CONVERT_TO_LOCAL_CURRENCY USING EBAN-WAERS
*                                                              G_BADAT
*                                                              EBKN-NETWR
*                                                        CHANGING EBKN-NETWR .

                      CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                        EXPORTING
                          client           = sy-mandt
                          date             = g_badat
                          foreign_amount   = <fs_ebkn>-netwr
                          foreign_currency = w_eban-waers
                          local_currency   = 'INR'
                          type_of_rate     = 'M'
                          read_tcurr       = 'X'
                        IMPORTING
                          local_amount     = <fs_ebkn>-netwr
                        EXCEPTIONS
                          no_rate_found    = 1
                          overflow         = 2
                          no_factors_found = 3
                          no_spread_found  = 4
                          derived_2_times  = 5
                          OTHERS           = 6.
                      g_pramt = g_pramt +   <fs_ebkn>-netwr .
                    ENDIF .
                  ENDIF .
                ENDLOOP.
              ENDIF .

*Now to get the amt utilized in old POs for the PR
*              PERFORM OLD_PO_FOR_PR_SRV USING L_SRVPR
*                                          L_SRVFISTL
*                                          L_SRVFIPOS
*                                    CHANGING G_AMT .



              SELECT  * FROM ekpo INTO TABLE  l_ekpo WHERE ( banfn = <fs_ekpo>-banfn ) AND ( loekz = ' ' )
                                             AND ( ebeln <> <fs_ekpo>-ebeln )  AND ( pstyp = '9' ) .
              IF sy-subrc = 0 .
                SELECT * FROM ekkn INTO TABLE l_ekkn FOR ALL ENTRIES IN l_ekpo WHERE ebeln = l_ekpo-ebeln AND
" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                                         ebelp = l_ekpo-ebelp AND
*                                         fistl = w_ekkn-fistl AND
*                                         fipos = w_ekkn-fipos AND
*                                         loekz = ' ' .
 ebelp = l_ekpo-ebelp AND fistl = w_ekkn-fistl AND fipos = w_ekkn-fipos
AND loekz = ' '.
                " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
              ENDIF.
              LOOP AT l_ekpo ASSIGNING <f_ekpo>.

                LOOP AT l_ekkn ASSIGNING <f_ekkn> WHERE ebeln = <f_ekpo>-ebeln AND ebelp = <f_ekpo>-ebelp.
*    Get currency
                  SELECT SINGLE * FROM ekko INTO l_ekko WHERE ebeln = <f_ekkn>-ebeln AND
                                                  loekz = ' ' AND bstyp = 'F'..
                  IF sy-subrc = 0 .
* If amt is in INR, it can be directly added.
                    IF l_ekko-waers = 'INR' .
                      g_amt = g_amt +  <f_ekkn>-netwr .
                    ELSE .
* if amt is not in INR, it should be converted before adding
*              PERFORM convert_to_local_currency USING ekko-waers
*                                                      g_badat
*                                                      ekpo-kzwi6
*                                                CHANGING ekpo-kzwi6 .
                      CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                        EXPORTING
                          client           = sy-mandt
                          date             = g_badat
                          foreign_amount   = <f_ekkn>-netwr
                          foreign_currency = l_ekko-waers
                          local_currency   = 'INR'
                          type_of_rate     = 'M'
                          read_tcurr       = 'X'
                        IMPORTING
                          local_amount     = <f_ekkn>-netwr
                        EXCEPTIONS
                          no_rate_found    = 1
                          overflow         = 2
                          no_factors_found = 3
                          no_spread_found  = 4
                          derived_2_times  = 5
                          OTHERS           = 6.


                      g_amt = g_amt + <f_ekpo>-kzwi6 .
                    ENDIF .
                  ENDIF .
                ENDLOOP.
              ENDLOOP.


            ELSE .
*              PERFORM CHECK_FC_CI_IN_SRV1 USING IST_TEKPO-BANFN
*                                               IST_TEKKN-FISTL
*                                               IST_TEKKN-FIPOS
*                                               L_POYEAR .



* Select all PR items where funds have been sanctioned under the FC/CI
              SELECT  * FROM ebkn INTO TABLE lt_ebkn WHERE banfn = <fs_ekpo>-banfn AND fistl = w_ekkn-fistl AND
                                        fipos = w_ekkn-fipos AND loekz = ' ' .
              IF sy-subrc = 0 .
                LOOP AT lt_ebkn ASSIGNING <fs_ebkn>.
* Find corresponding details (like delry date, currency) at EBAN level
                  CLEAR: w_eban.
                  SELECT SINGLE * FROM eban INTO w_eban WHERE banfn = <fs_ekpo>-banfn AND
                                                  bnfpo = <fs_ebkn>-bnfpo AND
                                                  pstyp = '9'   AND
                                                  loekz = ' ' .
                  CLEAR l_pryear .
*Total funds sanctioned calculated & cumulated only for PO fiscal year
                  IF sy-subrc = 0 .
*        PERFORM po_dely_date_fiscl_yr USING wa_ekko-bukrs
*                                            eban-lfdat
*                                   CHANGING l_pryear .

                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = ls_mepoheader-bukrs
                        date  = w_eban-lfdat
                      IMPORTING
                        curry = l_pryear.

                    IF ( l_pryear = l_poyear ) AND w_eban-loekz = ' ' .

                      IF ( w_eban-waers  = 'INR' ) AND w_eban-loekz = ' '.
                        g_pramt = g_pramt + <fs_ebkn>-netwr .
                      ELSE .
* If amt sanctioned is not in INR, convert into INR before adding
*          PERFORM convert_to_local_currency USING eban-waers
*                                                  g_badat
*                                                  eban-preis
*                                            CHANGING eban-preis .

                        CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                          EXPORTING
                            client           = sy-mandt
                            date             = g_badat
                            foreign_amount   = <fs_ebkn>-netwr
                            foreign_currency = w_eban-waers
                            local_currency   = 'INR'
                            type_of_rate     = 'M'
                            read_tcurr       = 'X'
                          IMPORTING
                            local_amount     = <fs_ebkn>-netwr
                          EXCEPTIONS
                            no_rate_found    = 1
                            overflow         = 2
                            no_factors_found = 3
                            no_spread_found  = 4
                            derived_2_times  = 5
                            OTHERS           = 6.
                        IF sy-subrc <> 0.
                          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                        ENDIF.

                        g_pramt = g_pramt +  <fs_ebkn>-netwr  .
                      ENDIF .
                    ENDIF.
                  ENDIF .
                ENDLOOP.
              ENDIF.

*Now to get the amt utilized in old POs for the PR
*  PERFORM old_po_for_pr_srv1 USING l_srvpr
*                              l_srvfistl
*                              l_srvfipos
*                              l_poyear
*                        CHANGING g_amt .



              SELECT  * FROM ekpo INTO TABLE  l_ekpo WHERE ( banfn = <fs_ekpo>-banfn ) AND ( loekz = ' ' )
                                            AND ( ebeln <> <fs_ekpo>-ebeln ) AND ( pstyp = '9' ) .
              IF sy-subrc = 0 .
                SELECT * FROM ekkn INTO TABLE l_ekkn FOR ALL ENTRIES IN l_ekpo WHERE ebeln = l_ekpo-ebeln AND
                                         ebelp = l_ekpo-ebelp AND
                                         fistl = w_ekkn-fistl AND
                                         fipos = w_ekkn-fipos AND
                                         loekz = ' ' .
              ENDIF.
              LOOP AT l_ekpo ASSIGNING <f_ekpo>.

                LOOP AT l_ekkn ASSIGNING <f_ekkn> WHERE ebeln = <f_ekpo>-ebeln AND ebelp = <f_ekpo>-ebelp.
*    Get currency
                  SELECT SINGLE * FROM ekko INTO l_ekko WHERE ebeln = <f_ekkn>-ebeln AND
                                                  loekz = ' '.
                  IF sy-subrc = 0 .
* Check that financial year also matches. Only then should the utilized
* amount be summed up

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*                    SELECT SINGLE * FROM eket INTO l_eket WHERE ebeln = <f_ekpo>-ebeln AND
*                                                    ebelp = <f_ekpo>-ebelp .

                    SELECT * FROM eket INTO l_eket UP TO 1 ROWS WHERE ebeln = <f_ekpo>-ebeln AND
                     ebelp = <f_ekpo>-ebelp
                     ORDER BY PRIMARY KEY .
                    ENDSELECT.
* End of Quick Fix


*            PERFORM po_dely_date_fiscl_yr USING ekko-bukrs
*                                                eket-eindt
*                                       CHANGING l_oldpoyear .
                    CLEAR: l_pryear.
                    CALL FUNCTION 'GET_CURRENT_YEAR'
                      EXPORTING
                        bukrs = l_ekko-bukrs
                        date  = l_eket-eindt
                      IMPORTING
                        curry = l_pryear.
* If amt is in INR, it can be directly added.

* Only if Old POs are utilizing funds in the PO year, amt will be added
                    IF ( l_pryear = l_poyear ).
                      IF l_ekko-waers = 'INR' .
                        g_amt = g_amt + <f_ekkn>-netwr .
                      ELSE .
* if amt is not in INR, it should be converted before adding
*              PERFORM convert_to_local_currency USING ekko-waers
*                                                      g_badat
*                                                      ekpo-kzwi6
*                                                CHANGING ekpo-kzwi6 .
                        CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
                          EXPORTING
                            client           = sy-mandt
                            date             = g_badat
                            foreign_amount   = <f_ekkn>-netwr
                            foreign_currency = l_ekko-waers
                            local_currency   = 'INR'
                            type_of_rate     = 'M'
                            read_tcurr       = 'X'
                          IMPORTING
                            local_amount     = <f_ekkn>-netwr
                          EXCEPTIONS
                            no_rate_found    = 1
                            overflow         = 2
                            no_factors_found = 3
                            no_spread_found  = 4
                            derived_2_times  = 5
                            OTHERS           = 6.


                        g_amt = g_amt + <f_ekkn>-netwr .
                      ENDIF .
                    ENDIF.
                  ENDIF .
                ENDLOOP.
              ENDLOOP.
            ENDIF .
*            PERFORM APPEND_IST_AMT_CHK USING IST_TEKPO-BANFN
*                        IST_TEKKN-FISTL IST_TEKKN-FIPOS L_POYEAR
*                        G_PRAMT G_AMT IST_TEKKN-NETWR .
            wa_amtchk-banfn = <fs_ekpo>-banfn .
            wa_amtchk-fistl = w_ekkn-fistl .
            wa_amtchk-fipos = w_ekkn-fipos .
* Fiscal yr will come into picture if PO created after 01.04.04
            IF ( g_greater_apr = 'X' ) .
              wa_amtchk-fyear = l_poyear .
            ENDIF .

            wa_amtchk-sanct = g_pramt .         "Total funds sanctioned in PR
            wa_amtchk-olamt = g_amt .         "Total funds used in old POs
            wa_amtchk-cuamt = w_ekkn-netwr .     "Funds used in runtime PO
            APPEND wa_amtchk TO ist_amtchk .
            CLEAR : g_pramt , g_amt .
          ENDIF .
        ENDLOOP .
      ENDIF .
    ENDLOOP.

*    TABLES SETLEAF.
    CLEAR: wa_amtchk.
    CLEAR  l_flg1.
    IF ls_mepoheader-bsart = 'MPOM' OR ls_mepoheader-bsart = 'MPOI'.

      IF g_trtyp = 'V'.

        SELECT SINGLE * FROM setleaf INTO ls_setleaf WHERE setname = 'ZMM_CENTRAL_PGRPS'
                  AND valfrom = ls_mepoheader-ekgrp.

        IF sy-subrc = 0.

          SELECT * FROM cdpos
                   INTO CORRESPONDING FIELDS OF TABLE ist_cdpos
                   WHERE objectclas = 'EINKBELEG' AND
                         objectid = ls_mepoheader-ebeln AND
                         tabname = 'EKKO' AND
                         fname = 'FRGKE' AND
                         value_new = 'S'.

          IF sy-subrc = 0.
            l_flg1 = 'X'.
          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

    IF l_flg1 = 'X'.

      LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> WHERE zzzpr_escln = 'X' AND loekz = space.

        READ TABLE ist_amtchk INTO wa_amtchk WITH KEY fistl = <fs_ekpo>-fistl
                                                      fipos = <fs_ekpo>-fipos.

        " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
        " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
        IF sy-subrc EQ 0.
          wa_amtchk-zzpr_escln = 'X'.

          MODIFY ist_amtchk FROM wa_amtchk INDEX sy-tabix TRANSPORTING zzpr_escln.

        ENDIF.

      ENDLOOP.

    ENDIF.
*+18.01.2006 - Uncommented
*+SPP001 - No validation of fund sanctioned in case of EPC approval
*          while creating/changing central PO
*****SAB_CKNAND  11.01.2006 Commenting the below part due to non
*transport of ZMM_EKGRP and it was asked to comment by CMM_CHAINULU.
    l_chk = '0'.
    l_ans = '0'.

    SELECT SINGLE * FROM zmm_ekgrp INTO ls_zmm_ekgrp
       WHERE ekgrp = ls_mepoheader-ekgrp.

    IF sy-subrc <> 0.
      l_chk = '1'.
    ENDIF.

*Insert into history table -

*    IF L_CHK = '0'.
*      CLEAR : LT_ZMM_EPCLOG.
*      CLEAR : LS_ZMM_EPCLOG.
*
*      SELECT * FROM ZMM_EPCLOG INTO TABLE LT_ZMM_EPCLOG
*         WHERE EBELN = LS_MEPOHEADER-EBELN.
*
*      IF SY-SUBRC = 0.
*        SORT LT_ZMM_EPCLOG BY VERSN DESCENDING.
*
*        READ TABLE LT_ZMM_EPCLOG INTO LS_ZMM_EPCLOG INDEX 1.
*        IF SY-SUBRC EQ 0.
*          L_D = SY-DATUM.
*          L_T = SY-UZEIT.
*
*          CONVERT DATE L_D TIME L_T INTO
*                  TIME STAMP L_TSTAMP TIME ZONE 'UTC   '.
*
*
*          IF LS_MEPOHEADER-ZZEPC <> LS_ZMM_EPCLOG-EPC_NEW.
*
*            CLEAR : L_EPC.
*            MOVE LS_ZMM_EPCLOG-EPC_NEW TO L_EPC.
*
*            MOVE  SY-UNAME TO LS_ZMM_EPCLOG-CHANGED_BY.
*            MOVE  SY-DATUM TO LS_ZMM_EPCLOG-CHANGED_ON.
*            MOVE  L_EPC    TO LS_ZMM_EPCLOG-EPC_OLD.
*            MOVE LS_MEPOHEADER-ZZEPC TO LS_ZMM_EPCLOG-EPC_NEW.
*
*            L_VERSN = LS_ZMM_EPCLOG-VERSN + 1.
*            MOVE L_VERSN TO LS_ZMM_EPCLOG-VERSN.
*
*            MOVE L_TSTAMP TO LS_ZMM_EPCLOG-TIMESTAMP.
*
*            APPEND LS_ZMM_EPCLOG TO LT_ZMM_EPCLOG.
*          ENDIF.
*          MODIFY ZMM_EPCLOG FROM TABLE LT_ZMM_EPCLOG.
**          IF SY-SUBRC = 0.
**            COMMIT WORK.
**          ELSE.
**            ROLLBACK WORK.
**          ENDIF.
*        ENDIF.
*      ELSE.
*        IF LS_MEPOHEADER-ZZEPC = 'Y'.
*
*          MOVE SY-MANDT TO LS_ZMM_EPCLOG-MANDT.
*          MOVE LS_MEPOHEADER-EBELN TO LS_ZMM_EPCLOG-EBELN.
*          MOVE LS_MEPOHEADER-BEDAT TO LS_ZMM_EPCLOG-BEDAT.
*
*          MOVE  SY-UNAME TO LS_ZMM_EPCLOG-CHANGED_BY.
*          MOVE  SY-DATUM TO LS_ZMM_EPCLOG-CHANGED_ON.
*          MOVE LS_MEPOHEADER-ZZEPC TO LS_ZMM_EPCLOG-EPC_NEW.
*          MOVE '0001' TO LS_ZMM_EPCLOG-VERSN.
*
*          MOVE L_TSTAMP TO LS_ZMM_EPCLOG-TIMESTAMP.
*
*          APPEND LS_ZMM_EPCLOG TO LT_ZMM_EPCLOG.
*
*          MODIFY ZMM_EPCLOG FROM TABLE LT_ZMM_EPCLOG.
**          IF SY-SUBRC = 0.
**            COMMIT WORK.
**          ELSE.
**            ROLLBACK WORK.
**          ENDIF.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*****************

    IF ls_mepoheader-zzepc = 'Y' AND l_chk = '0'.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Alert '
          text_question         = 'Sanction is not sufficient but EPC approval exists ?'
*         TEXT_QUESTION         = text-003
          text_button_1         = 'Yes'
          text_button_2         = 'No'
          display_cancel_button = ''
          default_button        = '1'
        IMPORTING
          answer                = l_ans.
    ENDIF.

    IF l_ans = '1'.
      MESSAGE s369(zmm).
    ELSE.
**+SPP001 - End
********END OF Change by sab_cknand.

*Here check the funds sanctioned & consumed PR/FC/CI-wise & raise error
*if exceeded
      IF NOT ist_amtchk[] IS INITIAL .
        LOOP AT ist_amtchk INTO wa_amtchk WHERE zzpr_escln <> 'X' .
          l_sumamt = ( wa_amtchk-olamt + wa_amtchk-cuamt ) .
          wa_amtchk-sanct = wa_amtchk-sanct +  l_round_val. "RK +001
          IF  l_sumamt > wa_amtchk-sanct.
            IF ( g_greater_apr <> 'X' ) .
              IF l_frgke  = 'S'.
              ELSE.
                MESSAGE e386(zmm) WITH wa_amtchk-fistl wa_amtchk-fipos
                                       wa_amtchk-banfn .
              ENDIF.
            ELSE .
              IF l_frgke  = 'S'.
              ELSE.
                """"""""""""""""""""""""""""""""""""""
                "ADDED BY LIPSY ON 27.05.2015 RD1K997318
                IF l_frgzu = 'XX' OR l_frgzu = 'X'.
                ELSE.
                  "END OF ADDITION BY LIPSY ON 27.05.2015 RD1K997318
                  """""""""""""""""""""""""""""""""""""""""
                  MESSAGE e391(zmm) WITH wa_amtchk-fistl wa_amtchk-fipos
                                         wa_amtchk-banfn wa_amtchk-fyear.

                  """"""""""""""""""""""""""""""""""""""
                  "ADDED BY LIPSY ON 27.05.2015 RD1K997318
                ENDIF.
                "END OF ADDITION BY LIPSY ON 27.05.2015 RD1K997318
                """"""""""""""""""""""""""""""""""""""""""""

              ENDIF.
            ENDIF .
            wa_amtchk-sanct = wa_amtchk-sanct -  l_round_val. "RK +001
          ENDIF .
        ENDLOOP .
      ENDIF .
    ENDIF.                                                  "+SPP001
  ENDIF. "EPC FUND VALIDATION END IF.

  " " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
* ** Validations as per FS-MM-INV-205-R06
** Validations as per FS-MM-INV-205-R06
** Start of Change ID KB +001
  IF ( sy-tcode <> 'ME28' ) AND ( sy-tcode <> 'ZMMME28' )  "#EC CI_USAGE_OK[1803189]
  AND ( sy-tcode <> 'ME35K' )
  AND ( sy-tcode <> 'ZMMME35K' )
  AND ( sy-uname+0(3) <> 'CMM' ) .

    IF ls_mepoheader-bsart+0(1) = 'M'. "if Material Doc.
      IF ls_mepoheader-bsart = 'MICM' OR ls_mepoheader-bsart = 'MIMM' .
      ELSE.
* REFRESH R_WERKS.
        CLEAR: r_werks[], w_werks, ist_werks[], wa_werks.
* REFRESH IST_WERKS.
* CLEAR IST_WERKS.

        SELECT * FROM setleaf CLIENT SPECIFIED
        APPENDING CORRESPONDING FIELDS OF TABLE ist_werks
        WHERE mandt = sy-mandt
        AND setclass = c_000
        AND setname = c_set .

        LOOP AT ist_werks INTO wa_werks .
          w_werks-low = wa_werks-valfrom.
          w_werks-high = wa_werks-valto.
          w_werks-sign = 'I'.
          w_werks-option = 'BT'.
          APPEND w_werks TO r_werks.
          CLEAR w_werks.
        ENDLOOP.

*Begin of <RD1K962333>.

*End of <RD1K962333>.
        LOOP AT lt_mepoitem INTO <fs_ekpo> .
          MOVE <fs_ekpo>-pstyp TO pstyp.
* receiving and sending plant should not be same.
*Begin of <RD1K962333>.
* IF tekpo-werks IN r_werks AND tekpo-loekz = space
* AND NOT ( i_ekko-reswk IN r_werks ) .
          IF <fs_ekpo>-werks IN r_werks AND <fs_ekpo>-loekz = space
          AND NOT ( ls_mepoheader-reswk IN r_werks ) AND ( pstyp = '0' ).
*End of <RD1K962333>.
            READ TABLE lt_komv INTO ls_komv WITH KEY kposn = <fs_ekpo>-ebelp
            kschl = 'ZOC1'.
            IF sy-subrc <> 0.
              MESSAGE e673(zmm) WITH <fs_ekpo>-ebelp.
            ENDIF.

          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
    IF g_trtyp = 'V' . "Only at the time of change
* REFRESH IST_EKPO.
      CLEAR: ist_ekpo[], wa_ekpo.

      SELECT * APPENDING CORRESPONDING FIELDS OF TABLE ist_ekpo
      FROM ekpo WHERE ebeln EQ ls_mepoheader-ebeln .

      LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> .

        IF <fs_ekpo>-loekz <> space.
          READ TABLE ist_ekpo INTO wa_ekpo WITH KEY ebelp = <fs_ekpo>-ebelp.

          IF wa_ekpo-loekz EQ space.
            CLEAR: ist_ekbe[], wa_ekbe .
            CLEAR: l_grqty, l_ivqty.

            SELECT * APPENDING CORRESPONDING FIELDS OF TABLE ist_ekbe
            FROM ekbe WHERE ebeln = <fs_ekpo>-ebeln AND
            ebelp = <fs_ekpo>-ebelp .

            LOOP AT ist_ekbe INTO wa_ekbe.
              IF wa_ekbe-shkzg = 'H'.
                IF wa_ekbe-vgabe = '1' .
                  l_grqty = l_grqty + wa_ekbe-menge.
                ELSEIF wa_ekbe-vgabe = '2'.
                  l_ivqty = l_ivqty + wa_ekbe-menge.
                ENDIF.
              ELSEIF wa_ekbe-shkzg = 'S'.
                IF wa_ekbe-vgabe = '1' .
                  l_grqty = l_grqty - wa_ekbe-menge.
                ELSEIF wa_ekbe-vgabe = '2'.
                  l_ivqty = l_ivqty - wa_ekbe-menge.
                ENDIF.
              ENDIF.
            ENDLOOP.

            IF ( l_grqty = l_ivqty ) AND ( l_grqty <> 0 )
            AND ( l_ivqty <> 0 ).
              MESSAGE e674(zmm).
            ENDIF.

          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF ls_mepoheader-bsart = 'MSIM' OR
    ls_mepoheader-bsart = 'MSDM' .

      CLEAR: ist_ekpo[], wa_ekpo.
      LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> .
        IF <fs_ekpo>-loekz = space.
          MOVE-CORRESPONDING <fs_ekpo> TO wa_ekpo.
          APPEND wa_ekpo TO ist_ekpo.
        ENDIF.
      ENDLOOP.

* REFRESH IST_MARA.
      CLEAR: ist_mara[], wa_mara.

      IF NOT ist_ekpo[] IS INITIAL.

        SELECT * APPENDING CORRESPONDING FIELDS OF TABLE ist_mara
        FROM mara
        FOR ALL ENTRIES IN ist_ekpo
        WHERE matnr = ist_ekpo-matnr.

        READ TABLE ist_mara INTO wa_mara WITH KEY mtart = 'ZCAP'.

        IF sy-subrc EQ 0.
          LOOP AT ist_mara INTO wa_mara .
            IF wa_mara-mtart <> 'ZCAP'.
              MESSAGE e675(zmm).
            ENDIF.
          ENDLOOP.
        ENDIF.

      ENDIF.

    ENDIF.

    IF g_trtyp = 'V' . "Only at the time of change
      IF ls_mepoheader-bsart = 'MSIM' AND ls_mepoheader-reswk IN r_werks_wshp.
        LOOP AT lt_mepoitem ASSIGNING <fs_ekpo> .
          IF <fs_ekpo>-loekz = space . "If item is not deleted.
            CLEAR: l_grqty, l_ivqty.
* REFRESH IST_EKBE.
            CLEAR: ist_ekbe[], wa_ekbe.

            SELECT * APPENDING CORRESPONDING FIELDS OF TABLE ist_ekbe
            FROM ekbe WHERE ebeln = <fs_ekpo>-ebeln AND
            ebelp = <fs_ekpo>-ebelp AND
            vgabe IN ('1', '6').

            IF sy-subrc = 0.
              LOOP AT ist_ekbe INTO wa_ekbe.
                IF wa_ekbe-bwart = '949'.
                  l_grqty = l_grqty + wa_ekbe-menge.
                ELSEIF wa_ekbe-bwart = '950'.
                  l_grqty = l_grqty - wa_ekbe-menge.
                ELSEIF wa_ekbe-bwart = '101'.
                  l_ivqty = l_ivqty + wa_ekbe-menge.
                ELSEIF wa_ekbe-bwart = '102'.
                  l_ivqty = l_ivqty - wa_ekbe-menge.
                ENDIF.
              ENDLOOP.

              IF l_grqty <> l_ivqty AND l_grqty <> 0 AND l_ivqty <> 0.
                CLEAR: ist_konv[], wa_konv.

* Quick Fix Append ORDER BY PRIMARY KEY to the SELECT statement
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
* SELECT * INTO TABLE ist_konv FROM V_KONV_CDS FOR ALL ENTRIES IN lt_komv
                " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
*                        WHERE knumv = lt_komv-knumv AND kposn = <fs_ekpo>-ebelp.
*Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 11.06.2026
*                SELECT * INTO TABLE ist_konv FROM konv FOR ALL ENTRIES IN lt_komv
*                        WHERE knumv = lt_komv-knumv AND kposn = <fs_ekpo>-ebelp ORDER BY PRIMARY KEY.

                SELECT * INTO CORRESPONDING FIELDS OF TABLE ist_konv FROM prcd_elements
                  FOR ALL ENTRIES IN lt_komv
      WHERE knumv = lt_komv-knumv AND kposn = <fs_ekpo>-ebelp ORDER BY PRIMARY KEY.
*Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 11.06.2026
* End of Quick Fix


                LOOP AT lt_komv ASSIGNING <fs_komv> WHERE kposn = <fs_ekpo>-ebelp.
                  READ TABLE ist_konv INTO wa_konv WITH KEY kposn = <fs_komv>-kposn
                                               stunr = <fs_komv>-stunr
                                               kschl = <fs_komv>-kschl
                                               kbetr = <fs_komv>-kbetr.

                  IF sy-subrc NE 0.
                    MESSAGE e676(zmm).
                  ENDIF.
                ENDLOOP.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.



*--- Change Begin : GR Mansuri  15.10.05   Validation check
*                                           for CVC Report
* data: l_ebeln  type ekko-ebeln.


  IF ls_mepoheader-aedat > '20051227' AND ls_mepoheader-bukrs <> 'OBV'.
    IF NOT ( sy-uname+0(3) = 'CMM' OR sy-uname+0(3) = 'SMM'

*Commented on 28.02.2007 - CAB_SPYADAV - Not required to bypass RMM*
*users - Start
**Start Changes by SAB_RAMESH on 16.06.2006
**Inclusion of RMM users in the exclude list in the Po user exit
*zxm06u43
*                                 or sy-uname+0(3) = 'RMM')."-SP004
**End Changes
  ).                                                        "+SP004
*End of comment
      IF     ls_mepoheader-bsart = 'FO'   OR ls_mepoheader-bsart = 'MPCM'
          OR ls_mepoheader-bsart = 'MPOM' OR ls_mepoheader-bsart = 'MICM'
          OR ls_mepoheader-bsart = 'MIMM' OR ls_mepoheader-bsart = 'SEM'
          OR ls_mepoheader-bsart = 'SNB'  OR ls_mepoheader-bsart = 'STK'.

        l_lifnr = ls_mepoheader-lifnr.

        IF ls_mepoheader-submi IS INITIAL.
          ls_mepoheader-submi = ls_mepoheader-zzsubmi.
        ENDIF.

        SELECT ebeln INTO TABLE itab_ebeln  FROM ekko
          WHERE lifnr = l_lifnr AND
                bstyp = 'A' AND
                statu = 'A' AND
                submi = ls_mepoheader-submi.

        CLEAR l_bsart.
        SELECT SINGLE bsart INTO l_bsart FROM zmm_pur_tender_d
        WHERE submi = ls_mepoheader-submi.

        IF l_bsart+0(1) <> 'E'.

          l_flag = 'N'.


          SELECT ebeln loekz INTO TABLE lt_ebeln FROM ekko FOR ALL ENTRIES IN itab_ebeln
                 WHERE ebeln = itab_ebeln-ebeln AND loekz = ' '.

          IF NOT  itab_ebeln[] IS INITIAL.
            LOOP AT itab_ebeln INTO wa_ebeln.
*            SELECT EBELN INTO  L_EBELN FROM EKPO
*             WHERE  EBELN = WA_EBELN AND LOEKZ = ' '.
*              IF SY-SUBRC = 0.
*                L_FLAG = 'Y'.
*              ENDIF.
*            ENDSELECT.
              READ TABLE lt_ebeln INTO l_ebeln WITH KEY ebeln = wa_ebeln loekz = ' '.
              IF sy-subrc = 0.
                l_flag = 'Y'.
              ENDIF.
            ENDLOOP.
          ENDIF.

          """""""""""""""""""""
          "start of addition by lipsy on 4.2.2013 for message e959  for all line items RD1K983281
          CLEAR:v_check_kunnr.
          "end of addition by lipsy on 4.2.2013 for message e959  for all line items RD1K983281

          """"""""""""
          LOOP AT  lt_mepoitem ASSIGNING <fs_ekpo>.
            IF  NOT <fs_ekpo>-konnr IS INITIAL OR
*              tekpo-bednr+0(4) = 'S100'.
********SAB_CKNAND 01.03.2005
                <fs_ekpo>-bednr+0(3) = 'S15'.
********END SAB_CKNAND 01.03.2005
              l_flag = 'Y'.

            ENDIF.

            "start of addition by lipsy on 19.12.2012 for message e959  for all line items <RD1K982318>
            """""""""""""""""""""""""""""""""""""
            """"""""""""""""""""""""""""""""
            "start of addition by lipsy on 4.2.2013 for message e959  for all line items RD1K983281

            IF <fs_ekpo>-konnr IS NOT INITIAL.
              IF <fs_ekpo>-loekz  = ' '.
                v_check_kunnr = 'X'.
              ENDIF.
            ENDIF.

            "end of addition by lipsy on 4.2.2013 for message e959  for all line items RD1K983281

            "start of comment by lipsy on 4.2.2013 for message e959  for all line items RD1K983281
*if LS_MEPOHEADER-aedat >= '20130123'.
*               IF   <fs_ekpo>-konnr IS INITIAL.
*               if <fs_ekpo>-bednr+0(3) = 'S15'.
*               else.
**               if <fs_ekpo>-loekz  = 'L' or <fs_ekpo>-loekz  = 'S'.
**                 else.
*               if <fs_ekpo>-loekz  = ' '.
*               MESSAGE e959(zmm) .
*               ENDIF.
*               endif.
*               ENDIF.
*ENDIF.
            "end of addition by lipsy on 9.1.2013 for message e959  for all line items RD1K983281
            "end of addition by lipsy on 19.12.2012 for message e959 for all line items <RD1K982318>
            "end of comment by lipsy on 4.2.2013 for message e959  for all line items RD1K983281

          ENDLOOP.

          """""""""""""""""""""
          "start of addition by lipsy on 4.2.2013 for message e959  for all line items <RD1K982318>

          IF v_check_kunnr = 'X'.
            CLEAR:ls_mepoitem1.
            LOOP AT  lt_mepoitem INTO ls_mepoitem1.
              """""""""RD1K983832  added by lipsy on 21.02.2013
              IF ls_mepoheader-aedat > '20130331'.
                """"""""RD1K983832  end of addition by lipsy on 21.02.2013
                """""""""RD1K983832  commented by lipsy on 21.02.2013
*if LS_MEPOHEADER-aedat > '20130207'.
                """""""""RD1K983832  end of comment by lipsy on 21.02.2013

                IF   ls_mepoitem1-konnr IS INITIAL.
                  IF ls_mepoitem1-loekz  = ' '.
                    MESSAGE e959(zmm) .
                  ENDIF.
                ENDIF.
              ENDIF.
              CLEAR:ls_mepoitem1.
            ENDLOOP.
          ENDIF.

          "end of addition by lipsy on 4.2.2013 for message e959  for all line items <RD1K982318>

          """""""""""""""""""""""
* Begin of <> 22052013
          IF  ls_mepoheader-frgke      <> 'S'.
            IF l_flag = 'N'.
              IF sy-uname+0(1) <> 'C'.
                MESSAGE e517(zmm) WITH ls_mepoheader-submi l_lifnr .
              ENDIF.
            ENDIF.
          ENDIF.
*{CR 30008447

          CLEAR l_rel_stat.
******************* CR 30009068
* Begin of <RD1K985058> on 21052013
*    IF NOT LS_MEPOHEADER-SUBMI is initial.
          IF  ls_mepoheader-zznat_proc = 8 OR
              ls_mepoheader-zznat_proc = 10 OR
              ls_mepoheader-zznat_proc = 12 OR
              ls_mepoheader-zznat_proc = 13 OR
              ls_mepoheader-zznat_proc = 14 OR
              ls_mepoheader-zznat_proc = 15 .
            g_flag = 'X'.
          ENDIF.
          IF  ls_mepoheader-frgke      = 'S'.
            g_flag = 'X'.
          ENDIF.
          IF  NOT ls_mepoitem-konnr       IS INITIAL.
            g_flag = 'X'.
          ENDIF.
          IF ls_mepoitem-bednr       CP 'S15*'. ""
            g_flag = 'X'.
          ENDIF.
          IF g_flag <> 'X'.
* End of <RD1K985058>
*********************
            SELECT SINGLE rel_stat INTO l_rel_stat
              FROM zmm_tms
              WHERE submi = ls_mepoheader-submi.
            IF sy-subrc = 0.
              IF l_rel_stat IS INITIAL.
*              MESSAGE e321(zmm) WITH text-002 ls_mepoheader-submi  . " - cab_dhiraj 30009068
                IF l_frgke  = 'S'.
                ELSE.
                  IF sy-uname+0(1) <> 'C'.
                    MESSAGE e321(zmm) WITH TEXT-003 ls_mepoheader-submi  .  " + cab_dhiraj 30009068
                  ENDIF.
                ENDIF.
              ENDIF.
            ELSE.
              IF l_frgke  = 'S'.
              ELSE.
                IF sy-uname+0(1) <> 'C'.
                  MESSAGE e321(zmm) WITH TEXT-003 ls_mepoheader-submi  .  ""By Sudhir Sharma
                ENDIF.
              ENDIF.
            ENDIF.
*}CR 30008447
          ENDIF. " CR 30009068
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


*----- Check for Consumption Factor  27.04.2006.
*break cab_mansuri.



* IF ls_mepoheader-aedat > '99990101'.                      "-SPP002

  """""""""""""""""""""""""""""""
  """""""""""""""""""""""""""""""""""""""""""""""""
  "uncommented by lipsy on 19.03.2013 for testing in ifrs RD1K984170
  IF ls_mepoheader-aedat > '99991231'.                      "+SPP002
    """""""""""""""""""""""""""""""""""""""""""""""""
    "end of uncomment by lipsy on 19.03.2013 for testing in ifrs RD1K984170
    """""""""""""""""""""""""""""""""""""""""


    """""""""""""""""""""""""""""""""""""""""""""""""
    "commented by lipsy on 19.03.2013 for testing in ifrs RD1K984170
*  IF ls_mepoheader-aedat > '20130224'.           "+SPP002    "25.02.2013
    "end of comment by lipsy on 19.03.2013 for testing in ifrs RD1K984170
    """"""""""""""""""""""""""""""""""""""""""""""""""""""

    LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
      IF <fs_ekpo>-loekz = 'L' OR <fs_ekpo>-loekz = 'S' .
      ELSE.
*      PERFORM check_consumption_factor USING
*                   tekpo-matnr tekpo-werks tekpo-lgort.

*+SPP002 : Changes as per CR No. 30006706 - Start
        PERFORM check_consumption_factor IN PROGRAM zmm_consumption_calc
" Code Remediation changes S4 2025_1_P Conversion **BEGIN OF CHANGE BY SAP_ABAP 10.06.2026  for ATC
*                           USING <fs_ekpo>-matnr
                          USING <fs_ekpo>-matnr "#EC CI_FLDEXT_OK[2215424]
" Code Remediation changes S4 2025_1_P Conversion * *END OF CHANGE BY SAP_ABAP 10.06.2026 for ATC
                                <fs_ekpo>-werks
                                <fs_ekpo>-lgort.
*+SPP002 : End

*-SPP002 : Start
*        CLEAR: s_mm, s_yy, e_mm, e_yy.
*
*        s_mm = sy-datum+4(2).
*        e_mm = s_mm + 11.
*        IF e_mm > 12.
*          e_mm = e_mm - 12.
*        ENDIF.
*        s_yy = sy-datum+0(4)  - 1.
*
*        IF s_mm > 1.
*          e_yy = s_yy + 1.
*        ELSE.
*          e_yy = s_yy.
*        ENDIF.
*        CONCATENATE s_mm   s_yy INTO l_from.
        " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
        " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
        " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
        " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
*           WHERE matnr = <fs_ekpo>-matnr AND
*                 werks = <fs_ekpo>-werks AND
*                 lgort = <fs_ekpo>-lgort.
*
*        IF sy-subrc = 0.
*          CLEAR: l_cmgvbr.
*
*          SELECT SUM( cmgvbr ) FROM s034 INTO l_cmgvbr
*             WHERE matnr = <fs_ekpo>-matnr AND
*                   werks = <fs_ekpo>-werks AND
*                   lgort = <fs_ekpo>-lgort  AND
*                    spmon GE l_from  AND
*                    spmon LE l_upto.
*          IF sy-subrc  = 0.
*            l_avg_consum = l_cmgvbr / l_sto_consum-kfactor.
*            SELECT SUM( cmbwbest ) INTO l_cmbwbest FROM s035
*              WHERE matnr = <fs_ekpo>-matnr AND
*                    werks = <fs_ekpo>-werks AND
*                    lgort = <fs_ekpo>-lgort.
*            IF l_cmbwbest > l_avg_consum.
*              DATA: l_avg TYPE p DECIMALS 1.
*              l_avg =  12 / l_sto_consum-kfactor.
*              MESSAGE e841(zmm) WITH <fs_ekpo>-matnr <fs_ekpo>-werks
*                                     <fs_ekpo>-lgort l_avg.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*-SPP002 : End

      ENDIF.
    ENDLOOP.
  ENDIF.
*---   Check Over


*--- Change End: GR mansuri  15.10.05
**---Addition Begin : GR Mansuri 12.12.2005  FS-MM-INV-029
**-- Restrict STO creation if MIT exists for more than 60 days.
******UNCOMMENTED Start AS REQUEST FROM BC SHARMA SAB_CKNAND**********

* IF ls_mepoheader-aedat > '99990101'.                      "-SPP002
  """""""""""""""""""""""""""""""""""
  """""""""""""""""""""""""""""""""""""""""""""""""
  "uncommented by lipsy on 19.03.2013 for testing in ifrs RD1K984170
  IF ls_mepoheader-aedat > '99991231'.                      "+SPP002
    """""""""""""""""""""""""""""""""""""""""""""""""
    "end of uncomment by lipsy on 19.03.2013 for testing in ifrs RD1K984170
    """""""""""""""""""""""""""""""""""""""""""""""""

    """"""""""""""""""""""""""""""""""""""""""""""""""
    """""""""""""""""""""""""""""""""""""""""""""""""
    "commented by lipsy on 19.03.2013 for testing in ifrs RD1K984170
*  IF ls_mepoheader-aedat > '20130224'.           "+SPP002    "25.02.2013
    """""""""""""""""""""""""""""""""""""""""""""""""
    "end of comment by lipsy on 19.03.2013 for testing in ifrs RD1K984170
    """""""""""""""""""""""""""""""""

    IF ls_mepoheader-bsart = 'MSIM' OR ls_mepoheader-bsart = 'MSDM'.
      LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
        SELECT  ebeln INTO l_ebeln FROM ekpo
         WHERE werks = <fs_ekpo>-werks AND
               lgort = <fs_ekpo>-lgort AND
               loekz = space AND elikz = space AND
               matnr = <fs_ekpo>-matnr.
          APPEND l_ebeln TO itab_sto.
        ENDSELECT.
        IF sy-subrc = 0 .
          LOOP AT itab_sto INTO wa_ebeln.
            SELECT ebeln matnr menge bewtp budat shkzg
            APPENDING
            CORRESPONDING FIELDS OF TABLE itab_ekbe
            FROM ekbe WHERE ebeln = wa_ebeln AND matnr = <fs_ekpo>-matnr.
          ENDLOOP.
          DESCRIBE TABLE itab_ekbe LINES l_lines.
          IF l_lines > 0.
            REFRESH itab_ekbe_2.
            SORT itab_ekbe BY ebeln.
            LOOP AT itab_ekbe INTO w_ekbe.
              APPEND w_ekbe TO itab_ekbe_2.
              AT END OF   ebeln.
*            describe table itab_ekbe_2 lines l_lines.
*            delete itab_ekbe_2 index l_lines.
                itab_ekbe_gi[] = itab_ekbe_2[].
                DELETE itab_ekbe_gi WHERE bewtp <> 'U'.
                itab_ekbe_gr[] = itab_ekbe_2[].
                DELETE itab_ekbe_gr WHERE bewtp <> 'E'.
                LOOP AT itab_ekbe_gi INTO w_ekbe.
                  IF w_ekbe-shkzg = 'S'.
                    w_ekbe-menge = w_ekbe-menge * -1.
                  ENDIF.
                  matrl-matnr =  w_ekbe-matnr.
                  matrl-menge =  w_ekbe-menge.
                  COLLECT matrl INTO matab.
                ENDLOOP.
                READ TABLE matab INTO wa_matab
                           WITH TABLE KEY matnr =  w_ekbe-matnr.
                IF sy-subrc = 0.
                  l_menge_gi = wa_matab-menge.
                ENDIF.
                REFRESH matab.
                LOOP AT itab_ekbe_gr INTO w_ekbe.
                  IF w_ekbe-shkzg = 'H'.
                    w_ekbe-menge = w_ekbe-menge * -1.
                  ENDIF.
                  matrl-matnr =  w_ekbe-matnr.
                  matrl-menge =  w_ekbe-menge.
                  COLLECT matrl INTO matab.
                ENDLOOP.
                READ TABLE matab INTO wa_matab
                           WITH TABLE KEY matnr =  w_ekbe-matnr.
                IF sy-subrc = 0.
                  l_menge_gr = wa_matab-menge.
                ENDIF.
                REFRESH matab.
                IF l_menge_gr <> l_menge_gi.
                  SORT itab_ekbe_2 BY budat DESCENDING.
                  LOOP AT itab_ekbe_2 INTO w_ekbe WHERE bewtp = 'U'.
                    l_days = sy-datum -  w_ekbe-budat .
                    IF l_days > 60.
*                     MESSAGE e817(zmm) WITH <fs_ekpo>-matnr <fs_ekpo>-werks <fs_ekpo>-lgort. "-SPP002
*+SPP002 : Start
                      CLEAR : l_txt_1,
                              l_txt_2,
                              l_txt_3,
                              l_txt_4.

                      CONCATENATE 'MIT for' <fs_ekpo>-matnr ',' <fs_ekpo>-werks 'and' <fs_ekpo>-lgort
                                  INTO l_txt_1 SEPARATED BY space.
                      " " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*                       MOVE 'is pending for more than 60 days.  Clear pending' TO l_txt_2.
                      MOVE 'is pending for more than 60 days. Clear pending' TO l_txt_2.
                      MOVE 'MIT first. See ZMMMIT for further details' TO l_txt_3.
                      MOVE 'for these combinations.' TO l_txt_4.

                      MESSAGE e940(zmm) WITH l_txt_1 l_txt_2 l_txt_3 l_txt_4.
*+SPP002 : End
                    ENDIF.
                    IF l_days > 30.
* MESSAGE i818(zmm) WITH <fs_ekpo>-matnr <fs_ekpo>-werks <fs_ekpo>-lgort. "-SPP002
* .
*+SPP002 : Start
                      CLEAR : l_txt_1,
                      l_txt_2,
                      l_txt_3,
                      l_txt_4.

                      CONCATENATE 'MIT for' <fs_ekpo>-matnr ',' <fs_ekpo>-werks 'and' <fs_ekpo>-lgort
                      INTO l_txt_1 SEPARATED BY space.
                      MOVE 'is pending for more than 30 days. Clear pending' TO l_txt_2.
                      MOVE 'MIT immediately to avoid blocking of further stos' TO l_txt_3.
                      MOVE 'after 60 days.' TO l_txt_4.

                      MESSAGE w941(zmm) WITH l_txt_1 l_txt_2 l_txt_3 l_txt_4.
*+SPP002 : End
                    ENDIF.
                  ENDLOOP.
                ENDIF.
                REFRESH itab_ekbe_2.
              ENDAT.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  GET PARAMETER ID 'SWLXZAP' FIELD lv_bdcflag.

  IF ( lv_bdcflag IS INITIAL )
  AND ( sy-tcode = 'ME22N' OR sy-tcode = 'ME22'
  OR sy-tcode = 'ME23N' OR sy-tcode = 'ME23' ).  "#EC CI_USAGE_OK[1803189]

    IF NOT lt_mepoitem[] IS INITIAL.
      SELECT banfn bnfpo matnr bsart bednr repos zzsrmmark
      INTO TABLE it_eban_mrcs
      FROM eban
      FOR ALL ENTRIES IN lt_mepoitem
      WHERE banfn = lt_mepoitem-banfn
* AND bsart = 'MRCS'
      AND loekz = space.

      SELECT a~ebeln ebelp matnr menge netpr zzexchng_rate zzzsrmmark
      banfn bnfpo
      INTO TABLE it_ekpo_mrcs
      FROM ekko AS a INNER JOIN ekpo AS b
      ON a~ebeln = b~ebeln
      FOR ALL ENTRIES IN lt_mepoitem
      WHERE a~ebeln = lt_mepoitem-ebeln AND ebelp = lt_mepoitem-ebelp
      AND a~loekz = ''.

    ENDIF.

** IF NOT IT_EBAN_MRCS[] IS INITIAL.
    LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
      READ TABLE it_eban_mrcs INTO wa_eban_mrcs
      WITH KEY banfn = <fs_ekpo>-banfn
      bnfpo = <fs_ekpo>-bnfpo.
      IF sy-subrc = 0.
        lv_tabix = sy-tabix.
        READ TABLE it_ekpo_mrcs INTO wa_ekpo_mrcs
        WITH KEY ebeln = <fs_ekpo>-ebeln ebelp = <fs_ekpo>-ebelp.
        IF sy-subrc = 0.
          IF lv_tabix = 1.
            IF ls_mepoheader-zzexchng_rate <> wa_ekpo_mrcs-zzexchng_rate.
              MESSAGE e837(zmm) WITH 'SRM Exchange Rate'.
* You are not authorized to change SRM Exchange Rate
            ENDIF.
          ENDIF.

          IF ( <fs_ekpo>-zzzsrmmark = 'X' OR wa_eban_mrcs-zzsrmmark = 'X' ) .
* and <fs_ekpo>-LOEKZ <> 'X'.
*******change by vaibhav
            IF wa_eban_mrcs-bsart = 'MRCS'.
* BREAK-POINT.
              CALL METHOD im_header->get_conditions( IMPORTING ex_conditions = tmp_komv ). "
              LOOP AT tmp_komv INTO ls_komv WHERE ( kschl = 'PBXX' OR kschl = 'PB00' ) AND updkz = 'U'.
                MESSAGE e832(zmm) WITH 'Net Price'.
              ENDLOOP.


            ENDIF.
********************************
*{ uncommented rama CR 30009741
* IF <FS_EKPO>-NETPR <> WA_EKPO_MRCS-NETPR
* AND WA_EBAN_MRCS-BSART = 'MRCS'.
* MESSAGE E832(ZMM) WITH 'Net Price'.
* Invalid Changes in Net Price
* ENDIF.
*} uncommented rama CR 30009741
            IF <fs_ekpo>-matnr <> wa_ekpo_mrcs-matnr
            AND wa_eban_mrcs-bsart = 'MRCS'.
              MESSAGE e837(zmm) WITH 'Material Number'.
* You are not authorized to change Material Number
            ENDIF.
            IF wa_eban_mrcs-bednr <> <fs_ekpo>-bednr
            AND wa_eban_mrcs-bsart = 'MRCS'.
              MESSAGE e837(zmm) WITH 'Tracking Number'.
* You are not authorized to change Tracking Number
            ENDIF.
* IF tekpo-zzsrmmark <> wa_ekpo_mrcs-zzsrmmark .
* MESSAGE e837(zmm) WITH 'SRM PO Indicator'.
** You are not authorized to change SRM PO Indicator
* ENDIF.

            """""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "comment by lipsy on 4.03.2015 for removing error for deleted ""RD1K995870

* IF <fs_ekpo>-zzsrmmark <> 'X' AND <fs_ekpo>-loekz NE 'X'.
            "ecomment by lipsy on 4.03.2015 for removing error for deleted ""RD1K995870
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

            """"""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "add by lipsy on 4.03.2015 for removing error for deleted ""RD1K995870

            IF <fs_ekpo>-zzzsrmmark <> 'X' AND <fs_ekpo>-loekz NE 'L'.
              "eadd by lipsy on 4.03.2015 for removing error for deleted ""RD1K995870
              """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

              IF <fs_ekpo>-netpr NE lv_netpr AND wa_eban_mrcs-bsart = 'MRCS'.
                MESSAGE e832(zmm) WITH 'Net Price'.
* Invalid Changes in Net Price
              ENDIF.
            ENDIF.

          ENDIF.
        ENDIF.
      ELSE.
        IF wa_eban_mrcs-bsart = 'MRCS'.
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          ""added by lipsy 31.07.2014 for deleted items RD1K994119
          IF <fs_ekpo>-loekz IS NOT INITIAL.
          ELSE.
            ""end of addition by lipsy 31.07.2014 for deleted items RD1K994119
            """"""""""""""""""""""""""""""""""""
            MESSAGE e847(zmm) WITH <fs_ekpo>-banfn. "Invalid line item

            """"""""""""""""""""""""""""""""""""""""""""""""
            ""added by lipsy 31.07.2014 for deleted items RD1K994119
          ENDIF.
          ""end of addition by lipsy 31.07.2014 for deleted items RD1K994119
          """"""""""""""""""""""""""""""""""""""
        ENDIF.
      ENDIF.
    ENDLOOP.

******change by valibhav
*BREAK-POINT.
    IF wa_eban_mrcs-bsart = 'MRCS'.
*Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 11.06.2026

*      DATA wa_konv11 TYPE konv.
      DATA wa_konv11 TYPE prcd_elements.
*Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 11.06.2026
      IF wa_eban_mrcs-zzsrmmark = 'X'.
        LOOP AT item ASSIGNING <fs_item>.
          ls_mepoitem = <fs_item>-item->get_data( ).
          IF ls_mepoitem-zzzsrmmark = 'X'.
* ls_mepoitem = <fs_item>-item->get_data( ).
* IF <fs_ekpo>-zzsrmmark = 'X' OR wa_eban_mrcs-zzsrmmark = 'X'.
* CALL METHOD <fs_item>-item->get_conditions( IMPORTING ex_conditions = tmp_komv ).
            CALL METHOD <fs_item>-item->get_conditions( IMPORTING ex_conditions = tmp_komv ).

            LOOP AT tmp_komv INTO ls_komv WHERE ( kschl = 'PBXX' OR kschl = 'PB00' ) AND updkz = 'U'.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
* SELECT SINGLE * INTO wa_konv11
* FROM V_KONV_CDS
              " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
*                WHERE
*                knumv = ls_komv-knumv
*                AND
*                kposn = ls_komv-kposn
*                AND
*                kschl = 'PBXX'.
*Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 11.06.2026
*              SELECT * INTO wa_konv11
*               FROM konv UP TO 1 ROWS WHERE knumv = ls_komv-knumv AND kposn = ls_komv-kposn AND kschl = 'PBXX'
*               ORDER BY PRIMARY KEY .
*              ENDSELECT.
              SELECT * INTO wa_konv11
 FROM prcd_elements UP TO 1 ROWS WHERE knumv = ls_komv-knumv AND kposn = ls_komv-kposn AND kschl = 'PBXX'
 ORDER BY PRIMARY KEY .
              ENDSELECT.
*Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 11.06.2026
* End of Quick Fix

              IF sy-subrc = 0.
                IF ls_komv-kbetr <> wa_konv11-kbetr.
                  """
                  "ADD BY LIPSY 21.1.2016
                  READ TABLE lt_eban INTO wa_eban_rerror WITH KEY banfn =    ls_mepoitem-banfn
                    bnfpo =    ls_mepoitem-bnfpo.
                  IF  wa_eban_rerror-zzcatalog_price IS NOT INITIAL.
                    IF wa_eban_rerror-zzdiscount IS NOT INITIAL.
                      lv_discount = ( wa_eban_rerror-zzcatalog_price * wa_eban_rerror-zzdiscount ) / 100.
                    ENDIF.

                    IF wa_eban_rerror-zzexcalation IS NOT INITIAL.
                      lv_escalat = ( wa_eban_rerror-zzcatalog_price * wa_eban_rerror-zzexcalation ) / 100.
                    ENDIF.

                    IF wa_eban_rerror-zzcustomduty IS NOT INITIAL .
                      lv_custom = ( wa_eban_rerror-zzcatalog_price * wa_eban_rerror-zzcustomduty ) / 100.
                    ENDIF.
                  ENDIF.

                  lv_base_price = wa_eban_rerror-zzcatalog_price - lv_discount + lv_escalat + lv_custom.

                  IF lv_base_price <> ls_komv-kbetr.

                    "EADD BY LIPSY 21.1.2016
                    """""""""""


                    MESSAGE e832(zmm) WITH 'Net Price'.
                    "
                    """"""""""""""""""""""""""""
                    "ADD BY LIPSY  21.01.2016
                  ENDIF.
                  "EADD BY LIPSY 21.01.2016
                  """"""""""""""""""""""""""""
                  "
                ENDIF.
              ELSE.
                MESSAGE e832(zmm) WITH 'Net Price'.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
**  ENDIF.
  ENDIF.
  CLEAR: wa_eban_mrcs, lv_tabix . ", wa_konv_mrcs.
  IF  ( lv_bdcflag IS INITIAL )
  AND ( sy-tcode = 'ME21N' OR sy-tcode = 'ME21' ).  "#EC CI_USAGE_OK[1803189]
**  IF NOT IT_EBAN_MRCS[] IS INITIAL.
    IF NOT lt_mepoitem[] IS INITIAL.
      SELECT banfn bnfpo matnr bsart bednr repos zzsrmmark
      INTO TABLE it_eban_mrcs
      FROM eban
      FOR ALL ENTRIES IN lt_mepoitem
      WHERE banfn = lt_mepoitem-banfn
*      AND bsart = 'MRCS'
        AND loekz = space.
    ENDIF.

    LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
*  LOOP AT it_eban_mrcs into wa_eban_mrcs.
      lv_tabix = sy-tabix.
      READ TABLE it_eban_mrcs INTO wa_eban_mrcs
*    READ TABLE tekpo
      WITH KEY banfn = <fs_ekpo>-banfn
               bnfpo = <fs_ekpo>-bnfpo.
      IF sy-subrc = 0.
        IF  wa_eban_mrcs-bednr <> <fs_ekpo>-bednr
        AND wa_eban_mrcs-bsart = 'MRCS'.
          MESSAGE e837(zmm) WITH 'Tracking Number'.
*            You are not authorized to change Tracking Number
        ENDIF.
        IF <fs_ekpo>-netpr NE lv_netpr AND wa_eban_mrcs-bsart = 'MRCS'.
          MESSAGE e832(zmm) WITH 'Net Price'.
*            Invalid Changes in Net Price
        ENDIF.
        IF wa_eban_mrcs-matnr <> <fs_ekpo>-matnr
        AND wa_eban_mrcs-bsart = 'MRCS'.
          MESSAGE e837(zmm) WITH 'Material Number'.
*            You are not authorized to change Material Number
        ENDIF.
*      IF <FS_EKPO>-zzsrmmark <> wa_ekpo_mrcs-zzsrmmark .
*        <FS_EKPO>-zzsrmmark = wa_ekpo_mrcs-zzsrmmark.
*        MESSAGE e837(zmm) WITH 'SRM PO Indicator'.
**            You are not authorized to change SRM PO Indicator
*      ENDIF.
      ELSE.
        IF wa_eban_mrcs-bsart = 'MRCS'.
          """""""""""""""""""""""""""""""""""""""""""""""""
          ""added by lipsy 31.07.2014 for deleted items RD1K994119
          IF <fs_ekpo>-loekz IS NOT INITIAL.
          ELSE.
            ""end of addition by lipsy 31.07.2014 for deleted items RD1K994119

            """"""""""""""""""""""""""""""""""""""""""""""

            MESSAGE e847(zmm) WITH <fs_ekpo>-banfn.  "Invalid line item"
            """"""""""""""""""""""""""""""""""""""""""""""""
            ""added by lipsy 31.07.2014 for deleted items RD1K994119
          ENDIF.
          ""end of addition by lipsy 31.07.2014 for deleted items RD1K994119
          """"""""""""""""""""""""""""""""""""""""""""

        ENDIF.
      ENDIF.
      CLEAR: wa_eban_mrcs, wa_ekpo_mrcs.
    ENDLOOP.
**  ENDIF.
  ENDIF.

  CLEAR: lv_bdcflag, lv_tabix.
  SET PARAMETER ID 'SWLXZAP' FIELD lv_bdcflag.

*---addition as per FS-MM-SRV-SIMPLFIED PROCESS dated 08/03/2006----*
*------------- Added by Cab_uniyal on 14-Mar-2006-------------------*
*  DATA : I_EKKO1 TYPE EKKO.
*  DATA : TEKPO1  TYPE EKPO.


  LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.
    IF <fs_ekpo>-werks IS NOT INITIAL.
      " Code Remediation changes S4 2025_1_P Conversion **BEGIN OF CHANGE BY SAP_ABAP 10.06.2026  for ATC
*       MOVE <fs_ekpo>-werks TO w_ekpo.
      MOVE <fs_ekpo>-werks TO w_ekpo.        "#EC CI_FLDEXT_OK[2522971]
      " Code Remediation changes S4 2025_1_P Conversion * *END OF CHANGE BY SAP_ABAP 10.06.2026 for ATC
    ENDIF.
  ENDLOOP.

  IF ( sy-tcode = 'ME21N' OR  sy-tcode = 'ME22N' OR sy-tcode = 'ME23N' OR
         sy-tcode = 'ME21'  OR  sy-tcode = 'ME22'  OR sy-tcode = 'ME23' ).  "#EC CI_USAGE_OK[1803189]

    IF sy-datum >= '20991231' AND ls_mepoheader-konnr <> '' .


* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*      SELECT SINGLE ebeln FROM ekko INTO l_ebeln
*                                  WHERE konnr = ls_mepoheader-konnr
*                                  AND   bsart = 'SWO'
*                                  AND   bedat >= '20991231'
*                                  AND   waers = ls_mepoheader-waers.

      SELECT ebeln FROM ekko INTO l_ebeln UP TO 1 ROWS
       WHERE konnr = ls_mepoheader-konnr AND bsart = 'SWO' AND bedat >= '20991231' AND waers = ls_mepoheader-waers
       ORDER BY PRIMARY KEY .
      ENDSELECT.
* End of Quick Fix


      IF sy-subrc = 0.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*        SELECT SINGLE werks FROM ekpo INTO l_werks
*                                WHERE ebeln = l_ebeln AND loekz  = ''.

        SELECT werks FROM ekpo INTO l_werks UP TO 1 ROWS
         WHERE ebeln = l_ebeln AND loekz = ''
         ORDER BY PRIMARY KEY .
        ENDSELECT.
* End of Quick Fix


        IF sy-subrc = 0 AND l_werks = w_ekpo-werks AND l_ebeln <>
                                                      ls_mepoheader-ebeln.
          MESSAGE e835(zmm) WITH l_ebeln ls_mepoheader-konnr l_werks ls_mepoheader-waers.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


*+SP004 -  PO Validation : Valuation type - FS-MM-PUR-231 Ver 1.1/1.2

  SELECT SINGLE * FROM lfa1 INTO w_lfa1 WHERE lifnr = ls_mepoheader-lifnr.

  l_val_date = '20070301'.

  IF     ( sy-tcode = 'ME21N'    OR
           sy-tcode = 'ME22N'    OR
           sy-tcode = 'ME23N'    OR
********Start of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
    sy-tcode = 'ME29N'    OR
    sy-tcode = 'ME51N'    OR
           sy-tcode = 'ME52N'    OR
           sy-tcode = 'ME53N'    OR
           sy-tcode = 'ME54N'     OR

*****End of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
           sy-tcode = 'ZMMME28' )  AND
         ( ls_mepoheader-bsart = 'MBPM' OR
           ls_mepoheader-bsart = 'MEMI' OR
           ls_mepoheader-bsart = 'MEPI' OR
           ls_mepoheader-bsart = 'MICM' OR
           ls_mepoheader-bsart = 'MIMM' OR
           ls_mepoheader-bsart = 'MPCM' OR
           ls_mepoheader-bsart = 'MPOI' OR
           ls_mepoheader-bsart = 'MPOM' OR
           ls_mepoheader-bsart = 'MSUB' ) AND
           ls_mepoheader-bukrs <> 'OBV'   AND
           ls_mepoheader-aedat > l_val_date.

    LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.

      IF <fs_ekpo>-werks = '90R1'.

        SELECT SINGLE * FROM mara INTO w_mara
                 WHERE matnr = <fs_ekpo>-matnr.

        IF sy-subrc = 0 AND ( w_mara-mtart = 'ZSPR' OR w_mara-mtart = 'ZSTO' ).

          IF w_lfa1-land1 = 'IN'.
            IF <fs_ekpo>-bwtar+2(2) <> 'ID'.
              """"""""""""""""""""""""""""""""""""""""""""""""""
              "add by lipsy on 8.07.2015 RD1K997763
              IF <fs_ekpo>-loekz = ''.
                "end of addition by lipsy on 8.07.2015 RD1K997763
                """"""""""""""""""""""""""""""""""""""""""""""""""
                MESSAGE e199(zmm) WITH <fs_ekpo>-ebelp.

                """""""""""""""""""""""""""""""""""""""""""""""""
                "add by lipsy on 8.07.2015 RD1K997763
              ENDIF.
              "end of addition by lipsy on 8.07.2015 RD1K997763
              """""""""""""""""""""""""""""""""""""""""""""""""""""
            ENDIF.
          ELSE.
            IF <fs_ekpo>-bwtar+2(2) <> 'IM'.
              """""""""""""""""""""""""""""""""""""
              "added by lipsy on 8.07.2015 RD1K997763
              IF <fs_ekpo>-loekz = ''.
                "end of addition by lipsy on 8.07.2015 RD1K997763
                """""""""""""""""""""""""""""""""""""""""""""
                MESSAGE e199(zmm) WITH <fs_ekpo>-ebelp.

                """"""""""""""""""""""""""""""""""""""""""""
                "added by lipsy on 8.07.2015 RD1K997763
              ENDIF.
              "end of addition by lipsy on 8.07.2015 RD1K997763

              """""""""""""""""""""""""""""""""""""""""""""""""""""""
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF. " Bipin
    ENDLOOP.
  ENDIF.






******Start of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
  l_val_date = '20150401'.
  IF     ( sy-tcode = 'ME21N'    OR
          sy-tcode = 'ME22N'    OR
          sy-tcode = 'ME23N'    OR
          sy-tcode = 'ME29N'    OR
          sy-tcode = 'ZMMME28' OR
      sy-tcode = 'ME51N'    OR
          sy-tcode = 'ME52N'    OR
          sy-tcode = 'ME53N'    OR
          sy-tcode = 'ME54N'     )  AND
        ( ls_mepoheader-bsart = 'MBPM' OR
          ls_mepoheader-bsart = 'MEMI' OR
          ls_mepoheader-bsart = 'MPCM' OR
          ls_mepoheader-bsart = 'MPOI' OR
          ls_mepoheader-bsart = 'MPOM' OR
          ls_mepoheader-bsart = 'MSUB' ) AND
          ls_mepoheader-bukrs <> 'OBV'   AND
          ls_mepoheader-aedat > l_val_date.
*    LOOP AT lt_mepoitem ASSIGNING <fs_ekpo>.

    IF <fs_ekpo>-werks = '90R1'.

      IF w_lfa1-land1 <> 'IN'.

        """"""""""""""""""""""""""
        "added by lipsy on 6.05.2015 RD1K997136
        IF <fs_ekpo>-pstyp = '2'.
        ELSE.
          "end of addition by lipsy on 6.05.2015 RD1K997136
          """"""""""""""""""""""""""""""

          MESSAGE e172(zmm_oth) WITH <fs_ekpo>-ebelp.


          """"""""""""""""""""
          "added by lipsy on 6.05.2015 RD1K997136
        ENDIF.
        "end of addition by lipsy on 6.05.2015 RD1K997136

        """"""""""""""""""
      ENDIF.
    ENDIF.
*    ENDLOOP.


  ELSEIF     ( sy-tcode = 'ME21N'    OR
     sy-tcode = 'ME22N'    OR
     sy-tcode = 'ME23N'    OR
     sy-tcode = 'ME29N'    OR
    sy-tcode = 'ME51N'    OR
     sy-tcode = 'ME52N'    OR
     sy-tcode = 'ME53N'    OR
     sy-tcode = 'ME54N'    OR
     sy-tcode = 'ZMMME28' )  AND
   ( ls_mepoheader-bsart = 'MEPI' OR
     ls_mepoheader-bsart = 'MICM' OR
     ls_mepoheader-bsart = 'MIMM' ).

****  Added <fs_ekpo>-werks = '90R1' on 19.09.2016 for OVL
*      IF <fs_ekpo>-werks = '90R1'.
    IF w_lfa1-land1 EQ 'IN' AND   <fs_ekpo>-werks = '90R1'.
      MESSAGE e171(zmm_oth) WITH <fs_ekpo>-ebelp.
    ENDIF.
*      ENDIF.
  ENDIF.





******End of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********



*+SP004 - End


*SET CURSOR FIELD 'EKKO-LIFNR'.

** - IN CASE OF COPY FROM OTHER DOCUMENT STORE REFERENCE DOCUMENT
*  IF NOT I_REKPO-EBELN IS INITIAL
*  AND I_REKPO-EBELN NE I_EKPO-EBELN
*  AND NOT I_EKPO-EBELP IS INITIAL.
** - move corresponding fields to rfq and po
** - For RFQ & PO
*    EKPO_CI-ZZPORT_CON = I_REKPO-ZZPORT_CON.
*    EKPO_CI-ZZULT_CON  = I_REKPO-ZZULT_CON.
*    EKPO_CI-ZZGROUP    = I_REKPO-ZZGROUP.
*    EKPO_CI-ZZPR_ESCLN = I_REKPO-ZZPR_ESCLN.
** Begin of <RD1K963237>
*    EKPO-ZZSRMMARK = I_REKPO-ZZSRMMARK.
** End of <RD1K963237>
*  ENDIF.
** -when creating PO with ref to RFQ
*  IF NOT I_AEKPO-EBELN IS INITIAL
*  AND NOT I_EKPO-EBELP IS INITIAL.
**- to retain the data entered by user after creating PO
**- with ref to RFQ when port consg and ult consg are blank
*    IF EKPO_CI-ZZPORT_CON IS INITIAL.
*      EKPO_CI-ZZPORT_CON = I_AEKPO-ZZPORT_CON.
*    ENDIF.
*    IF EKPO_CI-ZZULT_CON IS INITIAL.
*      EKPO_CI-ZZULT_CON  = I_AEKPO-ZZULT_CON.
*    ENDIF.
*
*  ENDIF.
** - For RFQ and PO
*  EKPO-ZZPORT_CON = EKPO_CI-ZZPORT_CON.
*  EKPO-ZZULT_CON  = EKPO_CI-ZZULT_CON.
*  EKPO-ZZGROUP    = EKPO_CI-ZZGROUP.
*  EKPO-ZZPR_ESCLN = EKPO_CI-ZZPR_ESCLN.
** Begin of <RD1K963237>
*  EKPO-ZZSRMMARK = EKPO_CI-ZZSRMMARK.
** End of <RD1K963237>

**Port Cong.
*    IF NOT I_EKKO-ZZPORT_CON IS INITIAL.
*      EKPO-ZZPORT_CON = I_EKKO-ZZPORT_CON.
*    ENDIF.
**Ulti.Cong.
*    IF NOT I_EKKO-ZZULT_CON IS INITIAL.
*      EKPO-ZZULT_CON = I_EKKO-ZZULT_CON.
*    ENDIF.
*  ENDIF.
*
** Begin of <RD1K963237>

*  Changes by SAB_RAHUL on 25.04.2006
*  fetch SRM PO Indicator
*  break sab_rahul.
*types : begin of ty_srmmark,
*        banfn     like eban-banfn,
*        bnfpo     like eban-bnfpo,
*        zzsrmmark like eban-zzsrmmark,
*        end of ty_srmmark.
*data : wa_srmmark type ty_srmmark.
*it_srmmark type table of ty_srmmark,

*  select single banfn bnfpo zzsrmmark into wa_srmmark
*  from eban where banfn = i_ekpo-banfn
*              and bnfpo = i_ekpo-bnfpo
*              and bsart = 'MRCS'.
*  if sy-subrc = 0.
*    ekpo-zzsrmmark = 'X'.
*  endif.
*  End Changes by SAB_RAHUL on 25.04.2006

  DATA: "LS_MEPOHEADER TYPE MEPOHEADER,
         header TYPE mepoheader.
  ls_mepoheader = im_header->get_data( ).

  IF sy-tcode EQ 'ME29N'.
** Begin of < > on 11-12-09 by Sudhir Sharma
*  or SY-TCODE EQ 'ZMMME28'.
** End of <> on 11-12-09.
    DATA: release TYPE REF TO if_release_state_mm.
    DATA: l_header        TYPE REF TO cl_po_header_handle_mm.
    DATA: rel_codes TYPE merel_t_codes,
          wa_code   TYPE merel_s_code.
    DATA: count TYPE i.
    release ?= im_header.
    l_header ?= im_header.

    l_header->my_cust_firewall_on = mmpur_yes.
*    CASE LS_MEPOHEADER-FRGKE.
*      WHEN 'S'.
*        MOVE SY-UNAME TO LS_MEPOHEADER-ZZPSA.
*        IF LS_MEPOHEADER-ZZRELDATE IS INITIAL.
*          MOVE SY-DATUM TO LS_MEPOHEADER-ZZRELDATE.
*        ENDIF.
*      WHEN 'B'.
*        CLEAR LS_MEPOHEADER-ZZPSA.
*      WHEN OTHERS.
*        CLEAR LS_MEPOHEADER-ZZPSA.
*    ENDCASE.


*        CASE LS_MEPOHEADER-FRGKE.
*      WHEN 'S'.
*      SELECT SINGLE * FROM EKKO INTO TP_EKKO WHERE EBELN = LS_MEPOHEADER-EBELN AND FRGKE = 'S'.
*      IF SY-SUBRC EQ 0.
*        MOVE TP_EKKO-ZZPSA TO LS_MEPOHEADER-ZZPSA.
*        MOVE TP_EKKO-ZZRELDATE TO LS_MEPOHEADER-ZZRELDATE.
*      ENDIF.
*      WHEN 'B'.
*        CLEAR LS_MEPOHEADER-ZZPSA.
*      WHEN OTHERS.
*        CLEAR LS_MEPOHEADER-ZZPSA.
*    ENDCASE.

    rel_codes = release->get_state( ).

    IF ls_mepoheader-frgke = 'S'.
      DESCRIBE TABLE rel_codes LINES count.
      READ TABLE rel_codes INTO wa_code INDEX count.
      MOVE wa_code-rel_code TO ls_mepoheader-zzrelcode.
    ELSEIF  ls_mepoheader-frgke = 'B'.
      CLEAR ls_mepoheader-zzrelcode.
    ENDIF.
    im_header->set_changed( ).
    im_header->set_data( ls_mepoheader ).
  ENDIF.

*+SP005 : Start
  IF sy-tcode = 'ME21N' OR
     sy-tcode = 'ME22N' OR
     sy-tcode = 'ME23N' OR
     sy-tcode = 'ME29N' OR
     sy-tcode = 'ME31K' OR
     sy-tcode = 'ME32K' OR
     sy-tcode = 'ME33K' OR


    """"""""""""""""""
     "added by lipsy on 11.06.2014  CR 30011059
     sy-tcode = 'ME35K' OR
     sy-tcode = 'ZMMME35K' .

    "end of addition by lipsy on 11.06.2014  CR 30011059

    """""""""""""""""""""""""""

    IF ls_mepoheader-bsart = 'SWO'  OR
       ls_mepoheader-bsart = 'MSDM' OR
       ls_mepoheader-bsart = 'MSIM' OR
       ls_mepoheader-bsart = 'MNBM' OR

      """""""""""""""""""""""""""""""""""
      "commented by lipsy on 11.06.2014  CR 30011059
*       ls_mepoheader-bsart = 'MSUM'
       "end of comment by lipsy on 11.06.2014  CR 30011059

      """""""""""""""""""""""""""""""""""""""""
      """""""""""""""""""""""""""""""""""""
        """"""""""""""""""""""""""""
        "added by lipsy on 11.06.2014  CR 30011059

       ls_mepoheader-bsart = 'PMNS' OR
       ls_mepoheader-bsart = 'MCON' OR
       ls_mepoheader-bsart = 'MRNT' OR
       ls_mepoheader-bsart = 'MSUB'." OR
*       ls_mepoheader-bsart = 'MMGM' OR
*       ls_mepoheader-bsart = 'MSGS' .

      "end of addition by lipsy on 11.06.2014  CR 30011059
      """""""""""""""""""""""""""""""""""""""

    ELSE.

      IF ls_mepoheader-zznat_proc IS INITIAL.

        """"""""""""""""""""""""""""
        "added by lipsy on 11.06.2014  CR 30011059

        IF ls_mepoheader-frgzu IS NOT INITIAL.


        ELSE.
          "end of addition by lipsy on 11.06.2014  CR 30011059
          """""""""""""""""""""""""""""""""""""""""

*          MESSAGE E240(ZMM). " Commented by Aparna on 15.10.2024

          """"""""""""""""""""""""""""
          "added by lipsy on 11.06.2014  CR 30011059

        ENDIF.
        "end of addition by lipsy on 11.06.2014  CR 30011059

        """"""""""""""""""""""""""""


      ENDIF.

    ENDIF.

  ENDIF.
*+SP005 : End



* DATA : "lt_shipping TYPE STANDARD TABLE OF ekpv,
*         temp_ekpv TYPE ekpv,
*         wa_ekpv LIKE LINE OF  lt_shipping. "cab_dns.

  """""""""""""" commented by hiren """"""""""""""""
*  wa_ekpv = <fs_item>-item->get_shipping_data( ).
*  APPEND wa_ekpv TO lt_shipping.
  """""""""""""till here """"""""""""""
******************************************************************************************************************************************
* For shipping data check ROUTE feild is not empty for Txn ME22n and Me21n.
******************************************************************************************************************************************
  IF     ( sy-tcode = 'ME21N' OR sy-tcode = 'ME22N' OR sy-tcode = 'ME23N')  AND
                          ( ls_mepoheader-bsart = 'MSDM' ) .
    IF lt_shipping[] IS NOT INITIAL.

      LOOP AT lt_shipping INTO wa_ekpv.
        IF wa_ekpv-route IS INITIAL AND wa_ekpv-vsbed EQ 'X2'.
          READ TABLE lt_mepoitem ASSIGNING <fs_ekpo> WITH KEY ebeln = wa_ekpv-ebeln ebelp = wa_ekpv-ebelp .
          MESSAGE e533(zmm) WITH <fs_ekpo>-ebelp  <fs_ekpo>-matnr.
        ENDIF.
      ENDLOOP.

    ENDIF.
  ENDIF.

  " Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*
*
*
*******Start of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********
  DATA : v_date TYPE char120.
  " Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
  DATA : w_date  TYPE datum,
         w_date1 TYPE char120.

  w_date = ls_mepoheader-aedat.

  IF ls_mepoheader-aedat GT '20150428'.
    IF ls_mepoheader-bedat IS NOT INITIAL.
      IF ls_mepoheader-bedat NE ls_mepoheader-aedat.
        IF ( sy-tcode  = 'ME21N' OR sy-tcode  = 'ME22N' OR sy-tcode  = 'ME23N'
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "commented by lipsy on 12.05.2015 for derelease check removed

*  or  sy-tcode  = 'ME29N'

          "end of comment  by lipsy on 12.05.2015 for derelease check removed
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""

          OR  sy-tcode  = 'ME51N' OR sy-tcode  = 'ME52N' OR  sy-tcode  = 'ME53N' ) AND ls_mepoheader-bedat NE sy-datum   .

          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "added by lipsy on 22.05.2015 for allowing deletion in case of error for date RD1K997320
          CLEAR: v_check_del.
          IF lt_mepoitem[] IS NOT INITIAL.
            v_check_del = 'X'.
          ENDIF.

          LOOP AT lt_mepoitem INTO ls_mepoitem2 WHERE loekz IS INITIAL.
            v_check_del = ''.
          ENDLOOP.

          "end of addition by lipsy on 22.05.2015 for allowing deletion in case of error for date RD1K997320
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""




          CONCATENATE w_date+6(2) w_date+4(2) w_date+0(4) INTO w_date1 SEPARATED BY '.'.
          CONDENSE w_date1.
          CONCATENATE  'Please enter' w_date1 'in the document date field' INTO v_date SEPARATED BY space.

          """"""""""""""""""""""""""""""""""""""""""""""""
          "added by lipsy on 22.05.2015 for allowing deletion in case of error for date RD1K997320
          IF  v_check_del IS NOT INITIAL.

          ELSE.
            "end of addition by lipsy on 22.05.2015 for allowing deletion in case of error for date RD1K997320
            """""""""""""""""""""""""""""""""""""""""""""""""""
            MESSAGE e803(zmm) WITH v_date.

            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
            "added by lipsy on 22.05.2015 for allowing deletion in case of error for date

          ENDIF.

          "end of addition by lipsy on 22.05.2015 for allowing deletion in case of error for date
          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

******End of addition by Anamika on 10.04.2015 RD1K996938 for Changes in the PO for Audi**********


  """""""""""""""""""""""
  "added by lipsy on 9.05.2015  RD1K997136

  LOOP AT  lt_mepoitem INTO ls_mepoitem.

    """""""""""""""""""""""""""""""""""""""""""""
    """""""""""added by lipsy on 18.06.2015  RD1K997583
    CLEAR:v_delvdate.
    CONCATENATE ls_mepoitem-eeind+6(4) ls_mepoitem-eeind+3(2) ls_mepoitem-eeind(2) INTO v_delvdate.
    IF ls_mepoitem-loekz IS INITIAL.

      """"""""""""""""""""""""""""""""""""""""
      "COMMENTED BY LIPSY ON 3.8.2015 RD1K998103
* if ls_mepoheader-frgke ne 'S' .
      "END OF COMMENT BY LIPSY ON 3.8.2015 RD1K998103
      """"""""""""""""""""""""""""""""""""""""""""""

      """"""""""""""""""""""""""""""""""""""""""""""""""
      "ADDED BY LIPSY ON 3.8.2015  RD1K998103
      IF l_frgke NE 'S' .
        IF ls_mepoheader-bedat GT '20150625'.
          "END OF ADDITION BY LIPSY ON 3.8.2015  RD1K998103

          """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

          "end of addition  by lipsy on 18.06.2015  RD1K997583
          """"""""""""""""""""""""""""""""""""""""""""""

          """""""""""""""""""""""""""""""""""""""""""""""
          "commented by lipsy on 18.06.2015  RD1K997583
*if ls_mepoitem-eeind > ls_mepoheader-bedat.

          "end of comment  by lipsy on 18.06.2015  RD1K997583
          """""""""""""""""""""""""""""""""""""""""""""

          """"""""""""""""""""""""""""
          "added by lipsy on 18.06.2015  RD1K997583
          IF v_delvdate < ls_mepoheader-bedat.
            "end of addition by lipsy on 18.06.2015  RD1K997583
            """"""""""""""""""""""""""

            IF ls_mepoheader-bsart = 'MPOI'  OR
              ls_mepoheader-bsart  = 'MBPM'  OR
              ls_mepoheader-bsart  = 'SEM'   OR
              ls_mepoheader-bsart  = 'MEMI'  OR
              ls_mepoheader-bsart  = 'MEPI'  OR
              ls_mepoheader-bsart  = 'MSDM'  OR


              """""""""""""""""""""""""""""""""
              "added by lipsy on 1.04.2016
              ls_mepoheader-bsart  = 'SWO'  OR
                ls_mepoheader-bsart  = 'SNB'  OR
              "eadd by lipsy on 1.04.2016
              """"""""""""""""""""""""""""""""""""
              ls_mepoheader-bsart  = 'MSIM' OR
              """"""""""""""""""""""""""""""""""""""""""
              "added by lipsy on 18.06.2015  RD1K997583
              "added by Rahul Gupta on 09-Sep-2019 Functional Sumit Gangadhare OCDK904008
              ls_mepoheader-bsart  = 'MMGM' OR
              ls_mepoheader-bsart  = 'MMGS'.
              "end of add by Rahul Gupta on 09-Sep-2019 Functional Sumit Gangadhare OCDK904008
            ELSE.
              "end of addition by lipsy on 18.06.2015  RD1K997583
              """""""""""""""""""""""""""""""""""""""""""

              MESSAGE e178(zmm_oth) WITH ls_mepoitem-ebelp .

            ENDIF.

          ENDIF.


          """""""""""""""""""""""""""""""""""""""""""""""""""""""
          """""""""""added by lipsy on 18.06.2015 RD1K997583
          """""""""""""""""""""""""""""""""""""""""
          "ADDED BY LIPSY ON 3.8.2015  RD1K998103

        ENDIF.

        "END OF ADDITION  BY LIPSY ON 3.8.2015  RD1K998103
        """""""""""""""""""""""""""""""""""""""
      ENDIF.
    ENDIF.
    "end of addition  by lipsy on 18.06.2015 RD1K997583

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  ENDLOOP.





  "end of addition by lipsy on 9.05.2015  RD1K997136
  """"""""""""""""""""""""""""""""""""""

  IF sy-tcode = 'ME21N' OR sy-tcode = 'ME22N' OR sy-tcode = 'ME23N' OR sy-tcode = 'ME29N' OR sy-tcode = 'ME28N'.

*    TYPES : BEGIN OF ty_lfa1,
*              lifnr  TYPE lifnr,
*              land1  TYPE land1_gp,
*            END OF ty_lfa1.
*    DATA : lt_t024 TYPE TABLE OF t024,
*           ls_t024 TYPE          t024,
*           ls_lfa1 TYPE          ty_lfa1.

    CLEAR : ls_lfa1 , ls_t024.
    SELECT SINGLE lifnr
           land1 FROM lfa1 INTO ls_lfa1
           WHERE lifnr = ls_mepoheader-lifnr.

    IF sy-subrc = 0.
      SELECT SINGLE * FROM t024 INTO ls_t024
           WHERE ekgrp = ls_mepoheader-ekgrp.

      IF ls_t024-tel_extens  <> ls_lfa1-land1.

        ls_mepoheader-kalsm = 'ZIMP'.

      ELSE.
        ls_mepoheader-kalsm = 'ZIND'.
      ENDIF.
    ENDIF.
    CALL METHOD im_header->set_data( ls_mepoheader ).
  ENDIF.

*{   INSERT         OCPK900104                                        1
  IF sy-tcode EQ 'ME21N' OR sy-tcode EQ 'ME22N' OR sy-tcode EQ 'ME23N' OR sy-tcode EQ 'ME29N'.  "Added OR SY-TCODE EQ 'ME29N' By Rahul Gupta

    IF sy-ucomm EQ 'MESAVE' OR sy-ucomm EQ 'MECHECKDOC'.

      IF ls_mepoheader-bsart EQ 'MMGM' OR ls_mepoheader-bsart EQ 'MMGS'.

* Quick Fix Replace this statement by a SELECT statement with ORDER BY
* 05.06.2026 12:26:48 SAP_ABAP
* Transport OCQK901318 SAP - ATC Correction 01.06.2026
* Replaced Code:
*        SELECT SINGLE * FROM ekko INTO @DATA(ls_gempo)
*         WHERE zgempo EQ  @ls_mepoheader-zgempo
*          AND  ebeln  NE  @ls_mepoheader-ebeln.

        SELECT * FROM ekko INTO @DATA(ls_gempo) UP TO 1 ROWS
         WHERE zgempo EQ @ls_mepoheader-zgempo AND ebeln NE @ls_mepoheader-ebeln
         ORDER BY PRIMARY KEY .
        ENDSELECT.
* End of Quick Fix

        IF sy-subrc = 0.
          MESSAGE e013(zmsg_cls_gem) WITH ls_gempo-ebeln  .
        ENDIF.
      ENDIF.
    ENDIF.
    DATA: gv_stcd3 TYPE lfa1-stcd3,
          gv_msg   TYPE char100,
*          gv_ven   TYPE j_1imovend-ven_class.
          gv_ven   TYPE lfa1-ven_class.


    CLEAR: gv_stcd3.
    SELECT SINGLE stcd3
      INTO gv_stcd3
      FROM lfa1
      WHERE lifnr = ls_mepoheader-lifnr.

    IF gv_stcd3 IS NOT INITIAL.
      CLEAR :gv_ven.
*Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 11.06.2026

*      SELECT SINGLE ven_class
*        INTO gv_ven
*        FROM j_1imovend
*        WHERE lifnr = ls_mepoheader-lifnr.

      SELECT SINGLE ven_class
INTO gv_ven
FROM lfa1
WHERE lifnr = ls_mepoheader-lifnr.
*Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 11.06.2026
      IF gv_ven EQ '0'.
        gv_msg = 'Maintain Vendor as Registered'.
        MESSAGE e206(zmm_oth) WITH  gv_msg.

      ENDIF.

    ELSE.

      CLEAR :gv_ven.
*Code Remediation changes S4 2025 Conversion Begin of change SAP_ABAP and 11.06.2026
*      SELECT SINGLE ven_class
*        INTO gv_ven
*        FROM j_1imovend
*        WHERE lifnr = ls_mepoheader-lifnr.

      SELECT SINGLE ven_class
INTO gv_ven
FROM lfa1
WHERE lifnr = ls_mepoheader-lifnr.
*Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 11.06.2026
      IF gv_ven NE '0'.
**        BOC by ss on 3.9.21
        SELECT SINGLE land1 FROM t001 INTO @DATA(lv_land) WHERE bukrs EQ @ls_mepoheader-bukrs.
        IF lv_land EQ 'IN'.
**        EOC by ss on 3.9.21
          gv_msg = 'Maintain Vendor as Unregistered'.
          MESSAGE e206(zmm_oth) WITH  gv_msg.
        ENDIF.
      ENDIF.
    ENDIF.

*      ENDIF.
*    ENDIF.
  ENDIF.




  IF sy-tcode EQ 'ME21N' OR sy-tcode EQ 'ME22N' OR sy-tcode EQ 'ME23N'.

    DATA: gv_brsch TYPE lfa1-brsch,
          gv_msg1  TYPE char100,
          gv_msg2  TYPE char200.

*   IF SY-UCOMM EQ 'MESAVE' OR SY-UCOMM EQ 'MECHECKDOC'.

    SELECT  * FROM lfa1 INTO TABLE @DATA(lt_data) WHERE lifnr = @ls_mepoheader-lifnr.

    IF lt_data IS NOT INITIAL.
      READ TABLE lt_data INTO DATA(ls_data) INDEX 1.
      IF sy-subrc EQ 0 AND ls_data-brsch = ' ' .
        SELECT SINGLE * FROM setleaf INTO @DATA(t_acc) WHERE setname = 'ZACC_GRP' AND valfrom = @ls_data-ktokk.
        IF t_acc IS INITIAL.
          gv_msg1 = 'Maintain vendor industry type'.
          MESSAGE e261(zmm_oth) WITH gv_msg1.
        ENDIF.
      ENDIF.

    ENDIF.
* ENDIF.
    "**************************************************** SOC BY ROHIT ON 24-03-2025
    SELECT SINGLE * FROM lfa1 INTO @DATA(st_lfa1) WHERE lifnr =  @ls_mepoheader-lifnr.
    IF sy-subrc EQ 0.
      IF st_lfa1-stenr IS INITIAL .

        SELECT SINGLE  brsch , udyog_aadhaar_no FROM zmm_vms_industry INTO @DATA(ls_vms) WHERE
         udyog_aadhaar_no EQ 'X' AND brsch EQ @st_lfa1-brsch.
        IF ls_vms IS NOT INITIAL.
          gv_msg2 = 'Please maintain Udyam/Udyog Aadhaar Number'.
          MESSAGE e261(zmm_oth) WITH gv_msg2.
        ENDIF.

      ENDIF.
      "          MESSAGE 'Please Enter Udyam/Udyog Aadhaar Number' TYPE 'E' .
    ENDIF.
    "**************************************************** EOC BY ROHIT ON 24-03-2025
  ENDIF.





*}   INSERT

* DATA: LS_MEPOHEADER TYPE MEPOHEADER.

*  DATA: LT_MEPOITEM TYPE STANDARD TABLE OF MEPOITEM,
*        LS_MEPOITEM TYPE MEPOITEM.

*  FIELD-SYMBOLS: <FS_EKPO> TYPE MEPOITEM.

*  FIELD-SYMBOLS: <FS_ITEM> TYPE PURCHASE_ORDER_ITEM.

*  DATA: IST_EXTENSION TYPE TABLE OF BAPI_TE_MEPOITEM,
*        LS_EXTENSION TYPE BAPI_TE_MEPOITEM.
*  DATA :  lo_header TYPE REF TO  if_purchase_order_mm.

*
*
*  INCLUDE mm_messages_mac.

*  lo_header = im_item->get_header( ).
*
*  ls_mepoheader = lo_header->get_data( ).
*  ls_mepoitem = im_item->get_data( ).

ENDMETHOD.
