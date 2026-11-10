//----------------------------------------------------------------------
// Object    : ZI_PBA_AGENDA_TF (DDL source, CDS table function)
// Title     : Per barrel analysis: ZFI_AGENDA rows for CDS views
// Project   : OVL                                   Module: FI-JVA
// Source    : Per_Barrel_Analysis_-_Annual_FY26_-_V3.xlsx, sheet PBA
// Author    : Arnav Johri                            Date: 10.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 1 of 4 for the Per Barrel Analysis report. ZFI_AGENDA holds
//   the last ZFI_PL run per project. Its value columns are DF34_DEC,
//   a type a CDS view on this release can read but not cast or
//   calculate with, so the table is read here through an AMDP method
//   (ZCL_PBA_AGENDA_TF=>GET_LINES) that returns ordinary DEC columns.
//   One row per company code / joint venture / ZFI_PL section / line /
//   fiscal year / period / product (OIL = crude oil column, GAS = gas
//   column).
//   Create and activate this object first, then the class, then
//   import the views.
//
// CHANGE HISTORY
//   10.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
@EndUserText.label: 'Per barrel analysis: ZFI_AGENDA rows'
@ClientHandling.type: #CLIENT_DEPENDENT
@ClientHandling.algorithm: #SESSION_VARIABLE
@AccessControl.authorizationCheck: #NOT_REQUIRED
define table function ZI_PBA_AGENDA_TF
  with parameters
    @Environment.systemField: #CLIENT
    p_clnt : abap.clnt
returns
{
  mandt          : abap.clnt;
  company_code   : abap.char( 4 );
  joint_venture  : abap.char( 6 );
  report_section : abap.char( 2 );
  line_text      : abap.char( 100 );
  fiscal_year    : abap.numc( 4 );
  report_period  : abap.char( 6 );
  product        : abap.char( 3 );
  line_value     : abap.dec( 16, 5 );
  quantity_mn    : abap.dec( 23, 11 );
}
implemented by method
  ZCL_PBA_AGENDA_TF=>GET_LINES;
