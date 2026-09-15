*&---------------------------------------------------------------------*
*& WRICEF        : 195_BRD_FS_ZMB5B_Report  (port to ZMM_MB5B_NEW)
*& Project       : UDAY  /  Astral Limited
*& Object        : ZMM_RM07MLBD  (tcode ZMM_MB5B_NEW, package ZMM_ABAP)
*& Change tag    : ZMB5B 195_BRD_FS
*& Date          : 15.09.2026
*&---------------------------------------------------------------------*
*& PASTE SHEET - the same change as ZRM07MLBD / ZMB5B, applied to the
*& already existing custom report ZMM_RM07MLBD. Main program only; the
*& Z includes ZMM_RM07MLDD / _FORM_01 / _FORM_02 are NOT touched.
*&
*& Each unit names the FORM and the line directly ABOVE the insertion.
*& Locate by FORM name in SE38, never by line number. Where a unit
*& replaces a line, the old line is kept commented out inside the block
*& - delete the original active line after pasting the block.
*&---------------------------------------------------------------------*

*&=====================================================================*
*& UNIT 1  -  global declarations, top of the main program
*&   insert directly BELOW :
*&   *INCLUDE:  rm07mldd.     " reportspezifische Datendefinitionen
*&=====================================================================*
*BOC By Arnav on 15/09/26
* ZMB5B 195_BRD_FS : receipt amount / issue amount for the radio button
* "Storage Loc./Batch Stock". The standard sum tables SUM_MAT and
* SUM_CHAR (include ZMM_RM07MLDD) aggregate quantities only - they have
* no DMBTR component - so the values are aggregated in this table.
DATA : BEGIN OF gt_zwert_sum OCCURS 100,
         werks     LIKE mseg-werks,
         matnr     LIKE mseg-matnr,
         charg     LIKE mseg-charg,
         shkzg     LIKE mseg-shkzg,
         dmbtr(09) TYPE p DECIMALS 2,
       END OF gt_zwert_sum.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 2  -  START-OF-SELECTION flow of the main program (not a FORM)
*&   the ONLY place where  PERFORM summen_bilden.  is directly
*&   followed by  PERFORM bestaende_berechnen.  - insert BELOW that.
*&=====================================================================*
*BOC By Arnav on 15/09/26
*   ZMB5B 195_BRD_FS : the standard fills the value fields for the
*   valuated stock only - add them for the storage location view
    PERFORM zf_lgbst_wert_ergaenzen.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 3  -  FORM CREATE_TABLE_TOTALS_HQ
*&   REPLACES the line  IF  bwbst = 'X'.  directly BELOW the comment
*&   *   line with the good receipts
*&=====================================================================*
*BOC By Arnav on 15/09/26
*   ZMB5B 195_BRD_FS : show the receipt amount for the radio button
*   "Storage Loc./Batch Stock", too
*    IF  bwbst = 'X'.
    IF  bwbst = 'X'  OR  lgbst = 'X'.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 4  -  FORM CREATE_TABLE_TOTALS_HQ
*&   REPLACES the line  IF  bwbst = 'X'.  directly BELOW the comment
*&   *   line with the good issues
*&=====================================================================*
*BOC By Arnav on 15/09/26
*   ZMB5B 195_BRD_FS : show the issue amount for the radio button
*   "Storage Loc./Batch Stock", too
*    IF  bwbst = 'X'.
    IF  bwbst = 'X'  OR  lgbst = 'X'.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 5  -  FORM CREATE_TABLE_TOTALS_HQ_1
*&   REPLACES the line  IF  bwbst = 'X'.  directly ABOVE the comment
*&   *  colorize the values only in mode valuated stock
*&=====================================================================*
*BOC By Arnav on 15/09/26
* ZMB5B 195_BRD_FS : colorize the value column in the storage location
* view as well
*  IF  bwbst = 'X'.
  IF  bwbst = 'X'  OR  lgbst = 'X'.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 6  -  FORM CREATE_TABLE_TOTALS_FLAT
*&   insert directly BELOW (inside the  IF bwbst = 'X'  block) :
*&   PERFORM  colorize_totals_flat   USING 'ENDWERT'.
*&=====================================================================*
*BOC By Arnav on 15/09/26
* ZMB5B 195_BRD_FS : same sign handling and colours for the radio
* button "Storage Loc./Batch Stock" - the goods issue is shown with a
* negative sign, exactly like the quantity HABEN above.
    ELSEIF  lgbst = 'X'.
      g_s_totals_flat-habenwert     = g_s_totals_flat-habenwert * -1.

      PERFORM  colorize_totals_flat   USING 'SOLLWERT'.
      PERFORM  colorize_totals_flat   USING 'HABENWERT'.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 7  -  FORM CREATE_FIELDCAT_TOTALS_FLAT
