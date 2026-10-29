# ovl/wf_pr_release_ws90900008 — custom PR release workflow WS90900008, agent rule AC90900002

## What it is

Custom workflow `WS90900008` (version 0000, started by the release event on object
*Purchase requisition*), with a parallel block at node `0000000004` (ParForEach) whose agent
determination is custom rule `AC90900002`. Nothing of it is on file: not the workflow
definition, not the rule's function module. Only the two SWI1 screenshots of 28/10/26 in
`original/` (workflow 50092307, PR 2100001615, started 13:00:09 by SAP CONSULTANT, in state
ERROR at 13:00:54).

## What the screenshots establish

- `Rule AC90900002 ended with an exception` → `SWP 088 E 0000000004 000000`: the rule ran for
  the first ParForEach index of node 4 and returned no agent (or raised), and the rule is
  flagged *terminate if rule resolution has no result*, so the workflow went to ERROR instead
  of falling back to the task's default agents.
- Everything before the rule was fine: event received, workflow started. The data of PR
  2100001615 itself is what the rule could not resolve.

## Where to look (PFAC, SWI1, no code yet)

1. PFAC `AC90900002` → rule definition: function module name (or responsibilities), the
   container elements it expects, and the *Terminate if rule resolution has no result* flag.
2. PFAC → *Simulate rule resolution* with the container of the failed work item (SWI1 →
   work item → Container): the same inputs the workflow passed. No agent = data, agent found =
   the container the workflow passed differs from the simulation.
3. Download the rule's function module with `ZR_PROG_DOWNLOAD` and read what it keys on
   (release group / code, document type, plant, purchasing group, creator, a Z table): the
   value that is blank or unknown for this PR is the cause.
4. Compare `EBAN` of 2100001615 with a PR whose workflow completed: document type, release
   group and strategy, purchasing group, plant, creator, every `ZZ*` field.

## Gotchas

- If the PR was created from a Fiori app, the same pattern as the PO applies: custom fields
  the app does not show are blank, and a rule keyed on them finds nobody. `sy-tcode` and
  `sy-uname` are also meaningless inside a rule (it runs under `SAP_WFRT`).
- After the cause is fixed, SWPR (restart after error) continues this workflow; a new PR
  is not needed to retest.
