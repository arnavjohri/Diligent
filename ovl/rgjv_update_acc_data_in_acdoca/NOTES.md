# RGJV_UPDATE_ACC_DATA_IN_ACDOCA — how the SAP JVA correction tool fetches data

**What it is.** SAP standard report, package `GJVA_MIG` (JVA migration tools),
S/4HANA. Corrects the Joint Venture Accounting columns on ACDOCA line items of
documents already posted: venture, equity group, venture partner, recovery
indicator, billing indicator, production period, CO object on balance-sheet lines
and on CO lines. Per entity the user picks "update existing line" in place or
"reverse and repost".

**Standard object — never modified.** Downloaded from OCQ/500 on 19.10.2026 for
analysis only. The three prints are in `original/`:

| File | Object | What it holds |
|---|---|---|
| `RGJV_UPDATE_ACC_DATA_IN_ACDOCA.txt` | report | selection screen + orchestration, no SELECT at all |
| `CL_JVA_MIG_CORRECT_ACDOCA.txt` | class | every DB read and write (91 methods, ~9500 lines plus unit tests) |
| `IF_JVA_MIG_CORRECT_ACDOCA.txt` | interface | the parameter structure and the four methods |

**Why it matters for OVL.** Our `ovl/zfi_acdoca_vname_upd/` copies `ACDOCA-VNAME`
into the custom `ZZ1_VNAME` column. This SAP tool is what fills or repairs
`VNAME` itself. It can only do so where a JVSO1 line exists for the posting;
lines without a JVSO1 counterpart are reported as issues, not corrected.

---

## 1. The report (shell only)

No `SELECT`, no DB function call. Flow:

1. `INITIALIZATION` → `modify_screen`: collapses the two hidden blocks
   (Additional Selection Parameters, Database Update Options), builds pushbutton texts.
2. `AT SELECTION-SCREEN ON` P_BLDOCH / P_BLDLPR / P_MXTSKS / P_DOCTSK: range check,
   silently reset to defaults 500000 / 500 / 20 / 1000000.
3. `AT SELECTION-SCREEN OUTPUT` → `prepare_sel_screen_frame`: `LOOP AT SCREEN`,
   `close_block` sets `screen-active = 0` for modif IDs ADC/UPC (closed) or ADO/UPO (open).
4. `AT SELECTION-SCREEN` → `process_sel_screen_actions`: toggles the hidden flags on
   the four pushbutton ucomms.
5. `END-OF-SELECTION` → `run_process`: packs every range and parameter into
   `gty_program_parameters`, `cl_jva_mig_correct_acdoca=>get_instance( )->execute_process( )`.
   Hard-coded false: all `post_*`, `update_existing_lines`, `post_new_documents`
   (used by sibling reports in GJVA_MIG). `repid_callback = sy-repid`.
6. FORMs `before_rfc` / `in_rfc` / `after_rfc`: SPTA callbacks, delegate to the class.
7. `AT LINE-SELECTION`: double-click → `cl_jva_mig_alv_output` shows a task spool.
8. `ltc_test`: ABAP Unit with `cl_abap_testdouble` on the interface.

Oddity: `set cursor field 'P_VNCORR'` names a field that does not exist (the
parameter is `P_VNUPD`). Harmless.

## 2. JVSO1 ↔ ACDOCA — the relation as coded

JVSO1 (ledger 4A) is the **source of truth** the tool reads; ACDOCA is the
**target** it corrects. JVSO1 carries `REFFIDOC` (FI document) and `REFDOCNR`
(CO document); the class joins on them (`retrieve_acdoca_lines`, `iv_type`):

| iv_type | JVSO1 line | ACDOCA join |
|---|---|---|
| FI | ACTIV = FI doc / FI-MM doc | `rbukrs`, `gjahr = ryear`, `belnr = reffidoc` |
| CO | ACTIV = CO doc | `rbukrs`, `gjahr = ryear`, `co_belnr = refdocnr` |
| 4A / 4B | internal JVA docs | `awtyp = 'BKPFF'`, `zuonr = jvso1-docnr` |
| IN | direct ACDOCA postings by JVA | `vorgn = 'RFRA'`, `prec_awref = refdocnr`, `prec_awitem = refdocln` |
| MI | migrated in S/4 conversion | `mig_source = 'J'` or `awtyp` in JVAME/JVAM, `awref = refdocnr` |
| LG | reposted by this tool earlier | `gjahr = gjahr_new`, `belnr = belnr_new` from `JVA_ACD_UPD_LOG` |

