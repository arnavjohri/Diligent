# Email notifications for the CM approval — matrix to call points

Requirement (FS, received 30/10/26): mail at each stage.

| Trigger / status | Recipients | Purpose | Where the mail is sent from | Kind |
|---|---|---|---|---|
| CM parked | Initiator, Manager (L1 agent) | Level 1 approval needed | `responsibility_rule` of the agent BAdI, level `001`, after `<fs_agent>` is final | `P`, level 1 |
| Approved by Level 1 | Initiator, AVP (L2 agent) | Level 2 approval needed | same rule, level `002` | `A`, level 2 |
| Approved by Level 2 | Initiator, SVP-CFO (L3 agent) | Level 3 approval needed | same rule, level `003` | `A`, level 3 |
| Approved by Level 3 | Initiator | Final approval confirmation | `ZEI_FI_CM_APPR_POST`, after `PRELIMINARY_POSTING_POST_ALL` returns clean | `F` |
| CM rejected (any level) | Initiator | Rejected | implicit enhancement on the reject method of `IF_FDC_ACCDOC_VER` in `CL_FDC_ACCDOC_VER` (name to be confirmed in SE24) | `R` |

The rule is the only code-only hook that knows the approver of the level being created, so the
three "approval needed" mails are raised there. The rule runs more than once per level
(re-determination, forward, restart, Manage Workflows preview) and has no commit of its own,
so sending is (a) deduplicated through `ZCM_WF_MAIL_LOG` and (b) done in a separate LUW by
the RFC FM `Z_CM_WF_MAIL_SEND` (calls `ZCL_CM_WORKFLOW=>SEND_MAIL`, commits or rolls back), called `STARTING NEW TASK ... DESTINATION 'NONE'` exactly as
the rule already calls `Z_JV_MASSGL_WF`.

Nothing in this needs a functional consultant: no SWNCONFIG, no Manage Workflows change.

## Objects, in build order

| # | Object | Type | Ships by | Status |
|---|---|---|---|---|
| 1 | `ZCM_WF_MAIL_LOG` | transparent table (SE11) | build sheet below | to create |
| 2 | `ZCL_CM_WORKFLOW->SEND_MAIL` (static, in the existing class per Arnav) | method | `ZCL_CM_WORKFLOW.abap` (whole class, source-based) | delivered 30/10/26 |
| 3 | `Z_CM_WF_MAIL_SEND` | RFC FM, FG `ZFI_CM_APPR` | paste | next |
| 4 | patch in `responsibility_rule` (agent BAdI class, team-owned) | patch sheet | paste | after 3 |
| 5 | patch in `ZEI_FI_CM_APPR_POST` | enhancement | paste | after 3 |
| 6 | `ZEI_FI_CM_APPR_REJ` on the reject method | enhancement | paste | after method name confirmed |

## Build sheet 1 — `ZCM_WF_MAIL_LOG` (SE11)

Short text: CM approval workflow - mails sent. Delivery class A, display/maintenance allowed,
enhancement category "can be enhanced (character-like)". Technical settings: APPL1, size 0,
buffering off.

| Field | Key | Data element | Note |
|---|---|---|---|
| MANDT | X | MANDT | |
| BUKRS | X | BUKRS | |
| BELNR | X | BELNR_D | |
| GJAHR | X | GJAHR | |
| MKIND | X | CHAR1 | P = parked (L1), A = approval needed (L2/L3), F = final, R = rejected |
| MLEVEL | X | NUMC2 | approval level for P/A, 00 for F and R |
| AGENT | X | SYUNAME | approver user for P/A, blank for F and R |
| SENT_BY | | SYUNAME | |
| SENT_ON | | SYDATUM | |
| SENT_AT | | SYUZEIT | |
| RCPTS | | CHAR255 | addresses, comma-separated, for support |

Use the standard data elements as named; create none. One row per mail. The class inserts
first and sends only when the insert succeeds, so a repeated rule call for the same level and
agent sends nothing.

## Assumptions, flagged in the code

- Addresses come from the SAP user master (`USR21` -> `ADR6`), not from PA0105 0010. A user
  without an address in SU01 gets no mail and the fact is returned in `EV_MSG`.
- The initiator is `VBKPF-USNAM` / `BKPF-USNAM` unless the caller passes one.
- Amount shown is the customer line amount in document currency (`VBSEGD-WRBTR`, or
  `BSEG-WRBTR` `KOART` D once posted).
- Approver names in the subject are generic ("Level n approver"); the FS titles Manager, AVP,
  SVP-CFO are not resolved from HR. The approver's own name from `ADRP` is in the body.
- Mails are sent immediately (`set_send_immediately`), through SCOT. SCOT must have an SMTP
  node for `*` — check in SOST that mails leave DEV.
