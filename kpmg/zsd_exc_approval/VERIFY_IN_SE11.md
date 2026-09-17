# VERIFY_IN_SE11.md — pre-paste DDIC checklist for ZSD_EXC_APPR_ADHESIVE

> **Superseded 07/09/26.** `ZSD_EXC_APPR_ADHESIVE` activated on 07/09/26, which proves every
> DDIC name it references. The one FS-sourced name that was wrong — `INFOCATEGORY` /
> `INFOTYPE` on `BP3100` — is `ADDTYPE` / `DATA_TYPE` (`ISSUES.md`, 07/09/26). Kept for the
> record; nothing below needs checking again. The one DDIC name added since — table
> `ZSD_CUSTEMP_ASSG` with `KUNNR`, `LCATEGORY`, `LNAME`, `STARTVAL`, `ENDVAL` (17/09/26) — is
> proven by the activation of `ZSD_CUSTOMER_DATA`, which selects exactly those fields.

There is no ADT connection to this landscape and no way to syntax-check the program
before it is pasted into SE38. This file lists **every DDIC table and field the
program references whose exact name came from the FS (`fs/141A_extract.md`) rather
than from confirmed SAP-standard knowledge.** KNB1, KNVV, KNA1, T001, BSID and BSAD
and their fields used here are all long-standing SAP-standard structures and are
**not** repeated below — they are not FS-sourced guesses.

Go through this table top to bottom in SE11 **before** pasting. A wrong name in row 1
stops the whole program from activating; a wrong name lower down stops one FORM.

