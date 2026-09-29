# ONE-SHOT-UPLOAD-ITALIAN-PASTA-RECIPES.ps1
# Locates italian-pasta-recipes.html + .jpg (repo root or Downloads),
# moves JPG into assets/, inserts blog.html card + sitemap.xml entry
# (skips insert if already present), commits, pushes, verifies.

$ErrorActionPreference = "Stop"

$repoPath   = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads  = Join-Path $env:USERPROFILE "Downloads"
$pageName   = "italian-pasta-recipes.html"
$posterName = "italian-pasta-recipes.jpg"
$pageUrl    = "https://www.nigelthomas.live/$pageName"
$posterUrl  = "https://www.nigelthomas.live/assets/$posterName"

Set-Location $repoPath

Write-Host "STEP 1: git pull --rebase --autostash" -ForegroundColor Yellow
git pull --rebase --autostash

function Find-File($name) {
    $candidates = @(
        (Join-Path $repoPath $name),
        (Join-Path $downloads $name)
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

Write-Host "STEP 2: Locating source files" -ForegroundColor Yellow
$htmlSrc = Find-File $pageName
$jpgSrc  = Find-File $posterName

if (-not $htmlSrc) { throw "Could not find $pageName in repo root or Downloads." }
if (-not $jpgSrc)  { throw "Could not find $posterName in repo root or Downloads." }

Write-Host "  HTML found at: $htmlSrc" -ForegroundColor Yellow
Write-Host "  JPG  found at: $jpgSrc" -ForegroundColor Yellow

$htmlDest = Join-Path $repoPath $pageName
if ((Resolve-Path $htmlSrc).Path -ne (Resolve-Path $htmlDest -ErrorAction SilentlyContinue).Path) {
    if (Test-Path $htmlDest) { Remove-Item $htmlDest -Force }
    Move-Item -Path $htmlSrc -Destination $htmlDest -Force
    Write-Host "  Moved HTML to repo root." -ForegroundColor Yellow
}

$assetsDir = Join-Path $repoPath "assets"
if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }
$jpgDest = Join-Path $assetsDir $posterName
if ((Resolve-Path $jpgSrc).Path -ne (Resolve-Path $jpgDest -ErrorAction SilentlyContinue).Path) {
    if (Test-Path $jpgDest) { Remove-Item $jpgDest -Force }
    Move-Item -Path $jpgSrc -Destination $jpgDest -Force
    Write-Host "  Moved JPG to assets/." -ForegroundColor Yellow
}

if (-not (Test-Path $htmlDest)) { throw "HTML missing at destination after move." }
if (-not (Test-Path $jpgDest))  { throw "JPG missing at destination after move." }

# ---- blog.html: insert "Newest"-badge card, skip if already present ----
Write-Host "STEP 3: Updating blog.html" -ForegroundColor Yellow
$blogPath = Join-Path $repoPath "blog.html"
$blogContent = [System.IO.File]::ReadAllText($blogPath)

if ($blogContent -notmatch [regex]::Escape($pageName)) {
    $newCard = @"
<div class="article-card">
  <div class="article-title">5 Classic Italian Pasta Recipes <span class="badge">Newest</span></div>
  <div class="article-meta">F&amp;B Tips Guide &middot; Recipe Series</div>
  <div class="article-excerpt">Five restaurant-quality Italian pasta recipes with full ingredients, method and chef's tips: Truffle Mushroom Tagliatelle, Creamy Garlic Shrimp Linguine, Classic Beef Rag&ugrave; Pappardelle, Spicy Tomato &amp; Burrata Rigatoni, and Lemon Parmesan Chicken Fettuccine.</div>
  <a class="read-more-btn" href="$pageName">Read Article &rarr;</a>
</div>
"@
    $cardPattern = '(?s)<div class="article-card">.*?<a class="read-more-btn"[^>]*>Read Article.*?</a>\s*</div>'
    $cardMatches = [regex]::Matches($blogContent, $cardPattern)
    if ($cardMatches.Count -eq 0) {
        throw "No existing 'Newest'-badge article-card blocks found in blog.html - manual insert needed."
    }
    $lastMatch = $cardMatches[$cardMatches.Count - 1]
    $insertAt = $lastMatch.Index + $lastMatch.Length
    $blogContent = $blogContent.Insert($insertAt, "`r`n" + $newCard)
    [System.IO.File]::WriteAllText($blogPath, $blogContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  Card inserted." -ForegroundColor Yellow
} else {
    Write-Host "  blog.html already references $pageName - skipped." -ForegroundColor Yellow
}

# ---- sitemap.xml: insert URL entry, skip if already present ----
Write-Host "STEP 4: Updating sitemap.xml" -ForegroundColor Yellow
$sitemapPath = Join-Path $repoPath "sitemap.xml"
$sitemapContent = [System.IO.File]::ReadAllText($sitemapPath)

if ($sitemapContent -notmatch [regex]::Escape($pageUrl)) {
    $today = Get-Date -Format "yyyy-MM-dd"
    $newUrlEntry = @"
  <url>
    <loc>$pageUrl</loc>
    <lastmod>$today</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
"@
    $sitemapContent = $sitemapContent -replace '</urlset>', ($newUrlEntry + "`r`n</urlset>")
    [System.IO.File]::WriteAllText($sitemapPath, $sitemapContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  Entry inserted." -ForegroundColor Yellow
} else {
    Write-Host "  sitemap.xml already references $pageUrl - skipped." -ForegroundColor Yellow
}

# ---- commit and push ----
Write-Host "STEP 5: git add / commit / push" -ForegroundColor Yellow
git add -A
git commit -m "Add 5 Classic Italian Pasta Recipes poster/article page"
git push

# ---- verify ----
Write-Host "STEP 6: Verifying live deployment (waiting 30s for Vercel build)" -ForegroundColor Yellow
Start-Sleep -Seconds 30

function Verify-Url($url, $mustContain) {
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing
        $ok = $resp.StatusCode -eq 200
        if ($mustContain) { $ok = $ok -and ($resp.Content -match [regex]::Escape($mustContain)) }
        $status = if ($ok) { "OK" } else { "CHECK NEEDED" }
        Write-Host "  $url -> $($resp.StatusCode) $status" -ForegroundColor Yellow
    } catch {
        Write-Host "  $url -> FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Verify-Url $pageUrl "View Infomatics"
Verify-Url $posterUrl $null
Verify-Url "https://www.nigelthomas.live/blog.html" $pageName
Verify-Url "https://www.nigelthomas.live/sitemap.xml" $pageName

Write-Host "`nSubmit this URL to Google Search Console for indexing:" -ForegroundColor Yellow
Write-Host $pageUrl -ForegroundColor Yellow
