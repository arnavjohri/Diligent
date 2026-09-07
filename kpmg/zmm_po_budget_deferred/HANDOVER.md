# HANDOVER — ZMM_PO_BUDGET_DEFERRED

Prepared 07/09/26 by Arnav Johri · cover period 08/09/26 – 14/09/26

| | |
|---|---|
| Client / project | Astral Limited / UDAY (KPMG) |
| Module | MM |
| Object | `ZCL_MM_PO_BUDGET_CHECK` — global class, 224 lines, + its abapGit `.clas.xml` |
| Repo path | `kpmg/zmm_po_budget_deferred/` |
| Ships by | Nothing today — see below |
| Status | **PARKED. Wired to nothing. Not importable as it stands** |

## What it is

The PO budget check as a standalone global class, written with **no dependency on the BAdI
interface** so the same logic could serve the ME21N / ME22N implementation and, later, the
ME31L / ME32L scheduling-agreement enhancement.

`check_document( )` takes ebeln / ekgrp / bedat / waers / items and returns `bapiret2_t`;
an empty table means the document may be saved. One check **per plant**, because plant is
an item field while purchasing group is a header field — one document can consume several
budgets at once.

## Why it is parked

The delivered path went **inline** into the existing `ME_PROCESS_PO_CUST` implementation
instead. This class is the alternative design, kept because it is the right shape if
scheduling agreements ever come into scope. **It is currently wired to nothing.**

## Two things to know before touching it

1. **The folder is not a valid abapGit repo.** The two files sit at folder root, not under
   `src/`, and there is no `.abapgit.xml`. As it stands it **cannot be imported** — it must
   either move into `kpmg/zmm_po_budget/src/` (and into that ZIP) or get its own `src/` +
   `.abapgit.xml`. Or paste it into SE24.
2. **It is one half of the design contradiction** documented in
   `kpmg/zmm_po_budget/HANDOVER.md`. `MANUAL_STEPS.md` over there describes a BAdI `CHECK`
   method calling this class; the snippet actually delivered there does the opposite.
   **Do not activate both.**

The three `OPEN POINT` markers live in this class: no budget row → block or allow;
calendar vs fiscal year; currency handling.

## Expected traffic this week: none

Nothing consumes this class. If it comes up, the answer is that it is a parked alternative
design, not work in progress.