**Line numbers below are from the 02/09/26 snapshot (1247 lines).** The 05/09/26 edit
(ISSUES.md #17-#21) grew the file to 1415 lines, so locate by FORM name, never by line
number — CLAUDE.md says the same. The first paste on 02/09/26 already proved rows 1, 2,
4, 5 and the `p LENGTH 7 DECIMALS 2` / `charNN` types; only row 3 (`INFOTYPE`) and row 6
(`UKMBP_CMS_SGM` field names) remain genuinely unverified.

## How this is ordered

Highest risk first, where "risk" = (my confidence the FS-supplied name is exactly
right) combined with (how much of the program a wrong name takes down):

1. **BP3100** — the single lowest-confidence name in the program. It sits in the
   `TABLES` statement (line 38), the very first DDIC reference in the source, so if
   it is wrong or doesn't exist, nothing else in the program even gets checked.
2. **BP3100's own field list** (PARTNER, COUNTER, DATEFR, DATETO, AMNT, TEXT) — these
   feed `TY_APPR` and, through it, most of `TY_OUTPUT`. Each is an independent point
   of failure, and per CLAUDE.md they are matched to `TY_APPR` **by position**, not
   by name.
3. **BP3100-INFOTYPE** — used only in a `WHERE` clause, so a wrong name here is not
   caught anywhere else. `BP3100-INFOCATEGORY` is settled: it does not exist (the
   02/09/26 syntax check said so) and the repo copy no longer references it. INFOTYPE
   is the same class of name and was never reached by that check.
4. **UKM_INFOCAT** + INFOCATEGORY — drives the `p_infcat` parameter, its F4 and its
   validation.
5. **UKM_INFOTYP** + INFOTYPE + INFOCATEGORY — same pattern for `p_inftyp`, one step
   later in the flow.
6. **UKMBP_CMS_SGM** + PARTNER, CREDIT_SGMNT, CREDIT_LIMIT — read once, late, in
   `f_get_credit_limits`. Smallest blast radius (only that FORM and the arithmetic
   fed by it break), and the table itself is the one I have the most independent
   confidence in — UKMBP_CMS_SGM is a well-known FSCM Credit Management "BP credit
   segment data" table. The exact field names are still FS-supplied, not re-verified.

My confidence, stated per row, is genuinely mine, not a hedge — see the "Confidence"
column. Nothing here was re-verified against `DDLS_BASE_FIELDS.txt` or
`ARS_API_SUCCESSOR.xlsx`; those are not on this machine (per CLAUDE.md).

---

## 1. BP3100 — table existence

| | |
|---|---|
| **Confidence** | **Low.** I have no independent, certain knowledge that a standard table named exactly `BP3100` exists on S/4HANA 7.50+. It was taken verbatim from the FS's output-mapping table ("Customer \| BP3100 \| PARTNER \| Fetch", etc.). Treat it as unconfirmed until you look it up. |
| **Program assumes** | The table exists, is client-independent or client-dependent in the normal way (no `CLIENT SPECIFIED` is used), and is a transparent/pooled table selectable with Open SQL. |
| **Where used** | `TABLES: knvv, bp3100.` (line 38) — the first DDIC statement in the source. Also `FROM bp3100` in `f_get_approvals`, and every `TYPE bp3100-xxx` in the TYPES section. |
| **SE11 navigation** | SE11 → Database Table → enter `BP3100` → Display. If it says "does not exist", search instead: SE11 → F4 on the table field → type `BP3100*`; or SE16N → `BP3100` and see if it opens. If neither works, ask the functional consultant (Sanjay Modhvadiya, per the FS) which table actually backs "Business Partner → Further Information → Information category → Additional information in credit management" — that path is a BP transaction view, not necessarily this table name. |
| **If different** | Replace `bp3100` everywhere it appears — the `TABLES` statement (line 38), the `TYPE bp3100-xxx` references in `ty_appr` (lines 67–72) and `ty_output` (lines 140, 142–147), the `SELECT-OPTIONS s_date FOR bp3100-datefr` (line 187), and the `FROM bp3100` in `f_get_approvals` (line 499) — with the confirmed table name. |

---

## 2. BP3100 field list (position-matched into TY_APPR)

All six rows below are read together in one SELECT in `f_get_approvals`:
`SELECT partner, counter, datefr, dateto, amnt, text FROM bp3100 ...`. Per
CLAUDE.md, this field list and `TY_APPR`'s component list are matched **by
position, not by name** — if a field turns out to have a different name, only the
`TYPE` reference needs to change; if a field turns out not to exist at all, or a
field needs to be added, both the SELECT list and `TY_APPR` must be edited together
at the same index or later fields silently shift into the wrong component.

| Field | Confidence | Program assumes | SE11 navigation | If different |
|---|---|---|---|---|
| `PARTNER` | Low (inherits BP3100's own uncertainty) | Customer-number-compatible: assigned to/from `KNA1-KUNNR`-typed fields (`ls_out-kunnr = ls_appr-partner`, `WHERE partner = @gt_cust-kunnr`). | SE11 → BP3100 → Fields tab → confirm `PARTNER` exists, note its data element/domain length (expect 10 chars, BU_PARTNER-like). | Edit `TYPE bp3100-partner` in `ty_appr` (line 67) and the field name in the SELECT list (line 498) and the WHERE clause (line 501). |
| `COUNTER` | Low | Used as `TY_OUTPUT-EXC_NO` and as a table key component in `READ TABLE gt_cdate WITH KEY partner counter` — needs to reliably distinguish multiple approval rows for the same partner. | SE11 → BP3100 → Fields tab → confirm `COUNTER` exists and is part of (or at least unique alongside) the table key. | Edit `TYPE bp3100-counter` (line 68) and the SELECT list (line 498). |
| `DATEFR` | Low | **Offset-accessed**: `ls_appr-datefr+4(2) && '/' && ls_appr-datefr(4)` (line 1032) builds `MM/YYYY`. This requires DATEFR to be a fixed 8-character, YYYYMMDD-laid-out field (i.e. type `DATS` or equivalent) — a shorter static length is a **compile error** ("offset/length not defined"), and a different layout compiles fine but produces a wrong month/year silently. Also drives `SELECT-OPTIONS s_date FOR bp3100-datefr` and the `datefr IN @s_date` filter. | SE11 → BP3100 → Fields tab → `DATEFR` → check Data Element → Domain → confirm type `DATS`, length 8. | If it is not DATS/8-char-YYYYMMDD: edit `TYPE bp3100-datefr` (line 69) and rewrite the `exc_month` build in `f_build_output` (around line 1032) to match the real layout instead of the fixed offsets. |
| `DATETO` | Low | Only moved straight across to `TY_OUTPUT-DATE_TO`, no offset access — lower risk than DATEFR. | SE11 → BP3100 → Fields tab → confirm `DATETO` exists. | Edit `TYPE bp3100-dateto` (line 70) and the SELECT list (line 498). |
| `AMNT` | Low | Assumed to be a currency-amount type (`CURR`), since the ALV fieldcat pairs `EXC_AMNT` with `cfieldname = 'WAERS'` (line 1164) for currency-aware display. Not used in arithmetic, so a plain numeric type would still activate, just might not format as a currency. | SE11 → BP3100 → Fields tab → `AMNT` → check Domain is CURR-based with 2 decimals. | Edit `TYPE bp3100-amnt` (line 71) and the SELECT list (line 498); if not a currency type, also drop `'WAERS'` from the `f_add_fcat` call for `EXC_AMNT` (line 1163–1164) since a currency reference on a non-currency field can misdisplay. |
| `TEXT` | Low | Free-text, character-like, long enough to carry a commitment-date token plus surrounding words. Passed to `f_parse_commit_date` as `USING iv_text TYPE bp3100-text` and converted with `lv_string = iv_text` (works for any char-like or numeric type; only a genuinely binary/raw type would break this). | SE11 → BP3100 → Fields tab → `TEXT` → check Domain/length (expect a STRING or long CHAR). | Edit `TYPE bp3100-text` (line 72) and the SELECT list (line 498). |

---

## 3. BP3100-INFOTYPE — the one WHERE-clause-only field left (INFOCATEGORY is settled)

| | |
|---|---|
| **What happened** | The first paste on 02/09/26 failed its syntax check on exactly this SELECT with **"Unknown column name INFOCATEGORY"**. So `BP3100` has **no** column of that name — settled, no SE11 check needed. Arnav corrected the WHERE clause by hand in SE38 and the program is active; the corrected clause was not sent back (ISSUES.md #17). |
| **Repo copy since 05/09/26** | `f_get_approvals` filters `WHERE partner = @gt_cust-kunnr AND infotype = @p_inftyp AND datefr IN @s_date`. The information category is no longer filtered in SQL; it is enforced on the selection screen, where `AT SELECTION-SCREEN ON p_inftyp` requires the `P_INFCAT` / `P_INFTYP` pair to exist in `UKM_INFOTYP`. The only leak is a type code that exists under two categories — flagged in the `" ASSUMPTION:` above the SELECT. |
| **Confidence** | **Still low on `INFOTYPE`.** The syntax check stopped at the first error, so `BP3100-INFOTYPE` was never reached. It is the same class of name INFOCATEGORY was: asserted by the FS, unverified. |
| **SE11 navigation** | SE11 → BP3100 → Fields tab → look for `INFOTYPE`. While there, note whether a category column exists under another name (`INFOCAT`, `INFO_CATEGORY`, …) and what the table key is (`PARTNER` + `COUNTER` alone, or with `DATEFR` / an info-type field). Better still: `ZR_PROG_DOWNLOAD` the active `ZSD_EXC_APPR_ADHESIVE` and diff it against the repo copy — that answers both questions without SE11. |
| **If different** | Edit the `infotype` line inside the BOC/EOC block of `f_get_approvals` only — `TY_APPR` does not reference the field. If BP3100 turns out to carry a category column, add it back to the WHERE under its real name and drop the ASSUMPTION paragraph. If the category/type mechanism is structurally different, this FORM needs a redesign, not a rename — flag it. |

---

## 4. UKM_INFOCAT — table + INFOCATEGORY field

| | |
|---|---|
| **Confidence** | **Medium.** `UKM_*` is SAP's internal namespace for FSCM Credit Management, and an "information category" master behind the BP credit-management "Additional Information" UI is a plausible, named-in-the-FS SAP-standard object. I have not independently confirmed the exact table name `UKM_INFOCAT`, only that the naming pattern is consistent with real FSCM Credit Management tables. |
| **Program assumes** | `INFOCATEGORY` is a short, F4-able character field. Used as the `TYPE` for `PARAMETERS p_infcat` (line 185), in the F4 help `SELECT DISTINCT infocategory FROM ukm_infocat` (lines 222–225), and in the validation `SELECT SINGLE infocategory FROM ukm_infocat WHERE infocategory = @p_infcat` (lines 363–366). No length is hardcoded in the program, so a wrong *length* is not an activation risk — only a wrong *name* is. |
| **SE11 navigation** | SE11 → Database Table → `UKM_INFOCAT` → Display → Fields tab → confirm `INFOCATEGORY` exists. Cross-check in SE16N by browsing a few rows to confirm it is really a category list (not, say, a customizing view name that SE11 resolves differently). |
| **If different** | Edit `TYPE ukm_infocat-infocategory` on the `PARAMETERS p_infcat` line (185), the `FROM ukm_infocat` / field name in the F4 SELECT (lines 222–225), and the same in the validation SELECT (lines 363–366). Three places, all inside `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_infcat` and the two validation blocks — no other FORM touches this table. |

---

## 5. UKM_INFOTYP — table + INFOTYPE + INFOCATEGORY (FK filter)

| | |
|---|---|
| **Confidence** | **Medium**, same basis as UKM_INFOCAT — plausible FSCM naming, not independently confirmed. |
| **Program assumes** | `INFOTYPE` is a short, F4-able character field, dependent on `INFOCATEGORY` as a foreign key. Used as the `TYPE` for `PARAMETERS p_inftyp` (line 186), in the F4 help `SELECT DISTINCT infotype FROM ukm_infotyp WHERE infocategory = @lv_infcat` (lines 302–306), and in validation `SELECT SINGLE infotype FROM ukm_infotyp WHERE infocategory = @p_infcat AND infotype = @p_inftyp` (lines 381–385). Both `INFOTYPE` and `INFOCATEGORY` must exist on this table — a wrong name on either one breaks all three statements. |
| **SE11 navigation** | SE11 → Database Table → `UKM_INFOTYP` → Display → Fields tab → confirm both `INFOTYPE` and `INFOCATEGORY` exist, and that `INFOCATEGORY` here is the same domain as `UKM_INFOCAT-INFOCATEGORY` above (so a category picked on screen actually filters this table). |
| **If different** | Edit `TYPE ukm_infotyp-infotype` on `PARAMETERS p_inftyp` (line 186), the `FROM ukm_infotyp` / field names in the F4 SELECT (lines 302–306), and the validation SELECT (lines 381–385). All inside `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_inftyp` and its validation block. |

---

## 6. UKMBP_CMS_SGM — table + PARTNER, CREDIT_SGMNT, CREDIT_LIMIT

| | |
|---|---|
| **Confidence** | **Medium-high on the table itself** — UKMBP_CMS_SGM is a table I recognise with reasonable confidence as SAP's standard "Business Partner Credit Management: Segment Data" table, the usual home of a partner's credit limit per credit segment. **Low-medium on the exact field names** `CREDIT_SGMNT` / `CREDIT_LIMIT` — these are FS-supplied and not independently re-verified against the actual DDIC (`DDLS_BASE_FIELDS.txt` is unavailable on this machine). |
| **Program assumes** | `PARTNER` joins to the customer/partner number (`WHERE partner = @gt_partner-kunnr`, `f_get_credit_limits`, line 571). `CREDIT_SGMNT` types `PARAMETERS p_segmnt` (line 199) and filters the same SELECT (`AND credit_sgmnt = @p_segmnt`, line 572) — this parameter exists specifically **because** the build spec assumes the table is keyed by partner AND segment (an explicit `" ASSUMPTION"` already in the code, build spec §1 / open issue 16). `CREDIT_LIMIT` is a **numeric** type: it feeds `ty_output-credit_limit` and is used directly in arithmetic — `non_fulfil = act_os - credit_limit` (line 1070) and the `def_perc` division (line 1076) — against `DMBTR`-typed `act_os`. If `CREDIT_LIMIT` were a non-numeric type this arithmetic would fail to activate, not just misbehave; a numeric type with a different currency/decimal convention than DMBTR activates fine but is a business-accuracy risk already flagged in the code as an `" ASSUMPTION"` (company-code currency vs segment currency). |
| **SE11 navigation** | SE11 → Database Table → `UKMBP_CMS_SGM` → Display → Fields tab → confirm `PARTNER`, `CREDIT_SGMNT` and `CREDIT_LIMIT` all exist by those exact names, and check `CREDIT_LIMIT`'s Data Element/Domain is a CURR (or otherwise numeric) type with a currency reference. SE16N on the same table with a known test partner is the fastest way to also confirm CREDIT_SGMNT holds the kind of value the user will type into `p_segmnt` (e.g. a 4-char segment code). |
| **If different** | Edit `TYPE ukmbp_cms_sgm-partner` / `-credit_sgmnt` / `-credit_limit` in `ty_climit` (lines 88–90), the `PARAMETERS p_segmnt TYPE ukmbp_cms_sgm-credit_sgmnt` line (199), and the SELECT field list / WHERE clause in `f_get_credit_limits` (lines 568–572). All confined to that one FORM plus the two `TYPES`/`PARAMETERS` declarations — nothing else in the program touches this table. |

---

## What is deliberately NOT in this file

- KNB1, KNVV, KNA1, T001, BSID, BSAD and all fields read from them (BUKRS, KUNNR,
  VKORG, KVGR1, KVGR2, NAME1, WAERS, BELNR, BUZEI, BUDAT, WRBTR, DMBTR, SHKZG,
  REBZG, AUGDT) — long-standing SAP-standard structures, not FS-sourced guesses.
- `DDSHRETVAL`, `DYNPREAD` and the `F4IF_INT_TABLE_VALUE_REQUEST` /
  `DYNP_VALUES_READ` function module interfaces — standard, not FS-sourced.
- The **L4/L5/L6 hierarchy source** (build spec deviation 1) — not a DDIC-lookup
  question at all. `f_get_hierarchy` is a deliberate stub; there is nothing to
  verify in SE11 until functional names a real source table.
- The **Exceptional Approval Type** column (build spec deviation 5) — same reason,
  no source field exists yet to verify.
