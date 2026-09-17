@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DPR As-of calendar (windows + divisors)'
@Metadata.ignorePropagatedAnnotations: true

/* ── Calendar helper for the DPR summary cube ────────────────────────────────
 * One row for the as-of date (the LAST production date included in the
 * report; the classic DPR of 01-JAN-2026 shows data up to 31.12.2025, so
 * P_AsOf = 31.12.2025). Every window and divisor of the Excel summary block
 * is computed here ONCE, as plain columns, so the row views only join on
 * date ranges and divide by fields - no date functions in WHERE clauses.
 *   MTD          : MonthStart .. AsOf          / DaysMtd
 *   MTD LY       : MonthStartLY .. AsOfLY      / DaysMtd
 *   Monthly      : PrevMonthStart .. PrevMonthEnd / DaysPrevMonth
 *   YTD          : FyStart .. AsOf             / DaysYtd
 *   YTD LY       : FyStartLY .. AsOfLY         / DaysYtd
 *   Annual LY    : FyStartLY .. FyEndLY        / DaysFyLY
 *   Asking rate  : (annual target - YTD actual) / DaysLeft
 * Source is the date spine so the row exists only when production data
 * exists for the as-of date (true for every DPR date).
 * ASSUMPTION: fiscal year April..March, as everywhere in this package.
 * Created by Arnav on 17/09/26.
 * ─────────────────────────────────────────────────────────────────────────── */
define view entity ZDPR_P_ASOF
  with parameters
    P_AsOf : datum

  as select from ZDPR_P_DATE_SPINE as Cal

{
  key Cal.ProductionDate                                        as AsOf,

      /* current fiscal year and the previous one */
      cast( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 )
            as abap.numc( 4 ) )                                 as FiscalYear,

      cast( substring( dats_add_months( Cal.ProductionDate, -15, 'INITIAL' ), 1, 4 )
            as abap.numc( 4 ) )                                 as FiscalYearLY,

      /* month of the as-of date */
      cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
            as abap.dats )                                      as MonthStart,

      /* same month, previous year */
      dats_add_months(
        cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
              as abap.dats ), -12, 'INITIAL' )                  as MonthStartLY,

      dats_add_months( Cal.ProductionDate, -12, 'INITIAL' )     as AsOfLY,

      /* previous month (the "Monthly Actual" row) */
      dats_add_months(
        cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
              as abap.dats ), -1, 'INITIAL' )                   as PrevMonthStart,

      dats_add_days(
        cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
              as abap.dats ), -1, 'INITIAL' )                   as PrevMonthEnd,

      /* 1 April of the current fiscal year */
      cast( concat( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 ), '0401' )
            as abap.dats )                                      as FyStart,

      /* 31 March of the current fiscal year */
      dats_add_days(
        dats_add_months(
          cast( concat( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 ), '0401' )
                as abap.dats ), 12, 'INITIAL' ), -1, 'INITIAL' ) as FyEnd,

      /* previous fiscal year */
      cast( concat( substring( dats_add_months( Cal.ProductionDate, -15, 'INITIAL' ), 1, 4 ), '0401' )
            as abap.dats )                                      as FyStartLY,

      dats_add_days(
        cast( concat( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 ), '0401' )
              as abap.dats ), -1, 'INITIAL' )                   as FyEndLY,

      /* ── divisors (days) ─────────────────────────────────────────────── */
      cast( dats_days_between(
              cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
                    as abap.dats ),
              Cal.ProductionDate ) + 1 as abap.dec( 5, 0 ) )   as DaysMtd,

      cast( dats_days_between(
              cast( concat( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 ), '0401' )
                    as abap.dats ),
              Cal.ProductionDate ) + 1 as abap.dec( 5, 0 ) )   as DaysYtd,

      cast( dats_days_between(
              dats_add_months(
                cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
                      as abap.dats ), -1, 'INITIAL' ),
              dats_add_days(
                cast( concat( substring( cast( Cal.ProductionDate as abap.char( 8 ) ), 1, 6 ), '01' )
                      as abap.dats ), -1, 'INITIAL' ) ) + 1
            as abap.dec( 5, 0 ) )                               as DaysPrevMonth,

      cast( dats_days_between(
              cast( concat( substring( dats_add_months( Cal.ProductionDate, -15, 'INITIAL' ), 1, 4 ), '0401' )
                    as abap.dats ),
              dats_add_days(
                cast( concat( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 ), '0401' )
                      as abap.dats ), -1, 'INITIAL' ) ) + 1
            as abap.dec( 5, 0 ) )                               as DaysFyLY,

      /* days from the as-of date to 31 March (asking-rate divisor) */
      cast( dats_days_between(
              Cal.ProductionDate,
              dats_add_days(
                dats_add_months(
                  cast( concat( substring( dats_add_months( Cal.ProductionDate, -3, 'INITIAL' ), 1, 4 ), '0401' )
                        as abap.dats ), 12, 'INITIAL' ), -1, 'INITIAL' ) )
            as abap.dec( 5, 0 ) )                               as DaysLeft
}
where Cal.ProductionDate = $parameters.P_AsOf
