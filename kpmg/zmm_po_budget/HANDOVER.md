# HANDOVER — ZMM_PO_BUDGET (budget control on indirect purchase)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | MM |
| FS | WRICEF 050_BRD_FS |
| What it does | Blocks a PO when the account-assigned value exceeds Budget + Additional Budget in `ZMM_PO_BUDGET` for plant / purchasing group / year |
| Repo path | `kpmg/zmm_po_budget/` (+ `kpmg/zmm_po_budget_deferred/`) |
| Ships by | **HYBRID** — DDIC + message class by ZIP, everything else by hand |
| Status | **BLOCKED. Do not activate anything here until the design contradiction below is resolved** |

## Stop — two mutually exclusive designs are both sitting in the repo

This is the single most dangerous thing in the KPMG set for someone picking it up cold.

- `MANUAL_STEPS.md` §3 describes a **fresh SE19 classic-BAdI implementation** whose `CHECK`
  method calls `ZCL_MM_PO_BUDGET_CHECK=>check_document( )`.
- `ZME_PROCESS_PO_CUST_CHECK_full.abap` (973 lines) and `BADI_CHECK_SNIPPET.abap`
  (111 lines) deliver **the opposite** — inline code pasted into the **already existing**
  `ME_PROCESS_PO_CUST` implementation, with no class involved.

**Both cannot be live.** Confirm which one was actually delivered before activating
either. My recollection is the inline route, which is why the class sits in
`zmm_po_budget_deferred/` wired to nothing — but that is recollection, not evidence, so it
needs checking in SE19 against the running system, not settled from the repo.

## Second documentation defect in the same folder

`MANUAL_STEPS.md` §1 misdescribes the ZIP. It lists `zcl_mm_po_budget_check.clas.*` as
being inside `ZMM_PO_BUDGET.zip`, and §5 says "activate the six objects". The ZIP actually
contains **7 files and no class at all**: `.abapgit.xml`, `package.devc.xml`,
`zde_add_budget.dtel.xml`, `zde_budget.dtel.xml`, `zdo_budget_amt.doma.xml`,
`zmm_budget.msag.xml`, `zmm_po_budget.tabl.xml`. `src/` matches the ZIP.

## Third: a name collision

`kpmg/abapgit_pilot/` claims the **same object names** with different definitions —
a 9-field `ZMM_PO_BUDGET` and no message class. Importing both into one system will
collide. Pick one; never treat the pilot table as the same table.

## Seven open points — `MANUAL_STEPS.md` §4

| # | Question | Where it bites |
|---|---|---|
| 1 | **Scheduling agreements.** ME31L / ME32L do not run through `ME_PROCESS_PO_CUST` at all. Needs `MM06E005` or a scope cut | Half the FS scope |
| 2 | No budget row for plant/group/year — block or allow? Blocks today (message 002) | First weeks after go-live |
| 3 | Calendar or fiscal year for `GJAHR`? Calendar assumed, from `EKKO-BEDAT` | `get_consumed` |
| 4 | Budget currency vs PO currency — error today, no conversion | `check_document` |
| 5 | **Direct vs indirect.** Logic filters `KNTTP = 'K'`, so stock POs are never checked, but the FS overview claims both are covered | Scope |
| 6 | Who may maintain? No auth object in the FS; TMG protects by auth group only | Security design |
| 7 | No visibility report — nothing lets a user see remaining budget before being blocked. Not in the FS; I recommend adding it | User experience |

1 and 5 are scope decisions and need functional. 2, 3, 4 are one-liners marked
`OPEN POINT` in `ZCL_MM_PO_BUDGET_CHECK`.

## Technical notes that will save someone a day

- `ME_PROCESS_PO_CUST` is a **classic** BAdI and an implementation **already exists**,
  carrying other people's changes (`<001>` Saurabh Saumya 20.01.2026, plus blocks by other
  authors). My block is `<002>`. This is an insert, not a new implementation.
- **Insert point matters:** immediately **BEFORE** `CHECK sy-tcode NE 'ME29N'`. `CHECK`
  exits the method when false, so anything after it is skipped for ME29N and for
  `gv_pstyp = 'U'`.
- `CHECK` is the right method, **not** `POST` — `CHECK` is where `ch_failed = 'X'` actually
  stops the save. Use `mmpur_message_forced`.
- The TMG rule needs **both** halves. SE54 event 01 is the enforcement (runs on the DB
  write, cannot be bypassed, survives regeneration). The screen module only greys the field
  and **is lost on every TMG regeneration** — greying alone silently reopens the budget
  field after a regeneration.
- `sy-subrc <> 0` must be set **before** the `MESSAGE` statement: a type E message returns
  to the screen immediately and anything after it never runs.
- Field symbols `<action>` and `<vim_total_struc>` come from the maintenance framework —
  confirm the generated names before activating.
- `WAERS` is on the table but **not in the FS** — added because the FS compares an amount
  with no currency.
- The **ME22N double-count case must be tested explicitly**: changing an existing PO must
  not count its value twice.

## Scheduling-agreement work in the folder

`ZMM_BUDGET_SA_ENHANCEMENT.abap` (281 lines) plus two probes are an implicit enhancement in
`SAPMM06E` for the SA path. Note in that file: **classic Open SQL only** — `SAPMM06E` is an
old program and the syntax check does not run in strict mode, so no commas, no `@`, no
inline `@DATA( )`, no string templates. Keep to that if anything is added there.

An SA item's value has to be derived — `EFFWR` and `NETWR` are both empty on a scheduling
agreement and `NETPR` is populated. The first non-zero of `EFFWR` → `NETWR` → `ZWERT` →
`KTMNG × NETPR / PEINH` wins, per item, and the **same** order is applied to the consumed
history so both are measured the same way.

## Expected traffic this week: none

Nothing here is live. If someone asks for a status, the honest answer is "blocked on a
design confirmation and two scope decisions", not "in progress".

## Stays manual regardless

SE11 TMG generation · SE54 event 01 · the PBO screen module (and re-applying it after
**every** TMG regeneration) · SE19 classic BAdI work · SE93 parameter transaction on SM30.
