# ZMM_ARMS vs ZOVL_ARMS — is it the same function? (26/10/26)

Two downloads supplied 26/10/26 (ZR_PROG_DOWNLOAD, OCD/500, full width), both filed in
`original/` and both **identical to the repo copies** in `ovl/atc/sources/modpool/` (drift
check per include, whitespace only):

| Tcode | Program | Download | Repo copy |
|---|---|---|---|
| ZMM_ARMS | SAPMZMMPREPROLE1 | `original/SAPMZMMPREPROLE1.txt` (supersedes the col-72 `SAPMZMMPREPROLE1_listing.txt` of 05/10) | SAPMZMMPREPROLE1.abap + MZMMPREPROLE1{TOP,O01,I01,F01} |
| ZOVL_ARMS → ZGRC_CALL_TODE → CALL TRANSACTION ZICE_ARMS | SAPMZMMPREPROLE1_PHASEII | `original/SAPMZMMPREPROLE1_PHASEII.txt`, `original/ZGRC_CALL_TODE.txt` | SAPMZMMPREPROLE1_PHASEII.abap + MZMMPREPROLE1_PHASEII{TOP,O01,I01,F01} |

## Verdict

**Not the same function. ZMM_ARMS is the 2005/06 MM-only predecessor and is retired in its own
code; ZOVL_ARMS (ZICE_ARMS underneath) is the live multi-module tool.** The four hardcoded roles
in Uday's mail exist only in the PHASEII program (and its ICE-side twin ZIC_AUTH). The changes go
there; nothing in SAPMZMMPREPROLE1 needs touching.

Why ZMM_ARMS cannot be what the business runs: `MODULE ICE_ARMS OUTPUT` (O01 1214–1228) pops
"This transaction has been discontinued — Please use ZICE_ARMS in place of ZMM_ARMS" when
`sy-tcode = 'ZMM_ARMS'` and then executes `LEAVE PROGRAM` **outside the IF**, so any screen whose
flow logic calls this module ends the program under every tcode. The program has no PFCG role
names, no AGR_* reads, no provisioning tables and no GRC call at all.

## Side by side (active code only)

| | ZMM_ARMS — SAPMZMMPREPROLE1 | ZOVL_ARMS — SAPMZMMPREPROLE1_PHASEII |
|---|---|---|
| Origin | FS-MM-AUTH-004, Ajit Singh, 30/11/2005 | Same FS "+ Delta FS of other modules", 02/08/2006 |
| Last change in header log | 26/09/2008 (RD1K960036) | 28/12/2015 (RD1K999362), plus the S/4 `pop_message` gate for ZOVL_ARMS |
| Size | 47 modules, 57 forms, ~8.0k lines | 210 modules, 136 forms, ~25.3k lines |
| Module scope | MM only, no MODULEID | MODULEID = MM, FI, HR, HSE, OLM, PM, PP, PS, QM, SD, SRM |
| Request header / items | ZMM_PREP_ROLEREQ / ZMM_PREP_ROLEREI | ZIC_PREP_ROLEREQ / ZIC_PREP_ROLEREI |
| Screens | 100, 105, 120 | 100, 105, 120, 200 |
| Tcode checks | ZMM_ARMS (discontinued popup), ZMM_ARMS_CONNECT | ZICE_ARMS, ZIC_ARMS_CONNECT, ZIC_AUTH_FI (23×), ZIC_AUTH_FI_REP, ZIC_AUTH_CORETEAM |
| Authorisation | M_EINK_FRG / FRGCO (7 checks) | M_EINK_FRG (8) + ZHR_ARMS |
| PFCG role names in code | none | M:COMMON_USER_TOOLS, D:FM_LOGS_OVL_ALL, D:MM_DISPLAY_ALL(+OVL), D:MM_DISPLAY_PM_PS_LIS_CIN(+OVL), D:MM_*_APPROVE_XX templates |
| Role master tables | none (role codes M1–M22 in ZMM_PREP_ROLEDES only) | ZHELP_MMROLES, _MMROLES_RC, _PMROLES, _PSROLES, _PPROLES(1), _SDROLES, _QMROLES, _HSROLES, _OLMROLES; Z{FI,OL,PM,PP,PS,QM,SD,HS,SR}_PREP_ROLEDES |
| Provisioning / GRC | none | AGR_USERS/AGR_DEFINE/AGR_TEXTS reads, BAPI_USER_GET_DETAIL, ZAUTH_HEAD/ITEM/USER/EXCP queue, ZGRC_DEV_FM + ZGRC_RFC_FM, ZGRC_* result tables, ZSRM_ROLE_ASSIGN_* |
| Shared with the other | ZMM_PREP_ROLEDES, ROLECRC, ROLEGRP, APPROVE, APP_CRC, CRCDESG, REJ_LIS, RSN, SL_EXCP, ZMM_CONSM, ZMM_LOCATION, ZD_T001W_BUKRS, T024, T001L, FMZUOB, USR02 | same |

So the MM approval rules documented on 05/10 in `HARDCODES.md`, `ROLES.md` and
`FRGCO_ROLE_ANALYSIS.md` (FRGCO levels, ZMM_PREP_* master data) still describe the MM branch of
ZOVL_ARMS, because those tables are shared. Everything about ZMM_PREP_ROLEREQ, the ZMM_ARMS popup
and the 3-copy purchasing-group map applies to the dead program only.

## How to confirm in the system (no code needed)

1. **SE93:** ZMM_ARMS → SAPMZMMPREPROLE1; ZOVL_ARMS → ZGRC_CALL_TODE; ZICE_ARMS →
   SAPMZMMPREPROLE1_PHASEII.
2. **ST03N → Workload → Transaction Profile** (last 1–3 months): dialog steps for ZMM_ARMS vs
   ZOVL_ARMS vs ZICE_ARMS. ZMM_ARMS should be zero or near zero.
3. **SE16N:** latest DOCNO / creation date in ZIC_PREP_ROLEREQ vs ZMM_PREP_ROLEREQ. New rows
   appear only in ZIC_PREP_ROLEREQ.
