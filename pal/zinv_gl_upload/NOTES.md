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
`t_bseg` at posting. Method lives in Z class `ZCL_GL_EXCHANGE_AMOUNT_DET` (called from the POST_DOCUMENT enhancement). `T_BSEG` is read-only in its signature (activation error 30/09/26) - parameter kind to be confirmed.

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

## Shipping: PASTE ONLY

Method body inside an enhancement of a standard class.
