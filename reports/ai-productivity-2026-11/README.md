# AI utilisation and productivity report — cut-off 19/11/26

Management submission on AI-assisted SAP ABAP delivery (Claude Code), 20/07/26 – 19/11/26.
Projects: PAL | ONGC (OVL) | Astral (KPMG).

| File | Deliverable |
|---|---|
| `AI_Utilisation_Report.docx` / `.pdf` | Deliverables 1 and 5 — report under the brief's headings (sections 1–14, 21 pages) plus Annex A use-case register, B ATC register, C effort calculation, D technical documentation, E evidence and estimation annexure (61 pages in all) |
| `AI_Use_Case_Register.xlsx` | Deliverable 2 — register with live formulas: Productivity Dashboard, Master Use Case Register, PAL / ONGC (OVL) / Astral (KPMG) Project Details, Common Tools Details, ATC Remediation Register, Automation Benefits Register, Effort Calc and Assumptions, AI Usage, Evidence References |
| `AI_Success_Story_JIB_Status.pptx` | Deliverable 4 — 7-slide success story: ONGC Videsh JIB Status dashboard, built in three working days, confirmed by the client in writing after their testing |
| `Management_Summary_Email.md` | Deliverable 3 — email-ready management summary / cover mail (fill in the manager's name; sending stays manual) |

## Headline

74 AI-assisted use cases (ONGC 51, Astral 12, PAL 6, common 5) · 865 commits in under four months ·
1,157 h conventional vs 699 h with AI (all working time, 6 weekend days included) ·
458 h / 57 man-days saved · 40% effort reduction.

Hours are identical in the Word tables and the workbook (one decimal); the workbook is the calculation of record.

## Rebuild

```
cd reports/ai-productivity-2026-11/build
python3 -I build_data.py && python3 -I build_usage.py
NODE_PATH=<node_modules with sharp> node make_charts.js
python3 -I build_report.py                      # writes data/report.json and ../Management_Summary_Email.md
NODE_PATH=<global node_modules with docx> node render_docx.js data/report.json ../AI_Utilisation_Report.docx
python3 -I fix_docx.py ../AI_Utilisation_Report.docx
python3 -I build_xlsx.py ../AI_Use_Case_Register.xlsx   # then recalculate once (LibreOffice or Excel)
NODE_PATH=<node_modules with pptxgenjs, react-icons, react-dom, sharp> node build_pptx.js $PWD/../AI_Success_Story_JIB_Status.pptx <pptx skill>/scripts/apply_theme.js
```

`build/data/inv_*.json` are the per-folder inventories read from every ISSUES.md / NOTES.md; `gitstats.json` is the
commit-timestamp work-block measure (`gitstats.py`). The use-case wording comes from `curated_ongc.json`,
`curated_rest.json` and `curated_own.json`; `automation.json`, `atc_patterns_clean.json` and `casestudy.json` feed the
automation table, Annex B and the success story. Commits that touch only `reports/` are excluded from every count,
so the figures do not move when this folder is rebuilt.
