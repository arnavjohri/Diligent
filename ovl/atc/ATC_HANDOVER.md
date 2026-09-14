# ATC correction — handover

**Scope:** everything currently known about ABAP Test Cockpit (ATC) S/4 readiness
remediation on this machine — standing rules, activation and runtime traps with the
evidence behind them, finding-by-finding routing, verified mappings, the state of the OVL
batch, and the questions that are still open.

**Written:** 25/08/26 · **Project:** OVL (ONGC Videsh, ECC→S/4) · **Owner:** Arnav Johri

Hand this file to a new session before it touches a single ATC finding. It is the
distillation; the long-form sources are listed in §1 and are still the place to go for a
mapping this file does not spell out.

---

## 1. Sources of truth, and what each one is for

| File | What it holds | Trust |
|---|---|---|
| `.claude/skills/atc-fix/SKILL.md` | The operating procedure — 31 rules + 5-phase workflow. Loaded by `/atc-fix`. | Current. This handover and that skill must stay in step. |
| `ovl/atc/kb/ATC_S4_COMPLETE_KNOWLEDGE_BASE.md` | 567 long lines: ~50-note disposition catalogue, table→CDS maps, DB-write→API map, ZATC_RESULT_CORRECTION internals, per-client dispositions. | **Third-party working notes** (cipla / Coca-Cola-CCEJ / ONGC). Mixed clients, self-contradicting in places. Read the slice, never quote it as OVL policy. |
| `ovl/atc/kb/SESSION_HANDOFF_ATC_S4_LEARNINGS.md` | 229 lines: dump→cause→fix table, perf patterns, CDS maps, BDC→BAPI worked example, MATNR selection-screen fix, FBL5N→FBL5H. | Same caveat. Its "programs touched" list (L198-212) is cipla/coke — do not reuse. |
| `ovl/atc/AUDIT-2026-08-23.md` + `AUDIT-detail-2026-08-23.md` | Rule audit of the 51 corrected OVL objects: 433 findings, 46 expected activation failures. | Current, machine-generated, **candidates for review** — the auditor reads source, it does not compile. |
| `ovl/atc/corrections/ONGC_abapgit/UPLOAD_PROCESS.md` | How the 51 objects go back into SAP (export → overlay → import, per package). | Current. |
| `CLAUDE.md` (repo root) | Shared marker / correction / delivery rules for all work, not just ATC. | Authoritative; the skill adds to it, never overrides it — except the author tag (§2). |
| `ovl/atc/kb/atc-ovl-project-context.md` | Project identity. Repo copy of the laptop memory file of the same name (same content). | Current. |
| `ovl/atc/kb/atc-knowledge-base-files.md` | Where the KB lives. Repo copy of the laptop memory file of the same name (same content). | Current. |

The KB and handoff were originally read from `C:\Users\ArnavJohri\Downloads\`; copies now
live in `ovl/atc/kb/` so they survive the machine. The KB blows the Read token cap if read
whole — read named line ranges (index at the end of the `atc-fix` skill).

---

## 2. Project identity — the first thing to get right

```
Project: OVL.  Change-marker author tag = SAP_ABAP.
NEVER write ABAP7 (cipla) or EJX9007359 (coke/CCEJ) into an OVL file.
```

**Marker format — match the file.** Default, matching the 205 existing pairs in the
delivered corrections:

```
*--- BEGIN OF CHANGE BY SAP_ABAP <date> FOR ATC ---
*--- END OF CHANGE BY SAP_ABAP <date> FOR ATC ---
```

If the file already carries ZATC-style markers, extend that style instead:

```
" Code Remediation changes S4 2025_1_P Conversion **BEGIN OF CHANGE BY SAP_ABAP <date>  for ATC
```

**Open question — marker date format.** `CLAUDE.md` mandates `DD/MM/YY` with slashes for
change markers (dots `DD.MM.YYYY` are for object *header* blocks). The delivered ATC files
carry the dotted `DD.MM.YYYY` form in their *markers* — e.g.
`BEGIN OF CHANGE BY SAP_ABAP 08.08.2026 FOR ATC` in `ZPME_SFORM_REPORT.abap:213`. That is
precedent, not a decision. **Write `DD/MM/YY` per CLAUDE.md unless Arnav confirms the dotted
form for ATC markers.** Ask before the first marker of a batch. Still unanswered as of
25/08/26.

The date is the date the change is made — never copied from a sample file.

**Pragma tokens:**

| Finding family | Token |
|---|---|
| Field Length Extension | `"#EC CI_FLDEXT_OK[<note>]` |
| SELECT without ORDER BY | `"#EC CI_NOORDER` (bare, no note) |
| Usages of Simplified Objects / Transactions | `"#EC CI_USAGE_OK[<note>]` |
| Search for Database Operations | `"#EC CI_DB_OPERATION_OK[<note>]` |
| Use of Native SQL | `"#EC CI_EXECSQL` |

---

## 3. Rules that produce a wrong deliverable if broken

1. **Real fix over suppression.** No P1 `#EC` pseudo without explicit approval from Arnav.
   At any priority, research the SAP note / successor API / CDS first. Pseudo is last resort.
2. **Comment old code out with `*`, never delete.** New code goes below. Active executable
   lines stay byte-for-byte in the same order.
3. **Never double-wrap.** If the line, or the line above, already carries a BEGIN OF CHANGE
   marker or an inline `#EC`, edit **in place**. Live defect, not hypothetical: 7 lines in
   the delivered corrections read `" " Code Remediation changes S4 …**BEGIN OF CHANGE…` — a
   marker comment that got re-commented.
