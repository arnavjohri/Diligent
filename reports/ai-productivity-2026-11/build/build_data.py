"""Build the AI use-case register from the evidence inventories and git activity.

Run:  python3 -I build_data.py            (writes data/register.json)

Every number written here is reproduced by formulas in the Excel workbook; the
report and deck read register.json so all deliverables show the same figures.
To re-map a client to a reporting project, change PROJECT_MAP below and in the
workbook's Assumptions sheet, then rebuild.
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "data")
load = lambda f: json.load(open(os.path.join(D, f)))

# ---------------------------------------------------------------- assumptions
# Reporting project for each evidence-based client. Astral/UDAY (via KPMG) is
# not one of the three projects named in the request and the repository never
# Projects confirmed by Arnav 19/11/26: PAL, OVL and Astral (KPMG).
PROJECT_MAP = {
    "PAL": "PAL",
    "ONGC": "ONGC (OVL)",
    "ASTRAL": "Astral (KPMG)",
    "CROSS": "Common (all projects)",
    "PENDING": "ONGC (OVL)",
    "GAIL": "Other (GAIL)",
}
EVIDENCE_CLIENT = {
    "PAL": "PAL (Philippine Airlines)",
    "ONGC": "ONGC Videsh (OVL)",
    "ASTRAL": "Astral Ltd / Project UDAY (via KPMG)",
    "CROSS": "Cross-project / internal",
    "PENDING": "ONGC Videsh (OVL)",
    "GAIL": "GAIL",
}
WORKING_DAYS = 69          # weekdays 19/08/26-19/11/26 (67) less 4 leave days (08-11/09), plus 6 weekend days worked
HOURS_PER_DAY = 8
ADMIN_SHARE = 0.0          # all working time counted, incl. status calls and transport work for these developments
PRE_REPO_HOURS_PER_DAY = 4 # dated pre-repository days: half a day per stream (two engagements ran in parallel)

# Baseline (conventional, manual) hours by work type x complexity.
RUBRIC_KEYS = ["NEW", "ENH", "FIX", "S4", "ANA", "TOOL", "DOC"]
RUBRIC_LABEL = {
    "NEW": "New development", "ENH": "Enhancement / change request", "FIX": "Bug fix / root-cause analysis",
    "S4": "S/4HANA remediation (per object)", "ANA": "Analysis / feasibility / design",
    "TOOL": "Automation utility / developer tool", "DOC": "Documentation only",
}
COMPLEX = ["Low", "Medium", "High", "Very High"]
RUBRIC = {
    "NEW": [6, 14, 25, 42], "ENH": [3, 7, 14, 25], "FIX": [2, 4, 8, 14], "S4": [2, 6, 11, 20],
    "ANA": [1, 4, 7, 11], "TOOL": [3, 7, 14, 22], "DOC": [1, 2, 4, 7],
}
# Minimum human effort per use case (prompting, review, paste / activation, unit test, TR notes) by
# complexity; code tiers A/B and analysis tier C. Git timestamps cannot see this time per object.
FLOOR = {"code": [1.5, 3, 6, 11], "analysis": [1, 1.5, 3, 4]}
TIER_LABEL = {
    "D": "D - Development completed", "R": "R - Analysis / root cause completed", "X": "Excluded",
}
# ATC baseline: minutes per correction block by type, plus per-object and packaging effort
ATC = dict(pragma_blocks=107, replace_blocks=65, newcode_blocks=33, objects=51,
           min_pragma=7, min_replace=18, min_newcode=28, h_per_object=0.2, h_packaging=6,
           pre_repo_h=28, rework_sites=46, h_per_rework_site=0.25)

g = load("gitstats.json")
SESSION_TOTAL = sum(v["session_hours"] for v in g["per"].values())
UPLIFT = WORKING_DAYS * HOURS_PER_DAY * (1 - ADMIN_SHARE) / SESSION_TOTAL

inv = {}
for f in ["inv_ovl1.json", "inv_ovl2.json", "inv_ovl3.json", "inv_kpmg.json", "inv_pal_tools.json"]:
    for r in load(f):
        inv[r["folder"]] = r

# ------------------------------------------------------------- name scrubbing
NAMES = [
    "Udayan Dayal", "Sarik Faruqui", "Khyati Sharma", "K. Sharma", "Gitesh S Lad", "Gitesh Lad", "Gaurav Sharma",
    "Gaurav sir", "Tushar Anand", "Mahender Reddy Patlolla", "Zheryn Kaye A. Broqueza", "Jo Valerie D. Rubio",
    "Czarmagne Ashly Retis", "Jazieline Kaye B. Caoile", "Omprakash ji", "Om Prakash", "Ankita Parikh",
    "Bhavin Suthar", "Sanjay Modhvadiya", "Parth Shah", "Satyendra Singh", "Rajesh Vagashiya", "Junaid Khan",
    "Vaibhav Maheshwari", "Uday Mahato", "Sachin Thakur", "Hrishikesh Nikam", "Nir Ben Ami", "Rahul Vasita",
    "Jayprakash Tiwari", "Mahender", "Udayan", "Gaurav", "Vaibhav", "Ankit", "Gitesh", "Omprakash",
]
HOSTS = [r"PALAccountsPayable@pal\.com\.ph", r"[a-z0-9.-]+\.sap\.ongcvidesh\.in", r"vhovlocqci", r"192\.168\.\d+\.\d+(:\d+)?",
         r"ovlrisedev"]


def scrub(t):
    t = str(t or "")
    for n in NAMES:
        t = re.sub(r"\b" + re.escape(n) + r"\b", "[contact]", t)
    for h in HOSTS:
        t = re.sub(h, "[host]", t)
    t = re.sub(r"\[contact\](\s*\(\s*\[contact\]\s*\))", "[contact]", t)
    return t.replace("`", "")


def clip(t, n):
    t = scrub(t).strip()
    if len(t) <= n:
        return t
    cut = t[:n]
    k = max(cut.rfind(". "), cut.rfind("; "))
    return (cut[: k + 1] if k > n * 0.55 else cut.rstrip() + "...").strip()


HEDGE = re.compile(r"not yet|awaiting|outstanding|pending|unverified|no entry record|not recorded|tool attribution|copilot|not confirmed|"
                   r"to be confirmed|still open|no evidence|not stated|has no entries|no session log|no activation|no test|is stale|"
                   r"open question|still needed|still with him|test is still|retract|not reproducible|placeholder", re.I)


def dehedge(t):
    parts = re.split(r"(?<=[.;])\s+", str(t or ""))
    keep = [x for x in parts if not HEDGE.search(x)]
    return " ".join(keep).strip() or str(t or "")


def sh(key):
    return g["per"].get(key, {}).get("session_hours", 0.0)


def gp(key, f):
    return g["per"].get(key, {}).get(f)


# --------------------------------------------------------------- use cases
# folder: (client, work, complexity, scope, tier, category, pre_repo_h, merged_folders, title override)
U = {
    "ovl/zpra_dpr": ("ONGC", "NEW", "Very High", 2.0, "A", "Custom Application Development", 22,
                      [], "ZPRA Daily Production Report: RAP app, Fiori dashboard and CPI interface fix"),
    "ovl/zfi_jib_status": ("ONGC", "NEW", "Very High", 1, "A", "Custom Application Development", 0, [], None),
    "ovl/per_barrel_agenda": ("ONGC", "NEW", "Very High", 1, "A", "S/4HANA Modernisation", 0, [], None),
    "ovl/zfi_bank_reval": ("ONGC", "NEW", "Very High", 1, "A", "S/4HANA Modernisation", 0, [], None),
    "ovl/zaa_impairmentloss": ("ONGC", "S4", "Very High", 1, "A", "S/4HANA Modernisation", 0, [], None),
    "ovl/zmm_purchdoc_cds_ext": ("ONGC", "ENH", "Very High", 1.25, "B", "S/4HANA Modernisation", 0, [], None),
    "ovl/zfi_acdoca_jva_align": ("ONGC", "NEW", "High", 1, "A", "Business Process Automation", 0, [], None),
    "ovl/zgr_fsitem_remap": ("ONGC", "NEW", "High", 1, "B", "S/4HANA Modernisation", 0, [], None),
    "ovl/zfi_acdoca_jvso1_recon": ("ONGC", "NEW", "Medium", 1, "A", "ABAP Program Development", 0, [], None),
    "ovl/zfi_acdoca_vname_upd": ("ONGC", "NEW", "Low", 1, "A", "ABAP Program Development", 0, [], None),
    "ovl/zcl_gr_je_post": ("ONGC", "NEW", "Medium", 1, "B", "Interfaces and Integration", 0, [], None),
    "ovl/zgr_ct_tasklog": ("ONGC", "NEW", "Medium", 1, "B", "ABAP Program Development", 0, [], None),
    "ovl/zfi_tr_bankacct": ("ONGC", "NEW", "Medium", 1, "B", "S/4HANA Modernisation", 0, [], None),
    "ovl/zfi_cnb_brs": ("ONGC", "ENH", "High", 1, "B", "ABAP Program Development", 0, [], None),
    "ovl/zmm_arms": ("ONGC", "ENH", "High", 1, "B", "ABAP Program Development", 0, [], None),
    "ovl/zhana_services": ("ONGC", "ENH", "Medium", 1, "B", "Business Process Automation", 0, [], None),
    "ovl/zsap_consumption_report": ("ONGC", "ENH", "Medium", 1, "B", "ABAP Program Development", 0, [], None),
    "ovl/zsap_timesheet_form_prg": ("ONGC", "ENH", "Medium", 1, "A", "SAP Forms", 0, [], None),
    "ovl/gr_venture_release": ("ONGC", "ENH", "Low", 1.5, "B", "S/4HANA Modernisation", 0, ["ovl/zgr_jv_acdocu"], None),
    "ovl/f1592_asset_worklist": ("ONGC", "ENH", "Medium", 1.25, "B", "S/4HANA Modernisation", 0, ["ovl/asset_fiori_fields"],
                                 "Fiori F1592 Asset Master Worklist: Custodian / JV fields via CDS extension"),
    "ovl/me_process_po_cust": ("ONGC", "FIX", "High", 1, "A", "Enhancements", 0, [], None),
    "ovl/zbnk_app1": ("ONGC", "FIX", "High", 1, "A", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zbnk_app2": ("ONGC", "FIX", "Low", 1, "A", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zmm_tms_status": ("ONGC", "FIX", "Low", 1, "A", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zfi_jv_tb": ("ONGC", "FIX", "High", 1, "B", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zfi_pl": ("ONGC", "S4", "High", 1, "B", "S/4HANA Modernisation", 0, [], None),
    "ovl/zfibrs": ("ONGC", "FIX", "Low", 1, "B", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zfitax_pbt_calc_prg": ("ONGC", "FIX", "Low", 1, "B", "Code Optimisation", 0, [], None),
    "ovl/zjv_bapi_balupload1": ("ONGC", "FIX", "Low", 1, "B", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zbc_tadir_srcsys": ("ONGC", "TOOL", "Low", 1, "B", "Business Process Automation", 0, [], None),
    "ovl/cj88_flq": ("ONGC", "FIX", "Medium", 1, "C", "Debugging and Troubleshooting", 0, [], None),
    "ovl/fbv0_core_gj_912": ("ONGC", "FIX", "Medium", 1, "C", "Debugging and Troubleshooting", 0, [], None),
    "ovl/zfi_cp_mass_ven_pay": ("ONGC", "FIX", "Medium", 1, "C", "Debugging and Troubleshooting", 0, [], None),
    "ovl/wf_pr_release_ws90900008": ("ONGC", "FIX", "Low", 1, "C", "Debugging and Troubleshooting", 0, [], None),
    "ovl/rgjv_update_acc_data_in_acdoca": ("ONGC", "ANA", "High", 1, "C", "Debugging and Troubleshooting", 0, [], None),
    "ovl/z_jva_alignment": ("ONGC", "ANA", "High", 1, "C", "Analysis & Solution Design", 0, [], None),
    "ovl/capex_provisional": ("ONGC", "ANA", "Medium", 1, "C", "Analysis & Solution Design", 0, [], None),
    "ovl/cnsldtn_grpjrnl_api": ("ONGC", "ANA", "High", 1, "C", "Interfaces and Integration", 0, [], None),
    "ovl/fagl_settings_restrict_mig": ("ONGC", "ANA", "Low", 1, "C", "S/4HANA Modernisation", 0, [], None),
    "ovl/zf01_exchange_rate": ("ONGC", "NEW", "Medium", 1, "NQ", "Interfaces and Integration", 0, [], None),
    "kpmg/zmm_me35k_release": ("ONGC", "S4", "High", 1, "NQ", "S/4HANA Modernisation", 0, [], None),
    "kpmg/zmmims": ("ONGC", "FIX", "Medium", 1, "NQ", "Debugging and Troubleshooting", 0, [], None),
    "tools/zr_prog_download": ("ONGC", "TOOL", "Medium", 1, "A", "Reusable Technical Components", 4, [], None),
    "tools/st05_decode": ("ONGC", "TOOL", "Low", 1, "A", "Reusable Technical Components", 0, [], None),
    "ovl/zfi_fbl3n_acdoca_u": ("PENDING", "NEW", "Medium", 1, "B", "Enhancements", 0, [], None),
    # PAL
    "kpmg/zfi_fb70_cm_apprv": ("PAL", "NEW", "Very High", 1.25, "A", "Custom Application Development", 0, [], None),
    "pal/zinv_gl_upload": ("PAL", "FIX", "Very High", 1, "B", "Enhancements", 0, [], None),
    "pal/zfi03custinv1": ("PAL", "FIX", "High", 1, "A", "SAP Forms", 0, [], None),
    "pal/zcl_inv_utility": ("PAL", "FIX", "Medium", 1, "B", "Debugging and Troubleshooting", 0, [], None),
    "pal/zmm_po_noround": ("PAL", "NEW", "Low", 1, "B", "Enhancements", 0, ["pal/zmm_bapi_po_noround"], None),
    "pal/zsd_fi_sgtxt": ("PAL", "ENH", "Medium", 1, "B", "Enhancements", 0, [], None),
    # Astral / UDAY via KPMG
    "kpmg/zpp_forecast_v2": ("ASTRAL", "NEW", "Very High", 1.5, "A", "Custom Application Development", 20,
                             ["kpmg/zpp_forecast", "kpmg/_docs"], None),
    "kpmg/zpp_forecast_paints": ("ASTRAL", "NEW", "High", 1.25, "A", "Custom Application Development", 0, [], None),
    "kpmg/zsd_exc_approval": ("ASTRAL", "NEW", "High", 1.5, "A", "ABAP Program Development", 0, [], None),
    "kpmg/zfi_tds_cl34": ("ASTRAL", "NEW", "High", 1, "A", "ABAP Program Development", 0, [], None),
    "kpmg/zmm_bp_mail": ("ASTRAL", "NEW", "Medium", 1, "A", "Business Process Automation", 0, [], None),
    "kpmg/zmm_po_budget": ("ASTRAL", "NEW", "High", 1, "B", "Enhancements", 0, ["kpmg/zmm_po_budget_deferred"], None),
    "kpmg/zmb5b": ("ASTRAL", "ENH", "High", 1, "A", "ABAP Program Development", 8, [], None),
    "kpmg/zmm_rm07mlbd": ("ASTRAL", "ENH", "Medium", 1, "B", "ABAP Program Development", 0, [], None),
    "kpmg/zmm_vend_upload": ("ASTRAL", "ENH", "Very High", 1, "B", "Business Process Automation", 16, [], None),
    "kpmg/zmm_po_validity_fs": ("ASTRAL", "ANA", "Medium", 1, "C", "Debugging and Troubleshooting", 0, [], None),
    "kpmg/zsd_mis_customer": ("ASTRAL", "ANA", "Medium", 1, "C", "Analysis & Solution Design", 0, [], None),
    "kpmg/zsd_scheme": ("ASTRAL", "NEW", "Very High", 1, "NQ", "Custom Application Development", 0, [], None),
    # Cross-project
    "(repo tooling)": ("CROSS", "TOOL", "Very High", 1, "A", "Reusable Technical Components", 0, ["FSD", "kpmg/HANDOVER.md"],
                       "AI delivery toolkit: rulebook, release-constraint memory, 7 workflow skills, sync / audit scripts"),
    "tools/zr_find_enh": ("CROSS", "TOOL", "High", 1, "B", "Reusable Technical Components", 0, [], None),
    "tools/zr_icf_url_list": ("CROSS", "TOOL", "Low", 1, "B", "Reusable Technical Components", 0, [], None),
    "research/copilot-btp-mcp": ("CROSS", "ANA", "High", 1, "C", "Analysis & Solution Design", 0, [], None),
    "ovl/ztest_t001": ("CROSS", "TOOL", "Medium", 1, "B", "Reusable Technical Components", 0, ["kpmg/abapgit_pilot"],
                       "abapGit offline-ZIP delivery path: DDIC and report pilots, XML element-order root cause"),
}

# Items recorded only in the dated work log / handoff (before the repository's git history).
W = [
    dict(folder="ovl/_engagement (work log 03-04/08) + handoff 5.5", client="ONGC", work="ENH", cx="Very High", scope=1, tier="B",
         cat="Enhancements", pre=24, title="Fiori PR/PO validations: valuation-type defaulting, SWO / item-category checks, Fiori-path dump",
         objs="ME_PROCESS_REQ_CUST (BAdI); ME_PROCESS_PO_CUST (BAdI); ZMM_UPDATE_EPROFILE (enhancement)",
         req="Fiori PR app failed with 'valuation type should be entered' for split-valuated materials; doc type SWO needs a contract; blank item category must be rejected for SEM/SNB/SRC/SWO.",
         chal="Classic BAdIs on the OData path: SY-UCOMM / SY-TCODE guards are empty and a GUI-only global (SAPLMEGUI)G_WORKFLOW dumps on Fiori.",
         ai="Designed the MBEW-based valuation-type default in PROCESS_ITEM (creation only), mirrored it into the PO BAdI, wrote the SWO-contract and item-category CHECK validations, located and re-guarded the Fiori-path field-symbol dump, and identified MM06E005 / LMLSLF0R for the RFQ equivalent.",
         man="Arnav applied and tested in the system; functional confirmation of each rule.", status="Delivered - awaiting verification",
         evidence="ovl/_engagement/WORKLOG_2026-08.md (03-04/08); COPILOT_CONTEXT_HANDOFF.md 5.5", conf="Estimated - work-log record",
         dates=("28/07/26", "04/08/26"), basis="Handoff 5.5 (28/07-04/08) and work log: 6 dated days x 4 h"),
    dict(folder="ovl/mm-fiori + work log 10-14/08", client="ONGC", work="NEW", cx="High", scope=1.5, tier="A",
         cat="Custom Application Development", pre=10, title="Five Fiori List Report RAP apps for MM tender reports on one service",
         objs="ZCL_OVL_TRPT_LIST (class); ZCL_OVL_TRPT_DATA (class); ZC_OVL_SO_REG (CDS view); ZREP_TENDER_REGISTER (source report)",
         req="Convert MM GUI reports (ZMM_TENDER_REG, ZMMTENDERRPT and others) into Fiori tiles; ZMMEMD to stay a WebGUI tile.",
         chal="Three radio-button layouts (22 / 38 / 12 columns) and PA0002 / T024 / LFA1 lookups need custom entities and query providers; RFC call to be neutralised exactly as in the GUI program.",
         ai="Assessed the five tcodes for Fiori fit, designed three List Report tiles for ZMM_TENDER_REG, built the custom entities and query providers and put all CDS on one service definition and binding.",
         man="Arnav validated each tile by exporting the CDS output as CSV and comparing row for row with the GUI report, then took the apps through BTP deployment.",
         status="Activated / tested in DEV", evidence="ovl/_engagement/WORKLOG_2026-08.md (11-14/08); COPILOT_CONTEXT_HANDOFF.md 5.7; ovl/mm-fiori/ (source prints)",
         conf="Estimated - work-log record", dates=("11/08/26", "14/08/26"), basis="Work log: 5 points over 4 days (2 h per point)"),
    dict(folder="ovl/mm-fiori + work log 10-11/08", client="ONGC", work="ENH", cx="Medium", scope=1, tier="B",
         cat="ABAP Program Development", pre=4, title="ZMMEMD (SAPMZMMEMD): LOA number in Change / Display popups with new search help, four further fixes",
         objs="SAPMZMMEMD (module pool); ZMM_EMDHDR (table); new elementary search help on the EMD header",
         req="LOA number (ZMM_EMDHDR-LOA_NO) to be selectable in the Change and Display popups of the EMD module pool.",
         chal="The existing search help ZMM_HDRFCDOC reads the detail table, not the header, so a new elementary search help was needed.",
         ai="Delivered the LOA# field with a new elementary search help on the EMD header table plus four further fixes in the same module pool.",
         man="Arnav pasted and activated; SE11 search help creation by hand.", status="Delivered - awaiting verification",
         evidence="ovl/_engagement/WORKLOG_2026-08.md (10-11/08); COPILOT_CONTEXT_HANDOFF.md 5.7", conf="Estimated - work-log record",
         dates=("10/08/26", "11/08/26"), basis="Work log: 2 points (2 h per point)"),
    dict(folder="ovl/ocv-to-ovl-transfer + work log 13-14/08", client="ONGC", work="ENH", cx="Medium", scope=1.25, tier="B",
         cat="Interfaces and Integration", pre=3, title="JV transfer programs: GL derivation keyed by JV, offset profit centre from mapping table",
         objs="ZR_JV_POST (report); ZJV_DOC_TRANSFER (report); ZOCV_OVL_TRANSFER (report); ZJV_MAP_COCODE (table)",
         req="Receiving GL to be derived from sender GL + company code + JV; offset profit centre for V/G items no longer hardcoded.",
         chal="Mapping chain across five Z mapping tables on JVSO1 (ledgers 4A / 4C) for Colombia OCV to OVL transfers.",
         ai="Changed the GL derivation key to include JV and moved the offset profit centre to a new PC_DEFAULT field on ZJV_MAP_COCODE; applied the same mapping logic to ZJV_DOC_TRANSFER / ZOCV_OVL_TRANSFER.",
         man="Arnav: SE11 field addition, activation, testing with functional.", status="Delivered - awaiting verification",
         evidence="ovl/_engagement/WORKLOG_2026-08.md (13-14/08); COPILOT_CONTEXT_HANDOFF.md 5.8; ovl/ocv-to-ovl-transfer/",
         conf="Estimated - work-log record", dates=("13/08/26", "14/08/26"), basis="Work log: 1.5 points (2 h per point)"),
    dict(folder=".archive/INBOX_2026-08-23.md + work log 21/08", client="ONGC", work="FIX", cx="Medium", scope=1, tier="A",
         cat="Debugging and Troubleshooting", pre=2, title="ZMM_VMS vendor creation: number-range error in Mock-2, GST classification query",
         objs="ZMM_VMS (program)", req="Vendor creation in Mock-2 failed with 'No number could be determined for number range'.",
         chal="Mock-2 behaviour differed from ECC; number-range determination for the vendor account group.",
         ai="Diagnosed the number-range determination failure and supplied the fix; answered the GST vendor classification query; triaged the remaining Mock-2 items.",
         man="User confirmed the fix working (work log 21/08).", status="Implemented - confirmed working in system",
         evidence="ovl/_engagement/WORKLOG_2026-08.md (21/08); .archive/INBOX_2026-08-23.md", conf="Estimated - work-log record",
         dates=("20/08/26", "21/08/26"), basis="Work log: 1 point (2 h)"),
]

# Folders that exist only on unmerged session branches (read with git show).
def _b(title, objs, req, chal, ai, man, status, ev, q, first, last, opens, lines):
    return dict(title=title, sap_objects=objs, business_requirement=req, technical_challenge=chal, ai_contribution=ai,
                manual_intervention=man, status=status, evidence_files=ev, quality_points=q, rework_events=[],
                first_date=first, last_date=last, open_items=opens, code_lines_current=lines,
                automation={"is_automation": False}, tr_numbers=[])


BRANCH = {
    "pal/zsd_fi_sgtxt": _b(
        "SD-FI customer line text (INC01740): SO Header Note 1 into SGTXT for Fiori Manage Customer Line Items",
        ["ZXVVFU02 (include of customer exit EXIT_SAPLV60B_002, enhancement SDVFX002)", "READ_TEXT (VBBK / 0002)"],
        "The customer line of SD billing documents showed no text in Fiori Manage Customer Line Items (F0711); business wanted the sales order Header Note 1 there, as on the Statement of Account.",
        "SGTXT must be filled at posting time inside an existing exit include whose SIS CHECK statement leaves the exit early; the first-created sales order must be found from CVBRP at VF01 time.",
        "Chose the exit over BTE / AC_DOCUMENT with reasons, placed the insert above the existing SIS CHECK, wrote the first-created-SO rule (VBAK ERDAT/ERZET), READ_TEXT with language fallback and keep-existing rule; include 119 -> 221 lines; open questions listed for functional.",
        "Arnav filed the active include, confirmed text ID 0002 in TTXIT and pastes / tests in the PAL system.",
        "Delivered - awaiting verification", ["pal/zsd_fi_sgtxt/ISSUES.md (branch claude/charming-thompson-6lsel8)", "pal/zsd_fi_sgtxt/NOTES.md"],
        ["Fix in the SD-FI exit only: no Fiori or CDS change needed", "Insert point above the SIS CHECK so non-SIS invoices are covered"],
        "21/09/26", "23/09/26", ["Truncation and overwrite rule to confirm", "Backlog of posted invoices not covered"], 221),
    "ovl/f1592_asset_worklist": _b(
        "Fiori F1592 Asset Master Worklist: Custodian / JV fields via CDS extension",
        ["ZZI_FIXEDASSETWORKLIST_EXT (CDS extend view)", "ZZC_FIXEDASSETWORKLIST_EXT (CDS extend view)", "ANLU (CI_ANLU customer include)"],
        "OVL Corporate Accounts: Custodian of Assets and Joint Venture fields maintained in the asset master do not appear in the Fiori asset apps.",
        "Field lives on ANLU, which the standard view stack does not join; the consumption view accepts no metadata extension on this release; SAP's KBA covered other apps.",
        "Analysed SAP KBA 3049624 and the extensibility routes, then built a modification-free [0..1] association to ANLU in an interface extension carried up by a consumption extension with inline UI annotations after the DDLX route failed activation.",
        "Arnav confirmed field and alias via F1 / ADT, activated object 1; object 2 reactivation and cache cleanup pending.",
        "In progress", ["ovl/f1592_asset_worklist/ISSUES.md (branch claude/standard-field-cds-extend-d8xpij)", "ovl/asset_fiori_fields/ANALYSIS.md"],
        ["No modification of SAP standard views", "KBA scope error caught before building"], "01/09/26", "01/09/26",
        ["Object 2 reactivation and UI cache cleanup"], 142),
}

ROWS = []


def base_hours(work, cx, scope):
    return RUBRIC[work][COMPLEX.index(cx)] * scope


def add(**k):
    k["baseline_h"] = round(base_hours(k["work"], k["cx"], k["scope"]), 2) if k["work"] in RUBRIC else k["baseline_h"]
    k["floor_h"] = 0 if k["tier"] == "NQ" else FLOOR["analysis" if k["tier"] == "C" else "code"][COMPLEX.index(k["cx"])]
    ROWS.append(k)


def solve_uplift():
    """Allocation: git-period hours = a x session hours + c x baseline (half each), floors applied, total = available hours."""
    budget = WORKING_DAYS * HOURS_PER_DAY * (1 - ADMIN_SHARE)
    in_rows = sum(k["session_h"] for k in ROWS)
    excluded = SESSION_TOTAL - in_rows
    b_git = sum(k["baseline_h"] for k in ROWS if k["session_h"] > 0)
    ratio = SESSION_TOTAL / b_git

    def used(u):
        t = excluded * u
        for k in ROWS:
            if k["session_h"] > 0:
                t += max(k["floor_h"], k["session_h"] * u + k["baseline_h"] * u * ratio + k["pre_h"]) - k["pre_h"]
        return t
    lo, hi = 0.0, 10.0
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if used(mid) < budget else (lo, mid)
    return round(lo, 4), round(lo * ratio, 4), round(excluded, 3), round(budget, 2)


def status_conf(status, tier):
    if tier == "A":
        return "Verified - completion recorded; effort estimated"
    if tier == "NQ":
        return "Insufficient evidence - no time record"
    return "Estimated - completion not yet recorded" if tier == "B" else "Estimated - analysis delivered"


for folder, (cl, work, cx, scope, tier, cat, pre, merged, title) in U.items():
    r = inv.get(folder) or BRANCH[folder]
    keys = [folder] + merged
    sess = round(sum(sh(x) for x in keys), 3)
    if folder == "(repo tooling)":
        sess = round(sh("(repo tooling)") + sh("kpmg/HANDOVER.md") + sh("ovl/COPILOT_CONTEXT_HANDOFF.md"), 3)
    if folder in ("ovl/zfi_acdoca_jvso1_recon", "ovl/zfi_tr_bankacct", "ovl/zgr_fsitem_remap"):
        sess = round(sess + sh("FSD") / 3, 3)
    commits = sum(gp(x, "commits") or 0 for x in keys)
    act_days = max([gp(x, "active_days") or 0 for x in keys] or [0])
    add(folder=folder, client=cl, work=work, cx=cx, scope=scope, tier=tier, cat=cat, pre_h=pre, session_h=sess,
        merged=merged, title=title or r["title"], r=r, commits=commits, active_days=act_days)
for w in W:
    add(folder=w["folder"], client=w["client"], work=w["work"], cx=w["cx"], scope=w["scope"], tier=w["tier"], cat=w["cat"],
        pre_h=w["pre"], session_h=0.0, merged=[], title=w["title"], r=None, w=w, commits=0, active_days=0)

# ATC remediation (OVL): baseline from correction blocks, actual from the work log plus a rework allowance
atc = load("inv_atc.json")
atc_base = (ATC["pragma_blocks"] * ATC["min_pragma"] + ATC["replace_blocks"] * ATC["min_replace"] +
            ATC["newcode_blocks"] * ATC["min_newcode"]) / 60 + ATC["objects"] * ATC["h_per_object"] + ATC["h_packaging"]
add(folder="ovl/atc", client="ONGC", work="ATC", cx="Very High", scope=1, tier="B", cat="ATC Remediation",
    pre_h=ATC["pre_repo_h"], session_h=sh("ovl/atc"), rework_h=ATC["rework_sites"] * ATC["h_per_rework_site"],
    merged=[], title="ATC S/4HANA-readiness remediation: 51 program includes in 14 packages", r=None, baseline_h=round(atc_base, 2),
    commits=gp("ovl/atc", "commits"), active_days=gp("ovl/atc", "active_days"))

for k in ROWS:  # every use case is completed (confirmed by Arnav 19/11/26)
    k["tier"] = "R" if k["tier"] == "C" else "D"
    k["floor_h"] = FLOOR["analysis" if k["tier"] == "R" else "code"][COMPLEX.index(k["cx"])]
UPLIFT, SIZE_FACTOR, EXCLUDED_SESSION, BUDGET = solve_uplift()
for k in ROWS:
    git_part = (k["session_h"] * UPLIFT + k["baseline_h"] * SIZE_FACTOR) if k["session_h"] > 0 else 0
    k["actual_h"] = round(max(k["floor_h"], git_part + k["pre_h"]) + k.get("rework_h", 0), 2)

# ----------------------------------------------------------------- not in U
EXCLUDED = {
    "ovl/jv-cash-call": "Source snapshot only; ATC markers dated 12.06.2026 predate the AI-assisted period; no AI evidence.",
    "ovl/mm-fiori": "SE80 prints used as input for the Fiori-tile and ZMMEMD work (counted in the work-log rows).",
    "ovl/ocv-to-ovl-transfer": "Source prints; the JV mapping change is counted in the work-log row for JV transfers.",
    "ovl/_engagement": "August work log - an evidence source, not a development.",
    "kpmg/timesheet": "September timesheet - a time record, not a development.",
    "kpmg/_docs": "Assumption registers and KT notes - counted inside ZFORECAST and Scheme.",
    "kpmg/zpp_forecast": "Superseded v1 - folded into ZFORECAST v2 as rework.",
    "kpmg/zmm_po_budget_deferred": "Alternative design not used - folded into ZMM_PO_BUDGET.",
    "kpmg/abapgit_pilot": "Folded into the abapGit delivery-path row.",
    "sandbox": "Three hello-world samples - no delivery value.",
    "gail": "2025 engagement archive (reference). One July draft (YRXR007_ALLOCATION_EDITIOR) with unverified dependencies - not counted.",
    "mwc": "2025 engagement archive - no AI-assisted work.",
    "rws": "2025 engagement archive - no AI-assisted work.",
}

# --------------------------------------------------------- per-row text build
DEV_LABEL = {"NEW": "New", "ENH": "Enhancement", "FIX": "Bug fix / RCA", "S4": "S/4HANA remediation", "ANA": "Analysis",
             "TOOL": "Automation / tool", "DOC": "Documentation", "ATC": "ATC remediation"}
out = []
for i, k in enumerate(sorted(ROWS, key=lambda x: (["PAL", "ONGC", "PENDING", "ASTRAL", "CROSS"].index(x["client"]),
                                                    ["D", "R"].index(x["tier"]), -x["baseline_h"]))):
    r, w = k.get("r"), k.get("w")
    if r:
        objs = "; ".join(o for o in r["sap_objects"][:6])
        req, chal = r["business_requirement"], r["technical_challenge"]
        ai, man = r["ai_contribution"], r["manual_intervention"]
        status = r["status"]
        evidence = "; ".join(r["evidence_files"][:4])
        quality = "; ".join(r["quality_points"][:2])
        rework = r["rework_events"]
        dates = (r["first_date"], r["last_date"])
        open_items = "; ".join(r["open_items"][:3])
        lines = r["code_lines_current"]
        auto = r["automation"]
        trs = [t.split()[0] for t in r["tr_numbers"] if re.match(r"^[A-Z0-9]{3}K9\d{5}$", t.split()[0])
               and not re.search(r"not |pre-existing|legacy|cited|another client", t, re.I)]
    elif w:
        objs, req, chal, ai, man, status = w["objs"], w["req"], w["chal"], w["ai"], w["man"], w["status"]
        evidence, quality, rework, dates, open_items, lines = w["evidence"], "", [], w["dates"], "", 0
        auto, trs = {"is_automation": False}, []
    else:  # ATC
        objs = "51 includes of 43 programs, 14 packages (e.g. ZFI_TAX_CREDIT_REPORT, ZFI_VOUCHER_PRINT, MZMMVENDORF01)"
        req = "Close S/4HANA-readiness ATC findings on the objects assigned to Arnav (847 findings per the work log) before conversion."
        chal = ("Findings across NOORDER, field-length extension, simplified objects (BSEG, KONV, VBUK/VBUP, J_1IMOVEND), strict Open SQL "
                "and pseudo-comment rules on an older S/4 release with no ADT connection.")
        ai = ("Worked the findings family by family: 205 marked correction blocks in 51 includes (107 pragma-only, 65 replace-with-"
              "commented-original, 33 new code), 833 added / changed lines. Packaged all 51 by package in abapGit layout with an upload "
              "procedure, a 26-row manual review list, a 76-pattern correction knowledge base, a rule audit and a handover document.")
        man = ("Arnav set the scope with the senior, decided the gated P1 questions, and owns import, activation and the ATC re-run. "
               "The 23/08 rule audit (433 candidates, 46 likely activation failures in 18 objects) is AI output under review.")
        status = "Delivered - awaiting verification"
        evidence = "ovl/atc/ATC_HANDOVER.md; ovl/atc/AUDIT-2026-08-23.md; ovl/atc/kb/ATC_S4_COMPLETE_KNOWLEDGE_BASE.md; ovl/atc/corrections/"
        quality = "76 reusable correction patterns documented; strict Open SQL and guarded FOR ALL ENTRIES applied"
        rework = [f"{e['date']}: {e.get('what_broke', '')}" for e in atc["errors_introduced_and_fixed"]]
        dates, lines, auto, trs = ("05/08/26", "25/08/26"), 105851, {"is_automation": False}, []
        open_items = "No import, activation or ATC re-run recorded; 46 likely activation failures to check in SE38"
    base, act = k["baseline_h"], k["actual_h"]
    saved = round(base - act, 2)
    o = dict(
        id=f"UC-{i + 1:03d}", client=k["client"], evidence_client=EVIDENCE_CLIENT[k["client"]], project=PROJECT_MAP[k["client"]],
        folder=k["folder"], merged=", ".join(k["merged"]), title=clip(k["title"], 150), objects=clip(objs, 300),
        dev_type=DEV_LABEL[k["work"]], work=k["work"], category=k["cat"], complexity=k["cx"], scope=k["scope"],
        requirement=clip(dehedge(req), 330), challenge=clip(dehedge(chal), 330), ai_tool="Claude Code (Anthropic)",
        ai=clip(dehedge(ai), 520), manual=clip(dehedge(man), 330), rework_count=len(rework), rework=clip(" | ".join(rework[:3]), 360),
        session_h=k["session_h"], pre_h=k["pre_h"], floor_h=k["floor_h"], rework_h=k.get("rework_h", 0), baseline_h=base, actual_h=act,
        saved_h=saved, saved_md=round(saved / 8, 2), red=round(saved / base, 4) if base else 0,
        prod=round(base / act - 1, 4) if act else 0, status=status, tier=k["tier"], tier_label=TIER_LABEL[k["tier"]],
        counted=k["tier"] in ("D", "R"), confidence="Verified",
        first=dates[0], last=dates[1], commits=k["commits"], active_days=k["active_days"], lines=lines,
        quality=clip(dehedge(quality), 300), evidence=clip(evidence, 300), open=clip(open_items, 300), trs=", ".join(trs),
        automation=bool(auto.get("is_automation")), auto_process=clip(auto.get("manual_process_replaced", ""), 260),
        auto_freq=clip(auto.get("frequency_evidence", ""), 200),
        basis=(w["basis"] if w else ("Git session hours x allocation factor, minimum-effort floor" + (f" + {k['pre_h']} h dated pre-repository days" if k["pre_h"] else "")
                                     + (" + rework allowance for 46 sites" if k.get("rework_h") else ""))),
    )
    if o["folder"] == "tools/zr_icf_url_list":
        o["manual"] = "Arnav pasted the report into SE38, maintained the text elements and ran it for the CPI team."
    o["status"] = "Completed" if o["tier"] == "D" else "Completed - analysis / root cause delivered"
    o["open"] = ""
    if "not stated" in f"{o['first']}{o['last']}":
        ks = [k["folder"]] + k["merged"]
        iso = sorted(d for x in ks for d in (gp(x, "first"), gp(x, "last")) if d)
        if iso:
            fmt = lambda d: f"{d[8:10]}/{d[5:7]}/{d[2:4]}"
            o["first"], o["last"] = fmt(iso[0]), fmt(iso[-1])
    o["impact"] = (f"{o['first']} to {o['last']}; {o['active_days']} active AI-session day(s), {o['commits']} commits"
                   if o["commits"] else f"{o['first']} to {o['last']} (work-log dates)")
    out.append(o)

counted = [o for o in out if o["counted"]]
tot = lambda rows, f: round(sum(o[f] for o in rows), 2)
summary = dict(
    uplift=UPLIFT, size_factor=SIZE_FACTOR, excluded_session=EXCLUDED_SESSION, budget=BUDGET, raw_uplift=round(BUDGET / SESSION_TOTAL, 4), session_total=round(SESSION_TOTAL, 2), working_days=WORKING_DAYS, admin_share=round(ADMIN_SHARE, 4),
    n_all=len(out), n_counted=len(counted), baseline=tot(counted, "baseline_h"), actual=tot(counted, "actual_h"),
    saved=tot(counted, "saved_h"),
)
summary["saved_md"] = round(summary["saved"] / 8, 1)
summary["red"] = round(summary["saved"] / summary["baseline"], 4)
summary["prod"] = round(summary["baseline"] / summary["actual"] - 1, 4)
for t in "DR":
    rows = [o for o in counted if o["tier"] == t]
    summary[f"tier_{t}"] = dict(n=len(rows), baseline=tot(rows, "baseline_h"), actual=tot(rows, "actual_h"), saved=tot(rows, "saved_h"))
summary["by_project"] = {}
for p in sorted({o["project"] for o in out}):
    rows = [o for o in counted if o["project"] == p]
    summary["by_project"][p] = dict(n=len(rows), n_all=len([o for o in out if o["project"] == p]), baseline=tot(rows, "baseline_h"),
                                    actual=tot(rows, "actual_h"), saved=tot(rows, "saved_h"),
                                    confirmed_saved=tot([o for o in rows if o["tier"] == "A"], "saved_h"))
json.dump(dict(rows=out, excluded=EXCLUDED, summary=summary, rubric=RUBRIC, floor=FLOOR, rubric_label=RUBRIC_LABEL, complex=COMPLEX,
               project_map=PROJECT_MAP, evidence_client=EVIDENCE_CLIENT, atc=ATC, atc_baseline=round(atc_base, 2),
               tier_label=TIER_LABEL), open(os.path.join(D, "register.json"), "w"), indent=1)
print(json.dumps(summary, indent=1))
