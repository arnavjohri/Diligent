#!/usr/bin/env python3
"""Rebuild clean ABAP sources from an SE80 print listing (one file per Program/Include)."""
import re, sys, os

src, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
hdr_title = re.compile(r'^\d\d\.\d\d\.\d\d \w+ +(Program|Include|Internal Program|Message Class) (\S+)(?: attrib)?(?: +Page +\d+)?')
numbered = re.compile(r'^( {0,4}\d{1,5})(?:  (.*))?$')

units = {}      # name -> list of [lineno, text]
order = []
cur = None
state = 0       # header state machine: 0 none, 1 saw dashes, 2 saw title, 3 saw closing dashes (next blank is noise)
last = None     # last numbered record (for continuations)
WRAP = 72
anom = []

with open(src, encoding='latin-1') as f:
    lines = [l.rstrip('\r\n') for l in f]

i = 0
skip_blank = False
while i < len(lines):
    l = lines[i]
    if l.startswith('-' * 80):
        i += 1; continue
    m = hdr_title.match(l)
    if m:
        name = m.group(2)
        if 'attrib' in l:
            cur = None; last = None  # attribute page, no source
        else:
            if name != cur:
                last = None     # new unit: a wrapped line never spans two units
            cur = name
            if name not in units:
                units[name] = []; order.append(name)
        skip_blank = True
        i += 1; continue
    if skip_blank and l.strip() == '':
        skip_blank = False
        i += 1; continue
    skip_blank = False
    m = numbered.match(l)
    if cur is None:
        i += 1; continue
    if m:
        no, text = int(m.group(1)), (m.group(2) or '')
        u = units[cur]
        if u and no < u[-1][0]:
            cur = None; last = None      # numbering restarted: text-element pages etc. follow
            i += 1; continue
        if u and no != u[-1][0] + 1:
            anom.append(f'{cur}: jump {u[-1][0]} -> {no} at file line {i+1}')
        u.append([no, text, 1])
        last = u[-1]
    elif l.strip() == '' :
        # unnumbered blank outside a header: treat as noise but record
        anom.append(f'{cur}: unnumbered blank at file line {i+1}')
    else:
        # continuation of a wrapped line: listing indents it by 7 spaces
        if not l.startswith('       '):
            anom.append(f'{cur}: odd continuation at file line {i+1}: {l[:40]!r}')
        tail = l[7:] if l.startswith('       ') else l.lstrip()
        if last is None:
            anom.append(f'{cur}: continuation with no owner at file line {i+1}')
        else:
            if len(last[1]) > WRAP * last[2]:
                anom.append(f'{cur}: owner len {len(last[1])} > {WRAP*last[2]} before file line {i+1}')
            last[1] = last[1].ljust(WRAP * last[2]) + tail
            last[2] += 1
    i += 1

for name in order:
    u = units[name]
    path = os.path.join(outdir, name + '.abap')
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        for _, t, _k in u:
            f.write(t.rstrip() + '\n')
    print(f'{name}: {len(u)} lines (first {u[0][0] if u else 0}, last {u[-1][0] if u else 0}) -> {path}')
print('anomalies:', len(anom))
for a in anom[:40]:
    print('  ', a)
