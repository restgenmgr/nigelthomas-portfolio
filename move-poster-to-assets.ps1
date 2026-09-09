# ============================================================
# Move restaurant-hotel-napkin-folding.png from repo root -> assets/
# then verify locally and (after push) verify live on Vercel
# ============================================================

$root = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $root

$file = "restaurant-hotel-napkin-folding.png"
$src  = Join-Path $root $file
$dest = Join-Path $root "assets\$file"

# --- Move ---
if (Test-Path $src) {
    Move-Item -Path $src -Destination $dest -Force
    Write-Host "Moved: $file -> assets\" -ForegroundColor Green
} else {
    Write-Host "File not found at repo root: $src" -ForegroundColor Red
}

# --- Verify locally ---
if (Test-Path $dest) {
    $info = Get-Item $dest
    Write-Host "Confirmed in assets/: $($info.FullName)" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($info.Length / 1KB, 1)) KB"
} else {
    Write-Host "Move failed — file not found in assets/" -ForegroundColor Red
}

# --- Commit + push ---
git pull --rebase
git add assets/$file
git commit -m "Add: restaurant-hotel-napkin-folding.png to assets"
git push

# ============================================================
# Verify live (run a minute or two after push, once Vercel redeploys)
# ============================================================
$liveUrl = "https://www.nigelthomas.live/assets/restaurant-hotel-napkin-folding.png"
try {
    $resp = Invoke-WebRequest -Uri $liveUrl -UseBasicParsing -Method Head
    Write-Host "LIVE CHECK: $($resp.StatusCode) $($resp.StatusDescription)" -ForegroundColor Green
    Write-Host "Content-Length: $($resp.Headers['Content-Length']) bytes"
} catch {
    Write-Host "LIVE CHECK FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
