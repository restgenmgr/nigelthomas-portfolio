# =====================================================================
# Deploy: 10 Stuffed & Filled Foods poster page
# Repo:   restgenmgr/nigelthomas-portfolio
# Files added/changed:
#   assets/food-stuffed.jpg
#   blog/stuffed-filled-foods-around-the-world.html
#   blog.html            (new card inserted)
#   sitemap.xml          (new <url> entry inserted)
# =====================================================================

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repoPath

# ---- 0. Always rebase-pull first (mixed web UI / local edit workflow) ----
git pull --rebase

# ---- 1. Place the two new files (adjust source paths to where you saved them) ----
$downloads = "$env:USERPROFILE\Downloads"

$posterSrc = Join-Path $downloads "food-stuffed.jpg"
$pageSrc   = Join-Path $downloads "stuffed-filled-foods-around-the-world.html"

$posterDest = Join-Path $repoPath "assets\food-stuffed.jpg"
$pageDest   = Join-Path $repoPath "blog\stuffed-filled-foods-around-the-world.html"

if (Test-Path $posterSrc) {
    Copy-Item $posterSrc $posterDest -Force
    if (-not (Test-Path $posterDest)) { throw "Poster copy failed: $posterDest" }
    Write-Host "Poster placed at $posterDest" -ForegroundColor Green
} else {
    Write-Warning "Poster not found at $posterSrc - place it manually at $posterDest before continuing."
}

if (Test-Path $pageSrc) {
    Copy-Item $pageSrc $pageDest -Force
    if (-not (Test-Path $pageDest)) { throw "Page copy failed: $pageDest" }
    Write-Host "Page placed at $pageDest" -ForegroundColor Green
} else {
    Write-Warning "Page not found at $pageSrc - place it manually at $pageDest before continuing."
}

# ---- 2. Insert the new blog.html card (BOM-free UTF-8 write) ----
$blogPath = Join-Path $repoPath "blog.html"
$blogContent = [System.IO.File]::ReadAllText($blogPath)

$cardHtml = @"
<div class="article-card">
  <img src="assets/food-stuffed.jpg" alt="10 stuffed and filled foods from around the world poster" loading="lazy">
  <div class="article-title">10 Stuffed &amp; Filled Foods From Around the World</div>
  <div class="article-meta">Global Cuisine &bull; Menu Knowledge</div>
  <p class="article-excerpt">A hospitality executive's field guide to momo, gyoza, manti, ravioli, wonton, samosa, pierogi, chimaki and empanada.</p>
  <a href="blog/stuffed-filled-foods-around-the-world.html" class="read-more-btn">Read More</a>
</div>
<!-- END NEW CARD -->
"@

if ($blogContent -match [regex]::Escape("stuffed-filled-foods-around-the-world.html")) {
    Write-Host "blog.html already references this page - skipping card insert." -ForegroundColor Yellow
} else {
    $marker = "<!-- END NEW CARD 101 -->"   # update to the actual last marker number in blog.html before running
    if ($blogContent -notmatch [regex]::Escape($marker)) {
        throw "Marker '$marker' not found in blog.html - open the file, find the LAST '<!-- END NEW CARD N -->' comment, and update `$marker` in this script to match."
    }
    $newContent = $blogContent -replace [regex]::Escape($marker), ($marker + "`r`n" + $cardHtml)
    [System.IO.File]::WriteAllText($blogPath, $newContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "blog.html updated." -ForegroundColor Green
}

# ---- 3. Insert the sitemap.xml entry (BOM-free UTF-8 write) ----
$sitemapPath = Join-Path $repoPath "sitemap.xml"
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath)

$today = Get-Date -Format "yyyy-MM-dd"
$urlEntry = @"
  <url>
    <loc>https://www.nigelthomas.live/blog/stuffed-filled-foods-around-the-world.html</loc>
    <lastmod>$today</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
"@

if ($sitemapContent -match [regex]::Escape("stuffed-filled-foods-around-the-world.html")) {
    Write-Host "sitemap.xml already contains this URL - skipping." -ForegroundColor Yellow
} else {
    $newSitemap = $sitemapContent -replace "</urlset>", ($urlEntry + "`r`n</urlset>")
    [System.IO.File]::WriteAllText($sitemapPath, $newSitemap, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "sitemap.xml updated." -ForegroundColor Green
}

# ---- 4. Stage, commit, pull --rebase again, push ----
git add "assets/food-stuffed.jpg" "blog/stuffed-filled-foods-around-the-world.html" "blog.html" "sitemap.xml"
git status
git commit -m "Add: 10 Stuffed & Filled Foods poster page, blog card, sitemap entry"
git pull --rebase
git push

# ---- 5. Verify live on Vercel (GET, not HEAD, plus content match) ----
Start-Sleep -Seconds 20   # give Vercel a moment to build/deploy

$pageUrl   = "https://www.nigelthomas.live/blog/stuffed-filled-foods-around-the-world.html"
$posterUrl = "https://www.nigelthomas.live/assets/food-stuffed.jpg"

$pageResp = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing
if ($pageResp.StatusCode -eq 200 -and $pageResp.Content -match "10 Stuffed") {
    Write-Host "PAGE LIVE: $pageUrl" -ForegroundColor Green
} else {
    Write-Warning "Page did not verify as expected: $pageUrl (status $($pageResp.StatusCode))"
}

$posterResp = Invoke-WebRequest -Uri $posterUrl -UseBasicParsing
if ($posterResp.StatusCode -eq 200 -and $posterResp.Headers["Content-Type"] -match "image") {
    Write-Host "POSTER LIVE: $posterUrl" -ForegroundColor Green
} else {
    Write-Warning "Poster did not verify as expected: $posterUrl (status $($posterResp.StatusCode))"
}

Write-Host "`nDone. Submit the page + image URL in Google Search Console > URL Inspection > Request Indexing." -ForegroundColor Cyan
