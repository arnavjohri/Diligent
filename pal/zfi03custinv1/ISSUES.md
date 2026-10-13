# Issues — ZFI03CUSTINV1

Running log: issue → cause → fix → TR → date. Newest last.

Object: report `ZFI03CUSTINV1` (Customer Invoice, Credit Memo and Debit Memo Forms,
Adobe Forms, package ZABAP), includes `ZFI_03_CUSTINV_TOP` / `_SEL` / `_FORM`.
PAL (Philippine Airlines) | FI-AR | Systems DS4 → QS4 → PS4.
Ticket: INC01967 | Reporter: Czarmagne Ashly Retis (AR) on behalf of Cebu Air, Inc. /
Cebu Pacific Air (Jazieline Kaye B. Caoile).
Earlier changes in the same FORM: INC01036 (ARAO 31/07/2026, all addresses in TO),
INC01368 (ARAO 07/08/2026, default address in TO, others CC).

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 10/10/26 | Invoice PDF mailed by the program (`rb_email`) cannot be opened — Acrobat: "not a supported file type or … damaged"; Edge: "We can't open this file", 0 of 0 pages. Example attachments `INVOICE_CEBU PACIFIC AIR_19-MAY-2026.PDF`, `INVOICE_CEBU AIR, INC._27-JUL-2026.PDF`. The same document saved with `rb_pdf` (Save as PDF) opens; a manual resend by AR opens | `f_send_email` never attaches the Adobe output `gv_form_output-pdf` that the download path uses. It writes it to the application server as padded 255-byte `solix` lines (`f_encrypt`), runs external command `ZDJ_ENCRYPTPDF` with `-j -P <pw> "" "<file>"` (the archive-name argument is empty — its build is commented out), waits 2 s, reads the file back with `C13Z_RAWDATA_READ`, converts it and **overwrites `i_tline` with the read-back**, then attaches it with `i_attachment_size = gv_zipsize`, which is never filled. Not one return code in that chain is checked — `OPEN DATASET`, the file exceptions, the `ZTMP_DIR` lookup, `SXPG_COMMAND_EXECUTE` status, `C13Z_RAWDATA_READ`, `SCMS_BINARY_TO_XSTRING` — so an empty, truncated or clobbered read-back goes out as `INVOICE_….PDF` and the e-mail log still says *Successful*. Which step fails on PS4 is only visible on the server (SM69 command text, AL11 file, SOST attachment size) — see NOTES.md, "What to check" | `ZFI_03_CUSTINV_FORM.abap`: `f_encrypt` writes the PDF with exact length (`TRANSFER` of the xstring, no padding), reports `ZTMP_DIR` missing / open failure / file exceptions, returns the `ZDJ_ENCRYPTPDF` status + exit code + first protocol line for the log. `f_send_email` checks `C13Z_RAWDATA_READ` and `SCMS_BINARY_TO_XSTRING`, validates the read-back (≥ 4 bytes, `%PDF` header, `%%EOF` in the last 1024 bytes, `/Encrypt` present), passes the exact `i_attachment_size`, and on any failure **sends nothing**: log status *Failed*, message `PDF encryption failed, mail not sent: <reason>`, `MESSAGE … TYPE 'S' DISPLAY LIKE 'E'`. `CATCH cx_root` now also logs *Failed* instead of leaving the previous document's *Successful*. **Switch `lc_encrypt` (default `abap_false`)**: the whole round trip is skipped and the in-memory PDF is attached as is, byte-identical to Save-as-PDF — because the mail body carries **no password instruction** (every "enter your password" line is commented out in all six body variants; the encryption block was copied from a payslip program), so an encrypted PDF could not be opened by the customer either. `abap_true` re-enables the checked encryption path; there `lc_plainok` decides whether a valid but unencrypted read-back may go out. Functional to confirm the default | `<TR>` |

**PRD debug evidence, 12/10/26** (dialog, Arnav's user, credit memo AVIAREPS KFT.,
stopped at `o_send_request->send` and terminated with `/n`, nothing sent):
`gv_size` 21 634 · file written 85 × 255 = 21 675 · `l_orln` 21 675 · `l_lines` 9 ·
`ld_buffer` starts `%PDF-1.6` · `i_tline` 85 × 255 at send. So under a developer user the
round trip returns the original PDF plus 41 zero bytes, the external command does not
alter the file, and nothing is encrypted — that mail would open. The broken mails therefore
come from runs where a step of the round trip fails for the executing user (job / AR user
without `S_DATASET` on the `ZTMP_DIR` path for `OPEN DATASET` and `C13Z_RAWDATA_READ` under
`RC1TCG3Y`, or `S_LOG_COM` for `ZDJ_ENCRYPTPDF`) and the empty read-back is attached as a
0-byte PDF. To confirm: SOST attachment size of the Cebu mails, job spool for
`operating system could not open file`, job user's authorisations. Either way
`lc_encrypt = abap_false` removes the dependency.

**Confirmed user-dependent, 12/10/26:** AR reports the mail is fine when sent by one user
ID and broken when another user ID sends it. That is the signature of the round trip failing
on an authorisation of the *executing* user (no message, log says Successful). User-dependent
checks in the mail path, in order: `F_BKPF_BUK` (ACTVT 01, selection screen — visible
message s016), `S_DATASET` write for `OPEN DATASET` in `f_encrypt` (swallowed), `S_LOG_COM`
for `ZDJ_ENCRYPTPDF` (ignored, harmless), `S_DATASET` read under program `RC1TCG3Y` for
`C13Z_RAWDATA_READ` (swallowed → empty attachment), `S_OC_SEND` for the external send
(visible as a WRITE line from `CATCH cx_root`). Exact missing values: STAUTHTRACE on the
failing user while they run one document. With `lc_encrypt = abap_false` the file-system
and OS-command authorisations are no longer needed by business users at all.

