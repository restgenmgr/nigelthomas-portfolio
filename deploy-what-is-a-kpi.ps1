$ErrorActionPreference = "Stop"

Write-Host "===== STEP 1: Clear stale downloads with the same names =====" -ForegroundColor Cyan
Get-ChildItem "$env:USERPROFILE\Downloads\what-is-a-kpi*" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem "$env:USERPROFILE\Downloads\blog*.html" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem "$env:USERPROFILE\Downloads\sitemap*.xml" -ErrorAction SilentlyContinue | Remove-Item -Force
Write-Host "Old cached downloads cleared. Now download the 4 files from the chat (jpg, article html, blog.html, sitemap.xml) before continuing." -ForegroundColor Yellow
Write-Host "Press Enter once all 4 files are in your Downloads folder..." -ForegroundColor Yellow
Read-Host | Out-Null

Write-Host ""
Write-Host "===== STEP 2: Verify each download against its expected hash =====" -ForegroundColor Cyan

$expected = @{
    "what-is-a-kpi.jpg"  = "D90F5B8646AC682CBC5D65CD3C6201880D0258C292CEC0B985D61BBE228F0E38"
    "what-is-a-kpi.html" = "46182CAFE1F8D48FFB5D3341D4778A9D5C99D0E9372E58E373F210EEA76BC752"
    "blog.html"           = "B9E43723A8791D6D63FEC1DAE4E82B7F74A94FF93BFF5AEE7D96A27B0D04B708"
    "sitemap.xml"         = "9C2723E18BF6A728CE5D53B3D1AB97A910E30B0CEE4398379C8917226F016BF5"
}

$allGood = $true
foreach ($file in $expected.Keys) {
    $path = Join-Path "$env:USERPROFILE\Downloads" $file
    if (-not (Test-Path $path)) {
        Write-Host "MISSING: $file not found in Downloads." -ForegroundColor Red
        $allGood = $false
        continue
    }
    $hash = (Get-FileHash $path -Algorithm SHA256).Hash
    if ($hash -eq $expected[$file]) {
        Write-Host "OK: $file hash matches." -ForegroundColor Green
    } else {
        Write-Host "MISMATCH: $file does NOT match expected hash. Do not proceed with this file." -ForegroundColor Red
        Write-Host "  Expected: $($expected[$file])"
        Write-Host "  Got:      $hash"
        $allGood = $false
    }
}

if (-not $allGood) {
    Write-Host ""
    Write-Host "ABORTING: one or more files failed verification. Fix the download(s) above and rerun this script." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All 4 files verified. Proceeding with deployment." -ForegroundColor Green

Write-Host ""
Write-Host "===== STEP 3: Sync with GitHub =====" -ForegroundColor Cyan
Set-Location "C:\Users\admin\Desktop\nigelthomas-portfolio"
git pull --rebase origin main

Write-Host ""
Write-Host "===== STEP 4: Move files into place =====" -ForegroundColor Cyan
Move-Item "$env:USERPROFILE\Downloads\what-is-a-kpi.jpg" ".\assets\what-is-a-kpi.jpg" -Force
Move-Item "$env:USERPROFILE\Downloads\what-is-a-kpi.html" ".\what-is-a-kpi.html" -Force
Move-Item "$env:USERPROFILE\Downloads\blog.html" ".\blog.html" -Force
Move-Item "$env:USERPROFILE\Downloads\sitemap.xml" ".\sitemap.xml" -Force

Write-Host ""
Write-Host "===== STEP 5: Confirm files landed in the right place =====" -ForegroundColor Cyan
Test-Path ".\assets\what-is-a-kpi.jpg"   # should be True
Test-Path ".\what-is-a-kpi.html"          # should be True
(Get-Content ".\blog.html").Count         # should be 827
(Get-Content ".\sitemap.xml").Count       # should be 647

Write-Host ""
Write-Host "===== STEP 6: Commit, push, deploy =====" -ForegroundColor Cyan
git add -A
git status
git commit -m "Add What Is a KPI article, poster image, blog card and sitemap entry"
git push origin main
vercel --prod --force

Write-Host ""
Write-Host "===== STEP 7: Verify live =====" -ForegroundColor Cyan
Invoke-WebRequest "https://www.nigelthomas.live/what-is-a-kpi.html" | Select-Object StatusCode
Invoke-WebRequest "https://www.nigelthomas.live/assets/what-is-a-kpi.jpg" | Select-Object StatusCode
Invoke-WebRequest "https://www.nigelthomas.live/blog.html" | Select-Object StatusCode
Invoke-WebRequest "https://www.nigelthomas.live/sitemap.xml" | Select-Object StatusCode

Write-Host ""
Write-Host "===== DONE =====" -ForegroundColor Yellow
Write-Host "All 4 checks above should read StatusCode 200."
