import re, sys, shutil

KNOWN = {'\u00f0\u0178\u00b8': '\U0001F378'}
RUN = re.compile('[\u00c2-\u00f4][\u0080-\u00bf\u0152\u0153\u0160\u0161\u0178\u017d\u017e\u0192\u02c6\u02dc'
                 '\u2013\u2014\u2018-\u201e\u2020-\u2022\u2026\u2030\u2039\u203a\u20ac\u2122]{1,3}')

def to_bytes(s):
    out = bytearray()
    for ch in s:
        try:
            out += ch.encode('cp1252')
        except UnicodeEncodeError:
            if ord(ch) < 256:
                out.append(ord(ch))
            else:
                return None
    return bytes(out)

def fix_run(m):
    s = m.group(0)
    if s in KNOWN:
        return KNOWN[s]
    b = to_bytes(s)
    if b is None:
        return s
    for n in range(len(b), 1, -1):
        try:
            return b[:n].decode('utf-8') + s[n:]
        except UnicodeDecodeError:
            continue
    return s

files = [a for a in sys.argv[1:] if not a.startswith('--')] or ['blog.html']
apply = '--apply' in sys.argv
for f in files:
    old = open(f, 'r', encoding='utf-8', newline='').read()
    new = RUN.sub(fix_run, old)
    n = sum(1 for a, b in zip(old.split('\n'), new.split('\n')) if a != b)
    print('%s: %d line(s) %s' % (f, n, 'fixed' if apply else 'would change'))
    if apply and n:
        shutil.copyfile(f, f + '.bak-emoji')
        open(f, 'w', encoding='utf-8', newline='').write(new)
if not apply:
    print('Dry run. Add --apply to write.')