$path = ".\fb-cost-control-blueprint.html"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($path, $utf8NoBom)

# 1. Add CSS for inline images + caption, right after .article-card block
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

if ($content -notmatch [regex]::Escape($oldCss)) {
    Write-Host "WARNING: CSS anchor not found - file may already be edited or has diverged. Aborting CSS insert." -ForegroundColor Yellow
} else {
    $content = $content.Replace($oldCss, $newCss)
    Write-Host "CSS block inserted." -ForegroundColor Green
}

# 2. Insert the image + caption before "Portion Discipline" heading
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

if ($content -notmatch [regex]::Escape($oldAnchor)) {
    Write-Host "WARNING: Image insertion anchor not found - aborting image insert." -ForegroundColor Yellow
} else {
    $content = $content.Replace($oldAnchor, $newAnchor)
    Write-Host "Image + caption inserted." -ForegroundColor Green
}

[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
Write-Host "Done. Review the file, then git add / commit / push / vercel --prod --force." -ForegroundColor Cyan
