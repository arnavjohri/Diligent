"""Management report: Deliverable-1 headings in the body, register / ATC / effort / evidence detail in annexes.
python3 -I build_report.py  -> data/report.json, data/casestudy.json, ../Management_Summary_Email.md   (render with render_docx.js)
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "data")
load = lambda f: json.load(open(os.path.join(D, f)))
R, U, ATC, G = load("register.json"), load("usage.json"), load("inv_atc.json"), load("gitstats.json")
PAT = [x for x in load("atc_patterns_clean.json") if x["keep"]]
S, ROWS = R["summary"], R["rows"]
M = {m[0].strip(): m[1] for m in U["metrics"]}
BP = S["by_project"]
BY = {o["folder"]: o for o in ROWS}
J, AT = BY["ovl/zfi_jib_status"], BY["ovl/atc"]
P3 = ["PAL", "ONGC (OVL)", "Astral (KPMG)"]
ALL = P3 + ["Common (all projects)"]
COMMITS = M["Commits in the work repository, 19/08 - 19/11/26"]
WKND = M["of which weekend days"]
OBJS = M["Custom SAP objects built, changed or analysed"]
NTS = M["Technical specifications produced"]
NLOG = M["Issue-log entries written (issue, cause, fix)"]
autos = [o for o in ROWS if o["automation"]]
h = lambda x: f"{x:,.0f}"
h1d = lambda x: f"{x:,.1f}"
pc = lambda x: f"{x * 100:.0f}%"
md = lambda x: f"{int(x / 8 + 0.5):,}"
rows_of = lambda p: [o for o in ROWS if o["project"] == p]
p = lambda text, **k: dict(t="p", text=text, **k)
bl = lambda items, **k: dict(t="bullets", items=items, **k)
h3 = lambda text: dict(t="h3", text=text)
BREAK = ("1.", "3.", "4.", "5.", "6.", "7.", "8.", "10.", "11.", "13.", "Annex A", "Annex B", "Annex C")
h1 = lambda text: dict(t="h1", text=text, pageBreak=text.startswith(BREAK))
count = lambda rows, kinds: len([o for o in rows if o["work"] in kinds])

FLAGSHIP = {
    "PAL": ["kpmg/zfi_fb70_cm_apprv", "pal/zinv_gl_upload", "pal/zfi03custinv1"],
    "ONGC (OVL)": ["ovl/zpra_dpr", "ovl/zfi_bank_reval", "ovl/per_barrel_agenda", "ovl/zmm_purchdoc_cds_ext", "ovl/zaa_impairmentloss",
                   "ovl/zfi_acdoca_jva_align"],
    "Astral (KPMG)": ["kpmg/zpp_forecast_v2", "kpmg/zsd_exc_approval", "kpmg/zfi_tds_cl34", "kpmg/zpp_forecast_paints"],
}
IN_BODY = {f for v in FLAGSHIP.values() for f in v} | {"ovl/zfi_jib_status", "ovl/atc"}


def key_items(name):
    out = [h3("Key developments")]
    for f in FLAGSHIP[name]:
        o = BY[f]
        out += [p(f"**{o['title']}** ({o['id']})", after=40, keepNext=True),
                bl([f"**Requirement.** {o['requirement']}", f"**AI contribution.** {o['ai']}", f"**Result.** {o['quality']}"], size=19)]
    return out


def uc_table(name):
    rows = rows_of(name)
    body = [[o["id"], o["title"], o["dev_type"], h1d(o["baseline_h"]), h1d(o["actual_h"]), h1d(o["saved_h"])] for o in rows]
    body.append(["", f"Total - {len(rows)} use cases", "", h1d(BP[name]["baseline"]), h1d(BP[name]["actual"]), h1d(BP[name]["saved"])])
    return dict(t="table", fontSize=7.5, widths=[7, 51, 15, 9, 9, 9], numeric=[3, 4, 5], totalRow=True, caption=f"{name} - all AI use cases (hours)",
                header=["Sr.", "Development / use case", "Type", "Without AI", "With AI", "Saved"], rows=body)


# ------------------------------------------------------------------ JIB case-study figures (shared with the deck)
jd = {d: x["ovl/zfi_jib_status"] for d, x in G["perday"].items() if "ovl/zfi_jib_status" in x}
tot = sum(jd.values())
share = dict(dev=(jd["2026-11-03"] + jd["2026-11-04"] + jd["2026-11-17"] + jd["2026-11-19"]) / tot, dbg=jd["2026-11-12"] / tot, tst=jd["2026-11-06"] / tot)
CONV = dict(dev=0.60, dbg=0.15, tst=0.25)
jb, ja = J["baseline_h"], J["actual_h"]
PH = [("Development (design and build)", jb * CONV["dev"], ja * share["dev"]), ("Debugging", jb * CONV["dbg"], ja * share["dbg"]),
      ("Testing and correction", jb * CONV["tst"], ja * share["tst"])]
json.dump(dict(phases=[[a, round(b, 1), round(c, 1)] for a, b, c in PH], baseline=jb, actual=ja, n_patterns=len(PAT)),
          open(os.path.join(D, "casestudy.json"), "w"), indent=1)

# ------------------------------------------------------------------ cover mail (Deliverable 3)
mail = f"""Subject: AI Utilisation, Productivity Improvement & Delivery Efficiency Report - PAL | ONGC (OVL) | Astral (KPMG)

