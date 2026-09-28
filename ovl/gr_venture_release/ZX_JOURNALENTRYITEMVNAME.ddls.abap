//----------------------------------------------------------------------
// Object    : ZX_JOURNALENTRYITEMVNAME (DDL source, extend view)
// Extends   : E_JournalEntryItem (extension include view on ACDOCA)
// Purpose   : Expose standard ACDOCA-VNAME (Joint Venture) so the
//             Group Reporting view I_CnsldtnIntegRptdFinData can read it
//             through its _Extension association (slide 105, case 3)
// Next      : ZX_CNSLDTNINTEGRPTDFINVNAME adds _Extension.ZZ_VNAME
// Author    : Arnav Johri
// Date      : 28.09.2026
//----------------------------------------------------------------------
//BOC By Arnav on 28/09/26
// Persistence is the ACDOCA alias used in E_JournalEntryItem itself.
// Element named ZZ_ so it cannot clash with SAP or key-user appends.
@AbapCatalog.sqlViewAppendName: 'ZXEFIJEIVNAME'
@EndUserText.label: 'Journal entry item ext: Joint Venture'
extend view E_JournalEntryItem with ZX_JOURNALENTRYITEMVNAME
{
  Persistence.vname as ZZ_VNAME
}
//EOC By Arnav on 28/09/26
