# Move coffee-types-poster.jpg from repo root to assets/, then commit and push.
# Run this AFTER you've uploaded coffee-types-poster.jpg to the repo root via GitHub web UI
# and pulled the latest changes locally.

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo

# Always rebase before pushing
git pull --rebase

$src = Join-Path $repo "coffee-types-poster.jpg"
$destDir = Join-Path $repo "assets"
$dest = Join-Path $destDir "coffee-types-poster.jpg"

if (-not (Test-Path $src)) {
    Write-Host "ERROR: $src not found. Did you upload it to repo root and pull first?" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

Move-Item -Path $src -Destination $dest -Force

git add -A
git commit -m "Move coffee-types-poster.jpg to assets folder"
git push

# Verify live deployment after Vercel redeploys
Start-Sleep -Seconds 20
$check = Invoke-WebRequest -Uri "https://www.nigelthomas.live/assets/coffee-types-poster.jpg" -UseBasicParsing
Write-Host "Status: $($check.StatusCode)  ContentLength: $($check.RawContentLength)"
