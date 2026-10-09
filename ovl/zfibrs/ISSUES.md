# ovl/zfibrs — issue log

| Date | Issue | Cause | Fix | TR |
|---|---|---|---|---|
| 09.10.2026 | "Inconsistent header in file C:\SAPPC\bankbook.txt" + "Run Validation Module First"; GUI_UPLOAD sy-subrc 1 | FILE_OPEN_ERROR — file never opened (file itself checked clean: 115 lines × 16 cols, CRLF, ASCII). Likely WebGUI / wrong name / file locked. | No code change. Run from SAP GUI desktop, close file, check exact name. Upload template supplied. | — |
