//----------------------------------------------------------------------
// Object    : ZI_GR_FSREMAP_CUBE (DDL source, classic view, cube)
// Title     : Group Data Analysis cube with FS item remap per cons unit
// Project   : OVL                                  Module: FI-CS (Group Reporting)
// Related FS: chat request 06/11/2026, no FSD - see ASSUMPTIONS_AND_QUERIES.md
// Author    : Arnav Johri                          Date: 06.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   Customer cube on the standard Group Data Analysis cube
//   I_MatrixConsolidationReportC (source as supplied from OCD 500 on
//   06/11/26, filed in original/). Every element, parameter and
//   association of the standard cube is carried unchanged, plus one
//   new column:
//     NewFinancialStatementItem = ZGR_FSITEM_MAP-RITEM_NEW for the row's
//       ConsolidationUnit + FinancialStatementItem when a mapping row
//       with a non-empty new item exists, else FinancialStatementItem.
//   The original FinancialStatementItem stays as it is. _NewFinStmntItm
//   gives the new column its texts and hierarchies (same cons chart of
//   accounts). Object 3 of 3; needs ZGR_FSITEM_MAP active.
//
// ASSUMPTION: built on the deprecated I_MatrixConsolidationReportC as
//   supplied, not on its successor I_MATRIXCNSLDTNREPORTC_2, whose
//   parameter list is not confirmed on this system (query 7).
// ASSUMPTION: @Analytics.readClassName 'CL_FINCS_GRA_CUBE_REL' of the
//   standard cube is NOT carried - this view is read by SQL. Totals are
//   to be compared with the Group Data Analysis app before use (query 9).
// ASSUMPTION: #NOT_REQUIRED access control, as on every other Z cube on
//   OVL; the standard cube is #CHECK with a DCL (query 10).
// ASSUMPTION: a mapping row whose RITEM_NEW is empty is treated as no
//   mapping - the original FS item is shown (query 11).
// Not carried from the standard: _Extension (extension hook of SAP's
//   cube) and _FiscalCalendarDate (defined but not exposed there).
// Release constraints (MEMORY section 4): classic define view with SQL
//   view name, no view entity, no year()/month(), no INT->NUMC cast.
//
// CHANGE HISTORY
//   06.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIGRFSREMAPCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.buffering.status: #NOT_ALLOWED
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType.sizeCategory: #XL
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MIXED
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_PROVIDER,
                                      #SQL_DATA_SOURCE,
                                      #CDS_MODELING_DATA_SOURCE ]
@ObjectModel.modelingPattern: #ANALYTICAL_CUBE
@Analytics.dataCategory: #CUBE
@VDM.viewType: #COMPOSITE
@EndUserText.label: 'Group Data Analysis - Cube with FS item remap'

