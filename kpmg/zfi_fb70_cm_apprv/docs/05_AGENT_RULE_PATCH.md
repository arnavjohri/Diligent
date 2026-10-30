# Patch: `ZCL_AGENT_GL_WF_RULE->IF_RSM_BADI_STATIC_RULE~RESPONSIBILITY_RULE`

Team-owned class behind rule `YY1_GL_WF_LVL1` (GL verification scenario WS02800046).
Original as pasted by Arnav 30/10/26: `original/ZCL_AGENT_GL_WF_RULE_responsibility_rule.abap`.
Corrected whole method: `ZCL_AGENT_GL_WF_RULE_responsibility_rule.abap`.

## Where

One insertion only. Locate the **last** `CLEAR:` of the method, the one directly before the
final `ENDIF.` / `ENDMETHOD.`:

    CLEAR:ls_hrp1001,ls_hrp1001_jb,ls_hrp1000_jb,
    ls_lst_appr,ls_last_approver,lv_objid,lv_sobjid.

Paste the BOC/EOC block from the corrected file **above** that `CLEAR:`. Nothing else in the
method changes.

## Why there

- `<fs_agent>` is final at that point (level 1 from the org chain, level n from the last
  approver's chain, or the final-approver branch).
- `ls_lst_appr` is still filled when the final-approver branch auto-approved through
  `Z_JV_MASSGL_WF`; the mail is skipped in that case because no human approval is pending.
- `lv_appr_lvl` 1 -> kind `P` (parked), 2 / 3 -> kind `A`.
- Guarded to `VBKPF-BLART = 'DG'` so the JV mass upload (SA) never mails.

## Known behaviour

- Re-determination, forward and restart call the rule again for the same level and agent:
  the row in `ZCM_WF_MAIL_LOG` blocks the duplicate.
- After a rejection and resubmit, level 1 runs again for the same agent and is also blocked
  by that row, so **no second "parked" mail on resubmit**. If the FS wants one, the log key
  needs the work item or a sequence; say so and I add it.
- The call runs under WF-BATCH. WF-BATCH needs an e-mail address in SU01 for BCS to accept
  the sender, and SCOT needs an SMTP node.
