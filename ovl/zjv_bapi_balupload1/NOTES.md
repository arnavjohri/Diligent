# ZJV_BAPI_BALUPLOAD1 — JV general ledger balances upload (OVL)

- Tcode `ZJVBALUPLOAD1`. Reads a tab-separated file via `GUI_UPLOAD` into `IST_GL`, posts with `BAPI_ACC_DOCUMENT_POST`.
- Sister program `ZJV_BAPI_BALUPLOAD1_MON` (monthly variant, also handles the JIB provision path via memory ID `ZJIB_PROV`). Its `IST_GL` is the reference for the 33-column upload layout.
- Ships by **paste** (uses `SET PF-STATUS 'STATUS'` / `'STATUS1'`, an SE41 status, so not ZIP-able).
- `original/` is the SE80 download Arnav pasted on 14/10/26; the loose `.abap` at this folder root is the corrected copy.
- Gotcha: `IST_GL` and the upload file are matched by column position, not name. Any new column in the template needs a field at the same index in `IST_GL`.
