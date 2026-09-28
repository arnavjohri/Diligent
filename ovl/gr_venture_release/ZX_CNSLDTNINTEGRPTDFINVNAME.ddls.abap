//----------------------------------------------------------------------
// Object    : ZX_CNSLDTNINTEGRPTDFINVNAME (DDL source, extend view)
// Extends   : I_CnsldtnIntegRptdFinData (GR Realtime Reported Data TAI)
// Purpose   : Expose coding-block custom field ZZ1_VNAME_COB (Venture)
//             to the Group Reporting data release task, so it can be
//             mapped to the ACDOCU custom field in "Data Release Task:
//             Define Mapping for Jrnl Entry to Group Jrnl Entry Fields"
// Reference : SAP deck slide 105 (customer view extension, OP only);
//             key-user usage "GR Realtime Reported Data - TAI" is not
//             offered in the Custom Fields app on this system
// Author    : Arnav Johri
// Date      : 28.09.2026
//----------------------------------------------------------------------
//BOC By Arnav on 28/09/26
// ASSUMPTION: ZZ1_VNAME_COB already exists on E_JournalEntryItem via the
// generated append ZZ1_DDHSAVE6EJDWDYO7JBVZNYNUNQ (seen in ADT).
// _Extension is the association I_CnsldtnIntegRptdFinData already
// defines to E_JournalEntryItem (ledger/CoCd/year/document/line item).
// Element named ZZ_ (not ZZ1_) so it cannot clash with a generated
// key-user extension if the TAI usage is enabled later.
@AbapCatalog.sqlViewAppendName: 'ZXINTFINVNAME'
@EndUserText.label: 'GR data release: Venture (ZZ1_VNAME_COB)'
extend view I_CnsldtnIntegRptdFinData with ZX_CNSLDTNINTEGRPTDFINVNAME
{
  _Extension.ZZ1_VNAME_COB as ZZ_VNAME_COB
}
//EOC By Arnav on 28/09/26
