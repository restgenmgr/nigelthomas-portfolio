# ============================================================
# deploy-pos-systems-article.ps1
# Adds restaurant-hotel-pos-systems.html to the site:
#   1. Locates the downloaded HTML file (handles (1) suffixes)
#   2. Copies it into the repo
#   3. Inserts a blog card into blog.html
#   4. Inserts a sitemap entry into sitemap.xml
#   5. git pull --rebase / add / commit / push
#   6. vercel --prod --force
#   7. Verifies the live URL with Invoke-WebRequest
# ============================================================

$ErrorActionPreference = "Stop"

$repoPath   = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads  = "$env:USERPROFILE\Downloads"
$targetName = "restaurant-hotel-pos-systems.html"

Write-Host "=== Step 0: Pre-flight check on repo state ===" -ForegroundColor Cyan
Set-Location $repoPath
git status
Write-Host "If you see uncommitted changes above (e.g. fire-safety-training-blog.html or restaurant-walkthrough-poster.html), resolve those before continuing." -ForegroundColor Yellow
Write-Host "Press Enter to continue once the working tree is clean, or Ctrl+C to stop." -ForegroundColor Yellow
Read-Host

# ------------------------------------------------------------
# Step 1: Locate the downloaded file (handles "(1)" suffixes)
# ------------------------------------------------------------
Write-Host "`n=== Step 1: Locating downloaded file ===" -ForegroundColor Cyan
$candidates = Get-ChildItem -Path $downloads -Filter "restaurant-hotel-pos-systems*.html" |
              Sort-Object LastWriteTime -Descending

if (-not $candidates) {
    Write-Host "No matching file found in $downloads. Save restaurant-hotel-pos-systems.html there first, then re-run this script." -ForegroundColor Red
    exit 1
}

$sourceFile = $candidates[0].FullName
Write-Host "Using: $sourceFile"

# ------------------------------------------------------------
# Step 2: Copy into repo
# ------------------------------------------------------------
Write-Host "`n=== Step 2: Copying into repo ===" -ForegroundColor Cyan
$destFile = Join-Path $repoPath $targetName
Copy-Item -Path $sourceFile -Destination $destFile -Force
Write-Host "Copied to $destFile"

# ------------------------------------------------------------
# Step 3: Insert blog card into blog.html
# ------------------------------------------------------------
Write-Host "`n=== Step 3: Updating blog.html ===" -ForegroundColor Cyan
$blogPath = Join-Path $repoPath "blog.html"
$blogContent = [System.IO.File]::ReadAllText($blogPath)

$newCard = @"
        <div class="article-card">
            <div class="article-title"><a href="/restaurant-hotel-pos-systems.html">POS Systems for Restaurants &amp; Hotels in India: The Complete Comparison</a></div>
            <div class="article-meta"><span class="badge badge-gold">Newest</span> Restaurant Operations &middot; Hotel Technology &middot; August 2026</div>
            <p class="article-excerpt">A field comparison of the top 5 restaurant POS platforms and top 5 hotel POS/PMS systems used in India &mdash; advantages, disadvantages, pricing, FOH &amp; BOH benefits, and offline vs online capability.</p>
            <a href="/restaurant-hotel-pos-systems.html" class="read-more-btn">Read Article &rarr;</a>
        </div>

        <div class="article-card">
            <div class="article-title"><a href="/hotel-management-playbook-month-end-reporting.html">Hotel Management Playbook - Month-End Reporting Secrets of Top Hotels</a></div>
"@

$anchor = @"
        <div class="article-card">
            <div class="article-title"><a href="/hotel-management-playbook-month-end-reporting.html">Hotel Management Playbook - Month-End Reporting Secrets of Top Hotels</a></div>
"@

if ($blogContent -notmatch [regex]::Escape($anchor.Trim())) {
    Write-Host "Anchor text for blog.html insertion not found. Aborting blog.html edit to avoid corrupting the file." -ForegroundColor Red
    exit 1
}

$blogContent = $blogContent.Replace($anchor, $newCard)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($blogPath, $blogContent, $utf8NoBom)
Write-Host "blog.html updated."

# ------------------------------------------------------------
# Step 4: Insert sitemap entry into sitemap.xml
# ------------------------------------------------------------
Write-Host "`n=== Step 4: Updating sitemap.xml ===" -ForegroundColor Cyan
$sitemapPath = Join-Path $repoPath "sitemap.xml"
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath)

$today = Get-Date -Format "yyyy-MM-dd"

$newUrlEntry = @"
    <url>
        <loc>https://www.nigelthomas.live/restaurant-hotel-pos-systems.html</loc>
        <lastmod>$today</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
    </url>
</urlset>
"@

if ($sitemapContent -notmatch "</urlset>") {
    Write-Host "Could not find closing </urlset> tag in sitemap.xml. Aborting sitemap edit." -ForegroundColor Red
    exit 1
}

$sitemapContent = $sitemapContent.Replace("</urlset>", $newUrlEntry)

[System.IO.File]::WriteAllText($sitemapPath, $sitemapContent, $utf8NoBom)
Write-Host "sitemap.xml updated."

# ------------------------------------------------------------
# Step 5: Git pull / add / commit / push
# ------------------------------------------------------------
Write-Host "`n=== Step 5: Git pull --rebase ===" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "`n=== Step 6: Git add / commit / push ===" -ForegroundColor Cyan
git add restaurant-hotel-pos-systems.html blog.html sitemap.xml
git commit -m "feat(blog): add restaurant & hotel POS systems comparison article, update blog index and sitemap"
git push origin main

# ------------------------------------------------------------
# Step 6: Deploy to Vercel
# ------------------------------------------------------------
Write-Host "`n=== Step 7: Deploying to Vercel ===" -ForegroundColor Cyan
vercel --prod --force

# ------------------------------------------------------------
# Step 7: Verify live URLs
# ------------------------------------------------------------
Write-Host "`n=== Step 8: Verifying live pages ===" -ForegroundColor Cyan
Start-Sleep -Seconds 8

$urlsToCheck = @(
    "https://www.nigelthomas.live/restaurant-hotel-pos-systems.html",
    "https://www.nigelthomas.live/blog.html",
    "https://www.nigelthomas.live/sitemap.xml"
)

foreach ($url in $urlsToCheck) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
        Write-Host "$($response.StatusCode)  $url" -ForegroundColor Green
    } catch {
        Write-Host "FAILED  $url  -->  $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
