# deploy-all-pending.ps1
# Deploys everything currently pending in one consolidated push:
#   - 7-types-of-coffee-and-how-theyre-made.html  (full coffee article - NEW)
#   - coffee-types-poster.html                     (coffee quick-ref poster - NEW)
#   - blog.html   (adds both coffee cards; moves Teas card into
#                   Food Safety & Culinary next to Spices)
#   - sitemap.xml (adds both coffee URLs; bumps teas lastmod;
#                   fixes the invalid trailing content bug)
#   - medicinal-properties-of-teas.html (adds coffee + spices cross-links)
#   - medicinal-value-of-spices.html    (adds reciprocal teas + coffee links)
#
# This REPLACES the older deploy-coffee-pages.ps1 - don't run that one,
# it has stale copies of blog.html/sitemap.xml/teas.html.
#
# Run from PowerShell as: .\deploy-all-pending.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads = "$env:USERPROFILE\Downloads"

$files = @(
    "7-types-of-coffee-and-how-theyre-made.html",
    "coffee-types-poster.html",
    "blog.html",
    "sitemap.xml",
    "medicinal-properties-of-teas.html",
    "medicinal-value-of-spices.html"
)

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Check git status ==" -ForegroundColor Cyan
git status

Write-Host "== Step 3: Pull latest with rebase ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 4: Verify all source files exist in Downloads ==" -ForegroundColor Cyan
foreach ($f in $files) {
    $src = Join-Path $downloads $f
    if (-not (Test-Path $src)) {
        Write-Host "ERROR: File not found: $src" -ForegroundColor Red
        Write-Host "Check Downloads for a (1) suffix if this was downloaded before." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "All 6 source files found." -ForegroundColor Green

Write-Host "== Step 5: Copy files into repo ==" -ForegroundColor Cyan
foreach ($f in $files) {
    Copy-Item (Join-Path $downloads $f) "$repoPath\$f" -Force
    Write-Host "Copied: $f" -ForegroundColor Green
}

Write-Host "== Step 6: Stage, commit, push ==" -ForegroundColor Cyan
git add .
git commit -m "Add coffee article + poster; cross-link coffee/teas/spices; reorganize blog.html and sitemap.xml"
git push origin main

Write-Host "== Step 7: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "== Step 8: Verify ==" -ForegroundColor Cyan
$urls = @(
    "https://www.nigelthomas.live/7-types-of-coffee-and-how-theyre-made.html",
    "https://www.nigelthomas.live/coffee-types-poster.html",
    "https://www.nigelthomas.live/medicinal-properties-of-teas.html",
    "https://www.nigelthomas.live/medicinal-value-of-spices.html",
    "https://www.nigelthomas.live/blog.html",
    "https://www.nigelthomas.live/sitemap.xml"
)
foreach ($u in $urls) {
    try {
        $resp = Invoke-WebRequest -Uri $u -UseBasicParsing -Method Head
        Write-Host "$($resp.StatusCode)  $u" -ForegroundColor Green
    } catch {
        Write-Host "FAILED  $u" -ForegroundColor Red
    }
}

Write-Host "`nDone." -ForegroundColor Green
Write-Host "Reminder: your accounting/index.html changes are stashed - run 'git stash pop' whenever you're ready to get them back." -ForegroundColor Yellow
