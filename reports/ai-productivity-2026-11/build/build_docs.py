"""Content for the assessment report, the evidence annexure and the management mail.
python3 -I build_docs.py   -> data/report.json, data/annexure.json, ../Management_Summary_Email.md
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "data")
R = json.load(open(os.path.join(D, "register.json")))
U = json.load(open(os.path.join(D, "usage.json")))
ATC = json.load(open(os.path.join(D, "inv_atc.json")))
S, ROWS = R["summary"], R["rows"]
C = [o for o in ROWS if o["counted"]]
h = lambda x: f"{x:,.0f}"
h1 = lambda x: f"{x:,.1f}"
pc = lambda x: f"{x * 100:.0f}%"
md = lambda x: f"{x / 8:,.0f}"
BP = S["by_project"]
P_ORDER = ["PAL", "ONGC (OVL)", "KPMG - Astral (UDAY)", "Cross-project", "Attribution pending"]
JIB = next(o for o in ROWS if o["folder"] == "ovl/zfi_jib_status")
ATCROW = next(o for o in ROWS if o["work"] == "ATC")
A_, B_, C_ = S["tier_A"], S["tier_B"], S["tier_C"]
sens = [(f, S["baseline"] * f - S["actual"], 1 - S["actual"] / (S["baseline"] * f)) for f in (0.7, 0.5)]
cnt = lambda rows, key, vals: len([o for o in rows if o[key] in vals])


def proj_rows(p):
    return [o for o in ROWS if o["project"] == p]


def uc_table(rows, caption):
    return dict(t="table", caption=caption, fontSize=7, widths=[5, 22, 34, 11, 6, 6, 6, 5],
                header=["ID", "Use case / SAP objects", "AI contribution", "Status / tier", "Without AI (h)", "With AI (h)", "Saved (h)", "Red."],
                numeric=[4, 5, 6, 7],
                rows=[[o["id"], f"**{o['title']}**\n{o['objects']}", o["ai"], f"{o['status']}\n{o['tier_label']}", h1(o["baseline_h"]),
                       h1(o["actual_h"]), h1(o["saved_h"]), pc(o["red"]) if o["counted"] else "n/q"] for o in rows],
                source="Source: Master Register (AI_Use_Case_Register.xlsx). Hours are estimates: rubric baseline vs git-measured session time "
                       "allocated over available working hours, with a minimum-effort floor. n/q = not quantified.")


def totals_row(rows, label):
    b, a, s = sum(o["baseline_h"] for o in rows if o["counted"]), sum(o["actual_h"] for o in rows if o["counted"]), sum(o["saved_h"] for o in rows if o["counted"])
    return [label, h(b), h(a), h(s), md(s), pc(s / b) if b else "-"]


def short(t, n):
    if len(t) <= n:
        return t
    c = t[:n]
    k = c.rfind(". ")
    return c[: k + 1] if k > n * 0.5 else c.rsplit(" ", 1)[0] + "..."


def highlights(rows, n=6):
    top = sorted([o for o in rows if o["counted"]], key=lambda o: -o["saved_h"])[:n]
    return dict(t="bullets", items=[f"**{o['title']}** ({o['id']}, {o['tier_label'].split(' - ')[1].lower()}; {h(o['saved_h'])} h saved): " + short(o['ai'], 260) for o in top], size=19)


project_summary = dict(t="table", caption="Effort by project (counted use cases)", widths=[30, 12, 12, 12, 12, 12, 10],
                       header=["Project", "Use cases", "Without AI (h)", "With AI (h)", "Saved (h)", "Saved (man-days)", "Reduction"],
                       numeric=[1, 2, 3, 4, 5, 6], totalRow=True,
                       rows=[[p, str(BP[p]["n"]), h(BP[p]["baseline"]), h(BP[p]["actual"]), h(BP[p]["saved"]), md(BP[p]["saved"]),
                              pc(BP[p]["saved"] / BP[p]["baseline"])] for p in P_ORDER if p in BP] +
                            [["T&G", "0", "-", "-", "-", "-", "-"]] +
                            [["Total", str(S["n_counted"]), h(S["baseline"]), h(S["actual"]), h(S["saved"]), md(S["saved"]), pc(S["red"])]],
                       source="Weighted reduction = total saved / total baseline. T&G: no evidence in the repository (section 6).")
tier_table = dict(t="table", caption="Effort saved by evidence tier", widths=[38, 10, 13, 13, 13, 13],
                  header=["Tier", "Use cases", "Without AI (h)", "With AI (h)", "Saved (h)", "Saved (man-days)"], numeric=[1, 2, 3, 4, 5],
                  totalRow=True,
                  rows=[["A - Confirmed in system (activated, tested, deployed or confirmed by the user)", str(A_["n"]), h(A_["baseline"]), h(A_["actual"]), h(A_["saved"]), md(A_["saved"])],
                        ["B - Delivered, verification pending", str(B_["n"]), h(B_["baseline"]), h(B_["actual"]), h(B_["saved"]), md(B_["saved"])],
                        ["C - Analysis / root cause / design delivered", str(C_["n"]), h(C_["baseline"]), h(C_["actual"]), h(C_["saved"]), md(C_["saved"])],
                        ["Total", str(S["n_counted"]), h(S["baseline"]), h(S["actual"]), h(S["saved"]), md(S["saved"])]])
cat_counts = {}
for o in C:
    cat_counts.setdefault(o["category"], []).append(o)
cat_table = dict(t="table", caption="Technical classification of the counted use cases", widths=[28, 8, 12, 52], numeric=[1, 2],
                 header=["Category", "Use cases", "Saved (h)", "Examples"],
                 rows=[[k, str(len(v)), h(sum(o["saved_h"] for o in v)), "; ".join(o["title"].split(" - ")[0].split(":")[0][:48] for o in v[:3])]
                       for k, v in sorted(cat_counts.items(), key=lambda kv: -sum(o["saved_h"] for o in kv[1]))])
rubric = dict(t="table", caption="Baseline rubric: conventional effort without AI (hours)", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
              header=["Work type", "Low", "Medium", "High", "Very High"],
              rows=[[R["rubric_label"][k]] + [str(v) for v in R["rubric"][k]] for k in R["rubric"]],
              source="Covers requirement study, design, coding, debugging, unit test and technical documentation by an associate consultant "
                     "without AI. A scope factor (1.0-2.0) on multi-object rows is stated in the register.")
usage_table = dict(t="table", caption="AI consumption measured in the repository", widths=[52, 18, 50], numeric=[],
                   header=["Measure", "Value", "Source"], rows=[[m[0], f"{m[1]:,}" if isinstance(m[1], int) else str(m[1]), m[2]] for m in U["metrics"]])
month_table = dict(t="table", caption="Monthly AI-assisted activity (repository period)", widths=[30, 22, 18, 30], numeric=[1, 2, 3],
                   header=["Month", "AI session hours (git)", "Active days", "Commits on client folders"],
                   rows=[[m[0], h1(m[1]), str(m[2]), str(m[3])] for m in U["monthly"]])

aa = ATC
funnel = dict(t="table", caption="ATC funnel - identified, corrected, implemented, validated", widths=[46, 12, 52], numeric=[1],
              header=["Stage", "Count", "Evidence / state"],
              rows=[["System-wide findings, ATC export 09/06/26 (context - whole team)", "10,165", "1,403 objects; P1 3,306 / P2 960 / P3 5,899"],
                    ["System-wide findings, export to 03/08/26 (context - whole team)", "5,220", "640 objects; the June reduction is in-system work and is not claimed"],
                    ["Findings assigned to Arnav, worked 05-14/08/26", "847", "Work log and handoff; not reproducible from the exports in the repository"],
                    ["AI-assisted correction blocks applied", "205", "107 pragma-only, 65 replaced with the original commented, 33 new code; 833 lines added / changed"],
                    ["Includes delivered (43 programs, 14 packages)", "51", "abapGit layout and upload procedure prepared"],
                    ["Findings set aside for decision", "26", "Manual review list: P1 field-length decisions, XK01 BDC, BSEG statements"],
                    ["Rule-audit candidates found in the AI corrections (23/08)", "433", "41 of 51 objects; 46 likely activation failures in 18 objects"],
                    ["Imported / activated / ATC re-run in the system", "0", "None recorded - tier B. Closure is proven only by an ATC re-run."],
                    ["Reusable correction patterns documented", str(aa["reusable_patterns_count"]), "Knowledge base plus 31 activation / runtime rules"]])
patterns = dict(t="table", caption="Recurring finding families and the reusable AI-assisted correction pattern (selection)", widths=[34, 66], fontSize=7,
                header=["Finding family", "Correction pattern"],
                rows=[[p["category"], str(p.get("typical_fix", ""))[:200]] for p in aa["finding_categories_resolved"][:18]])
errs = [e for e in aa["errors_introduced_and_fixed"]][:6]
err_table = dict(t="table", caption="Errors introduced during remediation and how they were handled", widths=[12, 22, 38, 28], fontSize=7,
                 header=["Date", "Program", "What went wrong", "Handling"],
                 rows=[[e.get("date", ""), str(e.get("program", ""))[:60], str(e.get("what_broke", ""))[:230], str(e.get("how_fixed", ""))[:170]] for e in errs])
autos = [o for o in ROWS if o["automation"] or o["work"] == "TOOL"]
auto_table = dict(t="table", caption="Automation solutions and reusable developer tools", widths=[8, 30, 14, 36, 12], fontSize=7,
                  header=["ID", "Automation / tool", "Project", "Manual process replaced", "Status"],
                  rows=[[o["id"], o["title"], o["project"], o["auto_process"] or o["requirement"], o["tier_label"]] for o in autos],
                  source="Recurring savings are not quantified: no execution counts or minutes per run are recorded. Enter them on the "
                         "Automation Benefits sheet to compute; they stay separate from development savings.")
nq = [o for o in ROWS if o["tier"] == "NQ"]
excluded = dict(t="table", caption="Reviewed and not counted", widths=[28, 72], fontSize=7, header=["Folder", "Reason"],
                rows=[[o["folder"], f"{o['title']} - delivered in the AI period, but no session or time record exists."] for o in nq] +
                     [[k, v] for k, v in R["excluded"].items()])
quality = [
    "**Root cause before code.** ZMM_TMS_STATUS: a blank Excel export traced to no_out = '0' on all 44 field-catalog entries - one constant changed, confirmed on DEV the same day (28/10/26). CJ88 and FBV0 update errors were proven to sit in standard SAP from ST22 / SM13 / ST05 evidence, so no custom code was changed.",
    "**S/4HANA-compatible replacements.** ZAA_IMPAIRMENTLOSS: ECC batch input on ABAA / ABZU (dead on S/4) replaced by FI-AA BAPIs with check-then-post per asset; activated and verified against a closed fiscal year (27/08/26).",
    "**Better SQL.** ZFITAX_PBT_CALC_PRG: rows lost to the implicit DISTINCT of FOR ALL ENTRIES on a compatibility view - replaced by a range; IS NOT INITIAL guards before every FOR ALL ENTRIES; strict Open SQL across the ATC batch.",
    "**No modification of SAP standard.** PAL Ariba PO rounding solved in a released BAdI (ME_BAPI_PO_CUST); Fiori PO value helps added through enhancements calling Z classes; asset fields through CDS extensions.",
    "**Error paths give messages, not dumps.** Upload and posting programs (ZFI_ACDOCA_JVA_ALIGN, ZFI_ACDOCA_VNAME_UPD, ZBC_TADIR_SRCSYS_CHANGE) default to test run and stop with a message; PAL invoice mail checks every return code before attaching a PDF.",
    "**Requirements challenged before build.** WRICEF 141: 16 FS questions; WRICEF 147: 21 queries (15 blocking) and a feasibility verdict; Paints forecast: 28 FS defects listed before code.",
    f"**Documentation as a by-product.** {U['metrics'][13][1]} issue-log entries (issue, cause, fix), {U['metrics'][15][1]} technical specification files and a NOTES file per object give the next consultant a complete trail.",
    f"**AI errors are caught and turned into rules.** {U['metrics'][14][1]} rework events are recorded across the counted use cases - activation errors, wrong assumptions, dumps. Each is fixed in the next delivery, and 56 release constraints plus 31 written-up mistakes are applied before new code is written.",
]
delivery = [
    "ZFI_JIB_STATUS: requirement 03/11/26, Fiori query running on the first model 04/11, client confirmation 'working well and meeting expectations' 17/11 - after two client test rounds and four additions.",
    "ZMM_BP_CREATE_MAIL: FS answers received 25/09/26; report built, activated on first paste and first mail run the same day.",
    "ZFORECAST Paints: FS received 19/10/26; DDIC, engine class, report and upload imported and activated by 22/10/26.",
    "ZFI_TDS_CL34 (Clause 34): built from the FS on 26/08/26; first live run with reconciled arithmetic on 27/08/26.",
    "ZFI_BNK_APP1 / ZBNK_APP2: two OVL bank-approval defects diagnosed, fixed and activated in OCQ on the day they were raised (27/08/26).",
]

exec_kpis = dict(t="kpis", items=[
    dict(value=str(S["n_counted"]), label="AI-assisted use cases", note=f"{cnt(C, 'work', ['NEW'])} new developments, 51-include ATC batch"),
    dict(value=md(S["saved"]), label="Man-days saved (est.)", note=f"{h(S['saved'])} h; {md(A_['saved'])} on work confirmed in system"),
    dict(value=pc(S["red"]), label="Weighted effort reduction", note=f"{h(S['baseline'])} h conventional vs {h(S['actual'])} h with AI"),
    dict(value=f"{S['prod'] + 1:.1f}x", label="Delivery throughput", note=f"productivity improvement {S['prod'] * 100:,.0f}%"),
])
report = dict(
    title="AI Utilisation and Productivity Report - SAP ABAP Delivery", header="AI utilisation and productivity - SAP ABAP delivery | 19 November 2026",
    footer="Prepared by Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri",
    sections=[
        dict(noHeader=True, blocks=[
            dict(t="cover", kicker="MANAGEMENT SUBMISSION", title="AI Utilisation, Productivity Improvement and Delivery Efficiency",
                 subtitle="SAP ABAP delivery for PAL, ONGC Videsh (OVL) and other engagements - historical assessment, 20 July to 19 November 2026",
                 lines=["**Prepared by:** Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global",
                        "**Reporting cut-off:** 19 November 2026", "**AI tool assessed:** Claude Code (Anthropic)",
                        "**Companion files:** AI_Use_Case_Register.xlsx, AI_Success_Story_JIB_Status.pptx, Evidence_and_Estimation_Annexure.docx"]),
            dict(t="pagebreak"), dict(t="toc"), dict(t="pagebreak"),
            dict(t="h1", text="1. Executive summary"),
            exec_kpis,
            dict(t="p", text=f"Between 20 July and 19 November 2026 I used Claude Code as a working partner on {S['n_counted']} distinct SAP ABAP use cases across "
                             f"ONGC Videsh ({BP['ONGC (OVL)']['n']}), PAL ({BP['PAL']['n']}) and the Astral / Project UDAY engagement through KPMG "
                             f"({BP['KPMG - Astral (UDAY)']['n']}), plus {BP['Cross-project']['n'] + BP['Attribution pending']['n']} reusable or not-yet-attributed items. "
                             "The work covers complete applications (CDS / RAP dashboards, a credit-memo approval workflow, forecasting), new reports and "
                             "interfaces, enhancements, S/4HANA remediation of 51 program includes, root-cause analysis of production issues, and the "
                             "toolkit that makes the AI loop repeatable."),
            dict(t="p", text=f"Estimated conventional effort for this work is **{h(S['baseline'])} hours**; the AI-assisted effort, which counts every "
                             f"development hour available in the period, is **{h(S['actual'])} hours**. That is **{h(S['saved'])} hours ({md(S['saved'])} man-days) "
                             f"saved, a {pc(S['red'])} weighted reduction**. Of this, {h(A_['saved'])} hours ({md(A_['saved'])} man-days) sit on "
                             f"{A_['n']} use cases already confirmed in the system (activated, tested, deployed or confirmed by the user or client)."),
            project_summary,
            dict(t="h3", text="How to read the numbers"),
            dict(t="bullets", items=[
                "Every use case traces to a repository folder, its issue log and its commits. Nothing is counted without that trail.",
                "Baselines are estimates from a stated rubric. Actual effort comes from commit timestamps and is scaled so that it adds up to all development time available in the period. That deliberately overstates the AI-assisted side.",
                f"Sensitivity: if conventional baselines were 30% lower, savings would be {h(sens[0][1])} hours ({md(sens[0][1])} man-days, {pc(sens[0][2])}); if 50% lower, {h(sens[1][1])} hours ({md(sens[1][1])} man-days, {pc(sens[1][2])}).",
                f"Tier B items ({B_['n']}) are delivered but have no activation or test result in the logs yet. ATC corrections are not yet imported or re-run in ATC, and are not presented as closed findings.",
                "T&G: no document, log or commit in the repository names this project. The Astral (UDAY) engagement is reported separately and can be re-mapped in one cell of the register.",
            ]),
            dict(t="h3", text="Strongest example"),
            dict(t="p", text=f"ONGC Videsh Management Dashboard 'JIB Status' (ZFI_JIB_STATUS): eight CDS views with an analytical cube, built from a requirement "
                             f"workbook on 03/11/26 and confirmed by the client on 17/11/26 as 'working well and meeting expectations'. Estimated "
                             f"{h(JIB['baseline_h'])} h conventionally against {h(JIB['actual_h'])} h with AI ({pc(JIB['red'])} less). Case study in section 13 and the deck."),
            dict(t="h1", text="2. Scope, sources and method", pageBreak=True),
            dict(t="h2", text="Sources reviewed"),
            dict(t="bullets", items=[
                f"The consolidated work repository: {len(ROWS)} use-case records built from 77 folders across ovl/, pal/, kpmg/, tools/ and research/; every ISSUES.md and NOTES.md read in full.",
                f"Git history of all 66 branches: {U['metrics'][5][1]} commits, {U['metrics'][6][1]} co-authored by the AI, 19/08-19/11/26, including 60 commits on session branches not yet merged.",
                "The Claude Code handoff record (30 sessions, 557 prompts, 20/07-15/08/26) and the August OVL work log (day-wise, 03-31/08/26).",
                "ATC exports (09/06/26 and to 03/08/26), the manual review list, the remediation knowledge base, the rule audit (23/08/26) and the handover.",
                "The filed client timesheets (August and September 2026), used for the admin share and dated pre-repository activity only.",
            ]),
            dict(t="h2", text="Access limitations"),
            dict(t="bullets", items=U["gaps"]),
            dict(t="h2", text="Effort method"),
            dict(t="numbered", items=[
                "**Effort without AI** = rubric hours for the work type and complexity x scope factor. The ATC row instead uses the correction blocks actually applied (section 8).",
                f"**Actual effort with AI** = MAX(minimum-effort floor, git session hours x {S['uplift']:.2f} + dated pre-repository hours) + any rework allowance. "
                f"The factor is set so that the hours allocated across all use cases equal the {S['budget']:.0f} development hours available in the period "
                f"({S['working_days']} working days x 8 h, less the {S['admin_share'] * 100:.1f}% admin share from the filed timesheet).",
                "**Saved** = without - with; **reduction** = saved / without; **man-days** = saved / 8; **productivity improvement** = without / with - 1.",
                "Project totals are weighted (summed hours), never an average of row percentages. Recurring automation savings are kept separate.",
            ]),
            rubric,
            dict(t="p", text="Minimum human effort per use case (prompting, review, paste / activation, unit test): 2 / 4 / 8 / 16 hours for Low / Medium / High / Very High code deliveries, "
                             "and 1 / 2 / 4 / 6 hours for analysis-only items.", size=18),
            dict(t="h2", text="Project attribution"),
            dict(t="bullets", items=[
                "**PAL** - the pal/ folders, plus the FB70 credit-memo approval workflow filed under kpmg/: its mails are sent from PAL's Accounts Payable mailbox and it runs on PAL's DS4 system.",
                "**ONGC (OVL)** - the ovl/ folders and ATC remediation, plus kpmg/zmm_me35k_release (system OCQ) and kpmg/zmmims (company codes OVL / OVC), the August work-log items and the tools written for OVL systems.",
                "**KPMG - Astral (Project UDAY)** - every other kpmg/ folder names Astral Limited / Project UDAY. It is not one of the three projects named in the request; see section 6.",
                "**Cross-project** - developer tools and the delivery toolkit. **Attribution pending** - one BAdI whose notes say the client is not yet confirmed.",
            ]),
            dict(t="h1", text="3. AI consumption", pageBreak=True),
            dict(t="p", text="The repository records how intensively the AI was used. Token and cost data are not stored there, so consumption is measured by sessions, prompts, commits and output."),
            usage_table, month_table,
            dict(t="h1", text="4. PAL project - AI use cases", pageBreak=True),
            dict(t="p", text=f"{BP['PAL']['n']} use cases; {h(BP['PAL']['saved'])} hours ({md(BP['PAL']['saved'])} man-days) saved, {pc(BP['PAL']['saved'] / BP['PAL']['baseline'])} reduction; "
                             f"{h(BP['PAL']['confirmed_saved'])} hours on work confirmed in system. Systems DS4 -> QS4 -> PS4; incidents INC01192, INC01740, INC01967."),
            highlights(proj_rows("PAL"), 4),
        ]),
        dict(orientation="landscape", blocks=[uc_table(proj_rows("PAL"), "PAL - use-case detail")]),
        dict(blocks=[
            dict(t="h1", text="5. ONGC Videsh (OVL) project - AI use cases"),
            dict(t="p", text=f"{BP['ONGC (OVL)']['n']} counted use cases (plus {BP['ONGC (OVL)']['n_all'] - BP['ONGC (OVL)']['n']} not quantified); "
                             f"{h(BP['ONGC (OVL)']['saved'])} hours ({md(BP['ONGC (OVL)']['saved'])} man-days) saved, "
                             f"{pc(BP['ONGC (OVL)']['saved'] / BP['ONGC (OVL)']['baseline'])} reduction; {h(BP['ONGC (OVL)']['confirmed_saved'])} hours on work confirmed in system. "
                             "The work spans S/4HANA-era analytics on CDS (JIB status, bank revaluation, per-barrel analysis, Group Reporting remaps), the DPR Fiori dashboard "
                             "and CPI interface, FI / JVA posting and reconciliation programs, ATC remediation, and root-cause analysis of production and Mock-2 issues."),
            highlights(proj_rows("ONGC (OVL)"), 8),
        ]),
        dict(orientation="landscape", blocks=[uc_table(proj_rows("ONGC (OVL)"), "ONGC Videsh (OVL) - use-case detail")]),
        dict(blocks=[
            dict(t="h1", text="6. T&G project and the Astral (Project UDAY) engagement"),
            dict(t="note", text="**T&G - no evidence found.** Every issue log, note, commit message on all branches, both timesheets and the handoff record "
                                "were searched for 'T&G', 'T & G' and 'T and G': there is no occurrence. No use case is attributed to T&G on the evidence. "
                                "If the Astral / Project UDAY engagement (via KPMG) is the one reported as T&G, change one cell (Effort Assumptions, section 4) "
                                "in the register and the dashboard follows. The figures below then become the T&G figures."),
            dict(t="p", text=f"**KPMG - Astral (Project UDAY):** {BP['KPMG - Astral (UDAY)']['n']} counted use cases (plus 1 not quantified); "
                             f"{h(BP['KPMG - Astral (UDAY)']['saved'])} hours ({md(BP['KPMG - Astral (UDAY)']['saved'])} man-days) saved, "
                             f"{pc(BP['KPMG - Astral (UDAY)']['saved'] / BP['KPMG - Astral (UDAY)']['baseline'])} reduction; "
                             f"{h(BP['KPMG - Astral (UDAY)']['confirmed_saved'])} hours on work confirmed in system. WRICEFs ID-2A / ID-2B (ZFORECAST), 141 A/B, 337 (Clause 34 TDS), "
                             "050 (PO budget), 057 (BP mail), 147 (CC MIS) and 195 (MB5B)."),
            highlights(proj_rows("KPMG - Astral (UDAY)"), 6),
        ]),
        dict(orientation="landscape", blocks=[uc_table(proj_rows("KPMG - Astral (UDAY)"), "KPMG - Astral (Project UDAY) - use-case detail"),
                                              uc_table(proj_rows("Cross-project") + proj_rows("Attribution pending"),
                                                       "Cross-project components and attribution pending")]),
        dict(blocks=[
            dict(t="h1", text="7. Technical classification"),
            cat_table,
            dict(t="h1", text="8. ATC correction and technical-debt reduction (ONGC)", pageBreak=True),
            dict(t="p", text=f"The ATC stream is reported as a funnel so that corrections made are never confused with findings closed. Baseline {h(ATCROW['baseline_h'])} h "
                             f"(205 blocks at 15 / 45 / 60 minutes by type, 0.5 h per include, 16 h packaging and knowledge base) against {h(ATCROW['actual_h'])} h with AI "
                             f"(28 h of dated work-log time plus an 11.5 h allowance to rework the 46 likely activation failures): {h(ATCROW['saved_h'])} h saved, tier B."),
            funnel, patterns, err_table,
            dict(t="p", text="Reuse without double counting: the patterns were derived once and applied across the batch. The saving is computed from the blocks "
                             "actually applied, not by multiplying a per-pattern saving by the number of programs.", size=18),
            dict(t="h1", text="9. Automation and reusable development", pageBreak=True),
            auto_table,
            dict(t="h1", text="10. Quantified effort and productivity analysis", pageBreak=True),
            tier_table, project_summary,
            dict(t="table", caption="Sensitivity of the headline", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
                 header=["Scenario", "Without AI (h)", "With AI (h)", "Saved (man-days)", "Reduction"],
                 rows=[["As estimated", h(S["baseline"]), h(S["actual"]), md(S["saved"]), pc(S["red"])],
                       ["Baselines 30% lower", h(S["baseline"] * 0.7), h(S["actual"]), md(sens[0][1]), pc(sens[0][2])],
                       ["Baselines 50% lower", h(S["baseline"] * 0.5), h(S["actual"]), md(sens[1][1]), pc(sens[1][2])]]),
            dict(t="p", text="Cycle time is reported separately from person-hours: see section 11 and the Delivery impact column of the register."),
            dict(t="h1", text="11. Development quality and delivery improvement"),
            dict(t="bullets", items=quality),
            dict(t="h3", text="Turnaround examples"),
            dict(t="bullets", items=delivery),
            dict(t="p", text="Claims not made: fewer production defects or faster releases. No release or defect data is in the repository.", size=18),
            dict(t="h1", text="12. Customer benefits", pageBreak=True),
            dict(t="bullets", items=[
                f"**Capacity released:** an estimated {md(S['saved'])} man-days of conventional effort were not needed for the work delivered. On the 50%-lower baseline it is still {md(sens[1][1])} man-days.",
                "**More work with the same resource:** one associate consultant covered three engagements concurrently, with several objects in flight on most days (58 active AI-session days in the repository period).",
                "**Shorter time to testing:** first testable versions typically the same or next working day (section 11), so functional testing starts earlier.",
                "**Reusable assets:** ATC correction patterns, release constraints, source-download and enhancement-finder tools, abapGit delivery path, the forecast engine reused for Paints, the workflow class pattern reused from GL to credit memo.",
                "**Commercial value:** no day rates are recorded, so no money value is stated. Potential effort value = man-days saved x applicable rate (Dashboard cell). It is not an invoiced saving: under fixed price it shows up as margin or released capacity; under time and material it depends on the billing arrangement.",
            ]),
            dict(t="h1", text="13. Case study - ONGC Videsh Management Dashboard 'JIB Status'", pageBreak=True),
            dict(t="table", caption="Case study at a glance", widths=[30, 70], header=["Item", "Detail"], boldFirst=True,
                 rows=[["Project / object", "ONGC Videsh (OVL) - ZFI_JIB_STATUS: ZI_JIB_STATUS_CUBE plus seven supporting CDS views (ZI_JIB_DOC, ZI_JIB_DOC_AGG, ZI_JIB_YEAR_AGG, ZI_JIB_QTR_AGG, ZI_JIB_CLEARING, ZI_JIB_PERIOD, ZI_JIB_VENTURE)"],
                       ["Business requirement", "Management dashboard card: for each joint venture, is the period's JIB posted and when was it entered - by month, quarter or fiscal year, with document drill-down (Fiori Custom Analytical Query)."],
                       ["Technical complexity", "No venture on BKPF; JIB identified by document type from a GS01 set; reversals; months without a JIB must still show as Pending; entry date vs posting period; older S/4 release limits on CDS; delivery by abapGit ZIP to a system without ADT access."],
                       ["Conventional approach", f"Analyse BKPF / BSEG / JV data in SE16N, design the views by trial activation, build and test each layer, rebuild on feedback - estimated {h(JIB['baseline_h'])} h (Very High new development)."],
                       ["How AI was used", "Read the requirement workbook and production sample documents; designed the data model; wrote all eight views and the ZIP; rebuilt the model twice on client feedback (entry date model 04/11, posting period at document grain 06/11); added year / quarter aggregates, reversal handling, clearing data, navigation annotation and the all-ventures extension."],
                       ["Human review and validation", "Arnav confirmed the document-type set in GS03 and SE16N, imported and activated the views, worked with the GR consultant on the query, relayed two client test rounds, and fixed the launchpad navigation setting."],
                       ["Result", f"Client (Corporate Accounts), 17/11/26: 'working well and meeting expectations'. {JIB['commits']} commits over {JIB['active_days']} active days; 13 logged issues and changes handled; 1,110 lines of CDS."],
                       ["Effort", f"{h(JIB['baseline_h'])} h conventional vs {h(JIB['actual_h'])} h with AI: {h(JIB['saved_h'])} h ({h(JIB['saved_h'] / 8)} man-days) saved, {pc(JIB['red'])} reduction."],
                       ["Timeline", "Requirement 03/11/26 -> first query running 04/11 -> client tests 06/11 -> navigation fixed 12/11 -> client confirmation 17/11 (11 working days, including four client additions)."],
                       ["Lessons", "One object at a time with activation feedback; release constraints recorded once and reused; production samples checked line by line before the model is fixed; client test data drives the rebuild."]]),
            dict(t="h1", text="14. Conclusions and next steps"),
            dict(t="bullets", items=[
                f"AI assistance is part of daily delivery, not a side experiment: {U['metrics'][6][1]} AI-assisted commits on 58 days, {S['n_counted']} use cases, three engagements in parallel.",
                f"The supportable effort reduction is {pc(S['red'])} on the estimates, and still {pc(sens[1][2])} if baselines are halved. {md(A_['saved'])} man-days of it are on work already confirmed in the system.",
                "The gain comes from speed of first build and of root-cause analysis. It depends on human control: fresh source download before every change, activation feedback, functional confirmation, and a standing record of release constraints.",
                f"Next steps: (1) record activation / test results for the {B_['n']} tier-B items, which moves them to confirmed; (2) import the ATC batch and re-run ATC; (3) confirm the reporting project for the Astral engagement (T&G?); (4) log hours per object from now on, to replace estimates with actuals; (5) roll the toolkit (rules, memory, skills) out to the team.",
            ]),
            dict(t="h2", text="Reviewed and not counted"),
            excluded,
        ]),
    ])

ann_rows = [[o["id"], o["project"], o["folder"] + (f"\n(+ {o['merged']})" if o["merged"] else ""), o["title"], short(o["evidence"].replace("; ", "\n"), 200),
             f"{o['status']}\n{o['first']} -> {o['last']}", o["basis"],
             f"{o['work']} / {o['complexity']} / x{o['scope']}", o["confidence"], short(o["open"], 170) or "-"] for o in ROWS]
annexure = dict(
    title="Evidence and Estimation Annexure", header="Evidence and estimation annexure | AI utilisation report | 19 November 2026",
    footer="Annexure to the AI Utilisation and Productivity Report - Arnav Johri", author="Arnav Johri",
    sections=[dict(orientation="landscape", blocks=[
        dict(t="h1", text="Evidence and estimation annexure"),
        dict(t="p", text="Traceability for every use case in the register: source folder and files, evidence of completion, the basis of the effort estimate, "
                         "the assumptions applied (work type / complexity / scope factor), confidence and missing information. Folder paths are relative to the "
                         "work repository; commit hashes are listed in the git history of each folder."),
        dict(t="table", fontSize=6.5, widths=[5, 7, 11, 16, 17, 10, 10, 6, 7, 14],
             header=["ID", "Project", "Folder", "Development / correction", "Evidence files", "Completion", "Effort basis", "Assumptions", "Confidence", "Missing information"],
             rows=ann_rows),
        dict(t="h2", text="Global assumptions"),
        dict(t="bullets", items=[
            f"Working days {S['working_days']} (19/08-19/11/26, 4 days leave), 8 h per day, admin share {S['admin_share'] * 100:.1f}% (filed September timesheet).",
            f"Session hours measured: {S['session_total']} h; allocation factor {S['uplift']} after minimum-effort floors; hours allocated equal the available {S['budget']} h.",
            "Pre-repository dated days (20/07-18/08/26): 4 h per stream-day, from the handoff, work log and timesheet narrative.",
            "Baseline rubric and floors as in the report, section 2. ATC baseline from correction blocks (report, section 8).",
        ]),
        dict(t="h2", text="Verification gaps"), dict(t="bullets", items=U["gaps"]),
    ])])
json.dump(report, open(os.path.join(D, "report.json"), "w"), indent=1)
json.dump(annexure, open(os.path.join(D, "annexure.json"), "w"), indent=1)

mail = f"""Subject: AI utilisation in SAP ABAP delivery - PAL, ONGC (OVL) and other engagements (to 19 Nov 2026)

