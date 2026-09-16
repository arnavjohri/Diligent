// BOC By Arnav on 16/09/26
// Converted from "define view entity" (OData V4 only) to a classic DDIC-based
// view so that @OData.publish: true generates the OData V2 service
// ZDPR_Q_PROD_PERF_CDS needed by the Overview Page (all other query services
// are V2; an OVP runs on one protocol). Classic views allow '/' on floats
// only, so every ratio uses division( a, b, decimals ).
// Select list unchanged: DDLX ZDPR_Q_PROD_PERF and ZDPR_SD_ANALYTICS stay valid.
// @OData.entityType.name dropped: with @OData.publish it would rename the
// generated V2 entity type away from the default ZDPR_Q_PROD_PERFType.
@AbapCatalog.sqlViewName: 'ZDPRQPRODPERF'
@AbapCatalog.compiler.compareFilter: true
// EOC By Arnav on 16/09/26
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DPR Production Performance (Excel tab 3)'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

/* ── The Production Performance table of the DPR Excel (tab 3) ──────────────
 * One row per (Scope, Product group):
 *   Scope 'YTD'    -> Actual & BE Target per-day figures for the report window
 *   Scope 'ANNUAL' -> BE Target per-day figure only (Actual = 0, Excel "-")
 * Columns mirror the Excel blocks:
 *   Oil group  : BOPD        Gas group : MMSCMD       Boepd : Total (O+OEG)
 * AchievementPct = YTD "% Achv w.r.t. BE Target" (0 for ANNUAL rows, where the
 * Excel leaves the cell blank). Operates on <= 4 pre-aggregated rows - the
 * division cost is negligible; all scanning happened in ZDPR_P_PERF_AGG.
 * ─────────────────────────────────────────────────────────────────────────── */
// BOC By Arnav on 16/09/26
//@OData.entityType.name: 'DPRProdPerfQueryType'
//
//define view entity ZDPR_Q_PROD_PERF
@OData.publish: true

define view ZDPR_Q_PROD_PERF
// EOC By Arnav on 16/09/26
  with parameters
    P_DateFrom   : datum,
    P_DateTo     : datum,
    P_FiscalYear : gjahr

  as select from ZDPR_P_PERF_AGG(
                   P_DateFrom   : $parameters.P_DateFrom,
                   P_DateTo     : $parameters.P_DateTo,
                   P_FiscalYear : $parameters.P_FiscalYear )

