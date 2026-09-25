*&---------------------------------------------------------------------*
*& Report/Include : ZMM_BP_CREATE_MAIL
*& Title          : Supplier BP creation - daily email notification
*& Project        : KPMG - UDAY / Astral          Module: MM
*& Related FS     : 057_BRD_FS (New BP creation - share a mail with
*&                  background run program), Om Prakash, 28.07.2026
*& Author         : Arnav Johri                   Date: 25.09.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Daily background job. Finds every supplier business partner created
*&   on the selected date (BUT000-CRDAT, BU_GROUP in the six supplier
*&   groupings the FS names), reads the supplier master, the BP address
*&   and the two e-mail entries of that address, and sends ONE e-mail
*&   for the whole day listing every new supplier, to
*&     - MDM              (TVARVC ZMM_BP_MAIL_MDM, one or more rows)
*&     - Supplier Manager (ADR6 sequence 004 of the BP address)
*&     - Supplier contact (ADR6 sequence 005 of the BP address)
*&   Foreground run shows a CL_SALV_TABLE log, one row per BP, with the
*&   send result in the list header. Background run writes the same list
*&   to the spool and the send result to the job log.
*&
*&   No includes - single object, paste-only. Text symbols and selection
*&   texts are listed in ZMM_BP_CREATE_MAIL_TEXTS.md and are maintained
*&   by hand after paste (SE38 -> Goto -> Text elements).
*&
*& CHANGE HISTORY
*&   25.09.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
REPORT zmm_bp_create_mail.

TABLES: but000.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_bp,
         partner  TYPE but000-partner,
         bu_group TYPE but000-bu_group,
         crdat    TYPE but000-crdat,
       END OF ty_bp,
       ty_t_bp TYPE STANDARD TABLE OF ty_bp WITH DEFAULT KEY.

TYPES: BEGIN OF ty_lfa1,
         lifnr TYPE lfa1-lifnr,
         name1 TYPE lfa1-name1,
         name2 TYPE lfa1-name2,
         name3 TYPE lfa1-name3,
         name4 TYPE lfa1-name4,
       END OF ty_lfa1,
       ty_t_lfa1 TYPE STANDARD TABLE OF ty_lfa1 WITH DEFAULT KEY.

TYPES: BEGIN OF ty_but020,
         partner    TYPE but020-partner,
         addrnumber TYPE but020-addrnumber,
       END OF ty_but020,
       ty_t_but020 TYPE STANDARD TABLE OF ty_but020 WITH DEFAULT KEY.

TYPES: BEGIN OF ty_adrc,
         addrnumber TYPE adrc-addrnumber,
         street     TYPE adrc-street,
         str_suppl1 TYPE adrc-str_suppl1,
         str_suppl2 TYPE adrc-str_suppl2,
         city2      TYPE adrc-city2,
         post_code1 TYPE adrc-post_code1,
         city1      TYPE adrc-city1,
         region     TYPE adrc-region,
         country    TYPE adrc-country,
       END OF ty_adrc,
       ty_t_adrc TYPE STANDARD TABLE OF ty_adrc WITH DEFAULT KEY.

TYPES: BEGIN OF ty_adr6,
         addrnumber TYPE adr6-addrnumber,
         consnumber TYPE adr6-consnumber,
         smtp_addr  TYPE adr6-smtp_addr,
       END OF ty_adr6,
       ty_t_adr6 TYPE STANDARD TABLE OF ty_adr6 WITH DEFAULT KEY.

TYPES: BEGIN OF ty_t005u,
         land1 TYPE t005u-land1,
         bland TYPE t005u-bland,
         bezei TYPE t005u-bezei,
       END OF ty_t005u,
       ty_t_t005u TYPE STANDARD TABLE OF ty_t005u WITH DEFAULT KEY.

TYPES: BEGIN OF ty_t005t,
         land1 TYPE t005t-land1,
         landx TYPE t005t-landx,
       END OF ty_t005t,
       ty_t_t005t TYPE STANDARD TABLE OF ty_t005t WITH DEFAULT KEY.

