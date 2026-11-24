//----------------------------------------------------------------------
// Object    : ZI_TASA_RCN_CUBE (DDL source, classic view, cube)
// Title     : TASA recon (one tile) - income, receivable, provision,
//             reclassification and aging per project / customer
// Project   : OVL                                   Module: FI-GL / FI-AR
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheets P&L-TASA,
//             BS - Customer Balance (TASA), zfi_age_31.03.2026
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   Data source of the single TASA query. Prompt: Key Date. Income =
//   fiscal year of the key date, posted up to it, per quarter (Q1-Q4 as
//   measures, so the balance columns are not split by quarter). Balance
//   and aging = open items of 91111 at the key date. Rows: Customer
//   Category, Sort No., Project / Subsidiary, Customer (partner: the
//   customer, or the G/L for Block 128). The three single cubes and
//   queries stay as they are.
//   After activation: ADT, Properties, API State, Add Release State,
//   contract Use in Key User Apps (C1).
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: as ZI_TASA_INC_CUBE / ZI_TASA_BAL_CUBE - provision =
//   balance x ZFI_TASA_MAP-PROVPC %, closing rate = type M at the key
//   date, reclassification displayed only.
// ASSUMPTION: a partner not in ZFI_TASA_MAP counts as Non-TASA.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASARCNCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: income, balance and aging (cube)'
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
define view ZI_TASA_RCN_CUBE
  with parameters
    @EndUserText.label: 'Key Date'
    P_KeyDate : vdm_v_key_date
  as select from    ZI_TASA_RCN_ITEM( P_KeyDate : $parameters.P_KeyDate ) as Item
    left outer join zfi_tasa_map                                          as Map
      on  Map.bukrs   = Item.company_code
      and Map.partner = Item.partner
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

      // -- report row ------------------------------------------------------
      @EndUserText.label: 'Customer Category'
      case Map.tasafl
        when 'X' then 'TASA Customer'
        else          'Non-TASA Customer'
      end                                            as CustomerCategory,
      @EndUserText.label: 'Sort No.'
      coalesce( Map.sortno, '999' )                  as SortNumber,
      @EndUserText.label: 'Project / Subsidiary'
      coalesce( Map.rowtxt, Item.unmapped_text )     as ProjectSubsidiary,
      @EndUserText.label: 'Customer / G/L (Partner)'
      Item.partner                                   as Customer,
      @EndUserText.label: 'Related Party'
      case Map.relpty when 'X' then 'Yes' else 'No' end
                                                     as IsRelatedParty,
      @EndUserText.label: 'In Reclassification'
      case Map.reclfl when 'X' then 'Yes' else 'No' end
                                                     as InReclassification,
      @EndUserText.label: 'Line Type'
      case Item.line_kind
        when 'I' then 'Income (230903)'
        else          'Open Item (91111)'
      end                                            as LineType,

      // -- line item attributes (drill-down) -------------------------------
      @EndUserText.label: 'Fiscal Quarter'
      Item.fiscal_quarter                            as FiscalQuarter,
      @EndUserText.label: 'G/L Account'
      Item.gl_account                                as GLAccount,
      @EndUserText.label: 'Posting Date'
      Item.posting_date                              as PostingDate,
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

      // -- measures: income, USD -------------------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q1 (USD)'
      case Item.fiscal_quarter
        when 'Q1' then Item.income_usd
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ1,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q2 (USD)'
      case Item.fiscal_quarter
        when 'Q2' then Item.income_usd
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ2,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q3 (USD)'
      case Item.fiscal_quarter
        when 'Q3' then Item.income_usd
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ3,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q4 (USD)'
      case Item.fiscal_quarter
        when 'Q4' then Item.income_usd
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ4,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Year to Date (USD)'
      Item.income_usd                                as IncomeAmount,

      // -- measures: income, INR -------------------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q1 (INR)'
      case Item.fiscal_quarter
        when 'Q1' then Item.income_inr
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ1InCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q2 (INR)'
      case Item.fiscal_quarter
        when 'Q2' then Item.income_inr
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ2InCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q3 (INR)'
      case Item.fiscal_quarter
        when 'Q3' then Item.income_inr
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ3InCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Q4 (INR)'
      case Item.fiscal_quarter
        when 'Q4' then Item.income_inr
        else           cast( 0 as abap.dec( 23, 2 ) )
      end                                            as IncomeQ4InCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Income Year to Date (INR)'
      Item.income_inr                                as IncomeAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Related Party Income (USD)'
      case Map.relpty
        when 'X' then Item.income_usd
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as RelatedPartyIncome,

      // -- measures: receivable on 91111 at the key date -------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Gross Balance (USD)'
      Item.balance_usd                               as GrossBalance,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Provision (USD)'
      case
        when Map.provpc is null then cast( 0 as abap.dec( 23, 2 ) )
        else cast( division( Item.balance_usd * Map.provpc, 100, 2 ) as abap.dec( 23, 2 ) )
      end                                            as ProvisionAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Net Receivable (USD)'
      case
        when Map.provpc is null then Item.balance_usd
        else Item.balance_usd
               - cast( division( Item.balance_usd * Map.provpc, 100, 2 ) as abap.dec( 23, 2 ) )
      end                                            as NetReceivable,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Actual G/L Balance (INR)'
      Item.balance_inr                               as GrossBalanceInCCCrcy,
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
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Reclassification (USD)'
      case Map.reclfl
        when 'X' then Item.balance_usd
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as ReclassAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Reclassification, Actual G/L (INR)'
      case Map.reclfl
        when 'X' then Item.balance_inr
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as ReclassAmountInCCCrcy,

      // -- measures: aging by calendar months, USD (ZFI_AGE buckets) --------
      @DefaultAggregation: #SUM
      @EndUserText.label: '1 Month (USD)'
      Item.age_1m                                    as Age1Month,
      @DefaultAggregation: #SUM
      @EndUserText.label: '2-3 Months (USD)'
      Item.age_2_3m                                  as Age2To3Months,
      @DefaultAggregation: #SUM
      @EndUserText.label: '4-6 Months (USD)'
      Item.age_4_6m                                  as Age4To6Months,
      @DefaultAggregation: #SUM
      @EndUserText.label: '6 Months - 1 Year (USD)'
      Item.age_6m_1y                                 as Age6MonthsTo1Year,
      @DefaultAggregation: #SUM
      @EndUserText.label: '1-2 Years (USD)'
      Item.age_1_2y                                  as Age1To2Years,
      @DefaultAggregation: #SUM
      @EndUserText.label: '2-3 Years (USD)'
      Item.age_2_3y                                  as Age2To3Years,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'More than 3 Years (USD)'
      Item.age_3y_plus                               as AgeOver3Years,

      // -- associations ----------------------------------------------------
      _CompanyCode
}
