# Issues — ZMM_RM07MLBD (tcode ZMM_MB5B_NEW)

Log format: date | issue | root cause | files changed | commit | TR

| Date | Issue | Root cause | Files changed | Commit | TR |
|---|---|---|---|---|---|
| 15/09/26 | Port ZMB5B receipt/issue amount (195_BRD_FS) into the existing custom tcode ZMM_MB5B_NEW so one report serves both | Standard fills SOLLWERT/HABENWERT/WAERS and the DMBTR detail column for valuated stock only | `ZMM_RM07MLBD.abap`, `ZMM_RM07MLBD_units.abap` (main program only; includes untouched) | ba15b56 | _tbc_ |
| 15/09/26 | Amounts blank in ZMM_MB5B_NEW after the port, fine in ZMB5B | Older-release copy lacks the standard's `gv_newdb = abap_false` (SAPSCORE) line; on HANA the BAdI stored-procedure path runs and skips `summen_bilden` / `bestaende_berechnen` / `zf_lgbst_wert_ergaenzen` | `ZMM_RM07MLBD.abap`, `ZMM_RM07MLBD_units.abap` (unit 11: `gv_newdb = abap_false` for LGBST) | _pending_ | _tbc_ |