*&   insert directly BELOW (inside the  IF bwbst = 'X'  block) :
*&   PERFORM fc_s_flat USING 'WAERS' 'T001' 'WAERS'.
*&=====================================================================*
*BOC By Arnav on 15/09/26
* ZMB5B 195_BRD_FS : receipt amount and issue amount for the radio
* button "Storage Loc./Batch Stock". The opening value (ANFWERT) and
* the closing value (ENDWERT) are not offered here - they are derived
* from the valuated stock (MBEW-SALK3), which does not exist per
* storage location.
  ELSEIF  lgbst = 'X'.

    MOVE : TEXT-101          TO  g_s_fieldcat-seltext_l, "sum GR values
           TEXT-101          TO  g_s_fieldcat-seltext_m,
           TEXT-101          TO  g_s_fieldcat-seltext_s,
           TEXT-101          TO  g_s_fieldcat-reptext_ddic,
           'L'               TO  g_s_fieldcat-ddictxt,
           23                TO  g_s_fieldcat-outputlen,
           'WAERS'           TO  g_s_fieldcat-cfieldname,
             7               TO  g_s_fieldcat-intlen,
            'P'              TO  g_s_fieldcat-inttype,
            'CURR'           TO  g_s_fieldcat-datatype.
    PERFORM fc_s_flat USING 'SOLLWERT' 'MSEG' 'DMBTR'.

    MOVE : TEXT-102          TO  g_s_fieldcat-seltext_l, "sum GI values
           TEXT-102          TO  g_s_fieldcat-seltext_m,
           TEXT-102          TO  g_s_fieldcat-seltext_s,
           TEXT-102          TO  g_s_fieldcat-reptext_ddic,
           'L'               TO  g_s_fieldcat-ddictxt,
           23                TO  g_s_fieldcat-outputlen,
           'WAERS'           TO  g_s_fieldcat-cfieldname,
             7               TO  g_s_fieldcat-intlen,
            'P'              TO  g_s_fieldcat-inttype,
            'CURR'           TO  g_s_fieldcat-datatype.
    PERFORM fc_s_flat USING 'HABENWERT' 'MSEG' 'DMBTR'.

    PERFORM fc_s_flat USING 'WAERS' 'T001' 'WAERS'.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 8  -  FORM SUMMEN_BILDEN, very end of the form
*&   insert BELOW the last  ENDIF.  and directly ABOVE
*&   ENDFORM.                               " SUMMEN_BILDEN
*&=====================================================================*
*BOC By Arnav on 15/09/26
* ZMB5B 195_BRD_FS : sum the values (MSEG-DMBTR) for the radio button
* "Storage Loc./Batch Stock". At this point G_T_MSEG_LEAN contains
* exactly the accepted material document items - the standard loops
* above have already deleted the automatically created / transfer
* postings. DMBTR is part of STYPE_MSEG_LEAN and is therefore already
* selected by F1000_SELECT_MSEG_MKPF, so no additional database
* access is needed here.
  IF  lgbst = 'X'.
    REFRESH                  gt_zwert_sum.

    LOOP AT g_t_mseg_lean    INTO  g_s_mseg_lean.
      CLEAR                  gt_zwert_sum.

      MOVE : g_s_mseg_lean-werks  TO  gt_zwert_sum-werks,
             g_s_mseg_lean-matnr  TO  gt_zwert_sum-matnr,
             g_s_mseg_lean-shkzg  TO  gt_zwert_sum-shkzg,
             g_s_mseg_lean-dmbtr  TO  gt_zwert_sum-dmbtr.

*     on material level the stocks are summarised over the batches
      IF  xchar = 'X'.
        MOVE  g_s_mseg_lean-charg TO  gt_zwert_sum-charg.
      ENDIF.

      COLLECT                gt_zwert_sum.
    ENDLOOP.

    SORT  gt_zwert_sum       BY  werks matnr charg shkzg.
  ENDIF.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 9  -  NEW FORM, placed directly AFTER
*&   ENDFORM.                               " SUMMEN_BILDEN
*&   (anywhere at top level is fine, this keeps it next to its caller)
*&=====================================================================*
*BOC By Arnav on 15/09/26
*&---------------------------------------------------------------------*
*&      Form  ZF_LGBST_WERT_ERGAENZEN
*&---------------------------------------------------------------------*
*&      ZMB5B 195_BRD_FS
*&      Fill BESTAND-SOLLWERT (receipt amount), BESTAND-HABENWERT
*&      (issue amount) and BESTAND-WAERS for the radio button
*&      "Storage Loc./Batch Stock". The standard form
*&      BESTAENDE_BERECHNEN (include ZMM_RM07MLBD_FORM_01) fills these
*&      fields for the valuated stock (BWBST) only.
*&---------------------------------------------------------------------*
FORM zf_lgbst_wert_ergaenzen.

  CHECK : lgbst = 'X'.

  LOOP AT bestand.

