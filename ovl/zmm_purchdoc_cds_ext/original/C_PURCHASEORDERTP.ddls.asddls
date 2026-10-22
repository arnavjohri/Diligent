@VDM.viewType: #CONSUMPTION
@AbapCatalog: { sqlViewName: 'CPURORDTP' }
@ClientHandling.algorithm: #SESSION_VARIABLE
@EndUserText.label: 'Purchase Order'
@AccessControl.authorizationCheck: #CHECK

@ObjectModel: {
    compositionRoot: true,
    transactionalProcessingDelegated: true,
    draftEnabled: true,
    createEnabled: true,
    updateEnabled: 'EXTERNAL_CALCULATION',
    deleteEnabled: 'EXTERNAL_CALCULATION',
    semanticKey: 'PurchaseOrder',
    representativeKey: 'PurchaseOrder',
    sapObjectNodeType.name: 'PurchaseOrder'
}

@ObjectModel.delegatedAction: [ { name: 'COPY_PO' },
                                { name: 'CANCEL_APPROVAL' },
                                { name: 'CWR_PO' },
                                { name: 'CREATE_ITEM_FROM_REF_DOCUMENT' },
                                { name: 'CREATE_ITEMS_FROM_REF_DOCUMNTS' },
                                { name: 'DELETE_ITEM'},
                                { name: 'UNDO_DELETE_ITEM'},
                                { name: 'BLOCK_ITEM'},
                                { name: 'UNBLOCK_ITEM'},
                                { name: 'CREATE_LIMIT_ITEM'},
                                { name: 'TOGGLE_HIERARCHY_VIEW'}]

@ObjectModel.usageType.serviceQuality: #C
@ObjectModel.usageType.sizeCategory: #XL
@ObjectModel.usageType.dataClass: #TRANSACTIONAL
@Search.searchable: true

@UI.headerInfo:{
  typeName:       'Purchase Order',
  typeNamePlural: 'Purchase Orders',
  typeImageUrl:   '/sap/bc/ui5_ui5/sap/mm_po_manages1/images/purchaseorder.jpg',
  title:          { value: 'PurchaseOrder' },
  description:    { value: 'PurchaseOrderTypeName' }
}


@UI: {
  lineItem.criticality: 'PurchaseOrderStatus'
}

@AccessControl.personalData.blocking: #NOT_REQUIRED
@Consumption.dbHints: [ 'USE_HEX_PLAN', 'NO_SUBPLAN_SHARING' ]

