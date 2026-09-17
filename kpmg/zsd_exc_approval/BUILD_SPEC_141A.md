# BUILD SPEC — ZSD_EXC_APPR_ADHESIVE (WRICEF 141.A)

Locked technical contract. Every implementer and reviewer works from THIS file.
Where this spec and the FS disagree, this spec wins and the deviation is listed in
"Deviations from the FS" below.

Program : ZSD_EXC_APPR_ADHESIVE
Type    : Executable report (type 1), screen-free
Title   : Exceptional Approval Report - Adhesives
Package : Z-package for the UDAY SD track (Arnav assigns in SE38)
Author  : Arnav, Diligent · client Astral Limited · project UDAY
ALV     : REUSE_ALV_GRID_DISPLAY_LVC, full screen, hand-built LVC_T_FCAT
Ships by: PASTE (screen-free, so a ZIP is possible later, but hand-written abapGit
          XML has never imported on this landscape — do not promise one)

## 0. Non-negotiable house rules (from CLAUDE.md)

- Source lines strictly under 120 characters. Long notes go in a `*` block ABOVE the
  statement, never trailing it.
- Strict Open SQL only: comma-separated field lists; `@` on EVERY host variable, host
  expression and inline declaration — `INTO TABLE @lt_tab`, `INTO @DATA(ls_x)`,
  `FOR ALL ENTRIES IN @lt_src`, `WHERE bukrs = @p_bukrs`.
- Clause order: `INTO` / `APPENDING` comes AFTER `ORDER BY`; `UP TO n ROWS` and
  `OFFSET` come AFTER `INTO`.
- `IS NOT INITIAL` guard before EVERY `FOR ALL ENTRIES`.
- No `SELECT` inside a `LOOP`. Ever. Read once into an internal table, then read that.
- `DELETE ADJACENT DUPLICATES` needs a matching `SORT` outside any loop, on exactly the
  fields the DELETE compares.
- No hardcoded clients, dates or company codes.
- Error paths give the user a message — no short dump, no silent skip.
- Selection texts and column headings are readable words, not technical names.
- Risky assumptions go in the code as `" ASSUMPTION: ...` so they are greppable.
- A field list and its target TYPES are matched by POSITION, not name. Re-check both
  lists together after any edit.
- Complete object, first line to last. No "... existing code ..." placeholders.

## 1. Selection screen

Two blocks with frames and titles.

BLOCK b1 "Exceptional Approval Data"
  s_kunnr  SELECT-OPTIONS FOR knvv-kunnr                       optional
  p_infcat PARAMETER TYPE ukm_infocat-infocategory  OBLIGATORY  F4 (see 1.1)
  p_inftyp PARAMETER TYPE ukm_infotyp-infotype      OBLIGATORY  F4 dependent on p_infcat
  s_date   SELECT-OPTIONS FOR bp3100-datefr         OBLIGATORY  (approval date from)

BLOCK b2 "Organisational Data"
  p_bukrs  PARAMETER TYPE knb1-bukrs   OBLIGATORY   (standard F4 via DDIC)
  s_vkorg  SELECT-OPTIONS FOR knvv-vkorg OBLIGATORY
  s_kvgr1  SELECT-OPTIONS FOR knvv-kvgr1 optional
  s_kvgr2  SELECT-OPTIONS FOR knvv-kvgr2 optional
  p_segmnt PARAMETER TYPE ukmbp_cms_sgm-credit_sgmnt OBLIGATORY

`p_segmnt` is NOT in the FS. It exists because UKMBP_CMS_SGM is keyed by partner AND
credit segment, so CREDIT_LIMIT is ambiguous without it (open issue 16). Mark it in the
code with `" ASSUMPTION:` and give it no hardcoded default.

### 1.1 F4 help
- `p_infcat`: AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infcat. SELECT the distinct
  INFOCATEGORY values from UKM_INFOCAT, call F4IF_INT_TABLE_VALUE_REQUEST with
  retfield 'INFOCATEGORY', dynpronr/dynprofield set so the value is written back,
  value_org 'S'. Do NOT read a text table — its name is unverified.
- `p_inftyp`: same pattern over UKM_INFOTYP, but SELECT `WHERE infocategory = @p_infcat`.
  Read p_infcat off the screen first with DYNP_VALUES_READ so the F4 reflects what the
  user has typed but not yet ENTERed. If p_infcat is still blank, message the user
  ("Enter the information category first") and leave the F4 empty — no dump.

### 1.2 Validation (AT SELECTION-SCREEN)
- p_bukrs exists in T001, else error message on the field.
- p_infcat exists in UKM_INFOCAT, else error.
- p_inftyp exists in UKM_INFOTYP for that category, else error.
- p_segmnt: no existence check (customizing table name unverified) — leave it.

