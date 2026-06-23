# fix-encoding.ps1
# Fixes double-encoded UTF-8 (mojibake) in all .html files under the current directory.
# Creates a timestamped backup folder before touching anything.

$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "encoding-backup-$timestamp"

Write-Host "Creating backup folder: $backupDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $backupDir | Out-Null

# Get all html files, excluding node_modules / backup folders / .git
$files = Get-ChildItem -Path . -Recurse -Filter "*.html" -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\backup-before-ga4-cleanup\\' -and
    $_.FullName -notmatch '\\encoding-backup-'
}

Write-Host "Found $($files.Count) HTML files to check." -ForegroundColor Cyan

$latin1 = [System.Text.Encoding]::GetEncoding("Windows-1252")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$fixedFiles = @()
$skippedFiles = @()

foreach ($file in $files) {

    # Read raw bytes, decode as UTF-8 (this gives us the CURRENT, possibly-corrupted text)
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $currentText = [System.Text.Encoding]::UTF8.GetString($bytes)

    # Detect mojibake markers commonly produced by UTF-8 -> Latin1 -> UTF-8 double encoding
    $mojibakePattern = 'Ã.|â€.|â€™|â€"|â€¢|Â©|Â®|ðŸ'

    if ($currentText -match $mojibakePattern) {

        # Reverse the damage:
        # 1. Take the corrupted string
        # 2. Re-encode it as Windows-1252 bytes (this recovers the ORIGINAL utf-8 byte sequence)
        # 3. Decode those bytes as UTF-8 to get the correct original text
        try {
            $recoveredBytes = $latin1.GetBytes($currentText)
            $fixedText = [System.Text.Encoding]::UTF8.GetString($recoveredBytes)
        } catch {
            Write-Host "  Could not process $($file.FullName): $_" -ForegroundColor Red
            continue
        }

        # Backup original first
        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
        $backupPath = Join-Path $backupDir $relativePath
        $backupFolder = Split-Path $backupPath -Parent
        if (-not (Test-Path $backupFolder)) {
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        }
        Copy-Item $file.FullName $backupPath -Force

        # Write fixed content back as clean UTF-8 (no BOM)
        [System.IO.File]::WriteAllText($file.FullName, $fixedText, $utf8NoBom)

        $fixedFiles += $relativePath
        Write-Host "  Fixed: $relativePath" -ForegroundColor Green
    } else {
        $skippedFiles += $file.Name
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Fixed:   $($fixedFiles.Count) files" -ForegroundColor Green
Write-Host "Skipped: $($skippedFiles.Count) files (no mojibake detected)" -ForegroundColor Yellow
Write-Host "Backups saved to: $backupDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Review changes with: git diff" -ForegroundColor White
Write-Host "If anything looks wrong, restore from $backupDir or use: git checkout -- <file>" -ForegroundColor White
