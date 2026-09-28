# GR data release: Venture field (ZZ1_VNAME_COB) into ACDOCU

## What it is
Group Reporting data release (ACDOCA -> ACDOCU) leaves the ACDOCU Venture
custom field blank. The Venture field in accounting is the key-user
coding-block field `ZZ1_VNAME_COB`, created with the Custom Fields app. It is
already on `E_JournalEntryItem` (generated append
`ZZ1_DDHSAVE6EJDWDYO7JBVZNYNUNQ`), but not on `I_CnsldtnIntegRptdFinData`,
the view the release task reads for prep-ledger integration. So it is missing
from the "Field in General Ledger" value help of the mapping table (only the 8
standard fields show).

The key-user route (slide 107: Custom Fields app -> UIs and Reports ->
"GR Realtime Reported Data - TAI") is not offered on this system, so the
ADT route from slide 105 is used: a customer extension of
`I_CnsldtnIntegRptdFinData`.

## Objects
| Object | Type | Ships |
|---|---|---|
| `ZX_CNSLDTNINTEGRPTDFINVNAME` | DDL source (extend view), SQL append `ZXINTFINVNAME` | Paste in ADT |

`E_JournalEntryItem` and its generated append are **not** touched.

## After activation (functional)
1. Mapping table "DRT: Mapping for Jrnl Entry to Group Jrnl Entry Ext Fields":
   `ZZ_VNAME_COB` -> existing ACDOCU Venture field. Customizing transport.
2. Re-run data release for the affected period(s).

## Gotchas
- Applies to integration with the GR **preparation ledger** and ACDOCA actuals
  only. Under classic accounting integration the release reads other views and
  the mapping table does not apply.
- ACDOCU field must have the same type/length as `ZZ1_VNAME_COB`.
- If someone later enables the TAI usage in Custom Fields, a generated
  `ZZ1_...` element will appear alongside `ZZ_VNAME_COB`; keep one mapping only.
- Source deck: SAP "Field Mapping for Data Release Task", slides 102-108.