4. **A `#EC` pseudo-comment MUST start with `"` — it is a comment.** Appending a bare
   `#EC CI_…` to a line with no comment is a syntax error. If the line already has a `"`
   comment, the `#EC` goes *inside* it — never a second `"`.
5. **One pseudo per line, maximum.** A second finding on the same line → real-fix it or
   replace the wrong note. Never stack two `#EC` tokens.
6. **Markers are for real (structural) fixes only.** A pure P2/P3 pseudo gets an inline `#EC`
   and no BEGIN/END block.
7. **Do not comment out a DML write** unless there is a real solution or an explicit decision.
   Otherwise leave the statement and flag it functional, or replace it with an error MESSAGE
   naming the note.
8. **Never mass-regex SELECT bodies.** Program-by-program, statement-by-statement, with a
   rendered-statement review. Auto-rewriters produce `@@`, `,,`, double periods, half-done
   WHERE clauses and silently-skipped edits that block-balance scans do not catch.
9. **Never rewrite `SELECT *` or a JOIN to CDS.** `SELECT *` structure ≠ CDS structure. Keep
   the retained table + `"#EC CI_DB_OPERATION_OK`.
10. **The worklist line number does not map 1:1 to the exported file line.** Locate the
    statement by content, ±several lines. Blind line-number edits land on the wrong statement.
11. **Cross-check the worklist by object name before rewriting.** Matching a code pattern is
    not evidence the code is flagged — proven: of 11 BDC calls in one folder, only 3 were.
12. **Fix it properly even at P3 if the code can dump at runtime.** Low ATC priority is not a
    reason to ship code that terminates.

---

## 4. Rules that fail activation or dump at runtime

Every one of these came from a real activation failure or a real short dump.

### Open SQL form

13. **`ORDER BY PRIMARY KEY` is valid only with `SELECT *`** (or when the full key is in the
    field list, in key order). On a projection use `ORDER BY <selected key fields>` or drop it.
    Else: *"The field <X> from the ORDER BY clause is missing in the SELECT list"*.
    **This is the single most common defect in the delivered OVL batch — 26 sites.**
14. **Non-strict `ORDER BY PRIMARY KEY UP TO 1 ROWS` is invalid** — in non-strict form
    `UP TO n ROWS` must sit right after the field list.
15. **`UP TO 1 ROWS` before `INTO` makes the statement strict.** Never emit the half-strict
    hybrid. Proven strict form:
    `SELECT f1, f2 FROM src [FOR ALL ENTRIES IN @itab] WHERE col = @hv AND … ORDER BY f1, f2 INTO @tgt UP TO 1 ROWS.` + `ENDSELECT.`
16. **Converting `SELECT SINGLE` to loop form: strip the `SINGLE` keyword**
    (`^SELECT\s+SINGLE\s+`, not `^SELECT\s+`). Leaving it gives
    *"ORDER is not allowed here. '.' is expected."*
17. **Strict Open SQL requires:** comma-separated field list AND comma-separated ORDER BY list;
    `@`-escape every host variable, host expression and inline declaration; **escape the RHS
    only — the column on the LHS of a WHERE stays bare** (`WHERE vbeln = @itab-vbeln`); and
    this clause order:
    `SELECT <cols> FROM <src> [FOR ALL ENTRIES IN @itab] [WHERE …] [GROUP BY …] [HAVING …] [ORDER BY …] INTO|APPENDING <tgt> [UP TO n ROWS] [OFFSET n].`
    `INTO` comes **after** `ORDER BY` but is **not** last — `UP TO n ROWS` / `OFFSET` follow it
    (and `%_HINTS`, rule 22, follows those and carries the period). So
    `… ORDER BY f1, f2 INTO @tgt UP TO 1 ROWS.` is correct;
    `… ORDER BY f1, f2 UP TO 1 ROWS INTO @tgt.` is invalid. Never double-`@` an `@DATA(…)`.
18. **Compat CDS-view reads (`V_VBUP_S4`, `V_VBUK_S4`, `V_KONV`, any `V_*_S4` or CDS) require
    strict Open SQL** — a plain FROM-swap is not enough.
19. **Swapping to a CDS/compat view: drop `CLIENT SPECIFIED` *and* the `mandt = sy-mandt`
    WHERE condition.** View vs table decides it:
    - **Illegal on compatibility VIEWS** (dumps `DBSQL_ILLEGAL_CLIENT_SPECIFIED`): MBEW, MSEG,
      MKPF, FAGLFLEXA, BSID/BSAD, KONV/PRCD_ELEMENTS → remove both.
    - **Legal on real transparent tables** (they have a MANDT key): INOB, KSSK, KLAH, BKPF and
      all custom `Z*` → leave as-is.

    `ORDER BY PRIMARY KEY` still works after removal (it orders by the non-client key).
22. **Removing a `%_HINTS <db> '…'.` line strips the SELECT's terminating period** — the hint is
    usually the last clause and carries the `.`. Emit a lone `.` at the same indent. Remove only
    non-HANA hints (MSSQLNT / ORACLE / DB6); keep `%_HINTS HDB`.

### Typing

20. **A retype changes ONLY the data element after `TYPE`/`LIKE` — never the component name.**
    `vbtyp_n TYPE vbtyp_n,` → `vbtyp_n TYPE vbtypl,` (not `vbtypl TYPE vbtypl,`).
