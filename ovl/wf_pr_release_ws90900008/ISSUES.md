# ISSUES — ovl/wf_pr_release_ws90900008

| # | Date | Issue | Cause | Fix | TR | Status |
|---|---|---|---|---|---|---|
| 1 | 28/10/26 | Workflow 50092307 (`WS90900008`) for PR 2100001615 in ERROR at node 4: "Rule AC90900002 ended with an exception", `SWP 088`. Screenshots in `original/`. Context not yet stated by Arnav — presumably a PR from the Fiori test alongside the PO tests | Agent rule `AC90900002` returned no agent for this PR and is set to terminate on an empty result. What it keys on is unknown (rule not on file) | Diagnosis path in NOTES: PFAC rule definition + simulation with the work item's container, the rule's function module by `ZR_PROG_DOWNLOAD`, `EBAN` of this PR against a PR that worked. Fix follows from which key is blank: fill the data / add the missing row in the rule's table / make the rule fall back when the key is blank | `<TR>` | **Open — rule FM and PR data awaited** |