**Role evidence, 13/10/26** (SUIM roles with `S_DATASET` vs. role lists of the working user and
three failing users): all four users share `ZPAL_GENERAL_ROLE` (has `S_DATASET`, evidently not
for this path/program); failing user 3 also has `ZFI_GL_MANAGER_PAL` (has `S_DATASET`) and
still fails. The only `S_DATASET`-carrying roles the working user has and no failing user has
are **`ZFI_AR_COLLECTIONS_PAL`** and **`ZFI_AR_COLLECTIONS_PALEX`** — the file authorisation
that makes the encryption round trip work lives there. Confirm in PFCG → Authorizations →
`S_DATASET` (expect `PROGRAM` ZFI03CUSTINV1 / RC1TCG3Y or `*`, `ACTVT` 33 + 34, `FILENAME`
on the `ZTMP_DIR` path). Decision: no role change recommended — ship `lc_encrypt = abap_false`.

**Resolution path agreed 13/10/26:** PRD cannot be changed from Arnav's ID, so the ticket
answer is a role assignment: `ZFI_AR_COLLECTIONS_PAL` (PR01 users) / `ZFI_AR_COLLECTIONS_PALEX`
(2P01 users) to the affected senders, after a PFCG display check of its `S_DATASET` /
`S_LOG_COM` values; Security may instead copy those values into `ZFI_AR_ACCOUNTANT_PAL`.
The corrected include (`lc_encrypt = abap_false`) goes DS4 → QS4 → PS4 by transport as the
permanent fix, after which the file authorisations are no longer needed.

**Confirmed 13/10/26 — `SUSR_USER_AUTH_FOR_OBJ_GET`, object `S_DATASET`, PRD:**
working user holds four authorisations: `T-D454017600` (ACTVT 06/33/34/A6/A7, FILENAME `*`,
PROGRAM `*`), `T-D454031300` (ACTVT 06/33/34, FILENAME `*`, PROGRAM `SAPLSX03`),
`T-D454032600` and `T-D454032700` (ACTVT `*`, FILENAME `*`, PROGRAM `*`). Failing user holds
only `T-D454031300` — PROGRAM `SAPLSX03`, i.e. file access solely for the SAPoffice function
group. Therefore `OPEN DATASET` under program `ZFI03CUSTINV1` and `C13Z_RAWDATA_READ` under
`RC1TCG3Y` are refused for that user, the read-back is empty and a 0-byte PDF is mailed.
Root cause of INC01967 is closed: missing `S_DATASET` for the round trip, hidden by the
unchecked return codes. Which role carries the `PROGRAM *` authorisations: SE16 `AGR_1251`,
OBJECT `S_DATASET`, FIELD `PROGRAM`, LOW `*`, AGR_NAME in the working user's roles.

**Role-menu check 13/10/26:** SUIM roles-by-transaction for `ZFIBSDMCM` returns only
`ZSAP_ALL_DISPLAY` — no business role carries the transaction in its menu; AR users start it
through wildcard `S_TCODE`. The `S_DATASET PROGRAM *` that makes the mail work for one user
sits in the Collections role(s) for other reasons, so the "working" case is an accident of
role content, not a design. Recommendation to Security: add the narrow `S_DATASET`
(ACTVT 33/34, PROGRAM `ZFI03CUSTINV1` + `RC1TCG3Y`, FILENAME `<ZTMP_DIR>/*`) and
`S_LOG_COM ZDJ_ENCRYPTPDF` to `ZFI_AR_ACCOUNTANT_PAL` (shared by all failing users), and put
`ZFIBSDMCM` into that role's menu; alternative accepted by business: assign
`ZFI_AR_COLLECTIONS_PAL`. Permanent: transport of the corrected include.

**Decision 13/10/26 (Arnav):** ask Security to assign `ZFI_AR_COLLECTIONS_PAL` (/`_PALEX`) to the
affected senders first — identical to the working user — and retest with one document to an
internal bill-to, checking the SOST attachment size before releasing the rest. Narrow-role
alternative stays documented above; transport of the corrected include remains the permanent fix.

Open, found while fixing (not changed — separate issues):

- `f_send_email`, "FAILED EMAIL" block: `IF sy-subrc NE 0` tests the **CC** loop, so any customer without a CC address gets an extra *Failed / No customer email address maintained* row even after a good send.
- `sy-cprog = 'RC1TCG3Y'` around `C13Z_RAWDATA_READ` makes the dataset authority check run as an EHS program (bypasses `S_DATASET` for this report). Only relevant while `lc_encrypt = abap_true`.
- With `lc_encrypt = abap_true` the server file name is `INVOICE_<billto>_<docdate> .PDF` — fixed per customer and day, so two runs at once (job + AR rerun, PAL + PALEX) can overwrite each other's file. A unique suffix (`sy-uzeit` / GUID) would close it.
- Supporting GOS attachments (`SO_DOCUMENT_READ_API1` loop) are added without `i_attachment_size` (padded) and unvalidated.
