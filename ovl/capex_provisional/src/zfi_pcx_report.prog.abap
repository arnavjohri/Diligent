*&---------------------------------------------------------------------*
*& Report         : ZFI_PCX_REPORT
*& Title          : Provisional Capex - utilisation reports
*& Project        : OVL                             Module: FI
*& Related FS     : SAP_Automation_Provisional_Capex_Process_-V3.xlsx
*& Author         : Arnav Johri                     Date: 20.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   The tabs of the Provisional Capex workbook, calculated from the
*&   cumulative Capex the Business Units entered with ZFI_PCX_ENTRY:
*&   cumulative by category, cumulative per fortnight, Capex per
*&   fortnight / month / quarter with budget utilisation in USD million
*&   and INR crore, entity roll-up, category-wise INR, inception to date.
*&   All figures are as at the fortnight given on the selection screen.
*&
*& CHANGE HISTORY
*&   20.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zfi_pcx_report.

TYPES: ty_amt  TYPE p LENGTH 8 DECIMALS 2,
       ty_pct  TYPE p LENGTH 6 DECIMALS 2,
       ty_fact TYPE p LENGTH 8 DECIMALS 5,
       ty_name TYPE c LENGTH 30,
       ty_text TYPE c LENGTH 40.

* Capex per fortnight / month / quarter. Fnn = first fortnight of month
* nn of the financial year, Mnn = the full month. The last four fields
* are derived (FORM finish_wide); the amounts between JVTXT and BALBE
* are added up by position in FORM add_wide - keep that order.
TYPES: BEGIN OF ty_wide,
         projid TYPE zfi_pcx_projid,
         projnm TYPE zfi_pcx_projnm,
         jvtxt  TYPE zfi_pcx_jvtxt,
         be     TYPE ty_amt,
         re     TYPE ty_amt,
         f01    TYPE ty_amt,
         m01    TYPE ty_amt,
         f02    TYPE ty_amt,
         m02    TYPE ty_amt,
         f03    TYPE ty_amt,
         m03    TYPE ty_amt,
         q1     TYPE ty_amt,
         f04    TYPE ty_amt,
         m04    TYPE ty_amt,
         f05    TYPE ty_amt,
         m05    TYPE ty_amt,
         f06    TYPE ty_amt,
         m06    TYPE ty_amt,
         q2     TYPE ty_amt,
         f07    TYPE ty_amt,
         m07    TYPE ty_amt,
         f08    TYPE ty_amt,
         m08    TYPE ty_amt,
         f09    TYPE ty_amt,
         m09    TYPE ty_amt,
         q3     TYPE ty_amt,
         f10    TYPE ty_amt,
         m10    TYPE ty_amt,
         f11    TYPE ty_amt,
         m11    TYPE ty_amt,
         f12    TYPE ty_amt,
         m12    TYPE ty_amt,
         q4     TYPE ty_amt,
         ytd    TYPE ty_amt,
         balbe  TYPE ty_amt,
         balre  TYPE ty_amt,
         utlbe  TYPE ty_pct,
         utlre  TYPE ty_pct,
       END OF ty_wide,
       ty_t_wide TYPE STANDARD TABLE OF ty_wide WITH DEFAULT KEY.

TYPES: BEGIN OF ty_cum,
         projid TYPE zfi_pcx_projid,
         projnm TYPE zfi_pcx_projnm,
         jvtxt  TYPE zfi_pcx_jvtxt,
         prior  TYPE ty_amt,
         ewip   TYPE ty_amt,
         dwip   TYPE ty_amt,
         cwip   TYPE ty_amt,
         othcap TYPE ty_amt,
         total  TYPE ty_amt,
         incr   TYPE ty_amt,
       END OF ty_cum.

TYPES: BEGIN OF ty_his,
         projid TYPE zfi_pcx_projid,
         projnm TYPE zfi_pcx_projnm,
         c01    TYPE ty_amt,
         c02    TYPE ty_amt,
         c03    TYPE ty_amt,
         c04    TYPE ty_amt,
         c05    TYPE ty_amt,
         c06    TYPE ty_amt,
         c07    TYPE ty_amt,
         c08    TYPE ty_amt,
         c09    TYPE ty_amt,
         c10    TYPE ty_amt,
         c11    TYPE ty_amt,
         c12    TYPE ty_amt,
         c13    TYPE ty_amt,
         c14    TYPE ty_amt,
         c15    TYPE ty_amt,
         c16    TYPE ty_amt,
         c17    TYPE ty_amt,
         c18    TYPE ty_amt,
         c19    TYPE ty_amt,
         c20    TYPE ty_amt,
         c21    TYPE ty_amt,
         c22    TYPE ty_amt,
         c23    TYPE ty_amt,
         c24    TYPE ty_amt,
       END OF ty_his.

TYPES: BEGIN OF ty_cat,
         projid TYPE zfi_pcx_projid,
         projnm TYPE zfi_pcx_projnm,
         ewip   TYPE ty_amt,
         dwip   TYPE ty_amt,
         cwip   TYPE ty_amt,
         othcap TYPE ty_amt,
         total  TYPE ty_amt,
         ytdinr TYPE ty_amt,
         diff   TYPE ty_amt,
       END OF ty_cat.

TYPES: BEGIN OF ty_itd,
         projid TYPE zfi_pcx_projid,
         projnm TYPE zfi_pcx_projnm,
         itd0   TYPE ty_amt,
         py     TYPE ty_amt,
         opn    TYPE ty_amt,
         q1     TYPE ty_amt,
         q2     TYPE ty_amt,
         q3     TYPE ty_amt,
         q4     TYPE ty_amt,
         ytd    TYPE ty_amt,
         clos   TYPE ty_amt,
       END OF ty_itd.

