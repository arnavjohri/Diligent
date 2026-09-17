# VERIFY_IN_SE11_141B.md — pre-paste DDIC checklist for WRICEF 141.B

> **Superseded 07/09/26.** `ZSD_EXC_APPR_PAINTS` and `ZSD_EXP_PAINTS_UPLOAD` both activated
> on 07/09/26, which proves every DDIC name in them, the Z table and its domains and data
> elements included. Kept for the record; nothing below needs checking again.

Covers both Paints programs:

- `ZSD_EXC_APPR_PAINTS` (982 lines) — the output report
- `ZSD_EXP_PAINTS_UPLOAD` (1522 lines) — the mass upload / change report

There is no ADT connection to this landscape and no way to syntax-check either program
before it is pasted into SE38. This file lists **every DDIC name in the two programs
whose exact spelling came from the FS or from `BUILD_SPEC_141B.md` rather than from
knowledge I can genuinely vouch for.** Work through it top to bottom in SE11 **before**
pasting anything.

**Line numbers are from the 02/09/26 snapshot** (report 982 lines, upload 1522). The
report grew to 1012 lines on 05/09/26 (ACDOCA read driven by `gt_partner`, one extra
ASSUMPTION block in `f_get_credit_limits`); the upload is unchanged. Locate by FORM name.

## Why this file exists in this form

The sibling object `ZSD_EXC_APPR_ADHESIVE` has just failed its first activation. One
error, and it was exactly this: **"Unknown column name INFOCATEGORY"** — a `WHERE`-clause
field name the FS asserted, that nobody looked up, that appeared nowhere else in the
program so nothing else contradicted it. A field name out of a functional spec is not
knowledge. Every row below is therefore graded on *my* confidence, and the rows I
genuinely vouch for are marked as such and separated from the rows taken on trust.

## How this is ordered

By blast radius — **what stops activation earliest comes first**, and where two rows stop
at the same point, the one that takes down both programs comes first. In practice:

| # | Item | First reference | Stops |
|---|---|---|---|
| 1 | `ZSD_EXP_PAINTS` exists and is **active** | report line 57 / upload line 114 | both programs, at their first DDIC reference |
| 2 | `ACDOCA` — table name | report line 58 | the output report, at line 58 |
| 3 | `ZSD_EXP_PAINTS` — the 16 column names | report line 92 / upload line 114 | both programs, in the TYPES block |
| 4 | `UKMBP_CMS_SGM` — PARTNER / CREDIT_SGMNT / CREDIT_LIMIT | report line 110 | the output report, in the TYPES block |
| 5 | `ACDOCA` — the 9 column names | report line 119 | the output report, in the TYPES block |
| 6 | `TCURC` — WAERS | upload line 170 | the upload program, in the TYPES block |
| 7 | `CHAR25` / `LOCALFILE` — reused standard type names | report line 151 / upload line 231 | one TYPES line or one PARAMETERS line |

Rows 1–5 are all **activation stoppers in the declaration part**, not FORM-local errors.
Unlike the Adhesives failure, none of them is hidden in a single `WHERE` clause — the
Paints design carries every FS-sourced name into a `TYPES` component, so a wrong name
surfaces on the first syntax check rather than at the twentieth. That is the one piece of
luck in this build; do not spend it by skipping the checks.

## What I genuinely vouch for, and is therefore NOT in this file

KNB1, KNVV, KNA1, T001 and their fields (BUKRS, KUNNR, VKORG, SPART, KVGR1, KVGR2, NAME1,
WAERS); `LVC_T_FCAT` / `LVC_S_FCAT` / `LVC_S_LAYO` and `REUSE_ALV_GRID_DISPLAY_LVC`;
`CL_GUI_FRONTEND_SERVICES` methods `FILE_OPEN_DIALOG` and `GUI_UPLOAD`; `INCLUDE <icon>`
with `ICON_GREEN_LIGHT` / `ICON_RED_LIGHT`; `CONVERSION_EXIT_ALPHA_INPUT`. All
long-standing SAP standard, none of them FS-sourced.

Also **confirmed by the sibling's own failure**, which is worth stating because it is real
evidence rather than my opinion: the Adhesives program reported *one* error and it was on
line ~501. Everything the syntax check reached before that line resolved, including
`TYPE char40`, `TYPE char7`, `TYPE char30`, `TYPE char15` and
`TYPE p LENGTH 7 DECIMALS 2`. Those five are settled on this landscape. `CHAR25` is
**not** — see row 7; it is new in Paints.

---

## 1. ZSD_EXP_PAINTS — the table must exist AND be active

