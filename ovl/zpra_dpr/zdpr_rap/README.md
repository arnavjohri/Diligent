# ZDPR_* backend objects touched for the dashboard

Package `ZPR_DPR_RAP`. The full as-documented package source is
`../docs/ZDPR_RAP_Complete_Source_Code.docx` (generated 15/09/26). This folder
holds only the objects changed after that, one file per object, paste-only
through ADT (abapGit cannot import DDLX on this system and the package repo is
offline).

| Object | Change | Why | Date |
|---|---|---|---|
| ZDPR_Q_PROD_PERF | view entity -> classic `define view` + `@OData.publish: true`, `/` -> `division()` | Overview Page needs the tab-3 query on OData V2 like the other four | 16/09/26 |

`original/` = the source exactly as it stood in the 15/09 document. Never edited.