*   total value of the goods receipts
    CLEAR                    gt_zwert_sum.

    READ TABLE gt_zwert_sum  WITH KEY
                             werks = bestand-werks
                             matnr = bestand-matnr
                             charg = bestand-charg
                             shkzg = 'S'
                             BINARY SEARCH.

    MOVE  gt_zwert_sum-dmbtr TO  bestand-sollwert.

*   total value of the goods issues
    CLEAR                    gt_zwert_sum.

    READ TABLE gt_zwert_sum  WITH KEY
                             werks = bestand-werks
                             matnr = bestand-matnr
                             charg = bestand-charg
                             shkzg = 'H'
                             BINARY SEARCH.

    MOVE  gt_zwert_sum-dmbtr TO  bestand-habenwert.

*   the currency key is taken from MBEW in mode valuated stock only,
*   so read it from the organisational data of the plant
    PERFORM  f9300_read_organ
                             USING  c_werks   bestand-werks.

    MOVE  g_s_organ-waers    TO  bestand-waers.

    MODIFY                   bestand.
  ENDLOOP.

ENDFORM.                     " zf_lgbst_wert_ergaenzen
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 10  -  FORM F0400_CREATE_FIELDCAT, the DMBTR block
*&   IF NOT bwbst IS INITIAL.   "mit bewertetem Bestand   (ref BSIM)
*&   insert BELOW its  PERFORM f0410_fieldcat  and ABOVE its  ENDIF.
*&=====================================================================*
*BOC By Arnav on 15/09/26
*   ZMB5B 195_BRD_FS : show the amount (MSEG-DMBTR) for the radio
*   button "Storage Loc./Batch Stock" as well. The value is already
*   on the detail row (selected from MSEG by MBLNR/MJAHR/ZEILE); only
*   its display is enabled here. LGBST/BWBST/SBBST are one mutually
*   exclusive radio group, so this branch is the storage location
*   view only.
  ELSEIF NOT lgbst IS INITIAL.
    g_s_fieldcat-fieldname     = 'DMBTR'.
    g_s_fieldcat-ref_tabname   = 'MSEG'.
    g_s_fieldcat-sp_group      = 'M'.
    PERFORM  f0410_fieldcat    USING  c_take   c_out.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT 11  -  START-OF-SELECTION flow of the main program (not a FORM)
*&   insert directly BELOW the block that ends with
*&   ENDIF.                       " w/o New DB feature  "^ hana_20120821
*&   (the  CASE p_aut  block, about 130 lines above  PERFORM new_db_run)
*&   WITHOUT THIS UNIT THE AMOUNTS STAY EMPTY ON HANA - see comment.
*&=====================================================================*
*BOC By Arnav on 15/09/26
* ZMB5B 195_BRD_FS : with the HANA stored-procedure optimisation
* (BAdI RM07MLBD_DBSYS_OPT, GV_NEWDB = 'X') the stocks come from
* FORM NEW_DB_RUN and the whole classic block SUMMEN_BILDEN /
* BESTAENDE_BERECHNEN / ZF_LGBST_WERT_ERGAENZEN is skipped, so the
* receipt and issue amounts stay empty. The current standard RM07MLBD
* (and ZRM07MLBD) switch this optimisation off unconditionally
* ("Deactivate old MMIM optimization in SAPSCORE ... gv_newdb =
* abap_false") because the AMDP path is not redirected to the S/4
* data model. Done here for the storage location view only, where
* the amounts are needed.
  IF  lgbst = 'X'.
    gv_newdb = abap_false.
  ENDIF.
*EOC By Arnav on 15/09/26

*&=====================================================================*
*& UNIT TESTS
*&=====================================================================*
*&  UT-01  ZMM_MB5B_NEW, "Storage Loc./Batch Stock", "Totals only":
*&         columns "Total value of goods receipts" / "... issues" are
*&         filled, issue value negative, currency = company code currency.
*&  UT-02  Cross-check one line: SUM(MSEG-DMBTR) for that material/plant
*&         in the date range split by SHKZG (S = receipt, H = issue).
*&  UT-03  Same with checkbox "Batch" (XCHAR): values per batch.
*&  UT-04  Same with "Totals with levels" (XSUM): the two value lines
*&         are filled and coloured.
*&  UT-05  Default output: detail list shows the DMBTR column for the
*&         storage location view.
*&  UT-06  User WITHOUT ZMB5B_NEW1 for the material type: the new value
*&         columns are blank (existing check_matnr_pa_sumfl clears them).
*&  UT-07  Regression: "Valuated Stock" and "Special Stock" unchanged.
*&=====================================================================*