Field correspondence used on the screen (JVSO1 → ACDOCA): RBUKRS/RYEAR/POPER/RACCT
same names; REFFIDOC → BELNR; REFDOCNR → CO_BELNR; RJVNAM → VNAME; REGROU → EGRUP;
RRECIN → RECID; PRODPER → PRODPER; RCNTR → RCNTR; NPLNR → NPLNR.
BILID → BTYPE and RORDNR/RPROJK → AUFNR/PS_PSP_PNR are inferred, not confirmed.

## 3. Data fetch, step by step (class)

1. **`check_cocodes_and_authorities`** — `SELECT bukrs FROM t8jz WHERE bukrs IN r_bukrs`
   (JV-active company codes; none → G5 802). `JV_AUTHORITY_CHECK_PROCESS` per
   company code, process `CUTBACK2`, activity 16 (update) or 48 (test/analysis).
   `JV_GET_LEDGER` → JV ledger.
2. **`get_global_settings`** — re-validates bulk/task limits, `count_jv_documents_total`
   on JVSO1; > 100000 in foreground → confirmation popup.
3. **`get_company_code_settings`** — `cl_jva_settings`, `T8JZ_FAGL` (+ `FI_SPLIT_ACTIVATION`),
   `get_ledgers`: `FINSC_LD_CMP` when "Correct All Ledgers". Then
   `SELECT DISTINCT mig_source, COUNT(docln) FROM acdoca ... WHERE mig_source IS NOT INITIAL`
   to detect migrated documents → changes the WHERE in step 7.
4. **Parallel split** (`calculate_task_packages`) — counts JVSO1 docs per year/period,
   cuts packages of `number_of_docs_per_task`; one SPTA task each
   (`spta_para_process_start_2`, callback forms in the report). One package → silently
   synchronous.
5. **`retrieve_jv_documents`** — the driving SELECT, paged by OFFSET in bulks of
   `bulk_no_of_doc_headers_in_mem` (outer `DO` in `retrieve_and_process_data`):

   ```abap
   SELECT DISTINCT rldnr, rbukrs, ryear, docnr, reffidoc, refdocnr, activ
     FROM jvso1
     WHERE rldnr = '4A' AND rbukrs = @bukrs
       AND (period condition) AND (reference condition)
       AND budat/bldat/racct/rjvnam/regrou/rrecin/bilid/prodper/
           rcntr/rordnr/rprojk/nplnr/aufpl/aplzl IN ranges
     ORDER BY activ, rbukrs, ryear, reffidoc, refdocnr, docnr
     INTO CORRESPONDING FIELDS OF TABLE @rt_doc
     UP TO @bulk_no_of_doc_headers_in_mem ROWS OFFSET @cv_doc_count_fico.
   ```
   Reference condition (`make_reference_condition`) restricts ACTIV to FI / FI-MM / CO
   line types per the two checkboxes and applies S_BELNR / S_REFNR.
   Internal-document mode (both checkboxes off) reads JVSO1 by `r_activ_me` and
   JVSO2 ledger 4B by `r_activ_op` instead.
6. **Line bundle** of `bulk_no_of_docs_for_line_proc` documents:
   - `retrieve_fi_doc_header_data`: `BKPF` FAE on bukrs/gjahr/belnr = reffidoc;
     `COBK` FAE on kokrs/gjahr/belnr = refdocnr. TCODE/BKTXT starting GJEC, GJ19,
     GJ17, GJFARM = internal JVA posting → dropped from FI list. `GLVOR = 'COFI'` →
     REFFIDOC wrong → dropped. Missing KOKRS → `TKA02`.
   - `retrieve_jv_doc_lines`: full JVSO1 lines FAE on ryear/docnr, ledger 4A (+4C when a
     3rd/4th JV currency exists); field list from `cl_jva_util=>get_selection_fields`.
     JVSO2 ledger 4B (+4D) for billing docs. `combine_and_analyze_jv_lines` merges
     currency ledgers.
   - `retrieve_log_items_diff_years`: `JVA_ACD_UPD_LOG` for docs reposted into another year.
