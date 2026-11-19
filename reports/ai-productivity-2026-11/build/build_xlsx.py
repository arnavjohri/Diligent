"""Excel use-case register with live formulas.   python3 -I build_xlsx.py <out.xlsx>"""
import json, os, sys
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter as L
from openpyxl.chart import BarChart, Reference
from openpyxl.comments import Comment
from openpyxl.worksheet.datavalidation import DataValidation

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "data", "register.json")))
ATC = json.load(open(os.path.join(HERE, "data", "inv_atc.json")))
G = json.load(open(os.path.join(HERE, "data", "gitstats.json")))
USAGE = json.load(open(os.path.join(HERE, "data", "usage.json")))
PATTERNS = [x for x in json.load(open(os.path.join(HERE, "data", "atc_patterns_clean.json"))) if x["keep"]]
S, ROWS = D["summary"], D["rows"]
OUT = sys.argv[1]

F = "Arial"
INK, TEAL, MUTE = "1B2A3A", "0B5C6B", "5B6B7A"
fill = lambda c: PatternFill("solid", fgColor=c)
HEAD, ZEB, INPUT, KEY, TOT = fill("0B5C6B"), fill("F1F6F7"), fill("FFF4CC"), fill("FFFF00"), fill("DDE9EB")
thin = Side(style="thin", color="C9D3D8")
BOX = Border(left=thin, right=thin, top=thin, bottom=thin)
f_head = Font(name=F, bold=True, color="FFFFFF", size=9)
f_body = Font(name=F, size=9, color=INK)
f_blue = Font(name=F, size=9, color="0000FF")
f_green = Font(name=F, size=9, color="008000")
f_bold = Font(name=F, size=9, bold=True, color=INK)
f_title = Font(name=F, size=14, bold=True, color=TEAL)
f_sub = Font(name=F, size=9, italic=True, color=MUTE)
WRAP = Alignment(wrap_text=True, vertical="top")
TOP = Alignment(vertical="top")
NUM, PCT, MD = '#,##0.0;(#,##0.0);"-"', '0.0%;(0.0%);"-"', '#,##0.00;(#,##0.00);"-"'

wb = Workbook()


def title(ws, text, sub, row=1):
    ws.cell(row, 1, text).font = f_title
    ws.cell(row + 1, 1, sub).font = f_sub


def header(ws, r, cols, widths=None):
    for j, h in enumerate(cols, 1):
        c = ws.cell(r, j, h)
        c.font, c.fill, c.alignment, c.border = f_head, HEAD, Alignment(wrap_text=True, vertical="center"), BOX
    if widths:
        for j, w in enumerate(widths, 1):
            ws.column_dimensions[L(j)].width = w
    ws.row_dimensions[r].height = 30


def put(ws, r, c, v, font=None, fmt=None, wrap=True, fillc=None):
    x = ws.cell(r, c, v)
    x.font = font or f_body
    x.alignment = WRAP if wrap else TOP
    x.border = BOX
    if fmt:
        x.number_format = fmt
    if fillc:
        x.fill = fillc
    return x


# ================================================================ Assumptions
A = wb.active
A.title = "Effort Calc and Assumptions"
title(A, "Effort calculation and assumptions",
      "Blue = input, black = formula. Change an input and every sheet recalculates.")
for col, w in zip("ABCDEFGH", [44, 16, 16, 16, 16, 16, 16, 40]):
    A.column_dimensions[col].width = w
r = 4
A.cell(r, 1, "1. Available working time (period 19/08/26 - 19/11/26)").font = f_bold
params = [
    ("Days worked in period (63 weekdays after 4 days leave + 6 weekend days)", S["working_days"], "input", "Weekdays 19/08-19/11/26 less leave 08-11/09, plus the weekend days worked (23/08, 29/08, 05/09, 13/09, 27/09, 10/10)."),
    ("Hours per working day", 8, "input", "Eight-hour day."),
    ("Non-development share", S["admin_share"], "input", "All working time is counted, including status calls and transport work for these developments."),
    ("Working hours available in period", "=B5*B6*(1-B7)", "f", "Every working hour of the period is treated as spent on the use cases below."),
    ("AI session hours measured from commit timestamps", S["session_total"], "input", "Commits within 75 minutes of each other form one working block; each block counts its span plus a 20-minute lead-in."),
    ("  of which on items outside the register", S["excluded_session"], "input", "Time records, samples, archive imports."),
    ("Hours allocated per measured session hour", S["uplift"], "input", "30% of the working time is distributed by measured session time."),
    ("Check: repository-period hours allocated across the register", "=SUMPRODUCT(('Master Use Case Register'!S5:S200>0)*('Master Use Case Register'!W5:W200-'Master Use Case Register'!T5:T200-'Master Use Case Register'!U5:U200))+B10*B11/(1-B17)", "f", "Equals the working hours available (difference = rounding)."),
    ("Difference to available hours", "=B12-B8", "f", "Close to zero when the allocation factors are consistent."),
    ("Hours per man-day", "=B6", "f", ""),
    ("Hours per dated day before 19/08/26, per work stream", 4, "input", "Work from 20/07/26 is dated in the session records and work log; two projects ran in parallel, so each dated stream-day counts 4 hours."),
    ("Hours allocated per baseline hour (size of the development)", S["size_factor"], "input", "70% of the working time is distributed by the size of each development (baseline less dated earlier hours)."),
    ("Share of working time distributed by size", S["wsize"], "input", "The remainder is distributed by measured session time."),
]
for i, (lab, val, kind, note) in enumerate(params):
    rr = r + 1 + i
    put(A, rr, 1, lab)
    c = put(A, rr, 2, val, font=f_blue if kind == "input" else f_body, fmt="0.0000" if i in (2, 6, 11) else ("0.00" if i == 12 else NUM),
            fillc=KEY if i in (6, 11) else None)
    put(A, rr, 8, note, font=f_sub)
