# Sync-and-deploy script for nigelthomas-portfolio
# Run this AFTER uploading files directly via GitHub web UI

Set-Location "C:\Users\admin\Desktop\nigelthomas-portfolio"

Write-Host "Checking git status..." -ForegroundColor Cyan
git status

Write-Host "`nPulling latest changes from GitHub (rebase)..." -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "`nConfirming local repo is now up to date..." -ForegroundColor Cyan
git status

Write-Host "`nDeploying to Vercel (production)..." -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify the live pages:" -ForegroundColor Green
Write-Host "  https://www.nigelthomas.live/fifo-vs-fefo-stock-rotation-guide.html"
Write-Host "  https://www.nigelthomas.live/blog.html"
Write-Host "  https://www.nigelthomas.live/sitemap.xml"