define view C_PurchaseOrderTP
  as select from I_PurchaseOrderTP as PurchaseOrderTP

  -------------------------------------------------------------------------------------------
  -- COMPOSITION NODE: Purchase Order                                                      --
  -------------------------------------------------------------------------------------------

  -- :* association to the child node
  association [1..*] to C_PurchaseOrderItemTP          as _PurchaseOrderItemTP          on  _PurchaseOrderItemTP.PurchaseOrder = $projection.PurchaseOrder

  association [1..*] to C_PurchaseOrderItemHierarchyTP as _PurchaseOrderItemHierarchyTP on  _PurchaseOrderItemHierarchyTP.PurchaseOrder = $projection.PurchaseOrder

  association [1..1] to C_PurOrdSupplierAddressTP      as _PurOrdSupplierAddressTP      on  _PurOrdSupplierAddressTP.PurchaseOrder = $projection.PurchaseOrder

  association [0..*] to C_PurOrdRefDocPO               as _PurOrdRefDocPO               on  _PurOrdRefDocPO.Supplier = $projection.Supplier
  association [0..*] to C_PurOrdRefDocIR               as _PurOrdRefDocIR               on  _PurOrdRefDocIR.Supplier = $projection.Supplier
  association [0..*] to C_PurOrdRefDocPC               as _PurOrdRefDocPC               on  _PurOrdRefDocPC.Supplier = $projection.Supplier

  association [0..1] to I_UserContactCard              as _UserContactCard              on  _UserContactCard.ContactCardType = 'User'
                                                                                        and _UserContactCard.ContactCardID   = $projection.CreatedByUser
                                                                                        and _UserContactCard.ContactCardRole = 'Creator'

  association [0..1] to C_OverduePurchaseOrder         as _OverduePurchaseOrder         on  $projection.PurchaseOrder = _OverduePurchaseOrder.PurchaseOrder
  association [0..1] to I_PurchaseOrderRelevance       as _PurchaseOrderRelevance       on  $projection.PurchaseOrder = _PurchaseOrderRelevance.PurchaseOrder
  association [0..1] to I_PurchaseOrderStatus          as _PurchaseOrderStatus          on  $projection.PurchaseOrder = _PurchaseOrderStatus.PurchaseOrder
  association [0..1] to I_PurchasingDocumentStatus     as _PurchasingDocumentStatus     on  $projection.PurchaseOrderStatus_H = _PurchasingDocumentStatus.PurchasingDocumentStatus
  association [1..*] to C_PurchaseOrderFeature         as _PurchaseOrderFeature         on  $projection.PurchaseOrder = _PurchaseOrderFeature.PurchaseOrder
  association [0..*] to C_PurchaseOrderCommitment      as _PurchaseOrderCommitment      on  $projection.PurchaseOrder = _PurchaseOrderCommitment.PurchaseOrder

  -------------------------------------------------------------------------------------------
  -- Value-Help Associations                                                               --
  -------------------------------------------------------------------------------------------

  association [0..1] to I_PaymentTerms                 as _PaymentTerms                 on  _PaymentTerms.PaymentTerms = $projection.PaymentTerms
  association [0..*] to C_PurchaseOrderNoteTP          as _PurchaseOrderNote            on  _PurchaseOrderNote.PurchaseOrder = $projection.PurchaseOrder
  association [0..*] to C_PurchaseOrderPartnerTP       as _PurchaseOrderPartnerTP       on  _PurchaseOrderPartnerTP.PurchaseOrder = $projection.PurchaseOrder

  association [0..1] to C_MM_CompanyCodeValueHelp      as _CompanyCodeValueHelp         on  _CompanyCodeValueHelp.CompanyCode = $projection.CompanyCode
  association [0..1] to C_SupplierPurchOrgVH           as _SupplierValueHelp            on  _SupplierValueHelp.Supplier               = $projection.Supplier
                                                                                        and _SupplierValueHelp.PurchasingOrganization = $projection.PurchasingOrganization
  association [0..1] to C_PurchasingOrgValueHelp       as _PurgOrgValueHelp             on  _PurgOrgValueHelp.PurchasingOrganization = $projection.PurchasingOrganization
                                                                                        and _PurgOrgValueHelp.CompanyCode            = $projection.CompanyCode
  association [0..1] to C_PurchasingGroupValueHelp     as _PurchasingGrpValueHelp       on  _PurchasingGrpValueHelp.PurchasingGroup = $projection.PurchasingGroup
  association [0..1] to C_PurOrdCreatedByValHelp       as _CreatedByValueHelp           on  _CreatedByValueHelp.UserID                 = $projection.CreatedByUser
                                                                                        and _CreatedByValueHelp.UserDescription        = $projection.CreatedByUserFullName
                                                                                        and _CreatedByValueHelp.PurchasingGroup        = $projection.PurchasingGroup
                                                                                        and _CreatedByValueHelp.PurchasingOrganization = $projection.PurchasingOrganization
  association [0..1] to I_Supplier                     as _Supplier                     on  _Supplier.Supplier = $projection.Supplier

  association [0..1] to I_PurgTotProdCmplncSuplrStsT   as _PurgTotProdCmplncSuplrStsT   on  $projection.PurgAggrgdProdCmplncSuplrSts = _PurgTotProdCmplncSuplrStsT.PurgAggrgdProdCmplncSuplrSts
                                                                                        and _PurgTotProdCmplncSuplrStsT.Language     = $session.system_language
  association [0..1] to I_PurgTotProdMarketabilityStsT as _PurgTotProdMarketabilityStsT on  $projection.PurgAggrgdProdMarketabilitySts = _PurgTotProdMarketabilityStsT.PurgAggrgdProdMarketabilitySts
                                                                                        and _PurgTotProdMarketabilityStsT.Language     = $session.system_language
  association [0..1] to I_PurgAggrgdSftyDataSheetStsT  as _PurgAggrgdSftyDataSheetStsT  on  $projection.PurgAggrgdSftyDataSheetStatus = _PurgAggrgdSftyDataSheetStsT.PurgAggrgdSftyDataSheetStatus
                                                                                        and _PurgAggrgdSftyDataSheetStsT.Language     = $session.system_language
  association [0..1] to I_PurgTotDangerousGoodsStsT    as _PurgTotDangerousGoodsStsT    on  $projection.PurgProdCmplncTotDngrsGoodsSts = _PurgTotDangerousGoodsStsT.PurgProdCmplncTotDngrsGoodsSts
                                                                                        and _PurgTotDangerousGoodsStsT.Language        = $session.system_language

  association [0..1] to C_POProdComplianceCriticality  as _POProdComplianceCriticality  on  $projection.PurchaseOrder = _POProdComplianceCriticality.PurchaseOrder

  association [0..*] to C_PurchaseOrderApprover        as _POApprover                   on  $projection.PurchaseOrder = _POApprover.PurchaseOrder

  association [1..1] to I_PurgProcessingStatusText     as _PurOrdProcessingStatusTxt    on  _PurOrdProcessingStatusTxt.PurchasingProcessingStatus = $projection.PurchasingProcessingStatus
                                                                                        and _PurOrdProcessingStatusTxt.Language                   = $session.system_language

  association [1..1] to C_PurchaseOrderStatus          as _POStatus                     on  $projection.PurchaseOrder = _POStatus.PurchaseOrder

