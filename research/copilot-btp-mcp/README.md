# Copilot / Claude ↔ SAP via BTP — research, 27/09/26

Goal: let a business user in Teams (Copilot) or in Claude drive tasks in an SAP backend,
with SAP BTP Integration Suite as the API/agent layer. Two routes were asked about:

- **Route A — Copilot Studio agent in Teams → SAP MCP Gateway on Integration Suite** (read + write).
- **Route B — M365 Copilot "Researcher" (with Claude as the model) → federated MCP connector → same
  MCP Gateway** (read-only by design).

Plus the adjacent option the senior already uses: **Claude Desktop/Claude Code → MCP on BTP** for
development.

Everything below is from public docs fetched 27/09/26. Items marked UNVERIFIED were seen only in
search snippets, not in a page I could open (SAP Help, SAP Community and Microsoft Learn are blocked
from this container; the GitHub mirrors of the Microsoft docs and the `hobru` sample repo were
readable and are the primary sources).

---

## 1. The one thing that changed in 2026: SAP MCP Gateway

SAP Integration Suite now ships an **MCP Server artifact**. You point it at an API artifact, an
OData service, an iFlow or an OpenAPI spec and it publishes the operations as MCP *tools* on the
**Integration Cell** runtime, with OAuth/OIDC, rate limiting, audit and tool lifecycle handled by SAP.
Copilot Studio, Claude, Joule or any MCP client then discovers the tools at runtime — no per-BAPI
custom connector.

