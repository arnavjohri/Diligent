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
// 28/10/26: first activation failed with "CAST 1.0 of type FLTP to type
//   CURR is not possible" - in a DDIC-based view a literal with a decimal
//   point is FLTP. The integer literal 1 is INT4 and casts to CURR.
// ASSUMPTION: INT4 -> abap.curr(23,10) is accepted. If not, cast to
//   abap.dec(23,10) instead; currency_conversion takes DEC amounts too.
// 03/11/26: house bank / account number came back blank. SKB1-HBKID /
//   HKTID (FS00, Create/bank/interest tab) are not maintained on S/4 -
//   the G/L to house bank account link is T012K-HKONT, written by the
//   connectivity path in Manage Bank Accounts. T012K is now joined on
//   company code + G/L account; SKB1 stays for the account currency.
// ASSUMPTION: one house bank account (T012K row) per G/L account and
//   company code. A G/L used by two account IDs would double the lines
//   of that account - check SE16 T012K, BUKRS OVL, duplicates in HKONT.
// 03/11/26 (v4): still blank with the direct T012K join. The house bank
//   now comes through ZI_BR_HOUSEBANKACCT, which pads T012K-HKONT to
//   10 digits, so the join holds whether the zeros are stored or not.
// 03/11/26 (v5): G/L description wanted as its own column (Excel col C).
//   SKAT joined on chart of accounts + G/L account in the logon language;
//   TXT50 exposed as GLAccountLongName.
// 10/11/26 (v6): the cube may not use a function in its WHERE ("Random
//   expressions are not supported in a condition"), so the fiscal year of
//   the key date is computed here as a column: parameter P_RevalDate added,
//   KeyDateFiscalYear = calendar year of (key date - 3 months), the V3
//   rule (April-March, year named by the calendar year of April). The cube
//   compares LedgerFiscalYear with it field to field.
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
  //BOC By Arnav on 10/11/26 - key date for the fiscal year column
  with parameters
    @EndUserText.label: 'Revaluation Key Date'
    P_RevalDate : vdm_v_key_date
  //EOC By Arnav on 10/11/26 - key date for the fiscal year column
  as select from I_GLAccountLineItemCube as Item
    left outer join skb1         as AcctCoCd on  AcctCoCd.bukrs = Item.CompanyCode
                                             and AcctCoCd.saknr = Item.GLAccount
    //BOC By Arnav on 03/11/26
    //  left outer join t012k        as BankAcct on  BankAcct.bukrs = AcctCoCd.bukrs
    //                                           and BankAcct.hbkid = AcctCoCd.hbkid
    //                                           and BankAcct.hktid = AcctCoCd.hktid
    //  left outer join t012k        as BankAcct on  BankAcct.bukrs = Item.CompanyCode
    //                                           and BankAcct.hkont = Item.GLAccount
    left outer join ZI_BR_HOUSEBANKACCT as BankAcct
                                             on  BankAcct.CompanyCode = Item.CompanyCode
                                             and BankAcct.GLAccount   = Item.GLAccount
    //EOC By Arnav on 03/11/26
    left outer join zfi_br_glmap as Map      on  Map.bukrs = Item.CompanyCode
                                             and Map.saknr = Item.GLAccount
    //BOC By Arnav on 03/11/26 - G/L description
    left outer join skat         as AcctText on  AcctText.ktopl = Item.ChartOfAccounts
                                             and AcctText.saknr = Item.GLAccount
                                             and AcctText.spras = $session.system_language
    //EOC By Arnav on 03/11/26 - G/L description
{
  key Item.Ledger,
  key Item.CompanyCode,
  key Item.FiscalYear,
  key Item.AccountingDocument,
  key Item.LedgerGLLineItem,

      // -- G/L account and organisation ------------------------------
      Item.ChartOfAccounts,
      Item.GLAccount,
      //BOC By Arnav on 03/11/26 - G/L description
      AcctText.txt50                   as GLAccountLongName,
      //EOC By Arnav on 03/11/26 - G/L description
      Item.ProfitCenter,
      Item.Segment,
      Item.JointVenture,

      // -- time ------------------------------------------------------
      Item.LedgerFiscalYear,
      //BOC By Arnav on 10/11/26 - fiscal year of the key date (V3)
      cast( substring( dats_add_months( $parameters.P_RevalDate, -3, 'INITIAL' ), 1, 4 )
            as abap.numc(4) )            as KeyDateFiscalYear,
      //EOC By Arnav on 10/11/26 - fiscal year of the key date (V3)
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
      //BOC By Arnav on 03/11/26
      //  AcctCoCd.hbkid                   as GLHouseBank,
      //  AcctCoCd.hktid                   as GLHouseBankAccount,
      //  BankAcct.hbkid                   as GLHouseBank,
      //  BankAcct.hktid                   as GLHouseBankAccount,
      //  BankAcct.bankn                   as BankAccountNumber,
      BankAcct.HouseBank               as GLHouseBank,
      BankAcct.HouseBankAccount        as GLHouseBankAccount,
      BankAcct.BankAccountNumber       as BankAccountNumber,
      //EOC By Arnav on 03/11/26

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
      cast( 1 as abap.curr(23,10) )    as UnitAmount
}
