"""
fix_mojibake.py
Scans all .html files in the repo for mojibake (UTF-8 emoji/punctuation
that got saved or read as Windows-1252) and fixes them.

Strategy:
  1. Peel utf8→latin1 repeatedly until no mojibake signature remains
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
MOJIBAKE_SIGS = [
    "Ãƒ",       # multi-layer
    "Ã‚",       # multi-layer
    "Ã¢â‚¬",    # multi-layer
    "ðŸ",       # single-layer (most common)
    "â€"",       # en dash single-layer
    "â€œ",       # left double quote
    "â€\x9d",   # right double quote
    "â€™",       # right single quote
    "Ã©", "Ã¨", "Ã ",  # accented latin
    "Â°", "Â£", "Â©",   # misc single-layer symbols
]


def has_mojibake(text):
    return any(sig in text for sig in MOJIBAKE_SIGS)


def peel(text):
    """Peel utf8→latin1 one layer. Returns new text."""
    return text.encode("latin-1", errors="strict").decode("utf-8", errors="strict")


def fix_text_multi(text):
    """Peel until no mojibake signature, then ftfy. Returns (fixed, depth, ok)."""
    depth = 0
    # Up to 6 peels — the worst we've seen is 5
    while has_mojibake(text) and depth < 6:
        try:
            text = peel(text)
        except (UnicodeDecodeError, UnicodeEncodeError):
            # Can't peel this file cleanly — bail and let caller decide
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
