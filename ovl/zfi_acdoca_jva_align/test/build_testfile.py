"""Build the ZFI_ACDOCA_JVA_ALIGN test workbook from recon rows (Diff = X) and check net-zero per account.
Usage: python3 build_testfile.py <recon_rows.txt> <out.xlsx>
Rows are whitespace-separated; key tokens are classified by shape (venture AA9999, equity group 3 chars,
recovery indicator 2 letters, account digits). Amounts use SAP format: thousands commas, trailing minus."""
import re, sys
from decimal import Decimal
from collections import defaultdict
import openpyxl
from openpyxl.styles import Font

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

# workbook: 15 columns, key order = recon export order
wb = openpyxl.Workbook(); ws = wb.active; ws.title = 'Upload'
hdr = ['Company Code', 'Fiscal Year', 'Posting Period', 'Joint Venture', 'Equity Group', 'G/L Account',
       'Recovery Indicator', 'Amount Local Currency', 'Amount Group Currency', 'Amount 3rd Currency',
       'Cost Center', 'Order', 'WBS Element', 'Profit Center', 'Line Text']
ws.append(hdr)
for c in ws[1]: c.font = Font(bold=True)
post.sort(key=lambda r: (r['racct'], r['vname'], r['egrup'], r['recid']))
for r in post:
    ws.append([r['bukrs'], int(r['gjahr']), int(r['poper']), r['vname'], r['egrup'], int(r['racct']), r['recid'],
               float(r['hsl']), float(r['ksl']), float(r['osl']) if r['osl'] else None, None, None, None, None, None])
for col in 'HIJ':
    for cell in ws[col][1:]: cell.number_format = '#,##0.00'
for i, w in enumerate([13, 11, 14, 13, 12, 12, 18, 22, 22, 20, 12, 12, 14, 13, 30], start=1):
    ws.column_dimensions[openpyxl.utils.get_column_letter(i)].width = w
wb.save(out)
print('written', out, 'data rows', len(post))
