"""One consolidated document: mail summary + full report + case study + every use case in full + annexes.
python3 -I build_combined.py   -> data/combined.json   (render with render_docx.js)
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "data")
R = json.load(open(os.path.join(D, "register.json")))
REP = json.load(open(os.path.join(D, "report.json")))
ATC = json.load(open(os.path.join(D, "inv_atc.json")))
S, ROWS = R["summary"], R["rows"]
MAIL = open(os.path.join(HERE, "..", "Management_Summary_Email.md")).read()
J = next(o for o in ROWS if o["folder"] == "ovl/zfi_jib_status")
h = lambda x: f"{x:,.0f}"
h1 = lambda x: f"{x:,.1f}"
pc = lambda x: f"{x * 100:.0f}%"
md = lambda x: f"{x / 8:,.0f}"
P_ORDER = ["PAL", "ONGC (OVL)", "KPMG - Astral (UDAY)", "Cross-project", "Attribution pending"]

# ------------------------------------------------------------ part 0: mail
mail_blocks = [dict(t="h1", text="Management summary (e-mail text)")]
subj, body = MAIL.split("\n", 1)
mail_blocks.append(dict(t="p", text="**" + subj.replace("Subject:", "Subject:").strip() + "**"))
bul = []
for line in body.strip().split("\n"):
    line = line.rstrip()
    if line.startswith("- "):
        bul.append(line[2:])
        continue
    if bul:
        mail_blocks.append(dict(t="bullets", items=bul)); bul = []
    if line:
        mail_blocks.append(dict(t="p", text=line, after=80))
if bul:
    mail_blocks.append(dict(t="bullets", items=bul))

# ------------------------------------------------------------ report body (renumbered from 1)
rep_sections = []
for i, sec in enumerate(REP["sections"]):
    blocks = [b for b in sec["blocks"] if b["t"] not in ("cover", "toc")]
    if i == 0:  # drop the two page breaks that followed cover / toc
        while blocks and blocks[0]["t"] == "pagebreak":
            blocks.pop(0)
    rep_sections.append(dict(sec, blocks=blocks, noHeader=False))

# ------------------------------------------------------------ case study deck, slide by slide
sens50 = S["baseline"] * 0.5 - S["actual"]
slides = [
    ("Slide 1 - AI-Enabled SAP ABAP Delivery Improvement",
     [f"Project: ONGC Videsh (OVL). Use case: Management Dashboard 'JIB Status' (ZFI_JIB_STATUS).",
      "Value statement: eight CDS views and an analytical cube, built from a requirement workbook and confirmed by the client in 11 working days.",
      f"Key result: {h(J['baseline_h'])} h conventional (estimate) vs {h(J['actual_h'])} h AI-assisted - {pc(J['red'])} less effort.",
      f"Portfolio: {S['n_counted']} AI-assisted use cases, {md(S['saved'])} man-days saved (est.), {pc(S['red'])} weighted reduction."]),
    ("Slide 2 - Business requirement and technical challenge",
     ["Requirement: per joint venture, is the period's JIB posted and when was it entered; month / quarter / fiscal-year views with Pending where no JIB exists; document numbers with drill-down; consumed as a Fiori Custom Analytical Query.",
      "Challenges: no venture on the document header (JIB found by document type from a GS01 set, venture from the line items); reversals and months without a JIB; older S/4 release and delivery by abapGit ZIP to a system the AI cannot reach; 13 logged issues and changes including two client test rounds and four additions.",
      "Conventional approach and bottlenecks: SE16N analysis of BKPF / BSEG / JV data, trial-and-error activation, a model rebuild after every client test - estimated 120 h (about 15 working days)."]),
    ("Slide 3 - How AI was leveraged",
     ["AI tool: Claude Code (Anthropic), working from the repository; every object reached SAP through Arnav.",
      "Workflow: (1) requirement workbook and production sample documents checked line by line -> (2) AI designs the data model -> (3) AI writes eight CDS views and the abapGit ZIP with release constraints applied -> (4) Arnav imports, activates, checks in GS03 / SE16N, builds the query with the GR consultant -> (5) client feedback turned around by the AI (two test rounds, four additions).",
      "Controls: document-type set confirmed before the model was fixed; one object at a time with activation feedback; 56 recorded release constraints applied before coding; no SAP standard object modified."]),
    ("Slide 4 - Before vs after AI",
     [f"Total effort: {h(J['baseline_h'])} h conventional (estimate) vs {h(J['actual_h'])} h AI-assisted (estimate).",
      "First running version: build about 15 working days conventionally vs the next working day (03/11 -> 04/11/26).",
      "Requirement to client confirmation: 11 working days including two client test rounds.",
      "Change rounds absorbed: 13 logged, 6 rebuilds / fixes. Phase-wise hours (development / debugging / testing) were not recorded, so only totals are compared."]),
    ("Slide 5 - Quantified productivity benefits",
     [f"{h(J['saved_h'])} h saved, {md(J['saved_h'])} man-days, {pc(J['red'])} effort reduction, {J['prod'] + 1:.1f}x throughput (+{J['prod'] * 100:.0f}% productivity).",
      f"Portfolio on the same method: {h(S['saved'])} h ({md(S['saved'])} man-days) saved, {pc(S['red'])} weighted; {md(S['tier_A']['saved'])} man-days on work confirmed in the system.",
      f"Even with conventional baselines 50% lower: {md(sens50)} man-days ({pc(1 - S['actual'] / (S['baseline'] * 0.5))})."]),
    ("Slide 6 - Delivery quality and customer value",
     ["Quality: all twelve periods generated so missing JIBs show as Pending; reversed documents handled; clearing date and document added; document-number navigation; no standard modification.",
      "Reuse: the same CDS-cube pattern is used for Bank Revaluation, the Treasury bank register and Per-Barrel analysis; abapGit ZIP delivery path proven; release constraints applied every time.",
      "Customer value: management sees JIB posting status per venture without Excel; client confirmed in writing 17/11/26; capacity released; money value = man-days x day rate (rate not recorded)."]),
    ("Slide 7 - Conclusion and replication",
     [f"Achievement: a client-confirmed management dashboard in 11 working days at {pc(J['red'])} less estimated effort, one of {S['n_counted']} AI-assisted use cases.",
      "Lessons: fresh source and production samples first; one object at a time with activation feedback; record every release constraint; claim only what the system confirms.",
      "Replication: PAL - workflow and upload fixes on the same loop; ONGC - further dashboard cards on the cube pattern; T&G - apply the toolkit once the project is mapped (the Astral work uses it already).",
      "Next steps: record test results for the 32 tier-B items; import and re-run the ATC batch; confirm the T&G mapping; log hours per object; share the toolkit with the team."]),
]
deck_blocks = [dict(t="h1", text="Success story presentation - slide content", pageBreak=True),
               dict(t="p", text="Text of the seven slides in AI_Success_Story_JIB_Status.pptx, so this document stands on its own.")]
for title, items in slides:
    deck_blocks += [dict(t="h3", text=title), dict(t="bullets", items=items)]

# ------------------------------------------------------------ Annex A: every use case in full
def card(o):
    eff = (f"Without AI {h1(o['baseline_h'])} h  |  with AI {h1(o['actual_h'])} h  |  saved {h1(o['saved_h'])} h = {o['saved_md']:.1f} man-days  |  "
           f"reduction {pc(o['red'])}  |  productivity +{o['prod'] * 100:.0f}%") if o["counted"] else \
        f"Not quantified - {o['tier_label']}. Indicative baseline {h1(o['baseline_h'])} h."
    rows = [
        ["Project", f"{o['project']}  (evidence: {o['evidence_client']})"],
        ["SAP object(s)", o["objects"]],
        ["Type / category / size", f"{o['dev_type']}  |  {o['category']}  |  {o['complexity']}" + (f"  |  scope x{o['scope']}" if o["scope"] != 1 else "")],
        ["Business requirement", o["requirement"]],
        ["Technical challenge", o["challenge"]],
        ["AI tool", o["ai_tool"]],
        ["AI contribution", o["ai"]],
        ["Manual intervention", o["manual"]],
        ["Corrections to AI output", f"{o['rework_count']} logged" + (f": {o['rework']}" if o["rework"] else "")],
        ["Effort", eff],
        ["Effort basis", o["basis"] + f"  (git session {o['session_h']:.2f} h; pre-repository {o['pre_h']:.0f} h; minimum {o['floor_h']} h)"],
        ["Delivery impact", o["impact"]],
        ["Quality improvement", o["quality"] or "-"],
        ["Completion status", f"{o['status']}  |  {o['tier_label']}" + (f"  |  TR {o['trs']}" if o["trs"] else "")],
        ["Confidence", o["confidence"]],
        ["Source evidence", o["folder"] + (f" (+ {o['merged']})" if o["merged"] else "") + "; " + o["evidence"]],
        ["Open items / missing information", o["open"] or "-"],
    ]
    return [dict(t="h3", text=f"{o['id']}  {o['title']}"),
            dict(t="table", widths=[22, 78], header=["Field", "Detail"], rows=rows, boldFirst=True, fontSize=7.5, cantSplit=True)]


annex_a = [dict(t="h1", text="Annex A - Every use case in full", pageBreak=True),
           dict(t="p", text=f"All {len(ROWS)} use cases of the register, grouped by project, with every field the evidence supports. "
                            "Hours are estimates (method in Annex B).")]
for p in P_ORDER:
    rs = [o for o in ROWS if o["project"] == p]
    if not rs:
        continue
    annex_a.append(dict(t="h2", text=f"{p} - {len(rs)} use case(s)"))
    for o in rs:
        annex_a += card(o)
annex_a += [dict(t="h2", text="T&G - 0 use cases"),
            dict(t="p", text="No document, issue log, commit message or timesheet in the repository names T&G. See report section 6.")]

# ------------------------------------------------------------ Annex B: method and assumptions
annex_b = [dict(t="h1", text="Annex B - Effort method and assumptions", pageBreak=True),
           dict(t="table", caption="Parameters", widths=[60, 20, 20], header=["Parameter", "Value", "Source"], numeric=[1],
                rows=[["Working days 19/08-19/11/26 (67 weekdays less 4 leave days)", str(S["working_days"]), "Calendar; leave 08-11/09"],
                      ["Hours per day", "8", "Request"],
                      ["Admin / non-development share", f"{S['admin_share'] * 100:.1f}%", "Filed September timesheet"],
                      ["Development hours available", h1(S["budget"]), "63 x 8 x (1 - share)"],
                      ["AI session hours measured in git", h1(S["session_total"]), "Commit work blocks"],
                      ["Allocation factor after minimum-effort floors", f"{S['uplift']:.4f}", "Solved: allocated hours = available hours"],
                      ["Allocation factor without floors (reference)", f"{S['raw_uplift']:.4f}", "Available / measured"],
                      ["Pre-repository dated day per stream", "4 h", "Two engagements in parallel"]]),
           dict(t="table", caption="Baseline rubric (hours without AI)", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
                header=["Work type", "Low", "Medium", "High", "Very High"],
                rows=[[R["rubric_label"][k]] + [str(v) for v in R["rubric"][k]] for k in R["rubric"]]),
           dict(t="table", caption="Minimum human effort per use case (hours)", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
                header=["Applies to", "Low", "Medium", "High", "Very High"],
                rows=[["Code deliveries (tiers A, B)"] + [str(v) for v in R["floor"]["code"]],
                      ["Analysis / design (tier C)"] + [str(v) for v in R["floor"]["analysis"]]]),
           dict(t="table", caption="ATC baseline parameters", widths=[70, 30], header=["Parameter", "Value"], numeric=[1],
                rows=[[k.replace("_", " "), str(v)] for k, v in R["atc"].items()] + [["ATC baseline (h)", h1(R["atc_baseline"])]]),
           dict(t="table", caption="Project attribution", widths=[35, 25, 40], header=["Evidence-based client", "Reporting project", "Note"],
                rows=[[R["evidence_client"][k], v, "Change to T&G if that is the reporting name" if k == "ASTRAL" else ""] for k, v in R["project_map"].items()]),
           dict(t="bullets", items=["Effort without AI = rubric x scope factor (ATC: correction blocks).",
                                    "Actual with AI = MAX(minimum floor, session hours x allocation factor + pre-repository hours) + rework allowance.",
                                    "Saved = without - with; reduction = saved / without; man-days = saved / 8; productivity improvement = without / with - 1.",
                                    "Totals are weighted by hours; recurring automation savings are kept separate and are not quantified (no execution data)."])]

# ------------------------------------------------------------ Annex C: ATC per program
progs = sorted(ATC["corrected_programs"], key=lambda p: -(p.get("boc_blocks_dated_08_08_2026") or 0))
annex_c = [dict(t="h1", text="Annex C - ATC corrected includes (ONGC)", pageBreak=True),
           dict(t="table", fontSize=7, widths=[26, 22, 12, 9, 9, 9, 9, 9], numeric=[3, 4, 5, 6, 7],
                header=["Include", "Parent program", "Package", "Lines", "Aug-26 blocks", "Changed hunks", "Audit candidates", "Likely activation failures"],
                rows=[[p["object"], str(p.get("parent") or ""), str(p.get("package") or ""), f"{p.get('lines') or 0:,}",
                       str(p.get("boc_blocks_dated_08_08_2026") or 0), str(p.get("diff_hunks") or 0), str(p.get("audit_findings") or 0),
                       str(p.get("audit_activation_candidates") or 0)] for p in progs],
                source="Validation: none of the 51 includes is recorded as imported, activated or re-run in ATC."),
           dict(t="table", caption="All reusable correction patterns in the knowledge base", fontSize=7, widths=[34, 66],
                header=["Finding family", "Correction pattern"],
                rows=[[p["category"], str(p.get("typical_fix", ""))[:260]] for p in ATC["finding_categories_resolved"]])]

# ------------------------------------------------------------ Annex D: index
annex_d = [dict(t="h1", text="Annex D - Use-case index", pageBreak=True),
           dict(t="table", fontSize=7, widths=[7, 16, 45, 18, 7, 7], numeric=[4, 5],
                header=["ID", "Project", "Use case", "Tier", "Saved (h)", "Red."],
                rows=[[o["id"], o["project"], o["title"], o["tier_label"], h1(o["saved_h"]), pc(o["red"]) if o["counted"] else "n/q"] for o in ROWS],
                source=f"Counted: {S['n_counted']} use cases, {h(S['saved'])} h ({md(S['saved'])} man-days) saved, {pc(S['red'])} weighted reduction.")]

contents = ["Management summary (e-mail text)", "1. Executive summary", "2. Scope, sources and method", "3. AI consumption",
            "4. PAL project", "5. ONGC Videsh (OVL) project", "6. T&G project and the Astral (Project UDAY) engagement",
            "7. Technical classification", "8. ATC correction and technical-debt reduction", "9. Automation and reusable development",
            "10. Quantified effort and productivity analysis", "11. Development quality and delivery improvement", "12. Customer benefits",
            "13. Case study - JIB Status", "14. Conclusions and next steps", "Success story presentation - slide content",
            "Annex A - Every use case in full", "Annex B - Effort method and assumptions", "Annex C - ATC corrected includes",
            "Annex D - Use-case index"]
cover = dict(noHeader=True, blocks=[
    dict(t="cover", kicker="MANAGEMENT SUBMISSION - COMPLETE REPORT", title="AI Utilisation in SAP ABAP Delivery",
         subtitle="PAL, ONGC Videsh (OVL) and other engagements - everything the records show, 20 July to 19 November 2026",
         lines=["**Prepared by:** Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global", "**Reporting cut-off:** 19 November 2026",
                "**AI tool:** Claude Code (Anthropic)",
                f"**Headline (estimates):** {S['n_counted']} use cases, {md(S['saved'])} man-days saved, {pc(S['red'])} weighted effort reduction"]),
    dict(t="pagebreak"), dict(t="h2", text="Contents"), dict(t="bullets", items=contents, size=19)] + mail_blocks)
first = rep_sections[0]
first["blocks"] = [dict(first["blocks"][0], pageBreak=True)] + first["blocks"][1:]
last = rep_sections[-1]
last["blocks"] = last["blocks"] + deck_blocks + annex_a + annex_b + annex_c + annex_d
doc = dict(title="AI Utilisation in SAP ABAP Delivery - Complete Report", header="AI utilisation in SAP ABAP delivery - complete report | 19 November 2026",
           footer="Prepared by Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri", sections=[cover] + rep_sections)
json.dump(doc, open(os.path.join(D, "combined.json"), "w"), indent=1)
print("sections", len(doc["sections"]), "cards", len(ROWS))