{
      @Consumption.semanticObject: 'PurchaseOrder'
      @UI.selectionField: { position: 10 }
      @UI: {
        identification: [ { position: 10},
                          { type: #FOR_ACTION, dataAction: 'BOPF:COPY_PO', label: 'Copy' },
                          { type: #FOR_ACTION, dataAction: 'BOPF:CANCEL_APPROVAL', label: 'Withdraw from Approval' }],

        lineItem: [ { position: 10, importance: #HIGH },
                    { type: #FOR_ACTION, dataAction: 'BOPF:COPY_PO', label: 'Copy' },
                    { type: #FOR_ACTION, dataAction: 'BOPF:CANCEL_APPROVAL', label: 'Withdraw from Approval' } ] }

      @Search: { defaultSearchElement: true, ranking: #HIGH, fuzzinessThreshold: 1 }
      @ObjectModel: { text.element: [ 'PurchaseOrderTypeName' ], readOnly: true, mandatory: true }
  key PurchaseOrderTP.PurchaseOrder,

      @UI: {
        identification: {position: 20},
        textArrangement: #TEXT_FIRST
      }
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION', mandatory: true}
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_POMntnDocumentTypeValueHelp', element: 'PurchaseOrderType'} }]
      PurchaseOrderTP.PurchaseOrderType,

      @UI.hidden:true
      PurchaseOrderTP.PurchaseOrderTypeName,

      @UI: {
        identification: { position: 30 },
        textArrangement: #TEXT_FIRST,
        lineItem: [ {position: 50, importance: #HIGH} ],
        selectionField: { position: 30 }
      }
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION', mandatory: true, foreignKey.association: '_CompanyCodeValueHelp',  text.association: '_CompanyCodeValueHelp'  }
      @Consumption: { valueHelp: '_CompanyCodeValueHelp' }
      PurchaseOrderTP.CompanyCode,

      @UI: {
        identification: { position: 60 },
        textArrangement: #TEXT_FIRST
      }
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION', foreignKey.association: '_PurgOrgValueHelp', text.association: '_PurgOrgValueHelp'}
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_PurchasingOrgValueHelp', element: 'PurchasingOrganization'}, additionalBinding: [{ element: 'CompanyCode', localElement: 'CompanyCode' }] }]
      cast (PurchaseOrderTP.PurchasingOrganization as ekorg_ll preserving type ) as PurchasingOrganization,

      @UI: {
        identification: { position: 50 },
        selectionField: { position: 20 },
        textArrangement: #TEXT_FIRST
      }
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION', foreignKey.association: '_PurchasingGrpValueHelp', text.association: '_PurchasingGrpValueHelp'}
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_PurchasingGroupValueHelp', element: 'PurchasingGroup'} }]
      PurchaseOrderTP.PurchasingGroup,

      @UI: {
        selectionField: {position: 10},
        identification: {position: 20},
        textArrangement: #TEXT_FIRST,
        lineItem: [ {position: 30, importance: #HIGH} ]
      }
      @Search: { defaultSearchElement: true, ranking: #MEDIUM, fuzzinessThreshold: 0.9 }
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_SupplierPurchOrgVH', element: 'Supplier'}, additionalBinding: [{ element: 'PurchasingOrganization', localElement: 'PurchasingOrganization' }] }]
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION', text.element: [ 'SupplierName' ] }
      PurchaseOrderTP.Supplier,

      @UI: {
        identification: {position: 40},
        textArrangement: #TEXT_FIRST
      }
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION', foreignKey.association: '_DocumentCurrency', text.association: '_DocumentCurrency' }
      @Semantics: { currencyCode: true }
      PurchaseOrderTP.DocumentCurrency,

      ----------------------------------------------------------------------------------------
      -- Calculated fields                                                                 --
      ----------------------------------------------------------------------------------------

      @UI: {
        lineItem: [ {position: 40, importance: #HIGH} ]
      }
      @Consumption.hidden: true
      @ObjectModel.readOnly: true
      _OverduePurchaseOrder.NumberOfOverduePurOrders                             as NumberOfOverduePurOrders,

      @Consumption.hidden: true
      @ObjectModel.readOnly: true
      _OverduePurchaseOrder.NumberOfOverduePurOrdItm                             as NumberOfOverduePurOrdItm_H,

      @ObjectModel.readOnly: true
      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      @ObjectModel.sort.transformedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      cast( 0 as abap.int4 )                                                     as NumberOfOverduePurOrdItm,

      @UI: {
        lineItem: { position: 60, importance: #HIGH, criticality: 'PurchaseOrderStatusCalc'},
        selectionField: { position: 50 },
        textArrangement: #TEXT_ONLY
      }
      @ObjectModel: {
        readOnly: true,
        text.element:  [ 'PurchaseOrderStatusName' ]
      }
      @Consumption.valueHelpDefinition: [{ entity: { name : 'I_PurchaseOrderStatusValueHelp', element : 'PurchasingDocumentStatus' } }]
      @EndUserText.label: 'Status'
      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      @ObjectModel.filter.transformedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      @ObjectModel.sort.transformedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      cast ( '' as abap.char(2))                                                 as PurchaseOrderStatus,

      @UI.hidden: true
      @ObjectModel: {
        readOnly: true
      }
      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      cast ( '' as mmpur_ord_status )                                            as PurchaseOrderStatusName,

      @Consumption.hidden: true
      @ObjectModel.readOnly: true
      _PurchaseOrderStatus.PurchasingDocumentStatus                              as PurchaseOrderStatus_H,

      @Consumption.hidden: true
      @ObjectModel.readOnly: true
      _PurchaseOrderStatus.PurchasingDocumentStatus,

      @UI.hidden: true
      PurchaseOrderTP.ReleaseIsNotCompleted,
      @UI.hidden: true
      @ObjectModel.text.element: ['PurchasingProcessingStatusName']
      PurchaseOrderTP.PurchasingProcessingStatus,
      @UI.hidden: true
      @ObjectModel.readOnly: true
      @Semantics.text: true
      _PurOrdProcessingStatusTxt.PurchasingProcessingStatusName,
      @UI.hidden: true
      PurchaseOrderTP.PurchasingCompletenessStatus,

      @UI: {
        lineItem: [ {position: 90, importance: #HIGH} ]
      }
      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @Semantics: { amount.currencyCode: 'DocumentCurrency' }
      cast( 0 as mm_pur_order_tot_net_amount )                                   as PurchaseOrderNetAmount,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT',
        sort.transformedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      cast( 0 as vdm_weightedrelevance )                                         as WeightedRelevance,

      @ObjectModel.readOnly: true

      @Consumption.hidden: true
      //attention: the field is always null for a non overdue purchase order
      _OverduePurchaseOrder.ScheduleLineDeliveryDate                             as ScheduleLineDeliveryDate,

      @UI.selectionField.position: 60
      @EndUserText.label: 'Material'
      @ObjectModel.virtualElement
      @ObjectModel.readOnly: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      @ObjectModel.filter.transformedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'

      @Consumption.valueHelpDefinition: [{ entity: { name : 'C_MM_MaterialValueHelp', element : 'Material' }, additionalBinding: [{ localElement: 'Plant', element: 'Plant' }] }]
      cast( '' as abap.sstring( 260 ) )                                          as ManufacturerMaterial,

      @UI.selectionField.position: 70
      @EndUserText.label: 'Plant'
      @ObjectModel.virtualElement
      @ObjectModel.readOnly: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'
      @ObjectModel.filter.transformedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_FILTERS'

      @Consumption.valueHelpDefinition: [{ entity: { name : 'C_MM_PlantValueHelp', element : 'Plant' }, additionalBinding: [{ localElement: 'PurchasingOrganization', element: 'PurchasingOrganization' }] }]
      cast( '' as abap.sstring( 260 ) )                                          as Plant,

      ----------------------------------------------------------------------------------------
      -- Transient fields                                                                   --
      ----------------------------------------------------------------------------------------

      @UI: {
        lineItem: [ {position: 20, importance: #HIGH} ]
      }
      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      cast( '' as mm_advanced_po )                                               as IsAdvancedPurchaseOrder,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as abap.char( 1 ) )                                               as PurOrdOutputCtrlType, //fka OutputControlType

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as abap.char( 1 ) )                                               as PurchaseOrderOutputStatus, //fka OutputStatusNast

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as abap.char( 60 ) )                                              as PurchaseOrderOutputStatusName, //fka OutputStatusTextNast

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('00000000000000' as timestamp)                                       as PurchaseOrderOutputDateTime, //fka OutputStatusTimestampNast

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast( '' as abap.char( 02 ) )                                              as ApprovalStatus,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.identification: [{ position: 80 }]
      cast( '' as mm_approval_status )                                           as ApprovalStatusName,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      cast( '' as mm_approver_name )                                             as ApproverName,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast( 0 as mmpur_approver_count )                                          as PurchaseOrderNumberOfApprovers,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @Feature: 'SW:MM_PUR_PURCHORD_REWORK_WFL'
      cast( '' as mm_approver_comment )                                          as POApproverCommentText,

      @Feature: 'SW:MM_PUR_PURCHORD_REWORK_WFL'
      PurchaseOrderTP.POReworkCommentText                                        as POReworkCommentText,

      @UI.identification: [{ position: 110, importance: #HIGH, label:'Approver', value: '_POApprover.ApproverName' }]
      @ObjectModel.filter.enabled: false
      _POApprover,

      @ObjectModel: {
        filter.enabled: false,
        sort.enabled: false,
        readOnly: true
      }
      _POStatus,

      @ObjectModel.readOnly: true
      @UI.hidden: true
      _PurchaseOrderType.PurgHasFlxblWorkflowApproval,

      ----------------------------------------------------------------------------------------
      --  Administrative Data
      ----------------------------------------------------------------------------------------

      @ObjectModel: { text.element:  [ 'CreatedByUserFullName' ], readOnly: true }
      @Search: { defaultSearchElement: true, ranking: #MEDIUM, fuzzinessThreshold: 0.8 }
      @UI.textArrangement: #TEXT_FIRST
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_PurOrdCreatedByValHelp', element: 'UserID'} }]
      PurchaseOrderTP.CreatedByUser,

      @Search: { defaultSearchElement: true, ranking: #MEDIUM, fuzzinessThreshold: 0.8 }
      @UI.hidden: true
      //      @Consumption.filter.hidden: true
      PurchaseOrderTP.CreatedByUserFullName,

      @ObjectModel: { readOnly: true }
      PurchaseOrderTP.CreationDate,
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION'}
      @Semantics.businessDate.at: true
      @UI: {
        identification: { position: 90 },
        lineItem: [ { position: 90, importance: #HIGH } ]
      }
      PurchaseOrderTP.PurchaseOrderDate,
      @ObjectModel: { readOnly: true, foreignKey.association: '_Language' }
      @UI.identification: { position: 70 }
      @Semantics.language: false
      PurchaseOrderTP.Language,

      --------------------------------------------------------------------------------------
      --  Delivery and Invoice
      ----------------------------------------------------------------------------------------
      @UI.fieldGroup: [ { groupLabel: 'Delivery and Invoice', position: 10, qualifier: 'DeliveryInvoiceGroup1' } ]
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_MM_PaymentTermValueHelp', element: 'PaymentTerms'} }]
      PurchaseOrderTP.PaymentTerms,

      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      @EndUserText.label: 'Days 1 / In Percent'
      PurchaseOrderTP.CashDiscount1Days,

      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      cast (PurchaseOrderTP.CashDiscount1Percent as dzbd1p_ll preserving type)   as CashDiscount1Percent,

      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      @EndUserText.label: 'Days 2 / In Percent'
      PurchaseOrderTP.CashDiscount2Days,

      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      cast(PurchaseOrderTP.CashDiscount2Percent as dzbd2p_ll preserving type)    as CashDiscount2Percent,

      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.NetPaymentDays,

      @UI.fieldGroup: [ { groupLabel: 'Delivery and Invoice 2', position: 10, qualifier: 'DeliveryInvoiceGroup2' } ]
      @ObjectModel: { foreignKey.association: '_IncotermsVersion', readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IncotermsVersion,

      @UI.fieldGroup: [ { position: 20, qualifier: 'DeliveryInvoiceGroup2'} ]
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_MM_IncotermValueHelp', element: 'IncotermsClassification'}} ]
      PurchaseOrderTP.IncotermsClassification,

      @UI.fieldGroup: [ { position: 30, importance: #HIGH, qualifier: 'DeliveryInvoiceGroup2' ,invocationGrouping: #CHANGE_SET} ]
      @Consumption.valueHelpDefinition: [{entity: {name: 'I_TransportationLocationVH', element: 'Location'} }]
      @UI.textArrangement: #TEXT_FIRST
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IncotermsLocation1Identifier,
      @UI.hidden: true
      PurchaseOrderTP.IncotermsSupChnLoc1AddlUUID,

      @UI.fieldGroup: [ { position: 40, qualifier: 'DeliveryInvoiceGroup2'} ]
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IncotermsLocation1,

      @UI.fieldGroup: [ { position: 50, importance: #HIGH, qualifier: 'DeliveryInvoiceGroup2' } ]
      @ObjectModel.readOnly:'EXTERNAL_CALCULATION'
      @Consumption.valueHelpDefinition: [{entity: {name: 'I_TransportationLocationVH', element: 'Location'} }]
      @UI.textArrangement: #TEXT_FIRST
      PurchaseOrderTP.IncotermsDvtgLocIdentifier,
      @UI.hidden: true
      PurchaseOrderTP.IncotermsSupChnDvtgLocAddlUUID,

      @UI.fieldGroup: [ { groupLabel: 'Delivery and Invoice 2', qualifier: 'DeliveryInvoiceGroup2', position: 60 } ]
      @ObjectModel: { readOnly: 'EXTERNAL_CALCULATION'}
      PurchaseOrderTP.IncotermsDvtgLocDescription,

      @UI.fieldGroup: [ { position: 70, importance: #HIGH, qualifier: 'DeliveryInvoiceGroup2' ,invocationGrouping: #CHANGE_SET} ]
      @Consumption.valueHelpDefinition: [{entity: {name: 'I_TransportationLocationVH', element: 'Location'} }]
      @UI.textArrangement: #TEXT_FIRST
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IncotermsLocation2Identifier,

      @UI.hidden: true
      PurchaseOrderTP.IncotermsSupChnLoc2AddlUUID,

      @UI.fieldGroup: [ { position: 80, qualifier: 'DeliveryInvoiceGroup2'} ]
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IncotermsLocation2,

      @UI.fieldGroup: [ { groupLabel: 'Delivery and Invoice 3', position: 10, qualifier: 'DeliveryInvoiceGroup3' } ]
      @Consumption.valueHelpDefinition: [{entity: {name: 'C_SupplierPurchOrgVH', element: 'Supplier'} }]
      PurchaseOrderTP.InvoicingParty,

      @UI.fieldGroup: [ { position: 20, qualifier: 'DeliveryInvoiceGroup3' } ]
      @EndUserText.label: 'Exchange Rate'
      PurchaseOrderTP.ExchangeRateForEdit,

      @UI.fieldGroup: [ { position: 30, qualifier: 'DeliveryInvoiceGroup3' } ]
      @EndUserText.label: 'Fixed Exchange Rate'
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.ExchangeRateIsFixed,                                  //3325054

      @UI.fieldGroup: [ { position: 40, qualifier: 'DeliveryInvoiceGroup3' } ]
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IsIntrastatReportingRelevant,

      @UI.fieldGroup: [ { position: 50, qualifier: 'DeliveryInvoiceGroup3' } ]
      @ObjectModel: {  readOnly: 'EXTERNAL_CALCULATION' }
      PurchaseOrderTP.IsIntrastatReportingExcluded,

      //    Data Privacy and Protection
      IsEndOfPurposeBlocked,

      //   Fields processing  App features

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      PurchaseOrderTP.PurchaseOrderHasCommitmentItem,

      ----------------------------------------------------------------------------------------
      -- Supplier Contact Person Data                                                       --
      ----------------------------------------------------------------------------------------

      @UI.fieldGroup: [ { groupLabel: 'Supplier Contact Person', position: 10, qualifier: 'SupplierContactPerson' } ]
      @EndUserText.label: 'Sales Person'
      PurchaseOrderTP.SupplierRespSalesPersonName,
      @UI.fieldGroup: [ { position: 20, qualifier: 'SupplierContactPerson' } ]
      PurchaseOrderTP.SupplierPhoneNumber,
      @UI.fieldGroup: [ { position: 30, qualifier: 'SupplierContactPerson' } ]
      PurchaseOrderTP.CorrespncExternalReference,
      @UI.fieldGroup: [ { position: 40, qualifier: 'SupplierContactPerson' } ]
      PurchaseOrderTP.CorrespncInternalReference,


      ----------------------------------------------------------------------------------------
      -- Product Compliance                                                                 --
      ----------------------------------------------------------------------------------------
      @ObjectModel: { readOnly: true }
      @UI.fieldGroup: [ { groupLabel: 'Product Compliance', position: 10, qualifier: 'ProductCompliance'
      ,criticality: 'UICT_PurgAggrgdCmplncSuplrSts',criticalityRepresentation: #WITHOUT_ICON
      } ]
      _PurgTotProdCmplncSuplrStsT.PurgTotProdCmplncSuplrStsName,

      @UI.hidden: true
      PurgAggrgdProdCmplncSuplrSts,

      @ObjectModel.readOnly: true
      @UI.hidden: true
      _POProdComplianceCriticality.UICT_PurgAggrgdCmplncSuplrSts,


      @ObjectModel: { readOnly: true }
      @UI.fieldGroup: [ { position: 20, qualifier: 'ProductCompliance'
      ,criticality: 'UICT_PurgAggrgMarketabilitySts', criticalityRepresentation: #WITHOUT_ICON } ]
      _PurgTotProdMarketabilityStsT.PurgTotMarketabilityStsName,

      @UI.hidden: true
      PurgAggrgdProdMarketabilitySts,

      @ObjectModel.readOnly: true
      @UI.hidden: true
      _POProdComplianceCriticality.UICT_PurgAggrgMarketabilitySts,

      @ObjectModel: { readOnly: true }
      @UI.fieldGroup: [ { position: 40, qualifier: 'ProductCompliance'
      ,criticality: 'UICT_PurgAggrgSftyDataSheetSts', criticalityRepresentation: #WITHOUT_ICON } ]
      _PurgAggrgdSftyDataSheetStsT.PurgAggrgdSftyDataSheetStsName,

      @UI.hidden: true
      PurgAggrgdSftyDataSheetStatus,


      @ObjectModel.readOnly: true
      @UI.hidden: true
      _POProdComplianceCriticality.UICT_PurgAggrgSftyDataSheetSts,

      @ObjectModel: { readOnly: true }
      @UI.fieldGroup: [ { position: 30, qualifier: 'ProductCompliance'
      ,criticality: 'UICT_PurgCmplncTotDngrsGdsSts', criticalityRepresentation: #WITHOUT_ICON } ]
      _PurgTotDangerousGoodsStsT.PurgTotDangerousGoodsStsName,

      @UI.hidden: true
      PurgProdCmplncTotDngrsGoodsSts,

      @ObjectModel.readOnly: true
      @UI.hidden: true
      _POProdComplianceCriticality.UICT_PurgCmplncTotDngrsGdsSts,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as ehfnd_boolean)                                                 as ProductComplianceIsActive,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as ehfnd_bf_pcs_is_active)                                        as BusFtreProdCmplncSuplrIsActive,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as ehfnd_bf_pma_is_active)                                        as BusFtreProdMarketabilityIsActv,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as ehfnd_bf_dg_is_active)                                         as BusFtreDngrsGoodsIsActive,

      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as ehfnd_bf_sds_is_active)                                        as BusFtreSftyDataShtMgmtIsActive,

      ----------------------------------------------------------------------------------------
      -- HDM enablement for attachments                                                     --
      ----------------------------------------------------------------------------------------
      @ObjectModel: {
        readOnly: true,
        virtualElement,
        virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as hdm_adoption_ind)                                              as HarmonizedDocumentMgmtIsActive,

      ----------------------------------------------------------------------------------------
      -- Unused fields                                                                      --
      ----------------------------------------------------------------------------------------

      @Consumption.hidden: true
      PurchaseOrderTP.PurchaseOrderSubtype,
      @Consumption.hidden: true
      PurchaseOrderTP.PurchasingDocumentOrigin,
      @Consumption.hidden: true
      PurchaseOrderTP.PurchasingDocumentDeletionCode,
      @Consumption.hidden: true
      PurchaseOrderTP.ManualSupplierAddressID,
      @Consumption.hidden: true
      PurchaseOrderTP.SupplierAddressID,
      @Consumption.hidden: true
      PurchaseOrderTP.SupplyingSupplier,
      @Consumption.hidden: true
      PurchaseOrderTP.SupplyingPlant,
      @Consumption.hidden: true
      PurchaseOrderTP.PurchasingDocumentCondition,
      @Consumption.hidden: true
      PurchaseOrderTP.PricingProcedure,
      @Consumption.hidden: true
      PurchaseOrderTP.ValidityStartDate,
      @Consumption.hidden: true
      PurchaseOrderTP.ValidityEndDate,
      @Consumption.hidden: true
      PurchaseOrderTP.IncotermsTransferLocation,

      ----------------------------------------------------------------------------------------
      -- Not for UI Exposure but used internally                                            --
      ----------------------------------------------------------------------------------------

      @UI: { hidden: true }
      PurchaseOrderTP.LastChangeDateTime,

      @UI: { hidden: true }
      PurchaseOrderTP.PurchasingHasItemHierarchy,

      @ObjectModel: {
      readOnly: true,
      virtualElement,
      virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as boolean)                                                       as SrvcProcmtItmHierIsEnbld,

      @ObjectModel: {
      readOnly: true,
      virtualElement,
      virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as boolean)                                                       as PurchaseOrderPrtnFuncIsEnbld,

      @ObjectModel: {
      readOnly: true,
      virtualElement,
      virtualElementCalculatedBy: 'ABAP:CL_MM_PUR_PO_MAINT_V2_TRA_EXIT'
      }
      @UI.hidden: true
      cast ('' as boolean)                                                       as PurOrderOutputPreviewIsEnabled,

      ----------------------------------------------------------------------------------------
      -- Associations                                                                       --
      ----------------------------------------------------------------------------------------
      //    enable 1:n on header level via Association
      @ObjectModel.association.type: [ #TO_COMPOSITION_CHILD ]
      _PurchaseOrderItemTP                                                       as _PurchaseOrderItemTP,

      //    enable 1:n on header level via Association
      @ObjectModel.sort.enabled: false
      @ObjectModel.filter.enabled: false
      @ObjectModel.association.type: [ #TO_COMPOSITION_CHILD ]
      _PurchaseOrderItemHierarchyTP,


      @ObjectModel.association.type: [ #TO_COMPOSITION_CHILD ]
      _PurOrdSupplierAddressTP,

      @ObjectModel.association.type: [ #TO_COMPOSITION_CHILD ]
      _PurchaseOrderNote,

      @ObjectModel.association.type: [ #TO_COMPOSITION_CHILD ]
      _PurchaseOrderPartnerTP,

      _PurOrdRefDocPO,
      _PurOrdRefDocIR,
      _PurOrdRefDocPC,

      @UI.identification: { position: 80, label: 'Created By', type: #AS_CONTACT }
      @Consumption.filter.hidden: true
      _UserContactCard,

      @Consumption.filter.hidden: true
      PurchaseOrderTP._DocumentCurrency,

      @Consumption.filter.hidden: true
      PurchaseOrderTP._IncotermsClassification,

      @Consumption.filter.hidden: true
      PurchaseOrderTP._IncotermsVersion,

      @Consumption.filter.hidden: true
      PurchaseOrderTP._Language,

      @Consumption.filter.hidden: true
      PurchaseOrderTP._PurchaseOrderType,

      @Consumption.filter.hidden: true
      _PurchasingDocumentStatus,

      @Consumption.filter.hidden: true
      _SupplierValueHelp,

      @Consumption.filter.hidden: true
      _CompanyCodeValueHelp,

      @Consumption.filter.hidden: true
      _PurgOrgValueHelp,

      @Consumption.filter.hidden: true
      _PurchasingGrpValueHelp,

      @Consumption.filter.hidden: true
      _CreatedByValueHelp,

      @Consumption.filter.hidden: true
      _PurchaseOrderFeature,

      @Consumption.filter.hidden: true
      _PurchaseOrderCommitment,

      @Consumption.filter.hidden: true
      _PurchaseOrderRelevance,

      @Consumption.filter.hidden: true
      _InvoicingParty,

      @ObjectModel.readOnly
      @Consumption.filter.hidden: true
      @UI.hidden: true
      @Semantics.text: true
      _Supplier.SupplierName,

      @ObjectModel.readOnly
      @Consumption.filter.hidden: true
      _POProdComplianceCriticality

      //      @ObjectModel.association.type: [ #TO_COMPOSITION_PARENT, #TO_COMPOSITION_ROOT ]

}
