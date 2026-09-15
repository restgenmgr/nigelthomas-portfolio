# ONE-SHOT DEPLOY: Types of Sandwiches poster + article + blog + sitemap
# Run from C:\Users\admin\Desktop\nigelthomas-portfolio
# Command: powershell -ExecutionPolicy Bypass -File .\ONE-SHOT-TYPES-OF-SANDWICHES.ps1

$ErrorActionPreference = "Stop"
$Repo = (Get-Location).Path
$Page = "types-of-sandwiches.html"
$Poster = "types-of-sandwiches-poster.png"
$PosterPath = Join-Path $Repo $Poster
$AssetsDir = Join-Path $Repo "assets"
$AssetsPoster = Join-Path $AssetsDir $Poster
$PagePath = Join-Path $Repo $Page
$BlogPath = Join-Path $Repo "blog.html"
$SitemapPath = Join-Path $Repo "sitemap.xml"

if(-not (Test-Path $PosterPath)) {
    throw "Missing $Poster in the repository root. Put the supplied poster PNG beside this script and run again."
}
if(-not (Test-Path $BlogPath)) { throw "blog.html not found." }
if(-not (Test-Path $SitemapPath)) { throw "sitemap.xml not found." }
if(-not (Test-Path $AssetsDir)) { New-Item -ItemType Directory -Path $AssetsDir | Out-Null }

Copy-Item $PosterPath $AssetsPoster -Force

# The production HTML is supplied separately with this package.
$SourceHtml = Join-Path $Repo $Page
if(-not (Test-Path $SourceHtml)) {
    throw "Missing $Page. Copy the supplied HTML file into the repository root, then run this script."
}

# Verify that the article has the required embedded poster and single Infomatics toggle.
$h = [IO.File]::ReadAllText($SourceHtml,[Text.UTF8Encoding]::new($false))
if($h -notmatch 'data:image/png;base64,') { throw "Embedded poster data is missing from $Page." }
if(([regex]::Matches($h,'FREE POSTER DOWNLOAD')).Count -ne 1) { throw "Expected exactly one FREE POSTER DOWNLOAD control." }
if($h -notmatch 'assets/nat-headshot\.jpg') { throw "nat-headshot.jpg reference is missing." }

# Add blog card once.
$blog = [IO.File]::ReadAllText($BlogPath,[Text.UTF8Encoding]::new($false))
if($blog -notmatch [regex]::Escape($Page)) {
    $card = @'
<article class="blog-card">
  <div class="blog-card-content">
    <span class="blog-category">KITCHEN &amp; FOOD</span>
    <h2>Types of Sandwiches: Professional Kitchen Guide</h2>
    <p>A chef-led guide to sandwich classification, food safety, menu engineering, food cost, service standards and kitchen training, with a free downloadable poster.</p>
    <a href="types-of-sandwiches.html">Read Article</a>
  </div>
</article>
'@
    if($blog -match '(?i)</main>') {
        $blog = [regex]::Replace($blog,'(?i)</main>',"$card`r`n</main>",1)
    } elseif($blog -match '(?i)</body>') {
        $blog = [regex]::Replace($blog,'(?i)</body>',"$card`r`n</body>",1)
    } else {
        throw "Could not find </main> or </body> in blog.html."
    }
    [IO.File]::WriteAllText($BlogPath,$blog,[Text.UTF8Encoding]::new($false))
}

# Add sitemap URL once.
$sitemap = [IO.File]::ReadAllText($SitemapPath,[Text.UTF8Encoding]::new($false))
$Url = "https://www.nigelthomas.live/$Page"
if($sitemap -notmatch [regex]::Escape($Url)) {
    $entry = @"
  <url>
    <loc>$Url</loc>
    <lastmod>2026-09-14</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
"@
    if($sitemap -notmatch '(?i)</urlset>') { throw "sitemap.xml has no </urlset>." }
    $sitemap = [regex]::Replace($sitemap,'(?i)</urlset>',"$entry`r`n</urlset>",1)
    [IO.File]::WriteAllText($SitemapPath,$sitemap,[Text.UTF8Encoding]::new($false))
}

Write-Host ""
Write-Host "=== TYPES OF SANDWICHES DEPLOY PACKAGE READY ===" -ForegroundColor Green
Write-Host "Article : https://www.nigelthomas.live/$Page"
Write-Host "Poster  : https://www.nigelthomas.live/assets/$Poster"
Write-Host ""
Write-Host "=== VERIFY ===" -ForegroundColor Yellow
Write-Host "Article exists : $(Test-Path $PagePath)"
Write-Host "Poster exists  : $(Test-Path $AssetsPoster)"
Write-Host "Blog URL       : $((Select-String -Path $BlogPath -Pattern ([regex]::Escape($Page)) -Quiet))"
Write-Host "Sitemap URL    : $((Select-String -Path $SitemapPath -Pattern ([regex]::Escape($Url)) -Quiet))"
Write-Host "Poster toggle  : $(([regex]::Matches($h,'FREE POSTER DOWNLOAD')).Count)"
Write-Host ""
Write-Host "=== GIT ===" -ForegroundColor Yellow
git add $Page "assets\$Poster" "blog.html" "sitemap.xml"
git diff --cached --check
if($LASTEXITCODE -ne 0) { throw "git diff --cached --check failed." }
git status --short
Write-Host ""
Write-Host "Review the staged files, then run:" -ForegroundColor Cyan
Write-Host 'git commit -m "Add types of sandwiches kitchen poster guide"'
Write-Host 'git push origin main'
Write-Host ""
Write-Host "After Vercel deploys, submit this URL in Google Search Console:" -ForegroundColor Cyan
Write-Host $Url
