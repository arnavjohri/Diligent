//----------------------------------------------------------------------
// Object    : ZI_TASA_BAL_ITEM (DDL source, classic view, parameter)
// Title     : TASA recon - open items of customer G/L 91111 at a key date
// Project   : OVL                                   Module: FI-AR
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheets
//             BS - Customer Balance (TASA) and zfi_age_31.03.2026
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   Open items of the non-trade customer G/L 91111 at P_KeyDate: posted
//   on or before it, not cleared or cleared after it, no balance carry-
//   forward lines. Checked on OCD 500 23.11.2026: per customer equal to
//   the workbook's SAP dump at 31.03.2026 (5,107,992.71 USD).
//   month_0 .. month_35: first day of the key-date month and of the
//   months 2, 5, 11, 23 and 35 before it - the aging buckets of ZFI_AGE
//   go by calendar months (workbook line items: 0 / 1-2 / 3-5 / 6-11 /
//   12-23 / 24-35 / 36+ months). The cube compares posting date with
//   these fields (a classic view takes no function in a CASE condition).
//   unit_usd: one USD, converted in the cube to the closing rate.
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: aging by posting date, as the ZFI_AGE dump (query 8).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASABALITM'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: open items 91111 at key date'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_TASA_BAL_ITEM
  with parameters
    P_KeyDate : vdm_v_key_date
  as select from acdoca as Line
{
  key Line.rbukrs                                    as company_code,
  key Line.gjahr                                     as fiscal_year,
  key Line.belnr                                     as accounting_doc,
  key Line.docln                                     as ledger_gl_item,
      Line.kunnr                                     as customer,
      Line.racct                                     as gl_account,
      Line.budat                                     as posting_date,
      Line.augdt                                     as clearing_date,
      Line.blart                                     as document_type,
      Line.sgtxt                                     as item_text,
      Line.zuonr                                     as assignment,
      Line.vname                                     as joint_venture,
      Line.rhcur                                     as co_code_currency,
      Line.rkcur                                     as global_currency,
      cast( Line.ksl as abap.dec( 23, 2 ) )          as amount_usd,
      cast( Line.hsl as abap.dec( 23, 2 ) )          as amount_inr,
      @Semantics.amount.currencyCode: 'global_currency'
      cast( 1 as abap.curr( 23, 10 ) )               as unit_usd,
      cast( concat( substring( $parameters.P_KeyDate, 1, 6 ), '01' ) as abap.dats )
                                                     as month_0,
      dats_add_months( cast( concat( substring( $parameters.P_KeyDate, 1, 6 ), '01' ) as abap.dats ),
                       -2, 'INITIAL' )               as month_2,
      dats_add_months( cast( concat( substring( $parameters.P_KeyDate, 1, 6 ), '01' ) as abap.dats ),
                       -5, 'INITIAL' )               as month_5,
      dats_add_months( cast( concat( substring( $parameters.P_KeyDate, 1, 6 ), '01' ) as abap.dats ),
                       -11, 'INITIAL' )              as month_11,
      dats_add_months( cast( concat( substring( $parameters.P_KeyDate, 1, 6 ), '01' ) as abap.dats ),
                       -23, 'INITIAL' )              as month_23,
      dats_add_months( cast( concat( substring( $parameters.P_KeyDate, 1, 6 ), '01' ) as abap.dats ),
                       -35, 'INITIAL' )              as month_35
}
where
      Line.rldnr =  '0L'
  and Line.racct =  '0000091111'
  and Line.bstat <> 'C'
  and Line.budat <= $parameters.P_KeyDate
  and (
       Line.augdt =  '00000000'
    or Line.augdt >  $parameters.P_KeyDate
  )
