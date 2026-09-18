# fix-blog-arrow-mojibake.ps1
# Fixes mojibake-corrupted "Read More" arrows in blog.html.
# Unlike fix-gourmet-canapes-v2/v3.ps1, this does NOT require exactly 1 match -
# it fixes every corrupted occurrence it finds, however many there are.
#
# Run from the repo root: .\fix-blog-arrow-mojibake.ps1

$targetFile = "blog.html"

if (-not (Test-Path $targetFile)) {
    Write-Host "ERROR: $targetFile not found in current directory." -ForegroundColor Red
    exit 1
}

# --- Backup first ---
$backupName = "$targetFile.bak-arrowfix-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path $targetFile -Destination $backupName
Write-Host "Backup created: $backupName" -ForegroundColor Yellow

# --- Read raw bytes, decode explicitly as UTF-8 ---
$fullPath = Join-Path (Get-Location) $targetFile
$bytes = [System.IO.File]::ReadAllBytes($fullPath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# The corrupted sequence is the arrow (U+2192, UTF-8 E2 86 92) that got
# misread as cp1252 and re-saved as UTF-8, producing this 3-char garble:
#   â  †  '
$corrupted = [char]0x00E2 + [char]0x2020 + [char]0x2019   # â†'
$correct   = [char]0x2192                                  # →

$countBefore = ([regex]::Matches($content, [regex]::Escape($corrupted))).Count
Write-Host "Found $countBefore corrupted arrow occurrence(s)."

if ($countBefore -eq 0) {
    Write-Host "Nothing to fix. No changes written." -ForegroundColor Yellow
    exit 0
}

$fixed = $content.Replace($corrupted, $correct)

# --- Write back as UTF-8 WITHOUT BOM ---
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($fullPath, $fixed, $utf8NoBom)

$countAfter = ([regex]::Matches($fixed, [regex]::Escape($corrupted))).Count
$fixedCount = $countBefore - $countAfter

Write-Host "Fixed $fixedCount occurrence(s). Remaining corrupted: $countAfter" -ForegroundColor Green
Write-Host "Review with: git diff $targetFile" -ForegroundColor Cyan
Write-Host "If it looks right: git add $targetFile; git commit -m 'Fix mojibake arrow in blog.html Read More buttons'" -ForegroundColor Cyan