" One supplier as it appears in the mail body
TYPES: BEGIN OF ty_det,
         partner    TYPE lfa1-lifnr,
         name       TYPE string,
         street     TYPE adrc-street,
         str_suppl1 TYPE adrc-str_suppl1,
         str_suppl2 TYPE adrc-str_suppl2,
         city2      TYPE adrc-city2,
         post_code1 TYPE adrc-post_code1,
         city1      TYPE adrc-city1,
         region_txt TYPE t005u-bezei,
         cntry_txt  TYPE t005t-landx,
         mgr_mail   TYPE adr6-smtp_addr,
         cont_mail  TYPE adr6-smtp_addr,
       END OF ty_det,
       ty_t_det TYPE STANDARD TABLE OF ty_det WITH DEFAULT KEY.

" One row of the processing log (ALV / spool)
TYPES: BEGIN OF ty_out,
         partner   TYPE but000-partner,
         name1     TYPE lfa1-name1,
         city1     TYPE adrc-city1,
         mgr_mail  TYPE adr6-smtp_addr,
         cont_mail TYPE adr6-smtp_addr,
         status    TYPE c LENGTH 1,
         msg       TYPE bapi_msg,
       END OF ty_out,
       ty_t_out TYPE STANDARD TABLE OF ty_out WITH DEFAULT KEY.

TYPES: ty_t_mail  TYPE STANDARD TABLE OF adr6-smtp_addr WITH DEFAULT KEY,
       ty_t_tvarv TYPE STANDARD TABLE OF tvarvc-low WITH DEFAULT KEY.

*----------------------------------------------------------------------*
* Constants
*----------------------------------------------------------------------*
" BP groupings that identify a supplier BP - hardcoded per FS 057 §2.1
CONSTANTS: gc_grp_zdom TYPE but000-bu_group VALUE 'ZDOM',
           gc_grp_zimp TYPE but000-bu_group VALUE 'ZIMP',
           gc_grp_zrel TYPE but000-bu_group VALUE 'ZREL',
           gc_grp_zotd TYPE but000-bu_group VALUE 'ZOTD',
           gc_grp_zoti TYPE but000-bu_group VALUE 'ZOTI',
           gc_grp_zsub TYPE but000-bu_group VALUE 'ZSUB'.

" ADR6 sequence numbers per FS 057: 4 = supplier manager, 5 = supplier contact
CONSTANTS: gc_cons_mgr  TYPE adr6-consnumber VALUE '004',
           gc_cons_cont TYPE adr6-consnumber VALUE '005'.

" Country / region descriptions in English, per FS 057 (SPRAS = EN)
CONSTANTS: gc_langu TYPE sy-langu VALUE 'E'.

" TVARVC variables (SM30 -> TVARVC / STVARV). MDM address(es): one row
" per recipient. Sender: optional; when blank the job user's own SU01
" address is used by CL_BCS.
CONSTANTS: gc_tvarv_mdm TYPE tvarvc-name VALUE 'ZMM_BP_MAIL_MDM',
           gc_tvarv_snd TYPE tvarvc-name VALUE 'ZMM_BP_MAIL_SENDER'.

CONSTANTS: gc_doc_html TYPE so_obj_tp VALUE 'HTM'.

CONSTANTS: gc_stat_ok   TYPE c LENGTH 1 VALUE 'S',
           gc_stat_warn TYPE c LENGTH 1 VALUE 'W',
           gc_stat_err  TYPE c LENGTH 1 VALUE 'E'.

*----------------------------------------------------------------------*
* Global data
*----------------------------------------------------------------------*
DATA: gt_bp     TYPE ty_t_bp,
      gt_lfa1   TYPE ty_t_lfa1,
      gt_but020 TYPE ty_t_but020,
      gt_adrc   TYPE ty_t_adrc,
      gt_adr6   TYPE ty_t_adr6,
      gt_t005u  TYPE ty_t_t005u,
      gt_t005t  TYPE ty_t_t005t,
      gt_det    TYPE ty_t_det,
      gt_out    TYPE ty_t_out,
      gt_recip  TYPE ty_t_mail.

