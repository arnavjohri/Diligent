# ZR_ICF_URL_LIST — every ICF URL of the system as a flat list (developer utility)

Read-only report. Reads table `ICFSERVICE` (the tree SICF displays) and prints one row per
node with its full path (`/sap/opu/odata/sap/ZXXX_SRV`), the virtual host it hangs under,
whether the node is active, whether the **whole chain** above it is active (only then the URL
answers), whether it is an end node, and the depth. Optional base URL (`https://host:port`
from SMICM, Goto → Services) is prefixed so the ALV export is the list CPI asked for.

Why: CPI needs the complete list of valid URLs of the system. SICF only shows a tree you
expand node by node; `ICFSERVICE` stores each node with its parent GUID, not the path. This
report walks the parent chain and rebuilds the path.

## Ship

Paste-only (single report, no includes, no screens). SE38 → create `ZR_ICF_URL_LIST`,
type 1 executable, paste `ZR_ICF_URL_LIST.abap` whole, activate, then maintain the text
elements:

| Element | Text |
|---|---|
| `TEXT-001` | Selection |
| `P_BASE` | Base URL (scheme://host:port) |
| `P_PATT` | Path starts with (* and + allowed) |
| `P_CHAIN` | Only URLs active end to end |
| `P_LEAF` | Only end nodes (no children) |

Local object (`$TMP`) is fine — it reads only, it is a developer tool.

## Run

- Blank selection, *Only URLs active end to end* ticked (default): every callable URL path.
- Base URL `https://<host>:<port>` → the *Full URL* column is ready to send.
- *Path starts with* `/sap/opu/odata` → OData services only. A value with no `*` is treated
  as "starts with"; `*` and `+` wildcards work as in `CP`, case-insensitive.
- *Only end nodes* → drops folder nodes such as `/sap/bc` and `/sap/opu/odata/sap`, which is
  usually the list an integration team wants.
- ALV → Export → Spreadsheet for the hand-over file.

## Gotchas and assumptions (also in the code as `" ASSUMPTION:`)

- **Virtual hosts.** The tree root nodes (`default_host`, any custom virtual host) are
  assumed to be rows of `ICFSERVICE` whose parent GUID is initial / all zeros / absent, and
  are **left out of the URL**. The code checks that a `default_host` row exists before
  applying this; if it does not, nothing is dropped and the *Virtual host* column reads
  `(not in ICFSERVICE)`. **Check on first run:** the *Virtual host* column should read
  `default_host` and `/sap/public/ping` should appear with *Valid* = X. If paths start at
  `/bc/...` instead of `/sap/bc/...`, the virtual-host assumption is wrong for this release —
  report it, one-line fix.
- `? parent missing` in the *Virtual host* column marks an orphan subtree (parent GUID set
  but no such row), or a chain deeper than 64 nodes. Should not occur on a healthy system.
- *Active* / *Valid* test `ICFACTIVE = 'X'`. If the *Active* column shows anything other
  than `X` or blank, the flag has another domain on this release and the chain test needs
  adjusting — untick *Only URLs active end to end* to see all rows meanwhile.
- Path and URL columns are `CHAR 255`. No real ICF path approaches that.
- Not covered, by design: external aliases (`ICFALIAS`, SICF hierarchy type ALIAS), SOAP
  endpoints (SOAMANAGER), and the handler class per node. Add only if CPI asks.

## Status

| Date | State |
|---|---|
| 02/11/26 | Written, not yet activated on any system. Awaiting Arnav's first run. |
