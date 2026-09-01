$path = Join-Path (Get-Location) "fb-cost-control-blueprint.html"

if (-not (Test-Path $path)) {
    Write-Host "ERROR: fb-cost-control-blueprint.html not found in current folder. Run this from nigelthomas-portfolio\" -ForegroundColor Red
    exit
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$raw = [System.IO.File]::ReadAllText($path, $utf8NoBom)

# Normalize to LF for reliable matching, remember to restore CRLF on save
$content = $raw.Replace("`r`n", "`n")
$originalContent = $content

# 1. CSS insert (skip if already present)
if ($content -match [regex]::Escape(".article-card img{")) {
    Write-Host "CSS already present - skipping." -ForegroundColor Yellow
} else {
    $cssPattern = [regex]::Escape(".article-card{`nbackground:#111;`npadding:50px;`nborder-radius:16px;`nborder-left:6px solid #d4af37;`nbox-shadow:0 8px 30px rgba(212,175,55,.10);`n}")
    $cssReplacement = ".article-card{`nbackground:#111;`npadding:50px;`nborder-radius:16px;`nborder-left:6px solid #d4af37;`nbox-shadow:0 8px 30px rgba(212,175,55,.10);`n}`n`n.article-card img{width:100%;height:auto;display:block;border-radius:12px;margin:30px 0 8px;border:1px solid #2a2a2a;}`n`n.img-caption{text-align:center;color:#888;font-size:0.85rem;margin-bottom:10px;font-style:italic;}"
    if ($content -match $cssPattern) {
        $content = [regex]::Replace($content, $cssPattern, { param($m) $cssReplacement }, 1)
        Write-Host "CSS block inserted." -ForegroundColor Green
    } else {
        Write-Host "WARNING: CSS anchor still not found." -ForegroundColor Red
    }
}

# 2. Image insert (skip if already present)
if ($content -match [regex]::Escape('f&amp;b-cost-control-blueprint.png')) {
    Write-Host "Blueprint image already present - skipping." -ForegroundColor Yellow
} else {
    $imgPattern = [regex]::Escape("</div>`n`n<h2>1. Portion Discipline</h2>")
    $imgReplacement = "</div>`n`n<img src=`"assets/f&amp;b-cost-control-blueprint.png`" alt=`"F&amp;B cost control blueprint infographic showing five habits: portion discipline, true recipe costing, waste visibility, supplier accountability, and inventory rhythm`">`n<p class=`"img-caption`">The five-habit blueprint for protecting F&amp;B margin &mdash; the same framework I bring into every property.</p>`n`n<h2>1. Portion Discipline</h2>"
    if ($content -match $imgPattern) {
        $content = [regex]::Replace($content, $imgPattern, { param($m) $imgReplacement }, 1)
        Write-Host "Image + caption inserted." -ForegroundColor Green
    } else {
        Write-Host "WARNING: Image anchor still not found." -ForegroundColor Red
    }
}

if ($content -eq $originalContent) {
    Write-Host "No changes were made to the file." -ForegroundColor Red
} else {
    # Restore CRLF line endings before saving
    $finalContent = $content.Replace("`n", "`r`n")
    [System.IO.File]::WriteAllText($path, $finalContent, $utf8NoBom)
    Write-Host "`nFile updated and saved." -ForegroundColor Cyan
    Write-Host "Next: git add . ; git commit -m 'Insert blueprint image, fix headshot path' ; git push origin main ; vercel --prod --force" -ForegroundColor Cyan
}
