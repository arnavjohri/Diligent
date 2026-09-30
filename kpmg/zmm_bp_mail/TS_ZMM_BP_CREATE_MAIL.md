# TS — ZMM_BP_CREATE_MAIL (FS 057_BRD_FS)

## 1. Document control

| Item | Value |
|---|---|
| Object | `ZMM_BP_CREATE_MAIL` (executable report, no includes) |
| Client / project | KPMG - UDAY / Astral Limited |
| Module | MM |
| Related FS | 057_BRD_FS — New BP creation: share a mail with background run program, Om Prakash, 28.07.2026 |
| Author | Arnav Johri |
| Version | 1.0, 25.09.2026 |
| Transport | `<TR>` |
| Source file | `kpmg/zmm_bp_mail/ZMM_BP_CREATE_MAIL.abap` (832 lines) |

## 2. Purpose / background

Suppliers are created as business partners in transaction BP, by BDC and by the Ariba SLP
inbound. Once a day a background job must inform MDM, the supplier manager and the
supplier's direct contact that a new supplier account exists, with the account's name,
address and BP number. The report finds every supplier BP created on the previous day,
builds one HTML e-mail listing all of them and sends it to all recipients in one go.

## 3. Objects affected

| Name | Type | New / changed | Package | TR |
|---|---|---|---|---|
| `ZMM_BP_CREATE_MAIL` | Executable program | New | `<package>` | `<TR>` |
| `ZMM_BP_MAIL` | Transaction (SE93, report transaction) | New | `<package>` | `<TR>` |
| `ZMM_BP_MAIL_MDM` | TVARVC variable | New (client data, no TR) | — | — |
| `ZMM_BP_MAIL_SENDER` | TVARVC variable (optional) | New (client data, no TR) | — | — |
| `BGJOB` | Report variant | New (client data) | — | — |
| `ZMM_BP_CREATE_MAIL_DAILY` | SM36 job | New (client data) | — | — |

No DDIC objects, screens, GUI statuses or message classes. Messages are text symbols.

## 4. Detailed design

### 4.1 Selection screen

| Field | Type | Text | Meaning |
|---|---|---|---|
| S_CRDAT | SELECT-OPTIONS for BUT000-CRDAT | BP Creation Date | creation date range, manual runs |
| P_BGJOB | checkbox | Background run (previous day) | ticked in the job variant |

Date precedence (`FORM derive_dates`): P_BGJOB ticked → previous calendar day, S_CRDAT
ignored. Not ticked and S_CRDAT blank → today. Not ticked and S_CRDAT filled → S_CRDAT.

### 4.2 Processing flow

| Step | Form | Logic |
|---|---|---|
| 1 | `build_group_range` | Range on BU_GROUP = ZDOM, ZIMP, ZREL, ZOTD, ZOTI, ZSUB (FS §2.1, constants) |
| 2 | `fetch_bps` | `BUT000` where CRDAT in range and BU_GROUP in range, ordered by PARTNER. Empty → message M01, stop |
| 3 | `fetch_details` | `LFA1` (NAME1–4) by LIFNR = PARTNER; `BUT020` → ADDRNUMBER (lowest kept); `ADRC` NATION = space (STREET, STR_SUPPL1/2, CITY2, POST_CODE1, CITY1, REGION, COUNTRY); `ADR6` PERSNUMBER = space, CONSNUMBER in ('004','005'); `T005U` and `T005T` in SPRAS 'E'. All FOR ALL ENTRIES, each guarded by IS NOT INITIAL, sorted for binary search |
| 4 | `build_records` | Per BP: no LFA1 → log W (M02), excluded from mail. Else detail row for the mail; missing address / 004 / 005 → log W (M03/M04/M05), still in the mail |
| 5 | `collect_recipients` | TVARVC `ZMM_BP_MAIL_MDM` (all rows) + every 004 and 005 address of the day, de-duplicated. No MDM row → flag M06 |
| 6 | `send_mail` | CL_BCS: HTML document from `build_body`, subject S01 via SET_MESSAGE_SUBJECT (full 63 chars) and the first 50 chars as document title, optional sender from TVARVC `ZMM_BP_MAIL_SENDER`, one internet recipient per address, send immediately, COMMIT WORK. Result in the ALV header and as a status message (job log) |
| 7 | `display_log` | CL_SALV_TABLE, one row per BP: BP, Name, City, Supplier Manager Email, Supplier Contact Email, Status, Message. Fixed column widths, list header = send result. Goes to spool in background |

