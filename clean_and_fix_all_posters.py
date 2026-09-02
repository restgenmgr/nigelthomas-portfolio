import os
import re
import shutil
from datetime import datetime
from bs4 import BeautifulSoup

ROOT = r"C:\Users\admin\Desktop\nigelthomas-portfolio"
BACKUP = os.path.join(ROOT, "backup_final_clean_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
DRY_RUN = False   # Set to True for preview

# The exact pages to fix (add more if needed)
FILES = [
    "history-of-wine-world-wine-regions-guide.html",
    "types-of-pasta-sauces.html",
    "area-manager-vs-cluster-manager.html",
    "blog/fine-dining-silverware.html",
    "restaurant-manager-roles-and-responsibilities.html",
    "haccp-hazard-analysis-critical-control-points.html",
    "direct-vs-ota-booking-guest-occasion.html",
    "types-of-cheese-used-in-hotels.html",
    "food-cost-basics.html",
    "about.html",
]

# The working, no‑JS Infomatics block
DETAILS_HTML = '''
<details style="margin:2rem 0;">
  <summary style="display:inline-block;padding:0.6em 1.4em;border:none;border-radius:6px;background:#1f2937;color:#fff;font-weight:600;cursor:pointer;font-size:1rem;">
    Infomatics
  </summary>
  <div style="margin-top:1rem;padding:1rem;background:#141414;border:1px solid #262626;border-radius:6px;">
    <!-- POSTER CONTENT WILL BE INSERTED HERE -->
  </div>
</details>
'''

def read_file_safe(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except UnicodeDecodeError:
        with open(path, 'r', encoding='latin-1') as f:
            return f.read()

def clean_old_panels(soup):
    """Remove any existing Infomatics panels (duplicates)."""
    for launcher in soup.find_all('div', class_='infomatics-launcher'):
        launcher.decompose()
    # Also remove any stray style blocks that might be from duplicates
    for style in soup.find_all('style'):
        if 'infomatics-launcher' in style.string or 'infomatics-btn' in style.string:
            style.decompose()

def find_poster_element(soup):
    """Find the poster element – priority: div.poster-wrap, then figure, then main img."""
    # 1. Look for div with class containing 'poster-wrap'
    poster_div = soup.find('div', class_=re.compile(r'poster-wrap'))
    if poster_div:
        return poster_div
    # 2. Look for figure with class containing 'article-figure' or 'poster'
    poster_figure = soup.find('figure', class_=re.compile(r'article-figure|poster'))
    if poster_figure:
        return poster_figure
    # 3. Look for any img inside <main> or <article> that has 'poster' in src/alt
    main = soup.find('main') or soup.find('article')
    if main:
        for img in main.find_all('img'):
            src = img.get('src', '').lower()
            alt = img.get('alt', '').lower()
            if any(kw in src for kw in ['poster','infographic','guide','cheese','haccp','wine','pasta','silverware','cluster','manager','roles','booking']) \
               or any(kw in alt for kw in ['poster','infographic','guide','cheese','haccp','wine','pasta','silverware','cluster','manager','roles','booking']):
                # take the whole parent if it's a div or figure, else just the img
                parent = img.parent
                if parent.name in ['div', 'figure', 'section']:
                    return parent
                else:
                    return img
    # 4. Fallback: first large image in body (if >300px)
    for img in soup.find_all('img'):
        width = img.get('width', '0')
        if width.isdigit() and int(width) > 200:
            return img
    return None

def process_file(rel_path):
    full_path = os.path.join(ROOT, rel_path)
    if not os.path.exists(full_path):
        print(f"❌ File not found: {rel_path}")
        return
    print(f"Processing: {rel_path}")

    html = read_file_safe(full_path)
    soup = BeautifulSoup(html, 'html.parser')
    body = soup.find('body')
    if not body:
        print("  ⚠️ No <body>")
        return

    # 1. Clean old Infomatics panels
    clean_old_panels(soup)

    # 2. Check if we already have a <details> with "Infomatics"
    if soup.find('details', string=re.compile(r'Infomatics')):
        print("  ⏭️ Already has clean Infomatics details, skipping.")
        return

    # 3. Find the poster element
    poster = find_poster_element(soup)
    if not poster:
        print("  ℹ️ No poster element found")
        return

    # 4. Extract it
    poster_html = str(poster)
    poster.extract()

    # 5. Build the details panel with the poster inside
    details = DETAILS_HTML.replace('<!-- POSTER CONTENT WILL BE INSERTED HERE -->', poster_html)
    details_soup = BeautifulSoup(details, 'html.parser')
    body.append(details_soup)

    # 6. Save
    if not DRY_RUN:
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(str(soup))
        print(f"  ✅ Updated: moved poster into Infomatics details")
    else:
        print(f"  🔍 DRY RUN: would move poster")

# Create backup folder
if not DRY_RUN:
    os.makedirs(BACKUP, exist_ok=True)

for f in FILES:
    full_path = os.path.join(ROOT, f)
    if os.path.exists(full_path):
        if not DRY_RUN:
            rel = os.path.relpath(full_path, ROOT)
            back = os.path.join(BACKUP, rel)
            os.makedirs(os.path.dirname(back), exist_ok=True)
            shutil.copy2(full_path, back)
        process_file(f)
    else:
        print(f"File not found: {f}")

print("Done.")
