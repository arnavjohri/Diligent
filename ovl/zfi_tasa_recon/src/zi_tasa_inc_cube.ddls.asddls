//----------------------------------------------------------------------
// Object    : ZI_TASA_INC_CUBE (DDL source, classic view, cube)
// Title     : TASA recon - TASA income by project / subsidiary
//             (cube for Custom Analytical Queries)
// Project   : OVL                                   Module: FI-GL
// Source    : TASA Recon Statement_AnnualFY26_v5.xlsx, sheet P&L-TASA
// Author    : Arnav Johri                            Date: 24.11.2026
// Transport : OCDK920558
//----------------------------------------------------------------------
// DESCRIPTION
//   Data source of the query "TASA Income". Rows: Sort No. + Project /
//   Subsidiary (ZFI_TASA_MAP; partners not in the table -> "Other").
//   Columns: Fiscal Year (start year: 2025 = FY26) and Fiscal Quarter,
//   measures Income USD / INR. Quarter-on-quarter difference and % are
//   restricted / calculated measures of the query. Related Party Income
//   is a measure of its own (workbook row 32).
//   After activation: ADT, Properties, API State, Add Release State,
//   contract Use in Key User Apps (C1).
//
// CHANGE HISTORY
//   24.11.2026  Arnav Johri  OCDK920558  Initial development
//----------------------------------------------------------------------
// ASSUMPTION: amounts are plain decimals; USD = global currency, INR =
//   company code currency of OVL, as on ZI_SLDI_CUBE.
// ASSUMPTION: no access control, as on the earlier cubes.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZITASAINCCUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TASA income by project / subsidiary (cube)'
@VDM.viewType: #COMPOSITE
@Analytics.dataCategory: #CUBE
@ObjectModel.modelingPattern: #ANALYTICAL_CUBE
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_PROVIDER,
                                      #CDS_MODELING_DATA_SOURCE,
                                      #CDS_MODELING_ASSOCIATION_TARGET,
                                      #SQL_DATA_SOURCE ]
@ClientHandling.algorithm: #SESSION_VARIABLE
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType.sizeCategory: #M
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.dataClass: #MIXED
define view ZI_TASA_INC_CUBE
  as select from    ZI_TASA_INC_ITEM as Item
    left outer join zfi_tasa_map     as Map on  Map.bukrs   = Item.company_code
                                            and Map.partner = Item.partner
  association [0..1] to I_CompanyCode as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
{
      // -- keys ----------------------------------------------------------
      @ObjectModel.foreignKey.association: '_CompanyCode'
      @EndUserText.label: 'Company Code'
  key Item.company_code                              as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Item.fiscal_year                               as FiscalYear,
      @EndUserText.label: 'Document Number'
  key Item.accounting_doc                            as AccountingDocument,
      @EndUserText.label: 'Ledger Line Item'
  key Item.ledger_gl_item                            as LedgerGLLineItem,

      // -- time ----------------------------------------------------------
      @EndUserText.label: 'Fiscal Quarter'
      Item.fiscal_quarter                            as FiscalQuarter,
      @EndUserText.label: 'Fiscal Period'
      Item.fiscal_period                             as FiscalPeriod,

      // -- report row ------------------------------------------------------
      @EndUserText.label: 'Sort No.'
      coalesce( Map.sortno, '999' )                  as SortNumber,
      @EndUserText.label: 'Project / Subsidiary'
      coalesce( Map.rowtxt, 'Other' )                as ProjectSubsidiary,
      @EndUserText.label: 'Customer / G/L (Partner)'
      Item.partner                                   as PartnerAccount,
      @EndUserText.label: 'Related Party'
      case Map.relpty when 'X' then 'Yes' else 'No' end
                                                     as IsRelatedParty,

      // -- line item attributes (drill-down) -------------------------------
      @EndUserText.label: 'G/L Account'
      Item.gl_account                                as GLAccount,
      @EndUserText.label: 'Posting Date'
      Item.posting_date                              as PostingDate,
      @EndUserText.label: 'Document Type'
      Item.document_type                             as AccountingDocumentType,
      @EndUserText.label: 'Item Text'
      Item.item_text                                 as DocumentItemText,
      @EndUserText.label: 'Assignment'
      Item.assignment                                as AssignmentReference,
      @EndUserText.label: 'Joint Venture'
      Item.joint_venture                             as JointVenture,
      @EndUserText.label: 'Company Code Currency'
      Item.co_code_currency                          as CompanyCodeCurrency,
      @EndUserText.label: 'Global Currency'
      Item.global_currency                           as GlobalCurrency,

      // -- measures --------------------------------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'TASA Income (USD)'
      Item.income_usd                                as IncomeAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'TASA Income (INR)'
      Item.income_inr                                as IncomeAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Related Party Income (USD)'
      case Map.relpty
        when 'X' then Item.income_usd
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as RelatedPartyIncome,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Related Party Income (INR)'
      case Map.relpty
        when 'X' then Item.income_inr
        else          cast( 0 as abap.dec( 23, 2 ) )
      end                                            as RelatedPartyIncomeInCCCrcy,

      // -- associations ----------------------------------------------------
      _CompanyCode
}
