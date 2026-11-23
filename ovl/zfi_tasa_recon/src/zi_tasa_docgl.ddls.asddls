//----------------------------------------------------------------------
// Object    : ZI_TASA_DOCGL (DDL source, classic view)
// Title     : TASA recon - G/L partner of a document without customer
// Project   : OVL                                   Module: FI-GL
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheet P&L-TASA
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   Some TASA income is posted without a customer: Block 128 ("Parent
//   Co. Overheads", offset G/L 80801 in the workbook) is 230903 against
//   G/L 80801. Per document and offset amount, the G/L account (other
//   than 230903) maintained as a partner in ZFI_TASA_MAP whose line
//   exactly offsets an income line (ZI_TASA_DOCGL_LN). ZI_TASA_INC_ITEM
//   uses it only when the document has no customer line.
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//   24.11.2026  Arnav Johri  OCDK920558  Per document AND offset amount:
//               the JIB document 1025003405 also posts to 80801 and was
//               put on Block 128 (3,928,054.62 instead of 200,000)
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASADOCGL'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: mapped G/L of a document'
@ClientHandling.algorithm: #SESSION_VARIABLE
//BOC By Arnav on 24/11/26
//define view ZI_TASA_DOCGL
//  as select from acdoca       as Line
//    inner join   zfi_tasa_map as Map on  Map.bukrs   = Line.rbukrs
//                                     and Map.partner = Line.racct
//{
//  key Line.rbukrs       as company_code,
//  key Line.gjahr        as fiscal_year,
//  key Line.belnr        as accounting_doc,
//      max( Line.racct ) as gl_partner
//}
//where
//      Line.rldnr =  '0L'
//  and Line.racct <> '0000230903'
//group by
//  Line.rbukrs,
//  Line.gjahr,
//  Line.belnr
define view ZI_TASA_DOCGL
  as select from ZI_TASA_DOCGL_LN as GlLine
{
  key GlLine.company_code       as company_code,
  key GlLine.fiscal_year        as fiscal_year,
  key GlLine.accounting_doc     as accounting_doc,
  key GlLine.offset_usd         as offset_usd,
      max( GlLine.gl_partner )  as gl_partner
}
group by
  GlLine.company_code,
  GlLine.fiscal_year,
  GlLine.accounting_doc,
  GlLine.offset_usd
//EOC By Arnav on 24/11/26
