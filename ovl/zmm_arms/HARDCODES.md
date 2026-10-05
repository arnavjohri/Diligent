# ZMM_ARMS — hardcoded values register

Program **SAPMZMMPREPROLE1** (module pool, package ZMM_OTH, created 29.05.2006 by CAB_AJIT,
last changed 31.07.2016 by SAB_SUMODH). Title: *End User Authorisation*, FS-MM-AUTH-004.
Includes: `MZMMPREPROLE1TOP`, `MZMMPREPROLE1O01`, `MZMMPREPROLE1I01`, `MZMMPREPROLE1F01`.

Source: SE38 print listing from system OCD, 05.10.2026 (`original/SAPMZMMPREPROLE1_listing.txt`).
That listing cuts every line at column 72; the full-width lines were read from the repo copy in
`ovl/atc/sources/modpool/`, which matches the listing line for line (**no drift**).

Line numbers are the include line numbers in that listing. They are snapshot-bound, so locate
the code by FORM/MODULE name. Only active code is listed here. Commented-out lines are left out.

---

## 1. Company code → purchasing-group prefix map (business-critical)

This is the biggest hardcode. The program decides which purchasing groups (T024-EKGRP) a user
may request from the user's company code. The mapping lives in the code, **in 3 identical copies**:

| Where | Include / line |
|---|---|
| `FORM validate_lineitem_datax` (save-time check) | F01 3153–3247 |
| `MODULE POV_GRP` (F4 help on Purchasing Group) | I01 307–401 |
| `MODULE validate_lineitem_data` (PAI check) | I01 1804–1898 |

| Company code (`G_CCODE`) | Purchasing groups allowed (`EKGRP LIKE`) |
|---|---|
| SBS, SBW | `R%` |
| DVP | `L%` |
| ANK | `A%` |
| BDA, BDW | `B%` |
| CBY | `C%` |
| AMD | `D%` |
| MHN | `E%` |
| JDH | `G%` |
| RJY | `K%` |
| SIL | `S%` |
| AGT | `T%` |
| MBP | `W%` |
| KKL | `M%` **plus** `V%` (the only code with two prefixes, done by a second SELECT) |

**Any other company code** (not in the list) gets every purchasing group *except* these ranges:

```
ekgrp NOT BETWEEN 'A' AND 'EZZ'   (A, B, C, D, E)
ekgrp NOT BETWEEN 'K' AND 'MZZ'   (K, L, M)
ekgrp NOT BETWEEN 'G' AND 'GZZ'   (G)
ekgrp NOT BETWEEN 'R' AND 'TZZ'   (R, S, T)
ekgrp NOT BETWEEN 'V' AND 'WZZ'   (V, W)
```

So the remaining prefixes (F, H, I, J, N, O, P, Q, U, X, Y, Z, digits) all belong to every
unlisted company code.

**How `G_CCODE` is filled:**
- For a normal request it is `ZMM_PREP_ROLEREQ-CCODE`, which comes from the user's PA0001-BUKRS.
- For a cross-company request (`CROSSCO_FL = 'X'` or fcode `CROSSCO`) it is the user's own
  PA0001-BUKRS, not the target company code.

**Impact:**
- A new company code, a renamed one, or a new purchasing-group series needs a code change in
  3 places.
- If the 3 copies ever differ, the F4 list and the save check will disagree.
- `'EZZ'`-style upper bounds only work for 3-character EKGRP values that sort below `ZZ`.

## 2. MM-discipline rules

| Hardcode | Where | Meaning in code |
|---|---|---|
| `DISC_CD = '36'` | `MODULE validate_header_data`, I01 695 | If the user's discipline code (ZDESIGNATION_REV-DISC_CD) is `36`, `DISC_MM_FLAG` is set to `X`, which marks the user as MM discipline. |
| EKGRP 2nd character `BETWEEN '0' AND 'A'` | F01 3263/3276, I01 437/450, I01 1913/1926 | **Non-MM user:** purchasing groups whose 2nd character is between `'0'` and `'A'` (digits, `:;<=>?@`, `A`) are removed. **MM user:** only those groups are kept. This means the naming convention for purchasing groups is built into the code. |
| Roles `M6`, `M7`, `M8` | same 3 places | These roles skip the discipline filter above, so they get all groups of the company code. |
| ZMM_CONSM-ZAREA 1st character `= 'M'` | F01 3349/3372, I01 1134/1157, I01 2002/2025 | **MM user:** only storage locations whose ZAREA starts with `M` are allowed. **Non-MM user:** those locations are excluded. |
| DISC_MM approval restricted to `IM`/`L1` | `FORM validations` F01 1937–1948; `FORM validations1` F01 2083–2089 | Message "This requires approval of I/C MM". |

## 3. Role codes (ZMM_PREP_ROLEREI-ROLE_NAME) wired into the logic