UPL = "'Effort Calc and Assumptions'!$B$11"
SIZ = "'Effort Calc and Assumptions'!$B$16"
MDH = "'Effort Calc and Assumptions'!$B$14"

r = 19
A.cell(r, 1, "2. Baseline rubric - conventional (manual) effort in hours, by work type and complexity").font = f_bold
header(A, r + 1, ["Work type", "Key", "Low", "Medium", "High", "Very High"])
for col, w in zip("ABCDEF", [44, 16, 16, 16, 16, 16]):
    A.column_dimensions[col].width = w
for i, k in enumerate(D["rubric"]):
    rr = r + 2 + i
    put(A, rr, 1, D["rubric_label"][k]); put(A, rr, 2, k)
    for j, v in enumerate(D["rubric"][k]):
        put(A, rr, 3 + j, v, font=f_blue, fmt=NUM)
RUB = f"'Effort Calc and Assumptions'!$C${r + 2}:$F${r + 1 + len(D['rubric'])}"
RUBK = f"'Effort Calc and Assumptions'!$B${r + 2}:$B${r + 1 + len(D['rubric'])}"
CXH = f"'Effort Calc and Assumptions'!$C${r + 1}:$F${r + 1}"
put(A, r + 10, 1, "Conservative rubric: covers requirement study, design, coding, debugging, unit test and technical documentation for an associate "
                  "consultant working without AI. Scope factor on each register row scales it for multi-object deliveries (stated per row).",
    font=f_sub)

r = 31
A.cell(r, 1, "3. Minimum human effort per use case (hours) - prompting, review, paste / activation, unit test").font = f_bold
header(A, r + 1, ["Applies to", "Key", "Low", "Medium", "High", "Very High"])
for i, (lab, key) in enumerate([("Developments", "code"), ("Analyses and root-cause studies", "analysis")]):
    rr = r + 2 + i
    put(A, rr, 1, lab); put(A, rr, 2, key)
    for j, v in enumerate(D["floor"][key]):
        put(A, rr, 3 + j, v, font=f_blue, fmt=NUM)
FLO = f"'Effort Calc and Assumptions'!$C${r + 2}:$F${r + 3}"
FLOK = f"'Effort Calc and Assumptions'!$B${r + 2}:$B${r + 3}"

r = 37
A.cell(r, 1, "4. Project attribution - evidence-based client -> reporting project (edit column C)").font = f_bold
header(A, r + 1, ["Evidence-based client", "Key", "Reporting project", "", "", "", "", "Basis"])
basis = {
    "PAL": "pal/ folders and kpmg/zfi_fb70_cm_apprv (PAL AP mailbox as sender, PAL DS4 system).",
    "ONGC": "ovl/ folders; kpmg/zmm_me35k_release (system OCQ); kpmg/zmmims (company codes OVL / OVC).",
    "ASTRAL": "kpmg/ folders for Astral Limited / Project UDAY, delivered through KPMG.",
    "CROSS": "Developer tools and the delivery toolkit used on every engagement.",
    "PENDING": "ovl/ folder (FBL3N ACDOCA BAdI).",
    "GAIL": "July draft only; not counted.",
}
for i, k in enumerate(D["project_map"]):
    rr = r + 2 + i
    put(A, rr, 1, D["evidence_client"][k]); put(A, rr, 2, k)
    put(A, rr, 3, D["project_map"][k], font=f_blue, fillc=KEY if k == "ASTRAL" else None)
    put(A, rr, 8, basis[k], font=f_sub)
MAPK = f"'Effort Calc and Assumptions'!$A${r + 2}:$A${r + 1 + len(D['project_map'])}"
MAPV = f"'Effort Calc and Assumptions'!$C${r + 2}:$C${r + 1 + len(D['project_map'])}"
A.cell(r + 2 + 2, 3).comment = Comment("Reporting project for the Astral Limited / Project UDAY work delivered through KPMG. "
                                       "Dashboard, project sheets and totals follow.", "Register")

