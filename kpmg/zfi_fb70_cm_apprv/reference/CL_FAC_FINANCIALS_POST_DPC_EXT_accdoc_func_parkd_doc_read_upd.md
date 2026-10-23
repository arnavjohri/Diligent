# Reference — standard method as pasted by Arnav on 23/10/26 (not ours, do not edit)

`CL_FAC_FINANCIALS_POST_DPC_EXT->ACCDOC_FUNC_PARKD_DOC_READ_UPD` — opens a parked document
for change in the Fiori G/L posting model (Verify General Journal Entries, and the first step of
`ACCDOC_FUNC_PARK_DOC_POST`). Sequence:

1. `conv_parameters` (BUKRS/BELNR/GJAHR), `cl_fdc_accdoc_park_access=>enqueue`.
2. `cl_fdc_accdoc_park_access=>read( iv_belnr iv_bukrs iv_gjahr iv_for_post
   -> es_accdoc_hdr_wa et_accdoc_itm_wa et_accdoc_tax_wa et_accdoc_whtax_wa ev_koars
   ev_error_occurred et_message )`.
3. If not for post and `approval_status` in `in_approval / approved / suspended`
   (`cl_fdc_accdoc_ver_services=>co_approval_status-*`) -> `E130 FDC_POSTING_001`.
4. **`ELSEIF NOT lv_koars CO cl_fdc_accdoc_park_access=>co_allowed_acct_ty_for_parking.`
   `MESSAGE e092(fdc_posting_001)`** -> message container, RETURN. This is the 092 the app shows.
5. Header to temporary document (`tmpty`, `session_create`, `ux_processing_mode = change`,
   `ux_action = glpostingheader-initialize_for_ref`, items `glpostingitem-initialize`).
6. `cl_fdc_posting_impl=>execute_action( )` over header, items, tax, withholding tax.
7. `mo_tmp_doc_access->document_write( )`, attachments and notes reassigned to the temp ID.
8. `er_data` = temp key (`tmpty`, `tmpid`).

The full source was pasted in the session on 23/10/26; only the structure is kept here.

## `CL_FDC_ACCDOC_PARK_ACCESS=>READ` (pasted 23/10/26)

- `PRELIMINARY_POSTING_DOC_READ` into `FVBKPF/FVBSEG/FVBSET/FVBSEC`; not found -> `E134` or
  `FIN_ODATA_GL E010`.
- Header: `MOVE-CORRESPONDING ls_vbkpf TO es_accdoc_hdr_wa` (so `TCODE` = `VBKPF-TCODE`);
  approval status from `XWFFR`/`XFRGE`, else `cl_fdc_accdoc_ver_services=>get_workflow_item_status`.
- **`ev_koars = ls_vbkpf-koars.`** — the value `ACCDOC_FUNC_PARKD_DOC_READ_UPD` checks for 092.
- Items: `MOVE-CORRESPONDING ls_vbseg TO ls_accdoc_itm_wa` (`FDC_S_ACCDOC_ITM`); for `KOART` other
  than G/L the `ASSERT 1 = 2` is commented out ("CE2302 Allow parking of supplier down payment
  request"), so a customer line is carried as it is. Whether its customer number survives depends
  on `FDC_S_ACCDOC_ITM` having a `KUNNR` field.
- Parameters seen: `IV_BELNR`, `IV_BUKRS`, `IV_GJAHR`, `IV_FOR_POST`, `IV_FOR_CREATE_WITH_REF`,
  `IV_FOR_SESSION_TMPTY`, `IV_FOR_SESSION_TMPID`, `ES_ACCDOC_HDR_WA`, `ET_ACCDOC_ITM_WA`,
  `ET_ACCDOC_TAX_WA`, `ET_ACCDOC_ITM_COPA`, `ET_ACCDOC_WHTAX_WA`, `EV_KOARS`, `EV_ERROR_OCCURRED`,
  `ET_MESSAGE`.
