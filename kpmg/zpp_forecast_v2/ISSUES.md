# Issues — ZPP_FORECAST_V2

Log format: date | issue | root cause | files changed | commit | TR


## 02/09/26 — ZPP_FORECAST, four refinements from Arnav (points 2, 3, 4)

| # | Point | Cause / change | Where |
|---|-------|----------------|-------|
| 2 | Quarterly sheet must show `BUS_FCST_ADD` before the max-of-two field | `FINAL_QTY` is `nmax( FCST_QTY, BUS_FCST )` (`ZCL_PP_FCST` line ~520). `BUS_FCST_ADD` was only appended in the `gc_show_extras` block, i.e. never on the live sheet | `FORM visible_columns`, quarterly branch — `BUS_FCST_ADD` inserted between `BUS_FCST` and `FINAL_QTY`; the duplicate append in the extras block removed |
| 3 | No popup on save; drop the Save checkbox | `MESSAGES_SHOW` popup ran after every save; `p_save` also saved the whole run before the list was drawn | `p_save` withdrawn, `PERFORM save_all` and `FORM save_all` commented out, `show_log( )` replaced by `result_message( )` — one status line. `show_result( )` un-hides `FCST_NO` / `MESSAGE` after the Save button runs, which is what `p_save` used to do up front |
| 4 | Hide the Legacy checkbox when the switch is blank | New `g_legc_on`, read once in `INITIALIZATION` by `FORM legacy_switch`; `p_legc` carries `MODIF ID LGC` and is suppressed in `AT SELECTION-SCREEN OUTPUT` | ASSUMPTION: switch is TVARVC parameter `ZPP_FCST_LEGACY` ('X' / blank). Single reader, so the source swaps in one place |

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast.prog.abap`

## 02/09/26 — ZPP_FORECAST_UPLOAD, general result message (point 1)

Detail column repeated the uploaded values back at the user one row at a time
("History of X Y will now be reported under Z", "Business forecast 100, final
quantity now 250"). Replaced with a flat statement of what was uploaded; the
Result column (Created / Changed / Would create / Would change / Rejected) and
the closing "Upload finished: n created, n changed, n rejected" already carry
the outcome.

| FORM | Was | Now |
|------|-----|-----|
| `do_category` | `Category C, load factor 1.05, MTS` | `Product category uploaded` |
| `do_tracking` | `History of M1 M2 will now be reported under M3` | `Material mapping uploaded` |
| `do_exclusion` | `Already excluded, entry refreshed` / `Excluded from forecasting` | `Exclusion uploaded` |
| `do_history` | `Twelve months loaded, year total 1200 KG` | `Sales history uploaded` |
| `do_business` | `Business forecast 100, final quantity now 250` | `Business forecast uploaded` |
| `do_change` | `Change 50, final quantity now 300, reason RSN` | `Forecast change uploaded` |

Rejected rows keep their full reason — without it the user cannot correct the
file. `lv_total` in `do_business` was only computed for the removed text, so its
declaration and both assignments are commented out; the `lv_total` in `do_change`
stays, it guards the negative-quantity check.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 02/09/26 — ZPP_FORECAST_UPLOAD, 16 activation errors (pre-existing)

`"'PLANT' and the row type of 'CT_HEAD' are incompatible"` × 16, all in
`FORM template_columns`. Not caused by the point-1 change — the lines are
original code that had not been activated on this release before.

Root cause: a text literal `'PLANT'` is type `C`. On this release the row of a
`VALUE #( ( ... ) )` short form must be **compatible** with the row type, and
`C` is not compatible with `STRING`, which is the row type of `STRING_TABLE`.
All 16 `ct_head` / `ct_demo` assignments hit it; the `cv_name = '...'` lines did
not, because a plain MOVE into a `STRING` variable is a conversion and allowed.

Attempt 1 — string templates, `( |PLANT| )`: **rejected the same way.** So the
problem is not C-vs-STRING; this release will not take a constructor expression
with a literal row over an elementary line type at all, whatever the literal's
type.

Attempt 2 — plain `APPEND 'PLANT' TO ct_head.`: **this is the fix.** APPEND
assigns by conversion rather than by compatibility. All 16 assignments rewritten
as APPEND blocks; the one blank example cell appends a cleared `lv_blank TYPE
string` so no literal is involved there either.

Same shape corrected pre-emptively in `ZPP_FORECAST`, which had not been pasted
yet: the leading `ct_show = VALUE tt_fname( ( 'WERKS' ) ... )` block in
`FORM visible_columns` (pre-existing) and `lt_res` in `LCL_HANDLER=>SHOW_RESULT`
(added 02/09/26) are both APPEND now.

**Rule for this landscape: do not use `VALUE` with literal rows over an
elementary line type. Use APPEND.** Structured-row `VALUE #( ( sign = 'I' ... ) )`
in `ZCL_PP_FCST` is a different shape and is not affected.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`,
`kpmg/zpp_forecast_v2/src/zpp_forecast.prog.abap`

## 02/09/26 — ZPP_FORECAST, two defects found on pre-paste read

Found by reading the file before it went to SE38, not by an activation error.

1. `LCL_HANDLER=>SHOW_RESULT` — on a **second** press of Save, neither `FCST_NO` nor
   `MESSAGE` is appended to `GT_SHOW` again, so `lines( gt_show )` returned the same
   number for both and `set_column_position` handed the two columns the same slot,
   shuffling the column order. Position now taken from `sy-tabix` when the column is
   already in the list. Cosmetic, no dump.
2. `p_legc` could still be forced on when the legacy switch is blank. `INITIALIZATION`
   runs **before** a selection-screen variant is transferred, so `CLEAR p_legc` there
   loses to a variant with the box ticked, and to `SUBMIT ... WITH p_legc = 'X'`. Hiding
   the checkbox only stops a user typing it. The switch is now re-asserted at
   `START-OF-SELECTION`, which runs last and runs in background and under SUBMIT too.

Unverifiable from the code, flagged rather than changed: `set_technical( abap_false )` +
`refresh( )` after `display( )` has run — the reveal-on-save mechanism. If the two columns
do not appear on screen after Save, the fallback is to list them from the start.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast.prog.abap`

