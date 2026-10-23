# ZFORECAST Paints — technical handover for the next ABAPer

Astral Limited / Project UDAY (KPMG) · Paints division, WRICEF ID-2B · PP / SD
Written 22.10.2026, updated 23.10.2026, by Arnav Johri. Development system only. Transport **DEVK930479**
(UDAYABAP03, "UDAY: PP: 2B: Forcast Paints"), not released. Repository
`arnavjohri/Diligent`, folder `kpmg/zpp_forecast_paints/`.

Transaction codes are **not** part of this handover: the programs are run from SE38 until
SE93 is done. Everything below is named by program, class and table.

---

## 1. What Paints is, in one paragraph

The Paints forecast is the Adhesive forecast (`kpmg/zpp_forecast_v2/`, built August to
September 2026) with a different list layout and three extra tables. The arithmetic, the
sales-history reads, the business-forecast comparison, the quarterly month split, the eight
uploads, the forecast number and the final report are the Adhesive ones and run in the
Adhesive objects unchanged. Paints adds, on top of the engine's output, the columns the
Paints template draws — plant name, brand, pack size, dealer price (DPL), quantity per
carton, gross weight, volume in kilolitres and value in crores per month, tonnage on gross
weight — and saves the list, column for column, into three Paints tables while the engine
still saves the shared Adhesive-shaped row. One Adhesive object was edited: the upload
program, which gained a Brand upload and a four-value category indicator.

The functional spec is `fs/Forecast_Template-Paints_1.xlsx` (received 19.10.2026, no version
inside). **Sheet1 was taken as the authority** where the sheets disagree. Twenty-eight defects
in the FS and seventeen open queries are logged in
`docs/ZFORECAST_Paints_Assumptions_and_Queries.docx`; none has been answered. The build
stands on the assumptions in section 11.

---

## 2. Timeline and the decisions behind it

| Date | What | Why |
|----------------------|------------------------------------------------|------------------------------|
| 19/10 AM | FS read; Assumptions and Queries v1 and v2 | v2 applied the rule "no Adhesive program or class is edited" |
| 19/10 PM | Build: `ZPPT_BRAND`, `ZCL_PP_FCST_PNT`, `ZPP_FORECAST_PAINTS`, `ZPP_FORECAST_PAINTS_UPL` (category + brand only); ZIP imported in DEV | first hand-written abapGit ZIP that pulled on this landscape |
| 19/10 PM | `ZPP_FORECAST_PAINTS_UPL` extended to all nine uploads | Arnav: Paints users should not need two upload transactions |
| 19/10 PM | Paints forecast tables `ZPPT_PNT_FCST_YR/QT/MN` (Adhesive shape + Paints columns), `SAVE_PAINTS` | Arnav: the Paints structure differs, save into own tables |
| 22/10 | Brand upload and indicator moved **into the Adhesive `ZPP_FORECAST_UPLOAD`** with markers; `ZPP_FORECAST_PAINTS_UPL` withdrawn; tables reshaped to the displayed list; two delta ZIPs | Arnav: one upload program, tables as the ALV |
| 22/10 | Imported and activated; SE41 `PF_STATUS` created; TR DEVK930479 | |
| 22/10 | Functional test pack issued (`docs/ZFORECAST_Paints_Test_Handover.docx`) | test not started |
| 22/10 PM | Sales organisation 4000 hardcoded in `ZCL_PP_FCST_PNT` (`GC_VKORG`); material groups re-read from that view; config read, `READ_CARTONS`, `ADD_MSG` removed; class-only delta ZIP | Arnav: "we want hard coded 4000 as per the FS" |
| 23/10 | `HANDOVER.md` written for the next ABAPer and their Claude; stale references to the config row cleaned out of every document | handover |

---

## 3. Object inventory

### 3.1 New, package `ZPP_FORECAST_PAINTS`

| Object | Type | Lines | Purpose |
|--------|--------------------------------------------------|--------------------|----------------------|
| `ZDO_BRAND` | Domain | | CHAR 40 |
| `ZDO_FCST_KL` | Domain | | DEC 13,3, signed — pack size, qty per carton, volume in KL |
| `ZDO_FCST_CR` | Domain | | DEC 13,4, signed — value in crores |
| `ZDE_BRAND` | Data element | | "Brand", on `ZDO_BRAND` |
| `ZDE_PACK_SIZE` | Data element | | "Pack Size", on `ZDO_FCST_KL` |
| `ZDE_QTY_CARTON` | Data element | | "Qty per Carton", on `ZDO_FCST_KL` |
| `ZDE_FCST_KL` | Data element | | "Volume in KL", on `ZDO_FCST_KL` |
| `ZDE_FCST_CR` | Data element | | "Value in Crores", on `ZDO_FCST_CR` |
| `ZPPT_BRAND` | Table | | Brand per plant and material, §4.1 |
| `ZPPT_PNT_FCST_YR` | Table | 73 fields | Paints annual forecast = the annual list, §4.2 |
| `ZPPT_PNT_FCST_QT` | Table | 58 fields | Paints quarterly forecast = the quarterly list, §4.3 |
| `ZPPT_PNT_FCST_MN` | Table | 45 fields | Paints monthly forecast = the monthly list, §4.4 |
| `ZCL_PP_FCST_PNT` | Class | 846 | Paints columns on the engine's row (`ENRICH`), save into the Paints tables (`SAVE_PAINTS`), §5 |
| `ZPP_FORECAST_PAINTS` | Report | 1,581 | Generation, three modes, Paints list, save, §6 |

