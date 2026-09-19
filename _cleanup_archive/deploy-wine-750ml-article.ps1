# =====================================================================
# Deploy: "Why Is a Wine Bottle 750 ml?" article
# - Copies the new HTML article into the repo root
# - Adds a blog.html card
# - Adds a sitemap.xml entry
# - Commits and pushes to main (Vercel auto-deploys on push)
#
# BEFORE RUNNING:
# 1. Save this script AND why-is-a-wine-bottle-750ml.html to the SAME
#    folder (e.g. your Desktop), then edit $DownloadedArticle below if needed.
# 2. Open PowerShell, cd into that folder, then run:  .\deploy-wine-750ml-article.ps1
# 3. Double-check the four "Related Beverage Reading" links inside the
#    article HTML (classic-cocktails-guide.html, beer-guide.html,
#    types-of-water-guide.html, restaurant-kpis-financial-operational-guide.html)
#    match your ACTUAL filenames on nigelthomas.live before pushing —
#    these were my best guess from naming patterns, not confirmed filenames.
# =====================================================================

$ErrorActionPreference = "Stop"

$RepoPath          = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$DownloadedArticle = Join-Path $PSScriptRoot "why-is-a-wine-bottle-750ml.html"
$ArticleSlug       = "why-is-a-wine-bottle-750ml.html"

Write-Host "Step 1: Sanity checks..." -ForegroundColor Cyan
if (-not (Test-Path $DownloadedArticle)) {
    Write-Host "ERROR: Could not find $DownloadedArticle. Place the article HTML next to this script." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $RepoPath)) {
    Write-Host "ERROR: Repo path not found: $RepoPath" -ForegroundColor Red
    exit 1
}

Set-Location $RepoPath

Write-Host "Step 2: git pull --rebase to avoid conflicts..." -ForegroundColor Cyan
git pull --rebase

Write-Host "Step 3: Copying article into repo root..." -ForegroundColor Cyan
$destArticle = Join-Path $RepoPath $ArticleSlug
Copy-Item -Path $DownloadedArticle -Destination $destArticle -Force

Write-Host "Step 4: Reading blog.html and sitemap.xml as UTF-8..." -ForegroundColor Cyan
$blogPath     = Join-Path $RepoPath "blog.html"
$sitemapPath  = Join-Path $RepoPath "sitemap.xml"
$blogContent    = [System.IO.File]::ReadAllText($blogPath, [System.Text.Encoding]::UTF8)
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath, [System.Text.Encoding]::UTF8)

Write-Host "Step 5: Checking anchors exist before touching anything..." -ForegroundColor Cyan
$cardAnchor    = "<!-- END NEW CARD 22 -->"   # UPDATE this to your latest card marker if different
$sitemapAnchor = "</urlset>"

if (-not $blogContent.Contains($cardAnchor)) {
    Write-Host "ERROR: blog.html card anchor '$cardAnchor' not found. Open blog.html, find the LAST '<!-- END NEW CARD N -->' marker, update `$cardAnchor` in this script to match, then re-run. Aborting without changes." -ForegroundColor Red
    exit 1
}
if (-not $sitemapContent.Contains($sitemapAnchor)) {
    Write-Host "ERROR: sitemap.xml closing tag not found. Aborting without changes." -ForegroundColor Red
    exit 1
}
Write-Host "Both anchors found. Proceeding." -ForegroundColor Green

Write-Host "Step 6: Adding blog.html article card..." -ForegroundColor Cyan
$wineCard = @'
<!-- END NEW CARD 22 -->
<div class="article-card">
<span class="badge">Newest</span>
<h2 class="article-title">
<a href="/why-is-a-wine-bottle-750ml.html">Why Is a Wine Bottle 750 ml? The History Behind the Standard Size</a>
</h2>
<div class="article-meta">August 2026 &bull; 2,000+ Word Guide &bull; Poster Included</div>
<p class="article-excerpt">Litres, gallons, Bordeaux barrels and a bit of 18th-century arithmetic: the real story of how 750 ml became the world's standard wine bottle &mdash; and why it still matters for cost control and service today.</p>
<a class="read-more-btn" href="/why-is-a-wine-bottle-750ml.html">Read Complete Guide &rarr;</a>
</div>
<!-- END NEW CARD 23 -->
'@
$blogContent = $blogContent.Replace($cardAnchor, $wineCard)

Write-Host "Step 7: Adding sitemap.xml entry..." -ForegroundColor Cyan
$sitemapEntry = @'
    <url>
        <loc>https://www.nigelthomas.live/why-is-a-wine-bottle-750ml.html</loc>
        <lastmod>2026-08-23</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
    </url>
</urlset>
'@
$sitemapContent = $sitemapContent.Replace($sitemapAnchor, $sitemapEntry)

Write-Host "Step 8: Writing blog.html and sitemap.xml back as clean UTF-8 (no BOM)..." -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($blogPath, $blogContent, $utf8NoBom)
[System.IO.File]::WriteAllText($sitemapPath, $sitemapContent, $utf8NoBom)

Write-Host ""
Write-Host "===== VERIFICATION =====" -ForegroundColor Yellow

$check0 = Test-Path $destArticle
Write-Host $(if ($check0) { "PASS: article file present at $destArticle" } else { "FAIL: article file missing" }) -ForegroundColor $(if ($check0) { "Green" } else { "Red" })

$check1 = Select-String -Path $blogPath -Pattern "why-is-a-wine-bottle-750ml"
Write-Host $(if ($check1) { "PASS: blog.html contains the article link." } else { "FAIL: blog.html link NOT found." }) -ForegroundColor $(if ($check1) { "Green" } else { "Red" })

$check2 = Select-String -Path $sitemapPath -Pattern "why-is-a-wine-bottle-750ml"
Write-Host $(if ($check2) { "PASS: sitemap.xml contains the article URL." } else { "FAIL: sitemap.xml URL NOT found." }) -ForegroundColor $(if ($check2) { "Green" } else { "Red" })

$mojibakePattern = [char]0x00E2 + [char]0x0080
$check3 = Select-String -Path $blogPath -SimpleMatch -Pattern $mojibakePattern
Write-Host $(if (-not $check3) { "PASS: No mojibake in blog.html." } else { "FAIL: Mojibake detected in blog.html." }) -ForegroundColor $(if (-not $check3) { "Green" } else { "Red" })

$check4 = Select-String -Path $destArticle -SimpleMatch -Pattern $mojibakePattern
Write-Host $(if (-not $check4) { "PASS: No mojibake in article HTML." } else { "FAIL: Mojibake detected in article HTML." }) -ForegroundColor $(if (-not $check4) { "Green" } else { "Red" })

Write-Host ""
Write-Host "===== NEXT STEPS =====" -ForegroundColor Yellow
Write-Host "If all checks PASS, review, then run:"
Write-Host "  git add why-is-a-wine-bottle-750ml.html blog.html sitemap.xml"
Write-Host "  git commit -m 'Add: Why Is a Wine Bottle 750 ml article, poster, blog card, sitemap entry'"
Write-Host "  git push origin main"
Write-Host ""
Write-Host "Vercel will auto-deploy on push (usually ~11-30 seconds)."
Write-Host "Live URL once deployed: https://www.nigelthomas.live/why-is-a-wine-bottle-750ml.html"
Write-Host ""
Write-Host "Then submit for indexing in Google Search Console:"
Write-Host "  URL Inspection -> paste the URL above -> Request Indexing"