Dear [Manager name],

As requested, please find attached my report on AI utilisation in SAP ABAP delivery from July to November 2026, with the detailed use-case register and the success-story presentation.

Summary:
- AI-assisted developments: **{S['n_counted']} completed** - ONGC (OVL) {BP['ONGC (OVL)']['n']}, Astral (KPMG) {BP['Astral (KPMG)']['n']}, PAL {BP['PAL']['n']}, common tools {BP['Common (all projects)']['n']}; **{COMMITS} commits** in the work repository.
- Significant applications: ONGC **JIB Status dashboard**, DPR Fiori dashboard and CPI interface, Bank Revaluation and Per-Barrel analytics; PAL **FB70 credit-memo approval workflow**; Astral **ZFORECAST** (Adhesive and Paints), Exceptional Approval and Clause 34 TDS report.
- ATC corrections (ONGC): **847 findings** worked across 51 program includes, with {len(PAT)} documented correction patterns.
- Automations: **{len(autos)}**, including the daily BP-creation mail, mass uploads, the approval workflow and developer tools.
- Effort: about **{md(S['saved'])} man-days saved, {pc(S['red'])} overall effort reduction**.
- Success story: the JIB Status dashboard was **built in three working days** and **confirmed by the client in writing** on 17 November after their testing.
- Benefits: **three projects handled in parallel** with production support, faster root-cause analysis, and reusable assets for the team.

Attachments:
1. AI_Utilisation_Report.docx - report with use-case register, ATC register, effort calculation and evidence annexure
2. AI_Use_Case_Register.xlsx - use-case register with formulas and productivity dashboard
3. AI_Success_Story_JIB_Status.pptx - success-story presentation

Kindly review and let me know if you need any further detail.

