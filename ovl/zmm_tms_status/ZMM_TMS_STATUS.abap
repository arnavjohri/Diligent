***********************************************************************
* Report     : ZMM_TMS_STATUS                                         *
*                                                                     *
* Title      : Tender Monitoring Status                               *
*                                                                     *
* Functional Specification No.: CR 30008847                           *
*                                                                     *
* Author     : S P YADAV                   Date : 11-Feb-2008         *
*                                                                     *
* Login Id   : CAB_SPYADAV                                            *
*                                                                     *
* Desciption : Development of a report which gives the information    *
*              about the number of tender still pending for PO        *
*              at different locations & reson for pending.            *
*              This helps the managament to track the tender's        *
*              current status.                                        *
*                                                                     *
* Transaction Code : ZMMTMSSTATUS                                     *
*                                                                     *
***********************************************************************
* CHANGE HISTORY                                                      *
*                                                                     *
* Mod Date    Changed by    Description                 Chng ID       *
*                                                                     *
* 07.02.2014  CAB_SPYADAV   Changes as per CR No.        001          *
*                           30010328                                  *
*                                                                     *
* 04.07.2014  CAB_SPYADAV   Changes as per CR No.        002          *
*                           30010728                                  *
*                                                                     *
*01.04.2015  CAB_SPYADAV  Changes as per CR No.30012147 <RD1K995870>  *
*                        (lipsy)
***********************************************************************

REPORT  zmm_tms_status.
TYPE-POOLS: slis.
TABLES : zmm_pur_tender_d,

  """"""""""""""""""""""""""""""""""""""""""""
  """"""""""""added by lipsy for doc type and pr no on 27.02.2015 RD1K995870
  ZMM_PUR_TENDER_D_ST,

  """"""""""""end of addition by lipsy for doc type and pr no on 27.02.2015 RD1K995870
  """""""""""""""""""""""""""""""""""""""""""""""""""""
         zmm_tms.

TABLES : t001w,
         syst.

*types : begin of ty_data.   "for excluding fcode from PF status
*        include structure zmm_tms.
*types : NITDATE type ZMM_PUR_TENDER_D-NITDATE,
*        EKGRP type ZMM_PUR_TENDER_D-EKGRP,
*        TNDR_VAL type ZMM_PUR_TENDER_D-TNDR_VAL,
*        BANFN type ZMM_PUR_TENDER_D-BANFN.
*
*types:  end of ty_data.
DATA:lv_diff TYPE i,

lv_no_date TYPE i.

DATA : ist_zmm_tms TYPE STANDARD TABLE OF zmm_tms,
       wa_zmm_tms TYPE zmm_tms.
DATA : ist_zmm_pur_tender_d TYPE STANDARD TABLE OF zmm_pur_tender_d,
      wa_zmm_pur_tender_d TYPE zmm_pur_tender_d.
*data : ist_data type STANDARD TABLE OF ty_data,
*       wa_data type ty_data.

DATA  g_repid LIKE sy-repid VALUE 'ZMM_TMS_STATUS'.


TYPES :  BEGIN OF ty_data.
        INCLUDE STRUCTURE zmm_tms.
TYPES : tdrdt TYPE zmm_pur_tender_d-tdrdt,                  "22052013 by Sudhir Sharma
        tdrsigner TYPE zmm_pur_tender_d-tdrsigner,
        nitdate TYPE zmm_pur_tender_d-nitdate,
        ekgrp TYPE zmm_pur_tender_d-ekgrp,
        tndr_val TYPE zmm_pur_tender_d-tndr_val,
        banfn TYPE zmm_pur_tender_d-banfn.
TYPES : noa_po TYPE vtbbewe-atage. ""(15)  type c."
TYPES : pb_noa TYPE vtbbewe-atage.
TYPES : tbo_pb TYPE vtbbewe-atage.
TYPES : nit_tbo TYPE vtbbewe-atage.
TYPES : ind_nit TYPE vtbbewe-atage.
TYPES : pr_po TYPE vtbbewe-atage.
*types : noa_po(15)  type c. ""type VTBBEWE-ATAGE. ""(15)  type c."
*types : pb_noa(15)  type c."" TYPE VTBBEWE-ATAGE.
*types : tbo_pb(15)  type c."" TYPE VTBBEWE-ATAGE.
*types : nit_tbo(15)  type c."" TYPE VTBBEWE-ATAGE.
*types : ind_nit(15)  type c."" TYPE VTBBEWE-ATAGE.
TYPES : ebeln TYPE eban-ebeln.
TYPES: workdesc TYPE zmm_pur_tender_d_st-workdesc.
TYPES :tcmem(50) TYPE c.
TYPES :podate TYPE ekko-aedat.
TYPES : tdrtxt TYPE zmm_pur_tender_d_st-tdrtxt.
*+001 : Start
TYPES : bsart     TYPE zmm_pur_trtyp-batxt,
        st_sel_dt TYPE zmm_pur_tender_d-st_sel_dt.
*+001 : End
*+001 : End
TYPES : tdrsts   TYPE zmm_pur_tender_d_st-tdrsts,
        tdrstat(20),
        rel_stat_t(20).
*+002 : End
TYPES : END OF ty_data.
DATA :ist_data TYPE STANDARD TABLE OF ty_data,
      wa_data TYPE  ty_data.

CONSTANTS:
gc_formname_top_of_page TYPE slis_formname VALUE 'TOP_OF_PAGE',
gc_formname_end_of_list TYPE slis_formname VALUE 'END_OF_LIST'.

DATA: gs_fieldcat TYPE slis_fieldcat_alv.

DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv,
      gs_print    TYPE slis_print_alv,
      gt_sort     TYPE slis_t_sortinfo_alv,
      gt_sp_group TYPE slis_t_sp_group_alv,
      gt_events   TYPE slis_t_event,
      gt_events1  TYPE slis_t_event,
             ist_listheader TYPE slis_t_listheader,
             wa_listheader  TYPE slis_listheader.

DATA: gt_list_top_of_page TYPE slis_t_listheader.

DATA: gs_keyinfo  TYPE slis_keyinfo_alv.
DATA : wa_fieldcat   TYPE slis_fieldcat_alv,
       wa_events     TYPE slis_alv_event,
       wa_layout     TYPE slis_layout_alv.
* Internal table/Structure - ALV
DATA : ist_listheader1 TYPE slis_t_listheader,
       ist_events2     TYPE slis_alv_event OCCURS 0,
       wa_listheader1  TYPE slis_listheader.

* Internal table - ALV
DATA : ist_fcat       TYPE slis_fieldcat_alv OCCURS 0,
       ist_events1    TYPE slis_alv_event OCCURS 0   ,
       ist_fcat_lst   TYPE slis_fieldcat_alv OCCURS 0.
DATA  g_comma TYPE c VALUE ','.
DATA  g_lines TYPE i.
SELECTION-SCREEN BEGIN OF BLOCK tms
                          WITH FRAME TITLE text-001.

SELECT-OPTIONS : s_submi  FOR zmm_pur_tender_d-submi MATCHCODE OBJECT zmm_pur_submi_h, ""21052013

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""added by lipsy for doc type and pr no on 27.02.2015 RD1K995870
             s_doc  for ZMM_PUR_TENDER_D_ST-BSART MATCHCODE OBJECT ZMM_PURTRTYP_H ,
            s_pr for  ZMM_PUR_TENDER_D-BANFN,

""""""""""""end of addition by lipsy for doc type and pr no on 27.02.2015 RD1K995870
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                 s_tproc  FOR zmm_pur_tender_d-tndr_proc,
                 s_ttyp   FOR zmm_pur_tender_d-tnndr_typ,
                 s_tval   FOR zmm_pur_tender_d-tndr_val,
                 s_indntr FOR zmm_tms-indentor,
 p_wrkdsc FOR zmm_pur_tender_d-workdesc NO-EXTENSION NO INTERVALS.

SELECT-OPTIONS : s_tsign  FOR zmm_pur_tender_d-tdrsigner,
                 s_cpa    FOR zmm_tms-cpa,
                 s_ekgrp  FOR zmm_pur_tender_d-ekgrp,
*                 s_werks  FOR t001w-werks,
*                 s_index  FOR syst-index,
                 s_tdrdt  FOR zmm_pur_tender_d-erfdt.
SELECTION-SCREEN END OF BLOCK tms.

START-OF-SELECTION.

  IF NOT s_cpa[] IS INITIAL OR NOT s_indntr[] IS INITIAL.
    SELECT * FROM zmm_tms
      INTO CORRESPONDING FIELDS OF TABLE ist_zmm_tms
      WHERE submi IN s_submi
      AND indentor IN s_indntr
      AND cpa IN s_cpa.

    IF NOT ist_zmm_tms[] IS INITIAL.
      SELECT * FROM zmm_pur_tender_d
        INTO CORRESPONDING FIELDS OF TABLE ist_zmm_pur_tender_d
      FOR ALL ENTRIES IN ist_zmm_tms
      WHERE submi = ist_zmm_tms-submi
        AND tdrdt IN s_tdrdt
        AND tdrsigner IN s_tsign
        AND ekgrp IN s_ekgrp
        AND tndr_proc IN s_tproc
        AND tnndr_typ IN s_ttyp
  """"""""""""""""""""""""""""""""""""""""""""""""""""""
   """"""""""""added by lipsy for doc type and pr no on 27.02.2015 RD1K995870

      and bsart  in s_doc
       and BANFN in s_pr

  """"""""""""end of addition by lipsy for doc type and pr no on 27.02.2015 RD1K995870
 """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        AND tndr_val IN s_tval .
    ELSE.
      MESSAGE e095(zmm).
    ENDIF.
  ELSE.
    SELECT * FROM zmm_pur_tender_d
      INTO CORRESPONDING FIELDS OF TABLE ist_zmm_pur_tender_d
