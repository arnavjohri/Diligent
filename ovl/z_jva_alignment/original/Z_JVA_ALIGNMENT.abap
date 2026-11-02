*&---------------------------------------------------------------------*
*& Report Z_JVA_ALIGNMENT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_jva_alignment.

TABLES: acdoca.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_bukrs FOR acdoca-rbukrs OBLIGATORY,
                  s_gjahr FOR acdoca-gjahr OBLIGATORY,
                  s_racct FOR acdoca-racct,
                  s_poper FOR acdoca-poper NO-EXTENSION NO INTERVALS.
SELECTION-SCREEN: END OF BLOCK blk1.

SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE TEXT-b02.
  PARAMETERS: p_del  TYPE c AS CHECKBOX DEFAULT '',
              p_test TYPE c AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: END OF BLOCK blk2.

START-OF-SELECTION.

  CONSTANTS: lc_ledger_ja TYPE rldnr VALUE '4A',           " Ledger for JVTO1
             lc_ledger_jc TYPE rldnr VALUE '4C',           " Other Ledger for JVTO1 for OSL if ROCUR = USD, or for KSL if RKCUR = USD
             lc_ledger_a  TYPE rldnr VALUE '0L',           " Ledger for ACDOCA
             lc_belnr     TYPE belnr_d VALUE 'DU00010',    " Document Number for added documents - This is the root for the number - last 3 digits = POPER
             lc_racct     TYPE racct VALUE '0015150000'.   " Retained Earnings account

  DATA: lt_zgtt_company TYPE TABLE OF zgtt_company            ##NEEDED,
        lv_counter      TYPE n LENGTH 6                       ##NEEDED,
        lt_acdoca       TYPE STANDARD TABLE OF acdoca         ##NEEDED,
        ls_acdoca       TYPE acdoca                           ##NEEDED,
        lv_count        TYPE n LENGTH 6                       ##NEEDED,
        lv_tabix        TYPE sy-tabix                         ##NEEDED,
        lv_rocur        TYPE tcurr-fcurr                      ##NEEDED,
        lv_belnr        TYPE belnr_d                          ##NEEDED.

  IF sy-batch = abap_true.
    IF p_del = abap_true.
      MESSAGE i141(sd) WITH 'Deleting previously JVA ali' 'gned ACDOCA records.'                    ##NO_TEXT.
    ELSE.
      MESSAGE i141(sd) WITH 'Aligning ACDOCA records usin' 'g JVA attributes.'                      ##NO_TEXT.
    ENDIF.
  ELSE.
    IF p_del = abap_true.
      WRITE: / 'Deleting previously JVA aligned ACDOCA records.'                                     ##NO_TEXT.
    ELSE.
      WRITE: / 'Aligning ACDOCA records using JVA attributes.'                                       ##NO_TEXT.
    ENDIF.
  ENDIF.


* Get the list of Company Codes to Process
  SELECT DISTINCT rbukrs AS bukrs
    FROM jvto1
   WHERE rbukrs IN @s_bukrs
   ORDER BY rbukrs
    INTO TABLE @DATA(lt_bukrs).

* Delete records if Delete flag set
  IF p_del = abap_true.
*   Main loop for each Company Code
    LOOP AT lt_bukrs ASSIGNING FIELD-SYMBOL(<ls_bukrs>).

      IF p_test = abap_true.
        SELECT COUNT( * )
          FROM acdoca
          INTO @DATA(lv_records)
         WHERE rbukrs = @<ls_bukrs>-bukrs
           AND gjahr IN @s_gjahr
           AND racct IN @s_racct
           AND poper IN @s_poper
           AND belnr BETWEEN 'DU00010000' AND 'DU00010016'
           AND rldnr = @lc_ledger_a.
        IF sy-batch = abap_true.
          MESSAGE i141(sd) WITH |{ lv_records NUMBER = USER } records would have been deleted f| |or Company Code { <ls_bukrs>-bukrs }.|    ##NO_TEXT.
        ELSE.
          WRITE: / |{ lv_records NUMBER = USER } records would have been deleted for Company Code { <ls_bukrs>-bukrs }.|                    ##NO_TEXT.
        ENDIF.
      ELSE.
        DELETE FROM acdoca
         WHERE rbukrs = @<ls_bukrs>-bukrs
           AND gjahr IN @s_gjahr
           AND racct IN @s_racct
           AND poper IN @s_poper
           AND belnr BETWEEN 'DU00010000' AND 'DU00010016'
           AND rldnr = @lc_ledger_a.
        DATA(lv_subrc) = sy-subrc                              ##NEEDED.
        DATA(lv_dbcnt) = sy-dbcnt                              ##NEEDED.
        IF lv_subrc IS INITIAL.
          COMMIT WORK.
          IF lv_dbcnt > 0.
            IF sy-batch = abap_true.
              MESSAGE i141(sd) WITH |{ lv_dbcnt NUMBER = USER } records have been deleted f| |or Company Code { <ls_bukrs>-bukrs }.|        ##NO_TEXT.
            ELSE.
              WRITE: / |{ lv_dbcnt NUMBER = USER } records have been deleted for Company Code { <ls_bukrs>-bukrs }.|                        ##NO_TEXT.
            ENDIF.
          ENDIF.
        ELSE.
          ROLLBACK WORK.
          IF lv_dbcnt > 0.
            IF sy-batch = abap_true.
              MESSAGE i141(sd) WITH |{ lv_dbcnt NUMBER = USER } records failed to be deleted f| |or Company Code { <ls_bukrs>-bukrs }.|     ##NO_TEXT.
            ELSE.
              WRITE: / |{ lv_dbcnt NUMBER = USER } records failed to be deleted for Company Code { <ls_bukrs>-bukrs }.|                     ##NO_TEXT.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
    RETURN.
  ENDIF.

