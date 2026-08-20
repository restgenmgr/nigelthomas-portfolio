<#
  pull-push-verify-food-handling-guide.ps1
  Run this FROM INSIDE your repo folder: C:\Users\admin\Desktop\nigelthomas-portfolio
  Syncs down what you uploaded via GitHub web UI, fixes file placement if needed,
  checks blog.html/sitemap.xml actually got the snippets merged in, commits any fixes,
  pushes, and verifies the live site.
#>

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"

Set-Location $repoPath

Write-Host "== Step 1: Pull latest from GitHub ==" -ForegroundColor Cyan
git pull --rebase

Write-Host "`n== Step 2: Verify the 6 files are present ==" -ForegroundColor Cyan
$files = @(
  "food-handling-guide-poster.html",
  "deploy-food-handling-guide.ps1",
  "blog-card-snippet.html",
  "sitemap-entry-snippet.xml",
  "food-handling-guide-poster.jpg",
  "food-handling-guide-poster.jpg"   # placeholder if it landed under a different name; adjust if needed
) | Select-Object -Unique

foreach ($f in @("food-handling-guide-poster.html","deploy-food-handling-guide.ps1","blog-card-snippet.html","sitemap-entry-snippet.xml")) {
  if (Test-Path ".\$f") {
    Write-Host "Found: $f" -ForegroundColor Green
  } else {
    Write-Warning "MISSING: $f -- re-upload this one."
  }
}

Write-Host "`n== Step 3: Locate the poster JPG and fix placement if needed ==" -ForegroundColor Cyan
$jpgTarget = ".\assets\food-handling-guide-poster.jpg"
$jpgAtRoot = ".\food-handling-guide-poster.jpg"
if (Test-Path $jpgTarget) {
  Write-Host "JPG already correctly placed at assets\food-handling-guide-poster.jpg" -ForegroundColor Green
} elseif (Test-Path $jpgAtRoot) {
  Write-Host "JPG found at repo root - moving to assets\ (known GitHub web-upload behavior)" -ForegroundColor Yellow
  Move-Item $jpgAtRoot $jpgTarget -Force
  Write-Host "Moved." -ForegroundColor Green
} else {
  Write-Warning "food-handling-guide-poster.jpg not found at root or in assets\ - upload it into the assets folder."
}

Write-Host "`n== Step 4: Verify blog.html and sitemap.xml actually contain the new content ==" -ForegroundColor Cyan
$blogContent = Get-Content ".\blog.html" -Raw
if ($blogContent -match "food-handling-guide-poster") {
  Write-Host "blog.html already references the new article - looks merged." -ForegroundColor Green
} else {
  Write-Warning "blog.html does NOT contain a reference to food-handling-guide-poster yet."
  Write-Warning "Open blog-card-snippet.html, copy its contents, and paste them into blog.html (near the other <!-- END NEW CARD --> markers), then re-run this script."
}

$sitemapContent = Get-Content ".\sitemap.xml" -Raw
if ($sitemapContent -match "food-handling-guide-poster") {
  Write-Host "sitemap.xml already references the new article - looks merged." -ForegroundColor Green
} else {
  Write-Warning "sitemap.xml does NOT contain a <url> entry for food-handling-guide-poster yet."
  Write-Warning "Open sitemap-entry-snippet.xml, copy its contents, and paste them into sitemap.xml just above </urlset>, then re-run this script."
}

Write-Host "`n== Step 5: Commit and push any fixes (e.g. the JPG move) ==" -ForegroundColor Cyan
git add -A
$status = git status --porcelain
if ($status) {
  git commit -m "Fix file placement for food handling guide poster"
  git pull --rebase
  git push
  Write-Host "Pushed fixes." -ForegroundColor Green
} else {
  Write-Host "Nothing to commit - working tree already clean." -ForegroundColor Green
}

Write-Host "`n== Step 6: Verify the live site ==" -ForegroundColor Cyan
Start-Sleep -Seconds 5
$cacheBust = Get-Date -UFormat %s
$urls = @(
  "https://www.nigelthomas.live/food-handling-guide-poster.html",
  "https://www.nigelthomas.live/assets/food-handling-guide-poster.jpg",
  "https://www.nigelthomas.live/blog.html",
  "https://www.nigelthomas.live/sitemap.xml"
)
foreach ($u in $urls) {
  try {
    $resp = Invoke-WebRequest -Uri "$u`?v=$cacheBust" -UseBasicParsing -Method Head
    Write-Host "$u -> $($resp.StatusCode)" -ForegroundColor Green
  } catch {
    Write-Warning "$u -> FAILED: $_"
  }
}

Write-Host "`nDONE." -ForegroundColor Cyan
Write-Host "If blog.html or sitemap.xml warnings appeared above, merge those snippets in manually and re-run this script." -ForegroundColor Yellow
Write-Host "Once everything checks out, submit this URL in Google Search Console:" -ForegroundColor Yellow
Write-Host "https://www.nigelthomas.live/food-handling-guide-poster.html" -ForegroundColor Yellow
