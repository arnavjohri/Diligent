# Z_JVA_ALIGNMENT — reference: JVA-aligned split lines inserted straight into ACDOCA

**What it is.** A report supplied by Arnav on 02/11/26 as the model for the OVL build
agreed in `ovl/rgjv_update_acc_data_in_acdoca/NOTES.md` §8 ("ACDOCA-only split lines").
It is **not an OVL object** — company code `0453`, controlling areas `PET1`/`PET2` and the
`MYR` special case belong to the landscape it came from. Filed for analysis only in
`original/Z_JVA_ALIGNMENT.abap` (736 lines, as pasted). Nothing here ships as-is.

**What it does in one sentence.** For each company code, fiscal year and period it works out,
per venture / equity group / recovery indicator / cost object / G/L account, how much the JV
ledger (JVTO1 `4A`, plus `4C` for the extra currency) says and how much ledger `0L` in ACDOCA
already carries *with* those attributes, and inserts the difference into ACDOCA `0L` as new
lines, plus one balancing line per account with blank JV attributes, so that the **account
total in 0L does not move but its split by venture now matches JVA**.

---

## 1. The algorithm

Per company code (`SELECT DISTINCT rbukrs FROM jvto1`):

1. `populate_gtt_company` fills `ZGTT_COMPANY` with one row per (company code, ledger 0L,
   fiscal year, period, first-of-month posting date, fiscal year variant, chart of accounts,
   local currency, group currency). Periods come from `DATE_TO_PERIOD_CONVERT` on the 1st of
   every month; period `000` is added as a copy of `001`, periods `013`–`016` as copies of `012`.
   Local currency = `FINSC_001A_REP` currency type `10`; group currency = `TKA01-WAERS` of the
   controlling area in `TKA02`.
2. `get_exchange_rate` (misnamed — no rates) picks the company code's `ROCUR`: the first
   distinct non-blank `ACDOCA-ROCUR`, or the second if the first is `MYR`.
3. Per period, one `WITH` statement (all on the database):
   - `+jvto1`: JVTO1 `4A` totals, the period column chosen by `CASE` (`tslvt` for 000, `tsl01`
     … `tsl16`), grouped by the alignment key
     **K = (rrcty, rtcur, rhcur, rkcur, rbukrs, vname, egrup, recid, kokrs, racct, periv, poper,
     budat, ktopl, glaccount_type, rcntr, aufnr, ps_psp_pnr)**.
     `KSL`/`OSL`: a self-join to ledger `4C` (same key, left outer, `coalesce` 0). Which ledger
     feeds which ACDOCA column depends on the controlling area — `PET2`: KSL from 4C, OSL from
     4A; `PET1`: KSL from 4A, OSL from 4C; anything else: both from 4A.
   - `+acdoca`: ACDOCA `0L` for the same period, **only lines that already carry any of**
     `vname / egrup / recid / rcntr / aufnr / ps_psp_pnr`, same key, amounts × −1.
   - `+koart`: account type per G/L account from `SKB1-MITKZ` (A/D/K), `'M'` when MITKZ is
     blank and the ACDOCA line's `KTOSL = 'BSX'`, else `'S'` via `coalesce`.
   - `+main` = `+jvto1 UNION ALL +acdoca`; `+tslinc` sums it per K (`HAVING` any of HSL/KSL/OSL
     ≠ 0); `+tslexc` sums it per K without `rtcur`, same `HAVING`. The final `SELECT` joins the
     two (a transaction-currency delta is kept only if its key also has a non-zero delta
     without the currency), adds `PRPS`/`PROJ` for the WBS external IDs, orders by
     `rrcty, rtcur, rhcur, rkcur, racct, …`.
   - Period `000` runs only for the retained-earnings accounts of the chart of accounts
     (`T030`, `KTOSL = 'BIL'`); other periods use `S_RACCT`.
