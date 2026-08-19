$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\admin\Desktop\nigelthomas-portfolio"
Set-Location $repoPath

Write-Host "== Pulling latest ==" -ForegroundColor Cyan
git pull --rebase

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$files = @(
  "coffee-types-poster.html",
  "7-types-of-coffee-and-how-theyre-made.html",
  "coffee-shop-vocabulary.html"
)

Write-Host "== Re-saving files as no-BOM UTF-8 ==" -ForegroundColor Cyan
foreach ($f in $files) {
    $path = Join-Path $repoPath $f
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path)
        [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
        Write-Host "  Re-saved: $f"
    } else {
        Write-Host "  MISSING: $f (did the zip extract correctly?)" -ForegroundColor Red
    }
}

Write-Host "== Checking required image assets ==" -ForegroundColor Cyan
$img1 = Join-Path $repoPath "assets\coffee-shop-vocabulary.jpg"
$img2 = Join-Path $repoPath "assets\7-types-of-coffee-and-how-theyre-made.jpg"

if (Test-Path $img1) {
    Write-Host "  OK: assets\coffee-shop-vocabulary.jpg"
} else {
    Write-Host "  MISSING: assets\coffee-shop-vocabulary.jpg" -ForegroundColor Red
}

if (Test-Path $img2) {
    Write-Host "  OK: assets\7-types-of-coffee-and-how-theyre-made.jpg"
} else {
    Write-Host "  WARNING: assets\7-types-of-coffee-and-how-theyre-made.jpg is MISSING." -ForegroundColor Yellow
    Write-Host "  coffee-types-poster.html and 7-types-of-coffee-and-how-theyre-made.html" -ForegroundColor Yellow
    Write-Host "  will show a broken poster image until this file is added." -ForegroundColor Yellow
}

Write-Host "== Staging files ==" -ForegroundColor Cyan
git add coffee-types-poster.html
git add 7-types-of-coffee-and-how-theyre-made.html
git add coffee-shop-vocabulary.html
git add assets/coffee-shop-vocabulary.jpg
if (Test-Path $img2) { git add assets/7-types-of-coffee-and-how-theyre-made.jpg }

# Uncomment these two lines once you've manually edited blog.html and sitemap.xml
# git add blog.html
# git add sitemap.xml

git status

Write-Host "== Committing ==" -ForegroundColor Cyan
git commit -m "Add 3 coffee training articles: coffee types poster, full coffee guide, coffee shop vocabulary poster"

Write-Host "== Pushing ==" -ForegroundColor Cyan
git push origin main

Write-Host "== Deploying to Vercel ==" -ForegroundColor Cyan
vercel --prod --force

Write-Host "== Done. Verify live pages: ==" -ForegroundColor Green
Write-Host "  https://www.nigelthomas.live/coffee-types-poster.html"
Write-Host "  https://www.nigelthomas.live/7-types-of-coffee-and-how-theyre-made.html"
Write-Host "  https://www.nigelthomas.live/coffee-shop-vocabulary.html"
