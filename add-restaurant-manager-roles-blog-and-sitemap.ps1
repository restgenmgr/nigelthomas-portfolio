# add-restaurant-manager-roles-blog-and-sitemap.ps1
# 1. Adds a new article card to blog.html for the Restaurant Manager Roles & Responsibilities page
# 2. Adds the page to sitemap.xml if not already present
# Run from: C:\Users\admin\Desktop\nigelthomas-portfolio
# Usage: .\add-restaurant-manager-roles-blog-and-sitemap.ps1

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# ---------- STEP 1: Add blog.html card ----------
$blogPath = Join-Path (Get-Location) "blog.html"

if (-not (Test-Path $blogPath)) {
    Write-Host "ERROR: blog.html not found in current folder. Run this from the repo root." -ForegroundColor Red
    exit 1
}

$blogContent = [System.IO.File]::ReadAllText($blogPath, [System.Text.Encoding]::UTF8)

$pageUrl = "/restaurant-manager-roles-and-responsibilities.html"

if ($blogContent.Contains($pageUrl)) {
    Write-Host "blog.html already contains a card for this page - no changes made." -ForegroundColor Yellow
} else {
    $newCard = @"
        <div class="article-card">
            <img src="assets/roles-responsibilities-restaurant-manager.jfif" alt="Restaurant Manager Roles and Responsibilities infographic" loading="lazy">
            <div class="article-title"><a href="/restaurant-manager-roles-and-responsibilities.html">Restaurant Manager Roles &amp; Responsibilities: The Complete Guide</a></div>
            <div class="article-meta"><span class="badge badge-gold">Newest</span> Restaurant Operations &middot; Leadership &middot; August 2026</div>
            <p class="article-excerpt">Operations management, team leadership, guest experience, compliance and safety, and financial and business management &mdash; the five core pillars of the Restaurant Manager role, broken down.</p>
            <a href="/restaurant-manager-roles-and-responsibilities.html" class="read-more-btn">Read Article &rarr;</a>
        </div>

"@

    # Insert right after the "Featured Articles" section title so it appears near the top
    $anchor = '<h2 class="section-title">Featured Articles</h2>'

    if ($blogContent.Contains($anchor)) {
        $newBlogContent = $blogContent.Replace($anchor, $anchor + "`r`n`r`n" + $newCard)
        [System.IO.File]::WriteAllText($blogPath, $newBlogContent, $utf8NoBom)
        Write-Host "Added: blog.html card for Restaurant Manager Roles and Responsibilities" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Could not find the Featured Articles anchor in blog.html. Manual insertion needed." -ForegroundColor Yellow
    }
}

# ---------- STEP 2: Add sitemap.xml entry ----------
$sitemapPath = Join-Path (Get-Location) "sitemap.xml"

if (-not (Test-Path $sitemapPath)) {
    Write-Host "ERROR: sitemap.xml not found in current folder." -ForegroundColor Red
    exit 1
}

$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath, [System.Text.Encoding]::UTF8)

$fullUrl = "https://www.nigelthomas.live/restaurant-manager-roles-and-responsibilities.html"

if ($sitemapContent.Contains($fullUrl)) {
    Write-Host "sitemap.xml already contains this URL - no changes made." -ForegroundColor Yellow
} else {
    $today = Get-Date -Format "yyyy-MM-dd"
    $newEntry = "  <url>`r`n    <loc>$fullUrl</loc>`r`n    <lastmod>$today</lastmod>`r`n    <changefreq>monthly</changefreq>`r`n    <priority>0.8</priority>`r`n  </url>`r`n"

    if ($sitemapContent -match '</urlset>') {
        $newSitemapContent = $sitemapContent -replace '</urlset>', ($newEntry + '</urlset>')
        [System.IO.File]::WriteAllText($sitemapPath, $newSitemapContent, $utf8NoBom)
        Write-Host "Added: sitemap.xml entry for restaurant-manager-roles-and-responsibilities.html" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Could not find </urlset> closing tag in sitemap.xml. Manual edit needed." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  git diff blog.html sitemap.xml"
Write-Host "  git add blog.html sitemap.xml"
Write-Host "  git commit -m 'Add blog card and sitemap entry for restaurant manager roles page'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
