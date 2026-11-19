"""Post-process the rendered report: unique bookmark ids, no directory entries in the package."""
import os
import re
import sys
import zipfile

src = sys.argv[1]
tmp = src + ".tmp"
n = [0]


def renumber(xml):
    def sub(m):
        if m.group(1) == "Start":
            n[0] += 1
        return re.sub(r'w:id="\d+"', f'w:id="{n[0]}"', m.group(0))
    return re.sub(r"<w:bookmark(Start|End)\b[^>]*>", sub, xml)


with zipfile.ZipFile(src) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
    for it in zin.infolist():
        if it.filename.endswith("/"):
            continue
        data = zin.read(it.filename)
        if it.filename == "word/document.xml":
            data = renumber(data.decode("utf-8")).encode("utf-8")
        zout.writestr(it, data)
os.replace(tmp, src)
print(f"fixed {src}: {n[0]} bookmarks renumbered")
