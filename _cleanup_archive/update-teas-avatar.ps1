# update-teas-avatar.ps1
# Replaces assets/teas.png with the updated version (new tuxedo-photo avatar)
# Run from PowerShell as: .\update-teas-avatar.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"

# ---- CONFIG: adjust source path if you saved the file elsewhere ----
$repoPath  = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$sourceImg = "$env:USERPROFILE\Downloads\teas.png"

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Check current git status (flagging any uncommitted changes) ==" -ForegroundColor Cyan
git status

Write-Host "== Step 3: Pull latest with rebase ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 4: Verify source file exists (watch for a (1) suffix if re-downloaded) ==" -ForegroundColor Cyan
if (-not (Test-Path $sourceImg)) {
    Write-Host "ERROR: File not found at $sourceImg" -ForegroundColor Red
    Write-Host "Check your Downloads folder — it may have saved with a (1) suffix." -ForegroundColor Yellow
    exit 1
}

Write-Host "== Step 5: Replace assets/teas.png ==" -ForegroundColor Cyan
Copy-Item $sourceImg "$repoPath\assets\teas.png" -Force

Write-Host "== Step 6: Stage, commit, push ==" -ForegroundColor Cyan
git add .
git commit -m "Update teas post avatar photo"
git push origin main

Write-Host "== Step 7: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify at:" -ForegroundColor Green
Write-Host "https://www.nigelthomas.live/medicinal-properties-of-teas.html" -ForegroundColor Green
Write-Host "(Hard-refresh or check in an incognito window — images are often cached.)" -ForegroundColor Yellow
