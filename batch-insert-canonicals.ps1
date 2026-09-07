$path = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$csvFile = (Get-ChildItem "$path\CanonicalAudit_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$csv = Import-Csv $csvFile

$exclude = @(
    "google0c2817338a31af1a.html",
    "accounting\index.html",
    "accounting-dashboard.html",
    "accounting-v3.html",
    "restaurant-general-manager-job-description-duties-responsibilities.html",
    "food-safety\restaurant-sop-haccp-fire-safety-compliance-india.html"
)

$targets = $csv | Where-Object { $_.HasCanonical -eq "No" -and $_.RelativePath -notin $exclude }

Write-Host "Processing $($targets.Count) files..." -ForegroundColor Cyan
$fixedCount = 0
$skippedCount = 0

foreach ($t in $targets) {
    $filePath = Join-Path $path $t.RelativePath
    $content = Get-Content -Raw $filePath

    if ($content -match 'rel="canonical"') {
        Write-Host "SKIP (already has canonical): $($t.RelativePath)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }

    $relUrlPath = ($t.RelativePath -replace '\\','/')
    $encodedUrlPath = $relUrlPath -replace '&','&amp;'
    $canonicalTag = "`n<link rel=`"canonical`" href=`"https://www.nigelthomas.live/$encodedUrlPath`">"

    if ($content -match '</title>') {
        $newContent = $content -replace '(</title>)', "`$1$canonicalTag"
        Set-Content -Path $filePath -Value $newContent -NoNewline -Encoding UTF8
        $fixedCount++
    } else {
        Write-Host "SKIP (no </title> found): $($t.RelativePath)" -ForegroundColor Red
        $skippedCount++
    }
}

Write-Host ""
Write-Host "Fixed: $fixedCount, Skipped: $skippedCount" -ForegroundColor Green
