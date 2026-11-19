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

bodies = git("log", "--all", "--no-merges", "--format=@@@%an%n%B")
blocks = bodies.split("@@@")[1:]
ai_commits = sum(1 for b in blocks if "Co-Authored-By: Claude" in b or b.startswith("Claude\n"))
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
for line in git("log", "--all", "--no-merges", "--date=format:%Y-%m", "--format=@@@%ad", "--name-only").split("@@@")[1:]:
    ls = line.strip().split("\n")
    if any(x.split("/")[0] in ("ovl", "kpmg", "pal", "tools") for x in ls[1:]):
        month[ls[0]][2] += 1
names = {"2026-08": "Aug 2026 (from 19/08)", "2026-09": "Sep 2026", "2026-10": "Oct 2026", "2026-11": "Nov 2026 (to 19/11)"}
monthly = [[names[m], round(v[0], 1), len(v[1]), v[2]] for m, v in sorted(month.items())]

metrics = [
    ("Period of AI-assisted delivery covered", "20/07/26 - 19/11/26", "Claude Code handoff record (from 20/07) and git history (from 19/08)"),
    ("AI tool", "Claude Code (Anthropic)", "Co-author trailers on commits; handoff record. No other AI tool is evidenced in the repository."),
    ("Claude Code sessions, 20/07 - 15/08/26", 30, "COPILOT_CONTEXT_HANDOFF.md closing note: 30 session transcripts"),
    ("Prompts in those sessions", 557, "Same note: 557 prompts"),
    ("Cloud sessions since 19/08/26 (one branch per session)", len(branches), "git: origin/claude/* branches (sessions working directly on main not counted)"),
    ("Commits in the repository (all branches, non-merge)", len(blocks), "git log --all --no-merges"),
    ("  of which AI co-authored or AI-authored", ai_commits, "Co-Authored-By: Claude trailer or author 'Claude'"),
    ("Active days with AI-assisted commits (19/08 - 19/11/26)", len(days), f"git commit dates; {weekend} of them weekend days"),
    ("Measured AI session hours (19/08 - 19/11/26)", round(g["total_block_hours"], 1), "Commit timestamps grouped into work blocks (method on Effort Assumptions)"),
    ("Lines of ABAP / CDS / script code added in AI commits", code_lines, "git numstat; originals, imports, SE80 prints and single additions > 3,000 lines excluded; rewrites count again"),
    ("Lines of documentation added in AI commits (notes, TS, logs)", doc_lines, "git numstat on .md files"),
    ("Use cases supported (counted / listed)", f"{len(counted)} / {len(reg['rows'])}", "Master Register"),
    ("Distinct custom (Z/Y) SAP objects named in those use cases", len(objs), "SAP object lists of the issue logs"),
    ("Issue-log entries written (issue -> cause -> fix)", issue_entries, "ISSUES.md rows across the use-case folders"),
    ("Defects in AI output caught and corrected (rework events)", rework, "Rework events in the issue logs - activation errors, wrong assumptions, dumps"),
    ("Technical specification files produced", len(ts_docs), "Files named TS_* outside the 2025 archives"),
    ("Workflow skills built for the AI loop", 7, ".claude/skills: triage, fix-issue, ship-fix, from-fs, atc-fix, status, solve"),
    ("Release constraints recorded from activation failures", 56, "MEMORY.md section 4"),
    ("Past mistakes written up as standing rules", 31, "MEMORY.md section 5"),
]
gaps = [
    "No document, issue log, commit or timesheet in the repository names a project 'T&G'.",
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
json.dump(dict(metrics=metrics, monthly=monthly, gaps=gaps, objects=sorted(objs)), open(os.path.join(D, "usage.json"), "w"), indent=1)
for m in metrics:
    print(m[0], "=", m[1])
print(monthly)
