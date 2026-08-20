"""
fix-blog-emojis-v2.py
Precisely repairs the 5 known mojibake emoji sequences in blog.html.

Instead of trying to detect mojibake with a regex (fragile - breaks on
invisible variation-selector control characters), this script computes
the EXACT broken byte sequence for each known-correct emoji by doing
the same utf-8 -> cp1252 misread that corrupted the file in the first
place -- including dropping the handful of undefined cp1252 byte
positions, which is what your corruption actually did -- then does a
plain, literal string replacement. No guessing, no regex.

Tested against a reconstruction of the exact corrupted lines reported
from blog.html: all 5 category headers repaired correctly.

Run:  python fix-blog-emojis-v2.py "C:\\path\\to\\blog.html"
"""
import sys

# The correct emoji that SHOULD appear, taken from your site's category headers.
CORRECT_EMOJIS = [
    "\U0001F4DA",              # 📚 books
    "\U0001F6E1\uFE0F",        # 🛡️ shield (with variation selector)
    "\U0001F3E8",              # 🏨 hotel
    "\U0001F377",              # 🍷 wine glass
    "\U0001F4BC",              # 💼 briefcase
]

def to_mojibake(correct: str) -> str:
    """Recreate exactly how `correct` got mangled: encode as utf-8, then
    decode those raw bytes as cp1252 -- dropping the handful of cp1252
    code points that are undefined, since that's how the real corruption
    behaved (verified against your actual reported broken text)."""
    raw = correct.encode("utf-8")
    chars = []
    for b in raw:
        try:
            chars.append(bytes([b]).decode("cp1252"))
        except UnicodeDecodeError:
            pass  # undefined cp1252 byte positions were dropped, not passed through
    return "".join(chars)

def main():
    if len(sys.argv) != 2:
        print("Usage: python fix-blog-emojis-v2.py <path-to-file>")
        sys.exit(1)

    path = sys.argv[1]

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    original = content
    total_replacements = 0

    for correct in CORRECT_EMOJIS:
        broken = to_mojibake(correct)
        count = content.count(broken)
        if count > 0:
            content = content.replace(broken, correct)
            print(f"Fixed {count} occurrence(s): {broken!r} -> {correct!r}")
            total_replacements += count
        else:
            print(f"No occurrences found for: {broken!r} (expected {correct!r})")

    if total_replacements == 0:
        print("\nNo changes made. Paste a hex dump of one broken line so we can "
              "see the exact bytes rather than guessing further.")
        return

    backup_path = path + ".bak2"
    with open(backup_path, "w", encoding="utf-8") as f:
        f.write(original)
    print(f"\nBackup written to {backup_path}")

    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(content)
    print(f"{path} updated. Total replacements: {total_replacements}")

if __name__ == "__main__":
    main()
