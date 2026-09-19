$path = "C:\Users\admin\Desktop\nigelthomas-portfolio"
$csvFile = (Get-ChildItem "$path\CanonicalAudit_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$csv = Import-Csv $csvFile

$exclude = @("google0c2817338a31af1a.html", "accounting\index.html", "accounting-dashboard.html", "accounting-v3.html")

$targets = $csv | Where-Object { $_.HasCanonical -eq "No" -and $_.RelativePath -notin $exclude }

Write-Host "Total targets: $($targets.Count)" -ForegroundColor Cyan
$missingTitle = 0

foreach ($t in $targets) {
    $filePath = Join-Path $path $t.RelativePath
    $content = Get-Content -Raw $filePath
    if ($content -notmatch '</title>') {
        Write-Host "NO </title> FOUND: $($t.RelativePath)" -ForegroundColor Red
        $missingTitle++
    }
}

Write-Host ""
Write-Host "Files without a </title> tag: $missingTitle" -ForegroundColor Yellow