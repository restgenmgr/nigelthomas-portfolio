from pathlib import Path
import re
from datetime import datetime

# Read current file (even if broken)
p = Path('sitemap.xml')
content = p.read_text(encoding='utf-8') if p.exists() else ""

# Extract all <url>...</url> blocks using regex (non-greedy)
url_blocks = re.findall(r'<url>.*?</url>', content, re.DOTALL)

# Extract loc from each block
urls = {}
for block in url_blocks:
    loc_match = re.search(r'<loc>\s*(.*?)\s*</loc>', block, re.DOTALL)
    if loc_match:
        loc = loc_match.group(1).strip()
        # Try to get lastmod, priority, changefreq (optional)
        lastmod_match = re.search(r'<lastmod>(.*?)</lastmod>', block, re.DOTALL)
        lastmod = lastmod_match.group(1).strip() if lastmod_match else datetime.now().strftime('%Y-%m-%d')
        changefreq_match = re.search(r'<changefreq>(.*?)</changefreq>', block, re.DOTALL)
        changefreq = changefreq_match.group(1).strip() if changefreq_match else 'monthly'
        priority_match = re.search(r'<priority>(.*?)</priority>', block, re.DOTALL)
        priority = priority_match.group(1).strip() if priority_match else '0.5'
        urls[loc] = (lastmod, changefreq, priority)

# Add / overwrite the two specific URLs we want
new_urls = {
    'https://www.nigelthomas.live/blog/types-of-meal-plans-in-hotels.html': ('2026-09-06', 'monthly', '0.7'),
    'https://www.nigelthomas.live/fb-leadership-playbook.html': ('2026-09-06', 'monthly', '0.6')
}
urls.update(new_urls)

# Build the new sitemap
xml_header = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
urlset_entries = []
for loc, (lastmod, changefreq, priority) in urls.items():
    entry = f'''    <url>
        <loc>{loc}</loc>
        <lastmod>{lastmod}</lastmod>
        <changefreq>{changefreq}</changefreq>
        <priority>{priority}</priority>
    </url>'''
    urlset_entries.append(entry)

xml_footer = '</urlset>'
new_content = xml_header + '\n'.join(urlset_entries) + '\n' + xml_footer

# Write back
p.write_text(new_content, encoding='utf-8')
print('sitemap.xml rebuilt successfully.')