#!/usr/bin/env python3
"""Generates the abapGit DDIC files of the TASA recon tile in ../src and the SM30 load sheet.
XML shapes are the ones of ovl/capex_provisional/build/build_ddic.py (pulled on OCD 23/11/26).
    python3 ovl/zfi_tasa_recon/build/build_ddic.py"""
import os
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src")

# name, datatype, length, decimals, outputlen, text
DOMS = [
 ("ZFI_TASA_PCT", "DEC", 5, 2, 7, "TASA recon: percentage"),
]
# name, domain, short(10), medium(20), long(40)
DTELS = [
 ("ZFI_TASA_PARTNER", "KUNNR", "Partner", "Customer / G/L", "Customer or G/L Account (Partner)"),
 ("ZFI_TASA_ROWTXT", "TEXT60", "Row", "Project / Subsidiary", "Project / Subsidiary (Report Row)"),
 ("ZFI_TASA_SORTNO", "NUMC3", "Sort No.", "Sort Number", "Sort Number in Reports"),
 ("ZFI_TASA_TASAFL", "XFELD", "TASA", "TASA Customer", "TASA Customer"),
 ("ZFI_TASA_RELPTY", "XFELD", "Rel. Party", "Related Party", "Related Party Income"),
 ("ZFI_TASA_RECLFL", "XFELD", "Reclass", "In Reclassification", "Include in Reclassification (100616)"),
 ("ZFI_TASA_PROVPC", "ZFI_TASA_PCT", "Prov. %", "Provision %", "Provision in % of the Balance"),
]
# table, text, [(field, key, data element)]
TABLES = [
 ("ZFI_TASA_MAP", "TASA recon: customer / G/L to report row",
  [("BUKRS", 1, "BUKRS"), ("PARTNER", 1, "ZFI_TASA_PARTNER"), ("ROWTXT", 0, "ZFI_TASA_ROWTXT"),
   ("SORTNO", 0, "ZFI_TASA_SORTNO"), ("TASAFL", 0, "ZFI_TASA_TASAFL"), ("RELPTY", 0, "ZFI_TASA_RELPTY"),
   ("RECLFL", 0, "ZFI_TASA_RECLFL"), ("PROVPC", 0, "ZFI_TASA_PROVPC")]),
]