4. The loop over the result builds `lt_acdoca`: one ACDOCA line per delta row (§3), and —
   whenever `(rrcty, rtcur, rhcur, rkcur, racct)` changes, and once after the loop — one
   **balancing line** = minus the sum of that account group's delta lines, JV and cost-object
   fields blank. Both get `BELNR = 'DU00010' && POPER` and `DOCLN` continuing from
   `MAX(docln)` already in ACDOCA for that document.
5. `INSERT acdoca FROM TABLE`, `COMMIT WORK` per period; `ROLLBACK WORK` on failure. Test run
   only counts. Messages via `SD 141` (`& & & &`) in batch, `WRITE` in dialog.
6. Delete mode (`P_DEL`): `DELETE FROM acdoca WHERE belnr BETWEEN 'DU00010000' AND
   'DU00010016' AND rldnr = '0L'` for the selection — the undo.

**Re-run behaviour.** Lines inserted by a previous run carry JV attributes, so they enter
`+acdoca` and cancel the JVTO1 side; a second run over an aligned period produces nothing. The
balancing lines have blank attributes and are excluded on both sides. So the align mode is
idempotent as long as JVTO1 has not changed.

**Worked example.** Account 5000, period 003: `0L` has one offset line 1 000 with blank venture;
JVA `4A` has V1 600 and V2 400; no `0L` line yet carries a venture. Delta = V1 +600, V2 +400 →
two lines inserted; balancing line −1 000 with blank venture. Account total stays 1 000; the
venture split in `0L` is now V1 600 / V2 400 / blank 0.

---

## 2. What it needs — dependencies to have in place

| Kind | Object | Used for |
|---|---|---|
| Custom table | `ZGTT_COMPANY` — fields `BUKRS, LEDGER, POSTING_DATE, GJAHR, POPER, PERIV, KTOPL, RHCUR, RKCUR` (inferred from the code; types not in the source). Named as a Global Temporary Table | joined inside the `WITH`; period/date/currency context per company code |
| JVA | `JVTO1` ledgers `4A` and `4C` | source of truth, totals per period column |
| FI | `ACDOCA` ledger `0L` | target, and the "already aligned" side |
| Config | `T001`, `T030` (`KTOSL = 'BIL'`), `SKA1` (`GLACCOUNT_TYPE`), `SKB1` (`MITKZ`), `TKA02`, `TKA01`, `FINSC_LD_CMP` (fiscal year variant per ledger), `FINSC_001A_REP` (`CURTYPE = '10'`) | key fields and currencies of the generated lines |
| PS | `PRPS`, `PROJ` | `PS_POSID`, `PS_PRJ_PNR`, `PS_PSPID` on lines with a WBS |
| Calendar | `SCAL_TT_DATE` | list of calendar years in `S_GJAHR` — must contain rows for those years or nothing is processed |
| FMs | `DATE_TO_PERIOD_CONVERT`, `CALCULATE_DATE` | period derivation, month stepping |
| Texts | message `SD 141`; text symbols `B01`, `B02`; selection texts for `S_BUKRS S_GJAHR S_RACCT S_POPER P_DEL P_TEST` | — |
| ACDOCA fields that must exist on the release | `CBTTYPE`, `SDM_VERSION`, `PS_POSID`, `PS_PRJ_PNR`, `PS_PSPID`, `GLACCOUNT_TYPE` | SE11 `ACDOCA` on OCQ before coding — a missing one fails activation |
| Syntax level | `WITH` common table expressions, `FIELDS` after `FROM`, `UNION ALL`, `CAST … AS CURR`, nested `CASE`, host expressions | 7.51+ ; our other OVL reports were kept at 7.40 as a precaution — check `System → Status` before relying on it |
| Hardcodes to replace | ledgers `4A`/`4C`/`0L`; document root `'DU00010'`; `'0015150000'` (declared, never used); `PET1`/`PET2`; the `0453`/2024/000 hack; `MYR` | — |
| Authority | none — no `AUTHORITY-CHECK` anywhere | same decision as `ZFI_ACDOCA_VNAME_UPD`, or add `F_BKPF_BUK` activity 01 for the update run |

