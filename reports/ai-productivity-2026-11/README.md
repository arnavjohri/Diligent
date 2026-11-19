# AI utilisation and productivity report — cut-off 19/11/26

Management submission on AI-assisted SAP ABAP delivery (Claude Code), 20/07/26 – 19/11/26.
Projects: PAL | ONGC (OVL) | T&G (Astral Ltd / Project UDAY via KPMG).

| File | Deliverable |
|---|---|
| `AI_Utilisation_Report.docx` / `.pdf` | **Short report, 6 pages** — the 10 headings of Deliverable 1, each figure once; detail in the Excel register |
| `AI_Utilisation_Complete_Report.docx` / `.pdf` | Everything in one file — management summary, report under the manager's 16 headings, slide content, the full use-case register (Annex A), effort method, ATC register, evidence annexure (118 pages, reference copy) |
| `AI_Use_Case_Register.xlsx` | Register with live formulas: Dashboard, Master Register, PAL, ONGC (OVL), T&G, Common, ATC, Automation, Assumptions, AI Usage, Evidence |
| `AI_Success_Story_JIB_Status.pptx` | 7-slide case study — ONGC Videsh JIB Status dashboard |
| `Management_Summary_Email.md` | Mail draft (sending stays manual; fill in the manager's name) |

## Headline

74 AI-assisted use cases completed · 869 commits in under four months · 1,159 h conventional vs 705 h with AI ·
454 h / 57 man-days saved · 39% effort reduction. 6 weekend days and a 68-commit peak day (22/10) in the record.

## Rebuild

```
cd reports/ai-productivity-2026-11/build
python3 -I build_data.py && python3 -I build_usage.py && python3 -I build_xlsx.py ../AI_Use_Case_Register.xlsx
python3 -I build_combined.py && python3 -I build_summary.py
NODE_PATH=<global node_modules with docx> node render_docx.js data/summary.json ../AI_Utilisation_Report.docx
NODE_PATH=<global node_modules with docx> node render_docx.js data/combined.json ../AI_Utilisation_Complete_Report.docx
NODE_PATH=<node_modules with pptxgenjs, react-icons, react-dom, sharp> node build_pptx.js $PWD/../AI_Success_Story_JIB_Status.pptx <pptx skill>/scripts/apply_theme.js
```

Project mapping is `PROJECT_MAP` in `build/build_data.py` (and section 4 of the workbook's Effort Assumptions).
`build/data/inv_*.json` are the per-folder inventories read from every ISSUES.md / NOTES.md; `gitstats.json` is the
commit-timestamp work-block measure (`gitstats.py`). Open the workbook once in Excel so formula results are cached.