| Role(s) | Hardcoded behaviour | Where |
|---|---|---|
| M6, M7, M8 | No MM/non-MM filter on purchasing group | see §2 |
| M13, M14, M16, M18, M19 | Plant must have storage locations in T001L. The SLOC is validated against T001L + ZMM_CONSM. | F01 3318–3407, I01 1972–2054 |
| M12 | Receipt location must have ZMM_LOCATION-LOCCG = `'RL'` | F01 3415–3431, I01 1556/2073, `POV_RECEIPT_LOC` |
| M17 | Receipt location must have ZMM_LOCATION-LOCCG = `'CF'` | F01 3434–3444, I01 1569/2086 |
| M8 | Approver F4 is filtered on ZMM_PREP_APPROVE-M8_FLAG | `POV_APPROVER` I01 1365; I01 2178 |
| M11S | Approver F4: MM user → MM_FLAG; non-MM user → M11S_FLAG | I01 1322; I01 2135 |
| M11M | Approver F4: MM user → MM_FLAG **and** M11M_FLAG; non-MM user → M11M_FLAG and not MM_FLAG | I01 1342; I01 2155 |
| M3, M3A, M3B (CRC) | Approver F4 on ZMM_PREP_APP_CRC-M3_FLAG / M3A_FLAG / M3B_FLAG | I01 1379–1413; I01 2192–2220 |
| M11S, M11M (CRC) | Same as non-CRC, but read from ZMM_PREP_APP_CRC | I01 1416–1461; I01 2229–2264 |
| M3B, M11S, M11M | On screen 100, CRC_POS is closed and APPROVER is open for these roles; all other roles get the reverse | `MODULE TABCTRL100_attrib` O01 884–907 |

**Impact:** each role-specific flag is a **column** in ZMM_PREP_APPROVE / ZMM_PREP_APP_CRC.
A new role that needs its own approver list needs a table change and a code change.

## 4. Approval levels and release codes (authorisation)

These are the program's **only** authorisation checks. 7 hardcoded `AUTHORITY-CHECK OBJECT 'M_EINK_FRG' ID 'FRGCO'`
calls test whether the user holds a given release code. The code checks no PFCG role names
(AGR_USERS) and no other authorisation object. Adding a release code, or giving an existing
code a different level, means a code change.

`FORM get_user` (F01 1808–1871) works out the user's level from authorisation object
`M_EINK_FRG`, field `FRGCO`. The first match wins.

| FRGCO value held | `g_user` set to |
|---|---|
| L1 | L1 |
| DI | L1 |
| CS | L1 |
| MD | L1 |
| IM | IM |
| L2 | **L3** (L2 is mapped to L3) |
| L3 | L3 |

How each level is used:

| Level | Approval flag it may set (O01 344–356) | Reject code it may use (I01 2330–2336) |
|---|---|---|
| L1 | `REQ_APP1_FL` | `R` |
| IM | `REQ_APP0_FL` | `I` |
| L3 | `REQ_APP_FL` | `B` |

- **Hierarchy L3 < IM < L1:** `FORM validate_role_approval_level` (F01 3631–3652) compares
  against ZMM_PREP_ROLEGRP-APPROVER1.
- **Popup text:** `IM` is shown as `'I/C MM'` (F01 3663, 3725).
- **Cross-company exception:** an approver whose personnel area is in a different company code
  is blocked with e112 unless listed in ZMM_PREP_EX_APP. In the `REQ_APP1_FL` branch, `g_user = 'L1'`
  is also exempt (`FORM insert_header` F01 1178).
- **Request already approved:** if `g_user = 'L1'` and APP0/APP flags are set, message i132 is
  raised (`FORM validations` F01 1893).

## 5. Status values (ZMM_PREP_ROLEREQ-STATUS)

| Value | Set / tested where |
|---|---|
| `IC` | Set when the creator resets released flags (`FORM verify`, F01 2314). |
| `IR` | Set on CHANGE with `COMM_FL = 'X'` (F01 1250). |
| `IF` | Set after an approval when the status was `IC`/`IR`; also set on DISPLAY + attachment while `IR` (F01 970–975, 1054–1059, 1124–1129, 1205–1210, 1244, 1269). |
| `N` | Set after an approval in all other cases (same places as `IF`). |
| `PC`, `C` | Only read, never set here. They block CHANGE (`FORM validations` F01 1919–1921, 2021). These values must be set by another program (the ICE team side). |

## 6. HR / personnel hardcodes