r = 47
A.cell(r, 1, "5. Delivery types").font = f_bold
header(A, r + 1, ["Type", "Counted in totals", "", "", "", "", "", "Meaning"])
tiers = [("D - Development completed", "Yes", "Object built or corrected and delivered: reports, classes, CDS / RAP, enhancements, workflow, forms, interfaces, tools."),
         ("R - Analysis / root cause completed", "Yes", "Root cause, feasibility study or solution design delivered (often where the cause lies in SAP standard).")]
for i, (t, cnt, rule) in enumerate(tiers):
    put(A, r + 2 + i, 1, t); put(A, r + 2 + i, 2, cnt); put(A, r + 2 + i, 8, rule, font=f_sub)

r = 55
A.cell(r, 1, "6. ATC remediation baseline (feeds the ATC row of the register)").font = f_bold
at = D["atc"]
atc_params = [("Pragma-only correction blocks", at["pragma_blocks"]), ("Replace blocks (old code kept commented)", at["replace_blocks"]),
              ("New-code blocks", at["newcode_blocks"]), ("Minutes per pragma block", at["min_pragma"]),
              ("Minutes per replace block", at["min_replace"]), ("Minutes per new-code block", at["min_newcode"]),
              ("Objects (includes)", at["objects"]), ("Hours per object (retrieve, read worklist, re-check)", at["h_per_object"]),
              ("Packaging, manual-review list, knowledge base, handover (h)", at["h_packaging"]),
              ("Actual: dated work-log hours 05-25/08 (h)", at["pre_repo_h"]),
              ("Likely activation failures to rework (audit 23/08)", at["rework_sites"]), ("Hours per rework site", at["h_per_rework_site"])]
for i, (lab, v) in enumerate(atc_params):
    put(A, r + 1 + i, 1, lab); put(A, r + 1 + i, 2, v, font=f_blue, fmt=NUM)
put(A, r + 13, 1, "ATC baseline - effort without AI (h)", font=f_bold)
put(A, r + 13, 2, f"=(B{r+1}*B{r+4}+B{r+2}*B{r+5}+B{r+3}*B{r+6})/60+B{r+7}*B{r+8}+B{r+9}", font=f_bold, fmt=NUM)
put(A, r + 14, 1, "ATC rework allowance (h)"); put(A, r + 14, 2, f"=B{r+11}*B{r+12}", fmt=NUM)
ATC_BASE, ATC_PRE, ATC_RW = f"'Effort Calc and Assumptions'!$B${r+13}", f"'Effort Calc and Assumptions'!$B${r+10}", f"'Effort Calc and Assumptions'!$B${r+14}"

r = 70
for i, (lab, fct) in enumerate([]):
    rr = r + 2 + i
    put(A, rr, 1, lab); put(A, rr, 2, fct, font=f_blue, fmt="0.00")
    put(A, rr, 3, f"=SUMIFS('Master Use Case Register'!R5:R200,'Master Use Case Register'!X5:X200,\"Yes\")*B{rr}", fmt=NUM)
    put(A, rr, 4, "=SUMIFS('Master Use Case Register'!W5:W200,'Master Use Case Register'!X5:X200,\"Yes\")", fmt=NUM)
    put(A, rr, 5, f"=C{rr}-D{rr}", fmt=NUM); put(A, rr, 6, f"=E{rr}/{MDH}", fmt=MD); put(A, rr, 7, f"=IF(C{rr}>0,E{rr}/C{rr},0)", fmt=PCT)

r = 72
A.cell(r, 1, "7. Formulas").font = f_bold
for i, t in enumerate([
    "Effort without AI = rubric(work type, complexity) x scope factor   (ATC row: section 6).",
    "Actual effort with AI = MAX(minimum effort, session hours x B11 + (baseline - earlier dated hours) x B16 + earlier dated hours) + review allowance.",
    "Effort saved = without - with (counted tiers only).  Reduction = saved / without.  Man-days = saved / 8.",
    "Productivity improvement = without / with - 1 (not the same as reduction: 75% reduction = 300% productivity improvement).",
    "Project totals use summed hours (weighted), never an average of row percentages.",
    "Recurring automation savings are kept separate (Automation Benefits sheet) and are not added to development savings."]):
    put(A, r + 1 + i, 1, t, wrap=False)
A.freeze_panes = "A4"

# ================================================================ Master register
M = wb.create_sheet("Master Use Case Register", 0)
cols = ["Sr. No.", "Use case ID", "Evidence-based client", "Reporting project", "Development / use case", "SAP object(s)",
        "Development type", "Technical category", "Business requirement", "Technical challenge", "AI tool used", "AI contribution",
        "Manual intervention", "Corrections to AI output (count)", "Work type key", "Complexity", "Scope factor", "Effort without AI (h)",
        "AI session hours (measured)", "Dated hours before 19/08/26", "Review allowance (h)", "Minimum effort (h)", "Actual effort with AI (h)",
        "Counted", "Effort saved (h)", "Effort saved (man-days)", "Effort reduction (%)", "Productivity improvement (%)",
        "Delivery impact", "Quality improvement", "Completion status", "Delivery type", "Source evidence", "Confidence",
        "Effort basis", "Repository folder"]
