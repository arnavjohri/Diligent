"""Generate the three Paints forecast tables as a mirror of the displayed ALV.
Shape and element order copied from the Adhesive table XMLs (which imported).
Run from kpmg/zpp_forecast_paints:  python3 -I tools/mktables.py
"""
import re
SRC = "../zpp_forecast_v2/src/zppt_fcst_yr.tabl.xml"
DST = "src"
BLOCK = r"    <DD03P>\n(?:     <[^\n]*\n)*?    </DD03P>\n"

t0 = open(SRC, encoding="utf-8").read()
def block_of(text, field):
    for m in re.finditer(BLOCK, text):
        if f"<FIELDNAME>{field}</FIELDNAME>" in m.group(0):
            return m.group(0)
    raise SystemExit(field)
KEY_TPL   = block_of(t0, "WERKS")   # key field block
PLAIN_TPL = block_of(t0, "MAKTX")   # no reference
REF_TPL   = block_of(t0, "NTGEW")   # with REFTABLE / REFFIELD

def blk(name, roll, key=False, ref=None):
    if key:
        b = KEY_TPL.replace("<FIELDNAME>WERKS</FIELDNAME>", f"<FIELDNAME>{name}</FIELDNAME>")
        b = b.replace("<ROLLNAME>WERKS_D</ROLLNAME>", f"<ROLLNAME>{roll}</ROLLNAME>")
    elif ref:
        b = REF_TPL.replace("<FIELDNAME>NTGEW</FIELDNAME>", f"<FIELDNAME>{name}</FIELDNAME>")
        b = b.replace("<ROLLNAME>NTGEW</ROLLNAME>", f"<ROLLNAME>{roll}</ROLLNAME>")
        b = b.replace("<REFFIELD>GEWEI</REFFIELD>", f"<REFFIELD>{ref}</REFFIELD>")
    else:
        b = PLAIN_TPL.replace("<FIELDNAME>MAKTX</FIELDNAME>", f"<FIELDNAME>{name}</FIELDNAME>")
        b = b.replace("<ROLLNAME>MAKTX</ROLLNAME>", f"<ROLLNAME>{roll}</ROLLNAME>")
    return b

Q  = lambda n: (n, "ZDE_FCST_QTY", False, "MEINS")     # quantity, unit MEINS
KL = lambda n: (n, "ZDE_FCST_KL", False, None)
CR = lambda n: (n, "ZDE_FCST_CR", False, None)
TON = Q

# The lead block every Paints list shows, Sheet1 columns A to M, plus the
# unit / currency fields the QUAN and CURR fields need as references.
LEAD = [("FCST_NO", "ZDE_FCST_NO", False, None),
        ("NAME1", "NAME1", False, None), ("BRAND", "ZDE_BRAND", False, None),
        ("MAKTX", "MAKTX", False, None), ("MTS_MTO", "ZDE_MTS_MTO", False, None),
        ("MVGR1_TXT", "BEZEI20", False, None), ("MVGR2_TXT", "BEZEI20", False, None),
        ("MVGR5_TXT", "BEZEI20", False, None), ("MATKL", "MATKL", False, None),
        ("PACK_SIZE", "ZDE_PACK_SIZE", False, None), ("PACK_UNIT", "MEINH", False, None),
        ("WAERS", "WAERS", False, None), ("PRICE", "ZDE_FCST_PRICE", False, "WAERS"),
        ("QTY_CARTON", "ZDE_QTY_CARTON", False, None), ("MEINS", "MEINS", False, None)]
AUDIT = [(f, f, False, None) for f in ("ERNAM", "ERDAT", "AENAM", "AEDAT")]
GROSS = [("GEWEI", "GEWEI", False, None), ("BRGEW", "BRGEW", False, "GEWEI")]
COMP  = [Q("M4_LAST"), Q("M5_LAST"), Q("M6_LAST"), Q("LY_QTR_TOT"),
         Q("M1_CURR"), Q("M2_CURR"), Q("M3_CURR"), Q("L3M_TOT"), Q("MAX_QTY"),
         ("PROD_CAT", "ZDE_PROD_CAT", False, None), ("LOAD_FCT", "ZDE_LOAD_FCT", False, None),
         Q("FCST_QTY"), Q("BUS_FCST"), Q("FINAL_QTY")]

TABLES = {
 "ZPPT_PNT_FCST_YR": ("Paints annual forecast - as the ZFCST_PAINTS annual list",
    [("MANDT", "MANDT", True, None), ("WERKS", "WERKS_D", True, None),
     ("MATNR", "MATNR", True, None), ("FYEAR", "ZDE_FYEAR", True, None)]
    + LEAD
    + [Q(f"M{i:02d}_FCST") for i in range(1, 13)]
    + [KL(f"M{i:02d}_KL") for i in range(1, 13)]
    + [CR(f"M{i:02d}_CR") for i in range(1, 13)]
    + GROSS + [TON(f"M{i:02d}_TON") for i in range(1, 13)]
    + AUDIT),
 "ZPPT_PNT_FCST_QT": ("Paints quarterly forecast - as the ZFCST_PAINTS quarterly list",
    [("MANDT", "MANDT", True, None), ("WERKS", "WERKS_D", True, None),
     ("MATNR", "MATNR", True, None), ("GJAHR", "GJAHR", True, None),
     ("QUARTER", "ZDE_QUARTER", True, None)]
    + LEAD + COMP
    + sum([[Q(f"M{m}_FCST"), Q(f"BUS_FCST_ADD{m-3}"), Q(f"M{m}_FCST_FINAL"),
            KL(f"M{m}_KL"), CR(f"M{m}_CR"), TON(f"M{m}_TON")] for m in (4, 5, 6)], [])
    + GROSS + AUDIT),
 "ZPPT_PNT_FCST_MN": ("Paints monthly forecast - as the ZFCST_PAINTS monthly list",
    [("MANDT", "MANDT", True, None), ("WERKS", "WERKS_D", True, None),
     ("MATNR", "MATNR", True, None), ("GJAHR", "GJAHR", True, None),
     ("PERIOD", "POPER", True, None)]
    + LEAD + COMP
    + [Q("BUS_FCST_ADD"), Q("TOTAL_QTY"), KL("M4_KL"), CR("M4_CR"), TON("M4_TON")]
    + GROSS + AUDIT),
}

head = t0[:t0.index("   <DD03P_TABLE>")]
tail = t0[t0.index("   </DD03P_TABLE>"):]
for name, (text, fields) in TABLES.items():
    body = "".join(blk(n, r, k, ref) for n, r, k, ref in fields)
    out = head + "   <DD03P_TABLE>\n" + body + tail
    out = out.replace("ZPPT_FCST_YR", name)
    out = re.sub(r"<DDTEXT>[^<]*</DDTEXT>", f"<DDTEXT>{text}</DDTEXT>", out, count=1)
    assert out.count(f"<TABNAME>{name}</TABNAME>") == 2
    path = f"{DST}/{name.lower()}.tabl.xml"
    open(path, "w", encoding="utf-8", newline="\n").write(out)
    names = [n for n, _, _, _ in fields]
    assert len(names) == len(set(names)), "duplicate field"
    print(path, len(fields), "fields")
