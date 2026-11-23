//----------------------------------------------------------------------
// Object    : ZI_TASA_INC_ITEM (DDL source, classic view)
// Title     : TASA recon - TASA income line items with their partner
// Project   : OVL                                   Module: FI-GL
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheet P&L-TASA
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   One row per ACDOCA line of the TASA income G/L 230903, leading
//   ledger. Partner = the document's customer (ZI_TASA_DOCCUST), else
//   the document's G/L maintained in ZFI_TASA_MAP (ZI_TASA_DOCGL), else
//   empty ("Other" in the cube). Income is shown positive (credit).
//   Fiscal quarter from the posting period, April - March year.
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//   24.11.2026  Arnav Johri  OCDK920558  G/L partner only from the line
//               that exactly offsets the income line (JIB document fix)
//----------------------------------------------------------------------
// ASSUMPTION: special periods 013 - 016 count in Q4 (query 2 of
//   NOTES.md). None carried 230903 in FY26.
// ASSUMPTION: history is read as posted. FY23 and FY24 in SAP differ
//   from the workbook (+1,702,867.97 / +100,000.00 USD, checked
//   23.11.2026) - query 1 of NOTES.md.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASAINCITM'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: income line items'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_TASA_INC_ITEM
  as select from    acdoca          as Line
    left outer join ZI_TASA_DOCCUST as Cust on  Cust.company_code   = Line.rbukrs
                                            and Cust.fiscal_year    = Line.gjahr
                                            and Cust.accounting_doc = Line.belnr
    left outer join ZI_TASA_DOCGL   as Gl   on  Gl.company_code     = Line.rbukrs
                                            and Gl.fiscal_year      = Line.gjahr
                                            and Gl.accounting_doc   = Line.belnr
                                            and Gl.offset_usd       = Line.ksl   //Changes by Arnav on 24/11/26
{
  key Line.rbukrs                                     as company_code,
  key Line.gjahr                                      as fiscal_year,
  key Line.belnr                                      as accounting_doc,
  key Line.docln                                      as ledger_gl_item,
      Line.poper                                      as fiscal_period,
      case Line.poper
        when '001' then 'Q1'
        when '002' then 'Q1'
        when '003' then 'Q1'
        when '004' then 'Q2'
        when '005' then 'Q2'
        when '006' then 'Q2'
        when '007' then 'Q3'
        when '008' then 'Q3'
        when '009' then 'Q3'
        else            'Q4'
      end                                             as fiscal_quarter,
      coalesce( Cust.customer, Gl.gl_partner )        as partner,
      Cust.customer                                   as customer,
      Line.racct                                      as gl_account,
      Line.budat                                      as posting_date,
      Line.blart                                      as document_type,
      Line.sgtxt                                      as item_text,
      Line.zuonr                                      as assignment,
      Line.vname                                      as joint_venture,
      Line.rhcur                                      as co_code_currency,
      Line.rkcur                                      as global_currency,
      cast( 0 as abap.dec( 23, 2 ) )
        - cast( Line.ksl as abap.dec( 23, 2 ) )       as income_usd,
      cast( 0 as abap.dec( 23, 2 ) )
        - cast( Line.hsl as abap.dec( 23, 2 ) )       as income_inr
}
where
      Line.rldnr = '0L'
  and Line.racct = '0000230903'