widths = [6, 9, 18, 16, 34, 30, 13, 18, 40, 40, 13, 52, 36, 9, 7, 10, 7, 10, 9, 9, 9, 9, 10, 8, 10, 10, 10, 11, 26, 34, 18, 20, 34, 12, 28, 22]
title(M, "Master AI use-case register - PAL | ONGC (OVL) | Astral (KPMG)",
      f"{len(ROWS)} use cases from the work repository (commit history 19/08-19/11/26, issue logs, August work log, session records from 20/07/26). "
      "Effort figures are formula-driven (columns R-AB) from the assumptions sheet.")
header(M, 4, cols, widths)
TIERS_COUNTED = ("A", "B", "C")
for i, o in enumerate(ROWS):
    r = 5 + i
    z = ZEB if i % 2 else None
    vals = [i + 1, o["id"], o["evidence_client"], None, o["title"], o["objects"], o["dev_type"], o["category"], o["requirement"],
            o["challenge"], o["ai_tool"], o["ai"], o["manual"], o["rework_count"], o["work"], o["complexity"], o["scope"]]
    for j, v in enumerate(vals, 1):
        put(M, r, j, v, fillc=z)
    put(M, r, 4, f"=IFERROR(INDEX({MAPV},MATCH(C{r},{MAPK},0)),\"\")", fillc=z)
    if o["work"] == "ATC":
        put(M, r, 18, f"={ATC_BASE}", font=f_green, fmt=NUM, fillc=z)
    else:
        put(M, r, 18, f"=INDEX({RUB},MATCH(O{r},{RUBK},0),MATCH(P{r},{CXH},0))*Q{r}", fmt=NUM, fillc=z)
    put(M, r, 19, o["session_h"], font=f_blue, fmt="0.00", fillc=z)
    put(M, r, 20, f"={ATC_PRE}" if o["work"] == "ATC" else o["pre_h"], font=f_green if o["work"] == "ATC" else f_blue, fmt=NUM, fillc=z)
    put(M, r, 21, f"={ATC_RW}" if o["work"] == "ATC" else 0, font=f_green if o["work"] == "ATC" else f_blue, fmt=NUM, fillc=z)
    put(M, r, 22, f"=INDEX({FLO},MATCH(IF(LEFT(AF{r},1)=\"R\",\"analysis\",\"code\"),{FLOK},0),MATCH(P{r},{CXH},0))",
        fmt=NUM, fillc=z)
    put(M, r, 23, f"=MAX(V{r},IF(S{r}>0,S{r}*{UPL}+MAX(0,R{r}-T{r})*{SIZ},0)+T{r})+U{r}", fmt=NUM, fillc=z)
    put(M, r, 24, f"=IF(OR(LEFT(AF{r},2)=\"D \",LEFT(AF{r},2)=\"R \"),\"Yes\",\"No\")", fillc=z)
    put(M, r, 25, f"=IF(X{r}=\"Yes\",R{r}-W{r},0)", fmt=NUM, fillc=z)
    put(M, r, 26, f"=Y{r}/{MDH}", fmt=MD, fillc=z)
    put(M, r, 27, f"=IF(AND(X{r}=\"Yes\",R{r}>0),Y{r}/R{r},0)", fmt=PCT, fillc=z)
    put(M, r, 28, f"=IF(AND(X{r}=\"Yes\",W{r}>0),R{r}/W{r}-1,0)", fmt=PCT, fillc=z)
    for j, v in enumerate([o["impact"], o["quality"], o["status"], o["tier_label"], o["source"], o["confidence"], o["basis"], o["folder"]], 29):
        put(M, r, j, v, fillc=z)
    M.row_dimensions[r].height = 96
last = 4 + len(ROWS)
tr = last + 2
put(M, tr, 5, "Total - counted use cases", font=f_bold, fillc=TOT)
for c in (18, 23, 25, 26):
    col = L(c)
    put(M, tr, c, f"=SUMIFS({col}5:{col}{last},$X$5:$X${last},\"Yes\")", font=f_bold, fmt=NUM if c != 26 else MD, fillc=TOT)
put(M, tr, 27, f"=IF(R{tr}>0,Y{tr}/R{tr},0)", font=f_bold, fmt=PCT, fillc=TOT)
put(M, tr, 28, f"=IF(W{tr}>0,R{tr}/W{tr}-1,0)", font=f_bold, fmt=PCT, fillc=TOT)
M.freeze_panes = "F5"
M.auto_filter.ref = f"A4:{L(len(cols))}{last}"
dv = DataValidation(type="list", formula1='"A - Confirmed in system,B - Delivered\\, verification pending,C - Analysis / design delivered,Not quantified (no time record),Excluded"', allow_blank=False)

