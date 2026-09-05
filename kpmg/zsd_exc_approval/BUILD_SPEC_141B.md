# BUILD SPEC — WRICEF 141.B, Exceptional Approval, Paints

Locked technical contract. Every implementer and reviewer works from THIS file.
Where this spec and the FS disagree, this spec wins and the deviation is listed in §7.

Deliverables, in the order Arnav creates them in the system:

| # | Object | Name | Created via |
|---|---|---|---|
| 1 | Domains + data elements | see §2 | SE11, by hand |
| 2 | Transparent table | ZSD_EXP_PAINTS | SE11, by hand from the build sheet |
| 3 | Table maintenance generator | on ZSD_EXP_PAINTS | SE11 -> Utilities -> TMG, by hand |
| 4 | Upload / change report | ZSD_EXP_PAINTS_UPLOAD | SE38 paste |
| 5 | Output report | ZSD_EXC_APPR_PAINTS | SE38 paste |

Objects 1-3 are DDIC/GUI work and CANNOT be pasted as source — they ship as a build
sheet Arnav types into SE11. Do not write ABAP for them and do not write abapGit XML.

## 0. Non-negotiable house rules (from CLAUDE.md)

Identical to BUILD_SPEC_141A.md §0 — read that file's §0 and apply it in full. In short:
lines under 120 chars; strict Open SQL with `@` on every host variable; `INTO` after
`ORDER BY`; `IS NOT INITIAL` before every `FOR ALL ENTRIES`; no SELECT in a LOOP;
`DELETE ADJACENT DUPLICATES` with a matching `SORT` outside any loop; no hardcoded
client / date / company code; errors message the user, never dump; risky assumptions
carry a greppable `" ASSUMPTION:` note; complete objects, never fragments.

DO NOT run any git command. Do not run scripts/sync.sh. Write your files and stop —
commits are handled outside the workflow.

## 1. The four FS contradictions and how they are settled

The FS for Paints contradicts itself in four places. These are settled here; each
carries an ASSUMPTION note in the code and appears in §7.

**C1 — Actual Collection date window.** The output mapping says BUDAT comes from the
selection screen. Parth Shah's document comment says "Collection received during the
approval date & Commitment date". SETTLED: per row, BUDAT between ZEXC_DATE_FROM and
ZCOMMIT_DATE inclusive. The reviewer comment is later, more specific, and semantically
coherent — a collection credited against one approval must fall inside that approval's
own window, otherwise a single selection-screen range double-counts collections across
overlapping approvals for the same customer.

**C2 — Non-Fulfilment Amount.** The formula row says Collection Commitment minus Actual
Collection. The sample row (limit 100,000 / collection 125,000 -> 25,000) is Actual minus
Credit Limit, which is the Adhesives formula copy-pasted. SETTLED: use the stated formula,
`ZCM_AMNT - Actual Collection`. Parth Shah's comment independently restates it, so the
prose has two votes and the sample has none.

**C3 — Info Category / Info Type on the selection screen.** Both are marked Required, but
ZSD_EXP_PAINTS has no info category or info type field, so neither can filter anything.
SETTLED: OMIT both from the Paints selection screen. Two mandatory fields that filter
nothing would mislead the user into thinking the list is narrower than it is. The two
reversals — add ZINFOCAT/ZINFOTYPE to the table, or drop them from the FS — both belong
to functional; §7 records the choice for sign-off.

