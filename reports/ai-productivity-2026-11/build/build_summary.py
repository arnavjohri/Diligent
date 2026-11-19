"""Short report: exactly the 10 headings of Deliverable 1; detail stays in the Excel register.
python3 -I build_summary.py  -> data/summary.json   (render with render_docx.js)
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_combined as C  # noqa: E402  (also refreshes combined.json and the mail draft)

S, BP, ROWS, J, AT, M = C.S, C.BP, C.ROWS, C.J, C.AT, C.M
h, pc, md, short, p, bullets = C.h, C.pc, C.md, C.short, C.p, C.bullets


def compact(rows, caption):
    return dict(t="table", caption=caption, fontSize=7.5, widths=[7, 47, 16, 10, 10, 10], numeric=[3, 4, 5],
                header=["Sr.", "Development / use case", "Type", "Without AI (h)", "With AI (h)", "Saved (h)"],
                rows=[[o["id"], short(o["title"], 95), o["dev_type"], h(o["baseline_h"]), h(o["actual_h"]), h(o["saved_h"])] for o in rows])


def project(num, name, intro):
    rows = C.rows_of(name)
    return [dict(t="h1", text=f"{num}. {name} Project - Detailed AI Use Cases"), p(C.proj_line(name)), p(intro),
            C.highlights(rows, 3), compact(rows, f"{name} - all AI use cases (full detail in the Excel register)")]


auto_short = dict(t="table", caption="Automation solutions and reusable tools", fontSize=7.5, widths=[8, 62, 30],
                  header=["Sr.", "Automation / tool", "Project"], rows=[[o["id"], short(o["title"], 110), o["project"]] for o in C.autos])
blocks = [
    dict(t="cover", kicker="MANAGEMENT SUBMISSION - AI ADOPTION AND QUANTIFIABLE PRODUCTIVITY BENEFITS IN SAP ABAP DELIVERY",
         title="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
         subtitle="Projects: PAL | ONGC (OVL) | T&G   -   Reporting cut-off date: 19 November 2026",
         lines=["**Prepared by:** Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global", "**Period:** 20 July - 19 November 2026",
                "**AI tool:** Claude Code (Anthropic)",
                "**Attachments:** AI_Use_Case_Register.xlsx (detailed register, dashboard, assumptions), AI_Success_Story_JIB_Status.pptx"]),
    dict(t="h1", text="1. Executive Summary", pageBreak=True), C.kpis,
    p(f"From 20 July to 19 November 2026 AI (Claude Code) was part of my daily SAP ABAP delivery on three concurrent projects. "
      f"**{S['n_counted']} AI-assisted developments were completed** - ONGC (OVL) {BP['ONGC (OVL)']['n']}, T&G {BP['T&G']['n']}, PAL {BP['PAL']['n']} and "
      f"{BP['Common (all projects)']['n']} common tools - with **{C.COMMITS} commits in under four months**, "
      f"{M['Lines of ABAP / CDS / script code added in AI commits']:,} lines of code and {M['Distinct custom (Z/Y) SAP objects named in those use cases']} custom SAP objects."),
    p(f"The same scope needs {h(S['baseline'])} h conventionally; it took {h(S['actual'])} h with AI - **{md(S['saved'])} man-days saved, a {pc(S['red'])} effort reduction**."),
    C.proj_summary(),
    dict(t="h1", text="2. Scope and Sources Reviewed"),
    bullets(["Every object folder of the work repository for PAL, ONGC (OVL), T&G and common tools, with its issue log and technical notes.",
             f"Git history of 66 branches: {C.COMMITS} commits, 19/08 - 19/11/26; Claude Code session records 20/07 - 15/08/26 (30 sessions, 557 prompts).",
             "The August OVL work log, ATC exports, manual review list, ATC knowledge base and handover, FS / TS documents and client feedback."]),
    *project(3, "PAL", "FI-AR forms and e-mail, journal-entry and invoice upload tiles, FB70 credit-memo approval workflow, Ariba PO integration, SD-FI texts."),
    *project(4, "ONGC (OVL)", "ATC remediation; CDS / RAP Management Dashboard analytics; DPR Fiori dashboard and CPI interface; Group Reporting; FI / JVA posting and "
                              "reconciliation; MM enhancements and Fiori tiles; root-cause analysis of production and Mock-2 issues."),
    *project(5, "T&G", "Astral Limited / Project UDAY via KPMG: ZFORECAST Adhesive and Paints, Exceptional Approval (141 A/B), Clause 34 TDS (337), PO budget (050), "
                       "BP mail (057), CC MIS (147), MB5B amounts (195), vendor upload (FSD 30), Scheme (Pipes)."),
    dict(t="h1", text="6. ATC Correction and Code Optimisation Summary"),
    p(f"ATC S/4HANA-readiness remediation for ONGC: {h(AT['baseline_h'])} h conventional vs {h(AT['actual_h'])} h with AI - **{h(AT['saved_h'])} h saved ({pc(AT['red'])})**."),
    C.atc_funnel,
    bullets(["Findings resolved: SELECT SINGLE without unique key (NOORDER), field-length extension, simplified objects (BSEG, KONV, VBUK / VBUP, J_1IMOVEND), "
             "CLIENT SPECIFIED on compatibility views, strict Open SQL, pseudo-comments with SAP notes.",
             "Code optimisation beyond ATC: FOR ALL ENTRIES with implicit DISTINCT replaced by ranges (ZFITAX_PBT_CALC_PRG), BDC on dead S/4 transactions replaced "
             "by FI-AA BAPIs (ZAA_IMPAIRMENTLOSS), guarded FOR ALL ENTRIES and aggregation on the database."]),
    dict(t="h1", text="7. Automation and Reusable Development Summary"),
    p(f"{len(C.autos)} automations and reusable tools: user-facing (daily BP mail, mass uploads, approval workflow, period-end revaluation, JV alignment postings) "
      "and developer-facing (source mass download, enhancement finder, ICF URL list, ST05 decoder, the AI delivery toolkit with 76 ATC patterns and 56 release constraints)."),
    auto_short,
    dict(t="h1", text="8. Quantified Effort and Productivity Analysis"),
    p(f"Effort without AI {h(S['baseline'])} h; with AI {h(S['actual'])} h; saved {h(S['saved'])} h = {md(S['saved'])} man-days; reduction {pc(S['red'])}; "
      f"productivity improvement {S['prod'] * 100:.0f}%. Saved = without - with; reduction = saved / without; man-days = saved / 8. "
      "Conventional effort comes from a baseline by work type and complexity; AI-assisted effort counts the full development time of the period, "
      "distributed by measured session time per object. The formula-driven calculation is in the Excel register."),
    C.dash, C.top10,
    dict(t="h1", text="9. Customer Benefits"),
    bullets([f"Capacity released: {md(S['saved'])} man-days in four months, used to carry three projects concurrently.",
             "Faster delivery: working versions typically within a working day; earlier functional testing.",
             "Reusable assets: ATC correction patterns, release constraints, forecast engine, workflow class and analytical cube patterns, five developer tools.",
             "Potential effort value = man-days saved x applicable day rate (margin and capacity under fixed price; per the billing arrangement under T&M)."]),
    dict(t="h1", text="10. Overall Conclusions"),
    p(f"**Success story - ONGC Videsh JIB Status dashboard:** eight CDS views with an analytical cube, from requirement (03/11/26) to written client confirmation "
      f"(17/11/26) in 11 working days; {h(J['baseline_h'])} h conventional delivered in {h(J['actual_h'])} h ({pc(J['red'])} reduction). Details in the attached deck."),
    bullets([f"AI is part of daily delivery: {S['n_counted']} completed use cases and {C.COMMITS} commits in under four months across PAL, ONGC and T&G.",
             f"{md(S['saved'])} man-days saved ({pc(S['red'])}) with human control at every step: fresh source download, activation feedback, functional confirmation.",
             "Next steps: share the AI delivery toolkit with the team, extend the dashboard pattern, apply the ATC patterns to the next remediation wave, log effort per object."]),
]
doc = dict(title="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
           header="SAP ABAP AI utilisation report | PAL | ONGC (OVL) | T&G | 19 November 2026",
           footer="Prepared by Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri",
           sections=[dict(noHeader=True, blocks=blocks)])
json.dump(doc, open(os.path.join(C.D, "summary.json"), "w"), indent=1)
print("ok")
