# Test: JV mass upload with a customer line (27/10/26)

**Question:** do the GL verification scenario and the Verify app behave the same for an SA
journal entry from the team's GL mass upload when it carries a customer line? If yes, the
problems seen with the DG credit memo come from the customer line, not from our objects.

**File:** `GL_MASS_UPLOAD_TEST_CUSTOMER_LINE.xlsx` - built from Arnav's template
`GL_MASS_UPLOAD_TEMPLATE_PAYROLL_ADP_CANADA_YYZ-_1007310_15SEP2026_tes6.XLSX` (sheet `Data`,
header rows 1-5 and formatting unchanged). The original template has seven G/L lines only
(`KOART` S) and no customer number column.

| Line | Account (col O) | Type (P) | D/C (R) | Doc amount CAD (S) | Local (T) | Group (U) | CO (W) |
|---|---|---|---|---|---|---|---|
| 1 | 2000852 (customer AIRBUS) | D | H | 1,000.00 | 100 | 110 | - |
| 2 | 54182010 | S | S | 1,000.00 | 100 | 110 | PPYVRSA641 |

Header: PR01, SA, 27.10.2026 / 27.10.2026, CAD (PHP local, USD group as in the template),
header text `CM TEST CUSTOMER LINE`, reference `CMTEST-01`, assignment `CMTEST`.
Line 2 reuses the account / cost centre pair of the template's first line, which is known to work.

**ASSUMPTION:** the upload program reads column O as the customer number when column P is `D`
(as FB01 does). There is no other place in the template for a customer number. If the program
rejects the line or treats 2000852 as a G/L account, it does not support customer lines at all -
which is itself the answer for the JV path.

**Our enhancements do not interfere:** every credit memo object filters on document type DG,
so this SA document runs on pure standard code.

**Expected if the customer line is the cause** (what we saw on DG before each fix):
1. Upload / park may already be refused with `FDC_POSTING_001 092` "Parked document is no GL
   posting" (the same account-type check on the save).
2. If it parks: opening it in the Verify app fails with 092.
3. Approve: the posting step fails with 092.
4. Edit any line in the app: the customer line disappears.