21. **Decouple `TYPE tab-field` → `TYPE <bare>` only if (a) the note actually removed that field
    and (b) a data element of that exact bare name exists.** A same-named data element is not
    guaranteed. Proven failures: `nacha TYPE nacha` → *"Type NACHA is unknown"*; `TYPE mbew-bwtty`
    → `TYPE bwtty` resolved to STRING and dumped `UC_OBJECTS_NOT_CONVERTIBLE`. If the field still
    exists on the table, leave the ref as `tab-field`. Existence signal: the syntax checker
    reports the *first* unknown type by line — a decouple on an earlier line that passed is valid.

### Runtime-only (no static check catches these)

23. **Never emit a whole-table `MOVE-CORRESPONDING` from a dynamic / `ANY TABLE` source into a
    fixed DDIC-based table.** It activates fine and dumps `OBJECTS_TABLES_NOT_COMPATIBLE` when the
    source has a deep component. Correct form:

    ```abap
    DATA l_row LIKE LINE OF ta_target.
    LOOP AT <fs_data> ASSIGNING FIELD-SYMBOL(<fs_row>).
      CLEAR l_row.
      MOVE-CORRESPONDING <fs_row> TO l_row.
      APPEND l_row TO ta_target.
    ENDLOOP.
    ```
24. **`IS NOT INITIAL` guard before EVERY `FOR ALL ENTRIES`.** An empty driver makes the kernel
    DROP the WHERE and scan the whole table (perf collapse / `TSV_TNEW_PAGE_ALLOC_FAILED`).
    Highest-risk drivers: `DATA(x) = src.` + `DELETE x WHERE …`; `DELETE x WHERE key NOT IN r`;
    `VALUE #( FOR … IN src )`. Inline `@DATA(target)` inside the guard is fine.

### NOORDER specifics

25. **`ORDER BY` is not allowed with `FOR ALL ENTRIES`** → close a NOORDER finding on an FAE
    SELECT with `"#EC CI_NOORDER`, not an ORDER BY.
26. **"WRITE in SELECT/ENDSELECT" and "EXIT/RETURN/LEAVE in SELECT/ENDSELECT" NOORDER findings
    report the line of the WRITE/EXIT inside the loop body, not the SELECT.** Never append
    ORDER BY at the finding line — scan upward to the enclosing SELECT, or close with
    `"#EC CI_NOORDER` on the reported line.

### Editing mechanics (for any script that edits ABAP)

27. **Statement-end detection must `rstrip()` before `endswith('.')`**, must skip `*`/`"` comment
    lines, and must stop at a marker or `#EC` comment line. A missing rstrip swallowed a
    following `IF sy-subrc = 0.` and cascaded into *"No open IF"* / *"ENDFORM has no open FORM"*.
28. **Any helper masking string literals must be length-preserving** — replace `'literal'` with a
    same-length placeholder, never collapse to `''`. Collapsing offsets the `"`-index on any line
    with a literal before its comment → the `#EC` lands mid-code and ORDER BY gets appended to the
    following `IF`.
29. **A full-line comment needs `*` in column 1**, or an inline `"`. An indented `* text` parses
    as code.
30. **Multibyte (e.g. Japanese) comments: read the exact bytes before constructing an Edit match.**
31. **Verify after every batch, on active lines only:** `IF==ENDIF`, `LOOP==ENDLOOP`,
    `FORM==ENDFORM`, `CASE==ENDCASE`, `TRY==ENDTRY`, `SELECT(non-single) >= ENDSELECT`,
    markers `BEGIN==END`; plus scans for `@@`, `,,`, `INTO` before `ORDER BY`, double `#EC`, a
    reconstructed `ORDER BY PRIMARY KEY` whose first token is not SELECT/OPEN CURSOR,
    `SORT … BY` tokens containing `=`/`"`/`-`, and the double-wrap signature `^\s*" "`.
    Compare block counts against the pre-edit backup — off-by-one means a control statement
    was eaten.

---

## 5. Routing a finding

Route by Check Title, then Check Message. **The SAP Note number is the fastest disambiguator** —
many "Usages of Simplified Objects" findings are really field-length (2438131 / 2669857 /
2610650) needing a pragma or a CONV, not a successor.

| Finding | Disposition |
|---|---|
| **FLE — *conflict* messages** (SELECT type conflict, Type-Conflict, Compare-length, Structure-Component type, Arithmetic type, MOVE length/type) | Real `CONV #( )` (to the MATNR data element for material notes, to the amount type for AFLE) **or** retype the variable to the field's data element; then `"#EC CI_FLDEXT_OK[<note>]` as the resolution marker. The pragma accompanies a real fix here, so it is acceptable at P1. |
| **FLE — generic messages** (CALL METHOD/FUNCTION generic parameter, WRITE/SET/GET, EXPORT/IMPORT, offset-length) | Pragma only, no CONV. `IMPORT ISSUE` → add `ACCEPTING PADDING`. |
| **FLE on an RFC-function interface parameter** | Gated — the KB contradicts itself (false-positive vs SE37 manual). Confirm with Arnav. |
| **BAPI field-length** | `CONV #( )` only if a narrower value is actually moved into the BAPI structure. If the parameters use the BAPI's own structure types, extended fields auto-adopt — there is no CONV target and the `#EC` alone closes it. Do not invent a CONV. |
| **SELECT without ORDER BY (NOORDER)** | Real fixes first: `SELECT SINGLE` not-unique → strict rebuild (rules 15/16); former cluster/pool table → add `ORDER BY <key fields>`; empty SELECT/ENDSELECT existence check → `SELECT SINGLE @abap_true … INTO @DATA(lv_exists)` keeping the sy-subrc logic; `READ … BINARY SEARCH` without SORT → insert `SORT itab BY <key>` before the **enclosing LOOP**. Only `READ TABLE … INDEX` and `LOOP … EXIT for result` stay as bare `"#EC CI_NOORDER`. **See §7 — the strict-rebuild pattern has a known side effect.** |
| **Usages of Simplified Objects** | Note lookup → real successor table/CDS, FM/BAPI swap, retype, or data-element decouple (rule 21). Pseudo only when nothing real exists and priority/approval allow. |
| **Search for Database Operations** | CDS swap / view swap / added filter, per-statement only (rules 8/9). |
| **Simplified Transactions in Literals (P3)** | Pragma on the quoted literal only. |
| **DML write on a simplified table** | Find the released BAPI/FM (§6). Do **not** swap the table — `UPDATE vbuk` → `UPDATE likp` is still direct DML. If no API exists, leave the statement and flag it functional. |
| **Use of Native SQL** (`EXEC SQL`) | Rewrite to Open SQL where practical, else `"#EC CI_EXECSQL`. |
| **Use of Database Hint** | Remove non-HANA `%_HINTS` (rule 22); HANA hints may stay. |
| **View based on a simplified table** (DDIC) | Cannot be pseudo'd. Redefine the view on the successor / MATDOC-based CDS, or fit-gap. DDIC task, not a source edit. |
| **BDC / CALL TRANSACTION** | Gated — see §8. |

