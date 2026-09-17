@AbapCatalog.sqlViewName: 'ZDPRQDASHFILTER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DPR Dashboard - global filter entity'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

/* ── Global filter entity of the DPR Overview Page ───────────────────────────
 * The Overview Page has one filter bar for the whole page, and that filter
 * bar offers ONLY the parameters and elements of its global filter entity.
 * Until now that entity was ZDPR_Q_PROD_PERF, which is pre-aggregated and has
 * no dimension columns, so the bar showed the three parameters and nothing
 * else. This view carries the same three parameters (the cards receive them
 * by NAME, so the names must stay P_DateFrom / P_DateTo / P_FiscalYear) plus
 * the dimensions a user can filter on. A filter-bar value reaches a card only
 * when the card's own query has an element of the same name:
 *   Asset        -> cards 1, 4, 5, 6      BusinessUnit -> cards 1, 5
 *   Block        -> cards 4, 6            Product      -> cards 1, 4, 5, 6
 * Cards 2 and 3 (ZDPR_Q_PROD_PERF) ignore them: the performance table is a
 * company-wide total by design.
 * The Overview Page never reads rows from this entity (only $metadata), so
 * the source is the small profile table, not the daily production table.
 * Business unit derivation copied from ZDPR_P_TARGET_DAY (asset prefix).
 * Classic view: @OData.publish generates the V2 service ZDPR_Q_DASH_FILTER_CDS
 * (parameter set ZDPR_Q_DASH_FILTER, result set ZDPR_Q_DASH_FILTERSet).
 * Created by Arnav on 17/09/26.
 * ─────────────────────────────────────────────────────────────────────────── */
@OData.publish: true

define view ZDPR_Q_DASH_FILTER
  with parameters
    P_DateFrom   : datum,
    P_DateTo     : datum,
    P_FiscalYear : gjahr

  as select distinct from zpra_c_prd_prof as Prof

  left outer join zoiu_pr_dn as AssetTxt
    on Prof.asset = AssetTxt.dn_no

{
      @EndUserText.label: 'Asset'
      @ObjectModel.text.element: ['AssetDescription']
      @UI.selectionField: [{ position: 10 }]
  key Prof.asset                                        as Asset,

      @EndUserText.label: 'Block'
      @UI.selectionField: [{ position: 30 }]
  key Prof.block                                        as Block,

      @EndUserText.label: 'Product'
      @ObjectModel.text.element: ['ProductDescription']
      @UI.selectionField: [{ position: 40 }]
  key Prof.product                                      as Product,

      @EndUserText.label: 'Business Unit'
      @UI.selectionField: [{ position: 20 }]
      case substring( Prof.asset, 1, 3 )
        when 'RUS' then 'BU-RUSSIA'
        when 'BRA' then 'BU-LAC'
        when 'COL' then 'BU-LAC'
        when 'VEN' then 'BU-LAC'
        when 'MMR' then 'BU-ASIA PACIFIC'
        when 'VNM' then 'BU-ASIA PACIFIC'
        when 'AZE' then 'BU-MENA CIS'
        when 'SSU' then 'BU-MENA CIS'
        when 'SUD' then 'BU-MENA CIS'
        when 'UAE' then 'BU-MENA CIS'
        else            'OTHER'
      end                                               as BusinessUnit,

      /* rtrim() drops the OIUNM conversion exit, which OData cannot expose
         (same technique as ZDPR_C_PROD_CUBE) */
      @EndUserText.label: 'Asset Description'
      rtrim( AssetTxt.dn_de, ' ' )                      as AssetDescription,

      @EndUserText.label: 'Product Description'
      case Prof.product
        when '722000001' then 'Oil'
        when '722000003' then 'Condensate'
        when '722000004' then 'Gas'
        when '722000005' then 'LNG'
        else                  'Other'
      end                                               as ProductDescription,

      /* the parameters, echoed so the view references them; hidden from the
         service so they do not appear as extra filter fields */
      @Consumption.hidden: true
      $parameters.P_DateFrom                            as DateFrom,

      @Consumption.hidden: true
      $parameters.P_DateTo                              as DateTo,

      @Consumption.hidden: true
      $parameters.P_FiscalYear                          as FiscalYear
}
