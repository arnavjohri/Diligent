*&---------------------------------------------------------------------*
*& Class          : ZCL_SLDI_ITEM_TF
*& Title          : Subsidiary schedules - AMDP for ZI_SLDI_ITEM_TF
*& Project        : OVL                           Module: FI-GL
*& Related FS     : SAP_FIORI_-_Subsidiaries_Loan_and_Deemed_Investment_
*&                  Schedule_-_Annual_FY26.xlsx
*& Author         : Arnav Johri                   Date: 20.11.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Object 4 of 5. Reads the ACDOCA lines of the G/L accounts listed in
*&   ZFI_SLDI_ROW and gives each line its schedule row (first matching
*&   ZFI_SLDI_ROW rule) and its movement column (first matching
*&   ZFI_SLDI_MOV rule). Opening = posted before the From date and not
*&   cleared before it; movement = posted From..To; closing = posted up
*&   to the To date and not cleared by it (FBL3N open items logic).
*&
*& CHANGE HISTORY
*&   20.11.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*
* ASSUMPTION: leading ledger is 0L (S/4 standard ID).
* ASSUMPTION: USD is the global currency of ACDOCA (KSL / RKCUR), as
*   confirmed for company code OVL on 10/11/26 (bank revaluation).
* ASSUMPTION: ACDOCA holds the line items FBL3N shows, with AUGDT on
*   cleared open items. If AUGDT is empty there, cleared items count as
*   open and the figures become plain G/L balances from line items.
* ASSUMPTION: a rule word matches when the item text CONTAINS it, upper
*   and lower case ignored; * inside the word stands for any characters.
* ASSUMPTION: a line no ZFI_SLDI_MOV rule matches is column 1 when it is
*   a debit, column 2 when it is a credit on the Loan / Interest
*   schedules, and 9 (unclassified) when it is a credit on the Deemed
*   Investment schedule.
* ASSUMPTION: a line of a mapped G/L that matches no ZFI_SLDI_ROW rule
*   is kept on row 99 'Unassigned' of that G/L's schedule, not dropped.
CLASS zcl_sldi_item_tf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_amdp_marker_hdb.

    CLASS-METHODS get_items
      FOR TABLE FUNCTION zi_sldi_item_tf.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_sldi_item_tf IMPLEMENTATION.


  METHOD get_items
    BY DATABASE FUNCTION
    FOR HDB
    LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING acdoca zfi_sldi_row zfi_sldi_mov.

    -- one schedule per mapped G/L account (for lines no rule matches)
    lt_gl =
      SELECT mandt, bukrs, saknr, MIN( sched ) AS sched
        FROM zfi_sldi_row
       WHERE mandt = :p_clnt
       GROUP BY mandt, bukrs, saknr;

    -- relevant line items: open at From date, posted in period, or
    -- open at To date
    lt_item =
      SELECT a.rclnt, a.rbukrs, a.gjahr, a.belnr, a.docln, a.racct,
             a.budat, a.augdt, a.blart, a.drcrk, a.sgtxt, a.zuonr,
             a.rassc, a.gkont, a.rhcur, a.rkcur, a.hsl, a.ksl,
             g.sched AS gl_sched
        FROM acdoca AS a
       INNER JOIN :lt_gl AS g
          ON  g.mandt = a.rclnt
          AND g.bukrs = a.rbukrs
          AND g.saknr = a.racct
       WHERE a.rclnt = :p_clnt
         AND a.rldnr = '0L'
         AND a.poper <> '000'
         AND a.budat <= :p_to
         AND ( a.budat >= :p_from
            OR a.augdt <  '19000101'
            OR a.augdt >= :p_from );

    -- schedule row: first matching rule of ZFI_SLDI_ROW
    lt_row =
      SELECT i.rclnt, i.rbukrs, i.gjahr, i.belnr, i.docln, i.racct,
             i.budat, i.augdt, i.blart, i.drcrk, i.sgtxt, i.zuonr,
             i.rassc, i.gkont, i.rhcur, i.rkcur, i.hsl, i.ksl,
             COALESCE( r.sched, i.gl_sched )                          AS sched,
             COALESCE( r.rowno, CAST( '99' AS NVARCHAR(2) ) )         AS rowno,
             COALESCE( r.rowtxt, CAST( 'Unassigned' AS NVARCHAR(60) ) ) AS rowtxt,
             COALESCE( r.provflag, CAST( '' AS NVARCHAR(1) ) )        AS provflag,
             ROW_NUMBER() OVER ( PARTITION BY i.rbukrs, i.gjahr, i.belnr, i.docln
                                 ORDER BY r.seqno )                   AS rn
        FROM :lt_item AS i
        LEFT OUTER JOIN zfi_sldi_row AS r
          ON  r.mandt = i.rclnt
          AND r.bukrs = i.rbukrs
          AND r.saknr = i.racct
          AND ( LENGTH( RTRIM( r.txtpat ) ) = 0
             OR UPPER( i.sgtxt ) LIKE
                '%' || REPLACE( UPPER( RTRIM( r.txtpat ) ), '*', '%' ) || '%' );

    -- movement column: first matching rule of ZFI_SLDI_MOV
    lt_mov =
      SELECT w.rclnt, w.rbukrs, w.gjahr, w.belnr, w.docln, w.racct,
             w.budat, w.augdt, w.blart, w.drcrk, w.sgtxt, w.zuonr,
             w.rassc, w.gkont, w.rhcur, w.rkcur, w.hsl, w.ksl,
             w.sched, w.rowno, w.rowtxt, w.provflag,
             m.movcol                                                 AS movcol,
             ROW_NUMBER() OVER ( PARTITION BY w.rbukrs, w.gjahr, w.belnr, w.docln
                                 ORDER BY m.seqno )                   AS rn2
        FROM :lt_row AS w
        LEFT OUTER JOIN zfi_sldi_mov AS m
          ON  m.mandt = w.rclnt
          AND m.bukrs = w.rbukrs
          AND m.sched = w.sched
          AND ( LENGTH( RTRIM( m.shkzg ) ) = 0 OR m.shkzg = w.drcrk )
          AND ( LENGTH( RTRIM( m.txtpat ) ) = 0
             OR UPPER( w.sgtxt ) LIKE
                '%' || REPLACE( UPPER( RTRIM( m.txtpat ) ), '*', '%' ) || '%' )
       WHERE w.rn = 1;

    RETURN
      SELECT rclnt                                            AS mandt,
             rbukrs                                           AS company_code,
             gjahr                                            AS fiscal_year,
             belnr                                            AS accounting_doc,
             docln                                            AS ledger_gl_item,
             racct                                            AS gl_account,
             sched                                            AS schedule,
             rowno                                            AS row_no,
             rowtxt                                           AS row_text,
             provflag                                         AS is_provision,
             CAST( CASE
                     WHEN movcol IS NOT NULL THEN movcol
                     WHEN drcrk = 'S'        THEN '1'
                     WHEN sched = 'D'        THEN '9'
                     ELSE                         '2'
                   END AS NVARCHAR(1) )                       AS movement_column,
             budat                                            AS posting_date,
             augdt                                            AS clearing_date,
             blart                                            AS document_type,
             drcrk                                            AS debit_credit,
             sgtxt                                            AS item_text,
             zuonr                                            AS assignment,
             rassc                                            AS partner_company,
             gkont                                            AS offsetting_account,
             rhcur                                            AS co_code_currency,
             rkcur                                            AS global_currency,
             CAST( CASE
                     WHEN budat < :p_from
                      AND ( augdt < '19000101' OR augdt >= :p_from )
                     THEN ksl ELSE 0
                   END AS DECIMAL(23,2) )                     AS opening_usd,
             CAST( CASE
                     WHEN budat >= :p_from THEN ksl ELSE 0
                   END AS DECIMAL(23,2) )                     AS movement_usd,
             CAST( CASE
                     WHEN augdt < '19000101' OR augdt > :p_to
                     THEN ksl ELSE 0
                   END AS DECIMAL(23,2) )                     AS closing_usd,
             CAST( CASE
                     WHEN budat >= :p_from THEN hsl ELSE 0
                   END AS DECIMAL(23,2) )                     AS movement_inr
        FROM :lt_mov
       WHERE rn2 = 1;

  ENDMETHOD.
ENDCLASS.