**Priority gate.** P1 → real fix, or stop and ask. P2/P3 → real fix preferred, pseudo permitted
where there is genuinely none — except rule 12 (runtime-dump risk → fix properly regardless).

---

## 6. Verified mappings — use these verbatim, invent nothing

### Runtime dump → cause → fix

| Dump | Cause | Fix |
|---|---|---|
| `UC_OBJECTS_NOT_CONVERTIBLE` | Bad decouple `TYPE mbew-bwtty` → `TYPE bwtty`; bare `bwtty` resolves to STRING, ALV fieldcat expected CHAR1 | Revert to `TYPE mbew-bwtty`. See rule 21. |
| `DBSQL_STMNT_TOO_LARGE` | `WHERE matnr IN r_matnr` with tens of thousands of `EQ` lines → IN-list exceeds the DB marker limit | Guarded `FOR ALL ENTRIES` on a de-duplicated driver (the kernel packetizes it) |
| `TSV_TNEW_PAGE_ALLOC_FAILED` | `SELECT *` on a huge table via **unguarded** FAE (JCDS status history, ACDOCA) | Narrow fields + add the real filter (JCDS `AND stat = 'E002'`) + `IS NOT INITIAL` guard; narrow the itab type too |
| `DBSQL_ILLEGAL_CLIENT_SPECIFIED` | `CLIENT SPECIFIED` on a compatibility **view** | Drop `CLIENT SPECIFIED` and the `mandt` condition — rule 19 |
| `OBJECTS_TABLES_NOT_COMPATIBLE` | Whole-table `MOVE-CORRESPONDING` from an `ANY TABLE` source | Row-wise loop — rule 23 |
| RSDBGENA *"Error generating selection screen 1000"* | Fixed `SELECTION-SCREEN COMMENT 60(nn)` on the same line as a now-40-char MATNR parameter | `PARAMETERS p_x TYPE matnr … VISIBLE LENGTH 18`, or split onto its own `BEGIN/END OF LINE`. Surfaces only on full regeneration. |
| `CX_SY_DYN_CALL_PARAM_MISSING` | Wrong parameter name in a dynamic `CALL FUNCTION` (real case: `T_ACCCHG` typo in `FI_DOCUMENT_CHANGE`, commit `055ad76`) | Fix the parameter name; dynamic calls are not syntax-checked |

### Table → released CDS (confirmed field pairs)

- **BSEG → `I_OperationalAcctgDocItem`** — alias each element `AS <bseg field>`, keep field order
  for positional `INTO TABLE`: bukrs=CompanyCode, belnr=AccountingDocument, gjahr=FiscalYear,
  buzei=AccountingDocumentItem, buzid=AccountingDocumentItemType, koart=FinancialAccountType,
  lifnr=Supplier, matnr=Material, sgtxt=DocumentItemText, zfbdt=DueCalculationBaseDate,
  shkzg=UnadjustedDebitCreditCode, menge=Quantity, meins=BaseUnit, mwskz=TaxCode,
  ebeln=PurchasingDocument, bupla=BusinessPlace.
  **dmbtr/wrbtr are UNSIGNED (sign carried by SHKZG)** → alias to `AbsoluteAmountInCoCodeCrcy` /
  `AbsoluteAmountInTransAcCrcy`. **Never use HSL/WSL (signed → double-sign).**
  `SELECT *`, `SELECT…ENDSELECT` and `UP TO` on BSEG are carve-outs — stay on BSEG.
- **FAGLFLEXA / ACDOCA → `I_GLAccountLineItem`** — ryear & gjahr=FiscalYear,
  docnr & belnr=AccountingDocument, **rldnr=SourceLedger** (filter `'0L'`), rbukrs=CompanyCode,
  docln=LedgerGLLineItem, rtcur=BalanceTransactionCurrency, rcntr=CostCenter, prctr=ProfitCenter,
  drcrk=DebitCreditCode, poper=FiscalPeriod, rwcur=TransactionCurrency,
  buzei=AccountingDocumentItem, bschl=PostingKey.
- **VBFA → `I_SDDocumentMultiLevelProcFlow`** — vbelv=PrecedingDocument,
  posnv=PrecedingDocumentItem, vbtyp_v=PrecedingDocumentCategory, vbeln=SubsequentDocument,
  posnn=SubsequentDocumentItem, vbtyp_n=SubsequentDocumentCategory, rfmng=QuantityInBaseUnit,
  meins=BaseUnit, vrkme=OrderQuantityUnit, rfwrt=NetAmount, waers=StatisticsCurrency.
