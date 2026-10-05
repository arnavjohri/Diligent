@AbapCatalog.sqlViewName: 'EFIJOURNALENTIT'
@AbapCatalog.preserveKey:true
@AbapCatalog.compiler.compareFilter:true 
@EndUserText.label: 'Include View for Journal Entry Item'
@VDM.viewType: #EXTENSION
@AccessControl.authorizationCheck: #PRIVILEGED_ONLY

@ObjectModel.usageType.sizeCategory: #XXL
@ObjectModel.usageType.dataClass:  #TRANSACTIONAL
@ObjectModel.usageType.serviceQuality: #D

//Do not use @ClientHandling.algorithm: #SESSION_VARIABLE for extension include views

define view E_JournalEntryItem
  as select from acdoca as Persistence
{

  key Persistence.rldnr  as SourceLedger,
  key Persistence.rbukrs as CompanyCode,
  key Persistence.gjahr  as FiscalYear,
  key Persistence.belnr  as AccountingDocument,
  key Persistence.docln  as LedgerGLLineItem

}
