# AI utilisation and productivity report — cut-off 19/11/26

Management submission on AI-assisted SAP ABAP delivery (Claude Code), 20/07/26 – 19/11/26.

| File | Deliverable |
|---|---|
| `AI_Utilisation_Productivity_Report.docx` | 1 — project-wise assessment (39 pages; open in Word and accept *update fields* to fill the contents page) |
| `AI_Use_Case_Register.xlsx` | 2 — register with live formulas: Dashboard, Master Register, PAL, ONGC (OVL), T&G, KPMG - Astral (UDAY), ATC, Automation, Assumptions, AI Usage, Evidence & Gaps, Attribution Pending |
| `Management_Summary_Email.md` | 3 — mail draft to the manager (sending stays manual) |
| `AI_Success_Story_JIB_Status.pptx` | 4 — 7-slide case study, ONGC Videsh JIB Status dashboard |
| `Evidence_and_Estimation_Annexure.docx` | 5 — traceability per use case |

## Headline (estimates)

70 counted use cases · 2,954 h conventional vs 587 h with AI · 2,367 h / 296 man-days saved · 80% weighted
reduction · 180 man-days of it on work confirmed in the system. At 50% lower baselines: 111 man-days (60%).

## Things to settle before sending

- **T&G** is not named anywhere in the repository. The Astral / Project UDAY (KPMG) work is its own bucket.
  If that is T&G: set `Effort Assumptions` row *Astral* column C to `T&G` in the workbook, and
  `PROJECT_MAP["ASTRAL"]` in `build/build_data.py`, then rebuild the documents (below).
- 32 tier-B items have no activation / test entry in their ISSUES.md — each confirmed one moves to tier A.
- `Dear [Manager name]` in the mail draft.

## Rebuild

```
cd reports/ai-productivity-2026-11/build
python3 -I build_data.py && python3 -I build_usage.py && python3 -I build_xlsx.py ../AI_Use_Case_Register.xlsx
python3 -I build_docs.py
NODE_PATH=<global node_modules with docx> node render_docx.js data/report.json ../AI_Utilisation_Productivity_Report.docx
NODE_PATH=<global node_modules with docx> node render_docx.js data/annexure.json ../Evidence_and_Estimation_Annexure.docx
NODE_PATH=<node_modules with pptxgenjs, react-icons, react-dom, sharp> node build_pptx.js $PWD/../AI_Success_Story_JIB_Status.pptx <pptx skill>/scripts/apply_theme.js
```

`build/data/inv_*.json` are the per-folder evidence inventories (read from every ISSUES.md / NOTES.md);
`gitstats.json` is the commit-timestamp work-block measure (`gitstats.py`). After `build_xlsx.py`, open the
workbook once in Excel (or recalculate with LibreOffice) so the formula results are cached.
