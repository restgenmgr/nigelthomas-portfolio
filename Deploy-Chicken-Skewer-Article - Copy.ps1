$ErrorActionPreference = "Stop"
$Repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$HtmlSource = Join-Path $env:USERPROFILE "Downloads\chicken-skewers-recipes.html"
$PosterSource = Join-Path $env:USERPROFILE "Downloads\chicken-skewers-black-gold.jpg"
$PageName = "chicken-skewers-recipes.html"
$PageUrl = "https://www.nigelthomas.live/$PageName"
$PosterName = "chicken-skewers-black-gold.jpg"

Write-Host "`n=== CHICKEN SKEWER ARTICLE: ONE-SHOT DEPLOY ===" -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $Repo ".git"))) { throw "Git repository not found: $Repo" }
if (-not (Test-Path $HtmlSource)) { throw "Missing $HtmlSource. Download the HTML file from this chat to Downloads first." }
if (-not (Test-Path $PosterSource)) { throw "Missing $PosterSource. Download the JPG poster from this chat to Downloads first." }
Set-Location $Repo

# Safety: do not overwrite a dirty working tree without a backup.
$dirty = git status --porcelain
if ($LASTEXITCODE -ne 0) { throw "Unable to read git status." }
if ($dirty) {
    Write-Host "Existing working-tree changes detected. They will not be discarded." -ForegroundColor Yellow
    git status --short
    throw "Commit/stash your existing changes first, then rerun. No files were changed by this script."
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir = Join-Path $Repo "_BACKUP_CHICKEN_SKEWERS_$stamp"
New-Item -ItemType Directory -Path $BackupDir | Out-Null
foreach ($f in @("sitemap.xml","blog.html","vercel.json")) {
    if (Test-Path (Join-Path $Repo $f)) { Copy-Item (Join-Path $Repo $f) (Join-Path $BackupDir $f) }
}
if (Test-Path (Join-Path $Repo $PageName)) { Copy-Item (Join-Path $Repo $PageName) (Join-Path $BackupDir $PageName) }

$Assets = Join-Path $Repo "assets"
New-Item -ItemType Directory -Path $Assets -Force | Out-Null
Copy-Item -LiteralPath $HtmlSource -Destination (Join-Path $Repo $PageName) -Force
Copy-Item -LiteralPath $PosterSource -Destination (Join-Path $Assets $PosterName) -Force

# Add URL to sitemap once, preserving existing XML entries and ordering.
$SitemapPath = Join-Path $Repo "sitemap.xml"
if (-not (Test-Path $SitemapPath)) { throw "sitemap.xml not found; stopping before commit." }
[xml]$xml = Get-Content -LiteralPath $SitemapPath -Raw
$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace("sm","http://www.sitemaps.org/schemas/sitemap/0.9")
$existing = $xml.SelectSingleNode("//sm:url[sm:loc='$PageUrl']", $ns)
if (-not $existing) {
    $urlNode = $xml.CreateElement("url", "http://www.sitemaps.org/schemas/sitemap/0.9")
    $locNode = $xml.CreateElement("loc", "http://www.sitemaps.org/schemas/sitemap/0.9")
    $locNode.InnerText = $PageUrl
    $lastNode = $xml.CreateElement("lastmod", "http://www.sitemaps.org/schemas/sitemap/0.9")
    $lastNode.InnerText = (Get-Date).ToString("yyyy-MM-dd")
    $freqNode = $xml.CreateElement("changefreq", "http://www.sitemaps.org/schemas/sitemap/0.9")
    $freqNode.InnerText = "monthly"
    $priorityNode = $xml.CreateElement("priority", "http://www.sitemaps.org/schemas/sitemap/0.9")
    $priorityNode.InnerText = "0.6"
    [void]$urlNode.AppendChild($locNode); [void]$urlNode.AppendChild($lastNode)
    [void]$urlNode.AppendChild($freqNode); [void]$urlNode.AppendChild($priorityNode)
    [void]$xml.DocumentElement.AppendChild($urlNode)
    $xml.Save($SitemapPath)
    Write-Host "Added URL to sitemap.xml" -ForegroundColor Green
} else { Write-Host "Sitemap URL already exists; no duplicate added." -ForegroundColor Yellow }

# Add the article to blog.html only if not already linked. Insert near the end of body, before closing body.
$BlogPath = Join-Path $Repo "blog.html"
if (Test-Path $BlogPath) {
    $blog = Get-Content -LiteralPath $BlogPath -Raw
    if ($blog -notmatch [regex]::Escape($PageName)) {
        $linkBlock = @"
<!-- NEW ARTICLE: Chicken Skewer Recipes -->
<section class="article-link chicken-skewer-article" style="max-width:1300px;margin:24px auto;padding:20px;border:1px solid #d4af37;background:#0a0a0a;color:#f5f2e8;border-radius:10px">
  <h2 style="color:#d4af37">6 Chicken Skewer Recipes</h2>
  <p>Sweet Chili Lime, Garlic Parmesan, Smoky Cajun, Lemon Herb, BBQ Ranch and Honey Garlic, with a free black-and-gold recipe poster.</p>
  <a href="/$PageName" style="display:inline-block;background:#d4af37;color:#0a0a0a;padding:10px 16px;text-decoration:none;font-weight:bold">Read the Recipes</a>
</section>
"@
        if ($blog -match '(?i)</main>') {
            $blog = [regex]::Replace($blog, '(?i)</main>', ($linkBlock + "`r`n</main>"), 1)
            Set-Content -LiteralPath $BlogPath -Value $blog -Encoding UTF8
            Write-Host "Added article link near the bottom of blog.html main content" -ForegroundColor Green
        } elseif ($blog -match '(?i)</body>') {
            $blog = [regex]::Replace($blog, '(?i)</body>', ($linkBlock + "`r`n</body>"), 1)
            Set-Content -LiteralPath $BlogPath -Value $blog -Encoding UTF8
            Write-Host "Added article link before blog.html closing body" -ForegroundColor Green
        } else { throw "blog.html has no closing main/body tag; stopping before commit." }
    } else { Write-Host "Article link already appears in blog.html." -ForegroundColor Yellow }
} else { throw "blog.html not found; stopping before commit." }

# Confirm requested related links appear at the bottom of the article.
$pagePath = Join-Path $Repo $PageName
$pageText = Get-Content -LiteralPath $pagePath -Raw
$related = @("chicken-nuggets-recipes.html","breakfast-snacks.html","buffet-food-temperature-guide.html","classic-snacks-recipes.html")
foreach ($r in $related) {
    if ($pageText -notmatch [regex]::Escape($r)) { throw "Required related link missing from article: $r" }
}

# Local preflight checks
if ($pageText -notmatch 'G-P839TWLQSJ') { throw "Expected GA4 ID not found in article." }
if ($pageText -notmatch 'chicken-skewers-black-gold.jpg') { throw "Poster image reference missing." }
if ($pageText -notmatch 'download=') { throw "Poster download link missing." }
if ($pageText -notmatch 'Infomatics: quick recipe') { throw "Infomatics disclosure missing." }
[xml](Get-Content -LiteralPath $SitemapPath -Raw) | Out-Null
Write-Host "`n=== PRE-COMMIT CHECKS ===" -ForegroundColor Cyan
Write-Host "Page bytes: $((Get-Item $pagePath).Length)"
Write-Host "Poster bytes: $((Get-Item (Join-Path $Assets $PosterName)).Length)"
Write-Host "Canonical: $PageUrl"
Write-Host "Sitemap XML: valid"
git status --short

# Stage only the three intended website files.
git add -- $PageName "assets/$PosterName" "sitemap.xml" "blog.html"
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check failed; review changes. No commit or push performed." }
git commit -m "Add chicken skewer recipes and downloadable poster"
if ($LASTEXITCODE -ne 0) { throw "Commit failed. Review git status; no push performed." }

# Safe normal push only; never force-push.
git pull --rebase --autostash origin main
if ($LASTEXITCODE -ne 0) { throw "Pull/rebase failed. Resolve safely before pushing; no force-push used." }
git push origin main
if ($LASTEXITCODE -ne 0) { throw "Push failed. Review git status and remote state." }

Write-Host "`n=== LIVE VERIFICATION ===" -ForegroundColor Cyan
Start-Sleep -Seconds 8
foreach ($url in @($PageUrl, "https://www.nigelthomas.live/assets/$PosterName", "https://www.nigelthomas.live/sitemap.xml", "https://www.nigelthomas.live/blog.html")) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        Write-Host "$($response.StatusCode) $url" -ForegroundColor Green
    } catch {
        Write-Host "CHECK FAILED: $url -- $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host "`nGSC: After live URL returns HTTP 200, open Search Console > URL Inspection, inspect $PageUrl, then select Request Indexing. Indexing is not guaranteed." -ForegroundColor Cyan
Write-Host "Backup folder: $BackupDir" -ForegroundColor Gray
