# Teams → SAP via BTP MCP Gateway

_Two-page technical brief: the connection method we are building and what the proof of concept covers_

- **v1.0:** 27 September 2026
- **Prepared by:** Arnav Johri
- **Full proposal:** Teams_SAP_Automation_Proposal_v1.0.docx

## 1. What we are building

A business user asks in **Microsoft Teams** ("create a PR for 10 × material 100-100, plant 1000") and the document is created in the SAP backend under that user’s own identity, visible in `ME53N` / `ME23N`. No screen scripting: the assistant calls the same APIs and BAPIs that sit behind `ME51N` / `ME21N`.

## 2. The chosen method

> **Copilot Studio agent → SAP Integration Suite MCP Gateway → Cloud Connector → SAP**
>
> SAP Integration Suite now has an **MCP Server artifact** (the "MCP Gateway"). It publishes an OData API artifact, an OpenAPI endpoint or **RFC-enabled function modules** as MCP tools that any AI agent (Copilot Studio, Claude, Joule) can discover and call, with OAuth, rate limiting and logging enforced by SAP.
> It is the one route documented by **both** Microsoft ([reference architecture](https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/architecture-mcp-gateway-integration-suite)) and SAP ([Architecture Center d2e34e](https://architecture.learning.sap.com/docs/ref-arch/d2e34e)), and it is the pathway SAP’s **API Policy v4.2026a** names as endorsed for AI agents — the SAP ERP/BAPI connector via on-premises data gateway is not, which is why we are not using it.

| Layer | Component | What it does |
| --- | --- | --- |
| Chat | Copilot Studio agent, published to Teams | Understands the request, picks a tool, **asks the user to confirm** before any write, replies with the document number. Model can be Microsoft’s or Claude. |
| Identity | Entra ID → SAP Cloud Identity Services (IAS) | OAuth 2.0 authorization-code; the signed-in user’s token (not a service identity) goes with every call. IAS is used because Entra alone cannot be propagated into on-prem ABAP. |
| Gateway | Integration Suite → MCP Server on the **Integration Cell** runtime | Validates the token (issuer, audience, e-mail), rate-limits, logs, routes to the API artifact (S/4 OData) or RFC receiver (ECC BAPI). Handles CSRF and ETag for OData writes. |
| Tunnel | SAP Cloud Connector in the SAP network | Outbound-only connection to BTP; no inbound firewall change. With principal propagation it issues a short-lived X.509 cert per user, mapped by `CERTRULE` to the SU01 user. |
| Backend | S/4HANA on-prem: `API_PURCHASEREQ_PROCESS_SRV`, `API_PURCHASEORDER_PROCESS_SRV`, `API_BUSINESS_PARTNER` · ECC: `Z` RFC wrappers | Document is created with the user’s own authorisations and release strategy. |

### ECC vs S/4 — same tools, different backend

- **S/4 on-prem:** OData API artifact per service → MCP Server (source = API). Principal propagation on HTTPS is documented end to end.
- **ECC:** MCP Server (source = RFC destination). SAP Help lists MCP-over-RFC as fully supported for ECC 6.0 (NW 7.0–7.5), max 30 tools. Because the gateway’s commit behaviour is undocumented, each tool is a thin `Z` RFC (`ZMCP_PR_CREATE`, `ZMCP_PO_CREATE`, `ZMCP_PO_RELEASE`, `ZMCP_PO_GET`) that calls the standard BAPI and does `BAPI_TRANSACTION_COMMIT WAIT = X` / `ROLLBACK` **inside the same call**, with a `TESTRUN` flag.
- Tool names and schemas are defined once in the MCP Server, so the ECC backend can be re-pointed to the S/4 OData artifacts after migration without changing the agent.

## 3. Why not the other options

| Option | Reason it is not the main path |
| --- | --- |
| Power Platform SAP ERP connector (BAPI via on-prem data gateway + NCo) | Mature, but no SAP endorsement for LLM-driven use under API Policy §2.2.2; PoC-only setup pages; stateful gateway sessions; 100 s agent-flow limit vs 2-min first NCo connect. Fallback only with written SAP confirmation. |
| M365 Copilot Researcher / federated connectors (Claude selectable) | Researcher is **read-only by design**; custom federated connectors are read-only. Good for reporting over SAP data — we will register a read-only MCP artifact for it later. |
| SAP Joule ↔ M365 Copilot | Cloud editions only (S/4 Cloud, SuccessFactors…); no classic on-prem/ECC without a RISE commitment. |
| Custom / self-hosted MCP (ADT servers, `abap-ai/mcp2`, GUI scripting) | Allowed only under SAP ref-arch 137800 conditions at customer risk; GUI scripting is single-desktop. Our ADT MCP set-up stays a **developer tool** (SAP FAQ carves out dev tooling). |

## 4. Proof-of-concept plan (Phase 1, trial systems only)

1. **BTP trial → Integration Suite** → booster → Settings → Runtime Profiles: activate Cloud Integration, API Management, **Integration Cell**. Gating check: Integration Cell must show Active in the trial region. (Integration Suite trial lasts ~30 days — export artifacts to git after every session.)
2. **First MCP Server against a public OpenAPI** (guide 01 of [hobru/sap-mcp-gateway-copilot-studio](https://github.com/hobru/sap-mcp-gateway-copilot-studio)): service key with `API.invoke`, test `initialize` → `tools/list` with `Accept: application/json, text/event-stream`, `Content-Type: application/json` (no charset).
3. **Copilot Studio trial** → Tools → Add → Model Context Protocol → server URL + auth → test pane.
4. **Cloud Connector → dev SAP**: RFC access control (allow the `Z` wrappers + `RFC_FUNCTION_SEARCH`, `SWO_QUERY_API_METHODS`, `RFC_METADATA_GET`, `RFC_GET_STRUCTURE_DEFINITION`, `BAPI_TRANSACTION_COMMIT`, `BAPI_TRANSACTION_ROLLBACK`); BTP destination type RFC, `ProxyType OnPremise`, label `IntegrationCell.Include = true`, technical user first. One read tool (`ZMCP_PO_GET` → `BAPI_PO_GETDETAIL1`).
5. **First write:** `ZMCP_PR_CREATE` → PR visible in `ME53N`; confirm commit behaviour; confirmation gate in the agent.
6. **Phase 2 (dev system, Basis needed):** Entra ↔ IAS federation; OAuth auth-code in Copilot Studio; principal propagation (`STRUST`, `icm/HTTPS/verify_client`, `icm/trusted_reverse_proxy_0`, `login/certificate_mapping_rulebased = 1` + full restart, `CERTRULE`, SU01 e-mail = Entra e-mail); PO create + release.

## 5. What I need from you

- Which dev system we can point at (ECC or S/4, release), and whether a **Cloud Connector** exists or can be installed in that network.
- Your BTP MCP setup: which subaccount/region, and whether Integration Suite is subscribed there (plan: MCP Server needs **Enhanced/Premium**, or trial/free tier — SAP Note 2903776).
- A Microsoft 365 tenant where a Copilot Studio trial can be created (publishing to Teams needs a pay-as-you-go/credit-pack environment later).
- Two open points to confirm with SAP before any client pilot: **Digital Access** licensing of PR/PO lines created from Teams, and written confirmation of the pattern under API Policy v4.2026a.

Sources and the step-by-step build guide (Appendix A) are in the full proposal. Key pages: SAP Help “Create an MCP Server by referring to an RFC-based backend”; Microsoft Learn “SSO with Entra ID and SAP Cloud Identity Services”; SAP API Policy FAQ (sap.com/documents/2026/04/e2a0665e-…).
