# ==== Config ====
$siteRoot = "https://www.nigelthomas.live"
$today    = (Get-Date).ToString("yyyy-MM-dd")

$folders = @(
  '.',
  'academy',
  'blog',
  'culinary',
  'food-safety',
  'hospitality-management',
  'regional-food'
)

$excludeNames = @(
  'index-old.html',
  'test.html',
  'accounting-dashboard.html',
  'accounting-v3.html',
  'accounting__index.html',
  'world-famous-foods-country-names-poster.html',
  'world-famous-foods-country-names-poster-updated.html'
)

# Resolve repo root regardless of where the script lives
$repoRoot = Split-Path -Parent $PSScriptRoot

# ==== Collect URLs ====
$urls = New-Object System.Collections.Generic.List[string]
$seen = New-Object System.Collections.Generic.HashSet[string]

foreach ($folder in $folders) {
    $fullPath = Join-Path -Path $repoRoot -ChildPath $folder
    if (-not (Test-Path $fullPath)) { continue }

    $files = Get-ChildItem -Path $fullPath -Filter *.html -File
    foreach ($f in $files) {
        if ($excludeNames -contains $f.Name) { continue }

        if ($folder -eq '.') {
            $rel = $f.Name
        } else {
            $rel = "$folder/$($f.Name)"
        }

        $rel = $rel -replace '&', '%26'
        $url = "$siteRoot/$rel"

        if (-not $seen.Add($url)) { continue }

        $priority = '0.5'
        if ($rel -eq 'index.html') { $priority = '1.0' }
        elseif ($rel -eq 'blog.html') { $priority = '0.8' }
        elseif ($rel -in @('kitchen-food.html','beverage.html','management-operations.html','career-general.html')) { $priority = '0.7' }
        elseif ($rel -in @('what-is-ebitda-fb-hospitality-guide.html','kitchen-temperature-log-sheet.html')) { $priority = '0.7' }

        $urls.Add(@"
  <url>
    <loc>$url</loc>
    <lastmod>$today</lastmod>
    <changefreq>monthly</changefreq>
    <priority>$priority</priority>
  </url>
"@)
    }
}

# ==== Build XML ====
$header = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
"@
$footer = "</urlset>`n"

$output = $header + ($urls -join "`n") + $footer

# ==== Write to repo root ====
$outPath = Join-Path -Path $repoRoot -ChildPath 'sitemap.xml'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outPath, $output, $utf8NoBom)

Write-Host "Done. Wrote $($urls.Count) unique URLs to $outPath" -ForegroundColor Green