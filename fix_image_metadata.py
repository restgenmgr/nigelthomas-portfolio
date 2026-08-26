#!/usr/bin/env python3
"""
fix_image_metadata.py

Scans HTML files for <script type="application/ld+json"> blocks, finds any
ImageObject (top-level or nested, e.g. inside an Article's "image" field),
and injects the four fields Google Search Console flagged as missing:

    license
    acquireLicensePage
    copyrightNotice
    creditText

Follows the same conventions as fix_mojibake.py:
  - --dry-run by default, --apply to actually write
  - auto-backup to _metadata_backups/ before any write
  - BOM-free UTF-8 output

USAGE
    python fix_image_metadata.py --dry-run
    python fix_image_metadata.py --apply
    python fix_image_metadata.py --apply --root "C:\\Users\\admin\\Desktop\\nigelthomas-portfolio"

You can override the default values below with CLI flags:
    --license-url            (default: https://www.nigelthomas.live/image-usage.html)
    --acquire-license-url    (default: https://www.nigelthomas.live/image-usage.html)
    --copyright-notice       (default: "© 2026 Nigel A. Thomas")
    --credit-text            (default: "Nigel A. Thomas — Hospitality Executive")
"""

import argparse
import json
import os
import re
import shutil
import sys
from datetime import datetime

LD_JSON_BLOCK_RE = re.compile(
    r'(<script[^>]+type=["\']application/ld\+json["\'][^>]*>)(.*?)(</script>)',
    re.DOTALL | re.IGNORECASE,
)

DEFAULT_LICENSE_URL = "https://www.nigelthomas.live/image-usage.html"
DEFAULT_ACQUIRE_URL = "https://www.nigelthomas.live/image-usage.html"
DEFAULT_COPYRIGHT = "\u00a9 2026 Nigel A. Thomas"
DEFAULT_CREDIT = "Nigel A. Thomas \u2014 Hospitality Executive"

REQUIRED_FIELDS = ["license", "acquireLicensePage", "copyrightNotice", "creditText"]


def find_image_objects(node, found):
    """Recursively walk a parsed JSON-LD structure and collect every dict
    whose @type is (or includes) 'ImageObject'."""
    if isinstance(node, dict):
        type_val = node.get("@type")
        is_image_object = type_val == "ImageObject" or (
            isinstance(type_val, list) and "ImageObject" in type_val
        )
        if is_image_object:
            found.append(node)
        for value in node.values():
            find_image_objects(value, found)
    elif isinstance(node, list):
        for item in node:
            find_image_objects(item, found)


def inject_fields(image_obj, values):
    changed = []
    for field in REQUIRED_FIELDS:
        if field not in image_obj or not image_obj.get(field):
            image_obj[field] = values[field]
            changed.append(field)
    return changed


def process_file(path, values, apply_changes, backup_dir):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    matches = list(LD_JSON_BLOCK_RE.finditer(content))
    if not matches:
        return None  # no JSON-LD in this file

    file_changed = False
    report_lines = []
    new_content = content

    # Process matches in reverse so string offsets stay valid as we edit.
    for m in reversed(matches):
        raw_json = m.group(2)
        try:
            data = json.loads(raw_json)
        except json.JSONDecodeError as e:
            report_lines.append(f"    ! could not parse JSON-LD block ({e})")
            continue

        image_objects = []
        find_image_objects(data, image_objects)

        if not image_objects:
            continue

        block_changed = False
        for io in image_objects:
            changed = inject_fields(io, values)
            if changed:
                block_changed = True
                content_url = io.get("contentUrl") or io.get("url") or "(no contentUrl)"
                report_lines.append(f"    + {content_url} -> added {', '.join(changed)}")

        if block_changed:
            file_changed = True
            new_json_str = json.dumps(data, ensure_ascii=False, indent=2)
            start, end = m.span(2)
            new_content = new_content[:start] + new_json_str + new_content[end:]

    if not file_changed:
        return None

    if apply_changes:
        rel_backup_path = os.path.join(backup_dir, os.path.relpath(path, start=os.getcwd()))
        os.makedirs(os.path.dirname(rel_backup_path), exist_ok=True)
        shutil.copy2(path, rel_backup_path)

        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(new_content)

    return report_lines


def main():
    parser = argparse.ArgumentParser(description="Inject missing ImageObject metadata fields into JSON-LD across the site.")
    parser.add_argument("--root", default=".", help="Root folder to scan (default: current directory)")
    parser.add_argument("--apply", action="store_true", help="Write changes. Without this flag, runs as a dry run.")
    parser.add_argument("--dry-run", action="store_true", help="Explicit dry run (default behavior).")
    parser.add_argument("--license-url", default=DEFAULT_LICENSE_URL)
    parser.add_argument("--acquire-license-url", default=DEFAULT_ACQUIRE_URL)
    parser.add_argument("--copyright-notice", default=DEFAULT_COPYRIGHT)
    parser.add_argument("--credit-text", default=DEFAULT_CREDIT)
    parser.add_argument("--ext", default=".html,.htm", help="Comma-separated file extensions to scan")
    args = parser.parse_args()

    apply_changes = args.apply and not args.dry_run
    extensions = tuple(e.strip().lower() for e in args.ext.split(","))

    values = {
        "license": args.license_url,
        "acquireLicensePage": args.acquire_license_url,
        "copyrightNotice": args.copyright_notice,
        "creditText": args.credit_text,
    }

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.join(args.root, "_metadata_backups", timestamp)

    total_files_changed = 0
    total_images_changed = 0

    for dirpath, dirnames, filenames in os.walk(args.root):
        # skip backup folders and typical non-source dirs
        dirnames[:] = [d for d in dirnames if d not in (
            "_metadata_backups", "_mojibake_backups", "node_modules", ".git"
        )]
        for filename in filenames:
            if not filename.lower().endswith(extensions):
                continue
            path = os.path.join(dirpath, filename)
            report = process_file(path, values, apply_changes, backup_dir)
            if report:
                total_files_changed += 1
                total_images_changed += sum(1 for line in report if line.strip().startswith("+"))
                print(f"\n{path}")
                for line in report:
                    print(line)

    print("\n" + "=" * 60)
    mode = "APPLIED" if apply_changes else "DRY RUN (no files written)"
    print(f"Mode: {mode}")
    print(f"Files changed: {total_files_changed}")
    print(f"ImageObject blocks updated: {total_images_changed}")
    if apply_changes and total_files_changed:
        print(f"Backups saved to: {backup_dir}")
    if not apply_changes:
        print("Re-run with --apply to write these changes.")
    print("=" * 60)


if __name__ == "__main__":
    sys.exit(main())