* Main loop for each Company Code
  LOOP AT lt_bukrs ASSIGNING <ls_bukrs>.

    DATA(lr_racct) = s_racct[]        ##NEEDED.
    DATA(r_racct) = s_racct[]         ##NEEDED.

    SELECT 'I' AS sign, 'EQ' AS option, b~konts AS low
      FROM t001 AS a
      JOIN t030 AS b
        ON a~ktopl = b~ktopl
       AND b~ktosl = 'BIL'
     WHERE a~bukrs = @<ls_bukrs>-bukrs
      INTO CORRESPONDING FIELDS OF TABLE @lr_racct.

    PERFORM populate_gtt_company USING <ls_bukrs>-bukrs.
*   Get table of years and periods for the Company Code being processed
    SELECT DISTINCT bukrs, gjahr, poper, posting_date
      FROM zgtt_company
     ORDER BY bukrs, gjahr, poper
      INTO TABLE @DATA(lt_bukrs_gjahr_poper).

*   Get the Foreign Currency for the Company Code
    PERFORM get_exchange_rate USING <ls_bukrs>-bukrs CHANGING lv_rocur.

*   Process the data one period at a time
    LOOP AT lt_bukrs_gjahr_poper ASSIGNING FIELD-SYMBOL(<ls_bukrs_gjahr_poper>).
      lv_belnr = lc_belnr && <ls_bukrs_gjahr_poper>-poper.              " Document numbers change every period (POPER)
      SELECT COUNT( * ) FROM zgtt_company INTO @DATA(lv_cnt)                              ##NEEDED.
      IF lv_cnt IS INITIAL.
        INSERT zgtt_company FROM TABLE @lt_zgtt_company.
      ENDIF.

