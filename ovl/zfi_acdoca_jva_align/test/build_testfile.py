"""Build the ZFI_ACDOCA_JVA_ALIGN test workbook from recon rows (Diff = X) and check net-zero per account.
Usage: python3 build_testfile.py <recon_rows.txt> <out.xlsx>
Rows are whitespace-separated; key tokens are classified by shape (venture AA9999, equity group 3 chars,
recovery indicator 2 letters, account digits). Amounts use SAP format: thousands commas, trailing minus."""
import re, sys
from decimal import Decimal
from collections import defaultdict

src, out = sys.argv[1], sys.argv[2]
def amt(s):
    neg = s.endswith('-'); s = s.rstrip('-').replace(',', '')
    d = Decimal(s); return -d if neg else d

rows = []
for line in open(src, encoding='utf-8'):
    line = line.strip()
    if not line or line.startswith('#'): continue
    t = line.split()
    diff = t[-1] == 'X'
    amts = t[-13:-1] if diff else t[-12:]
    keys = t[3:-13] if diff else t[3:-12]
    vname = egrup = recid = racct = ''
    for k in keys:
        if re.fullmatch(r'\d+', k): racct = k
        elif re.fullmatch(r'[A-Z]{2}\d{4}', k): vname = k
        elif re.fullmatch(r'[A-Z]{2}\d|[A-Z]{3}', k): egrup = k
        elif re.fullmatch(r'[A-Z]{2}', k): recid = k
        else: raise SystemExit(f'unclassified key token {k!r} in: {line}')
    assert racct, line
    a = [amt(x) for x in amts]
    hsl_acd, hsl_jv, hsl_diff, ksl_acd, ksl_jv, ksl_diff, osl_acd, osl_jv, osl_diff, hsl_post, ksl_post, osl_post = a[:12]
    # sanity: post = jv - acd = -diff
    assert hsl_post == hsl_jv - hsl_acd == -hsl_diff, line
    assert ksl_post == ksl_jv - ksl_acd == -ksl_diff, line
    rows.append(dict(bukrs=t[0], gjahr=t[1], poper=t[2], vname=vname, egrup=egrup, racct=racct, recid=recid,
                     hsl=hsl_post, ksl=ksl_post, osl=osl_post, diff=diff))

print(f'rows read: {len(rows)}')
post = [r for r in rows if r['hsl'] or r['ksl'] or r['osl']]
print(f'rows with an amount to post: {len(post)}')

# net-zero per company code / year / period / account
tot = defaultdict(lambda: [Decimal(0)]*3)
for r in post:
    k = (r['bukrs'], r['gjahr'], r['poper'], r['racct'])
    tot[k][0] += r['hsl']; tot[k][1] += r['ksl']; tot[k][2] += r['osl']
bad = {k: v for k, v in tot.items() if any(v)}
print(f'accounts touched: {len(tot)}; accounts NOT netting to zero: {len(bad)}')
for k, v in sorted(bad.items()):
    print('  ', k, 'LC', v[0], 'GC', v[1], '3C', v[2])
print('grand totals LC/GC/3C:', sum(r["hsl"] for r in post), sum(r["ksl"] for r in post), sum(r["osl"] for r in post))
docs = sorted({(r['bukrs'], r['gjahr'], r['poper']) for r in post})
print('documents:', docs)
print('rows with venture blank but recovery indicator filled:', sum(1 for r in post if not r['vname'] and r['recid']))
print('rows with venture filled but recovery indicator blank:', sum(1 for r in post if r['vname'] and not r['recid']))
print('distinct ventures:', sorted({r['vname'] for r in post if r['vname']}))
print('distinct recovery indicators:', sorted({r['recid'] for r in post if r['recid']}))

# workbook: 15 columns, key order = recon export order.
# Written by hand (zipfile + XML) in the shape Excel itself writes - relative relationship targets,
# shared strings, built-in number format 4 - because SAP's CL_FDT_XL_SPREADSHEET rejects the openpyxl
# package ("Unable to load worksheet", OCD 03/11/26: absolute worksheet target, inline strings).
import zipfile
from xml.sax.saxutils import escape

hdr = ['Company Code', 'Fiscal Year', 'Posting Period', 'Joint Venture', 'Equity Group', 'G/L Account',
       'Recovery Indicator', 'Amount Local Currency', 'Amount Group Currency', 'Amount 3rd Currency',
       'Cost Center', 'Order', 'WBS Element', 'Profit Center', 'Line Text']