### 3.2 Changed, package `ZPP_FORECAST` (Adhesive)

| Object | Change | Markers |
|----------------------|------------------------------------------------|------------------------------|
| `ZPP_FORECAST_UPLOAD` | Ninth upload type Brand; category indicator MTS / MTO / DIS / TIN; selection text `P_BRD` | `By Arnav on 22/10/26`, §7 |

### 3.3 Shared, untouched, called or read

`ZCL_PP_FCST` (engine, 2,309 lines), `ZCL_PP_FCST_UTIL` (393), `ZPP_FORECAST` (Adhesive
generation, the template this program was copied from), `ZPP_FORECAST_REPORT` (final report,
reads the shared tables, serves Paints by plant selection), tables `ZPPT_PROD_CAT`,
`ZPPT_MAT_TRACK`, `ZPPT_MAT_EXCL`, `ZPPT_SLS_HIST`, `ZPPT_FCST_CFG`, `ZPPT_FCST_YR`,
`ZPPT_FCST_QT`, `ZPPT_FCST_MN`, number range `ZPPFCST`, authorisation object `ZPP_FCST`,
message class `ZPP_FCST` (001–026, nothing added), application log object `ZPP_FCST` /
subobject `GENERATE`, TVARVC `ZPP_FORECAST_MTART` and `ZPP_FCST_LEGACY`.

### 3.4 Withdrawn

`ZPP_FORECAST_PAINTS_UPL` — the separate Paints upload of 19/10, imported in DEV that day,
superseded on 22/10 by the change to `ZPP_FORECAST_UPLOAD`. Still in the system; delete it
in SE38 when convenient. Its source is in git history
(`git log -- kpmg/zpp_forecast_paints/src/zpp_forecast_paints_upl.prog.abap`).

### 3.5 Manual objects

- SE41 GUI status `PF_STATUS` of `ZPP_FORECAST_PAINTS`: **created** on 22/10 — SALV_STANDARD
  plus `ZSAVE`, `ZSELALL`, `ZDESEL`, `ZEXCEL` in the application toolbar. Travels in the
  transport with the program; never in a ZIP.
- SM30 `ZPPV_FCST_CFG` rows: not needed for Paints since sales org 4000 is hardcoded.
- SM30 views on `ZPPT_BRAND` and the three Paints tables: **not generated** (optional).
- Domain `ZDO_MTS_MTO` fixed values `DIS`, `TIN`: **not added** (optional; the upload writes
  the codes regardless, SM30 on the category table would refuse them).

---

## 4. The DDIC in detail

All four tables: delivery class A, data class APPL0, size category 0, not buffered, client
dependent. XML shapes copied from the Adhesive table XML's field blocks (element order
`FIELDNAME, KEYFLAG, ROLLNAME, ADMINFIELD, NOTNULL, COMPTYPE, [REFTABLE, REFFIELD]`), the
shape that imports on this landscape. Generated by `tools/mktables.py`; re-run it after any
field change rather than editing the XML by hand.

### 4.1 `ZPPT_BRAND`

| Field | Key | Data element |
|----------------------|------------------------------------------------|------------------------------|
| MANDT, WERKS, MATNR | key | MANDT, WERKS_D, MATNR |
| BRAND | | ZDE_BRAND |
| ERNAM, ERDAT, AENAM, AEDAT | | standard |

Loaded by `ZPP_FORECAST_UPLOAD` type BRD; read by `ZCL_PP_FCST_PNT=>READ_BRANDS`.

### 4.2 `ZPPT_PNT_FCST_YR` — the annual list

Key `MANDT WERKS MATNR FYEAR` (`ZDE_FYEAR`, "2026-2027"). Then, in list order:

