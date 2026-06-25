# ============================================================
# Add Equal Opportunity Employer + Cruise Lines articles
# Sitemap update -> git commit -> push -> Vercel deploy
# Run from C:\Users\admin\Desktop\clean-repo
# ============================================================

cd C:\Users\admin\Desktop\clean-repo

# ----------------------------------------------------------------
# STEP 1 — Create the two new folders (only if they don't exist yet)
# ----------------------------------------------------------------
New-Item -ItemType Directory -Path ".\workplace-compliance" -Force
New-Item -ItemType Directory -Path ".\cruise-careers" -Force

# ----------------------------------------------------------------
# STEP 2 — Copy the two article files into their folders
# (adjust the source path below to wherever you saved the
#  downloaded HTML files, e.g. Downloads)
# ----------------------------------------------------------------
Copy-Item "$HOME\Downloads\equal-opportunity-employer-india-usa-europe.html" `
    -Destination ".\workplace-compliance\equal-opportunity-employer-india-usa-europe.html" -Force

Copy-Item "$HOME\Downloads\not-all-cruise-lines-are-created-equal.html" `
    -Destination ".\cruise-careers\not-all-cruise-lines-are-created-equal.html" -Force

# ----------------------------------------------------------------
# STEP 3 — Update sitemap.xml (same pattern as your existing script)
# ----------------------------------------------------------------
$sitemap = Get-Content sitemap.xml -Raw

$newUrls = @'
    <url><loc>https://www.nigelthomas.live/workplace-compliance/equal-opportunity-employer-india-usa-europe.html</loc><lastmod>2026-06-21</lastmod><changefreq>monthly</changefreq><priority>0.8</priority></url>
    <url><loc>https://www.nigelthomas.live/cruise-careers/not-all-cruise-lines-are-created-equal.html</loc><lastmod>2026-06-21</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>
'@

$sitemap = $sitemap -replace '(</urlset>)', "$newUrls`n`$1"
$sitemap | Out-File -FilePath sitemap.xml -Encoding utf8

# ----------------------------------------------------------------
# STEP 4 — Add the two new cards into blog.html
# This appends a <a> "Read Article" link pattern matching your
# existing ones. If blog.html uses a card wrapper per article
# (like the food-safety/regional-food sections), you'll likely
# want to paste a full card block rather than just a link —
# see blog-featured-section.html for the matching card markup.
# Open blog.html manually and paste the relevant <div class="...">
# block from blog-featured-section.html where you want each card
# to appear, OR uncomment and adjust the lines below if you just
# need to insert raw links at a known anchor point.
# ----------------------------------------------------------------
# $blog = Get-Content blog.html -Raw
# $newLinks = @'
#                 <a href="/workplace-compliance/equal-opportunity-employer-india-usa-europe.html" class="btn-read">Read Article →</a>
#                 <a href="/cruise-careers/not-all-cruise-lines-are-created-equal.html" class="btn-read">Read Article →</a>
# '@
# $blog = $blog -replace '(<a href="/culinary/mother-sauces-complete-guide.html" class="btn-read">Read Article →</a>)', "`$1`n$newLinks"
# $blog | Out-File -FilePath blog.html -Encoding utf8

# ----------------------------------------------------------------
# STEP 5 — Git commit & push
# ----------------------------------------------------------------
git add sitemap.xml workplace-compliance cruise-careers blog.html
git commit -m "Add Equal Opportunity Employer and Cruise Lines articles + sitemap update"
git push origin main

# ----------------------------------------------------------------
# STEP 6 — Deploy to Vercel
# ----------------------------------------------------------------
npx vercel --prod --force

Write-Host "Sitemap and site updated with 2 new articles" -ForegroundColor Green