{
  key ScopeType,
  key ProductGroup,

      @EndUserText.label: 'Scope'
      case ScopeType
        when 'YTD'    then 'YTD'
        when 'ANNUAL' then 'Annual'
        else               ScopeType
      end                                             as ScopeText,

      @EndUserText.label: 'Product Group'
      case ProductGroup
        when 'GAS' then 'Gas ( MMSCMD )'
        else            'Oil, LNG & Condensate ( BOPD )'
      end                                             as ProductGroupText,

// BOC By Arnav on 16/09/26
      /* One label per row: the Overview Page table card shows only three
         columns, so scope and product group share the first one */
      @EndUserText.label: 'Row'
      case ScopeType
        when 'YTD' then
          case ProductGroup
            when 'GAS' then 'YTD - Gas (MMSCMD)'
            else            'YTD - Oil, LNG & Cond. (BOPD)'
          end
        else
          case ProductGroup
            when 'GAS' then 'Annual - Gas (MMSCMD)'
            else            'Annual - Oil, LNG & Cond. (BOPD)'
          end
      end                                             as RowLabel,
// EOC By Arnav on 16/09/26

      /* ── Actual (per-day average over the window; 0 on ANNUAL rows) ──── */
      @EndUserText.label: 'Actual (BOPD / MMSCMD)'
// BOC By Arnav on 16/09/26
//      cast( case when Divisor > 0
//                 then SumActualQty / Divisor
//                 else cast( 0 as abap.dec( 23, 7 ) )
//            end as abap.dec( 23, 7 ) )                as ActualPerDay,
      cast( case when Divisor > 0
                 then division( SumActualQty, Divisor, 7 )
                 else cast( 0 as abap.dec( 23, 7 ) )
            end as abap.dec( 23, 7 ) )                as ActualPerDay,
// EOC By Arnav on 16/09/26

      @EndUserText.label: 'Actual Total (BOEPD)'
// BOC By Arnav on 16/09/26
//      cast( case when Divisor > 0
//                 then SumActualBoepd / Divisor
//                 else cast( 0 as abap.dec( 23, 3 ) )
//            end as abap.dec( 23, 3 ) )                as ActualBoepdPerDay,
      cast( case when Divisor > 0
                 then division( SumActualBoepd, Divisor, 3 )
                 else cast( 0 as abap.dec( 23, 3 ) )
            end as abap.dec( 23, 3 ) )                as ActualBoepdPerDay,
// EOC By Arnav on 16/09/26

      /* ── BE Target (per-day rate) ────────────────────────────────────── */
      @EndUserText.label: 'BE Target (BOPD / MMSCMD)'
// BOC By Arnav on 16/09/26
//      cast( case when Divisor > 0
//                 then SumTargetQty / Divisor
//                 else cast( 0 as abap.dec( 23, 7 ) )
//            end as abap.dec( 23, 7 ) )                as TargetPerDay,
      cast( case when Divisor > 0
                 then division( SumTargetQty, Divisor, 7 )
                 else cast( 0 as abap.dec( 23, 7 ) )
            end as abap.dec( 23, 7 ) )                as TargetPerDay,
// EOC By Arnav on 16/09/26

      @EndUserText.label: 'BE Target Total (BOEPD)'
// BOC By Arnav on 16/09/26
//      cast( case when Divisor > 0
//                 then SumTargetBoepd / Divisor
//                 else cast( 0 as abap.dec( 23, 3 ) )
//            end as abap.dec( 23, 3 ) )                as TargetBoepdPerDay,
      cast( case when Divisor > 0
                 then division( SumTargetBoepd, Divisor, 3 )
                 else cast( 0 as abap.dec( 23, 3 ) )
            end as abap.dec( 23, 3 ) )                as TargetBoepdPerDay,
// EOC By Arnav on 16/09/26

      /* ── % Achievement w.r.t. BE Target (YTD only; 0 -> blank/Annual) ── */
      @EndUserText.label: '% Achv w.r.t. BE Target'
// BOC By Arnav on 16/09/26
//      cast( case when ScopeType = 'YTD' and SumTargetBoepd > 0
//                 then SumActualBoepd * cast( 100 as abap.dec( 4, 0 ) )
//                      / SumTargetBoepd
//                 else cast( 0 as abap.dec( 10, 2 ) )
//            end as abap.dec( 10, 2 ) )                as AchievementPct,
      cast( case when ScopeType = 'YTD' and SumTargetBoepd > 0
                 then division( SumActualBoepd * cast( 100 as abap.dec( 4, 0 ) ),
                                SumTargetBoepd, 2 )
                 else cast( 0 as abap.dec( 10, 2 ) )
            end as abap.dec( 10, 2 ) )                as AchievementPct,
// EOC By Arnav on 16/09/26

      /* UI criticality for the % cell: 3=green >=100, 2=amber >=90, 1=red,
         0=neutral (ANNUAL rows - no actual, Excel shows "-") */
      @EndUserText.label: 'Achievement Criticality'
      cast( case
              when ScopeType <> 'YTD' or SumTargetBoepd <= 0        then 0
              when SumActualBoepd >= SumTargetBoepd                 then 3
              when SumActualBoepd * cast( 100 as abap.dec( 4, 0 ) )
                   >= SumTargetBoepd * cast( 90 as abap.dec( 4, 0 ) ) then 2
              else 1
            end as abap.int1 )                        as AchievementCriticality
}
