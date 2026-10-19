# ZFORECAST Paints — manual steps after the abapGit pull

Astral / UDAY (KPMG), Paints. 19.10.2026, Arnav Johri. Development system.
abapGit never carries a GUI status, a transaction code, a maintenance view or table
entries, so these are done by hand once, in this order.

## 1. GUI status `PF_STATUS` for `ZPP_FORECAST_PAINTS` (SE41)

The list toolbar needs a status that carries SALV's own functions plus the four buttons
Save, Select all, Deselect all, Export. Until it exists the list runs on SALV's standard
status, without the four buttons, and the status bar says
"GUI status PF_STATUS not found in ZPP_FORECAST_PAINTS, standard toolbar used".

**Route A — the Adhesive status exists** (SE41, program `ZPP_FORECAST`, status `PF_STATUS`
opens without "does not exist")

1. SE41. Program `ZPP_FORECAST`, Status `PF_STATUS`.
2. Press **Copy status** (the copy icon on the initial screen, Shift+F7).
3. In the dialog: To program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`. Copy menu bar,
   application toolbar and function keys. Confirm; if asked about the object list, choose
   the package `ZPP_FORECAST_PAINTS` and the transport.
4. SE41, program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`, Display: the application
   toolbar must show ZSAVE, ZSELALL, ZDESEL, ZEXCEL. **Activate** (Ctrl+F3). Done.

**Route B — from SAP's SALV status** (if Route A finds no Adhesive status)

1. SE41. Program `SAPLSALV_METADATA_STATUS`, Status `SALV_STANDARD`. Press **Copy status**.
2. To program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`, copy everything. Confirm, assign the
   package `ZPP_FORECAST_PAINTS` and the transport.
3. SE41, program `ZPP_FORECAST_PAINTS`, status `PF_STATUS`, **Change**.
4. Expand **Application Toolbar**. Find four free positions (positions 1 to 35; the free
   ones are the empty boxes, usually towards the right). If none is free, overwrite the
   graphics function `&GRAPH` and any other function Paints does not need; everything else
   stays as copied.
5. In each free box type the function code and press Enter; in the popup fill:

   | Function code | Function text | Icon name | Icon text |
   |---|---|---|---|
   | `ZSAVE` | Save | `ICON_SYSTEM_SAVE` | Save |
   | `ZSELALL` | Select all | `ICON_SELECT_ALL` | Select all |
   | `ZDESEL` | Deselect all | `ICON_DESELECT_ALL` | Deselect all |
   | `ZEXCEL` | Export | `ICON_XLS` | Export |

   Leave Function type blank (normal), no fast path.
6. Expand **Function Keys**: check that BACK, EXIT and CANC are assigned to F3, Shift+F3 and
   F12 (they come with the copy). The program handles these three codes itself.
7. **Activate** (Ctrl+F3). Run ZFCST_PAINTS once: the four buttons sit in the application
   toolbar row and the status-bar note is gone.

Why this is manual: `ZPP_FORECAST_PAINTS` calls `set_screen_status( pfstatus = 'PF_STATUS'
report = sy-repid set_functions = c_functions_all )`, which switches on every SALV function
whose `&` code the status carries and routes ZSAVE, ZSELALL, ZDESEL and ZEXCEL to
`LCL_HANDLER=>ON_ADDED_FUNCTION`. The status travels in the transport with the program.

## 2. Transactions (SE93)

| Transaction | Type | Program | Screen | Short text |
|---|---|---|---|---|
| `ZFCST_PAINTS` | Program and selection screen (report transaction) | `ZPP_FORECAST_PAINTS` | 1000 | ZFORECAST Paints - Forecast Generation |
| `ZFCST_PAINTS_UPL` | Program and selection screen (report transaction) | `ZPP_FORECAST_PAINTS_UPL` | 1000 | ZFORECAST Paints - Uploads |

SE93 → transaction code → Create → "Program and selection screen (report transaction)" →
program, screen 1000, GUI support SAP GUI for Windows and HTML → Save, package
`ZPP_FORECAST_PAINTS`.

## 3. Configuration row per Paints plant (SM30 `ZPPV_FCST_CFG`)

| Field | Value |
|---|---|
| Plant | each Paints plant |
| Sales Org (`VKORG`) | 4000 (FS value; confirm) |
| TVARV name for legacy users | as for Adhesive, or blank |
| Movement type | leave blank, no longer used |

Without a row the run logs message 018 in SLG1 and uses 4000. The material groups and the
quantity per carton are read for this sales organisation.

## 4. Optional

| Step | When |
|---|---|
| SE54 → generate maintenance view `ZPPV_BRAND` on `ZPPT_BRAND` (one-step, function group as for the other views, authorisation group as for `ZPPV_MAT_EXCL`) | If brands are to be maintained by hand as well as by upload |
| SE54 → `ZPPV_PNT_FCST_YR` / `_QT` / `_MN` on the three Paints forecast tables | Only if the saved forecasts must be editable by hand; not needed for testing (SE16 shows them) |
| SE11 → domain `ZDO_MTS_MTO` → Value Range → add fixed values `DIS` "Dis Art" and `TIN` "Tinting" → Activate (no conversion, length unchanged) | If Paints categories are maintained through SM30 `ZPPV_PROD_CAT`; the Paints upload writes the codes regardless |
| STVARV → `ZPP_FORECAST_MTART` rows FERT, HAWA | Already there for Adhesive; applies to Paints too |

## 5. Then

Run the test handover (`docs/ZFORECAST_Paints_Test_Handover.docx`). The saved Paints
forecasts are in `ZPPT_PNT_FCST_YR`, `ZPPT_PNT_FCST_QT`, `ZPPT_PNT_FCST_MN`; the shared
`ZPPT_FCST_YR` / `_QT` / `_MN` rows are written as well, which is what the business-forecast
and change uploads, the engine and the final report read.
