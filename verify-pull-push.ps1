# ============================================================
# Verify: local repo is in sync with GitHub (pull/push clean),
# then verify the live Vercel deployment
# ============================================================

$root = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $root

Write-Host "`n--- 1) Fetch latest from origin ---" -ForegroundColor Cyan
git fetch origin

Write-Host "`n--- 2) Local vs remote status ---" -ForegroundColor Cyan
git status
# Look for: "Your branch is up to date with 'origin/main'."
# If it says "ahead" -> you have unpushed commits.
# If it says "behind" -> pull before doing anything else.

Write-Host "`n--- 3) Last commit locally vs on origin ---" -ForegroundColor Cyan
$localHead  = git rev-parse HEAD
$remoteHead = git rev-parse origin/main
Write-Host "Local  HEAD: $localHead"
Write-Host "Origin HEAD: $remoteHead"
if ($localHead -eq $remoteHead) {
    Write-Host "MATCH — local and GitHub are in sync." -ForegroundColor Green
} else {
    Write-Host "MISMATCH — local and GitHub differ. Push or pull as needed." -ForegroundColor Red
}

Write-Host "`n--- 4) Confirm the file is tracked and committed ---" -ForegroundColor Cyan
git log -1 --oneline -- assets/restaurant-hotel-napkin-folding.png
git ls-files assets/restaurant-hotel-napkin-folding.png

# ============================================================
# 5) Verify live on Vercel (allow a minute or two after push
#    for the deployment to finish before trusting a 404 here)
# ============================================================
Write-Host "`n--- 5) Live checks ---" -ForegroundColor Cyan

$checks = @(
    "https://www.nigelthomas.live/assets/restaurant-hotel-napkin-folding.png",
    "https://www.nigelthomas.live/blog/restaurant-hotel-napkin-folding.html",
    "https://www.nigelthomas.live/blog.html",
    "https://www.nigelthomas.live/sitemap.xml"
)

foreach ($url in $checks) {
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head
        Write-Host "$($resp.StatusCode) $url" -ForegroundColor Green
    } catch {
        Write-Host "FAILED  $url  -- $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n--- 6) Confirm sitemap and blog.html actually mention the new page ---" -ForegroundColor Cyan
try {
    $sitemap = Invoke-WebRequest -Uri "https://www.nigelthomas.live/sitemap.xml" -UseBasicParsing
    if ($sitemap.Content -match "restaurant-hotel-napkin-folding") {
        Write-Host "sitemap.xml contains the new URL." -ForegroundColor Green
    } else {
        Write-Host "sitemap.xml does NOT contain the new URL yet." -ForegroundColor Red
    }
} catch { Write-Host "Could not fetch sitemap.xml" -ForegroundColor Red }

try {
    $blog = Invoke-WebRequest -Uri "https://www.nigelthomas.live/blog.html" -UseBasicParsing
    if ($blog.Content -match "restaurant-hotel-napkin-folding") {
        Write-Host "blog.html contains the new card link." -ForegroundColor Green
    } else {
        Write-Host "blog.html does NOT contain the new card link yet." -ForegroundColor Red
    }
} catch { Write-Host "Could not fetch blog.html" -ForegroundColor Red }
