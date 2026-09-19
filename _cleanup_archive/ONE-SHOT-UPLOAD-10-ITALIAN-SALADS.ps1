# ============================================================
# ONE-SHOT DEPLOY - 10 ITALIAN SALADS
# Repo: restgenmgr/nigelthomas-portfolio
# Local repo expected: C:\Users\admin\Desktop\nigelthomas-portfolio
#
# Package layout:
#   10-italian-salads.html
#   assets\10italian-salads.png
#   ONE-SHOT-UPLOAD-10-ITALIAN-SALADS.ps1
#
# Run from the extracted package folder:
#   powershell -ExecutionPolicy Bypass -File .\ONE-SHOT-UPLOAD-10-ITALIAN-SALADS.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$page = "10-italian-salads.html"
$poster = "10italian-salads.png"
$live = "https://www.nigelthomas.live/10-italian-salads.html"

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pageSrc = Join-Path $packageRoot $page
$posterSrc = Join-Path $packageRoot "assets\$poster"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Gold
Write-Host "  10 ITALIAN SALADS - ONE SHOT DEPLOY" -ForegroundColor Gold
Write-Host "============================================================" -ForegroundColor Gold

if (!(Test-Path $repo)) { throw "Repository not found: $repo" }
if (!(Test-Path $pageSrc)) { throw "Missing package HTML: $pageSrc" }
if (!(Test-Path $posterSrc)) { throw "Missing package poster: $posterSrc" }

Set-Location $repo

Write-Host "`n[1] Pull latest main..." -ForegroundColor Cyan
git pull --rebase origin main
if ($LASTEXITCODE -ne 0) { throw "git pull --rebase failed." }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "`n[2] Backup existing target files..." -ForegroundColor Cyan
foreach ($target in @(
    $page,
    "blog.html",
    "sitemap.xml",
    "assets\$poster"
)) {
    $full = Join-Path $repo $target
    if (Test-Path $full) {
        Copy-Item $full "$full.backup-$stamp" -Force
        Write-Host "  BACKUP: $target" -ForegroundColor DarkGray
    }
}

Write-Host "`n[3] Install HTML + poster..." -ForegroundColor Cyan
Copy-Item $pageSrc (Join-Path $repo $page) -Force
New-Item -ItemType Directory -Path (Join-Path $repo "assets") -Force | Out-Null
Copy-Item $posterSrc (Join-Path $repo "assets\$poster") -Force

# Normalize the new HTML to UTF-8 without BOM.
$htmlPath = Join-Path $repo $page
$html = [IO.File]::ReadAllText($htmlPath)
[IO.File]::WriteAllText($htmlPath, $html, [Text.UTF8Encoding]::new($false))

Write-Host "  INSTALLED: $page" -ForegroundColor Green
Write-Host "  INSTALLED: assets\$poster" -ForegroundColor Green

Write-Host "`n[4] Update blog.html..." -ForegroundColor Cyan
$blogPath = Join-Path $repo "blog.html"
$blog = [IO.File]::ReadAllText($blogPath)
$blogUrl = $page

if ($blog -notmatch [regex]::Escape($blogUrl)) {
    $blogEntry = @'
<li>
<a href="10-italian-salads.html">10 Italian Salads - Professional Kitchen Guide</a>
<span class="date">September 2026</span>
<p>Ten Italian salads explained for hotel, restaurant and professional kitchen teams, with practical preparation and service guidance.</p>
</li>
'@
    if ($blog -match '<!-- BLOG_LIST_MARKER -->') {
        $blog = $blog -replace '(<!-- BLOG_LIST_MARKER -->)', ('$1' + [Environment]::NewLine + $blogEntry)
        Write-Host "  BLOG: inserted after BLOG_LIST_MARKER" -ForegroundColor Green
    }
    else {
        $needle = '<ul style="margin-left:30px;line-height:2;">'
        if ($blog -match [regex]::Escape($needle)) {
            $blog = $blog -replace [regex]::Escape($needle), ($needle + [Environment]::NewLine + $blogEntry)
            Write-Host "  BLOG: inserted in article list" -ForegroundColor Green
        }
        else {
            throw "Could not find a safe insertion point in blog.html."
        }
    }
    [IO.File]::WriteAllText($blogPath, $blog, [Text.UTF8Encoding]::new($false))
}
else {
    Write-Host "  BLOG: URL already present - no duplicate added" -ForegroundColor Yellow
}

