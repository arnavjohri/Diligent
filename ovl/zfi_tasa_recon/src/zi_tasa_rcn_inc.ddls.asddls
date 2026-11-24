//----------------------------------------------------------------------
// Object    : ZI_TASA_RCN_INC (DDL source, classic view, parameter)
// Title     : TASA recon (one tile) - income lines up to a key date,
//             with the fiscal year of the key date
// Project   : OVL                                   Module: FI-GL
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheet P&L-TASA
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   ZI_TASA_INC_ITEM lines posted on or before P_KeyDate, plus
//   key_fiscal_year = the fiscal year (April - March, start year as in
//   ACDOCA-GJAHR: 2025 = FY26) that contains P_KeyDate. Key date minus
//   three months falls in the calendar year that equals the fiscal year
//   (31.03.2026 -> 31.12.2025 -> 2025; 01.04.2025 -> 01.01.2025 -> 2025).
//   ZI_TASA_RCN_ITEM keeps the lines whose fiscal year equals it: a
//   classic view takes no function in WHERE, only field = field
//   (MEMORY 4.1).
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: fiscal year April - March for OVL, ACDOCA-GJAHR = start
//   year (FY26 income is GJAHR 2025, checked 23.11.2026).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASARCNINC'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: income up to key date'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_TASA_RCN_INC
  with parameters
    P_KeyDate : vdm_v_key_date
  as select from ZI_TASA_INC_ITEM as Inc
{
  key Inc.company_code,
  key Inc.fiscal_year,
  key Inc.accounting_doc,
  key Inc.ledger_gl_item,
      Inc.fiscal_period,
      Inc.fiscal_quarter,
      Inc.partner,
      Inc.customer,
      Inc.gl_account,
      Inc.posting_date,
      Inc.document_type,
      Inc.item_text,
      Inc.assignment,
      Inc.joint_venture,
      Inc.co_code_currency,
      Inc.global_currency,
      Inc.income_usd,
      Inc.income_inr,
      cast( substring( dats_add_months( $parameters.P_KeyDate, -3, 'INITIAL' ), 1, 4 )
            as abap.numc( 4 ) )                      as key_fiscal_year
}
where
  Inc.posting_date <= $parameters.P_KeyDate
