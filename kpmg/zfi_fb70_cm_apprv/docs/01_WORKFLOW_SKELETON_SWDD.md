# Object 1 — Workflow skeleton, SWDD build sheet

**Object:** workflow template, abbreviation `ZFB70CMAPR`, name `FB70 credit memo approval`.
The number `WS9xxxxxxx` is assigned by the system on the first save. Write it down: every
later object binds to it.

**What the skeleton does:** the workflow starts on event `FIPP.CREATED`, the person who parked
gets ONE decision work item (Approve / Reject) in SBWP, and a mail comes back with the result.
No amounts, no approver table, no posting, no PDF. It exists to prove that event linkage, agent
assignment and mail work on this system before the real logic is written. Objects 2 to 7 turn
it into the real approval.

**Who raises the event:** SAP raises `FIPP.CREATED` on park only when a workflow variant with
*Posting release* is customised (OBWA, OBWJ). This build deliberately does not customise that,
because the release-required flag it sets would block posting from a custom workflow. Instead
object 2, a Z function module on BTE `00002218` (PRELIMINARY POSTING: When Document is Saved),
raises the event for credit memos only. Until object 2 exists the skeleton is tested by direct
start from SWUS (section 8). The FB70 test (section 9) comes after object 2.

Do the sections in order. Each one says what you should see; if you do not see it, stop and
send me the screen.

---

## 0. Before you start

| Check | Where | Must be |
|---|---|---|
| Automatic workflow customizing | `SWU3` | Every node green. A red node is Basis work, except the prefix number below |
| Prefix number | `SWU3` → Maintain Definition Environment → Maintain Prefix Numbers | At least one entry, e.g. `900`. Without it the first Save fails with "no prefix number" |
| Event trace | `SWELS` | Switched on. All users is fine in DEV |
| Test data | `FB70` | You can park a customer credit memo in the DEV company code. Ask FI for customer, G/L account, tax code |
| Your mail address | `SU01`, own user, Address tab | E-mail filled, communication method E-Mail |

Write the prefix down. The workflow becomes `WS<prefix>xxxxx`, generated tasks `TS<prefix>xxxxx`.

---

## 1. Look at FIPP once, in SWO1, and send me the result

`SWO1`, Object type `FIPP`, Display. Expand **Key fields**, **Attributes**, **Methods**, **Events**.
Send me the four lists (screenshots are fine). I need the exact key-field and attribute names for
the bindings in objects 3 and 4, and I want to know whether a document-type attribute exists for
the start condition (section 10). Change nothing here.

---

## 2. Create the workflow

1. `SWDD`. If it opens an existing workflow, choose **Workflow → New** (or the Create icon).
   You see three nodes: *Workflow started* → *Undefined* → *Workflow completed*.
2. **Workflow → Save.** Dialog: Abbr. `ZFB70CMAPR`, Name `FB70 credit memo approval`. Continue.
3. Object directory entry: the client's Z package. Local Object works for a first test but
   cannot be transported; use the package now if you already know it.
4. The title bar now shows `WS9xxxxxxx`. Note it.

---

## 3. Container element for the parked document

1. In the tray on the left choose **Workflow Container** (dropdown at the top of the tray if it
   shows something else).
2. Double-click `<Double-click to create>`.
3. Element `FIPP`. Name `Parked document`. Short description `Parked FI document (FIPP)`.
4. Tab **D.type**: choose *Object Type*, Object category `BO`, Object type `FIPP`.
5. Tab **Properties**: tick **Import**. Leave Export, Mandatory, Multiline off.
6. Confirm. `FIPP` appears in the tray with the small object icon.

Expected tray content afterwards: the system elements (`_WF_INITIATOR`, `_WORKITEM`, ...) plus `FIPP`.

---

## 4. Start event and binding

