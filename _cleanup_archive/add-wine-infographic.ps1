$ErrorActionPreference = "Stop"

Write-Host "Step 1: Reading article HTML as UTF-8..." -ForegroundColor Cyan
$articlePath = Join-Path (Get-Location) "history-of-wine-world-wine-regions-guide.html"
$articleContent = [System.IO.File]::ReadAllText($articlePath, [System.Text.Encoding]::UTF8)

Write-Host "Step 2: Checking anchor and asset exist before touching anything..." -ForegroundColor Cyan
$anchor = '<div class="article-body">'
if (-not $articleContent.Contains($anchor)) {
    Write-Host "ERROR: article-body anchor not found. Aborting without changes." -ForegroundColor Red
    exit 1
}
$imgPath = Join-Path (Get-Location) "assets\types-of-wine.jpg"
if (-not (Test-Path $imgPath)) {
    Write-Host "ERROR: assets\types-of-wine.jpg not found. Move the image into assets\ first, then rerun." -ForegroundColor Red
    exit 1
}
Write-Host "Anchor and image both found. Proceeding." -ForegroundColor Green

Write-Host "Step 3: Inserting wine types infographic after the hero..." -ForegroundColor Cyan
$posterBlock = @'
<div class="article-body">
            <div style="background:#111111;border:1px solid #2a2a2a;border-radius:16px;padding:20px;margin:0 0 40px;">
                <img src="/assets/types-of-wine.jpg" alt="Types of Wine - Still, Sparkling, Fortified, Dessert and Rose Wine Comparison" loading="lazy" width="800" height="575" style="width:100%;height:auto;display:block;border-radius:10px;">
                <p style="text-align:center;color:#888;font-size:0.85rem;margin-top:14px;margin-bottom:0;">Quick reference: the five core wine classifications by style, alcohol content, and taste.</p>
            </div>
'@
$articleNew = $articleContent.Replace($anchor, $posterBlock)

Write-Host "Step 4: Writing article back as clean UTF-8 (no BOM)..." -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($articlePath, $articleNew, $utf8NoBom)

Write-Host ""
Write-Host "===== VERIFICATION =====" -ForegroundColor Yellow
$check1 = Select-String -Path $articlePath -Pattern "types-of-wine.jpg"
if ($check1) {
    Write-Host "PASS: article contains the wine infographic image tag:" -ForegroundColor Green
    $check1 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "FAIL: image tag NOT found." -ForegroundColor Red
}

Write-Host ""
$mojibakePattern = [char]0x00E2 + [char]0x0080
$check2 = Select-String -Path $articlePath -SimpleMatch -Pattern $mojibakePattern
if ($check2) {
    Write-Host "FAIL: Mojibake detected in article:" -ForegroundColor Red
    $check2 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "PASS: No mojibake in article." -ForegroundColor Green
}

Write-Host ""
Write-Host "===== DONE =====" -ForegroundColor Yellow
Write-Host "If checks look right, run:"
Write-Host "  git add history-of-wine-world-wine-regions-guide.html assets\types-of-wine.jpg"
Write-Host "  git commit -m 'Add types of wine infographic to wine history article'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
