//----------------------------------------------------------------------
// Object    : ZI_TASA_DOCGL_LN (DDL source, classic view)
// Title     : TASA recon - mapped G/L lines with their offset amount
// Project   : OVL                                   Module: FI-GL
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheet P&L-TASA
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   Lines (other than 230903) of G/L accounts maintained as a partner in
//   ZFI_TASA_MAP, with offset_usd = the amount an income line must have
//   to be exactly offset by this line (sign reversed, typed like KSL so
//   ZI_TASA_INC_ITEM can compare it field to field). ZI_TASA_DOCGL
//   groups these per document and amount.
//   Why: the JIB inter-association document 1025003405 (type JM) also
//   posts to G/L 80801 (-6,774,130 against income -3,728,054); taking any
//   mapped G/L of the document put it on Block 128. Block 128's own
//   documents post 80801 exactly against the income line (+/-100,000).
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASADOCGLLN'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: mapped G/L lines'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_TASA_DOCGL_LN
  as select from acdoca       as Line
    inner join   zfi_tasa_map as Map on  Map.bukrs   = Line.rbukrs
                                     and Map.partner = Line.racct
{
  key Line.rbukrs                                    as company_code,
  key Line.gjahr                                     as fiscal_year,
  key Line.belnr                                     as accounting_doc,
  key Line.docln                                     as ledger_gl_item,
      Line.racct                                     as gl_partner,
      Line.rkcur                                     as global_currency,
      @Semantics.amount.currencyCode: 'global_currency'
      cast( cast( 0 as abap.dec( 23, 2 ) ) - cast( Line.ksl as abap.dec( 23, 2 ) )
            as abap.curr( 23, 2 ) )                  as offset_usd
}
where
      Line.rldnr =  '0L'
  and Line.racct <> '0000230903'