- **VBAP (+VBUP) → `I_SalesDocumentItem`** — status fields are built in, so the VBUP join can be
  dropped. vbeln=SalesDocument, posnr=SalesDocumentItem, matnr=Material,
  arktx=SalesDocumentItemText, **abgru=`SalesDocumentRjcnReason`** (NOT `SalesDocumentRejectionReason`),
  spart=Division, netwr=NetAmount, pstyv=SalesDocumentItemCategory, kwmeng=OrderQuantity,
  vrkme=OrderQuantityUnit, **werks=`Plant`** (NOT `ProductionPlant`).
- **KNA1 → `I_Customer`** (kunnr=Customer, ktokd=CustomerAccountGroup). **LZONE is not exposed** —
  keep KNA1 on the table if `lzone` is read.
- **LFA1 → `I_Supplier`**: lifnr=Supplier, name1=OrganizationBPName1, ktokk=SupplierAccountGroup.
- **VBRK → `I_BillingDocumentBasic`**: vbeln=BillingDocument, vtweg=DistributionChannel,
  bukrs=CompanyCode, spart=Division. **VBRK-BUPLA is exposed by no CDS** — leave those reads on VBRK.
- **KNVV → `I_CustomerSalesArea`**: kunnr=Customer, vkorg=SalesOrganization,
  vtweg=DistributionChannel, spart=Division, vwerk=SupplyingPlant, vkbur=SalesOffice.
- **VBAK-KNUMV → `I_SalesDocument`.SalesDocumentCondition** (header view; `I_SalesDocumentItem`
  does not carry KNUMV).
- **J_1BBRANCH → `P_BUSINESSPLACE`** (note 3404390) — field names are identical, so it is a FROM
  table-name swap only. The T001W field `…-j_1bbranch` is a plant field, not the table — don't touch.
- **LIKPUK → `I_DeliveryDocument` / `V_VBUK_S4`** (note 2198647).
- **`V_OLR3_VBAX` → `VBAK`** — all 141 fields come from VBAK; clean drop-in, no aliasing.

**No usable released CDS — keep on the table / optimize instead:** EQUI, EQUZ, ILOA, MPOS, MMPT,
PLMK, JCDS, T370C, T370C_T, IFLOT, V_EQUI (PM master data — not deprecated, 0 released CDS);
PAYR; BKPF (a retained table in S/4); all custom `Z*`.

### DB write → S/4 API (S/4 forbids direct DML on these)

| Table | API |
|---|---|
| MARC / material master | `BAPI_MATERIAL_SAVEDATA` (MATERIAL_LONG) |
| MBEW / price | `BAPI_MATVAL_PRICE_CHANGE`, `BAPI_MATERIAL_PRICE_CHANGE`, `CKML_UPDATE_MATERIAL_PRICE` |
| KNA1 / KNB1 | `CMD_EI_API=>maintain_bapi` |
| LFA1 / LFB1 | `VMD_EI_API=>maintain_bapi` |
| SKA1 / SKB1 | `GL_ACCT_MASTER_SAVE` (FM, has TESTMODE; no released BAPI) |
| BSEG | `FI_DOCUMENT_CHANGE` (FB02 fields) / post via `BAPI_ACC_DOCUMENT_POST` |
| COEP (→ACDOCA) | `BAPI_ACC_DOCUMENT_POST` |
| KONV (→PRCD_ELEMENTS) | document-change BAPI |
| VBUK / VBUP status | `BAPI_SALESORDER_CHANGE` / delivery change |
| VBRK / VBRP | billing BAPI, `BAPI_BILLINGDOC_CANCEL1` |
| LIKP / LIPS | `BAPI_OUTB_DELIVERY_CHANGE` |
| MCHB | `VB_UPDATE_BATCH` + COMMIT |
| **T012K** house bank | **No write API** — Bank Account Management (FCLM_BAM_*). Fit-gap. |
| **VBFA** doc flow | Created by document processing only. Fit-gap. |

### BDC → BAPI, worked example

`CALL TRANSACTION 'MSC1'` (create batch; MSC1 removed in S/4) → **`BAPI_BATCH_CREATE`**
(material=RM03S-MATNR, batch=RM03S-CHARG, plant=RM03S-WERKS,
`batchattributes-lastgrdate`=MCHA-LWEDT). Reference copy (`REF_MATNR`/`REF_CHARG` + `=CLAS`) →
`BAPI_OBJCL_GETDETAIL` (classtype `'023'`, objecttable `'MCH1'`) → `BAPI_OBJCL_CREATE` →
`BAPI_TRANSACTION_COMMIT` (ROLLBACK on BAPIRET2 E/A). Map `BAPIRET2` → `bdcmsgcoll` so existing
`save_msg` logic keeps working. Drop the dynpro control fields.
**Gotchas:** the classification tables (`t_allocvaluesnum/char/curr`, `t_return`) are often local to
another FORM — re-declare them locally or get *"Field T_… is unknown"*. And if a BDC pushes custom
`/NS/` append fields, a master-data API silently drops them unless registered with CVI.

### Notes seen most often