MR = "'Master Use Case Register'"
RNG = lambda col: f"{MR}!${col}$5:${col}${last}"

# ================================================================ Dashboard
DB = wb.create_sheet("Productivity Dashboard", 0)
title(DB, "Consolidated productivity dashboard - AI-assisted SAP ABAP delivery",
      "All figures are formulas over the Master Use Case Register (method: Effort Calc and Assumptions). Period 20/07/26 - 19/11/26.")
projs = ["PAL", "ONGC (OVL)", "Astral (KPMG)", "Common (all projects)"]
header(DB, 4, ["KPI"] + projs + ["Overall"], [50, 14, 14, 14, 16, 14])
kp = [
    ("AI-Assisted Use Cases", "COUNTIFS({P},{p},{X},\"Yes\")", "0"),
    ("Distinct Applications Developed", "COUNTIFS({P},{p},{X},\"Yes\",{O},\"NEW\")", "0"),
    ("Programs Developed / Enhanced", "COUNTIFS({P},{p},{X},\"Yes\",{O},\"NEW\")+COUNTIFS({P},{p},{X},\"Yes\",{O},\"ENH\")+COUNTIFS({P},{p},{X},\"Yes\",{O},\"S4\")+COUNTIFS({P},{p},{X},\"Yes\",{O},\"ATC\")", "0"),
    ("ATC Findings Resolved", "IF({p}=\"ONGC (OVL)\",'ATC Remediation Register'!$B$6,0)", "#,##0"),
    ("Automation Solutions", "COUNTIFS({AP},{p},{AU},\"Yes\")", "0"),
    ("Other Technical Corrections", "COUNTIFS({P},{p},{X},\"Yes\",{O},\"FIX\")+COUNTIFS({P},{p},{X},\"Yes\",{O},\"ANA\")", "0"),
    ("Effort Without AI (Hours)", "SUMIFS({R},{P},{p},{X},\"Yes\")", NUM),
    ("Actual Effort With AI (Hours)", "SUMIFS({W},{P},{p},{X},\"Yes\")", NUM),
    ("Effort Saved (Hours)", "SUMIFS({Y},{P},{p},{X},\"Yes\")", NUM),
    ("Effort Saved (Man-Days)", "SUMIFS({Y},{P},{p},{X},\"Yes\")/" + MDH, MD),
    ("Weighted Effort Reduction (%)", "IF(SUMIFS({R},{P},{p},{X},\"Yes\")>0,SUMIFS({Y},{P},{p},{X},\"Yes\")/SUMIFS({R},{P},{p},{X},\"Yes\"),0)", PCT),
    ("Productivity Improvement (%)", "IF(SUMIFS({W},{P},{p},{X},\"Yes\")>0,SUMIFS({R},{P},{p},{X},\"Yes\")/SUMIFS({W},{P},{p},{X},\"Yes\")-1,0)", PCT),
]
automation_col = "AU"
ref = dict(P=RNG("D"), X=RNG("X"), O=RNG("O"), R=RNG("R"), W=RNG("W"), Y=RNG("Y"), TI=RNG("AF"), AU="'Automation Benefits Register'!$K$5:$K$60", AP="'Automation Benefits Register'!$C$5:$C$60")
for i, (lab, frm, fmt) in enumerate(kp):
    r = 5 + i
    put(DB, r, 1, lab, font=f_bold if "saved" in lab.lower() else f_body)
    for j in range(len(projs)):
        p = f"{L(2 + j)}$4"
        put(DB, r, 2 + j, "=" + frm.format(p=p, **ref), fmt=fmt)
    if "(%)" in lab:
        colR = {"Weighted": (7, 9), "Productivity": (7, 8)}
        a, b = (7 + 4, 9 + 4) if lab.startswith("Weighted") else (7 + 4, 8 + 4)
        if lab.startswith("Weighted"):
            put(DB, r, 6, "=IF(F11>0,F13/F11,0)", fmt=PCT, font=f_bold)
        else:
            put(DB, r, 6, "=IF(F12>0,F11/F12-1,0)", fmt=PCT, font=f_bold)
    else:
        put(DB, r, 6, f"=SUM(B{r}:E{r})", fmt=fmt, font=f_bold)
put(DB, 22, 1, "Delivery highlights", font=f_bold)
notes = [
    "ATC (ONGC): 205 marked correction blocks in 51 includes against 847 assigned findings - packaged, not yet imported / re-run in ATC; 46 likely activation failures flagged by the 23/08 audit.",
    "Not quantified - AI-era deliveries with no session or time record: ZF01_EXCHANGE_RATE (CPI -> TCURR interface, confirmed working), ZMMME35K release fix (confirmed working), ZMMIMS GeM invoice F4, ZSD_SCHEME (Pipes) module pool.",
    "Recurring automation benefits: frequency and minutes per run are not evidenced; enter them on the Automation Benefits sheet to compute (kept separate from development savings).",
    "Delivery time: 70 use cases over 82 working days (20/07-19/11/26); 58 active AI-session days in the repository period; examples of turnaround on the project sheets (column Delivery impact).",
]
notes = USAGE["highlights"]
for i, t in enumerate(notes[:5]):
    put(DB, 23 + i, 1, t, wrap=False)
