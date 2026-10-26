# ZOVL_ARMS — hardcoded PFCG role rename (Uday Mahato mail, 09/10/26 + 26/10/26)

Analysis only. No source changed yet. Program behind tcode **ZOVL_ARMS** on S/4 is
`SAPMZMMPREPROLE1_PHASEII` (ECC tcode ZICE_ARMS). Repo copy used:
`ovl/atc/sources/modpool/SAPMZMMPREPROLE1_PHASEII.abap` (expanded listing, 28101 lines) and the
`MZMMPREPROLE1_PHASEII*` includes. **The repo O01 include is an empty file** — the PBO modules
exist only inside the expanded listing. Get a fresh `ZR_PROG_DOWNLOAD` of
SAPMZMMPREPROLE1_PHASEII (+ SAPMZMMPREPROLE3_PHASEII) before editing; line numbers below are
snapshot-bound, locate by FORM/MODULE.

## 1. Mapping received

| Old (hardcoded) | New |
|---|---|
| M:COMMON_USER_TOOLS | Z:S:BS:GENERAL_ACCESS:M:ALL |
| D:FM_LOGS_OVL_ALL | Z:E:FM_LOGS_:M:ALL |
| D:MM_DISPLAY_ALL | Z:D:MM:DISPLAY:D:OVL |
| D:MM_DISPLAY_PM_PS_LIS_CIN | Z:D:PM:DISPLAY:M:OVL **and** Z:D:PS:DISPLAY:D:OVL |

## 2. Where each literal lives (active code only)

### ZOVL_ARMS — SAPMZMMPREPROLE1_PHASEII

| # | Include | FORM / MODULE | Snapshot line | Literal | What the code does with it | Change |
|---|---|---|---|---|---|---|
| 1 | MZMMPREPROLE1_PHASEIII01 | `MODULE validate_header_data INPUT` | 568–570 | `M:COMMON_USER_TOOLS` | `SELECT * FROM agr_users WHERE agr_name = … AND uname = requested user`. Empty and module ≠ SRM → `MESSAGE e091(zhelp)` (user is not an SAP user). **This is the gate on every CREATE / CROSSCO.** | Replace literal with `Z:S:BS:GENERAL_ACCESS:M:ALL` |
| 2 | MZMMPREPROLE1_PHASEIIF01 | `FORM GRC_RISK_ANALYSIS` | 7247 | `M:COMMON_USER_TOOLS` | Clears role_name/role_type on the GRC bucket row for the common role | Replace literal |
| 3 | MZMMPREPROLE1_PHASEIIF01 | `FORM ROLE_HELP` | 10057 | `M:COMMON_USER_TOOLS` | `LOOP AT it_agr WHERE agr_name NE …` — delimit-existing-roles list skips the common role | Replace literal |
| 4 | MZMMPREPROLE1_PHASEIIF01 | `FORM INSERT_DATA` | 8167–8174 | `D:FM_LOGS_OVL_ALL` | `SEARCH wa_roles-role_name FOR 'FM_LOGS'`; if CCODE = OVL the role appended is this literal (ELSE branch does the FFFFFFFF fund-centre substitution) | Replace literal with `Z:E:FM_LOGS_:M:ALL` |
| 5 | MZMMPREPROLE1_PHASEIIF01 | `FORM INSERT_DATA_ADDL` | 8454–8461 | `D:FM_LOGS_OVL_ALL` | Same logic for the CRC additional-roles path | Replace literal |
| 6 | MZMMPREPROLE1_PHASEIIF01 | `FORM INSERT_DATA` | 8234–8238 | `D:MM_DISPLAY_ALL` → `D:MM_OVL_DISPLAY_ALL`, `D:MM_DISPLAY_PM_PS_LIS_CIN` → `D:MM_OVL_DISPLAY_PM_PS_LIS_CIN` | If CCODE = OVL and the role from ZHELP_MMROLES is the ONGC display role, **swap it for the OVL variant** | See §3 — not a plain literal swap |
| 7 | MZMMPREPROLE1_PHASEIIF01 | `FORM INSERT_DATA_ADDL` | 8516–8527 | same pair | Same swap, done as a post-loop over IT_ROLES1 | See §3 |

Commented-out, leave alone: `FORM DELIMIT_ROLES` F01 11124; `MODULE user_command_100` I01 1013.

### Same literals in sister programs (NOT in Uday's mail — must move in step)

| Program | Include | FORM | Line | Literals |
|---|---|---|---|---|
| **SAPMZMMPREPROLE3_PHASEII** (ZIC_AUTH / ZIC_AUTH_REP — ICE-side processing) | MZMMPREPROLE3_PHASEIIF01 | `insert_data` | 4649, 4710–4712 | D:FM_LOGS_OVL_ALL; MM_DISPLAY swap pair |
| same | same | `insert_data_addl` | 7017, 7076–7079 | D:FM_LOGS_OVL_ALL; MM_DISPLAY swap pair |
| **FI ARMS** (main program not in repo; includes MZFIPREPROLE1_PHASEII*) | MZFIPREPROLE1_PHASEIIF01 | `grc_risk_analysis` | 4434 | M:COMMON_USER_TOOLS |
| same | same | `role_help` | 5027 | M:COMMON_USER_TOOLS |

