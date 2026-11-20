#!/usr/bin/env python3
"""Writes src/*.prog.xml (PROGDIR + text pool) for the three programs. PROGDIR order NAME, VARCL,
SUBC, FIXPT, UCCHECK and TPOOL item order ID, KEY, ENTRY, LENGTH are load-bearing (CLAUDE.md).
Selection texts carry LENGTH = text + 8, the abapGit convention."""
import os
SRC = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src")
HEAD = ('<?xml version="1.0" encoding="utf-8"?>\n'
        '<abapGit version="v1.0.0" serializer="LCL_OBJECT_PROG" serializer_version="v1.0.0">\n'
        ' <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">\n  <asx:values>\n')

def prog(name, title, sel):
    x = HEAD + ("   <PROGDIR>\n    <NAME>%s</NAME>\n    <VARCL>X</VARCL>\n    <SUBC>1</SUBC>\n"
                "    <FIXPT>X</FIXPT>\n    <UCCHECK>X</UCCHECK>\n   </PROGDIR>\n   <TPOOL>\n" % name)
    x += "    <item>\n     <ID>R</ID>\n     <ENTRY>%s</ENTRY>\n     <LENGTH>%d</LENGTH>\n    </item>\n" % (title, len(title))
    src = open(os.path.join(SRC, name.lower() + ".prog.abap")).read().lower()
    for key, text in sel:
        assert len(key) <= 8 and len(text) <= 30, (key, text)
        assert key.lower() in src, key
        x += ("    <item>\n     <ID>S</ID>\n     <KEY>%s</KEY>\n     <ENTRY>%s</ENTRY>\n"
              "     <LENGTH>%d</LENGTH>\n    </item>\n" % (key, text, len(text) + 8))
    x += "   </TPOOL>\n  </asx:values>\n </asx:abap>\n</abapGit>\n"
    open(os.path.join(SRC, name.lower() + ".prog.xml"), "w", newline="\n").write(x)

YEAR = ("P_GJAHR", "Financial Year (start year)")
COMMON = [YEAR, ("P_PERNO", "Fortnight Number (01-24)"), ("S_BU", "Business Unit"), ("S_PROJ", "Project Number")]
prog("ZFI_PCX_ENTRY", "Provisional Capex - Fortnightly Entry",
     COMMON + [("P_DISP", "Display Only"), ("P_ADM", "Correct a Frozen Fortnight")])
prog("ZFI_PCX_REPORT", "Provisional Capex - Utilisation Reports", COMMON + [
     ("R_CUM", "Cumulative Capex by Category"), ("R_HIS", "Cumulative Capex per Fortnight"),
     ("R_USD", "Capex per Period, USD Million"), ("R_INR", "Capex per Period, INR Crore"),
     ("R_ENT", "Capex by Entity, INR Crore"), ("R_CAT", "Capex by Category, INR Crore"),
     ("R_ITDU", "Inception to Date, USD Million"), ("R_ITDI", "Inception to Date, INR Crore"),
     ("R_STAT", "Entry Status of the Fortnight")])
prog("ZFI_PCX_ADMIN", "Provisional Capex - Fortnight Control", [YEAR,
     ("P_PERNO", "Fortnight Number (01-24)"), ("P_RATE", "TTA Rate (INR per USD)"),
     ("R_LIST", "Show the Calendar"), ("R_GEN", "Generate the 24 Fortnights"),
     ("R_NEXT", "Freeze Open, Open Next"), ("R_FRZ", "Freeze This Fortnight"),
     ("R_OPEN", "Reopen This Fortnight"), ("R_RATE", "Save TTA Rate of Fortnight")])
print("prog xml written")