| Block | Fields | Type |
|----------------------|------------------------------------------------|------------------------------|
| Number | FCST_NO | ZDE_FCST_NO |
| Lead | NAME1 · BRAND · MAKTX · MTS_MTO · MVGR1_TXT · MVGR2_TXT · MVGR5_TXT · MATKL · PACK_SIZE · PACK_UNIT · WAERS · PRICE · QTY_CARTON · MEINS | NAME1 · ZDE_BRAND · MAKTX · ZDE_MTS_MTO · BEZEI20 ×3 · MATKL · ZDE_PACK_SIZE · MEINH · WAERS · ZDE_FCST_PRICE (ref WAERS) · ZDE_QTY_CARTON · MEINS |
| Forecast | M01_FCST … M12_FCST | ZDE_FCST_QTY, ref MEINS |
| Volume | M01_KL … M12_KL | ZDE_FCST_KL |
| Value | M01_CR … M12_CR | ZDE_FCST_CR |
| Weight | GEWEI · BRGEW · M01_TON … M12_TON | GEWEI · BRGEW (ref GEWEI) · ZDE_FCST_QTY (ref MEINS) |
| Audit | ERNAM ERDAT AENAM AEDAT | |

`MEINS`, `WAERS`, `GEWEI` are not list columns; they are the unit references the QUAN, CURR
and weight fields need. Material groups are stored as the descriptions the list shows.

### 4.3 `ZPPT_PNT_FCST_QT` — the quarterly list

Key `MANDT WERKS MATNR GJAHR QUARTER` (GJAHR = the year the financial year starts in,
QUARTER `ZDE_QUARTER` 1–4). Then FCST_NO, the lead block as above, then:

| Block | Fields |
|----------------------------|------------------------------------------------------------------------|
| Comparison | M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY |
| Month 1 of the quarter | M4_FCST BUS_FCST_ADD1 M4_FCST_FINAL M4_KL M4_CR M4_TON |
| Month 2 | M5_FCST BUS_FCST_ADD2 M5_FCST_FINAL M5_KL M5_CR M5_TON |
| Month 3 | M6_FCST BUS_FCST_ADD3 M6_FCST_FINAL M6_KL M6_CR M6_TON |
| Weight, audit | GEWEI BRGEW · ERNAM ERDAT AENAM AEDAT |

`M4 … M6` are positional names inherited from the engine: they hold the first, second and
third month of whichever quarter is run, not July to September.

### 4.4 `ZPPT_PNT_FCST_MN` — the monthly list

Key `MANDT WERKS MATNR GJAHR PERIOD` (PERIOD `POPER` 001–012, 001 = April). Then FCST_NO,
the lead block, the comparison block as in 4.3 (with L3M_TOT, not L3M_AVG), then
`BUS_FCST_ADD TOTAL_QTY M4_KL M4_CR M4_TON`, `GEWEI BRGEW`, audit. `TOTAL_QTY` is the
engine's final + additional + MSL and is the figure KL, crores and tonnage are computed on.

### 4.5 What is deliberately not in the Paints tables

Last year's twelve history months, LY_TOTAL, FCST_TOTAL (annual); MVGR3, MVGR4 and their
texts; NTGEW; the engine's value columns Mn_VAL, Mn_TON_VAL, TOTAL_VAL; MSL; REASON. They
are not on the Paints list and stay in the shared tables.

---

## 5. `ZCL_PP_FCST_PNT`

Public, final, create public. No instance attributes; every method works on what it is given.

### 5.1 Public section

```
CONSTANTS gc_msgid         TYPE symsgid VALUE 'ZPP_FCST'.
CONSTANTS gc_vkorg         TYPE vkorg   VALUE '4000'.      " FS row 91, hardcoded 22/10/26
TYPES ty_kl TYPE p LENGTH 13 DECIMALS 3.
TYPES ty_cr TYPE p LENGTH 13 DECIMALS 4.
TYPES: BEGIN OF ty_alv.
         INCLUDE TYPE zcl_pp_fcst=>ty_alv.                " the engine's row, first
TYPES:   name1, brand, pack_size, pack_unit, qty_carton, brgew,
         m01_kl..m12_kl, m01_cr..m12_cr, m4_kl..m6_kl, m4_cr..m6_cr,
       END OF ty_alv,
       tt_alv TYPE STANDARD TABLE OF ty_alv WITH DEFAULT KEY.
METHODS enrich      IMPORTING iv_mode TYPE char1 CHANGING ct_alv TYPE tt_alv ct_msg TYPE bapiret2_t.
METHODS save_paints IMPORTING iv_mode TYPE char1 CHANGING ct_alv TYPE tt_alv ct_msg TYPE bapiret2_t.
```

`ty_alv` includes the engine's `TY_ALV` as its first part, so `MOVE-CORRESPONDING` maps the
engine's output in and `CORRESPONDING zcl_pp_fcst=>ty_alv( )` maps a row back for the
engine's SAVE. `iv_mode` is `zcl_pp_fcst=>gc_mode-annual / quarterly / monthly` ('A', 'Q',
'M').

### 5.2 `ENRICH` — what it reads and computes

1. Collects the distinct plants, materials and plant+material pairs of `ct_alv`.
2. One read each, all `FOR ALL ENTRIES` on the de-duplicated drivers, each guarded by
   `IS NOT INITIAL`:

