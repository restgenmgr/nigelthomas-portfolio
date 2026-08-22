# Deploy: Store Keeper's Worksheet page + poster jpg + PDF
$ErrorActionPreference = "Stop"

$repo   = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$source = "$env:USERPROFILE\Downloads\storekeepers-worksheet-files"

$htmlFile   = "store-keepers-worksheet.html"
$posterFile = "poster_black_gold.jpg"
$pdfFile    = "storekeepers-worksheet.pdf"

Write-Host "== Step 1: Pull latest (rebase) ==" -ForegroundColor Cyan
Set-Location -LiteralPath $repo
git pull --rebase

Write-Host "== Step 2: Move files into place ==" -ForegroundColor Cyan

$assetsDir = Join-Path $repo "assets"
if (-not (Test-Path -LiteralPath $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir | Out-Null
}

$htmlSrc = Join-Path $source $htmlFile
$htmlDst = Join-Path $repo $htmlFile
if (Test-Path -LiteralPath $htmlSrc) {
    Move-Item -LiteralPath $htmlSrc -Destination $htmlDst -Force
    Write-Host "Moved $htmlFile to repo root" -ForegroundColor Green
} else {
    Write-Warning "$htmlFile not found - skipping."
}

$posterSrc = Join-Path $source $posterFile
$posterDstName = "storekeepers-worksheet-poster.jpg"
$posterDst = Join-Path $assetsDir $posterDstName
if (Test-Path -LiteralPath $posterSrc) {
    Move-Item -LiteralPath $posterSrc -Destination $posterDst -Force
    Write-Host "Moved $posterFile to assets/$posterDstName" -ForegroundColor Green
} else {
    Write-Warning "$posterFile not found - skipping."
}

$pdfSrc = Join-Path $source $pdfFile
$pdfDst = Join-Path $assetsDir $pdfFile
if (Test-Path -LiteralPath $pdfSrc) {
    Move-Item -LiteralPath $pdfSrc -Destination $pdfDst -Force
    Write-Host "Moved $pdfFile to assets/$pdfFile" -ForegroundColor Green
} else {
    Write-Warning "$pdfFile not found - skipping."
}

Write-Host "== Step 3: Git add / commit / push ==" -ForegroundColor Cyan
Set-Location -LiteralPath $repo
git add $htmlFile
git add "assets/$posterDstName"
git add "assets/$pdfFile"
git status

git commit -m "Add Store Keeper's Worksheet page, poster image, and PDF worksheet"
git pull --rebase
git push

Write-Host "== Step 4: Verify deployment (after Vercel finishes) ==" -ForegroundColor Cyan
Write-Host "Waiting 30 seconds for Vercel to build..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

$baseUrl = "https://www.nigelthomas.live"
$checks = @(
    @{ Url = "$baseUrl/$htmlFile";            Match = "STORE KEEPER'S WORKSHEET" },
    @{ Url = "$baseUrl/assets/$posterDstName"; Match = $null },
    @{ Url = "$baseUrl/assets/$pdfFile";       Match = $null }
)

foreach ($check in $checks) {
    try {
        $resp = Invoke-WebRequest -Uri $check.Url -UseBasicParsing -TimeoutSec 20
        $ok = $resp.StatusCode -eq 200
        if ($check.Match) {
            $ok = $ok -and ($resp.Content -match [regex]::Escape($check.Match))
        }
        if ($ok) {
            Write-Host "OK   $($check.Url)" -ForegroundColor Green
        } else {
            Write-Host "FAIL $($check.Url) (status $($resp.StatusCode), content check failed)" -ForegroundColor Red
        }
    } catch {
        Write-Host "FAIL $($check.Url) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "== Done ==" -ForegroundColor Cyan