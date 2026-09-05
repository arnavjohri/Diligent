# ZSD_EXC_APPROVAL.zip — what is in it, and what is NOT proven

First built 03/09/26 as `ZSD_EXP_PAINTS.zip`, renamed 04/09/26, **rebuilt 05/09/26** from
`src/` after the review below. 19 files, file entries only (no `src/` directory entry).

## Contents

| Objects | Count | In the ZIP |
|---|---|---|
| Domains | 5 | yes |
| Data elements | 6 | yes |
| Table ZSD_EXP_PAINTS | 1 | yes — fields, key, currency references, technical settings, client dependency, enhancement category |
| Programs | 2 | yes — source **and** all text elements (TPOOL) |
| Table maintenance generator | 1 | **no — abapGit does not serialise a TMG, ever** |
| Foreign keys | 2 | **no — deliberately left out, see below** |
| ZSD_EXC_APPR_ADHESIVE (141.A) | 1 | **no** — see `ABAPGIT_UPLOAD_STEPS.md`, "Why A is not here" |

The TPOOL is the real saving: 54 text symbols + 5 selection texts for the upload program,
38 + 10 for the report. That is ~107 lines you would otherwise type into SE38 by hand.

## Import

`ZABAPGIT_STANDALONE` -> New Offline Repo -> Import package from ZIP -> Pull.
Import DDIC first, activate, then the programs — the programs do not activate until
ZSD_EXP_PAINTS is active.

## What changed on 05/09/26, and why

The 03/09/26 build was checked element by element against the shape of real abapGit
serialisations. Six defects, all of the class that dumps `CX_XSLT_FORMAT_ERROR` on import
because `CALL TRANSFORMATION id` walks the target DDIC structure component by component:

| # | File(s) | Was | Now |
|---|---|---|---|
| 1 | `zsd_do_exc_amount.doma.xml`, `zsd_do_exc_type.doma.xml`, `zsd_do_exc_remarks.doma.xml` | `DDTEXT` before `SIGNFLAG` / `VALEXI` / `LOWERCASE` | `DDTEXT` after them — DD01V order is DOMNAME, DDLANGUAGE, DATATYPE, LENG, DECIMALS, OUTPUTLEN, LOWERCASE, SIGNFLAG, VALEXI, …, DDTEXT |
| 2 | `zsd_exp_paints.tabl.xml` — the three CURR fields | `REFTABLE` / `REFFIELD` after `COMPTYPE` | before `NOTNULL` / `COMPTYPE` — DD03P order is FIELDNAME, KEYFLAG, ROLLNAME, ADMINFIELD, INTTYPE, INTLEN, REFTABLE, PRECFIELD, REFFIELD, CONROUND, NOTNULL, …, COMPTYPE |
| 3 | all six `*.dtel.xml` | no `REFKIND` | `<REFKIND>D</REFKIND>` after `DTELMASTER` — a domain-based data element carries it in every real serialisation |
| 4 | `zsd_exp_paints.tabl.xml` DD02V | no `CLIDEP`, no `EXCLASS`, text "Exceptional Approval - Paints" | `<CLIDEP>X</CLIDEP>` after TABCLASS, `<EXCLASS>4</EXCLASS>` (can be enhanced, deep) after CONTFLAG, text "Exceptional Approval Data - Paints" as on the build sheet |
| 5 | both `*.prog.xml`, TPOOL `ID S` items | `LENGTH` = text length | `LENGTH` = text length + 8 — abapGit splits the 8-character textpool prefix into `SPLIT` and keeps the full length |
| 6 | the ZIP itself | carried a `src/` directory entry | file entries only |

Empty elements (`<KEYFLAG></KEYFLAG>`, `<NOTNULL></NOTNULL>`) were dropped as well; real
serialisations omit initial values. The `.abapgit.xml` was already correct — a bare
`<asx:abap>` document — and is unchanged.

## THE HONEST STATUS — read before relying on this

**No hand-written abapGit ZIP has ever been confirmed to import on this landscape**, and this
one has not been tried since the rebuild. What is different from every earlier attempt:

1. The `kpmg/zfi_tds_cl34/` failure — four dumps, "still unexplained" until 05/09/26 — has a
   root cause now. Its `.abapgit.xml` is wrapped in an `<abapGit ...>` element. abapGit parses
   object XML through `zcl_abapgit_xml_input`, which strips that wrapper before the
   transformation, but it reads `.abapgit.xml` with `zcl_abapgit_dot_abapgit=>from_xml`, which
   runs `CALL TRANSFORMATION id` on the raw string and needs a bare `<asx:abap>` root. That is
   the `FROM_XML` frame the dumps named, and it fires the moment the ZIP is imported, before
   any object is looked at — which matches "the list is empty or the pull short-dumps". None
   of the four fixes tried there touched that file.
2. `kpmg/zpp_forecast_v2/` — its `prog.xml` files carry `PROGDIR` in the order
   `NAME, SUBC, FIXPT, VARCL, UCCHECK`; the correct order is `NAME, VARCL, SUBC, FIXPT,
   UCCHECK`. There is no record that its ZIP was ever imported.

So: try the ZIP. If it dumps, go to ST22, open the `FROM_XML` / `READ` frame and note **which
file** abapGit was deserialising — that single fact is worth more than any further guessing —
then fall back to the manual path (`ZSD_EXP_PAINTS_DDIC.md` for objects 1-3, paste for the two
programs). Nothing is lost by trying; do not schedule around it working.

## Left out on purpose

- **Foreign keys** (`ZCUSTOMER` -> KNA1, `WAERS` -> TCURC). They serialise as
  `DD08V_TABLE` / `DD05M_TABLE`, which is more hand-written structure and more chance of
  the same format error. Add them in SE11 in two minutes — `ZSD_EXP_PAINTS_DDIC.md` §3.4,
  where SE11 proposes both.
- **Log data changes.** Tick it in Technical Settings after import (DDIC sheet §3.6).
- **The TMG.** Always manual, always (DDIC sheet §4).
- **ZSD_EXC_APPR_ADHESIVE.** Not until its repo copy is reconciled with the version that is
  active in the system (ISSUES.md #17).

## One value to check after import

`ZSD_DO_EXC_AMOUNT` carries `OUTPUTLEN 000031`, computed for CURR 23,2 with a sign, not
read off a system. If SE11 objects to it, blank the Output Length field and press Enter —
SE11 recalculates it from length + decimals.