7. **`retrieve_acdoca_lines`** — one call per iv_type (table in §2), all
   `FOR ALL ENTRIES ... APPENDING CORRESPONDING FIELDS`. Ledger: `rldnr IN @mr_ledgers`
   or `= jv_ledger`. With migrated docs present, FI/CO reads add
   `( mig_source IS INITIAL OR vname IS NOT INITIAL )`, or exclude MIG_SOURCE S/T/U/V
   when no migrated JV docs exist.
8. **`compare_and_correct_documents`** — JVSO1 sorted by rbukrs/ryear/docnr/docln,
   ACDOCA by rldnr/rbukrs/gjahr/belnr/buzei/co_buzei. Balancing lines excluded if
   P_EXCLBL. `compare_lines` matches; on a miss `get_acdoca_line_by_acc_data` builds a
   dynamic WHERE (`make_where_clause`) on account, posting date, EGRUP, RECID,
   JVACTIVITY — the "heuristic line assignment".
9. **`correct_acdoca_line`** via `cl_jva_mig_post_acdoca`: `update_acdoca_line`,
   `rev_and_rep_acdoca_line`, or `post_missing_acdoca_line`. Test run passes `iv_test`
   and writes nothing to ACDOCA.
10. **Log / output** — `update_log_db_table`: `JVA_ACD_UPD_LOG` via
    `JV_UPDATE_ACD_CORR_LOG IN UPDATE TASK` or direct `MODIFY`, in bulks of
    `log_bulk_no_of_itms_for_db_upd`. Results → `cl_jva_mig_alv_output`.

**Side effect even in test mode:** `get_ledgers` runs
`UPDATE jva_acd_upd_log SET rldnr_acd = ... WHERE rbukrs = ... AND rldnr_acd IS INITIAL`
followed by `COMMIT WORK`, unconditionally. Touches only the tool's log table, not ACDOCA.

## 4. Interface parameters the report never sets

| Field | Effect |
|---|---|
| `r_docnr` | JV doc number range, internal-document SELECTs only |
| `search_by_accounting_data` | false → only the heuristic path of `get_acdoca_line_by_acc_data` |
| `simulate_gl_split`, `update_fagl_split`, `select_open_items_only` | open-item branch is commented out in the class |
| `check_jva_data`, six `post_*` flags | sibling reports (equity change, suspense, cutback, cash call) |
| `update_existing_lines`, `post_new_documents` | hard-coded false; per-entity update/repost radio buttons decide |

`gty_s_task_package` = list of year + periods with a doc count — the unit one SPTA
task receives, hence the parallel WHERE `ryear = ... AND ( poper = ... OR ... )`.

## 5. Where to look in SE80

- SE24 `CL_JVA_MIG_CORRECT_ACDOCA` → `EXECUTE_PROCESS` → `PROCESS_DATA_SYNCHRONOUSLY`
  → `PROCESS_COMPANY_CODE` → `RETRIEVE_AND_PROCESS_DATA`.
- SE11: JVSO1 (fields REFFIDOC, REFDOCNR, ACTIV), ACDOCA (VNAME, EGRUP, VPTNR, RECID,
  BTYPE, ETYPE, PRODPER, MIG_SOURCE, JVACTIVITY, CO_BELNR, PREC_*).
- SE16H: `JVA_ACD_UPD_LOG` for what earlier runs changed.

## 6. FI-only run with a document in S_BELNR — why ACDOCA may not update (19/10/26)

