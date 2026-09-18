<#
ONE-SHOT-UPLOAD-GOURMET-CANAPES-STARTERS.ps1

Run this from PowerShell on the machine that has the local clone of
restgenmgr/nigelthomas-portfolio (normally C:\Users\admin\Desktop\nigelthomas-portfolio).

What it does:
1. Copies the poster PNG into assets\
2. Copies the self-contained HTML page into blog\
3. Confirms both files exist at their destination
4. Commits and pushes to GitHub

Before running: download GOURMET-canapes-starters.png and
gourmet-canapes-italian-starters.html from this chat into the SAME
folder as this script (e.g. your Desktop or Downloads), then edit
$SourceDir below if needed.
#>

$RepoPath  = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$SourceDir = "$PSScriptRoot"

$PosterName = "GOURMET-canapes-starters.png"
$PageName   = "gourmet-canapes-italian-starters.html"

$PosterSrc = Join-Path $SourceDir $PosterName
$PageSrc   = Join-Path $SourceDir $PageName

$AssetsDest = Join-Path $RepoPath "assets\$PosterName"
$BlogDest   = Join-Path $RepoPath "blog\$PageName"

Write-Host "Step 1: verifying source files..." -ForegroundColor Yellow
if (-not (Test-Path $PosterSrc)) { Write-Host "MISSING: $PosterSrc" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $PageSrc))   { Write-Host "MISSING: $PageSrc" -ForegroundColor Red; exit 1 }

Write-Host "Step 2: syncing repo (pull --rebase)..." -ForegroundColor Yellow
Set-Location $RepoPath
git pull --rebase

Write-Host "Step 3: copying poster into assets\..." -ForegroundColor Yellow
Copy-Item -Path $PosterSrc -Destination $AssetsDest -Force
if (-not (Test-Path $AssetsDest)) { Write-Host "FAILED to place poster in assets\" -ForegroundColor Red; exit 1 }

Write-Host "Step 4: copying page into blog\..." -ForegroundColor Yellow
if (-not (Test-Path (Join-Path $RepoPath "blog"))) {
    New-Item -ItemType Directory -Path (Join-Path $RepoPath "blog") | Out-Null
}
Copy-Item -Path $PageSrc -Destination $BlogDest -Force
if (-not (Test-Path $BlogDest)) { Write-Host "FAILED to place page in blog\" -ForegroundColor Red; exit 1 }

Write-Host "Step 5: staging, committing, pushing..." -ForegroundColor Yellow
git add "assets/$PosterName" "blog/$PageName"
git commit -m "Add Gourmet Canapes and Italian Non-Veg Starters poster + article"
git push

Write-Host ""
Write-Host "Done. Vercel will redeploy automatically." -ForegroundColor Yellow
Write-Host "Live URLs once the deploy finishes:" -ForegroundColor Yellow
Write-Host "  https://www.nigelthomas.live/blog/gourmet-canapes-italian-starters.html"
Write-Host "  https://www.nigelthomas.live/assets/GOURMET-canapes-starters.png"
Write-Host ""
Write-Host "Remaining manual steps (not automated by this script):" -ForegroundColor Yellow
Write-Host "  1. Add a card for this article to blog.html (see snippet provided separately)."
Write-Host "  2. Add the URL entry to sitemap.xml (see snippet provided separately)."