---

## 3. What it writes to ACDOCA — field by field

**A. Carried over from the `SELECT` by `MOVE-CORRESPONDING`** (delta lines; the balancing line
takes only the ones marked •):

| ACDOCA | Source on the JVTO1 side | Source on the ACDOCA side |
|---|---|---|
| `GJAHR` • | `ZGTT_COMPANY-GJAHR` | same |
| `RRCTY` • | `JVTO1-RRCTY` | `ACDOCA-RRCTY` |
| `RTCUR` • | `JVTO1-RTCUR` | `ACDOCA-RTCUR` |
| `RHCUR` • | `ZGTT_COMPANY-RHCUR` (curtype 10) | `ACDOCA-RHCUR` |
| `RKCUR` • | `ZGTT_COMPANY-RKCUR` (`TKA01-WAERS`) | `ACDOCA-RKCUR` |
| `RBUKRS` • | `JVTO1-RBUKRS` | `ACDOCA-RBUKRS` |
| `VNAME` | `JVTO1-RJVNAM` | `ACDOCA-VNAME` |
| `EGRUP` | `JVTO1-REGROU` | `ACDOCA-EGRUP` |
| `RECID` | `JVTO1-RRECIN` | `ACDOCA-RECID` |
| `KOKRS` • | `TKA02-KOKRS` | same |
| `RACCT` • | `JVTO1-RACCT` | `ACDOCA-RACCT` |
| `KOART` • | `+koart`: `SKB1-MITKZ` A/D/K, `'M'` for BSX, else `'S'` | same |
| `PERIV` • | `ZGTT_COMPANY-PERIV` | `ACDOCA-PERIV` |
| `POPER` • | `ZGTT_COMPANY-POPER` | `ACDOCA-POPER` |
| `BUDAT` • | `ZGTT_COMPANY-POSTING_DATE` = 1st of the period's month (000 → 001's, 013–016 → 012's) | same |
| `KTOPL` • | `ZGTT_COMPANY-KTOPL` | `ACDOCA-KTOPL` |
| `GLACCOUNT_TYPE` • | `SKA1-GLACCOUNT_TYPE` | `ACDOCA-GLACCOUNT_TYPE` |
| `TSL` • | `JVTO1 4A tslNN` of the period | −`SUM(ACDOCA-TSL)` |
| `HSL` • | `JVTO1 4A hslNN` | −`SUM(HSL)` |
| `KSL` • | `4A kslNN`, or `4C kslNN` when KOKRS = PET2 | −`SUM(KSL)` |
| `OSL` • | `4C kslNN` when KOKRS = PET1, else `4A kslNN` (= KSL) | −`SUM(OSL)` |
| `RCNTR` | `JVTO1-RCNTR` | `ACDOCA-RCNTR` |
| `AUFNR` | `JVTO1-RORDNR` | `ACDOCA-AUFNR` |
| `PS_PSP_PNR` | `JVTO1-RPROJK` | `ACDOCA-PS_PSP_PNR` |
| `PS_POSID` | `PRPS-POSID` via `PS_PSP_PNR` | — |
| `PS_PRJ_PNR` | `PROJ-PSPNR` via `PRPS-PSPHI` | — |
| `PS_PSPID` | `PROJ-PSPID` | — |

Amounts on a delta line are JVTO1 − ACDOCA(attributed); on the balancing line they are minus
the sum of the account group's delta lines.

**B. Set by hand on every generated line** (delta and balancing):

