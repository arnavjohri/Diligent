# ZBC_TADIR_SRCSYS_CHANGE — reset TADIR source system for Z/Y objects

**What:** Fixed OCQ -> OCD. Resets `TADIR-SRCSYSTEM` for every custom object created in OCQ so it is an original in OCD.
In the new development system they carry `TADIR-SRCSYSTEM = OCQ`, so every edit is a repair.
This report sets `SRCSYSTEM = SY-SYSID` for customer objects only, making them originals here.

**Run it in:** the development system only (it refuses when old system = current system).

**Guards:** `R3TR` + `SRCSYSTEM = OCQ` (standard objects carry `SAP`, even when modified); plus name Z/Y or package Z/Y/$ — anything else is listed, not changed. Runs only when SY-SYSID = OCD. Test flag default on; confirm popup.

**Ships:** paste-only, single report, no includes, no screens. Create in SE38 as type 1,
then maintain text elements (listed in the program header). Local `$TMP` is fine — it is a
one-off utility; delete it afterwards.

**Gotchas:**
- Direct `UPDATE tadir` writes no change document. Export the UPDATE-run ALV to Excel and keep it
  as the record of what changed.
- Objects already in an open TR as **repairs** keep their repair flag in that TR — release or
  re-collect those TRs after the run.
- Z/Y objects in `$TMP` / SAP packages are not changed by design — they are listed as skipped.
- Standard alternative for a handful of objects: SE03 → Object Directory →
  *Change Object Directory Entries* → Original system.
