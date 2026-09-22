"""
fix_mojibake.py
Scans all .html files in the repo for mojibake (UTF-8 emoji/punctuation
that got saved or read as Windows-1252) and fixes them.

Strategy:
  1. Peel utf8->latin1 repeatedly until no mojibake signature remains
  2. Run ftfy.fix_text as a final normalization pass
  3. Verify the result is clean; if not, skip and report

Usage:
  python fix_mojibake.py --dry-run
  python fix_mojibake.py --apply
  python fix_mojibake.py --dry-run --only partners.html
  python fix_mojibake.py --apply --only partners.html

Requires: pip install ftfy
"""

import argparse
import os
import shutil
import sys

try:
    import ftfy
except ImportError:
    print("Missing dependency. Run: pip install ftfy")
    sys.exit(1)

REPO_ROOT = os.getcwd()
BACKUP_DIR = os.path.join(REPO_ROOT, "_mojibake_backups")

# Backups, archives, and backups-of-backups must not be touched.
SKIP_DIRS = {
    ".git",
    "node_modules",
    "_mojibake_backups",
    "_metadata_backups",
    "encoding_backup",
    "encoding_fix2_backup",
}
SKIP_DIR_PREFIXES = ("backup-html", "backup")

# Any of these remaining in the text = still mojibake.
#
# Every signature is written as raw UTF-8 bytes (\xNN escapes) rather
# than literal characters.  This is deliberate: if this source file is
# ever saved or copied through a tool that mangles non-ASCII text, the
# signatures would silently stop matching.  Byte escapes cannot be
# mangled.
#
# Each entry is the UTF-8 encoding of what a Windows-1252 mis-decode
# of a real UTF-8 sequence looks like.  For example, an em dash U+2014
# (UTF-8 bytes E2 80 94) decoded as CP1252 becomes "â€”", which in
# UTF-8 is the bytes C3 A2 E2 82 AC E2 80 9D.
MOJIBAKE_SIGS = [
    # -- multi-layer (double/triple-encoded) ---------------------------
    "\xc3\x83",                          # Ãƒ
    "\xc3\x82",                          # Ã‚
    "\xc3\xa2\xe2\x82\xac",              # Ã¢â‚¬

    # -- single-layer, common -----------------------------------------
    "\xc3\xb0\xc5\xb8",                  # ðŸ   (emoji prefix)
    "\xe2\x80\x93",                      # â€“  (en dash)
    "\xe2\x80\x94",                      # â€”  (em dash)
    "\xe2\x80\x9c",                      # â€œ  (left double quote)
    "\xe2\x80\x9d",                      # â€   (right double quote)
    "\xe2\x80\x99",                      # â€™  (right single quote)
    "\xe2\x80\x98",                      # â€˜  (left single quote)
    "\xe2\x80\xa6",                      # â€¦  (ellipsis)
    "\xe2\x80\xa2",                      # â€¢  (bullet)
    "\xe2\x84\xa2",                      # â„¢  (trademark)

    # -- accented latin ----------------------------------------------
    "\xc3\xa9", "\xc3\xa8", "\xc3\xa0",  # é è à
    "\xc3\xaa", "\xc3\xab", "\xc3\xa7",  # ê ë ç
    "\xc3\xae", "\xc3\xaf", "\xc3\xb4",  # î ï ô
    "\xc3\xb9", "\xc3\xbb", "\xc3\xb1",  # ù û ñ
    "\xc3\xbc", "\xc3\xb6", "\xc3\xa4",  # ü ö ä

    # -- misc single-layer symbols -----------------------------------
    "\xc2\xb0", "\xc2\xa3", "\xc2\xa9",  # ° £ ©
    "\xc2\xae", "\xc2\xa0",              # ® nbsp
]


def has_mojibake(text):
    return any(sig in text for sig in MOJIBAKE_SIGS)


def peel(text):
    """Peel utf8->latin1 one layer. Returns new text."""
    return text.encode("latin-1", errors="strict").decode("utf-8", errors="strict")


def fix_text_multi(text):
    """Peel until no mojibake signature, then ftfy. Returns (fixed, depth, ok)."""
    depth = 0
    # Up to 6 peels -- the worst we've seen is 5
    while has_mojibake(text) and depth < 6:
        try:
            text = peel(text)
        except (UnicodeDecodeError, UnicodeEncodeError):
            # Can't peel this file cleanly -- bail and let caller decide
            return text, depth, False
        depth += 1

    # Final pass: let ftfy handle anything unusual the loop couldn't
    text = ftfy.fix_text(text, uncurl_quotes=False)
    return text, depth, not has_mojibake(text)


def find_html_files(root, only=None):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [
            d for d in dirnames
            if d not in SKIP_DIRS and not d.lower().startswith(SKIP_DIR_PREFIXES)
        ]
        for f in filenames:
            if not f.lower().endswith((".html", ".htm")):
                continue
            if ".bak-" in f or ".bak_" in f:
                continue
            full = os.path.join(dirpath, f)
            if only is not None:
                if os.path.basename(full) != only and os.path.relpath(full, root) != only:
                    continue
            yield full


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true")
    group.add_argument("--apply", action="store_true")
    parser.add_argument("--only", metavar="FILE", default=None)
    args = parser.parse_args()

    changed = []
    skipped_invalid = []
    skipped_still_dirty = []

    for path in find_html_files(REPO_ROOT, only=args.only):
        rel = os.path.relpath(path, REPO_ROOT)
        with open(path, "rb") as f:
            raw = f.read()

        try:
            text = raw.decode("utf-8-sig", errors="strict")
        except UnicodeDecodeError as e:
            skipped_invalid.append((rel, str(e)))
            continue

        if not has_mojibake(text):
            continue

        fixed, depth, ok = fix_text_multi(text)

        if not ok:
            skipped_still_dirty.append((rel, depth))
            continue

        if fixed == text:
            continue

        changed.append((rel, depth))

        if args.dry_run:
            print(f"[{rel}]  ({depth} peel{'s' if depth != 1 else ''})")
            shown = 0
            for old_line, new_line in zip(text.splitlines(), fixed.splitlines()):
                if old_line != new_line:
                    if shown >= 20:
                        print("  ...")
                        break
                    print(f"  - {old_line.strip()[:110]}")
                    print(f"  + {new_line.strip()[:110]}")
                    shown += 1
        else:
            os.makedirs(BACKUP_DIR, exist_ok=True)
            backup_path = os.path.join(BACKUP_DIR, rel.replace(os.sep, "__"))
            shutil.copy2(path, backup_path)
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(fixed)
            print(f"Fixed ({depth}p): {rel}")

    print()
    if args.dry_run:
        print(f"DRY RUN: {len(changed)} file(s) would be fixed.")
        print(f"Skipped (invalid UTF-8): {len(skipped_invalid)}")
        print(f"Skipped (still dirty after peel+ftfy): {len(skipped_still_dirty)}")
        if skipped_still_dirty:
            print("\nStill-dirty files:")
            for rel, d in skipped_still_dirty:
                print(f"  - {rel} (peeled {d}x, still dirty)")
    else:
        print(f"APPLIED: {len(changed)} file(s) fixed. Backups in _mojibake_backups/")
        if skipped_still_dirty:
            print(f"\n{len(skipped_still_dirty)} file(s) could not be cleaned:")
            for rel, d in skipped_still_dirty:
                print(f"  - {rel}")


if __name__ == "__main__":
    main()
