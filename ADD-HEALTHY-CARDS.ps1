# Adds the Healthy Daily Recipes card to kitchen-food.html and blog.html, then commits, pushes, verifies.
$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repo
$utf8 = New-Object System.Text.UTF8Encoding $false
$slug = "healthy-daily-recipes.html"
$bk = "C:\Users\admin\tools\card-backups"
New-Item -ItemType Directory -Force -Path $bk | Out-Null

git pull --rebase --autostash

$kfCard = @'

<div class="article-card">
<span class="badge">HEALTHY FOOD</span>
<h2><a href="healthy-daily-recipes.html">16 Healthy Daily Recipes: Simple Meals for Restaurants &amp; Home Kitchens</a></h2>
<p>Oats, omelette, quinoa bowl, lentil soup, baked fish, wraps, pasta and more &mdash; exact ingredients, methods, allergens and chef notes for 16 single-serve healthy meals, plus a free downloadable poster.</p>
<a class="read-more" href="healthy-daily-recipes.html">Read Article</a>
</div>

'@

$blogCard = @'

<div class="article-card">
<span class="badge">Newest</span>
<div class="article-title"><a href="healthy-daily-recipes.html">16 Healthy Daily Recipes: Simple Meals for Restaurants &amp; Home Kitchens</a></div>
<div class="article-excerpt">16 single-serve healthy meals with exact ingredients, methods, allergens and chef notes, plus a free downloadable poster.</div>
<a class="read-more-btn" href="healthy-daily-recipes.html">Read Article &rarr;</a>
</div>

'@

function Show-Context($text, $idx) {
    $s = [Math]::Max(0, $idx - 160)
    $len = [Math]::Min(320, $text.Length - $s)
    Write-Host "----- insertion point (<<HERE>>) -----" -ForegroundColor Yellow
    Write-Host ($text.Substring($s, $idx - $s) + "<<HERE>>" + $text.Substring($idx, [Math]::Min(160, $text.Length - $idx)))
    Write-Host "--------------------------------------" -ForegroundColor Yellow
}

# ---- kitchen-food.html : end of the article grid (before the </div> that precedes </main>) ----
$kf = Join-Path $repo "kitchen-food.html"
$t = [System.IO.File]::ReadAllText($kf, $utf8)
if ($t.Contains($slug)) { Write-Host "kitchen-food.html already has the card" -ForegroundColor Yellow }
elseif (-not $t.Contains("</main>")) { Write-Host "kitchen-food.html has no </main> - skipped" -ForegroundColor Red }
else {
    $idx = $t.LastIndexOf("</div>", $t.LastIndexOf("</main>"))
    Show-Context $t $idx
    if ((Read-Host "Insert card into kitchen-food.html here? (y/n)") -eq "y") {
        Copy-Item $kf (Join-Path $bk "kitchen-food.html.bak") -Force
        [System.IO.File]::WriteAllText($kf, $t.Insert($idx, $kfCard), $utf8)
        Write-Host "kitchen-food.html updated" -ForegroundColor Yellow
    }
}

# ---- blog.html : after the last END NEW CARD marker, else before the first existing card ----
$bl = Join-Path $repo "blog.html"
$t = [System.IO.File]::ReadAllText($bl, $utf8)
if ($t.Contains($slug)) { Write-Host "blog.html already has the card" -ForegroundColor Yellow }
else {
    $m = $t.LastIndexOf("<!-- END NEW CARD")
    if ($m -ge 0) {
        $eol = $t.IndexOf("`n", $m); if ($eol -lt 0) { $eol = $t.Length } else { $eol = $eol + 1 }
        $idx = $eol
    } else {
        $idx = $t.IndexOf('<div class="article-card">')
        if ($idx -lt 0) { $idx = $t.IndexOf('<article class="article-card">') }
    }
    if ($idx -lt 0) { Write-Host "blog.html: no anchor found - skipped" -ForegroundColor Red }
    else {
        Show-Context $t $idx
        if ((Read-Host "Insert card into blog.html here? (y/n)") -eq "y") {
            Copy-Item $bl (Join-Path $bk "blog.html.bak") -Force
            [System.IO.File]::WriteAllText($bl, $t.Insert($idx, $blogCard), $utf8)
            Write-Host "blog.html updated" -ForegroundColor Yellow
        }
    }
}

git add kitchen-food.html blog.html
git status --short
git diff --cached --stat
if ((Read-Host "Commit and push? (y/n)") -ne "y") { Write-Host "Stopped before commit." -ForegroundColor Red; exit 0 }
git commit -m "Add Healthy Daily Recipes card to kitchen-food and blog"
git pull --rebase
git push

Start-Sleep -Seconds 45
foreach ($u in @("https://www.nigelthomas.live/kitchen-food.html","https://www.nigelthomas.live/blog.html")) {
  try {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing
    Write-Host ("{0}  {1}  match={2}" -f $r.StatusCode, $u, ($r.Content -match [regex]::Escape($slug))) -ForegroundColor Yellow
  } catch { Write-Host ("FAIL {0}  {1}" -f $u, $_.Exception.Message) -ForegroundColor Red }
}
