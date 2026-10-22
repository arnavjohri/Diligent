# ZFORECAST Paints — manual steps after the abapGit pulls

Astral / UDAY (KPMG), Paints. 22.10.2026, Arnav Johri. Development system.
abapGit never carries a GUI status, a transaction code, a maintenance view or table entries,
so these are done by hand once, in this order.

## 0. The two pulls

| ZIP | Repo (package) | What changes in the system |
|---|---|---|
| `ZPP_FORECAST_UPLOAD_22-10-26_delta.zip` | `ZPP_FORECAST` | `ZPP_FORECAST_UPLOAD` only: ninth radio button Brand, indicator MTS/MTO/DIS/TIN |
| `ZPP_FORECAST_PAINTS_22-10-26_delta.zip` | `ZPP_FORECAST_PAINTS` | New: `ZDO_FCST_KL`, `ZDO_FCST_CR`, `ZDE_PACK_SIZE`, `ZDE_QTY_CARTON`, `ZDE_FCST_KL`, `ZDE_FCST_CR`, `ZPPT_PNT_FCST_YR`, `ZPPT_PNT_FCST_QT`, `ZPPT_PNT_FCST_MN`. Changed: `ZCL_PP_FCST_PNT`, `ZPP_FORECAST_PAINTS` |

ZABAPGIT_STANDALONE → open the repo → Import ZIP → the stage lists the objects above → Pull.
**Before pulling the first ZIP, open the diff of `ZPP_FORECAST_UPLOAD` in the stage: it must
show only lines marked `By Arnav on 22/10/26`. Anything else means the running program has
edits the repository does not have — stop and send the SE80 download instead of pulling.**

## 1. GUI status `PF_STATUS` for `ZPP_FORECAST_PAINTS` (SE41)

The list toolbar needs a status that carries SALV's own functions plus the four buttons Save,
Select all, Deselect all, Export. Until it exists the list runs on SALV's standard status
without the four buttons, and the status bar says "GUI status PF_STATUS not found in
ZPP_FORECAST_PAINTS, standard toolbar used".

**Route A — the Adhesive status exists** (SE41, program `ZPP_FORECAST`, status `PF_STATUS`
opens without "does not exist")

1. SE41. Program `ZPP_FORECAST`, Status `PF_STATUS`.
2. Press **Copy status** (the copy icon on the initial screen, Shift+F7).
3. To program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`. Copy menu bar, application toolbar
   and function keys. Confirm; assign package `ZPP_FORECAST_PAINTS` and the transport.
4. SE41, program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`, Display: the application toolbar
   shows ZSAVE, ZSELALL, ZDESEL, ZEXCEL. **Activate** (Ctrl+F3). Done.

**Route B — from SAP's SALV status** (if Route A finds no Adhesive status)

1. SE41. Program `SAPLSALV_METADATA_STATUS`, Status `SALV_STANDARD`. Press **Copy status**.
2. To program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`, copy everything. Confirm, assign the
   package `ZPP_FORECAST_PAINTS` and the transport.
3. SE41, program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`, **Change**.
4. Expand **Application Toolbar**. Find four free positions (1 to 35; the free ones are the
   empty boxes, usually towards the right). If none is free, overwrite the graphics function
   `&GRAPH` and any other function Paints does not need; everything else stays as copied.
5. In each free box type the function code and press Enter; in the popup fill:

   | Function code | Function text | Icon name | Icon text |
   |---|---|---|---|
   | `ZSAVE` | Save | `ICON_SYSTEM_SAVE` | Save |
   | `ZSELALL` | Select all | `ICON_SELECT_ALL` | Select all |
   | `ZDESEL` | Deselect all | `ICON_DESELECT_ALL` | Deselect all |
   | `ZEXCEL` | Export | `ICON_XLS` | Export |

   Leave Function type blank (normal), no fast path.
6. Expand **Function Keys**: BACK, EXIT and CANC on F3, Shift+F3 and F12 come with the copy;
   the program handles these three codes itself.
7. **Activate** (Ctrl+F3). Run ZFCST_PAINTS once: the four buttons sit in the application
   toolbar row and the status-bar note is gone.

Why this is manual: `ZPP_FORECAST_PAINTS` calls `set_screen_status( pfstatus = 'PF_STATUS'
report = sy-repid set_functions = c_functions_all )`, which switches on every SALV function
whose `&` code the status carries and routes ZSAVE, ZSELALL, ZDESEL and ZEXCEL to
`LCL_HANDLER=>ON_ADDED_FUNCTION`. The status travels in the transport with the program.

## 2. Transaction (SE93)

| Transaction | Type | Program | Screen | Short text |
|---|---|---|---|---|
| `ZFCST_PAINTS` | Program and selection screen (report transaction) | `ZPP_FORECAST_PAINTS` | 1000 | ZFORECAST Paints - Forecast Generation |

SE93 → transaction code → Create → "Program and selection screen (report transaction)" →
program, screen 1000, GUI support SAP GUI for Windows and HTML → Save, package
`ZPP_FORECAST_PAINTS`. Uploads for Paints go through the existing `ZFCST_UPL`; no second
upload transaction.

## 3. Configuration row per Paints plant — not needed

Since 22/10/26 the Paints sales organisation 4000 is hardcoded in `ZCL_PP_FCST_PNT`
(`GC_VKORG`), as the FS states; the class reads the material groups and the quantity per
carton itself with it. No `ZPPV_FCST_CFG` row is needed for a Paints plant. A row is only
needed if the Legacy Data checkbox is to be used (TVARVC name of the permitted users).

## 4. Optional

| Step | When |
|---|---|
| SE38 → delete program `ZPP_FORECAST_PAINTS_UPL` (imported 19/10, withdrawn 22/10; its uploads are in ZFCST_UPL now) | Housekeeping; it does no harm if left |
| SE54 → maintenance view `ZPPV_BRAND` on `ZPPT_BRAND` (one-step, as the other views) | If brands are to be maintained by hand as well as by upload |
| SE54 → views on `ZPPT_PNT_FCST_YR` / `_QT` / `_MN` | Only if the saved forecasts must be editable by hand; SE16 shows them |
| SE11 → domain `ZDO_MTS_MTO` → Value Range → add `DIS` "Dis Art" and `TIN` "Tinting" → Activate (no conversion, length unchanged) | If Paints categories are maintained through SM30 `ZPPV_PROD_CAT`; the upload writes the codes regardless |
| STVARV → `ZPP_FORECAST_MTART` rows FERT, HAWA | Already there for Adhesive; applies to Paints too |

## 5. Then

Run the test handover (`docs/ZFORECAST_Paints_Test_Handover.docx`). The saved Paints
forecasts, shaped exactly as the list, are in `ZPPT_PNT_FCST_YR`, `ZPPT_PNT_FCST_QT`,
`ZPPT_PNT_FCST_MN`. The shared `ZPPT_FCST_YR` / `_QT` / `_MN` rows are written as well; that is
what the business-forecast and change uploads, the engine and the final report read.
