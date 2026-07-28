$path = Join-Path (Get-Location) "fb-cost-control-blueprint.html"

if (-not (Test-Path $path)) {
    Write-Host "ERROR: fb-cost-control-blueprint.html not found in current folder. Run this from nigelthomas-portfolio\" -ForegroundColor Red
    exit
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($path, $utf8NoBom)
$originalContent = $content

# 1. Fix broken headshot path (4 occurrences: og:image, JSON-LD image, JSON-LD unquoted variant, visible img tag)
$before = ($content | Select-String -Pattern "images/assets" -AllMatches).Matches.Count
$content = $content.Replace("https://www.nigelthomas.live/images/assets/nigel-thomas-headshot.jpg", "https://www.nigelthomas.live/assets/nigel-thomas-headshot.jpg")
$content = $content.Replace('/images/assets/nigel-thomas-headshot.jpg', '/assets/nigel-thomas-headshot.jpg')
$after = ($content | Select-String -Pattern "images/assets" -AllMatches).Matches.Count
Write-Host "Headshot path: fixed $($before - $after) of $before occurrences." -ForegroundColor Green

# 2. Add CSS for inline images + caption, right after .article-card block
$oldCss = @'
.article-card{
background:#111;
padding:50px;
border-radius:16px;
border-left:6px solid #d4af37;
box-shadow:0 8px 30px rgba(212,175,55,.10);
}
'@

$newCss = @'
.article-card{
background:#111;
padding:50px;
border-radius:16px;
border-left:6px solid #d4af37;
box-shadow:0 8px 30px rgba(212,175,55,.10);
}

.article-card img{width:100%;height:auto;display:block;border-radius:12px;margin:30px 0 8px;border:1px solid #2a2a2a;}

.img-caption{text-align:center;color:#888;font-size:0.85rem;margin-bottom:10px;font-style:italic;}
'@

if ($content -match [regex]::Escape(".article-card img{")) {
    Write-Host "CSS already present - skipping CSS insert." -ForegroundColor Yellow
} elseif ($content -notmatch [regex]::Escape($oldCss)) {
    Write-Host "WARNING: CSS anchor not found - skipping CSS insert." -ForegroundColor Yellow
} else {
    $content = $content.Replace($oldCss, $newCss)
    Write-Host "CSS block inserted." -ForegroundColor Green
}

# 3. Insert the image + caption before "Portion Discipline" heading
$oldAnchor = @'
</div>

<h2>1. Portion Discipline</h2>
'@

$newAnchor = @'
</div>

<img src="assets/f&amp;b-cost-control-blueprint.png" alt="F&amp;B cost control blueprint infographic showing five habits: portion discipline, true recipe costing, waste visibility, supplier accountability, and inventory rhythm">
<p class="img-caption">The five-habit blueprint for protecting F&amp;B margin &mdash; the same framework I bring into every property.</p>

<h2>1. Portion Discipline</h2>
'@

if ($content -match [regex]::Escape('f&amp;b-cost-control-blueprint.png')) {
    Write-Host "Blueprint image already present - skipping image insert." -ForegroundColor Yellow
} elseif ($content -notmatch [regex]::Escape($oldAnchor)) {
    Write-Host "WARNING: Image insertion anchor not found - skipping image insert." -ForegroundColor Yellow
} else {
    $content = $content.Replace($oldAnchor, $newAnchor)
    Write-Host "Image + caption inserted." -ForegroundColor Green
}

if ($content -eq $originalContent) {
    Write-Host "No changes were made to the file." -ForegroundColor Red
} else {
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "`nFile updated and saved." -ForegroundColor Cyan
    Write-Host "Next: git add . ; git commit -m 'Insert blueprint image, fix headshot path' ; git push origin main ; vercel --prod --force" -ForegroundColor Cyan
}
