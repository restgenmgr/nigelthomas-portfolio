$root = Get-Location
$sitemapPath = Join-Path $root "sitemap.xml"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$sitemap = [System.IO.File]::ReadAllText($sitemapPath, [System.Text.Encoding]::UTF8)

if ($sitemap -notmatch "restaurant-financial-kpis") {

    $sitemapEntries = @'
<url>
  <loc>https://www.nigelthomas.live/food-cost-basics.html</loc>
  <lastmod>2026-08-14</lastmod>
  <changefreq>monthly</changefreq>
  <priority>0.8</priority>
</url>
<url>
  <loc>https://www.nigelthomas.live/restaurant-financial-kpis.html</loc>
  <lastmod>2026-08-15</lastmod>
  <changefreq>monthly</changefreq>
  <priority>0.9</priority>
</url>
'@

    $sitemap = $sitemap -replace "</urlset>", ($sitemapEntries + "`r`n</urlset>")
    [System.IO.File]::WriteAllText($sitemapPath, $sitemap, $utf8NoBom)
    Write-Host "sitemap.xml updated." -ForegroundColor Green

} else {
    Write-Host "sitemap.xml already contains restaurant-financial-kpis — no change made." -ForegroundColor Yellow
}

Write-Host "`nVerification:" -ForegroundColor Cyan
Select-String -Path $sitemapPath -Pattern "food-cost-basics","restaurant-financial-kpis" | Select-Object LineNumber, Line