**C4 — Field name of the exceptional amount.** The table definition declares ZEXC_AMOUNT;
the output mapping calls the same thing ZEXC_AMNT. SETTLED: the DDIC name is
**ZEXC_AMOUNT**. Note also that the separately declared ZEX_AMNT ("Exceptional Approval
Amount") appears in no output column — it is built into the table because the FS declares
it, but nothing reads it. Functional must confirm whether it is a real second figure or a
duplicate to drop.

## 2. Domains and data elements (object 1)

Create only these. Everything else reuses a standard SAP data element.

| Domain | Type | Len | Dec | Fixed values / notes |
|---|---|---|---|---|
| ZSD_DO_EXC_SRNO | NUMC | 10 | - | serial number |
| ZSD_DO_EXC_MONTH | NUMC | 6 | - | stored YYYYMM, displayed MM-YYYY |
| ZSD_DO_EXC_TYPE | CHAR | 1 | - | fixed values 1 = Credit Limit, 2 = Overdue, 3 = Credit Limit & Overdue |
| ZSD_DO_EXC_AMOUNT | CURR | 23 | 2 | length 23 is the FS figure; flag it in the sheet as unusually wide |
| ZSD_DO_EXC_REMARKS | CHAR | 250 | - | |

| Data element | Domain | Short / medium / long / heading |
|---|---|---|
| ZSD_DE_EXC_SRNO | ZSD_DO_EXC_SRNO | Sr. No. / Serial No. / Serial Number / Sr. No. |
| ZSD_DE_EXC_MONTH | ZSD_DO_EXC_MONTH | Month / Appr. Month / Exceptional Approval Month / Month |
| ZSD_DE_EXC_TYPE | ZSD_DO_EXC_TYPE | Type / Appr. Type / Exceptional Approval Type / Type |
| ZSD_DE_EXC_AMOUNT | ZSD_DO_EXC_AMOUNT | Exc. Amt / Exceptional Amt / Exceptional Amount / Exc. Amount |
| ZSD_DE_CM_AMOUNT | ZSD_DO_EXC_AMOUNT | Coll. Comm. / Collection Comm. / Collection Commitment Amount / Coll. Commitment |
| ZSD_DE_EXC_REMARKS | ZSD_DO_EXC_REMARKS | Remarks / Remarks / Remarks / Remarks |

## 3. Table ZSD_EXP_PAINTS (object 2)

Delivery class A, maintenance "Display/Maintenance Allowed".

| Pos | Field | Key | Data element | Type | Len | Dec | Check table | Curr ref |
|---|---|---|---|---|---|---|---|---|
| 1 | MANDT | X | MANDT | CLNT | 3 | - | T000 | - |
| 2 | ZSRN | X | ZSD_DE_EXC_SRNO | NUMC | 10 | - | - | - |
| 3 | ZCUSTOMER | X | KUNNR | CHAR | 10 | - | KNA1 | - |
| 4 | ZEXC_APPR_MONTH | X | ZSD_DE_EXC_MONTH | NUMC | 6 | - | - | - |
| 5 | ZEXC_APPR_TYPE | | ZSD_DE_EXC_TYPE | CHAR | 1 | - | - | - |
| 6 | ZEXC_DATE_FROM | | DATUM | DATS | 8 | - | - | - |
| 7 | ZEXC_DATE_TO | | DATUM | DATS | 8 | - | - | - |
| 8 | ZEXC_AMOUNT | | ZSD_DE_EXC_AMOUNT | CURR | 23 | 2 | - | ZSD_EXP_PAINTS-WAERS |
| 9 | ZCOMMIT_DATE | | DATUM | DATS | 8 | - | - | - |
| 10 | ZEX_AMNT | | ZSD_DE_EXC_AMOUNT | CURR | 23 | 2 | - | ZSD_EXP_PAINTS-WAERS |
| 11 | ZCM_AMNT | | ZSD_DE_CM_AMOUNT | CURR | 23 | 2 | - | ZSD_EXP_PAINTS-WAERS |
| 12 | ZREMARKS | | ZSD_DE_EXC_REMARKS | CHAR | 250 | - | - | - |
| 13 | WAERS | | WAERS | CUKY | 5 | - | TCURC | - |
| 14 | ERNAM | | ERNAM | CHAR | 12 | - | - | - |
| 15 | ERDAT | | ERDAT | DATS | 8 | - | - | - |
| 16 | AENAM | | AENAM | CHAR | 12 | - | - | - |
| 17 | AEDAT | | AEDAT | DATS | 8 | - | - | - |

WAERS is NOT in the FS. It is mandatory: a CURR field cannot be activated without a
currency reference, so the three amount fields need it. Rows 14-17 are also not in the
FS; they are recommended because the table is maintained by TMG and by mass upload with
no other audit trail, and they are cheap to drop if functional objects. Flag both in the
build sheet rather than passing them off as FS content. Table logging (SE11 -> Technical
settings -> Log data changes) is the alternative to 14-17; say so.

Month is stored NUMC 6 as YYYYMM so that it sorts and compares correctly, and is
DISPLAYED as MM-YYYY (Parth Shah's comment). Never store it as MM-YYYY text.

## 4. Table maintenance generator (object 3)

Build sheet only, no code. Give: authorization group (&NC& unless functional names one),
function group ZSD_EXC_PAINTS, maintenance type 1 (one step), overview screen number
0001, recording routine "standard recording routine". Note that the TMG screen is NOT
serialised by abapGit and never appears in a ZIP.

## 5. ZSD_EXP_PAINTS_UPLOAD (object 4)

Purpose: mass insert and change of ZSD_EXP_PAINTS from a file, per FS "Data Upload and
change report is required for mass data entry".

### 5.1 Selection screen
BLOCK b1 "File"
  p_file  PARAMETER TYPE string OBLIGATORY, F4 via
          cl_gui_frontend_services=>file_open_dialog
  p_head  CHECKBOX DEFAULT 'X'  "first line is a header, skip it"
BLOCK b2 "Mode"
  p_ins   RADIOBUTTON GROUP md DEFAULT 'X'  "insert new records only"
  p_upd   RADIOBUTTON GROUP md              "insert new and change existing"
BLOCK b3 "Processing"
  p_test  CHECKBOX DEFAULT 'X'  "test run - validate only, no database update"

### 5.2 File format
Tab-delimited text, read with cl_gui_frontend_services=>gui_upload, filetype 'ASC',
has_field_separator 'X'. NOT an Excel binary: OLE-based Excel reads are fragile, size
limited and fail in ways that are hard to diagnose at a client site. The user does
File -> Save As -> Text (Tab delimited) in Excel. Document that in the template file.

Column order, which is also the template column order:
ZSRN, ZCUSTOMER, ZEXC_APPR_MONTH, ZEXC_APPR_TYPE, ZEXC_DATE_FROM, ZEXC_DATE_TO,
ZEXC_AMOUNT, ZCOMMIT_DATE, ZEX_AMNT, ZCM_AMNT, WAERS, ZREMARKS

Dates arrive as DD.MM.YYYY or DD/MM/YYYY. Month arrives as MM-YYYY or MM/YYYY and is
converted to YYYYMM on the way in. Amounts may carry thousand separators and must be
stripped before conversion.

### 5.3 Validation — every row, all errors collected, never stop at the first
1. ZSRN not initial and numeric.
2. ZCUSTOMER exists in KNA1 (one read for all rows, not per row).
3. ZEXC_APPR_MONTH parses to a valid YYYYMM, month 01-12.
4. ZEXC_APPR_TYPE in 1 / 2 / 3.
5. ZEXC_DATE_FROM, ZEXC_DATE_TO, ZCOMMIT_DATE parse to valid calendar dates.
6. ZEXC_DATE_TO >= ZEXC_DATE_FROM.
7. Amounts convert cleanly; a non-numeric amount is an error, not a silent zero.
8. WAERS exists in TCURC (one read for all rows).
9. Duplicate key inside the file itself is an error on the second and later occurrence.
10. In insert mode, a key already on the database is an error. In change mode it is an
    update. Read the existing keys ONCE with a FOR ALL ENTRIES, never per row.

### 5.4 Update
Only when p_test is off AND at least one row is valid. Valid rows are written with
`MODIFY zsd_exp_paints FROM TABLE @lt_upd` inside a single LUW, followed by
`COMMIT WORK AND WAIT`, with sy-subrc checked and a rollback plus an error message on
failure. Invalid rows are never written. Set ERNAM/ERDAT on insert and AENAM/AEDAT on
change, from sy-uname and sy-datum.

### 5.5 Log
ALV via REUSE_ALV_GRID_DISPLAY_LVC: file row number, status (icon: ICON_GREEN_LIGHT /
ICON_RED_LIGHT — use the constants from INCLUDE <icon>), the four key fields, and the
message. A closing message gives counts: read, valid, written, in error, and states
plainly when it was a test run.

## 6. ZSD_EXC_APPR_PAINTS (object 5)

Same skeleton as ZSD_EXC_APPR_ADHESIVE. Read that program before writing this one and
keep the FORM names, the ALV construction and the house style consistent with it.

### 6.1 Selection screen
BLOCK b1 "Exceptional Approval Data"
  s_kunnr  SELECT-OPTIONS FOR knvv-kunnr                   optional
  s_date   SELECT-OPTIONS FOR zsd_exp_paints-zexc_date_from OBLIGATORY
BLOCK b2 "Organisational Data"
  p_bukrs  PARAMETER TYPE knb1-bukrs   OBLIGATORY
  s_vkorg  SELECT-OPTIONS FOR knvv-vkorg OBLIGATORY
  s_spart  SELECT-OPTIONS FOR knvv-spart OBLIGATORY
  s_kvgr1  SELECT-OPTIONS FOR knvv-kvgr1 optional
  s_kvgr2  SELECT-OPTIONS FOR knvv-kvgr2 optional
  p_segmnt PARAMETER TYPE ukmbp_cms_sgm-credit_sgmnt OBLIGATORY
BLOCK b3 "Collection Document Selection"
  p_rldnr  PARAMETER TYPE acdoca-rldnr DEFAULT '0L' OBLIGATORY
  s_blart  SELECT-OPTIONS FOR acdoca-blart DEFAULT 'DZ' OBLIGATORY

Info Category and Info Type are deliberately absent — see C3.
p_rldnr and s_blart exist so that '0L' and 'DZ' are not hardcoded; the FS values are
their defaults.

### 6.2 Output structure — declare in EXACTLY this order
```
TYPES: BEGIN OF ty_output,
         kunnr        TYPE kna1-kunnr,
         name1        TYPE kna1-name1,
         l4_name      TYPE char40,
         l5_name      TYPE char40,
         l6_name      TYPE char40,
         exc_month    TYPE char7,                       " MM-YYYY
         exc_no       TYPE zsd_exp_paints-zsrn,
         exc_type     TYPE char30,
         date_from    TYPE zsd_exp_paints-zexc_date_from,
         date_to      TYPE zsd_exp_paints-zexc_date_to,
         exc_amnt     TYPE zsd_exp_paints-zexc_amount,
         cm_amnt      TYPE zsd_exp_paints-zcm_amnt,
         commit_date  TYPE zsd_exp_paints-zcommit_date,
         credit_limit TYPE ukmbp_cms_sgm-credit_limit,
         act_coll     TYPE acdoca-hsl,
         non_fulfil   TYPE acdoca-hsl,
         def_perc     TYPE p LENGTH 7 DECIMALS 2,
         status1      TYPE char25,
         status2      TYPE char15,
         remarks      TYPE zsd_exp_paints-zremarks,
         waers        TYPE t001-waers,
       END OF ty_output.
```
waers last, `no_out = abap_true`, currency reference for the amount columns.

### 6.3 FORMs, in this order
1. `f_get_customers` — KNB1 by p_bukrs, then KNVV by s_vkorg / s_spart / s_kvgr1 /
   s_kvgr2. SORT + DELETE ADJACENT DUPLICATES so a customer in several sales areas
   appears once. Empty -> message, LEAVE LIST-PROCESSING.
2. `f_get_approvals` — SELECT from zsd_exp_paints FOR ALL ENTRIES over the customer
   list, zcustomer = kunnr, zexc_date_from IN s_date. Field list order must match the
   TYPES component for component.
3. `f_get_names` — KNA1.
4. `f_get_credit_limits` — UKMBP_CMS_SGM with credit_sgmnt = p_segmnt.
5. `f_get_company_currency` — T001 SINGLE.
6. `f_get_hierarchy` — **STUB**, identical treatment to the Adhesives report: the FORM
   exists, is called, leaves L4/L5/L6 blank, contains only the commented explanation.
   No SELECT, no SUBMIT, no invented table.
7. `f_get_collections` — read ACDOCA ONCE for the whole customer set, never per row.
   Compute lv_min_date = lowest ZEXC_DATE_FROM and lv_max_date = highest ZCOMMIT_DATE
   across all approval rows first, and bound the read with them.
   `SELECT rbukrs, gjahr, belnr, docln, budat, blart, kunnr, hsl FROM acdoca`
   `FOR ALL ENTRIES IN @gt_cust WHERE rldnr = @p_rldnr AND rbukrs = @p_bukrs`
   `AND kunnr = @gt_cust-kunnr AND budat BETWEEN @lv_min_date AND @lv_max_date`
   `AND blart IN @s_blart AND kunnr <> @space`.
   Guarded by IS NOT INITIAL. No GJAHR filter — a collection window that crosses a
   fiscal year boundary must not be silently dropped.
8. `f_calc_collection` — USING customer, date_from, commit_date; CHANGING the amount.
   Pure in-memory over the table from step 7, keyed access on a SORTED table.
   An item counts when `budat >= date_from AND budat <= commit_date`.
   Sum `hsl`, then take the absolute value — a customer collection is a credit and is
   stored negative in ACDOCA, and the FS says to remove the sign.
9. `f_calc_status` — USING cm_amnt, act_coll, commit_date; CHANGING status1, status2.
   Status-1, in this order:
     - `cm_amnt - act_coll <= 0`                      -> 'Collection Received'
     - commit_date > sy-datum                         -> 'Commitment Not due'
     - otherwise (commit_date <= sy-datum)            -> 'Commitment Overdue'
   Status-2:
     - commit_date > sy-datum                         -> blank (not yet arrived)
     - act_coll >= cm_amnt                            -> 'Fulfilled'
     - act_coll <  cm_amnt                            -> 'Not Fulfilled'
   Exact equality is undefined in the FS and is treated as Fulfilled — mark it.
   Both statuses stay blank when commit_date is initial.
10. `f_build_output` —
    - exc_month from ZEXC_APPR_MONTH (NUMC 6 YYYYMM) as `mm && '-' && yyyy`, so
      `lv_m = month+4(2)` style offsets on a 6 character field: month(4) is the year,
      month+4(2) is the month. Get this the right way round.
    - exc_type: CASE on 1 / 2 / 3 to the readable description, via text symbols. Do not
      read DD07T.
    - non_fulfil = cm_amnt - act_coll  (see C2).
    - def_perc = non_fulfil * 100 / credit_limit, ONLY when credit_limit <> 0.
    - remarks from ZREMARKS.
11. `f_display_alv` — hand-built LVC_T_FCAT, readable headings, cfieldname 'WAERS' on
    exc_amnt / cm_amnt / credit_limit / act_coll / non_fulfil, waers no_out, EXCEPTIONS
    handled.

## 7. Deviations from the FS — each needs a `" ASSUMPTION:` note in the code

| # | FS says | Build does | Why | ISSUES.md |
|---|---|---|---|---|
| 1 | L4/L5/L6 from SAPLSLVC_FULLSCREEN | stub FORM, columns blank | it is the ALV function group, not a data source | 1 |
| 2 | Info Category / Info Type required on the screen | omitted | the Z table has no such field to filter on | 10 |
| 3 | Actual Collection BUDAT from the selection screen | per row, ZEXC_DATE_FROM to ZCOMMIT_DATE | reviewer comment, and a shared range double counts | 5 |
| 4 | sample implies Actual minus Credit Limit | ZCM_AMNT minus Actual Collection | the prose says so twice, the sample is copy-pasted from Adhesives | 6 |
| 5 | Default % over Actual Credit Limit | followed as written, zero guarded | looks wrong for a collection shortfall, but it is what the FS says | 7 |
| 6 | GJAHR filter on ACDOCA | no GJAHR filter, BUDAT bounded | a window crossing a fiscal year would lose rows | - |
| 7 | RLDNR '0L', BLART 'DZ' | selection screen with those defaults | no hardcoded values | - |
| 8 | ZEXC_AMNT in the output mapping | ZEXC_AMOUNT | the DDIC definition is authoritative | 8 |
| 9 | ZEX_AMNT declared | built, never read | no output column uses it | 8 |
| 10 | no currency field | WAERS added | a CURR field cannot activate without one | 9 |
| 11 | no audit fields | ERNAM/ERDAT/AENAM/AEDAT added | TMG plus mass upload with no audit trail | 9 |
| 12 | Status-2 equality undefined | equality is Fulfilled | FS covers only > and < | 12 |
| 13 | no credit segment | p_segmnt on the screen | CREDIT_LIMIT is per segment | 16 |
| 14 | SR. No. source unstated | required in the upload file | no number range confirmed; SNRO can be added later | 9 |

## 7a. Amendments — 05/09/26

| # | Section | Was | Now | Why |
|---|---|---|---|---|
| B1 | §6.3 point 7 | `FOR ALL ENTRIES IN @gt_cust` on ACDOCA, guard on `gt_cust` | `FOR ALL ENTRIES IN @gt_partner`, guard on `gt_partner` | only the customers that carry an approval are ever asked for in `f_calc_collection`; identical figures, far smaller ACDOCA read. Marked `*BOC By Arnav on 05/09/26` in the source |
| B2 | §6.3 point 4 | — | `" ASSUMPTION:` on the UKMBP_CMS_SGM read that BP number = customer number (ISSUES.md #18, shared with 141.A) | greppable, as §0 requires |
| B3 | §8 / `src/` | hand-written abapGit XML as of 03/09/26 | XML regenerated 05/09/26 in DDIC structure order, `REFKIND`, `CLIDEP`, `EXCLASS 4`, selection-text lengths fixed, ZIP without directory entries | `ZIP_IMPORT_NOTES.md` — the ZIP has still not been tried since |

## 8. Also deliver

- `ZSD_EXP_PAINTS_DDIC.md` — the SE11 build sheet for objects 1, 2 and 3: every domain,
  every data element, the table field list, technical settings, and the TMG settings,
  in the order Arnav creates them, with the not-in-FS rows clearly marked as such.
- `ZSD_EXP_PAINTS_UPLOAD_TEMPLATE.md` — the upload file layout, column by column, with
  the accepted formats, a worked example row, and the Excel "Save As tab delimited" note.
- `ZSD_EXC_APPR_PAINTS_TEXTS.md` and `ZSD_EXP_PAINTS_UPLOAD_TEXTS.md` — text symbols and
  selection texts for each program, reconciled against the source in both directions.
- `ZSD_EXC_APPR_PAINTS_TS.md` — the client technical spec covering all five objects,
  same shape as ZSD_EXC_APPR_ADHESIVE_TS.md.
- `VERIFY_IN_SE11_141B.md` — every DDIC name taken from the FS on trust rather than
  confirmed, ranked by which blocks activation first. ACDOCA-HSL / RLDNR / BLART / KUNNR
  and UKMBP_CMS_SGM-CREDIT_SGMNT belong here.
