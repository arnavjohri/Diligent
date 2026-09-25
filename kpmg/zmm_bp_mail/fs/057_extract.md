# FS 057 — text extract (raw text pulled from the .doc; formatting such as strikethrough is lost)

Client: Astral Limited | WRICEF: 057_BRD_FS | Prepared by: Om Prakash | 28.07.2026
Type of development (as written): Conversion — actually a new report / outbound mail.

## Overview and Scope
When BP (Supplier) created in system (by BDC/Ariba SLP), daily batch job to perform and send
new BP code and ~~AN ID (if from Ariba)~~ (struck out in the FS — confirmed by Arnav 25/09/26)
Supplier manager email ID to following team.
- MDM (project owner in case of Ariba)
- Supplier Manager
- Supplier direct contact person (PO send)

References: BP (Supplier) Creation using T code BP
Functional Description: Business Partner (Supplier) Creation Email Notification
Initiating process: BP creation BP T Code & BAPI Program.

## 2.1 Functional Details
A background job will run daily. During execution, the system will identify all Vendor
Business Partners created on the current date. For each Vendor BP identified, the system will
read the Vendor Number (LIFNR) and creator user as per below logic.

Selection Screen: Date From / To; Time 12:05 AM; Checkbox for background job.
Needs to pick previous date. If we run manually & background job checkbox is not selected,
then system should pick the data as of the system date.

Filter BPs: Pass PARTNER into BUT000 and get BU_GROUP = ZDOM, ZIMP, ZREL, ZOTD, ZOTI, ZSUB.

Email recipients:
1. Hardcoded patel.jay@astralltd.com
2. LIFNR vs PARTNER into BUT020 -> ADDRNUMBER; ADDRNUMBER & CONSNUMBER = 4 into ADR6 -> SMTP_ADDR
3. LIFNR vs PARTNER into BUT020 -> ADDRNUMBER; ADDRNUMBER & CONSNUMBER = 5 into ADR6 -> SMTP_ADDR

## Email draft
Dear Sir/Madam,
We are pleased to inform that supplier has been registered in system with following supplier
account details. Please note this for further use and communication.

- Name 1..4 (LFA1-NAME1..NAME4)
- Street/House Number (BUT020 -> ADRC MC_STREET)  [Arnav 25/09/26: use STREET]
- Street 2 (ADRC-STR_SUPPL1)
- Street 3 (ADRC-STR_SUPPL2)
- District (ADRC-CITY2)
- Postal Code (ADRC-POST_CODE1)
- City (ADRC-CITY1)
- Region (description) (ADRC-REGION -> T005U-BLAND -> BEZEI)
- Country/Reg. (description) (ADRC-COUNTRY -> T005T-LAND1, SPRAS = EN -> LANDX)
- SAP Business Partner Code (LFA1-LIFNR)
- Supplier Manager assigned at Astral: email (BUT020 -> ADR6 CONSNUMBER 4 -> SMTP_ADDR)

Regards,
Astral Group of Companies.
This e-mail is system generated so DO NOT reply.

Sections 2.2, 2.3, 3, 3.1: empty.