The tool copies JVA values **from the JVSO1 line to the matched ACDOCA line**; it
derives nothing from FI. S_BELNR filters `JVSO1-REFFIDOC`, not ACDOCA-BELNR.
Chain: JVSO1 (rldnr 4A, activ JVFI/JVMM, reffidoc in S_BELNR) → BKPF header
(GJEC/GJ19/GJ17/GJFARM dropped) → ACDOCA by belnr = reffidoc → `compare_lines` →
`compare_field_values` (vname<>rjvnam, egrup<>regrou, ...) → `determine_correction_type`
(update_line only when the entity's "Update Existing Line" radio is set) →
`cl_jva_mig_post_acdoca->update_acdoca_line( iv_test = testrun )`.

Checklist, in order:
1. P_TEST is the default — must be Update Run. Test run writes nothing.
2. JVSO1 and ACDOCA already agree, or JVSO1-RJVNAM is blank → "Document OK", no update.
   Tool cannot fill a venture that JVA itself does not hold.
3. No JVSO1 row with REFFIDOC = document, or ACTIV not JVFI/JVMM → skipped silently.
4. ACDOCA line missing → FI mode maps line_missing to correction_not_possible.
5. Line assignment fails (P_HEUR off) or amounts differ → rev_and_repost_doc, not update.
6. Entity checkbox off, or radio on "Reverse and Repost" → no in-place update.
7. P_JVLEDG → only the JV ledger is read.
8. P_EXCLBL default on → balancing lines (ACTIV/REFACTIV) excluded.
9. Migrated docs present → FI read adds `mig_source IS INITIAL OR vname IS NOT INITIAL`;
   a migrated line with blank VNAME is not selected at all.
10. Update run needs activity 16 on JV process CUTBACK2 (G4 292 otherwise).
11. Hidden filters S_BUDAT/S_BLDAT/... apply to JVSO1 — stale value excludes the doc.

Diagnose: Analysis Only + "Display All Items Processed" on the one document; the
per-line message names the case. Empty list = never selected from JVSO1 (3 or 11).

## 7. Debug result 19/10/26 — where "cannot be fixed" is raised for the 50<>13 doc

Not `line_missing`. The ACDOCA offset line (BSEG 003) IS found by reference; the
amounts differ. Raising statement: `COMPARE_FIELD_VALUES` line 149
(`cs_log-corr_type = gc_corr_type-correction_not_possible`) under
`cs_log-issues &&= gc_issue_type-wrong_amount` (line 144), taken because
`iv_jvdoctype = fi_doc`. Line 63 is the twin for `wrong_amount_sign`.
`DETERMINE_CORRECTION_TYPE` (line 607 caller) only carries the 6 forward —
debugger showed `IV_CORR_TYPE = 6` on entry.

Breakpoint: `COMPARE_FIELD_VALUES`, the `IF` above `wrong_amount` (line 139).
Inspect IS_JVSO-HSL/RCNTR/RJVNAM/TABIX_AGGR vs IS_ACDOCA-BUZEI/HSL/RCNTR/VNAME.
Expected: BUZEI 003, HSL 20,695,950.00, RCNTR blank vs JV group 95,115.00 with CC.

Conclusion: one ACDOCA offset line vs many JV split lines per venture/cost object.
No selection-screen option changes this for an FI document. Functional decision:
reverse + repost with JVA active, or accept and handle expense lines only
(`ZFI_ACDOCA_VNAME_UPD` covers those where VNAME is present).

## 8. Way forward agreed in discussion (19–23/10/26)

Debugger confirmed `COMPARE_FIELD_VALUES` line 149: ACDOCA BSEG 003 WSL/HSL
20,695,950.00 / KSL 222,014.98 vs JV slice 32,400.00 / 345.60. Any grouping would also
fail on KSL rounding (slices converted individually).

Options: (1) reverse + repost the FI doc with JVA active; (2) Z report filling
VNAME/EGRUP/RECID on 1:1 lines from JVSO1 (join RBUKRS/RYEAR/REFFIDOC/REFFIDLN,
ACTIV JVFI/JVMM, only when all slices agree); (3) report history from ledger 4A.

Arnav's preferred fix: **ACDOCA-only split lines** (not in BKPF/BSEG, document type
DJ/DU). Standard mechanism exists — JVA direct ACDOCA postings are identified by
`vorgn = 'RFRA' AND bstat = 'U' AND awtyp = 'BKPFF'` (`MAKE_WHERE_CLAUSE`) and posted
by `CL_JVA_MIG_POST_ACDOCA` (`reverse_acdoca_doc`, `rev_and_rep_acdoca_line`,
`post_missing_acdoca_line`, `post_new_acdoca_doc`). Standard tool uses them 1:1 only.
Proposed Z wrapper: per offset line, reverse the one ACDOCA line and post one
ACDOCA-only line per JVSO1 slice via SAP's class; KSL rounding on last slice; posting
date per functional decision; test run + log; verify by re-running the SAP tool.
Evidence that ACDOCA-only entries already exist in OVL: BELNR CC001NVFLO, 0L/OVL/2026,
VORGN COIN, BLART KJ, AWREF 2726000220 — CO journal entry, not in FB03.

Open before building: `CL_JVA_MIG_POST_ACDOCA` source (where BLART is set);
SE16H ACDOCA OVL with BSTAT = 'U' / VORGN = 'RFRA' and BLART (is DJ/DU the JVA type?);
functional decision on posting date; OSS incident recommended first.
Never INSERT into ACDOCA directly.
