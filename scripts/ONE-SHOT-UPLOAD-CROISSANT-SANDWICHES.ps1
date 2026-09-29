# ONE-SHOT UPLOAD: Croissant Sandwiches  (Windows PowerShell 5.1 safe; ASCII only)
$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$dl   = Join-Path $env:USERPROFILE "Downloads"
$utf8 = New-Object System.Text.UTF8Encoding $false
$page = "croissant-sandwiches.html"
$img  = "croissant-sandwiches.png"
$base = "https://www.nigelthomas.live"
Set-Location $repo

function Find-Local($name) {
  $p = Join-Path $repo $name; if (Test-Path $p) { return $p }
  $p = Join-Path $dl $name;   if (Test-Path $p) { return $p }
  $f = Get-ChildItem $dl -Recurse -Filter $name -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($f) { return $f.FullName }
  return $null
}

# 0. sync first
Write-Host "== Pull ==" -ForegroundColor Yellow
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) { throw "git pull failed - fix conflicts, then rerun" }

# 1. place page at repo root
$dstPage = Join-Path $repo $page
$fresh = Get-ChildItem $dl -Recurse -Filter $page -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($fresh) { Move-Item $fresh.FullName $dstPage -Force; Write-Host "Page copied from Downloads (overwrites repo copy)." -ForegroundColor Yellow }
elseif (-not (Test-Path $dstPage)) { throw "Cannot find $page in repo root or Downloads" }

# 2. poster into assets\
$assets = Join-Path $repo "assets"
if (-not (Test-Path $assets)) { New-Item -ItemType Directory $assets | Out-Null }
$dstImg = Join-Path $assets $img
$oldPre = Join-Path $assets "croissant-sandwitches.png"
if ((-not (Test-Path $dstImg)) -and (Test-Path $oldPre)) {
  if (git ls-files "assets/croissant-sandwitches.png") { git mv "assets/croissant-sandwitches.png" "assets/$img" } else { Move-Item $oldPre $dstImg -Force }
  Write-Host "Renamed old-spelling poster to $img" -ForegroundColor Yellow
}
if (-not (Test-Path $dstImg)) {
  $s = Find-Local $img
  if (-not $s) { throw "Cannot find $img anywhere" }
  Move-Item $s $dstImg -Force
}
$oldImg = Join-Path $assets "croissant-sandwitches.png"
if (Test-Path $oldImg) {
  if ((Get-FileHash $oldImg).Hash -eq (Get-FileHash $dstImg).Hash) {
    if (git ls-files "assets/croissant-sandwitches.png") { git rm -f "assets/croissant-sandwitches.png" | Out-Null } else { Remove-Item $oldImg -Force }
    Write-Host "Removed duplicate old-spelling poster." -ForegroundColor Yellow
  } else { Write-Host "Old-spelling poster differs from new one - left in place, check manually." -ForegroundColor Red }
}
Write-Host "Files placed: page + assets\$img" -ForegroundColor Yellow

# 3. sitemap.xml (dedupe)
$sm = Join-Path $repo "sitemap.xml"
$txt = [System.IO.File]::ReadAllText($sm, $utf8)
if ($txt -notmatch [regex]::Escape($page)) {
  $entry = "  <url>`n    <loc>$base/$page</loc>`n    <lastmod>2026-09-28</lastmod>`n    <changefreq>monthly</changefreq>`n    <priority>0.8</priority>`n  </url>`n"
  $txt = $txt.Insert($txt.LastIndexOf("</urlset>"), $entry)
  [System.IO.File]::WriteAllText($sm, $txt, $utf8)
  Write-Host "Sitemap entry added." -ForegroundColor Yellow
} else { Write-Host "Sitemap already has the page - skipped." -ForegroundColor Yellow }

