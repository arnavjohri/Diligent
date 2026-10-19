# ZR_PROG_DOWNLOAD — mass source download with include tree (developer utility)

Read-only report. Downloads ABAP sources to the PC (`GUI_DOWNLOAD`, UTF-8, no BOM) or
to the application server (`OPEN DATASET`), **one file per object**, in the
"print with includes" listing layout that every `original/` in this repo uses.

Paste-only (single report, no includes, no screens beyond 1000). Create in SE38 as
type 1 executable, paste `ZR_PROG_DOWNLOAD.abap` whole, maintain the texts below, activate.

**History.** The first version (Aug 2026) was never filed in the repo and is lost. This is a
rewrite from its description and from the layout of the listings it produced
(`ovl/atc/sources/reports/*.ABAP`). One addition: **CDS DDL sources (DDLS)**.

## What it downloads

| Object | Selected by | Main unit read | Then |
|---|---|---|---|
| Program (type 1, M, S) | `S_PROG` or package | the program | every `INCLUDE` in source order, recursively (level 1, 2, …) |
| Include named directly | `S_PROG` | the include | its own includes |
| Function group | `S_FUGR` or package | `SAPL<group>` (`/NS/SAPL<group>` for namespaces) | `L<group>TOP`, `L<group>UXX` → `U01…`, `F01…` |
| Class | `S_CLAS` or package | class pool `<class>===…CP` | `CCDEF/CCIMP/CCMAC`, `CU/CO/CI`, then every `CM###` method include via `INCLUDE METHODS` |
| CDS DDL source | `S_DDLS` or package | active source from `DDDDLSRC` | — |

Package mode (`P_BYPACK`, `S_DEVC`) reads TADIR for `PROG / FUGR / CLAS / DDLS`, filtered by the
four checkboxes. Includes of the package that no main program pulled in are written on their
own at the end.

Not expanded, by design: compiler-generated includes (`<SYSINI>`, `%_CABAP`, `DB__SSEL` …) —
the lost version printed them as "Generated incl."; they carry no customer code.
`INCLUDE STRUCTURE` / `INCLUDE TYPE` inside declarations are ignored. An include that does not
exist (`INCLUDE … IF FOUND`) leaves a one-line note in the file instead of stopping the run.

## File names

`<folder><NAME>.<ext>` — `<ext>` from `P_EXT` (default `abap`). Function groups are named by
their main program (`SAPLZXXX.abap`). DDL sources are always `<NAME>.ddls.asddls`, the name
the repo uses. Namespace slashes become `#`.

## Listing layout (per unit)

    ----------------------------------------------------------------------------------------------------
    Main program     ZFI_CP_MASS_VEN_PAY                       Level 0    Page 1
    Object           ZFI_CP_MASS_VEN_PAY                       Lines 37
    System           OCQ / 500   User SAP_ABAP   08.08.2026 15:15:03
    ----------------------------------------------------------------------------------------------------
    1                 REPORT zfi_cp_mass_ven_pay .
    …
    *--- End of ZFI_CP_MASS_VEN_PAY - 37 lines ---

Label is `Main program`, `Include` or `DDL source`; `Page` counts units within the file;
`Object` is always the object the file belongs to. Line numbers restart at 1 in every unit, so
a line number from a listing is only meaningful together with its unit — locate by FORM/MODULE
name, as always.

## Manual steps after paste (SE38 → Goto → Text elements)

Text symbols (block titles — blank on screen if not maintained):

| Symbol | Text |
|---|---|
| B01 | Objects to download |
| B02 | Object types (package selection) |
| B03 | Destination |

Message and column texts are coded as `'literal'(key)` and fall back to the literal, so they
need no maintenance.

Selection texts:

| Field | Text |
|---|---|
| P_BYNAME | Select by object name |
| P_BYPACK | Select by package |
| S_PROG | Program / include |
| S_FUGR | Function group |
| S_CLAS | Class |
| S_DDLS | CDS DDL source |
| S_DEVC | Package |
| P_TPROG | Programs |
| P_TFUGR | Function groups |
| P_TCLAS | Classes |
| P_TDDLS | CDS DDL sources |
| P_FRONT | Download to PC |
| P_FDIR | Folder on PC |
| P_APPL | Write to application server |
| P_ADIR | Directory on application server |
| P_EXT | File extension |

## Unverified names (`ASSUMPTION` in code — first activation confirms)

- `CL_OO_CLASSNAME_SERVICE=>GET_ALL_METHOD_INCLUDES( clsname = … )` returning
  `SEOP_METHODS_W_INCLUDE` with component `INCNAME` (the abapGit route). Only reached for
  classes; programs, FGs and DDLS do not touch it.
- `DDDDLSRC` columns `DDLNAME`, `AS4LOCAL` (`'A'` = active), `SOURCE`.
- `READ REPORT … INTO` a `string` table and `SCAN ABAP-SOURCE` on it (abapGit does both).
- `STOKEX` as token structure (255-char `STR`, needed for 32-char class include names).

If activation rejects one of these, paste the error — the fix is local to that FORM.

## Using it for the 26 purchasing CDS extensions

`P_BYNAME`, `S_DDLS` → multiple selection → paste the 26 names from
`ovl/zmm_purchdoc_cds_ext/NOTES.md` → folder on PC → execute. 26 files
`Z…_EXT.ddls.asddls` land in the folder; drop them into `incoming/` and they are filed with
`./scripts/save-original.sh ovl/zmm_purchdoc_cds_ext incoming/*.asddls`.

## Gotchas

- `GUI_DOWNLOAD` needs SAP GUI; in background use the application-server option and fetch with
  CG3Y / AL11.
- A class that exists only as an interface (`SEOCLASS-CLSTYPE = 1`) is skipped as "does not
  exist"; interfaces are not in scope.
- Includes are written once per file even when included from several places (first occurrence
  wins), so a shared include appears under the first unit that pulls it in.
