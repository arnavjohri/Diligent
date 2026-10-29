*----------------------------------------------------------------------*
* PATCH SHEET - paste-only fragment, not a whole object
*
* Programs : ZFITAX_PBT_CALC_PRG    FORM PROCESS_DATA
*            ZFI_TAX_CREDIT_REPORT  FORM PROCESS_DATA  (identical statement)
*
* Issue    : FAGLFLEXT read via FOR ALL ENTRIES returns fewer rows than
*            SE16N for the same selection. Verified 29/10/26 on OCP:
*            RACCT 200153 / RBUKRS OVL / RYEAR 2026 / RLDNR 0L ->
*            25 rows in SE16N, 21 rows in it_fl.
*
* Cause    : FOR ALL ENTRIES adds an implicit DISTINCT over the columns
*            that reach the target (ty_fl). On the S/4 FAGLFLEXT
*            compatibility view OBJNR00..08 are all zero, so rows differ
*            only by DRCRK and RCNTR. ty_fl has no RCNTR, so H rows with
*            identical period amounts collapse into one (cost centres
*            DRLL/LG/MM, IT/MD, BD/MOZ) and their credits drop out of
*            the HSL/KSL sums.
*
* Fix      : RANGE on RACCT instead of FOR ALL ENTRIES. A range has no
*            implicit DISTINCT, so every DB row is returned.
*            Adding DRCRK/RCNTR/OBJNR to ty_fl is NOT a fix - any
*            characteristic ty_fl does not carry collapses the same way.
*
* Locate by FORM name and statement text, never by line number.
* Lines kept under 120 chars - the commented original is split in two
* so SE38 does not wrap it on paste.
*
* Behaviour change: an empty lt_racct used to select EVERY account for
* the year / company code (FOR ALL ENTRIES on an empty driver). It now
* selects nothing, which is the intended result.
*
* ASSUMPTION: lt_racct stays in the hundreds, not tens of thousands.
* If the SETLEAF BT explosion can produce very large lists, build the
* range from SETLEAF VALFROM/VALTO as I/BT lines instead of one I/EQ
* line per account (DBSQL_STMNT_TOO_LARGE, see MEMORY.md section 4).
*----------------------------------------------------------------------*

    DATA: it_fl TYPE TABLE OF ty_fl.

*BOC By Arnav on 29/10/26
*    SELECT  * FROM faglflext INTO CORRESPONDING FIELDS OF  TABLE @it_fl  FOR ALL ENTRIES IN @lt_racct
*      WHERE racct EQ @lt_racct-racct AND ryear EQ @year AND rbukrs EQ @c_code AND rldnr EQ '0L'.
    DATA: lr_racct TYPE RANGE OF faglflext-racct,
          ls_rng   LIKE LINE OF lr_racct.

    LOOP AT lt_racct ASSIGNING FIELD-SYMBOL(<fs_rng>).
      ls_rng-sign   = 'I'.
      ls_rng-option = 'EQ'.
      ls_rng-low    = <fs_rng>-racct.
      APPEND ls_rng TO lr_racct.
    ENDLOOP.
    SORT lr_racct BY low.
    DELETE ADJACENT DUPLICATES FROM lr_racct COMPARING low.

    IF lr_racct IS NOT INITIAL.
      SELECT * FROM faglflext
        INTO CORRESPONDING FIELDS OF TABLE @it_fl
        WHERE racct  IN @lr_racct
          AND ryear  EQ @year
          AND rbukrs EQ @c_code
          AND rldnr  EQ '0L'.
    ENDIF.
*EOC By Arnav on 29/10/26

    SORT it_fl BY racct.
    SORT lt_racct BY racct.
