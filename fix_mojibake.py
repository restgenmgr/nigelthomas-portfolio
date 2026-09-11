"""
fix_mojibake.py
Scans all .html files in the repo for mojibake (UTF-8 emoji/punctuation
that got saved or read as Windows-1252) and fixes them using ftfy.

Usage:
  python fix_mojibake.py --dry-run                Preview what would change, no writes
  python fix_mojibake.py --apply                  Fix files for real (backs up originals first)
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

SKIP_DIRS = {
    ".git",
    "node_modules",
    "_mojibake_backups",
    "encoding_backup",
    "encoding_fix2_backup",
    "_metadata_backups",
}
SKIP_DIR_PREFIXES = ("backup-html", "backup")


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
                # match by basename or relative path (either style works)
                if os.path.basename(full) != only and os.path.relpath(full, root) != only:
                    continue
            yield full


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true", help="Preview only, no writes")
    group.add_argument("--apply", action="store_true", help="Write fixes (backs up originals)")
    parser.add_argument("--only", metavar="FILE", default=None,
                        help="Process only this file (basename or relative path)")
    args = parser.parse_args()

    changed_files = []
    skipped_invalid = []

    for path in find_html_files(REPO_ROOT, only=args.only):
        rel = os.path.relpath(path, REPO_ROOT)

        with open(path, "rb") as f:
            raw = f.read()

        # Strict decode. If a file has real byte-level corruption (not just
        # multi-layer mis-decoding), we skip it rather than risk data loss.
        try:
            text = raw.decode("utf-8-sig", errors="strict")
        except UnicodeDecodeError as e:
            skipped_invalid.append((rel, str(e)))
            print(f"SKIP (invalid UTF-8, not touched): {rel} — {e}")
            continue

        # uncurl_quotes=False keeps straight quotes as-is, which matters for
        # HTML attributes like <div class="foo">.
        fixed = ftfy.fix_text(text, uncurl_quotes=False)

        if fixed == text:
            continue

        changed_files.append(rel)

        if args.dry_run:
            print(f"[{rel}]")
            diffs_shown = 0
            for old_line, new_line in zip(text.splitlines(), fixed.splitlines()):
                if old_line != new_line:
                    if diffs_shown >= 40:
                        print("  ...")
                        break
                    print(f"  - {old_line.strip()[:120]}")
                    print(f"  + {new_line.strip()[:120]}")
                    diffs_shown += 1
        else:
            os.makedirs(BACKUP_DIR, exist_ok=True)
            backup_path = os.path.join(BACKUP_DIR, rel.replace(os.sep, "__"))
            shutil.copy2(path, backup_path)

            # Write back BOM-free UTF-8, matching site standard
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(fixed)
            print(f"Fixed: {rel}  (backup: {os.path.relpath(backup_path, REPO_ROOT)})")

    print()
    if args.dry_run:
        print(f"DRY RUN: {len(changed_files)} file(s) contain mojibake that would be fixed.")
        for c in changed_files:
            print(f"  - {c}")
        if skipped_invalid:
            print(f"\n{len(skipped_invalid)} file(s) skipped (invalid UTF-8):")
            for rel, err in skipped_invalid:
                print(f"  - {rel}")
        print("\nReview above, then run with --apply to fix for real.")
    else:
        print(f"APPLIED: {len(changed_files)} file(s) fixed. Originals backed up in _mojibake_backups/")
        for c in changed_files:
            print(f"  - {c}")
        if skipped_invalid:
            print(f"\n{len(skipped_invalid)} file(s) skipped (invalid UTF-8):")
            for rel, err in skipped_invalid:
                print(f"  - {rel}")
        print("\nNext: verify a few pages in the browser, then git add/commit/push.")
        print("Also consider: git stash the backup dir is ignored by .gitignore.")


if __name__ == "__main__":
    main()