*    for all entries in ist_zmm_tms
*    where submi = ist_zmm_tms-submi
      WHERE submi IN s_submi
      AND tdrdt IN s_tdrdt
      AND tdrsigner IN s_tsign
      AND ekgrp IN s_ekgrp
      AND tndr_proc IN s_tproc
      AND tnndr_typ IN s_ttyp
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      """"""""""""added by lipsy for doc type and pr no on 27.02.2015 RD1K995870

      and bsart  in s_doc
       and BANFN in s_pr

  """"""""""""end of addition by lipsy for doc type and pr no on 27.02.2015 RD1K995870

      """"""""""""""""""""""""""""""""""""""""""""""""""""
      AND tndr_val IN s_tval
      AND workdesc IN p_wrkdsc.

    IF NOT ist_zmm_pur_tender_d[] IS INITIAL.
      SELECT * FROM zmm_tms
        INTO CORRESPONDING FIELDS OF TABLE ist_zmm_tms
        FOR ALL ENTRIES IN ist_zmm_pur_tender_d
        WHERE submi = ist_zmm_pur_tender_d-submi
        AND indentor IN s_indntr
        AND cpa IN s_cpa.
    ELSE.
      MESSAGE e095(zmm).
    ENDIF.
  ENDIF.
  DATA: g_edays LIKE vtbbewe-atage,
        l_mem(8) TYPE c.
  CLEAR wa_zmm_pur_tender_d.
  LOOP AT ist_zmm_pur_tender_d INTO wa_zmm_pur_tender_d.
    CLEAR wa_data.
    CLEAR wa_zmm_tms.
    IF ( NOT s_indntr-low IS INITIAL OR NOT s_cpa-low IS INITIAL ) .
      READ TABLE ist_zmm_tms INTO wa_zmm_tms
      WITH KEY submi = wa_zmm_pur_tender_d-submi.
      IF sy-subrc = 0 .""and ( s_indntr-low is not initial or s_cpa-low is not initial ) .

        MOVE-CORRESPONDING wa_zmm_pur_tender_d TO wa_data.
      ELSE.
        DELETE ist_zmm_pur_tender_d WHERE submi = wa_zmm_pur_tender_d-submi.
        CONTINUE.
      ENDIF.
    ELSE.
      MOVE-CORRESPONDING wa_zmm_pur_tender_d TO wa_data.
    ENDIF.
*    if ( not s_indntr-low is initial or not s_cpa-low is initial ) .
    CLEAR wa_zmm_tms.
    READ TABLE ist_zmm_tms INTO wa_zmm_tms
    WITH KEY submi = wa_zmm_pur_tender_d-submi.
    IF sy-subrc = 0 .""and ( s_indntr-low is not initial or s_cpa-low is not initial ) .
      MOVE-CORRESPONDING wa_zmm_tms TO wa_data.
      IF NOT wa_zmm_tms-tc_member1_s IS INITIAL.
        CONCATENATE wa_zmm_tms-tc_member1_s '' INTO wa_data-tcmem .
      ELSE.
        IF NOT wa_zmm_tms-tc_member1 IS INITIAL.
          CONCATENATE wa_zmm_tms-tc_member1 '' INTO wa_data-tcmem .
        ENDIF.
      ENDIF.
      SHIFT wa_data-tcmem LEFT DELETING LEADING '0'.
      IF NOT wa_zmm_tms-tc_member2_s IS INITIAL.
        CLEAR l_mem.
        l_mem = wa_zmm_tms-tc_member2_s.
        SHIFT l_mem LEFT DELETING LEADING '0'.
        CONCATENATE wa_data-tcmem l_mem  INTO wa_data-tcmem SEPARATED BY g_comma.
      ELSE.
        IF NOT wa_zmm_tms-tc_member2 IS INITIAL.
          CLEAR l_mem.
          l_mem = wa_zmm_tms-tc_member2.
          SHIFT l_mem LEFT DELETING LEADING '0'.
          CONCATENATE wa_data-tcmem l_mem  INTO wa_data-tcmem SEPARATED BY g_comma.
        ENDIF.
      ENDIF.

      IF NOT wa_zmm_tms-tc_member3_s IS INITIAL.
        CLEAR l_mem.
        l_mem = wa_zmm_tms-tc_member3_s.
        SHIFT l_mem LEFT DELETING LEADING '0'.
        CONCATENATE wa_data-tcmem l_mem  INTO wa_data-tcmem SEPARATED BY g_comma.
      ELSE.
        IF NOT wa_zmm_tms-tc_member3 IS INITIAL.
          CLEAR l_mem.
          l_mem = wa_zmm_tms-tc_member3.
          SHIFT l_mem LEFT DELETING LEADING '0'.
          CONCATENATE wa_data-tcmem l_mem  INTO wa_data-tcmem SEPARATED BY g_comma.
        ENDIF.
      ENDIF.

      IF NOT wa_zmm_tms-tc_member4_s IS INITIAL.
        CLEAR l_mem.
        l_mem = wa_zmm_tms-tc_member4_s.
        SHIFT l_mem LEFT DELETING LEADING '0'.
        CONCATENATE wa_data-tcmem l_mem INTO wa_data-tcmem SEPARATED BY g_comma.
      ELSE.
        IF NOT wa_zmm_tms-tc_member4 IS INITIAL.
          CLEAR l_mem.
          l_mem = wa_zmm_tms-tc_member4.
          SHIFT l_mem LEFT DELETING LEADING '0'.
          CONCATENATE wa_data-tcmem l_mem INTO wa_data-tcmem SEPARATED BY g_comma.
        ENDIF.
      ENDIF.

      IF NOT wa_zmm_tms-tc_member5_s IS INITIAL.
        CLEAR l_mem.
        l_mem = wa_zmm_tms-tc_member5_s.
        SHIFT l_mem LEFT DELETING LEADING '0'.
        CONCATENATE wa_data-tcmem l_mem  INTO wa_data-tcmem SEPARATED BY g_comma.
      ELSE.
        IF NOT wa_zmm_tms-tc_member5 IS INITIAL.
          CLEAR l_mem.
          l_mem = wa_zmm_tms-tc_member5.
          SHIFT l_mem LEFT DELETING LEADING '0'.
          CONCATENATE wa_data-tcmem l_mem  INTO wa_data-tcmem SEPARATED BY g_comma.
        ENDIF.
      ENDIF.
    ENDIF.
*    endif.



    PERFORM cal_diff USING  wa_data-loi_1_act_dt wa_data-po_issue_act_dt
                     CHANGING wa_data-noa_po.""g_EDAYS.
*    wa_data-noa_po = g_EDAYS.
    PERFORM cal_diff USING  wa_data-pr_bid_op_act_dt wa_data-loi_1_act_dt
                     CHANGING wa_data-pb_noa.
*    wa_data-pb_noa = g_EDAYS.
    PERFORM cal_diff USING  wa_data-tend_op_act_dt wa_data-pr_bid_op_act_dt
                   CHANGING wa_data-tbo_pb.
*    wa_data-tbo_pb = g_EDAYS.

*+001 : Start - Calculation of Days from NIT to TBO
    IF wa_data-nitdate IS INITIAL.

      IF wa_data-st_sel_dt IS INITIAL.
        PERFORM cal_diff USING  wa_data-tdrdt wa_data-tend_op_act_dt
                         CHANGING wa_data-nit_tbo.
      ELSE.
        PERFORM cal_diff USING  wa_data-st_sel_dt wa_data-tend_op_act_dt
                   CHANGING wa_data-nit_tbo.
      ENDIF.
    ELSE.
*+001 : End
      PERFORM cal_diff USING  wa_data-nitdate wa_data-tend_op_act_dt
               CHANGING wa_data-nit_tbo.
    ENDIF. "+001

*    wa_data-nit_tbo = g_EDAYS.

*-002 : Start
**+001 : Start - Calculation of Days from Indent to NIT
*    IF wa_data-nitdate IS INITIAL.
*
*      IF wa_data-st_sel_dt IS INITIAL.
*        PERFORM cal_diff USING  wa_data-pr_rcpt_dt wa_data-tdrdt
*                         CHANGING wa_data-ind_nit.
*      ELSE.
*        PERFORM cal_diff USING  wa_data-pr_rcpt_dt wa_data-st_sel_dt
*                         CHANGING wa_data-ind_nit.
*      ENDIF.
*    ELSE.
**+001 : End
*      PERFORM cal_diff USING  wa_data-pr_rcpt_dt wa_data-nitdate
*                       CHANGING wa_data-ind_nit.
*    ENDIF.                                                       "+001
*-002 : End

*    wa_data-nit_tbo = g_EDAYS.
*-002 : Start
*    PERFORM cal_diff USING  wa_data-pr_ff_rel_dt wa_data-po_ff_rel_dt
*                     CHANGING wa_data-pr_po.
*-002 : End
*wa_data-ind_nit = g_EDAYS.

" Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 05.06.2026  FOR ATC
*    SELECT SINGLE ebeln FROM eban
*      INTO wa_data-ebeln
*      WHERE banfn = wa_zmm_pur_tender_d-banfn.
 SELECT EBELN FROM EBAN   UP TO 1 ROWS INTO WA_DATA-EBELN WHERE BANFN =
WA_ZMM_PUR_TENDER_D-BANFN  ORDER BY  BANFN BNFPO .   ENDSELECT.
" Code Remediation changes S4 2025_1_A Conversion * *END OF CHANGE BY SAP_ABAP 05.06.2026 FOR ATC
    SELECT SINGLE aedat FROM ekko
      INTO wa_data-podate
      WHERE ebeln = wa_data-ebeln.

*+001 : Start
    SELECT SINGLE batxt FROM zmm_pur_trtyp INTO wa_data-bsart
         WHERE bsart = wa_data-bsart.
*+001 : End

*+002 : To derive 1st Final PO Release Date : Start
    IF wa_data-po_ff_rel_dt IS INITIAL AND
       NOT wa_data-ebeln IS INITIAL.

      PERFORM read_change_doc IN PROGRAM sapmzmmtms
                              USING 'EINKBELEG'
                                    wa_data-ebeln
                                    'FRGKE'
                              CHANGING wa_data-po_ff_rel_dt.

    ENDIF.

*To derive 1st Final PR Release Date
    IF wa_data-pr_ff_rel_dt IS INITIAL AND
       NOT wa_zmm_pur_tender_d-banfn IS INITIAL.

      PERFORM read_change_doc IN PROGRAM sapmzmmtms
                             USING 'BANF'
                                    wa_zmm_pur_tender_d-banfn
                                    'FRGKZ'
                              CHANGING wa_data-pr_ff_rel_dt.
    ENDIF.

*+002 : Days from PR to PO Release - Start
    PERFORM cal_diff USING  wa_data-pr_ff_rel_dt wa_data-po_ff_rel_dt
                     CHANGING wa_data-pr_po.

* Calculation of Days from Indent to NIT
    IF wa_data-pr_rcpt_dt IS INITIAL.

      IF NOT wa_data-pr_ff_rel_dt IS INITIAL.

        IF NOT wa_data-nitdate IS INITIAL.

          PERFORM cal_diff USING  wa_data-pr_ff_rel_dt wa_data-nitdate
                           CHANGING wa_data-ind_nit.

        ELSEIF NOT wa_data-st_sel_dt IS INITIAL.

          PERFORM cal_diff USING  wa_data-pr_ff_rel_dt wa_data-st_sel_dt
                           CHANGING wa_data-ind_nit.

        ELSEIF NOT wa_data-tdrdt IS INITIAL.

          PERFORM cal_diff USING  wa_data-pr_ff_rel_dt wa_data-tdrdt
                           CHANGING wa_data-ind_nit.

        ENDIF.

      ENDIF.

    ELSE.

      IF NOT wa_data-nitdate IS INITIAL.

        PERFORM cal_diff USING  wa_data-pr_rcpt_dt wa_data-nitdate
                         CHANGING wa_data-ind_nit.

      ELSEIF NOT wa_data-st_sel_dt IS INITIAL.

        PERFORM cal_diff USING  wa_data-pr_rcpt_dt wa_data-st_sel_dt
                         CHANGING wa_data-ind_nit.

      ELSEIF NOT wa_data-tdrdt IS INITIAL.

        PERFORM cal_diff USING  wa_data-pr_rcpt_dt wa_data-tdrdt
                         CHANGING wa_data-ind_nit.

      ENDIF.

    ENDIF.
*+002 : End

* Get Tender Status text
    PERFORM read_text USING    'ZTDRSTS'
                                wa_data-tdrsts
                       CHANGING wa_data-tdrstat.

* Get Tender release status
    IF wa_data-rel_stat = 'X'.
      wa_data-rel_stat_t = text-059.
    ELSE.
      CLEAR wa_data-rel_stat_t.
    ENDIF.
*+002 : End

    APPEND wa_data TO ist_data.

  ENDLOOP.


END-OF-SELECTION.
*  g_repid = sy-repid.
*  PERFORM get_summaries_data.                               "-003
  PERFORM reuse_alv_grid_display.

*&---------------------------------------------------------------------*
*&      Form  REUSE_ALV_GRID_DISPLAY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM reuse_alv_grid_display .
  IF NOT ist_data[] IS INITIAL.
    DESCRIBE TABLE ist_data LINES g_lines.
    PERFORM e01_fieldcat_init  USING gt_fieldcat[].
    PERFORM e05_layout_build USING gs_layout.
    PERFORM e03_eventtab_build USING gt_events[].
    PERFORM e04_comment_build  USING gt_list_top_of_page[].
*  PERFORM e06_t_sort_build   USING gt_sort[].
    PERFORM display_alv_grid.
  ELSE.
    MESSAGE e095(zmm).
  ENDIF.
ENDFORM.                    " REUSE_ALV_GRID_DISPLAY
*&---------------------------------------------------------------------*
*&      Form  E01_FIELDCAT_INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_FIELDCAT[]  text
*----------------------------------------------------------------------*
FORM e01_fieldcat_init USING e01_lt_fieldcat TYPE slis_t_fieldcat_alv.
  CONSTANTS : c_key      VALUE 'X',
              c_no_check VALUE space ,
              c_no_hot   VALUE space,
              c_no_input VALUE ' ',
*BOC By Arnav on 28/10/26
*              c_out      VALUE '0',
              c_out      VALUE space,
*EOC By Arnav on 28/10/26
              c_row_pos1 VALUE  '1',
              c_row_pos2 VALUE  '1'.
  DATA g_col(3) TYPE n.
  REFRESH : gt_fieldcat.
  g_col = 1.
  PERFORM append_fldcat USING 'SUBMI' 'IST_DATA' ' ' c_key text-027 c_no_check 'X' c_no_input c_out g_col '' CHANGING gt_fieldcat.

*+001 : Start
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'BSART' 'IST_DATA' '' '' text-056 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.
*+001 : End
* Begin of <> on 22052013 CR 30009229
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TDRDT' 'IST_DATA' '' '' text-054 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*+002 : Start
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'REL_STAT_T'
                              'IST_DATA'
                               ''
                               ''
                               text-060
                               c_no_check
                               c_no_hot
                               c_no_input
                               c_out g_col
                               ''
                        CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TDRSTAT'
                              'IST_DATA'
                               ''
                               ''
                               text-061
                               c_no_check
                               c_no_hot
                               c_no_input
                               c_out g_col
                               ''
                        CHANGING gt_fieldcat.
*+002 : End

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TDRSIGNER' 'IST_DATA' '' '' text-055 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

* End of  <>
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'WORKDESC' 'IST_DATA' '' '' text-050 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
*-002 : Start
*  PERFORM append_fldcat USING 'BANFN' 'IST_DATA' '' '' text-025 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.
*-002 : End

*+002 : Start
  PERFORM append_fldcat USING 'BANFN'
                              'IST_DATA'
                              ''
                              ''
                              text-025
                              c_no_check
                              'X'
                              c_no_input
                              c_out
                              g_col
                              ''
                          CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'PR_FF_REL_DT'
                              'IST_DATA'
                              ' ' ''
                              text-058
                              c_no_check
                              c_no_hot
                              c_no_input
                              c_out g_col
                              ''
                        CHANGING gt_fieldcat.
*+002 : End

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'PR_RCPT_DT' 'IST_DATA' '' '' text-026 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TNDR_VAL' 'IST_DATA' '' '' text-024 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'INDENTOR' 'IST_DATA' '' '' text-023 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'EKGRP' 'IST_DATA' '' '' text-022 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.


  g_col = g_col + 1.
  PERFORM append_fldcat USING 'CPA' 'IST_DATA' '' '' text-020 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TCMEM' 'IST_DATA' '' '' text-021 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TC_MET_ACT_DT' 'IST_DATA' '' '' text-019 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'NITDATE' 'IST_DATA' '' '' text-018 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

**********added by cab_dns ***************
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TEND_OP_SCH_DT' 'IST_DATA' '' '' text-064 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.
*********end of code by cab_dns 03082015********
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TEND_OP_ACT_DT' 'IST_DATA' '' '' text-015 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TBID_EVAL_ACT_DT' 'IST_DATA' '' '' text-011 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'FTC_RCPT_ACT_DT' 'IST_DATA' '' '' text-012 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.


  g_col = g_col + 1.
  PERFORM append_fldcat USING  'TC1_ACT_DT' 'IST_DATA' '' '' text-007 c_no_check c_no_hot c_no_input c_out  g_col '28' CHANGING gt_fieldcat.

*  *********** added by cab_dns *********
   g_col = g_col + 1.
  PERFORM append_fldcat USING  'PR_BID_OP_SCH_DT' 'IST_DATA' '' '' text-065 c_no_check c_no_hot c_no_input c_out  g_col '28' CHANGING gt_fieldcat.

*  *********** end of code by cab_dns 03082015
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'PR_BID_OP_ACT_DT' 'IST_DATA' '' '' text-005 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING  'CS_VETT_DT' 'IST_DATA' '' '' text-004 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TBID_EVAL_ACT_DT' 'IST_DATA' '' '' text-009 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.


  g_col = g_col + 1.
  PERFORM append_fldcat USING 'CLARIF2_L_ACT_DT' 'IST_DATA' '' '' text-010 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

  g_col = g_col + 1.
  PERFORM append_fldcat USING  'APRV_AWRD_ACT_DT' 'IST_DATA' '' '' text-006 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.


*NOA dt.
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'LOI_1_ACT_DT' 'IST_DATA' '' '' text-036 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*EMD release dt.
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'EMD_REL_SB_DT' 'IST_DATA' '' '' text-035 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.


*PO dt.
  g_col = g_col + 1.
* PERFORM append_fldcat USING 'PODATE' 'IST_DATA' ' ' '' text-033 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat. "-002
*+002 : Start
  PERFORM append_fldcat USING 'PO_FF_REL_DT'
                              'IST_DATA'
                              ' ' ''
                              text-057
                              c_no_check
                              c_no_hot
                              c_no_input
                              c_out g_col
                              ''
                        CHANGING gt_fieldcat.
*+002 : End
*
*PO Agreement No.
  g_col = g_col + 1.
*-002 : Start
*  PERFORM append_fldcat USING 'EBELN' 'IST_DATA' ' ' '' text-034 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.
*-002 : End

*+002 : Start
  PERFORM append_fldcat USING 'EBELN'
                              'IST_DATA'
                              ' '
                              ''
                              text-034
                              c_no_check
                              'X'
                              c_no_input
                              c_out
                              g_col
                              ''
                        CHANGING gt_fieldcat.
*+002 : End

*No. of  days from indent to NIT
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'IND_NIT' 'IST_DATA' ' ' '' text-032 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*No. of  days from NIT to TBO
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'NIT_TBO' 'IST_DATA' ' ' '' text-031 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*No. of  days from TBO to Price Bid opening
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TBO_PB' 'IST_DATA' ' ' '' text-030 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*No. of  days from Price Bid TO PO
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'PB_NOA' 'IST_DATA' ' ' '' text-029 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*No. of  days from NOA TO PO
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'NOA_PO' 'IST_DATA' ' ' '' text-028 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*No. of  days from PR TO PO
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'PR_PO' 'IST_DATA' ' ' '' text-051 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.

*Remarks
  g_col = g_col + 1.
  PERFORM append_fldcat USING 'TDRTXT' 'IST_DATA' ' ' '' text-053 c_no_check c_no_hot c_no_input c_out g_col '' CHANGING gt_fieldcat.
**
**
**
***  g_col = g_col + 1.
***  PERFORM append_fldcat USING 'PR_BID_OP_ACT_DT' 'IST_DATA' ' '
***  '' text-017 c_no_check c_no_hot c_no_input c_out
***  c_row_pos2 g_col '' CHANGING gt_fieldcat.
**
**
***  g_col = g_col + 1.
***  PERFORM append_fldcat USING 'FTC_RCPT_ACT_DT' 'IST_DATA' ' '
***  '' text-021 c_no_check c_no_hot c_no_input c_out
***  c_row_pos2 g_col '' CHANGING gt_fieldcat.

ENDFORM.                    " E01_FIELDCAT_INIT
*&---------------------------------------------------------------------*
*&      Form  E05_LAYOUT_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_LAYOUT  text
*----------------------------------------------------------------------*
FORM e05_layout_build USING e05_ls_layout TYPE slis_layout_alv.

  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.
  gs_layout-detail_popup      = 'X'.
  gs_layout-no_vline          = ' '.
  gs_layout-reprep            = 'X'.
  gs_layout-expand_all        = 'X'.
  gs_layout-no_scrolling      = ''.
ENDFORM.                    " E05_LAYOUT_BUILD
*&---------------------------------------------------------------------*
*&      Form  E03_EVENTTAB_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_EVENTS[]  text
*----------------------------------------------------------------------*
FORM e03_eventtab_build USING e03_lt_events TYPE slis_t_event.
  g_repid = sy-repid.

  wa_events-name = 'USER_COMMAND'.
  wa_events-form =  'PROCESS_USER_COMMAND'.
  APPEND wa_events TO ist_events1.
  CLEAR wa_events.

  wa_events-name = slis_ev_top_of_page.
  wa_events-form =  'TOP_OF_PAGE'.
  APPEND wa_events TO ist_events1.
  CLEAR wa_events.

  wa_events-name = 'USER_COMMAND'.
  wa_events-form =  'PROCESS_USER_COMMAND'.
  APPEND wa_events TO ist_events2.
  CLEAR wa_events.

  wa_events-name = slis_ev_top_of_page.
  wa_events-form =  'TOP_OF_PAGE1'.
  APPEND wa_events TO ist_events2.
  CLEAR wa_events.
*  DATA: ls_event TYPE slis_alv_event.
*
*  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
*    EXPORTING
*      i_list_type = 0
*    IMPORTING
*      et_events   = e03_lt_events.
*  READ TABLE e03_lt_events WITH KEY name =  slis_ev_top_of_page
*                           INTO ls_event.
*  IF sy-subrc = 0.
*    MOVE gc_formname_top_of_page TO ls_event-form.
*    APPEND ls_event TO e03_lt_events.
*    CLEAR: ls_event.
*    ls_event-name = slis_ev_end_of_list.
*    ls_event-form = gc_formname_end_of_list.
*    APPEND ls_event TO e03_lt_events.
*    MOVE 'TOP_OF_PAGE' TO ls_event-form.
*    ls_event-name = slis_ev_top_of_page.
*    APPEND ls_event TO e03_lt_events.
*    MOVE 'END_OF_LIST' TO ls_event-form.
*    ls_event-name = slis_ev_end_of_list .
*    APPEND ls_event TO e03_lt_events.
*  ENDIF.
*
** g_repid = sy-repid.
**
**  wa_events-name = slis_ev_top_of_page.
**  wa_events-form =  'TOP_OF_PAGE'.
**  append wa_events to ist_events.
***  wa_events-name = slis_ev_user_command.
***  wa_events-form = 'USER_COMMAND'.
***  append wa_events to
ENDFORM.                    " E03_EVENTTAB_BUILD
*&---------------------------------------------------------------------*
*&      Form  E04_COMMENT_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_LIST_TOP_OF_PAGE[]  text
*----------------------------------------------------------------------*
FORM e04_comment_build USING e04_lt_top_of_page TYPE slis_t_listheader.
  DATA: ls_line TYPE slis_listheader.
  DATA : l_rptdt LIKE sy-datum,
         l_text(60).

*Report Heading
*  CLEAR ls_line.
*  ls_line-typ  = 'H'.
*  ls_line-info = text-001.
*  APPEND ls_line TO e04_lt_top_of_page.

**Report Date
  CLEAR : ls_line,
          l_rptdt.
  WRITE sy-datum TO l_rptdt DD/MM/YY.
  ls_line-typ  = 'H'.
  ls_line-key  = text-002.
  ls_line-info = text-002.
  APPEND ls_line TO e04_lt_top_of_page.

  CLEAR ls_line.
  ls_line-typ  = 'H'.
  ls_line-info = text-003.
  APPEND ls_line TO e04_lt_top_of_page.
*
** Company Code
*  CLEAR : ls_line,
*          l_text.
*  LOOP AT s_bukrs[] INTO wa_bukrs.
*    READ TABLE lt_butxt INTO wa_butxt WITH KEY bukrs = wa_bukrs-low.
*    CONCATENATE wa_bukrs-low wa_butxt-g_butxt INTO l_text SEPARATED BY space.
*    ls_line-typ  = 'S'.
*    ls_line-key  = text-101.
*    ls_line-info = l_text.
*    APPEND ls_line TO e04_lt_top_of_page.
*  ENDLOOP.
**Verification Category
*  CLEAR : ls_line,
*          l_text.
*  CONCATENATE p_eigkz t097t-eigtx INTO l_text SEPARATED BY space.
*  ls_line-typ  = 'S'.
*  ls_line-key  = text-103.
*  ls_line-info = l_text.
*  APPEND ls_line TO e04_lt_top_of_page.
**Cut Off Amount
*  CLEAR ls_line.
*  ls_line-typ  = 'S'.
*  ls_line-key  = text-118.
*  ls_line-info = p_kansw1.
*  APPEND ls_line TO e04_lt_top_of_page.
*
*  CLEAR ls_line.
*  ls_line-typ  = 'S'.
*  ls_line-key  = text-119.
*  ls_line-info = p_kansw2.
*  APPEND ls_line TO e04_lt_top_of_page.
*
**Fiscal year
*  CLEAR ls_line.
*  ls_line-typ  = 'S'.
*  ls_line-key  = text-105.
*  ls_line-info = p_gjahr.
*  APPEND ls_line TO e04_lt_top_of_page.
**Report Date
*  CLEAR : ls_line,
*          l_rptdt.
*  WRITE p_repd TO l_rptdt DD/MM/YY.
*  ls_line-typ  = 'S'.
*  ls_line-key  = text-106.
*  ls_line-info = l_rptdt.
*  APPEND ls_line TO e04_lt_top_of_page.
**User Name & Run Date
*  CLEAR : ls_line,
*          l_text.
*  WRITE sy-datum TO l_rptdt DD/MM/YY.
*  CONCATENATE sy-uname l_rptdt INTO l_text SEPARATED BY text-137.
*  ls_line-typ  = 'S'.
*  ls_line-key  = text-111.
*  ls_line-info = l_text.
*  APPEND ls_line TO e04_lt_top_of_page.

ENDFORM.                    " E04_COMMENT_BUILD
*&---------------------------------------------------------------------*
*&      Form  E06_T_SORT_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_SORT[]  text
*----------------------------------------------------------------------*
FORM e06_t_sort_build USING e06_lt_sort TYPE slis_t_sortinfo_alv.
  DATA: ls_sort TYPE slis_sortinfo_alv.

  CLEAR ls_sort.
  ls_sort-fieldname = 'SUBMI'.
  ls_sort-up        = 'X'.
  ls_sort-group     = '*'.
  APPEND ls_sort TO e06_lt_sort.
ENDFORM.                    " E06_T_SORT_BUILD
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_GRID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_grid .
  DATA : l_title TYPE lvc_title.
  g_repid = sy-repid.
  gs_layout-colwidth_optimize = 'X'.
  CONCATENATE text-h01 '' INTO l_title
                                           SEPARATED BY space.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = g_repid
      i_grid_title            = l_title
*     i_callback_top_of_page  = 'TOP-OF-PAGE'
**      i_callback_pf_status_set = 'SET_ALV_STATUS'
*     i_callback_user_command = 'ALV_USER_COMMAND'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat[]
      it_sort                 = gt_sort[]
      it_events               = ist_events1
    TABLES
      t_outtab                = ist_data.
ENDFORM.                    " DISPLAY_ALV_GRID
*&---------------------------------------------------------------------*
*&      Form  alv_user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM alv_user_command USING  r_ucomm LIKE sy-ucomm

              rs_selfield TYPE slis_selfield .

  IF rs_selfield-fieldname = 'SUBMI'.
    CALL TRANSACTION 'ZMMTDR3' AND SKIP FIRST SCREEN .
  ENDIF.


ENDFORM.                    "alv_user_command

*&---------------------------------------------------------------------*
*&      Form  APPEND_FLDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0246   text
*      -->P_0247   text
*      -->P_0248   text
*      -->P_C_KEY  text
*      -->P_TEXT_122  text
*      -->P_C_NO_CHECK  text
*      -->P_C_NO_HOT  text
*      -->P_C_NO_INPUT  text
*      -->P_C_OUT  text
*      -->P_C_ROW_POS2  text
*      -->P_0256   text
*      <--P_GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM append_fldcat USING par_fldname par_tabname


par_reftabname par_key par_seltext par_checkbox par_hotspot par_input
par_no_out par_col_pos par_len
CHANGING pit_fldcat TYPE slis_t_fieldcat_alv.

  CLEAR gs_fieldcat.
  gs_fieldcat-tabname     = par_tabname.
  gs_fieldcat-fieldname   = par_fldname  .
  gs_fieldcat-ref_tabname = par_reftabname.
  gs_fieldcat-key         = par_key .
  gs_fieldcat-seltext_l   = par_seltext.
  gs_fieldcat-checkbox    = par_checkbox.
  gs_fieldcat-hotspot     = par_hotspot .
  gs_fieldcat-input       = par_input.
  gs_fieldcat-no_out      = par_no_out.
  gs_fieldcat-col_pos     = par_col_pos.
  gs_fieldcat-outputlen   = par_len.
  APPEND gs_fieldcat TO pit_fldcat.

ENDFORM.                    " APPEND_FLDCAT

*---------------------------------------------------------------------*
*       FORM top_of_page                                              *
*---------------------------------------------------------------------*
* To set Header with ONGC Logo
*---------------------------------------------------------------------*
FORM top_of_page.
  REFRESH : ist_listheader.

  PERFORM set_top_of_page.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = ist_listheader
      i_logo             = 'ZONGC'.

ENDFORM.                    "top_of_page
*&---------------------------------------------------------------------*
*&      Form  SET_TOP_OF_PAGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_top_of_page .
  DATA: ls_line TYPE slis_listheader.
  DATA : l_rptdt LIKE sy-datum,
         l_text(60).
  DATA : l_txt(80).
  DATA : l_txt2(80).
  DATA : l_dt_low(10),
         l_dt_hg(10).
*Report Heading
*  CLEAR ls_line.
*  ls_line-typ  = 'H'.
*  ls_line-info = text-001.
*  APPEND ls_line TO e04_lt_top_of_page.


  wa_listheader-typ = 'H'.
  wa_listheader-info = text-037.
  APPEND wa_listheader TO ist_listheader.
  CLEAR wa_listheader.

**Report Date
  DATA : l_date(25) TYPE c.
  wa_listheader-typ    = 'H'.
  wa_listheader-info   = text-h01.
  APPEND wa_listheader TO ist_listheader.
  CLEAR : wa_listheader.

  IF NOT  s_submi[] IS INITIAL.
    IF NOT s_submi-low  IS INITIAL AND
              s_submi-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
      CONCATENATE ':' s_submi-low INTO l_txt SEPARATED BY space.

      wa_listheader-key  = text-049.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_submi-low  IS INITIAL AND
                 s_submi-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.

      CONCATENATE ':' s_submi-low 'to' s_submi-high INTO l_txt
                                         SEPARATED BY space.
      wa_listheader-key  = text-049.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.

  IF NOT  s_tproc[] IS INITIAL.
    IF NOT s_tproc-low  IS INITIAL AND
              s_tproc-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
      CONCATENATE ':' s_tproc-low INTO l_txt SEPARATED BY space.

      wa_listheader-key  = text-038.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_tproc-low  IS INITIAL AND
                 s_tproc-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.

      CONCATENATE ':' s_tproc-low 'to' s_tproc-high INTO l_txt
                                         SEPARATED BY space.
      wa_listheader-key  = text-038.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.

  IF NOT  s_ttyp[] IS INITIAL.
    IF NOT s_ttyp-low  IS INITIAL AND
              s_ttyp-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
      CONCATENATE ':' s_ttyp-low INTO l_txt SEPARATED BY space.

      wa_listheader-key  = text-046.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_ttyp-low  IS INITIAL AND
                 s_ttyp-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.

      CONCATENATE ':' s_ttyp-low 'to' s_ttyp-high INTO l_txt
                                         SEPARATED BY space.
      wa_listheader-key  = text-046.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.
*Tender value s_tval
  IF NOT s_tval[] IS INITIAL.
    IF NOT s_tval-low  IS INITIAL AND
              s_tval-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
*      CONCATENATE ':' s_tval-low INTO l_txt SEPARATED BY space.
      l_txt = s_tval-low.
      wa_listheader-key  = text-047.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_tval-low  IS INITIAL AND
                 s_tval-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.
      l_txt = s_tval-low.
      l_txt2 = s_tval-high.
      CONCATENATE ':' l_txt 'to' l_txt2 INTO l_txt
                                         SEPARATED BY space.


      wa_listheader-key  = text-047.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.

*Descof work p_wrkdsc
  IF NOT p_wrkdsc IS INITIAL.
    wa_listheader-typ = 'S'.
    l_txt = p_wrkdsc.
    wa_listheader-key  = text-039.
    wa_listheader-info = l_txt.

    APPEND wa_listheader TO ist_listheader.
    CLEAR wa_listheader.
  ENDIF.

*Signer s_tsign
  IF NOT s_tsign[] IS INITIAL.
    IF NOT s_tsign-low  IS INITIAL AND
              s_tsign-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
*      CONCATENATE ':' s_tval-low INTO l_txt SEPARATED BY space.
      l_txt = s_tsign-low.
      wa_listheader-key  = text-045.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_tsign-low  IS INITIAL AND
                 s_tsign-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.
      l_txt = s_tsign-low.
      l_txt2 = s_tsign-high.
      CONCATENATE ':' l_txt 'to' l_txt2 INTO l_txt
                                         SEPARATED BY space.


      wa_listheader-key  = text-045.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.
*CPA s_cpa

*Indenter s_indntr
  IF NOT s_indntr[] IS INITIAL.
    IF NOT s_indntr-low  IS INITIAL AND
              s_indntr-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
*      CONCATENATE ':' s_tval-low INTO l_txt SEPARATED BY space.
      l_txt = s_indntr-low.
      wa_listheader-key  = text-042.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_indntr-low  IS INITIAL AND
                 s_indntr-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.
      l_txt = s_indntr-low.
      l_txt2 = s_indntr-high.
      CONCATENATE ':' l_txt 'to' l_txt2 INTO l_txt
                                         SEPARATED BY space.


      wa_listheader-key  = text-042.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.

* Purchase group  s_ekgrp
  IF NOT s_ekgrp[] IS INITIAL.
    IF NOT s_ekgrp-low  IS INITIAL AND
              s_ekgrp-high IS INITIAL.

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low INTO l_txt SEPARATED BY space.
*      CONCATENATE ':' s_tval-low INTO l_txt SEPARATED BY space.
      l_txt = s_ekgrp-low.
      wa_listheader-key  = text-041.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_ekgrp-low  IS INITIAL AND
                 s_ekgrp-high IS INITIAL ).

      wa_listheader-typ = 'S'.
*      CONCATENATE text-067 s_ekgrp-low 'to' s_ekgrp-high INTO l_txt
*                                                   SEPARATED BY space.
      l_txt = s_ekgrp-low.
      l_txt2 = s_ekgrp-high.
      CONCATENATE ':' l_txt 'to' l_txt2 INTO l_txt
                                         SEPARATED BY space.


      wa_listheader-key  = text-041.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.

*Tender date
  IF NOT s_tdrdt[] IS INITIAL.

    IF NOT s_tdrdt-low  IS INITIAL AND
           s_tdrdt-high IS INITIAL.

      WRITE s_tdrdt-low TO l_dt_low DD/MM/YYYY.

      wa_listheader-typ = 'S'.

*      CONCATENATE text-069 l_dt_low INTO l_txt SEPARATED BY space.
      CONCATENATE ':' l_dt_low INTO l_txt SEPARATED BY space.

      wa_listheader-key  = text-043.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ELSEIF NOT ( s_tdrdt-low  IS INITIAL AND
                 s_tdrdt-high IS INITIAL ).

      WRITE s_tdrdt-low  TO l_dt_low DD/MM/YYYY.
      WRITE s_tdrdt-high TO l_dt_hg DD/MM/YYYY.

      wa_listheader-typ = 'S'.

      wa_listheader-key  = text-043.

*      CONCATENATE text-069 l_dt_low 'to' l_dt_hg INTO l_txt
*                                                 SEPARATED BY space.
      CONCATENATE ':' l_dt_low 'to' l_dt_hg INTO l_txt
                                    SEPARATED BY space.
      wa_listheader-info = l_txt.

      APPEND wa_listheader TO ist_listheader.
      CLEAR wa_listheader.

    ENDIF.
  ENDIF.

  wa_listheader-typ = 'S'.
  wa_listheader-key  = text-052.
  wa_listheader-info = g_lines.

  APPEND wa_listheader TO ist_listheader.
  CLEAR wa_listheader.
ENDFORM.                    " SET_TOP_OF_PAGE
*&---------------------------------------------------------------------*
*&      Form  CAL_DIFF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_WA_DATA_PO_ISSUE_ACT_DT  text
*      -->P_WA_DATA_LOI_1_ACT_DT  text
*      <--P_LV_DIFF  text
*----------------------------------------------------------------------*
FORM cal_diff  USING    p_wa_data_po_issue_act_dt
                        p_wa_data_loi_1_act_dt
               CHANGING p_lv_diff.
  CLEAR p_lv_diff.
*  clear lv_diff.
*  CALL FUNCTION 'DAYS_BETWEEN_TWO_DATES'
*    EXPORTING
*      i_datum_bis             = P_WA_DATA_LOI_1_ACT_DT
*      i_datum_von             = P_WA_DATA_PO_ISSUE_ACT_DT
*    IMPORTING
*      e_tage                  = lv_diff
*    EXCEPTIONS
*      days_method_not_defined = 1
*      OTHERS                  = 2.
*
**  IF sy-subrc <> 0.
**
**    WRITE:/ 'Error'.
**
**  ELSE.
**
**    WRITE:/ lv_diff.
**
**  ENDIF.
*
*
*
*  if lv_diff < 0.
*
*    lv_diff = lv_diff * -1.
*
*  endif.
*
* lv_no_date = lv_diff.
*
**  lv_no_date = lv_diff - 1.
*P_LV_DIFF = lv_no_date.

  DATA: edays   LIKE vtbbewe-atage,
        emonths LIKE vtbbewe-atage,
        eyears  LIKE vtbbewe-atage.

  CALL FUNCTION 'FIMA_DAYS_AND_MONTHS_AND_YEARS'
    EXPORTING
      i_date_from = p_wa_data_po_issue_act_dt
      i_date_to   = p_wa_data_loi_1_act_dt
    IMPORTING
      e_days      = edays
      e_months    = emonths
      e_years     = eyears.

  p_lv_diff = edays.

ENDFORM.                    " CAL_DIFF

*&---------------------------------------------------------------------*
*&      Form  process_user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_UCOMM    text
*      -->P_SELFIELD text
*----------------------------------------------------------------------*
FORM process_user_command USING p_ucomm     LIKE sy-ucomm
                                p_selfield TYPE slis_selfield.

  DATA : l_f1(5).
  DATA : l_ebeln TYPE ekko-ebeln.

  MOVE p_selfield-fieldname TO l_f1.

  IF l_f1 = text-048 .
    SET PARAMETER ID 'ZTMS' FIELD p_selfield-value.

    CALL TRANSACTION 'ZMMTMSDISP' AND SKIP FIRST SCREEN.

*+002 : Start : hot link PR/PO
  ELSEIF l_f1 = text-062. "Purchase Order

    MOVE p_selfield-value TO l_ebeln.

    IF p_selfield-value+0(1) = '9'. "Contract

      CALL FUNCTION 'ME_DISPLAY_PURCHASE_DOCUMENT'
        EXPORTING
          i_ebeln              = l_ebeln
        EXCEPTIONS
          not_found            = 1
          no_authority         = 2
          invalid_call         = 3
          preview_not_possible = 4
          OTHERS               = 5.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    ELSE.

      SET PARAMETER ID 'BES' FIELD p_selfield-value.

      CALL TRANSACTION 'ME23N'.

    ENDIF.

  ELSEIF l_f1 = text-063.         "Purchase requisition

    SET PARAMETER ID 'BAN' FIELD p_selfield-value.

    CALL TRANSACTION 'ME53N'.

*+002 : End
  ENDIF.
ENDFORM.                    "process_user_command

*&---------------------------------------------------------------------*
*&      Form  READ_TEXT
*&---------------------------------------------------------------------*
*  To domain text
*----------------------------------------------------------------------*
*      -->P_DNAME Domain name
*      -->P_PROC  Domain value
*      <--P_text  Domain text
*----------------------------------------------------------------------*
FORM read_text  USING    p_dname
                         p_proc
                CHANGING p_text.

  DATA : wa_dd07v TYPE dd07v,
         l_value  TYPE dd07l-domvalue_l.

  MOVE p_proc TO l_value.

  CALL FUNCTION 'DD_DOMVALUE_TEXT_GET'
    EXPORTING
      domname  = p_dname
      value    = l_value
      langu    = sy-langu
    IMPORTING
      dd07v_wa = wa_dd07v.

  MOVE wa_dd07v-ddtext TO p_text.

ENDFORM.                    " READ_TEXT
