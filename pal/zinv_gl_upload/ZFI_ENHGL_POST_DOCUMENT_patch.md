# T_BSEG to CHANGING — patch sheet (30/09/26)

Cause: `ZCL_GL_EXCHANGE_AMOUNT_DET=>UPDATE_AMOUNT` has `T_BSEG` as **Importing** (type
`BSEG_T`). Writing its rows dumped `MOVE_TO_LIT_NOTALLOWED_NODATA` (ST22, 30.09.2026
12:30:20) inside the update task, so the parked document never posted. The original code
never reached the write (its G/L lookup never matched), which is why this never showed up.

## 1. ZCL_GL_EXCHANGE_AMOUNT_DET → UPDATE_AMOUNT → Parameters (SE24)

`T_BSEG`: Type **Importing → Changing**. Typing `Type BSEG_T` unchanged. Activate.
Method body: no change (it already writes row by row).

## 2. Enhancement ZFI_ENHGL_POST_DOCUMENT (implicit, start of FM POST_DOCUMENT)

SE37 `POST_DOCUMENT` → Enhance (spiral icon) → edit implementation
`ZFI_ENHGL_POST_DOCUMENT`. Replace the call:

      IF t_bseg[] IS NOT INITIAL.
    *BOC By Arnav on 30/09/26
    *    ZCL_GL_EXCHANGE_AMOUNT_DET=>update_amount(
    *      t_bseg =  t_bseg[]                " Accounting Document Segment
    *    ).
        zcl_gl_exchange_amount_det=>update_amount(
          CHANGING
            t_bseg = t_bseg[] ).
    *EOC By Arnav on 30/09/26
      ENDIF.

Activate 1 before 2 (2 does not compile against an Importing parameter).
