#!/usr/bin/env python3
"""
scan_mojibake.py

Sitewide mojibake checkup for nigelthomas-portfolio.

Scans every HTML file for:
  1. KNOWN broken sequences (specific corrupted em dashes, emoji, accented
     letters we've already traced byte-for-byte) - these get auto-fixed.
  2. UNKNOWN suspicious sequences (generic patterns typical of UTF-8/
     Windows-1252 mis-decoding) - these are only reported, never guessed at,
     since fixing them blind risks corrupting content further.

Follows the same conventions as your other site scripts:
  - --dry-run by default, --apply to actually write
  - auto-backup to _mojibake_scan_backups/ before any write
  - skips _metadata_backups, _mojibake_backups, backup-html-*, .git, node_modules
  - BOM-free UTF-8 output

USAGE
    python scan_mojibake.py --dry-run
    python scan_mojibake.py --apply
    python scan_mojibake.py --root "C:\\Users\\admin\\Desktop\\nigelthomas-portfolio"
"""

import argparse
import os
import re
import shutil
import sys
from datetime import datetime

KNOWN_FIXES = {
    chr(0x00e2) + chr(0x20ac) + chr(0x201d): chr(0x2014),
    chr(0xfffd): chr(0x2014),
    "Caf" + chr(0xfffd): "Caf" + chr(0xe9),
    "?" + chr(0x00e2) + chr(0x0161) + chr(0x2122) + chr(0x00ef) + chr(0x00b8) + chr(0x008f): chr(0x2699) + chr(0xfe0f),
    "?" + chr(0x00f0) + chr(0x0178) + chr(0x008d) + chr(0x00b7): chr(0x1F377),
    "?" + chr(0x00f0) + chr(0x0178) + chr(0x2019) + chr(0x00bc): chr(0x1F4BC),
}

SUSPICIOUS_PATTERNS = [
    re.compile(chr(0xFFFD)),
    re.compile(chr(0x00c3) + "[" + chr(0x0080) + "-" + chr(0x00bf) + "]"),
    re.compile(chr(0x00e2) + chr(0x20ac) + "[" + chr(0x0080) + "-" + chr(0x00ff) + "]"),
    re.compile(r"\?" + chr(0x00f0)),
    re.compile(r"\?" + chr(0x00e2)),
]

SKIP_DIRS = {"_metadata_backups", "_mojibake_backups", "_mojibake_scan_backups", "node_modules", ".git"}


def should_skip_dir(dirname):
    if dirname in SKIP_DIRS:
        return True
    if dirname.lower().startswith("backup-html-"):
        return True
    return False


def scan_file(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except UnicodeDecodeError:
        with open(path, "r", encoding="cp1252") as f:
            content = f.read()

    known_found = {}
    for broken in KNOWN_FIXES:
        count = content.count(broken)
        if count:
            known_found[broken] = count

    suspicious = []
    lines = content.split("\n")
    for i, line in enumerate(lines, start=1):
        for pattern in SUSPICIOUS_PATTERNS:
            if pattern.search(line):
                stripped = line
                for broken in KNOWN_FIXES:
                    stripped = stripped.replace(broken, "")
                if any(p.search(stripped) for p in SUSPICIOUS_PATTERNS):
                    snippet = line.strip()[:120]
                    suspicious.append((i, snippet))
                break

    return known_found, suspicious


def fix_file(path, backup_dir, root):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    total_fixed = 0
    ordered_keys = sorted(KNOWN_FIXES.keys(), key=len, reverse=True)
    for broken in ordered_keys:
        fixed = KNOWN_FIXES[broken]
        count = content.count(broken)
        if count:
            content = content.replace(broken, fixed)
            total_fixed += count

    if total_fixed:
        rel_backup_path = os.path.join(backup_dir, os.path.relpath(path, start=root))
        os.makedirs(os.path.dirname(rel_backup_path), exist_ok=True)
        shutil.copy2(path, rel_backup_path)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)

    return total_fixed


def main():
    parser = argparse.ArgumentParser(description="Scan (and optionally fix) mojibake across all site HTML files.")
    parser.add_argument("--root", default=".", help="Root folder to scan (default: current directory)")
    parser.add_argument("--apply", action="store_true", help="Write known fixes. Without this flag, runs as a dry run.")
    parser.add_argument("--dry-run", action="store_true", help="Explicit dry run (default behavior).")
    parser.add_argument("--ext", default=".html,.htm", help="Comma-separated file extensions to scan")
    args = parser.parse_args()

    apply_changes = args.apply and not args.dry_run
    extensions = tuple(e.strip().lower() for e in args.ext.split(","))

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.join(args.root, "_mojibake_scan_backups", timestamp)

    files_with_known = 0
    files_with_suspicious = 0
    suspicious_report = []

    for dirpath, dirnames, filenames in os.walk(args.root):
        dirnames[:] = [d for d in dirnames if not should_skip_dir(d)]
        for filename in filenames:
            if not filename.lower().endswith(extensions):
                continue
            path = os.path.join(dirpath, filename)
            known_found, suspicious = scan_file(path)

            if known_found:
                files_with_known += 1
                print(f"\n{path}")
                for broken, count in known_found.items():
                    print(f"    known fix available: {count}x {broken!r}")
                if apply_changes:
                    fixed_count = fix_file(path, backup_dir, args.root)
                    print(f"    -> fixed {fixed_count} occurrence(s)")

            if suspicious:
                files_with_suspicious += 1
                suspicious_report.append((path, suspicious))

    if suspicious_report:
        print("\n" + "=" * 60)
        print("SUSPICIOUS (not auto-fixed - needs manual review):")
        for path, items in suspicious_report:
            print(f"\n{path}")
            for lineno, snippet in items[:5]:
                print(f"    line {lineno}: {snippet}")
            if len(items) > 5:
                print(f"    ... and {len(items) - 5} more line(s)")

    print("\n" + "=" * 60)
    mode = "APPLIED" if apply_changes else "DRY RUN (no files written)"
    print(f"Mode: {mode}")
    print(f"Files with known fixes: {files_with_known}")
    print(f"Files with suspicious (unreviewed) patterns: {files_with_suspicious}")
    if apply_changes and files_with_known:
        print(f"Backups saved to: {backup_dir}")
    if not apply_changes and files_with_known:
        print("Re-run with --apply to write the known fixes.")
    if files_with_suspicious:
        print("Suspicious lines were NOT changed - review them manually.")
    print("=" * 60)


if __name__ == "__main__":
    sys.exit(main())