# 4. blog.html card (dedupe; inserted as sibling after the LAST existing card, found dynamically)
$bp = Join-Path $repo "blog.html"
$blog = [System.IO.File]::ReadAllText($bp, $utf8)
if ($blog -notmatch [regex]::Escape($page)) {
  Copy-Item $bp (Join-Path $env:TEMP "blog.html.pre-croissant.bak") -Force
  $card = '<div class="article-card"><div class="article-title"><a href="croissant-sandwiches.html">Croissant Sandwiches: 6 Delicious Recipes for Hotels &amp; Cafes</a></div><div class="article-meta">Food &amp; Beverage Series</div><div class="article-excerpt">Six croissant sandwich recipes with quantities, assembly rules, food safety, allergen control and costing.</div><a class="read-more-btn" href="croissant-sandwiches.html">Read Article &rarr;</a><span class="badge">Newest</span></div>'
  $ms = [regex]::Matches($blog, '<(article|div)\s+class="[^"]*\barticle-card\b[^"]*"[^>]*>')
  if ($ms.Count -gt 0) {
    $last = $ms[$ms.Count - 1]; $end = -1
    if ($last.Groups[1].Value -eq "article") { $end = $blog.IndexOf("</article>", $last.Index) + 10 }
    else {
      $depth = 0
      foreach ($t in [regex]::Matches($blog.Substring($last.Index), '<div\b|</div>')) {
        if ($t.Value -eq "</div>") { $depth-- } else { $depth++ }
        if ($depth -eq 0) { $end = $last.Index + $t.Index + 6; break }
      }
    }
    if ($end -gt 0) {
      $blog = $blog.Insert($end, "`n" + $card)
      [System.IO.File]::WriteAllText($bp, $blog, $utf8)
      Write-Host "blog.html card added after last existing card." -ForegroundColor Yellow
    } else { Write-Host "Could not find card end - add card by hand (see snippets file)." -ForegroundColor Red }
  } else { Write-Host "No article-card found in blog.html - add card by hand." -ForegroundColor Red }
} else { Write-Host "blog.html already has the card - skipped." -ForegroundColor Yellow }

# 5. commit + push
git add $page "assets/$img" sitemap.xml blog.html
git commit -m "Add Croissant Sandwiches page, poster, blog card and sitemap entry"
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) { throw "second pull failed" }
git push
if ($LASTEXITCODE -ne 0) { throw "git push failed" }

# 6. verify git state
Write-Host "== Git verification ==" -ForegroundColor Yellow
git fetch origin
$loc = (git rev-parse HEAD).Trim(); $rem = (git rev-parse origin/main).Trim()
if ($loc -eq $rem) { Write-Host "OK: local HEAD == origin/main ($($loc.Substring(0,7)))" -ForegroundColor Green }
else { Write-Host "WARNING: local $($loc.Substring(0,7)) differs from origin/main $($rem.Substring(0,7))" -ForegroundColor Red }
git status -sb
git log --stat -1

# 7. verify live (retry while Vercel deploys)
Write-Host "== Live check ==" -ForegroundColor Yellow
$checks = @(
  @{ u = "$base/$page";               m = "Croissant Sandwiches" },
  @{ u = "$base/assets/$img";         m = $null },
  @{ u = "$base/sitemap.xml";         m = $page },
  @{ u = "$base/blog.html";           m = $page }
)
foreach ($c in $checks) {
  $ok = $false
  for ($i = 1; $i -le 4 -and -not $ok; $i++) {
    Start-Sleep -Seconds 15
    try {
      $r = Invoke-WebRequest -Uri ($c.u + "?v=" + (Get-Random)) -UseBasicParsing
      if ($r.StatusCode -eq 200 -and ((-not $c.m) -or ($r.Content -match [regex]::Escape($c.m)))) { $ok = $true }
    } catch { }
  }
  if ($ok) { Write-Host "OK    $($c.u)" -ForegroundColor Green } else { Write-Host "FAIL  $($c.u)" -ForegroundColor Red }
}
Write-Host "GSC URL to inspect and request indexing: $base/$page" -ForegroundColor Yellow
