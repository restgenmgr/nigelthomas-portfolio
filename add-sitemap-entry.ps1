$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repoPath

$path = "sitemap.xml"
$content = Get-Content $path -Raw

if ($content -match "coffee-shop-vocabulary") {
    Write-Host "Already present - nothing to do." -ForegroundColor Yellow
} else {
    $newBlock = "  <url>`r`n    <loc>https://www.nigelthomas.live/coffee-shop-vocabulary.html</loc>`r`n    <lastmod>2026-08-19</lastmod>`r`n    <changefreq>monthly</changefreq>`r`n    <priority>0.7</priority>`r`n  </url>`r`n</urlset>"
    $updated = $content -replace '</urlset>', $newBlock
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $updated, $utf8NoBom)
    Write-Host "Write attempted." -ForegroundColor Green
}

Write-Host "== Tail of file now: ==" -ForegroundColor Cyan
Get-Content $path -Tail 8