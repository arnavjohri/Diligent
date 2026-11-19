"""The complete report in one file, under the section headings of the manager's request.
python3 -I build_combined.py  -> data/combined.json, ../Management_Summary_Email.md   (render with render_docx.js)
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
h = lambda x: f"{x:,.0f}"
pc = lambda x: f"{x * 100:.0f}%"
md = lambda x: f"{x / 8:,.0f}"
COMMITS = M["Total commits in the repository, 19/08 - 19/11/26 (all branches)"]
WD = M["Working days in the period 20/07 - 19/11/26 (less 4 days leave)"]
P4 = ["PAL", "ONGC (OVL)", "T&G", "Common (all projects)"]
rows_of = lambda p: [o for o in ROWS if o["project"] == p]
n_new = len([o for o in ROWS if o["work"] == "NEW"])
autos = [o for o in ROWS if o["automation"] or o["work"] == "TOOL"]


def short(t, n):
    if len(t) <= n:
        return t
    c = t[:n]
    k = c.rfind(". ")
    return c[: k + 1] if k > n * 0.5 else c.rsplit(" ", 1)[0] + "..."


def p(text, **k):
    return dict(t="p", text=text, **k)


def bullets(items, size=None):
    return dict(t="bullets", items=items, **({"size": size} if size else {}))


def proj_line(name):
    v = BP[name]
    return (f"{v['n']} AI-assisted use cases completed. Effort without AI {h(v['baseline'])} h; actual effort with AI {h(v['actual'])} h; "
            f"**{h(v['saved'])} h ({md(v['saved'])} man-days) saved, {pc(v['saved'] / v['baseline'])} effort reduction**.")


def uc_table(rows, caption):
    return dict(t="table", landscape=True, caption=caption, fontSize=7, widths=[5, 23, 37, 9, 6, 6, 6, 5], numeric=[4, 5, 6, 7],
                header=["Sr.", "Development / use case and SAP objects", "AI contribution", "Status", "Without AI (h)", "With AI (h)", "Saved (h)", "Red."],
                rows=[[o["id"], f"**{o['title']}**\n{o['objects']}", o["ai"], o["status"], h(o["baseline_h"]), h(o["actual_h"]), h(o["saved_h"]), pc(o["red"])]
                      for o in rows])


def highlights(rows, n):
    top = sorted(rows, key=lambda o: -o["saved_h"])[:n]
    return bullets([f"**{o['title']}** ({o['id']}; {h(o['saved_h'])} h saved): " + short(o["ai"], 280) for o in top], 19)


def proj_summary():
    rr = [[x, str(BP[x]["n"]), h(BP[x]["baseline"]), h(BP[x]["actual"]), h(BP[x]["saved"]), md(BP[x]["saved"]), pc(BP[x]["saved"] / BP[x]["baseline"])] for x in P4]
    rr.append(["Overall", str(S["n_counted"]), h(S["baseline"]), h(S["actual"]), h(S["saved"]), md(S["saved"]), pc(S["red"])])
    return dict(t="table", caption="Project-wise effort summary", widths=[28, 11, 13, 13, 12, 12, 11], numeric=[1, 2, 3, 4, 5, 6], totalRow=True,
                header=["Project", "Use cases", "Effort without AI (h)", "Actual with AI (h)", "Saved (h)", "Saved (man-days)", "Reduction"], rows=rr)


kpis = dict(t="kpis", items=[
    dict(value=str(S["n_counted"]), label="AI-assisted use cases", note=f"{n_new} new developments, all completed"),
    dict(value=f"{COMMITS}", label="Commits in under 4 months", note=f"{M['Average commits per active day']} per active day"),
    dict(value=md(S["saved"]), label="Man-days saved", note=f"{h(S['saved'])} h of {h(S['baseline'])} h conventional effort"),
    dict(value=pc(S["red"]), label="Effort reduction", note=f"{S['prod'] + 1:.1f}x delivery throughput"),
])

# ------------------------------------------------------------------ mail
mail = f"""Subject: AI utilisation in SAP ABAP delivery - PAL, ONGC (OVL) and T&G (cut-off 19 Nov 2026)

Dear [Manager name],

As requested in your mail of 19 November, please find my report on AI utilisation in SAP ABAP delivery from 20 July to 19 November 2026. The AI tool used is Claude Code (Anthropic).

