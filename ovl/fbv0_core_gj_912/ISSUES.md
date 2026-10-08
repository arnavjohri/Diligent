# ISSUES — FBV0 post fails CORE_GJ 912 (JVA, corporate venture)

## 2026-10-08 — "No partner found for venture CP0001 and vendor 7078087"
- **Issue:** posting parked doc 2526000582 / OVL / 2026 (doc type KM, ref
  "CONTINGENT ADV") in FBV0 fails with error CORE_GJ 912. Lines: PK 29 SGL 8 debit
  + PK 31 credit for employee vendors 7078087 and 7141634, all coded to venture
  CP0001 / equity group CRP, posting date 28.09.2026.
- **Cause:** standard FM `VALID_BTYPE` (function group GJA1, the Note 3106821
  version, SAP-delivered 16.02.2024, rel. 816, no local note/modification):
  1. `T8JZ-CORPVENT = CP0001`, so `GJ_PARTNER_CHECK` exits at its first `IF` and
     returns `sy-subrc = 0` (trace: no T8JO / T8JQ reads).
  2. The FBV0/FBVB exemption in `VALID_BTYPE` only fires on `sy-subrc = 1`, so the
     code falls into the `ELSE` operator check.
  3. `T8JV-OPERATOR` is blank for CP0001 (confirmed in SE16N), so
     `lv_partner_error = abap_true` and `MESSAGE e912` is raised.
  Result: any vendor line coded to the corporate venture CP0001 fails.
- **Ruled out:** custom code (where-used empty; `RS_ABAP_SOURCE_SCAN` on Z*/Y* for
  `CORE_GJ` empty; `ZFI_RGGBR000_USEREXIT` / `SAPLZIMS` run and pass before the
  error), vendor master gaps, missing equity group/shares (T8JV, T8JF, T8JG all found).
- **Fix:** none in ABAP. Standard object, not modified. Functional/Basis to look for
  a follow-up correction to Note 3106821 for the current S4CORE SP, else an OSS
  incident on JVA. Interim (functional decision): post without JV coding on the
  vendor lines.
- **TR:** —
- **Status:** handed to functional lead 08/10/26; awaiting SAP correction or incident.
