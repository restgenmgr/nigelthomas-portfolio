# fix-ops-vs-restaurant-blog-and-sitemap.ps1
# 1. Fixes wrong image path in blog.html for the Operations Manager vs Restaurant Manager card
# 2. Adds the page to sitemap.xml if not already present
# Run from: C:\Users\admin\Desktop\nigelthomas-portfolio
# Usage: .\fix-ops-vs-restaurant-blog-and-sitemap.ps1

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# ---------- STEP 1: Fix blog.html image path ----------
$blogPath = Join-Path (Get-Location) "blog.html"

if (-not (Test-Path $blogPath)) {
    Write-Host "ERROR: blog.html not found in current folder. Run this from the repo root." -ForegroundColor Red
    exit 1
}

$blogContent = [System.IO.File]::ReadAllText($blogPath, [System.Text.Encoding]::UTF8)

if ($blogContent.Contains('assets/smart-menu-pricing-formula.jfif') -and $blogContent.Contains('Operations Manager vs Restaurant Manager')) {
    # Regex handles the multi-line img tag reliably regardless of exact whitespace/line breaks
    $pattern = 'src="assets/smart-menu-pricing-formula\.jfif"\s*\r?\n?\s*alt="Operations Manager vs Restaurant Manager"'
    $replacement = 'src="/assets/operations-manager-vs-restaurant-manager.jfif"' + "`r`n" + '         alt="Operations Manager vs Restaurant Manager"'

    $regex = [System.Text.RegularExpressions.Regex]::new($pattern)
    $newBlogContent = $regex.Replace($blogContent, { param($m) $replacement }, 1)

    if ($newBlogContent -eq $blogContent) {
        Write-Host "WARNING: Pattern not matched exactly - no changes made to blog.html. Manual check needed." -ForegroundColor Yellow
    } else {
        [System.IO.File]::WriteAllText($blogPath, $newBlogContent, $utf8NoBom)
        Write-Host "Fixed: blog.html image path updated to operations-manager-vs-restaurant-manager.jfif" -ForegroundColor Green
    }
} else {
    Write-Host "WARNING: Could not find the expected wrong image reference in blog.html. It may already be fixed, or the text differs. Check manually." -ForegroundColor Yellow
}

# ---------- STEP 2: Add sitemap.xml entry ----------
$sitemapPath = Join-Path (Get-Location) "sitemap.xml"

if (-not (Test-Path $sitemapPath)) {
    Write-Host "ERROR: sitemap.xml not found in current folder." -ForegroundColor Red
    exit 1
}

$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath, [System.Text.Encoding]::UTF8)

$pageUrl = "https://www.nigelthomas.live/operations-manager-vs-restaurant-manager.html"

if ($sitemapContent -match [regex]::Escape($pageUrl)) {
    Write-Host "sitemap.xml already contains this URL - no changes made." -ForegroundColor Yellow
} else {
    $today = Get-Date -Format "yyyy-MM-dd"
    $newEntry = "  <url>`r`n    <loc>$pageUrl</loc>`r`n    <lastmod>$today</lastmod>`r`n    <changefreq>monthly</changefreq>`r`n    <priority>0.8</priority>`r`n  </url>`r`n"

    if ($sitemapContent -match '</urlset>') {
        $newSitemapContent = $sitemapContent -replace '</urlset>', ($newEntry + '</urlset>')
        [System.IO.File]::WriteAllText($sitemapPath, $newSitemapContent, $utf8NoBom)
        Write-Host "Added: sitemap.xml entry for operations-manager-vs-restaurant-manager.html" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Could not find </urlset> closing tag in sitemap.xml. Manual edit needed." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  git pull --rebase origin main"
Write-Host "  git add blog.html sitemap.xml"
Write-Host "  git commit -m 'Fix blog card image and add sitemap entry for ops vs restaurant manager page'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
