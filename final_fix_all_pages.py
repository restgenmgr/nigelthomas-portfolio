import os
import re
import shutil
from datetime import datetime
from bs4 import BeautifulSoup

ROOT = r"C:\Users\admin\Desktop\nigelthomas-portfolio"
BACKUP = os.path.join(ROOT, "backup_final_clean_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
DRY_RUN = False   # Set to True for preview

# ---------------------------------------------------------------------------
# 1. LIST OF PAGES TO FIX (add more if needed)
# ---------------------------------------------------------------------------
PAGES = [
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

# ---------------------------------------------------------------------------
# 2. RELATED PAGES MAPPING (root-relative paths)
# ---------------------------------------------------------------------------
RELATED_MAP = {
    "history-of-wine-world-wine-regions-guide.html": [
        "types-of-cheese-used-in-hotels.html",
        "types-of-pasta-sauces.html",
        "about.html",
    ],
    "types-of-pasta-sauces.html": [
        "types-of-cheese-used-in-hotels.html",
        "history-of-wine-world-wine-regions-guide.html",
        "food-cost-basics.html",
    ],
    "area-manager-vs-cluster-manager.html": [
        "restaurant-manager-roles-and-responsibilities.html",
        "food-cost-basics.html",
        "about.html",
    ],
    "blog/fine-dining-silverware.html": [
        "direct-vs-ota-booking-guest-occasion.html",
        "types-of-cheese-used-in-hotels.html",
        "about.html",
    ],
    "restaurant-manager-roles-and-responsibilities.html": [
        "area-manager-vs-cluster-manager.html",
        "haccp-hazard-analysis-critical-control-points.html",
        "food-cost-basics.html",
    ],
    "haccp-hazard-analysis-critical-control-points.html": [
        "food-cost-basics.html",
        "restaurant-manager-roles-and-responsibilities.html",
        "about.html",
    ],
    "direct-vs-ota-booking-guest-occasion.html": [
        "blog/fine-dining-silverware.html",
        "restaurant-manager-roles-and-responsibilities.html",
        "about.html",
    ],
    "types-of-cheese-used-in-hotels.html": [
        "history-of-wine-world-wine-regions-guide.html",
        "types-of-pasta-sauces.html",
        "food-cost-basics.html",
    ],
    "food-cost-basics.html": [
        "haccp-hazard-analysis-critical-control-points.html",
        "area-manager-vs-cluster-manager.html",
        "about.html",
    ],
    "about.html": [
        "restaurant-manager-roles-and-responsibilities.html",
        "food-cost-basics.html",
        "history-of-wine-world-wine-regions-guide.html",
    ],
}

# ---------------------------------------------------------------------------
# 3. HTML TEMPLATES
# ---------------------------------------------------------------------------
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

RELATED_HTML = '''
<section class="related-pages" style="margin:2.5rem 0 1rem;padding-top:1.5rem;border-top:1px solid #333;">
  <h2 style="font-size:1.1rem;margin-bottom:0.75rem;">You Might Also Like</h2>
  <ul style="list-style:none;padding:0;margin:0;display:flex;flex-direction:column;gap:0.5rem;">
    {items}
  </ul>
</section>
'''

def read_file_safe(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    except UnicodeDecodeError:
        with open(path, 'r', encoding='latin-1') as f:
            return f.read()

def clean_old_panels(soup):
    """Remove any existing Infomatics panels (all variants)."""
    # Remove div.infomatics-launcher
    for launcher in soup.find_all('div', class_='infomatics-launcher'):
        launcher.decompose()
    # Remove any style blocks with infomatics keywords
    for style in soup.find_all('style'):
        if style.string and ('infomatics-launcher' in style.string or 'infomatics-btn' in style.string):
            style.decompose()
    # Remove any details with "Infomatics" summary (if any)
    for details in soup.find_all('details'):
        summary = details.find('summary')
        if summary and 'Infomatics' in summary.get_text():
            details.decompose()
    # Remove any section with data-related-pages-marker (if already added)
    for section in soup.find_all(attrs={"data-related-pages-marker": "1"}):
        section.decompose()

def get_title(rel_path):
    """Extract <title> from a page; fallback to filename."""
    full_path = os.path.join(ROOT, rel_path)
    if not os.path.exists(full_path):
        return os.path.basename(rel_path).replace("-", " ").replace(".html", "").title()
    try:
        soup = BeautifulSoup(read_file_safe(full_path), "html.parser")
        if soup.title and soup.title.string:
            title = soup.title.string.strip()
            # Remove common suffix like " | Nigel A. Thomas"
            title = re.split(r"\s*[\|\u2013\u2014-]\s*Nigel", title)[0].strip()
            return title
    except:
        pass
    return os.path.basename(rel_path).replace("-", " ").replace(".html", "").title()

def find_poster_element(soup):
    """Find the poster element (priority: div.poster-wrap, figure, main img)."""
    # 1. div with poster-wrap
    poster_div = soup.find('div', class_=re.compile(r'poster-wrap'))
    if poster_div:
        return poster_div
    # 2. figure with article-figure or poster
    poster_figure = soup.find('figure', class_=re.compile(r'article-figure|poster'))
    if poster_figure:
        return poster_figure
    # 3. img inside main/article with poster keyword in src/alt
    main = soup.find('main') or soup.find('article')
    if main:
        for img in main.find_all('img'):
            src = img.get('src', '').lower()
            alt = img.get('alt', '').lower()
            keywords = ['poster','infographic','guide','cheese','haccp','wine','pasta','silverware','cluster','manager','roles','booking']
            if any(kw in src for kw in keywords) or any(kw in alt for kw in keywords):
                parent = img.parent
                if parent.name in ['div','figure','section']:
                    return parent
                else:
                    return img
    # 4. Fallback: first large image in body
    for img in soup.find_all('img'):
        w = img.get('width', '0')
        if w.isdigit() and int(w) > 200:
            return img
    return None

def process_page(rel_path):
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

    # 1. Clean all old Infomatics panels
    clean_old_panels(soup)

    # 2. Find poster element
    poster = find_poster_element(soup)
    if poster:
        poster_html = str(poster)
        poster.extract()
    else:
        print("  ℹ️ No poster element found, skipping poster move")
        poster_html = "<!-- No poster found -->"

    # 3. Insert new details panel (if poster exists)
    if poster:
        details = DETAILS_HTML.replace('<!-- POSTER CONTENT WILL BE INSERTED HERE -->', poster_html)
        details_soup = BeautifulSoup(details, 'html.parser')
        body.append(details_soup)
        print("  ✅ Inserted working Infomatics toggle")

    # 4. Add Related Pages section (if mapping exists)
    targets = RELATED_MAP.get(rel_path)
    if targets:
        items = []
        for t in targets:
            href = "/" + t.replace(os.sep, "/")
            title = get_title(t)
            items.append(f'<li><a href="{href}" style="color:#d4af37;text-decoration:none;">{title}</a></li>')
        related_section = RELATED_HTML.format(items="\n".join(items))
        related_soup = BeautifulSoup(related_section, 'html.parser')
        body.append(related_soup)
        print(f"  ✅ Added Related Pages ({len(targets)} links)")
    else:
        print("  ℹ️ No related links defined for this page")

    # 5. Save
    if not DRY_RUN:
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(str(soup))
        print("  💾 Saved")
    else:
        print("  🔍 DRY RUN – would save")

# ---------------------------------------------------------------------------
# 4. RUN
# ---------------------------------------------------------------------------
if not DRY_RUN:
    os.makedirs(BACKUP, exist_ok=True)

for page in PAGES:
    full_path = os.path.join(ROOT, page)
    if os.path.exists(full_path):
        if not DRY_RUN:
            rel = os.path.relpath(full_path, ROOT)
            back = os.path.join(BACKUP, rel)
            os.makedirs(os.path.dirname(back), exist_ok=True)
            shutil.copy2(full_path, back)
        process_page(page)
    else:
        print(f"File not found: {page}")

print("Done.")
