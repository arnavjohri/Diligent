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
* CHANGE HISTORY
*   10.11.2026  Arnav Johri  <TR>  Initial development
*----------------------------------------------------------------------*
* ASSUMPTION: FISCALn above 0000 marks a column set that is in use.
* ASSUMPTION: when a row repeats a year and period in a later column
*   set, both sets carry the same figures (true for all 1,547 rows
*   checked on 10/11/26).
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

    RETURN
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

  ENDMETHOD.
ENDCLASS.