TYPES: BEGIN OF ty_stat,
         projid  TYPE zfi_pcx_projid,
         projnm  TYPE zfi_pcx_projnm,
         bu      TYPE zfi_pcx_bu,
         entered TYPE c LENGTH 3,
         prior   TYPE ty_amt,
         total   TYPE ty_amt,
         aenam   TYPE aenam,
         aedat   TYPE aedat,
       END OF ty_stat.

TYPES: BEGIN OF ty_col,
         name TYPE ty_name,
         text TYPE ty_text,
       END OF ty_col.

TYPES ty_t_amt TYPE STANDARD TABLE OF ty_amt WITH DEFAULT KEY.

CONSTANTS: gc_total    TYPE zfi_pcx_projnm VALUE 'Total',
           gc_months   TYPE c LENGTH 36 VALUE 'JanFebMarAprMayJunJulAugSepOctNovDec',
*          ASSUMPTION: authorisation object ZFI_PCX (SU21, manual) with
*          fields ZPCX_BU and ACTVT; 03 = display.
           gc_auth_obj TYPE c LENGTH 10 VALUE 'ZFI_PCX',
           gc_act_dis  TYPE c LENGTH 2 VALUE '03'.

DATA: gs_proj   TYPE zfi_pcx_proj,
      gt_proj   TYPE STANDARD TABLE OF zfi_pcx_proj WITH DEFAULT KEY,
      gt_per    TYPE STANDARD TABLE OF zfi_pcx_period WITH DEFAULT KEY,
      gt_cap    TYPE STANDARD TABLE OF zfi_pcx_capex WITH DEFAULT KEY,
      gt_fyp    TYPE STANDARD TABLE OF zfi_pcx_fyproj WITH DEFAULT KEY,
      gs_fy     TYPE zfi_pcx_fy,
      gt_usd    TYPE ty_t_wide,
      gt_inr    TYPE ty_t_wide,
      gt_ent    TYPE ty_t_wide,
      gt_cum    TYPE STANDARD TABLE OF ty_cum WITH DEFAULT KEY,
      gt_his    TYPE STANDARD TABLE OF ty_his WITH DEFAULT KEY,
      gt_cat    TYPE STANDARD TABLE OF ty_cat WITH DEFAULT KEY,
      gt_itd    TYPE STANDARD TABLE OF ty_itd WITH DEFAULT KEY,
      gt_stat   TYPE STANDARD TABLE OF ty_stat WITH DEFAULT KEY,
      gt_col    TYPE STANDARD TABLE OF ty_col WITH DEFAULT KEY,
      gv_fytxt  TYPE c LENGTH 7,
      gv_asat   TYPE i,
      gv_title  TYPE lvc_title.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME.
PARAMETERS: p_gjahr TYPE gjahr OBLIGATORY,
            p_perno TYPE zfi_pcx_perno OBLIGATORY.
SELECT-OPTIONS: s_bu   FOR gs_proj-bu,
                s_proj FOR gs_proj-projid.
SELECTION-SCREEN END OF BLOCK b01.
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME.
PARAMETERS: r_cum  RADIOBUTTON GROUP vw DEFAULT 'X',
            r_his  RADIOBUTTON GROUP vw,
            r_usd  RADIOBUTTON GROUP vw,
            r_inr  RADIOBUTTON GROUP vw,
            r_ent  RADIOBUTTON GROUP vw,
            r_cat  RADIOBUTTON GROUP vw,
            r_itdu RADIOBUTTON GROUP vw,
            r_itdi RADIOBUTTON GROUP vw,
            r_stat RADIOBUTTON GROUP vw.
SELECTION-SCREEN END OF BLOCK b02.

AT SELECTION-SCREEN.
  IF p_perno < 1 OR p_perno > 24.
    MESSAGE 'Fortnight number must be between 01 and 24' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM run.

*&---------------------------------------------------------------------*
*& Form run
*&---------------------------------------------------------------------*
FORM run.
  DATA: lv_ok  TYPE abap_bool,
        lv_fy2 TYPE n LENGTH 2.

  CLEAR: gt_proj, gt_per, gt_cap, gt_fyp, gs_fy, gt_usd, gt_inr, gt_ent,
         gt_cum, gt_his, gt_cat, gt_itd, gt_stat, gt_col.
  lv_fy2   = ( p_gjahr + 1 ) MOD 100.
  gv_fytxt = |{ p_gjahr }-{ lv_fy2 }|.
  gv_asat  = p_perno.

  PERFORM read_data CHANGING lv_ok.
  IF lv_ok = abap_false.
    RETURN.
  ENDIF.
  PERFORM build_base.

  CASE abap_true.
    WHEN r_cum.
      PERFORM view_cum.
    WHEN r_his.
      PERFORM view_his.
    WHEN r_usd.
      PERFORM total_wide CHANGING gt_usd.
      PERFORM cols_wide.
      gv_title = |Capex per period and utilisation, USD million, FY { gv_fytxt }|.
      PERFORM show CHANGING gt_usd.
    WHEN r_inr.
      PERFORM total_wide CHANGING gt_inr.
      PERFORM cols_wide.
      gv_title = |Capex per period and utilisation, INR crore, FY { gv_fytxt }|.
      PERFORM show CHANGING gt_inr.
    WHEN r_ent.
      PERFORM view_ent.
    WHEN r_cat.
      PERFORM view_cat.
    WHEN r_itdu.
      PERFORM view_itd USING abap_false.
    WHEN r_itdi.
      PERFORM view_itd USING abap_true.
    WHEN r_stat.
      PERFORM view_stat.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form read_data