# SM30 entries: partner, row text, sort, TASA, related party, reclass, provision %
# Source: workbook sheets Customer List, P&L-TASA (rows 6-27, 32) and BS - Customer Balance (rows 4-50, 57)
MAP = [
 ("10042", "B-2", "010", "X", "", "", ""), ("B2NONTRADE", "B-2", "010", "X", "", "", ""),
 ("10033", "CPO-5", "020", "X", "", "", ""), ("CPO5NT", "CPO-5", "020", "X", "", "", ""),
 ("10041", "EP-3", "030", "X", "", "", ""), ("EP3NT", "EP-3", "030", "X", "", "", ""),
 ("10034", "Iran Farsi", "040", "X", "", "", ""), ("OVLFARSINT", "Iran Farsi", "040", "X", "", "", ""),
 ("10036", "OAAL", "050", "X", "X", "X", ""),
 ("10035", "ONGBV", "060", "X", "X", "X", ""),
 ("10068", "ONGCSCBV", "070", "X", "X", "X", ""),
 ("10027", "OVSL", "080", "X", "X", "X", ""), ("30002", "OVSL", "080", "X", "X", "", ""),
 ("10028", "OVVL", "090", "X", "X", "X", ""), ("30001", "OVVL", "090", "X", "X", "", ""),
 ("10067", "Petro Carabobo Ganga BV", "100", "X", "", "X", ""),
 ("10084", "RC8", "110", "X", "", "", ""),
 ("10032", "RC-10", "120", "X", "", "", ""), ("RC10NT", "RC-10", "120", "X", "", "", ""),
 ("10071", "SPOC", "130", "X", "", "", ""),
 ("10063", "Sakhalin-1, Russia", "140", "X", "", "", ""), ("EXXONNT", "Sakhalin-1, Russia", "140", "X", "", "", ""),
 ("10039", "SS-04", "150", "X", "", "", ""), ("SS04NT", "SS-04", "150", "X", "", "", ""),
 ("10062", "IEMEL", "160", "X", "", "", ""),
 ("10064", "FOGBV", "170", "X", "", "X", ""),
 ("10040", "SS-09", "180", "X", "", "", ""), ("SS09NT", "SS-09", "180", "X", "", "", ""),
 ("10129", "OOIL", "190", "X", "X", "X", ""),
 ("10134", "OVRL - TASA Income", "200", "X", "X", "X", ""),
 ("10135", "MECL", "210", "X", "X", "X", ""),
 ("80801", "Block 128", "220", "X", "", "", ""),
 ("GUAOFFNT", "Gua Offshore", "230", "X", "", "", ""),
 ("10059", "AIOC Azerbaijan", "500", "", "", "", ""),
 ("10086", "OIL India Limited", "510", "", "", "", ""),
 ("10099", "GAIL (India) Limited", "520", "", "", "", ""),
 ("10100", "Engineer India Limited", "530", "", "", "", ""),
 ("10101", "Indian Oil Corporation Limited", "540", "", "", "", ""),
 ("10121", "M/s Abdin International", "550", "", "", "", ""),
 ("10123", "Oil and Natural Gas Corporation Ltd", "560", "", "", "", ""),
 ("10126", "Bharat Petro Resources Limited", "570", "", "", "", ""),
 ("BPRL", "Bharat Petro Resources Limited", "570", "", "", "", ""),
 ("30003", "Bharat Petro Resources Limited", "570", "", "", "", ""),
 ("10133", "Cosmic Systems", "580", "", "", "", ""),
 ("10137", "Prakriti Power Systems", "590", "", "", "", ""),
 ("10140", "Genuine Agencies", "600", "", "", "", ""),
 ("IPRNT", "IPR - Non Trade", "610", "", "", "", "100.00"),
 ("10044", "Other - Employee", "900", "", "", "", ""), ("10045", "Other - Employee", "900", "", "", "", ""),
 ("10048", "Other - Employee", "900", "", "", "", ""), ("10049", "Other - Employee", "900", "", "", "", ""),
 ("EMP_OVLD01", "Other - Employee", "900", "", "", "", ""),
 ("10057", "Other - Scrap Sale", "910", "", "", "", ""),
 ("10069", "Other - Alsaad Traders - Scrap Sale", "910", "", "", "", ""),
 ("10070", "Other - Ecolite - Scrap Sale", "910", "", "", "", ""),
 ("10065", "Other - Petrotech-2019 A/c FIPI", "920", "", "", "", ""),
 ("10075", "Other - Superior Securitas", "930", "", "", "", ""),
 ("10076", "Other - Udal Ram", "940", "", "", "", ""),
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
    for n, typ, ln, dec, out, txt in DOMS:
        x = HEAD % "DOMA" + "   <DD01V>\n    <DOMNAME>%s</DOMNAME>\n    <DDLANGUAGE>E</DDLANGUAGE>\n" % n
        x += "    <DATATYPE>%s</DATATYPE>\n    <LENG>%06d</LENG>\n" % (typ, ln)
        if dec:
            x += "    <DECIMALS>%06d</DECIMALS>\n" % dec
        x += "    <OUTPUTLEN>%06d</OUTPUTLEN>\n    <DDTEXT>%s</DDTEXT>\n   </DD01V>\n" % (out, escape(txt))
        put(n.lower() + ".doma.xml", x + TAIL)
    for n, dom, s, m, l in DTELS:
        x = HEAD % "DTEL" + "   <DD04V>\n    <ROLLNAME>%s</ROLLNAME>\n    <DDLANGUAGE>E</DDLANGUAGE>\n" % n
        x += "    <DOMNAME>%s</DOMNAME>\n    <HEADLEN>20</HEADLEN>\n    <SCRLEN1>10</SCRLEN1>\n" % dom
        x += "    <SCRLEN2>20</SCRLEN2>\n    <SCRLEN3>40</SCRLEN3>\n    <DDTEXT>%s</DDTEXT>\n" % escape(l)
        x += "    <REPTEXT>%s</REPTEXT>\n    <SCRTEXT_S>%s</SCRTEXT_S>\n" % (escape(m), escape(s))
        x += "    <SCRTEXT_M>%s</SCRTEXT_M>\n    <SCRTEXT_L>%s</SCRTEXT_L>\n" % (escape(m), escape(l))
        x += "    <DTELMASTER>E</DTELMASTER>\n   </DD04V>\n"
        put(n.lower() + ".dtel.xml", x + TAIL)
    known = {d[0] for d in DTELS} | {"MANDT", "BUKRS"}
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
    # SM30 load sheet: tab-separated, columns in the order of the maintenance screen
    os.makedirs(os.path.join(ROOT, "load"), exist_ok=True)
    keys = set()
    with open(os.path.join(ROOT, "load", "ZFI_TASA_MAP_load.txt"), "w", encoding="utf-8", newline="\n") as f:
        for row in MAP:
            assert row[0] not in keys, row[0]
            keys.add(row[0])
            assert len(row[1]) <= 60
            f.write("\t".join(("OVL",) + row) + "\n")
    print("DDIC:", len(DOMS), "DOMA", len(DTELS), "DTEL", len(TABLES), "TABL;", len(MAP), "map rows")


if __name__ == "__main__":
    main()