### 4.3 Mail body (`build_body`)

HTML, Arial 10pt. Greeting T01, intro T02 + T03, then per supplier a two-column table with
rows L01–L11 (Name 1–4 concatenated, Street, Street 2, Street 3, District, Postal Code, City,
Region text, Country text, SAP Business Partner Code, Supplier Manager e-mail), then T04/T05
sign-off and T06 no-reply line. Values are HTML-escaped.

### 4.4 Text elements

See `ZMM_BP_CREATE_MAIL_TEXTS.md` — B01, S01, T01–T06, L01–L11, C01–C07, M01–M12 and the two
selection texts. Maintained by hand after paste.

### 4.5 Manual configuration

1. STVARV: `ZMM_BP_MAIL_MDM` = patel.jay@astralltd.com (parameter; more addresses as a
   selection option, one row each). `ZMM_BP_MAIL_SENDER` = no-reply address (optional).
2. SE93: `ZMM_BP_MAIL`, report transaction, program `ZMM_BP_CREATE_MAIL`, screen 1000.
3. SE38 variant `BGJOB`: S_CRDAT blank, P_BGJOB ticked.
4. SM36: `ZMM_BP_CREATE_MAIL_DAILY`, step `ZMM_BP_CREATE_MAIL` / `BGJOB`, daily 00:05.
   Job user needs S_OC_SEND and read on BUT000 / LFA1 / ADRC.
5. SCOT: SMTP node covering `*`, send job RSCONN01 scheduled. **Open on DEV as of
   25.09.2026** — "no node determined" in SOST.

## 5. Requirement mapping

| FS requirement | Implemented in |
|---|---|
| Daily background job | SM36 job + P_BGJOB (previous day) |
| Vendor BPs created on the date | `fetch_bps`: BUT000-CRDAT + BU_GROUP list |
| Read LIFNR | `fetch_details` LFA1 by PARTNER (LIFNR = PARTNER, confirmed) |
| Date From/To, background checkbox, previous date / system date | selection screen + `derive_dates` |
| Mail to hardcoded MDM address | TVARVC `ZMM_BP_MAIL_MDM` (agreed change) |
| Mail to ADR6 CONSNUMBER 4 and 5 | `fetch_details` ADR6 + `collect_recipients` |
| Body: Name 1–4, Street, Street 2/3, District, Postal Code, City, Region text, Country text, BP code, Supplier Manager e-mail | `build_records` + `build_body` |
| Subject | text symbol S01 |
| Regards / no-reply lines | T04–T06 |
| AN ID | struck out in FS — not built |
| Creator user | parked by functional — not built |

## 6. Test scenarios

| # | Input | Expected | Actual (25.09.2026, DEV) |
|---|---|---|---|
| 1 | Date range with 14 supplier BPs, P_BGJOB off, MDM = tester | ALV 14 rows, header "Mail sent to 3 recipient(s)" | As expected. 3000083–89 OK with 004/005 = oprj04/oprj05; 3000075–82 W no 004/005; 3000077 W no LFA1 |
| 2 | Same, SOST | Mail delivered | **Failed: "no node determined"** — SCOT node missing on DEV. Program side proven by the status document listing all 3 recipients |
| 3 | Date with no supplier BPs | Message M01, no mail | pending |
| 4 | P_BGJOB on, run 00:05 via SM36 | Previous day picked, spool list, job-log message | pending |
| 5 | Delivered mail | Full 63-char subject, HTML table per supplier, all L01–L11 rows | pending (needs SCOT) |
| 6 | TVARVC MDM row missing | Mail still sent to 004/005, header carries M06 | pending |

## 7. Open points

| # | Point | Owner |
|---|---|---|
| 1 | SCOT SMTP node and send job on DEV, then QA/PRD | Basis |
| 2 | Sender address for `ZMM_BP_MAIL_SENDER` (or confirm job user's SU01 address) | Functional / Basis |
| 3 | Package and transport | Arnav |
| 4 | BP without LFA1 is excluded; BP without 004/005 included with no recipient — confirm | Om Prakash |
| 5 | One mail to everyone exposes each supplier's data to the other suppliers of the day (QUERIES R1) — confirm acceptance in writing | Om Prakash |
| 6 | ADR6 sequence 4/5 depends on data-entry order (QUERIES Q3) — MDM to be told | Om Prakash / MDM |
| 7 | No authorisation check in the report (QUERIES Q15) — restrict via SE93 role if wanted | Functional / Security |