DATA: gr_crdat TYPE RANGE OF but000-crdat,
      gr_bugrp TYPE RANGE OF but000-bu_group.

DATA: gv_mdm_missing TYPE abap_bool,
      gv_send_result TYPE string.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_crdat FOR but000-crdat.
  PARAMETERS:     p_bgjob AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Events
*----------------------------------------------------------------------*
INITIALIZATION.
  PERFORM build_group_range.

START-OF-SELECTION.
  PERFORM derive_dates.
  PERFORM fetch_bps.

  IF gt_bp IS INITIAL.
    MESSAGE TEXT-m01 TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM fetch_details.
  PERFORM build_records.
  PERFORM collect_recipients.
  PERFORM send_mail.

END-OF-SELECTION.
  PERFORM display_log.

*&---------------------------------------------------------------------*
*& Form BUILD_GROUP_RANGE
*&---------------------------------------------------------------------*
*& The six supplier groupings the FS names, as a range so the SELECT
*& stays a single IN. Hardcoded because FS 057 §2.1 says so.
*&---------------------------------------------------------------------*
FORM build_group_range.

  DATA: ls_grp LIKE LINE OF gr_bugrp.

  CLEAR gr_bugrp.
  ls_grp-sign   = 'I'.
  ls_grp-option = 'EQ'.

  ls_grp-low = gc_grp_zdom. APPEND ls_grp TO gr_bugrp.
  ls_grp-low = gc_grp_zimp. APPEND ls_grp TO gr_bugrp.
  ls_grp-low = gc_grp_zrel. APPEND ls_grp TO gr_bugrp.
  ls_grp-low = gc_grp_zotd. APPEND ls_grp TO gr_bugrp.
  ls_grp-low = gc_grp_zoti. APPEND ls_grp TO gr_bugrp.
  ls_grp-low = gc_grp_zsub. APPEND ls_grp TO gr_bugrp.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DERIVE_DATES
*&---------------------------------------------------------------------*
*& Which creation date(s) to read. Precedence, agreed with functional
*& on 25/09/26: the checkbox decides.
*&   checkbox ticked            -> previous calendar day, whatever is
*&                                 typed in the date range (the job
*&                                 runs at 00:05, so "previous day" is
*&                                 the day the BPs were created)
*&   not ticked, range blank    -> today (manual run)
*&   not ticked, range filled   -> the range as typed
*&---------------------------------------------------------------------*
FORM derive_dates.

  DATA: ls_crdat LIKE LINE OF gr_crdat.

  CLEAR gr_crdat.

  IF p_bgjob = abap_true.
    ls_crdat-sign   = 'I'.
    ls_crdat-option = 'EQ'.
    ls_crdat-low    = sy-datum - 1.
    APPEND ls_crdat TO gr_crdat.
  ELSEIF s_crdat[] IS INITIAL.
    ls_crdat-sign   = 'I'.
    ls_crdat-option = 'EQ'.
    ls_crdat-low    = sy-datum.
    APPEND ls_crdat TO gr_crdat.
  ELSE.
    gr_crdat = s_crdat[].
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FETCH_BPS
*&---------------------------------------------------------------------*
*& Driver: every BP created on the derived date(s) in one of the
*& supplier groupings. BUT000-CRDAT is filled by the BP transaction,
*& by BDC and by the Ariba SLP inbound alike, so one read covers all
*& three creation paths the FS lists.
*&---------------------------------------------------------------------*
FORM fetch_bps.

  CLEAR gt_bp.

  SELECT partner, bu_group, crdat
    FROM but000
    WHERE crdat    IN @gr_crdat
      AND bu_group IN @gr_bugrp
    ORDER BY partner
    INTO TABLE @gt_bp.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FETCH_DETAILS