If ZIC_AUTH is not changed with ZOVL_ARMS, the request side and the ICE side will name
different roles for the same request. Confirm with Uday whether the FI program is live on S/4.

## 3. The two display roles are not a 1:1 literal swap

What ECC actually assigned to an OVL user was **D:MM_OVL_DISPLAY_ALL** and
**D:MM_OVL_DISPLAY_PM_PS_LIS_CIN** (the swap targets), not the D:MM_DISPLAY_* names in the
mail. The D:MM_DISPLAY_* names are the *trigger* — the row that comes out of ZHELP_MMROLES.

Two things decide the code change, and both are Uday's to answer:

1. **What does ZHELP_MMROLES hold now that his "table mapping" is done?**
   - If the table rows already carry `Z:D:MM:DISPLAY:D:OVL` etc., the IF at #6/#7 never
     matches, the swap is dead code, and the new name flows through unchanged. Code change:
     comment the swap out (or leave it, it is harmless), nothing else.
   - If the table still holds `D:MM_DISPLAY_ALL` / `D:MM_DISPLAY_PM_PS_LIS_CIN`, the swap
     targets must become the Z: names.
2. **One role becomes two.** `D:MM_DISPLAY_PM_PS_LIS_CIN` → PM *and* PS role. The swap in
   #6/#7 rewrites one row; it cannot produce two. Options:
   - ZHELP_MMROLES is consumed by `LOOP AT IT_ROLES0` (F01 7674), so **if its key allows two
     rows for the same ROLE_TYPE**, add the PS role as a second row and no code split is
     needed. Check the key in SE11 → ZHELP_MMROLES → Fields.
   - Otherwise #6 and #7 need a second `APPEND` for the PS role (small code change, same
     BOC/EOC block).

Also confirm the exact spellings in PFCG before anything is pasted — `Z:E:FM_LOGS_:M:ALL`
(trailing underscore) and `Z:D:PM:DISPLAY:M:OVL` vs `Z:D:PS:DISPLAY:D:OVL` (M vs D) look like
they may carry typos. A wrong role name fails silently at assignment, not at activation.

## 4. Tables

Uday's list vs what ZOVL_ARMS actually reads (active code, MM PHASEII includes):

| In the mail | Read by ZOVL_ARMS? | Note |
|---|---|---|
| ZHELP_MMROLES, ZMM_PREP_ROLEDES | yes | role master (PFCG names) and role descriptions, MM |
| ZHELP_OLMROLES, ZOL_PREP_ROLEDES | yes | OLM |
| ZHELP_PMROLES, ZPM_PREP_ROLEDES | yes | PM |
| ZHELP_PSROLES, ZPS_PREP_ROLEDES | yes | PS |
| ZHELP_SDROLES, ZSD_PREP_ROLEDES | yes | SD |
| ZHELP_HSROLES, ZHS_PREP_ROLEDES | yes | HSE |
| ZFI_PREP_ROLEDES | yes | FI descriptions |
| ZHELP_FIROLES | **no** — only the FI ARMS program reads it | fine to transport, just not ZOVL_ARMS |

**Read by ZOVL_ARMS but missing from the mail** — ask Uday whether they were mapped or are out of
scope for OVL: `ZHELP_PPROLES`, `ZHELP_PPROLES1`, `ZPP_PREP_ROLEDES` (PP), `ZHELP_QMROLES`,
`ZQM_PREP_ROLEDES` (QM), `ZSR_PREP_ROLEDES` (SRM), and **`ZHELP_MMROLES_RC`** — receipt-location
roles keyed by CCODE, read in `FORM INSERT_DATA` (F01 8155); it holds PFCG role names and is
OVL-specific, so it almost certainly needs the same rename.

### Moving the table contents to QA

The contents go as table entries in a transport, not as code. Steps on the dev system:

1. SE11 → table → *Delivery and Maintenance* tab → note **Delivery class** and whether a
   maintenance dialog (SM30) with recording routine exists.
2. If SM30 with "Standard recording routine": re-save the entries in SM30 and it prompts for a
   customizing request; the entries land as `R3TR TABU <table>`.
3. Otherwise (delivery class A, or no maintenance dialog): SE10 → create a Workbench request →
   open the task → *Object list* → add `R3TR TABU <table>` → double-click → *Keys* → key `*`
   (all entries, current client). Repeat per table. Release and hand to Basis.
4. Make sure the table **definitions** already exist in QA (SE11 there, or ask Basis). If the
   S/4 build recreated them, `R3TR TABL` must precede the `TABU` entries.

## 5. Not touched

No source edited. `ovl/zmm_arms/HARDCODES.md` describes the older ZMM_ARMS program
(SAPMZMMPREPROLE1), not this one; its role list does not apply here.
