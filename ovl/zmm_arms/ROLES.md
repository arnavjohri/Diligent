# ZMM_ARMS — role master as maintained (SE16N extract supplied 05/10/26)

These tables were supplied by Arnav as SE16N screenshots and pasted rows. The system is
assumed to be S/4. No ECC copy was supplied, so this is not an ECC vs S/4 comparison.

Not supplied yet: ZMM_PREP_REJ_LIS, ZMM_PREP_EX_APP, ZMM_PREP_CRCDESG, ZMM_LOCATION.

Flag legend: P = plant, G = purchasing group, A = approver level, S = storage location,
R = receipt location (all from the ROLEDES/ROLECRC columns). MM = MM_DISC_FLAG, meaning only
MM-discipline users may request the role.
"Min. approver" is ZMM_PREP_ROLEGRP-APPROVER1. L3 means L3, IM and L1 may all approve. IM
means IM or L1. L1 means L1 only.

## 1. Normal and Cross Company roles — ZMM_PREP_ROLEDES (22 roles)

| Role | Description | Required | MM only | Min. approver | Hardcoded rule in code |
|---|---|---|---|---|---|
| M1 | INDENTOR-MATERIALS | P G | | L3 | — |
| M2 | MRP CONTROLLER | P | | L1 | — |
| M4 | INDENTOR SERVICES | P G | | L3 | — |
| M5 | INDENT VERIFIER FOR SERVICES | P G | | L3 | — |
| M6 | SES CREATOR | P G | | L3 | No MM filter on purch. group |
| M7 | SES CHECKER | P G | | L3 | No MM filter on purch. group |
| M8 | SES APPROVER | P G A | | L3 | No MM filter; approver F4 by M8_FLAG |
| M9 | PO MATERIALS CREATOR | P G | X | L3 | — |
| M10 | PO SERVICES CREATOR | P G | | L3 | — |
| M11M | PO APPROVER - MATERIALS | P G A | X | L3 | Approver F4 by MM_FLAG + M11M_FLAG |
| M11S | PO APPROVER - SERVICES | P G A | | L3 | Approver F4 by M11S_FLAG (MM user: MM_FLAG) |
| M12 | STORES-RECEIPT SECTION | R | X | IM | Receipt location category must be RL |
| M13 | STOCK HOLDER IN MM STORES | P S | X | IM | Storage-location check |
| M14 | STOCK INCHARGE | P S | X | IM | Storage-location check |
| M15 | STOCK VERIFIER | P | X | IM | — (description asks for storage location, S not flagged) |
| M16 | ON-SITE STORES TRANSACTIONS | P S | | L3 | Storage-location check |
| M17 | C&F | R | X | IM | Receipt location category must be CF |
| M18 | DISPOSAL STOCK HOLDER | P S | X | IM | Storage-location check |
| M19 | DISPOSAL STOCK INCHARGE | P S | X | IM | Storage-location check |
| M20 | STOCK VERIFICATION INCHARGE | P | | IM | — |
| M21 | CAPITAL INDENTOR ROLE | — | | L1 | — |
| M22 | ALL DISPLAY ROLES FOR MM-NO SAP MAIL | — | | L3 | — |

- ADDL1 and ADDL2 are blank for every role.
- M21 and M22 share SORT_FIELD 022.

## 2. CRC roles — ZMM_PREP_ROLECRC (37 rows)

| Role | Entity | Required | Min. approver | STATUS |
|---|---|---|---|---|
| C30 | FINANCE | P G | L1 (module FI) | active |
| O1 | BUSINEES UNITS | P G | L3 | active |
| O2 | DIRECTOR OFFICE | P G | L3 | active |
| O3 | BUSINESS DEVELOPMENT | P G | L3 | active |
| O4 | CORPORATE COMMUNICATION | P G | L3 | active |
| O5 | COMPANY SECRETARY | P G | L3 | active |
| O6 | STRATEGIC HR | P G | L3 | active |
| O7 | PROJECT FINANCE | — | L3 | active |
| O8 | TECHNICAL AND MANAGEMENT CELL | P G | L3 | active |
| O9 | INFORMATION TECHNOLOGY | P G | L3 | active |
| O10 | MATERIALS MANAGEMENT | P G | L3 | active |
| O11 | HEALTH SAFETY AND ENVIRONMENT | P G | L3 | active |
| O12 | HR/ER | P G | L3 | active |
| O13 | LEGAL | P G | L3 | active |
| O14 | CORPORATE FINANCE | P G | L3 | active |
| O15 | MARKETING | P G | L3 | active |
| O16 | EXPLORATION AND DEVELOPMENT | P G | L3 | active |
| O17 | GEOLOGY AND GEOPHYSICS | P G | L3 | active |
| O18 | CORPORATE PLANNING AND STRATEGY | P G | L3 | active |
| O19 | OPERATIONS | P G | L3 | active |
| O20 | DRILLING | P G | L3 | active |
| O21 | CORPORATE SUPPORT SERVICES | P G | L3 | active |
| O22 | ENGINEERING AND CONSTRUCTION | P G | L3 | active |
| O23 | MEDICAL | P G | L3 | active |
| O24 | LOGISITCS | P G | L3 | active |
| O25 | MAINTENANCE | P G | L3 | active |
| O26 | VIGILANCE | P G | L3 | active |
| O27 | SECURITY | P G | L3 | active |
| O28 | OFFICE OF MD | P G | L3 | active |
| O29 | OTHERS | P G | L3 | active |
| O30 | PR APPROVALS AS PER DESIGNATIONS | P G | L3 | active |
| O31 | SES APPROVALS- L3/L4 | P G | L3 | active |
| M3, M3A, M3B | NOT IN USE | P G A | L3 | **inactive** |
| M11S | NOT IN USE | P G A | L3 | **inactive** |
| M11M | NOT IN USE | P G A, MM | L3 | **inactive** |