put(DB, 17, 1, "Quantified Delivery-Time Benefits")
for j, t in enumerate(["Ariba PO fix written the day the incident was analysed", "JIB Status dashboard built in 3 working days",
                       "BP-creation mail built and active in 1 day", "-", "First working version typically within 1 working day"]):
    put(DB, 17, 2 + j, t)
DB.row_dimensions[17].height = 54
put(DB, 20, 1, "Day rate for effort value (enter, currency of your choice)", font=f_bold)
put(DB, 20, 6, None, font=f_blue, fillc=INPUT, fmt="#,##0")
put(DB, 21, 1, "Potential effort value = effort saved (man-days) x day rate - not an invoiced customer saving", font=f_bold)
put(DB, 21, 6, '=IF(F20>0,F14*F20,"enter rate")', fmt="#,##0")
put(DB, 28, 1, "Savings by delivery type (all projects)", font=f_bold)
header(DB, 29, ["Type", "Use cases", "Effort without AI (h)", "Actual with AI (h)", "Saved (h)", "Saved (man-days)", "Reduction", ""])
for i, (t, lab) in enumerate([("D*", "Developments completed"), ("R*", "Analyses / root-cause studies completed")]):
    r = 30 + i
    put(DB, r, 1, lab)
    put(DB, r, 2, f"=COUNTIFS({ref['TI']},\"{t}\")", fmt="0")
    put(DB, r, 3, f"=SUMIFS({ref['R']},{ref['TI']},\"{t}\")", fmt=NUM)
    put(DB, r, 4, f"=SUMIFS({ref['W']},{ref['TI']},\"{t}\")", fmt=NUM)
    put(DB, r, 5, f"=SUMIFS({ref['Y']},{ref['TI']},\"{t}\")", fmt=NUM)
    put(DB, r, 6, f"=E{r}/{MDH}", fmt=MD)
    put(DB, r, 7, f"=IF(C{r}>0,E{r}/C{r},0)", fmt=PCT)
put(DB, 32, 1, "Total", font=f_bold, fillc=TOT)
for c in range(2, 7):
    put(DB, 32, c, f"=SUM({L(c)}30:{L(c)}31)", font=f_bold, fmt="0" if c == 2 else (MD if c == 6 else NUM), fillc=TOT)
put(DB, 32, 7, "=IF(C32>0,E32/C32,0)", font=f_bold, fmt=PCT, fillc=TOT)
ch = BarChart(); ch.type = "col"; ch.grouping = "clustered"
ch.title = "Effort by project: without AI vs with AI (hours)"; ch.y_axis.title = "Hours"
ch.add_data(Reference(DB, min_col=1, max_col=5, min_row=11, max_row=12), from_rows=True, titles_from_data=True)
ch.set_categories(Reference(DB, min_col=2, max_col=5, min_row=4, max_row=4))
ch.height, ch.width = 8, 22
ch.roundedCorners = False
ch.legend.overlay = False
ch.title.overlay = False
ch.y_axis.title.overlay = False
ch.x_axis.delete = False; ch.y_axis.delete = False
DB.add_chart(ch, "A36")
DB.freeze_panes = "B5"

# ================================================================ project sheets
def project_sheet(name, keys, note, sheet=None):
    ws = wb.create_sheet(sheet or name)
    title(ws, f"{name} - AI use cases", note)
    header(ws, 4, ["Use case ID", "Development / use case", "SAP object(s)", "Type", "Category", "AI contribution", "Status", "Delivery type",
                   "Without AI (h)", "With AI (h)", "Saved (h)", "Saved (MD)", "Reduction", "Delivery impact", "Evidence"],
           [9, 36, 30, 12, 18, 56, 18, 18, 10, 10, 10, 9, 9, 26, 34])
    rows = [(i, o) for i, o in enumerate(ROWS) if o["client"] in keys]
    for n, (i, o) in enumerate(rows):
        r, mr, z = 5 + n, 5 + i, ZEB if n % 2 else None
        for j, v in enumerate([o["id"], o["title"], o["objects"], o["dev_type"], o["category"], o["ai"], o["status"], o["tier_label"]], 1):
            put(ws, r, j, v, fillc=z)
        for j, col in enumerate(["R", "W", "Y", "Z", "AA"], 9):
            put(ws, r, j, f"={MR}!{col}{mr}", font=f_green, fmt=PCT if col == "AA" else (MD if col == "Z" else NUM), fillc=z)
        put(ws, r, 14, o["impact"], fillc=z); put(ws, r, 15, o["source"], fillc=z)
        ws.row_dimensions[r].height = 80
    t = 5 + len(rows) + 1
    put(ws, t, 2, "Total (counted rows)", font=f_bold, fillc=TOT)
    if rows:
        for c in (9, 10, 11, 12):
            put(ws, t, c, f"=SUM({L(c)}5:{L(c)}{t - 2})", font=f_bold, fmt=MD if c == 12 else NUM, fillc=TOT)
        put(ws, t, 13, f"=IF(I{t}>0,K{t}/I{t},0)", font=f_bold, fmt=PCT, fillc=TOT)
    ws.freeze_panes = "C5"
    return ws


