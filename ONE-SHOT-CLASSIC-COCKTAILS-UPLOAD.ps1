$ErrorActionPreference = "Stop"
$repo = (Get-Location).Path
$package = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlSource = Join-Path $package "classic-cocktails-guide.html"
$posterSource = Join-Path $package "classic-cocktails-guide.jfif"

if (-not (Test-Path (Join-Path $repo ".git"))) { throw "Run this from the portfolio root: C:\Users\admin\Desktop\nigelthomas-portfolio" }
if (-not (Test-Path $htmlSource)) { throw "Missing new HTML file." }
if (-not (Test-Path $posterSource)) { throw "Missing poster JFIF." }

# Preserve the old page locally before replacing it.
$old = Join-Path $repo "classic-cocktails-guide.html"
if (Test-Path $old) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  Copy-Item $old (Join-Path $repo "classic-cocktails-guide-backup-$stamp.html") -Force
}

# Replace page and create the public poster URL asset.
Copy-Item $htmlSource $old -Force
$assets = Join-Path $repo "assets"
if (-not (Test-Path $assets)) { New-Item -ItemType Directory -Path $assets | Out-Null }
Copy-Item $posterSource (Join-Path $assets "classic-cocktails-guide.jfif") -Force

# Add a black/gold blog card if the URL is not already present.
$blog = Join-Path $repo "blog.html"
if (Test-Path $blog) {
  $b = Get-Content $blog -Raw -Encoding UTF8
  if ($b -notmatch "classic-cocktails-guide\.html") {
    $card = @'
<article class="blog-card">
  <div class="blog-card-content">
    <span class="blog-category">BARTENDING &amp; HOSPITALITY</span>
    <h2>Classic Cocktails Guide</h2>
    <p>Five iconic spirit families, classic cocktails, ingredients and garnish guidance for bartenders and hospitality professionals.</p>
    <a href="classic-cocktails-guide.html">Read the Guide →</a>
  </div>
</article>
'@
    if ($b -match "(?i)</main>") {
      $b = [regex]::Replace($b, "(?i)</main>", "$card`r`n</main>", 1)
    } elseif ($b -match "(?i)</body>") {
      $b = [regex]::Replace($b, "(?i)</body>", "$card`r`n</body>", 1)
    } else { throw "Could not safely locate </main> or </body> in blog.html." }
    [IO.File]::WriteAllText($blog,$b,[Text.UTF8Encoding]::new($false))
  }
}

# Sitemap: ONLY the NigelThomas.live URL belongs here.
$sitemap = Join-Path $repo "sitemap.xml"
if (Test-Path $sitemap) {
  $s = Get-Content $sitemap -Raw -Encoding UTF8
  $u = "https://www.nigelthomas.live/classic-cocktails-guide.html"
  if ($s -notmatch [regex]::Escape($u)) {
    $entry = "  <url>`r`n    <loc>$u</loc>`r`n    <changefreq>monthly</changefreq>`r`n    <priority>0.7</priority>`r`n  </url>"
    $s = $s -replace "(?i)</urlset>", "$entry`r`n</urlset>"
    [IO.File]::WriteAllText($sitemap,$s,[Text.UTF8Encoding]::new($false))
  }
}

# Stage ONLY the intended website changes.
git add classic-cocktails-guide.html assets/classic-cocktails-guide.jfif blog.html sitemap.xml
git status --short

Write-Host ""
Write-Host "The old page has been replaced locally and the new poster is ready." -ForegroundColor Green
Write-Host "Review the status above. Then run:"
Write-Host 'git commit -m "Replace classic cocktails guide with embedded poster"'
Write-Host 'git push origin main'
Write-Host ""
Write-Host "The poster GSC/image URL is:"
Write-Host "https://www.nigelthomas.live/assets/classic-cocktails-guide.jfif"
