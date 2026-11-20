//----------------------------------------------------------------------
// Object    : ZI_SLDI_ITEM_TF (DDL source, CDS table function)
// Title     : Subsidiary schedules: G/L line items of the mapped
//             accounts, classified by ZFI_SLDI_ROW / ZFI_SLDI_MOV
// Project   : OVL                                   Module: FI-GL
// Source    : SAP_FIORI_-_Subsidiaries_Loan_and_Deemed_Investment_
//             Schedule_-_Annual_FY26.xlsx
// Author    : Arnav Johri                            Date: 20.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 3 of 5. One row per ACDOCA line (leading ledger, no balance
//   carry-forward rows) of every G/L account in ZFI_SLDI_ROW that is
//   open at the From date, posted in the period or open at the To
//   date. Implemented in ZCL_SLDI_ITEM_TF=>GET_ITEMS, because the item
//   text is matched against words kept in a table (SQLScript LIKE).
//   Amounts: USD = global currency (KSL), INR = company code currency.
//
// CHANGE HISTORY
//   20.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
@EndUserText.label: 'Subsidiary schedules: classified G/L line items'
@ClientHandling.type: #CLIENT_DEPENDENT
@ClientHandling.algorithm: #SESSION_VARIABLE
@AccessControl.authorizationCheck: #NOT_REQUIRED
define table function ZI_SLDI_ITEM_TF
  with parameters
    @Environment.systemField: #CLIENT
    p_clnt : abap.clnt,
    p_from : abap.dats,
    p_to   : abap.dats
returns
{
  mandt              : abap.clnt;
  company_code       : abap.char( 4 );
  fiscal_year        : abap.numc( 4 );
  accounting_doc     : abap.char( 10 );
  ledger_gl_item     : abap.char( 6 );
  gl_account         : abap.char( 10 );
  schedule           : abap.char( 1 );
  row_no             : abap.numc( 2 );
  row_text           : abap.char( 60 );
  is_provision       : abap.char( 1 );
  movement_column    : abap.char( 1 );
  posting_date       : abap.dats;
  clearing_date      : abap.dats;
  document_type      : abap.char( 2 );
  debit_credit       : abap.char( 1 );
  item_text          : abap.char( 50 );
  assignment         : abap.char( 18 );
  partner_company    : abap.char( 6 );
  offsetting_account : abap.char( 10 );
  co_code_currency   : abap.char( 5 );
  global_currency    : abap.char( 5 );
  opening_usd        : abap.dec( 23, 2 );
  movement_usd       : abap.dec( 23, 2 );
  closing_usd        : abap.dec( 23, 2 );
  movement_inr       : abap.dec( 23, 2 );
}
implemented by method
  ZCL_SLDI_ITEM_TF=>GET_ITEMS;
