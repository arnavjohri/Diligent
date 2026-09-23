*&---------------------------------------------------------------------*
*& Include          ZXVVFU02
*&---------------------------------------------------------------------*
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(XACCIT) LIKE  ACCIT STRUCTURE  ACCIT
*"     VALUE(VBRK) LIKE  VBRK STRUCTURE  VBRK
*"     REFERENCE(DOC_NUMBER) LIKE  VBRK-VBELN OPTIONAL
*"  EXPORTING
*"     VALUE(XACCIT) LIKE  ACCIT STRUCTURE  ACCIT
*"  TABLES
*"      CVBRP STRUCTURE  VBRPVB OPTIONAL
*"      CKOMV STRUCTURE  KOMV
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
* Program Name  : ZXVVFU02
* Title         : Populate Reference/Payment Method
* APSE No.      : i002
* Create Date   : 09/08/2024
* Release       : 1.0
* Author        : Nir Ben Ami
*----------------------------------------------------------------------*
* Description   : Populate Reference/Payment Method
*
*----------------------------------------------------------------------*
* CHANGE HISTORY
*----------------------------------------------------------------------*
*Date       | User ID      |Description                  |Change Label *
*----------------------------------------------------------------------*
*23/09/2026 | Arnav Johri  |INC01740 SGTXT from SO       |             *
*           |              |Header Note 1 (customer line)|             *
*----------------------------------------------------------------------*

DATA:
  lv_localamt  TYPE dmbtr,
  lv_convamt   TYPE dmbtr,
  ls_cvbrp     TYPE vbrpvb,
  lv_auart     TYPE auart,
  lv_fkart_ich TYPE fkart,
  lv_rstgr_i01 TYPE rstgr,
  lv_rstgr_i02 TYPE rstgr,
  lv_rstgr_i03 TYPE rstgr,
  lv_zlsch     TYPE dzlsch,
  lv_fdlev     TYPE fdlev,
  lv_pp(1)     TYPE n,
  lv_ppin(2)   TYPE n,
  lv_setperiod TYPE ziata_settlement_period, "YYMMPP
  lv_datum     TYPE sy-datum.

CONSTANTS:
  lc_tousd    TYPE waers VALUE 'USD',
  lc_iatarate TYPE kurst VALUE 'I5'.    "'IATA'.

*BOC By Arnav on 23/09/26
* INC01740 - Manage Customer Line Items shows no item text for SD documents.
* Fill the customer line text (ACCIT-SGTXT -> BSEG-SGTXT / ACDOCA-SGTXT) from
* Header Note 1 of the FIRST-CREATED sales order behind the billing document.
* Must stay ABOVE the SIS "CHECK ls_cvbrp-kvgr3 = '1'" below: that CHECK leaves
* the exit for every non-SIS billing document, so anything placed after it would
* never run for a normal customer invoice.
* Text: sales order Header Note 1 = text object VBBK, text ID 0002
*   (confirmed in TTXIT on the PAL system, 23/09/26).
* ASSUMPTION: an SGTXT already filled by SAP or by another exit is kept; the note
*   is only written into an empty SGTXT.
DATA:
  lt_aubel_sgtxt  TYPE STANDARD TABLE OF vbeln_va WITH EMPTY KEY,
  lt_tline_sgtxt  TYPE STANDARD TABLE OF tline WITH EMPTY KEY,
  lv_spras_sgtxt  TYPE spras,
  lv_tdname_sgtxt TYPE tdobname,
  lv_text_sgtxt   TYPE string.

CONSTANTS:
  lc_tdobject_sgtxt TYPE tdobject VALUE 'VBBK',
  lc_tdid_sgtxt     TYPE tdid     VALUE '0002'.

IF xaccit-sgtxt IS INITIAL.

* Distinct preceding sales orders of the billing document
  LOOP AT cvbrp INTO DATA(ls_cvbrp_sgtxt) WHERE aubel IS NOT INITIAL.
    APPEND ls_cvbrp_sgtxt-aubel TO lt_aubel_sgtxt.
  ENDLOOP.
  SORT lt_aubel_sgtxt.
  DELETE ADJACENT DUPLICATES FROM lt_aubel_sgtxt.

  IF lt_aubel_sgtxt IS NOT INITIAL.
*   First-created sales order (ticket wording), document number as tie-break only
    SELECT vbeln, erdat, erzet
      FROM vbak
      FOR ALL ENTRIES IN @lt_aubel_sgtxt
      WHERE vbeln = @lt_aubel_sgtxt-table_line
      INTO TABLE @DATA(lt_vbak_sgtxt).
    SORT lt_vbak_sgtxt BY erdat erzet vbeln.
    READ TABLE lt_vbak_sgtxt INTO DATA(ls_vbak_sgtxt) INDEX 1.

    IF sy-subrc = 0.
      lv_tdname_sgtxt = ls_vbak_sgtxt-vbeln.

