//----------------------------------------------------------------------
// Object    : ZI_TR_BANKACCT_CUBE (DDL source, classic view, cube)
// Title     : Treasury - Company Bank Accounts (cube for Custom
//             Analytical Queries)
// Project   : OVL                                   Module: FI (Treasury)
// Source    : Management_Dashboard_-_Bank_Details.xlsx
// Author    : Arnav Johri                            Date: 03.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Data source for the Fiori app Custom Analytical Queries (CAQ): the
//   app lists only views with @Analytics.dataCategory: #CUBE that are
//   released for key-user apps (ADT, API State, contract C1). Sits on
//   ZI_TR_BANKACCT, one row per bank account, every Excel column as a
//   characteristic, plus one counting measure - a cube needs at least
//   one measure, and "number of accounts" per Business Unit, country or
//   currency is the figure a management dashboard tile shows.
//   Annotation set copied from ZI_BR_BANKREVAL_CUBE, which the app
//   listed on 02/11/26 after the C1 release.
//
// CHANGE HISTORY
//   03.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: NumberOfAccounts (constant 1, SUM) is an acceptable
//   measure. Without any measure the analytic engine has no key figure
//   to build the ODP on. Switch its totals off in the query if unwanted.
// ASSUMPTION: key + text display is wired only for Company Code
//   (I_CompanyCode, proven on this system in ZI_BR_BANKREVAL_CUBE).
//   Country and Local Currency show the key; add associations to the
//   standard country / currency views once their names are confirmed
//   on this system - not guessed here.
// ASSUMPTION: no access control, as on ZI_BR_BANKREVAL_CUBE. The
//   published query runs with the user's analytics authorisations.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITRBNKACCTCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Treasury - Company Bank Accounts (cube)'
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
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MASTER
define view ZI_TR_BANKACCT_CUBE
  as select from ZI_TR_BANKACCT as BankAcct
  association [0..1] to I_CompanyCode as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
{
      // -- dimensions (Excel columns B..J) -----------------------------
      @ObjectModel.foreignKey.association: '_CompanyCode'
      @EndUserText.label: 'Company Code'
  key BankAcct.CompanyCode,
      @EndUserText.label: 'A/C Number'
  key BankAcct.BankAccountNumber,

      @EndUserText.label: 'Name of Bank Account'
      BankAcct.BankAccountName,
      @EndUserText.label: 'Project/Section'
      BankAcct.ProjectSection,
      @EndUserText.label: 'Business Unit'
      BankAcct.BusinessUnit,
      @EndUserText.label: 'Address'
      BankAcct.BankAddress,
      @Semantics.currencyCode: true
      @EndUserText.label: 'Local Currency'
      BankAcct.LocalCurrency,
      @EndUserText.label: 'Country'
      BankAcct.Country,
      @EndUserText.label: 'Principal Officer'
      BankAcct.PrincipalOfficer,
      @EndUserText.label: 'Signatory Officer'
      BankAcct.SignatoryOfficer,

      // -- measure: one per row, so SUM = number of accounts -----------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Number of Accounts'
      cast( 1 as abap.int4 )         as NumberOfAccounts,

      // -- texts -------------------------------------------------------
      _CompanyCode
}