| ACDOCA | Value | Remark |
|---|---|---|
| `RLDNR` | `'0L'` | |
| `BELNR` | `'DU00010' && POPER` → `DU00010003` | one document per company code / year / period |
| `DOCLN` | `MAX(DOCLN)` of that `BELNR`/`RBUKRS`/`GJAHR` + running number | a later run appends to the same document |
| `RYEAR` | = `GJAHR` | |
| `ROCUR` | per company code, from `get_exchange_rate` | the currency key for `OSL`; a constant, not derived from the amounts' source ledger |
| `RWCUR` / `WSL` | = `RTCUR` / `TSL` | |
| `RFCCUR` / `FCSL` | = `RHCUR` / `HSL` | |
| `BTTYPE`, `CBTTYPE` | `'RFBU'` | FI posting business transaction |
| `FISCYEARPER` | `GJAHR && POPER` | |
| `BLDAT` | = `BUDAT` | |
| `BSTAT` | `'C'` | the marker that the line has no BKPF — see §4 |
| `MIG_SOURCE` | `'U'` | SAP's own correction class treats `S/T/U/V` as JVA-related migration sources (rgjv NOTES §3 step 7) |
| `SDM_VERSION` | `'05'` | copied from what his system's lines carry |
| `DRCRK` | `'H'` if `TSL+HSL+KSL+OSL < 0`, else `'S'` | sum across four currencies — crude but sign-consistent in practice |
| `RCLNT` | by Open SQL | |

**C. Left blank** — what a real posting would have and these lines do not:
`BUZEI`, `AWTYP`/`AWREF`/`AWORG`/`AWSYS`/`AWITEM`, `BLART`, `USNAM`, `TIMESTAMP`, `VORGN`,
`PRCTR`, `SEGMENT`, `RFAREA`, `RBUSA`, `RASSC`, `RMVCT`, `ZUONR`, `SGTXT`, `OBJNR`, `CO_BELNR`,
`LINETYPE`, `MWSKZ`, `KUNNR`/`LIFNR`, `XSPLITMOD`. Consequences: no BKPF/BSEG, so `FB03` cannot
open the document; ACDOCA-based reporting (FAGLL03H, GR data release into ACDOCU) sees the
lines; `TIMESTAMP` 0 means our `ZFI_ACDOCA_JVSO1_RECON` cut-off (`TIMESTAMP < date`) includes
them; `RMVCT`/`PRCTR`/`SEGMENT` blank is a functional question for GR consolidation and document
splitting.

**D. The `0453` hack is dead code.** It `READ`s `lt_acdoca` for `BELNR = 'DG00000000'`, but
`lt_acdoca` only ever holds lines with `BELNR = lv_belnr` (`DU00010…`), so it never hits. Drop it.

---

## 4. What changes for an OVL version — decisions before building

1. **Source of the JV totals.** The program reads the physical `JVTO1`. At OVL JVA-on-ACDOCA
   is active (`JVAONACDOCAACTIV`; see `ovl/zfi_jv_tb/NOTES.md`): for years from the activation
   year the JV totals live in ACDOCA and `JVTO1` holds only legacy years. Use
   `JV_JVTO1_ACDOCA_SWITCH_2` (SAP's union view, `4C` amounts as `_4C` columns — which also
   removes the `4C` self-join) or aggregate `JVSO1`/ACDOCA `4A` lines. **Decision needed**, and
   whether `rldnr = '4A'` rows with full JV attributes already exist in ACDOCA on OCQ
   (SE16H `ACDOCA`, `RLDNR = 4A`, one company code / period).
2. **Add `rrcty = '0' AND rvers = '001'`.** The program filters neither; plan/other record
   types in the JV ledger would be inserted into `0L`. Our recon and `ZOCV_OVL_TRANSFER` both
   filter them.
3. **Currency mapping.** Replace the `PET1`/`PET2` switch with OVL's: which currency types
   `FINSC_001A_REP` holds per company code (SE16, `BUKRS`, read `CURTYPE`/`WAERS`), and which
   JV ledger (`4A` or `4C`) carries the group and the third currency. `ROCUR` should come from
   that configuration, not from scanning `ACDOCA-ROCUR`. If OVL has only two FI currencies,
   drop `OSL`/`ROCUR` handling entirely rather than filling `OSL` = `KSL`.
