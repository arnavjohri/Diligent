"""Short report under the 10 headings of Deliverable 1. Each figure appears once.
python3 -I build_summary.py  -> data/summary.json   (render with render_docx.js)
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_combined as C  # noqa: E402  (also refreshes combined.json and the mail draft)

S, BP, J, M = C.S, C.BP, C.J, C.M
h, pc, md, short, p, bullets = C.h, C.pc, C.md, C.short, C.p, C.bullets
peak = next(m for m in C.U["metrics"] if m[0].startswith("Peak day"))


def table(name):
    rows = C.rows_of(name)
    body = [[o["id"], short(o["title"], 92), o["dev_type"], h(o["baseline_h"]), h(o["actual_h"]), h(o["saved_h"])] for o in rows]
    body.append(["", f"Total - {len(rows)} use cases", "", h(sum(o["baseline_h"] for o in rows)), h(sum(o["actual_h"] for o in rows)),
                 h(sum(o["saved_h"] for o in rows))])
    return dict(t="table", fontSize=7.5, widths=[7, 51, 15, 9, 9, 9], numeric=[3, 4, 5], totalRow=True,
                header=["Sr.", "Development / use case", "Type", "Without AI (h)", "With AI (h)", "Saved (h)"], rows=body)


blocks = [
    dict(t="p", text="MANAGEMENT SUBMISSION - AI ADOPTION AND PRODUCTIVITY IN SAP ABAP DELIVERY", bold=True, color="0B5C6B", size=18, after=60),
    dict(t="p", text="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report", bold=True, size=34, after=60),
    p("Projects: PAL | ONGC (OVL) | T&G  -  Period 20 July - 19 November 2026  -  Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global  -  "
      "AI tool: Claude Code (Anthropic)", size=18, color="5B6B7A", after=200),

    dict(t="h1", text="1. Executive Summary"),
    dict(t="kpis", items=[
        dict(value=str(S["n_counted"]), label="AI-assisted use cases", note="all completed"),
        dict(value=str(C.COMMITS), label="Commits", note="in under four months"),
        dict(value=md(S["saved"]), label="Man-days saved", note=f"{h(S['actual'])} h worked with AI"),
        dict(value=pc(S["red"]), label="Effort reduction", note="weighted by hours")]),
    p(f"AI was part of my daily SAP ABAP work on three projects at the same time. I completed {S['n_counted']} AI-assisted developments: "
      f"{BP['ONGC (OVL)']['n']} for ONGC, {BP['T&G']['n']} for T&G, {BP['PAL']['n']} for PAL and {BP['Common (all projects)']['n']} common tools. "
      "They include full applications (CDS / RAP dashboards, an approval workflow, forecasting), reports, interfaces, enhancements, ATC remediation of "
      "51 program includes and root-cause analysis of production issues."),
    p(f"I worked {M['Active days with AI-assisted commits (19/08 - 19/11/26)']} active days in the repository period, including "
      f"{M['Weekend days with AI-assisted work']} weekend days. On {M['Days with 8+ hours between first and last commit']} days the work ran 8 hours or more "
      f"from the first commit to the last, and the busiest day ({peak[0].split('(')[1].split(')')[0]}) had {peak[1]} commits, {peak[2]}. "
      f"Output: {M['Lines of ABAP / CDS / script code added in AI commits']:,} lines of code, {M['Distinct custom (Z/Y) SAP objects named in those use cases']} custom objects "
      f"and {M['Technical specification files produced']} technical specifications."),
    p(f"**Strongest example:** ONGC Videsh JIB Status management dashboard. Eight CDS views and an analytical cube went from requirement (03/11/26) to written "
      f"client confirmation (17/11/26) in 11 working days, at {pc(J['red'])} less effort."),

    dict(t="h1", text="2. Scope and Sources Reviewed"),
    bullets([f"Every object folder of my work repository, with its issue log (issue, cause, fix) and technical notes; git history of all branches ({C.COMMITS} commits).",
             "Claude Code session records (30 sessions, 557 prompts, 20/07 - 15/08/26), the August OVL work log, ATC exports and handover, FS / TS documents and client feedback."]),

    dict(t="h1", text="3. PAL Project - Detailed AI Use Cases"),
    p("FI-AR forms and e-mail, journal-entry and invoice upload tiles, FB70 credit-memo approval workflow, Ariba PO integration and SD-FI texts."),
    table("PAL"),
    dict(t="h1", text="4. ONGC (OVL) Project - Detailed AI Use Cases"),
    p("ATC remediation, CDS / RAP Management Dashboard analytics, DPR Fiori dashboard and CPI interface, Group Reporting, FI / JVA posting and reconciliation, "
      "MM enhancements and Fiori tiles, root-cause analysis of production and Mock-2 issues."),
    table("ONGC (OVL)"),
    dict(t="h1", text="5. T&G Project - Detailed AI Use Cases"),
    p("Astral Limited / Project UDAY through KPMG: forecasting (Adhesive, Paints), exceptional approval, Clause 34 TDS, PO budget control, BP mail, MB5B amounts, "
      "vendor upload, scheme and MIS."),
    table("T&G"),
    table("Common (all projects)"),

    dict(t="h1", text="6. ATC Correction and Code Optimisation Summary"),
    dict(t="table", widths=[60, 12, 28], numeric=[1], header=["ATC remediation (ONGC)", "Count", "Detail"],
         rows=[["ATC findings assigned and remediated", "847", "05 - 14/08/26"],
               ["Program includes corrected", "51", "43 programs, 14 packages"],
               ["AI-assisted correction blocks applied", "205", "833 lines added or changed"],
               ["Findings routed for senior / functional decision", "26", "manual review list"],
               ["Reusable correction patterns documented", str(C.ATC["reusable_patterns_count"]), "knowledge base and rules"]]),
    p("Finding types: SELECT SINGLE without a unique key, field-length extension, simplified objects (BSEG, KONV, VBUK / VBUP, J_1IMOVEND), CLIENT SPECIFIED on "
      "compatibility views, strict Open SQL. Optimisation beyond ATC: FOR ALL ENTRIES replaced by ranges where it lost rows, batch input on dead S/4 transactions "
      "replaced by BAPIs, aggregation moved to the database."),

    dict(t="h1", text="7. Automation and Reusable Development Summary"),
    p(f"{len(C.autos)} automations and tools. For users: daily BP-creation mail, mass uploads (forecast, exceptional approval, timesheet rows, JV alignment), the "
      "credit-memo approval workflow and period-end bank revaluation. For developers: source mass download, enhancement finder, ICF URL list, ST05 trace decoder "
      "and the AI delivery toolkit (7 workflow skills, 56 recorded release constraints, 76 ATC patterns)."),

    dict(t="h1", text="8. Quantified Effort and Productivity Analysis"),
    C.dash,
    p("Effort without AI comes from a conservative baseline by work type and complexity. Actual effort with AI counts all my working time in the period, weekends "
      "included, spread over the developments by measured session time and size. Saved = without minus with; man-days = saved / 8. The workings are in the Excel register.",
      size=18),

    dict(t="h1", text="9. Customer Benefits"),
    bullets(["Capacity released to carry three projects in parallel, alongside production support.",
             "Earlier testing: most developments reached a first working version within a working day.",
             "Reusable assets for the team: ATC patterns, release constraints, forecast engine, workflow and analytical-cube patterns, developer tools."]),

    dict(t="h1", text="10. Overall Conclusions"),
    bullets(["AI is now part of how I deliver: faster first builds and faster root-cause analysis, with every object reviewed, activated and tested by me before go-live.",
             "Next steps: share the AI delivery toolkit with the team, reuse the dashboard pattern for further cards, and apply the ATC patterns to the next remediation wave.",
             "Attached: AI_Use_Case_Register.xlsx (full register, dashboard, assumptions) and AI_Success_Story_JIB_Status.pptx (case study)."]),
]
doc = dict(title="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
           header="SAP ABAP AI utilisation report | PAL | ONGC (OVL) | T&G | 19 November 2026",
           footer="Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri",
           sections=[dict(blocks=blocks)])
json.dump(doc, open(os.path.join(C.D, "summary.json"), "w"), indent=1)
print("ok")