| Private method | Table | Selection | Result |
|--------|--------------------------------------------------|--------------------|----------------------|
| `READ_NAMES` | `T001W` | plants | `NAME1` |
| `READ_BRANDS` | `ZPPT_BRAND` | plant + material | `BRAND` |
| `READ_MARA` | `MARA` | materials | `MEINS`, `BRGEW`, `GEWEI` |
| `READ_PACK_SIZES` | `MARM` | materials, `MEINH IN (L, ML, KG, G)` | first unit in that preference order that is not the material's base unit; pack = `UMREN / UMREZ`; ML and G divided by 1000. Unit codes assumed as internal MSEHI values — **query M5**. The preference list is a small internal table at the top of the method |
| `READ_SALES_VIEW` | `MVKE` | materials, `VKORG = '4000'` (`GC_VKORG`, hardcoded as FS row 91 states, Arnav 22/10/26) | `MVGR1..5` and `AUMNG`, one row per material (first distribution channel). The groups **overwrite** what the engine read with its own sales org; `AUMNG` is taken only where `MVGR1` is filled — **query Q2** |
| `READ_GROUP_TEXTS` | `TVM1T`..`TVM5T` | logon language, whole tables | descriptions for groups 1..5 |
| `READ_PRICES` | `A923` → `KONP` | materials, annual mode only | latest `DATAB` per material, lowest `KOPOS` of that `KNUMH`, `KBETR`. Same rule as the engine's private `READ_PRICES`; re-implemented because the engine is not changed — **query Q1** |

3. Per row: `NAME1`, `BRAND`, `BRGEW`, `PACK_SIZE` / `PACK_UNIT`, `MVGR1..5` with texts
   (cleared first, then filled from the 4000 view), `QTY_CARTON`, and for annual `PRICE`
   (quarterly and monthly already carry it from the engine).
4. Per forecast month, on the quantity the engine prices:

| Mode | Quantity field | Written |
|----------------------|------------------------------------------------|------------------------------|
| Annual | `Mnn_FCST` (nn = 01..12, `lv_p` is NUMC2 so the name keeps the zero) | `Mnn_TON` = qty × BRGEW ÷ 1000 · `Mnn_KL` = qty × PACK_SIZE ÷ 1000 · `Mnn_CR` = PRICE × qty ÷ 1,00,00,000 |
| Quarterly | `Mn_FCST_FINAL` (n = 4, 5, 6; `lv_m` is I so the name has no zero) | `Mn_TON`, `Mn_KL`, `Mn_CR` the same way |
| Monthly | `TOTAL_QTY` | `M4_TON`, `M4_KL`, `M4_CR` |

`Mnn_TON` **overwrites** the engine's net-weight tonnage; this is the only engine field
`ENRICH` changes, and it flows into the shared table on save for Paints rows.

### 5.3 `SAVE_PAINTS`

