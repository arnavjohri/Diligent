//----------------------------------------------------------------------
// Object    : ZI_PBA_CUBE (DDL source, classic view, cube)
// Title     : Per barrel analysis: revenue, costs and quantities per
//             project (cube for Custom Analytical Queries)
// Project   : OVL                                   Module: FI-JVA
// Source    : Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx, sheet PBA
// Author    : Arnav Johri                            Date: 10.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 4 of 4 for the Per Barrel Analysis report: the data source
//   the functional consultant picks in the Fiori app Custom Analytical
//   Queries. One row per company code / joint venture / product /
//   fiscal year / period / ZFI_PL line, taken from ZI_PBA_ITEM.
//   MEASURES - the inputs of the PBA sheet, each filled on the rows of
//   its ZFI_PL lines and zero elsewhere, so a query that does not show
//   ZFI_PL Line gets the total per project and period:
//     RevenueAmount        REVENUE FROM CRUDE OIL (product OIL),
//                          REVENUE FROM NATURAL GAS (product GAS)
//     ProductionCostAmount PRODUCTION EXPENSES + OTHER OPERATING EXPENSE
//     RoyaltyAmount        ROYALTY + OTHER TAXES (AS APPLICABLE)
//     TransportAmount      TRANSPORTATION EXPENSES
//     DdaAmount            DEPLETION + DEPRECIATION AND AMORTISATION
//     SurveyAmount         EXPLORATION COSTS (SURVEY) + (DRY WELL)
//     ProductionQuantity   Share of Production
//     SalesQuantity        Total Sales quantity
//     SalesQuantityNet     Total Sales quantity-net of state share
//   Amounts are USD million as ZFI_PL saves them. Quantities are in
//   millions: million bbl for OIL, million MMBTU for GAS. Amount
//   divided by quantity is therefore USD per bbl / USD per MMBTU.
//   PER-BARREL FIGURES are calculated measures of the query, so that a
//   total row is a weighted average as on the sheet:
//     Realised price   = RevenueAmount        / SalesQuantityNet
//     Production cost  = ProductionCostAmount / ProductionQuantity
//     Royalty          = RoyaltyAmount        / ProductionQuantity
//     Transportation   = TransportAmount      / SalesQuantityNet
//     DD&A             = DdaAmount            / ProductionQuantity
//     Survey           = SurveyAmount         / ProductionQuantity
//     Cost of goods sold = the five cost figures added
//     Profit           = Realised price - Cost of goods sold
//   LineValue with the dimensions ZFI_PL Section and ZFI_PL Line gives
//   any other ZFI_PL line (income tax, net profit, closing stock ...):
//   restrict it to one section and one line. Unrestricted it adds
//   quantities, amounts and per-barrel values together and means
//   nothing.
//   Always filter or show Product: OIL and GAS quantities are different
//   units.
//   Annotation set copied from ZI_JIB_STATUS_CUBE (listed by the app
//   after the C1 release). After activation: ADT, Properties, API
//   State, Add Release State, contract Use in Key User Apps (C1).
//
// CHANGE HISTORY
//   10.11.2026  Arnav Johri  <TR>  Initial development
//   12.11.2026  Arnav Johri  <TR>  Period No. for the order of the
//                                  periods (Q1, Q2, H1, Q3, 9M, Q4,
//                                  Annual)
//----------------------------------------------------------------------
// ASSUMPTION: Project Name and Report Row are the row texts of the PBA
//   sheet, matched to the ZFI_PL project by revenue on 10/11/26 (RU2002
//   = Sakhalin-1 by its code, all figures zero). MM2002 and MM2012 are
//   one sheet row. A project not in the list shows NOT MAPPED and
//   Report Row No. 99; its JV Code is still shown.
// ASSUMPTION: Report Row No. is the sheet's serial number, which differs
//   between the oil table and the gas table.
// ASSUMPTION: Fiscal Year is the start year as ZFI_PL saves it (2025 =
//   2025-26); the text covers 2014 to 2040.
// ASSUMPTION: gas quantities are saved in million MMBTU and oil
//   quantities in bbl (Myanmar and Vankor gas sales equal the workbook,
//   10/11/26).
// ASSUMPTION: no access control, as on the earlier cubes. The published
//   query runs with the user's analytics authorisations.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIPBACUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Per barrel analysis (cube)'
@VDM.viewType: #COMPOSITE
@Analytics.dataCategory: #CUBE
@ObjectModel.modelingPattern: #ANALYTICAL_CUBE
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_PROVIDER,
                                      #CDS_MODELING_DATA_SOURCE,
                                      #CDS_MODELING_ASSOCIATION_TARGET,
                                      #SQL_DATA_SOURCE ]
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType.sizeCategory: #M
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MIXED
define view ZI_PBA_CUBE
  as select from ZI_PBA_ITEM as Item
{
      // -- keys ----------------------------------------------------------
      @EndUserText.label: 'Company Code'
  key Item.CompanyCode,
      @ObjectModel.text.element: ['ProjectName']
      @EndUserText.label: 'JV Code'
  key Item.JointVenture,
      @ObjectModel.text.element: ['ProductName']
      @EndUserText.label: 'Product'
  key Item.Product,
      @ObjectModel.text.element: ['FiscalYearName']
      @EndUserText.label: 'Fiscal Year'
  key Item.FiscalYear,
      @EndUserText.label: 'Reporting Period'
  key Item.ReportingPeriod,
      @EndUserText.label: 'ZFI_PL Section'
  key Item.ReportSection,
      @EndUserText.label: 'ZFI_PL Line'
  key Item.LineText,

      // -- project texts, as on the PBA sheet ------------------------------
      @EndUserText.label: 'Project Name'
      case Item.JointVenture
        when 'AA2002' then 'ACG, AZERBAIJAN'
        when 'BC10'   then 'BLOCK BC-10, BRAZIL'
        when 'CL1202' then 'CPO-5, COLOMBIA'
        when 'GPOC'   then 'GPOC, SOUTH SUDAN'
        when 'IEL'    then 'IMPERIAL ENERGY, RUSSIA'
        when 'LZ'     then 'LOWER ZAKUM, UAE'
        when 'MECL'   then 'MECL, COLOMBIA'
        when 'MM2002' then 'BLOCK A-1, MYANMAR'
        when 'MM2012' then 'BLOCK A-3, MYANMAR'
        when 'PCSA'   then 'CARABOBO, VENEZUELA'
        when 'PIVSA'  then 'PIVSA SANCRISTOBAL, VENEZUELA'
        when 'RU2002' then 'SAKHALIN - 1, RUSSIA'
        when 'SD2002' then 'BLOCK 5A (SPOC), SOUTH SUDAN'
        when 'VANKOR' then 'VANKORNEFT, RUSSIA'
        when 'VN2012' then 'BLOCK 06.1, VIETNAM'
        else               'NOT MAPPED'
      end                                              as ProjectName,
      // the sheet's row: Myanmar A-1 and A-3 are one row
      @EndUserText.label: 'Report Row'
      case Item.JointVenture
        when 'AA2002' then 'ACG, AZERBAIJAN'
        when 'BC10'   then 'BLOCK BC-10, BRAZIL'
        when 'CL1202' then 'CPO-5, COLOMBIA'
        when 'GPOC'   then 'GPOC, SOUTH SUDAN'
        when 'IEL'    then 'IMPERIAL ENERGY, RUSSIA'
        when 'LZ'     then 'LOWER ZAKUM, UAE'
        when 'MECL'   then 'MECL, COLOMBIA'
        when 'MM2002' then 'BLOCK A-1 & A-3, MYANMAR'
        when 'MM2012' then 'BLOCK A-1 & A-3, MYANMAR'
        when 'PCSA'   then 'CARABOBO, VENEZUELA'
        when 'PIVSA'  then 'PIVSA SANCRISTOBAL, VENEZUELA'
        when 'RU2002' then 'SAKHALIN - 1, RUSSIA'
        when 'SD2002' then 'BLOCK 5A (SPOC), SOUTH SUDAN'
        when 'VANKOR' then 'VANKORNEFT, RUSSIA'
        when 'VN2012' then 'BLOCK 06.1, VIETNAM'
        else               'NOT MAPPED'
      end                                              as ReportRow,
      // the sheet's serial number, for sorting in the sheet's order
      @EndUserText.label: 'Report Row No.'
      case Item.Product
        when 'OIL' then
          case Item.JointVenture
            when 'PIVSA'  then '02'
            when 'SD2002' then '04'
            when 'VN2012' then '05'
            when 'BC10'   then '06'
            when 'IEL'    then '07'
            when 'MECL'   then '08'
            when 'RU2002' then '09'
            when 'AA2002' then '10'
            when 'GPOC'   then '11'
            when 'PCSA'   then '12'
            when 'LZ'     then '13'
            when 'CL1202' then '14'
            when 'VANKOR' then '16'
            else               '99'
          end
        else
          case Item.JointVenture
            when 'VN2012' then '01'
            when 'RU2002' then '02'
            when 'MM2002' then '04'
            when 'MM2012' then '04'
            when 'IEL'    then '05'
            when 'BC10'   then '06'
            when 'VANKOR' then '07'
            else               '99'
          end
      end                                              as ReportRowNumber,

//BOC By Arnav on 12/11/26
      // the period's place in the year, for columns in the sheet's order
      @EndUserText.label: 'Period No.'
      case Item.ReportingPeriod
        when 'Q1'     then '1'
        when 'Q2'     then '2'
        when 'H1'     then '3'
        when 'Q3'     then '4'
        when '9M'     then '5'
        when 'Q4'     then '6'
        when 'ANNUAL' then '7'
        else               '9'
      end                                              as ReportingPeriodNumber,
//EOC By Arnav on 12/11/26

      // -- product and year texts ------------------------------------------
      @EndUserText.label: 'Product Name'
      case Item.Product
        when 'OIL' then 'Crude Oil'
        when 'GAS' then 'Natural Gas'
        else            ' '
      end                                              as ProductName,
      @EndUserText.label: 'Financial Year'
      case Item.FiscalYear
        when '2014' then '2014-15'
        when '2015' then '2015-16'
        when '2016' then '2016-17'
        when '2017' then '2017-18'
        when '2018' then '2018-19'
        when '2019' then '2019-20'
        when '2020' then '2020-21'
        when '2021' then '2021-22'
        when '2022' then '2022-23'
        when '2023' then '2023-24'
        when '2024' then '2024-25'
        when '2025' then '2025-26'
        when '2026' then '2026-27'
        when '2027' then '2027-28'
        when '2028' then '2028-29'
        when '2029' then '2029-30'
        when '2030' then '2030-31'
        when '2031' then '2031-32'
        when '2032' then '2032-33'
        when '2033' then '2033-34'
        when '2034' then '2034-35'
        when '2035' then '2035-36'
        when '2036' then '2036-37'
        when '2037' then '2037-38'
        when '2038' then '2038-39'
        when '2039' then '2039-40'
        when '2040' then '2040-41'
        else             ' '
      end                                              as FiscalYearName,

      // -- measures: amounts, USD million ----------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Revenue (USD mn)'
      case Item.ReportSection
        when 'A2' then
          case Item.Product
            when 'OIL' then
              case Item.LineText
                when 'REVENUE FROM CRUDE OIL' then Item.LineValue
                else cast( 0 as abap.dec( 16, 5 ) )
              end
            else
              case Item.LineText
                when 'REVENUE FROM NATURAL GAS' then Item.LineValue
                else cast( 0 as abap.dec( 16, 5 ) )
              end
          end
        else cast( 0 as abap.dec( 16, 5 ) )
      end                                              as RevenueAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Production Cost (USD mn)'
      case Item.ReportSection
        when 'A2' then
          case Item.LineText
            when 'PRODUCTION EXPENSES'     then Item.LineValue
            when 'OTHER OPERATING EXPENSE' then Item.LineValue
            else cast( 0 as abap.dec( 16, 5 ) )
          end
        else cast( 0 as abap.dec( 16, 5 ) )
      end                                              as ProductionCostAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Royalty and Taxes (USD mn)'
      case Item.ReportSection
        when 'A2' then
          case Item.LineText
            when 'ROYALTY'                     then Item.LineValue
            when 'OTHER TAXES (AS APPLICABLE)' then Item.LineValue
            else cast( 0 as abap.dec( 16, 5 ) )
          end
        else cast( 0 as abap.dec( 16, 5 ) )
      end                                              as RoyaltyAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Transportation (USD mn)'
      case Item.ReportSection
        when 'A2' then
          case Item.LineText
            when 'TRANSPORTATION EXPENSES' then Item.LineValue
            else cast( 0 as abap.dec( 16, 5 ) )
          end
        else cast( 0 as abap.dec( 16, 5 ) )
      end                                              as TransportAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Depletion and Depreciation (USD mn)'
      case Item.ReportSection
        when 'A2' then
          case Item.LineText
            when 'DEPLETION'                     then Item.LineValue
            when 'DEPRECIATION AND AMORTISATION' then Item.LineValue
            else cast( 0 as abap.dec( 16, 5 ) )
          end
        else cast( 0 as abap.dec( 16, 5 ) )
      end                                              as DdaAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Survey and Dry Well (USD mn)'
      case Item.ReportSection
        when 'A2' then
          case Item.LineText
            when 'EXPLORATION COSTS (SURVEY)'   then Item.LineValue
            when 'EXPLORATION COSTS (DRY WELL)' then Item.LineValue
            else cast( 0 as abap.dec( 16, 5 ) )
          end
        else cast( 0 as abap.dec( 16, 5 ) )
      end                                              as SurveyAmount,

      // -- measures: quantities, million bbl (OIL) / million MMBTU (GAS) ---
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Production Quantity (mn)'
      case Item.ReportSection
        when 'A1' then
          case Item.LineText
            when 'Share of Production'
              then Item.QuantityMillion
            else cast( 0 as abap.dec( 23, 11 ) )
          end
        else cast( 0 as abap.dec( 23, 11 ) )
      end                                              as ProductionQuantity,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Sales Quantity (mn)'
      case Item.ReportSection
        when 'A1' then
          case Item.LineText
            when 'Total Sales quantity'
              then Item.QuantityMillion
            else cast( 0 as abap.dec( 23, 11 ) )
          end
        else cast( 0 as abap.dec( 23, 11 ) )
      end                                              as SalesQuantity,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Sales Qty Net of State Share (mn)'
      case Item.ReportSection
        when 'A1' then
          case Item.LineText
            when 'Total Sales quantity-net of state share (13-3a)'
              then Item.QuantityMillion
            else cast( 0 as abap.dec( 23, 11 ) )
          end
        else cast( 0 as abap.dec( 23, 11 ) )
      end                                              as SalesQuantityNet,

      // -- any ZFI_PL line: restrict to one ZFI_PL Section and Line --------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'ZFI_PL Line Value'
      Item.LineValue
}
