# extract-classic-cocktails-poster.ps1
# Pulls the base64-embedded poster image out of the OLD
# classic-cocktails-guide.html and saves it as a real file
# in assets/, so the new article can reference it properly.
# Run from: C:\Users\admin\Desktop\nigelthomas-portfolio
# IMPORTANT: run this BEFORE overwriting classic-cocktails-guide.html
# with the new version, since it reads the OLD file's embedded image.

[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)

$oldFile = ".\classic-cocktails-guide.html"

if (-not (Test-Path $oldFile)) {
    Write-Host "FILE NOT FOUND: $oldFile -- run this from the repo root, before overwriting it." -ForegroundColor Red
    exit 1
}

$content = Get-Content $oldFile -Raw -Encoding UTF8

# Find a base64 image data URI: data:image/...;base64,....
$pattern = 'data:image/(?<ext>png|jpeg|jpg);base64,(?<data>[A-Za-z0-9+/=]+)'
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    Write-Host "No embedded base64 image found in $oldFile." -ForegroundColor Yellow
    Write-Host "The poster may already be a normal file reference (not base64) -- check manually." -ForegroundColor Yellow
    exit 1
}

$ext = $match.Groups['ext'].Value
if ($ext -eq "jpg") { $ext = "jpeg" }
$base64Data = $match.Groups['data'].Value

Write-Host "Found embedded image, format: $ext, base64 length: $($base64Data.Length) chars"

$bytes = [Convert]::FromBase64String($base64Data)

if (-not (Test-Path ".\assets")) {
    New-Item -ItemType Directory -Path ".\assets" | Out-Null
}

$outPath = ".\assets\classic-cocktails-guide-poster.jpg"
[System.IO.File]::WriteAllBytes($outPath, $bytes)

$fileInfo = Get-Item $outPath
Write-Host "Saved poster to $outPath ($($fileInfo.Length) bytes)" -ForegroundColor Green
Write-Host "Verify it opens correctly before continuing:" -ForegroundColor Cyan
Write-Host "  Start-Process $outPath" -ForegroundColor Cyan
