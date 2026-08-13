# deploy-teas-crosslinks-and-blog-update.ps1
# Deploys:
#   - updated medicinal-properties-of-teas.html (adds spices cross-link + earlier bug fixes)
#   - updated medicinal-value-of-spices.html    (adds reciprocal teas + coffee links)
#   - updated blog.html   (moves the Teas card from Food & Beverage into
#                           Food Safety & Culinary, next to the Spices card;
#                           also carries the earlier Coffee article/poster cards)
#   - updated sitemap.xml (bumps teas lastmod date; also carries the earlier
#                           coffee URLs + the fix for invalid trailing content)
#
# Run AFTER move-teas-png-and-verify.ps1
# Run from PowerShell as: .\deploy-teas-crosslinks-and-blog-update.ps1
# (Do NOT paste this multi-line script directly into the PowerShell prompt.)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$downloads = "$env:USERPROFILE\Downloads"

$files = @(
    "medicinal-properties-of-teas.html",
    "medicinal-value-of-spices.html",
    "blog.html",
    "sitemap.xml"
)

Write-Host "== Step 1: Navigate to repo ==" -ForegroundColor Cyan
Set-Location $repoPath

Write-Host "== Step 2: Check git status ==" -ForegroundColor Cyan
git status

Write-Host "== Step 3: Pull latest with rebase ==" -ForegroundColor Cyan
git pull --rebase origin main

Write-Host "== Step 4: Verify all source files exist in Downloads ==" -ForegroundColor Cyan
foreach ($f in $files) {
    $src = Join-Path $downloads $f
    if (-not (Test-Path $src)) {
        Write-Host "ERROR: File not found: $src" -ForegroundColor Red
        Write-Host "Check Downloads for a (1) suffix if this was downloaded before." -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "All source files found." -ForegroundColor Green

Write-Host "== Step 5: Copy files into repo ==" -ForegroundColor Cyan
Copy-Item (Join-Path $downloads "medicinal-properties-of-teas.html") "$repoPath\medicinal-properties-of-teas.html" -Force
Copy-Item (Join-Path $downloads "medicinal-value-of-spices.html") "$repoPath\medicinal-value-of-spices.html" -Force
Copy-Item (Join-Path $downloads "blog.html") "$repoPath\blog.html" -Force
Copy-Item (Join-Path $downloads "sitemap.xml") "$repoPath\sitemap.xml" -Force

Write-Host "== Step 6: Stage, commit, push ==" -ForegroundColor Cyan
git add .
git commit -m "Cross-link teas and spices posts; move teas card to Food Safety & Culinary section; update sitemap"
git push origin main

Write-Host "== Step 7: Deploy to production via Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`nDone. Verify at:" -ForegroundColor Green
Write-Host "https://www.nigelthomas.live/medicinal-properties-of-teas.html" -ForegroundColor Green
Write-Host "https://www.nigelthomas.live/medicinal-value-of-spices.html" -ForegroundColor Green
Write-Host "https://www.nigelthomas.live/blog.html  (Teas card now under Food Safety & Culinary)" -ForegroundColor Green
Write-Host "https://www.nigelthomas.live/sitemap.xml" -ForegroundColor Green