*&---------------------------------------------------------------------*
*& Supplier master, BP address, address e-mails and the two description
*& tables, each in one FOR ALL ENTRIES read. Every buffer is sorted for
*& the BINARY SEARCH reads in BUILD_RECORDS.
*&---------------------------------------------------------------------*
FORM fetch_details.

  CLEAR: gt_lfa1, gt_but020, gt_adrc, gt_adr6, gt_t005u, gt_t005t.

  " Supplier master. Supplier number = BP number at Astral (confirmed
  " by functional 25/09/26), so LIFNR is read with the PARTNER directly.
  IF gt_bp IS NOT INITIAL.
    SELECT lifnr, name1, name2, name3, name4
      FROM lfa1
      FOR ALL ENTRIES IN @gt_bp
      WHERE lifnr = @gt_bp-partner
      INTO TABLE @gt_lfa1.
    SORT gt_lfa1 BY lifnr.
    DELETE ADJACENT DUPLICATES FROM gt_lfa1 COMPARING lifnr.

    " BP -> address number. Functional confirmed one address per BP;
    " should a second one ever exist the lowest address number is kept.
    SELECT partner, addrnumber
      FROM but020
      FOR ALL ENTRIES IN @gt_bp
      WHERE partner = @gt_bp-partner
      INTO TABLE @gt_but020.
    SORT gt_but020 BY partner addrnumber.
    DELETE ADJACENT DUPLICATES FROM gt_but020 COMPARING partner.
  ENDIF.

  IF gt_but020 IS NOT INITIAL.
    " Postal address, international version only (NATION = space).
    " ADRC is time-dependent (DATE_FROM in the key); one row per
    " address number is kept.
    SELECT addrnumber, street, str_suppl1, str_suppl2, city2,
           post_code1, city1, region, country
      FROM adrc
      FOR ALL ENTRIES IN @gt_but020
      WHERE addrnumber = @gt_but020-addrnumber
        AND nation     = @space
      INTO TABLE @gt_adrc.
    SORT gt_adrc BY addrnumber.
    DELETE ADJACENT DUPLICATES FROM gt_adrc COMPARING addrnumber.

    " E-mail entries 004 and 005 of the organisation address.
    " ASSUMPTION: PERSNUMBER = space restricts the read to the
    " organisation's own e-mails and excludes contact-person e-mails
    " stored under the same address number.
    SELECT addrnumber, consnumber, smtp_addr
      FROM adr6
      FOR ALL ENTRIES IN @gt_but020
      WHERE addrnumber = @gt_but020-addrnumber
        AND persnumber = @space
        AND consnumber IN ( @gc_cons_mgr, @gc_cons_cont )
      INTO TABLE @gt_adr6.
    SORT gt_adr6 BY addrnumber consnumber.
    DELETE ADJACENT DUPLICATES FROM gt_adr6 COMPARING addrnumber consnumber.
  ENDIF.

  IF gt_adrc IS NOT INITIAL.
    " Region description (T005U is keyed by country + region)
    SELECT land1, bland, bezei
      FROM t005u
      FOR ALL ENTRIES IN @gt_adrc
      WHERE spras = @gc_langu
        AND land1 = @gt_adrc-country
        AND bland = @gt_adrc-region
      INTO TABLE @gt_t005u.
    SORT gt_t005u BY land1 bland.
    DELETE ADJACENT DUPLICATES FROM gt_t005u COMPARING land1 bland.

    " Country description
    SELECT land1, landx
      FROM t005t
      FOR ALL ENTRIES IN @gt_adrc
      WHERE spras = @gc_langu
        AND land1 = @gt_adrc-country
      INTO TABLE @gt_t005t.
    SORT gt_t005t BY land1.
    DELETE ADJACENT DUPLICATES FROM gt_t005t COMPARING land1.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_RECORDS
