# ZMM_ARMS — which PFCG roles make a user an ARMS approver (AGR_1251 extract, 05/10/26)

Source: AGR_1251 rows for OBJECT = M_EINK_FRG, pasted by Arnav on 05/10/26. DELETED is blank on
every row.

## How the level is derived

`FORM get_user` checks only field FRGCO, never FRGGR, and the first match wins:

1. L1, DI, CS or MD → **L1**
2. IM → **IM**
3. L2 or L3 → **L3**

Any authorisation in a role whose FRGCO covers one of these values counts. That includes `*` and
ranges. **FRGCO = `*` therefore makes the user an L1 approver.** A blank FRGCO grants nothing.
Values such as 01, 02, C1–C9, E1–E7, 1A–1F, TC, TI, SM, TM, L4, K* and CH give no ARMS rights.

## Roles that grant L1

**Through an explicit L1, DI, CS or MD value (37 roles):**

| Role | Values that hit |
|---|---|
| D:FI_FM_PR_RELEASE_C1, D:FI_FM_PR_RELEASE_HF | L1 |
| Z:FI_FM_PR_RELEASE_C1, Z:FI_FM_PR_RELEASE_HF | L1 (and `*`) |
| D:MM_DISPLAY_ALL | L1 (a display role) |
| D:MM_PUR_PO_APPROVE_1A, _1B, _1C, _1E, _L1 | L1 |
| Z:MM_PUR_PO_APPROVE_1A, _1B, _L1 | L1 |
| D:MM_SRV_IND_APPROVE_1A, _1B, _1C, _1D, _1E, _L1 | L1 |
| D:MM_SRV_IND_APPROVE_DI, _MD | L1, DI (MD) |
| D:MM_SRV_IND_APPROVE_DF | DI |
| D:MM_SRV_IND_APPROVE_CS | CS |
| Z:MM_SRV_IND_APPROVE_1A, _1B, _1E, _L1, _DI, _MD | L1 / DI / MD (most also `*`) |
| Z:MM_SRV_IND_APPROVE_CS | CS |
| D:PSM_FUND_VRFR_BASE_ROLE_OVL | L1, DI (a fund-verifier role) |
| MM_SRV_SES_ALL_PLANT_ONGC_DI | DI (an SES role) |

**Through FRGCO = `*` only (44 roles):**

- **Z: copies of the service-indent approval roles:** Z:MM_SRV_IND_APPROVE_BO, _E6, _E7, _EC, _IR, _KH,
  _KI, _L2, _L3. Each has a second authorisation, status "S", with FRGCO = `*`. Their D: counterparts
  give no access or L3 at most (see below).
- **Maintenance and functional composites:**
  - Z:D:MM:MAINANTANCE:M:BML / OAL / OBT / OBV / OCL / OOL / ORL / OSL / OVA / OVC / OVL / OVV / PCG / SCB (14 roles)
  - ZC:D:MM:MAINANTANCE:M:OVL
  - Z:M:MM:MAINANTANCE:M:XXXX
  - Z:M:MM:RELS_PURCHS_REQ:M:PMAT / PSRV / XXXX
- **Broad roles:**
  - Z:SAP_ALL_RESTRICTED, Z:CORETEAM_ALL_MEMBERS, Z:E:CUTOVER:ACTIVITY
  - Z:E:COMPANY_CODE:M:CBB / FOG / ORL
- **Fiori and business roles:** Z:SAP_FIORI_MM, ZR_FIORI_PO_CUSTOM, ZFI_BR_PURCHASER,
  **ZSD_BR_INTERNAL_SALES_REP**, Z_PRC_BC_PROCUREMENT, Z_ZMMTDR.
- **SAP standard and technical roles:** SAP_MM_SE_CLERK, SAP_SCM_2_ERP_INTEGRATION,
  SAP_SCM_IBP_RTI_MAIN_1 to _4.

## Roles that grant IM (3)

| Role | Values |
|---|---|
| D:MM_PUR_PO_APPROVE_IM | IM, SM, TM, TC, TI, E1–E4 |
| Z:MM_PUR_PO_APPROVE_IM | Same |
| D:FI_VEM_MASTER_MAINTAIN | IM, L2, L3 (a vendor-master role) |

## Roles that grant L3 (21)

