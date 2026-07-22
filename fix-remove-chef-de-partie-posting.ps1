# fix-remove-chef-de-partie-posting.ps1
# Cleans up the Banana Leaf CDP job-posting references that were already pushed
# without the actual article/image files - fixes blog.html and sitemap.xml,
# and removes the now-unneeded deploy script from the repo.
# Run as: .\fix-remove-chef-de-partie-posting.ps1

$ErrorActionPreference = "Stop"

$repoPath  = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads = "$env:USERPROFILE\Downloads"

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Check current git status ==" -ForegroundColor Cyan
git status

Write-Host "== Step 3: Pull latest with rebase ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 4: Replace blog.html and sitemap.xml with cleaned versions ==" -ForegroundColor Cyan
Copy-Item "$downloads\blog.html"    "$repoPath\blog.html"    -Force
Copy-Item "$downloads\sitemap.xml"  "$repoPath\sitemap.xml"  -Force

Write-Host "== Step 5: Remove the stray deploy-chef-de-partie-article.ps1 if present ==" -ForegroundColor Cyan
if (Test-Path "$repoPath\deploy-chef-de-partie-article.ps1") {
    git rm "deploy-chef-de-partie-article.ps1"
}

Write-Host "== Step 6: Stage, commit, push ==" -ForegroundColor Cyan
git add .
git commit -m "Remove Banana Leaf CDP job posting references (article/image not published)"
git push origin main

Write-Host "== Step 7: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify at:" -ForegroundColor Green
Write-Host "  https://www.nigelthomas.live/blog.html"
Write-Host "  https://www.nigelthomas.live/sitemap.xml"
Write-Host "(No card or sitemap entry for the Banana Leaf posting should appear.)" -ForegroundColor Yellow
