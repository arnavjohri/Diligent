"""AI consumption metrics from the repository.   python3 -I build_usage.py  (writes data/usage.json)"""
import json, os, re, subprocess, collections, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
D = os.path.join(HERE, "data")
reg = json.load(open(os.path.join(D, "register.json")))
g = json.load(open(os.path.join(D, "gitstats.json")))
auth = json.load(open(os.path.join(D, "authored.json")))
git = lambda *a: subprocess.run(["git", "-C", REPO, *a], capture_output=True, text=True).stdout

inv = {}
for f in ["inv_ovl1.json", "inv_ovl2.json", "inv_ovl3.json", "inv_kpmg.json", "inv_pal_tools.json"]:
    for r in json.load(open(os.path.join(D, f))):
        inv[r["folder"]] = r

# Commits that only touch this report folder are excluded, so the figures describe the delivery work itself.
raw = git("log", "--all", "--no-merges", "--format=@@@%H|%an%n%B@@FILES", "--name-only")
report_only, blocks = 0, []
for blk in raw.split("@@@")[1:]:
    head, _, files = blk.partition("@@FILES")
    fs = [l for l in files.strip().split("\n") if l.strip()]
    if fs and all(f.startswith("reports/") for f in fs):
        report_only += 1
        continue
    blocks.append(head)
ai_commits = sum(1 for b in blocks if "Co-Authored-By: Claude" in b or b.split("\n")[0].endswith("|Claude"))
branches = [b for b in git("branch", "-r").split() if b.startswith("origin/claude/")]
days = [datetime.date.fromisoformat(d) for d in g["days"]]
weekend = sum(1 for d in days if d.weekday() >= 5)

counted = [o for o in reg["rows"] if o["counted"]]
folders = set()
for o in reg["rows"]:
    if o["tier"] != "X":
        folders.add(o["folder"]); folders.update(x.strip() for x in o["merged"].split(",") if x.strip())
objs = set()
for f in folders:
    for n in inv.get(f, {}).get("sap_objects", []):
        tok = n.split(" ")[0].strip(";,")
        if re.match(r"^[ZY][A-Z0-9_/]{2,}$", tok):
            objs.add(tok)
issue_entries = sum(inv[f]["issue_log_entries"] for f in folders if f in inv)
rework = sum(o["rework_count"] for o in counted)
ts_docs = [l for l in git("ls-files").splitlines() if re.search(r"(^|/)TS[_ ]", os.path.basename(l)) and not l.startswith(("gail/", "mwc/", "rws/"))]
code_lines = sum(v for k, v in auth["code"].items() if not k.startswith(("gail", "mwc", "rws")))
doc_lines = sum(auth["md"].values())

month = collections.defaultdict(lambda: [0.0, set(), 0])
for d, x in g["perday"].items():
    month[d[:7]][0] += sum(x.values()); month[d[:7]][1].add(d)
# Commits per month on the same basis as the headline count: every commit in the history, less report-only commits.
allm = collections.Counter(git("log", "--all", "--date=format:%Y-%m", "--format=%ad").split())
repm = collections.Counter()
for line in git("log", "--all", "--no-merges", "--date=format:%Y-%m", "--format=@@@%ad", "--name-only").split("@@@")[1:]:
    ls = [x for x in line.strip().split("\n") if x.strip()]
    if len(ls) > 1 and all(x.startswith("reports/") for x in ls[1:]):
        repm[ls[0]] += 1
for mth in allm:
    month[mth][2] = allm[mth] - repm[mth]
names = {"2026-08": "Aug 2026 (from 19/08)", "2026-09": "Sep 2026", "2026-10": "Oct 2026", "2026-11": "Nov 2026 (to 19/11)"}
monthly = [[names[m], round(v[0], 1), len(v[1]), v[2]] for m, v in sorted(month.items())]