post.sort(key=lambda r: (r['racct'], r['vname'], r['egrup'], r['recid']))

def col(i):
    s = ''
    while i:
        i, rem = divmod(i - 1, 26)
        s = chr(65 + rem) + s
    return s

shared, sidx = [], {}
def sref(text):
    if text not in sidx:
        sidx[text] = len(shared); shared.append(text)
    return sidx[text]

def cell(r, c, value, style=0):
    ref = f'{col(c)}{r}'
    if value is None or value == '':
        return ''
    if isinstance(value, Decimal):
        if value == 0:
            return ''
        return f'<c r="{ref}" s="{style}"><v>{value}</v></c>'
    return f'<c r="{ref}" s="{style}" t="s"><v>{sref(str(value))}</v></c>'

xrows = ['<row r="1">' + ''.join(cell(1, i, h, 1) for i, h in enumerate(hdr, 1)) + '</row>']
for n, r in enumerate(post, start=2):
    vals = [r['bukrs'], r['gjahr'], r['poper'], r['vname'], r['egrup'], r['racct'], r['recid'],
            r['hsl'], r['ksl'], r['osl'], '', '', '', '', '']
    cells = ''.join(cell(n, i, v, 2 if isinstance(v, Decimal) else 0) for i, v in enumerate(vals, 1))
    xrows.append(f'<row r="{n}">{cells}</row>')

widths = [13, 11, 14, 13, 12, 12, 18, 22, 22, 20, 12, 12, 14, 13, 30]
cols = ''.join(f'<col min="{i}" max="{i}" width="{w}" customWidth="1"/>' for i, w in enumerate(widths, 1))
NS = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
RNS = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
PNS = 'http://schemas.openxmlformats.org/package/2006/relationships'
X = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
sheet = (X + f'<worksheet xmlns="{NS}" xmlns:r="{RNS}"><dimension ref="A1:O{len(post) + 1}"/>'
         '<sheetViews><sheetView workbookViewId="0"/></sheetViews><sheetFormatPr defaultRowHeight="15"/>'
         f'<cols>{cols}</cols><sheetData>' + ''.join(xrows) + '</sheetData></worksheet>')
sst = (X + f'<sst xmlns="{NS}" count="{len(shared)}" uniqueCount="{len(shared)}">'
       + ''.join(f'<si><t>{escape(t)}</t></si>' for t in shared) + '</sst>')
styles = (X + f'<styleSheet xmlns="{NS}">'
          '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
          '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
          '<fills count="2"><fill><patternFill patternType="none"/></fill>'
          '<fill><patternFill patternType="gray125"/></fill></fills>'
          '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
          '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
          '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
          '<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>'
          '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>')
workbook = (X + f'<workbook xmlns="{NS}" xmlns:r="{RNS}"><sheets>'
            '<sheet name="Upload" sheetId="1" r:id="rId1"/></sheets></workbook>')
wb_rels = (X + f'<Relationships xmlns="{PNS}">'
           f'<Relationship Id="rId1" Type="{RNS}/worksheet" Target="worksheets/sheet1.xml"/>'
           f'<Relationship Id="rId2" Type="{RNS}/styles" Target="styles.xml"/>'
           f'<Relationship Id="rId3" Type="{RNS}/sharedStrings" Target="sharedStrings.xml"/></Relationships>')
root_rels = (X + f'<Relationships xmlns="{PNS}">'
             f'<Relationship Id="rId1" Type="{RNS}/officeDocument" Target="xl/workbook.xml"/></Relationships>')
CT = 'http://schemas.openxmlformats.org/package/2006/content-types'
content_types = (X + f'<Types xmlns="{CT}">'
                 '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                 '<Default Extension="xml" ContentType="application/xml"/>'
                 '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                 '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                 '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
                 '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
                 '</Types>')
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', root_rels)
    z.writestr('xl/workbook.xml', workbook)
    z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
    z.writestr('xl/styles.xml', styles)
    z.writestr('xl/sharedStrings.xml', sst)
    z.writestr('xl/worksheets/sheet1.xml', sheet)
print('written', out, 'data rows', len(post), 'shared strings', len(shared))