- AI-assisted developments: {S['n_counted']} completed - ONGC (OVL) {BP['ONGC (OVL)']['n']}, T&G {BP['T&G']['n']}, PAL {BP['PAL']['n']}, common tools {BP['Common (all projects)']['n']}; {n_new} of them new developments.
- Volume: {COMMITS} commits in under four months on {M['Active days with AI-assisted commits (19/08 - 19/11/26)']} active days (including {M['Weekend days with AI-assisted work']} weekends), {M['Lines of ABAP / CDS / script code added in AI commits']:,} lines of code, {M['Distinct custom (Z/Y) SAP objects named in those use cases']} custom SAP objects, {M['Technical specification files produced']} technical specifications.
- Significant applications: ONGC JIB Status management dashboard, DPR Fiori dashboard and CPI interface, bank revaluation and per-barrel analytics on CDS; PAL FB70 credit-memo approval workflow; T&G ZFORECAST (Adhesive and Paints), Exceptional Approval (WRICEF 141) and Clause 34 TDS report.
- ATC (ONGC): 847 assigned findings remediated through 205 correction blocks in 51 includes across 14 packages, with 76 reusable correction patterns.
- Automation: {len(autos)} automations and utilities - daily BP-creation mail, mass uploads, approval workflow, source mass-download and enhancement-finder tools.
- Effort: {h(S['baseline'])} h conventional against {h(S['actual'])} h with AI - **{md(S['saved'])} man-days saved, {pc(S['red'])} effort reduction** ({S['prod'] + 1:.1f}x throughput).
- Delivery: first working versions typically the same or next working day; JIB Status went from requirement (03/11) to written client confirmation (17/11) in 11 working days.
- Benefit: three engagements handled concurrently, faster root-cause analysis on production issues, and reusable patterns and tools for the team.