## 03/09/26 — CR of 02/09/26 built: month split, price columns, 5-material tracking

Everything in the CR except the price *logic*, which is still pending. `PRICE` is stored
and read but never derived, so it is 0 and both value columns compute to 0. When the
source is known, populate `PRICE` and `WAERS` — nothing else has to change.

**DDIC**

| Object | Change |
|---|---|
| `ZDO_FCST_VAL` | new domain, CURR 15,2 |
| `ZDE_FCST_PRICE` `ZDE_FCST_VAL` | new data elements over it |
| `ZPPT_FCST_QT` | `BUS_FCST_ADD` and `REASON` **removed**; added `BUS_FCST_ADD1/2/3`, `M4/M5/M6_FCST_FINAL`, `REASON1/2/3`, `WAERS`, `PRICE`, `M4/M5/M6_VAL`, `M4/M5/M6_TON_VAL` |
| `ZPPT_MAT_TRACK` | added `OLD_MATNR3/4/5` |

`ZPPT_FCST_MN` is untouched — the monthly table is already one row per month, so its
`BUS_FCST_ADD` and `REASON` stay.

**Code**

| Object | Change |
|---|---|
| `ZCL_PP_FCST` | `ty_alv` carries the new fields; quarterly reads the three additionals, the three reasons, `WAERS` and `PRICE` back (SAVE writes with CORRESPONDING, so anything not read would be blanked); per-month final and value computed in the split loop; material tracking walks 5 old codes in three places |
| `ZPP_FORECAST_UPLOAD` | quarterly change template gains `MONTH` at column 4, everything after shifts right; `do_change` resolves column offsets by mode; the change lands on `BUS_FCST_ADDn` / `REASONn` for the month it names; negative guard is now per month, not per quarter; tracking template gains 3 columns; `check_chain` and the duplicate checks walk 5 codes; new `FORM qt_finals`; `final_qty` lost its never-read `CV_ADD` parameter |
| `ZPP_FORECAST` | quarterly sheet shows `BUS_FCST_ADD1/2/3`, the three finals, `PRICE`, the six value columns and `WAERS`. Annual sheet carries no price |
| `ZPP_FORECAST_REPORT` | `QTR_ADD` is now `ADD1+ADD2+ADD3` — the report shows the quarter on one line |

Assumptions, all stated to Arnav and unchallenged: `month` is 1/2/3 **within the quarter**;
the CR's lines 12–13 naming `BUS_FCST_ADD1` for months 2 and 3 were a copy-paste slip;
the monthly change upload is untouched.

`M4_TON`/`M5_TON`/`M6_TON` still hold the tonnage of the forecast, not of the final. The
tonnage *value* columns use the final's tonnage. Flag if that should be consistent.

TR: not yet · ZIP rebuilt from `src/`, 39 files

## 03/09/26 — quarterly change upload: MONTH is the fiscal period, not a slot

Arnav confirmed "quarter 2 i.e. month 4 5 6". The first build read MONTH as 1/2/3 within
the quarter, which matched the CR's example row (Quarter 2, month 1) but not his intent.

MONTH is now the **fiscal period 1-12**, 1 = April, 12 = March — the same numbering the
monthly uploads already use. It must fall inside the quarter on the same row
(`period_to_quarter( month ) = quarter`), so Q1 takes 1-3, Q2 takes 4-6, Q3 takes 7-9,
Q4 takes 10-12. A mismatch is rejected with "Month 7 is not in quarter 2".

The column the value lands in is `month - ( quarter - 1 ) * 3` → 1, 2 or 3, which picks
`BUS_FCST_ADD1/2/3` and `REASON1/2/3`. Template demo row changed from month 1 to month 4.

Note for the TS: `M4_FCST` / `M5_FCST` / `M6_FCST` are named after Q2 but always hold the
first, second and third month of whichever quarter is run — Q4 fills them with Jan, Feb,
Mar. Pre-existing, not introduced here.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 03/09/26 — MONTH reverted to 1/2/3 per quarter (provisional)

Arnav's call: go with 1, 2, 3 within the quarter for now, revisit if the business raises it.
So Quarter 2 month 1 is July, Quarter 4 month 1 is January. Template demo row is back to
month 1, matching the CR's own example.

The fiscal-period version (Q2 takes 4-6, Q4 takes 10-12, validated with
`period_to_quarter`) is **kept commented in place** inside the same block in `do_change`,
so switching is uncommenting rather than rewriting. Everything downstream works off
`LV_SLOT`, which both readings set, so nothing else has to change. `LV_QCHK` in the DATA
list is commented out alongside and must be uncommented too.

Risk if this stands: a user given a column headed MONTH next to Quarter 2 may type 7 for
July. That is rejected as out of range, so it fails loudly rather than writing the wrong
month — but the error text is the only thing telling them the convention.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 03/09/26 — MONTH is the fiscal period on BOTH change templates (settled)

Supersedes the two entries above. Arnav's call after seeing that MONTH meant two different
things across the two files.

