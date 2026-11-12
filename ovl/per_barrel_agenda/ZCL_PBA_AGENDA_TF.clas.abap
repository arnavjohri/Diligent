CLASS zcl_pba_agenda_tf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

*----------------------------------------------------------------------*
* Object    : ZCL_PBA_AGENDA_TF (global class, AMDP)
* Title     : Per barrel analysis - implementation of the CDS table
*             function ZI_PBA_AGENDA_TF
* Project   : OVL                                   Module: FI-JVA
* Source    : Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx, sheet PBA
* Author    : Arnav Johri                            Date: 10.11.2026
* Transport : <TR>
*----------------------------------------------------------------------*
* DESCRIPTION
*   Reads ZFI_AGENDA, the table in which ZFI_PL (Profitability
*   Analysis) saves its last run per project, and returns it in a form
*   CDS views can work with:
*   - the value columns CRUDE_OIL1..4 / GAS1..4 are DF34_DEC in the
*     table; they are returned as DEC 16,5 (LINE_VALUE)
*   - the four column sets (FISCALn / PERIODn / CRUDE_OILn / GASn)
*     become rows, one per fiscal year and period
*   - the oil column and the gas column become two rows, PRODUCT OIL
*     and PRODUCT GAS
*   - QUANTITY_MN: the oil value divided by 1,000,000, the gas value
*     as stored. ZFI_PL keeps oil quantities in bbl and gas quantities
*     in million MMBTU, so this column holds both in millions.
*   A later column set that repeats the year and period of an earlier
*   one is left out (ZFI_PL fills two sets with the same selection when
*   it is run that way).
*
*   12.11.2026: the quarters ZFI_PL does not save are worked out here,
*   so that one ZFI_PL run per project with Q1, H1, 9M and ANNUAL as
*   its four columns gives all seven periods of the year:
*     Q2 = H1 - Q1,  Q3 = 9M - H1,  Q4 = ANNUAL - 9M
*   for every line of section A2 and the three quantity lines of A1 the
*   report uses. A quarter ZFI_PL itself saved is taken as saved.
*
* CHANGE HISTORY
*   10.11.2026  Arnav Johri  <TR>  Initial development
*   12.11.2026  Arnav Johri  <TR>  Q2, Q3, Q4 derived from the saved
*                                  cumulative periods
*----------------------------------------------------------------------*
* ASSUMPTION: FISCALn above 0000 marks a column set that is in use.
* ASSUMPTION: when a row repeats a year and period in a later column
*   set, both sets carry the same figures (true for all 1,547 rows
*   checked on 10/11/26).
* ASSUMPTION: a quarter is the difference of two cumulative periods,
*   as the board workbook does it (its Q4 = Annual - 9M). Stock lines
*   of A1 and the per-barrel lines of A3 are not differenced.
*----------------------------------------------------------------------*

  PUBLIC SECTION.

    INTERFACES if_amdp_marker_hdb.

    CLASS-METHODS get_lines
      FOR TABLE FUNCTION zi_pba_agenda_tf.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_pba_agenda_tf IMPLEMENTATION.


  METHOD get_lines
    BY DATABASE FUNCTION
    FOR HDB
    LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING zfi_agenda.

--BOC By Arnav on 12/11/26
--  RETURN
    lt_base =
