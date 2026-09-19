# Deploy: 6-pizza-recipes-hotel-restaurant-menu.html
# Repo: restgenmgr/nigelthomas-portfolio (local: C:\Users\admin\Desktop\nigelthomas-portfolio)
# Workflow: pull --rebase -> place files -> commit -> push -> verify on Vercel

$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$pageFile = "6-pizza-recipes-hotel-restaurant-menu.html"
$liveUrl  = "https://www.nigelthomas.live/$pageFile"

Set-Location $repoPath

# --- PULL ---
Write-Host "Pulling latest with rebase..." -ForegroundColor Cyan
git pull --rebase

# --- PLACE FILES ---
# Copy the finished article HTML (with the base64 image already embedded) into the repo root.
# If it lands anywhere other than repo root, move it explicitly - GitHub web UI uploads sometimes don't.
$sourceFile = Join-Path (Get-Location) "..\Downloads\$pageFile"   # adjust to wherever you saved it
$destFile   = Join-Path (Get-Location) $pageFile

if (Test-Path $sourceFile) {
    Copy-Item $sourceFile $destFile -Force
    if (-not (Test-Path $destFile)) {
        Write-Host "ERROR: file did not land at repo root: $destFile" -ForegroundColor Red
        exit 1
    }
    Write-Host "Placed $pageFile at repo root." -ForegroundColor Green
} else {
    Write-Host "Source file not found at $sourceFile - place it manually, then re-run from PUSH onward." -ForegroundColor Yellow
}

# Manually apply, before running this script:
#   1. blog-card-snippet.html   -> paste into blog.html above the current END NEW CARD marker
#   2. sitemap-entry.xml        -> paste into sitemap.xml above </urlset>

# --- COMMIT & PUSH ---
Write-Host "Staging and committing..." -ForegroundColor Cyan
git add $pageFile blog.html sitemap.xml
git commit -m "Add pizza recipes article, blog card, sitemap entry"
git push

# --- VERIFY ---
Write-Host "Waiting 20s for Vercel deploy..." -ForegroundColor Cyan
Start-Sleep -Seconds 20

Write-Host "Verifying live page ($liveUrl)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $liveUrl -UseBasicParsing
    if ($response.StatusCode -eq 200 -and $response.Content -match "6 Classic Pizza Recipes") {
        Write-Host "VERIFIED: page is live and content matches." -ForegroundColor Green
    } else {
        Write-Host "WARNING: page responded but content check failed - review manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: page not reachable yet - Vercel may still be building. Retry in 30s." -ForegroundColor Red
}

Write-Host ""
Write-Host "GSC: submit this URL for indexing once verified:" -ForegroundColor Cyan
Write-Host $liveUrl -ForegroundColor White