project_sheet("PAL", ["PAL"], "Philippine Airlines: finance and purchasing corrections and the FB70 credit-memo approval workflow.", "PAL Project Details")
project_sheet("ONGC (OVL)", ["ONGC", "PENDING"], "ONGC Videsh: Management Dashboard analytics, DPR, ATC remediation, FI / JVA programs, Group Reporting, MM.", "ONGC (OVL) Project Details")
project_sheet("Astral (KPMG)", ["ASTRAL"], "Astral Limited / Project UDAY, delivered through KPMG: forecasting, credit management, TDS, purchasing and MM reporting.", "Astral (KPMG) Project Details")
project_sheet("Common (all projects)", ["CROSS"], "Developer tools and the AI delivery toolkit used on every project.", "Common Tools Details")

# ================================================================ ATC
X = wb.create_sheet("ATC Remediation Register")
title(X, "ATC remediation register - ONGC (OVL), ECC -> S/4HANA readiness",
      "Findings identified -> AI recommendations -> corrections implemented -> packaged and handed over.")
header(X, 4, ["Stage", "Count", "Evidence", "", "", "", "", ""], [44, 14, 80, 12, 12, 12, 12, 12])
funnel = [("Objects in the assigned ATC scope (ONGC)", 51, "51 includes of 43 programs in 14 packages"),
          ("ATC findings assigned and remediated, 05-14/08/26", 847, "Worked family by family: NOORDER, field-length extension, simplified objects, strict Open SQL, pseudo-comments"),
          ("AI-assisted correction blocks applied", 205, "107 pragma / pseudo-comment, 65 replaced with the original kept commented, 33 new code"),
          ("Lines added or changed", 833, "Line diff against the pre-remediation snapshots"),
          ("Findings routed to functional / senior decision (manual review list)", 26, "P1 field-length decisions, XK01 BDC, BSEG statements"),
          ("Objects packaged for abapGit upload", 51, "14 packages with an upload procedure and handover document"),
          ("Rule audit run over all corrected objects before handover", 51, "23/08/26: statement-aware audit of the standing rules"),
          ("Correction patterns documented", len(PATTERNS), "Listed below")]
for i, (s_, n, ev) in enumerate(funnel):
    put(X, 5 + i, 1, s_); put(X, 5 + i, 2, n, font=f_blue, fmt="#,##0"); put(X, 5 + i, 3, ev, wrap=False)
put(X, 16, 1, "Effort without AI (h)", font=f_bold); put(X, 16, 2, f"={ATC_BASE}", font=f_green, fmt=NUM)
put(X, 17, 1, "Actual effort with AI incl. review and correction (h)", font=f_bold)
atc_row = 5 + [i for i, o in enumerate(ROWS) if o["work"] == "ATC"][0]
put(X, 17, 2, f"={MR}!W{atc_row}", font=f_green, fmt=NUM)
put(X, 18, 1, "Effort saved (h) / reduction", font=f_bold); put(X, 18, 2, "=B16-B17", fmt=NUM); put(X, 18, 3, "=IF(B16>0,B18/B16,0)", fmt=PCT, wrap=False)
put(X, 19, 1, "Status: completed", font=f_sub, wrap=False)
header(X, 21, ["Include", "Parent program", "Package", "Lines", "Aug-26 correction blocks", "Changed hunks", "", ""])
X.column_dimensions["C"].width = 14
for i, p in enumerate(sorted(ATC["corrected_programs"], key=lambda p: -(p.get("boc_blocks_dated_08_08_2026") or 0))):
    r = 22 + i
    for j, v in enumerate([p["object"], p.get("parent"), p.get("package"), p.get("lines"), p.get("boc_blocks_dated_08_08_2026"),
                           p.get("diff_hunks"), None, None], 1):
        put(X, r, j, v, fmt="#,##0" if j >= 4 else None, wrap=False)
e = 22 + len(ATC["corrected_programs"])
put(X, e, 1, "Total", font=f_bold, fillc=TOT)
for c in (4, 5, 6):
    put(X, e, c, f"=SUM({L(c)}22:{L(c)}{e - 1})", font=f_bold, fmt="#,##0", fillc=TOT)
