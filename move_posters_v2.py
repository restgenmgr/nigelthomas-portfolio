import os
import re
import shutil
from datetime import datetime
from bs4 import BeautifulSoup

ROOT_DIR = r"C:\Users\admin\Desktop\nigelthomas-portfolio"
BACKUP_DIR = os.path.join(ROOT_DIR, "backup_posters_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
LOG_FILE = os.path.join(ROOT_DIR, "poster_move_log_v2.txt")
DRY_RUN = False

PANEL_HTML = '''
<div class="infomatics-launcher">
  <button type="button" class="infomatics-btn" aria-expanded="false" onclick="var p=document.getElementById('infomatics-panel');var open=p.classList.toggle('active');this.setAttribute('aria-expanded', open?'true':'false');">
    Infomatics
  </button>
  <div id="infomatics-panel" class="infomatics-panel">
    <!-- POSTER CONTENT WILL BE INSERTED HERE -->
  </div>
</div>
<style>
.infomatics-launcher{margin:2rem 0;}
.infomatics-btn{padding:0.6em 1.4em;border:none;border-radius:6px;background:#1f2937;color:#fff;font-weight:600;cursor:pointer;}
.infomatics-btn:hover{background:#374151;}
.infomatics-panel{display:none;margin-top:1rem;}
.infomatics-panel.active{display:block;}
</style>
'''

def log_message(msg):
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(msg + "\n")
    print(msg)

def process_file(filepath):
    log_message(f"Processing: {filepath}")
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            html = f.read()

        soup = BeautifulSoup(html, "html.parser")
        body = soup.find("body")
        if not body:
            log_message("  ⚠️ No <body> found, skipping.")
            return

        # Find ANY element (tag) that has class or id containing "poster"
        poster_elements = []
        for elem in soup.find_all():
            classes = elem.get('class', [])
            elem_id = elem.get('id', '')
            # Check both class and id
            if any('poster' in (c or '') for c in classes) or 'poster' in elem_id:
                poster_elements.append(elem)

        if not poster_elements:
            log_message("  ℹ️ No poster elements found.")
            return

        if soup.find(string=re.compile(r'INFOMATICS-PANEL')):
            log_message("  ⏭️ Panel already exists, skipping.")
            return

        poster_htmls = []
        for elem in poster_elements:
            poster_htmls.append(str(elem))
            elem.extract()

        panel_with_content = PANEL_HTML.replace("<!-- POSTER CONTENT WILL BE INSERTED HERE -->", "\n".join(poster_htmls))
        panel_soup = BeautifulSoup(panel_with_content, "html.parser")

        body.append(panel_soup)

        if not DRY_RUN:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(str(soup))
            log_message(f"  ✅ Updated: moved {len(poster_htmls)} poster(s).")
        else:
            log_message(f"  🔍 DRY RUN: would move {len(poster_htmls)} poster(s).")

    except Exception as e:
        log_message(f"  ❌ ERROR: {str(e)}")

def main():
    if not DRY_RUN:
        os.makedirs(BACKUP_DIR, exist_ok=True)
        log_message(f"Backup folder: {BACKUP_DIR}")

    # Exclude directories with these names
    exclude_dirs = {'backup', 'mojibake', 'metadata', '_backup', '_mojibake', '_metadata'}
    for root, dirs, files in os.walk(ROOT_DIR):
        # Filter out excluded directories
        dirs[:] = [d for d in dirs if not any(ex in d.lower() for ex in exclude_dirs)]
        for file in files:
            if file.endswith('.html') and not file.startswith('.'):
                filepath = os.path.join(root, file)
                if not DRY_RUN:
                    rel_path = os.path.relpath(filepath, ROOT_DIR)
                    backup_path = os.path.join(BACKUP_DIR, rel_path)
                    os.makedirs(os.path.dirname(backup_path), exist_ok=True)
                    shutil.copy2(filepath, backup_path)
                process_file(filepath)

    log_message("\n✅ Done!")
    if DRY_RUN:
        log_message("🔍 This was a DRY RUN – no files were modified. Remove --dry-run to actually move posters.")

if __name__ == "__main__":
    import sys
    if "--dry-run" in sys.argv:
        DRY_RUN = True
    elif "--no-dry-run" in sys.argv:
        DRY_RUN = False
    main()