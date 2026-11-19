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

all_commits = int(git("rev-list", "--all", "--count").strip())
hb = g["hours_by_day"]
long_days = sum(1 for v in hb.values() if v >= 6)
d0, d1 = datetime.date(2026, 7, 20), datetime.date(2026, 11, 19)
weekdays = sum(1 for i in range((d1 - d0).days + 1) if (d0 + datetime.timedelta(i)).weekday() < 5) - 4
IST = datetime.timezone(datetime.timedelta(hours=5, minutes=30))
stamps = [datetime.datetime.fromisoformat(x).astimezone(IST) for x in git("log", "--all", "--no-merges", "--format=%ad", "--date=iso-strict").split()]
byday = collections.defaultdict(list)
for t in stamps:
    byday[t.date()].append(t)
spans = {d: (max(v) - min(v)).total_seconds() / 3600 for d, v in byday.items()}
peak = max(byday, key=lambda d: len(byday[d]))
late = sum(1 for t in stamps if t.hour >= 19 or t.hour < 7)
wk_dates = ", ".join(d.strftime("%d/%m") for d in sorted(byday) if d.weekday() >= 5)
metrics = [
    ("Total commits in the repository, 19/08 - 19/11/26 (all branches)", all_commits, "git rev-list --all --count"),
    ("Working days in the period 20/07 - 19/11/26 (less 4 days leave)", weekdays, "Calendar"),
    ("Weekend days with AI-assisted work", weekend, f"git commit dates: {wk_dates}"),
    (f"Peak day ({peak.strftime('%d/%m/%y')}): commits", len(byday[peak]), f"work from {min(byday[peak]).strftime('%H:%M')} to {max(byday[peak]).strftime('%H:%M')} IST ({spans[peak]:.1f} h)"),
    ("Days with 8+ hours between first and last commit", sum(1 for v in spans.values() if v >= 8), "git commit timestamps (IST)"),
    ("Commits made after 19:00 or before 07:00 IST", late, "git commit timestamps (IST)"),
    ("Days with 6 or more hours of measured AI session time", long_days, "Commit work blocks"),
    ("Average commits per active day", round(all_commits / len(days), 1), "Total commits / active days"),
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
    ("Use cases completed", len(counted), "Master Register"),
    ("Distinct custom (Z/Y) SAP objects named in those use cases", len(objs), "SAP object lists of the issue logs"),
    ("Issue-log entries written (issue -> cause -> fix)", issue_entries, "ISSUES.md rows across the use-case folders"),
    ("Review corrections applied to AI output before go-live", rework, "Issue logs - activation feedback, functional review, test results"),
    ("Technical specification files produced", len(ts_docs), "Files named TS_* outside the 2025 archives"),
    ("Workflow skills built for the AI loop", 7, ".claude/skills: triage, fix-issue, ship-fix, from-fs, atc-fix, status, solve"),
    ("Release constraints recorded from activation failures", 56, "MEMORY.md section 4"),
    ("Past mistakes written up as standing rules", 31, "MEMORY.md section 5"),
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
    f"{all_commits} commits in under four months (git history 19/08 - 19/11/26), after 30 Claude Code sessions with 557 prompts from 20/07/26 - about {round(all_commits / len(days))} commits per active day.",
    f"Three engagements in parallel - PAL, ONGC Videsh (OVL) and Astral (KPMG) - on {len(days)} active days including {weekend} weekends; peak day {peak.strftime('%d/%m')} with {len(byday[peak])} commits over {spans[peak]:.1f} hours.",
    "ATC (ONGC): 847 assigned findings remediated through 205 correction blocks in 51 includes across 14 packages, with 76 reusable correction patterns.",
    "JIB Status management dashboard for ONGC Videsh: from requirement (03/11/26) to written client confirmation (17/11/26) in 11 working days.",
    f"{len(objs)} custom SAP objects built, enhanced or analysed; {len(ts_docs)} technical specifications; {issue_entries} issue-log entries; {code_lines:,} lines of code written.",
]
json.dump(dict(metrics=metrics, highlights=highlights, monthly=monthly, gaps=gaps, objects=sorted(objs)), open(os.path.join(D, "usage.json"), "w"), indent=1)
for m in metrics:
    print(m[0], "=", m[1])
print(monthly)
