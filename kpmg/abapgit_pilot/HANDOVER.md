# HANDOVER — ABAPGIT_PILOT (proof of concept)

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Repo path | `kpmg/abapgit_pilot/` |
| Status | **NOT A DELIVERABLE.** Proof of concept, never confirmed to have imported |

## What it is

A deliberately small test of one question: **can DDIC objects be created in the SAP system
by importing an abapGit repository, instead of being built by hand in SE11?**

It exercises the full **DOMA → DTEL → TABL** dependency chain, which is the only part
genuinely in doubt — abapGit has to create and activate them in the right order for the
table to activate at all.

Contents: `ZDO_BUDGET_AMT` (CURR 15,2), `ZDE_BUDGET`, `ZDE_ADD_BUDGET`, `ZMM_PO_BUDGET`
(**9 fields here**), `package.devc` — packaged as `ZMM_PO_BUDGET_pilot.zip` (6 files).
No message class. `README.md` carries the procedure and pass criteria.

## The two things that matter this week

1. **Name collision — this is the live risk.** The pilot uses the **same object names** as
   the real `kpmg/zmm_po_budget/` repo, with a **different field count** and no message
   class. Importing both into one system will collide. Pick one; **never treat the pilot
   table as the same table.**
2. **Nothing here proves anything yet.** There is no record that this ZIP was ever
   imported. Do not cite it as evidence that the abapGit path works — and note that the
   wider evidence runs the other way: `kpmg/zfi_tds_cl34` made four attempts and
   short-dumped four times.

## If someone does run the pilot

- **Use standalone / offline mode.** `ZABAPGIT_STANDALONE` is a single report with no
  package dependencies, and an offline repo takes a ZIP from the PC, so the server never
  needs to reach github.com — which matters because outbound internet from the app server
  is blocked here. Online repos and the abapGit ADT integration require direct GitHub
  access; starting there fails for **network** reasons and tells you nothing about whether
  DDIC import works.
- **If the table fails on the first pass, pull a second time.** abapGit retries
  dependencies but a single pass can leave objects inactive.
- The package must exist or be creatable — create it in SE21 first if the user cannot.
  `$TMP` will not transport.
- **Pass criteria:** all four objects active in SE11; `ZMM_PO_BUDGET` activating with no
  "field does not exist" errors; `BUDGET` / `ADD_BUDGET` showing currency reference
  `ZMM_PO_BUDGET-WAERS`; objects on a transport.
- **Check the `PROGDIR` order rule does not apply here** — this pilot is DDIC only, no
  programs, so the `VARCL` ordering defect that has bitten two other objects cannot occur.

## What the pilot does NOT cover

Even a full pass proves nothing about SE51 screens, SE41 GUI statuses, SE54 maintenance
generation, SNRO number ranges, SU21 auth objects or SCDO change-document objects. Those
stay manual on every object regardless of the result.