*&---------------------------------------------------------------------*
*& One GT_DET row per supplier for the mail body and one GT_OUT row per
*& BP for the log. A BP with no LFA1 row (supplier role not yet
*& assigned) is logged and left out of the mail; a BP with a missing
*& address or e-mail is logged as a warning and still goes into the
*& mail with the fields it has.
*&---------------------------------------------------------------------*
FORM build_records.

  DATA: ls_bp     TYPE ty_bp,
        ls_lfa1   TYPE ty_lfa1,
        ls_but020 TYPE ty_but020,
        ls_adrc   TYPE ty_adrc,
        ls_adr6   TYPE ty_adr6,
        ls_t005u  TYPE ty_t005u,
        ls_t005t  TYPE ty_t005t,
        ls_det    TYPE ty_det,
        ls_out    TYPE ty_out.

  CLEAR: gt_det, gt_out.

  LOOP AT gt_bp INTO ls_bp.
    CLEAR: ls_det, ls_out.
    ls_out-partner = ls_bp-partner.
    ls_out-status  = gc_stat_ok.
    ls_out-msg     = TEXT-m10.

    " Supplier master - mandatory for the mail
    READ TABLE gt_lfa1 INTO ls_lfa1
         WITH KEY lifnr = ls_bp-partner BINARY SEARCH.
    IF sy-subrc <> 0.
      " ASSUMPTION: a BP in a supplier grouping but without LFA1 has
      " no supplier account yet, so it is reported, not mailed.
      ls_out-status = gc_stat_warn.
      ls_out-msg    = TEXT-m02.
      APPEND ls_out TO gt_out.
      CONTINUE.
    ENDIF.

    ls_det-partner = ls_lfa1-lifnr.
    ls_det-name    = |{ ls_lfa1-name1 } { ls_lfa1-name2 }|
                  && | { ls_lfa1-name3 } { ls_lfa1-name4 }|.
    CONDENSE ls_det-name.
    ls_out-name1   = ls_lfa1-name1.

    " Address
    READ TABLE gt_but020 INTO ls_but020
         WITH KEY partner = ls_bp-partner BINARY SEARCH.
    IF sy-subrc = 0.
      READ TABLE gt_adrc INTO ls_adrc
           WITH KEY addrnumber = ls_but020-addrnumber BINARY SEARCH.
    ENDIF.
    IF sy-subrc <> 0.
      PERFORM add_warning USING TEXT-m03 CHANGING ls_out.
    ELSE.
      ls_det-street     = ls_adrc-street.
      ls_det-str_suppl1 = ls_adrc-str_suppl1.
      ls_det-str_suppl2 = ls_adrc-str_suppl2.
      ls_det-city2      = ls_adrc-city2.
      ls_det-post_code1 = ls_adrc-post_code1.
      ls_det-city1      = ls_adrc-city1.
      ls_out-city1      = ls_adrc-city1.

      READ TABLE gt_t005u INTO ls_t005u
           WITH KEY land1 = ls_adrc-country
                    bland = ls_adrc-region BINARY SEARCH.
      IF sy-subrc = 0.
        ls_det-region_txt = ls_t005u-bezei.
      ENDIF.

      READ TABLE gt_t005t INTO ls_t005t
           WITH KEY land1 = ls_adrc-country BINARY SEARCH.
      IF sy-subrc = 0.
        ls_det-cntry_txt = ls_t005t-landx.
      ENDIF.

      " Supplier manager e-mail (sequence 004)
      READ TABLE gt_adr6 INTO ls_adr6
           WITH KEY addrnumber = ls_but020-addrnumber
                    consnumber = gc_cons_mgr BINARY SEARCH.
      IF sy-subrc = 0 AND ls_adr6-smtp_addr IS NOT INITIAL.
        ls_det-mgr_mail = ls_adr6-smtp_addr.
        ls_out-mgr_mail = ls_adr6-smtp_addr.
      ELSE.
        PERFORM add_warning USING TEXT-m04 CHANGING ls_out.
      ENDIF.

      " Supplier direct contact e-mail (sequence 005)
      READ TABLE gt_adr6 INTO ls_adr6
           WITH KEY addrnumber = ls_but020-addrnumber
                    consnumber = gc_cons_cont BINARY SEARCH.
      IF sy-subrc = 0 AND ls_adr6-smtp_addr IS NOT INITIAL.
        ls_det-cont_mail = ls_adr6-smtp_addr.
        ls_out-cont_mail = ls_adr6-smtp_addr.
      ELSE.
        PERFORM add_warning USING TEXT-m05 CHANGING ls_out.
      ENDIF.
    ENDIF.

    APPEND ls_det TO gt_det.
    APPEND ls_out TO gt_out.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_WARNING
