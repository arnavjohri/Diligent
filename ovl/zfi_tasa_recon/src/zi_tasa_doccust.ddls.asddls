//----------------------------------------------------------------------
// Object    : ZI_TASA_DOCCUST (DDL source, classic view)
// Title     : TASA recon - customer of an accounting document
// Project   : OVL                                   Module: FI-GL
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheet P&L-TASA
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   The TASA income lines (G/L 230903) carry no customer: KUNNR, GKONT
//   and GKOAR are blank on all of them (OCD 500, FY26, checked
//   23.11.2026). The customer is on the customer line (KOART = 'D') of
//   the same document. This view gives that customer per document.
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: one customer per document. With two, MAX picks one; on
//   FY26 the per-customer totals tie to the workbook to the cent, so no
//   income document has two customers today.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASADOCCUST'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA recon: customer of a document'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_TASA_DOCCUST
  as select from acdoca
{
  key rbukrs       as company_code,
  key gjahr        as fiscal_year,
  key belnr        as accounting_doc,
      max( kunnr ) as customer
}
where
      rldnr = '0L'
  and koart = 'D'
group by
  rbukrs,
  gjahr,
  belnr