| | |
|---|---|
| **Confidence** | **The name is correct by construction** — we are the ones creating it, per `ZSD_EXP_PAINTS_DDIC.md`. This row is not about a guessed name, it is about **sequencing**, and it is first because it is the single most likely reason a first paste fails: pasting either program before objects 1–3 exist gets a wall of "unknown" errors that look like a code problem and are not. |
| **Program assumes** | The transparent table `ZSD_EXP_PAINTS` exists, is **activated** (not just saved), delivery class A, client-dependent with MANDT in position 1, and is readable with plain Open SQL — no `CLIENT SPECIFIED` anywhere in either program. |
| **Where used** | Output report: `TABLES: knvv, zsd_exp_paints, acdoca.` (lines 56–58) — the first DDIC statement in the source; `SELECT ... FROM zsd_exp_paints` (359); `SELECT-OPTIONS s_date FOR zsd_exp_paints-zexc_date_from` (190). Upload: `TYPE zsd_exp_paints-...` from line 114; `gt_upd TYPE STANDARD TABLE OF zsd_exp_paints` (213); `SELECT ... FROM zsd_exp_paints` (724–729); `MODIFY zsd_exp_paints FROM TABLE @gt_upd` (928). |
| **SE11 navigation** | SE11 → Database Table → `ZSD_EXP_PAINTS` → Display. The status bar must say **Active**. Then Utilities → Database Object → Check: the runtime object must exist. If SE11 shows it but SE16N cannot open it, it was saved and never activated. |
| **If different** | Nothing to change in source — go back to `ZSD_EXP_PAINTS_DDIC.md` and finish objects 1, 2 and 3 first. Do not paste either program until this row is green. |

---

## 2. ACDOCA — table name

| | |
|---|---|
| **Confidence** | **High — I vouch for this one.** `ACDOCA` is the Universal Journal line item table and is the defining table of S/4HANA Finance; it is present on every S/4 release including 7.50-based ones. This is not an FS assertion I am passing through, it is standard knowledge. Listed anyway because it sits in the `TABLES` statement at line 58 and a landscape without it (i.e. a system that is not really S/4, or Finance not migrated) would stop the report dead at line 58 with nothing else checked. |
| **Program assumes** | `ACDOCA` exists as a transparent table and is selectable with Open SQL. It is in `TABLES:` (line 58) purely so that `p_rldnr TYPE acdoca-rldnr` (214) and `SELECT-OPTIONS s_blart FOR acdoca-blart` (215) have a reference field. |
| **SE11 navigation** | SE11 → Database Table → `ACDOCA` → Display. Then SE16N → `ACDOCA` → restrict to `RBUKRS` = your company code and `BLART` = `DZ`, execute with a small row count, and confirm rows come back. If ACDOCA is empty on this client the report will run and report zero collections everywhere — correct code, useless output. |
| **If different** | If ACDOCA is genuinely absent, this is not a rename — the entire Actual Collection design has to move to BSEG/BSAD and `f_get_collections`, `f_calc_collection`, `ty_coll` and the B3 selection block are all redesigned. Stop and raise it, do not substitute a table name. |

---

## 3. ZSD_EXP_PAINTS — the 16 column names the programs reference

All 17 fields of the build sheet exist because we create them; the risk here is **not**
that SAP named something differently, it is **transcription drift while typing 17 rows
into SE11 by hand**. A single character wrong in one field name fails both programs in
their TYPES block. Check the Fields tab against this list, character for character.

`MANDT` is the only build-sheet field neither program names — it is handled implicitly by
the client-dependent read and by `MODIFY`. It is not listed below.