## 2. Output structure — declare in EXACTLY this order

```
TYPES: BEGIN OF ty_output,
         kunnr        TYPE kna1-kunnr,
         name1        TYPE kna1-name1,
         l4_name      TYPE char40,
         l5_name      TYPE char40,
         l6_name      TYPE char40,
         exc_month    TYPE char7,                        " MM/YYYY
         exc_no       TYPE bp3100-counter,
         exc_type     TYPE char30,
         date_from    TYPE bp3100-datefr,
         date_to      TYPE bp3100-dateto,
         exc_amnt     TYPE bp3100-amnt,
         commit_date  TYPE dats,
         commit_text  TYPE bp3100-text,
         credit_limit TYPE ukmbp_cms_sgm-credit_limit,
         act_os       TYPE dmbtr,
         non_fulfil   TYPE dmbtr,
         def_perc     TYPE p LENGTH 7 DECIMALS 2,
         status       TYPE char15,
         waers        TYPE t001-waers,
       END OF ty_output.
```

`waers` is last on purpose: it is the ALV currency reference field for the amount
columns, not a business column. Set its fieldcat `no_out = abap_true`.

## 3. Processing — one FORM per step, in this order

Locate by FORM name, never by line number.

1. `f_get_customers`
   - SELECT kunnr FROM knb1 WHERE bukrs = @p_bukrs AND kunnr IN @s_kunnr
     INTO TABLE @DATA(lt_knb1).
   - guard IS NOT INITIAL, then SELECT kunnr FROM knvv FOR ALL ENTRIES IN @lt_knb1
     WHERE kunnr = @lt_knb1-kunnr AND vkorg IN @s_vkorg AND kvgr1 IN @s_kvgr1
     AND kvgr2 IN @s_kvgr2.
   - SORT by kunnr, DELETE ADJACENT DUPLICATES COMPARING kunnr. A customer extended to
     several sales areas must appear ONCE (open issue 13).
   - Empty result -> message "No customers match the selection" type S display like E,
     then LEAVE LIST-PROCESSING. No dump.

2. `f_get_approvals`
   - guard, then SELECT partner, counter, datefr, dateto, amnt, text FROM bp3100
     FOR ALL ENTRIES IN @gt_cust
     WHERE partner = @gt_cust-kunnr AND infocategory = @p_infcat
       AND infotype = @p_inftyp AND datefr IN @s_date.
   - Field list order must match the TYPES of the target table position for position.
   - Empty -> message, LEAVE LIST-PROCESSING.

3. `f_get_names`      — KNA1 kunnr, name1 FOR ALL ENTRIES over the approval partners.
4. `f_get_credit_limits` — UKMBP_CMS_SGM partner, credit_sgmnt, credit_limit
                           FOR ALL ENTRIES, WHERE credit_sgmnt = @p_segmnt.
5. `f_get_company_currency` — single SELECT SINGLE waers FROM t001 WHERE bukrs = @p_bukrs.

6. `f_get_hierarchy`  — **STUB.** L4/L5/L6 source is unknown: the FS names
   SAPLSLVC_FULLSCREEN, which is the generic ALV full-screen function group — it holds
   no data and cannot be SUBMITted. The FORM must exist, be called, take the customer
   table as CHANGING, and contain ONLY a commented block explaining what goes here plus
   the `" ASSUMPTION:` note. It must leave l4/l5/l6 blank without erroring. Do not invent
   a table. Do not SUBMIT anything.

7. `f_parse_commit_date` — USING iv_text TYPE bp3100-text, CHANGING cv_date TYPE dats.
   BP3100-TEXT is free text, so parsing must be defensive:
   - accept DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY, and 8-digit YYYYMMDD;
   - ignore surrounding words — scan the string for the first token that parses;
   - validate the result with a date check (day/month range, and reject 00000000);
   - on failure return initial. Never dump, never message per row.
   Rows with an unparseable commitment date still appear in the ALV, with commit_date
   blank, act_os / non_fulfil / def_perc zero and status blank, and commit_text shown so
   the user can see what was typed.

8. `f_get_open_items` — read ONCE for the whole customer set, never inside a loop.
   Compute lv_max_date = the highest parsed commitment date and lv_min_date = the lowest
   before selecting, and use them to bound the reads.
   - Open now: SELECT bukrs, kunnr, belnr, buzei, budat, wrbtr, dmbtr, shkzg, rebzg
     FROM bsid FOR ALL ENTRIES IN @gt_cust
     WHERE bukrs = @p_bukrs AND kunnr = @gt_cust-kunnr AND budat <= @lv_max_date.
   - Cleared after the commitment date: same field list plus augdt FROM bsad
     WHERE bukrs = @p_bukrs AND kunnr = @gt_cust-kunnr AND budat <= @lv_max_date
       AND augdt > @lv_min_date.
   - Both guarded by IS NOT INITIAL. Skip the whole FORM if no row has a parsed date.

