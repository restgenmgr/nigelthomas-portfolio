# ============================================================
# fix-encoding-sitewide.ps1
#
# Finds and repairs UTF-8-interpreted-as-Windows-1252 mojibake
# (the "Â©", "â€"", "â†'" pattern) across every .html file in the repo.
#
# SAFE BY DEFAULT: running this script with no switches only
# SCANS and writes a report. Nothing is modified until you
# re-run it with -Apply.
#
# Usage:
#   .\fix-encoding-sitewide.ps1                 # scan only, writes report
#   .\fix-encoding-sitewide.ps1 -Apply           # actually fixes files
#
# Excludes: .git, node_modules, any backup-html-* folder
# ============================================================

param(
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$repoRoot = Get-Location
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $repoRoot "encoding-scan-report-$timestamp.txt"
$backupRoot = Join-Path $repoRoot "backup-html-$timestamp"

Write-Host "=== Encoding Corruption Scan ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Apply) { 'APPLY (files will be modified)' } else { 'SCAN ONLY (report will be written, nothing changed)' })" -ForegroundColor Yellow

# Find all html files, excluding .git, node_modules, and any backup-html-* folder
$files = Get-ChildItem -Path $repoRoot -Recurse -Filter "*.html" -File |
    Where-Object {
        $_.FullName -notmatch "\\\.git\\" -and
        $_.FullName -notmatch "\\node_modules\\" -and
        $_.FullName -notmatch "\\backup-html-"
    }

Write-Host "Scanning $($files.Count) HTML files...`n"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$win1252 = [System.Text.Encoding]::GetEncoding(1252)

# Indicator characters that suggest UTF-8 bytes were misread as Windows-1252
$indicatorPattern = [regex]"[ÂÃâ]"

$report = New-Object System.Collections.Generic.List[string]
$report.Add("Encoding Corruption Scan Report - $timestamp")
$report.Add("Repo: $repoRoot")
$report.Add("Mode: $(if ($Apply) { 'APPLY' } else { 'SCAN ONLY' })")
$report.Add("=" * 70)
$report.Add("")

$filesWithIssues = 0
$filesFixed = 0
$filesSkippedRisky = 0

foreach ($file in $files) {

    $original = [System.IO.File]::ReadAllText($file.FullName)

    if (-not $indicatorPattern.IsMatch($original)) {
        continue
    }

    # Attempt the standard mojibake repair: reinterpret the UTF-8 text's
    # characters as if they were Windows-1252 bytes, then decode those
    # bytes as UTF-8 to recover the original characters.
    try {
        $bytes = $win1252.GetBytes($original)
        $repaired = [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        $filesSkippedRisky++
        $report.Add("SKIPPED (repair threw an error): $($file.FullName)")
        $report.Add("  Error: $($_.Exception.Message)")
        $report.Add("")
        continue
    }

    # Safety check: if the repair introduces replacement characters (U+FFFD)
    # that were NOT already present in the original, this indicates a deeper
    # or different corruption layer (e.g. CP437/OEM) that this fix cannot
    # safely handle. Skip it rather than risk further data loss.
    $originalReplacementCount = ([regex]::Matches($original, [char]0xFFFD)).Count
    $repairedReplacementCount = ([regex]::Matches($repaired, [char]0xFFFD)).Count

    if ($repairedReplacementCount -gt $originalReplacementCount) {
        $filesSkippedRisky++
        $report.Add("SKIPPED (would introduce replacement characters - needs manual review): $($file.FullName)")
        $report.Add("")
        continue
    }

    if ($repaired -eq $original) {
        continue
    }

    $filesWithIssues++

    # Build a small sample of what would change, for the report
    $relPath = $file.FullName.Substring($repoRoot.Path.Length).TrimStart('\')
    $report.Add("FILE: $relPath")

    # Show up to 3 sample differences
    $origLines = $original -split "`n"
    $repLines = $repaired -split "`n"
    $sampleCount = 0
    for ($i = 0; $i -lt $origLines.Count -and $sampleCount -lt 3; $i++) {
        if ($origLines[$i] -ne $repLines[$i]) {
            $report.Add("  Line $($i+1) before: $($origLines[$i].Trim())")
            $report.Add("  Line $($i+1) after:  $($repLines[$i].Trim())")
            $sampleCount++
        }
    }
    $report.Add("")

    if ($Apply) {
        # Back up the original before touching it
        $relDir = Split-Path $relPath -Parent
        $backupDir = if ($relDir) { Join-Path $backupRoot $relDir } else { $backupRoot }
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item -Path $file.FullName -Destination (Join-Path $backupRoot $relPath) -Force

        [System.IO.File]::WriteAllText($file.FullName, $repaired, $utf8NoBom)
        $filesFixed++
    }
}

$report.Add("=" * 70)
$report.Add("SUMMARY")
$report.Add("Files scanned: $($files.Count)")
$report.Add("Files with corruption found: $filesWithIssues")
$report.Add("Files skipped as risky (needs manual review): $filesSkippedRisky")
if ($Apply) {
    $report.Add("Files fixed: $filesFixed")
    $report.Add("Backups saved to: $backupRoot")
} else {
    $report.Add("No files modified (scan-only mode). Re-run with -Apply to fix.")
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`n=== Scan complete ===" -ForegroundColor Cyan
Write-Host "Files scanned:              $($files.Count)"
Write-Host "Files with corruption:      $filesWithIssues" -ForegroundColor $(if ($filesWithIssues -gt 0) { "Yellow" } else { "Green" })
Write-Host "Files flagged risky (skip): $filesSkippedRisky" -ForegroundColor $(if ($filesSkippedRisky -gt 0) { "Red" } else { "Green" })
if ($Apply) {
    Write-Host "Files fixed:                $filesFixed" -ForegroundColor Green
    Write-Host "Backups saved to:           $backupRoot"
}
Write-Host "`nFull report written to: $reportPath" -ForegroundColor Cyan

if (-not $Apply -and $filesWithIssues -gt 0) {
    Write-Host "`nThis was a SCAN ONLY. Review $reportPath, then re-run with:" -ForegroundColor Yellow
    Write-Host "  .\fix-encoding-sitewide.ps1 -Apply" -ForegroundColor Yellow
}

if ($filesSkippedRisky -gt 0) {
    Write-Host "`n$filesSkippedRisky file(s) were skipped because automatic repair looked unsafe (possible deeper/different corruption layer)." -ForegroundColor Red
    Write-Host "These need manual review - check the report for filenames, open them, and confirm with Claude before editing by hand." -ForegroundColor Red
}