| Field | Confidence | Program assumes | SE11 navigation | If different |
|---|---|---|---|---|
| `ZSRN` | High (ours), **NUMC 10 is the part to verify** | Key component. Report: `ty_appr-zsrn` (92) and `ty_output-exc_no` (140). Upload: key of `ty_key` / `ty_seen` / `ty_db` (139, 148, 158) and the SORTED-table key (212). Validated as numeric in the upload. | SE11 → ZSD_EXP_PAINTS → Fields → `ZSRN`, data element `ZSD_DE_EXC_SRNO`, domain `ZSD_DO_EXC_SRNO`, **NUMC 10**. | A name change hits report lines 92, 140, 356, 375, 753 and upload lines 114, 139, 148, 158, 212, 677, 724–727, 755, 791, 804, 812, 871, 885. Wide but mechanical. |
| `ZCUSTOMER` | High (ours) | Key component, and the join to the customer list: `WHERE zcustomer = @gt_cust-kunnr` (report 361). Assigned to and from `KNA1-KUNNR`-typed fields, so it must be **CHAR 10, data element KUNNR**, alpha-conversion identical to KNA1's. | SE11 → Fields → `ZCUSTOMER`, data element `KUNNR`, check table `KNA1`. Then SE16N on the table with a customer that has leading zeros, and confirm the stored value is zero-padded. | Report 93, 361, 382, 720, 723, 731, 781; upload 115, 140, 149, 159, 212, 664, 678, 724–728, 755, 766–768, 792, 805, 813, 872, 886. |
| `ZEXC_APPR_MONTH` | High on the name (ours). **Medium on the type surviving review — this is the trap in the table.** | Key component, and **offset-accessed**: `ls_appr-zexc_appr_month+4(2)` and `...(4)` (report 745–749) build `MM-YYYY`; the upload does the reverse at 485–489. This compiles ONLY on a fixed-length field of at least 6 characters, and is **semantically** correct only if the storage really is `YYYYMM`. A field defined as CHAR 7 holding `MM-YYYY` compiles fine and silently produces garbage. | SE11 → Fields → `ZEXC_APPR_MONTH`, data element `ZSD_DE_EXC_MONTH`, domain `ZSD_DO_EXC_MONTH`, **NUMC 6**. Then SE16N after the first upload: a row must read `202601`, never `01-2026`. | If someone "helpfully" made it CHAR 7 MM-YYYY, do not patch the offsets — fix the domain back to NUMC 6. Build spec §3 is explicit: never store MM-YYYY. If the length is right but the halves are swapped, the two offsets change at report 745–749 and upload 485–489. |
| `ZEXC_APPR_TYPE` | High (ours) | `ty_appr-zexc_appr_type` (report 95), `CASE` on `'1'` / `'2'` / `'3'` to the readable description (759–770), validated against the same three values in the upload (511). Must be **CHAR 1** with those fixed values. | SE11 → Fields → `ZEXC_APPR_TYPE` → data element `ZSD_DE_EXC_TYPE` → domain `ZSD_DO_EXC_TYPE` → Value range tab → the three fixed values must be there. | If the fixed values differ, change the `CASE` arms (report 759–770) and the upload validation (511) together — they must always agree. |
| `ZEXC_DATE_FROM` | High (ours) | `SELECT-OPTIONS s_date FOR zsd_exp_paints-zexc_date_from` (report 190, OBLIGATORY) — so this field is also the **selection-screen reference field**, and a wrong name here kills the selection screen, not just a FORM. Compared with `<` / `>` as a date (report 525–528) and used as the lower bound of the per-row collection window. Must be **DATS 8**. | SE11 → Fields → `ZEXC_DATE_FROM`, data element `DATUM`, DATS 8. While you are there, confirm `DATUM` resolved as a **data element** and not only as a domain — see `ZSD_EXP_PAINTS_DDIC.md` §0.4. | Report 96, 142, 190, 362, 525–528, 773, 790; upload 118, 526, 553–555, 875. |
| `ZEXC_DATE_TO` | High (ours) | Carried straight to the output column, no arithmetic (report 774). Compared with `ZEXC_DATE_FROM` in the upload validation (553–555). Lowest-risk of the three dates. | SE11 → Fields → `ZEXC_DATE_TO`, DATS 8. | Report 97, 143, 774; upload 119, 545, 554–555, 876. |
| `ZEXC_AMOUNT` | High on the name, but **this is FS contradiction C4 and the single most likely field to have been typed differently.** | The FS output mapping calls this same thing `ZEXC_AMNT`; the FS table definition calls it `ZEXC_AMOUNT`. The build spec settles on **`ZEXC_AMOUNT`** and both programs use only that. If whoever typed the table into SE11 followed the FS *mapping* section instead of the build sheet, the table will carry `ZEXC_AMNT` and both programs fail. Must be **CURR 23,2 with currency reference `WAERS`**. | SE11 → Fields → look for `ZEXC_AMOUNT`. If you find `ZEXC_AMNT` instead, that is the C4 collision and the table is wrong, not the code. | Rename the DDIC field to `ZEXC_AMOUNT` — do not change the programs. If functional insists on `ZEXC_AMNT`, change report 98, 144, 357, 775 and upload 120, 579, 877, and re-raise open issue 8. |
| `ZCOMMIT_DATE` | High (ours) | Upper bound of the per-row collection window (report 606, 790–792) and the pivot of both status ladders (`f_calc_status`, 655 onward, compared with `sy-datum`). Must be **DATS 8** — a comparison against `sy-datum` on a non-date type activates and then behaves wrongly. | SE11 → Fields → `ZCOMMIT_DATE`, DATS 8. | Report 99, 146, 532–534, 777, 790; upload 121, 878 (note: the upload's `ty_row-zcommit_date` at 121 is populated by the date parser, same as the other two dates). |
| `ZEX_AMNT` | High on the name (ours). **The field's right to exist is the open question, not its spelling.** | Referenced **only by the upload** (`ty_row-zex_amnt` at 122, parsed at 586–587, written at 879). The output report deliberately does not read it — no output column uses it (build spec deviation 9, open issue 8). CURR 23,2 with currency reference. | SE11 → Fields → `ZEX_AMNT`. Then ask functional whether it is a real second figure or a copy-paste duplicate of `ZEXC_AMOUNT`. | If functional drops it, delete upload lines 122, 586–587, 879 and column 9 of the upload template — the output report needs no change at all. That asymmetry is deliberate. |
| `ZCM_AMNT` | High (ours) | The Collection Commitment. Drives **both** the Non-Fulfilment figure (`non_fulfil = cm_amnt - act_coll`, report 801, build spec C2) and Status-2. Typed into a FORM signature: `FORM f_calc_status USING iv_cm_amnt TYPE zsd_exp_paints-zcm_amnt` (655) — so a wrong name breaks the FORM *interface*, which is a nastier error message than a plain unknown field. CURR 23,2, currency reference. | SE11 → Fields → `ZCM_AMNT`, data element `ZSD_DE_CM_AMOUNT`. | Report 100, 145, 358, 655, 776; upload 123, 594–595, 880. |
| `ZREMARKS` | High (ours) | Carried straight to the last business column (report 778). The upload truncates to the field length deliberately and reports it (622–637), so the **length must really be 250** or the truncation message lies. CHAR 250. | SE11 → Fields → `ZREMARKS`, domain `ZSD_DO_EXC_REMARKS`, CHAR 250. | Report 101, 153, 358, 778; upload 125, 625–637, 881. |
| `WAERS` | High (ours). Not in the FS — see `ZSD_EXP_PAINTS_DDIC.md` §0.3 row 13. | Referenced by name **only in the upload** (`ty_row-waers` at 124, validated against TCURC at 776–780, written at 882). In the output report the currency shown is `T001-WAERS` for the company code, not this field — an accepted difference already carrying an `" ASSUMPTION:` note at report lines 839–845. Must be **CUKY 5, check table TCURC**, and must be the currency reference of all three CURR fields. | SE11 → ZSD_EXP_PAINTS → **Currency/Quantity Fields tab**: `ZEXC_AMOUNT`, `ZEX_AMNT` and `ZCM_AMNT` must each show reference table `ZSD_EXP_PAINTS`, reference field `WAERS`. This tab is the activation blocker called out in the DDIC sheet §3.5. | `WAERS` cannot simply be dropped — a CURR field will not activate without it. If functional refuses it, the three amounts must be re-typed as DEC 23,2, and the `cfieldname 'WAERS'` arguments at report lines 894–905 come out. Not recommended. |
| `ERNAM` / `ERDAT` | High (ours). **Not in the FS — and the upload program hard-depends on them.** | The upload **selects** them back (`SELECT zsrn, zcustomer, zexc_appr_month, ernam, erdat FROM zsd_exp_paints`, 724–725) so that a change-mode `MODIFY`, which replaces the whole row, does not wipe the created-by data (892–893). Set from `sy-uname` / `sy-datum` on insert (897–898). | SE11 → Fields → rows 14 and 15, data elements `ERNAM` (CHAR 12) and `ERDAT` (DATS 8). | These are the "recommended, droppable" rows of DDIC sheet §0.3 — but they are droppable **only if the upload program is edited at the same time**. Dropping them silently is how the upload stops activating. If functional drops rows 14–17, remove upload lines 154–163 (`ty_db`), 724–729, 892–900 and switch to table logging instead. |
| `AENAM` / `AEDAT` | High (ours). Not in the FS. | Written only, never read: `sy-uname` / `sy-datum` on a change (upload 894–895), explicitly cleared on an insert (899–900). | SE11 → Fields → rows 16 and 17, `AENAM` CHAR 12, `AEDAT` DATS 8. | Same as ERNAM/ERDAT above — upload lines 894–895 and 899–900. |

---

## 4. UKMBP_CMS_SGM — PARTNER / CREDIT_SGMNT / CREDIT_LIMIT

| | |
|---|---|
| **Confidence** | **Medium-high on the table, low-medium on the field names — and these are the highest-risk FS-sourced names in the Paints build.** `UKMBP_CMS_SGM` I recognise with reasonable confidence as SAP's FSCM Credit Management "Business Partner credit segment data" table; `UKM_*` is the right namespace and a per-segment credit limit is the right shape. `CREDIT_SGMNT` and `CREDIT_LIMIT` are **FS-supplied and not independently re-verified** — `DDLS_BASE_FIELDS.txt` is not on this machine (CLAUDE.md). They are the exact analogue of `INFOCATEGORY`: plausible, asserted, unchecked. The one mitigation is that Paints, unlike Adhesives, puts them in `TYPES` (lines 110–112) so they fail on the first syntax check instead of hiding in a `WHERE` clause. |
| **Program assumes** | `PARTNER` is customer-number-compatible — the read is `WHERE partner = @gt_partner-kunnr` (436) with `gt_partner` typed on `KNA1-KUNNR`, so **the BP number and the customer number must be the same value**, which holds only when BP and customer share a number range. `CREDIT_SGMNT` is a short character field, is the type of `PARAMETERS p_segmnt` (203, OBLIGATORY) and filters the read (436). `CREDIT_LIMIT` must be **numeric** — it types the output column (147), is compared to zero (817) and is the divisor of the Default % (821). A non-numeric type fails activation at 821, not just misdisplays. |
| **Where used** | `ty_climit` (110–112) — the first UKMBP reference and an activation stopper; `ty_output-credit_limit` (147); `PARAMETERS p_segmnt` (203); `SELECT partner, credit_sgmnt, credit_limit FROM ukmbp_cms_sgm` (432–437); keyed read at 781; arithmetic at 783, 817, 821. Confined to the output report — the upload never touches it. |
| **SE11 navigation** | SE11 → Database Table → `UKMBP_CMS_SGM` → Display → Fields tab → confirm all three names exist **exactly as spelled**. Check `CREDIT_LIMIT`'s data element/domain is CURR (or otherwise numeric) with a currency reference; note which currency field it references. Then SE16N → `UKMBP_CMS_SGM` with a known test customer number in `PARTNER`: **if it returns nothing, that is the BP-number check failing, not an empty table** — try the same customer's BP number from BP/transaction `BP`. Also note what values `CREDIT_SGMNT` actually holds (e.g. `0000`, or a 4-char code) so Arnav knows what to type into `p_segmnt`. |
| **If different** | Field rename: edit `ty_climit` (110–112), `ty_output-credit_limit` (147), `PARAMETERS p_segmnt` (203) and the SELECT list / WHERE (432–436). Six places, all in one FORM plus two declarations. **If `PARTNER` turns out not to equal `KUNNR` on this landscape**, that is not a rename — a customer-to-BP translation (CVI link, table `CVI_CUST_LINK`) has to be inserted before `f_get_credit_limits`, and the same defect exists in the Adhesives program's `BP3100-PARTNER` read. Raise it as one issue across both objects rather than patching one. |

---

## 5. ACDOCA — the nine column names

Eight of these are read in one SELECT (`f_get_collections`, 566–575) and the field list is
matched to `TY_COLL` (119–126) **by position, not by name** — per CLAUDE.md. A rename
touches only the `TYPE` line; an added or removed field must be edited at the same index in
both lists or the later components silently fill with the wrong data.

| Field | Confidence | Program assumes | SE11 navigation | If different |
|---|---|---|---|---|
| `RLDNR` | **High — I vouch for it.** The ledger field in ACDOCA, carried over from new-GL. 2 characters, `0L` is the standard leading ledger. | Types `PARAMETERS p_rldnr TYPE acdoca-rldnr DEFAULT '0L'` (214) and filters the read (569). Note this is the **first** ACDOCA field reference in the source order that is not in `ty_coll` — it is on the selection screen, so a wrong name breaks the selection screen. Not existence-checked against ledger customizing on purpose (comment at 206–212): an unknown ledger returns no rows rather than a wrong figure. | SE11 → ACDOCA → Fields → `RLDNR`. SE16N → ACDOCA and confirm `0L` is really the leading ledger on this client. | Edit line 214 and line 569 only. |
| `RBUKRS` | **High — I vouch for it.** Company code in ACDOCA is `RBUKRS`, not `BUKRS`; the `R` prefix is the new-GL convention and this is a common source of confusion, which is why it is listed. | `ty_coll-rbukrs` (119), selected (566), filtered `= @p_bukrs` (570) where `p_bukrs` is typed on `KNB1-BUKRS`. | SE11 → ACDOCA → Fields → confirm it is `RBUKRS` and that no plain `BUKRS` exists to be confused with. | Edit 119, 566, 570. |
| `GJAHR` | **High — I vouch for it.** | `ty_coll-gjahr` (120), selected (566). Carried only because it is part of the document key — **deliberately not filtered**, per build spec deviation 6 and the ASSUMPTION at 552–556, so a window crossing a fiscal year does not lose rows. | SE11 → ACDOCA → Fields → `GJAHR`. | Edit 120 and 566. Nothing else — there is no GJAHR in the WHERE clause. |
| `BELNR` | **High — I vouch for it.** | `ty_coll-belnr` (121), selected (566), never filtered or displayed. | SE11 → ACDOCA → Fields → `BELNR`. | Edit 121 and 566. |
| `DOCLN` | **Medium-high.** The Universal Journal line-item number; I am confident it is `DOCLN` and that it is **character, 6 long** (`000001`), not numeric. It is carried only for completeness of the key, never used, so even a wrong type is harmless here. | `ty_coll-docln` (122), selected (566). | SE11 → ACDOCA → Fields → `DOCLN`. | Edit 122 and 566. If `DOCLN` does not exist, the cheapest fix is to **drop it from both lists at the same index** — the program never reads it. |
| `BUDAT` | **High — I vouch for it.** | `ty_coll-budat` (123), selected (566), and the whole collection window is expressed in it: `budat BETWEEN @lv_min_date AND @lv_max_date` (572) for the single bulk read, then the per-row test `budat >= date_from AND budat <= commit_date` in `f_calc_collection` (606 onward). Must be **DATS 8** so those comparisons against `ZEXC_DATE_FROM` / `ZCOMMIT_DATE` are date comparisons. | SE11 → ACDOCA → Fields → `BUDAT`, DATS 8. | Edit 123, 566, 572 and the comparison inside `f_calc_collection`. |
| `BLART` | **High — I vouch for it.** | `SELECT-OPTIONS s_blart FOR acdoca-blart DEFAULT 'DZ'` (215) — a selection-screen reference field, so a wrong name breaks the screen; `ty_coll-blart` (124); filtered `blart IN @s_blart` (573). | SE11 → ACDOCA → Fields → `BLART`. SE16N → ACDOCA filtered on `BLART` = `DZ` to confirm collection documents really carry that type on this client. | Edit 124, 215, 566, 573. |
| `KUNNR` | **Medium-high on existence, MEDIUM on it being populated — this is the ACDOCA row to actually look at.** I am reasonably confident ACDOCA carries a `KUNNR` customer field. What I cannot vouch for is that it is **filled** on the line of a `DZ` document that represents the incoming payment: on some configurations the customer only appears on the receivable line and the offsetting bank line carries nothing, which would make Actual Collection come out zero everywhere with no error at all. | `ty_coll-kunnr` (125), selected (566), filtered twice — `kunnr = @gt_cust-kunnr` (571) and the redundant `kunnr <> @space` (574, kept because the build spec locked that WHERE clause). Also the sort key of `gt_coll` and the keyed read in `f_calc_collection`. | SE11 → ACDOCA → Fields → `KUNNR`. **Then the important one:** SE16N → ACDOCA → `RBUKRS` = the test company code, `BLART` = `DZ`, `BUDAT` in a known month → look at the `KUNNR` column. If it is blank on every row, the design needs the customer from somewhere else and this is a functional question, not a rename. | Rename: edit 125, 566, 571, 574 and the `WITH KEY kunnr` reads. **Blank instead of missing:** stop and raise it — read the customer via BSEG/BSID or via the offsetting-account fields, which is a redesign of `f_get_collections`, not a patch. |
| `HSL` | **High on the name — I vouch for it.** `HSL` is the amount in company-code (local, *Hauswährung*) currency in ACDOCA. **Medium on the currency pairing**, which is a business risk rather than an activation risk. | Types `ty_coll-hsl` (126), `ty_output-act_coll` and `-non_fulfil` (148–149), the `f_calc_collection` CHANGING parameter (595) and its local sum (598), and the `f_calc_status` interface (656). Summed and signed at 635 and `abs( lv_sum )` at 642 — a customer collection is a credit and is stored negative, and the FS asks for it unsigned. Must be numeric or lines 635/642/801 do not activate. | SE11 → ACDOCA → Fields → `HSL` → data element/domain must be CURR. Note **which** currency field it references (expect the company-code currency, `RHCUR`). Then SE16N: pick one known `DZ` line and confirm `HSL` is negative for an incoming customer payment — if it is positive, `abs()` is harmless but the sign comment at 638–642 is wrong and should be corrected. | Rename: edit 126, 148, 149, 595, 598, 635, 642, 656, 709. Wide, because HSL is the type of every collection amount in the program. If the currency of `HSL` is not the company-code currency, that does not stop activation — it makes the ALV currency column wrong, and the existing `" ASSUMPTION:` at 839–845 already flags it for functional. |

---

## 6. TCURC — WAERS

| | |
|---|---|
| **Confidence** | **High — I vouch for both.** `TCURC` is the standard currency-code table and `WAERS` is its key field. It is in this file only because it is named by the build spec (§5.3 point 8) rather than by SAP standard knowledge in the program's own right, and because it is the upload program's only non-Z, non-KNA1 DDIC dependency. |
| **Program assumes** | `TCURC` exists with a `WAERS` column, client-dependent, and one row per valid currency key. Used as the existence check for the file's currency column: `SELECT waers FROM tcurc FOR ALL ENTRIES IN @gt_curr WHERE waers = @gt_curr-waers INTO TABLE @gt_tcurc` (710–714), guarded by `IS NOT INITIAL`, then a keyed read per row at 776–780 producing the message `Currency does not exist in TCURC`(e21). Also `ty_waers-waers TYPE tcurc-waers` (169–171). |
| **Where used** | Upload only — lines 169–171, 209–210, 668–670, 690–691, 710–717, 776–780. The output report never reads it; its currency comes from `T001-WAERS`. `TCURC` is separately the **check table** on `ZSD_EXP_PAINTS-WAERS` (DDIC sheet §3.4), which is why the upload's check duplicates what the database would enforce — deliberate, so the user gets a row-level message instead of a failed `MODIFY`. |
| **SE11 navigation** | SE11 → Database Table → `TCURC` → Display → Fields → `WAERS`, CUKY 5. SE16N → `TCURC` → confirm `INR` is present, since that is what the upload template's worked example uses. |
| **If different** | Edit upload lines 170, 711–713 and the message text at 780. Then also revisit the foreign key on `ZSD_EXP_PAINTS-WAERS` in the DDIC sheet §3.4, because both would be wrong together. |

---

## 7. CHAR25 and LOCALFILE — reused standard type names, not FS-sourced but same failure class

These two are not from the FS. They are in this file because they are exactly the kind of
name that is assumed rather than known, and because **neither is covered by the Adhesives
evidence** — `CHAR25` and `LOCALFILE` appear in Paints and in no line the Adhesives syntax
check reached.

| Item | Confidence | Program assumes | SE11 navigation | If different |
|---|---|---|---|---|
| `CHAR25` | **Medium. The one genuinely new type-name exposure in this build.** `CHAR40`, `CHAR30`, `CHAR15` and `CHAR7` are settled — the Adhesives program uses all four and its syntax check passed them before failing at line ~501. `CHAR25` is new: Paints widened Status-1 to hold `'Collection Received'`, `'Commitment Not due'` and `'Commitment Overdue'`. SAP does ship a long series of `CHARnn` data elements and I believe `CHAR25` is in it, but "I believe" is precisely what `INFOCATEGORY` was. | `ty_output-status1 TYPE char25` (151), filled in `f_calc_status` (655 onward) with the three literals above; longest is `'Collection Received'` at 19 characters, so 25 is ample. | SE11 → Data type → `CHAR25` → the radio button must land on **Data element**. Ten seconds. | One line: change report line 151 to `status1 TYPE c LENGTH 25,`. That is fully equivalent here — nothing types against `ty_output-status1` from outside the program and the ALV field catalogue is hand-built (908–909), so no DDIC reference is lost. If you would rather not run the check at all, make this change pre-emptively; it costs nothing. |
| `LOCALFILE` | **Medium-high.** A standard CHAR data element for a frontend file path, the conventional type for an upload report's file parameter. Not proven on this landscape by any object in this repo. | `PARAMETERS p_file TYPE localfile OBLIGATORY` (upload 231) — on the selection screen, so a wrong name breaks the screen, not a FORM. The comment at 226–229 records why it is a flat DDIC field rather than `STRING`: `f_read_file` takes a string copy for the frontend services (338), so nothing downstream depends on the DDIC type. | SE11 → Data type → `LOCALFILE` → must be a **Data element**, CHAR (128 expected). | One line: change upload line 231 to `PARAMETERS p_file TYPE string OBLIGATORY.` — which is also what build spec §5.1 originally specified. Nothing else changes; `f_read_file` already converts. |

---

## Checks that are NOT about activation — do these in SE16N while you are there

None of these stops a paste. All of them produce a report that runs cleanly and prints
wrong numbers, which is worse.

1. **`ACDOCA-KUNNR` populated on `DZ` documents.** Row 5. If blank, every Actual
   Collection is zero and every row reads "Not Fulfilled".
2. **`UKMBP_CMS_SGM-PARTNER` equals the customer number.** Row 4. If BP and customer use
   different number ranges, every credit limit is zero and `def_perc` is blank everywhere
   (the zero guard at 817 hides it).
3. **`HSL` sign on an incoming payment.** Row 5. `abs()` at 642 makes the output right
   either way, but confirm the assumption before it is written into the TS.
4. **Currency alignment.** `T001-WAERS` (report 457–460) is used as the ALV currency for
   columns that come from three different sources: `ZSD_EXP_PAINTS` amounts in their own
   `WAERS`, `UKMBP_CMS_SGM-CREDIT_LIMIT` in the credit-segment currency, and `ACDOCA-HSL`
   in the company-code currency. Only the third is guaranteed to match. Already carrying
   an `" ASSUMPTION:` at report 839–845; confirm with functional rather than converting.
5. **ACDOCA read performance.** `f_get_collections` is a `FOR ALL ENTRIES` over the
   customer list with `RLDNR`, `RBUKRS`, `KUNNR`, `BUDAT` range and `BLART` — no `GJAHR`,
   on purpose. On a large ACDOCA this can be slow. SE11 → ACDOCA → Indexes: check whether
   a secondary index covers `RBUKRS` + `KUNNR` or `RBUKRS` + `BUDAT`. If the first run
   times out, the fix is an index or an ST05 trace, **not** re-adding a `GJAHR` filter —
   that would silently drop rows across a year boundary (build spec deviation 6).

---

## Deliberately not in this file

- **KNB1, KNVV, KNA1, T001, TCURC-adjacent standard fields** — vouched for above.
- **The L4/L5/L6 hierarchy source** (build spec deviation 1, open issue 1). `f_get_hierarchy`
  (report 476) is a deliberate stub with no SELECT and no invented table. There is nothing
  to look up in SE11 until functional names a real source. Identical treatment to Adhesives.
- **Info Category / Info Type** (build spec C3, deviation 2, open issue 10). Omitted from
  the Paints selection screen entirely — `ZSD_EXP_PAINTS` has no such field. This is the
  one place where the Adhesives failure has already been designed around rather than
  merely documented: the field that broke Adhesives has no counterpart here to break.
- **The domains and data elements of objects 1–3** — they are ours, and
  `ZSD_EXP_PAINTS_DDIC.md` §0.4 carries their own trust list (`DATUM` as a data element,
  the CURR length 23, `ZEX_AMNT`'s right to exist). Do not duplicate that work here.

---

## One-page tick list

Everything above condensed. Tick all of it before the first paste.

- [ ] `ZSD_EXP_PAINTS` exists and shows **Active** in SE11 (row 1)
- [ ] Its 17 field names match the build sheet character for character (row 3)
- [ ] `ZEXC_AMOUNT`, not `ZEXC_AMNT` (row 3, FS contradiction C4)
- [ ] `ZEXC_APPR_MONTH` is **NUMC 6**, storing `YYYYMM` (row 3)
- [ ] Currency/Quantity tab: all three CURR fields reference `ZSD_EXP_PAINTS-WAERS` (row 3)
- [ ] `ERNAM` / `ERDAT` / `AENAM` / `AEDAT` present — the upload program requires them (row 3)
- [ ] `ACDOCA` exists (row 2)
- [ ] `ACDOCA`: `RLDNR`, `RBUKRS`, `GJAHR`, `BELNR`, `DOCLN`, `BUDAT`, `BLART`, `KUNNR`, `HSL` (row 5)
- [ ] `UKMBP_CMS_SGM`: `PARTNER`, `CREDIT_SGMNT`, `CREDIT_LIMIT`, and `CREDIT_LIMIT` is numeric (row 4)
- [ ] `TCURC-WAERS` (row 6)
- [ ] `CHAR25` is a data element — or change report line 151 to `c LENGTH 25` (row 7)
- [ ] `LOCALFILE` is a data element — or change upload line 231 to `TYPE string` (row 7)
- [ ] SE16N: `ACDOCA-KUNNR` is filled on `DZ` lines
- [ ] SE16N: `UKMBP_CMS_SGM-PARTNER` matches the customer number
- [ ] Paste order: `ZSD_EXP_PAINTS_UPLOAD` first (it needs only the Z table, KNA1 and
      TCURC), then `ZSD_EXC_APPR_PAINTS`. If the upload activates and the report does not,
      the fault is in ACDOCA or UKMBP_CMS_SGM and rows 1 and 3 are already proven good.
