# move-coffee-asset.ps1
# Moves the coffee-post jpg from repo root into assets/ and deploys
# Run from PowerShell as: .\move-coffee-asset.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Pull latest with rebase (picks up the web-UI upload) ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 3: Verify file landed at root ==" -ForegroundColor Cyan
$rootFile = "$repoPath\7-types-of-coffee-and-how-theyre-made.jpg"
if (-not (Test-Path $rootFile)) {
    Write-Host "ERROR: File not found at repo root: $rootFile" -ForegroundColor Red
    exit 1
}

Write-Host "== Step 4: Move into assets/ ==" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$repoPath\assets" | Out-Null
Move-Item $rootFile "$repoPath\assets\7-types-of-coffee-and-how-theyre-made.jpg" -Force

Write-Host "== Step 5: Stage the move (deletion + new file), commit, push ==" -ForegroundColor Cyan
git add -A
git commit -m "Move coffee post image from root to assets/"
git push origin main

Write-Host "== Step 6: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify at:" -ForegroundColor Green
Write-Host "https://www.nigelthomas.live/assets/7-types-of-coffee-and-how-theyre-made.jpg" -ForegroundColor Green