all_commits = int(git("rev-list", "--all", "--count").strip()) - report_only
assert sum(v[2] for v in month.values()) == all_commits, (sum(v[2] for v in month.values()), all_commits)
d0, d1 = datetime.date(2026, 7, 20), datetime.date(2026, 11, 19)
weekdays = sum(1 for i in range((d1 - d0).days + 1) if (d0 + datetime.timedelta(i)).weekday() < 5) - 4
wk_dates = ", ".join(d.strftime("%d/%m") for d in sorted(days) if d.weekday() >= 5)
n_ts = len(reg["ts_docs"])
metrics = [
    ("Commits in the work repository, 19/08 - 19/11/26", all_commits, "Repository history, all branches"),
    ("  of which AI-assisted (co-authored)", ai_commits, "Co-author record on each commit"),
    ("Working days in the period 20/07 - 19/11/26", weekdays, "Calendar, after 4 days of leave"),
    ("Days with AI-assisted commits, 19/08 - 19/11/26", len(days), "Commit dates"),
    ("  of which weekend days", weekend, f"Commit dates: {wk_dates}"),
    ("Claude Code sessions, 20/07 - 15/08/26", 30, "Session records"),
    ("Prompts in those sessions", 557, "Session records"),
    ("Claude Code cloud sessions, 19/08 - 19/11/26", len(branches), "One working branch per session"),
    ("Measured AI session time, 19/08 - 19/11/26 (hours)", round(g["total_block_hours"]), "Commit timestamps grouped into working blocks"),
    ("Lines of ABAP / CDS / script code written in AI-assisted commits", code_lines, "Commit statistics; imported originals and bulk additions excluded"),
    ("Lines of documentation written (notes, specifications, logs)", doc_lines, "Commit statistics"),
    ("Use cases completed", len(counted), "Use-case register"),
    ("Custom SAP objects built, changed or analysed", len(objs), "Object lists of the use cases"),
    ("Issue-log entries written (issue, cause, fix)", issue_entries, "Issue log of each object"),
    ("Technical specifications produced", n_ts, "Annex D"),
    ("Corrections to AI output logged during review and testing", reg["summary"]["corrections"], "Issue logs"),
    ("Release constraints recorded and reused", 56, "Toolkit record of activation constraints"),
    ("Workflow skills in the AI delivery toolkit", 7, "Toolkit"),
]
gaps = [
    "Client timesheets record hours per client per day, not per object; they were not used as per-object effort actuals.",
    "No conventional (manual) effort baselines exist in project records; baselines are rubric estimates by work type and complexity.",
    "ATC: no import, activation, syntax check or ATC re-run of the 51 corrected includes is recorded; the 847-finding figure comes from the work log, not from an export in the repository.",
    "20/07 - 18/08/26 has dated narrative records only (handoff, work log, timesheet text) - no timestamps; 17-19/08 have no record.",
    "AI token / cost consumption is not stored in the repository.",
    "No billing or day rates are recorded, so no monetary value is computed.",
    f"{len([o for o in counted if o['tier'] == 'B'])} delivered use cases have no recorded activation / test result (tier B); each confirmation moves it to tier A.",
    "Four AI-era deliveries have no session or time record and are listed but not quantified.",
    "Mail threads, meetings, SAP-side debugging and testing that produced no commit are not visible in the repository.",
]
highlights = [
    f"{all_commits} commits in under four months on {len(days)} working days with AI sessions, {weekend} of them weekends.",
    "Three projects in parallel: PAL, ONGC Videsh (OVL) and Astral (KPMG).",
    "ATC (ONGC): 847 assigned findings worked through 205 correction blocks in 51 includes across 14 packages.",
    "JIB Status management dashboard for ONGC Videsh: built in three working days; client confirmation in writing on 17/11/26.",
    f"{len(objs)} custom SAP objects built, changed or analysed; {n_ts} technical specifications; {code_lines:,} lines of code written.",
]
json.dump(dict(metrics=metrics, highlights=highlights, monthly=monthly, gaps=gaps, objects=sorted(objs)), open(os.path.join(D, "usage.json"), "w"), indent=1)
for m in metrics:
    print(m[0], "=", m[1])
print(monthly)
