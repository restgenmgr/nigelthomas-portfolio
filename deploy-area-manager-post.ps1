# deploy-area-manager-post.ps1
# The image and article HTML are already pushed to nigelthomas-portfolio on GitHub.
# This script just syncs blog.html + sitemap.xml (the listing + sitemap link)
# and deploys.

Set-Location "C:\Users\admin\Desktop\nigelthomas-portfolio"

Write-Host "Checking git status before doing anything..." -ForegroundColor Cyan
git status

# 1. Pull latest first, since the image/HTML were pushed separately
Write-Host "Pulling latest from origin main..." -ForegroundColor Cyan
git pull --rebase origin main

# 2. Copy the updated blog.html and sitemap.xml in (from Claude's outputs, saved to Downloads)
Write-Host "Copying updated blog.html and sitemap.xml into repo root..." -ForegroundColor Cyan
Copy-Item "$HOME\Downloads\blog.html" -Destination ".\blog.html" -Force
Copy-Item "$HOME\Downloads\sitemap.xml" -Destination ".\sitemap.xml" -Force

# 3. Stage, commit, push
git add .
git commit -m "List Area Manager Restaurant Visit article in blog and sitemap"
git push origin main

# 4. Deploy to Vercel
Write-Host "Deploying to Vercel..." -ForegroundColor Cyan
vercel --prod --force

Write-Host "Done. Test at: https://www.nigelthomas.live/area-manager-restaurant-visit-diagnostic-lenses.html" -ForegroundColor Green
