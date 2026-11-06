@AbapCatalog: {
    sqlViewName: 'IMCRPTC',
    compiler.compareFilter: true,
    buffering.status: #NOT_ALLOWED
}
@AccessControl: {
    authorizationCheck: #CHECK
}
@ClientHandling: {
    algorithm: #SESSION_VARIABLE
}
@Metadata: {
    allowExtensions:true,
    ignorePropagatedAnnotations: true
}
@ObjectModel: {
    usageType: {
        sizeCategory: #XL,
        serviceQuality: #D,
        dataClass: #MIXED
    },
    supportedCapabilities: [ #ANALYTICAL_PROVIDER, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ],
    modelingPattern: #ANALYTICAL_CUBE
}
@Analytics: {
    dataCategory: #CUBE
}
@VDM: {
    viewType: #COMPOSITE,
    lifecycle.contract.type:#PUBLIC_LOCAL_API,
    lifecycle.status: #DEPRECATED,
    lifecycle.successor: 'I_MATRIXCNSLDTNREPORTC_2'
}
@Analytics.readClassName: 'CL_FINCS_GRA_CUBE_REL'
@EndUserText.label: 'Group Data Analysis - Cube'

define view I_MatrixConsolidationReportC
  with parameters
    @Consumption.defaultValue: '$'
    @Consumption.valueHelp: '_CnsldtnUnitHierDir'
    P_ConsolidationUnitHierarchy : fincs_hryid_consunit,

    @Consumption.defaultValue: '$'
    @Consumption.valueHelp: '_ProfitCenterHierDir'
    P_ConsolidationPrftCtrHier   : fincs_hryid_profitcenter,

    @Consumption.defaultValue: '$'
    @Consumption.valueHelp: '_SegmentHierDir'
    P_ConsolidationSegmentHier   : fincs_hryid_segment,

    @Semantics.businessDate.at: true
    @Environment.systemField: #SYSTEM_DATE
    P_KeyDate                    : vdm_v_key_date

  as select from I_MatrixCnsldtnFoundation
                 ( P_ConsolidationUnitHierarchy: $parameters.P_ConsolidationUnitHierarchy,
                 P_ConsolidationPrftCtrHier: $parameters.P_ConsolidationPrftCtrHier,
                 P_ConsolidationSegmentHier: $parameters.P_ConsolidationSegmentHier,
                 P_KeyDate: $parameters.P_KeyDate ) as MatrixCnsldtnFoundation

  //Extension Association
  association [1..1] to E_CnsldtnGroupJrnlEntryItem    as _Extension                  on  $projection.ConsolidationLedger         = _Extension.ConsolidationLedger
                                                                                      and $projection.ConsolidationDimension      = _Extension.ConsolidationDimension
                                                                                      and $projection.FiscalYear                  = _Extension.FiscalYear
                                                                                      and $projection.ConsolidationDocumentNumber = _Extension.CnsldtnGroupJrnlEntry
                                                                                      and $projection.ConsolidationPostingItem    = _Extension.CnsldtnGroupJrnlEntryItem

  association [1..1] to I_CnsldtnLedger                as _Ledger                     on  $projection.ConsolidationLedger = _Ledger.ConsolidationLedger

  association [1..1] to I_CnsldtnDimension             as _Dimension                  on  $projection.ConsolidationDimension = _Dimension.ConsolidationDimension

  association [1..1] to I_CnsldtnVersion               as _Version                    on  $projection.ConsolidationVersion = _Version.ConsolidationVersion

  association [1..1] to I_CnsldtnVersion               as _VersionElement             on  $projection.ConsolidationVersionElement = _VersionElement.ConsolidationVersion

  association [1..1] to I_Globalcompany                as _Company                    on  $projection.Company = _Company.Company

  association [0..1] to I_DebitCreditCode              as _DebitCreditCode            on  $projection.DebitCreditCode = _DebitCreditCode.DebitCreditCode

  //Deprecation of association I_CnsldtnUnit_2
  association [1..1] to I_CnsldtnUnit_2                as _CnsldtnUnit                on  $projection.ConsolidationDimension = _CnsldtnUnit.ConsolidationDimension
                                                                                      and $projection.ConsolidationUnit      = _CnsldtnUnit.ConsolidationUnit

  association [1..1] to I_CnsldtnUnit_3                as _CnsldtnUnit_3              on $projection.ConsolidationUnit     = _CnsldtnUnit_3.ConsolidationUnit


  association [1..1] to I_CnsldtnUnitForElimination    as _CnsldtnUnitForElimination  on  $projection.ConsolidationDimension   = _CnsldtnUnitForElimination.ConsolidationDimension
                                                                                      and $projection.ConsolidationUnitForElim = _CnsldtnUnitForElimination.ConsolidationUnit

  association [1..1] to I_CnsldtnGroupWithEmptyValue   as _CnsldtnGroup               on  $projection.ConsolidationDimension = _CnsldtnGroup.ConsolidationDimension
                                                                                      and $projection.ConsolidationGroup     = _CnsldtnGroup.ConsolidationGroup

  association [1..1] to I_CnsldtnChartOfAccounts       as _ChartOfAccounts            on  $projection.ConsolidationChartOfAccounts = _ChartOfAccounts.ConsolidationChartOfAccounts

  association [1..1] to I_GroupReportingFSItem         as _FinStmntItm                on  $projection.ConsolidationChartOfAccounts = _FinStmntItm.ConsolidationChartOfAccounts
                                                                                      and $projection.FinancialStatementItem       = _FinStmntItm.FinancialStatementItem
  //Deprecation of association I_CnsldtnUnit_2
  association [0..1] to I_CnsldtnUnit_2                as _PartnerUnit                on  $projection.ConsolidationDimension   = _PartnerUnit.ConsolidationDimension
                                                                                      and $projection.PartnerConsolidationUnit = _PartnerUnit.ConsolidationUnit

  association [0..1] to I_CnsldtnUnit_3                as _PartnerUnit_3              on $projection.PartnerConsolidationUnit = _PartnerUnit_3.ConsolidationUnit



  association [0..1] to I_CompanyCode                  as _CompanyCode                on  $projection.CompanyCode = _CompanyCode.CompanyCode

  association [0..1] to I_CnsldtnGLAccount             as _GLAccountInChartOfAccounts on  $projection.ChartOfAccounts = _GLAccountInChartOfAccounts.ChartOfAccounts
                                                                                      and $projection.GLAccount       = _GLAccountInChartOfAccounts.GLAccount

  association [0..1] to I_CnsldtnGLChartOfAccounts     as _GLChartOfAccounts          on  $projection.ChartOfAccounts = _GLChartOfAccounts.ChartOfAccounts

  association [0..1] to I_CnsldtnSubItemCategory       as _SubItemCategory            on  $projection.SubItemCategory = _SubItemCategory.SubItemCategory

  association [0..1] to I_CnsldtnSubItem               as _SubItem                    on  $projection.SubItemCategory = _SubItem.SubItemCategory
                                                                                      and $projection.SubItem         = _SubItem.SubItem

  association [1..1] to I_CnsldtnDocumentType          as _DocumentType               on  $projection.ConsolidationDimension    = _DocumentType.ConsolidationDimension
                                                                                      and $projection.ConsolidationDocumentType = _DocumentType.ConsolidationDocumentType

  association [1..1] to I_CnsldtnPostingLevel          as _PostingLevel               on  $projection.PostingLevel = _PostingLevel.PostingLevel

  //Deprecation of association I_CnsldtnUnit_2
  association [0..1] to I_CnsldtnUnit_2                as _InvesteeUnit               on  $projection.ConsolidationDimension    = _InvesteeUnit.ConsolidationDimension
                                                                                      and $projection.InvesteeConsolidationUnit = _InvesteeUnit.ConsolidationUnit

  association [0..1] to I_CnsldtnUnit_3                as _InvesteeUnit_3             on $projection.InvesteeConsolidationUnit  = _InvesteeUnit_3.ConsolidationUnit


  association [1..1] to I_CnsldtnApportionment         as _Apportionment              on  $projection.ConsolidationApportionment = _Apportionment.ConsolidationApportionment

  association [1..1] to I_CnsldtnCrcyCnvrsnDiffType    as _CrcyCnvrsnDiffType         on  $projection.CurrencyConversionsDiffType = _CrcyCnvrsnDiffType.CurrencyConversionsDiffType

  association [0..1] to I_Currency                     as _TransactionCurrency        on  $projection.TransactionCurrency = _TransactionCurrency.Currency

  association [0..1] to I_Currency                     as _LocalCurrency              on  $projection.LocalCurrency = _LocalCurrency.Currency

  association [0..1] to I_Currency                     as _GroupCurrency              on  $projection.GroupCurrency = _GroupCurrency.Currency

  association [0..1] to I_UnitOfMeasure                as _BaseUnit                   on  $projection.BaseUnit = _BaseUnit.UnitOfMeasure

  association [0..1] to I_CnsldtnInternalOrder         as _InternalOrder              on  $projection.OrderID = _InternalOrder.InternalOrder

  association [0..1] to I_CnsldtnCustomer              as _Customer                   on  $projection.Customer = _Customer.Customer

  association [0..1] to I_CnsldtnSupplier              as _Supplier                   on  $projection.Supplier = _Supplier.Supplier

  association [0..1] to I_CnsldtnMaterial              as _Material                   on  $projection.Material = _Material.Material

  association [0..1] to I_CnsldtnMaterialGroup         as _MaterialGroup              on  $projection.MaterialGroup = _MaterialGroup.MaterialGroup

  association [0..1] to I_CnsldtnPlant                 as _Plant                      on  $projection.Plant = _Plant.Plant

  association [0..1] to I_CnsldtnFinTransType          as _FinancialTransactionType   on  $projection.FinancialTransactionType = _FinancialTransactionType.FinancialTransactionType

  association [0..1] to I_CnsldtnWBSElement            as _WBSElement                 on  $projection.Project              = _WBSElement.Project
                                                                                      and $projection.WBSElementExternalID = _WBSElement.WBSElement

  association [0..1] to I_WBSElementBasicData          as _WBSElementInternalID       on  $projection.WBSElementInternalID = _WBSElementInternalID.WBSElementInternalID

  association [0..1] to I_CnsldtnProject               as _Project                    on  $projection.Project = _Project.Project

  association [0..1] to I_CnsldtnCostCenter            as _CostCenter                 on  $projection.ControllingArea = _CostCenter.ControllingArea
                                                                                      and $projection.CostCenter      = _CostCenter.CostCenter

  association [0..1] to I_CnsldtnProfitCenter          as _ProfitCenter               on  $projection.ControllingArea = _ProfitCenter.ControllingArea
                                                                                      and $projection.ProfitCenter    = _ProfitCenter.ProfitCenter

  association [0..1] to I_CnsldtnProfitCenterForElim   as _ProfitCenterForElim        on  $projection.ControllingArea             = _ProfitCenterForElim.ControllingArea
                                                                                      and $projection.ConsolidationPrftCtrForElim = _ProfitCenterForElim.ProfitCenter

  association [0..1] to I_CnsldtnFunctionalArea        as _FunctionalArea             on  $projection.FunctionalArea = _FunctionalArea.FunctionalArea

  association [0..1] to I_CnsldtnBusinessArea          as _BusinessArea               on  $projection.BusinessArea = _BusinessArea.BusinessArea

  association [0..1] to I_CnsldtnControllingArea       as _ControllingArea            on  $projection.ControllingArea = _ControllingArea.ControllingArea

  association [0..1] to I_CnsldtnSegment               as _Segment                    on  $projection.Segment = _Segment.Segment

  association [0..1] to I_CnsldtnSegmentForElim        as _SegmentForElim             on  $projection.ConsolidationSegmentForElim = _SegmentForElim.Segment

  association [0..1] to I_CnsldtnCostCenter            as _PartnerCostCenter          on  $projection.ControllingArea   = _PartnerCostCenter.ControllingArea
                                                                                      and $projection.PartnerCostCenter = _PartnerCostCenter.CostCenter

  association [0..1] to I_CnsldtnProfitCenter          as _PartnerProfitCenter        on  $projection.ControllingArea     = _PartnerProfitCenter.ControllingArea
                                                                                      and $projection.PartnerProfitCenter = _PartnerProfitCenter.ProfitCenter

  association [0..1] to I_CnsldtnFunctionalArea        as _PartnerFunctionalArea      on  $projection.PartnerFunctionalArea = _PartnerFunctionalArea.FunctionalArea

  association [0..1] to I_CnsldtnBusinessArea          as _PartnerBusinessArea        on  $projection.PartnerBusinessArea = _PartnerBusinessArea.BusinessArea

  association [1..1] to I_Globalcompany                as _PartnerCompany             on  $projection.PartnerCompany = _PartnerCompany.Company

  association [0..1] to I_CnsldtnSegment               as _PartnerSegment             on  $projection.PartnerSegment = _PartnerSegment.Segment

  association [0..1] to I_CnsldtnBillingType           as _BillingDocumentType        on  $projection.BillingDocumentType = _BillingDocumentType.BillingDocumentType

  association [0..1] to I_CnsldtnSalesOrganization     as _SalesOrganization          on  $projection.SalesOrganization = _SalesOrganization.SalesOrganization

  association [0..1] to I_CnsldtnDistributionChannel   as _DistributionChannel        on  $projection.DistributionChannel = _DistributionChannel.DistributionChannel

  association [0..1] to I_CnsldtnDivision              as _Division                   on  $projection.OrganizationDivision = _Division.Division

  association [0..1] to I_CnsldtnProduct               as _SoldProduct                on  $projection.SoldProduct = _SoldProduct.Product

  association [0..1] to I_CnsldtnMaterialGroup         as _SoldProductGroup           on  $projection.SoldProductGroup = _SoldProductGroup.MaterialGroup

  association [0..1] to I_CnsldtnCustomerGroup         as _CustomerGroup              on  $projection.CustomerGroup = _CustomerGroup.CustomerGroup

  association [0..1] to I_CnsldtnCountry               as _Country                    on  $projection.CustomerSupplierCountry = _Country.Country

  association [0..1] to I_CnsldtnIndustry              as _Industry                   on  $projection.CustomerSupplierIndustry = _Industry.Industry

  association [0..1] to I_CnsldtnSalesDistrict         as _SalesDistrict              on  $projection.SalesDistrict = _SalesDistrict.SalesDistrict

  association [0..1] to I_CnsldtnCustomer              as _BillToParty                on  $projection.BillToParty = _BillToParty.Customer

  association [0..1] to I_CnsldtnCustomer              as _ShipToParty                on  $projection.ShipToParty = _ShipToParty.Customer

  association [0..1] to I_CnsldtnAdhocItem             as _AdhocItem                  on  $projection.ConsolidationChartOfAccounts = _AdhocItem.ConsolidationChartOfAccounts
                                                                                      and $projection.CnsldtnAdhocItem             = _AdhocItem.CnsldtnAdhocItem

  association [0..1] to I_CnsldtnAdhocSet              as _AdhocSet                   on  $projection.ConsolidationChartOfAccounts = _AdhocSet.ConsolidationChartOfAccounts
                                                                                      and $projection.CnsldtnAdhocSet              = _AdhocSet.CnsldtnAdhocSet

  association [0..1] to I_CnsldtnAdhocSetItem          as _AdhocSetItem               on  $projection.ConsolidationChartOfAccounts = _AdhocSetItem.ConsolidationChartOfAccounts
                                                                                      and $projection.CnsldtnAdhocSet              = _AdhocSetItem.CnsldtnAdhocSet
                                                                                      and $projection.CnsldtnAdhocSetItem          = _AdhocSetItem.CnsldtnAdhocSetItem


  association [0..1] to I_FiscalCalendarDate         as _FiscalCalendarDate           on $projection.PostingDate                   = _FiscalCalendarDate.CalendarDate
                                                                                      and $projection.FiscalYearVariant            = _FiscalCalendarDate.FiscalYearVariant

  //Associations for value helps of parameters
  association [0..*] to I_CnsldtnUnitHierDirVH         as _CnsldtnUnitHierDir         on  _CnsldtnUnitHierDir.ConsolidationUnitHierarchy = $parameters.P_ConsolidationUnitHierarchy

  association [0..*] to I_CnsldtnSegmentHierDirVH      as _SegmentHierDir             on  _SegmentHierDir.ConsolidationSegmentHierarchy = $parameters.P_ConsolidationSegmentHier

  association [0..*] to I_CnsldtnProfitCenterHierDirVH as _ProfitCenterHierDir        on  _ProfitCenterHierDir.AdditionalMasterDataHierarchy = $parameters.P_ConsolidationPrftCtrHier
{
      /**************************** ACDOCU Part ************************************************/
      @ObjectModel.foreignKey.association: '_Ledger'
  key ConsolidationLedger,
      @ObjectModel.foreignKey.association: '_Dimension'
  key ConsolidationDimension,

      @Semantics.fiscal.year: true
  key FiscalYear,

  key ConsolidationDocumentNumber,   //Successor should be CnsldtnGroupJrnlEntry

  key ConsolidationPostingItem,

      GLRecordType,

      @ObjectModel.foreignKey.association: '_Version'
      ConsolidationVersion,

      @ObjectModel.foreignKey.association: '_VersionElement'
      ConsolidationVersionElement,

      @Semantics.currencyCode:true
      @ObjectModel.foreignKey.association: '_TransactionCurrency'
      TransactionCurrency,

      @Semantics.currencyCode:true
      @ObjectModel.foreignKey.association: '_LocalCurrency'
      LocalCurrency,

      @Semantics.currencyCode:true
      @ObjectModel.foreignKey.association: '_GroupCurrency'
      GroupCurrency,

      @Semantics.unitOfMeasure: true
      @ObjectModel.foreignKey.association: '_BaseUnit'
      BaseUnit,

      @Semantics.fiscal.period: true
      FiscalPeriod,

      @Semantics.fiscal.yearPeriod: true
      FiscalYearPeriod,

      @Semantics.fiscal.yearVariant: true
      FiscalYearVariant,

      PeriodMode,

      @ObjectModel.foreignKey.association: '_DocumentType'
      ConsolidationDocumentType,

      @ObjectModel.foreignKey.association: '_DebitCreditCode'
      DebitCreditCode,

      @ObjectModel.foreignKey.association: '_Company'
      Company,

      @ObjectModel.foreignKey.association: '_CnsldtnUnit'
      ConsolidationUnit,

      @ObjectModel.foreignKey.association: '_CnsldtnUnitForElimination'
      ConsolidationUnitForElim,

      @ObjectModel.foreignKey.association: '_ChartOfAccounts'
      ConsolidationChartOfAccounts,

      @ObjectModel.foreignKey.association: '_FinStmntItm'
      FinancialStatementItem,

      @ObjectModel.foreignKey.association: '_PartnerUnit'
      PartnerConsolidationUnit,

      @ObjectModel.foreignKey.association: '_CnsldtnGroup'
      ConsolidationGroup,

      @ObjectModel.foreignKey.association: '_CompanyCode'
      CompanyCode,

      @ObjectModel.foreignKey.association: '_SubItemCategory'
      SubItemCategory,

      @ObjectModel.foreignKey.association: '_SubItem'
      SubItem,

      @ObjectModel.foreignKey.association: '_PostingLevel'
      PostingLevel,

      @ObjectModel.foreignKey.association: '_Apportionment'
      ConsolidationApportionment,

      @ObjectModel.foreignKey.association: '_CrcyCnvrsnDiffType'
      CurrencyConversionsDiffType,

      @Semantics.fiscal.year: true
      ConsolidationAcquisitionYear,

      @Semantics.fiscal.period: true
      ConsolidationAcquisitionPeriod,

      @ObjectModel.foreignKey.association: '_InvesteeUnit'
      InvesteeConsolidationUnit,

      @DefaultAggregation: #SUM
      @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
      AmountInTransactionCurrency,

      @DefaultAggregation: #SUM
      @Semantics: { amount : {currencyCode: 'LocalCurrency'} }
      AmountInLocalCurrency,

      @DefaultAggregation: #SUM
      @Semantics: { amount : {currencyCode: 'GroupCurrency'} }
      AmountInGroupCurrency,

      // Release CE 2008 Deprecation of QuantityInBaseUnit
      @DefaultAggregation: #SUM
      @Semantics: { quantity : {unitOfMeasure : 'BaseUnit'} }
      @API.element.releaseState:    #DEPRECATED
      @API.element.successor: 'CnsldtnQuantityInBaseUnit'
      QuantityInBaseUnit,

      @DefaultAggregation: #SUM
      @Semantics: { quantity : {unitOfMeasure : 'BaseUnit'} }
      CnsldtnQuantityInBaseUnit,

      DocumentItemText,

      ConsolidationPostgItemAutoFlag,

      BusinessTransactionType,

      PostingDate,
      CurrencyTranslationDate,
      RefConsolidationDocumentNumber,

      @Semantics.fiscal.year: true
      ReferenceFiscalYear,

      RefConsolidationPostingItem,
      RefConsolidationDocumentType,
      RefBusinessTransactionType,
      CreationDate,
      CreationTime,
      UserID,
      ReverseDocument,
      ReversedDocument,
      InvestmentActivityType,
      InvestmentActivity,
      ConsolidationDocReversalYear,
      ReferenceDocumentType,
      ReferenceDocumentContext,
      LogicalSystem,

      /*** Begin Of Additional Fields in Consolidation Journal Entries in S/4 ***/
      @ObjectModel.foreignKey.association: '_GLChartOfAccounts'
      ChartOfAccounts,

      @ObjectModel.foreignKey.association: '_GLAccountInChartOfAccounts'
      GLAccount,

      //  ReferenceDocumentNumber,

      AssignmentReference,

      @ObjectModel.foreignKey.association: '_CostCenter'
      CostCenter,

      @ObjectModel.foreignKey.association: '_ProfitCenter'
      ProfitCenter,

      @ObjectModel.foreignKey.association: '_ProfitCenterForElim'
      ConsolidationPrftCtrForElim,

      @ObjectModel.foreignKey.association: '_FunctionalArea'
      FunctionalArea,

      @ObjectModel.foreignKey.association: '_BusinessArea'
      BusinessArea,

      @ObjectModel.foreignKey.association: '_ControllingArea'
      ControllingArea,

      @ObjectModel.foreignKey.association: '_Segment'
      Segment,

      @ObjectModel.foreignKey.association: '_SegmentForElim'
      ConsolidationSegmentForElim,

      @ObjectModel.foreignKey.association: '_PartnerCostCenter'
      PartnerCostCenter,

      @ObjectModel.foreignKey.association: '_PartnerProfitCenter'
      PartnerProfitCenter,

      @ObjectModel.foreignKey.association: '_PartnerFunctionalArea'
      PartnerFunctionalArea,

      @ObjectModel.foreignKey.association: '_PartnerBusinessArea'
      PartnerBusinessArea,

      @ObjectModel.foreignKey.association: '_PartnerCompany'
      PartnerCompany,

      @ObjectModel.foreignKey.association: '_PartnerSegment'
      PartnerSegment,

      @ObjectModel.foreignKey.association: '_InternalOrder'
      OrderID,

      @ObjectModel.foreignKey.association: '_Customer'
      Customer,

      @ObjectModel.foreignKey.association: '_Supplier'
      Supplier,

      @ObjectModel.foreignKey.association: '_Material'
      Material, //do not use any longer, use Product

      @ObjectModel.foreignKey.association: '_Plant'
      Plant,

      @ObjectModel.foreignKey.association: '_FinancialTransactionType'
      FinancialTransactionType,

      @ObjectModel.foreignKey.association: '_WBSElementInternalID'
      WBSElementInternalID,

      @ObjectModel.foreignKey.association: '_WBSElement'
      WBSElementExternalID,

      @ObjectModel.foreignKey.association: '_Project'
      Project,
      /*** End Of Additional Fields in Consolidation Journal Entries in S/4 ***/


      /*** 1802CE: Begin Of Additional Fields in Consolidation Journal Entries in S/4 ***/
      @ObjectModel.foreignKey.association: '_BillingDocumentType'
      BillingDocumentType,

      @ObjectModel.foreignKey.association: '_SalesOrganization'
      SalesOrganization,

      @ObjectModel.foreignKey.association: '_DistributionChannel'
      DistributionChannel,

      @ObjectModel.foreignKey.association: '_Division'
      OrganizationDivision,

      @ObjectModel.foreignKey.association: '_MaterialGroup'
      MaterialGroup,

      @ObjectModel.foreignKey.association: '_SoldProduct'
      SoldProduct,

      @ObjectModel.foreignKey.association: '_SoldProductGroup'
      SoldProductGroup,

      @ObjectModel.foreignKey.association: '_CustomerGroup'
      CustomerGroup,

      @ObjectModel.foreignKey.association: '_Country'
      CustomerSupplierCountry,

      @ObjectModel.foreignKey.association: '_Industry'
      CustomerSupplierIndustry,

      @ObjectModel.foreignKey.association: '_SalesDistrict'
      SalesDistrict,

      @ObjectModel.foreignKey.association: '_BillToParty'
      BillToParty,

      @ObjectModel.foreignKey.association: '_ShipToParty'
      ShipToParty,

      CustomerSupplierCorporateGroup,

      //Additional Fileds: Adhoc Item
      @ObjectModel.foreignKey.association: '_AdhocItem'
      CnsldtnAdhocItem,

      @ObjectModel.foreignKey.association: '_AdhocSet'
      CnsldtnAdhocSet,

      @ObjectModel.foreignKey.association: '_AdhocSetItem'
      CnsldtnAdhocSetItem,

      //Additional Fields - ICMR
      MatchingReasonCode,
      OriginType,
      OriginReference,

      CnsldtnGroupJrnlEntryBundle,

      //Elements for value helps of parameters
      @Consumption.hidden: true
      :P_ConsolidationUnitHierarchy as ConsolidationUnitHierarchy,

      @Consumption.hidden: true
      :P_ConsolidationSegmentHier   as ConsolidationSegmentHierarchy,

      @Consumption.hidden: true
      :P_ConsolidationPrftCtrHier   as ConsolidationPrftCtrHierarchy,

      @Consumption.hidden: true
      :P_KeyDate                    as KeyDate,


      // Associations------------------------------------------------------------------------------
      _Ledger,

      _Dimension,

      _Version,

      _VersionElement,

      _Company,

      @API.element.releaseState: #DEPRECATED
      @API.element.successor: '_CnsldtnUnit_3'
      _CnsldtnUnit,
      _CnsldtnUnit_3,

      _CnsldtnUnitForElimination,

      _CnsldtnGroup,

      _ChartOfAccounts,

      _FinStmntItm,

      _GLAccountInChartOfAccounts,

      _GLChartOfAccounts,

      @API.element.releaseState: #DEPRECATED
      @API.element.successor: '_PartnerUnit_3'
      _PartnerUnit,
      _PartnerUnit_3,

      _CompanyCode,

      _SubItemCategory,

      _SubItem,

      _DebitCreditCode,

      _DocumentType,

      _PostingLevel,

      @API.element.releaseState: #DEPRECATED
      @API.element.successor: '_InvesteeUnit_3'
      _InvesteeUnit,
      _InvesteeUnit_3,

      _Apportionment,

      _CrcyCnvrsnDiffType,

      _TransactionCurrency,

      _LocalCurrency,

      _GroupCurrency,

      _BaseUnit,

      _InternalOrder,

      _Customer,

      _Supplier,

      _Material,

      _MaterialGroup,

      _Plant,

      _FinancialTransactionType,

      _WBSElement,

      _WBSElementInternalID,

      _Project,

      _CostCenter,

      _ProfitCenter,

      //  Profit Center Eliminated
      _ProfitCenterForElim,

      _FunctionalArea,

      _BusinessArea,

      _ControllingArea,

      _Segment,

      //  Segment Eliminated
      _SegmentForElim,

      _PartnerCostCenter,

      _PartnerProfitCenter,

      _PartnerFunctionalArea,

      _PartnerBusinessArea,

      _PartnerCompany,

      _PartnerSegment,

      _BillingDocumentType,

      _SalesOrganization,

      _DistributionChannel,

      _Division,

      _SoldProduct,

      _SoldProductGroup,

      _CustomerGroup,

      _Country,

      _Industry,

      _SalesDistrict,

      _BillToParty,

      _ShipToParty,

      _AdhocItem,

      _AdhocSet,

      _AdhocSetItem,

      //Associations for value helps of parameters
      @ObjectModel.association.boundFields.dataMatchesSourceAndTargetTypes:true
      _CnsldtnUnitHierDir,

      _SegmentHierDir,

      _ProfitCenterHierDir
}
