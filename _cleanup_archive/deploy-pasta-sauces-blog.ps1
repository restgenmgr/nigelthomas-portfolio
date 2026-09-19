# deploy-pasta-sauces-blog.ps1
# Run from C:\Users\admin\Desktop\nigelthomas-portfolio
# Adds the new pasta sauces blog post, its image, and sitemap entry, then deploys.

$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo

# 1. Always rebase first to avoid divergence
git pull --rebase

# 2. Copy the new files into place (adjust source paths to wherever you saved the
#    downloaded files from this chat, e.g. C:\Users\admin\Downloads)
$src = "$env:USERPROFILE\Downloads"

Copy-Item "$src\types-of-pasta-sauces.html" "$repo\types-of-pasta-sauces.html" -Force
Copy-Item "$src\types-of-pasta-sauces.jpg" "$repo\assets\types-of-pasta-sauces.jpg" -Force

# 3. Verify the files landed and are non-trivial in size (matches your standard
#    minimum-file-size safety check pattern)
foreach ($f in @(
    "$repo\types-of-pasta-sauces.html",
    "$repo\assets\types-of-pasta-sauces.jpg"
)) {
    if (-not (Test-Path $f)) { throw "Missing file: $f" }
    $size = (Get-Item $f).Length
    if ($size -lt 1000) { throw "Suspiciously small file (possible corruption): $f ($size bytes)" }
    Write-Host "OK: $f ($size bytes)"
}

# 4. Insert the sitemap entry before </urlset> (anchor-count safety check first)
$sitemapPath = "$repo\sitemap.xml"
$sitemap = Get-Content $sitemapPath -Raw
$anchor = "</urlset>"
$anchorCount = ([regex]::Matches($sitemap, [regex]::Escape($anchor))).Count
if ($anchorCount -ne 1) { throw "Expected exactly 1 </urlset> anchor, found $anchorCount. Aborting to avoid corrupting sitemap.xml." }

$newEntry = @"
  <url>
    <loc>https://www.nigelthomas.live/types-of-pasta-sauces.html</loc>
    <lastmod>2026-08-20</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
$anchor
"@

$updatedSitemap = $sitemap -replace [regex]::Escape($anchor), $newEntry

# Write with UTF8, no BOM (required — Set-Content causes mojibake)
[System.IO.File]::WriteAllText($sitemapPath, $updatedSitemap, (New-Object System.Text.UTF8Encoding $false))
Write-Host "sitemap.xml updated."

# 5. Manually add the card to blog.html using blog-card-snippet.html as reference
#    (insert above the relevant <!-- END NEW CARD N --> marker, then bump the number)
Write-Host "REMINDER: manually insert blog-card-snippet.html content into blog.html, then commit."

# 6. Stage, commit, push
git add types-of-pasta-sauces.html assets\types-of-pasta-sauces.jpg sitemap.xml blog.html
git commit -m "Add: Top 5 Classic Pasta Sauces blog post, image, sitemap entry, blog card"
git push

# 7. Deploy
vercel --prod --force

# 8. Post-deploy verification (cache-busted)
$check = Invoke-WebRequest -Uri "https://www.nigelthomas.live/types-of-pasta-sauces.html?v=$(Get-Date -UFormat %s)" -UseBasicParsing
if ($check.StatusCode -eq 200) {
    Write-Host "Live check OK: 200"
} else {
    Write-Host "Live check returned status $($check.StatusCode)"
}
