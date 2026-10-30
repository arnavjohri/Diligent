# ZCL_CM_WORKFLOW -> SEND_MAIL — SE24 paste sheet (form-based class)

SE24, `ZCL_CM_WORKFLOW`, change mode.

## Attributes tab — three constants

| Attribute | Level | Visibility | Typing | Type | Initial | Description |
|---|---|---|---|---|---|---|
| GC_MAIL_APPROVAL | Constant | Public | Type | CHAR1 | 'A' | Mail: level n approval needed |
| GC_MAIL_FINAL | Constant | Public | Type | CHAR1 | 'F' | Mail: final approval confirmation |
| GC_MAIL_REJECT | Constant | Public | Type | CHAR1 | 'R' | Mail: rejected |

## Methods tab — new row

| Method | Level | Visibility | Description |
|---|---|---|---|
| SEND_MAIL | Static Method | Public | CM approval mail per matrix (A / F / R) |

## Parameters of SEND_MAIL

| Parameter | Type | Pass value | Optional | Typing | Associated type |
|---|---|---|---|---|---|
| IV_BUKRS | Importing | | | Type | BUKRS |
| IV_BELNR | Importing | | | Type | BELNR_D |
| IV_GJAHR | Importing | | | Type | GJAHR |
| IV_KIND | Importing | | | Type | CHAR1 |
| IV_LEVEL | Importing | | X | Type | NUMC2 |
| IV_APPROVER | Importing | | X | Type | SYUNAME |
| IV_INITIATOR | Importing | | X | Type | SYUNAME |
| EV_SENT | Exporting | | | Type | ABAP_BOOL |
| EV_MSG | Exporting | | | Type | STRING |

No exceptions. Source code: paste `ZCL_CM_WORKFLOW_SEND_MAIL.abap` between `METHOD send_mail.`
and `ENDMETHOD.` (the file carries both lines; SE24 shows them already, so paste the body only).

Prerequisite: table `ZCM_WF_MAIL_LOG` active (build sheet in `03_EMAIL_MATRIX.md`).
`ZCL_CM_WORKFLOW.abap` in this folder is the whole class as it stands, for ADT / source-based use.