define view ZI_GR_FSREMAP_CUBE
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

  as select from I_MatrixConsolidationReportC(
                   P_ConsolidationUnitHierarchy: $parameters.P_ConsolidationUnitHierarchy,
                   P_ConsolidationPrftCtrHier:   $parameters.P_ConsolidationPrftCtrHier,
                   P_ConsolidationSegmentHier:   $parameters.P_ConsolidationSegmentHier,
                   P_KeyDate:                    $parameters.P_KeyDate ) as JrnlEntry

    // FS item remap maintained in SM30 (ZGR_FSITEM_MAP); client handled
    // by the session variable, so MANDT is not written here
    left outer join zgr_fsitem_map as FSItemMap
      on  FSItemMap.rbunit = JrnlEntry.ConsolidationUnit
      and FSItemMap.ritem  = JrnlEntry.FinancialStatementItem

  association [1..1] to I_CnsldtnLedger                as _Ledger
    on $projection.ConsolidationLedger = _Ledger.ConsolidationLedger

  association [1..1] to I_CnsldtnDimension             as _Dimension
    on $projection.ConsolidationDimension = _Dimension.ConsolidationDimension

  association [1..1] to I_CnsldtnVersion               as _Version
    on $projection.ConsolidationVersion = _Version.ConsolidationVersion

  association [1..1] to I_CnsldtnVersion               as _VersionElement
    on $projection.ConsolidationVersionElement = _VersionElement.ConsolidationVersion

  association [1..1] to I_Globalcompany                as _Company
    on $projection.Company = _Company.Company

  association [0..1] to I_DebitCreditCode              as _DebitCreditCode
    on $projection.DebitCreditCode = _DebitCreditCode.DebitCreditCode

  // Deprecated in the standard cube, kept for compatibility with it
  association [1..1] to I_CnsldtnUnit_2                as _CnsldtnUnit
    on  $projection.ConsolidationDimension = _CnsldtnUnit.ConsolidationDimension
    and $projection.ConsolidationUnit      = _CnsldtnUnit.ConsolidationUnit

  association [1..1] to I_CnsldtnUnit_3                as _CnsldtnUnit_3
    on $projection.ConsolidationUnit = _CnsldtnUnit_3.ConsolidationUnit

  association [1..1] to I_CnsldtnUnitForElimination    as _CnsldtnUnitForElimination
    on  $projection.ConsolidationDimension   = _CnsldtnUnitForElimination.ConsolidationDimension
    and $projection.ConsolidationUnitForElim = _CnsldtnUnitForElimination.ConsolidationUnit

  association [1..1] to I_CnsldtnGroupWithEmptyValue   as _CnsldtnGroup
    on  $projection.ConsolidationDimension = _CnsldtnGroup.ConsolidationDimension
    and $projection.ConsolidationGroup     = _CnsldtnGroup.ConsolidationGroup

  association [1..1] to I_CnsldtnChartOfAccounts       as _ChartOfAccounts
    on $projection.ConsolidationChartOfAccounts = _ChartOfAccounts.ConsolidationChartOfAccounts

  association [1..1] to I_GroupReportingFSItem         as _FinStmntItm
    on  $projection.ConsolidationChartOfAccounts = _FinStmntItm.ConsolidationChartOfAccounts
    and $projection.FinancialStatementItem       = _FinStmntItm.FinancialStatementItem

  //BOC By Arnav on 06/11/26 - master data of the remapped FS item
  // [0..1]: the new item may not exist (yet) in the cons chart of accounts
  association [0..1] to I_GroupReportingFSItem         as _NewFinStmntItm
    on  $projection.ConsolidationChartOfAccounts = _NewFinStmntItm.ConsolidationChartOfAccounts
    and $projection.NewFinancialStatementItem    = _NewFinStmntItm.FinancialStatementItem
  //EOC By Arnav on 06/11/26 - master data of the remapped FS item

  // Deprecated in the standard cube, kept for compatibility with it
  association [0..1] to I_CnsldtnUnit_2                as _PartnerUnit
    on  $projection.ConsolidationDimension   = _PartnerUnit.ConsolidationDimension
    and $projection.PartnerConsolidationUnit = _PartnerUnit.ConsolidationUnit

  association [0..1] to I_CnsldtnUnit_3                as _PartnerUnit_3
    on $projection.PartnerConsolidationUnit = _PartnerUnit_3.ConsolidationUnit

  association [0..1] to I_CompanyCode                  as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode

  association [0..1] to I_CnsldtnGLAccount             as _GLAccountInChartOfAccounts
    on  $projection.ChartOfAccounts = _GLAccountInChartOfAccounts.ChartOfAccounts
    and $projection.GLAccount       = _GLAccountInChartOfAccounts.GLAccount

  association [0..1] to I_CnsldtnGLChartOfAccounts     as _GLChartOfAccounts
    on $projection.ChartOfAccounts = _GLChartOfAccounts.ChartOfAccounts

  association [0..1] to I_CnsldtnSubItemCategory       as _SubItemCategory
    on $projection.SubItemCategory = _SubItemCategory.SubItemCategory

  association [0..1] to I_CnsldtnSubItem               as _SubItem
    on  $projection.SubItemCategory = _SubItem.SubItemCategory
    and $projection.SubItem         = _SubItem.SubItem

  association [1..1] to I_CnsldtnDocumentType          as _DocumentType
    on  $projection.ConsolidationDimension    = _DocumentType.ConsolidationDimension
    and $projection.ConsolidationDocumentType = _DocumentType.ConsolidationDocumentType

  association [1..1] to I_CnsldtnPostingLevel          as _PostingLevel
    on $projection.PostingLevel = _PostingLevel.PostingLevel

  // Deprecated in the standard cube, kept for compatibility with it
  association [0..1] to I_CnsldtnUnit_2                as _InvesteeUnit
    on  $projection.ConsolidationDimension    = _InvesteeUnit.ConsolidationDimension
    and $projection.InvesteeConsolidationUnit = _InvesteeUnit.ConsolidationUnit

  association [0..1] to I_CnsldtnUnit_3                as _InvesteeUnit_3
    on $projection.InvesteeConsolidationUnit = _InvesteeUnit_3.ConsolidationUnit

  association [1..1] to I_CnsldtnApportionment         as _Apportionment
    on $projection.ConsolidationApportionment = _Apportionment.ConsolidationApportionment

  association [1..1] to I_CnsldtnCrcyCnvrsnDiffType    as _CrcyCnvrsnDiffType
    on $projection.CurrencyConversionsDiffType = _CrcyCnvrsnDiffType.CurrencyConversionsDiffType

  association [0..1] to I_Currency                     as _TransactionCurrency
    on $projection.TransactionCurrency = _TransactionCurrency.Currency

  association [0..1] to I_Currency                     as _LocalCurrency
    on $projection.LocalCurrency = _LocalCurrency.Currency

  association [0..1] to I_Currency                     as _GroupCurrency
    on $projection.GroupCurrency = _GroupCurrency.Currency

  association [0..1] to I_UnitOfMeasure                as _BaseUnit
    on $projection.BaseUnit = _BaseUnit.UnitOfMeasure

  association [0..1] to I_CnsldtnInternalOrder         as _InternalOrder
    on $projection.OrderID = _InternalOrder.InternalOrder

  association [0..1] to I_CnsldtnCustomer              as _Customer
    on $projection.Customer = _Customer.Customer

  association [0..1] to I_CnsldtnSupplier              as _Supplier
    on $projection.Supplier = _Supplier.Supplier

  association [0..1] to I_CnsldtnMaterial              as _Material
    on $projection.Material = _Material.Material

  association [0..1] to I_CnsldtnMaterialGroup         as _MaterialGroup
    on $projection.MaterialGroup = _MaterialGroup.MaterialGroup

  association [0..1] to I_CnsldtnPlant                 as _Plant
    on $projection.Plant = _Plant.Plant

  association [0..1] to I_CnsldtnFinTransType          as _FinancialTransactionType
    on $projection.FinancialTransactionType = _FinancialTransactionType.FinancialTransactionType

  association [0..1] to I_CnsldtnWBSElement            as _WBSElement
    on  $projection.Project              = _WBSElement.Project
    and $projection.WBSElementExternalID = _WBSElement.WBSElement

  association [0..1] to I_WBSElementBasicData          as _WBSElementInternalID
    on $projection.WBSElementInternalID = _WBSElementInternalID.WBSElementInternalID

  association [0..1] to I_CnsldtnProject               as _Project
    on $projection.Project = _Project.Project

  association [0..1] to I_CnsldtnCostCenter            as _CostCenter
    on  $projection.ControllingArea = _CostCenter.ControllingArea
    and $projection.CostCenter      = _CostCenter.CostCenter

  association [0..1] to I_CnsldtnProfitCenter          as _ProfitCenter
    on  $projection.ControllingArea = _ProfitCenter.ControllingArea
    and $projection.ProfitCenter    = _ProfitCenter.ProfitCenter

  association [0..1] to I_CnsldtnProfitCenterForElim   as _ProfitCenterForElim
    on  $projection.ControllingArea             = _ProfitCenterForElim.ControllingArea
    and $projection.ConsolidationPrftCtrForElim = _ProfitCenterForElim.ProfitCenter

  association [0..1] to I_CnsldtnFunctionalArea        as _FunctionalArea
    on $projection.FunctionalArea = _FunctionalArea.FunctionalArea

  association [0..1] to I_CnsldtnBusinessArea          as _BusinessArea
    on $projection.BusinessArea = _BusinessArea.BusinessArea

  association [0..1] to I_CnsldtnControllingArea       as _ControllingArea
    on $projection.ControllingArea = _ControllingArea.ControllingArea

  association [0..1] to I_CnsldtnSegment               as _Segment
    on $projection.Segment = _Segment.Segment

  association [0..1] to I_CnsldtnSegmentForElim        as _SegmentForElim
    on $projection.ConsolidationSegmentForElim = _SegmentForElim.Segment

  association [0..1] to I_CnsldtnCostCenter            as _PartnerCostCenter
    on  $projection.ControllingArea   = _PartnerCostCenter.ControllingArea
    and $projection.PartnerCostCenter = _PartnerCostCenter.CostCenter

  association [0..1] to I_CnsldtnProfitCenter          as _PartnerProfitCenter
    on  $projection.ControllingArea     = _PartnerProfitCenter.ControllingArea
    and $projection.PartnerProfitCenter = _PartnerProfitCenter.ProfitCenter

  association [0..1] to I_CnsldtnFunctionalArea        as _PartnerFunctionalArea
    on $projection.PartnerFunctionalArea = _PartnerFunctionalArea.FunctionalArea

  association [0..1] to I_CnsldtnBusinessArea          as _PartnerBusinessArea
    on $projection.PartnerBusinessArea = _PartnerBusinessArea.BusinessArea

  association [1..1] to I_Globalcompany                as _PartnerCompany
    on $projection.PartnerCompany = _PartnerCompany.Company

  association [0..1] to I_CnsldtnSegment               as _PartnerSegment
    on $projection.PartnerSegment = _PartnerSegment.Segment

  association [0..1] to I_CnsldtnBillingType           as _BillingDocumentType
    on $projection.BillingDocumentType = _BillingDocumentType.BillingDocumentType

  association [0..1] to I_CnsldtnSalesOrganization     as _SalesOrganization
    on $projection.SalesOrganization = _SalesOrganization.SalesOrganization

  association [0..1] to I_CnsldtnDistributionChannel   as _DistributionChannel
    on $projection.DistributionChannel = _DistributionChannel.DistributionChannel

  association [0..1] to I_CnsldtnDivision              as _Division
    on $projection.OrganizationDivision = _Division.Division

  association [0..1] to I_CnsldtnProduct               as _SoldProduct
    on $projection.SoldProduct = _SoldProduct.Product

  association [0..1] to I_CnsldtnMaterialGroup         as _SoldProductGroup
    on $projection.SoldProductGroup = _SoldProductGroup.MaterialGroup

  association [0..1] to I_CnsldtnCustomerGroup         as _CustomerGroup
    on $projection.CustomerGroup = _CustomerGroup.CustomerGroup

  association [0..1] to I_CnsldtnCountry               as _Country
    on $projection.CustomerSupplierCountry = _Country.Country

  association [0..1] to I_CnsldtnIndustry              as _Industry
    on $projection.CustomerSupplierIndustry = _Industry.Industry

  association [0..1] to I_CnsldtnSalesDistrict         as _SalesDistrict
    on $projection.SalesDistrict = _SalesDistrict.SalesDistrict

  association [0..1] to I_CnsldtnCustomer              as _BillToParty
    on $projection.BillToParty = _BillToParty.Customer

  association [0..1] to I_CnsldtnCustomer              as _ShipToParty
    on $projection.ShipToParty = _ShipToParty.Customer

  association [0..1] to I_CnsldtnAdhocItem             as _AdhocItem
    on  $projection.ConsolidationChartOfAccounts = _AdhocItem.ConsolidationChartOfAccounts
    and $projection.CnsldtnAdhocItem             = _AdhocItem.CnsldtnAdhocItem

  association [0..1] to I_CnsldtnAdhocSet              as _AdhocSet
    on  $projection.ConsolidationChartOfAccounts = _AdhocSet.ConsolidationChartOfAccounts
    and $projection.CnsldtnAdhocSet              = _AdhocSet.CnsldtnAdhocSet

  association [0..1] to I_CnsldtnAdhocSetItem          as _AdhocSetItem
    on  $projection.ConsolidationChartOfAccounts = _AdhocSetItem.ConsolidationChartOfAccounts
    and $projection.CnsldtnAdhocSet              = _AdhocSetItem.CnsldtnAdhocSet
    and $projection.CnsldtnAdhocSetItem          = _AdhocSetItem.CnsldtnAdhocSetItem

  // Associations for the value helps of the parameters
  association [0..*] to I_CnsldtnUnitHierDirVH         as _CnsldtnUnitHierDir
    on _CnsldtnUnitHierDir.ConsolidationUnitHierarchy = $parameters.P_ConsolidationUnitHierarchy

  association [0..*] to I_CnsldtnSegmentHierDirVH      as _SegmentHierDir
    on _SegmentHierDir.ConsolidationSegmentHierarchy = $parameters.P_ConsolidationSegmentHier

  association [0..*] to I_CnsldtnProfitCenterHierDirVH as _ProfitCenterHierDir
    on _ProfitCenterHierDir.AdditionalMasterDataHierarchy = $parameters.P_ConsolidationPrftCtrHier
{
      /**************************** ACDOCU Part ********************************/
      @ObjectModel.foreignKey.association: '_Ledger'
  key JrnlEntry.ConsolidationLedger,
      @ObjectModel.foreignKey.association: '_Dimension'
  key JrnlEntry.ConsolidationDimension,

      @Semantics.fiscal.year: true
  key JrnlEntry.FiscalYear,

  key JrnlEntry.ConsolidationDocumentNumber,

  key JrnlEntry.ConsolidationPostingItem,

      JrnlEntry.GLRecordType,

      @ObjectModel.foreignKey.association: '_Version'
      JrnlEntry.ConsolidationVersion,

      @ObjectModel.foreignKey.association: '_VersionElement'
      JrnlEntry.ConsolidationVersionElement,

      @Semantics.currencyCode: true
      @ObjectModel.foreignKey.association: '_TransactionCurrency'
      JrnlEntry.TransactionCurrency,

      @Semantics.currencyCode: true
      @ObjectModel.foreignKey.association: '_LocalCurrency'
      JrnlEntry.LocalCurrency,

      @Semantics.currencyCode: true
      @ObjectModel.foreignKey.association: '_GroupCurrency'
      JrnlEntry.GroupCurrency,

      @Semantics.unitOfMeasure: true
      @ObjectModel.foreignKey.association: '_BaseUnit'
      JrnlEntry.BaseUnit,

      @Semantics.fiscal.period: true
      JrnlEntry.FiscalPeriod,

      @Semantics.fiscal.yearPeriod: true
      JrnlEntry.FiscalYearPeriod,

      @Semantics.fiscal.yearVariant: true
      JrnlEntry.FiscalYearVariant,

      JrnlEntry.PeriodMode,

      @ObjectModel.foreignKey.association: '_DocumentType'
      JrnlEntry.ConsolidationDocumentType,

      @ObjectModel.foreignKey.association: '_DebitCreditCode'
      JrnlEntry.DebitCreditCode,

      @ObjectModel.foreignKey.association: '_Company'
      JrnlEntry.Company,

      @ObjectModel.foreignKey.association: '_CnsldtnUnit'
      JrnlEntry.ConsolidationUnit,

      @ObjectModel.foreignKey.association: '_CnsldtnUnitForElimination'
      JrnlEntry.ConsolidationUnitForElim,

      @ObjectModel.foreignKey.association: '_ChartOfAccounts'
      JrnlEntry.ConsolidationChartOfAccounts,

      @ObjectModel.foreignKey.association: '_FinStmntItm'
      JrnlEntry.FinancialStatementItem,

      //BOC By Arnav on 06/11/26 - remapped FS item
      // Mapped item when ZGR_FSITEM_MAP has a row for this cons unit + FS
      // item with a filled new item; otherwise the original FS item. The
      // IS NOT NULL test comes first: after a left outer join miss the
      // column is NULL, and NULL <> '' would not be true either way.
      @EndUserText.label: 'New FS Item'
      @EndUserText.quickInfo: 'FS item after remap per consolidation unit (ZGR_FSITEM_MAP)'
      @ObjectModel.foreignKey.association: '_NewFinStmntItm'
      case
        when FSItemMap.ritem_new is not null
         and FSItemMap.ritem_new <> ''
        then FSItemMap.ritem_new
        else JrnlEntry.FinancialStatementItem
      end                                   as NewFinancialStatementItem,
      //EOC By Arnav on 06/11/26 - remapped FS item

      @ObjectModel.foreignKey.association: '_PartnerUnit'
      JrnlEntry.PartnerConsolidationUnit,

      @ObjectModel.foreignKey.association: '_CnsldtnGroup'
      JrnlEntry.ConsolidationGroup,

      @ObjectModel.foreignKey.association: '_CompanyCode'
      JrnlEntry.CompanyCode,

      @ObjectModel.foreignKey.association: '_SubItemCategory'
      JrnlEntry.SubItemCategory,

      @ObjectModel.foreignKey.association: '_SubItem'
      JrnlEntry.SubItem,

      @ObjectModel.foreignKey.association: '_PostingLevel'
      JrnlEntry.PostingLevel,

      @ObjectModel.foreignKey.association: '_Apportionment'
      JrnlEntry.ConsolidationApportionment,

      @ObjectModel.foreignKey.association: '_CrcyCnvrsnDiffType'
      JrnlEntry.CurrencyConversionsDiffType,

      @Semantics.fiscal.year: true
      JrnlEntry.ConsolidationAcquisitionYear,

      @Semantics.fiscal.period: true
      JrnlEntry.ConsolidationAcquisitionPeriod,

      @ObjectModel.foreignKey.association: '_InvesteeUnit'
      JrnlEntry.InvesteeConsolidationUnit,

      @DefaultAggregation: #SUM
      @Semantics: { amount : {currencyCode: 'TransactionCurrency'} }
      JrnlEntry.AmountInTransactionCurrency,

      @DefaultAggregation: #SUM
      @Semantics: { amount : {currencyCode: 'LocalCurrency'} }
      JrnlEntry.AmountInLocalCurrency,

      @DefaultAggregation: #SUM
      @Semantics: { amount : {currencyCode: 'GroupCurrency'} }
      JrnlEntry.AmountInGroupCurrency,

      // Deprecated in the standard cube (CE 2008), kept for compatibility
      @DefaultAggregation: #SUM
      @Semantics: { quantity : {unitOfMeasure : 'BaseUnit'} }
      @API.element.releaseState: #DEPRECATED
      @API.element.successor: 'CnsldtnQuantityInBaseUnit'
      JrnlEntry.QuantityInBaseUnit,

      @DefaultAggregation: #SUM
      @Semantics: { quantity : {unitOfMeasure : 'BaseUnit'} }
      JrnlEntry.CnsldtnQuantityInBaseUnit,

      JrnlEntry.DocumentItemText,

      JrnlEntry.ConsolidationPostgItemAutoFlag,

      JrnlEntry.BusinessTransactionType,

      JrnlEntry.PostingDate,
      JrnlEntry.CurrencyTranslationDate,
      JrnlEntry.RefConsolidationDocumentNumber,

      @Semantics.fiscal.year: true
      JrnlEntry.ReferenceFiscalYear,

      JrnlEntry.RefConsolidationPostingItem,
      JrnlEntry.RefConsolidationDocumentType,
      JrnlEntry.RefBusinessTransactionType,
      JrnlEntry.CreationDate,
      JrnlEntry.CreationTime,
      JrnlEntry.UserID,
      JrnlEntry.ReverseDocument,
      JrnlEntry.ReversedDocument,
      JrnlEntry.InvestmentActivityType,
      JrnlEntry.InvestmentActivity,
      JrnlEntry.ConsolidationDocReversalYear,
      JrnlEntry.ReferenceDocumentType,
      JrnlEntry.ReferenceDocumentContext,
      JrnlEntry.LogicalSystem,

      /*** Additional Fields in Consolidation Journal Entries in S/4 ***/
      @ObjectModel.foreignKey.association: '_GLChartOfAccounts'
      JrnlEntry.ChartOfAccounts,

      @ObjectModel.foreignKey.association: '_GLAccountInChartOfAccounts'
      JrnlEntry.GLAccount,

      JrnlEntry.AssignmentReference,

      @ObjectModel.foreignKey.association: '_CostCenter'
      JrnlEntry.CostCenter,

      @ObjectModel.foreignKey.association: '_ProfitCenter'
      JrnlEntry.ProfitCenter,

      @ObjectModel.foreignKey.association: '_ProfitCenterForElim'
      JrnlEntry.ConsolidationPrftCtrForElim,

      @ObjectModel.foreignKey.association: '_FunctionalArea'
      JrnlEntry.FunctionalArea,

      @ObjectModel.foreignKey.association: '_BusinessArea'
      JrnlEntry.BusinessArea,

      @ObjectModel.foreignKey.association: '_ControllingArea'
      JrnlEntry.ControllingArea,

      @ObjectModel.foreignKey.association: '_Segment'
      JrnlEntry.Segment,

      @ObjectModel.foreignKey.association: '_SegmentForElim'
      JrnlEntry.ConsolidationSegmentForElim,

      @ObjectModel.foreignKey.association: '_PartnerCostCenter'
      JrnlEntry.PartnerCostCenter,

      @ObjectModel.foreignKey.association: '_PartnerProfitCenter'
      JrnlEntry.PartnerProfitCenter,

      @ObjectModel.foreignKey.association: '_PartnerFunctionalArea'
      JrnlEntry.PartnerFunctionalArea,

      @ObjectModel.foreignKey.association: '_PartnerBusinessArea'
      JrnlEntry.PartnerBusinessArea,

      @ObjectModel.foreignKey.association: '_PartnerCompany'
      JrnlEntry.PartnerCompany,

      @ObjectModel.foreignKey.association: '_PartnerSegment'
      JrnlEntry.PartnerSegment,

      @ObjectModel.foreignKey.association: '_InternalOrder'
      JrnlEntry.OrderID,

      @ObjectModel.foreignKey.association: '_Customer'
      JrnlEntry.Customer,

      @ObjectModel.foreignKey.association: '_Supplier'
      JrnlEntry.Supplier,

      // Standard note: do not use any longer, use Product
      @ObjectModel.foreignKey.association: '_Material'
      JrnlEntry.Material,

      @ObjectModel.foreignKey.association: '_Plant'
      JrnlEntry.Plant,

      @ObjectModel.foreignKey.association: '_FinancialTransactionType'
      JrnlEntry.FinancialTransactionType,

      @ObjectModel.foreignKey.association: '_WBSElementInternalID'
      JrnlEntry.WBSElementInternalID,

      @ObjectModel.foreignKey.association: '_WBSElement'
      JrnlEntry.WBSElementExternalID,

      @ObjectModel.foreignKey.association: '_Project'
      JrnlEntry.Project,

      /*** 1802CE: Additional Fields in Consolidation Journal Entries in S/4 ***/
      @ObjectModel.foreignKey.association: '_BillingDocumentType'
      JrnlEntry.BillingDocumentType,

      @ObjectModel.foreignKey.association: '_SalesOrganization'
      JrnlEntry.SalesOrganization,

      @ObjectModel.foreignKey.association: '_DistributionChannel'
      JrnlEntry.DistributionChannel,

      @ObjectModel.foreignKey.association: '_Division'
      JrnlEntry.OrganizationDivision,

      @ObjectModel.foreignKey.association: '_MaterialGroup'
      JrnlEntry.MaterialGroup,

      @ObjectModel.foreignKey.association: '_SoldProduct'
      JrnlEntry.SoldProduct,

      @ObjectModel.foreignKey.association: '_SoldProductGroup'
      JrnlEntry.SoldProductGroup,

      @ObjectModel.foreignKey.association: '_CustomerGroup'
      JrnlEntry.CustomerGroup,

      @ObjectModel.foreignKey.association: '_Country'
      JrnlEntry.CustomerSupplierCountry,

      @ObjectModel.foreignKey.association: '_Industry'
      JrnlEntry.CustomerSupplierIndustry,

      @ObjectModel.foreignKey.association: '_SalesDistrict'
      JrnlEntry.SalesDistrict,

      @ObjectModel.foreignKey.association: '_BillToParty'
      JrnlEntry.BillToParty,

      @ObjectModel.foreignKey.association: '_ShipToParty'
      JrnlEntry.ShipToParty,

      JrnlEntry.CustomerSupplierCorporateGroup,

      // Adhoc item
      @ObjectModel.foreignKey.association: '_AdhocItem'
      JrnlEntry.CnsldtnAdhocItem,

      @ObjectModel.foreignKey.association: '_AdhocSet'
      JrnlEntry.CnsldtnAdhocSet,

      @ObjectModel.foreignKey.association: '_AdhocSetItem'
      JrnlEntry.CnsldtnAdhocSetItem,

      // ICMR
      JrnlEntry.MatchingReasonCode,
      JrnlEntry.OriginType,
      JrnlEntry.OriginReference,

      JrnlEntry.CnsldtnGroupJrnlEntryBundle,

      // Elements for the value helps of the parameters
      @Consumption.hidden: true
      :P_ConsolidationUnitHierarchy as ConsolidationUnitHierarchy,

      @Consumption.hidden: true
      :P_ConsolidationSegmentHier   as ConsolidationSegmentHierarchy,

      @Consumption.hidden: true
      :P_ConsolidationPrftCtrHier   as ConsolidationPrftCtrHierarchy,

      @Consumption.hidden: true
      :P_KeyDate                    as KeyDate,

      // Associations ----------------------------------------------------
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

      //BOC By Arnav on 06/11/26 - remapped FS item
      _NewFinStmntItm,
      //EOC By Arnav on 06/11/26 - remapped FS item

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
      _ProfitCenterForElim,
      _FunctionalArea,
      _BusinessArea,
      _ControllingArea,
      _Segment,
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

      // Associations for the value helps of the parameters
      @ObjectModel.association.boundFields.dataMatchesSourceAndTargetTypes: true
      _CnsldtnUnitHierDir,
      _SegmentHierDir,
      _ProfitCenterHierDir
}