1. **Basic data** (the hat icon, or Goto → Basic data). Tab **Start events**.
2. New row: Object category `BO`, Object type `FIPP`, Event `CREATED`.
3. Click the **binding** icon of the row. In the binding editor press *generate automatic binding*.
   Expected lines, at least the first:

       &_EVT_OBJECT&   →  &FIPP&
       &_EVT_CREATOR&  →  &_WF_INITIATOR&

   If the editor stays empty, drag `_EVT_OBJECT` from the left onto `FIPP` on the right, and
   `_EVT_CREATOR` onto `_WF_INITIATOR`. Continue.
4. Click the **activation** icon of the row. The light must turn green. This writes the type
   linkage: `SWETYPV` now shows Object `FIPP`, Event `CREATED`, Receiver type `WS9xxxxxxx`,
   *Linkage activated* ticked. Look at it once so you know where it lives.
5. Leave the **start condition** empty. The document-type and company-code filter lives in the
   BTE function module of object 2, so no start condition is needed (section 10).
6. Back to the builder. Save.

---

## 5. The decision step

1. Double-click the *Undefined* step. Step type **User Decision**.
2. Tab **Decision**:
   - Title: `Approve parked credit memo &1 in company code &2, year &3?`
   - Parameter 1, 2, 3: press F4 (*Insert expression*), expand `FIPP` → Key fields, and pick
     document number, company code and fiscal year in that order. Do not type the names; take
     them from the list so they match SWO1 exactly.
   - Decision options: row 1 `Approve`, row 2 `Reject`.
   - Agents: type *Expression*, value `&_WF_INITIATOR&` (F4 → Container → `_WF_INITIATOR`).
   - Task: the screen shows `TS00008267` (generic decision task). Leave it.
3. **Transfer and to graphic** (green check with arrow). The graphic now shows the decision with
   two branches, *Approve* and *Reject*, both running into the end node.

---

## 6. Two mail steps, one per branch

Approve branch:

1. Right-click the arrow under *Approve* → **Create** → step type **Send Mail**.
2. Recipient type: *Organizational object*. Expression: `&_WF_INITIATOR&`.
3. Subject: `Credit memo &1 approved (workflow test)` with parameter 1 = the FIPP document
   number, inserted via F4 exactly as in section 5. If the Send Mail screen has no parameter
   fields on your release, put the expression straight into the subject with *Insert expression*.
4. Text: `Parked document was approved by the test decision. Workflow ZFB70CMAPR.`
5. Transfer. Popup *Create task*: Abbr. `ZCM_MAIL_OK`, Name `Mail: credit memo approved`.
   Package as before. Note the `TS` number.

Reject branch: the same, Abbr. `ZCM_MAIL_REJ`, Name `Mail: credit memo rejected`, subject
`Credit memo &1 rejected (workflow test)`.

Where the mail lands: recipient *Organizational object* delivers to the user's SAP Business
Workplace (SBWP → Inbox → Documents). Whether it also reaches Outlook depends on the user's
SU01 communication method and SCOT. That is a Basis check, not a workflow one. The final
solution sends via the Z class anyway, with the PDF attached.

---

## 7. Check, activate, classify agents

1. **Workflow → Check.** No error in the information area (warnings about missing texts are fine).
2. **Workflow → Activate** (the match icon). Status bar: workflow activated, runtime version generated.
3. `PFTC`: Task type *Workflow template*, Task `WS9xxxxxxx`, Display.
   **Additional data → Agent assignment → Maintain.** Cursor on the top line, **Attributes**,
   choose **General task**, Transfer. Save. Without this the event cannot start the workflow for
   an arbitrary user.
4. `PFTC`: Task type *Standard task*, Task `TS00008267`, Display. Additional data → Agent
   assignment → Display. It must say *General task*. If not, Maintain it the same way. The two
   mail tasks run in background and need no agent.
5. `SWU_OBUF`: run it once. Agent changes are buffered and this refreshes the buffer.

---

## 8. Test 1 — direct start from SWUS

