//----------------------------------------------------------------------
// Object    : ZI_TR_BANKACCT (DDL source, classic view)
// Title     : Treasury - Company Bank Accounts (Management Dashboard)
// Project   : OVL                                   Module: FI (Treasury)
// Source    : Management_Dashboard_-_Bank_Details.xlsx (sheet Bank
//             Account Details, row 3 = the nine columns)
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Reads every row of the Treasury register ZFI_TR_BANKACCT - the bank
//   accounts held in the company's own name - one element per Excel
//   column, with the company code and the account number as keys.
//   Plain projection: no joins, no parameters, no aggregation, so that a
//   Fiori list, an analytical query or a report can sit on top of it.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: older S/4 release (OCQ) - classic "define view" with an
//   SQL view name, the form that activated on 28/10/26 for
//   ZI_BR_BANKREVAL_ITM. No view entity, no @Semantics beyond
//   currencyCode, no @Consumption.valueHelpDefinition.
// ASSUMPTION: no access control. The table is protected by its
//   authorisation group (S_TABU_DIS) at the T-code; if this view is ever
//   exposed through OData, add a DCL on CompanyCode (F_BKPF_BUK).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITRBANKACCT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Treasury - Company Bank Accounts'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
define view ZI_TR_BANKACCT
  as select from zfi_tr_bankacct as BankAcct
{
      // -- keys ------------------------------------------------------
      @EndUserText.label: 'Company Code'
  key BankAcct.bukrs                 as CompanyCode,
      @EndUserText.label: 'A/C Number'
  key BankAcct.zacctno               as BankAccountNumber,

      // -- Excel columns B..J, in sheet order ------------------------
      @EndUserText.label: 'Name of Bank Account'
      BankAcct.zacctname             as BankAccountName,
      @EndUserText.label: 'Project/Section'
      BankAcct.zprojsect             as ProjectSection,
      @EndUserText.label: 'Business Unit'
      BankAcct.zbusunit              as BusinessUnit,
      @EndUserText.label: 'Address'
      BankAcct.zaddress              as BankAddress,
      @EndUserText.label: 'Local Currency'
      @Semantics.currencyCode: true
      BankAcct.waers                 as LocalCurrency,
      @EndUserText.label: 'Country'
      BankAcct.land1                 as Country,
      @EndUserText.label: 'Principal Officer'
      BankAcct.zprincoff             as PrincipalOfficer,
      @EndUserText.label: 'Signatory Officer'
      BankAcct.zsignoff              as SignatoryOfficer
}