*&---------------------------------------------------------------------*
*& Downgrade a log row to warning and chain the reason onto any earlier
*& one, so a BP missing both e-mails shows both reasons.
*&---------------------------------------------------------------------*
FORM add_warning USING    iv_text TYPE clike
                 CHANGING cs_out  TYPE ty_out.

  IF cs_out-status = gc_stat_ok.
    cs_out-status = gc_stat_warn.
    cs_out-msg    = iv_text.
  ELSE.
    cs_out-msg = |{ cs_out-msg }; { iv_text }|.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form COLLECT_RECIPIENTS
*&---------------------------------------------------------------------*
*& One mail for the whole day to everyone (functional decision
*& 25/09/26): MDM from TVARVC plus every supplier manager and supplier
*& contact of every BP in GT_DET, de-duplicated.
*&---------------------------------------------------------------------*
FORM collect_recipients.

  DATA: lt_mdm  TYPE ty_t_tvarv,
        lv_mdm  TYPE tvarvc-low,
        lv_mail TYPE adr6-smtp_addr,
        ls_det  TYPE ty_det.

  CLEAR: gt_recip, gv_mdm_missing.

  " MDM address(es) - TVARVC instead of the hardcoded address in the FS,
  " agreed with functional 25/09/26 so a change needs no transport.
  SELECT low
    FROM tvarvc
    WHERE name = @gc_tvarv_mdm
    INTO TABLE @lt_mdm.

  LOOP AT lt_mdm INTO lv_mdm.
    lv_mail = lv_mdm.
    CONDENSE lv_mail.
    IF lv_mail IS NOT INITIAL.
      APPEND lv_mail TO gt_recip.
    ENDIF.
  ENDLOOP.
  IF gt_recip IS INITIAL.
    gv_mdm_missing = abap_true.
  ENDIF.

  LOOP AT gt_det INTO ls_det.
    IF ls_det-mgr_mail IS NOT INITIAL.
      APPEND ls_det-mgr_mail TO gt_recip.
    ENDIF.
    IF ls_det-cont_mail IS NOT INITIAL.
      APPEND ls_det-cont_mail TO gt_recip.
    ENDIF.
  ENDLOOP.

  SORT gt_recip.
  DELETE ADJACENT DUPLICATES FROM gt_recip.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_BODY
