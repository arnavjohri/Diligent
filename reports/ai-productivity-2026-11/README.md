# AI utilisation and productivity report — cut-off 19/11/26

Management submission on AI-assisted SAP ABAP delivery (Claude Code), 20/07/26 – 19/11/26.
Projects: PAL | ONGC (OVL) | Astral (KPMG).

| File | Deliverable |
|---|---|
| `AI_Utilisation_Report.docx` / `.pdf` | Deliverables 1, 3 and 5 — report under the Deliverable-1 headings with timeline, charts, ATC correction examples and full case study, plus Annex A use-case register, B ATC register, C effort calculation, D technical documentation, E evidence and estimation annexure (66 pages) |
| `AI_Use_Case_Register.xlsx` | Deliverable 2 — register with live formulas: Dashboard, Master Register, PAL, ONGC (OVL), Astral (KPMG), Common, ATC, Automation, Assumptions, AI Usage, Evidence |
| `AI_Success_Story_JIB_Status.pptx` | Deliverable 4 — 7-slide case study — ONGC Videsh JIB Status dashboard |
| `Management_Summary_Email.md` | Deliverable 3 — cover mail with the email-ready summary (fill in the manager's name; sending stays manual) |

## Headline

74 AI-assisted use cases · 870 commits in under four months · 1,159 h conventional vs 705 h with AI (all working time,
6 weekend days included) · 454 h / 57 man-days saved · 39% effort reduction.

## Rebuild

```
cd reports/ai-productivity-2026-11/build
python3 -I build_data.py && python3 -I build_usage.py && python3 -I build_xlsx.py ../AI_Use_Case_Register.xlsx
NODE_PATH=<node_modules with sharp> node make_charts.js
python3 -I build_report.py
NODE_PATH=<global node_modules with docx> node render_docx.js data/report.json ../AI_Utilisation_Report.docx
NODE_PATH=<node_modules with pptxgenjs, react-icons, react-dom, sharp> node build_pptx.js $PWD/../AI_Success_Story_JIB_Status.pptx <pptx skill>/scripts/apply_theme.js
```

`build/data/inv_*.json` are the per-folder inventories read from every ISSUES.md / NOTES.md; `gitstats.json` is the
commit-timestamp work-block measure (`gitstats.py`). Open the workbook once in Excel so formula results are cached.
