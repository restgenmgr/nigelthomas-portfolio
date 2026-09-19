$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repoPath

# 0. Sync first
git pull --rebase

# 1. Place the two new files directly into their correct folders
#    (edit $downloads if your browser saves elsewhere)
$downloads  = "$env:USERPROFILE\Downloads"
$posterSrc  = Join-Path $downloads "shake-vs-smoothie.jpg"
$pageSrc    = Join-Path $downloads "shake-vs-smoothie.html"
$posterDest = Join-Path $repoPath "assets\shake-vs-smoothie.jpg"
$pageDest   = Join-Path $repoPath "blog\shake-vs-smoothie.html"

if (-not (Test-Path $posterSrc)) { throw "Poster not found at $posterSrc - download it first." }
if (-not (Test-Path $pageSrc))   { throw "Page not found at $pageSrc - download it first." }

Copy-Item $posterSrc $posterDest -Force
Copy-Item $pageSrc $pageDest -Force

if (-not (Test-Path $posterDest)) { throw "Poster copy failed: $posterDest" }
if (-not (Test-Path $pageDest))   { throw "Page copy failed: $pageDest" }

Write-Host "Poster placed: $posterDest" -ForegroundColor Green
Write-Host "Page placed:   $pageDest" -ForegroundColor Green

# 2. Insert blog.html card - find the LAST "END NEW CARD" line by line number
#    (numbers in this file are non-sequential/duplicated, so match by position, not text)
$blogPath = Join-Path $repoPath "blog.html"
$blogContent = [System.IO.File]::ReadAllText($blogPath)

if ($blogContent -match [regex]::Escape("shake-vs-smoothie.html")) {
    Write-Host "blog.html already references this page - skipped." -ForegroundColor Yellow
} else {
    $lines = [System.IO.File]::ReadAllLines($blogPath)
    $lastMarkerIndex = ($lines | Select-String "END NEW CARD" | Select-Object -Last 1).LineNumber - 1
    if (-not $lastMarkerIndex) { throw "No 'END NEW CARD' marker found in blog.html - insert the card manually." }
    Write-Host "Last marker found at line $($lastMarkerIndex + 1): $($lines[$lastMarkerIndex])"

    $cardLines = @(
        '<div class="article-card">'
        '  <img src="assets/shake-vs-smoothie.jpg" alt="Shake vs smoothie comparison poster" loading="lazy">'
        '  <div class="article-title">Shake vs Smoothie: What''s Really the Difference?</div>'
        '  <div class="article-meta">Beverage Menu &bull; F&amp;B Knowledge</div>'
        '  <p class="article-excerpt">Same look, different ingredients - a hospitality guide to telling shakes and smoothies apart and menu-positioning both correctly.</p>'
        '  <a href="blog/shake-vs-smoothie.html" class="read-more-btn">Read More</a>'
        '</div>'
        '<!-- END NEW CARD 103 -->'
    )

    $newLines = @()
    $newLines += $lines[0..$lastMarkerIndex]
    $newLines += $cardLines
    if ($lastMarkerIndex -lt $lines.Count - 1) {
        $newLines += $lines[($lastMarkerIndex + 1)..($lines.Count - 1)]
    }
    [System.IO.File]::WriteAllText($blogPath, ($newLines -join "`r`n"), (New-Object System.Text.UTF8Encoding $false))
    Write-Host "blog.html updated - card inserted after line $($lastMarkerIndex + 1)." -ForegroundColor Green
}

# 3. Insert sitemap.xml entry
$sitemapPath = Join-Path $repoPath "sitemap.xml"
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath)
$today = Get-Date -Format "yyyy-MM-dd"

if ($sitemapContent -match [regex]::Escape("shake-vs-smoothie.html")) {
    Write-Host "sitemap.xml already has this URL - skipped." -ForegroundColor Yellow
} else {
    $urlLines = @(
        '  <url>'
        '    <loc>https://www.nigelthomas.live/blog/shake-vs-smoothie.html</loc>'
        "    <lastmod>$today</lastmod>"
        '    <changefreq>monthly</changefreq>'
        '    <priority>0.7</priority>'
        '  </url>'
    )
    $urlEntry = ($urlLines -join "`r`n")
    $newSitemap = $sitemapContent -replace "</urlset>", ($urlEntry + "`r`n</urlset>")
    [System.IO.File]::WriteAllText($sitemapPath, $newSitemap, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "sitemap.xml updated." -ForegroundColor Green
}

# 4. Verify what changed before committing
git diff --stat blog.html sitemap.xml
git status

# 5. Stage, commit, sync, push - ALL via git CLI, no web upload involved
git add "assets/shake-vs-smoothie.jpg" "blog/shake-vs-smoothie.html" "blog.html" "sitemap.xml"
git status
git commit -m "Add: Shake vs Smoothie poster page, blog card, sitemap entry"
git pull --rebase
git push

# 6. Verify live
Start-Sleep -Seconds 20
$pageUrl   = "https://www.nigelthomas.live/blog/shake-vs-smoothie.html"
$posterUrl = "https://www.nigelthomas.live/assets/shake-vs-smoothie.jpg"

$pageResp = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing
if ($pageResp.StatusCode -eq 200 -and $pageResp.Content -match "Shake vs Smoothie") {
    Write-Host "PAGE LIVE: $pageUrl" -ForegroundColor Green
} else {
    Write-Warning "Page check failed: $pageUrl (status $($pageResp.StatusCode))"
}

$posterResp = Invoke-WebRequest -Uri $posterUrl -UseBasicParsing
if ($posterResp.StatusCode -eq 200 -and $posterResp.Headers["Content-Type"] -match "image") {
    Write-Host "POSTER LIVE: $posterUrl" -ForegroundColor Green
} else {
    Write-Warning "Poster check failed: $posterUrl (status $($posterResp.StatusCode))"
}

Write-Host "`nDone. Submit both URLs in GSC > URL Inspection > Request Indexing." -ForegroundColor Cyan
