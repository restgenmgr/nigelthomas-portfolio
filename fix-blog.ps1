$ErrorActionPreference = "Stop"

Write-Host "Step 1: Restoring clean blog.html from commit d26d780..." -ForegroundColor Cyan
git checkout d26d780 -- blog.html

Write-Host "Step 2: Reading file as UTF-8..." -ForegroundColor Cyan
$path = Join-Path (Get-Location) "blog.html"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

Write-Host "Step 3: Checking anchor text exists before replacing..." -ForegroundColor Cyan
$navAnchor = '<a href="/blog.html">Blog</a>'
$headingAnchor = '<h2 class="section-title">Featured Articles</h2>'

if (-not $content.Contains($navAnchor)) {
    Write-Host "ERROR: Nav anchor not found. Aborting without changes." -ForegroundColor Red
    exit 1
}
if (-not $content.Contains($headingAnchor)) {
    Write-Host "ERROR: Heading anchor not found. Aborting without changes." -ForegroundColor Red
    exit 1
}

Write-Host "Both anchors found. Proceeding with replacement." -ForegroundColor Green

Write-Host "Step 4: Adding Tools link to nav..." -ForegroundColor Cyan
$navNew = '<a href="/hospitality-management-tools.html">Tools</a>' + "`n`n" + $navAnchor
$content = $content.Replace($navAnchor, $navNew)

Write-Host "Step 5: Adding both article cards..." -ForegroundColor Cyan
$blogCards = '<h2 class="section-title">Featured Articles</h2>' + "`n`n" + @'
<div class="article-card">
<span class="badge">Newest</span>
<h2 class="article-title">
<a href="/general-manager-vs-hotel-manager.html">General Manager vs Hotel Manager: Complete Career Guide</a>
</h2>
<div class="article-meta">July 2026</div>
<p>Understand the key differences, responsibilities, career paths, and current GM and Hotel Manager openings in hospitality leadership.</p>
<a class="read-more-btn" href="/general-manager-vs-hotel-manager.html">Read Article &rarr;</a>
</div>

<div class="article-card">
<span class="badge">Tools</span>
<h2 class="article-title">
<a href="/hospitality-management-tools.html">Free Hospitality Management Tools &amp; Calculators</a>
</h2>
<div class="article-meta">9 Free Calculators</div>
<p>Instant calculators for food cost, ADR, RevPAR, occupancy, labour cost, break-even, GOPPAR, and menu engineering &mdash; no sign-up required.</p>
<a class="read-more-btn" href="/hospitality-management-tools.html">Open Tools &rarr;</a>
</div>
'@

$content = $content.Replace($headingAnchor, $blogCards)

Write-Host "Step 6: Writing file back as clean UTF-8 (no BOM)..." -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

Write-Host ""
Write-Host "===== VERIFICATION =====" -ForegroundColor Yellow

$check1 = Select-String -Path $path -Pattern "general-manager-vs-hotel-manager|hospitality-management-tools"
if ($check1) {
    Write-Host "PASS: Found both new links:" -ForegroundColor Green
    $check1 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "FAIL: New links NOT found. Something went wrong." -ForegroundColor Red
}

Write-Host ""
$mojibakePattern = [char]0x00E2 + [char]0x0080  # matches the 'â€' mojibake sequence
$check2 = Select-String -Path $path -SimpleMatch -Pattern $mojibakePattern
if ($check2) {
    Write-Host "FAIL: Mojibake corruption detected:" -ForegroundColor Red
    $check2 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "PASS: No mojibake corruption found." -ForegroundColor Green
}

Write-Host ""
Write-Host "===== DONE =====" -ForegroundColor Yellow
Write-Host "If both checks above say PASS, run:"
Write-Host "  git add blog.html"
Write-Host "  git commit -m 'Restore clean blog.html and add both article cards plus Tools nav link'"
Write-Host "  git push origin main"