4. **`ZGTT_COMPANY`.** Either create it as a GTT (SE11 → Technical Settings → table category
   Global Temporary Table) — then the documented rule applies: a filled GTT must be emptied
   with `DELETE FROM` before every database commit or the runtime error `COMMIT_GTT_ERROR`
   occurs; the program's `SELECT COUNT(*)`/re-`INSERT` after each `COMMIT WORK` shows the
   author met this, so add `DELETE FROM zgtt_company` before the `COMMIT` — or create it as
   an ordinary Z table keyed by `BUKRS, LEDGER, GJAHR, POPER` and clear it per run. The join
   inside the `WITH` is the only reason it is a DB table at all (≤ 17 rows per company code
   and year).
5. **`SCAL_TT_DATE`** — drop; loop over the years of `S_GJAHR` directly. One dependency less,
   and no silent "nothing processed" when the table is empty.
6. **Technical markers (`BSTAT`, `MIG_SOURCE`, `SDM_VERSION`, `BTTYPE`, `VORGN`, `AWTYP`).** Do
   not copy his constants. SAP's own JVA direct-ACDOCA postings are identified as
   `VORGN = 'RFRA'`, `BSTAT = 'U'`, `AWTYP = 'BKPFF'` (rgjv NOTES §8), and OVL already has
   ACDOCA-only lines (BELNR `CC001NVFLO`, BLART `KJ`). SE16H one such line on OCQ and take
   `BSTAT`, `MIG_SOURCE`, `SDM_VERSION`, `BTTYPE`, `VORGN`, `AWTYP`, `BLART` from it; confirm
   with the GR consultant that the data release picks lines with that marking up.
7. **Document number.** Check `ACDOCA 0L` for existing `BELNR LIKE 'DU%'` before fixing the
   root, so the delete mode cannot touch anything that is not ours.
8. **Paste constraints.** Dozens of lines exceed 120 characters (the `CASE` blocks, messages,
   the `MAX(docln)` select). Reformat before paste — SE38 wraps and the tail becomes a bogus
   statement (CLAUDE.md rule). Keep the period `CASE` or replace it with 17 `SELECT`s on a
   dynamic column name; either way one statement per line.
9. **Direct `INSERT` into ACDOCA.** rgjv NOTES §8 recorded *never INSERT into ACDOCA directly*
   and proposed `CL_JVA_MIG_POST_ACDOCA`. This reference does exactly the direct insert. If the
   build goes this way it is a functional/client decision to record (same as the
   `ZFI_ACDOCA_VNAME_UPD` table update), test run first, one company code / one period first,
   and the delete mode kept as the undo.
10. **Keep from the reference:** the net-delta idea (`+jvto1 UNION ALL −acdoca`, grouped, `HAVING`
    ≠ 0), the per-account balancing line, one document per period, `DOCLN` continuing from
    `MAX`, idempotent re-run, test mode, period 000 limited to retained earnings via `T030 BIL`,
    special periods on period 12's date.

## 5. Where to look in SE80 / SE16 on OCQ

- SE11 `ACDOCA`: `CBTTYPE`, `SDM_VERSION`, `PS_POSID`, `PS_PRJ_PNR`, `PS_PSPID` present?
- SE16H `ACDOCA`: `RBUKRS` = one OVL company, `RLDNR = '4A'` — any rows? → decides §4.1.
- SE16H `ACDOCA`: `BELNR = 'CC001NVFLO'` → the marker fields for §4.6.
- SE16 `FINSC_001A_REP`, `FINSC_LD_CMP`, `TKA02`/`TKA01` for the company codes → §4.3.
- SE16 `T030`: `KTOPL` of OVL, `KTOSL = 'BIL'` → the retained-earnings account(s).
- SE16 `JVAONACDOCAACTIV` → activation year per company code.
