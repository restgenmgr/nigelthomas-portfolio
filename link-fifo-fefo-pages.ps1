# link-fifo-fefo-pages.ps1
# Cross-links fifo-vs-fefo-poster.html and fifo-vs-fefo-stock-rotation-guide.html
# Run this from your site's repo root (where both files already exist locally).

$articlePath = Join-Path (Get-Location) "fifo-vs-fefo-stock-rotation-guide.html"
$posterPath  = Join-Path (Get-Location) "fifo-vs-fefo-poster.html"

if (-not (Test-Path $articlePath)) { Write-Error "Article file not found at $articlePath"; exit 1 }
if (-not (Test-Path $posterPath))  { Write-Error "Poster file not found at $posterPath"; exit 1 }

# ---------- 1. Add "Quick Visual Reference" callout to the ARTICLE ----------
$articleContent = [System.IO.File]::ReadAllText($articlePath)

$anchorText = '<h2>FIFO vs FEFO: The Core Difference</h2>'

$calloutHtml = @'
<div class="tip-box">
  <strong>Quick Visual Reference:</strong> Prefer a one-page visual breakdown? See the <a href="/fifo-vs-fefo-poster.html">FIFO vs FEFO poster</a> for the core rules at a glance.
</div>

<h2>FIFO vs FEFO: The Core Difference</h2>
'@

if ($articleContent -notmatch [regex]::Escape('/fifo-vs-fefo-poster.html')) {
    if ($articleContent -match [regex]::Escape($anchorText)) {
        $articleContent = $articleContent.Replace($anchorText, $calloutHtml)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($articlePath, $articleContent, $utf8NoBom)
        Write-Host "Article updated: poster link added." -ForegroundColor Green
    } else {
        Write-Warning "Anchor text not found in article — no changes made. Check the H2 wording."
    }
} else {
    Write-Host "Article already links to the poster — skipped." -ForegroundColor Yellow
}

# ---------- 2. Add "Read the Full Guide" link to the POSTER ----------
$posterContent = [System.IO.File]::ReadAllText($posterPath)

$bottomAnchor = '<!-- BOTTOM BRANDING -->'

$fullGuideHtml = @'
<div style="text-align:center; margin-bottom:20px; font-size:14px; color:#b8b8b8;">
  Want the full breakdown with stacking rules by category?
  <a href="/fifo-vs-fefo-stock-rotation-guide.html" style="color:#d4af37; font-weight:600;">Read the Full Guide &rarr;</a>
</div>

<!-- BOTTOM BRANDING -->
'@

if ($posterContent -notmatch [regex]::Escape('/fifo-vs-fefo-stock-rotation-guide.html')) {
    if ($posterContent -match [regex]::Escape($bottomAnchor)) {
        $posterContent = $posterContent.Replace($bottomAnchor, $fullGuideHtml)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($posterPath, $posterContent, $utf8NoBom)
        Write-Host "Poster updated: full guide link added." -ForegroundColor Green
    } else {
        Write-Warning "Anchor comment not found in poster — no changes made."
    }
} else {
    Write-Host "Poster already links to the article — skipped." -ForegroundColor Yellow
}

Write-Host "`nDone. Review both files, then run your usual deploy sequence:" -ForegroundColor Cyan
Write-Host "  git add fifo-vs-fefo-poster.html fifo-vs-fefo-stock-rotation-guide.html"
Write-Host "  git commit -m 'Cross-link FIFO/FEFO poster and article'"
Write-Host "  git push origin main"
Write-Host "  vercel --prod --force"