The complete report, use-case register (Excel) and success-story deck are attached.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
"""
open(os.path.join(HERE, "..", "Management_Summary_Email.md"), "w").write(mail)
subj, body = mail.split("\n", 1)
mail_blocks = [dict(t="h1", text="Management Submission Summary", pageBreak=True), p("**" + subj + "**")]
acc = []
for line in body.strip().split("\n"):
    if line.startswith("- "):
        acc.append(line[2:]); continue
    if acc:
        mail_blocks.append(bullets(acc)); acc = []
    if line.strip():
        mail_blocks.append(p(line, after=80))

# ------------------------------------------------------------------ sections
cats = {}
for o in ROWS:
    cats.setdefault(o["category"], []).append(o)
cat_table = dict(t="table", caption="AI use cases by technical category", widths=[26, 9, 10, 55], numeric=[1, 2],
                 header=["Category", "Use cases", "Saved (h)", "Developments"],
                 rows=[[k, str(len(v)), h(sum(o["saved_h"] for o in v)), "; ".join(o["title"].split(" - ")[0].split(":")[0][:44] for o in v[:4])]
                       for k, v in sorted(cats.items(), key=lambda kv: -sum(o["saved_h"] for o in kv[1]))])
usage = dict(t="table", caption="AI utilisation and consumption", widths=[52, 16, 52], header=["Measure", "Value", "Source"],
             rows=[[m[0], f"{m[1]:,}" if isinstance(m[1], (int, float)) else str(m[1]), m[2]] for m in U["metrics"]])
monthly = dict(t="table", caption="Monthly AI-assisted activity", widths=[30, 22, 18, 30], numeric=[1, 2, 3],
               header=["Month", "AI session hours", "Active days", "Commits on client work"],
               rows=[[m[0], f"{m[1]:.0f}", str(m[2]), str(m[3])] for m in U["monthly"]])
atc_funnel = dict(t="table", caption="ATC remediation - findings identified to corrections implemented", widths=[46, 12, 52], numeric=[1],
                  header=["Stage", "Count", "Detail"],
                  rows=[["Objects (includes) in the assigned ATC scope", "51", "43 programs, 14 packages"],
                        ["ATC findings assigned and remediated (05-14/08/26)", "847", "Worked family by family"],
                        ["AI-assisted correction blocks applied", "205", "107 pragma / pseudo-comment, 65 replaced with the original kept commented, 33 new code"],
                        ["Lines added or changed", "833", "Line diff against pre-remediation snapshots"],
                        ["Findings routed for functional / senior decision", "26", "P1 field-length decisions, XK01 BDC, BSEG statements"],
                        ["Objects packaged for abapGit upload with procedure", "51", "14 packages; handover document 25/08/26"],
                        ["Rule audit across all corrected objects before handover", "51", "23/08/26"],
                        ["Reusable correction patterns documented", str(ATC["reusable_patterns_count"]), "Knowledge base plus 31 activation / runtime rules"]])
atc_cats = dict(t="table", caption="Types of ATC findings resolved and the AI-assisted correction pattern", fontSize=7, widths=[34, 66],
                header=["Finding category", "Correction applied"],
                rows=[[x["category"], short(str(x.get("typical_fix", "")), 200)] for x in ATC["finding_categories_resolved"][:24]])
auto_table = dict(t="table", caption="Automation solutions and reusable developer tools", fontSize=7, widths=[7, 30, 14, 39, 10],
                  header=["Sr.", "Automation / tool", "Project", "Manual process replaced", "Status"],
                  rows=[[o["id"], o["title"], o["project"], o["auto_process"] or o["requirement"], o["status"]] for o in autos])
dash = dict(t="table", caption="Project-wise productivity dashboard", widths=[40, 12, 12, 12, 12, 12], numeric=[1, 2, 3, 4, 5],
            header=["KPI", "PAL", "ONGC (OVL)", "T&G", "Common", "Overall"],
            rows=[[lab] + [f(x) for x in P4] + [tot] for lab, f, tot in [
                ("AI-assisted use cases", lambda x: str(BP[x]["n"]), str(S["n_counted"])),
                ("Distinct applications / new developments", lambda x: str(len([o for o in rows_of(x) if o["work"] == "NEW"])), str(n_new)),
                ("Programs developed / enhanced", lambda x: str(len([o for o in rows_of(x) if o["work"] in ("NEW", "ENH", "S4", "ATC")])),
                 str(len([o for o in ROWS if o["work"] in ("NEW", "ENH", "S4", "ATC")]))),
                ("ATC findings resolved", lambda x: "847" if x == "ONGC (OVL)" else "-", "847"),
                ("Automation solutions", lambda x: str(len([o for o in autos if o["project"] == x])), str(len(autos))),
                ("Other technical corrections (fixes, root-cause analyses)", lambda x: str(len([o for o in rows_of(x) if o["work"] in ("FIX", "ANA")])),
                 str(len([o for o in ROWS if o["work"] in ("FIX", "ANA")]))),
                ("Effort without AI (h)", lambda x: h(BP[x]["baseline"]), h(S["baseline"])),
                ("Actual effort with AI (h)", lambda x: h(BP[x]["actual"]), h(S["actual"])),
                ("Effort saved (h)", lambda x: h(BP[x]["saved"]), h(S["saved"])),
                ("Effort saved (man-days)", lambda x: md(BP[x]["saved"]), md(S["saved"])),
                ("Weighted effort reduction", lambda x: pc(BP[x]["saved"] / BP[x]["baseline"]), pc(S["red"])),
                ("Productivity improvement", lambda x: f"{(BP[x]['baseline'] / BP[x]['actual'] - 1) * 100:.0f}%", f"{S['prod'] * 100:.0f}%")]])
top10 = dict(t="table", caption="Ten largest effort savings", widths=[8, 50, 14, 14, 14], numeric=[2, 3, 4],
             header=["Sr.", "Development", "Without AI (h)", "With AI (h)", "Saved (h)"],
             rows=[[o["id"], o["title"], h(o["baseline_h"]), h(o["actual_h"]), h(o["saved_h"])] for o in sorted(ROWS, key=lambda o: -o["saved_h"])[:10]])
rubric = dict(t="table", caption="Conventional effort baseline by work type and complexity (hours)", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
              header=["Work type", "Low", "Medium", "High", "Very High"],
              rows=[[R["rubric_label"][k]] + [str(v) for v in R["rubric"][k]] for k in R["rubric"]])

quality = {
    "Development Efficiency": [
        "First working versions the same or next working day: ZMM_BP_CREATE_MAIL built and activated on first paste the day the FS answers arrived (25/09/26); ZFORECAST Paints from FS (19/10) to imported and active (22/10/26).",
        "Repetitive coding removed: the ZFORECAST calculation engine reused for Paints; the GL workflow class pattern reused for the FB70 credit-memo workflow; the ZMB5B amount logic ported into ZMM_MB5B_NEW.",
        "Complex logic delivered quickly: G/L line matching with backtracking in UPDATE_AMOUNT (PAL), JV alignment postings netting to zero per account (ONGC), cascading scheme settlement (T&G).",
    ],
    "Debugging and Problem Resolution": [
        "ZMM_TMS_STATUS: blank Excel export traced to no_out = '0' on 44 field-catalog entries - one constant changed, confirmed working by the SAP lead the same day (28/10/26).",
        "ZFI_BNK_APP1 / ZBNK_APP2: second-signatory approval and dead Back / Exit defects diagnosed, fixed and activated in OCQ on the day raised (27/08/26).",
        "CJ88 settlement reversal and FBV0 CORE_GJ 912: root causes proven in SAP standard from ST22 / SM13 / ST05 evidence, so no custom code was touched.",
        "PAL INC01967: unreadable e-mailed invoice PDFs traced to the server-side encryption round trip; incident closed 13/10/26.",
    ],
    "Code Quality": [
        "S/4HANA-compatible logic: ABAA / ABZU batch input replaced by FI-AA BAPIs (ZAA_IMPAIRMENTLOSS); strict Open SQL, guarded FOR ALL ENTRIES and released CDS views across the ATC batch.",
        "No modification of SAP standard: released BAdIs (ME_BAPI_PO_CUST for PAL Ariba POs), implicit enhancements calling Z classes, CDS extensions for Fiori fields.",
        "Error paths give the user a message instead of a dump; posting programs default to test run; every return code checked in the PAL invoice mail chain.",
    ],
    "Documentation and Knowledge Transfer": [
        f"{M['Issue-log entries written (issue -> cause -> fix)']} issue-log entries (issue, cause, fix) and a NOTES file per object; {M['Technical specification files produced']} technical specifications in client templates.",
        "FS questions raised before build: 16 for WRICEF 141, 21 for WRICEF 147, 28 FS points for the Paints forecast - fewer change cycles later.",
        "Legacy programs explained: ARMS authorisation tool (25,000 lines) mapped for role redesign; standard JVA correction tool RGJV_UPDATE_ACC_DATA_IN_ACDOCA documented for OVL.",
    ],
    "Project Delivery": [
        f"Three engagements delivered concurrently on {M['Active days with AI-assisted commits (19/08 - 19/11/26)']} active days, including {M['Weekend days with AI-assisted work']} weekends and {M['Days with 6 or more hours of measured AI session time']} days of 6+ hours of AI session time.",
        "Earlier availability for testing: functional testing started on working versions within a day for most developments.",
        f"{M['Review corrections applied to AI output before go-live']} review corrections applied to AI output before go-live; 56 release constraints and 31 standing rules applied to every new object.",
    ],
}
quality_blocks = []
for k, v in quality.items():
    quality_blocks += [dict(t="h3", text=k), bullets(v)]

case_rows = [
    ["Project name", "ONGC Videsh Ltd (OVL)"],
    ["Development title and SAP object", "Management Dashboard 'JIB Status' - ZFI_JIB_STATUS: analytical cube ZI_JIB_STATUS_CUBE with ZI_JIB_DOC, ZI_JIB_DOC_AGG, ZI_JIB_YEAR_AGG, ZI_JIB_QTR_AGG, ZI_JIB_CLEARING, ZI_JIB_PERIOD, ZI_JIB_VENTURE"],
    ["Business requirement", "For every joint venture, show whether the period's JIB is posted and when it was entered - by month, quarter or fiscal year - with document numbers and drill-down, as a Fiori Custom Analytical Query on the Management Dashboard."],
    ["Technical complexity", "No venture on the document header (JIB identified by document type from a GS01 set, venture from the line items); reversals; months without a JIB must show as Pending; entry date vs posting period; older S/4 CDS release; delivery by abapGit ZIP."],
    ["Conventional development approach", f"SE16N analysis of BKPF / BSEG / JV data, view-by-view design by trial activation, separate rebuilds after each client test - {h(J['baseline_h'])} h."],
    ["How AI was used", "Read the requirement workbook and production sample documents, designed the data model, wrote all eight CDS views and the abapGit ZIP, and rebuilt the model on client feedback."],
    ["Development workflow with AI", "Requirement -> AI data model -> AI CDS build -> import and activation -> query built with the GR consultant -> client test -> AI rebuild (entry-date model 04/11, posting-period model 06/11) -> additions (all ventures, document type, clearing date and document) 17/11 -> business-unit mapping 19/11."],
    ["Human review, corrections and validation", "Arnav confirmed the document-type set in GS03 and SE16N, imported and activated each version, validated output against production documents, relayed the client tests and set the launchpad navigation."],
    ["Before-and-after comparison", f"Effort {h(J['baseline_h'])} h -> {h(J['actual_h'])} h; first running query the next working day (03/11 -> 04/11); 13 logged changes absorbed."],
    ["Quantified effort reduction", f"{h(J['saved_h'])} h saved ({J['saved_h'] / 8:.1f} man-days), {pc(J['red'])} reduction, {J['prod'] + 1:.1f}x throughput."],
    ["Actual timeline impact", "Requirement 03/11/26 to written client confirmation 17/11/26 - 11 working days including two client test rounds and four additions."],
    ["Quality improvement", "All twelve periods generated so missing JIBs show as Pending; reversed documents handled; clearing date and document; document-number navigation; no standard object modified."],
    ["Customer or project benefit", "Client (Corporate Accounts), 17/11/26: 'working well and meeting expectations'. Management sees JIB posting status per venture without Excel; the cube pattern now serves Bank Revaluation, Treasury bank register and Per-Barrel analysis."],
    ["Lessons learned", "Check production samples line by line before fixing the model; one object at a time with activation feedback; record every release constraint once and reuse it."],
    ["Opportunities to replicate", "Further Management Dashboard cards on the same cube pattern (ONGC); analytical reporting for PAL finance; forecasting and credit-management analytics for T&G."],
]
slides = [
    ("Slide 1 - AI-Enabled SAP ABAP Delivery Improvement", [f"ONGC Videsh (OVL) - Management Dashboard 'JIB Status'.", "Eight CDS views and an analytical cube, built from a requirement workbook and confirmed by the client in 11 working days.",
                                                            f"Key result: {h(J['baseline_h'])} h -> {h(J['actual_h'])} h, {pc(J['red'])} less effort. Portfolio: {S['n_counted']} use cases, {md(S['saved'])} man-days saved, {COMMITS} commits."]),
    ("Slide 2 - Business Requirement and Technical Challenge", ["Requirement: JIB posting status per joint venture by month, quarter and fiscal year with document drill-down.",
                                                                "Complexity: no venture on the header; reversals and empty months; older S/4 CDS release; delivery by abapGit ZIP.",
                                                                f"Conventional approach: SE16N analysis, trial activation, rebuild after each test - {h(J['baseline_h'])} h."]),
    ("Slide 3 - How AI Was Leveraged", ["AI tool: Claude Code (Anthropic).", "Workflow: requirement -> AI data model -> AI build -> human validation -> client feedback loop.",
                                        "Controls: GS03 / SE16N confirmation, one object at a time with activation feedback, 56 release constraints, no standard modification."]),
    ("Slide 4 - Before vs After AI", [f"Total effort {h(J['baseline_h'])} h vs {h(J['actual_h'])} h.", "First running version: next working day.",
                                      "Requirement to client confirmation: 11 working days; 13 change rounds absorbed."]),
    ("Slide 5 - Quantified Productivity Benefits", [f"{h(J['saved_h'])} h saved, {J['saved_h'] / 8:.1f} man-days, {pc(J['red'])} reduction, {J['prod'] + 1:.1f}x throughput.",
                                                    f"Portfolio: {h(S['saved'])} h ({md(S['saved'])} man-days) saved, {pc(S['red'])} reduction, {COMMITS} commits in under four months."]),
    ("Slide 6 - Delivery Quality and Customer Value", ["Quality: complete periods, reversal handling, clearing data, document navigation.", "Reuse: cube pattern reused for three further analytics.",
                                                       "Customer value: client-confirmed management visibility; capacity released for other OVL work."]),
    ("Slide 7 - Conclusion and Replication Opportunities", ["Principal achievement: client-confirmed dashboard in 11 working days.", "Replication: PAL, ONGC and T&G on the same AI-assisted loop.",
                                                            "Next steps: roll the toolkit out to the team; extend the dashboard pattern; apply the ATC patterns to the next remediation wave."]),
]
slide_blocks = []
for t, items in slides:
    slide_blocks += [dict(t="h3", text=t), bullets(items)]


def card(o):
    rows = [["Sr. No.", o["id"]], ["Project", o["project"] + (f" ({o['evidence_client']})" if o["project"] == "T&G" else "")],
            ["Development / use case", o["title"]], ["SAP object", o["objects"]],
            ["Development type", f"{o['dev_type']} - {o['category']} - complexity {o['complexity']}"],
            ["Business requirement", o["requirement"]], ["Technical challenge", o["challenge"]], ["AI tool used", o["ai_tool"]],
            ["AI contribution", o["ai"]], ["Manual intervention", o["manual"]],
            ["Effort without AI", f"{h(o['baseline_h'])} h"], ["Actual effort with AI", f"{h(o['actual_h'])} h"],
            ["Effort saved", f"{h(o['saved_h'])} h ({o['saved_h'] / 8:.1f} man-days)"], ["Effort reduction (%)", pc(o["red"])],
            ["Delivery impact", o["impact"]], ["Quality improvement", o["quality"] or "Delivered to the coding standard (markers, strict SQL, messages on error paths)"],
            ["Completion status", o["status"] + (f" - TR {o['trs']}" if o["trs"] else "")],
            ["Source evidence", o["folder"] + (f" (+ {o['merged']})" if o["merged"] else "") + "; " + o["evidence"]], ["Confidence", o["confidence"]]]
    return [dict(t="h3", text=f"{o['id']}  {o['title']}"),
            dict(t="table", widths=[22, 78], header=["Field", "Detail"], rows=rows, boldFirst=True, fontSize=7.5, cantSplit=True)]


annex_a = [dict(t="h1", text="Annex A - Detailed AI Use Case Register", pageBreak=True),
           p(f"All {S['n_counted']} use cases with the register fields requested, grouped by project.")]
for x in P4:
    annex_a.append(dict(t="h2", text=f"{x} - {BP[x]['n']} use cases"))
    for o in rows_of(x):
        annex_a += card(o)

annex_b = [dict(t="h1", text="Annex B - Effort Calculation and Assumptions", pageBreak=True),
           dict(t="h3", text="A. Effort without AI"),
           p("Conventional effort per use case = baseline hours for the work type and complexity x scope factor (stated per use case where one delivery "
             "contains several objects). The baseline covers requirement understanding, technical analysis, design, coding, debugging, unit testing, rework and "
             "technical documentation. ATC uses the correction blocks actually applied: 10 / 25 / 40 minutes per pragma / replace / new-code block, 15 minutes per include, 8 h packaging."),
           rubric,
           dict(t="h3", text="B. Actual effort with AI"),
           p(f"Actual effort counts the full development time of the period: {WD} working days x 8 h, less the {S['admin_share'] * 100:.1f}% share of status calls and "
             f"transport administration ({h(S['budget'])} h from 19/08/26, plus dated work before it). It is distributed over the use cases by the measured AI session time of "
             "each object (commit timestamps), with a minimum per use case for prompting, review, activation and unit testing (2 / 4 / 8 / 16 h by complexity; "
             "1 / 2 / 4 / 6 h for analyses). Review and correction time is therefore included in every figure."),
           dict(t="h3", text="C. Calculation methodology"),
           bullets(["Effort saved (hours) = effort without AI - actual effort with AI.", "Effort reduction (%) = (effort saved / effort without AI) x 100.",
                    "Effort saved (man-days) = effort saved in hours / 8.", "Productivity improvement (%) = ((effort without AI / actual effort with AI) - 1) x 100.",
                    "Project totals are weighted by hours (summed), not averaged percentages; recurring automation savings are kept separate from development savings."]),
           dict(t="table", caption="Illustrative calculation (JIB Status)", widths=[50, 50], header=["Parameter", "Value"], numeric=[1],
                rows=[["Effort without AI", f"{h(J['baseline_h'])} h"], ["Actual effort with AI", f"{h(J['actual_h'])} h"], ["Effort saved", f"{h(J['saved_h'])} h"],
                      ["Effort reduction", pc(J["red"])], ["Man-days saved", f"{J['saved_h'] / 8:.1f}"], ["Productivity improvement", f"{J['prod'] * 100:.0f}%"]])]

progs = sorted(ATC["corrected_programs"], key=lambda q: -(q.get("boc_blocks_dated_08_08_2026") or 0))
annex_c = [dict(t="h1", text="Annex C - ATC Remediation Register", pageBreak=True),
           dict(t="table", fontSize=7, widths=[30, 26, 16, 10, 9, 9], numeric=[3, 4, 5],
                header=["Include", "Parent program", "Package", "Lines", "Correction blocks", "Changed hunks"],
                rows=[[q["object"], str(q.get("parent") or ""), str(q.get("package") or ""), f"{q.get('lines') or 0:,}",
                       str(q.get("boc_blocks_dated_08_08_2026") or 0), str(q.get("diff_hunks") or 0)] for q in progs]),
           dict(t="table", caption="Reusable correction patterns (complete list)", fontSize=7, widths=[34, 66], header=["Finding family", "Correction pattern"],
                rows=[[x["category"], short(str(x.get("typical_fix", "")), 260)] for x in ATC["finding_categories_resolved"]])]
annex_d = [dict(t="h1", text="Annex D - Evidence and Estimation Annexure", pageBreak=True),
           dict(t="table", fontSize=6.5, widths=[6, 9, 20, 24, 14, 13, 8, 6],
                header=["Sr.", "Project", "SAP object / development", "Source artefact", "Evidence of completion", "Effort basis", "Assumptions", "Confidence"],
                rows=[[o["id"], o["project"], o["title"], short(o["folder"] + "; " + o["evidence"], 200), f"{o['status']}\n{o['first']} -> {o['last']}",
                       short(o["basis"], 90), f"{o['work']} / {o['complexity']} / x{o['scope']}", o["confidence"]] for o in ROWS])]

contents = ["Management Submission Summary", "1. Executive Summary", "2. Scope and Sources Reviewed", "3. AI Utilisation and Consumption",
            "4. PAL Project - Detailed AI Use Cases", "5. ONGC (OVL) Project - Detailed AI Use Cases", "6. T&G Project - Detailed AI Use Cases",
            "7. Technical Classification of AI Use Cases", "8. ATC Correction and Technical Debt Reduction Analysis", "9. Automation Benefits Assessment and Reusable Development",
            "10. Quantitative Analysis of Productivity and Effort Savings", "11. Project-Wise Productivity Dashboard", "12. Development Quality and Delivery Improvement Assessment",
            "13. Customer Cost-Benefit Assessment", "14. Strongest AI Success Story", "15. PowerPoint Case Study - Slide Content", "16. Overall Conclusions",
            "Annex A - Detailed AI Use Case Register", "Annex B - Effort Calculation and Assumptions", "Annex C - ATC Remediation Register",
            "Annex D - Evidence and Estimation Annexure"]

main = [
    dict(t="h1", text="1. Executive Summary", pageBreak=True), kpis,
    p(f"Between 20 July and 19 November 2026 AI (Claude Code) was integrated into my day-to-day SAP ABAP delivery on three concurrent projects - ONGC Videsh (OVL), "
      f"T&G and PAL. **{S['n_counted']} AI-assisted developments were completed**: {BP['ONGC (OVL)']['n']} for ONGC, {BP['T&G']['n']} for T&G, {BP['PAL']['n']} for PAL "
      f"and {BP['Common (all projects)']['n']} common tools. They include complete applications (CDS / RAP dashboards, a credit-memo approval workflow, forecasting), "
      "new reports and interfaces, enhancements, ATC remediation of 51 program includes, root-cause analysis of production issues, and automation utilities."),
    p(f"The work produced **{COMMITS} commits in under four months** - about {round(M['Average commits per active day'])} per active day - with "
      f"{M['Lines of ABAP / CDS / script code added in AI commits']:,} lines of code, {M['Distinct custom (Z/Y) SAP objects named in those use cases']} custom SAP objects "
      f"and {M['Technical specification files produced']} technical specifications."),
    p(f"Conventional delivery of the same scope requires **{h(S['baseline'])} hours**; with AI it took **{h(S['actual'])} hours** of my development time. "
      f"**{h(S['saved'])} hours - {md(S['saved'])} man-days - were saved, a {pc(S['red'])} effort reduction and {S['prod'] + 1:.1f}x delivery throughput.**"),
    proj_summary(),
    dict(t="h3", text="Strongest success story"),
    p(f"ONGC Videsh Management Dashboard 'JIB Status': eight CDS views with an analytical cube, from requirement (03/11/26) to written client confirmation (17/11/26) "
      f"in 11 working days; {h(J['baseline_h'])} h conventional effort delivered in {h(J['actual_h'])} h ({pc(J['red'])} reduction)."),
    dict(t="h1", text="2. Scope and Sources Reviewed", pageBreak=True),
    bullets([f"The consolidated work repository: every object folder for ONGC (ovl/), PAL (pal/), T&G (kpmg/) and common tools (tools/), with each issue log (issue -> cause -> fix) and technical note.",
             f"Git history across 66 branches: {COMMITS} commits from 19/08/26 to 19/11/26.",
             "Claude Code session records from 20/07/26 to 15/08/26: 30 sessions and 557 prompts.",
             "The day-wise August 2026 OVL work log, ATC exports, the manual review list, the ATC knowledge base and the handover document.",
             "Functional specifications, technical specifications, client test feedback and mail drafts filed with each object."]),
    dict(t="h1", text="3. AI Utilisation and Consumption", pageBreak=True), usage, monthly,
    dict(t="h1", text="4. PAL Project - Detailed AI Use Cases", pageBreak=True), p(proj_line("PAL")),
    p("PAL (Philippine Airlines), systems DS4 -> QS4 -> PS4: FI-AR forms and e-mail, journal-entry and invoice upload tiles, FB70 credit-memo approval workflow, Ariba PO integration and SD-FI texts (incidents INC01192, INC01740, INC01967)."),
    highlights(rows_of("PAL"), 6), uc_table(rows_of("PAL"), "PAL - AI use cases"),
    dict(t="h1", text="5. ONGC (OVL) Project - Detailed AI Use Cases", pageBreak=True), p(proj_line("ONGC (OVL)")),
    p("ONGC Videsh, ECC -> S/4HANA (systems OCD / OCQ / OCP): ATC remediation; CDS / RAP analytics for the Management Dashboard (JIB status, bank revaluation, treasury bank register, per-barrel analysis); "
      "DPR Fiori dashboard and CPI interface; Group Reporting; FI / JVA posting and reconciliation programs; MM enhancements and Fiori tiles; root-cause analysis of production and Mock-2 issues."),
    highlights(rows_of("ONGC (OVL)"), 10), uc_table(rows_of("ONGC (OVL)"), "ONGC (OVL) - AI use cases"),
    dict(t="h1", text="6. T&G Project - Detailed AI Use Cases", pageBreak=True), p(proj_line("T&G")),
    p("T&G - Astral Limited, Project UDAY, delivered through KPMG: ZFORECAST Adhesive and Paints (WRICEF ID-2A / ID-2B), Exceptional Approval (141 A/B), Clause 34 TDS report (337), PO budget control (050), "
      "supplier BP mail (057), CC MIS (147), MB5B receipt / issue amounts (195), vendor mass upload (FSD 30) and Scheme (Pipes)."),
    highlights(rows_of("T&G"), 8), uc_table(rows_of("T&G"), "T&G - AI use cases"),
    dict(t="h1", text="7. Technical Classification of AI Use Cases", pageBreak=True), cat_table,
    dict(t="h1", text="8. ATC Correction and Technical Debt Reduction Analysis", pageBreak=True),
    p(f"ATC S/4HANA-readiness remediation for ONGC Videsh: {h(AT['baseline_h'])} h conventional against {h(AT['actual_h'])} h with AI, including review and correction - "
      f"**{h(AT['saved_h'])} h saved ({pc(AT['red'])})**. The correction patterns were derived once and applied across the batch; the saving is computed from the blocks actually applied, so reuse is not double counted."),
    atc_funnel,
    bullets(["Recurring technical problems: SELECT SINGLE without a unique key (NOORDER), field-length extension of MATNR and amounts, simplified objects (BSEG, KONV, VBUK / VBUP, J_1IMOVEND), CLIENT SPECIFIED on compatibility views, non-strict Open SQL.",
             "Manual debugging and validation: rule audit across all 51 objects before handover; P1 decisions routed to the senior; abapGit upload procedure written for the 14 packages.",
             "Quality and maintainability: original code kept commented inside markers for review; strict Open SQL; released CDS views instead of simplified tables; one pseudo-comment per line with the SAP note."]),
    atc_cats,
    dict(t="h1", text="9. Automation Benefits Assessment and Reusable Development", pageBreak=True),
    p(f"{len(autos)} automations and reusable tools were built with AI. They replace manual steps for users (daily BP-creation mail, mass uploads, approval routing, period-end revaluation, "
      "JV alignment postings) and for developers (source mass download, enhancement finder, ICF URL list, ST05 trace decoder, the AI delivery toolkit). Recurring savings are separate "
      "from the development savings in this report and can be computed per tool on the Automation Benefits sheet of the register."),
    auto_table,
    dict(t="h1", text="10. Quantitative Analysis of Productivity and Effort Savings", pageBreak=True),
    p(f"Effort without AI {h(S['baseline'])} h; actual effort with AI {h(S['actual'])} h; effort saved {h(S['saved'])} h = {md(S['saved'])} man-days; effort reduction {pc(S['red'])}; "
      f"productivity improvement {S['prod'] * 100:.0f}%. The method is in Annex B; every figure is formula-driven in the register."),
    proj_summary(), top10,
    p("Cycle time is reported separately from person-hours: most developments reached a first working version within a working day (section 12, Delivery impact in Annex A)."),
    dict(t="h1", text="11. Project-Wise Productivity Dashboard", pageBreak=True), dash,
    dict(t="h1", text="12. Development Quality and Delivery Improvement Assessment", pageBreak=True), *quality_blocks,
    dict(t="h1", text="13. Customer Cost-Benefit Assessment", pageBreak=True),
    bullets([f"Developer capacity released: {md(S['saved'])} man-days in four months - capacity that carried three projects concurrently.",
             "Reduced effort for comparable development: the same scope needs about a third of the conventional effort.",
             "Additional work with existing resources: one associate consultant covered PAL, ONGC and T&G developments, ATC remediation and production support in the same period.",
             "Reduced time to delivery: working versions within a working day; JIB Status from requirement to client confirmation in 11 working days.",
             "Reusable development assets: 76 ATC correction patterns, 56 release constraints, the forecast engine, the workflow class pattern, the analytical cube pattern and five developer tools.",
             "Reduced repetitive remediation effort: ATC patterns applied across 51 includes in one pass.",
             "Potential effort value = effort saved (man-days) x applicable day rate. Under fixed-price engagements the benefit is delivery margin and released capacity; under time-and-material it follows the billing arrangement."]),
    dict(t="h1", text="14. Strongest AI Success Story", pageBreak=True),
    dict(t="table", widths=[28, 72], header=["Item", "Detail"], rows=case_rows, boldFirst=True, fontSize=8.5),
    dict(t="h1", text="15. PowerPoint Case Study - Slide Content", pageBreak=True),
    p("Content of the seven slides in AI_Success_Story_JIB_Status.pptx."), *slide_blocks,
    dict(t="h1", text="16. Overall Conclusions", pageBreak=True),
    bullets([f"AI is part of daily SAP ABAP delivery: {S['n_counted']} completed use cases and {COMMITS} commits in under four months across PAL, ONGC (OVL) and T&G.",
             f"Effort reduced by {pc(S['red'])} - {md(S['saved'])} man-days saved - with complete applications, ATC remediation, enhancements, interfaces and root-cause analyses delivered.",
             "The gain comes from fast first builds and fast root-cause analysis under human control: fresh source download before every change, activation feedback, functional confirmation and a standing record of release constraints.",
             "Next steps: roll the AI delivery toolkit out to the team, extend the dashboard cube pattern to further cards, apply the ATC patterns to the next remediation wave, and log effort per object to sharpen future reporting."]),
]

cover = dict(noHeader=True, blocks=[
    dict(t="cover", kicker="MANAGEMENT SUBMISSION - AI ADOPTION AND QUANTIFIABLE PRODUCTIVITY BENEFITS IN SAP ABAP DELIVERY",
         title="Comprehensive SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
         subtitle="Projects: PAL | ONGC (OVL) | T&G   -   Reporting cut-off date: 19 November 2026",
         lines=["**Prepared by:** Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global", "**Period:** 20 July - 19 November 2026", "**AI tool:** Claude Code (Anthropic)",
                f"**Headline:** {S['n_counted']} AI-assisted use cases | {COMMITS} commits | {md(S['saved'])} man-days saved | {pc(S['red'])} effort reduction"]),
    dict(t="pagebreak"), dict(t="h2", text="Contents"), bullets(contents, 19)] + mail_blocks)
body = dict(blocks=main[:main.index(next(b for b in main if b.get("text") == "4. PAL Project - Detailed AI Use Cases"))])
def split_sections(blocks):
    out, cur = [], []
    for b in blocks:
        if b.get("landscape"):
            if cur:
                out.append(dict(blocks=cur)); cur = []
            out.append(dict(orientation="landscape", blocks=[b]))
            continue
        if not cur and out and b.get("pageBreak"):
            b = dict(b, pageBreak=False)
        cur.append(b)
    if cur:
        out.append(dict(blocks=cur))
    return out


doc = dict(title="Comprehensive SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
           header="SAP ABAP AI utilisation, productivity & delivery efficiency report | PAL | ONGC (OVL) | T&G | 19 November 2026",
           footer="Prepared by Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri",
           sections=[cover] + split_sections(main + annex_a + annex_b + annex_c + annex_d))
json.dump(doc, open(os.path.join(D, "combined.json"), "w"), indent=1)
print("blocks", len(main), "cards", len(ROWS))
