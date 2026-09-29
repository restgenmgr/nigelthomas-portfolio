# ONE-SHOT-UPLOAD-MISE-EN-PLACE-VS-SCENE.ps1
# Deploys restaurant-mis-en-plas.html + poster asset, updates blog.html and sitemap.xml
# Run from inside your local repo folder, e.g.:
#   cd C:\Users\admin\Desktop\nigelthomas-portfolio
#   powershell -ExecutionPolicy Bypass -File .\ONE-SHOT-UPLOAD-MISE-EN-PLACE-VS-SCENE.ps1

$ErrorActionPreference = "Stop"
$repo = Get-Location

function Write-Utf8NoBom($path, $content) {
    $full = Join-Path $repo $path
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($full, $content, $enc)
}

Write-Host "Step 1: git pull --rebase (sync before editing)" -ForegroundColor Yellow
git pull --rebase --autostash

Write-Host "Step 2: Confirm required source files are present in this folder" -ForegroundColor Yellow
$required = @(
    "restaurant-mis-en-plas.html",
    "mise-en-place-vs-scene.jpg"
)
foreach ($f in $required) {
    $p = Join-Path $repo $f
    if (-not (Test-Path $p)) {
        Write-Host "MISSING: $f -- place it in $repo before running this script." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Step 3: Move poster into assets/" -ForegroundColor Yellow
$assetsDir = Join-Path $repo "assets"
if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }
Move-Item -Path (Join-Path $repo "mise-en-place-vs-scene.jpg") -Destination (Join-Path $assetsDir "mise-en-place-vs-scene.jpg") -Force
if (-not (Test-Path (Join-Path $assetsDir "mise-en-place-vs-scene.jpg"))) {
    Write-Host "Move to assets/ failed." -ForegroundColor Red
    exit 1
}

Write-Host "Step 4: restaurant-mis-en-plas.html is already at repo root -- confirmed" -ForegroundColor Yellow

Write-Host "Step 5: Insert card into blog.html" -ForegroundColor Yellow
$blogPath = Join-Path $repo "blog.html"
$blogContent = Get-Content $blogPath -Raw -Encoding UTF8

$cardHtml = @"
<!-- NEW CARD: Mise en Place vs Mise en Scene -->
<div class="article-card">
  <img src="assets/mise-en-place-vs-scene.jpg" alt="Mise en Place vs Mise en Scène" loading="lazy">
  <div class="article-title">Mise en Place vs Mise en Scène</div>
  <div class="article-meta">Hospitality Terminology Series &middot; Part 22</div>
  <div class="article-excerpt">Two disciplines, one goal: an exceptional guest experience. What each term really means, where restaurants get it wrong, and how to train both into your pre-service routine.</div>
  <a class="read-more-btn" href="restaurant-mis-en-plas.html">Read More</a>
</div>
<!-- END NEW CARD -->
"@

$markers = [regex]::Matches($blogContent, "<!-- END NEW CARD.*?-->")
if ($markers.Count -gt 0) {
    $lastMarker = $markers[$markers.Count - 1]
    $insertAt = $lastMarker.Index + $lastMarker.Length
    $newBlogContent = $blogContent.Substring(0, $insertAt) + "`r`n" + $cardHtml + $blogContent.Substring($insertAt)
} else {
    Write-Host "No END NEW CARD marker found -- appending before closing </body> as fallback." -ForegroundColor Red
    $newBlogContent = $blogContent -replace "</body>", ($cardHtml + "`r`n</body>")
}
Write-Utf8NoBom "blog.html" $newBlogContent

Write-Host "Step 6: Insert entry into sitemap.xml" -ForegroundColor Yellow
$sitemapPath = Join-Path $repo "sitemap.xml"
$sitemapContent = Get-Content $sitemapPath -Raw -Encoding UTF8

$sitemapEntry = @"
  <url>
    <loc>https://www.nigelthomas.live/restaurant-mis-en-plas.html</loc>
    <lastmod>2026-09-23</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
"@

if ($sitemapContent -match "</urlset>") {
    $newSitemapContent = $sitemapContent -replace "</urlset>", ($sitemapEntry + "`r`n</urlset>")
    Write-Utf8NoBom "sitemap.xml" $newSitemapContent
} else {
    Write-Host "No </urlset> tag found in sitemap.xml -- please add the entry manually." -ForegroundColor Red
}

Write-Host "Step 7: git add / commit / push" -ForegroundColor Yellow
git add restaurant-mis-en-plas.html assets/mise-en-place-vs-scene.jpg blog.html sitemap.xml
git commit -m "Add Mise en Place vs Mise en Scene poster/article page (Hospitality Terminology Series Part 22)"
git pull --rebase --autostash
git push

Write-Host "Step 8: Verify live deployment (allow Vercel a minute to build)" -ForegroundColor Yellow
Start-Sleep -Seconds 45
try {
    $resp = Invoke-WebRequest -Uri "https://www.nigelthomas.live/restaurant-mis-en-plas.html" -UseBasicParsing
    Write-Host "Page status: $($resp.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Could not verify yet -- check manually in a minute: https://www.nigelthomas.live/restaurant-mis-en-plas.html" -ForegroundColor Red
}

Write-Host "DONE. Page: https://www.nigelthomas.live/restaurant-mis-en-plas.html" -ForegroundColor Green