*&---------------------------------------------------------------------*
*& HTML body per the FS e-mail draft: greeting, intro, one detail table
*& per supplier, sign-off, no-reply line. All wording comes from text
*& symbols so functional can adjust it without a code change. Master
*& data is HTML-escaped so a '&' or '<' in a name cannot break the
*& layout.
*&---------------------------------------------------------------------*
FORM build_body CHANGING cv_html TYPE string.

  DATA: ls_det TYPE ty_det.

  CLEAR cv_html.

  cv_html = |<html><body style="font-family:Arial;font-size:10pt">|
         && |<p>{ TEXT-t01 }</p>|
         && |<p>{ TEXT-t02 } { TEXT-t03 }</p>|.

  LOOP AT gt_det INTO ls_det.
    cv_html = cv_html
           && |<table border="1" cellpadding="4" cellspacing="0">|.
    PERFORM add_row USING TEXT-l01 ls_det-name       CHANGING cv_html.
    PERFORM add_row USING TEXT-l02 ls_det-street     CHANGING cv_html.
    PERFORM add_row USING TEXT-l03 ls_det-str_suppl1 CHANGING cv_html.
    PERFORM add_row USING TEXT-l04 ls_det-str_suppl2 CHANGING cv_html.
    PERFORM add_row USING TEXT-l05 ls_det-city2      CHANGING cv_html.
    PERFORM add_row USING TEXT-l06 ls_det-post_code1 CHANGING cv_html.
    PERFORM add_row USING TEXT-l07 ls_det-city1      CHANGING cv_html.
    PERFORM add_row USING TEXT-l08 ls_det-region_txt CHANGING cv_html.
    PERFORM add_row USING TEXT-l09 ls_det-cntry_txt  CHANGING cv_html.
    PERFORM add_row USING TEXT-l10 ls_det-partner    CHANGING cv_html.
    PERFORM add_row USING TEXT-l11 ls_det-mgr_mail   CHANGING cv_html.
    cv_html = cv_html && |</table><br/>|.
  ENDLOOP.

  cv_html = cv_html
         && |<p>{ TEXT-t04 }<br/>{ TEXT-t05 }</p>|
         && |<p>{ TEXT-t06 }</p>|
         && |</body></html>|.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_ROW
*&---------------------------------------------------------------------*
FORM add_row USING    iv_label TYPE clike
                      iv_value TYPE clike
             CHANGING cv_html  TYPE string.

  DATA: lv_value TYPE string.

  lv_value = iv_value.
  lv_value = escape( val    = lv_value
                     format = cl_abap_format=>e_html_text ).

  cv_html = cv_html
         && |<tr><td><b>{ iv_label }</b></td>|
         && |<td>{ lv_value }</td></tr>|.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SEND_MAIL
*&---------------------------------------------------------------------*
*& CL_BCS, HTML document, one internet recipient per address in
*& GT_RECIP. The FS subject is longer than the 50 characters
*& CREATE_DOCUMENT accepts, so the full text goes through
*& SET_MESSAGE_SUBJECT. The result lands in GV_SEND_RESULT for the ALV
*& header and in a status message for the job log. Actual dispatch is
*& done by the SCOT send job (RSCONN01), as for every CL_BCS mail.
*&---------------------------------------------------------------------*
FORM send_mail.

  DATA: lo_send    TYPE REF TO cl_bcs,
        lo_doc     TYPE REF TO cl_document_bcs,
        lo_sender  TYPE REF TO cl_cam_address_bcs,
        lo_recip   TYPE REF TO cl_cam_address_bcs,
        lo_cx      TYPE REF TO cx_bcs,
        lt_soli    TYPE soli_tab,
        lv_html    TYPE string,
        lv_subject TYPE string,
        lv_subj50  TYPE so_obj_des,
        lv_sender  TYPE tvarvc-low,
        lv_addr    TYPE adr6-smtp_addr,
        lv_sent    TYPE os_boolean,
        lv_count   TYPE i.

  CLEAR gv_send_result.

  IF gt_det IS INITIAL.
    " Every BP of the day was skipped (no supplier master) - nothing to mail
    gv_send_result = TEXT-m11.
    MESSAGE gv_send_result TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF gt_recip IS INITIAL.
    gv_send_result = TEXT-m07.
    MESSAGE gv_send_result TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM build_body CHANGING lv_html.

  lv_subject = TEXT-s01.
  lv_subj50  = lv_subject.

  " Optional fixed sender, e.g. noreply@astralltd.com
  SELECT SINGLE low
    FROM tvarvc
    WHERE name = @gc_tvarv_snd
    INTO @lv_sender.
  CONDENSE lv_sender.

  TRY.
      lo_send = cl_bcs=>create_persistent( ).

      lt_soli = cl_bcs_convert=>string_to_soli( iv_string = lv_html ).
      lo_doc  = cl_document_bcs=>create_document(
                  i_type    = gc_doc_html
                  i_text    = lt_soli
                  i_subject = lv_subj50 ).
      lo_send->set_document( lo_doc ).
      lo_send->set_message_subject( ip_subject = lv_subject ).

      IF lv_sender IS NOT INITIAL.
        lv_addr   = lv_sender.
        lo_sender = cl_cam_address_bcs=>create_internet_address(
                      i_address_string = lv_addr ).
        lo_send->set_sender( i_sender = lo_sender ).
      ENDIF.

      LOOP AT gt_recip INTO lv_addr.
        lo_recip = cl_cam_address_bcs=>create_internet_address(
                     i_address_string = lv_addr ).
        lo_send->add_recipient( i_recipient = lo_recip ).
      ENDLOOP.

      lo_send->set_send_immediately( i_send_immediately = abap_true ).
      lv_sent = lo_send->send( i_with_error_screen = abap_false ).

      IF lv_sent = abap_true.
        COMMIT WORK.
        lv_count = lines( gt_recip ).
        gv_send_result = TEXT-m08.
        REPLACE '&' IN gv_send_result WITH |{ lv_count }|.
        IF gv_mdm_missing = abap_true.
          gv_send_result = |{ gv_send_result } - { TEXT-m06 }|.
        ENDIF.
        MESSAGE gv_send_result TYPE 'S'.
      ELSE.
        ROLLBACK WORK.
        gv_send_result = TEXT-m09.
        MESSAGE gv_send_result TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    CATCH cx_bcs INTO lo_cx.
      ROLLBACK WORK.
      gv_send_result = |{ TEXT-m09 }: { lo_cx->get_text( ) }|.
      MESSAGE gv_send_result TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_LOG
