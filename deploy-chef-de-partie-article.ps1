# deploy-chef-de-partie-article.ps1
# Deploys "Chef de Partie (CDP) Job Opening: Banana Leaf by Klox Is Hiring" to nigelthomas.live
# Adds the new article + hero image, and pushes updated blog.html + sitemap.xml
# Run as: .\deploy-chef-de-partie-article.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"

# ---- CONFIG: adjust source folder if you saved the downloaded files elsewhere ----
$repoPath  = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads = "$env:USERPROFILE\Downloads"

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Check current git status (flagging any uncommitted web-UI changes) ==" -ForegroundColor Cyan
git status

Write-Host "== Step 3: Pull latest with rebase (avoids divergence from web UI uploads) ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 4: Copy article, hero image, blog.html and sitemap.xml into repo ==" -ForegroundColor Cyan
Copy-Item "$downloads\chef-de-partie-job-opening-banana-leaf-klox.html" "$repoPath\chef-de-partie-job-opening-banana-leaf-klox.html" -Force
Copy-Item "$downloads\chef-de-partie-job-opening-banana-leaf-klox.jpg"  "$repoPath\chef-de-partie-job-opening-banana-leaf-klox.jpg"  -Force
Copy-Item "$downloads\blog.html"                                        "$repoPath\blog.html"                                        -Force
Copy-Item "$downloads\sitemap.xml"                                      "$repoPath\sitemap.xml"                                      -Force

Write-Host "== Step 5: Stage, commit, push ==" -ForegroundColor Cyan
git add .
git commit -m "Add article: Chef de Partie (CDP) Job Opening - Banana Leaf by Klox (+ blog & sitemap updates)"
git push origin main

Write-Host "== Step 6: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify at:" -ForegroundColor Green
Write-Host "  https://www.nigelthomas.live/chef-de-partie-job-opening-banana-leaf-klox.html"
Write-Host "  https://www.nigelthomas.live/blog.html"
Write-Host "  https://www.nigelthomas.live/sitemap.xml"
