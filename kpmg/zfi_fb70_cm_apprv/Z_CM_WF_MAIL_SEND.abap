*----------------------------------------------------------------------*
* Function    : Z_CM_WF_MAIL_SEND            (new, FG ZFI_CM_APPR)
* Author      : Arnav Johri
* Date        : 30.10.2026
* Description : Own LUW around ZCL_CM_WORKFLOW=>SEND_MAIL. Called
*               STARTING NEW TASK ... DESTINATION 'NONE' from the agent
*               rule (kinds P / A), and directly from the POST and reject
*               enhancements (kinds F / R) which commit themselves.
*               Commits when the mail was handed to BCS, rolls back the
*               ZCM_WF_MAIL_LOG row otherwise.
* SE37        : Attributes -> Processing Type "Remote-Enabled Module".
*               Import: IV_BUKRS BUKRS, IV_BELNR BELNR_D, IV_GJAHR GJAHR,
*                       IV_KIND CHAR1, IV_LEVEL NUMC2 opt,
*                       IV_APPROVER SYUNAME opt, IV_INITIATOR SYUNAME opt
*               Export: EV_SENT BOOLE_D (RFC takes DDIC types only), EV_MSG STRING
*               All "Pass Value" (mandatory for RFC).
*----------------------------------------------------------------------*
FUNCTION z_cm_wf_mail_send.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUKRS) TYPE  BUKRS
*"     VALUE(IV_BELNR) TYPE  BELNR_D
*"     VALUE(IV_GJAHR) TYPE  GJAHR
*"     VALUE(IV_KIND) TYPE  CHAR1
*"     VALUE(IV_LEVEL) TYPE  NUMC2 OPTIONAL
*"     VALUE(IV_APPROVER) TYPE  SYUNAME OPTIONAL
*"     VALUE(IV_INITIATOR) TYPE  SYUNAME OPTIONAL
*"  EXPORTING
*"     VALUE(EV_SENT) TYPE  BOOLE_D
*"     VALUE(EV_MSG) TYPE  STRING
*"----------------------------------------------------------------------

  CLEAR: ev_sent, ev_msg.

  zcl_cm_workflow=>send_mail(
    EXPORTING
      iv_bukrs     = iv_bukrs
      iv_belnr     = iv_belnr
      iv_gjahr     = iv_gjahr
      iv_kind      = iv_kind
      iv_level     = iv_level
      iv_approver  = iv_approver
      iv_initiator = iv_initiator
    IMPORTING
      ev_sent      = ev_sent
      ev_msg       = ev_msg ).

  IF ev_sent = abap_true.
    COMMIT WORK AND WAIT.
  ELSE.
    ROLLBACK WORK.
  ENDIF.

ENDFUNCTION.
