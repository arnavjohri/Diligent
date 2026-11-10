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
// 10/11/26: the query's year variable did not restrict rows, so the cube
//   summed every fiscal year up to the key date - each year's carry-forward
//   line plus the years it already contains (93483: 2,519.71 instead of
//   0.00, ISSUES #5). The cube now restricts itself to the fiscal year of
//   the key date; carry-forward lines (period 000) carry the first day of
//   that year as posting date, so they stay in. A function in the WHERE
//   was refused ("Random expressions are not supported in a condition"),
//   so the ITM computes KeyDateFiscalYear from the key date passed down
//   and the WHERE compares two fields.
// ASSUMPTION: fiscal year variant V3 for OVL - April to March, year named
//   by the calendar year of April (ACDOCA: 01.10.2025 = period 007.2025).
//   Fiscal year = calendar year of (key date - 3 months). If OVL ever used
//   a variant named by the closing year, this becomes + 9 months.
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
// 28/10/26: active and released for key-user apps (API State, C1), yet
//   not listed as a data source in Custom Analytical Queries. The key-user
//   catalogue classifies views by @ObjectModel.modelingPattern and
//   @ObjectModel.supportedCapabilities (the generated ZZ9 query carries
//   them); added here with #ANALYTICAL_CUBE / #ANALYTICAL_PROVIDER.
// 03/11/26: GLAccountLongName (SKAT TXT50, via the ITM) added as a plain
//   dimension, so the description is an exportable column of its own
//   next to the key + text display of GLAccount.
// 03/11/26: Analytics warning "Association of field GLACCOUNT ignored:
//   Association for field CHARTOFACCOUNTS is inconsistent". The G/L
//   dimension is keyed by chart of accounts + account, so the engine
//   needs ChartOfAccounts linked to its own dimension as well, or it
//   drops the G/L texts and hierarchy. _ChartOfAccounts added.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIBRBNKREVCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bank Revaluation - G/L line item cube'
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
  //BOC By Arnav on 10/11/26 - key date passed to the ITM
  //  as select from ZI_BR_BANKREVAL_ITM as Item
  as select from ZI_BR_BANKREVAL_ITM( P_RevalDate: $parameters.P_RevalDate ) as Item
  //EOC By Arnav on 10/11/26 - key date passed to the ITM
  association [0..1] to I_Ledger                     as _Ledger
    on $projection.Ledger = _Ledger.Ledger
  association [0..1] to I_CompanyCode                as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
  association [0..1] to I_GLAccountInChartOfAccounts as _GLAccountInChartOfAccounts
    on  $projection.ChartOfAccounts = _GLAccountInChartOfAccounts.ChartOfAccounts
    and $projection.GLAccount       = _GLAccountInChartOfAccounts.GLAccount
  //BOC By Arnav on 03/11/26 - chart of accounts dimension
  association [0..1] to I_ChartOfAccounts            as _ChartOfAccounts
    on $projection.ChartOfAccounts = _ChartOfAccounts.ChartOfAccounts
  //EOC By Arnav on 03/11/26 - chart of accounts dimension
{
      // -- dimensions ------------------------------------------------
      @ObjectModel.foreignKey.association: '_Ledger'
  key Item.Ledger,
      @ObjectModel.foreignKey.association: '_CompanyCode'
  key Item.CompanyCode,
  key Item.FiscalYear,
  key Item.AccountingDocument,
  key Item.LedgerGLLineItem,

      //BOC By Arnav on 03/11/26 - chart of accounts dimension
      @ObjectModel.foreignKey.association: '_ChartOfAccounts'
      //EOC By Arnav on 03/11/26 - chart of accounts dimension
      Item.ChartOfAccounts,
      @ObjectModel.foreignKey.association: '_GLAccountInChartOfAccounts'
      Item.GLAccount,
      //BOC By Arnav on 03/11/26 - G/L description
      @EndUserText.label: 'G/L Account Description'
      Item.GLAccountLongName,
      //EOC By Arnav on 03/11/26 - G/L description
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
      //BOC By Arnav on 03/11/26 - chart of accounts dimension
      _ChartOfAccounts,
      //EOC By Arnav on 03/11/26 - chart of accounts dimension
      _GLAccountInChartOfAccounts
}
where
  Item.PostingDate <= $parameters.P_RevalDate
  //BOC By Arnav on 10/11/26 - found active on OCD, added by hand, no marker
  // Dropped every account without a house bank account in BAM (Excel: most
  // are "To be created"; 96468 has none). The hierarchy already scopes the
  // report - removed again by Arnav on 10/11/26, 96468 visible since.
  //  and Item.GLHouseBankAccount is not initial
  //EOC By Arnav on 10/11/26 - found active on OCD
  //BOC By Arnav on 10/11/26 - fiscal year of the key date (V3), from the ITM
  and Item.LedgerFiscalYear = Item.KeyDateFiscalYear
  //EOC By Arnav on 10/11/26 - fiscal year of the key date (V3), from the ITM
