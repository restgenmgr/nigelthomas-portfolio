$py = @'
"""
fix_mojibake.py
Scans all .html files in the repo for mojibake (UTF-8 emoji/punctuation
that got saved or read as Windows-1252) and fixes them using ftfy.

Usage:
  python fix_mojibake.py --dry-run     Preview what would change, no writes
  python fix_mojibake.py --apply       Fix files for real (backs up originals first)

Requires: pip install ftfy   (or: python -m pip install ftfy)
"""

import argparse
import os
import shutil
import sys

try:
    import ftfy
except ImportError:
    print("Missing dependency. Run: python -m pip install ftfy")
    sys.exit(1)

REPO_ROOT = os.getcwd()
BACKUP_DIR = os.path.join(REPO_ROOT, "_mojibake_backups")
SKIP_DIRS = {".git", "node_modules", "_mojibake_backups"}


def find_html_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for f in filenames:
            if f.lower().endswith((".html", ".htm")):
                yield os.path.join(dirpath, f)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true", help="Preview only, no writes")
    group.add_argument("--apply", action="store_true", help="Write fixes (backs up originals)")
    args = parser.parse_args()

    changed_files = []

    for path in find_html_files(REPO_ROOT):
        with open(path, "rb") as f:
            raw = f.read()

        text = raw.decode("utf-8-sig", errors="replace")
        fixed = ftfy.fix_text(text)

        if fixed != text:
            changed_files.append(path)
            rel = os.path.relpath(path, REPO_ROOT)

            if args.dry_run:
                for old_line, new_line in zip(text.splitlines(), fixed.splitlines()):
                    if old_line != new_line:
                        print(f"[{rel}]")
                        print(f"  - {old_line.strip()[:100]}")
                        print(f"  + {new_line.strip()[:100]}")
            else:
                os.makedirs(BACKUP_DIR, exist_ok=True)
                backup_path = os.path.join(BACKUP_DIR, rel.replace(os.sep, "__"))
                shutil.copy2(path, backup_path)

                with open(path, "w", encoding="utf-8", newline="") as f:
                    f.write(fixed)
                print(f"Fixed: {rel}  (backup: {os.path.relpath(backup_path, REPO_ROOT)})")

    print()
    if args.dry_run:
        print(f"DRY RUN: {len(changed_files)} file(s) contain mojibake that would be fixed.")
        print("Review above, then run with --apply to fix for real.")
    else:
        print(f"APPLIED: {len(changed_files)} file(s) fixed. Originals backed up in _mojibake_backups/")
        print("Now run your normal verification + git add/commit/push/vercel steps.")


if __name__ == "__main__":
    main()
'@

$path = Join-Path (Get-Location) "fix_mojibake.py"
[System.IO.File]::WriteAllText($path, $py, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Written: $path" -ForegroundColor Green
Test-Path $path
