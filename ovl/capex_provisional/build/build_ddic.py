#!/usr/bin/env python3
"""Generates the abapGit DDIC files in ../src, the SE11 fallback sheet and the SM30 load sheets.
XML shapes are copied element for element from ovl/zfi_bank_reval/src (pulled on OCD 28/10/26)
and kpmg/zpp_forecast_paints/src (pulled 19/10/26). Run from anywhere:
    python3 ovl/capex_provisional/build/build_ddic.py [workbook.xlsx]
The workbook argument is optional; with it the load sheets are rebuilt as well."""
import os, re, sys
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src")

# name, datatype, length, decimals, outputlen, text, fixed values
DOMS = [
 ("ZFI_PCX_AMT", "DEC", 15, 2, 20, "Prov. Capex: amount, USD million / INR crore", []),
 ("ZFI_PCX_RATE", "DEC", 9, 5, 11, "Prov. Capex: exchange rate INR per USD", []),
 ("ZFI_PCX_NUMC2", "NUMC", 2, 0, 2, "Prov. Capex: fortnight number", []),
 ("ZFI_PCX_NUMC3", "NUMC", 3, 0, 3, "Prov. Capex: entity number", []),
 ("ZFI_PCX_NUMC4", "NUMC", 4, 0, 4, "Prov. Capex: project / sort number", []),
 ("ZFI_PCX_CHAR10", "CHAR", 10, 0, 10, "Prov. Capex: code, 10 characters", []),
 ("ZFI_PCX_CHAR60", "CHAR", 60, 0, 60, "Prov. Capex: text, 60 characters", []),
 ("ZFI_PCX_STATUS", "CHAR", 1, 0, 1, "Prov. Capex: fortnight entry status",
  [("O", "Open for entry"), ("F", "Frozen")]),
 ("ZFI_PCX_ENTTYP", "CHAR", 1, 0, 1, "Prov. Capex: entity type",
  [("S", "Subsidiary"), ("J", "Incorporated JV"), ("H", "HQ / directly held")]),
 ("ZFI_PCX_OPXCLS", "CHAR", 1, 0, 1, "Prov. Capex: Opex class of a project",
  [("C", "Consolidated block"), ("E", "Equity investee")]),
]
# name, domain, short(10), medium(20), long(40)
DTELS = [
 ("ZFI_PCX_PROJID", "ZFI_PCX_NUMC4", "Project", "Project Number", "Project Number"),
 ("ZFI_PCX_PROJNM", "ZFI_PCX_CHAR60", "Proj. Name", "Project Name", "Project Name"),
 ("ZFI_PCX_SORTNO", "ZFI_PCX_NUMC4", "Sort No.", "Sort Number", "Sort Number in Reports"),
 ("ZFI_PCX_ACTIVE", "XFELD", "Active", "Active", "Project Active"),
 ("ZFI_PCX_BU", "ZFI_PCX_CHAR10", "Bus. Unit", "Business Unit", "Business Unit"),
 ("ZFI_PCX_JVTXT", "ZFI_PCX_CHAR60", "JV Code", "JV Code(s)", "JV Code(s), Information Only"),
 ("ZFI_PCX_ENTID", "ZFI_PCX_NUMC3", "Entity", "Entity Number", "Entity Number"),
 ("ZFI_PCX_ENTNM", "ZFI_PCX_CHAR60", "Ent. Name", "Entity Name", "Entity Name"),
 ("ZFI_PCX_ENTTYP", "ZFI_PCX_ENTTYP", "Ent. Type", "Entity Type", "Entity Type"),
 ("ZFI_PCX_OPXCLS", "ZFI_PCX_OPXCLS", "Opex Class", "Opex Class", "Opex Class (Consolidated / Equity)"),
 ("ZFI_PCX_PERNO", "ZFI_PCX_NUMC2", "Fortnight", "Fortnight Number", "Fortnight Number (01-24)"),
 ("ZFI_PCX_CUTOFF", "DATUM", "Cutoff", "Cutoff Date", "Fortnight Cutoff Date"),
 ("ZFI_PCX_STATUS", "ZFI_PCX_STATUS", "Status", "Entry Status", "Fortnight Entry Status"),
 ("ZFI_PCX_CHTIME", "UZEIT", "Changed At", "Changed At", "Time of Last Change"),
 ("ZFI_PCX_TTARATE", "ZFI_PCX_RATE", "TTA Rate", "TTA Rate (INR/USD)", "TTA Rate for the Fortnight (INR/USD)"),
 ("ZFI_PCX_BERATE", "ZFI_PCX_RATE", "BE Rate", "BE Rate (INR/USD)", "Budget Estimate Rate (INR/USD)"),
 ("ZFI_PCX_RERATE", "ZFI_PCX_RATE", "RE Rate", "RE Rate (INR/USD)", "Revised Estimate Rate (INR/USD)"),
 ("ZFI_PCX_EWIP", "ZFI_PCX_AMT", "Cum. EWIP", "Cumulative EWIP", "Cumulative EWIP (USD Million)"),
 ("ZFI_PCX_DWIP", "ZFI_PCX_AMT", "Cum. DWIP", "Cumulative DWIP", "Cumulative DWIP (USD Million)"),
 ("ZFI_PCX_CWIP", "ZFI_PCX_AMT", "Cum. CWIP", "Cumulative CWIP", "Cumulative CWIP (USD Million)"),
 ("ZFI_PCX_OTHCAP", "ZFI_PCX_AMT", "Cum. Other", "Cum. Other Capex", "Cumulative Other Capex (USD Million)"),
 ("ZFI_PCX_CAPBE", "ZFI_PCX_AMT", "Capex BE", "Capex BE (USD Mn)", "Capex Budget Estimate (USD Million)"),
 ("ZFI_PCX_CAPRE", "ZFI_PCX_AMT", "Capex RE", "Capex RE (USD Mn)", "Capex Revised Estimate (USD Million)"),
 ("ZFI_PCX_ITDUSD", "ZFI_PCX_AMT", "Op.ITD USD", "Opening ITD (USD Mn)", "Opening ITD Capex (USD Million)"),
 ("ZFI_PCX_PYUSD", "ZFI_PCX_AMT", "PY Cap USD", "PY Capex (USD Mn)", "Prior-Year Actual Capex (USD Million)"),
 ("ZFI_PCX_ITDINR", "ZFI_PCX_AMT", "Op.ITD INR", "Opening ITD (INR Cr)", "Opening ITD Capex (INR Crore)"),
 ("ZFI_PCX_PYINR", "ZFI_PCX_AMT", "PY Cap INR", "PY Capex (INR Cr)", "Prior-Year Actual Capex (INR Crore)"),
]
# table, text, [(field, key, data element)]
TABLES = [
 ("ZFI_PCX_ENT", "Prov. Capex: entities (subsidiaries / JVs) for the roll-up",
  [("ENTID", 1, "ZFI_PCX_ENTID"), ("ENTNM", 0, "ZFI_PCX_ENTNM"), ("ENTTYP", 0, "ZFI_PCX_ENTTYP"),
   ("SORTNO", 0, "ZFI_PCX_SORTNO")]),
 ("ZFI_PCX_PROJ", "Prov. Capex: project master",
  [("PROJID", 1, "ZFI_PCX_PROJID"), ("PROJNM", 0, "ZFI_PCX_PROJNM"), ("SORTNO", 0, "ZFI_PCX_SORTNO"),
   ("ACTIVE", 0, "ZFI_PCX_ACTIVE"), ("BU", 0, "ZFI_PCX_BU"), ("ENTID", 0, "ZFI_PCX_ENTID"),
   ("JVTXT", 0, "ZFI_PCX_JVTXT"), ("OPXCLS", 0, "ZFI_PCX_OPXCLS")]),
 ("ZFI_PCX_FY", "Prov. Capex: budget rates per financial year",
  [("GJAHR", 1, "GJAHR"), ("BERATE", 0, "ZFI_PCX_BERATE"), ("RERATE", 0, "ZFI_PCX_RERATE")]),
 ("ZFI_PCX_PERIOD", "Prov. Capex: fortnight calendar, status and TTA rate",
  [("GJAHR", 1, "GJAHR"), ("PERNO", 1, "ZFI_PCX_PERNO"), ("CUTOFF", 0, "ZFI_PCX_CUTOFF"),
   ("STATUS", 0, "ZFI_PCX_STATUS"), ("TTARATE", 0, "ZFI_PCX_TTARATE")]),
 ("ZFI_PCX_FYPROJ", "Prov. Capex: budgets and opening ITD per year and project",
  [("GJAHR", 1, "GJAHR"), ("PROJID", 1, "ZFI_PCX_PROJID"), ("CAPBE", 0, "ZFI_PCX_CAPBE"),
   ("CAPRE", 0, "ZFI_PCX_CAPRE"), ("ITDUSD", 0, "ZFI_PCX_ITDUSD"), ("PYUSD", 0, "ZFI_PCX_PYUSD"),
   ("ITDINR", 0, "ZFI_PCX_ITDINR"), ("PYINR", 0, "ZFI_PCX_PYINR")]),
 ("ZFI_PCX_CAPEX", "Prov. Capex: cumulative Capex per fortnight and project",
  [("GJAHR", 1, "GJAHR"), ("PERNO", 1, "ZFI_PCX_PERNO"), ("PROJID", 1, "ZFI_PCX_PROJID"),
   ("EWIP", 0, "ZFI_PCX_EWIP"), ("DWIP", 0, "ZFI_PCX_DWIP"), ("CWIP", 0, "ZFI_PCX_CWIP"),
   ("OTHCAP", 0, "ZFI_PCX_OTHCAP"), ("AENAM", 0, "AENAM"), ("AEDAT", 0, "AEDAT"),
   ("AETIM", 0, "ZFI_PCX_CHTIME")]),
]