Dear [Manager name],

As requested in your mail of 19 November, please find my assessment of AI use in my SAP ABAP work from 20 July to 19 November 2026. The AI tool is Claude Code (Anthropic).

- AI-assisted use cases: {S['n_counted']} - ONGC (OVL) {BP['ONGC (OVL)']['n']}, PAL {BP['PAL']['n']}, KPMG - Astral (Project UDAY) {BP['KPMG - Astral (UDAY)']['n']}, cross-project tools {BP['Cross-project']['n'] + BP['Attribution pending']['n']}. T&G: no item is linked to it in my records (please see note below).
- Significant applications: ONGC JIB Status management dashboard (client-confirmed 17/11), DPR Fiori dashboard and CPI interface, bank revaluation and per-barrel analytics on CDS, PAL FB70 credit-memo approval workflow, Astral ZFORECAST (Adhesive and Paints), Exceptional Approval (WRICEF 141), Clause 34 TDS report.
- ATC: 205 correction blocks across 51 includes (43 programs, 14 packages) against 847 assigned findings, with 76 reusable correction patterns. Packaged for import; activation and the ATC re-run are pending, so these are not yet reported as closed findings.
- Automation and tools: {len(autos)} automations / utilities, e.g. daily BP-creation mail, mass uploads, source mass-download and enhancement-finder tools.
- Effort: estimated {h(S['baseline'])} h conventional vs {h(S['actual'])} h with AI, i.e. **{md(S['saved'])} man-days saved, {pc(S['red'])} weighted reduction**. {md(A_['saved'])} man-days of this are on work already confirmed in the system. Even if the conventional baselines were 50% lower, the saving stays at {md(sens[1][1])} man-days ({pc(sens[1][2])}).
- Delivery: first testable versions typically the same or next working day, e.g. JIB Status from requirement (03/11) to client confirmation (17/11) in 11 working days.
- Benefit: capacity released to carry three engagements concurrently, faster root-cause analysis on production issues, and documented, reusable patterns for the team.

Every figure traces to the work repository (issue logs and commits); hours are estimates and the method is stated in the attached register. Attached: report, use-case register (Excel), success-story deck and evidence annexure.

Note on T&G: my records name PAL, ONGC Videsh and Astral (via KPMG). If the Astral work is what we report as T&G, I will re-map it; the totals do not change.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
"""
open(os.path.join(HERE, "..", "Management_Summary_Email.md"), "w").write(mail)
print("report sections", len(report["sections"]), "annexure rows", len(ann_rows))
