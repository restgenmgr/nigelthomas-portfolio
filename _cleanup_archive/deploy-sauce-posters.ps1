# ============================================================
# Deploy: Mother Sauce Derivatives page + Bonus Sauces poster
# Repo: restgenmgr/nigelthomas-portfolio
# ============================================================

$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repoPath

Write-Host "STEP 1: Pulling latest (web-UI uploads may already be in root)..." -ForegroundColor Yellow
git pull --rebase

# ------------------------------------------------------------
# STEP 2: Confirm the files landed at repo root
# ------------------------------------------------------------
Write-Host "STEP 2: Checking root for uploaded files..." -ForegroundColor Yellow

$rootSvg1 = Join-Path $repoPath "mother-sauce-derivatives-poster.svg"
$rootSvg2 = Join-Path $repoPath "popular-sauces-condiments-poster.svg"
$rootHtml = Join-Path $repoPath "mother-sauce-derivatives.html"

$missing = @()
if (-not (Test-Path $rootSvg1)) { $missing += "mother-sauce-derivatives-poster.svg" }
if (-not (Test-Path $rootSvg2)) { $missing += "popular-sauces-condiments-poster.svg" }
if (-not (Test-Path $rootHtml)) { $missing += "mother-sauce-derivatives.html" }

if ($missing.Count -gt 0) {
    Write-Host "MISSING at repo root, stopping:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "Upload the missing file(s) to root via GitHub web UI, then re-run this script." -ForegroundColor Red
    exit 1
}

Write-Host "All three files found at root." -ForegroundColor Green

# ------------------------------------------------------------
# STEP 3: Move the SVGs into assets/ (HTML page stays at root,
# matching the live URL nigelthomas.live/mother-sauce-derivatives.html)
# ------------------------------------------------------------
Write-Host "STEP 3: Moving SVGs into assets/..." -ForegroundColor Yellow

$assetsPath = Join-Path $repoPath "assets"
if (-not (Test-Path $assetsPath)) { New-Item -ItemType Directory -Path $assetsPath | Out-Null }

Move-Item -Path $rootSvg1 -Destination (Join-Path $assetsPath "mother-sauce-derivatives-poster.svg") -Force
Move-Item -Path $rootSvg2 -Destination (Join-Path $assetsPath "popular-sauces-condiments-poster.svg") -Force

$check1 = Test-Path (Join-Path $assetsPath "mother-sauce-derivatives-poster.svg")
$check2 = Test-Path (Join-Path $assetsPath "popular-sauces-condiments-poster.svg")

if (-not ($check1 -and $check2)) {
    Write-Host "Move failed - one or both SVGs not confirmed in assets/. Stopping." -ForegroundColor Red
    exit 1
}
Write-Host "Both SVGs confirmed in assets/." -ForegroundColor Green

# ------------------------------------------------------------
# STEP 4: Stage, commit, push
# ------------------------------------------------------------
Write-Host "STEP 4: Committing and pushing..." -ForegroundColor Yellow

git add mother-sauce-derivatives.html
git add assets/mother-sauce-derivatives-poster.svg
git add assets/popular-sauces-condiments-poster.svg

git status

git commit -m "Add bonus Popular Sauces & Condiments poster to Mother Sauce Derivatives page"
git pull --rebase
git push

# ------------------------------------------------------------
# STEP 5: Verify live (Vercel) â€” GET, not HEAD, with content checks
# ------------------------------------------------------------
Write-Host "STEP 5: Verifying live deployment (allow ~30-60s for Vercel build)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

$pageUrl  = "https://www.nigelthomas.live/mother-sauce-derivatives.html"
$svg1Url  = "https://www.nigelthomas.live/assets/mother-sauce-derivatives-poster.svg"
$svg2Url  = "https://www.nigelthomas.live/assets/popular-sauces-condiments-poster.svg"

try {
    $page = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing
    $hasBonusButton = $page.Content -match "VIEW BONUS POSTER"
    Write-Host "Page status: $($page.StatusCode) | Bonus button present: $hasBonusButton" -ForegroundColor Green
} catch {
    Write-Host "Page check FAILED: $_" -ForegroundColor Red
}

try {
    $s1 = Invoke-WebRequest -Uri $svg1Url -UseBasicParsing
    Write-Host "Mother Sauce poster SVG status: $($s1.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Mother Sauce poster SVG FAILED: $_" -ForegroundColor Red
}

try {
    $s2 = Invoke-WebRequest -Uri $svg2Url -UseBasicParsing
    Write-Host "Bonus poster SVG status: $($s2.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Bonus poster SVG FAILED: $_" -ForegroundColor Red
}

Write-Host "DONE." -ForegroundColor Yellow
