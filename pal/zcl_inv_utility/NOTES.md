# ZCL_INV_UTILITY — NOTES (PAL, company code PR01)

## What it is

Utility class behind the PAL invoice-upload Fiori tiles (AP supplier, AR customer,
GL journal). Holds the Excel transform methods, the per-flow validation methods
(`validate_inv_data_ap`, `validate_inv_data_ar`, `validate_inv_data_gl`,
`validate_inv_data_copy`), and `process_invoice_data` which calls
`BAPI_ACC_DOCUMENT_POST`. Validation calls `ZFM_INV_DOC_CHECK` (RFC `NONE`) for
the FI document check and maps its `RETURN` into the upload log.

## Files

- `ZCL_INV_UTILITY.abap` — corrected class, whole (definition + implementation).
- `original/ZCL_INV_UTILITY.abap` — as pasted into the session 12/10/26 (5367 lines).

## Gotchas

- **Local = PHP and group = USD are hardcoded**, both in the validation and when the
  currency type 10 / 30 lines are built for the BAPI. Any other company code fails
  validation. Correct source would be T001-WAERS and the ledger currency setup; not
  changed yet, needs confirmation of where currency type 30 is configured on PR01.
- **No rate check anywhere.** Validation only checks that local amounts balance
  against each other (customer vs GL, or debit vs credit). A local amount that is
  a wrong conversion of the document amount but consistent across lines passes.
  The BAPI accepts explicitly supplied type 10 / 30 amounts as given.
- `<fs_data>` in every validation method is the **first Excel row** of the
  invoice / document. Header-level fields (currency codes, header amounts) are read
  from that row only.
- `lv_no_curr` is driven by the currency *codes*, not the amounts. When only one
  of local / group is supplied, type 10 and type 30 lines are both still built, the
  missing one with amount zero and the hardcoded currency. Not changed 12/10/26.
- The AP method (`validate_inv_data_ap`) carries `amt_loc_curr` / `amt_gp_curr`
  in its vendor type but never reads them. Local / group currency is not validated
  or posted in the AP flow at all.
- `validate_inv_data_gl` and `_ar` map `RETURN-TYPE = 'W'` twice (second branch
  meant `'A'`), so a termination message is logged as a warning. Pre-existing,
  not touched.
- `transform_inv_data_ar` writes the 0.07 fix for `gl_amt_loc_cur` into
  `amt_loc_curr` (customer field) instead of the GL field. Pre-existing, not touched.

## Shipping: PASTE

Global class, could ship by abapGit ZIP, but no `.abapgit.xml` has been generated
for it. Paste the two changed methods (`validate_inv_data_gl`,
`validate_inv_data_ar`) over the method bodies in SE24 / ADT, or paste the whole
class source in ADT source view.
