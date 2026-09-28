# ONE-SHOT UPLOAD: Classic Snacks Recipes  (run from anywhere; ASCII only, UTF-8 no BOM)
$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$dl = Join-Path $env:USERPROFILE "Downloads"
$utf8 = New-Object System.Text.UTF8Encoding $false
Set-Location $repo
function Find-File($name) {
  foreach ($d in @($repo, $dl)) { $p = Join-Path $d $name; if (Test-Path $p) { return $p } }
  throw "Missing $name in repo root or Downloads"
}
$html = Find-File "classic-snacks-recipes.html"
$jpg  = Find-File "classic-snacks-recipes.jpg"
if ($html -ne (Join-Path $repo "classic-snacks-recipes.html")) { Copy-Item $html (Join-Path $repo "classic-snacks-recipes.html") -Force }
if (-not (Test-Path (Join-Path $repo "assets"))) { New-Item -ItemType Directory (Join-Path $repo "assets") | Out-Null }
Copy-Item $jpg (Join-Path $repo "assets\classic-snacks-recipes.jpg") -Force
if ($jpg -eq (Join-Path $repo "classic-snacks-recipes.jpg")) { Remove-Item $jpg -Force }
Write-Host "Files placed." -ForegroundColor Yellow

# sitemap.xml (skip if already present)
$sm = Join-Path $repo "sitemap.xml"
$txt = [System.IO.File]::ReadAllText($sm, $utf8)
if ($txt -notmatch "classic-snacks-recipes\.html") {
  $entry = "  <url>`n    <loc>https://www.nigelthomas.live/classic-snacks-recipes.html</loc>`n    <lastmod>2026-09-28</lastmod>`n    <changefreq>monthly</changefreq>`n    <priority>0.8</priority>`n  </url>`n"
  $idx = $txt.LastIndexOf("</urlset>")
  $txt = $txt.Insert($idx, $entry)
  [System.IO.File]::WriteAllText($sm, $txt, $utf8)
  Write-Host "Sitemap entry added." -ForegroundColor Yellow
} else { Write-Host "Sitemap already has the page - skipped." -ForegroundColor Yellow }

git pull --rebase --autostash
git add classic-snacks-recipes.html assets/classic-snacks-recipes.jpg sitemap.xml
git commit -m "Add Classic Snacks Recipes page, poster and sitemap entry"
git push

Start-Sleep -Seconds 25
foreach ($u in @("https://www.nigelthomas.live/classic-snacks-recipes.html","https://www.nigelthomas.live/assets/classic-snacks-recipes.jpg","https://www.nigelthomas.live/sitemap.xml")) {
  try { $r = Invoke-WebRequest -Uri $u -UseBasicParsing; Write-Host "$($r.StatusCode)  $u" -ForegroundColor Green } catch { Write-Host "FAIL  $u" -ForegroundColor Red }
}
Write-Host "Now paste the blog.html card from blog-and-sitemap-snippets.txt (GitHub web UI), then commit." -ForegroundColor Yellow
