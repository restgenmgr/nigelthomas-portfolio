# ONE-SHOT: deploy Healthy Daily Recipes page
$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo
$utf8 = New-Object System.Text.UTF8Encoding $false
$slug = "healthy-daily-recipes.html"

git pull --rebase --autostash

# 1. locate page (repo root first, then Downloads)
$page = Join-Path $repo $slug
$dl   = Join-Path $env:USERPROFILE "Downloads\$slug"
if (-not (Test-Path $page)) {
    if (Test-Path $dl) { Copy-Item $dl $page -Force } else { Write-Host "$slug not found in repo root or Downloads" -ForegroundColor Red; exit 1 }
}
$poster = Join-Path $repo "assets\healthy-daily-recipes.jpg"
if (-not (Test-Path $poster)) { Write-Host "assets\healthy-daily-recipes.jpg missing" -ForegroundColor Red; exit 1 }
$pt = [System.IO.File]::ReadAllText($page, $utf8)
Write-Host ("Page found. Poster embedded: " + $pt.Contains("data:image/jpeg;base64,")) -ForegroundColor Yellow

# 2. sitemap.xml
$sm = Join-Path $repo "sitemap.xml"
$smText = [System.IO.File]::ReadAllText($sm, $utf8)
if ($smText -notmatch [regex]::Escape("/healthy-daily-recipes.html")) {
    $entry = "  <url>`n    <loc>https://www.nigelthomas.live/healthy-daily-recipes.html</loc>`n    <lastmod>2026-09-30</lastmod>`n  </url>`n"
    $idx = $smText.LastIndexOf("</urlset>")
    $smText = $smText.Insert($idx, $entry)
    [System.IO.File]::WriteAllText($sm, $smText, $utf8)
    Write-Host "sitemap.xml updated" -ForegroundColor Yellow
} else { Write-Host "sitemap.xml already has entry" -ForegroundColor Yellow }

# 3. kitchen-food.html card (only if it uses the same article-grid layout as beverage.html)
$kf = Join-Path $repo "kitchen-food.html"
$kfText = [System.IO.File]::ReadAllText($kf, $utf8)
if ($kfText -match [regex]::Escape($slug)) {
    Write-Host "kitchen-food.html already has card" -ForegroundColor Yellow
} elseif ($kfText -match 'class="article-grid"' -and $kfText.Contains("</main>")) {
    $card = @'

<div class="article-card">
<span class="badge">HEALTHY FOOD</span>
<h2>
<a href="healthy-daily-recipes.html">
16 Healthy Daily Recipes: Simple Meals for Restaurants &amp; Home Kitchens
</a>
</h2>
<p>
Oats, omelette, quinoa bowl, lentil soup, baked fish, wraps, pasta and more &mdash; exact ingredients, methods, allergens and chef notes for 16 single-serve healthy meals, plus a free downloadable poster.
</p>
<a class="read-more" href="healthy-daily-recipes.html">Read Article</a>
</div>
'@
    $mainIdx = $kfText.LastIndexOf("</main>")
    $gridClose = $kfText.LastIndexOf("</div>", $mainIdx)
    $kfText = $kfText.Insert($gridClose, $card + "`n")
    [System.IO.File]::WriteAllText($kf, $kfText, $utf8)
    Write-Host "kitchen-food.html card added" -ForegroundColor Yellow
} else {
    Write-Host "kitchen-food.html layout differs - card NOT added (paste healthy-daily-recipes-cards.txt manually)" -ForegroundColor Red
}

# 4. review, confirm, commit, push
git add healthy-daily-recipes.html sitemap.xml kitchen-food.html assets/healthy-daily-recipes.jpg
git status --short
git diff --cached --stat
$ok = Read-Host "Commit and push? (y/n)"
if ($ok -ne "y") { Write-Host "Stopped before commit." -ForegroundColor Red; exit 0 }
git commit -m "Add Healthy Daily Recipes article + poster, sitemap, kitchen-food card"
git pull --rebase
git push

# 5. verify live
Start-Sleep -Seconds 45
$checks = @(
 @{u="https://www.nigelthomas.live/healthy-daily-recipes.html"; m="16 Healthy Daily Recipes"},
 @{u="https://www.nigelthomas.live/assets/healthy-daily-recipes.jpg"; m=$null},
 @{u="https://www.nigelthomas.live/sitemap.xml"; m="healthy-daily-recipes.html"},
 @{u="https://www.nigelthomas.live/kitchen-food.html"; m="healthy-daily-recipes.html"}
)
foreach ($c in $checks) {
  try {
    $r = Invoke-WebRequest -Uri $c.u -UseBasicParsing
    $hit = if ($c.m) { $r.Content -match [regex]::Escape($c.m) } else { "n/a" }
    Write-Host ("{0}  {1}  match={2}" -f $r.StatusCode, $c.u, $hit) -ForegroundColor Yellow
  } catch { Write-Host ("FAIL {0}  {1}" -f $c.u, $_.Exception.Message) -ForegroundColor Red }
}
