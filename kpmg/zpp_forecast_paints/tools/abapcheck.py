import sys, re
for path in sys.argv[1:]:
    src = open(path, encoding="utf-8").read().split("\n")
    print("=====", path, len(src), "lines")
    long_ = [(i+1, len(l)) for i, l in enumerate(src) if len(l) > 120]
    print("lines >120:", long_[:10])
    # strip comments
    code = []
    for l in src:
        if l.startswith("*"): code.append(""); continue
        # drop trailing " comments (naive: first " not inside quotes)
        out, inq = "", False
        for ch in l:
            if ch == "'": inq = not inq
            if ch == '"' and not inq: break
            out += ch
        code.append(out)
    text = "\n".join(code)
    stmts = [s.strip() for s in re.split(r"\.\s*\n|\.\s*$", text) if s.strip()]
    pairs = [("IF","ENDIF"),("LOOP","ENDLOOP"),("DO","ENDDO"),("WHILE","ENDWHILE"),("CASE","ENDCASE"),
             ("TRY","ENDTRY"),("FORM","ENDFORM"),("METHOD","ENDMETHOD"),("CLASS","ENDCLASS")]
    for a,b in pairs:
        na = sum(1 for s in stmts if re.match(rf"^{a}\b", s, re.I) and not re.match(rf"^{a}\s+\w+\s+DEFINITION\s+(DEFERRED|LOAD)", s, re.I))
        nb = sum(1 for s in stmts if re.match(rf"^{b}\b", s, re.I))
        if a == "CLASS":
            na = sum(1 for s in stmts if re.match(r"^CLASS\s+\w+\s+(DEFINITION|IMPLEMENTATION)\b", s, re.I) and "DEFERRED" not in s.upper())
        if a == "METHOD":
            na = sum(1 for s in stmts if re.match(r"^METHOD\s", s, re.I))
        flag = "" if na == nb else "   <<< MISMATCH"
        print(f"  {a}/{b}: {na}/{nb}{flag}")
    # FORM signatures vs PERFORM
    forms = {}
    for s in stmts:
        m = re.match(r"^FORM\s+(\w+)(.*)$", s, re.I|re.S)
        if m:
            name, rest = m.group(1).lower(), m.group(2)
            toks = [t for t in re.split(r"\s+", rest.strip()) if t]
            n = 0; skip = False
            for t in toks:
                tu = t.upper()
                if tu in ("USING","CHANGING","TABLES"): continue
                if tu in ("TYPE","LIKE","REF","TO","STRUCTURE","DEFAULT","VALUE","OPTIONAL"): skip = True; continue
                if skip: skip = False; continue
                if tu == "ANY": continue
                n += 1
            forms[name] = n
    perf_bad = []
    for s in stmts:
        m = re.match(r"^PERFORM\s+(\w+)(.*)$", s, re.I|re.S)
        if m:
            name, rest = m.group(1).lower(), m.group(2)
            # count args: split on whitespace, drop USING/CHANGING; string literals with spaces are single tokens
            toks = re.findall(r"'[^']*'|\|[^|]*\||\S+", rest)
            n = sum(1 for t in toks if t.upper() not in ("USING","CHANGING","TABLES"))
            if name not in forms: perf_bad.append((name, "NO FORM"))
            elif forms[name] != n: perf_bad.append((name, f"form {forms[name]} vs perform {n}: {s[:80]}"))
    print("  PERFORM/FORM mismatches:", perf_bad if perf_bad else "none")
    # methods declared vs implemented (classes only)
    decl = set(re.findall(r"^\s*(?:CLASS-)?METHODS\s+(\w+)", text, re.I|re.M))
    impl = set(re.findall(r"^\s*METHOD\s+(\w+)", text, re.I|re.M))
    if decl or impl:
        print("  methods declared not implemented:", sorted(d.lower() for d in decl if d.lower() not in {i.lower() for i in impl}))
        print("  methods implemented not declared:", sorted(i.lower() for i in impl if i.lower() not in {d.lower() for d in decl}))
