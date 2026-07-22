# deploy-menu-types-article.ps1
# Deploys "13 Types of Menus Used in Food & Beverage Service" to nigelthomas.live
# Run from PowerShell as: .\deploy-menu-types-article.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"

# ---- CONFIG: adjust source paths if you saved the downloaded files elsewhere ----
$repoPath   = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$sourceHtml = "$env:USERPROFILE\Downloads\types-of-menus-fb-service.html"
$sourceImg  = "$env:USERPROFILE\Downloads\types-of-menus-fb-service.jpg"

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Check current git status (flagging any uncommitted web-UI changes) ==" -ForegroundColor Cyan
git status

Write-Host "== Step 3: Pull latest with rebase (avoids divergence from web UI uploads) ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 4: Copy article + image into repo ==" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$repoPath\images" | Out-Null
Copy-Item $sourceHtml "$repoPath\types-of-menus-fb-service.html" -Force
Copy-Item $sourceImg  "$repoPath\images\types-of-menus-fb-service.jpg" -Force

Write-Host "== Step 5: Stage, commit, push ==" -ForegroundColor Cyan
git add .
git commit -m "Add article: 13 Types of Menus Used in Food & Beverage Service"
git push origin main

Write-Host "== Step 6: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify at: https://www.nigelthomas.live/types-of-menus-fb-service.html" -ForegroundColor Green
Write-Host "Reminder: add this URL to blog.html and sitemap.xml (fetch live copies first before editing)." -ForegroundColor Yellow
