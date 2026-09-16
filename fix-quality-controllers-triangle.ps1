# fix-quality-controllers-triangle.ps1
# Fixes ONLY the single corrupted triangle-bullet character (in a CSS
# content: property) in quality-controllers-food-industry.html.
# Run from: C:\Users\admin\Desktop\nigelthomas-portfolio

[System.IO.Directory]::SetCurrentDirectory((Get-Location).Path)

$filePath = ".\quality-controllers-food-industry.html"

if (-not (Test-Path $filePath)) {
    Write-Host "FILE NOT FOUND: $filePath -- run this from the repo root." -ForegroundColor Red
    exit 1
}

# Corrupted sequence, built from explicit code points:
#   U+00E2 (a-circumflex), U+2013 (en dash), U+00B8 (cedilla)
$broken = -join @([char]0x00E2, [char]0x2013, [char]0x00B8)

# Correct replacement: U+25B8 BLACK RIGHT-POINTING SMALL TRIANGLE
$fixed = [string][char]0x25B8

$fullPath = (Resolve-Path $filePath).Path
$bytes = [System.IO.File]::ReadAllBytes($fullPath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$occurrences = ([regex]::Matches($content, [regex]::Escape($broken))).Count
Write-Host "Occurrences of the broken sequence found: $occurrences"

if ($occurrences -eq 0) {
    Write-Host "No match found -- nothing changed." -ForegroundColor Yellow
    exit 1
}
if ($occurrences -gt 1) {
    Write-Host "More than one occurrence found -- stopping without changes so you can review first." -ForegroundColor Yellow
    exit 1
}

$newContent = $content.Replace($broken, $fixed)

$backupPath = ".\quality-controllers-food-industry.html.bak"
Copy-Item $filePath $backupPath -Force
Write-Host "Backup saved to $backupPath" -ForegroundColor Green

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($fullPath, $newContent, $utf8NoBom)

Write-Host "Done. Replaced 1 occurrence of the corrupted triangle-bullet character." -ForegroundColor Cyan
Write-Host "Verify with: Select-String -Path .\quality-controllers-food-industry.html -Pattern 'content:'" -ForegroundColor Cyan