**The program never reads ROLECRC-STATUS.** The 5 inactive "NOT IN USE" rows still appear in the
CRC role F4 and can still be saved on a request.

## 3. ZMM_PREP_ROLEGRP — entries that are not requestable in ZMM_ARMS

ROLEGRP has 88 rows and covers every role in §1 and §2. The rows below have no entry in
ROLEDES or ROLECRC, so ZMM_ARMS cannot request them:

- C1–C21 (MM)
- M11 (MM)
- N20–N23 (MM)
- S1–S3 (MM)
- HSE5 (HS)
- PM2 (PM)

ASSUMPTION: the FI, HS and PM entries (and possibly the C, N and S roles) belong to the other ARMS
programs that share this table, such as the `MZFIPREPROLE*` sources in `ovl/atc/sources/modpool/`.
Confirm before anyone deletes them.

- **L2 in APPROVER2:** C30 has APPROVER2 = L2. The code converts release code L2 into level L3
  (`FORM get_user`), so a user can never be "L2" and that slot never matches. L2 holders still
  approve C30, through APPROVER3 = L3.

## 4. Approver lists

**ZMM_PREP_APPROVE** fills the APPROVER column on normal requests:

| Level | Description | M8 | M11S | M11M | MM |
|---|---|---|---|---|---|
| E1–E4 | E1–E4 DESIGNATION | X | X | X | X |
| E5–E8 | E5–E8 DESIGNATION | X | X | | |
| IM | I/C MM (E4 & ABOVE) | | | X | X |
| SM | SECOND LEVEL MM (E4 & ABOVE) | | | X | X |
| TM | THIRD LEVEL MM (E4 & ABOVE) | | | X | X |
| TC | MM TC MEMBER | | X | X | X |
| TI | INDENTOR TC MEMBER | | X | | X |

What this gives in the approver F4:
- M8: E1–E8.
- M11S, non-MM user: E1–E8, TC, TI.
- M11S, MM user: E1–E4, IM, SM, TM, TC, TI.
- M11M, MM user: E1–E4, IM, SM, TM, TC.
- M11M, non-MM user: empty. That cannot happen in practice, because M11M is MM-only.

**ZMM_PREP_APP_CRC** (levels 1A–1F, C1, E1–E7, HC/HI/HL/HS, IM, L1–L4, SM) is read only for
CRC roles M3, M3A, M3B, M11S and M11M. All 5 are inactive, so this table is effectively unused.

## 5. Hardcoded role codes against the data

| Hardcode | What the data shows | Can it move to the table without a DDIC change? |
|---|---|---|
| Storage-location check for M13, M14, M16, M18, M19 | Exactly the 5 roles with S_LOC = X | **Yes:** test `S_LOC = 'X'`. Same behaviour today. |
| Receipt-location category RL / CF for M12 / M17 | Exactly the 2 roles with R_LOC = X | Partly: the trigger can use R_LOC, but the category value has no column. |
| No MM filter for M6, M7, M8 | No column marks these | **Yes, with data:** ADDL1 is blank for all roles. Functional would set ADDL1 = X on M6–M8. (ASSUMPTION: ADDL1 is unused by the other ARMS programs.) |
| Approver F4 for M8, M11S, M11M | Tied to the flag column names in ZMM_PREP_APPROVE | No: needs a DDIC change. Keep in code. |
| CRC rules for M3, M3A, M3B, M11S, M11M | All inactive | Dead code. Leave it. |
| Company code → purchasing-group map | No table holds it | Needs TVARVC or a new table. |
| Release code → level (L1/DI/CS/MD/IM/L2/L3) | No table holds it | Needs TVARVC or a new table. |
