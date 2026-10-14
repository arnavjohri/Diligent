# ZINV GL upload — NOTES (PAL, company code PR01)

## What it is

Custom Fiori tile "Upload General Journal Entry" (RAP BO `ZINV_I_USER_GL`, root table
`ZINV_GL_USER`, lines `ZINV_POST_GL`, messages `ZINV_GL_VALID`). On save,
`lsc_zinv_i_user_gl->save_modified` parks the journal entry (`DOC_STATUS = '2'`) via
`Z_ACC_DOC_POST` (no Excel local/group amounts) or `Z_ACC_DOC_POST_MCR` (Excel amounts),
then `ZCL_GL_WORKFLOW->START_WORKFLOW` starts the **standard** verification workflow
`WS02800046` / `FIGLJEV_WF01` (object `FI_GLJEVER`). Final approval posts the parked
document.

`UPDATE_AMOUNT` is called from an enhancement in `POST_DOCUMENT` of the standard class
`CL_FINS_ACDOC_BKPF_BSEG_EVENTS`. It restores the Excel amounts from `ZINV_POST_GL` onto
`t_bseg` at posting. Method lives in Z class `ZCL_GL_EXCHANGE_AMOUNT_DET` (static), called from implicit enhancement `ZFI_ENHGL_POST_DOCUMENT` at the start of update FM `POST_DOCUMENT` (runs in the update task, for every FI posting). `T_BSEG` was Importing `BSEG_T` - changed to Changing 30/09/26.

## Files

- `UPDATE_AMOUNT.abap` — the corrected method, whole (METHOD…ENDMETHOD). Paste over
  the method body in the enhancement implementation.
- `original/UPDATE_AMOUNT.abap` — as supplied 29/09/26.

## Gotchas

- Group currency on PR01 appears to be translated from **local** currency (OB22 source
  currency 2 — to be confirmed). Editing a parked document re-derives local and group
  from TCURR, which is why only rejected-then-edited requests go wrong.
- `ZINV_POST_GL` rows survive posting (checked 29/09/26 on data from 28.05 and 14.07.2026).
- `save_modified` maps `amt_gp_curr = amtloccurr` into `ZINV_POST_GL` — group amount is
  stored as the local amount. Fix pending (behaviour pool, object 2).
- Debit/credit indicator is not stored in `ZINV_POST_GL`; amounts are unsigned.
- Posting via the Verify Journal Entries app runs in the approver's dialog session as
  transaction FBVB (FB03 header 12/10/26: Created By = approver, TCode FBVB), so
  `POST_DOCUMENT` runs in that user's update task. Session breakpoints never fire there:
  external breakpoint for that user on `COMMIT WORK`, then Update Debugging, then F8.
- `UPDATE_AMOUNT` has no app-dependent logic. Its only inputs are `T_BSEG` and
  `ZINV_POST_GL`; a different result between apps means a different line-item set
  (summarisation) or different upload rows. Spread (proportional) only runs when a G/L
  has fewer line items than Excel lines; otherwise amounts are copied as entered (12/10/26).

## UPDATE_AMOUNT (14/10/26 version)

- One method body, no signature change (`T_BSEG` CHANGING as since 30/09). Enhancement
  `ZFI_ENHGL_POST_DOCUMENT` unchanged.
- Reads `ZINV_POST_GL` with `SELECT *` and accesses the key fields **dynamically** by name
  (`ASSIGN COMPONENT`): `COSTCENTER`, `WBSELEMENT`, `PROFITCENT`, `GLASSIGNMENT`,
  `GLITMTXT`, `DEB_CRE`. These are the names of the Excel line type in
  `ZCL_INV_UTILITY->validate_inv_data_gl` (`lty_gl_det`), which the table is believed to
  mirror (`glaccount`, `amt_*` are confirmed). A name that does not exist in the table is
  simply not used, no dump, no activation error. **Check SE11 ZINV_POST_GL once**: the SLG1
  line "keys ..." shows which fields were actually found and usable, "D/C known X" whether
  `DEB_CRE` exists. If a field is named differently, change the literal in `lt_map`.
- Matching: per G/L, Excel lines are placed onto line items so that document amounts add up
  exactly and key fields agree (Excel blank = wildcard, since SAP derives profit centre,
  assignment etc.). Level 1 uses all usable fields, level 2 cost centre + WBS only, level 3
  amounts only; a lower level is tried only when nothing fits. One fit -> written; several
  fits with different sums -> ambiguous, untouched; 200,000 search steps -> untouched.
- Log: SLG1, Object blank, External ID `PR01 4800000140 2026`. Message type S = restored,
  E = not restored (with the G/L and the reason), I = nothing to restore (currency setup).
- Cannot be fixed here, by design: document currency = local currency (local is always the
  document amount), document amounts changed after the upload (no fit), files before the
  29/09 behaviour-pool fix (group stored = local, group left to SAP).

## Shipping: PASTE ONLY

Method body inside an enhancement of a standard class.
