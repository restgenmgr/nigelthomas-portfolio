with open('blog.html', 'r', encoding='utf-8') as f:
    content = f.read()

old = '        <h2 class="section-title">Featured Articles</h2>\n\n        <div class="article-card">\n            <div class="article-title"><a href="/14-major-food-allergens.html">14 Major Food Allergens Every Hospitality Professional Must Know</a></div>'

new = '        <h2 class="section-title">Featured Articles</h2>\n\n        <div class="article-card">\n            <div class="article-title"><a href="/hotel-management-playbook-month-end-reporting.html">Hotel Management Playbook - Month-End Reporting Secrets of Top Hotels</a></div>\n            <div class="article-meta"><span class="badge badge-gold">Newest</span> Hotel Operations &middot; Management Reporting &middot; July 2026</div>\n            <p class="article-excerpt">The complete month-end reporting framework across 10 departments - Rooms, Housekeeping, F&amp;B, Kitchen, Finance, Sales &amp; Marketing, Engineering, HR, Security and Purchasing - plus the Management Dashboard that ties them together.</p>\n            <a href="/hotel-management-playbook-month-end-reporting.html" class="read-more-btn">Read Article &rarr;</a>\n        </div>\n\n        <div class="article-card">\n            <div class="article-title"><a href="/14-major-food-allergens.html">14 Major Food Allergens Every Hospitality Professional Must Know</a></div>'

if old in content:
    content = content.replace(old, new)
    with open('blog.html', 'w', encoding='utf-8', newline='') as f:
        f.write(content)
    print('Playbook card added successfully')
    print('Refs to playbook:', content.count('hotel-management-playbook-month-end-reporting.html'))
else:
    print('Pattern not found - check file')
