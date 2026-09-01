"""
fix-blog-emojis.py
Repairs UTF-8-saved-as-Windows-1252 mojibake in blog.html (or any file passed as arg).
Run from the repo root: python fix-blog-emojis.py blog.html

Safe pattern:
  1. Reads the file as UTF-8 (how it's currently stored/misread).
  2. Re-encodes each mis-decoded string back to raw bytes using cp1252.
  3. Decodes those raw bytes as UTF-8 (the correct original encoding).
  4. Writes back as UTF-8, no BOM.

Only touches sequences that actually round-trip cleanly — if a chunk of text
isn't valid mojibake, it's left untouched rather than guessed at.
"""
import sys
import re

def fix_mojibake(text: str) -> str:
    # Candidate mojibake runs: sequences of characters typical of
    # cp1252-misdecoded UTF-8 (e.g. ð, Ÿ, ð�, ¢, ™, etc. followed by
    # more high-byte chars). We attempt the round-trip on the whole
    # file; if a given line has no such characters, it's unaffected.
    def try_fix(match: re.Match) -> str:
        chunk = match.group(0)
        try:
            fixed = chunk.encode('cp1252').decode('utf-8')
            return fixed
        except (UnicodeDecodeError, UnicodeEncodeError):
            return chunk  # leave untouched if it doesn't round-trip cleanly

    # Match runs of 2+ characters in the Latin-1 supplement / cp1252 range,
    # which is where mojibake byte sequences land.
    pattern = re.compile(r'[\u00c0-\u00ff\u2018-\u201f\u2013\u2014\u2122]{2,}')
    return pattern.sub(try_fix, text)

def main():
    if len(sys.argv) != 2:
        print("Usage: python fix-blog-emojis.py <path-to-file>")
        sys.exit(1)

    path = sys.argv[1]

    with open(path, 'r', encoding='utf-8') as f:
        original = f.read()

    fixed = fix_mojibake(original)

    if fixed == original:
        print("No changes made — no mojibake patterns matched.")
        return

    # Show a short diff summary before writing
    changed_lines = sum(
        1 for a, b in zip(original.splitlines(), fixed.splitlines()) if a != b
    )
    print(f"{changed_lines} line(s) will be changed.")

    backup_path = path + ".bak"
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(original)
    print(f"Backup written to {backup_path}")

    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(fixed)
    print(f"{path} updated.")

if __name__ == "__main__":
    main()
