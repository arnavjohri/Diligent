# ZMM_BP_CREATE_MAIL — text elements and manual steps

Paste-only object. After pasting and activating the source, maintain the following by hand
(SE38 → Goto → Text elements). **The mail body is built entirely from text symbols — an
unmaintained symbol produces a blank line in the mail.**

## Selection texts

| Field | Text |
|---|---|
| S_CRDAT | BP Creation Date |
| P_BGJOB | Background run (previous day) |

## Text symbols (max 132 chars each)

| Sym | Text |
|---|---|
| B01 | Selection |
| S01 | Your Supplier Account Has Been Successfully Created with Astral |
| T01 | Dear Sir/Madam, |
| T02 | We are pleased to inform that supplier has been registered in system with following supplier account details. |
| T03 | Please note this for further use and communication. |
| T04 | Regards, |
| T05 | Astral Group of Companies. |
| T06 | This e-mail is system generated so DO NOT reply. |
| L01 | Name |
| L02 | Street/House Number |
| L03 | Street 2 |
| L04 | Street 3 |
| L05 | District |
| L06 | Postal Code |
| L07 | City |
| L08 | Region |
| L09 | Country/Reg. |
| L10 | SAP Business Partner Code |
| L11 | Supplier Manager assigned at Astral |
| C01 | Business Partner |
| C02 | Name |
| C03 | City |
| C04 | Supplier Manager Email |
| C05 | Supplier Contact Email |
| C06 | Status |
| C07 | Message |
| M01 | No supplier BPs created for the selected date(s) |
| M02 | No supplier master (LFA1) found - BP not included in the mail |
| M03 | No address found for this BP |
| M04 | No supplier manager email (ADR6 sequence 004) |
| M05 | No supplier contact email (ADR6 sequence 005) |
| M06 | TVARVC ZMM_BP_MAIL_MDM not maintained - MDM not copied |
| M07 | No recipients found - mail not sent |
| M08 | Mail sent to & recipient(s) |
| M09 | Mail could not be sent |
| M10 | OK |
| M11 | No BP with a supplier master found - mail not sent |
| M12 | ALV column not found |

M08: the `&` is replaced by the recipient count at runtime — keep it.

## Program attributes

SE38 → Attributes: Type Executable program, Status Customer production program, Application M.
**Tick "Fixed point arithmetic"** and **"Unicode checks active"**.

## Manual steps outside the program

1. **TVARVC (SM30 → TVARVC, or STVARV):**
   - `ZMM_BP_MAIL_MDM`, type P (parameter), LOW = `patel.jay@astralltd.com`.
     More MDM recipients: add the variable as type S (selection option) with one row per
     address, SIGN I / OPTION EQ / LOW = address. The program reads every row of the name.
   - `ZMM_BP_MAIL_SENDER`, type P, LOW = the no-reply sender address, e.g.
     `noreply@astralltd.com`. Optional — when blank, CL_BCS uses the SU01 e-mail address of
     the user running the job, so that user must then have one.
2. **SE93:** transaction `ZMM_BP_MAIL` → Program and selection screen (report transaction),
   program `ZMM_BP_CREATE_MAIL`, screen 1000.
3. **SE38 variant** `BGJOB`: S_CRDAT blank, P_BGJOB ticked.
4. **SM36:** job `ZMM_BP_CREATE_MAIL_DAILY`, step ABAP program `ZMM_BP_CREATE_MAIL` variant
   `BGJOB`, start condition Date/Time, first run tomorrow **00:05**, Period values → Daily.
   The job user must be authorised for SO/BCS sending (S_OC_SEND) and for the read on
   BUT000/LFA1/ADRC.
5. **SCOT:** SMTP node active and the send job (`SAP&CONNECTINT`, RSCONN01) scheduled,
   otherwise the mail sits in SOST. The domain `astralltd.com` (and any supplier domains)
   must be allowed on the node — check with Basis.
6. **Test:** run in foreground with S_CRDAT = a day on which a supplier BP was created and
   P_BGJOB unticked; check SOST for the mail and the ALV for one row per BP.