HEAD = ('<?xml version="1.0" encoding="utf-8"?>\n'
        '<abapGit version="v1.0.0" serializer="LCL_OBJECT_%s" serializer_version="v1.0.0">\n'
        ' <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">\n  <asx:values>\n')
TAIL = '  </asx:values>\n </asx:abap>\n</abapGit>\n'

def put(name, text):
    with open(os.path.join(SRC, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)

def main():
    os.makedirs(SRC, exist_ok=True)
    for n, t, s, m, l in DTELS:
        assert len(n) <= 30 and len(s) <= 10 and len(m) <= 20 and len(l) <= 40, n
    for n, typ, ln, dec, out, txt, fix in DOMS:
        assert len(txt) <= 60, n
        x = HEAD % "DOMA" + "   <DD01V>\n    <DOMNAME>%s</DOMNAME>\n    <DDLANGUAGE>E</DDLANGUAGE>\n" % n
        x += "    <DATATYPE>%s</DATATYPE>\n    <LENG>%06d</LENG>\n" % (typ, ln)
        if dec:
            x += "    <DECIMALS>%06d</DECIMALS>\n" % dec
        x += "    <OUTPUTLEN>%06d</OUTPUTLEN>\n    <DDTEXT>%s</DDTEXT>\n" % (out, escape(txt))
        if fix:
            x += "    <VALEXI>X</VALEXI>\n"
        x += "   </DD01V>\n"
        if fix:
            x += "   <DD07V_TAB>\n"
            for i, (v, d) in enumerate(fix, 1):
                x += ("    <DD07V>\n     <VALPOS>%04d</VALPOS>\n     <DDLANGUAGE>E</DDLANGUAGE>\n"
                      "     <DOMVALUE_L>%s</DOMVALUE_L>\n     <DDTEXT>%s</DDTEXT>\n    </DD07V>\n" % (i, v, escape(d)))
            x += "   </DD07V_TAB>\n"
        put(n.lower() + ".doma.xml", x + TAIL)
    for n, dom, s, m, l in DTELS:
        x = HEAD % "DTEL" + "   <DD04V>\n    <ROLLNAME>%s</ROLLNAME>\n    <DDLANGUAGE>E</DDLANGUAGE>\n" % n
        x += "    <DOMNAME>%s</DOMNAME>\n    <HEADLEN>20</HEADLEN>\n    <SCRLEN1>10</SCRLEN1>\n" % dom
        x += "    <SCRLEN2>20</SCRLEN2>\n    <SCRLEN3>40</SCRLEN3>\n    <DDTEXT>%s</DDTEXT>\n" % escape(l)
        x += "    <REPTEXT>%s</REPTEXT>\n    <SCRTEXT_S>%s</SCRTEXT_S>\n" % (escape(m), escape(s))
        x += "    <SCRTEXT_M>%s</SCRTEXT_M>\n    <SCRTEXT_L>%s</SCRTEXT_L>\n" % (escape(m), escape(l))
        x += "    <DTELMASTER>E</DTELMASTER>\n   </DD04V>\n"
        put(n.lower() + ".dtel.xml", x + TAIL)
    known = {d[0] for d in DTELS} | {"MANDT", "GJAHR", "AENAM", "AEDAT"}
    for n, txt, flds in TABLES:
        assert len(n) <= 16 and len(txt) <= 60, n
        x = HEAD % "TABL" + "   <DD02V>\n    <TABNAME>%s</TABNAME>\n    <DDLANGUAGE>E</DDLANGUAGE>\n" % n
        x += "    <TABCLASS>TRANSP</TABCLASS>\n    <DDTEXT>%s</DDTEXT>\n    <CONTFLAG>A</CONTFLAG>\n" % escape(txt)
        x += "    <MAINFLAG>X</MAINFLAG>\n    <EXCLASS>1</EXCLASS>\n   </DD02V>\n"
        x += "   <DD09L>\n    <TABNAME>%s</TABNAME>\n    <AS4LOCAL>A</AS4LOCAL>\n    <TABKAT>0</TABKAT>\n" % n
        x += "    <TABART>APPL0</TABART>\n    <BUFALLOW>N</BUFALLOW>\n   </DD09L>\n   <DD03P_TABLE>\n"
        for f, k, de in [("MANDT", 1, "MANDT")] + flds:
            assert de in known, de
            x += ("    <DD03P>\n     <FIELDNAME>%s</FIELDNAME>\n     <KEYFLAG>%s</KEYFLAG>\n"
                  "     <ROLLNAME>%s</ROLLNAME>\n     <ADMINFIELD>0</ADMINFIELD>\n     <NOTNULL>%s</NOTNULL>\n"
                  "     <COMPTYPE>E</COMPTYPE>\n    </DD03P>\n" % (f, "X" if k else "", de, "X" if k else ""))
        put(n.lower() + ".tabl.xml", x + "   </DD03P_TABLE>\n" + TAIL)
    # SE11 fallback sheet
    o = ["# DDIC of the Provisional Capex package — SE11 fallback sheet\n",
         "Generated by `build/build_ddic.py`; the same definitions are in `src/*.xml` of the ZIP.",
         "Use this only if the abapGit pull does not create an object. Order: domains, data elements, tables.\n",
         "## Domains (%d)\n" % len(DOMS), "| Domain | Type | Length | Decimals | Description | Fixed values |", "|---|---|---|---|---|---|"]
    for n, typ, ln, dec, out, txt, fix in DOMS:
        o.append("| `%s` | %s | %d | %s | %s | %s |" % (n, typ, ln, dec or "", txt,
                 " · ".join("%s = %s" % f for f in fix) + (" (no sign)" if typ == "DEC" else "")))
    o += ["\n## Data elements (%d)\n" % len(DTELS), "Short description = Long label. Heading = Medium label.\n",
          "| Data element | Domain | Short (10) | Medium (20) | Long (40) |", "|---|---|---|---|---|"]
    o += ["| `%s` | `%s` | %s | %s | %s |" % d for d in DTELS]
    o.append("\n## Tables (%d)\n" % len(TABLES))
    o.append("All: transparent, delivery class A, data class APPL0, size category 0, no buffering,")
    o.append("*Display/Maintenance Allowed*. `MANDT` (data element `MANDT`) is the first key field of each.\n")
    for n, txt, flds in TABLES:
        o += ["### `%s` — %s\n" % (n, txt), "| Field | Key | Data element |", "|---|---|---|"]
        o += ["| `%s` | %s | `%s` |" % (f, "X" if k else "", de) for f, k, de in flds]
        o.append("")
    with open(os.path.join(ROOT, "ddic", "01_domains_data_elements.md"), "w") as f:
        f.write("\n".join(o))
    print("DDIC:", len(DOMS), "DOMA", len(DTELS), "DTEL", len(TABLES), "TABL")
    if len(sys.argv) > 1:
        loads(sys.argv[1])

def cells(ref):
    out = []
    for part in ref.split(","):
        m = re.findall(r"[A-Z]+(\d+)", part)
        out += list(range(int(m[0]), int(m[-1]) + 1))
    return out

def loads(xlsx):
    import openpyxl
    wf = openpyxl.load_workbook(xlsx)
    wv = openpyxl.load_workbook(xlsx, data_only=True)
    ci, cv, ou = wf["Capex INR"], wv["Capex INR"], wf["Opex USD"]
    ent_of, ents = {}, []
    for r in range(92, 109):
        name = str(ci["C%d" % r].value).strip()
        typ = "S" if name.endswith("-Subsidiary") else "J" if name.endswith("Incorporated JV") else "H"
        eid = "%03d" % (r - 91)
        ents.append((eid, name[:60], typ, "%04d" % ((r - 91) * 10)))
        f = ci["E%d" % r].value
        if isinstance(f, str) and f.startswith("="):
            body = f[1:].replace("SUM(", "").replace(")", "").replace("+", ",")
            for row in cells(body):
                if row in ent_of:      # template counts the row twice: the named entity wins over HQ
                    print("  row %d (%s) is in entity %s and %s - kept %s" % (
                          row, str(ci["C%d" % row].value).strip(), ent_of[row], eid, ent_of[row]))
                    continue
                ent_of[row] = eid
    equity = set()
    for row in cells(ou["G80"].value[1:].replace("SUM(", "").replace(")", "")):
        equity.add(str(ou["E%d" % row].value).strip())
    equity.add("Sakhalin I, Russia")   # RE and actuals count it as equity investee (query 20)
    with open(os.path.join(ROOT, "load", "ZFI_PCX_ENT_load.txt"), "w") as f:
        f.write("\n".join("\t".join(e) for e in ents) + "\n")
    n = 0
    with open(os.path.join(ROOT, "load", "ZFI_PCX_PROJ_load.txt"), "w") as f:
        for r in range(12, 83):
            n += 1
            name = str(ci["C%d" % r].value).strip()
            jv = cv["D%d" % r].value
            jv = "" if jv in (0, None, "0") else str(jv)
            if r not in ent_of:    # in no Tab 5 formula: put under HQ so that the totals still agree
                print("  row %d (%s) is in no entity formula - set to %s" % (r, name, ents[-1][0]))
                ent_of[r] = ents[-1][0]
            f.write("\t".join(["%04d" % n, name[:60], "%04d" % (n * 10), "X", "", ent_of[r], jv,
                               "E" if name in equity else "C"]) + "\n")
    print("load:", len(ents), "entities,", n, "projects,", len(equity), "equity investees")

if __name__ == "__main__":
    main()
