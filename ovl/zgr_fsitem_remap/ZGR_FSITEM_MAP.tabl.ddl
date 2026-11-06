//----------------------------------------------------------------------
// Object    : ZGR_FSITEM_MAP (transparent table, ADT DDL source)
// Title     : Group Reporting - FS item remap per consolidation unit
// Project   : OVL                                  Module: FI-CS (Group Reporting)
// Related FS: chat request 06/11/2026, no FSD - see ASSUMPTIONS_AND_QUERIES.md
// Author    : Arnav Johri                          Date: 06.11.2026
// Transport : <TR>
//----------------------------------------------------------------------
// DESCRIPTION
//   User-maintained mapping (SM30): for a consolidation unit and an FS
//   item of ACDOCU, the FS item that is to be reported instead. Read by
//   ZI_GR_FSREMAP_CUBE (left outer join on RBUNIT + RITEM); a row with
//   an empty RITEM_NEW counts as "no mapping".
//   Paste fallback for the abapGit ZIP (src/zgr_fsitem_map.tabl.xml):
//   the two Z domains and three Z data elements come first - TS 4.1.
//
// ASSUMPTION: one consolidation dimension and one consolidation chart
//   of accounts in use, so neither is part of the key (query 2).
// ASSUMPTION: the mapping is not version-, year- or period-dependent
//   (query 3).
// ASSUMPTION: consolidation unit is CHAR 18 and FS item CHAR 10, the
//   ACDOCU lengths; the Z data elements carry those lengths (query 4).
//
// CHANGE HISTORY
//   06.11.2026  Arnav Johri  <TR>  Initial development
//----------------------------------------------------------------------
// Technical settings (separate tab in ADT / SE11, not in this source):
//   data class APPL0, size category 0, buffering not allowed,
//   log data changes off. Delivery class A, maintenance allowed.
//----------------------------------------------------------------------
@EndUserText.label : 'Group Reporting: FS item remap per consolidation unit'
@AbapCatalog.enhancementCategory : #EXTENSIBLE_CHARACTER
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table zgr_fsitem_map {
  key mandt     : mandt not null;
  key rbunit    : zgr_rbunit not null;
  key ritem     : zgr_ritem not null;
  ritem_new     : zgr_ritem_new;
}
