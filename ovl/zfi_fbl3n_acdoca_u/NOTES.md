# ZFI_FBL3N_ACDOCA_U — show ACDOCA-only lines (BSTAT = 'U') in FBL3N

**What it is.** Classic BAdI `FI_ITEMS_CH_DATA`, method `CHANGE_ITEMS`
(`CT_ITEMS TYPE IT_RFPOSXEXT`). FBL3N (program `RFITEMGL`, logical database
`SDF`) builds its list from BSIS/BSAS, so a journal entry that exists only in
ACDOCA with document status `U` (no BSEG item) is never shown. The BAdI selects
those ACDOCA lines for the G/L accounts, company codes and posting dates on the
FBL3N selection screen and appends them to `CT_ITEMS`. FBL3N only — the same
BAdI fires for FBL1N and FBL5N, which it leaves untouched (`sy-tcode` check).

Client folder is a placeholder until Arnav names the project (OVL or KPMG).
Move with `git mv`; nothing inside depends on the path.

Source: `ZCL_IM_FI_FBL3N_ACDOCA_U.abap` — header comment plus the complete
method `IF_EX_FI_ITEMS_CH_DATA~CHANGE_ITEMS`.

## How it ships

Paste-only (BAdI method body).

1. SE19 → **Classic BAdI** → `FI_ITEMS_CH_DATA` → Create implementation
   `ZFI_FBL3N_ACDOCA_U`, implementing class `ZCL_IM_FI_FBL3N_ACDOCA_U`.
2. Interface tab → double-click `CHANGE_ITEMS` → paste the lines between
   `METHOD` and `ENDMETHOD` from the `.abap` file → activate the class.
3. SE19 → Activate the implementation.
4. **`FI_ITEMS_CH_DATA` is not multiple-use.** If SE19 already shows an active
   implementation (common — clients use it to add columns in FBL1N/FBL5N), do
   not create a second one: paste the same body into the existing
   `CHANGE_ITEMS` inside `*BOC/*EOC By Arnav on DD/MM/YY` markers. The `sy-tcode`
   guard at the top keeps it away from the existing logic for other tcodes.

## Before activating — verify the technical names (one F1 each)

The selection screen is read with `ASSIGN ('(RFITEMGL)<name>')`. A wrong name is
caught (`sy-subrc`) and reported with an information message — no dump — but then
nothing is added. On the FBL3N screen, cursor on the field → F1 → Technical
Information → *Screen field*:

| Screen field | Expected name | Used for |
|---|---|---|
| G/L account | `SD_SAKNR` | `racct IN` |
| Company code | `SD_BUKRS` | `rbukrs IN` |
| Open items (radio) | `X_OPSEL` | `budat <= key date` |
| Open at key date | `PA_STIDA` | key date |
| Cleared items (radio) | `X_CLSEL` | nothing added (never cleared) |
| All items (radio) | `X_AISEL` | not read — the `ELSE` branch |
| Posting date (all items) | `SO_BUDAT` | `budat IN` |

If a name differs, change the literal in the `ASSIGN` for that field only.

## Behaviour

- Leading ledger from `T881-XLEADING = 'X'` (ACDOCA has one line per ledger;
  FBL3N is the entry view, so one ledger only). Not found → message, nothing added.
- `SELECT` from `ACDOCA` `LEFT OUTER JOIN BKPF` (XBLNR, BKTXT, USNAM, MONAT).
  A line without a BKPF header is still listed; period then comes from `POPER`.
- `F_BKPF_BUK` activity 03 per company code, as LDB `SDF` does for the standard
  items. Unauthorised company codes are dropped silently (same as standard).
- Dedup on BUKRS/BELNR/GJAHR/BUZEI against what FBL3N already selected.
- `BUZEI` = last three digits of `DOCLN` (no BSEG item exists). `KOART = 'S'`,
  `KONTO = HKONT = RACCT`, `SHKZG = DRCRK`,
  `DMSHB/WRSHB = HSL/WSL` (debit +, credit −, same convention both sides),
  `WAERS = RWCUR`, `HWAER = RHCUR`, `KOSTL = RCNTR`, `GSBER = RBUSA`, `U_BKTXT`, `U_USNAM`, plus
  BLART, BUDAT, BLDAT, XBLNR, SGTXT, ZUONR, PRCTR, AUFNR, BSCHL, MWSKZ, BSTAT.

## Not done, deliberately

- `F_BKPF_BES` (account authorisation group `SKB1-BEGRU`) is not checked. Raise
  if the client uses account auth groups.
- FBL3N dynamic selections (BKPF/BSEG fields) and the worklist mode are ignored.
- No sort of `CT_ITEMS` — the ALV layout sorts.
- Columns not in ACDOCA (payment terms, clearing, reference keys) stay empty.

## Open points / risks (grep `ASSUMPTION` in the source)

- Confirmed by the first activation (19/10/26): `RFPOSXEXT` here has **no** `DMBTR`, `WRBTR`,
  `CPUDT` or `SEGMENT`; header text and user are `U_BKTXT` / `U_USNAM`. `HWAER` exists.
- Whether `CHANGE_ITEMS` is called at all when the standard selection finds **zero**
  items is not confirmed. Test first on an account that also has normal items;
  then on one with only status-U lines. If the second case shows nothing, the
  BAdI is not reached and a different hook is needed.
- Double-click on an appended line calls FB03 with the derived `BUZEI`; for a
  document without BSEG, FB03 shows the journal entry view. Check once.

## Test steps

1. SE16 → `ACDOCA`, `BSTAT = 'U'`, `RLDNR = <leading>`, one `RBUKRS`, note a
   `RACCT` and the line count for a posting-date range.
2. FBL3N, that account / company code, *All items*, same date range → the
   count should rise by exactly that number; the new lines show BSTAT `U`.
3. Same with *Open items* at a key date; *Cleared items* adds nothing.
4. FBL1N / FBL5N unchanged.
5. A user without `F_BKPF_BUK` for the company code sees no added lines.