- Microsoft's reference architecture for exactly this:
  [SAP MCP Gateway on SAP Integration Suite](https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/architecture-mcp-gateway-integration-suite)
  and SAP's mirror,
  [Microsoft Copilot Studio and the MCP Gateway](https://architecture.learning.sap.com/docs/ref-arch/d2e34e).
- Product docs: [MCP Server — SAP Integration Suite](https://help.sap.com/docs/integration-suite/isuite-integrations-and-apis/model-context-protocol-mcp),
  tutorial [Create an MCP Server for Enterprise AI Agents](https://developers.sap.com/tutorials/integration-suite-mcp-server).
- **Plan requirement (UNVERIFIED, from snippets of SAP Help + SAP Note 2903776):** MCP Server artifact
  is on *Enhanced, Premium, Trial and Free Tier* plans only, and **needs Integration Cell activated** —
  it does not deploy to plain Cloud Integration. So a BTP trial is enough for a POC.
- Transport is **Streamable HTTP**; SSE is deprecated on both the SAP and the Copilot Studio side
  (Copilot Studio dropped SSE Aug 2025).

**Working, step-by-step sample (the thing to follow):**
[hobru/sap-mcp-gateway-copilot-studio](https://github.com/hobru/sap-mcp-gateway-copilot-studio)
— 7 guides, each with a video, MIT-licensed, includes importable Integration Suite packages, OpenAPI
files and `.http` test scripts:

| Part | What it proves | Identity in SAP |
|---|---|---|
| 01 | Build the MCP server, front it with Azure APIM, connect Copilot Studio | shared technical user |
| 02 | OAuth2 auth-code with Entra ID on the MCP call | real user at gateway |
| 03 | SAP IAS federated to Entra; gateway validates IAS token | real user at gateway |
| **04** | **On-prem S/4 via Cloud Connector with principal propagation** | **real ABAP user (CERTRULE)** |
| 05 | Script the creation of the 21 Copilot Studio MCP connectors (`pac connector create`) | — |
| 06 | MCP server written *in ABAP* (`abap-ai/mcp2` SDK) behind BTP router | real ABAP user |
| **07** | **Write ops: PATCH Business Partner through an OData API artifact** | user at gateway, comm. user in backend |

---

## 2. Route A — Copilot Studio agent in Teams (read + write)

### Architecture

```
Teams / M365 Copilot
  └─ Copilot Studio agent  (MCP client; Entra ID sign-in)
       └─ [optional Azure APIM: token cache, header fix, API key]
            └─ SAP Integration Suite · MCP Server artifact  (Integration Cell)
                 └─ API artifact / OData receiver  → BTP destination (ProxyType OnPremise)
                      └─ SAP Cloud Connector  →  S/4HANA / ECC  ICM :44301  (/sap/opu/odata, /sap/bc)
```
Source: MS Learn architecture page (flow steps 1-9), hobru guides 01 + 04.

### Step 1 — SAP side: build the MCP server (hobru guide 01, 07)

1. BTP subaccount → subscribe Integration Suite → activate **Integration Cell** in settings.
2. Cloud Connector on-prem (for our landscape; skip for a public API):
   - Access Control → ABAP System, protocol **HTTPS**, internal host `sap-fqdn:44301`, virtual
     host e.g. `s4.internal.ssl:44301`, principal type *X.509 Certificate (General Usage)*,
     expose `/sap/opu/odata` and `/sap/bc` with sub-paths.
   - Import the ICM server cert into CC → On-Premise → Back-End Trust Store; connection check green.
3. BTP destination: `Type HTTP, ProxyType OnPremise, URL https://s4.internal.ssl:44301,
   sap-client <nnn>, CloudConnectorLocationId <id>`, extra property
   **`integration-cell-include = true`**, Authentication = BasicAuthentication (technical user) to
   prove connectivity first.
4. Design → Integrations and APIs → new package → **Add → API** (runtime profile *Integration
   Cell*, *URL or Specification*, Service Type **ODATA**), target = the destination / OData URL,
   e.g. `API_BUSINESS_PARTNER` or a custom Z RAP/SEGW service. Restrict resources to the exact
   operations you want (GET list, GET single, PATCH/POST).
   - Receiver → *CSRF Protected ✓*, request headers `Accept|Content-Type|If-Match`, response
     headers `ETag|Content-Type|Location`. The receiver fetches the CSRF token + cookies itself;
     Copilot never sees them.
   - Backend credential = **User Credentials** security material (Monitor → Manage Security),
     referenced by name — never in the API definition.
5. **Add → MCP Server**, source = that API artifact; the wizard imports the OpenAPI and lists
   tools. Tick only the operations you want; write a tool description that tells the agent to
   read first and confirm with the user before any update. Hide `If-Match` with
   `x-ms-visibility: internal` + `default: '*'` (POC only; production sends the real ETag).
6. Policies: default = Authentication (OAuth token or client cert) + Authorization (scope
   `API.invoke`). If the source API already authorises, enable *Trust Upstream MCP Authorization*.
7. Deploy → endpoint under Monitor → Manage Integration Content. Service key from the Integration
   Suite booster; **add the `API.invoke` role** to it.
8. Test with a REST client: token (`client_credentials`) → `initialize` → `tools/list`, reusing
   the session-id header. Gotchas: `Accept: application/json, text/event-stream`;
   `Content-Type: application/json` **without** charset, or SAP rejects it.

### Step 2 — identity: Entra ID → SAP IAS → real ABAP user (hobru 02/03/04, MS SSO page)

Users expect principal propagation — audit and authorisations must be the real user
([MS BTP API page](https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/architecture-business-technology-platform-api),
[SSO pattern](https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/sso-entra-id-sap-cloud-identity-services)).

1. Entra ID app registration = the trust SAP IAS uses; IAS corporate IdP = Entra via **OIDC**.
2. Second app in IAS = the Copilot Studio client. Copilot Studio MCP auth = **OAuth 2.0
   authorization code** with IAS authorize/token URLs, redirect = Copilot Studio callback.
   IAS has **no custom scopes** — the gateway validates issuer + audience + the `mail` claim.
3. Align identity in three places: Entra UPN/mail = IAS `mail` = **SU01 e-mail**.
4. Cloud Connector ≥ 2.7: *Principal Propagation CA* cert **and** a separate *System
   Certificate* (`CN=SCC-<subdomain>`); connection check must say "acts as client certificate".
5. Backend: STRUST → import both into **SAPSSLS.pse**; SMICM → Exit Hard → Global.
   RZ10: `icm/HTTPS/verify_client = 1`,
   `icm/trusted_reverse_proxy_0 = SUBJECT="CN=SCC-<sub>", ISSUER="CN=SCC-<sub>"`,
   `login/certificate_mapping_rulebased = 1` → **whole-system restart** (ICM restart is not
   enough; the symptom is 401 for everyone while CERTRULE simulates green).
6. **CERTRULE**: issuer `CN=Cloud Connector Principal Propagation CA`, entry Subject, attribute
   CN, *Login As E-Mail*. Test with an exported *leaf* cert, not the CA.
7. Flip the destination to `Authentication = PrincipalPropagation`, remove user/password.
8. Verify: two users in Copilot Studio → CC Monitor shows two e-mails → `/IWFND/TRACES` shows two
   ABAP users. First call ≈ 4 s (cold logon).

Alternative for writes when you don't want cert plumbing (hobru 07): user auth stops at the
gateway, a least-privilege **communication user** does the PATCH; Integration Suite log holds the
caller, SAP change docs show the comm. user. Acceptable for a POC, weaker audit for production.

### Step 3 — Copilot Studio side

1. Agent → Tools → **Add tool → MCP Server** → name, description, server URL, auth (API key via
   APIM in part 01; OAuth2 auth-code against IAS in part 03). Generative orchestration must be on.
   [Connect your agent to an existing MCP server](https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-existing-server-to-agent).
2. Tools are discovered automatically; add agent instructions (read → confirm → write).
3. Publish → **Teams and Microsoft 365 Copilot** channel; admin approves in Teams admin centre.
4. If Azure APIM is in front: cache the SAP token (60 s buffer), strip the APIM subscription key,
   `buffer-response=false` to keep the stream alive.

### What we can automate with it

Anything with an OData/RAP service: PO status / release, PR creation, BP/vendor maintenance,
stock enquiry (MB5B-style), invoice status, notification/ticket creation. Our Z SEGW/RAP services
are exposed exactly like `API_BUSINESS_PARTNER`. RFC/BAPI without OData is possible via the RFC
receiver in an iFlow exposed as an API artifact, or via the Power Platform **SAP ERP** connector
(needs on-prem data gateway + .NET Connector) — but the MCP path is the SAP-endorsed one.

---

## 3. Route B — Researcher (Claude model) via federated MCP connector (read-only)

- Federated Copilot connectors = MCP servers registered as an org data source; GA June 2026;
  used by Copilot Chat, Researcher, Excel agent mode and Cowork
  ([overview](https://learn.microsoft.com/en-us/microsoft-365/copilot/connectors/federated-connectors-overview)).
- **Researcher stays read-only.** Write/update/delete on federated connectors rolls out Oct 2026
  for Copilot Chat etc., *not* for Researcher (overview page, MC1476316).
- Claude in Researcher: model picker has *Auto / Critique / Model Council / Claude*; admin must
  enable Anthropic models (M365 admin centre → Copilot → Settings → AI providers, AI Administrator
  role). EU/UK tenants opt-in.
  ([Use Claude with Researcher](https://support.microsoft.com/en-us/microsoft-365-copilot/use-claude-with-researcher-in-microsoft-365-copilot),
  [Anthropic models in M365](https://learn.microsoft.com/en-us/microsoft-365/copilot/connect-to-ai-subprocessor)).

### Setup ([custom federated connectors](https://learn.microsoft.com/en-us/microsoft-365/copilot/connectors/set-up-custom-federated-connectors))

1. MCP server URL exposing read-only tools (`search`, `fetch`, `query`) — the same Integration
   Suite MCP server works; just publish only GET tools on a separate MCP artifact.
2. Auth: **Entra SSO** (add token audience to the Entra app → register SSO client in Teams
   Developer Portal → copy the SSO registration ID) or **OAuth 2.0** (redirect
   `https://teams.microsoft.com/api/platform/v1.0/oAuthRedirect`, Teams Dev Portal → Tools →
   OAuth Client Registration; PKCE optional).
3. M365 admin centre → Copilot → Connectors → Gallery → *Create a new connector* → Connect to
   MCP server → display name, base URL, registration ID → save.
4. Staged rollout to a test group, then *Deploy to all users*; ~15 min to appear.
5. In Researcher the connector appears in *Sources*; user authenticates once.

Known issue: a custom federated connector can show as connected but Copilot Chat/Excel never
call it ([MS Q&A](https://learn.microsoft.com/en-us/answers/questions/5936458/custom-microsoft-365-copilot-federated-mcp-connect)) — plan
for tool-description tuning.

**Verdict:** Route B is for *analysis and reports* over live SAP data ("summarise open POs older
than 30 days for plant 1000"). It cannot post anything. Route A is the automation path.

---

## 4. Claude directly (what the senior is doing, and how it extends)

- **Claude Desktop / claude.ai custom connector → Integration Suite MCP server**: Customize →
  Connectors → Add custom connector → server URL (+ optional OAuth client id/secret). Server must
  be reachable from Anthropic's cloud. Pro/Max/Team/Enterprise.
  ([Claude help](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)).
  SAP blog note (UNVERIFIED, snippet only): Claude connects by OAuth redirect, so plain BTP
  service-key credentials are not enough — publish the MCP server as a **Developer Hub product**,
  create a subscription and put the Claude callback URL in it
  ([blog](https://community.sap.com/t5/integration-blog-posts/building-and-consuming-an-mcp-server-in-sap-integration-suite-connecting-it/ba-p/14482795)).
- **Claude Code → ABAP for development**: ADT-based MCP servers (SAP's official ADT MCP,
  ARC-1, `mcp-abap-adt`, Vibing Steampunk, Eclipse-plugin `sap-adt-mcp-server`) — curated list at
  [marianfoo/sap-ai-mcp-servers](https://github.com/marianfoo/sap-ai-mcp-servers). These are
  developer tools, not for business users.
- **Joule ↔ M365 Copilot** (`@Joule` in Teams): GA, bidirectional, but needs Joule licences and
  lists only **cloud** backends (S/4 Cloud private/public, SuccessFactors, Ariba); on-prem S/4 not
  listed; custom agents not included
  ([MS Learn](https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/joule/joule-copilot-overview)).
  Not a fit for ECC/on-prem S/4 clients.

---

## 5. Recommendation

1. **POC on BTP trial (Integration Suite trial plan, Integration Cell on):** MCP server over
   `API_BUSINESS_PARTNER` or one of our Z OData services, technical user, Copilot Studio agent in
   Teams. Follow hobru parts 01 → 07. ~2 days.
2. **Then principal propagation** (part 04) on the client dev system — needs Basis for STRUST,
   RZ10 and a system restart; get that on the calendar early.
3. Add a **read-only MCP artifact** and register it as a federated connector so Researcher +
   Claude can do reporting over the same backend at no extra build cost.
4. Skip Joule for now (cloud-only backends, extra licence). Skip the SAP ERP/RFC connector unless
   a task has no OData at all.

Blockers to confirm with the client/senior: Integration Suite plan on the real subaccount
(MCP artifact needs Enhanced/Premium), Cloud Connector version ≥ 2.7, Copilot Studio licence and
Entra ↔ IAS federation ownership.

---

## Sources

- https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/copilot-with-sap-overview
- https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/architecture-mcp-gateway-integration-suite
- https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/architecture-business-technology-platform-api
- https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/copilot-studio/sso-entra-id-sap-cloud-identity-services
- https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-existing-server-to-agent
- https://architecture.learning.sap.com/docs/ref-arch/d2e34e
- https://github.com/hobru/sap-mcp-gateway-copilot-studio
- https://help.sap.com/docs/integration-suite/isuite-integrations-and-apis/model-context-protocol-mcp
- https://developers.sap.com/tutorials/integration-suite-mcp-server
- https://community.sap.com/t5/technology-blog-posts-by-members/connecting-mcp-gateway-on-integration-suite-with-copilot-studio-updating/ba-p/14488725
- https://community.sap.com/t5/integration-blog-posts/building-and-consuming-an-mcp-server-in-sap-integration-suite-connecting-it/ba-p/14482795
- https://learn.microsoft.com/en-us/microsoft-365/copilot/connectors/federated-connectors-overview
- https://learn.microsoft.com/en-us/microsoft-365/copilot/connectors/set-up-custom-federated-connectors
- https://support.microsoft.com/en-us/microsoft-365-copilot/use-claude-with-researcher-in-microsoft-365-copilot
- https://learn.microsoft.com/en-us/microsoft-365/copilot/connect-to-ai-subprocessor
- https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp
- https://github.com/marianfoo/sap-ai-mcp-servers
- https://learn.microsoft.com/en-us/azure/sap/microsoft-ai/joule/joule-copilot-overview
