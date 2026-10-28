//----------------------------------------------------------------------
// Object    : ZI_BR_BANKREVAL_ITM (DDL source, classic view)
// Purpose   : Bank revaluation for Group Reporting (OVL) - object 2 of 3.
//             G/L line items of I_GLAccountLineItemCube joined to the
//             account master (SKB1: account currency, house bank; T012K:
//             bank account number) and to the mapping table ZFI_BR_GLMAP
//             (PI share, exchange rate type, Project/Section, Business
//             Unit per company code + G/L account). No parameters here;
//             the key date lives in the cube ZI_BR_BANKREVAL_CUBE.
// Source    : FIORI_Development_-_Bank_Revaluation_-_Updated_V2.xlsx
// Author    : Arnav Johri
// Date      : 28.10.2026
//----------------------------------------------------------------------
// ASSUMPTION: a bank G/L whose account currency (SKB1-WAERS) differs
//   from the company code currency is posted only in that currency, so
//   its "Local Currency Balance" (Excel col J) is the transaction
//   currency amount; for an INR account it is the company code currency
//   amount. This is the SAP posting rule for foreign account currencies.
// ASSUMPTION: ZFI_BR_GLMAP has no validity dates - one PI share per
//   company code + G/L. Add DATAB/DATBI if shares must be historised.
// ASSUMPTION: cast of the literal 1.0 to abap.curr(23,10) is accepted on
//   this release. If activation rejects it, use abap.dec(23,10) instead;
//   the cube's currency_conversion takes DEC amounts as well.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIBRBNKREVITM'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bank Revaluation - G/L items with account attributes'
@VDM.viewType: #COMPOSITE
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_BR_BANKREVAL_ITM
  as select from I_GLAccountLineItemCube as Item
    left outer join skb1         as AcctCoCd on  AcctCoCd.bukrs = Item.CompanyCode
                                             and AcctCoCd.saknr = Item.GLAccount
    left outer join t012k        as BankAcct on  BankAcct.bukrs = AcctCoCd.bukrs
                                             and BankAcct.hbkid = AcctCoCd.hbkid
                                             and BankAcct.hktid = AcctCoCd.hktid
    left outer join zfi_br_glmap as Map      on  Map.bukrs = Item.CompanyCode
                                             and Map.saknr = Item.GLAccount
{
  key Item.Ledger,
  key Item.CompanyCode,
  key Item.FiscalYear,
  key Item.AccountingDocument,
  key Item.LedgerGLLineItem,

      // -- G/L account and organisation ------------------------------
      Item.ChartOfAccounts,
      Item.GLAccount,
      Item.ProfitCenter,
      Item.Segment,
      Item.JointVenture,

      // -- time ------------------------------------------------------
      Item.LedgerFiscalYear,
      Item.FiscalPeriod,
      Item.FiscalYearPeriod,
      Item.FiscalYearVariant,
      Item.PostingDate,
      Item.DocumentDate,

      // -- document --------------------------------------------------
      Item.AccountingDocumentType,
      Item.AccountingDocumentItem,
      Item.DocumentItemText,
      Item.AssignmentReference,
      Item.HouseBank,
      Item.HouseBankAccount,

      // -- account master (SKB1 / T012K) -----------------------------
      @Semantics.currencyCode: true
      AcctCoCd.waers                   as GLAccountCurrency,
      AcctCoCd.hbkid                   as GLHouseBank,
      AcctCoCd.hktid                   as GLHouseBankAccount,
      BankAcct.bankn                   as BankAccountNumber,

      // -- mapping table ZFI_BR_GLMAP --------------------------------
      Map.zpishare                     as PIShare,
      Map.kurst                        as ExchangeRateType,
      Map.zprojsect                    as ProjectSection,
      Map.zbusunit                     as BusinessUnit,

      // -- currencies ------------------------------------------------
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

      // -- amounts ---------------------------------------------------
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      Item.AmountInTransactionCurrency,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      Item.AmountInCompanyCodeCurrency,
      @Semantics.amount.currencyCode: 'GlobalCurrency'
      Item.AmountInGlobalCurrency,
      @Semantics.amount.currencyCode: 'FunctionalCurrency'
      Item.AmountInFunctionalCurrency,
      @Semantics.amount.currencyCode: 'FreeDefinedCurrency1'
      Item.AmountInFreeDefinedCurrency1,

      // Balance in the account's own currency (Excel col J)
      @Semantics.amount.currencyCode: 'GLAccountCurrency'
      case
        when AcctCoCd.waers = Item.CompanyCodeCurrency
        then Item.AmountInCompanyCodeCurrency
        else Item.AmountInTransactionCurrency
      end                              as AmountInGLAccountCurrency,

      // One unit of the account currency, 10 decimals. The cube converts
      // it at the key date; the converted value is the exchange rate.
      @Semantics.amount.currencyCode: 'GLAccountCurrency'
      cast( 1.0 as abap.curr(23,10) )  as UnitAmount
}
