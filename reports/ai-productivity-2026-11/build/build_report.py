"""The management report (about 15 pages): Deliverable-1 headings, no figure repeated.
python3 -I build_report.py  -> data/report.json, ../Management_Summary_Email.md   (render with render_docx.js)
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "data")
R = json.load(open(os.path.join(D, "register.json")))
U = json.load(open(os.path.join(D, "usage.json")))
ATC = json.load(open(os.path.join(D, "inv_atc.json")))
S, ROWS = R["summary"], R["rows"]
M = {m[0]: m[1] for m in U["metrics"]}
BP = S["by_project"]
J = next(o for o in ROWS if o["folder"] == "ovl/zfi_jib_status")
AT = next(o for o in ROWS if o["work"] == "ATC")
P3 = ["PAL", "ONGC (OVL)", "Astral (KPMG)"]
ALL = P3 + ["Common (all projects)"]
COMMITS = M["Total commits in the repository, 19/08 - 19/11/26 (all branches)"]
PEAK = next(m for m in U["metrics"] if m[0].startswith("Peak day"))
autos = [o for o in ROWS if o["automation"] or o["work"] == "TOOL"]
h = lambda x: f"{x:,.0f}"
pc = lambda x: f"{x * 100:.0f}%"
md = lambda x: f"{x / 8:,.0f}"
rows_of = lambda p: [o for o in ROWS if o["project"] == p]


def short(t, n):
    t = str(t or "")
    if len(t) <= n:
        return t
    c = t[:n]
    k = c.rfind(". ")
    return c[: k + 1] if k > n * 0.5 else c.rsplit(" ", 1)[0] + "..."


p = lambda text, **k: dict(t="p", text=text, **k)
bl = lambda items, **k: dict(t="bullets", items=items, **k)
BREAK = ("3.", "4.", "5.", "6.", "8.", "10.", "13.")
h1 = lambda text: dict(t="h1", text=text, pageBreak=text.startswith(BREAK))
h3 = lambda text: dict(t="h3", text=text)


KEYED = {"ovl/zfi_jib_status", "ovl/atc"}


def key_items(rows, n, skip=()):
    out = []
    for o in sorted([o for o in rows if o["folder"] not in skip], key=lambda o: -o["saved_h"])[:n]:
        KEYED.add(o["folder"])
        out += [h3(o["title"].split(" - ")[0] if len(o["title"]) > 70 else o["title"]),
                p(f"**Problem.** {short(o['requirement'], 260)}", after=60),
                p(f"**What AI did.** {short(o['ai'], 330)}", after=60),
                p(f"**Result.** {o['status']}; {short(o['quality'] or 'delivered to the project coding standard', 200)}", after=140)]
    return out


def uc_table(name):
    rows = rows_of(name)
    body = [[o["id"], short(o["title"], 88), o["dev_type"], h(o["baseline_h"]), h(o["actual_h"]), h(o["saved_h"])] for o in rows]
    body.append(["", f"Total - {len(rows)} use cases", "", h(BP[name]["baseline"]), h(BP[name]["actual"]), h(BP[name]["saved"])])
    return dict(t="table", fontSize=7.5, widths=[7, 51, 15, 9, 9, 9], numeric=[3, 4, 5], totalRow=True,
                caption=f"{name} - all AI use cases",
                header=["Sr.", "Development / use case", "Type", "Without AI (h)", "With AI (h)", "Saved (h)"], rows=body)


# ------------------------------------------------------------------ mail draft
mail = f"""Subject: AI Utilisation Report - SAP ABAP Delivery (PAL, ONGC (OVL), Astral (KPMG))

Dear [Manager name],

Please find attached my AI utilisation report for SAP ABAP delivery across PAL, ONGC (OVL) and Astral (KPMG), covering July to November 2026, along with the detailed use-case register and the success-story deck.

In brief: {S['n_counted']} AI-assisted developments completed, {COMMITS} commits, and about {md(S['saved'])} man-days saved ({pc(S['red'])} effort reduction).

