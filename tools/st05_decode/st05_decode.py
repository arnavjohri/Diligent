#!/usr/bin/env python3
"""Decode an ST05 binary export (.trc) without an SAP system.

An ST05 "export" is an ABAP data cluster (UTF-16 payload, codepage 4103) whose body is
compressed with SAP's LZH, which is a DEFLATE stream behind an 8-byte header
(4-byte length, 0x12?, 1F 9D, algorithm 02) plus a 2-bit noise count and that many
noise bits. The outer cluster holds the filter XML and a second, nested cluster with the
DETAILED_RECORD_TABLE, compressed the same way.

    python3 -I st05_decode.py Trace.trc out_dir

Writes out_dir/records.tsv (time, object, operation, tcode, program, rc, short statement),
out_dir/strings_u16.txt (every UTF-16 string, full SQL statements included) and the raw
decompressed cluster out_dir/nested.bin. Written 06/11/26 for ovl/zgr_ct_tasklog.
"""
import os, re, struct, sys, zlib


def inflate_from(data, pos):
    """Inflate the SAP LZH stream whose CS header starts at the first 1F 9D at or after pos."""
    m = data.find(b'\x1f\x9d', pos)
    if m < 0:
        raise SystemExit('no CS header found')
    origlen = struct.unpack('<I', data[m - 5:m - 1])[0]
    start = m + 3
    noise = data[start] & 3
    shifted = int.from_bytes(data[start:], 'little') >> (2 + noise)
    stream = shifted.to_bytes(len(data) - start, 'little')
    out = zlib.decompressobj(-15).decompress(stream)
    if len(out) != origlen:
        print(f'warning: expected {origlen} bytes, got {len(out)}', file=sys.stderr)
    return out


def u16(b):
    return b.decode('utf-16-le', errors='replace')


def read_str(buf, pos, marker):
    m = buf.find(marker, pos)
    if m < 0:
        return '', pos
    ln = struct.unpack('>I', buf[m + 2:m + 6])[0]
    return u16(buf[m + 6:m + 6 + ln]), m + 6 + ln


def main(src, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    raw = open(src, 'rb').read()
    if not raw.startswith(b'___ST05___BINARY_EXPORT___'):
        raise SystemExit('not an ST05 binary export')
    outer = inflate_from(raw, 0)
    nested = inflate_from(outer, 0)
    open(os.path.join(out_dir, 'nested.bin'), 'wb').write(nested)

    # UTF-16 strings, 3+ printable characters
    with open(os.path.join(out_dir, 'strings_u16.txt'), 'w', encoding='utf-8') as fh:
        for m in re.finditer(rb'(?:[\x20-\x7e]\x00){3,}', nested):
            fh.write(u16(m.group(0)) + '\n')

    # one record per timestamp "YYYYMMDDhh:mm:ss.mmm"
    ts = re.compile(rb'(?:[0-9]\x00){10}:\x00(?:[0-9]\x00){2}:\x00(?:[0-9]\x00){2}\.\x00(?:[0-9]\x00){3}')
    offs = [m.start() for m in ts.finditer(nested)] + [len(nested)]
    n = 0
    with open(os.path.join(out_dir, 'records.tsv'), 'w', encoding='utf-8') as fh:
        fh.write('time\tobject\toperation\ttcode\tprogram\trc\tstatement\n')
        for i in range(len(offs) - 1):
            row = nested[offs[i]:offs[i + 1]]
            time = u16(row[0:40])
            obj, p = read_str(row, 120, b'\xbd\xca')
            stmt, p = read_str(row, p, b'\xcb\xca')
            fx = row.find(b'\xcb\xbc\x00\x00\x02\x28', p)
            tcode = prog = op = rc = ''
            if fx >= 0:
                t = u16(row[fx + 6:fx + 6 + 552])
                rc, tcode, prog, op = t[0:42].strip(), t[44:64].strip(), t[64:104].strip(), t[143:151].strip()
            cells = [time, obj, op, tcode, prog, rc, stmt]
            fh.write('\t'.join(c.replace('\t', ' ').replace('\n', ' ') for c in cells) + '\n')
            n += 1
    print(f'{n} records -> {out_dir}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2])
