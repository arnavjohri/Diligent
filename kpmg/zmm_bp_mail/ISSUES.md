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