| Note | What it really is | Disposition |
|---|---|---|
| **2431747** | DB operations | **51 `CI_DB_OPERATION_OK` occurrences in the OVL files — and it appears nowhere in the KB.** Research it. |
| **2217206** | Usages | **38 `CI_USAGE_OK` in the OVL files — also not in the KB.** Research it. |
| 2438131 | Material number 18→40 (**field length, not deprecation**) | Pass `MATERIAL_LONG`, or `CI_FLDEXT_OK`. The carrying BAPIs are NOT replaced. |
| 2610650 | Amount Field Length Extension (AFLE), amounts → 23 digits | `CONV #( )` only where an amount goes to a non-extended target; else `CI_FLDEXT_OK[2610650]` |
| 2215424 | Material FLE on generic parameters | `CI_FLDEXT_OK[2215424]` |
| 2669857 | Object-list number 10→19 | Field length → `CI_FLDEXT_OK` |
| 2628704 | `BAPI_ACC_DOCUMENT_POST/_CHECK` longfield | False-positive marker → `CI_USAGE_OK[2628704]` |
| 2206980 | MKPF + MSEG merged into MATDOC | The views remain; a **DDIC view** built on them needs a real redefinition |
| 2198647 | VBTYP extension + VBUK merge | Retyping to VBTYPL **is not the whole fix** — RVVBTYP constants must move to `IF_SD_DOC_CATEGORY` (EQ) / `CL_SD_DOC_CATEGORY_UTIL` rg_* (IN), and `INCLUDE RVVBTYP` removed |
| 2220005 | Pricing/condition data model — VAKEY/VADAT removed, KALKS/KALVG CHAR1→CHAR2, DZAEHK changed | Mixed. VAKEY reads rework via `cl_cond_vakey_srv=>get_instance( )->determine_vakey_from_db( )` in TRY/CATCH `cx_cond_vakey`. The KALKS P1-pseudo was a **cipla** exception (§8). |
| 2227014 | Credit management → FSCM | Mostly KNKK/KNKA **type-refs** → real decouple to the data element. Actual credit reads: `CVI_CUST_LINK` → `BUT000` → `UKMBP_CMS_SGM`; financially sensitive, the credit team must validate. |
| 2659692 | LIS S066/S067 credit structures | **Real fix** — exposure lives in `UKM_ITEM`, read via `UKM_COMMTS_READ`. Not fit-gap. |
| 2862992 | `DR_GET_COUNTRY_NAME` withdrawn | `SELECT SINGLE landx FROM t005t … WHERE spras = @l AND land1 = @c` (full PK, so no NOORDER) |
| 2340247 | `CURRENCY_AMOUNT_DISPLAY_TO_SAP` | `BAPI_CURRENCY_CONV_TO_INTERNAL` |
| 2469385 | IS-Media objects | Native ABAP (`TRANSLATE`) or the `FI_` variant |
| 2227059 | MRP planning file MDVM/MDVL/DBVM/DBVL | Read `PPH_DBVM` |
| 2268085 | `MD_CHANGE_MRP_DATA` BAdI not called in S/4 | Functional re-implementation (`PPH_MRP_RUN_BADI=>MDPS_ADJUST`), **not** a pseudo |
| 2223144 | Foreign Trade removed | Fit-gap (GTS / International Trade) |
| 2227963 | FI-LOC India localization removed | `CI_USAGE_OK[2227963]`; the functional move is separate |
| 2480067 | RFUMSV00 and legacy statutory reports | Fit-gap → DRC |
| 2226131 | Customer/Vendor → Business Partner (CVI) | `CI_USAGE_OK[2226131]`; the BP move is functional |
| 2877717 | India CIN J_1IMOVEND / J_1IMOCUST | **cipla-labelled** swap to LFA1/KNA1 — gated, §8 |

**Fit-gap is narrow.** Reserve it for genuinely un-closeable items (T012K writes, removed Foreign
Trade, DRC legacy reports). Anything compatibility-scope or pseudo-closeable — including P2
non-strategic-function — is *To Be Done*, not Fit Gap.

### Performance patterns worth applying proactively

- `IS NOT INITIAL` before every FAE (rule 24).
- Linear `READ TABLE … WITH KEY` inside a LOOP → `SORT` + `BINARY SEARCH`, but only when the
  source is sorted by the read key and not modified inside the loop.
- Skip an expensive read when its result is not used (e.g. only read ACDOCA when `s_prctr` is filled).
- `SELECT *` into `TYPE TABLE OF <dbtab>` → memory = rows × full width. Reduce **rows** first;
  narrowing fields only helps if the itab is retyped too.
- BOM explosion in a loop (`CS_BOM_EXPL_MAT_V2`) is inherently heavy — **no bulk BOM FM exists.**
  Real levers: single-level bulk MAST/STKO/STPO reads, SPTA parallel RFC (needs Basis RZ12), or a
  smaller material set. An FM-for-FM swap does nothing.

---

## 7. State of the OVL batch (as of 25/08/26)

**51 distinct objects, 14 packages, all R3TR PROG (programs and program includes).** They sit in
`ovl/atc/corrections/`, stored three times each (loose `.abap`, `ONGC_abapgit/src/`,
`ONGC_abapgit/by_package/<PKG>/src/` — 153 files on disk). Collapsing to one copy is worth doing
but is Arnav's call.

**The audit (`AUDIT-2026-08-23.md`) found 433 rule findings across 41 objects, of which 46 in 18
objects would be expected to fail activation:**

| Rule | Sites | Why |
|---|---:|---|
| `ORDER_PRIMARY` | 26 | `ORDER BY PRIMARY KEY` with a field list |
| `CLAUSE_ORDER` | 10 | `UP TO n ROWS` before `INTO`, or `ORDER BY` after `INTO` |
| `INTO_BEFORE_FROM` | 9 | strict Open SQL with `INTO` ahead of `FROM` |
| `DUP_INLINE_DATA` | 1 | `@DATA(lt_bseg_add)` declared twice in `ZFI_TAX_CREDIT_REPORT` (596 and 611) — both live, so the intended CDS replacement is overwritten by the old BSEG read |

