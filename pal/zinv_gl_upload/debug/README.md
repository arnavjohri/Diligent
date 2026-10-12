# Temporary SAAB instrumentation (12/10/26)

Question: on the Verify Journal Entries app path, is `POST_DOCUMENT` (and so
`ZCL_GL_EXCHANGE_AMOUNT_DET=>UPDATE_AMOUNT`) reached at all, and if yes which exit
does the method take? My Inbox approval gives correct group amounts, the other app
does not. Breakpoints do not fire: update task + WF-BATCH + Gateway session.

## Steps

1. SAAB: create checkpoint group `ZGL_AMT`. Activation tab: Logpoints = **Log**.
   Activate for your user **and WF-BATCH** (Users tab), duration a few days. Save.
2. `ZFI_ENHGL_POST_DOCUMENT_logpoint.abap` -> replace the enhancement body
   (SE37 POST_DOCUMENT -> Enhance -> ZFI_ENHGL_POST_DOCUMENT). Activate.
3. `UPDATE_AMOUNT_logpoints.abap` -> paste over the method body in SE24
   `ZCL_GL_EXCHANGE_AMOUNT_DET`. Activate. (Parameter `T_BSEG` must already be CHANGING.)
4. Approve one request via My Inbox and one via the Verify app.
5. SAAB -> group `ZGL_AMT` -> Log. Subkeys per document:
   - `ENH-<belnr>`  enhancement reached; shows SY-UNAME, SY-CPROG, first line before.
   - `UPD-<belnr>`  which branch the method took (EXIT1..EXIT4 or OK), with values.
   - `AFT-<belnr>`  first line after the method.

## Reading it

| Seen for Verify-app doc | Meaning |
|---|---|
| no `ENH-` at all | that app does not post through `POST_DOCUMENT`; different posting FM, find it from the app's OData handler |
| `ENH-` with a BELNR different from the parked doc | app reposts as a new document; objkey lookup cannot match |
| `UPD-` EXIT1 | ZINV_I_GL_VALID has no row for belnr+bukrs+gjahr |
| `UPD-` EXIT2 | ZINV_POST_GL rows not found for that fileid/documentid |
| `UPD-` EXIT3 | document amounts on the line items no longer match the Excel per G/L (app changed them, or summarisation differs) |
| `UPD-` EXIT4 | restored amounts do not balance |
| `UPD-` OK but ACDOCA KSL still wrong | something after POST_DOCUMENT re-derives group (check SY-CPROG, then the FINS currency translation) |

Remove all `*BOC By Arnav on 12/10/26 - TEMPORARY` blocks and deactivate the SAAB group
when done. `../UPDATE_AMOUNT.abap` is the clean version to restore.