*&---------------------------------------------------------------------*
FORM read_data CHANGING cv_ok TYPE abap_bool.
  DATA: lt_all  TYPE STANDARD TABLE OF zfi_pcx_proj WITH DEFAULT KEY,
        ls_proj TYPE zfi_pcx_proj,
        lv_skip TYPE i.

  cv_ok = abap_false.
  SELECT * FROM zfi_pcx_period
    WHERE gjahr = @p_gjahr
    ORDER BY PRIMARY KEY
    INTO TABLE @gt_per.
  IF lines( gt_per ) <> 24.
    MESSAGE |Calendar of year { p_gjahr } needs 24 fortnights in table ZFI_PCX_PERIOD| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT * FROM zfi_pcx_proj
    WHERE projid IN @s_proj
      AND bu     IN @s_bu
      AND active = @abap_true
    ORDER BY PRIMARY KEY
    INTO TABLE @lt_all.
  LOOP AT lt_all INTO ls_proj.
    AUTHORITY-CHECK OBJECT gc_auth_obj
      ID 'ZPCX_BU' FIELD ls_proj-bu
      ID 'ACTVT'   FIELD gc_act_dis.
    IF sy-subrc = 0.
      APPEND ls_proj TO gt_proj.
    ELSE.
      lv_skip = lv_skip + 1.
    ENDIF.
  ENDLOOP.
  IF gt_proj IS INITIAL.
    IF lv_skip > 0.
      MESSAGE 'No authorisation for the Business Units of the selected projects' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      MESSAGE 'No data found for the given selection' TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
    RETURN.
  ENDIF.
  SORT gt_proj BY sortno projid.
  IF lv_skip > 0.
    MESSAGE |{ lv_skip } project(s) left out: no authorisation for their Business Unit| TYPE 'S'.
  ENDIF.

  SELECT * FROM zfi_pcx_capex
    WHERE gjahr  = @p_gjahr
      AND perno <= @p_perno
      AND projid IN @s_proj
    ORDER BY PRIMARY KEY
    INTO TABLE @gt_cap.
  SORT gt_cap BY projid perno.

  SELECT * FROM zfi_pcx_fyproj
    WHERE gjahr  = @p_gjahr
      AND projid IN @s_proj
    ORDER BY PRIMARY KEY
    INTO TABLE @gt_fyp.

  SELECT SINGLE * FROM zfi_pcx_fy
    WHERE gjahr = @p_gjahr
    INTO @gs_fy.
  IF sy-subrc <> 0.
    CLEAR gs_fy.
  ENDIF.
  cv_ok = abap_true.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form fname - component name such as F03 or C17