--EOC By Arnav on 12/11/26
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal1                                     AS fiscal_year,
             period1                                     AS report_period,
             CAST( 'OIL' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( crude_oil1, 16, 5 )             AS line_value,
             TO_DECIMAL( crude_oil1 * 0.000001, 23, 11 ) AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal1 > '0000'
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal1                                     AS fiscal_year,
             period1                                     AS report_period,
             CAST( 'GAS' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( gas1, 16, 5 )                   AS line_value,
             TO_DECIMAL( gas1, 23, 11 )                  AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal1 > '0000'
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal2                                     AS fiscal_year,
             period2                                     AS report_period,
             CAST( 'OIL' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( crude_oil2, 16, 5 )             AS line_value,
             TO_DECIMAL( crude_oil2 * 0.000001, 23, 11 ) AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal2 > '0000'
         AND ( fiscal2 <> fiscal1 OR period2 <> period1 )
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal2                                     AS fiscal_year,
             period2                                     AS report_period,
             CAST( 'GAS' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( gas2, 16, 5 )                   AS line_value,
             TO_DECIMAL( gas2, 23, 11 )                  AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal2 > '0000'
         AND ( fiscal2 <> fiscal1 OR period2 <> period1 )
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal3                                     AS fiscal_year,
             period3                                     AS report_period,
             CAST( 'OIL' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( crude_oil3, 16, 5 )             AS line_value,
             TO_DECIMAL( crude_oil3 * 0.000001, 23, 11 ) AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal3 > '0000'
         AND ( fiscal3 <> fiscal1 OR period3 <> period1 )
         AND ( fiscal3 <> fiscal2 OR period3 <> period2 )
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal3                                     AS fiscal_year,
             period3                                     AS report_period,
             CAST( 'GAS' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( gas3, 16, 5 )                   AS line_value,
             TO_DECIMAL( gas3, 23, 11 )                  AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal3 > '0000'
         AND ( fiscal3 <> fiscal1 OR period3 <> period1 )
         AND ( fiscal3 <> fiscal2 OR period3 <> period2 )
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal4                                     AS fiscal_year,
             period4                                     AS report_period,
             CAST( 'OIL' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( crude_oil4, 16, 5 )             AS line_value,
             TO_DECIMAL( crude_oil4 * 0.000001, 23, 11 ) AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal4 > '0000'
         AND ( fiscal4 <> fiscal1 OR period4 <> period1 )
         AND ( fiscal4 <> fiscal2 OR period4 <> period2 )
         AND ( fiscal4 <> fiscal3 OR period4 <> period3 )
      UNION ALL
      SELECT mandt                                       AS mandt,
             comp                                        AS company_code,
             proj                                        AS joint_venture,
             per_key                                     AS report_section,
             per                                         AS line_text,
             fiscal4                                     AS fiscal_year,
             period4                                     AS report_period,
             CAST( 'GAS' AS NVARCHAR(3) )                AS product,
             TO_DECIMAL( gas4, 16, 5 )                   AS line_value,
             TO_DECIMAL( gas4, 23, 11 )                  AS quantity_mn
        FROM zfi_agenda
       WHERE mandt = :p_clnt
         AND fiscal4 > '0000'
         AND ( fiscal4 <> fiscal1 OR period4 <> period1 )
         AND ( fiscal4 <> fiscal2 OR period4 <> period2 )
         AND ( fiscal4 <> fiscal3 OR period4 <> period3 );

--BOC By Arnav on 12/11/26
    RETURN
      SELECT mandt                                       AS mandt,
             company_code                                AS company_code,
             joint_venture                               AS joint_venture,
             report_section                              AS report_section,
             line_text                                   AS line_text,
             fiscal_year                                 AS fiscal_year,
             report_period                               AS report_period,
             product                                     AS product,
             line_value                                  AS line_value,
             quantity_mn                                 AS quantity_mn
        FROM :lt_base
      UNION ALL
      SELECT c.mandt                                     AS mandt,
             c.company_code                              AS company_code,
             c.joint_venture                             AS joint_venture,
             c.report_section                            AS report_section,
             c.line_text                                 AS line_text,
             c.fiscal_year                               AS fiscal_year,
             CAST( 'Q2' AS NVARCHAR(6) )                 AS report_period,
             c.product                                   AS product,
             TO_DECIMAL( c.line_value - p.line_value, 16, 5 )    AS line_value,
             TO_DECIMAL( c.quantity_mn - p.quantity_mn, 23, 11 ) AS quantity_mn
        FROM :lt_base AS c
       INNER JOIN :lt_base AS p
          ON  p.mandt          = c.mandt
          AND p.company_code   = c.company_code
          AND p.joint_venture  = c.joint_venture
          AND p.report_section = c.report_section
          AND p.line_text      = c.line_text
          AND p.fiscal_year    = c.fiscal_year
          AND p.product        = c.product
          AND p.report_period  = 'Q1'
        LEFT OUTER JOIN :lt_base AS s
          ON  s.mandt          = c.mandt
          AND s.company_code   = c.company_code
          AND s.joint_venture  = c.joint_venture
          AND s.report_section = c.report_section
          AND s.line_text      = c.line_text
          AND s.fiscal_year    = c.fiscal_year
          AND s.product        = c.product
          AND s.report_period  = 'Q2'
       WHERE c.report_period = 'H1'
         AND s.mandt IS NULL
         AND ( c.report_section = 'A2'
            OR ( c.report_section = 'A1'
                 AND c.line_text IN ( 'Share of Production',
                                      'Total Sales quantity',
                                      'Total Sales quantity-net of state share (13-3a)' ) ) )
      UNION ALL
      SELECT c.mandt                                     AS mandt,
             c.company_code                              AS company_code,
             c.joint_venture                             AS joint_venture,
             c.report_section                            AS report_section,
             c.line_text                                 AS line_text,
             c.fiscal_year                               AS fiscal_year,
             CAST( 'Q3' AS NVARCHAR(6) )                 AS report_period,
             c.product                                   AS product,
             TO_DECIMAL( c.line_value - p.line_value, 16, 5 )    AS line_value,
             TO_DECIMAL( c.quantity_mn - p.quantity_mn, 23, 11 ) AS quantity_mn
        FROM :lt_base AS c
       INNER JOIN :lt_base AS p
          ON  p.mandt          = c.mandt
          AND p.company_code   = c.company_code
          AND p.joint_venture  = c.joint_venture
          AND p.report_section = c.report_section
          AND p.line_text      = c.line_text
          AND p.fiscal_year    = c.fiscal_year
          AND p.product        = c.product
          AND p.report_period  = 'H1'
        LEFT OUTER JOIN :lt_base AS s
          ON  s.mandt          = c.mandt
          AND s.company_code   = c.company_code
          AND s.joint_venture  = c.joint_venture
          AND s.report_section = c.report_section
          AND s.line_text      = c.line_text
          AND s.fiscal_year    = c.fiscal_year
          AND s.product        = c.product
          AND s.report_period  = 'Q3'
       WHERE c.report_period = '9M'
         AND s.mandt IS NULL
         AND ( c.report_section = 'A2'
            OR ( c.report_section = 'A1'
                 AND c.line_text IN ( 'Share of Production',
                                      'Total Sales quantity',
                                      'Total Sales quantity-net of state share (13-3a)' ) ) )
      UNION ALL
      SELECT c.mandt                                     AS mandt,
             c.company_code                              AS company_code,
             c.joint_venture                             AS joint_venture,
             c.report_section                            AS report_section,
             c.line_text                                 AS line_text,
             c.fiscal_year                               AS fiscal_year,
             CAST( 'Q4' AS NVARCHAR(6) )                 AS report_period,
             c.product                                   AS product,
             TO_DECIMAL( c.line_value - p.line_value, 16, 5 )    AS line_value,
             TO_DECIMAL( c.quantity_mn - p.quantity_mn, 23, 11 ) AS quantity_mn
        FROM :lt_base AS c
       INNER JOIN :lt_base AS p
          ON  p.mandt          = c.mandt
          AND p.company_code   = c.company_code
          AND p.joint_venture  = c.joint_venture
          AND p.report_section = c.report_section
          AND p.line_text      = c.line_text
          AND p.fiscal_year    = c.fiscal_year
          AND p.product        = c.product
          AND p.report_period  = '9M'
        LEFT OUTER JOIN :lt_base AS s
          ON  s.mandt          = c.mandt
          AND s.company_code   = c.company_code
          AND s.joint_venture  = c.joint_venture
          AND s.report_section = c.report_section
          AND s.line_text      = c.line_text
          AND s.fiscal_year    = c.fiscal_year
          AND s.product        = c.product
          AND s.report_period  = 'Q4'
       WHERE c.report_period = 'ANNUAL'
         AND s.mandt IS NULL
         AND ( c.report_section = 'A2'
            OR ( c.report_section = 'A1'
                 AND c.line_text IN ( 'Share of Production',
                                      'Total Sales quantity',
                                      'Total Sales quantity-net of state share (13-3a)' ) ) );
--EOC By Arnav on 12/11/26

  ENDMETHOD.
ENDCLASS.
