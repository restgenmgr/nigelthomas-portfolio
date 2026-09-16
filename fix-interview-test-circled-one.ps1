# fix-interview-test-circled-one.ps1
# Fixes ONLY the single corrupted circled-one character in
# the-five-minute-restaurant-interview-test.html
# Does NOT touch the already-correct emoji elsewhere in the file.
# Run from: C:\Users\admin\Desktop\nigelthomas-portfolio

$filePath = ".\the-five-minute-restaurant-interview-test.html"

if (-not (Test-Path $filePath)) {
    Write-Host "FILE NOT FOUND: $filePath -- run this from the repo root." -ForegroundColor Red
    exit 1
}

# Build the corrupted sequence from explicit code points (not typed literally,
# so this script's own encoding can't matter):
#   U+00E2 (a-circumflex), U+2018 (left single quote), U+00A0 (nbsp)
$broken = -join @([char]0x00E2, [char]0x2018, [char]0x00A0)

# The correct replacement: U+2460 CIRCLED DIGIT ONE
$fixed = [string][char]0x2460

$bytes = [System.IO.File]::ReadAllBytes($filePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$occurrences = ([regex]::Matches($content, [regex]::Escape($broken))).Count
Write-Host "Occurrences of the broken sequence found: $occurrences"

if ($occurrences -eq 0) {
    Write-Host "No match found -- nothing changed. The corruption may differ from what we diagnosed." -ForegroundColor Yellow
    exit 1
}
if ($occurrences -gt 1) {
    Write-Host "More than one occurrence found -- stopping without changes so you can review first." -ForegroundColor Yellow
    exit 1
}

$newContent = $content.Replace($broken, $fixed)

# Backup before writing
$backupPath = ".\the-five-minute-restaurant-interview-test.html.bak"
Copy-Item $filePath $backupPath -Force
Write-Host "Backup saved to $backupPath" -ForegroundColor Green

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)

Write-Host "Done. Replaced 1 occurrence of the corrupted circled-one character." -ForegroundColor Cyan
Write-Host "Verify with: Select-String -Path .\the-five-minute-restaurant-interview-test.html -Pattern 'What to Check First'" -ForegroundColor Cyan