Write-Host "`n[5] Update sitemap.xml..." -ForegroundColor Cyan
$sitemapPath = Join-Path $repo "sitemap.xml"
$sitemap = [IO.File]::ReadAllText($sitemapPath)

if ($sitemap -notmatch [regex]::Escape("https://www.nigelthomas.live/$page")) {
    $sitemapEntry = @'
    <url>
        <loc>https://www.nigelthomas.live/10-italian-salads.html</loc>
        <lastmod>2026-09-10</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.7</priority>
    </url>
'@
    if ($sitemap -match '</urlset>') {
        $sitemap = $sitemap -replace '</urlset>', ($sitemapEntry + [Environment]::NewLine + '</urlset>')
        [IO.File]::WriteAllText($sitemapPath, $sitemap, [Text.UTF8Encoding]::new($false))
        Write-Host "  SITEMAP: new URL inserted" -ForegroundColor Green
    }
    else {
        throw "Could not find </urlset> in sitemap.xml."
    }
}
else {
    Write-Host "  SITEMAP: URL already present - no duplicate added" -ForegroundColor Yellow
}

Write-Host "`n[6] Verify local files..." -ForegroundColor Cyan
$checks = @(
    (Join-Path $repo $page),
    (Join-Path $repo "assets\$poster"),
    $blogPath,
    $sitemapPath
)
foreach ($f in $checks) {
    if (!(Test-Path $f)) { throw "Missing after update: $f" }
    $size = (Get-Item $f).Length
    if ($size -lt 100) { throw "File unexpectedly small: $f" }
    Write-Host "  PASS: $f ($size bytes)" -ForegroundColor Green
}

$posterMatches = ([regex]::Matches($html, "10italian-salads\.png")).Count
$buttonMatches = ([regex]::Matches($html, "FREE POSTER DOWNLOAD")).Count
Write-Host "  Poster references in HTML: $posterMatches" -ForegroundColor Cyan
Write-Host "  Infomatics button labels: $buttonMatches" -ForegroundColor Cyan

if ($buttonMatches -ne 1) { throw "Expected exactly one FREE POSTER DOWNLOAD button." }

Write-Host "`n[7] Git status..." -ForegroundColor Cyan
git status --short --branch

Write-Host "`n[8] Commit + push..." -ForegroundColor Cyan
git add $page "assets\$poster" "blog.html" "sitemap.xml"
git status --short

git commit -m "Add 10 Italian Salads kitchen guide and poster"
if ($LASTEXITCODE -ne 0) {
    Write-Host "No new commit created. This may mean there were no changes." -ForegroundColor Yellow
}
else {
    git push origin main
    if ($LASTEXITCODE -ne 0) { throw "git push failed." }
}

Write-Host "`n[9] Live verification..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

foreach ($url in @(
    $live,
    "https://www.nigelthomas.live/blog.html",
    "https://www.nigelthomas.live/sitemap.xml",
    "https://www.nigelthomas.live/assets/$poster"
)) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25
        Write-Host "  $($r.StatusCode)  $url" -ForegroundColor Green
    }
    catch {
        Write-Host "  CHECK FAILED: $url" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  10 ITALIAN SALADS DEPLOY COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Page:   $live"
Write-Host "Poster: https://www.nigelthomas.live/assets/$poster"
Write-Host "Blog:   https://www.nigelthomas.live/blog.html"
Write-Host "Sitemap:https://www.nigelthomas.live/sitemap.xml"
Write-Host "GSC URL: $live"
Write-Host "============================================================" -ForegroundColor Green
