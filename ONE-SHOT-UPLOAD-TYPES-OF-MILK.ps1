# ONE-SHOT: deploy Types of Milk page (run from anywhere)
$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo
$utf8 = New-Object System.Text.UTF8Encoding $false
$slug = "types-of-milk.html"

git pull --rebase --autostash

# 1. locate the page (repo root first, then Downloads)
$page = Join-Path $repo $slug
$dl   = Join-Path $env:USERPROFILE "Downloads\$slug"
if (-not (Test-Path $page)) {
    if (Test-Path $dl) { Copy-Item $dl $page -Force } else { Write-Host "types-of-milk.html not found in repo root or Downloads" -ForegroundColor Red; exit 1 }
}
$poster = Join-Path $repo "assets\types-of-milk.jpg"
if (-not (Test-Path $poster)) { Write-Host "assets\types-of-milk.jpg missing - move poster first" -ForegroundColor Red; exit 1 }
Write-Host "Page + poster found" -ForegroundColor Yellow

# 2. sitemap.xml (skip if already present)
$sm = Join-Path $repo "sitemap.xml"
$smText = [System.IO.File]::ReadAllText($sm, $utf8)
if ($smText -notmatch [regex]::Escape("/types-of-milk.html")) {
    $entry = "  <url>`n    <loc>https://www.nigelthomas.live/types-of-milk.html</loc>`n    <lastmod>2026-09-30</lastmod>`n  </url>`n"
    $idx = $smText.LastIndexOf("</urlset>")
    $smText = $smText.Insert($idx, $entry)
    [System.IO.File]::WriteAllText($sm, $smText, $utf8)
    Write-Host "sitemap.xml updated" -ForegroundColor Yellow
} else { Write-Host "sitemap.xml already has entry" -ForegroundColor Yellow }

# 3. beverage.html card (skip if already present; inserted as last card in the grid)
$bv = Join-Path $repo "beverage.html"
$bvText = [System.IO.File]::ReadAllText($bv, $utf8)
if ($bvText -notmatch [regex]::Escape("types-of-milk.html")) {
    $card = @'

<div class="article-card">
<span class="badge">BEVERAGE</span>
<h2>
<a href="types-of-milk.html">
Types of Milk &amp; Their Uses in Restaurant &amp; Caf&eacute;
</a>
</h2>
<p>
Low-fat, skim, lactose-free, soy, almond, oat, rice, coconut, evaporated, condensed, goat, buttermilk, flavoured and barista plant milks &mdash; characteristics, best uses, allergen and storage tips, plus a free downloadable poster.
</p>
<a class="read-more" href="types-of-milk.html">Read Article</a>
</div>
'@
    $mainIdx = $bvText.LastIndexOf("</main>")
    $gridClose = $bvText.LastIndexOf("</div>", $mainIdx)
    $bvText = $bvText.Insert($gridClose, $card + "`n")
    [System.IO.File]::WriteAllText($bv, $bvText, $utf8)
    Write-Host "beverage.html card added" -ForegroundColor Yellow
} else { Write-Host "beverage.html already has card" -ForegroundColor Yellow }

# 4. review + commit + push
git add types-of-milk.html sitemap.xml beverage.html assets/types-of-milk.jpg
git status --short
git diff --cached --stat
$ok = Read-Host "Commit and push? (y/n)"
if ($ok -ne "y") { Write-Host "Stopped before commit." -ForegroundColor Red; exit 0 }
git commit -m "Add Types of Milk article + poster, sitemap, beverage card"
git pull --rebase
git push

# 5. verify live
Start-Sleep -Seconds 45
$checks = @(
 @{u="https://www.nigelthomas.live/types-of-milk.html"; m="Types of Milk"},
 @{u="https://www.nigelthomas.live/assets/types-of-milk.jpg"; m=$null},
 @{u="https://www.nigelthomas.live/sitemap.xml"; m="types-of-milk.html"},
 @{u="https://www.nigelthomas.live/beverage.html"; m="types-of-milk.html"}
)
foreach ($c in $checks) {
  try {
    $r = Invoke-WebRequest -Uri $c.u -UseBasicParsing
    $hit = if ($c.m) { $r.Content -match [regex]::Escape($c.m) } else { "n/a" }
    Write-Host ("{0}  {1}  match={2}" -f $r.StatusCode, $c.u, $hit) -ForegroundColor Yellow
  } catch { Write-Host ("FAIL {0}  {1}" -f $c.u, $_.Exception.Message) -ForegroundColor Red }
}
