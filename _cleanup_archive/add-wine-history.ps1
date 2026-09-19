$ErrorActionPreference = "Stop"

Write-Host "Step 1: Reading blog.html and sitemap.xml as UTF-8..." -ForegroundColor Cyan
$blogPath = Join-Path (Get-Location) "blog.html"
$sitemapPath = Join-Path (Get-Location) "sitemap.xml"

$blogContent = [System.IO.File]::ReadAllText($blogPath, [System.Text.Encoding]::UTF8)
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath, [System.Text.Encoding]::UTF8)

Write-Host "Step 2: Checking anchors exist before touching anything..." -ForegroundColor Cyan
$headingAnchor = '<h2 class="section-title">Featured Articles</h2>'
$sitemapAnchor = '</urlset>'

if (-not $blogContent.Contains($headingAnchor)) {
    Write-Host "ERROR: blog.html heading anchor not found. Aborting without changes." -ForegroundColor Red
    exit 1
}
if (-not $sitemapContent.Contains($sitemapAnchor)) {
    Write-Host "ERROR: sitemap.xml closing tag not found. Aborting without changes." -ForegroundColor Red
    exit 1
}
Write-Host "Both anchors found. Proceeding." -ForegroundColor Green

Write-Host "Step 3: Adding wine history card to blog.html..." -ForegroundColor Cyan
$wineCard = @'
<div class="article-card">
<span class="badge">Newest</span>
<h2 class="article-title">
<a href="/history-of-wine-world-wine-regions-guide.html">The Origin and History of Wine &amp; World Wine Growing Regions</a>
</h2>
<div class="article-meta">July 2026 &bull; 6,000+ Word Professional Guide</div>
<p>From ancient Caucasus origins to Old World France and New World Argentina &mdash; the complete history of wine, terroir, classification systems, and what every hospitality professional should know about wine service.</p>
<a class="read-more-btn" href="/history-of-wine-world-wine-regions-guide.html">Read Complete Guide &rarr;</a>
</div>

'@
$blogNew = $headingAnchor + "`n`n" + $wineCard
$blogContent = $blogContent.Replace($headingAnchor, $blogNew)

Write-Host "Step 4: Adding wine history URL to sitemap.xml..." -ForegroundColor Cyan
$sitemapEntry = @'
    <url>
        <loc>https://www.nigelthomas.live/history-of-wine-world-wine-regions-guide.html</loc>
        <lastmod>2026-07-08</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.9</priority>
    </url>
</urlset>
'@
$sitemapContent = $sitemapContent.Replace($sitemapAnchor, $sitemapEntry)

Write-Host "Step 5: Writing both files back as clean UTF-8 (no BOM)..." -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($blogPath, $blogContent, $utf8NoBom)
[System.IO.File]::WriteAllText($sitemapPath, $sitemapContent, $utf8NoBom)

Write-Host ""
Write-Host "===== VERIFICATION =====" -ForegroundColor Yellow

$check1 = Select-String -Path $blogPath -Pattern "history-of-wine-world-wine-regions-guide"
if ($check1) {
    Write-Host "PASS: blog.html contains the wine history link:" -ForegroundColor Green
    $check1 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "FAIL: blog.html link NOT found." -ForegroundColor Red
}

Write-Host ""
$check2 = Select-String -Path $sitemapPath -Pattern "history-of-wine-world-wine-regions-guide"
if ($check2) {
    Write-Host "PASS: sitemap.xml contains the wine history URL:" -ForegroundColor Green
    $check2 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "FAIL: sitemap.xml URL NOT found." -ForegroundColor Red
}

Write-Host ""
$mojibakePattern = [char]0x00E2 + [char]0x0080
$check3 = Select-String -Path $blogPath -SimpleMatch -Pattern $mojibakePattern
if ($check3) {
    Write-Host "FAIL: Mojibake detected in blog.html:" -ForegroundColor Red
    $check3 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "PASS: No mojibake in blog.html." -ForegroundColor Green
}

Write-Host ""
Write-Host "===== DONE =====" -ForegroundColor Yellow
Write-Host "If all three checks say PASS, run:"
Write-Host "  git add blog.html sitemap.xml"
Write-Host "  git commit -m 'Add wine history article to blog and sitemap'"
Write-Host "  git push origin main"