9. `f_calc_open_amount` — USING customer + commitment date, RETURNING/CHANGING the
   amount. Pure in-memory arithmetic over the tables read in step 8:
   - a BSID item counts if `budat <= commitment date`;
   - a BSAD item counts if `budat <= commitment date AND augdt > commitment date`
     (it was still open on that date, cleared later);
   - sign: `shkzg = 'S'` adds, `shkzg = 'H'` subtracts.
   Use a sorted or hashed secondary key on kunnr so this is not a linear scan per row.

10. `f_build_output` — assemble ty_output per approval row:
    - exc_month = DATEFR MM/YYYY, built as `datefr+4(2) && '/' && datefr(4)`.
    - exc_type  = blank. Source field unknown (open issue 2) — `" ASSUMPTION:` note,
      column still present in the ALV so the layout matches the FS.
    - non_fulfil = act_os - credit_limit.
    - def_perc  = non_fulfil * 100 / credit_limit, ONLY when credit_limit <> 0;
      otherwise zero. Never divide by zero.
    - status: non_fulfil > 0 -> 'Not Fulfilled'; non_fulfil <= 0 -> 'Fulfilled'
      (the FS leaves exactly zero undefined; zero is treated as Fulfilled — mark it).
    - status stays blank when commit_date is initial.
    All literal user-facing strings come from TEXT SYMBOLS, not hardcoded literals.

11. `f_display_alv` — build LVC_T_FCAT by hand, one entry per column, readable
    `scrtext_l` / `scrtext_m` / `scrtext_s` and `reptext`. Set `cfieldname = 'WAERS'`
    on exc_amnt, credit_limit, act_os and non_fulfil. Mark waers `no_out`. Call
    REUSE_ALV_GRID_DISPLAY_LVC with i_save 'A', a layout with `zebra` and
    `cwidth_opt` set, and EXCEPTIONS handled — a non-zero sy-subrc raises a message,
    not a dump.

## 4. Deviations from the FS — every one must carry a `" ASSUMPTION:` in the code

| # | FS says | Build does | Why |
|---|---|---|---|
| 1 | L4/L5/L6 from SAPLSLVC_FULLSCREEN | stub FORM, columns blank | that is the ALV function group, not a data source |
| 2 | Actual OS from BSID by GJAHR | BSID + BSAD bounded by BUDAT and AUGDT, no GJAHR filter | BSID holds items open NOW; an item cleared after the commitment date must still count as open on that date. Open items also span fiscal years, so a GJAHR filter drops them |
| 3 | fetch WRBTR | uses DMBTR, selects both | WRBTR is document currency; the credit limit is not. DMBTR is company-code currency and comparable. Switching back is a one-line change |
| 4 | REBZG blank / not blank as two steps | single read, no REBZG filter | the two FS steps together are simply "all items"; REBZG (invoice reference) does not change the sum |
| 5 | approval type column | column present, always blank | no source field given |
| 6 | commitment date "fetch" from TEXT | defensive parse | TEXT is free text |
| 7 | no credit segment | p_segmnt on the selection screen | CREDIT_LIMIT is per segment |
| 8 | status for zero non-fulfilment | 'Fulfilled' | FS covers only (+) and (-) |
| 9 | KNVV-keyed customer selection | one row per customer after SORT + DELETE ADJACENT DUPLICATES | a customer in several sales areas would otherwise multiply rows (open issue 13) |
| 10 | required "Date" range, no table/field | applied to BP3100-DATEFR | the only date the FS ties to an approval (open issue 11) |
| 11 | "Authorization TBD" | no authorization check built | nothing confirmed to check against (open issue 15) |
| 12 | no division on the Adhesives input table | `s_spart`, optional, added 05/09/26 | the FS reviewer comment asks for it; blank = all divisions (open issue 20) |

Rows 9-11 were tagged in the source on 05/09/26 (they were built from the start but
carried no `" ASSUMPTION:`); row 12 is new. The TS (`ZSD_EXC_APPR_ADHESIVE_TS.md` §7)
numbers the same rows identically and adds 13-15 for the BP3100 filter, the BP-number
assumption and the "all BSID/BSAD lines" assumption, which carry untagged ASSUMPTION
notes in the source.

## 4a. Amendments — 05/09/26

The contract above is kept as written; these amendments override it where they
conflict. Each is marked in the source with a `*BOC By Arnav on 05/09/26` block and is
logged in `ISSUES.md` #17-#21.