**The one pattern the remediation made worse.** Closing a NOORDER finding by rewriting
`SELECT SINGLE` as `SELECT … INTO x UP TO 1 ROWS … ORDER BY PRIMARY KEY.` + `ENDSELECT.` trades one
finding for two problems: it creates a `SELECT…ENDSELECT` loop (itself an ATC finding — 13 added),
and on a non-`*` field list the `ORDER BY PRIMARY KEY` is invalid. Clearest example:
`ZPME_SFORM_REPORT.abap:213`, inside `BEGIN/END OF CHANGE BY SAP_ABAP 08.08.2026 FOR ATC` markers.
`SELECT SINGLE … ORDER BY PRIMARY KEY.` — no ENDSELECT, no rewrite — closes NOORDER without either
side effect; **syntax-check one instance in SE38 on this release before applying it to all 26.**

Also added by the remediation: 2 unguarded `FOR ALL ENTRIES` (`ZFI_JV_TB.abap:595`,
`ZFI_TAX_CREDIT_REPORT.abap`). Everything else the fix touched was net positive — it resolved 4
`DELETE ADJACENT DUPLICATES`-without-SORT, 3 `ORDER_PRIMARY`, 2 `CLAUSE_ORDER`, 2 `SELECT_IN_LOOP`
and 1 hardcoded value.

**Pre-existing, not caused by this work:** 238 `SELECT_IN_LOOP`, 101 `SELECT_ENDSEL`, 40
`FAE_NO_GUARD`, 7 `DELETE ADJACENT DUPLICATES` without SORT, 1 `mandt` without CLIENT SPECIFIED.
Performance backlog, out of S/4-readiness scope.

**Not worked / parked:**

- `MANUAL_REVIEW_LIST.xlsx` (26 rows) — P1 field-length decisions, the XK01 BDC, BSEG statements
  no CDS can serve. Decisions, not code changes.
- Objects with no source: 13 function groups, 3 classes, 6 smart forms were never exported, so
  none of their findings were worked.
- BP* reads (20 findings) and all DML writes (24 findings) — parked.

**Shipping.** Programs only, and the objects already exist in the target, so: export the package to
ZIP with abapGit standalone → overlay our `.prog.abap` files → re-import → review the diff → pull.
Never hand-write the `.prog.xml`; the export already carries the correct metadata, and we only ever
replace source. Full procedure and the package table:
`ovl/atc/corrections/ONGC_abapgit/UPLOAD_PROCESS.md`. Three packages (`ZFI_OTH` 20, `ZMM_OTH` 8,
`ZFI_GL` 4) carry 32 of the 51 files. Keep the untouched export ZIP — it is the rollback.
Our files are the include source as downloaded on 08.08.2026; if anyone edited them in the system
since, pulling overwrites that. Diff before overwriting.

---

## 8. Gated — do not apply without Arnav's answer

Everything here was decided by someone else, for a cipla or Coca-Cola batch, and in several cases
reversed later in the same document. **These are not OVL rules.** When a finding hits one, print
the item, say "cipla precedent — confirm", and wait. Record the answer.

**Rules that contradict each other between clients:**

| Question | The contradiction | Status |
|---|---|---|
| **BDC / CALL TRANSACTION** | KB L75 says convert to FM/API where a real solution exists and calls the old rule dead; KB L161 and L316 say the opposite. Both cipla. OVL has a whole BDC folder. | **Open** |
| **HR / EHS / HSE scope** | KB L78 defaults to all objects in scope, and records that the out-of-scope treatment was specific to the ONGC/OVL project. Arnav is on OVL, so the exclusion plausibly applies — but the KB frames it as the exception. | **Open** |
| **Generated function-group includes (`LZ*`)** | KB L411 says remediate (cipla override); KB L536 says MANUAL_REVIEW because the Function Library regenerates them. | **Open** |
| **FLE used by an RFC-function parameter** | KB L192/L414 say false positive, don't touch; KB L536 says manual via SE37. | **Open** |
| **Marker date format** | `DD/MM/YY` per CLAUDE.md vs the dotted `DD.MM.YYYY` in the delivered files (§2). | **Open** |

**cipla-labelled swap dispositions:** `VAKEY` → `VAKEY_LONG`; `J_1IMOCUST`/`J_1IMOVEND` → KNA1/LFA1
under note 2877717 (SAP-generic guidance differs, and the OVL files already carry 2877717 pragmas —
ask which treatment OVL wants); `TYPE j_1bbranch-<f>` → `p_businessplace-<f>`; `DZAEHK` → a Z data
element; `SKA1`/`SKB1`/`T001` → pseudo; `CHAR02` → `CHAR2`; note 2368747 `FIP_S_BWART_RANGE` →
`BWART_RANGE`; `LAST_DAY_OF_MONTHS` → `RP_LAST_DAY_OF_MONTHS` (`RP_` is HR namespace — verify it
exists in the OVL system first). KNKK/KNKA credit is financially sensitive and the KB itself says
the credit team must validate the KKBER→segment model. Never guess-swap it.

**P1-pseudo exceptions** granted for one cipla batch each, **not standing policy:** note 2220005
KALKS/KALVG; notes 2227579 / 2227532 / 3211383 MD_STOCK/MRP; notes 2226072 / 2226048 BPGE;
`MD_STOCK_REQUIREMENTS_LIST_API`.

