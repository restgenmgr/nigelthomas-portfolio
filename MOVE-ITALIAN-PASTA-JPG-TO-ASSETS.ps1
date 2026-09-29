# MOVE-ITALIAN-PASTA-JPG-TO-ASSETS.ps1
$ErrorActionPreference = "Stop"

$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repoPath

Write-Host "Pulling latest..." -ForegroundColor Yellow
git pull --rebase --autostash

$src = Join-Path $repoPath "italian-pasta-recipes.jpg"
$assetsDir = Join-Path $repoPath "assets"
$dest = Join-Path $assetsDir "italian-pasta-recipes.jpg"

if (-not (Test-Path $src)) { throw "italian-pasta-recipes.jpg not found at repo root - has it already been moved?" }
if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }

git mv "italian-pasta-recipes.jpg" "assets/italian-pasta-recipes.jpg"

if (-not (Test-Path $dest)) { throw "Move failed - file not found in assets/ after git mv." }
Write-Host "Moved to assets/italian-pasta-recipes.jpg" -ForegroundColor Yellow

git commit -m "Move italian-pasta-recipes.jpg from root to assets/"
git push

Start-Sleep -Seconds 20
$url = "https://www.nigelthomas.live/assets/italian-pasta-recipes.jpg"
try {
    $resp = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing
    Write-Host "$url -> $($resp.StatusCode)" -ForegroundColor Yellow
} catch {
    Write-Host "$url -> FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

$oldUrl = "https://www.nigelthomas.live/italian-pasta-recipes.jpg"
try {
    $resp2 = Invoke-WebRequest -Uri $oldUrl -Method Get -UseBasicParsing -ErrorAction SilentlyContinue
    Write-Host "$oldUrl -> $($resp2.StatusCode) (should ideally 404 now)" -ForegroundColor Yellow
} catch {
    Write-Host "$oldUrl -> 404/removed as expected" -ForegroundColor Yellow
}