| # | Section | Was | Now | Why |
|---|---|---|---|---|
| A1 | §3 step 2 | `WHERE ... AND infocategory = @p_infcat AND infotype = @p_inftyp` | ~~`AND infotype = @p_inftyp` only~~ **Superseded 07/09/26:** `AND addtype = @p_infcat AND data_type = @p_inftyp` — the real BP3100 columns, confirmed by activation | BP3100 has neither INFOCATEGORY nor INFOTYPE |
| A2 | §3 step 2 | rows in database order | `SORT gt_appr BY partner datefr counter` right after the empty check; nothing re-sorts it later | grouped per customer as in the FS layout; deterministic between runs; lets A3 read by index |
| A3 | §3 steps 7/8/10 | commitment dates cached in a sorted table keyed PARTNER + COUNTER | standard table, one row per GT_APPR row, read by index in `f_build_output` | PARTNER + COUNTER is not confirmed unique in BP3100 |
| A4 | §3 step 8 | `FOR ALL ENTRIES IN @gt_cust` on BSID and BSAD | `FOR ALL ENTRIES IN @gt_partner` | only approval partners are ever asked for; identical figures, far smaller read on a large BSID/BSAD |
| A5 | §1 block b2 | no division | `s_spart FOR knvv-spart`, optional, applied to the KNVV read | FS reviewer comment (Yogesh Vanani) asks for division; blank = all divisions |
| A6 | §3 step 7 | DD.MM.YYYY / DD/MM/YYYY / DD-MM-YYYY / YYYYMMDD | ~~two-digit year and month-first order added~~ **Dropped 07/09/26:** functional confirmed DD.MM.YYYY; the bare YYYYMMDD branch is removed too, `/` and `-` still accepted as separators | the confirmed format wins over a defensive parse |
| A7 | §4 | eight deviations | rows 9-12 added to the table above and tagged in the source; BP-number = customer-number and "all BSID/BSAD lines summed" are ASSUMPTION notes too (ISSUES.md #18, #19) | every deviation greppable, as §0 requires |

## 4b. Amendments — 07/09/26 and 17/09/26

| # | Section | Was | Now | Why |
|---|---|---|---|---|
| A8 | §2 / §3 step 10 | `exc_type` component and "Approval Type" column, always blank | component, `CLEAR` and field-catalogue entry removed; columns after it renumbered 8 to 18; text symbol C08 unused | functional confirmed 07/09/26 the column is not required (ISSUES.md #2 closed) |
| A9 | §1 / §1.1 / §1.2 | `P_INFCAT` / `P_INFTYP` typed off `UKM_INFOCAT` / `UKM_INFOTYP`, F4 and checks from those tables | typed off `BP3100-ADDTYPE` / `BP3100-DATA_TYPE`; F4 and checks read the distinct values in BP3100 itself | the customizing field names are unconfirmed on this landscape; BP3100's own values cannot be wrong |
| A10 | §1 block b1 | no credit segment | `P_SEGMNT` obligatory, default `2000` | functional confirmed the segment 07/09/26 (ISSUES.md #16 closed) |
| A11 | §3 step 6 | hierarchy read by the four `GC_HIER_F_*` names through `ASSIGN COMPONENT`; a wrong level name leaves the level silently blank | names resolved at runtime from the callee's structure (`F_HIER_FIELD`: exact name, else first field containing `L4`/`L5`/`L6`, or `KUNNR` then `CUST`); when the customer, all three levels, or the merge fail, the status message ends with the callee's field names; empty callee result reported as M15 | functional testing 17/09/26 showed L4/L5/L6 blank with the real program name — the placeholders do not match `ZSD_CUSTOMER_DATA` (ISSUES.md #26) |
| A12 | §3 step 6 | only `S_VKORG` passed to the callee | approval partners from `GT_PARTNER` passed as well under placeholder `S_KUNNR` (`GC_HIER_SELKUN`) | a right name makes the callee run for a handful of customers; a wrong one is ignored by `SUBMIT` |

## 5. Also deliver

- `ZSD_EXC_APPR_ADHESIVE_TEXTS.md` — the text symbols and selection texts as two
  tables, ready to type into SE38 -> Goto -> Text Elements. Every text symbol
  referenced in the source must appear, with its number, and no text symbol may be
  referenced that is not listed.
- `ZSD_EXC_APPR_ADHESIVE_TS.md` — the technical spec document for the client, matching
  the shape used elsewhere in this repo: object header, purpose, selection screen,
  tables used, processing logic, output layout, assumptions and open points, unit test
  scenarios.
- `VERIFY_IN_SE11.md` — every DDIC name this program references that came from the FS
  rather than from confirmed knowledge, with the exact SE11/SE16 navigation for Arnav
  to confirm before pasting.
