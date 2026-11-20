# ovl/mir7_tax_busarea_split — business area on the tax line of a logistics invoice (OVL)

## What it is

Enhancement implementation **`ZFI_ENH_SPLIT_TAX_BAPC`** at the explicit enhancement point
`G_BEB_SPLIT_DOCUMENT_CALC_01` (spot `ES_SAPLGLT0`) in function module
`G_BEB_SPLIT_DOCUMENT_CALC`, function group `GLT0` — the document splitter.

It fills business area (and profit center, if blank) on **tax lines** of a logistics invoice
from `ZFI_BAPC1`, before the splitter's mandatory-field check. Rule copied from substitution
exit `UF122` in `ZFI_RGGBS000_USEREXIT`: company code + G/L, earliest start date, posting date
not before the start date.

## Why it is needed (root cause, established in the debugger on OCD/500, 20/11/26)

MIR7/MIRO post fails with *"Balancing field "Business Area" in line item 003 not filled"*
(raised in `G_BEB_CHECK_MANDATORY_FIELDS`, message class `GLT2`).

Inside one `AC_DOCUMENT_CREATE`, form `DOCUMENT_CREATE` (SAPLRWCL) runs the splitter
(`FAGL_RWIN_SPLIT` → `G_BEB_SPLIT_DOCUMENT` → `G_BEB_SPLIT_DOCUMENT_CALC`) **before** the FI
check that carries the substitution (`FI_DOCUMENT_CHECK` → `CHECK_ACCIT` → `SUBSTITUTION` →
`SUBSTITUTE_ITEM` → `FI_SUBSTITUTION_ITEM`). `UF122` does fill `JV` for the tax G/L and standard
copies it back (`MOVE-CORRESPONDING xbseg TO accit_fi`), but by then the check has failed.

At the splitter the lines of test invoice 5105645567/2026 (doc type KR, PO 5100000910) were:

| Row | G/L | Item cat. | Profit center | Business area |
|---|---|---|---|---|
| 1, 5, 6 | 190101 vendor | 03000 | OVLJVBAPC | JV |
| 2 | 190117 SR/IR | 01000 | VN128BRH1E | JV |
| 3 | 92604 Input IGST (`KTOSL` JII, `BUZID` T, tax code LG) | 05100 | OVLJVCORP | *blank* |
| 4 | 190281 TDS | 05200 | OVLJVCORP | JV |

The tax line arrives with a profit center and no business area. Reading (not confirmed in the
forms `split_item` / `copy_unique_asgmt`, which were not seen): a partly assigned line is not
derived from its base line, and inheritance (`LD_INHERIT` = X, `LD_INTF` = X) finds no unique
assignment across three profit centers. Row 3 was blank after the split and after inheritance.

**Where `OVLJVCORP` on the tax line comes from is not established.** `FAGL3KEH` was the
suspect; Arnav removed the G/L "from the table" on 20/11/26 and the error stayed — which table,
and whether the entry was restored, is to be confirmed.

## Ruled out along the way (all checked on screen)

`ZFI_BAPC1/3/5` rows for 92604 (JV / OVLJVCORP) · field status group G133, variant OJVA
(business area optional) · splitting classification (92604 = 05100, 190117 = 01000) · doc type
KR → 0300 / Z006 · rule Z000000012 / 0300 / Z006 (05100 edited, 01000 a base category) ·
inheritance active · business area financial statements active for OVL · header business area
on the invoice (filling it raises another error) · G/L master of 92604 vs 92601 (identical bar
sort key) · BAdI `GLT0_COMP_TAX` (FI-CA only) · `GLT0_COMPLETE_ASSIGNMENT` (does not exist here).

"Works for CGST/SGST" was reported and then withdrawn: it fails for every document.

## How it ships

**Paste-only.** An enhancement implementation is created in the enhancement editor; abapGit ZIP
is not used here.

1. SE37 → `G_BEB_SPLIT_DOCUMENT_CALC` → Display.
2. Enhance (spiral icon, Shift+F4).
3. Find the line `ENHANCEMENT-POINT g_beb_split_document_calc_01 SPOTS es_saplglt0.`
   (Edit → Find). Cursor on that line → right-click → Enhancement Operations →
   Create Implementation.
4. In the pop-up choose **Create Enhancement Implementation** (new) — do **not** select the
   existing `JVA_BEB_SPLIT_01`. Name `ZFI_ENH_SPLIT_TAX_BAPC`, short text, Z package, TR.
5. The editor inserts `ENHANCEMENT n ZFI_ENH_SPLIT_TAX_BAPC.` / `ENDENHANCEMENT.`
   Paste the whole of `ZFI_ENH_SPLIT_TAX_BAPC.abap` between them.
6. Activate (the enhancement, not the function group).

Switch-off if needed: SE19/SE80 → the implementation → deactivate, or comment the body.

## Scope, on purpose

- Reference transaction `RMRP` only (MIRO / MIR7). FB60 and other FI postings untouched.
- Item category `05100` only. Vendor, GR/IR and TDS lines untouched.
- Only blank fields are filled. A value already on the line is never overwritten.
- Reversals skipped (`i_acchd_ex-reverse`).
- No `ZFI_BAPC1` entry, or posting date before its start date → line left alone; the standard
  balancing-field error still appears and tells the user.
- `UF122` and the `ZFI_BAPC*` tables are not changed. `UF122` still runs afterwards and writes
  the same values, which is why the row choice here mirrors it exactly.

## Assumptions (also in the code as `ASSUMPTION:`)

1. Nothing between the enhancement point and the mandatory check (`clear_assignments`,
   `handle_squan`) removes the business area again. Rows 1/4/5/6 keep theirs through that code;
   the debug stops after the JVA enhancement and after `clear_assignments` were not taken.
2. Logistics invoices only is the wanted scope.

## Gotchas

- Enhancement implementations at the same point run in no guaranteed order relative to SAP's
  `JVA_BEB_SPLIT_01`; this one touches only tax lines, that one JV bank assignments.
- The fill is not shown in the splitter's expert-mode trace (it is not a splitter rule).
- An SAP upgrade or note that changes `G_BEB_SPLIT_DOCUMENT_CALC` can require re-adjusting the
  enhancement in SPAU_ENH.
- The Simulate pop-up in MIRO/MIR7 is not built from the splitter's table; judge by Post and
  by FB03 (entry view and general ledger view), not by the pop-up.

## Sources reviewed, not filed

`ZFI_RGGBS000_USEREXIT` (substitution exit pool, ~2,900 lines) and the standard routines
`FI_SUBSTITUTION_ITEM`, `SUBSTITUTE_ITEM`, `G_BEB_SPLIT_DOCUMENT_CALC`, `G_BEB_SPLIT_DOCUMENT`
were pasted into chat on 20/11/26 and read there. None is changed, so none is filed under
`original/`. If `UF122` is ever to be changed, take a fresh `ZR_PROG_DOWNLOAD` of the pool first.
`original/` holds four screenshots: Simulate, the post error, the call stack at the error, and
the splitter values after inheritance.
