//----------------------------------------------------------------------
// Object    : ZI_BR_HOUSEBANKACCT (DDL source, classic view)
// Purpose   : Bank revaluation for Group Reporting (OVL) - helper for
//             ZI_BR_BANKREVAL_ITM. One row per house bank account
//             (T012K) with the G/L account normalised to the 10-digit
//             internal form, so the join to the line items matches
//             whether T012K-HKONT was stored with or without leading
//             zeros (03/11/26: house bank came back blank although the
//             T012K row for OVL / HB101 / 96488 exists).
// Author    : Arnav Johri
// Date      : 03.11.2026
//----------------------------------------------------------------------
// ASSUMPTION: G/L accounts at OVL are numeric (SAKNR with ALPHA), so a
//   left pad with '0' to 10 characters yields the ACDOCA value. A blank
//   HKONT becomes '0000000000' and matches nothing.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIBRHBANKACCT'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bank Revaluation - house bank account per G/L'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_BR_HOUSEBANKACCT
  as select from t012k
{
  key bukrs                    as CompanyCode,
  key hbkid                    as HouseBank,
  key hktid                    as HouseBankAccount,
      lpad( hkont, 10, '0' )   as GLAccount,
      bankn                    as BankAccountNumber,
      @Semantics.currencyCode: true
      waers                    as BankAccountCurrency
}
