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

Open, found while fixing (not changed — separate issues):

- `f_send_email`, "FAILED EMAIL" block: `IF sy-subrc NE 0` tests the **CC** loop, so any customer without a CC address gets an extra *Failed / No customer email address maintained* row even after a good send.
- `sy-cprog = 'RC1TCG3Y'` around `C13Z_RAWDATA_READ` makes the dataset authority check run as an EHS program (bypasses `S_DATASET` for this report). Only relevant while `lc_encrypt = abap_true`.
- With `lc_encrypt = abap_true` the server file name is `INVOICE_<billto>_<docdate> .PDF` — fixed per customer and day, so two runs at once (job + AR rerun, PAL + PALEX) can overwrite each other's file. A unique suffix (`sy-uzeit` / GUID) would close it.
- Supporting GOS attachments (`SO_DOCUMENT_READ_API1` loop) are added without `i_attachment_size` (padded) and unvalidated.
