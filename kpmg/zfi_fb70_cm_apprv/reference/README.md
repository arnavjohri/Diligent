# Reference code (as pasted by Arnav, 14-15/10/26) — NOT our objects, never edited

Existing GL upload workflow objects that the credit memo trigger mirrors. Kept so the
credit memo class can be diffed against the GL one without asking for the code again.

| File | Object | Why it matters |
|---|---|---|
| `ZCL_GL_WORKFLOW_start_workflow.abap` | `ZCL_GL_WORKFLOW->START_WORKFLOW` | template for `ZCL_CM_WORKFLOW`; event, container element names, XWFFR flag, amount rule |
| `ZCL_AGENT_GL_get_agent.abap` | `ZCL_AGENT_GL->GET_AGENT` | approver = parker's direct manager via PA0105 / HRP1001; no amount logic |
| `ZINV_I_USER_GL_behaviour.abap` | RAP behaviour implementation of the GL upload app | shows the JV trigger: park via `Z_ACC_DOC_POST` (doc status 2), then `start_workflow`; no threshold check in code |

Findings recorded from these: no amount threshold and no document type check anywhere in
code; routing is configuration in "Manage Workflows for Journal Entry Verification"
(scenario `WS02800046`). Amount in the event = sum of debit lines, net of tax.