Called by the program **after** `ZCL_PP_FCST=>SAVE`. For every row with `MARK = X`: clears
`MARK`; skips the row if `FCST_NO` is blank; builds the table row with
`CORRESPONDING zppt_pnt_fcst_xx( <ls> )`; reads the existing row's `ERNAM`/`ERDAT` so
created-by is kept; sets `AENAM`/`AEDAT`; `MODIFY` of the mode's table. One `COMMIT WORK AND
WAIT` if anything was written. A refused row gets `LIGHT = '1'` and the message "Saved under
forecast n, Paints table not updated"; a summary E message is appended to `ct_msg`.

`ENRICH` keeps its `ct_msg` parameter for the caller's run log but writes nothing to it
since 22/10/26.

---

## 6. `ZPP_FORECAST_PAINTS`

A copy of `ZPP_FORECAST` (Adhesive, 23/09/26 state) with the Paints row type, the enrichment
call, the Sheet1 column lists and the second save. If `ZPP_FORECAST` changes in a way that
should reach Paints, port it here by hand.

### 6.1 Globals and switches

| Name | Value | Meaning |
|----------------------|------------------------------------------------|------------------------------|
| `gv_container` | `abap_false` | full screen with GUI status `PF_STATUS`. `abap_true` = SALV in `cl_gui_container=>default_screen` with `ADD_FUNCTION` buttons, no status needed, toolbar one row lower. DATA, not CONSTANTS, so both branches compile |
| `gc_status` | `'PF_STATUS'` | the SE41 status of this program |
| `gc_tv_legacy` | `'ZPP_FCST_LEGACY'` | TVARVC parameter; blank = Legacy checkbox not drawn (Sheet1 draws none) |
| `g_legc_on` | | read once in INITIALIZATION by `FORM legacy_switch`; re-asserted at START-OF-SELECTION because a variant can carry the checkbox |
| `gt_eng` | `zcl_pp_fcst=>tt_alv` | what the engine returned |
| `gt_alv` | `zcl_pp_fcst_pnt=>tt_alv` | what is displayed and saved |
| `gt_show`, `gt_opt` | `tt_fname` (local table of `LVC_FNAME`; `LVC_T_FNAME` is not in every release) | drawn columns in order; hidden-but-offered columns |
| `go_fcst`, `go_pnt`, `go_alv` | | engine, Paints class, SALV |
| `g_mode`, `g_quart` | | 'A' / 'Q' / 'M'; the quarter being planned (from `p_quart` or the first date of `s_datum`) |

### 6.2 Selection screen

Block `b0`: `p_ann` (default) / `p_qtr` / `p_mth`, radio group `MOD`, user command `MD`.
Block `b1`: `s_werks`, `s_matnr` (both `FOR marc-…`), `p_fyear` (`ZDE_FYEAR`, defaulted to the
financial year containing today), `p_quart` (`MODIF ID QTR`), `p_perio` (`POPER`, `MODIF ID
MTH`), `s_datum` (`NO-EXTENSION`, `MODIF ID DAT`). Block `b2`: `p_tonn`, `p_legc` (`MODIF ID
LGC`). Plant and year are not OBLIGATORY on purpose: a mandatory field is checked on the mode
radio click and looks like the screen refusing to switch; `AT SELECTION-SCREEN` checks them
by hand and skips every check when `sscrfields-ucomm = 'MD'`. Checks: 001 no plant, 002 year
format (`zcl_pp_fcst_util=>split_fyear`), 003 quarter and date both or neither, 004 month
missing, 010 display authority per plant (activity 03), 011 legacy authority. Value helps:
`f4_fyear` (five years back, five forward), `f4_quart` (months behind each quarter),
`f4_perio` (period, month name, year).

### 6.3 Flow

```
START-OF-SELECTION
  FORM generate      engine generate_<mode>( s_werks[] s_matnr[] p_fyear [g_quart|p_perio]
                                             p_legc p_tonn ) -> gt_eng, gt_msg
                     gt_eng -> gt_alv row by row (MOVE-CORRESPONDING)
                     go_pnt->enrich( g_mode, gt_alv, gt_msg )
  FORM save_log      SLG1: object ZPP_FCST, subobject GENERATE,
                     external number "PAINTS <mode> <fyear> <user>"; BAL_* functions;
                     absent log object -> silently no log
  (no rows -> message 008)
  FORM display       cl_salv_table=>factory (container or full screen per gv_container)
                     set_all functions; layout key report = sy-repid, handle = g_mode,
                     restrict_none, default on -> Save/Select layout work per mode
                     save allowed (activity 01 on every plant) -> set_screen_status PF_STATUS,
                     c_functions_all; else SALV's own status, no buttons
                     selection mode row_column; handler lcl_handler=>on_added_function
                     FORM visible_columns -> gt_show, gt_opt
                     FORM setup_columns   -> technical / hidden / positions / headings
                     list header "Paints <Annual|Quarterly|Monthly> Forecast - <fyear>"
                     display; CX_SALV_OBJECT_NOT_FOUND (status missing) -> message in the
                     status bar, SALV_STANDARD used, display again
```

### 6.4 `lcl_handler`

| Method | Function code | Does |
|----------------------|------------------------------------------------|------------------------------|
| `on_added_function` | all | routes ZSAVE, ZSELALL, ZDESEL, ZEXCEL; BACK/EXIT/CANC → `LEAVE TO SCREEN 0`; anything else ignored |
| `save_selected` | ZSAVE | no selection → 017. Marks the selected rows; copies `gt_alv` row by row into an engine-typed table; `go_fcst->save( g_mode, lt_eng )`; copies `FCST_NO LIGHT STATUS MESSAGE` back by index and clears MARK on every row; sets MARK again on the selected rows the engine accepted (`LIGHT = '3'`); `go_pnt->save_paints( )`; `show_result`; refresh; `result_message` (one status line: "Save completed" or "…, n row(s) not saved") |
| `show_result` | | un-hides `FCST_NO` and `MESSAGE` at the end of the list; on a second Save keeps their slot (`sy-tabix`) instead of appending again |
| `select_all` | ZSELALL / ZDESEL | `set_selected_rows` with every index / an empty table |
| `export` | ZEXCEL | the drawn columns, in their order, as a tab file via `file_save_dialog` + `gui_download`, name `ZFORECAST_PAINTS_<mode>.txt` |

### 6.5 Column lists (`FORM visible_columns`)

Lead block on every mode: `WERKS NAME1 BRAND MATNR MAKTX MTS_MTO MVGR1_TXT MVGR2_TXT
MVGR5_TXT MATKL PACK_SIZE PRICE QTY_CARTON`. Optional on every mode: `PACK_UNIT MVGR3_TXT
MVGR4_TXT MEINS NTGEW GEWEI PROD_CAT LOAD_FCT` (the last two become drawn on quarterly and
monthly).

| Mode | Drawn after the lead block | Optional (Change Layout) |
|----------------------|------------------------------------------------|------------------------------|
| Annual | `M01_FCST…M12_FCST` · `M01_KL…M12_KL` · `M01_CR…M12_CR` · if `p_tonn`: `BRGEW`, `M01_TON…M12_TON` | `M01…M12`, `LY_TOTAL`, `FCST_TOTAL`, `BRGEW` when tonnage off |
| Quarterly | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY` · per month n=1..3, m=n+3: `Mm_FCST BUS_FCST_ADDn Mm_FCST_FINAL Mm_KL Mm_CR [Mm_TON]` · `[BRGEW]` | `TOTAL_VAL`, `BRGEW` when tonnage off |
| Monthly | `M4_LAST M5_LAST M6_LAST LY_QTR_TOT M1_CURR M2_CURR M3_CURR L3M_TOT MAX_QTY PROD_CAT LOAD_FCT FCST_QTY BUS_FCST FINAL_QTY BUS_FCST_ADD TOTAL_QTY M4_KL M4_CR [M4_TON BRGEW]` | `L3M_AVG MSL M4_VAL`, `BRGEW` when tonnage off |