1. `SWUS` (or the Test icon in SWDD). Task `WS9xxxxxxx`.
2. Under *Input data* the element `FIPP` shows its key fields. Enter company code, document number
   and fiscal year of an **existing parked document**. Find one in `FBV3` → Document → List, or
   park one in FB70 first (section 9, step 2).
3. Execute. Then `SBWP` → Inbox → Workflow: the work item with the title from section 5.
4. Execute the work item, choose *Approve*. SBWP → Inbox → Documents shows the mail.
5. `SWI6`: Object type `FIPP`, the same key. Open the workflow log: status *Completed*, steps
   Decision and Send Mail visible.

Pass criterion: work item appeared, decision taken, mail received, log complete.

---

## 9. Test 2 — the real trigger from FB70 (only after object 2 is active)

Before object 2 this test cannot pass: SAP does not raise the event on park, see the note at the
top. Do it once the BTE function module is registered in FIBF.

1. `SWELS`: trace on.
2. `FB70`: transaction dropdown *Credit memo*, customer, amount, one G/L line, tax code. Toolbar
   **Park**. Not *Hold*: a held document is not a parked document and raises no event. Note the
   document number from the status bar.
3. `SWEL`: one line Object type `FIPP`, Event `CREATED`, Receiver type `WS9xxxxxxx`, no error.
   - Event line present, receiver empty → linkage not active (section 4 step 4).
   - Event line present, receiver `WS` with error → double-click the line. Usually agent
     assignment (section 7) or the RFC destination in SWU3 (Basis).
   - No event line at all → the BTE of object 2 is not registered or not active in FIBF, the
     document type was filtered out by it, the document was held not parked, or the trace was off.
4. `SBWP`: the work item. Approve. Mail. `SWI6` log as in test 1.
5. Done for the day: nothing to switch off. Only credit memos of the configured document type
   raise the event, by construction of object 2.

---

## 10. Start condition — not used

The filter on document type and company code is in the BTE function module (object 2): the
event is raised only for the credit memo document type, so every start is wanted. `SWB_COND`
stays empty. If FI later asks for a second filter that the BTE cannot see, it goes here.
---

## 11. Common errors on a first workflow

| Symptom | Cause | Fix |
|---|---|---|
| Save refuses: no prefix number | SWU3 prefix missing | Section 0 |
| SWEL: no event at all on park | BTE not registered or inactive, or doc type filtered | Object 2, FIBF |
| SWEL: event, no receiver | Linkage inactive | Section 4 step 4 |
| SWEL: receiver error, "no agent" or "not started by user" | WS not a general task | Section 7 step 3 |
| Work item exists, nobody sees it | TS00008267 not general, or buffer stale | Section 7 steps 4 and 5 |
| SWI1 shows work items in ERROR immediately | RFC destination or WF-BATCH | SWU3, Basis |
| Mail never arrives | SU01 address or SCOT send job | Basis; workflow side is fine if SBWP → Documents has it |
| Changed something, old behaviour persists | Not re-activated | Section 7 step 2 |

---

## 12. What this object deliberately leaves out

- Raising the event from FB70: object 2 (BTE 00002218 function module, FIBF registration).
- Amount ranges and approver per level: object 3 (tables) and object 4 (class).
- Loop over levels, background steps, approver from the container: object 5.
- The approver seeing the parked document from the work item: object 6 (Z copy of TS00008267
  with a FIPP container element).
- Posting after the last approval and the mails with the PDF: objects 5 and 7.
- Outlook delivery: Basis (SU01 communication method, SCOT). Not a workflow problem.

---

## 13. Send back before object 2

1. The `WS` number and the two `TS` numbers.
2. The four SWO1 lists from section 1.
3. Test 1 result: pass, or the SWUS / SBWP screen.
4. `SE37`: display `SAMPLE_INTERFACE_00002218`, screenshots of the Import, Export, Changing and
   Tables tabs. Object 2 is written against that exact signature.