`MONTH` is the fiscal period 1-12, 1 = April, 12 = March, in
`ZFCST_Forecast_Change_Quarterly` and `ZFCST_Forecast_Change_Monthly` alike. The monthly
file already worked this way (`check_period` mode M) — only the quarterly one changed.

On the quarterly file the period must also fall inside the quarter on the same row:
Q1 takes 1-3, Q2 takes 4-6, Q3 takes 7-9, Q4 takes 10-12. Rejected with
"Month 7 is not in quarter 2". Column chosen by `month - ( quarter - 1 ) * 3`.
Template demo row is Quarter 2, month 4.

The 1/2/3-within-the-quarter version stays commented in the same block in case it comes
back. Note it only differs from Q2 onward — for Q1 both readings give April, May, June,
which is why the CR's own example row (Q2, month 1) read naturally and was wrong.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 03/09/26 — MONTH convention put behind one switch, set to 1/2/3

Supersedes the three entries above. The convention flipped three times in one session, so
it is no longer an edit — it is `DATA gv_qmonth TYPE char1 VALUE 'S'.` at the top of
`ZPP_FORECAST_UPLOAD`.

    'S'  MONTH is 1, 2 or 3 - first, second or third month of the quarter.  <-- LIVE
    'P'  MONTH is the fiscal period 1-12, 1 = April, checked against the quarter.

Both branches are live code in `do_change`; whichever runs, `LV_SLOT` ends up 1, 2 or 3 and
everything downstream works off that. The downloadable template's example row follows the
switch too, so changing the one letter is the whole job — no other edit, no re-test of the
write path.

`DATA` and not `CONSTANTS` deliberately: a constant lets the compiler fold the IF and
report the other branch as unreachable.

The two readings agree only for quarter 1 (both give April, May, June), which is why the
CR's own example row, Quarter 2 month 1, read naturally under either.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 03/09/26 — CR rebuilt on the CORRECT base (supersedes every 03/09 entry above)

**What went wrong.** The session branch forked from `ed57e79` (31/08), before branch
`claude/forecast-template-adhesive-hnqpxq` was written and never merged to main. Every
file edited on 02-03/09 therefore started from a version that never had the 31/08-01/09
work — real .XLSX upload, legacy fallback to standard tables, month-name headings,
MTS/MTO, Net Weight, Price, CSV templates driven from DDIC. The ZIP built from it
overwrote all of that in the system. The golden rule exists for exactly this: a fresh
SE80 download was never requested before the CR build.

**Recovery.** The four sources were restored from `5906927` (tip of that branch) and every
CR change re-applied on top. Nothing was lost - it was all in git.

| Object | Lines | Change |
|---|---|---|
| `ZCL_PP_FCST` | 1490 -> 1611 | `ty_alv` per-month adds/finals/value fields; `price` upgraded from the packed workaround to `ZDE_FCST_PRICE` with `waers` (the DDIC now has a currency field, so the reason for the workaround is gone); quarterly reads the three adds + reason/waers/price back so SAVE's CORRESPONDING cannot blank them; five old material codes in three places |
| `ZPP_FORECAST_UPLOAD` | 2090 -> 2437 | MONTH column + `GV_QMONTH` switch ('S' = 1/2/3 live, 'P' = fiscal period); per-month change write; `qt_finals`; `final_qty` loses unused `CV_ADD`; five old codes in `do_tracking` and `check_chain`; general per-row messages; `field_label` passes a dash-free key through as its own heading |
| `ZPP_FORECAST` | 1500 -> 1704 | Quarterly shows `ADD1/2/3`, three finals, six value columns, `WAERS`; Save checkbox withdrawn; `POPUP_TO_CONFIRM` withdrawn (`FORM SAVE_PROMPT` commented out whole - it still read `P_SAVE`); `SHOW_RESULT` / `RESULT_MESSAGE`; legacy switch with re-assert at START-OF-SELECTION |
| `ZPP_FORECAST_REPORT` | 413 -> 421 | `QTR_ADD` = `ADD1+ADD2+ADD3` |

**Corrections to earlier claims in this file.** Price DID already exist (`ty_alv-price`,
a Price column on all three modes and on the Final ALV) - Arnav was right and I was reading
the wrong branch. The CSV download is deliberate on this base, not a regression: the
template is comma separated with proper quoting and the upload reads CSV back.

`REASON` stays a SINGLE field on both tables - `REASON1/2/3` was my addition, not in the CR,
and was reverted at Arnav's call. A quarter changed three times keeps the last row's reason.

Verified: all five sources balance FORM/IF/LOOP/TRY/CASE/DO/WHILE/METHOD/CLASS, no line
over 120, every field the code reads exists in the DDIC, ZIP 39 files, XML well-formed,
no BOM, LF only.

TR: not yet

## 03/09/26 — activation error: FINAL_QTY parameter count

`"Different number of parameters in FORM and PERFORM (routine: FINAL_QTY, number of formal
parameters: 3, number of actual parameters: 4)"` at line 1686.

Cause: `CV_ADD` was dropped from `FORM final_qty` (it was never read, and the quarterly
table has no single `BUS_FCST_ADD` to pass any more), but only the two quarterly call sites
were updated. Both **monthly** branches — `do_business` and `do_change` — still passed
`ls_mn-bus_fcst_add` as a fourth argument. The compiler stops at the first, which is why
only one error showed.

Fixed both. All four call sites now pass three arguments.

Added a check that would have caught it: every `PERFORM` in all five sources is now
compared against its `FORM` signature (quote-aware, so string literals with spaces are not
miscounted). Result: 0 mismatches across the whole object. Worth re-running after any
change to a FORM signature.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 03/09/26 — QA source verified against the rebuild; CHANGE QTY heading reverted

