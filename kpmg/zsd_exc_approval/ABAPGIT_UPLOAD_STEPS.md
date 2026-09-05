# Uploading ZSD_EXC_APPROVAL.zip with abapGit standalone

One ZIP, 18 files, 14 objects. Everything for **Paints (141.B)** except the table
maintenance generator, which abapGit cannot serialise. **Rebuilt 05/09/26** — six
defects in the hand-written XML were corrected first (`ZIP_IMPORT_NOTES.md`); use this
build, not the 03/09/26 one.

## Before you start

1. Create the target package in SE80/SE21 if it does not exist, and have a workbench
   transport ready. abapGit asks for both on the pull.
2. `ZSD_EXC_APPR_ADHESIVE` (141.A) is **not** in this ZIP — see "Why A is not here".

## Steps

1. `SE38` -> `ZABAPGIT_STANDALONE` -> Execute.
2. **Repository -> New Offline** (or "New Offline Repo" on older builds).
3. Package: your UDAY SD Z package. Name: `ZSD_EXC_APPROVAL`. Create.
4. **Import package from ZIP** (the "Import" / "zip" button on the repo screen) and pick
   `ZSD_EXC_APPROVAL.zip`.
5. The object list appears. You should see **14 objects**:

   ```
   DEVC  <your package>
   DOMA  ZSD_DO_EXC_SRNO      ZSD_DO_EXC_MONTH     ZSD_DO_EXC_TYPE
   DOMA  ZSD_DO_EXC_AMOUNT    ZSD_DO_EXC_REMARKS
   DTEL  ZSD_DE_EXC_SRNO      ZSD_DE_EXC_MONTH     ZSD_DE_EXC_TYPE
   DTEL  ZSD_DE_EXC_AMOUNT    ZSD_DE_CM_AMOUNT     ZSD_DE_EXC_REMARKS
   TABL  ZSD_EXP_PAINTS
   PROG  ZSD_EXP_PAINTS_UPLOAD                     ZSD_EXC_APPR_PAINTS
   ```

   If the list is empty or the pull short-dumps `XML_FORMAT_ERROR` /
   `CX_XSLT_FORMAT_ERROR`, go to ST22 first and note **which file** abapGit was
   deserialising (the `FROM_XML` / `READ` frame shows it) — that is the one fact every
   earlier attempt failed to capture. Then use the manual route
   (`ZSD_EXP_PAINTS_DDIC.md` for the DDIC, paste for the two programs). See
   `ZIP_IMPORT_NOTES.md` for what was fixed on 05/09/26 and what is still unproven.

6. **Pull**. Give the transport when asked.
7. Activate in this order — the order matters, each step needs the previous one active:
   **5 domains -> 6 data elements -> ZSD_EXP_PAINTS -> the 2 programs.**
   SE80 -> right-click the package -> Activate, or SE11/SE38 per object.

## After the pull — four things the ZIP could not carry

| # | What | Where |
|---|---|---|
| 1 | Foreign keys: `ZCUSTOMER` -> KNA1, `WAERS` -> TCURC | SE11, Foreign Keys button, accept SE11's proposal. `ZSD_EXP_PAINTS_DDIC.md` §3.4 |
| 2 | Enhancement category — the ZIP now sets "Can be enhanced (deep)" (`EXCLASS 4`); just confirm it under SE11 -> Extras -> Enhancement Category. §3.7 |
| 3 | "Log data changes" tick | SE11 -> Goto -> Technical Settings. §3.6 |
| 4 | **Table maintenance generator** | SE11 -> Utilities -> Table Maintenance Generator. §4 — auth group `&NC&`, function group `ZSD_EXC_PAINTS`, one step, overview screen `0001`, standard recording routine |

The text elements for both programs **are** in the ZIP (54+5 and 38+10 entries), so you do
not need to type them into SE38.

Check `ZSD_DO_EXC_AMOUNT`'s Output Length after import: it is set to 31, computed rather
than read off a system. If SE11 objects, blank the field and press Enter to let it
recalculate.

## Why A is not here

`ZSD_EXC_APPR_ADHESIVE` is already active in your system with the `BP3100` WHERE clause
you corrected by hand on 02/09/26. That clause was never sent back, so on 05/09/26 the
repo copy was corrected on reasoning alone: the `INFOCATEGORY` predicate is gone and the
read filters on `INFOTYPE` only, with the category enforced on the selection screen. That
may or may not be the same clause you activated. An abapGit pull **overwrites the SAP
object with the repo version**, so A stays out of the ZIP until the two are reconciled.

To reconcile: `ZR_PROG_DOWNLOAD` the active `ZSD_EXC_APPR_ADHESIVE`, drop it in
`incoming/`, and the diff against the repo copy settles it (ISSUES.md #17). The repo copy
also carries the other 05/09/26 corrections (sorted output, positional commitment-date
link, smaller BSID/BSAD read, optional Division, sturdier date parse) that the active
version does not have, so the reconciled repo copy is what gets pasted back.
