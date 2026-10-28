//----------------------------------------------------------------------
// Object    : ZI_BR_BANKREVAL_CUBE (DDL source, classic view, cube)
// Purpose   : Bank revaluation for Group Reporting (OVL) - object 3 of 3.
//             Data source for the Custom Analytical Query that replaces
//             ZZ1_BR_REPORT (generated ZZ9_BR_REPORT). That query sits
//             directly on I_GLAccountLineItemCube and so cannot carry a
//             PI share or an exchange rate. This cube adds, per line:
//               PIShare          - ZFI_BR_GLMAP           (Excel col I)
//               ExchangeRateType - ZFI_BR_GLMAP           (Excel col M)
//               ExchangeRate     - one unit of the account currency
//                                  converted to P_RevalCurrency at
//                                  P_RevalDate with the account's rate
//                                  type, through SAP's currency_conversion
//                                  (OB08 rates, OBBS ratios, OB07 inversion
//                                  and reference currency) (Excel col L)
//             OVL Share (col K) and USD Balance after revaluation (col N)
//             are calculated measures in the query:
//               AmountInGLAccountCurrency * PIShare, and that * ExchangeRate.
//             Evaluated after aggregation, they reproduce the Excel
//             arithmetic exactly (balance x share x rate, no per-line
//             rounding).
// Author    : Arnav Johri
// Date      : 28.10.2026
//----------------------------------------------------------------------
// ASSUMPTION: the query filters one fiscal year; the WHERE below only
//   stops lines posted after the key date. Carry-forward lines (period 0)
//   carry the first day of the year as posting date, so they stay in.
// ASSUMPTION: 'USD' is set as the fixed value of P_RevalCurrency in the
//   query. Which SAP currency type already holds USD (Global, Functional
//   or Free-defined 1) is to be confirmed in FINSC_LEDGER / OB22; the two
//   measures that do not apply can then be dropped.
// 28/10/26: activation failed with "Function CURRENCY_CONVERSION: for
//   parameter EXCHANGE_RATE_TYPE only expressions of type literal..." -
//   on this release the rate type cannot be read from the row. It is now
//   a CASE on ZFI_BR_GLMAP-KURST with one literal call per rate type.
// ASSUMPTION: the rate types in use are CLT, M and TTA (Excel col M). A
//   fourth type needs one more WHEN branch here; until then its accounts
//   show a blank rate.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIBRBNKREVCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bank Revaluation - G/L line item cube'
@VDM.viewType: #COMPOSITE
@Analytics.dataCategory: #CUBE
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.sizeCategory: #XXL
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MIXED
define view ZI_BR_BANKREVAL_CUBE
  with parameters
    @EndUserText.label: 'Revaluation Key Date'
    @Semantics.businessDate.at: true
    P_RevalDate     : vdm_v_key_date,
    @EndUserText.label: 'Revaluation Currency'
    @Consumption.defaultValue: 'USD'
    P_RevalCurrency : waers
  as select from ZI_BR_BANKREVAL_ITM as Item
  association [0..1] to I_Ledger                     as _Ledger
    on $projection.Ledger = _Ledger.Ledger
  association [0..1] to I_CompanyCode                as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
  association [0..1] to I_GLAccountInChartOfAccounts as _GLAccountInChartOfAccounts
    on  $projection.ChartOfAccounts = _GLAccountInChartOfAccounts.ChartOfAccounts
    and $projection.GLAccount       = _GLAccountInChartOfAccounts.GLAccount
{
      // -- dimensions ------------------------------------------------
      @ObjectModel.foreignKey.association: '_Ledger'
  key Item.Ledger,
      @ObjectModel.foreignKey.association: '_CompanyCode'
  key Item.CompanyCode,
  key Item.FiscalYear,
  key Item.AccountingDocument,
  key Item.LedgerGLLineItem,

      Item.ChartOfAccounts,
      @ObjectModel.foreignKey.association: '_GLAccountInChartOfAccounts'
      Item.GLAccount,
      Item.ProfitCenter,
      Item.Segment,
      Item.JointVenture,

      Item.LedgerFiscalYear,
      Item.FiscalPeriod,
      Item.FiscalYearPeriod,
      Item.FiscalYearVariant,
      Item.PostingDate,
      Item.DocumentDate,

      Item.AccountingDocumentType,
      Item.AccountingDocumentItem,
      Item.DocumentItemText,
      Item.AssignmentReference,
      Item.HouseBank,
      Item.HouseBankAccount,

      @EndUserText.label: 'G/L House Bank'
      Item.GLHouseBank,
      @EndUserText.label: 'G/L House Bank Account'
      Item.GLHouseBankAccount,
      @EndUserText.label: 'Bank Account Number'
      Item.BankAccountNumber,
      @EndUserText.label: 'Exchange Rate Type'
      Item.ExchangeRateType,
      @EndUserText.label: 'Project/Section'
      Item.ProjectSection,
      @EndUserText.label: 'Business Unit'
      Item.BusinessUnit,

      // -- currencies ------------------------------------------------
      @Semantics.currencyCode: true
      @EndUserText.label: 'Account Currency'
      Item.GLAccountCurrency,
      @Semantics.currencyCode: true
      Item.TransactionCurrency,
      @Semantics.currencyCode: true
      Item.CompanyCodeCurrency,
      @Semantics.currencyCode: true
      Item.GlobalCurrency,
      @Semantics.currencyCode: true
      Item.FunctionalCurrency,
      @Semantics.currencyCode: true
      Item.FreeDefinedCurrency1,
      @Semantics.currencyCode: true
      @EndUserText.label: 'Revaluation Currency'
      $parameters.P_RevalCurrency        as RevaluationCurrency,

      // -- measures --------------------------------------------------
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'GLAccountCurrency'
      @EndUserText.label: 'Balance in Account Currency'
      Item.AmountInGLAccountCurrency,

      @DefaultAggregation: #MAX
      @EndUserText.label: 'PI Share'
      Item.PIShare,

      @DefaultAggregation: #MAX
      @EndUserText.label: 'Exchange Rate at Key Date'
      case
        when Item.ExchangeRateType = 'CLT'
        then cast( currency_conversion( amount             => Item.UnitAmount,
                                        source_currency    => Item.GLAccountCurrency,
                                        target_currency    => $parameters.P_RevalCurrency,
                                        exchange_rate_type => 'CLT',
                                        exchange_rate_date => $parameters.P_RevalDate,
                                        round              => ' ',
                                        decimal_shift      => ' ',
                                        decimal_shift_back => ' ',
                                        error_handling     => 'SET_TO_NULL' )
                   as abap.dec(23,10) )
        when Item.ExchangeRateType = 'M'
        then cast( currency_conversion( amount             => Item.UnitAmount,
                                        source_currency    => Item.GLAccountCurrency,
                                        target_currency    => $parameters.P_RevalCurrency,
                                        exchange_rate_type => 'M',
                                        exchange_rate_date => $parameters.P_RevalDate,
                                        round              => ' ',
                                        decimal_shift      => ' ',
                                        decimal_shift_back => ' ',
                                        error_handling     => 'SET_TO_NULL' )
                   as abap.dec(23,10) )
        when Item.ExchangeRateType = 'TTA'
        then cast( currency_conversion( amount             => Item.UnitAmount,
                                        source_currency    => Item.GLAccountCurrency,
                                        target_currency    => $parameters.P_RevalCurrency,
                                        exchange_rate_type => 'TTA',
                                        exchange_rate_date => $parameters.P_RevalDate,
                                        round              => ' ',
                                        decimal_shift      => ' ',
                                        decimal_shift_back => ' ',
                                        error_handling     => 'SET_TO_NULL' )
                   as abap.dec(23,10) )
      end                                as ExchangeRate,

      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      Item.AmountInTransactionCurrency,
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      Item.AmountInCompanyCodeCurrency,
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'GlobalCurrency'
      Item.AmountInGlobalCurrency,
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'FunctionalCurrency'
      Item.AmountInFunctionalCurrency,
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'FreeDefinedCurrency1'
      Item.AmountInFreeDefinedCurrency1,

      // -- associations: texts and the G/L account hierarchy -------------
      _Ledger,
      _CompanyCode,
      _GLAccountInChartOfAccounts
}
where
  Item.PostingDate <= $parameters.P_RevalDate
