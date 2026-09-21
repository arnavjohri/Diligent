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
*           |              |                             |             *
*           |              |                             |             *
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
