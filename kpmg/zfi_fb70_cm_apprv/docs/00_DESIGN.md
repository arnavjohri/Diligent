# Design — FB70 customer credit memo approval workflow

Status: design agreed in chat on 29/09/26 and 30/09/26. Build started 30/09/26 with object 1.
Trigger corrected 05/10/26: SAP does not raise `FIPP.CREATED` on park without release
customising; object 2 (BTE 00002218) raises it.
Client folder is a placeholder (`kpmg/`) until Arnav names the project; move with `git mv`.

## Requirement (as stated)

- A customer credit memo parked through FB70 (the FB70/FB75 Enjoy screen) must be approved
  before posting.
- Three amount ranges decide how many approvers: range 1 → 1 approver, range 2 → 2,
  range 3 → 3, sequential.
- Every approver gets a mail naming the document, and approves or rejects.
- After the last approval the document is posted automatically.
- Tax is not visible on the parked document, so the approver mail carries a PDF
  (Adobe form; ADS availability to be checked, fallback Smart Form or HTML body) that shows
  header, customer, line items, computed tax, totals and the approval trail.

## Approach chosen

Custom Z workflow on business object `FIPP` (parked document), not the standard framework
`WS10000051` with sub-workflows `WS10000052/53/54`. Reason: the per-level PDF mail needs a
custom step inside the approval loop, which in the standard means copying three sub-workflows.
Trade-off accepted: the standard release flag that stops FBV0 is lost; creators get park-only
authorisation (F_BKPF_BUK activity 77) instead, and a BTE hard lock stays optional.

Standard pieces reused: event `FIPP.CREATED` as trigger, generic decision task `TS00008267`
(copied to Z so the document shows on the work item), background posting task `TS00008142`
(`FIPP.POST`, uses `PRELIMINARY_POSTING_POST_ALL`).

## Trigger

SAP raises `FIPP.CREATED` on park **only** when a workflow variant with *Posting release* exists
(OBWA) and the company code is assigned to it (OBWJ). Confirmed by several community threads
("FIPP - Created event not getting triggered"). That customising also marks the parked document
release-required, which FBV0 and `FIPP.POST` honour, so a custom workflow could never post it.
Therefore no OBWA variant. The event is raised by our own function module on publish-and-
subscribe BTE `00002218` (PRELIMINARY POSTING: When Document is Saved), which fires in the
Enjoy parking transactions (SAP Note 1888123 discusses it for FV60). The function module:

- filters on company code and credit memo document type (from the config table once it exists,
  hardcoded `" ASSUMPTION:` constants until then),
- guards against a second raise when the same parked document is saved again (FBV2, Save as
  completed) by checking for an existing workflow on the object,
- raises `FIPP.CREATED` with `SAP_WAPI_CREATE_EVENT`, `COMMIT_WORK` = space, so the event
  commits together with the parking transaction and never inside it.

BTEs `00002213` (check for release) and `00002214` (determine release approval path) belong to
the standard release framework and are not used. There is no BAdI for "after park" in FB70;
`AC_DOCUMENT` fires on posting only, `BADI_FDCB_SUBBAS01..05` are screen subscreens.

## Objects, in build order

| # | Object | Name | Created via | Sheet |
|---|---|---|---|---|
| 1 | Workflow skeleton | abbr `ZFB70CMAPR`, number `WS9xxxxxxx` | SWDD by hand | `01_WORKFLOW_SKELETON_SWDD.md` |
| 2 | BTE trigger | FG `ZFI_CM_APPR`, FM `Z_FI_CM_APPR_PARK_EVENT`, BTE `00002218` | SE80 paste, FIBF by hand | next |
| 3 | Config + log tables | `ZFI_CM_APPR_CFG`, `ZFI_CM_APPR_LOG` | SE11 by hand, TMG | |
| 4 | Class | `ZCL_FI_CM_APPR_WF` | SE24, paste | |
| 5 | Workflow, full version | same `WS` | SWDD by hand | |
| 6 | Decision task | copy of `TS00008267`, abbr `ZCM_DECIDE` | PFTC by hand | |
| 7 | Form | `ZFI_CM_APPR_FORM` or Smart Form | SFP / SMARTFORMS by hand | after ADS check |

Generated on the way: mail tasks `ZCM_MAIL_OK`, `ZCM_MAIL_REJ` (Send Mail steps, object 1).

## Assumptions (until Arnav or FI says otherwise)

- Amount compared = customer line gross amount in company code currency (`VBSEGD-DMBTR`);
  limits in the config table in the same currency.
- Reject mails the creator and ends the workflow; the document stays parked for the creator
  to change or delete. No edit-and-restart loop in version 1.
- Approvers are SU01 user IDs.
- Tax rows on the form are whatever `CALCULATE_TAX_FROM_NET_AMOUNT` returns, one per condition
  type; no hardcoded GST condition names.
- HSN/SAC and business-place GSTIN go on the form only after SE11 confirms the fields exist
  in `VBSEGS` and `J_1BBRANCH` on this release.

## Open inputs

Document type(s), company code(s), currency, three limits, approver IDs per level,
rejection handling, ADS yes/no (`FP_PDF_TEST_00`), client Z package, SWO1 lists for FIPP,
SE37 signature of `SAMPLE_INTERFACE_00002218` (object 2 is written against it).

## Shipping

Everything here is by hand in SWDD / PFTC / SE11 / SFP except the class, which is paste
(SE24 source-based editing). abapGit could carry the tables and the class; the workflow
definition and tasks it cannot. Treat the folder as paste-only.