*     Language: billing document language first, else the first language the
*     note exists in (STXH is the text header, no cluster read needed)
      lv_spras_sgtxt = vbrk-spras.
      SELECT SINGLE tdspras
        FROM stxh
        WHERE tdobject = @lc_tdobject_sgtxt
          AND tdname   = @lv_tdname_sgtxt
          AND tdid     = @lc_tdid_sgtxt
          AND tdspras  = @lv_spras_sgtxt
        INTO @lv_spras_sgtxt.
      IF sy-subrc <> 0.
        SELECT tdspras
          FROM stxh
          WHERE tdobject = @lc_tdobject_sgtxt
            AND tdname   = @lv_tdname_sgtxt
            AND tdid     = @lc_tdid_sgtxt
          ORDER BY tdspras
          INTO @lv_spras_sgtxt
          UP TO 1 ROWS.
        ENDSELECT.
      ENDIF.

      IF sy-subrc = 0.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = lc_tdid_sgtxt
            language                = lv_spras_sgtxt
            name                    = lv_tdname_sgtxt
            object                  = lc_tdobject_sgtxt
          TABLES
            lines                   = lt_tline_sgtxt
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
*         Lines joined with a blank; SGTXT is CHAR 50, the assignment truncates
          LOOP AT lt_tline_sgtxt INTO DATA(ls_tline_sgtxt) WHERE tdline IS NOT INITIAL.
            lv_text_sgtxt = |{ lv_text_sgtxt } { ls_tline_sgtxt-tdline }|.
          ENDLOOP.
          CONDENSE lv_text_sgtxt.
          IF lv_text_sgtxt IS NOT INITIAL.
            xaccit-sgtxt = lv_text_sgtxt.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
ENDIF.
*EOC By Arnav on 23/09/26

READ TABLE cvbrp INTO ls_cvbrp INDEX 1.
"First check if SIS case
CHECK ls_cvbrp-kvgr3 = '1'.
* Concatenate company code with billing document number into XBLNR
DATA(lv_xblnr_val) = | { xaccit-xblnr ALPHA = OUT } |.
CONDENSE lv_xblnr_val.
xaccit-xblnr = lv_xblnr_val.
*CONCATENATE xaccit-bukrs lv_xblnr_val INTO xaccit-xblnr.
"Get the SIS header data
SELECT SINGLE *
    FROM ziata_invheader
    INTO @DATA(gw_invheader)
    WHERE vbeln EQ @ls_cvbrp-aubel.

"Get Order type
SELECT SINGLE auart INTO lv_auart FROM vbak WHERE vbeln = cvbrp-aubel.
* Payment Currency+payment amount+Settlement Period
IF vbrk-waerk <> lc_tousd.
  IF lv_auart = 'ZDR' .  "Rejection
    SELECT SINGLE *
    FROM ziata_rej_det
    INTO @DATA(gw_rej_invdet)
    WHERE vbeln EQ @cvbrp-aubel.
    IF sy-subrc = 0.
      lv_setperiod = gw_rej_invdet-settlement_per.  "Rejection settl. period
    ENDIF.
  ELSE.
    CONCATENATE xaccit-zuonr(2) xaccit-zuonr+3(2) xaccit-zuonr+6(2) INTO lv_setperiod."Normal period
  ENDIF.

  lv_datum(2)   = sy-datum(2)." 'YYYYMMDD' YYMMDD
  lv_datum+2(2) = lv_setperiod(2).
  lv_datum+4(2) = lv_setperiod+2(2).
  lv_datum+6(2) = lv_setperiod+4(2).

  xaccit-pycur = lc_tousd.

  lv_localamt = vbrk-netwr + vbrk-mwsbk.

  CALL FUNCTION 'CONVERT_TO_FOREIGN_CURRENCY'
    EXPORTING
      date             = lv_datum "date based on the settlement period
      foreign_currency = lc_tousd
      local_amount     = lv_localamt
      local_currency   = vbrk-waerk
      type_of_rate     = lc_iatarate
      read_tcurr       = 'X'
    IMPORTING
      foreign_amount   = lv_convamt
    EXCEPTIONS
      no_rate_found    = 1
      overflow         = 2
      no_factors_found = 3
      no_spread_found  = 4
      derived_2_times  = 5
      OTHERS           = 6.

  IF sy-subrc = 0.
    xaccit-pyamt = lv_convamt.
  ENDIF.
ENDIF.

"Charge Category
xaccit-xref2 = gw_invheader-chargecategory.
"Payment Method
xaccit-zlsch = gw_invheader-settlementmethod.