| Hardcode | Where | Note |
|---|---|---|
| `endda = '99991231'`, `sprps = ' '` on PA0001 and PA9930 | Every HR join: `FORM insert_header` (×4), `FORM validate_lineitem_datax`, `MODULE validate_header_data`, `MODULE POV_PLANT`, `MODULE validate_lineitem_data` | Only the open-ended record counts. Someone with a future-dated end or a delimited record is treated as "not found". |
| PA0027 `ENDDA = '99991231' AND SPRPS = ' '` | `MODULE validate_header_data` I01 736 | This literal is cut off in the listing; it was confirmed from the repo copy. |
| **PERNR = `'000'` + SAP user ID** (`cpf_lfb1`, CHAR 8) | F01 3006; I01 254, 727, 1657 | Assumes every SAP user ID is a 5-digit CPF number and PERNR is the same number with 3 leading zeros. A user ID of any other length gives a wrong PERNR or one cut to 8 characters. PA0001 is read directly with `pernr = USERID` elsewhere, so both conventions are in use. |
| `RSN_CODE = '01'` | I01 631 (default on create); O01 196, 401, 505 | Reason `01` is the only one that opens Personnel Area (PERSA) for input and triggers the "joined at new location" popup (`FORM pop_up_message`). |
| FMZUOB `OBJNR LIKE '%<cost centre>'` | I01 742–751 | The fund centre is derived from the cost centre by suffix match on OBJNR. This is a convention, and a full-table LIKE scan. |
| Fund centre `FICTR LIKE '<CCODE>%'` | `FORM HELP_LIST` F01 541–548 | Assumes every fund-centre code starts with the company code. |
| Max 4 fund centres | `FORM insert_header` F01 1219–1229 | A 5th one gives message i078. |

## 7. Technical / object hardcodes

| Hardcode | Where |
|---|---|
| Number range object `ZDOCNUMB`, interval `'01'` | `FORM gen_no` F01 837–842 (`sy-subrc` is not checked) |
| Long text object `ZHELP`, ID `'0001'`, line size 72, name = DOCNO | `FORM get_correspondense`, `FORM save_cors_text`, `FORM delete_cors_text` |
| Reply marker `'**Reply'` / `'* Reply'` + date `DD/MM/YYYY` + `sy-uname` | `FORM save_cors_text` F01 1770–1774; highlighting in `FORM text_control_set_text_table1` F01 1694 |
| Attachments: `objtype = 'ATT'`, `objkey = '01'`, DOCNO stored in the **LOGSYS** field (`DOCNO+2(10)`, which drops the first 2 of 12 digits), type `'DOC'` | `FORM attach_files`, `FORM list_files` F01 3491–3519 |
| Upload mode: `TXT`/`HTM` → ASC, everything else → BIN | `FORM attach_file` F01 2661–2685 |
| Release check `sy-saprl GT '4.6D'` | F01 2595 |
| Lock object `EZ_MM_PREPHDR`, mode `'E'` | `FORM lock_reqhd`, `FORM unlock_record` |
| SET/GET parameter `ZREQNO` (DOCNO); `FIS` and `BUK` are cleared | F01 82, 1302; O01 582–583 |
| Table control: columns with index > 11 hidden, column 12 shown | `MODULE scr100_col_attrib` O01 1094–1100 (breaks if the screen layout changes) |
| Screen `'0100'` in `SWD_DYNPRO_FIELD_GET` | I01 422, 1110, 1273, 1549, 2488 |
| Message class `ZHELP` throughout | — |

## 8. Transaction-code hardcodes

| Hardcode | Where | Effect |
|---|---|---|
| `sy-tcode = 'ZMM_ARMS'` | `MODULE ICE_ARMS` O01 1214–1228 | Shows a popup: *"This transaction has been discontinued — Please use ZICE_ARMS in place of ZMM_ARMS"*, then **`LEAVE PROGRAM`**. The `LEAVE PROGRAM` is outside the IF, so any screen whose PBO calls ICE_ARMS ends the program. |
| `sy-tcode = 'ZMM_ARMS_CONNECT'` | `FORM fill_sttab` F01 80–83 | Forces DISPLAY mode and reads DOCNO from parameter ZREQNO (drill-in from another program). |

## 9. Organisation-specific text in popups

Hardcoded English text, not text elements, so it cannot be translated or changed without a
code change. All in F01:
- "Please send order copy by fax to **Head-ICE**" (`pop_up_crc_message` 3597, `pop_up_crossco_message` 3616).
- "routed to **ICE core team**" (`popup_release_message` 3674, `popup_approve_message` 3693,
  `verify2` 3711–3713, `popup_release_message1` 3729).
- "**I/C MM**" (F01 1943, 3664, 3726).

---

## Already table-driven (not hardcoded)

ZMM_PREP_ROLEDES / ZMM_PREP_ROLECRC (which fields each role requires), ZMM_PREP_ROLEGRP
(approver level per role), ZMM_PREP_APPROVE / ZMM_PREP_APP_CRC (approver lists),
ZMM_PREP_REJ_LIS (reject codes), ZMM_PREP_EX_APP (cross-company approver exceptions),
ZMM_LOCATION, ZMM_CONSM, ZD_T001W_BUKRS (plant ↔ company code), ZMM_PREP_CRCDESG.

## Not visible in this download

Screen flow logic (which screen's PBO calls `ICE_ARMS`), GUI status `OPTNS`/`STATUS_120`/`STAT105`,
the ZHELP message texts, and the number-range interval itself. Check them in SE51 / SE41 / SE91 /
SNRO. Any literals in those are not covered here.
