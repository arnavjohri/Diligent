//----------------------------------------------------------------------
// Object    : ZI_SLDI_CUBE (DDL source, classic view, cube)
// Title     : Subsidiary loan, accrued interest and deemed investment
//             schedule (cube for Custom Analytical Queries)
// Project   : OVL                                   Module: FI-GL
// Source    : SAP_FIORI_-_Subsidiaries_Loan_and_Deemed_Investment_
//             Schedule_-_Annual_FY26.xlsx, sheet Loan & Interest Movement
// Author    : Arnav Johri                            Date: 20.11.2026
// Transport : OCDK920552
//----------------------------------------------------------------------
// DESCRIPTION
//   Object 5 of 5: the data source picked in the Fiori app Custom
//   Analytical Queries. One row per G/L line item from ZI_SLDI_ITEM_TF.
//   Prompts: From Date and To Date (01.04.2025 / 31.03.2026 for FY26).
//   Rows of a query: ScheduleType (filter: L, I or D - one query per
//   schedule), Row No. / Subsidiary. Columns per schedule:
//     Loan       Opening | Addition | Reduction | Closing | Provision |
//                Net
//     Interest   Opening | Addition (= interest recognised) | Reduction
//                | Closing | Provision | Net
//     Deemed     Opening | Addition | Conv. to Equity | Conv. to
//                Preference | [Closing - Conv. to Loan] | Conv. to Loan
//                | Closing; the INR measures; INR / USD per column
//   The two figures in brackets / with a slash are calculated measures
//   of the query. Unclassified Movement should be on every query: it
//   must be zero, otherwise an item text matched no rule.
//   Provision accounts (ZFI_SLDI_ROW-PROVFLAG) fill only Provision and
//   Net Balance.
//   After activation: ADT, Properties, API State, Add Release State,
//   contract Use in Key User Apps (C1).
//
// CHANGE HISTORY
//   20.11.2026  Arnav Johri  <TR>  Initial development
//   23.11.2026  Arnav Johri  OCDK920552  Parameters DATUM -> VDM_V_KEY_DATE
//                                         (refused by Custom Analytical Queries)
//   23.11.2026  Arnav Johri  OCDK920552  Element Schedule -> ScheduleType
//                                         (SCHEDULE is a reserved word in CAQ)
//----------------------------------------------------------------------
// ASSUMPTION: opening balance = open items as at the day before the
//   From Date (the workbook's FBL3N key date 01.04.2025 would count
//   postings of 1 April in the opening and in the movement).
// ASSUMPTION: amounts are plain decimals; USD = global currency, INR =
//   company code currency of OVL. Both currency keys are dimensions.
// ASSUMPTION: no access control, as on the earlier cubes. The published
//   query runs with the user's analytics authorisations.
// ASSUMPTION: view parameters can be passed on to a table function
//   (not yet used on this system; standard syntax).
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZISLDICUBE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Subsidiary loan and deemed investment schedule (cube)'
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
// Parameters typed with released data element VDM_V_KEY_DATE: Custom
// Analytical Queries refuses DATUM ("The use of Data Element DATUM is not
// permitted", OCD 23.11.2026); VDM_V_KEY_DATE is the one bank reval uses.
define view ZI_SLDI_CUBE
  with parameters
    @EndUserText.label: 'From Date'
    P_FromDate : vdm_v_key_date,
    @EndUserText.label: 'To Date'
    P_ToDate   : vdm_v_key_date
  as select from ZI_SLDI_ITEM_TF( p_clnt : $session.client,
                                  p_from : $parameters.P_FromDate,
                                  p_to   : $parameters.P_ToDate ) as Item
  association [0..1] to I_CompanyCode as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
{
      // -- keys ----------------------------------------------------------
      @ObjectModel.foreignKey.association: '_CompanyCode'
      @EndUserText.label: 'Company Code'
  key Item.company_code       as CompanyCode,
      @EndUserText.label: 'Fiscal Year'
  key Item.fiscal_year        as FiscalYear,
      @EndUserText.label: 'Document Number'
  key Item.accounting_doc     as AccountingDocument,
      @EndUserText.label: 'Ledger Line Item'
  key Item.ledger_gl_item     as LedgerGLLineItem,

      // -- schedule and row ------------------------------------------------
      @ObjectModel.text.element: ['ScheduleName']
      // Element name SCHEDULE is refused by Custom Analytical Queries
      // ("SCHEDULE is a reserved word"), OCD 23.11.2026.
      @EndUserText.label: 'Schedule'
      Item.schedule           as ScheduleType,
      @EndUserText.label: 'Schedule Name'
      case Item.schedule
        when 'L' then 'Loan Movement Schedule'
        when 'I' then 'Accrued Interest Movement Schedule'
        when 'D' then 'Deemed Investment Schedule'
        else          'Not Mapped'
      end                     as ScheduleName,
      @ObjectModel.text.element: ['Subsidiary']
      @EndUserText.label: 'Row No.'
      Item.row_no             as ScheduleRow,
      @EndUserText.label: 'Subsidiary'
      Item.row_text           as Subsidiary,
      @EndUserText.label: 'Provision Account'
      Item.is_provision       as IsProvisionAccount,
      @ObjectModel.text.element: ['MovementColumnName']
      @EndUserText.label: 'Movement Column'
      Item.movement_column    as MovementColumn,
      @EndUserText.label: 'Movement Column Name'
      case Item.movement_column
        when '1' then 'Additional Funding / Interest Recognised'
        when '2' then 'Repayment / Conversion / Interest'
        when '3' then 'Conversion to Equity Shares'
        when '4' then 'Conversion to Preference Shares'
        when '5' then 'Conversion to Loan'
        else          'Unclassified'
      end                     as MovementColumnName,

      // -- line item attributes (drill-down) -------------------------------
      @EndUserText.label: 'G/L Account'
      Item.gl_account         as GLAccount,
      @EndUserText.label: 'Posting Date'
      Item.posting_date       as PostingDate,
      @EndUserText.label: 'Clearing Date'
      Item.clearing_date      as ClearingDate,
      @EndUserText.label: 'Document Type'
      Item.document_type      as AccountingDocumentType,
      @EndUserText.label: 'Debit/Credit'
      Item.debit_credit       as DebitCreditCode,
      @EndUserText.label: 'Item Text'
      Item.item_text          as DocumentItemText,
      @EndUserText.label: 'Assignment'
      Item.assignment         as AssignmentReference,
      @EndUserText.label: 'Trading Partner'
      Item.partner_company    as PartnerCompany,
      @EndUserText.label: 'Offsetting Account'
      Item.offsetting_account as OffsettingAccount,
      @EndUserText.label: 'Company Code Currency'
      Item.co_code_currency   as CompanyCodeCurrency,
      @EndUserText.label: 'Global Currency'
      Item.global_currency    as GlobalCurrency,

      // -- measures, USD (global currency) ---------------------------------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Opening Balance (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        else Item.opening_usd
      end                     as OpeningBalance,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Additional Funding / Interest Recognised (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '1' then Item.movement_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as AdditionAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Repayment / Conversion / Interest (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '2' then Item.movement_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ReductionAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Conversion to Equity Shares (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '3' then Item.movement_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ConvToEquityAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Conversion to Preference Shares (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '4' then Item.movement_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ConvToPreferenceAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Conversion to Loan (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '5' then Item.movement_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ConvToLoanAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Unclassified Movement (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '9' then Item.movement_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as UnclassifiedAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Total Movement (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        else Item.movement_usd
      end                     as TotalMovementAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Closing Balance (USD)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        else Item.closing_usd
      end                     as ClosingBalance,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Provision Made (USD)'
      case
        when Item.is_provision = 'X' then Item.closing_usd
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ProvisionAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Net Balance (USD)'
      Item.closing_usd        as NetBalance,

      // -- measures, INR (company code currency, at transaction date) -------
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Additional Funding / Interest Recognised (INR)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '1' then Item.movement_inr
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as AdditionAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Repayment / Conversion / Interest (INR)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '2' then Item.movement_inr
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ReductionAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Conversion to Equity Shares (INR)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '3' then Item.movement_inr
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ConvToEquityAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Conversion to Preference Shares (INR)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '4' then Item.movement_inr
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ConvToPreferenceAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Conversion to Loan (INR)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        when Item.movement_column = '5' then Item.movement_inr
        else cast( 0 as abap.dec( 23, 2 ) )
      end                     as ConvToLoanAmountInCCCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Total Movement (INR)'
      case
        when Item.is_provision = 'X' then cast( 0 as abap.dec( 23, 2 ) )
        else Item.movement_inr
      end                     as TotalMovementAmountInCCCrcy,

      // -- associations ----------------------------------------------------
      _CompanyCode
}