Arnav supplied the QA copy of `ZPP_FORECAST_UPLOAD`. It matches `5906927` exactly — 2090
lines, 8 per-radio Download Template buttons, 33 FORMs — so the restore base was right.

All 25 distinguishing features survive the rebuild: the eight pushbuttons and their
`TCAT`-`TCGM` handling, `g_type`, `g_xls`, `current_type`, `download_template USING`,
`upload_excel`, `upload_text`, `file_extension`, `split_line`, `put_field`, `drop_header`,
`field_label`, `CL_FDT_XL_SPREADSHEET`, `solix_to_xstring`, `get_itab_from_worksheet`,
`MESSAGE e024`, CSV `join_row`. No routine lost; `qt_finals` is the only addition.

All 49 deleted lines checked one by one - each is an active line replaced by its CR
equivalent, with the original preserved commented in its BOC/EOC block.

**Corrected:** the CHGQ quantity column had been given the literal heading 'CHANGE QTY'.
That broke the 31/08 principle that every heading is the DDIC label of the field it loads.
Pointed at `ZPPT_FCST_QT-BUS_FCST_ADD1` instead, so it reads "Forecast Quantity" again,
exactly as in QA. `MONTH` stays a literal - it is the only column with no table field
behind it.

**Open:** `do_exclusion` still carries its two original result texts ('Already excluded,
entry refreshed' / 'Excluded from forecasting'). They echo no uploaded values so they do
not breach point 1; left as they are pending Arnav's call.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast_upload.prog.abap`

## 03/09/26 — audit of all four objects against the QA base; two unrequested changes reverted

Same check run over `ZCL_PP_FCST`, `ZPP_FORECAST` and `ZPP_FORECAST_REPORT` that was run on
the upload. Every changed line classified as asked-for or not.

**Reverted - nobody asked for these:**

1. `ZCL_PP_FCST` `ty_alv-price` had been retyped from `TYPE p LENGTH 13 DECIMALS 2` to
   `ZDE_FCST_PRICE`, with a `waers` field added beside it. The 31/08 note chose packed
   deliberately, because a CURR column with no currency reference field makes SALV raise
   `CX_SALV_DATA_ERROR`. Overriding a deliberate decision that was working. Back to packed;
   `waers` removed from the structure and from the quarterly SELECT.
2. `ZPP_FORECAST` had gained a `WAERS` / "Currency" column on the quarterly sheet. Not in
   the CR. Removed.

Consequence: the six new value columns are now `TYPE p LENGTH 13 DECIMALS 2` as well,
matching PRICE for the same SALV reason. The table fields stay CURR; CORRESPONDING converts.

**Kept, all traceable to a request:** the nine new quarterly fields and the per-month final
and value calculation (CR 1-5); five old material codes in three places (CR 6);
`total_qty` and `QTR_ADD` summing the three adds and the extras-block change (forced by
`BUS_FCST_ADD` leaving the table); `g_legc_on` / `gc_tv_legacy` / `MODIF ID LGC` (point 4);
`p_save` withdrawn, `SHOW_RESULT` / `RESULT_MESSAGE`, `FORM SAVE_PROMPT` commented out
(point 3, the POPUP_TO_CONFIRM); the new column list and headings (CR).

Nothing else in the three objects was touched.

TR: not yet

## 03/09/26 — do_exclusion result texts: closed, no change

Arnav's call: leave 'Already excluded, entry refreshed' / 'Excluded from forecasting' as
they are. They echo no uploaded values, so point 1 is satisfied, and "already excluded"
tells the user the row was a no-op. `FORM do_exclusion` stays byte-identical to QA.

Point 1 therefore applies to five of the six upload types by design, not by omission.

## 03/09/26 — ZPP_FORECAST1.zip, delta only

`ZPP_FORECAST.zip` (39 files) is the whole package. `ZPP_FORECAST1.zip` (15 files) carries
only what differs from the QA base, so a pull cannot touch anything that is already correct:

  3 new DDIC   ZDO_FCST_VAL, ZDE_FCST_PRICE, ZDE_FCST_VAL
  2 tables     ZPPT_FCST_QT, ZPPT_MAT_TRACK
  1 class      ZCL_PP_FCST (.abap + .clas.xml)
  3 reports    ZPP_FORECAST, ZPP_FORECAST_UPLOAD, ZPP_FORECAST_REPORT (.abap + .prog.xml)
  package.devc.xml and .abapgit.xml, which abapGit needs to resolve the package

Deliberately NOT in it, all byte-identical to QA: `ZCL_PP_FCST_UTIL`, message class
`ZPP_FCST` (024 already present there), and the six unchanged tables, seven domains and
eight data elements.


## 03/09/26 — import error: "REPORT/PROGRAM statement is missing, or the program type is INCLUDE"

Two errors on the pull, for `ZPP_FORECAST` and `ZPP_FORECAST_REPORT`, both at line 1.

Cause: the `PROGDIR` block of all three `.prog.xml` files listed `SUBC` BEFORE `VARCL`.
abapGit deserialises with `CALL TRANSFORMATION id`, which walks the target structure
component by component - `varcl` is component 5 of `zif_abapgit_sap_report=>ty_progdir`
and `subc` is component 11 - so an element arriving out of sequence is not applied.
`SUBC` therefore never reached the program directory and the programs were created with
no type at all, which SE38 reports as "program type is INCLUDE".

This is the exact defect CLAUDE.md records for `ovl/ztest_t001` and warns is copied
between objects unnoticed. All three were wrong; only two showed, because
`ZPP_FORECAST_UPLOAD` already existed as an executable program from an earlier paste, so
its directory entry did not need to change.

Fixed in all three - the order is now NAME, VARCL, SUBC, FIXPT, UCCHECK.

Also removed: the orphan `P_SAVE` selection text from `ZPP_FORECAST`'s TPOOL. The
parameter was withdrawn for point 3, so the text pointed at nothing.

Both ZIPs rebuilt.

TR: not yet · Files: the three `.prog.xml` under `kpmg/zpp_forecast_v2/src/`

## 03/09/26 — quarterly ALV column order: three blocks of three

The three add-ons sat in front of FINAL_QTY, five columns away from the monthly forecast
each one adds to. Reordered so the quarterly sheet reads across:

  FCST_QTY  BUS_FCST  FINAL_QTY
  M4_FCST        M5_FCST        M6_FCST          the quarter split by month
  BUS_FCST_ADD1  BUS_FCST_ADD2  BUS_FCST_ADD3    the add-on for each month
  M4_FCST_FINAL  M5_FCST_FINAL  M6_FCST_FINAL    forecast + add-on
  M4_VAL         M5_VAL         M6_VAL           final x PRICE
  [M4_TON        M5_TON         M6_TON]          only when Tonnage is ticked
  M4_TON_VAL     M5_TON_VAL     M6_TON_VAL       final tonnage x PRICE

Each column now sits directly above and below the ones it is derived from, so a value can
be checked by reading down the block.

This supersedes point 2 of 02/09 ("BUS_FCST_ADD before the field that displays the max of
the 2"). That was written when there was one add-on column; with three, they belong beside
the monthly forecasts rather than in front of the quarter-level FINAL_QTY.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast.prog.abap`

## 03/09/26 — quarterly ALV: month by month, headings from the calendar

Supersedes the "three blocks of three" entry above.

Columns are now grouped by MONTH, not by kind, and built in a DO 3 TIMES loop:

  Jul-26 · Jul-26 additional · Jul-26 final · Jul-26 value [· Jul-26 tonnage · tonnage value]
  Aug-26 · Aug-26 additional · Aug-26 final · Aug-26 value [...]
  Sep-26 · Sep-26 additional · Sep-26 final · Sep-26 value [...]

The static 'Month 1 / 2 / 3' headings are gone. `MONTH_HEADINGS` names the additional,
final and both value columns from the financial calendar, exactly as it already named
`Mn_FCST` and `Mn_TON`, so a quarter 4 run reads Jan-27 and not "Month 1".

Two things worth remembering:
  - `LV_Q` and `LV_M` are typed I, not NUMC2. A NUMC in a string template keeps its
    leading zero, which would have built BUS_FCST_ADD01 instead of BUS_FCST_ADD1.
    `LV_P` stays NUMC2 because the annual sheet needs M01..M12.
  - Tonnage now joins its own month rather than sitting in a block of its own.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zpp_forecast.prog.abap`

## 03/09/26 — AUTHORITY CHECKS DISABLED FOR QAS TESTING — MUST BE RESTORED

**This is a temporary change and it must not go past QAS initial testing.**

Both methods in `ZCL_PP_FCST_UTIL` now return `abap_true` immediately:

  CHECK_AUTHORITY          AUTHORITY-CHECK OBJECT 'ZPP_FCST' commented out
  CHECK_LEGACY_AUTHORITY   the ZPPT_FCST_CFG / TVARVC reads commented out

Done at source, not at the call sites. Six callers go through these two methods —
`ZCL_PP_FCST=>SAVE`, `ZPP_FORECAST` (AT SELECTION-SCREEN, SAVE_ALL, DISPLAY),
`ZPP_FORECAST_REPORT` (AT SELECTION-SCREEN) and `ZPP_FORECAST_UPLOAD` (CHECK_MARC).
All six keep their code exactly as QA has it, so nothing has to be unpicked later and
no call site can be missed.

TO RESTORE: in each method delete the `RETURN` and uncomment the block beneath it.
Two edits, one object, nothing else changes.

Note for the record: these were NOT previously commented out. `ZCL_PP_FCST_UTIL` was
byte-identical to the QA copy until now, and the checks were active in QA - the pasted
QA source shows `CHECK_MARC` calling `CHECK_AUTHORITY` with ACTVT 02.

`ZCL_PP_FCST_UTIL` is therefore now a changed object and is in ZPP_FORECAST1.zip, which
grows from 15 files to 17.

TR: not yet · Files: `kpmg/zpp_forecast_v2/src/zcl_pp_fcst_util.clas.abap`

## 15/09/26 — wrong base: main never had the 02–03/09 CR build

`main`'s forecast folder was still the 26/08 state — the whole 02–03/09 CR build (per-month
`BUS_FCST_ADD1/2/3`, price and value columns, five old codes, PROGDIR fix, 07/09 auth
bypass) sat on branch `claude/forecast-adhesive-refinements-5asxec`, 28 commits never
merged. The first 15/09 build (commits `8f31877`, `d611203`) was made on that stale copy and
failed activation with `Unknown column name "BUS_FCST_ADD"` in `GENERATE_QUARTERLY` — the
QAS table has `BUS_FCST_ADD1/2/3` and no `BUS_FCST_ADD`, exactly as the branch's DDIC says.
**The advice given at that point, to add `BUS_FCST_ADD` back to `ZPPT_FCST_QT` in SE11, was
wrong and is withdrawn — the table is right, the file was not.**

Recovery: branch merged into `main` (merge commit `3c7d7d6`, forecast folder taken wholesale
from the branch), then the 15/09 request re-applied on that base below. Same lesson as the
03/09 entry: `git log --all -- kpmg/zpp_forecast_v2` before trusting `main`, and ask for the
SE80 download.

## 15/09/26 — ZPP_FORECAST / ZCL_PP_FCST, quarterly and monthly: price logic, value columns, material type

Change request received 15/09/26, three points under "Quarter and Month". Built on the
03/09 base (branch above). **No fresh SE80 download was supplied** — diff the running
`ZCL_PP_FCST` and `ZPP_FORECAST` against `src/` before pasting.

| # | Request | What was built | Where |
|---|---|---|---|
| 1 | Price logic: A923-MATNR → KNUMH by DATAB descending; KONP-KNUMH → KBETR | This is the "price logic still pending" of the 03/09 entry. `READ_PRICES`, one read per run, latest DATAB per material, lowest KOPOS line of that KNUMH. Read on material alone — no condition type, VKORG, valid-to, KPEIN or KONWA — as worded, flagged `ASSUMPTION` in the method header. `PRICE` is overwritten with the result every run; the existing read-back from `ZPPT_FCST_QT` stays only so SAVE does not blank the column. No condition record → price 0, values 0 (the first row of the sample) | `ZCL_PP_FCST` private method, called after `BUILD_SCOPE` in `GENERATE_QUARTERLY` and `GENERATE_MONTHLY`; price assigned before the quarterly split loop and in the monthly row |
| 2 | Columns "Price for <month> in EA" ×3, "Price for <month> in Tonnage" ×3, "Final forecast qty × Price" | Quarterly already had `M4/5/6_VAL` (final incl. additional × price) and `M4/5/6_TON_VAL` since 03/09 — re-headed as the request names them, and new `TOTAL_VAL` = `TOTAL_QTY` × price at the end. Monthly gains `M4_VAL` = `TOTAL_QTY` × price and `M4_TON_VAL` = tonnage of `TOTAL_QTY` × price (sample: 189.045 × 1.2 = 226.854), the tonnage value following the Tonnage Wise checkbox. Display only — `ZPPT_FCST_MN` has no price or value fields | `ZCL_PP_FCST` `TY_ALV-TOTAL_VAL`; `ZPP_FORECAST` `VISIBLE_COLUMNS` (after the PRICE append), `MONTH_HEADINGS`, `SETUP_COLUMNS` |
| 3 | Material type only FERT and HAWA, TVARVC `ZPP_FORECAST_MTART` | `FILTER_MTART` reads the variable as a range (EQ rows or BT), drops every scope material whose MARA-MTART is outside it. Quarterly and monthly only, annual untouched. Unmaintained variable → no filter + new message **ZPP_FCST 025** (W) in the log | `ZCL_PP_FCST` private method |

**"Values come in quarterly but not in monthly"** — on the real base this is simply that the
03/09 CR added price and value columns to the quarterly sheet only; `GENERATE_MONTHLY` never
computed a value and `VISIBLE_COLUMNS` never listed one. Point 2 above closes it. (The earlier
diagnosis blaming the MATDOC source was made against the stale base and is withdrawn.)

Column order after the change — quarterly: … `MTS_MTO`, `PRICE`, `TOTAL_VAL`; monthly: …
`TOTAL_QTY`, [`M4_TON`], `PRICE`, `M4_VAL`, [`M4_TON_VAL`].

Not touched: `ZPP_FORECAST_REPORT`, `ZPP_FORECAST_UPLOAD` (its `qt_finals` recomputes the
quarterly values from the stored `PRICE`, which the ALV save now fills), `ZCL_PP_FCST_UTIL`
(auth bypass of 07/09 still in place). Annual unchanged. ZIPs not rebuilt. The
`zcl_pp_fcst_nocomments.abap` copy regenerated; `zpp_forecast_v2_nocomments.abap` is a
stale 31/08 class copy and was left alone.

Manual steps: SE91 message `ZPP_FCST 025`; STVARV selection variable `ZPP_FORECAST_MTART`
with rows FERT and HAWA; confirm `A923` exists with fields MATNR, DATAB, KNUMH (SE11).
Do NOT change `ZPPT_FCST_QT`.

**Activated by Arnav on 15/09/26** — `ZCL_PP_FCST`, `ZPP_FORECAST`, message `ZPP_FCST 025`.
Commit `7388be0` on `main`.

TR: not yet transported.

## 15/09/26 — monthly history read from billing, same as quarterly

Test case: quarter 2 run showed May-26 = 3600, period 4 run showed May-26 = 300 for the same
material; most materials had figures in quarterly and none in monthly. Cause: by design (FS
and mandatory query M1, never answered) quarterly read `VBRP-FKIMG` from billing while monthly
read `MATDOC-MENGE` for movement 601 — different documents and, at 12×, different units.

Arnav's call: one source. `GENERATE_MONTHLY` now reads `READ_BILLING` instead of
`READ_MATDOC`, and passes `iv_use_billing = abap_true` so superseded codes follow the
successor onto billing too. Old lines commented in place inside the 31/08 block (single-line
markers, no nesting). The monthly formula (average × load, max with LY same month, max with
business forecast) is untouched; only the history figures change. `READ_MATDOC` and
`ZPPT_FCST_CFG-BWART` remain but are no longer called. **Deviates from the FS, which names
MATDOC 601 for this mode — to be corrected in the FS.**

Not changed, flagged: both modes now sum `FKIMG`, the sales-unit quantity, while tonnage
multiplies by `MARA-NTGEW`, which is per base unit. Wherever sales unit ≠ base unit the
tonnage is off by the conversion factor. `VBRP-FKLMG` (billed quantity in base unit) is the
one-word fix if the functional side wants base-unit figures.

Files: `src/zcl_pp_fcst.clas.abap` only (`zcl_pp_fcst_nocomments.abap` regenerated).
TR: not yet transported.

## 15/09/26 — pre-handover check before functional testing (static, no data in DEV)

Re-read every 15/09 block in `ZCL_PP_FCST` and `ZPP_FORECAST` after the last paste:

- Tonnage: every `Mn_TON` / `Mn_TON_VAL` / `M4_TON` / `M4_TON_VAL` append in `VISIBLE_COLUMNS`
  sits under `IF p_tonn = abap_true`; `iv_tonnage = p_tonn` on all three generate calls.
  The tonnage *values* are computed regardless and only hidden, and the quarterly save
  stores them (03/09 behaviour, unchanged).
- Price: `READ_PRICES` called after `BUILD_SCOPE` in quarterly and monthly; `ls_alv-price`
  set before the quarterly split (so `Mn_VAL` / `Mn_TON_VAL` / `TOTAL_VAL` multiply by it)
  and in the monthly row (`M4_VAL`, `M4_TON_VAL`). Values are final quantity × price
  throughout. No duplicate inline declarations (each `lt_price` is in its own method).
- Monthly history from billing, same as quarterly. Message 025 present in the msag.

**Open, seen during the check — not part of any request:** `ZPP_FORECAST_REPORT` declares
and heads a `PRICE` column (31/08) but never fills it. The quarterly save now stores `PRICE`
on `ZPPT_FCST_QT`, so the report could read it back for quarterly rows; monthly rows have
no stored price. Testers will see a blank Price column on the Final ALV until this is built.

QAS setup the testers need: STVARV `ZPP_FORECAST_MTART` (TVARVC is client-specific — maintain
it in QAS, it does not travel with the code), A923 condition records for the test materials,
and the transport carrying message 025.

## 15/09/26 PM — quarterly and monthly save without an annual forecast; material type on annual too

Two issues from Arnav's own test, both in `ZCL_PP_FCST` only.

**1. Quarterly and monthly rows would not save until annual was saved; forecast number blank.**
Cause: SAVE took the number from `ZPPT_FCST_YR` only (`ANNUAL_NUMBER`) and refused the row
with message 005 when there was none — the FS reading "insert with the same forecast number
by passing the fiscal year to the annual table". Arnav's call: the three modes must save
independently under one shared number.

- New `SHARED_NUMBER`: the number already carried by any of the three tables for the plant,
  material and financial year — annual first (keyed on FYEAR), then quarterly, then monthly
  (keyed on the start year GJAHR); blank numbers on a row are skipped.
- SAVE, all three branches: shared number first; if none, a new one from ZPPFCST via
  `NUMBER_GET` (the same call annual used); if that fails, message 021 as annual already
  did. Message 005 is no longer raised at save. Old lines commented in place.
- Generation, quarterly and monthly: `SHARED_NUMBER` instead of `ANNUAL_NUMBER`, so a number
  drawn by an earlier quarterly save shows on the next run. Annual generation still checks
  `ZPPT_FCST_YR` alone — its "already saved, will be overwritten" flag must mean the annual
  row, not a quarterly one.
- `NUMBER_FROM_TABLE` (the 31/08 fallback when SNRO is not there) now takes the maximum over
  all three tables, otherwise it could re-issue a number a quarterly save had already used.

Consequence for the data: the number on `ZPPT_FCST_QT` / `_MN` no longer proves an annual
forecast exists. `ZPP_FORECAST_REPORT` consolidates by plant, material and year, not by
number, so it is unaffected.

**2. Material type restriction was not applied to annual.** Built that morning for quarterly
and monthly only, as the request was headed. `FILTER_MTART` is now called after `BUILD_SCOPE`
in `GENERATE_ANNUAL` as well; comments updated to say all three modes.

Files: `src/zcl_pp_fcst.clas.abap` (`zcl_pp_fcst_nocomments.abap` regenerated). No DDIC, no
message change, no program change.
TR: not yet transported.

## 18/09/26 — ZPP_FORECAST_UPLOAD, legacy history: one filled month reported as "all twelve zero"

Found by Arnav in the debugger: in `FORM do_history` the `ASSIGN COMPONENT lv_fld OF
STRUCTURE ls_hist` returned sy-subrc 4, so the month value was never stored or counted.

Root cause: `lv_fld = |M{ lv_i WIDTH = 2 PAD = '0' }|`. A string template aligns LEFT by
default, so the pad character goes on the right: month 1 gave `M10`, months 2 to 9 gave
`M20`..`M90`, which are not fields of ZPPT_SLS_HIST. Only months 10 to 12 came out right, and
month 1 landed in M10 (January). A file with one month filled therefore summed to zero and
was refused; a file with all twelve months filled was **accepted and stored wrong** —
April in January's column, May to December lost.

Fix: `ALIGN = RIGHT` added to the template (single line, original kept commented above).

**Data:** every legacy-history row loaded through this upload before the fix is wrong or
missing. Re-upload the history files after activating, or clear ZPPT_SLS_HIST for the test
plant first.

**Same idiom, not changed:** `ZCL_PP_FCST_UTIL=>LAST_THREE_MONTHS` line 296 builds the
month's first date with `{ lv_m WIDTH = 2 PAD = '0' }`, so for months 1 to 9 `datfr` is an
invalid date such as 20264001. It is only ever used as the upper bound of the billing read
window, which becomes wider than needed (into months that have no data yet), never
narrower, and the month buckets are keyed on the correct NUMC month, so results are
unaffected. Left as is because the class in QAS carries the 07/09 auth bypass and was not to
be touched; the one-word fix is the same `ALIGN = RIGHT`.

Files: `src/zpp_forecast_upload.prog.abap`. TR: not yet transported.

## 23/09/26 — ZFCST: a superseded code entered on the selection screen returned nothing

Tester ran one material that has a product category; the material sits in ZPPT_MAT_TRACK as an
old code, so `BUILD_SCOPE` dropped it (D6a) while its successor was outside the entered range —
empty list.

Fix in `ZCL_PP_FCST` only: new `EXTEND_BY_TRACK`, called right after `READ_CONFIG` in all three
generators, widens the material range with the NEW_MATNR of every tracking row of the plant
whose OLD_MATNR1..5 falls inside the entered range (a blank selection is left alone). Every
read in the generator then uses the widened range `LR_MATNR` — history, legacy, old-code
absorption and scope (12 lines, originals commented above each). Message **026** (W) records
"Material &1 is superseded by &2 and is shown under &2" in the run log. Result: typing the old
code brings up the successor row carrying the old code's history. Old codes still get no row
of their own.

**Open design point raised by Arnav the same day, not built:** the tracking table has no
validity. For a financial year in which the old code was still the live material (e.g. a
2025-2026 run when the replacement happened in 2026-2027) the old code is still absorbed and
removed, and the successor shown instead. Options recorded in NOTES; recommendation is a
"valid from financial year" on ZPPT_MAT_TRACK if the business needs forecasts for years before
a replacement, otherwise keep the successor rule.

Manual: SE91 message ZPP_FCST 026. Files: `src/zcl_pp_fcst.clas.abap`, `src/zpp_fcst.msag.xml`
(`zcl_pp_fcst_nocomments.abap` regenerated). TR: not yet transported.

## 23/09/26 — ZFCST list: full standard toolbar (sort, filter, totals, layout) beside the four buttons

Two parts. **SE41 (manual, Arnav):** `PF_STATUS` of ZPP_FORECAST is recreated as a copy of
`SALV_STANDARD` from `SAPLSALV_METADATA_STATUS` with `ZSAVE`, `ZSELALL`, `ZDESEL`, `ZEXCEL`
added to the application toolbar; the program already calls `set_screen_status` with
`c_functions_all`, which switches on every SALV function whose `&` code the status carries.
The status is not serialised by abapGit and travels only in the transport.

**Code (`ZPP_FORECAST`, `FORM display`):** a layout key was never set, so SALV offered
"Change layout" only — "Save layout" and "Select layout" need `get_layout( )->set_key( )`.
Added after `set_all( )`: key = report + mode as handle (annual, quarterly and monthly have
different column sets, so their layouts must not be offered to each other),
`set_save_restriction( restrict_none )`, `set_default( abap_true )`. `ZPP_FORECAST_REPORT`
runs on the standard status but has no layout key either — same three lines if wanted.

Files: `src/zpp_forecast.prog.abap`. TR: not yet transported.

## 23/09/26 PM — ZFCST list in a container: full standard toolbar with no GUI status (supersedes the SE41 entry above)

Arnav's call: the standard toolbar must be complete and must not depend on a hand-built
status. In full screen SALV can only switch on the standard functions whose codes the given
status carries, and `ADD_FUNCTION` raises `CX_SALV_WRONG_CALL`; in a container both problems
go away. `FORM display` in `ZPP_FORECAST`:

- `cl_salv_table=>factory` now receives `r_container = cl_gui_container=>default_screen`.
  No SE51 screen is involved, so the object stays abapGit-shippable.
- The four buttons are added with `ADD_FUNCTION` (ZSAVE only when the user may save, as
  before), positioned right of SALV's own functions. The handler is unchanged.
- `set_screen_status` and its status-not-found fallback are commented out; `display( )` is
  followed by `WRITE: space.`, which opens the list screen the container is drawn on.
- The layout key added that morning stays, so Save / Select layout work.

`PF_STATUS` is no longer referenced at runtime; if it was created, it can stay or go.
`GC_STATUS` is kept for the commented code. Background execution is expected to fall back
to SALV's list output but is untested. `ZPP_FORECAST_REPORT` untouched (standard status,
full toolbar already; no layout key).

