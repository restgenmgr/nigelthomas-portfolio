# ============================================================
# ONE-SHOT-UPLOAD-TOP-WORLDWIDE-FAMOUS-DESSERTS.ps1
# Locates the 3 dessert-poster files (already in GitHub repo
# root and/or your Downloads folder), moves the JPG into
# assets/, then pulls, commits, and pushes to nigelthomas.live.
# ============================================================

$ErrorActionPreference = "Stop"

$repo       = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$assets     = Join-Path $repo "assets"
$downloads  = Join-Path $env:USERPROFILE "Downloads"

$htmlName = "top-worldwide-famous-desserts.html"
$jpgName  = "top-worldwide-famous-desserts.jpg"
$txtName  = "deployment-snippets.txt"

function Find-SourceFile {
    param([string]$FileName)
    $repoRoot  = Join-Path $repo $FileName
    $dlPath    = Join-Path $downloads $FileName
    if (Test-Path $repoRoot) { return $repoRoot }
    if (Test-Path $dlPath)   { return $dlPath }
    return $null
}

Set-Location $repo
Write-Host "== Step 1: Sync local repo with remote ==" -ForegroundColor Yellow
git pull --rebase --autostash

Write-Host "== Step 2: Locate the 3 files ==" -ForegroundColor Yellow
$htmlSrc = Find-SourceFile $htmlName
$jpgSrc  = Find-SourceFile $jpgName
$txtSrc  = Find-SourceFile $txtName

if (-not $htmlSrc) { throw "Could not find $htmlName in repo root or Downloads." }
if (-not $jpgSrc)  { throw "Could not find $jpgName in repo root or Downloads." }

Write-Host "  HTML found at: $htmlSrc"
Write-Host "  JPG  found at: $jpgSrc"
if ($txtSrc) { Write-Host "  TXT  found at: $txtSrc" }

Write-Host "== Step 3: Place HTML at repo root ==" -ForegroundColor Yellow
$htmlDest = Join-Path $repo $htmlName
if ($htmlSrc -ne $htmlDest) {
    Move-Item -Path $htmlSrc -Destination $htmlDest -Force
}
if (-not (Test-Path $htmlDest)) { throw "HTML did not land at repo root: $htmlDest" }
Write-Host "  Confirmed: $htmlDest" -ForegroundColor Yellow

Write-Host "== Step 4: Move JPG into assets/ ==" -ForegroundColor Yellow
if (-not (Test-Path $assets)) { New-Item -ItemType Directory -Path $assets | Out-Null }
$jpgDest = Join-Path $assets $jpgName
Move-Item -Path $jpgSrc -Destination $jpgDest -Force
if (-not (Test-Path $jpgDest)) { throw "JPG did not land in assets/: $jpgDest" }
Write-Host "  Confirmed: $jpgDest" -ForegroundColor Yellow

# Optional: keep the deployment-snippets.txt out of the deployed site;
# just leave it in Downloads for reference (not added to git).
if ($txtSrc -and (Split-Path $txtSrc -Parent) -eq $repo) {
    Move-Item -Path $txtSrc -Destination (Join-Path $downloads $txtName) -Force
}

Write-Host "== Step 5: git add / commit / push ==" -ForegroundColor Yellow
git add $htmlDest
git add $jpgDest
git status --short

$commitMsg = "Add Top Worldwide Famous Desserts poster page"
git commit -m $commitMsg
git pull --rebase --autostash
git push

Write-Host "== Step 6: Verify live deployment (allow ~60s for Vercel build) ==" -ForegroundColor Yellow
Start-Sleep -Seconds 60

$pageUrl  = "https://www.nigelthomas.live/top-worldwide-famous-desserts.html"
$assetUrl = "https://www.nigelthomas.live/assets/top-worldwide-famous-desserts.jpg"

foreach ($url in @($pageUrl, $assetUrl)) {
    try {
        $resp = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing
        Write-Host "  $($resp.StatusCode)  $url" -ForegroundColor Yellow
    } catch {
        Write-Host "  FAILED  $url  -- $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "== Done. Now add the blog.html card and sitemap.xml entry manually" -ForegroundColor Yellow
Write-Host "   (see deployment-snippets.txt in your Downloads folder). ==" -ForegroundColor Yellow