*     For period 000, only process the Retained Earnings Account
      IF <ls_bukrs_gjahr_poper>-poper = '000'.
        r_racct = lr_racct.
      ELSE.
        r_racct = s_racct[].
      ENDIF.

      WITH +jvto1 AS (
        SELECT
          FROM jvto1 AS a
          JOIN zgtt_company AS b
            ON a~rbukrs = b~bukrs
           AND a~ryear = b~gjahr
          JOIN ska1 AS c
            ON b~ktopl = c~ktopl
           AND a~racct = c~saknr
          JOIN tka02 AS d
            ON a~rbukrs = d~bukrs
          LEFT OUTER JOIN jvto1 AS e
            ON a~rrcty = e~rrcty
           AND a~rvers = e~rvers
           AND a~ryear = e~ryear
           AND a~robjnr = e~robjnr
           AND a~cobjnr = e~cobjnr
           AND a~sobjnr = e~sobjnr
           AND a~rtcur = e~rtcur
           AND a~runit = e~runit
           AND a~drcrk = e~drcrk
*   Change request to add WBS, Order and Cost Centre - begin
           AND a~rcntr = e~rcntr
           AND a~rordnr = e~rordnr
           AND a~rprojk = e~rprojk
           AND e~rldnr = @lc_ledger_jc
*   Change request to add WBS, Order and Cost Centre - end
        FIELDS b~gjahr, a~rrcty, a~rtcur, b~rhcur, b~rkcur, a~rbukrs, a~rjvnam AS vname, a~regrou AS egrup, a~rrecin AS recid,
               d~kokrs, a~racct, b~periv, b~poper, b~posting_date AS budat, b~ktopl, c~glaccount_type,
               CASE WHEN @<ls_bukrs_gjahr_poper>-poper = '000' THEN CAST( SUM( a~tslvt ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '001' THEN CAST( SUM( a~tsl01 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '002' THEN CAST( SUM( a~tsl02 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '003' THEN CAST( SUM( a~tsl03 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '004' THEN CAST( SUM( a~tsl04 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '005' THEN CAST( SUM( a~tsl05 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '006' THEN CAST( SUM( a~tsl06 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '007' THEN CAST( SUM( a~tsl07 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '008' THEN CAST( SUM( a~tsl08 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '009' THEN CAST( SUM( a~tsl09 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '010' THEN CAST( SUM( a~tsl10 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '011' THEN CAST( SUM( a~tsl11 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '012' THEN CAST( SUM( a~tsl12 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '013' THEN CAST( SUM( a~tsl13 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '014' THEN CAST( SUM( a~tsl14 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '015' THEN CAST( SUM( a~tsl15 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '016' THEN CAST( SUM( a~tsl16 ) AS CURR( 23, 2 ) ) END AS tsl,
               CASE WHEN @<ls_bukrs_gjahr_poper>-poper = '000' THEN CAST( SUM( a~hslvt ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '001' THEN CAST( SUM( a~hsl01 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '002' THEN CAST( SUM( a~hsl02 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '003' THEN CAST( SUM( a~hsl03 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '004' THEN CAST( SUM( a~hsl04 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '005' THEN CAST( SUM( a~hsl05 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '006' THEN CAST( SUM( a~hsl06 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '007' THEN CAST( SUM( a~hsl07 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '008' THEN CAST( SUM( a~hsl08 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '009' THEN CAST( SUM( a~hsl09 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '010' THEN CAST( SUM( a~hsl10 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '011' THEN CAST( SUM( a~hsl11 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '012' THEN CAST( SUM( a~hsl12 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '013' THEN CAST( SUM( a~hsl13 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '014' THEN CAST( SUM( a~hsl14 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '015' THEN CAST( SUM( a~hsl15 ) AS CURR( 23, 2 ) )
                    WHEN @<ls_bukrs_gjahr_poper>-poper = '016' THEN CAST( SUM( a~hsl16 ) AS CURR( 23, 2 ) ) END AS hsl,
               CASE WHEN d~kokrs = 'PET2' THEN       " If KOKRS = PET2 then get the value of KSL from Ledger 4C
                    CASE WHEN @<ls_bukrs_gjahr_poper>-poper = '000' THEN CAST( SUM( coalesce( e~kslvt, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '001' THEN CAST( SUM( coalesce( e~ksl01, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '002' THEN CAST( SUM( coalesce( e~ksl02, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '003' THEN CAST( SUM( coalesce( e~ksl03, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '004' THEN CAST( SUM( coalesce( e~ksl04, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '005' THEN CAST( SUM( coalesce( e~ksl05, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '006' THEN CAST( SUM( coalesce( e~ksl06, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '007' THEN CAST( SUM( coalesce( e~ksl07, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '008' THEN CAST( SUM( coalesce( e~ksl08, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '009' THEN CAST( SUM( coalesce( e~ksl09, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '010' THEN CAST( SUM( coalesce( e~ksl10, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '011' THEN CAST( SUM( coalesce( e~ksl11, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '012' THEN CAST( SUM( coalesce( e~ksl12, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '013' THEN CAST( SUM( coalesce( e~ksl13, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '014' THEN CAST( SUM( coalesce( e~ksl14, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '015' THEN CAST( SUM( coalesce( e~ksl15, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '016' THEN CAST( SUM( coalesce( e~ksl16, 0 ) ) AS CURR( 23, 2 ) ) END
               ELSE                                 " Otherwise get it from Ledger 4A
                    CASE WHEN @<ls_bukrs_gjahr_poper>-poper = '000' THEN CAST( SUM( a~kslvt ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '001' THEN CAST( SUM( a~ksl01 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '002' THEN CAST( SUM( a~ksl02 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '003' THEN CAST( SUM( a~ksl03 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '004' THEN CAST( SUM( a~ksl04 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '005' THEN CAST( SUM( a~ksl05 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '006' THEN CAST( SUM( a~ksl06 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '007' THEN CAST( SUM( a~ksl07 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '008' THEN CAST( SUM( a~ksl08 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '009' THEN CAST( SUM( a~ksl09 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '010' THEN CAST( SUM( a~ksl10 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '011' THEN CAST( SUM( a~ksl11 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '012' THEN CAST( SUM( a~ksl12 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '013' THEN CAST( SUM( a~ksl13 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '014' THEN CAST( SUM( a~ksl14 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '015' THEN CAST( SUM( a~ksl15 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '016' THEN CAST( SUM( a~ksl16 ) AS CURR( 23, 2 ) ) END END AS ksl,
               CASE WHEN d~kokrs = 'PET1' THEN     " If KOKRS = PET1 then get the value of OSL from Ledger 4C
                    CASE WHEN @<ls_bukrs_gjahr_poper>-poper = '000' THEN CAST( SUM( coalesce( e~kslvt, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '001' THEN CAST( SUM( coalesce( e~ksl01, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '002' THEN CAST( SUM( coalesce( e~ksl02, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '003' THEN CAST( SUM( coalesce( e~ksl03, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '004' THEN CAST( SUM( coalesce( e~ksl04, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '005' THEN CAST( SUM( coalesce( e~ksl05, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '006' THEN CAST( SUM( coalesce( e~ksl06, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '007' THEN CAST( SUM( coalesce( e~ksl07, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '008' THEN CAST( SUM( coalesce( e~ksl08, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '009' THEN CAST( SUM( coalesce( e~ksl09, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '010' THEN CAST( SUM( coalesce( e~ksl10, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '011' THEN CAST( SUM( coalesce( e~ksl11, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '012' THEN CAST( SUM( coalesce( e~ksl12, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '013' THEN CAST( SUM( coalesce( e~ksl13, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '014' THEN CAST( SUM( coalesce( e~ksl14, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '015' THEN CAST( SUM( coalesce( e~ksl15, 0 ) ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '016' THEN CAST( SUM( coalesce( e~ksl16, 0 ) ) AS CURR( 23, 2 ) ) END
               ELSE                                 " Otherwise get it from Ledger 4A
                    CASE WHEN @<ls_bukrs_gjahr_poper>-poper = '000' THEN CAST( SUM( a~kslvt ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '001' THEN CAST( SUM( a~ksl01 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '002' THEN CAST( SUM( a~ksl02 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '003' THEN CAST( SUM( a~ksl03 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '004' THEN CAST( SUM( a~ksl04 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '005' THEN CAST( SUM( a~ksl05 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '006' THEN CAST( SUM( a~ksl06 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '007' THEN CAST( SUM( a~ksl07 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '008' THEN CAST( SUM( a~ksl08 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '009' THEN CAST( SUM( a~ksl09 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '010' THEN CAST( SUM( a~ksl10 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '011' THEN CAST( SUM( a~ksl11 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '012' THEN CAST( SUM( a~ksl12 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '013' THEN CAST( SUM( a~ksl13 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '014' THEN CAST( SUM( a~ksl14 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '015' THEN CAST( SUM( a~ksl15 ) AS CURR( 23, 2 ) )
                         WHEN @<ls_bukrs_gjahr_poper>-poper = '016' THEN CAST( SUM( a~ksl16 ) AS CURR( 23, 2 ) ) END END AS osl
*   Change request to add WBS, Order and Cost Centre - begin
               , a~rcntr, a~rordnr AS aufnr, a~rprojk AS ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - end
         WHERE b~bukrs = @<ls_bukrs_gjahr_poper>-bukrs
           AND b~gjahr = @<ls_bukrs_gjahr_poper>-gjahr
           AND b~poper = @<ls_bukrs_gjahr_poper>-poper
           AND a~rldnr = @lc_ledger_ja
           AND a~racct IN @r_racct
         GROUP BY b~gjahr, a~rrcty, a~rtcur, b~rhcur, b~rkcur, a~rbukrs, a~rjvnam, a~regrou, a~rrecin, d~kokrs,
*   Change request to add WBS, Order and Cost Centre - begin
*                  a~racct, b~periv, b~poper, b~posting_date, b~ktopl, c~glaccount_type ),
                  a~racct, b~periv, b~poper, b~posting_date, b~ktopl, c~glaccount_type
                  , a~rcntr, a~rordnr, a~rprojk ),
*   Change request to add WBS, Order and Cost Centre - end
           +acdoca AS (
        SELECT
          FROM acdoca AS a
          JOIN zgtt_company AS b
            ON a~rbukrs = b~bukrs
           AND a~ryear = b~gjahr
           AND a~poper = b~poper
          JOIN tka02 AS c
            ON a~rbukrs = c~bukrs
   FIELDS b~gjahr, a~rrcty, a~rtcur, a~rhcur, a~rkcur, a~rbukrs, a~vname, a~egrup, a~recid, c~kokrs, a~racct, a~periv, a~poper,
          b~posting_date AS budat, a~ktopl, a~glaccount_type,
          CAST( SUM( a~tsl ) * -1 AS CURR( 23, 2 ) ) AS tsl,
          CAST( SUM( a~hsl ) * -1 AS CURR( 23, 2 ) ) AS hsl,
          CAST( SUM( a~ksl ) * -1 AS CURR( 23, 2 ) ) AS ksl,
          CAST( SUM( a~osl ) * -1 AS CURR( 23, 2 ) ) AS osl
*   Change request to add WBS, Order and Cost Centre - begin
          , a~rcntr, a~aufnr, a~ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - end
         WHERE b~bukrs = @<ls_bukrs_gjahr_poper>-bukrs
           AND b~gjahr = @<ls_bukrs_gjahr_poper>-gjahr
           AND b~poper = @<ls_bukrs_gjahr_poper>-poper
           AND a~rldnr = @lc_ledger_a
           AND a~racct IN @r_racct
*   Change Request to remove non-JV records from remediation - begin
           AND ( vname <> '' OR egrup <> '' OR recid <> '' OR rcntr <> '' OR aufnr <> '' OR ps_psp_pnr <> '' )
*   Change Request to remove non-JV records from remediation - end
         GROUP BY b~gjahr, a~rrcty, a~rtcur, a~rhcur, a~rkcur, a~rbukrs, a~vname, a~egrup, a~recid, c~kokrs, a~racct, a~periv, a~poper,
*   Change request to add WBS, Order and Cost Centre - begin
*                  b~posting_date, a~ktopl, a~glaccount_type ),
                  b~posting_date, a~ktopl, a~glaccount_type
                  , a~rcntr, a~aufnr, a~ps_psp_pnr ),
*   Change request to add WBS, Order and Cost Centre - end
           +koart AS (
        SELECT
          FROM acdoca AS a
          JOIN skb1 AS b
            ON a~rbukrs = b~bukrs
           AND a~racct = b~saknr
        FIELDS DISTINCT a~racct, CASE b~mitkz
                 WHEN 'A' THEN 'A'
                 WHEN 'D' THEN 'D'
                 WHEN 'K' THEN 'K'
                 WHEN ' ' THEN
                   CASE a~ktosl
                     WHEN 'BSX' THEN 'M' END END AS koart
         WHERE a~rbukrs = @<ls_bukrs_gjahr_poper>-bukrs
           AND a~ryear = @<ls_bukrs_gjahr_poper>-gjahr
           AND a~rldnr = @lc_ledger_a
           AND a~racct IN @r_racct ),
           +main AS (
        SELECT
          FROM +jvto1
        FIELDS gjahr, rrcty, rtcur, rhcur, rkcur, rbukrs, vname, egrup, recid, kokrs, racct,
               periv, poper, budat, ktopl, glaccount_type, tsl, hsl, ksl, osl
*   Change request to add WBS, Order and Cost Centre - begin
               , rcntr, aufnr, ps_psp_pnr
         WHERE tsl <> 0 OR hsl <> 0 OR ksl <> 0 OR osl <> 0
*   Change request to add WBS, Order and Cost Centre - end
         UNION ALL
        SELECT
          FROM +acdoca
         FIELDS gjahr, rrcty, rtcur, rhcur, rkcur, rbukrs, vname, egrup, recid, kokrs, racct,
*   Change request to add WBS, Order and Cost Centre - begin
*               periv, poper, budat, ktopl, glaccount_type, tsl, hsl, ksl, osl ),
               periv, poper, budat, ktopl, glaccount_type, tsl, hsl, ksl, osl
               , rcntr, aufnr, ps_psp_pnr ),
*   Change request to add WBS, Order and Cost Centre - end
           +tslinc AS (
        SELECT
          FROM +main
        FIELDS gjahr, rrcty, rtcur, rhcur, rkcur, rbukrs, vname, egrup, recid,
               kokrs, racct, periv, poper, budat, ktopl, glaccount_type,
               SUM( tsl ) AS tsl, SUM( hsl ) AS hsl, SUM( ksl ) AS ksl, SUM( osl ) AS osl
*   Change request to add WBS, Order and Cost Centre - begin
               , rcntr, aufnr, ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - end
         GROUP BY gjahr, rrcty, rtcur, rhcur, rkcur, rbukrs, vname, egrup, recid,
                  kokrs, racct, periv, poper, budat, ktopl, glaccount_type
*   Change request to add WBS, Order and Cost Centre - begin
                  , rcntr, aufnr, ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - end
        HAVING SUM( hsl ) <> 0 OR SUM( ksl ) <> 0 OR SUM( osl ) <> 0 ),
           +tslexc AS (
        SELECT
          FROM +main
        FIELDS gjahr, rrcty, rhcur, rkcur, rbukrs, vname, egrup, recid,
               kokrs, racct, periv, poper, budat, ktopl, glaccount_type,
               SUM( hsl ) AS hsl, SUM( ksl ) AS ksl, SUM( osl ) AS osl
*   Change request to add WBS, Order and Cost Centre - begin
               , rcntr, aufnr, ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - end
         GROUP BY gjahr, rrcty, rhcur, rkcur, rbukrs, vname, egrup, recid,
                  kokrs, racct, periv, poper, budat, ktopl, glaccount_type
*   Change request to add WBS, Order and Cost Centre - begin
                  , rcntr, aufnr, ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - end
        HAVING SUM( hsl ) <> 0 OR SUM( ksl ) <> 0 OR SUM( osl ) <> 0 )
      SELECT
        FROM +tslinc AS a
        JOIN +tslexc AS b
          ON a~rrcty = b~rrcty
         AND a~vname = b~vname
         AND a~egrup = b~egrup
         AND a~recid = b~recid
         AND a~kokrs = b~kokrs
         AND a~racct = b~racct
         AND a~glaccount_type = b~glaccount_type
         AND a~rcntr = b~rcntr
         AND a~aufnr = b~aufnr
         AND a~ps_psp_pnr = b~ps_psp_pnr
*   Change request to add WBS, Order and Cost Centre - begin
        LEFT OUTER JOIN prps AS c
          ON a~ps_psp_pnr = c~pspnr
        LEFT OUTER JOIN proj AS d
          ON c~psphi = d~pspnr
        LEFT OUTER JOIN +koart AS e
          ON a~racct = e~racct
         AND e~koart IS NOT INITIAL
*   Change request to add WBS, Order and Cost Centre - end
      FIELDS a~gjahr, a~rrcty, a~rtcur, a~rhcur, a~rkcur, a~rbukrs, a~vname, a~egrup, a~recid,
             a~kokrs, a~racct, coalesce( e~koart, 'S' ) AS koart, a~periv, a~poper, a~budat, a~ktopl, a~glaccount_type,
             a~tsl, a~hsl, a~ksl, a~osl
*   Change request to add WBS, Order and Cost Centre - begin
             , a~rcntr, a~aufnr, a~ps_psp_pnr, c~posid AS ps_posid, d~pspnr AS ps_prj_pnr, d~pspid AS ps_pspid
*   Change request to add WBS, Order and Cost Centre - end
       ORDER BY a~rrcty, a~rtcur, a~rhcur, a~rkcur, a~racct, a~vname, a~egrup, a~recid, a~glaccount_type
        INTO TABLE @DATA(lt_acdoca_tmp).

      IF lines( lt_acdoca_tmp ) > 0.
        SELECT MAX( docln ) AS count INTO @DATA(lv_docln) FROM acdoca WHERE belnr = @lv_belnr AND rbukrs = @<ls_bukrs_gjahr_poper>-bukrs AND gjahr = @<ls_bukrs_gjahr_poper>-gjahr      ##NEEDED.
      ENDIF.
      lv_count = lv_docln.

      CLEAR: ls_acdoca.
      LOOP AT lt_acdoca_tmp ASSIGNING FIELD-SYMBOL(<ls_acdoca_tmp>).
*       Change Request Need to create balancing records for each Account, ignoring JVA and Cost objects - begin
        IF ls_acdoca-rrcty <> <ls_acdoca_tmp>-rrcty OR
           ls_acdoca-rtcur <> <ls_acdoca_tmp>-rtcur OR
           ls_acdoca-rhcur <> <ls_acdoca_tmp>-rhcur OR
           ls_acdoca-rkcur <> <ls_acdoca_tmp>-rkcur OR
           ls_acdoca-racct <> <ls_acdoca_tmp>-racct.
          IF ls_acdoca-tsl <> 0 OR ls_acdoca-hsl <> 0 OR ls_acdoca-ksl <> 0 OR ls_acdoca-osl <> 0.
*           Totals for this account don't balance, so write balancing record
            APPEND INITIAL LINE TO lt_acdoca ASSIGNING FIELD-SYMBOL(<ls_acdoca>).
            MOVE-CORRESPONDING ls_acdoca TO <ls_acdoca>.
            <ls_acdoca>-rldnr = lc_ledger_a.
            <ls_acdoca>-belnr = lv_belnr.
            <ls_acdoca>-ryear = <ls_acdoca>-gjahr.
            <ls_acdoca>-rocur = lv_rocur.
            <ls_acdoca>-rwcur = <ls_acdoca>-rtcur.
            <ls_acdoca>-rfccur = <ls_acdoca>-rhcur.
            <ls_acdoca>-wsl = <ls_acdoca>-tsl.
            <ls_acdoca>-fcsl = <ls_acdoca>-hsl.
            <ls_acdoca>-bttype = 'RFBU'.
            <ls_acdoca>-cbttype = 'RFBU'.
            <ls_acdoca>-fiscyearper = <ls_acdoca>-gjahr && <ls_acdoca>-poper.
            <ls_acdoca>-bldat = <ls_acdoca>-budat.
            <ls_acdoca>-bstat = 'C'.
            <ls_acdoca>-mig_source = 'U'.
            <ls_acdoca>-sdm_version = '05'.
            IF ( <ls_acdoca>-tsl + <ls_acdoca>-hsl + <ls_acdoca>-ksl + <ls_acdoca>-osl ) < 0.
              <ls_acdoca>-drcrk = 'H'.
            ELSE.
              <ls_acdoca>-drcrk = 'S'.
            ENDIF.
            lv_count = lv_count + 1.
            <ls_acdoca>-docln = lv_count.
          ENDIF.
*         Reset the Structure for the next account
          CLEAR: ls_acdoca.
          ls_acdoca-gjahr = <ls_acdoca_tmp>-gjahr.
          ls_acdoca-rrcty = <ls_acdoca_tmp>-rrcty.
          ls_acdoca-rtcur = <ls_acdoca_tmp>-rtcur.
          ls_acdoca-rhcur = <ls_acdoca_tmp>-rhcur.
          ls_acdoca-rkcur = <ls_acdoca_tmp>-rkcur.
          ls_acdoca-rbukrs = <ls_acdoca_tmp>-rbukrs.
          ls_acdoca-racct = <ls_acdoca_tmp>-racct.
          ls_acdoca-koart = <ls_acdoca_tmp>-koart.
          ls_acdoca-kokrs = <ls_acdoca_tmp>-kokrs.
          ls_acdoca-periv = <ls_acdoca_tmp>-periv.
          ls_acdoca-poper = <ls_acdoca_tmp>-poper.
          ls_acdoca-budat = <ls_acdoca_tmp>-budat.
          ls_acdoca-ktopl = <ls_acdoca_tmp>-ktopl.
          ls_acdoca-glaccount_type = <ls_acdoca_tmp>-glaccount_type.
          ls_acdoca-tsl = ls_acdoca-tsl - <ls_acdoca_tmp>-tsl.
          ls_acdoca-hsl = ls_acdoca-hsl - <ls_acdoca_tmp>-hsl.
          ls_acdoca-ksl = ls_acdoca-ksl - <ls_acdoca_tmp>-ksl.
          ls_acdoca-osl = ls_acdoca-osl - <ls_acdoca_tmp>-osl.
        ELSE.
          ls_acdoca-tsl = ls_acdoca-tsl - <ls_acdoca_tmp>-tsl.
          ls_acdoca-hsl = ls_acdoca-hsl - <ls_acdoca_tmp>-hsl.
          ls_acdoca-ksl = ls_acdoca-ksl - <ls_acdoca_tmp>-ksl.
          ls_acdoca-osl = ls_acdoca-osl - <ls_acdoca_tmp>-osl.
        ENDIF.
*       Change Request Need to create balancing records for each Account, ignoring JVA and Cost objects - end
        APPEND INITIAL LINE TO lt_acdoca ASSIGNING <ls_acdoca>.
        MOVE-CORRESPONDING <ls_acdoca_tmp> TO <ls_acdoca>.
        <ls_acdoca>-rldnr = lc_ledger_a.
        <ls_acdoca>-belnr = lv_belnr.
        <ls_acdoca>-ryear = <ls_acdoca>-gjahr.
        <ls_acdoca>-rocur = lv_rocur.
        <ls_acdoca>-rwcur = <ls_acdoca>-rtcur.
        <ls_acdoca>-rfccur = <ls_acdoca>-rhcur.
        <ls_acdoca>-wsl = <ls_acdoca>-tsl.
        <ls_acdoca>-fcsl = <ls_acdoca>-hsl.
        <ls_acdoca>-bttype = 'RFBU'.
        <ls_acdoca>-cbttype = 'RFBU'.
        <ls_acdoca>-fiscyearper = <ls_acdoca>-gjahr && <ls_acdoca>-poper.
        <ls_acdoca>-bldat = <ls_acdoca>-budat.
        <ls_acdoca>-bstat = 'C'.
        <ls_acdoca>-mig_source = 'U'.
        <ls_acdoca>-sdm_version = '05'.
        IF ( <ls_acdoca>-tsl + <ls_acdoca>-hsl + <ls_acdoca>-ksl + <ls_acdoca>-osl ) < 0.
          <ls_acdoca>-drcrk = 'H'.
        ELSE.
          <ls_acdoca>-drcrk = 'S'.
        ENDIF.
        lv_count = lv_count + 1.
        <ls_acdoca>-docln = lv_count.
      ENDLOOP.
*     Change Request Need to create balancing records for each Account, ignoring JVA and Cost objects - begin
*     Cater for the very last account and write if necessary
      IF ls_acdoca-tsl <> 0 OR ls_acdoca-hsl <> 0 OR ls_acdoca-ksl <> 0 OR ls_acdoca-osl <> 0.
*       Totals for this account don't balance, so write balancing record
        APPEND INITIAL LINE TO lt_acdoca ASSIGNING <ls_acdoca>.
        MOVE-CORRESPONDING ls_acdoca TO <ls_acdoca>.
        <ls_acdoca>-rldnr = lc_ledger_a.
        <ls_acdoca>-belnr = lv_belnr.
        <ls_acdoca>-ryear = <ls_acdoca>-gjahr.
        <ls_acdoca>-rocur = lv_rocur.
        <ls_acdoca>-rwcur = <ls_acdoca>-rtcur.
        <ls_acdoca>-rfccur = <ls_acdoca>-rhcur.
        <ls_acdoca>-wsl = <ls_acdoca>-tsl.
        <ls_acdoca>-fcsl = <ls_acdoca>-hsl.
        <ls_acdoca>-bttype = 'RFBU'.
        <ls_acdoca>-cbttype = 'RFBU'.
        <ls_acdoca>-fiscyearper = <ls_acdoca>-gjahr && <ls_acdoca>-poper.
        <ls_acdoca>-bldat = <ls_acdoca>-budat.
        <ls_acdoca>-bstat = 'C'.
        <ls_acdoca>-mig_source = 'U'.
        <ls_acdoca>-sdm_version = '05'.
        IF ( <ls_acdoca>-tsl + <ls_acdoca>-hsl + <ls_acdoca>-ksl + <ls_acdoca>-osl ) < 0.
          <ls_acdoca>-drcrk = 'H'.
        ELSE.
          <ls_acdoca>-drcrk = 'S'.
        ENDIF.
        lv_count = lv_count + 1.
        <ls_acdoca>-docln = lv_count.
      ENDIF.
*     Change Request Need to create balancing records for each Account, ignoring JVA and Cost objects - end

*     Specific hack to correct data anomoly for Company Code 0453 and account 15150000

      IF <ls_bukrs_gjahr_poper>-bukrs = '0453' AND <ls_bukrs_gjahr_poper>-gjahr = '2024' AND <ls_bukrs_gjahr_poper>-poper = '000'.
        READ TABLE lt_acdoca WITH KEY belnr = 'DG00000000' bttype = 'RFBC' awtyp = 'BKPF' rtcur = 'USD' racct = '0015150000' prctr = '453C0000-0'
                                      tsl = '72607.78' hsl = '72607.78' osl = '72607.78' drcrk = 'S' vname = '' egrup = '' recid = ''
                                      ASSIGNING <ls_acdoca>.
        IF sy-subrc IS INITIAL.
          <ls_acdoca>-vname = 'CP-001'.
          <ls_acdoca>-egrup = 'CP'.
          <ls_acdoca>-recid = 'CP'.
        ENDIF.
      ENDIF.
*     Write applicable records
      IF lines( lt_acdoca ) > 0.
        IF p_test = abap_true.
          IF sy-batch = abap_true.
            MESSAGE i141(sd) WITH |{ lines( lt_acdoca ) NUMBER = USER } JVA Alignment records would be writ|
                                  |ten for CoyCd { <ls_bukrs_gjahr_poper>-bukrs }, FY { <ls_bukrs_gjahr_poper>-gjahr }, Pd { <ls_bukrs_gjahr_poper>-poper }.|      ##NO_TEXT.
          ELSE.
            WRITE: / |{ lines( lt_acdoca ) NUMBER = USER } JVA Alignment records would be writ| &&
                     |ten for CoyCd { <ls_bukrs_gjahr_poper>-bukrs }, FY { <ls_bukrs_gjahr_poper>-gjahr }, Pd { <ls_bukrs_gjahr_poper>-poper }.|      ##NO_TEXT.
          ENDIF.
        ELSE.
          INSERT acdoca FROM TABLE lt_acdoca.
          IF sy-subrc IS INITIAL.
            COMMIT WORK.
            IF sy-batch = abap_true.
              MESSAGE i141(sd) WITH |{ lines( lt_acdoca ) NUMBER = USER } JVA Alignment records were writ|
                                    |ten for CoyCd { <ls_bukrs_gjahr_poper>-bukrs }, FY { <ls_bukrs_gjahr_poper>-gjahr }, Pd { <ls_bukrs_gjahr_poper>-poper }.|      ##NO_TEXT.
            ELSE.
              WRITE: / |{ lines( lt_acdoca ) NUMBER = USER } JVA Alignment records were writ| &&
                       |ten for CoyCd { <ls_bukrs_gjahr_poper>-bukrs }, FY { <ls_bukrs_gjahr_poper>-gjahr }, Pd { <ls_bukrs_gjahr_poper>-poper }.|      ##NO_TEXT.
            ENDIF.
          ELSE.
            ROLLBACK WORK.
            IF sy-batch = abap_true.
              MESSAGE i141(sd) WITH |{ lines( lt_acdoca ) NUMBER = USER } JVA Alignment records failed to writ|
                                    |e for CoyCd { <ls_bukrs_gjahr_poper>-bukrs }, FY { <ls_bukrs_gjahr_poper>-gjahr }, Pd { <ls_bukrs_gjahr_poper>-poper }.|      ##NO_TEXT.
            ELSE.
              WRITE: / |{ lines( lt_acdoca ) NUMBER = USER } JVA Alignment records failed to writ| &&
                       |e for CoyCd { <ls_bukrs_gjahr_poper>-bukrs }, FY { <ls_bukrs_gjahr_poper>-gjahr }, Pd { <ls_bukrs_gjahr_poper>-poper }.|      ##NO_TEXT.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
      CLEAR: lt_acdoca.
    ENDLOOP.
  ENDLOOP.

  DELETE FROM zgtt_company.
*&---------------------------------------------------------------------*
*& Form populate_gtt_company
*&---------------------------------------------------------------------*
*& Rather than look up company specific fields for every record, do it
*& once, as well as converting the date to a Fiscal Year and Period for
*& every 1st day of the month per company code
*&---------------------------------------------------------------------*
FORM populate_gtt_company USING pv_bukrs TYPE bukrs.

  DATA: lv_start_date TYPE datum,
        lv_end_date   TYPE datum,
        lv_gjahr      TYPE bdatj,
        lv_poper      TYPE poper.

  CLEAR: lt_zgtt_company.

  SELECT MIN( ryear ) AS gjahr
    FROM jvto1
   WHERE rbukrs = @pv_bukrs
    INTO @lv_gjahr.

  SELECT DISTINCT calendaryear AS ryear
    FROM scal_tt_date
   WHERE calendaryear IN @s_gjahr
     AND calendaryear >= @lv_gjahr
   ORDER BY calendaryear
    INTO TABLE @DATA(lt_ryear).

  LOOP AT lt_ryear ASSIGNING FIELD-SYMBOL(<ls_ryear>).
    IF sy-tabix = 1.
      lv_start_date = <ls_ryear>-ryear && '0101'.
    ENDIF.
    lv_end_date = <ls_ryear>-ryear && '1231'.
  ENDLOOP.

  SELECT
    FROM finsc_ld_cmp AS a
    JOIN t001 AS b
      ON a~bukrs = b~bukrs
    JOIN finsc_001a_rep AS c
      ON a~bukrs = c~bukrs
     AND c~curtype = '10'
    JOIN tka02 AS d
      ON a~bukrs = d~bukrs
    JOIN tka01 AS e
      ON d~kokrs = e~kokrs
   FIELDS a~periv, a~bukrs, a~rldnr, b~ktopl, c~waers AS rhcur, e~waers AS rkcur
    WHERE a~bukrs = @pv_bukrs
      AND a~rldnr = @lc_ledger_a
    INTO TABLE @DATA(lt_finsc_ld_cmp).
  SORT lt_finsc_ld_cmp BY rldnr.

  WHILE lv_start_date <= lv_end_date.
    LOOP AT lt_finsc_ld_cmp ASSIGNING FIELD-SYMBOL(<ls_finsc_ld_cmp>).
      CALL FUNCTION 'DATE_TO_PERIOD_CONVERT'
        EXPORTING
          i_date  = lv_start_date
          i_periv = <ls_finsc_ld_cmp>-periv
        IMPORTING
          e_buper = lv_poper  "Conversion Logic 2.2.6 Posting period
          e_gjahr = lv_gjahr.
      IF lv_poper IN s_poper.
        APPEND INITIAL LINE TO lt_zgtt_company ASSIGNING FIELD-SYMBOL(<ls_zgtt_company>).
        <ls_zgtt_company>-bukrs = <ls_finsc_ld_cmp>-bukrs.
        <ls_zgtt_company>-ledger = <ls_finsc_ld_cmp>-rldnr.
        <ls_zgtt_company>-posting_date = lv_start_date.
        <ls_zgtt_company>-gjahr = lv_gjahr.
        <ls_zgtt_company>-poper = lv_poper.      " Standard periods 001 to 012
        <ls_zgtt_company>-periv = <ls_finsc_ld_cmp>-periv.
        <ls_zgtt_company>-ktopl = <ls_finsc_ld_cmp>-ktopl.
        <ls_zgtt_company>-rhcur = <ls_finsc_ld_cmp>-rhcur.
        <ls_zgtt_company>-rkcur = <ls_finsc_ld_cmp>-rkcur.
        IF lv_poper = '001'.
*         Opening Balance period, needed for Retained Earnings Account
          ASSIGN <ls_zgtt_company> TO FIELD-SYMBOL(<ls_zgtt_company_copy>).
          APPEND INITIAL LINE TO lt_zgtt_company ASSIGNING <ls_zgtt_company>.
          <ls_zgtt_company> = <ls_zgtt_company_copy>.
          <ls_zgtt_company>-poper = '000'.         " Opening Balance period 000
        ENDIF.
        IF lv_poper = '012'.
*         The 'Special' periods, 013 to 016 are copies of period 012
          ASSIGN <ls_zgtt_company> TO <ls_zgtt_company_copy>.
          APPEND INITIAL LINE TO lt_zgtt_company ASSIGNING <ls_zgtt_company>.
          <ls_zgtt_company> = <ls_zgtt_company_copy>.
          <ls_zgtt_company>-poper = '013'.         " Special period 013
          APPEND INITIAL LINE TO lt_zgtt_company ASSIGNING <ls_zgtt_company>.
          <ls_zgtt_company> = <ls_zgtt_company_copy>.
          <ls_zgtt_company>-poper = '014'.         " Special period 014
          APPEND INITIAL LINE TO lt_zgtt_company ASSIGNING <ls_zgtt_company>.
          <ls_zgtt_company> = <ls_zgtt_company_copy>.
          <ls_zgtt_company>-poper = '015'.         " Special period 015
          APPEND INITIAL LINE TO lt_zgtt_company ASSIGNING <ls_zgtt_company>.
          <ls_zgtt_company> = <ls_zgtt_company_copy>.
          <ls_zgtt_company>-poper = '016'.         " Special period 016
        ENDIF.
      ENDIF.
    ENDLOOP.
    CALL FUNCTION 'CALCULATE_DATE'
      EXPORTING
        months      = '1'
        start_date  = lv_start_date
      IMPORTING
        result_date = lv_start_date.
  ENDWHILE.

  SORT lt_zgtt_company BY bukrs ledger gjahr poper.

  DELETE FROM zgtt_company.
  INSERT zgtt_company FROM TABLE @lt_zgtt_company.

ENDFORM.      " populate_gtt_company
*&---------------------------------------------------------------------*
*& Form get_exchange_rate
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM get_exchange_rate  USING    pv_bukrs         TYPE bukrs
                        CHANGING pv_rocur         TYPE tcurr-fcurr.

* Get the foreign currency  when company code changes
  SELECT
    FROM acdoca
  FIELDS DISTINCT rocur
   WHERE rbukrs = @pv_bukrs
     AND rocur <> ''
    INTO TABLE @DATA(lt_currency).

  pv_rocur = lt_currency[ 1 ]-rocur.
  IF lines( lt_currency ) > 1 AND pv_rocur = 'MYR'.
    pv_rocur = lt_currency[ 2 ]-rocur.
  ENDIF.

ENDFORM.      " get_exchange_rate