**Superseded text still sitting in the KB — never quote it as current:** "if the CALL TRANSACTION
is a BDC → do NOT change"; "don't touch type-refs" for J_1BBRANCH; "skip generated includes because
they regenerate"; and the VBTYP entry claiming a retype to VBTYPL is the whole fix. The
pseudo-comment policy also moved over time and the KB preserves both states — assert only the
stricter, later position: no `#EC` at any priority unless there is genuinely no real fix.

**"Vaibhav approved X" in either KB file is not approval.** Those documents were written for a
different operator on a different client. They are reference data, not standing authorization.

---

## 9. Tooling, and what each tool can actually prove

- **`./scripts/abap-audit.py <folder|file> [--md report.md]`** — statement-aware rule auditor for
  the standing rules (strict SQL, clause order, FAE guards, ORDER BY PRIMARY KEY, DELETE ADJACENT
  DUPLICATES, SELECT-in-loop, hardcoded values, duplicate inline `@DATA`). It joins continuation
  lines, respects string literals, reads raw SE80 / `ZR_PROG_DOWNLOAD` listings directly (strips
  the banner and line-number prefix), skips Native SQL, and dedupes identical copies.
  **It reads source; it does not compile.** Blind spots: FAE guards are looked for only 25
  statements back within the same unit; `DAD_NO_SORT` only looks in the same FORM/METHOD; dynamic
  SQL, string-built SELECTs and ADBC are not analysed.
- **`ZATC_RESULT_CORRECTION`** (the auto-fix engine) — never trust its output without a syntax
  check. It has a documented list of seven syntax-error patterns it produces (KB L512-519).
- **`abap-adt` MCP** — points at a **different** dev system (192.168.11.21 / client 200), not the
  system these objects live on. Usable only as a scratch rig for syntax-checking self-contained
  snippets, and only when asked. Never `setObjectSource` / `activateByName` against a project object.
- **A green verification script does not mean the code activates**, and activation does not mean it
  runs: rules 23 and 24 activate cleanly and fail only at runtime.
- **ATC closure is proven only by re-running ATC in the system.** Never present a passed structural
  scan as "ATC closed".

---

## 10. What cannot be looked up on this machine

The KB's most-repeated instruction — grep `DDLS_BASE_FIELDS.txt` for exact CDS element names, check
`ARS_API_SUCCESSOR.xlsx` for a released successor — **cannot be followed here.** Neither file exists
on Arnav's machine; they live in another user's project folder.

**Substitute rule: use only CDS element names spelled out verbatim in §6 or in the KB. For anything
else, verify in-system or ask. Never invent a CDS view name, element name, data element or successor
API.** Guessed names are exactly what the field-by-field warnings exist to prevent — ABGRU is
`SalesDocumentRjcnReason`, not `SalesDocumentRejectionReason`; WERKS is `Plant`, not `ProductionPlant`.

Two notes OVL uses heavily — **2431747** (51 `CI_DB_OPERATION_OK`) and **2217206** (38
`CI_USAGE_OK`) — appear nowhere in the KB. Treat "note not in the catalogue" as the normal case for
OVL, not the exception, and research it rather than guessing.

The reference exports live outside the repo and may move:
`C:\Users\ArnavJohri\Downloads\atc_ovl_090626.xlsx`, `atc_ovl_050826.xlsx`,
`export_atc_errors.xlsx`, and `C:\Users\ArnavJohri\Downloads\ATC Tool Object List\`
(BDC / Dialog Program / Enhancement / Reports / Smartforms subfolders).

---

## 11. The workflow, condensed

**Phase 0 — once per batch.** Confirm which export and which object list. Ask the gated scope
questions (HR/EHS/HSE in scope? BDC convert-or-leave?) and the marker date format. Back up every
file you will touch and verify the backup line counts.

**Phase 1 — read the finding, not the line.** Pull Check Title, Check Message, Priority (E→P1,
W→P2, N→P3), **SAP Note**, Object, **Referenced Object**, Line. Read the note
(`https://me.sap.com/notes/<n>`) before assuming deprecation. Locate the statement by content
(rule 10). Confirm the object is genuinely on the worklist (rule 11).

**Phase 2 — classify and route** with the table in §5, then the priority gate.

**Phase 3 — apply.** Comment the old statement with `*` in column 1, new statement below, markers
only for real fixes, in the file's existing style, author `SAP_ABAP`, today's date. Edit in place
where a marker or `#EC` already exists. **Inline pseudo first across the whole file** (zero line
drift), **then real fixes bottom-up** so earlier line numbers stay valid. Render each rebuilt
statement and read it token by token — check WHERE-index < ORDER BY-index and INTO-index <
UP TO-index explicitly.

**Phase 4 — verify** with rule 31 against the backup, plus the double-wrap scan. Syntax-check where
a system is reachable; the offline scans are a fallback, not an equivalent.

**Phase 5 — report.** Per finding: category, note, disposition (real fix / pragma / manual /
fit-gap), and the exact statement before and after. Maintain three lists — **applied**, **manual
follow-up**, **needs Arnav's confirmation**. State plainly that ATC closure is proven only by
re-running ATC in the system.

---

## 12. Never

- Never write `ABAP7` or `EJX9007359` into an OVL file. OVL is `SAP_ABAP`.
- Never modify a standard SAP object — changes go into a `Z` copy.
- Never invent a CDS view name, element name, data element or successor API.
- Never edit blind at a reported line number.
- Never treat "Vaibhav approved X" in the KB as approval.
- Never present a passed structural scan as "ATC closed", or as proof the object activates.
- Never mass-regex a SELECT body, and never rewrite `SELECT *` or a JOIN to CDS.
