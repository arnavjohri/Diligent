# ZFI03CUSTINV1 — NOTES

## What it is

Report `ZFI03CUSTINV1`, PAL FI-AR: prints / previews / saves / e-mails customer
invoices, credit memos and debit memos (Adobe Forms, `FP_JOB_OPEN` → generated form FM →
`gv_form_output`). Four radio buttons: `rb_view`, `rb_print`, `rb_pdf` (GUI download of
`gv_form_output-pdf`), `rb_email` (`f_send_email`, one mail per document, e-mail log ALV
`gt_email` at the end). Includes: `ZFI_03_CUSTINV_TOP` (550 lines, globals),
`ZFI_03_CUSTINV_SEL` (38), `ZFI_03_CUSTINV_FORM` (5020 → 5166, all FORMs). Author
DAGOYAOY (2022); later hands PPUNO, ARAO. Package ZABAP. Message class ZNDPH_AGOYAOY03.

## Files

- `original/ZFI03CUSTINV1.TXT` — the SE80 **print listing** as supplied on 10.10.26
  (whole program with includes, 72-column wraps, page headers). Never edited.
- `original/rebuilt/*.abap` — the same source rebuilt one file per include by
  `scripts/unlist.py` (joins the wrapped lines, strips headers, keeps source line
  numbers 1:1). Derived, not downloaded; diff a future SE80 download against these.
- `ZFI_03_CUSTINV_FORM.abap` — the **corrected include**, whole file, paste target.

## Shipping: PASTE ONLY

An include of an existing program with a selection screen and GUI status — not
zippable. Open `ZFI_03_CUSTINV_FORM` in SE38/SE80, select all, paste the whole file,
activate `ZFI03CUSTINV1`. Only this include changed; TOP and SEL are untouched.

## The mail path, and why it is the only one that can corrupt

`rb_pdf` downloads `gv_form_output-pdf` as is. `rb_email` does not attach it: `f_encrypt`
writes it to `<ZTMP_DIR>/<name> .PDF` on the application server (yes, with a blank before
`.PDF` — the stray `'''` is replaced by a space; consistent for write and read, so left
alone), runs SM69 command `ZDJ_ENCRYPTPDF` with `-j -P <ccode+DDMMMYY> "" "<file>"`,
waits 2 s, reads the file back (`C13Z_RAWDATA_READ` under `sy-cprog = 'RC1TCG3Y'`) and
attaches the read-back. After the 10/10/26 fix every step is checked and the read-back
is validated before it can replace the in-memory PDF; on failure nothing is sent and the
e-mail log row says why.

`ZTMP_DIR` comes from `ZGLBPARAM` (`zparam_id = 'ZTMP_DIR'`, `zprog = 'ZFI005'`,
`zcounter` 001 = DS4, 002 = QS4, 003 = PS4). Any other SID → no directory → now a
logged failure instead of a write to `/`.

## What to check on the system (no dev access needed)

Cheapest first; each one discriminates between the remaining failure modes.

1. **SOST / SOSV** — open one of the failed mails, note the attachment size. 0 KB or a
   few bytes = empty read-back; a plausible size = garbage or truncated bytes.
2. **SM69** — command `ZDJ_ENCRYPTPDF` (Linux): operating-system command and parameters.
   The program passes `-j -P <pw> "" "<file>"`, which is `zip` syntax with an empty
   archive name. Whatever the script does with `$3`/`$4` decides whether the PDF on disk
   is rewritten, clobbered or untouched.
3. **AL11** — the `ZTMP_DIR` path for PS4: is `INVOICE_<customer>_<date> .PDF` there, what
   size and timestamp, and is it a PDF (`%PDF` first bytes)? Compare with the SOST size.
4. **SM37** job log / spool of the automated run — the new `MESSAGE` and the e-mail log
   ALV now carry the exact failing step (`C13Z_RAWDATA_READ rc 2 …`, `not encrypted …`,
   `ZDJ_ENCRYPTPDF status E exit n: …`).
5. **ST22** only if something still dumps.

## The two switches in `f_send_email` (functional to confirm)

- **`lc_encrypt`, default `abap_false`** — the round trip is skipped; the mail carries
  `gv_form_output-pdf` with its exact size, the same bytes Save-as-PDF downloads. Chosen
  because the mail body tells the customer **no password** (every such line is commented
  out in all six variants; the block was lifted from a payslip program — the commented
  text still says "your payslip is protected by a unique password"). An encrypted PDF
  would therefore be unopenable for the customer anyway. This is the only setting that
  resolves INC01967 with certainty and without any server-side dependency.
- **`lc_plainok`, default `abap_false`** — only matters with `lc_encrypt = abap_true`:
  whether a valid but unencrypted read-back may still be sent.

If the business does want password-protected invoices: `lc_encrypt = abap_true`, fix
whatever the log then reports (see "What to check"), add a password line to the body
texts, and give the server file a unique name (see ISSUES.md, open items).

## Debugging in PRD without sending a mail (code as it stands in PRD)

SE38 `ZFI03CUSTINV1`, one document, `rb_email`; `/h`, F8. Breakpoints → *Breakpoint at* →
function modules `SXPG_COMMAND_EXECUTE`, `C13Z_RAWDATA_READ`, `SCMS_BINARY_TO_XSTRING`;
method `CL_BCS` → `SEND`. At each stop F7 back to the caller and read: `l_file` (then
**CG3Y** it from a second session, binary, open on the PC — the decisive test),
`sy-subrc`, **`t_result`** (the OS command's own output), `l_orln`, `l_lines`,
`ld_buffer` length vs `gv_size` (hex `25 50 44 46` … `25 25 45 4F 46`), lines of
`i_tline`. At `CL_BCS->SEND` do not step: `/n` in the debugger command field ends the
program before `send`; `COMMIT WORK` is the next statement, so BCS persists nothing.
Check SOST afterwards. Debug on DS4 instead if it reproduces there.

## Gotchas

- `gv_elog_status` / `gv_elog_message` are globals and were never cleared per document;
  a send that threw after a successful one was logged *Successful*. Now cleared at the
  top of `f_send_email` and set to *Failed* in `CATCH cx_root`.
- `WAIT UP TO 2 SECONDS` in `f_encrypt` is an implicit `COMMIT WORK` per document. Left as
  is — it predates the fix and the mail is committed right after anyway.
- 68 lines of the *original* include are already longer than 120 characters (old
  commented `CONCATENATE`s and comment banners). They are live in the system and were not
  touched; nothing new is over 120.
- The listing parser (`scripts/unlist.py`) pads the first 72-column chunk back to 72
  before joining a wrapped line, because the printer trims trailing blanks — without that
  `FOR` + `ALL ENTRIES` fuse into `FORALL ENTRIES`.