*&---------------------------------------------------------------------*
FORM fname USING iv_prefix TYPE clike iv_no TYPE i CHANGING cv_name TYPE ty_name.
* ALIGN = RIGHT is needed for the zero padding (left is the default)
  cv_name = |{ iv_prefix }{ iv_no WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form build_base - per project: cumulative and marginal per fortnight,
*& then the USD and INR period rows, the category row and the history
*&---------------------------------------------------------------------*
FORM build_base.
  DATA: ls_proj  TYPE zfi_pcx_proj,
        ls_cap   TYPE zfi_pcx_capex,
        ls_last  TYPE zfi_pcx_capex,
        ls_fyp   TYPE zfi_pcx_fyproj,
        ls_per   TYPE zfi_pcx_period,
        lt_cum   TYPE ty_t_amt,
        lt_marg  TYPE ty_t_amt,
        lv_cum   TYPE ty_amt,
        lv_prev  TYPE ty_amt,
        lv_marg  TYPE ty_amt,
        lv_m1    TYPE ty_amt,
        lv_m2    TYPE ty_amt,
        lv_r1    TYPE zfi_pcx_ttarate,
        lv_r2    TYPE zfi_pcx_ttarate,
        lv_p     TYPE i,
        lv_pn    TYPE zfi_pcx_perno,
        lv_p1    TYPE i,
        lv_p2    TYPE i,
        lv_i     TYPE i,
        lv_asat  TYPE i,
        lv_name  TYPE ty_name,
        ls_usd   TYPE ty_wide,
        ls_inr   TYPE ty_wide,
        ls_cum   TYPE ty_cum,
        ls_his   TYPE ty_his.
  FIELD-SYMBOLS <lv_amt> TYPE ty_amt.

  lv_asat = gv_asat.
  LOOP AT gt_proj INTO ls_proj.
    CLEAR: lt_cum, lt_marg, ls_last, ls_cum, ls_his, ls_usd, ls_inr, lv_prev, ls_fyp.

*   cumulative total per fortnight; a fortnight without a row carries
*   the last reported figure forward
    DO lv_asat TIMES.
      lv_p  = sy-index.
      lv_pn = lv_p.
      READ TABLE gt_cap INTO ls_cap WITH KEY projid = ls_proj-projid perno = lv_pn BINARY SEARCH.
      IF sy-subrc = 0.
        IF lv_p < lv_asat.
          ls_cum-prior = ls_cap-ewip + ls_cap-dwip + ls_cap-cwip + ls_cap-othcap.
        ENDIF.
        ls_last = ls_cap.
      ENDIF.
      lv_cum  = ls_last-ewip + ls_last-dwip + ls_last-cwip + ls_last-othcap.
      lv_marg = lv_cum - lv_prev.
      APPEND lv_cum  TO lt_cum.
      APPEND lv_marg TO lt_marg.
      lv_prev = lv_cum.
    ENDDO.

*   view: cumulative by category as at the fortnight
    ls_cum-projid = ls_proj-projid.
    ls_cum-projnm = ls_proj-projnm.
    ls_cum-jvtxt  = ls_proj-jvtxt.
    ls_cum-ewip   = ls_last-ewip.
    ls_cum-dwip   = ls_last-dwip.
    ls_cum-cwip   = ls_last-cwip.
    ls_cum-othcap = ls_last-othcap.
    ls_cum-total  = lv_cum.
    ls_cum-incr   = ls_cum-total - ls_cum-prior.
    APPEND ls_cum TO gt_cum.

*   view: cumulative per fortnight
    ls_his-projid = ls_proj-projid.
    ls_his-projnm = ls_proj-projnm.
    LOOP AT lt_cum INTO lv_cum.
      lv_i = sy-tabix.
      PERFORM fname USING 'C' lv_i CHANGING lv_name.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_his TO <lv_amt>.
      IF sy-subrc = 0.
        <lv_amt> = lv_cum.
      ENDIF.
    ENDLOOP.
    APPEND ls_his TO gt_his.

*   views: Capex per period in USD million and INR crore
    READ TABLE gt_fyp INTO ls_fyp WITH KEY projid = ls_proj-projid.
    IF sy-subrc <> 0.
      CLEAR ls_fyp.
    ENDIF.
    ls_usd-projid = ls_proj-projid.
    ls_usd-projnm = ls_proj-projnm.
    ls_usd-jvtxt  = ls_proj-jvtxt.
    ls_usd-be     = ls_fyp-capbe.
    ls_usd-re     = ls_fyp-capre.
    ls_inr-projid = ls_proj-projid.
    ls_inr-projnm = ls_proj-projnm.
    ls_inr-jvtxt  = ls_proj-jvtxt.
*   INR crore = USD million x rate / 10, rounded to 2 decimals
    ls_inr-be     = ls_fyp-capbe * gs_fy-berate / 10.
    ls_inr-re     = ls_fyp-capre * gs_fy-rerate / 10.

    DO 12 TIMES.
      lv_i  = sy-index.
      lv_p1 = 2 * lv_i - 1.
      lv_p2 = 2 * lv_i.
      CLEAR: lv_m1, lv_m2, lv_r1, lv_r2.
      READ TABLE lt_marg INTO lv_m1 INDEX lv_p1.
      IF sy-subrc <> 0.
        CLEAR lv_m1.
      ENDIF.
      READ TABLE lt_marg INTO lv_m2 INDEX lv_p2.
      IF sy-subrc <> 0.
        CLEAR lv_m2.
      ENDIF.
      READ TABLE gt_per INTO ls_per INDEX lv_p1.
      IF sy-subrc = 0.
        lv_r1 = ls_per-ttarate.
      ENDIF.
      READ TABLE gt_per INTO ls_per INDEX lv_p2.
      IF sy-subrc = 0.
        lv_r2 = ls_per-ttarate.
      ENDIF.

      PERFORM fname USING 'F' lv_i CHANGING lv_name.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_usd TO <lv_amt>.
      IF sy-subrc = 0.
        <lv_amt> = lv_m1.
      ENDIF.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_inr TO <lv_amt>.
      IF sy-subrc = 0.
        <lv_amt> = lv_m1 * lv_r1 / 10.
      ENDIF.

      PERFORM fname USING 'M' lv_i CHANGING lv_name.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_usd TO <lv_amt>.
      IF sy-subrc = 0.
        <lv_amt> = lv_m1 + lv_m2.
      ENDIF.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_inr TO <lv_amt>.
      IF sy-subrc = 0.
        IF lv_asat >= lv_p2.
*         full month: month total in USD x monthly rate, as in the workbook
          <lv_amt> = ( lv_m1 + lv_m2 ) * lv_r2 / 10.
        ELSE.
*         ASSUMPTION: as at mid-month the month-to-date column uses the
*         15-day rate, because the monthly rate does not exist yet.
          <lv_amt> = lv_m1 * lv_r1 / 10.
        ENDIF.
      ENDIF.
    ENDDO.
    PERFORM finish_wide CHANGING ls_usd.
    PERFORM finish_wide CHANGING ls_inr.
    APPEND ls_usd TO gt_usd.
    APPEND ls_inr TO gt_inr.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form finish_wide - quarters, year to date, balances, utilisation
*&---------------------------------------------------------------------*
FORM finish_wide CHANGING cs_wide TYPE ty_wide.
  cs_wide-q1    = cs_wide-m01 + cs_wide-m02 + cs_wide-m03.
  cs_wide-q2    = cs_wide-m04 + cs_wide-m05 + cs_wide-m06.
  cs_wide-q3    = cs_wide-m07 + cs_wide-m08 + cs_wide-m09.
  cs_wide-q4    = cs_wide-m10 + cs_wide-m11 + cs_wide-m12.
  cs_wide-ytd   = cs_wide-q1 + cs_wide-q2 + cs_wide-q3 + cs_wide-q4.
  cs_wide-balbe = cs_wide-be - cs_wide-ytd.
  cs_wide-balre = cs_wide-re - cs_wide-ytd.
  CLEAR: cs_wide-utlbe, cs_wide-utlre.
  IF cs_wide-be <> 0.
    cs_wide-utlbe = cs_wide-ytd * 100 / cs_wide-be.
  ENDIF.
  IF cs_wide-re <> 0.
    cs_wide-utlre = cs_wide-ytd * 100 / cs_wide-re.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form add_wide - add the amounts BE .. YTD of one row to another
*&---------------------------------------------------------------------*
FORM add_wide USING is_from TYPE ty_wide CHANGING cs_to TYPE ty_wide.
  DATA: lv_type TYPE c LENGTH 1,
        lv_cnt  TYPE i,
        lv_idx  TYPE i.
  FIELD-SYMBOLS: <lv_from> TYPE ty_amt,
                 <lv_to>   TYPE ty_amt.

  DESCRIBE FIELD is_from TYPE lv_type COMPONENTS lv_cnt.
* components 1-3 are texts, the last four are derived in FINISH_WIDE
  lv_idx = 4.
  WHILE lv_idx <= lv_cnt - 4.
    ASSIGN COMPONENT lv_idx OF STRUCTURE is_from TO <lv_from>.
    ASSIGN COMPONENT lv_idx OF STRUCTURE cs_to   TO <lv_to>.
    <lv_to> = <lv_to> + <lv_from>.
    lv_idx = lv_idx + 1.
  ENDWHILE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form total_wide - total row at the end
*&---------------------------------------------------------------------*
FORM total_wide CHANGING ct_wide TYPE ty_t_wide.
  DATA: ls_tot  TYPE ty_wide,
        ls_wide TYPE ty_wide.

  LOOP AT ct_wide INTO ls_wide.
    PERFORM add_wide USING ls_wide CHANGING ls_tot.
  ENDLOOP.
  ls_tot-projnm = gc_total.
  PERFORM finish_wide CHANGING ls_tot.
  APPEND ls_tot TO ct_wide.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form col - one visible column, in display order
*&---------------------------------------------------------------------*
FORM col USING iv_name TYPE clike iv_text TYPE clike.
  DATA ls_col TYPE ty_col.

  ls_col-name = iv_name.
  ls_col-text = iv_text.
  APPEND ls_col TO gt_col.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form per_text - heading of a fortnight from its cutoff date
*&---------------------------------------------------------------------*
FORM per_text USING iv_perno TYPE i iv_month_only TYPE abap_bool CHANGING cv_text TYPE ty_text.
  DATA: ls_per TYPE zfi_pcx_period,
        lv_off TYPE i,
        lv_mon TYPE c LENGTH 3.

  CLEAR cv_text.
  READ TABLE gt_per INTO ls_per INDEX iv_perno.
  IF sy-subrc <> 0 OR ls_per-cutoff IS INITIAL.
    cv_text = |Fortnight { iv_perno }|.
    RETURN.
  ENDIF.
  lv_off = ( ls_per-cutoff+4(2) - 1 ) * 3.
  lv_mon = gc_months+lv_off(3).
  IF iv_month_only = abap_true.
    cv_text = |{ lv_mon } { ls_per-cutoff(4) }|.
  ELSE.
    cv_text = |{ ls_per-cutoff+6(2) } { lv_mon } { ls_per-cutoff(4) }|.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form cols_wide - column order of the workbook's period tabs
*&---------------------------------------------------------------------*
FORM cols_wide.
  DATA: lv_i    TYPE i,
        lv_p    TYPE i,
        lv_q    TYPE i,
        lv_name TYPE ty_name,
        lv_text TYPE ty_text.

  CLEAR gt_col.
  PERFORM col USING 'PROJID' 'Project'.
  PERFORM col USING 'PROJNM' 'Project Name'.
  PERFORM col USING 'JVTXT'  'JV Code'.
  lv_text = |BE { gv_fytxt }|.
  PERFORM col USING 'BE' lv_text.
  lv_text = |RE { gv_fytxt }|.
  PERFORM col USING 'RE' lv_text.
  DO 12 TIMES.
    lv_i = sy-index.
    lv_p = 2 * lv_i - 1.
    PERFORM fname USING 'F' lv_i CHANGING lv_name.
    PERFORM per_text USING lv_p abap_false CHANGING lv_text.
    PERFORM col USING lv_name lv_text.
    lv_p = 2 * lv_i.
    PERFORM fname USING 'M' lv_i CHANGING lv_name.
    PERFORM per_text USING lv_p abap_true CHANGING lv_text.
    PERFORM col USING lv_name lv_text.
    IF lv_i MOD 3 = 0.
      lv_q    = lv_i / 3.
      lv_name = |Q{ lv_q }|.
      lv_text = |Q{ lv_q } { gv_fytxt }|.
      PERFORM col USING lv_name lv_text.
    ENDIF.
  ENDDO.
  PERFORM per_text USING gv_asat abap_false CHANGING lv_text.
  lv_text = |Capex till { lv_text }|.
  PERFORM col USING 'YTD'   lv_text.
  PERFORM col USING 'BALBE' 'Balance against BE'.
  PERFORM col USING 'BALRE' 'Balance against RE'.
  PERFORM col USING 'UTLBE' '% Utilisation vs BE'.
  PERFORM col USING 'UTLRE' '% Utilisation vs RE'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form view_cum - cumulative Capex by category (workbook Tab 1)
*&---------------------------------------------------------------------*
FORM view_cum.
  DATA: ls_tot  TYPE ty_cum,
        ls_cum  TYPE ty_cum,
        lv_text TYPE ty_text.

  LOOP AT gt_cum INTO ls_cum.
    ls_tot-prior  = ls_tot-prior  + ls_cum-prior.
    ls_tot-ewip   = ls_tot-ewip   + ls_cum-ewip.
    ls_tot-dwip   = ls_tot-dwip   + ls_cum-dwip.
    ls_tot-cwip   = ls_tot-cwip   + ls_cum-cwip.
    ls_tot-othcap = ls_tot-othcap + ls_cum-othcap.
    ls_tot-total  = ls_tot-total  + ls_cum-total.
    ls_tot-incr   = ls_tot-incr   + ls_cum-incr.
  ENDLOOP.
  ls_tot-projnm = gc_total.
  APPEND ls_tot TO gt_cum.

  CLEAR gt_col.
  PERFORM col USING 'PROJID' 'Project'.
  PERFORM col USING 'PROJNM' 'Project Name'.
  PERFORM col USING 'JVTXT'  'JV Code'.
  PERFORM col USING 'PRIOR'  'Prior Reported Capex'.
  PERFORM col USING 'EWIP'   'Cumulative EWIP'.
  PERFORM col USING 'DWIP'   'Cumulative DWIP'.
  PERFORM col USING 'CWIP'   'Cumulative CWIP'.
  PERFORM col USING 'OTHCAP' 'Cumulative Other Capex'.
  PERFORM col USING 'TOTAL'  'Total'.
  PERFORM col USING 'INCR'   'Increase in Fortnight'.
  PERFORM per_text USING gv_asat abap_false CHANGING lv_text.
  gv_title = |Cumulative Capex by category as at { lv_text }, USD million|.
  PERFORM show CHANGING gt_cum.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form view_his - cumulative Capex per fortnight (workbook Tab 2)
*&---------------------------------------------------------------------*
FORM view_his.
  DATA: ls_tot  TYPE ty_his,
        ls_his  TYPE ty_his,
        lv_i    TYPE i,
        lv_name TYPE ty_name,
        lv_text TYPE ty_text.
  FIELD-SYMBOLS: <lv_from> TYPE ty_amt,
                 <lv_to>   TYPE ty_amt.

  CLEAR gt_col.
  PERFORM col USING 'PROJID' 'Project'.
  PERFORM col USING 'PROJNM' 'Project Name'.
  DO gv_asat TIMES.
    lv_i = sy-index.
    PERFORM fname USING 'C' lv_i CHANGING lv_name.
    PERFORM per_text USING lv_i abap_false CHANGING lv_text.
    PERFORM col USING lv_name lv_text.
    LOOP AT gt_his INTO ls_his.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_his TO <lv_from>.
      ASSIGN COMPONENT lv_name OF STRUCTURE ls_tot TO <lv_to>.
      <lv_to> = <lv_to> + <lv_from>.
    ENDLOOP.
  ENDDO.
  ls_tot-projnm = gc_total.
  APPEND ls_tot TO gt_his.
  gv_title = |Cumulative Capex per fortnight, USD million, FY { gv_fytxt }|.
  PERFORM show CHANGING gt_his.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form view_ent - INR Capex rolled up to subsidiaries / JVs (Tab 5)
*&---------------------------------------------------------------------*
FORM view_ent.
  DATA: lt_entm TYPE STANDARD TABLE OF zfi_pcx_ent WITH DEFAULT KEY,
        ls_entm TYPE zfi_pcx_ent,
        ls_proj TYPE zfi_pcx_proj,
        ls_inr  TYPE ty_wide,
        ls_none TYPE ty_wide,
        lv_none TYPE abap_bool,
        lv_tab  TYPE i.
  FIELD-SYMBOLS <ls_ent> TYPE ty_wide.

  SELECT * FROM zfi_pcx_ent
    ORDER BY PRIMARY KEY
    INTO TABLE @lt_entm.
  SORT lt_entm BY sortno entid.
* one row per entity, also when no project belongs to it;
* row n of GT_ENT belongs to row n of LT_ENTM
  LOOP AT lt_entm INTO ls_entm.
    APPEND INITIAL LINE TO gt_ent ASSIGNING <ls_ent>.
    <ls_ent>-projnm = ls_entm-entnm.
  ENDLOOP.

  LOOP AT gt_inr INTO ls_inr.
    READ TABLE gt_proj INTO ls_proj WITH KEY projid = ls_inr-projid.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    READ TABLE lt_entm TRANSPORTING NO FIELDS WITH KEY entid = ls_proj-entid.
    IF sy-subrc = 0.
      lv_tab = sy-tabix.
      READ TABLE gt_ent ASSIGNING <ls_ent> INDEX lv_tab.
      PERFORM add_wide USING ls_inr CHANGING <ls_ent>.
    ELSE.
      PERFORM add_wide USING ls_inr CHANGING ls_none.
      lv_none = abap_true.
    ENDIF.
  ENDLOOP.
  IF lv_none = abap_true.
    ls_none-projnm = 'Projects without entity'.
    APPEND ls_none TO gt_ent.
  ENDIF.
  LOOP AT gt_ent ASSIGNING <ls_ent>.
    PERFORM finish_wide CHANGING <ls_ent>.
  ENDLOOP.
  PERFORM total_wide CHANGING gt_ent.

  PERFORM cols_wide.
  DELETE gt_col WHERE name = 'PROJID' OR name = 'JVTXT'.
  READ TABLE gt_col ASSIGNING FIELD-SYMBOL(<ls_col>) WITH KEY name = 'PROJNM'.
  IF sy-subrc = 0.
    <ls_col>-text = 'Subsidiary / JV'.
  ENDIF.
  gv_title = |Capex contribution by entity, INR crore, FY { gv_fytxt }|.
  PERFORM show CHANGING gt_ent.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form view_cat - cumulative Capex by category in INR crore (Tab 6)
*&---------------------------------------------------------------------*
FORM view_cat.
  DATA: ls_cum  TYPE ty_cum,
        ls_inr  TYPE ty_wide,
        ls_usd  TYPE ty_wide,
        ls_cat  TYPE ty_cat,
        ls_tot  TYPE ty_cat,
        lv_usd  TYPE ty_amt,
        lv_inr  TYPE ty_amt,
        lv_fact TYPE ty_fact,
        lv_text TYPE ty_text.

* one weighted factor for all projects: INR to date / USD to date
  LOOP AT gt_usd INTO ls_usd.
    lv_usd = lv_usd + ls_usd-ytd.
  ENDLOOP.
  LOOP AT gt_inr INTO ls_inr.
    lv_inr = lv_inr + ls_inr-ytd.
  ENDLOOP.
  IF lv_usd <> 0.
    lv_fact = lv_inr / lv_usd.
  ENDIF.

  LOOP AT gt_cum INTO ls_cum.
    CLEAR: ls_cat, ls_inr.
    READ TABLE gt_inr INTO ls_inr WITH KEY projid = ls_cum-projid.
    IF sy-subrc <> 0.
      CLEAR ls_inr.
    ENDIF.
    ls_cat-projid = ls_cum-projid.
    ls_cat-projnm = ls_cum-projnm.
    ls_cat-ewip   = ls_cum-ewip   * lv_fact.
    ls_cat-dwip   = ls_cum-dwip   * lv_fact.
    ls_cat-cwip   = ls_cum-cwip   * lv_fact.
    ls_cat-othcap = ls_cum-othcap * lv_fact.
    ls_cat-total  = ls_cat-ewip + ls_cat-dwip + ls_cat-cwip + ls_cat-othcap.
    ls_cat-ytdinr = ls_inr-ytd.
    ls_cat-diff   = ls_cat-total - ls_cat-ytdinr.
    APPEND ls_cat TO gt_cat.
    ls_tot-ewip   = ls_tot-ewip   + ls_cat-ewip.
    ls_tot-dwip   = ls_tot-dwip   + ls_cat-dwip.
    ls_tot-cwip   = ls_tot-cwip   + ls_cat-cwip.
    ls_tot-othcap = ls_tot-othcap + ls_cat-othcap.
    ls_tot-total  = ls_tot-total  + ls_cat-total.
    ls_tot-ytdinr = ls_tot-ytdinr + ls_cat-ytdinr.
    ls_tot-diff   = ls_tot-diff   + ls_cat-diff.
  ENDLOOP.
  ls_tot-projnm = gc_total.
  APPEND ls_tot TO gt_cat.

  CLEAR gt_col.
  PERFORM col USING 'PROJID' 'Project'.
  PERFORM col USING 'PROJNM' 'Project Name'.
  PERFORM col USING 'EWIP'   'Cumulative EWIP'.
  PERFORM col USING 'DWIP'   'Cumulative DWIP'.
  PERFORM col USING 'CWIP'   'Cumulative CWIP'.
  PERFORM col USING 'OTHCAP' 'Cumulative Other Capex'.
  PERFORM col USING 'TOTAL'  'Total'.
  PERFORM col USING 'YTDINR' 'Capex to Date (INR)'.
  PERFORM col USING 'DIFF'   'Difference'.
  PERFORM per_text USING gv_asat abap_false CHANGING lv_text.
  gv_title = |Capex by category, INR crore, as at { lv_text }, factor { lv_fact }|.
  PERFORM show CHANGING gt_cat.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form view_itd - inception to date, USD (Tab 8) or INR (Tab 7)
*&---------------------------------------------------------------------*
FORM view_itd USING iv_inr TYPE abap_bool.
  DATA: ls_wide TYPE ty_wide,
        ls_fyp  TYPE zfi_pcx_fyproj,
        ls_itd  TYPE ty_itd,
        ls_tot  TYPE ty_itd,
        lv_y1   TYPE n LENGTH 4,
        lv_text TYPE ty_text.
  FIELD-SYMBOLS <lt_wide> TYPE ty_t_wide.

  IF iv_inr = abap_true.
    ASSIGN gt_inr TO <lt_wide>.
  ELSE.
    ASSIGN gt_usd TO <lt_wide>.
  ENDIF.
  LOOP AT <lt_wide> INTO ls_wide.
    CLEAR: ls_itd, ls_fyp.
    READ TABLE gt_fyp INTO ls_fyp WITH KEY projid = ls_wide-projid.
    IF sy-subrc <> 0.
      CLEAR ls_fyp.
    ENDIF.
    ls_itd-projid = ls_wide-projid.
    ls_itd-projnm = ls_wide-projnm.
    IF iv_inr = abap_true.
      ls_itd-itd0 = ls_fyp-itdinr.
      ls_itd-py   = ls_fyp-pyinr.
    ELSE.
      ls_itd-itd0 = ls_fyp-itdusd.
      ls_itd-py   = ls_fyp-pyusd.
    ENDIF.
    ls_itd-opn  = ls_itd-itd0 + ls_itd-py.
    ls_itd-q1   = ls_wide-q1.
    ls_itd-q2   = ls_wide-q2.
    ls_itd-q3   = ls_wide-q3.
    ls_itd-q4   = ls_wide-q4.
    ls_itd-ytd  = ls_wide-ytd.
    ls_itd-clos = ls_itd-opn + ls_itd-ytd.
    APPEND ls_itd TO gt_itd.
    ls_tot-itd0 = ls_tot-itd0 + ls_itd-itd0.
    ls_tot-py   = ls_tot-py   + ls_itd-py.
    ls_tot-opn  = ls_tot-opn  + ls_itd-opn.
    ls_tot-q1   = ls_tot-q1   + ls_itd-q1.
    ls_tot-q2   = ls_tot-q2   + ls_itd-q2.
    ls_tot-q3   = ls_tot-q3   + ls_itd-q3.
    ls_tot-q4   = ls_tot-q4   + ls_itd-q4.
    ls_tot-ytd  = ls_tot-ytd  + ls_itd-ytd.
    ls_tot-clos = ls_tot-clos + ls_itd-clos.
  ENDLOOP.
  ls_tot-projnm = gc_total.
  APPEND ls_tot TO gt_itd.

  lv_y1 = p_gjahr - 1.
  CLEAR gt_col.
  PERFORM col USING 'PROJID' 'Project'.
  PERFORM col USING 'PROJNM' 'Project Name'.
  lv_text = |Actual ITD 31.03.{ lv_y1 }|.
  PERFORM col USING 'ITD0' lv_text.
  lv_text = |Actual Capex { lv_y1 }-{ p_gjahr+2(2) }|.
  PERFORM col USING 'PY' lv_text.
  lv_text = |Actual ITD 31.03.{ p_gjahr }|.
  PERFORM col USING 'OPN' lv_text.
  lv_text = |Q1 { gv_fytxt }|.
  PERFORM col USING 'Q1' lv_text.
  lv_text = |Q2 { gv_fytxt }|.
  PERFORM col USING 'Q2' lv_text.
  lv_text = |Q3 { gv_fytxt }|.
  PERFORM col USING 'Q3' lv_text.
  lv_text = |Q4 { gv_fytxt }|.
  PERFORM col USING 'Q4' lv_text.
  lv_text = |YTD { gv_fytxt } (Prov.)|.
  PERFORM col USING 'YTD' lv_text.
  PERFORM col USING 'CLOS' 'Total Inception to Date'.
  IF iv_inr = abap_true.
    gv_title = |Capex inception to date, INR crore, FY { gv_fytxt }|.
  ELSE.
    gv_title = |Capex inception to date, USD million, FY { gv_fytxt }|.
  ENDIF.
  PERFORM show CHANGING gt_itd.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form view_stat - who has entered the selected fortnight, who has not
*&---------------------------------------------------------------------*
FORM view_stat.
  DATA: ls_proj TYPE zfi_pcx_proj,
        ls_cap  TYPE zfi_pcx_capex,
        ls_cum  TYPE ty_cum,
        ls_stat TYPE ty_stat,
        lv_pn   TYPE zfi_pcx_perno,
        lv_text TYPE ty_text.

  lv_pn = gv_asat.
  LOOP AT gt_proj INTO ls_proj.
    CLEAR: ls_stat, ls_cum.
    READ TABLE gt_cum INTO ls_cum WITH KEY projid = ls_proj-projid.
    IF sy-subrc <> 0.
      CLEAR ls_cum.
    ENDIF.
    ls_stat-projid = ls_proj-projid.
    ls_stat-projnm = ls_proj-projnm.
    ls_stat-bu     = ls_proj-bu.
    ls_stat-prior  = ls_cum-prior.
    ls_stat-total  = ls_cum-total.
    READ TABLE gt_cap INTO ls_cap WITH KEY projid = ls_proj-projid perno = lv_pn BINARY SEARCH.
    IF sy-subrc = 0.
      ls_stat-entered = 'Yes'.
      ls_stat-aenam   = ls_cap-aenam.
      ls_stat-aedat   = ls_cap-aedat.
    ELSE.
      ls_stat-entered = 'No'.
    ENDIF.
    APPEND ls_stat TO gt_stat.
  ENDLOOP.
* projects still to be entered come first
  SORT gt_stat STABLE BY entered bu.

  CLEAR gt_col.
  PERFORM col USING 'PROJID'  'Project'.
  PERFORM col USING 'PROJNM'  'Project Name'.
  PERFORM col USING 'BU'      'Business Unit'.
  PERFORM col USING 'ENTERED' 'Entered'.
  PERFORM col USING 'PRIOR'   'Prior Reported Capex'.
  PERFORM col USING 'TOTAL'   'Cumulative Capex'.
  PERFORM col USING 'AENAM'   'Entered By'.
  PERFORM col USING 'AEDAT'   'Entered On'.
  PERFORM per_text USING gv_asat abap_false CHANGING lv_text.
  gv_title = |Entry status of the fortnight to { lv_text }|.
  PERFORM show CHANGING gt_stat.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form show - ALV list with the columns of GT_COL, in that order
*&---------------------------------------------------------------------*
FORM show CHANGING ct_tab TYPE STANDARD TABLE.
  DATA: lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table,
        lo_col  TYPE REF TO cl_salv_column,
        lt_ref  TYPE salv_t_column_ref,
        ls_ref  TYPE salv_s_column_ref,
        ls_col  TYPE ty_col,
        lv_name TYPE lvc_fname,
        lv_pos  TYPE i,
        lv_s    TYPE scrtext_s,
        lv_m    TYPE scrtext_m,
        lv_l    TYPE scrtext_l,
        lx_msg  TYPE REF TO cx_salv_msg,
        lx_nf   TYPE REF TO cx_salv_not_found,
        lv_err  TYPE string.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                              CHANGING  t_table      = ct_tab ).
      lo_cols = lo_alv->get_columns( ).
      lt_ref  = lo_cols->get( ).
      LOOP AT lt_ref INTO ls_ref.
        ls_ref-r_column->set_visible( abap_false ).
      ENDLOOP.
      LOOP AT gt_col INTO ls_col.
        lv_pos  = sy-tabix.
        lv_name = ls_col-name.
        lv_s    = ls_col-text.
        lv_m    = ls_col-text.
        lv_l    = ls_col-text.
        lo_col  = lo_cols->get_column( lv_name ).
        lo_col->set_visible( abap_true ).
        lo_col->set_short_text( lv_s ).
        lo_col->set_medium_text( lv_m ).
        lo_col->set_long_text( lv_l ).
        lo_cols->set_column_position( columnname = lv_name position = lv_pos ).
      ENDLOOP.
      lo_cols->set_optimize( abap_true ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_display_settings( )->set_list_header( gv_title ).
      lo_alv->display( ).
    CATCH cx_salv_msg INTO lx_msg.
      lv_err = lx_msg->get_text( ).
      MESSAGE lv_err TYPE 'S' DISPLAY LIKE 'E'.
    CATCH cx_salv_not_found INTO lx_nf.
      lv_err = lx_nf->get_text( ).
      MESSAGE lv_err TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
ENDFORM.
