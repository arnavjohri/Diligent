# M1xchange TReDS integration (OVL): ABAP scope and effort

**Status:** scoping only. Nothing built. The effort estimate was asked for by Varnika Negi (SAP CPI) on 25/11/26.
**Source:** `M1XChange_API_Integration_Approach-ONGC_Videsh_v1.0.pdf` (Draft, UAT), attached to the mail
*"FW: [EXTERNAL]FW: [EXTERNAL]IT integration OVL"* from Varnika Negi, 25/11/26. M1 sent it on 24/11/26.
The PDF is marked confidential, so it is **not** filed in the repo. Get it from that mail.

## What it is

OVL uploads MSME vendor invoices to M1xchange, an RBI-licensed TReDS platform, for reverse factoring.
M1xchange hosts all four APIs (REST/JSON, API key in the `Authorization` header):

| # | API | Endpoint (UAT, `uat.m1xchange.com:8473/IntegrationService/integration/...`) |
|---|---|---|
| 1 | Vendor Details Pull: PAN list in, Udyam/MSME class, seller ID and bank on record out | `api/getVendorDetailsByPan` |
| 2 | Vendor Onboarding / Bank Mapping: vendor + bank out, `Seller_Id` back | `api/onboardVendor` |
| 3 | Invoice Initiation: create a Factoring Unit (FU) | `hpcl/createAndAuthorizeFactor` |
| 4 | Invoice Status: query an FU by FU name / invoice no. / internal ref | `transaction/getTransactionDetails` |

All four calls are **outbound from OVL**. v1.0 has **no callback**, so status has to be polled.

## Proposed split

```
S/4 (OCQ) --SM59 HTTPS, sync--> CPI iFlow (x4) --REST/JSON + API key--> M1xchange
```

- **ABAP:** selects the data, calls CPI synchronously, stores the results, sets and releases the payment
  block, runs the status job, and provides the monitor reports.
- **CPI:** maps field names, injects the API key, connects to M1, logs messages.
  It should own the field-name mapping. M1 uses names such as `PO/PI_Number`, `GRN/SRN_Number` and
  mixed-case `Vendor_Id`, and none of these can be an ABAP component name. `/UI2/CL_JSON` `name_mappings`
  cannot be relied on, because OCQ is an older release (MEMORY.md §4).
- Alternative: CPI pulls from S/4 on a timer. ABAP would then expose RFC/OData for pending records and for
  writing results back. The effort is about the same, but S/4 then needs inbound access (Cloud Connector).
  Not recommended.

## ABAP effort (person-days; object names are proposals)

| # | Work item | Objects | Days |
|---|---|---|---|
| 1 | DDIC + config | `ZFI_TREDS_CFG` (+TMG), `ZFI_TREDS_VEND`, `ZFI_TREDS_FU`, `ZFI_TREDS_FUI`, `ZFI_TREDS_LOG`, msg class `ZFI_TREDS` | 3 |
| 2 | Common API layer | `ZCL_FI_TREDS_API`: SM59 HTTP call, JSON build/parse for 4 APIs, M1 error codes → messages, payload log | 3 |
| 3 | Vendor pull + onboarding | `ZFI_TREDS_VENDOR`: PAN from vendor master, batched pull, ALV (linked / MSME class / bank match), onboard selected, store `Seller_Id` | 4 |
| 4 | Invoice initiation | `ZFI_TREDS_INVOICE`: open MSME invoices, derive amounts/PO/GRN/due date, pre-checks (dup, holiday, amount, min days), ALV preview, upload, payment block, store FU | 6 |
| 5 | Status job + monitor | `ZFI_TREDS_STATUS`: background poll of open FUs, status update, release block on Expired/Discard, reprocess failed | 4 |
| 6 | Integration test with CPI on UAT + defect fixing | — | 4 |
| 7 | TS document, UAT support, KT | — | 3 |
| | **Total** | | **27** |

The total is about 27 person-days, or 5–6 weeks for one developer. It holds to ±20% only once the FI
points below are closed.

**Not included (add if asked):**

| Add-on | Extra days |
|---|---|
| Automatic clearing posting for settled FUs | +5 |
| Inbound callback service, if M1 offers a push | +4 (plus Cloud Connector) |
| Writing Udyam/MSME data back to the vendor master | +3 |
| Fiori app or e-mail alerts | not estimated |

