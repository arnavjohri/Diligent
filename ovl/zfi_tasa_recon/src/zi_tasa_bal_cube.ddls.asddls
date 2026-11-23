//----------------------------------------------------------------------
// Object    : ZI_TASA_BAL_CUBE (DDL source, classic view, cube)
// Title     : TASA recon - customer balance, provision, reclassification
//             and aging at a key date (cube for Custom Analytical Queries)
// Project   : OVL                                   Module: FI-AR
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheets
//             BS - Customer Balance (TASA) and zfi_age_31.03.2026
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   Data source of the queries "TASA Customer Balance" and "TASA
//   Customer Aging". Prompt: Key Date (31.03.2026 for FY26).
//   Balance query: rows Customer Category, Customer, Project /
//   Subsidiary; Gross Balance USD, Provision USD, Net Receivable USD,
//   Closing Rate, Net Receivable INR at closing rate (calculated in the
//   query: Net Receivable x Closing Rate, after aggregation, as bank
//   reval does), Actual G/L INR. Reclassification query block: filter
//   In Reclassification = Yes, or the Reclassification measures.
//   Aging query: the seven bucket measures (USD).
//   After activation: ADT, Properties, API State, Add Release State,
//   contract Use in Key User Apps (C1).
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: provision per customer = balance x ZFI_TASA_MAP-PROVPC %.
//   Provision G/L 190790 carries no customer (checked 23.11.2026); the
//   workbook provides only IPRNT, 100 % (query 5).
// ASSUMPTION: closing rate = exchange rate type M at the key date
//   (93.75 at 31.03.2026, valid from 30.03.2026 - same as the workbook).
// ASSUMPTION: the reclassification is displayed only; posting it to
//   100616 / 100711 stays manual (query 7).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASABALCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA customer balance and aging (cube)'
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
// Parameter typed VDM_V_KEY_DATE: Custom Analytical Queries refuses
// DATUM (MEMORY 4.1, ZI_SLDI_CUBE 23.11.2026).
define view ZI_TASA_BAL_CUBE
  with parameters
    @EndUserText.label: 'Key Date'
    P_KeyDate : vdm_v_key_date
  as select from    ZI_TASA_BAL_ITEM( P_KeyDate : $parameters.P_KeyDate ) as Item
    left outer join zfi_tasa_map                                          as Map
      on  Map.bukrs   = Item.company_code
      and Map.partner = Item.customer
  association [0..1] to I_CompanyCode as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
{
      // -- keys ----------------------------------------------------------
      @ObjectModel.foreignKey.association: '_CompanyCode'
      @EndUserText.label: 'Company Code'
  key Item.company_code                              as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Item.fiscal_year                               as FiscalYear,
      @EndUserText.label: 'Document Number'
  key Item.accounting_doc                            as AccountingDocument,
      @EndUserText.label: 'Ledger Line Item'
  key Item.ledger_gl_item                            as LedgerGLLineItem,

      // -- customer and report row -----------------------------------------
      @EndUserText.label: 'Customer'
      Item.customer                                  as Customer,
      @EndUserText.label: 'Sort No.'
      coalesce( Map.sortno, '999' )                  as SortNumber,
      @EndUserText.label: 'Project / Subsidiary'
      coalesce( Map.rowtxt, 'Not in Customer List' ) as ProjectSubsidiary,
      @EndUserText.label: 'Customer Category'
      case Map.tasafl
        when 'X' then 'TASA Customer'
        else          'Non-TASA Customer'
      end                                            as CustomerCategory,
      @EndUserText.label: 'In Reclassification'
      case Map.reclfl when 'X' then 'Yes' else 'No' end
                                                     as InReclassification,

      // -- line item attributes (drill-down) -------------------------------
      @EndUserText.label: 'G/L Account'
      Item.gl_account                                as GLAccount,
      @EndUserText.label: 'Posting Date'
      Item.posting_date                              as PostingDate,
      @EndUserText.label: 'Clearing Date'
      Item.clearing_date                             as ClearingDate,
      @EndUserText.label: 'Document Type'
      Item.document_type                             as AccountingDocumentType,
      @EndUserText.label: 'Item Text'
      Item.item_text                                 as DocumentItemText,
      @EndUserText.label: 'Assignment'
      Item.assignment                                as AssignmentReference,
      @EndUserText.label: 'Joint Venture'
      Item.joint_venture                             as JointVenture,
      @EndUserText.label: 'Company Code Currency'
      Item.co_code_currency                          as CompanyCodeCurrency,
      @EndUserText.label: 'Global Currency'
      Item.global_currency                           as GlobalCurrency,
      @EndUserText.label: 'Key Date'
      $parameters.P_KeyDate                          as KeyDate,

      // -- measures: balance -----------------------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Gross Balance (USD)'
      Item.amount_usd                                as GrossBalance,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Provision (USD)'
      case
        when Map.provpc is null then cast( 0 as abap.dec( 23, 2 ) )
        else cast( division( Item.amount_usd * Map.provpc, 100, 2 ) as abap.dec( 23, 2 ) )
      end                                            as ProvisionAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Net Receivable (USD)'
      case
        when Map.provpc is null then Item.amount_usd
        else Item.amount_usd
               - cast( division( Item.amount_usd * Map.provpc, 100, 2 ) as abap.dec( 23, 2 ) )
      end                                            as NetReceivable,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Actual G/L Balance (INR)'
      Item.amount_inr                                as GrossBalanceInCCCrcy,
      @DefaultAggregation: #MAX
      @EndUserText.label: 'Closing Rate (INR per USD)'
      cast( currency_conversion( amount             => Item.unit_usd,
                                 source_currency    => Item.global_currency,
                                 target_currency    => Item.co_code_currency,
                                 exchange_rate_type => 'M',
                                 exchange_rate_date => $parameters.P_KeyDate,
                                 round              => ' ',
                                 decimal_shift      => ' ',
                                 decimal_shift_back => ' ',
                                 error_handling     => 'SET_TO_NULL' )
            as abap.dec( 23, 10 ) )                  as ClosingRate,

      // -- measures: reclassification to 100616 / 100711 -------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Reclassification (USD)'
      case Map.reclfl
        when 'X' then Item.amount_usd
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as ReclassAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Reclassification, Actual G/L (INR)'
      case Map.reclfl
        when 'X' then Item.amount_inr
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as ReclassAmountInCCCrcy,

      // -- measures: aging by calendar months, USD (ZFI_AGE buckets) --------
      @DefaultAggregation: #SUM
      @EndUserText.label: '1 Month (USD)'
      case
        when Item.posting_date >= Item.month_0 then Item.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as Age1Month,
      @DefaultAggregation: #SUM
      @EndUserText.label: '2-3 Months (USD)'
      case
        when Item.posting_date >= Item.month_0 then cast( 0 as abap.dec( 23, 2 ) )
        when Item.posting_date >= Item.month_2 then Item.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as Age2To3Months,
      @DefaultAggregation: #SUM
      @EndUserText.label: '4-6 Months (USD)'
      case
        when Item.posting_date >= Item.month_2 then cast( 0 as abap.dec( 23, 2 ) )
        when Item.posting_date >= Item.month_5 then Item.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as Age4To6Months,
      @DefaultAggregation: #SUM
      @EndUserText.label: '6 Months - 1 Year (USD)'
      case
        when Item.posting_date >= Item.month_5  then cast( 0 as abap.dec( 23, 2 ) )
        when Item.posting_date >= Item.month_11 then Item.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as Age6MonthsTo1Year,
      @DefaultAggregation: #SUM
      @EndUserText.label: '1-2 Years (USD)'
      case
        when Item.posting_date >= Item.month_11 then cast( 0 as abap.dec( 23, 2 ) )
        when Item.posting_date >= Item.month_23 then Item.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as Age1To2Years,
      @DefaultAggregation: #SUM
      @EndUserText.label: '2-3 Years (USD)'
      case
        when Item.posting_date >= Item.month_23 then cast( 0 as abap.dec( 23, 2 ) )
        when Item.posting_date >= Item.month_35 then Item.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as Age2To3Years,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'More than 3 Years (USD)'
      case
        when Item.posting_date >= Item.month_35 then cast( 0 as abap.dec( 23, 2 ) )
        else Item.amount_usd
      end                                            as AgeOver3Years,

      // -- associations ----------------------------------------------------
      _CompanyCode
}
