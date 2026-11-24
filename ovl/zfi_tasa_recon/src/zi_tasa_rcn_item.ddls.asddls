//----------------------------------------------------------------------
// Object    : ZI_TASA_RCN_ITEM (DDL source, classic view, union)
// Title     : TASA recon (one tile) - income and open receivable lines
// Project   : OVL                                   Module: FI-GL / FI-AR
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheets P&L-TASA,
//             BS - Customer Balance (TASA), zfi_age_31.03.2026
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   One row per line, two kinds (line_kind; SECTION is a reserved word):
//     I  income on G/L 230903 of the key date's fiscal year, posted up to
//        the key date (ZI_TASA_RCN_INC) - income amounts filled
//     B  open items of customer G/L 91111 at the key date
//        (ZI_TASA_BAL_ITEM) - balance and aging amounts filled
//   Every other amount of a row is 0, so the cube can add the two kinds
//   side by side per project / customer. Aging buckets are computed here
//   (calendar months, as ZI_TASA_BAL_CUBE / ZFI_AGE). unmapped_text is
//   the row label when the partner is not in ZFI_TASA_MAP, as on the two
//   single cubes ("Other" / "Not in Customer List").
//   Every element is cast in both branches: a union needs equal types.
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASARCNITM'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: income and open items'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_TASA_RCN_ITEM
  with parameters
    P_KeyDate : vdm_v_key_date
  as select from ZI_TASA_RCN_INC( P_KeyDate : $parameters.P_KeyDate ) as Inc
{
  key Inc.company_code                               as company_code,
  key Inc.fiscal_year                                as fiscal_year,
  key Inc.accounting_doc                             as accounting_doc,
  key Inc.ledger_gl_item                             as ledger_gl_item,
      cast( 'I' as abap.char( 1 ) )                  as line_kind,
      cast( Inc.partner as abap.char( 10 ) )         as partner,
      cast( 'Other' as abap.char( 60 ) )             as unmapped_text,
      cast( Inc.fiscal_quarter as abap.char( 2 ) )   as fiscal_quarter,
      Inc.gl_account                                 as gl_account,
      cast( Inc.posting_date as abap.dats )          as posting_date,
      Inc.document_type                              as document_type,
      Inc.item_text                                  as item_text,
      Inc.assignment                                 as assignment,
      Inc.joint_venture                              as joint_venture,
      Inc.co_code_currency                           as co_code_currency,
      Inc.global_currency                            as global_currency,
      @Semantics.amount.currencyCode: 'global_currency'
      cast( 1 as abap.curr( 23, 10 ) )               as unit_usd,
      cast( Inc.income_usd as abap.dec( 23, 2 ) )    as income_usd,
      cast( Inc.income_inr as abap.dec( 23, 2 ) )    as income_inr,
      cast( 0 as abap.dec( 23, 2 ) )                 as balance_usd,
      cast( 0 as abap.dec( 23, 2 ) )                 as balance_inr,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_1m,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_2_3m,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_4_6m,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_6m_1y,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_1_2y,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_2_3y,
      cast( 0 as abap.dec( 23, 2 ) )                 as age_3y_plus
}
where
  Inc.fiscal_year = Inc.key_fiscal_year

union all

  select from ZI_TASA_BAL_ITEM( P_KeyDate : $parameters.P_KeyDate ) as Bal
{
  key Bal.company_code                               as company_code,
  key Bal.fiscal_year                                as fiscal_year,
  key Bal.accounting_doc                             as accounting_doc,
  key Bal.ledger_gl_item                             as ledger_gl_item,
      cast( 'B' as abap.char( 1 ) )                  as line_kind,
      cast( Bal.customer as abap.char( 10 ) )        as partner,
      cast( 'Not in Customer List' as abap.char( 60 ) )
                                                     as unmapped_text,
      cast( '  ' as abap.char( 2 ) )                 as fiscal_quarter,
      Bal.gl_account                                 as gl_account,
      cast( Bal.posting_date as abap.dats )          as posting_date,
      Bal.document_type                              as document_type,
      Bal.item_text                                  as item_text,
      Bal.assignment                                 as assignment,
      Bal.joint_venture                              as joint_venture,
      Bal.co_code_currency                           as co_code_currency,
      Bal.global_currency                            as global_currency,
      cast( 1 as abap.curr( 23, 10 ) )               as unit_usd,
      cast( 0 as abap.dec( 23, 2 ) )                 as income_usd,
      cast( 0 as abap.dec( 23, 2 ) )                 as income_inr,
      Bal.amount_usd                                 as balance_usd,
      Bal.amount_inr                                 as balance_inr,
      case
        when Bal.posting_date >= Bal.month_0  then Bal.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as age_1m,
      case
        when Bal.posting_date >= Bal.month_0  then cast( 0 as abap.dec( 23, 2 ) )
        when Bal.posting_date >= Bal.month_2  then Bal.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as age_2_3m,
      case
        when Bal.posting_date >= Bal.month_2  then cast( 0 as abap.dec( 23, 2 ) )
        when Bal.posting_date >= Bal.month_5  then Bal.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as age_4_6m,
      case
        when Bal.posting_date >= Bal.month_5  then cast( 0 as abap.dec( 23, 2 ) )
        when Bal.posting_date >= Bal.month_11 then Bal.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as age_6m_1y,
      case
        when Bal.posting_date >= Bal.month_11 then cast( 0 as abap.dec( 23, 2 ) )
        when Bal.posting_date >= Bal.month_23 then Bal.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as age_1_2y,
      case
        when Bal.posting_date >= Bal.month_23 then cast( 0 as abap.dec( 23, 2 ) )
        when Bal.posting_date >= Bal.month_35 then Bal.amount_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                                            as age_2_3y,
      case
        when Bal.posting_date >= Bal.month_35 then cast( 0 as abap.dec( 23, 2 ) )
        else Bal.amount_usd
      end                                            as age_3y_plus
}