Thanks & Regards,
Arnav Johri | Associate Consultant | Diligent Global
"""
open(os.path.join(HERE, "..", "Management_Summary_Email.md"), "w").write(mail)


def mail_html(text):
    """Same mail as HTML, so that the bold survives copy and paste into Outlook."""
    import html as _h
    fmt = lambda t: re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", _h.escape(t, quote=False))
    lines = text.strip().split("\n")
    out, mode = [], None
    for ln in lines[1:]:
        kind = "ul" if ln.startswith("- ") else "ol" if re.match(r"\d+\. ", ln) else None
        if mode and kind != mode:
            out.append(f"</{mode}>")
        if kind and kind != mode:
            out.append(f"<{kind}>")
        mode = kind
        if kind:
            out.append("<li>" + fmt(re.sub(r"^(- |\d+\. )", "", ln)) + "</li>")
        elif ln.strip():
            out.append("<p>" + fmt(ln) + "</p>")
    body = "\n".join(out).replace("</p>\n<p>Arnav Johri", "<br>\nArnav Johri")
    return ("<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>Cover mail</title>\n"
            "<style>body{font-family:Calibri,Arial,sans-serif;font-size:11pt;color:#000;background:#fff;max-width:820px;margin:24px auto;padding:0 16px}"
            ".subj{background:#eef2f4;padding:8px 12px;margin-bottom:18px;font-size:10pt}p{margin:0 0 11pt}ul,ol{margin:0 0 11pt}</style></head>\n<body>\n"
            f"<div class=\"subj\"><b>Subject</b> (paste into the subject field): {_h.escape(lines[0].replace('Subject: ', ''), quote=False)}</div>\n"
            f"<div id=\"mail\">\n{body}\n</div>\n</body></html>\n")


open(os.path.join(HERE, "..", "Management_Summary_Email.html"), "w", encoding="utf-8").write(mail_html(mail))

# ------------------------------------------------------------------ building blocks
cats = {}
for o in ROWS:
    cats.setdefault(o["category"], []).append(o)
KEEP = ("Commits in the work repository", "of which AI-assisted", "Working days in the period", "Days with AI-assisted commits", "of which weekend days",
        "Claude Code sessions, 20/07", "Prompts in those sessions", "Claude Code cloud sessions", "Lines of ABAP", "Lines of documentation",
        "Custom SAP objects", "Issue-log entries", "Technical specifications")
usage_rows = [[("    " if m[0].startswith("  ") else "") + m[0].strip(), f"{m[1]:,}" if isinstance(m[1], (int, float)) else str(m[1]), m[2]]
              for m in U["metrics"] if m[0].strip().startswith(KEEP)]
MONTHS = [("07", "July"), ("08", "August"), ("09", "September"), ("10", "October"), ("11", "November")]
tl_rows = [[label] + ["; ".join(o["nick"] for o in rows_of(x) if o["first"][3:5] == mm) or "-" for x in P3] for mm, label in MONTHS]
finding_types = [
    ["SELECT SINGLE without a unique key", "Full key supplied where available; otherwise SELECT with ORDER BY on the key fields and UP TO 1 ROWS, so the result is deterministic."],
    ["BINARY SEARCH or DELETE ADJACENT DUPLICATES on unsorted data", "SORT on exactly the compared fields, placed before the statement and outside any loop."],
    ["Field-length extension (40-character material number, amounts)", "Variables retyped to the data element or converted explicitly; pseudo-comment with the SAP note only where no truncation can occur."],
    ["Simplified object: BSEG reads", "Read through the released CDS view I_OperationalAcctgDocItem with field aliases; cluster-specific constructs removed."],
    ["Simplified object: KONV pricing conditions", "Read through the compatibility view V_KONV in strict Open SQL; CLIENT SPECIFIED and the client field dropped together."],
    ["Simplified object: VBUK / VBUP status tables", "Status fields read from VBAK / VBAP / LIKP / LIPS or the compatibility views V_VBUK_S4 / V_VBUP_S4."],
    ["Removed tables J_1IMOVEND / J_1IMOCUST", "Reads moved to LFA1 / KNA1 according to SAP note 2877717, with the type references updated."],
    ["CLIENT SPECIFIED on compatibility views", "CLIENT SPECIFIED and the client condition removed; kept only on real transparent tables."],
    ["Open SQL not in strict mode", "Comma-separated field lists, host variables escaped with @, clause order corrected."],
    ["FOR ALL ENTRIES without a guard", "IS NOT INITIAL check on the driver table before every FOR ALL ENTRIES."],
    ["Batch input on transactions changed in S/4HANA", "Replaced by released BAPIs, with the return messages mapped back to the caller."],
    ["Native SQL and database hints", "Rewritten in Open SQL where practical; non-HANA hints removed."],
]
atc_code = [
    dict(t="code", caption="Example 1 - SELECT SINGLE without a unique key", lines=[
        "* Before", "SELECT SINGLE belnr FROM bkpf INTO lv_belnr WHERE bukrs = p_bukrs AND xblnr = lv_ref.",
        "* After - deterministic result, strict Open SQL",
        "SELECT belnr FROM bkpf WHERE bukrs = @p_bukrs AND xblnr = @lv_ref",
        "  ORDER BY belnr INTO @lv_belnr UP TO 1 ROWS.", "ENDSELECT."]),
    dict(t="code", caption="Example 2 - simplified object: KONV pricing read moved to the compatibility view", lines=[
        "* Before", "SELECT kschl kbetr FROM konv CLIENT SPECIFIED INTO TABLE lt_cond", "  WHERE mandt = sy-mandt AND knumv = lv_knumv.",
        "* After - CLIENT SPECIFIED and the client field dropped together",
        "SELECT kschl, kbetr FROM v_konv WHERE knumv = @lv_knumv INTO TABLE @lt_cond."]),
    dict(t="code", caption="Example 3 - FOR ALL ENTRIES guarded, driver de-duplicated on the full key", lines=[
        "SORT lt_docs BY bukrs belnr gjahr.", "DELETE ADJACENT DUPLICATES FROM lt_docs COMPARING bukrs belnr gjahr.",
        "IF lt_docs IS NOT INITIAL.",
        "  SELECT bukrs, belnr, gjahr, buzei, hkont FROM bseg FOR ALL ENTRIES IN @lt_docs",
        "    WHERE bukrs = @lt_docs-bukrs AND belnr = @lt_docs-belnr AND gjahr = @lt_docs-gjahr",
        "    INTO TABLE @DATA(lt_items).", "ENDIF."]),
    dict(t="code", caption="Example 4 - field-length extension: variable retyped to the data element", lines=[
        "* Before", "DATA lv_matnr(18) TYPE c.", "* After - follows the 40-character material number", "DATA lv_matnr TYPE matnr."]),
]
quality = [
    ("Development efficiency", [
        "Working versions the same or the next working day: ZMM_BP_CREATE_MAIL was built and activated on first paste the day the FS answers arrived (25/09/26); the Paints forecast went from FS (19/10) to imported and active (22/10).",
        "Reuse instead of rework: the forecast engine is reused for Paints, the G/L workflow class pattern for the FB70 credit-memo workflow, and the MB5B amount logic was ported to ZMM_MB5B_NEW."]),
    ("Debugging and problem resolution", [
        "ZMM_TMS_STATUS: a blank Excel export was traced to one constant applied to 44 columns; fixed and confirmed working the same day (28/10/26).",
        "CJ88 settlement reversal and FBV0 posting errors were proven to sit in SAP standard from dump, update and trace evidence, so no custom code was touched and the issues were routed correctly.",
        "PAL incident INC01967: unreadable invoice PDFs in customer e-mails were traced to the server-side encryption round trip; incident closed 13/10/26."]),
    ("Code quality", [
        "S/4HANA-compatible code: batch input on changed transactions replaced by BAPIs, strict Open SQL, released CDS views, guarded FOR ALL ENTRIES.",
        "No modification of SAP standard: released BAdIs, enhancements that call Z classes, and CDS extensions. Error paths give the user a message instead of a dump; posting programs default to a test run."]),
    ("Documentation and knowledge transfer", [
        f"{NLOG} issue-log entries (issue, cause, fix) and a technical notes file per object; {NTS} technical specifications (Annex D).",
        "Specification gaps raised before build: 16 questions on WRICEF 141, 21 on WRICEF 147 and 28 points on the Paints specification, which reduced change cycles later."]),
    ("Project delivery", [
        "Three projects were handled in parallel together with production support; functional testing could start earlier on most developments.",
        f"About {round(S['corrections'], -1)} corrections to AI output were logged during review, activation and testing - every object passes human review before release - and 56 recorded release constraints are applied to each new object."]),
]
case_rows = [
    ["Project", "ONGC Videsh Ltd (OVL)"],
    ["Development and SAP objects", "Management Dashboard 'JIB Status' - ZFI_JIB_STATUS: analytical cube ZI_JIB_STATUS_CUBE with seven supporting CDS views (documents, aggregates, periods, ventures, clearing)"],
    ["Business requirement", J["requirement"]],
    ["Technical complexity", J["challenge"]],
    ["Conventional approach", "Data analysis of BKPF / BSEG and joint-venture data in SE16N, view-by-view design by trial activation, and a separate rebuild after each round of client feedback."],
    ["How AI was used", J["ai"]],
    ["Human review and validation", J["manual"]],
]
case_tl = dict(t="table", caption="Timeline - development and client testing", widths=[13, 20, 67], header=["Date", "Activity", "Step"],
               rows=[["03/11/26", "Development", "Requirement workbook received; production documents checked line by line; data model designed and the first views delivered."],
                     ["04/11/26", "Development", "Model rebuilt on entry-date windows; Fiori Custom Analytical Query running on the cube - one working day after the requirement."],
                     ["06/11/26", "Development", "Client test feedback built in the same day: document-level model, year and quarter summaries, reversal handling. Layout accepted by the client on retest."],
                     ["06/11 - 17/11/26", "Client testing", "Testing and review by the client's Corporate Accounts team. One launchpad navigation setting corrected on 12/11."],
                     ["17/11/26", "Client confirmation", "Written confirmation: 'working well and meeting expectations'. Four additions requested with it were delivered the same day."],
                     ["19/11/26", "Follow-up addition", "Business-unit mapping extended to every venture from the client's list."]])
case_ba = dict(t="table", caption="Before and after AI (hours)", widths=[40, 30, 30], header=["Effort", "Conventional", "With AI"], numeric=[1, 2], totalRow=True,
               rows=[[a, h1d(b), h1d(c)] for a, b, c in PH] + [["Total effort", h1d(jb), h1d(ja)]],
               source="Conventional effort split by a standard phase ratio (60 / 15 / 25); AI-assisted effort split by the recorded working sessions of each phase.")
dash_rows = [
    ("AI-assisted use cases", lambda x: str(BP[x]["n"]), str(S["n_counted"])),
    ("Distinct applications developed", lambda x: str(count(rows_of(x), ("NEW",))), str(count(ROWS, ("NEW",)))),
    ("Programs developed / enhanced", lambda x: str(count(rows_of(x), ("NEW", "ENH", "S4", "ATC"))), str(count(ROWS, ("NEW", "ENH", "S4", "ATC")))),
    ("ATC findings resolved", lambda x: "847" if x == "ONGC (OVL)" else "-", "847"),
    ("Automation solutions", lambda x: str(len([o for o in autos if o["project"] == x])), str(len(autos))),
    ("Other technical corrections", lambda x: str(count(rows_of(x), ("FIX", "ANA"))), str(count(ROWS, ("FIX", "ANA")))),
    ("Effort without AI (hours)", lambda x: h1d(BP[x]["baseline"]), h1d(S["baseline"])),
    ("Actual effort with AI (hours)", lambda x: h1d(BP[x]["actual"]), h1d(S["actual"])),
    ("Effort saved (hours)", lambda x: h1d(BP[x]["saved"]), h1d(S["saved"])),
    ("Effort saved (man-days)", lambda x: h1d(BP[x]["saved"] / 8), h1d(S["saved"] / 8)),
    ("Weighted effort reduction (%)", lambda x: pc(BP[x]["saved"] / BP[x]["baseline"]), pc(S["red"])),
    ("Productivity improvement (%)", lambda x: f"{(BP[x]['baseline'] / BP[x]['actual'] - 1) * 100:.0f}%", f"{S['prod'] * 100:.0f}%"),
]
DELIVERY = [["PAL", "Ariba purchase-order fix written the day the incident was analysed (17/09/26)"],
            ["ONGC (OVL)", "JIB Status dashboard built in three working days; ZMM_TMS_STATUS export fixed and confirmed the same day"],
            ["Astral (KPMG)", "BP-creation mail built and active in one day; Paints forecast from specification to active in three working days"],
            ["Overall", "First working version typically within one working day of the requirement"]]


def card(o):
    rows = [["SAP objects", o["objects"]], ["Business requirement", o["requirement"]], ["Technical challenge", o["challenge"]],
            ["AI contribution", o["ai"]], ["Manual intervention", o["manual"]], ["Result and quality", o["quality"]],
            ["Type and timeline", f"{o['dev_type']} - {o['category']} - {o['impact']}"]]
    return [dict(t="h3", text=f"{o['id']}  {o['title']}"),
            dict(t="table", widths=[20, 80], header=["Field", "Detail"], rows=rows, boldFirst=True, fontSize=7.5, cantSplit=True)]


CONTENTS = ["1. Executive Summary", "2. Scope and Sources Reviewed", "3. How AI Was Used in Daily Delivery", "4. PAL Project - Detailed AI Use Cases",
            "5. ONGC (OVL) Project - Detailed AI Use Cases", "6. Astral (KPMG) Project - Detailed AI Use Cases", "7. Technical Classification of AI Use Cases",
            "8. ATC Correction and Code Optimisation Summary", "9. Automation and Reusable Development Summary",
            "10. Quantified Effort and Productivity Analysis", "11. Development Quality and Delivery Improvement", "12. Customer Benefits",
            "13. Strongest AI Success Story - ONGC JIB Status Dashboard", "14. Overall Conclusions", "Annex A - Detailed AI Use Case Register",
            "Annex B - ATC Remediation Register", "Annex C - Effort Calculation and Assumptions", "Annex D - Technical Documentation Produced",
            "Annex E - Evidence and Estimation Annexure"]

front = [
    dict(t="cover", kicker="MANAGEMENT SUBMISSION  |  AI ADOPTION AND QUANTIFIABLE PRODUCTIVITY BENEFITS IN SAP ABAP DELIVERY",
         title="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
         subtitle="Projects: PAL  |  ONGC (OVL)  |  Astral (KPMG)",
         lines=["**Prepared by:** Arnav Johri, Associate Consultant (SAP ABAP), Diligent Global", "**Period covered:** 20 July - 19 November 2026",
                "**Reporting cut-off date:** 19 November 2026", "**AI tool:** Claude Code (Anthropic)"]),
    dict(t="pagebreak"), dict(t="h2", text="Contents"), dict(t="contents", items=CONTENTS),
]
body = [
    h1("1. Executive Summary"),
    dict(t="kpis", items=[dict(value=str(S["n_counted"]), label="AI-assisted use cases", note="completed across three projects"),
                          dict(value=f"{COMMITS}", label="Commits", note="in under four months"),
                          dict(value=md(S["saved"]), label="Man-days saved", note=f"{h(S['saved'])} hours"),
                          dict(value=pc(S["red"]), label="Effort reduction", note="weighted by hours")]),
    p("Between July and November 2026, AI (Claude Code) was used as a daily working tool in SAP ABAP delivery on three projects running in parallel: PAL, "
      "ONGC Videsh (OVL) and Astral through KPMG. It supported the full development cycle: reading functional specifications and legacy code, building new "
      "objects, correcting existing ones, ATC remediation, root-cause analysis of dumps and production issues, and technical documentation."),
    p(f"{S['n_counted']} developments were completed with AI assistance, covering {OBJS} custom SAP objects built, changed or analysed. They include complete "
      "applications (CDS / RAP dashboards, an approval workflow, a forecasting application), reports, interfaces, enhancements, forms and developer tools. "
      "Every object was reviewed, activated and tested by the consultant before release."),
    p(f"Conventional delivery of the same scope would take about {h(S['baseline'])} hours. With AI it took {h(S['actual'])} hours of working time: "
      f"**{h(S['saved'])} hours ({md(S['saved'])} man-days) saved, a {pc(S['red'])} effort reduction.**"),
    dict(t="table", caption="At a glance", widths=[17, 10, 73], header=["Project", "Use cases", "What was delivered"], numeric=[1],
         rows=[["ONGC (OVL)", str(BP["ONGC (OVL)"]["n"]), "Management Dashboard analytics (JIB status, bank revaluation, treasury register, per-barrel analysis), DPR Fiori dashboard and CPI interface, ATC remediation, FI / JVA programs, Group Reporting, MM enhancements and Fiori apps"],
               ["Astral (KPMG)", str(BP["Astral (KPMG)"]["n"]), "ZFORECAST for Adhesive and Paints, Exceptional Approval (WRICEF 141), Clause 34 TDS report, PO budget control, BP-creation mail, MB5B amounts, vendor upload, Scheme (Pipes)"],
               ["PAL", str(BP["PAL"]["n"]), "FB70 credit-memo approval workflow, journal-entry and invoice upload corrections, invoice forms and e-mail, Ariba PO integration, SD-FI line texts"],
               ["Common", str(BP["Common (all projects)"]["n"]), "AI delivery toolkit and developer tools used on every project"]]),
    p("**Strongest example:** the ONGC Videsh JIB Status management dashboard was built in three working days and confirmed by the client in writing after "
      "their testing (section 13)."),
    h1("2. Scope and Sources Reviewed"),
    bl(["The work repository: one folder per SAP object for each project, with its issue log (issue, cause, fix), technical notes and delivered source.",
        f"The complete commit history of the repository ({COMMITS} commits, 19/08 - 19/11/26) and the Claude Code session records from 20/07/26 (30 sessions, 557 prompts).",
        "The August work log for ONGC, the ATC exports and correction knowledge base, functional and technical specifications, client test feedback and mail threads."]),
    h1("3. How AI Was Used in Daily Delivery"),
    p("The same five-step loop ran on every project:"),
    dict(t="numbered", items=[
        "**Intake** - the issue mail, functional specification or change request is triaged into a work queue.",
        "**Fresh source** - the current version is downloaded from SAP and compared with the last copy, so that nobody else's change is lost.",
        "**AI build or diagnosis** - Claude Code reads the source, dump or trace and writes the new or corrected object, with change markers and the old code kept commented.",
        "**Activation and test** - the consultant pastes or imports the object, activates it, feeds activation errors back and tests with the functional consultant.",
        "**Record** - issue, cause and fix are logged per object and committed, so that every change is traceable."]),
    dict(t="table", caption="AI utilisation", widths=[56, 12, 52], header=["Measure", "Value", "Basis"], numeric=[1], rows=usage_rows),
    dict(t="image", path=os.path.join(HERE, "charts", "monthly_activity.png"), w=600, h=240, alt="Commits per month", caption=""),
    dict(t="table", caption="Delivery timeline - developments started in each month", fontSize=7, widths=[11, 22, 45, 22],
         header=["Month", "PAL", "ONGC (OVL)", "Astral (KPMG)"], rows=tl_rows),
    h1("4. PAL Project - Detailed AI Use Cases"),
    p("Philippine Airlines (systems DS4, QS4, PS4): finance and purchasing corrections raised as incidents (INC01192, INC01740, INC01967) and one new approval workflow."),
    *key_items("PAL"), uc_table("PAL"),
    h1("5. ONGC (OVL) Project - Detailed AI Use Cases"),
    p("ONGC Videsh, ECC to S/4HANA: the largest share of the work - new CDS analytics for the Management Dashboard, the Daily Production Report application, "
      "ATC remediation (section 8), FI / JVA posting and reconciliation programs, Group Reporting, and root-cause analysis of production and Mock-2 issues. "
      "The JIB Status dashboard is described in section 13."),
    *key_items("ONGC (OVL)"), uc_table("ONGC (OVL)"),
    h1("6. Astral (KPMG) Project - Detailed AI Use Cases"),
    p("Astral Limited, Project UDAY, delivered through KPMG: new developments built from functional specifications across PP, SD, FI and MM "
      "(WRICEF ID-2A, ID-2B, 141, 337, 050, 057, 147 and 195)."),
    *key_items("Astral (KPMG)"), uc_table("Astral (KPMG)"), uc_table("Common (all projects)"),
    h1("7. Technical Classification of AI Use Cases"),
    dict(t="table", widths=[28, 10, 62], numeric=[1], header=["Category", "Use cases", "Examples"],
         rows=[[k, str(len(v)), "; ".join(o["nick"] for o in sorted(v, key=lambda o: -o["baseline_h"])[:4])]
               for k, v in sorted(cats.items(), key=lambda kv: -len(kv[1]))]),
    h1("8. ATC Correction and Code Optimisation Summary"),
    p(f"The ATC S/4HANA-readiness findings assigned for ONGC were worked family by family, so that each correction pattern was derived once and reused "
      f"across the batch: about {h(AT['baseline_h'])} hours conventionally against {h(AT['actual_h'])} hours with AI, including review and correction."),
    dict(t="table", widths=[60, 12, 28], numeric=[1], header=["Stage", "Count", "Detail"],
         rows=[["ATC findings assigned and worked", "847", "05/08 - 14/08/26"], ["Program includes corrected", "51", "43 programs, 14 packages"],
               ["Correction blocks applied", "205", "833 lines added or changed"], ["Findings routed for decision", "26", "manual review list"],
               ["Correction patterns documented", str(len(PAT)), "listed in Annex B"]]),
    dict(t="table", caption="Main finding types and the correction applied", fontSize=7.5, widths=[36, 64], header=["Finding type", "Correction"], rows=finding_types),
    h3("Examples of AI-assisted correction logic"),
    p("Generic patterns as applied across the batch (illustrative statements, not client code)."),
    *atc_code,
    p("**Optimisation beyond ATC.** FOR ALL ENTRIES replaced by a range where it lost rows through its implicit DISTINCT (ZFITAX_PBT_CALC_PRG); batch input "
      "on transactions changed in S/4HANA replaced by FI-AA BAPIs (ZAA_IMPARMENTLOSS); totals aggregated on the database instead of line by line "
      "(ZFI_ACDOCA_JVSO1_RECON)."),
    h1("9. Automation and Reusable Development Summary"),
    dict(t="table", fontSize=7.5, widths=[24, 13, 43, 20], header=["Automation / tool", "Project", "Manual work it replaces", "When it is used"],
         rows=[[o["nick"], o["project"].replace("Common (all projects)", "Common"), o["auto_process"], o["auto_freq"]] for o in autos]),
    p("Reusable beyond these projects: the ATC correction patterns, the record of release constraints, the forecast engine (reused for Paints), the "
      "workflow class pattern (reused from G/L to credit memo), the analytical cube pattern (four dashboards) and the developer tools."),
    h1("10. Quantified Effort and Productivity Analysis"),
    dict(t="image", path=os.path.join(HERE, "charts", "effort_by_project.png"), w=500, h=225, alt="Effort by project", caption=""),
    dict(t="table", caption="Project-wise productivity dashboard", widths=[34, 14, 14, 14, 11, 13], numeric=[1, 2, 3, 4, 5],
         header=["KPI", "PAL", "ONGC (OVL)", "Astral (KPMG)", "Common", "Overall"],
         rows=[[lab] + [f(x) for x in ALL] + [t_] for lab, f, t_ in dash_rows]),
    dict(t="table", caption="Quantified delivery-time benefits", widths=[22, 78], header=["Project", "Example"], rows=DELIVERY),
    dict(t="note", text="**Method.** Effort without AI is a conservative baseline by work type and complexity of each use case (Annex C). Actual effort with AI "
                        f"counts all working time of the period - {S['working_days']} days from 19/08/26 including {WKND} weekend days, plus the dated work before - "
                        "distributed over the use cases by their size and measured AI session time. Saved = without - with; man-days = saved / 8; "
                        "reduction = saved / without; productivity improvement = without / with - 1. All figures are formula-driven in the Excel register; hours are shown rounded, and totals are calculated from the unrounded values."),
    h1("11. Development Quality and Delivery Improvement"),
    *[x for k, v in quality for x in (h3(k), bl(v))],
    h1("12. Customer Benefits"),
    bl(["**Capacity released** - one associate consultant carried three projects, ATC remediation and production support in the same months.",
        "**Earlier testing** - first working versions typically within a working day, so functional testing and sign-off started sooner.",
        "**Reusable assets** - correction patterns, release constraints, engine and workflow patterns and developer tools are ready for the next project.",
        "**Commercial view** - effort value = man-days saved x applicable day rate. Under fixed price it shows as margin and released capacity; under time and material it follows the billing arrangement."]),
    h1("13. Strongest AI Success Story - ONGC JIB Status Dashboard"),
    dict(t="table", widths=[24, 76], header=["Item", "Detail"], rows=case_rows, boldFirst=True, fontSize=8.5),
    p("**Development took three working days (03, 04 and 06 November).** The remaining time to 17 November was testing and review on the client side; "
      "the dashboard was then confirmed in writing."),
    case_tl, case_ba,
    p(f"**Quantified effort reduction.** {h(J['saved_h'])} hours saved ({J['saved_h'] / 8:.1f} man-days), a {pc(J['red'])} reduction "
      f"({J['prod'] + 1:.1f}x throughput). First running version one working day after the requirement."),
    p(f"**Quality and customer benefit.** {J['quality']} Management now sees the JIB posting status of every joint venture without an Excel workbook."),
    h3("Lessons learned and replication"),
    bl(["Production sample documents are checked line by line before the data model is fixed.",
        "One object at a time with activation feedback; every release constraint is recorded once and reused.",
        "The same cube pattern already serves Bank Revaluation, the Treasury bank register and Per-Barrel analysis, and can serve further Management Dashboard cards for ONGC, finance analytics for PAL and forecasting or credit analytics for Astral."]),
    h1("14. Overall Conclusions"),
    bl([f"AI is now part of daily SAP ABAP delivery: {S['n_counted']} completed use cases across PAL, ONGC (OVL) and Astral (KPMG) in under four months.",
        f"The saving is about {md(S['saved'])} man-days ({pc(S['red'])}), achieved with human control at every step: fresh source before each change, activation feedback, functional confirmation.",
        "The approach is repeatable: the same loop and toolkit worked across reports, CDS / RAP, workflow, enhancements, forms and ATC remediation.",
        "Next steps: share the AI delivery toolkit with the team, reuse the dashboard pattern for further cards, and apply the ATC patterns to the next remediation wave."]),
]

annex = [h1("Annex A - Detailed AI Use Case Register"),
         p("One entry for every use case not already described in sections 4 to 6, 8 and 13. Hours per use case are in the project tables of sections 4 to 6; "
           "the complete register with all fields and formulas is the Excel workbook.")]
for x in ALL:
    rest = [o for o in rows_of(x) if o["folder"] not in IN_BODY]
    if rest:
        annex.append(dict(t="h2", text=f"{x} - {len(rest)} use cases"))
        for o in rest:
            annex += card(o)
progs = sorted(ATC["corrected_programs"], key=lambda q: -(q.get("boc_blocks_dated_08_08_2026") or 0))
annex += [h1("Annex B - ATC Remediation Register"),
          dict(t="table", caption="Corrected program includes (ONGC)", fontSize=7.5, widths=[30, 26, 16, 12, 16], numeric=[3, 4],
               header=["Include", "Parent program", "Package", "Lines", "Correction blocks"],
               rows=[[q["object"], str(q.get("parent") or ""), str(q.get("package") or ""), f"{q.get('lines') or 0:,}",
                      str(q.get("boc_blocks_dated_08_08_2026") or 0)] for q in progs]),
          dict(t="table", caption=f"Documented correction patterns ({len(PAT)})", fontSize=7.5, widths=[34, 66], header=["Finding", "Correction pattern"],
               rows=[[x["category"], x["fix"]] for x in PAT])]
annex += [h1("Annex C - Effort Calculation and Assumptions"),
          h3("A. Effort without AI"),
          p("Conventional effort per use case = baseline hours for its work type and complexity x scope factor (above 1 where one delivery contains several "
            "objects). The baseline covers requirement understanding, analysis, design, coding, debugging, unit testing and documentation. The ATC "
            "baseline uses the correction blocks applied: 10 / 25 / 40 minutes per pseudo-comment / replacement / new-code block, 15 minutes per include and 8 hours of packaging."),
          dict(t="table", caption="Baseline by work type and complexity (hours)", widths=[40, 15, 15, 15, 15], numeric=[1, 2, 3, 4],
               header=["Work type", "Low", "Medium", "High", "Very High"],
               rows=[[R["rubric_label"][k]] + [f"{v:g}" for v in R["rubric"][k]] for k in R["rubric"] if k != "DOC"]),
          h3("B. Actual effort with AI"),
          p(f"All working time of the period is counted: {S['working_days']} days from 19/08/26 ({S['working_days'] - WKND} weekdays after leave and {WKND} weekend days) "
            f"x 8 hours = {h(S['budget'])} hours, plus the dated work from 20/07/26. The hours are distributed over the use cases by their size (70%) and by the "
            "measured AI session time of each object (30%), with a minimum per use case for prompting, review, activation and unit testing "
            "(1 / 2 / 4 / 8 hours by complexity; 0.5 / 1 / 2 / 3 hours for analyses). Review and correction time is therefore included in every figure."),
          h3("C. Calculation"),
          bl(["Effort saved (hours) = effort without AI - actual effort with AI.", "Effort reduction (%) = effort saved / effort without AI x 100.",
              "Effort saved (man-days) = effort saved in hours / 8.", "Productivity improvement (%) = (effort without AI / actual effort with AI - 1) x 100.",
              "Project totals are weighted by hours, not averaged percentages. Recurring savings from automation are separate from these development savings."]),
          dict(t="table", caption="Worked example - JIB Status dashboard", widths=[50, 50], numeric=[1], header=["Parameter", "Value"],
               rows=[["Effort without AI", f"{h(jb)} hours"], ["Actual effort with AI", f"{h(ja)} hours"], ["Effort saved", f"{h(J['saved_h'])} hours"],
                     ["Effort reduction", pc(J["red"])], ["Man-days saved", f"{J['saved_h'] / 8:.1f}"], ["Productivity improvement", f"{J['prod'] * 100:.0f}%"]]),
          dict(t="h1", text="Annex D - Technical Documentation Produced"),
          dict(t="table", widths=[20, 80], header=["Project", "Technical specification"], rows=R["ts_docs"]),
          p(f"In addition: {NLOG} issue-log entries, a technical notes file for every object, assumption and query registers for each specification, "
            "build guides and handover documents.")]
annex_e = [dict(t="h1", text="Annex E - Evidence and Estimation Annexure"),
           p("Traceability for every use case: source artefact in the work repository, evidence of completion and effort assumptions "
             "(work type / complexity / scope factor as used in Annex C). Repository folder names show where an object was first filed; the project of each "
             "use case follows the client system named in its own log."),
           dict(t="table", fontSize=7, widths=[6, 10, 26, 30, 14, 14],
                header=["Sr.", "Project", "Development / correction", "Source artefact", "Completion", "Effort assumptions"],
                rows=[[o["id"], o["project"].replace("Common (all projects)", "Common"), o["title"], o["source"],
                       f"{o['status'].split(' - ')[0]}, {o['first'] if o['first'] == o['last'] else o['first'] + ' - ' + o['last']}",
                       f"{o['dev_type']} / {o['complexity']} / x{o['scope']:g}"] for o in ROWS],
                source="Confidence: each use case is verified against the issue log and commit history of its object; effort figures follow the method in Annex C.")]

doc = dict(title="SAP ABAP AI Utilisation, Productivity Improvement & Delivery Efficiency Report",
           header="SAP ABAP AI utilisation report  |  PAL  |  ONGC (OVL)  |  Astral (KPMG)  |  19 November 2026",
           footer="Arnav Johri, Associate Consultant, Diligent Global", author="Arnav Johri",
           sections=[dict(noHeader=True, blocks=front), dict(blocks=body + annex), dict(orientation="landscape", blocks=annex_e)])
json.dump(doc, open(os.path.join(D, "report.json"), "w"), indent=1)
print("ok", len(body), "body blocks;", sum(1 for b in annex if b["t"] == "h3"), "annex cards")
