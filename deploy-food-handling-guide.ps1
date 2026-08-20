<#
  deploy-food-handling-guide.ps1
  One-shot deploy: self-contained article page (poster embedded as base64) + blog.html card + sitemap.xml entry
  Run this FROM the folder that contains:
    - food-handling-guide-poster.html   (poster is embedded inline — no separate image file needed)
    - sitemap-entry-snippet.xml
    - blog-card-snippet.html
#>

$ErrorActionPreference = "Stop"

$repoPath    = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$packagePath = $PSScriptRoot

Write-Host "== Step 1: Verify source files ==" -ForegroundColor Cyan
$requiredFiles = @(
  "$packagePath\food-handling-guide-poster.html",
  "$packagePath\sitemap-entry-snippet.xml",
  "$packagePath\blog-card-snippet.html"
)
foreach ($f in $requiredFiles) {
  if (-not (Test-Path $f)) { throw "Missing required file: $f" }
}
$htmlSize = (Get-Item "$packagePath\food-handling-guide-poster.html").Length
if ($htmlSize -lt 250000) { throw "food-handling-guide-poster.html looks too small ($htmlSize bytes) - the embedded poster image may be missing. Aborting." }
Write-Host "All source files present. Article HTML is $htmlSize bytes (poster embedded inline)." -ForegroundColor Green

Write-Host "`n== Step 2: Sync repo ==" -ForegroundColor Cyan
Set-Location $repoPath
git pull --rebase

Write-Host "`n== Step 3: Copy self-contained article page into repo ==" -ForegroundColor Cyan
Copy-Item "$packagePath\food-handling-guide-poster.html" "$repoPath\food-handling-guide-poster.html" -Force

# Re-write as UTF8 no-BOM per established encoding standard
$htmlContent = Get-Content "$repoPath\food-handling-guide-poster.html" -Raw
[System.IO.File]::WriteAllText(
  "$repoPath\food-handling-guide-poster.html",
  $htmlContent,
  (New-Object System.Text.UTF8Encoding $false)
)

Write-Host "`n== Step 4: Insert blog.html card ==" -ForegroundColor Cyan
$blogPath = "$repoPath\blog.html"
$blogContent = Get-Content $blogPath -Raw
$anchor = "<!-- END NEW CARD -->"
$anchorCount = ([regex]::Matches($blogContent, [regex]::Escape($anchor))).Count
if ($anchorCount -eq 0) {
  Write-Warning "Anchor '$anchor' not found in blog.html. Skipping auto-insert - add the card from blog-card-snippet.html manually (note: it references assets/food-handling-guide-poster.jpg for the thumbnail - upload that separately if you want a distinct thumbnail, or point it at the article page instead)."
} else {
  $cardSnippet = Get-Content "$packagePath\blog-card-snippet.html" -Raw
  $idx = $blogContent.IndexOf($anchor)
  $newBlogContent = $blogContent.Insert($idx, $cardSnippet)
  [System.IO.File]::WriteAllText($blogPath, $newBlogContent, (New-Object System.Text.UTF8Encoding $false))
  Write-Host "Card inserted into blog.html." -ForegroundColor Green
}

Write-Host "`n== Step 5: Insert sitemap.xml entry ==" -ForegroundColor Cyan
$sitemapPath = "$repoPath\sitemap.xml"
$sitemapContent = Get-Content $sitemapPath -Raw
$closeTag = "</urlset>"
$closeCount = ([regex]::Matches($sitemapContent, [regex]::Escape($closeTag))).Count
if ($closeCount -ne 1) {
  throw "Expected exactly one </urlset> in sitemap.xml, found $closeCount. Aborting to avoid corrupting the file."
}
$entrySnippet = Get-Content "$packagePath\sitemap-entry-snippet.xml" -Raw
$newSitemapContent = $sitemapContent.Replace($closeTag, "$entrySnippet$closeTag")
[System.IO.File]::WriteAllText($sitemapPath, $newSitemapContent, (New-Object System.Text.UTF8Encoding $false))
Write-Host "sitemap.xml updated." -ForegroundColor Green

Write-Host "`n== Step 6: Commit and push ==" -ForegroundColor Cyan
git add food-handling-guide-poster.html blog.html sitemap.xml
git commit -m "Add self-contained Food Handling Guide poster page (inline image), blog card, sitemap entry"
git pull --rebase
git push

Write-Host "`n== Step 7: Deploy to Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "`n== Step 8: Verify live ==" -ForegroundColor Cyan
Start-Sleep -Seconds 8
$cacheBust = Get-Date -UFormat %s
try {
  $resp = Invoke-WebRequest -Uri "https://www.nigelthomas.live/food-handling-guide-poster.html?v=$cacheBust" -UseBasicParsing
  Write-Host "Article page status: $($resp.StatusCode), size: $($resp.RawContentLength) bytes" -ForegroundColor Green
} catch {
  Write-Warning "Verification request failed - check manually: $_"
}

Write-Host "`nDONE. Live URL:" -ForegroundColor Cyan
Write-Host "https://www.nigelthomas.live/food-handling-guide-poster.html" -ForegroundColor Yellow
Write-Host "`nSubmit this URL in Google Search Console > URL Inspection > Request Indexing." -ForegroundColor Yellow