Files: `src/zpp_forecast.prog.abap`. TR: not yet transported.

## 23/09/26 PM — ZPP_FORECAST_REPORT: layout key, so Save / Select layout work on the final report

Same three lines as on ZFCST, in `FORM display` after `set_all( )`: key = report (no handle,
one column set), `set_save_restriction( restrict_none )`, `set_default( abap_true )`. The
report stays full screen on SALV's standard status, which already carries the whole toolbar.
ZFCST activated by Arnav on 23/09/26 in container mode.

Files: `src/zpp_forecast_report.prog.abap`. TR: not yet transported.

## 23/09/26 PM — ZFCST toolbar position: back to full screen, container kept behind a switch

Arnav's screenshot after activating the container version: the grid toolbar sits under the
empty application toolbar row and under the grid's own title line. He wants the functions
where Execute sits and one title on top - which only full screen with a GUI status gives.

`FORM display` now branches on `GV_CONTAINER` (DATA at the top of the program, default
`abap_false`): full screen = `factory` without container, `set_screen_status( PF_STATUS,
c_functions_all )` when the user may save, `display( )` with the status-not-found fallback
to SALV_STANDARD; container = the 23/09 PM code unchanged. Layout key applies to both.

**SE41 is back (one-time, then it travels in the transport):** copy `SALV_STANDARD` from
program `SAPLSALV_METADATA_STATUS` to `ZPP_FORECAST` / `PF_STATUS`, add the four buttons to
the application toolbar, keep every `&` code as copied. Until the status exists the program
shows the standard toolbar without the four buttons and says so in the status bar.

Files: `src/zpp_forecast.prog.abap`. TR: not yet transported.