`FCST_NO` and `MESSAGE` are optional on every mode and revealed by `show_result`. Everything
else in the structure is set technical (`setup_columns`: not in `pt_show`, not in `pt_opt` →
`set_technical`; in `pt_opt` → `set_visible( abap_false )`).

Headings (`FORM setup_columns`, `annual_headings`, `month_headings`): Sheet1 wording for the
lead block ("Mfg. Plant Code", "Mfg. Plant Name", "MTS / MTO / Dis Art / Tinting", "Pack
Size", "DPL", "Qty / Carton", "Gross Weight"); financial-calendar names for the month columns
via `zcl_pp_fcst_util=>period_to_yearmonth` / `quarter_periods` / `last_year_quarter` /
`last_three_months` — annual "Q2 Jul-26 Forecast Qty", "Q2 Jul-26 Volume in KL", "Q2 Jul-26
Value in Crores", "Jul-26 Tonnage"; quarterly and monthly "Jul-26", "Jul-26 additional",
"Jul-26 final forecast", "Jul-26 KL", "Jul-26 in Cr", "Jul-26 tonnage". `FORM txt` sets all
three SALV texts and the output length so the long text is the one drawn.

### 6.6 Release-specific constructs kept on purpose

`APPEND` instead of `VALUE #( ( 'X' ) )` for column lists (literal rows over an elementary
line type are refused on this release); `LOOP AT lo_cols->get( )` result put in a variable
first (a loop over a functional call iterates zero times here); `DATA` not `CONSTANTS` for
`gv_container`; NUMC2 vs I for building month field names (a NUMC keeps its leading zero).
`MEMORY.md` §4 in the repository root has the full list.

---

## 7. `ZPP_FORECAST_UPLOAD` — the 22/10/26 change

Applied by `tools/mkupl_adhesive.py` on the repository copy of 23/09/26 (no SE80 download of
this program has been supplied since 03/09/26; the abapGit stage diff before the pull was the
drift check). Every touch is marked `By Arnav on 22/10/26`; the originals are commented in
place.

| Where | What |
|----------------------------|------------------------------------------------------------------------|
| Header comment | "Nine upload types" |
| Selection screen block `b0`, after the `p_chgm` line | `p_brd` radio button, comment `c_brd`, pushbutton `b_brd` user command `TBRD`. **Single-line markers**: the block already sits inside the 31/08/26 BOC/EOC and markers are never nested |
| `INITIALIZATION` | `c_brd = 'Brand'`, `b_brd = 'Download Template'` |
| `AT SELECTION-SCREEN` | `WHEN 'TBRD'. PERFORM download_template USING 'BRD'.` |
| `START-OF-SELECTION` | `WHEN p_brd. PERFORM do_brand.` |
| `FORM current_type` | `WHEN p_brd. cv_type = 'BRD'.` |
| `FORM template_columns` | `WHEN 'BRD'`: file `ZFCST_Brand`, columns `ZPPT_BRAND-WERKS`, `-MATNR`, `-BRAND` (headings = DDIC labels, as every other type) |
| `FORM do_category` | the three lines of the MTS/MTO-only check commented; `PERFORM check_indicator USING lv_tmp CHANGING lv_mts lv_err` in their place |
| new `FORM check_indicator` | MTS, MTO, DIS, TIN stored as typed (upper case, condensed); `DIS ART` / `DISART` → DIS; `TINTING` → TIN; blank stays blank; anything else → "Indicator must be MTS, MTO, DIS, TIN or nothing" |
| new `FORM do_brand` | per row: `to_plant`, `to_material` (MATN1 conversion), `check_marc` (plant + material mandatory, in MARC, activity 02 authority), brand mandatory, read existing row, `stamp`, `MODIFY zppt_brand` unless test run, `log_ok` "Brand uploaded" |
| Text pool | `P_BRD` "Brand" |

Adhesive files that carry MTS or MTO behave exactly as before. The program now depends on
`ZPPT_BRAND`, which lives in package `ZPP_FORECAST_PAINTS`.

---

## 8. How the engine is used, and what it reads behind Paints' back

| Engine call | Parameters | What matters for Paints |
|----------------------|------------------------------------------------|------------------------------|
| `generate_annual` / `generate_quarterly` / `generate_monthly` | `ir_werks`, `ir_matnr`, `iv_fyear`, `iv_quarter` / `iv_period`, `iv_legacy`, `iv_tonnage` | reads billing (`VBRK`/`VBRP`, `FKIMG`, returns excluded, on `FKDAT`), `ZPPT_SLS_HIST` when legacy, `ZPPT_MAT_TRACK` (old codes absorbed into the successor; an old code typed alone is shown under its successor), `ZPPT_MAT_EXCL`, `ZPPT_PROD_CAT` (category, growth, indicator; missing category → growth 1.000 + message), TVARVC `ZPP_FORECAST_MTART` (FERT, HAWA; unmaintained → message 025, no filter), `ZPPT_FCST_CFG` (VKORG for its own `MVKE` reads, default 1100 — the Paints class re-reads the groups with 4000 and overwrites them), **`ZPPT_FCST_QT` / `ZPPT_FCST_MN` for BUS_FCST, BUS_FCST_ADD1-3 / BUS_FCST_ADD, MSL, PRICE, REASON** (read back so SAVE cannot blank them), `A923`/`KONP` for the price (quarterly, monthly) |
| `save` | `iv_mode`, `ct_alv` (engine row type) | activity 01 per plant; forecast number: `SHARED_NUMBER` looks in `ZPPT_FCST_YR` (by FYEAR) then `_QT` then `_MN` (by GJAHR), else `NUMBER_GET_NEXT` on `ZPPFCST`, interval = last two digits of the start year, fallback max+1 over the three tables; `MODIFY` of the shared table; per row `STATUS 'S'`, `LIGHT '3'`, `MESSAGE "Saved under forecast n"`, MARK cleared; messages 009 / 022 / 017 / 021 / 010 |

Consequences: the business forecast and change uploads must target the **shared** tables
(they do — ZFCST_UPL writes them); the forecast number is shared with Adhesive's sequence;
`ZPP_FORECAST_REPORT` sees Paints rows through the shared tables; nothing reads the Paints
tables yet. The authority checks in `ZCL_PP_FCST_UTIL` return true unconditionally since
07/09/26 (QAS testing) and must be restored before release — that restore reaches Paints too.

---

## 9. Shipping

| Archive | Repo / package | Contents |
|----------------------|------------------------------------------------|------------------------------|
| `ZPP_FORECAST_PAINTS.zip` | `ZPP_FORECAST_PAINTS` | the whole package from `src/`, 18 files |
| `ZPP_FORECAST_PAINTS_22-10-26_delta.zip` | `ZPP_FORECAST_PAINTS` | the 22/10 delta: 2 domains, 4 data elements, 3 tables, class, program |
| `../zpp_forecast_v2/ZPP_FORECAST_UPLOAD_22-10-26_delta.zip` | `ZPP_FORECAST` | the upload program only |

`ZABAPGIT_STANDALONE` → the offline repo of the package → Import ZIP → stage → Pull. One ZIP
per package. `.abapgit.xml` at the ZIP root (`STARTING_FOLDER /src/`, `FOLDER_LOGIC PREFIX`),
`src/package.devc.xml`, LF line endings, no BOM. `PROGDIR` order in the `.prog.xml` is
`NAME, VARCL, SUBC, FIXPT, UCCHECK`; `TPOOL` items `ID, KEY, ENTRY, LENGTH`. Re-zip from
`src/` after any change:

```
cd kpmg/zpp_forecast_paints && rm -f ZPP_FORECAST_PAINTS.zip && zip -X -D ZPP_FORECAST_PAINTS.zip .abapgit.xml src/*
```

Paste fallback, in this order: `ZDO_BRAND`, `ZDO_FCST_KL`, `ZDO_FCST_CR` → the five data
elements → `ZPPT_BRAND`, the three Paints tables → `ZCL_PP_FCST_PNT` (SE24, source based) →
`ZPP_FORECAST_PAINTS` (SE38, selection texts from the `.prog.xml` TPOOL) → the
`ZPP_FORECAST_UPLOAD` change (the 22/10 blocks, by FORM name).

Tools in `tools/`: `mktables.py` (the three table XMLs from the field lists in the script),
`mkupl_adhesive.py` (the upload change, every anchor asserted exactly once; refuses to run
twice), `abapcheck.py` (line length, block balance, PERFORM vs FORM parameter counts, method
declaration vs implementation — run it before every ZIP). None of this is a syntax check; the
first activation on a system is.

---

## 10. Repository map

```
kpmg/zpp_forecast_paints/
  HANDOVER.md               start here: everything in one file, written for the next ABAPer's Claude
  00_TECHNICAL_OBJECTS.md   inventory, import, requirement mapping, column lists, assumptions
  MANUAL_STEPS.md           pulls, SE41 status (done), SE93 (pending), SM30, optional steps
  KT_TCODES.md              one-page functional view
  NOTES.md / ISSUES.md      what it is, how it ships, gotchas / dated log of every change
  fs/                       the FS as received + text extract
  docs/                     Assumptions and Queries, TS, test pack, manual steps, KT, this file
  src/                      the 18 abapGit files
  tools/                    mktables.py, mkupl_adhesive.py, abapcheck.py
  ZPP_FORECAST_PAINTS.zip, ZPP_FORECAST_PAINTS_22-10-26_delta.zip
kpmg/zpp_forecast_v2/       the Adhesive objects, their ISSUES.md (22/10 entry) and the upload delta ZIP
MEMORY.md, CLAUDE.md        standing rules of the repository (markers, Open SQL, release constraints)
```

---

## 11. Assumptions the build stands on (greppable as `ASSUMPTION`)

| Where | Assumption | Query |
|----------------------|------------------------------------------------|------------------------------|
| `ZDO_BRAND` | brand is free text, 40 characters | M2 |
| `ZPP_FORECAST_UPLOAD` `CHECK_INDICATOR` | codes DIS, TIN; long forms accepted | M3 |
| `ZCL_PP_FCST_PNT` `GC_VKORG` | 4000 hardcoded as FS row 91 states; groups and carton read from that view | M4 |
| `READ_PACK_SIZES` | unit preference L, ML, KG, G; internal codes; UMREN ÷ UMREZ; ML, G ÷ 1000 | M5 |
| `READ_PRICES` | A923 holds the Paints DPL; material alone, latest DATAB | Q1 |
| `READ_SALES_VIEW` | MVKE-AUMNG is the quantity per carton; first distribution channel of 4000 | Q2 |
| `ENRICH` | tonnage on gross weight ÷ 1000, on the priced quantity, all modes | Q4 |
| `ZPP_FORECAST_PAINTS` | annual list without history columns (Sheet1); hidden, not absent | M7 |
| `ZPP_FORECAST_PAINTS` | legacy switch is TVARVC `ZPP_FCST_LEGACY`, the Adhesive one | — |
| shared engine | per-month additional via the change upload, Month 1/2/3 within the quarter | M6 |
| design | one set of shared tables for both divisions; a plant is never in both | M1 |

---

## 12. Open items

1. Functional test not started; `docs/ZFORECAST_Paints_Test_Handover.docx` is the pack.
2. Queries M1–M7, Q1–Q10 unanswered (`docs/ZFORECAST_Paints_Assumptions_and_Queries.docx`).
3. Transaction code `ZFCST_PAINTS`: reported created on 22/10 together with the GUI status, but
   Arnav asked that tcodes be left out of the handover documents; check SE93 and run from
   SE38 if it is not there.
4. (dropped) sales organisation is hardcoded; no config row.
5. `ZPP_FORECAST_PAINTS_UPL` still in DEV, to be deleted.
6. `ZDO_MTS_MTO` fixed values DIS / TIN not added; SM30 on the category table refuses them.
7. SM30 views on `ZPPT_BRAND` and the Paints tables not generated.
8. Authority bypass in `ZCL_PP_FCST_UTIL` (07/09/26) still live; restore before release.
9. The A923 price read exists twice (engine, private; Paints class). A change to the price
   rule goes into both.
10. `ZPP_FORECAST_PAINTS` is a copy of `ZPP_FORECAST`; a fix to the Adhesive program's
    screen, handler or display code has to be ported by hand.
11. Nothing reads the three Paints tables; the final report reads the shared ones.
12. TR DEVK930479 not released; nothing is in QAS.

---

## 13. How to change anything here safely

1. Ask for a fresh SE80 download of the object (`ZR_PROG_DOWNLOAD`) and diff it against
   `src/` before editing; the repository copy is not proof of what runs.
2. Change markers: `*BOC By <name> on DD/MM/YY` … `*EOC …` around blocks, `"Changes by …`
   on single lines; comment the old code, never delete it; never nest markers.
3. Strict Open SQL, `IS NOT INITIAL` before every `FOR ALL ENTRIES`, no SELECT in a loop,
   lines under 120 characters (SE38 wraps on paste).
4. Table field change → edit `tools/mktables.py`, re-run, re-zip. Upload change → edit the
   source with markers; the generator is for the record.
5. Run `python3 -I tools/abapcheck.py src/<file>` before zipping.
6. Commit to `main` and push (`./scripts/sync.sh "<what>"`); log the change in `ISSUES.md`
   with date, cause, files, TR.
