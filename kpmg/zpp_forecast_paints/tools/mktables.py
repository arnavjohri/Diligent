"""Generate the three Paints forecast tables from the Adhesive ones.
Same shape, same element order (which abapGit needs), plus the Paints fields.
Run from kpmg/zpp_forecast_paints:  python3 -I tools/mktables.py
"""
import re, os
SRC = "../zpp_forecast_v2/src"
DST = "src"
BLOCK = r"    <DD03P>\n(?:     <[^\n]*\n)*?    </DD03P>\n"

def block_of(text, field):
    for m in re.finditer(BLOCK, text):
        if f"<FIELDNAME>{field}</FIELDNAME>" in m.group(0):
            return m.group(0)
    raise SystemExit(f"no block for {field}")

def mk(tpl, name, roll, reffield=None, ref_tpl_field="NTGEW"):
    b = tpl.replace(f"<FIELDNAME>{ref_tpl_field}</FIELDNAME>", f"<FIELDNAME>{name}</FIELDNAME>")
    b = b.replace(f"<ROLLNAME>{ref_tpl_field}</ROLLNAME>", f"<ROLLNAME>{roll}</ROLLNAME>")
    if reffield:
        b = b.replace("<REFFIELD>GEWEI</REFFIELD>", f"<REFFIELD>{reffield}</REFFIELD>")
    return b

COMMON = [("NAME1", "NAME1", None), ("BRAND", "ZDE_BRAND", None),
          ("PACK_SIZE", "ZDE_PACK_SIZE", None), ("PACK_UNIT", "MEINH", None),
          ("QTY_CARTON", "ZDE_QTY_CARTON", None), ("BRGEW", "BRGEW", "GEWEI")]

SPEC = {
  "zppt_fcst_yr": ("ZPPT_PNT_FCST_YR", "Paints annual forecast",
      COMMON + [("WAERS", "WAERS", None), ("PRICE", "ZDE_FCST_PRICE", "WAERS")]
      + [(f"M{i:02d}_KL", "ZDE_FCST_KL", None) for i in range(1, 13)]
      + [(f"M{i:02d}_CR", "ZDE_FCST_CR", None) for i in range(1, 13)]),
  "zppt_fcst_qt": ("ZPPT_PNT_FCST_QT", "Paints quarterly forecast",
      COMMON + [(f"M{i}_KL", "ZDE_FCST_KL", None) for i in (4, 5, 6)]
      + [(f"M{i}_CR", "ZDE_FCST_CR", None) for i in (4, 5, 6)]),
  "zppt_fcst_mn": ("ZPPT_PNT_FCST_MN", "Paints monthly forecast",
      COMMON + [("WAERS", "WAERS", None), ("PRICE", "ZDE_FCST_PRICE", "WAERS"),
                ("M4_KL", "ZDE_FCST_KL", None), ("M4_CR", "ZDE_FCST_CR", None)]),
}

for src, (newname, text, extra) in SPEC.items():
    t = open(f"{SRC}/{src}.tabl.xml", encoding="utf-8").read()
    ref_tpl = block_of(t, "NTGEW")                       # with REFTABLE/REFFIELD
    plain_tpl = block_of(t, "MAKTX")                     # without
    oldname = newname.replace("_PNT", "")
    assert t.count(f"<TABNAME>{oldname}</TABNAME>") == 2
    # MSL sits after AEDAT on the Adhesive monthly table (appended 23/09); a new table orders it before the audit fields
    if src == "zppt_fcst_mn":
        msl = block_of(t, "MSL")
        t = t.replace(msl, "")
        ernam = block_of(t, "ERNAM")
        assert t.count(ernam) == 1
        t = t.replace(ernam, msl + ernam)
    new_blocks = ""
    for name, roll, reffield in extra:
        if reffield:
            new_blocks += mk(ref_tpl, name, roll, reffield)
        else:
            new_blocks += mk(plain_tpl, name, roll, None, "MAKTX")
    ernam = block_of(t, "ERNAM")
    assert t.count(ernam) == 1
    t = t.replace(ernam, new_blocks + ernam)
    t = t.replace(oldname, newname)
    t = re.sub(r"<DDTEXT>[^<]*</DDTEXT>", f"<DDTEXT>{text}</DDTEXT>", t, count=1)
    out = f"{DST}/{newname.lower()}.tabl.xml"
    open(out, "w", encoding="utf-8", newline="\n").write(t)
    print("wrote", out, t.count("<DD03P>"), "fields")