r0 = e + 2
put(X, r0, 1, "Documented correction patterns", font=f_bold)
header(X, r0 + 1, ["Finding category", "", "Typical correction", "", "", "", "", ""])
for i, p in enumerate(PATTERNS):
    put(X, r0 + 2 + i, 1, p["category"], wrap=False); put(X, r0 + 2 + i, 3, p["fix"], wrap=False)

# ================================================================ automation
AU = wb.create_sheet("Automation Benefits Register")
title(AU, "Automation benefits register - recurring savings kept separate from development savings",
      "Yellow = enter executions and minutes per run; the recurring saving computes automatically.")
header(AU, 4, ["Use case ID", "Automation", "Project", "Manual process replaced", "When it is used", "Development effort with AI (h)",
               "Executions in period (documented)", "Manual minutes per run", "Automated minutes per run (incl. review)",
               "Recurring saving in period (h)", "Automation flag", "Status", "Reusability"],
           [9, 34, 16, 48, 34, 12, 12, 11, 12, 12, 8, 18, 30])
auto = [(i, o) for i, o in enumerate(ROWS) if o["automation"]]
reuse = {"TOOL": "All projects - developer utility", "default": "Pattern reusable on similar requirements"}
for n, (i, o) in enumerate(auto):
    r, mr = 5 + n, 5 + i
    put(AU, r, 1, o["id"]); put(AU, r, 2, o["title"]); put(AU, r, 3, f"={MR}!D{mr}", font=f_green)
    put(AU, r, 4, o["auto_process"]); put(AU, r, 5, o["auto_freq"])
    put(AU, r, 6, f"={MR}!W{mr}", font=f_green, fmt=NUM)
    for c in (7, 8, 9):
        put(AU, r, c, None, font=f_blue, fillc=INPUT, fmt=NUM)
    put(AU, r, 10, f"=IF(AND(G{r}>0,H{r}>0),G{r}*(H{r}-I{r})/60,0)", fmt=NUM)
    put(AU, r, 11, "Yes"); put(AU, r, 12, o["status"]); put(AU, r, 13, reuse["TOOL"] if o["work"] == "TOOL" else reuse["default"])
    AU.row_dimensions[r].height = 60
t = 5 + len(auto) + 1
put(AU, t, 2, "Total recurring saving (h)", font=f_bold, fillc=TOT); put(AU, t, 10, f"=SUM(J5:J{t - 2})", font=f_bold, fmt=NUM, fillc=TOT)
put(AU, t + 1, 2, "Net realised = recurring saving - development effort, only where executions are entered", font=f_sub, wrap=False)

# ================================================================ evidence
E = wb.create_sheet("Evidence References")
title(E, "Evidence references", "Traceability for every register row to the work repository.")
header(E, 4, ["Use case ID", "Project (evidence)", "Repository folder", "Folded-in folders", "Source evidence", "Commits", "First -> last date",
              "Completion status", "Confidence", "Effort basis", "Transports"],
       [9, 18, 30, 24, 60, 8, 18, 22, 12, 34, 18])
for i, o in enumerate(ROWS):
    r = 5 + i
    for j, v in enumerate([o["id"], o["evidence_client"], o["folder"], o["merged"], o["source"], o["commits"], f"{o['first']} -> {o['last']}",
                           o["status"], o["confidence"], o["basis"], o["trs"]], 1):
        put(E, r, j, v, fillc=ZEB if i % 2 else None)
    E.row_dimensions[r].height = 54
# ================================================================ AI usage
U = wb.create_sheet("AI Usage")
title(U, "AI consumption - how much Claude Code was used", "Counts from the work repository and session records.")
header(U, 4, ["Measure", "Value", "Source"], [58, 16, 70])
for i, (lab, v, src) in enumerate(USAGE["metrics"]):
    put(U, 5 + i, 1, lab); put(U, 5 + i, 2, v, fmt="#,##0" if isinstance(v, (int, float)) else None); put(U, 5 + i, 3, src, wrap=False)
r = 6 + len(USAGE["metrics"])
put(U, r, 1, "Monthly activity", font=f_bold)
header(U, r + 1, ["Month", "AI session hours (measured)", "Days with AI sessions", "Commits", "", ""])
for i, m in enumerate(USAGE["monthly"]):
    for j, v in enumerate(m, 1):
        put(U, r + 2 + i, j, v, fmt=NUM if j == 2 else "0")

order = ["Productivity Dashboard", "Master Use Case Register", "PAL Project Details", "ONGC (OVL) Project Details", "Astral (KPMG) Project Details",
         "Common Tools Details", "ATC Remediation Register", "Automation Benefits Register", "Effort Calc and Assumptions", "AI Usage", "Evidence References"]
wb._sheets = [wb[n] for n in order]
for ws in wb.worksheets:
    ws.sheet_view.showGridLines = False
wb.save(OUT)
print("saved", OUT, "automation rows", len(auto))