**Not ABAP work:**

- Basis: SM59 destinations, STRUST certificates, the firewall/proxy path from OCQ to CPI.
- CPI: API key storage, whitelisting of CPI egress with M1.
- FI: configuring the payment block key.
- By hand: the SM30 TMG and the SE41 GUI status.

## Field mapping (draft)

| M1 field | SAP source | Confidence |
|---|---|---|
| `PAN_LIST[]`, `Vendor_PAN` | `LFA1-J_1IPANNO` | used by OVL `SAPMZMMVENDOR`. CHAR 40 (KPMG DD03L), so condense before sending |
| `Vendor_GSTN` | `LFA1-STCD3` | OVL `SAPMZMMVENDOR` writes GST no. into STCD3 |
| `Vendor_Id` | `LFA1-LIFNR` | — |
| `Vendor_Bank_Account_No` | `LFBK-BANKN` | which account if a vendor has several (BVTYP)? **open** |
| `Vendor_IFSC` | `LFBK-BANKL` | **ASSUMPTION** that the bank key is the IFSC (ZMMVENDOR checks `BANKL+0(4)`). Check in SE16 `LFBK` |
| `Vendor_Contact_Name/Email/Phone` | — | **open**: mandatory. Contact person vs address e-mail/phone |
| `Invoice_Number` / `Invoice_Date` | `BKPF-XBLNR` / `BKPF-BLDAT` | standard, to be confirmed with FI |
| `Invoice_Amount` / `Approved_Amount` | — | **open**: gross vs net of TDS / GST-TDS / retention. FI to define |
| `PO/PI_Number` | `BSEG-EBELN` (`RSEG-EBELN` for MIRO) | — |
| `GRN/SRN_Number`, `_Date` | `RSEG-LFBNR` → material doc / SES | **open** for service invoices |
| `Due_Date` | net due date (`NET_DUE_DATE_GET`) | DD-MM-YYYY |
| `Internal_Reference_Number` | `BUKRS`+`BELNR`+`GJAHR` | M1's sample `43001288702025` = BELNR+GJAHR. BUKRS added for uniqueness; confirm the length limit |
| `Product_Type`, `Commodity_Type`, `Commodity` | config / PO item category | **open** |

## Open points

**CPI (Varnika):**

- Confirm the S/4 → CPI synchronous model and get 4 endpoint URLs.
- Auth: basic or certificate.
- Payload: plain JSON with ABAP names, or a WSDL. A SOAP proxy adds about 1–2 ABAP days.
- Confirm that CPI does the field-name and date mapping.

**M1, through CPI:**

- The initiation URL contains `/hpcl/`. Confirm the OVL endpoint.
- The onboarding sample returns `Seller_Id = "VEN001"`, an echo of `Vendor_Id`. Confirm it returns a real `SELLER…` ID.
- §9 asks for ingress from 103.25.172.132, but no API calls OVL. Is there a callback?
- Max PANs per call, max invoices per FU, rate limits, field lengths.
- Error codes for APIs 1 and 2. §7 covers only 3 and 4.
- §2.2 says "two major steps" and then lists four.

**FI (blocks the estimate):**

- Which vendors, company codes and document types are in scope.
- Manual selection by F&A, or an automatic batch.
- `Invoice_Amount` vs `Approved_Amount`.
- The payment block key, so that F110 does not pay an invoice that is with TReDS.
- What happens on each terminal status: Expired/Discard → unblock; Settled → clearing, manual or automatic?
- `Direct_Payment_Settled` handling.
- 1 invoice = 1 FU, or bundled. Recommend 1:1 at first.

## Gotchas noted already

- Double payment is the main risk: an FU-created invoice must be blocked for F110 until the FU reaches a
  terminal status.
- M1 checks these server-side: `M1_0003` duplicate, `M1_0007` due date on a holiday, `M1_0008` approved >
  invoice, `M1_0009` due date too close. Pre-checking them in ABAP saves round trips.
- Once built, the reports with an ALV toolbar need an SE41 status, so they are **paste-only**. A
  screen-free version per MEMORY.md §4.2 could go by ZIP.