| Role | Values |
|---|---|
| D:MM_PUR_PO_APPROVE_L2, _L3 / Z:MM_PUR_PO_APPROVE_L2, _L3 | L2 / L3 |
| D:MM_SRV_IND_APPROVE_KH, _KI, _L2, _L3 | L2 / L3 |
| D:MM_SRV_SES_ACCEPT_L2, _L3 | L2 / L3 |
| D:FI_FM_PR_RELEASE_C3 / Z:FI_FM_PR_RELEASE_C3 | L3 |
| **M:MM_PUR_PO_CREATE** and the plant copies: MM_PUR_PO_ALL_PLANT_ONGC_DI, MM_PUR_PO_KKL_PLANT_40*, MM_PUR_PO_MUM_PLANT_MUM*, MM_PUR_PO_OBV_PLANT_91R1, _91R2, MM_PUR_PO_RJY_PLANT_41* | L3 (PO **creation** roles) |
| MM_PUR_PO_OVL_PLANT_90R1 | L2 |

## Roles with M_EINK_FRG but no ARMS rights

The FRGCO values in these roles miss every ARMS value, or are blank:

- **PR release C-series:** D:/Z:FI_FM_PR_RELEASE_C2, _C4, _FM.
- **Indent, purchasing and SES:** MM_INDENT_*, MM_PURCHASING_*, MM_SES*, MM_MAT_IND_APPROVE_02.
- **PO approval and SES acceptance at E, L4 and T levels:**
  - MM_PUR_PO_APPROVE_E1–E7, _L4, _OM, _SM, _TC, _TI, _CH, _ED_OBV, _HP_OBV
  - MM_SRV_SES_ACCEPT_E1–E7, _L4, _CH_OBV
- **Service-indent approval, D: versions and the Z: versions without `*`:**
  - D:MM_SRV_IND_APPROVE_02, _BD, _BO, _CF, _E6, _E7, _EC, _ED_OBV, _EP, _GC, _IF, _IR, _L4, _LM_OBV, _MI, _OSD, _PF
  - Z:MM_SRV_IND_APPROVE_01, _02, _ED_OBV, _IF, _L4, _LM_OBV, _PF
- **Master roles:** M:MM_SRV_IND_CREATE, M:MM_SRV_SES_CREATE, M:MM_FM_PR_RELEASE_03, M:PB_MRPFIRM,
  M:PP_DISCT_MRPFIRM, M:PP_MRP_ON, MM_FM_PR_RELEASE_03_ALL, MM_SRV_SES_*_PLANT_* (except ALL_PLANT_ONGC_DI).
- **Z: display and functional roles:** Z:D:MM:DISPLAY:D:*, Z:D:PM:*, Z:M:MM:APRV_CONTR_AGRMT:*,
  Z:M:MM:DISPLAY / MAINT_SES / MNT_PURCH_* / PURCH_ORDR_APPR:*, Z:M:PM:*, Z:S:BS:GENERAL_ACCESS:M:ALL.
- **Others:** Z:MM_PUR_PO_CREATE_01, Z_OVL_ZMM_IMAC_ROLE, Z_MM_DSPLAY_TEST, and the SAP_MM_PUR_* /
  SAP_BPR_BUYER_16 / EAMS / JIT standard templates (FRGCO blank).

## Findings

1. **About 44 roles make the user an L1 ARMS approver through FRGCO = `*`.** Most are maintenance,
   Fiori, business or SAP standard roles that have nothing to do with approving. Anyone holding one
   can approve any ARMS request, including MM-discipline ones (IM/L1 only).
2. **The S/4 Z: copies are broader than the D: originals.** Examples: D:MM_SRV_IND_APPROVE_KH, _KI,
   _L2 and _L3 give L3; D:MM_SRV_IND_APPROVE_E6, _E7, _EC, _IR and _BO give nothing. Each matching Z:
   copy has an extra standard ("S") authorisation with FRGCO = `*`, which gives **L1** and also
   unrestricted PO/PR release. This looks like an SU24 default pulled in during the S/4 role build.
   Security should review it.
3. **PO creation roles count as L3 approvers:** M:MM_PUR_PO_CREATE and the plant copies, through L3 or L2.
4. **Unexpected roles give L1:** D:MM_DISPLAY_ALL, D:PSM_FUND_VRFR_BASE_ROLE_OVL and the SES role
   MM_SRV_SES_ALL_PLANT_ONGC_DI.
5. **Some Z: roles may not have their profile generated.** Their AUTH name is a placeholder
   (`__________00`) instead of a generated name like `T-R…`. Those roles may not give users anything
   until the profile is generated. Check in PFCG → Authorizations.

## Still needed

- **Who actually holds these roles:** AGR_USERS (UNAME, AGR_NAME, FROM_DAT, TO_DAT) for the roles
  above. This file shows only role content, not user assignment.
- **Cross-check:** SUIM → Users by authorization values, M_EINK_FRG / FRGCO = L1, DI, CS, MD, IM, L2,
  L3, run one value at a time.
