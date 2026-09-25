# Issues — ZMM_BP_CREATE_MAIL

Running log: issue → cause → fix → TR → date. Newest last.

Object: `ZMM_BP_CREATE_MAIL` | KPMG — UDAY / Astral | MM
FS: 057_BRD_FS (Om Prakash, 28/07/2026), received via Ankit | Owners: Om Prakash, Ankit

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 22/09/26 | FS received; eleven queries raised (see QUERIES.md) | — | Queries sent to functional | — |
| 25/09/26 | Answers received: checkbox-first precedence, LIFNR = PARTNER, ADR6 004/005 as given, AN ID struck, creator parked, subject given, one address per BP, use STREET, TVARVC for MDM, one consolidated mail per day to everyone | — | `ZMM_BP_CREATE_MAIL` built, 777 lines. Not yet activated in the target. Open: sender address (Q6), package (Q13), release (Q14), authorisation (Q15) | `<TR>` |
| 25/09/26 | Activated in the target on first paste | — | No activation errors. Next: text elements, TVARVC, SE93, SM36, SCOT check, first foreground test (see TEXTS.md) | `<TR>` |
| 25/09/26 | First run dumped `CALL_METHOD_CONFLICT_TYPE` / `CX_SY_DYN_CALL_ILLEGAL_TYPE` in `DISPLAY_LOG` (SET_MEDIUM_TEXT of CL_SALV_COLUMN) | `SET_SHORT/MEDIUM/LONG_TEXT` take the typed `SCRTEXT_S/M/L`; a text symbol passed directly is not type-compatible in the dynamic call. Mail had already been sent and committed before the dump | New `FORM set_column_text`: moves the text into typed `SCRTEXT_*` variables, then sets all three headings. `DISPLAY_LOG` calls it per column; old block commented inside BOC/EOC. 777 → 820 lines | `<TR>` |
| 25/09/26 | First run: SAPoffice status "Cannot process message; no node determined for <address>" for all three recipients (MDM + ADR6 004 + ADR6 005) | SCOT on DEV has no active SMTP node covering internet addresses. Not a program defect — recipient resolution and send are proven by the status document | Basis asked to configure the SMTP node (address area `*`) and confirm the RSCONN01 send job. Open check: delivered mail must show the full 63-char subject (status doc shows the 50-char short description) | — |
| 25/09/26 | DISPLAY_LOG fix activated; run on a 14-BP range gave "Mail sent to 3 recipient(s)" and the ALV. Recipient logic proven on 3000083-3000089 (ADR6 004/005 = oprj04/oprj05). Headings showed as "Business P" / "Supplier M" | `set_optimize` shrank columns to the data width, so the ALV fell back to the 10-char short text, which had been filled from the long heading | `set_optimize` commented out; `SET_COLUMN_TEXT` takes a width, sets `set_output_length`, and sets the short text only when it fits 10 chars. 820 → 833 lines | `<TR>` |
