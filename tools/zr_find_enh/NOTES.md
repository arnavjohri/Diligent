# ZR_FIND_ENH — enhancement finder (developer utility)

Starts from an FM / class method / program, follows `CALL FUNCTION`, `PERFORM`
and method calls down to *Depth* levels, and lists every enhancement option met.
Read-only. Paste-only (single report, no includes, no screens beyond 1000).

## What it reports (column "Enhancement type")

| Type | Detected from | Extra info |
|---|---|---|
| CUSTOMER EXIT | `CALL CUSTOMER-FUNCTION 'nnn'` → `EXIT_<main>_nnn` | SMOD enhancement (MODSAP), CMOD project(s) (MODACT) |
| CLASSIC BADI | `CL_EXITHANDLER=>GET_INSTANCE` | BAdI name from `EXIT_NAME` or `IF_EX_*` type; implementations from SXC_EXIT |
| NEW BADI / NEW BADI CALL | `GET BADI` / `CALL BADI` | BAdI name from the variable's `TYPE REF TO` |
| ENH POINT / ENH SECTION | `ENHANCEMENT-POINT/-SECTION ... SPOTS` | spot name |
| BTE | `OPEN_FI_PERFORM_*`, `OUTBOUND_CALL_*`, `BF_FUNCTIONS_FIND` | event number → FIBF |
| SCREEN EXIT | `CALL CUSTOMER-SUBSCREEN` | |
| USER EXIT (FORM) | `PERFORM USEREXIT_*` | include holding the FORM (MV45AFZZ etc.) |
| IMPLICIT | one row per routine scanned, only with *Implicit options* ticked | |
| NOT FOLLOWED | only with *List calls not followed* ticked | dynamic / unresolved calls |

## Limits (static analysis)

- Dynamic calls (`CALL FUNCTION lv_fm`, `PERFORM (lv)`, `->(lv_meth)`) are counted, not followed.
- Instance calls `lo->meth( )` are resolved through the where-used index (WBCROSSGT).
  If the index is not built, or the call is on an interface, it is not followed.
- `SUBMIT`, `CALL TRANSACTION`, RFC destinations, local classes: not followed.
- Lists enhancement **options**. Already-implemented implicit/explicit enhancements are not
  read from the enhancement tables — open the include in SE80 and use the spiral button.
- Runtime cross-check: debugger → Breakpoints → Breakpoint at Statement
  `GET BADI`, `CALL BADI`, `CALL CUSTOMER-FUNCTION`; method breakpoint
  `CL_EXITHANDLER=>GET_INSTANCE`; FM breakpoint `BF_FUNCTIONS_FIND`.

## Unverified names (ASSUMPTION in code — first activation/run confirms)

- `SEOMETAREL` RELTYPE `'2'` = inheritance.
- `WBCROSSGT` stores method refs as OTYPE `'ME'`, NAME `<CLASS>\ME:<METHOD>`.
- `MODACT`: NAME = CMOD project, MEMBER = SMOD enhancement.

## Manual steps after paste (SE38)

Text symbols: `B01` Start from · `B02` Options

Selection texts:

| Param | Text |
|---|---|
| P_RFM | Function module |
| P_FM | Function module name |
| P_RMT | Class method |
| P_CLS | Class |
| P_MTH | Method |
| P_RPG | Program / include |
| P_PROG | Program name |
| P_DEPTH | Call depth to follow |
| P_MAX | Max. routines to scan |
| P_ZCALL | Also follow Z/Y objects |
| P_IMPL | Show implicit options |
| P_NF | List calls not followed |

## Usage tips

- Depth 3–4 is usually enough; big standard FMs (BAPI_PO_CREATE1, SD_SALESDOCUMENT_CREATE)
  fan out fast — raise *Max. routines* if the summary says it stopped at the limit.
- Filter the ALV on *Enhancement type*; *Call path* shows how each one is reached.
