from pathlib import Path
import re

p = Path('sitemap.xml')
content = p.read_text(encoding='utf-8')

# Extract all URLs from the current file (ignore malformed tags)
urls = set(re.findall(r'<loc>(.*?)</loc>', content, re.DOTALL))

# Add the two new URLs we need
urls.add('https://www.nigelthomas.live/blog/types-of-meal-plans-in-hotels.html')
urls.add('https://www.nigelthomas.live/fb-leadership-playbook.html')

# Build a clean XML
header = '<?xml version="1.0" encoding="UTF-8"?>\n'
header += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
entries = []
for u in sorted(urls):
    if 'meal-plans' in u:
        priority = '0.7'
    elif 'fb-leadership' in u:
        priority = '0.6'
    else:
        priority = '0.5'
    entries.append(f'''    <url>
        <loc>{u}</loc>
        <lastmod>2026-09-06</lastmod>
        <changefreq>monthly</changefreq>
        <priority>{priority}</priority>
    </url>''')
footer = '</urlset>'
new_content = header + '\n'.join(entries) + '\n' + footer

# Write back
p.write_text(new_content, encoding='utf-8')
print('sitemap.xml rebuilt successfully.')