*&---------------------------------------------------------------------*
*& One row per BP found, with what was read and how the send went.
*& CL_SALV_TABLE prints to the spool in background, so the job has a
*& readable record as well as the job-log message.
*&---------------------------------------------------------------------*
FORM display_log.

  DATA: lo_salv    TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column,
        lo_cx      TYPE REF TO cx_salv_msg,
        lv_title   TYPE lvc_title.

  IF gt_out IS INITIAL.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = gt_out ).

      lo_salv->get_functions( )->set_all( abap_true ).
      lo_salv->get_columns( )->set_optimize( abap_true ).

      lv_title = gv_send_result.
      lo_salv->get_display_settings( )->set_list_header( lv_title ).

      lo_columns = lo_salv->get_columns( ).

      lo_column = lo_columns->get_column( 'PARTNER' ).
      lo_column->set_medium_text( TEXT-c01 ).
      lo_column->set_long_text( TEXT-c01 ).

      lo_column = lo_columns->get_column( 'NAME1' ).
      lo_column->set_medium_text( TEXT-c02 ).
      lo_column->set_long_text( TEXT-c02 ).

      lo_column = lo_columns->get_column( 'CITY1' ).
      lo_column->set_medium_text( TEXT-c03 ).
      lo_column->set_long_text( TEXT-c03 ).

      lo_column = lo_columns->get_column( 'MGR_MAIL' ).
      lo_column->set_medium_text( TEXT-c04 ).
      lo_column->set_long_text( TEXT-c04 ).

      lo_column = lo_columns->get_column( 'CONT_MAIL' ).
      lo_column->set_medium_text( TEXT-c05 ).
      lo_column->set_long_text( TEXT-c05 ).

      lo_column = lo_columns->get_column( 'STATUS' ).
      lo_column->set_short_text( TEXT-c06 ).
      lo_column->set_medium_text( TEXT-c06 ).
      lo_column->set_long_text( TEXT-c06 ).

      lo_column = lo_columns->get_column( 'MSG' ).
      lo_column->set_medium_text( TEXT-c07 ).
      lo_column->set_long_text( TEXT-c07 ).

      lo_salv->display( ).

    CATCH cx_salv_msg INTO lo_cx.
      MESSAGE lo_cx->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    CATCH cx_salv_not_found.
      MESSAGE TEXT-m12 TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.
