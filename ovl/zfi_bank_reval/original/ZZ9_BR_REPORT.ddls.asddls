@AbapCatalog.sqlViewName : 'ZZ9_M8G5FS3XP4U2'
@EndUserText.label: 'Journal Entry Analyzer'
@VDM.viewType: #CONSUMPTION

@Analytics.query: true

@Analytics.settings.maxProcessingEffort: #HIGH

@AccessControl.authorizationCheck: #PRIVILEGED_ONLY
@ClientHandling.algorithm: #SESSION_VARIABLE
@AbapCatalog.buffering.status: #NOT_ALLOWED
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.usageType.sizeCategory: #XXL
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MIXED
@ObjectModel.modelingPattern: #ANALYTICAL_QUERY
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_QUERY ]
@OData.publish: true

define view ZZ9_BR_REPORT
  with parameters
    @Consumption.hidden: true
    @Environment.systemField: #SYSTEM_LANGUAGE
    P_Language : sylangu,
    @Semantics.businessDate.at: true
    @Environment.systemField: #SYSTEM_DATE
    P_KeyDate  : vdm_v_key_date

  as select from I_GLAccountLineItemCube as I_GLAccountLineItemCube
{

  @Consumption.filter: {selectionType: #SINGLE, multipleSelections: false, mandatory: true}
  @Consumption.derivation: { lookupEntity: 'I_Ledger',
        resultElement: 'Ledger', binding: [
        { targetElement : 'IsLeadingLedger' , type : #CONSTANT, value : 'X' } ]
       }
  @AnalyticsDetails.query.variableSequence : 10
  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.display: #KEY_TEXT
  Ledger,

  @Consumption.filter: {selectionType: #RANGE, multipleSelections: true, mandatory: true}
  @AnalyticsDetails.query.variableSequence : 20
  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #SHOW
  @AnalyticsDetails.query.display: #KEY_TEXT
  CompanyCode,


  
  
  @AnalyticsDetails.query.axis: #ROWS
  @AnalyticsDetails.query.totals: #SHOW
  @AnalyticsDetails.query.display: #KEY_TEXT
  
  @AnalyticsDetails.query.displayHierarchy: #ON
  @AnalyticsDetails.query.hierarchyInitialLevel: 99
  @AnalyticsDetails.query.hierarchyBinding : [
{type :#CONSTANT,value :'H109/ONGC/BANK_REVAL'}
]
  GLAccount,

  @Consumption.filter: { selectionType: #SINGLE, multipleSelections: true, mandatory: false }
  @Consumption.derivation: { lookupEntity: 'I_CalendarDate',
        resultElement: 'CalendarYear', binding: [
        { targetElement : 'CalendarDate' , type : #PARAMETER, value : 'P_KeyDate' } ]
       }
  @AnalyticsDetails.query.variableSequence: 40
  @AnalyticsDetails.query.axis: #FREE
  LedgerFiscalYear,

  @AnalyticsDetails.query.axis: #FREE
  JrnlEntrAltvFYConsecutiveID,

  @Consumption.filter: { selectionType: #RANGE, multipleSelections: true, mandatory: false }
  @AnalyticsDetails.query.variableSequence: 50
  @AnalyticsDetails.query.axis: #FREE
  FiscalPeriod,

  @Consumption.filter: { selectionType: #RANGE, multipleSelections: true, mandatory: false }
  @AnalyticsDetails.query.variableSequence: 60
  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.totals: #SHOW
  PostingDate,

  @Consumption.filter: { selectionType: #SINGLE, multipleSelections: true, mandatory: false }
  @AnalyticsDetails.query.variableSequence: 70
  @AnalyticsDetails.query.axis: #FREE
  FinancialTransactionType,

  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.display: #KEY_TEXT
  Segment,

  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.display: #KEY_TEXT
  ProfitCenter,

  @AnalyticsDetails.query.axis: #FREE
  @Consumption.filter: { selectionType: #RANGE, multipleSelections: true, mandatory: false }
  @AnalyticsDetails.query.resultValueHelpSource: #DIMENSION
  AccountingDocument,

  ///////////////////////////////////////////////////////////////////////
  // Measures - Amounts
  ///////////////////////////////////////////////////////////////////////
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  CompanyCodeCurrency,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  GlobalCurrency,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FunctionalCurrency,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  BalanceTransactionCurrency,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  TransactionCurrency,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency1,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency2,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency3,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency4,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency5,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency6,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency7,
  @Semantics.currencyCode: true
  @AnalyticsDetails.query.axis: #FREE
  FreeDefinedCurrency8,

  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  @AnalyticsDetails.query.axis: #COLUMNS
  
  @Consumption.semanticObject: 'GLAccount'
  AmountInCompanyCodeCurrency,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  @Consumption.semanticObject: 'GLAccount'
  AmountInTransactionCurrency,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
  @Consumption.semanticObject: 'GLAccount'
  AmountInGlobalCurrency,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FunctionalCurrency'} }
  AmountInFunctionalCurrency,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'BalanceTransactionCurrency'} }
  AmountInBalanceTransacCrcy,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency1'} }
  AmountInFreeDefinedCurrency1,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency2'} }
  AmountInFreeDefinedCurrency2,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency3'} }
  AmountInFreeDefinedCurrency3,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency4'} }
  AmountInFreeDefinedCurrency4,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency5'} }
  AmountInFreeDefinedCurrency5,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency6'} }
  AmountInFreeDefinedCurrency6,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency7'} }
  AmountInFreeDefinedCurrency7,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency8'} }
  AmountInFreeDefinedCurrency8,


  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  @AnalyticsDetails.query.hidden : true
  
  DebitAmountInCoCodeCrcy,
  @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
  @AnalyticsDetails.query.hidden : true
  
  CreditAmountInCoCodeCrcy,
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  DebitAmountInGlobalCrcy,
  @Semantics: { amount : {currencyCode: 'GlobalCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  CreditAmountInGlobalCrcy,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FunctionalCurrency'} }
  DebitAmountInFunctionalCrcy,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FunctionalCurrency'} }
  CreditAmountInFunctionalCrcy,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  DebitAmountInTransCrcy,
  @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  CreditAmountInTransCrcy,
  @Semantics: { amount : {currencyCode: 'BalanceTransactionCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  DebitAmountInBalanceTransCrcy,
  @Semantics: { amount : {currencyCode: 'BalanceTransactionCurrency'} }
  @AnalyticsDetails.query.hidden : true
  
  CreditAmountInBalanceTransCrcy,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency1'} }
  DebitAmountInFreeDefinedCrcy1,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency1'} }
  CreditAmountInFreeDefinedCrcy1,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency2'} }
  DebitAmountInFreeDefinedCrcy2,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency2'} }
  CreditAmountInFreeDefinedCrcy2,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency3'} }
  DebitAmountInFreeDefinedCrcy3,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency3'} }
  CreditAmountInFreeDefinedCrcy3,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency4'} }
  DebitAmountInFreeDefinedCrcy4,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency4'} }
  CreditAmountInFreeDefinedCrcy4,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency5'} }
  DebitAmountInFreeDefinedCrcy5,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency5'} }
  CreditAmountInFreeDefinedCrcy5,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency6'} }
  DebitAmountInFreeDefinedCrcy6,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency6'} }
  CreditAmountInFreeDefinedCrcy6,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency7'} }
  DebitAmountInFreeDefinedCrcy7,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency7'} }
  CreditAmountInFreeDefinedCrcy7,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency8'} }
  DebitAmountInFreeDefinedCrcy8,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { amount : {currencyCode: 'FreeDefinedCurrency8'} }
  CreditAmountInFreeDefinedCrcy8,

  ///////////////////////////////////////////////////////////////////////
  // Measures - Quantities
  ///////////////////////////////////////////////////////////////////////

  @Semantics.unitOfMeasure: true
  @AnalyticsDetails.query.axis: #FREE
  CostSourceUnit,
  @Semantics.unitOfMeasure: true
  @AnalyticsDetails.query.axis: #FREE
  BaseUnit,
  @Semantics.unitOfMeasure: true
  @AnalyticsDetails.query.axis: #FREE
  AdditionalQuantity1Unit,
  @Semantics.unitOfMeasure: true
  @AnalyticsDetails.query.axis: #FREE
  AdditionalQuantity2Unit,
  @Semantics.unitOfMeasure: true
  @AnalyticsDetails.query.axis: #FREE
  AdditionalQuantity3Unit,


  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { quantity : {unitOfMeasure: 'AdditionalQuantity1Unit'} }
  AdditionalQuantity1,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { quantity : {unitOfMeasure: 'AdditionalQuantity2Unit'} }
  AdditionalQuantity2,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { quantity : {unitOfMeasure: 'AdditionalQuantity3Unit'} }
  AdditionalQuantity3,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { quantity : {unitOfMeasure: 'CostSourceUnit'} }
  ValuationQuantity,
  @AnalyticsDetails.query.hidden : true
  
  @Semantics: { quantity : {unitOfMeasure: 'BaseUnit'} }
  Quantity,



  ///////////////////////////////////////////////////////////////////////
  // Dimensions
  ///////////////////////////////////////////////////////////////////////


  @AnalyticsDetails.query.axis: #FREE
  DebitCreditCode,

  @AnalyticsDetails.query.axis: #FREE
  AccountingDocumentType,

  @AnalyticsDetails.query.axis: #FREE
  PostingKey,

  @AnalyticsDetails.query.axis: #FREE
  OffsettingAccount,

  @AnalyticsDetails.query.axis: #FREE
  AssignmentReference,

  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.display: #KEY_TEXT
  CostCenter,
  @AnalyticsDetails.query.axis: #FREE
  AccountingDocumentItem,
  @AnalyticsDetails.query.axis: #FREE
  DocumentDate,

  @AnalyticsDetails.query.axis: #FREE
  LedgerGLLineItem,
  @AnalyticsDetails.query.axis: #FREE
  TransactionTypeDetermination,
  @AnalyticsDetails.query.axis: #FREE
  AccountingDocCreatedByUser,
  @AnalyticsDetails.query.axis: #FREE
  CreationDate,
  @AnalyticsDetails.query.axis: #FREE
  ChartOfAccounts,
  @Consumption.filter: { selectionType: #SINGLE, multipleSelections: true, mandatory: false }
  @AnalyticsDetails.query.variableSequence: 35
  @AnalyticsDetails.query.totals: #SHOW
  @AnalyticsDetails.query.display: #KEY_TEXT
  @AnalyticsDetails.query.axis: #FREE
  AlternativeGLAccount,
  @AnalyticsDetails.query.axis: #FREE
  CountryChartOfAccounts,
  @AnalyticsDetails.query.axis: #FREE
  InvoiceReference,
  @AnalyticsDetails.query.axis: #FREE
  InvoiceReferenceFiscalYear,
  @AnalyticsDetails.query.axis: #FREE
  FollowOnDocumentType,
  @AnalyticsDetails.query.axis: #FREE
  InvoiceItemReference,
  @AnalyticsDetails.query.axis: #FREE
  ReferencePurchaseOrderCategory,
  @AnalyticsDetails.query.axis: #FREE
  PurchasingDocument,
  @AnalyticsDetails.query.axis: #FREE
  PurchasingDocumentItem,
  @AnalyticsDetails.query.axis: #FREE
  AccountAssignmentNumber,
  @AnalyticsDetails.query.axis: #FREE
  DocumentItemText,
  @AnalyticsDetails.query.axis: #FREE
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'SalesDocument'
  SalesOrder,
  @AnalyticsDetails.query.axis: #FREE
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'SalesDocumentItem'
  SalesOrderItem,
  @AnalyticsDetails.query.axis: #FREE
  SalesDocument,
  @AnalyticsDetails.query.axis: #FREE
  SalesDocumentItem,
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'Product'
  @AnalyticsDetails.query.axis: #FREE
  Material, // do not use any longer, use Product
  @AnalyticsDetails.query.axis: #FREE
  Product,
  @AnalyticsDetails.query.axis: #FREE
  Plant,
  @AnalyticsDetails.query.axis: #FREE
  Supplier,
  @AnalyticsDetails.query.axis: #FREE
  Customer,
  @AnalyticsDetails.query.axis: #FREE
  FinancialAccountType,
  @AnalyticsDetails.query.axis: #FREE
  SpecialGLCode,
  @AnalyticsDetails.query.axis: #FREE
  TaxCode,
  @AnalyticsDetails.query.axis: #FREE
  TaxCountry,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.filter :{ selectionType: #SINGLE, multipleSelections: false, mandatory: false }
  HouseBank,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.filter :{ selectionType: #SINGLE, multipleSelections: false, mandatory: false }
  HouseBankAccount,
  @AnalyticsDetails.query.axis: #FREE
  IsOpenItemManaged,
  @AnalyticsDetails.query.axis: #FREE
  ClearingDate,

  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'ClearingJournalEntry'
  @AnalyticsDetails.query.axis: #FREE
  ClearingAccountingDocument,
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'ClearingJournalEntryFiscalYear'
  @AnalyticsDetails.query.axis: #FREE
  ClearingDocFiscalYear,
  @AnalyticsDetails.query.axis: #FREE
  ClearingJournalEntry,
  @AnalyticsDetails.query.axis: #FREE
  ClearingJournalEntryFiscalYear,

  @AnalyticsDetails.query.axis: #FREE
  MasterFixedAsset,
  @AnalyticsDetails.query.axis: #FREE
  FixedAsset,
  @AnalyticsDetails.query.axis: #FREE
  AssetValueDate,
  @AnalyticsDetails.query.axis: #FREE
  
  
  InventorySpecialStockValnType,
  @AnalyticsDetails.query.axis: #FREE
  InvtrySpecialStockValnType_2,
  @AnalyticsDetails.query.axis: #FREE
  InventorySpecialStockType,
  @AnalyticsDetails.query.axis: #FREE
  InventoryValuationType,
  @AnalyticsDetails.query.axis: #FREE
  ValuationArea,
  @AnalyticsDetails.query.axis: #FREE
  OffsettingAccountType,
  @AnalyticsDetails.query.axis: #FREE
  LineItemIsCompleted,
  @AnalyticsDetails.query.axis: #FREE
  PersonnelNumber,
  @AnalyticsDetails.query.axis: #FREE
  ControllingObjectClass,
  @AnalyticsDetails.query.axis: #FREE
  PartnerControllingObjectClass,
  @AnalyticsDetails.query.axis: #FREE
  PartnerCompany,
  @AnalyticsDetails.query.axis: #FREE
  CostCtrActivityType,
  @AnalyticsDetails.query.axis: #FREE
  OrderID,
  @AnalyticsDetails.query.axis: #FREE
  OrderCategory,
  @AnalyticsDetails.query.axis: #FREE
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'WBSElementExternalID'
  WBSElement,
  @AnalyticsDetails.query.axis: #FREE
  WBSElementExternalID,
  @AnalyticsDetails.query.axis: #FREE
  OperatingConcern,
  @AnalyticsDetails.query.axis: #FREE
  PartnerCostCtrActivityType,
  @AnalyticsDetails.query.axis: #FREE
  BillingDocumentType,
  @AnalyticsDetails.query.axis: #FREE
  SalesOrganization,
  @AnalyticsDetails.query.axis: #FREE
  DistributionChannel,
  @AnalyticsDetails.query.axis: #FREE
  OrganizationDivision,
  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.display: #KEY_TEXT
  ControllingArea,
  @AnalyticsDetails.query.axis: #FREE
  @AnalyticsDetails.query.display: #KEY_TEXT
  FunctionalArea,
  @AnalyticsDetails.query.axis: #FREE
  AccountAssignment,
  @AnalyticsDetails.query.axis: #FREE
  AccountAssignmentType,
  @AnalyticsDetails.query.axis: #FREE
  AccountingDocumentCategory,
  @AnalyticsDetails.query.axis: #FREE
  AssetDepreciationArea,
  @AnalyticsDetails.query.axis: #FREE
  BudgetPeriod,
  @AnalyticsDetails.query.axis: #FREE
  BusinessProcess,
  @AnalyticsDetails.query.axis: #FREE
  BusinessTransactionCategory,
  @AnalyticsDetails.query.axis: #FREE
  BusinessTransactionType,
  @AnalyticsDetails.query.axis: #FREE
  ControllingObjectDebitType,
  @AnalyticsDetails.query.axis: #FREE
  CostEstimate,
  @AnalyticsDetails.query.axis: #FREE
  CostObject,
  @AnalyticsDetails.query.axis: #FREE
  CustomerGroup,
  @AnalyticsDetails.query.axis: #FREE
  CustomerServiceNotification,
  @AnalyticsDetails.query.axis: #FREE
  DepreciationFiscalPeriod,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.semanticObject: 'ProfitCenter'
  EliminationProfitCenter,
  @AnalyticsDetails.query.axis: #FREE
  AssetTransactionType,
  @AnalyticsDetails.query.axis: #FREE
  Fund,
  @AnalyticsDetails.query.axis: #FREE
  FinancialManagementArea,
  //  @AnalyticsDetails.query.axis: #FREE
  //  CommitmentItem,
  //  @AnalyticsDetails.query.axis: #FREE
  //  EarmarkedFundsDocument,
  //  @AnalyticsDetails.query.axis: #FREE
  //  EarmarkedFundsDocumentItem,
  //  @AnalyticsDetails.query.axis: #FREE
  //  FundsCenter,
  //  @AnalyticsDetails.query.axis: #FREE
  //  FundedProgram,
  @AnalyticsDetails.query.axis: #FREE
  GLAccountType,
  @AnalyticsDetails.query.axis: #FREE
  GrantID,
  @AnalyticsDetails.query.axis: #FREE
  GroupFixedAsset,
  @AnalyticsDetails.query.axis: #FREE
  GroupMasterFixedAsset,
  @AnalyticsDetails.query.axis: #FREE
  InventorySpclStkSalesDocItm,
  @AnalyticsDetails.query.axis: #FREE
  InventorySpclStkSalesDocument,
  @AnalyticsDetails.query.axis: #FREE
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'InvtrySpclStockWBSElmntExtID'
  InventorySpclStockWBSElement,
  @AnalyticsDetails.query.axis: #FREE
  InvtrySpclStockWBSElmntExtID,
  @AnalyticsDetails.query.axis: #FREE
  InventorySpecialStockSupplier,
  @AnalyticsDetails.query.axis: #FREE
  IsReversal,
  @AnalyticsDetails.query.axis: #FREE
  IsReversed,
  @AnalyticsDetails.query.axis: #FREE
  IsSettled,
  @AnalyticsDetails.query.axis: #FREE
  IsSettlement,
  @AnalyticsDetails.query.axis: #FREE
  JointVenture,
  @AnalyticsDetails.query.axis: #FREE
  JointVentureCostRecoveryCode,
  @AnalyticsDetails.query.axis: #FREE
  JointVentureEquityGroup,
  @AnalyticsDetails.query.axis: #FREE
  JointVentureEquityType,
  @AnalyticsDetails.query.axis: #FREE
  LogicalSystem,
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'SoldProductGroup'
  @AnalyticsDetails.query.axis: #FREE
  MaterialGroup, // do not use any longer, use ProductGroup
  @AnalyticsDetails.query.axis: #FREE
  SoldProductGroup,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.semanticObject: 'CostCenter'
  OriginCostCenter,
  @AnalyticsDetails.query.axis: #FREE
  OriginCostCtrActivityType,
  @AnalyticsDetails.query.axis: #FREE
  OriginObjectType,
  @AnalyticsDetails.query.axis: #FREE
  PartnerAccountAssignment,
  @AnalyticsDetails.query.axis: #FREE
  PartnerAccountAssignmentType,
  @AnalyticsDetails.query.axis: #FREE
  PartnerBudgetPeriod,
  @AnalyticsDetails.query.axis: #FREE
  PartnerBusinessArea,
  @AnalyticsDetails.query.axis: #FREE
  PartnerBusinessProcess,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.semanticObject: 'CompanyCode'
  PartnerCompanyCode,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.semanticObject: 'CostCenter'
  PartnerCostCenter,
  @AnalyticsDetails.query.axis: #FREE
  PartnerCostObject,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.semanticObject: 'FunctionalArea'
  PartnerFunctionalArea,
  @AnalyticsDetails.query.axis: #FREE
  PartnerFund,
  @AnalyticsDetails.query.axis: #FREE
  PartnerGrant,
  @AnalyticsDetails.query.axis: #FREE
  
  
  //  @VDM.lifecycle.status:     #DEPRECATED
  //  @VDM.lifecycle.successor:  'PartnerOrder_2'
  PartnerOrder,
  @Analytics.internalName: #LOCAL
  @AnalyticsDetails.query.axis: #FREE
  PartnerOrder_2,
  @AnalyticsDetails.query.axis: #FREE
  PartnerOrderCategory,
  @AnalyticsDetails.query.axis: #FREE
  @Consumption.semanticObject: 'ProfitCenter'
  PartnerProfitCenter,
  @AnalyticsDetails.query.axis: #FREE
  
  
  PartnerProject,
  @AnalyticsDetails.query.axis: #FREE
  PartnerProjectExternalID,
  @AnalyticsDetails.query.axis: #FREE
  PartnerProjectNetwork,
  @AnalyticsDetails.query.axis: #FREE
  PartnerProjectNetworkActivity,
  @AnalyticsDetails.query.axis: #FREE
  PartnerSalesDocument,
  @AnalyticsDetails.query.axis: #FREE
  PartnerSalesDocumentItem,
  @AnalyticsDetails.query.axis: #FREE
  PartnerSegment,
  @AnalyticsDetails.query.axis: #FREE
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'PartnerWBSElementExternalID'
  PartnerWBSElement,
  @AnalyticsDetails.query.axis: #FREE
  PartnerWBSElementExternalID,
  @AnalyticsDetails.query.axis: #FREE
  PredecessorReferenceDocCntxt,
  @AnalyticsDetails.query.axis: #FREE
  PredecessorReferenceDocItem,
  @AnalyticsDetails.query.axis: #FREE
  PredecessorReferenceDocType,
  @AnalyticsDetails.query.axis: #FREE
  PredecessorReferenceDocument,
  @AnalyticsDetails.query.axis: #FREE
  
  
  Project,
  @AnalyticsDetails.query.axis: #FREE
  ProjectExternalID,
  @AnalyticsDetails.query.axis: #FREE
  ProjectNetwork,
  @AnalyticsDetails.query.axis: #FREE
  QuantityIsIncomplete,
  @AnalyticsDetails.query.axis: #FREE
  ReferenceDocument,
  @AnalyticsDetails.query.axis: #FREE
  ReferenceDocumentContext,
  @AnalyticsDetails.query.axis: #FREE
  ReferenceDocumentItem,
  @AnalyticsDetails.query.axis: #FREE
  ReferenceDocumentItemGroup,
  @AnalyticsDetails.query.axis: #FREE
  ReferenceDocumentType,
  @AnalyticsDetails.query.axis: #FREE
  RelatedNetworkActivity,
  @AnalyticsDetails.query.axis: #FREE
  ReversalReferenceDocument,
  @AnalyticsDetails.query.axis: #FREE
  ReversalReferenceDocumentCntxt,
  @AnalyticsDetails.query.axis: #FREE
  SenderAccountAssignment,
  @AnalyticsDetails.query.axis: #FREE
  SenderAccountAssignmentType,
  @AnalyticsDetails.query.axis: #FREE
  SenderGLAccount,
  @AnalyticsDetails.query.axis: #FREE
  SettlementReferenceDate,
  
  
  //  @VDM.lifecycle.status:    #DEPRECATED
  //  @VDM.lifecycle.successor: 'SoldProduct'
  @AnalyticsDetails.query.axis: #FREE
  SoldMaterial, // do not use any longer, use SoldProduct
  @AnalyticsDetails.query.axis: #FREE
  SoldProduct,
  @AnalyticsDetails.query.axis: #FREE
  BusinessArea,
  @AnalyticsDetails.query.axis: #FREE
  FiscalYear,
  //  @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false, mandatory: false }
  @Consumption.filter: { selectionType: #RANGE, multipleSelections: true, mandatory: false }
  @AnalyticsDetails.query.variableSequence: 55
  @AnalyticsDetails.query.axis: #FREE
  FiscalYearPeriod,
  @AnalyticsDetails.query.axis: #FREE
  // Has to be taken out for now to avoid a deadlock when entering a not valid fiscal year period
  //  @Consumption.filter.hidden: true
  //  @Consumption.filter: {selectionType: #SINGLE, multipleSelections: true}
  //  @Consumption.derivation: {
  //    lookupEntity: 'I_LedgerCompanyCodeCrcyRoles', resultElement: 'FiscalYearVariant',
  //      binding: [{targetElement: 'Ledger', type: #ELEMENT, value: 'Ledger'},
  //                {targetElement: 'CompanyCode', type: #ELEMENT, value: 'CompanyCode'}]
  //  }
  FiscalYearVariant,
  @AnalyticsDetails.query.axis: #FREE
  LastChangeDateTime,
  @AnalyticsDetails.query.axis: #FREE
  CreationDateTime,
  @AnalyticsDetails.query.axis: #FREE
  AssetAcctTransClassfctn,
  @AnalyticsDetails.query.axis: #FREE
  InvtrySpclStockWBSElmntIntID,
  @AnalyticsDetails.query.axis: #FREE
  AccrualObjectType,
  @AnalyticsDetails.query.axis: #FREE
  AccrualObject,
  @AnalyticsDetails.query.axis: #FREE
  AccrualSubobject,
  @AnalyticsDetails.query.axis: #FREE
  AccrualItemType,
  @AnalyticsDetails.query.axis: #FREE
  AccrualValueDate,
  @Consumption.hidden : true
  $parameters.P_Language as P_Language_param,
  @Consumption.hidden : true
  $parameters.P_KeyDate as P_KeyDate_param



};
