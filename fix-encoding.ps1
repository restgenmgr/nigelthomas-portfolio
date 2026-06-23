# fix-encoding.ps1 
# Fixes double-encoded UTF-8 (mojibake) in all .html files under the current directory.
# Creates a timestamped backup folder before touching anything.
# NOTE: Uses only ASCII characters in this script file itself to avoid encoding issues.

$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "encoding-backup-$timestamp"

Write-Host "Creating backup folder: $backupDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $backupDir | Out-Null

# Get all html files, excluding .git / backup folders
$files = Get-ChildItem -Path . -Recurse -Filter "*.html" -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\backup-before-ga4-cleanup\\' -and
    $_.FullName -notmatch '\\encoding-backup-'
}

Write-Host "Found $($files.Count) HTML files to check." -ForegroundColor Cyan

$latin1 = [System.Text.Encoding]::GetEncoding("Windows-1252")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Mojibake marker characters, expressed as ASCII-safe unicode escapes
$mojibakePattern = "[`u{00C3}`u{00C2}`u{00F0}]"

$fixedFiles = @()
$skippedFiles = @()

foreach ($file in $files) {

    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $currentText = [System.Text.Encoding]::UTF8.GetString($bytes)

    if ($currentText -match $mojibakePattern) {

        try {
            $recoveredBytes = $latin1.GetBytes($currentText)
            $fixedText = [System.Text.Encoding]::UTF8.GetString($recoveredBytes)
        } catch {
            Write-Host ("  Could not process {0}: {1}" -f $file.FullName, $_) -ForegroundColor Red
            continue
        }

        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
        $backupPath = Join-Path $backupDir $relativePath
        $backupFolder = Split-Path $backupPath -Parent
        if (-not (Test-Path $backupFolder)) {
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        }
        Copy-Item $file.FullName $backupPath -Force

        [System.IO.File]::WriteAllText($file.FullName, $fixedText, $utf8NoBom)

        $fixedFiles += $relativePath
        Write-Host ("  Fixed: {0}" -f $relativePath) -ForegroundColor Green
    } else {
        $skippedFiles += $file.Name
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ("Fixed:   {0} files" -f $fixedFiles.Count) -ForegroundColor Green
Write-Host ("Skipped: {0} files (no mojibake detected)" -f $skippedFiles.Count) -ForegroundColor Yellow
Write-Host ("Backups saved to: {0}" -f $backupDir) -ForegroundColor Cyan
Write-Host ""
Write-Host "Review changes with: git diff" -ForegroundColor White
Write-Host "If anything looks wrong, restore a single file with: git checkout -- FILENAME" -ForegroundColor White
