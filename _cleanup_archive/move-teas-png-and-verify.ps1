# move-teas-png-and-verify.ps1
# Moves medicinal-properties-of-teas.png from repo root into assets/,
# renaming it to teas.png (matching what the HTML page already references),
# then pulls, pushes, deploys and verifies.
#
# Run from PowerShell as: .\move-teas-png-and-verify.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Pull latest with rebase (picks up the web-UI upload) ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 3: Verify PNG landed at root ==" -ForegroundColor Cyan
$rootPng = "$repoPath\medicinal-properties-of-teas.png"
if (-not (Test-Path $rootPng)) {
    Write-Host "ERROR: File not found at repo root: $rootPng" -ForegroundColor Red
    exit 1
}

Write-Host "== Step 4: Move + rename into assets/teas.png (overwrites old version) ==" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$repoPath\assets" | Out-Null
Move-Item $rootPng "$repoPath\assets\teas.png" -Force

Write-Host "== Step 5: Stage the move (deletion at root + updated file in assets), commit, push ==" -ForegroundColor Cyan
git add -A
git commit -m "Move updated teas avatar image from root into assets/teas.png"
git push origin main

Write-Host "== Step 6: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "== Step 7: Verify ==" -ForegroundColor Cyan
Write-Host "Checking https://www.nigelthomas.live/assets/teas.png ..." -ForegroundColor Yellow
try {
    $resp = Invoke-WebRequest -Uri "https://www.nigelthomas.live/assets/teas.png" -UseBasicParsing -Method Head
    Write-Host "Status: $($resp.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Could not verify automatically - check manually in browser (may be cache delay)." -ForegroundColor Yellow
}

Write-Host "`nDone. Note: the .html file with the same name at repo root is expected and correct — that's the live page itself, not something to move." -ForegroundColor Green