Kindly review and let me know if you need any further detail.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
"""
open(os.path.join(HERE, "..", "Management_Summary_Email.md"), "w").write(mail)

# ------------------------------------------------------------------ sections
cats = {}
for o in ROWS:
    cats.setdefault(o["category"], []).append(o)
KEEP = ("Total commits", "Working days", "Weekend days", "Peak day", "Days with 8+", "Commits made after", "Active days", "Claude Code sessions",
        "Prompts", "Lines of ABAP", "Lines of documentation", "Distinct custom", "Technical specification", "Issue-log")
usage_rows = [m for m in U["metrics"] if m[0].startswith(KEEP)]
workflow = [
    "**Intake** - issue mail, FS or change request triaged into a queue.",
    "**Fresh source** - current version downloaded from SAP (ZR_PROG_DOWNLOAD / SE80) and compared with the last copy, so no one else's change is lost.",
    "**AI build or diagnosis** - Claude Code reads the source, the dump or the trace and writes the corrected or new object, with change markers and the old code kept commented.",
    "**Activation and test** - I paste or import the object, activate it, feed activation errors back, and test with the functional consultant.",
    "**Record** - issue, cause and fix logged per object and committed, so every change is traceable.",
]
quality = [
    ("Development efficiency", ["Working versions the same or next working day - ZMM_BP_CREATE_MAIL built and activated on first paste the day the FS answers arrived; Paints forecast from FS (19/10) to active (22/10).",
                                "Reuse instead of rework - forecast engine reused for Paints, GL workflow class reused for the FB70 workflow, MB5B amount logic ported to ZMM_MB5B_NEW."]),
    ("Debugging and problem resolution", ["ZMM_TMS_STATUS blank Excel export traced to one constant on 44 columns - fixed and confirmed the same day.",
                                          "CJ88 and FBV0 posting errors proven to sit in SAP standard from ST22 / SM13 / ST05 evidence - no custom code touched; PAL INC01967 unreadable PDFs traced to the encryption round trip and closed."]),
    ("Code quality", ["S/4HANA-compatible code: BDC on dead transactions replaced by BAPIs, strict Open SQL, released CDS views, guarded FOR ALL ENTRIES.",
                      "No modification of SAP standard - released BAdIs, enhancements calling Z classes, CDS extensions; error paths give a message instead of a dump."]),
    ("Documentation and knowledge transfer", [f"{M['Issue-log entries written (issue -> cause -> fix)']} issue-log entries and a notes file per object; {M['Technical specification files produced']} technical specifications in client templates.",
                                              "FS gaps raised before build - 16 questions for WRICEF 141, 21 for WRICEF 147, 28 points on the Paints FS - fewer change cycles later."]),
    ("Project delivery", ["Three projects handled in parallel with production support; functional testing started earlier on most developments.",
                          f"{M['Review corrections applied to AI output before go-live']} review corrections applied to AI output before go-live; 56 recorded release constraints applied to every new object."]),
]
case_rows = [
    ["Project", "ONGC Videsh Ltd (OVL)"],
    ["Development and SAP objects", "Management Dashboard 'JIB Status' - ZFI_JIB_STATUS: cube ZI_JIB_STATUS_CUBE with seven supporting CDS views"],
    ["Business requirement", "For every joint venture: is the period's JIB posted and when was it entered, by month, quarter or fiscal year, with document drill-down, as a Fiori Custom Analytical Query."],
    ["Technical complexity", "No venture on the document header; JIB identified by document type from a GS01 set; reversals; empty months shown as Pending; older S/4 CDS release; delivery by abapGit ZIP."],
    ["Conventional approach", "SE16N data analysis, view-by-view design by trial activation, a rebuild after each client test."],
    ["How AI was used", "Read the requirement workbook and production samples, designed the data model, wrote all eight views and the ZIP, rebuilt the model on each round of client feedback."],
    ["Human review and validation", "Document-type set confirmed in GS03 / SE16N; each version imported, activated and checked against production documents; client tests relayed; launchpad navigation set."],
    ["Timeline", "Requirement 03/11/26 -> first query running 04/11 -> client test 06/11 -> navigation 12/11 -> written client confirmation 17/11 (11 working days, four additions included)."],
    ["Effort", f"{h(J['baseline_h'])} h conventional -> {h(J['actual_h'])} h with AI: {h(J['saved_h'])} h saved, {pc(J['red'])} less effort."],
    ["Client feedback", "Corporate Accounts, 17/11/26: 'working well and meeting expectations'."],
    ["Replication", "The same cube pattern now serves Bank Revaluation, the Treasury bank register and Per-Barrel analysis."],
]

blocks = [
    # cover + 1
    p("MANAGEMENT SUBMISSION  |  AI ADOPTION IN SAP ABAP DELIVERY", bold=True, color="0B5C6B", size=18, after=40),
    p("SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report", bold=True, size=36, after=60),
    p("PAL  |  ONGC (OVL)  |  Astral (KPMG)      20 July - 19 November 2026      Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global",
      size=18, color="5B6B7A", after=240),
    dict(t="h1", text="1. Executive Summary"),
    dict(t="kpis", items=[dict(value=str(S["n_counted"]), label="AI-assisted use cases", note="completed across 3 projects"),
                          dict(value=f"{COMMITS}", label="Commits", note="in under four months"),
                          dict(value=md(S["saved"]), label="Man-days saved", note="conventional vs AI-assisted"),
                          dict(value=pc(S["red"]), label="Effort reduction", note="weighted by hours")]),
    p("From July to November 2026 AI (Claude Code) became part of my daily SAP ABAP delivery on three projects running at the same time: PAL, "
      "ONGC Videsh (OVL) and Astral through KPMG. It covered the full cycle - reading FS documents and legacy code, building new objects, correcting "
      "existing ones, ATC remediation, root-cause analysis of production dumps and writing technical specifications."),
    p(f"The result is a body of work that would normally take a larger team: complete applications (CDS / RAP dashboards, an approval workflow, a forecasting "
      f"system), reports, interfaces, enhancements and tools - {M['Distinct custom (Z/Y) SAP objects named in those use cases']} custom SAP objects in all. "
      f"Every object was reviewed, activated and tested by me before go-live."),
    dict(t="table", caption="At a glance", widths=[18, 10, 72], header=["Project", "Use cases", "What was delivered"], numeric=[1],
         rows=[["ONGC (OVL)", str(BP["ONGC (OVL)"]["n"]), "Management Dashboard analytics (JIB status, bank revaluation, treasury, per-barrel), DPR Fiori dashboard and CPI interface, ATC remediation, FI / JVA programs, Group Reporting, MM enhancements"],
               ["Astral (KPMG)", str(BP["Astral (KPMG)"]["n"]), "ZFORECAST Adhesive and Paints, Exceptional Approval (141 A/B), Clause 34 TDS, PO budget control, BP-creation mail, MB5B amounts, vendor upload, Scheme"],
               ["PAL", str(BP["PAL"]["n"]), "FB70 credit-memo approval workflow, journal-entry and invoice upload fixes, invoice forms and e-mail, Ariba PO integration, SD-FI texts"],
               ["Common", str(BP["Common (all projects)"]["n"]), "AI delivery toolkit and developer tools used on every project"]]),

    h1("2. Scope and Sources Reviewed"),
    bl(["My work repository - one folder per SAP object for each project, with its issue log (issue, cause, fix), technical notes and delivered source.",
        f"Git history of every branch - {COMMITS} commits between 19/08 and 19/11/26 - and Claude Code session records from 20/07/26 (30 sessions, 557 prompts).",
        "The August OVL work log, ATC exports and knowledge base, FS and TS documents, client test feedback and mail threads."]),
    h1("3. How AI Was Used in Daily Delivery"),
    p("The same five-step loop ran on every project:"),
    dict(t="numbered", items=workflow),
    dict(t="table", caption="AI utilisation and working pattern", widths=[56, 14, 50], header=["Measure", "Value", "Basis"],
         rows=[[m[0], f"{m[1]:,}" if isinstance(m[1], (int, float)) else str(m[1]), m[2]] for m in usage_rows]),
    dict(t="image", path=os.path.join(HERE, "charts", "monthly_activity.png"), w=600, h=240, alt="Commits per month",
         caption="Output grew month on month as the toolkit matured; October was the peak with 329 commits on client work."),

    h1("4. PAL Project - Detailed AI Use Cases"),
    p("Philippine Airlines, systems DS4 -> QS4 -> PS4: finance and purchasing fixes and one new workflow, mostly raised as incidents (INC01192, INC01740, INC01967)."),
    *key_items(rows_of("PAL"), 3), uc_table("PAL"),
    h1("5. ONGC (OVL) Project - Detailed AI Use Cases"),
    p("ONGC Videsh, ECC to S/4HANA (OCD / OCQ / OCP): the largest share of the work - new analytics on CDS for the Management Dashboard, the DPR application, "
      "ATC remediation (section 8), FI / JVA posting and reconciliation programs, and root-cause analysis of production and Mock-2 issues."),
    *key_items(rows_of("ONGC (OVL)"), 4, skip=("ovl/atc", "ovl/zfi_jib_status")), uc_table("ONGC (OVL)"),
    h1("6. Astral (KPMG) Project - Detailed AI Use Cases"),
    p("Astral Limited, Project UDAY, delivered through KPMG: new developments from FS documents across PP, SD, FI and MM (WRICEFs ID-2A / ID-2B, 141, 337, 050, 057, 147, 195)."),
    *key_items(rows_of("Astral (KPMG)"), 3), uc_table("Astral (KPMG)"),

    h1("7. Technical Classification of AI Use Cases"),
    dict(t="table", widths=[30, 10, 60], numeric=[1], header=["Category", "Use cases", "Examples"],
         rows=[[k, str(len(v)), "; ".join(short(o["title"].split(" - ")[0].split(":")[0], 40) for o in v[:3])]
               for k, v in sorted(cats.items(), key=lambda kv: -len(kv[1]))]),
    h1("8. ATC Correction and Code Optimisation Summary"),
    p(f"ATC S/4HANA-readiness remediation for ONGC was worked family by family, so each correction pattern was derived once and reused across the batch "
      f"({h(AT['baseline_h'])} h conventional, {h(AT['actual_h'])} h with AI)."),
    dict(t="table", widths=[60, 12, 28], numeric=[1], header=["Stage", "Count", "Detail"],
         rows=[["ATC findings assigned and remediated", "847", "05 - 14/08/26"], ["Program includes corrected", "51", "43 programs, 14 packages"],
               ["Correction blocks applied", "205", "833 lines added or changed"], ["Findings routed for decision", "26", "manual review list"],
               ["Reusable correction patterns", str(ATC["reusable_patterns_count"]), "knowledge base and rules"]]),
    dict(t="table", caption="Main finding types and the correction applied", fontSize=7.5, widths=[34, 66], header=["Finding type", "Correction"],
         rows=[[x["category"], short(str(x.get("typical_fix", "")), 170)] for x in ATC["finding_categories_resolved"]
               if any(k in x["category"] for k in ("SELECT SINGLE", "BINARY SEARCH", "Field Length Extension - conflict", "VBUK", "KONV", "BSEG",
                                                   "J_1IMOVEND", "CLIENT SPECIFIED", "Strict Open SQL", "FOR ALL ENTRIES guard", "BDC", "Native SQL"))]),
    p("Optimisation beyond ATC: FOR ALL ENTRIES replaced by ranges where it silently lost rows (ZFITAX_PBT_CALC_PRG), batch input on dead S/4 transactions "
      "replaced by FI-AA BAPIs (ZAA_IMPAIRMENTLOSS), totals aggregated on the database instead of line by line (ZFI_ACDOCA_JVSO1_RECON)."),
    h1("9. Automation and Reusable Development Summary"),
    dict(t="table", fontSize=7.5, widths=[34, 16, 50], header=["Automation / tool", "Project", "Manual work it replaces"],
         rows=[[short(o["title"].split(" - ")[0], 60), o["project"].replace("Common (all projects)", "Common"), short(o["auto_process"] or o["requirement"], 150)] for o in autos]),

    h1("10. Quantified Effort and Productivity Analysis"),
    dict(t="image", path=os.path.join(HERE, "charts", "effort_by_project.png"), w=600, h=270, alt="Effort by project",
         caption="ONGC carries most of the volume; every project shows a clear saving."),
    dict(t="table", widths=[40, 12, 12, 12, 12, 12], numeric=[1, 2, 3, 4, 5], header=["KPI", "PAL", "ONGC (OVL)", "Astral (KPMG)", "Common", "Overall"],
         rows=[[lab] + [f(x) for x in ALL] + [tot] for lab, f, tot in [
             ("AI-assisted use cases", lambda x: str(BP[x]["n"]), str(S["n_counted"])),
             ("New developments", lambda x: str(len([o for o in rows_of(x) if o["work"] == "NEW"])), str(len([o for o in ROWS if o["work"] == "NEW"]))),
             ("Enhancements, S/4 and ATC", lambda x: str(len([o for o in rows_of(x) if o["work"] in ("ENH", "S4", "ATC")])), str(len([o for o in ROWS if o["work"] in ("ENH", "S4", "ATC")]))),
             ("Fixes and root-cause analyses", lambda x: str(len([o for o in rows_of(x) if o["work"] in ("FIX", "ANA")])), str(len([o for o in ROWS if o["work"] in ("FIX", "ANA")]))),
             ("Automations and tools", lambda x: str(len([o for o in autos if o["project"] == x])), str(len(autos))),
             ("Effort saved (man-days)", lambda x: md(BP[x]["saved"]), md(S["saved"])),
             ("Effort reduction", lambda x: pc(BP[x]["saved"] / BP[x]["baseline"]), pc(S["red"])),
             ("Productivity improvement", lambda x: f"{(BP[x]['baseline'] / BP[x]['actual'] - 1) * 100:.0f}%", f"{S['prod'] * 100:.0f}%")]]),
    dict(t="note", text="**Method.** Effort without AI = conservative baseline for the work type and complexity of each use case. Actual effort with AI = all my "
                        f"working time in the period ({S['working_days']} days from 19/08/26 including 6 weekend days, plus dated work before), spread over the "
                        "use cases by measured session time and size. Saved = without - with; man-days = saved / 8; reduction = saved / without. "
                        "Every number is formula-driven in the attached Excel register."),
    h1("11. Development Quality and Delivery Improvement"),
    *[x for k, v in quality for x in (h3(k), bl(v))],
    h1("12. Customer Benefits"),
    bl(["**Capacity released** - one associate consultant carried three projects, ATC remediation and production support in the same months.",
        "**Earlier testing** - first working versions within a working day, so functional testing and sign-off started sooner.",
        "**Reusable assets** - ATC patterns, release constraints, forecast engine, workflow and analytical-cube patterns and five developer tools, ready for the next project.",
        "**Commercial view** - effort value = man-days saved x day rate; under fixed price it shows as margin and capacity, under T&M it follows the billing arrangement."]),
    h1("13. Strongest AI Success Story - ONGC JIB Status Dashboard"),
    dict(t="table", widths=[26, 74], header=["Item", "Detail"], rows=case_rows, boldFirst=True, fontSize=8.5),
    h1("14. Overall Conclusions"),
    bl(["AI is part of how I deliver: faster first builds and faster root-cause analysis, with every object reviewed, activated and tested by me.",
        "The approach is repeatable - the same loop and toolkit worked on PAL, ONGC and Astral, across reports, CDS / RAP, workflow, enhancements and ATC.",
        "Next steps: share the AI delivery toolkit with the team, reuse the dashboard pattern for further cards, apply the ATC patterns to the next remediation wave."]),
]
# ------------------------------------------------------------------ annexes
import subprocess
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def card(o):
    rows = [["SAP objects", o["objects"]], ["Business requirement", o["requirement"]], ["Technical challenge", o["challenge"]],
            ["What AI did", o["ai"]], ["My work", o["manual"] or "Review, activation, testing and functional sign-off"],
            ["Result", f"{o['status']}" + (f" - {o['quality']}" if o["quality"] else "")], ["Timeline", o["impact"]],
            ["Evidence", o["folder"] + "; " + short(o["evidence"], 160)]]
    return [dict(t="h3", text=f"{o['id']}  {short(o['title'], 110)}"),
            dict(t="table", widths=[20, 80], header=["Field", "Detail"], rows=rows, boldFirst=True, fontSize=7.5, cantSplit=True)]


annex = [dict(t="h1", text="Annex A - Detailed AI Use Case Register", pageBreak=True),
         p("Every use case not already described in sections 4 to 6, 8 and 13, by project. Hours per use case are in the project tables of sections 4 to 6.")]
for x in ALL:
    rest = [o for o in rows_of(x) if o["folder"] not in KEYED]
    if rest:
        annex.append(dict(t="h2", text=f"{x} - {len(rest)} further use cases"))
        for o in rest:
            annex += card(o)
progs = sorted(ATC["corrected_programs"], key=lambda q: -(q.get("boc_blocks_dated_08_08_2026") or 0))
annex += [dict(t="h1", text="Annex B - ATC Remediation Register", pageBreak=True),
          dict(t="table", caption="Corrected program includes (ONGC)", fontSize=7.5, widths=[30, 26, 16, 12, 16], numeric=[3, 4],
               header=["Include", "Parent program", "Package", "Lines", "Correction blocks"],
               rows=[[q["object"], str(q.get("parent") or ""), str(q.get("package") or ""), f"{q.get('lines') or 0:,}",
                      str(q.get("boc_blocks_dated_08_08_2026") or 0)] for q in progs]),
          dict(t="table", caption="All reusable correction patterns", fontSize=7.5, widths=[34, 66], header=["Finding family", "Correction pattern"],
               rows=[[x["category"], short(str(x.get("typical_fix", "")), 260)] for x in ATC["finding_categories_resolved"]])]
annex += [dict(t="h1", text="Annex C - Effort Calculation and Assumptions", pageBreak=True),
          dict(t="table", caption="Conventional effort baseline by work type and complexity (hours)", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
               header=["Work type", "Low", "Medium", "High", "Very High"],
               rows=[[R["rubric_label"][k]] + [str(v) for v in R["rubric"][k]] for k in R["rubric"]]),
          bl([f"Working time counted: {S['working_days']} days from 19/08/26 (weekdays after 4 days leave, plus 6 weekend days) x 8 h = {h(S['budget'])} h, "
              "plus dated work from 20/07/26 recorded in the session records and work log.",
              "Distribution: half by measured AI session time per object (commit timestamps), half by the size of the development; "
              "a minimum per use case covers prompting, review, activation and unit testing.",
              "Effort saved = without AI - with AI;  reduction = saved / without AI;  man-days = saved / 8;  productivity improvement = without / with - 1.",
              "ATC baseline from the correction blocks applied: 7 / 18 / 28 minutes per pragma / replace / new-code block, 0.2 h per include, 6 h packaging."]),
          dict(t="table", caption="Worked example - JIB Status dashboard", widths=[50, 50], numeric=[1], header=["Step", "Value"],
               rows=[["Effort without AI (Very High new development)", f"{h(J['baseline_h'])} h"], ["Actual effort with AI", f"{h(J['actual_h'])} h"],
                     ["Effort saved", f"{h(J['saved_h'])} h"], ["Effort reduction", pc(J["red"])], ["Man-days saved", f"{J['saved_h'] / 8:.1f}"]])]
ts = [l for l in subprocess.run(["git", "-C", REPO, "ls-files"], capture_output=True, text=True).stdout.splitlines()
      if os.path.basename(l).startswith(("TS_", "TS ")) and not l.startswith(("gail/", "mwc/", "rws/"))]
proj = lambda l: {"ovl": "ONGC (OVL)", "pal": "PAL", "kpmg": "Astral (KPMG)"}.get(l.split("/")[0], "Common")
annex += [dict(t="h1", text="Annex D - Technical Documentation Produced", pageBreak=False),
          dict(t="table", fontSize=7.5, widths=[18, 82], header=["Project", "Technical specification"],
               rows=[[proj(l), l] for l in sorted(ts, key=lambda l: (proj(l), l))]),
          p(f"Plus {M['Issue-log entries written (issue -> cause -> fix)']} issue-log entries (issue, cause, fix) and a technical notes file for every object.")]
blocks += annex

doc = dict(title="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
           header="SAP ABAP AI utilisation report  |  PAL  |  ONGC (OVL)  |  Astral (KPMG)  |  19 November 2026",
           footer="Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri", sections=[dict(blocks=blocks)])
json.dump(doc, open(os.path.join(D, "report.json"), "w"), indent=1)
print("ok")
